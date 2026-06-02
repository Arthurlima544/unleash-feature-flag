package com.learnff.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import io.getunleash.DefaultUnleash;
import io.getunleash.Unleash;
import io.getunleash.util.UnleashConfig;

@Configuration
@Profile("unleash")
public class UnleashConfiguration {

    @Bean
    public Unleash unleashClient(
        @Value("${unleash.api-url}") String apiUrl,
        @Value("${unleash.client-key}") String clientKey,
        @Value("${unleash.app-name}") String appName
    ) {
        var config = new UnleashConfig.Builder()
            .appName(appName)
            .instanceId(appName + "-" + ProcessHandle.current().pid())
            .unleashAPI(apiUrl)
            .apiKey(clientKey)
            .synchronousFetchOnInitialisation(true)
            .build();

        return new DefaultUnleash(config);
    }
}
