"""The rules: which pairs of rectangles are a bug.

Five rules, each of which maps to something a player can see:

``canvas``  something is partly off the screen.  The Garden Book's shop column
            at 5:4 is this: it does not overlap anything, it is simply not
            there, which is why no collision rule would have caught it.
``collide`` two BOXES intersect without either containing the other.  Siblings
            in a flow never do that; hand-placed rectangles do.  Nesting (a
            button inside a panel, a cell inside a screen) is not a collision -
            that is what a layout *is*.
``text``    two strings intersect.  Always a bug: two labels on the same pixels
            is a misread, even if both are legible.
``spill``   a string intersects a box it is not inside.  That is the label that
            runs out of its own panel, and the reason the Deploy header lands in
            wall cells 4-6 - the text is wider than the cell it belongs to, so
            it crosses its neighbour.
``image``   a picture intersects a label, or crosses the edge of the cell it
            sits in.  This is the rule that was missing while every screen read
            clean and the art was visibly wrong: ``meta_sprite_fit`` registered
            the CANVAS rectangle while the pixels landed somewhere else, so the
            checker was handed a fiction, and the thumbnails it described were
            46-75% of their cells with two of them poking out (LL-071).  A
            picture inside its own cell - or big enough to be the backdrop
            behind a label - is fine, which is the same shape as ``spill``.

Tolerance, and why it is not zero.  Rects reach here from a flex solver that
lays out in floats, so a shared edge can read 0.0001 apart.  ``tol`` (0.5 GUI
unit by default) ignores those.  It does NOT ignore the Deploy seed break: that
was a 1px overlap, and 1 > 0.5.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import List, Optional, Sequence, Tuple

from .dump import Frame, Item, Rect

#: Kinds that are "a box drawn behind something".  Everything else is measured
#: as content.
BOX_KINDS = ("panel", "button")

#: Kinds a picture is allowed to sit inside.  ``area`` is registered once, for a
#: whole body region, and is a container by the same logic.
CONTAINER_KINDS = BOX_KINDS + ("area",)

#: Kinds that are "a picture".  Content, like a label: it may sit inside a box,
#: it may not cross one.
IMAGE_KINDS = ("image",)

#: A pair closer than this is a shared edge, not an overlap.
TOLERANCE = 0.5


def intersection(a: Rect, b: Rect) -> Rect:
    """The overlapping rectangle, or a zero-area one when they miss."""
    x1, y1 = max(a[0], b[0]), max(a[1], b[1])
    x2, y2 = min(a[2], b[2]), min(a[3], b[3])
    if x2 <= x1 or y2 <= y1:
        return (0.0, 0.0, 0.0, 0.0)
    return (x1, y1, x2, y2)


def area(rect: Rect) -> float:
    return max(0.0, rect[2] - rect[0]) * max(0.0, rect[3] - rect[1])


def contains(outer: Rect, inner: Rect, tol: float = TOLERANCE) -> bool:
    """Is ``inner`` inside ``outer``, within ``tol``?"""
    return (inner[0] >= outer[0] - tol and inner[1] >= outer[1] - tol
            and inner[2] <= outer[2] + tol and inner[3] <= outer[3] + tol)


def overlaps(a: Rect, b: Rect, tol: float = TOLERANCE) -> bool:
    """Do they share more than a tolerance-wide sliver?"""
    shared = intersection(a, b)
    return (shared[2] - shared[0] > tol) and (shared[3] - shared[1] > tol)


@dataclass(frozen=True)
class Finding:
    """One reason a screen is wrong, with the numbers that prove it."""

    rule: str
    screen: str
    size: str
    area: float
    a: Item
    b: Optional[Item] = None
    detail: str = ""

    def sort_key(self) -> Tuple[str, float, str]:
        return (self.screen, -self.area, self.a.name)

    def line(self) -> str:
        """The one-line report form."""
        head = "%-7s %-9s %7.0fpx2  %s" % (self.rule, self.size, self.area, self.a.label())
        if self.b is not None:
            head += "  <>  " + self.b.label()
        if self.detail:
            head += "   (" + self.detail + ")"
        return head


def check(frames: Sequence[Frame], tol: float = TOLERANCE,
          min_area: float = 0.0) -> List[Finding]:
    """Every finding in ``frames``, worst first within each screen."""
    found: List[Finding] = []
    for frame in frames:
        found.extend(_canvas(frame, tol))
        items = [item for item in frame.items if item.width > tol and item.height > tol]
        for index, first in enumerate(items):
            for second in items[index + 1:]:
                found.extend(_pair(frame, first, second, tol))
    found = [finding for finding in found if finding.area >= min_area]
    found.sort(key=lambda finding: finding.sort_key())
    return found


def _canvas(frame: Frame, tol: float) -> List[Finding]:
    """Anything not wholly inside the canvas."""
    found: List[Finding] = []
    screen = (0.0, 0.0, frame.width, frame.height)
    for item in frame.items:
        if contains(screen, item.rect, tol):
            continue
        inside = intersection(screen, item.rect)
        missing = area(item.rect) - area(inside)
        edges = []
        if item.rect[0] < -tol:
            edges.append("left %+.0f" % item.rect[0])
        if item.rect[1] < -tol:
            edges.append("top %+.0f" % item.rect[1])
        if item.rect[2] > frame.width + tol:
            edges.append("right %+.0f" % (item.rect[2] - frame.width))
        if item.rect[3] > frame.height + tol:
            edges.append("bottom %+.0f" % (item.rect[3] - frame.height))
        found.append(Finding("canvas", frame.screen, frame.size, max(missing, 0.0),
                             item, None, ", ".join(edges)))
    return found


def _pair(frame: Frame, a: Item, b: Item, tol: float) -> List[Finding]:
    """What is wrong with this pair, if anything."""
    if not overlaps(a.rect, b.rect, tol):
        return []
    shared = area(intersection(a.rect, b.rect))

    a_box, b_box = a.kind in BOX_KINDS, b.kind in BOX_KINDS
    a_text, b_text = a.kind == "text", b.kind == "text"

    if a_box and b_box:
        # nesting is the layout; a sibling that cannot contain the other is a
        # collision
        if contains(a.rect, b.rect, tol) or contains(b.rect, a.rect, tol):
            return []
        return [Finding("collide", frame.screen, frame.size, shared, a, b)]

    a_image, b_image = a.kind in IMAGE_KINDS, b.kind in IMAGE_KINDS

    if a_image or b_image:
        # A picture is CONTENT, so it follows the label's rule: inside its own
        # cell is the layout, over a label is a misread, and hanging out of the
        # cell is the bug the tower thumbnails had while every dump read clean.
        if a_image and b_image:
            return [Finding("image", frame.screen, frame.size, shared, a, b)]
        picture, other = (a, b) if a_image else (b, a)
        if contains(picture.rect, other.rect, tol):
            return []  # a backdrop behind a panel or a label
        if other.kind == "text":
            return [Finding("image", frame.screen, frame.size, shared, picture, other)]
        if other.kind in CONTAINER_KINDS:
            if contains(other.rect, picture.rect, tol):
                return []  # inside the cell it belongs to
            return [Finding("image", frame.screen, frame.size, shared, picture, other)]
        return []

    if a_text and b_text:
        return [Finding("text", frame.screen, frame.size, shared, a, b)]

    if a_text or b_text:
        text, box = (a, b) if a_text else (b, a)
        if contains(box.rect, text.rect, tol):
            return []  # inside its own panel: fine
        if contains(text.rect, box.rect, tol):
            return []  # a label wide enough to cover a whole box is a canvas
                       # finding at worst, not a pair bug
        return [Finding("spill", frame.screen, frame.size, shared, text, box)]

    return []  # anything else: not a rule yet


__all__ = [
    "BOX_KINDS",
    "CONTAINER_KINDS",
    "Finding",
    "IMAGE_KINDS",
    "TOLERANCE",
    "area",
    "check",
    "contains",
    "intersection",
    "overlaps",
]
