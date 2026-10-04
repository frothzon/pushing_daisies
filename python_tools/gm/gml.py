"""Reading, editing and writing GML source files while preserving formatting.

GameMaker stores GML as plain text.  The scripts in this repository use tab
indentation and *both* LF and CRLF line endings, so the helpers here never
reformat a file: they hand you the text and, when you save, write back exactly
the line endings and trailing newline the file had.

The higher level helpers locate and replace individual ``function`` blocks
without touching a single byte of the surrounding code, which keeps diffs
minimal.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path
from typing import List, Optional, Union

__all__ = [
    "GmlDocument",
    "Function",
    "read_gml",
    "write_gml",
    "detect_indent",
    "find_functions",
    "function_names",
    "get_function",
    "replace_function",
    "append_function",
    "indent_block",
]

PathLike = Union[str, "Path"]


class GmlDocument:
    """A GML file held in memory together with its exact layout.

    ``text`` is the file's contents (including its original line endings).  Any
    edit that keeps the line endings intact saves back byte-for-byte.
    """

    def __init__(self, text: str, path: Optional[PathLike] = None) -> None:
        self.text = text
        self.path = Path(path) if path is not None else None

    @classmethod
    def from_file(cls, path: PathLike) -> "GmlDocument":
        return cls(read_gml(path), path=path)

    def save(self, path: Optional[PathLike] = None) -> Path:
        target = Path(path) if path is not None else self.path
        if target is None:
            raise ValueError("no path given and GmlDocument has no path")
        write_gml(target, self.text)
        return target

    def functions(self) -> List["Function"]:
        """Return the functions defined in this file."""
        return find_functions(self.text)


def read_gml(path: PathLike) -> str:
    """Read *path* as UTF-8 text, preserving line endings."""
    return Path(path).read_bytes().decode("utf-8-sig")


def write_gml(path: PathLike, text: str) -> Path:
    """Write *text* to *path* as UTF-8 without altering line endings."""
    target = Path(path)
    target.write_bytes(text.encode("utf-8"))
    return target


def detect_indent(text: str, default: str = "\t") -> str:
    """Return the indentation string a GML file seems to use.

    Tabs win when any line starts with a tab; otherwise the most common run of
    leading spaces is used.  Falls back to *default*.
    """
    if re.search(r"(?m)^\t", text):
        return "\t"
    space_runs = re.findall(r"(?m)^( +)\S", text)
    if space_runs:
        return min(space_runs, key=len)
    return default


def indent_block(text: str, indent: str, base: str = "\t") -> str:
    """Re-indent *text* from *base* units to a single *indent* unit per level.

    Used when generating code whose relative indentation is already correct but
    whose indentation characters differ from the target file.
    """
    out_lines = []
    for line in text.split("\n"):
        stripped = line.lstrip()
        levels = 0
        remainder = line[: len(line) - len(stripped)]
        if base:
            levels = remainder.count(base) if base in remainder else 0
            if not levels and remainder:
                # fall back to counting two-space levels
                levels = len(remainder) // 2
        out_lines.append(indent * levels + stripped if stripped else "")
    return "\n".join(out_lines)


def _code_mask(text: str) -> bytearray:
    """Return a mask that is 1 for characters that are real code.

    Characters inside strings and comments (``//`` and ``/* */``) are 0, which
    lets the structural scanners ignore braces and parentheses there.
    """
    mask = bytearray(len(text))
    i = 0
    n = len(text)
    while i < n:
        char = text[i]
        if char == "/" and i + 1 < n and text[i + 1] == "/":
            newline = text.find("\n", i)
            i = n if newline == -1 else newline
        elif char == "/" and i + 1 < n and text[i + 1] == "*":
            end = text.find("*/", i + 2)
            i = n if end == -1 else end + 2
        elif char == '"':
            j = i + 1
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == '"':
                    break
                j += 1
            i = j + 1
        else:
            mask[i] = 1
            i += 1
    return mask


_FUNCTION_RE = re.compile(r"\bfunction\b[ \t]*([A-Za-z_]\w*)?[ \t]*\(")


@dataclass
class Function:
    """A ``function name(...) { ... }`` definition found in GML source."""

    name: str
    params: str
    start: int
    doc_start: int
    header_end: int
    body_end: int
    source: str

    @property
    def end(self) -> int:
        """Index just past the closing brace of the function body."""
        return self.body_end + 1

    @property
    def doc_source(self) -> str:
        return self.source

    def __str__(self) -> str:  # pragma: no cover - convenience
        return f"{self.name}({self.params})"


def _match_pair(text: str, mask: bytearray, open_index: int) -> int:
    """Return the index of the bracket matching ``text[open_index]``."""
    depth = 0
    i = open_index
    while i < len(text):
        if mask[i]:
            char = text[i]
            if char in "([{":
                depth += 1
            elif char in ")]}":
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    raise ValueError(f"unbalanced {text[open_index]!r} at {open_index}")


def _find_body_brace(text: str, mask: bytearray, start: int) -> int:
    """Find the ``{`` that opens a function body starting at *start*."""
    depth = 0
    i = start
    while i < len(text):
        if mask[i]:
            char = text[i]
            if char in "([":
                depth += 1
            elif char in ")]":
                depth -= 1
            elif char == "{" and depth == 0:
                return i
        i += 1
    raise ValueError("function body not found")


def _doc_start(text: str, code_start: int) -> int:
    """Return the index of the first preceding ``///`` doc-comment line."""
    pos = text.rfind("\n", 0, code_start) + 1
    while pos > 0:
        previous_end = pos - 1
        previous_start = text.rfind("\n", 0, previous_end) + 1
        line = text[previous_start:previous_end].rstrip("\r")
        if line.lstrip(" \t").startswith("///"):
            pos = previous_start
        else:
            break
    return pos


def find_functions(text: str) -> List[Function]:
    """Return every ``function`` definition in *text*, in source order."""
    mask = _code_mask(text)
    functions: List[Function] = []
    for match in _FUNCTION_RE.finditer(text):
        if not mask[match.start()]:
            continue
        open_paren = match.end() - 1
        close_paren = _match_pair(text, mask, open_paren)
        body_open = _find_body_brace(text, mask, close_paren + 1)
        body_end = _match_pair(text, mask, body_open)
        functions.append(
            Function(
                name=match.group(1) or "",
                params=text[open_paren + 1:close_paren],
                start=match.start(),
                doc_start=_doc_start(text, match.start()),
                header_end=body_open + 1,
                body_end=body_end,
                source=text[match.start():body_end + 1],
            )
        )
    return functions


def function_names(text: str) -> List[str]:
    """Return the names of all (named) functions defined in *text*."""
    return [f.name for f in find_functions(text) if f.name]


def get_function(text: str, name: str) -> Optional[Function]:
    """Return the :class:`Function` called *name*, or ``None``."""
    for function in find_functions(text):
        if function.name == name:
            return function
    return None


def replace_function(text: str, name: str, new_source: str) -> str:
    """Replace the body of the function *name* with *new_source*.

    Only the function's own text (from the ``function`` keyword through its
    closing brace) is replaced; surrounding code and any preceding ``///`` doc
    comment are preserved.
    """
    function = get_function(text, name)
    if function is None:
        raise KeyError(f"function {name!r} not found")
    return text[: function.start] + new_source + text[function.end:]


def append_function(text: str, new_source: str) -> str:
    """Append *new_source* as a new function, keeping the file's final newline."""
    if text and not text.endswith("\n"):
        text += "\n"
    if text:
        text += "\n"
    return text + new_source.rstrip("\n") + "\n"
