# Garden Defense TD+ — Roadmap

*The plan of record for turning [`goal.md`](./goal.md) and [`economy.md`](./economy.md) into a game, in an order where every phase ends in something playable and every phase has a gate that can fail.*

| Field | Value |
| --- | --- |
| Last updated | 2026-10-04 |
| Companions | `goal.md` (§27 loop, §28 scope), `economy.md` (numbers), `AGENTS.md` (working rules + gates), `lessons_learned.md` (read first, always) |

---

## 1. How to use this document

* Every phase has a **deliverable**, a **gate** (how we know it worked), and a **falsifier** (what would prove it did not).
* **Do not start a phase before its dependency is green.** The dependencies below are real, not decorative.
* Every code change still obeys `AGENTS.md`: consult `lessons_learned.md` first, run the four verification gates, never hand-edit `.yy`, never change line endings, never shadow a built-in script name.
* **GameMaker must be closed while these files are being edited** (LL-008) and reloaded before testing. This is the single most likely way to lose a session's work.

---

## 2. The phases at a glance

| Phase | Name | Depends on | Deliverable | Gate |
| --- | --- | --- | --- | --- |
| **0** | Foundations | — | a save that works, stage/difficulty data, level flow on `enum` + `switch`, `room_speed` fixed | a stage declared in **data** is playable, progress survives a restart, and the three Phase-0 bugs of §4.4 pass their acceptance tests |
| **1** | Vertical slice | Phase 0 | region 1: 10 stages, 3 difficulties, seeds, one clover branch, 3 badges, world map, Deploy screen, 6 towers | **clear → unlock → farm → badge → quit → still there** |
| **2** | Combat depth | Phase 1 | crit, burn/slow/stun, persistent levels 1–5, specializations, the `scr_level_difficulty` rewrite | winnable *and* losable for the right reasons; two loadouts play differently |
| **3** | Garden Book | Phase 2 | four trees, five master nodes, currency HUD, per-tower mastery | every currency earnable *and* spendable; nothing inert |
| **4** | Endless, candy, shards | Phase 3 | endless mode, 1.2× boxes, choice-of-three, pity counter, blood tree, candy | a run reaches box 5+; a shard drops in a normal session |
| **5** | Content | Phase 4 | regions 2–6: 5 biomes, 5 mechanics, 5 bosses, 6 zombies, 6 towers, 50 stages | the campaign is completable; `economy.md` §9 checkpoints hold |
| **6** | Balance & polish | Phase 5 | retune from logs, audio, onboarding | a fresh player reaches stage 5 unaided |

**Why this order:** a closed meta loop at *one* region is ~70% of the systems work. Everything after Phase 1 is content and tuning, which is exactly the part that can run in parallel with art. Content-first would mean re-authoring 60 stages every time a system moved.

---

## 3. What runs in parallel

| Track | Can start | Notes |
| --- | --- | --- |
| **Code** (Phases 0–4) | now | strictly sequential — each phase assumes the last |
| **Art** (towers, zombies, bosses, biomes) | after Phase 1's *design* is frozen | the long pole: ~850 frames in v1 |
| **Stage authoring** (60 stages) | after Phase 1's data schema exists | mostly table-filling; only `par_spend`, `par_time` and boss waves are hand-authored |
| **Audio** | any time | 11 sounds exist; region music is the only real gap |

**Art must not lead design.** Nothing gets drawn for a system that has not shipped in the slice, or we pay for it twice.

---

## 4. Phase 0 — Foundations (nothing player-visible)

### 4.1 Tasks

| # | Task | Files | Why |
| --- | --- | --- | --- |
| 0.1 | **A save that works** — versioned, atomic, corrupt-safe | new `scr_save_meta` / `scr_load_meta`; fix `scr_setup_statinv`, `scr_save_static`, `scr_load_static` | the meta layer has nowhere to live today: the current path is `working_directory` and the load call is commented out |
| 0.2 | **`stage_data`** — region, stage, base seeds, wave count, spawn mix, biome, `par_spend`, `par_time`, boss flag | new script | removes the need for 60 rooms |
| 0.3 | **`difficulty_data`** — seed/HP/speed/spawn/money multipliers | new script | one table for the whole game (`goal.md` §2) |
| 0.4 | **Level flow → `enum` + `switch`** | `objects/_levelControl/Step_0.gml`, new `scr_level_state` | `scr_runState` + numeric sentinels will not survive stage phases (LL-004) |
| 0.5 | **`room_speed` → `game_get_speed(gamespeed_fps)`** in the touched files | level flow first | every status-effect timer depends on it (LL-007) — and **the candy timer is the first real timer in the game**, so it cannot be written until this lands |
| 0.6 | **Currency instrumentation** | new `scr_meta_log`, `print()` prefixes `META`/`SEED`/`CLOVER`/`SHARD`/`CANDY` | `economy.md` §9/§10 are guesswork without it |
| 0.7 | **Fix the latent fatal in `create_perlin_grid`** | `scripts/create_perlin_grid` | it reads `vx`/`vy`, which do not exist — harmless today, fatal the moment biomes depend on it |
| 0.8 | **Loadout/config globals** | `scripts/initialize_game` | one place for "current stage", "current difficulty", "current loadout" |
| 0.9 | **Bug 1 — path integrity:** a placement must not be able to pocket a zombie, and a broken path must heal itself | `objects/obj_tower_edit/Step_0.gml`, `objects/obj_mon/Alarm_0.gml`, `scripts/scr_zombie_path`, `scripts/scr_level_wait` | §4.4.1 — a soft-lock is the worst class of bug in a 60-stage game |
| 0.10 | **Bug 2 — the pause/exit screen is black:** the snapshot is captured at a mismatched size and gated on another state's fade variable | `scripts/scr_drawBlurScreen`, `objects/_mainControl/Draw_75.gml`, `scripts/scr_main_pause`, `scripts/scr_initResolution` | §4.4.2 |
| 0.11 | **Bug 3 — the tower upgrade UI:** declutter, and show targets/DPS/upgrade deltas | `scripts/scr_drawTowerSelected`, `scripts/scr_drawTowerMod`, `scripts/scr_drawTowerStats`, `scripts/scr_dataToString`, `objects/obj_tower_edit/Draw_0.gml` | §4.4.3 |
| 0.12 | **Deprecated / legacy API audit** — fix the calls in the files we touch, schedule the sweep | see §4.5 | `room_speed` alone is 64 hits in 36 files (LL-007) |

