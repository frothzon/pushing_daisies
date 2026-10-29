# AGENTS.md

Working agreement for AI agents (and humans) editing **Pushing Daisies**
(`pushing_daisies_recovered`) — a GameMaker Studio 2 project converted from
GameMaker 8, so much of the code is GMS1-era GML running under GMS2 semantics.
Most of the bugs here come from that gap.

---

## 0. Start here

1. Read [`progress.json`](./progress.json): the `focus` block and every card
   awaiting `rayu`. [`progress.html`](./progress.html) renders the same board.
   Create a card before starting untracked work (§6).
2. Before debugging, search [`lessons_learned.md`](./lessons_learned.md) by
   symptom and keyword. Apply the matching fix **and** guard rails before
   forming a new theory:

   ```bash
   grep -niE 'grey|not set before reading|active=0|noone|scope|room_speed|crlf|shadow|state machine' lessons_learned.md
   ```

3. After fixing a new, non-obvious bug, add an indexed entry using the template
   at the end of `lessons_learned.md`.

---

## 1. Working rules (non-negotiable)

These seven rules each exist because breaking them cost hours. Each links to the
lesson that explains why.

| # | Rule | Lesson |
| --- | --- | --- |
| 1 | **GameMaker must not have the files you are editing open** — ask the user to close/reload the project, and reload again before they test | [LL-008](./lessons_learned.md#ll-008) |
| 2 | **Never hand-edit or JSON-round-trip `.yy`/`.yyp`/`.resource_order`** — use `python_tools/gm` | [LL-009](./lessons_learned.md#ll-009) |
| 3 | **Never change a file's line endings as a side effect**, and never let an escape like `\r\n` land in a file as literal text | [LL-006](./lessons_learned.md#ll-006) |
| 4 | **Never add a script whose name matches a GameMaker built-in** | [LL-005](./lessons_learned.md#ll-005) |
| 5 | **A diagnostic must never be able to throw** — guard every variable a log line reads | [LL-002](./lessons_learned.md#ll-002) |
| 6 | **Pass what a function needs as arguments; read another instance's variables only inside `with()`** | [LL-003](./lessons_learned.md#ll-003) |
| 7 | **Keep [`progress.json`](./progress.json) true, in the same task** — it is the answer to "what are we doing?". Update it, then `gm progress build`. | [§6](#6-the-progress-tracker) |

### 1.1 GameMaker holds the files
The IDE keeps resources in memory and rewrites `.yy`, `.yyp`, `.resource_order`
and any open event/script from **its own buffers** when it saves. Work done
outside the IDE for those files is silently thrown away. Before a structural
edit, ask the user to close the project; before they test, ask them to reload it.

### 1.2 Version control

* Run `git status` before structural changes. Commit a local checkpoint if the
  tree is dirty; pushes are the owner's decision (`decide-github-push`).
* Ensure new scripts and tests are tracked. Untracked files cannot be restored
  by checkout, stash, or revert.
* Back up files to `/tmp` before restructuring them.
* Use `git log`, not stale hashes copied into documentation.
* `.gitignore` excludes `*.resource_order` and `Build`; GameMaker recreates the
  former after a clean checkout.

### 1.3 Line endings

GML files may be LF, CRLF, or mixed; `objects/**` events often use CRLF with
LF-only blank lines. `.gitattributes` normalizes stored files to LF. Always use
`gm.gml.read_gml` / `write_gml` to preserve the working file's existing bytes.

```bash
grep -cF '\r' <file.gml>  # literal backslash-r: must be 0
t=$(wc -l < <file.gml>); c=$(grep -c $'\r$' <file.gml>); echo "$t lines, $c crlf"
```

For CRLF-only files, the two counts must match. See
[LL-006](./lessons_learned.md#ll-006) for the full census.

---

## 2. Verification gates — run these before you claim anything is fixed

```bash
cd /home/rayu/GameMakerProjects/pushing_daisies_recovered

# 1. every .yy/.yyp/.resource_order round-trips byte-for-byte
#    expect: `0 differ`
#    (the COUNT grows as resources are added - a *drop* is the signal, not a
#     change in the number)
PYTHONPATH=python_tools python3 -m gm roundtrip

# 2. toolkit test suite
#    expect `OK`; the count must not drop, and adding n tests must raise it by n
#    (a suite that cannot notice a missing test has a hole, LL-041)
PYTHONPATH=python_tools python3 -m unittest discover -s python_tools/tests

# 3. the GML you changed still parses, and has the functions you expect
PYTHONPATH=python_tools python3 -m gm gml-functions scr_menu_state
PYTHONPATH=python_tools python3 -m gm gml-get Menu --event Step_0
PYTHONPATH=python_tools python3 -m gm info Menu           # type, events, functions
PYTHONPATH=python_tools python3 -m gm list GMScript       # spot built-in collisions

# 4. no stray escapes in the files you touched (each must print 0)
grep -cF '\r' objects/Menu/Step_0.gml

# 5. the balance tester still has every number it needs (reads the GML tables)
#    expect: "ok        the tester has every number it needs"
PYTHONPATH=python_tools python3 -m gm balance check

# 6. the tracker still describes reality (section 6)
#    expect: "progress.json, PROGRESS.md and progress.html agree"
PYTHONPATH=python_tools python3 -m gm progress check

# 7. the layout gate - only after a run with global.devMode = true that has
#    opened the meta screens (the F12/GUI dump lives in the log, not on disk)
#    expect: "ok  ..." and exit 0; a finding is a rectangle in the wrong place,
#    and an INCOMPLETE block (no `end` line, or fewer items than it declared)
#    also exits 1 - that is a run that died mid-dump, not a clean screen (LL-070)
PYTHONPATH=python_tools python3 -m gm layout check <the run's log>
```

**Green tooling is not a fix.** The real gate is a run with
`global.devMode = true`, after the user has **reloaded the project**. Give them
the exact log lines to look for, and name what would falsify your fix.

---

## 3. Codebase map

| Area | Where |
| --- | --- |
| Title menu (state machine = `enum` + `switch`) | `objects/Menu/{Create_0,Step_0,Draw_0,Draw_64}.gml` |
| **Level boot** (the one place a stage begins) | `rooms/rm_test/RoomCreationCode.gml` → `scripts/scr_level_boot` - idempotent, runs on EVERY entry to the stage room, after every instance Create ([LL-049](./lessons_learned.md#ll-049)). Never boot a level from an instance Create |
| Level flow (state machine = `enum` + `switch`) | `scripts/scr_level_state` → `scr_level_{start,spawn,wait,clear}`; `_mainControl` startup → cutscene → `_levelControl` |
| **Monster flow** (state machine = `enum` + `switch`; **DEATH is a state**) | `scripts/scr_zomb_state` → `ZOMB_STATE {NONE,EMERGE,PATH,DIE}`, `scr_zomb_{state_name,request,begin,step}` (request/apply, like the Menu). States: `scr_zombie_emerge`, `scr_zombie_path`, `scr_zombie_die`; `scr_zomb_death` is the **kill only** and requests DIE. The life check lives in `scr_zomb_step`, **before** the switch, so no state can miss a death ([LL-080](./lessons_learned.md#ll-080)) |
| **Monster art (the rig)** | `scripts/scr_mon_roster` — `mon_roster_build(spawn_mon, spawn_boss)` runs **once**, at the end of `scr_setupSpawning`, and caches a struct per creature in `global.mon_roster`; `mon_rig_find(name)` hands one to each spawn, `zomb_rig()` gives a state the calling monster's, and `mon_rig_slot(rig, ZOMB_ANIM.die)` / `mon_rig_play(...)` read and play a slot **by name**. The struct is shared and read-only: never `sprite_array[n]`, never `art[3]` ([LL-081](./lessons_learned.md#ll-081)) |
| Menu states, state-change, debug dump | `scripts/scr_menu_state/scr_menu_state.gml` — `MENU_STATE`, `scr_menu_state_name`, `scr_menu_changeState`, `scr_menu_debug`, `scr_menu_debug_buttons` |
| Button object (all buttons are `_button`) | `objects/_button/{Create_0,Step_0,Draw_0,Draw_64}.gml` → `scr_iniButton()`, `scr_stpButton()` |
| Button plumbing | `scripts/scr_setup_menuStates`, `scr_create_button`, `scr_button_index_{enable,disable,hide}`, `scr_button_greyout`, `scr_scaleButton` |
| Button callbacks | `scripts/fcn_button_{new,cont,options,quit,return,test}/` |
| Fade | `scripts/{fadeout,ini_fadeout,draw_fadeout,draw_reset}`, `objects/_fadeout/` |
| Globals | `scripts/initialize_game/initialize_game.gml` — `global.devMode`, `global.saveName`, `global.startRoom` |
| Logging | `scripts/print/print.gml` (already gated on `global.devMode`) |
| **Statuses** (slow now; stun/burn/poison/root/bleed/vuln are declared) | `scripts/scr_status/scr_status.gml` — `STATUS`, `status_apply`, `status_tick`, `status_speed_mult`, `status_tint`, `status_summary`. One instance per kind per monster; the monster owns `statuses` + `status_count` (obj_mon/Create_0) and ticks it LAST in obj_mon/Step_0; the speed multiply is in `scr_zomb_pathSpeed` |
| **Tower traits** (a status on hit, a crit chance) | `scripts/scr_tower_roster/scr_tower_roster.gml` — `tower_trait_table()`, `tower_trait_find`, `tower_trait_get`. Keyed by tower NAME, kept out of `scr_towerData` so the balance tester's 5-argument contract cannot drift (LL-038). Applied in `scr_tower_shoot` at the strike |
| **Progress tracker** | `progress.json` (source) → `PROGRESS.md`, `progress.html` (generated) — §6 |
| **Meta screens** (World Map, Deploy, Garden Book, Results) | `scripts/scr_meta_screen/scr_meta_screen.gml` — drawing and hit testing. **Their geometry is a flex tree**, read back by name (`meta_*_geom()`), never a hand-placed number: `scripts/scr_ui_layout_meta` ([LL-069](./lessons_learned.md#ll-069)) |
| **Layout trees** | `scripts/scr_ui_flex` (state, trees, `ui_rect`/`ui_place`/`ui_dump`) → `scripts/scr_ui_layout_{menu,meta}` (one function per screen) → `scripts/scr_ui_text` (`ui_fit_font`, `ui_clip_text`, `ui_palette`) |
| **Layout gate** | `scripts/scr_ui_check` dumps every painted rectangle once per screen per canvas size (F12 re-arms); `gm layout check <log>` rules on it (overlap / spill / image / off-canvas, exit 1); `gm layout metrics --log <log>` proves the font model matches the game |
| **Picture placement** (a sprite is placed by its ART rect, never its origin) | `scripts/scr_ui_image` — `ui_art_bbox`, `ui_art_scale` (fits the art, capped at 1), `ui_art_rect`, `ui_art_draw` (registers the rect it painted), `ui_art_fit`. `icon_draw` and `meta_sprite_fit` are both thin callers of it; the origin is read **once**, inside the draw, and never subtracted from a centre ([LL-071](./lessons_learned.md#ll-071)) |
| **Art briefs** (what to draw, canvas/origin/frames, what already exists) | `art_descriptions.md` — §3 the technical contract, §4 card by card |
| **Balance tester** | `python_tools/gm/balance/` — `gm balance {tables,route,towers,afford,sim,project,check,fit}`; reads the tables (and the shot cycle) out of GML, so it cannot drift ([LL-038](./lessons_learned.md#ll-038), [LL-040](./lessons_learned.md#ll-040)). `project` is the closed form (a ratio); `sim` time-steps the stage at 60fps and is the arbiter on outcomes ([LL-042](./lessons_learned.md#ll-042)) |
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
| switches | (driven by scripts, no dedicated object) | `scr_updateSwitch`, `scr_setupSwitch`, `scr_set_switch`, `scr_switch_hold`, `scr_switch_timer`, `scr_switch_toggle`, `scr_switch_oneShot` |

**Migrated so far:** the Menu (the reference implementation), the level flow
(`scr_level_state`) and the **monsters** (`scr_zomb_state`, [LL-080](./lessons_learned.md#ll-080)) —
all three are `enum` + `switch` with request/apply state changes.

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
  `instance_exists()`, `variable_instance_exists()`, `is_array()`, `is_callable()`,
  and `sprite_exists()` before any `sprite_get_*` — an object with no sprite has
  `sprite_index == -1`, which is a *fatal error* in GMS2
  ([LL-012](./lessons_learned.md#ll-012)).
* **Prefer `enum` + `switch`** over numeric state sentinels in anything you touch.
* **Log prefixes**: `MENU  `, `BTN   `, `FADE  `, `STAT  ` — keep them aligned so
  `grep -E 'MENU|BTN|FADE|STAT'` gives the whole trail. (`TOWER `, `PATH  `,
  `LOADOUT`, `SEED  ` are the same shape and already in use.) See
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
- [ ] `progress.json` updated for this task, and `gm progress check` is green (§6).

---

## 6. The progress tracker

Three files at the repo root, and only **one** of them is ever edited:

| File | What it is |
| --- | --- |
| `progress.json` | **The source of truth.** Cards and their fields, nothing else. |
| `PROGRESS.md` | **Generated.** Renders on GitHub and at the top of the project. |
| `progress.html` | **Generated.** The board: kanban columns, with a "waiting on you" strip on top. |

```bash
PYTHONPATH=python_tools python3 -m gm progress                     # check - this is the gate
PYTHONPATH=python_tools python3 -m gm progress build               # regenerate both views
PYTHONPATH=python_tools python3 -m gm progress list --awaiting rayu
PYTHONPATH=python_tools python3 -m gm progress set econ-rung-price status=done
PYTHONPATH=python_tools python3 -m gm progress add fix-thing title="Fix the thing" area=code
```

Editing the JSON by hand is fine — the gate catches typos — but `gm progress set`
keeps the canonical key order, which keeps the diffs small. Every generated file
carries a `progress-sha`, and `check` **fails** when any of the three disagree,
so "forgot to rebuild" is a red gate rather than a stale board.

### 6.1 The fields that matter

| Field | Values | Meaning |
| --- | --- | --- |
| `status` | `backlog` `next` `doing` `review` `done` | where the work is |
| `awaiting` | `rayu` `cline` `none` `external` | **whose turn it is** |
| `owner` | `rayu` `cline` `both` | who does the work |
| `area` | `code` `art` `sound` `design` `docs` `tools` `data` | what kind of work |
| `needs` | one line | **what the awaited person must actually do** |
| `phase` / `size` / `prio` | roadmap phase / `S` `M` `L` / `1` `2` `3` | the shape of the board |
| `refs` | real file paths (a `#fragment` is allowed) | **the gate checks they exist** |
| `focus.now` / `focus.next` / `focus.note` | card ids | what this session is on |

There is deliberately **no `blocked` status**: `awaiting != none` on an unfinished
card *is* blocked, so it cannot go stale. And a `backlog` card may not be
`awaiting` a person — the gate refuses it. If someone really has to act, the card
is `next`, not `backlog`. That way a name in the top strip always means "someone
is expected to move", instead of the strip slowly filling up with the wishlist.

Keep a card at the size of one session's work. If a card needs a sentence with an
"and" in it, split it.

### 6.2 When to touch it — part of the task, not optional cleanup

1. **Starting work** → `status=doing`, and set `awaiting` to whoever moves next.
2. **Handing something to the user** → `awaiting=rayu` **and a `needs` line**
   saying exactly what to do. The gate refuses an awaiting card with no `needs`.
3. **Finishing** → `status=done` (the CLI stamps the date and clears `awaiting`),
   then append a `log` line — the log is how progress becomes visible.
4. **Finding a new open question** → a new card, *never* a TODO comment.
5. Then `gm progress build` in the same change, or the gate goes red.

