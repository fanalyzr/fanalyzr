# Enhanced Yahoo Fantasy Sports Integration Architecture

## Executive Summary

This document outlines a comprehensive architecture for integrating Yahoo Fantasy Sports API with OAuth authentication into the Fanalyzr application. The integration enables users to sync multiple fantasy football leagues, toggle between leagues and seasons, and generate advanced visualizations and analytics based on the synced data.

### Key Enhancements
- Complete data capture including player stats, transactions, and draft history
- Robust rate limiting and error recovery mechanisms
- Real-time updates during game days
- Advanced caching and performance optimization
- Progressive data loading for improved UX
- Comprehensive analytics pre-computation

## High Level Architecture

### System Overview
```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│                 │     │                  │     │                 │
│  React Frontend │────▶│  Vercel Edge Fn  │────▶│  Yahoo Fantasy  │
│   (TypeScript)  │     │   (API Routes)   │     │      API        │
│                 │     │                  │     │                 │
└────────┬────────┘     └────────┬─────────┘     └─────────────────┘
         │                       │
         │                       │
         ▼                       ▼
┌─────────────────┐     ┌──────────────────┐
│                 │     │                  │
│    Supabase     │────▶│  Redis Cache     │
│   (Database)    │     │  (Performance)   │
│                 │     │                  │
└─────────────────┘     └──────────────────┘
```

### Technical Stack
| Category | Technology | Version | Purpose | Rationale |
|----------|------------|---------|---------|-----------|
| Frontend Framework | React | 18+ | UI Framework | Existing codebase |
| UI Library | Material-UI | 7.x | Component Library | Consistent design system |
| State Management | Zustand + SWR | Latest | Global & server state | Lightweight, powerful |
| Backend | Supabase | Latest | Database, Auth, Realtime | Existing infrastructure |
| Edge Functions | Vercel | Latest | API routes, OAuth handler | Serverless scalability |
| Cache Layer | Redis/Upstash | Latest | Performance optimization | Low latency, TTL support |
| API Protocol | REST | - | Yahoo API Integration | Yahoo requirement |
| OAuth | OAuth 2.0 + PKCE | - | Secure authentication | Industry standard |
| Data Validation | Zod | Latest | Runtime validation | Type-safe validation |
| Analytics | MUI X Charts | 8.x | Data visualization | MUI consistency |
| Rate Limiting | p-queue | Latest | API rate management | Prevents 429 errors |

## Comprehensive Data Models

### Core Entities

#### User Profile (Extended)
```typescript
interface UserProfile {
  id: string;                    // UUID - auth.users reference
  email: string;
  yahoo_guid?: string;           // Yahoo unique identifier
  yahoo_access_token?: string;   // Encrypted
  yahoo_refresh_token?: string;  // Encrypted
  token_expires_at?: Date;
  sync_preferences: {
    auto_sync: boolean;
    sync_frequency: 'manual' | 'hourly' | 'daily';
    last_sync_at: Date;
  }

## API Specification

### Yahoo Fantasy Sports API Integration

```typescript
// src/lib/yahoo/yahoo-api-client.ts
export class YahooAPIClient {
  private baseUrl = 'https://fantasysports.yahooapis.com/fantasy/v2';
  private rateLimiter: YahooRateLimiter;
  
  constructor() {
    this.rateLimiter = new YahooRateLimiter();
  }
  
  // Core API methods with automatic token refresh
  private async makeRequest<T>(
    endpoint: string,
    userId: string,
    options: RequestInit = {}
  ): Promise<T> {
    const tokens = await this.getValidTokens(userId);
    
    return this.rateLimiter.executeRequest(async () => {
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        ...options,
        headers: {
          'Authorization': `Bearer ${tokens.access_token}`,
          'Accept': 'application/json',
          ...options.headers
        }
      });
      
      if (response.status === 401) {
        // Token expired, refresh and retry
        const newTokens = await this.refreshToken(userId);
        return this.makeRequest<T>(endpoint, userId, options);
      }
      
      if (!response.ok) {
        throw new YahooAPIError(response.status, await response.text());
      }
      
      return response.json();
    });
  }
  
  // League endpoints
  async getUserLeagues(userId: string): Promise<League[]> {
    return this.makeRequest('/users;use_login=1/games;game_keys=nfl/leagues', userId);
  }
  
  async getLeague(userId: string, leagueKey: string): Promise<LeagueDetail> {
    return this.makeRequest(`/league/${leagueKey}`, userId);
  }
  
  async getLeagueSettings(userId: string, leagueKey: string): Promise<LeagueSettings> {
    return this.makeRequest(`/league/${leagueKey}/settings`, userId);
  }
  
  // Team endpoints
  async getLeagueTeams(userId: string, leagueKey: string): Promise<Team[]> {
    return this.makeRequest(`/league/${leagueKey}/teams`, userId);
  }
  
  async getTeamRoster(userId: string, teamKey: string, week?: number): Promise<Roster> {
    const weekParam = week ? `;week=${week}` : '';
    return this.makeRequest(`/team/${teamKey}/roster${weekParam}`, userId);
  }
  
  // Player endpoints  
  async getPlayer(userId: string, playerKey: string): Promise<Player> {
    return this.makeRequest(`/player/${playerKey}`, userId);
  }
  
  async getPlayerStats(userId: string, playerKey: string, week?: number): Promise<PlayerStats> {
    const weekParam = week ? `;week=${week}` : '';
    return this.makeRequest(`/player/${playerKey}/stats${weekParam}`, userId);
  }
  
  // Game/Matchup endpoints
  async getScoreboard(userId: string, leagueKey: string, week?: number): Promise<Scoreboard> {
    const weekParam = week ? `;week=${week}` : '';
    return this.makeRequest(`/league/${leagueKey}/scoreboard${weekParam}`, userId);
  }
  
  // Transaction endpoints
  async getTransactions(userId: string, leagueKey: string): Promise<Transaction[]> {
    return this.makeRequest(`/league/${leagueKey}/transactions`, userId);
  }
  
  // Draft endpoints
  async getDraftResults(userId: string, leagueKey: string): Promise<DraftResult[]> {
    return this.makeRequest(`/league/${leagueKey}/draftresults`, userId);
  }
  
  // Batch operations for efficiency
  async batchRequest(userId: string, requests: BatchRequest[]): Promise<any[]> {
    const batchUrl = this.buildBatchUrl(requests);
    return this.makeRequest(batchUrl, userId);
  }
  
  private buildBatchUrl(requests: BatchRequest[]): string {
    // Yahoo supports multi-resource requests
    // Example: /league/nfl.l.12345,nfl.l.67890/teams
    const resources = requests.map(r => r.resource).join(',');
    const collection = requests[0].collection;
    return `/${resources}/${collection}`;
  }
}
```

### Internal API Routes

```typescript
// src/app/api/yahoo/auth/initiate/route.ts
export async function POST(request: Request) {
  const session = await getServerSession();
  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  
  const oauth = new YahooOAuthHandler();
  const authUrl = await oauth.initiateAuth(session.user.id);
  
  return NextResponse.json({ authUrl });
}

// src/app/api/yahoo/auth/callback/route.ts
export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const code = searchParams.get('code');
  const state = searchParams.get('state');
  const error = searchParams.get('error');
  
  if (error) {
    return NextResponse.redirect(`/fantasy/auth-error?error=${error}`);
  }
  
  if (!code || !state) {
    return NextResponse.json({ error: 'Missing parameters' }, { status: 400 });
  }
  
  try {
    const oauth = new YahooOAuthHandler();
    await oauth.handleCallback(code, state);
    
    return NextResponse.redirect('/fantasy/leagues?auth=success');
  } catch (error) {
    console.error('OAuth callback error:', error);
    return NextResponse.redirect('/fantasy/auth-error');
  }
}

// src/app/api/leagues/sync/route.ts
export async function POST(request: Request) {
  const session = await getServerSession();
  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  
  const { leagueKey, progressive = true } = await request.json();
  
  const sync = new FantasyDataSync();
  
  if (progressive) {
    // Start progressive sync (returns immediately)
    sync.performProgressiveSync(session.user.id, leagueKey);
    
    return NextResponse.json({ 
      status: 'started',
      message: 'Progressive sync initiated'
    });
  } else {
    // Full sync (waits for completion)
    const result = await sync.syncLeague(session.user.id, leagueKey);
    return NextResponse.json(result);
  }
}

