-- MVP-32: Create Players Table
-- This migration creates the players table to store comprehensive player information and status

-- Create players table
CREATE TABLE IF NOT EXISTS public.players (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    yahoo_player_key TEXT UNIQUE NOT NULL,
    yahoo_player_id INTEGER NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    full_name TEXT NOT NULL,
    positions TEXT[] NOT NULL,
    primary_position TEXT NOT NULL,
    nfl_team TEXT,
    nfl_team_full TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'injured', 'out', 'questionable', 'doubtful', 'ir', 'pup')),
    injury_note TEXT,
    bye_week INTEGER,
    headshot_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create performance indexes
CREATE INDEX IF NOT EXISTS idx_players_yahoo_player_key ON public.players(yahoo_player_key);
CREATE INDEX IF NOT EXISTS idx_players_nfl_team ON public.players(nfl_team);
CREATE INDEX IF NOT EXISTS idx_players_primary_position ON public.players(primary_position);
CREATE INDEX IF NOT EXISTS idx_players_status ON public.players(status);
CREATE INDEX IF NOT EXISTS idx_players_full_name ON public.players(full_name);
CREATE INDEX IF NOT EXISTS idx_players_created_at ON public.players(created_at);

-- Create GIN index for positions array
CREATE INDEX IF NOT EXISTS idx_players_positions_gin ON public.players USING GIN(positions);

-- Add comments for documentation
COMMENT ON TABLE public.players IS 'Stores comprehensive player information and status';
COMMENT ON COLUMN public.players.id IS 'Primary key UUID';
COMMENT ON COLUMN public.players.yahoo_player_key IS 'Unique Yahoo player identifier';
COMMENT ON COLUMN public.players.yahoo_player_id IS 'Yahoo player ID number';
COMMENT ON COLUMN public.players.first_name IS 'Player first name';
COMMENT ON COLUMN public.players.last_name IS 'Player last name';
COMMENT ON COLUMN public.players.full_name IS 'Player full name';
COMMENT ON COLUMN public.players.positions IS 'Array of positions player can play';
COMMENT ON COLUMN public.players.primary_position IS 'Primary position for the player';
COMMENT ON COLUMN public.players.nfl_team IS 'NFL team abbreviation';
COMMENT ON COLUMN public.players.nfl_team_full IS 'Full NFL team name';
COMMENT ON COLUMN public.players.status IS 'Player status (active, injured, out, etc.)';
COMMENT ON COLUMN public.players.injury_note IS 'Injury note if applicable';
COMMENT ON COLUMN public.players.bye_week IS 'Player bye week';
COMMENT ON COLUMN public.players.headshot_url IS 'URL to player headshot image';
COMMENT ON COLUMN public.players.created_at IS 'Record creation timestamp';
COMMENT ON COLUMN public.players.updated_at IS 'Record last update timestamp';

-- Enable Row Level Security (all users can view players, but only authenticated users can modify)
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;

-- Create RLS policies (players are shared across all users)
CREATE POLICY "Anyone can view players" ON public.players
  FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can update players" ON public.players
  FOR UPDATE
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert players" ON public.players
  FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete players" ON public.players
  FOR DELETE
  USING (auth.role() = 'authenticated');

-- Grant permissions
GRANT ALL ON TABLE public.players TO authenticated;
GRANT SELECT ON TABLE public.players TO anon;

-- Create trigger for updated_at
CREATE TRIGGER handle_players_updated_at
  BEFORE UPDATE ON public.players
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Create function to generate full_name from first_name and last_name
CREATE OR REPLACE FUNCTION generate_player_full_name()
RETURNS TRIGGER AS $$
BEGIN
  -- Generate full_name from first_name and last_name
  IF NEW.first_name IS NOT NULL OR NEW.last_name IS NOT NULL THEN
    NEW.full_name = TRIM(CONCAT(COALESCE(NEW.first_name, ''), ' ', COALESCE(NEW.last_name, '')));
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for full_name generation
CREATE TRIGGER generate_player_full_name_trigger
  BEFORE INSERT OR UPDATE OF first_name, last_name ON public.players
  FOR EACH ROW EXECUTE FUNCTION generate_player_full_name();
