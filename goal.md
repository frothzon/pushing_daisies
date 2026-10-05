Yes. I think this becomes much stronger if we make **Seeds = content**, **Four-Leaf Clovers = permanent power**, **Blood Shards = long-term prestige/economy**, and **Candy = temporary run power**. That gives every reward a distinct purpose and prevents one currency from doing everything.

I'd structure the entire meta-game around four layers:

# Garden Defense TD+ — Core Progression

## 1. The Four Reward Currencies

| Currency | Primary Purpose | Earned From | Power Type |
| --- | --- | --- | --- |
| 🌱 **Seeds** | Unlock towers | Clearing a stage (full on first clear, 25% on repeats) | Permanent content |
| ☘️ **Four-Leaf Clovers** | Permanent upgrades | Remaining lives | Permanent power |
| 🩸 **Blood Shards** | Meta-tech tree | Extremely rare zombie drops | Long-term progression |
| 🍬 **Candy** | Temporary buffs | Endless + loot boxes | Run-specific power |

The important distinction:

**Seeds unlock what you can play.**\
**Clovers make your garden stronger.**\
**Blood Shards improve your account over time.**\
**Candy lets you break the rules temporarily.**

---

One more economy sits *underneath* those four, and it is deliberately not a meta currency:

**Money is the in-run economy.** It starts at 25, zombies pay 1–3, bosses pay `wave + 1`, and it buys placement, upgrades and refinement **inside the stage only**. It is left behind when the stage ends. Everything else in this document is *between-run*.

That split is the spine of the whole design:

> **Money is the moment. Seeds are the campaign. Clovers are the garden. Shards are the account. Candy is the run.**

---

# 2. Campaign Structure

## Six Regions

Each region contains:

- 10 stages.
- **1 new zombie type**, plus stat and behaviour variants built from the existing three rigs (see §28 on scope).
- 1 new gameplay mechanic, always reusing a system that already exists (§27.4).
- **1–2 unlockable towers** gated behind that region (§10).
- Stage 10 = Boss.

That gives us:

**60 campaign stages + 6 bosses.**

Each stage has three difficulties:

| Difficulty | Seed Reward | Zombie HP | Zombie speed | Zombies per wave | In-run money |
| --- | --- | --- | --- | --- | --- |
| Normal | 1× | 1× | 1× | +0 | 1× |
| Hard | 2× | 1.5× | 1.05× | +0 | 1× |
| Brutal | 5× | 2.5× | 1.15× | +1 | 1.5× |

Difficulty applies the **same** multipliers to every stage in the game; per-stage scaling is separate and lives in `scr_level_difficulty` (§28.3). Keeping the two apart is what lets one difficulty table work for 60 stages.

**First clear pays full seeds. Repeats pay 25%** (minimum 1). That single rule is what makes farming impossible while still letting a player go back for a badge or a better clover haul — and it means §11's "remaining lives" reward never needs a second anti-farm mechanism.

I'd actually make the **5× Brutal reward intentional**: Brutal shouldn't merely be "Hard but harder." It should be the primary way skilled players accelerate tower collection.

### Example

Stage 17:

- Normal → 5 Seeds
- Hard → 10 Seeds
- Brutal → 25 Seeds

The player can therefore choose:

> "Do I slowly clear the campaign, or do I master difficult stages to unlock the garden faster?"

---

# 3. Four-Tower Loadout

Before entering a stage:

**Choose exactly 4 towers. Only those 4 can be placed in that stage.**

That's important.

It means having 20 towers doesn't mean every stage becomes overwhelming.

The player has to answer:

> "What four plants are best for this problem?"

This creates a natural counter-system.

For example:

**Swamp Stage**

- Fast zombies
- Armored zombies
- Regenerating zombies

The player might bring:

- Daisy Pusher — cheap DPS
- Burning Ivy — regeneration counter
- Slender Mandrake — multi-target
- New slow/control tower

The fifth tower they own doesn't matter because it wasn't selected.

This also makes unlocking towers exciting without making the actual battlefield cluttered.

## 3.1 The Loadout Rule (locked)

| Question | Rule |
| --- | --- |
| Slots | **4, hard.** Never fewer — guaranteed because 4 towers are free starters (§10.1) |
| Presented | A **Deploy screen** before every stage: region/stage header, difficulty picker, the 4 loadout slots, `Deploy` |
| Locked towers | **Always listed and greyed out**, with the unlock requirement on them (`Clear Region 2`, `280 🌱`). The fleet is never hidden |
| Default | Pre-filled with the loadout used last time, so deploying is one click |
| Mid-run changes | **Not allowed.** The in-run shop shows exactly the 4 chosen |
| Saved | The "last used" loadout persists; the per-stage choice does not |
| After a loss | Same loadout pre-filled, and changing it is free |
| Endless | Same rule, chosen once when the run starts (§19) |
| Badges | *Botanist* needs all 4 types placed; *Purist* needs exactly 1 of the 4 placed (§25) |

**The first game.** Exactly four towers are unlocked from the start, so on the first run all four slots auto-fill, the screen still appears, and the other eight sit there greyed out. No real choice — but the rule is taught, and the player sees the wall they are going to climb.

**Two balance obligations this creates:**

1. Every stage must be clearable by **at least three distinct 4-tower loadouts**. Otherwise the choice is fake and there is one correct answer.
2. Unlock pacing becomes the campaign's primary reward — which is exactly what §1 and §24 already claim.

**Two good news items for the build:**

* The in-run shop is **already a 4-wide grid** (`create_display_grid(_x,_y,64,64,4,1)` in `_levelControl/Create_0.gml`), so "only 4" needs **no shop layout change** — it draws the selected four instead of all four.
* The greyed-out treatment reuses the project's existing `scr_button_greyout` convention rather than inventing a new one.

