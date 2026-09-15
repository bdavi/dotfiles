# The work overlay

This repo is **public** and serves both work and personal machines, so nothing employer-specific can live in it. Work configuration lives in a separate private repo that installs on top of this one. This document describes the mechanism; the private repo carries the half that names names.

## The routing rule

Five questions, asked in order. The first that applies decides where an instruction goes.

| # | Question | If yes |
|---|---|---|
| 1 | A credential, secret, or shared test account? | **Never write it down.** Link the source. |
| 2 | Does it name the employer — repo, URL, ticket-system field, team, service, host, brand, domain concept? | The private overlay |
| 3 | Is it about how you want AI to work, regardless of employer? | This repo |
| 4 | Does it apply to exactly one repo? | That repo's own `AGENTS.md` |
| 5 | True always, or only during a task? | Always → an `AGENTS` file; during a task → a **skill** |

Two rules that make the table hold:

- 🔴 **An `AGENTS` file never summarizes a skill.** A one-line pointer at most. Summaries are how the two fall out of sync: the skill gets updated and the summary does not.
- ⚠️ **Authorization is not craft.** "Never push without an explicit ask" gates behaviour before any skill loads, so it is always-on and lives in `AGENTS.md`. "A PR summary is one plain sentence" is craft, so it belongs in a skill.

The one deliberate exception to rule 2: `scripts/install_dotfiles.sh` names the private repo so it can offer to clone it. A repo name and nothing else.

## How both halves load

`config_files/.claude/CLAUDE.md` imports two files:

```markdown
@~/AGENTS.md
@~/AGENTS.comoto.md
```

The first ships here. The second ships in the overlay, so on a personal machine it would dangle — `install_dotfiles.sh` therefore creates an empty `~/AGENTS.comoto.md` stub if none exists. The overlay's installer replaces the stub with a symlink into its own repo. Nothing here needs to know what the overlay puts in it.

Shell config works the same way: `config_files/.commonrc` sources `~/.workrc` and `~/.workrc-codespaces` **only if the files exist**, and they ship in the overlay. A personal machine sources neither and reports nothing.

## Installing

```bash
~/code/dotfiles/scripts/install_dotfiles.sh
```

It symlinks everything under `config_files/` into `$HOME` (`cp -rsf`, so installed files are links back into the checkout), writes the stub, then offers to clone and install the overlay — or just to install it, if the checkout is already there. Answer no on a personal machine.

**A new file is not live until the installer is re-run.** That includes skills under `config_files/.claude/skills/`.

## Checking the seam holds

Employer-specific content drifts back in easily — a hostname in a comment, a team name in an example. The overlay ships a `check-leaks` script that greps this repo for the terms that must never appear here; run it before pushing:

```bash
~/code/comoto-dotfiles/scripts/check-leaks
```

The term list lives in the overlay rather than here, because the list is itself made of employer-specific strings.

## History

Work content lived in this repo before the split and **remains in its git history** — deleting the files moved them forward, it did not unpublish them. No history has been rewritten.
