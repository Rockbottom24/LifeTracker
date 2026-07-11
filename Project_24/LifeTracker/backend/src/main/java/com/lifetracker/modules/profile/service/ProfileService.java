package com.lifetracker.modules.profile.service;

import com.lifetracker.modules.auth.entity.AppUser;
import com.lifetracker.modules.auth.security.CurrentUserService;
import com.lifetracker.modules.habitlogs.entity.HabitLog;
import com.lifetracker.modules.habitlogs.repository.HabitLogRepository;
import com.lifetracker.modules.habits.entity.Habit;
import com.lifetracker.modules.habits.repository.HabitRepository;
import com.lifetracker.modules.meals.entity.MealLog;
import com.lifetracker.modules.meals.entity.MealLogItem;
import com.lifetracker.modules.meals.repository.MealLogItemRepository;
import com.lifetracker.modules.meals.repository.MealLogRepository;
import com.lifetracker.modules.nutrition.dto.NutritionGoalsResponse;
import com.lifetracker.modules.nutrition.service.NutritionGoalsService;
import com.lifetracker.modules.profile.dto.DailyPerformanceResponse;
import com.lifetracker.modules.profile.dto.ProfileResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@Transactional(readOnly = true)
public class ProfileService {
    private final CurrentUserService currentUserService;
    private final HabitRepository habitRepository;
    private final HabitLogRepository habitLogRepository;
    private final MealLogRepository mealLogRepository;
    private final MealLogItemRepository mealLogItemRepository;
    private final NutritionGoalsService nutritionGoalsService;

    public ProfileService(
            CurrentUserService currentUserService,
            HabitRepository habitRepository,
            HabitLogRepository habitLogRepository,
            MealLogRepository mealLogRepository,
            MealLogItemRepository mealLogItemRepository,
            NutritionGoalsService nutritionGoalsService
    ) {
        this.currentUserService = currentUserService;
        this.habitRepository = habitRepository;
        this.habitLogRepository = habitLogRepository;
        this.mealLogRepository = mealLogRepository;
        this.mealLogItemRepository = mealLogItemRepository;
        this.nutritionGoalsService = nutritionGoalsService;
    }

    public ProfileResponse getProfile() {
        AppUser user = currentUserService.getCurrentUser();
        String houseKey = normalizeHouseKey(user.getHouseKey());
        LocalDate today = LocalDate.now(ZoneId.systemDefault());
        List<ProfileResponse.DailyPerformanceSummary> recent = new ArrayList<>();
        int sevenDayHonor = 0;
        BigDecimal completionSum = BigDecimal.ZERO;
        int countedDays = 0;

        for (int offset = 0; offset < 14; offset++) {
            LocalDate date = today.minusDays(offset);
            ProfileResponse.DailyPerformanceSummary day = summarizeDay(user.getId(), date);
            if (offset < 7) {
                sevenDayHonor += day.earnedPoints();
                completionSum = completionSum.add(day.completionPercentage());
                countedDays++;
            }
            recent.add(day);
        }

        BigDecimal sevenDayCompletion = countedDays == 0
                ? BigDecimal.ZERO
                : completionSum.divide(BigDecimal.valueOf(countedDays), 2, RoundingMode.HALF_UP);

        int currentStreak = 0;
        int longestStreak = 0;
        int running = 0;
        for (int offset = 59; offset >= 0; offset--) {
            LocalDate date = today.minusDays(offset);
            ProfileResponse.DailyPerformanceSummary day = summarizeDay(user.getId(), date);
            boolean full = day.plannedHabits() > 0 && day.completedHabits() >= day.plannedHabits();
            if (full) {
                running++;
                longestStreak = Math.max(longestStreak, running);
            } else {
                running = 0;
            }
        }
        for (int offset = 0; offset < 60; offset++) {
            LocalDate date = today.minusDays(offset);
            ProfileResponse.DailyPerformanceSummary day = summarizeDay(user.getId(), date);
            if (day.plannedHabits() > 0 && day.completedHabits() >= day.plannedHabits()) {
                currentStreak++;
            } else {
                break;
            }
        }
        longestStreak = Math.max(longestStreak, currentStreak);

        String firstName = user.getFirstName() == null || user.getFirstName().isBlank()
                ? (user.getDisplayName() == null ? "Traveler" : user.getDisplayName())
                : user.getFirstName().trim();

        return new ProfileResponse(
                user.getId(),
                user.getEmail(),
                firstName,
                houseKey,
                houseDisplayName(houseKey),
                houseMotto(houseKey),
                new ProfileResponse.PerformanceSummary(sevenDayHonor, sevenDayCompletion, currentStreak, longestStreak),
                recent
        );
    }

