"""The art pass: pixels, files, and a picture of the result.

Why this exists
---------------
The restyled zombie sprites arrived with anti-aliased edges - a one-pixel ramp
of fractional alpha, plus a halo of ``alpha 1..8`` pixels a row or two outside
the silhouette.  At 1:1 it looks like a drawing; at the ``base_scale 0.25`` the
game actually draws, a 50 %-covered pixel becomes 12 %-covered and the sprite
reads as a grey smudge with no edge at all.  The fix is not a filter, it is
arithmetic: alpha is either 0 or 255, and the contour is one colour.

Why a tool and a gate, not a one-off script
-------------------------------------------
There are forty of these sets and more art coming, and the question "is this
drop clean?" has a yes/no answer that a machine can give in a second.  So the
same shape as the rest of ``python_tools``: ``check`` measures, ``clean`` acts,
``preview`` shows, and the numbers come from the pixels rather than from a note
that says it was done.

The package is standard-library only, on purpose: :mod:`gm.art.png` decodes and
re-encodes 8-bit PNGs with ``zlib`` alone, so no image library can quietly
reinterpret a sprite.

Modules:

* :mod:`gm.art.png`     - the PNG codec (8-bit, non-interlaced, all filters)
* :mod:`gm.art.pixels`  - binarize / inner outline / narrow-feature count
* :mod:`gm.art.sprites` - a sprite's ``.yy`` -> its root and layer PNGs
* :mod:`gm.art.clean`   - the pass, and the read-back verification of it
* :mod:`gm.art.report`  - the table and the before/after contact sheet
"""

from . import clean, pixels, png, report, sprites
from .cli import add_parser, cmd_art

__all__ = ["clean", "pixels", "png", "report", "sprites", "cmd_art", "add_parser"]
