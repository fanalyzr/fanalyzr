-- MVP-33: Create Player Stats Table
-- This migration creates the player_stats table to track player performance data by league, season, and week

-- Create player_stats table
CREATE TABLE IF NOT EXISTS public.player_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    league_id UUID NOT NULL REFERENCES public.leagues(id) ON DELETE CASCADE,
    week INTEGER NOT NULL,
    season INTEGER NOT NULL,
    points_scored DECIMAL(10,2),
    projected_points DECIMAL(10,2),
    game_played BOOLEAN DEFAULT FALSE,
    stats JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create unique constraint on player_id, league_id, week, season combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_player_stats_unique_combination 
ON public.player_stats(player_id, league_id, week, season);

-- Create composite indexes for efficient lookups
CREATE INDEX IF NOT EXISTS idx_player_stats_player_league_season_week 
ON public.player_stats(player_id, league_id, season, week);
CREATE INDEX IF NOT EXISTS idx_player_stats_league_season_week 
ON public.player_stats(league_id, season, week);
CREATE INDEX IF NOT EXISTS idx_player_stats_player_id ON public.player_stats(player_id);
CREATE INDEX IF NOT EXISTS idx_player_stats_league_id ON public.player_stats(league_id);
CREATE INDEX IF NOT EXISTS idx_player_stats_week ON public.player_stats(week);
CREATE INDEX IF NOT EXISTS idx_player_stats_season ON public.player_stats(season);
CREATE INDEX IF NOT EXISTS idx_player_stats_points_scored ON public.player_stats(points_scored);
CREATE INDEX IF NOT EXISTS idx_player_stats_created_at ON public.player_stats(created_at);

-- Create GIN index for JSONB stats column
CREATE INDEX IF NOT EXISTS idx_player_stats_stats_gin ON public.player_stats USING GIN(stats);

-- Add comments for documentation
COMMENT ON TABLE public.player_stats IS 'Tracks player performance data by league, season, and week';
COMMENT ON COLUMN public.player_stats.id IS 'Primary key UUID';
COMMENT ON COLUMN public.player_stats.player_id IS 'Reference to player';
COMMENT ON COLUMN public.player_stats.league_id IS 'Reference to league';
COMMENT ON COLUMN public.player_stats.week IS 'Week number in the season';
COMMENT ON COLUMN public.player_stats.season IS 'Season year';
COMMENT ON COLUMN public.player_stats.points_scored IS 'Actual points scored this week';
COMMENT ON COLUMN public.player_stats.projected_points IS 'Projected points for this week';
COMMENT ON COLUMN public.player_stats.game_played IS 'Whether the player played this week';
COMMENT ON COLUMN public.player_stats.stats IS 'Detailed statistics in JSONB format';
COMMENT ON COLUMN public.player_stats.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN public.player_stats.updated_at IS 'Record last update timestamp';

-- Enable Row Level Security
ALTER TABLE public.player_stats ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (users can access stats for their own leagues)
CREATE POLICY "Users can view stats in own leagues" ON public.player_stats
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = player_stats.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update stats in own leagues" ON public.player_stats
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = player_stats.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert stats in own leagues" ON public.player_stats
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = player_stats.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete stats in own leagues" ON public.player_stats
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = player_stats.league_id 
      AND l.user_id = auth.uid()
    )
  );

-- Grant permissions
GRANT ALL ON TABLE public.player_stats TO authenticated;

-- Create trigger for updated_at
CREATE TRIGGER handle_player_stats_updated_at
  BEFORE UPDATE ON public.player_stats
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