    public DailyPerformanceResponse getDailyPerformance(LocalDate date) {
        Long userId = currentUserService.getCurrentUserId();
        ProfileResponse.DailyPerformanceSummary summary = summarizeDay(userId, date);

        List<Habit> habits = habitsForPerformanceDay(userId, date);
        Map<Long, HabitLog> latestLogs = latestLogsForDate(habits, date);

        List<DailyPerformanceResponse.HabitPerformanceItem> habitItems = habits.stream()
                .map(habit -> {
                    HabitLog log = latestLogs.get(habit.getId());
                    boolean completed = log != null && "completed".equalsIgnoreCase(log.getCompletionStatus());
                    int configuredPoints = completed && log != null
                            ? log.getPointsAwarded()
                            : habit.getPoints();
                    return new DailyPerformanceResponse.HabitPerformanceItem(
                            habit.getId(),
                            habit.getName(),
                            completed,
                            configuredPoints,
                            completed && log != null ? log.getPointsAwarded() : 0
                    );
                })
                .toList();

        List<MealLog> meals = mealLogRepository.findByOwnerUserIdAndMealDateOrderByMealTypeAscCreatedAtAsc(userId, date);
        List<DailyPerformanceResponse.MealPerformanceItem> mealItems = new ArrayList<>();
        BigDecimal calories = BigDecimal.ZERO;
        BigDecimal protein = BigDecimal.ZERO;
        BigDecimal carbs = BigDecimal.ZERO;
        BigDecimal fat = BigDecimal.ZERO;
        BigDecimal fiber = BigDecimal.ZERO;

        for (MealLog meal : meals) {
            List<MealLogItem> items = mealLogItemRepository.findByMealLogIdOrderByDisplayOrderAscIdAsc(meal.getId());
            BigDecimal mealCalories = sum(items, MealLogItem::getCalories);
            BigDecimal mealProtein = sum(items, MealLogItem::getProtein);
            BigDecimal mealCarbs = sum(items, MealLogItem::getCarbs);
            BigDecimal mealFat = sum(items, MealLogItem::getFat);
            BigDecimal mealFiber = sum(items, MealLogItem::getFiber);
            calories = calories.add(mealCalories);
            protein = protein.add(mealProtein);
            carbs = carbs.add(mealCarbs);
            fat = fat.add(mealFat);
            fiber = fiber.add(mealFiber);
            mealItems.add(new DailyPerformanceResponse.MealPerformanceItem(
                    meal.getId(),
                    meal.getMealType() == null ? "MEAL" : meal.getMealType().name(),
                    mealCalories,
                    mealProtein,
                    mealCarbs,
                    mealFat,
                    mealFiber
            ));
        }

        NutritionGoalsResponse goals = nutritionGoalsService.getGoals();

        return new DailyPerformanceResponse(
                date,
                summary.earnedPoints(),
                summary.possiblePoints(),
                summary.completionPercentage(),
                summary.completedHabits(),
                summary.plannedHabits(),
                habitItems,
                new DailyPerformanceResponse.NutritionPerformance(
                        calories,
                        goals.calorieGoal(),
                        protein,
                        carbs,
                        fat,
                        fiber,
                        mealItems
                )
        );
    }

