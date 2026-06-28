-- Bring the habits table in line with the current Habit entity mapping.
-- This migration is additive and preserves existing rows by backfilling
-- required non-null fields with safe defaults.

ALTER TABLE habits
    ADD COLUMN IF NOT EXISTS frequency VARCHAR(20),
    ADD COLUMN IF NOT EXISTS reminder_time TIME,
    ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN,
    ADD COLUMN IF NOT EXISTS icon_name VARCHAR(50);

UPDATE habits
SET frequency = COALESCE(frequency, 'DAILY'),
    notifications_enabled = COALESCE(notifications_enabled, TRUE)
WHERE frequency IS NULL
   OR notifications_enabled IS NULL;

ALTER TABLE habits
    ALTER COLUMN frequency SET DEFAULT 'DAILY',
    ALTER COLUMN frequency SET NOT NULL,
    ALTER COLUMN notifications_enabled SET DEFAULT TRUE,
    ALTER COLUMN notifications_enabled SET NOT NULL;

COMMENT ON COLUMN habits.frequency IS
    'Habit recurrence frequency such as daily, weekly, or monthly.';
COMMENT ON COLUMN habits.reminder_time IS
    'Optional reminder time for the habit.';
COMMENT ON COLUMN habits.notifications_enabled IS
    'Indicates whether notifications are enabled for the habit.';
COMMENT ON COLUMN habits.icon_name IS
    'Optional icon identifier used to render the habit in the UI.';
