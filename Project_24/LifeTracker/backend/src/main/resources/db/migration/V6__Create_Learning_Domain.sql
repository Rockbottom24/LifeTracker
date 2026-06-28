-- Purpose: create the learning domain schema for LifeTracker.
-- This migration adds the goal, subject, topic, study session, and study note
-- tables required for structured learning workflows without storing progress or
-- revision tracking data.

-- Purpose: store top-level learning goals for structured study planning.
CREATE TABLE IF NOT EXISTS learning_goals (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    name VARCHAR(150) NOT NULL,
    description TEXT,
    target_date DATE,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_learning_goals PRIMARY KEY (id),
    CONSTRAINT uq_learning_goals_uuid UNIQUE (uuid),
    CONSTRAINT ck_learning_goals_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_learning_goals_display_order_non_negative CHECK (display_order >= 0)
);

COMMENT ON TABLE learning_goals IS
    'Top-level learning objectives that organize a structured study plan.';
COMMENT ON COLUMN learning_goals.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN learning_goals.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN learning_goals.name IS
    'Human-readable learning goal name.';
COMMENT ON COLUMN learning_goals.description IS
    'Optional longer description of the learning goal.';
COMMENT ON COLUMN learning_goals.target_date IS
    'Optional date by which the learning goal should be achieved.';
COMMENT ON COLUMN learning_goals.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN learning_goals.is_active IS
    'Indicates whether the learning goal is active and available for use.';
