"""Round-trip and editing tests for the ``gm`` toolkit.

Run with::

    python3 -m unittest discover -s python_tools/tests -v

The suite checks three things:

1. every ``.yy`` / ``.yyp`` / ``.resource_order`` file in the project
   round-trips byte-for-byte;
2. editing a value (or setting it to its current value) does not disturb the
   rest of the file;
3. the GML helpers and the resource-creation helpers behave correctly.
"""

import contextlib
import io
import json
import re
import string
import sys
import tempfile
import unittest
from pathlib import Path

TESTS_DIR = Path(__file__).resolve().parent
TOOLS_DIR = TESTS_DIR.parent
REPO_ROOT = TOOLS_DIR.parent
sys.path.insert(0, str(TOOLS_DIR))

from gm import events, gml, progress, project, yy  # noqa: E402


def find_project_root():
    for candidate in [REPO_ROOT, *REPO_ROOT.parents]:
        if any(candidate.glob("*.yyp")):
            return candidate
    return None


PROJECT_ROOT = find_project_root()


def runtime_fnames():
    """The ``fnames`` file of the ACTIVE runtime, or None when this machine has
    no runtime cache (CI, a fresh checkout).

    ``fnames`` is the IDE's own table of everything the runtime provides: one
    identifier per line, a function as ``json_stringify(val, [prettify])`` and an
    enum constant as ``??flexpanel_align``.  It is the only offline authority on
    "does this function exist", which is what makes the tests below possible.
    """
    for cfg in sorted(Path.home().glob(".local/share/GameMakerStudio2*/runtime.json")):
        try:
            data = json.loads(cfg.read_text())
        except (OSError, ValueError):
            continue
        name = data.get("active")
        if not name:
            continue
        fnames = cfg.parent / "Cache" / "runtimes" / f"runtime-{name}" / "fnames"
        if fnames.exists():
            return fnames
    return None


def runtime_identifiers(path):
    """Every identifier defined by an ``fnames`` file."""
    known = set()
    for line in Path(path).read_text(errors="replace").splitlines():
        line = line.strip()
        if not line:
            continue
        # strip the enum marker, then take the name: the signature after it
        # ("([struct])", "(val, [prettify])") is documentation, not a name
        match = re.match(r"\?*([A-Za-z_][A-Za-z0-9_]*)", line)
        if match:
            known.add(match.group(1))
    return known


def strip_gml(source):
    """``source`` with comments and string literals removed (2026-10-22).

    Needed before asking "what does this code call", because a ``(`` inside a
    doc comment or a label is not a call, and a ``//`` inside a string is not a
    comment.  One left-to-right scan decides both; two regexes cannot, because
    which one wins would depend on the order they ran in.
    """
    out = []
    index, size = 0, len(source)
    while index < size:
        char = source[index]
        if char == "/" and source.startswith("//", index):
            end = source.find("\n", index)
            index = size if end < 0 else end
        elif char == "/" and source.startswith("/*", index):
            end = source.find("*/", index + 2)
            index = size if end < 0 else end + 2
        elif source.startswith('@"', index):
            # a verbatim string: "" is the escape, a backslash is literal
            index += 2
            while index < size:
                if source.startswith('""', index):
                    index += 2
                elif source[index] == '"':
                    index += 1
                    break
                else:
                    index += 1
        elif char == '"':
            index += 1
            while index < size:
                if source[index] == "\\":
                    index += 2
                elif source[index] == '"':
                    index += 1
                    break
                else:
                    index += 1
        else:
            out.append(char)
            index += 1
    return "".join(out)


