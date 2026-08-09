-- Purpose: add food household/piece conversion metadata, expand serving-unit checks,
-- seed piece weights for countable system foods, and add habit points with log snapshots.

-- Food conversion metadata (additive; existing rows remain valid).
ALTER TABLE food_items
    ADD COLUMN IF NOT EXISTS grams_per_piece NUMERIC(10, 4),
    ADD COLUMN IF NOT EXISTS household_unit VARCHAR(20),
    ADD COLUMN IF NOT EXISTS household_quantity NUMERIC(10, 4),
    ADD COLUMN IF NOT EXISTS household_grams NUMERIC(10, 4);

COMMENT ON COLUMN food_items.grams_per_piece IS
    'Optional grams per single piece/count for countable foods whose primary nutrition basis may be mass.';
COMMENT ON COLUMN food_items.household_unit IS
    'Optional household unit from label/barcode (TABLESPOON, TEASPOON, SERVING, PIECE, SCOOP, CUP).';
COMMENT ON COLUMN food_items.household_quantity IS
    'Quantity of household_unit that equals household_grams (e.g. 2 for 2 tbsp).';
COMMENT ON COLUMN food_items.household_grams IS
    'Gram weight of household_quantity household units (e.g. 32 for 2 tbsp).';

ALTER TABLE food_items
    DROP CONSTRAINT IF EXISTS ck_food_items_serving_unit;

ALTER TABLE food_items
    ADD CONSTRAINT ck_food_items_serving_unit CHECK (serving_unit IN (
        'GRAM', 'KILOGRAM', 'ML', 'LITER', 'PIECE', 'TABLESPOON', 'TEASPOON', 'CUP', 'SCOOP', 'SERVING'
    ));

ALTER TABLE food_items
    DROP CONSTRAINT IF EXISTS ck_food_items_household_unit;

ALTER TABLE food_items
    ADD CONSTRAINT ck_food_items_household_unit CHECK (
        household_unit IS NULL OR household_unit IN (
            'GRAM', 'KILOGRAM', 'ML', 'LITER', 'PIECE', 'TABLESPOON', 'TEASPOON', 'CUP', 'SCOOP', 'SERVING'
        )
    );

ALTER TABLE food_items
    DROP CONSTRAINT IF EXISTS ck_food_items_grams_per_piece_positive;

ALTER TABLE food_items
    ADD CONSTRAINT ck_food_items_grams_per_piece_positive CHECK (
        grams_per_piece IS NULL OR grams_per_piece > 0
    );

ALTER TABLE food_items
    DROP CONSTRAINT IF EXISTS ck_food_items_household_conversion_consistent;

ALTER TABLE food_items
    ADD CONSTRAINT ck_food_items_household_conversion_consistent CHECK (
        (household_unit IS NULL AND household_quantity IS NULL AND household_grams IS NULL)
        OR (
            household_unit IS NOT NULL
            AND household_quantity IS NOT NULL AND household_quantity > 0
            AND household_grams IS NOT NULL AND household_grams > 0
        )
    );

-- Countable system foods: enable piece logging via grams-per-piece while keeping per-100g basis.
UPDATE food_items
SET grams_per_piece = 1.20
WHERE lower(name) = 'almonds' AND grams_per_piece IS NULL;

UPDATE food_items
SET grams_per_piece = 1.60
WHERE lower(name) = 'cashews' AND grams_per_piece IS NULL;

-- Eggs already use PIECE reference; mirror grams-per-piece from reference weight.
UPDATE food_items
SET grams_per_piece = CASE
    WHEN reference_quantity IS NOT NULL AND reference_quantity > 0
        THEN round(reference_weight / reference_quantity, 4)
    ELSE reference_weight
END
WHERE lower(name) = 'egg' AND serving_unit = 'PIECE' AND grams_per_piece IS NULL;

-- Habit points (user-defined) and historical snapshot on completion logs.
ALTER TABLE habits
    ADD COLUMN IF NOT EXISTS points INTEGER NOT NULL DEFAULT 0;

ALTER TABLE habits
    DROP CONSTRAINT IF EXISTS ck_habits_points_non_negative;

ALTER TABLE habits
    ADD CONSTRAINT ck_habits_points_non_negative CHECK (points >= 0);

ALTER TABLE habit_logs
    ADD COLUMN IF NOT EXISTS points_awarded INTEGER NOT NULL DEFAULT 0;

ALTER TABLE habit_logs
    DROP CONSTRAINT IF EXISTS ck_habit_logs_points_awarded_non_negative;

ALTER TABLE habit_logs
    ADD CONSTRAINT ck_habit_logs_points_awarded_non_negative CHECK (points_awarded >= 0);

COMMENT ON COLUMN habits.points IS
    'User-defined honor points awarded when this habit is completed.';
COMMENT ON COLUMN habit_logs.points_awarded IS
    'Snapshot of habit points at completion time; used for historical honor totals.';
