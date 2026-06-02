package com.learnff.service;

import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

import org.springframework.stereotype.Service;

import com.learnff.config.FeatureFlagProperties;
import com.learnff.model.FeatureFlag;
import com.learnff.model.FeatureFlag.FlagScope;

@Service
public class FeatureFlagService {

    // Runtime overrides live here — they shadow application.yml values
    private final Map<String, Boolean> runtimeOverrides = new ConcurrentHashMap<>();
    private final FeatureFlagProperties properties;

    public FeatureFlagService(FeatureFlagProperties properties) {
        this.properties = properties;
    }

    public List<FeatureFlag> getAllFlags() {
        return properties.flags().entrySet().stream()
            .map(entry -> toFeatureFlag(entry.getKey(), entry.getValue()))
            .toList();
    }

    public List<FeatureFlag> getFlagsByScope(FlagScope scope) {
        return getAllFlags().stream()
            .filter(f -> f.scope() == scope || f.scope() == FlagScope.GENERAL)
            .toList();
    }

    public Optional<FeatureFlag> getFlag(String key) {
        var def = properties.flags().get(key);
        if (def == null) return Optional.empty();
        return Optional.of(toFeatureFlag(key, def));
    }

    public boolean isEnabled(String key) {
        if (runtimeOverrides.containsKey(key)) {
            return runtimeOverrides.get(key);
        }
        var def = properties.flags().get(key);
        return def != null && def.enabled();
    }

    public FeatureFlag toggle(String key) {
        var current = isEnabled(key);
        runtimeOverrides.put(key, !current);
        return getFlag(key).orElseThrow(() -> new IllegalArgumentException("Unknown flag: " + key));
    }

    public FeatureFlag setEnabled(String key, boolean enabled) {
        if (!properties.flags().containsKey(key)) {
            throw new IllegalArgumentException("Unknown flag: " + key);
        }
        runtimeOverrides.put(key, enabled);
        return getFlag(key).orElseThrow();
    }

    public void resetToDefaults() {
        runtimeOverrides.clear();
    }

    private FeatureFlag toFeatureFlag(String key, FeatureFlagProperties.FlagDefinition def) {
        boolean enabled = runtimeOverrides.getOrDefault(key, def.enabled());
        FlagScope scope = FlagScope.valueOf(def.scope());
        return new FeatureFlag(key, enabled, def.description(), scope);
    }
}
