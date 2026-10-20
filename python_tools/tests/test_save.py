"""`gm save inspect` - reading a real garden_meta.dat (LL-050).

The v1 merge returned every nested map EMPTY and stamped a `version` key into
it.  That stamp is the only thing the file retained, so it is the detector's
signal: no stray stamp means the file was written by a merge that kept what it
read.
"""
from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from gm import save


def healthy() -> dict:
    return {
        "version": 2, "seeds": 48, "clovers": 205, "shards": 0,
        "towers": {"Burning Ivy": True},
        "loadout": ["Daisy Pusher"],
        "stages": {"1:1": 0},
        "clears": {"1:1": 1},
        "badges": {"1:1:0": True},
        "candy": {}, "clover_nodes": {"off_1": 2},
        "blood_nodes": {}, "candy_levels": {},
        "mastery": 0, "candy_duration": 0, "shard_pity": 0,
    }


def poisoned() -> dict:
    """What the v1 merge actually wrote - the file on the developer's disk."""
    doc = healthy()
    for key in save.MAP_FIELDS:
        doc[key] = {"version": 1.0}
    doc["stages"]["1:1"] = 0          # added by this run, after the wipe
    return doc


class InspectTests(unittest.TestCase):
    def test_a_healthy_save_has_no_stray_stamps(self):
        found = save.inspect(healthy())
        self.assertEqual([], found["stray_version"])
        self.assertEqual(["Burning Ivy"], found["maps"]["towers"])
        self.assertEqual(["1:1"], found["maps"]["stages"])

    def test_the_v1_stamp_is_detected_in_every_map(self):
        found = save.inspect(poisoned())
        self.assertEqual(sorted(save.MAP_FIELDS), sorted(found["stray_version"]))

    def test_a_map_that_is_not_a_map_is_reported_not_raised(self):
        doc = healthy()
        doc["towers"] = "gone"
        found = save.inspect(doc)
        self.assertIsNone(found["maps"]["towers"])

    def test_the_stamp_is_not_counted_as_content(self):
        found = save.inspect(poisoned())
        self.assertEqual([], found["maps"]["towers"])

    def test_render_names_the_emptied_maps(self):
        path = Path("garden_meta.dat")
        text = save.render(path, save.inspect(poisoned()))
        self.assertIn("EMPTY", text)
        self.assertIn("STRAY VERSION STAMPS", text)
        self.assertIn("LL-050", text)

    def test_cmd_save_exits_1_on_a_poisoned_file_and_0_on_a_healthy_one(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = Path(tmp) / "garden_meta.dat"
            p.write_text(json.dumps(poisoned()), encoding="utf-8")
            self.assertEqual(1, save.cmd_save(type("A", (), {"file": str(p)})()))
            p.write_text(json.dumps(healthy()), encoding="utf-8")
            self.assertEqual(0, save.cmd_save(type("A", (), {"file": str(p)})()))

    def test_a_missing_file_is_a_message_not_a_traceback(self):
        self.assertEqual(1, save.cmd_save(type("A", (), {"file": "/nope/none.dat"})()))


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
