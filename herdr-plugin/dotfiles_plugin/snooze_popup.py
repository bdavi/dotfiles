"""The snooze popup's contents, as plain text, with no terminal, so they're testable as text."""

import time

from . import snooze

WAKE = "wake"


def choices(label, wake_at):
    """[(text, value)]: value is seconds, None for until woken, or WAKE. A snoozed space offers Wake now first
    and can be snoozed again for a different time."""
    items = [(text, seconds) for text, seconds in snooze.DURATIONS]
    if snooze.is_snoozed(label):
        items.insert(0, ("Wake now", WAKE))
    return items


def heading(label, wake_at, now=None):
    name = label[len(snooze.PREFIX):] if snooze.is_snoozed(label) else label
    if not snooze.is_snoozed(label):
        return [f"Snooze {name}"]
    if wake_at is None:
        return [f"{name} is snoozed", "until you wake it"]
    return [f"{name} is snoozed", f"until {_when(wake_at, now)}"]


def frame(label, wake_at, selected, now=None):
    """The popup's lines: the heading, a blank line, then one line per choice, numbered for the number keys.
    Returns (lines, first_choice_row) so a click can be mapped back to a choice."""
    lines = heading(label, wake_at, now) + [""]
    first = len(lines)
    for i, (text, _) in enumerate(choices(label, wake_at)):
        lines.append(f"{'>' if i == selected else ' '} {i + 1}  {text}")
    lines += ["", "enter choose · esc cancel"]
    return lines, first


def _when(at, now=None):
    now = now or time.time()
    local, today = time.localtime(at), time.localtime(now)
    if local.tm_yday == today.tm_yday and local.tm_year == today.tm_year:
        return time.strftime("%H:%M", local)
    if at - now < 6 * 86400:
        return time.strftime("%a %H:%M", local)
    return time.strftime("%a %d %b %H:%M", local)
