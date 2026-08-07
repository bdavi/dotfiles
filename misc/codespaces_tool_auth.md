# Sharing tool authentication with GitHub Codespaces

Status: **Both sections decided and implemented — ready to run on the work
machine, not here.** `cs-sync-gcloud` is already written into
`config_files/.workrc-codespaces`; nothing left to build, just to run.
Sibling doc to
[`misc/herdr_codespaces.md`](herdr_codespaces.md) (that one's about mirroring
herdr workspaces; this one's about not having to re-authenticate other tools
in every Codespace) — separate concern, no dependency between them.

## Goal

Running several `Comoto-Tech/dev-hub` Codespaces at once, and re-authenticating
Claude Code and `gcloud` separately in each one is real friction. Want the
local machine's authenticated state to reach every Codespace automatically,
refreshing as needed without manual re-login per Codespace.

## Claude Code

### The mechanism, and why it works

- `claude setup-token` mints a **one-year OAuth token**
  (`sk-ant-oat01-...`). Anthropic's own docs frame this specifically as the
  mechanism for "CI pipelines, scripts, or other environments where
  interactive browser login isn't available" — a Codespace is exactly that
  environment, not an edge case being stretched to fit.
- Claude Code reads it via the `CLAUDE_CODE_OAUTH_TOKEN` env var. Confirmed
  precedence order (highest to lowest): cloud-provider auth (Bedrock/Vertex/
  Foundry) → `ANTHROPIC_AUTH_TOKEN` → `ANTHROPIC_API_KEY` → `apiKeyHelper` →
  **`CLAUDE_CODE_OAUTH_TOKEN`** → plain subscription `/login`. So it wins
  automatically as long as nothing higher in that list is also set — checked
  both dotfiles repos, neither currently sets `ANTHROPIC_API_KEY` or
  `ANTHROPIC_AUTH_TOKEN` anywhere, so there's no conflict to clean up first.
- Critically, this token is **independent of the local interactive login**
  (`~/.claude/.credentials.json`, which stores the browser-login OAuth
  session). It does not need re-syncing when the local session refreshes or
  you re-log-in locally — set once, valid for a year, done. This is the
  reason Claude Code doesn't need the same kind of ongoing-sync machinery
  the gcloud side might.
- Considered and rejected: copying `~/.claude/.credentials.json` itself to a
  Codespace. That file genuinely is the portable Linux credential store (no
  keychain-wrapping to fight), but Anthropic's docs never document or endorse
  copying it between machines — `setup-token` is the actual documented path
  for this scenario, so use that instead of relying on undocumented behavior.

### Why a GitHub Codespaces secret, not a script/SSH push

- Codespaces secrets are injected as env vars into every Codespace
  automatically once set — no changes needed to
  `comoto-codespaces-dotfiles/script/setup` or anything in this `dotfiles`
  repo. Simplest possible mechanism for something that's genuinely "set once."
- One propagation caveat, confirmed against GitHub's own docs: a secret
  update only reaches *new* Codespaces, or existing ones after a restart —
  GitHub's own wording: "If you've created a secret on GitHub and you want to
  use it in a currently running codespace, stop the codespace and then
  restart it." Since this particular token doesn't need repeat updates, this
  only matters once: any Codespace already running when the secret is first
  set needs one restart to pick it up. New Codespaces created afterward get
  it automatically.
- Considered and rejected: pushing the token over the `gh codespace ssh`
  transport `cs-sync` already uses (see `config_files/.workrc-codespaces`).
  Unnecessary complexity for a value that's set once and never touched again
  — that machinery is worth it for gcloud specifically (see below), where
  the credential genuinely needs active resyncing, not here.

### Steps (work machine, not this one)

1. `claude setup-token` — opens a browser, walks through the normal Claude.ai
   OAuth flow, then prints a token starting `sk-ant-oat01-...` to the
   terminal **once**. Nothing is saved to disk automatically — capture it
   immediately from the terminal output; it can't be retrieved again if lost
   (just mint a new one in that case).
