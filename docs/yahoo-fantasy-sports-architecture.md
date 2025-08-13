# Fanalyzr Yahoo Fantasy Sports Integration Architecture

## Introduction

This document outlines the complete architecture for integrating Yahoo Fantasy Sports API with OAuth authentication into the Fanalyzr application. The integration will allow users to sync multiple fantasy football leagues, toggle between leagues and seasons, and generate visualizations and analysis based on the synced data.

### Key Requirements
- OAuth 2.0 authentication with Yahoo Fantasy Sports API
- Support for multiple league synchronization
- League and season toggling functionality
- Data visualization and analysis capabilities
- Read-only access (no modifications to Yahoo data)

## High Level Architecture

### Technical Summary
The architecture leverages the existing React TypeScript frontend with Supabase backend, extending it with Yahoo Fantasy Sports API integration. The system uses OAuth 2.0 for secure authentication, implements a robust data synchronization layer, and provides a scalable database schema for storing fantasy sports data. The frontend will feature league management, season selection, and data visualization components.

### Platform and Infrastructure
**Platform:** Supabase + Vercel
**Key Services:** 
- Supabase (Database, Auth, Real-time)
- Vercel (Frontend hosting, Edge Functions)
- Yahoo Fantasy Sports API (External data source)

### Repository Structure
**Structure:** Monorepo with existing structure
**Package Organization:** Extend existing src/ structure with new fantasy sports modules

## Tech Stack

| Category | Technology | Version | Purpose | Rationale |
|----------|------------|---------|---------|-----------|
| Frontend Framework | React | 18+ | UI Framework | Existing codebase |
| UI Library | Material-UI | 7.x | Component Library | Existing codebase |
| Backend | Supabase | Latest | Database & Auth | Existing infrastructure |
| API Style | REST | - | Yahoo API Integration | Yahoo API is REST-based |
| OAuth Library | OAuth 2.0 | - | Yahoo Authentication | Industry standard |
| State Management | React Context + SWR | - | Server state | Existing patterns |
| Data Visualization | MUI X Charts | 8.x | Fantasy data charts | Consistent with MUI |

## Data Models

### User Profile
**Purpose:** Extends existing user profiles with Yahoo OAuth integration

**Key Attributes:**
- `id`: string - Unique user identifier (references auth.users)
- `email`: string - User email address
- `yahoo_guid`: string - Yahoo user GUID from OAuth
- `yahoo_access_token`: string - Encrypted OAuth access token
- `yahoo_refresh_token`: string - Encrypted OAuth refresh token
- `token_expires_at`: timestamp - Token expiration time

### League
**Purpose:** Represents a Yahoo Fantasy Football league

**Key Attributes:**
- `id`: string - Unique league identifier
- `user_id`: string - Owner user ID
- `yahoo_league_key`: string - Yahoo league key
- `name`: string - League name
- `season`: number - Fantasy season year
- `league_type`: string - League type (public/private)
- `num_teams`: number - Number of teams in league
- `last_synced_at`: timestamp - Last data sync time

### Team
**Purpose:** Represents a team within a fantasy league

**Key Attributes:**
- `id`: string - Unique team identifier
- `league_id`: string - Associated league ID
- `yahoo_team_key`: string - Yahoo team key
- `name`: string - Team name
- `owner_name`: string - Team owner name
- `division_id`: number - Division within league
- `wins`: number - Season wins
- `losses`: number - Season losses
- `ties`: number - Season ties

### Player
**Purpose:** Represents a player on a fantasy team

**Key Attributes:**
- `id`: string - Unique player identifier
- `yahoo_player_key`: string - Yahoo player key
- `name`: string - Player name
- `position`: string - Player position
- `nfl_team`: string - NFL team abbreviation
- `status`: string - Player status (active/injured/etc)

### Roster
**Purpose:** Represents a team's roster for a specific week

**Key Attributes:**
- `id`: string - Unique roster identifier
- `team_id`: string - Associated team ID
- `week`: number - Fantasy week number
- `players`: jsonb - Array of player data with positions

