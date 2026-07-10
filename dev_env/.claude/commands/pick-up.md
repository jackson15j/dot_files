---
description: Fetch, assign a Linear issue, branch, implement and push a PR
argument-hint: <linear-id> (e.g. COE-456)
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Agent
  - mcp__linear-server__get_issue
  - mcp__linear-server__get_user
  - mcp__linear-server__list_issue_statuses
  - mcp__linear-server__save_issue
model: opus[1m]
---

The Linear issue ID is: $ARGUMENTS

## Phase 0 — Detect the repo's toolchain (you do this directly, on Opus[1m])

Before doing anything else, figure out how THIS repo runs lint, tests, and
E2E. Resolve concrete commands once and reuse them in later phases.

1. Read project conventions:
   - Check for `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, or `README.md` at
     the repo root. Extract any documented commands for: lint, unit tests,
     E2E tests, build, type-check, format.
   - Check for a branch-naming convention. If none is documented, default
     to: `<type>/<linear-id-lower>_<kebab-slug>` (e.g.
     `feature/coe-456_add-excess-options`).

2. If CLAUDE.md/AGENTS.md didn't specify commands, detect the toolchain:
   - `mise.toml` / `.mise.toml`           → likely `mise run <task>`
   - `Taskfile.yml`                       → likely `task <task>`
   - `Justfile`                           → likely `just <task>`
   - `Makefile`                           → check for `lint`/`test`/`e2e` targets
   - `package.json`                       → read `scripts` section
   - `pyproject.toml` / `poetry.lock`     → check for `poetry run` scripts
   - `Cargo.toml`                         → `cargo clippy` / `cargo test`
   - `go.mod` (no other runner detected)  → `go vet ./...` / `go test ./...`

3. Resolve and record these four values (some may be empty):
   - LINT_CMD       (e.g. `mise run //home:lint`, `npm run lint`, `cargo clippy`)
   - UNIT_TEST_CMD  (e.g. `mise run //home:test`, `npm test`, `go test ./...`)
   - E2E_TEST_CMD   (may be empty — not all repos have E2E)
   - BRANCH_FORMAT  (template string with placeholders for type/id/slug)

4. If any critical command is ambiguous, ASK the user before proceeding.
   Do NOT guess.

## Phase 1 - Linear + branch setup (dispatch to a Haiku subagent)

1. `get_user` (query: "me") → your user ID.
2. `list_issue_statuses` → find "In Progress" status ID for the issue's team.
3. `save_issue` with `id: $ARGUMENTS`, `assignee: "me"`, state = In Progress.
4. `git fetch --all --prune`.

## Phase 2 — Linear + branch setup (you do this directly, on Opus[1m])

1. `get_issue` with id `$ARGUMENTS`. Read title/description carefully.
2. Ask clarifying questions until 95% confident on scope.
3. Enter plan mode. Present the implementation plan for approval.
4. After approval, create branch from `origin/main` using BRANCH_FORMAT:
   `git checkout -b <branch-name> origin/main`

## Phase 3 — Implementation (dispatch to a Sonnet[1m] subagent)

Use the Agent tool with `subagent_type: general-purpose` and `model: sonnet[1m]`.

Build a SELF-CONTAINED prompt that includes:
- The full approved plan from Phase 1
- The Linear issue title + description
- The branch name being worked on
- The literal commands resolved in Phase 0:
    - "Run lint with: <LINT_CMD>"
    - "Run unit tests with: <UNIT_TEST_CMD>"
- Explicit rules:
    - Implement the plan as written; flag any deviation in your summary
    - Run lint and unit tests; fix failures
    - Commit locally using Conventional Commits style
    - Do NOT push. Do NOT open a PR.
- Required return format: files changed, tests passed, deviations from plan

After the subagent returns, review the summary. If incomplete or wrong:
  (a) dispatch a follow-up Agent with a corrected brief, or
  (b) use SendMessage to resume the same agent with steering.

## Phase 4 — E2E gate (only if E2E_TEST_CMD was detected)

Dispatch another Agent (general-purpose, model: sonnet[1m]) with prompt:
  "Run `<E2E_TEST_CMD>` and return only pass/fail plus full details on
   any failure. Do not summarize passing tests beyond a count."

Only proceed to Phase 4 if E2E passes. If E2E couldn't be run (e.g. Docker
unavailable), tell the user and ask whether to push anyway.

If E2E_TEST_CMD is empty (repo has no E2E), skip this phase.

## Phase 5 — Review + ship (you do this directly, on Opus[1m])

1. Invoke the `/cr` skill against `origin/main`.
2. `git push -u origin <branch-name>`.
3. `gh pr create` with title and description covering full scope + test plan.
   The test plan MUST list which commands were actually run and passed
   (the resolved LINT_CMD, UNIT_TEST_CMD, and E2E_TEST_CMD if
   applicable).
   - PR Title format: `<conventional_commit_topic>: <issue ID> - <title>`.
