"""The headless layout checker.

Answers "does this rectangle sit on top of that one?" without a screenshot, at
every aspect ratio the game supports, in CI.

WHY A CHECKER AND NOT SCREENSHOTS.  A UI overlap is invisible at the one
resolution a screenshot was taken at: the World Map title clears the currency
line at 960 by 1px and runs 28px through it at 5:4, and the Garden Book's shop
column is only off-canvas below 972 wide.  Eyeballing one frame cannot see that,
and a playtest only gets looked at once.  So the geometry is dumped from the
running game and *measured*, the way ``gm balance`` measures a curve instead of
playing sixty waves.

THE TWO HALVES, AND WHICH IS AUTHORITATIVE:

* the **game** owns the rectangles.  ``scr_ui_check`` registers every drawn box
  and every string (with ``string_width``) and prints one JSON line per screen
  per aspect.  That is the same code path that paints, so it cannot describe a
  layout the game does not have;
* **this package** owns the analysis: text metrics read from the same glyph
  sheets (so a fit can be predicted before a run), then the rules - box on box,
  text on text, text off its own panel, anything off the canvas.

:mod:`gm.layout.metrics` is the only place a glyph width is decided, so a
"will this fit?" answer and an "it does not fit" finding can never disagree.

Modules:

* :mod:`gm.layout.metrics` -- glyph ink widths and ``string_width``, from the PNGs
* :mod:`gm.layout.dump`    -- the game's JSON dump -> rectangles
* :mod:`gm.layout.rules`   -- the overlap rules
* :mod:`gm.layout.report`  -- the read-out
"""

from . import cli, dump, metrics, report, rules
from .cli import cmd_layout

__all__ = ["cli", "dump", "metrics", "report", "rules", "cmd_layout"]
