"""The snooze popup's program: asks how long to snooze $SNOOZE_SPACE, does it, and exits, which closes the popup.

Keys: a choice's number, or j/k (↑/↓) and enter; q or escape cancels. A click on a choice picks it.
"""

import curses
import locale
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

from dotfiles_plugin import herdr, snooze, snooze_popup  # noqa: E402


def ask(stdscr, label, wake_at):
    """The chosen value from snooze_popup.choices, or False when cancelled."""
    curses.curs_set(0)
    curses.use_default_colors()
    # No click interval, so a press acts at once rather than after curses waits to see if it's a double click.
    curses.mousemask(curses.ALL_MOUSE_EVENTS)
    curses.mouseinterval(0)
    items = snooze_popup.choices(label, wake_at)
    selected = 0
    while True:
        lines, first = snooze_popup.frame(label, wake_at, selected)
        stdscr.erase()
        height, width = stdscr.getmaxyx()
        for y, line in enumerate(lines[:height]):
            attr = curses.A_REVERSE if y == first + selected else (curses.A_BOLD if y == 0 else 0)
            stdscr.addnstr(y, 1, line, max(width - 2, 0), attr)
        stdscr.refresh()

        key = stdscr.getch()
        if key in (ord("q"), 27):
            return False
        if ord("1") <= key < ord("1") + len(items):
            return items[key - ord("1")][1]
        if key in (ord("j"), curses.KEY_DOWN):
            selected = (selected + 1) % len(items)
        elif key in (ord("k"), curses.KEY_UP):
            selected = (selected - 1) % len(items)
        elif key in (curses.KEY_ENTER, 10, 13):
            return items[selected][1]
        elif key == curses.KEY_MOUSE:
            row = _clicked_row()
            if row is not None and 0 <= row - first < len(items):
                return items[row - first][1]


def _clicked_row():
    """The row of the first press in curses' mouse queue. Drains the whole queue: a terminal sends a click's
    press and release together and curses queues the second, so reading one per KEY_MOUSE answers each click
    one event late."""
    row = None
    while True:
        try:
            _, _, y, _, bstate = curses.getmouse()
        except curses.error:
            return row
        if row is None and bstate & (curses.BUTTON1_PRESSED | curses.BUTTON1_CLICKED):
            row = y


def main():
    locale.setlocale(locale.LC_ALL, "")
    os.environ.setdefault("ESCDELAY", "25")
    workspace_id = os.environ.get("SNOOZE_SPACE")
    try:
        space = next((s for s in herdr.workspaces() if s["workspace_id"] == workspace_id), None)
        if space is None:
            sys.exit(f"snooze: no space {workspace_id}")
        choice = curses.wrapper(ask, space["label"], snooze.wake_at(workspace_id))
        if choice is False:
            return
        if choice == snooze_popup.WAKE:
            snooze.wake(workspace_id)
        else:
            snooze.snooze(workspace_id, choice)
            if choice is not None:
                snooze.start_waker()
    except (herdr.HerdrError, OSError) as err:
        sys.exit(f"snooze: {err}")


if __name__ == "__main__":
    main()
