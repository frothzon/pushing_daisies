"""Tests for the art pass: the arithmetic, the PNG codec, and the files it writes.

The numbers are pinned to pictures built in the test, not to the sprite folder,
so a failure says *which rule* broke rather than "the art moved".  The rules
worth pinning are the ones a reviewer would otherwise have to take on trust:

* 127 is out, 128 is in - the 50 % coverage contour, and the exact pixel where
  the silhouette would otherwise quietly fatten or thin;
* the contour is a 4-neighbour contour, so a diagonal gap is not an edge;
* the stroke never grows the silhouette (that is what lets the pass leave every
  ``.yy`` alone);
* the pass is idempotent, because it will be run again on the next art drop;
* both copies of a frame are written from one buffer, because a sprite whose
  root and layer PNGs disagree looks fixed in the editor and soft in game.
"""

import struct
import sys
import tempfile
import unittest
import zlib
from pathlib import Path

TESTS_DIR = Path(__file__).resolve().parent
TOOLS_DIR = TESTS_DIR.parent
REPO_ROOT = TOOLS_DIR.parent
sys.path.insert(0, str(TOOLS_DIR))

from gm.art import clean, pixels, png, report, sprites  # noqa: E402


# -- helpers ----------------------------------------------------------------
def blank(width, height, colour=(0, 0, 0, 0)):
    """A canvas of one colour, as bytes."""
    return bytes(colour) * (width * height)


def paint(rgba, width, pixels_at, colour):
    """Return a copy of *rgba* with each ``(x, y)`` in *pixels_at* set to *colour*."""
    out = bytearray(rgba)
    for x, y in pixels_at:
        i = (y * width + x) * 4
        out[i:i + 4] = bytes(colour)
    return bytes(out)


def pixel(rgba, width, x, y):
    """The ``(r, g, b, a)`` at ``(x, y)``."""
    i = (y * width + x) * 4
    return tuple(rgba[i:i + 4])


def block(x0, y0, x1, y1):
    """Every pixel coordinate in the inclusive rectangle."""
    return [(x, y) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)]


INK = (0, 0, 0, 255)


def write_png(path, rows, colour_type=6, filter_type=0):
    """Write an 8-bit PNG from ``rows`` of channel tuples (no dependency)."""
    height, width = len(rows), len(rows[0])
    channels = {0: 1, 2: 3, 4: 2, 6: 4}[colour_type]
    raw = bytearray()
    for row in rows:
        payload = bytearray()
        for one in row:
            payload.extend(one)
        raw.append(filter_type)
        if filter_type == 0:
            raw.extend(payload)
        elif filter_type == 1:          # Sub: each byte minus the one `channels` back
            for x in range(len(payload)):
                left = payload[x - channels] if x >= channels else 0
                raw.append((payload[x] - left) & 0xFF)
        else:                           # pragma: no cover - only 0 and 1 are used
            raise AssertionError("unsupported filter %r" % (filter_type,))
    ihdr = struct.pack(">IIBBBBB", width, height, 8, colour_type, 0, 0, 0)

    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF))

    path.write_bytes(png.MAGIC + chunk(b"IHDR", ihdr)
                     + chunk(b"IDAT", zlib.compress(bytes(raw))) + chunk(b"IEND", b""))
    return path


def find_project_root():
    for candidate in [REPO_ROOT, *REPO_ROOT.parents]:
        if any(candidate.glob("*.yyp")):
            return candidate
    return None


PROJECT_ROOT = find_project_root()


