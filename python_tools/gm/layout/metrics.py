"""How wide a string is, without running the game.

WHY THIS EXISTS.  Every layout bug on the meta screens (a title drawn through
the currency line, a tower name wider than its cell, a shop column hanging off
the canvas) is a question about *text*: how many pixels does this string take at
this font size?  In the game that question is answered by ``string_width``, which
needs the IDE and a run.  Here it is answered from the same data the game uses,
so a checker can ask it a thousand times in a second and in CI.

WHAT IT READS, AND WHY THAT CANNOT DRIFT.  The toon fonts are
``font_add_sprite_ext(spr_toonfont_Nx, _fontText, true, sep)``
(``scripts/initialize_game/initialize_game.gml``): sub-image *i* is
``_fontText[i]``, ``prop`` is true so each glyph advances by *its own ink width*
plus ``sep``, and ``sep`` is negative (the glyphs deliberately overlap).  So:

    width(text) = sum(ink(ch) for ch in text) + sep * (len(text) - 1)

Both inputs are read out of the project, never restated:

* ``_fontText`` and the five ``sep`` values come from the GML literal, with the
  *same* regex ``tests/test_gm.py::ToonFontTests`` uses, so a sixth font or a
  re-cut map is picked up here for free (LL-067: a map one character short
  shifts every glyph and throws nothing);
* each glyph's ink width is the alphabet's real bounding box in
  ``sprites/spr_toonfont_Nx/<frame>.png`` - the same PNG the runtime slices.

THE ONE THING THAT CANNOT BE READ FROM A FILE is GM's trailing-separator rule:
whether ``string_width("a")`` counts the ``sep`` after the last glyph.  The
difference is 2px per string, which is exactly the size of the overlaps this
module exists to find, so it is not guessed - :meth:`Metrics.boot_lines` prints
the numbers in the *same shape* as the game's ``FONT`` log line, and
``gm layout metrics --log`` compares them.  If the game disagrees with
:data:`TRAILING_SEP_EXCLUDED`, flip that constant and every number here moves
with it, in one place.

Standard library only, like the rest of ``gm``.
"""

from __future__ import annotations

import re
import struct
import zlib
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

#: Font sizes the game loads, in the order ``initialize_game`` declares them.
FONT_SIZES: Tuple[int, ...] = (12, 16, 20, 32, 48)

#: The file that declares the map and the separators.
INIT_GML = "scripts/initialize_game/initialize_game.gml"

#: Where a size's glyph sheet lives, relative to the project root.
SPRITE_DIR = "sprites/spr_toonfont_{size}x"
#: See the module docstring: does ``string_width`` count the trailing ``sep``?
#: ``True`` (exclude it) is what GMS documents for a proportional sprite font,
#: and what the in-game ``FONT`` line is expected to confirm.
TRAILING_SEP_EXCLUDED = True


class MetricsError(RuntimeError):
    """The font metrics could not be read.  Always names what was expected."""




