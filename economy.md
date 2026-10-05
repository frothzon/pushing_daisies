# Garden Defense TD+ — Numerical Economy (numbers of record)

*Companion to [`goal.md`](./goal.md): that document says what the game is, this one says **what the numbers are**. Where they disagree, `goal.md` wins on intent and this file wins on values.*

Status: **v1 draft, approved for Phase 0/1 implementation.** Every value here is a starting point to be tuned in Phase 6 from play logs, not a law.

| Field | Value |
| --- | --- |
| Last updated | 2026-10-04 |
| Engine | GameMaker Studio 2 (converted from GameMaker 8) |
| Companions | `goal.md` §1–§28, `roadmap.md`, `AGENTS.md`, `lessons_learned.md` |

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

`seeds = region_base × difficulty_multiplier × repeat_multiplier`

| Region | Base (Normal) | Hard ×2 | Brutal ×5 |
| --- | --- | --- | --- |
| 1 Grass | 3 | 6 | 15 |
| 2 Swamp | 5 | 10 | 25 |
| 3 Desert | 8 | 16 | 40 |
| 4 Jungle | 11 | 22 | 55 |
| 5 Graveyard | 15 | 30 | 75 |
| 6 Blood Fields | 20 | 40 | 100 |

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
| First unlock (25 🌱) | ~9 Normal stages, or **2 Brutal stages** |
| Half the roster (4 of 8) | end of Region 3 on a Normal/Hard mix |
| Whole roster | Regions 5–6, mixing Hard and Brutal |
| First tower to L6 | after Garden Mastery I, ~stage 12–14 |

*A Normal-only player finishes with ~620 + 155 (repeats) ≈ 775 🌱 — five unlocks, deliberately not eight.*

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
| ⚔️ **Offense** | +2% tower damage per rank (to +10%) | +1% fire rate per rank, +1% crit chance, +5% crit damage, +2% more damage, +3% more damage |
| 🌱 **Growth** | −5% upgrade cost per rank (to −25%) | +15% in-run money from kills, a third spec tier at L4, −10% master node cost, −20% master node cost, +2 starting money |
| 💰 **Harvest** | +1% zombie money per rank | +starting money, +boss reward %, +5% seeds, +10% seeds, +15% seeds |

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
| Zombie kill payout | 1–3 | unchanged (`scr_makeMonster` values) |
| Boss payout | `wave + 1` | unchanged |
| Economy tower (Money Marigold) | +1–3 money per wave it survives, scaling with level | new |
| Harvest nodes | +1% per rank | see §3.2 |

### 4.2 Placement prices (unchanged from today)

| Tower | Price | Range | Damage | Fire rate | Targets |
| --- | --- | --- | --- | --- | --- |
| Daisy Pusher | 5 | 100 | 4 | 3 | 1 |
| Burning Ivy | 15 | 80 | 40 | 2 | 1 |
| Slender Mandrake | 45 | 125 | 125 | 1 | 3 |
| Pina Collider | 100 | 75 | 200 | 1 | 10 |
| Chillip | 30 | 90 | 8 | 2 | 3 |
| Bindweed | 40 | 70 | 5 | 1 | 2 |
| Thornamental | 60 | 110 | 90 | 2 | 1 |
| Belladonna Blitz | 55 | 85 | 12 | 4 | 2 |
| Cannon Tulip | 120 | 220 | 150 | 0.5 | 1 |
| Kaboom Kalanchoe | 150 | 80 | 120 | 1 | 6 |
| Money Marigold | 35 | — | 0 | — | — |
| Meat Bulb | 200 | 140 | 400 | 1 | 1 |

*These are first approximations that keep today's five `d/$` ratios roughly intact while making the new roles affordable. They will move in Phase 2 tuning; the **curve** matters more than the numbers.*

### 4.3 Upgrade prices (in-run money) and refunds

| Level | Cost | Cumulative |
| --- | --- | --- |
| L2 | 0.50 × base price | 0.50 |
| L3 | 0.75 × base price | 1.25 |
| L4 | 1.00 × base price | 2.25 |
| L5 | 1.50 × base price | 3.75 |

**Sell refunds 60% of everything invested** (placement + upgrades). Today's code refunds 25–50% of *current* price, which punishes the experimentation a loadout game depends on.

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

