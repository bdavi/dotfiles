# Worktree commands — cheat sheet

Copy-paste reference. See `README.md` for how it works and `NOTES.md` for why.

## One-time, before first use

```bash
# Load the new commands in an already-open shell
source ~/.workrc

# Register the slot hostnames
sudo tee -a /etc/hosts < ~/.monorepo-worktrees/hosts-block.txt
```

`wdc` tightens loose `~/.ssh` permissions itself before starting containers — a cold `mix deps.get` fails on any group-writable file there.

## Create, list, remove

`wnew` runs from `~/monorepo` or any worktree, everything else from inside a worktree.

```bash
# New branch, created off local master
wnew bdavi/APP-1234

# Remote branch: fetched, local branch tracks it so pushes go back
wnew origin/hwideman/APP-1069

# Existing local branch: checked out, never recreated
wnew bdavi/APP-1234

# Every slot: letter, branch, containers up, URL
wls

# Current slot letter
windex

# Remove this worktree, keeping the branch
wdel

# ... despite uncommitted or unpushed work
wdel --force
```

## Run containers

Cycle gear only by default.

```bash
# Start
wdc up -d

# What's running
wdc ps

# Restart one service
wdc restart wta-cycle-gear-redline-webapp

# Stop, keeping volumes
wdc down

# Add a brand for this session
wdc up -d --scale wta-revzilla-redline-webapp=1

# Rebuild the compose file and nginx confs from the branch
wregen
```

To keep a brand on permanently, set its `scale` in `~/.local/share/wt/<letter>/compose.override.yaml` — that file survives `wregen`.

## Work in them

```bash
# Follow logs
wcg-log
wrz-log
wjp-log
wecom-log

# Interactive shell
wcg-bash
wrz-bash
wjp-bash
wecom-bash

# Run a single command instead of a shell
wcg-bash 'mix format'

# Remote iex into the running app
wcg-iex
wrz-iex
wjp-iex

# Open the site (ecom opens <slot>-rz.devzla.com/admin)
wcg-open
wrz-open
wjp-open
wecom-open

# Rebuild the redline test schema (shared DB, branch's schema dump)
wclts

# Rebuild the ecom test schema (shared DB, needs ecom scaled up)
welts
```

## URLs

Slot `a`:

```
https://a-cg.devzla.com
https://a-rz.devzla.com
https://a-jp.devzla.com
http://a-cg.devzla.com:4042/swaggerui
```

## Paths

```
~/worktrees/<letter>                              # the checkout
~/.local/share/wt/<letter>/compose.yaml           # generated, machine-owned
~/.local/share/wt/<letter>/compose.override.yaml  # yours, survives wregen
~/.monorepo-worktrees/README.md                   # commands + gotchas
~/.monorepo-worktrees/NOTES.md                    # full design record
```

The primary stack has to be up — its network is where the databases live.
