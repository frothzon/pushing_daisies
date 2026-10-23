"""Tests for the layout checker's text metrics, and the ``gm layout`` command.

The metrics are the foundation of every overlap finding, so they are pinned to
numbers rather than "looks about right": ``string_width`` is reproduced from the
glyph PNGs, and the pinned values are the ones the game itself logs at boot
(``FONT   p16 i=6 W=16 space=4 line=16``).  If a sheet is re-cut and these tests
fail, the *tests* need the new numbers - and so does every layout decision made
with them, which is the point.
"""

import contextlib
import io
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

from gm.layout import cli, dump, metrics, report, rules  # noqa: E402


def find_project_root():
    for candidate in [REPO_ROOT, *REPO_ROOT.parents]:
        if any(candidate.glob("*.yyp")):
            return candidate
    return None


PROJECT_ROOT = find_project_root()


def write_png(path, rows, colour_type=6, filter_type=0):
    """Write an 8-bit PNG from ``rows`` of channel tuples (no dependency)."""
    height, width = len(rows), len(rows[0])
    channels = {0: 1, 2: 3, 4: 2, 6: 4}[colour_type]
    raw = bytearray()
    for row in rows:
        payload = bytearray()
        for pixel in row:
            payload.extend(pixel)
        if filter_type == 0:
            raw.append(0)
            raw.extend(payload)
        elif filter_type == 1:  # Sub: each byte minus the byte `channels` back
            raw.append(1)
            for x in range(len(payload)):
                left = payload[x - channels] if x >= channels else 0
                raw.append((payload[x] - left) & 0xFF)
        else:  # pragma: no cover - only 0 and 1 are used
            raise AssertionError(f"unsupported filter {filter_type}")
    ihdr = struct.pack(">IIBBBBB", width, height, 8, colour_type, 0, 0, 0)

    def chunk(kind, data):
        return (struct.pack(">I", len(data)) + kind + data
                + struct.pack(">I", zlib.crc32(kind + data) & 0xFFFFFFFF))

    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", ihdr)
        + chunk(b"IDAT", zlib.compress(bytes(raw)))
        + chunk(b"IEND", b"")
    )
    return path


