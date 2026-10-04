# AGENTS.md

Working agreement for AI agents (and humans) editing **Pushing Daisies**
(`pushing_daisies_recovered`) — a GameMaker Studio 2 project converted from
GameMaker 8, so much of the code is GMS1-era GML running under GMS2 semantics.
Most of the bugs here come from that gap.

---

## 0. START HERE — consult `lessons_learned.md` before you debug

**Before forming a theory about any bug, read
[`lessons_learned.md`](./lessons_learned.md).**

That file is a post-mortem of every hard-won bug in this project:
*symptom → the real cause → the fix → the rule that stops it coming back*.
These bugs **deliberately look like something else** — a "greyed-out button" was
an array index, "buttons that never appear" was an error inside a log statement —
so a symptom match means you are almost certainly looking at the same bug.

1. Search it by symptom **and** by keyword:

   ```bash
   grep -niE 'grey|not set before reading|active=0|noone|scope|room_speed|crlf|shadow|state machine' lessons_learned.md
   ```

2. Read the matching entry and apply **both** its fix and its guard rails.
3. Only if nothing matches do you debug from first principles.
4. **When you fix something new that took more than a few minutes to understand,
   add an entry to `lessons_learned.md` and a row to its Index.** That is part of
   the task, not optional cleanup. The template is at the bottom of that file.

> If you are about to write *"let me try changing X and see"* — stop and grep
> `lessons_learned.md` first.

---

## 1. Working rules (non-negotiable)

These six rules each exist because breaking them cost hours. Each links to the
lesson that explains why.

