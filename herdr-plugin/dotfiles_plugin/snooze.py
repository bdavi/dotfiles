"""Snoozing a space: its label gets a sleep glyph, it moves to the bottom of the sidebar, and a timed snooze
wakes on its own.

The glyph in the label is what makes a space snoozed. herdr saves labels and order in its session, so a snooze
survives a server restart, and renaming the glyph away by hand wakes the space just as well. A timed snooze
also has its wake time in a state file, one per herdr session (sessions have their own sockets and their own
space ids); bin/waker.py wakes each space when its time comes. The dimming is config.toml's: a style rule on
the workspace token, matching the glyph.
"""

import contextlib
import fcntl
import hashlib
import json
import os
import subprocess
import sys
import time

from . import herdr

# nf-md-sleep (U+F04B2), so the terminal showing herdr needs a Nerd Font, as the $agentctl row already does.
PREFIX = "\U000f04b2 "

# The popup's choices: (label, seconds), None for a snooze that lasts until it's woken by hand.
DURATIONS = [
    ("1 hour", 3600),
    ("3 hours", 3 * 3600),
    ("1 day", 86400),
    ("2 days", 2 * 86400),
    ("1 week", 7 * 86400),
    ("Until I wake it", None),
]

WAKER = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "bin", "waker.py")


def is_snoozed(label):
    return label.startswith(PREFIX)


def state_path(socket_path=None):
    """The session's wake times. Named after the socket, so each herdr session gets its own file."""
    socket_path = socket_path or os.environ.get("HERDR_SOCKET_PATH") or ""
    root = os.environ.get("HERDR_PLUGIN_STATE_DIR") or os.path.expanduser("~/.local/state/herdr/plugins/dotfiles")
    os.makedirs(root, exist_ok=True)
    return os.path.join(root, f"snooze-{hashlib.sha1(socket_path.encode()).hexdigest()[:12]}.json")


@contextlib.contextmanager
def wake_times(socket_path=None):
    """{workspace_id: wake_at} under a lock, written back when the block ends. The waker and the popup both
    change it, so a read-modify-write without the lock could drop the other's change."""
    path = state_path(socket_path)
    with open(path + ".lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            with open(path) as f:
                times = json.load(f)
        except (FileNotFoundError, ValueError):
            times = {}
        yield times
        tmp = path + ".tmp"
        with open(tmp, "w") as f:
            json.dump(times, f)
        os.replace(tmp, path)


def wake_at(workspace_id, socket_path=None):
    with wake_times(socket_path) as times:
        return times.get(workspace_id)


def snooze(workspace_id, seconds, now=None, socket_path=None):
    """Snoozes the space for seconds (None: until it's woken by hand). Snoozing a snoozed space only changes
    when it wakes; it's already at the bottom."""
    spaces = herdr.workspaces(socket_path=socket_path)
    space = _find(spaces, workspace_id)
    with wake_times(socket_path) as times:
        if seconds is None:
            times.pop(workspace_id, None)
        else:
            times[workspace_id] = (now or time.time()) + seconds
    if not is_snoozed(space["label"]):
        herdr.rename(workspace_id, PREFIX + space["label"], socket_path=socket_path)
        herdr.move_block([workspace_id], None, socket_path=socket_path)


def wake(workspace_id, socket_path=None):
    spaces = herdr.workspaces(socket_path=socket_path)
    _wake(spaces, _find(spaces, workspace_id), socket_path)
    with wake_times(socket_path) as times:
        times.pop(workspace_id, None)


def wake_due(now=None, socket_path=None):
    """Wakes every space whose time has come and forgets any that were closed or woken by hand. Returns the
    wake times still pending."""
    now = now or time.time()
    spaces = herdr.workspaces(socket_path=socket_path)
    by_id = {s["workspace_id"]: s for s in spaces}
    with wake_times(socket_path) as times:
        for workspace_id, when in list(times.items()):
            space = by_id.get(workspace_id)
            if space is None or not is_snoozed(space["label"]):
                del times[workspace_id]
            elif when <= now:
                _wake(spaces, space, socket_path)
                del times[workspace_id]
        return dict(times)


def settle(socket_path=None):
    """Moves every snoozed space back to the bottom, keeping their order among themselves."""
    snoozed = [s["workspace_id"] for s in herdr.workspaces(socket_path=socket_path) if is_snoozed(s["label"])]
    if snoozed:
        herdr.move_block(snoozed, None, socket_path=socket_path)


def start_waker():
    """Starts bin/waker.py in the background. Harmless when one is already running: it holds a lock, and a
    second one exits at once."""
    subprocess.Popen([sys.executable, WAKER], stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                     stderr=subprocess.DEVNULL, start_new_session=True)


def _find(spaces, workspace_id):
    space = next((s for s in spaces if s["workspace_id"] == workspace_id), None)
    if space is None:
        raise herdr.HerdrError(f"no space {workspace_id}")
    return space


def _wake(spaces, space, socket_path):
    """Strips the glyph and moves the space to the last of the awake ones, just above the snoozed block: back
    in view without jumping the queue."""
    workspace_id = space["workspace_id"]
    if not is_snoozed(space["label"]):
        return
    herdr.rename(workspace_id, space["label"][len(PREFIX):], socket_path=socket_path)
    first_snoozed = next((s["workspace_id"] for s in spaces
                          if s["workspace_id"] != workspace_id and is_snoozed(s["label"])), None)
    herdr.move_block([workspace_id], first_snoozed, socket_path=socket_path)