class BinarizeTest(unittest.TestCase):
    """The threshold, and what happens to the pixels that fall below it."""

    def test_half_coverage_is_opaque(self):
        rgba = blank(2, 1)
        rgba = paint(rgba, 2, [(0, 0)], (10, 20, 30, 128))
        out, partial = pixels.binarize(rgba)
        self.assertEqual(pixel(out, 2, 0, 0), (10, 20, 30, 255))
        self.assertEqual(partial, 1)

    def test_just_below_half_is_dropped(self):
        rgba = paint(blank(2, 1), 2, [(0, 0)], (10, 20, 30, 127))
        out, partial = pixels.binarize(rgba)
        self.assertEqual(pixel(out, 2, 0, 0), (0, 0, 0, 0))
        self.assertEqual(partial, 1)

    def test_transparent_pixels_lose_their_colour(self):
        """A halo pixel's colour is what bilinear sampling drags into the edge."""
        rgba = paint(blank(2, 1), 2, [(0, 0)], (200, 10, 10, 0))
        out, partial = pixels.binarize(rgba)
        self.assertEqual(pixel(out, 2, 0, 0), (0, 0, 0, 0))
        self.assertEqual(partial, 0)

    def test_only_fractional_alpha_counts_as_partial(self):
        rgba = blank(3, 1)
        rgba = paint(rgba, 3, [(0, 0)], (1, 2, 3, 255))
        rgba = paint(rgba, 3, [(1, 0)], (4, 5, 6, 200))
        rgba = paint(rgba, 3, [(2, 0)], (7, 8, 9, 0))
        _, partial = pixels.binarize(rgba)
        self.assertEqual(partial, 1)

    def test_a_bad_threshold_is_refused(self):
        for bad in (0, -1, 256):
            with self.assertRaises(ValueError):
                pixels.binarize(blank(1, 1), bad)

    def test_already_clean_input_is_unchanged(self):
        rgba = paint(blank(2, 2), 2, [(0, 0), (1, 1)], (9, 9, 9, 255))
        out, partial = pixels.binarize(rgba)
        self.assertEqual(out, rgba)
        self.assertEqual(partial, 0)


class OutlineTest(unittest.TestCase):
    """Where the ring goes, and - more importantly - where it does not."""

    def test_contour_is_inked(self):
        rgba = paint(blank(7, 7), 7, block(2, 2, 4, 4), (120, 90, 60, 255))
        out, painted = pixels.inner_outline(rgba, 7, 7)
        self.assertEqual(pixel(out, 7, 2, 2), INK)        # corner of the block
        self.assertEqual(pixel(out, 7, 3, 3), (120, 90, 60, 255))
        self.assertEqual(painted, 8)                      # 3x3 block: 8 ring pixels
        self.assertEqual(pixel(out, 7, 1, 1), (0, 0, 0, 0))   # nothing outside

    def test_the_silhouette_does_not_grow(self):
        """The reason no .yy has to change: same canvas, same opaque pixels."""
        rgba = paint(blank(9, 9), 9, block(2, 2, 6, 6), (1, 2, 3, 255))
        out, _ = pixels.inner_outline(rgba, 9, 9)
        self.assertEqual(len(out), len(rgba))
        self.assertEqual(pixels.opaque_mask(out), pixels.opaque_mask(rgba))

    def test_a_diagonal_gap_is_not_a_contour(self):
        """A plus has transparent corners around its centre; the centre is interior."""
        shape = [(3, 3), (2, 3), (4, 3), (3, 2), (3, 4)]
        rgba = paint(blank(7, 7), 7, shape, (50, 60, 70, 255))
        out, _ = pixels.inner_outline(rgba, 7, 7)
        self.assertEqual(pixel(out, 7, 3, 3), (50, 60, 70, 255))
        self.assertEqual(pixel(out, 7, 3, 2), INK)

    def test_a_hole_is_inked(self):
        """The gap between an arm and a torso is a contour like any other."""
        rgba = paint(blank(7, 7), 7, block(1, 1, 5, 5), (5, 5, 5, 255))
        rgba = paint(rgba, 7, [(3, 3)], (0, 0, 0, 0))
        out, painted = pixels.inner_outline(rgba, 7, 7)
        for x, y in [(2, 3), (4, 3), (3, 2), (3, 4)]:
            self.assertEqual(pixel(out, 7, x, y), INK)
        self.assertEqual(pixel(out, 7, 3, 3), (0, 0, 0, 0))
        self.assertEqual(painted, 20)     # 16 round the block + 4 round the hole

    def test_two_pixel_stroke_goes_behind_the_first(self):
        rgba = paint(blank(9, 9), 9, block(3, 3, 5, 5), (5, 5, 5, 255))
        one, _ = pixels.inner_outline(rgba, 9, 9, stroke=1)
        two, painted = pixels.inner_outline(rgba, 9, 9, stroke=2)
        self.assertEqual(pixel(one, 9, 4, 4), (5, 5, 5, 255))
        self.assertEqual(pixel(two, 9, 4, 4), INK)
        self.assertEqual(painted, 9)      # the whole 3x3 block, in two rings

    def test_it_is_idempotent(self):
        """The next art drop will run this again over the same files."""
        rgba = paint(blank(11, 11), 11, block(2, 2, 8, 8), (90, 20, 20, 255))
        snapped, _ = pixels.binarize(rgba)
        once, first = pixels.inner_outline(snapped, 11, 11)
        twice, second = pixels.inner_outline(once, 11, 11)
        self.assertEqual(once, twice)
        self.assertEqual(first, 24)       # the 7x7 block's perimeter
        self.assertEqual(second, 0)       # nothing left to change

    def test_an_empty_frame_is_left_alone(self):
        out, painted = pixels.inner_outline(blank(4, 4), 4, 4)
        self.assertEqual(painted, 0)
        self.assertEqual(out, blank(4, 4))

    def test_a_wrong_sized_buffer_is_refused(self):
        with self.assertRaises(ValueError):
            pixels.inner_outline(blank(4, 4), 5, 4)


