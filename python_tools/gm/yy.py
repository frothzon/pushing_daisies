"""Byte-exact reader/writer for GameMaker Studio 2 ``.yy`` / ``.yyp`` files.

GameMaker does not emit its "resources" JSON as plain JSON.  Its dialect
differs from the standard in several ways:

* every object member and every array element is followed by a trailing comma
  (even the last one)::

      {
        "name": "obj_player",
        "eventList": [
          {"eventType": 0, "eventNum": 0,},
        ],
      }

* object keys are ordered case-insensitively, with ``_`` sorting *after*
  letters (so ``bboxMode`` comes before ``bbox_bottom``);
* whether a nested object/array is written on one line ("inline") or spread
  across several lines depends on the resource schema and does not follow a
  simple rule -- so this module simply remembers the layout it read and
  reproduces it;
* files use LF line endings and contain no trailing newline.

The reader returns :class:`GmObject` / :class:`GmArray` containers.  They behave
exactly like ``dict`` / ``list`` (so ordinary code keeps working) but carry an
``inline`` flag describing how the container was formatted on disk.  Together
with the preserved key order this makes an unmodified file round-trip **byte
for byte**, so editing a single value produces a one-line diff instead of a
whole-file reformat.

Only the standard library is used.
"""

from __future__ import annotations

import json as _json
import re
from pathlib import Path
from typing import Any, Iterator, Optional, Tuple, Union

__all__ = [
    "GmJsonError",
    "GmObject",
    "GmArray",
    "INDENT",
    "loads",
    "load",
    "load_document",
    "dumps",
    "dump",
    "strip_trailing_commas",
    "gm_sort_key",
    "sort_keys",
    "Document",
]

INDENT = "  "
"""One level of indentation, matching GameMaker's two-space style."""

PathLike = Union[str, "Path"]
_WS = " \t\r\n"
_NUMBER_RE = re.compile(r"-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?")
_UNESCAPE = {
    '"': '"', "\\": "\\", "/": "/", "b": "\b", "f": "\f",
    "n": "\n", "r": "\r", "t": "\t",
}
_TRAILING_COMMA_RE = re.compile(r",(\s*[}\]])")


class GmJsonError(ValueError):
    """Raised when a ``.yy`` file cannot be parsed."""


class GmObject(dict):
    """A ``dict`` that remembers whether GameMaker wrote it on a single line."""

    __slots__ = ("inline",)

    def __init__(self, *args: Any, inline: bool = False, **kwargs: Any) -> None:
        super().__init__(*args, **kwargs)
        self.inline = inline


class GmArray(list):
    """A ``list`` that remembers whether GameMaker wrote it on a single line."""

    __slots__ = ("inline",)

    def __init__(self, *args: Any, inline: bool = False) -> None:
        super().__init__(*args)
        self.inline = inline


def strip_trailing_commas(text: str) -> str:
    """Return *text* with GameMaker's trailing commas removed.

    The substitution only removes a comma that is immediately followed by
    (optional whitespace and) a closing ``}`` or ``]``, so commas inside
    strings are never touched.  Handy for feeding GameMaker JSON to the
    standard :mod:`json` module.
    """
    return _TRAILING_COMMA_RE.sub(r"\1", text)