class YyRoundTripTests(unittest.TestCase):
    def test_all_project_files_round_trip(self):
        if PROJECT_ROOT is None:
            self.skipTest("no GameMaker project found")
        files = sorted(PROJECT_ROOT.glob("**/*.yy"))
        files += sorted(PROJECT_ROOT.glob("*.yyp"))
        files += sorted(PROJECT_ROOT.glob("*.resource_order"))
        self.assertGreater(len(files), 0, "expected to find project files")
        failures = []
        for path in files:
            original = path.read_bytes()
            rebuilt = yy.Document.from_file(path).dumps().encode("utf-8")
            if original != rebuilt:
                failures.append(str(path.relative_to(PROJECT_ROOT)))
        self.assertEqual(failures, [], f"{len(failures)} files did not round-trip")

    def test_loads_accepts_trailing_commas_and_reports_layout(self):
        text = '{"a":1,"nested":{"b":2,},"arr":[1,2,],}'
        data = yy.loads(text)
        self.assertEqual(data, {"a": 1, "nested": {"b": 2}, "arr": [1, 2]})
        # this fragment contains no newlines, so every container is inline
        self.assertTrue(data.inline)
        self.assertTrue(data["nested"].inline)
        self.assertTrue(data["arr"].inline)
        self.assertEqual(yy.dumps(data), text)

    def test_multiline_layout_is_preserved(self):
        text = '{\n  "a":1,\n  "arr":[\n    1,\n    2,\n  ],\n}'
        data = yy.loads(text)
        self.assertFalse(data.inline)
        self.assertFalse(data["arr"].inline)
        self.assertEqual(yy.dumps(data), text)

    def test_numbers_and_escapes_round_trip(self):
        text = (
            "{\n"
            '  "scale":1.0,\n'
            '  "count":42,\n'
            '  "label":"a\\"b\\\\c",\n'
            '  "empty":[],\n'
            "}"
        )
        data = yy.loads(text)
        self.assertEqual(data["scale"], 1.0)
        self.assertIsInstance(data["scale"], float)
        self.assertIsInstance(data["count"], int)
        self.assertEqual(data["label"], 'a"b\\c')
        self.assertEqual(yy.dumps(data), text)



class EditPreservationTests(unittest.TestCase):
    def _sample(self):
        return (
            "{\n"
            '  "$GMShader":"",\n'
            '  "%Name":"s",\n'
            '  "name":"s",\n'
            '  "parent":{\n'
            '    "name":"Shaders",\n'
            '    "path":"folders/Shaders.yy",\n'
            "  },\n"
            '  "resourceType":"GMShader",\n'
            '  "resourceVersion":"2.0",\n'
            '  "type":1,\n'
            "}"
        )

    def test_setting_same_value_keeps_bytes(self):
        text = self._sample()
        document = yy.Document.from_text(text)
        value = project.get_path(document.data, "type")
        project.set_path(document.data, "type", value)
        self.assertEqual(document.dumps(), text)

    def test_adding_and_removing_key_restores_bytes(self):
        text = self._sample()
        document = yy.Document.from_text(text)
        project.set_path(document.data, "zzz", 5, sort=True)
        added = document.dumps()
        self.assertIn('"zzz":5,', added)
        self.assertTrue(added.index('"type"') < added.index('"zzz"'))
        project.del_path(document.data, "zzz")
        self.assertEqual(document.dumps(), text)

    def test_nested_array_editing(self):
        text = '{"x":[{"y":1,},{"y":2,},],}'
        document = yy.Document.from_text(text)
        project.set_path(document.data, "x.1.y", 9)
        self.assertEqual(document.dumps(), '{"x":[{"y":1,},{"y":9,},],}')


