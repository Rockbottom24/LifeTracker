-- Purpose: create learning_sessions for the LifeTracker learning module.

CREATE TABLE IF NOT EXISTS learning_sessions (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT,
    topic VARCHAR(100),
    resource_type VARCHAR(50),
    resource_url TEXT,
    planned_minutes INTEGER NOT NULL DEFAULT 0,
    completed_minutes INTEGER NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'PLANNED',
    priority VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    scheduled_date DATE,
    completed_date DATE,
    reminder_time TIME,
    notifications_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    color_hex VARCHAR(20),
    icon_name VARCHAR(50),
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_learning_sessions PRIMARY KEY (id),
    CONSTRAINT uq_learning_sessions_uuid UNIQUE (uuid),
    CONSTRAINT ck_learning_sessions_title_not_blank CHECK (length(btrim(title)) > 0),
    CONSTRAINT ck_learning_sessions_planned_minutes_non_negative CHECK (planned_minutes >= 0),
    CONSTRAINT ck_learning_sessions_completed_minutes_non_negative CHECK (completed_minutes >= 0),
    CONSTRAINT ck_learning_sessions_display_order_non_negative CHECK (display_order >= 0),
    CONSTRAINT ck_learning_sessions_status CHECK (status IN ('PLANNED', 'IN_PROGRESS', 'COMPLETED', 'SKIPPED')),
    CONSTRAINT ck_learning_sessions_priority CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH'))
);

CREATE INDEX IF NOT EXISTS idx_learning_sessions_user_id ON learning_sessions (user_id);
CREATE INDEX IF NOT EXISTS idx_learning_sessions_scheduled_date ON learning_sessions (scheduled_date);
CREATE INDEX IF NOT EXISTS idx_learning_sessions_status ON learning_sessions (status);

DROP TRIGGER IF EXISTS trg_learning_sessions_set_updated_at ON learning_sessions;
CREATE TRIGGER trg_learning_sessions_set_updated_at
BEFORE UPDATE ON learning_sessions
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
