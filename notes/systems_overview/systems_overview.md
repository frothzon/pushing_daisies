# Pushing Daisies — Systems Overview

*Developer reference. This is a GameMaker `Notes` resource (`notes/systems_overview/`),
so it lives in the IDE's Notes browser. It is **not** shipped with the game and is
not read by any code at runtime.*

*Last updated: 2026-10-04 · GameMaker Studio 2 · converted from GameMaker 8*

Companion documents:

| Document | What it is for |
| --- | --- |
| [`../../AGENTS.md`](../../AGENTS.md) | Working agreement, verification gates, codebase map |
| [`../../lessons_learned.md`](../../lessons_learned.md) | Symptom → cause → fix → rule for every hard-won bug |
| [`../../python_tools/README.md`](../../python_tools/README.md) | The byte-exact `.yy` / `.yyp` / GML toolkit |

---

## 1. What the game is

A wave-based **tower defence**. Zombies walk a path from a spawn point to a
despawn point; the player buys and upgrades four plant-themed towers to stop
them. Four numbers drive everything, all held in the static inventory and drawn
top-right: **points**, **money**, **life**, **wave**.

Starting values (`objects/_levelControl/Create_0.gml`): money **15**, life **20**,
wave **1**, points **0**.

## 2. Runtime map

| Room | Purpose | Key objects |
| --- | --- | --- |
| `rm_title` | Title screen / intro | `obj_title`, `obj_titleZomb`, `_dayCycle`, `_shadows` |
| `rm_menu` | Options menu (volumes, keys, gamepad) | `Menu`, `_button` |
| `rm_test` | **The play room** — this is `global.startRoom` | `Control`, `_mainControl`, `_levelControl`, `_viewControl`, `obj_tower`, `obj_mon` |
| `rm_score` | Score screen + restart | `_score` |
| `perlin_room` | Dev sandbox for the tile generator (not part of the game) | `perlin_tester` |

Room order lives in `pushing_daisies_recovered.yyp` → `RoomOrderNodes`.
`global.startRoom` (`scripts/initialize_game`) is consumed by
`scripts/scr_setup_menuStates` — it is the room the Menu's *New Game* fades to.

## 3. Systems

One row per system. "Key resources" are the files to open first when changing it.

