"""A PNG codec built on ``zlib`` alone, because this toolkit has no dependencies.

The art pass in :mod:`gm.art.pixels` rewrites every frame of a sprite, so it has
to decode and re-encode 8-bit PNGs exactly.  Pillow is not installed here, and
more importantly a second imaging library would be a second opinion about what
the file *is*: this module refuses anything it does not fully understand and
names the file instead, so a surprising image is reported rather than silently
re-encoded into something else (LL-009's rule, applied to pixels - the toolkit
writes the file, never a guess).

What is supported
-----------------
* 8 bits per channel, non-interlaced, all five row filters;
* colour types 0 (grey), 2 (RGB), 4 (grey + alpha) and 6 (RGBA).  Everything
  comes back as RGBA, because that is the only shape the pass reasons about;
* writing is 8-bit RGBA, filter 0, one ``IDAT``, ``zlib`` level 9.  Measured on
  a real frame that is 18 949 bytes against the 20 372 the art tool saved, so a
  round trip through here does not inflate the sprite folder.

Anything else - 16-bit, interlaced, paletted, truncated - raises
:class:`PngError` with the reason and the file name.

Why filter 0 on the way out
---------------------------
Filter 0 stores each row literally, which is the only encoding that cannot be
wrong, and these images are flat-shaded sprites with large single-colour
regions, so ``zlib`` still compresses them better than the art tool's adaptive
filtering did.  Speed is not a concern: this runs on an art pass, not per frame.
"""

from __future__ import annotations

import struct
import zlib
from pathlib import Path
from typing import Iterator, List, Tuple, Union

__all__ = ["PngError", "read_png", "read_png_bytes", "write_png", "MAGIC"]

#: The 8-byte PNG signature: 0x89, "PNG", CR, LF, 0x1A, LF.  Spelled as
#: numbers so that a line-ending check (`grep -cF`) does not report this file
#: as a CRLF accident just because the format's magic bytes look like one.
MAGIC = bytes((0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A))

#: colour type -> channels per pixel, for the types this module accepts.
CHANNELS = {0: 1, 2: 3, 4: 2, 6: 4}

PathLike = Union[str, Path]


class PngError(RuntimeError):
    """A PNG that cannot be read exactly.  Always names the file and the reason."""


def _chunks(data: bytes, label: str) -> Iterator[Tuple[bytes, bytes]]:
    """Walk the chunk list, yielding ``(kind, body)`` up to and including IEND."""
    if not data.startswith(MAGIC):
        raise PngError("%s: not a PNG (bad signature)" % label)
    pos = len(MAGIC)
    while True:
        if pos + 8 > len(data):
            raise PngError("%s: truncated PNG (no IEND chunk)" % label)
        length, kind = struct.unpack_from(">I4s", data, pos)
        body = data[pos + 8:pos + 8 + length]
        if len(body) != length:
            raise PngError("%s: truncated %s chunk (%d of %d bytes)"
                           % (label, kind.decode("ascii", "replace"), len(body), length))
        yield kind, body
        pos += 12 + length          # length + kind + body + crc
        if kind == b"IEND":
            return


def _paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c


def _unfilter(raw: bytes, width: int, height: int, bpp: int, label: str) -> bytes:
    """Undo the per-row filters, returning ``height * width * bpp`` bytes."""
    stride = width * bpp
    need = height * (stride + 1)
    if len(raw) != need:
        raise PngError("%s: image data is %d bytes, expected %d for %dx%d"
                       % (label, len(raw), need, width, height))
    out = bytearray(stride * height)
    prev = bytes(stride)
    pos = 0
    for y in range(height):
        kind = raw[pos]
        line = bytearray(raw[pos + 1:pos + 1 + stride])
        pos += stride + 1
        if kind == 0:
            pass
        elif kind == 1:
            for i in range(bpp, stride):
                line[i] = (line[i] + line[i - bpp]) & 0xFF
        elif kind == 2:
            for i in range(stride):
                line[i] = (line[i] + prev[i]) & 0xFF
        elif kind == 3:
            for i in range(stride):
                left = line[i - bpp] if i >= bpp else 0
                line[i] = (line[i] + ((left + prev[i]) >> 1)) & 0xFF
        elif kind == 4:
            for i in range(stride):
                left = line[i - bpp] if i >= bpp else 0
                upleft = prev[i - bpp] if i >= bpp else 0
                line[i] = (line[i] + _paeth(left, prev[i], upleft)) & 0xFF
        else:
            raise PngError("%s: unknown row filter %d on row %d" % (label, kind, y))
        out[y * stride:(y + 1) * stride] = line
        prev = bytes(line)
    return bytes(out)


