-- Purpose: refactor food_items so nutrition values are stored per reference serving
-- instead of assuming every food is defined per 100g.
-- This migration is additive and preserves the existing table so historical data
-- remains available while the application transitions to reference-serving math.

-- Purpose: add reference-serving columns and canonical nutrition columns.
ALTER TABLE food_items
    ADD COLUMN IF NOT EXISTS reference_quantity NUMERIC(10, 2) NOT NULL DEFAULT 100,
    ADD COLUMN IF NOT EXISTS reference_weight NUMERIC(10, 2) NOT NULL DEFAULT 100,
    ADD COLUMN IF NOT EXISTS calories NUMERIC(8, 2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS protein NUMERIC(8, 2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS carbs NUMERIC(8, 2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS fat NUMERIC(8, 2) NOT NULL DEFAULT 0,
    ADD COLUMN IF NOT EXISTS fiber NUMERIC(8, 2) NOT NULL DEFAULT 0;

COMMENT ON COLUMN food_items.reference_quantity IS
    'Reference amount for the serving unit, such as 1 piece, 1 scoop, or 100 grams.';
COMMENT ON COLUMN food_items.reference_weight IS
    'Gram-equivalent weight for the reference quantity, used by the generic nutrition calculator.';
COMMENT ON COLUMN food_items.calories IS
    'Calories stored per reference serving.';
COMMENT ON COLUMN food_items.protein IS
    'Protein stored per reference serving.';
COMMENT ON COLUMN food_items.carbs IS
    'Carbohydrates stored per reference serving.';
COMMENT ON COLUMN food_items.fat IS
    'Fat stored per reference serving.';
COMMENT ON COLUMN food_items.fiber IS
    'Fiber stored per reference serving.';

-- Purpose: backfill existing rows so the application can use the new columns immediately.
UPDATE food_items
SET
    reference_quantity = 100,
    reference_weight = 100,
    calories = calories_per_100g,
    protein = protein_per_100g,
    carbs = carbs_per_100g,
    fat = fat_per_100g,
    fiber = fiber_per_100g
WHERE reference_quantity IS NULL
   OR reference_weight IS NULL
   OR calories = 0
   OR protein = 0
   OR carbs = 0
   OR fat = 0
   OR fiber = 0;

-- Purpose: seed realistic reference-serving values for the common foods already
-- provided by the Nutrition module.
UPDATE food_items
SET serving_unit = 'PIECE', reference_quantity = 1, reference_weight = 50, calories = 72, protein = 6.3, carbs = 0.4, fat = 4.8, fiber = 0
WHERE name = 'Egg';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 165, protein = 31, carbs = 0, fat = 3.6, fiber = 0
WHERE name = 'Chicken Breast';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 209, protein = 26, carbs = 0, fat = 11, fiber = 0
WHERE name = 'Chicken Thigh';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 130, protein = 2.7, carbs = 28, fat = 0.3, fiber = 0.4
WHERE name = 'Rice';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 111, protein = 2.6, carbs = 23, fat = 0.9, fiber = 1.8
WHERE name = 'Brown Rice';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 389, protein = 17, carbs = 66, fat = 7, fiber = 10
WHERE name = 'Oats';

UPDATE food_items
SET serving_unit = 'ML', reference_quantity = 250, reference_weight = 250, calories = 149, protein = 7.7, carbs = 12, fat = 8, fiber = 0
WHERE name = 'Milk';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 59, protein = 10, carbs = 3.6, fat = 0.4, fiber = 0
WHERE name = 'Curd';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 265, protein = 18, carbs = 3.6, fat = 20, fiber = 0
WHERE name = 'Paneer';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 76, protein = 8, carbs = 1.9, fat = 4.8, fiber = 0.3
WHERE name = 'Tofu';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 347, protein = 24, carbs = 63, fat = 1.2, fiber = 16
WHERE name = 'Green Moong';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 364, protein = 19, carbs = 61, fat = 6, fiber = 17
WHERE name = 'Brown Chickpeas';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 567, protein = 26, carbs = 16, fat = 49, fiber = 8.5
WHERE name = 'Peanuts';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 579, protein = 21, carbs = 22, fat = 50, fiber = 12
WHERE name = 'Almonds';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 553, protein = 18, carbs = 30, fat = 44, fiber = 3.3
WHERE name = 'Cashews';

UPDATE food_items
SET serving_unit = 'PIECE', reference_quantity = 1, reference_weight = 118, calories = 105, protein = 1.3, carbs = 27, fat = 0.4, fiber = 3.1
WHERE name = 'Banana';

UPDATE food_items
SET serving_unit = 'PIECE', reference_quantity = 1, reference_weight = 182, calories = 95, protein = 0.5, carbs = 25, fat = 0.3, fiber = 4.4
WHERE name = 'Apple';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 77, protein = 2, carbs = 17, fat = 0.1, fiber = 2.2
WHERE name = 'Potato';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 86, protein = 1.6, carbs = 20, fat = 0.1, fiber = 3
WHERE name = 'Sweet Potato';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 40, protein = 1.1, carbs = 9.3, fat = 0.1, fiber = 1.7
WHERE name = 'Onion';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 18, protein = 0.9, carbs = 3.9, fat = 0.2, fiber = 1.2
WHERE name = 'Tomato';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 31, protein = 1, carbs = 6, fat = 0.3, fiber = 2.1
WHERE name = 'Capsicum';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 23, protein = 2.9, carbs = 3.6, fat = 0.4, fiber = 2.2
WHERE name = 'Spinach';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 34, protein = 2.8, carbs = 7, fat = 0.4, fiber = 2.6
WHERE name = 'Broccoli';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 100, reference_weight = 100, calories = 22, protein = 3.1, carbs = 3.3, fat = 0.3, fiber = 1
WHERE name = 'Mushroom';

UPDATE food_items
SET serving_unit = 'TABLESPOON', reference_quantity = 1, reference_weight = 13.50, calories = 119, protein = 0, carbs = 0, fat = 13.50, fiber = 0
WHERE name = 'Olive Oil';

UPDATE food_items
SET serving_unit = 'TABLESPOON', reference_quantity = 1, reference_weight = 14.20, calories = 102, protein = 0.1, carbs = 0, fat = 11.50, fiber = 0
WHERE name = 'Butter';

UPDATE food_items
SET serving_unit = 'SCOOP', reference_quantity = 1, reference_weight = 30, calories = 120, protein = 24, carbs = 3, fat = 2, fiber = 1.5
WHERE name = 'Protein Powder';

UPDATE food_items
SET serving_unit = 'GRAM', reference_quantity = 5, reference_weight = 5, calories = 0, protein = 0, carbs = 0, fat = 0, fiber = 0
WHERE name = 'Creatine';
