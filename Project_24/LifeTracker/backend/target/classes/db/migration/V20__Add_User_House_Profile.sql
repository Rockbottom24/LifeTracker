ALTER TABLE app_user
    ADD COLUMN IF NOT EXISTS first_name VARCHAR(150),
    ADD COLUMN IF NOT EXISTS house_key VARCHAR(50);

UPDATE app_user
SET first_name = COALESCE(NULLIF(first_name, ''), display_name),
    house_key = COALESCE(NULLIF(house_key, ''), 'stark')
WHERE first_name IS NULL OR house_key IS NULL;
