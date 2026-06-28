package com.lifetracker.modules.habits.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDate;
import java.time.LocalDateTime;

import java.time.LocalTime;

import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;

import com.lifetracker.modules.habits.enums.HabitFrequency;

@Entity
@Table(name = "habits")
public class Habit {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "uuid", nullable = false, unique = true)
    private java.util.UUID uuid;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "habit_category_id", nullable = false)
    private Long habitCategoryId;

    @Column(name = "name", nullable = false, length = 150)
    private String name;

    @Column(name = "description")
    private String description;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "display_order", nullable = false)
    private int displayOrder;

    @Column(name = "is_active", nullable = false)
    private boolean active;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;


    @Enumerated(EnumType.STRING)
    @Column(name = "frequency", nullable = false)
    private HabitFrequency frequency;

    @Column(name = "reminder_time")
    private LocalTime reminderTime;

    @Column(name = "notifications_enabled", nullable = false)
    private boolean notificationsEnabled;

    @Column(name = "icon_name", length = 50)
    private String iconName;

    @Column(name = "color_hex", length = 20)
    private String colorHex;

    public void setFrequency(HabitFrequency frequency) {
        this.frequency = frequency;
    }

    public void setReminderTime(LocalTime reminderTime) {
        this.reminderTime = reminderTime;
    }

    public void setNotificationsEnabled(boolean notificationsEnabled) {
        this.notificationsEnabled = notificationsEnabled;
    }

    public void setIconName(String iconName) {
        this.iconName = iconName;
    }

    public void setColorHex(String colorHex) {
        this.colorHex = colorHex;
    }

    public HabitFrequency getFrequency() {
        return frequency;
    }

    public LocalTime getReminderTime() {
        return reminderTime;
    }

    public boolean isNotificationsEnabled() {
        return notificationsEnabled;
    }

    public String getIconName() {
        return iconName;
    }

    public String getColorHex() {
        return colorHex;
    }

    public Habit() {
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public java.util.UUID getUuid() {
        return uuid;
    }

    public void setUuid(java.util.UUID uuid) {
        this.uuid = uuid;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Long getHabitCategoryId() {
        return habitCategoryId;
    }

    public void setHabitCategoryId(Long habitCategoryId) {
        this.habitCategoryId = habitCategoryId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public int getDisplayOrder() {
        return displayOrder;
    }

    public void setDisplayOrder(int displayOrder) {
        this.displayOrder = displayOrder;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
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
