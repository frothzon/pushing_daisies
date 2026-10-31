# Garden Defense TD+ — Numerical Economy

The values of record for [`goal.md`](./goal.md): intent wins on conflict, this
file wins on numbers. Values are v1 starting points to tune from Phase 6 logs.

Last updated: **2026-10-30**.

---

## 1. The five economies at a glance

Four meta currencies and one run currency. Nothing else in the game should ever be spendable.

| | Currency | Scope | Earned from | Spent on | Stored in |
| --- | --- | --- | --- | --- | --- |
| 💵 | **Money** | **the run** | zombie kills (1–3), bosses (`wave + 1`), economy towers | tower placement, levels L2–L5 | nowhere — it dies with the stage |
| 🌱 | **Seeds** | campaign | clearing stages | unlocking the 8 towers and their region gates — **content only** | save |
| ☘️ | **Clovers** | garden | lives remaining at stage end | the four clover trees; the five master nodes | save |
| 🩸 | **Blood Shards** | account | zombie kills (pity curve), bosses (guaranteed) | blood tree; candy recipes; candy stock | save |
| 🍬 | **Candy** | run (stock) / account (recipes, levels, duration) | endless boxes, shard shop | consumed inside a run — **each unit adds time, never magnitude** | save |

**The rule that keeps this legible:** money is the only thing spent *while playing*. Everything else is spent between stages, in the Garden Book, where the player can think.

---

## 2. Seeds 🌱

### 2.1 Earning

`seeds = stage_row_seeds × difficulty_multiplier × repeat_multiplier`

Each region has a base `B` in `region_data`; its ten stage rows use the ladder
`B, B, B, B+1, B+1, B+1, B+2, B+2, B+2, B+5` from `stage_data`. The repeat
multiplier applies to that stage's difficulty-scaled reward, then floors the
result (minimum 1 seed).

| Region | Base B | Normal, 10 first clears | Hard, 10 first clears | Brutal, 10 first clears | One Normal repeat of all 10 |
| --- | ---: | ---: | ---: | ---: | ---: |
| 1 Grass | 3 | 44 | 88 | 220 | 11 |
| 2 Swamp | 5 | 64 | 128 | 320 | 11 |
| 3 Desert | 8 | 94 | 188 | 470 | 21 |
| 4 Jungle | 11 | 124 | 248 | 620 | 28 |
| 5 Graveyard | 15 | 164 | 328 | 820 | 38 |
| 6 Blood Fields | 20 | 214 | 428 | 1,070 | 51 |
| **All regions** | — | **704** | **1,408** | **3,520** | **160** |

| Multiplier | Value |
| --- | --- |
| First clear | ×1 (full) |
| Second clear | ×0.25 |
| Third and later | ×0.25 (floor) |
| Minimum award | 1 🌱 — a clear is never insulting |

### 2.2 Spending — the 12-tower roster

| Slot | Tower | Cost | Gate |
| --- | --- | --- | --- |
| 1–4 | Daisy Pusher, Burning Ivy, Slender Mandrake, Pina Collider | **free** | — (this is the first loadout) |
| 5 | 🌶️ Chillip | 25 | clear Region 1 |
| 6 | 🌱 Bindweed | 50 | clear Region 1 |
| 7 | 🥀 Thornamental | 90 | clear Region 2 |
| 8 | ☠️ Belladonna Blitz | 150 | clear Region 2 |
| 9 | 🎆 Cannon Tulip | 230 | clear Region 3 |
| 10 | 🍄 Kaboom Kalanchoe | 340 | clear Region 4 |
| 11 | 🏵️ Money Marigold | 480 | clear Region 5 |
| 12 | 🎺 Meat Bulb | 650 | clear Region 6 |

**Total: 2,015 🌱.**

### 2.3 Seeds buy content, and nothing else

There is no seed cost for power anywhere in the game:

| What buys power | Currency |
| --- | --- |
| The four rungs a tower climbs inside a stage | 💵 money (in-run) |
| The garden's **floor and ceiling** | ☘️ clover master nodes (§3.3) |
| Stat bonuses on everything | ☘️ clover trees (§3.2) |
| Run-scoped burst power | 🍬 candy stock (§6) |

Keeping seeds strictly content-only is what makes the four currencies readable at a glance (`goal.md` §1): *"Seeds unlock what you can play."*

**Overflow.** Once the roster is complete (2,015 🌱 spent), further seeds convert to clovers at **20:1**. Deliberately bad — a safety valve so a late-game player's seeds are never inert, not a rate worth farming.

### 2.4 Pacing checkpoints

| Milestone | Target |
| --- | --- |
| First unlock seed threshold (25 🌱) | 7 R1 Normal clears (26 seeds), or **2 Brutal clears** (30); the tower gate opens after the R1 boss at stage 10 |
| Half the roster (4 of 8) | end of Region 3 on a Normal/Hard mix |
| Whole roster | Regions 5–6, mixing Hard and Brutal |
| First tower to L6 | after Garden Mastery I, ~stage 12–14 |

*A Normal-only player earns 704 on first clears, or 864 after one Normal repeat of each stage (the per-stage floor makes repeats total 160) — still five unlocks, deliberately not eight.*

A seed-legal fresh-save mixed route earns **3,344 🌱**: clear R1 on Normal to
open the first tower gate, then take first clears in R2–R6 on Brutal. The 3,520
figure in the table is the sum if all 60 rows pay the Brutal first-clear
multiplier; gates make the mixed route the verified model path.

---

## 3. Clovers ☘️

### 3.1 Earning

`clovers = remaining_lives × (1 + 0.25 × (difficulty − 1)) × repeat_multiplier`

| Difficulty | Multiplier | A 20/20 clear pays |
| --- | --- | --- |
| Normal | ×1.00 | 20 |
| Hard | ×1.25 | 25 |
| Brutal | ×1.50 | 30 |

| Repeat | Multiplier |
| --- | --- |
| First clear | ×1 |
| Second | ×0.5 |
| Third and later | ×0.25 |

Life is a **per-stage budget**: every stage starts at 20 (Vitality nodes raise it). Losing all 20 ends the stage with no stage reward; nothing already banked is lost.

### 3.2 The four trees — 10 nodes each, 5 ranks per node

| Rank | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Cost (☘️) | 5 | 8 | 12 | 18 | 25 | 35 | 50 | 70 | 100 | 150 |

One branch at rank 1 across all 10 nodes: **473 ☘️**. All four branches: **1,892 ☘️**.