class GmlTests(unittest.TestCase):
    def test_find_and_replace_function(self):
        text = (
            "/// @description  scr_demo(a);\n"
            "function scr_demo(argument0) {\n"
            "\treturn(argument0);\n"
            "}\n"
            "\n"
            "function helper() {\n"
            "\t// a } brace in a comment\n"
            "\tvar s = \"}\";\n"
            "\treturn(s);\n"
            "}\n"
        )
        functions = gml.find_functions(text)
        self.assertEqual([f.name for f in functions], ["scr_demo", "helper"])
        self.assertEqual(functions[0].params, "argument0")

        replacement = "function scr_demo(argument0) {\n\treturn(argument0 * 2);\n}"
        updated = gml.replace_function(text, "scr_demo", replacement)
        self.assertIn("argument0 * 2", updated)
        self.assertIn("function helper()", updated)
        # doc comment is preserved
        self.assertIn("/// @description  scr_demo(a);", updated)

    def test_get_function_ignores_strings_and_comments(self):
        text = 'function f() {\n\tvar x = "function fake() {}";\n\treturn(x);\n}\n'
        self.assertEqual(gml.function_names(text), ["f"])

    def test_read_write_preserves_crlf_and_trailing_newline(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "a.gml"
            path.write_bytes(b"line1\r\nline2\r\n")
            text = gml.read_gml(path)
            self.assertEqual(text, "line1\r\nline2\r\n")
            gml.write_gml(path, text)
            self.assertEqual(path.read_bytes(), b"line1\r\nline2\r\n")

    def test_detect_indent(self):
        self.assertEqual(gml.detect_indent("\tvar a = 1;\n"), "\t")
        self.assertEqual(gml.detect_indent("    var a = 1;\n"), "    ")


class EventTests(unittest.TestCase):
    def test_filename_round_trip(self):
        self.assertEqual(events.event_filename(0, 0), "Create_0.gml")
        self.assertEqual(events.event_filename(8, 75), "Draw_75.gml")
        self.assertEqual(events.event_filename(3, 1), "Step_1.gml")
        self.assertEqual(events.event_filename(4, 0, "obj_wall"), "Collision_obj_wall.gml")

    def test_parse_event_filename(self):
        self.assertEqual(events.parse_event_filename("Draw_75.gml"), (8, "75"))
        self.assertEqual(events.parse_event_filename("Create_0.gml"), (0, "0"))
        self.assertIsNone(events.parse_event_filename("notes.txt"))


class KeyPathTests(unittest.TestCase):
    def test_parse_keypath(self):
        self.assertEqual(
            project.parse_keypath("layers[1].instances[0].x"),
            ["layers", 1, "instances", 0, "x"],
        )

    def test_get_path_missing(self):
        self.assertIsNone(project.get_path({"a": 1}, "a.b.c"))
        self.assertEqual(project.get_path({"a": 1}, "missing", "fallback"), "fallback")


class ProjectTests(unittest.TestCase):
    def _make_project(self, tmp):
        root = Path(tmp)
        (root / "test.yyp").write_text(
            '{\n  "$GMProject":"v1",\n  "%Name":"test",\n  "resources":[\n  ],\n}',
            encoding="utf-8",
        )
        return root

    def test_create_script_and_object(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = self._make_project(tmp)
            proj = project.Project(root)
            script = proj.create_script("scr_new", "function scr_new() {\n\treturn(1);\n}\n")
            self.assertTrue((root / "scripts/scr_new/scr_new.gml").exists())
            self.assertTrue((root / "scripts/scr_new/scr_new.yy").exists())
            self.assertEqual(proj.resource("scr_new").type, "GMScript")
            self.assertEqual(script.read_script().strip(), "function scr_new() {\n\treturn(1);\n}")

            obj = proj.create_object("obj_new", sprite=None)
            self.assertTrue((root / "objects/obj_new/obj_new.yy").exists())
            self.assertEqual(obj.data["name"], "obj_new")

            shader = proj.create_shader(
                "shd_new", "void main() {}\n", "void main() {}\n"
            )
            self.assertTrue((root / "shaders/shd_new/shd_new.yy").exists())
            self.assertEqual(shader.type, "GMShader")
            self.assertEqual(
                (root / "shaders/shd_new/shd_new.vsh").read_text(encoding="utf-8"),
                "void main() {}\n",
            )
            self.assertEqual(
                (root / "shaders/shd_new/shd_new.fsh").read_text(encoding="utf-8"),
                "void main() {}\n",
            )

            # event helper
            obj.write_event(0, 0, "show_debug_message(\"hi\");\n")
            obj.save()
            self.assertTrue((root / "objects/obj_new/Create_0.gml").exists())
            self.assertEqual(obj.events()[0][2], "Create_0.gml")

            # the yyp still parses and lists the new resources
            reloaded = project.Project(root)
            self.assertIn("scr_new", [r.name for r in reloaded.resources()])
            self.assertIn("obj_new", [r.name for r in reloaded.resources()])
            self.assertIn("shd_new", [r.name for r in reloaded.resources()])


class ProgressTests(unittest.TestCase):
    """The tracker: progress.json is the source, and the views must match it.

    The first three tests are the gate.  Edit progress.json, forget
    ``gm progress build``, and this suite goes red - which is the entire reason
    the JSON is allowed to be the source of truth.
    """

    def setUp(self):
        self.json_path = PROJECT_ROOT / progress.JSON_NAME

    def _doc(self):
        try:
            return progress.load(self.json_path)
        except SystemExit as exc:
            self.fail("progress.json is unreadable: %s" % exc)

    def _errors(self, mutate):
        doc = self._doc()
        mutate(doc)
        return progress.validate(doc)

    # -- the repo's own tracker -------------------------------------------
    def test_repo_tracker_is_valid(self):
        self.assertEqual([], progress.validate(self._doc(), PROJECT_ROOT))

    def test_generated_views_are_in_sync(self):
        sha = progress.fingerprint(self._doc())
        for name in (progress.MD_NAME, progress.HTML_NAME):
            path = PROJECT_ROOT / name
            self.assertTrue(path.exists(), "%s is missing - run: gm progress build" % name)
            self.assertIn(sha, path.read_text(encoding="utf-8"),
                          "%s is stale - run: gm progress build" % name)

    def test_check_passes_on_the_repo(self):
        with contextlib.redirect_stdout(io.StringIO()):
            code = progress.check(PROJECT_ROOT)
        self.assertEqual(0, code)

    def test_a_hand_edit_breaks_the_sync_until_you_rebuild(self):
        doc = self._doc()
        before = progress.fingerprint(doc)
        doc["tasks"][0]["title"] += " (edited)"
        after = progress.fingerprint(doc)
        self.assertNotEqual(before, after)
        md = (PROJECT_ROOT / progress.MD_NAME).read_text(encoding="utf-8")
        self.assertIn(before, md)
        self.assertNotIn(after, md)

    def test_awaiting_none_survives_the_cli_coercion(self):
        # A backlog card is "awaiting none" - the STRING - and the generic
        # "none means absent" rule used to turn it into null, which the
        # validator then rejected.  Backlog cards had to be hand-edited.
        self.assertEqual(progress._coerce("awaiting", "none"), "none")
        self.assertIsNone(progress._coerce("done", "none"))

    def test_save_and_load_round_trip_in_canonical_order(self):
        doc = self._doc()
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / progress.JSON_NAME
            progress.save(path, doc)
            again = progress.load(path)
        self.assertEqual(progress.dumps(doc), progress.dumps(again))
        ids = [t["id"] for t in again["tasks"]]
        self.assertEqual(sorted(ids), ids, "canonical form sorts the tasks by id")
        self.assertEqual(len(ids), len(set(ids)))
        self.assertNotIn("\r", progress.dumps(again))

    def test_html_embeds_the_json_it_was_built_from(self):
        doc = self._doc()
        html = progress.build_html(doc)
        found = re.search(r'id="progress-data" data-sig="([^"]*)"[^>]*>(.*?)</script>',
                          html, re.S)
        self.assertIsNotNone(found, "the data block is missing from the page")
        self.assertEqual(len(doc["tasks"]), len(json.loads(found.group(2))["tasks"]))
        unescaped = (found.group(1).replace("&amp;", "&")
                     .replace("&quot;", '"').replace("&lt;", "<"))
        self.assertEqual(unescaped, progress.loose_signature(doc),
                         "python and the browser must agree, or the page cannot spot staleness")

    def test_build_is_deterministic(self):
        doc = self._doc()
        self.assertEqual(progress.build_md(doc), progress.build_md(doc))
        self.assertEqual(progress.build_html(doc), progress.build_html(doc))

    def test_loose_signature_ignores_task_order(self):
        doc = self._doc()
        shuffled = json.loads(json.dumps(doc))
        shuffled["tasks"].reverse()
        self.assertEqual(progress.loose_signature(doc), progress.loose_signature(shuffled))

    # -- the rules that keep it honest ------------------------------------
    def test_rejects_an_unknown_key(self):
        errs = self._errors(lambda d: d["tasks"][0].update({"statuss": "next"}))
        self.assertTrue(any("unknown key" in e for e in errs), errs)

    def test_rejects_a_status_it_does_not_know(self):
        errs = self._errors(lambda d: d["tasks"][0].update({"status": "nearly"}))
        self.assertTrue(any("status" in e for e in errs), errs)

    def test_rejects_a_duplicate_id(self):
        errs = self._errors(lambda d: d["tasks"].append(dict(d["tasks"][0])))
        self.assertTrue(any("duplicate id" in e for e in errs), errs)

    def test_rejects_a_done_card_that_is_still_awaiting(self):
        """The card is built BY THE TEST, not found in the repo.

        This used to search for whichever card happened to be awaiting a
        person, so it raised StopIteration - not a real failure - the moment
        the board's awaiting strip was emptied.  A gate that goes red when the
        thing it guards is finally clean is worse than no gate (LL-037).
        """
        def mutate(d):
            task = d["tasks"][0]
            task["status"] = "done"
            task["done"] = "2026-01-01"
            task["awaiting"] = "rayu"
            task["needs"] = "a line, so only the rule under test fails"
        errs = self._errors(mutate)
        self.assertTrue(any("awaiting" in e for e in errs), errs)

    def test_rejects_awaiting_without_saying_what_is_needed(self):
        def mutate(d):
            d["tasks"][0]["awaiting"] = "rayu"
            d["tasks"][0]["needs"] = ""
        errs = self._errors(mutate)
        self.assertTrue(any("needs" in e for e in errs), errs)

    def test_rejects_a_backlog_card_that_is_awaiting_a_person(self):
        """Built by the test, for the same reason as the test above: selecting a
        card out of the live board makes the gate depend on the board's shape
        rather than on the rule (LL-037)."""
        def mutate(d):
            task = d["tasks"][0]
            task["status"] = "backlog"
            task["done"] = None
            task["awaiting"] = "rayu"
            task["needs"] = "a line, so only the rule under test fails"
        errs = self._errors(mutate)
        self.assertTrue(any("backlog card" in e for e in errs), errs)

    def test_rejects_focus_pointing_at_a_card_that_does_not_exist(self):
        errs = self._errors(lambda d: d["focus"].update({"now": ["no-such-card"]}))
        self.assertTrue(any("focus.now" in e for e in errs), errs)

    def test_rejects_a_ref_to_a_file_that_is_not_there(self):
        doc = self._doc()
        doc["tasks"][0]["refs"] = ["this/file/does/not/exist.gml"]
        errs = progress.validate(doc, PROJECT_ROOT)
        self.assertTrue(any("does not exist" in e for e in errs), errs)


class ToonFontTests(unittest.TestCase):
    """The toon sprite fonts: one string_map character per sub-image.

    ``font_add_sprite_ext()`` maps sub-image *i* to ``string_map[i]``, so a map
    that is one character SHORT shifts every glyph after the gap, and one that
    is one character LONG asks for a sub-image that is not there.  Neither
    throws: the text simply comes out wrong, and the cause is invisible from
    the game window.  So the invariant is checked here instead of trusted
    (LL-067).
    """

    INIT = "scripts/initialize_game/initialize_game.gml"

    def _font_map(self):
        if PROJECT_ROOT is None:
            self.skipTest("no GameMaker project found")
        path = PROJECT_ROOT / self.INIT
        self.assertTrue(path.exists(), f"{self.INIT} is missing")
        text = gml.read_gml(path)
        match = re.search(r'var _fontText = "((?:[^"\\]|\\.)*)";', text)
        self.assertIsNotNone(match, "no _fontText literal in initialize_game")
        return re.sub(r"\\(.)", r"\1", match.group(1))

    def _font_sprites(self):
        if PROJECT_ROOT is None:
            self.skipTest("no GameMaker project found")
        return sorted(PROJECT_ROOT.glob("sprites/spr_toonfont_*/*.yy"))

    def test_there_are_five_toon_font_sprites(self):
        self.assertEqual(len(self._font_sprites()), 5)

    def test_one_character_per_sub_image(self):
        mapping = self._font_map()
        for path in self._font_sprites():
            frames = yy.Document.from_file(path).data["frames"]
            self.assertEqual(
                len(mapping), len(frames),
                f"{path.parent.name} has {len(frames)} frames but the map has "
                f"{len(mapping)} characters",
            )

    def test_the_map_has_a_space(self):
        # without a space slot GameMaker spaces every word by the WIDEST glyph
        self.assertIn(" ", self._font_map())

    def test_no_character_is_mapped_twice(self):
        mapping = self._font_map()
        self.assertEqual(len(mapping), len(set(mapping)),
                         "a duplicated character leaves another glyph unmapped")

    def test_every_letter_and_digit_is_mapped(self):
        mapped = set(self._font_map())
        missing = [c for c in string.ascii_letters + string.digits
                   if c not in mapped]
        self.assertEqual(missing, [], f"no glyph for {missing}")


class FlexPanelTests(unittest.TestCase):
    """Introspection guards for the flex UI layer (2026-10-21).

    Two mistakes in a flex panel UI are silent, which is why they are checked
    here instead of trusted:

    * a style property or function this runtime does not have does not error -
      it simply does nothing, and the screen comes out wrong with no message;
    * the layout talks to itself by NAME (``ui_rect("menu", "menu.brand")``),
      and a name no node has returns an EMPTY rectangle rather than throwing,
      so a typo looks like "the title moved to the corner".

    Neither can be caught by a compile, and neither shows up in a screenshot
    taken on the machine where it was written.
    """

    LAYOUT_SCRIPTS = (
        "scripts/scr_ui_layout_menu/scr_ui_layout_menu.gml",
        "scripts/scr_ui_layout_hud/scr_ui_layout_hud.gml",
    )

    def _gml_files(self):
        if PROJECT_ROOT is None:
            self.skipTest("no GameMaker project found")
        return sorted(PROJECT_ROOT.glob("**/*.gml"))

    def _active_runtime_fnames(self):
        """The fnames file of the ACTIVE runtime, or None."""
        return runtime_fnames()

    def test_every_flexpanel_symbol_used_exists_in_the_runtime(self):
        fnames = self._active_runtime_fnames()
        if fnames is None:
            self.skipTest("no GameMaker runtime fnames on this machine")

        known = runtime_identifiers(fnames)

        used = set()
        for path in self._gml_files():
            used.update(re.findall(r"\b(flexpanel_[A-Za-z0-9_]*[A-Za-z0-9])\b",
                                   gml.read_gml(path)))

        self.assertTrue(used, "the GML no longer mentions flex panels")
        missing = sorted(name for name in used if name not in known)
        self.assertEqual(
            missing, [],
            "used but not in the active runtime's fnames: "
            f"{missing} - the call will fail only when this branch runs",
        )

    def test_every_layout_name_asked_for_is_a_node_in_the_tree(self):
        if PROJECT_ROOT is None:
            self.skipTest("no GameMaker project found")

        names = set()
        for rel in self.LAYOUT_SCRIPTS:
            path = PROJECT_ROOT / rel
            self.assertTrue(path.exists(), f"{rel} is missing")
            names.update(re.findall(r'\bname:\s*"([^"]+)"', gml.read_gml(path)))
        self.assertTrue(names, "no named nodes in the layout scripts")

        # every "<tree>", "<node>" pair handed to a rect lookup
        lookup = re.compile(r'\bui_(?:rect|box|hit|place|centre)\(\s*"[^"]*"\s*,\s*"([^"]+)"')
        used = set()
        for path in self._gml_files():
            used.update(lookup.findall(gml.read_gml(path)))

        self.assertTrue(used, "nothing reads a layout rectangle by name")
        # Names are built by concatenation where there are four of them
        # ("options.slider." + string(i)), so a used name and a declared name
        # may be a prefix of each other in EITHER direction.  A typo still
        # fails both tests, which is what this is for.
        unknown = sorted(
            name for name in used
            if not any(node == name or node.startswith(name) or name.startswith(node)
                       for node in names)
        )
        self.assertEqual(
            unknown, [],
            f"asked for a rectangle no node in {self.LAYOUT_SCRIPTS} has: {unknown}",
        )


class CalledFunctionTests(unittest.TestCase):
    """Every identifier the GML CALLS has to exist (2026-10-22).

    ``json_string(_it.t)`` - a name borrowed from JSON.stringify and Python's
    ``json.dumps`` habit instead of from GameMaker - cost a whole run.  GameMaker
    never says "no such function": an unknown call compiles to a VARIABLE READ,
    so the World Map screen built its entire 140-item dump and then died inside
    the Draw event with

        Variable Menu.json_string(101726, -2147483648) not set before reading it.

    naming a variable that is assigned nowhere, in a file that has no such
    variable.  The runtime's own fnames list spells it ``json_stringify``.

    Nothing before that line could see it: it compiles, the rest of the run is
    healthy, and only the frame that reaches the call fails.  So every ``name(``
    in the project is matched against the runtime's fnames and against what the
    project itself defines.  A script counts, because GML lets one be called by
    its own name.

    What this cannot see: a wrong ARGUMENT, a name built into a string, or a
    function that only a NEWER runtime than this machine has.
    """

    #: GML words a `(` may follow without that being a call.
    KEYWORDS = frozenset({
        "if", "else", "while", "for", "do", "switch", "with", "repeat",
        "return", "function", "catch", "throw", "try", "finally", "new",
    })

    def _files(self):
        """{relative path: source} for every .gml the game runs."""
        if PROJECT_ROOT is None:
            self.skipTest("no GameMaker project found")
        paths = []
        for folder in ("scripts", "objects", "rooms"):
            root = PROJECT_ROOT / folder
            if root.is_dir():
                paths += sorted(root.glob("**/*.gml"))
        self.assertTrue(paths, "no GML found")
        return {str(path.relative_to(PROJECT_ROOT)): gml.read_gml(path)
                for path in paths}

    def _called(self, code):
        """The names this code calls as a function.

        ``x.foo()`` and ``global.foo()`` are member calls, so the lookbehind
        rejects a name with a dot in front of it.
        """
        return set(re.findall(r"(?<![\w.$])([A-Za-z_]\w*)\s*\(", code))

    def _defined(self, sources):
        """Every callable name the PROJECT defines."""
        defined = set()
        for folder in ("scripts", "objects"):
            root = PROJECT_ROOT / folder
            if root.is_dir():
                for path in root.iterdir():
                    if path.is_dir():
                        defined.add(path.name)      # a script / an object
        for source in sources.values():
            # function foo(...) - a script function or a constructor
            defined.update(re.findall(r"\bfunction\s+([A-Za-z_]\w*)\s*\(", source))
            # a struct member holding a function literal:
            # `to_key: function(dx, dy){`, `static add_sprite = function(...)`
            defined.update(re.findall(r"([A-Za-z_]\w*)\s*[:=]\s*function\b", source))
            # #macro NAME value
            defined.update(re.findall(r"#[ \t]*macro\s+([A-Za-z_]\w*)", source))
            # a local or static that HOLDS a callable:
            # `var _fn = script_name; ... _fn();`.  This is the author's
            # promise - calling a non-callable throws on its own, and this test
            # is about names that were never defined anywhere at all.
            defined.update(re.findall(r"\bvar\s+([A-Za-z_]\w*)", source))
            defined.update(re.findall(r"\bstatic\s+([A-Za-z_]\w*)", source))
        return defined

    def test_every_called_name_exists(self):
        fnames = runtime_fnames()
        if fnames is None:
            self.skipTest("no GameMaker runtime fnames on this machine")

        raw = self._files()
        sources = {relative: strip_gml(source) for relative, source in raw.items()}
        known = runtime_identifiers(fnames) | self._defined(sources)

        unknown = []
        for relative in sorted(sources):
            for name in sorted(self._called(sources[relative])):
                if name not in known and name not in self.KEYWORDS:
                    unknown.append(f"{name}() in {relative}")
        self.assertEqual(
            unknown, [],
            "called, but defined neither by the runtime nor by this project - "
            "GameMaker compiles an unknown call as a variable read and fails "
            "only when that line runs",
        )

    def test_the_extractor_ignores_comments_and_strings(self):
        """The check above is only as good as this: a `(` in a doc comment or a
        label is not a call, and a `//` inside a string is not a comment."""
        code = strip_gml(
            "/// ui_doc_comment()\n"
            'var _label = "ui_string()";   // ui_trailing_comment()\n'
            "ui_real(1);\n"
        )
        self.assertEqual(self._called(code), {"ui_real"})


if __name__ == "__main__":
    unittest.main()
