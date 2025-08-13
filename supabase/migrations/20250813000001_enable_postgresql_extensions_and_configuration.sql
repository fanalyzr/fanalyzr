-- MVP-27: Enable PostgreSQL Extensions and Configuration
-- This migration sets up required extensions and configuration for Yahoo Fantasy Sports integration

-- Enable required PostgreSQL extensions (already enabled, but ensuring they exist)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Set encryption key for database (this should be configured via environment variables in production)
-- Note: In production, this should be set via environment variables, not hardcoded
-- For development, we'll use a placeholder that should be replaced with actual key
-- Commented out due to permission restrictions in local development
-- DO $$
-- BEGIN
--   -- Only set if not already set
--   IF current_setting('app.encryption_key', true) IS NULL THEN
--     ALTER DATABASE postgres SET "app.encryption_key" = 'your-32-character-encryption-key-here';
--   END IF;
-- END $$

-- Instead, we'll set it at the session level for this migration
SET "app.encryption_key" = 'your-32-character-encryption-key-here';;

-- Verify extensions are working (this will fail if extensions are not properly installed)
SELECT uuid_generate_v4() as test_uuid;
SELECT encode(encrypt('test'::bytea, 'test-key'::bytea, 'aes'), 'base64') as test_encryption;

-- Add comment for documentation
COMMENT ON DATABASE postgres IS 'Database configured for Yahoo Fantasy Sports integration with encryption support';