class PngInkTests(unittest.TestCase):
    """The decoder: a glyph's ink is its alpha bounding box, per row."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = Path(self._tmp.name)

    def tearDown(self):
        self._tmp.cleanup()

    def _png(self, rows, **kwargs):
        return write_png(self.tmp / "f.png", rows, **kwargs)

    def test_a_blank_frame_has_no_ink(self):
        blank = [[(0, 0, 0, 0)] * 4 for _ in range(4)]
        self.assertEqual((4, 4, 0), metrics.png_ink_width(self._png(blank)))

    def test_ink_is_the_span_of_the_widest_row(self):
        # one blob on row 1 (x=2..3) and a wider one on row 3 (x=1..3):
        # the ink is the overall span 1..3, not the first row's span.
        rows = [[(0, 0, 0, 0)] * 5 for _ in range(5)]
        for x in (2, 3):
            rows[1][x] = (255, 255, 255, 255)
        for x in (1, 2, 3):
            rows[3][x] = (255, 255, 255, 255)
        self.assertEqual((5, 5, 3), metrics.png_ink_width(self._png(rows)))

    def test_separate_blobs_on_one_row_count_as_one_span(self):
        rows = [[(0, 0, 0, 0)] * 4 for _ in range(2)]
        rows[0][0] = (255, 255, 255, 255)
        rows[0][3] = (255, 255, 255, 255)
        self.assertEqual(4, metrics.png_ink_width(self._png(rows))[2])

    def test_the_sub_filter_decodes_to_the_same_pixels(self):
        rows = [[(0, 0, 0, 0)] * 6 for _ in range(2)]
        for x in (1, 2, 3, 4):
            rows[1][x] = (10, 20, 30, 255)
        plain = metrics.png_ink_width(self._png(rows, filter_type=0))
        subbed = metrics.png_ink_width(self._png(rows, filter_type=1))
        self.assertEqual(plain, subbed)
        self.assertEqual(4, subbed[2])

    def test_an_rgb_png_uses_any_non_black_channel(self):
        rows = [[(0, 0, 0)] * 4 for _ in range(2)]
        rows[0][2] = (0, 0, 40)
        self.assertEqual(1, metrics.png_ink_width(self._png(rows, colour_type=2))[2])


class ToonMetricTests(unittest.TestCase):
    """The real project: one glyph per sub-image, and the numbers the game logs."""

    def setUp(self):
        if PROJECT_ROOT is None:
            self.skipTest("no GameMaker project found")
        self.metrics = metrics.load(PROJECT_ROOT)

    def test_every_size_has_the_five_separators_the_game_declares(self):
        self.assertEqual(list(metrics.FONT_SIZES), sorted(self.metrics.fonts))
        seps = {size: self.metrics.fonts[size].sep for size in metrics.FONT_SIZES}
        self.assertEqual({12: -2, 16: -2, 20: -4, 32: -4, 48: -4}, seps)

    def test_the_map_is_pinned_to_94_printable_characters(self):
        chars = self.metrics.font(16).chars
        self.assertEqual(94, len(chars))
        self.assertEqual("!", chars[0])
        self.assertEqual("~", chars[-1])
        self.assertIn(" ", chars)
        self.assertIn("\\", chars)

    def test_the_boot_line_matches_the_game(self):
        # The exact line initialize_game logs; i<W proves prop was honoured and
        # space is a third of W, which is what the game says at boot.
        font = self.metrics.font(16)
        self.assertEqual(6, font.width("i"))
        self.assertEqual(16, font.width("W"))
        self.assertEqual(4, font.width("a a") - 2 * font.width("a"))
        self.assertEqual(16, font.height_of(1))

    def test_a_line_is_one_frame_high_per_row(self):
        self.assertEqual(16, self.metrics.font(16).height_of(1))
        self.assertEqual(32, self.metrics.font(16).height_of(2))
        self.assertEqual(12, self.metrics.height(12))

    def test_an_empty_string_has_no_width(self):
        self.assertEqual(0, self.metrics.width("", 16))

    def test_one_glyph_is_its_own_ink(self):
        font = self.metrics.font(16)
        self.assertEqual(font.ink, {c: font.ink[c] for c in font.chars})
        self.assertEqual(font.ink["W"], font.width("W"))

    def test_width_grows_with_every_character(self):
        sizes = (12, 16, 32)
        for size in sizes:
            font = self.metrics.font(size)
            self.assertLess(font.width("a"), font.width("aa"))
            self.assertLess(font.width("aa"), font.width("aaa"))
            self.assertLess(font.width("W"), font.width("WW"))

    def test_the_trailing_separator_rule_is_the_only_difference(self):
        font = self.metrics.font(16)
        self.assertEqual(font.width("Hi") + font.sep, font.width("Hi", trailing=False))

    def test_the_table_names_the_sizes_it_loaded(self):
        rows = self.metrics.table()
        self.assertEqual(1 + len(metrics.FONT_SIZES), len(rows))
        for size in metrics.FONT_SIZES:
            self.assertTrue(any(row.startswith("%4d" % size) for row in rows[1:]),
                            f"no row for p{size}: {rows}")


class FitTests(unittest.TestCase):
    """Fit, wrap and clip against a synthetic font, so the rules are exact."""

    def setUp(self):
        self.font = metrics.FontMetrics(
            size=16, sep=0, chars="ab .",
            ink={"a": 10, "b": 12, " ": 4, ".": 3}, height=16,
        )

    def test_fits_is_the_width_comparison(self):
        self.assertEqual(22, self.font.width("ab"))
        self.assertTrue(self.font.fits("ab", 22))
        self.assertFalse(self.font.fits("ab", 21))

    def test_a_fitting_string_is_not_clipped(self):
        self.assertEqual("ab", self.font.clip("ab", 22))

    def test_clipping_shortens_until_it_fits_and_never_overruns(self):
        clipped = self.font.clip("ababab", 30)
        self.assertTrue(clipped.endswith(".."), clipped)
        self.assertLessEqual(self.font.width(clipped), 30)
        self.assertTrue("ababab".startswith(clipped[:-2]), clipped)

    def test_clipping_to_nothing_returns_nothing_rather_than_overrunning(self):
        self.assertEqual("", self.font.clip("ababab", 5))

    def test_wrap_breaks_on_spaces_and_every_line_fits(self):
        lines = self.font.wrap("ab ab ab", 48)
        self.assertEqual(["ab ab", "ab"], lines)
        for line in lines:
            self.assertLessEqual(self.font.width(line), 48)
        self.assertEqual("ab ab ab".split(" "), " ".join(lines).split(" "))

    def test_fit_size_prefers_the_bigger_font_and_falls_back(self):
        big = metrics.FontMetrics(size=16, sep=0, chars="ab", ink={"a": 10, "b": 12}, height=16)
        small = metrics.FontMetrics(size=12, sep=0, chars="ab", ink={"a": 7, "b": 9}, height=12)
        sheet = metrics.Metrics(root=Path("."), fonts={16: big, 12: small})
        self.assertEqual(16, sheet.fit_size("ab", 22))
        self.assertEqual(12, sheet.fit_size("ab", 16))
        self.assertIsNone(sheet.fit_size("ab", 15))

    def test_an_unknown_size_names_the_ones_that_exist(self):
        sheet = metrics.Metrics(root=Path("."), fonts={16: self.font})
        with self.assertRaises(metrics.MetricsError) as caught:
            sheet.width("a", 32)
        self.assertIn("[16]", str(caught.exception))


MAP_OK = (
    'var _fontText = "a\\\\b";\n'
    "switch (_size) {\n"
    "    p12: font_add_sprite_ext(spr_toonfont_12x, _fontText, true, -2),\n"
    "    p16: font_add_sprite_ext(spr_toonfont_16x, _fontText, true, -2),\n"
    "    p20: font_add_sprite_ext(spr_toonfont_20x, _fontText, true, -4),\n"
    "    p32: font_add_sprite_ext(spr_toonfont_32x, _fontText, true, -4),\n"
    "    p48: font_add_sprite_ext(spr_toonfont_48x, _fontText, true, -4)\n"
    "}\n"
)


class MetricsErrorTests(unittest.TestCase):
    """A sheet and a map that disagree must fail loudly, not measure garbage."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        (self.root / "fake.yyp").write_text("{}", encoding="utf-8")
        init = self.root / metrics.INIT_GML
        init.parent.mkdir(parents=True, exist_ok=True)
        init.write_text(MAP_OK, encoding="utf-8")

    def tearDown(self):
        self._tmp.cleanup()

    def _sheet(self, size, frames):
        sprite = self.root / metrics.SPRITE_DIR.format(size=size)
        sprite.mkdir(parents=True, exist_ok=True)
        entries = ",".join(
            '{"$GMSpriteFrame":"v1","%%Name":"%s"},' % name for name in frames
        )
        (sprite / f"{sprite.name}.yy").write_text(
            '{"frames":[%s]}' % entries, encoding="utf-8"
        )
        for name in frames:
            write_png(sprite / f"{name}.png", [[(0, 0, 0, 0)]])
        return sprite

    def test_a_map_that_is_longer_than_the_sheet_is_an_error(self):
        for size in metrics.FONT_SIZES:
            self._sheet(size, ["only-one"])
        with self.assertRaises(metrics.MetricsError) as caught:
            metrics.load(self.root, fresh=True)
        self.assertIn("frames", str(caught.exception))
        self.assertIn("_fontText", str(caught.exception))

    def test_the_map_is_read_with_its_escapes_intact(self):
        self.assertEqual("a\\b", metrics.read_font_map(MAP_OK))

    def test_a_non_proportional_font_is_refused(self):
        source = MAP_OK.replace("true, -2", "false, -2", 1)
        with self.assertRaises(metrics.MetricsError) as caught:
            metrics.read_separators(source)
        self.assertIn("not proportional", str(caught.exception))

    def test_a_missing_font_call_names_the_call_it_wanted(self):
        source = MAP_OK.replace("    p20: font_add_sprite_ext(spr_toonfont_20x, _fontText, true, -4),\n", "")
        with self.assertRaises(metrics.MetricsError) as caught:
            metrics.read_separators(source)
        self.assertIn("p20", str(caught.exception))

    def test_a_missing_map_names_the_file(self):
        with self.assertRaises(metrics.MetricsError) as caught:
            metrics.read_font_map("nothing here")
        self.assertIn(metrics.INIT_GML, str(caught.exception))