# ---------------------------------------------------------------------------
# PNG ink width
# ---------------------------------------------------------------------------
def png_ink_width(path: Path) -> Tuple[int, int, int]:
    """``(width, height, ink_width)`` of a PNG, using only ``zlib``.

    The sheet frames are 8-bit RGBA with an alpha channel, but every colour type
    is handled so a re-export in another mode does not become a wrong width - it
    becomes a supported one.
    """
    try:
        blob = path.read_bytes()
    except OSError as exc:
        raise MetricsError(f"cannot read {path}: {exc}") from exc

    width = height = 0
    bit_depth, colour_type = 8, 6
    compressed = bytearray()
    pos = 8
    while pos + 8 <= len(blob):
        (length,) = struct.unpack(">I", blob[pos:pos + 4])
        kind = blob[pos + 4:pos + 8]
        data = blob[pos + 8:pos + 8 + length]
        if kind == b"IHDR":
            width, height, bit_depth, colour_type = struct.unpack(">IIBB", data[:10])
        elif kind == b"IDAT":
            compressed += data
        elif kind == b"IEND":
            break
        pos += 12 + length

    if not width or not height:
        raise MetricsError(f"{path} has no IHDR - not a PNG?")
    if bit_depth != 8:
        raise MetricsError(f"{path}: {bit_depth}-bit PNGs are not supported (8-bit only)")

    channels = {0: 1, 2: 3, 4: 2, 6: 4}.get(colour_type)
    if channels is None:
        raise MetricsError(f"{path}: colour type {colour_type} is not supported")

    raw = zlib.decompress(bytes(compressed))
    stride = width * channels
    rows: List[bytes] = []
    previous = bytearray(stride)
    cursor = 0
    for _ in range(height):
        filter_type = raw[cursor]
        cursor += 1
        line = bytearray(raw[cursor:cursor + stride])
        cursor += stride
        if filter_type == 0:
            pass
        elif filter_type == 1:
            for x in range(channels, stride):
                line[x] = (line[x] + line[x - channels]) & 0xFF
        elif filter_type == 2:
            for x in range(stride):
                line[x] = (line[x] + previous[x]) & 0xFF
        elif filter_type == 3:
            for x in range(stride):
                left = line[x - channels] if x >= channels else 0
                line[x] = (line[x] + ((left + previous[x]) >> 1)) & 0xFF
        elif filter_type == 4:
            for x in range(stride):
                left = line[x - channels] if x >= channels else 0
                up = previous[x]
                up_left = previous[x - channels] if x >= channels else 0
                estimate = left + up - up_left
                d_left = abs(estimate - left)
                d_up = abs(estimate - up)
                d_up_left = abs(estimate - up_left)
                if d_left <= d_up and d_left <= d_up_left:
                    predictor = left
                elif d_up <= d_up_left:
                    predictor = up
                else:
                    predictor = up_left
                line[x] = (line[x] + predictor) & 0xFF
        else:
            raise MetricsError(f"{path}: unknown PNG filter {filter_type}")
        rows.append(bytes(line))
        previous = line

    alpha = channels - 1
    has_alpha = colour_type in (4, 6)

    def is_ink(row: bytes, x: int) -> bool:
        if has_alpha:
            return bool(row[x * channels + alpha])
        base = x * channels
        return any(row[base:base + channels])

    left, right = width, -1
    for y in range(height):
        row = rows[y]
        first = -1
        for x in range(width):
            if is_ink(row, x):
                first = x
                break
        if first < 0:
            continue
        last = width - 1
        while last > first and not is_ink(row, last):
            last -= 1
        if first < left:
            left = first
        if last > right:
            right = last
    if right < 0:
        return width, height, 0
    return width, height, right - left + 1


# ---------------------------------------------------------------------------
# the font, as the game builds it
# ---------------------------------------------------------------------------
def find_project_root(start: Optional[Path] = None) -> Optional[Path]:
    """The nearest directory holding a ``.yyp``, walking up from ``start``."""
    here = Path(start) if start is not None else Path(__file__).resolve().parent
    for candidate in [here, *here.parents]:
        if any(candidate.glob("*.yyp")):
            return candidate
    return None


def _unescape_gml(text: str) -> str:
    r"""Undo GML string escapes (``\\`` -> ``\``, ``\"`` -> ``"``) in a map."""
    return re.sub(r"\\(.)", r"\1", text)


def read_font_map(init_source: str) -> str:
    """The ``_fontText`` literal: the character sitting in each sub-image."""
    match = re.search(r'var _fontText = "((?:[^"\\]|\\.)*)";', init_source)
    if match is None:
        raise MetricsError(f"no _fontText literal in {INIT_GML}")
    return _unescape_gml(match.group(1))


