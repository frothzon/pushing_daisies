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
| [LL-012](#ll-012) | `sprite_get_height ... requested -1` once per step; a sprite flip that "does nothing"; a tower that un-mirrors - or draws upside-down - when it is upgraded | A **text object has no sprite** (`sprite_index == -1`, fatal in GMS2) and the shared scale helper **overwrote `image_xscale`**; `image_xscale` carries size **and** facing in one number | **FIXED** |
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
| [LL-029](#ll-029) | A tower loops its **attack animation** forever and stops dealing damage; only after it has been **upgraded**; no error | A state exit gated on `state_time == frame_number`, where `frame_number = room_speed/fire_rate` is a **float** once the level ladder / clover bonus scales `fire_rate` — an integer can never equal it | **FIXED** |
| [LL-030](#ll-030) | A tower's **idle / return animation plays far too fast** after its sprite is re-drawn with fewer frames; no error, and no code was changed | Two states set **`image_speed` (a SPEED) where a duration was meant**, so the period scaled with the frame count: 5 frames at `0.25` is 20 steps, not the 60 the 15-frame art took | **FIXED** |
| [LL-031](#ll-031) | Zombies **vanish a few seconds into every wave** and the wave moves on; nothing reaches the exit, nothing is killed, and the **lives counter never moves** | A **safety valve firing on a stopwatch** (6 s after the wave's last spawn) deleted the whole wave - a stopwatch cannot tell *slow* from *stuck*, and a zombie needs 20-45 s to walk a stage | **FIXED** |
| [LL-032](#ll-032) | `gm progress` says "nothing written", and then **every** later `gm progress add` fails the same way | The gate is transactional for `set`/`add` only - a **hand edit** that points `focus` at a card that does not exist yet stays on disk and blocks every later write | **FIXED** |
| [LL-033](#ll-033) | A hand-drawn click mask "does nothing": the clickable area still hugs the artwork and is half the size it should be; and the placement ghost refuses the cell **above** an existing tower | A collision mask **scales with `image_xscale`** and `mask_index` does not exempt it - so "draw the art small" and "keep the mask fixed" were the same number; and a mask cannot answer "is this CELL taken" | **FIXED** |
| [LL-034](#ll-034) | Every stage is **silent** - no region theme, ever - while the title and world-map themes play; the log blames the track: `META  [MUSIC] region 1 "Wilted Sprouts" has no track yet - playing nothing` | **A guard asked a TYPE question about an asset**: `is_real(sound)` is **false for an asset reference** (it is not a real number, whatever the runtime calls the type) - so the guard refused a track that was there, and its message blamed the track. The menu path skips that guard, which is why only levels were silent | **FIXED** |
| [LL-035](#ll-035) | A monster **in water throws every frame**: `undefined value at gml_Script_draw_self_part (line 33) - _x = x - sprite_get_xoffset(sprite_index)*_sx`, from `obj_mon/Draw_0`'s five-argument call | The **optional argument** was detected with `argument_count`, but the function **declares seven** parameters and the call passes five, so the list is padded with `undefined` and the wrong branch was taken | **FIXED** |
| [LL-036](#ll-036) | A difficulty projection disagrees with the play - "the numbers look fine but I keep leaking" | The wave was a **BOSS wave** (`boss_every` is a cadence, not the last wave), and its creature comes from **`spawn_boss`** - ~10x the HP of the pool the projection read, with no error and no log line | **FIXED** |
| [LL-037](#ll-037) | The toolkit suite goes **red on an edit that changed no code** - `FAILED (errors=1)`, and the traceback is a `StopIteration` inside a *test* | The test built its fixture by **searching the repo's own `progress.json`** for a card that already had the property under test, so it could only pass while the board happened to have such a card | **FIXED** |
| [LL-038](#ll-038) | A projection says **`ok` while the play leaks** - and a second tool built to check it agrees, because it was written from the same formula | The supply model treated three *assumptions* as facts: that the purse can afford the best-value tower, that `targets` is always full, and that a tower projects its dps down the whole route | **FIXED** |
| [LL-039](#ll-039) | A tower's **`targets` stat does nothing** - it hits one monster however high the number, and no error ever appears | The collection loop read `array_last_index(_targets)` and then wrote at **that same index**, so the last index could never change. A list you only ever write to at its own last index does not grow | **FIXED** |
| [LL-040](#ll-040) | Every tower deals about **a third** of the dps on its card, and the shortfall is **uneven** across the roster - so the paper ranking does not match the play ranking. No error, no crash, and the balance panel still says `ok` | The **fire period was charged twice per shot**: a full `room_speed/fire_rate` wait in `scr_tower_normal` *and* a full `room_speed/fire_rate` attack in `scr_tower_shoot`, so the cycle was `2P + off + 15` and not `P` | **FIXED** |
| [LL-041](#ll-041) | A test suite stays **green while tests quietly stop existing** - the only symptom is a count that moves by less than it should | Two `GeometryTests` methods were indented four spaces inside the **`if __name__ == "__main__":` block**, so they were only defined when the file was *run* - and the discoverer **imports** it | **FIXED** |
| [LL-042](#ll-042) | **Brutal is easier than Hard.** Brutal holds with 0 leaks where Hard leaks 19, and the panel says the opposite on every wave | The difficulty money column is applied to a kill that pays **1** and *then* rounded: `round(1 x 1.25)` is still 1, so Hard's column does nothing, while `round(1 x 1.5)` is 2 and doubles Brutal's | **FIXED** |
| [LL-043](#ll-043) | Plants in water wear a **halo of themselves**, meet the surface at a different height per tower, and a left-facing one is **upside down and ~220px low** | The submerged copy was drawn at `image_xscale` (so 1.43x too big) and the waterline was a **fraction of the sprite CANVAS** - a different world depth for every sprite - while the reflection script had been ported disabled and wrong | **FIXED** |
| [LL-044](#ll-044) | The HUD's **Wave number reads one high** (wave 1 shows as 2), the level log agrees with it, and the speed ramp computes for the *next* wave - yet the pre-wave banner is right, so nothing looks broken | `STATINV.waves` was seeded at **1** while `wave_count` started at **0**, so one item carried **two meanings**: the wave being fought (HUD, log, ramp) and the wave about to spawn (banner). The banner was correct **by accident**, which is why it survived | **FIXED** |
| [LL-045](#ll-045) | Nothing at all - the feature simply does nothing, and the code for it looks complete. An outline shader that had never drawn a pixel in its life | **Ported dead code**: `shd_outline`, `scr_getOutlineShd()` and `scr_drawSelfOutlined()` all existed and nothing ever called the two scripts - and three faults were waiting inside, the worst being that `draw_self()` draws at `image_xscale` (±1 facing on a tower, [LL-033](#ll-033)) and the shader took its colour from `image_blend`, which is the sprite's TINT here | **FIXED** |
| [LL-046](#ll-046) | A ringed tower goes **see-through and blown out** the moment the ring is blended additively; or the ring's opacity changes nothing at all | **One shader pass draws whatever it is told to draw**, and a blend mode is a property of the PASS - so an additive ring pass cannot also carry the body; and `draw_set_alpha()` cannot reach a shader that writes `gl_FragColor` (the alpha it did write was a COUNT, which additive blending uses as a multiplier) | **FIXED** |
| [LL-047](#ll-047) | A label placed "above the sprite's head" lands in the middle of it (or below its feet), with the value looking plausible | **`sprite_get_bbox_top()` is measured from the sprite CANVAS, not from the origin** - while the `bbox_top` instance variable is room-relative. The offset from the origin is the DIFFERENCE, and it is negative for this project's feet-origin sprites | **FIXED** |
| [LL-048](#ll-048) | A balance model that says a stage **holds** while every tower stands on the same fifth of the map and the **last quarter of the route is never shot**; and a run of 11 towers that **never bought a single upgrade** | The greedy ranked on `dps x coverage`, and coverage was **additive** - two towers over one stretch both score it, so the objective was the SUM of per-tower coverage instead of the **UNION** of route actually covered. And it was told which CELLS were taken, never which TOWERS were standing, so a rung was invisible to it every wave | **FIXED** |
| [LL-049](#ll-049) | The **second level never loads**: the stage room comes up, walls and spawns are there, but the **ground never appears and no waves start** - and nothing errors | The whole level bootstrap hung off `Control/Create_0` (a **persistent** instance, first in the room order) creating `_mainControl`. A persistent instance keeps Room Start/Room End but **not Create**, so the second entry built nothing - while `_mainControl`, `_levelControl` and `_viewControl` are non-persistent and had already died on Room End | **FIXED** |
| [LL-050](#ll-050) | The game **resets every time**: stage progress, bought towers and clover nodes are gone after a relaunch - but seeds, clovers and the loadout are still there | **The merge looped over the DEFAULT's keys**, so every nested map (`{}` in the default) came back EMPTY with a `version` stamp inside it; only the non-structs survived - and the load log printed exactly those non-structs | **FIXED** |
| [LL-051](#ll-051) | A volume slider **does not apply until you leave Options**, and **0% / 100% take a second pass** because the mouse leaves the track | The slider read the mouse in a DRAW event, only while the pointer was inside a 32px band, `lerp`ed 25% per frame towards it, and the gain was only re-applied on RETURN | **FIXED** |
| [LL-052](#ll-052) | A tower's **shadow flips but does not follow** the tower when it turns round - it lands most of a tower-width to the side; after the origin was fixed it was still ~96px to the **right** | `scr_drawLight` built the silhouette box from **signed** values: `sprite_xoffset` AND `sprite_width` both carry the image_xscale sign, so the flip branch laid the box out on the wrong side | **FIXED** |
| [LL-053](#ll-053) | Losing every life **never reaches the new level flow** - the old arcade high-score screen takes over and nothing is saved or withheld | `LEVEL_STATE.FAILED` existed and was **never requested**; the legacy `scr_main_normal` still ran `scr_main_gameOver -> rm_score` underneath | **FIXED** |
| [LL-054](#ll-054) | A **slow-firing tower never fires at all** - the Pina Collider stands through a whole stage; the attack timer looks frozen until something is in range | The fire period was **also the animation length** (`frame_number = room_speed/fire_rate`) and the swing was **cancelled the moment the target left range** - so a 0.10/s tower needed a monster in range for 600 frames, longer than it takes to cross its range | **FIXED** |
| [LL-055](#ll-055) | A 3-second **Level Complete** hold lasts one second in fast-forward; a banner sized as "60% of the viewport" comes out at 37% or spills off the edges | A hold counted in **frames** against a `room_speed` that fast-forward sets to 180, and a banner sized from the sprite **canvas** instead of the art inside it | **FIXED** |
| [LL-056](#ll-056) | A monster HP bar draws with a **negative width** - an orange fill to the LEFT of the black bar, usually on a boss that has just died | `obj_mon/Draw_73` fed an **unclamped** `life/maxLife` to `lerp`, and `life` really does go negative: an overkill is normal, `scr_zomb_death` only runs in the path state, and the emerge reset heals it 60 steps later | **FIXED** |
| [LL-057](#ll-057) | The **Up Next popup shows the previous creature portrait** under the new creature name - read as "Tusk-A-Lot and Sub-Zero are swapped" | The portrait is stored per MESSAGE but drawn at `message_current`, and `show_message_box` **appends** to a live box, so a second preview painted message 0 - with message 0 portrait | **FIXED** |
| [LL-058](#ll-058) | The **"Up Next" popup names a creature the wave does not send**, and the mismatch looks *random* - it started on the third level | Three defects on the popup path: the portrait was per MESSAGE and drawn per `message_current`; `show_message_box` **appends**; and the preview box was destroyed and re-created in the same step. Plus a silent re-roll fallback in `scr_level_spawn`. Stage 1-3 is the first stage with **two** creatures in its pool, which is why a bug from wave 1 became visible there | **FIXED** |
| [LL-059](#ll-059) | Zombies draw **over plants they stand behind**, and two crossing monsters swap order | There was no sorting: monsters were a flat `-60` (in three places), plants `-60 - (y>>5)` (always in front) and the six gravestones one flat value from a fraction of the room. Three formulas cannot make one draw order | **FIXED** |
| [LL-060](#ll-060) | The **boss rule disagreed with itself** - play rolled one on a `boss_every` cadence, the curve projected wave 10, the tester encoded it again | The rule lived in four readers as a copied *condition*, so changing it left every copy silently authoritative. Now one authored `[mid, end]` pair and one derived `boss_wave` (`waves div 2`) that play, the curve and the tester all read | **FIXED** |
| [LL-061](#ll-061) | "A leak pays half instead of nothing" changed the purse by **1 money over 20 leaks** | `floor(kill_money * 0.5)` is `0` when `kill_money` is `1`: the percentage was applied AFTER the rounding, so it erased the only value that mattered | **FIXED** |
| [LL-062](#ll-062) | **Crit could not be added** - the damage function had no amount to multiply | `scr_do_damage(arr, i)` subtracted `damage_calc`, an instance variable the CALLER set, so its result depended on whose scope called it (AGENTS rule 6). Now the amount is a parameter and the tower passes the `shot_damage` it locked at the swing | **FIXED** |
| [LL-063](#ll-063) | **A test changed colour with no edit** - it asserted a LINE, and the IDE re-saved an equivalent one | `assertIn("id mod 97", src)` vs the code's `irandom(97) * 0.00001`, after GameMaker wrote `.gml` + `.yy` in the same millisecond. Test the PROPERTY (rolled once, too small to reorder); on an unexplained red, check mtimes before theories | **FIXED** |
| [LL-065](#ll-065) | Monsters **vanish ~5 s after being stunned**, and the stage loses Exterminator | The LL-031 safety valve fires on "`path_position` has not moved", which a stun produces ON PURPOSE. A held monster is not a stuck one: the counter now only runs while `status_speed_mult() > 0` | **FIXED** |
| [LL-064](#ll-064) | The **music fades out in the middle of a stage**, and the menu goes quiet every ~3 minutes - no error, and the track is still "playing" | The loop had **one end**: `loop_in` was the chorus start and the loop ran to END OF FILE, so every cycle played the outro fade. The menu did not set loop points at all, so it was worse there. A loop **section** has two ends | **FIXED** |


Tags for searching: `button` `menu` `array` `noone` `scope` `state machine`
`enum` `crlf` `room_speed` `built-in` `shadowing` `null` `log` `debug`
`flip` `image_xscale` `sprite_index` `sprite_get_width` `-1` `_text_rise`
`facing` `mirror` `image_yscale` `draw_sprite_pos` `shadow` `orientation` `sign`
`wave` `valve` `safety valve` `stuck` `soft-lock` `path_position` `life` `leak` `timer`
`soft-lock` `path` `mp_grid_path` `return value` `pocket` `black` `pause`
`off-by-one` `wave_count` `STATINV.waves` `counter` `seed` `wave number`
`shader` `outline` `shader_set` `shader_reset` `uniform` `draw_self` `draw_scale`
`dead code` `image_blend` `make_colour_rgb` `$BBGGRR` `shader_is_compiled`
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
`tower` `attack animation` `stuck` `freeze` `frame_number` `fire_rate` `scaled cadence` `state exit` `equality` `float`
`animation` `image_speed` `image_number` `sprite_get_number` `frames per second` `sprite swap` `duration not speed` `idle loop` `image_single`
`music` `audio` `region music` `loop points` `chorus` `loop_in` `loop_out` `outro` `intro` `fade` `music fades out` `menu theme` `music_data`
`focus` `progress.json` `pointer field` `gate is not a transaction` `write order` `two tracks at once`
`collision mask` `mask_index` `image_xscale` `bbox` `bbox_left` `draw_sprite_ext` `draw_scale` `sprite_width` `sprite_offset`
`is_real` `asset` `handle` `ref` `typeof` `audio` `music` `silent` `mus_world1`
`has no track yet` `guard` `false negative` `region music`
`argument_count` `optional argument` `argument5` `undefined value` `declared parameters`
`draw_self_part` `in water` `pad with undefined` `is_undefined` `variadic`
`boss_every` `boss wave` `spawn_boss` `spawn_mon` `two banks` `cadence not the last wave` `MAX = 1`
`curve` `ceiling` `curve_end` `bite` `projection disagrees with the play` `reachable ground` `slots` `coverage ceiling`
`test` `fixture` `StopIteration` `next()` `live data` `gate depends on data` `unittest` `fragile gate` `empty generator`
`projection` `bite` `nominal dps` `targets` `coverage` `the panel says ok while the play leaks` `affordability` `bankers rounding`
`array_last_index` `index never advanced` `dead stat` `find_all_range` `single-target` `list never grows` `silent no-op` `targets`
`fire_rate` `fire cycle` `cycle length` `2P + off + 15` `time_offset` `idle wait` `double-counted period` `stopwatch` `nominal vs delivered dps` `roster order`
`test count` `if __name__` `indentation is semantic` `dead test` `silent no-op` `suite is green` `has this ever run`
`difficulty_money_mult` `round after scale` `step function` `kill_money 1` `hp per dollar` `brutal easier than hard` `a ratio cannot see it`
`additive blending` `bm_add` `gpu_set_blendmode` `blend mode is per pass` `draw_set_alpha`
`gl_FragColor.a` `count not an opacity` `min(x,1.0)` `ring only` `two draws` `25% 75%`
`outlineColor.a` `shader_set_uniform_color` `vec4 uniform` `leaked blend mode`
`bbox_top` `sprite_get_bbox_top` `canvas vs origin` `yoffset` `anchor a label` `above the head`
`newline ends a statement` `unclosed bracket` `draw_text_outline` `draw_rectangle` `bm_add`
`hover` `grid cell` `cell highlight` `tower_hovered` `which cell is this`

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

**Three more ways a flip dies — all three appeared at once when the towers
learned to face their target (2026-10-11).**

1. **A scale tween that re-derives `image_xscale` un-mirrors the instance.**
   The tower's upgrade tween wrote `image_xscale = lerp(0.25,0.70,_frac)` — a
   bare positive value — so a tower that had turned to face a monster on its
   left span back to the right the moment it was upgraded. Keep the sign:

   ```gml
   var _tower_scale = lerp(0.25,0.70,_frac);
   image_xscale = _tower_scale * (image_xscale < 0 ? -1 : 1);
   ```
2. **`image_yscale = image_xscale` propagates the SIGN, not the size.** The
   same tween read `image_yscale = tower_selection.image_xscale`. That was
   harmless only while `image_xscale` was always positive. Once a tower can
   face left it writes a **negative `image_yscale`**, which draws the tower
   **upside-down** — a bug that looks nothing like a flip. Write the
   magnitude into both axes, then the sign into x only.
3. **Anything else that reads the sprite has to respect the sign.** The shadow
   silhouette (`scr_drawLight`) is built from `sprite_width` /
   `sprite_xoffset`, which ignore `image_xscale`, so a mirrored tower (and a
   mirrored monster) cast a silhouette facing the wrong way.
   `draw_sprite_pos` takes its corners clockwise from the **top left**, so
   mirroring it is swapping the two left/right x's — and the *sun's* shear
   offset must not be swapped with them.

The rule under all three: **`image_xscale` is two pieces of information in one
number — magnitude (size) and sign (facing).** Every writer must preserve the
half it is not setting, and every reader that cares about orientation must
look at the sign.

**Guard rails.**

* **A helper that reads `sprite_index` must survive `sprite_index == -1`** —
  test `sprite_exists()` (or `< 0`) before any `sprite_get_*`, and treat "no
  sprite" as "nothing to scale", never as a 0×0 sprite.
* **Before blaming a flip, find what re-derives the scale every step** —
  `scr_scale_sprite`, `scr_scaleButton` or a `lerp` scale tween overwrites
  `image_xscale` on every call.
* An object with no sprite has no mask, so `place_meeting()`,
  `position_meeting()` and `bbox_*` are dead code in it.
* **When you add a flip, grep both sides of it**: every *writer* of
  `image_xscale` on that object (a `lerp` tween, `scr_scale_sprite`, a
  "reset the scale" line — each will eat the flip or invert it), and every
  *reader* (`draw_self_part`, `scr_drawLight`, `scr_drawReflections`,
  `sprite_width`-based click boxes).

**Status.** FIXED, 2026-10-03; extended 2026-10-11 (towers mirror to face
their target).

**Files.** `scripts/scr_scale_sprite/scr_scale_sprite.gml`;
`objects/_text_rise/Step_0.gml` line 20 (now a harmless no-op);
`objects/_text_rise/_text_rise.yy` (`spriteId` is `null`).

Added by the 2026-10-11 extension: `scripts/scr_tower_faceTarget/`
`scr_tower_faceTarget.gml` (new), `objects/obj_tower/Step_0.gml`,
`objects/_levelControl/Step_0.gml`, `scripts/scr_drawLight/scr_drawLight.gml`.

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
* **A card that says "nothing exists" is a claim about the repo, and the repo can
  answer it in one command.** `art-belladonna-trio` said *"Belladonna has NOTHING —
  a tower with `sprite_index -1` is a fatal error"* for four days while
  `spr_bella_idle_192x`, `_attack_` and `_return_` sat in `sprites/` (added
  2026-10-12, card written 2026-10-15). The card had been written from the roster
  table rather than from the folder. Before acting on a "missing" card — or on its
  opposite, "this exists, so that is blocked" — run the one search: `ls sprites |
  grep bella`, `grep -rn 'spr_bella' --include=*.gml`. Two seconds, and it either
  promotes the card to done or turns it into a code card.

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

<a name="ll-029"></a>
## LL-029 — Never exit a state on equality with a value another system can scale

**Symptom.** Some towers freeze mid-fight, stuck looping their **attack
animation**, and they stop dealing damage. It is not every tower and not every
session; the ones that freeze are the ones that have been **upgraded** (or placed
on a garden with a fire-rate / mastery bonus). There is **no error in the log** —
the tower simply never changes back to idle.

**Root cause.** `scr_tower_shoot` left the attack state on an exact test:

```gml
frame_number = room_speed/data[TOWER.fire_rate];   /// a FLOAT
...
if(state_time == frame_number){ scr_changeState(scr_tower_return); }
```

`state_time` is an integer (0, 1, 2, …). `fire_rate` is scaled fractionally by the
level ladder — `tower_data_at_level()` multiplies it by `tower_level_firerate()`,
which is `1.04, 1.08, 1.12, …` above L1 — and by the clover bonus, and placement
folds in the garden floor. So at L2 a base 3/s tower is `3.12/s`, and
`60 / 3.12 = 19.2308…`. An integer can never equal `19.2308`, so the return line
never ran: the tower re-entered the attack state every frame, looped the sprite
and stopped firing. The L1 row is `1.00`, which is why a fresh tower is fine and
an upgraded one is not — the bug arrives one upgrade later.

**Fix.** Exit on `>=`, and fire each one-shot beat once:

```gml
var _rate = data[TOWER.fire_rate];
frame_number  = (_rate > 0) ? room_speed/_rate : room_speed;
fire_frame    = max(1, floor(frame_number - time_offset));
...
if(!did_damage && state_time >= fire_frame){ for_array(target,scr_do_damage); did_damage = true; }
if(state_time >= frame_number){ scr_changeState(scr_tower_return); }
```

The same change re-checks the target list every frame, so a target that dies (or
leaves range) mid-swing returns the tower to idle instead of leaving it swinging
at a corpse.

**Guard rails.**
* **Never gate a state exit on `==` against a value another system scales.** Use
  `>=` (or an animation counter). The fractional multiplier lives in a *different*
  file (`tower_levels.gml`), so this looks like a tower bug when it is really a
  coupling bug.
* **A `time == N` beat that fires once needs a one-shot flag** if you relax the
  test to `>=`, or it fires on every frame from `N` onward.
* **`floor()`d comparisons are safe; raw floats are not.** The damage beat had
  used `floor(frame_number - time_offset)` and was fine — the exit did not, and
  that asymmetry is the tell.
* **When a state machine "hangs", suspect a test that can never be true** before
  suspecting the log: there was no error, because nothing threw.

**Status.** FIXED, 2026-10-10.

**Files.** `scripts/scr_tower_shoot/scr_tower_shoot.gml`,
`scripts/tower_levels/tower_levels.gml`.

---

<a name="ll-030"></a>
## LL-030 — An animation timed with a SPEED instead of a DURATION

**Symptom.** The Daisy Pusher's **idle loop and its return-to-idle swing play
about three times too fast** once its art is replaced with a shorter sprite.
Nothing is in the log, there is no error, and no code changed — only the sprite
in the roster entry did. The other three towers are fine, because their art is
still the old 15-frame trio.

**Root cause.** Two of the three tower states set `image_speed`, which is a
**rate**, where what they meant was a **length of time**:

```gml
image_speed = 0.25;   /// scr_tower_normal, the idle loop
image_speed = 1;      /// scr_tower_return, the return
```

`image_speed` is frames per step (a multiplier of the sprite's own declared
speed), so the period it produces depends entirely on how many frames the sprite
happens to have. The old trio was **15 frames**; the new daisy trio is **5**:

| state | before (15 frames) | after the 5-frame swap |
| --- | --- | --- |
| idle, `image_speed = 0.25` | 15 ÷ 0.25 = **60 steps** (1 s @ 60 fps) | 5 ÷ 0.25 = **20 steps** |
| return, `image_speed = 1` | 15 ÷ 1.0 = **15 steps** (0.25 s) | 5 ÷ 1.0 = **5 steps** |
| attack, `image_number/frame_number` | 15 over `frame_number` steps | 5 over `frame_number` steps — **already correct**, because it divides by a duration |

The attack state was accidentally right and the two hard-coded ones were wrong,
which is exactly why this reads as "the new sprite is broken" rather than "two
lines were written in the wrong unit". It is the same *shape* of bug as
[LL-029](#ll-029).

**Fix.** Ask for a **period in steps** and derive the speed from the frame count:

```gml
image_speed = scr_animSpeedForSteps(sprite, 60);   /// 5 frames -> 0.0833  15 frames -> 0.25
```

* `scr_animSpeedForSteps(sprite, steps)` returns `(frames / steps) / declared_speed`
  — the multiplier that makes one pass of the animation span `steps` steps whatever
  the frame count. It normalises the sprite's declared speed first, because a
  sprite may declare **frames per second** or **frames per game frame**
  (`sprite_get_speed_type`), and `image_speed` multiplies whichever it is.
* `scr_tower_animSpeed(slot, steps)` is the ONE place a tower's playback speed is
  set: it looks the sprite up in `sprite_list` (now indexed by the `TOWER_ANIM`
  enum) and logs the period once per animation per tower.
* The durations live with the sprites, as `anim_seconds` in
  `objects/obj_tower/Create_0.gml` (`1.00` s idle, `0.25` s return; the attack's
  length is the fire rate, so `scr_tower_shoot` supplies it).
* The return state's exit became a **time** test (`state_time >= anim_steps`)
  because its length is now a number of steps — the old
  `image_index >= image_number-1` fires up to a frame early once the speed is
  fractional, and it exits on a value the frame count scales (LL-029).

**Guard rails.**

* **If a timing must not change when the art changes, store a DURATION, not a
  speed.** Never hard-code `image_speed`; derive it from `sprite_get_number()`.
  `image_number` *is* the frame count, so "the same period whatever the frames" is
  one division.
* **`image_speed` is a multiplier, not frames-per-step.** It only looked like
  frames-per-step here because every sprite declares 1 frame per game frame. Check
  `sprite_get_speed_type()`, or a sprite that declares FPS will silently change
  period with the game's frame rate.
* **A sprite swap is a behaviour change.** When art is replaced, grep for
  `image_number` / `image_index` / `image_speed`, and for every state exit gated
  on the animation having finished.
* **Prefer `state_time >= duration`** over "has the animation finished" tests.
* **`image_single` is GM8 and does not exist in GMS2** — `obj_tower_edit`'s
  placement ghost had been animating at the sprite's default speed since the
  conversion. The GMS2 equivalent of "hold a frame" is
  `image_index = 0; image_speed = 0;`.

**Status.** FIXED, 2026-10-11.

**Files.** `scripts/scr_animSpeedForSteps/scr_animSpeedForSteps.gml` (new),
`scripts/scr_tower_animSpeed/scr_tower_animSpeed.gml` (new),
`scripts/scr_tower_normal/scr_tower_normal.gml`,
`scripts/scr_tower_return/scr_tower_return.gml`,
`scripts/scr_tower_shoot/scr_tower_shoot.gml`,
`objects/obj_tower/Create_0.gml`, `objects/obj_tower_edit/Create_0.gml`,
`scripts/tower_enums/tower_enums.gml`.

---

<a name="ll-031"></a>
## LL-031 — A safety valve that fires on a stopwatch cannot tell **slow** from **stuck**, so the net becomes the normal path

**Symptom.** Run a wave with no towers (or with the towers simply out of range)
and the zombies **vanish a few seconds in**, every wave, and the next wave
starts. Nothing was killed, nothing reached the exit, and the **lives counter
never moves** — so the whole *leak -> -1 life -> game over* mechanic silently
disappears. A stage can be "cleared" having killed nothing, and `Untouched` is
still awarded. The only clue is one line:

```text
META  [PATH] WARNING: 5 monster(s) still alive 6s past the wave - forcing the wave to end so the stage cannot hang
```

**Root cause.** `scripts/scr_level_wait` carried the anti-soft-lock valve that
`roadmap.md` 4.4.1 asked for, and it fired on **elapsed time since the wave's
last spawn**:

```gml
if(wait_stuck == _fps * 6){
    level_forced = true;
    with(obj_mon){ instance_destroy(); }   /// every live monster
}
```

Time since spawn cannot tell a monster that is **walking** from one that is
**stuck**, and the walk is slow: `scr_zomb_pathSpeed` puts
`path_speed = ((12-z_climb)/12)*1.5 + 0.5` times the monster's speed at roughly
**0.75 pixels per step** (`path_start(myPath,1,0,true)` passes an *absolute*
speed), so a zombie needs about **20-45 s** to cross a stage. Six seconds was
never a net under the wave — it was the *end* of the wave.

Because they were deleted mid-route, `scr_zomb_updatePosition`'s two arrival
tests (`point_in_circle(path_loc...)`, `path_position >= 1`) never ran, so
`lose_life()` never fired; `level_leaked` stayed `0`; the stage reached
`wave_count >= _row.waves`; `scr_level_clear()` paid seeds and clovers. The one
mechanic the fix was meant to leave alone was the one it removed.

Three things hid it: the valve logged under `PATH` (which reads like pathing
noise), the **leak path printed nothing at all**, and the mechanic it discarded
is written down nowhere.

**Fix.** The valve fires on **evidence about the monster**, and only for the
monster that is the evidence — a path follower that has not advanced:

```gml
/// scr_zomb_updatePosition - the path FOLLOWER's own progress, not a guess
if(path_position == path_pos_last){
    stuck_frames++;
} else {
    stuck_frames = 0;
}
path_pos_last = path_position;
```

```gml
/// scr_level_wait - five seconds of provable stillness clears ONE monster,
/// and the wave itself is untouched: it still ends only when the field is empty
var _limit  = _fps * 5,
    _before = instance_number(obj_mon),
    _stuck  = 0;
/// BACKWARDS: instance_find indexes shift as instances are destroyed,
/// and instance_number() itself only updates at the end of the step
for(var _i = _before - 1; _i >= 0; _i--){
    var _m = instance_find(obj_mon, _i);
    if(!instance_exists(_m)) continue;
    if(!variable_instance_exists(_m, "stuck_frames")) continue;
    if(_m.stuck_frames < _limit) continue;
    scr_meta_log("PATH", "WARNING: monster ", _m.id, " stuck at ", ...);
    instance_destroy(_m);
    _stuck++;
}
```

* **`path_position`, not `x/y`.** An instance whose path has been thrown away
  can still *drift* in `x/y` — in [LL-025](#ll-025) an unbalanced draw offset
  marched a zombie north through every wall, every frame — so a movement test
  would have called that monster "walking". A frozen `path_position` means no
  follower is driving it at all. It also needs no epsilon: the smallest real
  advance is `0.125 px/step / path length` (~2e-5), and a stalled follower is
  bit-identical.
* **`==` is correct *here***: both sides are reads of the **same stored float**,
  so equality means the follower did not write it this step. [LL-029](#ll-029) is
  the opposite case — `==` against a value *derived* from a moving quantity.
* **Five seconds, not two**: `obj_mon/Alarm_0` legitimately needs up to ~2 s to
  escalate before it takes the tower-ignoring escape grid, and a monster being
  rescued must not be deleted for being rescued.
* **A ten-minute per-wave latch** (`wait_valve_fired`, `>=`) keeps roadmap
  4.4.1's promise for a monster that never stops moving *and* never arrives.
  `>=` plus a one-shot flag, never `==`: the frame budget is read from the FPS
  setting, which can change mid-wave, and the old `== _fps * 6` is a valve that
  silently never opens the moment that value moves.
* **Every fate is now labelled exactly once** — `kill` (`scr_zomb_death`),
  `leak` (`lose_life`), `valve` (`scr_level_wait`) — plus one line per monster,
  `path 1408px @ 0.75px/step = ~1877 steps (~31s to the despawn)`, which is where
  a future threshold must be *derived* from rather than guessed.

**Guard rails.**

* **A safety valve must fire on evidence about the thing it protects, never on a
  stopwatch.** "It has been long enough" is a guess about *slow*; only a failed
  progress test is evidence of *stuck*.
* **Ask the subsystem that does the work.** The path follower owns the progress
  and `path_position` is its own report; `x/y` is a *consequence* and can be
  moved by code that has nothing to do with the route.
* **A net that can catch the normal case is not a net.** Before shipping a
  last-resort timeout, compute the ordinary duration it must sit above (here:
  walk time = path length / pixels per step) and log it.
* **Label every fate** (kill / leak / valve / timeout). A mechanic whose exit
  path prints nothing cannot be debugged, and it gets re-reported as "the game
  cheats".
* **Never delete the rule's punishment.** When you add an escape hatch around a
  rule, check what the rule *was for*: this valve ended the wave without the
  leak, so lives never moved and the fail state could never be reached.
* **`==` latches, `>=` repeats.** If you relax one into the other, add the
  one-shot flag in the same edit — or a warning fires every frame from there on.
* **Count what your own loop removed, never the difference in
  `instance_number()`.** GMS2 removes a destroyed instance — and updates
  `instance_number()` / `instance_find()` indexes — only at the **end of the
  step**, so a delta read in the same step is always `0` (the summary line
  could never print), and a forwards loop walks off the end of a list that is
  shortening under it. Walk the list **backwards** and count in a local.

**Status.** FIXED, 2026-10-11.

**Files.** `scripts/scr_level_wait/scr_level_wait.gml`,
`objects/obj_mon/Create_0.gml`,
`scripts/scr_zomb_updatePosition/scr_zomb_updatePosition.gml`,
`scripts/scr_setupSpawning/scr_setupSpawning.gml`,
`scripts/scr_level_spawn/scr_level_spawn.gml`,
`scripts/lose_life/lose_life.gml`,
`scripts/scr_zomb_death/scr_zomb_death.gml`,
`scripts/scr_zombie_path/scr_zombie_path.gml`.

<a name="ll-032"></a>
## LL-032 — The progress gate is transactional for `set`/`add` only, so a hand edit that breaks it blocks every later write

**Symptom.** The tracker refuses a change and says so:

```
ERROR   focus.now points at unknown task 'audio-briefs'
nothing written - fix the values above and try again
```

Then **every subsequent command fails the same way** - including the
`gm progress add` that would have created the missing card - so the board
cannot be repaired with the tool that reported the failure.

**Root cause.** `validate()` runs on **every** write, and it checks `focus.now`
and `focus.next` against the card list. Pointing `focus` at a card that does
not exist yet is correctly rejected, but the rejection only rolls back the
change *that command* was making. A `focus` edit made **by hand** is already
on disk, so the file is left in a state that fails validation and no later
`add`/`set` will save until it is put back.

The rule is not the bug - the **order** is. `focus` is a pointer into the
card list, so it is the last thing to change, never the first.

**Fix.** Cards first, focus second:

1. `gm progress add <id> ...` for every new card;
2. *then* point `focus.now` / `focus.next` at them;
3. `gm progress build` in the same change.

If the file is already stuck, restore the `focus` block (`git diff
progress.json` has the previous value) and re-run the adds before re-applying
the focus. Do **not** delete the check.

**Guard rails.**
* **A gate that runs on write is not a transaction.** `nothing written`
  describes *that command*; run `git diff` before assuming the file is
  unchanged.
* **A pointer field is written last.** Anything that references another record
  (`focus.now`, `refs`, `needs`) has an order, and it comes after the record
  exists.
* **Hand-editing the JSON is still the sanctioned path** (AGENTS.md §6) - it
  just means the gate validates *your* edit too, so obey its ordering rule.

**Status.** FIXED (workflow), 2026-10-11.

**Files.** `python_tools/gm/progress.py` (`validate`, `_edit`), `progress.json`,
`AGENTS.md` §6.

<a name="ll-033"></a>
## LL-033 — A collision mask scales with `image_xscale`, so `mask_index` alone cannot give an object a fixed footprint

**Symptom.** A hand-drawn click mask was set on the tower object in the IDE
- `spr_tower_click_region`, 32x64: one cell wide, two cells tall - and it did
nothing observable. The tower's clickable area still hugged the artwork, and
because the artwork is drawn at 0.5 the region the mask described arrived at
**16x32**, half a cell wide. No error, no warning, and the mask sprite was
correct in every way that can be checked - size, origin, bbox, collision kind.

**Root cause.** `image_xscale`/`image_yscale` scale the COLLISION MASK too, and
`mask_index` does not exempt an instance from that. The manual defines the
bounding box as "the maximum width and height of the mask for the instance (as
set by the `sprite_index` or by the `mask_index`)", and a mask is scaled like
the sprite it comes from. `obj_tower/Create_0` set

```gml
image_xscale = 0.5;
image_yscale = 0.5;
```

to make 192x192 art occupy about 96px, so EVERY mask on that instance - the
artwork's own or a hand-drawn one - arrived at half size. The GameMaker
community answers the same question the same way: *"The mask_index should
still scale."*

The deeper problem is the usual one: **one variable doing several jobs.**
`image_xscale` was the sprite's size, its facing (the sign), its mask's size,
and - through `sprite_width` - the size of the step-1 click rectangle. Four
jobs in one number, and only three of them wanted to move together.

**Fix.** Keep `image_xscale`/`image_yscale` at +/-1 for FACING ONLY, and put
the art's size in a variable of its own, drawn with `draw_sprite_ext`, whose
scale arguments are independent of `image_xscale`:

```gml
draw_scale = 0.5;
image_xscale = 1;
image_yscale = 1;
```

```gml
/// scr_draw_self_scaled(_scale) - the one place that knows the idiom
var _scale = abs(argument0),
    _flip  = (image_xscale < 0) ? -1 : 1;
draw_sprite_ext(sprite_index, image_index, x, y,
                _scale * _flip, _scale,
                image_angle, image_blend, image_alpha);
```

Everything that read the size went with it: the shadow silhouette in
`scr_drawLight` (multiply by the instance's `draw_scale` when it has one), the
hover glow in `scr_drawGlowOutline` (passed in), the in-water part-draw in
`draw_self_part` (optional `_sx`/`_sy`, defaulting to `image_xscale` so every
existing caller is untouched) and the upgrade tween in `_levelControl/Step_0`
(writes `draw_scale`, so it can no longer un-mirror a tower). The step-1 click
box was deleted outright: `Step_1` asks the mask itself, with
`position_meeting(mouse_x, mouse_y, id)`.

**The same mask also made the placement ghost lie.** `obj_tower_edit/Step_0`
asked `position_meeting(x, y, obj_tower)` to decide whether the cell under the
ghost was taken, which reads the tower's 32x64 MASK - so the cell ABOVE a tower
went red, while `obj_tower/Create_0` blocks exactly ONE cell of the grid and two
towers may stand one above the other. The ghost now asks the grid it is about to
be written into - `mp_grid_get_cell(LEVEL.path_grid, (x + cell_w) div cell_w,
(y + cell_h) div cell_h) != 0` - plus a `_spawn` test, since the spawn is not in
the grid at all. A test of the shape "is this cell taken" belongs in the GRID;
a mask can only answer "is this point inside the ART", and after this change
those two are different shapes of answer.

**Guard rails.**
* **A mask of a fixed size needs the instance's scale to be 1.** There is no
  `mask_index` trick around it. Draw at the size you want with
  `draw_sprite_ext` / `draw_sprite_pos` and leave `image_xscale` alone.
* **Count the jobs before writing `image_xscale`.** Size, facing and mask are
  three questions, and anything derived from `sprite_width` or `sprite_xoffset`
  is a fourth. This is [LL-012](#ll-012) one level deeper: LL-012 lists the
  three ways a flip dies, and this is the fourth thing the same variable was
  carrying.
* **`sprite_width`, `sprite_height`, `sprite_xoffset` and `sprite_yoffset` all
  include the image scales**, so anything built on them follows the ART and not
  the mask once the two are decoupled. `sprite_get_width` /
  `sprite_get_xoffset` are the unscaled ones.
* **Grep for the consumers, not just the writer.** The size had five readers,
  and three of them were in files nowhere near the tower.
* **A mask answers "is this POINT inside the ART"; it cannot answer "is this
  CELL taken".** For occupancy ask the grid - and ask the SAME grid you write
  to, or the ghost and the placement will disagree about the same cell.

**Status.** FIXED, 2026-10-11.

**Files.** `objects/obj_tower/{Create_0,Draw_0,Step_1,Alarm_0}.gml`,
`objects/obj_tower_edit/{Create_0,Draw_0}.gml`,
`objects/_levelControl/Step_0.gml`, `scripts/scr_draw_self_scaled` (new),
`scripts/scr_drawLight`, `scripts/scr_drawGlowOutline`,
`scripts/draw_self_part`, `sprites/spr_tower_click_region`,
`objects/obj_tower/obj_tower.yy` (`spriteMaskId`).

<a name="ll-034"></a>
## LL-034 — A guard that asks a TYPE question about an asset refuses the asset

**Symptom.** Every stage is silent: no region theme, on any stage, ever — while the
title screen and the world map play theirs and every sound effect is normal. No
error, no popup, nothing wrong in the game itself. The only clue is a line in the
runtime's own output (rayu's run, `GameMakerStudio2/debug.log`):

    META  [MUSIC] region 1 "Wilted Sprouts" has no track yet - playing nothing

It names the RIGHT region and the RIGHT title, so `music_for_region()` found the
row and the table is fine. Only `_music.sound` was rejected — and the message
blamed the TRACK rather than the test, which is what made it look like a missing
asset for far too long.

**Root cause.** The guard meant to catch *"this track has not been generated yet"*
asked the wrong question:

    if(!is_real(_sound) || _sound < 0){ ...refuse... }

`is_real()` asks *"is this a plain number"*, and an **asset reference is not a plain
number**: it is a reference. `is_real()` is itself documented as false for int64s such
as enums, and `typeof()` documents `"ref"` for handle references — both are the same
shape of value, one that a numeric type test rejects. So `is_real(mus_world1)` is
**false for a perfectly good sound**, `||`
short-circuited before the (also wrong) `< 0`, and the guard refused a track that had
been imported, converted and built correctly: its `.yy` is byte-identical to
`mus_world2.yy` apart from the duration, and the IDE's asset cache held a valid
converted `mus_world1.wav` with a valid `<Duration>163.53</Duration>` beside it.

Why the menu theme kept working — the most misleading part: `obj_title` and `Menu`
call `scr_playMusic(music_menu().sound, true)`, the SAME KIND of value through the
SAME `audio_play_sound_on(global.MUSemitter, …)` — but **that path never runs the
guard**. One code path had the type test, the other did not, so the same asset type
played on one screen and was refused on another.

**Fix.** Test the value the table actually documents, and let the audio API be the
judge of an asset:

    if(is_undefined(_sound) || _sound == -1){
        ...logs which of the two fired...
        return -1;
    }

`music_data()` already documents `sound = -1` as *"not generated yet"* (LL-021: one
source of truth) and `undefined` as *"no row / no sound"*. Both are tested by value,
and the refusal now says WHICH one fired instead of one sentence covering two
different bugs. The play line also prints `typeof(_sound)`, so the representation of
an asset reference is on the record instead of assumed - expect a line of this shape,
where the parenthesised word is `typeof()`'s own name for an asset reference:

    META  [MUSIC] region 1 "Wilted Sprouts" mus_world1 (ref) loop 0 -> 163.53s (whole track)


**Guard rails.**

* **Never ask a TYPE question about an asset.** Ask the sentinel your own table
  documents, or use the asset's own API — and note that `audio_exists()` **throws**
  on an index the runtime has never seen (*"this function will cause an error as it
  is searching for non-existent asset indices"*), so it cannot be a guard either
  (LL-002). There is no `is_asset()` in the runtime: `asset_get_index()` /
  `asset_get_type()` are the asset-scoped lookups.
* **A guard that refuses a good value is worse than no guard** — it converts a
  working feature into silence, and its message blames the data. Test a guard
  against a REAL row first, not only against the broken case it was written for.
* **Grep for the shape, not the function**: a numeric type test (`is_real`,
  `is_int64`) applied to something that is not a number. The project's convention
  for an asset is `is_undefined(x) || !sprite_exists(x)` — see `scr_scale_sprite`.
* The same silence taught a second lesson: the loop-point pair `0.0/0.0` is now
  never set, because `loop = true` already repeats the whole track and that pair
  depends on the runtime reading *"loop end 0"* as *"end of file"* rather than as
  *"zero seconds"*. Do not ship a setting you cannot verify for a case that does not
  need it.

**Status.** FIXED — 2026-10-11.

**Files.** `scripts/scr_music_start_level/scr_music_start_level.gml`,
`scripts/music_data/music_data.gml`, `scripts/scr_playMusic/scr_playMusic.gml`,
`objects/obj_title/Step_0.gml`, `objects/Menu/Step_0.gml`.

---

<a name="ll-035"></a>
## LL-035 — An unpassed declared parameter is `undefined`, and `argument_count` is not the call count

**Symptom.** Every frame a monster was in water:

    ERROR in action number 1
    of Draw Event for object obj_mon:
    undefined value
     at gml_Script_draw_self_part (line 33) - 	    _x = x - sprite_get_xoffset(sprite_index)*_sx,
    gml_Script_draw_self_part (line 33)
    gml_Object_obj_mon_Draw_0 (line 4) -     draw_self_part(0,0,1,0.75,0);

The call is legal, the sprite exists, and the same function drew fine for a tower
in water. Only the *five-argument* call failed, and only after the function gained
two OPTIONAL parameters.

**Root cause.** The optional parameters were detected with `argument_count`:

    var _sx = (argument_count > 5) ? argument5 : image_xscale,   // 7 declared

`draw_self_part` declares SEVEN parameters (`argument0`..`argument6`) and
`obj_mon/Draw_0` passes FIVE. The argument list is sized to the **declared** arity —
the unpassed parameters are padded with `undefined` — so `argument_count` was not
5. The ternary took the `argument5` branch, `argument5` is a declared-but-unpassed
parameter holding `undefined`, and the multiply on the next line threw.

Three things prove the mechanism, none of which needs a debugger:

* **The error text is the proof.** It says *undefined value* — arithmetic on
  `undefined` — and not *not set before reading it*. So the parameter slot EXISTS
  and holds `undefined`; it is not an absent variable. That is also why
  `is_undefined()` is a safe test for it.
* **`image_xscale` cannot be the `undefined`.** `obj_mon/Create_0` never touches it,
  and every assignment in the project gives a monster a real number — `0`,
  `±abs(image_xscale)`, `base_scale * _t`, `±base_scale` — with `base_scale` always
  a real (`1` in `obj_mon/Create_0`, `0.25`/`0.5` from `scr_level_spawn`). The
  default branch would have been a number.
* **The same project shows `argument_count` counting the CALL.** `scr_meta_log(_tag)`
  declares ONE parameter and is called with about ten; its
  `for(var _i = 1; _i < argument_count; _i++)` prints ALL of them (`META  [MUSIC]
  region 1 "Wilted Sprouts" …`). Declared 1, called 10 → count 10. Declared 7,
  called 5 → count 7. Both fit **`argument_count = max(declared, passed)`**.


**Why nothing else in the game ever hit it.** Every other `argument_count` user in
the project declares ZERO parameters — `array()`, `array_slice()`,
`scr_makeMonster()`, `show_menu()`, `print()`, `set_bitmask()`,
`stream_particles()`, `scr_randomBoolAddition()`, `setup_blowup()`,
`create_display_grid()` — the manual's variadic shape
(`function print() { … argument_count … }`). A function with no declared
parameters cannot be padded, so it is immune. `draw_self_part` was the only
function in the project whose parameter list is longer than its smallest call.

**Fix.** Ask the VALUE whether the argument was passed:

    var _sx = is_undefined(argument5) ? image_xscale : argument5,
        _sy = is_undefined(argument6) ? image_yscale : argument6,

This does not depend on how `argument_count` is computed, and it is the project's
established "not there" test (`GameLevelData`, `region_data`, `scr_meta_seeds`).
`scr_drawGlowOutline(argument0)` carried the same brittle shape
(`argument_count > 0 && argument0 > 0`) and was changed with it — it worked only
because its one caller always passes an argument.

**Guard rails.**

* **Two safe shapes for an optional argument:** declare it and test
  `is_undefined(value)`; or declare NOTHING and read `argument[i]` with
  `i < argument_count`. The unsafe third shape is *declare parameters AND test
  `argument_count` for the short call*.
* **Never size a variadic list from `argument_count` in a function that declares
  parameters.** If the declared list can ever be longer than the call,
  `argument_count` reports the declared arity. Pad-proof code declares nothing.
* **A declared-but-unpassed parameter is a variable holding `undefined`.** It can
  be read, and `is_undefined()` is the right question — but if it feeds a plain
  assignment, the `undefined` travels silently until something does arithmetic
  with it, which may be far away (here: the next line; in general: another event,
  another frame).
* **When a caller-count bug is suspected, print the count and the type**
  (`argument_count`, `typeof(...)`) rather than guessing. The diagnosis here took
  the error text plus two greps, not a debugger.

**Status.** FIXED — 2026-10-12.

**Files.** `scripts/draw_self_part/draw_self_part.gml`,
`scripts/scr_drawGlowOutline/scr_drawGlowOutline.gml`,
`objects/obj_mon/Draw_0.gml`, `objects/obj_tower/Draw_0.gml`.

---

<a name="ll-036"></a>
## LL-036 — A wave's creature comes from one of TWO banks, and the boss rule is a cadence, not the last wave

**Symptom.** A difficulty projection and the actual play disagreed, and the play
was right: rayu **leaked units from wave 10 of stage 1-1 with a full tower wrap**,
then starved. The curve diagnostic - reading the stage's ordinary spawn pool -
modelled wave 10 as `5 + 10 div 5 = 7` creatures of 7 HP, **nothing special**, and
printed a comfortable `bite` for it. No error, no warning, nothing in any log to
suggest the number was wrong.

**Root cause.** Wave 10 is a **BOSS wave**, and the projection was reading the
wrong array. `region_data()` gives region 1 `boss_every = 10`, and
`scr_level_pick_spawn` promotes **every** `wave % boss_every == 0` (with
`wave > 1`) to a boss wave:

    var _is_boss = (_every > 0 && _wave % _every == 0 && _wave > 1);

Two things make this easy to miss:

* **The stage's own `bosses` list is not the rule.** `stage_row(1, 1, 3, [0], [],
  40, 90)` leaves `bosses` empty, so the *named* final boss does not exist in
  stage 1-1 - but the **cadence** still fires at wave 10. "The last wave is the
  boss" is only half the rule, and stage 1-1 satisfies neither half until you know
  `boss_every` exists.
* **A boss wave comes from a different pool.** `scr_level_spawn` sends exactly ONE
  creature (`if(is_boss_wave) MAX = 1`) drawn from **`spawn_boss`**, where the two
  entries are `Tusk-A-Lot` life **55** and `Sub-Zero` life **110** - against
  Grumble-Mulch's **7**. At the ceiling then in force (`m(10) = 12.98`), that is
  **714-1428 HP on one body**, roughly an order of magnitude above what the
  projection was modelling.

So the diagnostic agreed with the design, and the design was not what was
running. The number was plausible because it came from a real array - just not the
one the wave used.

**Fix.** State the rule from the data, in one place, and take the creature from
the bank the rule implies:

    function scr_curve_is_boss_wave(_w, _waves, _boss_every, _has_named_boss) {
        if(_w > 1 && _boss_every > 0 && _w % _boss_every == 0) return true;
        if(_has_named_boss && _w >= _waves) return true;
        return false;
    }

`scr_curve_wave_demand()` then reads `MON.life` / `MON.speed` from
`spawn_boss` (and its own count of 1) when that returns true, and the read-out
prints a `BOSS` row for the **first mid-stage** boss wave as well as the last
wave. It is drawn on screen (`scr_curve_draw()`), because the Output window is
not visible while playing and a diagnostic nobody can read is not a diagnostic.

**Guard rails.**

* **A wave's creature is `spawn_boss` OR `spawn_mon` - never just the one you
  have in hand.** Code that reasons about "a wave" while reading only `spawn_mon`
  is wrong on **every boss wave**, which is 1 in 10 of a region-1 stage.
* **`boss_every` is a CADENCE and the named boss is the FINALE.** Both are true at
  once, either can be absent, and `wave > 1` matters (wave 1 is never a boss). Do
  not re-implement the rule - `scr_level_pick_spawn` owns it.
* **A projection that agrees with the design is not evidence.** Ask what a number
  would look like if it were reading the *wrong input*: here, too small by ~10x
  and completely silent. Two banks, one of them chosen by arithmetic, is exactly
  the shape a "looks fine" bug takes.
* **Money is not the only constraint on defence.** The same function originally
  assumed every dollar ever earned becomes a tower that reaches the path, so it
  could report `ok` while a full wrap leaked. A fixed route can only be covered by
  the cells within range of it - `scr_curve_slots()` counts them - and the supply
  term has to be `min(money / price, slots)`.
* **The ceiling and the ladder are ONE change** ([LL-022](#ll-022)). Lowering
  `curve_end` from 30 to 13 without settling the rung price is half a change, so
  `curve-cap-lower` and `choose-rung-price` are deliberately coupled.
* **Only the ceiling moves a wall.** With `curve_pow = 3` the old curve still
  crosses 12.98 at wave 11, so a steeper bend re-sites the wall rather than
  removing it - if the complaint is "it gets too hard", the ceiling is the lever.

**Status.** FIXED — 2026-10-13.

**Files.** `scripts/scr_curve/scr_curve.gml` (`scr_curve_is_boss_wave`,
`scr_curve_wave_demand`, `scr_curve_slots`, `scr_curve_draw`),
`objects/_levelControl/Draw_64.gml`, `scripts/region_data/region_data.gml`,
`scripts/scr_level_pick_spawn/scr_level_pick_spawn.gml`,
`scripts/scr_level_spawn/scr_level_spawn.gml`.

---

<a name="ll-037"></a>
## LL-037 — A test that selects its fixture from the live data fails when the data is finally clean

**Symptom.** `python3 -m unittest discover -s python_tools/tests` went from
`Ran 32 tests ... OK` to `FAILED (errors=1)` on an edit that changed **no
production code**, and the traceback was inside a *test*, not in the game:

    ERROR: test_rejects_a_done_card_that_is_still_awaiting
      File "python_tools/tests/test_gm.py", line 337, in mutate
        task = next(x for x in d["tasks"] if x.get("awaiting") not in (None, "none"))
    StopIteration

Nothing in `scripts/`, `objects/` or `progress.py` had been touched. What *had*
changed was `progress.json`: the last card awaiting a person had just been
closed, so the board read **`awaiting: nobody`**.

**Root cause.** Two tests built their fixture by SEARCHING the repo's own
`progress.json` for a card that already had the property under test:

    task = next(x for x in d["tasks"] if x.get("awaiting") not in (None, "none"))
    task = next(x for x in d["tasks"] if x.get("status") == "backlog")

`next()` on an exhausted generator raises `StopIteration`. So the gate asserted a
fact about the **board's current shape** instead of about the **rule**: the
"done card must not be awaiting" test could only pass while some *other* card was
awaiting someone. Emptying the awaiting strip - the thing the session set out to
do - is exactly what turned it red.

That is the trap: the test's pass was coupled to the data it was supposed to
guard. A gate that fails when its subject is finally clean teaches you to ignore
the next red.

**Fix.** Build the fixture instead of finding it, the way the neighbouring test
always did:

    def mutate(d):
        task = d["tasks"][0]
        task["status"] = "done"
        task["done"] = "2026-01-01"
        task["awaiting"] = "rayu"
        task["needs"] = "a line, so only the rule under test fails"

`d["tasks"][0]` is deterministic in canonical order (tasks are sorted by id), so
the test now depends on `validate()` and nothing else. The **BACKLOG** test
(`test_rejects_a_backlog_card_that_is_awaiting_a_person`) had the identical
latent hole and was fixed with it - it was only passing because the repo happened
to still have backlog cards, and a finished project has none.

**Guard rails.**

* **A test may READ the live data; it must not require the live data to have a
  particular shape.** Mutate a known key (`d["tasks"][0]`) or append a synthetic
  card - never `next(... for x in <live> if <property>)`.
* **`next()` with no default is a hidden assertion.** `next(it)` on an empty
  iterator is a `StopIteration` that unittest reports as an **ERROR in the test**,
  not a failure of the rule. If a search is genuinely needed, pass a default and
  assert on it, so the message names the missing precondition.
* **A red gate after a "nothing changed" edit is data, not noise.** Read the
  traceback before assuming your change caused it - here the data *was* the point.
* **Some tests are supposed to read the repo** (`test_repo_tracker_is_valid`,
  `test_generated_views_are_in_sync`). That is correct for a rule about the repo,
  and a trap for a rule about the schema - keep the two apart.

**Status.** FIXED — 2026-10-13.

**Files.** `python_tools/tests/test_gm.py`.

---

<a name="ll-038"></a>
## LL-038 — The projection said `ok` and the play leaked, because three assumptions were doing the work of facts

**Symptom.** Two of them, and the second is the dangerous one.

1. The in-game `CURVE` panel read `?` for the first **eleven waves** of stage 1-1
   and `ok` for every wave after that — while the play log said Rayu leaked from
   wave 10 with a full tower wrap.
2. A brand-new headless tester, written expressly to check that panel, **agreed
   with it**, because it had been written from the same formula. A checker that
   restates the thing it checks cannot find anything.

**Root cause.** `scr_curve_report`'s supply was

    available = min(money / price, slots) * best_placement_dps

and all three of its terms were *assumptions* wearing the costume of arithmetic:

* **Affordability.** `best_placement_dps` comes from the tower with the highest
  dps per dollar — Pina Collider, $100. On wave 1 the purse is $30, so the
  formula fields **zero** towers and cannot compute a bite at all (`?`). The shop
  sells $5 towers. A model may not spend money the player does not have, and it
  must be checked against the CHEAPEST thing in the shop, not the best value.
* **Congestion.** `dps` was `damage x fire_rate x targets`, and `targets` is 10
  for the Pina Collider — "2000 dps" only if ten monsters are inside a 75px
  range at once. They spawn 0.5 s apart and walk ~1.26 px a step, so on the
  board's 1840px route they are ~37px apart: two or three in range, not ten.
  `targets` is a *claim about congestion*, not a multiplier.
* **Coverage.** A tower fires only while a monster is inside its range. The
  formula credited it with its full dps along the **whole route**, and `slots`
  only ever counted *how many* towers could reach the path, never *how much of
  the path* each one holds. On stage 1-1 that is 9–15% of the route — so the
  model was optimistic by roughly an order of magnitude.

Put together: a wall the game felt at wave 10 read as comfortable, and the tool
built to catch it reproduced the mistake because it was the same mistake.

**Fix.** Supply is now built from the same greedy the sim spends with — score
every `(cell, tower)` by `nominal dps x coverage / price` and buy while the
purse lasts (`gm.balance.policy`), where `coverage = covered route px / route
px` (`gm.balance.geometry.covered_length`) and `nominal dps` is the
**single-target** figure. The panel's own formula is still computed and printed
beside it, so the gap between belief and arithmetic is visible instead of
argued. With that model the old ceiling of 30 reads a worst bite of **1.32**,
`HIGH` from wave 13 — the leak, predicted — and the retuned 13 reads **0.57**.

**Guard rails.**

* **A projection must be able to disagree with the play.** Build it from the
  mechanics, not from the last explanation of them, or it will certify whatever
  is already believed.
* **When you write a checker for a model, re-derive it - never port it.** The
  first version of the tester was a faithful port, which made it useless.
* **Every multiplier in a "dps" has a precondition. Write it down.** `x targets`
  means "and enough monsters in range"; "coverage" means "and for the whole
  traversal". A number with an unstated precondition will be read as a fact.
* **Validate a balance model against a KNOWN bad outcome.** The regression test
  is "the old ceiling must break the stage" — a model that cannot reproduce a
  leak the player actually had is not evidence about anything.
* **A verified non-trap, so nobody "fixes" it later:** GML's `round()` is
  **banker's rounding** (half to even), exactly like Python's built-in. The
  manual says so, and `python_tools/tests/test_balance.py` asserts it. A
  hand-written "round half up" would put every rung price and kill payout out by
  one.

**Status.** FIXED — 2026-10-13.

**Files.** `python_tools/gm/balance/` (`policy.py`, `model.py`, `geometry.py`,
`terrain.py`), `scripts/scr_curve/scr_curve.gml`.

---

<a name="ll-039"></a>
## LL-039 — A list you only ever write to at its own last index can never grow

**Symptom.** None, for months. That is the point.

A tower's `targets` stat did nothing. A Slender Mandrake with `targets = 3` hit
one monster. A Pina Collider with `targets = 10` hit one monster. No error, no
warning, no log line - just a number in a table that quietly meant nothing, and
a shop card that printed `damage x rate x targets` as if it did.

It surfaced sideways: a balance tool reported the game was comfortable while a
play log said it leaked, and the discrepancy could not be closed until this fell
out of the code (LL-038).

**Root cause.** `find_all_range`:

```gml
var _targets = -1;                       // a NUMBER, not an array
for (var i=0; i<_count; i+=1) {
    var _them = instance_find(_type,i);
    if(point_in_circle(_x,_y,_them.x,_them.y,_r)){
        var _ind = array_last_index(_targets);   // the index it JUST READ
        if(_ind < _max){
            _targets[_ind] = _them;              // writes at THAT SAME index
        }
    }
}
```

The **missing advance**. Let `L(t)` be the array's last index after iteration
*t*. Iteration *t* writes at `L(t)`, so `L(t+1) = max(L(t), L(t)) = L(t)` - the
last index is a fixed point. The array can therefore never hold more than one
entry, whatever `qty` is, and whatever GML makes of `array_last_index(-1)` or a
negative-index write. The `+ 1` (`_ind = array_last_index(_targets) + 1`) was
simply not there.

So **every tower in the game was single-target**, and the roster's own stated
roles were fiction: `scr_tower_roster` says the four starters "between them cover
cheap DPS, damage over time, multi-target and area damage" — two of those four
did not exist.

| tower | `targets` | shop dps | actual dps |
| --- | --- | --- | --- |
| Slender Mandrake | 3 | 375 | **125** |
| Pina Collider | 10 | 2000 | **200** |
| Cannon Tulip | 5 | 150 | **30** |

**Fix.** Append instead of overwrite, take the nearest `_max`, and **keep the
non-array sentinel**:

```gml
_near[array_length(_near)] = [_dist, _them];    // the advance
...
if(_found == 0) return -1;                      // the sentinel
```

The sentinel is not decoration. `scr_tower_shoot` does
`if(!is_array(target)) ... scr_changeState(scr_tower_return); exit;` — it decides
"nothing to shoot, go idle" by testing that the return is *not* an array.
Returning `[]` for "nothing in range" would be a **valid** list: the tower would
never go idle, and would swing at the air forever with `did_damage` already set.
A failure that looks like a success (LL-025's shape).

**Guard rails.**

* **Read and write indices are different jobs.** `array_last_index()` answers
  "where does it end"; an append needs "where does the next one go" —
  `array_length()`. If a loop reads an index and writes to it, suspect it.
* **A signature check cannot catch this.** `gm gml-functions` reported
  `find_all_range(argument0, ...)` quite happily; the bug is inside. A
  brace/paren **balance** check caught the orphan `}` my own fix left behind —
  run both, and check balance after any structural edit.
* **A stat that nothing reads is invisible; a stat that is read but ignored is
  worse.** `targets` was plumbed all the way into the shop's arithmetic, which
  is what made it look real.
* **When a number in the UI has a multiplier, verify the multiplier can be
  non-1.** Pina's "2000 dps" was checked against a doc table, not against ten
  monsters on screen.
* **Prove a load-bearing claim, then *see* it.** A bounded dev-mode probe
  (`cap_probe_left`) printing the cap beside the count turns this from an
  argument into one line in the Output window.

**Status.** FIXED — 2026-10-13.

**Files.** `scripts/find_all_range/find_all_range.gml`,
`scripts/scr_tower_shoot/scr_tower_shoot.gml`,
`objects/obj_tower/Create_0.gml`.

---

<a name="ll-040"></a>
## LL-040 — The fire period was charged twice per shot: the idle wait *and* the attack

**Symptom.** Nothing errors, nothing crashes, and no individual number looks
wrong — but the board will not balance. Every tower in the roster delivers
roughly **a third** of the dps its shop card advertises, and the shortfall is
**uneven**, so the ranking of the roster on paper does not match the ranking in
play. It is [LL-038](#ll-038) one level down: a projection that says `ok` on a
wave the play leaks.

**Root cause.** One shot walked through three states and **two of them each
spent a whole fire period**:

```gml
scr_tower_normal:  if(state_time > room_speed/data[TOWER.fire_rate] + time_offset)  // wait P + off
scr_tower_shoot:   frame_number = room_speed/data[TOWER.fire_rate]; exit at P      // spend P
scr_tower_return:  anim_steps  = anim_seconds[TOWER_ANIM.return] * fps             // spend 15
```

so the cycle was `2P + off + 15`, not `P`. A Daisy Pusher (`fire_rate` 3, so
`P` = 20) swung every **~59** frames instead of ~20.

The intent is written down in `scr_tower_shoot` itself — *"the attack's length
IS the fire rate"* — and that is exactly what makes the wait in
`scr_tower_normal` a duplicate: the fire rate had **already** been spent, in the
state that was meant to spend it.

It survived because **it is arithmetic spread across three files, and every file
is correct on its own.** `scr_tower_normal` reads as a sensible "do not shoot
too often" throttle; `scr_tower_shoot` reads as a sensible "the animation is the
cadence". Only the *sum* is wrong, and nothing in any one file looks like a bug —
so a reader confirms each line and moves on.

**Fix.** The idle wait is the STAGGER only, which is what `time_offset`
(`irandom_range(1,8)`, `obj_tower/Create_0`) is for:

```gml
/// scr_tower_normal
if(state_time > time_offset){
```

The cycle becomes `P + off + 15`. `>` and not `==`, for [LL-029](#ll-029)'s
reason (never test equality against a quantity derived from the FPS setting).
It also takes the last obsolete `room_speed` read out of the firing loop
([LL-007](#ll-007)).

**What it is worth.** `off` averages 4.5 (it is a per-tower `irandom_range(1,8)`,
so towers do not fire in lockstep):

| tower | P | cycle before | cycle after | real dps before → after | gain |
| --- | --- | --- | --- | --- | --- |
| Daisy Pusher | 20 | 59.5 | 39.5 | 4.0 → 6.1 | 1.51x |
| Burning Ivy | 30 | 79.5 | 49.5 | 30 → 49 | 1.61x |
| Slender Mandrake | 60 | 139.5 | 79.5 | 54 → 94 | 1.75x |
| Pina Collider | 60 | 139.5 | 79.5 | 86 → 151 | 1.75x |
| Cannon Tulip | 120 | 259.5 | 139.5 | 14 → 26 | 1.86x |
| Meat Bulb | 80 | 179.5 | 99.5 | 84 → 151 | 1.80x |

A **1.5x–1.9x** buff — and the part that matters for a rebalance is that it is
**not flat**: the slow-firing towers gain most (Cannon Tulip +86%, Daisy Pusher
+51%). Fixing it **changes the order of the roster**, so it has to land *before*
the prices are fitted, never after. A "buff of 1.7x on average" is not a
description of this change; the *ratios* move.

**Guard rails.**

* **A period is spent in ONE place.** If two states each wait for the fire rate,
  one of them is wrong. Count the states between two identical events.
* **A `+ time_offset` on a period is a smell worth reading twice.** Offsets are
  for de-synchronising; if the base term is the *whole* period, ask which other
  state is also spending it.
* **Verify a cadence with a stopwatch, not a formula.** The probe in
  `scr_tower_shoot` prints the **measured** step gap between swings
  (`TOWER  shot interval …`), so the fix is *seen* and not assumed — the same
  move as `cap_probe_left` in [LL-039](#ll-039).
* **A fix that is uneven is a roster change.** Check the *ratio* between the
  entries, not just the total, before pricing anything.
* **When the intent is written in a comment, the comment is the spec.**
  *"The attack's length IS the fire rate"* is what makes the second wait a bug
  rather than a design choice — and it also names the residual below.
* **A residual is still a lie.** After this fix the card overstates by 1.3–2x,
  because `fire_rate` is nominally "shots per second" while the 0.25 s return
  animation is charged on top. The card is a *nominal* number; only a simulation
  converts nominal into delivered (see [LL-038](#ll-038), coverage).

**Status.** FIXED — 2026-10-13 (the fire-cycle probe is awaiting one play log).

**Files.** `scripts/scr_tower_normal/scr_tower_normal.gml`,
`scripts/scr_tower_shoot/scr_tower_shoot.gml`,
`objects/obj_tower/Create_0.gml`, `objects/obj_tower/Step_0.gml`.

---

<a name="ll-041"></a>
## LL-041 — Two tests indented inside the `__main__` block had never run

**Symptom.** None. The suite was green (`Ran 75 tests ... OK`) and it stayed
green. The only trace of the problem was a *number*: adding ten tests moved the
count by ten, not twelve.

**Root cause.** `test_balance.py` ended like this:

```python
if __name__ == "__main__":
    unittest.main()




    def test_a_bigger_range_covers_more_of_the_route(self):
        ...
```

Four spaces of indentation after a blank line is **not** a new top-level
statement - it is still the body of the `if`. Python parses that happily, so the
two methods are defined only when the module is *run* as `__main__`. The test
discoverer **imports** the file, `__name__` is not `"__main__"`, the methods are
never created, and two `GeometryTests` cases silently stop existing. No error,
no warning, no visible symptom - and `test_covered_length_never_exceeds_the_route`
had been dead since the day it was written.

**Fix.** Both methods moved back into `GeometryTests`, before `class ModelTests`:

```python
    def test_covered_length_never_exceeds_the_route(self):
        ...
```

The suite went 75 → 87 on the same change (10 new fire-cycle/report tests, plus
these 2 that had been missing).

**Guard rails.**

* **Check the COUNT moved, not just that the run is green.** After adding *n*
  tests the total must rise by *n*. A suite that cannot notice a missing test has
  a hole in it - this is [LL-025](#ll-025)'s shape, a failure that looks like a
  pass.
* **A `def` after a blank line is not automatically top level.** Indentation is
  semantic; when appending to an existing Python file, look at what block you are
  already inside before you write.
* **A dead test is worse than a missing one**, because the coverage *looks*
  present. The same is true of a probe that never prints and a log line that
  never fires - so ask **"has this ever actually run?"** before you rely on it.
  That question is the reason `cap_probe_left` and the fire-cycle probe exist.
* **Fix it where it belongs, not where it is.** De-indenting the orphans in place
  would have left them after `unittest.main()`; moving them into the class they
  were written for is the fix, and the class then asserts the shared fixture.

**Status.** FIXED — 2026-10-13.

**Files.** `python_tools/tests/test_balance.py`.

---

<a name="ll-042"></a>
## LL-042 — Hard pays exactly what Normal pays, and Brutal pays double

**Symptom.** None on its own, which is why it survived two years of tuning. The
consequence showed up in the SIM, not the game: stepping stage 1-1 at 60fps with
the money arriving as it lands, **Brutal holds better than Hard** - 0 leaks and
$22 left over, against 19 leaks and one heart left. `gm balance project` says
the opposite, and so does every number the game prints.

**Root cause.** `scr_zomb_death` pays

```gml
add_item_value(STATINV.money,
               round(data[MON.kill_money]*difficulty_money_mult()));
```

A Grumble-Mulch pays **1**, so the money column is applied to a 1 and *then*
rounded to an integer:

| difficulty | money mult | `round(1 x mult)` | per kill | income over 1-1 | hp mult |
| --- | --- | --- | --- | --- | --- |
| Normal | 1.00 | 1 | $1 | $122 | 1.0 |
| Hard | 1.25 | **1** | $1 | $128 | 1.5 |
| Brutal | 1.50 | **2** | $2 | $247 | 2.5 |

Hard's column is a NO-OP and Brutal's is a DOUBLING. HP per dollar therefore
comes out at 1.00 / 1.17 / 1.01: **Hard is the hardest difficulty in the game
and Brutal is the easiest.** `difficulty_money_mult()` on a base of 1 is a step
function, not a scale - 1.25 and 1.00 are the same number, and so is everything
below 1.49.

**Fix.** A **fractional carry** at the payout site - chosen over "raise the base
payout" (which rescales every number in economy.md by 4) and over "move the
rounding" (which makes the purse a float, so the HUD prints $12.5 and the shop's
affordability test changes meaning).

```gml
/// scr_kill_money, in difficulty_data.gml - the ramp, the column and the carry
/// are ONE rule.  Called from inside with(_levelControl), because money_carry is
/// the RUN's (AGENTS.md 1 rule 6).
function scr_kill_money(_base, _wave, _ramp) {
    if(!is_real(_base)) return 0;
    if(!variable_instance_exists(id, "money_carry")) return round(_base);
    var _mult = (is_undefined(_ramp) || _ramp) ? kill_money_ramp(_wave) : 1,
        _want = _base * _mult * difficulty_money_mult() + money_carry,
        _pay  = floor(_want);
    money_carry = _want - _pay;   /// the fraction lives on to the next kill
    return _pay;
}
```

Money stays an integer - the carry is the only fractional thing, and it lives on
`_levelControl` - so four kills at x1.25 pay **1, 1, 1, 2**: exactly +25% over
the four, where rounding paid 1, 1, 1, 1.

Landed with it (the same change, 2026-10-13): the kill-money **ramp**
(`1 + 0.06 * (wave - 1)`, so income grows with the wave instead of only with the
count) and the CLOSED FORM and the SIM taught to model both, because a tester
that keeps its own opinion about the payout is LL-038 again. Measured after:
income $160 / $196 / $264 and hp-per-dollar **0.0063 / 0.0076 / 0.0095** -
ordered, hardening as the difficulty rises, where it was 1.00 / 1.17 / 1.01.

**Guard rails.**

* **A multiplier applied AFTER a round to an integer is a step, and the step
  here is 100%.** Scale before you round, or accumulate fractionally; never tune
  a percentage that a `round` can swallow. (`+0.01 * wave` in the speed ramp is
  the other side of the same coin - it works because the speed it feeds is a
  float.)
* **Test a difficulty column against INCOME, not just hp.** The panel's promise
  is about hp; what the player experiences is hp per dollar.
* **A ratio cannot see this.** The closed form was right about every wave and
  wrong about the stage, because it never let the money arrive late. It took a
  time-step to find - which is the entire argument for `gm balance sim`.
* **When the rule changes, the tools change with it.** Two Python models
  (`money_through`, `Sim._payout`) computed the payout too, and the slope is read
  out of the GML by `gm balance check` so it cannot drift.

**Status.** FIXED, 2026-10-13 (`difficulty-columns-vs-curve`; the reprice that
shipped alongside it left the wave curve stale - worst bite 0.32 on 1-1 - which
is `balance-fit-from-sim`).

**Files.** `scripts/difficulty_data/difficulty_data.gml` (`kill_money_slope`,
`kill_money_ramp`, `scr_kill_money`), `scripts/scr_zomb_death/scr_zomb_death.gml`,
`objects/_levelControl/Create_0.gml` (`money_carry`),
`python_tools/gm/balance/{model,sim,tables}.py`, `python_tools/gm/cli.py`.

---

<a name="ll-043"></a>
## LL-043 — A waterline expressed as a fraction of the sprite CANVAS means a different depth for every sprite

**Symptom.** After the tower art was swapped to the 192x192 daisy trio, the
plants stopped sitting in the water properly, and nothing errored:

* a plant in water wore a **halo of itself** — a second, larger copy around and
  behind the one you place;
* the **seam** where the plant meets the surface sat at a different height for
  each tower, so two towers side by side were wading to different depths, and a
  monster waded to a third;
* a **left-facing** tower in water was drawn **upside down and about 220px too
  low** - and only when it faced left, so it read as "sometimes the water
  glitches";
* the reflection the water was supposed to show had never once been drawn.

No error, no log line, no clue in the runtime output. It is a *look*, so there
is nothing to grep for.

**Root cause.** Four defects, all of them the same art change arriving at a
different reader. This is [LL-033](#ll-033)'s own guard rail ("grep for the
consumers, not just the writer") being violated by four more consumers.

1. **The submerged copy was drawn at the wrong size.**
   `obj_water/Draw_0` re-drew every in-water tower with `draw_self()`, which
   draws at `image_xscale`/`image_yscale`. On a tower those are `±1` **facing
   only** and the art's size is `draw_scale` (LL-033), so the copy was drawn at
   `1/draw_scale` — **1.43x** the tower at the `0.70` a placed tower settles on.

2. **The waterline was a fraction of the CANVAS.**
   `obj_tower/Draw_0` cropped `0.8` and `obj_mon/Draw_0` cropped `0.75` of the
   sprite's height. A fraction of the canvas is a *different world depth for
   every sprite*, because every canvas has a different origin and a different
   amount of padding:

   | sprite | canvas | origin | origin / canvas | what 0.8 hides |
   | --- | --- | --- | --- | --- |
   | `spr_daisy_idle_192x` | 192x192 | (97, 158) | 0.823 | 27px |
   | `spr_t3_idle` (Cannon Tulip) | 66x88 | (32, 75) | 0.852 | 12px |
   | `spr_grumble_walk` (0.75) | 140x160 | (49, 150) | 0.937 | 10px |

   Measured seams: **daisy 3.1px** above its base, **`spr_t3` 3.2px**,
   **monster 7.5px** - three different waterlines from three numbers that were
   each "obviously the same idea".

3. **A signed value went into both axes of a part draw.**
   `obj_tower/Draw_0` built `_art = draw_scale * sign(...)` and passed it as
   **both** `_sx` and `_sy` to `draw_self_part`. `draw_sprite_part_ext` reads a
   negative yscale as "draw it upside down **and** anchor it from there", so on
   a left-facing tower `_y` moved from `y - 110.6` to `y + 110.6` (the origin is
   158px from the top; at 0.70 that is 110.6px) **and** the part was flipped.
   That is another way for a flip to die in [LL-012](#ll-012)'s collection, and
   the fix is the same as ever: the sign belongs to the axis that carries
   facing, and only that one.

4. **The reflection script was ported dead and left dead.**
   `scr_drawReflections` had exactly one reference - a commented-out line in
   `draw_water_shader`:

   ```gml
   ///scr_drawReflections(_statObj);
   ```

   `_statObj` is a GameMaker 8 engine global that does not exist in GMS2, so the
   call could not simply be uncommented, and nobody ever revisited it. By the
   time it was looked at, all three of its inputs were wrong: it drew at
   `image_xscale` (a full-size reflection of a half-size tower), it sized its
   offset from `sprite_height` (fault 2 again), and it read `bbox_bottom`, which
   is the **MASK** - on a tower that is `spr_tower_click_region`, 32x64, with
   nothing to do with the art it was reflecting.

**Why it looked like something else.** Every one of these is *derived from the
sprite*, and every one was correct while all the art shared a shape. Swapping the
art did not change one line of water code - which is exactly why nothing pointed
at the water. The bug presented as "the water behaviour didn't translate
cleanly", as though the water were at fault, when the water was faithfully
obeying numbers that had stopped describing the art.

**Fix.** Stop expressing the waterline as a fraction. Derive it from the ORIGIN -
the one property every sprite in this project shares, and the thing the anchor
actually stands on - and express the depth in **screen pixels**, because how deep
water looks is a property of the water, not of the creature standing in it (a
boss is drawn twice as big and must not sink twice as deep).

```gml
/// How deep a thing standing in water is sunk, in SCREEN pixels - the ONE
/// number to tune if the water ever looks wrong.
function water_sink() {
    return 8;
}

/// The fraction of _sprite, measured from its TOP, that is ABOVE the waterline.
function water_line_keep(_sprite, _scale, _sink) {
    if(!sprite_exists(_sprite)) return 1;
    var _h = sprite_get_height(_sprite);
    if(_h <= 0) return 1;

    var _s    = (is_undefined(_scale) || _scale == 0) ? 1 : abs(_scale),
        _sink = is_undefined(_sink) ? water_sink() : _sink;

    /// the origin is the base; sink() screen px of it is under the surface
    var _keep = sprite_get_yoffset(_sprite) - (_sink / _s);
    return clamp(_keep / _h, 0, 1);
}
```

All four sites call it, so they agree **by construction** rather than by four
people reading the same comment: `obj_tower/Draw_0` and `obj_mon/Draw_0` crop with
it, `obj_water/Draw_0` draws the submerged tower through
`scr_draw_self_scaled(draw_scale)` instead of `draw_self()`, and
`scr_drawReflections` mirrors about the same seam. `water_line_report()` prints
one line per instance - canvas, origin as a fraction of it, scale, height left
visible - so the next person can read the numbers instead of arguing about them.

`sprite_get_yoffset()` / `sprite_get_height()` are the **unscaled** reads, which
is what is wanted here ([LL-033](#ll-033) again: `sprite_yoffset` carries
`image_yscale`).

The measured deltas against the old behaviour: a monster's seam moves 7.5px →
8px (unchanged to the eye), a plant's 3.1px → 8px. The plants are the ones that
read wrong next to each other, and `water_sink()` is the one knob.

**Guard rails.**

* **A crop expressed as a fraction of a sprite is valid for exactly one sprite.**
  Waterlines, ground contacts and baselines belong in the ORIGIN, or in
  world/screen pixels. *"0.8 of the height"* is not a design decision, it is a
  measurement of one drawing.
* **When a sprite's size or origin changes, grep the READERS.** The size alone
  (`draw_scale`) has readers in `scr_draw_self_scaled`, `scr_drawLight`,
  `scr_drawGlowOutline`, `draw_self_part`, `obj_water/Draw_0` and
  `scr_drawReflections` - and the water ones live in a folder nobody thinks of as
  "towers". LL-033 wrote this rule down and then this file found four more
  consumers it had missed.
* **One sign, one axis.** A helper taking two scale arguments needs both checked
  separately. A negative `draw_sprite_part_ext`/`draw_sprite_ext` scale flips the
  image *and* moves the anchor.
* **`bbox_*` is the mask; `sprite_*` is the art.** After LL-033 those are
  different shapes, and `bbox_bottom` on a tower is its click region.
* **Commented-out code is not dead, it is armed.** A call disabled through a port
  will be wrong by the time anyone enables it, and nothing will warn them.
  Either delete it, or fix it and turn it on.

**Status.** FIXED, 2026-10-13 - needs a run in `rm_test`; the look is the only
test there is.

**Files.** `scripts/draw_water_shader/draw_water_shader.gml` (`water_sink`,
`water_line_keep`, `water_line_report`), `objects/obj_water/Draw_0.gml`,
`objects/obj_tower/Draw_0.gml`, `objects/obj_mon/Draw_0.gml`,
`objects/obj_tower/Create_0.gml`, `objects/obj_mon/Create_0.gml`,
`scripts/scr_drawReflections/scr_drawReflections.gml`.

---

<a name="ll-044"></a>
## LL-044 — One stored counter served two questions, and the reader that was right hid the one that was wrong

**Symptom.** The HUD's **Wave** number read **one high** — during wave 1 it showed
`2`. The level log agreed with it, so the log looked like confirmation rather than
a second victim:

```
LEVEL  now SPAWN | stage 1-1 wave 2/15     <- during wave 1
```

`scr_zomb_pathSpeed` fed that same number to the speed ramp, so monsters walked as
if they were one wave further along than they were. No error, no crash, no unset
variable, nothing in the Output window: the game simply fought a slightly
different wave from the one it said it was on. And the **pre-wave banner was
correct throughout** ("Wave 1", then "Wave 2"), which is exactly what made it look
like nothing was wrong.

**Root cause.** `STATINV.waves` was **seeded at 1** in `_levelControl/Create_0`
while `wave_count` started at **0** in `scr_setupSpawning`, and `scr_level_spawn`
raised **both** by one as each wave began (`wave_count++`,
`add_item_value(waves,1)`). So during wave N the item read **N + 1** — the *next*
wave — and it had two consumers asking different questions:

| consumer | wants | read |
| --- | --- | --- |
| `scr_draw_statinv` (HUD item value), `scr_level_state` (log), `scr_zomb_pathSpeed` (ramp) | the wave being **fought** | one high |
| `scr_level_showPath` -> `scr_showWave` (the "Wave N" banner) | the wave about to **spawn** | correct — by accident |

The second row is the whole lesson: a reader that happens to be right is
**evidence for the wrong model**, and it is why this survived a reprice, a curve
change and two balance passes.

**Fix.**

1. `objects/_levelControl/Create_0.gml` — the item is the **current** wave, so it
   starts at 0 and now equals `wave_count`:
   ```gml
   set_item_value(waves,0);
   ```
2. `scripts/scr_level_showPath/scr_level_showPath.gml` — the one consumer that
   wants the *next* wave does its own arithmetic, at the point where the meaning
   differs:
   ```gml
   var _wave = get_item_value(waves) + 1;
   ```
3. `python_tools/gm/balance/sim.py` — `Sim.stat_waves` was `return wave + 1`,
   *restating the bug in Python*. It now **reads the seed out of the GML**
   (`tables.py` reads `set_item_value(waves,N)` into `constants.wave_seed`) and
   returns `seed + wave`, so the sim follows the game instead of holding its own
   opinion about it.

**Measured — and the honest part: the bug is real but SMALL.** `scr_zomb_pathSpeed`
applies its wave weight only when `_spd < 1`, and `_spd = ((12-z)/12)*1.5 + 0.5`,
so at `z=6` the weight is skipped entirely and the seed changes *nothing*; on slow
ground (`z=11`, `_spd = 0.625`) the monsters walk **0.2–0.5 frames faster** on
average (mean walk 89.1 -> 89.6) with money, kills and leaks identical. So this is
**not** a balance fix and no documented number moves. The reason it had to land
before `balance-fit-from-sim` is different: the **closed form already used the true
wave** (`model.demand` -> `terrain.walk_seconds`), so while the seed was 1 the sim
and the closed form were modelling the ramp **one wave apart** — and the fit solves
against both.

**Guard rails.**

* **A counter that answers two questions is two counters.** If a stored number is
  right for one reader and wrong for another, the right one is a coincidence, not
  a check. Name the meaning in the item's own comment, and make the odd reader do
  the arithmetic (`+ 1`) where the meaning actually differs.
* **If a tool models a bug on purpose, read the bug's parameter out of the GML.**
  A literal `+ 1` in Python models *the game as it was when the literal was
  written* — the sim would have kept modelling the old game after the fix. This is
  [LL-038](#ll-038)'s rule, applied to a single scalar: `constants.wave_seed`.
* **Spot it early.** `gm balance check` prints the seed, and
  `test_the_wave_counter_is_the_wave_being_fought` asserts it is 0 *with the
  reason in the failure message*, so a revert fails loudly instead of the two
  tools quietly diverging again.
* **A diagnostic that agrees with you is not a second opinion.** The log line and
  the HUD were the same wrong number; only the banner differed, and it was wrong
  to trust.

**Status.** FIXED 2026-10-14.

**Files.** `objects/_levelControl/Create_0.gml`,
`scripts/scr_level_showPath/scr_level_showPath.gml`,
`scripts/scr_level_state/scr_level_state.gml`,
`scripts/scr_zomb_pathSpeed/scr_zomb_pathSpeed.gml`,
`python_tools/gm/balance/sim.py`, `python_tools/gm/balance/tables.py`,
`python_tools/tests/test_balance.py`.

<a name="ll-045"></a>
## LL-045 — Ported dead code that had never run, and the three traps waiting inside it

**Symptom.** There was none, and that is the entry. `shd_outline` was a registered
`GMShader`; `scr_getOutlineShd()` and `scr_drawSelfOutlined()` both existed and both
looked like finished code. **Nothing in the project called either script**, so the
outline machinery had never drawn a single pixel in its life. It was found by
grepping for the two names *outside their own files* - the cheapest liveness test
there is:

```
grep -rn 'scr_drawSelfOutlined' --include=*.gml . | grep -v scripts/scr_drawSelfOutlined/
# (nothing)
```

**Root cause.** Three separate faults, each invisible until the first call - which
is why "it is already written, I will just wire it up" would have produced three
bugs at once:

1. **`draw_self()` draws at `image_xscale`.** On a tower that is **±1 FACING
   only**, because the art's size had to come out of it for the click mask
   ([LL-033](#ll-033)). So the helper would have drawn a full-size 192px tower
   with a 1px ring around it - and the ring is the one part that would have
   looked right.
2. **The shader took its colour from `v_vColour` and then threw `v_vColour` away.**
   `gl_FragColor = (v_vColour * (1.0 - originAlpha)) + texture2D(...)` uses
   `image_blend` for the ring and adds the **raw** texture, so the sprite's own
   pixels lose their tint. In this project `image_blend` is *also* the hover
   glow's colour, the reflection's colour and the water copy's colour - four
   subsystems on one variable, and the ring wanted to be the fifth.
3. **`shader_set()` with no guaranteed `shader_reset()`.** The ported helper had
   no reset path at all. A `return` added between the two would not crash - it
   would leave the shader bound and outline the rest of the frame.

**Fix.** An explicit uniform, and a draw path that knows the idiom:

```glsl
uniform vec4 outlineColor;                                      // passed in
vec4 body = texture2D(gm_BaseTexture, v_vTexcoord) * v_vColour;  // tint kept
gl_FragColor = mix(outlineColor, body, originAlpha);
```

plus the four DIAGONAL neighbours (the ported kernel was a plus shape, so corners
notched at 1-2px), and on the GML side `scr_outline_begin()`/`scr_outline_end()`
with every guard *before* `shader_set`:

```gml
if(!variable_instance_exists(id, "outline_ready") || !outline_ready) return;
if(!sprite_exists(sprite_index)) return;                 /// LL-012
...
shader_set(shd_outline);
shader_set_uniform_color(uniOutlineCol_, argument0, 1.0);
```

`scr_getOutlineShd()` became the setup step (`shader_is_compiled()` once, in
Create), so a shader that fails to compile degrades to "no ring" instead of a
half-drawn tower.

**Guard rails.**
- **Grep a function's name outside its own file before trusting it.** Ported code
  that has never run is not code that works; it is a hypothesis.
- **Ask a draw helper what it draws at.** `draw_self()` is `image_xscale`;
  `scr_draw_self_scaled()` is `draw_scale` ([LL-033](#ll-033)).
- **A shader's colour is an input.** Riding it on `image_blend` collides with
  every other user of `image_blend`, and this shader's body term drops it.
- **`shader_set`/`shader_reset` are a pair with no `return` between them** - and
  `shader_reset()` with nothing bound is a no-op, so call it unconditionally.
- **`shader_is_compiled()` at setup**, so a compile error is a missing feature
  rather than a broken frame.
- **GameMaker's hex colour literals are `$BBGGRR`**: `$FFD24A` would come out
  blue. Build colours with `make_colour_rgb()`.

**Status.** FIXED 2026-10-15.

**Files.** `shaders/shd_outline/shd_outline.fsh`,
`scripts/scr_getOutlineShd/scr_getOutlineShd.gml`,
`scripts/scr_drawSelfOutlined/scr_drawSelfOutlined.gml`,
`scripts/tower_levels/tower_levels.gml`, `objects/obj_tower/Draw_0.gml`,
`objects/obj_tower/Create_0.gml`, `objects/_levelControl/Step_0.gml`.

---

<a name="ll-046"></a>
## LL-046 — A blend mode belongs to the PASS, so an additive ring cannot carry the body with it

**Symptom.** Two of them, and the second one is the trap.

1. Ask for an **additively blended** tower ring and the obvious implementation
   (`bm_add` around the draw that already worked) turns every ringed tower into a
   **see-through, blown-out ghost**: its own pixels are added to the background
   instead of replacing it, so it glows over the ground and the art under it shows
   through. Nothing errors. The tower is still there, still clickable, still
   shooting - it just looks like a hologram.
2. Set the ring's opacity with **`draw_set_alpha(0.25)`** and *nothing happens*:
   the ring is exactly as solid as before. No error, no warning.

**Root cause.** Three mechanisms, all about who owns the fragment.

1. **A blend mode applies to the whole pass, not to the thing you meant to blend.**
   `shd_outline` drew the **body** (the tinted sprite) *and* the **ring** in one
   pass - `gl_FragColor = mix(outlineColor, body, originAlpha)` ([LL-045](#ll-045)).
   Wrap that pass in `bm_add` and the body is added too. A blend mode is a property
   of the draw call, so "blend the ring additively" cannot be expressed inside a
   pass that also draws something that must *replace*.
2. **`draw_set_alpha()` cannot change a shader's output.** It sets `v_vColour.a`,
   and this shader never reads `v_vColour` - it writes `gl_FragColor` itself. The
   opacity therefore has to be a uniform, and it was already half-built:
   `outlineColor` is a **`vec4`** and its fourth component was sitting there
   hardcoded to `1.0`.
3. **The alpha the shader did write was a COUNT, not an opacity.**
   `gl_FragColor.a = alpha`, where `alpha` was the sum of nine `ceil()` samples of
   the kernel (0-8). Under normal blending a count of 5 clamps to opaque and looks
   fine - which is why it survived. Under **additive** blending `alpha` is the
   **multiplier**: a count of 5 adds five times the colour, and - worse - any stray
   non-zero alpha in the quad's empty margin **adds light over the whole rectangle**
   instead of hiding it.

**Fix.** The ring pass draws the ring and nothing else, and the body is drawn
before it:

```glsl
// 1 only NEXT TO the art: 0 on the art itself (the tinted body is already
// drawn), 0 where there is no covered neighbour at all.
float ring = min(alpha, 1.0) * (1.0 - originAlpha);
gl_FragColor = vec4(outlineColor.rgb, outlineColor.a * ring);
```

```gml
function scr_drawSelfOutlined(argument0, argument1, argument2) {
	scr_draw_self_scaled(draw_scale);                    /// the BODY: normal, tinted
	scr_outline_begin(argument0, argument1, argument2);  /// the RING: additive, ring pixels only
	scr_draw_self_scaled(draw_scale);
	scr_outline_end();
}
```

The opacity rides on the colour's fourth component
(`shader_set_uniform_color(uniOutlineCol_, argument0, _alpha)`), the blend mode is
set **last** in `scr_outline_begin` - after every early return, so no return can
leak it - and `scr_outline_end()` puts it back beside `shader_reset()`.

**Guard rails.**
- **A blend mode belongs to the pass, not to the thing you meant to blend.** If a
  pass draws two things and only one should be blended, **split the pass**.
- **`draw_set_alpha()` does nothing to a shader that writes `gl_FragColor`.** Pass
  opacity as a uniform. (And use `shader_set_uniform_color`, which is this project's
  own wrapper for a `vec4` - it is not a GameMaker built-in.)
- **Never put a COUNT in `gl_FragColor.a`.** In a kernel loop `alpha` is a count;
  under additive blending it is a multiplier. Fold it with `min(x, 1.0)` first.
- **Under additive blending "invisible" means alpha 0, not "the background colour".**
  Anything with a non-zero alpha in a mostly-empty quad adds light - hence the
  `(1.0 - originAlpha)` term rather than relying on the colour to cancel out.
- **`bm_add` is `(bm_src_alpha, bm_one)`** - the source is weighted by its own
  alpha, which is exactly what makes "25% opacity" add a quarter of the colour
  rather than all of it. (`bm_max` is `(bm_src_alpha, bm_inv_src_colour)`, a
  different animal; the full factor table is on the `gpu_set_blendmode` page.)
- **Put the blend mode back in the same pair as `shader_reset()`.** A leaked
  `bm_add` is worse than a leaked shader: everything drawn after it is additive and
  there is no error to find it by.
- **Declare every parameter you READ, and test an omitted one by VALUE**
  (`is_undefined(argument2)`). `argument_count` reports the declared arity, not the
  call, and the argument list is sized to the DECLARED arity - so a function that
  declares two parameters and reads `argument2` is **out of range**, while one that
  declares three and is called with two gets a padded `undefined` ([LL-035](#ll-035)).
  `gm gml-functions <script>` prints the declared arity, which is how this one was
  caught: the body read `argument2` while the signature still said two.

**Status.** FIXED 2026-10-15.

**Files.** `shaders/shd_outline/shd_outline.fsh`,
`scripts/scr_drawSelfOutlined/scr_drawSelfOutlined.gml`,
`scripts/tower_levels/tower_levels.gml`, `objects/obj_tower/Draw_0.gml`.

---

<a name="ll-047"></a>
## LL-047 — `sprite_get_bbox_top()` is measured from the sprite CANVAS, not from the origin

**Symptom.** A label that is supposed to sit "above the sprite's head" comes out
**in the middle of it** - or, for a sprite whose origin is near its top, below its
feet. Nothing errors and the value itself is right, so it reads as "the label is in
a silly place" rather than as a units bug. Here: hovering a plant was to print its
level above the plant, and the first version printed it across the plant's stem.

**Root cause.** Two different things are called "the top of the bounding box", and
they are measured from different places:

| Thing | Measured from | For a sprite whose origin is at its feet |
| --- | --- | --- |
| `bbox_top` (the **instance variable**) | the room | positive, above `y` |
| `sprite_get_bbox_top()` (the **function**) | the sprite's **upper-left corner** | small and positive |

The manual says it exactly: *"This value is given as a relative value based on the
upper left corner of the base sprite asset being (0, 0)."* So
`y + sprite_get_bbox_top(sprite_index) * scale` is not the top of the art at all -
it is the top of the art measured down from a corner the origin has nothing to do
with. The conversion is to subtract the origin:

```gml
/// the top of the ART relative to the origin - NEGATIVE for a bottom origin
var _dy = sprite_get_bbox_top(sprite_index) - sprite_get_yoffset(sprite_index);
```

For this project's tower art that difference is large and negative, because every
sprite puts its origin at the plant's feet:

| sprite | size | origin | bbox_top | bbox_top - yorigin |
| --- | --- | --- | --- | --- |
| `spr_t3_idle` | 66x88 | (32,75) | 3 | **-72** |
| `spr_t1_idle` | 99x103 | (49,75) | 2 | **-73** |
| `spr_t4_idle` | 100x95 | (46,71) | 1 | **-70** |
| `spr_tower` | 32x32 | (16,16) | 0 | **-16** |

**Fix.** The difference, times the scale it is drawn at:

```gml
_top = _hov.y + (sprite_get_bbox_top(_hov.sprite_index)
                 - sprite_get_yoffset(_hov.sprite_index)) * abs(_hov.draw_scale) - 6;
```

**Guard rails.**
- **The `sprite_get_bbox_*()` functions are canvas-relative; the `bbox_*` instance
  variables are room-relative.** Convert with `sprite_get_xoffset()` /
  `sprite_get_yoffset()` before using either as an offset from the origin.
- **Check the numbers against a real sprite before trusting a position.** The four
  rows above came from one script over the `.yy` files, and they are what proved the
  first version wrong. A guessed offset would have looked "close enough" and been
  wrong on every sprite that is not the one you tested.
- **`sprite_exists()` first**: `sprite_get_bbox_top(-1)` is fatal ([LL-012](#ll-012)).
- **A newline ends a statement as soon as the expression is COMPLETE**, so break a
  long expression inside an unclosed bracket (or after a binary operator), never
  after a complete `(...)` group - GML would read the next line as a new statement.

**Status.** FIXED 2026-10-15.

**Files.** `objects/_levelControl/Draw_73.gml`.

---

<a name="ll-048"></a>
## LL-048 — Additive coverage double-counts, and a planner told only what it must not reuse can only duplicate

**Symptom.** Two things, one cause.

1. The balance sim said a stage **holds** (no leaks) while every tower stood on the same
   fifth of the map and the last quarter of the route was never shot. Nothing failed - the
   number just described a build nobody would make, and a leak there would have been
   invisible to the model that was supposed to predict it.
2. A full run earned $135 and bought **eleven $5 towers and no upgrade at all**, ending
   with $17 still in the purse.

**Root cause.** The budget greedy (`policy.plan`) ranked candidates by
`dps x coverage / price`, where coverage means "the share of the route THIS tower shoots".
Two towers over the same stretch of route **both** score that stretch, so the second one
looks as good as the first. The sum of per-tower coverage is not the thing being
maximised - a monster only dies once - so the objective was wrong, not the tuning.

Measured on stage 1-1's 1841px route, same $300:

| objective | towers bought | route actually covered | last quartile |
| --- | --- | --- | --- |
| additive (before) | 15 | **41%** | **0%** |
| union (after) | 14 | **100%** | 25% |

And the second half: `plan()` was passed `taken` - a set of CELLS it must not reuse - and
never the towers standing on them. So each wave re-planned from scratch, a rung on an
existing tower was not a candidate, and the only purchase it could ever make was another
cheap tower in a free cell.

**Fix.** Two changes, both in `policy.py`, both opt-in so published numbers stay put.

```python
# union coverage: what this cell shoots that NOTHING ELSE already shoots
def marginal(self, cell, reach, taken):
    ids = self.indices(cell, reach)          # route samples inside the reach
    return len(ids - taken) / float(len(self._samples()))

# and the planner is TOLD what is standing, so a rung is a competitor
bought = policy.plan(..., allow_rungs=True, spread=True, standing=standing)
```

Union coverage is **submodular**, which is exactly the setting where a density greedy
carries its `1 - 1/e` bound - so the greedy stayed the right tool and only its scoring
changed. Measured A/B on the same money, same wave, same seed:

| objective | towers | spent | widest target list | wasted swings |
| --- | --- | --- | --- | --- |
| additive | 16 | $143 | 6 | 33% |
| union | 11 | $143 | **3** | **25%** |

Fewer towers, less waste, and the route covered - so the *finding* that a 10-target cap is
unreachable got **stronger** (6 -> 3), which is why that test's threshold moved.

The sim then gained `--spend instant`, which re-runs the same greedy while a wave is
**live** instead of only at the wave boundary: **$2 left at the end instead of $17**, and
9 upgraded towers instead of 11 cheap ones.

**Guard rails.**

* **An objective that sums per-agent benefit over-counts whenever two agents can serve the
  same event.** Ask "what does the SECOND one add?" before trusting a sum of shares.
* **A planner that re-plans from scratch must be told what already exists**, or it can
  only ever duplicate. "Which cells are taken" is not "what is standing".
* **Pin two estimators of one quantity with a test.** `Coverage.of()` walks exact segment
  lengths (it is the figure the in-game panel is matched against, so it must not move) and
  `Coverage.indices()` samples every 4px (what union coverage subtracts). `test_the_two_
  coverage_estimators_agree` keeps them within 6% - otherwise the ranking optimises a
  different map from the one every published number was measured on.
* **When a finding's number moves, record WHY next to the new number.** The cap test now
  says 3 instead of 6 *and* says that the greedy stopped concentrating.

**Status.** FIXED 2026-10-15.

**Files.** `python_tools/gm/balance/policy.py`, `python_tools/gm/balance/sim.py`,
`python_tools/gm/balance/report.py`, `python_tools/gm/cli.py`,
`python_tools/tests/test_balance.py`.

---

<a name="ll-049"></a>
## LL-049 — A persistent instance's Create was the only thing that built the level

**Symptom.** The **second** level never loads. The stage room comes up - the walls and the
spawn points are all there, the fade finishes - but the ground never appears and **no waves
ever start**, and the screen just sits on an empty room. Nothing errors, nothing logs. The
first level is completely fine.

**Root cause.** Every non-persistent controller is created by one persistent instance.

```
rm_test creation order:  #1 Control  (persistent: true)   <- first instance in the room
Control/Create_0         instance_create(0,0,_mainControl)   <- the ONLY creator
_mainControl             persistent: false  -> dies on Room End
_mainControl/Step_0      scr_runState(scr_main_startup)      -> builds the terrain
scr_main_startup         ... -> cutscene -> instance_create(_levelControl)  <- the ONLY creator
```

A persistent instance is carried between rooms, and the GMS2 manual is explicit that it keeps
its **Game Start, Game End, Room Start and Room End** events - **Create is not in that list**,
because it already ran. So:

| on the second visit | what that costs |
| --- | --- |
| `Control/Create` does not run | `_mainControl` is never created |
| no `_mainControl` -> `scr_main_startup` never runs | no `ground_map`, no `load_max`, zero `scr_iniTileBuilder` calls - **no terrain** |
| no cutscene -> `_levelControl` never created | no `scr_level_step`, no path/placement grids - **no waves** |
| `Control/Other_5` (Room End) had destroyed the collider, particles, debree and bag | and Create was the only thing that rebuilt them |

That is why it reads as a *partial* load rather than a crash: the room's own placed instances
(`obj_wall`, `obj_spawn`, `obj_water`, `obj_graveCenter`, `obj_raiseGround`) are created
normally and **none of their Create events reads anything the boot owns**. I checked all five
before touching the code.

There is a second, quieter half: `_levelControl/Create_0` does
`ground_map = _mainControl.ground_map`, so the level depends on the boot having *finished*
before the cutscene runs - an ordering that only worked because the two were ten frames apart.

The repository already believed a second level existed: `scr_iniLighting()` says the
shadow renderer is persistent because "a later level - which re-runs startup, and
therefore this script - must reuse the instance that survived" (LL-020). The code for
the second level was written. The second level never ran.

**Fix.** The boot moved to the one hook that is guaranteed on every entry.

```gml
// rooms/rm_test/RoomCreationCode.gml   (runs on EVERY entry, after all Create events)
scr_level_boot();
```

```gml
// scripts/scr_level_boot - idempotent: clear, then build, then say so
function scr_level_boot() {
    with(_mainControl)  instance_destroy();
    with(_levelControl) instance_destroy();
    with(_viewControl)  instance_destroy();
    with(_dayCycle)     instance_destroy();
    level_data_ensure();
    var _row = stage_current();
    instance_create(0, 0, _mainControl);   // the rest of the chain hangs off this
    scr_meta_log("LEVEL", "boot ", _row.region, "-", _row.stage,
                 " waves=", _row.waves, "  main=", instance_number(_mainControl));
}
```

Two supporting changes, both because the same class of bug can come back by another route:

* **`Control` is non-persistent.** It is placed only in `rm_test`, so persistence bought
  nothing and cost the systems: Room End destroyed them and Create never rebuilt them.
  (`Input` is persistent but guarded by `instance_number(Input) == 0`, so re-creating
  `Control` cannot duplicate it.)
* **`scr_main_startup` builds the grid when it is MISSING**, not merely when
  `state_time == 0`, logs `terrain grid WxH max N seed S`, and logs `startup done rows=N`
  when the reveal ends. `rows=0` is now the one-line statement of "the terrain did not
  build". The `load_max` division is guarded too: `load_amount = load_counter/load_max` is
  `0/0` for the frames before the init block, which is a fatal GML error rather than a zero.

And one latent defect in the same path: `draw_fadeout` did

```gml
if(room != target){ room_goto(target); }
```

`room_goto` to the room you are **already in** does nothing, so a retry or a replay was a
silent no-op - the fade ran, the screen went black and came back, and the stage carried on.
`fadeout()` now takes an optional sixth argument and the branch is `room_restart()`, which
re-runs the room's creation code and therefore the boot.

**Guard rails.**

* **Never let a persistent instance's Create be the only thing that builds a room.** Create is
  a one-off; Room Creation Code and Room Start are the hooks that fire every time.
* **The room-entry order is: every instance's Create (in creation order) -> Room Creation Code
  -> Room Start.** Anything that must see the room's whole contents belongs *after* Create -
  which is also why `scr_gridSetObject()`'s `with(obj_raiseGround)` only works from a Step.
* **Give every boot a log line naming a count**, so "did it run" is a grep and not a guess.
* **`room_goto(current_room)` is a no-op.** Any retry path needs `room_restart()`.

**Status.** FIXED 2026-10-17.

**Files.** `rooms/rm_test/RoomCreationCode.gml`, `scripts/scr_level_boot/scr_level_boot.gml`,
`objects/Control/Create_0.gml`, `objects/Control/Control.yy`,
`scripts/scr_main_startup/scr_main_startup.gml`, `scripts/fadeout/fadeout.gml`,
`scripts/draw_fadeout/draw_fadeout.gml`, `scripts/ini_fadeout/ini_fadeout.gml`.

---

<a name="ll-050"></a>
## LL-050 — The save merge read the wrong struct, and the log printed only what survived

**Symptom.** The game "resets every time". Quit and relaunch and the world map shows only
1-1, bought towers are locked again and clover nodes are back to rank 0 - **but** seeds and
clovers are still there, and the loadout is still the four towers last deployed. Not a fresh
save: a *partial* one, which is why it read as a design problem for two playtests.

**The cause was a ten-line function.** `scr_meta_merge()` looped over
`variable_struct_get_names(_base)` - the DEFAULT's keys. For a nested map the default is
`{}`, so the loop body never ran, and the function returned that EMPTY map with
`_base[$ "version"] = scr_meta_version()` stamped into it:

    towers : {"version":1.0}      // was {"Burning Ivy":true, ...}
    stages : {"version":1.0}      // was {"1:1":0, ...}

Everything that is a struct was replaced by the stamp. Everything that is not - `seeds`,
`clovers`, `shards`, and the `loadout` ARRAY - took the `else` branch and survived.

**The proof was on disk, not in the game.** `garden_meta.dat` is plain JSON:

    {"towers":{"version":1.0}, "badges":{"version":1.0,"1:1:0":true},
     "stages":{"version":1.0,"1:1":0}, "seeds":48.0, "clovers":205.0, ...}

`towers` holding nothing but a version stamp is not a state the game can produce except by
merging into an empty map. `stages` holding the stamp AND `1:1` is the same file after one
more clear: `progress_record_clear()` wrote that key back *after* the wipe.

**Why it survived a playtest.** `scr_load_meta()` logged

    SAVE loaded version= seeds= clovers= shards=

i.e. **exactly the three fields the merge cannot lose**. A diagnostic that reports only the
parts that still work is not evidence that the rest works.

**Fix.**
* the merge iterates the LOADED struct's keys;
* an EMPTY struct in the default is an OPEN MAP (stages, clears, towers, badges, the node
  tables) and takes every key the file has; a POPULATED struct is a FIXED RECORD
  (`last_stage`) and merges key by key;
* scalars and arrays keep their default's TYPE, so a hand-edited save cannot make a later
  read throw (LL-002 applied to data);
* `version` is skipped during the merge and stamped once, on the top level, by the caller;
* the load log now prints `stages= clears= towers= nodes= badges=` - the maps, not just the
  scalars;
* `python_tools/gm/save/` inspects a real `garden_meta.dat` and exits 1 when it finds a stray
  `version` inside a map. It is a DETECTOR, not a second implementation of the merge.

**The rule.** **A merge must iterate the file, not the default** - and **a save log must print
the maps it could lose**, or the one bug that costs the player everything is the one the log
cannot see.

**Files.** `scripts/scr_meta_schema/scr_meta_schema.gml`,
`scripts/scr_load_meta/scr_load_meta.gml`, `python_tools/gm/save/__init__.py`,
`python_tools/gm/cli.py`, `python_tools/tests/test_save.py`.

**Status.** FIXED 2026-10-17. Schema is v2.

---


<a name="ll-051"></a>
## LL-051 — A slider is a modal drag, and a Draw event must not own input

**Symptom.** Two complaints about one screen: the volume sliders **do not apply until you
leave Options**, and reaching 0% or 100% **takes a second pass** because the mouse leaves
the track before you get there.

**Cause.** `show_slider()` did three jobs from inside `Menu/Draw_64`: it read the mouse,
wrote the global, and drew. Each job was wrong in its own way.

1. **Positional, not modal.** Every frame re-tested
   `point_in_rectangle(mouse, x1-16, y3-16, x2+16, y3+16)` - a 32px band around a 16px
   track. Drift out of it during a fast stroke and the drag silently ended mid-gesture.
2. **`lerp(_pt,_pos,0.25)`** approached the pointer asymptotically, so even inside the
   track the knob lagged and never quite arrived at 0 or 1.
3. **Apply-on-exit.** `scr_resetSoundVolume()` (two `audio_emitter_gain` calls) was called
   from `MENU_STATE.RETURN` and `scr_setup_menuStates` - never from the drag. Music already
   plays through `global.MUSemitter`, so applying the gain live was always a two-line no-op;
   nobody had called it.
4. **Input in Draw** is the pattern roadmap 5.6.2 already forbids - the Menu's buttons were
   moved out of it for exactly this reason, and the sliders were left behind.

**Fix.** A new script, `scr_menu_slider`, owns the geometry (`scr_slider_rect`) and the drag
(`scr_sliders_step`, called from the Options case of `Menu/Step_0`); `show_slider` became
draw-only. A press inside a track GRABS it, and from then on the value follows the pointer
**wherever it goes**, clamped to 0..1 - so the far end of the track is reachable in one
stroke. Release writes `gameoptions.dat`. A changed value is applied immediately:
`scr_resetSoundVolume()` for a volume, plus one throttled `snd_button` tick for Sound FX so
the new level is audible while you drag.

Splitting `scr_resetSoundVolume()` mattered too: it also called
`audio_channel_num((clutterDensity+0.1)*50)`, which would have reallocated the audio channels
**every frame of a drag**. The channel count moved to `scr_applyClutter()`, which runs when
the clutter slider moves and at boot.

**The rule.** **A drag is modal: grab on press, follow until release, clamp at the edges.**
And **the draw event draws** - geometry and input belong in Step, or the thing you test and
the thing you see drift apart.

**Files.** `scripts/scr_menu_slider` (new), `scripts/show_slider`,
`objects/Menu/{Create_0,Step_0,Draw_64}.gml`, `scripts/scr_resetSoundVolume`.

**Status.** FIXED 2026-10-17 (in-game confirmation pending).

---


<a name="ll-052"></a>
## LL-052 — A mirrored shadow that lands a whole tower to the right

**Symptom.** A tower turns to face left and its cast shadow does not "match the mirroring":
it flips, but it is displaced - on the 192px daisies, about a hundred pixels to the right.

**Cause.** `scr_drawLight` built the silhouette box from `sprite_xoffset`:

    _xn = x - view - sprite_xoffset*_art + _wn;

`sprite_xoffset` is the sprite's origin **times image_xscale**, so on a left-facing instance
it is NEGATIVE. The origin term therefore flipped sign the moment the tower turned, moving
the box by `2 * xoffset * draw_scale` (97px on a 192px sprite at draw_scale 0.5). The corner
swap that LL-012 added to mirror the TEXTURE was working perfectly - it was mirroring inside
a box that had already jumped.

This is the same family as LL-043's water bug, and `draw_self_part` documents the rule in so
many words: *"sprite_xoffset is the sprite's origin times image_xscale"*.

**Fix.** Derive the box from the UNSIGNED origin and mirror it about the origin:

    _xo = abs(sprite_xoffset)*_art;                  // origin, unsigned
    _l  = _flip ? _bx + _xo - _w : _bx - _xo;
    _r  = _l + _w;

with the corner swap kept for the texture. Monsters are fixed by the same line: their
`image_xscale` IS the size, so `abs(sprite_xoffset)` is already scaled and `sprite_width`
already includes it.

**The rule.** **A reader that multiplies by `sprite_xoffset` / `sprite_yoffset` is multiplying
by the facing sign.** Want the size? `abs()` it. This is the fourth way a flip dies, after
LL-012's three.

**THE SECOND HALF (2026-10-18) - it still landed to the RIGHT.** With the origin unsigned the mirrored shadow was STILL displaced, now by most of a sprite-width to the right, and only when mirrored. The remaining signed value was `_w = sprite_width*_art`: `sprite_width` is `sprite_get_width * image_xscale` - the same "dependent on the image_xscale" the manual uses for the origin - so on a left-facing tower it is NEGATIVE, and the flip branch reads

    _l = _bx + _xo - _w        // bx + 48 - (-96) = bx + 144
    _r = _l + _w               // bx + 48

a 96px box sitting 48..144px to the RIGHT of the plant. The un-mirrored branch uses `_w` in the other direction, which is why only the mirrored case was wrong.

    _w = abs(sprite_width)*_art,
    _h = abs(sprite_height)*_art,

plus a one-off `SHADOW  flip  w=...` line (per instance, dev-gated) so the sign is checkable in one run instead of one playtest.

**The rule, completed.** `sprite_width`, `sprite_height`, `sprite_xoffset` and `sprite_yoffset` ALL carry the image scale INCLUDING ITS SIGN. A reader that lays a box out with one of them must `abs()` every one of them - fixing one signed term and leaving the next is how this took two sessions. Monsters are unaffected (their `image_xscale` IS the size, and it is positive), which is why the symptom looked tower-specific.

**Files.** `scripts/scr_drawLight/scr_drawLight.gml`.

**Status.** FIXED 2026-10-17; second half 2026-10-18 (in-game confirmation pending).

---


<a name="ll-053"></a>
## LL-053 — The stage could not be lost, only quietly handed to the arcade screen

**Symptom.** None, until you look for it: losing your last life never produced the new flow's
failure. It produced the OLD one - the screen froze, everything was deactivated, and a
high-score table appeared - and the meta layer never heard about it.

**Cause.** Two controllers owned the end of a stage. `_levelControl` had
`LEVEL_STATE.CLEAR` and **never requested `LEVEL_STATE.FAILED`**; the enum member existed and
nothing wrote it. Meanwhile the legacy `scr_main_normal()` still ran
`if(life <= 0) scr_changeState(scr_main_gameOver)`, which fades to `rm_score`. A lost stage
therefore ran the arcade path *underneath* the new flow, which carried on as if nothing had
happened: no seeds withheld, no badges skipped, no save written, no results.

**Fix.** `scr_level_step()` checks `life <= 0` **before** the state switch and requests
`LEVEL_STATE.FAILED` (returning for one frame, so a wave cannot also request CLEAR and pay
the player for a stage they just lost). `scr_level_failed()` pays nothing and takes nothing
(goal.md 27.3), writes the save, moves the run cursor and returns to the world map. The
legacy branch in `scr_main_normal()` is gone - one controller owns the end of a stage.

**The rule.** **A terminal condition needs a state, not a side effect.** If a state can only
be entered by an object that might not exist, the flow does not have that state - it has a
gap that the oldest code in the project will fill.

**Files.** `scripts/scr_level_state/scr_level_state.gml`,
`objects/_levelControl/Create_0.gml`, `scripts/scr_main_normal/scr_main_normal.gml`.

**Status.** FIXED 2026-10-17 (in-game confirmation pending).

<a name="ll-054"></a>
## LL-054 - A slow-firing tower never fires, because the fire period WAS the swing

**Symptom.** The Pina Collider (fire_rate 0.10) never damages anything: it stands
through a whole stage, or winds up and gives up. The Slender Mandrake (0.35) is
nearly as bad. Nothing errors and the fast towers are fine - so it reads as "the
attack timer is frozen until a monster is in range", which is close to the truth.

**Root cause.** Three things all said "the fire period is the length of the attack
animation".

1. `scr_tower_shoot` set `frame_number = room_speed/fire_rate`, played the
   5-frame attack sprite over it - 600 frames, ten seconds, for the Pina - and put
   the damage frame at the END of that swing (`frame_number - time_offset`).
2. It returned to idle the moment its cached target left RANGE. A zombie crosses a
   75-125px range in about a hundred frames, so a 600-frame strike frame was never
   reached: the swing was always cancelled first.
3. `scr_tower_normal` only started looking after `state_time > time_offset`, and
   `state_time` resets on every state change - so the attack timer only existed
   inside the swing. Idle time was not banked at all.

The only way that tower could fire was a monster standing in range for ten seconds.
None does.

**Fix.** The rate is a COOLDOWN, the animation is art, and a started swing commits.

* `attack_timer` on `obj_tower` ticks in EVERY state, in `obj_tower/Step_0`, whether
  or not anything is in range - that is the "ready to fire" the tower was missing.
  `attack_cycle = tower_cycle_frames(rate, return_seconds) + time_offset`: the fire
  period PLUS the return PLUS the tower's own stagger, which is the cycle LL-040 and
  the balance closed form already assume, so no fast tower's delivered rate moves.
* `swing_frame = min(fire period, tower_swing_seconds()*fps)` - the attack sprite
  plays for ~0.35s (never longer than the period) and the damage lands near the end
  of THAT, so a slow tower strikes in a third of a second.
* `scr_tower_shoot` abandons a swing only when every cached target is DEAD, not when
  one walks out of range: the monster was in range when the swing began.
* `tower_levels.gml` owns `tower_fire_period`, `tower_cycle_frames` and
  `tower_swing_seconds`. `tables.py` reads them and `sim.py` mirrors the machine, so
  the game and the tester cannot drift (LL-038, LL-040, LL-042).

**One finding moved.** The sim no longer fires FEWER shots than the closed form:
with the wait running during the animation the transition frames are absorbed, so
`real` and `nominal` agree. `test_the_state_machine_fires_slower_than_the_idealised_cycle`
now asserts the direction that still matters - the closed form is never optimistic -
and says so in its docstring. That is information about the model, not a weakened
assertion: every real tower still loses the frames it spends with nothing in range.

**Guard rails.**
* **A rate is a timer, not an animation length.** If two quantities are ever
  assigned the same expression, ask which one is allowed to move independently.
* **A timer that only runs while it has something to do is not a timer.** Tick it in
  the state machine's Step, before the state runs.
* **A swing that has started must commit.** Cancelling on "target out of range"
  turns a slow attacker into no attacker.
* **Log the first shot** (`TOWER  first shot  rate=... period=... swing=...`): a tower
  that never prints it is not attacking, and that is one grep, not one playtest.

**Files.** `scripts/scr_tower_normal`, `scripts/scr_tower_shoot`,
`objects/obj_tower/{Create_0,Step_0}.gml`, `scripts/tower_levels`,
`python_tools/gm/balance/{sim,tables}.py`, `python_tools/tests/test_balance.py`.

**Status.** FIXED 2026-10-18 (in-game confirmation pending).

---


<a name="ll-055"></a>
## LL-055 - A three-second hold is not 180 frames, and 60% of the viewport is not 60% of the canvas

**Symptom.** A planned Level Complete card would have lasted one second instead of
three with fast-forward on, come out at 37% of the screen height instead of 60% (or
spilled past both edges), and been covered by the tower list and the speed buttons.

**Root cause.** Three ways to be wrong about "the same thing the player sees".

1. The project runs at 60 steps a second, but `scr_setFrameSkip` sets
   `room_speed = 180` for fast-forward. A hold counted in FRAMES is three times
   shorter in real time the moment the player uses it.
2. `spr_level_complete` is a 200x100 canvas whose art occupies 165x62. Scaling the
   CANVAS to 60% of the port makes the visible banner 37%; scaling the ART to 60%
   makes the canvas 1045px wide, past the 960px GUI. Which rectangle "60%" means
   decides both the size and whether it fits.
3. The stage HUD is drawn in three places (`_levelControl/Draw_64`, the build list
   inside it through `list_opacity`, and `_mainControl/Draw_75` for the speed
   buttons), and `draw_set_alpha` does not compose with the per-draw alpha those
   sprites already pass.

**Fix.** `scr_level_clear` runs the sequence on `delta_time` (clamped per step, so a
stall cannot skip a beat) - a real-time clock that is also pause-safe, because a
pause stops the Step. One function per beat (`level_clear_*_seconds()`) so it can be
retimed in one place. The banner is measured from the sprite's automatic bbox and
positioned by the ART's centre (`(bbox centre - origin) * scale`), so the placeholder
and a redraw land identically. One `level_ui_alpha` on `_levelControl` is read by
every piece of the stage UI (through `with()` where the variable belongs to another
instance), and the pieces that pass explicit alphas multiply by it.

**Guard rails.**
* **Any duration the player perceives is seconds, not frames**, because this
  project ships a fast-forward that changes the step rate.
* **"N% of the viewport" has to say WHICH rectangle** - port, GUI, canvas or art -
  and the answer should be the one the player can see.
* **A fade is only as wide as its alpha reaches**: `draw_set_alpha` is overridden by
  `draw_sprite_*_ext`'s own alpha argument.

**Files.** `scripts/scr_level_state`,
`objects/_levelControl/{Create_0,Step_0,Draw_64}.gml`,
`objects/_mainControl/{Create_0,Step_0}.gml`,
`scripts/{scr_drawSpdBtns,scr_view_zoom,scr_view_idle}`, `sprites/spr_level_complete`.

**Status.** FIXED 2026-10-18 (in-game confirmation pending).

<a name="ll-056"></a>
## LL-056 - A bar is a clamped ratio, and its denominator is data

**Symptom.** A monster HP bar draws with a **negative width**: the orange fill
appears to the LEFT of the black outline, sometimes a long way out. It is most
often a boss that has just been killed, or a monster that is still emerging.

**Root cause.** (`obj_mon/Draw_73`)

    var _x2 = lerp(_xa+1, _xb-1, data[MON.life]/data[MON.maxLife]);
    draw_line_width(_xa+1, _y2+1, _x2, _y2+1, 3);

`lerp` with a ratio outside 0..1 **extrapolates**, and `life` really does leave
the range:

* `scr_do_damage` subtracts the WHOLE hit - a Pina Collider does 250 - and the
  death check (`scr_zomb_death`) only runs inside `scr_zombie_path`. A monster
  killed by a tower that steps later in the same frame therefore has `life < 0`
  for the rest of that frame, and it still draws.
* `scr_zombie_emerge` sets `life = maxLife` at **step 60**, so every shot fired
  at an emerging monster is erased there (card `emerge-resets-life`) and the bar
  is negative for up to a second of real time first.
* `maxLife` is data. A zero row divides by zero, and `lerp` of an infinity is
  not a bar.

**Fix.**

    _max   = data[MON.maxLife],
    _ratio = (_max > 0) ? clamp(data[MON.life] / _max, 0, 1) : 0,
    ...
    if(_xb - _xa >= 2){
        draw_line_width(_xa+1, _y2+1, lerp(_xa+1, _xb-1, _ratio), _y2+1, 3);
    }

plus a one-off `MON  life<0  <name>  life=x/max  bar=%` line, so an overdraw is
named instead of inferred.

**Guard rails.**
* **A bar is `clamp(value/max, 0, 1)`.** Any other arithmetic can draw outside
  its own track, and the symptom looks like a drawing bug when it is a data one.
* **Guard the denominator** - `maxLife` is a table value, so it can be 0.
* **A Draw event must not be the first place an invariant is checked.** The
  monsters were allowed to be at `life <= 0`; the bar was the first reader to
  care.
* A zero-sized sprite (the emerge starts at `image_xscale = 0`) collapses the
  bbox, so skip the fill when the track has no width rather than drawing a
  1-pixel dot at the origin.

**Files.** `objects/obj_mon/Draw_73.gml`.

**Status.** FIXED 2026-10-18 (in-game confirmation pending).

---


<a name="ll-057"></a>
## LL-057 - A message box is a QUEUE: write the portrait to the message that will be drawn

**Symptom.** The "Up Next..." popup shows the previous creature's portrait
beside the new creature's name. With two bosses that reads as "Tusk-A-Lot and
Sub-Zero are swapped".

**What it was NOT.** The art and the table both agree, and it is worth knowing
the check: `spr_tusk_portrait` is the boar and `spr_tusk_walk` is the boar;
`spr_zero_portrait` is the blue hood and `spr_zero_walk` is the blue hood; each
`.yy` frame name matches the PNG in its folder, and no code writes
`MON.portrait` except the one table row per creature. A centre-of-face colour
sample settles which portrait file is which when the eye is not sure.

**Root cause.** `show_portrait_box` stores the portrait per MESSAGE
(`message_portrait[message_end]`) while `obj_textbox/Draw_64` draws
`message_portrait[message_current]` - and `show_message_box` **APPENDS** to a
box that already exists. So a second preview in the same box wrote its portrait
one index ahead, and the box kept rendering message 0 (the PREVIOUS creature)
with message 0's portrait. Nothing errors: every sprite involved exists.

**Fix.**

* a preview starts a FRESH box - `if(instance_exists(obj_textbox)) instance_destroy(obj_textbox)` -
  because two popups at once is never what is wanted;
* the wrapper writes its portrait to **every** message the box holds, so the
  displayed message cannot be the one without it;
* `scr_makeMonster` defaults every slot the enum names (`debree = 0`,
  `portrait = -1`), so a row is complete before `scr_setupSpawning` fills it,
  and `-1` (none) is a value both readers guard on;
* `LEVEL boss bank: 0=Tusk-A-Lot walk=... portrait=...` is printed once at
  setup, and `LEVEL up next: ... portrait=...` on every preview - the pairing
  is now observable instead of argued about;
* `python_tools/tests/test_content.py` asserts the portrait column is a
  **bijection** (every creature has one, no two share one, every named sprite
  exists). A duplicated or missing portrait now fails the suite.

**Guard rails.**
* **Store data against the thing that will read it.** A queue indexed by
  `message_end` and read by `message_current` will disagree the moment anything
  appends.
* **"The assets are swapped" is a claim you can test in a minute** - frame
  names, `.yy` names, colour, and the one table that pairs them. Do that before
  editing art.
* **A silent fallback is a bug of its own**: a row with no portrait drew
  *nothing* and looked like a layout problem. `-1` plus a log is cheaper.

**Files.** `scripts/show_portrait_box`, `scripts/scr_wave_preview`,
`scripts/scr_makeMonster`, `scripts/mon_enums`, `scripts/scr_setupSpawning`,
`python_tools/tests/test_content.py`.

**Status.** FIXED 2026-10-18 (in-game confirmation pending; the name/portrait
pairing itself may still be a naming decision).

<a name="ll-058"></a>
## LL-058 - A passive popup must not read a queue it does not own

**Symptom.** The "Up Next..." popup named one creature and the wave sent
another - *often*, in the player's words, and with no pattern: "almost like it
is random". It began **on the third level**.

**That last detail is the whole diagnosis.** `stage_data` gives 1-1 and 1-2
`spawns = [0]` - ONE creature - and 1-3 is the first stage with `[0,1]`. With a
single entry a preview cannot be wrong, so a defect that had existed since wave
1 of stage 1 had been invisible for two stages and became a coin flip on the
third. **A symptom that appears on a particular stage is a data precondition,
not a new bug**: find what the stage changed (here: the pool size) and look
*backwards* from it.

**Root cause - three defects, any one of them enough.**

1. **The portrait was per MESSAGE, drawn per `message_current`.**
   `show_portrait_box` wrote `message_portrait[message_end]`,
   `obj_textbox/Draw_64` read `message_portrait[message_current]`. Two indexes
   that agree only while the box holds exactly one message.
2. **`show_message_box` APPENDS to a live box.** So a second preview added
   message 1 while the box kept drawing message 0 - the PREVIOUS creature,
   with the previous portrait, under the new name.
3. **The box was destroyed and re-created in the same step**, which is not
   reliable: a destroyed instance is only dropped at the end of the step
   ([LL-031](#ll-031)), so `instance_find` can hand back the dying one and the
   new text lands in a box that is about to disappear.

And one silent hazard that would make a *real* mismatch unreadable:
`scr_level_spawn`'s fallback called `scr_level_pick_spawn` again - the exact
re-roll the design forbids - and printed nothing.

**Fix.**

* `obj_textbox.portrait` is **one sprite for the whole box**; `Draw_64` draws it
  with no index at all, so there is nothing left to disagree with. `-1` = none,
  and the old frame-of-`message_sprite` path still works for the cutscene.
* `show_portrait_box` **resets** the live box (one message at slot 0, typewriter
  clock at 0) instead of appending or replacing it.
* The decision is **one struct** - `next_pick { wave, is_boss, index, name,
  portrait }` - made by `scr_level_pick_store`, which is **idempotent per wave
  number**: asking again for a wave already decided returns the FIRST answer.
  Popup and wave are two readers of one answer.
* `scr_level_spawn` compares the promise with the delivery and logs
  `LEVEL WARNING ...` if the wave, the row, the bank or the controller count
  disagree. It also clamps a pick with no row instead of indexing a bank with -1
  ([LL-002](#ll-002)).
* The popup names the **wave** (`Up Next...  wave 12`), so a player reports two
  numbers instead of two pictures - and the numbers say which half is wrong.

**Guard rails.**

* **One decision, one struct, and let it carry the wave it was made for.** An
  `is_boss, index` pair cannot prove itself: the same index means a different
  creature in the other bank, so any disagreement about `is_boss` silently
  swaps the monster.
* **Any decision made with `irandom` must be idempotent per key.** If a function
  that rolls can run twice for the same key, it will - a state re-entry, a
  double Step, a rebuilt controller - and everything that already showed the
  first answer is now lying.
* **A popup resets; a dialogue appends.** `show_message_box` is right for a
  cutscene and wrong for a passive popup, and the two must not share a code
  path that can append.
* **Never destroy and re-create an instance in the same step to "replace" it.**
  Overwrite the live one; the dying one is still in the list.
* **A fallback that can change an answer must log.** `if(...) { re-roll }` with
  no output is a bug that hides itself.
* **Read a generated file back before believing it.** Three of the files in this
  fix were written by a build script, and one write silently dropped leading
  tabs - and, in a second file, `_is_boss = ` and `_in` from four lines. Braces
  were still balanced, so `roundtrip`, the brace check and `gml-functions` all
  passed: the function still *existed*, it just could not run. A file you did
  not type by hand is proven by a `repr()` of its lines, not by how it renders.

**Files.** `objects/obj_textbox/{Create_0,Draw_64}.gml`,
`scripts/{show_message_box,show_portrait_box,scr_wave_preview,
scr_level_pick_spawn,scr_level_wait,scr_level_spawn,scr_level_start}`,
`objects/_levelControl/Create_0.gml`, `python_tools/tests/test_content.py`.

**Status.** FIXED 2026-10-18 (in-game confirmation pending).

<a name="ll-059"></a>
## LL-059 - Everything at one depth is not "sorted"

**Symptom.** Zombies drew over plants they were standing behind, and two
zombies crossing each other could swap order. Nobody had made the graphics
worse; it had always been like this.

**Root cause: there was no sorting at all - only three opinions.**

| Actor | Depth | Consequence |
| --- | --- | --- |
| monsters | a flat `-60`, written in three places | one plane: never sorted against each other, never sorted against plants |
| plants | `-60 - (y>>5)`, at placement | always <= -62, so **in front of every monster, wherever either stood** |
| 6 gravestones | `-(y/room_height)-50` | in an 800px room that is one flat value for all six |

Nothing was wrong with any single line. The bug lived in the *relationship*:
three different formulas cannot produce one draw order.

**Fix.** One function, `scr_depth_y(y)` in `scripts/scr_setDepth` (which held a
dead GM8 `depth = (room_height-y) >> 2` - note the direction: a larger y gave a
LARGER depth, i.e. behind). `depth = -60 - y/32`, plus a 1e-5 tie-break from
`id`, and a second entry point `scr_depth_band()` with no `id` for log lines.
Monsters derive it in `obj_mon/Step_0` **every step** (a moving thing has to sort
from the frame it crosses, not from the frame it spawned); plants and
gravestones derive it once, at creation.

**Guard rails.**

* **"Sorted" needs one formula, not one value per class.** If two object types
  pick their own depth expression, the relationship between them is decided by
  arithmetic nobody wrote down.
* **An actor's depth is a VIEW of its position, so it is re-derived when the
  position changes.** Set it in the Step event that runs in every state, not in
  the state scripts - a monster in its emerge or death animation is on screen
  too.
* **Sort by the origin, and make sure the origin IS the feet.**
  `spr_grumble_walk` is 160 tall with `yorigin 150`, `spr_daisy_idle_192x` is 192
  with `yorigin 158`, `spr_graves` is 64 with `yorigin 53` - all three stand on
  their origin, which is why one formula works for all of them. A sprite with a
  centre origin needs half its height added, and that is a different formula.
* **A quantised depth ties.** The plants' `y>>5` put everything in the same
  32px row at one depth; the float `y/32` is what lets a zombie stand BETWEEN
  two plants instead of sharing their plane.
* **Two instances at equal depth are drawn in creation order**, which for a
  queue of monsters is an order that changes as they jostle - a flicker. The
  tie-break must be smaller than the depth difference between two pixels of
  ground (1/32), or it reorders real positions instead of breaking ties.
* **Log the band once per level** (`DEPTH` prefix). A depth mistake looks like
  an art mistake in a screenshot; the number makes it arithmetic.

**Files.** `scripts/scr_setDepth`, `objects/obj_mon/{Create_0,Step_0}.gml`,
`scripts/{scr_zombie_emerge,scr_zombie_path,scr_level_spawn}`,
`objects/obj_spawn/Create_0.gml`, `objects/obj_tower/Create_0.gml`,
`objects/obj_tower_edit/Step_0.gml`, `scripts/scr_level_boot`.

**Status.** FIXED 2026-10-18 (in-game confirmation pending).

<a name="ll-060"></a>
## LL-060 - A rule with three readers has to be one number

**Symptom.** The card said "stage bosses are not authored"; the real problem was
that the boss RULE existed in four places and each said something different.
Play rolled a boss on waves divisible by the region's `boss_every` (10), the
stage's own named finale was a boss only for 1-10, the curve diagnostic used the
`boss_every` cadence, and the balance tester encoded all of it again in Python.

**Root cause.** A gameplay rule is data, and this one had been copied as a
*number* and as a *condition* into every reader. Changing the game's rule then
required finding every copy, and nothing failed when you missed one: the curve
just confidently projected a boss wave that play had stopped sending.

**Fix (decided by rayu 2026-10-18: one mid boss and one end boss per stage, both
authored).**

* `stage_data` rows author `bosses = [mid, end]` - an ORDERED pair, both
  indices into `spawn_boss`. `irandom` is gone from the boss path entirely.
* The mid WAVE is derived once, in `GameLevelData`: `boss_wave = waves div 2`,
  so it cannot go stale against the stage's wave count (15 -> 7, 60 -> 30).
* `scr_level_pick_spawn`, `scr_curve_is_boss_wave` and
  `tables.is_boss_wave` all read that same `boss_wave` and the same finale test.
* `region_data.boss_every` stays in the row, marked legacy, so a reader cannot
  mistake its presence for its being used.

**Guard rails.**

* **A rule that gameplay and a tool both know is a number to share, not a
  condition to copy.** Put it where both can read it (a derived field on the
  level struct), and give the tool a test that fails when its mirror disagrees.
* **When a rule changes, the tests that encoded the OLD rule must change too** -
  three of them did (`test_boss_wave_rule`, the demand test, the payout test).
  A test that still asserts the old rule is not protecting you; it is lying.
* **A boss is authored, not rolled**, when the player is meant to learn it. The
  fallback for a stage that names none is still random, and it is LOGGED, so
  authored data can never be confused with an accident.

**Status.** FIXED 2026-10-18.

<a name="ll-061"></a>
## LL-061 - A percentage applied after rounding is not a percentage

**Symptom.** "A leak pays half instead of nothing" shipped, and the first test
run showed the purse had barely moved: 20 leaks had paid 1 in total.

**Root cause.** `floor(kill_money * 0.5)` is `0` when `kill_money` is `1`. The
cheapest creature pays 1 money, so half of it, floored, is the nothing the
change was meant to replace. The percentage looked fine and was a no-op on the
only numbers that matter.

**Fix.** The scale is applied to the UNROUNDED amount, inside the payout rule:
`scr_kill_money(base, wave, ramp, scale)` multiplies into the same `money_carry`
the difficulty column already uses (LL-042), and the sim mirrors it
(`_payout(scale=)`). Two leaks of a 1-money creature then pay exactly 1 between
them.

**Guard rails.**

* **Multiply before the floor, or the fraction disappears.** Any "pay 50%" on an
  integer currency has to share the same carried remainder as everything else.
* **Carry, do not round, at the payout site** - LL-042 again, and this is the
  third bug with that shape.
* **Test the SMALLEST value, not the average.** `0.5 x 1` is where a percentage
  dies; `0.5 x 100` passes any test.

**Status.** FIXED 2026-10-18.

<a name="ll-062"></a>
## LL-062 - A function that reads the caller's scope cannot be extended

**Symptom.** None yet - the symptom was an absence. Crit could not be added.
Every route ran into the same wall: `scr_do_damage(array, index)` had no
amount, so a multiplier rolled at the tower had nowhere to go.

**Root cause.** `scr_do_damage` subtracted `damage_calc`: an instance variable
declared on `obj_tower` and SET BY THE CALLER (`scr_tower_shoot`). So the
function's behaviour depended on whose scope happened to call it - AGENTS
rule 6, in the one place where being wrong is expensive. Three consequences,
in order of when they would have bitten:

1. **Crit had no home.** A multiplier applied at the tower cannot reach a
   function that also serves splash, because splash needs a different number.
2. **A second caller would have dealt the wrong number, silently.** A burn
   tick or an AoE calling it would have subtracted whatever the tower last
   left in `damage_calc`. No error, no warning - just a number from another
   instance.
3. **`for_array` could not carry it.** That helper runs a NAMED script
   through `run_script` with exactly `(array, index)`, which is why the
   variable existed in the first place.

**Fix.** `scr_do_damage(_arr, _ind, _amount)`; the tower passes `shot_damage`,
locked when the swing starts. `damage_calc` is deleted from the project (a test
greps every `.gml` for it). The strike loop is written out rather than
`for_array`, because a three-argument call is clearer than a closure or a
global.

**Guard rails.**

* **If a function needs a value, it takes it as a parameter** - even when only
  one caller exists today. The second caller is where a scope read becomes a
  wrong number instead of an error.
* **Per-swing state is fine; per-scope input is not.** `shot_damage` lives on
  the tower because a swing spans frames. The difference is that the function
  is TOLD it, not reading it.
* **A callback helper with a fixed signature is a limit, not an obstacle to
  route around.** A short explicit loop beats a closure whose only purpose is
  to satisfy `run_script`.
* **Prove a refactor with an unchanged table.** `gm balance project
  --all-waves` and `gm balance sim` were captured before and after and
  diffed: byte-identical. That is the only honest proof that a "no behaviour
  change" refactor changed no behaviour - and it costs one command.

**Status.** DONE 2026-10-18 (balance tables identical; in-game confirmation
pending, card `combat-damage-pipeline`).

<a name="ll-063"></a>
## LL-063 - A test that asserts a LINE fails when the editor rewrites the line

**Symptom.** `test_the_tiebreak_cannot_reorder_two_different_y` passed twice in
one session and then went red, with no edit to the test, the GML, or anything
that imports them.

**What actually happened.** `scripts/scr_setDepth/scr_setDepth.gml` and its
`.yy` carried the SAME mtime, to the millisecond, minutes after the last green
run: GameMaker saved the asset from its own buffer (AGENTS rule 1, LL-008), and
the buffer's version of one line was `irandom(97) * 0.00001` where the disk had
`id mod 97 * 0.00001`. The test asserted the *string* `id mod 97`, so it was
measuring the buffer rather than the behaviour.

**Why it matters.** A test that names a line of code is a second copy of that
line. When the two disagree, the test reports the disagreement as a failure -
which reads as "the game is broken" when nothing about the game changed. Both
versions are the same behaviour: a random tie-break of at most 0.00097 of a
depth unit, rolled once per instance.

**The rule.**

* **Assert the property, not the expression.** Here: the buffer must be rolled
  ONCE (`variable_instance_exists` guards it - a per-frame random is the very
  flicker it exists to prevent) and it must be smaller than 1/32 of a depth
  unit, so it cannot reorder two different y. Which random it is does not
  matter.
* **When a test changes colour with no edit, check mtimes before theories.**
  `ls -l --time-style=full-iso` on the asset and on the test. Two files of one
  asset sharing an mtime to the millisecond means the IDE wrote them.
* **A comment describing a mechanism the code no longer uses is the same class
  of lie as a stale doc** - and it is what made the test's wrong assumption
  look right in the first place. Fix the comment in the same edit as the test.

**Status.** Comment and test now describe `irandom(97)`; the behaviour never
changed and the depth card stays validated.

---

<a name="ll-064"></a>
## LL-064 - A loop that ends at the end of the file replays the ENDING

**Symptom.** The music fades out in the middle of a stage, sits quiet for a
couple of seconds and comes back in - and `audio_is_playing()` says it never
stopped, because it never did. On the menu the same thing happens every ~177 s,
which is where it is most obvious: a player can sit on that screen for minutes.
The log says the loop was set up correctly:

```
META  [MUSIC] region 1 "Wilted Sprouts" mus_world1 (ref) loop 0 -> 163.53s (whole track)
```

**Root cause.** `music_data` had **one** loop field. `loop_in` was the chorus
start, and `scr_music_start_level` set `audio_sound_loop_end()` to
`audio_sound_length()` - the end of the file. That is the manual's "Intro &
Outro" shape, but it assumes the outro is *inside* the loop or absent. These
seven tracks are intro / body / breakdown / body / **outro fade**, so every
cycle went through the fade: the music was working exactly as instructed and the
instruction was wrong.

The menu was the other half. `obj_title` and `Menu` called
`scr_playMusic(music_menu().sound, true)` and **never set loop points at all**,
so they repeated the whole file - 24.7 s intro and 7.7 s outro fade included.
Two paths to the same audio call, one of them with the rule and one without, is
how the menu kept the bug after the stage path was written
([LL-034](#ll-034) is the same shape: one path guarded, one not).

**Fix.** A section has **two** ends.

* `music_row()` takes `loop_in` **and** `loop_out`; `music_data` carries the
  measured pair for all seven tracks.
* `scr_music_apply_loop(row)` is the ONE place that calls
  `audio_sound_loop_start()` / `audio_sound_loop_end()`, and it returns what it
  actually applied so the caller logs the truth.
* `scr_music_start_menu()` is the menu's counterpart to
  `scr_music_start_level()`, and all four menu call sites now use it.
* The log ends in `(section)` rather than `(whole track)`, with both ends.

The points were measured, not guessed: a 20 ms RMS envelope against each track's
median level (0.9x it) finds where the intro reaches full level and where the
final outro falls away, then both are snapped to the bar grid at the track's
BPM. *Wilted Sprouts* comes out `14.63 -> 152.20` - 137.6 s of body, which is
what a 3-5 minute stage should be hearing.

**Guard rails.**

* **"Loop to the end of the file" is a bug by construction for any track with an
  outro.** If a file has an ending, the loop has to stop before it.
* **A sentinel must not collide with a legal value.** `loop_in = 0` is a real
  start (region 5 has no intro), so "unset" is `-1` here. Same class of mistake
  as [LL-004](#ll-004) and [LL-044](#ll-044).
* **One path per rule.** Two callers reaching `audio_play_sound_on()` directly
  is how the menu silently kept the old behaviour. The stage and the menu now
  share one helper.
* **Log what was applied, not what was asked for.** The old line printed `_len`,
  the loop end it had computed, which read as confirmation.
* **If a loop seam clicks, that is a different bug**, and it is answered by
  baking the tail into the head (or by OGG, which has no MP3 encoder padding),
  not by moving the points.

**Status.** FIXED 2026-10-19. The code is in; the ear test is rayu's
(`provide-chorus-loops`): a stage and the menu for ~3 minutes each, and the seam
on *Wilted Sprouts* and *Mires of the Undead*, whose bodies end quiet and
restart at full level.

**Files.** `scripts/music_data/music_data.gml`,
`scripts/scr_music_apply_loop/scr_music_apply_loop.gml`,
`scripts/scr_music_start_level/scr_music_start_level.gml`,
`scripts/scr_music_start_menu/scr_music_start_menu.gml`,
`objects/obj_title/Step_0.gml`, `objects/Menu/Step_0.gml`,
`notes/systems_overview/systems_overview.md`.

---


<a name="ll-065"></a>
## LL-065 - A status that legitimately STOPS a monster looks exactly like a stuck one

**Symptom.** (Caught by reasoning, before it shipped.) Add a stun or a root -
any status whose speed multiplier is 0 - and monsters with nothing wrong with
them disappear about five seconds later, with this in the log:

```
PATH  WARNING: monster 100003 stuck at 412,288 - path_position 0.37 unmoved for 5s (path_free=1 retry=0)
PATH  WARNING: 1 stuck monster(s) cleared so the wave can end (2 still walking)
```

The stage then finishes with `level_forced = true`, so it silently does not
earn Exterminator - and the monster that was deleted never paid a life, so the
wave "cleared" without the leak it should have been.

**Root cause.** The safety valve from [LL-031](#ll-031) fires on a signal that
was only ever meant as evidence of a BROKEN PATH: `path_position` has not
changed for five seconds. A stun writes `path_speed = 0` on purpose (the
status multiplies the speed, and 0 x anything is 0), so the follower is
working perfectly and the valve cannot tell the difference. Two mechanisms
read the same number for different questions - the same shape as
[LL-034](#ll-034) and [LL-021](#ll-021): one fact, two meanings.

The blast radius is bigger than the deleted monster. `level_forced` is what
denies the badge, so a CONTROL tower would quietly cost the player a medal -
and it would look like the badge system being flaky.

**Fix.** The counter only runs while the monster is TRYING to move. The status
is already the single answer to "how fast is this monster", so the guard asks
it:

```gml
/// scr_zomb_updatePosition: a HELD monster is not a STUCK one (LL-031)
if(status_speed_mult() <= 0){
    stuck_frames = 0;
} else if(path_position == path_pos_last){
    stuck_frames++;
} else {
    stuck_frames = 0;
}
```

A SLOW is a fraction (0.55), not a hold, so a slowed monster still advances
and still counts - the valve's five-second budget is far longer than any slow
needs.

**Guard rails.**

* **When you add a mechanic that stops something, grep for who reads its
  motion as evidence.** `stuck_frames`, `wait_stuck`, `path_retry` and
  `path_escape` are all "is this thing broken?" counters, and every one of
  them starts lying the moment stopping is legal.
* **A safety valve must fire on EVIDENCE of a fault, not on absence of the
  good thing.** LL-031 fixed the opposite mistake (a timer that ended every
  wave after six seconds); both bugs are the same valve asking a question it
  cannot answer.
* **A status is a MULTIPLIER, never a special case.** `path_speed` has one
  owner and the status multiplies it last, which is why a stun needed no code
  in the follower - and why the one place that had to change was the valve.
* **One instance per kind, strongest wins** (`status_apply`): an effect that
  stacks is an effect whose strength is "however many towers got in range".

**Status.** FIXED 2026-10-20, with `combat-status-slow`; the guard landed in
the same change as the status spine so `combat-status-stun` cannot inherit it.

**Files.** `scripts/scr_status/scr_status.gml`,
`scripts/scr_zomb_updatePosition/scr_zomb_updatePosition.gml`,
`scripts/scr_zomb_pathSpeed/scr_zomb_pathSpeed.gml`,
`objects/obj_mon/{Create_0,Step_0,Draw_0}.gml`

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

