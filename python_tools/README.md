# python_tools

Tools for reading, writing and editing **GameMaker Studio 2** project files
(`.yy`, `.yyp`, `.resource_order` and `.gml`) *without disturbing formatting*.

Everything is pure standard-library Python 3.8+, so there is nothing to
install.

## Why this exists

GameMaker's resource files are *almost* JSON, and the differences are exactly
the ones that make naive tools rewrite the whole file and turn a one-line edit
into a 1000-line diff:

* every object member and array element has a **trailing comma**;
* object keys are sorted **case-insensitively, with `_` sorting last**
  (`bboxMode` comes before `bbox_bottom`);
* a nested object/array is sometimes written **inline** on one line
  (`{"name":"x","path":"y",}`) and sometimes spread over several lines, and the
  choice depends on the resource schema, not on a simple rule;
* files use **LF** and have **no trailing newline**; `%Name` and `$GMxxx` keys
  are part of the format.

`gm` reads the file's real layout (including which containers were inline) into
ordinary `dict`s/`list`s, and writes it back exactly. Edit one value and only
that value changes on disk.

## Quick start

```bash
cd python_tools

# Explore the project
python -m gm list                 # all resources
python -m gm list GMObject        # only objects
python -m gm info _fadeout        # type, events, functions

# Read values (dotted paths, with [n] for arrays)
python -m gm get-path spr_flower origin
python -m gm get-path rm_test layers.0.instances.0.x

# Edit a value and save (JSON is auto-detected; --raw forces a string)
python -m gm set-path spr_flower origin 4
python -m gm set-path obj_enemy persistent true
python -m gm del-path obj_enemy properties.0

# Canonicalise a file to GameMaker's key order
python -m gm sort spr_flower

# GML
python -m gm gml-functions scr_get_speed
python -m gm gml-get scr_get_speed --function scr_get_speed
python -m gm gml-set scr_get_speed --function scr_get_speed --text "function scr_get_speed(a, b) { return(a/b); }"
python -m gm gml-get _fadeout --event Create_0

# Events
python -m gm events _fadeout
python -m gm add-event obj_enemy Draw_75

# New resources
python -m gm new-script scr_hello
python -m gm new-object obj_enemy --sprite spr_mon --parent obj_mon_base

# Verify every .yy/.yyp round-trips byte-for-byte
python -m gm roundtrip

# The progress tracker (progress.json -> PROGRESS.md + progress.html)
python -m gm progress            # check: valid, and the views match the JSON
python -m gm progress build      # regenerate both views
python -m gm progress list       # a compact board in the terminal
python -m gm progress set <id> status=done
```

Add `-p /path/to/project` (or `--project`) to any command to point at a
project other than the one above the current directory.

`python -m gm --help` lists everything.

## Library use

```python
from gm import Project, gml

project = Project()                      # finds the .yyp automatically
flower = project.resource("spr_flower")

print(flower.type)                       # GMSprite
print(flower.data["origin"])             # 4

# mutate the parsed data, then save; everything else stays byte-identical
flower.data["origin"] = 0
flower.save()

# objects and their events
enemy = project.resource("obj_enemy")
for event_type, event_num, filename in enemy.events():
    print(event_type, event_num, filename)
enemy.write_event(0, 0, 'show_debug_message("created");\n')
enemy.save()

# scripts
src = project.resource("scr_get_speed").read_script()
functions = gml.function_names(src)
```

### Low-level `.yy` access

```python
from gm import yy

document = yy.Document.from_file("objects/obj_player/obj_player.yy")
document.data["visible"] = False
document.save()                          # byte-exact except that one value

text = yy.dumps(yy.loads('{"a":1,}'))    # '{"a":1,}'
```

`yy.loads` returns `GmObject` / `GmArray`, which are `dict` / `list` subclasses
with an extra `inline` attribute describing how the container was formatted.
Pass `sort=True` to `dumps`/`save` to have keys re-ordered the way the IDE
would when creating a new resource.

### Editing GML

```python
from gm import gml

text = gml.read_gml("scripts/scr_get_speed/scr_get_speed.gml")
updated = gml.replace_function(text, "scr_get_speed", "function scr_get_speed(a, b) {\n\treturn(a/b);\n}")
gml.write_gml("scripts/scr_get_speed/scr_get_speed.gml", updated)
```

`find_functions` understands strings and comments, so braces inside them do not
confuse it. `read_gml` / `write_gml` never touch line endings (the project
contains both LF and CRLF `.gml` files).

## Layout

| File | Purpose |
| --- | --- |
| `gm/yy.py` | Byte-exact `.yy` / `.yyp` / `.resource_order` reader & writer |
| `gm/gml.py` | GML read/write plus function-level editing |
| `gm/events.py` | `eventType`/`eventNum` ↔ `Create_0.gml` mapping |
| `gm/project.py` | `Project`, `Resource`, key-path helpers, creation helpers |
| `gm/progress.py` | The progress tracker: schema, validation, the two generated views |
| `gm/cli.py`, `gm/__main__.py` | `python -m gm ...` command line interface |
| `tests/test_gm.py` | Round-trip and editing tests |

## Tests

```bash
python -m unittest discover -s python_tools/tests -v
```

The suite verifies that every `.yy`, `.yyp` and `.resource_order` file in the
project round-trips **byte-for-byte**, that edits leave the rest of the file
untouched, and that the GML and creation helpers work.

## Notes & limitations

* New scripts/objects are registered in the `.yyp`; GameMaker regenerates the
  `.resource_order` file on its next save, so this tool does not maintain it.
* `sort=True` reproduces the IDE's key order; newly *inserted* keys are placed
  in that order automatically, but existing files are never re-sorted unless
  you ask.
* Collision events are written to `Collision_<object>.gml` when the collision
  object name is known.
