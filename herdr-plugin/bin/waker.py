"""Wakes timed snoozes when their time comes, for the herdr session whose socket is $HERDR_SOCKET_PATH.

One per session, held by a lock beside the session's state file. It checks every 30 seconds and exits once no
timed snooze is left, so nothing runs while nothing is snoozed; snoozing starts it again, and so does herdr's
startup hook, which picks up where it left off after a restart. It also exits when the server has been
unreachable for five minutes.
"""

import fcntl
import os
import sys
import time

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

from dotfiles_plugin import herdr, snooze  # noqa: E402

INTERVAL = 30
GIVE_UP_AFTER = 10  # unreachable checks in a row


def try_lock(f):
    try:
        fcntl.flock(f, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return True
    except BlockingIOError:
        return False


def main():
    lock = open(snooze.state_path() + ".waker", "w")
    if not try_lock(lock):
        return
    failures = 0
    while True:
        try:
            pending = snooze.wake_due()
            failures = 0
        except (herdr.HerdrError, OSError):
            failures += 1
            if failures >= GIVE_UP_AFTER:
                return
            pending = True
        if not pending:
            # A snooze set between that check and the unlock would find the lock held and leave it to this
            # waker, so look once more after letting go, and carry on if there's one.
            fcntl.flock(lock, fcntl.LOCK_UN)
            with snooze.wake_times() as times:
                if not times or not try_lock(lock):
                    return
            continue
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
