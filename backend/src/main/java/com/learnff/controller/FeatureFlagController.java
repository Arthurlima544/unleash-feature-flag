package com.learnff.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.learnff.model.FeatureFlag;
import com.learnff.model.FeatureFlag.FlagScope;
import com.learnff.service.FeatureFlagService;

@RestController
@RequestMapping("/api/flags")
public class FeatureFlagController {

    private final FeatureFlagService flagService;

    public FeatureFlagController(FeatureFlagService flagService) {
        this.flagService = flagService;
    }

    @GetMapping
    public List<FeatureFlag> getAllFlags() {
        return flagService.getAllFlags();
    }

    @GetMapping("/scope/{scope}")
    public List<FeatureFlag> getFlagsByScope(@PathVariable String scope) {
        FlagScope flagScope = FlagScope.valueOf(scope.toUpperCase());
        return flagService.getFlagsByScope(flagScope);
    }

    @GetMapping("/{key}")
    public ResponseEntity<FeatureFlag> getFlag(@PathVariable String key) {
        return flagService.getFlag(key)
            .map(ResponseEntity::ok)
            .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{key}/enabled")
    public Map<String, Object> isFlagEnabled(@PathVariable String key) {
        return Map.of("key", key, "enabled", flagService.isEnabled(key));
    }

    @PostMapping("/{key}/toggle")
    public FeatureFlag toggleFlag(@PathVariable String key) {
        return flagService.toggle(key);
    }

    @PutMapping("/{key}")
    public FeatureFlag setFlag(@PathVariable String key, @RequestBody Map<String, Boolean> body) {
        boolean enabled = body.getOrDefault("enabled", false);
        return flagService.setEnabled(key, enabled);
    }

    @PostMapping("/reset")
    public Map<String, String> resetToDefaults() {
        flagService.resetToDefaults();
        return Map.of("status", "All flags reset to defaults from application.yml");
    }
}
