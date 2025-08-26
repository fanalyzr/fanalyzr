#!/usr/bin/env node

/**
 * MVP-47: REST Seeder for Test Data
 * This script populates the database with test data via REST API calls
 * 
 * Usage:
 *   node supabase/seed-rest.cjs
 *   node supabase/seed-rest.cjs --reset  # Full database reset
 */

const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

// Configuration
const SUPABASE_URL = process.env.SUPABASE_URL || 'http://localhost:54321';
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || 'your-anon-key';

// Test user credentials
const TEST_USER = {
  email: 'test@fanalyzr.com',
  password: 'testpassword123',
  full_name: 'Test User'
};

// Test data
const TEST_DATA = {
  leagues: [
    {
      yahoo_league_key: '399.l.123456',
      yahoo_game_key: '399',
      name: 'Test Fantasy League 2024',
      season: 2024,
      league_type: 'private',
      scoring_type: 'head',
      draft_type: 'live',
      num_teams: 12,
      sync_status: 'completed'
    },
    {
      yahoo_league_key: '399.l.789012',
      yahoo_game_key: '399',
      name: 'Public Fantasy League 2024',
      season: 2024,
      league_type: 'public',
      scoring_type: 'head',
      draft_type: 'live',
      num_teams: 10,
      sync_status: 'completed'
    }
  ],
  teams: [
    {
      yahoo_team_key: '399.l.123456.t.1',
      yahoo_team_id: 1,
      name: "Yarber's Warriors",
      owner_name: 'Josh Yarber',
      owner_guid: 'test_owner_guid_1',
      is_current_user: true,
      wins: 8,
      losses: 5,
      ties: 0,
      points_for: 1456.78,
      points_against: 1423.45,
      rank: 3
    },
    {
      yahoo_team_key: '399.l.123456.t.2',
      yahoo_team_id: 2,
      name: 'Fantasy Legends',
      owner_name: 'John Smith',
      owner_guid: 'test_owner_guid_2',
      is_current_user: false,
      wins: 10,
      losses: 3,
      ties: 0,
      points_for: 1589.23,
      points_against: 1345.67,
      rank: 1
    }
  ],
  players: [
    {
      yahoo_player_key: '399.p.1234',
      yahoo_player_id: 1234,
      full_name: 'Patrick Mahomes',
      first_name: 'Patrick',
      last_name: 'Mahomes',
      primary_position: 'QB',
      eligible_positions: ['QB'],
      nfl_team: 'KC',
      status: 'ACTIVE'
    },
    {
      yahoo_player_key: '399.p.1236',
      yahoo_player_id: 1236,
      full_name: 'Christian McCaffrey',
      first_name: 'Christian',
      last_name: 'McCaffrey',
      primary_position: 'RB',
      eligible_positions: ['RB', 'WR'],
      nfl_team: 'SF',
      status: 'ACTIVE'
    },
    {
      yahoo_player_key: '399.p.1238',
      yahoo_player_id: 1238,
      full_name: 'Tyreek Hill',
      first_name: 'Tyreek',
      last_name: 'Hill',
      primary_position: 'WR',
      eligible_positions: ['WR'],
      nfl_team: 'MIA',
      status: 'ACTIVE'
    }
  ],
  games: [
    {
      week: 1,
      season: 2024,
      home_score: 125.67,
      away_score: 118.45,
      home_projected: 120.50,
      away_projected: 115.75,
      is_playoff: false,
      is_consolation: false,
      is_complete: true
    },
    {
      week: 2,
      season: 2024,
      home_score: 145.78,
      away_score: 132.45,
      home_projected: 140.25,
      away_projected: 135.50,
      is_playoff: false,
      is_consolation: false,
      is_complete: true
    }
  ]
};

class RestSeeder {
  constructor() {
    this.supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    this.userId = null;
    this.leagueIds = [];
    this.teamIds = [];
    this.playerIds = [];
  }

