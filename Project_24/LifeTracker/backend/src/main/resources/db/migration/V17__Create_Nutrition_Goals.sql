-- Purpose: create per-user nutrition goals for the Daily Nutrition Dashboard.

CREATE TABLE IF NOT EXISTS nutrition_goals (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    owner_user_id BIGINT NOT NULL,
    calorie_goal NUMERIC(8, 2) NOT NULL DEFAULT 2500,
    protein_goal NUMERIC(8, 2) NOT NULL DEFAULT 150,
    carbs_goal NUMERIC(8, 2) NOT NULL DEFAULT 300,
    fat_goal NUMERIC(8, 2) NOT NULL DEFAULT 70,
    fiber_goal NUMERIC(8, 2) NOT NULL DEFAULT 35,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_nutrition_goals PRIMARY KEY (id),
    CONSTRAINT uq_nutrition_goals_uuid UNIQUE (uuid),
    CONSTRAINT uq_nutrition_goals_owner_user_id UNIQUE (owner_user_id),
    CONSTRAINT fk_nutrition_goals_owner_user_id_user FOREIGN KEY (owner_user_id)
        REFERENCES app_user (id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,
    CONSTRAINT ck_nutrition_goals_calorie_goal_positive CHECK (calorie_goal > 0),
    CONSTRAINT ck_nutrition_goals_protein_goal_non_negative CHECK (protein_goal >= 0),
    CONSTRAINT ck_nutrition_goals_carbs_goal_non_negative CHECK (carbs_goal >= 0),
    CONSTRAINT ck_nutrition_goals_fat_goal_non_negative CHECK (fat_goal >= 0),
    CONSTRAINT ck_nutrition_goals_fiber_goal_non_negative CHECK (fiber_goal >= 0)
);

CREATE INDEX IF NOT EXISTS idx_nutrition_goals_owner_user_id ON nutrition_goals (owner_user_id);

DROP TRIGGER IF EXISTS trg_nutrition_goals_set_updated_at ON nutrition_goals;
CREATE TRIGGER trg_nutrition_goals_set_updated_at
BEFORE UPDATE ON nutrition_goals
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();
