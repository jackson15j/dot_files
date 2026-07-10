---
description: Fetch, assign a Linear issue, branch, implement and push a PR (v2)
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

> **v2 changes vs v1** (see Phase notes): risk-based Opus/Sonnet split instead
> of phase-based; an adversarial self-review BEFORE first push; a
> representative E2E gate that exercises each app's real create route; and
> explicit "split a big cross-cutting change into a stack" guidance.

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

## Phase 2 — Plan + scope (you do this directly, on Opus[1m])

1. `get_issue` with id `$ARGUMENTS`. Read title/description carefully.
2. Ask clarifying questions until 95% confident on scope.
3. Enter plan mode. Present the implementation plan for approval.
4. **Size check — split before you build.** If the change is cross-cutting
   (touches >~15 files, or multiple apps/products + a shared contract + docs),
   plan it as a STACK of small PRs, not one. A good default split for a
   shared-contract change:
     (a) shared spec / contract + codegen,
     (b) per-product backend(s),
     (c) shared FE threading,
     (d) docs + hand-maintained fixtures/REST collections.
   Smaller surfaces get reviewed in one round; one product's bug no longer
   re-triggers review of all three. State the chosen split in the plan.
5. After approval, create branch from `origin/main` using BRANCH_FORMAT:
   `git checkout -b <branch-name> origin/main`

## Phase 3 — Implementation (risk-based delegation, NOT phase-based)

Delegate by RISK, not by "all implementation goes to a sub-agent":

- **Keep on Opus[1m], edit directly:** the semantically deep / high-risk pieces
  — contract shapes, custom-decoder or middleware interactions, nil-able types,
  test helpers that inject defaults, anything where one context needs to hold
  the whole picture. These are exactly the files that cause repeat review
  rounds when reviewed via summary.
- **Delegate to a Sonnet[1m] sub-agent** (Agent tool, `subagent_type:
  general-purpose`, `model: sonnet[1m]`): mechanical breadth — regenerating
  generated files, doc sweeps, updating hand-maintained REST-client
  collections, repetitive per-product edits that follow an already-decided
  pattern.

For any delegated work, build a SELF-CONTAINED prompt that includes:
- The full approved plan (and which slice of the stack this is)
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

**After a sub-agent returns, READ THE ACTUAL CHANGED HUNKS for every risky
file it touched** (`git diff`), not just its summary. A summary describes
intent; you are accountable for the code. If incomplete or wrong:
  (a) dispatch a follow-up Agent with a corrected brief, or
  (b) use SendMessage to resume the same agent with steering.

## Phase 3.5 — Adversarial self-review BEFORE first push (you do this, Opus[1m])

This is the new gate that prevents pushing red / leaving findings for the bot.

1. Invoke `/cr-v2` against `origin/main` and clear every finding it raises —
   treat its smell catalogue as a hard checklist (substring-matching
   structured data, nil-map writes, tests that reimplement the code, generated
   files not regenerated, renamed paths still referenced, custom decoders on
   touched routes, contract divergence across sibling apps).
2. Fix the CLASS, not the cited line (see /cr-v2 Step 4).
3. Only proceed once a second automated review would plausibly find nothing.

## Phase 4 — E2E gate (only if E2E_TEST_CMD was detected)

Dispatch an Agent (general-purpose, model: sonnet[1m]) with prompt:
  "Run `<E2E_TEST_CMD>` and return only pass/fail plus full details on
   any failure. Do not summarize passing tests beyond a count."

**Representativeness:** the gate MUST exercise each app's REAL entry path
(e.g. each product's actual create route), not just one app's. A contract
change that only one sibling app hits will pass a narrow gate and fail in CI.
If the suite has a KNOWN flake, run it in isolation / retry it so a flake can
never mask a real failure — and never conflate "flake re-run passed" with
"the real failures are fixed" (they are different defects).

Only proceed past this phase if E2E passes. If E2E couldn't be run (e.g. Docker
unavailable), tell the user and ask whether to push anyway. Do NOT push or open
a PR until E2E has actually passed in this session.

If E2E_TEST_CMD is empty (repo has no E2E), skip this phase.

## Phase 5 — Ship (you do this directly, on Opus[1m])

(Review already happened in Phase 3.5 — do not defer it to here.)

1. `git push -u origin <branch-name>`.
2. `gh pr create` with title and description covering full scope + test plan.
   The test plan MUST list which commands were actually run and passed
   (the resolved LINT_CMD, UNIT_TEST_CMD, and E2E_TEST_CMD if applicable) —
   only tick a check once it has actually passed.
   - PR Title format: `<conventional_commit_topic>: <issue ID> - <title>`.
3. **Keep the branch short-lived.** If the PR will live more than a day,
   rebase (don't merge) `origin/main` in regularly so latent interactions
   surface early rather than detonating near the end. After any rebase that
   pulls in new work, re-run Phase 4's E2E gate.
4. When review comments arrive, address them via `/cr-v2` (fix-the-class +
   reply-with-reason + resolve-thread).
