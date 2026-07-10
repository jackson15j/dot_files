---
description: Fetch, assign a Linear issue, branch, implement and push a PR (subagent-orchestrated)
argument-hint: <linear-id> (e.g. COE-456)
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - Agent
  - Skill
  - mcp__linear-server__get_issue
  - mcp__linear-server__get_user
  - mcp__linear-server__list_issue_statuses
  - mcp__linear-server__save_issue
model: opus[1m]
---

The Linear issue ID is: $ARGUMENTS

> **sao variant** — same Linear→branch→implement→PR flow as v1/v2, but run as
> an ORCHESTRATION. You (Opus[1m]) stay a thin, coherent coordinator and push
> nearly all context-heavy work into disposable sub-agent contexts. This keeps
> your window clean over a long-horizon task instead of filling it with search
> output, noisy CLI logs, and mechanical edits. See
> https://www.humanlayer.dev/blog/long-context-isnt-the-answer

## Phase 0 — Load the orchestration skill (you do this directly)

Invoke the `subagent-orchestrator` skill FIRST. It sets the delegation rules
for every phase below. The user has already given you a task (this issue), so
proceed with it per the skill.

**Orchestrator discipline for the whole command:**
- Delegate all non-trivial operations to sub-agents. Reserve your own context
  for decisions, plan-holding, reading diffs, and review.
- Delegate research / codebase understanding to `codebase-locator`,
  `codebase-analyzer`, and `pattern-locator` sub-agents. If those agent types
  aren't registered in this harness, fall back to `Explore` (read-only search)
  for locate/pattern work and `general-purpose` for deeper analysis.
- Delegate noisy bash (anything likely to dump lots of output — `git`, `gh`,
  logs, `aws`, test runners) to `Bash` sub-agents so the raw output never lands
  in your window; ask them to return only a short structured summary.
- One sub-agent per non-overlapping task. Launch independent tasks in parallel,
  but NEVER split two tasks with significant overlap across separate agents —
  they'll duplicate work and produce conflicting edits.

## Phase 1 — Detect the repo's toolchain (dispatch to a research sub-agent)

Dispatch ONE sub-agent (Explore, or codebase-analyzer if available) to resolve
how THIS repo runs lint, tests, and E2E. Give it these instructions and ask for
a compact structured return — do not have it paste file contents back.

1. Read project conventions: `CLAUDE.md`, `AGENTS.md`, `.cursorrules`,
   `README.md` at the repo root. Extract documented commands for lint, unit
   tests, E2E, build, type-check, format, and any branch-naming convention. If
   none is documented, default branch format to
   `<type>/<linear-id-lower>_<kebab-slug>` (e.g. `feature/coe-456_add-excess`).
2. If conventions didn't specify commands, detect the toolchain:
   - `mise.toml` / `.mise.toml`          → likely `mise run <task>`
   - `Taskfile.yml`                      → likely `task <task>`
   - `Justfile`                          → likely `just <task>`
   - `Makefile`                          → check for `lint`/`test`/`e2e` targets
   - `package.json`                      → read `scripts` section
   - `pyproject.toml` / `poetry.lock`    → check for `poetry run` scripts
   - `Cargo.toml`                        → `cargo clippy` / `cargo test`
   - `go.mod` (nothing else detected)    → `go vet ./...` / `go test ./...`
3. Required return format (these are the only values you keep):
   - LINT_CMD, UNIT_TEST_CMD, E2E_TEST_CMD (may be empty), BRANCH_FORMAT.

If any critical command comes back ambiguous, ASK the user before proceeding.
Do NOT guess.

## Phase 2 — Linear + branch setup (dispatch to a Haiku sub-agent)

Dispatch a lightweight sub-agent (model: haiku) to do the noisy setup and
return only the resolved IDs and fetch result:

1. `get_user` (query: "me") → your user ID.
2. `list_issue_statuses` → "In Progress" status ID for the issue's team.
3. `save_issue` with `id: $ARGUMENTS`, `assignee: "me"`, state = In Progress.
4. `git fetch --all --prune`.

## Phase 3 — Plan + scope (you do this directly, on Opus[1m])

Planning is a decision, not a mechanical op — keep it in your own context so the
whole picture stays coherent.

1. `get_issue` with id `$ARGUMENTS`. Read title/description carefully.
2. Dispatch research sub-agents (in parallel, non-overlapping slices) to build
   the context you need to plan well — e.g. one `codebase-locator`/`Explore` to
   find the files and entry points the issue touches, one
   `codebase-analyzer`/`general-purpose` to explain how the relevant subsystem
   works, one `pattern-locator` to find existing patterns to mirror. Give each a
   distinct question. Consolidate their short returns yourself.
