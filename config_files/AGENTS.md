# Agent instructions

Global preferences, loaded for every project via ~/.claude/CLAUDE.md.

## Git commits

- Only commit when explicitly asked to ("commit" / "commit this") - never commit proactively.
- Scope commits to what was just discussed or implemented. Don't sweep in unrelated
  pre-existing uncommitted changes unless asked to include them too.
- Do not add Claude, or any other agent, as a co-author/co-committer on commits.

## Ticket-based branches

Some projects use a ticket-number branch/commit convention. It applies when the current
branch name starts with 3-4 capital letters, a dash, and 1-6 digits (e.g. `NERD-1234` in
`NERD-1234-hello_there`, or `APP-23` in `APP-23_more_stuff`) - that leading
`LETTERS-NUMBERS` segment is the ticket number.

When it applies:
- Prefix every commit message with the ticket number.
- Before committing, group the changes into logical chunks and commit each chunk
  separately, rather than one large commit.
- Still never commit without a specific ask from the user (see Git commits above).

## Pushing and pull requests

- Never push without a specific request from the user.
- On the first push of a branch, open a PR.
- PRs are always drafts.
- Always use the repo's default PR description template - don't write a custom
  summary/test-plan body.

## Writing QA steps

When writing QA/test-plan steps for new code, there are three main ways to exercise it -
pick whichever fits the change:
1. Through the UI.
2. Via a REPL (iex, irb, or the language's equivalent).
3. Via API endpoints (SwaggerUI or a similar tool).

Keep the instructions simple, and include all setup needed to actually follow them (seed
data, env vars, how to start the REPL/server, etc.) - don't assume prior context.

## Planning feature requirements

When given a feature requirement to plan, review it skeptically rather than taking it at
face value:
- Look for missed items, edge cases, and inconsistencies.
- Ask questions about anything unclear.
- Make sure we're on the same page before moving to implementation.

## Installing tools, plugins, and dependencies

- Check stated requirements (version minimums, auth, platform support) against the actual
  environment before installing.
- If something looks incompatible or restricted (e.g. platform-gated to an OS this machine
  isn't), stop and ask how to proceed rather than forcing a workaround.

## Working in an existing codebase

- Match the codebase's existing conventions (function/file structure, comment style
  explaining *why* not *what*) instead of introducing a new style.

## Verifying claims

- Before repeating a claim about a fast-moving tool or product (especially one sourced from
  a subagent or web search), cross-check it against an authoritative/current source if the
  claim is consequential enough to act on.

## Repo-specific conventions

Only apply within the named repo, except bdavi/dotfiles below, which is checked for
regardless of which repo you're actively working in.

### Comoto-Tech/monorepo

- When creating a PR, add the `create staging` and `Team Rohan` labels at creation time
  (e.g. `gh pr create --label "create staging" --label "Team Rohan" ...`), not after.
  `create staging` affects CI behavior and must be present before the first CI run kicks
  off, so it can't be added as a follow-up edit.

#### Worktree dev environments (`w*` commands)

Only on the work dev box. The monorepo also runs as git worktrees under
`~/worktrees/<letter>` alongside the primary checkout at `~/monorepo`, each with
its own containers (`wt<letter>-*`) and URLs
(`https://<letter>-{rz,cg,jp}.devzla.com`), managed by the `w*` shell commands
(`wnew`, `wdel`, `wls`, `wdc`, `wcg-bash`, ...) from
`~/.monorepo-worktrees/functions.sh`. Docs live next to it: `CHEATSHEET.md`
(command reference), `README.md` (how it fits together), `NOTES.md` (full design
record - constraints, evidence, rejected approaches). Read those before changing
the tooling; update them when you do.

- Inside a worktree, never run bare `docker compose` - it would try to boot a
  second full stack. Use `wdc`, which scopes compose to the worktree's generated
  files in `~/.local/share/wt/<letter>/`. `compose.yaml` there is machine-owned
  (rewritten by `wregen`); hand edits belong in `compose.override.yaml`.
- The `w` prefix is load-bearing: `wcg-bash`/`wcg-log`/`wcg-iex` target the
  worktree's container, while the unprefixed `cg-*` twins target the shared
  primary stack. One letter is the only difference.
- Postgres, redis, rabbitmq, and elasticsearch are shared with the primary
  stack. Migrations and test-schema rebuilds (`welts`/`wclts`) therefore touch
  shared state - time them deliberately, and say so before running one.
- A worktree's identity is its directory (slot letter), never its branch -
  branches can be switched inside a worktree. `wls` is the only letter -> branch
  map.

### bdavi/dotfiles

- Whenever installing a tool or application on a dev box - even one needed for a
  completely different project (e.g. installing Playwright for that project's tests) -
  check whether this repo is present (working in it, or checked out elsewhere on the
  machine). If so, ask the user whether they want it permanently added to
  `scripts/dev_box/build_ubuntu.sh` (via a new or updated `lib/*.sh` helper, matching the
  existing pattern) so it's provisioned automatically on future dev box builds. Don't add
  it without asking.