### 4.2 Gate

A stage **declared in `stage_data`** plays: its waves spawn, it ends after its wave count, and the save file survives a full game restart with its versioned contents intact. **Plus all three bugs of §4.4 pass their acceptance tests** — a phase that adds a stage system on top of a soft-lockable path is a phase that cannot be tested.

### 4.3 Falsifier

If wave counts or spawn mixes still live in `scr_setupSpawning` rather than in `stage_data`, Phase 1 cannot proceed — the data layer is the whole point of Phase 0.

### 4.4 The three blockers (fixed before Phase 1)

These are not polish. Two of them touch systems that Phase 1 and Phase 2 build directly on top of (pathing, and the tower panel that the loadout card will replace), and the first one can soft-lock a run so badly that only a restart recovers.

#### 4.4.1 Bug 1 — blocking the path glitches, and the path stays broken forever

**Symptom.** A tower placed so that it seals a zombie's route leaves the zombie frozen. The wave never ends, so the run is dead, and only restarting the game recovers.

**Root cause — four separate defects, all in the pathing code:**

| # | What actually happens | Where |
| --- | --- | --- |
| 1 | The placement check validates only **spawn → despawn**. A placement that leaves the spawn connected but **pockets a zombie already on the map** is accepted | `obj_tower_edit/Step_0.gml:22-24` |
| 2 | The pocketed zombie re-paths from its own position, gets `false`, and is left with an **empty path** — it simply stops where it stands | `obj_mon/Alarm_0.gml:5-6` |
| 3 | The retry loop re-runs forever with the identical result (`if(!path_free) alarm[0] = 0.5s`), so nothing ever changes and nothing ever heals | `obj_mon/Alarm_0.gml:9-11` |
| 4 | The **first** path of every zombie **discards its return value** and leaves `path_free = true` from creation — so a failed initial path is completely silent and never even schedules a retry | `scr_zombie_path:8` vs `obj_mon/Create_0:24` |

**A fifth vector:** a tower can be placed **on the cell a moving zombie is standing in** — the placement test only asks `position_meeting(x,y,obj_tower)`. That blocks the zombie's own start cell and produces the identical freeze.

**The fix — refuse, then always heal.**

*Refuse (make pockets impossible):*
1. Reject the placement if any live `obj_mon` overlaps the target cell.
2. Validate **every** live `obj_mon` from its current cell to the despawn against the candidate grid — not just the spawn.
3. Keep the existing spawn → despawn test as the cheap first pass.

*Heal (so no cause, present or future, can soft-lock the wave):*
4. Capture the `mp_grid_path` return value at **every** call site, including `scr_zombie_path`.
5. Escalating recovery in the monster: retry → after ~2 s, re-path on a **tower-ignoring grid** so the zombie can walk out over the tops of the towers → log a `PATH` warning under `devMode`. This guarantees `instance_number(obj_mon)` can always reach 0.
6. A last-resort safety valve in the wave-end check, so a stuck monster can never hang a stage forever.

**Acceptance.** All four of these must hold:

| Test | Expected |
| --- | --- |
| Try to seal a zombie into a pocket | placement **refused**, `snd_unable` plays, no money spent |
| Sell a tower mid-wave | every zombie re-paths and the wave still ends |
| Dev-only: `mp_grid_clear_all(LEVEL.path_grid)` while a wave is live | zombies recover within ~2 s and the wave completes |
| Normal play, `devMode` on | **zero** `PATH` warnings |

**Lessons:** once fixed, `lessons_learned.md` gets an entry per root cause — "a discarded return value is a silent failure", and "validate the whole system, not the entrance to it".

#### 4.4.2 Bug 2 — the pause / exit screen is black

**Symptom.** Pausing blacks the screen. The game image is neither captured nor displayed, so the pause menu has nothing to sit on.

**Root cause — three defects, and any one of them produces a black screen on its own:**

| # | Defect | Where |
| --- | --- | --- |
| 1 | **Size mismatch.** The snapshot surface is created at GUI size, but `application_surface` is resized to `ideal_width`/`ideal_height`. Drawing an app surface into a differently sized surface leaves the remainder as the `draw_clear_alpha(c_black, 1)` fill — so the frame is mostly opaque black | `scr_drawBlurScreen:5-7`, `scr_initResolution:48`, `_mainControl/Draw_75.gml:43-45` |
| 2 | **The snapshot is gated on another state's variable:** `draw_sprite_ext(..., clamp(1 - blackScreen, 0, 1))`. If `blackScreen` is 1, the snapshot draws at **alpha 0** while the black-screen block fills the frame. Worse, `instance_deactivate_all(true)` at `state_time == 10` freezes whatever ramps `blackScreen`, so it can stick there | `_mainControl/Draw_75.gml:31`, `:52-55`, `scr_main_pause:16-18` |
| 3 | The capture happens **mid-Draw** (depth 75), so it grabs a partially composed frame — and Draw GUI runs after it, so the HUD is never in the snapshot | `_mainControl/Draw_75.gml:39-47` |

**The fix:**

1. Capture at the **application surface's own size** (`surface_get_width/height(application_surface)`) and then draw the resulting sprite **stretched to the GUI size**. No size assumption survives anywhere in the path.
2. Give pause its **own** alpha (`pause_alpha`) and stop reading `blackScreen`. Reset `blackScreen` on entering pause so no other state's fade can darken it.
3. Apply the same "never black" principle as the path fix: if the snapshot sprite is missing or zero-sized, **skip the black fill entirely** and let the frozen world show through. The worst case then becomes "pause without the blur", never "pause with nothing".
4. Move the capture to the earliest draw pass (Draw Begin), so it always captures a complete, already-composed frame rather than a half-drawn one.

**Diagnostic first, in `devMode`** (guarded so it cannot throw — LL-002): log `state`, `state_time`, `grab_surf`, `display_get_gui_width/height`, `surface_get_width/height(application_surface)`, `sprite_exists(pause_surf)`, and `blackScreen` at the moment of the grab. That single line tells us which of the three defects dominates on your machine, and it is the evidence that the fix worked.

**Acceptance.**

| Test | Expected |
| --- | --- |
| Press P mid-wave | world visible behind the overlay, HUD legible, vignette fades in |
| Pause → resume → pause again | identical both times (no stuck alpha) |
| Game over | same, with the GAME OVER treatment |
| Log check | GUI size and app-surface size are both printed; if they differ, the stretched draw is what makes the image correct |
| Dev-only: force `sprite_delete(pause_surf)` immediately after the grab | the pause screen degrades to "frozen world + overlay", never to black |