class _Parser:
    """A small tolerant parser for the GameMaker JSON dialect."""

    def __init__(self, text: str) -> None:
        self.text = text
        self.pos = 0
        self.length = len(text)

    def parse(self) -> Any:
        self._ws()
        value = self._value()
        self._ws()
        if self.pos != self.length:
            raise GmJsonError(f"trailing data at offset {self.pos}")
        return value

    def _ws(self) -> None:
        while self.pos < self.length and self.text[self.pos] in _WS:
            self.pos += 1

    def _error(self, message: str) -> "GmJsonError":
        return GmJsonError(f"{message} at offset {self.pos}")

    def _skip_string(self, start: int) -> int:
        i = start + 1
        while i < self.length:
            char = self.text[i]
            if char == "\\":
                i += 2
                continue
            if char == '"':
                return i + 1
            i += 1
        raise GmJsonError("unterminated string")

    def _has_newline(self) -> bool:
        """Return True if a newline occurs at this container's own top level."""
        depth = 0
        i = self.pos
        while i < self.length:
            char = self.text[i]
            if char == '"':
                i = self._skip_string(i)
                continue
            if char in "{[":
                depth += 1
            elif char in "}]":
                if depth == 0:
                    break
                depth -= 1
            elif char == "\n" and depth == 0:
                return True
            i += 1
        return False

    def _value(self) -> Any:
        char = self.text[self.pos]
        if char == "{":
            return self._object()
        if char == "[":
            return self._array()
        if char == '"':
            return self._string()
        match = _NUMBER_RE.match(self.text, self.pos)
        if match:
            token = match.group(0)
            self.pos = match.end()
            if "." in token or "e" in token or "E" in token:
                return float(token)
            return int(token)
        word = self.text[self.pos:self.pos + 5]
        for literal, value in (("true", True), ("false", False), ("null", None)):
            if word.startswith(literal):
                self.pos += len(literal)
                return value
        raise self._error(f"unexpected {char!r}")

    def _string(self) -> str:
        text = self.text
        i = self.pos + 1
        parts = []
        start = i
        while i < self.length:
            char = text[i]
            if char == '"':
                parts.append(text[start:i])
                self.pos = i + 1
                return "".join(parts)
            if char == "\\":
                parts.append(text[start:i])
                escape = text[i + 1]
                if escape == "u":
                    parts.append(chr(int(text[i + 2:i + 6], 16)))
                    i += 6
                else:
                    parts.append(_UNESCAPE.get(escape, escape))
                    i += 2
                start = i
                continue
            i += 1
        raise GmJsonError("unterminated string")

    def _object(self) -> "GmObject":
        self.pos += 1  # consume '{'
        obj = GmObject(inline=not self._has_newline())
        self._ws()
        if self.text[self.pos] == "}":
            self.pos += 1
            return obj
        while True:
            self._ws()
            if self.text[self.pos] == "}":  # trailing comma before close
                self.pos += 1
                return obj
            key = self._string()
            self._ws()
            if self.text[self.pos] != ":":
                raise self._error("expected ':'")
            self.pos += 1
            self._ws()
            obj[key] = self._value()
            self._ws()
            char = self.text[self.pos]
            if char == ",":
                self.pos += 1
                continue
            if char == "}":
                self.pos += 1
                return obj
            raise self._error("expected ',' or '}'")

    def _array(self) -> "GmArray":
        self.pos += 1  # consume '['
        arr = GmArray(inline=not self._has_newline())
        self._ws()
        if self.text[self.pos] == "]":
            self.pos += 1
            return arr
        while True:
            self._ws()
            if self.text[self.pos] == "]":  # trailing comma before close
                self.pos += 1
                return arr
            arr.append(self._value())
            self._ws()
            char = self.text[self.pos]
            if char == ",":
                self.pos += 1
                continue
            if char == "]":
                self.pos += 1
                return arr
            raise self._error("expected ',' or ']'")


def loads(text: str) -> Any:
    """Parse GameMaker JSON *text* into :class:`GmObject` / :class:`GmArray`."""
    return _Parser(text).parse()


def load(path: PathLike) -> Any:
    """Parse the GameMaker JSON file at *path* and return its data."""
    return loads(_read_text(path))


def gm_sort_key(key: str) -> str:
    """Return the sort key GameMaker uses to order object members.

    GameMaker compares keys case-insensitively but sorts ``_`` after letters,
    so ``bboxMode`` precedes ``bbox_bottom``.  Mapping ``_`` to a very high
    code point reproduces that ordering.
    """
    return str(key).lower().replace("_", "\uffff")


def _inline_default(value: Any) -> bool:
    """Guess the inline style for plain dict/list values that lack a flag."""
    if isinstance(value, dict):
        return not any(
            isinstance(child, (dict, list)) and len(child) for child in value.values()
        )
    # GameMaker expands every non-empty array.
    return len(value) == 0


def _sorted_items(value: dict) -> Iterator[Tuple[Any, Any]]:
    return iter(sorted(value.items(), key=lambda kv: gm_sort_key(kv[0])))


def dumps(obj: Any, sort: bool = False) -> str:
    """Serialise *obj* to GameMaker JSON text.

    With *sort* false (the default) dict keys are emitted in their current
    order and every container keeps the layout it was parsed with, so a value
    loaded with :func:`loads` and written with :func:`dumps` is identical to
    the original.  Pass ``sort=True`` to re-order keys the way the IDE would.
    """
    out: list[str] = []
    _write(obj, 0, out, sort)
    return "".join(out)