// src/app/api/leagues/[id]/live/route.ts
export async function GET(request: Request, { params }: { params: { id: string } }) {
  const session = await getServerSession();
  if (!session?.user) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }
  
  // Set up SSE for live updates
  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    async start(controller) {
      // Subscribe to Supabase real-time
      const channel = supabase
        .channel(`league:${params.id}`)
        .on('postgres_changes',
          {
            event: '*',
            schema: 'public',
            table: 'games',
            filter: `league_id=eq.${params.id}`
          },
          (payload) => {
            const data = `data: ${JSON.stringify(payload)}\n\n`;
            controller.enqueue(encoder.encode(data));
          }
        )
        .subscribe();
      
      // Clean up on disconnect
      request.signal.addEventListener('abort', () => {
        supabase.removeChannel(channel);
        controller.close();
      });
    }
  });
  
  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive'
    }
  });
}
```

## Frontend Implementation

### State Management

```typescript
// src/store/fantasy-store.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface FantasyState {
  // Current selections
  selectedLeague: string | null;
  selectedSeason: number | null;
  selectedWeek: number | null;
  
  // Data
  leagues: League[];
  currentLeagueData: LeagueDetail | null;
  
  // Actions
  setLeague: (leagueId: string) => Promise<void>;
  setSeason: (season: number) => void;
  setWeek: (week: number) => void;
  syncLeague: (leagueId: string) => Promise<void>;
  refreshCurrentWeek: () => Promise<void>;
}

export const useFantasyStore = create<FantasyState>()(
  persist(
    (set, get) => ({
      selectedLeague: null,
      selectedSeason: null,
      selectedWeek: null,
      leagues: [],
      currentLeagueData: null,
      
      setLeague: async (leagueId: string) => {
        set({ selectedLeague: leagueId });
        
        // Load league data
        const response = await fetch(`/api/leagues/${leagueId}`);
        const data = await response.json();
        
        set({ 
          currentLeagueData: data,
          selectedSeason: data.season,
          selectedWeek: data.current_week
        });
      },
      
      setSeason: (season: number) => {
        set({ selectedSeason: season });
      },
      
      setWeek: (week: number) => {
        set({ selectedWeek: week });
      },
      
      syncLeague: async (leagueId: string) => {
        const response = await fetch('/api/leagues/sync', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ leagueKey: leagueId, progressive: true })
        });
        
        if (response.ok) {
          // Start listening for sync updates
          const eventSource = new EventSource(`/api/leagues/${leagueId}/sync-status`);
          
          eventSource.onmessage = (event) => {
            const data = JSON.parse(event.data);
            if (data.status === 'complete') {
              eventSource.close();
              get().setLeague(leagueId);
            }
          };
        }
      },
      
      refreshCurrentWeek: async () => {
        const { selectedLeague, selectedWeek } = get();
        if (!selectedLeague || !selectedWeek) return;
        
        const response = await fetch(
          `/api/leagues/${selectedLeague}/week/${selectedWeek}/refresh`,
          { method: 'POST' }
        );
        
        if (response.ok) {
          const data = await response.json();
          set(state => ({
            currentLeagueData: {
              ...state.currentLeagueData!,
              current_week_data: data
            }
          }));
        }
      }
    }),
    {
      name: 'fantasy-storage',
      partialize: (state) => ({
        selectedLeague: state.selectedLeague,
        selectedSeason: state.selectedSeason
      })
    }
  )
);
```

### Component Architecture

```typescript
// src/sections/fantasy/components/LeagueSelector.tsx
import { useFantasyStore } from '@/store/fantasy-store';
import { Card, Grid, Skeleton, Button, Chip } from '@mui/material';
import { Plus, RefreshCw, Check } from 'lucide-react';

export function LeagueSelector() {
  const { leagues, selectedLeague, setLeague, syncLeague } = useFantasyStore();
  const [syncing, setSyncing] = useState<string | null>(null);
  
  const handleSync = async (leagueId: string) => {
    setSyncing(leagueId);
    await syncLeague(leagueId);
    setSyncing(null);
  };
  
  return (
    <Grid container spacing={3}>
      {leagues.map((league) => (
        <Grid item xs={12} sm={6} md={4} key={league.id}>
          <Card
            sx={{
              p: 2,
              cursor: 'pointer',
              border: selectedLeague === league.id ? 2 : 0,
              borderColor: 'primary.main',
              position: 'relative'
            }}
            onClick={() => setLeague(league.id)}
          >
            {selectedLeague === league.id && (
              <Chip
                icon={<Check size={16} />}
                label="Active"
                color="primary"
                size="small"
                sx={{ position: 'absolute', top: 8, right: 8 }}
              />
            )}
            
            <Typography variant="h6">{league.name}</Typography>
            <Typography variant="body2" color="text.secondary">
              {league.season} Season • {league.num_teams} Teams
            </Typography>
            
            <Box sx={{ mt: 2, display: 'flex', gap: 1 }}>
              <Chip
                label={league.league_type}
                size="small"
                variant="outlined"
              />
              <Chip
                label={league.scoring_type}
                size="small"
                variant="outlined"
              />
            </Box>
            
            <Button
              size="small"
              startIcon={syncing === league.id ? <CircularProgress size={16} /> : <RefreshCw size={16} />}
              onClick={(e) => {
                e.stopPropagation();
                handleSync(league.id);
              }}
              disabled={syncing === league.id}
              sx={{ mt: 2 }}
            >
              {syncing === league.id ? 'Syncing...' : 'Sync Data'}
            </Button>
            
            {league.last_synced_at && (
              <Typography variant="caption" display="block" sx={{ mt: 1 }}>
                Last synced: {formatDistanceToNow(new Date(league.last_synced_at))} ago
              </Typography>
            )}
          </Card>
        </Grid>
      ))}
      
      <Grid item xs={12} sm={6} md={4}>
        <Card
          sx={{
            p: 2,
            height: '100%',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            border: '2px dashed',
            borderColor: 'divider',
            cursor: 'pointer',
            '&:hover': {
              borderColor: 'primary.main',
              bgcolor: 'action.hover'
            }
          }}
          onClick={() => router.push('/fantasy/connect')}
        >
          <Box textAlign="center">
            <Plus size={32} />
            <Typography variant="body1" sx={{ mt: 1 }}>
              Add League
            </Typography>
          </Box>
        </Card>
      </Grid>
    </Grid>
  );
}

// src/sections/fantasy/components/WeekSelector.tsx
export function WeekSelector() {
  const { selectedWeek, setWeek, currentLeagueData } = useFantasyStore();
  
  if (!currentLeagueData) return null;
  
  const weeks = Array.from(
    { length: currentLeagueData.current_week },
    (_, i) => i + 1
  );
  
  return (
    <Box sx={{ display: 'flex', gap: 1, overflowX: 'auto', pb: 1 }}>
      {weeks.map((week) => (
        <Chip
          key={week}
          label={`Week ${week}`}
          onClick={() => setWeek(week)}
          color={selectedWeek === week ? 'primary' : 'default'}
          variant={selectedWeek === week ? 'filled' : 'outlined'}
          sx={{ flexShrink: 0 }}
        />
      ))}
    </Box>
  );
}

// src/sections/fantasy/components/LiveScoreboard.tsx
export function LiveScoreboard() {
  const { selectedLeague, selectedWeek } = useFantasyStore();
  const [games, setGames] = useState<Game[]>([]);
  const [isLive, setIsLive] = useState(false);
  
  useEffect(() => {
    if (!selectedLeague) return;
    
    // Initial data fetch
    fetchGames();
    
    // Set up SSE for live updates
    const eventSource = new EventSource(
      `/api/leagues/${selectedLeague}/live`
    );
    
    eventSource.onmessage = (event) => {
      const update = JSON.parse(event.data);
      setGames(prev => updateGameInList(prev, update));
      setIsLive(true);
    };
    
    return () => {
      eventSource.close();
    };
  }, [selectedLeague, selectedWeek]);
  
  return (
    <Box>
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
        <Typography variant="h6">Scoreboard</Typography>
        {isLive && (
          <Chip
            label="LIVE"
            color="error"
            size="small"
            sx={{ ml: 2 }}
            icon={<Box sx={{ 
              width: 8, 
              height: 8, 
              borderRadius: '50%',
              bgcolor: 'error.main',
              animation: 'pulse 2s infinite'
            }} />}
          />
        )}
      </Box>
      
      <Grid container spacing={2}>
        {games.map((game) => (
          <Grid item xs={12} md={6} key={game.id}>
            <GameCard game={game} isLive={!game.is_complete} />
          </Grid>
        ))}
      </Grid>
    </Box>
  );
}
```

### Analytics Dashboard

```typescript
// src/sections/fantasy/analytics/AnalyticsDashboard.tsx
import { LineChart, BarChart, PieChart } from '@mui/x-charts';

