package com.learnff.controller;

import java.util.List;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import com.learnff.service.FeatureFlagService;

@RestController
@RequestMapping("/api/demo")
public class DemoController {

    private final FeatureFlagService flagService;

    public DemoController(FeatureFlagService flagService) {
        this.flagService = flagService;
    }

    // General feature — used by all clients
    @GetMapping("/notifications")
    public Map<String, Object> getNotifications() {
        if (!flagService.isEnabled("GENERAL_NOTIFICATION_CENTER")) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Notification center is disabled");
        }
        return Map.of(
            "notifications", List.of(
                Map.of("id", 1, "message", "Welcome to the notification center!", "read", false),
                Map.of("id", 2, "message", "Feature flags are working!", "read", true)
            )
        );
    }

    // Backend-specific features
    @GetMapping("/search")
    public Map<String, Object> advancedSearch(@RequestParam(defaultValue = "") String q) {
        if (!flagService.isEnabled("BACKEND_ADVANCED_SEARCH")) {
            return Map.of("results", List.of(), "mode", "basic", "flagDisabled", true);
        }
        return Map.of(
            "results", List.of(
                Map.of("id", 1, "title", "Result for: " + q, "score", 0.95),
                Map.of("id", 2, "title", "Another result", "score", 0.87)
            ),
            "mode", "advanced",
            "filters", List.of("category", "date", "relevance")
        );
    }

    @GetMapping("/recommendations")
    public Map<String, Object> getRecommendations() {
        if (!flagService.isEnabled("BACKEND_AI_RECOMMENDATIONS")) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "AI Recommendations feature is disabled");
        }
        return Map.of(
            "recommendations", List.of(
                Map.of("id", 1, "title", "AI Pick: Learn Feature Flags", "confidence", 0.98),
                Map.of("id", 2, "title", "AI Pick: Spring Boot Best Practices", "confidence", 0.91)
            ),
            "model", "recommendation-v2"
        );
    }

    // Health check with flag summary
    @GetMapping("/status")
    public Map<String, Object> getStatus() {
        return Map.of(
            "service", "learn-feature-flags-backend",
            "status", "UP",
            "activeFlags", flagService.getAllFlags().stream()
                .filter(f -> f.enabled())
                .map(f -> f.key())
                .toList()
        );
    }
}
