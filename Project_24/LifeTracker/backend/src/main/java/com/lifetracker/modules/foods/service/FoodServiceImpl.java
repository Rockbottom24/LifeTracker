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
        String barcode = normalizeBarcode(request.barcode());
        ensureBarcodeAvailable(barcode, null);
        FoodItem food = foodMapper.toEntity(request, currentUserService.getCurrentUserId());
        food.setBarcode(barcode);
        return foodMapper.toResponse(foodItemRepository.save(food));
    }

    @Override
    public FoodResponse updateFood(Long id, UpdateFoodRequest request) {
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
                food.getFiber().doubleValue()
        );
    }

    private ScannedFoodResponse toScannedFoodResponse(ProductDto product, String barcode) {
        NutrimentsDto nutriments = product.nutriments();
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
                nutriments != null ? nullToZero(nutriments.fiber()) : 0.0
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
}
