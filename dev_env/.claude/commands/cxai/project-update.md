---
name: project-update
description: Generate a Linear project status update from Linear, GitHub, Slack, and Notion data
argument-hint: [project-name]
allowed-tools:
  - Agent
  - AskUserQuestion
  - Bash
  - mcp__linear-server__get_project
  - mcp__linear-server__list_projects
  - mcp__linear-server__get_status_updates
  - mcp__linear-server__save_status_update
  - mcp__linear-server__list_issues
  - mcp__linear-server__list_comments
  - mcp__linear-server__list_cycles
  - mcp__plugin_slack_slack__slack_read_user_profile
  - mcp__plugin_slack_slack__slack_search_public_and_private
  - mcp__plugin_slack_slack__slack_read_thread
  - mcp__notion__notion-search
  - mcp__notion__notion-fetch
---

Generate a Linear project status update for: $ARGUMENTS

Follow these steps carefully, completing each before moving to the next.

---

## Step 1 — Resolve project, check connections, and determine reporting window

Run all of these in parallel:

1. **Resolve project + verify Linear** — `get_project` for the argument. If it fails with an auth/connection error, Linear is not connected. If the argument is empty or ambiguous, ask the user to pick from `list_projects`.
2. **Determine reporting window** — `get_status_updates` (type: "project") for the project to find the most recent update. The reporting window runs from that update's creation date to now. If there is no previous update, you'll need to ask the user for a start date after this step completes.
3. **Verify Slack** — `slack_read_user_profile` with no arguments. Any successful response confirms Slack is connected.

If **Linear or Slack** fail with authentication/connection errors, stop immediately and tell the user which MCP server(s) are not connected. Instruct them to run `/mcp` to authenticate, then retry the command.

---

## Step 2 — Gather all data in parallel

Launch the following data-gathering tasks **simultaneously** using the Agent tool with `model: "haiku"` for each. All agents run in parallel — do NOT wait for one to finish before starting the next.

Pass each agent the project name/ID, team key (Linear team prefix), and reporting window dates.

### Agent 1: Linear Issues & Comments

Instruct the agent to:

1. **Issues** — `list_issues` filtered to the project. Note any issues whose state changed within the reporting window (e.g. moved to Done, In Progress, Cancelled). Group them by current state. If the project has more than ~50 issues, do not enumerate all open issues — summarise by state count and only list individual issues that changed state.
2. **Comments** — For issues that changed state or have recent activity, use `list_comments` to capture context on decisions, blockers, or scope changes. Fetch comments for multiple issues in parallel.
3. **Cycles** — If the project's teams use cycles, `list_cycles` for context on what's current vs upcoming.

Return a structured summary of: issues grouped by state, issues that changed state (with context from comments), any blockers or decisions mentioned, and cycle info.

### Agent 2: Git / GitHub data

Instruct the agent to:

1. Run `gh auth status` via Bash — if it fails, return "Git data unavailable" and stop.
2. Infer the GitHub org from the current repo's remote (`gh repo view --json owner -q '.owner.login'`), or state it couldn't be determined.
3. Use `gh repo list <org> --json name,url --limit 100` to list org repos, then identify repos relevant to the project's team.
4. For each relevant repo **in parallel**, list merged PRs in the reporting window: `gh pr list -R <owner/repo> --state merged --search "merged:>=<start-date> <team-prefix>-" --json title,url,mergedAt`
5. Optionally check for open PRs in review or draft.

Return results grouped by repo.

### Agent 3: Slack data

Instruct the agent to:

1. Run multiple `slack_search_public_and_private` queries **in parallel** — one for the project name and one for the team prefix — within the reporting window.
2. For any relevant threads found, use `slack_read_thread` to get full context. Read multiple threads in parallel.

Return a summary of decisions, blockers, or notable discussions found.

### Agent 4: Notion data

Instruct the agent to:

1. `notion-search` for pages mentioning the project name or key terms. If the search fails with an auth/connection error, return "Notion data unavailable" and stop.
2. For promising results, use `notion-fetch` to read page content in parallel and extract relevant context (decisions, status notes, blockers, scope changes).

Return a summary of findings, or "Notion data unavailable" if not connected.

---

**Wait for all agents to complete**, then synthesise their results.

## Step 3 — Ask for additional context

Present a summary of what you found across all sources and ask the user:

- Is there anything missing or incorrect?
- Any risks, blockers, annual leave, or team dependencies to call out?
- Any other context that didn't show up in Linear/Git/Slack?

## Step 4 — Draft the update

Write the update body using this exact format (the status is set separately via the Linear health field, not in the body):

```
## Progress

- **TL;DR:** <Concise summary of most critical points>
- **STATE:** <[old Linear Health -> ]><new Linear Health> <Reasoning if Linear Health has changed>

### Done
- <bullet list of what shipped or was completed>

### Now
- <bullet list of what's actively in progress>

### Next
- <bullet list of what's planned next>

### Later
- <bullet list of longer-term items, if relevant>

## Risks
- <bullet list of blockers, unknowns, team dependencies, or annual leave>
- If none, state "No risks identified."
```

**Writing guidelines:** Ensure all relevant information is captured, but keep bullets concise.

Separately, determine the Linear health status based on the data:

- **onTrack** — work is progressing as planned, no significant blockers.
- **atRisk** — there are concerns (blocked issues, scope changes, resource gaps) that could delay the project.
- **offTrack** — the project is behind schedule or has unresolved critical blockers.

If you're unsure about the status, present the evidence and ask the user to decide.

## Step 5 — Confirm and create

Show the full drafted update to the user and ask for confirmation. Include the proposed status (onTrack / atRisk / offTrack) and confirm which project it will be posted to.

Only after explicit user approval, use `save_status_update` with:

- `type`: "project"
- `project`: the project name/ID
- `health`: "onTrack" | "atRisk" | "offTrack"
- `body`: the update body in markdown

Report the result back to the user.