export function AnalyticsDashboard() {
  const { selectedLeague, selectedSeason } = useFantasyStore();
  const { data: analytics } = useSWR(
    selectedLeague ? `/api/analytics/league/${selectedLeague}?season=${selectedSeason}` : null,
    fetcher
  );
  
  if (!analytics) return <AnalyticsSkeletonLoader />;
  
  return (
    <Grid container spacing={3}>
      {/* Team Performance Trends */}
      <Grid item xs={12} lg={8}>
        <Card>
          <CardHeader title="Team Performance Trends" />
          <CardContent>
            <LineChart
              width={500}
              height={300}
              series={analytics.teamTrends}
              xAxis={[{ 
                data: analytics.weeks,
                label: 'Week'
              }]}
              yAxis={[{
                label: 'Points'
              }]}
            />
          </CardContent>
        </Card>
      </Grid>
      
      {/* Win/Loss Distribution */}
      <Grid item xs={12} lg={4}>
        <Card>
          <CardHeader title="Win/Loss Distribution" />
          <CardContent>
            <PieChart
              series={[{
                data: analytics.winLossData,
                highlightScope: { faded: 'global', highlighted: 'item' }
              }]}
              width={400}
              height={200}
            />
          </CardContent>
        </Card>
      </Grid>
      
      {/* Top Performers */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardHeader title="Top Performers" />
          <CardContent>
            <TopPerformersTable data={analytics.topPerformers} />
          </CardContent>
        </Card>
      </Grid>
      
      {/* Position Analysis */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardHeader title="Points by Position" />
          <CardContent>
            <BarChart
              width={500}
              height={300}
              series={analytics.positionData}
              xAxis={[{ 
                data: ['QB', 'RB', 'WR', 'TE', 'K', 'DEF'],
                scaleType: 'band'
              }]}
            />
          </CardContent>
        </Card>
      </Grid>
      
      {/* Trade Analysis */}
      <Grid item xs={12}>
        <Card>
          <CardHeader title="Trade Impact Analysis" />
          <CardContent>
            <TradeImpactChart data={analytics.tradeImpact} />
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
}
```

## Security & Privacy

### Security Measures

1. **OAuth Token Security**
   - Tokens encrypted at rest using AES-256
   - Automatic token refresh before expiration
   - Secure session storage for PKCE verifier

2. **API Security**
   - Rate limiting to prevent abuse
   - Request validation with Zod schemas
   - CORS configuration for API routes

3. **Database Security**
   - Row Level Security (RLS) policies
   - Encrypted sensitive columns
   - Prepared statements to prevent SQL injection

4. **Privacy Considerations**
   - Minimal data collection
   - User-controlled data deletion
   - No sharing with third parties
   - Clear data retention policies

## Performance Optimization

### Caching Strategy

1. **Multi-tier Caching**
   - Redis for hot data (scores, standings)
   - Database materialized views for analytics
   - Client-side SWR caching

2. **Smart TTL Management**
   - Game-day aware cache expiration
   - Progressive cache invalidation
   - Stale-while-revalidate patterns

3. **Data Loading Optimization**
   - Progressive data loading by priority
   - Batch API requests where possible
   - Lazy loading for historical data
   - Prefetching for predictable navigation

### Database Optimization

```sql
-- Composite indexes for common queries
CREATE INDEX idx_games_league_season_week ON games(league_id, season, week);
CREATE INDEX idx_player_stats_lookup ON player_stats(player_id, league_id, season, week);
CREATE INDEX idx_rosters_team_season ON rosters(team_id, season);
CREATE INDEX idx_transactions_date ON transactions(league_id, transaction_date DESC);

-- Partitioning for large tables (if needed)
CREATE TABLE player_stats_2024 PARTITION OF player_stats
FOR VALUES FROM (2024) TO (2025);

CREATE TABLE player_stats_2025 PARTITION OF player_stats
FOR VALUES FROM (2025) TO (2026);

-- Query optimization with CTEs
CREATE OR REPLACE FUNCTION get_team_analytics(
  p_team_id UUID,
  p_season INTEGER
) RETURNS TABLE (
  week INTEGER,
  points DECIMAL,
  opponent_points DECIMAL,
  cumulative_wins INTEGER,
  ranking INTEGER
) AS $
WITH team_games AS (
  SELECT 
    g.week,
    CASE 
      WHEN g.home_team_id = p_team_id THEN g.home_score
      ELSE g.away_score
    END as points,
    CASE 
      WHEN g.home_team_id = p_team_id THEN g.away_score
      ELSE g.home_score
    END as opponent_points,
    CASE 
      WHEN g.winner_id = p_team_id THEN 1
      ELSE 0
    END as win
  FROM games g
  WHERE (g.home_team_id = p_team_id OR g.away_team_id = p_team_id)
    AND g.season = p_season
    AND g.is_complete = true
)
SELECT 
  week,
  points,
  opponent_points,
  SUM(win) OVER (ORDER BY week) as cumulative_wins,
  RANK() OVER (PARTITION BY week ORDER BY points DESC) as ranking
FROM team_games
ORDER BY week;
$ LANGUAGE SQL STABLE;
```

## Error Handling & Recovery

### Comprehensive Error Handling

```typescript
// src/lib/yahoo/error-handler.ts
export enum YahooErrorCode {
  TOKEN_EXPIRED = 'TOKEN_EXPIRED',
  RATE_LIMITED = 'RATE_LIMITED',
  INVALID_LEAGUE = 'INVALID_LEAGUE',
  NETWORK_ERROR = 'NETWORK_ERROR',
  SYNC_FAILED = 'SYNC_FAILED',
  PARTIAL_SYNC = 'PARTIAL_SYNC'
}

export class YahooErrorHandler {
  private readonly maxRetries = 3;
  private readonly retryDelays = [1000, 3000, 10000];
  
  async handleError(error: any, context: ErrorContext): Promise<ErrorResolution> {
    const errorType = this.classifyError(error);
    
    switch (errorType) {
      case YahooErrorCode.TOKEN_EXPIRED:
        return this.handleTokenExpired(context);
        
      case YahooErrorCode.RATE_LIMITED:
        return this.handleRateLimit(error, context);
        
      case YahooErrorCode.NETWORK_ERROR:
        return this.handleNetworkError(error, context);
        
      case YahooErrorCode.SYNC_FAILED:
        return this.handleSyncFailure(error, context);
        
      default:
        return this.handleUnknownError(error, context);
    }
  }
  
  private async handleTokenExpired(context: ErrorContext): Promise<ErrorResolution> {
    try {
      // Attempt to refresh token
      const oauth = new YahooOAuthHandler();
      await oauth.refreshToken(context.userId);
      
      return {
        resolved: true,
        action: 'retry',
        message: 'Token refreshed successfully'
      };
    } catch (refreshError) {
      return {
        resolved: false,
        action: 'reauth',
        message: 'Please reconnect your Yahoo account'
      };
    }
  }
  
  private async handleRateLimit(error: any, context: ErrorContext): Promise<ErrorResolution> {
    const retryAfter = error.headers?.['retry-after'] || 3600;
    
    // Queue for later execution
    await this.queueForRetry(context, retryAfter * 1000);
    
    return {
      resolved: true,
      action: 'queued',
      message: `Request queued. Will retry in ${retryAfter} seconds.`,
      retryAfter
    };
  }
  
  private async handleSyncFailure(error: any, context: ErrorContext): Promise<ErrorResolution> {
    // Check if partial sync is possible
    const checkpoint = await this.getCheckpoint(context.leagueId);
    
    if (checkpoint && checkpoint.completed_steps.length > 0) {
      return {
        resolved: true,
        action: 'partial',
        message: 'Partial sync completed. Some data may be missing.',
        completedSteps: checkpoint.completed_steps
      };
    }
    
    return {
      resolved: false,
      action: 'manual',
      message: 'Sync failed. Please try again later.'
    };
  }
  
  private async queueForRetry(context: ErrorContext, delay: number): Promise<void> {
    // Store in retry queue
    await supabase
      .from('retry_queue')
      .insert({
        user_id: context.userId,
        league_id: context.leagueId,
        action: context.action,
        retry_at: new Date(Date.now() + delay),
        attempts: context.attemptNumber || 1
      });
  }
}

// Retry queue processor
export class RetryQueueProcessor {
  private processing = false;
  
  async start(): Promise<void> {
    if (this.processing) return;
    
    this.processing = true;
    
    while (this.processing) {
      await this.processQueue();
      await new Promise(resolve => setTimeout(resolve, 30000)); // Check every 30 seconds
    }
  }
  
  private async processQueue(): Promise<void> {
    const { data: items } = await supabase
      .from('retry_queue')
      .select('*')
      .lte('retry_at', new Date().toISOString())
      .limit(10);
      
    if (!items || items.length === 0) return;
    
    for (const item of items) {
      try {
        await this.processItem(item);
        
        // Remove from queue on success
        await supabase
          .from('retry_queue')
          .delete()
          .eq('id', item.id);
      } catch (error) {
        // Update attempts and retry time
        await supabase
          .from('retry_queue')
          .update({
            attempts: item.attempts + 1,
            retry_at: new Date(Date.now() + Math.pow(2, item.attempts) * 60000)
          })
          .eq('id', item.id);
      }
    }
  }
  
  private async processItem(item: RetryQueueItem): Promise<void> {
    const sync = new FantasyDataSync();
    
    switch (item.action) {
      case 'sync_league':
        await sync.syncLeague(item.user_id, item.league_id);
        break;
      case 'sync_week':
        await sync.syncWeekData(item.user_id, item.league_id, item.metadata.week);
        break;
      // Add more actions as needed
    }
  }
}
```

## Real-time Updates

### WebSocket/SSE Implementation

```typescript
// src/lib/realtime/live-updates.ts
export class LiveUpdatesManager {
  private subscriptions: Map<string, RealtimeChannel> = new Map();
  
  subscribeToLeague(leagueId: string, callbacks: {
    onScoreUpdate?: (data: ScoreUpdate) => void;
    onGameComplete?: (data: GameComplete) => void;
    onRosterChange?: (data: RosterChange) => void;
  }): () => void {
    const channelKey = `league:${leagueId}`;
    
    if (this.subscriptions.has(channelKey)) {
      return () => this.unsubscribe(channelKey);
    }
    
    const channel = supabase
      .channel(channelKey)
      .on('postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'games',
          filter: `league_id=eq.${leagueId}`
        },
        (payload) => {
          if (callbacks.onScoreUpdate) {
            callbacks.onScoreUpdate(payload.new as ScoreUpdate);
          }
          
          if (payload.new.is_complete && !payload.old.is_complete) {
            if (callbacks.onGameComplete) {
              callbacks.onGameComplete(payload.new as GameComplete);
            }
          }
        }
      )
      .on('postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'rosters',
          filter: `team_id=in.(${this.getTeamIds(leagueId)})`
        },
        (payload) => {
          if (callbacks.onRosterChange) {
            callbacks.onRosterChange(payload as RosterChange);
          }
        }
      )
      .subscribe();
    
    this.subscriptions.set(channelKey, channel);
    
    return () => this.unsubscribe(channelKey);
  }
  
  private unsubscribe(channelKey: string): void {
    const channel = this.subscriptions.get(channelKey);
    if (channel) {
      supabase.removeChannel(channel);
      this.subscriptions.delete(channelKey);
    }
  }
  
  // Auto-refresh during game times
  startGameDayUpdates(leagueId: string): void {
    const now = new Date();
    const day = now.getDay();
    
    // Check if it's game day (Thu, Sun, Mon)
    if (![0, 1, 4].includes(day)) return;
    
    // Set up periodic refresh
    const intervalId = setInterval(async () => {
      const sync = new FantasyDataSync();
      await sync.refreshLiveScores(leagueId);
    }, 60000); // Every minute
    
    // Store interval for cleanup
    this.intervals.set(leagueId, intervalId);
    
    // Auto-stop after games end (typically by 11:30 PM ET)
    const stopTime = new Date();
    stopTime.setHours(23, 30, 0, 0);
    
    setTimeout(() => {
      clearInterval(intervalId);
      this.intervals.delete(leagueId);
    }, stopTime.getTime() - now.getTime());
  }
}
```

## Testing Strategy

### Unit Tests

```typescript
// src/__tests__/yahoo/oauth-handler.test.ts
describe('YahooOAuthHandler', () => {
  let handler: YahooOAuthHandler;
  
  beforeEach(() => {
    handler = new YahooOAuthHandler();
  });
  
  describe('PKCE Generation', () => {
    it('should generate valid PKCE challenge', async () => {
      const authUrl = await handler.initiateAuth('user-123');
      const url = new URL(authUrl);
      
      expect(url.searchParams.get('code_challenge')).toBeTruthy();
      expect(url.searchParams.get('code_challenge_method')).toBe('S256');
    });
  });
  
  describe('Token Refresh', () => {
    it('should refresh expired token', async () => {
      // Mock expired token
      mockSupabase.from.mockReturnValue({
        select: () => ({
          single: () => ({
            data: {
              yahoo_refresh_token: 'refresh-token',
              token_expires_at: new Date(Date.now() - 1000)
            }
          })
        })
      });
      
      const tokens = await handler.refreshToken('user-123');
      expect(tokens.access_token).toBeTruthy();
    });
  });
});

// src/__tests__/yahoo/rate-limiter.test.ts
describe('YahooRateLimiter', () => {
  let limiter: YahooRateLimiter;
  
  beforeEach(() => {
    limiter = new YahooRateLimiter();
  });
  
  it('should queue requests when approaching limit', async () => {
    const requests = Array(200).fill(null).map((_, i) => 
      () => Promise.resolve(i)
    );
    
    const start = Date.now();
    const results = await Promise.all(
      requests.map(req => limiter.executeRequest(req))
    );
    
    expect(results).toHaveLength(200);
    expect(Date.now() - start).toBeGreaterThan(0); // Some were queued
  });
  
  it('should handle 429 responses with retry', async () => {
    const mockRequest = jest.fn()
      .mockRejectedValueOnce({ status: 429, headers: { 'retry-after': '1' } })
      .mockResolvedValueOnce({ data: 'success' });
    
    const result = await limiter.executeRequest(mockRequest);
    
    expect(result.data).toBe('success');
    expect(mockRequest).toHaveBeenCalledTimes(2);
  });
});
```

### Integration Tests

```typescript
// src/__tests__/integration/sync-flow.test.ts
describe('Fantasy Data Sync Flow', () => {
  it('should complete progressive sync', async () => {
    const userId = 'test-user';
    const leagueKey = 'nfl.l.12345';
    
    const sync = new FantasyDataSync();
    const result = await sync.performProgressiveSync(userId, leagueKey);
    
    // Verify priority 1 data is available immediately
    const league = await getLeague(leagueKey);
    expect(league).toBeTruthy();
    expect(league.teams).toBeTruthy();
    
    // Wait for background sync
    await waitFor(() => {
      const stats = getPlayerStats(leagueKey);
      return stats.length > 0;
    }, { timeout: 10000 });
  });
  
  it('should recover from partial sync failure', async () => {
    const sync = new FantasyDataSync();
    
    // Mock failure at transactions step
    jest.spyOn(sync, 'syncTransactions').mockRejectedValueOnce(new Error('API Error'));
    
    const result = await sync.syncLeague('user', 'league', { continueOnError: true });
    
    expect(result.results).toContainEqual(
      expect.objectContaining({
        step: 'transactions',
        status: 'failed'
      })
    );
    
    // Other steps should complete
    expect(result.results.filter(r => r.status === 'success').length).toBeGreaterThan(0);
  });
});
```

## Deployment Configuration

### Environment Variables

```bash
# .env.local
# Yahoo OAuth
YAHOO_CLIENT_ID=your_yahoo_client_id
YAHOO_CLIENT_SECRET=your_yahoo_client_secret

# Supabase
NEXT_PUBLIC_SUPABASE_URL=your_supabase_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_KEY=your_service_key

# Redis Cache
REDIS_URL=your_redis_url

# Encryption
ENCRYPTION_KEY=your_32_char_encryption_key

# App Configuration
NEXT_PUBLIC_APP_URL=https://your-app.com
NODE_ENV=production

# Feature Flags
ENABLE_LIVE_UPDATES=true
ENABLE_PROGRESSIVE_SYNC=true
ENABLE_ANALYTICS_CACHE=true
```

### Docker Configuration

```dockerfile
# Dockerfile
FROM node:18-alpine AS base

# Install dependencies
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
RUN \
  if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# Build application
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED 1

RUN npm run build

# Production image
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

CMD ["node", "server.js"]
```

### Monitoring & Observability

```typescript
// src/lib/monitoring/metrics.ts
import { metrics } from '@opentelemetry/api-metrics';

export class FantasyMetrics {
  private meter = metrics.getMeter('fantasy-sports');
  
  // OAuth metrics
  private oauthSuccessCounter = this.meter.createCounter('oauth_success_total');
  private oauthFailureCounter = this.meter.createCounter('oauth_failure_total');
  private tokenRefreshCounter = this.meter.createCounter('token_refresh_total');
  
  // Sync metrics
  private syncDurationHistogram = this.meter.createHistogram('sync_duration_seconds');
  private syncStepCounter = this.meter.createCounter('sync_step_total');
  private syncErrorCounter = this.meter.createCounter('sync_error_total');
  
  // API metrics
  private apiRequestCounter = this.meter.createCounter('yahoo_api_requests_total');
  private apiLatencyHistogram = this.meter.createHistogram('yahoo_api_latency_ms');
  private rateLimitCounter = this.meter.createCounter('rate_limit_hits_total');
  
  recordOAuthSuccess(provider: string = 'yahoo'): void {
    this.oauthSuccessCounter.add(1, { provider });
  }
  
  recordOAuthFailure(provider: string = 'yahoo', reason: string): void {
    this.oauthFailureCounter.add(1, { provider, reason });
  }
  
  recordSyncDuration(leagueId: string, duration: number): void {
    this.syncDurationHistogram.record(duration, { league_id: leagueId });
  }
  
  recordApiRequest(endpoint: string, status: number, duration: number): void {
    this.apiRequestCounter.add(1, { endpoint, status });
    this.apiLatencyHistogram.record(duration, { endpoint });
    
    if (status === 429) {
      this.rateLimitCounter.add(1, { endpoint });
    }
  }
}

// Logging configuration
import winston from 'winston';

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  defaultMeta: { service: 'fantasy-sports' },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});
```

## Implementation Timeline

### Phase 1: Foundation (Week 1-2)
- ✅ Database schema creation and migrations
- ✅ Yahoo OAuth app registration and configuration
- ✅ OAuth flow implementation with PKCE
- ✅ Basic token management and encryption
- ✅ Error handling framework

### Phase 2: Core Sync (Week 3-4)
- ✅ League and team data synchronization
- ✅ Player and roster sync
- ✅ Game/matchup data sync
- ✅ Rate limiting implementation
- ✅ Checkpoint and recovery system

### Phase 3: Frontend Components (Week 5-6)
- ✅ League selector component
- ✅ Season and week selectors
- ✅ Basic dashboard layout
- ✅ Live scoreboard component
- ✅ Team standings display

### Phase 4: Advanced Features (Week 7-8)
- ✅ Transaction history sync
- ✅ Draft results import
- ✅ Player statistics tracking
- ✅ Progressive sync implementation
- ✅ Real-time updates via WebSocket

### Phase 5: Analytics & Visualization (Week 9-10)
- ✅ Performance trends charts
- ✅ Position analysis
- ✅ Trade impact analysis
- ✅ Materialized views for analytics
- ✅ Advanced filtering and sorting

### Phase 6: Optimization & Polish (Week 11-12)
- ✅ Caching layer implementation
- ✅ Performance optimization
- ✅ Comprehensive error handling
- ✅ User experience refinements
- ✅ Documentation and testing

## Conclusion

This enhanced architecture provides a robust, scalable foundation for Yahoo Fantasy Sports integration. Key improvements include:

1. **Complete Data Capture**: Comprehensive schema covering all fantasy data including transactions, drafts, and detailed player statistics
2. **Robust Error Handling**: Sophisticated error recovery with checkpointing and retry mechanisms
3. **Performance Optimization**: Multi-tier caching, progressive loading, and database optimization
4. **Real-time Updates**: WebSocket integration for live scoring updates
5. **Advanced Analytics**: Pre-computed metrics and materialized views for instant insights
6. **Security**: Enhanced OAuth implementation with PKCE, encrypted tokens, and RLS policies

The phased implementation approach ensures steady progress while maintaining system stability. The architecture is designed to scale with user growth and can handle the Yahoo API's rate limits effectively through intelligent queuing and caching strategies.
   ;
  created_at: Date;
  updated_at: Date;
}
```

