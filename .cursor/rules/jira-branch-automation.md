### Rule: Auto-create and checkout a git branch when starting work on a Jira Issue

#### Scope
Global

#### Intent
When the user is about to start working on a Jira Issue (e.g., they say they will start/pick up/work on an issue, reference an Issue Key like ABC-123, or when transitioning an issue to In Progress), automatically create and checkout a local git branch using the naming convention `[IssueKey]-[Summary]` with spaces in the Summary replaced by dashes.

#### Required Data
- Jira Issue Key (e.g., ABC-123)
- Jira Issue Summary (fetched from Jira)

#### Data Retrieval
- Use the Atlassian integration to fetch the Jira Issue by key and read its Summary field.

#### Branch Name Construction
- Construct `branchName = IssueKey + '-' + SummaryWithSpacesReplacedByDashes`.
- Replace all whitespace in Summary with a single dash (`-`).
- Do not change case unless the user or project specifies otherwise.
- Example: IssueKey = `FA-42`, Summary = `Implement login flow` → `FA-42-Implement-login-flow`.

#### Behavior
1. Detect intent that the user is starting work on a specific Jira Issue.
2. Retrieve the Issue Summary via Jira.
3. Build the branch name as described above.
4. Propose and run a terminal command to checkout the branch in the repository root (non-interactive). If the branch exists locally, checkout; otherwise create then checkout.

#### Terminal Command (PowerShell-safe)
Use this when the shell is PowerShell:

```powershell
# Assumes current working directory is the repository root
$branchName = "<IssueKey>-<Summary-with-dashes>"
git rev-parse --verify --quiet "$branchName" > $null
if ($LASTEXITCODE -eq 0) {
  git checkout "$branchName"
} else {
  git checkout -b "$branchName"
}
```

#### Terminal Command (POSIX shell)
Use this when the shell is bash/zsh:

```bash
branchName="<IssueKey>-<Summary-with-dashes>"
if git rev-parse --verify --quiet "$branchName" >/dev/null; then
  git checkout "$branchName"
else
  git checkout -b "$branchName"
fi
```

#### Notes
- Ensure you are in the repository root before running git commands. If entering a new shell, `cd` to the project root first.
- Keep exactly the requested naming: only replace spaces in Summary with dashes; do not add other sanitization unless explicitly asked.
- If the user specifies a different branch name, prefer the user's input.
- Confirm the created/checked out branch back to the user.

---

### Rule: Complete work, commit changes, merge to main, and mark Jira Issue as done

#### Scope
Global

#### Intent
When the user indicates they have completed work on a Jira Issue (e.g., they say the work is done, ready to merge, or want to complete the issue), automatically:
1. Commit all changes to the current branch
2. Merge the feature branch to main
3. Push the main branch to remote
4. Mark the Jira Issue as Done

#### Required Data
- Current branch name (to identify the Jira Issue Key)
- Jira Issue Key (extracted from branch name)
- Commit message (generated from Jira Issue details)

#### Data Retrieval
- Extract Jira Issue Key from current branch name (format: `[IssueKey]-[Summary]`)
- Use the Atlassian integration to fetch the Jira Issue details
- Generate commit message using Issue Key and Summary

#### Workflow Steps

##### 1. Commit Changes
- Stage all changes: `git add .`
- Create commit with descriptive message: `git commit -m "[IssueKey] [Summary]"`
- Example: `git commit -m "FA-42 Implement login flow"`

##### 2. Merge to Main
- Switch to main branch: `git checkout main`
- Pull latest changes: `git pull origin main`
- Merge feature branch: `git merge [branch-name]`
- Resolve any merge conflicts if they occur

##### 3. Push to Remote
- Push main branch: `git push origin main`
- Delete the feature branch locally: `git branch -d [branch-name]`
- Delete the feature branch remotely: `git push origin --delete [branch-name]`

##### 4. Mark Jira Issue as Done
- Use Atlassian integration to transition the Jira Issue to "Done" status
- Add a comment indicating the work has been completed and merged

#### Terminal Commands (PowerShell-safe)

```powershell
# 1. Commit changes
git add .
$issueKey = "<IssueKey>"
$summary = "<Summary>"
git commit -m "$issueKey $summary"

# 2. Merge to main
git checkout main
git pull origin main
git merge "<branch-name>"

# 3. Push to remote
git push origin main
git branch -d "<branch-name>"
git push origin --delete "<branch-name>"
```

#### Terminal Commands (POSIX shell)

```bash
# 1. Commit changes
git add .
issueKey="<IssueKey>"
summary="<Summary>"
git commit -m "$issueKey $summary"

# 2. Merge to main
git checkout main
git pull origin main
git merge "<branch-name>"

# 3. Push to remote
git push origin main
git branch -d "<branch-name>"
git push origin --delete "<branch-name>"
```

#### Jira Issue Transition
- Use the Atlassian MCP integration to transition the issue to "Done"
- Add a completion comment with merge information
- Example comment: "Work completed and merged to main branch. Feature branch [branch-name] has been deleted."

#### Behavior
1. Detect intent that the user has completed work on a Jira Issue
2. Extract Issue Key from current branch name
3. Retrieve Issue details from Jira
4. Execute the complete workflow: commit → merge → push → cleanup
5. Transition Jira Issue to Done status
6. Confirm completion to the user

#### Notes
- Always ensure you're in the repository root before running git commands
- Handle merge conflicts gracefully - prompt user if manual resolution is needed
- Verify the current branch follows the expected naming convention before proceeding
- Confirm each step completion before proceeding to the next
- If any step fails, stop and inform the user of the issue