**The coupling that must never be forgotten:** today's L5 is ×16 damage and `scr_level_difficulty` (`life *= power(2, wave/5−2) + 0.2*(wave−1)`) is written for that. Ship §4.4 without rewriting that scaling and the game becomes unplayable. They are one change.

**Which rows money actually buys.** A tower *arrives* at the garden's floor (`goal.md` §4; `start = cap − 4`) and the four rows above that floor are the ones bought in-run. So at mastery V, money buys L7→L10 (×1.59 → ×2.00) — still about +8% per rung, because the rungs are defined against the base rather than compounding. **The relative value of money never changes, at any point in the campaign**; that is the entire reason the floor and the cap move together.

**Visuals are normalised by a fixed 10**, not by the current cap — the existing `lerp(0.25, 0.70, level / tower_max_level)` in `_levelControl/Step_0.gml:117` must become `level / 10` with adjusted endpoints, or a tower placed at floor 6 would be indistinguishable from one placed at floor 3.

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

---

## 6. Candy 🍬

### 6.1 Recipes, levels, and stock — three different things

| Thing | What it is | Cost / source |
| --- | --- | --- |
| 🍬 **Recipe** | permanent unlock of one candy type | 3 / 8 / 20 shards for tiers 1 / 2 / 3 |
| 🍬 **Level** | permanent power of that candy, 1 → 10 | shards, escalating (§6.4) |
| 🍬 **Stock** | the units actually spent in a run | Endless boxes, and a shard shop at 1 shard = 5 candies |

**Recipes and levels are permanent; stock is consumed.** A player's shard income therefore always has three jobs to choose between: *open a new candy*, *sharpen one they have*, or *buy a burst of stock for tonight's run*. That is the whole design of the blood economy after the blood tree is finished, and it is why shards never stop mattering.

### 6.2 The candies, and what a level does to them

Each level adds one unit of **that candy's own** stat, so the growth is always legible in the UI as `+10% → +19%` rather than as an abstract "level".

| Candy | Tier | Effect at **L1** | Per level | At **L10** | Duration |
| --- | --- | --- | --- | --- | --- |
| 🍬 **Red Licorice** | 1 | +10% damage | +1% | **+19%** | 30 s |
| 🍬 **Jawbreaker** | 1 | +10% range | +1% | +19% | 30 s |
| 🍬 **Gummy Worm** | 1 | +15% slow effectiveness | +1.5% | +28% | 30 s |
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

**95 shards per candy. 760 for all eight.**

Sanity-checked against shard supply:

| Source | Shards |
| --- | --- |
| One full campaign sweep (~12,000–15,000 kills) from the pity curve | ~1.5 |
| Plus the 6 region bosses (guaranteed) | 6 |
| **Per sweep** | **~7.5** |
| A good Endless run (boxes 1–8) | 3–8 |
| Blood tree, complete (one-off) | 46 |

So **the first two levels cost 5 shards** — about two thirds of one campaign sweep — which is why early investment is felt immediately. One candy to L10 is roughly **a dozen sweeps**; all eight is the lifetime project. That curve is the whole point: it is the only shard sink that never ends (`goal.md` §16).

**A level never touches the duration.** Levels buy magnitude, clovers buy time (§3.5): a level-10 candy is still exactly 30 seconds — 60 with the clover track maxed — it just does more per second.

### 6.5 Special candies — rare, meta, and deliberately single

Two candies act on the **economies** rather than on combat — and because nothing stacks any more (§6.3), they need no special rule to stay bounded.

| Candy | Tier | Effect at **L1** | Per level | At **L10** | Duration |
| --- | --- | --- | --- | --- | --- |
| 🍊 **Blood Orange** | 4 (rare) | kills count **1.10×** toward the next blood shard | +0.10× | **2.00×** | 30 s |
| 🍯 **Money Honey** | 4 (rare) | **+15%** money from every kill | +1.5% | **+29%** | 30 s |

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

## 8. Badges 🏅 (medals only in v1)

One medal per badge per stage, stored in the save. **No art in v1** — the record is the reward.

| Badge | Condition | Notes |
| --- | --- | --- |
| 🏅 **Untouched** | finish with 20/20 lives | the clean clear |
| 🏅 **Frugal** | total spend ≤ the stage's `par_spend` | `par_spend` is authored per stage in `stage_data` and shown in the Deploy briefing, so it is a target the player can *see* rather than a secret |
| 🏅 **Botanist** | place all 4 loadout tower types | interacts with `goal.md` §3.1 |
| 🏅 **Purist** | place exactly 1 tower type | **first clear only**, so it cannot be farmed with a degenerate loadout |
| 🏅 **Exterminator** | no zombie reaches the despawn point | |
| 🏅 **Speed Grower** | finish under the stage's `par_time` | authored per stage |
| 🏅 **Brutalist** | complete the stage on Brutal | the difficulty badge |

