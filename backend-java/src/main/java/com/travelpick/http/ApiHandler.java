package com.travelpick.http;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.travelpick.model.Group;
import com.travelpick.model.User;
import com.travelpick.service.DestinationCatalogService;
import com.travelpick.service.DestinationService;
import com.travelpick.service.GroupService;
import com.travelpick.service.ResultsService;
import com.travelpick.service.UserService;
import com.travelpick.service.VoteService;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import java.io.IOException;
import java.net.URI;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Single HTTP handler routing all API paths.
 * Matches Python FastAPI routes for frontend compatibility.
 */
public class ApiHandler implements HttpHandler {

    private final GroupService groupService;
    private final UserService userService;
    private final DestinationService destinationService;
    private final VoteService voteService;
    private final ResultsService resultsService;
    private final com.travelpick.store.DataStore store;
    private final DestinationCatalogService catalogService = new DestinationCatalogService();

    public ApiHandler(
            GroupService groupService,
            UserService userService,
            DestinationService destinationService,
            VoteService voteService,
            ResultsService resultsService,
            com.travelpick.store.DataStore store) {
        this.groupService = groupService;
        this.userService = userService;
        this.destinationService = destinationService;
        this.voteService = voteService;
        this.resultsService = resultsService;
        this.store = store;
    }

    @Override
    public void handle(HttpExchange exchange) throws IOException {
        try {
            if ("OPTIONS".equalsIgnoreCase(exchange.getRequestMethod())) {
                HttpResponses.handleOptions(exchange);
                return;
            }

            String method = exchange.getRequestMethod().toUpperCase();
            URI uri = exchange.getRequestURI();
            String path = uri.getPath();
            if (path.endsWith("/") && path.length() > 1) {
                path = path.substring(0, path.length() - 1);
            }
            Map<String, String> query = QueryParams.parse(uri.getRawQuery());

            if ("/".equals(path) && "GET".equals(method)) {
                HttpResponses.sendJson(
                        exchange,
                        200,
                        Map.of("message", "TravelPick Backend. Visit /docs for API documentation."));
                return;
            }

            if ("/reset".equals(path)) {
                if (!"POST".equals(method)) {
                    HttpResponses.sendError(exchange, 405, "Method not allowed");
                    return;
                }
                String confirm = query.get("confirm");
                if (confirm != null && ("true".equalsIgnoreCase(confirm.trim()) || "yes".equalsIgnoreCase(confirm.trim()))) {
                    store.resetData();
                    HttpResponses.sendJson(exchange, 200, Map.of("message", "All data has been reset successfully."));
                } else {
                    HttpResponses.sendError(exchange, 400, "Reset requires confirmation query parameter: confirm=true");
                }
                return;
            }

            if (path.startsWith("/groups")) {
                handleGroups(exchange, method, path, query);
                return;
            }
            if (path.startsWith("/users")) {
                handleUsers(exchange, method, path, query);
                return;
            }
            if (path.startsWith("/destinations")) {
                handleDestinations(exchange, method, path, query);
                return;
            }
            if (path.startsWith("/votes")) {
                handleVotes(exchange, method, path, query);
                return;
            }
            if (path.startsWith("/results")) {
                handleResults(exchange, method, path, query);
                return;
            }

            HttpResponses.sendError(exchange, 404, "Not found");
        } catch (VoteService.NotFoundException exc) {
            HttpResponses.sendError(exchange, 404, exc.getMessage());
        } catch (IllegalArgumentException exc) {
            int status = exc.getMessage() != null && exc.getMessage().toLowerCase().contains("not found") ? 404 : 400;
            HttpResponses.sendError(exchange, status, exc.getMessage());
        } catch (VoteService.BadRequestException exc) {
            HttpResponses.sendError(exchange, 400, exc.getMessage());
        } catch (Exception exc) {
            HttpResponses.sendError(exchange, 500, exc.getMessage() == null ? "Internal server error" : exc.getMessage());
        } finally {
            exchange.close();
        }
    }

