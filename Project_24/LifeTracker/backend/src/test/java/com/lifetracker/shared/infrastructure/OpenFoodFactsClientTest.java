package com.lifetracker.shared.infrastructure;

import com.lifetracker.shared.infrastructure.client.OpenFoodFactsClient;
import com.lifetracker.shared.infrastructure.dto.openfoodfacts.OpenFoodFactsResponse;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertNotNull;

class OpenFoodFactsClientTest {

    @Test
    void shouldFetchProduct() throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(0), 0);
        try {
            server.createContext("/api/v2/product/3017620422003.json", this::handleProduct);
            server.start();

            int port = server.getAddress().getPort();
            OpenFoodFactsClient client = new OpenFoodFactsClient("http://localhost:" + port + "/api/v2");
            OpenFoodFactsResponse response = client.lookup("3017620422003");

            assertNotNull(response);
            assertNotNull(response.product());
        } finally {
            server.stop(0);
        }
    }

    private void handleProduct(HttpExchange exchange) throws IOException {
        byte[] body = """
                {
                  "code": "3017620422003",
                  "product": {
                    "product_name": "Nutella",
                    "brands": "Ferrero",
                    "image_front_url": "https://example.com/nutella.jpg",
                    "nutriments": {
                      "energy-kcal_100g": 530,
                      "proteins_100g": 6,
                      "carbohydrates_100g": 57,
                      "fat_100g": 31,
                      "fiber_100g": 3
                    }
                  }
                }
                """.getBytes(StandardCharsets.UTF_8);

        exchange.getResponseHeaders().add("Content-Type", "application/json");
        exchange.sendResponseHeaders(200, body.length);
        try (OutputStream outputStream = exchange.getResponseBody()) {
            outputStream.write(body);
        }
    }
}