#### 4.4.3 Bug 3 — the tower upgrade UI fights itself and hides the numbers

**Symptom.** Two elements compete for attention — the range circle and a large upgrade panel in the middle of the screen — and the information shown is missing exactly what a purchase decision needs.

**Root causes:**

| # | Defect | Where |
| --- | --- | --- |
| 1 | The panel is a **256×256 box centred on the screen** (`tower_radius << 1`, with `tower_radius` a fixed 128), while the range circle uses the tower's real range (75–125). Two shapes, two radii, both mid-screen | `scr_drawTowerSelected:6-9`, `obj_tower_edit/Draw_0.gml:10`, `_levelControl/Create_0.gml:89` |
| 2 | The two buttons float in their own grid over the same area | `scr_drawTowerMod`, `tower_dgrid` |
| 3 | The stat string prints **only Range and Damage**: `array_last_index(_type)` is 2 for a 3-element array, so the loop stops before Fire-Rate — and **Targets was never in the list at all** | `scr_dataToString:11-16` |
| 4 | No **DPS** and no **deltas**, so the player cannot tell what a purchase will do | `scr_drawTowerStats` |
| 5 | The `var _count = array_last_index(_type),` / `for (...)` construction is a latent parse hazard | `scr_dataToString:13-16` |

**The fix — one card, one place:**

* **Layout:** a single **fixed card**, docked bottom-left, never under the mouse. Line 1: `NAME · Lv n`. Line 2: `DMG · RATE · RNG · TARGETS · DPS`. Line 3: the Upgrade and Sell buttons **inside the card**. The buttons stop floating and the two elements stop competing, because there is now only one element.
* **Deltas:** the card shows `125 → 250` for the pending upgrade, so a purchase explains itself without a tooltip.
* **The range circle becomes subordinate:** alpha ≈0.15, a 1px outline, drawn beneath the towers, and only while the pointer is over the tower on the map or over the card's *Range* row. Never while the card is being read.
* **Link the two:** the selected tower pulses on the map — the `tower_hilight` flag already exists for it.
* `scr_dataToString` prints all five fields, with its declaration cleaned up.

**Acceptance.** With a tower selected: the card is legible at a glance, the range circle reads as clearly secondary, all five numbers plus the delta are present, and the buttons are inside the card. Before/after screenshots go into the Phase 0 record.

**This is the one bug with a design decision inside it** (see the summary): a fixed bottom-left card, or a callout anchored to the selected tower. **Recommendation: the fixed card** — the loadout UI that replaces it in Phase 1 is a fixed panel too, so building it that way now means reusing the layout instead of rewriting it.

### 4.5 Deprecated / legacy API audit

Measured across the project today (files / occurrences):

| API | Files | Hits | Replacement |
| --- | --- | --- | --- |
| `room_speed` | 36 | 64 | read `game_get_speed(gamespeed_fps)`; set `game_set_speed(60, gamespeed_fps)` (LL-007) |
| `draw_set_blend_mode` | 13 | 27 | `gpu_set_blendmode` |
| `action_inherited` | 11 | 15 | a no-op in GMS2 — delete the call |
| `instance_create(` | 11 | 12 | `instance_create_depth` / `instance_create_layer` |
| `display_get_width/height(` | 2 | 11 | `display_get_gui_width/height`, or the view size |
| `string_width(` | 11 | 14 | valid, but prefer `string_width_ext` where wrapping matters |