def read_separators(init_source: str) -> Dict[int, int]:
    """``{size: sep}`` from the ``font_add_sprite_ext`` calls."""
    found: Dict[int, int] = {}
    for size in FONT_SIZES:
        pattern = (
            r"p%d:\s*font_add_sprite_ext\(\s*spr_toonfont_%dx\s*,\s*_fontText\s*,"
            r"\s*(true|false)\s*,\s*(-?\d+)\s*\)" % (size, size)
        )
        match = re.search(pattern, init_source)
        if match is None:
            raise MetricsError(
                f"{INIT_GML} has no `p{size}: font_add_sprite_ext(spr_toonfont_{size}x, "
                f"_fontText, true, sep)` call"
            )
        if match.group(1) != "true":
            raise MetricsError(
                f"p{size} is not proportional (prop = {match.group(1)}); "
                "per-glyph ink widths would be wrong"
            )
        found[size] = int(match.group(2))
    return found


def _frame_names(sheet: Path) -> List[str]:
    """Sub-image names, in the order ``font_add_sprite_ext`` maps them."""
    if not sheet.exists():
        raise MetricsError(f"missing sprite {sheet}")
    text = sheet.read_text(encoding="utf-8", errors="replace")
    names = re.findall(r'"\$GMSpriteFrame":"v1","%Name":"([^"]+)"', text)
    if not names:
        raise MetricsError(f"{sheet} lists no frames")
    return names


@dataclass(frozen=True)
class FontMetrics:
    """One size of the toon font: its map, its ink widths, its separator."""

    size: int
    sep: int
    chars: str
    ink: Dict[str, int]
    height: int

    def advance(self, char: str) -> int:
        """How far the pen moves after this glyph (ink plus overlap)."""
        if char not in self.ink:
            return 0  # a glyph the sheet does not have draws nothing
        return self.ink[char] + self.sep

    def ink_of(self, char: str) -> int:
        return self.ink.get(char, 0)

    @property
    def space(self) -> int:
        """The space glyph's ink width - the game logs this as ``space=``."""
        return self.ink_of(" ")

    def width(self, text: str, trailing: bool = TRAILING_SEP_EXCLUDED) -> int:
        """``string_width(text)`` for this size."""
        if not text:
            return 0
        total = sum(self.advance(char) for char in text)
        if trailing:
            total -= self.sep
        return total

    def height_of(self, lines: int = 1) -> int:
        """``string_height`` is one frame per line."""
        return self.height * max(1, lines)

    def fits(self, text: str, max_width: float) -> bool:
        return self.width(text) <= max_width

    def wrap(self, text: str, max_width: float) -> List[str]:
        """Break ``text`` on spaces so every line fits; a long word is cut.

        ``draw_text_ext`` wraps on spaces too, so a checker can measure a
        wrapped block the way the draw will paint it.
        """
        lines: List[str] = []
        current = ""
        for word in text.split(" "):
            candidate = word if not current else current + " " + word
            if not current or self.width(candidate) <= max_width:
                current = candidate
            else:
                lines.append(current)
                current = word
        if current:
            lines.append(current)
        return lines

    def clip(self, text: str, max_width: float, suffix: str = "..") -> str:
        r"""Shorten ``text`` with ``suffix`` until it fits.

        ``suffix`` is ``".."`` and not ``"\u2026"`` because the map is
        ``"!".."~"`` - there is no ellipsis glyph to draw (LL-067 again: a
        character with no sub-image silently draws nothing).
        """
        if self.fits(text, max_width):
            return text
        tail = min(len(suffix), len(text))
        cut = text[:len(text) - tail]
        while cut and not self.fits(cut + suffix, max_width):
            cut = cut[:-1]
        return (cut + suffix) if cut else ""


