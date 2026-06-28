-- Purpose: create food_items table and seed system foods for the Nutrition module.

CREATE TABLE IF NOT EXISTS food_items (
    id BIGSERIAL,
    uuid UUID NOT NULL DEFAULT gen_random_uuid(),
    owner_user_id BIGINT,
    name VARCHAR(150) NOT NULL,
    category VARCHAR(30) NOT NULL,
    serving_unit VARCHAR(20) NOT NULL,
    calories_per_100g NUMERIC(8, 2) NOT NULL DEFAULT 0,
    protein_per_100g NUMERIC(8, 2) NOT NULL DEFAULT 0,
    carbs_per_100g NUMERIC(8, 2) NOT NULL DEFAULT 0,
    fat_per_100g NUMERIC(8, 2) NOT NULL DEFAULT 0,
    fiber_per_100g NUMERIC(8, 2) NOT NULL DEFAULT 0,
    is_system BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_food_items PRIMARY KEY (id),
    CONSTRAINT uq_food_items_uuid UNIQUE (uuid),
    CONSTRAINT fk_food_items_owner_user_id_user FOREIGN KEY (owner_user_id)
        REFERENCES app_user (id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT ck_food_items_name_not_blank CHECK (length(btrim(name)) > 0),
    CONSTRAINT ck_food_items_display_order_non_negative CHECK (display_order >= 0),
    CONSTRAINT ck_food_items_calories_non_negative CHECK (calories_per_100g >= 0),
    CONSTRAINT ck_food_items_protein_non_negative CHECK (protein_per_100g >= 0),
    CONSTRAINT ck_food_items_carbs_non_negative CHECK (carbs_per_100g >= 0),
    CONSTRAINT ck_food_items_fat_non_negative CHECK (fat_per_100g >= 0),
    CONSTRAINT ck_food_items_fiber_non_negative CHECK (fiber_per_100g >= 0),
    CONSTRAINT ck_food_items_category CHECK (category IN (
        'GRAINS', 'VEGETABLES', 'FRUITS', 'MEAT', 'SEAFOOD', 'EGGS', 'DAIRY',
        'LEGUMES', 'NUTS', 'SEEDS', 'OILS', 'BEVERAGES', 'SUPPLEMENTS', 'SNACKS', 'OTHER'
    )),
    CONSTRAINT ck_food_items_serving_unit CHECK (serving_unit IN (
        'GRAM', 'ML', 'PIECE', 'TABLESPOON', 'TEASPOON', 'CUP', 'SCOOP'
    )),
    CONSTRAINT ck_food_items_system_owner CHECK (
        (is_system = TRUE AND owner_user_id IS NULL)
        OR (is_system = FALSE AND owner_user_id IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS idx_food_items_owner_user_id ON food_items (owner_user_id);
CREATE INDEX IF NOT EXISTS idx_food_items_is_system ON food_items (is_system);
CREATE INDEX IF NOT EXISTS idx_food_items_is_active ON food_items (is_active);
CREATE INDEX IF NOT EXISTS idx_food_items_name ON food_items (name);

DROP TRIGGER IF EXISTS trg_food_items_set_updated_at ON food_items;
CREATE TRIGGER trg_food_items_set_updated_at
BEFORE UPDATE ON food_items
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at();

INSERT INTO food_items (
    name, category, serving_unit,
    calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g,
    is_system, display_order
) VALUES
    ('Egg', 'EGGS', 'PIECE', 155, 13.00, 1.10, 11.00, 0.00, TRUE, 1),
    ('Chicken Breast', 'MEAT', 'GRAM', 165, 31.00, 0.00, 3.60, 0.00, TRUE, 2),
    ('Chicken Thigh', 'MEAT', 'GRAM', 209, 26.00, 0.00, 11.00, 0.00, TRUE, 3),
    ('Rice', 'GRAINS', 'GRAM', 130, 2.70, 28.00, 0.30, 0.40, TRUE, 4),
    ('Brown Rice', 'GRAINS', 'GRAM', 111, 2.60, 23.00, 0.90, 1.80, TRUE, 5),
    ('Oats', 'GRAINS', 'GRAM', 389, 17.00, 66.00, 7.00, 10.00, TRUE, 6),
    ('Milk', 'DAIRY', 'ML', 61, 3.20, 4.80, 3.30, 0.00, TRUE, 7),
    ('Curd', 'DAIRY', 'GRAM', 59, 10.00, 3.60, 0.40, 0.00, TRUE, 8),
    ('Paneer', 'DAIRY', 'GRAM', 265, 18.00, 3.60, 20.00, 0.00, TRUE, 9),
    ('Tofu', 'LEGUMES', 'GRAM', 76, 8.00, 1.90, 4.80, 0.30, TRUE, 10),
    ('Green Moong', 'LEGUMES', 'GRAM', 347, 24.00, 63.00, 1.20, 16.00, TRUE, 11),
    ('Brown Chickpeas', 'LEGUMES', 'GRAM', 364, 19.00, 61.00, 6.00, 17.00, TRUE, 12),
    ('Peanuts', 'NUTS', 'GRAM', 567, 26.00, 16.00, 49.00, 8.50, TRUE, 13),
    ('Almonds', 'NUTS', 'GRAM', 579, 21.00, 22.00, 50.00, 12.00, TRUE, 14),
    ('Cashews', 'NUTS', 'GRAM', 553, 18.00, 30.00, 44.00, 3.30, TRUE, 15),
    ('Banana', 'FRUITS', 'PIECE', 89, 1.10, 23.00, 0.30, 2.60, TRUE, 16),
    ('Apple', 'FRUITS', 'PIECE', 52, 0.30, 14.00, 0.20, 2.40, TRUE, 17),
    ('Potato', 'VEGETABLES', 'GRAM', 77, 2.00, 17.00, 0.10, 2.20, TRUE, 18),
    ('Sweet Potato', 'VEGETABLES', 'GRAM', 86, 1.60, 20.00, 0.10, 3.00, TRUE, 19),
    ('Onion', 'VEGETABLES', 'GRAM', 40, 1.10, 9.30, 0.10, 1.70, TRUE, 20),
    ('Tomato', 'VEGETABLES', 'GRAM', 18, 0.90, 3.90, 0.20, 1.20, TRUE, 21),
    ('Capsicum', 'VEGETABLES', 'GRAM', 31, 1.00, 6.00, 0.30, 2.10, TRUE, 22),
    ('Spinach', 'VEGETABLES', 'GRAM', 23, 2.90, 3.60, 0.40, 2.20, TRUE, 23),
    ('Broccoli', 'VEGETABLES', 'GRAM', 34, 2.80, 7.00, 0.40, 2.60, TRUE, 24),
    ('Mushroom', 'VEGETABLES', 'GRAM', 22, 3.10, 3.30, 0.30, 1.00, TRUE, 25),
    ('Olive Oil', 'OILS', 'GRAM', 884, 0.00, 0.00, 100.00, 0.00, TRUE, 26),
    ('Butter', 'DAIRY', 'GRAM', 717, 0.90, 0.10, 81.00, 0.00, TRUE, 27),
    ('Protein Powder', 'SUPPLEMENTS', 'SCOOP', 400, 80.00, 10.00, 5.00, 2.00, TRUE, 28),
    ('Creatine', 'SUPPLEMENTS', 'GRAM', 0, 0.00, 0.00, 0.00, 0.00, TRUE, 29);
