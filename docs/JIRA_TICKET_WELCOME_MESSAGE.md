# Jira Issue: Dashboard Welcome Message Update

Project: MVP
Issue Type: Story
Priority: Medium

Summary
Update Dashboard Welcome Message to Display First Name Only

Description
User Story:
As a user, I want the dashboard welcome message to show only my first name instead of my full name, so that the greeting feels more personal and concise.

Current Behavior:
- Dashboard shows "Welcome back 👋 Josh Yarber" (full display name)
- Analytics view shows generic "Hi, Welcome back 👋" without personalization

Desired Behavior:
- Dashboard shows "Welcome back 👋 Josh" (first name only)
- Analytics view shows "Hi, Welcome back 👋 Josh" (personalized with first name)

Acceptance Criteria
• App overview dashboard displays "Welcome back 👋 [FirstName]" instead of full display name
• Analytics overview dashboard displays "Hi, Welcome back 👋 [FirstName]" instead of generic message
• First name is extracted from authenticated user's displayName field
• Solution handles edge cases (empty names, single names, extra whitespace)
• Welcome messages use real authenticated user data via useAuthContext
• No hard-coded names or demo data remain

Technical Details
Files to modify:
• `src/sections/overview/app/view/overview-app-view.tsx`
• `src/sections/overview/analytics/view/overview-analytics-view.tsx`

Key Changes:
1. Added getFirstName() helper function to both components
2. Replaced user?.displayName with firstName variable
3. Updated both app and analytics overview welcome messages
4. Maintained existing authentication integration

Definition of Done
Dashboard welcome message shows first name only (e.g., "Josh" instead of "Josh Yarber")
Analytics welcome message is personalized with first name
• Helper function handles various name formats correctly
• No performance impact on dashboard load times
• Works consistently across different user accounts
• Code follows existing component patterns and conventions

Test Cases
Test Scenario 1: Standard Full Name
• Given: User displayName is "John Smith"
• When: User views dashboard
• Then: Welcome message shows "Welcome back 👋 John"

Test Scenario 2: Single Name
• Given: User displayName is "Madonna"
• When: User views dashboard
• Then: Welcome message shows "Welcome back 👋 Madonna"

Test Scenario 3: Empty/Missing Name
• Given: User displayName is empty or null
• When: User views dashboard
• Then: Welcome message shows "Welcome back 👋" (graceful fallback)

Test Scenario 4: Name with Extra Whitespace
• Given: User displayName is "  Alice  Johnson  "
• When: User views dashboard
• Then: Welcome message shows "Welcome back 👋 Alice" (trimmed properly)

Story Points
Estimate: 2 Story Points