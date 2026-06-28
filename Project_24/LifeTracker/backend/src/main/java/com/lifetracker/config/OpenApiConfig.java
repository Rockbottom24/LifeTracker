package com.lifetracker.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {
    @Bean
    public OpenAPI lifeTrackerOpenAPI() {
        return new OpenAPI()
                .info(new Info()
                        .title("LifeTracker API")
                        .description("Backend skeleton for the LifeTracker offline-first application")
                        .version("1.0.0"));
    }
}