| System | Key resources | What it does |
| --- | --- | --- |
| Boot & globals | `scripts/initialize_game`, `scripts/__global_object_depths` | Runs once before any room (`gml_pragma("global", ...)`). Sets `global.devMode` (true), `global.saveName` (`test.data`), `global.startRoom` (`rm_test`), `global.shadowQuality`, `global.clutterDensity`, `global.fadeOut`, and creates `global.tileSystem`. |
| Main flow, pause, fast-forward | `objects/_mainControl`, `objects/Control`, `scripts/scr_setup_main`, `scripts/scr_main_*`, `scripts/scr_setFrameSkip` | Owns the game-level state machine: startup → normal → pause → game over → high score. Fast-forward toggles the game speed between 60 and 180. `Control` is the engine object that creates `Input`, the bag system, the tooltip, the camera box and the ground/tile setup. |
| Level & wave flow | `objects/_levelControl`, `scripts/scr_level_start`, `scripts/scr_level_spawn`, `scripts/scr_level_wait`, `scripts/scr_setupSpawning`, `scripts/scr_level_difficulty` | Countdown → spawn wave → wait for the field to clear → repeat. Wave lists and difficulty scaling live here (see §5). |
| Towers | `objects/obj_tower`, `objects/obj_tower_edit`, `scripts/scr_tower_*`, `scripts/scr_towerData`, `scripts/tower_enums`, `scripts/scr_placeTower` | Buying, placing, shooting, upgrading and selling (see §4). |
| Monsters | `objects/obj_mon`, `scripts/mon_enums`, `scripts/scr_makeMonster`, `scripts/scr_zombie_*`, `scripts/scr_zomb_*`, `objects/obj_spawn`, `objects/obj_despawn` | Path following (`mp_grid` from spawn to despawn), climbing, damage display and death payouts. |
| Economy & inventory | `scripts/scr_setup_statinv`, `scripts/scr_update_statinv`, `scripts/scr_draw_statinv`, `scripts/scr_set_item` / `scr_get_item` / `scr_add_item`, `scripts/scr_*BagSystem` | `globalvar STATINV` holds the four counters (`points`, `money`, `life`, `waves`). A separate "bag" layer (`BAGLIST`) tracks items and handles saving. |
| Terrain & tiles | `scripts/create_perlin_grid`, `scripts/Sprite_Layer_Manager`, `scripts/scr_iniTileBuilder`, `scripts/scr_buildTiles`, `scripts/test_tile`, `scripts/set_bitmask`, `sprites/bck_tile_*_framed` | Perlin noise produces `ground_map`; each cell's neighbours produce a bitmask that picks a tile frame; tiles are added as *layer sprites* through `global.tileSystem`, one layer per depth. |
| Debree | `scripts/scr_iniDebree`, `scripts/scr_addDebree`, `scripts/scr_endDebree`, `objects/obj_despawn` | Queue of tiles and pieces to delete when a level ends, so the tile count stays under control. |
| Camera | `objects/_viewControl`, `scripts/scr_setup_view`, `scripts/scr_initResolution`, `scripts/scr_view_idle` / `scr_view_drag` / `scr_view_pause` / `scr_view_zoom`, `scripts/points_to_gui` | Fixed view size, drag-to-pan, zoom, and a pause state used while the tower list is open. All view maths goes through `__view_get` / `__view_set`. |
| Lighting & day cycle | `objects/_dayCycle`, `objects/_light`, `scripts/scr_iniLighting`, `scripts/scr_drawDaylight`, `scripts/scr_stpLighting` | A 24-hour cycle drives `shadow_intensity`, which darkens the view and lights the lamps. |
| Shadows, reflections, water | `objects/_shadows`, `scripts/scr_setupShadow`, `scripts/scr_drawShadows`, `scripts/scr_drawReflections`, `objects/obj_water`, `scripts/setup_water_shader` | Shadow surfaces scaled by `global.shadowQuality`, mirrored sprite reflections, and a water shader on the water object. |
| Particles & FX | `scripts/setup_*`, `scripts/ini_part_*`, `scripts/burst_particle*`, `scripts/scr_part_effect`, `objects/_eff_*` | The particle component library plus the four tower hit effects (`_eff_puff`, `_eff_acid`, `_eff_spikes`, `_eff_xplod`). |

