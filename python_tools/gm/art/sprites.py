"""From a sprite name in the ``.yyp`` to the PNG files that hold its pixels.

A GameMaker sprite is two copies of the same picture: ``<frame guid>.png`` at
the top of the sprite folder, and the same pixels again in
``layers/<frame guid>/<layer guid>.png``.  The texture the game draws comes from
the layer copy; the top copy is what the IDE shows in the frame strip.  Writing
only one of them is how a "fixed" sprite comes back unchanged in the editor, so
a :class:`Frame` here holds both paths and the writer updates both from the same
buffer.

The GUID file names are read from the ``.yy`` (``frames[].name`` and
``layers[].name``), never guessed with a glob: a stray PNG in the folder is not
a frame, and a sprite whose frame list disagrees with its files is reported
rather than half-written.

Selection is by sprite name glob, by the logical folder path recorded in the
``.yyp`` (``Tower Defense/Zombie Sprites/restyled``), and by state suffix
(``_idle``, ``_walk``, ``_attack``, ``_die``).  The logical path is the one the
IDE shows, so "the restyled zombies" is a selector a person can check by eye -
the filesystem holds every sprite in ``sprites/`` and cannot tell them apart.
"""

from __future__ import annotations

import fnmatch
import shutil
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

from ..project import Project

__all__ = ["Frame", "Sprite", "folder_paths", "sprite", "select", "backup"]


@dataclass
class Frame:
    """One frame of a sprite: its root PNG and its one-per-layer copies."""

    name: str
    width: int
    height: int
    root: Path
    layers: List[Path] = field(default_factory=list)

    def files(self) -> List[Path]:
        return [self.root] + list(self.layers)


@dataclass
class Sprite:
    """A sprite resource and the frames it says it has."""

    name: str
    folder: Path
    folder_path: str
    frames: List[Frame]

    def files(self) -> List[Path]:
        out: List[Path] = []
        for frame in self.frames:
            out.extend(frame.files())
        return out

    def size(self) -> Tuple[int, int]:
        if not self.frames:
            return (0, 0)
        return (self.frames[0].width, self.frames[0].height)


def folder_paths(project: Project) -> Dict[str, str]:
    """Folder GUID -> the logical path the IDE shows, from the ``.yyp``."""
    out: Dict[str, str] = {}
    for entry in project.data.get("Folders") or []:
        guid = entry.get("name")
        if guid:
            out[guid] = entry.get("folderPath") or ""
    return out



def sprite(project: Project, name: str, folders: Optional[Dict[str, str]] = None) -> Sprite:
    """Read the frame and layer GUIDs for *name* out of its ``.yy``.

    Raises ``KeyError`` when the resource does not exist and ``ValueError`` when
    it is not a sprite or declares a frame without a name.  A frame file that is
    missing from disk is left for the report to name, not filled in here.
    """
    resource = project.resource(name)
    if resource.type != "GMSprite":
        raise ValueError("%s is a %s, not a sprite" % (name, resource.type))
    data = resource.data

    width = int(data.get("width") or 0)
    height = int(data.get("height") or 0)
    if width <= 0 or height <= 0:
        raise ValueError("%s: the .yy says %dx%d" % (name, width, height))

    layer_names = [l.get("name") for l in (data.get("layers") or []) if l.get("name")]
    frames: List[Frame] = []
    for index, raw in enumerate(data.get("frames") or []):
        stub = raw.get("name")
        if not stub:
            raise ValueError("%s: frame %d has no name in the .yy" % (name, index))
        frames.append(Frame(
            name=stub,
            width=width,
            height=height,
            root=resource.folder / (stub + ".png"),
            layers=[resource.folder / "layers" / stub / (l + ".png")
                    for l in layer_names],
        ))

    folders = folder_paths(project) if folders is None else folders
    parent = (data.get("parent") or {}).get("name") or ""
    return Sprite(name, resource.folder, folders.get(parent, ""), frames)


def select(
    project: Project,
    patterns: Optional[Sequence[str]] = None,
    folder: Optional[str] = None,
    states: Optional[Sequence[str]] = None,
) -> Tuple[List[Sprite], List[str]]:
    """Return ``(sprites, notes)`` - the sprites matched, and anything surprising.

    With no selector at all this returns nothing and one note, because a pass
    that quietly means "every sprite in the project" is not a pass anyone meant
    to run.
    """
    notes: List[str] = []
    if not patterns and not folder:
        return [], ["nothing selected: pass sprite name globs or --folder"]

    states = [s if s.startswith("_") else "_" + s for s in (states or [])]

    folders = folder_paths(project)
    chosen: List[Sprite] = []
    matched_patterns = set()
    for resource in project.resources("GMSprite"):
        if patterns:
            hit = [p for p in patterns if fnmatch.fnmatchcase(resource.name, p)]
            if not hit:
                continue
            matched_patterns.update(hit)
        parent = (resource.data.get("parent") or {}).get("name") or ""
        if folder and folder.lower() not in folders.get(parent, "").lower():
            continue
        if states and not any(resource.name.endswith(s) for s in states):
            continue
        chosen.append(sprite(project, resource.name, folders))

    for pattern in patterns or []:
        if pattern not in matched_patterns:
            notes.append("no sprite matched %r" % pattern)
    if not chosen:
        notes.append("the selector matched no sprites")
    return chosen, notes


def backup(project: Project, paths: Sequence[Path], dest: Path) -> List[Path]:
    """Copy *paths* under *dest*, mirroring the project layout.

    An existing file is **not** overwritten: the point of the backup is the
    first, untouched pixels, so running the pass twice cannot replace the
    original with an already-cleaned copy.
    """
    written: List[Path] = []
    root = project.root.resolve()
    for path in paths:
        target = Path(dest) / path.resolve().relative_to(root)
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            continue
        shutil.copy2(path, target)
        written.append(target)
    return written

