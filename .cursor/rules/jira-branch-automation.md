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
- If the user specifies a different branch name, prefer the user’s input.
- Confirm the created/checked out branch back to the user.


