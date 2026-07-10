---
name: initiative-update
description: Generate a Linear initiative status update from Linear, GitHub, Slack, and Notion data
argument-hint: [initiative-name]
allowed-tools:
  - Agent
  - AskUserQuestion
  - Bash
  - mcp__linear-server__get_initiative
  - mcp__linear-server__list_initiatives
  - mcp__linear-server__get_status_updates
  - mcp__linear-server__save_status_update
  - mcp__linear-server__get_project
  - mcp__linear-server__list_issues
  - mcp__linear-server__list_comments
  - mcp__plugin_slack_slack__slack_read_user_profile
  - mcp__plugin_slack_slack__slack_search_public_and_private
  - mcp__plugin_slack_slack__slack_read_thread
  - mcp__notion__notion-search
  - mcp__notion__notion-fetch
---

Generate a Linear initiative status update for: $ARGUMENTS

Follow these steps carefully, completing each before moving to the next.

---

## Step 1 — Resolve initiative, check connections, and determine reporting window

Run all of these in parallel:

1. **Resolve initiative + get sub-projects + verify Linear** — `get_initiative` with `includeProjects: true` for the argument. This both resolves the initiative and fetches all sub-projects in one call. If it fails with an auth/connection error, Linear is not connected. If the argument is empty or ambiguous, ask the user to pick from `list_initiatives`.
2. **Determine reporting window** — `get_status_updates` (type: "initiative") for the initiative to find the most recent update. The reporting window runs from that update's creation date to now. If there is no previous update, you'll need to ask the user for a start date after this step completes.
3. **Verify Slack** — `slack_read_user_profile` with no arguments. Any successful response confirms Slack is connected.

If **Linear or Slack** fail with authentication/connection errors, stop immediately and tell the user which MCP server(s) are not connected. Instruct them to run `/mcp` to authenticate, then retry the command.

---

## Step 2 — Gather all data in parallel

Launch the following data-gathering tasks **simultaneously** using the Agent tool with `model: "haiku"` for each. All agents run in parallel — do NOT wait for one to finish before starting the next.

Pass each agent the initiative name, the list of sub-project names/IDs, team keys (Linear team prefixes), and reporting window dates.

### Agent 1: Linear project statuses & issues

Instruct the agent to:

1. **Project status** — For each sub-project **in parallel**, use `get_project` and `get_status_updates` (type: "project") to get the latest project-level status and health.
2. **Issues** — For each sub-project **in parallel**, use `list_issues` filtered to the project. Note issues whose state changed within the reporting window. Group by project and state. If a sub-project has more than ~50 issues, do not enumerate all open issues — summarise by state count and only list individual issues that changed state.
3. **Comments** — For issues with recent state changes or notable activity, use `list_comments` for context on decisions, blockers, or scope changes. Fetch comments for multiple issues in parallel.

Return a structured summary per sub-project: health status, issues by state, issues that changed state (with comment context), and any blockers or decisions.

### Agent 2: Git / GitHub data

Instruct the agent to:

1. Run `gh auth status` via Bash — if it fails, return "Git data unavailable" and stop.
2. Infer the GitHub org from the current repo's remote (`gh repo view --json owner -q '.owner.login'`), or state it couldn't be determined.
3. Use `gh repo list <org> --json name,url --limit 100` to list org repos, then identify repos relevant to the initiative's projects.
4. For each relevant repo **in parallel**, list merged PRs in the reporting window: `gh pr list -R <owner/repo> --state merged --search "merged:>=<start-date> <team-prefix>-" --json title,url,mergedAt`
5. Optionally check for open PRs in review or draft.

Return results grouped by repo and project.

### Agent 3: Slack data

Instruct the agent to:

1. Run multiple `slack_search_public_and_private` queries **in parallel** — one for the initiative name and one for each sub-project name — within the reporting window.
2. For any relevant threads found, use `slack_read_thread` to get full context. Read multiple threads in parallel.

Return a summary of decisions, blockers, metric discussions, or notable findings.

### Agent 4: Notion data

Instruct the agent to:

1. `notion-search` for pages mentioning the initiative name, its projects, or key metric terms. If the search fails with an auth/connection error, return "Notion data unavailable" and stop.
2. For promising results, use `notion-fetch` to read page content in parallel and extract relevant context (metric data, decisions, scope changes).

Return a summary of findings, or "Notion data unavailable" if not connected.

---

**Wait for all agents to complete**, then synthesise their results.

## Step 3 — Ask for additional context

Present a summary of what you found across all sources and ask the user:

- Is there anything missing or incorrect?
- Any metric updates or data points not captured in Linear/Git/Slack/Notion?
- Any scope changes, learnings, or strategic context to include?
- Any risks, blockers, or team dependencies to call out?

## Step 4 — Draft the update

Write the update body using this exact format (the status is set separately via the Linear health field, not in the body):

```
## Progress

**<Sub-project 1 name>**
- <Bullet points covering what's been completed, key decisions, and notable results. Include specific numbers/data where available.>

**<Sub-project 2 name>**
- <Bullet points covering what's been completed, key decisions, and notable results.>

<repeat for each sub-project>

## Next Steps

- <Concrete actions planned for the next period, across all sub-projects. Each bullet should be actionable and specific.>

## Risks

- **<Risk area>** — <description of the risk, why it matters, and what's needed to mitigate it.>
- If none, state "No risks identified."
```

**Writing guidelines:**

- Group progress by sub-project using **bold** headers (not ### subheadings).
- Keep bullets concise but include enough detail to be useful — mention specific tools, services, metrics, and team members where relevant.
- Next Steps should be a flat list across all sub-projects, not grouped by project.
- Risks should bold the risk area name and use an em dash before the description.

Separately, determine the Linear health status based on the data:

- **onTrack** — metrics are trending in the right direction, delivery is progressing as planned.
- **atRisk** — metrics are flat or uncertain, there are delivery concerns, or scope changes may be needed.
- **offTrack** — metrics are trending negatively, delivery is significantly behind, or the initiative needs strategic review.

If you're unsure about the status, present the evidence and ask the user to decide.

## Step 5 — Confirm and create

Show the full drafted update to the user and ask for confirmation. Include the proposed status (onTrack / atRisk / offTrack) and confirm which initiative it will be posted to.

Only after explicit user approval, use `save_status_update` with:

- `type`: "initiative"
- `initiative`: the initiative name/ID
- `health`: "onTrack" | "atRisk" | "offTrack"
- `body`: the update body in markdown

Report the result back to the user.