| Audio | `scripts/scr_initSoundEmitters`, `scripts/scr_playSound`, `scripts/scr_playSoundAt`, `scripts/scr_playMusic`, `scripts/scr_resetSoundVolume`, `scripts/scr_music_start_level`, `scripts/scr_music_stop`, `scripts/music_data` | Two emitters (`global.SEemitter` / `global.MUSemitter`) so the Music and SE volume options can be applied independently. `scr_playMusic` also stops whatever music was already playing (it remembers the instance in `global.music_playing`), so two tracks can never overlap. Region and menu music live in one table — see §8. |
| Switches & receivers | `scripts/scr_setupSwitch`, `scripts/scr_updateSwitch`, `scripts/scr_set_switch`, `scripts/scr_trigger_switch`, `scripts/scr_switch_*`, `scripts/scr_setupReciever`, `scripts/scr_receiver_on` / `scr_receiver_off` | Generic "trigger fires → switch state changes → receiver runs a script" logic. Matching `team` values stop one switch firing another team's receivers. |
| UI: buttons, menus, tooltips | `objects/_button`, `scripts/scr_iniButton`, `scripts/scr_stpButton`, `scripts/scr_create_button`, `scripts/scr_scaleButton`, `scripts/scr_button_greyout`, `scripts/show_menu*`, `scripts/draw9slice`, `scripts/show_tooltip` | Every button in the game is the `_button` object driven by callables. Menus, sliders, message boxes and the 9-slice panel drawing live here. |
| Floating text | `scripts/float_text`, `scripts/float_text_gui`, `objects/_text_rise`, `objects/_waveNum`, `scripts/scr_showWave`, `scripts/scr_showMonDamage` | Damage numbers, score popups, the "Wave N" banner and monster damage counters. |
| Text input | `objects/_oTextInput`, `objects/obj_textbox`, `scripts/scr_setup_textInput`, `scripts/scr_update_textInput`, `scripts/scr_draw_textInput`, `scripts/string_wordwrap_width`, `scripts/show_message_box`, `scripts/show_portrait_box`, `scripts/scr_wave_preview` | On-screen text entry (high-score name) and the typewriter-style message box. `show_portrait_box()` shows a creature PORTRAIT (a whole sprite, one per message - `obj_textbox.message_portrait`) instead of a frame of the one shared `message_sprite`; the "Up Next..." popup is built on it. |
| Input | `objects/Input`, `scripts/Input_enums`, `scripts/scr_setup_input`, `scripts/scr_setup_keyboard`, `scripts/scr_setup_gamepad`, `scripts/scr_add_key`, `scripts/scr_key_get` | One `KEYCODE` enum mapped to either keyboard or gamepad at boot (`gamepad_is_connected(0)`), remappable and saved per user. |
| Options & saving | `scripts/scr_loadOptions`, `scripts/scr_saveOptions`, `scripts/scr_saveArray` / `scr_loadArray`, `scripts/scr_save_keys` / `scr_load_keys`, `scripts/scr_save_gamepad` / `scr_load_gamepad`, `scripts/scr_save_static` / `scr_load_static`, `scripts/scr_autosave_statinv` | `gameOptions.dat` stores music volume, SE volume, shadow quality and clutter density; keys and gamepad bindings are stored the same way. See §7 for the one broken save path. |
| Collision | `scripts/scr_setupCollider`, `scripts/scr_collide`, `scripts/scr_colliderAddObject`, `scripts/scr_colliderAddPoint`, `scripts/for_collGrid`, `scripts/for_collVisible`, `scripts/scr_inRangeBBOX`, `scripts/scr_pointInBBOX` | A collider grid (one cell per placeable object) used for placement checks and cheap range queries, plus bbox helpers. |
| Z order & depth | `scripts/scr_setDepth`, `scripts/scr_setup_zaxis`, `scripts/scr_update_zaxis`, `scripts/__global_object_depths` | Depth is derived from world `y` (plus z-axis stepping for climbs); `__global_object_depths` is the single table of named depths. |
| Dev tooling | `scripts/print`, `global.devMode`, `rooms/perlin_room`, `scripts/NOTES`, `python_tools/` | `print()` is prefixed with time / object name / instance id and gated on `global.devMode`. `perlin_room` is a sandbox, `NOTES` is the author's TODO list, `python_tools` edits `.yy` / `.yyp` byte-exactly. |

## 4. Towers & stats

### 4.1 Where the numbers live

| What | File |
| --- | --- |
| The four towers themselves (name, price, sprites, stats) | `objects/_levelControl/Create_0.gml` → `tower_array` (lines 60-66) |
| Stat array packing: `scr_towerData(range, damage, fire-rate, eff-obj, targets)` | `scripts/scr_towerData` |
| Stat array indexes | `scripts/tower_enums` → `enum TOWER { range, damage, fire_rate, effect, level, targets }` |
| Buying | `scripts/scr_placeTower`, `objects/obj_tower_edit` |
| Created tower | `objects/obj_tower` |
| Behaviour states | `scripts/scr_tower_normal`, `scripts/scr_tower_shoot`, `scripts/scr_tower_return` |
| Upgrade / sell UI, prices, level cap | `objects/_levelControl/Step_0.gml`, `scripts/scr_setMaxPrice` |
| Stats panel and name/level label | `scripts/scr_drawTowerStats`, `scripts/scr_drawTowerSelected`, `scripts/scr_drawTowerMod`, `scripts/scr_dataToString` |

`tower_array[i]` slot layout — `0` sprite array `[idle, attack, return]`,
`1` name, `2` price, `3` the `TOWER` data array, `4` unused (legacy object slot).
`data[TOWER.level]` starts at **1**; `tower_max_level` is **5**.

### 4.2 The towers