class LayoutCliTests(unittest.TestCase):
    """``gm layout metrics`` prints the table, and --log is the model's proof."""

    def setUp(self):
        if PROJECT_ROOT is None:
            self.skipTest("no GameMaker project found")
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = Path(self._tmp.name)

    def tearDown(self):
        self._tmp.cleanup()

    def _run(self, **kwargs):
        args = type("Args", (), {"action": "metrics", "root": str(PROJECT_ROOT),
                                 "log": None})
        for key, value in kwargs.items():
            setattr(args, key, value)
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            code = cli.cmd_layout(args)
        return code, out.getvalue()

    def test_metrics_prints_the_sizes_and_the_boot_lines(self):
        code, out = self._run()
        self.assertEqual(0, code, out)
        sheet = metrics.load(PROJECT_ROOT)
        for size in metrics.FONT_SIZES:
            self.assertIn("%4d" % size, out)
        for line in sheet.boot_lines():
            self.assertIn(line.split("  (")[0], out)

    def test_a_matching_log_proves_the_model(self):
        log = self.tmp / "ok.log"
        log.write_text(
            "META  0.00 obj_ui [META  ] FONT   p16 i=6 W=16 space=4 line=16\n",
            encoding="utf-8",
        )
        code, out = self._run(log=str(log))
        self.assertEqual(0, code, out)
        self.assertIn("matches the game", out)

    def test_a_log_with_only_space_different_blames_the_separator_rule(self):
        log = self.tmp / "space.log"
        log.write_text(
            "META  0.00 obj_ui [META  ] FONT   p16 i=6 W=16 space=6 line=16\n",
            encoding="utf-8",
        )
        code, out = self._run(log=str(log))
        self.assertEqual(1, code, out)
        self.assertIn("MISMATCH p16 space", out)
        self.assertIn("trailing separator", out)

    def test_a_log_with_a_different_glyph_width_is_a_plain_mismatch(self):
        log = self.tmp / "bad.log"
        log.write_text(
            "META  0.00 obj_ui [META  ] FONT   p16 i=4 W=16 space=4 line=16\n",
            encoding="utf-8",
        )
        code, out = self._run(log=str(log))
        self.assertEqual(1, code, out)
        self.assertIn("MISMATCH p16 i", out)
        self.assertIn("does not describe", out)
        self.assertNotIn("trailing separator", out)

    def test_a_log_with_no_font_line_fails_loudly(self):
        log = self.tmp / "empty.log"
        log.write_text("nothing to see\n", encoding="utf-8")
        code, out = self._run(log=str(log))
        self.assertEqual(1, code, out)
        self.assertIn("global.devMode", out)


