-- Purpose: create expenses table for the LifeTracker money module.

CREATE TABLE IF NOT EXISTS expenses (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    user_id BIGINT NOT NULL,
    expense_type VARCHAR(20) NOT NULL DEFAULT 'PERSONAL',
    category VARCHAR(100),
    title VARCHAR(150) NOT NULL,
    description TEXT,
    amount NUMERIC(12, 2) NOT NULL,
    expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_mode VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_expenses PRIMARY KEY (id),
    CONSTRAINT uq_expenses_uuid UNIQUE (uuid),
    CONSTRAINT fk_expenses_user_id_user FOREIGN KEY (user_id)
        REFERENCES app_user (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_expenses_title_not_blank CHECK (length(btrim(title)) > 0),
    CONSTRAINT ck_expenses_amount_positive CHECK (amount > 0),
    CONSTRAINT ck_expenses_type CHECK (expense_type IN ('PERSONAL', 'SHARED_LIVING', 'FAMILY'))
);

CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses (user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_expense_date ON expenses (expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_expense_type ON expenses (expense_type);

DROP TRIGGER IF EXISTS trg_expenses_set_updated_at ON expenses;
CREATE TRIGGER trg_expenses_set_updated_at
BEFORE UPDATE ON expenses
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
