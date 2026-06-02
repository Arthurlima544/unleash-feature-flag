package com.learnff;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.learnff.config.FeatureFlagProperties;
import com.learnff.config.FeatureFlagProperties.FlagDefinition;
import com.learnff.model.FeatureFlag.FlagScope;
import com.learnff.service.FeatureFlagService;

class FeatureFlagServiceTest {

    private FeatureFlagService service;

    @BeforeEach
    void setup() {
        var flags = Map.of(
            "GENERAL_DARK_MODE", new FlagDefinition(true, "Dark mode", "GENERAL"),
            "BACKEND_ADVANCED_SEARCH", new FlagDefinition(false, "Advanced search", "BACKEND")
        );
        service = new FeatureFlagService(new FeatureFlagProperties(flags));
    }

    @Test
    void returnsAllFlags() {
        assertThat(service.getAllFlags()).hasSize(2);
    }

    @Test
    void reflectsDefaultEnabledState() {
        assertThat(service.isEnabled("GENERAL_DARK_MODE")).isTrue();
        assertThat(service.isEnabled("BACKEND_ADVANCED_SEARCH")).isFalse();
    }

    @Test
    void toggleChangesState() {
        service.toggle("GENERAL_DARK_MODE");
        assertThat(service.isEnabled("GENERAL_DARK_MODE")).isFalse();
    }

    @Test
    void runtimeOverrideShadowsDefault() {
        service.setEnabled("BACKEND_ADVANCED_SEARCH", true);
        assertThat(service.isEnabled("BACKEND_ADVANCED_SEARCH")).isTrue();
    }

    @Test
    void resetRestoresDefaults() {
        service.setEnabled("GENERAL_DARK_MODE", false);
        service.resetToDefaults();
        assertThat(service.isEnabled("GENERAL_DARK_MODE")).isTrue();
    }

    @Test
    void filtersByScopeIncludingGeneral() {
        var backendFlags = service.getFlagsByScope(FlagScope.BACKEND);
        assertThat(backendFlags).extracting("scope")
            .containsOnly(FlagScope.GENERAL, FlagScope.BACKEND);
    }
}
