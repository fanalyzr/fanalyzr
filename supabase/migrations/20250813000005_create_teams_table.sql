-- MVP-31: Create Teams Table
-- This migration creates the teams table to store team information, owner details, and season statistics

-- Create teams table
CREATE TABLE IF NOT EXISTS public.teams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    league_id UUID NOT NULL REFERENCES public.leagues(id) ON DELETE CASCADE,
    yahoo_team_key TEXT NOT NULL,
    yahoo_team_id INTEGER NOT NULL,
    name TEXT NOT NULL,
    owner_name TEXT NOT NULL,
    owner_guid TEXT,
    is_current_user BOOLEAN DEFAULT FALSE,
    wins INTEGER DEFAULT 0,
    losses INTEGER DEFAULT 0,
    ties INTEGER DEFAULT 0,
    points_for DECIMAL(10,2) DEFAULT 0,
    points_against DECIMAL(10,2) DEFAULT 0,
    rank INTEGER,
    playoff_seed INTEGER,
    division_id INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create unique constraint on yahoo_team_key, league_id combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_teams_unique_combination 
ON public.teams(yahoo_team_key, league_id);

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_teams_league_id ON public.teams(league_id);
CREATE INDEX IF NOT EXISTS idx_teams_yahoo_team_key ON public.teams(yahoo_team_key);
CREATE INDEX IF NOT EXISTS idx_teams_is_current_user ON public.teams(is_current_user);
CREATE INDEX IF NOT EXISTS idx_teams_owner_guid ON public.teams(owner_guid);
CREATE INDEX IF NOT EXISTS idx_teams_rank ON public.teams(rank);
CREATE INDEX IF NOT EXISTS idx_teams_created_at ON public.teams(created_at);

-- Add comments for documentation
COMMENT ON TABLE public.teams IS 'Stores team information, owner details, and season statistics';
COMMENT ON COLUMN public.teams.id IS 'Primary key UUID';
COMMENT ON COLUMN public.teams.league_id IS 'Reference to league this team belongs to';
COMMENT ON COLUMN public.teams.yahoo_team_key IS 'Unique Yahoo team identifier';
COMMENT ON COLUMN public.teams.yahoo_team_id IS 'Yahoo team ID number';
COMMENT ON COLUMN public.teams.name IS 'Team name';
COMMENT ON COLUMN public.teams.owner_name IS 'Team owner name';
COMMENT ON COLUMN public.teams.owner_guid IS 'Yahoo owner GUID';
COMMENT ON COLUMN public.teams.is_current_user IS 'Whether this team belongs to the current user';
COMMENT ON COLUMN public.teams.wins IS 'Number of wins this season';
COMMENT ON COLUMN public.teams.losses IS 'Number of losses this season';
COMMENT ON COLUMN public.teams.ties IS 'Number of ties this season';
COMMENT ON COLUMN public.teams.points_for IS 'Total points scored this season';
COMMENT ON COLUMN public.teams.points_against IS 'Total points against this season';
COMMENT ON COLUMN public.teams.rank IS 'Current league rank';
COMMENT ON COLUMN public.teams.playoff_seed IS 'Playoff seed (if applicable)';
COMMENT ON COLUMN public.teams.division_id IS 'Division ID (if applicable)';
COMMENT ON COLUMN public.teams.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN public.teams.updated_at IS 'Record last update timestamp';

-- Enable Row Level Security
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (users can access teams in their own leagues)
CREATE POLICY "Users can view teams in own leagues" ON public.teams
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = teams.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update teams in own leagues" ON public.teams
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = teams.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert teams in own leagues" ON public.teams
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = teams.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete teams in own leagues" ON public.teams
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = teams.league_id 
      AND l.user_id = auth.uid()
    )
  );

-- Grant permissions
GRANT ALL ON TABLE public.teams TO authenticated;

-- Create trigger for updated_at
CREATE TRIGGER handle_teams_updated_at
  BEFORE UPDATE ON public.teams
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