---

# 4. Tower Progression

**Levels are bought in-run, with in-run money. What clovers buy is the *range* of levels a tower can occupy.** That split is deliberate:

* **💵 money** buys the four rungs between where a tower arrives and where it can go — this stage, gone next stage.
* **☘️ clovers** raise the **floor** (the level a tower *arrives* at, free) and the **ceiling** (the highest rung it can be taken to) — permanently, for the whole garden.

So a tower has no persistent level of its own. It has a **floor and a ceiling granted by the garden**, and everything between them is earned inside the stage. Money therefore stays meaningful forever, and a clover purchase is visible the moment a tower is placed.

**Start = cap − 4.** Both numbers move together, one level per master node, so the money climb is **always four rungs deep** at every point in the game:

| Garden mastery | Tower cap | Towers arrive at | Rungs bought with money | Base power on placement |
| --- | --- | --- | --- | --- |
| none | **5** | 1 | 4 — L2…L5 | ×1.00 |
| ☘️ Mastery I | **6** | 2 | 4 — L3…L6 | ×1.08 |
| ☘️ Mastery II | **7** | 3 | 4 — L4…L7 | ×1.17 |
| ☘️ Mastery III | **8** | 4 | 4 — L5…L8 | ×1.26 |
| ☘️ Mastery IV | **9** | 5 | 4 — L6…L9 | ×1.36 |
| ☘️ Mastery V | **10** | 6 | 4 — L7…L10 | ×1.47 |

**Four rules that keep that honest:**

1. **The gap never widens.** If clovers raised only the ceiling, the last rungs would be unreachable inside one stage and mastery would feel like an IOU. If they raised only the floor, money would become irrelevant. One node raises both, so the climb is exactly as meaningful at the end of the campaign as at the start.
2. **A placed tower arrives at its floor, free.** The four rungs above it are bought with money at the prices in `economy.md` §4.3 — unchanged, because it is the same currency those rungs have always taken.
3. **Visual scaling is normalised by a fixed 10, never by the current cap** — otherwise a tower placed at floor 6 would look identical to one placed at floor 3, and the player would lose the one cue that says "the garden grew".
4. **Mastery is gated by region clears** (`economy.md` §3.3), so region N's enemy scaling assumes the mastery a player can plausibly hold by region N. Without that pairing, mastery would trivialise old content.

**What a level gives you — this replaces today's doubling.** Right now an L5 tower does 16× an L1's damage, and `scr_level_difficulty` is tuned around that, so these two changes must land together or the game becomes unplayable:

| Level | Damage | Fire rate | Range |
| --- | --- | --- | --- |
| L1 | ×1.00 | ×1.00 | ×1.00 |
| L2 | ×1.08 | ×1.04 | ×1.03 |
| L3 | ×1.17 | ×1.08 | ×1.06 |
| L4 | ×1.26 | ×1.12 | ×1.09 |
| L5 | ×1.36 | ×1.17 | ×1.12 |
| L6–L10 | +8% damage, +4% fire rate, +3% range per level | | |

Upgrade prices, so a level is a decision rather than a formality: L2 = 0.5× base price, L3 = 0.75×, L4 = 1.0×, L5 = 1.5×. Selling refunds **60% of everything invested** — today's 25–50% of *current* price punishes exactly the experimentation a loadout game needs.

For example:

| Tower Level | Function |
| --- | --- |
| L1 | Base tower |
| L2 | Stat increase |
| L3 | Specialization choice |
| L4 | Stronger specialization |
| L5 | Signature ability |
| L6+ | Advanced mastery |

This means **L5 isn't just another numerical upgrade**.

It's the point where the tower becomes mechanically unique.

---

# 5. Tower Specializations

Every tower gets two paths.

For example:

## Daisy Pusher

### 🌼 Bulldozer

Focuses on control.

- Increased knockback.
- Stun chance.
- Larger impact.
- Eventually knocks back bosses slightly.

### 🌼 Rapid Bloom

Focuses on DPS.

- Increased attack speed.
- Crit chance.
- Crit damage.
- Multi-shot at high levels.

The important thing is that **specializations shouldn't simply be "more damage vs more range."**

They should change how the tower behaves.

---

# 6. The Status Effect System

I'd establish a universal combat-stat vocabulary now so every future tower can use it.

## Offensive Stats

Every attack can potentially have:

- Damage
- Crit Chance
- Crit Damage
- Attack Speed (`fire_rate` in code — shots per second; keep the code name, relabel it in the UI)
- Range
- Projectile Count
- Target Count

**No armor.** Monsters in this project have no armor stat, and adding one would double the balance matrix for no design gain, so armor and armor penetration are cut for v1. Zombie toughness is expressed as HP, speed and elite tier instead.

### Crit

I'd use:

**Crit Chance:** 0–100%

**Crit Damage:** multiplier

Baseline:

> 5% crit chance\
> 150% crit damage

A critical hit deals:

**Damage × Crit Multiplier**

So:

100 damage × 1.5 = **150 damage**

Crit chance is **additive** (5% base + tower + specialization + clovers + candy, capped at 100%); crit damage is a **multiplier** (×1.5 base, additive bonuses on top). **Crit applies to direct hits only — damage over time never crits.** That one rule is what stops DoT builds from becoming the only correct answer.

---

# 7. Status Effects

I'd keep the core list relatively small.

### 🔥 Burn

Deals damage over time.

Example:

> 20% chance to Burn\
> 10 damage/sec\
> 3 seconds

Burn can stack duration but not damage.