    private ProfileResponse.DailyPerformanceSummary summarizeDay(Long userId, LocalDate date) {
        List<Habit> habits = habitsForPerformanceDay(userId, date);
        Map<Long, HabitLog> latestLogs = latestLogsForDate(habits, date);
        int planned = habits.size();
        int completed = 0;
        int earned = 0;
        int possible = 0;
        for (Habit habit : habits) {
            HabitLog log = latestLogs.get(habit.getId());
            if (log != null && "completed".equalsIgnoreCase(log.getCompletionStatus())) {
                completed++;
                earned += log.getPointsAwarded();
                // Historical possible for completed habits uses the snapshot, not today's edited value.
                possible += log.getPointsAwarded();
            } else {
                possible += habit.getPoints();
            }
        }
        BigDecimal percentage = planned == 0
                ? BigDecimal.ZERO
                : BigDecimal.valueOf(completed)
                .multiply(BigDecimal.valueOf(100))
                .divide(BigDecimal.valueOf(planned), 2, RoundingMode.HALF_UP);
        return new ProfileResponse.DailyPerformanceSummary(date, earned, possible, percentage, completed, planned);
    }

    /**
     * Active habits plus any inactive habits that have a log on the date,
     * so deleted/deactivated habits remain visible in historical chronicles.
     */
    private List<Habit> habitsForPerformanceDay(Long userId, LocalDate date) {
        List<Habit> allHabits = habitRepository.findAllByUserId(userId);
        Map<Long, HabitLog> logsForAll = latestLogsForDate(allHabits, date);
        List<Habit> relevant = allHabits.stream()
                .filter(habit -> habit.isActive() || logsForAll.containsKey(habit.getId()))
                .sorted(Comparator.comparingInt(Habit::getDisplayOrder).thenComparing(Habit::getName))
                .collect(Collectors.toList());
        return relevant;
    }

    private Map<Long, HabitLog> latestLogsForDate(List<Habit> habits, LocalDate date) {
        if (habits.isEmpty()) {
            return Map.of();
        }
        List<Long> ids = habits.stream().map(Habit::getId).toList();
        LocalDateTime start = date.atStartOfDay();
        LocalDateTime end = date.plusDays(1).atStartOfDay();
        List<HabitLog> logs = habitLogRepository.findByHabitIdInAndLoggedAtBetweenOrderByLoggedAtDescIdDesc(ids, start, end);
        Map<Long, HabitLog> latest = new LinkedHashMap<>();
        for (HabitLog log : logs) {
            latest.putIfAbsent(log.getHabitId(), log);
        }
        return latest;
    }

    private BigDecimal sum(List<MealLogItem> items, java.util.function.Function<MealLogItem, BigDecimal> extractor) {
        return items.stream()
                .map(extractor)
                .filter(java.util.Objects::nonNull)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private String normalizeHouseKey(String houseKey) {
        if (houseKey == null || houseKey.isBlank()) {
            return "stark";
        }
        return houseKey.trim().toLowerCase(Locale.ENGLISH);
    }

    private String houseDisplayName(String houseKey) {
        return switch (houseKey) {
            case "targaryen" -> "Targaryen";
            case "lannister" -> "Lannister";
            case "baratheon" -> "Baratheon";
            case "greyjoy" -> "Greyjoy";
            case "martell" -> "Martell";
            case "tyrell" -> "Tyrell";
            case "arryn" -> "Arryn";
            case "tully" -> "Tully";
            default -> "Stark";
        };
    }

    private String houseMotto(String houseKey) {
        return switch (houseKey) {
            case "targaryen" -> "Fire and Blood";
            case "lannister" -> "Hear Me Roar";
            case "baratheon" -> "Ours is the Fury";
            case "greyjoy" -> "We Do Not Sow";
            case "martell" -> "Unbowed, Unbent, Unbroken";
            case "tyrell" -> "Growing Strong";
            case "arryn" -> "As High as Honor";
            case "tully" -> "Family, Duty, Honor";
            default -> "Winter is Coming";
        };
    }
}
