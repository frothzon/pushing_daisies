"""Mapping between GameMaker event types and the ``EventType_Num.gml`` files.

An object stores one ``.gml`` file per event in its folder, e.g. ``Create_0.gml``
or ``Draw_75.gml``, and lists those events in its ``.yy`` ``eventList``.  This
module converts between the ``(eventType, eventNum)`` pair used in the ``.yy``
and the file name GameMaker uses on disk.
"""

from __future__ import annotations

import re
from typing import Optional, Tuple

__all__ = [
    "EVENT_TYPE_NAMES",
    "EVENT_TYPE_IDS",
    "event_filename",
    "parse_event_filename",
    "event_label",
]

#: ``eventType`` -> the prefix GameMaker uses in event file names.
EVENT_TYPE_NAMES = {
    0: "Create",
    1: "Destroy",
    2: "Alarm",
    3: "Step",
    4: "Collision",
    5: "Keyboard",
    6: "Mouse",
    7: "Other",
    8: "Draw",
    9: "KeyPress",
    10: "KeyRelease",
    11: "Trigger",
    12: "CleanUp",
    13: "Gesture",
    14: "PreCreate",
}

#: The inverse of :data:`EVENT_TYPE_NAMES`.
EVENT_TYPE_IDS = {name: id_ for id_, name in EVENT_TYPE_NAMES.items()}

_EVENT_FILE_RE = re.compile(r"^([A-Za-z]+)_(.+)\.gml$")

# Common eventNum meanings, used only for friendlier labels.
_STEP_NAMES = {0: "Step", 1: "Begin Step", 2: "End Step"}
_DRAW_NAMES = {
    0: "Draw",
    64: "Draw GUI",
    65: "Window Resize",
    72: "Pre Draw",
    73: "Post Draw",
    74: "Draw GUI Begin",
    75: "Draw GUI End",
    76: "Pre Draw",
    77: "Post Draw",
}


def event_filename(
    event_type: int, event_num: int, collision_name: Optional[str] = None
) -> str:
    """Return the ``.gml`` file name for an event.

    Collision events name the file after the other object rather than using
    the numeric ``eventNum``, so pass *collision_name* for those.
    """
    prefix = EVENT_TYPE_NAMES.get(event_type, f"Event{event_type}")
    if event_type == 4 and collision_name:
        return f"Collision_{collision_name}.gml"
    return f"{prefix}_{event_num}.gml"


def parse_event_filename(filename: str) -> Optional[Tuple[int, str]]:
    """Parse ``Draw_75.gml`` into ``(8, "75")``.

    The numeric part is returned as a string because collision events store the
    other object's name there.  Returns ``None`` if *filename* is not an event
    file.
    """
    match = _EVENT_FILE_RE.match(filename)
    if not match:
        return None
    type_id = EVENT_TYPE_IDS.get(match.group(1))
    if type_id is None:
        return None
    return type_id, match.group(2)


def event_label(event_type: int, event_num: int) -> str:
    """Return a human readable label such as ``Draw (Draw GUI)``."""
    name = EVENT_TYPE_NAMES.get(event_type, f"Event{event_type}")
    if event_type == 3:
        name = _STEP_NAMES.get(event_num, name)
    elif event_type == 8:
        name = _DRAW_NAMES.get(event_num, name)
    else:
        name = f"{name} {event_num}"
    return name