2. `gh secret set CLAUDE_CODE_OAUTH_TOKEN --user` — run this interactively so
   the value is typed/pasted straight into `gh`'s own prompt and never lands
   anywhere else (not a chat, not a committed file, not a script argument
   that'd show up in shell history). `--user` is the correct flag — per
   `gh secret set --help`: "user: available to Codespaces for your user."
   (Not `--app codespaces`, which is the repo/org-level flag; not scoped to
   `Comoto-Tech/dev-hub` specifically, since this is about the account, not
   any one repo.)
3. Restart any Codespace that's already running so it picks up the
   newly-set secret (`gh codespace stop -c <name>`, then reconnect — or via
   the Codespaces UI). New Codespaces created after this point get it
   automatically, no restart needed.
4. Verify: inside a Codespace, `claude auth status` should report
   authenticated via the token; running `claude` itself should not prompt
   for login.

### Security considerations

- Treat the printed token exactly like a password — Anthropic's own docs
  frame it this way. Anyone holding it can use the subscription behind it.
- **Revocation is currently unreliable — a real, open gap, not a
  hypothetical.** [anthropics/claude-code#43801](https://github.com/anthropics/claude-code/issues/43801)
  reports that "log out all sessions" on claude.ai does not reliably
  invalidate `setup-token`-issued tokens (one report: persisted 3-4 days,
  survived a VM cold boot). There's no `claude setup-token --list`/`--revoke
  <id>` yet either — both tracked as open feature requests
  ([#48373](https://github.com/anthropics/claude-code/issues/48373),
  [#57400](https://github.com/anthropics/claude-code/issues/57400)). If this
  token ever needs to be killed, the current reliable path is claude.ai →
  Settings → active sessions
  ([support article](https://support.claude.com/en/articles/13124001-managing-your-active-sessions)),
  one session at a time — not a CLI command.
- Narrower blast radius than a full interactive login, at least: per
  Anthropic's docs, a `setup-token` credential "can only make model
  requests, so it can't establish Remote Control sessions or fetch claude.ai
  connectors."
- Net: one token, shared across every Codespace, real (if scope-limited)
  exposure if a Codespace is compromised, no clean single-command revoke
  today. Worth being deliberate about before generating it — it's a one-time
  step, not something to redo casually once minted.

### Sources

- [code.claude.com/docs/en/authentication](https://code.claude.com/docs/en/authentication)
  — `setup-token`, `CLAUDE_CODE_OAUTH_TOKEN`, precedence order, CI framing,
  scope limitation
- [GitHub Docs: Managing account-specific secrets for Codespaces](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces)
  — secrets mechanism, restart-to-propagate caveat
- `gh secret set --help`, run directly on this machine — confirmed `--user`
  flag and its exact description
- [anthropics/claude-code#43801](https://github.com/anthropics/claude-code/issues/43801),
  [#48373](https://github.com/anthropics/claude-code/issues/48373),
  [#57400](https://github.com/anthropics/claude-code/issues/57400) —
  revocation gaps
- [Managing your active sessions](https://support.claude.com/en/articles/13124001-managing-your-active-sessions)
  — the current manual revoke path
- Checked locally: neither `dotfiles` nor `comoto-codespaces-dotfiles` sets
  `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` anywhere, so nothing
  competes with `CLAUDE_CODE_OAUTH_TOKEN` in the precedence order

## gcloud

Status: **decided and implemented** — `cs-sync-gcloud` in
`config_files/.workrc-codespaces`, ready to run on the work machine.

### On Google's own warning, and why this proceeds anyway

Verified directly (not just cited secondhand) against
[Authenticate for the gcloud CLI](https://docs.cloud.google.com/sdk/docs/authorizing):

> Any user with access to your file system can use the stored access
> credentials created by `gcloud auth login`. To reduce the consequences of
> a system being compromised, strictly separate human and workload use, and
> don't use `gcloud auth login` for automated workloads on remote systems
> with persistent storage.

Deliberate judgment call, made after reading that source directly: this
warning is aimed at **automated, unattended workloads** running on shared or
persistent remote systems — a CI runner, a cron job, a service. A Codespace
here is a **human-driven interactive dev environment**, reached over your
own authenticated SSH session, and it's going to have *some* gcloud
credential on it regardless — the only actual choice is whether that
credential got there via a manual `gcloud auth login` run inside the
Codespace, or via a sync from the identical login already sitting on the
local machine. The warning's blanket framing doesn't map cleanly onto that.

One part of Google's stated reasoning still applies regardless of
automated-vs-human framing, though, and shapes the design below: "any user
with access to your file system can use the stored credentials" isn't only
about other *people* on a shared automated system — inside a Codespace it
also covers anything that runs code under your account there (an `npm
install` pulling a compromised package, a devcontainer feature, a build
step). That's not a reason to abandon this, but it's why the design below
minimizes what actually lands on disk and locks down its permissions,
rather than just mirroring the whole `~/.config/gcloud` tree.

Also relevant, for handling a leak if one ever happens:
[Best practices for mitigating compromised OAuth tokens for Google Cloud CLI](https://docs.cloud.google.com/architecture/bps-for-mitigating-gcloud-oauth-tokens).

### The mechanism, and why it works

- Two genuinely separate credential sets make up "being logged into
  gcloud," confirmed distinct, not two views of one thing:
  `gcloud auth login`'s own store (`credentials.db`, a SQLite file — used
  by `gcloud` CLI commands themselves) and the separate
  `gcloud auth application-default login`'s
  `application_default_credentials.json` (Application Default Credentials —
  used by client-library code, e.g. Python/Node/Go SDKs). Both get synced;
  ADC is optional (only present if that separate login was ever run
  locally) and handled gracefully if absent.
- Unlike Claude Code, there's no `setup-token`-equivalent here — no
  independent, long-lived credential that can be minted once and forgotten.
  gcloud's refresh tokens are tied to the interactive login itself, so this
  genuinely needs an active push, not a one-time setup.
- **Decision: overwrite `~/.config/gcloud` directly** on each Codespace
  (not a side directory + `CLOUDSDK_CONFIG`) — simplest option, matches "as
  if you'd logged in there yourself" exactly. `CLOUDSDK_CONFIG` is real and
  Google's own docs cite the motivating case as "running commands inside
  docker," a container scenario directly analogous to a Codespace — noted
  here as the road not taken, in case the direct-overwrite approach ever
  needs revisiting (e.g. if a Codespace's own gcloud state is ever worth
  preserving separately from the synced copy).
- **Decision: manual trigger, not automatic.** `cs-sync-gcloud` is a
  function you run yourself, any time after re-authenticating locally —
  not folded into `cs-connect`'s automatic flow, and not a background
  file-watcher. Starts simple, no new always-on process to build or keep
  alive; upgradeable later (fold into `cs-connect`, or add a local watcher
  on `credentials.db`'s mtime) if manual triggering gets tedious in
  practice.
- **Considered and rejected: short-lived access-token relay**
  (`gcloud auth print-access-token` / `application-default
  print-access-token`, ~1hr lifetime) instead of syncing the long-lived
  refresh token. Lower blast radius in principle, but needs an actual
  ongoing timer on both ends rather than a simple push — more moving parts
  than this use case's threat model (see above) justifies. Worth
  reconsidering only if the direct-copy approach turns out to be a real
  problem in practice.
- **Curated file set, not the whole `~/.config/gcloud` tree.**
  `cs-sync-gcloud` only pushes `credentials.db`, `active_config`,
  `configurations/config_default`, and (if present)
  `application_default_credentials.json` — not `logs/`, `.metrics.uuid`,
  cached CLI surveys, or anything else that directory accumulates. Keeps
  what actually lands on each Codespace to credential/config material only.
- **File permissions locked to 600 after copying** — matches gcloud's own
  restrictive defaults, directly addressing the "any process running under
  your account" risk from Google's warning above, rather than leaving
  synced files at whatever permissions `scp` happens to produce.
- Transport reuses the exact same `gh codespace ssh`-managed SSH aliases
  (`~/.ssh/codespaces`) `cs-sync`/`cs-connect` already depend on — no new
  auth mechanism, just pushing files over a channel already proven working
  end to end (see `misc/herdr_codespaces.md`'s live test results).
  `cs-sync-gcloud` calls `cs-sync` itself first, so the alias list is
  current, then loops over **every** currently running Codespace (not just
  one) — matches "running many Codespaces simultaneously."

### Steps (work machine, not this one)

1. Make sure you're logged in locally the way you want every Codespace to
   be: `gcloud auth login`, and `gcloud auth application-default login` too
   if you use client libraries (Python/Node/Go SDKs, Terraform, etc.) from
   inside a Codespace, not just `gcloud` commands directly.
2. Run `cs-sync-gcloud`. It refreshes the Codespace SSH alias list, then
   pushes the files listed above to every currently running
   `Comoto-Tech/dev-hub` Codespace, logging progress per target.
3. Verify inside a Codespace: `gcloud auth list` should show the same
   active account as the local machine, and (if ADC was synced)
   `gcloud auth application-default print-access-token` should succeed
   without prompting for login.
4. Whenever you re-authenticate locally (a fresh `gcloud auth login`, a
   different account, etc.), just run `cs-sync-gcloud` again — that's the
   whole "refresh" step, no separate command to remember.

### Security considerations

- This copies real, working credential material (not a scoped-down token)
  to every Codespace it targets. Treat each Codespace as holding a live
  copy of your gcloud login for as long as it's running.
- **The mitigating safety net**: for user-account credentials specifically
  (not service-account keys — not what this uses), `gcloud auth revoke`
  revokes **server-side**. Revoking or simply re-authenticating locally
  invalidates every synced copy on every Codespace at once — a real,
  working response if a Codespace is ever suspected compromised, not a
  theoretical one.
- The 600-permission chmod and curated file list (both above) are the
  concrete mitigations for the one part of Google's warning that still
  applies regardless of automated-vs-human framing — limiting what's
  readable, by what, on each Codespace.
- Not addressed by this design, worth knowing: anything with access to a
  running Codespace's filesystem *while it's running* (not just a
  compromised dependency, but you yourself debugging, a collaborator with
  Codespace access if that's ever enabled, etc.) can use the synced
  credentials for as long as that Codespace is up. No different in kind
  from the risk of being logged into gcloud on any machine you use, but
  worth remembering there are now several such machines instead of one.

### Sources

- [Authenticate for the gcloud CLI](https://docs.cloud.google.com/sdk/docs/authorizing)
  — the warning text, quoted and verified directly above
- [Best practices for mitigating compromised OAuth tokens for Google Cloud CLI](https://docs.cloud.google.com/architecture/bps-for-mitigating-gcloud-oauth-tokens)
- [Managing gcloud CLI configurations](https://docs.cloud.google.com/sdk/docs/configurations)
  — `CLOUDSDK_CONFIG`, `configurations/config_default`
- [Application Default Credentials overview](https://docs.cloud.google.com/docs/authentication/application-default-credentials)
  — confirms ADC is a distinct credential set from `gcloud auth login`
- [gcloud auth revoke](https://docs.cloud.google.com/sdk/gcloud/reference/auth/revoke)
  — server-side revocation behavior for user-account credentials
- `config_files/.workrc-codespaces` — the actual `cs-sync-gcloud`
  implementation, comments included
