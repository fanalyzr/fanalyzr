# Jira Tickets for Database Schema Implementation

## Epic: Yahoo Fantasy Sports Database Schema Implementation
**Epic ID:** FAN-100  
**Epic Type:** Database  
**Priority:** High  
**Sprint:** MVP Database Foundation  

### Epic Description
Implement comprehensive database schema for Yahoo Fantasy Sports integration to support league management, player statistics, team analytics, and real-time data synchronization.

---

## Phase 1: Foundation Setup (Week 1)

### FAN-101: Enable PostgreSQL Extensions and Configuration
**Type:** Task  
**Priority:** High  
**Story Points:** 2  
**Assignee:** Database Engineer  

**Description:**  
Set up required PostgreSQL extensions and encryption configuration for the Yahoo Fantasy Sports integration.

**Acceptance Criteria:**
- [ ] Enable uuid-ossp extension
- [ ] Enable pgcrypto extension  
- [ ] Configure encryption key for database
- [ ] Verify extensions are working correctly
- [ ] Document configuration settings

**Technical Notes:**
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
ALTER DATABASE postgres SET "app.encryption_key" = 'your-32-character-encryption-key';
```

---

### FAN-102: Extend User Profiles with Yahoo OAuth Fields
**Type:** Task  
**Priority:** High  
**Story Points:** 3  
**Assignee:** Database Engineer  

**Description:**  
Extend the existing user_profiles table to support Yahoo OAuth authentication and sync preferences.

**Acceptance Criteria:**
- [ ] Add yahoo_guid column (TEXT, UNIQUE)
- [ ] Add yahoo_access_token column (TEXT)
- [ ] Add yahoo_refresh_token column (TEXT)
- [ ] Add token_expires_at column (TIMESTAMPTZ)
- [ ] Add sync_preferences column (JSONB with default)
- [ ] Create index on yahoo_guid
- [ ] Test OAuth field storage and retrieval

**Technical Notes:**
```sql
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS yahoo_guid TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS yahoo_access_token TEXT,
ADD COLUMN IF NOT EXISTS yahoo_refresh_token TEXT,
ADD COLUMN IF NOT EXISTS token_expires_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS sync_preferences JSONB DEFAULT '{"auto_sync": false, "sync_frequency": "manual"}';
```

---

### FAN-103: Create Encryption Functions for OAuth Tokens
**Type:** Task  
**Priority:** High  
**Story Points:** 3  
**Assignee:** Database Engineer  

**Description:**  
Implement encryption and decryption functions for secure storage of Yahoo OAuth tokens.

**Acceptance Criteria:**
- [ ] Create encrypt_token function
- [ ] Create decrypt_token function
- [ ] Test encryption/decryption with sample tokens
- [ ] Verify security definer permissions
- [ ] Document function usage

**Technical Notes:**
```sql
CREATE OR REPLACE FUNCTION encrypt_token(token TEXT) 
RETURNS TEXT AS $$
BEGIN
  RETURN encode(encrypt(token::bytea, current_setting('app.encryption_key')::bytea, 'aes'), 'base64');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## Phase 2: Core Tables Implementation (Week 2)

### FAN-104: Create Leagues Table
**Type:** Task  
**Priority:** High  
**Story Points:** 5  
**Assignee:** Database Engineer  

**Description:**  
Create the leagues table to store Yahoo Fantasy Sports league information and sync status.

**Acceptance Criteria:**
- [ ] Create leagues table with all required columns
- [ ] Implement CHECK constraints for league_type and scoring_type
- [ ] Add foreign key constraint to user_profiles
- [ ] Create unique constraint on yahoo_league_key, season, user_id
- [ ] Create performance indexes
- [ ] Test table creation and constraints

**Technical Notes:**
- Primary key: UUID with uuid_generate_v4()
- Required constraints: league_type, scoring_type, sync_status
- Indexes: user_id, yahoo_league_key, sync_status, season

---

### FAN-105: Create Teams Table
**Type:** Task  
**Priority:** High  
**Story Points:** 5  
**Assignee:** Database Engineer  

**Description:**  
Create the teams table to store team information, owner details, and season statistics.

