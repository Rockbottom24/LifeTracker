-- V28: Add schedule_days for custom habit frequency and reminder_date for monthly habits

ALTER TABLE habits
    ADD COLUMN IF NOT EXISTS schedule_days VARCHAR(20) DEFAULT NULL,
    ADD COLUMN IF NOT EXISTS reminder_date DATE DEFAULT NULL;

COMMENT ON COLUMN habits.schedule_days IS 'Comma-separated weekday numbers (1=Mon..7=Sun) for CUSTOM frequency. Null means every day.';
COMMENT ON COLUMN habits.reminder_date IS 'For MONTHLY habits, the specific date that defines the day-of-month reminder (e.g. 2024-01-15 = 15th of every month).';
