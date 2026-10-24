"""What an art pass needs to do to a sprite, and nothing else.

Three operations, each a pure function on an RGBA buffer, so every one of them
can be tested on a 5x5 picture instead of on 640 frames:

``binarize``
    Snap ``0 < alpha < 255`` to either 255 or fully transparent.  Anti-aliasing
    is a lie on a pixel sprite: at 0.25 draw scale a 50 %-covered edge pixel
    becomes a 12 %-covered one, which is the soft grey fringe that reads as
    "blurry" in game even though the PNG looks fine at 1:1.  The threshold is
    the 50 % coverage contour, so the silhouette neither fattens nor loses ink.
    Pixels that become transparent also have their colour zeroed - otherwise a
    bilinear texture fetch at the edge mixes the discarded halo's colour back in.

``inner_outline``
    Stroke the contour black, *inside* the silhouette: every opaque pixel with a
    transparent 4-neighbour is repainted.  A 1 px stroke whose outer edge is the
    silhouette puts its centreline half a pixel inside - which is what "inset by
    0.5 px" means in raster terms - and grows the sprite by nothing, so the
    canvas, the origin and the ``.yy`` bounding box all stay as they are.  The
    ring runs around interior holes too (the gap between an arm and a torso is a
    contour like any other).

``narrow_components``
    Count silhouette islands with no interior at all - a 1 px chain, a weed
    tendril.  A stroke consumes those completely, so they are reported by name
    before anyone looks at the result and wonders where the detail went.

Nothing here reads or writes a file.  :mod:`gm.art.sprites` owns the files and
:mod:`gm.art.clean` decides what to call in what order.
"""

from __future__ import annotations

from typing import List, Sequence, Tuple

__all__ = [
    "CLEAR",
    "INK",
    "DEFAULT_THRESHOLD",
    "binarize",
    "opaque_mask",
    "boundary",
    "inner_outline",
    "narrow_components",
    "problems",
    "alpha_histogram",
]

#: A fully transparent pixel with no colour, which is what a discarded halo
#: has to become.
CLEAR = (0, 0, 0, 0)

#: The stroke colour.  Pure black, fully opaque: the whole point is an edge that
#: is one colour at every draw scale.
INK = (0, 0, 0, 255)

#: 50 % coverage.  Anything at or above it is part of the silhouette.
DEFAULT_THRESHOLD = 128


def binarize(rgba: bytes, threshold: int = DEFAULT_THRESHOLD) -> Tuple[bytes, int]:
    """Snap every alpha to 0 or 255.

    Returns ``(out, partial)`` where *partial* is how many pixels had a
    fractional alpha (the number the art pass exists to drive to zero).
    """
    if not 0 < threshold <= 255:
        raise ValueError("threshold must be 1..255, got %r" % (threshold,))
    if len(rgba) % 4:
        raise ValueError("an RGBA buffer is a multiple of 4 bytes, got %d" % len(rgba))

    out = bytearray(len(rgba))
    partial = 0
    for i in range(0, len(rgba), 4):
        a = rgba[i + 3]
        if a == 255:
            out[i:i + 4] = rgba[i:i + 4]
        elif a == 0:
            continue                    # already clear; colour is dropped below
        else:
            partial += 1
            if a >= threshold:
                out[i] = rgba[i]
                out[i + 1] = rgba[i + 1]
                out[i + 2] = rgba[i + 2]
                out[i + 3] = 255
            # else: stays (0,0,0,0), so no halo colour survives
    return bytes(out), partial