def _to_rgba(raw: bytes, width: int, height: int, colour_type: int) -> bytes:
    """Expand grey / RGB / grey+alpha to RGBA.  RGBA is returned untouched."""
    pixels = width * height
    if colour_type == 6:
        return raw
    out = bytearray(pixels * 4)
    if colour_type == 0:
        for p in range(pixels):
            g = raw[p]
            out[p * 4] = out[p * 4 + 1] = out[p * 4 + 2] = g
            out[p * 4 + 3] = 255
    elif colour_type == 4:
        for p in range(pixels):
            g = raw[p * 2]
            out[p * 4] = out[p * 4 + 1] = out[p * 4 + 2] = g
            out[p * 4 + 3] = raw[p * 2 + 1]
    else:                                   # colour type 2
        for p in range(pixels):
            out[p * 4] = raw[p * 3]
            out[p * 4 + 1] = raw[p * 3 + 1]
            out[p * 4 + 2] = raw[p * 3 + 2]
            out[p * 4 + 3] = 255
    return bytes(out)

    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    if pb <= pc:
        return b
    return c



def read_png_bytes(data: bytes, label: str = "<bytes>") -> Tuple[int, int, bytes]:
    """Decode PNG *data* to ``(width, height, rgba)``."""
    header = None
    palette = False
    idat: List[bytes] = []
    for kind, body in _chunks(data, label):
        if kind == b"IHDR":
            if len(body) != 13:
                raise PngError("%s: IHDR is %d bytes, expected 13" % (label, len(body)))
            header = struct.unpack(">IIBBBBB", body)
        elif kind == b"PLTE":
            palette = True
        elif kind == b"IDAT":
            idat.append(body)
        elif kind == b"IEND":
            break
    if header is None:
        raise PngError("%s: no IHDR chunk" % label)

    width, height, depth, colour_type, compression, filtering, interlace = header
    if depth != 8:
        raise PngError("%s: %d bits per channel, only 8 is supported" % (label, depth))
    if interlace:
        raise PngError("%s: interlaced PNGs (Adam7) are not supported" % label)
    if colour_type not in CHANNELS:
        if colour_type == 3 or palette:
            raise PngError("%s: paletted PNGs are not supported" % label)
        raise PngError("%s: colour type %d is not supported" % (label, colour_type))
    if compression != 0 or filtering != 0:
        raise PngError("%s: unknown compression/filter method (%d/%d)"
                       % (label, compression, filtering))
    if width <= 0 or height <= 0:
        raise PngError("%s: %dx%d is not a picture" % (label, width, height))
    if not idat:
        raise PngError("%s: no IDAT chunk (no pixels)" % label)

    try:
        raw = zlib.decompress(b"".join(idat))
    except zlib.error as err:
        raise PngError("%s: image data does not decompress (%s)" % (label, err))

    bpp = CHANNELS[colour_type]
    planes = _unfilter(raw, width, height, bpp, label)
    return width, height, _to_rgba(planes, width, height, colour_type)


def read_png(path: PathLike) -> Tuple[int, int, bytes]:
    """Decode the PNG at *path* to ``(width, height, rgba)``."""
    path = Path(path)
    try:
        data = path.read_bytes()
    except OSError as err:
        raise PngError("%s: %s" % (path, err))
    return read_png_bytes(data, str(path))


def write_png(path: PathLike, width: int, height: int, rgba: bytes) -> Path:
    """Write *rgba* as an 8-bit RGBA PNG, atomically, and return the path."""
    expected = width * height * 4
    if len(rgba) != expected:
        raise PngError("%s: %d bytes of pixels for %dx%d, expected %d"
                       % (path, len(rgba), width, height, expected))
    if width <= 0 or height <= 0:
        raise PngError("%s: %dx%d is not a picture" % (path, width, height))

    stride = width * 4
    raw = bytearray()
    for y in range(height):
        raw.append(0)                       # filter 0: the row as it is
        raw += rgba[y * stride:(y + 1) * stride]

    def chunk(kind: bytes, body: bytes) -> bytes:
        return (struct.pack(">I", len(body)) + kind + body
                + struct.pack(">I", zlib.crc32(kind + body) & 0xFFFFFFFF))

    blob = b"".join([
        MAGIC,
        chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)),
        chunk(b"IDAT", zlib.compress(bytes(raw), 9)),
        chunk(b"IEND", b""),
    ])

    path = Path(path)
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_bytes(blob)
    tmp.replace(path)                       # never leave a half-written frame
    return path

    try:
        data = path.read_bytes()
    except OSError as err:
        raise PngError("%s: %s" % (path, err))
    return read_png_bytes(data, str(path))