class NarrowTest(unittest.TestCase):
    """The warning that stops a 1 px tendril quietly disappearing."""

    def test_a_one_pixel_chain_is_flagged(self):
        rgba = paint(blank(6, 6), 6, [(2, 1), (2, 2), (2, 3)], (9, 9, 9, 255))
        mask = pixels.opaque_mask(rgba)
        self.assertEqual(pixels.narrow_components(mask, 6, 6), 1)

    def test_a_solid_block_is_not_flagged(self):
        rgba = paint(blank(9, 9), 9, block(2, 2, 6, 6), (9, 9, 9, 255))
        mask = pixels.opaque_mask(rgba)
        self.assertEqual(pixels.narrow_components(mask, 9, 9), 0)

    def test_two_islands_are_two_components(self):
        rgba = paint(blank(9, 9), 9, [(1, 1), (1, 2), (7, 7), (7, 8)], (9, 9, 9, 255))
        mask = pixels.opaque_mask(rgba)
        self.assertEqual(pixels.narrow_components(mask, 9, 9), 2)

    def test_a_diagonal_step_is_not_a_speck(self):
        """A pixel contour steps diagonally constantly; those are meant to be inked."""
        rgba = paint(blank(9, 9), 9, block(2, 2, 4, 4), (9, 9, 9, 255))
        rgba = paint(rgba, 9, [(5, 5)], (9, 9, 9, 255))   # a step off the corner
        mask = pixels.opaque_mask(rgba)
        self.assertEqual(pixels.narrow_components(mask, 9, 9), 0)

    def test_a_lonely_pixel_is_a_speck(self):
        rgba = paint(blank(9, 9), 9, block(1, 1, 4, 4), (9, 9, 9, 255))
        rgba = paint(rgba, 9, [(8, 8)], (9, 9, 9, 255))
        mask = pixels.opaque_mask(rgba)
        self.assertEqual(pixels.narrow_components(mask, 9, 9), 1)


