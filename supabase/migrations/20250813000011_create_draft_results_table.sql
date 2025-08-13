-- MVP-37: Create Draft Results Table
-- This migration creates the draft_results table to store draft history and keeper information

-- Create draft_results table
CREATE TABLE IF NOT EXISTS public.draft_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    league_id UUID NOT NULL REFERENCES public.leagues(id) ON DELETE CASCADE,
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    round INTEGER NOT NULL,
    pick INTEGER NOT NULL,
    overall_pick INTEGER NOT NULL,
    keeper_round INTEGER,
    cost DECIMAL(10,2),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create unique constraint on league_id, overall_pick combination
CREATE UNIQUE INDEX IF NOT EXISTS idx_draft_results_unique_combination 
ON public.draft_results(league_id, overall_pick);

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_draft_results_league_id ON public.draft_results(league_id);
CREATE INDEX IF NOT EXISTS idx_draft_results_team_id ON public.draft_results(team_id);
CREATE INDEX IF NOT EXISTS idx_draft_results_player_id ON public.draft_results(player_id);
CREATE INDEX IF NOT EXISTS idx_draft_results_overall_pick ON public.draft_results(overall_pick);
CREATE INDEX IF NOT EXISTS idx_draft_results_round ON public.draft_results(round);
CREATE INDEX IF NOT EXISTS idx_draft_results_pick ON public.draft_results(pick);
CREATE INDEX IF NOT EXISTS idx_draft_results_keeper_round ON public.draft_results(keeper_round);
CREATE INDEX IF NOT EXISTS idx_draft_results_created_at ON public.draft_results(created_at);

-- Add comments for documentation
COMMENT ON TABLE public.draft_results IS 'Stores draft history and keeper information';
COMMENT ON COLUMN public.draft_results.id IS 'Primary key UUID';
COMMENT ON COLUMN public.draft_results.league_id IS 'Reference to league';
COMMENT ON COLUMN public.draft_results.team_id IS 'Reference to team that drafted the player';
COMMENT ON COLUMN public.draft_results.player_id IS 'Reference to drafted player';
COMMENT ON COLUMN public.draft_results.round IS 'Draft round number';
COMMENT ON COLUMN public.draft_results.pick IS 'Pick number within the round';
COMMENT ON COLUMN public.draft_results.overall_pick IS 'Overall pick number in the draft';
COMMENT ON COLUMN public.draft_results.keeper_round IS 'Keeper round (if applicable)';
COMMENT ON COLUMN public.draft_results.cost IS 'Auction draft cost (if applicable)';
COMMENT ON COLUMN public.draft_results.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN public.draft_results.updated_at IS 'Record last update timestamp';

-- Enable Row Level Security
ALTER TABLE public.draft_results ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (users can access draft results for their own leagues)
CREATE POLICY "Users can view draft results in own leagues" ON public.draft_results
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = draft_results.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update draft results in own leagues" ON public.draft_results
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = draft_results.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert draft results in own leagues" ON public.draft_results
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = draft_results.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete draft results in own leagues" ON public.draft_results
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = draft_results.league_id 
      AND l.user_id = auth.uid()
    )
  );

-- Grant permissions
GRANT ALL ON TABLE public.draft_results TO authenticated;

-- Create trigger for updated_at
CREATE TRIGGER handle_draft_results_updated_at
  BEFORE UPDATE ON public.draft_results
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
