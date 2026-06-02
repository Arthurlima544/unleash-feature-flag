package com.learnff.config;

import java.util.Map;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "feature-flags")
public record FeatureFlagProperties(Map<String, FlagDefinition> flags) {

    public record FlagDefinition(boolean enabled, String description, String scope) {}
}
