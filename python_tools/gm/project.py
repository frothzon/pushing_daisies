"""High level access to a GameMaker Studio 2 project.

``Project`` locates the ``.yyp`` file, indexes every resource, and hands out
:class:`Resource` objects that wrap a single ``.yy`` file.  Edits go through
:class:`gm.yy.Document`, so a change to one value leaves the rest of the file
byte-for-byte identical.

Also included are helpers for the tasks that are awkward to do by hand:

* reading/writing an object's event code (``Create_0.gml`` etc.);
* reading/writing a script's GML;
* creating new scripts and objects, including their ``.yyp`` entries.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union

from . import events as events_mod
from . import gml as gml_mod
from . import yy

__all__ = [
    "Project",
    "Resource",
    "find_project_root",
    "parse_keypath",
    "get_path",
    "set_path",
    "del_path",
]

PathLike = Union[str, "Path"]

#: Directory name -> GameMaker resource type, used to identify resources
#: without opening every ``.yy`` file.
TYPE_BY_DIR = {
    "objects": "GMObject",
    "sprites": "GMSprite",
    "sounds": "GMSound",
    "scripts": "GMScript",
    "shaders": "GMShader",
    "fonts": "GMFont",
    "rooms": "GMRoom",
    "tilesets": "GMTileSet",
    "paths": "GMPath",
    "timelines": "GMTimeline",
    "animcurves": "GMAnimCurve",
    "sequences": "GMSequence",
    "extensions": "GMExtension",
    "notes": "GMNotes",
    "particles": "GMParticleSystem",
    "datafiles": "GMDataFile",
}

#: The top-level folder each resource type lives in inside the project.
FOLDER_BY_TYPE = {
    "GMScript": "folders/Scripts.yy",
    "GMObject": "folders/Objects.yy",
    "GMSprite": "folders/Sprites.yy",
    "GMSound": "folders/Sounds.yy",
    "GMShader": "folders/Shaders.yy",
    "GMRoom": "folders/Rooms.yy",
    "GMFont": "folders/Fonts.yy",
    "GMTileSet": "folders/Tile Sets.yy",
}

_INDEX_RE = re.compile(r"\[(\d+)\]")


def find_project_root(start: PathLike = ".") -> Path:
    """Walk up from *start* until the directory containing a ``.yyp`` file."""
    path = Path(start).resolve()
    for candidate in [path, *path.parents]:
        if any(candidate.glob("*.yyp")):
            return candidate
    raise FileNotFoundError(f"no .yyp file found at or above {start}")


def parse_keypath(keypath: str) -> List[Union[str, int]]:
    """Split ``"layers[1].instances[0].x"`` into ``["layers", 1, "instances", 0, "x"]``."""
    tokens: List[Union[str, int]] = []
    for part in keypath.split("."):
        for chunk in _INDEX_RE.split(part):
            if chunk == "":
                continue
            if chunk.isdigit():
                tokens.append(int(chunk))
            else:
                tokens.append(chunk)
    return tokens


def get_path(data: Any, keypath: str, default: Any = None) -> Any:
    """Return the value at *keypath* within *data*, or *default* if missing."""
    current = data
    try:
        for token in parse_keypath(keypath):
            current = current[token]
    except (KeyError, IndexError, TypeError):
        return default
    return current


def set_path(data: Any, keypath: str, value: Any, sort: bool = False) -> Any:
    """Set the value at *keypath*, creating intermediate containers as needed.

    When a key is added to a dict it is inserted in the position GameMaker
    would use (keys are kept case-insensitively sorted, with ``_`` last) unless
    *sort* is false, in which case it is appended.  Returns *data*.
    """
    tokens = parse_keypath(keypath)
    if not tokens:
        raise ValueError("empty keypath")
    current = data
    for i, token in enumerate(tokens[:-1]):
        nxt = tokens[i + 1]
        if isinstance(token, int):
            while len(current) <= token:
                current.append(yy.GmObject() if isinstance(nxt, str) else yy.GmArray())
            current = current[token]
        else:
            if token not in current:
                current[token] = yy.GmObject() if isinstance(nxt, str) else yy.GmArray()
            current = current[token]
    last = tokens[-1]
    if isinstance(last, int):
        while len(current) <= last:
            current.append(None)
        current[last] = value
    else:
        if last not in current and isinstance(current, yy.GmObject):
            _insert_sorted(current, last, value, sort)
        else:
            current[last] = value
    return data


def _insert_sorted(obj: "yy.GmObject", key: str, value: Any, sort: bool) -> None:
    """Insert *key* into *obj* in GameMaker's key order."""
    if not sort or not obj:
        obj[key] = value
        return
    new_key = yy.gm_sort_key(key)
    for existing in list(obj.keys()):
        if yy.gm_sort_key(existing) > new_key:
            _reinsert_before(obj, key, existing, value)
            return
    obj[key] = value