  async init() {
    console.log('🚀 Initializing REST Seeder...');
    
    // Check if we need to reset the database
    if (process.argv.includes('--reset')) {
      console.log('🔄 Resetting database...');
      await this.resetDatabase();
    }

    // Sign up or sign in test user
    await this.authenticateUser();
  }

  async resetDatabase() {
    try {
      // This would typically call a reset endpoint
      // For now, we'll just log that reset was requested
      console.log('⚠️  Database reset requested. Please run: npx supabase db reset --no-seed --yes');
    } catch (error) {
      console.error('❌ Error resetting database:', error.message);
    }
  }

  async authenticateUser() {
    try {
      console.log('🔐 Authenticating test user...');
      
      // Try to sign in first
      const { data: signInData, error: signInError } = await this.supabase.auth.signInWithPassword({
        email: TEST_USER.email,
        password: TEST_USER.password
      });

      if (signInError) {
        // If sign in fails, try to sign up
        console.log('📝 Creating new test user...');
        const { data: signUpData, error: signUpError } = await this.supabase.auth.signUp({
          email: TEST_USER.email,
          password: TEST_USER.password,
          options: {
            data: {
              full_name: TEST_USER.full_name
            }
          }
        });

        if (signUpError) {
          throw new Error(`Failed to create user: ${signUpError.message}`);
        }

        this.userId = signUpData.user.id;
        console.log('✅ Test user created successfully');
      } else {
        this.userId = signInData.user.id;
        console.log('✅ Test user authenticated successfully');
      }
    } catch (error) {
      console.error('❌ Authentication error:', error.message);
      throw error;
    }
  }

  async seedLeagues() {
    console.log('🏈 Seeding leagues...');
    
    for (const leagueData of TEST_DATA.leagues) {
      try {
        const { data, error } = await this.supabase
          .from('leagues')
          .insert({
            user_id: this.userId,
            ...leagueData
          })
          .select()
          .single();

        if (error) {
          if (error.code === '23505') { // Unique constraint violation
            console.log(`⚠️  League ${leagueData.name} already exists, skipping...`);
            // Get existing league
            const { data: existingLeague } = await this.supabase
              .from('leagues')
              .select('id')
              .eq('yahoo_league_key', leagueData.yahoo_league_key)
              .eq('season', leagueData.season)
              .eq('user_id', this.userId)
              .single();
            
            if (existingLeague) {
              this.leagueIds.push(existingLeague.id);
            }
          } else {
            throw error;
          }
        } else {
          this.leagueIds.push(data.id);
          console.log(`✅ Created league: ${data.name}`);
        }
      } catch (error) {
        console.error(`❌ Error creating league ${leagueData.name}:`, error.message);
      }
    }
  }

  async seedTeams() {
    console.log('👥 Seeding teams...');
    
    for (let i = 0; i < TEST_DATA.teams.length; i++) {
      const teamData = TEST_DATA.teams[i];
      const leagueId = this.leagueIds[i % this.leagueIds.length];
      
      try {
        const { data, error } = await this.supabase
          .from('teams')
          .insert({
            league_id: leagueId,
            ...teamData
          })
          .select()
          .single();

        if (error) {
          if (error.code === '23505') { // Unique constraint violation
            console.log(`⚠️  Team ${teamData.name} already exists, skipping...`);
            // Get existing team
            const { data: existingTeam } = await this.supabase
              .from('teams')
              .select('id')
              .eq('yahoo_team_key', teamData.yahoo_team_key)
              .eq('league_id', leagueId)
              .single();
            
            if (existingTeam) {
              this.teamIds.push(existingTeam.id);
            }
          } else {
            throw error;
          }
        } else {
          this.teamIds.push(data.id);
          console.log(`✅ Created team: ${data.name}`);
        }
      } catch (error) {
        console.error(`❌ Error creating team ${teamData.name}:`, error.message);
      }
    }
  }

