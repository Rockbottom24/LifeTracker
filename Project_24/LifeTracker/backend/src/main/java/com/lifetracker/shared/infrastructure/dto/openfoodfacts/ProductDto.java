package com.lifetracker.shared.infrastructure.dto.openfoodfacts;

import com.fasterxml.jackson.annotation.JsonProperty;

public record ProductDto(

        @JsonProperty("product_name")
        String productName,

        String brands,

        @JsonProperty("image_front_url")
        String imageFrontUrl,

        NutrimentsDto nutriments

) {}