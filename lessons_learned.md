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
| [LL-007](#ll-007) | Timings fire instantly or never; fades snap or hang | **`room_speed` is obsolete** in GMS2 (~35 files use it) | **OPEN** |
| [LL-008](#ll-008) | Your edit "reverted" / the file changed under you | **GameMaker has the project open** and saves from its own buffers | **WATCH** |
| [LL-009](#ll-009) | A one-value change produces a 1000-line diff | `.yy`/`.yyp` are **not JSON** — trailing commas, key order, inline containers | **FIXED** |
| [LL-010](#ll-010) | A state's "just entered" code runs twice, or never | **Changing state from inside a state** instead of requesting it for the next Step | **FIXED** |
| [LL-011](#ll-011) | — | **How to instrument the game** so the next bug takes one run, not ten | **METHOD** |

Tags for searching: `button` `menu` `array` `noone` `scope` `state machine`
`enum` `crlf` `room_speed` `built-in` `shadowing` `null` `log` `debug`.

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

