-- Purpose: Add more system foods with correct macros, serving units, and piece/household conversion metadata.

INSERT INTO food_items (
    name, category, serving_unit,
    reference_quantity, reference_weight,
    calories, protein, carbs, fat, fiber,
    is_system, display_order,
    grams_per_piece, household_unit, household_quantity, household_grams
) VALUES
    ('Salmon', 'SEAFOOD', 'GRAM', 100.00, 100.00, 208.00, 20.00, 0.00, 13.00, 0.00, TRUE, 30, NULL, NULL, NULL, NULL),
    ('Beef', 'MEAT', 'GRAM', 100.00, 100.00, 250.00, 26.00, 0.00, 15.00, 0.00, TRUE, 31, NULL, NULL, NULL, NULL),
    ('Whole Wheat Bread', 'GRAINS', 'PIECE', 1.00, 28.00, 69.00, 3.60, 12.00, 0.90, 1.90, TRUE, 32, 28.0000, NULL, NULL, NULL),
    ('Peanut Butter', 'NUTS', 'TABLESPOON', 1.00, 16.00, 94.00, 4.00, 3.00, 8.00, 1.00, TRUE, 33, 16.0000, 'TABLESPOON', 1.0000, 16.0000),
    ('Avocado', 'FRUITS', 'PIECE', 1.00, 150.00, 240.00, 3.00, 12.00, 22.00, 10.00, TRUE, 34, 150.0000, NULL, NULL, NULL),
    ('Greek Yogurt', 'DAIRY', 'GRAM', 100.00, 100.00, 59.00, 10.00, 3.60, 0.40, 0.00, TRUE, 35, NULL, NULL, NULL, NULL),
    ('Honey', 'OTHER', 'TEASPOON', 1.00, 7.00, 21.00, 0.00, 6.00, 0.00, 0.00, TRUE, 36, 7.0000, 'TEASPOON', 1.0000, 7.0000);
