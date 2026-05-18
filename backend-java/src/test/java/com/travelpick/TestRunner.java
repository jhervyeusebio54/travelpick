package com.travelpick;

import java.lang.reflect.Field;
import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;

public class TestRunner {
    public static void main(String[] args) {
        System.out.println("Starting TravelPick E2E JUnit Tests Execution...");
        int passed = 0;
        int failed = 0;
        List<String> failedTests = new ArrayList<>();

        try {
            Class<?> testClass = E2EWorkflowTest.class;
            Method[] methods = testClass.getDeclaredMethods();

            for (Method method : methods) {
                if (method.isAnnotationPresent(Test.class)) {
                    System.out.println("\n[RUNNING] " + method.getName());
                    Path tempDir = null;
                    try {
                        // Create instance of test class
                        Object testInstance = testClass.getDeclaredConstructor().newInstance();

                        // Inject @TempDir field
                        tempDir = Files.createTempDirectory("junit_e2e_");
                        for (Field field : testClass.getDeclaredFields()) {
                            if (field.isAnnotationPresent(TempDir.class)) {
                                field.setAccessible(true);
                                field.set(testInstance, tempDir);
                            }
                        }

                        // Invoke test method
                        method.setAccessible(true);
                        method.invoke(testInstance);

                        System.out.println("[SUCCESS] " + method.getName());
                        passed++;
                    } catch (Throwable t) {
                        System.out.println("[FAILED] " + method.getName());
                        if (t instanceof java.lang.reflect.InvocationTargetException) {
                            t = t.getCause();
                        }
                        t.printStackTrace(System.out);
                        failed++;
                        failedTests.add(method.getName() + ": " + t.getMessage());
                    } finally {
                        // Clean up temporary directory
                        if (tempDir != null) {
                            try {
                                Files.walk(tempDir)
                                    .sorted((a, b) -> b.compareTo(a))
                                    .forEach(p -> {
                                        try {
                                            Files.deleteIfExists(p);
                                        } catch (Exception ignored) {}
                                    });
                            } catch (Exception ignored) {}
                        }
                    }
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(1);
        }

        System.out.println("\n========================================");
        System.out.println("TEST RESULTS SUMMARY");
        System.out.println("Passed: " + passed);
        System.out.println("Failed: " + failed);
        System.out.println("========================================");

        if (failed > 0) {
            System.out.println("Failed tests:");
            for (String f : failedTests) {
                System.out.println(" - " + f);
            }
            System.exit(1);
        } else {
            System.out.println("ALL TESTS PASSED SUCCESSFULLY!");
            System.exit(0);
        }
    }
}