    private void handleGroups(HttpExchange exchange, String method, String path, Map<String, String> query)
            throws IOException {
        if ("/groups".equals(path) && "GET".equals(method)) {
            if (query.containsKey("id")) {
                getGroupById(exchange, parsePositiveInt(query.get("id"), "id"));
                return;
            }
            if (query.containsKey("code")) {
                Optional<Group> group = groupService.findByCode(query.get("code"));
                if (group.isEmpty()) {
                    HttpResponses.sendError(exchange, 404, "Group not found");
                    return;
                }
                HttpResponses.sendJson(exchange, 200, group.get());
                return;
            }
            HttpResponses.sendJson(exchange, 200, groupService.listGroups());
            return;
        }
        if ("/groups".equals(path) && "POST".equals(method)) {
            JsonNode body = HttpResponses.mapper().readTree(HttpResponses.readBody(exchange));
            String name = text(body, "name").trim();
            if (name.isEmpty()) {
                HttpResponses.sendError(exchange, 400, "Group name is required");
                return;
            }
            int ownerUserId = body.path("owner_user_id").asInt(1);
            List<Integer> memberIds = parseIntList(body.get("member_user_ids"));
            Group group = groupService.createGroup(
                    name,
                    textOrNull(body, "code"),
                    textOrNull(body, "privacy"),
                    ownerUserId,
                    memberIds);
            HttpResponses.sendJson(exchange, 200, group);
            return;
        }
        if (path.matches("/groups/\\d+") && "GET".equals(method)) {
            int groupId = Integer.parseInt(path.substring("/groups/".length()));
            getGroupById(exchange, groupId);
            return;
        }
        HttpResponses.sendError(exchange, 404, "Not found");
    }

    private void getGroupById(HttpExchange exchange, int groupId) throws IOException {
        Optional<Group> group = groupService.getGroup(groupId);
        if (group.isEmpty()) {
            HttpResponses.sendError(exchange, 404, "Group not found");
            return;
        }
        HttpResponses.sendJson(exchange, 200, group.get());
    }

