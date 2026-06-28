-- Purpose: create the habit domain schema for LifeTracker.
-- This migration adds the category, habit, bundle, membership, log, and reminder
-- tables that support habit planning and tracking without introducing streak or
-- analytics storage.

-- Purpose: store the canonical habit category taxonomy used to classify habits.
CREATE TABLE IF NOT EXISTS habit_categories (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_habit_categories PRIMARY KEY (id),
    CONSTRAINT uq_habit_categories_uuid UNIQUE (uuid),
    CONSTRAINT uq_habit_categories_code UNIQUE (code),
    CONSTRAINT ck_habit_categories_code_not_blank CHECK (length(btrim(code)) > 0),
    CONSTRAINT ck_habit_categories_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_habit_categories_display_order_non_negative CHECK (display_order >= 0)
);

COMMENT ON TABLE habit_categories IS
    'Canonical classification table for organizing habits into business-defined categories.';
COMMENT ON COLUMN habit_categories.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN habit_categories.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN habit_categories.code IS
    'Unique machine-readable business code for the habit category.';
COMMENT ON COLUMN habit_categories.name IS
    'Human-readable display name for the habit category.';
COMMENT ON COLUMN habit_categories.description IS
    'Optional longer description explaining the category.';
COMMENT ON COLUMN habit_categories.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN habit_categories.is_active IS
    'Indicates whether the category is active and available for use.';
