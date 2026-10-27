# Dotfiles herdr plugin

This repo's own herdr plugin (id `dotfiles`): general-purpose additions that aren't worth a plugin each. Work-only plugins live in the private overlay repo instead.

## Snooze

`prefix+l` (Ctrl+Space, then L) opens a popup asking how long to snooze the focused space: 1 hour, 3 hours, 1 day, 2 days, 1 week, or until you wake it. On a snoozed space it says until when, and offers **Wake now** first, or a different time. Pick with the number, `j`/`k` and enter, or a click; `q` or escape cancels. `prefix+l` was herdr's focus-right, which ctrl+l (vim-herdr-navigation) already covers.

- **Snooze** puts the sleep glyph (nf-md-sleep, U+F04B2) in front of the space's name and moves it to the bottom of the sidebar. config.toml has a style rule that dims the name when it contains the glyph.
- **Wake**, by hand or when the time comes, removes the glyph and moves the space to just above the snoozed ones.
- **A new space** goes to the end of the list, below the snoozed ones, so the `workspace.created` hook moves the snoozed ones back to the bottom.

The glyph in the name is what makes a space snoozed. herdr saves names and order in its session, so a snooze survives a server restart, and deleting the glyph by hand (`prefix+shift+w`) wakes the space too, though it stays where it is.

**Timed wakes:** each space's wake time is in `~/.local/state/herdr/plugins/dotfiles/snooze-<socket hash>.json`, one file per herdr session. `bin/waker.py` checks it every 30 seconds and wakes what's due, so a wake can be up to 30 seconds late. It runs only while a timed snooze is pending: snoozing starts it, it exits when nothing is left, and the `[[startup]]` hook starts it again after a server restart. A lock keeps it to one per session. A wake time that passed while herdr was down happens at the first check after startup.

Moving uses `workspace.move_block` on herdr's socket, because the CLI has no command for it.

## Install

`install_herdr_dotfiles_plugin` in `scripts/dev_box/lib/herdr.sh` runs on every dev box build. By hand:

```bash
herdr plugin link ~/code/dotfiles/herdr-plugin --enabled
```

## Tests

```bash
cd ~/code/dotfiles/herdr-plugin && /usr/bin/python3 -m unittest discover -s tests
```

They run against a fake herdr socket and a temporary state directory, so they never touch the live session. The waker loop and the curses side of the popup aren't covered; the popup's text is.
