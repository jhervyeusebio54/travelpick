package com.travelpick.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.util.Base64;

/** SHA-256 password hashing with per-user salt (stored in users.json). */
public final class PasswordHasher {

    private static final String PREFIX = "sha256:";

    private PasswordHasher() {
    }

    public static String hash(String password) {
        if (password == null || password.isBlank()) {
            throw new IllegalArgumentException("Password must not be empty");
        }
        byte[] salt = new byte[16];
        new SecureRandom().nextBytes(salt);
        String digest = digest(salt, password);
        return PREFIX + Base64.getEncoder().encodeToString(salt) + ":" + digest;
    }

    public static boolean verify(String password, String storedHash) {
        if (password == null || storedHash == null || !storedHash.startsWith(PREFIX)) {
            return false;
        }
        String[] parts = storedHash.substring(PREFIX.length()).split(":", 2);
        if (parts.length != 2) {
            return false;
        }
        byte[] salt = Base64.getDecoder().decode(parts[0]);
        String expected = parts[1];
        return MessageDigest.isEqual(digest(salt, password).getBytes(StandardCharsets.UTF_8), expected.getBytes(StandardCharsets.UTF_8));
    }

    private static String digest(byte[] salt, String password) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            digest.update(salt);
            digest.update(password.getBytes(StandardCharsets.UTF_8));
            return Base64.getEncoder().encodeToString(digest.digest());
        } catch (NoSuchAlgorithmException exc) {
            throw new IllegalStateException("SHA-256 not available", exc);
        }
    }
}