| # | Tower | Sprites | Price | Range | Damage | Fire-rate | DPS | Targets | Hit effect |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 0 | Daisy Pusher | `spr_t1_idle` / `spr_t1_attack` / `spr_t1_return` | 5 | 100 | 4 | 3 /s | 12 | 1 | `_eff_puff` |
| 1 | Burning Ivy | `spr_t2_idle` / `spr_t2_attack` / `spr_t2_return` | 15 | 80 | 40 | 2 /s | 80 | 1 | `_eff_acid` |
| 2 | Slender Mandrake | `spr_t4_idle` / `spr_t4_attack` / `spr_t4_return` | 45 | 125 | 125 | 1 /s | 125 | 3 | `_eff_spikes` |
| 3 | Pina Collider | `spr_t3_idle` / `spr_t3_attack` / `spr_t3_return` | 100 | 75 | 200 | 1 /s | 200 | 10 | `_eff_xplod` |

* **Fire-rate is shots per second.** `scr_tower_shoot` converts it to frames with
  `frame_number = room_speed / data[TOWER.fire_rate]` (20 frames at fire-rate 3
  and 60 fps). DPS above is damage × fire-rate against a single target.
* **Targets** is the maximum number of monsters one shot may hit.
  `find_all_range(x, y, obj_mon, range, targets)` collects up to that many
  monsters inside the circle, and `scr_do_damage` is applied to each — so
  Mandrake and Pina Collider hit several at once.
* **Watch the sprite numbering.** `tower_array[2]` is *Slender Mandrake* and uses
  `spr_t4_*`; `tower_array[3]` is *Pina Collider* and uses `spr_t3_*`. The array
  order is the shop order, not the sprite order.
* Only **Pina Collider** is flagged as AoE in the source comments, and it is the
  only one whose effect sprite is an explosion; mechanically the multi-target
  behaviour is the same `targets` count as Mandrake.

### 4.3 How a tower behaves

1. `scr_tower_normal` — plays the idle sprite and every
   `room_speed / fire_rate + time_offset` frames looks for the nearest monster
   and tests `point_in_circle(x, y, target.x, target.y, range)`.
   `time_offset = irandom_range(1, 8)` (set in `obj_tower/Create_0`) de-syncs
   towers so they do not all fire on the same frame.
2. `scr_tower_shoot` — plays the attack sprite, picks targets with
   `find_all_range`, applies damage at the end of the animation
   (`scr_do_damage`, which subtracts `damage` from `data[MON.life]` and adds it
   to `damage_amount` for the on-screen counter), then spawns one
   `data[TOWER.effect]` instance per target via `scr_damage_particles`.
   If nothing is in range it falls through to the return animation.
3. `scr_tower_return` — plays the return sprite, then back to normal.
4. `obj_tower/Step_0` then calls `scr_tower_faceTarget(target)`, which mirrors
   the tower (`image_xscale = -abs(...)` / `abs(...)`) to face the nearest
   monster it was aiming at, holds its facing when there is nothing to face,
   and ignores targets inside a ±2 px dead zone so a monster in the cell
   directly above or below cannot strobe it. The facing lives in the SIGN of
   `image_xscale` and nowhere else: `image_xscale`/`image_yscale` are ±1 and
   the art's size lives in `draw_scale` (LL-033).
5. Clicking is answered by the tower's **collision mask**. `obj_tower` carries
   `spr_tower_click_region` — 32×64, one cell wide and its own cell plus the
   one above — and `obj_tower/Step_1` sets `tower_hilight` with
   `position_meeting(mouse_x, mouse_y, id)`. There is no separate click box.
   Because the mask is two cells tall, two towers stacked a cell apart can
   both be under the pointer, so `_levelControl` picks the tower whose OWN
   cell holds the pointer.

### 4.3.1 The wave lifecycle, and the one timer that is NOT allowed to end a wave

* A wave ends in **exactly one way**: `scr_level_wait` sees
  `instance_number(obj_mon) == 0`. A monster leaves the field by being
  **killed** (`scr_zomb_death`: money + points) or by **arriving** at the
  despawn (`scr_zomb_updatePosition` -> `lose_life()`: `-1 life`,
  `level_leaked++`). At `life <= 0` the legacy main machine ends the run
  (`scr_main_normal` -> `scr_main_gameOver` -> `scr_main_highScore`). That is
  the whole risk model: let one through and you pay a life.
* The between-wave delay (`spawn_wait_time`, 5.9 s) only counts down while
  the field is clear, so it can never cut a wave short.
