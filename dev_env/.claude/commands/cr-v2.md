---
name: cas code review v2
model: opus[1m]
description: Thorough code review (adversarial pre-push variant)
---

Use sub-agents as needed.

Code review my current git branch against `${ARGUMENTS:-origin/main}`

If a PR has been raised; check comments and either fix or comment with
a reason before resolving. When resolving. make sure you add a reason
and also mark the comment as resolved, so that it is not left in an
open state.

---

## How to run this review

This variant exists to catch, in ONE pass, the class of defects that an
automated reviewer (Copilot) would otherwise surface across multiple rounds.
Each extra review round costs a push + CI cycle + context-switch, so the goal
is zero foreseeable findings left for the bot.

### Step 1 — Get the real diff, not a summary

Run `git diff ${ARGUMENTS:-origin/main}...HEAD` and read the actual changed
hunks. If the implementation was done by sub-agents, you MUST read the changed
hunks yourself for every RISKY file (see Step 3) — a sub-agent's summary
describes intent, not the code that landed. "The agent said it fixed X" is not
evidence X is fixed.

For a large diff (>~20 files), dispatch one read-only sub-agent PER risky file
with the smell catalogue below, and review breadth (docs, generated files,
test collections) yourself. Do not let any single summary stand in for reading
the code on a risky file.

### Step 2 — Hunt the smell catalogue (adversarial pass)

Be the hostile reviewer. For every changed file, actively look for these —
they are the recurring, foreseeable findings, not exotic edge cases:

- **Substring-matching structured data** — `strings.Contains(jsonBody, "key")`,
  regexing JSON/YAML/XML, `.includes('"field"')`. Parse it and check the real
  key/shape instead. (A value containing the word can false-match.)
- **Writing to a possibly-nil map / deref of a maybe-nil pointer** — in Go,
  `json.Unmarshal([]byte("null"), &m)` SUCCEEDS leaving `m == nil`; the next
  `m[k] = v` panics. Guard `== nil` before writing. Same scrutiny for any
  pointer a decoder may leave unset.
- **Tests that reimplement or import the code under test** — a test that copies
  the component's expressions into local helpers, or only asserts on a mock,
  cannot fail when the real code breaks. The test must exercise the actual
  symbol.
- **Generated files not regenerated** — if a spec/schema/`*.gen.*`/bundled-doc
  has a hand-edited source, confirm the generated output was re-run and
  committed. Grep for the codegen task and diff its output.
- **Renamed/removed path still referenced** — after any rename or refactor,
  grep the WHOLE repo (docs, READMEs, CLAUDE.md, configs, fixtures, test
  collections) for every old identifier/path. Zero misses. (This is already a
  standing CLAUDE.md rule — enforce it here.)
- **Custom decoders / middleware on any route you touched** — if a handler
  reads a request body, find HOW that body is decoded. A custom decoder
  (streaming, null-sanitising, partial-decode) can make field order or a bad
  array item change what your handler sees. If you touched a body field, trace
  the decode path and ask "what input shape breaks this?"
- **Contract divergence across siblings** — if multiple apps/products share a
  client but hit different routes, confirm EVERY route accepts the one body
  shape the shared client sends. (Mismatched create routes = a 400 only one
  app hits.)
- **Latent paths activated by main** — if `origin/main` moved under this branch,
  check whether merged work now exercises a code path this PR changed but never
  ran (e.g. a validation route a feature flag just enabled).

### Step 3 — Classify each changed file by risk

- **RISKY** (read every hunk yourself, reason adversarially): anything with
  branching logic, body/decode handling, shared contracts, test helpers that
  inject defaults, nil-able types, concurrency.
- **MECHANICAL** (skim): regenerated files, doc sweeps, REST-client collection
  edits, formatting. Still confirm they were actually regenerated/complete.

### Step 4 — Fix the CLASS, not the comment

When you (or the bot) find a defect in a function/helper, rewrite that unit to
be correct for ALL inputs in one go — do not patch only the cited path. The
expensive pattern is: narrow fix → bot finds the next narrow gap in the same
file → another round. Ask "what is the full contract of this function, and
does it hold for null / empty / wrong-type / wrong-order input?" and satisfy
that contract once.

### Step 5 — Verify, then reply + resolve

- Verify each finding empirically before acting (reproduce, or trace the code).
  If a finding is wrong, say so with the evidence rather than churning a change.
- For each PR comment: fix it OR reply with a concrete reason. When resolving,
  add the reason AND mark the thread Resolved (GraphQL `resolveReviewThread`)
  so nothing is left open.
- Before declaring done: re-read the risky hunks once more and confirm the
  smell catalogue is clean. The bar is "a second automated review would find
  nothing new."
