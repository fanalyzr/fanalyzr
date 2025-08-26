-- MVP-47: Seed Test Data
-- This file contains basic test data that can be inserted without user authentication
-- For comprehensive test data with user authentication, use the REST seeder: supabase/seed-rest.cjs

-- Test Players (these can be inserted without user context)
INSERT INTO public.players (
  yahoo_player_key, yahoo_player_id, full_name, first_name, last_name,
  primary_position, positions, nfl_team, status, injury_note
)
VALUES 
  -- Quarterbacks
  (
    '399.p.1234',
    1234,
    'Patrick Mahomes',
    'Patrick',
    'Mahomes',
    'QB',
    ARRAY['QB'],
    'KC',
    'active',
    NULL
  ),
  (
    '399.p.1235',
    1235,
    'Josh Allen',
    'Josh',
    'Allen',
    'QB',
    ARRAY['QB'],
    'BUF',
    'active',
    NULL
  ),
  -- Running Backs
  (
    '399.p.1236',
    1236,
    'Christian McCaffrey',
    'Christian',
    'McCaffrey',
    'RB',
    ARRAY['RB', 'WR'],
    'SF',
    'active',
    NULL
  ),
  (
    '399.p.1237',
    1237,
    'Saquon Barkley',
    'Saquon',
    'Barkley',
    'RB',
    ARRAY['RB'],
    'PHI',
    'active',
    NULL
  ),
  -- Wide Receivers
  (
    '399.p.1238',
    1238,
    'Tyreek Hill',
    'Tyreek',
    'Hill',
    'WR',
    ARRAY['WR'],
    'MIA',
    'active',
    NULL
  ),
  (
    '399.p.1239',
    1239,
    'Justin Jefferson',
    'Justin',
    'Jefferson',
    'WR',
    ARRAY['WR'],
    'MIN',
    'active',
    NULL
  ),
  -- Tight Ends
  (
    '399.p.1240',
    1240,
    'Travis Kelce',
    'Travis',
    'Kelce',
    'TE',
    ARRAY['TE'],
    'KC',
    'active',
    NULL
  ),
  (
    '399.p.1241',
    1241,
    'Mark Andrews',
    'Mark',
    'Andrews',
    'TE',
    ARRAY['TE'],
    'BAL',
    'active',
    NULL
  ),
  -- Kickers
  (
    '399.p.1242',
    1242,
    'Justin Tucker',
    'Justin',
    'Tucker',
    'K',
    ARRAY['K'],
    'BAL',
    'active',
    NULL
  ),
  -- Defense
  (
    '399.p.1243',
    1243,
    'San Francisco 49ers',
    'San Francisco',
    '49ers',
    'DEF',
    ARRAY['DEF'],
    'SF',
    'active',
    NULL
  )
ON CONFLICT (yahoo_player_key) DO NOTHING;

-- Note: For comprehensive test data including leagues, teams, games, etc.
-- that require user authentication, run the REST seeder:
-- node supabase/seed-rest.cjs
