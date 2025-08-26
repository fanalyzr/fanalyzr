-- MVP-46: Create Data Validation Triggers
-- This migration creates the validate_game_data function and trigger for the games table

-- Create validation function for game data
CREATE OR REPLACE FUNCTION public.validate_game_data()
RETURNS TRIGGER AS $$
BEGIN
  -- Validate that home and away teams are different
  IF NEW.home_team_id = NEW.away_team_id THEN
    RAISE EXCEPTION 'Home and away teams cannot be the same (home_team_id: %, away_team_id: %)', 
      NEW.home_team_id, NEW.away_team_id;
  END IF;

  -- Validate that scores are non-negative
  IF NEW.home_score IS NOT NULL AND NEW.home_score < 0 THEN
    RAISE EXCEPTION 'Home score cannot be negative: %', NEW.home_score;
  END IF;

  IF NEW.away_score IS NOT NULL AND NEW.away_score < 0 THEN
    RAISE EXCEPTION 'Away score cannot be negative: %', NEW.away_score;
  END IF;

  IF NEW.home_projected IS NOT NULL AND NEW.home_projected < 0 THEN
    RAISE EXCEPTION 'Home projected score cannot be negative: %', NEW.home_projected;
  END IF;

  IF NEW.away_projected IS NOT NULL AND NEW.away_projected < 0 THEN
    RAISE EXCEPTION 'Away projected score cannot be negative: %', NEW.away_projected;
  END IF;

  -- Automatically set winner when game is complete and scores are available
  IF NEW.is_complete = TRUE AND NEW.home_score IS NOT NULL AND NEW.away_score IS NOT NULL THEN
    IF NEW.home_score > NEW.away_score THEN
      NEW.winner_id := NEW.home_team_id;
    ELSIF NEW.away_score > NEW.home_score THEN
      NEW.winner_id := NEW.away_team_id;
    ELSE
      -- Handle ties - set winner_id to NULL for ties
      NEW.winner_id := NULL;
    END IF;
  ELSIF NEW.is_complete = FALSE THEN
    -- If game is not complete, clear winner_id
    NEW.winner_id := NULL;
  END IF;

  -- Validate that teams belong to the same league
  IF NOT EXISTS (
    SELECT 1 FROM public.teams t1, public.teams t2
    WHERE t1.id = NEW.home_team_id 
    AND t2.id = NEW.away_team_id
    AND t1.league_id = t2.league_id
    AND t1.league_id = NEW.league_id
  ) THEN
    RAISE EXCEPTION 'Home and away teams must belong to the same league (league_id: %)', NEW.league_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment to function
COMMENT ON FUNCTION public.validate_game_data()
  IS 'Validates game data integrity and automatically sets winner when game is complete';

-- Create trigger for games table
CREATE TRIGGER validate_game_data_before_insupd
  BEFORE INSERT OR UPDATE ON public.games
  FOR EACH ROW EXECUTE FUNCTION public.validate_game_data();

-- Add comment to trigger
COMMENT ON TRIGGER validate_game_data_before_insupd ON public.games
  IS 'Validates game data before insert or update operations';