class ProblemsTest(unittest.TestCase):
    """What ``check`` refuses, and the coordinates it gives you."""

    def test_fractional_alpha_is_a_problem(self):
        rgba = paint(blank(3, 2), 3, [(1, 0)], (5, 5, 5, 200))
        found = pixels.problems(rgba, 3, 2)
        self.assertEqual(len(found), 1)
        self.assertIn("partially transparent", found[0])
        self.assertIn("1,0", found[0])

    def test_colour_in_a_transparent_pixel_is_a_problem(self):
        rgba = paint(blank(5, 5), 5, block(1, 1, 3, 3), (0, 0, 0, 255))
        rgba = paint(rgba, 5, [(4, 4)], (200, 0, 0, 0))
        found = pixels.problems(rgba, 5, 5)
        self.assertEqual(len(found), 1)
        self.assertIn("still carry a colour", found[0])

    def test_a_soft_contour_is_a_problem(self):
        rgba = paint(blank(5, 5), 5, block(1, 1, 1, 3), (60, 60, 60, 255))
        found = pixels.problems(rgba, 5, 5)
        self.assertEqual(len(found), 1)
        self.assertIn("not (0,0,0,255)", found[0])
        self.assertEqual(pixels.problems(rgba, 5, 5, require_ink=False), [])

    def test_a_clean_frame_has_no_problems(self):
        rgba = paint(blank(7, 7), 7, block(2, 2, 4, 4), (60, 120, 60, 255))
        out, _ = pixels.inner_outline(*pixels.binarize(rgba)[:1], 7, 7)
        self.assertEqual(pixels.problems(out, 7, 7), [])

    def test_an_empty_frame_is_a_problem(self):
        self.assertIn("empty", " ".join(pixels.problems(blank(2, 2), 2, 2)))


class PngTest(unittest.TestCase):
    """The codec: it round-trips, it expands, and it refuses what it cannot read."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_roundtrip_preserves_every_byte_of_pixels(self):
        width, height = 4, 3
        rgba = b"".join(bytes(one) for one in
                        [(x * 7 % 256, y * 11 % 256, (x + y) * 3 % 256,
                          255 if (x + y) % 3 else 0)
                         for y in range(height) for x in range(width)])
        path = png.write_png(self.dir / "a.png", width, height, rgba)
        self.assertEqual(png.read_png(path), (width, height, rgba))

    def test_a_sub_filtered_png_is_decoded(self):
        rows = [[(10, 20, 30, 255), (40, 50, 60, 255), (70, 80, 90, 128)],
                [(1, 2, 3, 0), (4, 5, 6, 255), (7, 8, 9, 255)]]
        path = write_png(self.dir / "sub.png", rows, filter_type=1)
        width, height, rgba = png.read_png(path)
        self.assertEqual((width, height), (3, 2))
        self.assertEqual(rgba, b"".join(bytes(one) for row in rows for one in row))

    def test_grey_and_rgb_are_expanded_to_rgba(self):
        grey = write_png(self.dir / "g.png", [[(90,), (180,)]], colour_type=0)
        self.assertEqual(png.read_png(grey)[2], bytes((90, 90, 90, 255, 180, 180, 180, 255)))
        rgb = write_png(self.dir / "rgb.png", [[(1, 2, 3), (4, 5, 6)]], colour_type=2)
        self.assertEqual(png.read_png(rgb)[2], bytes((1, 2, 3, 255, 4, 5, 6, 255)))

    def test_a_non_png_is_refused_by_name(self):
        path = self.dir / "nope.png"
        path.write_bytes(b"GIF89a and then some")
        with self.assertRaises(png.PngError) as caught:
            png.read_png(path)
        self.assertIn("nope.png", str(caught.exception))

    def test_sixteen_bit_is_refused_rather_than_guessed(self):
        def chunk(kind, data):
            return (struct.pack(">I", len(data)) + kind + data
                    + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF))
        blob = (png.MAGIC
                + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 16, 6, 0, 0, 0))
                + chunk(b"IDAT", zlib.compress(b"\0" * 8))
                + chunk(b"IEND", b""))
        with self.assertRaises(png.PngError) as caught:
            png.read_png_bytes(blob, "deep.png")
        self.assertIn("16 bits", str(caught.exception))

    def test_a_truncated_png_is_refused(self):
        path = write_png(self.dir / "t.png", [[(1, 2, 3, 4)]])
        path.write_bytes(path.read_bytes()[:-12])
        with self.assertRaises(png.PngError):
            png.read_png(path)

    def test_writing_the_wrong_number_of_bytes_is_refused(self):
        with self.assertRaises(png.PngError):
            png.write_png(self.dir / "bad.png", 2, 2, b"\0" * 15)


class CleanFrameTest(unittest.TestCase):
    """The pass end to end on a frame built here: both copies, one buffer."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)
        self.width = self.height = 9
        rgba = paint(blank(9, 9), 9, block(2, 2, 6, 6), (70, 90, 40, 255))
        rgba = paint(rgba, 9, [(4, 4)], (10, 10, 10, 128))     # one soft pixel
        rgba = paint(rgba, 9, [(1, 1)], (250, 250, 250, 6))    # one halo speck
        self.expected_clean = rgba

        self.frame = sprites.Frame(name="frame-guid", width=9, height=9,
                                   root=self.dir / "frame-guid.png", layers=[])
        png.write_png(self.frame.root, 9, 9, rgba)
        layer = self.dir / "layers" / "frame-guid" / "layer-guid.png"
        layer.parent.mkdir(parents=True)
        png.write_png(layer, 9, 9, rgba)
        self.frame.layers.append(layer)

    def tearDown(self):
        self.tmp.cleanup()

    def test_both_copies_are_written_and_agree(self):
        result = clean.clean_frame(self.frame)
        self.assertTrue(result.ok, result.errors)
        self.assertEqual(result.files, 2)
        self.assertEqual(png.read_png(self.frame.root)[2],
                         png.read_png(self.frame.layers[0])[2])

    def test_the_result_passes_check(self):
        result = clean.clean_frame(self.frame)
        self.assertEqual(pixels.problems(png.read_png(self.frame.root)[2], 9, 9), [])
        self.assertGreater(result.painted, 0)
        self.assertEqual(result.partial, 2)      # the 128 and the 6

    def test_a_missing_layer_is_reported_and_the_root_still_written(self):
        self.frame.layers[0].unlink()
        result = clean.clean_frame(self.frame)
        self.assertTrue(result.ok, result.errors)
        self.assertEqual(result.files, 1)
        self.assertEqual(len(result.warnings), 1)
        self.assertIn("missing", result.warnings[0])
        self.assertFalse(self.frame.layers[0].exists())   # not invented

    def test_a_size_mismatch_leaves_the_file_alone(self):
        before = self.frame.root.read_bytes()
        frame = sprites.Frame(name="other", width=4, height=4,
                              root=self.frame.root, layers=[])
        result = clean.clean_frame(frame)
        self.assertFalse(result.ok)
        self.assertIn("9x9", result.errors[0])
        self.assertEqual(self.frame.root.read_bytes(), before)

    def test_a_dry_run_writes_nothing(self):
        before = self.frame.root.read_bytes()
        result = clean.clean_frame(self.frame, dry_run=True)
        self.assertTrue(result.ok)
        self.assertEqual(result.files, 0)
        self.assertEqual(self.frame.root.read_bytes(), before)