def opaque_mask(rgba: bytes) -> bytearray:
    """1 where the pixel is fully opaque, 0 everywhere else."""
    mask = bytearray(len(rgba) // 4)
    for p in range(len(mask)):
        if rgba[p * 4 + 3] == 255:
            mask[p] = 1
    return mask


def boundary(mask: bytearray, width: int, height: int) -> List[int]:
    """Pixel indices of every opaque pixel touching a transparent one or the edge."""
    if len(mask) != width * height:
        raise ValueError("mask is %d pixels, canvas is %dx%d" % (len(mask), width, height))
    ring: List[int] = []
    for y in range(height):
        row = y * width
        for x in range(width):
            p = row + x
            if not mask[p]:
                continue
            if (x == 0 or x == width - 1 or y == 0 or y == height - 1
                    or not mask[p - 1] or not mask[p + 1]
                    or not mask[p - width] or not mask[p + width]):
                ring.append(p)
    return ring


def inner_outline(
    rgba: bytes,
    width: int,
    height: int,
    stroke: int = 1,
    colour: Sequence[int] = INK,
) -> Tuple[bytes, int]:
    """Repaint the silhouette's contour in *colour*, keeping the silhouette.

    Returns ``(out, painted)``.  The mask is punched out as each ring is
    painted, so ``stroke=2`` puts the second ring immediately behind the first
    instead of rediscovering the same contour.
    """
    if stroke < 0:
        raise ValueError("stroke must be >= 0, got %r" % (stroke,))
    if len(colour) != 4:
        raise ValueError("a stroke colour is (r, g, b, a), got %r" % (colour,))
    if len(rgba) != width * height * 4:
        raise ValueError("%d bytes of pixels for %dx%d" % (len(rgba), width, height))

    out = bytearray(rgba)
    mask = opaque_mask(rgba)
    painted = 0
    for _ in range(stroke):
        ring = boundary(mask, width, height)
        if not ring:
            break
        for p in ring:
            i = p * 4
            if (out[i], out[i + 1], out[i + 2], out[i + 3]) != tuple(colour):
                painted += 1            # only pixels this pass actually changed
            out[i:i + 4] = bytes(colour)
            mask[p] = 0                 # already inked: the next ring goes behind
    return bytes(out), painted


def narrow_components(mask: bytearray, width: int, height: int) -> int:
    """How many islands are 1 px thick *and* touch nothing else.

    A one-pixel island with no interior is completely inked by a 1 px stroke,
    so it needs naming - a detached highlight speck or tendril disappears into
    a black dot.  Diagonal neighbours count as "touching": the contour of a
    pixel silhouette steps diagonally all the time, and those single pixels are
    meant to be inked.  Counting them would report ~50 per sprite and the
    warning would become noise, which is worse than no warning at all.
    """
    labels = [-1] * len(mask)
    count = 0
    for start in range(len(mask)):
        if not mask[start] or labels[start] != -1:
            continue
        labels[start] = count
        stack = [start]
        while stack:
            p = stack.pop()
            x = p % width
            y = p // width
            if x > 0 and mask[p - 1] and labels[p - 1] == -1:
                labels[p - 1] = count
                stack.append(p - 1)
            if x < width - 1 and mask[p + 1] and labels[p + 1] == -1:
                labels[p + 1] = count
                stack.append(p + 1)
            if y > 0 and mask[p - width] and labels[p - width] == -1:
                labels[p - width] = count
                stack.append(p - width)
            if y < height - 1 and mask[p + width] and labels[p + width] == -1:
                labels[p + width] = count
                stack.append(p + width)
        count += 1
    if not count:
        return 0

    interior = [False] * count
    touches = [False] * count
    for p, label in enumerate(labels):
        if label < 0:
            continue
        x = p % width
        y = p // width
        if (0 < x < width - 1 and 0 < y < height - 1
                and mask[p - 1] and mask[p + 1]
                and mask[p - width] and mask[p + width]):
            interior[label] = True
        for q, ok in ((p - width - 1, x > 0 and y > 0),
                      (p - width + 1, x < width - 1 and y > 0),
                      (p + width - 1, x > 0 and y < height - 1),
                      (p + width + 1, x < width - 1 and y < height - 1)):
            if ok and labels[q] >= 0 and labels[q] != label:
                touches[label] = True
                touches[labels[q]] = True
    return sum(1 for label in range(count)
               if not interior[label] and not touches[label])


def alpha_histogram(rgba: bytes) -> Tuple[int, int, int]:
    """``(clear, partial, opaque)`` pixel counts - the numbers in the report."""
    clear = partial = opaque = 0
    for i in range(3, len(rgba), 4):
        a = rgba[i]
        if a == 0:
            clear += 1
        elif a == 255:
            opaque += 1
        else:
            partial += 1
    return clear, partial, opaque


def problems(
    rgba: bytes, width: int, height: int, require_ink: bool = True
) -> List[str]:
    """Everything wrong with a frame after the pass, in plain words.

    An empty list is the gate: no fractional alpha, no colour hiding in
    transparent pixels, and - when *require_ink* is set - every contour pixel is
    the stroke colour.  Coordinates of the first offender are included, because
    "one pixel" is useless if you cannot find it.
    """
    if len(rgba) != width * height * 4:
        return ["%d bytes of pixels for %dx%d, expected %d"
                % (len(rgba), width, height, width * height * 4)]

    out: List[str] = []
    clear, partial, _ = alpha_histogram(rgba)
    if partial:
        first = next(i for i in range(0, len(rgba), 4) if 0 < rgba[i + 3] < 255)
        out.append("%d partially transparent pixel(s), first at %d,%d"
                   % (partial, (first // 4) % width, (first // 4) // width))

    coloured = 0
    first_coloured = None
    for i in range(0, len(rgba), 4):
        if rgba[i + 3] == 0 and (rgba[i] or rgba[i + 1] or rgba[i + 2]):
            coloured += 1
            if first_coloured is None:
                first_coloured = i // 4
    if coloured:
        out.append("%d transparent pixel(s) still carry a colour, first at %d,%d"
                   % (coloured, first_coloured % width, first_coloured // width))

    if require_ink:
        ink = tuple(INK)
        uninked = []
        for p in boundary(opaque_mask(rgba), width, height):
            i = p * 4
            if (rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]) != ink:
                uninked.append(p)
        if uninked:
            out.append("%d contour pixel(s) are not (0,0,0,255), first at %d,%d"
                       % (len(uninked), uninked[0] % width, uninked[0] // width))

    if clear and not any(rgba[i] for i in range(3, len(rgba), 4)):
        out.append("the frame is empty (no opaque pixels at all)")
    return out
