---
description: Fetch and check if a Linear issue's branch has merged into origin/main, then close it if so
argument-hint: <linear-id> (e.g. COE-456)
model: sonnet[1m]
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Agent
  - mcp__linear-server__get_issue
  - mcp__linear-server__list_issue_statuses
  - mcp__linear-server__save_comment
  - mcp__linear-server__save_issue
---

The Linear issue ID is: $ARGUMENTS

## Phase 0 - Linear + Git state (dispatch to a Haiku subagent)

1. `git fetch --all --prune`.
2. Check if a remote branch for this issue has been merged into `origin/main`:
   - Run `git branch -r --merged origin/main` and look for branches
     containing the issue ID `$AEGUMENTS` (case-insensitive, e.g. `coe-456`)
3. Check the commit log on `origin/main` for any mention of the issue ID:
   - Run `git log origin/main --oneline` and grep for the issue ID (case-insensitive)
   - If not found, widen the search since it may be a merge-commit without the issue ID.

## Phase 1 - Understanding state (you do this directly, on sonnet[1m])

1. Report clearly:
   - Whether a matching branch was found merged into `origin/main`
   - Whether any commits on `origin/main` reference the issue
   - A final recommendation: **safe to close** or **not yet merged**

## Phase 2 - Linear Clean up (dispatch to a Haiku subagent)

5. If **safe to close**:
   - Use `mcp__linear-server__get_issue` to fetch the issue and confirm its current state
   - Use `mcp__linear-server__list_issue_statuses` with the issue's team to find the "Done" status
   - Use `mcp__linear-server__save_comment` to post a comment on the issue, e.g.: "Branch merged into `main` — closing."
   - Use `mcp__linear-server__save_issue` to update the issue state to "Done"
   - Confirm the issue has been closed