**Acceptance Criteria:**
- [ ] Create teams table with all required columns
- [ ] Add foreign key constraint to leagues table
- [ ] Create unique constraint on yahoo_team_key, league_id
- [ ] Add default values for statistics columns
- [ ] Create performance indexes
- [ ] Test team data insertion and retrieval

**Technical Notes:**
- Include columns for: team info, owner details, season stats, playoff info
- Indexes: league_id, is_current_user, owner_guid
- Default values for wins, losses, ties, points_for, points_against

---

### FAN-106: Create Players Table
**Type:** Task  
**Priority:** High  
**Story Points:** 4  
**Assignee:** Database Engineer  

**Description:**  
Create the players table to store comprehensive player information and status.

**Acceptance Criteria:**
- [ ] Create players table with all required columns
- [ ] Add CHECK constraint for player status
- [ ] Create unique constraint on yahoo_player_key
- [ ] Create performance indexes
- [ ] Test player data insertion and retrieval

**Technical Notes:**
- Include columns for: player info, positions array, NFL team, status, injury info
- Indexes: yahoo_player_key, nfl_team, primary_position, status
- Status values: active, injured, out, questionable, doubtful

---

## Phase 3: Performance and Statistics Tables (Week 3)

### FAN-107: Create Player Stats Table
**Type:** Task  
**Priority:** High  
**Story Points:** 5  
**Assignee:** Database Engineer  

**Description:**  
Create the player_stats table to track player performance data by league, season, and week.

**Acceptance Criteria:**
- [ ] Create player_stats table with all required columns
- [ ] Add foreign key constraints to players and leagues
- [ ] Create unique constraint on player_id, league_id, week, season
- [ ] Create composite indexes for efficient lookups
- [ ] Test stats data insertion and retrieval

**Technical Notes:**
- Include columns for: points, projections, game status, detailed stats JSONB
- Composite indexes: (player_id, league_id, season, week), (league_id, season, week)
- Stats stored as JSONB for flexibility

---

### FAN-108: Create Rosters Table
**Type:** Task  
**Priority:** High  
**Story Points:** 4  
**Assignee:** Database Engineer  

**Description:**  
Create the rosters table to store team lineup information by week and season.

**Acceptance Criteria:**
- [ ] Create rosters table with all required columns
- [ ] Add foreign key constraint to teams table
- [ ] Create unique constraint on team_id, week, season
- [ ] Store players as JSONB array
- [ ] Create performance indexes
- [ ] Test roster data insertion and retrieval

**Technical Notes:**
- Players stored as JSONB array with position and starter info
- Include total_points and projected_points columns
- Indexes: (team_id, season), (team_id, season, week)

---

### FAN-109: Create Games Table
**Type:** Task  
**Priority:** High  
**Story Points:** 5  
**Assignee:** Database Engineer  

**Description:**  
Create the games table to store matchup information and scores.

**Acceptance Criteria:**
- [ ] Create games table with all required columns
- [ ] Add foreign key constraints to leagues and teams
- [ ] Create unique constraint on league_id, week, season, home_team_id, away_team_id
- [ ] Add CHECK constraints for data validation
- [ ] Create performance indexes
- [ ] Test game data insertion and retrieval

**Technical Notes:**
- Include columns for: scores, projections, playoff flags, winner
- Indexes: (league_id, season, week), (home_team_id, away_team_id), is_complete
- Support for playoff and consolation games

---

## Phase 4: Transaction and History Tables (Week 4)

### FAN-110: Create Transactions Table
**Type:** Task  
**Priority:** Medium  
**Story Points:** 4  
**Assignee:** Database Engineer  

**Description:**  
Create the transactions table to track roster moves, trades, and waiver claims.

**Acceptance Criteria:**
- [ ] Create transactions table with all required columns
- [ ] Add foreign key constraints to leagues and teams
- [ ] Add CHECK constraints for transaction type and status
- [ ] Store player arrays for adds/drops
- [ ] Create performance indexes
- [ ] Test transaction data insertion and retrieval

**Technical Notes:**
- Transaction types: add, drop, trade, commish
- Status values: pending, accepted, rejected, executed
- Support for FAAB bids and waiver priority

---

### FAN-111: Create Draft Results Table
**Type:** Task  
**Priority:** Medium  
**Story Points:** 3  
**Assignee:** Database Engineer  

