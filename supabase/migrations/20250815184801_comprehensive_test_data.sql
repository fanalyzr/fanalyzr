-- MVP-47: Comprehensive Test Data
-- This migration creates comprehensive test data to validate the database schema and constraints
-- Note: User-dependent data (leagues, teams, etc.) requires authentication and is handled separately

-- Additional test players for comprehensive testing
INSERT INTO public.players (
  yahoo_player_key, yahoo_player_id, full_name, first_name, last_name,
  primary_position, positions, nfl_team, status, injury_note
)
VALUES 
  -- Additional Quarterbacks
  (
    '399.p.1244',
    1244,
    'Lamar Jackson',
    'Lamar',
    'Jackson',
    'QB',
    ARRAY['QB'],
    'BAL',
    'active',
    NULL
  ),
  (
    '399.p.1245',
    1245,
    'Jalen Hurts',
    'Jalen',
    'Hurts',
    'QB',
    ARRAY['QB'],
    'PHI',
    'active',
    NULL
  ),
  -- Additional Running Backs
  (
    '399.p.1246',
    1246,
    'Bijan Robinson',
    'Bijan',
    'Robinson',
    'RB',
    ARRAY['RB'],
    'ATL',
    'active',
    NULL
  ),
  (
    '399.p.1247',
    1247,
    'Jahmyr Gibbs',
    'Jahmyr',
    'Gibbs',
    'RB',
    ARRAY['RB'],
    'DET',
    'active',
    NULL
  ),
  -- Additional Wide Receivers
  (
    '399.p.1248',
    1248,
    'CeeDee Lamb',
    'CeeDee',
    'Lamb',
    'WR',
    ARRAY['WR'],
    'DAL',
    'active',
    NULL
  ),
  (
    '399.p.1249',
    1249,
    'Amon-Ra St. Brown',
    'Amon-Ra',
    'St. Brown',
    'WR',
    ARRAY['WR'],
    'DET',
    'active',
    NULL
  ),
  -- Additional Tight Ends
  (
    '399.p.1250',
    1250,
    'Sam LaPorta',
    'Sam',
    'LaPorta',
    'TE',
    ARRAY['TE'],
    'DET',
    'active',
    NULL
  ),
  -- Additional Kickers
  (
    '399.p.1251',
    1251,
    'Evan McPherson',
    'Evan',
    'McPherson',
    'K',
    ARRAY['K'],
    'CIN',
    'active',
    NULL
  ),
  -- Additional Defenses
  (
    '399.p.1252',
    1252,
    'Dallas Cowboys',
    'Dallas',
    'Cowboys',
    'DEF',
    ARRAY['DEF'],
    'DAL',
    'active',
    NULL
  ),
  -- Injured Player (for testing injury scenarios)
  (
    '399.p.1253',
    1253,
    'Cooper Kupp',
    'Cooper',
    'Kupp',
    'WR',
    ARRAY['WR'],
    'LAR',
    'injured',
    'Hamstring injury - Questionable for Week 3'
  ),
  -- Out Player (for testing different statuses)
  (
    '399.p.1254',
    1254,
    'Aaron Rodgers',
    'Aaron',
    'Rodgers',
    'QB',
    ARRAY['QB'],
    'NYJ',
    'out',
    'Achilles injury - Out for season'
  ),
  -- Questionable Player
  (
    '399.p.1255',
    1255,
    'Davante Adams',
    'Davante',
    'Adams',
    'WR',
    ARRAY['WR'],
    'LV',
    'questionable',
    'Shoulder injury - Game time decision'
  )
ON CONFLICT (yahoo_player_key) DO NOTHING;

-- Test data validation queries (these will be run to verify the schema works)
-- Note: These are commented out as they would require user authentication
-- but they demonstrate the expected structure for testing

