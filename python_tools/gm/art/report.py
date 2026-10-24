"""What the art pass says, and a picture of what it did.

Two jobs:

* **the table** - one line per sprite, with the numbers that matter (frames,
  canvas, partial pixels removed, contour pixels inked, files written) and the
  problems underneath it, indented, so a failing run says which *frame* rather
  than which sprite;
* **the sheet** - a contact sheet of before/after, because "the outline looks
  right" is a judgement only eyes can make, and the new zombies are not wired
  into any object yet, so the sprite editor is the only other place to look.
  Row per view: before at 1:1, after at 1:1, then both zoomed on the silhouette's
  head so a 1 px rim is actually visible.

The sheet composites over a checkerboard, which is the only background on which
a partially transparent pixel is obvious: on black a 12 %-coverage pixel looks
like ink, on white it looks like nothing.
"""

from __future__ import annotations

from pathlib import Path
from typing import List, Optional, Sequence, Tuple

from . import png
from .clean import SpriteResult
from .sprites import Sprite

__all__ = ["render_clean", "render_check", "summary", "preview"]

#: Checkerboard colours: mid greys, so neither a black contour nor a white
#: highlight can hide against them.
CHECKER = ((64, 64, 68, 255), (88, 88, 94, 255))
CHECKER_SIZE = 8


def _fmt(n: int) -> str:
    return "{:,}".format(n).replace(",", " ")


def render_clean(result: SpriteResult, dry_run: bool = False) -> List[str]:
    """One line per sprite for a ``clean`` run, plus its warnings and errors."""
    lines = []
    size = "%dx%d" % (result.width, result.height)
    lines.append(
        "ART   %-34s %2d frames  %-9s  partial %7s -> 0  stroke %7s px%s"
        % (result.name, len(result.frames), size, _fmt(result.partial),
           _fmt(result.painted), "   (dry run)" if dry_run else ""))
    if result.narrow:
        lines.append("ART       ~ %d isolated 1 px speck(s) - the stroke turns each into "
                     "a black dot, check the preview" % result.narrow)
    for note in result.notes:
        lines.append("ART       . %s" % note)
    for frame in result.frames:
        for warning in frame.warnings:
            lines.append("ART       ~ %s" % warning)
        for error in frame.errors:
            lines.append("ART       ! %s" % error)
    return lines


def render_check(result: SpriteResult) -> List[str]:
    """One line for a sprite that passes, and every problem for one that does not."""
    if result.ok:
        return ["ART   %-34s %2d frames  %-9s  ok"
                % (result.name, len(result.frames),
                   "%dx%d" % (result.width, result.height))]
    lines = ["ART   %-34s %2d frames  %-9s  PROBLEM"
             % (result.name, len(result.frames),
                "%dx%d" % (result.width, result.height))]
    for frame in result.frames:
        for warning in frame.warnings:
            lines.append("ART       ~ %s" % warning)
        for error in frame.errors:
            lines.append("ART       ! %s" % error)
    return lines


def summary(results: Sequence[SpriteResult], mode: str) -> str:
    """The last line: totals, and the one verdict."""
    sprites = len(results)
    frames = sum(len(r.frames) for r in results)
    files = sum(r.files for r in results)
    partial = sum(r.partial for r in results)
    painted = sum(r.painted for r in results)
    broken = [r for r in results if not r.ok]
    if mode == "check":
        verdict = ("ok    every frame is hard-edged, inked and identical to its "
                   "layer copy" if not broken
                   else "FAIL  %d sprite(s) do not match the rule" % len(broken))
        return ("ART   %d sprites, %d frames: %s"
                % (sprites, frames, verdict))
    return ("ART   %d sprites, %d frames, %s files: %s partial pixels -> 0, "
            "%s contour pixels inked%s"
            % (sprites, frames, _fmt(files), _fmt(partial), _fmt(painted),
               "" if not broken else "  (%d sprite(s) FAILED)" % len(broken)))



