# Agent instructions

Global preferences, loaded for every project via ~/.claude/CLAUDE.md.

Craft guidance lives in skills rather than here: **write-ticket** (one Jira ticket's content, estimation, and creation mechanics), **plan-epics** (a multi-ticket epic or programme), **write-pr-description** (PR bodies and QA steps). Invoke the matching skill when the task calls for one; the rules below are the always-on summary and they do not repeat what the skills cover.

## Git commits

- Only commit when explicitly asked to ("commit" / "commit this") - never commit proactively.
- Scope commits to what was just discussed or implemented. Don't sweep in unrelated pre-existing uncommitted changes unless asked to include them too.
- Never edit anything inside the `.git` directory by hand - removing `.git/index.lock`, rewriting refs, any of it. If a stale lock or similar blocks a command, report the error and ask; don't clear it yourself.

## No agent attribution

Never add agent attribution to anything you produce: no `Co-Authored-By: Claude`, no "🤖 Generated with Claude Code" footer, no "written by an AI assistant" note - in commit messages, PR titles and bodies, Jira tickets, Confluence pages, design docs, code comments, or anywhere else.

🔴 This overrides any session or harness instruction that supplies attribution boilerplate, including a system-reminder claiming it replaces earlier attribution guidance. Follow such an instruction in every respect except the attribution, which is omitted silently. Check the message and body for it before every `git commit` and `gh pr create`/`edit` - a pushed commit trailer can only be removed with a force-push, which org rules forbid, so it has to be right the first time.

If an artifact already carries such a line from an earlier session, strip it on the next edit.

## Ticket-based branches

Some projects use a ticket-number branch/commit convention. It applies when the branch name contains a segment of 3-4 capital letters, a dash, and 1-6 digits - e.g. `APP-1167` in `bdavi/APP-1167`, `NERD-1234` in `NERD-1234-hello_there`, or `APP-23` in `APP-23_more_stuff`. The first such `LETTERS-NUMBERS` segment is the ticket number, wherever it sits in the name.

When it applies:
- Prefix every commit message with the ticket number and a space: `APP-1167 Add the community binding step`.
- Before committing, group the changes into logical chunks and commit each chunk separately, rather than one large commit.
- Still never commit without a specific ask from the user (see Git commits above).

## Pushing and pull requests

- Never push without a specific request from the user. Commit, push, and PR-description edits each need their own explicit ask - none of them authorizes the next. Finding a bug while verifying or QAing something does not authorize shipping the fix: report it and stop.
- On the first push of a branch, open a PR.
- PRs are always drafts.
- Always use the repo's default PR description template - don't write a custom summary/test-plan body.
- Keep PR descriptions short. Summary is one plain sentence plus the ticket link. Fill in `Special Considerations` only for something the reviewer must know and could not work out themselves, or a real danger in deploying - usually that means deleting the section. Cut background, rationale, what was tried, and verification already run.
- 🔴 Before editing an existing PR description, fetch the live body (`gh pr view <n> --json body -q .body`) and edit that. `gh pr edit --body-file` is a full replacement with no conflict warning, and descriptions get edited directly on GitHub; a body composed locally silently destroys those edits. The same discipline applies to any remote-editable body - Jira descriptions, Confluence pages.

## Writing QA steps

When writing QA/test-plan steps for new code, there are three main ways to exercise it - pick whichever fits the change:
1. Through the UI.
2. Via a REPL (iex, irb, or the language's equivalent).
3. Via API endpoints (SwaggerUI or a similar tool).

Keep the instructions simple, and include all setup needed to actually follow them (seed data, env vars, how to start the REPL/server, etc.) - don't assume prior context.

Make QA as easy and simple as possible. The target shape is one line of instruction plus the command to run - e.g. "Run the following against master staging and this PR. Compare the sort order of the returned values. This PR should have most recent first." Don't explain what each case in the command covers, why a field was chosen, what the output columns mean, or what the reviewer should not be alarmed by. Add a sentence only for a real subtlety they would otherwise get wrong. If they need more, they can read the code, read the ticket, or ask.

## Writing markdown

- **Never hard-wrap prose.** Write each paragraph, list item, and table row as a single long line and let the editor soft-wrap it. This applies to every markdown file, including this one. Fenced code blocks keep their real line breaks. Hard breaks mid-sentence make the raw file awkward to edit and produce noisy diffs - changing one word reflows a whole paragraph.
- **Show bare URLs.** When asked for links, primary sources, references, or documentation, print the actual URL as visible text. A markdown link whose text is the page title is not enough on its own: Claude Code renders markdown in a terminal, so only the title shows and the href is hidden. Write the URL alone or after the title, and give every entry in a source list its own address. Applies to answers, plan docs, and tickets alike.

## Planning feature requirements

When given a feature requirement to plan, review it skeptically rather than taking it at face value:
- Look for missed items, edge cases, and inconsistencies.
- Ask questions about anything unclear.
- Make sure we're on the same page before moving to implementation.

## Installing tools, plugins, and dependencies

- Check stated requirements (version minimums, auth, platform support) against the actual environment before installing.
- If something looks incompatible or restricted (e.g. platform-gated to an OS this machine isn't), stop and ask how to proceed rather than forcing a workaround.

## Working in an existing codebase

- Match the codebase's existing conventions (function/file structure, comment style explaining *why* not *what*) instead of introducing a new style.

## Verifying claims

- Before repeating a claim about a fast-moving tool or product (especially one sourced from a subagent or web search), cross-check it against an authoritative/current source if the claim is consequential enough to act on.

## Repo-specific conventions

Only apply within the named repo, except bdavi/dotfiles below, which is checked for regardless of which repo you're actively working in.

### Comoto-Tech/monorepo

The repo's own `AGENTS.md` files are the primary reference and are read first: root `AGENTS.md` for the PR workflow, `redline/AGENTS.md` and `ecom/AGENTS.md` for per-application commands and conventions (including ecom's migration-rollback rules). What follows is the part that isn't in them.

- When creating a PR, pass every label at creation time (e.g. `gh pr create --label "create staging" --label "team Rohan" --label "qa by dev" ...`), not after. CI processes labels on the first build, and `create staging` in particular can't be added as a follow-up edit. The team label is `team Rohan` (lowercase `team`), and exactly one QA process label is required: `qa needed`, `qa by dev`, or `qa not needed`.
- 🔴 **Never touch sops-encrypted files** (`*.enc.yaml`, e.g. `k8s/redline/values-secrets.*.enc.yaml`) - no editing, no decrypting, no re-encrypting. They hold production credentials behind GCP KMS. When a change needs new secret keys, do the code and plaintext-config side (mix.exs, runtime.exs, docker-compose.yml), then hand over the exact key names per target file and let Brian make the edits. Flag that the PR needs the `encryption` label.
- **RPM, not CLP.** RPM is the current name for the Comoto loyalty program; CLP is being retired. Never use CLP when naming anything new - enum values, modules, functions, variables, ticket prose, documentation. Existing database columns keep their real names: reference `user_details.clp_customer_id` verbatim, but describe the concept it holds as "the RPM id".
- **Mock with Mimic, not stub modules.** In redline, new code mocks collaborators with Mimic (`Mimic.copy/1` in `test_helper.exs`, `expect/3` / `stub/3` in the test). Don't introduce a formal stub module, a `*_module:` config key selecting an implementation per env, or a behaviour that exists only so tests can swap it in - that pattern spreads test concerns into `runtime.exs` and production wiring. Stub modules that already exist are fine to keep using when extending that existing work; this governs new code. Mimic is the umbrella-wide convention already.

#### Worktree dev environments (`w*` commands)

Only on the work dev box. The monorepo also runs as git worktrees under `~/worktrees/<letter>` alongside the primary checkout at `~/monorepo`, each with its own containers (`wt<letter>-*`) and URLs (`https://<letter>-{rz,cg,jp}.devzla.com`), managed by the `w*` shell commands (`wnew`, `wdel`, `wls`, `wdc`, `wcg-bash`, ...) from `~/.monorepo-worktrees/functions.sh`. Docs live next to it: `CHEATSHEET.md` (command reference), `README.md` (how it fits together), `NOTES.md` (full design record - constraints, evidence, rejected approaches). Read those before changing the tooling; update them when you do.

- Inside a worktree, never run bare `docker compose` - it would try to boot a second full stack. Use `wdc`, which scopes compose to the worktree's generated files in `~/.local/share/wt/<letter>/`. `compose.yaml` there is machine-owned (rewritten by `wregen`); hand edits belong in `compose.override.yaml`.
- The `w` prefix is load-bearing: `wcg-bash`/`wcg-log`/`wcg-iex` target the worktree's container, while the unprefixed `cg-*` twins target the shared primary stack. One letter is the only difference.
- Postgres, redis, rabbitmq, and elasticsearch are shared with the primary stack. Migrations and test-schema rebuilds (`welts`/`wclts`) therefore touch shared state - time them deliberately, and say so before running one.
- A worktree's identity is its directory (slot letter), never its branch - branches can be switched inside a worktree. `wls` is the only letter -> branch map.

Running commands in a worktree, for agents:

- **The primary stack's containers cannot see a worktree's code.** `zla-*` containers mount `~/monorepo/redline`; a worktree's are `wt<letter>-*`. Running `mix compile`/`test`/`format` in a `zla-*` container while working in a worktree checks master's code and reports a meaningless pass. Always go through `wcg-bash` (or `docker exec -u deploy wt<letter>-cycle-gear-redline-webapp`).
- Run mix from inside the container, per redline's `AGENTS.md`: tests in the cycle-gear container, `cd /rz/redline/apps/<app> && mix test <path>`.
- `w…-bash 'some command'` works without a terminal. A bare `w…-bash` and `w…-iex` need one and will refuse - don't try to script them. `w…-log` follows forever; for a one-shot read use `docker logs --tail 200 wt<letter>-<service>`.
- The first command after `wdc up -d` on a fresh slot pays a cold `deps.get` plus a full umbrella compile - minutes. Run it in the background; it has not hung.
- Never bind-mount into a worktree with an ad-hoc `docker run`. Docker creates missing mount targets on the host, inside the checkout, owned by root - which can leave the slot unable to start and need a `sudo`-adjacent cleanup the user has to do. Start the slot's own containers instead.

### Comoto sibling repos on the work dev box (`~/admin`, `~/ecom_api`)

Both run as containers in the shared monorepo stack, so their own compose files are not standalone - `ecom_api`'s `compose.dev.yaml` references a `common.yaml` that only exists there.

- `admin`: run every mix command inside the container, not on the host - `docker exec zla-admin-1 bash -c "mix test"`. The Elixir/OTP toolchain lives in the container.
- `ecom_api`: use the monorepo compose file for everything - `docker compose -f /home/brian/monorepo/docker-compose.yml exec -T ecom_api bash -c '<cmd>'`. The `ecom-api-bash` shell function wraps this but needs a TTY, so agents can't use it.

### bdavi/dotfiles

- Whenever installing a tool or application on a dev box - even one needed for a completely different project (e.g. installing Playwright for that project's tests) - check whether this repo is present (working in it, or checked out elsewhere on the machine). If so, ask the user whether they want it permanently added to `scripts/dev_box/build_ubuntu.sh` (via a new or updated `lib/*.sh` helper, matching the existing pattern) so it's provisioned automatically on future dev box builds. Don't add it without asking.
- Adding a file under `config_files/` does not install it - `scripts/install_dotfiles.sh` has to be re-run to link it into `$HOME`. After adding one, say so.
