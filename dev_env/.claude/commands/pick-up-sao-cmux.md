---
description: Fetch, assign a Linear issue, branch, implement and push a PR (agent-teams / cmux panes)
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

> **cmux / agent-teams variant** — same Linear→branch→implement→PR flow as
> `pick-up-sao`, but the parallel, independent work is run by **agent-team
> TEAMMATES** (each a full, independent Claude Code session) instead of the
> `Agent` subagent tool. When launched via `cmux claude-teams`, teammates spawn
> in **real cmux panes** you can watch and steer live. You (Opus[1m]) stay the
> LEAD: a thin, coherent coordinator that holds the plan, reviews diffs, and
> gates the ship. Noisy one-shot work (git/gh/log capture) stays on the `Agent`
> subagent tool — a pane for a git-log dump is pointless.
>
> **This v1 mapping is PROVISIONAL.** It mirrors the phases of `pick-up-sao` so
> behaviour is directly comparable. After one real run in cmux, revisit whether
> to push more phases onto teammates, use a research/review-only team, or keep
> implementation on the lead. See
> https://www.humanlayer.dev/blog/long-context-isnt-the-answer

## Phase 0 — Launch & environment preconditions (you do this FIRST, directly)

This command only produces panes when it runs inside a `cmux claude-teams`
session, **started from inside a cmux terminal pane** (not an external terminal,
and not the Spotlight-launched cmux GUI with no shell — Spotlight opens the app;
the command must run in a pane so the shim has a "current pane" to split from).

Recommended launch:
1. Open a cmux workspace — either `cmux ~/work/nextgen/quote-request-api-worktree`
   from any terminal, or open cmux via Spotlight and `cd` inside one of its panes.
2. Inside a cmux pane: `cd` to the worktree, then run
   `cmux claude-teams --teammate-mode auto`.
3. In that session, run `/pick-up-sao-cmux COE-xxxx`.

Before spawning any teammates, VERIFY you are in a teams-capable session. Run:

```bash
echo "AGENT_TEAMS=${CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS:-<unset>} TMUX=${TMUX:-<unset>} TMUX_PANE=${TMUX_PANE:-<unset>}"
```

- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` must be `1` (teams enabled).
- `TMUX` and `TMUX_PANE` must be set (the `cmux claude-teams` shim sets these).

If any are unset, STOP and tell the user to relaunch via
`cmux claude-teams --teammate-mode auto` from inside a cmux pane. Do NOT silently
fall back to subagents — the whole point of this variant is live panes.

Note on panes: split panes require `teammateMode` to be `tmux` or `auto`. The
shim provides a tmux-like env, so `auto` selects split panes. If teammates only
appear as agent-panel rows (not new cmux panes), the session is in-process —
relaunch with `--teammate-mode auto` (or set `"teammateMode": "auto"` in
`~/.claude/settings.json`).

## Phase 0.5 — Teams discipline (applies to every phase below)

- **Teammates vs subagents:** use **teammates** (spawn via natural-language
  instruction, e.g. "Spawn a teammate named `researcher` to …") for independent,
  parallel work you want to see in panes. Use the **`Agent` subagent tool** ONLY
  for noisy bash that should NOT occupy a pane (git/gh/test-log capture returning
  a short summary).
- **Name every teammate** in the spawn instruction so it's addressable later
  (steer, ask follow-ups, or shut down by name).
- **Give each teammate full context.** Teammates do NOT inherit your conversation
  history. They DO load CLAUDE.md, skills, and MCP servers. Put everything the
  slice needs into the spawn prompt (plan, issue text, branch, literal commands,
  rules, return format).
- **Non-overlapping file ownership.** Two teammates editing the same file will
  overwrite each other. Give each a distinct file set.
- **Wait for teammates to finish** before you proceed or mark work done. If you
  catch yourself implementing a teammate's task, stop and let them do it.
- **Shut teammates down by name** once their slice is complete.
- **Team size 3–5.** Don't over-shard; coordination overhead scales with count.
- **You still own the code.** Delegating an edit does not delegate the review —
  read the actual changed hunks yourself.

## Phase 1 — Detect the repo's toolchain (Agent subagent, NOT a teammate)

A quick one-shot lookup — a pane adds nothing, so keep this as a single `Agent`
subagent (`Explore`, or codebase-analyzer if available). Give it these
instructions and ask for a compact structured return — do not have it paste file
contents back.

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

## Phase 2 — Linear + branch setup (Agent subagent, NOT a teammate)

Mechanical setup, no pane needed. Dispatch a lightweight `Agent` subagent
(model: haiku) to do the noisy setup and return only the resolved IDs and fetch
result:

1. `get_user` (query: "me") → your user ID.
2. `list_issue_statuses` → "In Progress" status ID for the issue's team.
3. `save_issue` with `id: $ARGUMENTS`, `assignee: "me"`, state = In Progress.
4. `git fetch --all --prune`.

## Phase 3 — Plan + scope (you plan directly; research via TEAMMATES)

Planning is a decision, not a mechanical op — keep it in your own context so the
whole picture stays coherent. Research, however, is the canonical "research team"
use case and benefits from panes.

1. `get_issue` with id `$ARGUMENTS`. Read title/description carefully.
2. **Spawn research TEAMMATES** (in parallel, non-overlapping slices) to build
   the context you need to plan well. Name them and give each a distinct
   question — for example:
   - `locator` — "Find the files and entry points this issue touches: <issue
     summary>. Return a short list of paths with one-line notes."
   - `analyzer` — "Explain how <relevant subsystem> works, focusing on <area>.
     Return a compact explanation, no file dumps."
   - `patterns` — "Find existing patterns to mirror for <change type>. Return
     representative file paths + the pattern in a sentence each."
   Consolidate their short returns yourself. Shut them down once consolidated.
   (If the session turned out NOT to be teams-capable — see Phase 0 — fall back
   to `Explore`/`general-purpose` subagents, but tell the user panes are off.)
3. Ask the user clarifying questions until 95% confident on scope.
4. Call the `EnterPlanMode` tool FIRST to enter plan mode. Only after that,
   present the implementation plan and call `ExitPlanMode` to request approval.
   (`ExitPlanMode` errors with "You are not in plan mode" if you skip the
   `EnterPlanMode` step — never call it before entering plan mode.)
5. **Size check — split before you build.** If the change is cross-cutting
   (touches >~15 files, or multiple apps/products + a shared contract + docs),
   plan it as a STACK of small PRs, not one. A good default split for a
   shared-contract change: (a) shared spec/contract + codegen, (b) per-product
   backend(s), (c) shared FE threading, (d) docs + hand-maintained fixtures.
   State the chosen split in the plan.
6. After approval, have an `Agent` (Bash) subagent create the branch and confirm:
   `git checkout -b <branch-name> origin/main`.

## Phase 4 — Implementation (one TEAMMATE per non-overlapping slice)

Decompose the approved plan into non-overlapping work slices, then spawn **one
named teammate per slice** so each opens its own pane. Parallel where slices
don't overlap; sequential where a later slice depends on an earlier one's output.
Enforce non-overlapping FILE ownership per teammate (docs stress: two teammates
editing the same file overwrite each other).

- **Spawn a TEAMMATE** for each self-contained implementation slice, and for
  mechanical breadth (regenerating generated files, doc sweeps, repetitive
  per-product edits following an already-decided pattern). Tell each teammate to
  use Sonnet if you want to control cost (set the default teammate model, or say
  so in the spawn prompt).
- **Keep in your own context only** the small set of semantically deep / high-
  risk decisions where one context must hold the whole picture (contract shapes,
  custom-decoder/middleware interactions, nil-able types). Don't delegate
  *understanding* — if you delegate an edit, you still own reviewing it.

For every teammate slice, build a SELF-CONTAINED spawn prompt that includes:
- The full approved plan (and which slice of the stack this is).
- The Linear issue title + description.
- The branch name being worked on.
- The exact set of files this teammate owns (and that it must NOT touch others).
- The literal commands from Phase 1:
    - "Run lint with: <LINT_CMD>"
    - "Run unit tests with: <UNIT_TEST_CMD>"
- Explicit rules:
    - Implement this slice as written; flag any deviation in your summary.
    - Run lint and unit tests; fix failures.
    - Commit locally using Conventional Commits style.
    - Do NOT push. Do NOT open a PR.
- Required return format: files changed, tests passed, deviations from plan.

**After a teammate reports done, READ THE ACTUAL CHANGED HUNKS** for every risky
file it touched (`git diff` — via an `Agent` Bash subagent if the diff is large,
otherwise directly), not just its message. A summary describes intent; you are
accountable for the code. If a slice is incomplete or wrong:
  (a) message the teammate by name with a corrected brief and let it revise, or
  (b) shut it down and spawn a replacement teammate with a sharper brief.

Wait for all implementation teammates to finish before moving on. Shut down each
teammate once its slice is reviewed and accepted.

## Phase 5 — Adversarial self-review BEFORE first push (you do this, Opus[1m])

Keep this on the lead for the first test run to reduce moving parts. (Later, this
could become a review teammate — decide after watching a run.)

1. Invoke `/cr-v2` against `origin/main` and clear every finding — treat its
   smell catalogue as a hard checklist (substring-matching structured data,
   nil-map writes, tests that reimplement the code, generated files not
   regenerated, renamed paths still referenced, custom decoders on touched
   routes, contract divergence across sibling apps).
2. Fix the CLASS, not the cited line.
3. Only proceed once a second automated review would plausibly find nothing.

Delegate any noisy verification bash (re-running lint/tests to confirm the
fixes) to an `Agent` Bash subagent that returns only pass/fail + failure detail.

## Phase 6 — E2E gate (only if E2E_TEST_CMD was detected)

Dispatch an `Agent` subagent (general-purpose, model: sonnet[1m]) with prompt:
  "Run `<E2E_TEST_CMD>` and return only pass/fail plus full details on any
   failure. Do not summarize passing tests beyond a count."

(Keep E2E as a subagent, not a teammate — it's a noisy one-shot verification, not
collaborative work. Its multi-thousand-token output should never land in your
window or a pane you have to watch.)

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

1. Delegate to an `Agent` Bash subagent: `git push -u origin <branch-name>` and
   `gh pr create` with a title and description covering full scope + test plan.
   The test plan MUST list which commands were actually run and passed (the
   resolved LINT_CMD, UNIT_TEST_CMD, and E2E_TEST_CMD if applicable) — only
   tick a check once it has actually passed. Have the subagent return the PR URL.
   - PR Title format: `<conventional_commit_topic>: <issue ID> - <title>`.
2. **Keep the branch short-lived.** If the PR will live more than a day, rebase
   (don't merge) `origin/main` in regularly. After any rebase that pulls in new
   work, re-run Phase 6's E2E gate.
3. When review comments arrive, address them via `/cr-v2` (fix-the-class +
   reply-with-reason + resolve-thread), delegating the mechanical edits to
   teammates (or subagents) as in Phase 4.

## Experimental limitations to expect while testing

Agent teams are experimental. Be aware during this test run:
- **No session resumption of in-process teammates.** `/resume` and `/rewind` do
  not restore teammates; after resuming, the lead may try to message teammates
  that no longer exist — spawn fresh ones if so.
- **Task status can lag.** Teammates sometimes fail to mark tasks complete,
  blocking dependents. Nudge the teammate or update status manually.
- **Shutdown can be slow.** Teammates finish their current tool call before
  exiting.
- **Higher token cost** than the `pick-up-sao` subagent variant — each teammate
  is a full Claude session with its own context window.
- **One team per session, no nested teams** — teammates cannot spawn their own
  teammates; only you (the lead) manage the team.
- **Split panes** are normally unsupported in VS Code's integrated terminal,
  Windows Terminal, and Ghostty native — but via `cmux claude-teams` the panes
  are cmux's own (routed through the shim → cmux socket), so pane spawning is
  cmux's responsibility, not the host terminal's.