    private void handleUsers(HttpExchange exchange, String method, String path, Map<String, String> query)
            throws IOException {
        if ("/users/signup".equals(path) && "POST".equals(method)) {
            JsonNode body = HttpResponses.mapper().readTree(HttpResponses.readBody(exchange));
            String name = text(body, "name").trim();
            String email = text(body, "email").trim();
            String password = text(body, "password");
            if (name.isEmpty() || email.isEmpty()) {
                HttpResponses.sendError(exchange, 400, "Invalid input");
                return;
            }
            if (!email.contains("@")) {
                HttpResponses.sendError(exchange, 400, "Invalid input");
                return;
            }
            if (password.isEmpty() || password.length() < 6) {
                HttpResponses.sendError(exchange, 400, "Invalid input");
                return;
            }

            Integer groupId = body.has("group_id") && !body.get("group_id").isNull()
                    ? body.get("group_id").asInt()
                    : null;
            String groupCode = textOrNull(body, "group_code");
            if (groupId != null && groupId <= 0) {
                HttpResponses.sendError(exchange, 400, "Invalid input");
                return;
            }

            sendSignUpResponse(exchange, userService.signUp(name, email, password, groupId, groupCode));
            return;
        }
        if ("/users/login".equals(path) && "POST".equals(method)) {
            JsonNode body = HttpResponses.mapper().readTree(HttpResponses.readBody(exchange));
            String identifier = text(body, "email").trim();
            if (identifier.isEmpty()) {
                identifier = text(body, "username").trim();
            }
            String password = text(body, "password");
            if (identifier.isEmpty() || password.isEmpty()) {
                HttpResponses.sendError(exchange, 400, "Invalid input");
                return;
            }
            Optional<User> user = userService.authenticate(identifier, password);
            if (user.isEmpty()) {
                HttpResponses.sendError(exchange, 401, "Invalid email or password");
                return;
            }
            sendUserProfile(exchange, 200, user.get());
            return;
        }
        if ("/users".equals(path) && "POST".equals(method)) {
            JsonNode body = HttpResponses.mapper().readTree(HttpResponses.readBody(exchange));
            String name = text(body, "name").trim();
            String email = text(body, "email").trim();
            String password = text(body, "password");
            if (name.isEmpty()) {
                HttpResponses.sendError(exchange, 400, "User name is required");
                return;
            }
            if (!email.isEmpty() && email.contains("@") && !body.has("group_id") && !password.isEmpty()) {
                sendSignUpResponse(
                        exchange,
                        userService.signUp(name, email, password, null, textOrNull(body, "group_code")));
                return;
            }
            if (body.has("group_id") && !body.get("group_id").isNull()) {
                int groupId = body.get("group_id").asInt();
                Integer existingUserId = body.has("user_id") && !body.get("user_id").isNull()
                        ? body.get("user_id").asInt()
                        : null;
                User user = userService.assignUserToGroup(
                        groupId, existingUserId, name, textOrNull(body, "email"));
                sendUserProfile(exchange, 200, user);
                return;
            }
            Integer id = body.has("id") && !body.get("id").isNull() ? body.get("id").asInt() : null;
            User user = userService.createUser(name, textOrNull(body, "email"), id);
            sendUserProfile(exchange, 200, user);
            return;
        }
        if ("/users".equals(path) && "GET".equals(method) && query.containsKey("id")) {
            getUserById(exchange, parsePositiveInt(query.get("id"), "id"));
            return;
        }
        if (path.matches("/users/\\d+") && "GET".equals(method)) {
            getUserById(exchange, Integer.parseInt(path.substring("/users/".length())));
            return;
        }
        if ("/users/membership".equals(path) && "POST".equals(method)) {
            JsonNode body = HttpResponses.mapper().readTree(HttpResponses.readBody(exchange));
            int userId = body.path("user_id").asInt();
            int groupId = body.path("group_id").asInt();
            if (userId <= 0 || groupId <= 0) {
                HttpResponses.sendError(exchange, 400, "Invalid input");
                return;
            }
            if (groupService.getGroup(groupId).isEmpty()) {
                HttpResponses.sendError(exchange, 404, "Group not found");
                return;
            }
            String groupCode = textOrNull(body, "group_code");
            if (groupCode == null) {
                groupCode = groupService.getGroup(groupId).map(group -> group.getCode()).orElse(null);
            }
            String groupRole = textOrNull(body, "group_role");
            if (groupRole == null || groupRole.isBlank()) {
                groupRole = "member";
            }
            try {
                groupService.addMember(groupId, userId);
                Optional<User> existing = userService.getUser(userId);
                boolean keepOwner = existing.isPresent()
                        && existing.get().getGroupId() != null
                        && existing.get().getGroupId() == groupId
                        && "owner".equalsIgnoreCase(existing.get().getGroupRole());
                if (!keepOwner) {
                    userService.setGroupMembership(userId, groupId, groupCode, groupRole);
                }
            } catch (IllegalArgumentException exc) {
                HttpResponses.sendError(exchange, 400, exc.getMessage());
                return;
            }
            Optional<User> user = userService.getUser(userId);
            if (user.isEmpty()) {
                HttpResponses.sendError(exchange, 404, "User not found");
                return;
            }
            sendUserProfile(exchange, 200, user.get());
            return;
        }
        HttpResponses.sendError(exchange, 404, "Not found");
    }

    private void getUserById(HttpExchange exchange, int userId) throws IOException {
        Optional<User> user = userService.getUser(userId);
        if (user.isEmpty()) {
            HttpResponses.sendError(exchange, 404, "User not found");
            return;
        }
        sendUserProfile(exchange, 200, user.get());
    }

