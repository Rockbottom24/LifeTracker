-- Add the missing color_hex column to habits to match the Habit entity mapping.
-- This is an additive, non-destructive change for existing databases.

ALTER TABLE habits
    ADD COLUMN IF NOT EXISTS color_hex VARCHAR(20);

COMMENT ON COLUMN habits.color_hex IS
    'Optional hex color value used to style the habit in the UI.';
