-- MVP-30: Create Leagues Table
-- This migration creates the leagues table to store Yahoo Fantasy Sports league information

-- Create leagues table
CREATE TABLE IF NOT EXISTS public.leagues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    yahoo_league_key TEXT NOT NULL,
    yahoo_game_key TEXT NOT NULL,
    name TEXT NOT NULL,
    season INTEGER NOT NULL,
    league_type TEXT NOT NULL CHECK (league_type IN ('public', 'private')),
    scoring_type TEXT NOT NULL CHECK (scoring_type IN ('head', 'roto')),
    draft_type TEXT NOT NULL CHECK (draft_type IN ('live', 'offline', 'autopick')),
    num_teams INTEGER NOT NULL CHECK (num_teams > 0),
    sync_status TEXT NOT NULL DEFAULT 'pending' CHECK (sync_status IN ('pending', 'in_progress', 'completed', 'failed')),
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create unique constraint on yahoo_league_key, season, user_id combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_leagues_unique_combination 
ON public.leagues(yahoo_league_key, season, user_id);

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_leagues_user_id ON public.leagues(user_id);
CREATE INDEX IF NOT EXISTS idx_leagues_yahoo_league_key ON public.leagues(yahoo_league_key);
CREATE INDEX IF NOT EXISTS idx_leagues_sync_status ON public.leagues(sync_status);
CREATE INDEX IF NOT EXISTS idx_leagues_season ON public.leagues(season);
CREATE INDEX IF NOT EXISTS idx_leagues_created_at ON public.leagues(created_at);

-- Add comments for documentation
COMMENT ON TABLE public.leagues IS 'Stores Yahoo Fantasy Sports league information and sync status';
COMMENT ON COLUMN public.leagues.id IS 'Primary key UUID';
COMMENT ON COLUMN public.leagues.user_id IS 'Reference to user who owns this league';
COMMENT ON COLUMN public.leagues.yahoo_league_key IS 'Unique Yahoo league identifier';
COMMENT ON COLUMN public.leagues.yahoo_game_key IS 'Yahoo game identifier (e.g., 2024 for NFL 2024)';
COMMENT ON COLUMN public.leagues.name IS 'League name';
COMMENT ON COLUMN public.leagues.season IS 'Season year (e.g., 2024)';
COMMENT ON COLUMN public.leagues.league_type IS 'League type: public or private';
COMMENT ON COLUMN public.leagues.scoring_type IS 'Scoring type: head-to-head or rotisserie';
COMMENT ON COLUMN public.leagues.draft_type IS 'Draft type: live, offline, or autopick';
COMMENT ON COLUMN public.leagues.num_teams IS 'Number of teams in the league';
COMMENT ON COLUMN public.leagues.sync_status IS 'Current sync status for this league';
COMMENT ON COLUMN public.leagues.last_sync_at IS 'Timestamp of last successful sync';
COMMENT ON COLUMN public.leagues.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN public.leagues.updated_at IS 'Record last update timestamp';

-- Enable Row Level Security
ALTER TABLE public.leagues ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own leagues" ON public.leagues
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can update own leagues" ON public.leagues
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own leagues" ON public.leagues
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own leagues" ON public.leagues
  FOR DELETE
  USING (auth.uid() = user_id);

-- Grant permissions
GRANT ALL ON TABLE public.leagues TO authenticated;

-- Create trigger for updated_at
CREATE TRIGGER handle_leagues_updated_at
  BEFORE UPDATE ON public.leagues
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
