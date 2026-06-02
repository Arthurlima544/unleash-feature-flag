package com.learnff.service;

import java.util.List;
import java.util.Optional;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import com.learnff.config.FeatureFlagProperties;
import com.learnff.model.FeatureFlag;
import com.learnff.model.FeatureFlag.FlagScope;

import io.getunleash.Unleash;
import jakarta.annotation.PostConstruct;

/**
 * Unleash-backed implementation. Active when spring.profiles.active=unleash.
 * Reads flag metadata (scope, description) from application.yml but delegates
 * enabled/disabled state entirely to the Unleash server.
 * Toggle calls go to Unleash Admin API so state persists server-side.
 */
@Service
@Profile("unleash")
@Primary
public class UnleashFeatureFlagService extends FeatureFlagService {

    private final Unleash unleash;
    private RestClient adminClient;

    @Value("${unleash.api-url}")
    private String apiUrl;

    @Value("${unleash.admin-key}")
    private String adminKey;

    @Value("${unleash.environment:development}")
    private String environment;

    @Value("${unleash.project:default}")
    private String project;

    public UnleashFeatureFlagService(FeatureFlagProperties properties, Unleash unleash) {
        super(properties);
        this.unleash = unleash;
    }

    @PostConstruct
    void buildAdminClient() {
        // Base URL up to /api — we append /admin/... paths per call
        this.adminClient = RestClient.builder()
            .baseUrl(apiUrl)
            .defaultHeader("Authorization", adminKey)
            .defaultHeader("Content-Type", "application/json")
            .build();
    }

    @Override
    public boolean isEnabled(String key) {
        return unleash.isEnabled(key);
    }

    @Override
    public List<FeatureFlag> getAllFlags() {
        // Merge Unleash state with YAML metadata (scope, description)
        return super.getAllFlags().stream()
            .map(f -> new FeatureFlag(f.key(), unleash.isEnabled(f.key()), f.description(), f.scope()))
            .toList();
    }

    @Override
    public Optional<FeatureFlag> getFlag(String key) {
        return super.getFlag(key)
            .map(f -> new FeatureFlag(f.key(), unleash.isEnabled(f.key()), f.description(), f.scope()));
    }

    @Override
    public FeatureFlag toggle(String key) {
        boolean current = unleash.isEnabled(key);
        String action = current ? "off" : "on";
        callToggleApi(key, action);
        // Give Unleash SDK a moment to pick up the change via its polling cycle,
        // but return the expected new state immediately
        FlagScope scope = super.getFlag(key).map(FeatureFlag::scope).orElse(FlagScope.GENERAL);
        String desc = super.getFlag(key).map(FeatureFlag::description).orElse("");
        return new FeatureFlag(key, !current, desc, scope);
    }

    @Override
    public FeatureFlag setEnabled(String key, boolean enabled) {
        String action = enabled ? "on" : "off";
        callToggleApi(key, action);
        FlagScope scope = super.getFlag(key).map(FeatureFlag::scope).orElse(FlagScope.GENERAL);
        String desc = super.getFlag(key).map(FeatureFlag::description).orElse("");
        return new FeatureFlag(key, enabled, desc, scope);
    }

    // reset() is not meaningful against a real server; just log a warning
    @Override
    public void resetToDefaults() {
        throw new UnsupportedOperationException(
            "resetToDefaults() is not supported when using Unleash. Manage flags in the Unleash UI."
        );
    }

    private void callToggleApi(String flagKey, String action) {
        try {
            adminClient.post()
                .uri("/admin/projects/{project}/features/{key}/environments/{env}/{action}",
                    project, flagKey, environment, action)
                .retrieve()
                .toBodilessEntity();
        } catch (RestClientException e) {
            throw new IllegalStateException(
                "Unleash Admin API call failed for flag '" + flagKey + "': " + e.getMessage(), e
            );
        }
    }
}
