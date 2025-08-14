## Epic: Replace Demo Data with Real Supabase Authentication
**Epic Summary**: Integrate real Supabase authentication data to replace demo user data throughout the application  
**Epic Description**: Currently the application uses mock/demo user data (Jaydon Frankie, demo@minimals.cc). This epic covers replacing all demo data with real authenticated user information from Supabase, including proper database schema updates and UI component integration.

---

## Story 1: Database Schema - Add User Profile Name Fields
**Story Points**: 5  
**Priority**: High  

**Summary**: Add first_name and last_name columns to profiles table

**Description**:
As a developer, I need to add first_name and last_name columns to the existing profiles table so that user profile information can be properly stored and retrieved from the database.

**Acceptance Criteria**:
- [ ] Add `first_name` TEXT column to profiles table
- [ ] Add `last_name` TEXT column to profiles table  
- [ ] Create database migration file
- [ ] Migration should be idempotent (safe to run multiple times)
- [ ] Migration should work with existing profiles table structure

**Technical Details**:
- Migration file: `supabase/migrations/20250107000001_add_name_columns_to_profiles.sql`
- Use `ALTER TABLE profiles ADD COLUMN IF NOT EXISTS` for safety

**Definition of Done**:
- Migration file created and tested
- Columns successfully added to profiles table
- No data loss or corruption during migration

---

## Story 2: Database Triggers - Auto-populate User Profiles
**Story Points**: 8  
**Priority**: High  

**Summary**: Create database trigger to automatically populate user profiles on signup

**Description**:
As a user, when I sign up for an account, my profile information should be automatically created in the profiles table so that my name data is available immediately without manual intervention.

**Acceptance Criteria**:
- [ ] Create `handle_new_user()` trigger function
- [ ] Function extracts first_name and last_name from user_metadata
- [ ] Function handles both `display_name` parsing and separate name fields
- [ ] Trigger fires AFTER INSERT on auth.users table
- [ ] Handle name extraction for "First Last" format
- [ ] Use UPSERT pattern for conflict resolution

**Technical Details**:
- Function should extract from `raw_user_meta_data->>'display_name'`
- Use `split_part()` for parsing "First Last" format
- Handle cases where only first name is provided
- Include proper error handling and security definer

**Definition of Done**:
- Trigger function created and deployed
- New user signups automatically create profile records
- Name fields properly populated from signup data
- Existing users not affected

---

## Story 3: Authentication - Update Sign Up Process
**Story Points**: 3  
**Priority**: High 

**Summary**: Modify signup process to store first_name and last_name in user metadata

**Description**:
As a developer, I need to update the signup process to store both display_name and separate first_name/last_name fields in user metadata so that the database trigger can access this information.

**Acceptance Criteria**:
- [ ] Update `signUp` function in Supabase auth actions
- [ ] Store `display_name` as combined "First Last"
- [ ] Store separate `first_name` and `last_name` fields
- [ ] Maintain backward compatibility with existing signup flow
- [ ] No breaking changes to signup form UI

**Technical Details**:
- File: `src/auth/context/supabase/action.tsx`
- Add to `options.data` object in signUp call
- Include: `{ display_name, first_name, last_name }`

**Definition of Done**:
- signUp function updated with new metadata fields
- New signups include all required name data
- Database trigger receives proper data
- Existing functionality unaffected

---

## Story 4: Authentication Context - Add Email Property
**Story Points**: 2  
**Priority**: Medium  

**Summary**: Update authentication provider to include user email

**Description**:
As a developer, I need the authentication context to provide the user's email address so that components can display real email data instead of demo email addresses.

**Acceptance Criteria**:
- [ ] Add `email` property to user object in auth provider
- [ ] Email should come from `state.user?.email`
- [ ] Maintain existing user object structure
- [ ] No breaking changes to existing components

**Technical Details**:
- File: `src/auth/context/supabase/auth-provider.tsx`
- Add email to memoizedValue user object
- Source from Supabase user.email field

**Definition of Done**:
- Email property available in useAuthContext
- Real user email displayed throughout app
- No null/undefined email issues

---

## Story 5: UI Components - Replace Mock User with Real Auth
**Story Points**: 8  
**Priority**: Medium  

**Summary**: Replace useMockedUser with useAuthContext in all components

**Description**:
As a user, I want to see my real name and email throughout the application instead of demo data (Jaydon Frankie, demo@minimals.cc) so that the app reflects my actual account information.

**Acceptance Criteria**:
- [ ] Replace `useMockedUser` with `useAuthContext` in all components
- [ ] Update dashboard layout component
- [ ] Update account drawer component  
- [ ] Update account popover component
- [ ] Update overview app view component
- [ ] Update account general component
- [ ] All user displays show real authenticated user data
- [ ] No references to demo data remain

**Technical Details**:
Files to update:
- `src/layouts/dashboard/layout.tsx`
- `src/layouts/components/account-drawer.tsx`
- `src/layouts/components/account-popover.tsx`
- `src/sections/overview/app/view/overview-app-view.tsx`
- `src/sections/account/account-general.tsx`

**Definition of Done**:
- All components use real authentication data
- Demo user data no longer appears in UI
- User sees their actual name and email
- Avatar shows correct initials

---

## Story 6: Avatar Enhancement - Real User Initials
**Story Points**: 3  
**Priority**: Low  

**Summary**: Update avatar initials to use real user's display name

**Description**:
As a user, I want my avatar to display my actual initials (derived from my first and last name) instead of demo initials so that the avatar is personalized to my account.

**Acceptance Criteria**:
- [ ] Avatar initials derived from real user displayName
- [ ] Initials extracted from first and last name (e.g., "John Doe" → "JD")
- [ ] Handle edge cases (single name, empty name)
- [ ] Maintain existing avatar styling and colors
- [ ] Background color matches card styling

**Technical Details**:
- Initials come from `user.displayName` via `useAuthContext`
- Existing `getInitials()` function handles extraction
- Background color: `background.paper`
- Works in both header button and account drawer

**Definition of Done**:
- Avatar displays user's actual initials
- Initials update when user changes display name
- Styling consistent with design system
- No demo initials visible

---

## Bug/Task: Documentation and Migration Guide
**Story Points**: 2  
**Priority**: Low  

**Summary**: Create documentation for Supabase authentication setup

**Description**:
As a developer, I need comprehensive documentation of the authentication changes so that the setup can be replicated and maintained by the team.

**Acceptance Criteria**:
- [ ] Document all database changes made
- [ ] Include migration instructions  
- [ ] List all modified files
- [ ] Explain the authentication flow
- [ ] Provide troubleshooting guidance

**Technical Details**:
- Create `SUPABASE_AUTH_SETUP.md`
- Include migration commands
- Document component changes
- Explain trigger functionality

**Definition of Done**:
- Documentation complete and accurate
- Migration steps clearly outlined
- File changes documented
- Ready for team review
