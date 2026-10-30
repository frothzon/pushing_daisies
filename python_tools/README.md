# python_tools

Tools for reading, writing and editing **GameMaker Studio 2** project files
(`.yy`, `.yyp`, `.resource_order` and `.gml`) *without disturbing formatting*.

Everything is pure standard-library Python 3.8+, so there is nothing to
install.

## Why this exists

GameMaker resources are not standard JSON: they contain trailing commas,
case-insensitive key ordering with `_` last, schema-dependent inline containers,
special `%Name`/`$GMxxx` keys, LF endings, and no trailing newline. Generic JSON
formatting therefore creates large diffs.

`gm` preserves the original layout while exposing ordinary `dict`/`list` data,
so editing one value changes only that value on disk.

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
python -m gm new-shader shd_tint --vertex shaders/source.vsh --fragment shaders/source.fsh

# Verify every .yy/.yyp round-trips byte-for-byte
python -m gm roundtrip

# The progress tracker (progress.json -> PROGRESS.md + progress.html)
python -m gm progress            # check: valid, and the views match the JSON
python -m gm progress build      # regenerate both views
python -m gm progress list       # a compact board in the terminal
python -m gm progress set <id> status=done

# The headless balance tester - reads the game's own tables out of the GML
python -m gm balance             # project stage 1-1 and print the findings
python -m gm balance tables      # every number it read, and which file owns it
python -m gm balance route       # the room's grid, route and slots
python -m gm balance towers      # the roster: card dps vs delivered, and dominance
python -m gm balance afford      # the income curve against the ladder prices
python -m gm balance sim         # time-step a whole stage: leaks, hearts, the gate
python -m gm balance sim --cycle both   # ...against the idealised fire cycle
python -m gm balance gate --trials 20 --seed 17  # control vs DPS loadout gate
python -m gm balance project --all-waves --profile
python -m gm balance check       # every table still parses (the fast gate)

# fit a knob from outcomes: which curve_end puts these stages in band?
python -m gm balance fit --stages 1 2 3 --from 10 --to 20 --step 5
python -m gm balance fit --stages 1 2 3 --from 10 --to 20 --step 5 --sim

# The art pass - hard alpha + a 1 px black rim, inside the silhouette (LL-073)
python -m gm art check --folder "Zombie Sprites/restyled"   # the gate: exit 1 on any finding
python -m gm art clean --dry-run --sprite 'spr_shroud_*'    # measure, write nothing
python -m gm art clean --backup /tmp/art_before --sprite 'spr_shroud_*'
python -m gm art preview --backup /tmp/art_before \
    --folder "Zombie Sprites/restyled" --state idle  # before/after sheet
```

`art check` decodes the pixels of both copies of every frame (the root PNG and
`layers/<frame>/<layer>.png`), so it fails on the thing the sprite editor hides:
a partially transparent pixel, a colour left in a cleared pixel, a contour that
is not black, or a layer copy that disagrees with its root. `art clean` writes
both copies from one buffer; the stroke is *inside* the silhouette, so no `.yy`
changes and `roundtrip` stays at `0 differ`.

`balance towers` prints four dps figures per tower and it matters which is
which: **card** (`damage x rate x targets`, the shop's claim), **x1** (one
target), **deliv** (x1 with the shot *cycle* charged - LL-040) and **eff**
(deliv x coverage, i.e. what reaches the route). Every step to the right is a
step down, and the size of each drop is the finding. It also reports dominance
on two axis sets: on **every** axis (price, card, x1, eff) nothing in the
roster is dominated; **on the board** (price + delivered) Pina Collider is, by
Slender Mandrake.

`balance sim` is the other half: where `project` is a closed form (a ratio),
`sim` steps the real rules at 60fps - monsters spawn one per 0.5s, towers run
the idle/attack/return state machine, damage lands on `fire_frame` against the
target list, crits and on-hit statuses use seeded rolls, and status effects tick
on every monster Step. Damage during the emerge is retained, matching the
current GML life check; a leak costs one life and pays half a kill. It reports
leaks, hearts, idle money, the split between fighting and the 354-frame wave
gate, how many swings achieved nothing, and the widest target list any tower
held - which is the only honest way to ask whether a `targets` cap can ever
fill. `--seed` makes combat-effect rolls repeatable. `--cycle nominal` runs the
same stage on the idealised fire period instead of the state machine. `--spend`
picks the policy: `none` buys nothing (the baseline that shows what a wave costs
with no towers), `ceiling` re-runs
the greedy at each wave boundary - perfect play with perfect information, and
optimistic because money that lands mid-wave idles until the next one - and
`instant` re-runs it while a wave is live, which is what a person does. The
greedy scores UNION coverage (`dps x the share of route nothing else shoots`)
and is handed the towers already standing, so it spreads along the route and
buys rungs as well as placements (LL-048).

`balance gate` runs the current control and damage four-tower builds on the
first five Brutal waves of the fast Shroud and high-HP Harvester stages. It
places both level-1 builds without specializations or candy in the same four
route cells and reports clean runs, failed runs, leaks, lives, fixed setup cost,
and delivered DPS per tower. Set `--trials`
and `--seed` to choose repeat count and the first deterministic seed; use
`--max-waves` to change the wave count. This is a combat comparison, so it does
not buy more towers during the run.

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
| `gm/project.py` | `Project`, `Resource`, key-path helpers, script/object/shader creation helpers |
| `gm/progress.py` | The progress tracker: schema, validation, the two generated views |
| `gm/balance/` | The headless balance tester: `tables.py` (a GML table reader, including the shot `Cycle`), `geometry.py` (room → grid, route, slots), `terrain.py`, `model.py` (the closed form), `policy.py` (how the money gets spent), `sim.py` (the 60fps time-step), `report.py` (the read-outs) |
| `gm/cli.py`, `gm/__main__.py` | `python -m gm ...` command line interface |
| `tests/test_gm.py`, `tests/test_balance.py` | Round-trip, editing and balance tests |

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