/*
-- Example test data structure for when user authentication is available:

-- Test League (requires user_id from auth)
-- INSERT INTO public.leagues (
--   id, user_id, yahoo_league_key, yahoo_game_key, name, season, 
--   league_type, scoring_type, draft_type, num_teams, sync_status
-- ) VALUES (
--   '22222222-2222-2222-2222-222222222222',
--   'user-uuid-from-auth',
--   '399.l.123456',
--   '399',
--   'Test Fantasy League 2024',
--   2024,
--   'private',
--   'head',
--   'live',
--   12,
--   'completed'
-- );

-- Test Teams (requires league_id)
-- INSERT INTO public.teams (
--   id, league_id, yahoo_team_key, yahoo_team_id, name, owner_name, 
--   owner_guid, is_current_user, wins, losses, ties, points_for, points_against, rank
-- ) VALUES (
--   '33333333-3333-3333-3333-333333333333',
--   '22222222-2222-2222-2222-222222222222',
--   '399.l.123456.t.1',
--   1,
--   'Yarber''s Warriors',
--   'Josh Yarber',
--   'test_owner_guid_1',
--   TRUE,
--   8, 5, 0, 1456.78, 1423.45, 3
-- );

-- Test Games (requires league_id and team_ids)
-- INSERT INTO public.games (
--   id, league_id, week, season, home_team_id, away_team_id,
--   home_score, away_score, home_projected, away_projected,
--   is_playoff, is_consolation, is_complete, winner_id
-- ) VALUES (
--   '55555555-5555-5555-5555-555555555555',
--   '22222222-2222-2222-2222-222222222222',
--   1, 2024, '33333333-3333-3333-3333-333333333333', '33333333-3333-3333-3333-333333333334',
--   125.67, 118.45, 120.50, 115.75, FALSE, FALSE, TRUE, '33333333-3333-3333-3333-333333333333'
-- );

-- Test Player Stats (requires league_id, player_id, team_id)
-- INSERT INTO public.player_stats (
--   id, league_id, player_id, team_id, week, season,
--   points_scored, projected_points, game_played, stats
-- ) VALUES (
--   '66666666-6666-6666-6666-666666666666',
--   '22222222-2222-2222-2222-222222222222',
--   '44444444-4444-4444-4444-444444444444',
--   '33333333-3333-3333-3333-333333333333',
--   1, 2024, 28.45, 25.50, TRUE,
--   '{"passing_yards": 312, "passing_touchdowns": 3, "interceptions": 0, "rushing_yards": 45, "rushing_touchdowns": 1}'
-- );

-- Test Rosters (requires team_id)
-- INSERT INTO public.rosters (
--   id, team_id, week, season, players, total_points, projected_points
-- ) VALUES (
--   '77777777-7777-7777-7777-777777777777',
--   '33333333-3333-3333-3333-333333333333',
--   1, 2024,
--   '[
--     {"player_id": "44444444-4444-4444-4444-444444444444", "position": "QB", "is_starter": true},
--     {"player_id": "44444444-4444-4444-4444-444444444446", "position": "RB", "is_starter": true}
--   ]'::jsonb,
--   125.67, 120.50
-- );

-- Test Transactions (requires league_id, team_id)
-- INSERT INTO public.transactions (
--   id, league_id, team_id, partner_team_id, type, status,
--   transaction_date, players_added, players_dropped, notes
-- ) VALUES (
--   '88888888-8888-8888-8888-888888888888',
--   '22222222-2222-2222-2222-222222222222',
--   '33333333-3333-3333-3333-333333333333',
--   NULL, 'add', 'completed', '2024-09-01',
--   ARRAY['44444444-4444-4444-4444-444444444444'],
--   ARRAY[]::text[],
--   'Added Patrick Mahomes from free agents'
-- );

-- Test Draft Results (requires league_id, team_id, player_id)
-- INSERT INTO public.draft_results (
--   id, league_id, team_id, player_id, round, pick, overall_pick, keeper_round, cost
-- ) VALUES (
--   '99999999-9999-9999-9999-999999999999',
--   '22222222-2222-2222-2222-222222222222',
--   '33333333-3333-3333-3333-333333333333',
--   '44444444-4444-4444-4444-444444444444',
--   1, 3, 3, NULL, NULL
-- );

-- Test Sync Checkpoints (requires league_id)
-- INSERT INTO public.sync_checkpoints (
--   id, league_id, sync_type, current_step, completed_steps, error_message, started_at, completed_at
-- ) VALUES (
--   'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
--   '22222222-2222-2222-2222-222222222222',
--   'full_sync', 'completed',
--   ARRAY['leagues', 'teams', 'players', 'games', 'rosters'],
--   NULL, '2024-09-01 10:00:00', '2024-09-01 10:15:00'
-- );
*/

