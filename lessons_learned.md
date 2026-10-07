# Lessons Learned

Bug post-mortems for **Pushing Daisies** (`pushing_daisies_recovered`), a GameMaker
Studio 2 project imported from GameMaker 8 through the GMS2 project converter.

> ## Read this before you debug
>
> Nearly every bug in here took a long time because it **looks like something
> else**. A "broken button" was an array index; "greyed-out buttons" were an
> object index; "buttons that never appear" was an error in a *log* statement.
>
> **If a symptom matches an entry below, assume it is that bug until you have
> evidence otherwise** — start from the entry's fix, not from scratch.
>
> After you fix something that took more than a few minutes to understand,
> **add an entry** (template at the bottom). That is part of the task.

---

## Index

| ID | Symptom you notice | What it really is | Status |
| --- | --- | --- | --- |
| [LL-001](#ll-001) | Buttons greyed out / nothing fires; `active=0` on every button | An **empty array slot reads as `0`**, and `0` means *object index 0* = the `_button` object | **FIXED** |
| [LL-002](#ll-002) | The same error every frame; buttons never created; the rest of the event never seems to run | A runtime error **aborts the remainder of the event** — the line that would have created the variable never runs | **FIXED** |
| [LL-003](#ll-003) | `Variable Menu.<name> not set before reading it` from a helper; logs naming the wrong object | A function **cannot read another instance's variables**; scope must be passed in or switched with `with()` | **FIXED** |
| [LL-004](#ll-004) | Buttons that never fire; code that tests `script >= 0` | GMS1→GMS2: a **script is a function reference, not an index** | **FIXED** |
| [LL-005](#ll-005) | Engine functions behaving strangely | Project scripts **shadowing GameMaker built-ins** | **FIXED** |
| [LL-006](#ll-006) | Whole-file diffs; the file literally contains `\r` as text | **Mixed LF/CRLF** in the project, plus escape-unaware writing | **FIXED** |
| [LL-007](#ll-007) | Timings fire instantly or never; fades snap or hang | **`room_speed` is obsolete** in GMS2 (~35 files use it) | **PART FIXED** |
| [LL-008](#ll-008) | Your edit "reverted" / the file changed under you | **GameMaker has the project open** and saves from its own buffers | **WATCH** |
| [LL-009](#ll-009) | A one-value change produces a 1000-line diff | `.yy`/`.yyp` are **not JSON** — trailing commas, key order, inline containers | **FIXED** |
| [LL-010](#ll-010) | A state's "just entered" code runs twice, or never | **Changing state from inside a state** instead of requesting it for the next Step | **FIXED** |
| [LL-011](#ll-011) | — | **How to instrument the game** so the next bug takes one run, not ten | **METHOD** |
| [LL-012](#ll-012) | `sprite_get_height ... requested -1` once per step; a sprite flip that "does nothing" | A **text object has no sprite** (`sprite_index == -1`, fatal in GMS2) and the shared scale helper **overwrote `image_xscale`** | **FIXED** |
| [LL-013](#ll-013) | A zombie **freezes** on the map; the wave never ends; only a restart helps | A **placement that pockets a monster**, and a **discarded `mp_grid_path` return value** that made the failure silent | **FIXED** |
| [LL-014](#ll-014) | The pause / exit screen is **black** | **One variable doing two jobs** - `blackScreen` is the game-over crossfade, and pause read it; plus a surface **size mismatch** and a **mid-frame grab** | **FIXED** |
| [LL-015](#ll-015) | A UI is **missing information** that was never once displayed | **`array_last_index()` used as a count** hides the last element, and a label list that was never extended | **FIXED** |
| [LL-016](#ll-016) | Nothing - yet | A **sibling function's parameter is not in scope**, so a fatal sat behind an unreachable branch | **FIXED** |
| [LL-017](#ll-017) | A new "safety" guard crashes on a line that looks defensive, only before an object's Create has run | **`instance_exists()` on an unassigned `globalvar` is itself a read of an unset variable** | **FIXED** |
| [LL-018](#ll-018) | A check script reports "line endings changed" for files nothing touched; `git diff` says otherwise | Comparing against **`git show HEAD:`** compares a *normalised* blob (LF) against a CRLF working tree | **FIXED** |
| [LL-019](#ll-019) | Buttons that were "hidden" are **still drawn**, still hover, still beep, and sit over the screen that replaced them | **`visible = false` only affects the built-in sprite draw** - an object with its own Draw event must check it itself | **FIXED** |
| [LL-020](#ll-020) | `Unable to find instance for object index 1` from `_shadows` Draw, every frame, after finishing a level | A **persistent instance whose dependency did not persist** — `_shadows` survives the room change, `_dayCycle` does not | **FIXED** |
| [LL-022](#ll-022) | 60-wave stages come out either trivial or unbeatable, depending on which half gets landed first | The wave ramp and the tower-level ladder are **two curves that only mean something together** | **FIXED** |
| [LL-023](#ll-023) | The board's "waiting on you" strip slowly fills with parked work | A rule that lives in **prose only** — the validator checked each field's shape but never compared two fields | **FIXED** |
| [LL-021](#ll-021) | A stage can be Deployed to that has no level data, and it silently plays stage 1 | The world map's 6x10 grid and the authored stage table are **two sources of truth** that never compared | **FIXED** |
| [LL-024](#ll-024) | `Variable <caller>.<name> not set before reading it` for a name you *know* is a function; the numbers in the parentheses look like corrupt arguments | The function was **never defined** — GameMaker names the **calling scope**, and the parentheses are *(instance id, internal id)*, **not the arguments** | **FIXED** |
| [LL-025](#ll-025) | Monsters walk **north, straight through walls**, mid-wave, even when the level has a clear route; the wave then ends via the 6 s valve | A **draw-only `y` offset applied twice** (Pre Draw *and* Post Draw) that only bites once `Alarm_0` has **thrown the live path away on a failed re-path** — a monster with no path is a monster nothing rewrites | **FIXED** |
| [LL-026](#ll-026) | The same `Variable Input.<name> not set before reading it` every step, naming a function that event never calls | A **saved function reference**: an array of listeners (`key_type`) was persisted through `ds_list_write` and came back callable-but-stale - it ran whatever script the handle then indexed (see [LL-028](#ll-028)) | **FIXED** |
| [LL-027](#ll-027) | Pathfinding is still off: monsters take odd routes or cannot leave their pen, as if a tower or wall covered more than its cell; **no error** | **`mp_grid_add_rectangle`/`mp_grid_add_instances` floor BOTH edges and iterate INCLUSIVELY**, so a rectangle the size of one cell blocks two (a 2x2) — block a **cell by index** instead | **FIXED** |
| [LL-028](#ll-028) | The LL-026 error again, but naming a **different** script and an unrelated object, changing each rebuild | A saved function reference comes back **still callable**, on a handle that shifts when the project gains a script; `is_callable()` cannot spot it, so `key_type` must never be loaded | **FIXED** |

Tags for searching: `button` `menu` `array` `noone` `scope` `state machine`
`enum` `crlf` `room_speed` `built-in` `shadowing` `null` `log` `debug`
`flip` `image_xscale` `sprite_index` `sprite_get_width` `-1` `_text_rise`
`soft-lock` `path` `mp_grid_path` `return value` `pocket` `black` `pause`
`snapshot` `surface` `application_surface` `array_last_index` `scope`
`sibling` `parameter` `RNG` `perlin` `globalvar` `instance_exists`
`variable_global_exists` `guard` `git` `HEAD` `eol` `gitattributes`
`verifier` `false positive` `visible` `hide` `draw event` `button`
`draw_sprite_ext` `aspect ratio` `text wrap` `loadout`
`persistent` `room change` `_shadows` `_dayCycle` `day cycle`
`level start` `missing instance` `Unable to find instance`
`single source of truth` `world map` `level data` `level_exists`
`GameLevelData` `phantom stage` `deploy`
`undefined function` `not set before reading it` `Read Variable` `caller scope`
`function` `grep function` `tower_upgrade_price` `tower_sell_refund`
`coupled constants` `wave curve` `tower ladder` `exponential` `base-relative`
`region_data` `difficulty wiring` `money is quadratic` `balance` `rung price`
`executable rule` `invariant` `derived field` `checked-in artefact` `gate`
`climb` `z_climb` `pre draw` `post draw` `draw offset` `drift` `march north`
`no path` `path cache` `probe then commit` `phantom block` `grid_block`
`progress tracker` `single source of truth` `stale view`.
`key_type` `script_execute` `is_callable` `asset_get_index` `ds_list_write` `function reference` `saved binding` `_objSwitch`
`mp_grid_add_rectangle` `mp_grid_add_instances` `mp_grid_add_cell` `inclusive` `2x2` `footprint` `cell`
`callable but stale` `handle` `key_type` `ds_list_read` `never load a function` `obj_spawn` `scr_drawSwitchTimer` `purge slot`

---

<a name="ll-001"></a>
## LL-001 — An empty array slot is `0`, and `0` means "object index 0", not "nothing"

**Symptom.** The title menu's buttons draw greyed out and/or do nothing when
clicked. The debug log shows `active=0` for buttons that nothing ever disabled.
Worse, a loop that should touch *one* button touches *all* of them.

**Root cause.** The Continue button is commented out in
`scr_setup_menuStates`, so `menu_button[1]` was **never assigned**. Reading an
unassigned array index yields `0` — and in GMS2 `0` is a perfectly valid
*object index*, not "nothing". Object index 0 in this project is `_button`.

So a slot helper doing `with(_arr[_id])` ran its body with `self` set to
**every `_button` instance in the room**:

```gml
for_array(menu_options, scr_button_index_disable);   /// disabled the whole menu
```

Same trap applies to `instance_exists(0)`, `with(0)`,
`position_meeting(x, y, 0)` and collision checks.

**Fix (both halves are needed).**

1. Never leave a hole — mark it explicitly:

```gml
///menu_button[1] = scr_create_button("Continue",_x,_y,fcn_button_cont);
menu_button[1] = noone;   /// explicit empty slot
```

2. Every consumer of an array slot validates it *before* using it:

```gml
var _inst = _arr[_id];
if(_inst == undefined || _inst == noone || _inst == 0 || !instance_exists(_inst)){
    print("BTN   enable  ", _id, " skipped - slot is not a live instance");
    exit;
}

with(_inst){
    visible = true;
    active  = true;
}
```

**Guard rails.**

* `undefined`, `noone` and `0` are all "not a button" — test all three.
* Anything taken from an array and handed to `with()` / `instance_exists()` /
  `position_meeting()` / a collision check must be validated first.
* If a batch operation like "disable all buttons" affects things it shouldn't,
  suspect an empty slot long before you suspect the loop.

**Files.** `scripts/scr_setup_menuStates/scr_setup_menuStates.gml`,
`scripts/scr_button_index_enable|disable|hide/*.gml`, `objects/Menu/Step_0.gml`.

---

<a name="ll-002"></a>
## LL-002 — A runtime error aborts the rest of the event (the initialisation deadlock)

**Symptom.** This, repeating forever, every frame — and the buttons are never
created no matter how long you wait:

```
ERROR in action number 1
of  Step Event0 for object Menu:
Variable Menu.menu_button(100843, -2147483648) not set before reading it.
 at gml_Script_scr_menu_debug (line 62) - 	scr_menu_debug_buttons("menu_button", _menu.menu_button);
############################################################################################
gml_Script_scr_menu_debug (line 62)
gml_Object_Menu_Step_0 (line 12) -     scr_menu_debug(id, "state entered");
```

Everything in the event *after* the error line is silently skipped.

**Root cause.** `menu_button` / `menu_options` were only ever *written* by
`scr_setup_menuStates()`, which is called **further down the same Step** (line 26).
A newly added *debug* read at the top of that Step (line 12) referenced them
first, so:

```
frame 1:  line 12  read menu_button      -> NOT SET -> runtime error -> Step 0 ABORTS
          line 26  scr_setup_menuStates()            -> never runs
frame 2:  identical                                  -> forever
```

A `print()` statement destroyed the feature it was meant to diagnose.

**Three rules, all learned the hard way.**

1. **Initialise instance variables in Create.** Never rely on some later
   function in the same event to bring a variable into existence.
2. **A diagnostic must never be able to throw.** Logging runs *before* the code
   it inspects, so an error in a log changes behaviour and deletes your
   evidence. Guard every read: `variable_instance_exists()`, `is_array()`,
   `instance_exists()`, `is_callable()`.
3. When the **same error repeats every frame**, think *"the event aborts before
   it can repair the cause"* — not *"that code is never reached"*.

**Fix.**

```gml
/// objects/Menu/Create_0.gml
menu_button  = [];
menu_options = [];
```

```gml
/// scripts/scr_menu_state/scr_menu_state.gml  -  only dump what exists
if(variable_instance_exists(_menu, "menu_button")){
    scr_menu_debug_buttons("menu_button", _menu.menu_button);
} else {
    print("        menu_button not set yet");
}
```

```gml
/// scripts/scr_setup_menuStates/scr_setup_menuStates.gml
/// start from empty arrays - never rely on implicit array creation
menu_button  = [];
menu_options = [];
```

**Files.** `objects/Menu/Create_0.gml`, `objects/Menu/Step_0.gml`,
`scripts/scr_setup_menuStates/scr_setup_menuStates.gml`,
`scripts/scr_menu_state/scr_menu_state.gml`.

---

<a name="ll-003"></a>
## LL-003 — Functions cannot read another instance's variables (scope discipline)

**Symptom.** `Variable Menu.<name> not set before reading it` thrown *from a
helper*; or a debug dump that reports the wrong object name, or `- not a button`
for things that clearly are buttons.

**Root cause.** Two bad habits in the same helper:

1. It was written as though the caller's scope were the Menu — it used bare
   `menu_state`, `menu_button`, so it only worked when called from the Menu's
   Step and threw from anywhere else.
2. It read a button's variables *from outside the button* (`_b.text`,
   `_b.active`) and decided what it was looking at from the **caller's**
   `object_index` — which is the Menu, so the `object_index == _button` test
   never matched and every slot printed as "not a button".

**Fix — pass it in, or switch scope with `with()`.**

```gml
/// The Menu instance is passed in, so this can be called from ANY scope and
/// nothing is looked up in the caller's instance.
function scr_menu_debug(_menu, _where) {
    if(!instance_exists(_menu)){ ... return; }
    if(!variable_instance_exists(_menu, "menu_state")){ ... return; }
    print("MENU  [", _where, "] state=", scr_menu_state_name(_menu.menu_state), ...);
    scr_menu_debug_buttons("menu_button", _menu.menu_button);
}
```

```gml
/// read the button's own variables in the button's own scope
with(_b){
    print("          [", _slot, "] '", text, "' active=", active, " visible=", visible, " id=", id);
}
```

**Rules.**

* **Pass what a function needs as arguments** — `scr_menu_debug(_menu, _where)`,
  `scr_button_index_enable(_arr, _i)`. Never assume `self`.
* **Read another instance's variables inside `with()`** — that is the one place
  GML switches scope for you. Prefer `with(_inst){ print(text) }` over
  `_inst.text` in diagnostics: `print()` uses `object_index`, so inside `with()`
  it names the *right* object automatically.
* Guard with `instance_exists(_inst)` and
  `variable_instance_exists(_inst, "text")` before trusting a reference.
* A helper that *must* be called "with X in scope" (and cannot take the instance
  as a parameter) is a smell — document the contract in the function's header
  comment, e.g. `scr_menu_changeState(_new_state)` starts with
  "Must be called with the Menu instance in scope".

**Files.** `scripts/scr_menu_state/scr_menu_state.gml`,
`scripts/scr_stpButton/scr_stpButton.gml`, `scripts/scr_button_index_*/*.gml`.

---

<a name="ll-004"></a>
## LL-004 — GMS1→GMS2: a script is a function reference, not an index

**Symptom.** Buttons that are visible, enabled and hoverable but **never fire**.
Code that looks like a validity check and always takes the same branch.

**Root cause.** Legacy GM8/GMS1 code stored *numeric script ids* and tested them:

```gml
script = fcn_button_new;     /// fine in GMS2 (a function reference)
...
if(script >= 0){ ... }       /// always true in GMS2 - means nothing
script_execute(script);      /// ok, but with no way to detect a bad value
```

After the converter, `script` holds a function reference (or `undefined`), so
`script >= 0` is meaningless. The same class of bug: state machines that stored
a *script* in `state` and compared it with numeric sentinels
(`if(state < 0)`, `state == 1`, `state += 1`).

**Fix.** Ask the language:

```gml
if(is_callable(script)){
    print("BTN   call   '", text, "'");
    script_execute(script);
} else {
    print("BTN   SKIP   '", text, "' - script is not callable");
}
```

and replace numeric state sentinels with a real `enum` + `switch`
(`MENU_STATE` + `objects/Menu/Step_0.gml`). The 6 absorbed `state_menu_*`
scripts were deleted in this refactor.

**Guard rails.**

* When touching imported legacy code, grep for `script >=`, `script <`,
  `script ==`, `script_execute(` and `state == <number>` and audit every hit.
* `is_callable()` is the only reliable "is this a function?" test.
* Prefer `enum` + `switch` over magic numbers for any state machine you touch.

**Files.** `scripts/scr_stpButton/scr_stpButton.gml`,
`scripts/fcn_button_*/*.gml`, `objects/Menu/Step_0.gml`,
`scripts/scr_menu_state/scr_menu_state.gml`, `scripts/scr_runState/scr_runState.gml`.

---

<a name="ll-005"></a>
## LL-005 — Project scripts that shadow GameMaker built-ins

**Symptom.** An engine call behaves like a 2009 homebrew implementation, or you
cannot tell which version of `array_pop` you just called.

**Root cause.** The project shipped its own scripts named exactly like GMS2
built-ins: `array_concat`, `array_insert`, `array_pop`, `instance_create_depth`.
Inside the project the project's script wins, so any call anywhere silently gets
the legacy behaviour and the built-in becomes unreachable.

**Fix.** Those four scripts were deleted (backup kept in `/tmp/gmfix_backup/`).

**Guard rails.**

* After importing legacy code, list scripts and diff the names against the GMS2
  function reference; rename (`scr_…`) or delete collisions:
  `python3 -m gm list GMScript`
* Be suspicious of any helper whose name is a bare engine verb
  (`array_*`, `instance_*`, `draw_*`, `string_*`).

---

<a name="ll-006"></a>
## LL-006 — Mixed LF/CRLF, and `\r` that ends up in the file as literal text

**Symptom.** A one-line edit produces a whole-file diff — or the file literally
contains the two characters `\` and `r` sprinkled through the source, which GML
then reads as text.

**Root cause.** Two separate traps:

1. **The project mixes line endings — including *inside* a single file.** A census
   of the 465 `.gml` files gives **375 LF-only | 89 mixed | 1 CRLF-only**
   (`objects/Menu/Step_0.gml`). The mixed files are almost all `objects/**` event
   files, and the difference is always the **blank lines**: real lines end `\r\n`,
   empty lines end with a lone `\n`, e.g. `objects/_levelControl/Step_0.gml`
   reports `crlf 162 | lone_lf 5` and `objects/_mainControl/Step_0.gml` contains
   `...scr_runState(scr_main_startup);\r\n\n`. So "the line endings of this file"
   is not even a single answer. `.gitattributes` says `*.gml text eol=lf`, which
   means **git stores LF and normalises the working tree on the next checkout** —
   harmless for GameMaker (it reads both) but it *will* rewrite ~90 files' bytes.
2. **"Modify the file" scripts that are not escape-aware.** Writing a
   replacement like `"\r\n"` through a tool that does not interpret the escape
   puts the *literal characters* `\r` into the source file.

**Fix / guard rails.**

* Read and write GML through the toolkit (`gm.gml.read_gml` / `write_gml`) — it
  never touches line endings, whatever the file uses:
  `python3 -m gm gml-get Menu --event Step_0`
* After any edit, census the bytes. This one is escape-proof (92 = `\`, 114 = `r`):

```bash
python3 - <<'PY'
import sys
for f in sys.argv[1:]:
    b = open(f, 'rb').read()
    crlf = b.count(b'\r\n')
    print(f, '| crlf', crlf, '| lone_lf', b.count(b'\n') - crlf,
          '| lone_cr', b.count(b'\r') - crlf,
          '| literal_backslash_r', b.count(bytes([92, 114])))
PY
```

* Classify the whole project when EOL questions come up:

```bash
python3 - <<'PY'
import os
crlf = lf = mixed = 0
for root, dirs, files in os.walk('.'):
    if '.git' in root.split(os.sep): continue
    for f in files:
        if not f.endswith('.gml'): continue
        b = open(os.path.join(root, f), 'rb').read()
        c = b.count(b'\r\n'); l = b.count(b'\n') - c
        if c and l: mixed += 1
        elif c:     crlf  += 1
        else:       lf    += 1
print('CRLF-only', crlf, '| LF-only', lf, '| MIXED', mixed)
PY
```

```
CRLF-only 1 | LF-only 375 | MIXED 89        (2026-10-03, 465 .gml files)
```

```bash
grep -cF '\r' objects/Menu/Step_0.gml     # fixed-string: must print 0
```

* Never "normalise" line endings as a side effect of an edit. Preserve what is
  on disk and let the IDE/git decide.

---

<a name="ll-007"></a>
## LL-007 — `room_speed` is obsolete in GMS2  *(OPEN — not yet fixed)*

**Symptom.** Timers fire immediately or never; `state_time > room_speed*0.5`
behaves like `> 0`; a fade either snaps to black or hangs instead of fading.
`scr_drawSwitchTimer` shows nonsense.

**Root cause.** `room_speed` is on GameMaker's **Obsolete Functions** list. This
project still uses it in ~35 places — `objects/Menu/Step_0.gml` (four states),
`scripts/scr_stpButton`, `scripts/fadeout`, `scripts/scr_main_*`,
`scripts/scr_set_switch`, `scripts/scr_level_*`, `objects/obj_mon`,
`objects/_spawn`, `objects/_waveNum`, `objects/obj_title`, `objects/obj_titleZomb`,
`scripts/scr_position_next`, `scripts/scr_tower_*` … — and
`scripts/scr_setFrameSkip` **writes** `room_speed = 60 / 180`.

**Diagnosis (already instrumented).** `fadeout()` prints the value it actually
saw:

```
FADE  -> <room> in <n>s  (room_speed=… -> … alpha/frame; would take … frames)
```

If that prints `room_speed=0`, `fade.fade_speed = room_speed/argument2` is `0`,
the alpha never reaches 1 and the fade never completes.

**Fix (once confirmed).** Replace every read with
`game_get_speed(gamespeed_fps)`, and set the speed with
`game_set_speed(60, gamespeed_fps)` instead of `room_speed = 60`. Do it in one
pass and re-check the timings of every affected script.

---

<a name="ll-008"></a>
## LL-008 — GameMaker (the IDE) owns the project files while it is open

**Symptom.** An edit "reverts" by itself; a file has different contents than you
wrote; `.yy`/`.resource_order` change while you are not touching them.

**Root cause.** The IDE keeps resources in memory and rewrites `.yy`, `.yyp`,
`.resource_order` and any **open** event/script file when it saves — from *its*
buffers, not from disk. Anything written outside the IDE for those resources is
silently overwritten.

**Fix / guard rails.**

* **Before editing**: ask the user to close the file/project in GameMaker, or at
  least to not save from it.
* **Before they test**: the project must be **reloaded**, otherwise the running
  build is the old code (a reload *does* pick up external edits — it did here).
* After the IDE has saved, re-read the files to confirm your change survived; the
  `.resource_order` mtime is a good tell that something saved.
* **This working copy had no `.git` directory until 2026-10-03** (`git status`
  used to fail). A local repo now exists with a single initial commit and no
  remote — and because `.gitattributes` normalises `.gml` to LF, a `git
  checkout` can rewrite ~90 files' line endings. There is still effectively no
  safety net: copy files to `/tmp` before bulk edits, as was done with
  `/tmp/menu_refactor_backup/` and `/tmp/gmfix_backup/`.

---

<a name="ll-009"></a>
## LL-009 — `.yy`/`.yyp` are not JSON: never edit them with JSON tooling

**Symptom.** Changing one value turns into a 1000-line diff, or the IDE
mis-reads the file afterwards.

**Root cause.** GameMaker's resource format is *almost* JSON:

* every object member and array element has a **trailing comma**;
* object keys are sorted **case-insensitively with `_` last** (`bboxMode` before
  `bbox_bottom`);
* nested containers are sometimes written **inline** and sometimes spread over
  lines — decided by the resource schema, not a simple rule;
* LF, no trailing newline; `%Name` and `$GMxxx` keys are part of the format.

A generic `json.dumps` round-trip rewrites all of that.

**Fix.** Use `python_tools/gm`, which keeps the real layout and only changes the
value you asked for:

```bash
python3 -m gm get-path spr_flower origin
python3 -m gm set-path spr_flower origin 4
python3 -m gm sort spr_flower          # only when you *want* canonical order
python3 -m gm roundtrip                # MUST print: 566 file(s) ... 0 differ
```

**Guard rail.** Any structural edit is finished only when `roundtrip` reports
**0 differ** and the test suite is green.

---

<a name="ll-010"></a>
## LL-010 — "Request the next state, apply it at the top of the next Step"

**Symptom.** A state's "just entered" block runs **twice**, or never; buttons get
created more than once; identical hover/click log lines appear several times at
the same timestamp; an initialisation is skipped entirely.

**Root cause.** A state handler that changes state *while it is running*:

```gml
case MENU_STATE.SOMETHING:
    ...
    menu_state      = MENU_STATE.OTHER;   /// applies immediately
    menu_state_time = 0;
```

The `menu_state_time == 0` blocks are guarded by the time counter, so mutating
`menu_state` mid-frame can re-enter an initialiser in the same frame (or skip
one) depending on the switch's shape. The old code additionally derived states
from script references and numeric sentinels (see LL-004).

**Fix.** Separate *requesting* from *applying*:

```gml
/// scratch: only records the request
function scr_menu_changeState(_new_state) {
    print("MENU  request ", scr_menu_state_name(menu_state), " -> ", scr_menu_state_name(_new_state));
    menu_state_next = _new_state;
}
```

```gml
/// objects/Menu/Step_0.gml - applied at the top of the NEXT step, so every
/// state gets exactly one frame with menu_state_time == 0
if(menu_state_next != -1){
    menu_state_prev = menu_state;
    menu_state       = menu_state_next;
    menu_state_next  = -1;
    menu_state_time  = 0;
    print("MENU  now ", scr_menu_state_name(menu_state));
    scr_menu_debug(id, "state entered");
} else {
    menu_state_time++;
}
```

**Guard rails.**

* A state machine should have exactly **one** place that assigns the state
  variable, and it should be the first thing the Step does.
* Give every state a `time == 0` frame and put all "on entry" work in it.
* If an initialiser seems to run twice, check who else writes the state variable.

**Files.** `objects/Menu/Step_0.gml`, `scripts/scr_menu_state/scr_menu_state.gml`,
`scripts/fcn_button_*/*.gml`.

---

<a name="ll-011"></a>
## LL-011 — How to instrument, so the next bug takes one run instead of ten

Not a bug — the method that finally made LL-001 and LL-002 obvious.

* `print()` (in `scripts/print/print.gml`) is already dev-gated by
  `global.devMode` and prefixes every line with the time, the object name of the
  current scope and an instance id, e.g.
  `Menu:100843    MENU  [state entered] state=START time=0 next=-1`.
* **Use prefixes** so one grep gives you the whole trail:
  `MENU  `, `BTN   `, `FADE  `, `SND   `.
  ```bash
  grep -E 'MENU|BTN|FADE' debug.log
  ```
* Log at these points and nowhere else by default:
  * every **button create / init** (`BTN   create`, `BTN   init`);
  * every **click** and the decision after it (`BTN   click`, `BTN   call`,
    `BTN   SKIP`);
  * every **state entry** (`MENU  now`, then a full dump);
  * every **array dump** — index, text, `active`, `visible`, `id`, and the words
    `noone` / `undefined` / `0` for bad slots;
  * every **fade** with the speed value it computed.
* Dump state *before* acting on it, then again after the action, so the log shows
  the transition rather than just a final value.
* **A line that repeats identically every frame is a loop**, not a one-off — go
  read LL-002.
* Never let a log line throw (LL-002): guard every variable you read.

---

<a name="ll-012"></a>
## LL-012 — A text object has no sprite, so `sprite_get_width(-1)` is fatal (and rescaling eats your flip)

**Symptom.** The console fills with this **once per step, for as long as any
`_text_rise` exists**, so the error you are actually chasing is buried:

```
ERROR in action number 1
of  Step Event0 for object _text_rise:
sprite_get_height argument 1 invalid reference to (sprite) - requested -1 max is 122
 at gml_Script_scr_scale_sprite (line 11) - 	image_yscale = argument1/sprite_get_height(sprite_index);
gml_Script_scr_scale_sprite (line 11)
gml_Object__text_rise_Step_0 (line 20) - scr_scale_sprite(_w,_h);
```

Usually reported together with *"my `image_xscale = -1` flip does nothing"*.

**Root cause.** Two GM8 habits that GMS2 does not forgive:

1. `_text_rise` draws text and has **no sprite** — `"spriteId":null` in
   `objects/_text_rise/_text_rise.yy` — so `sprite_index == -1`. In GM8
   `sprite_get_width(-1)` returned `0`; in GMS2 it is a **fatal error**, and
   because the call sits in a Step it repeats every frame. The call is
   vestigial: its comment says "resize text object for collisions", but no
   sprite means no mask to resize (`place_meeting` / `scr_collide()` are inert
   there for the same reason).
2. `scr_scale_sprite(w,h)` ended in plain assignments, so it **overwrote both
   scales**: a flip applied before the call was gone by the next frame, and it
   divided by the sprite size, which is invalid when there is no sprite.

**Fix.** `scripts/scr_scale_sprite/scr_scale_sprite.gml` — guard, then keep the
facing:

```gml
	/// an object with no sprite has no dimensions to scale to, and
	/// sprite_get_width(-1) is a *fatal error* in GMS2 (GM8 quietly
	/// returned 0), so bail out instead of erroring every step - LL-012
	var _spr = sprite_index;
	if(is_undefined(_spr) || _spr < 0 || !sprite_exists(_spr)) return;

	var _sw = sprite_get_width(_spr),
	    _sh = sprite_get_height(_spr);

	/// a zero sized sprite would divide by zero
	if(_sw <= 0 || _sh <= 0) return;

	/// a negative dimension flips that axis; otherwise keep whatever
	/// facing the instance already has, so a flip is not undone here
	var _flipx = (argument0 < 0 || image_xscale < 0) ? -1 : 1,
	    _flipy = (argument1 < 0 || image_yscale < 0) ? -1 : 1;

	image_xscale = abs(argument0) / _sw * _flipx;
	image_yscale = abs(argument1) / _sh * _flipy;
```

**Flipping on x — pick the row that matches what you are flipping.**

| Flipping | Write | Why |
| --- | --- | --- |
| an object that has a sprite | `image_xscale = -abs(image_xscale);` to face left, `abs(...)` to face right | the manual: negative values flip the sprite, exactly `-1` is a flip with no scaling. Project idiom: `scripts/scr_zomb_updatePosition` lines 10-14 |
| a sprite whose size `scr_scale_sprite` sets | `scr_scale_sprite(-w, h);`, or set the flip and let it survive | the helper now rescales by magnitude and keeps a negative sign |
| `_text_rise` or any text object | nothing in the Step — give `Draw_64`'s `draw_text_outline_scaled(...)` a negative `xsc` | `image_xscale` scales *the sprite assigned to the instance*; a text object has none, so there is nothing for it to flip |

Never flip with `image_xscale = sign(...)`: `sign(0)` is `0`, so a mouse exactly
on the instance makes it invisible for a frame and clamps the scale to ±1.
`objects/obj_titleZomb/Step_0.gml` line 44 still does this.

**Guard rails.**

* **A helper that reads `sprite_index` must survive `sprite_index == -1`** —
  test `sprite_exists()` (or `< 0`) before any `sprite_get_*`, and treat "no
  sprite" as "nothing to scale", never as a 0×0 sprite.
* **Before blaming a flip, find what re-derives the scale every step** —
  `scr_scale_sprite`, `scr_scaleButton` or a `lerp` scale tween overwrites
  `image_xscale` on every call.
* An object with no sprite has no mask, so `place_meeting()`,
  `position_meeting()` and `bbox_*` are dead code in it.

**Status.** FIXED, 2026-10-03.

**Files.** `scripts/scr_scale_sprite/scr_scale_sprite.gml`;
`objects/_text_rise/Step_0.gml` line 20 (now a harmless no-op);
`objects/_text_rise/_text_rise.yy` (`spriteId` is `null`).

---

<a name="ll-013"></a>
## LL-013 — A discarded return value is a silent failure (and validate the whole system, not the entrance)

**Symptom.** A tower placed so that it seals a monster's route leaves the
monster **frozen**. The wave never ends, so the run is dead, and only a restart
recovers it. No error, no log — the zombie just stands there.

**Root cause.** Four separate defects that all look like "blocking the path
glitches", and any one of them alone freezes a wave:

1. The placement check validated only `spawn → despawn`. A tower that left the
   **spawn** connected but pocketed a monster *already on the map* was accepted.
2. The pocketed monster re-pathed from its own position, got `false`, and was
   left with an **empty path** — it stopped where it stood.
3. The retry loop re-ran for ever with the identical result: same grid, same
   start cell, same failure. Nothing ever changed.
4. **The first path discarded its return value.** `scr_zombie_path` called
   `mp_grid_path(...)` without capturing it, while `Create_0` had already set
   `path_free = true`. So a failed *first* path was completely silent: the
   monster walked forward on an empty path for ever and never even scheduled a
   retry.

Defect 4 is the one that explains "forever". A fifth vector existed too — a
tower could be placed **on the cell a monster was standing in**, because the
test only asked `position_meeting(x,y,obj_tower)`.

**Fix.** Refuse, then always heal.

```gml
/// scripts/scr_path_validate - one place that answers "is this walkable"
scr_path_try(_grid,_x1,_y1,_x2,_y2,_path)          /// clear, then mp_grid_path
scr_path_cell_blocked_by_monster(_x,_y,_r)         /// is a monster in this cell
scr_path_all_monsters_ok(_grid,_path,_to_x,_to_y)  /// can EVERY one still get out
```

* A placement is refused if a monster occupies the cell, if the spawn route is
  sealed, **or if any monster on the map cannot reach the despawn**. That last
  check is what makes a pocket impossible by construction.
* `scr_zombie_path` captures the return value and schedules a retry on failure.
* The monster's re-path alarm **escalates**: after ~2 s of polite retrying it
  walks an **empty grid**, ignoring the towers entirely, so
  `instance_number(obj_mon)` can always reach `0`.
* `scr_level_wait` has a last-resort valve: monsters alive 6 s past the wave
  timer are cleared, with a loud `PATH` warning.

**Guard rails.**

* **Capture every return value** that reports success/failure. `mp_grid_path`,
  `file_*`, `ds_map_*` — `if(!ok){ ... }` on the same line as the call is the
  cheapest guard you will ever write. A discarded `false` becomes "it just
  doesn't work sometimes", which is the most expensive kind of bug.
* **Validate the whole system, not the entrance to it.** "Is the spawn still
  connected?" is not "can everything on the map still get out?".
* **Any loop that can retry with identical inputs is an infinite loop.** If a
  retry cannot change its inputs, it must change its *strategy*.
* A soft-lock is the worst class of bug: in a 60-stage campaign it costs the
  player the whole session. **Every wave must be able to end.**

**Status.** FIXED, 2026-10-04.

**Files.** `scripts/scr_path_validate`, `objects/obj_mon/Alarm_0.gml`,
`objects/obj_mon/Create_0.gml`, `objects/obj_mon/Collision_obj_tower.gml`,
`scripts/scr_zombie_path`, `objects/obj_tower_edit/Step_0.gml`,
`objects/obj_tower/Destroy_0.gml`, `scripts/scr_level_wait`.

---
<a name="ll-014"></a>
## LL-014 — One variable doing two jobs: the pause screen went black

**Symptom.** Pausing blacks the screen. The game image is neither captured nor
displayed, so the pause menu has nothing to sit on.

**Root cause.** `blackScreen` drives the **GAME OVER crossfade into the high
score table**. The pause path read it as if it were its own fade:

```gml
draw_sprite_ext(pause_surf,0,0,0,1,1,0,c_white,clamp(1-blackScreen,0,1));
```

So a pause **after a game over** inherited `blackScreen == 1` and drew the
snapshot at **alpha 0**. `scr_draw_main_text` line 12 does
`text_alpha*(1-blackScreen)` too, so the PAUSED text was invisible as well.
Black was the *correct* output of that arithmetic — the bug was the input.

Two more defects were waiting behind it:

* **Size mismatch.** The snapshot surface was created at GUI size, while
  `application_surface` is resized to `ideal_width/ideal_height` by
  `scr_initResolution`. Drawing one into the other leaves the remainder as the
  `draw_clear_alpha(c_black,1)` fill — most of the frame.
* **Mid-frame capture.** The grab ran part-way through Draw. On this project the
  ground sits at a negative depth and the towers and monsters at about `-60`,
  all of which draw **after** depth 75 — so a mid-frame grab captures almost
  nothing, which also reads as black.

**Fix.** Three changes, each of which independently prevents black:

* Capture at the **application surface's own size** and draw the result
  **stretched to the GUI size**, so no size assumption survives anywhere.
* Pause gets its **own** alpha (`pause_alpha`) and resets `blackScreen = 0` on
  entry. The black score background is gated on the **state**
  (`gameOver`/`highScore`), not on `blackScreen` alone.
* The grab moved to the **very top of Draw_75** — which is the Draw GUI End
  event (75), the *last* pass of the frame, so `application_surface` is fully
  composed there.
* **Never-black promise:** with no usable snapshot, draw the text over the
  existing screen and skip everything that could darken it. The worst case is
  "pause without the blur", never "pause with nothing".

**Guard rails.**

* **A variable that gates one state's transition must not be read by another
  state.** If two states need "how faded am I", they need two variables.
* **Never assume two surfaces are the same size.** `application_surface` is
  resized explicitly at startup; `display_get_gui_width()` is a different thing.
  Ask `surface_get_width(application_surface)`, and draw stretched.
* **Capture at the last draw pass, not the middle of one.** If you are drawing
  at depth 75 but the world draws at depth −60, depth 75 runs *first*.
* `surface_create` off a GUI size and `sprite_create_from_surface` off a
  different size is how "it's black" becomes "it's black and also half empty".

**Status.** FIXED, 2026-10-04.

**Files.** `scripts/scr_drawBlurScreen`, `objects/_mainControl/Draw_75.gml`,
`objects/_mainControl/Other_5.gml`, `scripts/scr_main_pause`,
`scripts/scr_setup_main`, `scripts/scr_initResolution`,
`scripts/scr_draw_main_text`.

---
<a name="ll-015"></a>
## LL-015 — `array_last_index()` is not a count, and a UI can hide its own numbers

**Symptom.** The tower upgrade panel is missing information. Fire-Rate is
**never** displayed anywhere in the game, and Targets is not displayed at all —
not truncated, *absent*, as though it had never been written.

**Root cause.** `array_last_index()` returns `length - 1`. It was being used as
a loop bound:

```gml
var _type = array("Range - ", "Damage - ", "Fire-Rate - ");   /// 3 entries
var _count = array_last_index(_type),                          /// 2, NOT 3
for (var i=0; i<_count; i+=1){ ... }
```

So the loop stopped *before* Fire-Rate. And Targets was never in the list in the
first place — it was added to the data array (`TOWER.targets`) but nobody ever
added its label, so nothing could ever print it.

**Fix.** Print every field, indexed by the same enum the data is, so the labels
and the data cannot drift apart, and use `array_length` as the bound:

```gml
var _label = array("Range - ", "Damage - ", "Fire-Rate - ", "", "", "Targets - ");
var _count = array_length(_label);
for (var i = 0; i < _count; i += 1){
    if(_label[i] == "") continue;   /// effect and level are not numbers
    _str += concat(_label[i], round(_data[i]), "#");
}
```

The same work replaced a **256×256 panel centred on the screen** (with its own
"Tower Range" label *and* a second copy of the stats, while the range circle drew
at full strength beside it) with **one fixed card** docked in a corner, showing
`DMG · RATE · RNG · TGT · DPS` with the deltas a purchase buys.

**Guard rails.**

* **`array_last_index` is `length - 1`.** Use `array_length` for bounds. The
  off-by-one is invisible when the dropped element is the least important one.
* When you add a field to a data array, **grep for every place that enumerates
  the array** and add the label there too. A field that exists but is never
  printed is worse than a field that does not exist, because it looks finished.
* **Index labels by the enum, not by position in a hand-written list.** Two
  lists that must stay in step will not.
* Two elements competing for the same screen space is a *layout* bug, not a
  polish item: the fix is to make it one element.
* A delta (`125 → 250`) explains a purchase better than any tooltip, and costs
  two numbers. Compute it with the **same arithmetic the purchase uses**, so the
  card cannot promise something the upgrade does not deliver.

**Status.** FIXED, 2026-10-04.

**Files.** `scripts/scr_dataToString`, `scripts/scr_drawTowerSelected`,
`scripts/scr_drawTowerMod`,
`objects/_levelControl/{Create_0,Draw_64,Draw_73,Step_0}.gml`.

---

<a name="ll-016"></a>
## LL-016 — A parameter is not visible in a sibling function (and an unreachable line hides a fatal)

**Symptom.** None — yet. `create_perlin_grid` has been generating maps happily,
and this bug never appeared in a single play session.

**Root cause.** Inside a struct, each method has its **own** scope:

```gml
dot_prod_grid: function(x, y, vx, vy){ ... },   /// vx, vy live HERE
get: function(x, y) {
    if (ds_map_exists(memory, to_key(x,y)))
        return memory[? to_key(vx,vy)];          /// vx/vy DO NOT EXIST here
    ...
}
```

Reading a variable that does not exist in scope is a **fatal error** in GMS2. It
never threw for one reason and one reason only: the cache key it tested could
never already be present, so the `return` was never reached. The memoisation was
dead weight, and a fatal error was sitting inside it, one cache hit away from
being live.

**Fix.** `to_key(x,y)` — the key the function was actually asked about. The memo
now works, and there is no undefined variable to read.

The same file also reseeded the **global** random sequence
(`random_set_seed`/`randomize`), which a map generator has no business doing. It
was harmless only because the caller happened to pass `random_get_seed()`, so the
sequence was restored. Now it saves, uses, and restores explicitly:

```gml
var _seed_saved = random_get_seed();
if(_seed >= 0) random_set_seed(_seed);
   ...generate...
random_set_seed(_seed_saved);
```

**Guard rails.**

* **A parameter belongs to the function that declares it.** Inside a struct, do
  not assume a sibling method's parameters are visible — they are not.
* **An unreachable branch is not a test.** "It has never thrown" means the line
  has never run. When you find a variable that does not exist in scope, fix it
  even if it looks dead — the thing that made it dead is usually a bug itself.
* **A generator must not reseed the global RNG.** Save `random_get_seed()`, use
  your own, then restore.
* If a guard can never be true, the guard is not protecting anything: check
  whether the *condition* is wrong, not just the body.

**Status.** FIXED, 2026-10-04.

**Files.** `scripts/create_perlin_grid/create_perlin_grid.gml`.

---

<a name="ll-017"></a>
## LL-017 — `instance_exists()` on an unassigned `globalvar` is itself a throw

**Symptom.** A brand new guard, written to make something *safer*, becomes the
new crash: `Variable <name> not set before reading it`, or an
`instance_exists` failure, on a line that reads like defensive code. It only
reproduces before the object that owns the global has run its Create event -
so it looks intermittent, and it never reproduces on a reload from a saved
session.

**Root cause.** `globalvar LEVEL;` declares the name, but the **value is
assigned at runtime** (`LEVEL = id;` inside `_levelControl`'s Create). Before
that assignment the global exists but holds nothing useful, and passing that
to `instance_exists()` is another read of an unset variable. The guard throws
before the guarded line ever runs - the LL-002 shape ("a guard that can throw
is not a guard") reached from a new direction.

**Fix.** Ask whether the global *exists* before touching it:

```gml
	if(variable_global_exists("LEVEL")){
		var _lvl = LEVEL;
		if(instance_exists(_lvl)){
			with(_lvl){
				if(variable_instance_exists(id, "level_leaked")) level_leaked++;
			}
		}
	}
```

**Guard rails.**
* `instance_exists(x)` is not a validity test for `x`. It asserts something
  about an instance id, so `x` must already be a valid id.
* Any code that can run *before* an object's Create - a script called from
  another object, a `Destroy`, a `lose_life`, a diagnostic - must test the
  global with `variable_global_exists()` first, then the instance.
* The same applies to `variable_instance_exists()`: it needs a live instance.

**Status.** FIXED, 2026-10-04.

**Files.** `scripts/lose_life/lose_life.gml`, `objects/_levelControl/Create_0.gml`.

---

<a name="ll-018"></a>
## LL-018 — A verifier that compares against `git show HEAD:` lies about line endings

**Symptom.** A check script reports **"ending changed" for files that were
never touched by the edit** - in this project every CRLF file, every time. The
`git diff` for the same commit shows a small, surgical change. Two tools, two
answers, and the one that looks more rigorous is the wrong one.

**Root cause.** `.gitattributes` says `*.gml text eol=lf`, so git **stores LF**
and converts on checkout. `git show HEAD:file.gml` therefore returns the
*normalised* blob (LF), while the working tree holds CRLF. Comparing the two
compares a normalised copy against a raw one, and every CRLF file "changed" by
definition. Git even says so, quietly, on every `git add`:

```
warning: in the working copy of 'objects/Menu/Step_0.gml',
         CRLF will be replaced by LF the next time Git touches it
```

That warning is about the **store**, not the working tree. It is not a problem
to fix; it is a fact to stop mis-reading.

**Fix.** Do not verify line endings against HEAD. Verify the thing the rule
actually cares about:

1. **No literal backslash-r** — the two-byte run must count as `0` in the
   file's raw bytes (grep for it with a fixed-string match; see LL-006).
2. **Composition** - count CRLF and bare LF and report the kind, and confirm
   the file did not *become a different kind* of file.
3. **No wholesale rewrite** - `git diff --numstat` (added/removed per file)
   must match the size of the edit. A line-ending rewrite shows up as "every
   line changed"; a real edit does not.

**Guard rails.**
* `editlib.replace_lines` writes new lines with the file's **own dominant
  ending**, so it cannot convert a file. That is why the composition check is
  the right one, and why a "before/after kind" comparison is the meaningful
  assertion.
* Any automated check that disagrees with `git diff` about *what changed* is
  almost always wrong about *how git stores bytes*, not right about a bug.
* Corollary for agents: a false-positive verifier costs as much time as a
  missing one, because it sends you looking for a fault that does not exist.

**Status.** FIXED, 2026-10-04.

**Files.** `AGENTS.md` §1.3, this file's LL-006; the check lives in the Phase 1
verification script.

---

<a name="ll-019"></a>
## LL-019 — `visible = false` does not hide an object that has its own Draw event

**Symptom.** Buttons that were supposed to be hidden are **still drawn, still
hover, and still play the click sound** - and they sit *on top of* whatever
screen replaced them. The helper that was called to hide them
(`scr_button_index_hide`) reports that it ran. A related symptom with no
obvious link: the title buttons stayed clickable over the world map, so a click
aimed at a stage node landed on **Start**.

**Root cause.** `scr_button_index_hide()` sets `visible = false`, which is
correct-looking code. But `visible` only suppresses GameMaker's **built-in
sprite draw**, and an object that has its own Draw event does not get the
built-in draw at all. `_button` has `Draw_64`, which calls
`scr_draButtonGUI()` - and that function drew unconditionally:

```gml
function scr_draButtonGUI() {
	var _tx = x + sprite_width*0.5, ...   /// no visible check
	draw9slice(sprite_index, ...);        /// draws every frame
```

So **every "hidden" button in this project had been visible all along.** The
options screen and the Continue button were carrying this defect the whole
time; nothing had ever depended on the difference, so nobody noticed.

The same applied to input: `scr_stpButton()` tested the mouse and played
`snd_button` *before* it checked `active`, so a hidden button still beeped
when clicked through (only its script was correctly suppressed).

**Fix.** Make the flag mean something at both ends.

```gml
	/// scr_draButtonGUI() - a Draw event ignores `visible`
	if(!visible) exit;

	/// scr_stpButton() - a hidden button is not a button
	if(!visible) exit;
```

**Guard rails.**
* **`visible` is not a cross-cutting "hide me" flag.** It is a draw hint for
  the built-in renderer. Any object with a custom Draw event must check it
  itself - so check it in *every* custom Draw, and in any Step code that
  reacts to the mouse.
* When a helper "hides" something, **verify it visually in one run**, not by
  reading the helper. The helper here was correct; the consumer was not.
* Grep for the pattern: a script that sets `visible`, and the object's Draw
  event that never reads it.
* `active = false` alone is not a hide. It stops the *action* and leaves the
  button on screen and noisily clickable - which is more confusing than not
  disabling it at all.

**Status.** FIXED, 2026-10-04.

**Files.** `scripts/scr_draButtonGUI/scr_draButtonGUI.gml`,
`scripts/scr_stpButton/scr_stpButton.gml`,
`scripts/scr_button_index_hide/scr_button_index_hide.gml`,
`objects/Menu/Step_0.gml`.

---

<a name="ll-020"></a>
## LL-020 — A persistent instance outlives the non-persistent data it draws

**Symptom.** Finish a level, return to the world map, pick the next stage, and
the game throws the **same error every frame** while entering the play room:

```
ERROR in action number 1
of Draw Event for object _shadows:
Unable to find instance for object index 1
 at gml_Script_scr_drawLight (line 13) -         _sx = _DAY.shadow_offset[0],
gml_Script_scr_drawShadows (line 22) -     scr_drawLight(_scale);
gml_Object__shadows_Draw_0 (line 2) - scr_drawShadows();
```

`_DAY` is `_dayCycle`, and "object index 1" is that object with **no live
instance**. Level one is fine; every level *after* it is not.

**Root cause.** Two objects are created as a pair, but only one of them was
marked persistent:

* `_shadows` — `persistent: true`.
* `_dayCycle` — `persistent: false`.

`scr_iniLighting()` creates `_shadows` from `_dayCycle`'s Create event, so on the
first level they appear together. But a stage is a fresh entry to `rm_test`: the
main flow re-runs (`Control` → `_mainControl` → `scr_main_startup`), which
recreates `_dayCycle` **after** the loading sequence, while the persistent
`_shadows` from the previous level is already in the room. For the first frames
of the new stage the wall shadows are drawn *before* `_dayCycle` exists again,
and `scr_drawLight` dereferenced it without a guard.

The same asymmetry had a second half: because `_shadows` is persistent and
`scr_iniLighting` created unconditionally, **every** level stacked one more
`_shadows` on top of the last - an ever-growing pile of shadow passes.

`scr_drawShadows` had already been half-guarded (`instance_exists(_dayCycle)`
before the final `draw_surface_ext`), but the `with(_shadow)` / `with(obj_wall)`
blocks that call `scr_drawLight` ran *before* that, so the fatal still fired.

**Fix.** Guard the reference (the LL-012 shape) *and* stop the pile.

```gml
/// scr_drawLight() - the day cycle may not exist yet, or at all
if(!instance_exists(_dayCycle)){
    return;
}

/// scr_drawShadows() - no day cycle, no shadow pass at all
if(!instance_exists(_dayCycle)){
    return;
}

/// scr_iniLighting() - create the renderer once, reuse the survivor
if(!instance_exists(_shadows)){
    instance_create_depth(0,0,-50,_shadows);
}
```

**Guard rails.**
* **An instance may only outlive another if the thing it reads outlives it
  too.** `_shadows` reads `_dayCycle` every frame, so they must share a
  lifetime - either both persist or neither does. Grep the pair, not just the
  object named in the error.
* A guard **at the consumer** (`instance_exists()` before a `.var` read) turns
  a fatal into "it did not draw this frame". Put it in *every* function that
  dereferences a sibling, not only in the Draw event that happened to call it.
* **Creation inside a re-run initialiser must be idempotent.** An
  `instance_create*` in a `scr_ini*` that runs once per level is a duplicate
  generator the moment the object is persistent.

**Status.** FIXED, 2026-10-05.

**Files.** `scripts/scr_drawLight/scr_drawLight.gml`,
`scripts/scr_drawShadows/scr_drawShadows.gml`,
`scripts/scr_iniLighting/scr_iniLighting.gml`.

---

<a name="ll-021"></a>
## LL-021 — Two sources of truth for "what a level is": a map that can create a stage

**Symptom.** Nothing, until it did.  The world map draws a **6 x 10** grid of
region/stage nodes and every unlocked node is clickable.  After clearing region
1 the next region opens (the gate is `region_cleared(1)`) - but the authored
stage table only ever held **region 1's ten rows**.  Clicking 2-1 Deployed, the
level ran, and it was **stage 1-1 again**: `stage_current()` fell back to
`stage_get(1, 1)` when the lookup came back `undefined`.  A level the map
"created" that the data never defined - on screen, and payable, and wrong.

**Root cause.** The shape of the campaign lived in two places that could not
disagree out loud:

* the **map** - `meta_worldmap_geom()` / `meta_worldmap_rects()` hardcode
  6 regions x 10 stages, and `Menu/Step_0` turned *any* node index into a
  region+stage and deployed it;
* the **data** - `stage_data()` had ten rows.

Nothing compared the two, so a node could exist with no level behind it, and the
level flow's own safety fallback (`stage_get(1,1)`) hid the mismatch instead of
surfacing it.

**Fix.** One source of truth, and a gate at the door.  `GameLevelData`
(`scripts/GameLevelData`) is what a level IS; `global.level_data` is built
**once** in `initialize_game()` from the authored rows, and `level_get()` /
`level_exists()` / `level_current()` read it.  The map resolves every node
through `level_get()`, draws a node with no level as an inert dash, and the
Menu refuses the Deploy:

```gml
if(!level_exists(_rgn, _stg)){
    print("MENU  stage ", _rgn, "-", _stg, " has no level yet");
} else if(stage_unlocked(_rgn, _stg)){
    ... deploy ...
}
```

`stage_get()` / `stage_current()` / `stage_count()` are now thin wrappers over
the one list, so every existing caller moved without changing.

**Guard rails.**
* **A screen that enumerates things must enumerate the same list the game plays
  from.**  A hardcoded count (`6 x 10`) beside a data table is two truths that
  will drift the moment one is edited.
* **A fallback that swallows "not found" hides exactly the bug you want to
  see.**  Keep the fallback so nothing throws (LL-002), but add a gate that
  refuses the input *before* the fallback can matter.
* Build shared data **once, at init**, and hand everyone the same list - a list
  rebuilt per screen is a list that can be a different list per screen.

**Status.** FIXED, 2026-10-05.

**Files.** `scripts/GameLevelData/GameLevelData.gml` (new),
`scripts/stage_data/stage_data.gml`, `scripts/initialize_game/initialize_game.gml`,
`scripts/scr_meta_screen/scr_meta_screen.gml`, `objects/Menu/Step_0.gml`.

---

<a name="ll-022"></a>
## LL-022 — Two curves that only mean something together (wave ramp vs tower ladder)

**Symptom.** "Just raise the wave count" is not a one-line change.  Set a stage
to 60 waves with the old ramp and the game is unbeatable; land the new tower
ladder without the new ramp and the game is trivial.  Both directions present as
*"the balance is broken"* and neither points at the cause.

**Root cause.** Two constants whose values only have meaning relative to each
other:

* `scr_level_difficulty` did `life *= power(2, wave/5 - 2) + 0.2*(wave - 1)` —
  ×1.0 at wave 1, ×2.8 at wave 10, **×1036 at wave 60**;
* a tower's L5 did **×16** an L1's damage, because each purchase added the
  tower's *current* damage.  The exponential ramp was written to match *that*
  and nothing else.

Change either alone and the product moves by an order of magnitude.  Stage
stages used to be 5-10 waves, which is why nobody noticed: the exponential
never got past ×2.8.

**Fix.** Make both of them data, then make the shape legible.

* Waves became a **rule** in `region_data()` — 15 in stage 1, +5 a stage, in
  every biome — and the ramp became a per-biome curve:

  ```gml
  m(w) = 1 + (curve_end - 1) * ((w - 1) / (waves - 1)) ^ curve_pow
  ```

  `m(1) = 1.00` in EVERY biome (so one set of tower numbers survives sixty
  stages), `curve_end` per region (30 → 125), and `curve_pow = 2` because a
  stage's money grows with the **square** of the wave number.
* The ladder became `tower_levels.gml` — a level is `base × ladder` and never
  compounds, and cap/floor come from the garden — and it landed in the **same
  change** as the curve.

**Guard rails.**
* **A constant tuned against another constant is not a constant, it is a
  coupling.**  Write it down next to its partner.  `economy.md` §4.4 and
  `goal.md` §4 both said "they are one change" and it was *still* nearly landed
  in two halves.
* **Check a curve where it is steepest, not where it is comfortable.**  The old
  ramp is perfectly reasonable at wave 10 and absurd at wave 60.
* **Match the ramp to the income, not to a feeling.**  Rewards per wave grow
  ~quadratically (`spawn_count + wave div 5`); a ramp that tracks that stays
  reachable, and an exponential one never can.
* When two tables must agree (a price and a worth), **write the inequality
  down** — `Δdps ÷ Σprice ≥ dps-per-money` — so a violation is arithmetic
  rather than an argument.  Doing that is how §4.6 was found.

**Status.** FIXED for the waves, the curve and the difficulty wiring,
2026-10-05.  The **rung price vs rung worth** mismatch it exposed is OPEN and
recorded as `economy.md` §4.6.

**Files.** `scripts/region_data/region_data.gml` (new),
`scripts/tower_levels/tower_levels.gml` (new), `scripts/GameLevelData/GameLevelData.gml`,
`scripts/stage_data/stage_data.gml`, `scripts/scr_level_difficulty/scr_level_difficulty.gml`,
`scripts/difficulty_data/difficulty_data.gml`, `scripts/scr_level_spawn/scr_level_spawn.gml`,
`scripts/scr_zomb_death/scr_zomb_death.gml`, `scripts/scr_zomb_pathSpeed/scr_zomb_pathSpeed.gml`,
`objects/_levelControl/{Create_0,Step_0}.gml`, `objects/obj_tower/Create_0.gml`,
`objects/obj_tower_edit/Step_0.gml`, `scripts/scr_placeTower/scr_placeTower.gml`.

---

<a name="ll-023"></a>
## LL-023 — A convention nobody checks gets broken by its author, within the hour

**Symptom.** `progress.json`'s own documentation said *"a `backlog` card has
`awaiting: "none"` because nobody is holding it yet."* Within the hour the board
had a `backlog` card awaiting Rayu, and the top strip — the one place that is
supposed to mean *"this is on you right now"* — had started filling with parked
work. Nothing errored. Nothing looked broken. The board was just quietly less
useful than it claimed to be.

**Root cause.** The rule lived in **prose only**. The validator checked the *shape*
of every field (enums, ids, dates, cross-references) and never compared two fields
to each other, so a document could be perfectly well-formed and still mean the
wrong thing. Prose in a doc is not a constraint; it is a hope with good formatting.

**Fix.** Make the invariant executable, and give it a test:

```python
if status == "backlog" and t.get("awaiting") not in (None, "none", "external"):
    errs.append("%s: a backlog card must not be awaiting a person "
                "(promote it to next if they really need to act)" % where)
```

**Guard rails.**
* **If a doc states a rule, ask which command enforces it.** If the answer is
  "none", the rule is a wish. This is [LL-021](#ll-021) one level up: not two
  data sources that never compared, but a data source and *its own documentation*.
* **Derive a field when you can, instead of storing it.** There is no `blocked`
  status in the tracker — it is `awaiting != none` on an unfinished card, and a
  derived field cannot disagree with itself.
* **Any checked-in file built from another file needs a gate.** `PROGRESS.md` and
  `progress.html` carry a `progress-sha` and `gm progress check` fails when they
  disagree with `progress.json`, so "forgot to rebuild" is a red test instead of a
  board that quietly lies. Verify the gate *bites*: edit the JSON, watch it go red.
* **Put the rule where it is cheap to obey.** A validation error is a fix; a
  paragraph in `AGENTS.md` is a reminder.

**Status.** FIXED, 2026-10-05.

**Files.** `python_tools/gm/progress.py` (`validate`), `python_tools/tests/test_gm.py`
(`ProgressTests`), `progress.json`, `AGENTS.md` §6.

---

<a name="ll-024"></a>
## LL-024 — A call to a function that was never defined reports as a *variable* read, in the CALLER's scope

**Symptom.** Selecting a tower in a level threw, every time:

```
of  Step Event0 for object _levelControl:
Variable _levelControl.tower_upgrade_price(101533, -2147483648) not set before reading it.
 at gml_Object__levelControl_Step_0 (line 94) -  tower_price_save[0] = tower_upgrade_price(tower_selection.base_price,
```

The first instinct is to read the parentheses as the arguments: `base_price` is
`101533` (not a price — that looks like an instance id!) and `level` is
`-2147483648` (`INT_MIN`!). From there you go hunting for a corrupt tower, a
mis-set `tower_selection`, or a `data[TOWER.level]` that was never written. **All
of that is a dead end**, and the real cause is much duller.

**Root cause.** Two things, one of them a documentation trap.

1. **The function did not exist.** The Phase 1 economy refactor rewrote
   `_levelControl/Step_0.gml` to *call* `tower_upgrade_price(...)` and
   `tower_sell_refund(...)`, but the functions themselves were never added to any
   script. Grep for `` `function tower_upgrade_price` `` returns **zero hits**.
2. **GameMaker names the caller, not the missing file.** A call to an unknown
   identifier is compiled as a *variable read* of that name in the current scope,
   so the message is `Variable <calling object>.<the name> not set before reading
   it` — here `<caller>` is `_levelControl` even though the function "belongs" to
   `tower_levels`. An undefined **function** and an undefined **variable** produce
   the *same* error text.
3. **The numbers in the parentheses are not the arguments.** The manual
   (`Runner Errors`) is explicit: the first value is *the instance ID of the
   instance running the code* and the second is *an internal value … that can be
   ignored*. `101533` is not the selected tower (`100181` in the log) and `-2147483648`
   is not a level — they are runner bookkeeping. Reading them as data sends you
   after the wrong bug.

**Fix.** Define the two functions, next to the rest of the ladder they belong to
(`scripts/tower_levels/tower_levels.gml`, all reads guarded per [LL-002](#ll-002)):

```gml
function tower_upgrade_price(_base_price, _level) {
	if(!is_real(_base_price) || !is_real(_level)) return -1;
	if(_level >= tower_cap()) return -1;              /// -1 = "at the cap" sentinel
	var _rung = round(_level) - tower_floor() + 1,    /// rungs counted from the FLOOR
	    _cost = tower_rung_cost(_rung);
	if(_cost < 0) return -1;
	return round(_base_price * _cost);                /// economy.md 4.3
}

function tower_sell_refund(_invested) {
	if(!is_real(_invested)) return 0;
	return round(_invested * 0.60);                   /// 60% of everything invested
}
```

**Guard rails.**
* **When the failing name looks like a function, grep for its definition before
  you chase its arguments:** `grep -rn 'function <name>' --include='*.gml' .`.
  Zero hits means "never defined", full stop — not "set later".
* **A `not set before reading it` error proves nothing about which file is at
  fault.** The scope in the message is *the caller*. Read it as *"this call site
  is unbound"*, then go find (or write) the other end.
* **Never treat the parenthesised values in a runner error as arguments.**
  They are *(instance id, internal id)*. If they look like garbage to an argument
  reading, that is because they are not arguments.
* **A refactor that adds call sites needs a "does it define?" pass** in the same
  change. After touching an event, list its `name(` calls and confirm each has a
  `function name` somewhere (or is a real built-in). This is the same shape as the
  wave-curve lesson ([LL-022](#ll-022)): two ends of one change that must land
  together.

**Status.** FIXED, 2026-10-06.

**Files.** `objects/_levelControl/Step_0.gml` (the call sites, lines 54/94/167),
`scripts/tower_levels/tower_levels.gml` (the definitions).

---

<a name="ll-025"></a>
## LL-025 — A monster marches north through every wall (because its path was thrown away first)

**Symptom.** Part-way through a wave the zombies stop following the route and
**walk north**, in a straight line, **through towers and walls**, until they are
off the top of the map. It happens even when the level plainly has a clear route,
and it starts around the moment a tower is placed. The only log line is usually
the last-resort valve:

```
PATH  WARNING: 3 monster(s) still alive 6s past the wave - forcing the wave to end so the stage cannot hang
```

**Root cause.** Two defects, one hiding the other.

1. `obj_mon/Draw_72.gml` is **Pre Draw** and `obj_mon/Draw_73.gml` is **Post
   Draw**. They are the fake "climb" height and must be a *balanced pair*: Pre
   Draw lifts the sprite, Post Draw puts the instance back. **Both subtracted**
   `z_climb*2-12`, so the instance's `y` stepped north by `2*(z_climb*2-12)`
   (**~16-24 px**) *every frame*. It was invisible for as long as a monster was on
   a path, because the path follower rewrites `x`/`y` every step and discards the
   offset.

2. `obj_mon/Alarm_0.gml` opened with

   ```gml
   path_end();
   path_clear_points(myPath);     /// ... and only THEN asked the grid for a new one
   ```

   so a **single failed re-path** — a tower just placed, a monster brushing one;
   `Collision_obj_tower` forces a re-path on mere *proximity* — left the monster
   with **no path at all**. A monster with no path is a monster **nothing
   rewrites each step**, so defect 1 stopped being invisible and walked it off the
   map. And once it is outside `LEVEL.path_grid`, every later `mp_grid_path`
   starts from an off-grid cell and fails, so it never comes back. That is why the
   report sounded like a placement glitch: the placement is what *triggered* the
   re-path.

A third, smaller defect fed the trigger: `obj_tower/Create_0` blocked `bbox_*` at
`image_xscale == 1` (32 px) while `Destroy_0` cleared `bbox_*` at `0.5` (16 px),
so the clear was **always a smaller rectangle than the block** and every removed
tower left phantom blocked cells behind; and the placement check added the *edit*
object at `0.25` while the placed tower blocked at `1.0`, so the check reasoned
about a footprint the tower would not actually have.

**Fix.** Never move the instance in Draw, and never throw away a route you cannot
replace.

```gml
/// obj_mon/Draw_73.gml  POST DRAW restores what PRE DRAW applied
y += z_climb*2-12;

/// scripts/scr_path_validate  - probe first, commit only on success
function scr_path_replace(_grid, _x1, _y1, _x2, _y2, _dst, _probe) {
	path_clear_points(_probe);
	if(!mp_grid_path(_grid, _probe, _x1, _y1, _x2, _y2, true)) return false;
	path_clear_points(_dst);                  /// only now is _dst touched
	mp_grid_path(_grid, _dst, _x1, _y1, _x2, _y2, true);
	return true;
}
```

* `obj_mon/Alarm_0` — both the polite re-path and the last-resort escape — and
  the first path in `scr_zombie_path` now go through `scr_path_replace(...)`: the
  monster keeps walking what it has until a *replacement* exists, and is only ever
  `path_start`ed on a path that has points.
* `obj_mon/Create_0` adds a scratch `path_probe`; `Destroy_0` frees both paths
  (neither was ever freed, so every zombie leaked its path).
* `obj_tower/Create_0` blocks **the cell** and remembers it in `grid_block`;
  `Destroy_0` clears that same rectangle; `obj_tower_edit/Step_0` checks that same
  footprint — so add, clear and check finally agree.

**Guard rails.**
* **A draw-only offset must be applied and removed in the same frame.** Pre
  Draw/Begin Draw shifts, Post Draw/End Draw restores, and the restore is the
  exact inverse (`-=` then `+=`, never `-=` twice). An unmatched write of `x`/`y`
  in a Draw event drifts the instance at the frame rate.
* **Never destroy state you cannot rebuild.** Emptying a path/array/queue before
  you know the new value exists turns "this failed" into "there is nothing here
  any more". Probe, then commit.
* **Whatever moves an instance must be rewritten every step.** Here motion is
  "the path follower re-writes `x`/`y`"; when that stops, *any* other write —
  even one in a Draw event — becomes movement. Ask "who writes x/y this step?"
  whenever an instance starts drifting.
* **An add and its remove must be the same rectangle.** Derive it once and keep
  it (`grid_block`); recomputing from `bbox_*` after a scale change leaks blocked
  cells, and a phantom block reads exactly like "the path is blocked but there is
  nothing in the way".
* **A monster with no path should freeze, not fly.** The escape route plus the
  6 s valve in `scr_level_wait` still guarantee a wave can end, but nothing should
  be able to move a monster off the grid in the first place.

**Status.** FIXED, 2026-10-06.

**Files.** `objects/obj_mon/Draw_72.gml`, `objects/obj_mon/Draw_73.gml`,
`objects/obj_mon/Alarm_0.gml`, `objects/obj_mon/Create_0.gml`,
`objects/obj_mon/Destroy_0.gml`, `scripts/scr_zombie_path/scr_zombie_path.gml`,
`scripts/scr_path_validate/scr_path_validate.gml`,
`objects/obj_tower/Create_0.gml`, `objects/obj_tower/Destroy_0.gml`,
`objects/obj_tower_edit/Step_0.gml`.

---

<a name="ll-026"></a>
## LL-026 — A persisted function reference comes back as a number, and `script_execute()` runs the wrong script

**Symptom.** Every Step, from *Input* — and nothing in `Input/Step_0` mentions
`scr_drawTimerExt`, nor does anything in the project call it, so the stack "looks
wrong":

```text
ERROR in action number 1
of  Step Event0 for object Input:
Variable Input._objSwitch(100808, -2147483648) not set before reading it.
 at gml_Script_scr_drawTimerExt (line 10) - 	var _logAmt = instance_number(_objSwitch);
gml_Script_scr_drawTimerExt (line 10)
gml_Object_Input_Step_0 (line 4)
Script_Free called with 934 and global 392
```

**Root cause.** `Input/Step_0` dispatches the key listeners with

```gml
key[i] = script_execute(key_type[i],key_code[i]);
```

and `key_type` holds **function references** (`scr_key_get`, `scr_keyDown_get`,
`scr_gamepad_get`, `scr_gamepadDown_get`) set up by `scr_add_key` in
`scr_setup_keyboard` / `scr_setup_gamepad`. Then `scr_setup_keyboard` overwrites
them from the save file:

```text
scr_setup_keyboard()  ->  scr_load_keys(global.saveName)
scr_load_keys()       ->  scr_loadArray(...)              ->  ds_list_read
scr_save_keys()       ->  scr_saveArray(key_type, ...)    ->  ds_list_write
```

`ds_list_write` / `ds_list_read` carry **only reals and strings**. A function
reference is written as a plain number — the save file's `KeyInputData/1` held
`41880100`, `3f880100`, ... (100417 / 100415) — so on the next launch `key_type`
is an array of *numbers*. `script_execute(<number>)` then resolves the number as
a **script index** and runs that script; in this build that was
`scr_drawTimerExt`, an orphan from the "Simple Game Engine" asset pack that reads
`_objSwitch`, an object **never recovered into this project**. Hence the error
names a function nobody calls, in an object that does not exist, from an event
that never mentions it.

It only bites *after the first save*: a fresh run builds `key_type` correctly and
`scr_loadArray` returns `-1` when there is no file, so the good array survives.
The first `scr_save_keys` (Input's Game End event) writes the poisoned version,
and every run from then on crashes.

**Fix.** Never persist a function, never dispatch a value you have not checked,
and never read a possibly-missing object as a bare name.

```gml
/// Input/Step_0.gml - dispatch through run_script(), which calls only a real function
key[i] = run_script(key_type[i], noone, [key_code[i]]);

/// scr_load_keys.gml - keep the freshly built key_type unless the saved one is all-callable
var _typeOk = is_array(_key_type) && array_length(_key_type) > 0;
if(_typeOk){
    for (var _i=0; _i<array_length(_key_type); _i+=1){
        if(!is_callable(_key_type[_i])){ _typeOk = false; break; }
    }
}
if(_typeOk){ key_type = _key_type; };

/// scr_save_keys.gml - do not save key_type at all (it cannot round-trip)
scr_saveArray(key,_fname,_sec,"0");
scr_saveArray(key_name,_fname,_sec,"2");

/// scr_drawTimerExt.gml - resolve the object by name, bail when it is gone
var _objSwitch = asset_get_index("_objSwitch");
if(_objSwitch == -1) return;
```

`key_type` is fixed by the device (keyboard or gamepad), not the player, so
rebuilding it every launch is always correct; only `key` and `key_name` are
worth saving.

**Correction ([LL-028](#ll-028)).** The saved value is not a plain number:
it comes back **still callable**, so an `is_callable()` guard accepts it and
the dispatch runs whatever script the handle now indexes. The value has to be
bounded at the *load* - never read `key_type` at all - which is why the guard
below was not enough on its own.

**Guard rails.**
* **`ds_list_write`/`ds_list_read` cannot store a function** (nor can an
  `ini`/`json` round-trip). Anything holding callables — key listeners, button
  callbacks, timer scripts — must be *rebuilt* on load, or saved as a **name**
  and resolved with `asset_get_index()`.
* **Never `script_execute()` a value that might not be a function - dispatch
  through `run_script()` (LL-028).** It checks `is_undefined()` and
  `is_callable()` first, binds the call to a target instance with `method()`
  when asked, and forwards an `arguments_list` array. (LL-004 is the same
  GMS1→GMS2 gap from the other side.) **That guard is half the fix**: a
  value read back from a save file is callable *and* wrong, so `is_callable()`
  passes it - the load has to refuse it instead (LL-028).
* **A saved value outlives the code that wrote it.** Asset indices are not stable
  across a conversion or a growing project, so a numeric reference on disk is a
  landmine; never let one reach a dispatcher.
* **When the stack names a function you never call, read the caller's *dispatch*
  line, not the caller's text.** Line 4 dispatched an array element; the
  function it named was never written in that file. (LL-024 is the mirror
  image — there the
  *callee* was the surprise.)
* **`asset_get_index("name")` is the safe way to read an object that may not
  exist** — a missing object is `-1`, where a bare `_objSwitch` is a fatal
  "variable not set" (LL-002 / LL-012).
* **A defect in a helper has siblings — grep for them.** The gamepad pair
  `scr_save_gamepad` / `scr_load_gamepad` had the same persisted-function bug and
  were fixed with the keyboard pair. They still disagree on the save *section*
  (`"scr_save_gamepad"` vs `"GamepadInputData"`), so the gamepad path is inert
  today; if it is ever wired up, keep the `is_callable()` guard.

**Status.** FIXED, 2026-10-06.

**Files.** `objects/Input/Step_0.gml`, `scripts/scr_load_keys/scr_load_keys.gml`,
`scripts/scr_save_keys/scr_save_keys.gml`,
`scripts/scr_drawTimerExt/scr_drawTimerExt.gml`,
`scripts/scr_save_gamepad/scr_save_gamepad.gml`,
`scripts/scr_load_gamepad/scr_load_gamepad.gml`.  Every one of its
`script_execute()` dispatches now goes through `scripts/run_script/` (LL-028).

---

<a name="ll-027"></a>
## LL-027 — `mp_grid_add_rectangle` / `mp_grid_add_instances` walk their range INCLUSIVELY, so a rectangle the size of one cell blocks two

**Symptom.** Pathfinding is "still not fixed" even after LL-025: monsters take
odd routes, or cannot leave the walled pen they spawn in at all, as though the
towers were bigger than the 32x32 cell they stand on. **Nothing errors** - the
grid is just wrong, so the route that comes back is not the route you drew.

**Root cause.** The tower's grid footprint was a rectangle around its centre:

```gml
mp_grid_add_rectangle(LEVEL.path_grid,
                      x - LEVEL.cell_w*0.5, y - LEVEL.cell_h*0.5,
                      x + LEVEL.cell_w*0.5, y + LEVEL.cell_h*0.5);
```

A placed tower snaps to its cell centre (`((mouse_x>>5)<<5)+16`), so its far
edge is `x + cell_w*0.5` - **exactly** the boundary of the NEXT cell. GameMaker
floors *both* edges and iterates **inclusively**:

```text
_FA = floor((min(x1,x2) - originX) / cellW)
_GA = floor((max(x1,x2) - originX) / cellW)
for (i = _FA; i <= _GA; i++) add_cell(i, ...)
```

For a tower at `x = 112` (grid origin `-32`, cell 32): `_FA = floor(144/32) = 4`,
`_GA = floor(160/32) = 5`, so **columns 4 and 5** are marked - and likewise two
rows. Every tower therefore blocked a **2x2 block of four cells**, not the one
it occupied. `mp_grid_add_instances()` has the identical floor/inclusive loop
with the instance's bbox, so any instance whose far edge lands on a boundary
over-blocks the same way. The level is a **walled pen** around the spawn with a
one-cell exit, so one over-blocked wall cell can seal the exit and the whole
horde is trapped - which is what "pathfinding is broken" actually looked like.

**Fix.** Block the **cell an instance's origin falls in**, by index, everywhere.
Never a rectangle.

```gml
/// the grid origin is (-cell_w,-cell_h), so a point's cell is (x+cell_w) div cell_w
grid_col = (x + LEVEL.cell_w) div LEVEL.cell_w;
grid_row = (y + LEVEL.cell_h) div LEVEL.cell_h;
mp_grid_add_cell(LEVEL.path_grid, grid_col, grid_row);
```

* `obj_tower/Create_0` blocks its one cell and remembers `grid_col`/`grid_row`;
  `obj_tower/Destroy_0` clears exactly that cell, so add and clear cannot drift
  apart whatever the tower's `image_xscale` has become.
* `obj_tower_edit/Step_0` blocks one cell for the candidate and one cell per
  existing blocker.
* A new helper `scr_grid_block_instances(grid, obj)` (in `scr_path_validate`)
  replaces **every** `mp_grid_add_instances(...)` over the live grid -
  `scr_resetDrawPath` and `obj_mon/Alarm_0` - one cell per instance, from `x/y`.

**Guard rails.**
* **A rectangle is not a cell.** `mp_grid_add_rectangle` and
  `mp_grid_add_instances` are inclusive on the far edge, so a rectangle whose
  edges land on cell boundaries marks one cell too many on each axis. When you
  mean "one cell", say `mp_grid_add_cell`.
* **A footprint must not depend on `image_xscale`.** The old code blocked
  `bbox_*`, which changes when a tower is re-scaled on upgrade. Deriving the cell
  from `x/y` is scale-independent. (This is *why* LL-025 moved off `bbox_*` - the
  move just picked the wrong replacement.)
* **Add and clear must be the same quantity.** Remember the cell on the
  instance and clear that; never re-derive it later.
* **A grid a "draw the path" helper mutates is a side effect.** `scr_resetDrawPath`
  writes to the LIVE `path_grid` - which is how walls reached the path grid at
  all. Be suspicious of a helper that blocks a grid it was only meant to read.
* **Sprites here are authored 32x32 on the 32px grid**, so the cell that
  contains an instance's `x/y` *is* the cell it occupies - for a centre-origin
  tower and a top-left-origin wall alike.

**Status.** FIXED, 2026-10-06.

**Files.** `objects/obj_tower/Create_0.gml`, `objects/obj_tower/Destroy_0.gml`,
`objects/obj_tower_edit/Step_0.gml`,
`scripts/scr_path_validate/scr_path_validate.gml`,
`scripts/scr_resetDrawPath/scr_resetDrawPath.gml`, `objects/obj_mon/Alarm_0.gml`.

---

<a name="ll-028"></a>
## LL-028 — A saved function reference comes back **still callable**, and its handle shifts when the project gains a script

**Symptom.** The LL-026 error returns, but naming a **different** script and an
unrelated object each time the project is rebuilt:

```text
ERROR in action number 1
of  Step Event0 for object Input:
Variable obj_spawn.time_keeper(100807, -2147483648) not set before reading it.
 at gml_Script_scr_drawSwitchTimer (line 11) - 	    var _time = (time_keeper - state_time) div room_speed,

gml_Script_scr_drawSwitchTimer (line 11)
gml_Script_run_script (line 41) - 	    case 1: return _fn(arguments_list[0]);
gml_Object_Input_Step_0 (line 8) -     key[i] = run_script(key_type[i], noone, [key_code[i]]);
```

`Input`'s Step event names a script it never mentions, and the failing scope is
some unrelated object (`obj_spawn`) — because that script takes its argument as
an instance to `with()`.

**Root cause.** LL-026 was right that a saved listener array is poison, and wrong
about *why*. `ds_list_write`/`ds_list_read` **do** survive a function reference —
they do not give back a plain number, they give back a value that is **still
callable** — but the *handle* inside it indexes a table that shifts whenever the
project gains or loses a script. The save file proves it: the `key` array's
elements carry type-marker **5** (real) while `key_type`'s carry type-marker
**15** holding **100417 / 100415** — a different kind of value:

```text
[KeyInputData]
0="2F01000008000000 05000000 05000000 ..."          <- key:   8 x real
1="2F01000008000000 0F00000041880100 ... "          <- key_type: 8 x 100417/100415
```

So the guard in `scr_load_keys` — *"accept the saved `key_type` only when every
entry `is_callable()`"* — **passes**, `key_type` is replaced by the stale array,
and the dispatch runs whatever script now sits at that handle. Adding one script
(`run_script`) shifted the table, which moved `100417` from `scr_drawTimerExt`
(LL-026's symptom) to `scr_drawSwitchTimer` (this one). **No runtime check can see
it**: the value is not undefined, not a number, and not non-callable — it is a
well-formed handle to the wrong function.

**Fix.** Refuse the value at the boundary. A function reference must never be
*read back*:

```gml
/// scr_load_keys.gml - load key/key_name, and never slot "1"
var _key = scr_loadArray(_fname,concat(_sec),"0"),
    _key_name = scr_loadArray(_fname,concat(_sec),"2");
/// key_type is NOT read back - not even guarded.
```

and purge what is already on disk, so an older build cannot read it either:

```gml
/// scr_save_keys.gml - blank the stale slot; scr_loadArray() then returns -1
ini_open(_fname);
ini_write_string(_sec,"1","");
ini_close();
```

Every dispatch in the project now also goes through `run_script()` (LL-026),
which refuses an undefined or non-callable name. That closes the *other* half of
the hole — a genuinely non-function value — but it cannot close this one.

**Guard rails.**
* **A saved function reference is still a function.** `is_callable()` is not a
  validity check; do not use it to "sanitise" a value that came off disk. The
  only safe rule is **never to load one**: rebuild it, or store a `string` name
  and resolve it with `asset_get_index()`.
* **An index that survives a save is a landmine.** Adding or removing any
  resource renumbers the table, so a handle from an old save silently points at a
  *different* function. When a dispatch "changes its mind" after an unrelated
  change, suspect a saved reference.
* **The listener belongs to the device, not the player.** `key_type` is built by
  `scr_setup_keyboard()`/`scr_setup_gamepad()` and has no business in a save file
  — which is also why validating it could not fix the bug.
* **Check for siblings.** `key_type` was the only function *array* ever written to
  a save file here (options, bags, high score and the static inventory are all
  numbers), but `scr_saveArray`/`scr_loadArray` is shared: audit anything new that
  puts a callable in one.
* **A save file outlives the build that wrote it.** Blank slot "1" on save and
  keep the read gone even so.

**Status.** FIXED, 2026-10-06.

**Files.** `scripts/scr_load_keys/scr_load_keys.gml`,
`scripts/scr_save_keys/scr_save_keys.gml`,
`scripts/scr_load_gamepad/scr_load_gamepad.gml`,
`scripts/scr_save_gamepad/scr_save_gamepad.gml`,
`scripts/run_script/run_script.gml`, `objects/Input/Step_0.gml`.

---

## Adding an entry

Copy this template, give it the next free `LL-0NN` id, and **add a row to the
Index at the top**:

```markdown
<a name="ll-0NN"></a>
## LL-0NN — <one-line description of the real cause, not the symptom>

**Symptom.** What you actually see: the error text, the log line, the visible
misbehaviour. Include real log/error output — that is what makes this file
searchable next time.

**Root cause.** The mechanism. Why the symptom and the cause look unrelated.

**Fix.** The code that fixes it, verbatim.

**Guard rails.** The rule that stops it coming back, and how to spot it early.

**Status.** FIXED / OPEN / WATCH, and the date.

**Files.** The paths involved.
```

**Searchability matters.** Put the exact error text (`Variable … not set before
reading it`), the exact log prefix (`BTN   click`), and the plain-English symptom
(*"buttons greyed out"*) in the entry. Next time the search is a grep.

