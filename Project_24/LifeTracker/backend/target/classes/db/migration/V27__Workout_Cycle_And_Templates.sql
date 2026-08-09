-- Migration: V27__Workout_Cycle_And_Templates.sql
-- Description: Create workout templates, template exercises, and user workout schedule tables + seed 24*7 Fitness Studio PDF presets.

-- 1. Workout Templates Table
CREATE TABLE IF NOT EXISTS workout_templates_v2 (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id BIGINT,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL,
    description TEXT,
    is_preset BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_workout_templates_v2_uuid UNIQUE (uuid)
);

-- 2. Workout Template Exercises Table
CREATE TABLE IF NOT EXISTS workout_template_exercises_v2 (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    template_id BIGINT NOT NULL,
    exercise_name VARCHAR(150) NOT NULL,
    sets INT NOT NULL DEFAULT 3,
    reps VARCHAR(50) NOT NULL DEFAULT '12-15',
    rest_seconds INT NOT NULL DEFAULT 45,
    sequence_order INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_workout_template_exercises_v2_uuid UNIQUE (uuid),
    CONSTRAINT fk_workout_template_exercises_v2_template FOREIGN KEY (template_id)
        REFERENCES workout_templates_v2(id) ON DELETE CASCADE
);

-- 3. User Workout Schedule Table
CREATE TABLE IF NOT EXISTS user_workout_schedule (
    id BIGSERIAL PRIMARY KEY,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    scheduled_date DATE NOT NULL,
    template_id BIGINT,
    custom_title VARCHAR(150),
    status VARCHAR(30) NOT NULL DEFAULT 'PLANNED',
    completed_at TIMESTAMP WITHOUT TIME ZONE,
    notes TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_user_workout_schedule_uuid UNIQUE (uuid),
    CONSTRAINT uq_user_workout_schedule_user_date UNIQUE (user_id, scheduled_date),
    CONSTRAINT fk_user_workout_schedule_user FOREIGN KEY (user_id) REFERENCES app_user(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_workout_schedule_template FOREIGN KEY (template_id) REFERENCES workout_templates_v2(id) ON DELETE SET NULL
);

-- Seed Preset Templates from 24*7 Fitness Studio PDF
-- Push A (Week 1 & 4)
INSERT INTO workout_templates_v2 (id, name, category, description, is_preset, is_active)
VALUES (1, 'Push Day (Week 1 & 4)', 'PUSH', 'Flat Press, Machine Fly, Shoulder Press, Side Raise, Rope Pushdown, Seated Dips', TRUE, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO workout_template_exercises_v2 (template_id, exercise_name, sets, reps, rest_seconds, sequence_order) VALUES
(1, 'Flat Press', 3, '12-15', 45, 1),
(1, 'Machine Fly', 3, '12-15', 45, 2),
(1, 'Shoulder Press', 3, '12-15', 45, 3),
(1, 'Side Raise', 3, '12-15', 45, 4),
(1, 'Rope Pushdown', 3, '12-15', 45, 5),
(1, 'Seated Dips', 3, '12-15', 45, 6)
ON CONFLICT DO NOTHING;

-- Pull A (Week 1 & 4)
INSERT INTO workout_templates_v2 (id, name, category, description, is_preset, is_active)
VALUES (2, 'Pull Day (Week 1 & 4)', 'PULL', 'Lat Pulldown, Single Hand DB Row, Reverse Flys, Dumbbell Curls, DB Concentration Curl, Shrugs', TRUE, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO workout_template_exercises_v2 (template_id, exercise_name, sets, reps, rest_seconds, sequence_order) VALUES
(2, 'Lat Pulldown', 3, '12-15', 45, 1),
(2, 'Single Hand Dumbbell Row', 3, '12-15', 45, 2),
(2, 'Reverse Flys', 3, '12-15', 45, 3),
(2, 'Dumbbell Curls', 3, '12-15', 45, 4),
(2, 'DB Concentration Curl', 3, '12-15', 45, 5),
(2, 'Shrugs', 3, '10-12', 45, 6)
ON CONFLICT DO NOTHING;

-- Leg A (Week 1 & 4)
INSERT INTO workout_templates_v2 (id, name, category, description, is_preset, is_active)
VALUES (3, 'Leg Day (Week 1 & 4)', 'LEGS', 'Squats, Leg Press, Leg Extension, Lunges, Leg Curls, Standing Calf Raise', TRUE, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO workout_template_exercises_v2 (template_id, exercise_name, sets, reps, rest_seconds, sequence_order) VALUES
(3, 'Squats', 3, '8-10', 45, 1),
(3, 'Leg Press', 3, '12-15', 45, 2),
(3, 'Leg Extension', 3, '12-15', 45, 3),
(3, 'Lunges', 3, '12-15', 45, 4),
(3, 'Leg Curls', 3, '12-15', 45, 5),
(3, 'Standing Calf Raise', 3, '20-25', 45, 6)
ON CONFLICT DO NOTHING;

-- Push B (Week 2 & 5)
INSERT INTO workout_templates_v2 (id, name, category, description, is_preset, is_active)
VALUES (4, 'Push Day (Week 2 & 5)', 'PUSH', 'Incline Chest, DB Flies (Flat), Front Raise, Lateral Raise, Over Hand Extension, Kick Back', TRUE, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO workout_template_exercises_v2 (template_id, exercise_name, sets, reps, rest_seconds, sequence_order) VALUES
(4, 'Incline Chest', 3, '12-15', 45, 1),
(4, 'DB Flies (Flat)', 3, '12-15', 45, 2),
(4, 'Front Raise', 3, '12-15', 45, 3),
(4, 'Lateral Raise', 3, '12-15', 45, 4),
(4, 'Over Hand Extension', 3, '12-15', 45, 5),
(4, 'Kick Back', 3, '12-15', 45, 6)
ON CONFLICT DO NOTHING;

-- Pull B (Week 2 & 5)
INSERT INTO workout_templates_v2 (id, name, category, description, is_preset, is_active)
VALUES (5, 'Pull Day (Week 2 & 5)', 'PULL', 'Deadlift, High Row, Seated Row, Upright Row, Preacher Curl, Incline DB Curl', TRUE, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO workout_template_exercises_v2 (template_id, exercise_name, sets, reps, rest_seconds, sequence_order) VALUES
(5, 'Deadlift', 3, '8-10', 60, 1),
(5, 'High Row', 3, '12-15', 45, 2),
(5, 'Seated Row', 3, '12-15', 45, 3),
(5, 'Upright Row', 3, '12-15', 45, 4),
(5, 'Preacher Curl', 3, '12-15', 45, 5),
(5, 'Incline DB Curl', 3, '12-15', 45, 6)
ON CONFLICT DO NOTHING;

-- Leg B (Week 2 & 5)
INSERT INTO workout_templates_v2 (id, name, category, description, is_preset, is_active)
VALUES (6, 'Legs Day (Week 2 & 5)', 'LEGS', 'Sumo Squats, Seated Leg Press, Bulgarian Split Squats, Leg Extension, Adductor Press, Calf Rise (seated)', TRUE, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO workout_template_exercises_v2 (template_id, exercise_name, sets, reps, rest_seconds, sequence_order) VALUES
(6, 'Sumo Squats', 3, '10-15', 45, 1),
(6, 'Seated Leg Press', 3, '10-15', 45, 2),
(6, 'Bulgarian Split Squats', 3, '10-15', 45, 3),
(6, 'Leg Extension', 3, '10-15', 45, 4),
(6, 'Adductor Press', 3, '10-15', 45, 5),
(6, 'Calf Rise (seated)', 3, '15-25', 45, 6)
ON CONFLICT DO NOTHING;

-- Push C (Week 3 & 6)
INSERT INTO workout_templates_v2 (id, name, category, description, is_preset, is_active)
VALUES (7, 'Push Day (Week 3 & 6)', 'PUSH', 'Decline Chest Press, Cable Crossover, BB Shoulder Press, Y-Raise, Reverse Push Down, Single Hand Overhead Ex', TRUE, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO workout_template_exercises_v2 (template_id, exercise_name, sets, reps, rest_seconds, sequence_order) VALUES
(7, 'Decline Chest Press', 3, '12-15', 45, 1),
(7, 'Cable Crossover', 3, '12-15', 45, 2),
(7, 'BB Shoulder Press', 3, '12-15', 45, 3),
(7, 'Y - Raise', 3, '12-15', 45, 4),
(7, 'Reverse Push Down', 3, '12-15', 45, 5),
(7, 'Single Hand Overhead Ex', 3, '12-15', 45, 6)
ON CONFLICT DO NOTHING;

-- Pull C (Week 3 & 6)
INSERT INTO workout_templates_v2 (id, name, category, description, is_preset, is_active)
VALUES (8, 'Pull Day (Week 3 & 6)', 'PULL', 'Deadlift, Close Grip Pulldown, Machine Row, Face Pull, BB Curls, Hammer Curls', TRUE, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO workout_template_exercises_v2 (template_id, exercise_name, sets, reps, rest_seconds, sequence_order) VALUES
(8, 'Deadlift', 3, '8-10', 60, 1),
(8, 'Close Grip Pulldown', 3, '12-15', 45, 2),
(8, 'Machine Row', 3, '12-15', 45, 3),
(8, 'Face Pull', 3, '12-15', 45, 4),
(8, 'BB Curls', 3, '12-15', 45, 5),
(8, 'Hammer Curls', 3, '12-15', 45, 6)
ON CONFLICT DO NOTHING;

-- Lower Body C (Week 3 & 6)
INSERT INTO workout_templates_v2 (id, name, category, description, is_preset, is_active)
VALUES (9, 'Lower Body Day (Week 3 & 6)', 'LEGS', 'Machine Squats, 90 deg. Leg Press, Weighted Walking Lunges, Leg Extension, Abductor Press, Calf Rise (weighted)', TRUE, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO workout_template_exercises_v2 (template_id, exercise_name, sets, reps, rest_seconds, sequence_order) VALUES
(9, 'Machine Squats', 3, '10-15', 45, 1),
(9, '90 deg. Leg Press', 3, '10-15', 45, 2),
(9, 'Weighted Walking Lunges', 3, '10-15', 45, 3),
(9, 'Leg Extension', 3, '10-15', 45, 4),
(9, 'Abductor Press', 3, '10-15', 45, 5),
(9, 'Calf Rise (weighted)', 3, '15-25', 45, 6)
ON CONFLICT DO NOTHING;

-- Upper Body Presets
INSERT INTO workout_templates_v2 (id, name, category, description, is_preset, is_active)
VALUES (10, 'Upper Body Power', 'UPPER', 'Flat Press, Lat Pulldown, BB Shoulder Press, Seated Row, Dumbbell Curls, Rope Pushdown', TRUE, TRUE)
ON CONFLICT DO NOTHING;

INSERT INTO workout_template_exercises_v2 (template_id, exercise_name, sets, reps, rest_seconds, sequence_order) VALUES
(10, 'Flat Press', 3, '10-12', 45, 1),
(10, 'Lat Pulldown', 3, '10-12', 45, 2),
(10, 'BB Shoulder Press', 3, '10-12', 45, 3),
(10, 'Seated Row', 3, '10-12', 45, 4),
(10, 'Dumbbell Curls', 3, '12-15', 45, 5),
(10, 'Rope Pushdown', 3, '12-15', 45, 6)
ON CONFLICT DO NOTHING;

-- Align primary key sequence for workout_templates_v2
SELECT setval(pg_get_serial_sequence('workout_templates_v2', 'id'), COALESCE((SELECT MAX(id) FROM workout_templates_v2), 1), TRUE);
