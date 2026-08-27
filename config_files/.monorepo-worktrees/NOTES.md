# Worktree-scoped dev environments

A design spec for running the primary monorepo stack **plus several git worktrees at once**, each with its own redline/ecom containers, so work on several tickets can proceed in parallel and switching between them is just switching windows.

Personal tooling. Nothing in this design requires a change to any tracked file in the monorepo, and nothing about it is visible to other developers.

Status: **built**. The implementation lives in `~/code/dotfiles/config_files/.monorepo-worktrees/` (`functions.sh`, `wt-generate.py`, `hosts-block.txt`, `README.md`), sourced from `.workrc`. Everything under [Evidence](#appendix-b--evidence) was tested on this box; everything in [Superseded](#appendix-a--superseded-decisions) was considered and rejected.

One manual step remains, on purpose — the tooling never edits system files:

```sh
sudo tee -a /etc/hosts < ~/.monorepo-worktrees/hosts-block.txt
```

---

## 1. Shape

A worktree gets a **slot letter**. One letter derives everything:

| Thing | Slot `a` |
| --- | --- |
| worktree checkout | `~/worktrees/a` |
| compose project | `wta` |
| containers | `wta-cycle-gear-redline-webapp`, `wta-ecom-webapp`, `wta-gateway`, … |
| hostnames | `a-rz.devzla.com`, `a-cg.devzla.com`, `a-jp.devzla.com` |
| network | `172.30.1.0/24`, sidecar pinned at `172.30.1.10` (third octet = letter position) |
| generated state | `~/.local/share/wt/a/` |

Allocation is the lowest unused letter. `docker ps | grep wt` shows every worktree container across all slots. Because names carry no branch or ticket, `wls` is the only place the letter → branch mapping exists — it is load-bearing, not a convenience.

Identity comes from the **directory**, never from the branch: a worktree is an ordinary checkout and you can switch branches inside it freely ([evidence](#branch-switching-inside-a-worktree)), so anything derived from the branch name would silently break the moment you did.

**What is shared with the primary stack** (deliberately, all of it): postgres including `ecom`, `ecom_test`, and `ecom_redline_test`; redis and its DB indexes; rabbitmq queues and consumers; the `products` Elasticsearch index; the `zla_shared-data` volume. Worktree containers reach all of them by their normal service names because they join `zla_default`. Colliding consumers or schema resets are managed by hand, not by tooling.

**What is per-worktree:** the checkout, the containers, the `_build` / `deps` / `node_modules` volumes, the nginx sidecar, the network, and the hostnames.

---

## 2. Networking and routing

Worktree containers join the primary's network `zla_default` as external. That is not optional — redline's dev config hardcodes sibling hostnames (`redis` in `config/config.exs:127`; `product-service`, `payment-service`, `loyalty`, `ecom-webapp` in `config/dev.exs`) — and it means `DATABASE_URL`, `ELASTICCLOUD_URL`, `REDLINE_RABBIT_URI` and friends are inherited unchanged.

**The constraint that shapes everything:** a compose service name becomes a network alias on *every* network the container joins, and an explicit alias does not replace it ([evidence](#service-names-are-aliases-everywhere)). Two containers sharing a service name on `zla_default` therefore round-robin, and the primary's gateway would serve your worktree's app half the time. Hence the `wta-` prefix on every service key.

**Browser access uses no host ports at all.** On Linux the docker bridge is routable from the host, so a container is reachable at its own IP with nothing published. Each worktree declares its own network with a pinned subnet and gives its sidecar a static IP; `/etc/hosts` points the slot's hostnames at that address ([evidence](#static-container-ip-with-no-published-ports)).

This is what makes `https://a-cg.devzla.com` work with no port, no host-port allocation, no conflict between slots, and nothing changed in the primary stack. The mapping is permanently stable because the subnet is declared rather than assigned, so `wdc down` and a later `up` recreate it identically.

### The sidecar

A per-worktree `nginx:1.24` service in the generated compose file, a faithful clone of the primary gateway:

- mounts the **worktree's own** `zlaverse/dev/nginx/nginx.conf`, `mime.types`, `dhparams.pem` and `ecom/public`, so routing tracks any nginx change on the branch
- mounts the existing external volume `zla_certs` read-only for the `*.devzla.com` cert
- mounts generated vhost confs at `/etc/nginx-upstreams`, which the stock `nginx.conf` already globs
- listens on 80 and 443 inside its own namespace, and on 4041-4043 proxying to the app containers so `http://a-cg.devzla.com:4042/swaggerui` mirrors the primary's ergonomics
- joins `zla_default` (to reach app containers by their prefixed names) and the pinned slot network (to be reachable from the host)

**The vhost confs are derived from the branch's own, not hand-written.** `zlaverse/dev/nginx/upstreams/*.conf` is copied out of the worktree checkout with three mechanical rewrites:

1. redline `upstream {}` server lines → `wta-<service>:4000`
2. `server_name` regexes → the slot's hostname (`a-rz.devzla.com`)
3. the `ecom` upstream stays `ecom-webapp:80` — the **primary's** ecom, shared like everything else — and is rewritten to `wta-ecom-webapp:80` only when the worktree runs its own

This matters more than it looks. `revzilla.conf` carries a `map $request_path $upstream` routing roughly twenty path patterns to the ecom upstream — `/admin`, `/accounts/login`, `/ajax_utility/`, `/api/…`, `/livechat`, and more — and that map is http-level, so `cyclegear.conf`'s `proxy_pass http://$upstream` depends on it too. Hand-written minimal confs would silently lose all of it, `/admin` included.

Two consequences of reusing `upstream {}` blocks, which nginx resolves once at startup:

- confs are generated only for brands that are actually enabled, because a missing container makes nginx refuse to start entirely
- an app container that gets recreated leaves the sidecar pointing at a dead IP

So `wdc` regenerates the confs from the current service set and restarts the sidecar after any `up` or `restart` that touches an app container.

### One-time host setup

`/etc/hosts` needs one line per slot, written once by hand. Twenty slots, three brands, covering every slot forever:

```
172.30.1.10   a-rz.devzla.com a-cg.devzla.com a-jp.devzla.com
172.30.2.10   b-rz.devzla.com b-cg.devzla.com b-jp.devzla.com
172.30.3.10   c-rz.devzla.com c-cg.devzla.com c-jp.devzla.com
172.30.4.10   d-rz.devzla.com d-cg.devzla.com d-jp.devzla.com
172.30.5.10   e-rz.devzla.com e-cg.devzla.com e-jp.devzla.com
172.30.6.10   f-rz.devzla.com f-cg.devzla.com f-jp.devzla.com
172.30.7.10   g-rz.devzla.com g-cg.devzla.com g-jp.devzla.com
172.30.8.10   h-rz.devzla.com h-cg.devzla.com h-jp.devzla.com
172.30.9.10   i-rz.devzla.com i-cg.devzla.com i-jp.devzla.com
172.30.10.10  j-rz.devzla.com j-cg.devzla.com j-jp.devzla.com
172.30.11.10  k-rz.devzla.com k-cg.devzla.com k-jp.devzla.com
172.30.12.10  l-rz.devzla.com l-cg.devzla.com l-jp.devzla.com
172.30.13.10  m-rz.devzla.com m-cg.devzla.com m-jp.devzla.com
172.30.14.10  n-rz.devzla.com n-cg.devzla.com n-jp.devzla.com
172.30.15.10  o-rz.devzla.com o-cg.devzla.com o-jp.devzla.com
172.30.16.10  p-rz.devzla.com p-cg.devzla.com p-jp.devzla.com
172.30.17.10  q-rz.devzla.com q-cg.devzla.com q-jp.devzla.com
172.30.18.10  r-rz.devzla.com r-cg.devzla.com r-jp.devzla.com
172.30.19.10  s-rz.devzla.com s-cg.devzla.com s-jp.devzla.com
172.30.20.10  t-rz.devzla.com t-cg.devzla.com t-jp.devzla.com
```

There is no `-ecom` name: the Ruby app is reached through the RevZilla host at `a-rz.devzla.com/admin`, exactly as the primary serves it at `rz.devzla.com/admin`.

Single-label names keep the `*.devzla.com` wildcard cert valid. The tooling never edits `/etc/hosts`.

**Linux only.** Docker Desktop on macOS cannot route to container IPs, so a Mac or codespace would need published ports instead.

---

## 3. The generated compose file

**Source: the worktree's own `docker-compose.yml`**, not the primary's, so a branch that changes a service definition gets its version. This costs nothing — the file contains zero `${}` substitutions, so no `.env` is needed to resolve it.

```
docker compose -p wta \
  -f ~/worktrees/a/docker-compose.yml \
  --project-directory ~/worktrees/a \
  config --format json
```

Two things fall out for free: `--project-directory` resolves every relative bind source against the worktree (`./redline` → `/home/brian/worktrees/a/redline`, no path rewriting), and `-p wta` emits the named volumes already namespaced as `wta_cg-build`, `wta_cg-deps`, and so on.

Services kept: `cycle-gear-redline-webapp`, `revzilla-redline-webapp`, `jp-cycles-redline-webapp`, `ecom-webapp`, `oban-job`, `revzilla-translation-worker`. Everything else — postgres, redis, rabbit, elasticsearch, and the sibling-repo services — is used from the primary stack.

Patches applied to each kept service:

1. rename the service key to `wta-<service>`, and add `container_name: wta-<service>`
2. drop `ports` — nothing is published
3. drop `depends_on` — it names `postgres14`/`redis`/`rabbitmq`/`elasticcloud`, which don't exist in this project, and compose errors on unknown refs
4. replace `networks: {default: null}` with external `zla_default` plus the unique alias
5. add the second `.git` mount (see below)
6. `shared-data` → external, `name: zla_shared-data`
7. `scale: 0` on everything except `cycle-gear-redline-webapp` — verified compatible with `container_name` ([evidence](#container_name-with-scale-0))
8. set `ENDPOINT_HOST` per brand
9. append the sidecar service and the pinned slot network

Then the file is written to `~/.local/share/wt/a/compose.yaml`. Nothing is generated inside the checkout, so `git status` on the branch stays clean and no tracked `.gitignore` needs touching.

**Regeneration.** The generated file is machine-owned and rewritten only by an explicit `wregen`. `wdc` always passes a second `-f` at a hand-editable `~/.local/share/wt/a/compose.override.yaml`, where scale changes and local experiments live and survive regeneration. This matters because compose does not persist `--scale`: a brand enabled with a flag drops back to zero on the next plain `up`.

**No `.env` anywhere.** `wdc` always passes `-p` and `-f` explicitly, so nothing depends on cwd. A bare `docker compose up -d` inside a worktree would try to boot an entire second stack — accepted as a self-inflicted wound rather than defended against.

**No volume seeding.** Every new worktree pays a cold `mix deps.get` + full umbrella compile + `npm install`. Roughly 700MB of volumes per brand.

That makes one pre-existing host condition load-bearing: OpenSSH refuses any file under `~/.ssh` that is group- or world-writable, so a single loose mode bit stops `mix deps.get` from fetching git dependencies (`Bad owner or permissions on /home/deploy/.ssh/<file>`). Verified to fail identically in the primary's container — it simply never surfaces there because that deps volume is already populated.

First hit was `~/.ssh/config` at 664. Fixing that one file was not enough: `~/.ssh/codespaces` was 664 too, and the failure came back on the next cold worktree — the same error on a different file, several minutes into `deps.get`. Hence `_wt_ssh_preflight`, which `wdc up|start|restart` runs on the host before compose: it finds every group/world-writable regular file at the top of `~/.ssh` and tightens it, printing each change.

It chmods to 600 rather than just dropping the write bits, because the offending file may be a config (rejected only when writable) or a private key (also rejected when merely group-readable); 600 satisfies both checks. `.pub` files are supposed to stay readable, so those only lose the write bits. Tightening is the only direction that cannot break ssh, which is what makes it safe to do unattended. `-maxdepth 1` deliberately skips `~/.ssh/agent/` and anything else nested — those aren't files OpenSSH reads directly.

### The `.git` mount

`/rz/redline` is the container's view of the `redline/` subdirectory, which is not a repo root, and the build shells out to git: `mix_helper.exs:53` runs `git rev-parse --short HEAD` to stamp a version string, used by at least ten `mix.exs` files across the umbrella. There is no fallback — if git can't answer, compilation breaks. The primary solves this by mounting the repo-root `.git` **directory** at `/rz/redline/.git`.

In a worktree, `.git` is a **file** containing `gitdir: /home/brian/monorepo/.git/worktrees/a`, so that pointer has to resolve inside the container. Two mounts, both read-only ([evidence](#git-mount-recipes)):

- `~/worktrees/a/.git` → `/rz/redline/.git` — the pointer file, which the config already emits
- `/home/brian/monorepo/.git` → `/home/brian/monorepo/.git` — the primary's real git directory at its own absolute path

Read-only because the only consumer is a compile-time read, and because the container runs as `deploy`: a stray write would leave lock files or objects owned by the wrong user inside the real `.git`, surfacing later as permission errors in host-side git. If something ever needs write access it fails with an obvious error and the flag is a one-word change.

---

## 4. Commands

All of it lives in `~/code/dotfiles/config_files/.workrc`, symlinked to `~/.workrc` — already where the `-log` aliases live (lines 16-23), so the `w` twins sit beside their originals, version-controlled and dev-box-provisioned.

```
wnew <branch>       wdel [--force]      wls      windex      wdc …      wregen
w{ecom,rz,cg,jp}-log      w{ecom,rz,cg,jp}-bash      w{ecom,rz,cg,jp}-open
w{rz,cg,jp}-iex           welts      wclts
```

All names verified free on this box.

**Resolution is inside-only.** Each command resolves its worktree from cwd via `git rev-parse --show-toplevel` (works from any subdirectory) and confirms it's a linked worktree, not the primary. Anywhere else it says so and does nothing. No env var, no explicit-slot argument — herdr already opens each workspace with its cwd at the worktree root.

**Every log, shell, and iex command prints a one-line target banner** (`→ wta-cycle-gear-redline-webapp`). The `w` is the only thing between "my worktree" and the shared primary, and `cg-bash` typed by mistake targets the primary silently. Not applied to `welts`/`wclts`, which hit the same shared databases either way.

**When a container isn't running**, the message prints the exact command rather than an instruction — `wdc up -d --scale wta-revzilla-redline-webapp=1` — since the compose file lives outside the checkout.

The originals go through `container-log <service>` and `cd $COMPOSE_ROOT && docker compose exec`; the twins don't need compose at all, because container names are deterministic: `docker logs -f --tail 1000 wta-cycle-gear-redline-webapp`, `docker exec -u deploy -it wta-… bash -lc …`. Simpler, and a cleaner "not running" error.

`wecom-open` opens `https://a-rz.devzla.com/admin`, since ecom has no host of its own.

`wclts` covers all three redline brands — same database, same schema dump, only the executing container differs — so there is no `wrlts`/`wjlts`. `welts`/`wclts` are still not redundant with their primary twins: the reset loads the schema dump from the *worktree's* `db/` mount, so you get the branch's schema rather than master's.

### `wnew <branch>`

Runs from any checkout of the monorepo — the primary or an existing worktree; they share refs, remotes, and the worktree list, so behavior is identical (originally primary-only, relaxed once running it from inside a worktree proved routine). Validates the `<handle>/<TICKET-123>` convention (a guardrail now, not load-bearing), allocates the lowest free letter, creates the worktree, generates the compose file and nginx confs, and adds a herdr workspace when `HERDR_ENV=1` via `herdr worktree create --branch --base --path --label --focus`.

Branch resolution, with the chosen path always announced:

| Input | Condition | Action |
| --- | --- | --- |
| `origin/hwideman/APP-1069` | explicit remote ref | `git fetch origin hwideman/APP-1069`, then `worktree add --track -b hwideman/APP-1069 <path> origin/hwideman/APP-1069` |
| `bdavi/APP-1234` | local branch exists | `worktree add <path> bdavi/APP-1234` — check out, never create |
| `hwideman/APP-1069` | not local, exists on origin | fetch and create the tracking branch, announcing that it matched a remote |
| `bdavi/APP-1234` | exists nowhere | `worktree add -b bdavi/APP-1234 <path> master`, off **local** master |

Tracking is verified to set `branch.<name>.remote=origin` and `branch.<name>.merge=refs/heads/<name>`, and `push.default` is unset (so `simple`), meaning a later `git push` goes straight back to that same remote branch ([evidence](#remote-tracking-worktrees)).

Row three is git's own DWIM. It's the one that can surprise — a genuinely new branch name that happens to exist on origin gets you someone else's branch — so it is announced loudly, and `--new` forces branching off master regardless.

No fetching of `master`; keeping local master current is the developer's job. The only fetch is the targeted one for a branch that exists solely on the remote.

Fails before creating anything when: the branch is already checked out in another worktree; `origin/<x>` doesn't exist on origin; no slot letters are free.

### `wdel [--force]`

Runs only from inside a worktree. Refuses without `--force` when there are uncommitted tracked changes, or commits ahead of `origin/master` with no upstream (a fresh branch has no upstream, so `git log @{u}..` errors rather than reporting). Untracked files warn but don't block. `--force` maps onto `git worktree remove --force`.

Then: `wdc down -v` (drops the slot's `_build`/`deps`/`node_modules` volumes — going back to a deleted worktree is rare enough that a cold rebuild is the right trade; external volumes are untouched), `cd` back to the primary monorepo since the cwd ceases to exist, `git worktree remove`, delete the state dir to free the letter, and close the herdr workspace **last**, because doing it from inside kills the pane running the command.

**The branch is always retained.** Hosts entries are left alone.

### `wls` / `windex` / `wdc` / `wregen`

`wls` — letter, branch (read live from each worktree, so it stays right after a checkout), path, URL, and which containers are up. `wnew` needs the same registry to allocate, so exposing it is nearly free, and it's the only way to debug slot drift.

`windex` — the current worktree's letter, bare, for scripting.

`wdc` — `docker compose -p wta -f <generated> -f <override>`, passing everything through. `wdc up -d` checks first that `zla_default` exists, since a stopped primary stack produces an opaque error otherwise.

`wregen` — rewrite the generated compose file and nginx confs from the branch's current `docker-compose.yml`.

---

## 5. Where the code lives

Everything lives together in one directory in the dotfiles repo. `install_dotfiles.sh:12` does `cp -rsf ~/code/dotfiles/config_files/. ~`, which recreates directories and symlinks the files inside them, so the whole directory is picked up automatically.

```
config_files/
  .workrc                        # one added line (see below)
  .monorepo-worktrees/
    functions.sh                 # every w* command — thin wrappers only
    wt-generate.py               # compose + nginx generation
    hosts-block.txt              # the twenty /etc/hosts lines
    README.md                    # what this is, the one-time host setup, how the pieces fit
```

`.workrc` gains a single guarded line, so a machine without the directory doesn't error:

```sh
[ -f ~/.monorepo-worktrees/functions.sh ] && source ~/.monorepo-worktrees/functions.sh
```

Runtime state stays out of the dotfiles repo entirely, in `~/.local/share/wt/<letter>/` (`compose.yaml`, `compose.override.yaml`, `nginx/`, `meta`).

**Shell functions stay thin.** They resolve the slot, check preconditions, print the banner, and shell out. Anything structural — the nine compose patches, the nginx rewrites — belongs in `wt-generate.py`, because JSON surgery inside a shell function is where this would rot. `jq` is available at `/usr/bin/jq`, but python suits the amount of restructuring better.

**Invoke it as `/usr/bin/python3 ~/.monorepo-worktrees/wt-generate.py`** — explicit interpreter, absolute path. Bare `python3` currently resolves to an asdf shim, and a tool that breaks when an asdf version is switched in an unrelated project isn't worth the convenience. Calling the interpreter directly also sidesteps the executable bit, which `cp -rs` inherits from the file in the repo rather than setting itself.

No nginx templates are needed in the directory: the vhost confs are derived from the branch's own `upstreams/*.conf` at generation time, and the sidecar's extra listeners are emitted by the generator.

## 6. Build order

1. `wnew` — branch resolution, slot allocation, worktree, herdr workspace. No docker yet.
2. Compose generation + `wdc` + `wls` + `windex`.
3. Sidecar, generated nginx confs, the hosts-file lines to paste once.
4. The `w*` twins with banners.
5. `wdel`.

---

## Appendix A — superseded decisions

Kept for the "why not", since most of these look reasonable until you push on them.

**Takeover mode.** Early on, the worktree container kept the primary's service name, the primary's cg was scaled to 0, and `cg.devzla.com` simply pointed at the worktree — no DNS, ports, or nginx work at all. Died with the requirement to run the primary *and* several worktrees simultaneously.

**Branch or ticket in container names.** The original ask was for `docker ps` to identify a worktree by branch. Rejected once it was verified that you can check out a different branch inside a worktree, which would leave every derived name pointing at nothing. `wls` covers the readability gap.

**Numeric ordinals.** Replaced by letters: shorter, no visual collision with compose's trailing `-1` index, and no container names starting with a digit.

**Per-worktree redis DB indexes, and per-worktree test databases.** Both were proposed to stop worktrees stomping shared state — redis DBs 5-15 are free, and per-worktree test databases would have cost ~90MB each. Rejected in favour of always sharing every database; deciding when it's safe to reset a schema or run a migration is the developer's call. (The dev `ecom` database is 445GB, so per-worktree copies of *that* were never on the table.)

**Routing option A — rebind the primary gateway to `127.0.0.1`.** Would have freed 443 on other loopback addresses via an override appended to the gitignored `.env`. Rejected: it still adjusts the primary stack, and it breaks reaching the box from other machines.

**Routing option B — sidecars on `127.0.0.1:844N`.** No primary changes, but the URL carries a port, and `ENDPOINT_HOST` can express a host but not a port, so absolute links would need the port smuggled into the host string. Rejected in favour of the static-IP approach, which needs neither.

**Volume seeding from the primary with `cp -a`.** Preserves mtimes so dep artifacts stay valid and most of a cold build becomes incremental. Rejected as unnecessary complexity — a cold compile is acceptable.

**`WT_TICKET` env var and explicit-slot arguments.** A way for `w*` commands to work from `~` or any other directory. Rejected: inside-only is simpler, and herdr opens each workspace at the worktree root anyway.

**Fetching `origin/master` in `wnew`.** Rejected; new branches come off local master and keeping it current is manual. This also removed a wrinkle where `git fetch origin master:master` refuses when master is checked out in some worktree.

**A `.env` in the worktree, and generated files inside the checkout.** Both rejected: `wdc` passes `-p`/`-f` explicitly, and generated files in the checkout would show up in `git status` on the branch being PR'd, with no way to ignore them that doesn't touch a tracked `.gitignore`.

**Refactoring the primary `docker-compose.yml` to `env_file:` fragments** so the primary and worktree files could share one source of truth for ~60 brand env vars. Rejected: it touches a file the whole team uses. Generating from the resolved config gets the same result with no shared change.

**Per-worktree rabbit queues, oban isolation, ES index prefixes.** All considered, all declined in favour of sharing and managing collisions by hand.

---

## Appendix B — evidence

Everything here was run against this box; the design leans on these results rather than on assumption.

### Service names are aliases everywhere

Compose adds the service name as an alias on *every* network a container joins, including a shared external one, and an explicit alias does not replace it. A service keyed `cycle-gear-redline-webapp` joining `zla_default` got aliases `[wtalias-cycle-gear-redline-webapp-1, cycle-gear-redline-webapp, cg-app-1234]`.

Consequence, demonstrated live: six consecutive `getent hosts cycle-gear-redline-webapp` from `zla-gateway-1` alternated between the real cg (172.19.0.17) and the imposter (172.19.0.22). nginx resolves `upstream {}` names once at config load, so the gateway kept serving the address it started with — which also means it won't notice a new container taking a name until reloaded, and points at a dead IP after a recreate.

### Cross-project networking

A separate compose project attached to `zla_default` as external resolved `postgres14`, `redis`, `rabbitmq`, `elasticcloud`, `gateway`, and got HTTP 200 from `cycle-gear-redline-webapp:4000`. In reverse, `zla-gateway-1` resolved the other project's alias and container name. (DNS entries vanish the instant a container exits, which is what "the gateway can't resolve it" usually means.)

### `.git` mount recipes

| Mounts | Result |
| --- | --- |
| worktree `.git` file → `/rz/redline/.git` **plus** primary `.git` → same absolute path | ✅ `git rev-parse --short HEAD` works, reports the **worktree's** branch |
| worktree `.git` file only | ❌ `fatal: not a git repository: /home/brian/monorepo/.git/worktrees/<name>` |
| primary `.git` dir → `/rz/redline/.git` (primary-style) | ❌ docker refuses: can't mount a directory over a file |

Read-only was sufficient for `rev-parse`.

### `container_name` with `scale: 0`

They coexist. A two-service project with explicit `container_name` on both and `scale: 0` on one: `up -d` started only the unscaled service and `docker ps` showed exactly `app-1234-cycle-gear-redline-webapp-1`; `up -d --scale app-1234-revzilla-redline-webapp=1` then produced exactly `app-1234-revzilla-redline-webapp-1`. Compose also accepted `1`, `wt1`, and `1-app-1234` as project names, so a leading digit is not a constraint.

### Static container IP with no published ports

Host → container works with nothing published: `curl http://172.19.0.17:4000/` returned 200 for the primary cg webapp, which publishes no such port.

With a pinned subnet and static IP, a sidecar at `172.30.1.10` joined to both its own network and `zla_default`:

| Check | Result |
| --- | --- |
| host → `172.30.1.10:443` (nothing published) | ✅ served |
| host → `172.30.1.10:80` | ✅ served |
| sidecar resolves `cycle-gear-redline-webapp`, `postgres14` | ✅ both |
| primary gateway still owns host `0.0.0.0:443` | ✅ 200 for `cg.devzla.com` |

The blocker this works around: `127.0.0.2:8443` publishes fine and `127.0.0.1:8443` correctly refuses, but **`127.0.0.3:443` cannot be bound** — the primary gateway publishes on `0.0.0.0:443`, which covers every loopback address. In-use subnets: 172.17 bridge, 172.18 dev, 172.19 zla, 172.20 platform-api-client. Nothing uses 172.30; a collision would fail with an explicit pool-overlap error.

### Branch switching inside a worktree

| Action | Result |
| --- | --- |
| `git checkout master` (not checked out elsewhere) | ✅ switched |
| `git checkout -b wt-second-branch` | ✅ switched |
| `git checkout worktree-build` (checked out in the primary) | ❌ `fatal: 'worktree-build' is already used by worktree at '/home/brian/monorepo'` |

A worktree is an ordinary checkout; the only restriction is that a branch can't be checked out twice.

### Remote-tracking worktrees

`git worktree add --track -b APP-231 <path> origin/APP-231` (git 2.53) set `branch.APP-231.remote=origin` and `branch.APP-231.merge=refs/heads/APP-231`; `push.default` is unset, so `simple`.

### ssh permissions on a cold build

Two cold worktrees, two different files, the same failure — this is why the check sweeps `~/.ssh` rather than naming a file.

| File | Mode | Result |
| --- | --- | --- |
| `~/.ssh/config` | 664 | ❌ `Bad owner or permissions on /home/deploy/.ssh/config` — died on the first git dep |
| `~/.ssh/codespaces` | 664 | ❌ same error, different file, after `config` had already been fixed |
| both at 600 | 600 | ✅ `deps.get` fetched every git dep and went on to compile |

The failure surfaces minutes in, on whichever git dependency is fetched first (`platform_api_client` here), and leaves the deps volume half-populated — so it reads like a network flake rather than a permissions problem. `_wt_ssh_preflight` on `wdc up|start|restart` is idempotent: it prints one line per file it tightens and is silent once `~/.ssh` is clean.

### Compose config resolution

`docker-compose.yml` contains **zero** `${}` substitutions, so no `.env` is needed to resolve it. `--project-directory /tmp` produced bind sources rooted at `/tmp` (`/tmp/redline`, `/tmp/.git`, `/tmp/db`), confirming that pointing it at the worktree does the path rewriting for free. The cg service resolves to 63 environment variables, `ports`, `depends_on` with four services, `networks: {default: null}`, and named volumes emitted with `name: <project>_<volume>`.

### Measurements

| Thing | Value |
| --- | --- |
| `ecom` / `ecom_redline_test` / `ecom_test` | 445 GB / 52 MB / 39 MB |
| redis DB indexes holding keys | db0, db1, db4 (jp configured for db3) |
| idle webapp memory | cg 230MB, jp 240MB, ecom 322MB, rz 1.18GB after exercise, translation worker 171MB, oban 163MB |
| host | 20 cores, 31GB RAM (~12GB free with the full stack up), 1.1TB disk free |
| volumes per brand | `_build` 250MB + `deps` 75MB + web_store `node_modules` 304MB + store_portal 74MB ≈ 700MB |
| dev cert | `/mnt/certs/devzla.com/cert.pem`, SAN `*.devzla.com` — single label only |
| DNS | no wildcard; `cg/rz/jp.devzla.com` have public records → 127.0.0.1 and are pinned in `/etc/hosts:10` |
| helper functions | `zlaverse/support/bash_functions.sh`, sourced from `~/.workrc:14`; `-log` aliases at `.workrc:16-23` |