### Game
**Purpose:** Represents a fantasy matchup between teams

**Key Attributes:**
- `id`: string - Unique game identifier
- `league_id`: string - Associated league ID
- `week`: number - Fantasy week number
- `home_team_id`: string - Home team ID
- `away_team_id`: string - Away team ID
- `home_score`: number - Home team score
- `away_score`: number - Away team score
- `winner_id`: string - Winning team ID

## Database Schema

```sql
-- Extend existing user_profiles table with Yahoo OAuth fields
ALTER TABLE public.user_profiles 
ADD COLUMN yahoo_guid TEXT UNIQUE,
ADD COLUMN yahoo_access_token TEXT,
ADD COLUMN yahoo_refresh_token TEXT,
ADD COLUMN token_expires_at TIMESTAMP WITH TIME ZONE;

-- Leagues table
CREATE TABLE public.leagues (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  yahoo_league_key TEXT NOT NULL,
  name TEXT NOT NULL,
  season INTEGER NOT NULL,
  league_type TEXT NOT NULL,
  num_teams INTEGER NOT NULL,
  last_synced_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(yahoo_league_key, season)
);

-- Teams table
CREATE TABLE public.teams (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  league_id UUID REFERENCES public.leagues(id) ON DELETE CASCADE,
  yahoo_team_key TEXT NOT NULL,
  name TEXT NOT NULL,
  owner_name TEXT NOT NULL,
  division_id INTEGER,
  wins INTEGER DEFAULT 0,
  losses INTEGER DEFAULT 0,
  ties INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(yahoo_team_key, league_id)
);

-- Players table
CREATE TABLE public.players (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  yahoo_player_key TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  position TEXT NOT NULL,
  nfl_team TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Rosters table
CREATE TABLE public.rosters (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
  week INTEGER NOT NULL,
  players JSONB NOT NULL DEFAULT '[]',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(team_id, week)
);

-- Games table
CREATE TABLE public.games (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  league_id UUID REFERENCES public.leagues(id) ON DELETE CASCADE,
  week INTEGER NOT NULL,
  home_team_id UUID REFERENCES public.teams(id),
  away_team_id UUID REFERENCES public.teams(id),
  home_score DECIMAL(6,2),
  away_score DECIMAL(6,2),
  winner_id UUID REFERENCES public.teams(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(league_id, week, home_team_id, away_team_id)
);

-- Indexes for performance
CREATE INDEX idx_leagues_user_id ON public.leagues(user_id);
CREATE INDEX idx_leagues_yahoo_key ON public.leagues(yahoo_league_key);
CREATE INDEX idx_teams_league_id ON public.teams(league_id);
CREATE INDEX idx_teams_yahoo_key ON public.teams(yahoo_team_key);
CREATE INDEX idx_rosters_team_week ON public.rosters(team_id, week);
CREATE INDEX idx_games_league_week ON public.games(league_id, week);

-- Row Level Security
ALTER TABLE public.leagues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rosters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own profile data" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can view own leagues" ON public.leagues
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view teams in own leagues" ON public.teams
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.leagues 
      WHERE leagues.id = teams.league_id 
      AND leagues.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view rosters in own leagues" ON public.rosters
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.teams 
      JOIN public.leagues ON leagues.id = teams.league_id
      WHERE teams.id = rosters.team_id 
      AND leagues.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can view games in own leagues" ON public.games
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.leagues 
      WHERE leagues.id = games.league_id 
      AND leagues.user_id = auth.uid()
    )
  );
```

## API Specification

### Yahoo Fantasy Sports API Integration

**Base URL:** `https://fantasysports.yahooapis.com/fantasy/v2`

**Authentication:** OAuth 2.0 with PKCE

**Key Endpoints:**
- `GET /users;use_login=1/games;game_keys=nfl` - Get user's NFL fantasy games
- `GET /league/{league_key}/teams` - Get league teams
- `GET /team/{team_key}/roster;week={week}` - Get team roster for week
- `GET /league/{league_key}/scoreboard;week={week}` - Get league scoreboard
- `GET /league/{league_key}/settings` - Get league settings