3. Ask the user clarifying questions until 95% confident on scope.
4. Enter plan mode. Present the implementation plan for approval.
5. **Size check — split before you build.** If the change is cross-cutting
   (touches >~15 files, or multiple apps/products + a shared contract + docs),
   plan it as a STACK of small PRs, not one. A good default split for a
   shared-contract change: (a) shared spec/contract + codegen, (b) per-product
   backend(s), (c) shared FE threading, (d) docs + hand-maintained fixtures.
   State the chosen split in the plan.
6. After approval, have a `Bash` sub-agent create the branch and confirm:
   `git checkout -b <branch-name> origin/main`.

## Phase 4 — Implementation (delegate by non-overlapping slice)

Decompose the approved plan into non-overlapping work slices, then delegate.
Follow the orchestrator rule: parallel where slices don't overlap, sequential
where a later slice depends on an earlier one's output.

- **Delegate to a Sonnet[1m] sub-agent** (Agent tool, `subagent_type:
  general-purpose`, `model: sonnet[1m]`): each self-contained implementation
  slice, and all mechanical breadth (regenerating generated files, doc sweeps,
  repetitive per-product edits following an already-decided pattern).
- **Keep in your own context only** the small set of semantically deep / high-
  risk decisions where one context must hold the whole picture (contract shapes,
  custom-decoder/middleware interactions, nil-able types). Don't delegate
  *understanding* — if you delegate an edit, you still own reviewing it.

For every delegated slice, build a SELF-CONTAINED prompt that includes:
- The full approved plan (and which slice of the stack this is).
- The Linear issue title + description.
- The branch name being worked on.
- The literal commands from Phase 1:
    - "Run lint with: <LINT_CMD>"
    - "Run unit tests with: <UNIT_TEST_CMD>"
- Explicit rules:
    - Implement this slice as written; flag any deviation in your summary.
    - Run lint and unit tests; fix failures.
    - Commit locally using Conventional Commits style.
    - Do NOT push. Do NOT open a PR.
- Required return format: files changed, tests passed, deviations from plan.

**After a sub-agent returns, READ THE ACTUAL CHANGED HUNKS** for every risky
file it touched (`git diff` — via a `Bash` sub-agent if the diff is large,
otherwise directly), not just its summary. A summary describes intent; you are
accountable for the code. If a slice is incomplete or wrong:
  (a) dispatch a follow-up Agent with a corrected brief, or
  (b) use SendMessage to resume the same agent with steering.

## Phase 5 — Adversarial self-review BEFORE first push (you do this, Opus[1m])

1. Invoke `/cr-v2` against `origin/main` and clear every finding — treat its
   smell catalogue as a hard checklist (substring-matching structured data,
   nil-map writes, tests that reimplement the code, generated files not
   regenerated, renamed paths still referenced, custom decoders on touched
   routes, contract divergence across sibling apps).
2. Fix the CLASS, not the cited line.
3. Only proceed once a second automated review would plausibly find nothing.

Delegate any noisy verification bash (re-running lint/tests to confirm the
fixes) to a `Bash` sub-agent that returns only pass/fail + failure detail.

## Phase 6 — E2E gate (only if E2E_TEST_CMD was detected)

Dispatch an Agent (general-purpose, model: sonnet[1m]) with prompt:
  "Run `<E2E_TEST_CMD>` and return only pass/fail plus full details on any
   failure. Do not summarize passing tests beyond a count."

**Representativeness:** the gate MUST exercise each app's REAL entry path (e.g.
each product's actual create route), not just one app's. A contract change that
only one sibling app hits will pass a narrow gate and fail in CI. If the suite
has a KNOWN flake, run it in isolation / retry it so a flake can never mask a
real failure — and never conflate "flake re-run passed" with "the real failures
are fixed".

Only proceed past this phase if E2E passes. If E2E couldn't be run (e.g. Docker
unavailable), tell the user and ask whether to push anyway. Do NOT push or open
a PR until E2E has actually passed in this session.

If E2E_TEST_CMD is empty (repo has no E2E), skip this phase.

## Phase 7 — Ship (you do this directly, on Opus[1m])

(Review already happened in Phase 5 — do not defer it to here.)

1. Delegate to a `Bash` sub-agent: `git push -u origin <branch-name>` and
   `gh pr create` with a title and description covering full scope + test plan.
   The test plan MUST list which commands were actually run and passed (the
   resolved LINT_CMD, UNIT_TEST_CMD, and E2E_TEST_CMD if applicable) — only
   tick a check once it has actually passed. Have the sub-agent return the PR
   URL.
   - PR Title format: `<conventional_commit_topic>: <issue ID> - <title>`.
2. **Keep the branch short-lived.** If the PR will live more than a day, rebase
   (don't merge) `origin/main` in regularly. After any rebase that pulls in new
   work, re-run Phase 6's E2E gate.
3. When review comments arrive, address them via `/cr-v2` (fix-the-class +
   reply-with-reason + resolve-thread), delegating the mechanical edits to
   sub-agents as in Phase 4.
