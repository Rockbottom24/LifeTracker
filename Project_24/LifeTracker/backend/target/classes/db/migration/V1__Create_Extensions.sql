-- Purpose: enable only the PostgreSQL extensions that are genuinely useful for
-- the LifeTracker production schema.
--
-- Extension: pgcrypto
-- Why it exists:
-- - Provides modern, built-in cryptographic functions that are commonly used in
--   PostgreSQL-backed applications.
-- - Most importantly for this project, it exposes `gen_random_uuid()`, which is
--   the preferred database-side UUID generator on PostgreSQL 16.
-- - This supports the requirement to use UUIDs for business entities without
--   introducing unnecessary dependencies.
--
-- No other extensions are enabled here because the current project requirements
-- do not justify them. In particular, `uuid-ossp` is not needed when `pgcrypto`
-- already provides a reliable UUID generator.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
