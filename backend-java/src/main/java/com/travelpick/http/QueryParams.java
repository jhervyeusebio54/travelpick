package com.travelpick.http;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

final class QueryParams {

    private QueryParams() {
    }

    static Map<String, String> parse(String rawQuery) {
        Map<String, String> params = new HashMap<>();
        if (rawQuery == null || rawQuery.isBlank()) {
            return params;
        }
        for (String pair : rawQuery.split("&")) {
            int index = pair.indexOf('=');
            if (index < 0) {
                params.put(
                        URLDecoder.decode(pair, StandardCharsets.UTF_8),
                        "");
            } else {
                String key = URLDecoder.decode(pair.substring(0, index), StandardCharsets.UTF_8);
                String value = URLDecoder.decode(pair.substring(index + 1), StandardCharsets.UTF_8);
                params.put(key, value);
            }
        }
        return params;
    }
}
