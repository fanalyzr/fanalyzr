-- MVP-28: Extend User Profiles with Yahoo OAuth Fields
-- This migration adds Yahoo OAuth authentication fields to the user_profiles table

-- Add Yahoo OAuth fields to user_profiles table
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS yahoo_guid TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS yahoo_access_token TEXT,
ADD COLUMN IF NOT EXISTS yahoo_refresh_token TEXT,
ADD COLUMN IF NOT EXISTS token_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS sync_preferences JSONB DEFAULT '{"auto_sync": false, "sync_frequency": "manual"}'::jsonb;

-- Create index on yahoo_guid for efficient lookups
CREATE INDEX IF NOT EXISTS idx_user_profiles_yahoo_guid ON public.user_profiles(yahoo_guid);

-- Add comments for documentation
COMMENT ON COLUMN public.user_profiles.yahoo_guid IS 'Unique Yahoo user identifier';
COMMENT ON COLUMN public.user_profiles.yahoo_access_token IS 'Yahoo OAuth access token (encrypted)';
COMMENT ON COLUMN public.user_profiles.yahoo_refresh_token IS 'Yahoo OAuth refresh token (encrypted)';
COMMENT ON COLUMN public.user_profiles.token_expires_at IS 'Timestamp when access token expires';
COMMENT ON COLUMN public.user_profiles.sync_preferences IS 'JSON object containing sync preferences and settings';

-- Update RLS policies to include new columns
-- Drop existing policies first
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.user_profiles;

-- Recreate policies with updated column access
CREATE POLICY "Users can view own profile" ON public.user_profiles
  FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.user_profiles
  FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.user_profiles
  FOR INSERT
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete own profile" ON public.user_profiles
  FOR DELETE
  USING (auth.uid() = id);
