-- Purpose: create the analytics domain schema for LifeTracker.
-- This migration adds the daily snapshot, achievement catalog, and user
-- achievement unlock tables while intentionally avoiding any persisted life
-- score or derived scoring tables.

-- Purpose: store one snapshot per user per day for lightweight daily analytics.
CREATE TABLE IF NOT EXISTS daily_summary (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    summary_date DATE NOT NULL,
    snapshot_data JSONB,
    generated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_daily_summary PRIMARY KEY (id),
    CONSTRAINT uq_daily_summary_uuid UNIQUE (uuid),
    CONSTRAINT uq_daily_summary_user_id_summary_date UNIQUE (user_id, summary_date),
    CONSTRAINT fk_daily_summary_user_id_user FOREIGN KEY (user_id)
        REFERENCES app_user (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_daily_summary_snapshot_data_object CHECK (snapshot_data IS NULL OR jsonb_typeof(snapshot_data) = 'object')
);

COMMENT ON TABLE daily_summary IS
    'One-per-day analytics snapshot for a user. The table stores snapshot data, not computed life scores.';
COMMENT ON COLUMN daily_summary.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN daily_summary.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN daily_summary.user_id IS
    'Foreign key to the owning user account.';
COMMENT ON COLUMN daily_summary.summary_date IS
    'Calendar date represented by this snapshot.';
COMMENT ON COLUMN daily_summary.snapshot_data IS
    'Optional JSON snapshot payload used to store bounded day-level analytics details. If queryable metrics grow, promote them into typed columns in a future migration.';
COMMENT ON COLUMN daily_summary.generated_at IS
    'Timestamp when the snapshot was generated.';
COMMENT ON COLUMN daily_summary.is_active IS
    'Indicates whether the snapshot row is active and visible.';
COMMENT ON COLUMN daily_summary.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN daily_summary.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store the master list of achievements that can be unlocked by users.
CREATE TABLE IF NOT EXISTS achievements (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    code VARCHAR(100) NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    badge_key VARCHAR(100),
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_achievements PRIMARY KEY (id),
    CONSTRAINT uq_achievements_uuid UNIQUE (uuid),
    CONSTRAINT uq_achievements_code UNIQUE (code),
    CONSTRAINT ck_achievements_code_not_blank CHECK (length(btrim(code)) > 0),
    CONSTRAINT ck_achievements_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_achievements_display_order_non_negative CHECK (display_order >= 0),
    CONSTRAINT ck_achievements_badge_key_not_blank CHECK (badge_key IS NULL OR length(btrim(badge_key)) > 0)
);

COMMENT ON TABLE achievements IS
    'Master achievement catalog defining the badges or milestones users can unlock.';
COMMENT ON COLUMN achievements.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN achievements.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN achievements.code IS
    'Unique machine-readable business code for the achievement.';
COMMENT ON COLUMN achievements.name IS
    'Human-readable achievement name.';
COMMENT ON COLUMN achievements.description IS
    'Optional longer description of the achievement.';
COMMENT ON COLUMN achievements.badge_key IS
    'Optional identifier used to map the achievement to badge artwork or assets.';
COMMENT ON COLUMN achievements.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN achievements.is_active IS
    'Indicates whether the achievement is active and available for use.';
COMMENT ON COLUMN achievements.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN achievements.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store achievements unlocked by users.
CREATE TABLE IF NOT EXISTS user_achievements (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    achievement_id BIGINT NOT NULL,
    unlocked_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source_key VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_user_achievements PRIMARY KEY (id),
    CONSTRAINT uq_user_achievements_uuid UNIQUE (uuid),
    CONSTRAINT uq_user_achievements_user_id_achievement_id UNIQUE (user_id, achievement_id),
    CONSTRAINT fk_user_achievements_user_id_user FOREIGN KEY (user_id)
        REFERENCES app_user (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_user_achievements_achievement_id_achievements FOREIGN KEY (achievement_id)
        REFERENCES achievements (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_user_achievements_source_key_not_blank CHECK (source_key IS NULL OR length(btrim(source_key)) > 0)
);

COMMENT ON TABLE user_achievements IS
    'Association table that records which achievements have been unlocked by a user.';
COMMENT ON COLUMN user_achievements.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN user_achievements.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN user_achievements.user_id IS
    'Foreign key to the owning user account.';
COMMENT ON COLUMN user_achievements.achievement_id IS
    'Foreign key to the unlocked achievement.';
COMMENT ON COLUMN user_achievements.unlocked_at IS
    'Timestamp when the achievement was unlocked.';
COMMENT ON COLUMN user_achievements.source_key IS
    'Optional machine-readable source marker explaining how the achievement was earned.';
COMMENT ON COLUMN user_achievements.is_active IS
    'Indicates whether the unlocked achievement row is active and visible.';
COMMENT ON COLUMN user_achievements.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN user_achievements.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: keep updated_at synchronized on mutable analytics tables.
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

-- Purpose: apply updated_at maintenance to mutable analytics tables.
DROP TRIGGER IF EXISTS trg_daily_summary_set_updated_at ON daily_summary;
CREATE TRIGGER trg_daily_summary_set_updated_at
BEFORE UPDATE ON daily_summary
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_achievements_set_updated_at ON achievements;
CREATE TRIGGER trg_achievements_set_updated_at
BEFORE UPDATE ON achievements
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_user_achievements_set_updated_at ON user_achievements;
CREATE TRIGGER trg_user_achievements_set_updated_at
BEFORE UPDATE ON user_achievements
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- Purpose: create targeted indexes that support common lookup paths without over-indexing.
CREATE INDEX IF NOT EXISTS idx_daily_summary_summary_date ON daily_summary (summary_date DESC);
CREATE INDEX IF NOT EXISTS idx_achievements_display_order ON achievements (display_order);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON user_achievements (achievement_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id_unlocked_at ON user_achievements (user_id, unlocked_at DESC);
