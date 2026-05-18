package com.travelpick.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/** Wikipedia destination catalog proxy (mirrors Python destinations.py /catalog). */
public class DestinationCatalogService {

    private static final Pattern LOCATION_PATTERN = Pattern.compile(
            "\\b(?:in|near|from|of)\\s+([A-Z][A-Za-z .'-]+?)(?:,|\\.|\\sis|\\sare|\\swas|\\swith|\\sand)");

    private final ObjectMapper mapper = new ObjectMapper();
    private final HttpClient client = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(8))
            .build();

    public List<Map<String, Object>> search(String query, int limit) throws IOException, InterruptedException {
        int safeLimit = Math.min(Math.max(limit, 1), 50);
        String searchText = query == null || query.isBlank()
                ? "popular tourist attractions travel destinations"
                : query.trim() + " tourist attraction travel destination";

        String params = "action=query&generator=search&gsrsearch="
                + URLEncoder.encode(searchText, StandardCharsets.UTF_8)
                + "&gsrlimit=" + safeLimit
                + "&prop=pageimages|extracts&exintro=1&explaintext=1&piprop=thumbnail&pithumbsize=900&format=json";

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("https://en.wikipedia.org/w/api.php?" + params))
                .header("User-Agent", "TravelPick/1.0 destination catalog")
                .timeout(Duration.ofSeconds(8))
                .GET()
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() >= 400) {
            throw new IOException("Wikipedia API returned " + response.statusCode());
        }

        JsonNode pages = mapper.readTree(response.body()).path("query").path("pages");
        List<JsonNode> pageList = new ArrayList<>();
        pages.fields().forEachRemaining(entry -> pageList.add(entry.getValue()));
        pageList.sort(Comparator.comparingInt(node -> node.path("index").asInt(0)));

        List<Map<String, Object>> rows = new ArrayList<>();
        int index = 0;
        for (JsonNode page : pageList) {
            String extract = page.path("extract").asText("").trim();
            if (extract.isEmpty()) {
                continue;
            }
            rows.add(destinationFromWikipediaPage(page, index));
            index++;
        }
        return rows;
    }

    private Map<String, Object> destinationFromWikipediaPage(JsonNode page, int index) {
        String title = page.path("title").asText("").replaceAll("\\s*\\([^)]*\\)", "").trim();
        String extract = page.path("extract").asText("").replaceAll("\\s+", " ").trim();
        String imageUrl = page.path("thumbnail").path("source").asText("");

        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", page.path("pageid").asInt());
        row.put("name", title);
        row.put("country", deriveLocation(extract));
        row.put("imageUrl", imageUrl);
        row.put("rating", Math.max(3.8, 4.9 - (index * 0.03)));
        row.put("popularity", Math.max(68, 96 - index));
        row.put("description", shortDescription(extract));
        row.put("estimatedCost", "Varies by itinerary");
        row.put("bestSeason", "Check local seasonality");
        return row;
    }

    private String deriveLocation(String extract) {
        Matcher matcher = LOCATION_PATTERN.matcher(extract);
        return matcher.find() ? matcher.group(1).trim() : "Tourist place";
    }

    private String shortDescription(String extract) {
        return extract.length() <= 180 ? extract : extract.substring(0, 177).trim() + "...";
    }
}