#### League
```typescript
interface League {
  id: string;                    // UUID
  user_id: string;              // Owner reference
  yahoo_league_key: string;     // Yahoo identifier
  yahoo_game_key: string;       // Yahoo game reference
  name: string;
  season: number;
  league_type: 'public' | 'private' | 'pro' | 'cash';
  scoring_type: 'head' | 'points' | 'roto';
  draft_type: 'live' | 'auto' | 'offline';
  num_teams: number;
  playoff_start_week: number;
  current_week: number;
  settings: JsonValue;          // Complete league settings
  last_synced_at: Date;
  sync_status: 'pending' | 'syncing' | 'complete' | 'error';
  sync_checkpoint?: SyncCheckpoint;
  created_at: Date;
  updated_at: Date;
}
```

#### Team
```typescript
interface Team {
  id: string;                    // UUID
  league_id: string;
  yahoo_team_key: string;
  yahoo_team_id: number;
  name: string;
  logo_url?: string;
  owner_name: string;
  owner_guid?: string;
  is_current_user: boolean;     // Flags user's own team
  division_id?: number;
  waiver_priority: number;
  faab_balance?: number;         // For FAAB leagues
  moves_made: number;
  trades_made: number;
  // Season stats
  wins: number;
  losses: number;
  ties: number;
  points_for: number;
  points_against: number;
  rank: number;
  playoff_seed?: number;
  created_at: Date;
  updated_at: Date;
}
```