This prevents absurd exponential scaling.

**One instance of each status per zombie.** A second tower's burn refreshes the duration and keeps the stronger damage rate; it never adds a second burn. Burn and poison from *different* towers do stack, which is what makes a multi-tower DoT loadout worth building.

---

### ❄️ Slow

Reduces movement speed.

Example:

> 25% Slow\
> 4 seconds

Slow should have diminishing effectiveness at high values.

I'd cap ordinary slow around **75%**.

Slow never stacks either: the strongest magnitude wins and the duration refreshes.

---

### ⚡ Stun

Stops a zombie completely.

Example:

> 5% Stun Chance\
> 1 second

Bosses receive reduced stun duration.

For example:

**Normal zombie:** 1.0 sec\
**Elite:** 0.5 sec\
**Boss:** 0.25 sec

This prevents stun-locking.

**Every crowd-control effect needs that same treatment, not just stun** — otherwise whichever debuff lands first becomes the entire strategy:

| Debuff | Zombie | Elite | Boss |
| --- | --- | --- | --- |
| Slow | 100% | 60% | 40% |
| Stun | 1.0 s | 0.5 s | 0.25 s |
| Root | 1.0 s | 0.6 s | 0.3 s |
| Knockback | 100% | 50% | 15% |

---

### ☠️ Poison

Different from Burn.

**Burn**

- Burst-oriented.
- Short duration.
- Fire-themed.

**Poison**

- Longer duration.
- Stack-oriented.
- Nature/chemical themed.

---

### 🩸 Bleed

Damage triggered by movement.

That gives us an interesting interaction:

> Fast zombies take more Bleed damage because they move more.

---

### 💫 Vulnerable

Increases damage received.

Example:

> Vulnerable +15% damage taken for 3 sec.

This creates support towers.

---

### 🌱 Root

Stops movement without interrupting attacks.

This is different from Stun.

**Stun:** can't move or attack.\
**Root:** can't move, but can attack.

That distinction gives us considerably more design space.

---

# 8. Status Effect Rules

To keep the game understandable:

### Crowd Control

- Slow
- Stun
- Root

### Damage Over Time

- Burn
- Poison
- Bleed

### Damage Amplification

- Vulnerable

### Special

- Knockback

(Armor Break is cut along with armor, see §6. Vulnerable — the damage-amplification debuff — is the one that survives as a support-tower hook.)

I'd avoid introducing 15 different effects.

**Around 8–10 total status mechanics is plenty.**

---

# 9. The Tower Stat Framework

Every tower can now be constructed from the same basic vocabulary:

```
Damage
Attack Speed
Range
Targets
Crit Chance
Crit Damage

Burn Chance
Burn Damage
Burn Duration

Poison Chance
Poison Damage
Poison Duration

Slow Chance
Slow Amount
Slow Duration

Stun Chance
Stun Duration

Bleed Chance
Bleed Damage
Bleed Duration

Root Chance
Root Duration

Vulnerability
Knockback
```

Not every tower needs all of them.

That's the point.

One tower might be:

> 500 damage\
> 5% crit\
> 100 range

while another might be:

> 80 damage\
> 40% burn chance\
> 25% slow\
> 3 targets

---

# 10. Witty Plant Tower Naming

I would make the names a major part of the game's identity.

Your existing:

**Slender Mandrake**

is exactly the right direction.

I'd use names like:

## 10.1 The roster is 12, not 20

**The 4 starters — free, already built, zero new art. These are also the towers of the first ever loadout:**

| Slot | Tower | Role | Today's data (range / damage / fire-rate / targets) |
| --- | --- | --- | --- |
| 1 | 🌼 **Daisy Pusher** | cheap single-target DPS | 100 / 4 / 3 / 1 |
| 2 | 🔥 **Burning Ivy** | damage over time | 80 / 40 / 2 / 1 |
| 3 | 🌿 **Slender Mandrake** | multi-target | 125 / 125 / 1 / 3 |
| 4 | 💥 **Pina Collider** | AoE burst | 75 / 200 / 1 / 10 |

**The 8 unlockables — one per gap in the current kit, priced 25 → 650 seeds (§28.2):**

| # | Name | Role | The gap it fills |
| --- | --- | --- | --- |
| 5 | 🌶️ **Chillip** | slow / freeze | nothing slows anything today |
| 6 | 🌱 **Bindweed** | root | no root exists |
| 7 | 🥀 **Thornamental** | burst + crit | crit has no home |
| 8 | ☠️ **Belladonna Blitz** | poison, fast cadence | poison has no home |
| 9 | 🎆 **Cannon Tulip** | long-range artillery | nothing reaches across the map |
| 10 | 🍄 **Kaboom Kalanchoe** | AoE + burn | burn has no home |
| 11 | 🏵️ **Money Marigold** | in-run economy | economy play has no tower |
| 12 | 🎺 **Meat Bulb** | capstone single-target | the reward for regions 5–6 |

**Renamed from the original list, to stay off other people's IP:** *Snapdragon* → **Meat Bulb**; *Peashooter Prime* → **Cannon Tulip**; *Doomshroom* → **Kaboom Kalanchoe**; *Rosemary's Baby* → **Thornamental**. The four originals keep their names untouched, because they are the player's first four friends.

**Held in reserve** — designed, not built in v1, and the first names to promote if the roster ever grows past 12 (see `roadmap.md`): **Knockout Nasturtium**, **Snarewort**, **Bomb Begonia**, **Mortar Marigold**, **Mint Condition**, **Profitera**, **Heal-a-Peno**, **Buffalo Bean**.

