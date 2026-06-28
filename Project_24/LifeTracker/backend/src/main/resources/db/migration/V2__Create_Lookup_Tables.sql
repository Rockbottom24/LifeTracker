-- Purpose: create the shared lookup tables used by the LifeTracker domain model.
-- These tables store stable reference data for application-controlled lookup
-- values such as habit behavioral types, scheduling, muscle grouping, and
-- equipment types.

-- Purpose: store the canonical list of habit behavioral types used across the application.
CREATE TABLE IF NOT EXISTS habit_types (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_habit_types PRIMARY KEY (id),
    CONSTRAINT uq_habit_types_uuid UNIQUE (uuid),
    CONSTRAINT uq_habit_types_code UNIQUE (code),
    CONSTRAINT ck_habit_types_code_not_blank CHECK (length(btrim(code)) > 0),
    CONSTRAINT ck_habit_types_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_habit_types_display_order_non_negative CHECK (display_order >= 0)
);

COMMENT ON TABLE habit_types IS
    'Canonical reference list describing the behavioral type of a habit.';
COMMENT ON COLUMN habit_types.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN habit_types.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN habit_types.code IS
    'Unique machine-readable business code for the habit type.';
COMMENT ON COLUMN habit_types.name IS
    'Human-readable display name for the habit type.';
COMMENT ON COLUMN habit_types.description IS
    'Optional longer description explaining the habit type.';
COMMENT ON COLUMN habit_types.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN habit_types.is_active IS
    'Indicates whether the lookup value is available for active use.';
COMMENT ON COLUMN habit_types.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN habit_types.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store the canonical list of habit frequencies used by the application.
CREATE TABLE IF NOT EXISTS habit_frequencies (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_habit_frequencies PRIMARY KEY (id),
    CONSTRAINT uq_habit_frequencies_uuid UNIQUE (uuid),
    CONSTRAINT uq_habit_frequencies_code UNIQUE (code),
    CONSTRAINT ck_habit_frequencies_code_not_blank CHECK (length(btrim(code)) > 0),
    CONSTRAINT ck_habit_frequencies_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_habit_frequencies_display_order_non_negative CHECK (display_order >= 0)
);

COMMENT ON TABLE habit_frequencies IS
    'Reference list describing how often a habit is intended to occur.';
COMMENT ON COLUMN habit_frequencies.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN habit_frequencies.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN habit_frequencies.code IS
    'Unique machine-readable business code for the habit frequency.';
COMMENT ON COLUMN habit_frequencies.name IS
    'Human-readable display name for the habit frequency.';
COMMENT ON COLUMN habit_frequencies.description IS
    'Optional longer description explaining the habit frequency.';
COMMENT ON COLUMN habit_frequencies.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN habit_frequencies.is_active IS
    'Indicates whether the lookup value is available for active use.';
COMMENT ON COLUMN habit_frequencies.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN habit_frequencies.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store the canonical list of muscle groups used for workout tracking.
CREATE TABLE IF NOT EXISTS muscle_groups (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_muscle_groups PRIMARY KEY (id),
    CONSTRAINT uq_muscle_groups_uuid UNIQUE (uuid),
    CONSTRAINT uq_muscle_groups_code UNIQUE (code),
    CONSTRAINT ck_muscle_groups_code_not_blank CHECK (length(btrim(code)) > 0),
    CONSTRAINT ck_muscle_groups_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_muscle_groups_display_order_non_negative CHECK (display_order >= 0)
);

COMMENT ON TABLE muscle_groups IS
    'Reference list of muscle groups used to classify workout movements and plans.';
COMMENT ON COLUMN muscle_groups.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN muscle_groups.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN muscle_groups.code IS
    'Unique machine-readable business code for the muscle group.';
COMMENT ON COLUMN muscle_groups.name IS
    'Human-readable display name for the muscle group.';
COMMENT ON COLUMN muscle_groups.description IS
    'Optional longer description explaining the muscle group.';
COMMENT ON COLUMN muscle_groups.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN muscle_groups.is_active IS
    'Indicates whether the lookup value is available for active use.';
COMMENT ON COLUMN muscle_groups.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN muscle_groups.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store the canonical list of equipment types used in workout tracking.
CREATE TABLE IF NOT EXISTS equipment_types (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_equipment_types PRIMARY KEY (id),
    CONSTRAINT uq_equipment_types_uuid UNIQUE (uuid),
    CONSTRAINT uq_equipment_types_code UNIQUE (code),
    CONSTRAINT ck_equipment_types_code_not_blank CHECK (length(btrim(code)) > 0),
    CONSTRAINT ck_equipment_types_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_equipment_types_display_order_non_negative CHECK (display_order >= 0)
);

COMMENT ON TABLE equipment_types IS
    'Reference list of equipment types used to classify workout equipment.';
COMMENT ON COLUMN equipment_types.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN equipment_types.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN equipment_types.code IS
    'Unique machine-readable business code for the equipment type.';
COMMENT ON COLUMN equipment_types.name IS
    'Human-readable display name for the equipment type.';
COMMENT ON COLUMN equipment_types.description IS
    'Optional longer description explaining the equipment type.';
COMMENT ON COLUMN equipment_types.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN equipment_types.is_active IS
    'Indicates whether the lookup value is available for active use.';
COMMENT ON COLUMN equipment_types.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN equipment_types.updated_at IS
    'Timestamp when the row was last updated.';