COMMENT ON COLUMN learning_goals.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN learning_goals.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store learning subjects that belong to a learning goal.
CREATE TABLE IF NOT EXISTS learning_subjects (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    learning_goal_id BIGINT NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_learning_subjects PRIMARY KEY (id),
    CONSTRAINT uq_learning_subjects_uuid UNIQUE (uuid),
    CONSTRAINT uq_learning_subjects_learning_goal_id_name UNIQUE (learning_goal_id, name),
    CONSTRAINT fk_learning_subjects_learning_goal_id_learning_goals FOREIGN KEY (learning_goal_id)
        REFERENCES learning_goals (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_learning_subjects_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_learning_subjects_display_order_non_negative CHECK (display_order >= 0)
);

COMMENT ON TABLE learning_subjects IS
    'Subjects grouped under a learning goal to organize the study plan.';
COMMENT ON COLUMN learning_subjects.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN learning_subjects.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN learning_subjects.learning_goal_id IS
    'Foreign key to the parent learning goal.';
COMMENT ON COLUMN learning_subjects.name IS
    'Human-readable subject name.';
COMMENT ON COLUMN learning_subjects.description IS
    'Optional longer description of the subject.';
COMMENT ON COLUMN learning_subjects.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN learning_subjects.is_active IS
    'Indicates whether the learning subject is active and available for use.';
COMMENT ON COLUMN learning_subjects.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN learning_subjects.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store learning topics that belong to a subject.
CREATE TABLE IF NOT EXISTS learning_topics (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    learning_subject_id BIGINT NOT NULL,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    display_order INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_learning_topics PRIMARY KEY (id),
    CONSTRAINT uq_learning_topics_uuid UNIQUE (uuid),
    CONSTRAINT uq_learning_topics_learning_subject_id_name UNIQUE (learning_subject_id, name),
    CONSTRAINT fk_learning_topics_learning_subject_id_learning_subjects FOREIGN KEY (learning_subject_id)
        REFERENCES learning_subjects (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_learning_topics_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_learning_topics_display_order_non_negative CHECK (display_order >= 0)
);

COMMENT ON TABLE learning_topics IS
    'Topics grouped under a subject to organize study content at a finer level.';
COMMENT ON COLUMN learning_topics.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN learning_topics.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN learning_topics.learning_subject_id IS
    'Foreign key to the parent learning subject.';
COMMENT ON COLUMN learning_topics.name IS
    'Human-readable topic name.';
COMMENT ON COLUMN learning_topics.description IS
    'Optional longer description of the topic.';
COMMENT ON COLUMN learning_topics.display_order IS
    'Non-negative ordering value used to control presentation order.';
COMMENT ON COLUMN learning_topics.is_active IS
    'Indicates whether the learning topic is active and available for use.';
COMMENT ON COLUMN learning_topics.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN learning_topics.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: store immutable study sessions linked to a learning topic.
CREATE TABLE IF NOT EXISTS study_sessions (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    learning_topic_id BIGINT NOT NULL,
    session_started_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    session_completed_at TIMESTAMP WITHOUT TIME ZONE,
    session_status VARCHAR(20) NOT NULL DEFAULT 'planned',
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_study_sessions PRIMARY KEY (id),
    CONSTRAINT uq_study_sessions_uuid UNIQUE (uuid),
    CONSTRAINT fk_study_sessions_learning_topic_id_learning_topics FOREIGN KEY (learning_topic_id)
        REFERENCES learning_topics (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_study_sessions_session_status_valid CHECK (session_status IN ('planned', 'in_progress', 'completed', 'cancelled')),
    CONSTRAINT ck_study_sessions_session_completed_at_not_before_started_at CHECK (session_completed_at IS NULL OR session_completed_at >= session_started_at)
);

COMMENT ON TABLE study_sessions IS
    'Immutable records of study execution linked to a learning topic.';
COMMENT ON COLUMN study_sessions.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN study_sessions.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN study_sessions.learning_topic_id IS
    'Foreign key to the learning topic that owns the study session.';
COMMENT ON COLUMN study_sessions.session_started_at IS
    'Timestamp when the study session started.';
COMMENT ON COLUMN study_sessions.session_completed_at IS
    'Optional timestamp when the study session completed.';
COMMENT ON COLUMN study_sessions.session_status IS
    'Lifecycle status of the study session.';
COMMENT ON COLUMN study_sessions.notes IS
    'Optional free-form notes captured for the study session.';
COMMENT ON COLUMN study_sessions.is_active IS
    'Indicates whether the study session is active and visible.';
COMMENT ON COLUMN study_sessions.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN study_sessions.updated_at IS
    'Timestamp when the row was created; immutable sessions are never updated.';

-- Purpose: store notes captured during a study session.
CREATE TABLE IF NOT EXISTS study_notes (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    study_session_id BIGINT NOT NULL,
    note_number INTEGER NOT NULL,
    note_text TEXT NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_study_notes PRIMARY KEY (id),
    CONSTRAINT uq_study_notes_uuid UNIQUE (uuid),
    CONSTRAINT uq_study_notes_study_session_id_note_number UNIQUE (study_session_id, note_number),
    CONSTRAINT fk_study_notes_study_session_id_study_sessions FOREIGN KEY (study_session_id)
        REFERENCES study_sessions (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_study_notes_note_number_positive CHECK (note_number > 0),
    CONSTRAINT ck_study_notes_note_text_not_blank CHECK (length(btrim(note_text)) > 0)
);

COMMENT ON TABLE study_notes IS
    'Notes captured within a study session, stored as a child record of the session.';
COMMENT ON COLUMN study_notes.id IS
    'Surrogate primary key for internal relational joins and indexing.';
COMMENT ON COLUMN study_notes.uuid IS
    'Stable external identifier used by application code and APIs.';
COMMENT ON COLUMN study_notes.study_session_id IS
    'Foreign key to the study session that owns the note.';
COMMENT ON COLUMN study_notes.note_number IS
    'Positive sequence number of the note within the study session.';
COMMENT ON COLUMN study_notes.note_text IS
    'Body of the study note.';
COMMENT ON COLUMN study_notes.is_active IS
    'Indicates whether the note is active and visible.';
COMMENT ON COLUMN study_notes.created_at IS
    'Timestamp when the row was created.';
COMMENT ON COLUMN study_notes.updated_at IS
    'Timestamp when the row was last updated.';

-- Purpose: keep updated_at synchronized on mutable learning tables.
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

-- Purpose: prevent any modifications to study_sessions so the history remains immutable.
CREATE OR REPLACE FUNCTION public.prevent_study_session_mutations()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'study_sessions are immutable and cannot be updated';
    ELSIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'study_sessions are immutable and cannot be deleted';
    END IF;

    RETURN NULL;
END;
$$;

COMMENT ON FUNCTION public.prevent_study_session_mutations() IS
    'Trigger helper that blocks UPDATE and DELETE operations on study_sessions.';

-- Purpose: apply updated_at maintenance to mutable learning tables.
DROP TRIGGER IF EXISTS trg_learning_goals_set_updated_at ON learning_goals;
CREATE TRIGGER trg_learning_goals_set_updated_at
BEFORE UPDATE ON learning_goals
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_learning_subjects_set_updated_at ON learning_subjects;
CREATE TRIGGER trg_learning_subjects_set_updated_at
BEFORE UPDATE ON learning_subjects
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_learning_topics_set_updated_at ON learning_topics;
CREATE TRIGGER trg_learning_topics_set_updated_at
BEFORE UPDATE ON learning_topics
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_study_notes_set_updated_at ON study_notes;
CREATE TRIGGER trg_study_notes_set_updated_at
BEFORE UPDATE ON study_notes
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

-- Purpose: enforce immutability for study_sessions.
DROP TRIGGER IF EXISTS trg_study_sessions_prevent_update ON study_sessions;
CREATE TRIGGER trg_study_sessions_prevent_update
BEFORE UPDATE ON study_sessions
FOR EACH ROW
EXECUTE FUNCTION public.prevent_study_session_mutations();

DROP TRIGGER IF EXISTS trg_study_sessions_prevent_delete ON study_sessions;
CREATE TRIGGER trg_study_sessions_prevent_delete
BEFORE DELETE ON study_sessions
FOR EACH ROW
EXECUTE FUNCTION public.prevent_study_session_mutations();

-- Purpose: create targeted indexes that support common lookup paths without over-indexing.
CREATE INDEX IF NOT EXISTS idx_study_sessions_learning_topic_id ON study_sessions (learning_topic_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_session_started_at ON study_sessions (session_started_at DESC);