I'd deliberately mix **real botanical references + terrible puns + slightly absurd names** — and every one of the 12 must be describable in one line, which is the test the reserve list mostly fails.

---

# 11. Four-Leaf Clover System

This becomes the player's **permanent garden technology**.

At the end of every stage:

> Remaining lives → Four-Leaf Clovers

Example:

Player finishes with:

**17 / 20 lives**

They receive:

**17 Four-Leaf Clovers**

This makes every life meaningful.

But there's an important balancing question:

### Don't make clovers completely proportional to lives forever.

Otherwise players can farm easy stages.

Instead:

**Clover reward = remaining lives × (1 + 0.25 × (difficulty − 1))**

then diminishing returns on repeats: first clear ×1, second ×0.5, third and later ×0.25 (floor).

**Life is a per-stage budget, not a campaign pool.** Every stage starts with 20 lives (§12 *Vitality* can raise the cap). That is the only way "remaining lives" stays a meaningful, repeatable reward across 60 stages — a campaign-wide pool would either be gone by region 2 or so large that clovers stopped tracking skill. Failing a stage keeps everything already banked; it simply pays no stage reward, and *Untouched* (§25) waits for the next attempt.

---

# 12. Clover Tech Tree

I'd divide Clovers into four branches — **10 nodes each, up to 5 ranks per node**.

Node costs per rank: **5, 8, 12, 18, 25, 35, 50, 70, 100, 150** clovers. The level-cap master nodes (§13) are priced separately, and they are the expensive part.

A stage pays roughly 20–28 clovers (20 lives, scaled by difficulty), so one branch takes about 8–10 stages to fill and all four branches together are a genuine long-term project rather than a checklist.

## 🌿 Vitality

Improves the garden's durability.

- +1 maximum life
- Reduced life-loss penalties
- Starting regeneration
- Improved boss survival

## ⚔️ Offense

Improves towers.

- +2% tower damage
- +1% attack speed
- +1% crit chance
- +5% crit damage

## 🌱 Growth

Improves progression.

- The five master nodes — floor **and** cap (§13)
- Reduced upgrade cost (in-run: L2–L5 prices drop by up to 25%)
- Cheaper clover master nodes (−10% then −20% off their cost)
- A third specialization tier at L4 (§5)

## 💰 Harvest

Improves economy.

- Increased zombie money
- Increased starting money
- Better boss rewards
- Increased Seed rewards

---

# 13. Level-Cap Progression

This is one of the strongest uses for Clovers.

Start:

**Maximum tower level = 5**

Eventually:

**6 → 7 → 8 → 9 → 10**

But don't let every tower automatically become Level 10.

Instead, the tech tree unlocks:

> **Garden Mastery I — Tower Cap 6**

Then:

> **Garden Mastery II — Tower Cap 7**

etc.

This creates a meaningful long-term objective.

**The five master nodes:**

| Node | Effect | Cost |
| --- | --- | --- |
| Garden Mastery I | tower cap **6**, towers arrive at **2** | 120 ☘️ |
| Garden Mastery II | tower cap **7**, arrive at **3** | 260 ☘️ |
| Garden Mastery III | tower cap **8**, arrive at **4** | 500 ☘️ |
| Garden Mastery IV | tower cap **9**, arrive at **5** | 900 ☘️ |
| Garden Mastery V | tower cap **10**, arrive at **6** | 1500 ☘️ |

Cap 6 lands around stage 10–12 on a Normal run; cap 10 is the endgame chase.

**Mastery is account-wide.** One garden, one floor, one ceiling — which is what "clover" means as a currency, and it keeps the Garden Book small enough to read at a glance. The cost of that simplicity is that each node is a milestone rather than a per-tower project: the *arrival* level rises with the campaign, so by region 4 a freshly placed tower already fights like an old L4 one, and the four rungs above it are what money is for.

*(If per-tower floors are ever wanted, it is a data change on the same resolver — a master node would name a tower instead of the garden — not a rewrite. Build the account-wide version first.)*

**Specializations are never bought.** They arrive automatically at L3 (§5, §27.5) — the choice *is* the reward — so the Seed Tree does not gate them (§24).

---

# 14. Blood Shards

I like this idea, but the **0.01% drop rate needs to be handled carefully**.

At 0.01%:

**1 in 10,000 zombies**

That makes Blood Shards feel genuinely mysterious.

But we should add a **pity mechanism**.

Otherwise a player could theoretically kill 100,000 zombies and receive nothing.

I'd use:

> Base Blood Shard chance: **0.01%** — 1 in 10,000

plus a real pity mechanism, because "increases slightly" is not implementable:

```
p = kills since the last shard
c = 0.0001                                          # base
if p >= 8000: c = 0.0001 + 0.00003 * ((p-8000)/1000)  # soft pity
if p >= 20000: c = 1.0                                # hard pity: guaranteed
```

Then receiving a shard resets the counter (`p = 0`).

A stage is roughly 100–400 kills, so **the first shard lands around region 3–4** — genuinely a "holy crap" moment, but reachable inside a single campaign rather than a statistical rumour. **Bosses always drop one shard**, which decouples the chase from a single dice roll.

This maintains the "holy crap!" feeling without making the system frustrating. (The original paste spliced the closing paragraph of §26 into this sentence; it now ends where it should.)

---

# 15. Blood Shard Tech Tree

Blood Shards should **not** directly make towers massively stronger.

They're too rare.

Instead, they unlock **account-wide systems**.

## 🩸 Blood Alchemy

### Tier 1

**Blood Magnet**

**−10% kills required** for the next shard (the pity counter fills 10% faster).

### Tier 2

**Hemorrhagic Harvest**

**−25% kills required** for the next shard.

