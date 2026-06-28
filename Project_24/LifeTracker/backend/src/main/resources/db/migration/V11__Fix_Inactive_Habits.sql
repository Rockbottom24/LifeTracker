-- Habits created before active defaults were applied in HabitMapper were persisted as inactive.
UPDATE habits
SET is_active = TRUE,
    updated_at = CURRENT_TIMESTAMP
WHERE is_active = FALSE;