class BackwardCompatibleBufferTest(unittest.TestCase):
    """``binarize`` and ``inner_outline`` compose into the one pass ``clean`` runs."""

    def test_the_composition_is_the_pass(self):
        rgba = paint(blank(6, 6), 6, block(2, 2, 4, 4), (30, 40, 50, 255))
        rgba = paint(rgba, 6, [(0, 0)], (30, 40, 50, 90))
        snapped, partial = pixels.binarize(rgba)
        inked, _ = pixels.inner_outline(snapped, 6, 6)
        self.assertEqual(partial, 1)
        self.assertEqual(pixels.problems(inked, 6, 6), [])
        self.assertEqual(pixel(inked, 6, 0, 0), (0, 0, 0, 0))


@unittest.skipUnless(PROJECT_ROOT is not None, "no .yyp above the tests")
class SpriteFilesTest(unittest.TestCase):
    """A real sprite: the GUIDs in the ``.yy`` are the file names on disk."""

    @classmethod
    def setUpClass(cls):
        from gm.project import Project
        cls.project = Project(PROJECT_ROOT)

    def test_frame_paths_come_from_the_yy(self):
        sprite = sprites.sprite(self.project, "spr_bell_ringer_idle")
        self.assertEqual(len(sprite.frames), 16)
        self.assertEqual(sprite.size(), (97, 151))
        self.assertIn("Bell-Ringer", sprite.folder_path)
        self.assertTrue(sprite.frames[0].root.exists())
        self.assertTrue(all(path.exists() for path in sprite.frames[0].layers))

    def test_the_layer_file_name_is_the_layer_guid(self):
        sprite = sprites.sprite(self.project, "spr_bell_ringer_idle")
        data = self.project.resource("spr_bell_ringer_idle").data
        self.assertEqual([path.stem for path in sprite.frames[0].layers],
                         [layer["name"] for layer in data["layers"]])
        self.assertEqual([path.parent.name for path in sprite.frames[0].layers],
                         [sprite.frames[0].name])      # the folder is the frame

    def test_select_by_folder_and_state(self):
        chosen, notes = sprites.select(self.project, folder="Zombie Sprites/restyled",
                                       states=["idle"])
        self.assertEqual(notes, [])
        self.assertGreaterEqual(len(chosen), 10)       # restyled has older sets too
        self.assertTrue(all(one.name.endswith("_idle") for one in chosen))
        self.assertFalse(any("portrait" in one.name for one in chosen))

    def test_a_narrow_selector_picks_one_sprite(self):
        chosen, notes = sprites.select(self.project, folder="restyled/Bell-Ringer",
                                       states=["idle"])
        self.assertEqual(notes, [])
        self.assertEqual([one.name for one in chosen], ["spr_bell_ringer_idle"])
        self.assertEqual(chosen[0].folder_path,
                         "folders/Sprites/Tower Defense/Zombie Sprites/restyled/Bell-Ringer.yy")

    def test_no_selector_selects_nothing(self):
        chosen, notes = sprites.select(self.project)
        self.assertEqual(chosen, [])
        self.assertTrue(notes)

    def test_a_glob_that_matches_nothing_says_so(self):
        chosen, notes = sprites.select(self.project, patterns=["spr_no_such_*"])
        self.assertEqual(chosen, [])
        self.assertTrue(any("no sprite matched" in note for note in notes))

    def test_a_non_sprite_name_is_refused(self):
        with self.assertRaises(ValueError):
            sprites.sprite(self.project, "obj_mon")


