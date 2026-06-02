package com.learnff;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

import com.learnff.config.FeatureFlagProperties;

@SpringBootApplication
@EnableConfigurationProperties(FeatureFlagProperties.class)
public class LearnFeatureFlagsApplication {

    public static void main(String[] args) {
        SpringApplication.run(LearnFeatureFlagsApplication.class, args);
    }
}
