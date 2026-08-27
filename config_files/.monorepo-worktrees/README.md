# Monorepo worktrees

Run the primary monorepo stack **and** several git worktrees at the same time, each with its own redline/ecom containers and its own URLs, so work on several tickets can go in parallel.

Nothing here requires a change to any tracked file in the monorepo.

`CHEATSHEET.md` alongside this file is the copy-paste command reference; `NOTES.md` is the full design record — the constraints that shaped it, the tests behind each decision, and the approaches that were rejected and why.

## One-time setup

Everything else is automatic; this step is not, on purpose — the tooling never edits system files.

```sh
sudo tee -a /etc/hosts < ~/.monorepo-worktrees/hosts-block.txt
```

Twenty slots, three brands each. Do it once and it covers every worktree from then on.

## Commands

| Command | Does |
| --- | --- |
| `wnew <branch>` | create a worktree (run from the primary monorepo or any worktree) |
| `wdel [--force]` | tear down and remove the current worktree, keeping the branch |
| `wls` | every slot: letter, branch, containers up, URL |
| `windex` | the current slot letter |
| `wdc …` | `docker compose` scoped to this worktree |
| `wregen` | rebuild the generated compose file and nginx confs from the branch |
| `w{cg,rz,jp,ecom}-log` | follow that container's logs |
| `w{cg,rz,jp,ecom}-bash` | shell (or `w… -bash 'some command'`) |
| `w{cg,rz,jp}-iex` | remote iex into the running app |
| `w{cg,rz,jp,ecom}-open` | open the site (ecom opens `<slot>-rz.devzla.com/admin`) |
| `welts` / `wclts` | rebuild the ecom / redline **test** schema |

`wnew` accepts a new branch (`bdavi/APP-1234`, created off local `master`), an existing local branch, or a remote one (`origin/hwideman/APP-1069`, fetched and set up to track so pushes go back to it). It says which of those it did.

Everything except `wnew` runs from inside a worktree and does nothing anywhere else. The log, shell and iex commands print the container they are about to touch, because the only thing between them and the shared primary stack is one letter.

## What a slot is

One letter derives everything:

| | slot `a` |
| --- | --- |
| checkout | `~/worktrees/a` |
| compose project | `wta` |
| containers | `wta-cycle-gear-redline-webapp`, `wta-gateway`, … |
| URLs | `https://a-rz.devzla.com`, `https://a-cg.devzla.com`, `https://a-jp.devzla.com` |
| network | `172.30.1.0/24`, sidecar at `172.30.1.10` |
| generated state | `~/.local/share/wt/a/` |

Identity comes from the directory, never the branch — a worktree is an ordinary checkout and you can switch branches inside it.

Only cycle gear starts by default. Enable another brand either for one command:

```sh
wdc up -d --scale wta-revzilla-redline-webapp=1
```

or permanently, by setting its `scale` in `~/.local/share/wt/a/compose.override.yaml`, which survives `wregen`. `compose.yaml` next to it is machine-owned and gets rewritten.

## What is shared with the primary stack

Postgres (including `ecom_test` and `ecom_redline_test`), redis, rabbitmq, elasticsearch, and every sibling service — worktree containers join `zla_default` and reach them by their usual names. Colliding rabbit consumers or a test-schema rebuild are yours to time; nothing here tries to be clever about it.

A brand this worktree isn't running routes to the **primary's** container, which is why `a-rz.devzla.com/admin` works without running ecom here.

## How it hangs together

- `wt-generate.py` resolves the worktree's own `docker-compose.yml` (`docker compose config`), keeps the six services built from monorepo code, and patches them: prefixed names, no published ports, no `depends_on`, the external `zla_default` network, `scale: 0` on all but cycle gear, `ENDPOINT_HOST` per brand, and the two `.git` mounts the Elixir build needs.
- The nginx sidecar is a copy of the primary gateway pointed at this slot. Its vhost confs are derived from the branch's own `zlaverse/dev/nginx/upstreams/*.conf` so the `/admin` path map and asset handling come along for free.
- Nothing is published to a host port. The sidecar is reached at its container IP, which is why the hosts entries point at `172.30.x.10`.

## Gotchas

- **Linux only.** Docker Desktop on macOS cannot route to container IPs.
- The primary stack must be up: its network is where the databases live.
- nginx resolves upstreams once at startup, so `wdc` restarts the sidecar after anything that creates or recreates a container. If a site 502s after a container was replaced by hand, `wdc restart` fixes it.
- A bare `docker compose` inside a worktree would try to start a whole second stack. Use `wdc`.
- `wdel` drops the slot's `_build`/`deps`/`node_modules` volumes, so the next worktree compiles from cold.
- **A cold build needs working ssh inside the container.** `mix deps.get` fetches git dependencies over ssh using the mounted `~/.ssh`, and OpenSSH refuses *any* file there that is group- or world-writable: `Bad owner or permissions on /home/deploy/.ssh/<file>`. `wdc up|start|restart` now runs `_wt_ssh_preflight` first, which chmods the offending files (600, or `go-w` for `.pub`) and prints what it changed — so this should no longer bite. If a build still dies there, the message names the file; fix it and `wdc restart`, since the container re-runs `deps.get` on start. This affects the primary stack's cold builds identically (`fixit` included); it just doesn't show up while its deps volume is already populated.
