package com.learnff.model;

public record FeatureFlag(
    String key,
    boolean enabled,
    String description,
    FlagScope scope
) {
    public enum FlagScope {
        GENERAL, BACKEND, WEB, MOBILE
    }
}
