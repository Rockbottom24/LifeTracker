-- Purpose: seed deterministic master data for the LifeTracker lookup tables.
-- This migration inserts only application-owned reference data and avoids any
-- user-specific records.

-- Purpose: seed habit behavioral type reference data with fixed primary keys.
INSERT INTO habit_types (id, code, name, description, display_order, is_active, created_at, updated_at)
VALUES
    (1, 'checkbox', 'Checkbox', 'Binary habit marked as complete or incomplete.', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (2, 'counter', 'Counter', 'Habit tracked as a counted occurrence.', 20, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (3, 'duration', 'Duration', 'Habit tracked by elapsed time.', 30, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (4, 'quantity', 'Quantity', 'Habit tracked by a measured quantity.', 40, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (5, 'boolean', 'Boolean', 'Habit tracked using a true or false state.', 50, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (code) DO NOTHING;

-- Purpose: seed habit frequency reference data with fixed primary keys.
INSERT INTO habit_frequencies (id, code, name, description, display_order, is_active, created_at, updated_at)
VALUES
    (1, 'daily', 'Daily', 'Occurs every day.', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (2, 'weekly', 'Weekly', 'Occurs once per week.', 20, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (3, 'weekdays', 'Weekdays', 'Occurs Monday through Friday.', 30, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (4, 'weekends', 'Weekends', 'Occurs Saturday and Sunday.', 40, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (5, 'multiple_times_daily', 'Multiple Times Daily', 'Occurs more than once per day.', 50, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (6, 'monthly', 'Monthly', 'Occurs once per month.', 60, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (7, 'custom', 'Custom', 'Occurs on a user-defined schedule.', 70, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (code) DO NOTHING;

-- Purpose: seed muscle group reference data with fixed primary keys.
INSERT INTO muscle_groups (id, code, name, description, display_order, is_active, created_at, updated_at)
VALUES
    (1, 'chest', 'Chest', 'Muscles covering the chest region.', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (2, 'back', 'Back', 'Muscles covering the upper and lower back.', 20, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (3, 'shoulders', 'Shoulders', 'Deltoids and supporting shoulder musculature.', 30, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (4, 'arms', 'Arms', 'Biceps, triceps, and supporting arm musculature.', 40, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (5, 'core', 'Core', 'Abdominal and trunk stabilizing musculature.', 50, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (6, 'legs', 'Legs', 'Quadriceps, hamstrings, and lower leg musculature.', 60, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (7, 'glutes', 'Glutes', 'Gluteal muscles and hip extension support.', 70, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (8, 'calves', 'Calves', 'Gastrocnemius and soleus muscles.', 80, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (9, 'full_body', 'Full Body', 'Exercises that engage multiple major muscle groups.', 90, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (code) DO NOTHING;

-- Purpose: seed equipment type reference data with fixed primary keys.
INSERT INTO equipment_types (id, code, name, description, display_order, is_active, created_at, updated_at)
VALUES
    (1, 'bodyweight', 'Bodyweight', 'Exercises performed using only bodyweight.', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (2, 'dumbbell', 'Dumbbell', 'Free-weight dumbbell equipment.', 20, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (3, 'barbell', 'Barbell', 'Free-weight barbell equipment.', 30, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (4, 'machine', 'Machine', 'Selectorized or plate-loaded strength equipment.', 40, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (5, 'cable', 'Cable', 'Cable-based resistance equipment.', 50, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (6, 'kettlebell', 'Kettlebell', 'Kettlebell-based training equipment.', 60, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (7, 'resistance_band', 'Resistance Band', 'Elastic band resistance equipment.', 70, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (8, 'cardio_machine', 'Cardio Machine', 'Treadmills, bikes, rowers, and similar cardio equipment.', 80, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (9, 'none', 'None', 'No equipment required.', 90, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (code) DO NOTHING;

-- Purpose: keep lookup table sequences aligned with the seeded primary keys.
SELECT setval(pg_get_serial_sequence('habit_types', 'id'), COALESCE((SELECT MAX(id) FROM habit_types), 1), TRUE);
SELECT setval(pg_get_serial_sequence('habit_frequencies', 'id'), COALESCE((SELECT MAX(id) FROM habit_frequencies), 1), TRUE);
SELECT setval(pg_get_serial_sequence('muscle_groups', 'id'), COALESCE((SELECT MAX(id) FROM muscle_groups), 1), TRUE);
SELECT setval(pg_get_serial_sequence('equipment_types', 'id'), COALESCE((SELECT MAX(id) FROM equipment_types), 1), TRUE);
