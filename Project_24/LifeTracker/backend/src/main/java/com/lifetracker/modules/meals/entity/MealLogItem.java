package com.lifetracker.modules.meals.entity;

import com.lifetracker.modules.foods.enums.ServingUnit;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;

@Entity
@Table(name = "meal_log_items")
public class MealLogItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "meal_log_id", nullable = false)
    private Long mealLogId;

    @Column(name = "food_item_id", nullable = false)
    private Long foodItemId;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal quantity;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private ServingUnit unit;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal calories;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal protein;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal carbs;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal fat;

    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal fiber;

    @Column(name = "display_order", nullable = false)
    private int displayOrder;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getMealLogId() {
        return mealLogId;
    }

    public void setMealLogId(Long mealLogId) {
        this.mealLogId = mealLogId;
    }

    public Long getFoodItemId() {
        return foodItemId;
    }

    public void setFoodItemId(Long foodItemId) {
        this.foodItemId = foodItemId;
    }

    public BigDecimal getQuantity() {
        return quantity;
    }

    public void setQuantity(BigDecimal quantity) {
        this.quantity = quantity;
    }

    public ServingUnit getUnit() {
        return unit;
    }

    public void setUnit(ServingUnit unit) {
        this.unit = unit;
    }

    public BigDecimal getCalories() {
        return calories;
    }

    public void setCalories(BigDecimal calories) {
        this.calories = calories;
    }

    public BigDecimal getProtein() {
        return protein;
    }

    public void setProtein(BigDecimal protein) {
        this.protein = protein;
    }

    public BigDecimal getCarbs() {
        return carbs;
    }

    public void setCarbs(BigDecimal carbs) {
        this.carbs = carbs;
    }

    public BigDecimal getFat() {
        return fat;
    }

    public void setFat(BigDecimal fat) {
        this.fat = fat;
    }

    public BigDecimal getFiber() {
        return fiber;
    }

    public void setFiber(BigDecimal fiber) {
        this.fiber = fiber;
    }

    public int getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(int displayOrder) {
        this.displayOrder = displayOrder;
    }
}
