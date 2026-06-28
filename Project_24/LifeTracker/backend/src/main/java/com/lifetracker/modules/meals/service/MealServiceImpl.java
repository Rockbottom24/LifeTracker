package com.lifetracker.modules.meals.service;

import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.foods.entity.FoodItem;
import com.lifetracker.modules.foods.repository.FoodItemRepository;
import com.lifetracker.modules.meals.dto.CreateMealRequest;
import com.lifetracker.modules.meals.dto.MealItemRequest;
import com.lifetracker.modules.meals.dto.MealResponse;
import com.lifetracker.modules.meals.dto.MealItemRequest;
import com.lifetracker.modules.meals.dto.UpdateMealRequest;
import com.lifetracker.modules.meals.entity.MealLog;
import com.lifetracker.modules.meals.entity.MealLogItem;
import com.lifetracker.modules.meals.enums.MealType;
import com.lifetracker.modules.meals.mapper.MealMapper;
import com.lifetracker.modules.meals.repository.MealLogItemRepository;
import com.lifetracker.modules.meals.repository.MealLogRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@Transactional
public class MealServiceImpl implements MealService {
    private final MealLogRepository mealLogRepository;
    private final MealLogItemRepository mealLogItemRepository;
    private final FoodItemRepository foodItemRepository;
    private final MealMapper mealMapper;
    private final CurrentUserService currentUserService;

    public MealServiceImpl(
            MealLogRepository mealLogRepository,
            MealLogItemRepository mealLogItemRepository,
            FoodItemRepository foodItemRepository,
            MealMapper mealMapper,
            CurrentUserService currentUserService
    ) {
        this.mealLogRepository = mealLogRepository;
        this.mealLogItemRepository = mealLogItemRepository;
        this.foodItemRepository = foodItemRepository;
        this.mealMapper = mealMapper;
        this.currentUserService = currentUserService;
    }

    @Override
    @Transactional(readOnly = true)
    public List<MealResponse> getMealsForToday() {
        return getMealsForDate(LocalDate.now());
    }

    @Override
    @Transactional(readOnly = true)
    public List<MealResponse> getMealsForDate(LocalDate date) {
        Long userId = currentUserService.getCurrentUserId();
        List<MealLog> meals = mealLogRepository.findByOwnerUserIdAndMealDateOrderByMealTypeAscCreatedAtAsc(userId, date);
        return buildResponses(meals, userId);
    }

    @Override
    @Transactional(readOnly = true)
    public MealResponse getMealById(Long id) {
        MealLog meal = findMealOrThrow(id);
        return buildResponse(meal);
    }

    @Override
    public MealResponse createMeal(CreateMealRequest request) {
        Long userId = currentUserService.getCurrentUserId();
        Map<Long, FoodItem> foodsById = resolveFoods(request.items(), userId);

        MealLog meal = mealMapper.toEntity(request, userId);
        MealLog savedMeal = mealLogRepository.save(meal);

        List<MealLogItem> items = mealMapper.toItems(savedMeal.getId(), request.items(), foodsById);
        if (items.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "At least one valid food item is required");
        }
        mealLogItemRepository.saveAll(items);

