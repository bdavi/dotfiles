"""The snooze action and hooks.

- `snooze.py` (prefix+l) opens the popup that asks how long, for the space the key was pressed in. A key
  can name an action but not a pane, so the action opens the pane.
- `snooze.py settle` (workspace.created) puts snoozed spaces back at the bottom.
- `snooze.py startup` (server start) starts the waker, so timed snoozes still wake after a restart.
"""

import json
import os
import subprocess
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

from dotfiles_plugin import herdr, snooze  # noqa: E402

try:
    if sys.argv[1:] == ["settle"]:
        snooze.settle()
    elif sys.argv[1:] == ["startup"]:
        snooze.start_waker()
    else:
        context = json.loads(os.environ.get("HERDR_PLUGIN_CONTEXT_JSON") or "{}")
        workspace_id = context.get("workspace_id") or os.environ.get("HERDR_WORKSPACE_ID")
        if not workspace_id:
            sys.exit("snooze: no space in the action's context")
        # No --workspace: herdr opens a popup over the active pane, which is where the key was pressed.
        result = subprocess.run([os.environ.get("HERDR_BIN_PATH") or "herdr", "plugin", "pane", "open",
                                 "--plugin", "dotfiles", "--entrypoint", "snooze",
                                 "--env", f"SNOOZE_SPACE={workspace_id}", "--focus"],
                                capture_output=True, text=True)
        if result.returncode != 0:
            sys.exit(f"snooze: couldn't open the popup: {(result.stderr or result.stdout).strip()}")
except (herdr.HerdrError, OSError) as err:
    sys.exit(f"snooze: {err}")