#### Player
```typescript
interface Player {
  id: string;                    // UUID
  yahoo_player_key: string;
  yahoo_player_id: number;
  first_name: string;
  last_name: string;
  full_name: string;
  positions: string[];           // Can be eligible for multiple
  primary_position: string;
  nfl_team: string;             // Team abbreviation
  nfl_team_full: string;        // Full team name
  uniform_number?: number;
  status: 'active' | 'injured' | 'out' | 'questionable' | 'doubtful';
  injury_note?: string;
  bye_week?: number;
  image_url?: string;
  created_at: Date;
  updated_at: Date;
}
```

#### Player Stats
```typescript
interface PlayerStats {
  id: string;                    // UUID
  player_id: string;
  league_id: string;            // Stats can vary by league scoring
  week: number;
  season: number;
  points_scored: number;
  projected_points: number;
  game_played: boolean;
  stats: {
    passing?: { yards: number; tds: number; ints: number; attempts: number; completions: number; };
    rushing?: { yards: number; tds: number; attempts: number; };
    receiving?: { yards: number; tds: number; receptions: number; targets: number; };
    kicking?: { fg_made: number; fg_attempts: number; xp_made: number; };
    defense?: { sacks: number; ints: number; fumbles: number; tds: number; points_allowed: number; };
  };
  created_at: Date;
}
```

#### Roster
```typescript
interface Roster {
  id: string;                    // UUID
  team_id: string;
  week: number;
  season: number;
  players: Array<{
    player_id: string;
    position: string;           // Position in lineup (QB, RB1, RB2, FLEX, BN)
    selected_position: string;  // Actual player position
    is_starter: boolean;
    points_scored?: number;
  }>;
  total_points: number;
  projected_points: number;
  created_at: Date;
  updated_at: Date;
}
```

#### Game (Matchup)
```typescript
interface Game {
  id: string;                    // UUID
  league_id: string;
  week: number;
  season: number;
  home_team_id: string;
  away_team_id: string;
  home_score: number;
  away_score: number;
  home_projected: number;
  away_projected: number;
  is_playoff: boolean;
  is_consolation: boolean;
  is_complete: boolean;
  winner_id?: string;
  stat_winners: {               // Categories won (for H2H categories)
    home: number;
    away: number;
    ties: number;
  };
  created_at: Date;
  updated_at: Date;
}
```