        return mealMapper.toResponse(savedMeal, items, foodsById);
    }

    @Override
    public MealResponse updateMeal(Long id, UpdateMealRequest request) {
        Long userId = currentUserService.getCurrentUserId();
        MealLog meal = findMealOrThrow(id);
        Map<Long, FoodItem> foodsById = resolveFoods(request.items(), userId);

        mealMapper.updateEntity(meal, request);
        mealLogRepository.save(meal);

        mealLogItemRepository.deleteByMealLogId(meal.getId());
        List<MealLogItem> items = mealMapper.toItems(meal.getId(), request.items(), foodsById);
        if (items.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "At least one valid food item is required");
        }
        mealLogItemRepository.saveAll(items);

        return mealMapper.toResponse(meal, items, foodsById);
    }

    @Override
    public void deleteMeal(Long id) {
        MealLog meal = findMealOrThrow(id);
        mealLogItemRepository.deleteByMealLogId(meal.getId());
        mealLogRepository.delete(meal);
    }

    @Override
    public List<MealResponse> duplicateYesterday(MealType mealType, LocalDate targetDate) {
        Long userId = currentUserService.getCurrentUserId();
        LocalDate sourceDate = targetDate.minusDays(1);
        List<MealLog> sourceMeals = mealLogRepository.findByOwnerUserIdAndMealDateAndMealTypeOrderByCreatedAtAsc(
                userId,
                sourceDate,
                mealType
        );

        if (sourceMeals.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "No meals found to duplicate from yesterday");
        }

        List<MealResponse> duplicated = new ArrayList<>();
        for (MealLog sourceMeal : sourceMeals) {
            List<MealLogItem> sourceItems = mealLogItemRepository.findByMealLogIdOrderByDisplayOrderAscIdAsc(sourceMeal.getId());
            List<MealItemRequest> itemRequests = sourceItems.stream()
                    .map(item -> new MealItemRequest(item.getFoodItemId(), item.getQuantity(), item.getUnit()))
                    .toList();

            duplicated.add(createMeal(new CreateMealRequest(
                    mealType,
                    targetDate,
                    sourceMeal.getNotes(),
                    itemRequests
            )));
        }
        return duplicated;
    }

    @Override
    public void clearMealsForType(MealType mealType, LocalDate date) {
        Long userId = currentUserService.getCurrentUserId();
        List<MealLog> meals = mealLogRepository.findByOwnerUserIdAndMealDateAndMealTypeOrderByCreatedAtAsc(
                userId,
                date,
                mealType
        );
        for (MealLog meal : meals) {
            mealLogItemRepository.deleteByMealLogId(meal.getId());
            mealLogRepository.delete(meal);
        }
    }

    private MealLog findMealOrThrow(Long id) {
        return mealLogRepository.findByIdAndOwnerUserId(id, currentUserService.getCurrentUserId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Meal not found"));
    }

    private List<MealResponse> buildResponses(List<MealLog> meals, Long userId) {
        if (meals.isEmpty()) {
            return List.of();
        }

        Map<Long, List<MealLogItem>> itemsByMealId = loadItemsByMealId(meals);
        Map<Long, FoodItem> foodsById = loadFoods(itemsByMealId, userId);
        return mealMapper.toResponseList(meals, itemsByMealId, foodsById);
    }

    private MealResponse buildResponse(MealLog meal) {
        List<MealLogItem> items = mealLogItemRepository.findByMealLogIdOrderByDisplayOrderAscIdAsc(meal.getId());
        Map<Long, FoodItem> foodsById = loadFoods(Map.of(meal.getId(), items), meal.getOwnerUserId());
        return mealMapper.toResponse(meal, items, foodsById);
    }

    private Map<Long, List<MealLogItem>> loadItemsByMealId(List<MealLog> meals) {
        Map<Long, List<MealLogItem>> itemsByMealId = new HashMap<>();
        for (MealLog meal : meals) {
            itemsByMealId.put(
                    meal.getId(),
                    mealLogItemRepository.findByMealLogIdOrderByDisplayOrderAscIdAsc(meal.getId())
            );
        }
        return itemsByMealId;
    }

    private Map<Long, FoodItem> loadFoods(Map<Long, List<MealLogItem>> itemsByMealId, Long userId) {
        Set<Long> foodIds = itemsByMealId.values().stream()
                .flatMap(List::stream)
                .map(MealLogItem::getFoodItemId)
                .collect(Collectors.toCollection(HashSet::new));

        Map<Long, FoodItem> foodsById = new HashMap<>();
        for (Long foodId : foodIds) {
            foodItemRepository.findVisibleById(foodId, userId)
                    .ifPresent(food -> foodsById.put(foodId, food));
        }
        return foodsById;
    }

    private Map<Long, FoodItem> resolveFoods(List<MealItemRequest> items, Long userId) {
        Map<Long, FoodItem> foodsById = new HashMap<>();
        for (MealItemRequest item : items) {
            FoodItem food = foodItemRepository.findVisibleById(item.foodItemId(), userId)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.BAD_REQUEST,
                            "Food not found or not accessible: " + item.foodItemId()
                    ));
            foodsById.put(food.getId(), food);
        }
        return foodsById;
    }
}