*(Written as "−kills required", never as "+drop rate". A +10% bonus on a 0.01% chance is 0.011% — invisible to a player and worthless as a reward. Every node in this tree must be perceptible, which is the rule this whole branch is built on.)*

### Tier 3

**Crimson Appetite**

Chance for elite zombies to drop additional shards.

### Tier 4

**Blood Moon**

Small chance for an entire wave to receive increased shard drop rates.

### Tier 5

**Crimson Garden**

Unlocks special Blood Shard content.

---

# 16. Second Blood Shard Economy: Candy

This is where I think your idea gets particularly good.

**Shards do three different things to candy, and the third one is what keeps shards relevant forever.** They are deliberately separate:

| Thing | What it is | Where it comes from |
| --- | --- | --- |
| 🍬 **Candy recipe** | permanent unlock of one candy type | 🩸 Blood Shards — 3 / 8 / 20 for tiers 1 / 2 / 3 |
| 🍬 **Candy level** | permanent power of that candy, **1 → 10** | 🩸 Blood Shards, on an escalating cost curve |
| 🍬 **Candy stock** | the units you actually spend in a run | 🩸 Endless loot boxes, plus a shard shop at 1 shard = 5 candies |

That resolves the three-sources problem in §1/§16/§20 without removing any of them, and it gives blood shards a *reliable*, never-finished sink.

**Why candy has levels.** The blood tree is finite — five tiers and it is done. Candy recipes are finite — eight of them. Candy *levels* are not: eight candies × nine paid levels is a refinement track that can never be exhausted. It turns every shard into something a player still wants, which is exactly what a rare drop needs in order to stay interesting a hundred hours in. **Candy levels are the game's only unbounded shard sink, on purpose.**

Candy becomes the game's temporary power system.

For example:

### 🍬 Red Licorice

+10% damage for 5 waves.

### 🍬 Jawbreaker

+10% range for 5 waves.

### 🍬 Gummy Worm

+15% slow effectiveness for 5 waves.

### 🍬 Sour Drop

+10% crit chance for 5 waves.

### 🍬 Fireball Candy

+20% burn damage for 5 waves.

---

# 17. Candy Stacking

Your idea of making candy **additive** is good.

For example:

One Red Licorice:

**+10% damage**

Two:

**+20%**

Three:

**+30%**

Four:

**+40%**

But I'd introduce a soft cap.

For example:

> Maximum 10 active candies of the same type, and **20 active in total**.

Candy is applied **after** clovers (clovers set the base, candy multiplies it), so the numbers stay readable and a clover upgrade never feels wasted on a candy run.

**A candy's level raises *its own* buff; the stacking caps do not move.** A level-10 Red Licorice is worth +19% instead of +10% — so a fully levelled candy is roughly **twice** a fresh one, not ten times one. That is the whole balance of the candy level track: it buys quality, not a second axis of stacking. Ten maxed Red Licorices are still ten candies against the 20-active cap, and they still expire after five waves.

That lets players deliberately create absurd builds without letting the numbers become infinite.

---

# 18. Candy Creates Build Runs

Now Endless becomes much more interesting.

You might enter with:

**4 towers**

and consume:

- +50% damage
- +30% crit
- +40% burn
- +20% range

Suddenly your build is fundamentally different.

Another player might choose:

- +80% slow
- +50% stun duration
- +40% root duration

and create a **control build**.

---

# 19. Endless Mode

Endless should have its own progression.

The player starts at:

**Wave 1**

Every time they reach a milestone:

**Loot Box!**

But instead of fixed intervals:

### First box

Wave **10**

### Second box

Wave **12**

### Third box

Wave **15** (14.4 rounded up — the formula below governs)

### Fourth

Wave **17.28**

And so on.

The 20% multiplier creates exponential spacing.

However, I'd round it to whole waves:

> `ceil(previous_target × 1.20)`

So:

**10 → 12 → 15 → 18 → 22 → 27 → 33 → 40 → 48 → 58...**

This becomes a very nice psychological system.

---

# 20. Endless Loot Boxes

Every box is **a choice** (§21), not a random package. The offers are drawn from these four:

- 🩸 Blood Shards
- 🌱 Seeds
- ☘️ Four-Leaf Clovers
- 🍬 Candy

The box's **tier** sets the quality of the three offers inside it.

### Common

Small amounts.

### Uncommon

Better quantities.

### Rare

Large currency bundle.

### Epic

Special candy or Blood Shards.

### Legendary

Potentially unique cosmetic/collection rewards.

This gives players a reason to push _just a little farther_.

---

# 21. The Endless Choice

I'd make the loot box a **choice of three rewards** rather than a completely random package.

Example:

```
      LOOT BOX

   🌱 20 Seeds

   OR

   🩸 2 Blood Shards

   OR

   🍬 5 Sour Drops
```

This is much more interesting than simply opening a random box.

**Offer tables — v1 numbers of record, expanded in `economy.md`:**

| Box tier | Weight (boxes 1–5) | Seeds | Clovers | Shards | Candy |
| --- | --- | --- | --- | --- | --- |
| Common | 50% | 5–10 | 10–20 | — | 1–2 |
| Uncommon | 28% | 10–20 | 20–35 | 1 | 2–4 |
| Rare | 14% | 25–45 | 40–70 | 1–2 | 3–6 |
| Epic | 6% | 50–80 | 80–120 | 2–3 | 5–8 |
| Legendary | 2% | 100 | 150 | 5 | 10 |

Amounts scale by `1 + 0.15 × box_index`, so box 20 still feels like a reward. From box 15 onward the weights shift toward the top end (20 / 30 / 28 / 16 / 6). **Legendary pays a big currency bundle in v1** — the "unique cosmetic" tier waits until the art pipeline is not the critical path (`roadmap.md`).

