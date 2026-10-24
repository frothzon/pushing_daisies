"""``gm art`` - the command line over the art pass.

Three verbs, one selector:

* ``check``   - measure the sprites against the rule; exit 1 on any finding.
  This is the gate, and it reads pixels rather than trusting that a pass ran;
* ``clean``   - do it: binarize the alpha and ink the contour, in place;
* ``preview`` - a before/after sheet, for the only question a number cannot
  answer ("does the rim look right?").

``--dry-run`` measures without writing, and is the way to see the size of the
job before committing to it.  ``--backup DIR`` copies the untouched files under
*DIR* first, mirroring the project layout, which is also what ``preview`` reads
so that "before" is a file and not a memory.

Nothing here writes a ``.yy``: the pass cannot change a sprite's size, so canvas,
origin and bounding box stay exactly as the art tool left them, and ``gm
roundtrip`` has nothing new to disagree with.
"""

from __future__ import annotations

import sys
import tempfile
from pathlib import Path
from typing import Any, List, Optional

from ..project import Project
from . import clean as clean_mod
from . import pixels, report
from . import sprites as sprites_mod

__all__ = ["cmd_art", "add_parser"]

DEFAULT_PREVIEW = Path(tempfile.gettempdir()) / "gm_art_preview.png"


def add_parser(sub: Any) -> Any:
    """Register the ``art`` sub-command on the main parser's subparsers."""
    p = sub.add_parser("art", help="clean sprite pixels: snap alpha, ink the contour")
    p.add_argument("action", nargs="?", default="check",
                   choices=["check", "clean", "preview"],
                   help="default: check")
    p.add_argument("sprites", nargs="*", metavar="SPRITE",
                   help="sprite names or globs (spr_bell_ringer_*)")
    p.add_argument("--sprite", action="append", default=[], metavar="PATTERN",
                   help="a sprite name or glob, repeatable - the reliable form when "
                        "other options are also given (argparse cannot mix a "
                        "positional list with options in the middle)")
    p.add_argument("--folder", metavar="TEXT",
                   help="only sprites whose .yyp folder path contains TEXT")
    p.add_argument("--state", nargs="+", metavar="SUFFIX",
                   help="only these state suffixes (idle walk attack die)")
    p.add_argument("--threshold", type=int, default=pixels.DEFAULT_THRESHOLD,
                   help="alpha at or above this becomes opaque (default %d)"
                        % pixels.DEFAULT_THRESHOLD)
    p.add_argument("--width", type=int, default=1,
                   help="outline thickness in pixels, inside the silhouette (default 1)")
    p.add_argument("--dry-run", action="store_true",
                   help="clean: measure and report, write nothing")
    p.add_argument("--backup", metavar="DIR",
                   help="clean: copy the untouched files under DIR first")
    p.add_argument("--out", metavar="PNG", help="preview: where to write the sheet")
    p.add_argument("--cell", type=int, default=220, help="preview: cell size (default 220)")
    p.add_argument("--cols", type=int, default=10,
                   help="preview: sprites per row of blocks (default 10)")
    p.set_defaults(func=cmd_art)
    return p


def cmd_art(args: Any) -> int:
    root = getattr(args, "project", None) or "."
    project = Project(Path(root))

    chosen, notes = sprites_mod.select(
        project,
        patterns=(list(getattr(args, "sprites", []) or [])
                  + list(getattr(args, "sprite", []) or [])) or None,
        folder=getattr(args, "folder", None),
        states=getattr(args, "state", None),
    )
    for note in notes:
        print("ART   . %s" % note)
    if not chosen:
        return 2

    action = getattr(args, "action", None) or "check"
    if action == "check":
        return _check(chosen)
    if action == "clean":
        return _clean(project, chosen, args)
    if action == "preview":
        return _preview(project, chosen, args)
    print("ART   ! unknown art action %r (check / clean / preview)" % action,
          file=sys.stderr)
    return 2


def _check(chosen: List[sprites_mod.Sprite]) -> int:
    results = [clean_mod.check_sprite(sprite) for sprite in chosen]
    for result in results:
        for line in report.render_check(result):
            print(line)
    print(report.summary(results, "check"))
    return 0 if all(result.ok for result in results) else 1


def _clean(project: Project, chosen: List[sprites_mod.Sprite], args: Any) -> int:
    dry_run = bool(getattr(args, "dry_run", False))

    if args.backup and not dry_run:
        paths = [path for sprite in chosen for path in sprite.files() if path.exists()]
        written = sprites_mod.backup(project, paths, Path(args.backup))
        print("ART   backup: %d file(s) under %s" % (len(written), args.backup))

    results = []
    for sprite in chosen:
        result = clean_mod.clean_sprite(sprite, args.threshold, args.width, dry_run)
        for line in report.render_clean(result, dry_run):
            print(line)
        results.append(result)

    print(report.summary(results, "clean"))
    if dry_run:
        print("ART   dry run: nothing was written (drop --dry-run to write)")
    return 0 if all(result.ok for result in results) else 1


def _preview(project: Project, chosen: List[sprites_mod.Sprite], args: Any) -> int:
    if not args.backup:
        print("ART   preview needs --backup DIR: the tree clean --backup wrote",
              file=sys.stderr)
        return 2
    out = Path(args.out) if args.out else DEFAULT_PREVIEW
    path, notes = report.preview(project.root, chosen, Path(args.backup), out,
                                 cell=args.cell, cols=args.cols)
    for note in notes:
        print("ART   . %s" % note)
    print("ART   preview: %s" % path)
    print("ART   columns: %s"
          % ", ".join("%d %s" % (i + 1, s.name) for i, s in enumerate(chosen[:args.cols])))
    print("ART   rows: 1 before, 2 after, 3 before zoomed, 4 after zoomed")
    return 0
