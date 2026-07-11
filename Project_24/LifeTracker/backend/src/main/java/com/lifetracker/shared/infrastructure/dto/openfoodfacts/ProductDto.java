package com.lifetracker.shared.infrastructure.dto.openfoodfacts;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

@JsonIgnoreProperties(ignoreUnknown = true)
public record ProductDto(

        @JsonProperty("product_name")
        String productName,

        String brands,

        @JsonProperty("image_front_url")
        String imageFrontUrl,

        @JsonProperty("serving_size")
        String servingSize,

        @JsonProperty("serving_quantity")
        Double servingQuantity,

        @JsonProperty("serving_quantity_unit")
        String servingQuantityUnit,

        NutrimentsDto nutriments

) {}