The player gets to decide:

> "Do I want immediate tower unlock progress, permanent meta progression, or temporary power?"

---

# 22. Endless Escalation

Every 10 waves, increase difficulty.

But don't just increase HP.

Rotate modifiers.

### Wave 20

Zombies +25% HP.

### Wave 30

Zombies +20% speed.

### Wave 40

Armored zombies.

### Wave 50

Two spawn points, alternating. (Cheap: `obj_spawn` already supports more than one, and the path is grid-based.)

### Wave 60

Boss.

### Wave 70

Reduced tower range — a **global modifier** (one multiplier read by the range test in `scr_tower_normal`), not a per-tower debuff.

### Wave 80

Elite zombies.

### Wave 100

**Endless Boss.**

### Waves 110 and beyond

The list repeats on a **90-wave cycle**, and each cycle multiplies all of it: **HP ×1.5 and speed ×1.05 per cycle**. The *modifiers* keep rotating while the pressure still rises, so Endless never settles into "same game, bigger HP numbers" and never becomes static either. A run ends when the player loses, or at wave 500 for the leaderboard's sanity.

This prevents Endless from becoming:

> "Same game, bigger HP numbers."

---

# 23. The Full Meta Loop

The whole system now forms a nice circular economy:

```
                 CAMPAIGN
                    │
                    ▼
                 🌱 SEEDS
                    │
                    ▼
              UNLOCK TOWERS
                    │
                    ▼
               HARD / BRUTAL
                    │
                    ▼
             ☘️ FOUR-LEAF CLOVERS
                    │
                    ▼
             PERMANENT UPGRADES
                    │
                    ▼
                STRONGER RUNS
                    │
                    ▼
                 ENDLESS
                    │
          ┌─────────┴─────────┐
          ▼                   ▼
     LOOT BOXES           ZOMBIE KILLS
          │                   │
          ▼                   ▼
  🌱 🩸 ☘️ 🍬              🩸 BLOOD SHARDS
                              │
                              ▼
                       BLOOD TECH TREE
                              │
                              ▼
                          MORE CANDY
                              │
                              ▼
                        STRONGER RUNS
```

That's the core system I'd build around.

---

# 24. The Four Permanent Progression Trees

I'd ultimately make the player's **Garden Book** contain four trees:

### 🌱 Seed Tree — Content

Unlocks:

- Towers (the 8 unlockables)
- Regions
- Campaign stages
- Region mechanics
- Signature abilities at L5

Seeds are **content only** (§1) — they never buy power, which is what keeps the four currencies from blurring. Once the roster is complete, leftover seeds convert to clovers at **20:1**, deliberately bad, so it is a safety valve rather than a strategy.

**Question it answers:**\
_"What can I play?"_

---

### ☘️ Clover Tree — Power

Unlocks:

- Tower **floors and caps** — where a tower arrives, and how far it can go (§4, §13)
- Global stat bonuses
- Economy improvements
- Starting bonuses
- Permanent tower improvements

**Question it answers:**\
_"How strong is my garden?"_

---

### 🩸 Blood Tree — Meta

Unlocks:

- Blood drop chance
- Rare enemies
- Blood events
- Special candy recipes
- Endgame systems

**This tree is finite on purpose** — five tiers and it is finished. The unbounded shard sink is candy *levels* (§16), which is why shards stay interesting long after the tree is done.

**Question it answers:**\
_"What am I working toward long-term?"_

---

### 🍬 Candy — Temporary

Provides:

- Damage
- Range
- Crit
- Status effects
- Economy
- Attack speed
- Special effects

…and **levels 1–10 on each candy**, bought with blood shards, which raise whichever of those the candy provides. Recipes and levels are permanent; the stock is consumed.

**Question it answers:**\
_"How do I make this particular run ridiculous?"_

---

# 25. One More Collectible: Garden Badges

I would add **one non-economic collectible system**.

Don't make everything a currency.

Each stage has optional **Garden Badges**.

Examples:

🏅 **Untouched**

- Finish without losing a life.

🏅 **Frugal**

- Finish while spending less than 50% of the stage's median spend (published in the Deploy briefing; dev-tracked).

🏅 **Botanist**

- Finish using four different tower types.

🏅 **Purist**

- Finish using only one tower.

🏅 **Exterminator**

- Kill every zombie.

🏅 **Speed Grower**

- Finish before a time limit.

🏅 **Brutalist**

- Complete Brutal difficulty.

These don't buy anything.

They exist as **permanent accomplishments**. In v1 the reward is the record itself — one profile medal per badge, stored in the save. Cosmetic unlocks are deferred until art is no longer the critical path (see `roadmap.md`).

That gives completionists something to chase without contaminating the game's economy.

---

# 26. The Result

The game now has **three fundamentally different reasons to replay a stage**:

### "I need Seeds."

Play campaign.

### "I need Clovers."

Try to finish with as many lives as possible.

### "I need Blood Shards."

Kill as many zombies as possible.

And then:

### "I want to see how far I can get."

Play Endless.

That is a very healthy foundation for replayability because the player isn't just grinding one resource.

**Campaign = progression.**\
**Difficulty = mastery.**\
**Lives = optimization.**\
**Blood Shards = long-term chase.**\
**Candy = experimentation.**\
**Endless = score/push-your-luck.**\
**Badges = completionism.**

The next thing I'd lock down before designing dozens of towers is the **actual numerical economy**: starting Seeds, tower unlock costs, Clover costs, Blood Shard probabilities/pity, Candy prices, tower level costs, stat growth per level, and Endless loot-box scaling. Once those numbers are established, we can design the 20-ish towers around a stable mathematical framework instead of having to rebalance the entire progression system later.

