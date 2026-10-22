"""The game's layout dump -> rectangles.

``scr_ui_check`` prints one block per screen per canvas size:

    UI    [GEOM] begin worldmap 960x540 items 14
    UI    [GEOM]   box title 392,20,567,52
    UI    [GEOM]   text cur_0 80,24,141,40 "48"
    UI    [GEOM] end worldmap 14 items

This module reads that back.  It is deliberately tolerant about everything that
is not a rectangle - the log also carries MENU/BTN/UI lines, and the console
interleaves them - and honest about the two things it cannot fix:

* a block that ends without ``end`` (a truncated log) is still returned, with
  ``complete = False``, because a half-read screen is worth reporting on;
* the item count the game declared is kept, so a mismatch is visible instead of
  silently measuring a partial layout.

Nothing here knows what an overlap is - that is :mod:`gm.layout.rules`.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

Rect = Tuple[float, float, float, float]

#: One item line.  Kinds are open-ended ("box", "panel", "text", "image",
#: "button", ...) because a screen may register something new; the rules decide
#: which kinds they care about.
_ITEM = re.compile(
    r"\[GEOM\]\s+(?!begin\b|end\b)(\w+)\s+(\S+)\s+"
    r"(-?[\d.]+),(-?[\d.]+),(-?[\d.]+),(-?[\d.]+)(?:\s+(.*?))?\s*$"
)
_BEGIN = re.compile(r"\[GEOM\]\s+begin\s+(\S+)\s+(\d+)x(\d+)\s+items\s+(\d+)")
_END = re.compile(r"\[GEOM\]\s+end\s+(\S+)\s+(\d+)\s+items")


class DumpError(RuntimeError):
    """A dump could not be read.  Always says which file and why."""


@dataclass(frozen=True)
class Item:
    """One rectangle the game drew, in GUI units."""

    kind: str
    name: str
    rect: Rect
    text: str = ""

    @property
    def width(self) -> float:
        return self.rect[2] - self.rect[0]

    @property
    def height(self) -> float:
        return self.rect[3] - self.rect[1]

    def label(self) -> str:
        """How the report names it: ``text title "World Map"``."""
        if self.text:
            return '%s %s "%s"' % (self.kind, self.name, self.text)
        return "%s %s" % (self.kind, self.name)

    def box_text(self) -> str:
        return "%gx%g @ %g,%g" % (self.width, self.height, self.rect[0], self.rect[1])


@dataclass
class Frame:
    """One screen at one canvas size."""

    screen: str
    width: float
    height: float
    declared: int
    items: List[Item] = field(default_factory=list)
    complete: bool = False

    @property
    def size(self) -> str:
        return "%gx%g" % (self.width, self.height)

    def named(self, name: str) -> List[Item]:
        return [item for item in self.items if item.name == name]

    def kinds(self, *kinds: str) -> List[Item]:
        return [item for item in self.items if item.kind in kinds]


def parse_text(text: str, origin: str = "<text>") -> List[Frame]:
    """Every frame in a log, in the order the game printed them."""
    frames: List[Frame] = []
    current: Optional[Frame] = None

    for number, line in enumerate(text.splitlines(), start=1):
        begin = _BEGIN.search(line)
        if begin is not None:
            current = Frame(
                screen=begin.group(1),
                width=float(begin.group(2)),
                height=float(begin.group(3)),
                declared=int(begin.group(4)),
            )
            frames.append(current)
            continue

        end = _END.search(line)
        if end is not None:
            if current is not None and current.screen == end.group(1):
                current.complete = True
                current = None
            continue

        if current is None:
            continue

        item = _ITEM.search(line)
        if item is None:
            continue

        kind, name = item.group(1), item.group(2)
        try:
            rect = tuple(float(item.group(index)) for index in (3, 4, 5, 6))
        except ValueError:  # pragma: no cover - the regex only admits numbers
            raise DumpError("%s:%d: unreadable rectangle %r" % (origin, number, line))
        current.items.append(
            Item(kind=kind, name=name, rect=rect, text=_read_string(item.group(7)))
        )

    return frames


def _read_string(raw: Optional[str]) -> str:
    """The quoted label at the end of an item line, if there is one."""
    if not raw:
        return ""
    raw = raw.strip()
    if not raw.startswith('"'):
        return raw
    try:
        value = json.loads(raw)
    except json.JSONDecodeError:
        return raw.strip('"')
    return value if isinstance(value, str) else ""


def parse_file(path: Path) -> List[Frame]:
    """Every frame in a log file."""
    path = Path(path)
    try:
        text = path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        raise DumpError("cannot read %s: %s" % (path, exc)) from exc
    frames = parse_text(text, str(path))
    if not frames:
        raise DumpError(
            "no `UI    [GEOM] begin ...` line in %s - was the game run with "
            "global.devMode = true, and was a meta screen opened?" % path
        )
    return frames


def load(paths: Iterable[Path]) -> List[Frame]:
    """Frames from several logs, de-duplicated by (screen, size).

    The same screen dumps once per size per run, so the same block can appear in
    two logs; comparing a layout across the three aspect ratios the game
    supports is what this is for, so the first copy wins and the rest are
    dropped.
    """
    seen: Dict[Tuple[str, str], Frame] = {}
    order: List[Tuple[str, str]] = []
    for path in paths:
        for frame in parse_file(path):
            key = (frame.screen, frame.size)
            if key in seen:
                continue
            seen[key] = frame
            order.append(key)
    return [seen[key] for key in order]


__all__ = ["DumpError", "Frame", "Item", "Rect", "load", "parse_file", "parse_text"]