* The **safety valve** (`scr_level_wait`, roadmap 4.4.1) is the last line of
  defence against a soft-lock, and it fires on **evidence, not a stopwatch**:
  a monster whose `path_position` has not advanced for 5 s (`stuck_frames`,
  counted in `scr_zomb_updatePosition`) is cleared - **one monster at a
  time** - with `level_forced = true` (which blocks the *Exterminator*
  badge). A ten-minute per-wave latch (`wait_valve_fired`) guarantees a
  stage can never hang. It used to fire 6 s after the wave's last spawn and
  delete the whole wave, which ended normal rounds before any zombie could
  reach the exit - see [LL-031](../../lessons_learned.md#ll-031).
* Every monster's fate is logged under `devMode`: `META [LEVEL] kill ...`,
  `META [LEVEL] leak - life ...`, `META [PATH] WARNING: ... stuck ...`, and
  one `META [PATH] monster ... path Npx @ S px/step (~T s to the despawn)`
  per monster. If a zombie disappears, the log says which of the three did
  it.

### 4.4 Placing a tower

* `scr_placeTower(index)` refuses if `price > get_item_value(STATINV.money)`,
  otherwise it creates `obj_tower_edit` under the mouse; the mouse position is
  snapped to the 32 px cell with `((mouse_x >> 5) << 5)`.
* The ghost turns red (`spr_noPlace` frame 0) when the cell it stands on is
  taken, and `blocked_reason` holds the sentence the log prints. Occupancy is
  asked of the **pathing grid** — `mp_grid_get_cell(LEVEL.path_grid, col, row)
  with the cell index `(x + cell_w) div cell_w`, the same arithmetic
  `obj_tower/Create_0` and `scr_grid_block_instances` use — plus a `_spawn`
  mask test, because the spawn is not in the grid at all. It used to be
  `position_meeting(x, y, obj_tower)`, which asks the tower's **collision
  mask**: with the 32×64 click mask (LL-033) that made the cell *above* a
  tower read as taken, while the grid gives a tower exactly one cell and two
  towers are allowed to stand one above the other.
* On mouse release `obj_tower_edit/Step_0` refuses the placement, logs
  `META  [PATH] placement refused: <why>` and plays `snd_unable` if a monster is
  standing in the cell, if the route from `obj_spawn` no longer exists, or if a
  monster already on the map could no longer reach `obj_despawn` — **you cannot
  wall off the zombies' route**.
* Accepted placements spend `price`, then create `obj_tower` at
  `depth = -60 - (y >> 5)` and play `snd_placement`.
* `obj_tower/Create_0` blocks its own **cell** in `LEVEL.path_grid` (not a
  bounding box — LL-027), and sets `inWater = true` when the ground map value
  under it is below 2.

### 4.5 Upgrade and sell formulas

All from `objects/_levelControl/Step_0.gml` unless noted:

* **Upgrade cost** = `round(current_price * 0.50)`, then `current_price *= 2`.
* **Every upgrade** does `level++`, `damage += damage` (i.e. **doubles**),
  `range += range * 0.05` (+5% of the current range, so it compounds).
* **Visuals per level:** `draw_scale = lerp(0.25, 0.70, level / 10)` and
  `image_blend = merge_colour(c_gray, c_white, level / 10)` — the higher the
  level, the bigger and brighter. The divisor is the FIXED 10 the code uses,
  not the current cap. The size is `draw_scale`, not `image_xscale`, whose sign
  is the FACING and nothing else, so that the art's size cannot drag the
  collision mask with it (LL-033).
* **Sell** refunds 25% of the *current* price
  (`tower_price_save[1] = -round(price * 0.25)`, then
  `add_item_value(money, -tower_price_save[1])`).
* **Level cap:** `scripts/scr_setMaxPrice` sets `tower_price_save[0] = -1` and the
  button text to `Upgrade $ --` once `level >= tower_max_level` (5).
  The level cap is checked against `tower_max_level`, not against the price.

The three tables below are **derived from those formulas** — no data file holds
them, so recompute if the base stats or formulas change.

**Damage by level** (doubles each level):

| Tower | L1 | L2 | L3 | L4 | L5 |
| --- | --- | --- | --- | --- | --- |
| Daisy Pusher | 4 | 8 | 16 | 32 | 64 |
| Burning Ivy | 40 | 80 | 160 | 320 | 640 |
| Slender Mandrake | 125 | 250 | 500 | 1000 | 2000 |
| Pina Collider | 200 | 400 | 800 | 1600 | 3200 |

**Range by level** (+5% each level; the panel shows these rounded):

| Tower | L1 | L2 | L3 | L4 | L5 |
| --- | --- | --- | --- | --- | --- |
| Daisy Pusher | 100 | 105 | 110 | 116 | 122 |
| Burning Ivy | 80 | 84 | 88 | 93 | 97 |
| Slender Mandrake | 125 | 131 | 138 | 145 | 152 |
| Pina Collider | 75 | 79 | 83 | 87 | 91 |

**Costs** (base price `P`; each upgrade also doubles the price, so upgrade costs
are `0.5P, P, 2P, 4P`):

| Tower | `P` | Upg 1 | Upg 2 | Upg 3 | Upg 4 | Upgrades total | Build + all upgrades | Sell at L5 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Daisy Pusher | 5 | 3 | 5 | 10 | 20 | 38 | 43 | 20 |
| Burning Ivy | 15 | 8 | 15 | 30 | 60 | 113 | 128 | 60 |
| Slender Mandrake | 45 | 23 | 45 | 90 | 180 | 338 | 383 | 180 |
| Pina Collider | 100 | 50 | 100 | 200 | 400 | 750 | 850 | 400 |

At level 5 the stored price is `16 × P`, so selling then returns a quarter of
that (`4 × P`) and the player loses three quarters of everything invested.

## 5. Monsters & waves

Base monster table — `scripts/scr_setupSpawning`, built with
`scr_makeMonster(name, speed, life, sprite_data, kill_score, kill_money, spawn_count)`:

| Monster | Speed | Life | Sprite (walk) | Kill score | Kill money | Spawn count |
| --- | --- | --- | --- | --- | --- | --- |
| Grumble-Mulch | 1 | 7 | `spr_grumble_walk` | 10 | 1 | 5 |
| Dome-Alone | 0.5 | 12 | `spr_dome_alone_walk` | 10 | 2 | 3 |
| Professor-Cerebrisk | 1.5 | 5 | `spr_professor_walk` | 10 | 3 | 2 |
| Tusk-A-Lot (boss) | 0.5 | 55 | `spr_tusk_walk` | 100 | 50, overwritten with `wave + 1` | 1 |
| Sub-Zero (boss) | 0.25 | 110 | `spr_zero_walk` | 100 | 50, overwritten with `wave + 1` | 1 |

Slot layout is `enum MON { name, speed, life, sprite_data, kill_score, kill_money, spawn_count, maxLife, debree, portrait }` (`scripts/mon_enums`); `scr_makeMonster` copies `life` into `maxLife`. `sprite_data` is now a ONE-element array holding the creature's walk sprite: the crawl art that used to be `sprite_array[0]` is gone, and `scr_zombie_emerge` grows the monster from nothing to its full size instead. The size it grows to is `base_scale`, set by `scr_level_spawn` (0.25 for a monster, 0.5 for a boss).

`MON.portrait` is a whole portrait SPRITE (e.g. `spr_grumble_portrait`) shown by the **"Up Next..."** popup. It is set in `scr_setupSpawning` *after* each `scr_makeMonster()` call, never through it: `scr_makeMonster`'s arguments are positional and `MON.maxLife` sits at index 7, so a tenth value cannot be passed safely.

The pre-restyle art (Bald/Angry/Brainy, Tuskinator/Zero, plus `spr_bald_swim`, `spr_hair_grab`, `spr_hair_idle`, `spr_boss`) is filed under `sprites/…/Zombie Sprites/Legacy/` and is no longer referenced by code.

Wave rules (`scripts/scr_level_spawn`, `scripts/scr_level_wait`,
`scripts/scr_level_start`):

* A wave spawns `spawn_count + wave_count div 5` monsters, one every
  `game_get_speed(gamespeed_fps) * 0.5`, until the count is reached.
* The creature a wave sends is chosen by `scr_level_pick_spawn()` - the
  stage's `spawns` pool, or `bosses` on the final wave - and the choice is
  made when the level enters START or WAIT, **not** at SPAWN, so the
  "Up Next..." popup and the wave it names can never disagree. SPAWN
  consumes the stored pick rather than re-rolling.
* A stage's boss is its **final** wave (`wave_count >= _row.waves`); a
  level's `boss_every` sets any mid-stage cadence. A boss rewrites its
  `kill_money` to `wave_count + 1`.
* Health scaling (`scr_level_difficulty`):
  `life *= power(2, max(0, wave_count / 5 - 2)) + 0.2 * (wave_count - 1)`.
  The first term is zero until wave 15, and the linear `0.2` term alone applies
  before that; from wave 15 the doubling takes over (×2 at 15, ×4 at 20, ×8 at 25).
* A wave ends when `instance_number(obj_mon) == 0`; `scr_level_wait` then
  counts down `spawn_wait_time` (`game_get_speed(gamespeed_fps) * 5.9`) and
  shows the **"Up Next..."** portrait popup for the wave after this one
  (`scr_wave_preview`), before the next wave starts. The popup is closed
  the moment SPAWN begins, so it never overlaps play.
* Monsters spawn at a random `obj_spawn` object and path to `obj_despawn`;
  `scr_zomb_death` adds the kill score and kill money.
* `scr_level_start` opens with a 5.9 second countdown that also draws the
  incoming path (`scr_level_showPath`).

## 6. Where to change things

| I want to… | Change this |
| --- | --- |
| Add or retune a tower | `objects/_levelControl/Create_0.gml` → `tower_array` (price, `scr_towerData(...)`, sprite trio, effect) |
| Add a monster or boss | `scripts/scr_setupSpawning` → `spawn_mon` / `spawn_boss` |
| Change starting money / lives / wave | `objects/_levelControl/Create_0.gml` lines 44-53 |
| Change the game speed (fast-forward) | `scripts/scr_setFrameSkip` — but read §7 first |
| Change wave pacing | `spawn_wait_time` and the 0.5 s spawn interval in `scripts/scr_level_spawn` |
| Change tile art or bitmasking | `scripts/test_tile`, `scripts/set_bitmask`, `sprites/bck_tile_*_framed` (17 frames: 16 neighbour combinations plus frame 16, the "graveyard ground" fill) |
| Change the map size or noise | `scripts/scr_main_startup` (`ground_w` / `ground_h`) and `create_perlin_grid(ground_w, ground_h, 10, load_max, seed)` |
| Resize a tower's art without moving its click area | `draw_scale` in `objects/obj_tower/Create_0.gml` (0.5 placed; the placement ghost is 0.25) — `image_xscale` there is FACING ONLY (±1), so the 32×64 click mask does not scale with the art (LL-033) |

## 7. Known issues

These are already documented in `../../lessons_learned.md`; this is the short
version as it affects gameplay-facing systems.

* **`room_speed` is obsolete in GMS2 (LL-007, ~35 files).** Timers, fades and
  tower cadences can misbehave: `scripts/scr_tower_shoot`,
  `scripts/scr_tower_normal`, `scripts/scr_level_*`, `objects/_eff_*`,
  `objects/Menu/Step_0`. The fix is to read `game_get_speed(gamespeed_fps)` and
  to write `game_set_speed(60, gamespeed_fps)` instead of `room_speed = 60`.
* **Upgrade and sell prices disagree between two code paths.**
  `objects/_levelControl/Step_0.gml` lines 50-51 (re-anchoring while a tower stays
  selected) use **50% upgrade / 25% sell**, while lines 87-88 (the frame you click
  a tower) use **25% / 50%**. The panel therefore shows a different price the
  moment a tower is selected. §4.5 documents the 50/25 pair.
* **The static-inventory save path is wrong.** `scr_save_static` and
  `scr_load_static` build their filename from `working_directory` (the game
  bundle, read-only in exported builds) and default to `test.data`. It is dormant
  at the moment: `scr_setup_statinv` has the load call commented out.
  `scr_loadOptions` / `scr_saveOptions` use a bare `gameOptions.dat`, which
  GameMaker resolves into the per-user save area — that is the pattern to copy.
* **Stale balance comments.** The `/// 240 d/$` notes beside `tower_array` were
  written when Mandrake's fire-rate was 3 and Pina Collider's was 10; both are 1
  now, so those numbers no longer describe the towers.
* **Legacy state machines.** Main flow, level flow, camera, towers, monsters and
  switches still run on `scr_runState` / `scr_changeState` with numeric
  sentinels. The Menu is the only machine migrated to `enum` + `switch`
  (`scripts/scr_menu_state`); see `AGENTS.md` §3 for the list and the pattern.
* **Newer content is still settling.** `create_perlin_grid` and
  `Sprite_Layer_Manager` are fresh (October 2026). In `create_perlin_grid`, the
  `memory` cache never hits because the keys are unique per cell, and the line
  that reads it refers to `vx` / `vy`, which do not exist in that function —
  harmless today, fatal if it ever runs. `rooms/perlin_room` exists only to
  test the generator.

## 8. Region music

Every stage plays its **region's** theme, looped, for as long as the stage runs
(roadmap 5.8). The track is a property of the region, so it is a table:

| Region | Biome | Track | BPM | Asset | `loop_in` |
| --- | --- | --- | --- | --- | --- |
| — | Title / menu | *Pushing Daisies* | 68 | `mus_title` | 0 |
| 1 | Grass | *Wilted Sprouts* | 82 | `mus_world1` | 0 |
| 2 | Swamp | *Mires of the Undead* | 72 | `mus_world2` | 0 |
| 3 | Desert | *Rust in the Sun* | 88 | `mus_world3` | 0 |
| 4 | Jungle | *Vines Take the Ruins* | 78 | `mus_world4` | 0 |
| 5 | Graveyard | *Toll for the Nameless* | 70 | `mus_world5` | 0 |
| 6 | Blood Fields | *Where the Garden Ends* | 108 | `mus_world6` | 0 |

`scripts/music_data` is the single place a track is named. `music_for_region()`
hands a row to `scr_music_start_level()`, which `scr_level_start` calls when the
level enters START — so the theme is up under the deploy countdown rather than
arriving with wave 1. `scr_level_clear` calls `scr_music_stop()`, because the
clear fade is the ONE exit from a stage that does not already call
`audio_stop_all()` (game over, quit and deploy all do); without it the region
theme would follow the player onto the world map. The map then plays the menu
theme, so no screen in the game is silent.

`loop_in` is the **chorus start in seconds**: the intro plays once, then the
track loops section-to-end for as long as the stage runs. `0` means "loop the
whole track". The loop uses GameMaker's **Audio Loop Points**
(`audio_sound_loop_start` / `audio_sound_loop_end`), which are applied on the
audio thread — the manual is explicit that doing it by hand with
`set_track_position` can never be accurate, because audio runs at 44100 samples
a second and the game only looks 60 times. The points are set on the sound
ASSET, so every later play of that track inherits them.

A region whose track does not exist yet carries `sound = -1`: it plays nothing
and logs `META  [MUSIC] region 3 "Rust in the Sun" has no track yet (-1) -
playing nothing`, so a silent region explains itself instead of borrowing a
track that is not its own. No region is `-1` today - all six have a track - and
the sentinel exists only for the day a region is added before its music is.
`undefined` (no row, or a row built without a sound) is refused the same way in
its own words, because those are two different bugs.

**The guard tests VALUES, never types.** It used to be `!is_real(_sound) ||
_sound < 0`, and that is what made every stage silent while the menu theme
played on: an asset reference is not a real number, so `is_real(mus_world1)`
was false for a perfectly good
track. The play line prints `typeof(_sound)` for the same reason - the
representation is on the record rather than assumed. `audio_exists()` is not a
substitute: it throws on an index the runtime has never seen (LL-034).

The loop POINTS are only set when a row has a real chorus (`loop_in > 0`). A
whole track needs none: `audio_play_sound_on()` is already told to loop, and a
`0.0/0.0` pair would depend on the runtime reading "loop end 0" as "the end
of the file" rather than as "zero seconds".

The prompts for every track live in
`notes/Music-Generation/Music-Generation.md`, and that table and this one must
agree. `mus_worldN` is region N, which was checked by estimating each track's
tempo from its audio rather than by trusting the file name.
