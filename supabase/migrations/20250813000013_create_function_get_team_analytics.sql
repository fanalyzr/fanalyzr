-- MVP-39: Implement Team Analytics Function
-- Creates function get_team_analytics(team_id, season) returning weekly points, opponent points,
-- cumulative wins, and weekly ranking within the team's league for the given season.

CREATE OR REPLACE FUNCTION public.get_team_analytics(
  p_team_id UUID,
  p_season INTEGER
) RETURNS TABLE (
  week INTEGER,
  points NUMERIC,
  opponent_points NUMERIC,
  cumulative_wins INTEGER,
  ranking INTEGER
) AS $$
WITH team_info AS (
  SELECT t.league_id
  FROM public.teams t
  WHERE t.id = p_team_id
),
team_games AS (
  SELECT
    g.week,
    CASE WHEN g.home_team_id = p_team_id THEN g.home_score ELSE g.away_score END AS points,
    CASE WHEN g.home_team_id = p_team_id THEN g.away_score ELSE g.home_score END AS opponent_points,
    g.is_complete,
    g.winner_id
  FROM public.games g
  WHERE g.season = p_season
    AND (g.home_team_id = p_team_id OR g.away_team_id = p_team_id)
),
wins_by_week AS (
  SELECT
    tg.week,
    CASE
      WHEN tg.is_complete IS TRUE AND tg.winner_id = p_team_id THEN 1
      ELSE 0
    END AS is_win
  FROM team_games tg
),
cumulative AS (
  SELECT
    w.week,
    SUM(w.is_win) OVER (ORDER BY w.week ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_wins
  FROM wins_by_week w
),
per_week_points AS (
  -- Build per-team weekly points across the team's league for completed games only
  SELECT
    g.week,
    g.home_team_id AS team_id,
    g.home_score AS points
  FROM public.games g
  JOIN team_info ti ON ti.league_id = g.league_id
  WHERE g.season = p_season AND g.is_complete IS TRUE AND g.home_score IS NOT NULL
  UNION ALL
  SELECT
    g.week,
    g.away_team_id,
    g.away_score
  FROM public.games g
  JOIN team_info ti ON ti.league_id = g.league_id
  WHERE g.season = p_season AND g.is_complete IS TRUE AND g.away_score IS NOT NULL
),
rankings AS (
  SELECT
    pwp.week,
    pwp.team_id,
    RANK() OVER (PARTITION BY pwp.week ORDER BY pwp.points DESC) AS ranking
  FROM per_week_points pwp
)
SELECT
  tg.week,
  tg.points,
  tg.opponent_points,
  c.cumulative_wins,
  r.ranking
FROM team_games tg
LEFT JOIN cumulative c ON c.week = tg.week
LEFT JOIN rankings r ON r.week = tg.week AND r.team_id = p_team_id
ORDER BY tg.week ASC;
$$ LANGUAGE SQL STABLE;

COMMENT ON FUNCTION public.get_team_analytics(UUID, INTEGER)
  IS 'Returns weekly analytics for a team (points, opponent points, cumulative wins, weekly ranking within league) for a given season.';


