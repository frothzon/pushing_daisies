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

import sys
import tempfile
import unittest
from pathlib import Path

TESTS_DIR = Path(__file__).resolve().parent
TOOLS_DIR = TESTS_DIR.parent
REPO_ROOT = TOOLS_DIR.parent
sys.path.insert(0, str(TOOLS_DIR))

from gm import events, gml, project, yy  # noqa: E402


def find_project_root():
    for candidate in [REPO_ROOT, *REPO_ROOT.parents]:
        if any(candidate.glob("*.yyp")):
            return candidate
    return None


PROJECT_ROOT = find_project_root()


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

            # event helper
            obj.write_event(0, 0, "show_debug_message(\"hi\");\n")
            obj.save()
            self.assertTrue((root / "objects/obj_new/Create_0.gml").exists())
            self.assertEqual(obj.events()[0][2], "Create_0.gml")

            # the yyp still parses and lists the new resources
            reloaded = project.Project(root)
            self.assertIn("scr_new", [r.name for r in reloaded.resources()])
            self.assertIn("obj_new", [r.name for r in reloaded.resources()])


if __name__ == "__main__":
    unittest.main()