    private void handleDestinations(HttpExchange exchange, String method, String path, Map<String, String> query)
            throws IOException {
        if ("/destinations/catalog".equals(path) && "GET".equals(method)) {
            String searchQuery = query.getOrDefault("query", "");
            int limit = query.containsKey("limit") ? Integer.parseInt(query.get("limit")) : 30;
            try {
                HttpResponses.sendJson(exchange, 200, catalogService.search(searchQuery, limit));
            } catch (InterruptedException exc) {
                Thread.currentThread().interrupt();
                HttpResponses.sendError(exchange, 502, exc.getMessage());
            } catch (IOException exc) {
                HttpResponses.sendError(exchange, 502, exc.getMessage());
            }
            return;
        }
        if ("/destinations".equals(path) && "GET".equals(method) && query.containsKey("groupId")) {
            listDestinations(exchange, parsePositiveInt(query.get("groupId"), "groupId"));
            return;
        }
        if (path.matches("/destinations/\\d+") && "GET".equals(method)) {
            int groupId = Integer.parseInt(path.substring("/destinations/".length()));
            listDestinations(exchange, groupId);
            return;
        }
        if ("/destinations".equals(path) && "POST".equals(method)) {
            JsonNode body = HttpResponses.mapper().readTree(HttpResponses.readBody(exchange));
            int groupId = body.path("group_id").asInt();
            String name = text(body, "name").trim();
            if (name.isEmpty()) {
                HttpResponses.sendError(exchange, 400, "Destination name is required");
                return;
            }
            if (groupService.getGroup(groupId).isEmpty()) {
                HttpResponses.sendError(exchange, 404, "Group not found");
                return;
            }
            Integer destId = body.has("id") && !body.get("id").isNull() ? body.get("id").asInt() : null;
            var destination = destinationService.create(
                    groupId,
                    name,
                    textOrNull(body, "description"),
                    destId,
                    textOrNull(body, "country"),
                    textOrNull(body, "imageUrl"),
                    body.has("rating") && !body.get("rating").isNull() ? body.get("rating").asDouble() : null,
                    body.has("popularity") && !body.get("popularity").isNull() ? body.get("popularity").asInt() : null,
                    textOrNull(body, "estimatedCost"),
                    textOrNull(body, "bestSeason"));
            HttpResponses.sendJson(exchange, 200, destination);
            return;
        }
        HttpResponses.sendError(exchange, 404, "Not found");
    }

    private void listDestinations(HttpExchange exchange, int groupId) throws IOException {
        if (groupService.getGroup(groupId).isEmpty()) {
            HttpResponses.sendError(exchange, 404, "Group not found");
            return;
        }
        HttpResponses.sendJson(exchange, 200, destinationService.listByGroup(groupId));
    }

    private void handleVotes(HttpExchange exchange, String method, String path, Map<String, String> query)
            throws IOException {
        if ("/votes/batch".equals(path) && "POST".equals(method)) {
            JsonNode body = HttpResponses.mapper().readTree(HttpResponses.readBody(exchange));
            List<VoteService.VoteRequest> requests = new ArrayList<>();
            for (JsonNode vote : body.path("votes")) {
                requests.add(new VoteService.VoteRequest(
                        vote.path("user_id").asInt(),
                        vote.path("destination_id").asInt(),
                        vote.path("weight").asInt(),
                        vote.has("group_id") && !vote.get("group_id").isNull()
                                ? vote.get("group_id").asInt()
                                : null));
            }
            HttpResponses.sendJson(exchange, 200, voteService.submitBatch(requests));
            return;
        }
        if ("/votes".equals(path) && "POST".equals(method)) {
            JsonNode body = HttpResponses.mapper().readTree(HttpResponses.readBody(exchange));
            Map<String, Object> result = voteService.submitVote(
                    body.path("user_id").asInt(),
                    body.path("destination_id").asInt(),
                    body.path("weight").asInt(),
                    body.has("group_id") && !body.get("group_id").isNull()
                            ? body.get("group_id").asInt()
                            : null);
            HttpResponses.sendJson(exchange, 200, result);
            return;
        }
        if ("/votes".equals(path) && "GET".equals(method) && query.containsKey("groupId")) {
            listVotes(exchange, parsePositiveInt(query.get("groupId"), "groupId"));
            return;
        }
        if (path.matches("/votes/\\d+") && "GET".equals(method)) {
            listVotes(exchange, Integer.parseInt(path.substring("/votes/".length())));
            return;
        }
        HttpResponses.sendError(exchange, 404, "Not found");
    }

