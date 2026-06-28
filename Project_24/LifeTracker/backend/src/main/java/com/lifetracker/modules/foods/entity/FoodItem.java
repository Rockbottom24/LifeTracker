package com.lifetracker.modules.foods.entity;

import com.lifetracker.modules.foods.enums.FoodCategory;
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
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "food_items")
public class FoodItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private UUID uuid;

    @Column(name = "owner_user_id")
    private Long ownerUserId;

    @Column(nullable = false, length = 150)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private FoodCategory category;

    @Enumerated(EnumType.STRING)
    @Column(name = "serving_unit", nullable = false, length = 20)
    private ServingUnit servingUnit;

    @Column(name = "reference_quantity", nullable = false, precision = 10, scale = 2)
    private BigDecimal referenceQuantity;

    @Column(name = "reference_weight", nullable = false, precision = 10, scale = 2)
    private BigDecimal referenceWeight;

    @Column(nullable = false, precision = 8, scale = 2)
    private BigDecimal calories;

    @Column(nullable = false, precision = 8, scale = 2)
    private BigDecimal protein;

    @Column(nullable = false, precision = 8, scale = 2)
    private BigDecimal carbs;

    @Column(nullable = false, precision = 8, scale = 2)
    private BigDecimal fat;

    @Column(nullable = false, precision = 8, scale = 2)
    private BigDecimal fiber;

    @Column(name = "is_system", nullable = false)
    private boolean system;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @Column(name = "display_order", nullable = false)
    private int displayOrder;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @Column(name = "barcode", unique = true)
    private String barcode;

    @Column(name = "brand")
    private String brand;

    @Column(name = "image_url", length = 1000)
    private String imageUrl;

    @Column(name = "source")
    private String source;

    public String getBarcode() {
        return barcode;
    }

    public void setBarcode(String barcode) {
        this.barcode = barcode;
    }

    public String getBrand() {
        return brand;
    }

    public void setBrand(String brand) {
        this.brand = brand;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public String getSource() {
        return source;
    }

    public void setSource(String source) {
        this.source = source;
    }

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

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public FoodCategory getCategory() {
        return category;
    }

    public void setCategory(FoodCategory category) {
        this.category = category;
    }

    public ServingUnit getServingUnit() {
        return servingUnit;
    }

    public void setServingUnit(ServingUnit servingUnit) {
        this.servingUnit = servingUnit;
    }

    public BigDecimal getReferenceQuantity() {
        return referenceQuantity;
    }

    public void setReferenceQuantity(BigDecimal referenceQuantity) {
        this.referenceQuantity = referenceQuantity;
    }

    public BigDecimal getReferenceWeight() {
        return referenceWeight;
    }

    public void setReferenceWeight(BigDecimal referenceWeight) {
        this.referenceWeight = referenceWeight;
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

    public boolean isSystem() {
        return system;
    }

    public void setSystem(boolean system) {
        this.system = system;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public int getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(int displayOrder) {
        this.displayOrder = displayOrder;
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