class PreviewTest(unittest.TestCase):
    """The sheet: four rows, one column per sprite, and no crash without a before."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        base = Path(self.tmp.name)
        self.root = base / "proj"
        self.backup = base / "backup"
        folder = self.root / "sprites" / "spr_demo_idle"
        folder.mkdir(parents=True)

        soft = paint(blank(6, 6), 6, block(1, 1, 4, 4), (40, 60, 40, 255))
        snapped, _ = pixels.binarize(soft)
        clean_rgba, _ = pixels.inner_outline(snapped, 6, 6)

        root_png = folder / "frame.png"
        png.write_png(root_png, 6, 6, clean_rgba)

        before_dir = self.backup / "sprites" / "spr_demo_idle"
        before_dir.mkdir(parents=True)
        png.write_png(before_dir / "frame.png", 6, 6, soft)

        self.sprite = sprites.Sprite(
            "spr_demo_idle", folder, "Tower Defense/Zombie Sprites/restyled/Demo",
            [sprites.Frame("frame", 6, 6, root_png, [])])

    def tearDown(self):
        self.tmp.cleanup()

    def test_the_sheet_is_four_rows_of_one_column(self):
        out = Path(self.tmp.name) / "sheet.png"
        path, notes = report.preview(self.root, [self.sprite], self.backup, out,
                                     cell=16, pad=4, cols=4)
        self.assertEqual(notes, [])
        width, height, _ = png.read_png(path)
        self.assertEqual((width, height), (4 + 16 + 4, 4 + 4 * (16 + 4)))

    def test_a_missing_before_is_a_note_not_a_crash(self):
        (self.backup / "sprites" / "spr_demo_idle" / "frame.png").unlink()
        out = Path(self.tmp.name) / "sheet2.png"
        _, notes = report.preview(self.root, [self.sprite], self.backup, out,
                                  cell=16, pad=4, cols=4)
        self.assertTrue(notes)
        self.assertIn("no 'before'", notes[0])


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