### Internal API Endpoints

```typescript
// OAuth endpoints
POST /api/yahoo/auth/initiate - Start OAuth flow
GET /api/yahoo/auth/callback - Handle OAuth callback
POST /api/yahoo/auth/refresh - Refresh access token

// League management
GET /api/leagues - Get user's leagues
POST /api/leagues/sync - Sync league data
GET /api/leagues/{id} - Get specific league
GET /api/leagues/{id}/teams - Get league teams
GET /api/leagues/{id}/scoreboard - Get league scoreboard

// Data endpoints
GET /api/teams/{id}/roster - Get team roster
GET /api/players/{id} - Get player details
GET /api/analytics/league/{id} - Get league analytics
```

## Component Architecture

### Frontend Components

```typescript
// League Management
src/sections/fantasy/
├── league-selector/
│   ├── LeagueSelector.tsx
│   ├── LeagueCard.tsx
│   └── AddLeagueButton.tsx
├── season-selector/
│   ├── SeasonSelector.tsx
│   └── SeasonCard.tsx
├── league-dashboard/
│   ├── LeagueDashboard.tsx
│   ├── TeamStandings.tsx
│   ├── WeeklyMatchups.tsx
│   └── LeagueStats.tsx
└── analytics/
    ├── AnalyticsDashboard.tsx
    ├── PlayerPerformance.tsx
    ├── TeamComparison.tsx
    └── TrendAnalysis.tsx

// OAuth Components
src/sections/auth/
├── YahooAuthButton.tsx
├── YahooAuthCallback.tsx
└── YahooAuthStatus.tsx
```

### Backend Services

```typescript
// Yahoo API Service
src/lib/yahoo/
├── yahoo-api.ts
├── oauth-handler.ts
├── data-sync.ts
└── types.ts

// Fantasy Data Service
src/lib/fantasy/
├── league-service.ts
├── team-service.ts
├── player-service.ts
└── analytics-service.ts
```

## OAuth Implementation Plan

### 1. OAuth Flow Setup

```typescript
// OAuth Configuration
const YAHOO_OAUTH_CONFIG = {
  clientId: process.env.YAHOO_CLIENT_ID,
  redirectUri: `${process.env.APP_URL}/api/yahoo/auth/callback`,
  scope: 'fspt-r', // Read-only fantasy sports access
  authUrl: 'https://api.login.yahoo.com/oauth2/request_auth',
  tokenUrl: 'https://api.login.yahoo.com/oauth2/get_token'
};

// PKCE Flow Implementation
export class YahooOAuthHandler {
  async initiateAuth(): Promise<string> {
    const codeVerifier = this.generateCodeVerifier();
    const codeChallenge = await this.generateCodeChallenge(codeVerifier);
    
    const authUrl = new URL(YAHOO_OAUTH_CONFIG.authUrl);
    authUrl.searchParams.set('client_id', YAHOO_OAUTH_CONFIG.clientId);
    authUrl.searchParams.set('redirect_uri', YAHOO_OAUTH_CONFIG.redirectUri);
    authUrl.searchParams.set('response_type', 'code');
    authUrl.searchParams.set('scope', YAHOO_OAUTH_CONFIG.scope);
    authUrl.searchParams.set('code_challenge', codeChallenge);
    authUrl.searchParams.set('code_challenge_method', 'S256');
    
    // Store code_verifier in session
    await this.storeCodeVerifier(codeVerifier);
    
    return authUrl.toString();
  }
  
  async handleCallback(code: string): Promise<OAuthTokens> {
    const codeVerifier = await this.getStoredCodeVerifier();
    
    const response = await fetch(YAHOO_OAUTH_CONFIG.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${this.getBasicAuth()}`
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        redirect_uri: YAHOO_OAUTH_CONFIG.redirectUri,
        code_verifier: codeVerifier
      })
    });
    
    return response.json();
  }
}
```

### 2. Data Synchronization

```typescript
export class FantasyDataSync {
  async syncUserLeagues(userId: string, accessToken: string): Promise<void> {
    // Get user's fantasy games
    const games = await this.yahooApi.getUserGames(accessToken);
    
    // Filter for NFL games
    const nflGames = games.filter(game => game.game_code === 'nfl');
    
    // Sync each league
    for (const game of nflGames) {
      await this.syncLeague(userId, game.league_key, accessToken);
    }
  }
  