@dataclass(frozen=True)
class Metrics:
    """Every size, loaded from one project."""

    root: Path
    fonts: Dict[int, FontMetrics]

    def font(self, size: int) -> FontMetrics:
        try:
            return self.fonts[size]
        except KeyError:
            raise MetricsError(
                f"no font at size {size}; the game loads {sorted(self.fonts)}"
            ) from None

    def width(self, text: str, size: int = 16) -> int:
        return self.font(size).width(text)

    def height(self, size: int = 16) -> int:
        return self.font(size).height

    def fit_size(self, text: str, max_width: float,
                 sizes: Sequence[int] = (16, 12)) -> Optional[int]:
        """The largest size in ``sizes`` whose width fits, or ``None``."""
        for size in sizes:
            if size in self.fonts and self.fonts[size].width(text) <= max_width:
                return size
        return None

    def boot_lines(self) -> List[str]:
        """The ``FONT`` lines, in the shape ``initialize_game`` logs them.

        Compare these against the game's output - a metric nobody checks is a
        metric that is wrong.  ``space=`` is printed twice on purpose: ``ink`` is
        the glyph's own width, and ``incl-sep`` is what the game prints if it
        does *not* drop the trailing separator, so whichever number the log
        shows settles :data:`TRAILING_SEP_EXCLUDED`.
        """
        lines: List[str] = []
        for size in (16, 48):
            font = self.fonts.get(size)
            if font is None:
                continue
            space = font.width("a a") - 2 * font.width("a")
            lines.append(
                "FONT   p%d i=%d W=%d space=%d line=%d  (space incl-sep=%d)"
                % (size, font.width("i"), font.width("W"), space,
                   font.height_of(1), space + font.sep)
            )
        return lines

    def table(self) -> List[str]:
        """One row per size: the separator, and the ink of a few probe glyphs.

        ``space`` is the game's own definition - ``string_width("a a") -
        2*string_width("a")`` - so a row can be compared with the ``FONT`` log
        line without arithmetic.  ``ink`` is the glyph's raw bounding box.
        """
        rows = ["size  sep   W   i  space  ink  height  glyphs"]
        for size in sorted(self.fonts):
            font = self.fonts[size]
            space = font.width("a a") - 2 * font.width("a")
            rows.append(
                "%4d  %3d  %3d  %2d  %5d  %3d  %6d  %6d"
                % (size, font.sep, font.width("W"), font.width("i"),
                   space, font.space, font.height, len(font.chars))
            )
        return rows


# ---------------------------------------------------------------------------
# loading
# ---------------------------------------------------------------------------
_CACHE: Dict[Path, Metrics] = {}


def load(root: Optional[Path] = None, *, fresh: bool = False) -> Metrics:
    """Read every size out of the project at ``root``, caching per root.

    Raises :class:`MetricsError` rather than guessing: a sheet whose frame count
    disagrees with the map is the LL-067 bug, and a checker built on a shifted
    map would report overlaps that are not there - or miss the ones that are.
    """
    project = Path(root) if root is not None else find_project_root()
    if project is None:
        raise MetricsError("no GameMaker project (.yyp) found above this file")
    project = project.resolve()
    if not fresh and project in _CACHE:
        return _CACHE[project]

    init_path = project / INIT_GML
    try:
        init_source = init_path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        raise MetricsError(f"cannot read {INIT_GML}: {exc}") from exc

    chars = read_font_map(init_source)
    separators = read_separators(init_source)

    fonts: Dict[int, FontMetrics] = {}
    for size, sep in separators.items():
        sprite = SPRITE_DIR.format(size=size)
        sheet = project / sprite / f"{Path(sprite).name}.yy"
        frames = _frame_names(sheet)
        if len(frames) != len(chars):
            raise MetricsError(
                f"{sprite} has {len(frames)} frames but _fontText has {len(chars)} "
                "characters - the map is out of step with the sheet (LL-067)"
            )
        ink: Dict[str, int] = {}
        height = size
        for char, frame in zip(chars, frames):
            _w, frame_height, ink_width = png_ink_width(project / sprite / f"{frame}.png")
            ink[char] = ink_width
            height = max(height, frame_height)
        fonts[size] = FontMetrics(size=size, sep=sep, chars=chars, ink=ink, height=height)

    metrics = Metrics(root=project, fonts=fonts)
    _CACHE[project] = metrics
    return metrics


__all__ = [
    "FONT_SIZES",
    "FontMetrics",
    "Metrics",
    "MetricsError",
    "TRAILING_SEP_EXCLUDED",
    "find_project_root",
    "load",
    "png_ink_width",
    "read_font_map",
    "read_separators",
]