def _write(value: Any, level: int, out: list[str], sort: bool) -> None:
    pad = INDENT * level
    if isinstance(value, dict):
        items = list(_sorted_items(value) if sort else value.items())
        if not items:
            out.append("{}")
            return
        inline = getattr(value, "inline", None)
        if inline is None:
            inline = _inline_default(value)
        if inline:
            out.append("{")
            for key, child in items:
                out.append(_json.dumps(str(key), ensure_ascii=False))
                out.append(":")
                _write(child, level + 1, out, sort)
                out.append(",")
            out.append("}")
        else:
            out.append("{\n")
            for key, child in items:
                out.append(INDENT * (level + 1))
                out.append(_json.dumps(str(key), ensure_ascii=False))
                out.append(":")
                _write(child, level + 1, out, sort)
                out.append(",\n")
            out.append(pad)
            out.append("}")
    elif isinstance(value, (list, tuple)):
        if not value:
            out.append("[]")
            return
        inline = getattr(value, "inline", None)
        if inline is None:
            inline = _inline_default(value)
        if inline:
            out.append("[")
            for child in value:
                _write(child, level + 1, out, sort)
                out.append(",")
            out.append("]")
        else:
            out.append("[\n")
            for child in value:
                out.append(INDENT * (level + 1))
                _write(child, level + 1, out, sort)
                out.append(",\n")
            out.append(pad)
            out.append("]")
    else:
        out.append(_scalar(value))


def _scalar(value: Any) -> str:
    if value is None:
        return "null"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        # ``repr`` yields the shortest round-tripping form; GameMaker always
        # writes a decimal point for integral reals (1.0 rather than 1).
        return repr(value)
    if isinstance(value, str):
        return _json.dumps(value, ensure_ascii=False)
    raise TypeError(f"cannot serialise {type(value).__name__} to GameMaker JSON")


def _read_text(path: PathLike) -> str:
    return Path(path).read_bytes().decode("utf-8-sig")


def sort_keys(obj: Any) -> Any:
    """Return *obj* recursively with every dict reordered like GameMaker would.

    Containers keep their inline style.  Dicts whose keys are all decimal
    integers (font glyph tables) are left in their current order.
    """
    if isinstance(obj, dict):
        keys = list(obj.keys())
        if keys and all(isinstance(k, str) and k.isdigit() for k in keys):
            ordered = keys
        else:
            ordered = sorted(keys, key=gm_sort_key)
        result = GmObject(inline=getattr(obj, "inline", _inline_default(obj)))
        for key in ordered:
            result[key] = sort_keys(obj[key])
        return result
    if isinstance(obj, list):
        result = GmArray(inline=getattr(obj, "inline", _inline_default(obj)))
        result.extend(sort_keys(v) for v in obj)
        return result
    return obj


class Document:
    """A GameMaker JSON file loaded into memory, remembering its exact layout.

    ``Document`` keeps the line ending and trailing whitespace of the file it
    was read from so :meth:`save` can write it back without introducing spurious
    diffs.  ``data`` is an ordinary dict/list (a :class:`GmObject` /
    :class:`GmArray`) that you can mutate freely.
    """

    def __init__(
        self,
        data: Any,
        path: Optional[PathLike] = None,
        eol: str = "\n",
        trailing: str = "",
        sort: bool = False,
    ) -> None:
        self.data = data
        self.path = Path(path) if path is not None else None
        self.eol = eol
        self.trailing = trailing
        self.sort = sort

    @classmethod
    def from_text(cls, text: str, path: Optional[PathLike] = None) -> "Document":
        eol = "\r\n" if "\r\n" in text else "\n"
        trailing = re.search(r"[ \t\r\n]*\Z", text).group(0)
        return cls(loads(text), path=path, eol=eol, trailing=trailing)

    @classmethod
    def from_file(cls, path: PathLike) -> "Document":
        return cls.from_text(_read_text(path), path=path)

    def dumps(self, sort: Optional[bool] = None) -> str:
        use_sort = self.sort if sort is None else sort
        text = dumps(self.data, sort=use_sort)
        if self.eol != "\n":
            text = text.replace("\n", self.eol)
        return text + self.trailing

    def save(self, path: Optional[PathLike] = None, sort: Optional[bool] = None) -> Path:
        target = Path(path) if path is not None else self.path
        if target is None:
            raise ValueError("no path given and Document has no path")
        target.write_bytes(self.dumps(sort=sort).encode("utf-8"))
        return target


def dump(
    obj: Any,
    path: PathLike,
    sort: bool = False,
    eol: str = "\n",
    trailing: str = "",
) -> Path:
    """Write *obj* to *path* in GameMaker JSON format."""
    text = dumps(obj, sort=sort)
    if eol != "\n":
        text = text.replace("\n", eol)
    target = Path(path)
    target.write_bytes((text + trailing).encode("utf-8"))
    return target


def load_document(path: PathLike) -> Document:
    """Read the GameMaker JSON file at *path* into a :class:`Document`."""
    return Document.from_file(path)