| Tree | Nodes 1–5 | Nodes 6–10 |
| --- | --- | --- |
| 🌿 **Vitality** | +1 max life per rank (to 25) | −life-loss penalty, regen per wave, boss survival, +1 more life, +2 more life |
| ⚔️ **Offense** | +0.4% tower damage per rank across nodes 1–5 (10% together) | +1% fire rate per rank, +1% crit chance per rank, +5% crit damage per rank, +2% and +3% damage per rank on nodes 9–10 |
| 🌱 **Growth** | −1% upgrade cost per rank across nodes 1–5 (25% together) | +3% kill money per rank, a third spec tier at L4, −10%/−20% mastery-node discounts, +2 starting money per rank |
| 💰 **Harvest** | +1% zombie money per rank | +starting money, +boss reward %, +5% seeds, +10% seeds, +15% seeds |

**Implementation mapping (2026-10-30).** The design names the effects but does not assign each one across all ten nodes and five ranks. The ten listed prices are the fixed price of each node rank; they repeat for that node’s five ranks. Rank 1 across a branch therefore costs 473 ☘, and a fully ranked branch costs 2,365 ☘. These are first-pass tuning values.

- **Vitality:** nodes 1–5 grant +1 max life per rank; node 6 reduces life loss by 5% per rank (cap 25%); node 7 restores one life per rank every fifth wave; node 8 saves one boss leak per rank per stage (cap 5); nodes 9 and 10 grant +1 and +2 max life per rank. A full branch adds 40 max life to the base 20.
- **Offense:** nodes 1–5 grant +0.4% damage per rank (10% together); node 6 grants +1% attack speed per rank; node 7 grants +1% crit chance per rank; node 8 grants +5% crit damage per rank; nodes 9 and 10 grant +2% and +3% damage per rank.
- **Growth:** nodes 1–5 grant 1% upgrade discount per rank (25% together); node 6 grants +3% kill money per rank; node 7 unlocks specialization tier 3 at L4 and adds 1% specialization stat strength per rank; nodes 8 and 9 discount mastery nodes by 2% and 4% per rank (30% together); node 10 grants +2 starting money per rank.

**Respec in the Garden Book.** Resetting one clover branch clears only that branch and refunds its recorded spend minus a fee of `max(1, floor(spent × 10%))` clovers. Resetting a tower's saved specialization costs **25 clovers**; the next L3 choice is still free. Seeds remain content-only, as required by `goal.md` §1.
- **Harvest:** nodes 1–5 grant +1% kill money per rank; node 6 grants +1 starting money per rank; node 7 grants +5% boss reward per rank; nodes 8–10 grant +1%, +2%, and +3% seed reward per rank. Money bonuses share one additive axis.

### 3.3 The five master nodes (priced separately, outside the 473 totals)

Each node raises **two** numbers by one level: the **cap** (how far a tower can go) and the **floor** (the level a tower arrives at, free, the moment it is placed).

| Node | Tower cap | Towers arrive at | Cost |
| --- | --- | --- | --- |
| Garden Mastery I | 6 | 2 | 120 ☘️ |
| Garden Mastery II | 7 | 3 | 260 ☘️ |
| Garden Mastery III | 8 | 4 | 500 ☘️ |
| Garden Mastery IV | 9 | 5 | 900 ☘️ |
| Garden Mastery V | 10 | 6 | 1500 ☘️ |

**`start = cap − 4`, always.** That single rule is what keeps the in-run money economy alive for the whole campaign:

* Cap-only mastery would put the last rungs out of reach inside one stage, so the purchase would feel like an IOU.
* Floor-only mastery would make money irrelevant.
* Moving both keeps the money climb **exactly four rungs deep** forever — worth roughly +8% damage, +4% fire rate and +3% range each, at every stage of the game.