---

# 27. Loop & UX (locked)

This is the section the original brief was missing: how the player actually travels between all of the above.

## 27.1 The loop, in order

1. **World map** — 6 regions × 10 stages. Locked stages are visible and greyed; a region opens when the previous region's stage 10 boss falls.
2. **Deploy** (§3.1) — difficulty, 4 slots, `Deploy`. Pre-filled, one click.
3. **Play** — money buys towers and levels; waves run; the in-run HUD shows money and lives.
4. **Stage reward** — seeds (first clear full, repeat 25%), clovers (remaining lives × difficulty), badges, and any blood shard drops (§14).
5. **Garden Book** — spend seeds (towers), clovers (the four trees), shards (blood tree + candy recipes).
6. **Repeat**, or **Endless** for boxes and speed.

## 27.2 The five screens that have to exist

| Screen | Purpose | What it is built from |
| --- | --- | --- |
| World map / stage select | pick a stage, see region progress | new, on the `Menu` state-machine pattern |
| Deploy | difficulty + 4 slots + the locked-tower wall | new; reuses `_button` and `scr_button_greyout` |
| Stage results | seeds / clovers / badges / shards earned | extend `rm_score` (`objects/_score`) |
| Garden Book | the four trees | new, `Menu` pattern again |
| Blood & candy shop | recipes, stock | a tab inside the Garden Book |

Five screens, all on the same state-machine + button pattern that `objects/Menu` already proves. No new UI framework — which is why this is *work* in the plan rather than *risk*.

## 27.3 Failure, retry, replay

* Lose all 20 lives → the stage ends. **Everything already banked is kept**; the stage pays nothing and un-earned badges are lost.
* Retry pre-fills the loadout and offers `Change loadout` as one extra click — it does not force the full Deploy flow again.
* Any cleared stage can be replayed at any difficulty: 25% seeds, clover decay per §11.
* *Purist* (§25) only awards on a first clear, so it cannot be farmed with a degenerate loadout.

## 27.4 The six region mechanics — all built from what already exists

| Region | Mechanic | Reuses |
| --- | --- | --- |
| 1 Grass | none — this is the tutorial region | — |
| 2 Swamp | water cells cannot hold towers | `obj_tower/Create_0` already sets `inWater` from the ground map |
| 3 Desert | sandstorms: periodic global range debuff | the wave-modifier system from §22 |
| 4 Jungle | alternating spawn points | `obj_spawn` is already a list |
| 5 Graveyard | zombies rise mid-path from graves | the climbing state in `obj_mon` / `scr_zombie_emerge` |
| 6 Blood Fields | night: more elites, pity bonus | spawn tables + the shard counter |

**Not one of these needs new engine technology.** That is deliberate: six regions is a *content* promise, and content is only cheap when it reuses systems.

## 27.5 Onboarding order

| Moment | What appears |
| --- | --- |
| Stage 1 | the Deploy screen (4 auto-filled slots and the locked wall), money, lives |
| First clear | seeds, and the first unlock (25 🌱) |
| Stage 5 | badges — the first *Untouched* attempt |
| Region 1 boss | Endless mode |
| First blood shard | the Blood tree and candy |
| Tower cap 6 | the Seed Tree's mastery branch (pointless before then) |

Nothing is shown before it can be acted on. Four currencies on screen at stage 1 is the single most likely way to lose a new player.

## 27.6 Technical prerequisites (this is largely why Phase 0 exists)

* **A working save.** `scr_save_static` / `scr_load_static` build their path from `working_directory`, and the load call in `scr_setup_statinv` is commented out — the entire meta layer has nowhere to live until that is fixed. Copy the `gameOptions.dat` pattern from `scr_saveOptions` / `scr_loadOptions`, which correctly resolves into the per-user save area.
* **Per-stage life**, not per-run: `life` starts at 20 in `_levelControl/Create_0.gml` and is decremented by `scripts/lose_life`.
* **`room_speed` → `game_get_speed(gamespeed_fps)`** before any status-effect timing is written (LL-007).
* **Level flow → `enum` + `switch`** before stage phases are layered on it (LL-004; the Menu is the reference implementation).
* **Path integrity.** A placement must never be able to pocket a zombie, and a broken path must heal itself (`roadmap.md` §4.4.1). Any rule that can leave a wave un-completable is a soft-lock, and a soft-lock in a 60-stage campaign costs a player an entire session.
* **The pause snapshot** must own its own alpha and assume nothing about surface sizes (`roadmap.md` §4.4.2). A UI overlay that reads another state's fade variable is a UI overlay that will one day be invisible.
* **The tower card** is the surface the loadout and mastery UI will grow out of, so it is worth building once, properly (`roadmap.md` §4.4.3).

---

# 28. Scope & phasing (the plan of record)

## 28.1 What v1 ships, and why

| | The brief asked for | v1 builds | The reason |
| --- | --- | --- | --- |
| Towers | "20-ish" | **12** — 4 free + 8 unlockable | 45 hand-drawn frames per tower; 20 towers ≈ 900 frames |
| New zombies | 12–18 | **6**, one per region, plus stat/behaviour variants | 30 frames each; variants cost data, not art |
| Bosses | 6 | **6** — 2 retuned, 4 new | boss rigs are the most expensive art in the game |
| Regions × stages | 6 × 10 | **6 × 10** | the *cheap* part, once stages are data-driven |
| Region mechanics | 6 | **6**, every one reusing an existing system (§27.4) | no new engine technology |
| Specializations | 2 per tower | **2 × 12** | 40 specs is a balance treadmill, not a design win |
| Badges | 7 per stage | **7 types**, medals only | the record is the reward; cosmetics need art |
| Status effects | 7 + 2 | **7** | armor break left with armor (§6) |