#### Transaction
```typescript
interface Transaction {
  id: string;                    // UUID
  league_id: string;
  type: 'add' | 'drop' | 'trade' | 'commish';
  status: 'pending' | 'accepted' | 'rejected' | 'executed';
  team_id: string;              // Primary team
  partner_team_id?: string;     // For trades
  players_added: string[];      // Player IDs
  players_dropped: string[];    // Player IDs
  faab_bid?: number;
  waiver_priority?: number;
  transaction_date: Date;
  process_date?: Date;
  notes?: string;
  created_at: Date;
}
```

#### Draft Result
```typescript
interface DraftResult {
  id: string;                    // UUID
  league_id: string;
  team_id: string;
  player_id: string;
  round: number;
  pick: number;
  overall_pick: number;
  keeper_round?: number;        // For keeper leagues
  cost?: number;                // For auction drafts
  created_at: Date;
}
```

## Enhanced Database Schema

```sql
-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Extend user profiles with Yahoo OAuth and preferences
ALTER TABLE public.user_profiles 
ADD COLUMN yahoo_guid TEXT UNIQUE,
ADD COLUMN yahoo_access_token TEXT,
ADD COLUMN yahoo_refresh_token TEXT,
ADD COLUMN token_expires_at TIMESTAMPTZ,
ADD COLUMN sync_preferences JSONB DEFAULT '{"auto_sync": false, "sync_frequency": "manual"}';

-- Create encrypted columns for sensitive data
CREATE OR REPLACE FUNCTION encrypt_token(token TEXT) 
RETURNS TEXT AS $$
BEGIN
  RETURN encode(encrypt(token::bytea, current_setting('app.encryption_key')::bytea, 'aes'), 'base64');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Leagues table with comprehensive settings
CREATE TABLE public.leagues (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  yahoo_league_key TEXT NOT NULL,
  yahoo_game_key TEXT NOT NULL,
  name TEXT NOT NULL,
  season INTEGER NOT NULL,
  league_type TEXT NOT NULL CHECK (league_type IN ('public', 'private', 'pro', 'cash')),
  scoring_type TEXT NOT NULL CHECK (scoring_type IN ('head', 'points', 'roto')),
  draft_type TEXT NOT NULL,
  num_teams INTEGER NOT NULL,
  playoff_start_week INTEGER,
  current_week INTEGER DEFAULT 1,
  settings JSONB DEFAULT '{}',
  last_synced_at TIMESTAMPTZ,
  sync_status TEXT DEFAULT 'pending',
  sync_checkpoint JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(yahoo_league_key, season, user_id)
);

-- Teams table with extended stats
CREATE TABLE public.teams (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  league_id UUID REFERENCES public.leagues(id) ON DELETE CASCADE,
  yahoo_team_key TEXT NOT NULL,
  yahoo_team_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  logo_url TEXT,
  owner_name TEXT NOT NULL,
  owner_guid TEXT,
  is_current_user BOOLEAN DEFAULT FALSE,
  division_id INTEGER,
  waiver_priority INTEGER,
  faab_balance DECIMAL(10,2),
  moves_made INTEGER DEFAULT 0,
  trades_made INTEGER DEFAULT 0,
  wins INTEGER DEFAULT 0,
  losses INTEGER DEFAULT 0,
  ties INTEGER DEFAULT 0,
  points_for DECIMAL(10,2) DEFAULT 0,
  points_against DECIMAL(10,2) DEFAULT 0,
  rank INTEGER,
  playoff_seed INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(yahoo_team_key, league_id)
);

-- Players table with comprehensive info
CREATE TABLE public.players (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  yahoo_player_key TEXT UNIQUE NOT NULL,
  yahoo_player_id INTEGER NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  full_name TEXT NOT NULL,
  positions TEXT[] NOT NULL,
  primary_position TEXT NOT NULL,
  nfl_team TEXT,
  nfl_team_full TEXT,
  uniform_number INTEGER,
  status TEXT DEFAULT 'active',
  injury_note TEXT,
  bye_week INTEGER,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Player stats table for performance tracking
CREATE TABLE public.player_stats (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  player_id UUID REFERENCES public.players(id) ON DELETE CASCADE,
  league_id UUID REFERENCES public.leagues(id) ON DELETE CASCADE,
  week INTEGER NOT NULL,
  season INTEGER NOT NULL,
  points_scored DECIMAL(10,2),
  projected_points DECIMAL(10,2),
  game_played BOOLEAN DEFAULT FALSE,
  stats JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(player_id, league_id, week, season)
);

-- Rosters table with detailed lineup info
CREATE TABLE public.rosters (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  team_id UUID REFERENCES public.teams(id) ON DELETE CASCADE,
  week INTEGER NOT NULL,
  season INTEGER NOT NULL,
  players JSONB NOT NULL DEFAULT '[]',
  total_points DECIMAL(10,2) DEFAULT 0,
  projected_points DECIMAL(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(team_id, week, season)
);

-- Games table for matchups
CREATE TABLE public.games (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  league_id UUID REFERENCES public.leagues(id) ON DELETE CASCADE,
  week INTEGER NOT NULL,
  season INTEGER NOT NULL,
  home_team_id UUID REFERENCES public.teams(id),
  away_team_id UUID REFERENCES public.teams(id),
  home_score DECIMAL(10,2),
  away_score DECIMAL(10,2),
  home_projected DECIMAL(10,2),
  away_projected DECIMAL(10,2),
  is_playoff BOOLEAN DEFAULT FALSE,
  is_consolation BOOLEAN DEFAULT FALSE,
  is_complete BOOLEAN DEFAULT FALSE,
  winner_id UUID REFERENCES public.teams(id),
  stat_winners JSONB DEFAULT '{"home": 0, "away": 0, "ties": 0}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(league_id, week, season, home_team_id, away_team_id)
);

-- Transactions table for tracking moves
CREATE TABLE public.transactions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  league_id UUID REFERENCES public.leagues(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('add', 'drop', 'trade', 'commish')),
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'executed')),
  team_id UUID REFERENCES public.teams(id),
  partner_team_id UUID REFERENCES public.teams(id),
  players_added UUID[] DEFAULT '{}',
  players_dropped UUID[] DEFAULT '{}',
  faab_bid DECIMAL(10,2),
  waiver_priority INTEGER,
  transaction_date TIMESTAMPTZ NOT NULL,
  process_date TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Draft results table
CREATE TABLE public.draft_results (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  league_id UUID REFERENCES public.leagues(id) ON DELETE CASCADE,
  team_id UUID REFERENCES public.teams(id),
  player_id UUID REFERENCES public.players(id),
  round INTEGER NOT NULL,
  pick INTEGER NOT NULL,
  overall_pick INTEGER NOT NULL,
  keeper_round INTEGER,
  cost DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(league_id, overall_pick)
);

-- Sync checkpoints for error recovery
CREATE TABLE public.sync_checkpoints (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  league_id UUID REFERENCES public.leagues(id) ON DELETE CASCADE,
  sync_type TEXT NOT NULL,
  completed_steps TEXT[] DEFAULT '{}',
  current_step TEXT,
  error_message TEXT,
  started_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  UNIQUE(league_id, sync_type)
);

-- Create indexes for performance
CREATE INDEX idx_leagues_user_id ON public.leagues(user_id);
CREATE INDEX idx_leagues_yahoo_key ON public.leagues(yahoo_league_key);
CREATE INDEX idx_leagues_sync_status ON public.leagues(sync_status);
CREATE INDEX idx_teams_league_id ON public.teams(league_id);
CREATE INDEX idx_teams_is_current_user ON public.teams(is_current_user);
CREATE INDEX idx_player_stats_lookup ON public.player_stats(player_id, league_id, season, week);
CREATE INDEX idx_rosters_lookup ON public.rosters(team_id, season, week);
CREATE INDEX idx_games_lookup ON public.games(league_id, season, week);
CREATE INDEX idx_transactions_league_date ON public.transactions(league_id, transaction_date);
CREATE INDEX idx_draft_results_league ON public.draft_results(league_id, overall_pick);

-- Materialized view for team performance trends
CREATE MATERIALIZED VIEW team_performance_trends AS
WITH weekly_scores AS (
  SELECT 
    t.id as team_id,
    t.league_id,
    g.week,
    g.season,
    CASE 
      WHEN g.home_team_id = t.id THEN g.home_score 
      WHEN g.away_team_id = t.id THEN g.away_score 
    END as score,
    CASE 
      WHEN g.winner_id = t.id THEN 1 
      WHEN g.winner_id IS NOT NULL THEN 0
      ELSE 0.5 
    END as result
  FROM teams t
  JOIN games g ON g.home_team_id = t.id OR g.away_team_id = t.id
  WHERE g.is_complete = true
)
SELECT 
  team_id,
  league_id,
  season,
  week,
  score,
  result,
  AVG(score) OVER (
    PARTITION BY team_id, season 
    ORDER BY week 
    ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
  ) as rolling_avg_score,
  SUM(result) OVER (
    PARTITION BY team_id, season 
    ORDER BY week
  ) as cumulative_wins,
  RANK() OVER (
    PARTITION BY league_id, season, week 
    ORDER BY score DESC
  ) as weekly_rank
FROM weekly_scores;

CREATE UNIQUE INDEX idx_team_trends ON team_performance_trends(team_id, season, week);

-- Row Level Security
ALTER TABLE public.leagues ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.teams ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rosters ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.draft_results ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can view own leagues" ON public.leagues
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own leagues" ON public.leagues
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can view teams in own leagues" ON public.teams
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.leagues 
      WHERE leagues.id = teams.league_id 
      AND leagues.user_id = auth.uid()
    )
  );

-- Similar policies for other tables...
```

