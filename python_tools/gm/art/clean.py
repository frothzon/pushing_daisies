"""The pass: snap a sprite's alpha, ink its contour, then prove it.

Per frame, in this order - and the order is the point:

1. decode the **root** PNG (the copy the IDE shows in the frame strip);
2. binarize, which is what "the anti-aliasing is gone" means numerically;
3. stroke the contour black, inside the silhouette;
4. encode **once** and write that same buffer to the root PNG and to every
   layer PNG, because they are two views of one picture and a sprite whose
   copies disagree is a sprite that looks fixed in the editor and soft in game;
5. read the file back and run :func:`gm.art.pixels.problems` on it.  A pass
   that does not verify what it wrote is a pass that reports success on a
   broken PNG, which is the whole class of bug this repo keeps finding.

Frame size is checked against the ``.yy`` before anything is written: a frame of
a different size means the file and the resource have drifted apart, and
re-encoding it would bake the drift in.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import List, Optional, Sequence

from . import pixels, png
from .sprites import Frame, Sprite

__all__ = ["FrameResult", "SpriteResult", "clean_frame", "clean_sprite", "check_sprite"]


@dataclass
class FrameResult:
    """What happened to one frame, in numbers."""

    name: str
    partial: int = 0
    painted: int = 0
    narrow: int = 0
    files: int = 0
    warnings: List[str] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)

    @property
    def ok(self) -> bool:
        return not self.errors


@dataclass
class SpriteResult:
    """What happened to one sprite."""

    name: str
    folder_path: str = ""
    width: int = 0
    height: int = 0
    frames: List[FrameResult] = field(default_factory=list)
    notes: List[str] = field(default_factory=list)

    @property
    def partial(self) -> int:
        return sum(f.partial for f in self.frames)

    @property
    def painted(self) -> int:
        return sum(f.painted for f in self.frames)

    @property
    def narrow(self) -> int:
        return sum(f.narrow for f in self.frames)

    @property
    def files(self) -> int:
        return sum(f.files for f in self.frames)

    @property
    def ok(self) -> bool:
        return all(f.ok for f in self.frames)

    def errors(self) -> List[str]:
        out: List[str] = []
        for frame in self.frames:
            out.extend(frame.errors)
        return out


def clean_frame(
    frame: Frame,
    threshold: int = pixels.DEFAULT_THRESHOLD,
    stroke: int = 1,
    dry_run: bool = False,
) -> FrameResult:
    """Clean one frame in place (or only measure it, when *dry_run*)."""
    result = FrameResult(frame.name)
    try:
        width, height, rgba = png.read_png(frame.root)
    except png.PngError as err:
        result.errors.append(str(err))
        return result

    if (width, height) != (frame.width, frame.height):
        result.errors.append(
            "%s is %dx%d but the .yy says %dx%d - not touching it"
            % (frame.root.name, width, height, frame.width, frame.height))
        return result

    snapped, result.partial = pixels.binarize(rgba, threshold)
    inked, result.painted = pixels.inner_outline(snapped, width, height, stroke)
    result.narrow = pixels.narrow_components(pixels.opaque_mask(snapped), width, height)

    if dry_run:
        return result

    for path in frame.files():
        if not path.exists():
            result.warnings.append("%s: layer PNG is missing, left alone" % path)
            continue
        try:
            png.write_png(path, width, height, inked)
            result.files += 1
        except (OSError, png.PngError) as err:
            result.errors.append("%s: %s" % (path, err))

    # Prove it: the bytes on disk, read back, must be exactly what we meant.
    for path in frame.files():
        if not path.exists():
            continue
        try:
            w, h, back = png.read_png(path)
        except png.PngError as err:
            result.errors.append("%s did not read back: %s" % (path, err))
            continue
        if (w, h) != (width, height):
            result.errors.append("%s came back %dx%d, expected %dx%d"
                                 % (path.name, w, h, width, height))
            continue
        if back != inked:
            result.errors.append("%s does not hold the pixels we wrote" % path.name)
            continue
        for problem in pixels.problems(back, w, h):
            result.errors.append("%s: %s" % (path.name, problem))
    return result


def clean_sprite(
    sprite: Sprite,
    threshold: int = pixels.DEFAULT_THRESHOLD,
    stroke: int = 1,
    dry_run: bool = False,
) -> SpriteResult:
    """Clean every frame of *sprite*."""
    result = SpriteResult(sprite.name, sprite.folder_path, *sprite.size())
    if not sprite.frames:
        result.notes.append("the .yy lists no frames")
    for frame in sprite.frames:
        result.frames.append(clean_frame(frame, threshold, stroke, dry_run))
    return result


def check_sprite(sprite: Sprite, require_ink: bool = True) -> SpriteResult:
    """Measure *sprite* against the rule, without changing anything.

    This is the gate: every frame decodes, matches the ``.yy`` size, has no
    fractional alpha, no colour in its transparent pixels, an all-black contour,
    and a layer copy identical to its root copy.
    """
    result = SpriteResult(sprite.name, sprite.folder_path, *sprite.size())
    for frame in sprite.frames:
        one = FrameResult(frame.name)
        result.frames.append(one)
        try:
            width, height, rgba = png.read_png(frame.root)
        except png.PngError as err:
            one.errors.append(str(err))
            continue
        if (width, height) != (frame.width, frame.height):
            one.errors.append("%s is %dx%d but the .yy says %dx%d"
                              % (frame.root.name, width, height, frame.width, frame.height))
            continue
        for problem in pixels.problems(rgba, width, height, require_ink):
            one.errors.append("%s: %s" % (frame.root.name, problem))

        for path in frame.files()[1:]:
            if not path.exists():
                one.warnings.append("%s: layer PNG is missing" % path)
                continue
            try:
                lw, lh, layer = png.read_png(path)
            except png.PngError as err:
                one.errors.append(str(err))
                continue
            if (lw, lh) != (width, height):
                one.errors.append("%s is %dx%d, the root is %dx%d"
                                  % (path.name, lw, lh, width, height))
            elif layer != rgba:
                one.errors.append("%s does not match the root PNG (the editor and "
                                  "the game would draw different pictures)" % path.name)
    return result
