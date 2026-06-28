-- Purpose: seed default habit categories for the LifeTracker application.
INSERT INTO habit_categories (id, code, name, description, display_order, is_active, created_at, updated_at)
VALUES
    (1, 'health', 'Health', 'Physical and mental wellbeing habits.', 10, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (2, 'fitness', 'Fitness', 'Exercise and movement habits.', 20, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (3, 'learning', 'Learning', 'Study and skill-building habits.', 30, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (4, 'productivity', 'Productivity', 'Focus and organization habits.', 40, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
    (5, 'mindfulness', 'Mindfulness', 'Meditation and reflection habits.', 50, TRUE, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT (code) DO NOTHING;

SELECT setval(pg_get_serial_sequence('habit_categories', 'id'), COALESCE((SELECT MAX(id) FROM habit_categories), 1), TRUE);