## OAuth Implementation with Rate Limiting

### OAuth Flow with PKCE and Rate Limiting

```typescript
// src/lib/yahoo/oauth-handler.ts
import { createHash, randomBytes } from 'crypto';
import PQueue from 'p-queue';

interface OAuthConfig {
  clientId: string;
  clientSecret: string;
  redirectUri: string;
  scope: string;
  authUrl: string;
  tokenUrl: string;
}

export class YahooOAuthHandler {
  private config: OAuthConfig;
  private rateLimiter: YahooRateLimiter;
  
  constructor() {
    this.config = {
      clientId: process.env.YAHOO_CLIENT_ID!,
      clientSecret: process.env.YAHOO_CLIENT_SECRET!,
      redirectUri: `${process.env.NEXT_PUBLIC_APP_URL}/api/yahoo/auth/callback`,
      scope: 'fspt-r', // Fantasy sports read-only
      authUrl: 'https://api.login.yahoo.com/oauth2/request_auth',
      tokenUrl: 'https://api.login.yahoo.com/oauth2/get_token'
    };
    
    this.rateLimiter = new YahooRateLimiter();
  }
  
  // Generate PKCE challenge
  private generatePKCE(): { verifier: string; challenge: string } {
    const verifier = randomBytes(32).toString('base64url');
    const challenge = createHash('sha256')
      .update(verifier)
      .digest('base64url');
    
    return { verifier, challenge };
  }
  
  // Initiate OAuth flow
  async initiateAuth(userId: string): Promise<string> {
    const { verifier, challenge } = this.generatePKCE();
    const state = randomBytes(16).toString('base64url');
    
    // Store in secure session storage
    await this.storeAuthSession({
      userId,
      state,
      codeVerifier: verifier,
      createdAt: new Date()
    });
    
    const params = new URLSearchParams({
      client_id: this.config.clientId,
      redirect_uri: this.config.redirectUri,
      response_type: 'code',
      scope: this.config.scope,
      state,
      code_challenge: challenge,
      code_challenge_method: 'S256'
    });
    
    return `${this.config.authUrl}?${params}`;
  }
  
  // Handle OAuth callback
  async handleCallback(code: string, state: string): Promise<TokenResponse> {
    // Validate state to prevent CSRF
    const session = await this.getAuthSession(state);
    if (!session) {
      throw new Error('Invalid state parameter');
    }
    
    // Exchange code for tokens
    const response = await fetch(this.config.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${Buffer.from(
          `${this.config.clientId}:${this.config.clientSecret}`
        ).toString('base64')}`
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code,
        redirect_uri: this.config.redirectUri,
        code_verifier: session.codeVerifier
      })
    });
    
    if (!response.ok) {
      throw new Error(`Token exchange failed: ${response.statusText}`);
    }
    
    const tokens = await response.json();
    
    // Store encrypted tokens
    await this.storeTokens(session.userId, tokens);
    
    // Clean up session
    await this.deleteAuthSession(state);
    
    return tokens;
  }
  
  // Refresh access token
  async refreshToken(userId: string): Promise<TokenResponse> {
    const tokens = await this.getStoredTokens(userId);
    
    if (!tokens?.refresh_token) {
      throw new Error('No refresh token available');
    }
    
    const response = await fetch(this.config.tokenUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': `Basic ${Buffer.from(
          `${this.config.clientId}:${this.config.clientSecret}`
        ).toString('base64')}`
      },
      body: new URLSearchParams({
        grant_type: 'refresh_token',
        refresh_token: tokens.refresh_token
      })
    });
    
    if (!response.ok) {
      throw new Error(`Token refresh failed: ${response.statusText}`);
    }
    
    const newTokens = await response.json();
    await this.storeTokens(userId, newTokens);
    
    return newTokens;
  }
  
  // Token storage with encryption
  private async storeTokens(userId: string, tokens: TokenResponse): Promise<void> {
    const { data, error } = await supabase
      .from('user_profiles')
      .update({
        yahoo_access_token: await this.encryptToken(tokens.access_token),
        yahoo_refresh_token: await this.encryptToken(tokens.refresh_token),
        yahoo_guid: tokens.xoauth_yahoo_guid,
        token_expires_at: new Date(Date.now() + tokens.expires_in * 1000)
      })
      .eq('id', userId);
      
    if (error) throw error;
  }
  
  private async encryptToken(token: string): Promise<string> {
    // Use Supabase Vault or custom encryption
    return encrypt(token, process.env.ENCRYPTION_KEY!);
  }
}

// Rate limiter implementation
export class YahooRateLimiter {
  private queue: PQueue;
  private requestCount: number = 0;
  private windowStart: Date = new Date();
  private readonly MAX_REQUESTS = 195; // Leave buffer
  private readonly WINDOW_MS = 3600000; // 1 hour
  
  constructor() {
    this.queue = new PQueue({
      concurrency: 5,
      interval: 1000,
      intervalCap: 3
    });
  }
  
  async executeRequest<T>(
    request: () => Promise<T>,
    retries: number = 3
  ): Promise<T> {
    return this.queue.add(async () => {
      // Check rate limit window
      if (Date.now() - this.windowStart.getTime() > this.WINDOW_MS) {
        this.requestCount = 0;
        this.windowStart = new Date();
      }
      
      // Check if we're approaching limit
      if (this.requestCount >= this.MAX_REQUESTS) {
        const waitTime = this.WINDOW_MS - (Date.now() - this.windowStart.getTime());
        console.log(`Rate limit approaching, waiting ${waitTime}ms`);
        await new Promise(resolve => setTimeout(resolve, waitTime));
        this.requestCount = 0;
        this.windowStart = new Date();
      }
      
      this.requestCount++;
      
      // Execute with retry logic
      let lastError;
      for (let i = 0; i < retries; i++) {
        try {
          return await request();
        } catch (error: any) {
          lastError = error;
          
          if (error.status === 429) {
            // Rate limited, wait and retry
            const retryAfter = error.headers?.['retry-after'] || 60;
            await new Promise(resolve => setTimeout(resolve, retryAfter * 1000));
          } else if (error.status >= 500) {
            // Server error, exponential backoff
            await new Promise(resolve => setTimeout(resolve, Math.pow(2, i) * 1000));
          } else {
            // Client error, don't retry
            throw error;
          }
        }
      }
      
      throw lastError;
    });
  }
  
  getQueueStatus() {
    return {
      pending: this.queue.pending,
      size: this.queue.size,
      requestCount: this.requestCount,
      windowRemaining: this.MAX_REQUESTS - this.requestCount
    };
  }
}
```

## Data Synchronization with Error Recovery

### Progressive Sync Implementation