Art drops from roughly **1,800 frames to roughly 850** without removing a single *system*. Systems are the risky part; art is the parallelizable part. That is the whole logic of this section.

## 28.2 The seed economy (numbers of record; full tables in `economy.md`)

Unlock prices: **25, 50, 90, 150, 230, 340, 480, 650** → **2,015 🌱** for all eight.

| Path | Seeds earned |
| --- | --- |
| Normal, all 60 first clears | 620 |
| + Hard on everything | ~1,240 |
| Full Brutal sweep | ~3,100 |

So a Normal-only player **cannot** unlock the whole roster — they have to meet the game at Hard or Brutal, which is exactly what §2 asks for. The first unlock (25 🌱) is ~9 Normal stages or **2 Brutal stages**, so the promise lands in the first session.

## 28.3 Where every number lives

| Number | File |
| --- | --- |
| Region/stage table, rewards, gates, badges | `stage_data` (new — Phase 0) |
| Difficulty multipliers | `difficulty_data` (new — Phase 0) |
| Tower stats, prices, specs | extend `tower_array` + `scr_towerData` (add crit/status fields) |
| Mastery (**floor and cap**), candy levels, currencies, badges, loadout | the save file (Phase 0) |
| Wave HP/speed scaling | `scr_level_difficulty`, rewritten with §4's curve |

## 28.4 The phases

| Phase | Deliverable | Gate |
| --- | --- | --- |
| **0. Foundations** | a save that works; `stage` / `region` / `difficulty` data; level flow → `enum` + `switch`; `room_speed` fixed | a stage declared in data is playable and progress survives a restart — *nothing player-visible ships* |
| **1. Vertical slice** | region 1: 10 data-driven stages, 3 difficulties, seeds, one clover branch, badges, Deploy screen, world map, 6 towers | **clear stage 1 → unlock a tower → farm clovers → replay for a badge → quit → it is all still there** |
| **2. Combat depth** | crit, burn/slow/stun, persistent levels 1–5, specializations, the `scr_level_difficulty` rewrite | a stage is winnable *and* losable for the right reasons; two loadouts play measurably differently |
| **3. Garden Book** | the four trees, all five master nodes, currency HUD, the mastery panel | every currency can be earned *and* spent; none is inert |
| **4. Endless, candy, shards** | endless mode, 1.2× boxes, choice-of-three, the pity counter, the blood tree, candy recipes | a run reaches box 5+; a shard drops in a normal session |
| **5. Content** | regions 2–6: 5 biomes, 5 mechanics, 5 bosses, 6 zombies, 6 towers, 50 stages | the full campaign is completable and the §28.2 checkpoints hold |
| **6. Balance & polish** | retune from logs, audio, an onboarding pass | a fresh player reaches stage 5 unaided |

**A closed meta loop at one region is ~70% of the systems work.** Everything after Phase 1 is content and tuning — which is precisely why these phases are ordered this way instead of content-first.

## 28.5 Cut order — decided now, so it is not decided in a panic later

1. Cosmetic rewards for badges and legendary boxes
2. Badges beyond the five core (*Untouched, Frugal, Botanist, Purist, Exterminator*)
3. Candy tier 3 recipes
4. Regions 6 and 5
5. Towers 12 → 8

**Never cut:** the save, the Deploy screen, the closed loop at region 1, or the four-currency identity.

## 28.6 Reconciliation log — every discrepancy found in review, and its resolution

| Was | Now |
| --- | --- |
| Seeds from "campaign completion" | per stage, first clear full / repeat 25% |
| In-run money absent from the brief entirely | named as the fifth, run-scoped economy (§1) |
| "2–3 new zombies × 6 regions" | 1 per region + variants (§2, §28.1) |
| 20 tower names vs "20-ish towers" | a fixed 12-slot roster (§10.1) |
| Candy from three sources, one contradicting §16 | recipes (shards) vs stock (boxes/shop) (§16) |
| "Remaining lives" with no life model | life is a per-stage budget of 20 (§11) |
| 0.01% drop rate with +10%/+25% nodes | a real pity curve, and nodes in −kills-required (§14, §15) |
| "increases the chance slightly" | the explicit formula in §14 |
| Wave 14.4 vs 15 | 15, with the formula as the authority (§19) |
| §20's randomised box vs §21's choice of three | a choice, tiers govern quality (§20, §21) |
| §22 stopping at wave 100 | a 90-wave cycle with per-cycle multipliers (§22) |
| "Wave 50: two paths" | two alternating spawn points (§22) |
| Seed Tree unlocking specializations | specs are automatic at L3; the tree grants mastery (§24, §13) |
| "Frugal: less than X" | 50% of median spend (§25) |
| Cosmetic rewards assumed | medals in v1, cosmetics deferred (§25) |
| §14's spliced sentence | repaired (§14) |
| Loadout undefined | a full spec, and the first-game case in §3.1 |
| Seeds as a power currency (levels 6–10, 1,180 🌱 per tower) | seeds are **content only**; clovers grant the tower **floor and cap** (§4, §13), and leftover seeds convert to clovers at 20:1 |
| Mastery raising only the cap | one node raises floor **and** cap, so the money climb is always four rungs — money never becomes irrelevant (§4) |
| Candy had recipes and stock only | candy also has **levels 1–10** bought with shards — the game's unbounded shard sink, which is what keeps a rare drop interesting forever (§16, `economy.md` §6.4) |