  async seedPlayers() {
    console.log('🏃 Seeding players...');
    
    for (const playerData of TEST_DATA.players) {
      try {
        const { data, error } = await this.supabase
          .from('players')
          .insert(playerData)
          .select()
          .single();

        if (error) {
          if (error.code === '23505') { // Unique constraint violation
            console.log(`⚠️  Player ${playerData.full_name} already exists, skipping...`);
            // Get existing player
            const { data: existingPlayer } = await this.supabase
              .from('players')
              .select('id')
              .eq('yahoo_player_key', playerData.yahoo_player_key)
              .single();
            
            if (existingPlayer) {
              this.playerIds.push(existingPlayer.id);
            }
          } else {
            throw error;
          }
        } else {
          this.playerIds.push(data.id);
          console.log(`✅ Created player: ${data.full_name}`);
        }
      } catch (error) {
        console.error(`❌ Error creating player ${playerData.full_name}:`, error.message);
      }
    }
  }

  async seedGames() {
    console.log('🎮 Seeding games...');
    
    for (let i = 0; i < TEST_DATA.games.length; i++) {
      const gameData = TEST_DATA.games[i];
      const leagueId = this.leagueIds[i % this.leagueIds.length];
      const homeTeamId = this.teamIds[i % this.teamIds.length];
      const awayTeamId = this.teamIds[(i + 1) % this.teamIds.length];
      
      try {
        const { data, error } = await this.supabase
          .from('games')
          .insert({
            league_id: leagueId,
            home_team_id: homeTeamId,
            away_team_id: awayTeamId,
            winner_id: gameData.is_complete ? (gameData.home_score > gameData.away_score ? homeTeamId : awayTeamId) : null,
            ...gameData
          })
          .select()
          .single();

        if (error) {
          if (error.code === '23505') { // Unique constraint violation
            console.log(`⚠️  Game for week ${gameData.week} already exists, skipping...`);
          } else {
            throw error;
          }
        } else {
          console.log(`✅ Created game: Week ${data.week} - ${data.home_score} vs ${data.away_score}`);
        }
      } catch (error) {
        console.error(`❌ Error creating game for week ${gameData.week}:`, error.message);
      }
    }
  }

  async seedPlayerStats() {
    console.log('📊 Seeding player stats...');
    
    for (let i = 0; i < this.playerIds.length; i++) {
      const playerId = this.playerIds[i];
      const teamId = this.teamIds[i % this.teamIds.length];
      const leagueId = this.leagueIds[i % this.leagueIds.length];
      
      try {
        const { data, error } = await this.supabase
          .from('player_stats')
          .insert({
            league_id: leagueId,
            player_id: playerId,
            team_id: teamId,
            week: 1,
            season: 2024,
            points_scored: Math.random() * 30 + 10, // Random points between 10-40
            projected_points: Math.random() * 25 + 15, // Random projected points between 15-40
            game_played: true,
            stats: {
              passing_yards: Math.floor(Math.random() * 400),
              rushing_yards: Math.floor(Math.random() * 150),
              receiving_yards: Math.floor(Math.random() * 200)
            }
          })
          .select()
          .single();

        if (error) {
          if (error.code === '23505') { // Unique constraint violation
            console.log(`⚠️  Player stats for player ${playerId} week 1 already exists, skipping...`);
          } else {
            throw error;
          }
        } else {
          console.log(`✅ Created player stats: ${data.points_scored} points`);
        }
      } catch (error) {
        console.error(`❌ Error creating player stats for player ${playerId}:`, error.message);
      }
    }
  }

  async run() {
    try {
      await this.init();
      
      console.log('\n🌱 Starting data seeding...\n');
      
      await this.seedLeagues();
      await this.seedTeams();
      await this.seedPlayers();
      await this.seedGames();
      await this.seedPlayerStats();
      
      console.log('\n✅ Seeding completed successfully!');
      console.log(`📊 Created ${this.leagueIds.length} leagues, ${this.teamIds.length} teams, ${this.playerIds.length} players`);
      
    } catch (error) {
      console.error('\n❌ Seeding failed:', error.message);
      process.exit(1);
    }
  }
}

// Run the seeder
if (require.main === module) {
  const seeder = new RestSeeder();
  seeder.run();
}

module.exports = RestSeeder;

