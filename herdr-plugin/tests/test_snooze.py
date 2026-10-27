"""Snooze against a stand-in herdr socket that keeps a list of spaces and applies rename and move_block to it."""

import json
import os
import socket
import sys
import tempfile
import threading
import time
import unittest
from unittest import mock

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))

from dotfiles_plugin import herdr, snooze, snooze_popup  # noqa: E402

Z = snooze.PREFIX


class FakeHerdr:
    def __init__(self, labels):
        self.spaces = [{"workspace_id": f"w{i}", "label": label} for i, label in enumerate(labels)]
        self.dir = tempfile.TemporaryDirectory()
        self.path = os.path.join(self.dir.name, "herdr.sock")
        self.server = socket.socket(socket.AF_UNIX)
        self.server.bind(self.path)
        self.server.listen()
        threading.Thread(target=self.serve, daemon=True).start()

    def serve(self):
        while True:
            try:
                conn, _ = self.server.accept()
            except OSError:
                return
            with conn:
                req = json.loads(conn.makefile(encoding="utf-8").readline())
                conn.sendall((json.dumps(self.handle(req["method"], req["params"])) + "\n").encode())

    def handle(self, method, params):
        if method == "workspace.rename":
            next(s for s in self.spaces if s["workspace_id"] == params["workspace_id"])["label"] = params["label"]
        elif method == "workspace.move_block":
            moving = [next(s for s in self.spaces if s["workspace_id"] == i) for i in params["workspace_ids"]]
            rest = [s for s in self.spaces if s not in moving]
            before = params["before_workspace_id"]
            at = len(rest) if before is None else next(i for i, s in enumerate(rest) if s["workspace_id"] == before)
            self.spaces = rest[:at] + moving + rest[at:]
        elif method != "workspace.list":
            return {"error": {"code": "unknown_method"}}
        return {"result": {"workspaces": [dict(s) for s in self.spaces]}}

    def labels(self):
        return [s["label"] for s in self.spaces]

    def close(self):
        self.server.close()
        self.dir.cleanup()


class SnoozeTest(unittest.TestCase):
    def setUp(self):
        state = tempfile.TemporaryDirectory()
        self.addCleanup(state.cleanup)
        patcher = mock.patch.dict(os.environ, {"HERDR_PLUGIN_STATE_DIR": state.name})
        patcher.start()
        self.addCleanup(patcher.stop)

    def herdr(self, labels):
        fake = FakeHerdr(labels)
        self.addCleanup(fake.close)
        return fake

    def test_snooze_prefixes_the_label_moves_to_the_bottom_and_records_the_wake_time(self):
        fake = self.herdr(["a", "b", Z + "c"])
        snooze.snooze("w0", 3600, now=1000, socket_path=fake.path)
        self.assertEqual(fake.labels(), ["b", Z + "c", Z + "a"])
        self.assertEqual(snooze.wake_at("w0", socket_path=fake.path), 4600)

    def test_snooze_until_woken_records_no_wake_time(self):
        fake = self.herdr(["a"])
        snooze.snooze("w0", None, socket_path=fake.path)
        self.assertEqual(fake.labels(), [Z + "a"])
        self.assertIsNone(snooze.wake_at("w0", socket_path=fake.path))

    def test_snoozing_again_changes_only_the_wake_time(self):
        fake = self.herdr(["a", Z + "b", Z + "c"])
        snooze.snooze("w1", 86400, now=1000, socket_path=fake.path)
        self.assertEqual(fake.labels(), ["a", Z + "b", Z + "c"])
        self.assertEqual(snooze.wake_at("w1", socket_path=fake.path), 87400)

    def test_wake_strips_the_prefix_lands_just_above_the_snoozed_and_forgets_the_time(self):
        fake = self.herdr(["a", Z + "b", "c"])
        snooze.snooze("w2", 3600, socket_path=fake.path)
        snooze.wake("w2", socket_path=fake.path)
        self.assertEqual(fake.labels(), ["a", "c", Z + "b"])
        self.assertIsNone(snooze.wake_at("w2", socket_path=fake.path))

    def test_wake_due_wakes_only_spaces_whose_time_has_come(self):
        fake = self.herdr(["a", "b", "c"])
        snooze.snooze("w0", 60, now=1000, socket_path=fake.path)
        snooze.snooze("w1", 3600, now=1000, socket_path=fake.path)
        pending = snooze.wake_due(now=1100, socket_path=fake.path)
        self.assertEqual(fake.labels(), ["c", "a", Z + "b"])
        self.assertEqual(pending, {"w1": 4600})

    def test_wake_due_forgets_spaces_closed_or_woken_by_hand(self):
        fake = self.herdr(["a", "b"])
        snooze.snooze("w0", 60, now=1000, socket_path=fake.path)
        snooze.snooze("w1", 60, now=1000, socket_path=fake.path)
        fake.spaces = [s for s in fake.spaces if s["workspace_id"] != "w0"]
        fake.spaces[0]["label"] = "renamed"
        self.assertEqual(snooze.wake_due(now=1001, socket_path=fake.path), {})
        self.assertEqual(fake.labels(), ["renamed"])

    def test_each_session_has_its_own_wake_times(self):
        one, two = self.herdr(["a"]), self.herdr(["a"])
        snooze.snooze("w0", 60, now=1000, socket_path=one.path)
        self.assertIsNone(snooze.wake_at("w0", socket_path=two.path))

    def test_settle_moves_snoozed_below_a_new_space_keeping_their_order(self):
        fake = self.herdr(["a", Z + "b", Z + "c", "new"])
        snooze.settle(socket_path=fake.path)
        self.assertEqual(fake.labels(), ["a", "new", Z + "b", Z + "c"])

    def test_unknown_space_is_an_error(self):
        fake = self.herdr(["a"])
        with self.assertRaises(herdr.HerdrError):
            snooze.snooze("nope", 60, socket_path=fake.path)


class PopupTest(unittest.TestCase):
    def test_an_awake_space_is_offered_the_durations(self):
        lines, first = snooze_popup.frame("dotfiles", None, 0)
        self.assertEqual(lines[0], "Snooze dotfiles")
        self.assertEqual(lines[first:first + 2], ["> 1  1 hour", "  2  3 hours"])
        self.assertIn("  6  Until I wake it", lines)

    def test_a_snoozed_space_is_offered_wake_now_first_and_says_until_when(self):
        now = time.mktime((2026, 10, 27, 9, 0, 0, 0, 0, -1))
        lines, first = snooze_popup.frame(Z + "dotfiles", now + 3 * 3600, 0, now=now)
        self.assertEqual(lines[:2], ["dotfiles is snoozed", "until 12:00"])
        self.assertEqual(lines[first], "> 1  Wake now")
        self.assertEqual(snooze_popup.choices(Z + "dotfiles", None)[0][1], snooze_popup.WAKE)


if __name__ == "__main__":
    unittest.main()
