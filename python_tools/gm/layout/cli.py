"""``gm layout`` - the command line half of the layout checker.

``metrics`` is the one action that needs no run: it prints what the fonts measure
and, with ``--log``, checks those numbers against the ``FONT`` lines the game
logs at boot.  That comparison is the *only* proof this model is right, so it is
a first-class action rather than a comment (a metric nobody checks is a metric
that is wrong).

``check`` reads the ``[GEOM]`` dumps out of one or more logs and reports every
overlap, spill and off-canvas rectangle.  Exit code 1 when there is one, so a
shell or CI can gate on it.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path
from typing import List, Optional

from . import dump, metrics, report, rules

FONT_LINE = re.compile(
    r"p(\d+)\s+i=(-?\d+)\s+W=(-?\d+)\s+space=(-?\d+)\s+line=(-?\d+)"
)


def cmd_layout(args) -> int:
    """Dispatch ``gm layout <action>``."""
    action = getattr(args, "action", None) or "metrics"
    if action == "metrics":
        return _metrics(args)
    if action == "check":
        return _check(args)
    raise SystemExit("unknown layout action %r" % (action,))


def _check(args) -> int:
    paths = [Path(path) for path in (getattr(args, "paths", None) or [])]
    if not paths:
        print("layout check: pass at least one log file, e.g. "
              "gm layout check run.log", file=sys.stderr)
        return 2

    try:
        frames = dump.load(paths)
    except dump.DumpError as exc:
        print("layout: %s" % exc, file=sys.stderr)
        return 1

    findings = rules.check(frames, tol=getattr(args, "tol", rules.TOLERANCE),
                           min_area=getattr(args, "min_area", 0.0))

    for line in report.render(frames, findings, show_items=getattr(args, "items", False)):
        print(line)

    okay = not findings
    print("%s  %s" % ("ok  " if okay else "FAIL", report.summary(frames, findings)))
    if not okay:
        print("Each line above is a rectangle the player can see in the wrong place. "
              "Fix the layout, not the tolerance.")
    return 0 if okay else 1


def _metrics(args) -> int:
    root = getattr(args, "root", None)
    if getattr(args, "paths", None):
        print("layout metrics: `metrics` takes --log, not a path list", file=sys.stderr)
        return 2
    try:
        sheet = metrics.load(root)
    except metrics.MetricsError as exc:
        print(f"layout: {exc}", file=sys.stderr)
        return 1

    print(f"project {sheet.root}")
    for line in sheet.table():
        print(line)
    print()
    for line in sheet.boot_lines():
        print(line)

    log_path = getattr(args, "log", None)
    if not log_path:
        print()
        print("compare with the game: run with global.devMode = true and pass the log "
              "here (gm layout metrics --log <log>) - the i/W/space/line numbers must "
              "match, or the model is wrong.")
        return 0

    path = Path(log_path)
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        print(f"layout: cannot read {path}: {exc}", file=sys.stderr)
        return 1

    found = FONT_LINE.findall(text)
    if not found:
        print(f"layout: no `p16 i=.. W=.. space=.. line=..` line in {path}.", file=sys.stderr)
        print("        Is the log from a run with global.devMode = true?", file=sys.stderr)
        return 1

    bad = 0
    space_bad = 0
    for size_text, i_text, w_text, space_text, line_text in found:
        size = int(size_text)
        font = sheet.fonts.get(size)
        if font is None:
            print("layout: the log has p%s, which the game does not load" % size)
            bad += 1
            continue
        mine = {
            "i": font.width("i"),
            "W": font.width("W"),
            "space": font.width("a a") - 2 * font.width("a"),
            "line": font.height_of(1),
        }
        theirs = {
            "i": int(i_text),
            "W": int(w_text),
            "space": int(space_text),
            "line": int(line_text),
        }
        for key in ("i", "W", "space", "line"):
            if mine[key] == theirs[key]:
                print("ok    p%d %s=%d" % (size, key, mine[key]))
            else:
                bad += 1
                if key == "space":
                    space_bad += 1
                print("MISMATCH p%d %s: mine=%d game=%d"
                      % (size, key, mine[key], theirs[key]))

    if bad:
        print("\n%d mismatch(es): the model does not describe the game's font." % bad)
        if space_bad and space_bad == bad:
            print("`space` is the only difference, so it is the trailing separator "
                  "rule: flip TRAILING_SEP_EXCLUDED in gm/layout/metrics.py "
                  "(it is %s) and re-run." % metrics.TRAILING_SEP_EXCLUDED)
        return 1

    print("\nok    the model matches the game's font exactly")
    return 0
