-- MVP-40: Implement League Standings Function
-- Creates function get_league_standings(league_id, season) returning team records and rank.

CREATE OR REPLACE FUNCTION public.get_league_standings(
  p_league_id UUID,
  p_season INTEGER
) RETURNS TABLE (
  team_id UUID,
  team_name TEXT,
  wins INTEGER,
  losses INTEGER,
  ties INTEGER,
  points_for NUMERIC,
  points_against NUMERIC,
  win_percentage NUMERIC,
  rank INTEGER
) AS $$
WITH league_teams AS (
  SELECT t.id, t.name
  FROM public.teams t
  WHERE t.league_id = p_league_id
),
team_results AS (
  SELECT
    lt.id AS team_id,
    lt.name AS team_name,
    COALESCE(SUM(CASE WHEN g.is_complete IS TRUE AND g.winner_id = lt.id THEN 1 ELSE 0 END), 0) AS wins,
    COALESCE(SUM(CASE WHEN g.is_complete IS TRUE AND g.winner_id IS NOT NULL AND g.winner_id <> lt.id AND (g.home_team_id = lt.id OR g.away_team_id = lt.id) THEN 1 ELSE 0 END), 0) AS losses,
    COALESCE(SUM(CASE 
      WHEN g.is_complete IS TRUE AND g.winner_id IS NULL AND 
           (g.home_team_id = lt.id OR g.away_team_id = lt.id) AND 
           g.home_score IS NOT NULL AND g.away_score IS NOT NULL AND g.home_score = g.away_score
      THEN 1 ELSE 0 END), 0) AS ties,
    COALESCE(SUM(CASE WHEN g.home_team_id = lt.id THEN g.home_score WHEN g.away_team_id = lt.id THEN g.away_score ELSE NULL END), 0) AS points_for,
    COALESCE(SUM(CASE WHEN g.home_team_id = lt.id THEN g.away_score WHEN g.away_team_id = lt.id THEN g.home_score ELSE NULL END), 0) AS points_against
  FROM league_teams lt
  LEFT JOIN public.games g
    ON g.league_id = p_league_id AND g.season = p_season AND (g.home_team_id = lt.id OR g.away_team_id = lt.id)
  GROUP BY lt.id, lt.name
),
calc AS (
  SELECT
    tr.team_id,
    tr.team_name,
    tr.wins,
    tr.losses,
    tr.ties,
    tr.points_for,
    tr.points_against,
    CASE WHEN (tr.wins + tr.losses + tr.ties) > 0
      THEN ROUND(((tr.wins + 0.5 * tr.ties)::numeric / (tr.wins + tr.losses + tr.ties)::numeric)::numeric, 6)
      ELSE 0::numeric
    END AS win_percentage
  FROM team_results tr
)
SELECT
  c.team_id,
  c.team_name,
  c.wins,
  c.losses,
  c.ties,
  c.points_for,
  c.points_against,
  c.win_percentage,
  RANK() OVER (ORDER BY c.win_percentage DESC, c.points_for DESC) AS rank
FROM calc c
ORDER BY rank ASC, c.team_name ASC;
$$ LANGUAGE SQL STABLE;

COMMENT ON FUNCTION public.get_league_standings(UUID, INTEGER)
  IS 'Returns league standings for a season, ordered by win_percentage then points_for, with computed rank.';


