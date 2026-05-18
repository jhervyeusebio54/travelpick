package com.travelpick.util;

/** Input validators mirroring Python validators.py. */
public final class Validators {

    private Validators() {
    }

    public static void validateWeight(int weight) {
        if (weight < 1 || weight > 5) {
            throw new IllegalArgumentException("Weight must be between 1 and 5");
        }
    }

    public static void validatePositiveInt(int value, String name) {
        if (value <= 0) {
            throw new IllegalArgumentException(name + " must be a positive integer");
        }
    }
}