**Total available:** 7 × 60 stages = **420 medals**, plus 6 region-completion medals (one per boss) = **426**.

*`par_spend` and `par_time` are the only two numbers a designer must author per stage. Everything else derives from the region table, which is what keeps 60 stages cheap.*

---

## 9. Validation checkpoints — the only numbers that decide if this is right

| # | Checkpoint | Target | Verified in |
| --- | --- | --- | --- |
| 1 | First tower unlock | inside the first ~3 stages of meaningful play | Phase 1 playtest |
| 2 | Early Brutal beats a Normal grind | a Brutal clear ≥ 3× a Normal clear (5× by construction) | Phase 1 by arithmetic |
| 3 | Normal-only cannot buy the roster | 775 🌱 earned < 2,015 🌱 needed | arithmetic |
| 4 | Garden Mastery I — cap 6, towers arrive at **2** | ~stage 10–12 | Phase 3 |
| 5 | First blood shard | region 3–4 | Phase 4, from the kill counter |
| 6 | Every stage clearable by ≥ 3 loadouts | no stage has a single correct answer | Phase 2 |
| 7 | Nothing is inert | every currency earnable *and* spendable at every point in the campaign | Phase 3 gate |
| 8 | First candy levels (L2–L3, 5 shards) | inside the first campaign after the first shard | Phase 4 |
| 9 | First candy to L10 (95 shards) | ~a dozen campaign sweeps — long, but visibly progressing | Phase 4 |
| 10 | A maxed Blood Orange + blood tree tier 2 | pity fills ~2× for 30 s at a time, never stacked — a *window*, not a farming engine | Phase 4 |
| 11 | Candy duration track — first purchase | 10 ☘️ for +10%, buyable inside region 1, so every player feels it | Phase 3 |
| 12 | Candy duration track — the +100% cap | 10,230 ☘️ total, deliberately the last thing a clover-rich player finishes | Phase 3/6 |

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
| Does Endless pay seeds/clovers outside boxes? | Yes, a small trickle (~2% of a stage per 10 waves) so a long run is not purely a candy farm |
| Is Crimson Garden a new mode or a region-6 modifier? | A modifier — it reuses the wave-modifier system and costs no new screens |
| Does `par_spend` scale with difficulty? | No. Par is par, and Brutal making *Frugal* harder is a feature, not a bug |
| Do cadies apply to the whole loadout or one tower? | The whole loadout — it is a run-wide power fantasy, not a focus-fire tool |

---

## 12. Change log

| Date | Change |
| --- | --- |
| 2026-10-04 | v1 created out of the `goal.md` design review. All values first-pass; every one is expected to move in Phase 6. |
| 2026-10-04 | Mastery redesigned on the user's call: clovers now raise the tower **floor and cap together** (`start = cap − 4`), so the money climb stays four rungs at every mastery. Seeds consequently buy **content only** (§2.3), and candy gained **levels 1–10** bought with shards (§6.4) as the game's unbounded shard sink. |
| 2026-10-04 | Added the **special (rare) candies** (§6.5): 🍊 Blood Orange (pity fill ×1.10 → ×2.00) and 🍯 Money Honey (+15% → +29% kill money). Tier 4, 35 shards, gated, and the only candies that never stack. The shard one was reframed from "+10% drop rate" to pity fill because a +10% on 0.01% is imperceptible (§5.2's own rule), and it now also exposes the pity counter. Fixed the Growth tree's in-run money node from +75% to **+15%**, which contradicted the whole Harvest branch (+5%). |
| 2026-10-04 | Candy redesigned from **stacking** to **duration** on the user's call: magnitude never stacks, each candy is 30 s, consuming more of a type *adds* time, and a clover track (§3.5) buys up to **+100%** duration. The +2% step became **+10%** (ten purchases, not fifty) so the +100% cap is honest rather than 2^49 clovers away; total 10,230 ☘️, making it the game's longest single clover sink. The timer counts **game frames** and ticks **only while a wave is live**. This is also the rule that a doubling ladder may only ever be attached to a knob that cannot break the power curve. |