**Description:**  
Create the draft_results table to store draft history and keeper information.

**Acceptance Criteria:**
- [ ] Create draft_results table with all required columns
- [ ] Add foreign key constraints to leagues, teams, and players
- [ ] Create unique constraint on league_id, overall_pick
- [ ] Support for auction draft costs
- [ ] Create performance indexes
- [ ] Test draft data insertion and retrieval

**Technical Notes:**
- Include columns for: round, pick, overall_pick, keeper_round, cost
- Support for both snake and auction drafts
- Indexes: (league_id, overall_pick), team_id, player_id

---

### FAN-112: Create Sync Checkpoints Table
**Type:** Task  
**Priority:** Medium  
**Story Points:** 3  
**Assignee:** Database Engineer  

**Description:**  
Create the sync_checkpoints table for error recovery and sync progress tracking.

**Acceptance Criteria:**
- [ ] Create sync_checkpoints table with all required columns
- [ ] Add foreign key constraint to leagues table
- [ ] Store completed steps as array
- [ ] Track sync progress and errors
- [ ] Create performance indexes
- [ ] Test checkpoint functionality

**Technical Notes:**
- Include columns for: sync_type, completed_steps array, current_step, error_message
- Unique constraint on league_id, sync_type
- Indexes: league_id, completed_at

---

## Phase 5: Basic Analytics Functions (Week 5)

### FAN-113: Implement Team Analytics Function
**Type:** Task  
**Priority:** Medium  
**Story Points:** 4  
**Assignee:** Database Engineer  

**Description:**  
Create database function to calculate team performance analytics and trends.

**Acceptance Criteria:**
- [ ] Create get_team_analytics function
- [ ] Calculate weekly points and opponent points
- [ ] Track cumulative wins and weekly rankings
- [ ] Test function with sample data
- [ ] Document function parameters and return values

**Technical Notes:**
```sql
CREATE OR REPLACE FUNCTION get_team_analytics(
  p_team_id UUID,
  p_season INTEGER
) RETURNS TABLE (...)
```

---

### FAN-114: Implement League Standings Function
**Type:** Task  
**Priority:** Medium  
**Story Points:** 3  
**Assignee:** Database Engineer  

**Description:**  
Create database function to calculate league standings and rankings.

**Acceptance Criteria:**
- [ ] Create get_league_standings function
- [ ] Calculate win percentages and rankings
- [ ] Handle ties correctly
- [ ] Test function with sample data
- [ ] Document function usage

**Technical Notes:**
- Calculate win percentage: (wins + 0.5 * ties) / total_games
- Rank by win percentage, then points_for
- Return team_id, team_name, wins, losses, ties, points_for, points_against, win_percentage, rank

---

### FAN-115: Implement Player Performance Function
**Type:** Task  
**Priority:** Medium  
**Story Points:** 3  
**Assignee:** Database Engineer  

**Description:**  
Create database function to retrieve player performance data with filtering options.

**Acceptance Criteria:**
- [ ] Create get_player_performance function
- [ ] Support filtering by league, season, and week
- [ ] Return player details and performance metrics
- [ ] Order by points scored (descending)
- [ ] Test function with sample data
- [ ] Document function parameters

**Technical Notes:**
- Optional week parameter for specific week or all weeks
- Return: player_id, player_name, position, nfl_team, week, points_scored, projected_points, game_played
- Order by points_scored DESC NULLS LAST

---

## Phase 6: Security and Row Level Security (Week 6)

### FAN-116: Enable Row Level Security
**Type:** Task  
**Priority:** High  
**Story Points:** 2  
**Assignee:** Database Engineer  

**Description:**  
Enable Row Level Security on all fantasy sports tables for data isolation.

**Acceptance Criteria:**
- [ ] Enable RLS on leagues table
- [ ] Enable RLS on teams table
- [ ] Enable RLS on player_stats table
- [ ] Enable RLS on rosters table
- [ ] Enable RLS on games table
- [ ] Enable RLS on transactions table
- [ ] Enable RLS on draft_results table
- [ ] Enable RLS on sync_checkpoints table
- [ ] Test RLS functionality

