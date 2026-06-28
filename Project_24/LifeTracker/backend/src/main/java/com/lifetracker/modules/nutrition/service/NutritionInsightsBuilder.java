package com.lifetracker.modules.nutrition.service;

import com.lifetracker.modules.meals.dto.MealResponse;
import com.lifetracker.modules.nutrition.dto.MacroProgressItem;
import com.lifetracker.modules.nutrition.dto.NutritionGoalsResponse;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;

@Component
public class NutritionInsightsBuilder {

    public List<String> build(
            NutritionGoalsResponse goals,
            List<MacroProgressItem> progress,
            List<MealResponse> meals
    ) {
        List<String> insights = new ArrayList<>();
        MacroProgressItem calories = findProgress(progress, "CALORIES");
        MacroProgressItem protein = findProgress(progress, "PROTEIN");
        MacroProgressItem fiber = findProgress(progress, "FIBER");

        if (meals.isEmpty()) {
            insights.add("Start logging meals to track your daily nutrition.");
            return insights;
        }

        if (protein != null && protein.consumed().compareTo(goals.proteinGoal()) >= 0) {
            insights.add("Protein goal achieved.");
        }

        if (fiber != null && goals.fiberGoal().compareTo(BigDecimal.ZERO) > 0) {
            BigDecimal fiberThreshold = goals.fiberGoal().multiply(new BigDecimal("0.5"));
            if (fiber.consumed().compareTo(fiberThreshold) < 0) {
                insights.add("Fiber intake is low.");
            }
        }

        if (calories != null && calories.remaining().compareTo(BigDecimal.ZERO) > 0) {
            insights.add("You still need " + calories.remaining().setScale(0, RoundingMode.HALF_UP) + " kcal.");
        }

        if (calories != null
                && calories.consumed().compareTo(goals.calorieGoal()) <= 0
                && calories.consumed().compareTo(BigDecimal.ZERO) > 0) {
            insights.add("Great job staying below your calorie goal.");
        }

        if (calories != null && calories.consumed().compareTo(goals.calorieGoal()) > 0) {
            insights.add("You've exceeded your calorie goal today.");
        }

        MacroProgressItem carbs = findProgress(progress, "CARBS");
        if (carbs != null && carbs.consumed().compareTo(goals.carbsGoal()) >= 0) {
            insights.add("Carbohydrate goal reached.");
        }

        if (insights.isEmpty()) {
            insights.add("Keep going — you're making steady progress today.");
        }

        return insights;
    }

    private MacroProgressItem findProgress(List<MacroProgressItem> progress, String key) {
        return progress.stream()
                .filter(item -> key.equals(item.key()))
                .findFirst()
                .orElse(null);
    }
}