def _silhouette_box(rgba: bytes, width: int, height: int) -> Tuple[int, int, int, int]:
    """The tight box round the opaque pixels, or the whole canvas if there are none."""
    min_x, min_y, max_x, max_y = width, height, -1, -1
    for y in range(height):
        row = y * width
        for x in range(width):
            if rgba[(row + x) * 4 + 3]:
                if x < min_x:
                    min_x = x
                if x > max_x:
                    max_x = x
                if y < min_y:
                    min_y = y
                if y > max_y:
                    max_y = y
    if max_x < 0:
        return (0, 0, width, height)
    return (min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


def _head_box(box: Tuple[int, int, int, int],
              min_side: int = 12) -> Tuple[int, int, int, int]:
    """A square window on the head: half the sprite's short side, a bit down.

    Square because a wide, short creature (the shroud) otherwise zooms into a
    letterbox of nothing; half the short side shows a face and enough contour to
    judge the rim, at roughly the same zoom for every sprite.
    """
    x, y, w, h = box
    side = min(max(min_side, int(round(min(w, h) * 0.5))), w, h)
    left = x + max(0, (w - side) // 2)
    top = y + max(0, min(h - side, h // 4))
    return (left, top, max(1, side), max(1, side))


def _cell(rgba: bytes, sw: int, sh: int,
          box: Tuple[int, int, int, int], size: int) -> bytes:
    """Resample *box* of the source into a *size* square cell, over a checkerboard.

    Nearest-neighbour on purpose: a smoothed preview of a hard edge would look
    exactly like the anti-aliasing this pass removes.
    """
    x0, y0, bw, bh = box
    scale = min(size / bw, size / bh)
    if scale >= 1:
        scale = float(max(1, int(scale)))      # integer zoom, so pixels stay square
    dw = max(1, min(size, int(round(bw * scale))))
    dh = max(1, min(size, int(round(bh * scale))))
    ox, oy = (size - dw) // 2, (size - dh) // 2

    out = bytearray(size * size * 4)
    for y in range(size):
        for x in range(size):
            i = (y * size + x) * 4
            out[i:i + 4] = bytes(CHECKER[((x // CHECKER_SIZE) + (y // CHECKER_SIZE)) % 2])

    for dy in range(dh):
        sy = min(sh - 1, y0 + min(bh - 1, (dy * bh) // dh))
        srow = sy * sw * 4
        for dx in range(dw):
            sx = min(sw - 1, x0 + min(bw - 1, (dx * bw) // dw))
            s = srow + sx * 4
            i = ((oy + dy) * size + (ox + dx)) * 4
            a = rgba[s + 3]
            if a == 255:
                out[i] = rgba[s]
                out[i + 1] = rgba[s + 1]
                out[i + 2] = rgba[s + 2]
                out[i + 3] = 255
            elif a:
                inv = 255 - a
                out[i] = (rgba[s] * a + out[i] * inv) // 255
                out[i + 1] = (rgba[s + 1] * a + out[i + 1] * inv) // 255
                out[i + 2] = (rgba[s + 2] * a + out[i + 2] * inv) // 255
                out[i + 3] = 255
    return bytes(out)


def preview(
    root: Path,
    sprites: Sequence[Sprite],
    backup: Path,
    out: Path,
    cell: int = 220,
    pad: int = 8,
    cols: int = 10,
) -> Tuple[Path, List[str]]:
    """Write a before/after contact sheet of *sprites* (frame 0 of each).

    *backup* is the tree :func:`gm.art.sprites.backup` wrote, so "before" is the
    bytes on disk before the pass rather than a memory of them.  Returns
    ``(path, notes)``; the notes are the sprites that could not be shown.
    """
    notes: List[str] = []
    columns: List[Tuple[str, bytes, bytes, int, int]] = []
    for sprite in sprites:
        if not sprite.frames:
            notes.append("%s: no frames" % sprite.name)
            continue
        frame = sprite.frames[0]
        try:
            w, h, after = png.read_png(frame.root)
        except png.PngError as err:
            notes.append(str(err))
            continue
        rel = frame.root.resolve().relative_to(Path(root).resolve())
        try:
            bw, bh, before = png.read_png(Path(backup) / rel)
        except png.PngError as err:
            notes.append("no 'before' for %s: %s" % (sprite.name, err))
            continue
        if (bw, bh) != (w, h):
            notes.append("%s: 'before' is %dx%d, now %dx%d - not compared"
                         % (sprite.name, bw, bh, w, h))
            continue
        columns.append((sprite.name, before, after, w, h))

    if not columns:
        notes.append("nothing to preview")
        return out, notes

    cols = max(1, min(cols, len(columns)))
    width = pad + cols * (cell + pad)
    rows = 4 * ((len(columns) + cols - 1) // cols)
    height = pad + rows * (cell + pad)
    sheet = bytearray(bytes((24, 24, 26, 255)) * (width * height))

    for index, (_, before, after, fw, fh) in enumerate(columns):
        block, col = divmod(index, cols)
        # The zoom is measured on the *cleaned* silhouette and then applied to
        # both, so the two rows show the same window of the same pixels.
        zoom = _head_box(_silhouette_box(after, fw, fh))
        cells = [
            _cell(before, fw, fh, (0, 0, fw, fh), cell),
            _cell(after, fw, fh, (0, 0, fw, fh), cell),
            _cell(before, fw, fh, zoom, cell),
            _cell(after, fw, fh, zoom, cell),
        ]
        for row, data in enumerate(cells):
            ox = pad + col * (cell + pad)
            oy = pad + (block * 4 + row) * (cell + pad)
            for y in range(cell):
                src = y * cell * 4
                dst = ((oy + y) * width + ox) * 4
                sheet[dst:dst + cell * 4] = data[src:src + cell * 4]

    png.write_png(out, width, height, bytes(sheet))
    return out, notes