  async syncLeague(userId: string, leagueKey: string, accessToken: string): Promise<void> {
    // Get league details
    const leagueData = await this.yahooApi.getLeague(leagueKey, accessToken);
    
    // Upsert league
    const league = await this.upsertLeague(userId, leagueData);
    
    // Sync teams
    await this.syncTeams(league.id, leagueKey, accessToken);
    
    // Sync current week data
    await this.syncCurrentWeek(league.id, leagueKey, accessToken);
  }
  
  async syncTeams(leagueId: string, leagueKey: string, accessToken: string): Promise<void> {
    const teams = await this.yahooApi.getLeagueTeams(leagueKey, accessToken);
    
    for (const teamData of teams) {
      await this.upsertTeam(leagueId, teamData);
    }
  }
  
  async syncCurrentWeek(leagueId: string, leagueKey: string, accessToken: string): Promise<void> {
    const currentWeek = await this.yahooApi.getCurrentWeek(leagueKey, accessToken);
    
    // Sync rosters for current week
    const teams = await this.getLeagueTeams(leagueId);
    for (const team of teams) {
      const roster = await this.yahooApi.getTeamRoster(team.yahoo_team_key, currentWeek, accessToken);
      await this.upsertRoster(team.id, currentWeek, roster);
    }
    
    // Sync games for current week
    const scoreboard = await this.yahooApi.getLeagueScoreboard(leagueKey, currentWeek, accessToken);
    await this.upsertGames(leagueId, currentWeek, scoreboard);
  }
}
```

## Frontend Implementation

### League Management UI

```typescript
// League Selector Component
export function LeagueSelector() {
  const { data: leagues, isLoading } = useSWR('/api/leagues', fetcher);
  const [selectedLeague, setSelectedLeague] = useState<string | null>(null);
  
  return (
    <Box>
      <Typography variant="h6" gutterBottom>
        Your Leagues
      </Typography>
      
      {isLoading ? (
        <CircularProgress />
      ) : (
        <Grid container spacing={2}>
          {leagues?.map((league) => (
            <Grid item xs={12} sm={6} md={4} key={league.id}>
              <LeagueCard
                league={league}
                selected={selectedLeague === league.id}
                onSelect={() => setSelectedLeague(league.id)}
              />
            </Grid>
          ))}
          <Grid item xs={12} sm={6} md={4}>
            <AddLeagueButton />
          </Grid>
        </Grid>
      )}
    </Box>
  );
}

