# Clipboard on Wayland (labwc): herdr, xclip, and the split clipboard

Status: **fixed and verified live** (`wl-clipboard` installed; herdr copy
and `clipcopy` both confirmed working 2026-08-10 — see
[Verification](#verification-2026-08-10)). Written 2026-08-10, after the
work machine's move to Ubuntu Budgie's Wayland session (labwc) broke
copying out of herdr. Sibling doc to
[`herdr_codespaces.md`](herdr_codespaces.md)'s copy/paste notes — those
cover the *mirrored-pane* copy bugs (wrapped-row rendering, OSC 52 drops);
this covers plain local copying on the Wayland machine.

## Symptom

Copy inside herdr (mouse selection, copy-on-select) → paste outside herdr
pastes nothing, or stale content. herdr's own log
(`~/.config/herdr/herdr-server.log`) claims success on every attempt:
`INFO herdr::app::actions: copied selection to clipboard`.

## Diagnosis (all observed live, 2026-08-10)

Under Wayland there are two parallel clipboards — the Wayland one and the
X11/XWayland one — and after a herdr copy they disagreed:

- **X11 clipboard: had the copied text** (read via `xclip -selection
  clipboard -o`).
- **Wayland clipboard: EMPTY** (read via a GTK
  `Gtk.Clipboard.wait_for_text()` probe with `GDK_BACKEND=wayland`,
  using `/usr/bin/python3` — the asdf shim python has no `gi`, same
  lesson as the labwc-bridge autostart pin, commit `5f94130`).

Wayland-native apps paste from the Wayland clipboard, so every one of
them saw nothing — and sakura (the terminal herdr runs in) is itself
Wayland-native (`GDK_BACKEND=wayland,x11`), so pasting back into any
terminal failed too. XWayland apps kept working, which made the failure
look intermittent/app-specific rather than what it was.

Why each side behaved as it did:

- **herdr's Wayland clipboard write is a silent no-op without `wl-copy`.**
  Upstream [herdrdev/herdr#1905](https://github.com/herdrdev/herdr/issues/1905)
  (closed "not planned"): on Wayland, herdr shells out to `wl-copy` to
  set the clipboard, and when the binary is missing it still shows its
  "copied to clipboard" feedback while writing nothing —
  `wl-clipboard` is a de facto runtime dependency, not an optional
  nicety. This machine didn't have it installed. Related:
  [#2193](https://github.com/herdrdev/herdr/issues/2193) (no OSC 52
  fallback either, also "not planned").
- **The text that did land on the X11 side doesn't propagate.** herdr
  (the *server* process does the copying — its env had `WAYLAND_DISPLAY`
  set, so that's not the variable) also writes the X11 clipboard via a
  direct X connection. But it's a *windowless* X client, and labwc/wlroots
  only syncs X11 selections to the Wayland side in ways tied to focused
  XWayland surfaces — a selection grabbed by a windowless client while a
  Wayland window has focus never crosses over. This is the same reason
  plain `xclip` (also windowless) stopped reaching Wayland apps.

## Fix (applied 2026-08-10)

1. **`wl-clipboard` added to `build_ubuntu.sh`'s Install Tools list**
   (unconditional, both machines — inert where there's no Wayland
   session, and it's what makes herdr's own Wayland copy path work at
   all per #1905).
2. **New `config_files/.local/bin/clipcopy`** — tiny stdin-to-clipboard
   wrapper: `wl-copy` when `$WAYLAND_DISPLAY` is set and the binary
   exists, `xclip -selection clipboard` otherwise. wl-copy writes the
   Wayland clipboard and the compositor mirrors that into XWayland, so
   one write reaches both worlds — the reverse of the broken direction.
   On the X11 machine (Xubuntu box) the env check short-circuits first —
   even with wl-clipboard installed — and the fallback branch is
   literally the old `xclip` command, so behavior there is unchanged
   (verified with `env -u WAYLAND_DISPLAY`, albeit under XWayland's
   `DISPLAY`; display-less shells fail the same way bare `xclip` always
   did).
3. **Every `xclip` copy call site migrated to `clipcopy`**: `gca` in
   `.workrc`, the tmux copy-mode bindings in `.tmuxrc-linux`, and
   `cs-copy-url` in `.workrc-codespaces` (which otherwise would have
   kept "working" while Wayland apps saw nothing).
4. **`WAYLAND_DISPLAY` added to tmux's `update-environment`**
   (`.tmuxrc-linux`). tmux's default list refreshes `DISPLAY` on client
   attach but not `WAYLAND_DISPLAY` (still true in tmux 3.6), so a tmux
   server surviving a logout/login would hand `clipcopy` a stale or
   missing `WAYLAND_DISPLAY` on reattach — pointing `wl-copy` at a dead
   socket, or falling back to `xclip`'s broken windowless path. Same
   env-staleness failure mode as herdr's #2448 above, fixed at the tmux
   layer.

### Considered and rejected: an X11→Wayland bridge daemon

First plan (before finding #1905) was a login-time daemon mirroring X11
CLIPBOARD changes into the Wayland clipboard: `clipnotify` isn't packaged
on Ubuntu, so the sketch was a pinned-`/usr/bin/python3` GTK watcher on
the clipboard's `owner-change` signal (event-driven, no polling) piping
into `wl-copy`, with a last-synced-content guard against the infinite
echo loop (our own `wl-copy` → labwc mirrors to X11 → owner-change fires
→ would re-copy forever), autostarted like the Budgie panel workaround.
Dropped: with `wl-clipboard` installed, herdr writes the Wayland side
natively and the `xclip` call sites are migrated, so nothing that matters
copies X11-only anymore — the daemon would be a second moving part
guarding an empty path. Revisit only if some new windowless-X11-only
copier shows up (this paragraph is the design, ready to build).

### Upstream watch-items

- [#2448](https://github.com/herdrdev/herdr/issues/2448) (open): local
  Wayland clipboard unavailable in panes after reattaching to a
  persistent session — if copy breaks again *after a detach/reattach*,
  check `tr '\0' '\n' < /proc/$(pgrep -f 'herdr server')/environ | grep
  WAYLAND` before re-diagnosing from scratch; a stale/missing
  `WAYLAND_DISPLAY` in the server's env means `wl-copy` (run as its
  child) can't find the compositor.
- [#2621](https://github.com/herdrdev/herdr/issues/2621) (closed, not
  planned): `wl-copy` steals keyboard focus on GNOME — GNOME-specific
  (no `wlr-data-control` there); labwc has that protocol, so not
  applicable here.

## Security note: token exposure during this debugging (2026-08-10)

While diagnosing, the X11 clipboard was read in a Claude Code session to
see where copies were landing — and it held the full output of a freshly
minted `claude setup-token` (the Codespaces auth token from
[`codespaces_tool_auth.md`](codespaces_tool_auth.md)), which thereby
landed in the session transcript. Disposition: that token is treated as
burned — revoke via claude.ai → Settings → active sessions (the reliable
path; see the revocation caveats in `codespaces_tool_auth.md`), mint a
fresh one, and only then set the `CLAUDE_CODE_OAUTH_TOKEN` user secret
(which was still unset at the time, so nothing else needs rotating).
Lesson recorded for next time: don't route live secrets through the
clipboard while the clipboard itself is the thing being debugged — for
the token specifically, piping straight into `gh secret set
CLAUDE_CODE_OAUTH_TOKEN --user` from the same shell avoids the clipboard
entirely.

## Verification (2026-08-10)

- [x] X11 vs Wayland clipboard divergence reproduced and measured (339
  chars vs EMPTY, same copy).
- [x] herdr server env confirmed to have `WAYLAND_DISPLAY` (rules out
  #2448's failure mode for this incident).
- [x] `wl-clipboard` installed; herdr copy → paste works again (user
  confirmed, 2026-08-10).
- [x] `clipcopy` round-trips through the tmux server's own environment
  (`tmux run-shell 'printf test | clipcopy'` → `wl-paste` returns it) —
  exercises the same env a copy-mode `copy-pipe` binding gets.
- [x] `WAYLAND_DISPLAY` present in the live server's
  `update-environment` list after config reload (tmux 3.6).

## Sources

- `~/.config/herdr/herdr-server.log`, `xclip`, a GTK clipboard probe via
  `/usr/bin/python3`, `/proc/<pid>/environ` — all run live on the work
  machine, 2026-08-10
- [herdrdev/herdr#1905](https://github.com/herdrdev/herdr/issues/1905),
  [#2193](https://github.com/herdrdev/herdr/issues/2193),
  [#2448](https://github.com/herdrdev/herdr/issues/2448),
  [#2621](https://github.com/herdrdev/herdr/issues/2621) — fetched live
  2026-08-10
- `misc/codespaces_tool_auth.md` — the token whose exposure is recorded
  above, and its revocation caveats
