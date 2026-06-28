package com.lifetracker.modules.nutrition.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "nutrition_goals")
public class NutritionGoals {
    public static final BigDecimal DEFAULT_CALORIE_GOAL = new BigDecimal("2500");
    public static final BigDecimal DEFAULT_PROTEIN_GOAL = new BigDecimal("150");
    public static final BigDecimal DEFAULT_CARBS_GOAL = new BigDecimal("300");
    public static final BigDecimal DEFAULT_FAT_GOAL = new BigDecimal("70");
    public static final BigDecimal DEFAULT_FIBER_GOAL = new BigDecimal("35");

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private UUID uuid;

    @Column(name = "owner_user_id", nullable = false, unique = true)
    private Long ownerUserId;

    @Column(name = "calorie_goal", nullable = false, precision = 8, scale = 2)
    private BigDecimal calorieGoal = DEFAULT_CALORIE_GOAL;

    @Column(name = "protein_goal", nullable = false, precision = 8, scale = 2)
    private BigDecimal proteinGoal = DEFAULT_PROTEIN_GOAL;

    @Column(name = "carbs_goal", nullable = false, precision = 8, scale = 2)
    private BigDecimal carbsGoal = DEFAULT_CARBS_GOAL;

    @Column(name = "fat_goal", nullable = false, precision = 8, scale = 2)
    private BigDecimal fatGoal = DEFAULT_FAT_GOAL;

    @Column(name = "fiber_goal", nullable = false, precision = 8, scale = 2)
    private BigDecimal fiberGoal = DEFAULT_FIBER_GOAL;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public UUID getUuid() {
        return uuid;
    }

    public void setUuid(UUID uuid) {
        this.uuid = uuid;
    }

    public Long getOwnerUserId() {
        return ownerUserId;
    }

    public void setOwnerUserId(Long ownerUserId) {
        this.ownerUserId = ownerUserId;
    }

    public BigDecimal getCalorieGoal() {
        return calorieGoal;
    }

    public void setCalorieGoal(BigDecimal calorieGoal) {
        this.calorieGoal = calorieGoal;
    }

    public BigDecimal getProteinGoal() {
        return proteinGoal;
    }

    public void setProteinGoal(BigDecimal proteinGoal) {
        this.proteinGoal = proteinGoal;
    }

    public BigDecimal getCarbsGoal() {
        return carbsGoal;
    }

    public void setCarbsGoal(BigDecimal carbsGoal) {
        this.carbsGoal = carbsGoal;
    }

    public BigDecimal getFatGoal() {
        return fatGoal;
    }

    public void setFatGoal(BigDecimal fatGoal) {
        this.fatGoal = fatGoal;
    }

    public BigDecimal getFiberGoal() {
        return fiberGoal;
    }

    public void setFiberGoal(BigDecimal fiberGoal) {
        this.fiberGoal = fiberGoal;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