# ---------------------------------------------------------------------------
# the dump, the rules and the report
# ---------------------------------------------------------------------------

OK_LOG = """\
MENU  0.00 Menu [MENU  ] world map  ->  region 1 stage 1 seeds 48
UI    [FONT  ] p16 i=6 W=16 space=4 line=16
UI    [GEOM] begin worldmap 960x540 items 3
UI    [GEOM]   text title 392,20,567,52 "World Map"
UI    [GEOM]   text cur_0 80,24,141,40 "48"
UI    [GEOM]   box panel 80,80,880,500
UI    [GEOM] end worldmap 3 items
BTN   0.00 Menu [BTN   ] hover
"""

BAD_LOG = """\
UI    [GEOM] begin deploy 675x540 items 5
UI    [GEOM]   panel panel 80,160,452,532
UI    [GEOM]   button Deploy 355,408,595,460
UI    [GEOM]   text stage 80,64,300,80 "Region 1   Stage 1   10 waves"
UI    [GEOM]   text title 250,20,425,52 "Deploy"
UI    [GEOM]   text slot 340,415,560,431 "Slender Mandrake"
UI    [GEOM] end deploy 5 items
"""

TRUNCATED_LOG = """\
UI    [GEOM] begin garden 1260x540 items 2
UI    [GEOM]   panel panel 600,160,972,532
UI    [GEOM]   text heading 600,130,700,146 "Seed Shop"
"""


