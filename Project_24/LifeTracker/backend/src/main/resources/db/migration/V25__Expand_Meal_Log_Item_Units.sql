-- Purpose: allow meal_log_items to store KILOGRAM, LITER, and SERVING quantities
-- introduced for household/piece conversions and mass/volume scaling.

ALTER TABLE meal_log_items
    DROP CONSTRAINT IF EXISTS ck_meal_log_items_unit;

ALTER TABLE meal_log_items
    ADD CONSTRAINT ck_meal_log_items_unit CHECK (unit IN (
        'GRAM', 'KILOGRAM', 'ML', 'LITER', 'PIECE',
        'TABLESPOON', 'TEASPOON', 'CUP', 'SCOOP', 'SERVING'
    ));