**Rule for Phase 0: fix the deprecated calls in the files we touch, and do not sweep the project.** A blanket sweep is its own risk (every file is a chance to change line endings — LL-006 — and to trip the IDE's buffers — LL-008) and it would make the three bug fixes unreviewable. The audit is recorded here so the sweep can be scheduled as its own commit, with the gates run over it, once the bugs are closed.

### 4.6 Explicitly NOT in Phase 0

No new screens, no currencies, no art, no balance. Phase 0 is invisible on purpose: it is the difference between a 60-stage game and a 60-times-repeated prototype.

---

### 4.7 Phase 0 as built (the record)

| # | Task | State | Where it landed |
| --- | --- | --- | --- |
| 0.1 | A save that works | **done** | `scr_meta_schema` (schema, defaults, merge), `scr_save_meta`, `scr_load_meta`; wired into `initialize_game`; `scr_autosave_statinv` — called from `_levelControl`'s Room End — is what persists it |
| 0.2 | `stage_data` | **done** | `stage_data` — region 1's ten stages, plus `stage_row`/`stage_get`/`stage_current` |
| 0.3 | `difficulty_data` | **done** | `difficulty_data` — the table, plus `difficulty_current`/`difficulty_name`/`stage_seed_reward` |
| 0.4 | Level flow on `enum` + `switch` | **done** | `scr_level_state`; `scr_level_start/spawn/wait` are now the state bodies; `_levelControl/{Create_0,Step_0}` |
| 0.5 | `room_speed` → `game_get_speed` | **done in the touched files** | level flow, `scr_setupSpawning`, `fadeout`, `scr_main_pause`, `obj_mon/*`. The project-wide sweep is still scheduled — LL-007 is **PART FIXED**, not FIXED |
| 0.6 | Currency instrumentation | **done** | `scr_meta_log` — `META  [TAG] …`, dev-gated, and it cannot throw |
| 0.7 | The latent fatal in `create_perlin_grid` | **done** | `to_key(x,y)` (it was reading `vx`/`vy`, which do not exist in that scope) + RNG save/restore |
| 0.8 | Loadout / config globals | **done** | `initialize_game`: `global.region`, `global.stage`, `global.difficulty`, `global.loadout` |
| 0.9 | Bug 1 — path integrity | **done** | `scr_path_validate` + 7 files; see §4.7.1 |
| 0.10 | Bug 2 — the black pause screen | **done** | 6 files; see §4.7.2 |
| 0.11 | Bug 3 — the tower UI | **done** | 7 files; see §4.7.3 |
| 0.12 | Deprecated / legacy API audit | **done in the touched files** | and one entry corrected: `instance_create` is a GameMaker **compatibility script**, not a bug (§4.7.4) |

**What is deliberately NOT done, and why:**

* The **project-wide** `room_speed` sweep (~35 files) is still outstanding. It is
  its own commit with the gates run over it; mixing it in would have buried the
  three bug fixes. Until it lands, treat every remaining `room_speed` as a live
  timing bug (LL-007).
* **`stage_data` is not yet consumed by a Deploy screen** — that is Phase 1.
  Phase 0 consumes it for the wave count and the spawn pool, which is what the
  gate asks for.
* **`scr_save_static` / `scr_load_static` stay in the tree, unwired.** A static
  inventory is per-run state and should not be saved at all; they now document
  that rather than pretending to work. The things that *do* persist live in
  `global.meta`.
* **Main flow still uses the old runner.** `_mainControl` keeps `scr_runState`;
  migrating it is Phase 1's first task (§5.1). Only the *level* flow moved, which
  is what Phase 0 needed.

#### 4.7.1 Bug 1 as built — refuse, then always heal

Four defects behind one symptom (a frozen zombie, and a wave that can never end):
a placement that left the spawn connected but pocketed a monster already on the
map; a monster left with an empty path; a retry loop that could not change its own
inputs; and **a discarded `mp_grid_path` return value** — which is why a failed
*first* path was silent and never even scheduled a retry.

A placement is now refused if a monster occupies the cell, if the spawn route is
sealed, or if **any** monster on the map cannot reach the despawn. That last check
is what makes a pocket impossible by construction. And every failure path heals:
escalating re-path, then an empty grid with the towers ignored, then a last-resort
valve in `scr_level_wait` that clears stragglers and logs a `PATH` warning.
Selling a tower now wakes every monster, because that is the moment a monster
walking backwards can go forwards again.

**Acceptance tests.** Seal a monster in → the placement is refused and
`snd_unable` plays; no money is spent. Sell a tower mid-wave → every monster
re-paths and the wave still ends. `mp_grid_clear_all(LEVEL.path_grid)` mid-wave
(dev only) → monsters recover within ~2 s and the wave completes. Normal play →
**zero** `PATH` warnings.

#### 4.7.2 Bug 2 as built — one variable doing two jobs

`blackScreen` drives the GAME OVER crossfade into the high score table, and the
pause path read it as its own fade — so a pause *after* a game over drew the
snapshot at alpha 0, over a black fill. (`scr_draw_main_text` multiplies its alpha
by `1 - blackScreen` too, so the PAUSED text vanished with it.) Two more defects
were waiting behind that one: the snapshot surface was created at **GUI** size
while `application_surface` is resized to `ideal_width/ideal_height`, and the grab
was taken part-way through Draw — where on this project almost nothing has been
drawn yet, because the ground sits at a negative depth and the towers and monsters
at about `-60`.

Now: capture at the application surface's **own** size and draw it **stretched** to
the GUI; pause has its own `pause_alpha` and resets `blackScreen` on entry; the
black score background is gated on the **state**; and the grab runs at the top of
`Draw_75` — the Draw GUI End event, the *last* pass of the frame, so the surface is
fully composed by then. If there is no usable snapshot, everything that could
darken the screen is skipped: the worst case is "pause without the blur", never
"pause with nothing".

**Acceptance tests.** Pause mid-wave → the world is visible behind the overlay,
the HUD legible, the vignette fading in. Pause → resume → pause again → identical
both times. Game over → the same treatment. The log prints **both** sizes, so a
mismatch is visible rather than guessed. Force `sprite_delete(pause_surf)` after
the grab (dev only) → it degrades to "frozen world + text", never to black.
#### 4.7.3 Bug 3 as built — one card, one place

A 256×256 panel centred on the screen (showing two values: Range and Damage), its
buttons floating in their own grid over the same area, and the range circle at
full strength beside them — three elements fighting for attention, while the two
numbers a purchase decision needs were never printed. `scr_dataToString` used
`array_last_index(_type)` as a **count**, so the loop stopped before Fire-Rate, and
Targets had no label at all.

Now: one fixed card docked bottom-left — `NAME · Level n` / `DMG · RNG · RATE ·
TGT` / `DPS`, with `A -> B` deltas computed by the **same arithmetic the purchase
uses**; the buttons inside the card; the range circle demoted to a 0.15-alpha decal
shown only while the pointer is over the tower on the map or over the card's range
band; and the tower list hides while a tower is selected, since both dock in the
same corner.

**Acceptance tests.** With a tower selected: the card is legible at a glance, all
five numbers plus the delta are present, the buttons are inside the card, and the
range circle reads as clearly secondary. Before/after screenshots go in the Phase 0
record.

#### 4.7.4 The audit's one correction

`instance_create(` was listed in §4.5 as 11 files / 12 hits to replace. It is **not
a bug**: `scripts/instance_create/instance_create.gml` is a GameMaker-generated
**compatibility script** (`isCompatibility: true`) that wraps
`instance_create_depth` using the object's own depth. Those calls are legitimate
and were left alone. The other rows stand.

#### 4.7.5 What the fixes taught, and where it is written down

Four new entries in `lessons_learned.md`, because each one took real work to
understand and each one will look like something else next time:

| Entry | The rule it produced |
| --- | --- |
| [LL-013](../lessons_learned.md#ll-013) | **A discarded return value is a silent failure** — and *validate the whole system, not the entrance to it* |
| [LL-014](../lessons_learned.md#ll-014) | **One variable doing two jobs** — a state's fade must not be read by another state; never assume two surfaces are the same size |
| [LL-015](../lessons_learned.md#ll-015) | **`array_last_index()` is not a count** — and a field that exists but is never printed looks finished |
| [LL-016](../lessons_learned.md#ll-016) | **A parameter is not visible in a sibling function** — and an unreachable branch is not a test |

---

## 5. Phase 1 — Vertical slice: one region, a closed loop

*This is the most important phase in the plan. Everything after it is content.*

### 5.1 Tasks

| # | Task | Files | Notes |
| --- | --- | --- | --- |
| 1.1 | **World map** — 6 regions × 10 nodes, locked stages greyed, region unlock on boss clear | new `rooms/rm_worldmap` + `obj_worldmap` | built on the `objects/Menu` state-machine pattern |
| 1.2 | **Deploy screen** — difficulty picker, 4 slots, the locked-tower wall, pre-filled, `Deploy` | new `rooms/rm_deploy` + `obj_deploy` | reuses `_button` + `scr_button_greyout`; `goal.md` §3.1 is the spec |
| 1.3 | **Loadout enforcement** — the shop draws the selected 4, and only those 4 can be placed | `objects/_levelControl/Create_0.gml`, `Step_0.gml`, `scr_placeTower` | the shop is already a 4-wide grid, so this is data plumbing, not layout |
| 1.4 | **Stage parameterization** — the play room reads the selected stage: biome/tile seed, wave count, spawn mix, `par_spend`, `par_time`; a stage *ends* instead of running forever | `objects/_levelControl`, `objects/Control`, `scripts/scr_main_startup` | the moment `rm_test` becomes "any stage" |
| 1.5 | **Stage results** — seeds, clovers, badges, and a route back to the map | extend `objects/_score` (`rm_score`) | |
| 1.6 | **Seeds + Clovers** — awards with first-clear/repeat tracking, stored in the save | new `scr_meta_seeds`, `scr_meta_clovers`, save schema | `economy.md` §2–§3 |
| 1.7 | **Garden Book v1** — one clover branch (Offense), the seed shop with locked towers greyed | new `rm_garden` + `obj_garden` | one tree now, four later, so the *screen* is proven early |
| 1.8 | **Badges v1** — *Untouched*, *Exterminator*, *Brutalist* | new `scr_badges` | the other four are data + a flag once the pattern exists |
| 1.9 | **Region 1 content** — 10 stages + the region boss (a retuned existing rig) | `stage_data` rows | the boss costs **no new art** |
| 1.10 | **Six towers** — the 4 starters plus **2 unlocks that need no new mechanics** | `tower_array` | see 5.2 |
| 1.11 | **Art for the slice** — 2 tower sprite trios (6 sprites × 15 frames) | `sprites/spr_t5_*`, `spr_t6_*` | the only art Phase 1 needs; region 1 reuses the 3 existing zombies |

### 5.2 The sequencing decision inside 1.10

Phase 1 must ship a **real unlock loop** without shipping status effects (that is Phase 2). So the two unlockable towers in the slice are the two that are pure stat changes:

* 🎆 **Cannon Tulip** — long range, low fire rate (no status)
* 🎺 **Meat Bulb** — high damage, single target (no status)

**Chillip (slow), Bindweed (root), Belladonna Blitz (poison) and Thornamental (crit) deliberately wait for Phase 2**, because each of them needs a system that does not exist yet. This is the whole reason to cut systems and content into separate phases.

### 5.3 Gate — the loop, end to end

> Clear stage 1 → earn seeds → unlock a tower in the Garden Book → deploy with the new loadout → finish a stage with all 20 lives → earn clovers → spend them in the Offense tree → replay stage 1 for *Untouched* → **quit the game entirely** → relaunch → the saves, unlocks, tree nodes and medals are all still there.

### 5.4 Falsifier

If **any** step needs a restart to see its effect, or a currency can be earned but not spent, the phase is not finished. Also: if the Deploy screen takes more than two clicks for a player who wants to repeat their last loadout, §3.1's promise is broken.

### 5.5 Explicitly NOT in Phase 1

Regions 2–6, status effects, crit, specializations, endless, candy, blood shards, cosmetics. **Eight currencies/systems on screen at once is how the slice becomes a swamp.**

### 5.6 Phase 1 as built (the record)

| # | Task | State | Where it landed |
| --- | --- | --- | --- |
| 1.1 | World map | **done, as a Menu state** | `meta_draw_worldmap()` / `meta_worldmap_hit()` in `scr_meta_screen` |
| 1.2 | Deploy screen | **done, as a Menu state** | `meta_draw_deploy()` + the `MENU_STATE.DEPLOY` case |
| 1.3 | Loadout enforcement | **done** | `tower_array` is built from `loadout_current()`; `scr_tower_roster` holds the stats |
| 1.4 | Stage parameterization | **done** | Phase 0 already drove the wave count and spawn pool from `stage_data`; the level now also **arms from the loadout** |
| 1.5 | Stage results | **done in the level, not in `rm_score`** | the `CLEAR` state pays out, writes the banner and sets `global.menu_entry` |
| 1.6 | Seeds + Clovers | **done** | `scr_meta_seeds`, `scr_meta_clovers`, `scr_meta_progress`, the `clears` save key |
| 1.7 | Garden Book v1 | **done, as a Menu state** | `meta_draw_garden()`; `scr_clover_tree` (Offense), `scr_meta_unlock` (the shop) |
| 1.8 | Badges v1 | **done** | `scr_badges`; counters in `_levelControl` and `lose_life` |
| 1.9 | Region 1 content | **done** | the ten `stage_data` rows (Phase 0) |
| 1.10 | Six towers | **done** | `scr_tower_roster` — four starters plus **Cannon Tulip** and **Meat Bulb** |
| 1.11 | Art for the slice | **NOT done** | the two unlocks borrow the t3/t4 sprite trios as clearly-marked placeholders |

#### 5.6.1 The one deviation: the screens are Menu states, not new rooms

Roadmap 1.1/1.2/1.7 name `rm_worldmap`, `rm_deploy` and `rm_garden`. **Those
rooms do not exist.** The reason is mechanical, not aesthetic:

* `python_tools/gm` can create scripts and objects (`create_script`,
  `create_object`) but **has no `create_room`**.
* A room `.yy` is the most complex resource in the project — layers, instance
  lists, view settings, physics — and hand-authoring one is exactly what
  **LL-009 forbids**.

So the three screens live as states of the existing `Menu` object, which is
what §5.1 itself asks for ("built on the `objects/Menu` state-machine
pattern"). Nothing assumes a single object: each screen is a `meta_draw_*()`
plus a `case` in the Menu's switch, so moving one into its own room later is a
cut-and-paste once the IDE has made the room.

#### 5.6.2 The trap that was written down instead of walked into

`meta_button_draw()` **only draws**; `meta_button_clicked()` **only tests**. A
single helper doing both would be tested in the **Step** event and again in the
**Draw** event of the same frame — `mouse_check_button_pressed` is true in both
— so every click would fire twice, and the second fire would arrive *after* the
state had already changed. Same class as LL-010 (a state entered twice),
reached by a different route.

#### 5.6.3 Two guards that were not obvious

* **`instance_exists()` on an unassigned `globalvar` is not a safe test.** The
  leak counter in `lose_life` has to reach the level, and the obvious
  `if(instance_exists(LEVEL))` would itself throw before the level existed. It
  asks `variable_global_exists("LEVEL")` **first** — a guard that can throw is
  not a guard (LL-002).
* **Every save write proves its target is a struct first.** A save from an
  older build, or a hand-edited one, must not be able to make a purchase throw.

#### 5.6.4 Acceptance tests

| # | Test | Passes when |
| --- | --- | --- |
| P1-1 | Fresh save, open the menu | Start → world map; 60 nodes; region 1 stage 1 open, everything else locked |
| P1-2 | Click stage 1-1 | Deploy: four slots already full (the starters), two towers greyed **with their requirement**, three difficulties |
| P1-3 | Click Deploy | `META [LOADOUT] armed with 4 towers …` and the in-run shop shows exactly those four |
| P1-4 | Clear the stage | `META [LEVEL] CLEAR … seeds=+3 clovers=+…`; `META [SEED]` / `META [CLOVER]` lines; the banner names the seeds, the clovers and any new medal |
| P1-5 | Return | the menu opens on the **world map**, not the title screen; 1-1 is green and 1-2 is now open |
| P1-6 | Garden Book | nodes show `rank 0/5` and a cost; clicking one with enough clovers buys a rank and saves |
| P1-7 | Seed Shop, after ~9 Normal clears | 25 seeds and Cannon Tulip is affordable; buying it makes it appear in the Deploy wall |
| P1-8 | Quit and relaunch | seeds, clovers, the unlocked tower, the tree rank, the clear and the medal are all still there |
| P1-9 | Replay stage 1-1 | seeds and clovers are quartered (repeat), and the medal is **not** announced again |

**What would falsify it:** any step needing a restart to take effect; a currency
earnable but not spendable; the Deploy screen taking more than two clicks to
repeat the last loadout. **What is deliberately weaker than intended:** on a
brand new save *Untouched* and *Exterminator* both fire together, because
"nothing reached the exit" and "nothing leaked and the safety valve never
fired" only diverge once a stage can fail in a way that is not a leak.

#### 5.6.5 Playtest round 1 — three things the first run found

| # | What it looked like | What it was | Fix |
| --- | --- | --- | --- |
| 1 | "I can't remove towers" | `loadout_current()` did two jobs — sanitise **and** pad to four — so a removed tower was put straight back | split into `loadout_stored()` (the selection, 0–4) and `loadout_current()` (what a run needs); `loadout_ready()` gates Deploy |
| 2 | Art and names clipped in the slots | a guessed `0.8` scale, and a name drawn with one unwrapped `draw_text` | `meta_sprite_fit()` (uniform scale, aspect kept), `meta_wrap()` / `meta_text_fit()` (two lines, space-preferred, hyphen only mid-word) |
| 3 | Start / Options / Quit stayed clickable over the new screens | **`scr_button_index_hide()` had never hidden anything** — `visible = false` only affects the built-in sprite draw, and `_button` has its own Draw event | `scr_draButtonGUI()` and `scr_stpButton()` now exit on `!visible`; the Menu hides the title buttons on the three meta states |
| 4 | *(found while fixing 1)* a chosen loadout would not survive a relaunch | `initialize_game` set `global.loadout = []` **before** the save was loaded, and `loadout_current()` reads `global.loadout` — so the pad topped up an empty array and the **saved loadout was never read** | read `global.meta["loadout"]` into `global.loadout` **before** calling `loadout_current()` |

**Change 3 is bigger than Phase 1.** It is a project-wide defect: every
"hidden" button in the game was still drawn, and a hidden one still played
`snd_button` when clicked through. It is now **LL-019**, and the fix is at the
root rather than in the Menu.

**A visible consequence worth expecting:** the Options screen will now look
different, and correctly so — Start / Options / Quit disappear behind the
Return button, which is what that state's `hide` calls always meant.

| # | Test (additions) | Passes when |
| --- | --- | --- |
| P1-10 | Clear a slot, then try Deploy | the slot shows `empty`, Deploy is greyed, and clicking it prints `MENU deploy blocked - 3/4 slots filled` |
| P1-11 | Refill the slot | Deploy enables and the run arms with the four chosen towers |
| P1-12 | Open the world map / Deploy / Garden | no Start / Options / Quit buttons anywhere on screen |
| P1-13 | Options, then Return | the title buttons come back and respond |
| P1-14 | Slot Cannon Tulip, Deploy, quit, relaunch | the Deploy screen still shows Cannon Tulip in the slot (**not** the four starters) |

---

## 6. Phase 2 — Combat depth

### 6.1 Tasks

| # | Task | Files | Notes |
| --- | --- | --- | --- |
| 2.1 | **Crit** — 5% / ×1.5 baseline, additive chance, direct hits only | `scr_do_damage`, `scr_towerData`, `tower_enums` | `goal.md` §6 |
| 2.2 | **Statuses: burn, slow, stun** (the three the game needs first) | new `scr_status_*`, `objects/obj_mon` | one instance per status per zombie; durations in `game_get_speed` frames |
| 2.3 | **Resistances** — zombie / elite / boss columns | `mon_enums`, `scr_makeMonster` | `goal.md` §7; elites introduced here |
| 2.4 | **Persistent tower levels 1–5** — mastery XP per kill, levels stored per tower in the save | save schema, `objects/obj_tower` | money still buys L2–L5 in-run; the *level* persists |
| 2.5 | **Specializations at L3** — two per tower, stored per tower, respec costs seeds | new `scr_spec_*` | 12 specs for the 6 shipped towers |
| 2.6 | **`scr_level_difficulty` rewrite** — the new curve from `economy.md` §4.4 | `scripts/scr_level_difficulty` | **atomic with 2.4**: the old function exists to match a ×16 L5 |
| 2.7 | **Tower stat vocabulary** — extend `enum TOWER` and `scr_towerData` with crit/status fields | `tower_enums`, `scr_towerData` | append fields at the **end** of the enum: every existing index must keep its meaning |
| 2.8 | **The other three towers** — Chillip (slow), Bindweed (root), Belladonna Blitz (poison) + Thornamental (crit) | `tower_array` | now that their systems exist |
| 2.9 | **Art** — 4 tower trios (12 sprites), 1–2 new zombies | sprites | the largest single art push in v1 |

### 6.2 Gate

A stage is winnable **and** losable for the right reasons (not because a number moved), and two different 4-tower loadouts produce measurably different wave-by-wave outcomes. Specifically: a slow/root loadout survives longer against a fast wave than a pure-DPS loadout, and a pure-DPS loadout kills an armoured wave faster than a control loadout.

### 6.3 Falsifier

If one tower or one status appears in every viable loadout, the counter-system of `goal.md` §3 is not working and the numbers — not the plan — need another pass.

---

## 7. Phase 3 — The Garden Book (the meta layer's face)

### 7.1 Tasks

| # | Task | Notes |
| --- | --- | --- |
| 3.1 | **All four clover trees** — Vitality, Offense, Growth, Harvest, 10 nodes × 5 ranks | `economy.md` §3.2 |
| 3.2 | **The five master nodes** — cap 6→10 | the campaign's long tail |
| 3.3 | **Mastery** — the five master nodes (floor **and** cap, `start = cap − 4`), plus a panel showing where each tower arrives and how far it can go | account-wide, so there are no per-tower level screens: the tree *is* the mastery UI |
| 3.4 | **Currency HUD** — all four, with a "new" highlight when one changes | so nothing is earned invisibly |
| 3.5 | **Respec** — specialization changes for seeds; tree respec for a clover fee | protects experimentation |
| 3.6 | **Garden Book navigation** — tabs for the four trees, the shop, and (later) the blood tree and the **candy panel** | one screen, six tabs; the candy content lands in Phase 4, so the layout is proven here first |

### 7.2 Gate

Every currency can be earned *and* spent. **Nothing is inert.** Walk the whole meta layer as a player and every counter does something within two clicks.

### 7.3 Falsifier

Any node whose effect the player cannot perceive is a broken node (`goal.md` §15's rule). If a tree has a node the playtester cannot describe after buying it, redesign that node before adding more content.

---

## 8. Phase 4 — Endless, candy and blood shards

### 8.1 Tasks

| # | Task | Notes |
| --- | --- | --- |
| 4.1 | **Endless mode** — entry from the world map, `ceil(prev × 1.20)` box spacing, the §22 modifier rotation, the 90-wave cycle, the wave-500 cap | `economy.md` §7.1 |
| 4.2 | **Global wave modifiers** — including the range multiplier read by `scr_tower_normal`, and two alternating spawn points | reuses `obj_spawn` |
| 4.3 | **Loot box: choice of three** — tier weights, offer tables, the scaling formula, one re-roll | `economy.md` §7.2–§7.4 |
| 4.4 | **Kill counter + pity curve + shard drops**, with the boss guarantee | `economy.md` §5.1 — log every roll under `devMode` |
| 4.5 | **The blood tree** — five tiers, nodes in "−kills required" | |
| 4.6 | **Candy** — recipes, **levels 1–10 (shards)**, stock, **duration instead of stacking** (30 s per candy, extended by feeding, +100% from the clover track), game-frame timers that tick **only while a wave is live**, a HUD + pause readout, the two rare meta candies, and the pity counter Blood Orange reveals | `economy.md` §6; the level track is the unbounded shard sink and the duration track is the longest clover sink, so both ship with the blood tree |
| 4.7 | **Blood Fields modifier** — region 6's night: more elites, pity bonus | reuses 4.4 |

### 8.2 Gate

An Endless run reaches **box 5 or beyond**; a blood shard drops during a **normal** play session (not a scripted one); and a candy build plays measurably differently from the same loadout without candy. Specifically: **30 s of candy covers 3–6 waves, the timer does not tick during the between-wave wait or the countdown, and it stops dead while paused.**

### 8.3 Falsifier

If 15,000 kills produce no shard, the pity window is wrong (that is the first number to move in `economy.md` §10). If box income makes campaign seeds irrelevant, the box weights are wrong — not the campaign payouts.

---

## 9. Phase 5 — Content scale-out: regions 2–6

### 9.1 Tasks

| # | Task | Volume | Cost driver |
| --- | --- | --- | --- |
| 5.1 | **Five biomes** — Swamp, Desert, Jungle, Graveyard, Blood Fields | 5 tile atlases × 17 frames | the framed-tile pipeline from `bck_tile_*_framed` already exists |
| 5.2 | **Five region mechanics** | the `goal.md` §27.4 table | **zero new engine work by design** |
| 5.3 | **Five bosses** — 4 new rigs + region 2 reusing the second existing boss | 4 × 2 sprites × 15 frames | boss art is the most expensive in the game |
| 5.4 | **Six new zombies** — one per region, plus variants from the existing 3 rigs | 6 × 2 sprites × 15 frames | variants cost data, not art |
| 5.5 | **Six towers** — the remaining unlockables | 6 × 3 sprites × 15 frames | the largest art block in v1 |
| 5.6 | **Fifty stages** — data rows, spawn mixes, `par_spend`, `par_time` | authoring | should be *minutes per stage*, not hours |
| 5.7 | **All seven badges** across all 60 stages | data | the pattern exists after Phase 1 |
| 5.8 | **Audio** — region music, new tower/zombie sounds | 5 tracks + ~15 stings | can run in parallel with everything |

### 9.2 Gate

The full 60-stage campaign is completable, and the `economy.md` §9 checkpoints hold at region scale: cap 6 by stage ~12, first shard region 3–4, the roster unlockable by region 5–6, and every stage clearable by at least three loadouts.

### 9.3 Falsifier

**If authoring one stage takes more than ~30 minutes, the data schema is wrong — fix the schema, not the stages.** That rule exists because 50 stages at three hours each is a year of work, and at twenty minutes each it is a fortnight.

---

## 10. Phase 6 — Balance, polish, release

### 10.1 Tasks

| # | Task | Notes |
| --- | --- | --- |
| 6.1 | **Retune from logs**, in the `economy.md` §10 order | one number at a time; difficulty multipliers last |
| 6.2 | **Onboarding pass** — does a fresh player reach stage 5 unaided? | `goal.md` §27.5 is the script |
| 6.3 | **Performance** — status overhead with 60 monsters, sprite memory and texture groups | the project is at 126 sprites and v1 adds ~100 |
| 6.4 | **Audio and feel** — hit feedback, kill feedback, screen shake budget | |
| 6.5 | **Readability** — the HUD shows four meta currencies and money; the player must never wonder which is which | |
| 6.6 | **Localization-ready strings** | cheap now, expensive later |

### 10.2 Gate

A brand-new player reaches stage 5 without being told anything, and an Endless run at wave 40 with 60 monsters holds frame rate on the target machine.

---

## 11. Cut order and the never-cut list

**Cut order (from `goal.md` §28.5 — decided now, so it is not decided in a panic):**

1. Cosmetic rewards for badges and legendary boxes
2. Badges beyond the five core (*Untouched, Frugal, Botanist, Purist, Exterminator*)
3. Candy tier 3 recipes
4. Regions 6 and 5
5. Towers 12 → 8

**Never cut:** the save, the Deploy screen, the closed loop at region 1, or the four-currency identity. Those four *are* the game; everything else is content.

---

## 12. Risk register

| Risk | Likelihood | Mitigation |
| --- | --- | --- |
| **GameMaker overwrites our edits** from its own buffers (LL-008) | high | close the IDE before structural edits; reload before testing; ask the user, every time |
| **`room_speed` timing bugs** in every new status effect (LL-007) | high | fix it in Phase 0, before a single timer is written |
| **State-machine sentinel bugs** (LL-004) | high | migrate level flow to `enum` + `switch` in Phase 0; copy the Menu |
| **Save corruption** wipes a tester's campaign | medium | atomic write (temp file then replace), a version field, and a fallback that starts fresh rather than crashing |
| **Art becomes the critical path** | high | freeze a system's design before drawing for it; reuse the 3 zombie rigs and 4 tower rigs wherever possible |
| **A stage takes hours to author** | medium | the 30-minute rule (§9.3); fix the schema, not the stages |
| **One tower dominates every loadout** | medium | Phase 2's gate; rebalance numbers, not the plan |
| **Scope creep back to "20-ish towers"** | high | the cut order exists precisely for this |
| **Sprite memory / frame rate** | medium | texture groups, and measure at wave 40 with 60 monsters in Phase 6 |
| **A currency becomes inert** | medium | Phase 3's "nothing is inert" gate, checked by walking the whole loop as a player |

---

## 13. Per-commit discipline (from `AGENTS.md`)

Every code commit in every phase runs the four gates before it is committed:

```bash
PYTHONPATH=python_tools python3 -m gm roundtrip                              # expect 0 differ
PYTHONPATH=python_tools python3 -m unittest discover -s python_tools/tests    # expect OK
PYTHONPATH=python_tools python3 -m gm list GMScript                          # no built-in collisions
```

**Fourth gate:** no literal backslash-r escape in any touched file. The command lives in `AGENTS.md` §2 and is deliberately **not repeated here** — spelling that escape into a document is precisely the LL-006 mistake, and this file's own gate caught it during review. That is the rule working.

And every commit is described in terms of **what the user should see in the log** when they reload and run under `global.devMode` — plus what would prove it *didn't* work. A green gate is not a fix; a log line is not either. Both together are.

## 14. Progress tracking

| Phase | State | Notes |
| --- | --- | --- |
| Design (`goal.md`, `economy.md`, `roadmap.md`) | **done** | 2026-10-04 |
| 0 — Foundations | **done** | 2026-10-04 — save, `stage_data`, `difficulty_data`, level flow on `enum` + `switch`, instrumentation, the perlin fatal, config globals, and all three blocker bugs. Outstanding on purpose: the project-wide `room_speed` sweep, and a Deploy screen that reads `stage_data` (Phase 1). See §4.7 |
| 1 — Vertical slice | **done** | 2026-10-04 — world map, Deploy screen, Garden Book (Offense + seed shop), seeds, clovers, 3 badges, 6 towers, loadout enforcement, results in the level's `CLEAR` state. The three screens are **Menu states, not rooms** (see §5.6.1). Outstanding on purpose: art for the two unlockable towers (1.11), and the four remaining badges. See §5.6 |
| 2 — Combat depth | not started | |
| 3 — Garden Book | not started | |
| 4 — Endless, candy, shards | not started | |
| 5 — Content | not started | |
| 6 — Balance & polish | not started | |

## 15. Change log

| Date | Change |
| --- | --- |
| 2026-10-04 | Created, out of the `goal.md` review and the approved design calls. |
| 2026-10-04 | Phase 0 expanded with the three blocker bugs (§4.4.1 path integrity, §4.4.2 the black pause screen, §4.4.3 the tower card) — each with its root causes located in the source, a fix plan, and acceptance tests that can fail. Added the deprecated / legacy API audit (§4.5) and its numbers. |
| 2026-10-04 | Candy changed from stacking to **duration** in `goal.md` §16–§17 and `economy.md` §1/§3.5/§6.2–§6.5: 30 s per candy, feeding extends, and a clover track to +100%. Roadmap touched in three places — task 0.5 now owns the fact that the candy timer is the game's first real timer, task 3.6 proves the six-tab Garden Book layout, and task 4.6 plus the Phase 4 gate carry the duration system and its timer tests. |
| 2026-10-04 | **Playtest round 1 fixes** (§5.6.5). Three issues from the first run: slots could not be cleared (`loadout_current()` padded them back — split into `loadout_stored()` + `loadout_ready()`); art and names clipped (added `meta_sprite_fit`, `meta_wrap`, `meta_text_fit`); and the title buttons stayed live over the new screens, which turned out to be a **project-wide** defect — `scr_button_index_hide()` had never hidden anything, because `visible = false` does not affect an object with its own Draw event. Recorded as **LL-019**. |
| 2026-10-04 | **Phase 1 implemented.** Nine new scripts (`scr_tower_roster`, `scr_loadout`, `scr_meta_progress`, `scr_meta_seeds`, `scr_meta_clovers`, `scr_clover_tree`, `scr_meta_unlock`, `scr_badges`, `scr_meta_screen`), the Meta's three screens built as Menu states, the level armed from the loadout, and the clear now paying seeds, clovers and badges. Added §5.6 (as built) with the deviation, the double-click trap, the two guards and nine acceptance tests. The two new `lessons_learned.md` entries (LL-017, LL-018) came out of it. |
| 2026-10-04 | **Phase 0 implemented.** Eight new scripts (`scr_meta_schema`, `scr_save_meta`, `scr_load_meta`, `scr_meta_log`, `stage_data`, `difficulty_data`, `scr_level_state`, `scr_path_validate`), the level flow moved onto `enum` + `switch`, `room_speed` fixed in every file touched, and all three blocker bugs closed with their acceptance tests. Added 4.7 (as built), the four new `lessons_learned.md` entries (LL-013 to LL-016), and promoted LL-007 to **PART FIXED**. Recorded one correction: `instance_create` is a compatibility script, not a bug. |

