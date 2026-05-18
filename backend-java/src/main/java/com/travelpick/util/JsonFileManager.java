package com.travelpick.util;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.locks.ReentrantLock;

/**
 * Thread-safe JSON file read/write helpers.
 * Mirrors Python {@code backend/utils/json_store.py}.
 */
public class JsonFileManager {

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .enable(SerializationFeature.INDENT_OUTPUT);

    private final ReentrantLock lock = new ReentrantLock();

    public <T> List<T> readFile(String filePath, Class<T> elementType) throws IOException {
        return readFile(Path.of(filePath), elementType);
    }

    public <T> List<T> readFile(Path filePath, Class<T> elementType) throws IOException {
        lock.lock();
        try {
            Files.createDirectories(filePath.getParent());
            if (!Files.exists(filePath)) {
                writeFile(filePath, List.of());
                return new ArrayList<>();
            }

            String raw = Files.readString(filePath);
            if (raw.isBlank()) {
                writeFile(filePath, List.of());
                return new ArrayList<>();
            }

            try {
                List<T> items = MAPPER.readValue(
                        raw,
                        MAPPER.getTypeFactory().constructCollectionType(List.class, elementType));
                return new ArrayList<>(items);
            } catch (IOException exc) {
                throw new IOException("Invalid JSON in " + filePath.getFileName() + ": " + exc.getMessage(), exc);
            }
        } finally {
            lock.unlock();
        }
    }

    public void writeFile(String filePath, List<?> data) throws IOException {
        writeFile(Path.of(filePath), data);
    }

    public void writeFile(Path filePath, List<?> data) throws IOException {
        lock.lock();
        try {
            Files.createDirectories(filePath.getParent());
            Path temp = filePath.resolveSibling(filePath.getFileName() + ".tmp");
            MAPPER.writeValue(temp.toFile(), data);
            Files.move(
                    temp,
                    filePath,
                    java.nio.file.StandardCopyOption.REPLACE_EXISTING,
                    java.nio.file.StandardCopyOption.ATOMIC_MOVE);
        } catch (IOException exc) {
            Path temp = filePath.resolveSibling(filePath.getFileName() + ".tmp");
            try {
                Files.deleteIfExists(temp);
            } catch (IOException ignored) {
                // best effort cleanup
            }
            throw new IOException("Failed to write " + filePath.getFileName() + ": " + exc.getMessage(), exc);
        } finally {
            lock.unlock();
        }
    }

    public <T> void appendToFile(String filePath, T item, Class<T> elementType) throws IOException {
        appendToFile(Path.of(filePath), item, elementType);
    }

    public <T> void appendToFile(Path filePath, T item, Class<T> elementType) throws IOException {
        List<T> data = readFile(filePath, elementType);
        data.add(item);
        writeFile(filePath, data);
    }

    public int generateId(List<?> data) {
        if (data == null || data.isEmpty()) {
            return 1;
        }
        int max = 0;
        for (Object item : data) {
            if (item instanceof Identifiable identifiable) {
                max = Math.max(max, identifiable.getId());
            }
        }
        return max + 1;
    }

    public ObjectMapper getMapper() {
        return MAPPER;
    }

    /** Optional helper for entities with numeric ids. */
    public interface Identifiable {
        int getId();
    }
}