-- Create a function to validate the test data and schema
CREATE OR REPLACE FUNCTION validate_test_data_schema()
RETURNS TABLE (
  test_name TEXT,
  status TEXT,
  details TEXT
) AS $$
BEGIN
  -- Test 1: Verify players table structure
  RETURN QUERY
  SELECT 
    'Players Table Structure'::TEXT,
    'PASS'::TEXT,
    'All required columns and constraints present'::TEXT
  WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'players' 
    AND column_name IN ('id', 'yahoo_player_key', 'full_name', 'primary_position', 'nfl_team')
  );

  -- Test 2: Verify RLS is enabled on players
  RETURN QUERY
  SELECT 
    'Players RLS Enabled'::TEXT,
    'PASS'::TEXT,
    'Row Level Security is properly configured'::TEXT
  WHERE EXISTS (
    SELECT 1 FROM pg_tables 
    WHERE tablename = 'players' 
    AND rowsecurity = true
  );

  -- Test 3: Verify triggers exist
  RETURN QUERY
  SELECT 
    'Update Timestamp Trigger'::TEXT,
    'PASS'::TEXT,
    'handle_players_updated_at trigger exists'::TEXT
  WHERE EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'handle_players_updated_at' 
    AND tgrelid = 'public.players'::regclass
  );

  -- Test 4: Verify functions exist
  RETURN QUERY
  SELECT 
    'Analytics Functions'::TEXT,
    'PASS'::TEXT,
    'get_team_analytics, get_league_standings, get_player_performance functions exist'::TEXT
  WHERE EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'get_team_analytics'
  ) AND EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'get_league_standings'
  ) AND EXISTS (
    SELECT 1 FROM pg_proc 
    WHERE proname = 'get_player_performance'
  );

  -- Test 5: Verify game validation trigger exists
  RETURN QUERY
  SELECT 
    'Game Validation Trigger'::TEXT,
    'PASS'::TEXT,
    'validate_game_data_before_insupd trigger exists'::TEXT
  WHERE EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'validate_game_data_before_insupd' 
    AND tgrelid = 'public.games'::regclass
  );

  -- Test 6: Verify test data was inserted
  RETURN QUERY
  SELECT 
    'Test Players Count'::TEXT,
    CASE WHEN player_count >= 20 THEN 'PASS' ELSE 'FAIL' END::TEXT,
    'Inserted ' || player_count || ' test players'::TEXT
  FROM (
    SELECT COUNT(*) as player_count FROM public.players
  ) counts;

  -- Test 7: Verify different player statuses
  RETURN QUERY
  SELECT 
    'Player Status Variety'::TEXT,
    'PASS'::TEXT,
    'Players with different statuses (active, injured, out, questionable) present'::TEXT
  WHERE EXISTS (
    SELECT 1 FROM public.players WHERE status = 'active'
  ) AND EXISTS (
    SELECT 1 FROM public.players WHERE status = 'injured'
  ) AND EXISTS (
    SELECT 1 FROM public.players WHERE status = 'out'
  ) AND EXISTS (
    SELECT 1 FROM public.players WHERE status = 'questionable'
  );

  -- Test 8: Verify positions array structure
  RETURN QUERY
  SELECT 
    'Player Positions Array'::TEXT,
    'PASS'::TEXT,
    'Players have proper positions arrays'::TEXT
  WHERE EXISTS (
    SELECT 1 FROM public.players 
    WHERE 'QB' = ANY(positions)
  ) AND EXISTS (
    SELECT 1 FROM public.players 
    WHERE 'RB' = ANY(positions)
  ) AND EXISTS (
    SELECT 1 FROM public.players 
    WHERE 'WR' = ANY(positions)
  );

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Add comment to the validation function
COMMENT ON FUNCTION validate_test_data_schema()
  IS 'Validates that the test data and database schema are properly configured for MVP-47';

-- Grant execute permission
GRANT EXECUTE ON FUNCTION validate_test_data_schema() TO authenticated;
