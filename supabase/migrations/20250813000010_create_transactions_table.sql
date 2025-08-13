-- MVP-36: Create Transactions Table
-- This migration creates the transactions table to track roster moves, trades, and waiver claims

-- Create transactions table
CREATE TABLE IF NOT EXISTS public.transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    league_id UUID NOT NULL REFERENCES public.leagues(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('add', 'drop', 'trade', 'commish')),
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'executed')),
    team_id UUID NOT NULL REFERENCES public.teams(id) ON DELETE CASCADE,
    partner_team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
    players_added UUID[] DEFAULT '{}',
    players_dropped UUID[] DEFAULT '{}',
    faab_bid DECIMAL(10,2),
    waiver_priority INTEGER,
    transaction_date TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_transactions_league_id ON public.transactions(league_id);
CREATE INDEX IF NOT EXISTS idx_transactions_team_id ON public.transactions(team_id);
CREATE INDEX IF NOT EXISTS idx_transactions_partner_team_id ON public.transactions(partner_team_id);
CREATE INDEX IF NOT EXISTS idx_transactions_type ON public.transactions(type);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON public.transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_transaction_date ON public.transactions(transaction_date);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON public.transactions(created_at);

-- Create GIN indexes for array columns
CREATE INDEX IF NOT EXISTS idx_transactions_players_added_gin ON public.transactions USING GIN(players_added);
CREATE INDEX IF NOT EXISTS idx_transactions_players_dropped_gin ON public.transactions USING GIN(players_dropped);

-- Add comments for documentation
COMMENT ON TABLE public.transactions IS 'Tracks roster moves, trades, and waiver claims';
COMMENT ON COLUMN public.transactions.id IS 'Primary key UUID';
COMMENT ON COLUMN public.transactions.league_id IS 'Reference to league';
COMMENT ON COLUMN public.transactions.type IS 'Transaction type: add, drop, trade, commish';
COMMENT ON COLUMN public.transactions.status IS 'Transaction status: pending, accepted, rejected, executed';
COMMENT ON COLUMN public.transactions.team_id IS 'Reference to team making the transaction';
COMMENT ON COLUMN public.transactions.partner_team_id IS 'Reference to partner team (for trades)';
COMMENT ON COLUMN public.transactions.players_added IS 'Array of player IDs being added';
COMMENT ON COLUMN public.transactions.players_dropped IS 'Array of player IDs being dropped';
COMMENT ON COLUMN public.transactions.faab_bid IS 'FAAB bid amount (if applicable)';
COMMENT ON COLUMN public.transactions.waiver_priority IS 'Waiver priority (if applicable)';
COMMENT ON COLUMN public.transactions.transaction_date IS 'Date and time of the transaction';
COMMENT ON COLUMN public.transactions.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN public.transactions.updated_at IS 'Record last update timestamp';

-- Enable Row Level Security
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (users can access transactions for their own leagues)
CREATE POLICY "Users can view transactions in own leagues" ON public.transactions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = transactions.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update transactions in own leagues" ON public.transactions
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = transactions.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert transactions in own leagues" ON public.transactions
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = transactions.league_id 
      AND l.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete transactions in own leagues" ON public.transactions
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.leagues l 
      WHERE l.id = transactions.league_id 
      AND l.user_id = auth.uid()
    )
  );

-- Grant permissions
GRANT ALL ON TABLE public.transactions TO authenticated;

-- Create trigger for updated_at
CREATE TRIGGER handle_transactions_updated_at
  BEFORE UPDATE ON public.transactions
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