def _reinsert_before(obj: "yy.GmObject", key: str, before: str, value: Any) -> None:
    items = list(obj.items())
    obj.clear()
    for existing_key, existing_value in items:
        if existing_key == before:
            obj[key] = value
        obj[existing_key] = existing_value


def del_path(data: Any, keypath: str) -> bool:
    """Delete the value at *keypath*.  Returns True if something was removed."""
    tokens = parse_keypath(keypath)
    if not tokens:
        return False
    parent = data
    for token in tokens[:-1]:
        try:
            parent = parent[token]
        except (KeyError, IndexError, TypeError):
            return False
    last = tokens[-1]
    try:
        if isinstance(last, int):
            del parent[last]
        else:
            del parent[last]
    except (KeyError, IndexError, TypeError):
        return False
    return True


class Resource:
    """A single GameMaker resource, wrapping its ``.yy`` file."""

    def __init__(self, project: "Project", name: str, path: str, resource_type: str) -> None:
        self.project = project
        self.name = name
        self.path = path  # relative to the project root, e.g. objects/x/x.yy
        self.type = resource_type
        self._document: Optional[yy.Document] = None

    # -- paths ---------------------------------------------------------------
    @property
    def yy_path(self) -> Path:
        return self.project.root / self.path

    @property
    def folder(self) -> Path:
        return self.yy_path.parent

    def gml_files(self) -> List[Path]:
        """Return the ``.gml`` files that live beside this resource's ``.yy``."""
        return sorted(self.folder.glob("*.gml"))

    # -- yy data -------------------------------------------------------------
    def document(self) -> yy.Document:
        """Load (and cache) this resource's ``.yy`` as a :class:`gm.yy.Document`."""
        if self._document is None:
            self._document = yy.Document.from_file(self.yy_path)
        return self._document

    @property
    def data(self) -> Any:
        """The parsed ``.yy`` contents (a :class:`gm.yy.GmObject`)."""
        return self.document().data

    def save(self, sort: Optional[bool] = None) -> Path:
        """Write the ``.yy`` back to disk, preserving formatting."""
        return self.document().save(sort=sort)

    # -- object events -------------------------------------------------------
    def event_entries(self) -> List[Any]:
        """Return the object's ``eventList`` entries."""
        return list(self.data.get("eventList", []))

    def events(self) -> List[Tuple[int, int, str]]:
        """Return ``(eventType, eventNum, filename)`` for every event."""
        result = []
        for entry in self.event_entries():
            event_type = int(entry.get("eventType", 0))
            event_num = int(entry.get("eventNum", 0))
            collision = None
            if event_type == 4:
                ref = entry.get("collisionObjectId") or {}
                collision = ref.get("name")
            result.append(
                (event_type, event_num,
                 events_mod.event_filename(event_type, event_num, collision))
            )
        return result

    def event_path(self, event_type: int, event_num: int) -> Path:
        """Return the ``.gml`` path for an event, resolving collision names."""
        collision = None
        if event_type == 4:
            for entry in self.event_entries():
                same = (int(entry.get("eventType", 0)) == event_type
                        and int(entry.get("eventNum", 0)) == event_num)
                if same:
                    ref = entry.get("collisionObjectId") or {}
                    collision = ref.get("name")
                    break
        return self.folder / events_mod.event_filename(event_type, event_num, collision)

    def read_event(self, event_type: int, event_num: int) -> str:
        """Return the source of an event, or an empty string if it has none."""
        path = self.event_path(event_type, event_num)
        return gml_mod.read_gml(path) if path.exists() else ""

    def write_event(self, event_type: int, event_num: int, source: str) -> Path:
        """Write an event's source, registering the event if necessary."""
        self._ensure_event(event_type, event_num)
        path = self.event_path(event_type, event_num)
        gml_mod.write_gml(path, source)
        return path

    def add_event(self, event_type: int, event_num: int) -> Path:
        """Create an empty event, returning the path to its ``.gml`` file."""
        self._ensure_event(event_type, event_num)
        path = self.event_path(event_type, event_num)
        if not path.exists():
            gml_mod.write_gml(path, "")
        return path

    def remove_event(self, event_type: int, event_num: int) -> bool:
        """Remove an event from the ``eventList`` and delete its file."""
        def matches(entry: Any) -> bool:
            return (int(entry.get("eventType", 0)) == event_type
                    and int(entry.get("eventNum", 0)) == event_num)

        removed = any(matches(entry) for entry in self.event_entries())
        events_array = self.data["eventList"]
        events_array[:] = [entry for entry in events_array if not matches(entry)]
        path = self.event_path(event_type, event_num)
        if path.exists():
            path.unlink()
            removed = True
        return removed

    def _ensure_event(self, event_type: int, event_num: int) -> None:
        for entry in self.event_entries():
            same = (int(entry.get("eventType", 0)) == event_type
                    and int(entry.get("eventNum", 0)) == event_num)
            if same:
                return
        entry = yy.GmObject()
        entry["$GMEvent"] = "v1"
        entry["%Name"] = ""
        entry["collisionObjectId"] = None
        entry["eventNum"] = event_num
        entry["eventType"] = event_type
        entry["isDnD"] = False
        entry["name"] = ""
        entry["resourceType"] = "GMEvent"
        entry["resourceVersion"] = "2.0"
        events_array = self.data["eventList"]
        position = len(events_array)
        for index, existing in enumerate(events_array):
            key = (int(existing.get("eventType", 0)), int(existing.get("eventNum", 0)))
            if key > (event_type, event_num):
                position = index
                break
        events_array.insert(position, entry)

    # -- script code ---------------------------------------------------------
    def script_path(self) -> Path:
        """Return the ``.gml`` path for a script resource."""
        return self.folder / f"{self.name}.gml"

    def read_script(self) -> str:
        """Return the source of a script resource."""
        return gml_mod.read_gml(self.script_path())

    def write_script(self, source: str) -> Path:
        """Overwrite a script resource's source."""
        return gml_mod.write_gml(self.script_path(), source)

    def functions(self) -> List[str]:
        """Return the function names defined by this resource's GML."""
        paths = [self.script_path()] if self.type == "GMScript" else self.gml_files()
        names: List[str] = []
        for path in paths:
            if path.exists():
                names.extend(gml_mod.function_names(gml_mod.read_gml(path)))
        return names

    def __repr__(self) -> str:  # pragma: no cover - convenience
        return f"<Resource {self.type} {self.name}>"


