package com.lifetracker.modules.foods.service;

import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.foods.dto.BarcodeLookupResponse;
import com.lifetracker.modules.foods.dto.CreateFoodRequest;
import com.lifetracker.modules.foods.dto.FoodResponse;
import com.lifetracker.modules.foods.dto.ScannedFoodResponse;
import com.lifetracker.modules.foods.dto.UpdateFoodRequest;
import com.lifetracker.modules.foods.entity.FoodItem;
import com.lifetracker.modules.foods.mapper.FoodMapper;
import com.lifetracker.modules.foods.repository.FoodItemRepository;
import com.lifetracker.modules.foods.dto.CreateFoodRequest;
import com.lifetracker.modules.foods.dto.UpdateFoodRequest;
import com.lifetracker.modules.foods.mapper.FoodMapper;
import com.lifetracker.modules.foods.service.ServingSizeParser;
import com.lifetracker.modules.meals.service.MealNutritionCalculator;
import com.lifetracker.shared.infrastructure.client.OpenFoodFactsClient;
import com.lifetracker.shared.infrastructure.dto.openfoodfacts.NutrimentsDto;
import com.lifetracker.shared.infrastructure.dto.openfoodfacts.OpenFoodFactsResponse;
import com.lifetracker.shared.infrastructure.dto.openfoodfacts.ProductDto;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class FoodServiceImpl implements FoodService {
    private final FoodItemRepository foodItemRepository;
    private final FoodMapper foodMapper;
    private final CurrentUserService currentUserService;
    private final OpenFoodFactsClient openFoodFactsClient;

    public FoodServiceImpl(
            FoodItemRepository foodItemRepository,
            FoodMapper foodMapper,
            CurrentUserService currentUserService,
            OpenFoodFactsClient openFoodFactsClient
    ) {
        this.foodItemRepository = foodItemRepository;
        this.foodMapper = foodMapper;
        this.currentUserService = currentUserService;
        this.openFoodFactsClient = openFoodFactsClient;
    }

    @Override
    @Transactional(readOnly = true)
    public List<FoodResponse> getAllFoods() {
        return foodMapper.toResponseList(foodItemRepository.findAllVisible(currentUserService.getCurrentUserId()));
    }

    @Override
    @Transactional(readOnly = true)
    public List<FoodResponse> searchFoods(String query) {
        String normalized = query == null ? "" : query.trim();
        if (normalized.isEmpty()) {
            return getAllFoods();
        }
        return foodMapper.toResponseList(
                foodItemRepository.searchVisible(currentUserService.getCurrentUserId(), normalized)
        );
    }

    @Override
    @Transactional(readOnly = true)
    public FoodResponse getFoodById(Long id) {
        return foodMapper.toResponse(findVisibleFoodOrThrow(id));
    }

    @Override
    public FoodResponse createFood(CreateFoodRequest request) {
        validateNutritionConfig(request);
        String barcode = normalizeBarcode(request.barcode());
        ensureBarcodeAvailable(barcode, null);
        FoodItem food = foodMapper.toEntity(request, currentUserService.getCurrentUserId());
        food.setBarcode(barcode);
        return foodMapper.toResponse(foodItemRepository.save(food));
    }

    @Override
    public FoodResponse updateFood(Long id, UpdateFoodRequest request) {
        validateNutritionConfig(request);
        FoodItem food = findEditableFoodOrThrow(id);
        String barcode = normalizeBarcode(request.barcode());
        ensureBarcodeAvailable(barcode, food.getId());
        foodMapper.updateEntity(food, request);
        if (request.barcode() != null) {
            food.setBarcode(barcode);
        }
        return foodMapper.toResponse(foodItemRepository.save(food));
    }

    @Override
    public void deleteFood(Long id) {
        FoodItem food = findEditableFoodOrThrow(id);
        food.setActive(false);
        foodItemRepository.save(food);
    }

    private FoodItem findVisibleFoodOrThrow(Long id) {
        return foodItemRepository.findVisibleById(id, currentUserService.getCurrentUserId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Food not found"));
    }

    private FoodItem findEditableFoodOrThrow(Long id) {
        FoodItem food = findVisibleFoodOrThrow(id);
        if (food.isSystem()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "System foods cannot be modified");
        }
        if (!currentUserService.getCurrentUserId().equals(food.getOwnerUserId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "You cannot modify this food");
        }
        return food;
    }

    @Override
    @Transactional(readOnly = true)
    public BarcodeLookupResponse lookupBarcode(String barcode) {
        String normalizedBarcode = barcode == null ? "" : barcode.trim();
        if (normalizedBarcode.isEmpty()) {
            return new BarcodeLookupResponse(normalizedBarcode, false, null, false, null);
        }

        Optional<FoodItem> local = foodItemRepository.findByBarcode(normalizedBarcode);
        if (local.isPresent()) {
            FoodItem food = local.get();
            return new BarcodeLookupResponse(
                    normalizedBarcode,
                    true,
                    food.getId(),
                    true,
                    toScannedFoodResponse(food, normalizedBarcode)
            );
        }

        OpenFoodFactsResponse remote = openFoodFactsClient.lookup(normalizedBarcode);
        if (remote == null || remote.product() == null) {
            return new BarcodeLookupResponse(normalizedBarcode, false, null, false, null);
        }

        return new BarcodeLookupResponse(
                normalizedBarcode,
                true,
                null,
                false,
                toScannedFoodResponse(remote.product(), normalizedBarcode)
        );
    }

    private ScannedFoodResponse toScannedFoodResponse(FoodItem food, String barcode) {
        var context = FoodMapper.toConversionContext(food);
        return new ScannedFoodResponse(
                food.getId(),
                true,
                barcode,
                food.getName(),
                nullToEmpty(food.getBrand()),
                nullToEmpty(food.getImageUrl()),
                food.getCalories().doubleValue(),
                food.getProtein().doubleValue(),
                food.getCarbs().doubleValue(),
                food.getFat().doubleValue(),
                food.getFiber().doubleValue(),
                null,
                food.getServingUnit(),
                food.getReferenceQuantity() == null ? null : food.getReferenceQuantity().doubleValue(),
                food.getReferenceWeight() == null ? null : food.getReferenceWeight().doubleValue(),
                food.getGramsPerPiece() == null ? null : food.getGramsPerPiece().doubleValue(),
                food.getHouseholdUnit(),
                food.getHouseholdQuantity() == null ? null : food.getHouseholdQuantity().doubleValue(),
                food.getHouseholdGrams() == null ? null : food.getHouseholdGrams().doubleValue(),
                context.supportedUnits()
        );
    }

    private ScannedFoodResponse toScannedFoodResponse(ProductDto product, String barcode) {
        NutrimentsDto nutriments = product.nutriments();
        var parsed = ServingSizeParser.parse(
                product.servingSize(),
                product.servingQuantity(),
                product.servingQuantityUnit()
        );

        java.math.BigDecimal referenceQuantity = java.math.BigDecimal.valueOf(100);
        java.math.BigDecimal referenceWeight = java.math.BigDecimal.valueOf(100);
        com.lifetracker.modules.foods.enums.ServingUnit servingUnit =
                com.lifetracker.modules.foods.enums.ServingUnit.GRAM;
        com.lifetracker.modules.foods.enums.ServingUnit householdUnit = null;
        java.math.BigDecimal householdQuantity = null;
        java.math.BigDecimal householdGrams = null;
        java.math.BigDecimal gramsPerPiece = null;
        String servingSizeText = product.servingSize();

        if (parsed.isPresent()) {
            ServingSizeParser.ParsedServingSize serving = parsed.get();
            if (serving.isHouseholdUnit() && serving.hasGramConversion()) {
                householdUnit = serving.unit();
                householdQuantity = serving.quantity();
                householdGrams = serving.grams();
                if (serving.unit() == com.lifetracker.modules.foods.enums.ServingUnit.PIECE) {
                    gramsPerPiece = serving.grams().divide(serving.quantity(), 4, java.math.RoundingMode.HALF_UP);
                }
            } else if (serving.unit() == com.lifetracker.modules.foods.enums.ServingUnit.GRAM
                    || serving.unit() == com.lifetracker.modules.foods.enums.ServingUnit.KILOGRAM) {
                // Keep canonical per-100g nutrition; plain gram serving does not change basis.
                servingUnit = com.lifetracker.modules.foods.enums.ServingUnit.GRAM;
                referenceQuantity = java.math.BigDecimal.valueOf(100);
                referenceWeight = java.math.BigDecimal.valueOf(100);
            } else if (serving.unit() == com.lifetracker.modules.foods.enums.ServingUnit.ML
                    || serving.unit() == com.lifetracker.modules.foods.enums.ServingUnit.LITER) {
                servingUnit = serving.unit() == com.lifetracker.modules.foods.enums.ServingUnit.LITER
                        ? com.lifetracker.modules.foods.enums.ServingUnit.ML
                        : serving.unit();
                referenceQuantity = serving.unit() == com.lifetracker.modules.foods.enums.ServingUnit.LITER
                        ? serving.quantity().multiply(java.math.BigDecimal.valueOf(1000))
                        : serving.quantity();
                // Without density, treat ml reference weight as equal only for water-like products is unsafe.
                // Keep mass nutrition at 100g and expose volume units only when product is volume-based later.
                servingUnit = com.lifetracker.modules.foods.enums.ServingUnit.GRAM;
                referenceQuantity = java.math.BigDecimal.valueOf(100);
                referenceWeight = java.math.BigDecimal.valueOf(100);
            }
        }

        var context = com.lifetracker.modules.foods.model.FoodConversionContext.of(
                servingUnit,
                referenceQuantity,
                referenceWeight,
                gramsPerPiece,
                householdUnit,
                householdQuantity,
                householdGrams
        );

        return new ScannedFoodResponse(
                null,
                false,
                barcode,
                nullToEmpty(product.productName()),
                nullToEmpty(product.brands()),
                nullToEmpty(product.imageFrontUrl()),
                nutriments != null ? nullToZero(nutriments.calories()) : 0.0,
                nutriments != null ? nullToZero(nutriments.protein()) : 0.0,
                nutriments != null ? nullToZero(nutriments.carbs()) : 0.0,
                nutriments != null ? nullToZero(nutriments.fat()) : 0.0,
                nutriments != null ? nullToZero(nutriments.fiber()) : 0.0,
                servingSizeText,
                servingUnit,
                referenceQuantity.doubleValue(),
                referenceWeight.doubleValue(),
                gramsPerPiece == null ? null : gramsPerPiece.doubleValue(),
                householdUnit,
                householdQuantity == null ? null : householdQuantity.doubleValue(),
                householdGrams == null ? null : householdGrams.doubleValue(),
                context.supportedUnits()
        );
    }

    private static String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private static double nullToZero(Double value) {
        return value == null ? 0.0 : value;
    }

    private String normalizeBarcode(String barcode) {
        if (barcode == null) {
            return null;
        }
        String trimmed = barcode.trim();
        return trimmed.isEmpty() ? null : trimmed;
    }

    private void ensureBarcodeAvailable(String barcode, Long currentFoodId) {
        if (barcode == null) {
            return;
        }

        Optional<FoodItem> existing = foodItemRepository.findByBarcode(barcode);
        if (existing.isPresent() && (currentFoodId == null || !currentFoodId.equals(existing.get().getId()))) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "A food with this barcode already exists");
        }
    }

    private void validateNutritionConfig(
            CreateFoodRequest request
    ) {
        try {
            MealNutritionCalculator.validateFoodConfiguration(
                    FoodMapper.toConversionContext(toTemporaryFood(request))
            );
        } catch (com.lifetracker.modules.meals.exception.NutritionCalculationException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, ex.getMessage());
        }
    }

    private void validateNutritionConfig(UpdateFoodRequest request) {
        try {
            MealNutritionCalculator.validateFoodConfiguration(
                    com.lifetracker.modules.foods.model.FoodConversionContext.of(
                            request.servingUnit(),
                            request.referenceQuantity(),
                            request.referenceWeight(),
                            request.gramsPerPiece(),
                            request.householdUnit(),
                            request.householdQuantity(),
                            request.householdGrams()
                    )
            );
        } catch (com.lifetracker.modules.meals.exception.NutritionCalculationException ex) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, ex.getMessage());
        }
    }

    private FoodItem toTemporaryFood(CreateFoodRequest request) {
        FoodItem food = new FoodItem();
        food.setServingUnit(request.servingUnit());
        food.setReferenceQuantity(request.referenceQuantity());
        food.setReferenceWeight(request.referenceWeight());
        food.setGramsPerPiece(request.gramsPerPiece());
        food.setHouseholdUnit(request.householdUnit());
        food.setHouseholdQuantity(request.householdQuantity());
        food.setHouseholdGrams(request.householdGrams());
        return food;
    }
}
