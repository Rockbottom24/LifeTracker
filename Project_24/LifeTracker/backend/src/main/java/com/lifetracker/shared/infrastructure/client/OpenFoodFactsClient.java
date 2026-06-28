package com.lifetracker.shared.infrastructure.client;

import com.lifetracker.shared.infrastructure.dto.openfoodfacts.OpenFoodFactsResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

@Component
public class OpenFoodFactsClient {

    private final RestClient restClient;

    public OpenFoodFactsClient(
            @Value("${lifetracker.openfoodfacts.base-url:https://world.openfoodfacts.org/api/v2}") String baseUrl
    ) {
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .build();
    }

    public OpenFoodFactsResponse lookup(String barcode) {
        try {
            return restClient.get()
                    .uri("/product/{barcode}.json", barcode)
                    .retrieve()
                    .body(OpenFoodFactsResponse.class);
        } catch (RestClientException ex) {
            return null;
        }
    }
}
