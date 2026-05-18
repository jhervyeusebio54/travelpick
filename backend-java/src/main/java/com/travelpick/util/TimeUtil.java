package com.travelpick.util;

import java.time.Instant;

public final class TimeUtil {

    private TimeUtil() {
    }

    public static String utcNow() {
        return Instant.now().toString().replace("+00:00", "Z");
    }
}
