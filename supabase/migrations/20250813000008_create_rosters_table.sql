-- MVP-34: Create Rosters Table
-- This migration creates the rosters table to store team lineup information by week and season

-- Create rosters table
CREATE TABLE IF NOT EXISTS public.rosters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    week INTEGER NOT NULL,
    season INTEGER NOT NULL,
    players JSONB NOT NULL DEFAULT '[]'::jsonb,
    total_points DECIMAL(10,2) DEFAULT 0,
    projected_points DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create unique constraint on team_id, week, season combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_rosters_unique_combination 
ON public.rosters(team_id, week, season);

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_rosters_team_id ON public.rosters(team_id);
CREATE INDEX IF NOT EXISTS idx_rosters_team_season ON public.rosters(team_id, season);
CREATE INDEX IF NOT EXISTS idx_rosters_team_season_week ON public.rosters(team_id, season, week);
CREATE INDEX IF NOT EXISTS idx_rosters_week ON public.rosters(week);
CREATE INDEX IF NOT EXISTS idx_rosters_season ON public.rosters(season);
CREATE INDEX IF NOT EXISTS idx_rosters_total_points ON public.rosters(total_points);
CREATE INDEX IF NOT EXISTS idx_rosters_created_at ON public.rosters(created_at);

-- Create GIN index for JSONB players column
CREATE INDEX IF NOT EXISTS idx_rosters_players_gin ON public.rosters USING GIN(players);

-- Add comments for documentation
COMMENT ON TABLE public.rosters IS 'Stores team lineup information by week and season';
COMMENT ON COLUMN public.rosters.id IS 'Primary key UUID';
COMMENT ON COLUMN public.rosters.team_id IS 'Reference to team';
COMMENT ON COLUMN public.rosters.week IS 'Week number in the season';
COMMENT ON COLUMN public.rosters.season IS 'Season year';
COMMENT ON COLUMN public.rosters.players IS 'Array of players in roster with position and starter info';
COMMENT ON COLUMN public.rosters.total_points IS 'Total points scored by this roster';
COMMENT ON COLUMN public.rosters.projected_points IS 'Projected points for this roster';
COMMENT ON COLUMN public.rosters.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN public.rosters.updated_at IS 'Record last update timestamp';

-- Enable Row Level Security
ALTER TABLE public.rosters ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (users can access rosters for teams in their own leagues)
CREATE POLICY "Users can view rosters in own leagues" ON public.rosters
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.teams t
      JOIN public.leagues l ON l.id = t.league_id
      WHERE t.id = rosters.team_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update rosters in own leagues" ON public.rosters
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.teams t
      JOIN public.leagues l ON l.id = t.league_id
      WHERE t.id = rosters.team_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert rosters in own leagues" ON public.rosters
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.teams t
      JOIN public.leagues l ON l.id = t.league_id
      WHERE t.id = rosters.team_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete rosters in own leagues" ON public.rosters
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.teams t
      JOIN public.leagues l ON l.id = t.league_id
      WHERE t.id = rosters.team_id 
      AND l.user_id = auth.uid()
    )
  );

-- Grant permissions
GRANT ALL ON TABLE public.rosters TO authenticated;

-- Create trigger for updated_at
CREATE TRIGGER handle_rosters_updated_at
  BEFORE UPDATE ON public.rosters
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
