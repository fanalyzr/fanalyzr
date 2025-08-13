-- Rename profiles table to user_profiles for better naming convention
-- This migration renames the table and updates all related database objects

-- Step 1: Rename the table
ALTER TABLE public.profiles RENAME TO user_profiles;

-- Step 2: Drop existing policies (they will be recreated with new table name)
DROP POLICY IF EXISTS "Users can view own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profiles;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.user_profiles;

-- Step 3: Recreate RLS policies with the new table name
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

-- Step 4: Update the handle_new_user function to reference user_profiles table
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.user_profiles (id, created_at, updated_at)
  VALUES (NEW.id, NOW(), NOW())
  ON CONFLICT (id) DO UPDATE SET
    updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 5: Add name columns if they don't exist (for future use)
DO $$
BEGIN
  -- Add first_name column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'user_profiles' AND column_name = 'first_name') THEN
    ALTER TABLE public.user_profiles ADD COLUMN first_name TEXT;
  END IF;
  
  -- Add last_name column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'user_profiles' AND column_name = 'last_name') THEN
    ALTER TABLE public.user_profiles ADD COLUMN last_name TEXT;
  END IF;
  
  -- Add full_name column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'user_profiles' AND column_name = 'full_name') THEN
    ALTER TABLE public.user_profiles ADD COLUMN full_name TEXT;
  END IF;
END $$;

-- Step 6: Create or update the generate_full_name function (BEFORE creating triggers)
CREATE OR REPLACE FUNCTION public.generate_full_name()
RETURNS TRIGGER AS $$
BEGIN
  -- Generate full_name from first_name and last_name
  IF NEW.first_name IS NOT NULL OR NEW.last_name IS NOT NULL THEN
    NEW.full_name = TRIM(CONCAT(COALESCE(NEW.first_name, ''), ' ', COALESCE(NEW.last_name, '')));
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Step 7: Update triggers to work with the new table name (AFTER creating functions)
-- Drop existing triggers first
DROP TRIGGER IF EXISTS handle_updated_at ON public.user_profiles;
DROP TRIGGER IF EXISTS generate_full_name_trigger ON public.user_profiles;

-- Recreate the updated_at trigger
CREATE TRIGGER handle_updated_at
  BEFORE UPDATE ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Recreate the full_name generation trigger
CREATE TRIGGER generate_full_name_trigger
  BEFORE INSERT OR UPDATE OF first_name, last_name ON public.user_profiles
  FOR EACH ROW EXECUTE FUNCTION public.generate_full_name();