    private void listVotes(HttpExchange exchange, int groupId) throws IOException {
        if (groupService.getGroup(groupId).isEmpty()) {
            HttpResponses.sendError(exchange, 404, "Group not found");
            return;
        }
        HttpResponses.sendJson(exchange, 200, voteService.listForGroup(groupId));
    }

    private void handleResults(HttpExchange exchange, String method, String path, Map<String, String> query)
            throws IOException {
        if (path.matches("/results/\\d+") && "GET".equals(method)) {
            int groupId = Integer.parseInt(path.substring("/results/".length()));
            HttpResponses.sendJson(exchange, 200, resultsService.getResults(groupId));
            return;
        }
        if ("/results".equals(path) && "GET".equals(method) && query.containsKey("groupId")) {
            HttpResponses.sendJson(
                    exchange, 200, resultsService.getResults(parsePositiveInt(query.get("groupId"), "groupId")));
            return;
        }
        HttpResponses.sendError(exchange, 404, "Not found");
    }

    private void sendSignUpResponse(
            HttpExchange exchange, com.travelpick.store.DataStore.SignUpResult result) throws IOException {
        sendUserProfile(exchange, 200, result.user());
    }

    private void sendUserProfile(HttpExchange exchange, int status, User user) throws IOException {
        Map<String, Object> response = userProfileMap(user);
        HttpResponses.sendJson(exchange, status, response);
    }

    private Map<String, Object> userProfileMap(User user) {
        Map<String, Object> response = new java.util.LinkedHashMap<>();
        response.put("id", user.getId());
        response.put("username", user.getUsername());
        response.put("name", user.getUsername());
        response.put("email", user.getEmail());
        
        Integer activeGroupId = user.getGroupId();
        response.put("group_id", activeGroupId);
        response.put("group_role", user.getGroupRole());
        
        String groupCode = null;
        if (activeGroupId != null) {
            try {
                groupCode = groupService.getGroup(activeGroupId)
                        .map(Group::getCode)
                        .orElse(null);
            } catch (IOException ignored) {
            }
        }
        response.put("group_code", groupCode);
        
        response.put("created_at", user.getCreatedAt());
        response.put("last_login", user.getLastLogin());

        List<Map<String, Object>> groupsList = new ArrayList<>();
        if (user.getGroups() != null) {
            for (User.UserGroupMembership membership : user.getGroups()) {
                Map<String, Object> m = new java.util.LinkedHashMap<>();
                m.put("group_id", membership.getGroupId());
                m.put("role", membership.getRole());
                groupsList.add(m);
            }
        }
        response.put("groups", groupsList);

        return response;
    }

    private static String text(JsonNode body, String field) {
        return body.path(field).asText("");
    }

    private static String textOrNull(JsonNode body, String field) {
        JsonNode node = body.get(field);
        if (node == null || node.isNull()) {
            return null;
        }
        String value = node.asText();
        return value.isBlank() ? null : value;
    }

    private static List<Integer> parseIntList(JsonNode node) {
        if (node == null || !node.isArray()) {
            return null;
        }
        List<Integer> values = new ArrayList<>();
        node.forEach(item -> values.add(item.asInt()));
        return values;
    }

    private static int parsePositiveInt(String value, String name) {
        int parsed = Integer.parseInt(value);
        if (parsed <= 0) {
            throw new IllegalArgumentException(name + " must be a positive integer");
        }
        return parsed;
    }
}
