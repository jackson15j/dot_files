- `git fetch` and check `origin/main`/`origin/master` before
  investigations/deep-dives/research/implementation tasks.
- Interview User to 95% confidence when planning.
- Do not write auth tokens (eg. $GITHUB_TOKEN, $AUTH_TOKEN resolution in .npmrc) into Claude logs/sessions/projects or remote calls.

## Patterns/Principles

- TDD
- Red, Green, Refactor
- Event Driven Design
- Contracts driven
- YAGNI
- No Code Comments (Design/ Business Logic / Intent in `docs/*.md` or DocStrings).
- If you need a paragraph-long comment to justify why the workaround is OK, the code is wrong — fix the code.

### Avoid permission requests

- Use: `git -C <path> <command>` instead of: `cd <path>; git <command>`
- Don't: `cd </path/to/current_workspace>`
