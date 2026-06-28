-- Purpose: require non-blank category on expenses.

UPDATE expenses
SET category = 'Uncategorized'
WHERE category IS NULL OR length(btrim(category)) = 0;

ALTER TABLE expenses
    ALTER COLUMN category SET NOT NULL;

ALTER TABLE expenses
    DROP CONSTRAINT IF EXISTS ck_expenses_category_not_blank;

ALTER TABLE expenses
    ADD CONSTRAINT ck_expenses_category_not_blank CHECK (length(btrim(category)) > 0);