class Project:
    """A GameMaker Studio 2 project rooted at the folder containing the ``.yyp``."""

    def __init__(self, root: Optional[PathLike] = None) -> None:
        self.root = find_project_root(root if root is not None else ".")
        yyp_files = sorted(self.root.glob("*.yyp"))
        if not yyp_files:
            raise FileNotFoundError(f"no .yyp file in {self.root}")
        self.yyp_path = yyp_files[0]
        self._yyp = yy.Document.from_file(self.yyp_path)
        self._resources: Dict[str, Resource] = {}
        self._index_resources()

    # -- project data --------------------------------------------------------
    @property
    def data(self) -> Any:
        """The parsed ``.yyp`` contents."""
        return self._yyp.data

    def _index_resources(self) -> None:
        self._resources = {}
        for entry in self.data.get("resources", []):
            identifier = entry.get("id", {})
            name = identifier.get("name")
            path = identifier.get("path")
            if not name or not path:
                continue
            self._resources[name] = Resource(
                self, name, path, TYPE_BY_DIR.get(path.split("/", 1)[0], "GMUnknown")
            )

    def resource(self, name: str) -> Resource:
        """Return the resource called *name* (raises ``KeyError`` if absent)."""
        return self._resources[name]

    def resources(self, type: Optional[str] = None) -> List[Resource]:
        """Return all resources, optionally filtered by resource type."""
        items = sorted(self._resources.values(), key=lambda r: r.name.lower())
        if type is not None:
            items = [r for r in items if r.type == type]
        return items

    def find(self, pattern: str, type: Optional[str] = None) -> List[Resource]:
        """Return resources whose name contains *pattern* (case-insensitive)."""
        needle = pattern.lower()
        return [r for r in self.resources(type) if needle in r.name.lower()]

    def save(self) -> Path:
        """Write the ``.yyp`` back to disk, preserving formatting."""
        return self._yyp.save()

    # -- resource creation ---------------------------------------------------
    def create_script(self, name: str, source: Optional[str] = None) -> Resource:
        """Create a new script resource with an optional initial GML source."""
        if name in self._resources:
            raise FileExistsError(f"resource {name!r} already exists")
        folder = self.root / "scripts" / name
        folder.mkdir(parents=True, exist_ok=True)
        if source is None:
            source = f"/// @description {name}\nfunction {name}() {{\n\t\n}}\n"
        (folder / f"{name}.gml").write_bytes(source.encode("utf-8"))
        yy.dump(self._script_template(name), folder / f"{name}.yy")
        self._register(name, f"scripts/{name}/{name}.yy")
        return self.resource(name)

    def create_object(
        self,
        name: str,
        sprite: Optional[str] = None,
        parent_object: Optional[str] = None,
    ) -> Resource:
        """Create a new object resource, optionally with a sprite and parent."""
        if name in self._resources:
            raise FileExistsError(f"resource {name!r} already exists")
        folder = self.root / "objects" / name
        folder.mkdir(parents=True, exist_ok=True)
        yy.dump(self._object_template(name, sprite, parent_object), folder / f"{name}.yy")
        self._register(name, f"objects/{name}/{name}.yy")
        return self.resource(name)

    def _register(self, name: str, path: str) -> None:
        identifier = yy.GmObject(inline=True)
        identifier["name"] = name
        identifier["path"] = path
        entry = yy.GmObject(inline=True)
        entry["id"] = identifier
        self.data["resources"].append(entry)
        self.save()
        self._resources[name] = Resource(
            self, name, path, TYPE_BY_DIR.get(path.split("/", 1)[0], "GMUnknown")
        )

    @staticmethod
    def _reference(name: str, path: str, inline: bool = True) -> "yy.GmObject":
        ref = yy.GmObject(inline=inline)
        ref["name"] = name
        ref["path"] = path
        return ref

    def _script_template(self, name: str) -> "yy.GmObject":
        root = yy.GmObject(inline=False)
        for key, value in (
            ("$GMScript", "v1"),
            ("%Name", name),
            ("isCompatibility", False),
            ("isDnD", False),
            ("name", name),
            ("parent", self._reference("Scripts", "folders/Scripts.yy", inline=False)),
            ("resourceType", "GMScript"),
            ("resourceVersion", "2.0"),
        ):
            root[key] = value
        return yy.sort_keys(root)

    def _object_template(
        self, name: str, sprite: Optional[str], parent_object: Optional[str]
    ) -> "yy.GmObject":
        root = yy.GmObject(inline=False)
        root.update({
            "$GMObject": "",
            "%Name": name,
            "eventList": yy.GmArray(),
            "managed": True,
            "name": name,
            "overriddenProperties": yy.GmArray(),
            "parent": self._reference("Objects", "folders/Objects.yy", inline=False),
            "parentObjectId": None,
            "persistent": False,
            "physicsAngularDamping": 0.1,
            "physicsDensity": 0.5,
            "physicsFriction": 0.2,
            "physicsGroup": 0,
            "physicsKinematic": False,
            "physicsLinearDamping": 0.1,
            "physicsObject": False,
            "physicsRestitution": 0.1,
            "physicsSensor": False,
            "physicsShape": 0,
            "physicsShapePoints": yy.GmArray(),
            "physicsStartAwake": True,
            "properties": yy.GmArray(),
            "resourceType": "GMObject",
            "resourceVersion": "2.0",
            "solid": False,
            "spriteId": None,
            "spriteMaskId": None,
            "visible": True,
        })
        if sprite:
            root["spriteId"] = self._reference(sprite, f"sprites/{sprite}/{sprite}.yy")
        if parent_object:
            root["parentObjectId"] = self._reference(
                parent_object, f"objects/{parent_object}/{parent_object}.yy"
            )
        return yy.sort_keys(root)
