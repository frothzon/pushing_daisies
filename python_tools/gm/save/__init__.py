"""Inspect a real `garden_meta.dat` without running the game.

Why this exists (LL-050)
------------------------
The save merge in GML discarded every nested map, and the only trace it left
was a stray `"version"` key inside each one - because the merge stamped the
version into the empty map it had just returned.  Nothing in the game could
see that: the load log printed the three fields the merge cannot lose.

This command is a DETECTOR, not a reimplementation of the merge.  It reads the
file the game actually wrote and answers two questions:

  * how much is in each map (so "0 towers" is visible at a glance), and
  * does any nested map carry a `version` key (which only the v1 merge ever
    wrote, and which the fixed merge strips).

Exit code 1 when a stray stamp is found, so it can be used as a gate.
"""
from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

SAVE_NAME = "garden_meta.dat"

#: Maps whose contents are progress.  A `version` key inside one of these is
#: the fingerprint of the v1 merge bug; they are listed explicitly so the
#: report can say WHICH ones were emptied rather than just "something is off".
MAP_FIELDS = ("towers", "stages", "clears", "badges", "candy",
              "clover_nodes", "blood_nodes", "candy_levels")
SCALAR_FIELDS = ("seeds", "clovers", "shards", "mastery", "shard_pity",
                 "candy_duration")


def default_candidates() -> List[Path]:
    """Where GameMaker puts the save area, most likely first."""
    name = Path.cwd().name
    home = Path.home()
    out = [home / ".config" / name / SAVE_NAME,          # Linux / the IDE here
           home / ".local" / "share" / name / SAVE_NAME]
    for var in ("LOCALAPPDATA", "APPDATA"):              # Windows
        base = os.environ.get(var)
        if base:
            out.append(Path(base) / name / SAVE_NAME)
    return out


def find_save(explicit: Optional[str] = None) -> Optional[Path]:
    if explicit:
        p = Path(explicit).expanduser()
        return p if p.exists() else None
    for p in default_candidates():
        if p.exists():
            return p
    return None


def inspect(doc: Dict[str, Any]) -> Dict[str, Any]:
    """What the file holds.  Pure, so a test can pass a dict straight in."""
    maps: Dict[str, Any] = {}
    strays: List[str] = []
    for key in MAP_FIELDS:
        value = doc.get(key)
        if isinstance(value, dict):
            strays += [key] if "version" in value else []
            keys = [k for k in value.keys() if k != "version"]
            maps[key] = sorted(keys)
        else:
            maps[key] = None          # missing, or not a map at all
    return {
        "version": doc.get("version"),
        "scalars": {k: doc.get(k) for k in SCALAR_FIELDS},
        "maps": maps,
        "stray_version": strays,
    }


def _num(value: Any) -> Any:
    """48.0 -> 48, so the report reads like the design docs."""
    if isinstance(value, float) and value.is_integer():
        return int(value)
    return value


def render(path: Path, found: Dict[str, Any]) -> str:
    try:
        size = path.stat().st_size
    except OSError:            # a unit test may hand in a name, not a file
        size = 0
    lines = ["file      %s  (%d bytes)" % (path, size),
             "version   %s" % _num(found["version"])]
    for k, v in found["scalars"].items():
        lines.append("%-13s %s" % (k, _num(v)))
    for k, keys in found["maps"].items():
        if keys is None:
            lines.append("%-9s MISSING (not a map)" % k)
        elif not keys:
            lines.append("%-9s 0    <-- EMPTY" % k)
        else:
            shown = ", ".join(keys[:6]) + (" ..." if len(keys) > 6 else "")
            lines.append("%-9s %d    [%s]" % (k, len(keys), shown))
    if found["stray_version"]:
        lines.append("")
        lines.append("STRAY VERSION STAMPS  " + ", ".join(found["stray_version"]))
        lines.append("  Written by the v1 merge (scr_meta_merge), which returned")
        lines.append("  each nested map EMPTY and stamped the version into it.")
        lines.append("  Those maps lost their contents on load (LL-050).")
    return "\n".join(lines)


def cmd_save(args: Any) -> int:
    path = find_save(getattr(args, "file", None))
    if path is None:
        tried = "\n".join("  " + str(p) for p in default_candidates())
        print("no %s found.  Looked in:\n%s" % (SAVE_NAME, tried))
        print("pass a path:  gm save inspect /path/to/%s" % SAVE_NAME)
        return 1
    try:
        doc = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as err:
        print("%s: %s" % (path, err))
        return 1
    if not isinstance(doc, dict):
        print("%s: not a JSON object" % path)
        return 1

    found = inspect(doc)
    print(render(path, found))
    return 1 if found["stray_version"] else 0