// Season Selector Component
export function SeasonSelector({ leagueId }: { leagueId: string }) {
  const { data: seasons } = useSWR(`/api/leagues/${leagueId}/seasons`, fetcher);
  const [selectedSeason, setSelectedSeason] = useState<number | null>(null);
  
  useEffect(() => {
    if (seasons?.length > 0 && !selectedSeason) {
      setSelectedSeason(seasons[0]); // Most recent season
    }
  }, [seasons, selectedSeason]);
  
  return (
    <Box>
      <Typography variant="subtitle1" gutterBottom>
        Season
      </Typography>
      <ToggleButtonGroup
        value={selectedSeason}
        exclusive
        onChange={(_, value) => setSelectedSeason(value)}
      >
        {seasons?.map((season) => (
          <ToggleButton key={season} value={season}>
            {season}
          </ToggleButton>
        ))}
      </ToggleButtonGroup>
    </Box>
  );
}
```

### Analytics Dashboard

```typescript
export function AnalyticsDashboard({ leagueId, season }: { leagueId: string; season: number }) {
  const { data: analytics } = useSWR(
    `/api/analytics/league/${leagueId}?season=${season}`,
    fetcher
  );
  
  return (
    <Box>
      <Typography variant="h5" gutterBottom>
        League Analytics
      </Typography>
      
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <TeamStandingsChart data={analytics?.standings} />
        </Grid>
        <Grid item xs={12} md={6}>
          <WeeklyPerformanceChart data={analytics?.weeklyPerformance} />
        </Grid>
        <Grid item xs={12}>
          <PlayerPerformanceTable data={analytics?.topPlayers} />
        </Grid>
      </Grid>
    </Box>
  );
}
```

## Security Considerations

### OAuth Security
- Use PKCE flow for enhanced security
- Store tokens encrypted in database
- Implement token refresh logic
- Validate state parameter to prevent CSRF
- Use HTTPS for all OAuth endpoints

### Data Security
- Row Level Security (RLS) policies ensure users only access their data
- Encrypt sensitive OAuth tokens
- Implement rate limiting on API endpoints
- Validate all input data from Yahoo API

### Privacy
- Only request read-only permissions from Yahoo
- Store minimal user data necessary for functionality
- Implement data retention policies
- Provide user control over data deletion

## Performance Optimization

### Data Caching
- Cache league data for 1 hour
- Cache team rosters for 15 minutes during game days
- Use SWR for frontend data fetching with revalidation
- Implement background sync for fresh data

### API Optimization
- Batch API calls where possible
- Implement pagination for large datasets
- Use database indexes for common queries
- Implement connection pooling

## Error Handling

### OAuth Errors
```typescript
export class YahooOAuthError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number
  ) {
    super(message);
    this.name = 'YahooOAuthError';
  }
}

export function handleOAuthError(error: any): YahooOAuthError {
  if (error.status === 401) {
    return new YahooOAuthError('Token expired', 'TOKEN_EXPIRED', 401);
  }
  if (error.status === 403) {
    return new YahooOAuthError('Insufficient permissions', 'INSUFFICIENT_PERMISSIONS', 403);
  }
  return new YahooOAuthError('OAuth error occurred', 'OAUTH_ERROR', error.status || 500);
}
```

### Data Sync Errors
- Implement retry logic for failed API calls
- Log sync errors for debugging
- Provide user feedback for sync failures
- Graceful degradation when data is unavailable

## Testing Strategy

### Unit Tests
- OAuth flow components
- Data transformation utilities
- API service methods
- Database operations

### Integration Tests
- OAuth callback handling
- Data synchronization flows
- API endpoint responses
- Database schema validation

### E2E Tests
- Complete OAuth flow
- League selection and switching
- Data visualization rendering
- Error handling scenarios

## Deployment Considerations

### Environment Variables
```bash
# Yahoo OAuth
YAHOO_CLIENT_ID=your_client_id
YAHOO_CLIENT_SECRET=your_client_secret
YAHOO_REDIRECT_URI=https://your-app.com/api/yahoo/auth/callback

# App Configuration
APP_URL=https://your-app.com
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_key
```

### Monitoring
- Track OAuth success/failure rates
- Monitor data sync performance
- Alert on API rate limit approaching
- Log user interaction patterns

## Implementation Timeline

### Phase 1: OAuth Foundation (Week 1-2)
- Set up Yahoo OAuth application
- Implement OAuth flow with PKCE
- Create database schema
- Basic user authentication integration

### Phase 2: Data Synchronization (Week 3-4)
- Implement league data sync
- Create team and player data models
- Build data transformation utilities
- Add background sync capabilities

### Phase 3: Frontend Components (Week 5-6)
- League selector component
- Season selector component
- Basic league dashboard
- Data visualization components

### Phase 4: Analytics & Polish (Week 7-8)
- Advanced analytics features
- Performance optimization
- Error handling improvements
- User experience refinements

## Conclusion

This architecture provides a robust foundation for integrating Yahoo Fantasy Sports API into the Fanalyzr application. The OAuth implementation ensures secure access to user data, while the comprehensive database schema supports multiple leagues and seasons. The modular component architecture allows for easy extension and maintenance.

The implementation follows security best practices, includes comprehensive error handling, and provides a scalable foundation for future enhancements. The phased approach allows for iterative development and testing throughout the implementation process.