```typescript
// src/lib/yahoo/data-sync.ts
import { z } from 'zod';

// Validation schemas
const LeagueSchema = z.object({
  league_key: z.string(),
  name: z.string(),
  season: z.number(),
  num_teams: z.number(),
  // ... other fields
});

export class FantasyDataSync {
  private yahooApi: YahooAPIClient;
  private rateLimiter: YahooRateLimiter;
  private cache: CacheManager;
  
  constructor() {
    this.yahooApi = new YahooAPIClient();
    this.rateLimiter = new YahooRateLimiter();
    this.cache = new CacheManager();
  }
  
  // Main sync orchestrator with checkpointing
  async syncLeague(
    userId: string, 
    leagueKey: string,
    options: SyncOptions = {}
  ): Promise<SyncResult> {
    const syncId = crypto.randomUUID();
    const checkpoint = await this.getOrCreateCheckpoint(leagueKey, syncId);
    
    const syncSteps: SyncStep[] = [
      { name: 'league_info', priority: 1, fn: this.syncLeagueInfo },
      { name: 'teams', priority: 1, fn: this.syncTeams },
      { name: 'current_week', priority: 1, fn: this.syncCurrentWeek },
      { name: 'standings', priority: 1, fn: this.syncStandings },
      { name: 'rosters', priority: 2, fn: this.syncRosters },
      { name: 'player_stats', priority: 2, fn: this.syncPlayerStats },
      { name: 'historical_games', priority: 3, fn: this.syncHistoricalGames },
      { name: 'transactions', priority: 3, fn: this.syncTransactions },
      { name: 'draft_results', priority: 4, fn: this.syncDraftResults }
    ];
    
    // Filter by priority if progressive sync
    const stepsToRun = options.progressive 
      ? syncSteps.filter(s => s.priority <= (options.maxPriority || 1))
      : syncSteps;
    
    const results: SyncStepResult[] = [];
    
    for (const step of stepsToRun) {
      // Skip completed steps
      if (checkpoint.completed_steps.includes(step.name)) {
        results.push({ step: step.name, status: 'skipped' });
        continue;
      }
      
      try {
        await this.updateCheckpoint(checkpoint.id, {
          current_step: step.name
        });
        
        await this.rateLimiter.executeRequest(
          () => step.fn.call(this, userId, leagueKey)
        );
        
        await this.updateCheckpoint(checkpoint.id, {
          completed_steps: [...checkpoint.completed_steps, step.name]
        });
        
        results.push({ step: step.name, status: 'success' });
      } catch (error) {
        console.error(`Sync step ${step.name} failed:`, error);
        
        await this.updateCheckpoint(checkpoint.id, {
          error_message: error.message
        });
        
        results.push({ 
          step: step.name, 
          status: 'failed',
          error: error.message 
        });
        
        // Continue with other steps if not critical
        if (step.priority === 1 && !options.continueOnError) {
          throw error;
        }
      }
    }
    
    // Mark sync as complete
    await this.completeCheckpoint(checkpoint.id);
    
    return {
      syncId,
      leagueKey,
      results,
      completedAt: new Date()
    };
  }
  
  // Sync league information
  private async syncLeagueInfo(userId: string, leagueKey: string): Promise<void> {
    const data = await this.yahooApi.getLeague(leagueKey);
    const validated = LeagueSchema.parse(data);
    
    const { error } = await supabase
      .from('leagues')
      .upsert({
        user_id: userId,
        yahoo_league_key: validated.league_key,
        name: validated.name,
        season: validated.season,
        num_teams: validated.num_teams,
        settings: data.settings,
        last_synced_at: new Date(),
        sync_status: 'syncing'
      }, {
        onConflict: 'yahoo_league_key,season,user_id'
      });
      
    if (error) throw error;
  }
  
  // Sync current week with real-time updates
  private async syncCurrentWeek(userId: string, leagueKey: string): Promise<void> {
    const league = await this.getLeague(leagueKey);
    const currentWeek = await this.yahooApi.getCurrentWeek(leagueKey);
    
    // Get live scores
    const scoreboard = await this.yahooApi.getScoreboard(leagueKey, currentWeek);
    
    for (const matchup of scoreboard.matchups) {
      await this.upsertGame({
        league_id: league.id,
        week: currentWeek,
        season: league.season,
        home_team_id: await this.getTeamId(matchup.home_team_key),
        away_team_id: await this.getTeamId(matchup.away_team_key),
        home_score: matchup.home_score,
        away_score: matchup.away_score,
        home_projected: matchup.home_projected,
        away_projected: matchup.away_projected,
        is_complete: matchup.is_complete
      });
    }
    
    // Set up real-time subscription for live updates
    if (!scoreboard.every(m => m.is_complete)) {
      await this.setupLiveUpdates(league.id, currentWeek);
    }
  }
  
  // Batch sync historical data
  private async syncHistoricalGames(userId: string, leagueKey: string): Promise<void> {
    const league = await this.getLeague(leagueKey);
    const weeks = Array.from({ length: league.current_week - 1 }, (_, i) => i + 1);
    
    // Batch API calls for efficiency
    const batchSize = 5;
    for (let i = 0; i < weeks.length; i += batchSize) {
      const batch = weeks.slice(i, i + batchSize);
      
      await Promise.all(
        batch.map(week => 
          this.rateLimiter.executeRequest(() => 
            this.syncWeekGames(league.id, leagueKey, week)
          )
        )
      );
    }
  }
  
  // Sync transactions with validation
  private async syncTransactions(userId: string, leagueKey: string): Promise<void> {
    const league = await this.getLeague(leagueKey);
    const transactions = await this.yahooApi.getTransactions(leagueKey);
    
    for (const transaction of transactions) {
      const players_added = await this.resolvePlayerIds(transaction.players_added);
      const players_dropped = await this.resolvePlayerIds(transaction.players_dropped);
      
      await supabase
        .from('transactions')
        .upsert({
          league_id: league.id,
          type: transaction.type,
          status: transaction.status,
          team_id: await this.getTeamId(transaction.team_key),
          partner_team_id: transaction.partner_team_key 
            ? await this.getTeamId(transaction.partner_team_key)
            : null,
          players_added,
          players_dropped,
          faab_bid: transaction.faab_bid,
          transaction_date: transaction.transaction_date,
          process_date: transaction.process_date
        });
    }
  }
  
  // Progressive data loading based on priority
  async performProgressiveSync(userId: string, leagueKey: string): Promise<void> {
    // Priority 1: Essential data (immediate)
    await this.syncLeague(userId, leagueKey, {
      progressive: true,
      maxPriority: 1
    });
    
    // Priority 2: Current season data (background)
    setTimeout(() => {
      this.syncLeague(userId, leagueKey, {
        progressive: true,
        maxPriority: 2
      });
    }, 1000);
    
    // Priority 3: Historical data (deferred)
    setTimeout(() => {
      this.syncLeague(userId, leagueKey, {
        progressive: true,
        maxPriority: 3
      });
    }, 5000);
    
    // Priority 4: Analytics data (low priority)
    setTimeout(() => {
      this.syncLeague(userId, leagueKey, {
        progressive: true,
        maxPriority: 4
      });
    }, 10000);
  }
}

// Cache manager for performance
export class CacheManager {
  private redis: Redis;
  
  constructor() {
    this.redis = new Redis(process.env.REDIS_URL!);
  }
  
  // Cache keys with TTL strategy
  private getCacheKey(type: string, id: string, suffix?: string): string {
    return `fantasy:${type}:${id}${suffix ? `:${suffix}` : ''}`;
  }
  
  private getTTL(type: string): number {
    const ttlMap = {
      league: 3600,        // 1 hour
      team: 3600,          // 1 hour
      roster: 900,         // 15 minutes (game day)
      roster_off: 86400,   // 24 hours (non-game day)
      player: 86400,       // 24 hours
      score: 60,           // 1 minute (live games)
      standings: 1800      // 30 minutes
    };
    
    return ttlMap[type] || 3600;
  }
  
  async get<T>(key: string): Promise<T | null> {
    const data = await this.redis.get(key);
    return data ? JSON.parse(data) : null;
  }
  
  async set(key: string, value: any, ttl?: number): Promise<void> {
    const type = key.split(':')[1];
    const actualTTL = ttl || this.getTTL(type);
    
    await this.redis.setex(key, actualTTL, JSON.stringify(value));
  }
  
  async invalidate(pattern: string): Promise<void> {
    const keys = await this.redis.keys(pattern);
    if (keys.length > 0) {
      await this.redis.del(...keys);
    }
  }
  
  // Smart caching based on game schedule
  async setWithGameAwareTTL(key: string, value: any): Promise<void> {
    const isGameDay = await this.isGameDay();
    const type = key.split(':')[1];
    
    let ttl = this.getTTL(type);
    if (type === 'roster' && !isGameDay) {
      ttl = this.getTTL('roster_off');
    }
    
    await this.set(key, value, ttl);
  }
  
  private async isGameDay(): Promise<boolean> {
    const day = new Date().getDay();
    // NFL games: Thu (4), Sun (0), Mon (1)
    return [0, 1, 4].includes(day);
  }
}