class DumpTests(unittest.TestCase):
    """The parser: tolerant of the log, strict about the block."""

    def test_it_reads_a_block_and_skips_everything_else(self):
        frames = dump.parse_text(OK_LOG)
        self.assertEqual(1, len(frames))
        frame = frames[0]
        self.assertEqual("worldmap", frame.screen)
        self.assertEqual((960.0, 540.0), (frame.width, frame.height))
        self.assertEqual(3, len(frame.items))
        self.assertTrue(frame.complete)
        self.assertEqual(3, frame.declared)
        self.assertEqual(('text', 'title', (392.0, 20.0, 567.0, 52.0), 'World Map'),
                         (frame.items[0].kind, frame.items[0].name,
                          frame.items[0].rect, frame.items[0].text))

    def test_an_unterminated_block_is_returned_but_marked_incomplete(self):
        frames = dump.parse_text(TRUNCATED_LOG)
        self.assertEqual(1, len(frames))
        self.assertFalse(frames[0].complete)
        self.assertEqual(2, len(frames[0].items))

    def test_items_outside_a_block_are_ignored(self):
        frames = dump.parse_text("UI    [GEOM]   box panel 0,0,10,10\n")
        self.assertEqual([], frames)

    def test_a_label_with_spaces_and_quotes_survives_the_round_trip(self):
        log = ('UI    [GEOM] begin x 100x100 items 1\n'
               'UI    [GEOM]   text t 0,0,10,10 "a \\"quoted\\" name"\n'
               'UI    [GEOM] end x 1 items\n')
        frames = dump.parse_text(log)
        self.assertEqual('a "quoted" name', frames[0].items[0].text)

    def test_two_sizes_of_one_screen_stay_two_frames(self):
        log = (BAD_LOG + BAD_LOG.replace("675x540", "1260x540"))
        frames = dump.parse_text(log)
        self.assertEqual(2, len(frames))
        self.assertEqual(["675x540", "1260x540"], [frame.size for frame in frames])

    def test_a_file_with_no_dump_says_so(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "empty.log"
            path.write_text("nothing here\n", encoding="utf-8")
            with self.assertRaises(dump.DumpError) as caught:
                dump.parse_file(path)
            self.assertIn("global.devMode", str(caught.exception))

    def test_item_geometry_helpers(self):
        item = dump.Item("panel", "panel", (10.0, 20.0, 40.0, 60.0))
        self.assertEqual(30.0, item.width)
        self.assertEqual(40.0, item.height)
        self.assertEqual("panel panel", item.label())
        self.assertEqual('text t "x"', dump.Item("text", "t", (0, 0, 1, 1), "x").label())




def make_item(kind, name, x1, y1, x2, y2, text=""):
    return dump.Item(kind=kind, name=name, rect=(x1, y1, x2, y2), text=text)


def make_frame(items, width=100, height=100, screen="probe"):
    return dump.Frame(screen=screen, width=width, height=height,
                      declared=len(items), items=list(items), complete=True)


class RuleTests(unittest.TestCase):
    """Each rule, on rectangles small enough to check by hand."""

    def test_two_strings_that_touch_are_a_text_finding(self):
        items = [make_item("text", "a", 10, 10, 50, 26, "World Map"),
                 make_item("text", "b", 40, 20, 90, 36, "48")]
        found = rules.check([make_frame(items)])
        self.assertEqual(["text"], [f.rule for f in found])
        self.assertEqual(10 * 6, found[0].area)

    def test_nested_boxes_are_the_layout_not_a_collision(self):
        items = [make_item("panel", "screen", 0, 0, 100, 100),
                 make_item("button", "Deploy", 10, 10, 40, 30),
                 make_item("panel", "panel", 10, 10, 40, 30)]
        self.assertEqual([], rules.check([make_frame(items)]))

    def test_sibling_boxes_that_cannot_contain_each_other_collide(self):
        items = [make_item("panel", "wall", 10, 10, 60, 60),
                 make_item("button", "Deploy", 40, 40, 90, 90)]
        found = rules.check([make_frame(items)])
        self.assertEqual(["collide"], [f.rule for f in found])
        self.assertEqual(20 * 20, found[0].area)

    def test_a_string_inside_a_box_is_fine(self):
        items = [make_item("panel", "panel", 0, 0, 100, 100),
                 make_item("text", "t", 10, 10, 60, 26, "inside")]
        self.assertEqual([], rules.check([make_frame(items)]))

    def test_a_string_running_out_of_its_box_is_a_spill(self):
        items = [make_item("panel", "cell", 10, 10, 60, 60),
                 make_item("text", "label", 10, 10, 80, 26, "too wide")]
        found = rules.check([make_frame(items)])
        self.assertEqual(["spill"], [f.rule for f in found])
        self.assertEqual("label", found[0].a.name)
        self.assertEqual("cell", found[0].b.name)

    def test_something_off_the_canvas_names_the_edge(self):
        items = [make_item("panel", "panel", 80, 10, 120, 40)]
        found = rules.check([make_frame(items)])
        self.assertEqual(["canvas"], [f.rule for f in found])
        self.assertIn("right +20", found[0].detail)
        self.assertEqual(20 * 30, found[0].area)

    def test_a_one_pixel_break_is_caught_and_a_rounding_sliver_is_not(self):
        items = [make_item("panel", "a", 0, 0, 10, 10),
                 make_item("panel", "b", 9, 0, 20, 10)]
        self.assertEqual(1, len(rules.check([make_frame(items)])))
        self.assertEqual(0, len(rules.check([make_frame(items)], tol=1.5)))

    def test_boxes_sharing_an_edge_do_not_overlap(self):
        items = [make_item("panel", "a", 0, 0, 10, 10),
                 make_item("panel", "b", 10, 0, 20, 10)]
        self.assertEqual([], rules.check([make_frame(items)]))

    def test_an_image_inside_its_cell_is_fine(self):
        items = [make_item("panel", "cell", 0, 0, 100, 100),
                 make_item("image", "spr_pina_idle_192x", 10, 10, 90, 90)]
        self.assertEqual([], rules.check([make_frame(items)]))

    def test_an_image_over_a_label_is_an_image_finding(self):
        # the Garden Book's branch icon, as it was drawn: x 1..31, while the
        # heading starts at 38 - except here it lands ON the heading
        items = [make_item("text", "heading", 10, 10, 60, 26, "Offense"),
                 make_item("image", "branch_icon", 1, 10, 31, 42)]
        found = rules.check([make_frame(items)])
        self.assertEqual(["image"], [f.rule for f in found])
        self.assertEqual("branch_icon", found[0].a.name)
        self.assertEqual("heading", found[0].b.name)
        self.assertEqual(21 * 16, found[0].area)

    def test_an_image_that_crosses_its_cell_is_an_image_finding(self):
        # Cannon Tulip in the Garden Book's shop cell: 8px of art above the
        # cell's top edge, which every dump called clean (LL-071)
        items = [make_item("panel", "shop_cell", 496, 100, 602, 206),
                 make_item("image", "spr_cannon_tulip_idle_192x", 521, 92, 576, 146)]
        found = rules.check([make_frame(items, width=960, height=540)])
        self.assertEqual(["image"], [f.rule for f in found])
        self.assertEqual("shop_cell", found[0].b.name)
        self.assertEqual(55 * 46, found[0].area)

    def test_an_image_big_enough_to_be_a_backdrop_is_not_a_finding(self):
        items = [make_item("image", "backdrop", 0, 0, 100, 100),
                 make_item("panel", "cell", 10, 10, 90, 90),
                 make_item("text", "label", 10, 10, 60, 26, "on top")]
        self.assertEqual([], rules.check([make_frame(items)]))

    def test_two_images_on_the_same_pixels_is_an_image_finding(self):
        items = [make_item("image", "a", 10, 10, 60, 60),
                 make_item("image", "b", 40, 40, 90, 90)]
        found = rules.check([make_frame(items)])
        self.assertEqual(["image"], [f.rule for f in found])
        self.assertEqual(20 * 20, found[0].area)

    def test_the_worst_finding_comes_first(self):
        items = [make_item("text", "small", 10, 10, 20, 20),
                 make_item("text", "big", 12, 12, 30, 40),
                 make_item("text", "other", 14, 14, 60, 60)]
        found = rules.check([make_frame(items)])
        areas = [finding.area for finding in found]
        self.assertEqual(sorted(areas, reverse=True), areas)

    def test_min_area_drops_the_pedantic_ones(self):
        items = [make_item("panel", "a", 0, 0, 10, 10),
                 make_item("panel", "b", 9, 0, 20, 10)]
        self.assertEqual(1, len(rules.check([make_frame(items)])))
        self.assertEqual(0, len(rules.check([make_frame(items)], min_area=100)))


class ReportTests(unittest.TestCase):
    """What the terminal output says, including when a log is half a log."""

    def test_a_clean_frame_summarises_as_zero_findings(self):
        frames = dump.parse_text(OK_LOG)
        self.assertEqual("1 screen at 1 size, 0 findings", report.summary(frames, []))

    def test_every_finding_lands_under_its_own_screen_heading(self):
        frames = dump.parse_text(BAD_LOG)
        found = rules.check(frames)
        self.assertTrue(found)
        lines = report.render(frames, found)
        self.assertTrue(lines[0].startswith("deploy"))
        self.assertTrue(all(line.startswith("    ") for line in lines[1:-1]), lines)
        self.assertIn("collide", "\n".join(lines))

    def test_a_truncated_frame_is_labelled_not_counted_clean(self):
        frames = dump.parse_text(TRUNCATED_LOG)
        lines = report.render(frames, rules.check(frames))
        self.assertIn("INCOMPLETE", lines[0])
        self.assertIn("incomplete", report.summary(frames, []))

    def test_a_count_mismatch_is_visible(self):
        log = TRUNCATED_LOG + "UI    [GEOM] end garden 2 items\n"
        frames = dump.parse_text(log)
        frames[0].declared = 7
        lines = report.render(frames, [])
        self.assertIn("MISSING ITEMS", lines[0])


class CheckCliTests(unittest.TestCase):
    """``gm layout check``: zero on a clean log, one when something is wrong."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp = Path(self._tmp.name)

    def tearDown(self):
        self._tmp.cleanup()

    def _run(self, *paths, **kwargs):
        args = type("Args", (), {"action": "check", "paths": [str(p) for p in paths],
                                 "tol": 0.5, "min_area": 0.0, "items": False})
        for key, value in kwargs.items():
            setattr(args, key, value)
        out = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(out):
            code = cli.cmd_layout(args)
        return code, out.getvalue()

    def _log(self, name, text):
        path = self.tmp / name
        path.write_text(text, encoding="utf-8")
        return path

    def test_a_clean_layout_passes(self):
        code, out = self._run(self._log("ok.log", OK_LOG))
        self.assertEqual(0, code, out)
        self.assertIn("ok    ", out)
        self.assertIn("0 findings", out)

    def test_the_measured_deploy_overlap_fails_the_gate(self):
        code, out = self._run(self._log("deploy.log", BAD_LOG))
        self.assertEqual(1, code, out)
        self.assertIn("FAIL", out)
        self.assertIn("collide", out)
        self.assertIn("spill", out)
        self.assertIn("Deploy", out)

    def test_no_log_file_fails_with_instructions(self):
        code, out = self._run()
        self.assertEqual(2, code, out)
        self.assertIn("pass at least one log file", out)

    def test_a_log_without_a_dump_is_an_error_not_a_pass(self):
        code, out = self._run(self._log("empty.log", "just noise\n"))
        self.assertEqual(1, code, out)
        self.assertIn("no `UI    [GEOM] begin", out)

    def test_a_dump_that_never_finished_fails_the_gate(self):
        """The first real run died mid-dump, and `check` said `ok` (LL-070).

        A block with no `end` has 0 findings only because nothing was examined -
        the rectangles that never printed cannot collide. So it is a failure, and
        the message has to say what it looks like: an ERROR above the block.
        """
        code, out = self._run(self._log("cut.log", TRUNCATED_LOG))
        self.assertEqual(1, code, out)
        self.assertIn("FAIL", out)
        self.assertIn("INCOMPLETE", out)
        self.assertIn("never checked", out)

    def test_a_dump_one_item_short_of_its_count_fails_the_gate(self):
        """The other way a dump stops early: `end` prints, but fewer items than
        the `begin` line declared. The count mismatch is already flagged by the
        report - this pins that it also moves the exit code."""
        log = TRUNCATED_LOG + "UI    [GEOM] end garden 2 items\n"
        text = log.replace("items 2\n", "items 3\n", 1)
        code, out = self._run(self._log("short.log", text))
        self.assertEqual(1, code, out)
        self.assertIn("MISSING ITEMS", out)

    def test_items_flag_lists_the_rectangles_behind_the_findings(self):
        code, out = self._run(self._log("deploy.log", BAD_LOG), items=True)
        self.assertEqual(1, code, out)
        self.assertIn("text stage", out)