**Mastery is account-wide:** one garden, one floor, one ceiling, for every tower. Gates: node N requires clearing region N (so region N's enemy scaling assumes the mastery a player can plausibly hold by then).

**Total to cap 10:** 3,280 ☘️ — more than the four trees (1,892) combined, which makes mastery a genuine long-term project. It is *not* the longest one, though: the candy duration track (§3.5) costs three times as much again, and is deliberately the last thing a clover-rich player finishes.

### 3.4 Pacing checkpoints

| Milestone | Target |
| --- | --- |
| One branch filled | 8–10 stages (~20–28 ☘️ per stage) |
| Garden Mastery I (cap 6) | ~stage 10–12 |
| All four branches + cap 8 | end of the campaign |
| Cap 10 | post-campaign and Endless income |

*A full campaign pays ~1,300 ☘️ (60 stages × ~22, mostly first clears). All four branches cost 1,892 — so the garden deliberately has a tail beyond the campaign. If that feels too slow in playtest, cut node 10's 150 to 120 before touching anything else.*

### 3.5 The candy duration track — the garden's longest project

Candy magnitude never stacks (`goal.md` §17): feeding in more of the same type buys **time**. Clovers buy the length of that time.

| Purchase | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Effect | +10% | +20% | +30% | +40% | +50% | +60% | +70% | +80% | +90% | **+100%** |
| Cost (☘️) | 10 | 20 | 40 | 80 | 160 | 320 | 640 | 1,280 | 2,560 | 5,120 |

**Ten purchases, the price doubling each time, +100% at the cap: 10,230 ☘️ in total.** A maxed candy is 60 s instead of 30 s.

**Why a doubling ladder is acceptable here, and nowhere else.** Doubling puts roughly half the total cost into the final purchase — exactly what a "keep this currency relevant forever" sink needs. It is only safe on a knob that **cannot break the power curve**, and duration is that knob: +100% adds no damage at all, it just means the player holds the same edge for twice as long. **Never put a doubling ladder on a stat.** That single rule is why this track exists at the end of the clover economy rather than inside a tree.

**Where it sits:** 10,230 ☘️ is about three times the whole tree investment (1,892) plus the master nodes (3,280) — so it is deliberately the *last* thing a clover-rich player finishes, which is what keeps clovers relevant long after the campaign ends. *(If playtest says that is too long, change the base cost from 10 to 4 — a 4,092 total — before touching the doubling.)*

**Why +10% and not +2%.** The original idea was +2% per purchase with the price doubling to a +100% cap. That is **50 purchases**, so the last costs `2^49 × base` — more clovers than exist in any number of playthroughs, which turns the +100% cap into a lie in the UI and leaves the effective ceiling around +16%. Either the cap comes down to ~+20% (ten purchases) or the step comes up to +10% (ten purchases). **Ten steps at +10% is chosen**, because it keeps the cap honest and the payoff legible — and it costs exactly what the +20% version would have.

---

## 4. Money 💵 and the level curve

### 4.1 The run economy

| Item | Value | Note |
| --- | --- | --- |
| Starting money | **25** | up from today's 15, because L2–L5 now cost less than doubling |
| Zombie kill payout | `base × (1 + 0.06×(wave−1))` | **ramped 2026-10-13** - `scr_kill_money`, slope in `kill_money_slope()` (card kill-money-ramp) |
| Boss payout | `wave + 1` | unchanged |
| Economy tower (Money Marigold) | +1–3 money per wave it survives, scaling with level | new |
| Harvest nodes | +1% per rank | see §3.2 |

**Measured 2026-10-13: the kill payout is a STEP function, and it inverts the
ladder.** `scr_zomb_death` pays `round(kill_money × difficulty_money_mult())`,
and the common Grumble-Mulch pays **1** - so the column is applied *after* a
round, and the base is the smallest integer there is:

| Difficulty | money column | pays per kill | income over 1-1 | hp column | **hp per dollar** |
| --- | --- | --- | --- | --- | --- |
| Normal | ×1.00 | $1 | $122 | ×1.0 | 1.00 |
| Hard | ×1.25 | **$1** | $128 | ×1.5 | **1.17 - the hardest** |
| Brutal | ×1.50 | **$2** | $247 | ×2.5 | 1.01 |

Hard's column does nothing at all (any multiplier below ×1.5 rounds back to $1)
and Brutal's *doubles*. `gm balance sim` turns that into an outcome: **Brutal
clears 1-1 with 20 hearts and $22 spare, where Hard leaks 19 and survives on
one** - and fails outright on fast ground (z=2). So the money column cannot be
tuned in place; it needs a fractional accumulator, a higher base payout, or the
rounding moved. See LL-042 and the `difficulty-columns-vs-curve` card.

**FIXED 2026-10-13.** The column keeps the value it was given and the FRACTION is
CARRIED instead of rounded: `scr_kill_money` pays `floor(base × ramp × column +
carry)` and leaves the remainder on `_levelControl`'s `money_carry`, so money is
still a whole number everywhere and a ×1.25 column really is +25% over a wave.
Measured after, on 1-1:

| Difficulty | income | vs Normal | hp per dollar |
| --- | --- | --- | --- |
| Normal | $160 | ×1.00 | 0.0063 |
| Hard | $196 | ×1.23 | 0.0076 |
| Brutal | $264 | ×1.65 | 0.0095 |

The ladder is ordered again - hp per dollar RISES with the difficulty, which is
what "harder" is supposed to mean - where it was 1.00 / 1.17 / 1.01. The income
figures now include the wave ramp, so they are not comparable to the
$122 / $128 / $247 measured above.

### 4.2 Placement prices

All 12 towers are present in `scr_tower_roster()`. Combat towers show their
base numbers; Money Marigold is passive and earns dividends rather than attacking.

| Tower | Price | Range | Damage | Fire rate | Targets | In the build? |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Daisy Pusher | 5 | 100 | 4 | 3 | 1 | **built** |
| Burning Ivy | 10 | 80 | 40 | 2 | 1 | **built** |
| Slender Mandrake | 20 | 125 | 100 | 0.35 | 3 | **built** |
| Pina Collider | 40 | 75 | 250 | 0.10 | 10 | **built** |
| Chillip | 15 | 90 | 8 | 1.5 | 1 | **built** (25 🌱, Region 1) |
| Bindweed | 40 | 70 | 5 | 1 | 2 | **built** (50 🌱, Region 1) |
| Thornamental | 60 | 110 | 100 | 2 | 1 | **built** (90 🌱, Region 2) |
| Belladonna Blitz | 55 | 85 | 12 | 4 | 2 | **built** (150 🌱, Region 2) |
| Cannon Tulip | 60 | 200 | 60 | 0.5 | 5 | **built** (230 🌱, Region 3) |
| Kaboom Kalanchoe | 150 | 80 | 120 | 1 | 6 | **built** (340 🌱, Region 4) |
| Money Marigold | 35 | — | — | — | — | **built** (480 🌱, Region 5; passive) |
| Meat Bulb | 80 | 90 | 250 | 0.75 | 1 | **built** (650 🌱, Region 6) |

**Control tuning (2026-10-30):** Chillip slows to 25% movement speed (75% slow)
for 1.5 s on every hit; Bindweed roots for 1.3 s with a 100% proc chance.
Root duration scales to 0.78 s on elites and 0.39 s on bosses. Thornamental
damage is 100 per hit. These values keep the ordinary slow within goal.md's
75% cap and retain class resistance; they tune control to hold fast waves.

Money Marigold pays $1 at L1–L2, $2 at L3–L4, and $3 at L5 per cleared wave.
At L6–L10, its dividend grows by the same +8% per level as the tower mastery
ladder. Compound Interest raises the dividend by 5%, 5%, and 8% across the
three tiers; at L5 its signature compounds a 2% base bonus per cleared wave,
up to 20%. Golden Harvest adds $1, $1, and $2 per wave, then pays a $5 bonus on
every fifth cleared wave at L5. Both signatures scale with Growth's
specialization-strength bonus. Fractional income carries through the same
run-level money accumulator as kill payouts.

These are the starting balance values. The tower and economy review cards still
own the playtest tuning; the roster and unlock prices now match §2.2 and the
actual code.

**REBUILT AGAINST THE CODE 2026-10-14** (`economy-4-2-stale`): the Cannon Tulip
and Meat Bulb rows read **120 / 220 / 150 / 0.5 / 1** and **200 / 140 / 400 / 1 /
1** until today — numbers from a twelve-tower plan that were never built, sitting
in a table whose built rows are the game. They now read `scr_tower_roster()`
verbatim, which is what the tool reads: Cannon Tulip **60 / 200 / 60 / 0.5 / 5**
and Meat Bulb **80 / 90 / 250 / 0.75 / 1**. The two rows were wrong in every
column *except* fire rate, so anything derived from them (a `dps` figure, a
`d/$` ratio) was wrong by 2x–5x. `gm balance towers` prints the built rows from
the same table, so the two can be diffed by eye.

**REPRICED 2026-10-13** (`economy-prices-rebalance`): the four starters are
**5 / 10 / 20 / 40**, from 5 / 15 / 45 / 100. The old ladder was a 3x-then-3x-
then-2.2x climb against an income that starts near $30 a wave, so the $45 and $100
towers arrived on waves 9 and 12 of 15 - the second half of the roster was a
one-wave decision, which is why the measurable ladder was really "Daisy, then
Ivy". All four are affordable by wave 6 now.

**Historical consequence, measured immediately after the 2026-10-13 reprice:**
with that snapshot of the roster, stage 1-1 at `curve_end` **13** read a worst
bite of **0.32**, below the panel's 0.35 floor; the old cap 30 read 0.73. Later
tower-stat changes mean those readings are not a current result. The 2026-10-30
Normal fit for regions 4-6 is recorded in §4.5; Region 1 and regions 2-3 still
need a current all-stage pass. The former Cannon / Meat unlock prices (25 / 40
🌱 behind Region 1) are retired: §2.2 now sets the full roster's gates and costs,
and the code follows that table.

**⚠ The `Targets` column did nothing until 2026-10-13 (LL-039).** `find_all_range`
read `array_last_index(_targets)` and then wrote at that same index, so the list
could never hold more than one monster and *every tower in the game was
single-target*. A Slender Mandrake with `targets = 3` hit one monster for 125; a
Pina Collider with `targets = 10` hit one monster for 200. The roles this table
assigns — "multi-target" and "area damage" — did not exist, and the shop's
`damage × rate × targets` was arithmetic about a column nothing read.

`targets` is the distinct-enemy cap; `projectiles` is the number of direct-hit
packets each selected enemy receives. The roster's aggregate nominal DPS is
`damage × rate × targets × projectiles`. Every base tower currently has one
projectile, so the table below is unchanged. The selected-tower card shows the
per-target figure (`damage × effective shots/s × projectiles`, including
expected crit), which is the value one enemy receives before coverage and
overkill. Rapid Bloom's signature raises its projectile count to two without
raising its target cap.

That is now fixed, so **the multipliers in this table are real for the first
time**, and the curve is calibrated for the world where they were not:

| tower | `targets` | shop dps (now real) | what it was |
| --- | --- | --- | --- |
| Slender Mandrake | 3 | 375 | 125 |
| Pina Collider | 10 | 2000 | 200 |
| Cannon Tulip | 5 | 150 | 30 |

Nothing else changes: `targets = 1` was the only case where the old code was
correct, which is why Daisy Pusher, Burning Ivy and Meat Bulb always behaved.
**A price or curve set against these numbers must be re-derived with them**
(`economy-prices-rebalance`, `difficulty-columns-vs-curve`) — Pina Collider is
ten times the tower it was, and `curve_end = 13` was fitted when it was not.

**⚠ The `Fire rate` column was an overstatement too, until 2026-10-13 (LL-040).**
One shot walks `idle → attack → return`, and *two* of those three states each
spent a whole fire period: `scr_tower_normal` waited
`room_speed/fire_rate + time_offset` before it would even look for a target, and
`scr_tower_shoot` then spent `room_speed/fire_rate` — its own comment says *"the
attack's length IS the fire rate"*. The cycle was therefore `2P + off + 15`, not
`P` (`P = 60/fire_rate`, `off` = the per-tower `time_offset`, mean 4.5):

| tower | `fire_rate` | P | cycle before | cycle now | real dps before → now |
| --- | --- | --- | --- | --- | --- |
| Daisy Pusher | 3 | 20 | 59.5 | 39.5 | 4.0 → 6.1 |
| Burning Ivy | 2 | 30 | 79.5 | 49.5 | 30 → 49 |
| Slender Mandrake | 1 | 60 | 139.5 | 79.5 | 54 → 94 |
| Pina Collider | 1 | 60 | 139.5 | 79.5 | 86 → 151 |
| Cannon Tulip | 0.5 | 120 | 259.5 | 139.5 | 14 → 26 |
| Meat Bulb | 0.75 | 80 | 179.5 | 99.5 | 84 → 151 |

*(the dps column uses the **built** roster's `damage`, read from
`scr_tower_roster`, not the aspirational table above — see `economy-4-2-stale`.)*

The fix is a **1.5x–1.9x** buff and it is **not flat** — the slower the tower
fires, the more it gains — so it moves the *order* of this roster, not just its
scale. A residual remains even after it: the card still overstates by 1.3x–2x,
because the 0.25 s `return` animation is charged *on top of* a `fire_rate` that
nominally means "shots per second" (`fire-rate-vs-animation-length`).

Together with the note above, **every `dps` figure in this section is NOMINAL.**
Between `targets`, the fire cycle and coverage — a tower only fires while
something is actually in range, which on 1-1 is 9–15% of the route — Pina
Collider's 2000 dps is nearer **8** on the board. This document's job is to name
the *intent*; only the sim (`balance-sim`) converts nominal into delivered, and
nothing here should be fitted by arithmetic alone (LL-038).


### 4.3 Upgrade prices (in-run money) and refunds

| Level | Cost | Cumulative |
| --- | --- | --- |
| L2 | 0.50 × base price | 0.50 |
| L3 | 0.75 × base price | 1.25 |
| L4 | 1.00 × base price | 2.25 |
| L5 | 1.50 × base price | 3.75 |

**Sell refunds 60% of everything invested** (placement + upgrades), returning part of the commitment when the player experiments with a loadout.

*Growth tree nodes reduce all four prices by up to 25%.*

### 4.4 What a level gives (replaces today's doubling)

| Level | Damage | Fire rate | Range | Unlocks |
| --- | --- | --- | --- | --- |
| L1 | ×1.00 | ×1.00 | ×1.00 | — |
| L2 | ×1.08 | ×1.04 | ×1.03 | — |
| L3 | ×1.17 | ×1.08 | ×1.06 | **specialization choice** |
| L4 | ×1.26 | ×1.12 | ×1.09 | spec tier 2 (Growth tree: tier 3) |
| L5 | ×1.36 | ×1.17 | ×1.12 | **signature ability** |
| L6 | ×1.47 | ×1.21 | ×1.15 | — |
| L7 | ×1.59 | ×1.26 | ×1.19 | — |
| L8 | ×1.71 | ×1.31 | ×1.22 | — |
| L9 | ×1.85 | ×1.36 | ×1.26 | — |
| L10 | ×2.00 | ×1.42 | ×1.30 | — |

**The ladder and stage curve are coupled.** The current base-relative L1–L10 table replaces the former compounding path to ×16 damage at L5. Refit stage difficulty and rerun the balance checks whenever the ladder changes; changing only one side invalidates the tuning.

**Which rows money actually buys.** A tower *arrives* at the garden's floor (`goal.md` §4; `start = cap − 4`) and the four rows above that floor are the ones bought in-run. So at mastery V, money buys L7→L10 (×1.59 → ×2.00) — still about +8% per rung, because the rungs are defined against the base rather than compounding. **The relative value of money never changes, at any point in the campaign**; that is the entire reason the floor and the cap move together.

**Level visuals use the fixed ten-level ladder.** Towers keep their placed size; the ring color carries the absolute level from 2–10, and the hover label supplies the exact level. The ring is not normalized to the current mastery cap (`goal.md` §4).

### 4.5 Wave count and biome curve

Waves are no longer authored per stage. They are a **rule**, held in `region_data()`:

| | Value |
| --- | --- |
| Waves in stage 1 | **15** |
| Extra waves per stage | **+5** |
| Stage 10 | **60** |

Every biome starts at 15 and climbs by the same 5, so **all six regions share the
15…60 wave counts**. What separates them is the *curve*:

```
m(w) = 1 + (curve_end - 1) * ((w - 1) / (waves - 1)) ^ curve_pow
```

| Region | Biome | curve_end | curve_pow |
| --- | --- | --- | --- |
| 1 | Grass | **13** | 2 |
| 2 | Swamp | **19** | 2 |
| 3 | Desert | **26** | 2 |
| 4 | Jungle | **18** | 2 |
| 5 | Graveyard | **16** | 2 |
| 6 | Blood Fields | **10** | 2 |

`m(1) = 1.00` in **every** biome — *"wave 1 of any stage in the game is the same
fight"* — which is what lets one set of tower numbers survive sixty stages. The
bend is 2 because a stage's money grows with the **square** of the wave number
(§4.1: `spawn_count + wave div 5` kills a wave); a straight line makes the late
waves relatively *easier*, which is the opposite of a ramp.

`STATINV.waves` is seeded at **0**, so the speed ramp, HUD, and `wave_count`
refer to the same wave (LL-044). The current endpoints are 13 / 19 / 26 / 18 /
16 / 10 for regions 1-6. `gm balance fit --sim` tested all ten stage lengths
in regions 4-6 at their current endpoints; all 30 Normal ceiling-buy simulations
cleared without leaks. A separate all-region check found three distinct
progression-available replay builds for every Normal row: 180 deterministic
instant-buy simulations cleared with 20 lives and zero leaks.

A seed-aware first-clear route also cleared all 60 Normal stages in the model.
It uses the four starters in R1; buys Chillip for 25 seeds after the R1 gate and
uses it from R2 through R3-7; then buys Thornamental for 90 seeds after R3-1 and
uses it from R3-8 through R6-10. The 60 deterministic instant-buy runs used
terrain z=6, no clovers, candy, or specialization, and all ended with 20 lives
and zero leaks. This proves one model route, not live player winnability or
Hard/Brutal coverage. The starter-only policy still loses late R2/R3 stages,
which is why progression unlocks matter. Refit after tower or economy changes.

**Diagnostics.** `scr_curve_report()` logs and `scr_curve_draw()` displays the
curve under `global.devMode`: biome endpoints, route and reachable slots,
placement/rung DPS-per-dollar, and wave 1 / first boss / final wave rows with
`req`, `bite`, and `LOW` / `HIGH` / `ok`. The target band is wave 1 `bite >=
0.35` and final-wave `bite <= 0.90`.

```
required  = count * hp / walk_seconds
available = min(money / price, slots) * best_placement_dps
```

The in-game supply panel is deliberately approximate; `gm balance` is the
authority. Its nominal fire-rate display is tracked separately by
`tower-panel-effective-rate`.

**Accepted combat/economy decisions:**

* Charge the return animation and stagger in the real shot cycle.
* Do not heal monsters when their emerge animation finishes.
* Leaks pay **half** the corresponding kill, scaled **before** flooring and
  using the same fractional carry as difficulty payouts (LL-042).
* Keep region 1's cap at 13 unless a later fit or play log reopens it.

### 4.6 The rung price and its worth disagree — kept on purpose (decided 2026-10-14)

§4.3's prices and §4.4's ladder are inconsistent, and the code now implements
both faithfully, so the inconsistency is live:

| per **1 unit** of money | DPS added |
| --- | --- |
| Place another tower | **+1.00 ×** base |
| Buy the four rungs (§4.4) | +0.59 × base for 3.75 units = **+0.16** |
| *(the old doubling, for comparison)* | *+15 × base for 7.5 units = **+2.00*** |

So a rung is **~6× worse value than another placement**, and "money buys the
four rungs" stops being a decision — which defeats goal.md §4 and the whole
point of the floor/cap pair. The inequality to satisfy is:

```
ΔDPS from the four rungs  ÷  Σ(rung prices)   ≥   DPS-per-money of a placement
```

Two ways out, and either is a one-table change:

* **Steepen the ladder** (preferred — keeps §4.4's legible non-compounding
  shape): damage ×1.00 / 1.60 / 2.20 / 2.80 / 3.40, DPS ×3.9 at L5 for 3.75
  units ⇒ ≈1.0 per unit, so a rung pays for itself.
* **Cut the rung prices** to total ≈1.0 unit (0.15 / 0.25 / 0.30 / 0.30).

Decide this before Phase 2 tuning, because every wave curve value in §4.5 is
measured against whichever answer wins.

**As built 2026-10-12.** The `scr_curve` diagnostic prints the two sides of this
inequality as `dps per $ : place <a>  rung <b>`, read from the live
`tower_array`, and flags it `<- rung is dominated (economy 4.6)` when the rung
loses. So the choice below is arithmetic in the log rather than a feeling — and
it re-reports automatically once either the ladder or the prices move.

**DECIDED 2026-10-14 (status quo, `choose-rung-price`): the mismatch STAYS.**
The ladder is not steepened and the rung prices are not cut, so a rung remains
~6x worse per money than another placement on stage 1-1 — measured, printed,
and accepted. The reasoning is the diagnostic itself: the numbers are on screen
every stage (`dps per $ : place a  rung b`), so a player who upgrades is
choosing a worse deal knowingly, and the alternative (another placement) is
capped by free cells and coverage long before the ladder is. Treat any future
"fix the rung price" as a NEW decision to reopen this one, not as an open bug.

---

## 5. Blood Shards 🩸

### 5.1 The pity curve (this replaces "increases slightly")

```
p = kills since the last shard
c = 0.0001                                             # base: 1 in 10,000
if p >= 8000: c = 0.0001 + 0.00003 * ((p - 8000)/1000)  # soft pity, +0.003%/1k kills
if p >= 20000: c = 1.0                                  # hard pity: guaranteed
on drop: p = 0
```

| Kills since last shard | Chance per kill | Cumulative chance of a shard by then |
| --- | --- | --- |
| 0 | 0.0100% | 0.01% |
| 1,000 | 0.0100% | ~9.5% |
| 5,000 | 0.0100% | ~39% |
| 8,000 | 0.0100% | ~55% |
| 10,000 | 0.0160% | ~69% |
| 14,000 | 0.0280% | ~88% |
| 18,000 | 0.0400% | ~97% |
| 20,000 | 100% | guaranteed |

**Expected kills per shard: ~9,000.**

| Assumption | Value |
| --- | --- |
| Kills per stage | ~100–400 (3 zombie types × `spawn_count + wave div 5` × ~10 waves) |
| Kills per full campaign sweep | ~12,000–15,000 |
| Therefore first shard | **region 3–4** |
| Bosses | **always drop exactly 1 shard** |

The boss guarantee is the safety valve: even a player on a cold streak gets a shard from every region boss, so the currency can never feel dead.

### 5.2 The blood tree — nodes in "−kills required"

| Tier | Node | Effect | Cost (shards) |
| --- | --- | --- | --- |
| 1 | Blood Magnet | −10% kills required | 2 |
| 2 | Hemorrhagic Harvest | −25% kills required | 4 |
| 3 | Crimson Appetite | elites can drop an extra shard | 8 |
| 4 | Blood Moon | a whole wave can roll boosted pity | 12 |
| 5 | Crimson Garden | unlocks blood content (region 6) | 20 |

**The blood tree is finite by design (46 shards total).** That is deliberate: a rare currency needs a *finished* goal and an *unfinished* one. The finished one is this tree; the unfinished one is **candy levels** (§6.4), which is where a shard goes forever after.

**One axis, never two.** Blood Magnet (−10% kills required) and the rare **Blood Orange** candy (§6.5) both modify the *same* number — the pity fill rate — so they **add** into one multiplier: `fills = 1 + 0.10 + 0.10` at tier 1 with an L1 Blood Orange, never `1.10 × 1.10`. Without that rule the two systems would silently compound and the shard curve would drift every time a node or a candy was tuned.

**Why "−kills required" and never "+drop rate":** the base chance is 0.01%. A +10% bonus on that is 0.011%, which no human can perceive in a lifetime of play. Every node in this tree must change something the player can *feel* — fewer kills needed, an extra shard, or a visibly different wave.

*If `Crimson Appetite` and `Blood Moon` test as invisible in Phase 4, replace them with flat extra shards per boss (a number the player can see) rather than nerfing the idea away.*

### 5.3 Blood Fields night

After buying Crimson Garden, every fifth wave in campaign Region 6 becomes Night. The current tuning guess raises the elite spawn chance from 5% to 15% and adds +1 effective pity progress per kill for that wave. This bonus adds to Blood Moon and Blood Orange fill bonuses on the same pity axis; boss kills keep their guaranteed +1 shard rule.

---

## 6. Candy 🍬

### 6.1 Recipes, levels, and stock — three different things

| Thing | What it is | Cost / source |
| --- | --- | --- |
| 🍬 **Recipe** | permanent unlock of one candy type | 3 / 8 / 20 shards for tiers 1 / 2 / 3; 35 shards for each gated tier-4 rare recipe (§6.5) |
| 🍬 **Level** | permanent power of that candy, 1 → 10 | shards, escalating (§6.4) |
| 🍬 **Stock** | the units actually spent in a run | Endless boxes, and a shard shop at 1 shard = 5 candies |

**Recipes and levels are permanent; stock is consumed.** A player's shard income therefore always has three jobs to choose between: *open a new candy*, *sharpen one they have*, or *buy a burst of stock for tonight's run*. That is the whole design of the blood economy after the blood tree is finished, and it is why shards never stop mattering.

### 6.2 The candies, and what a level does to them

Each level adds one unit of **that candy's own** stat, so the growth is always legible in the UI as `+10% → +19%` rather than as an abstract "level".

| Candy | Tier | Effect at **L1** | Per level | At **L10** | Duration |
| --- | --- | --- | --- | --- | --- |
| 🍬 **Red Licorice** | 1 | +10% damage | +1% | **+19%** | 30 s |
| 🍬 **Jawbreaker** | 1 | +10% range | +1% | +19% | 30 s |
| 🍬 **Gummy Worm** | 1 | +15% slow effectiveness | +1.5% | +28.5% | 30 s |
| 🍬 **Sour Drop** | 2 | +10% crit chance | +0.5% | +14.5% | 30 s |
| 🍬 **Fireball Candy** | 2 | +20% burn damage | +2% | +38% | 30 s |
| 🍬 **Frosted Flake** | 2 | +10% fire rate | +1% | +19% | 30 s |
| 🍬 **Blood Bonbon** | 3 | +25% damage, +5% crit damage | +2% / +1% | +43% / +14% | 30 s |
| 🍬 **Everlasting Gob** | 3 | **freezes every active candy timer** for 1 wave (+1 wave per 3 levels) | +1 wave / 3 levels | 4 waves frozen | — |

**Every candy lasts 30 seconds**, and **duration never changes with level** (except the Gob, which is *made* of duration). Levels buy magnitude; clovers buy time (`§3.5`). That keeps the pause-menu decision simple — *which candy, and when* — instead of *how many can I stack*.

**The Gob is the tier-3 capstone** precisely because it is the only candy whose effect is time-shaped: it does not add power, it stops the clock on everything already running, which is what you want when a boss wave lands.

### 6.3 Duration, not stacking

| Rule | Value |
| --- | --- |
| Base duration | **30 seconds** per candy consumed |
| Consuming more of the same type | **adds** 30 s to the remaining timer — it does not restart it |
| Maximum duration | none from the rules; your **stock** is the limit |
| Different types | run side by side, each with its own timer, one instance of each type at a time |
| Magnitude | fixed by the candy's **level**; it never stacks, ever |
| Duration bonus | up to **+100%** from the clover track (§3.5), so 60 s per candy |
| When the timer ticks | **only while a wave is live** — not during the countdown, and not during the ~6 s between-wave wait |
| Speed | the timer counts **game frames**, so fast-forward does not shorten it in waves; the pause menu freezes it |

**What this replaced, and why.** The earlier draft stacked candies additively — ten maxed Red Licorices were +190% damage. That is a blow-up waiting to happen, and it turned the pause menu into a "how much can I spike?" button. Under the duration model the same stock buys **+19% damage for as long as you feed it**, so the ceiling is bounded by *time* instead of by a cap table. Three things got simpler as a result: no per-type cap, no total cap, and no stacking exception needed for the rare candies (§6.5).

**The trade.** Candy stops being an explosion and becomes **reliability** — the thing you start before an elite wave and then hold. If the spike is missed in playtest, raise a candy's level-10 magnitude (say +19% → +25%); **never bring stacking back.**

**30 s ≈ the old "5 waves"** (a wave runs roughly 6–10 s), so this is a legibility change as much as a balance one: a countdown the player can watch is more tangible than a wave counter, and "start it now, it lasts 30 seconds" is a decision anyone can make.

---

### 6.4 Candy levels — the unbounded shard sink

Levels are permanent, per candy, and bought with shards:

| Level | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **Cost (shards)** | 2 | 3 | 4 | 6 | 8 | 11 | 15 | 20 | 26 |

**95 shards per candy. 950 for all ten recipes.**

Sanity-checked against shard supply:

| Source | Shards |
| --- | --- |
| One full campaign sweep (~12,000–15,000 kills) from the pity curve | ~1.5 |
| Plus the 6 region bosses (guaranteed) | 6 |
| **Per sweep** | **~7.5** |
| A good Endless run (boxes 1–8) | 3–8 |
| Blood tree, complete (one-off) | 46 |

So **the first two levels cost 5 shards** — about two thirds of one campaign sweep — which is why early investment is felt immediately. One candy to L10 is roughly **a dozen sweeps**; taking all ten to L10 is the lifetime project. That curve is the whole point: it is the only shard sink that never ends (`goal.md` §16).

**A level never touches the duration.** Levels buy magnitude, clovers buy time (§3.5): a level-10 candy is still exactly 30 seconds — 60 with the clover track maxed — it just does more per second.

### 6.5 Special candies — rare, meta, and deliberately single

Two candies act on the **economies** rather than on combat — and because nothing stacks any more (§6.3), they need no special rule to stay bounded.

| Candy | Tier | Effect at **L1** | Per level | At **L10** | Duration |
| --- | --- | --- | --- | --- | --- |
| 🍊 **Blood Orange** | 4 (rare) | kills count **1.10×** toward the next blood shard | +0.10× | **2.00×** | 30 s |
| 🍯 **Money Honey** | 4 (rare) | **+15%** money from every kill | +1.5% | **+28.5%** | 30 s |

**Recipe: 35 shards each. Gated:** Blood Orange requires the blood tree's tier 2 (*Hemorrhagic Harvest*); Money Honey requires region 4 cleared. Neither can therefore distort the early economy.

**The class rules — so this stays two candies and never becomes twenty:**

1. **Rare** — tier 4, 35 shards, and the gates above.
2. **Nothing stacks any more.** That is now the universal rule (§6.3), so the rare candies need no exception. Their specialness is their tier, their gate and their meta effect — and feeding more Blood Orange buys more *time*, never more than 2× pity fill.
3. **They act on systems the player can see.** Money is already visible; **Blood Orange's other job is to make the pity counter visible** — while it is active, the counter and its multiplier are shown, counting up. An invisible statistical buff is not a reward (the §5.2 rule, restated for candy).
4. **They accelerate; they never grant.** No candy can pay out a currency directly. That is the rule that keeps candy as *temporary power* instead of a farm, and it is what stops an "activate candy, get paid, repeat" loop.
5. **Shared axes sum.** Money: Harvest (+5%) + Growth (+15%) + Money Honey (+29%) — one axis, added. Pity: blood tree + Blood Orange — one axis, added. Nothing multiplies with anything else on its own axis.

**Why they earn their slot.** Every other candy answers *"how do I win this run?"*. These two answer *"what kind of run am I having?"* — one farms the account, one accelerates the garden. Each hooks into exactly one existing line (`scr_zomb_death:7` for kill money; the pity increment for shards), so they are cheap to add and impossible to accidentally over-couple.

**Guarded risk:** a sustained Blood Orange could compress the shard economy. The bounds are structural rather than numeric — 30 s per activation, one instance at a time, and the hard pity cap at 20,000 kills still applies, so the floor under the chase can never be pulled up far enough to make shards routine.

---

## 7. Endless loot boxes

### 7.1 Box spacing — `next = ceil(previous × 1.20)`

| Box | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 | 15 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Wave | 10 | 12 | 15 | 18 | 22 | 27 | 33 | 40 | 48 | 58 | 70 | 84 | 101 | 122 | 147 |

*(The sequence is mathematically correct as specified in `goal.md` §19 — verified: ceil(10×1.2)=12, ceil(12×1.2)=15, ceil(15×1.2)=18, ceil(18×1.2)=22 …)*

### 7.2 Tier weights

| Box tier | Boxes 1–5 | Boxes 6–14 | Boxes 15+ |
| --- | --- | --- | --- |
| Common | 50% | 35% | 20% |
| Uncommon | 28% | 30% | 30% |
| Rare | 14% | 22% | 28% |
| Epic | 6% | 10% | 16% |
| Legendary | 2% | 3% | 6% |

### 7.3 What a tier offers (before scaling)

| Box tier | Seeds | Clovers | Shards | Candy |
| --- | --- | --- | --- | --- |
| Common | 5–10 | 10–20 | — | 1–2 |
| Uncommon | 10–20 | 20–35 | 1 | 2–4 |
| Rare | 25–45 | 40–70 | 1–2 | 3–6 |
| Epic | 50–80 | 80–120 | 2–3 | 5–8 |
| Legendary | 100 | 150 | 5 | 10 |

`amount = round(base_roll × (1 + 0.15 × box_index))`

**The player is offered three of these and picks one** (`goal.md` §21). The three offers are drawn from different tiers where possible, so the choice is real: one box should rarely be "all common".

### 7.4 Escape hatches built in on purpose

| Situation | Behaviour |
| --- | --- |
| A box offers three things the player cannot use | a re-roll is available once per box |
| A run reaches wave 500 | the run ends with a score, for the leaderboard's sanity |
| The player has cap 10 on everything | box seeds convert to clovers at 1:2, and clovers to shards at 100:1 |

---

### 7.5 Endless modifiers

The Endless bands follow `goal.md` §22. The wave-40 Hardened band uses **35% more HP** (`HP x1.35`) as the v1 proxy for armor: `goal.md` §2 cuts armor to avoid adding a second resistance matrix. Waves 80–89 force the existing elite class (1.5x health, 1.1x speed); the Endless band does not multiply that health bonus a second time.

### 7.6 Endless milestone currency

Every **10 cleared waves**, Endless banks a small Seeds and Clovers payout in addition to loot boxes. Each milestone earns **2%** of the full first-clear Seeds reward for the region/stage represented by that Endless wave, plus **2%** of the current-life Clovers reward at the run's difficulty. The Clovers baseline is recomputed from lives after the wave's regeneration.

Fractions carry independently across milestones for the duration of the run; only whole currency is added and saved. A path-safety-forced wave does not earn its milestone payout. This keeps Endless progress tied to the current campaign economy without rounding every small share down to zero.

## 8. Badges 🏅 (medals only in v1)

One medal per badge per stage, stored in the save. **No art in v1** — the record is the reward.

| Badge | Condition | Notes |
| --- | --- | --- |
| 🏅 **Untouched** | finish with 20/20 lives | the clean clear |
| 🏅 **Frugal** | total gross spend < the stage's `par_spend` | `par_spend` is an exclusive cutoff authored per stage in `stage_data` and shown in Deploy |
| 🏅 **Botanist** | place all 4 loadout tower types | interacts with `goal.md` §3.1 |
| 🏅 **Purist** | place exactly 1 tower type | **first clear only**, so it cannot be farmed with a degenerate loadout |
| 🏅 **Exterminator** | no zombie reaches the despawn point | |
| 🏅 **Speed Grower** | finish under the stage's `par_time` | authored per stage |
| 🏅 **Brutalist** | complete the stage on Brutal | the difficulty badge |

**Threshold method (2026-10-30).** Each stage uses nine seeded Normal model clears: three replay-eligible four-tower loadouts, each run with three seeds. The 540 sampled runs cleared with 20 lives and no leaks. `par_spend` is `ceil(median gross spend / 2)`. Frugal awards only when spend is *strictly below* that exclusive integer cutoff, so the requirement remains below half the median. `par_time` is the smallest whole-second cutoff strictly above the nearest-rank 75th-percentile clear time. The original sample used the real fire cycle, instant buying, fixed terrain z=6, and elapsed time from first wave spawn through clear, matching `level_elapsed_seconds` without the deploy countdown. After the corpse-lifecycle correction (LL-092), every modeled clear waits for the source-backed 48-frame / 0.8-second DIE duration after the last kill in each wave. Every stage has 15–60 waves in steps of five, so the elapsed time increases by an exact integer `waves × 0.8s` for every run in that stage. The p75 and exclusive whole-second cutoff therefore shift by that same exact amount; all 60 `par_time` values were updated, while `par_spend` stays unchanged. New times span 213–989 seconds. These are model-derived first-pass thresholds, not player telemetry. The sampled runs used no Candy, specializations, or mastery. The simulator now reads specialization tiers, Growth scaling, and implemented signatures from GML, but those effects remain absent from this threshold sample.

**Total available:** 7 × 60 stages = **420 medals**, plus 6 region-completion medals (one per boss) = **426**.

*`par_spend` and `par_time` are the only two numbers a designer must author per stage. Everything else derives from the region table, which is what keeps 60 stages cheap.*

---

## 9. Validation checkpoints — the only numbers that decide if this is right

| # | Checkpoint | Target | Verified in |
| --- | --- | --- | --- |
| 1 | First tower unlock | after the R1 boss; the gate opens and 44 Normal first-clear seeds can buy Chillip | Phase 1 playtest |
| 2 | Early Brutal beats a Normal grind | a Brutal clear ≥ 3× a Normal clear (5× by construction) | Phase 1 by arithmetic |
| 3 | Normal-only cannot buy the roster | 864 🌱 after first clears plus one repeat of every stage < 2,015 🌱 needed | arithmetic |
| 4 | Garden Mastery I — cap 6, towers arrive at **2** | ~stage 10–12 | Phase 3 |
| 5 | First blood shard | region 3–4 | Phase 4, from the kill counter |
| 6 | Every stage clearable by ≥ 3 loadouts | no stage has a single correct answer | Phase 2 |
| 7 | Nothing is inert | every currency earnable *and* spendable at every point in the campaign | Phase 3 gate |
| 8 | First candy levels (L2–L3, 5 shards) | inside the first campaign after the first shard | Phase 4 |
| 9 | First candy to L10 (95 shards) | ~a dozen campaign sweeps — long, but visibly progressing | Phase 4 |
| 10 | A maxed Blood Orange + blood tree tier 2 | pity fills ~2× for 30 s at a time, never stacked — a *window*, not a farming engine | Phase 4 |
| 11 | Candy duration track — first purchase | 10 ☘️ for +10%, buyable inside region 1, so every player feels it | Phase 3 |
| 12 | Candy duration track — the +100% cap | 10,230 ☘️ total, deliberately the last thing a clover-rich player finishes | Phase 3/6 |
| 13 | The difficulty ladder is monotonic **in play** | hp per dollar of income must be **ordered** and rising with the difficulty - it measures how much hp the player must chew per dollar earned, so the top difficulty must show the most. It was 1.00 / 1.17 / 1.01 (**worst on Hard**, LL-042); since the carry it is 0.0063 / 0.0076 / 0.0095 | `gm balance sim`, every rebalance |
| 15 | The wave curve matches the ladder it is fitted to | All six current Normal endpoints fit the ten stage rows per region; three replay-eligible builds cleared every row in 180 deterministic runs, and one seed-legal Normal path cleared all 60 rows. A mixed Normal R1 / Brutal R2–R6 path also clears all 60 in the simulator with regional mastery and gated unlocks. Endpoint fit and live play remain unverified at Hard/Brutal | `gm balance fit --sim`, `gm balance sim`, `loadout-stage-coverage`, `normal-first-clear-path`, `difficulty-first-clear` |
| 14 | A `targets` cap is reachable | `gm balance sim` reports the widest target list any tower held; 1-1 peaks at **7**, so a cap of 10 is coverage-limited, not target-limited | `gm balance sim` |

**Instrumentation this requires (Phase 0):** every currency event logs through `print()` under `global.devMode`, with the `META`, `SEED`, `CLOVER`, `SHARD` and `CANDY` prefixes, per the log-prefix convention in `AGENTS.md` §4. Without that log, Phase 6 tuning is guesswork.

---

## 10. Tuning ledger — what will move, and in what order

Adjust **one** of these at a time, log first, and only after the previous one has been played:

1. **Blood pity window** (8,000 / 20,000) — the most sensitive number in the game
2. **Candy duration base** (30 s / 60 s) and the duration track's **base cost** — these two decide whether candy feels usable at all. **The doubling on that track is structural: do not tune it.**
3. **Candy level costs** — if the first two levels are not cheap enough to feel immediate, the entire track stops registering
4. **Region base seeds** — if unlocks come too fast or too slow
5. **Clover costs** — the trees (473 per branch), the master nodes (3,280 to cap 10) and the duration track (10,230 to +100%)
6. **Upgrade prices** (in-run money) — if the run economy feels tight or trivial
7. **Tower stats**, then placement prices — Phase 2 tuning, not before
8. **Candy magnitudes** — if losing the stacking spike (from +190% down to +19%) leaves candy feeling weak, raise the level-10 numbers, never the rule
9. **Box weights** — if Endless income dwarfs the campaign
10. **Difficulty multipliers** — *last*, because they touch every other number on this page

---

## 11. Open questions (decide in Phase 1–2, not now)

| Question | Recommendation |
| --- | --- |
| Does Endless pay seeds/clovers outside boxes? | Resolved 2026-10-30: yes; see §7.6 for the 2%-per-10-cleared-waves rule |
| Is Crimson Garden a new mode or a region-6 modifier? | A modifier — it reuses the wave-modifier system and costs no new screens |
| Does `par_spend` scale with difficulty? | No. Par is par, and Brutal making *Frugal* harder is a feature, not a bug |
| Do cadies apply to the whole loadout or one tower? | The whole loadout — it is a run-wide power fantasy, not a focus-fire tool |

---