COMMENT ON COLUMN habit_categories.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN habit_categories.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store user-owned habits that belong to a single category.
CREATE TABLE IF NOT EXISTS habits (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    habit_category_id BIGINT NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_habits PRIMARY KEY (id),
    CONSTRAINT uq_habits_uuid UNIQUE (uuid),
    CONSTRAINT fk_habits_user_id_user FOREIGN KEY (user_id)
        REFERENCES app_user (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_habits_habit_category_id_habit_categories FOREIGN KEY (habit_category_id)
        REFERENCES habit_categories (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_habits_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_habits_display_order_non_negative CHECK (display_order >= 0),
    CONSTRAINT ck_habits_end_date_not_before_start_date CHECK (end_date IS NULL OR end_date >= start_date)
);

COMMENT ON TABLE habits IS
    'User-owned habits that are assigned to a category and tracked over time.';
COMMENT ON COLUMN habits.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN habits.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN habits.user_id IS
    'Foreign key to the owning user account.';
COMMENT ON COLUMN habits.habit_category_id IS
    'Foreign key to the category that classifies the habit.';
COMMENT ON COLUMN habits.name IS
    'Human-readable habit title.';
COMMENT ON COLUMN habits.description IS
    'Optional longer description of the habit.';
COMMENT ON COLUMN habits.start_date IS
    'Date when the habit became active.';
COMMENT ON COLUMN habits.end_date IS
    'Optional date when the habit ends or is expected to end.';
COMMENT ON COLUMN habits.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN habits.is_active IS
    'Indicates whether the habit is active and available for use.';
COMMENT ON COLUMN habits.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN habits.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store user-owned habit bundles that group related habits together.
CREATE TABLE IF NOT EXISTS habit_bundles (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_habit_bundles PRIMARY KEY (id),
    CONSTRAINT uq_habit_bundles_uuid UNIQUE (uuid),
    CONSTRAINT uq_habit_bundles_user_id_name UNIQUE (user_id, name),
    CONSTRAINT fk_habit_bundles_user_id_user FOREIGN KEY (user_id)
        REFERENCES app_user (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_habit_bundles_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_habit_bundles_display_order_non_negative CHECK (display_order >= 0)
);

COMMENT ON TABLE habit_bundles IS
    'User-owned collections that group habits into reusable bundles.';
COMMENT ON COLUMN habit_bundles.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN habit_bundles.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN habit_bundles.user_id IS
    'Foreign key to the owning user account.';
COMMENT ON COLUMN habit_bundles.name IS
    'Human-readable bundle name.';
COMMENT ON COLUMN habit_bundles.description IS
    'Optional longer description of the bundle.';
COMMENT ON COLUMN habit_bundles.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN habit_bundles.is_active IS
    'Indicates whether the bundle is active and available for use.';
COMMENT ON COLUMN habit_bundles.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN habit_bundles.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: map habits into bundles using an associative table.
CREATE TABLE IF NOT EXISTS bundle_members (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    habit_bundle_id BIGINT NOT NULL,
    habit_id BIGINT NOT NULL,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_bundle_members PRIMARY KEY (id),
    CONSTRAINT uq_bundle_members_uuid UNIQUE (uuid),
    CONSTRAINT uq_bundle_members_habit_bundle_id_habit_id UNIQUE (habit_bundle_id, habit_id),
    CONSTRAINT fk_bundle_members_habit_bundle_id_habit_bundles FOREIGN KEY (habit_bundle_id)
        REFERENCES habit_bundles (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_bundle_members_habit_id_habits FOREIGN KEY (habit_id)
        REFERENCES habits (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT ck_bundle_members_display_order_non_negative CHECK (display_order >= 0)
);

COMMENT ON TABLE bundle_members IS
    'Associative table linking habits to bundles with optional display ordering.';
COMMENT ON COLUMN bundle_members.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN bundle_members.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN bundle_members.habit_bundle_id IS
    'Foreign key to the owning habit bundle.';
COMMENT ON COLUMN bundle_members.habit_id IS
    'Foreign key to the linked habit.';
COMMENT ON COLUMN bundle_members.display_order IS
    'Non-negative ordering value used to control presentation order inside the bundle.';
COMMENT ON COLUMN bundle_members.is_active IS
    'Indicates whether the bundle membership is active and available for use.';
COMMENT ON COLUMN bundle_members.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN bundle_members.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store the immutable history of habit execution events.
CREATE TABLE IF NOT EXISTS habit_logs (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    habit_id BIGINT NOT NULL,
    logged_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completion_status VARCHAR(20) NOT NULL DEFAULT 'completed',
    value NUMERIC(12, 2) NOT NULL DEFAULT 1,
    notes TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_habit_logs PRIMARY KEY (id),
    CONSTRAINT uq_habit_logs_uuid UNIQUE (uuid),
    CONSTRAINT fk_habit_logs_habit_id_habits FOREIGN KEY (habit_id)
        REFERENCES habits (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_habit_logs_completion_status_valid CHECK (completion_status IN ('completed', 'skipped', 'missed', 'partial')),
    CONSTRAINT ck_habit_logs_value_non_negative CHECK (value >= 0)
);

COMMENT ON TABLE habit_logs IS
    'Immutable append-only history of habit completion events.';
COMMENT ON COLUMN habit_logs.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN habit_logs.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN habit_logs.habit_id IS
    'Foreign key to the habit that was logged.';
COMMENT ON COLUMN habit_logs.logged_at IS
    'Timestamp when the habit event occurred.';
COMMENT ON COLUMN habit_logs.completion_status IS
    'Normalized status describing the outcome of the habit event.';
COMMENT ON COLUMN habit_logs.value IS
    'Numeric value associated with the logged event, such as repetitions or duration.';
COMMENT ON COLUMN habit_logs.notes IS
    'Optional free-form notes captured when the log entry was created.';
COMMENT ON COLUMN habit_logs.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN habit_logs.updated_at IS
    'Timestamp when the row was created; the row is immutable and never updated.';
COMMENT ON COLUMN habit_logs.is_active IS
    'Indicates whether the log entry is considered active and visible.';

-- Purpose: store reminder schedules for habits with support for multiple reminders per habit.
CREATE TABLE IF NOT EXISTS habit_reminders (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    habit_id BIGINT NOT NULL,
    reminder_day_of_week SMALLINT NOT NULL,
    reminder_time TIME WITHOUT TIME ZONE NOT NULL,
    lead_minutes INTEGER NOT NULL DEFAULT 0,
    reminder_label VARCHAR(150),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_habit_reminders PRIMARY KEY (id),
    CONSTRAINT uq_habit_reminders_uuid UNIQUE (uuid),
    CONSTRAINT uq_habit_reminders_habit_id_day_time UNIQUE (habit_id, reminder_day_of_week, reminder_time),
    CONSTRAINT fk_habit_reminders_habit_id_habits FOREIGN KEY (habit_id)
        REFERENCES habits (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_habit_reminders_day_of_week_valid CHECK (reminder_day_of_week BETWEEN 1 AND 7),
    CONSTRAINT ck_habit_reminders_lead_minutes_non_negative CHECK (lead_minutes >= 0),
    CONSTRAINT ck_habit_reminders_label_not_blank CHECK (reminder_label IS NULL OR length(btrim(reminder_label)) > 0)
);

COMMENT ON TABLE habit_reminders IS
    'Recurring reminder definitions for habits, allowing multiple reminder rows per habit.';
COMMENT ON COLUMN habit_reminders.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN habit_reminders.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN habit_reminders.habit_id IS
    'Foreign key to the habit that owns the reminder.';
COMMENT ON COLUMN habit_reminders.reminder_day_of_week IS
    'Day of week for the reminder, where 1 = Monday and 7 = Sunday.';
COMMENT ON COLUMN habit_reminders.reminder_time IS
    'Local time at which the reminder should fire.';
COMMENT ON COLUMN habit_reminders.lead_minutes IS
    'Non-negative lead time in minutes before the scheduled reminder moment.';
COMMENT ON COLUMN habit_reminders.reminder_label IS
    'Optional label that describes the purpose of the reminder.';
COMMENT ON COLUMN habit_reminders.is_active IS
    'Indicates whether the reminder is active and available for use.';
COMMENT ON COLUMN habit_reminders.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN habit_reminders.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: keep updated_at synchronized on mutable habit tables.
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.set_updated_at() IS
    'Reusable BEFORE UPDATE trigger helper that refreshes updated_at using the current timestamp.';

-- Purpose: prevent any modifications to habit_logs so the history remains append-only.
CREATE OR REPLACE FUNCTION public.prevent_habit_log_mutations()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'habit_logs are immutable and cannot be updated';
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'habit_logs are immutable and cannot be deleted';
    END IF;

    RETURN NULL;
END;
$$;

COMMENT ON FUNCTION public.prevent_habit_log_mutations() IS
    'Trigger helper that blocks UPDATE and DELETE operations on habit_logs.';

-- Purpose: apply updated_at maintenance to mutable tables.
DROP TRIGGER IF EXISTS trg_habit_categories_set_updated_at ON habit_categories;
CREATE TRIGGER trg_habit_categories_set_updated_at
BEFORE UPDATE ON habit_categories
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_habits_set_updated_at ON habits;
CREATE TRIGGER trg_habits_set_updated_at
BEFORE UPDATE ON habits
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_habit_bundles_set_updated_at ON habit_bundles;
CREATE TRIGGER trg_habit_bundles_set_updated_at
BEFORE UPDATE ON habit_bundles
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_bundle_members_set_updated_at ON bundle_members;
CREATE TRIGGER trg_bundle_members_set_updated_at
BEFORE UPDATE ON bundle_members
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_habit_reminders_set_updated_at ON habit_reminders;
CREATE TRIGGER trg_habit_reminders_set_updated_at
BEFORE UPDATE ON habit_reminders
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- Purpose: enforce append-only behavior for habit_logs.
DROP TRIGGER IF EXISTS trg_habit_logs_prevent_update ON habit_logs;
CREATE TRIGGER trg_habit_logs_prevent_update
BEFORE UPDATE ON habit_logs
FOR EACH ROW
EXECUTE FUNCTION public.prevent_habit_log_mutations();

DROP TRIGGER IF EXISTS trg_habit_logs_prevent_delete ON habit_logs;
CREATE TRIGGER trg_habit_logs_prevent_delete
BEFORE DELETE ON habit_logs
FOR EACH ROW
EXECUTE FUNCTION public.prevent_habit_log_mutations();

-- Purpose: create targeted indexes that support common lookup paths without over-indexing.
CREATE INDEX IF NOT EXISTS idx_habits_user_id ON habits (user_id);
CREATE INDEX IF NOT EXISTS idx_habits_habit_category_id ON habits (habit_category_id);
CREATE INDEX IF NOT EXISTS idx_habit_bundles_user_id ON habit_bundles (user_id);
CREATE INDEX IF NOT EXISTS idx_bundle_members_habit_id ON bundle_members (habit_id);
CREATE INDEX IF NOT EXISTS idx_habit_logs_habit_id_logged_at ON habit_logs (habit_id, logged_at DESC);
