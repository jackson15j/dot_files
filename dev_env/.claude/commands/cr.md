---
name: cas code review
model: opus[1m]
description: Thorough code review
---

Use sub-agents as needed.

Code review my current git branch against `${ARGUMENTS:-origin/main}`

If a PR has been raised; check comments and either fix or comment with
a reason before resolving. When resolving. make sure you add a reason
and also mark the comment as resolved, so that it is not left in an
open state.
