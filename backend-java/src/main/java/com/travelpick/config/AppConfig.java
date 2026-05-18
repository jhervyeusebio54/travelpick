package com.travelpick.config;

import java.nio.file.Path;
import java.nio.file.Paths;

/** Application configuration (data directory, server port). */
public final class AppConfig {

    public static final int PORT = 8000;

    private AppConfig() {
    }

    public static Path getDataDir() {
        return resolveDataDir();
    }

    public static Path groupsFile() {
        return getDataDir().resolve("groups.json");
    }

    public static Path usersFile() {
        return getDataDir().resolve("users.json");
    }

    public static Path destinationsFile() {
        return getDataDir().resolve("destinations.json");
    }

    public static Path votesFile() {
        return getDataDir().resolve("votes.json");
    }

    public static Path legacyFile() {
        return getDataDir().resolve("travelpick.json");
    }

    private static Path resolveDataDir() {
        String override = System.getenv("TRAVELPICK_DATA_DIR");
        if (override == null || override.isBlank()) {
            override = System.getProperty("travelpick.data.dir");
        }
        if (override != null && !override.isBlank()) {
            return Paths.get(override).toAbsolutePath().normalize();
        }
        // backend-java/ -> ../backend/data
        Path fromModule = Paths.get("").toAbsolutePath().resolve("../backend/data").normalize();
        if (fromModule.toFile().exists()) {
            return fromModule;
        }
        return Paths.get("backend", "data").toAbsolutePath().normalize();
    }
}