**Technical Notes:**
```sql
ALTER TABLE public.leagues ENABLE ROW LEVEL SECURITY;
-- Repeat for all tables
```

---

### FAN-117: Create RLS Policies for Leagues
**Type:** Task  
**Priority:** High  
**Story Points:** 3  
**Assignee:** Database Engineer  

**Description:**  
Implement Row Level Security policies for leagues table to ensure users can only access their own leagues.

**Acceptance Criteria:**
- [ ] Create SELECT policy for user's own leagues
- [ ] Create UPDATE policy for user's own leagues
- [ ] Create INSERT policy for user's own leagues
- [ ] Test policies with different user contexts
- [ ] Verify data isolation works correctly

**Technical Notes:**
```sql
CREATE POLICY "Users can view own leagues" ON public.leagues
  FOR SELECT USING (auth.uid() = user_id);
```

---

### FAN-118: Create RLS Policies for Related Tables
**Type:** Task  
**Priority:** High  
**Story Points:** 5  
**Assignee:** Database Engineer  

**Description:**  
Implement Row Level Security policies for all tables related to leagues to ensure proper data access control.

**Acceptance Criteria:**
- [ ] Create policies for teams table (via league ownership)
- [ ] Create policies for player_stats table (via league ownership)
- [ ] Create policies for rosters table (via team ownership)
- [ ] Create policies for games table (via league ownership)
- [ ] Create policies for transactions table (via league ownership)
- [ ] Create policies for draft_results table (via league ownership)
- [ ] Create policies for sync_checkpoints table (via league ownership)
- [ ] Test all policies thoroughly

**Technical Notes:**
- Use EXISTS subqueries to check league ownership
- Test with multiple users and leagues
- Verify no data leakage between users

---

## Phase 7: Triggers and Automation (Week 7)

### FAN-119: Create Update Timestamp Triggers
**Type:** Task  
**Priority:** Medium  
**Story Points:** 3  
**Assignee:** Database Engineer  

**Description:**  
Implement triggers to automatically update the updated_at timestamp column on record modifications.

**Acceptance Criteria:**
- [ ] Create update_updated_at_column function
- [ ] Create triggers for leagues table
- [ ] Create triggers for teams table
- [ ] Create triggers for rosters table
- [ ] Create triggers for games table
- [ ] Test trigger functionality
- [ ] Verify timestamps are updated correctly

