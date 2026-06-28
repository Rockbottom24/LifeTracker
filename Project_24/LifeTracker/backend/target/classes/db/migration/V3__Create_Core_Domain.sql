-- Purpose: create the core LifeTracker domain tables that own the application
-- account record and its one-to-one configuration tables.
-- The table name app_user is used instead of the reserved PostgreSQL keyword user.

-- Purpose: store the primary application account record for each LifeTracker user.
CREATE TABLE IF NOT EXISTS app_user (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    email VARCHAR(255) NOT NULL,
    display_name VARCHAR(150),
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_app_user PRIMARY KEY (id),
    CONSTRAINT uq_app_user_uuid UNIQUE (uuid),
    CONSTRAINT uq_app_user_email UNIQUE (email),
    CONSTRAINT ck_app_user_email_not_blank CHECK (length(btrim(email)) > 0)
);

COMMENT ON TABLE app_user IS
    'Primary application account record used as the parent for user-specific settings.';
COMMENT ON COLUMN app_user.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN app_user.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN app_user.email IS
    'Unique email address used to identify the account.';
COMMENT ON COLUMN app_user.display_name IS
    'Optional display name shown in the application UI.';
COMMENT ON COLUMN app_user.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN app_user.updated_at IS
    'Timestamp when the row was last updated.';
COMMENT ON COLUMN app_user.is_active IS
    'Indicates whether the account is active and available for use.';

-- Purpose: store profile-level configuration that is owned one-to-one by a user.
CREATE TABLE IF NOT EXISTS user_settings (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    timezone VARCHAR(64) NOT NULL DEFAULT 'UTC',
    locale VARCHAR(16) NOT NULL DEFAULT 'en_US',
    theme_mode VARCHAR(20) NOT NULL DEFAULT 'system',
    week_start_day SMALLINT NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_user_settings PRIMARY KEY (id),
    CONSTRAINT uq_user_settings_uuid UNIQUE (uuid),
    CONSTRAINT uq_user_settings_user_id UNIQUE (user_id),
    CONSTRAINT fk_user_settings_user_id_user FOREIGN KEY (user_id)
        REFERENCES app_user (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT ck_user_settings_timezone_not_blank CHECK (length(btrim(timezone)) > 0),
    CONSTRAINT ck_user_settings_locale_not_blank CHECK (length(btrim(locale)) > 0),
    CONSTRAINT ck_user_settings_theme_mode_valid CHECK (theme_mode IN ('system', 'light', 'dark')),
    CONSTRAINT ck_user_settings_week_start_day_valid CHECK (week_start_day BETWEEN 1 AND 7)
);

COMMENT ON TABLE user_settings IS
    'One-to-one user profile settings owned by the corresponding application account.';
COMMENT ON COLUMN user_settings.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN user_settings.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN user_settings.user_id IS
    'Foreign key to the owning user account.';
COMMENT ON COLUMN user_settings.timezone IS
    'IANA timezone identifier used for user-specific date and time rendering.';
COMMENT ON COLUMN user_settings.locale IS
    'Locale tag used for user-specific language and regional formatting.';
COMMENT ON COLUMN user_settings.theme_mode IS
    'Preferred UI theme mode for the user.';
COMMENT ON COLUMN user_settings.week_start_day IS
    'Preferred first day of the week, where 1 = Monday and 7 = Sunday.';
COMMENT ON COLUMN user_settings.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN user_settings.updated_at IS
    'Timestamp when the row was last updated.';
COMMENT ON COLUMN user_settings.is_active IS
    'Indicates whether the settings record is active and available for use.';

-- Purpose: store one-to-one notification preferences owned by each user.
CREATE TABLE IF NOT EXISTS notification_settings (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    email_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    push_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    in_app_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    digest_notifications_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    reminder_notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT pk_notification_settings PRIMARY KEY (id),
    CONSTRAINT uq_notification_settings_uuid UNIQUE (uuid),
    CONSTRAINT uq_notification_settings_user_id UNIQUE (user_id),
    CONSTRAINT fk_notification_settings_user_id_user FOREIGN KEY (user_id)
        REFERENCES app_user (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

COMMENT ON TABLE notification_settings IS
    'One-to-one notification preference record owned by the corresponding user account.';
COMMENT ON COLUMN notification_settings.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN notification_settings.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN notification_settings.user_id IS
    'Foreign key to the owning user account.';
COMMENT ON COLUMN notification_settings.email_notifications_enabled IS
    'Controls whether email notifications are enabled for the user.';
COMMENT ON COLUMN notification_settings.push_notifications_enabled IS
    'Controls whether push notifications are enabled for the user.';
COMMENT ON COLUMN notification_settings.in_app_notifications_enabled IS
    'Controls whether in-app notifications are enabled for the user.';
COMMENT ON COLUMN notification_settings.digest_notifications_enabled IS
    'Controls whether notification digests are enabled for the user.';
COMMENT ON COLUMN notification_settings.reminder_notifications_enabled IS
    'Controls whether reminder notifications are enabled for the user.';
COMMENT ON COLUMN notification_settings.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN notification_settings.updated_at IS
    'Timestamp when the row was last updated.';
COMMENT ON COLUMN notification_settings.is_active IS
    'Indicates whether the settings record is active and available for use.';
