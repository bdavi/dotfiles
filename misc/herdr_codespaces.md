# Unifying local + GitHub Codespaces workspaces in herdr

Status: **implemented (Option A / herdr-mirror, 2026-08-06) — changes
applied to both `dotfiles` and `comoto-codespaces-dotfiles`, neither
committed nor run live.** See
[Implementation status](#implementation-status) for exactly what changed and
[Still open](#still-open) for what's left before a real test.
Supersedes an earlier draft of this file. Everything below has now been checked
against one of: the `herdr` binary actually installed on this machine (`herdr
0.7.5`), the `gh` CLI actually installed on this machine (`gh 2.97.0`), the
`nikok6/herdr-mirror` plugin's own README (fetched live), the GitHub CLI's own
source on `cli/cli` (fetched live), official `gh`/GitHub Codespaces docs
(fetched live), and — critically — the **actual `Comoto-Tech/dev-hub`
devcontainer config** (fetched live via `gh api`, not guessed at). The
earlier draft was written blind, without a live Codespace or repo access, and
had a few speculative caveats that this pass was able to resolve concretely.
Still, the end-to-end flow has never been run against a real Codespace —
treat this as a strong, verified starting point to test on the real machine,
not a copy-paste-and-forget solution.

## Goal (restated from the request)

One local herdr instance that shows both local workspaces and several GitHub
Codespaces workspaces (all created against `Comoto-Tech/dev-hub`), with this
workflow:

1. Start herdr locally; do local work in a local workspace.
2. Create a new herdr workspace.
3. In that new workspace, run a convenience function that lists existing
   Codespaces and offers a choice: connect to one, or create a new one and
   connect to it.
4. Once connected over SSH inside that local herdr workspace, running
   `herdr` should be enough to fold that remote herdr session into the local
   sidebar — no separate command run back on the local machine.

Lowest-friction version of this is the explicit design target. The rest of
this doc evaluates whether/how that's achievable and what it costs.

## Executive summary

- Steps 1–3 are straightforwardly buildable today with plain `gh`/shell
  scripting — nothing about them is blocked on anything speculative.
- Step 4, taken **literally** (SSH in, type `herdr`, it just appears
  locally) is only achievable with the **herdr-mirror plugin**, and even
  then the mechanism isn't "the ssh session pushes itself into view" — it's
  "the local herdr-mirror plugin is already polling that host in the
  background, and starting a herdr server on the Codespace gives it
  something to find." That's a subtle but important distinction (see
  [Mechanism check on step 4](#mechanism-check-on-step-4) below), and it's
  the one part of this plan that most needs a live test.
- herdr-mirror requires **both ends on herdr's preview channel**, and
  specifically a **preview build dated `2026-06-30` or newer** (not just
  "any preview build" — the plugin's README pins an exact date). This is a
  real, non-trivial tradeoff: it moves your daily-driver local herdr off the
  stable channel. **Decision: accepted** — see
  [Decision: preview channel](#decision-preview-channel--go-with-option-a-2026-08-06).
- The built-in `herdr --remote <alias>` (stable channel, no plugin) is a
  strictly safer fallback that satisfies steps 1–3 fully and step 4 partially
  (you'd run `herdr --remote <alias>` **from the local workspace**, not from
  inside an already-open SSH session — but it's one command, not two, so
  friction is still low). It just doesn't give a *unified* sidebar — it
  replaces the local view with the remote one, one Codespace at a time.
- The `dev-hub` devcontainer was inspected directly (see
  [dev-hub devcontainer findings](#dev-hub-devcontainer-findings)). SSH
  connectivity risk, which the original draft flagged as a maybe, is now
  resolved: `gh cs ssh` already works against `dev-hub` Codespaces today
  (proven by the existing `csclaude` alias and `misc/codespaces-notes.sh` in
  `comoto-codespaces-dotfiles`), so herdr-mirror's SSH precondition rides on
  a transport that's already known-good.

## Architecture options considered

### Option A — herdr-mirror plugin (unified sidebar, preview channel)

```
┌─────────────────────────┐        ssh (BatchMode, via gh's ProxyCommand)
│  Local machine             │ ─────────────────────────────────────────┐
│  herdr (preview channel)   │                                          │
│  + herdr-mirror plugin     │                                          ▼
│  ~/.config/herdr-mirror/   │                              ┌───────────────────┐
│  hosts.toml                │                              │  Codespace #1       │
└─────────────────────────┘                              │  herdr (preview)    │
          │                                                │  server, headless   │
          │ ssh (same mechanism, polled every               └───────────────────┘
          │ poll_seconds - tuned to 20s, see below)
          ▼
┌───────────────────┐
│  Codespace #2       │
│  herdr (preview)    │
│  server, headless   │
└───────────────────┘
```

Local herdr's sidebar shows local workspaces plus one grouped, prefixed
(`<host>: <name>`) section per Codespace, live-streamed and drivable in
place. This is the only option that satisfies the goal as literally stated
("all workspaces in a single instance"). Cost: preview channel on both ends,
a third-party plugin, and a bit more moving-parts surface (hosts.toml sync,
polling lag, exec-relay fallback edge case).

### Option B — `herdr --remote <alias>` (built-in, stable channel)

Shipped in stable herdr today, zero extra software, zero channel risk.
Attaches to one remote server at a time and **replaces** the local view
rather than showing local + remote together. Still satisfies "low friction" —
it's `herdr --remote <alias>` as a single command from the local workspace —
but it is not a unified sidebar, and it means picking one Codespace to look
at at a time (which may be a non-issue if you genuinely only work one
Codespace at a time in practice — worth clarifying).

### Option C — wait for native multi-remote, or use the community fork

herdr core has an open, active feature request for native multi-remote
support — [discussion #515](https://github.com/herdrdev/herdr/discussions/515)
on `herdrdev/herdr` (25.1k★, the real/official repo — verified directly, see
[Verified facts](#verified-facts)). As of 2026-08-06 the maintainer
reaffirmed (2026-07-13 update) it's still "top priority" but is blocked on
backend architecture work landing first — **unshipped, no ETA**. A community
proof-of-concept branch (`tahaalibra/herdr`) reportedly has multi-remote
working; treat that as unofficial and not something to build a documented
workflow on top of, but worth a periodic glance.

### Decisions made (2026-08-06)

- **Build Option A** (herdr-mirror) — preview-channel tradeoff accepted.
- **`cs-connect` and `cs-remote` stay separate**, no auto-fallback between
  them. `cs-connect` is the mirror-based path from the request; `cs-remote`
  is the manual stable-channel fallback if the mirror setup ever needs
  troubleshooting. You choose which to run.

## Decision: preview channel — **go with Option A** (2026-08-06)

Switching local herdr to preview is the load-bearing prerequisite for Option
A. Preview is herdr's pre-release channel — less tested than stable, and this
plan puts the daily-driver local herdr on it, not just a throwaway
environment. Every Codespace's herdr also needs to be on preview (low-stakes
there — Codespaces are disposable and get herdr auto-installed fresh by the
dotfiles bootstrap each time anyway).

**Decided: accept the tradeoff, build Option A (herdr-mirror).** Both `cs-connect`
(Option A, mirror-based) and `cs-remote` (Option B, stable fallback) are
still worth scripting side by side — `cs-remote` costs nothing extra to keep
around and is the documented fallback if preview/mirror ever misbehaves.

## Mechanism check on step 4

The request describes: SSH into the Codespace from inside a local herdr
workspace, then just run `herdr`, and that integrates the remote session
into the local one. Worth being precise about what "integrates" actually
means mechanically, because it's easy to read that as the `herdr` command
itself reaching back to the local machine — it doesn't work that way.

What actually happens under Option A:
1. Local herdr-mirror is **already** running in the background, per its
   `hosts.toml` config, polling every `poll_seconds` for a reachable herdr
   server at each configured host's SSH alias — regardless of whether you're
   currently SSH'd into that host yourself. Default is 60s; tuned down to
   **20s** in the `hosts.toml` this plan generates (see
   [poll_seconds tuning](#nikok6herdr-mirror-plugin-fetched-live-from-its-readme)
   below) since the request favors low friction over background-check
   overhead.
2. Running `herdr` on the Codespace starts (or attaches to) a herdr server
   there, because that's what `herdr` does on first run.
3. On its next poll, local herdr-mirror finds a server now listening and
   mirrors its workspaces into the local sidebar.

So the SSH session you're sitting in when you type `herdr` is almost
incidental — what matters is that (a) the host is registered in
`hosts.toml` before you connect (handled by syncing on every `cs-connect`
call, see below), and (b) a herdr server ends up running there. The practical
effect matches the request (run `herdr`, it shows up locally) but with up to
~20s of poll lag, and it would technically work the same way even if you
never manually SSH'd in at all (e.g. mirror could pick up a server someone
else started). This is the single piece of the whole plan most worth
confirming live, since it was never run against a real Codespace.

## `dev-hub` devcontainer findings

Fetched directly via `gh api repos/Comoto-Tech/dev-hub/contents/...` (repo
access, not a live Codespace — `gh auth status` on this machine already has
`repo` scope). Relevant facts, not guesses:

- **Base image**: `mcr.microsoft.com/vscode/devcontainers/base:3-alpine` —
  explains why `comoto-codespaces-dotfiles/script/setup` uses `apk`, and why
  it pulls Neovim/ripgrep/etc. from Alpine's `edge` repos (the base repos are
  too old for the plugin set in use).
- **A custom `./local/sshd` devcontainer feature is already declared.**
  Its `install.sh` runs `apk add openssh-server-pam ...`, generates host
  keys, and starts `sshd` on **port 2222** with a random password — intended
  for a *different* use case than `gh cs ssh` (its own echoed instructions
  say "forward port 2222 to your local machine and run `ssh -p 2222 ...
  vscode@localhost`" — this is a direct/JetBrains-Gateway-style path, not the
  one `gh cs ssh`/herdr-mirror will use).
- **`gh cs ssh` itself is already proven working against `dev-hub`
  Codespaces** — independent of the port-2222 feature above. Evidence: the
  existing `.commonrc` alias `csclaude='HERDR_AGENT=claude gh cs ssh'` and
  `comoto-codespaces-dotfiles/misc/codespaces-notes.sh`'s documented `gh cs
  ssh` usage are real, currently-used workflow, not aspirational notes. Web
  research independently confirms `gh cs ssh` needs a real sshd inside the
  container and fails outright on custom minimal images that lack one
  (sources below) — so the fact that it already works here means `dev-hub`'s
  Codespaces do have a working sshd for `gh cs ssh`'s own transport, sourced
  from somewhere in the base image/platform setup, separate from the custom
  port-2222 feature. Net effect: **the original draft's "might need to add
  the sshd devcontainer feature" caveat is resolved — not needed, already
  works.**
- Also present: `ghcr.io/tailscale/codespace/tailscale` feature. Unlikely to
  interact with `gh cs ssh` (which tunnels via GitHub's own relay, not raw
  network), noted here only in case networking-related surprises show up
  during live testing.
- `postAttachCommand: "./setup.sh"` in the devcontainer is a **separate**
  mechanism from the personal-dotfiles bootstrap (`script/setup` in
  `comoto-codespaces-dotfiles`, wired up via GitHub's account-level
  Settings → Codespaces → dotfiles selection). No conflict between them, but
  worth knowing they're two different systems if something needs debugging.
- `python3`/`socat` (needed only if herdr-mirror's exec-relay fallback
  triggers — see below) aren't explicitly installed by
  `comoto-codespaces-dotfiles/script/setup` today. Low priority: only add if
  a live test shows the mirror actually falling back to exec relay.

## Verified facts

### herdr core CLI (checked directly against the local binary, `herdr 0.7.5`)

All of the following were run directly on this machine, not taken from docs:

| Command | Confirmed |
|---|---|
| `herdr channel show` / `herdr channel set <stable\|preview>` | Yes — `channel show` currently prints `stable` |
| `herdr --remote <ssh-target> [--session <name>]` | Yes — shipped, stable-channel, documented in `herdr --help` itself |
| `herdr update [--handoff]` | Yes |
| `herdr plugin install <owner>/<repo> -y`, `plugin uninstall/link/unlink/enable/disable/list/config-dir/action/log/pane` | Yes — full subcommand list confirmed via `herdr plugin --help`; this machine already has 4 plugins installed this way |
| `herdr server reload-config`, `server stop`, `server agent-manifests`, etc. | Yes |
| `herdr workspace create --cwd <path> --label <text> [--focus\|--no-focus] --env <K=V>` | Yes — this is the real flag set for step 2 |
| `herdr workspace list/get/focus/rename/close`, `herdr api snapshot/schema` | Yes — `workspace list` and `api snapshot` both return live JSON; useful primitives if the convenience functions ever want to check what's already open locally before creating a new workspace |
| `[remote]` config section, `manage_ssh_config` (default true) | Yes — confirms `herdr --remote` includes your real `~/.ssh/config` and only adds keepalive/multiplexing as fallbacks, so `gh`'s generated Codespace SSH aliases (via `~/.ssh/codespaces`, included from `~/.ssh/config`) work with `--remote` unmodified |

One correction from the original draft: `herdr plugin install ... -y` (short
flag) is what this repo's own `lib/herdr.sh` already uses successfully
today — it works — but the documented/canonical spelling on herdr.dev is
`--yes`. Fine to keep `-y` (proven), but prefer `--yes` in any new script for
future-proofing.

### `nikok6/herdr-mirror` plugin (fetched live from its README)

- Real, active, 100+★ (star counts drift; don't hardcode a number
  anywhere scripts might print it).
- Purpose confirmed: mirrors several remote herdr servers into the local
  sidebar simultaneously, prefixed `<host>: <name>`, live-streamed —
  distinct from core `--remote`'s 1:1 replace-view model.
- **Exact version requirement, quoted**: "Both ends: herdr with the
  `terminal session` streams — preview build `2026-06-30` or newer
  (`herdr channel set preview`), until the next stable." This is more
  specific than "just be on preview" — it's a build-date floor. Given
  today is 2026-08-06, any current preview pull almost certainly clears
  it, but this should be confirmed live after switching channels rather
  than assumed.
- **`~/.config/herdr-mirror/hosts.toml` schema, confirmed and expanded**
  beyond what the original draft captured:
  - Global (optional): `autostart` (default true), `poll_seconds` (default
    60), `default_host`, `close_remote_on_local_close` (default true),
    `always_control` (default true).
  - Per-host (SSH targets, what we need): `target` (required), `prefix`,
    `remote_bin`, `always_control`, `enabled` (default true), `api_transport`
    (`auto`/`socket`/`exec`).
  - Per-host (Docker targets — not relevant here): `kind`, `folder`,
    `container`, `docker_bin`, `remote_bin`, `prefix`.
  - No auto-discovery — `enabled`/`disabled` toggles on already-listed hosts
    only, confirming the sync script's regenerate-on-change approach is the
    right model.
  - **`poll_seconds` decision**: default 60s, tuned down to **20s** here to
    cut the lag between running `herdr` on a fresh Codespace and it showing
    up in the local sidebar (see
    [Mechanism check on step 4](#mechanism-check-on-step-4)). Traded off
    against more frequent background SSH checks against every configured
    host — accepted as worth it for the low-friction goal. `poll_seconds` is
    a *global* key, which TOML requires to appear before any `[hosts.x]`
    table in the file — `cs-sync` below writes it as the first line of its
    managed block for that reason; if you ever hand-add anything of your own
    to `hosts.toml` outside the managed markers, keep it above the markers
    too, or it'll land after a table and fail to parse.
- **"The remote needs no plugin — just herdr"** — confirmed verbatim.
  Codespaces only need herdr itself (on preview), not herdr-mirror.
- **SSH precondition, confirmed verbatim**: `ssh -o BatchMode=yes <host>
  true` must succeed without a prompt.
- **Exec-relay fallback, new detail not in the original draft**: activates
  automatically when SSH socket forwarding fails; needs `socat` or `python3`
  on the remote for that path (mandatory for Docker targets, not relevant to
  us there). Given `dev-hub`'s Alpine base, worth installing `socat` in
  `comoto-codespaces-dotfiles/script/setup` proactively, or just watching
  for a fallback warning on first live test and adding it then.
- **New detail on mirror control semantics**: mirrored (remote) workspaces
  are read-only until you type into them, then control escalates to you and
  auto-releases after 1h idle. Relevant to know before being surprised by it
  live.
- Limitations, confirmed verbatim: latency overhead vs raw ssh; no git
  status on mirror rows (herdr derives that from local cwd, no API for
  remote repo state); no custom sidebar UI beyond the `<host>: ` prefix
  (plugin API limitation); a down/incompatible host surfaces a readable
  status rather than failing silently.

### `gh codespace ssh` (checked against `cli.github.com/manual` and live `cli/cli` trunk source)

- `gh codespace ssh --config` exists, writes an OpenSSH config block to
  stdout, and the recommended `~/.ssh/codespaces` + `Include` pattern in the
  original draft matches official usage exactly.
- The generated template was pulled **byte-for-byte** from current
  `cli/cli` trunk (`pkg/cmd/codespace/ssh.go`, `printOpenSSHConfig`, ~line
  633): `Host cs.{{.Name}}.{{.EscapedRef}}`, `User {{.SSHUser}}`,
  `ProxyCommand {{.GHExec}} cs ssh -c {{.Name}} --stdio -- -i
  {{.AutomaticIdentityFilePath}}`, `UserKnownHostsFile=/dev/null`,
  `StrictHostKeyChecking no`, `LogLevel quiet`, `ControlMaster auto`,
  `IdentityFile {{.AutomaticIdentityFilePath}}` — matches the original draft
  exactly.
- The identity file is generated lazily, the **first time** the
  `ProxyCommand` actually runs (`generateAutomaticSSHKeys`, ssh.go
  ~line 316-420), with an empty passphrase (`GenerateSSHKey(name, "")`) —
  confirms nothing needs pre-seeding, the first real connection attempt
  creates it.
- A real historical bug existed here — a stale/missing
  `codespaces.auto` key file could break this
  ([cli/cli#9817](https://github.com/cli/cli/issues/9817)) — but it was
  fixed in `gh` v2.61.0 ([cli/cli#9881](https://github.com/cli/cli/pull/9881)).
  This machine runs `gh 2.97.0`, well past the fix. Not a live concern, noted
  only because it's the kind of thing that would look like a herdr-mirror
  problem if it ever resurfaced on an old `gh`.
- `gh auth` needs the `codespace` scope; `gh auth refresh -h github.com -s
  codespace` is the correct current command. **Checked live on this
  machine**: `gh auth status` currently shows scopes `admin:public_key,
  gist, read:org, repo` — no `codespace` scope. This refresh is a real,
  currently-outstanding one-time step, not hypothetical.
- **New finding, not in the original draft**: `--config`'s codegen silently
  **skips unavailable/stopped Codespaces** (logs `"skipping unavailable
  codespace %s: %s"` to stderr, and the command can return non-zero even
  though the config it wrote is otherwise fine). `cs-sync` (in
  `config_files/.workrc-codespaces`) accounts for this and doesn't treat it
  as fatal — the original draft's `set -euo pipefail` around a bare `gh
  codespace ssh --config > ...` would have aborted the whole sync any time
  one Codespace happened to be stopped.
- No newer/superseding flow found — `--profile` exists but is orthogonal
  (selects an SSH profile), not a replacement for `--config`.

### GitHub Codespaces dotfiles bootstrap

- Entrypoint filename list confirmed verbatim against
  [the official docs](https://docs.github.com/en/codespaces/setting-your-user-preferences/personalizing-github-codespaces-for-your-account):
  `install.sh, install, bootstrap.sh, bootstrap, script/bootstrap, setup.sh,
  setup, script/setup`. `comoto-codespaces-dotfiles/script/setup` is already
  a valid entrypoint on that list (and evidently already selected in GitHub
  account settings, since it's the mechanism that currently installs herdr,
  Neovim, etc. on every new Codespace).
- Default Codespaces devcontainer base images ship `sshd` already; it's
  specifically **custom/minimal images** that may not — consistent with why
  `dev-hub`'s Alpine-based devcontainer needed its own sshd-related feature
  work (see [dev-hub devcontainer findings](#dev-hub-devcontainer-findings)
  above for the concrete, repo-specific version of this).

## Applied changes — `dotfiles` (local machine)

**Applied 2026-08-06.** Full rationale for each function lives as comments in
the actual files (linked below) rather than duplicated here — this section
summarizes what changed and why, so it doesn't drift out of sync with the
real code.

### `scripts/dev_box/lib/herdr.sh`

Two functions added: `switch_herdr_to_preview_channel` and
`install_herdr_mirror_plugin`, following the file's existing idempotent,
`$HERDR_ENV`-aware style (see the existing `install_latest_herdr` for that
pattern).

One real bug caught while implementing, which is exactly what "ensure the
correct version of herdr is installed" needed to fix: the original sketch's
call order was `switch_herdr_to_preview_channel` *then*
`install_latest_herdr` — but `switch_herdr_to_preview_channel` runs `herdr
channel show`, which fails outright on a genuinely fresh box with no herdr
binary yet (that's what `install_latest_herdr` installs). Corrected order,
now applied: `install_latest_herdr` **first** (guarantees a binary exists,
on whatever channel it starts on — normally stable), **then**
`switch_herdr_to_preview_channel` (switches channel and re-runs `herdr
update` so the binary actually matches — `channel set` alone only changes
where *future* updates pull from, it fetches nothing by itself). Both
functions now log the resulting `herdr --version` after updating, and
`switch_herdr_to_preview_channel` logs a reminder of herdr-mirror's
`2026-06-30`+ build-date requirement, since there's no reliable way to
parse/verify that programmatically without having seen a real preview
version string (never available in this session — no live Codespace or
preview build to inspect).

### New file: `scripts/dev_box/lib/herdr_codespaces.sh`

Idempotent one-time SSH config wiring, sourced from `build_ubuntu.sh` right
after `herdr.sh`. Two functions:

- `ensure_gh_codespace_scope` — checks (doesn't run) for the `codespace`
  OAuth scope, since `gh auth refresh` is interactive and has no place in an
  unattended build (this script also runs from the daily cron job). Logs
  the exact command to run and returns non-fatal (1) rather than aborting
  the rest of the build.
- `ensure_ssh_config_includes_codespaces` — idempotently adds `Include
  ~/.ssh/codespaces` to `~/.ssh/config`, using the same grep-before-append
  idiom `lib/default_apps.sh` already uses for `~/.config/xfce4/helpers.rc`.

Deliberately does **not** run the hosts.toml sync itself — that needs to
re-run every time the Codespace list changes, not just at build time, so it
lives as the on-demand `cs-sync` function in `.workrc-codespaces` instead.

### New file: `config_files/.workrc-codespaces`

The convenience functions from the request — `cs-sync`, `cs-connect`,
`cs-remote`, plus internal helpers `_cs_list_raw`/`_cs_pick`/`_cs_create`.
Every function logs to stderr, deliberately verbose since none of this was
tested against a live Codespace.

Key design points (full code + comments in the file itself):

- `cs-sync` regenerates `~/.ssh/codespaces` and the managed `[hosts.*]`
  block in herdr-mirror's `hosts.toml`, then reloads the local herdr server.
  Handles the researched `gh codespace ssh --config` non-fatal-nonzero-exit
  case (stopped Codespaces get skipped, not a real failure) — the original
  draft's naive `set -euo pipefail` version would have aborted on that.
  Writes `poll_seconds = 20` as the first line of its managed block, since
  TOML requires global keys before any `[table]` — see the `poll_seconds`
  decision in [Verified facts](#nikok6herdr-mirror-plugin-fetched-live-from-its-readme).
- `_cs_pick` uses `fzf` (confirmed already installed locally, via the
  Neovim setup) if present, else a plain `select` menu — the "existing
  Codespaces + Create new" picker from step 3 of the request.
- `cs-connect` is the step-3/step-4 entry point: syncs, picks/creates, then
  `exec`s straight into `gh codespace ssh` (not a subshell call) so the herdr
  workspace's pane just becomes "you, inside the codespace shell" — same
  pattern as the existing `csclaude` alias in `.commonrc`.
- `cs-remote` is the manual Option B fallback (`herdr --remote`, no plugin
  needed) — kept as a separate function per the no-auto-fallback decision,
  not invoked automatically by `cs-connect`.

One naming fix made while implementing: the original sketch had `local
alias=...` inside `cs-remote`, which merely *shadows* — doesn't break — the
`alias` builtin (bash keeps variable and command namespaces separate), but
reads confusingly next to a real `alias` command a few lines away in
`.commonrc`. Renamed to `ssh_alias` in the applied file.

**Sourcing decision, revised 2026-08-06**: this `dotfiles` repo is shared
between a personal machine and a work machine, and `~/monorepo` only exists
on the work machine (new context, not known when the original "always load"
decision was made below) — so the Codespaces integration should only load
on the work machine. `.commonrc` now sources `~/.workrc-codespaces` **from
inside** the existing `if [ -d "/home/brian/monorepo" ]` block, right after
`~/.workrc`, reversing the earlier "always load, regardless of `~/monorepo`"
decision (superseded — see the updated decisions log below). No separate
symlinking step was needed: `scripts/install_dotfiles.sh` already does `cp
-rsf config_files/. ~`, which picks up any new file in `config_files/`
automatically, hidden files included.

Same reasoning applied to `build_ubuntu.sh`, since this build script is also
shared across both machines: `switch_herdr_to_preview_channel`,
`install_herdr_mirror_plugin`, `ensure_gh_codespace_scope`, and
`ensure_ssh_config_includes_codespaces` are now called inside an `if [ -d
"$HOME/monorepo" ]` block, **after** the plugin installs that stay
unconditional (`install_herdr_vim_navigation_plugin` and friends — those are
useful on the personal machine too, just not the Codespaces-specific parts).
`install_latest_herdr` itself also stays unconditional, both machines use
herdr day to day.

## Applied changes — `comoto-codespaces-dotfiles` (Codespaces side)

**Applied 2026-08-06.** One change, to `script/setup` (the dotfiles
bootstrap entrypoint GitHub already runs automatically on every new
`dev-hub` Codespace — see
[GitHub Codespaces dotfiles bootstrap](#github-codespaces-dotfiles-bootstrap)
above): before the existing `herdr update` block, added a channel check that
switches to preview if not already there, mirroring
`switch_herdr_to_preview_channel`'s logic on the local-machine side (same
"switching channel doesn't itself fetch anything" reasoning, so the
subsequent `herdr update` still has to run). Also added a post-update
`herdr --version` log line, for the same reason as the local side: no way to
verify the `2026-06-30`+ build-date requirement programmatically without
having seen a real preview version string, so this at least makes the
installed version visible in the Codespace's setup log for a human to check.

No herdr-mirror plugin install added here — confirmed in
[Verified facts](#nikok6herdr-mirror-plugin-fetched-live-from-its-readme)
that "the remote needs no plugin — just herdr."

## Decisions log (2026-08-06)

| Question | Decision |
|---|---|
| Preview channel vs. stay stable | **Go with Option A** (herdr-mirror, preview channel) |
| `cs-connect` auto-fallback to `cs-remote`? | **No** — kept as two separate, manually-chosen functions |
| Where `.workrc-codespaces` is sourced from | ~~Always load~~ **Superseded**: gated behind `~/monorepo` (same signal `.workrc` itself uses) — `dotfiles` is shared between a personal machine and a work machine, and Codespaces integration should only run on the work machine, where `~/monorepo` (and the actual `monorepo` checkout) lives |
| `poll_seconds` | **Tuned to 20s** (from herdr-mirror's 60s default) |
| `build_ubuntu.sh` gating | Same `~/monorepo` check now wraps `switch_herdr_to_preview_channel`, `install_herdr_mirror_plugin`, `ensure_gh_codespace_scope`, `ensure_ssh_config_includes_codespaces` — the base herdr install and its non-Codespaces plugins stay unconditional |

## Still open

All script changes described above are now applied to both repos (not yet
committed — see [Implementation status](#implementation-status) below).
Remaining open items:

- **Picker UX** — `cs-connect`/`cs-remote` were implemented with the fzf
  default sketched above (falls back to plain `select` if fzf is missing).
  Revisit if that's not what you want.
- Anything from the [Mechanism check on step 4](#mechanism-check-on-step-4)
  section that changes the shape of what you want, now that it's spelled
  out precisely — this is still the one piece of the whole plan that's
  never been run against a real Codespace.
- The `gh auth refresh -h github.com -s codespace` one-time step is still
  outstanding on this machine (confirmed missing under
  [Verified facts](#gh-codespace-ssh-checked-against-cligithubcommanual-and-live-clicli-trunk-source))
  — `ensure_gh_codespace_scope` will log instructions for it on the next
  build run rather than doing it itself.

## Implementation status

- `dotfiles`: `scripts/dev_box/lib/herdr.sh` (2 new functions),
  `scripts/dev_box/lib/herdr_codespaces.sh` (new file), `config_files/.workrc-codespaces`
  (new file), `config_files/.commonrc` (1 new source line),
  `scripts/dev_box/build_ubuntu.sh` (sources the new lib, calls the new
  functions).
- `comoto-codespaces-dotfiles`: `script/setup` (preview-channel switch
  added).
- **`build_ubuntu.sh` has been run on this machine** (confirms it has
  `~/monorepo`, i.e. it's the work machine — the Codespaces-gated block
  executed). Confirmed live via `herdr status`/`herdr channel
  show`/`herdr plugin list`: local herdr is now on the **preview channel**,
  version `0.8.0-preview.2026-08-04-d78e3d3b5126` — clears the `2026-06-30`
  floor herdr-mirror requires — and `mirror` (nikok6/herdr-mirror) shows up
  installed and enabled alongside the other 4 plugins. `config_files/.config/herdr/config.toml`
  now has a `[update]\nchannel = "preview"` block that wasn't there before —
  `herdr channel set` writes to `config.toml` itself, which the file's own
  header comment (in `lib/herdr.sh`) didn't previously account for
  (previously said "herdr only *reads* it" except for onboarding — narrowly
  true until this, worth a follow-up comment fix, not done as part of this
  session since it's unrelated to the task at hand).
- Still outstanding: `gh auth refresh -h github.com -s codespace` (checked
  live — `codespace` scope still missing), and no live Codespace has been
  touched yet (no `cs-connect`/`cs-sync` run, `comoto-codespaces-dotfiles/script/setup`
  not yet run on an actual Codespace). First real test against a live
  Codespace is still pending.

## Fallback if Option A doesn't pan out

Already covered above as Option B / `cs-remote` — real, shipped, stable,
zero extra risk, just not a unified sidebar.

## Sources

- `herdr --help`, `herdr plugin --help`, `herdr channel --help`, `herdr
  workspace --help`, `herdr session --help`, `herdr server --help`, `herdr
  --default-config`, `herdr status`, `herdr plugin list` — all run directly
  against the locally installed `herdr 0.7.5`
- [nikok6/herdr-mirror](https://github.com/nikok6/herdr-mirror) README,
  fetched live
- [herdrdev/herdr](https://github.com/herdrdev/herdr) — verified directly as
  the real/official repo (25.1k★, Apache 2.0)
- [herdr discussion #515](https://github.com/herdrdev/herdr/discussions/515)
  (native multi-remote status)
- [`gh codespace ssh` manual](https://cli.github.com/manual/gh_codespace_ssh)
  and `pkg/cmd/codespace/ssh.go` on `cli/cli` trunk, fetched live
- [cli/cli#9817](https://github.com/cli/cli/issues/9817) /
  [#9881](https://github.com/cli/cli/pull/9881) (historical SSH key bug,
  fixed in gh v2.61.0; this machine runs 2.97.0)
- [GitHub Docs: Personalizing GitHub Codespaces for your account](https://docs.github.com/en/codespaces/setting-your-user-preferences/personalizing-github-codespaces-for-your-account)
- `gh api repos/Comoto-Tech/dev-hub/contents/...` — `.devcontainer/devcontainer.json`
  and `.devcontainer/local/sshd/{devcontainer-feature.json,install.sh}`,
  fetched live from the actual repo
- `gh --version`, `gh auth status` — run directly on this machine
- `~/code/dotfiles/config_files/.commonrc`,
  `~/code/comoto-codespaces-dotfiles/misc/codespaces-notes.sh` — existing,
  already-used `gh cs ssh` workflow on this machine, used as empirical proof
  that `dev-hub` Codespaces already support it
