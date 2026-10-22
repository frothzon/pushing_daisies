"""The read-out: what the checker found, screen by screen.

Two shapes, because the checker serves two readers:

* :func:`render` is the terminal form, one line per finding, grouped by screen -
  the thing a developer reads after a run;
* :func:`summary` is the one-liner a test asserts on ("3 screens, 0 findings"),
  and the line CI greps for.

A frame that did not finish (a truncated log) is reported as such rather than
counted clean: half a screen is not a screen that passes.
"""

from __future__ import annotations

from typing import Dict, List, Sequence

from . import dump, rules


def summary(frames: Sequence[dump.Frame], findings: Sequence[rules.Finding]) -> str:
    """``3 screens at 3 sizes, 0 findings`` - or the count that is not zero."""
    screens = len({frame.screen for frame in frames})
    sizes = len({frame.size for frame in frames})
    broken = [frame for frame in frames if not frame.complete
              or frame.declared != len(frame.items)]
    text = "%d screen%s at %d size%s, %d finding%s" % (
        screens, "" if screens == 1 else "s",
        sizes, "" if sizes == 1 else "s",
        len(findings), "" if len(findings) == 1 else "s",
    )
    if broken:
        text += "  (%d incomplete: %s)" % (
            len(broken), ", ".join(sorted({"%s %s" % (f.screen, f.size) for f in broken})))
    return text


def render(frames: Sequence[dump.Frame], findings: Sequence[rules.Finding],
           show_items: bool = False) -> List[str]:
    """One line per finding, grouped by frame; plus a per-frame header."""
    by_screen: Dict[str, List[rules.Finding]] = {}
    for finding in findings:
        by_screen.setdefault("%s %s" % (finding.screen, finding.size), []).append(finding)

    lines: List[str] = []
    for frame in frames:
        key = "%s %s" % (frame.screen, frame.size)
        count = len(by_screen.get(key, ()))
        note = ""
        if not frame.complete:
            note = "  INCOMPLETE (no end line - truncated log?)"
        elif frame.declared != len(frame.items):
            note = "  MISSING ITEMS (declared %d, read %d)" % (frame.declared, len(frame.items))
        lines.append("%-9s %-9s %3d items  %2d finding%s%s" % (
            frame.screen, frame.size, len(frame.items), count,
            "" if count == 1 else "s", note))
        if show_items:
            for item in frame.items:
                lines.append("    .        %-70s %s" % (item.label(), item.box_text()))
        for finding in by_screen.get(key, ()):
            lines.append("    " + finding.line())
        lines.append("")
    return lines


__all__ = ["render", "summary"]
