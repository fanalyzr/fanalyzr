# Authentication System Overview

## Current Configuration

**Active Provider**: Supabase  
**Configuration File**: `src/global-config.ts`  
**Last Updated**: December 2024

## System Architecture

The Fanalyzr application implements a flexible, multi-provider authentication system that supports five different authentication methods:

### Supported Providers

1. **Supabase** (Currently Active)
2. **JWT** (JSON Web Tokens)
3. **Auth0**
4. **Firebase**
5. **AWS Amplify**

## Directory Structure

```
src/auth/
├── components/           # Shared auth UI components
├── context/             # Provider-specific auth contexts
│   ├── amplify/         # AWS Amplify implementation
│   ├── auth0/           # Auth0 implementation
│   ├── firebase/        # Firebase implementation
│   ├── jwt/             # JWT implementation
│   └── supabase/        # Supabase implementation (active)
├── guard/               # Route protection components
├── hooks/               # Authentication hooks
├── types.ts             # TypeScript definitions
├── utils/               # Authentication utilities
└── view/                # Provider-specific UI views
    ├── amplify/         # Amplify-specific views
    ├── auth0/           # Auth0-specific views
    ├── auth-demo/       # Demo authentication views
    ├── firebase/        # Firebase-specific views
    ├── jwt/             # JWT-specific views
    └── supabase/        # Supabase-specific views (active)
```

## Configuration

### Global Configuration (`src/global-config.ts`)

The authentication provider is configured in the global configuration:

```typescript
export const CONFIG: ConfigValue = {
  // ... other config
  auth: {
    method: 'supabase',        // Current active provider
    skip: false,               // Whether to skip authentication
    redirectPath: paths.dashboard.root,  // Post-auth redirect
  },
  // Provider-specific configurations
  supabase: {
    url: import.meta.env.VITE_SUPABASE_URL ?? '',
    key: import.meta.env.VITE_SUPABASE_ANON_KEY ?? '',
  },
  // ... other provider configs
};
```

### Environment Variables

**Supabase (Active)**:
- `VITE_SUPABASE_URL` - Supabase project URL
- `VITE_SUPABASE_ANON_KEY` - Supabase anonymous key

**Other Providers** (Available but not active):
- Firebase: `VITE_FIREBASE_*` variables
- Auth0: `VITE_AUTH0_*` variables
- Amplify: `VITE_AWS_AMPLIFY_*` variables

## Dynamic Provider Selection

The application uses a conditional logic pattern in `src/app.tsx` to dynamically select the appropriate authentication provider:

```typescript
const AuthProvider =
  (CONFIG.auth.method === 'amplify' && AmplifyAuthProvider) ||
  (CONFIG.auth.method === 'firebase' && FirebaseAuthProvider) ||
  (CONFIG.auth.method === 'supabase' && SupabaseAuthProvider) ||
  (CONFIG.auth.method === 'auth0' && Auth0AuthProvider) ||
  JwtAuthProvider;  // Default fallback
```

## Current Implementation Details

### Supabase Integration

**Context Provider**: `src/auth/context/supabase/auth-provider.tsx`  
**Actions**: `src/auth/context/supabase/action.tsx`  
**Views**: `src/auth/view/supabase/` directory

**Features**:
- Sign in/up with email and password
- Password reset functionality
- Email verification
- Password update
- Social authentication (via Supabase)

### Authentication Guards

The system includes several route protection components:

- **AuthGuard** (`src/auth/guard/auth-guard.tsx`) - Protects authenticated routes
- **GuestGuard** (`src/auth/guard/guest-guard.tsx`) - Protects guest-only routes
- **RoleBasedGuard** (`src/auth/guard/role-based-guard.tsx`) - Role-based access control

### Authentication Hooks

- **useAuthContext** (`src/auth/hooks/use-auth-context.ts`) - Main auth context hook
- **useMockedUser** (`src/auth/hooks/use-mocked-user.ts`) - Development/testing hook

## Switching Authentication Providers

To switch to a different authentication provider:

1. **Update Configuration**: Modify `src/global-config.ts`:
   ```typescript
   auth: {
     method: 'jwt', // or 'firebase', 'auth0', 'amplify'
     skip: false,
     redirectPath: paths.dashboard.root,
   }
   ```

2. **Set Environment Variables**: Configure the appropriate environment variables for the new provider

3. **Update Views**: Ensure the appropriate view components are available in `src/auth/view/[provider]/`

4. **Test Integration**: Verify the new provider works with your backend/authentication service

## Security Considerations

- All authentication providers use secure token-based authentication
- Environment variables are used for sensitive configuration
- Route guards prevent unauthorized access
- Provider-specific security features are leveraged (e.g., Supabase RLS)

## Development Notes

- The system supports multiple providers simultaneously in the codebase
- Provider-specific UI components are isolated in their respective directories
- The authentication context provides a consistent interface regardless of the underlying provider
- Mock authentication is available for development/testing via `useMockedUser`

## Related Documentation

- [Supabase Setup Guide](SUPABASE_AUTH_SETUP.md)
- [Database Schema Implementation](database-schema-implementation-plan.md)
- [Jira Tickets - Supabase Authentication Integration](Jira%20Tickets%20-%20Supabase%20Authentication%20Integration.md)

## Maintenance

- Regularly update provider SDKs and dependencies
- Monitor authentication logs and security updates
- Test provider switching functionality during major updates
- Keep environment variables secure and rotate keys as needed