| # | Rule | Lesson |
| --- | --- | --- |
| 1 | **GameMaker must not have the files you are editing open** — ask the user to close/reload the project, and reload again before they test | [LL-008](./lessons_learned.md#ll-008) |
| 2 | **Never hand-edit or JSON-round-trip `.yy`/`.yyp`/`.resource_order`** — use `python_tools/gm` | [LL-009](./lessons_learned.md#ll-009) |
| 3 | **Never change a file's line endings as a side effect**, and never let an escape like `\r\n` land in a file as literal text | [LL-006](./lessons_learned.md#ll-006) |
| 4 | **Never add a script whose name matches a GameMaker built-in** | [LL-005](./lessons_learned.md#ll-005) |
| 5 | **A diagnostic must never be able to throw** — guard every variable a log line reads | [LL-002](./lessons_learned.md#ll-002) |
| 6 | **Pass what a function needs as arguments; read another instance's variables only inside `with()`** | [LL-003](./lessons_learned.md#ll-003) |

### 1.1 GameMaker holds the files
The IDE keeps resources in memory and rewrites `.yy`, `.yyp`, `.resource_order`
and any open event/script from **its own buffers** when it saves. Work done
outside the IDE for those files is silently thrown away. Before a structural
edit, ask the user to close the project; before they test, ask them to reload it.

### 1.2 Version control
A local repo was initialised on **2026-10-03** (`git init -b main`, one initial
commit, 2425 files). It has **no remote**, so "undo" goes back exactly one
commit. `.gitignore` already excludes `*.resource_order` and `Build`. Still copy
anything you are about to restructure into `/tmp`
(`/tmp/menu_refactor_backup/`, `/tmp/gmfix_backup/` are from previous sessions).

### 1.3 Line endings
Measure before you assume. The 465 `.gml` files are **375 LF-only | 89 mixed |
1 CRLF-only**; the mixed ones are `objects/**` event files where the *blank
lines* are a lone LF among CRLF lines. `.gitattributes` says `*.gml text eol=lf`,
so git stores LF and **rewrites the working tree on the next checkout** —
GameMaker copes with both, but ~90 files' bytes change. Read/write GML through
`gm.gml.read_gml` / `write_gml`, which preserve whatever is on disk, and verify:

```bash
grep -cF '\r' <file.gml>     # fixed-string count of literal backslash-r: must be 0
```

Full EOL census commands: [LL-006](./lessons_learned.md#ll-006).

---

## 2. Verification gates — run these before you claim anything is fixed

```bash
cd /home/rayu/GameMakerProjects/pushing_daisies_recovered

# 1. every .yy/.yyp/.resource_order round-trips byte-for-byte
#    expect: 566 file(s) round-trip byte-for-byte, 0 differ
PYTHONPATH=python_tools python3 -m gm roundtrip

# 2. toolkit test suite
#    expect: Ran 16 tests ... OK
PYTHONPATH=python_tools python3 -m unittest discover -s python_tools/tests

# 3. the GML you changed still parses, and has the functions you expect
PYTHONPATH=python_tools python3 -m gm gml-functions scr_menu_state
PYTHONPATH=python_tools python3 -m gm gml-get Menu --event Step_0
PYTHONPATH=python_tools python3 -m gm info Menu           # type, events, functions
PYTHONPATH=python_tools python3 -m gm list GMScript       # spot built-in collisions

# 4. no stray escapes in the files you touched (each must print 0)
grep -cF '\r' objects/Menu/Step_0.gml
```

**Green tooling is not a fix.** The real gate is a run with
`global.devMode = true`, after the user has **reloaded the project**. Give them
the exact log lines to look for, and name what would falsify your fix.

---

## 3. Codebase map

| Area | Where |
| --- | --- |
| Title menu (state machine = `enum` + `switch`) | `objects/Menu/{Create_0,Step_0,Draw_0,Draw_64}.gml` |
| Menu states, state-change, debug dump | `scripts/scr_menu_state/scr_menu_state.gml` — `MENU_STATE`, `scr_menu_state_name`, `scr_menu_changeState`, `scr_menu_debug`, `scr_menu_debug_buttons` |
| Button object (all buttons are `_button`) | `objects/_button/{Create_0,Step_0,Draw_0,Draw_64}.gml` → `scr_iniButton()`, `scr_stpButton()` |
| Button plumbing | `scripts/scr_setup_menuStates`, `scr_create_button`, `scr_button_index_{enable,disable,hide}`, `scr_button_greyout`, `scr_scaleButton` |
| Button callbacks | `scripts/fcn_button_{new,cont,options,quit,return,test}/` |
| Fade | `scripts/{fadeout,ini_fadeout,draw_fadeout,draw_reset}`, `objects/_fadeout/` |
| Globals | `scripts/initialize_game/initialize_game.gml` — `global.devMode`, `global.saveName`, `global.startRoom` |
| Logging | `scripts/print/print.gml` (already gated on `global.devMode`) |
| Python toolkit | `python_tools/` — read `python_tools/README.md` first |

**Legacy state machines that are NOT yet migrated** (they still use
`scr_runState` / `scr_changeState` / `scr_setupState`, with the numeric-sentinel
problems from [LL-004](./lessons_learned.md#ll-004)):

| Machine | Object(s) | State scripts |
| --- | --- | --- |
| main game flow | `_mainControl`, `Control` | `scr_main_startup`, `scr_main_cutscene`, `scr_main_normal`, `scr_main_pause`, `scr_main_gameOver`, `scr_main_highScore` |
| level flow | `_levelControl` | `scr_level_start`, `scr_level_spawn`, `scr_level_wait` |
| camera | `_viewControl` | `scr_view_idle`, `scr_view_drag`, `scr_view_pause` |
| towers | `obj_tower`, `obj_tower_edit` | `scr_tower_normal`, `scr_tower_shoot`, `scr_tower_return` |
| monsters | `obj_mon` | `scr_zombie_emerge`, `scr_zombie_path` |
| switches | (driven by scripts, no dedicated object) | `scr_updateSwitch`, `scr_setupSwitch`, `scr_set_switch`, `scr_switch_hold`, `scr_switch_timer`, `scr_switch_toggle`, `scr_switch_oneShot` |

The Menu is the **reference implementation** for migrating them — copy its shape
(enum + `switch` + request/apply state changes + debug dump).

---

## 4. GML conventions in this project

* **Match the file you are editing.** Older scripts use
  `function name(argument0, argument1)` with `var _a = argument0, ...;`;
  newer/refactored code uses `function name(_arg)` with `_`-prefixed parameters.
* **Indentation is tabs.** Doc comments are `///`, and `///` is also used for
  trailing inline comments — keep both.
* **Log with `print()`**, which is already gated on `global.devMode` and prefixes
  time / `object_get_name(object_index)` / instance id. Don't add `if(global.devMode)`
  around `print(...)` calls unless you are guarding expensive work.
* **Guard every reference** before use:
  `instance_exists()`, `variable_instance_exists()`, `is_array()`, `is_callable()`.
* **Prefer `enum` + `switch`** over numeric state sentinels in anything you touch.
* **Log prefixes**: `MENU  `, `BTN   `, `FADE  ` — keep them aligned so
  `grep -E 'MENU|BTN|FADE'` gives the whole trail. See
  [LL-011](./lessons_learned.md#ll-011).

---

## 5. Definition of done

A task is finished only when **all** of these are true:

- [ ] `lessons_learned.md` was consulted first, and updated if the bug was new.
- [ ] `roundtrip` → `0 differ`; tests → `OK`; touched GML parses.
- [ ] No literal `\r` in touched files; no line-ending changes.
- [ ] No new script shadows a GameMaker built-in.
- [ ] The change has been described in terms of **what the user should see in the
      log** when they reload and run — including what would prove it *didn't* work.
- [ ] No debug logging was left that can throw (LL-002).

