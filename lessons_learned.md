# Lessons Learned

Bug post-mortems for **Pushing Daisies**, a GameMaker 8 project converted to
GameMaker Studio 2. Most bugs here looked like something else: a broken button
was an array index; greyed-out buttons were an object index; a missing button
was a diagnostic that threw.

**If a symptom matches an entry, assume that bug until evidence says otherwise.**
Start from the rule, not from scratch. Add an entry after any non-obvious fix,
and add its row to the index.

---

## Index

`FIXED` means the fix is in. `PART FIXED`, `WATCH` and `METHOD` need attention.

| ID | Look for | Status |
| --- | --- | --- |
| [LL-001](#ll-001) | Buttons greyed out / nothing fires; `active=0` on every button | FIXED |
| [LL-002](#ll-002) | The same error every frame; buttons never created; the rest of the event never seems to run | FIXED |
| [LL-003](#ll-003) | `Variable Menu.<name> not set before reading it` from a helper; logs naming the wrong object | FIXED |
| [LL-004](#ll-004) | Buttons that never fire; code that tests `script >= 0` | FIXED |
| [LL-005](#ll-005) | Engine functions behaving strangely | FIXED |
| [LL-006](#ll-006) | Whole-file diffs; the file literally contains `\r` as text | FIXED |
| [LL-007](#ll-007) | Timings fire instantly or never; fades snap or hang | PART FIXED |
| [LL-008](#ll-008) | Your edit "reverted" / the file changed under you | WATCH |
| [LL-009](#ll-009) | A one-value change produces a 1000-line diff | FIXED |
| [LL-010](#ll-010) | A state's "just entered" code runs twice, or never | FIXED |
| [LL-011](#ll-011) | Not a bug — the method that finally made LL-001 and LL-002 obvious. | METHOD |
| [LL-012](#ll-012) | `sprite_get_height ... requested -1` once per step; a sprite flip that "does nothing"; a tower that un-mirrors - or draws upside-down - when it is upgraded | FIXED |
| [LL-013](#ll-013) | A zombie **freezes** on the map; the wave never ends; only a restart helps | FIXED |
| [LL-014](#ll-014) | The pause / exit screen is **black** | FIXED |
| [LL-015](#ll-015) | A UI is **missing information** that was never once displayed | FIXED |
| [LL-016](#ll-016) | Nothing - yet | FIXED |
| [LL-017](#ll-017) | A new "safety" guard crashes on a line that looks defensive, only before an object's Create has run | FIXED |
| [LL-018](#ll-018) | A check script reports "line endings changed" for files nothing touched; `git diff` says otherwise | FIXED |
| [LL-019](#ll-019) | Buttons that were "hidden" are **still drawn**, still hover, still beep, and sit over the screen that replaced them | FIXED |
| [LL-020](#ll-020) | `Unable to find instance for object index 1` from `_shadows` Draw, every frame, after finishing a level | FIXED |
| [LL-021](#ll-021) | A stage can be Deployed to that has no level data, and it silently plays stage 1 | FIXED |
| [LL-022](#ll-022) | 60-wave stages come out either trivial or unbeatable, depending on which half gets landed first | FIXED |
| [LL-023](#ll-023) | The board's "waiting on you" strip slowly fills with parked work | FIXED |
| [LL-024](#ll-024) | `Variable <caller>.<name> not set before reading it` for a name you *know* is a function; the numbers in the parentheses look like corrupt arguments | FIXED |
| [LL-025](#ll-025) | Monsters walk **north, straight through walls**, mid-wave, even when the level has a clear route; the wave then ends via the 6 s valve | FIXED |
| [LL-026](#ll-026) | The same `Variable Input.<name> not set before reading it` every step, naming a function that event never calls | FIXED |
| [LL-027](#ll-027) | Pathfinding is still off: monsters take odd routes or cannot leave their pen, as if a tower or wall covered more than its cell; **no error** | FIXED |
| [LL-028](#ll-028) | The LL-026 error again, but naming a **different** script and an unrelated object, changing each rebuild | FIXED |
| [LL-029](#ll-029) | A tower loops its **attack animation** forever and stops dealing damage; only after it has been **upgraded**; no error | FIXED |
| [LL-030](#ll-030) | A tower's **idle / return animation plays far too fast** after its sprite is re-drawn with fewer frames; no error, and no code was changed | FIXED |
| [LL-031](#ll-031) | Zombies **vanish a few seconds into every wave** and the wave moves on; nothing reaches the exit, nothing is killed, and the **lives counter never moves** | FIXED |
| [LL-032](#ll-032) | `gm progress` says "nothing written", and then **every** later `gm progress add` fails the same way | FIXED |
| [LL-033](#ll-033) | A hand-drawn click mask "does nothing": the clickable area still hugs the artwork and is half the size it should be; and the placement ghost refuses the cell **above** an existing tower | FIXED |
| [LL-034](#ll-034) | Every stage is **silent** - no region theme, ever - while the title and world-map themes play; the log blames the track: `META  [MUSIC] region 1 "Wilted Sprouts" has no track yet - playing nothing` | FIXED |
| [LL-035](#ll-035) | A monster **in water throws every frame**: `undefined value at gml_Script_draw_self_part (line 33) - _x = x - sprite_get_xoffset(sprite_index)*_sx`, from `obj_mon/Draw_0`'s five-argument call | FIXED |
| [LL-036](#ll-036) | A difficulty projection disagrees with the play - "the numbers look fine but I keep leaking" | FIXED |
| [LL-037](#ll-037) | The toolkit suite goes **red on an edit that changed no code** - `FAILED (errors=1)`, and the traceback is a `StopIteration` inside a *test* | FIXED |
| [LL-038](#ll-038) | A projection says **`ok` while the play leaks** - and a second tool built to check it agrees, because it was written from the same formula | FIXED |
| [LL-039](#ll-039) | A tower's **`targets` stat does nothing** - it hits one monster however high the number, and no error ever appears | FIXED |
| [LL-040](#ll-040) | Every tower deals about **a third** of the dps on its card, and the shortfall is **uneven** across the roster - so the paper ranking does not match the play ranking. No error, no crash, and the balance panel still says `ok` | FIXED |
| [LL-041](#ll-041) | A test suite stays **green while tests quietly stop existing** - the only symptom is a count that moves by less than it should | FIXED |
| [LL-042](#ll-042) | **Brutal is easier than Hard.** Brutal holds with 0 leaks where Hard leaks 19, and the panel says the opposite on every wave | FIXED |
| [LL-043](#ll-043) | Plants in water wear a **halo of themselves**, meet the surface at a different height per tower, and a left-facing one is **upside down and ~220px low** | FIXED |
| [LL-044](#ll-044) | The HUD's **Wave number reads one high** (wave 1 shows as 2), the level log agrees with it, and the speed ramp computes for the *next* wave - yet the pre-wave banner is right, so nothing looks broken | FIXED |
| [LL-045](#ll-045) | Nothing at all - the feature simply does nothing, and the code for it looks complete. An outline shader that had never drawn a pixel in its life | FIXED |
| [LL-046](#ll-046) | A ringed tower goes **see-through and blown out** the moment the ring is blended additively; or the ring's opacity changes nothing at all | FIXED |
| [LL-047](#ll-047) | A label placed "above the sprite's head" lands in the middle of it (or below its feet), with the value looking plausible | FIXED |
| [LL-048](#ll-048) | A balance model that says a stage **holds** while every tower stands on the same fifth of the map and the **last quarter of the route is never shot**; and a run of 11 towers that **never bought a single upgrade** | FIXED |
| [LL-049](#ll-049) | The **second level never loads**: the stage room comes up, walls and spawns are there, but the **ground never appears and no waves start** - and nothing errors | FIXED |
| [LL-050](#ll-050) | The game **resets every time**: stage progress, bought towers and clover nodes are gone after a relaunch - but seeds, clovers and the loadout are still there | FIXED |
| [LL-051](#ll-051) | A volume slider **does not apply until you leave Options**, and **0% / 100% take a second pass** because the mouse leaves the track | FIXED |
| [LL-052](#ll-052) | A tower's **shadow flips but does not follow** the tower when it turns round - it lands most of a tower-width to the side; after the origin was fixed it was still ~96px to the **right** | FIXED |
| [LL-053](#ll-053) | Losing every life **never reaches the new level flow** - the old arcade high-score screen takes over and nothing is saved or withheld | FIXED |
| [LL-054](#ll-054) | A **slow-firing tower never fires at all** - the Pina Collider stands through a whole stage; the attack timer looks frozen until something is in range | FIXED |
| [LL-055](#ll-055) | A 3-second **Level Complete** hold lasts one second in fast-forward; a banner sized as "60% of the viewport" comes out at 37% or spills off the edges | FIXED |
| [LL-056](#ll-056) | A monster HP bar draws with a **negative width** - an orange fill to the LEFT of the black bar, usually on a boss that has just died | FIXED |
| [LL-057](#ll-057) | The **Up Next popup shows the previous creature portrait** under the new creature name - read as "Tusk-A-Lot and Sub-Zero are swapped" | FIXED |
| [LL-058](#ll-058) | The **"Up Next" popup names a creature the wave does not send**, and the mismatch looks *random* - it started on the third level | FIXED |
| [LL-059](#ll-059) | Zombies draw **over plants they stand behind**, and two crossing monsters swap order | FIXED |
| [LL-060](#ll-060) | The **boss rule disagreed with itself** - play rolled one on a `boss_every` cadence, the curve projected wave 10, the tester encoded it again | FIXED |
| [LL-061](#ll-061) | "A leak pays half instead of nothing" changed the purse by **1 money over 20 leaks** | FIXED |
| [LL-062](#ll-062) | **Crit could not be added** - the damage function had no amount to multiply | FIXED |
| [LL-063](#ll-063) | **A test changed colour with no edit** - it asserted a LINE, and the IDE re-saved an equivalent one | FIXED |
| [LL-064](#ll-064) | The **music fades out in the middle of a stage**, and the menu goes quiet every ~3 minutes - no error, and the track is still "playing" | FIXED |
| [LL-065](#ll-065) | Monsters **vanish ~5 s after being stunned**, and the stage loses Exterminator | FIXED |
| [LL-066](#ll-066) | A font **installed for the user works everywhere except GameMaker** - `fc-list` finds it, KDE renders it, the font picker does not list it | FIXED |
| [LL-067](#ll-067) | A sprite font puts an **em-wide gap between every word**, and **half the UI still draws in the old font** | FIXED |
| [LL-068](#ll-068) | "**The buttons do not work**" on a 16:10 or 21:9 window - the highlight follows the pointer onto the wrong button, and a click opens the wrong screen | FIXED |
| [LL-069](#ll-069) | The **World Map title runs through the Garden Book button**, Deploy's **wall sits under its own slots**, the Garden Book's shop **hangs off the right edge** - and every locked tower's **name touches its reason** | FIXED |
| [LL-070](#ll-070) | The layout gate's **first real run** died inside the Draw event, two lines after `UI    [GEOM] begin worldmap 960x540 items 140`: `Variable Menu.json_string(101726, -2147483648) not set before reading it.` | FIXED |
| [LL-071](#ll-071) | Icons sit **half an icon up and left** of where the layout put them, tower thumbnails are a **different size each** and two **poke out of their cell** - and `gm layout check` calls every one of those screens **clean** | FIXED |
| [LL-072](#ll-072) | The title-screen zombie's **idle loop plays twice as fast** as in the original build - same art, no error, and the walk and grab look right | FIXED |
| [LL-073](#ll-073) | A sprite looks sharp in the **sprite editor** and soft/fringed **in game**; or a "cleaned" sprite comes back unchanged after a reload | FIXED |
| [LL-074](#ll-074) | A one-off surface bake written with `matrix_set(matrix_projection, matrix_build_orthographic(...))` - **no compile error, no warning**, and the first meta screen dies on `Variable Menu.matrix_build_orthographic(…)` | FIXED |
| [LL-075](#ll-075) | **No GML changed** - only the creature table grew from 2 bosses to 6 - and `gm balance`'s numbers for **stage 1-1** moved while a long-green test went red; the projection and the sim still agreed with each other | FIXED |
| [LL-076](#ll-076) | The four meta screens are **sharp** while the log says `MENU  blur on`, and no flag or depth changes it - it looks like a GPU/display bug | FIXED |
| [LL-077](#ll-077) | Nothing at all - the suite, the brace count, `gm gml-functions`, `roundtrip` and a diff are all green, and the file still is not what it reads like | FIXED |
| [LL-078](#ll-078) | Corpses settle **below the path** they died on - 6.6 px on the Bell-Ringer, 28 on the Shroud - and the Gardener walks 2 px into the ground all game; no error, nothing in the log | FIXED |
| [LL-079](#ll-079) | **"The walk animation plays as the zombies die"** - the kill line prints, the money is paid, the body **strides in place** for 0.8 s, then gone. Every other part of the death beat behaves | FIXED |
| [LL-080](#ll-080) | **A zombie killed while it is still rising stands up and walks** - the kill line prints, the money is paid, and the body strolls off; other corpses get **dragged along their route** while they topple; some falls show a **one-frame "standing" flicker** just before the body vanishes | FIXED |
| [LL-081](#ll-081) | A dying monster still draws `spr_*_walk` - the Draw print says `state: DIE` and `Sprite-ind: spr_grumble_walk` - with **nothing in the log to say which link of the art chain is wrong**, and every fix attempt is a guess | FIXED |
| [LL-082](#ll-082) | **Every monster spawns with one sprite for both its walk and its death** - a 32x32 still, the same picture for every creature and every state, while fifteen rigs of real art sit unused; `Sprite-ind: spr_mon` in the Draw print and no error | FIXED |
| [LL-083](#ll-083) | The boot trace says **`RIG   walker N <creature> slots=4 walk=none idle=none attack=none die=none` for every creature** while the art sits in the bank row - every monster wears the one-frame `spr_mon` for walk AND death, `is_real()` on an enum slot answered false, and no error anywhere; the second hit of LL-034's landmine, and the diagnosis was sitting unread in the run log | FIXED |
| [LL-084](#ll-084) | The new Spriter zombies look **squat** even though scale normalization says the rig is 2–3× larger than its sheet | FIXED |
| [LL-085](#ll-085) | The runtime knee clamp masked crouched authored keys; straight-leg poses now live in the package | WATCH |
| [LL-086](#ll-086) | A fresh save shows zero balances for every future currency before the player can earn them | FIXED |
| [LL-087](#ll-087) | The late-region balance sim started every tower at level 1 and ignored permanent clover progression | FIXED |
| [LL-088](#ll-088) | Ordinary leaks cost zero lives without Vitality, and 25% Vitality prevents 75%; raw leak counts also differ from lives lost | FIXED |
| [LL-089](#ll-089) | A range Candy changes targeting but the tower's light radius stays at its old size | WATCH |
| [LL-090](#ll-090) | Active Candy timers cover the speed controls, while Blood Orange pity covers the stage stats | WATCH |
| [LL-091](#ll-091) | Campaign seed totals do not match the per-stage awards, or a seed threshold is treated as an unlocked tower | FIXED |
| [LL-092](#ll-092) | The balance sim ends a wave on the last kill, while the game still has a corpse playing its DIE animation | FIXED |
| [LL-093](#ll-093) | Seeds stay inert after all towers are bought; Endless box seeds convert too early | FIXED |
| [LL-094](#ll-094) | gm-cli says `Cannot set a constant ("_score") to a value`; a local identifier collides with an object resource | FIXED |
| [LL-095](#ll-095) | `scr_tower_shoot` reads a local shot key on the strike frame, but it was declared only at state entry | FIXED |
| [LL-096](#ll-096) | SCML bounds and shadow draws repeatedly searched every rig part each frame | FIXED |
| [LL-097](#ll-097) | The stage-entry frame freezes before the loading screen can draw; room creation spends ~15 ms preloading all Spriter rigs | FIXED |
| [LL-098](#ll-098) | 30 Hz SCML pose sampling can look stepped because each evaluated pose is held between updates | WATCH |
| [LL-099](#ll-099) | Zombie HP bars vibrate as the feet move, even though the zombie root follows a smooth path | FIXED |
| [LL-100](#ll-100) | Enabling dev mode makes global initialization crash when `print()` reads `object_index` | FIXED |
| [LL-101](#ll-101) | `load_max` cells appear on every terrain slice after dual-grid conversion | FIXED |
| [LL-102](#ll-102) | The dual-grid renderer skips every tile because a static manager method fails an instance-field check | FIXED |
| [LL-103](#ll-103) | A valid DS Grid Handle is rejected because `is_real()` returns false | FIXED |

---

<a name="ll-001"></a>
## LL-001 — An empty array slot is `0`, and `0` means "object index 0", not "nothing"

**Look for.** Buttons greyed out / nothing fires; `active=0` on every button.

**Cause.** An **empty array slot reads as `0`**, and `0` means *object index 0* = the `_button` object.

**Rule.**

* `undefined`, `noone` and `0` are all "not a button" — test all three.
* Anything taken from an array and handed to `with()` / `instance_exists()` / `position_meeting()` / a collision check must be validated first.
* If a batch operation like "disable all buttons" affects things it shouldn't, suspect an empty slot long before you suspect the loop.

**Files.** `scripts/scr_setup_menuStates/scr_setup_menuStates.gml`, `scripts/scr_button_index_enable|disable|hide/*.gml`, `objects/Menu/Step_0.gml`.

---

<a name="ll-002"></a>
## LL-002 — A runtime error aborts the rest of the event (the initialisation deadlock)

**Look for.** The same error every frame; buttons never created; the rest of the event never seems to run.

```
ERROR in action number 1
of  Step Event0 for object Menu:
Variable Menu.menu_button(100843, -2147483648) not set before reading it.
 at gml_Script_scr_menu_debug (line 62) - 	scr_menu_debug_buttons("menu_button", _menu.menu_button);
############################################################################################
gml_Script_scr_menu_debug (line 62)
gml_Object_Menu_Step_0 (line 12) -     scr_menu_debug(id, "state entered");
```

**Cause.** A runtime error **aborts the remainder of the event** — the line that would have created the variable never runs.

**Rule.**

* Initialise instance variables in Create.
* A diagnostic must never be able to throw — guard every variable it reads.

**Files.** `objects/Menu/Create_0.gml`, `objects/Menu/Step_0.gml`, `scripts/scr_setup_menuStates/scr_setup_menuStates.gml`, `scripts/scr_menu_state/scr_menu_state.gml`.

---

<a name="ll-003"></a>
## LL-003 — Functions cannot read another instance's variables (scope discipline)

**Look for.** `Variable Menu.<name> not set before reading it` from a helper; logs naming the wrong object.

**Cause.** A function **cannot read another instance's variables**; scope must be passed in or switched with `with()`.

**Rule.**

* **Pass what a function needs as arguments** — `scr_menu_debug(_menu, _where)`, `scr_button_index_enable(_arr, _i)`. Never assume `self`.
* **Read another instance's variables inside `with()`** — that is the one place GML switches scope for you. Prefer `with(_inst){ print(text) }` over `_inst.text` in diagnostics: `print()` uses `object_index`, so inside `with()` it names the *right* object automatically.
* Guard with `instance_exists(_inst)` and `variable_instance_exists(_inst, "text")` before trusting a reference.
* A helper that *must* be called "with X in scope" (and cannot take the instance as a parameter) is a smell — document the contract in the function's header comment, e.g. `scr_menu_changeState(_new_state)` starts with "Must be called with the Menu instance in scope".

**Files.** `scripts/scr_menu_state/scr_menu_state.gml`, `scripts/scr_stpButton/scr_stpButton.gml`, `scripts/scr_button_index_*/*.gml`.

---

<a name="ll-004"></a>
## LL-004 — GMS1→GMS2: a script is a function reference, not an index

**Look for.** Buttons that never fire; code that tests `script >= 0`.

**Cause.** GMS1→GMS2: a **script is a function reference, not an index**.

**Rule.**

* and replace numeric state sentinels with a real `enum` + `switch` (`MENU_STATE` + `objects/Menu/Step_0.gml`). The 6 absorbed `state_menu_*` scripts were deleted in this refactor.
* When touching imported legacy code, grep for `script >=`, `script <`, `script ==`, `script_execute(` and `state == <number>` and audit every hit.
* `is_callable()` is the only reliable "is this a function?" test.
* Prefer `enum` + `switch` over magic numbers for any state machine you touch.

**Files.** `scripts/scr_stpButton/scr_stpButton.gml`, `scripts/fcn_button_*/*.gml`, `objects/Menu/Step_0.gml`, `scripts/scr_menu_state/scr_menu_state.gml`, `scripts/scr_runState/scr_runState.gml`.

---

<a name="ll-005"></a>
## LL-005 — Project scripts that shadow GameMaker built-ins

**Look for.** Engine functions behaving strangely.

**Cause.** Project scripts shadow GameMaker built-ins: `array_concat`, `array_insert`, `array_pop` and `instance_create_depth`.

**Rule.**

* The project no longer defines those four names; delete the shadowing scripts and call the built-ins.
* After importing legacy code, list scripts and diff the names against the GMS2 function reference; rename (`scr_…`) or delete collisions: `python3 -m gm list GMScript`
* Be suspicious of any helper whose name is a bare engine verb (`array_*`, `instance_*`, `draw_*`, `string_*`).

---

<a name="ll-006"></a>
## LL-006 — Mixed LF/CRLF, and `\r` that ends up in the file as literal text

**Look for.** Whole-file diffs; the file literally contains `\r` as text.

**Cause.** **Mixed LF/CRLF** in the project, plus escape-unaware writing.

**Rule.**

* Read and write GML through the toolkit (`gm.gml.read_gml` / `write_gml`) — it never touches line endings, whatever the file uses: `python3 -m gm gml-get Menu --event Step_0`
* Never "normalise" line endings as a side effect of an edit. Preserve what is on disk and let the IDE/git decide.
* **`git add` tells you when you broke this rule - believe it.** The line `warning: in the working copy of 'objects/Menu/Step_0.gml', CRLF will be replaced by LF the next time Git touches it` on `2026-10-21` meant the whole 411-line event had come back **CRLF-only** from an editing tool that had been inserting LF lines into an LF file.
* Fix by converting back (`b.replace(b"\r\n", b"\n")`) and committing the file GameMaker will actually read - not by letting git store a normalised copy the IDE then disagrees with.
* **The EOF newline is where an "EOL-preserving" editor still leaks** (2026-10-21). Editing `objects/obj_spawn/Draw_0.gml` - a CRLF-only event - kept every *replaced* line CRLF but left the file ending `}\r\n\n`: one bare LF, because the tool appended its own newline. `grep -cF '\r'` says 0 (nothing literal), and `wc -l` looks right, so the two checks this file recommends both pass.
* Fix: rewrite the tail (`b[:-1] + b'\r\n'`), then re-run the ratio. Do this for every edited `objects/**` event, not just the ones git warned about - git only warns when the *whole* file's normalisation changes.
* **`gm gml-set` writes an event back as LF even when the file on disk is CRLF** (2026-10-28). Rewriting `objects/obj_mon/Draw_0.gml` (58/58 CRLF) via `gml-set --event Draw_0 --file` landed the content but flipped the whole file to LF - the roundtrip gate cannot see it (GML is not a .yy) and git only warns when the *whole* file's normalisation changes, which it did. The fix is bytes-level, after the write: read, `replace(b"\r\n", b"\n")`, then `replace(b"\n", b"\r\n")` - the content is already right, only the endings are wrong. Re-run the `wc -l` vs `grep -c $'\r$'` ratio after ANY `gml-set` on an `objects/**` event.

**Files.** `objects/Menu/Step_0.gml`, `objects/_levelControl/Step_0.gml`, `objects/_mainControl/Step_0.gml`, `objects/obj_spawn/Draw_0.gml`

---

<a name="ll-007"></a>
## LL-007 — `room_speed` is obsolete in GMS2  *(LIVE CODE CONVERTED 2026-10-30; runtime verification pending)*

**Look for.** Timings fire instantly or never; fades snap or hang.

**Cause.** The obsolete GMS1 speed identifier remained in live GML timers and the frame-skip switch.

**Rule.**

* Replace every read with `game_get_speed(gamespeed_fps)`, and set the speed with `game_set_speed(60, gamespeed_fps)` instead of `room_speed = 60`. Do it in one pass and re-check the timings of every affected script.

**Status.** The 26 live reads/writes across 19 GML files now use the GMS2 FPS getter/setter. The selected timer display guards its FPS divisor, and the legacy game-over transition uses `>=` so an FPS change cannot skip its exit threshold. Historical comments still name `room_speed`; there are no live code references. The runtime timing check is tracked by `gms2-room-speed-api`.

**Files.** Full inventory: progress card `gms2-room-speed-api`; entry points include `objects/Menu/Step_0.gml`, `scripts/scr_setFrameSkip/scr_setFrameSkip.gml`, and the legacy timer helpers.

---

<a name="ll-008"></a>
## LL-008 — GameMaker (the IDE) owns the project files while it is open

**Look for.** Your edit "reverted" / the file changed under you.

**Cause.** **GameMaker has the project open** and saves from its own buffers.

**Rule.**

* **Before editing**: ask the user to close the file/project in GameMaker, or at least to not save from it.
* **Before they test**: the project must be **reloaded**, otherwise the running build is the old code (a reload *does* pick up external edits — it did here).
* After the IDE has saved, re-read the files to confirm your change survived; the `.resource_order` mtime is a good tell that something saved.
* **This working copy had no `.git` directory until 2026-10-03** (`git status` used to fail). A local repo now exists with a single initial commit and no remote — and because `.gitattributes` normalises `.gml` to LF, a `git checkout` can rewrite ~90 files' line endings.

---

<a name="ll-009"></a>
## LL-009 — `.yy`/`.yyp` are not JSON: never edit them with JSON tooling

**Look for.** A one-value change produces a 1000-line diff.

**Cause.** `.yy`/`.yyp` are **not JSON** — trailing commas, key order, inline containers.

**Rule.**

* Any structural edit is finished only when `roundtrip` reports **0 differ** and the test suite is green.

---

<a name="ll-010"></a>
## LL-010 — "Request the next state, apply it at the top of the next Step"

**Look for.** A state's "just entered" code runs twice, or never.

**Cause.** **Changing state from inside a state** instead of requesting it for the next Step.

**Rule.**

* A state machine should have exactly **one** place that assigns the state variable, and it should be the first thing the Step does.
* Give every state a `time == 0` frame and put all "on entry" work in it.
* If an initialiser seems to run twice, check who else writes the state variable.

**Files.** `objects/Menu/Step_0.gml`, `scripts/scr_menu_state/scr_menu_state.gml`, `scripts/fcn_button_*/*.gml`.

**See also.** [LL-004](#ll-004)

---

<a name="ll-011"></a>
## LL-011 — How to instrument, so the next bug takes one run instead of ten

**Look for.** Not a bug — the method that finally made LL-001 and LL-002 obvious.

**Cause.** **How to instrument the game** so the next bug takes one run, not ten.

**Rule.**

* Not a bug — the method that finally made LL-001 and LL-002 obvious.
* `print()` (in `scripts/print/print.gml`) is already dev-gated by `global.devMode` and prefixes every line with the time, the object name of the current scope and an instance id, e.g. `Menu:100843 MENU [state entered] state=START time=0 next=-1`.
* **Use prefixes** so one grep gives you the whole trail: `MENU `, `BTN `, `FADE `, `SND `.
* every **button create / init** (`BTN create`, `BTN init`);
* every **click** and the decision after it (`BTN click`, `BTN call`, `BTN SKIP`);
* every **state entry** (`MENU now`, then a full dump);

**Files.** `scripts/print/print.gml`

**See also.** [LL-001](#ll-001), [LL-002](#ll-002)

---

<a name="ll-012"></a>
## LL-012 — A text object has no sprite, so `sprite_get_width(-1)` is fatal (and rescaling eats your flip)

**Look for.** `sprite_get_height ... requested -1` once per step; a sprite flip that "does nothing"; a tower that un-mirrors - or draws upside-down - when it is upgraded.

```
ERROR in action number 1
of  Step Event0 for object _text_rise:
sprite_get_height argument 1 invalid reference to (sprite) - requested -1 max is 122
 at gml_Script_scr_scale_sprite (line 11) - 	image_yscale = argument1/sprite_get_height(sprite_index);
gml_Script_scr_scale_sprite (line 11)
gml_Object__text_rise_Step_0 (line 20) - scr_scale_sprite(_w,_h);
```

**Cause.** A **text object has no sprite** (`sprite_index == -1`, fatal in GMS2) and the shared scale helper **overwrote `image_xscale`**; `image_xscale` carries size **and** facing in one number.

**Rule.**

* **A helper that reads `sprite_index` must survive `sprite_index == -1`** — test `sprite_exists()` (or `< 0`) before any `sprite_get_*`, and treat "no sprite" as "nothing to scale", never as a 0×0 sprite.
* **Before blaming a flip, find what re-derives the scale every step** — `scr_scale_sprite`, `scr_scaleButton` or a `lerp` scale tween overwrites `image_xscale` on every call.
* An object with no sprite has no mask, so `place_meeting()`, `position_meeting()` and `bbox_*` are dead code in it.
* **When you add a flip, grep both sides of it**: every *writer* of `image_xscale` on that object (a `lerp` tween, `scr_scale_sprite`, a "reset the scale" line — each will eat the flip or invert it), and every *reader* (`draw_self_part`, `scr_drawLight`, `scr_drawReflections`, `sprite_width`-based click boxes).

**Files.** `scripts/scr_scale_sprite/scr_scale_sprite.gml`; `objects/_text_rise/Step_0.gml` line 20 (now a harmless no-op); `objects/_text_rise/_text_rise.yy` (`spriteId` is `null`). Added by the 2026-10-11 extension: `scripts/scr_tower_faceTarget/` `scr_tower_faceTarget.gml` (new), `objects/obj_tower/Step_0.gml`, `objects/_levelControl/Step_0.gml`, `scripts/scr_drawLight/scr_drawLight.gml`.

---

<a name="ll-013"></a>
## LL-013 — A discarded return value is a silent failure (and validate the whole system, not the entrance)

**Look for.** A zombie **freezes** on the map; the wave never ends; only a restart helps.

**Cause.** A **placement that pockets a monster**, and a **discarded `mp_grid_path` return value** that made the failure silent.

**Rule.**

* Refuse, then always heal.
* A placement is refused if a monster occupies the cell, if the spawn route is sealed, **or if any monster on the map cannot reach the despawn**. That last check is what makes a pocket impossible by construction.
* `scr_zombie_path` captures the return value and schedules a retry on failure.
* The monster's re-path alarm **escalates**: after ~2 s of polite retrying it walks an **empty grid**, ignoring the towers entirely, so `instance_number(obj_mon)` can always reach `0`.
* `scr_level_wait` has a last-resort valve: monsters alive 6 s past the wave timer are cleared, with a loud `PATH` warning.
* **Capture every return value** that reports success/failure. `mp_grid_path`, `file_*`, `ds_map_*` — `if(!ok){ ... }` on the same line as the call is the cheapest guard you will ever write. A discarded `false` becomes "it just doesn't work sometimes", which is the most expensive kind of bug.

**Files.** `scripts/scr_path_validate`, `objects/obj_mon/Alarm_0.gml`, `objects/obj_mon/Create_0.gml`, `objects/obj_mon/Collision_obj_tower.gml`, `scripts/scr_zombie_path`, `objects/obj_tower_edit/Step_0.gml`, `objects/obj_tower/Destroy_0.gml`, `scripts/scr_level_wait`.

---

<a name="ll-014"></a>
## LL-014 — One variable doing two jobs: the pause screen went black

**Look for.** The pause / exit screen is **black**.

**Cause.** **One variable doing two jobs** - `blackScreen` is the game-over crossfade, and pause read it; plus a surface **size mismatch** and a **mid-frame grab**.

**Rule.**

* Capture at the **application surface's own size** and draw the result **stretched to the GUI size**, so no size assumption survives anywhere.
* Pause gets its **own** alpha (`pause_alpha`) and resets `blackScreen = 0` on entry. The black score background is gated on the **state** (`gameOver`/`highScore`), not on `blackScreen` alone.
* The grab moved to the **very top of Draw_75** — which is the Draw GUI End event (75), the *last* pass of the frame, so `application_surface` is fully composed there.
* **Never-black promise:** with no usable snapshot, draw the text over the existing screen and skip everything that could darken it. The worst case is "pause without the blur", never "pause with nothing".
* **A variable that gates one state's transition must not be read by another state.** If two states need "how faded am I", they need two variables.
* **Never assume two surfaces are the same size.** `application_surface` is resized explicitly at startup; `display_get_gui_width()` is a different thing. Ask `surface_get_width(application_surface)`, and draw stretched.

**Files.** `scripts/scr_drawBlurScreen`, `objects/_mainControl/Draw_75.gml`, `objects/_mainControl/Other_5.gml`, `scripts/scr_main_pause`, `scripts/scr_setup_main`, `scripts/scr_initResolution`, `scripts/scr_draw_main_text`.

---

<a name="ll-015"></a>
## LL-015 — `array_last_index()` is not a count, and a UI can hide its own numbers

**Look for.** A UI is **missing information** that was never once displayed.

**Cause.** **`array_last_index()` used as a count** hides the last element, and a label list that was never extended.

**Rule.**

* The same work replaced a **256×256 panel centred on the screen** (with its own "Tower Range" label *and* a second copy of the stats, while the range circle drew at full strength beside it) with **one fixed card** docked in a corner, showing `DMG · RATE · RNG · TGT · DPS` with the deltas a purchase buys.
* **`array_last_index` is `length - 1`.** Use `array_length` for bounds. The off-by-one is invisible when the dropped element is the least important one.
* When you add a field to a data array, **grep for every place that enumerates the array** and add the label there too. A field that exists but is never printed is worse than a field that does not exist, because it looks finished.
* **Index labels by the enum, not by position in a hand-written list.** Two lists that must stay in step will not.
* Two elements competing for the same screen space is a *layout* bug, not a polish item: the fix is to make it one element.
* A delta (`125 → 250`) explains a purchase better than any tooltip, and costs two numbers. Compute it with the **same arithmetic the purchase uses**, so the card cannot promise something the upgrade does not deliver.

**Files.** `scripts/scr_dataToString`, `scripts/scr_drawTowerSelected`, `scripts/scr_drawTowerMod`, `objects/_levelControl/{Create_0,Draw_64,Draw_73,Step_0}.gml`.

---

<a name="ll-016"></a>
## LL-016 — A parameter is not visible in a sibling function (and an unreachable line hides a fatal)

**Look for.** Nothing - yet.

**Cause.** A **sibling function's parameter is not in scope**, so a fatal sat behind an unreachable branch.

**Rule.**

* `to_key(x,y)` — the key the function was actually asked about. The memo now works, and there is no undefined variable to read.
* **A parameter belongs to the function that declares it.** Inside a struct, do not assume a sibling method's parameters are visible — they are not.
* **An unreachable branch is not a test.** "It has never thrown" means the line has never run. When you find a variable that does not exist in scope, fix it even if it looks dead — the thing that made it dead is usually a bug itself.
* **A generator must not reseed the global RNG.** Save `random_get_seed()`, use your own, then restore.
* If a guard can never be true, the guard is not protecting anything: check whether the *condition* is wrong, not just the body.

**Files.** `scripts/create_perlin_grid/create_perlin_grid.gml`.

---

<a name="ll-017"></a>
## LL-017 — `instance_exists()` on an unassigned `globalvar` is itself a throw

**Look for.** A new "safety" guard crashes on a line that looks defensive, only before an object's Create has run.

**Cause.** **`instance_exists()` on an unassigned `globalvar` is itself a read of an unset variable**.

**Rule.**

* `instance_exists(x)` is not a validity test for `x`. It asserts something about an instance id, so `x` must already be a valid id.
* Any code that can run *before* an object's Create - a script called from another object, a `Destroy`, a `lose_life`, a diagnostic - must test the global with `variable_global_exists()` first, then the instance.
* The same applies to `variable_instance_exists()`: it needs a live instance.

**Files.** `scripts/lose_life/lose_life.gml`, `objects/_levelControl/Create_0.gml`.

**See also.** [LL-002](#ll-002)

---

<a name="ll-018"></a>
## LL-018 — A verifier that compares against `git show HEAD:` lies about line endings

**Look for.** A check script reports "line endings changed" for files nothing touched; `git diff` says otherwise.

```
warning: in the working copy of 'objects/Menu/Step_0.gml',
         CRLF will be replaced by LF the next time Git touches it
```

**Cause.** Comparing against **`git show HEAD:`** compares a *normalised* blob (LF) against a CRLF working tree.

**Rule.**

* **No literal backslash-r** — the two-byte run must count as `0` in the file's raw bytes (grep for it with a fixed-string match; see LL-006).
* **Composition** - count CRLF and bare LF and report the kind, and confirm the file did not *become a different kind* of file.
* **No wholesale rewrite** - `git diff --numstat` (added/removed per file) must match the size of the edit. A line-ending rewrite shows up as "every line changed"; a real edit does not.
* `editlib.replace_lines` writes new lines with the file's **own dominant ending**, so it cannot convert a file. That is why the composition check is the right one, and why a "before/after kind" comparison is the meaningful assertion.
* Any automated check that disagrees with `git diff` about *what changed* is almost always wrong about *how git stores bytes*, not right about a bug.
* Corollary for agents: a false-positive verifier costs as much time as a missing one, because it sends you looking for a fault that does not exist.

**Files.** `AGENTS.md` §1.3, this file's LL-006; the check lives in the Phase 1 verification script.

**See also.** [LL-006](#ll-006)

---

<a name="ll-019"></a>
## LL-019 — `visible = false` does not hide an object that has its own Draw event

**Look for.** Buttons that were "hidden" are **still drawn**, still hover, still beep, and sit over the screen that replaced them.

**Cause.** **`visible = false` only affects the built-in sprite draw** - an object with its own Draw event must check it itself.

**Rule.**

* Make the flag mean something at both ends.
* **`visible` is not a cross-cutting "hide me" flag.** It is a draw hint for the built-in renderer. Any object with a custom Draw event must check it itself - so check it in *every* custom Draw, and in any Step code that reacts to the mouse.
* When a helper "hides" something, **verify it visually in one run**, not by reading the helper. The helper here was correct; the consumer was not.
* Grep for the pattern: a script that sets `visible`, and the object's Draw event that never reads it.
* `active = false` alone is not a hide. It stops the *action* and leaves the button on screen and noisily clickable - which is more confusing than not disabling it at all.

**Files.** `scripts/scr_draButtonGUI/scr_draButtonGUI.gml`, `scripts/scr_stpButton/scr_stpButton.gml`, `scripts/scr_button_index_hide/scr_button_index_hide.gml`, `objects/Menu/Step_0.gml`.

---

<a name="ll-020"></a>
## LL-020 — A persistent instance outlives the non-persistent data it draws

**Look for.** `Unable to find instance for object index 1` from `_shadows` Draw, every frame, after finishing a level.

```
ERROR in action number 1
of Draw Event for object _shadows:
Unable to find instance for object index 1
 at gml_Script_scr_drawLight (line 13) -         _sx = _DAY.shadow_offset[0],
gml_Script_scr_drawShadows (line 22) -     scr_drawLight(_scale);
gml_Object__shadows_Draw_0 (line 2) - scr_drawShadows();
```

**Cause.** A **persistent instance whose dependency did not persist** — `_shadows` survives the room change, `_dayCycle` does not.

**Rule.**

* Guard the reference (the LL-012 shape) *and* stop the pile.
* **An instance may only outlive another if the thing it reads outlives it too.** `_shadows` reads `_dayCycle` every frame, so they must share a lifetime - either both persist or neither does. Grep the pair, not just the object named in the error.
* A guard **at the consumer** (`instance_exists()` before a `.var` read) turns a fatal into "it did not draw this frame". Put it in *every* function that dereferences a sibling, not only in the Draw event that happened to call it.
* **Creation inside a re-run initialiser must be idempotent.** An `instance_create*` in a `scr_ini*` that runs once per level is a duplicate generator the moment the object is persistent.

**Files.** `scripts/scr_drawLight/scr_drawLight.gml`, `scripts/scr_drawShadows/scr_drawShadows.gml`, `scripts/scr_iniLighting/scr_iniLighting.gml`.

**See also.** [LL-012](#ll-012)

---

<a name="ll-021"></a>
## LL-021 — Two sources of truth for "what a level is": a map that can create a stage

**Look for.** A stage can be Deployed to that has no level data, and it silently plays stage 1.

**Cause.** The world map's 6x10 grid and the authored stage table are **two sources of truth** that never compared.

**Rule.**

* `stage_get()` / `stage_current()` / `stage_count()` are now thin wrappers over the one list, so every existing caller moved without changing.
* **A screen that enumerates things must enumerate the same list the game plays from.** A hardcoded count (`6 x 10`) beside a data table is two truths that will drift the moment one is edited.
* **A fallback that swallows "not found" hides exactly the bug you want to see.** Keep the fallback so nothing throws (LL-002), but add a gate that refuses the input *before* the fallback can matter.
* Build shared data **once, at init**, and hand everyone the same list - a list rebuilt per screen is a list that can be a different list per screen.

**Files.** `scripts/GameLevelData/GameLevelData.gml` (new), `scripts/stage_data/stage_data.gml`, `scripts/initialize_game/initialize_game.gml`, `scripts/scr_meta_screen/scr_meta_screen.gml`, `objects/Menu/Step_0.gml`.

**See also.** [LL-002](#ll-002)

---

<a name="ll-022"></a>
## LL-022 — Two curves that only mean something together (wave ramp vs tower ladder)

**Look for.** 60-wave stages come out either trivial or unbeatable, depending on which half gets landed first.

**Cause.** The wave ramp and the tower-level ladder are **two curves that only mean something together**.

**Rule.**

* Make both of them data, then make the shape legible.
* `m(1) = 1.00` in EVERY biome (so one set of tower numbers survives sixty stages), `curve_end` per region (30 → 125), and `curve_pow = 2` because a stage's money grows with the **square** of the wave number. * The ladder became `tower_levels.gml` — a level is `base × ladder` and never compounds, and cap/floor come from the garden — and it landed in the **same change** as the curve.
* **A constant tuned against another constant is not a constant, it is a coupling.** Write it down next to its partner. `economy.md` §4.4 and `goal.md` §4 both said "they are one change" and it was *still* nearly landed in two halves.
* **Check a curve where it is steepest, not where it is comfortable.** The old ramp is perfectly reasonable at wave 10 and absurd at wave 60.
* **Match the ramp to the income, not to a feeling.** Rewards per wave grow ~quadratically (`spawn_count + wave div 5`); a ramp that tracks that stays reachable, and an exponential one never can.
* When two tables must agree (a price and a worth), **write the inequality down** — `Δdps ÷ Σprice ≥ dps-per-money` — so a violation is arithmetic rather than an argument. Doing that is how §4.6 was found.

**Files.** `scripts/region_data/region_data.gml` (new), `scripts/tower_levels/tower_levels.gml` (new), `scripts/GameLevelData/GameLevelData.gml`, `scripts/stage_data/stage_data.gml`, `scripts/scr_level_difficulty/scr_level_difficulty.gml`, `scripts/difficulty_data/difficulty_data.gml`, `scripts/scr_level_spawn/scr_level_spawn.gml`, `scripts/scr_zomb_death/scr_zomb_death.gml`, `scripts/scr_zomb_pathSpeed/scr_zomb_pathSpeed.gml`, `objects/_levelControl/{Create_0,Step_0}.gml`, `objects/obj_tower/Create_0.gml`, `objects/obj_tower_edit/Step_0.gml`, `scripts/scr_placeTower/scr_placeTower.gml`.

---

<a name="ll-023"></a>
## LL-023 — A convention nobody checks gets broken by its author, within the hour

**Look for.** The board's "waiting on you" strip slowly fills with parked work.

**Cause.** A rule that lives in **prose only** — the validator checked each field's shape but never compared two fields.

**Rule.**

* **If a doc states a rule, ask which command enforces it.** If the answer is "none", the rule is a wish. This is [LL-021](#ll-021) one level up: not two data sources that never compared, but a data source and *its own documentation*.
* **Derive a field when you can, instead of storing it.** There is no `blocked` status in the tracker — it is `awaiting != none` on an unfinished card, and a derived field cannot disagree with itself.
* **Any checked-in file built from another file needs a gate.** `PROGRESS.md` and `progress.html` carry a `progress-sha` and `gm progress check` fails when they disagree with `progress.json`, so "forgot to rebuild" is a red test instead of a board that quietly lies. Verify the gate *bites*: edit the JSON, watch it go red.
* **Put the rule where it is cheap to obey.** A validation error is a fix; a paragraph in `AGENTS.md` is a reminder.
* **A card that says "nothing exists" is a claim about the repo, and the repo can answer it in one command.** `art-belladonna-trio` said *"Belladonna has NOTHING — a tower with `sprite_index -1` is a fatal error"* for four days while `spr_bella_idle_192x`, `_attack_` and `_return_` sat in `sprites/` (added 2026-10-12, card written 2026-10-15).

**Files.** `python_tools/gm/progress.py` (`validate`), `python_tools/tests/test_gm.py` (`ProgressTests`), `progress.json`, `AGENTS.md` §6.

**See also.** [LL-021](#ll-021)

---

<a name="ll-024"></a>
## LL-024 — A call to a function that was never defined reports as a *variable* read, in the CALLER's scope

**Look for.** `Variable <caller>.<name> not set before reading it` for a name you *know* is a function; the numbers in the parentheses look like corrupt arguments.

```
of  Step Event0 for object _levelControl:
Variable _levelControl.tower_upgrade_price(101533, -2147483648) not set before reading it.
 at gml_Object__levelControl_Step_0 (line 94) -  tower_price_save[0] = tower_upgrade_price(tower_selection.base_price,
```

**Cause.** The function was **never defined** — GameMaker names the **calling scope**, and the parentheses are *(instance id, internal id)*, **not the arguments**.

**Rule.**

* **When the failing name looks like a function, grep for its definition before you chase its arguments:** `grep -rn 'function <name>' --include='*.gml' .`. Zero hits means "never defined", full stop — not "set later".
* **A `not set before reading it` error proves nothing about which file is at fault.** The scope in the message is *the caller*. Read it as *"this call site is unbound"*, then go find (or write) the other end.
* **Never treat the parenthesised values in a runner error as arguments.** They are *(instance id, internal id)*. If they look like garbage to an argument reading, that is because they are not arguments.
* **A refactor that adds call sites needs a "does it define?" pass** in the same change. After touching an event, list its `name(` calls and confirm each has a `function name` somewhere (or is a real built-in). This is the same shape as the wave-curve lesson ([LL-022](#ll-022)): two ends of one change that must land together.

**Files.** `objects/_levelControl/Step_0.gml` (the call sites, lines 54/94/167), `scripts/tower_levels/tower_levels.gml` (the definitions).

**See also.** [LL-002](#ll-002), [LL-022](#ll-022)

---

<a name="ll-025"></a>
## LL-025 — A monster marches north through every wall (because its path was thrown away first)

**Look for.** Monsters walk **north, straight through walls**, mid-wave, even when the level has a clear route; the wave then ends via the 6 s valve.

```
PATH  WARNING: 3 monster(s) still alive 6s past the wave - forcing the wave to end so the stage cannot hang
```

**Cause.** A **draw-only `y` offset applied twice** (Pre Draw *and* Post Draw) that only bites once `Alarm_0` has **thrown the live path away on a failed re-path** — a monster with no path is a monster nothing rewrites.

**Rule.**

* Never move the instance in Draw, and never throw away a route you cannot replace.
* `obj_mon/Alarm_0` — both the polite re-path and the last-resort escape — and the first path in `scr_zombie_path` now go through `scr_path_replace(...)`: the monster keeps walking what it has until a *replacement* exists, and is only ever `path_start`ed on a path that has points.
* `obj_mon/Create_0` adds a scratch `path_probe`; `Destroy_0` frees both paths (neither was ever freed, so every zombie leaked its path).
* `obj_tower/Create_0` blocks **the cell** and remembers it in `grid_block`; `Destroy_0` clears that same rectangle; `obj_tower_edit/Step_0` checks that same footprint — so add, clear and check finally agree.
* **A draw-only offset must be applied and removed in the same frame.** Pre Draw/Begin Draw shifts, Post Draw/End Draw restores, and the restore is the exact inverse (`-=` then `+=`, never `-=` twice). An unmatched write of `x`/`y` in a Draw event drifts the instance at the frame rate.
* **Never destroy state you cannot rebuild.** Emptying a path/array/queue before you know the new value exists turns "this failed" into "there is nothing here any more". Probe, then commit.

**Files.** `objects/obj_mon/Draw_72.gml`, `objects/obj_mon/Draw_73.gml`, `objects/obj_mon/Alarm_0.gml`, `objects/obj_mon/Create_0.gml`, `objects/obj_mon/Destroy_0.gml`, `scripts/scr_zombie_path/scr_zombie_path.gml`, `scripts/scr_path_validate/scr_path_validate.gml`, `objects/obj_tower/Create_0.gml`, `objects/obj_tower/Destroy_0.gml`, `objects/obj_tower_edit/Step_0.gml`.

---

<a name="ll-026"></a>
## LL-026 — A persisted function reference comes back as a number, and `script_execute()` runs the wrong script

**Look for.** The same `Variable Input.<name> not set before reading it` every step, naming a function that event never calls.

**Cause.** A **saved function reference**: an array of listeners (`key_type`) was persisted through `ds_list_write` and came back callable-but-stale - it ran whatever script the handle then indexed (see [LL-028](#ll-028)).

**Rule.**

* Never persist a function, never dispatch a value you have not checked, and never read a possibly-missing object as a bare name.
* `key_type` is fixed by the device (keyboard or gamepad), not the player, so rebuilding it every launch is always correct; only `key` and `key_name` are worth saving.
* **`ds_list_write`/`ds_list_read` cannot store a function** (nor can an `ini`/`json` round-trip). Anything holding callables — key listeners, button callbacks, timer scripts — must be *rebuilt* on load, or saved as a **name** and resolved with `asset_get_index()`.
* **Never `script_execute()` a value that might not be a function - dispatch through `run_script()` (LL-028).** It checks `is_undefined()` and `is_callable()` first, binds the call to a target instance with `method()` when asked, and forwards an `arguments_list` array.
* **A saved value outlives the code that wrote it.** Asset indices are not stable across a conversion or a growing project, so a numeric reference on disk is a landmine; never let one reach a dispatcher.
* **When the stack names a function you never call, read the caller's *dispatch* line, not the caller's text.** Line 4 dispatched an array element; the function it named was never written in that file. (LL-024 is the mirror image — there the *callee* was the surprise.)

**Files.** `objects/Input/Step_0.gml`, `scripts/scr_load_keys/scr_load_keys.gml`, `scripts/scr_save_keys/scr_save_keys.gml`, `scripts/scr_drawTimerExt/scr_drawTimerExt.gml`, `scripts/scr_save_gamepad/scr_save_gamepad.gml`, `scripts/scr_load_gamepad/scr_load_gamepad.gml`.  Every one of its `script_execute()` dispatches now goes through `scripts/run_script/` (LL-028).

**See also.** [LL-028](#ll-028), [LL-004](#ll-004), [LL-024](#ll-024), [LL-002](#ll-002), [LL-012](#ll-012)

---

<a name="ll-027"></a>
## LL-027 — `mp_grid_add_rectangle` / `mp_grid_add_instances` walk their range INCLUSIVELY, so a rectangle the size of one cell blocks two

**Look for.** Pathfinding is still off: monsters take odd routes or cannot leave their pen, as if a tower or wall covered more than its cell; **no error**.

**Cause.** **`mp_grid_add_rectangle`/`mp_grid_add_instances` floor BOTH edges and iterate INCLUSIVELY**, so a rectangle the size of one cell blocks two (a 2x2) — block a **cell by index** instead.

**Rule.**

* Block the **cell an instance's origin falls in**, by index, everywhere. Never a rectangle.
* `obj_tower/Create_0` blocks its one cell and remembers `grid_col`/`grid_row`; `obj_tower/Destroy_0` clears exactly that cell, so add and clear cannot drift apart whatever the tower's `image_xscale` has become.
* `obj_tower_edit/Step_0` blocks one cell for the candidate and one cell per existing blocker.
* A new helper `scr_grid_block_instances(grid, obj)` (in `scr_path_validate`) replaces **every** `mp_grid_add_instances(...)` over the live grid - `scr_resetDrawPath` and `obj_mon/Alarm_0` - one cell per instance, from `x/y`.
* **A rectangle is not a cell.** `mp_grid_add_rectangle` and `mp_grid_add_instances` are inclusive on the far edge, so a rectangle whose edges land on cell boundaries marks one cell too many on each axis. When you mean "one cell", say `mp_grid_add_cell`.
* **A footprint must not depend on `image_xscale`.** The old code blocked `bbox_*`, which changes when a tower is re-scaled on upgrade. Deriving the cell from `x/y` is scale-independent. (This is *why* LL-025 moved off `bbox_*` - the move just picked the wrong replacement.)

**Files.** `objects/obj_tower/Create_0.gml`, `objects/obj_tower/Destroy_0.gml`, `objects/obj_tower_edit/Step_0.gml`, `scripts/scr_path_validate/scr_path_validate.gml`, `scripts/scr_resetDrawPath/scr_resetDrawPath.gml`, `objects/obj_mon/Alarm_0.gml`.

**See also.** [LL-025](#ll-025)

---

<a name="ll-028"></a>
## LL-028 — A saved function reference comes back **still callable**, and its handle shifts when the project gains a script

**Look for.** The LL-026 error again, but naming a **different** script and an unrelated object, changing each rebuild.

**Cause.** A saved function reference comes back **still callable**, on a handle that shifts when the project gains a script; `is_callable()` cannot spot it, so `key_type` must never be loaded.

**Rule.**

* Every dispatch in the project now also goes through `run_script()` (LL-026), which refuses an undefined or non-callable name. That closes the *other* half of the hole — a genuinely non-function value — but it cannot close this one.
* **A saved function reference is still a function.** `is_callable()` is not a validity check; do not use it to "sanitise" a value that came off disk. The only safe rule is **never to load one**: rebuild it, or store a `string` name and resolve it with `asset_get_index()`.
* **An index that survives a save is a landmine.** Adding or removing any resource renumbers the table, so a handle from an old save silently points at a *different* function. When a dispatch "changes its mind" after an unrelated change, suspect a saved reference.
* **The listener belongs to the device, not the player.** `key_type` is built by `scr_setup_keyboard()`/`scr_setup_gamepad()` and has no business in a save file — which is also why validating it could not fix the bug.
* **Check for siblings.** `key_type` was the only function *array* ever written to a save file here (options, bags, high score and the static inventory are all numbers), but `scr_saveArray`/`scr_loadArray` is shared: audit anything new that puts a callable in one.
* **A save file outlives the build that wrote it.** Blank slot "1" on save and keep the read gone even so.

**Files.** `scripts/scr_load_keys/scr_load_keys.gml`, `scripts/scr_save_keys/scr_save_keys.gml`, `scripts/scr_load_gamepad/scr_load_gamepad.gml`, `scripts/scr_save_gamepad/scr_save_gamepad.gml`, `scripts/run_script/run_script.gml`, `objects/Input/Step_0.gml`.

**See also.** [LL-026](#ll-026)

---

<a name="ll-029"></a>
## LL-029 — Never exit a state on equality with a value another system can scale

**Look for.** A tower loops its **attack animation** forever and stops dealing damage; only after it has been **upgraded**; no error.

**Cause.** A state exit gated on `state_time == frame_number`, where `frame_number = room_speed/fire_rate` is a **float** once the level ladder / clover bonus scales `fire_rate` — an integer can never equal it.

**Rule.**

* The same change re-checks the target list every frame, so a target that dies (or leaves range) mid-swing returns the tower to idle instead of leaving it swinging at a corpse.
* **Never gate a state exit on `==` against a value another system scales.** Use `>=` (or an animation counter). The fractional multiplier lives in a *different* file (`tower_levels.gml`), so this looks like a tower bug when it is really a coupling bug.
* **A `time == N` beat that fires once needs a one-shot flag** if you relax the test to `>=`, or it fires on every frame from `N` onward.
* **`floor()`d comparisons are safe; raw floats are not.** The damage beat had used `floor(frame_number - time_offset)` and was fine — the exit did not, and that asymmetry is the tell.
* **When a state machine "hangs", suspect a test that can never be true** before suspecting the log: there was no error, because nothing threw.

**Files.** `scripts/scr_tower_shoot/scr_tower_shoot.gml`, `scripts/tower_levels/tower_levels.gml`.

---

<a name="ll-030"></a>
## LL-030 — An animation timed with a SPEED instead of a DURATION

**Look for.** A tower's **idle / return animation plays far too fast** after its sprite is re-drawn with fewer frames; no error, and no code was changed.

**Cause.** Two states set **`image_speed` (a SPEED) where a duration was meant**, so the period scaled with the frame count: 5 frames at `0.25` is 20 steps, not the 60 the 15-frame art took.

**Rule.**

* `scr_animSpeedForSteps(sprite, steps)` returns `(frames / steps) / declared_speed` — the multiplier that makes one pass of the animation span `steps` steps whatever the frame count. It normalises the sprite's declared speed first, because a sprite may declare **frames per second** or **frames per game frame** (`sprite_get_speed_type`), and `image_speed` multiplies whichever it is.
* `scr_tower_animSpeed(slot, steps)` is the ONE place a tower's playback speed is set: it looks the sprite up in `sprite_list` (now indexed by the `TOWER_ANIM` enum) and logs the period once per animation per tower.
* The durations live with the sprites, as `anim_seconds` in `objects/obj_tower/Create_0.gml` (`1.00` s idle, `0.25` s return; the attack's length is the fire rate, so `scr_tower_shoot` supplies it).
* The return state's exit became a **time** test (`state_time >= anim_steps`) because its length is now a number of steps — the old `image_index >= image_number-1` fires up to a frame early once the speed is fractional, and it exits on a value the frame count scales (LL-029).
* **If a timing must not change when the art changes, store a DURATION, not a speed.** Never hard-code `image_speed`; derive it from `sprite_get_number()`. `image_number` *is* the frame count, so "the same period whatever the frames" is one division.
* **`image_speed` is a multiplier, not frames-per-step.** It only looked like frames-per-step here because every sprite declares 1 frame per game frame. Check `sprite_get_speed_type()`, or a sprite that declares FPS will silently change period with the game's frame rate.

**Files.** `scripts/scr_animSpeedForSteps/scr_animSpeedForSteps.gml` (new), `scripts/scr_tower_animSpeed/scr_tower_animSpeed.gml` (new), `scripts/scr_tower_normal/scr_tower_normal.gml`, `scripts/scr_tower_return/scr_tower_return.gml`, `scripts/scr_tower_shoot/scr_tower_shoot.gml`, `objects/obj_tower/Create_0.gml`, `objects/obj_tower_edit/Create_0.gml`, `scripts/tower_enums/tower_enums.gml`.

**See also.** [LL-029](#ll-029)

---

<a name="ll-031"></a>
## LL-031 — A safety valve that fires on a stopwatch cannot tell **slow** from **stuck**, so the net becomes the normal path

**Look for.** Zombies **vanish a few seconds into every wave** and the wave moves on; nothing reaches the exit, nothing is killed, and the **lives counter never moves**.

**Cause.** A **safety valve firing on a stopwatch** (6 s after the wave's last spawn) deleted the whole wave - a stopwatch cannot tell *slow* from *stuck*, and a zombie needs 20-45 s to walk a stage.

**Rule.**

* **`path_position`, not `x/y`.** An instance whose path has been thrown away can still *drift* in `x/y` — in [LL-025](#ll-025) an unbalanced draw offset marched a zombie north through every wall, every frame — so a movement test would have called that monster "walking". A frozen `path_position` means no follower is driving it at all.
* **`==` is correct *here***: both sides are reads of the **same stored float**, so equality means the follower did not write it this step. [LL-029](#ll-029) is the opposite case — `==` against a value *derived* from a moving quantity.
* **Five seconds, not two**: `obj_mon/Alarm_0` legitimately needs up to ~2 s to escalate before it takes the tower-ignoring escape grid, and a monster being rescued must not be deleted for being rescued.
* **A ten-minute per-wave latch** (`wait_valve_fired`, `>=`) keeps roadmap 4.4.1's promise for a monster that never stops moving *and* never arrives. `>=` plus a one-shot flag, never `==`: the frame budget is read from the FPS setting, which can change mid-wave, and the old `== _fps * 6` is a valve that silently never opens the moment that value moves.
* **Every fate is now labelled exactly once** — `kill` (`scr_zomb_death`), `leak` (`lose_life`), `valve` (`scr_level_wait`) — plus one line per monster, `path 1408px @ 0.75px/step = ~1877 steps (~31s to the despawn)`, which is where a future threshold must be *derived* from rather than guessed.
* **A safety valve must fire on evidence about the thing it protects, never on a stopwatch.** "It has been long enough" is a guess about *slow*; only a failed progress test is evidence of *stuck*.

**Files.** `scripts/scr_level_wait/scr_level_wait.gml`, `objects/obj_mon/Create_0.gml`, `scripts/scr_zomb_updatePosition/scr_zomb_updatePosition.gml`, `scripts/scr_setupSpawning/scr_setupSpawning.gml`, `scripts/scr_level_spawn/scr_level_spawn.gml`, `scripts/lose_life/lose_life.gml`, `scripts/scr_zomb_death/scr_zomb_death.gml`, `scripts/scr_zombie_path/scr_zombie_path.gml`.

**See also.** [LL-025](#ll-025), [LL-029](#ll-029)

---

<a name="ll-032"></a>
## LL-032 — The progress gate is transactional for `set`/`add` only, so a hand edit that breaks it blocks every later write

**Look for.** `gm progress` says "nothing written", and then **every** later `gm progress add` fails the same way.

```
ERROR   focus.now points at unknown task 'audio-briefs'
nothing written - fix the values above and try again
```

**Cause.** The gate is transactional for `set`/`add` only - a **hand edit** that points `focus` at a card that does not exist yet stays on disk and blocks every later write.

**Rule.**

* `gm progress add <id> ...` for every new card;
* *then* point `focus.now` / `focus.next` at them;
* `gm progress build` in the same change.
* If the file is already stuck, restore the `focus` block (`git diff progress.json` has the previous value) and re-run the adds before re-applying the focus. Do **not** delete the check.
* **A gate that runs on write is not a transaction.** `nothing written` describes *that command*; run `git diff` before assuming the file is unchanged.
* **A pointer field is written last.** Anything that references another record (`focus.now`, `refs`, `needs`) has an order, and it comes after the record exists.

**Files.** `python_tools/gm/progress.py` (`validate`, `_edit`), `progress.json`, `AGENTS.md` §6.

---

<a name="ll-033"></a>
## LL-033 — A collision mask scales with `image_xscale`, so `mask_index` alone cannot give an object a fixed footprint

**Look for.** A hand-drawn click mask "does nothing": the clickable area still hugs the artwork and is half the size it should be; and the placement ghost refuses the cell **above** an existing tower.

**Cause.** A collision mask **scales with `image_xscale`** and `mask_index` does not exempt it - so "draw the art small" and "keep the mask fixed" were the same number; and a mask cannot answer "is this CELL taken".

**Rule.**

* Everything that read the size went with it: the shadow silhouette in `scr_drawLight` (multiply by the instance's `draw_scale` when it has one), the hover glow in `scr_drawGlowOutline` (passed in), the in-water part-draw in `draw_self_part` (optional `_sx`/`_sy`, defaulting to `image_xscale` so every existing caller is untouched) and the upgrade tween in `_levelControl/Step_0` (writes `draw_scale`, so it can no …
* **A mask of a fixed size needs the instance's scale to be 1.** There is no `mask_index` trick around it. Draw at the size you want with `draw_sprite_ext` / `draw_sprite_pos` and leave `image_xscale` alone.
* **Count the jobs before writing `image_xscale`.** Size, facing and mask are three questions, and anything derived from `sprite_width` or `sprite_xoffset` is a fourth. This is [LL-012](#ll-012) one level deeper: LL-012 lists the three ways a flip dies, and this is the fourth thing the same variable was carrying.
* **`sprite_width`, `sprite_height`, `sprite_xoffset` and `sprite_yoffset` all include the image scales**, so anything built on them follows the ART and not the mask once the two are decoupled. `sprite_get_width` / `sprite_get_xoffset` are the unscaled ones.
* **Grep for the consumers, not just the writer.** The size had five readers, and three of them were in files nowhere near the tower.
* **A mask answers "is this POINT inside the ART"; it cannot answer "is this CELL taken".** For occupancy ask the grid - and ask the SAME grid you write to, or the ghost and the placement will disagree about the same cell.

**Files.** `objects/obj_tower/{Create_0,Draw_0,Step_1,Alarm_0}.gml`, `objects/obj_tower_edit/{Create_0,Draw_0}.gml`, `objects/_levelControl/Step_0.gml`, `scripts/scr_draw_self_scaled` (new), `scripts/scr_drawLight`, `scripts/scr_drawGlowOutline`, `scripts/draw_self_part`, `sprites/spr_tower_click_region`, `objects/obj_tower/obj_tower.yy` (`spriteMaskId`).

**See also.** [LL-012](#ll-012)

---

<a name="ll-034"></a>
## LL-034 — A guard that asks a TYPE question about an asset refuses the asset

**Look for.** Every stage is **silent** - no region theme, ever - while the title and world-map themes play; the log blames the track: `META  [MUSIC] region 1 "Wilted Sprouts" has no track yet - playing nothing`. A dual-grid renderer can similarly report `atlas_exists=1 atlas_is_real=0` and skip every tile.

**Cause.** **A guard asked a TYPE question about an asset**: `is_real(sound)` is **false for an asset reference** (it is not a real number, whatever the runtime calls the type) - so the guard refused a track that was there, and its message blamed the track. The menu path skips that guard, which is why only levels were silent.

**Rule.**

* if(is_undefined(_sound) || _sound == -1){ ...logs which of the two fired... return -1; }
* `music_data()` already documents `sound = -1` as *"not generated yet"* (LL-021: one source of truth) and `undefined` as *"no row / no sound"*. Both are tested by value, and the refusal now says WHICH one fired instead of one sentence covering two different bugs.
* META [MUSIC] region 1 "Wilted Sprouts" mus_world1 (ref) loop 0 -> 163.53s (whole track)
* **Never ask a TYPE question about an asset.** Ask the sentinel your own table documents, or use the asset's own API — and note that `audio_exists()` **throws** on an index the runtime has never seen (*"this function will cause an error as it is searching for non-existent asset indices"*), so it cannot be a guard either (LL-002).
* **A guard that refuses a good value is worse than no guard** — it converts a working feature into silence, and its message blames the data. Test a guard against a REAL row first, not only against the broken case it was written for.
* **Grep for the shape, not the function**: a numeric type test (`is_real`, `is_int64`) applied to something that is not a number. The project's convention for an asset is `is_undefined(x) || !sprite_exists(x)` — see `scr_scale_sprite`.

**Files.** `scripts/scr_music_start_level/scr_music_start_level.gml`, `scripts/music_data/music_data.gml`, `scripts/scr_playMusic/scr_playMusic.gml`, `objects/obj_title/Step_0.gml`, `objects/Menu/Step_0.gml`, `scripts/scr_dual_grid/scr_dual_grid.gml`.

**See also.** [LL-021](#ll-021), [LL-002](#ll-002)

---

<a name="ll-035"></a>
## LL-035 — An unpassed declared parameter is `undefined`, and `argument_count` is not the call count

**Look for.** A monster **in water throws every frame**: `undefined value at gml_Script_draw_self_part (line 33) - _x = x - sprite_get_xoffset(sprite_index)*_sx`, from `obj_mon/Draw_0`'s five-argument call.

**Cause.** The **optional argument** was detected with `argument_count`, but the function **declares seven** parameters and the call passes five, so the list is padded with `undefined` and the wrong branch was taken.

**Rule.**

* var _sx = is_undefined(argument5) ? image_xscale : argument5, _sy = is_undefined(argument6) ? image_yscale : argument6,
* This does not depend on how `argument_count` is computed, and it is the project's established "not there" test (`GameLevelData`, `region_data`, `scr_meta_seeds`). `scr_drawGlowOutline(argument0)` carried the same brittle shape (`argument_count > 0 && argument0 > 0`) and was changed with it — it worked only because its one caller always passes an argument.
* **Two safe shapes for an optional argument:** declare it and test `is_undefined(value)`; or declare NOTHING and read `argument[i]` with `i < argument_count`. The unsafe third shape is *declare parameters AND test `argument_count` for the short call*.
* **Never size a variadic list from `argument_count` in a function that declares parameters.** If the declared list can ever be longer than the call, `argument_count` reports the declared arity. Pad-proof code declares nothing.
* **A declared-but-unpassed parameter is a variable holding `undefined`.** It can be read, and `is_undefined()` is the right question — but if it feeds a plain assignment, the `undefined` travels silently until something does arithmetic with it, which may be far away (here: the next line; in general: another event, another frame).
* **When a caller-count bug is suspected, print the count and the type** (`argument_count`, `typeof(...)`) rather than guessing. The diagnosis here took the error text plus two greps, not a debugger.

**Files.** `scripts/draw_self_part/draw_self_part.gml`, `scripts/scr_drawGlowOutline/scr_drawGlowOutline.gml`, `objects/obj_mon/Draw_0.gml`, `objects/obj_tower/Draw_0.gml`.

---

<a name="ll-036"></a>
## LL-036 — A wave's creature comes from one of TWO banks, and the boss rule is a cadence, not the last wave

**Look for.** A difficulty projection disagrees with the play - "the numbers look fine but I keep leaking".

**Cause.** The wave was a **BOSS wave** (`boss_every` is a cadence, not the last wave), and its creature comes from **`spawn_boss`** - ~10x the HP of the pool the projection read, with no error and no log line.

**Rule.**

* function scr_curve_is_boss_wave(_w, _waves, _boss_every, _has_named_boss) { if(_w > 1 && _boss_every > 0 && _w % _boss_every == 0) return true; if(_has_named_boss && _w >= _waves) return true; return false; }
* `scr_curve_wave_demand()` then reads `MON.life` / `MON.speed` from `spawn_boss` (and its own count of 1) when that returns true, and the read-out prints a `BOSS` row for the **first mid-stage** boss wave as well as the last wave. It is drawn on screen (`scr_curve_draw()`), because the Output window is not visible while playing and a diagnostic nobody can read is not a diagnostic.
* **A wave's creature is `spawn_boss` OR `spawn_mon` - never just the one you have in hand.** Code that reasons about "a wave" while reading only `spawn_mon` is wrong on **every boss wave**, which is 1 in 10 of a region-1 stage.
* **`boss_every` is a CADENCE and the named boss is the FINALE.** Both are true at once, either can be absent, and `wave > 1` matters (wave 1 is never a boss). Do not re-implement the rule - `scr_level_pick_spawn` owns it.
* **A projection that agrees with the design is not evidence.** Ask what a number would look like if it were reading the *wrong input*: here, too small by ~10x and completely silent. Two banks, one of them chosen by arithmetic, is exactly the shape a "looks fine" bug takes.
* **Money is not the only constraint on defence.** The same function originally assumed every dollar ever earned becomes a tower that reaches the path, so it could report `ok` while a full wrap leaked. A fixed route can only be covered by the cells within range of it - `scr_curve_slots()` counts them - and the supply term has to be `min(money / price, slots)`.

**Files.** `scripts/scr_curve/scr_curve.gml` (`scr_curve_is_boss_wave`, `scr_curve_wave_demand`, `scr_curve_slots`, `scr_curve_draw`), `objects/_levelControl/Draw_64.gml`, `scripts/region_data/region_data.gml`, `scripts/scr_level_pick_spawn/scr_level_pick_spawn.gml`, `scripts/scr_level_spawn/scr_level_spawn.gml`.

**See also.** [LL-022](#ll-022)

---

<a name="ll-037"></a>
## LL-037 — A test that selects its fixture from the live data fails when the data is finally clean

**Look for.** The toolkit suite goes **red on an edit that changed no code** - `FAILED (errors=1)`, and the traceback is a `StopIteration` inside a *test*.

**Cause.** The test built its fixture by **searching the repo's own `progress.json`** for a card that already had the property under test, so it could only pass while the board happened to have such a card.

**Rule.**

* def mutate(d): task = d["tasks"][0] task["status"] = "done" task["done"] = "2026-01-01" task["awaiting"] = "rayu" task["needs"] = "a line, so only the rule under test fails"
* `d["tasks"][0]` is deterministic in canonical order (tasks are sorted by id), so the test now depends on `validate()` and nothing else. The **BACKLOG** test (`test_rejects_a_backlog_card_that_is_awaiting_a_person`) had the identical latent hole and was fixed with it - it was only passing because the repo happened to still have backlog cards, and a finished project has none.
* **A test may READ the live data; it must not require the live data to have a particular shape.** Mutate a known key (`d["tasks"][0]`) or append a synthetic card - never `next(... for x in <live> if <property>)`.
* **`next()` with no default is a hidden assertion.** `next(it)` on an empty iterator is a `StopIteration` that unittest reports as an **ERROR in the test**, not a failure of the rule. If a search is genuinely needed, pass a default and assert on it, so the message names the missing precondition.
* **A red gate after a "nothing changed" edit is data, not noise.** Read the traceback before assuming your change caused it - here the data *was* the point.
* **Some tests are supposed to read the repo** (`test_repo_tracker_is_valid`, `test_generated_views_are_in_sync`). That is correct for a rule about the repo, and a trap for a rule about the schema - keep the two apart.

**Files.** `python_tools/tests/test_gm.py`.

---

<a name="ll-038"></a>
## LL-038 — The projection said `ok` and the play leaked, because three assumptions were doing the work of facts

**Look for.** A projection says **`ok` while the play leaks** - and a second tool built to check it agrees, because it was written from the same formula.

**Cause.** The supply model treated three *assumptions* as facts: that the purse can afford the best-value tower, that `targets` is always full, and that a tower projects its dps down the whole route.

**Rule.**

* Supply is now built from the same greedy the sim spends with — score every `(cell, tower)` by `nominal dps x coverage / price` and buy while the purse lasts (`gm.balance.policy`), where `coverage = covered route px / route px` (`gm.balance.geometry.covered_length`) and `nominal dps` is the **single-target** figure.
* **A projection must be able to disagree with the play.** Build it from the mechanics, not from the last explanation of them, or it will certify whatever is already believed.
* **When you write a checker for a model, re-derive it - never port it.** The first version of the tester was a faithful port, which made it useless.
* **Every multiplier in a "dps" has a precondition. Write it down.** `x targets` means "and enough monsters in range"; "coverage" means "and for the whole traversal". A number with an unstated precondition will be read as a fact.
* **Validate a balance model against a KNOWN bad outcome.** The regression test is "the old ceiling must break the stage" — a model that cannot reproduce a leak the player actually had is not evidence about anything.
* **A verified non-trap, so nobody "fixes" it later:** GML's `round()` is **banker's rounding** (half to even), exactly like Python's built-in. The manual says so, and `python_tools/tests/test_balance.py` asserts it. A hand-written "round half up" would put every rung price and kill payout out by one.

**Files.** `python_tools/gm/balance/` (`policy.py`, `model.py`, `geometry.py`, `terrain.py`), `scripts/scr_curve/scr_curve.gml`.

---

<a name="ll-039"></a>
## LL-039 — A list you only ever write to at its own last index can never grow

**Look for.** A tower's **`targets` stat does nothing** - it hits one monster however high the number, and no error ever appears.

**Cause.** The collection loop read `array_last_index(_targets)` and then wrote at **that same index**, so the last index could never change. A list you only ever write to at its own last index does not grow.

**Rule.**

* The sentinel is not decoration. `scr_tower_shoot` does `if(!is_array(target)) ... scr_changeState(scr_tower_return); exit;` — it decides "nothing to shoot, go idle" by testing that the return is *not* an array. Returning `[]` for "nothing in range" would be a **valid** list: the tower would never go idle, and would swing at the air forever with `did_damage` already set.
* **Read and write indices are different jobs.** `array_last_index()` answers "where does it end"; an append needs "where does the next one go" — `array_length()`. If a loop reads an index and writes to it, suspect it.
* **A signature check cannot catch this.** `gm gml-functions` reported `find_all_range(argument0, ...)` quite happily; the bug is inside. A brace/paren **balance** check caught the orphan `}` my own fix left behind — run both, and check balance after any structural edit.
* **A stat that nothing reads is invisible; a stat that is read but ignored is worse.** `targets` was plumbed all the way into the shop's arithmetic, which is what made it look real.
* **When a number in the UI has a multiplier, verify the multiplier can be non-1.** Pina's "2000 dps" was checked against a doc table, not against ten monsters on screen.
* **Prove a load-bearing claim, then *see* it.** A bounded dev-mode probe (`cap_probe_left`) printing the cap beside the count turns this from an argument into one line in the Output window.

**Files.** `scripts/find_all_range/find_all_range.gml`, `scripts/scr_tower_shoot/scr_tower_shoot.gml`, `objects/obj_tower/Create_0.gml`.

**See also.** [LL-038](#ll-038), [LL-025](#ll-025)

---

<a name="ll-040"></a>
## LL-040 — The fire period was charged twice per shot: the idle wait *and* the attack

**Look for.** Every tower deals about **a third** of the dps on its card, and the shortfall is **uneven** across the roster - so the paper ranking does not match the play ranking. No error, no crash, and the balance panel still says `ok`.

**Cause.** The **fire period was charged twice per shot**: a full `room_speed/fire_rate` wait in `scr_tower_normal` *and* a full `room_speed/fire_rate` attack in `scr_tower_shoot`, so the cycle was `2P + off + 15` and not `P`.

**Rule.**

* The cycle becomes `P + off + 15`. `>` and not `==`, for [LL-029](#ll-029)'s reason (never test equality against a quantity derived from the FPS setting). It also takes the last obsolete `room_speed` read out of the firing loop ([LL-007](#ll-007)).
* **A period is spent in ONE place.** If two states each wait for the fire rate, one of them is wrong. Count the states between two identical events.
* **A `+ time_offset` on a period is a smell worth reading twice.** Offsets are for de-synchronising; if the base term is the *whole* period, ask which other state is also spending it.
* **Verify a cadence with a stopwatch, not a formula.** The probe in `scr_tower_shoot` prints the **measured** step gap between swings (`TOWER shot interval …`), so the fix is *seen* and not assumed — the same move as `cap_probe_left` in [LL-039](#ll-039).
* **A fix that is uneven is a roster change.** Check the *ratio* between the entries, not just the total, before pricing anything.
* **When the intent is written in a comment, the comment is the spec.** *"The attack's length IS the fire rate"* is what makes the second wait a bug rather than a design choice — and it also names the residual below.

**Files.** `scripts/scr_tower_normal/scr_tower_normal.gml`, `scripts/scr_tower_shoot/scr_tower_shoot.gml`, `objects/obj_tower/Create_0.gml`, `objects/obj_tower/Step_0.gml`.

**See also.** [LL-038](#ll-038), [LL-029](#ll-029), [LL-007](#ll-007), [LL-039](#ll-039)

---

<a name="ll-041"></a>
## LL-041 — Two tests indented inside the `__main__` block had never run

**Look for.** A test suite stays **green while tests quietly stop existing** - the only symptom is a count that moves by less than it should.

**Cause.** Two `GeometryTests` methods were indented four spaces inside the **`if __name__ == "__main__":` block**, so they were only defined when the file was *run* - and the discoverer **imports** it.

**Rule.**

* The suite went 75 → 87 on the same change (10 new fire-cycle/report tests, plus these 2 that had been missing).
* **Check the COUNT moved, not just that the run is green.** After adding *n* tests the total must rise by *n*. A suite that cannot notice a missing test has a hole in it - this is [LL-025](#ll-025)'s shape, a failure that looks like a pass.
* **A `def` after a blank line is not automatically top level.** Indentation is semantic; when appending to an existing Python file, look at what block you are already inside before you write.
* **A dead test is worse than a missing one**, because the coverage *looks* present. The same is true of a probe that never prints and a log line that never fires - so ask **"has this ever actually run?"** before you rely on it. That question is the reason `cap_probe_left` and the fire-cycle probe exist.
* **Fix it where it belongs, not where it is.** De-indenting the orphans in place would have left them after `unittest.main()`; moving them into the class they were written for is the fix, and the class then asserts the shared fixture.

**Files.** `python_tools/tests/test_balance.py`.

**See also.** [LL-025](#ll-025)

---

<a name="ll-042"></a>
## LL-042 — Hard pays exactly what Normal pays, and Brutal pays double

**Look for.** **Brutal is easier than Hard.** Brutal holds with 0 leaks where Hard leaks 19, and the panel says the opposite on every wave.

**Cause.** The difficulty money column is applied to a kill that pays **1** and *then* rounded: `round(1 x 1.25)` is still 1, so Hard's column does nothing, while `round(1 x 1.5)` is 2 and doubles Brutal's.

**Rule.**

* A **fractional carry** at the payout site - chosen over "raise the base payout" (which rescales every number in economy.md by 4) and over "move the rounding" (which makes the purse a float, so the HUD prints $12.5 and the shop's affordability test changes meaning).
* Money stays an integer - the carry is the only fractional thing, and it lives on `_levelControl` - so four kills at x1.25 pay **1, 1, 1, 2**: exactly +25% over the four, where rounding paid 1, 1, 1, 1.
* Landed with it (the same change, 2026-10-13): the kill-money **ramp** (`1 + 0.06 * (wave - 1)`, so income grows with the wave instead of only with the count) and the CLOSED FORM and the SIM taught to model both, because a tester that keeps its own opinion about the payout is LL-038 again.
* **A multiplier applied AFTER a round to an integer is a step, and the step here is 100%.** Scale before you round, or accumulate fractionally; never tune a percentage that a `round` can swallow. (`+0.01 * wave` in the speed ramp is the other side of the same coin - it works because the speed it feeds is a float.)
* **Test a difficulty column against INCOME, not just hp.** The panel's promise is about hp; what the player experiences is hp per dollar.
* **A ratio cannot see this.** The closed form was right about every wave and wrong about the stage, because it never let the money arrive late. It took a time-step to find - which is the entire argument for `gm balance sim`.

**Files.** `scripts/difficulty_data/difficulty_data.gml` (`kill_money_slope`, `kill_money_ramp`, `scr_kill_money`), `scripts/scr_zomb_death/scr_zomb_death.gml`, `objects/_levelControl/Create_0.gml` (`money_carry`), `python_tools/gm/balance/{model,sim,tables}.py`, `python_tools/gm/cli.py`.

**See also.** [LL-038](#ll-038)

---

<a name="ll-043"></a>
## LL-043 — A waterline expressed as a fraction of the sprite CANVAS means a different depth for every sprite

**Look for.** Plants in water wear a **halo of themselves**, meet the surface at a different height per tower, and a left-facing one is **upside down and ~220px low**.

**Cause.** The submerged copy was drawn at `image_xscale` (so 1.43x too big) and the waterline was a **fraction of the sprite CANVAS** - a different world depth for every sprite - while the reflection script had been ported disabled and wrong.

**Rule.**

* Stop expressing the waterline as a fraction. Derive it from the ORIGIN - the one property every sprite in this project shares, and the thing the anchor actually stands on - and express the depth in **screen pixels**, because how deep water looks is a property of the water, not of the creature standing in it (a boss is drawn twice as big and must not sink twice as deep).
* All four sites call it, so they agree **by construction** rather than by four people reading the same comment: `obj_tower/Draw_0` and `obj_mon/Draw_0` crop with it, `obj_water/Draw_0` draws the submerged tower through `scr_draw_self_scaled(draw_scale)` instead of `draw_self()`, and `scr_drawReflections` mirrors about the same seam.
* `sprite_get_yoffset()` / `sprite_get_height()` are the **unscaled** reads, which is what is wanted here ([LL-033](#ll-033) again: `sprite_yoffset` carries `image_yscale`).
* The measured deltas against the old behaviour: a monster's seam moves 7.5px → 8px (unchanged to the eye), a plant's 3.1px → 8px. The plants are the ones that read wrong next to each other, and `water_sink()` is the one knob.
* **A crop expressed as a fraction of a sprite is valid for exactly one sprite.** Waterlines, ground contacts and baselines belong in the ORIGIN, or in world/screen pixels. *"0.8 of the height"* is not a design decision, it is a measurement of one drawing.
* **When a sprite's size or origin changes, grep the READERS.** The size alone (`draw_scale`) has readers in `scr_draw_self_scaled`, `scr_drawLight`, `scr_drawGlowOutline`, `draw_self_part`, `obj_water/Draw_0` and `scr_drawReflections` - and the water ones live in a folder nobody thinks of as "towers". LL-033 wrote this rule down and then this file found four more consumers it had missed.

**Files.** `scripts/draw_water_shader/draw_water_shader.gml` (`water_sink`, `water_line_keep`, `water_line_report`), `objects/obj_water/Draw_0.gml`, `objects/obj_tower/Draw_0.gml`, `objects/obj_mon/Draw_0.gml`, `objects/obj_tower/Create_0.gml`, `objects/obj_mon/Create_0.gml`, `scripts/scr_drawReflections/scr_drawReflections.gml`.

**See also.** [LL-033](#ll-033), [LL-012](#ll-012)

---

<a name="ll-044"></a>
## LL-044 — One stored counter served two questions, and the reader that was right hid the one that was wrong

**Look for.** The HUD's **Wave number reads one high** (wave 1 shows as 2), the level log agrees with it, and the speed ramp computes for the *next* wave - yet the pre-wave banner is right, so nothing looks broken.

**Cause.** `STATINV.waves` was seeded at **1** while `wave_count` started at **0**, so one item carried **two meanings**: the wave being fought (HUD, log, ramp) and the wave about to spawn (banner). The banner was correct **by accident**, which is why it survived.

**Rule.**

* `python_tools/gm/balance/sim.py` — `Sim.stat_waves` was `return wave + 1`, *restating the bug in Python*. It now **reads the seed out of the GML** (`tables.py` reads `set_item_value(waves,N)` into `constants.wave_seed`) and returns `seed + wave`, so the sim follows the game instead of holding its own opinion about it.
* **A counter that answers two questions is two counters.** If a stored number is right for one reader and wrong for another, the right one is a coincidence, not a check. Name the meaning in the item's own comment, and make the odd reader do the arithmetic (`+ 1`) where the meaning actually differs.
* **If a tool models a bug on purpose, read the bug's parameter out of the GML.** A literal `+ 1` in Python models *the game as it was when the literal was written* — the sim would have kept modelling the old game after the fix. This is [LL-038](#ll-038)'s rule, applied to a single scalar: `constants.wave_seed`.
* **Spot it early.** `gm balance check` prints the seed, and `test_the_wave_counter_is_the_wave_being_fought` asserts it is 0 *with the reason in the failure message*, so a revert fails loudly instead of the two tools quietly diverging again.
* **A diagnostic that agrees with you is not a second opinion.** The log line and the HUD were the same wrong number; only the banner differed, and it was wrong to trust.

**Files.** `objects/_levelControl/Create_0.gml`, `scripts/scr_level_showPath/scr_level_showPath.gml`, `scripts/scr_level_state/scr_level_state.gml`, `scripts/scr_zomb_pathSpeed/scr_zomb_pathSpeed.gml`, `python_tools/gm/balance/sim.py`, `python_tools/gm/balance/tables.py`, `python_tools/tests/test_balance.py`.

**See also.** [LL-038](#ll-038)

---

<a name="ll-045"></a>
## LL-045 — Ported dead code that had never run, and the three traps waiting inside it

**Look for.** Nothing at all - the feature simply does nothing, and the code for it looks complete. An outline shader that had never drawn a pixel in its life.

**Cause.** **Ported dead code**: `shd_outline`, `scr_getOutlineShd()` and `scr_drawSelfOutlined()` all existed and nothing ever called the two scripts - and three faults were waiting inside, the worst being that `draw_self()` draws at `image_xscale` (±1 facing on a tower, [LL-033](#ll-033)) and the shader took its colour from `image_blend`, which is the sprite's TINT here.

**Rule.**

* `scr_getOutlineShd()` became the setup step (`shader_is_compiled()` once, in Create), so a shader that fails to compile degrades to "no ring" instead of a half-drawn tower.
* **Grep a function's name outside its own file before trusting it.** Ported code that has never run is not code that works; it is a hypothesis.
* **Ask a draw helper what it draws at.** `draw_self()` is `image_xscale`; `scr_draw_self_scaled()` is `draw_scale` ([LL-033](#ll-033)).
* **A shader's colour is an input.** Riding it on `image_blend` collides with every other user of `image_blend`, and this shader's body term drops it.
* **`shader_set`/`shader_reset` are a pair with no `return` between them** - and `shader_reset()` with nothing bound is a no-op, so call it unconditionally.
* **`shader_is_compiled()` at setup**, so a compile error is a missing feature rather than a broken frame.

**Files.** `shaders/shd_outline/shd_outline.fsh`, `scripts/scr_getOutlineShd/scr_getOutlineShd.gml`, `scripts/scr_drawSelfOutlined/scr_drawSelfOutlined.gml`, `scripts/tower_levels/tower_levels.gml`, `objects/obj_tower/Draw_0.gml`, `objects/obj_tower/Create_0.gml`, `objects/_levelControl/Step_0.gml`.

**See also.** [LL-033](#ll-033), [LL-012](#ll-012)

---

<a name="ll-046"></a>
## LL-046 — A blend mode belongs to the PASS, so an additive ring cannot carry the body with it

**Look for.** A ringed tower goes **see-through and blown out** the moment the ring is blended additively; or the ring's opacity changes nothing at all.

**Cause.** **One shader pass draws whatever it is told to draw**, and a blend mode is a property of the PASS - so an additive ring pass cannot also carry the body; and `draw_set_alpha()` cannot reach a shader that writes `gl_FragColor` (the alpha it did write was a COUNT, which additive blending uses as a multiplier).

**Rule.**

* The opacity rides on the colour's fourth component (`shader_set_uniform_color(uniOutlineCol_, argument0, _alpha)`), the blend mode is set **last** in `scr_outline_begin` - after every early return, so no return can leak it - and `scr_outline_end()` puts it back beside `shader_reset()`.
* **A blend mode belongs to the pass, not to the thing you meant to blend.** If a pass draws two things and only one should be blended, **split the pass**.
* **`draw_set_alpha()` does nothing to a shader that writes `gl_FragColor`.** Pass opacity as a uniform. (And use `shader_set_uniform_color`, which is this project's own wrapper for a `vec4` - it is not a GameMaker built-in.)
* **Never put a COUNT in `gl_FragColor.a`.** In a kernel loop `alpha` is a count; under additive blending it is a multiplier. Fold it with `min(x, 1.0)` first.
* **Under additive blending "invisible" means alpha 0, not "the background colour".** Anything with a non-zero alpha in a mostly-empty quad adds light - hence the `(1.0 - originAlpha)` term rather than relying on the colour to cancel out.
* **`bm_add` is `(bm_src_alpha, bm_one)`** - the source is weighted by its own alpha, which is exactly what makes "25% opacity" add a quarter of the colour rather than all of it. (`bm_max` is `(bm_src_alpha, bm_inv_src_colour)`, a different animal; the full factor table is on the `gpu_set_blendmode` page.)

**Files.** `shaders/shd_outline/shd_outline.fsh`, `scripts/scr_drawSelfOutlined/scr_drawSelfOutlined.gml`, `scripts/tower_levels/tower_levels.gml`, `objects/obj_tower/Draw_0.gml`.

**See also.** [LL-045](#ll-045), [LL-035](#ll-035)

---

<a name="ll-047"></a>
## LL-047 — `sprite_get_bbox_top()` is measured from the sprite CANVAS, not from the origin

**Look for.** A label placed "above the sprite's head" lands in the middle of it (or below its feet), with the value looking plausible.

**Cause.** **`sprite_get_bbox_top()` is measured from the sprite CANVAS, not from the origin** - while the `bbox_top` instance variable is room-relative. The offset from the origin is the DIFFERENCE, and it is negative for this project's feet-origin sprites.

**Rule.**

* **The `sprite_get_bbox_*()` functions are canvas-relative; the `bbox_*` instance variables are room-relative.** Convert with `sprite_get_xoffset()` / `sprite_get_yoffset()` before using either as an offset from the origin.
* **Check the numbers against a real sprite before trusting a position.** The four rows above came from one script over the `.yy` files, and they are what proved the first version wrong. A guessed offset would have looked "close enough" and been wrong on every sprite that is not the one you tested.
* **`sprite_exists()` first**: `sprite_get_bbox_top(-1)` is fatal ([LL-012](#ll-012)).
* **A newline ends a statement as soon as the expression is COMPLETE**, so break a long expression inside an unclosed bracket (or after a binary operator), never after a complete `(...)` group - GML would read the next line as a new statement.

**Files.** `objects/_levelControl/Draw_73.gml`.

**See also.** [LL-012](#ll-012)

---

<a name="ll-048"></a>
## LL-048 — Additive coverage double-counts, and a planner told only what it must not reuse can only duplicate

**Look for.** A balance model that says a stage **holds** while every tower stands on the same fifth of the map and the **last quarter of the route is never shot**; and a run of 11 towers that **never bought a single upgrade**.

**Cause.** The greedy ranked on `dps x coverage`, and coverage was **additive** - two towers over one stretch both score it, so the objective was the SUM of per-tower coverage instead of the **UNION** of route actually covered. And it was told which CELLS were taken, never which TOWERS were standing, so a rung was invisible to it every wave.

**Rule.**

* Two changes, both in `policy.py`, both opt-in so published numbers stay put.
* | objective | towers | spent | widest target list | wasted swings | | --- | --- | --- | --- | --- | | additive | 16 | $143 | 6 | 33% | | union | 11 | $143 | **3** | **25%** |
* Fewer towers, less waste, and the route covered - so the *finding* that a 10-target cap is unreachable got **stronger** (6 -> 3), which is why that test's threshold moved.
* The sim then gained `--spend instant`, which re-runs the same greedy while a wave is **live** instead of only at the wave boundary: **$2 left at the end instead of $17**, and 9 upgraded towers instead of 11 cheap ones.
* **An objective that sums per-agent benefit over-counts whenever two agents can serve the same event.** Ask "what does the SECOND one add?" before trusting a sum of shares.
* **A planner that re-plans from scratch must be told what already exists**, or it can only ever duplicate. "Which cells are taken" is not "what is standing".

**Files.** `python_tools/gm/balance/policy.py`, `python_tools/gm/balance/sim.py`, `python_tools/gm/balance/report.py`, `python_tools/gm/cli.py`, `python_tools/tests/test_balance.py`.

---

<a name="ll-049"></a>
## LL-049 — A persistent instance's Create was the only thing that built the level

**Look for.** The **second level never loads**: the stage room comes up, walls and spawns are there, but the **ground never appears and no waves start** - and nothing errors.

**Cause.** The whole level bootstrap hung off `Control/Create_0` (a **persistent** instance, first in the room order) creating `_mainControl`. A persistent instance keeps Room Start/Room End but **not Create**, so the second entry built nothing - while `_mainControl`, `_levelControl` and `_viewControl` are non-persistent and had already died on Room End.

**Rule.**

* The boot moved to the one hook that is guaranteed on every entry.
* **`Control` is non-persistent.** It is placed only in `rm_test`, so persistence bought nothing and cost the systems: Room End destroyed them and Create never rebuilt them. (`Input` is persistent but guarded by `instance_number(Input) == 0`, so re-creating `Control` cannot duplicate it.)
* **`scr_main_startup` builds the grid when it is MISSING**, not merely when `state_time == 0`, logs `terrain grid WxH max N seed S`, and logs `startup done rows=N` when the reveal ends. `rows=0` is now the one-line statement of "the terrain did not build".
* And one latent defect in the same path: `draw_fadeout` did
* `room_goto` to the room you are **already in** does nothing, so a retry or a replay was a silent no-op - the fade ran, the screen went black and came back, and the stage carried on. `fadeout()` now takes an optional sixth argument and the branch is `room_restart()`, which re-runs the room's creation code and therefore the boot.
* **Never let a persistent instance's Create be the only thing that builds a room.** Create is a one-off; Room Creation Code and Room Start are the hooks that fire every time.

**Files.** `rooms/rm_test/RoomCreationCode.gml`, `scripts/scr_level_boot/scr_level_boot.gml`, `objects/Control/Create_0.gml`, `objects/Control/Control.yy`, `scripts/scr_main_startup/scr_main_startup.gml`, `scripts/fadeout/fadeout.gml`, `scripts/draw_fadeout/draw_fadeout.gml`, `scripts/ini_fadeout/ini_fadeout.gml`.

**See also.** [LL-020](#ll-020)

---

<a name="ll-050"></a>
## LL-050 — The save merge read the wrong struct, and the log printed only what survived

**Look for.** The game **resets every time**: stage progress, bought towers and clover nodes are gone after a relaunch - but seeds, clovers and the loadout are still there.

**Cause.** **The merge looped over the DEFAULT's keys**, so every nested map (`{}` in the default) came back EMPTY with a `version` stamp inside it; only the non-structs survived - and the load log printed exactly those non-structs.

**Rule.**

* the merge iterates the LOADED struct's keys;
* an EMPTY struct in the default is an OPEN MAP (stages, clears, towers, badges, the node tables) and takes every key the file has; a POPULATED struct is a FIXED RECORD (`last_stage`) and merges key by key;
* scalars and arrays keep their default's TYPE, so a hand-edited save cannot make a later read throw (LL-002 applied to data);
* `version` is skipped during the merge and stamped once, on the top level, by the caller;
* the load log now prints `stages= clears= towers= nodes= badges=` - the maps, not just the scalars;
* `python_tools/gm/save/` inspects a real `garden_meta.dat` and exits 1 when it finds a stray `version` inside a map. It is a DETECTOR, not a second implementation of the merge.

**Files.** `scripts/scr_meta_schema/scr_meta_schema.gml`, `scripts/scr_load_meta/scr_load_meta.gml`, `python_tools/gm/save/__init__.py`, `python_tools/gm/cli.py`, `python_tools/tests/test_save.py`.

**See also.** [LL-002](#ll-002)

---

<a name="ll-051"></a>
## LL-051 — A slider is a modal drag, and a Draw event must not own input

**Look for.** A volume slider **does not apply until you leave Options**, and **0% / 100% take a second pass** because the mouse leaves the track.

**Cause.** The slider read the mouse in a DRAW event, only while the pointer was inside a 32px band, `lerp`ed 25% per frame towards it, and the gain was only re-applied on RETURN.

**Rule.**

* A new script, `scr_menu_slider`, owns the geometry (`scr_slider_rect`) and the drag (`scr_sliders_step`, called from the Options case of `Menu/Step_0`); `show_slider` became draw-only. A press inside a track GRABS it, and from then on the value follows the pointer **wherever it goes**, clamped to 0..1 - so the far end of the track is reachable in one stroke. Release writes `gameoptions.dat`.
* Splitting `scr_resetSoundVolume()` mattered too: it also called `audio_channel_num((clutterDensity+0.1)*50)`, which would have reallocated the audio channels **every frame of a drag**. The channel count moved to `scr_applyClutter()`, which runs when the clutter slider moves and at boot.
* **A drag is modal: grab on press, follow until release, clamp at the edges.** And **the draw event draws** - geometry and input belong in Step, or the thing you test and the thing you see drift apart.

**Files.** `scripts/scr_menu_slider` (new), `scripts/show_slider`, `objects/Menu/{Create_0,Step_0,Draw_64}.gml`, `scripts/scr_resetSoundVolume`.

---

<a name="ll-052"></a>
## LL-052 — A mirrored shadow that lands a whole tower to the right

**Look for.** A tower's **shadow flips but does not follow** the tower when it turns round - it lands most of a tower-width to the side; after the origin was fixed it was still ~96px to the **right**.

**Cause.** `scr_drawLight` built the silhouette box from **signed** values: `sprite_xoffset` AND `sprite_width` both carry the image_xscale sign, so the flip branch laid the box out on the wrong side.

**Rule.**

* _xo = abs(sprite_xoffset)*_art; // origin, unsigned _l = _flip ? _bx + _xo - _w : _bx - _xo; _r = _l + _w;
* with the corner swap kept for the texture. Monsters are fixed by the same line: their `image_xscale` IS the size, so `abs(sprite_xoffset)` is already scaled and `sprite_width` already includes it.
* **A reader that multiplies by `sprite_xoffset` / `sprite_yoffset` is multiplying by the facing sign.** Want the size? `abs()` it. This is the fourth way a flip dies, after LL-012's three.

**Files.** `scripts/scr_drawLight/scr_drawLight.gml`.

**See also.** [LL-012](#ll-012), [LL-043](#ll-043)

---

<a name="ll-053"></a>
## LL-053 — The stage could not be lost, only quietly handed to the arcade screen

**Look for.** Losing every life **never reaches the new level flow** - the old arcade high-score screen takes over and nothing is saved or withheld.

**Cause.** `LEVEL_STATE.FAILED` existed and was **never requested**; the legacy `scr_main_normal` still ran `scr_main_gameOver -> rm_score` underneath.

**Rule.**

* `scr_level_step()` checks `life <= 0` **before** the state switch and requests `LEVEL_STATE.FAILED` (returning for one frame, so a wave cannot also request CLEAR and pay the player for a stage they just lost). `scr_level_failed()` pays nothing and takes nothing (goal.md 27.3), writes the save, moves the run cursor and returns to the world map.
* **A terminal condition needs a state, not a side effect.** If a state can only be entered by an object that might not exist, the flow does not have that state - it has a gap that the oldest code in the project will fill.

**Files.** `scripts/scr_level_state/scr_level_state.gml`, `objects/_levelControl/Create_0.gml`, `scripts/scr_main_normal/scr_main_normal.gml`.

---

<a name="ll-054"></a>
## LL-054 — A slow-firing tower never fires, because the fire period WAS the swing

**Look for.** A **slow-firing tower never fires at all** - the Pina Collider stands through a whole stage; the attack timer looks frozen until something is in range.

**Cause.** The fire period was **also the animation length** (`frame_number = room_speed/fire_rate`) and the swing was **cancelled the moment the target left range** - so a 0.10/s tower needed a monster in range for 600 frames, longer than it takes to cross its range.

**Rule.**

* The rate is a COOLDOWN, the animation is art, and a started swing commits.
* `attack_timer` on `obj_tower` ticks in EVERY state, in `obj_tower/Step_0`, whether or not anything is in range - that is the "ready to fire" the tower was missing. `attack_cycle = tower_cycle_frames(rate, return_seconds) + time_offset`: the fire period PLUS the return PLUS the tower's own stagger, which is the cycle LL-040 and the balance closed form already assume, so no fast tower's delivered rate moves.
* `swing_frame = min(fire period, tower_swing_seconds()*fps)` - the attack sprite plays for ~0.35s (never longer than the period) and the damage lands near the end of THAT, so a slow tower strikes in a third of a second.
* `scr_tower_shoot` abandons a swing only when every cached target is DEAD, not when one walks out of range: the monster was in range when the swing began.
* `tower_levels.gml` owns `tower_fire_period`, `tower_cycle_frames` and `tower_swing_seconds`. `tables.py` reads them and `sim.py` mirrors the machine, so the game and the tester cannot drift (LL-038, LL-040, LL-042).
* **A rate is a timer, not an animation length.** If two quantities are ever assigned the same expression, ask which one is allowed to move independently.

**Files.** `scripts/scr_tower_normal`, `scripts/scr_tower_shoot`, `objects/obj_tower/{Create_0,Step_0}.gml`, `scripts/tower_levels`, `python_tools/gm/balance/{sim,tables}.py`, `python_tools/tests/test_balance.py`.

**See also.** [LL-040](#ll-040), [LL-038](#ll-038), [LL-042](#ll-042)

---

<a name="ll-055"></a>
## LL-055 — A three-second hold is not 180 frames, and 60% of the viewport is not 60% of the canvas

**Look for.** A 3-second **Level Complete** hold lasts one second in fast-forward; a banner sized as "60% of the viewport" comes out at 37% or spills off the edges.

**Cause.** A hold counted in **frames** against a `room_speed` that fast-forward sets to 180, and a banner sized from the sprite **canvas** instead of the art inside it.

**Rule.**

* `scr_level_clear` runs the sequence on `delta_time` (clamped per step, so a stall cannot skip a beat) - a real-time clock that is also pause-safe, because a pause stops the Step. One function per beat (`level_clear_*_seconds()`) so it can be retimed in one place.
* **Any duration the player perceives is seconds, not frames**, because this project ships a fast-forward that changes the step rate.
* **"N% of the viewport" has to say WHICH rectangle** - port, GUI, canvas or art - and the answer should be the one the player can see.
* **A fade is only as wide as its alpha reaches**: `draw_set_alpha` is overridden by `draw_sprite_*_ext`'s own alpha argument.

**Files.** `scripts/scr_level_state`, `objects/_levelControl/{Create_0,Step_0,Draw_64}.gml`, `objects/_mainControl/{Create_0,Step_0}.gml`, `scripts/{scr_drawSpdBtns,scr_view_zoom,scr_view_idle}`, `sprites/bck_level_complete_banner`.

---

<a name="ll-056"></a>
## LL-056 — A bar is a clamped ratio, and its denominator is data

**Look for.** A monster HP bar draws with a **negative width** - an orange fill to the LEFT of the black bar, usually on a boss that has just died.

**Cause.** `obj_mon/Draw_73` fed an **unclamped** `life/maxLife` to `lerp`, and `life` really does go negative: an overkill is normal, `scr_zomb_death` only runs in the path state, and the emerge reset heals it 60 steps later.

**Rule.**

* _max = data[MON.maxLife], _ratio = (_max > 0) ? clamp(data[MON.life] / _max, 0, 1) : 0, ... if(_xb - _xa >= 2){ draw_line_width(_xa+1, _y2+1, lerp(_xa+1, _xb-1, _ratio), _y2+1, 3); }
* plus a one-off `MON life<0 <name> life=x/max bar=%` line, so an overdraw is named instead of inferred.
* **A bar is `clamp(value/max, 0, 1)`.** Any other arithmetic can draw outside its own track, and the symptom looks like a drawing bug when it is a data one.
* **Guard the denominator** - `maxLife` is a table value, so it can be 0.
* **A Draw event must not be the first place an invariant is checked.** The monsters were allowed to be at `life <= 0`; the bar was the first reader to care.
* A zero-sized sprite (the emerge starts at `image_xscale = 0`) collapses the bbox, so skip the fill when the track has no width rather than drawing a 1-pixel dot at the origin.

**Files.** `objects/obj_mon/Draw_73.gml`.

---

<a name="ll-057"></a>
## LL-057 — A message box is a QUEUE: write the portrait to the message that will be drawn

**Look for.** The **Up Next popup shows the previous creature portrait** under the new creature name - read as "Tusk-A-Lot and Sub-Zero are swapped".

**Cause.** The portrait is stored per MESSAGE but drawn at `message_current`, and `show_message_box` **appends** to a live box, so a second preview painted message 0 - with message 0 portrait.

**Rule.**

* a preview starts a FRESH box - `if(instance_exists(obj_textbox)) instance_destroy(obj_textbox)` - because two popups at once is never what is wanted;
* the wrapper writes its portrait to **every** message the box holds, so the displayed message cannot be the one without it;
* `scr_makeMonster` defaults every slot the enum names (`debree = 0`, `portrait = -1`), so a row is complete before `scr_setupSpawning` fills it, and `-1` (none) is a value both readers guard on;
* `LEVEL boss bank: 0=Tusk-A-Lot walk=... portrait=...` is printed once at setup, and `LEVEL up next: ... portrait=...` on every preview - the pairing is now observable instead of argued about;
* `python_tools/tests/test_content.py` asserts the portrait column is a **bijection** (every creature has one, no two share one, every named sprite exists). A duplicated or missing portrait now fails the suite.
* **Store data against the thing that will read it.** A queue indexed by `message_end` and read by `message_current` will disagree the moment anything appends.

**Files.** `scripts/show_portrait_box`, `scripts/scr_wave_preview`, `scripts/scr_makeMonster`, `scripts/mon_enums`, `scripts/scr_setupSpawning`, `python_tools/tests/test_content.py`.

---

<a name="ll-058"></a>
## LL-058 — A passive popup must not read a queue it does not own

**Look for.** The **"Up Next" popup names a creature the wave does not send**, and the mismatch looks *random* - it started on the third level.

**Cause.** Three defects on the popup path: the portrait was per MESSAGE and drawn per `message_current`; `show_message_box` **appends**; and the preview box was destroyed and re-created in the same step. Plus a silent re-roll fallback in `scr_level_spawn`. Stage 1-3 is the first stage with **two** creatures in its pool, which is why a bug from wave 1 became visible there.

**Rule.**

* `obj_textbox.portrait` is **one sprite for the whole box**; `Draw_64` draws it with no index at all, so there is nothing left to disagree with. `-1` = none, and the old frame-of-`message_sprite` path still works for the cutscene.
* `show_portrait_box` **resets** the live box (one message at slot 0, typewriter clock at 0) instead of appending or replacing it.
* The decision is **one struct** - `next_pick { wave, is_boss, index, name, portrait }` - made by `scr_level_pick_store`, which is **idempotent per wave number**: asking again for a wave already decided returns the FIRST answer. Popup and wave are two readers of one answer.
* `scr_level_spawn` compares the promise with the delivery and logs `LEVEL WARNING ...` if the wave, the row, the bank or the controller count disagree. It also clamps a pick with no row instead of indexing a bank with -1 ([LL-002](#ll-002)).
* The popup names the **wave** (`Up Next... wave 12`), so a player reports two numbers instead of two pictures - and the numbers say which half is wrong.
* **One decision, one struct, and let it carry the wave it was made for.** An `is_boss, index` pair cannot prove itself: the same index means a different creature in the other bank, so any disagreement about `is_boss` silently swaps the monster.

**Files.** `objects/obj_textbox/{Create_0,Draw_64}.gml`, `scripts/{show_message_box,show_portrait_box,scr_wave_preview, scr_level_pick_spawn,scr_level_wait,scr_level_spawn,scr_level_start}`, `objects/_levelControl/Create_0.gml`, `python_tools/tests/test_content.py`.

**See also.** [LL-031](#ll-031), [LL-002](#ll-002)

---

<a name="ll-059"></a>
## LL-059 — Everything at one depth is not "sorted"

**Look for.** Zombies draw **over plants they stand behind**, and two crossing monsters swap order.

**Cause.** There was no sorting: monsters were a flat `-60` (in three places), plants `-60 - (y>>5)` (always in front) and the six gravestones one flat value from a fraction of the room. Three formulas cannot make one draw order.

**Rule.**

* One function, `scr_depth_y(y)` in `scripts/scr_setDepth` (which held a dead GM8 `depth = (room_height-y) >> 2` - note the direction: a larger y gave a LARGER depth, i.e. behind). `depth = -60 - y/32`, plus a 1e-5 tie-break from `id`, and a second entry point `scr_depth_band()` with no `id` for log lines.
* **"Sorted" needs one formula, not one value per class.** If two object types pick their own depth expression, the relationship between them is decided by arithmetic nobody wrote down.
* **An actor's depth is a VIEW of its position, so it is re-derived when the position changes.** Set it in the Step event that runs in every state, not in the state scripts - a monster in its emerge or death animation is on screen too.
* **Sort by the origin, and make sure the origin IS the feet.** `spr_grumble_walk` is 160 tall with `yorigin 150`, `spr_daisy_idle_192x` is 192 with `yorigin 158`, `spr_headstone_round` is 64 with `yorigin 53` - all three stand on their origin, which is why one formula works for all of them. A sprite with a centre origin needs half its height added, and that is a different formula.
* **A quantised depth ties.** The plants' `y>>5` put everything in the same 32px row at one depth; the float `y/32` is what lets a zombie stand BETWEEN two plants instead of sharing their plane.
* **Two instances at equal depth are drawn in creation order**, which for a queue of monsters is an order that changes as they jostle - a flicker. The tie-break must be smaller than the depth difference between two pixels of ground (1/32), or it reorders real positions instead of breaking ties.

**Files.** `scripts/scr_setDepth`, `objects/obj_mon/{Create_0,Step_0}.gml`, `scripts/{scr_zombie_emerge,scr_zombie_path,scr_level_spawn}`, `objects/obj_spawn/Create_0.gml`, `objects/obj_tower/Create_0.gml`, `objects/obj_tower_edit/Step_0.gml`, `scripts/scr_level_boot`.

---

<a name="ll-060"></a>
## LL-060 — A rule with three readers has to be one number

**Look for.** The **boss rule disagreed with itself** - play rolled one on a `boss_every` cadence, the curve projected wave 10, the tester encoded it again.

**Cause.** The rule lived in four readers as a copied *condition*, so changing it left every copy silently authoritative. Now one authored `[mid, end]` pair and one derived `boss_wave` (`waves div 2`) that play, the curve and the tester all read.

**Rule.**

* **A rule that gameplay and a tool both know is a number to share, not a condition to copy.** Put it where both can read it (a derived field on the level struct), and give the tool a test that fails when its mirror disagrees.
* **When a rule changes, the tests that encoded the OLD rule must change too** - three of them did (`test_boss_wave_rule`, the demand test, the payout test). A test that still asserts the old rule is not protecting you; it is lying.
* **A boss is authored, not rolled**, when the player is meant to learn it. The fallback for a stage that names none is still random, and it is LOGGED, so authored data can never be confused with an accident.

---

<a name="ll-061"></a>
## LL-061 — A percentage applied after rounding is not a percentage

**Look for.** "A leak pays half instead of nothing" changed the purse by **1 money over 20 leaks**.

**Cause.** `floor(kill_money * 0.5)` is `0` when `kill_money` is `1`: the percentage was applied AFTER the rounding, so it erased the only value that mattered.

**Rule.**

* The scale is applied to the UNROUNDED amount, inside the payout rule: `scr_kill_money(base, wave, ramp, scale)` multiplies into the same `money_carry` the difficulty column already uses (LL-042), and the sim mirrors it (`_payout(scale=)`). Two leaks of a 1-money creature then pay exactly 1 between them.
* **Multiply before the floor, or the fraction disappears.** Any "pay 50%" on an integer currency has to share the same carried remainder as everything else.
* **Carry, do not round, at the payout site** - LL-042 again, and this is the third bug with that shape.
* **Test the SMALLEST value, not the average.** `0.5 x 1` is where a percentage dies; `0.5 x 100` passes any test.

**See also.** [LL-042](#ll-042)

---

<a name="ll-062"></a>
## LL-062 — A function that reads the caller's scope cannot be extended

**Look for.** **Crit could not be added** - the damage function had no amount to multiply.

**Cause.** `scr_do_damage(arr, i)` subtracted `damage_calc`, an instance variable the CALLER set, so its result depended on whose scope called it (AGENTS rule 6). Now the amount is a parameter and the tower passes the `shot_damage` it locked at the swing.

**Rule.**

* `scr_do_damage(_arr, _ind, _amount)`; the tower passes `shot_damage`, locked when the swing starts. `damage_calc` is deleted from the project (a test greps every `.gml` for it). The strike loop is written out rather than `for_array`, because a three-argument call is clearer than a closure or a global.
* **If a function needs a value, it takes it as a parameter** - even when only one caller exists today. The second caller is where a scope read becomes a wrong number instead of an error.
* **Per-swing state is fine; per-scope input is not.** `shot_damage` lives on the tower because a swing spans frames. The difference is that the function is TOLD it, not reading it.
* **A callback helper with a fixed signature is a limit, not an obstacle to route around.** A short explicit loop beats a closure whose only purpose is to satisfy `run_script`.
* **Prove a refactor with an unchanged table.** `gm balance project --all-waves` and `gm balance sim` were captured before and after and diffed: byte-identical. That is the only honest proof that a "no behaviour change" refactor changed no behaviour - and it costs one command.

---

<a name="ll-063"></a>
## LL-063 — A test that asserts a LINE fails when the editor rewrites the line

**Look for.** **A test changed colour with no edit** - it asserted a LINE, and the IDE re-saved an equivalent one.

**Cause.** `assertIn("id mod 97", src)` vs the code's `irandom(97) * 0.00001`, after GameMaker wrote `.gml` + `.yy` in the same millisecond. Test the PROPERTY (rolled once, too small to reorder); on an unexplained red, check mtimes before theories.

**Rule.**

* **Assert the property, not the expression.** Here: the buffer must be rolled ONCE (`variable_instance_exists` guards it - a per-frame random is the very flicker it exists to prevent) and it must be smaller than 1/32 of a depth unit, so it cannot reorder two different y. Which random it is does not matter.
* **When a test changes colour with no edit, check mtimes before theories.** `ls -l --time-style=full-iso` on the asset and on the test. Two files of one asset sharing an mtime to the millisecond means the IDE wrote them.
* **A comment describing a mechanism the code no longer uses is the same class of lie as a stale doc** - and it is what made the test's wrong assumption look right in the first place. Fix the comment in the same edit as the test.

**Files.** `scripts/scr_setDepth/scr_setDepth.gml`

**See also.** [LL-008](#ll-008)

---

<a name="ll-064"></a>
## LL-064 — A loop that ends at the end of the file replays the ENDING

**Look for.** The **music fades out in the middle of a stage**, and the menu goes quiet every ~3 minutes - no error, and the track is still "playing".

```
META  [MUSIC] region 1 "Wilted Sprouts" mus_world1 (ref) loop 0 -> 163.53s (whole track)
```

**Cause.** The loop had **one end**: `loop_in` was the chorus start and the loop ran to END OF FILE, so every cycle played the outro fade. The menu did not set loop points at all, so it was worse there. A loop **section** has two ends.

**Rule.**

* A section has **two** ends.
* `music_row()` takes `loop_in` **and** `loop_out`; `music_data` carries the measured pair for all seven tracks.
* `scr_music_apply_loop(row)` is the ONE place that calls `audio_sound_loop_start()` / `audio_sound_loop_end()`, and it returns what it actually applied so the caller logs the truth.
* `scr_music_start_menu()` is the menu's counterpart to `scr_music_start_level()`, and all four menu call sites now use it.
* The log ends in `(section)` rather than `(whole track)`, with both ends.
* The points were measured, not guessed: a 20 ms RMS envelope against each track's median level (0.9x it) finds where the intro reaches full level and where the final outro falls away, then both are snapped to the bar grid at the track's BPM. *Wilted Sprouts* comes out `14.63 -> 152.20` - 137.6 s of body, which is what a 3-5 minute stage should be hearing.

**Files.** `scripts/music_data/music_data.gml`, `scripts/scr_music_apply_loop/scr_music_apply_loop.gml`, `scripts/scr_music_start_level/scr_music_start_level.gml`, `scripts/scr_music_start_menu/scr_music_start_menu.gml`, `objects/obj_title/Step_0.gml`, `objects/Menu/Step_0.gml`, `notes/systems_overview/systems_overview.md`.

**See also.** [LL-034](#ll-034), [LL-004](#ll-004), [LL-044](#ll-044)

---

<a name="ll-065"></a>
## LL-065 — A status that legitimately STOPS a monster looks exactly like a stuck one

**Look for.** Monsters **vanish ~5 s after being stunned**, and the stage loses Exterminator.

```
PATH  WARNING: monster 100003 stuck at 412,288 - path_position 0.37 unmoved for 5s (path_free=1 retry=0)
PATH  WARNING: 1 stuck monster(s) cleared so the wave can end (2 still walking)
```

**Cause.** The LL-031 safety valve fires on "`path_position` has not moved", which a stun produces ON PURPOSE. A held monster is not a stuck one: the counter now only runs while `status_speed_mult() > 0`.

**Rule.**

* A SLOW is a fraction (0.55), not a hold, so a slowed monster still advances and still counts - the valve's five-second budget is far longer than any slow needs.
* **When you add a mechanic that stops something, grep for who reads its motion as evidence.** `stuck_frames`, `wait_stuck`, `path_retry` and `path_escape` are all "is this thing broken?" counters, and every one of them starts lying the moment stopping is legal.
* **A safety valve must fire on EVIDENCE of a fault, not on absence of the good thing.** LL-031 fixed the opposite mistake (a timer that ended every wave after six seconds); both bugs are the same valve asking a question it cannot answer.
* **A status is a MULTIPLIER, never a special case.** `path_speed` has one owner and the status multiplies it last, which is why a stun needed no code in the follower - and why the one place that had to change was the valve.
* **One instance per kind, strongest wins** (`status_apply`): an effect that stacks is an effect whose strength is "however many towers got in range".

**Files.** `scripts/scr_status/scr_status.gml`, `scripts/scr_zomb_updatePosition/scr_zomb_updatePosition.gml`, `scripts/scr_zomb_pathSpeed/scr_zomb_pathSpeed.gml`, `objects/obj_mon/{Create_0,Step_0,Draw_0}.gml`

**See also.** [LL-031](#ll-031), [LL-034](#ll-034), [LL-021](#ll-021)

---

<a name="ll-066"></a>
## LL-066 — The Linux IDE finds fonts by walking /usr/share/fonts, so a user install does not exist

**Look for.** A font **installed for the user works everywhere except GameMaker** - `fc-list` finds it, KDE renders it, the font picker does not list it.

**Cause.** The Linux IDE discovers fonts by **walking `/usr/share/fonts`**, never fontconfig, so `~/.local/share/fonts` does not exist as far as it is concerned - and a font resource keeps drawing text without any TTF, because its glyphs are **baked** into a PNG atlas.

**Rule.**

* An alternative with no root and no font cache: tick **Include TTF** in the font editor (`checkbox_includettf` / `label_ttfpath`); the `.yy` grows `"includeTTF": true` with a `"TTFName"` and the TTF is copied into the resource folder, so the project bakes from its own file on any machine. This is the right end state for a shipped project even if the system install is what unblocks the picker today.
* **Check `/usr/share/fonts` before blaming the resource.** `ls /usr/share/fonts/truetype` is the whole test; a font in `~/.local/share/fonts` is installed for every program except the one you are using.
* **`fontName` is the FAMILY, `styleName` the FACE.** "Garden Toon ASCII" is the full name; the family is "Garden Toon". `fc-match "Garden Toon ASCII"` silently falls back to Noto Sans, which is what a wrong `fontName` does in the editor.
* **A one-face family wants `"bold": false`.** With `bold: true` FreeType synthesises an emboldened Regular; on a font whose strokes are 1-2 px that smears, it does not thicken.
* **Sizes do not transfer between families.** Measured per em: Ink Free advances 0.48 em with a 0.71 em cap; Garden Toon advances 0.70 em with a 0.847 em cap - 46% wider and 19% taller at the same `size`. Line height is nearly identical (1.08 vs 1.10 em), so keeping the existing sizes preserves the vertical rhythm and every auto-sized button (`scr_scaleButton`), while every *fixed* panel has to be looked at.
* **A stale `.gms1.yy`/`.gms1.png` pair is a leftover, not a fallback.** The IDE writes them when `maintainGms1Font` is unticked; they are never read. And it really is a leftover worth keeping: it is the only copy of the pre-rebind resource if the toggle goes back on.

**Files.** `fonts/fnt_size{12,16,20,32,48}/{*.yy,*.png}`, `GardenToonASCII.ttf`, `GardenToonASCII-outline.ttf`, `notes/font_garden_toon_{sizes,colr}.png`, `scripts/scr_scaleButton/scr_scaleButton.gml` (why buttons survive a wider face); generators: `~/Documents/GardenToonASCII-repair/{make_outline_variant,sheet_sizes}.py`.

---

<a name="ll-067"></a>
## LL-067 — A sprite font with no space frame spaces every word by its WIDEST glyph, and the string map is positional

**Look for.** A sprite font puts an **em-wide gap between every word**, and **half the UI still draws in the old font**.

**Cause.** The string map is **positional** and the sheets are `"!"`..`"~"` with **no space**, so the documented fallback is the **widest glyph's** width; and `draw_reset()`'s font is *ambient*, so any draw path that never calls `draw_set_font` keeps the old face.

**Rule.**

* Give the space a slot, and make every draw path name its font.
* > "You can define 'space' as being any character you want ... and all spaces > in text will be rendered at that width (but the image chosen will never be > rendered), or if you don't supply a sprite for space then the width of the > widest character in the sprite font will be used instead."
* Seven candidates, and two of them are **traps**: `7` and `9` are absent from the *literals*, but `string(7)` puts one on screen every time a score ends in 7 - sacrificing a digit is the choice that breaks silently, a week later, on a number. Free in the literals AND never produced at runtime: `&`, `*`, `\`, `^` and the backtick.
* The residual cost is small and worth stating: a **typed** high-score name may contain a backtick, and that character now maps to the space slot - whose image *is never rendered* - so it draws as a narrow gap. The failure mode is one invisible character in a player-entered name, not a crash and not a broken screen.
* **The map is positional: one character per frame, or every glyph after the hole is wrong.** Add a frame to ONE sheet and the whole alphabet shifts one letter. `python_tools/tests/test_gm.py::ToonFontTests` now checks exactly that against the five `.yy` frame counts (plus: a space exists, no character is mapped twice, every letter and digit has a glyph).
* **Do not assume `prop = true` means narrow.** The advance is the glyph's *ink*, and these sheets' ink runs 4-12 px at 12 px against a 12 px canvas - so `fnt_size12` is width-compatible with the old Arial 12 (~6.7 px/char) and `fnt_size16` is about **1.4x wider**. Body text that has to *fit* a fixed box is 12; 16 is for headers and labels. `initialize_game` prints

**Files.** `scripts/initialize_game/initialize_game.gml` (the map and the boot log), `scripts/draw_reset/draw_reset.gml` (the ambient default), `scripts/scr_meta_screen/scr_meta_screen.gml` (16 of the 34, plus the line gaps), `scripts/show_slider/show_slider.gml`, `objects/Menu/Draw_64.gml`, `sprites/spr_toonfont_{12x,16x,20x,32x,48x}/`, `python_tools/tests/test_gm.py` (the `ToonFontTests` guard).

---

<a name="ll-068"></a>
## LL-068 — A GUI pinned to 960x540 over a window sized from the display puts every click in the wrong place

**Look for.** "**The buttons do not work**" on a 16:10 or 21:9 window - the highlight follows the pointer onto the wrong button, and a click opens the wrong screen.

**Cause.** `points_to_gui()` divides **GUI by view** on each axis, so the two must share an **aspect**; the GUI was pinned to 960x540 while the window was sized from the **display** aspect (960x600 on 16:10), which is a 60px vertical error at the bottom of the screen.

**Rule.**

* `ui_screen_apply_camera()` is the "vertical fit, horizontal reveal" rule: it KEEPS `HView` and sets `WView = HView * (gui_w/gui_h)`, then re-centres and clamps into the room. A 21:9 window therefore shows 1260 world units across, not 960 stretched over 1260 pixels - and because GUI units and world units stay 1:1, `points_to_gui()` ends up multiplying by exactly 1 on both axes.
* `MISMATCH` is the failure, and it names the two numbers that disagree. A screenshot cannot show this; the log can. * **Anything that sets a view size must take it from `global.ui.w/h`**, never from a literal. `scr_main_cutscene` ended its zoom-out on a hard `960` and `960 * ratio`; on a wide window the aspect still matched (so no drift) but the world was no longer 1:1 with the GUI. Fixed there too.

**Files.** `scripts/scr_ui_screen/scr_ui_screen.gml` (the invariant, the refresh order, the canary), `scripts/scr_initResolution/scr_initResolution.gml` (now a one-line call), `scripts/scr_level_boot/scr_level_boot.gml` (the room's view gets the design aspect on every entry), `scripts/scr_main_cutscene/scr_main_cutscene.gml`, `objects/obj_ui/Step_0.gml` (polls the window).

---

<a name="ll-069"></a>
## LL-069 — A hand-placed layout can say "at x=600", not "under that", so three of four screens were already wrong at 16:9

**Look for.** The **World Map title runs through the Garden Book button**, Deploy's **wall sits under its own slots**, the Garden Book's shop **hangs off the right edge** - and every locked tower's **name touches its reason**.

**Cause.** Every one of those numbers was placed by hand in 960x540, so the layout could say "at x=600" but not "under that" - and the title was centred on the **canvas** while the button was measured from the **right edge**. Three of the four screens were already wrong at 16:9.

**Rule.**

* Three parts, each of which is only useful with the others - the trees stop the overlap, the fitting stops the spill, and the dump proves both.
* **`scr_ui_layout_meta`** - one flex tree per screen. Every screen is now `band 56 / body / foot 60`, and the band is `[currency 240 | title flexGrow | actions 240]`, so the title is centred in the space *between* the two fixed columns and cannot be underneath either. Deploy is slots-row-on-top (4 x 96), then a 4x2 wall of 112 cells beside a 160-wide difficulty column.
* **`scr_ui_text`** - `ui_fit_font()` picks the largest of `[32,20,16]` that fits (so "Garden Book" drops to 20pt at 675 rather than running into the button), `ui_clip_text()` truncates with `".."` and not an ellipsis, because the string map is `"!"`..`"~"` and U+2026 is not in it (LL-067). `ui_palette()` is the same idea for colour.
* A `FAIL` there means a node name the draw code reads does not exist, or a node is outside the canvas. Neither is visible in a screenshot.
* `meta_*_geom()` still returns the same struct shape it always did, now read from `ui_meta_rect("deploy", "deploy.wall")` - so every hit test in `objects/Menu/Step_0` is untouched. That is the point of doing it this way: the screen's geometry moved from a hand-placement to a declaration, and nothing that consumed it had to change.
* **A screen's geometry is DECLARED and read BY NAME.** If you are writing `_gw - 300`, you are writing a band by hand.

**Files.** `scripts/scr_ui_layout_meta/scr_ui_layout_meta.gml`, `scripts/scr_ui_text/scr_ui_text.gml`, `scripts/scr_meta_screen/scr_meta_screen.gml`, `scripts/scr_ui_check/scr_ui_check.gml`, `objects/Menu/Draw_64.gml`, `python_tools/gm/layout/` (`metrics.py`, `dump.py`, `rules.py`, `report.py`).

**See also.** [LL-067](#ll-067)

---

<a name="ll-070"></a>
## LL-070 — GameMaker compiles an unknown function call as a VARIABLE READ, so a missing name fails only when the line runs, and blames a variable that never existed

**Look for.** The layout gate's **first real run** died inside the Draw event, two lines after `UI    [GEOM] begin worldmap 960x540 items 140`: `Variable Menu.json_string(101726, -2147483648) not set before reading it.`.

```
ERROR in action number 1
of Draw Event for object Menu:
Variable Menu.json_string(101726, -2147483648) not set before reading it.
 at gml_Script_ui_check_end (line 146) - _str += " " + json_string(_it.t);
gml_Script_ui_check_end (line 146)
gml_Object_Menu_Draw_64 (line 64) - ui_check_begin("worldmap");  meta_draw_worldmap();  ui_check_end();
Script_Free called with 1208 and global 419
FAILED: Run Program Complete
```

**Cause.** `json_string` **is not a GameMaker function** (the pair is `json_parse` / `json_stringify`). GML compiles an unknown name followed by `(` as a **variable READ**, so there is no compile error, the build succeeds, and the failure waits until the line runs - naming a variable nobody ever assigned. A diagnostic that can throw breaks working rule 5.

**Rule.**

* `json_stringify` produces the literal the Python side already reads (`_read_string` → `json.loads`), so the dump format did not change.
* **An unfinished dump is a FAILURE, not a pass.** The same run exposed a second hole: `gm layout check` printed `ok 1 screen at 1 size, 0 findings (1 incomplete: worldmap 960x540)` and **exited 0**, because a block with no `end` line has no rectangles to collide - the run died before printing any.
* It was **falsified before being trusted**: re-introducing `json_string(` produced `['json_string() in scripts/scr_ui_check/scr_ui_check.gml']`. The comment/string stripper it depends on has its own test, because a `(` inside a doc comment is not a call and a `//` inside a string is not a comment.

**Files.** `scripts/scr_ui_check/scr_ui_check.gml`, `python_tools/tests/test_gm.py`, `python_tools/tests/test_layout.py`, `python_tools/gm/layout/report.py`, `python_tools/gm/layout/cli.py`, `scripts/scr_ui_layout_meta/scr_ui_layout_meta.gml`.

**See also.** [LL-003](#ll-003), [LL-002](#ll-002), [LL-069](#ll-069)

---

<a name="ll-071"></a>
## LL-071 — A picture is placed by its ART RECTANGLE, not by its origin, and the dump was registering a rectangle nobody drew

**Look for.** Icons sit **half an icon up and left** of where the layout put them, tower thumbnails are a **different size each** and two **poke out of their cell** - and `gm layout check` calls every one of those screens **clean**.

**Cause.** A picture is placed by its **art rectangle**, not its origin: the origin was subtracted **twice** (`draw_sprite_ext` had already honoured it), the **canvas** was scaled instead of the art, and the dump registered a rectangle **nobody had drawn**.

**Rule.**

* One idea, in a new script `scr_ui_image`: **place the art rectangle**.
* | Call | What it does | | --- | --- | | `ui_art_bbox` | the art box in canvas space, `[l, t, r, b, w, h]`, from `sprite_get_bbox_*` (canvas-relative - LL-047); no-art falls back to the canvas, nothing throws (LL-012) | | `ui_art_scale` | `min(maxw/aw, maxh/ah, 1)` - fits the ART, never blows it up | | `ui_art_rect` | the screen rect the art will occupy, from the art centre | | `ui_art_draw` | draws with …
* `icon_draw` and `meta_sprite_fit` both became thin callers, keeping their signatures, so all five call sites were untouched. Then the gate learned the rule: an `image` may sit inside its cell or be a backdrop behind a label (the same shape as `spill`), and anything else - art over text, art crossing its cell's edge, two pictures on the same pixels - is a finding.
* The origin did not need to be fixed anywhere, only *read once, inside the draw*. That is why `spr_blood_magnet` and `spr_blood_moon` still have `(0,0)` origins and land exactly like every other icon, and why the 12 tower sheets all land on `y 100..176` - the full band, one height, inside the cell.
* **Never subtract an origin from a centre.** If you have a point you want the *picture* centred on, compute where the picture is and move the draw to match. `draw_sprite_ext` has already honoured the origin; subtracting it is doing it twice.
* **Measure the art, not the canvas.** `sprite_get_bbox_*` is canvas-relative and **inclusive** at the far edge, so width is `bbox_right - bbox_left + 1` and the art centre is `(bbox_left + bbox_right + 1)/2`. A canvas is a working size; it is not the picture.

**Files.** `scripts/scr_ui_image/scr_ui_image.gml` (new), `scripts/scr_ui_icons/scr_ui_icons.gml`, `scripts/scr_meta_screen/scr_meta_screen.gml`, `python_tools/gm/layout/rules.py`, `python_tools/tests/test_layout.py`.

**See also.** [LL-047](#ll-047), [LL-012](#ll-012)

---

<a name="ll-072"></a>
## LL-072 — A step is not a unit of time: an animation timed in STEPS changes duration when the frame rate does, and nothing in the code looks wrong

**Look for.** The title-screen zombie's **idle loop plays twice as fast** as in the original build - same art, no error, and the walk and grab look right.

**Cause.** The state asked for **60 STEPS**, and a step is not a unit of time: 60 steps was 2 s in the 30 fps build and is 1 s at 60 fps, exactly the factor reported. [LL-030](#ll-030) made animations duration-based but converted **at each call site**, so the unit stayed steps and the frame rate moved.

**Rule.**

* `steps=120` at `fps=60` **is** the arithmetic in one line: if that says `60`, a caller is still counting steps.
* **If the period matters, write it in seconds** and convert at **one** owner site. A bare step count in a state machine is the bug.
* The frame rate is a **global** that can move under you (`game_get_speed(gamespeed_fps)`; `room_speed` in GMS1). Grep the literal: `grep -rn 'animSpeedForSteps(.*, 60)'` lists every remaining step-timed call site. Backlog card `anim-step-counts-since-30fps` tracks the ones left.
* A sprite declares its speed in **frames per second or frames per game frame** (`sprite_get_speed_type`), so the conversion must normalise that first — which is why the seconds function **delegates** to `scr_animSpeedForSteps` (line 45) instead of repeating the maths.
* **The animation periods are deliberate and named.** The title idle keeps its 2.0 s duration; title walk/grab and monster walk/idle use `ZOMB_CYCLE_SECS` (1.0 s). The emergence grow uses `ZOMB_EMERGE_SECS` (1.0 s) measured with clamped `delta_time`, so it stays the same length at normal and 3x speed.
* When *one* loop is reported as "too fast" and its neighbours look fine, do not look at the art: check the unit of the number that was asked for.

**Files.** `scripts/scr_animSpeedForSteps/scr_animSpeedForSteps.gml`, `objects/obj_titleZomb/Step_0.gml`, `objects/obj_tower/Create_0.gml` (the `anim_seconds` precedent), `scripts/scr_zombie_emerge/scr_zombie_emerge.gml`, `scripts/scr_zombie_path/scr_zombie_path.gml`.

**See also.** [LL-030](#ll-030), [LL-002](#ll-002)

---

<a name="ll-073"></a>
## LL-073 — A frame is TWO PNGs, and anti-aliased alpha is a file problem: the sprite looks sharp in the editor and soft in game

**Look for.** A sprite looks sharp in the **sprite editor** and soft/fringed **in game**; or a "cleaned" sprite comes back unchanged after a reload.

**Cause.** A frame is **two PNGs** (`<frame>.png` *and* `layers/<frame>/<layer>.png`) - write one and the editor and the game disagree. And anti-aliased alpha is a **file** problem: at `base_scale 0.25` a 50 %-covered pixel is 12 %-covered, which no filter or scaling can undo.

**Rule.**

* The stroke is **inside** the silhouette, so the opaque mask never changes - which is why no `.yy` has to be edited, and why `gm roundtrip` stays at `0 differ` and `git diff` shows nothing but `.png` files.
* **After any pixel edit, write both copies and then compare them.** `gm art check` does exactly that: it decodes every frame, and fails on a partial alpha, a colour left in a cleared pixel, a contour that is not `(0,0,0,255)`, or a layer copy that does not match its root. Exit 0 or it is not done.
* **Read the frame and layer GUIDs out of the `.yy`** (`frames[].name`, `layers[].name`); never glob the folder. Note the layer *file* is named for the layer and its *folder* for the frame, which is one swap away from a silent mismatch.
* **An inside stroke cannot move the bbox; an outside one can.** If the rim ever has to grow the sprite, the `.yy` (`width`/`height`/`bbox_*`) must be re-imported through the IDE, never hand-edited ([LL-009](#ll-009)).
* **Do not "fix" soft art by scaling or filtering.** Measure the alpha histogram first (`pixels.alpha_histogram`); if there are fractional pixels, the file is the problem.
* **Idempotent or it is not a pass.** The next art drop will run this again over the same files; `inner_outline` only counts pixels it actually changed, so a second run reports `stroke 0 px`.

**Files.** `python_tools/gm/art/{png,pixels,sprites,clean,report,cli}.py`, `python_tools/gm/cli.py`, `python_tools/tests/test_art.py`, `art_descriptions.md` §3.0.

**See also.** [LL-009](#ll-009)

---

<a name="ll-074"></a>
## LL-074 — A surface bake inherits the projection that is already set, and `matrix_build_orthographic` is not a function

**Look for.** A one-off surface bake written with `matrix_set(matrix_projection, matrix_build_orthographic(...))` - **no compile error, no warning**, and the first meta screen dies on `Variable Menu.matrix_build_orthographic(…)`.

**Cause.** That function **does not exist** (the pair is `matrix_build_projection_ortho` + `matrix_set`), and GML reads an unknown name before `(` as a **variable** ([LL-070](#ll-070)). You need neither: `surface_set_target` does **not** change the projection, so a bake under Draw GUI fills a half-size surface at half resolution and the two scalings cancel by construction.

**Rule.**

* **Check that a function EXISTS before you write it.** `gm gml-functions` on the script you are editing tells you what really resolves; the same trap is `matrix_build_projection_ortho` vs `matrix_build_orthographic`, `json_string` vs `json_stringify` ([LL-070](#ll-070)), and every other name that feels like it should exist.
* **Prefer the projection you were given to one you set.** A hand-set projection is global state that has to be restored, and GameMaker replaces all three matrices at the start of the next event anyway - so "save, set, draw, restore" is three chances to get it wrong in exchange for nothing.
* **The bake is drawn at GUI scale, so it must be drawn back at GUI scale.** `surface_create(w * 0.5, h * 0.5)` is a resolution decision, not a layout one; the moment either draw stops going "across `global.ui`", the blur shifts or crops instead of scaling.
* **A bake belongs in a sprite, not a surface.** Sprites survive a surface being lost (minimise, resolution change), and the cache is the feature - `MENU blur bake 683x384 …` must appear **once per run**; twice means the cache is not being read.

**Files.** `scripts/scr_menu_blur/scr_menu_blur.gml`, `shaders/shd_blur/shd_blur.fsh`, `objects/Menu/Draw_64.gml`, `scripts/scr_drawBlurScreen/scr_drawBlurScreen.gml`.

**See also.** [LL-070](#ll-070), [LL-002](#ll-002), [LL-076](#ll-076)

---

<a name="ll-075"></a>
## LL-075 — A bank is a catalogue, not a scene: six bosses made stage 1-1's boss wave 2.5× harder on paper

**Look for.** **No GML changed** - only the creature table grew from 2 bosses to 6 - and `gm balance`'s numbers for **stage 1-1** moved while a long-green test went red; the projection and the sim still agreed with each other.

**Cause.** `model.demand` priced a boss wave from the **whole bank** (`t.bosses`) and took its mean: invisible at two bosses, a **2.5× error at six** (210 life instead of the row's 82). `sim.wave_spec` read the same table, so the two tools shared the mistake. A bank is a **catalogue**; a stage is **what arrives**.

**Rule.**

* and `sim.wave_spec` reads `self.scene.bosses if d.boss else self.scene.monsters`, falling back to the full bank **only** when the row names none - the same fallback, in one place, documented. `Scene.monsters` and `Scene.bosses` are built from the stage row.
* **Demand, speed and payout come from the row, never from the bank.** If a number describes "what this wave sends", its source is `scene.*`; `tables.*` is the catalogue behind it.
* **A mean over a list that just grew is a silent balance change.** Adding rows is not a data-only edit for anything that averages the table. After a roster change run `gm balance` on 1-1 and `gm balance check` before believing any other number.
* **A test that goes red on a data-only change is doing its job.** Read it as "the model moved", not "the test is stale" - here the test was right, and stage 1-1 was being modelled as if it fought the mean of every boss in the game.
* **Two tools that share a formula agree for free** ([LL-038](#ll-038)). When both move together, look at what they *both* read, not at either one.

**Files.** `python_tools/gm/balance/model.py`, `python_tools/gm/balance/sim.py`, `python_tools/tests/test_balance.py`, `scripts/stage_data/stage_data.gml`, `scripts/scr_setupSpawning/scr_setupSpawning.gml`.

**See also.** [LL-038](#ll-038)

---

<a name="ll-076"></a>
## LL-076 — A layer is not a contract: the room editor turned the FX layer into a background, and the switch went on switching nothing

**Look for.** The four meta screens are **sharp** while the log says `MENU  blur on`, and no flag or depth changes it - it looks like a GPU/display bug.

**Cause.** The room editor had converted the FX layer into a **`GMRBackgroundLayer`** that kept the same name, the same `effectType` and `effectEnabled: true`; a background layer draws a sprite and never filters, so both flags the code checked genuinely read "on". `effectType` is dead data unless `resourceType` is `GMREffectLayer`. The blur is a shader pass over `application_surface` in `Draw GUI` now, and the log reports the EFFECT it drew, not the intent.

**Rule.**

* This is the pause screen's recipe (`scr_drawBlurScreen`, working in game since 4.4.2), applied every frame instead of once - the room behind a meta screen is alive (particles, the title zombie) and a frozen backdrop reads as a bug. At a quarter of the canvas `shd_blur`'s 160 taps cost 5.2 M reads a frame instead of 83 M, and a lower scale blurs *further*, because the shader samples NORMALISED coordinates.
* **Read the layer's TYPE before trusting its effect.** `GMREffectLayer` and nothing else runs a filter; an `effectType` on a background/instance/tile layer is dead data that will fool `grep`. (This is why the room's `Blur_Effect` layer is now dead weight - delete it in the IDE: it draws a second copy of the sidewalk.)
* **Log the effect, never the intent.** `MENU blur on shd_blur 240x135` is printed by the code path that actually drew a blurred frame; a failure prints `MENU blur FAILED <reason>` **once per reason**. A diagnostic that reports what was asked for is a diagnostic that cannot fail.
* **A `.yy` in the repo is not a contract.** Room-owned state (layers, room instances) is editable from outside your diff and the runtime reports none of it. Keep visual MECHANISMS in GML; use the room for art.
* **If you ever do go back to a layer:** an FX layer has TWO switches - `layer_enable_fx` *and* the layer's visibility (the asset ships it hidden) - it applies to the layers **below** it (a higher depth is "in front"), and the room resets both flags on every entry.
* **A per-frame blur has to be smaller than the canvas.** `MENU_BLUR_SCALE` is the knob: 0.25 = 5.2 M reads, 0.5 = 20.7 M, 1.0 = 83 M a frame.

**Files.** `scripts/scr_menu_blur/scr_menu_blur.gml`, `objects/Menu/Draw_64.gml`, `objects/Menu/Step_0.gml`, `shaders/shd_blur/shd_blur.fsh`, `python_tools/tests/test_content.py`, `rooms/rm_menu/rm_menu.yy` (the converted layer, kept as the evidence).

**See also.** [LL-074](#ll-074), [LL-002](#ll-002)

---

<a name="ll-077"></a>
## LL-077 — Braces balance, code does not: a tail appended at EOF nests everything after it

**Look for.** Nothing at all - the suite, the brace count, `gm gml-functions`, `roundtrip` and a diff are all green, and the file still is not what it reads like.

**Cause.** A function TAIL appended at **EOF**: the braces still balance (14 and 14) while every later function is nested inside an unclosed `if`, so GML compiles a program nobody intended. Count the DEPTH at each `function`, not the total in the file.

**Rule.**

* Broken file: `menu_blur_fail 2, menu_blur_draw 2`. Fixed file: `0, 0, 0, 0`. The test pins the four names in order as well, so a function that vanishes is red too.
* **Read the whole file after a scripted whole-file rewrite** - or do not rewrite a whole file with a tool that splices. Print it back with line numbers and look at the last twenty lines: a stranded tail is always at EOF.
* **Verify the FUNCTION, not the file.** When a structural edit touches one function, `awk` out the definition and check that the next `function` starts at column 0.
* **A green suite is evidence about the assertions, not about the code.** Twelve tests written for this exact script passed on the broken version of it.

**Files.** `scripts/scr_menu_blur/scr_menu_blur.gml`, `python_tools/tests/test_content.py`.

**See also.** [LL-076](#ll-076)

---

<a name="ll-078"></a>
## LL-078 — A sprite's ground is its ORIGIN: a "ground offset" measured the empty canvas under the art, and the bbox it read was the envelope of all sixteen frames

**Look for.** Corpses settle **below the path** they died on - 6.6 px on the Bell-Ringer, 28 on the Shroud - and the Gardener walks 2 px into the ground all game; no error, nothing in the log.

**Cause.** `obj_mon/Draw_0` moved `y` by `(sprite_get_height-1) - sprite_get_bbox_bottom`: the **empty canvas rows under the art** - room kept for the body to lie down, 22 of the Bell-Ringer's 175 px sheet - which says nothing about where the feet are, and one bbox serves all sixteen frames besides. The art was already on the walk's origin (within 5 px on all fifteen rigs).

**Rule.**

* `obj_mon/Draw_0.gml` keeps only the comment (the ground line is the origin, LL-078), and `zomb_ground_offset()` is deleted from `scr_zomb_art.gml`; it had exactly one caller.
* **A monster's ground contact is its sprite origin.** If a pose does not meet its neighbours, re-cut the art onto that origin. Never compute a shift at draw time and hope: the number will be derived from something that is only *correlated* with the mistake.
* **`sprite_get_bbox_*` (and the `.yy`'s `bbox_*`) is a union over frames.** Fine for a hit box, wrong for "where is this frame". To measure one frame, decode its PNG - `gm.art.png.read_png`, then the lowest row with any alpha. Frame 0's file is `<frames[0].name>.png`, in `.yy` frame order (the PNGs on disk are not in frame order - `ls` sorts by GUID).
* **Compare art-relative, never canvas coordinates across sheets.** Two sheets can show the same feet with origins 20 px apart, because their canvases differ in size. The only number that means anything is `lowest painted row - yorigin`.
* **When an error is proportional to something in the art, suspect a quantity that is not the one you meant.** Here: "distance from the art to the bottom of the canvas", which grows exactly with how far the pose reaches down.
* **`y +=` in a Draw event is a smell.** It mutates the instance for one frame, so anything that reads `y` later in the step - depth, targeting, the water crop, a second draw - sees the shifted or unshifted value depending on event order. The water branch's `draw_self_part(0,0,...)` crop is derived from the origin, so the shift never applied there anyway.

**Files.** `objects/obj_mon/Draw_0.gml`, `scripts/scr_zomb_art/scr_zomb_art.gml`, `python_tools/tests/test_content.py`.

**See also.** [LL-079](#ll-079)

---

<a name="ll-079"></a>
## LL-079 — A missing slot is not an error, it is the PREVIOUS animation: death played the walk frames, and the stage you test first is the one creature that had no die art

**Look for.** **"The walk animation plays as the zombies die"** - the kill line prints, the money is paid, the body **strides in place** for 0.8 s, then gone. Every other part of the death beat behaves.

```
META  [LEVEL] kill Grumble-Mulch +money=4 +pts=3 die=spr_grumble_die (life 12 left)
META  [LEVEL] kill Something-New +money=4 +pts=3 die=NONE (keeps the walk art) (life 12 left)
```

**Cause.** Five spawn rows still carried the pre-rig `array(spr_x_walk)` while their `_idle`/`_attack`/`_die` sheets sat in the `.yyp`; `zomb_art_play` **answers false for an empty slot and leaves the previous animation running**, by design. Region 1 stages 1-5 spawn *only* those five, so the creature anyone tests first is always one of them.

**Rule.**

* **A fallback that "keeps what you had" must say so in the log.** The silent version is indistinguishable, in a screenshot, from the animation being broken - and the person best placed to notice is the one who has to grep the log. `scr_zomb_death` prints `die=` (the sprite name, or `NONE ...`) on the per-kill line it already printed, once per kill.
* **Pin the TABLE, not the rows the table happens to contain.** `test_every_creature_row_is_in_the_rig_table` asserts the rig table and the spawn table name the **same creatures** (equality both ways), so a row cannot exist without its slots being checked, and a renamed rig cannot hide behind a name that no longer matches.
* **Art is delivered with its row.** A sheet in the `.yyp` is not "in the game": `gm list GMSprite` only says *registered*, and `zomb_bank_report`'s boot line prints `rig=` per row - `rig=1` is the tell, `rig=4` is the fix. When a card is titled "art: creature X, four states", the spawn row is part of the delivery.
* **Check which creatures a stage can even send before believing "the death animation is broken".** `stage_data()` says region 1 stages 1-5 exercise five rows; a report from stage 1 is a report about those five, nothing else.

**Files.** `scripts/scr_setupSpawning/scr_setupSpawning.gml`, `scripts/scr_zomb_death/scr_zomb_death.gml`, `scripts/scr_zomb_art/scr_zomb_art.gml`, `python_tools/tests/test_content.py`, `sprites/spr_grumble_die/`, `sprites/spr_tusk_die/`, `sprites/spr_zero_die/`.

**See also.** [LL-012](#ll-012), [LL-041](#ll-041)

---

<a name="ll-080"></a>
## LL-080 — Death is a STATE, not a flag polled inside another state's tail: a zombie killed while it was rising stood up and walked

**Look for.** **A zombie killed while it is still rising stands up and walks** - the kill line prints, the money is paid, and the body strolls off; other corpses get **dragged along their route** while they topple; some falls show a **one-frame "standing" flicker** just before the body vanishes.

**Cause.** Death was a **flag polled at the top of the walking state**, not a state: `scr_zombie_path` checked `dying` and called `scr_zomb_death` again to finish the fall. A monster killed in EMERGE never reached that check (the emerge has no life test, and its last step requests the walk); the fall clock started one step after the kill, so the sheet wrapped to frame 0 and frame 0 was **drawn**; `Alarm_0`, armed by a tower brush - which is where kills happen - could `path_start` a corpse, and the follower moves x/y from the **engine**; and the destroy used `round(ZOMB_DIE_SECS*fps)` instead of watching the animation, so it agreed with the sprite only by coincidence.

**Rule.**

* The wrap is detected on the step *after* the last pose was drawn, and the destroy happens **before Draw**, so every pose is drawn once and frame 0 never returns. `zomb_die_art` is the switch between the two clocks: a rig with no die slot keeps the walk art it died in ([LL-079](#ll-079)) and is removed by the step count, and a logged `dying_time > zomb_die_steps*2 + 2` backstop covers a sheet that cannot animate at …
* **A condition that can end another state is a state.** If something can stop a state mid-way (`dying`, a stun, a leak), make it a state of its own and test for it in the dispatcher - *before* the switch - so no state can be written that forgets it. `return` after the check: the old body must not run on the step of the transition.
* **Never time an animation twice.** If the art was given a duration, ask the art when it is done (`image_index` wrapped), and keep the step count only as the fallback for "there is no art to watch", with a logged backstop.
* **Anything that moves an instance from the engine** (`path_start`, a timeline, a motion add) must be stopped in the **entry** code of the state that must not move - and whatever could restart it (an alarm) needs its own guard.
* **`state_time == 0` is only entry code if the dispatcher resets the clock.** `scr_runState` incremented *after* the body, so a state entered from the middle of another state's step lost its entry frame; request/apply (`= 0` on apply, `++` while idle) is what makes "just entered" mean exactly one step.
* **A transition you cannot see is a transition you cannot debug.** `scr_meta_log` names every change (`META [ZOMB] now DIE … life 0/7`) and the entry decision (`META [ZOMB] die <id> art=spr_x_die frames=16 image_speed=0.33 steps=48`).

**Files.** `scripts/scr_zomb_state/scr_zomb_state.gml` (new), `scripts/scr_zombie_die/scr_zombie_die.gml` (new), `scripts/scr_zomb_death/scr_zomb_death.gml`, `scripts/scr_zombie_path/scr_zombie_path.gml`, `scripts/scr_zombie_emerge/scr_zombie_emerge.gml`, `scripts/scr_zomb_updatePosition/scr_zomb_updatePosition.gml`, `objects/obj_mon/{Create_0,Step_0,Alarm_0,Draw_73}.gml`, `python_tools/tests/test_content.py`.

**See also.** [LL-004](#ll-004), [LL-040](#ll-040), [LL-079](#ll-079)

---

<a name="ll-081"></a>
## LL-081 — A slot read by INDEX is one edit away from silent: name it, then make the miss loud

**Look for.** A dying monster still draws `spr_*_walk` - the Draw print says `state: DIE` and `Sprite-ind: spr_grumble_walk` - with **nothing in the log to say which link of the art chain is wrong**, and every fix attempt is a guess.

```
  META  [ZOMB] WARNING Gardener has NO die slot - its corpse keeps the art it died in, removed by the step clock: Gardener slots=4 walk=… die=none
```

**Cause.** The rig was a **bare array copied onto every instance** and read **by index** from four scripts; a slot that is missing answers **-1**, which every caller treats as "change nothing" - so *keep the walk art* is a legal answer to "play the die art". And the two lines that could have said which link broke (`ZOMB die … art=`, the bank report's `rig=N`) are gated on `global.devMode`, which is **false** in `initialize_game`: the run that showed the bug had no record at all.

**Rule.**

* `mon_roster_build(spawn_mon, spawn_boss)` runs **once**, at the end of `scr_setupSpawning` - the only scope where both banks exist - and caches the array in `global.mon_roster`, so a monster never reaches into another instance for its own art (rule 6).
* `scr_level_spawn` hands each spawn `_inst.rig = mon_rig_find(_mon[MON.name])`, so every monster of a creature shares **one** struct.
* `zomb_rig()` is what the states call. It pulls by `data[MON.name]`, caches on the instance, and **self-heals** from `sprite_array` when the roster has no answer - an instance that predates this file still gets its art.
* One line per corpse plus one per rig at boot (`RIG walker 0 Grumble-Mulch slots=4 walk=spr_grumble_walk idle=… attack=… die=spr_grumble_die`), which answers all three causes in one read: `die=none` is a row/roster problem, `changed=false` with `now=spr_x_walk` is the apply step, and `now=spr_x_die` means the art was always right and whatever reported otherwise was reading something else.
* `zomb_art_sprite` and `zomb_art_play` are **deleted** from `scr_zomb_art.gml` (nothing may index a rig array again), `zomb_bank_report` now prints all four slots through `mon_rig_report` instead of the first one, and the debug print in `obj_mon/Draw_0` guards `sprite_get_name` behind `sprite_exists` - it was a fatal error on `-1` (LL-012).
* **Never read a rig by position.** A slot is `rig.die`, not `_art[3]`: an index is one edit - one reordered row, one short array, one copied default - away from a wrong answer that has no name. `grep -rn 'sprite_array\[' objects scripts` must stay empty.

**Files.** `scripts/scr_mon_roster/scr_mon_roster.gml` (new), `scripts/scr_zomb_art/scr_zomb_art.gml`, `scripts/scr_zombie_die/scr_zombie_die.gml`, `scripts/scr_zombie_path/scr_zombie_path.gml`, `scripts/scr_zombie_emerge/scr_zombie_emerge.gml`, `scripts/scr_zomb_death/scr_zomb_death.gml`, `scripts/scr_level_spawn/scr_level_spawn.gml`, `scripts/scr_setupSpawning/scr_setupSpawning.gml`, `objects/obj_mon/{Create_0,Draw_0}.gml`, `python_tools/tests/test_content.py`.

**See also.** [LL-078](#ll-078), [LL-079](#ll-079), [LL-012](#ll-012), [LL-077](#ll-077)

---

<a name="ll-082"></a>
## LL-082 — An object's `spriteId` is not the art: `spr_mon` is ONE frame, and it drew the walk AND the death of every monster

**Look for.** **Every monster spawns with one sprite for both its walk and its death** - a 32x32 still, the same picture for every creature and every state, while fifteen rigs of walk/idle/attack/die sheets sit in `sprites/`. The Draw print says `Sprite-ind: spr_mon`. No error: every spawn row carries its four slots, `gm roundtrip` is clean, and `zomb_rig()` hands back the right struct.

**Cause.** Two facts that are each correct in isolation.

* `obj_mon.yy`'s `spriteId` is `spr_mon`, a **1-frame 32x32 placeholder**, and Create copies it into `sprite_array`. A `spriteId` is what the instance *draws* until something writes `sprite_index`; it is a default, not a promise that anything will replace it.
* The only two writers of a monster's `sprite_index` were **state entry code**: `scr_zombie_emerge` (EMERGE, first Step) and `mon_rig_play()` (PATH/DIE). A monster created anywhere else - a unit test, a dev seed, an instance dropped in the room, a spawn whose state never runs - therefore plays the placeholder for its whole life, and "walk" and "death" are the same single frame.

Nothing in the log could distinguish that from "the art never landed": the `RIG   walker N …` lines name the ROSTER, never the sheet an INSTANCE was wearing.

**Rule.**

* **Dress at birth.** `scr_level_spawn` calls `mon_rig_dress(rig)` inside `with(_inst)` in the same breath as `_inst.rig = mon_rig_find(...)`, so a monster is drawn in its own class's WALK sheet on the first frame it is visible. `mon_rig_dress` asks `mon_rig_slot(_rig, ZOMB_ANIM.walk)` - by NAME, never by position ([LL-081](#ll-081)) - returns `-1` and changes nothing when a class has no walk art, and **never touches the die slot**: falling is the DIE state's job ([LL-080](#ll-080)).
* **Heal every step, on the sprite, before the dispatch.** `scr_zomb_step` runs `if(!mon_rig_has(_rig, sprite_index)) mon_rig_dress(_rig);` after `scr_zomb_begin()` and *before* the death check and the `switch`. It can never fight a state: a walker holds its walk sheet and a corpse holds its die sheet and both are IN the rig, so `mon_rig_has` answers true and nothing is written - it fires only for a monster wearing art the rig never named. Re-dressing the sheet already playing is a no-op, so a per-step caller cannot restart a cycle in progress ([LL-030](#ll-030), [LL-079](#ll-079)).
* **Say what a class got, once per creature.** `mon_rig_report_spawn` prints `META  [ZOMB] SPAWN Grumble-Mulch  walk=spr_grumble_walk  die=spr_grumble_die`, so "is any of the zombie art being used?" is answered from the log and not from a screenshot. `walk=none` is a row/roster problem; a sprite name different from the class's is a dressing problem.
* **A placeholder must not pretend to animate.** `obj_mon/Create_0` says in words that `spr_mon` *is* the placeholder, keeps `sprite_array` (it is what `zomb_rig()` rebuilds a rig from, as a last resort) and sets `image_speed = 0`, so a one-frame sheet cannot drift its `image_index` and read as a broken walk cycle.
* **Before trusting a default, ask what is proved to overwrite it.** For every `spriteId` / `mask_index` / `depth` / `image_*` set in an object file, name the line that always runs and replaces it. If the answer is "a state's entry code", that is not a guarantee - it is a hope that the state is reached.

**Files.** `scripts/scr_mon_roster/scr_mon_roster.gml`, `scripts/scr_level_spawn/scr_level_spawn.gml`, `scripts/scr_zomb_state/scr_zomb_state.gml`, `objects/obj_mon/Create_0.gml`, `sprites/spr_mon/spr_mon.yy`, `python_tools/tests/test_content.py`.

**See also.** [LL-081](#ll-081), [LL-080](#ll-080), [LL-030](#ll-030), [LL-012](#ll-012)

---

<a name="ll-083"></a>
## LL-083 — `is_real()` on an enum value: every rig slot built as -1, so every monster wore `spr_mon` while the roster trace said `walk=none`

**Look for.** The boot trace prints `RIG   walker 0  Grumble-Mulch slots=4 walk=none idle=none attack=none die=none` for ALL FIFTEEN creatures, monsters draw `spr_mon` - the one-frame placeholder - for their whole life (`Sprite-ind: spr_mon` on EMERGE and PATH), and corpses die in it (`RIG   die <id> ... was=spr_mon now=spr_mon changed=0 frames=1 speed=0`). No error anywhere, `gm roundtrip` is clean, the whole test suite is green, and an OLDER build dressed the same creatures fine - so the art, the banks and the spawn all look right. The `RIG` boot lines are ungated (`show_debug_message`), so they are in `~/GameMakerStudio2/debug.log` even with `global.devMode` false.

**Cause.** `mon_rig_pick(_art, _slot)` opened with `if(!is_real(_slot)) return -1;`, and `_slot` is a `ZOMB_ANIM` constant. **Enum values are stored as int64s, and `is_real()` answers FALSE for int64s** - the manual's `is_real` page says so outright ("This function will return false for any enum values as they are stored as int64s"). Every slot of every creature therefore bailed on that one line at roster build: the struct kept `name` and `slots=4` (the art array WAS read, 4 long) but `walk/idle/attack/die` were all -1. Downstream, `mon_rig_slot` answers -1, so `mon_rig_dress` never dresses at birth, the heal in `scr_zomb_step` never heals, the EMERGE entry never switches and `mon_rig_play` never falls - and `zomb_rig()`'s rebuild-from-instance fallback calls `mon_rig_from` too, so the last resort was poisoned as well. Array indexing and comparisons (`_art[ZOMB_ANIM.walk]`, `case ZOMB_ANIM.walk:`) work fine with int64s - only the TYPE TEST fails, which is why the pre-roster code, which read `sprite_array[0]` directly, dressed monsters correctly.

This is [LL-034](#ll-034)'s landmine (`is_real(mus_world1)` refusing every region theme) struck again by code written AFTER that lesson existed - nobody grepped for the shape when reviewing `scr_mon_roster`. The same line also sat in `menu_blur_wanted` (`is_real(_state)` on a `MENU_STATE`), where it silently disabled the blurred backdrop on every meta screen - the `!wanted` path prints nothing, so a broken blur looks exactly like a design choice.

**Rule.**

* **Never type-test an enum or an asset constant with `is_real()`.** Enums and asset references are int64s; `is_real()` answers false for them, so the test can only ever produce a false negative ([LL-034](#ll-034)). Ask for a state's own sentinel by name (`_state == -1`), let a `switch` answer "not one of ours", and let the ASSET API judge an asset (`sprite_exists`, `audio_is_playing` - the `scr_scale_sprite` convention). In `mon_rig_pick`, the bounds checks (`is_array`, `_slot < 0`, `_slot >= array_length`) are the real guards: the slot is a compile-time constant, not data anyone can mistype.
* **Read the run log before saying "fixed".** The whole diagnosis was in the user's `debug.log` from the previous evening: `RIG   walker N ... walk=none` on all fifteen creatures, `was=spr_mon now=spr_mon` on every corpse. The `zomb-rig-roster` card's own acceptance had said "What would prove it wrong: die=none on any creature" - **the falsifier had fired and nobody looked**. Every text gate (`roundtrip`, the unittests, `gml-functions`) stayed green because they read the GML as strings, and LL-082's "dress at birth" was then layered on a roster whose every slot was -1, so it could never work and its tests passed anyway.
* **The debug log is an input, not a write-only file.** `~/GameMakerStudio2/debug.log` accumulates every run's output; the ungated lines (`RIG`, the Draw `Sprite-ind` print) are there even with `global.devMode` false, which is exactly the run the gated `META` lines are missing from.

**Files.** `scripts/scr_mon_roster/scr_mon_roster.gml` (`mon_rig_pick`), `scripts/scr_menu_blur/scr_menu_blur.gml` (`menu_blur_wanted`), `scripts/scr_music_start_level/scr_music_start_level.gml` (the LL-034 original), `python_tools/tests/test_content.py`, `~/GameMakerStudio2/debug.log` (the evidence).

**See also.** [LL-034](#ll-034), [LL-082](#ll-082), [LL-081](#ll-081), [LL-012](#ll-012)

---

<a name="ll-084"></a>
## LL-084 — The scale fix measured transparent part canvases, so the Spriter zombies looked squat

**Look for.** Rigged zombies look too short or squat after the SCML scale fix, even though every creature has a valid Spriter player and the fix is meant to match the old walk-sheet height.

**Cause.** `get_part_world()` reports each part sprite's full canvas `width` and `height` (`sprite_get_width/height`), and the normalizer treated those rectangles as centered on the joint. Imported part images carry large transparent margins: Grumble-Mulch's `pelvis_art`, for example, is a 94×103 canvas with an automatic painted bbox at x=3..88, y=58..99. Counting that padding inflates the measured rig footprint, so `sheet_height / rig_height` produces a scale that's too small for the visible pixels.

**Rule.**

* For these one-frame Spriter part sprites, measure `sprite_get_bbox_*()` and transform the painted rectangle from the part's actual SCML pivot through its sampled scale and angle. Do not use the full canvas as the visible bounds, and do not treat a joint pivot as the rectangle centre.
* Keep the resulting scale uniform on the whole rig. That preserves authored proportions while matching the visible art height to the legacy walk sheet.
* Compare the measured `rig=` height and `fix=` in `META [SCML] normalize` with the on-screen creature. A plausible number is not proof that the pixels being measured are the pixels being drawn. Pass explicit root coordinates to `zomb_scml_part_alpha_bounds`: (0, 0) for the scratch scale probe, and the monster's room position for its live bounds.

**Files.** `scripts/scr_scml_rig/scr_scml_rig.gml`, `scripts/scr_scml_spriter_interface_system/scr_scml_spriter_interface_system.gml`, `sprites/spr_scmlsi_5173b77a_pelvis_art_237feb3a/spr_scmlsi_5173b77a_pelvis_art_237feb3a.yy`.

**See also.** [LL-078](#ll-078), [LL-071](#ll-071), [LL-012](#ll-012)

---

<a name="ll-085"></a>
## LL-085 — Upright zombie legs belong in the authored animation data

**Look for.** A rigged zombie keeps a crouched silhouette even though its scale matches the older walk sheet; the walk clip's knees remain visibly folded.

**Cause.** The imported animation keys themselves carried that posture. A runtime angle clamp rewrote leg and foot keys after loading, which could distort the stride and duplicate work that belongs in the animation source.

**Rule.**

* Raise the pelvis and author straight standing knees in the SCML animation, then regenerate and update the managed animation package.
* Remove temporary runtime leg-key mutation once the package contains the corrected poses. Keep animation playback and sprite-size normalization separate from posture authoring.
* When the generated runtime changes its public API, update project adapters at their call sites. Preserve a bulk read-only pose snapshot when draw-time bounds depend on a single linear scan.
* Preserve existing sprite metadata when packaged images are unchanged. Some generated package exports contain full-canvas bbox placeholders even though the project has tighter alpha bounds.

**Files.** `scripts/scr_scml_rig/scr_scml_rig.gml`, `scripts/scr_scml_spriter_interface_system/scr_scml_spriter_interface_system.gml`, `scripts/scr_scml_spriter_interface_system/Spriter_Interface_System.md`.

**See also.** [LL-084](#ll-084), [LL-098](#ll-098), [LL-096](#ll-096)

<a name="ll-086"></a>
## LL-086 — The meta bar introduced every currency on a fresh save, before the player could earn them

**Look for.** A first-time player sees Seeds, Clovers, Blood Shards, and Candy all displayed as zero on the world map and Deploy screens before completing a stage.

**Cause.** `meta_currency_items()` returned every account balance unconditionally. The HUD was correct about the numbers but ignored `goal.md` §27.5's staged introduction: campaign rewards begin on the first clear, and Blood/Candy begin on the first shard.

**Rule.** Reveal Seeds and Clovers after a saved campaign clear; reveal Shards and Candy after a shard is earned or the player has made a permanent Blood/Candy purchase. Derive visibility from saved progression so spending a balance back to zero does not make an already introduced system disappear. Keep in-run Money and Lives on the stage HUD.

**Files.** `scripts/scr_meta_screen/scr_meta_screen.gml`, `goal.md` §27.5.

**See also.** [LL-050](#ll-050), [LL-015](#ll-015)

---

<a name="ll-087"></a>
## LL-087 — The late-region balance sim started every tower at level 1 and ignored permanent clover progression

**Look for.** A late-region stage appears impossible in the headless sim even though the campaign grants mastery, tower bonuses, more money, extra lives, or leak protection.

**Cause.** `model.resolve()` always built its `Scene` at Mastery 0 with zero clover bonuses. The planner therefore deployed at L1, priced rungs against the wrong cap, and ignored persisted offense, economy, and vitality upgrades while measuring a region whose difficulty assumes those upgrades are reachable.

**Rule.** Keep a fresh-save default, but thread explicit mastery and every combat/economy clover bonus through scene resolution, rung pricing, greedy planning, the time-step sim, fit/gate scenarios and the CLI. Bound inputs to what the trees can grant, and print them with results. Mastery raises floor and cap together; the planner must still have the same four money-bought rungs.

**Files.** `python_tools/gm/balance/{model,policy,sim,report}.py`, `python_tools/gm/cli.py`, `python_tools/tests/test_balance.py`.

**See also.** [LL-038](#ll-038), [LL-040](#ll-040), [LL-042](#ll-042), [LL-048](#ll-048)

---

<a name="ll-088"></a>
## LL-088 — Leak loss was inverted, and raw leaks differ from lives lost

**Look for.** An ordinary leak costs no life in a fresh garden, or 25% Vitality prevents three out of four lives; a progressed run's life total may also differ from its raw leak count.

**Cause.** `lose_life` and the simulator accumulated the prevention bonus as life loss. With no bonus, the carry stayed at zero; at 25%, it accumulated only 0.25 per leak, reversing the intended effect. Vitality can also save boss leaks and restores lives every fifth cleared wave. Raw leak count is still useful for badges, but is not the same as lives lost. The leak payout calls `scr_kill_money` with the raw creature payout at half scale; it does not pass the clover kill-money or boss-reward bonuses used by `scr_zomb_death`.

**Rule.** Accumulate `1 - prevention` as the fraction of a life actually lost, then carry the remainder; zero prevention costs one life per leak and 25% prevention costs three lives per four leaks. Boss saves skip that loss. Report actual life balance separately from raw leak count, regenerate after each fifth cleared wave, and update ending lives after regeneration. Keep leak payouts on the raw half-value path unless the GML caller passes kill bonuses.

**Files.** `scripts/lose_life/lose_life.gml`, `scripts/scr_level_wait/scr_level_wait.gml`, `scripts/scr_zomb_death/scr_zomb_death.gml`, `python_tools/gm/balance/{sim,report}.py`, `python_tools/tests/test_balance.py`.

**See also.** [LL-042](#ll-042), [LL-087](#ll-087)

---

<a name="ll-089"></a>
## LL-089 — A range Candy changed the tower's reach but left its light behind

**Look for.** Jawbreaker increases a tower's effective firing radius, but its light-map radius remains at the placement or previous-upgrade size; it also stays stale when the Candy expires.

**Cause.** `candy_reapply_towers()` rebuilt each tower's stat array, while the separate `_light` instance kept the scale last assigned at placement, upgrade, or wave-modifier change. Targeting read the rebuilt range, so combat could be correct while the visible/revealed area was wrong.

**Rule.** Whenever an active effect rebuilds tower range, refresh the tower range lights after the new data is assigned. Check both activation and expiry, and ensure the radius returns to baseline.

**Files.** `scripts/scr_candy_system/scr_candy_system.gml`, `scripts/tower_levels/tower_levels.gml`, `objects/obj_tower/Alarm_0.gml`.


<a name="ll-090"></a>
## LL-090 — Active Candy timers covered the speed controls, while Blood Orange pity covered the stage stats

**Look for.** The Candy countdown panel starts at the upper-left over the speed buttons, or the Blood Orange pity line is hidden by the upper-right stat inventory. The full Candy panel can reach 250 px tall when every recipe is active.

**Cause.** Candy drew from hard-coded screen corners instead of the named HUD layout, and its pity readout had a separate hard-coded corner. Neither rectangle reserved space against the other HUD elements or the panel's maximum content.

**Rule.** Anchor the active Candy panel through a named flex node, reserve its maximum height clear of speed, weather, stats, tower card, and Endless HUD, and draw pity progress inside the same panel. Keep the layout check's node count and the Candy runtime acceptance criteria in sync.

**Files.** `scripts/scr_candy_system/scr_candy_system.gml`, `scripts/scr_ui_layout_hud/scr_ui_layout_hud.gml`, `objects/_levelControl/Draw_64.gml`.

---

<a name="ll-091"></a>
## LL-091 — Region base seeds undercount the stage-row economy

**Look for.** Campaign seed totals such as 620 Normal / 3,100 Brutal, or claims that a tower is purchasable after reaching its seed cost even though its region gate is still closed.

**Cause.** `region_data` stores a base seed value, but `stage_data` applies a ten-stage ladder: `B, B, B, B+1, B+1, B+1, B+2, B+2, B+2, B+5`. Multiplying only the regional base by ten undercounts all six regions. Also, first-clear seeds can reach 25 before the Region 1 boss clears `region_cleared(1)`, so affordability and unlock availability are separate conditions.

**Rule.** Sum the authored `stage_row.seeds` values, apply the selected difficulty multiplier, and floor each repeat award per stage. For purchase timing, check both the seed balance and the tower's region gate; a threshold reached early does not bypass `region_cleared`.

**Files.** `scripts/region_data/region_data.gml`, `scripts/stage_data/stage_data.gml`, `scripts/scr_meta_progress/scr_meta_progress.gml`, `scripts/scr_meta_unlock/scr_meta_unlock.gml`, `python_tools/gm/balance/tables.py`, `economy.md`, `goal.md`.

**See also.** [LL-021](#ll-021), [LL-038](#ll-038), [LL-042](#ll-042)

---
<a name="ll-092"></a>
## LL-092 — The balance sim ended waves before their corpses finished dying

**Look for.** The sim starts its between-wave gate and pauses Candy timers on the last kill, but GameMaker continues the wave through the DIE animation.

**Cause.** The sim removed a monster as soon as its life reached zero. In the game, `scr_zomb_death()` settles the kill and requests `ZOMB_STATE.DIE`; the `obj_mon` remains until `scr_zombie_die()` sees the non-looping sheet or SCML clip end. Both paths use `ZOMB_DIE_SECS`. `scr_level_wait()` starts the 354-frame clear gate only when `instance_number(obj_mon) == 0`, and `candy_run_wave_end()` is called at that same boundary.

**Rule.** Settle money, damage, and kill effects immediately, but keep killed monsters as non-targetable corpses for the source-backed DIE duration. Start the clear gate and stop Candy ticking only after no live monsters or corpses remain. Leaks still remove monsters immediately.

**Files.** `python_tools/gm/balance/{tables,sim}.py`, `scripts/scr_zomb_art/scr_zomb_art.gml`, `scripts/scr_zombie_die/scr_zombie_die.gml`, `scripts/scr_level_wait/scr_level_wait.gml`, `scripts/scr_candy_system/scr_candy_system.gml`.

**See also.** [LL-079](#ll-079), [LL-080](#ll-080), [LL-087](#ll-087)


---
<a name="ll-093"></a>
## LL-093 — Seeds stayed inert after the roster was complete, and box conversion started early

**Look for.** The tower shop is fully owned but Seeds keep accumulating with no use, or an Endless Seed offer turns into two Clovers before the permanent upgrades are capped.

**Cause.** The seed award path only incremented the saved balance, and an existing save could keep its old Seed balance until another reward arrived. Endless boxes separately used tower ownership as the trigger for the much stronger 1:2 exchange, although the economy reserves that exchange for a fully capped garden.

**Rule.** On load and after the final tower unlock, convert each complete 20-seed group into one Clover; apply the same rule to every later Seed reward and preserve a remainder under 20. Convert Endless box Seeds at 1:2 only after the whole permanent garden is capped; show the actual 20:1 result and remainder before the choice.

**Files.** `scripts/initialize_game/initialize_game.gml`, `scripts/scr_meta_seeds/scr_meta_seeds.gml`, `scripts/scr_meta_unlock/scr_meta_unlock.gml`, `scripts/scr_endless_mode/scr_endless_mode.gml`, `scripts/scr_ui_text/scr_ui_text.gml`, `economy.md` §2.3 and §7.4.

**See also.** [LL-061](#ll-061), [LL-091](#ll-091)

---
<a name="ll-094"></a>
## LL-094 — A local identifier collided with a GameMaker object resource

**Look for.** `gm-cli compile` reports `Cannot set a constant ("_score") to a value` and malformed assignment at a comma in a `var` declaration, even though the local declaration looks valid.

**Cause.** The project contains an object resource named `_score`. GML resolves that identifier as an asset constant, so assigning the local variable with the same name fails compilation.

**Rule.** Avoid local names that match project asset names; use a distinct semantic name such as `_run_score`. Use `gm-cli compile` to catch compiler errors that function enumeration and text-based checks cannot detect.

**Files.** `scripts/scr_endless_mode/scr_endless_mode.gml`, `objects/_score/_score.yy`.

**See also.** [LL-005](#ll-005)

---
<a name="ll-095"></a>
## LL-095 — A local declared at state entry does not survive the next Step call

**Look for.** `local variable _spec_key(...) not set before reading it` in `scr_tower_shoot` on the strike frame, even though the variable was assigned when the swing began.

**Cause.** `scr_tower_shoot` runs again on every Step. `_spec_key` was declared only inside `if(state_time == 0)`, so the next invocation had no local value when the delayed hit and signature callbacks read it.

**Rule.** Any shot data needed across frames belongs on the tower instance: initialize it in Create, capture it when the shot starts, and read that persistent field on later frames. A local lasts only for its function invocation.

**Files.** `scripts/scr_tower_shoot/scr_tower_shoot.gml`, `objects/obj_tower/Create_0.gml`.

**See also.** [LL-003](#ll-003), [LL-054](#ll-054), [LL-062](#ll-062)

---
<a name="ll-096"></a>
## LL-096 — Rig bounds rescanned every part for each part, in the draw and shadow hot paths

**Look for.** A frame-rate drop with Spriter monsters, and the profiler shows `obj_mon` drawing or `_shadows_Draw_0` high. Bounds code loops every part name and calls `get_part_world()`, which itself scans the whole pose array; the tint shader also runs on rigs with no active tint.

**Cause.** Each rig bounds pass performed N linear searches over N pose entries (quadratic work), cloned each matching pose, and queried the same static sprite alpha box every frame. Every untinted rig also switched to the custom tint shader and back. `obj_mon` inherits `_shadow`, so the bounds work feeds both the HP bar and the recurring shadow pass.

**Rule.** Expose a read-only bulk pose view and scan active parts once. Cache immutable sprite alpha boxes by sprite id, use the stable sampled walk envelope for HP bars, and keep current-pose bounds for shadows. Keep the custom status shader off when the tint is white while restoring the default draw state.

**Files.** `scripts/scr_scml_rig/scr_scml_rig.gml`, `scripts/scr_scml_spriter_interface_system/scr_scml_spriter_interface_system.gml`, `scripts/scr_scml_spriter_interface_system/Spriter_Interface_System.md`, `objects/obj_mon/obj_mon.yy`.

**See also.** [LL-071](#ll-071), [LL-084](#ll-084)

---
<a name="ll-097"></a>
## LL-097 — Room creation did fifteen Spriter preloads before the first loading-screen Draw

**Look for.** Entering a stage appears frozen before the loading screen can draw. The GameMaker profile attributes about 15.6 ms (166.8% of a frame) to `rm_test.CreationCode`, and there is no progress update during the work.

**Cause.** `scr_level_boot()` ran `zomb_scml_reset()` from Room Creation Code, and reset synchronously described and corrected every SCML entity in one event. The existing loader then prepared terrain in Steps, but its image and bar were only shown after that earlier batch completed. Monster scale measurement also repeated a full 16-pose pass over every part using nested per-part pose searches. After moving preparation into Steps, the loading panel could still be skipped when its state check changed early or be too brief to notice.

**Rule.** Room Creation Code should only clear stale players and queue preparation. Let the main startup Step process one creature at a time, combine that count with terrain slices in the loading percentage, and show the first backdrop Draw before doing the work. Keep an explicit `load_visible` flag independent of the state method comparison, and require a short minimum display time after the work completes. The one-time `META [LEVEL] loading screen Draw GUI End` line proves that draw event ran; the screen still needs a visual check. During a scale probe, read one bulk pose snapshot and pass its scratch root explicitly. GameMaker's `room_goto` switches rooms at the end of the calling event; the engine's room transition itself is not a GML background task.

**Files.** `rooms/rm_test/RoomCreationCode.gml`, `scripts/scr_level_boot/scr_level_boot.gml`, `scripts/scr_scml_rig/scr_scml_rig.gml`, `scripts/scr_main_startup/scr_main_startup.gml`, `objects/_mainControl/Draw_75.gml`, `sprites/bck_loading`.

**See also.** [LL-049](#ll-049), [LL-084](#ll-084), [LL-096](#ll-096)

---
<a name="ll-098"></a>
## LL-098 — A 30 Hz SCML pose rate holds samples between evaluations

**Look for.** The animation clock advances smoothly, but limbs can hold their pose for two display frames when a rig is evaluated at 30 Hz on a 60 fps room.

**Cause.** The optimized runtime advances clocks and events each Step while evaluating bones and parts at the configured pose interval. The current package draws the last evaluated pose without blending, trading visual smoothness for lower evaluation cost.

**Rule.** Keep the 30 Hz rate for units where the performance headroom matters. Use full pose rate for a prominently viewed unit or one needing current attachment coordinates. Do not rewrite authored leg keys or angle spin to hide sample stepping; any later smoothing change should include a measured draw and update cost.

**Files.** `scripts/scr_scml_rig/scr_scml_rig.gml`, `scripts/scr_scml_spriter_interface_system/scr_scml_spriter_interface_system.gml`, `scripts/scr_scml_spriter_interface_system/Spriter_Interface_System.md`.

**See also.** [LL-085](#ll-085), [LL-096](#ll-096)

<a name="ll-099"></a>
## LL-099 — Zombie HP bars vibrate as the feet move, even though the zombie root follows a smooth path

**Look for.** The health bar's left, right, or bottom edge shifts with a walk cycle while the monster's path and root position are steady.

**Cause.** `obj_mon/Draw_73` anchored the bar to `zomb_scml_bounds()`, which measures the current animated pose. Arms and legs change that rectangle every sample, so the bar inherits gait motion.

**Rule.** Union the painted alpha bounds over the existing walk-pose samples during rig preparation. Transform that fixed root-relative envelope by the monster's position, facing, rotation, and current scale for the health bar. Keep current-pose bounds for shadows, which should follow the image.

**Files.** `scripts/scr_scml_rig/scr_scml_rig.gml`, `objects/obj_mon/Draw_73.gml`.

**See also.** [LL-084](#ll-084), [LL-096](#ll-096)

---
<a name="ll-100"></a>
## LL-100 — A debug print called during global initialization aborts startup

**Look for.** `Variable <unknown_object>.object_index ... not set before reading it` in `print()` while a global initialization script runs with `global.devMode = true`.

**Cause.** The project logger always read the instance-only `object_index` and `id` built-ins. A call from a global script has no object instance, so the diagnostic itself threw and stopped initialization.

**Rule.** Guard `global.devMode` before reading it. Build a global-safe log prefix by default, and read instance built-ins only after checking the current `self` scope contains them. Diagnostics must work both from object events and from global/struct scopes.

**Files.** `scripts/print/print.gml`, `scripts/scr_loadout/scr_loadout.gml`, `scripts/initialize_game/initialize_game.gml`.

**See also.** [LL-002](#ll-002), [LL-003](#ll-003)

---
<a name="ll-101"></a>
## LL-101 — A terrain override shapes a dual-grid edge but must not draw the whole higher layer

**Look for.** After switching layered terrain to dual-grid, the highest `load_max` cells appear on lower slices where the legacy renderer drew no tile for them.

**Cause.** The old renderer selected a tile from the current height band, then treated `load_max` as an occupied neighbor while building that tile's edge mask. A direct dual-grid mask treated the override as a full member of every band, so vertices surrounded only by `load_max` cells produced extra terrain.

**Rule.** In a layered dual-grid draw, require at least one cell from the active height band at each render vertex. Then include the override in that vertex's corner mask so it shapes adjacency without creating a tile by itself.

**Files.** `scripts/scr_dual_grid/scr_dual_grid.gml`, `scripts/scr_iniTileBuilder/scr_iniTileBuilder.gml`.

**See also.** [LL-081](#ll-081)

---
<a name="ll-102"></a>
## LL-102 — A struct-field check rejects a callable static method on the tile manager

**Look for.** The dual-grid draw helper returns zero tiles even though the tile manager is a valid constructor instance and exposes `add_tile` for normal terrain drawing.

**Cause.** `variable_struct_exists()` checks fields stored directly on the instance. A `static` method declared by its constructor is resolved through the constructor's static chain, so the instance-field check can reject a method that `is_callable()` can call.

**Rule.** Validate the manager as a struct, then test the method with `is_callable()`; do not require a direct instance field for a constructor's static method.

**Files.** `scripts/scr_dual_grid/scr_dual_grid.gml`, `scripts/Sprite_Layer_Manager/Sprite_Layer_Manager.gml`.

**See also.** [LL-001](#ll-001)

---
<a name="ll-103"></a>
## LL-103 — `is_real()` rejects a valid DS Grid Handle

**Look for.** `ds_exists(grid, ds_type_grid)` returns true, while a helper guarded by `is_real(grid)` returns its invalid-input sentinel; the dual-grid preflight showed `grid=1 sample_mask=-1`.

**Cause.** `ds_grid_create()` returns a DS Grid Handle, not a real-number contract. Testing its runtime representation with `is_real()` rejects a live handle before any grid cells are read.

**Rule.** Validate data-structure references with `ds_exists(reference, expected_type)`; do not add `is_real()` as a second guard on the handle.

**Files.** `scripts/scr_dual_grid/scr_dual_grid.gml`.

**See also.** [LL-034](#ll-034)

---
## Adding an entry

Use the next free `LL-0NN`, add an index row, and keep the same four fields:

```markdown
<a name="ll-0NN"></a>
## LL-0NN — the real cause, not the symptom

**Look for.** Exact error/log text and the visible symptom.
**Cause.** The mechanism that made symptom and cause look unrelated.
**Rule.** The fix or invariant that prevents a repeat.
**Files.** The paths involved.
```

Searchability is the point: include exact errors
(`Variable … not set before reading it`), log prefixes (`BTN   click`), API
names, and plain-English symptoms.
