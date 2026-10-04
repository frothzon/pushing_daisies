"""Tools for reading, writing and editing GameMaker Studio 2 project files.

The package is standard-library only.  The entry points are:

* :mod:`gm.yy` -- byte-exact ``.yy`` / ``.yyp`` reader & writer.
* :mod:`gm.gml` -- GML reader, writer and function-level editor.
* :mod:`gm.events` -- object event name/code helpers.
* :mod:`gm.project` -- :class:`Project` / :class:`Resource` high level API.

The quickest way to explore is the command line::

    python -m gm list objects
    python -m gm get-path spr_flower origin
    python -m gm roundtrip
"""

from . import events, gml, project, yy
from .events import (
    EVENT_TYPE_IDS,
    EVENT_TYPE_NAMES,
    event_filename,
    event_label,
    parse_event_filename,
)
from .gml import (
    Function,
    GmlDocument,
    detect_indent,
    find_functions,
    function_names,
    get_function,
    read_gml,
    replace_function,
    write_gml,
)
from .project import (
    Project,
    Resource,
    del_path,
    find_project_root,
    get_path,
    parse_keypath,
    set_path,
)
from .yy import (
    Document,
    GmArray,
    GmJsonError,
    GmObject,
    dump,
    dumps,
    load,
    load_document,
    loads,
)

__version__ = "1.0.0"

__all__ = [
    "yy",
    "gml",
    "events",
    "project",
    "Document",
    "GmObject",
    "GmArray",
    "GmJsonError",
    "dumps",
    "loads",
    "dump",
    "load",
    "load_document",
    "GmlDocument",
    "Function",
    "read_gml",
    "write_gml",
    "detect_indent",
    "find_functions",
    "function_names",
    "get_function",
    "replace_function",
    "Project",
    "Resource",
    "find_project_root",
    "parse_keypath",
    "get_path",
    "set_path",
    "del_path",
    "event_filename",
    "parse_event_filename",
    "event_label",
    "EVENT_TYPE_NAMES",
    "EVENT_TYPE_IDS",
]
