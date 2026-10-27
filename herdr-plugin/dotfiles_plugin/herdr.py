"""herdr's socket API: newline-delimited JSON over $HERDR_SOCKET_PATH.

The socket rather than the CLI because `workspace.move_block` has no CLI command.
"""

import json
import os
import socket


class HerdrError(Exception):
    pass


def request(method, params=None, socket_path=None):
    path = socket_path or os.environ.get("HERDR_SOCKET_PATH")
    if not path:
        raise HerdrError("HERDR_SOCKET_PATH is not set")
    with socket.socket(socket.AF_UNIX) as sock:
        sock.connect(path)
        sock.sendall((json.dumps({"id": "dotfiles", "method": method, "params": params or {}}) + "\n").encode())
        reply = json.loads(sock.makefile(encoding="utf-8").readline())
    if "error" in reply:
        raise HerdrError(f"{method}: {reply['error']}")
    return reply["result"]


def workspaces(**kwargs):
    return request("workspace.list", **kwargs)["workspaces"]


def rename(workspace_id, label, **kwargs):
    request("workspace.rename", {"workspace_id": workspace_id, "label": label}, **kwargs)


def move_block(workspace_ids, before_workspace_id=None, **kwargs):
    """Moves the spaces, in the order given, to just above before_workspace_id, or to the end when it's None."""
    request("workspace.move_block", {"workspace_ids": workspace_ids, "before_workspace_id": before_workspace_id}, **kwargs)
