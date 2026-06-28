-- Purpose: create the workout domain schema for LifeTracker.
-- This migration adds the plan, template, exercise catalog, execution history,
-- and performed set tables needed for production workout tracking without
-- storing analytics or personal records.

-- Purpose: store user-owned workout programs that define long-lived training plans.
CREATE TABLE IF NOT EXISTS workout_programs (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    program_status VARCHAR(20) NOT NULL DEFAULT 'draft',
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_workout_programs PRIMARY KEY (id),
    CONSTRAINT uq_workout_programs_uuid UNIQUE (uuid),
    CONSTRAINT uq_workout_programs_user_id_name UNIQUE (user_id, name),
    CONSTRAINT fk_workout_programs_user_id_user FOREIGN KEY (user_id)
        REFERENCES app_user (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_workout_programs_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_workout_programs_program_status_valid CHECK (program_status IN ('draft', 'active', 'completed', 'archived')),
    CONSTRAINT ck_workout_programs_display_order_non_negative CHECK (display_order >= 0),
    CONSTRAINT ck_workout_programs_end_date_not_before_start_date CHECK (end_date IS NULL OR end_date >= start_date)
);

COMMENT ON TABLE workout_programs IS
    'User-owned training plans that define the high-level structure of workouts.';
COMMENT ON COLUMN workout_programs.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN workout_programs.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN workout_programs.user_id IS
    'Foreign key to the owning user account.';
COMMENT ON COLUMN workout_programs.name IS
    'Human-readable workout program name.';
COMMENT ON COLUMN workout_programs.description IS
    'Optional longer description of the training plan.';
COMMENT ON COLUMN workout_programs.program_status IS
    'Lifecycle status of the workout program.';
COMMENT ON COLUMN workout_programs.start_date IS
    'Date when the workout program becomes effective.';
COMMENT ON COLUMN workout_programs.end_date IS
    'Optional date when the workout program ends or is expected to end.';
COMMENT ON COLUMN workout_programs.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN workout_programs.is_active IS
    'Indicates whether the workout program is active and available for use.';
COMMENT ON COLUMN workout_programs.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN workout_programs.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store workout templates that belong to a specific workout program.
CREATE TABLE IF NOT EXISTS workout_templates (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    workout_program_id BIGINT NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_workout_templates PRIMARY KEY (id),
    CONSTRAINT uq_workout_templates_uuid UNIQUE (uuid),
    CONSTRAINT uq_workout_templates_workout_program_id_name UNIQUE (workout_program_id, name),
    CONSTRAINT fk_workout_templates_workout_program_id_workout_programs FOREIGN KEY (workout_program_id)
        REFERENCES workout_programs (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_workout_templates_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_workout_templates_display_order_non_negative CHECK (display_order >= 0)
);

COMMENT ON TABLE workout_templates IS
    'Reusable workout blueprints that define the structure of a session within a program.';
COMMENT ON COLUMN workout_templates.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN workout_templates.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN workout_templates.workout_program_id IS
    'Foreign key to the workout program that owns the template.';
COMMENT ON COLUMN workout_templates.name IS
    'Human-readable workout template name.';
COMMENT ON COLUMN workout_templates.description IS
    'Optional longer description of the workout template.';
COMMENT ON COLUMN workout_templates.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN workout_templates.is_active IS
    'Indicates whether the workout template is active and available for use.';
COMMENT ON COLUMN workout_templates.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN workout_templates.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store the canonical exercise catalog used across workout templates.
CREATE TABLE IF NOT EXISTS exercises (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    muscle_group_id BIGINT,
    equipment_type_id BIGINT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_exercises PRIMARY KEY (id),
    CONSTRAINT uq_exercises_uuid UNIQUE (uuid),
    CONSTRAINT uq_exercises_code UNIQUE (code),
    CONSTRAINT fk_exercises_muscle_group_id_muscle_groups FOREIGN KEY (muscle_group_id)
        REFERENCES muscle_groups (id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT fk_exercises_equipment_type_id_equipment_types FOREIGN KEY (equipment_type_id)
        REFERENCES equipment_types (id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT ck_exercises_code_not_blank CHECK (length(btrim(code)) > 0),
    CONSTRAINT ck_exercises_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_exercises_display_order_non_negative CHECK (display_order >= 0)
);

COMMENT ON TABLE exercises IS
    'Canonical catalog of exercises used to build workout templates and record execution history.';
COMMENT ON COLUMN exercises.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN exercises.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN exercises.code IS
    'Unique machine-readable business code for the exercise.';
COMMENT ON COLUMN exercises.name IS
    'Human-readable exercise name.';
COMMENT ON COLUMN exercises.description IS
    'Optional longer description of the exercise.';
COMMENT ON COLUMN exercises.muscle_group_id IS
    'Optional foreign key to the primary muscle group classification.';
COMMENT ON COLUMN exercises.equipment_type_id IS
    'Optional foreign key to the equipment type classification.';
COMMENT ON COLUMN exercises.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN exercises.is_active IS
    'Indicates whether the exercise is active and available for use.';
COMMENT ON COLUMN exercises.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN exercises.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: map workout templates to the exercises they contain and prescribe targets.
CREATE TABLE IF NOT EXISTS template_exercises (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    workout_template_id BIGINT NOT NULL,
    exercise_id BIGINT NOT NULL,
    sequence_order INTEGER NOT NULL,
    target_sets SMALLINT NOT NULL DEFAULT 1,
    target_reps_min SMALLINT,
    target_reps_max SMALLINT,
    target_duration_seconds INTEGER,
    rest_seconds INTEGER NOT NULL DEFAULT 0,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_template_exercises PRIMARY KEY (id),
    CONSTRAINT uq_template_exercises_uuid UNIQUE (uuid),
    CONSTRAINT uq_template_exercises_workout_template_id_sequence_order UNIQUE (workout_template_id, sequence_order),
    CONSTRAINT uq_template_exercises_workout_template_id_exercise_id UNIQUE (workout_template_id, exercise_id),
    CONSTRAINT fk_template_exercises_workout_template_id_workout_templates FOREIGN KEY (workout_template_id)
        REFERENCES workout_templates (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_template_exercises_exercise_id_exercises FOREIGN KEY (exercise_id)
        REFERENCES exercises (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_template_exercises_sequence_order_positive CHECK (sequence_order > 0),
    CONSTRAINT ck_template_exercises_target_sets_positive CHECK (target_sets > 0),
    CONSTRAINT ck_template_exercises_target_reps_min_positive CHECK (target_reps_min IS NULL OR target_reps_min > 0),
    CONSTRAINT ck_template_exercises_target_reps_max_positive CHECK (target_reps_max IS NULL OR target_reps_max > 0),
    CONSTRAINT ck_template_exercises_target_reps_range_valid CHECK (target_reps_min IS NULL OR target_reps_max IS NULL OR target_reps_min <= target_reps_max),
    CONSTRAINT ck_template_exercises_target_duration_seconds_positive CHECK (target_duration_seconds IS NULL OR target_duration_seconds > 0),
    CONSTRAINT ck_template_exercises_target_measurement_present CHECK (target_reps_min IS NOT NULL OR target_duration_seconds IS NOT NULL),
    CONSTRAINT ck_template_exercises_rest_seconds_non_negative CHECK (rest_seconds >= 0)
);

COMMENT ON TABLE template_exercises IS
    'Template-specific exercise prescriptions with ordering and target values.';
COMMENT ON COLUMN template_exercises.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN template_exercises.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN template_exercises.workout_template_id IS
    'Foreign key to the workout template that owns the prescription.';
COMMENT ON COLUMN template_exercises.exercise_id IS
    'Foreign key to the exercise being prescribed.';
COMMENT ON COLUMN template_exercises.sequence_order IS
    'Positive ordering value that defines exercise order inside the template.';
COMMENT ON COLUMN template_exercises.target_sets IS
    'Positive number of intended sets for the exercise.';
COMMENT ON COLUMN template_exercises.target_reps_min IS
    'Optional lower bound for the target repetition range.';
COMMENT ON COLUMN template_exercises.target_reps_max IS
    'Optional upper bound for the target repetition range.';
COMMENT ON COLUMN template_exercises.target_duration_seconds IS
    'Optional target duration in seconds for time-based exercises.';
COMMENT ON COLUMN template_exercises.rest_seconds IS
    'Non-negative rest time in seconds recommended after the exercise.';
COMMENT ON COLUMN template_exercises.notes IS
    'Optional prescription notes for the exercise within the template.';
COMMENT ON COLUMN template_exercises.is_active IS
    'Indicates whether the template exercise is active and available for use.';
COMMENT ON COLUMN template_exercises.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN template_exercises.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store workout session history owned by each user.
CREATE TABLE IF NOT EXISTS workout_sessions (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    workout_template_id BIGINT,
    session_status VARCHAR(20) NOT NULL DEFAULT 'planned',
    started_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITHOUT TIME ZONE,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_workout_sessions PRIMARY KEY (id),
    CONSTRAINT uq_workout_sessions_uuid UNIQUE (uuid),
    CONSTRAINT fk_workout_sessions_user_id_user FOREIGN KEY (user_id)
        REFERENCES app_user (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_workout_sessions_workout_template_id_workout_templates FOREIGN KEY (workout_template_id)
        REFERENCES workout_templates (id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT ck_workout_sessions_session_status_valid CHECK (session_status IN ('planned', 'in_progress', 'completed', 'cancelled')),
    CONSTRAINT ck_workout_sessions_completed_at_not_before_started_at CHECK (completed_at IS NULL OR completed_at >= started_at)
);

COMMENT ON TABLE workout_sessions IS
    'Execution history for workouts performed by a user, optionally linked to a template.';
COMMENT ON COLUMN workout_sessions.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN workout_sessions.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN workout_sessions.user_id IS
    'Foreign key to the owning user account.';
COMMENT ON COLUMN workout_sessions.workout_template_id IS
    'Optional foreign key to the template used for the session; history is preserved if the template is retired.';
COMMENT ON COLUMN workout_sessions.session_status IS
    'Lifecycle status of the workout session.';
COMMENT ON COLUMN workout_sessions.started_at IS
    'Timestamp when the workout session started.';
COMMENT ON COLUMN workout_sessions.completed_at IS
    'Optional timestamp when the workout session completed.';
COMMENT ON COLUMN workout_sessions.notes IS
    'Optional notes captured for the session.';
COMMENT ON COLUMN workout_sessions.is_active IS
    'Indicates whether the session record is active and visible.';
COMMENT ON COLUMN workout_sessions.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN workout_sessions.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store the exercise occurrences within a workout session.
CREATE TABLE IF NOT EXISTS workout_session_exercises (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    workout_session_id BIGINT NOT NULL,
    template_exercise_id BIGINT,
    exercise_id BIGINT NOT NULL,
    sequence_order INTEGER NOT NULL,
    exercise_status VARCHAR(20) NOT NULL DEFAULT 'planned',
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_workout_session_exercises PRIMARY KEY (id),
    CONSTRAINT uq_workout_session_exercises_uuid UNIQUE (uuid),
    CONSTRAINT uq_workout_session_exercises_workout_session_id_sequence_order UNIQUE (workout_session_id, sequence_order),
    CONSTRAINT fk_workout_session_exercises_workout_session_id_workout_sessions FOREIGN KEY (workout_session_id)
        REFERENCES workout_sessions (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_workout_session_exercises_template_exercise_id_template_exercises FOREIGN KEY (template_exercise_id)
        REFERENCES template_exercises (id)
        ON UPDATE CASCADE
        ON DELETE SET NULL,
    CONSTRAINT fk_workout_session_exercises_exercise_id_exercises FOREIGN KEY (exercise_id)
        REFERENCES exercises (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_workout_session_exercises_sequence_order_positive CHECK (sequence_order > 0),
    CONSTRAINT ck_workout_session_exercises_exercise_status_valid CHECK (exercise_status IN ('planned', 'in_progress', 'completed', 'skipped'))
);

COMMENT ON TABLE workout_session_exercises IS
    'Exercise-level execution history within a workout session.';
COMMENT ON COLUMN workout_session_exercises.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN workout_session_exercises.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN workout_session_exercises.workout_session_id IS
    'Foreign key to the workout session that owns the exercise occurrence.';
COMMENT ON COLUMN workout_session_exercises.template_exercise_id IS
    'Optional foreign key to the template exercise that originated the session exercise.';
COMMENT ON COLUMN workout_session_exercises.exercise_id IS
    'Foreign key to the underlying exercise being performed.';
COMMENT ON COLUMN workout_session_exercises.sequence_order IS
    'Positive ordering value that defines exercise order within the session.';
COMMENT ON COLUMN workout_session_exercises.exercise_status IS
    'Lifecycle status of the exercise within the session.';
COMMENT ON COLUMN workout_session_exercises.notes IS
    'Optional notes captured for the exercise occurrence.';
COMMENT ON COLUMN workout_session_exercises.is_active IS
    'Indicates whether the session exercise record is active and visible.';
COMMENT ON COLUMN workout_session_exercises.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN workout_session_exercises.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store every performed set for a workout session exercise.
CREATE TABLE IF NOT EXISTS workout_sets (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    workout_session_exercise_id BIGINT NOT NULL,
    set_number SMALLINT NOT NULL,
    performed_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    repetitions SMALLINT,
    weight_kg NUMERIC(8, 2),
    duration_seconds INTEGER,
    distance_meters NUMERIC(8, 2),
    is_completed BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_workout_sets PRIMARY KEY (id),
    CONSTRAINT uq_workout_sets_uuid UNIQUE (uuid),
    CONSTRAINT uq_workout_sets_workout_session_exercise_id_set_number UNIQUE (workout_session_exercise_id, set_number),
    CONSTRAINT fk_workout_sets_workout_session_exercise_id_workout_session_exercises FOREIGN KEY (workout_session_exercise_id)
        REFERENCES workout_session_exercises (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_workout_sets_set_number_positive CHECK (set_number > 0),
    CONSTRAINT ck_workout_sets_repetitions_positive CHECK (repetitions IS NULL OR repetitions > 0),
    CONSTRAINT ck_workout_sets_weight_kg_non_negative CHECK (weight_kg IS NULL OR weight_kg >= 0),
    CONSTRAINT ck_workout_sets_duration_seconds_positive CHECK (duration_seconds IS NULL OR duration_seconds > 0),
    CONSTRAINT ck_workout_sets_distance_meters_non_negative CHECK (distance_meters IS NULL OR distance_meters >= 0),
    CONSTRAINT ck_workout_sets_measurement_present CHECK (
        repetitions IS NOT NULL
        OR weight_kg IS NOT NULL
        OR duration_seconds IS NOT NULL
        OR distance_meters IS NOT NULL
    )
);

COMMENT ON TABLE workout_sets IS
    'Every performed set recorded during a workout session exercise.';
COMMENT ON COLUMN workout_sets.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN workout_sets.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN workout_sets.workout_session_exercise_id IS
    'Foreign key to the workout session exercise that owns the set.';
COMMENT ON COLUMN workout_sets.set_number IS
    'Positive sequence number of the performed set within the exercise.';
COMMENT ON COLUMN workout_sets.performed_at IS
    'Timestamp when the set was performed.';
COMMENT ON COLUMN workout_sets.repetitions IS
    'Optional performed repetition count for the set.';
COMMENT ON COLUMN workout_sets.weight_kg IS
    'Optional load used for the set, expressed in kilograms.';
COMMENT ON COLUMN workout_sets.duration_seconds IS
    'Optional duration of the set, expressed in seconds.';
COMMENT ON COLUMN workout_sets.distance_meters IS
    'Optional distance covered during the set, expressed in meters.';
COMMENT ON COLUMN workout_sets.is_completed IS
    'Indicates whether the set was completed as recorded.';
COMMENT ON COLUMN workout_sets.notes IS
    'Optional notes captured for the performed set.';
COMMENT ON COLUMN workout_sets.is_active IS
    'Indicates whether the set record is active and visible.';
COMMENT ON COLUMN workout_sets.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN workout_sets.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: apply updated_at maintenance to mutable workout tables.
DROP TRIGGER IF EXISTS trg_workout_programs_set_updated_at ON workout_programs;
CREATE TRIGGER trg_workout_programs_set_updated_at
BEFORE UPDATE ON workout_programs
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_workout_templates_set_updated_at ON workout_templates;
CREATE TRIGGER trg_workout_templates_set_updated_at
BEFORE UPDATE ON workout_templates
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_exercises_set_updated_at ON exercises;
CREATE TRIGGER trg_exercises_set_updated_at
BEFORE UPDATE ON exercises
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_template_exercises_set_updated_at ON template_exercises;
CREATE TRIGGER trg_template_exercises_set_updated_at
BEFORE UPDATE ON template_exercises
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_workout_sessions_set_updated_at ON workout_sessions;
CREATE TRIGGER trg_workout_sessions_set_updated_at
BEFORE UPDATE ON workout_sessions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_workout_session_exercises_set_updated_at ON workout_session_exercises;
CREATE TRIGGER trg_workout_session_exercises_set_updated_at
BEFORE UPDATE ON workout_session_exercises
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_workout_sets_set_updated_at ON workout_sets;
CREATE TRIGGER trg_workout_sets_set_updated_at
BEFORE UPDATE ON workout_sets
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- Purpose: create targeted indexes that support common lookup paths without over-indexing.
CREATE INDEX IF NOT EXISTS idx_exercises_muscle_group_id ON exercises (muscle_group_id);
CREATE INDEX IF NOT EXISTS idx_exercises_equipment_type_id ON exercises (equipment_type_id);
CREATE INDEX IF NOT EXISTS idx_template_exercises_exercise_id ON template_exercises (exercise_id);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_user_id_started_at ON workout_sessions (user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_workout_sessions_workout_template_id ON workout_sessions (workout_template_id);
CREATE INDEX IF NOT EXISTS idx_workout_session_exercises_exercise_id ON workout_session_exercises (exercise_id);
CREATE INDEX IF NOT EXISTS idx_workout_sets_workout_session_exercise_id_performed_at ON workout_sets (workout_session_exercise_id, performed_at DESC);
