-- Purpose: create meal_logs and meal_log_items tables for the Nutrition meal logger.

CREATE TABLE IF NOT EXISTS meal_logs (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    owner_user_id BIGINT NOT NULL,
    meal_type VARCHAR(20) NOT NULL,
    meal_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_meal_logs PRIMARY KEY (id),
    CONSTRAINT uq_meal_logs_uuid UNIQUE (uuid),
    CONSTRAINT fk_meal_logs_owner_user_id_user FOREIGN KEY (owner_user_id)
        REFERENCES app_user (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_meal_logs_meal_type CHECK (meal_type IN ('BREAKFAST', 'LUNCH', 'SNACK', 'DINNER'))
);

CREATE INDEX IF NOT EXISTS idx_meal_logs_owner_user_id ON meal_logs (owner_user_id);
CREATE INDEX IF NOT EXISTS idx_meal_logs_meal_date ON meal_logs (meal_date);
CREATE INDEX IF NOT EXISTS idx_meal_logs_owner_user_id_meal_date ON meal_logs (owner_user_id, meal_date);

DROP TRIGGER IF EXISTS trg_meal_logs_set_updated_at ON meal_logs;
CREATE TRIGGER trg_meal_logs_set_updated_at
BEFORE UPDATE ON meal_logs
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE IF NOT EXISTS meal_log_items (
    id BIGSERIAL,
    meal_log_id BIGINT NOT NULL,
    food_item_id BIGINT NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    calories NUMERIC(10, 2) NOT NULL DEFAULT 0,
    protein NUMERIC(10, 2) NOT NULL DEFAULT 0,
    carbs NUMERIC(10, 2) NOT NULL DEFAULT 0,
    fat NUMERIC(10, 2) NOT NULL DEFAULT 0,
    fiber NUMERIC(10, 2) NOT NULL DEFAULT 0,
    display_order INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT pk_meal_log_items PRIMARY KEY (id),
    CONSTRAINT fk_meal_log_items_meal_log_id FOREIGN KEY (meal_log_id)
        REFERENCES meal_logs (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT fk_meal_log_items_food_item_id FOREIGN KEY (food_item_id)
        REFERENCES food_items (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_meal_log_items_quantity_positive CHECK (quantity > 0),
    CONSTRAINT ck_meal_log_items_display_order_non_negative CHECK (display_order >= 0),
    CONSTRAINT ck_meal_log_items_calories_non_negative CHECK (calories >= 0),
    CONSTRAINT ck_meal_log_items_protein_non_negative CHECK (protein >= 0),
    CONSTRAINT ck_meal_log_items_carbs_non_negative CHECK (carbs >= 0),
    CONSTRAINT ck_meal_log_items_fat_non_negative CHECK (fat >= 0),
    CONSTRAINT ck_meal_log_items_fiber_non_negative CHECK (fiber >= 0),
    CONSTRAINT ck_meal_log_items_unit CHECK (unit IN (
        'GRAM', 'ML', 'PIECE', 'TABLESPOON', 'TEASPOON', 'CUP', 'SCOOP'
    ))
);

CREATE INDEX IF NOT EXISTS idx_meal_log_items_meal_log_id ON meal_log_items (meal_log_id);
CREATE INDEX IF NOT EXISTS idx_meal_log_items_food_item_id ON meal_log_items (food_item_id);
