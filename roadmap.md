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
| **0** | Foundations | — | a save that works, stage/difficulty data, level flow on `enum` + `switch`, `room_speed` fixed | a stage declared in **data** is playable and progress survives a restart |
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
| 0.5 | **`room_speed` → `game_get_speed(gamespeed_fps)`** in the touched files | level flow first | every status-effect timer depends on it (LL-007) |
| 0.6 | **Currency instrumentation** | new `scr_meta_log`, `print()` prefixes `META`/`SEED`/`CLOVER`/`SHARD`/`CANDY` | `economy.md` §9/§10 are guesswork without it |
| 0.7 | **Fix the latent fatal in `create_perlin_grid`** | `scripts/create_perlin_grid` | it reads `vx`/`vy`, which do not exist — harmless today, fatal the moment biomes depend on it |
| 0.8 | **Loadout/config globals** | `scripts/initialize_game` | one place for "current stage", "current difficulty", "current loadout" |

### 4.2 Gate

A stage **declared in `stage_data`** plays: its waves spawn, it ends after its wave count, and the save file survives a full game restart with its versioned contents intact.

### 4.3 Falsifier

If wave counts or spawn mixes still live in `scr_setupSpawning` rather than in `stage_data`, Phase 1 cannot proceed — the data layer is the whole point of Phase 0.

### 4.4 Explicitly NOT in Phase 0

No new screens, no currencies, no art, no balance. Phase 0 is invisible on purpose: it is the difference between a 60-stage game and a 60-times-repeated prototype.

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
| 3.3 | **Per-tower mastery screen** — spend seeds on L6–L10, see XP progress | the only place seeds and clovers meet |
| 3.4 | **Currency HUD** — all four, with a "new" highlight when one changes | so nothing is earned invisibly |
| 3.5 | **Respec** — specialization changes for seeds; tree respec for a clover fee | protects experimentation |
| 3.6 | **Garden Book navigation** — tabs for the four trees, the shop, and (later) the blood tree | one screen, five tabs |

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
| 4.6 | **Candy** — recipes (shards), stock (boxes/shop), additive stacking, caps, wave-based expiry, pause-menu activation | `economy.md` §6 |
| 4.7 | **Blood Fields modifier** — region 6's night: more elites, pity bonus | reuses 4.4 |

### 8.2 Gate

An Endless run reaches **box 5 or beyond**; a blood shard drops during a **normal** play session (not a scripted one); and a candy build plays measurably differently from the same loadout without candy.

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
| 0 — Foundations | not started | next |
| 1 — Vertical slice | not started | |
| 2 — Combat depth | not started | |
| 3 — Garden Book | not started | |
| 4 — Endless, candy, shards | not started | |
| 5 — Content | not started | |
| 6 — Balance & polish | not started | |

## 15. Change log

| Date | Change |
| --- | --- |
| 2026-10-04 | Created, out of the `goal.md` review and the approved design calls. |