**Technical Notes:**
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';
```

---

### FAN-120: Create Data Validation Triggers
**Type:** Task  
**Priority:** Medium  
**Story Points:** 4  
**Assignee:** Database Engineer  

**Description:**  
Implement triggers to validate data integrity and enforce business rules.

**Acceptance Criteria:**
- [ ] Create validate_game_data function
- [ ] Ensure home and away teams are different
- [ ] Validate scores are non-negative
- [ ] Automatically set winner when game is complete
- [ ] Create trigger for games table
- [ ] Test validation rules
- [ ] Handle edge cases (ties, incomplete games)

**Technical Notes:**
- Validate team uniqueness in games
- Set winner based on scores when is_complete = true
- Handle ties appropriately

---

## Phase 8: Testing and Validation (Week 8)

### FAN-121: Insert Test Data
**Type:** Task  
**Priority:** Medium  
**Story Points:** 3  
**Assignee:** Database Engineer  

**Description:**  
Create and insert comprehensive test data to validate the database schema and constraints.

**Acceptance Criteria:**
- [ ] Create test league data
- [ ] Create test team data
- [ ] Create test player data
- [ ] Create test game data
- [ ] Create test transaction data
- [ ] Verify all constraints work correctly
- [ ] Test foreign key relationships

**Technical Notes:**
- Use realistic fantasy sports data
- Test edge cases and boundary conditions
- Verify data integrity across all tables

---

### FAN-122: Performance Testing
**Type:** Task  
**Priority:** Medium  
**Story Points:** 4  
**Assignee:** Database Engineer  

**Description:**  
Test query performance and optimize indexes for common operations.

**Acceptance Criteria:**
- [ ] Test common query performance
- [ ] Test analytics function performance
- [ ] Analyze query execution plans
- [ ] Optimize slow queries
- [ ] Document performance benchmarks
- [ ] Create performance monitoring queries

**Technical Notes:**
- Use EXPLAIN ANALYZE for query analysis
- Test with realistic data volumes
- Monitor index usage and effectiveness

---

### FAN-123: Security Testing
**Type:** Task  
**Priority:** High  
**Story Points:** 3  
**Assignee:** Database Engineer  

**Description:**  
Test Row Level Security policies and verify data isolation between users.

**Acceptance Criteria:**
- [ ] Test RLS policies with multiple users
- [ ] Verify users cannot access other users' data
- [ ] Test edge cases and security scenarios
- [ ] Document security test results
- [ ] Create security testing procedures

**Technical Notes:**
- Test with authenticated and unauthenticated users
- Verify no data leakage between users
- Test policy bypass attempts

---

### FAN-124: Documentation and Handoff
**Type:** Task  
**Priority:** Medium  
**Story Points:** 2  
**Assignee:** Database Engineer  

**Description:**  
Create comprehensive documentation for the database schema and implementation.

**Acceptance Criteria:**
- [ ] Document all tables and their relationships
- [ ] Document all functions and their usage
- [ ] Document RLS policies and security model
- [ ] Create database schema diagram
- [ ] Document testing procedures
- [ ] Create maintenance procedures

**Technical Notes:**
- Include ERD diagram
- Document all constraints and indexes
- Provide usage examples for functions

---

## Future Enhancements (Post-MVP)

### FAN-200: Implement Materialized Views for Analytics
**Type:** Epic  
**Priority:** Low  
**Story Points:** 13  
**Sprint:** Future Enhancement  

**Description:**  
Implement materialized views for complex analytics queries to improve performance.

**Epic Breakdown:**
- FAN-201: Create team performance trends materialized view
- FAN-202: Create player performance summary materialized view
- FAN-203: Implement materialized view refresh strategies
- FAN-204: Create indexes for materialized views

---

### FAN-300: Implement Caching Layer
**Type:** Epic  
**Priority:** Low  
**Story Points:** 21  
**Sprint:** Future Enhancement  

**Description:**  
Implement Redis caching layer for frequently accessed data and real-time updates.

**Epic Breakdown:**
- FAN-301: Set up Redis infrastructure
- FAN-302: Implement cache manager class
- FAN-303: Cache league and team data
- FAN-304: Cache live game scores
- FAN-305: Implement cache invalidation strategies
- FAN-306: Add cache monitoring and metrics

---

### FAN-400: Database Partitioning
**Type:** Epic  
**Priority:** Low  
**Story Points:** 8  
**Sprint:** Future Enhancement  

**Description:**  
Implement table partitioning for large tables to improve query performance and maintenance.

**Epic Breakdown:**
- FAN-401: Partition player_stats table by season
- FAN-402: Partition games table by season
- FAN-403: Implement partition maintenance procedures
- FAN-404: Update queries to work with partitions

---

## Sprint Planning Notes

### Sprint 1 (Week 1-2): Foundation
- FAN-101: Enable PostgreSQL Extensions
- FAN-102: Extend User Profiles
- FAN-103: Create Encryption Functions
- FAN-104: Create Leagues Table
- FAN-105: Create Teams Table
- FAN-106: Create Players Table

**Total Story Points:** 22

### Sprint 2 (Week 3-4): Core Data
- FAN-107: Create Player Stats Table
- FAN-108: Create Rosters Table
- FAN-109: Create Games Table
- FAN-110: Create Transactions Table
- FAN-111: Create Draft Results Table
- FAN-112: Create Sync Checkpoints Table

**Total Story Points:** 24

### Sprint 3 (Week 5-6): Analytics & Security
- FAN-113: Team Analytics Function
- FAN-114: League Standings Function
- FAN-115: Player Performance Function
- FAN-116: Enable Row Level Security
- FAN-117: RLS Policies for Leagues
- FAN-118: RLS Policies for Related Tables

**Total Story Points:** 20

### Sprint 4 (Week 7-8): Automation & Testing
- FAN-119: Update Timestamp Triggers
- FAN-120: Data Validation Triggers
- FAN-121: Insert Test Data
- FAN-122: Performance Testing
- FAN-123: Security Testing
- FAN-124: Documentation and Handoff

**Total Story Points:** 19

**Total MVP Story Points:** 85
