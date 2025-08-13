-- MVP-35: Create Games Table
-- This migration creates the games table to store matchup information and scores

-- Create games table
CREATE TABLE IF NOT EXISTS public.games (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    league_id UUID NOT NULL REFERENCES public.leagues(id) ON DELETE CASCADE,
    week INTEGER NOT NULL,
    season INTEGER NOT NULL,
    home_team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    away_team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    home_score DECIMAL(10,2),
    away_score DECIMAL(10,2),
    home_projected DECIMAL(10,2),
    away_projected DECIMAL(10,2),
    is_playoff BOOLEAN DEFAULT FALSE,
    is_consolation BOOLEAN DEFAULT FALSE,
    is_complete BOOLEAN DEFAULT FALSE,
    winner_id UUID REFERENCES public.teams(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Ensure home and away teams are different
    CONSTRAINT games_different_teams CHECK (home_team_id != away_team_id),
    -- Ensure scores are non-negative
    CONSTRAINT games_non_negative_scores CHECK (
        (home_score IS NULL OR home_score >= 0) AND 
        (away_score IS NULL OR away_score >= 0) AND
        (home_projected IS NULL OR home_projected >= 0) AND 
        (away_projected IS NULL OR away_projected >= 0)
    )
);

-- Create unique constraint on league_id, week, season, home_team_id, away_team_id combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_games_unique_combination 
ON public.games(league_id, week, season, home_team_id, away_team_id);

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_games_league_id ON public.games(league_id);
CREATE INDEX IF NOT EXISTS idx_games_league_season_week ON public.games(league_id, season, week);
CREATE INDEX IF NOT EXISTS idx_games_home_team_id ON public.games(home_team_id);
CREATE INDEX IF NOT EXISTS idx_games_away_team_id ON public.games(away_team_id);
CREATE INDEX IF NOT EXISTS idx_games_winner_id ON public.games(winner_id);
CREATE INDEX IF NOT EXISTS idx_games_is_complete ON public.games(is_complete);
CREATE INDEX IF NOT EXISTS idx_games_is_playoff ON public.games(is_playoff);
CREATE INDEX IF NOT EXISTS idx_games_week ON public.games(week);
CREATE INDEX IF NOT EXISTS idx_games_season ON public.games(season);
CREATE INDEX IF NOT EXISTS idx_games_created_at ON public.games(created_at);

-- Add comments for documentation
COMMENT ON TABLE public.games IS 'Stores matchup information and scores';
COMMENT ON COLUMN public.games.id IS 'Primary key UUID';
COMMENT ON COLUMN public.games.league_id IS 'Reference to league';
COMMENT ON COLUMN public.games.week IS 'Week number in the season';
COMMENT ON COLUMN public.games.season IS 'Season year';
COMMENT ON COLUMN public.games.home_team_id IS 'Reference to home team';
COMMENT ON COLUMN public.games.away_team_id IS 'Reference to away team';
COMMENT ON COLUMN public.games.home_score IS 'Home team score';
COMMENT ON COLUMN public.games.away_score IS 'Away team score';
COMMENT ON COLUMN public.games.home_projected IS 'Home team projected score';
COMMENT ON COLUMN public.games.away_projected IS 'Away team projected score';
COMMENT ON COLUMN public.games.is_playoff IS 'Whether this is a playoff game';
COMMENT ON COLUMN public.games.is_consolation IS 'Whether this is a consolation game';
COMMENT ON COLUMN public.games.is_complete IS 'Whether the game is complete';
COMMENT ON COLUMN public.games.winner_id IS 'Reference to winning team';
COMMENT ON COLUMN public.games.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN public.games.updated_at IS 'Record last update timestamp';

-- Enable Row Level Security
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (users can access games for their own leagues)
CREATE POLICY "Users can view games in own leagues" ON public.games
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = games.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update games in own leagues" ON public.games
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = games.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert games in own leagues" ON public.games
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = games.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete games in own leagues" ON public.games
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = games.league_id 
      AND l.user_id = auth.uid()
    )
  );

-- Grant permissions
GRANT ALL ON TABLE public.games TO authenticated;

-- Create trigger for updated_at
CREATE TRIGGER handle_games_updated_at
  BEFORE UPDATE ON public.games
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
