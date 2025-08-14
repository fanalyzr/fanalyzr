-- MVP-41: Implement Player Performance Function
-- Creates function get_player_performance(league_id, season, week DEFAULT NULL) returning player metrics.

CREATE OR REPLACE FUNCTION public.get_player_performance(
  p_league_id UUID,
  p_season INTEGER,
  p_week INTEGER DEFAULT NULL
) RETURNS TABLE (
  player_id UUID,
  player_name TEXT,
  player_position TEXT,
  nfl_team TEXT,
  week INTEGER,
  points_scored NUMERIC,
  projected_points NUMERIC,
  game_played BOOLEAN
) AS $$
SELECT
  ps.player_id,
  pl.full_name AS player_name,
  pl.primary_position AS player_position,
  pl.nfl_team,
  ps.week,
  ps.points_scored,
  ps.projected_points,
  ps.game_played
FROM public.player_stats ps
JOIN public.players pl ON pl.id = ps.player_id
WHERE ps.league_id = p_league_id
  AND ps.season = p_season
  AND (p_week IS NULL OR ps.week = p_week)
ORDER BY ps.points_scored DESC NULLS LAST, pl.full_name ASC;
$$ LANGUAGE SQL STABLE;

COMMENT ON FUNCTION public.get_player_performance(UUID, INTEGER, INTEGER)
  IS 'Returns player performance for league/season, optionally filtered by week, ordered by points_scored desc.';


