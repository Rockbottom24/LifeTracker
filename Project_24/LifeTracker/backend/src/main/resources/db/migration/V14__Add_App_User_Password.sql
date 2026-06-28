-- Purpose: add password storage for JWT authentication.
ALTER TABLE app_user
    ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);

COMMENT ON COLUMN app_user.password_hash IS
    'BCrypt hash of the user password used for authentication.';
