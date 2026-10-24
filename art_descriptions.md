# Art descriptions — the remaining art, in enough detail to draw from

**What this is.** One brief per open art job: what the game actually does today,
what is missing, what to draw, and the technical contract the drawing has to
meet. It exists because the board (`progress.json`) says *what* is owed but not
*what it looks like*, and because "draw a swamp tileset" is not a brief.

**Who it is for.** Rayu (the artist — the ownership questions are his to settle,
see §6) and cline (who wires whatever arrives). Every number here was measured
from the repo on **2026-10-19**, not remembered: canvas sizes and origins from
the sprite `.yy` files, draw scales and tints from the GML, frame counts from
the frame lists. Where a thing is a **proposal** rather than a fact of the game
it says so.

**The one rule that overrides taste.** Art is only finished when the game
*shows* it: a sprite nothing references is not a tower, a tileset no stage
selects is not a biome (LL-023, and the Belladonna card that claimed "NOTHING"
while a week-old trio sat in the repo). §5 is the checklist that catches that.

## What has landed since these briefs were written

**2026-10-21 — 75 sprites, 142 frames.** The drawing half of §4.3 (props),
§4.4 (every icon), §4.5 (the banner) and §4.9 (four trios and their effect
sprites) is now IN the project, and four of those uses are wired. Read a brief
below as *what the art is for*, not as *work to do*, unless it says otherwise:

| Brief | State on 2026-10-21 |
| --- | --- |
| §4.5 level-complete banner | **delivered and drawn**: `bck_level_complete_banner`, 680×360, art 647×323, one sprite pixel to one screen pixel at 16:9 |
| §4.3 biome atlases + props | **props delivered** (18 sprites), **atlas still missing** — there is no `spr_graveyard_128x`, so region 5's ground is unchanged |
| §4.4 meta icons | **delivered** (36 icons); the currency line, the Offense heading, the node pips and the headstones draw them — the rest wait on their screens |
| §4.9 tower trios + effects | **delivered** (Tulip, Meat Bulb, Kaboom, Marigold, and the eight shot effects); Tulip and Meat Bulb are in the roster and now throw a muzzle puff and an impact, Kaboom and Marigold have no tower yet |
| §4.1 bosses, §4.2 zombies | **not in this drop** — still owed |

The banner's `bck_` name (against §3.7's `spr_` convention), the two blood icons
whose origin is `(0,0)`, and the four sprite sets this drop made unreferenced
are all on the board (`art-cleanup-unreferenced`), not in a comment.

---


## 0. The open art jobs, and what is actually missing

| Card | Status | What is genuinely missing | Drawing? |
| --- | --- | --- | --- |
| `region-bosses` | **code done 2026-10-24** | the **4 new boss rigs** and their 4 portraits arrived and are wired (a row carries `array(walk, idle, attack, die)`, `scr_zomb_art` plays it); region 2 reuses an existing boss | — |
| `region-zombies` | **code done 2026-10-24**, one art job left | the **6 rigs** arrived (walk + idle + attack + die each); **two portraits are still missing** - Sandblasted and Shroud (`art-sandblasted-portrait`). `attack` is drawn but never played: the gate is a place, not an enemy (`zomb-attack-at-gate`, §3.2) | two portraits |
| `tower-slice-trios` | **done 2026-10-21** | all four trios arrived; Tulip and Meat Bulb draw theirs, Kaboom and Marigold wait for their towers (§4.9) | — |
| `art-biome-tiles` | backlog | **only the Graveyard atlas** — the 18 props arrived 2026-10-21; the other four biomes already have greyscale atlases (§4.3) | small |
| `art-garden-book` | **done 2026-10-21** | every icon arrived (36); the screens that show the rest are their own cards | — |
| `art-level-complete` | **done 2026-10-21** | the banner arrived and is drawn at 1:1 (§4.5) | — |
| `art-state-origins` | next | **no drawing** — per-state y-origins (§4.8) | no |
| `portrait-draw-fit` | backlog | **no drawing** unless frameless busts are chosen (§4.6) | optional |
| `legacy-boss-art-cleanup` | backlog | **no drawing** — five unused sprites to delete (§4.7) | no |
| `tower-belladonna` | backlog | **no drawing** — the trio exists, the code does not (§4.9) | no |

Not on an art card yet: **Kaboom Kalanchoe** and **Money Marigold** (roadmap 5.5)
have their art since 2026-10-21 but no final design — §4.9 describes them
provisionally so the design cards have something to agree with, and their trios
and effect sprites sit in the project unused until those towers exist.
**Cannon Tulip** and **Meat Bulb** were on borrowed art until the same drop;
they now draw their own (§4.9).

---

## 1. What already exists (do not redraw these)

Verified by opening the files, not by listing names:

* **Tower trios, 192×192, 5–9 frames per state** — Daisy Pusher, Burning Ivy,
  Slender Mandrake, Pina Collider, Chillip, Thornamental, Bindweed and
  Belladonna Blitz. All eight have idle / attack / return. Four of them
  (Chillip, Thornamental, Bindweed, Bella) are not yet on the roster, but their
  art is finished. **Cannon Tulip and Meat Bulb are on the roster and still wear
  the old `spr_t3_*` / `spr_t4_*` trios** — see §4.9.
* **Monster rigs, 4 states × 16 frames** — Grumble-Mulch, Dome-Alone,
  Professor-Cerebrisk, plus the two bosses Tusk-A-Lot and Sub-Zero. Each state
  has its **own canvas size** (that is the origin bug, §4.8).
* **Portraits, 314×314** — five: grumble, dome, cerebrisk, tusk, zero. Rusted
  gold frame, painterly rim light, vignetted background.
* **Terrain atlases, 128×128 × 17 frames, greyscale** — grass, dirt, sand,
  thick, **swamp, desert, jungle, blood**. The last four are real, distinct,
  hand-drawn atlases (mud and reeds / cracked sand plates / root-and-moss /
  veined ground), already in the repo and already the right format. See §4.3 —
  this contradicts the card.
* **Props** — `bck_fence` (128×128), `bck_house` (128×128), `bck_debree_blood`
  (288×32 gore strip, used by every zombie death), `spr_graves` (4 tombstones,
  64×64), `bck_water` + `bck_waves` (water shader), `spr_tower_grass` (48×48).
* **UI** — `spr_icon` (64×64, 2 frames), `spr_button` (36×36), `spr_coin`,
  `spr_heart`, `spr_flower`, `spr_timer`, `spr_level_complete` (placeholder).
  Everything else in the Garden Book and world map is **rectangles and text**.

If a brief below overlaps something on this list, the list wins — correct the
board, don't redraw.

---

## 2. The house style, measured

The game's art is **cartoon PvZ-like**, and the reference set is small enough to
hold in your head: `spr_daisy_idle_192x`, `spr_grumble_walk`,
`spr_tusk_portrait`, `spr_bindweed_idle_192x`.

| Property | What it is | Consequence for new art |
| --- | --- | --- |
| Outline | Thick black outer contour (about 3 px on a 192 canvas, 2 px on a 150 canvas), thinned or dropped on interior detail | The silhouette is what the player reads at 25–50 % scale — design it first |
| Shading | 2–3 flat bands of cel shade plus one hard highlight; no soft airbrush gradients on the body | Recolour variants are cheap because the shading is flat |
| Palette | Saturated mid-tones, dark saturated shadows, warm highlights; green/red/gold dominant | Keep new subjects inside that family; the portraits are the least saturated art in the game |
| Faces | Big readable eyes, visible mouth/teeth; a plant has a face on its flower/head | A tower or zombie without a face reads as scenery |
| View | Side-on, **drawn facing right**; monsters are mirrored by a negative `image_xscale` | Never draw left- and right-facing frames |
| Detail floor | Nothing thinner than ~2 px at final size; no text, no fine filigree | At 40 px tall a 1 px line disappears; the level-complete banner is the one exception (it is 324 px tall) |

**Scale budget — the number that decides how much detail is worth drawing:**

| Thing | Canvas | Drawn at | On screen (960×540) |
| --- | --- | --- | --- |
| Tower | 192×192 | `draw_scale` 0.5 (frozen — the level look owns it) | ~96 px tall |
| Monster | ~140×160 | `base_scale` 0.25 (boss 0.5) | ~37 px tall |
| Boss | ~230×200 | 0.5 | ~100 px tall |
| Portrait | 314×314 | fitted into a 64×64 slot (bug, §4.6) | 64 px today |
| Terrain tile | 128×128 | ×0.2525 | ~32 px |
| Level-complete banner | 200×100 today | 60 % of the 540 px port | 324 px of art |

Three consequences worth stating plainly:

1. A new **monster** is seen at 37 px. A face, a silhouette and one colour
   accent are the whole budget; interior stitching will never be seen.
2. A new **boss** is seen at 100 px, and its **portrait** at 314 px. The portrait
   is where the character is actually designed.
3. **Tower level** is carried by an outline colour (levels 2–10), not by size,
   because `draw_scale` is frozen at the placed 0.5. Tower art must therefore
   keep a clean, closed outer silhouette that a coloured outline can trace.

---

## 3. The technical contract

Read this before any of §4; it is the part that turns a drawing into a working
asset. The project's rules apply throughout: sprites are imported **in the
GameMaker IDE** (never by hand-editing `.yy`, LL-009), `bboxMode` stays
**automatic** unless stated, and a missing sprite is a fatal draw (LL-012).

### 3.0 Pixels — hard alpha, one rim, no halos (`gm art`)

New art arrives from the drawing tool **anti-aliased**: a 1 px ramp of fractional
alpha round the silhouette, often with an `alpha 1–8` halo a row or two outside
it. At 1:1 that reads as a drawing; at `base_scale 0.25` — the scale the game
actually draws at (§2) — a 50 %-covered pixel becomes 12 %-covered and the whole
sprite reads as a grey smudge with no edge. It cannot be fixed by scaling or by
a filter, because the problem is in the file's alpha values.

```bash
# the gate (decodes every frame; exit 1 on any finding)
PYTHONPATH=python_tools python3 -m gm art check --folder "Zombie Sprites/restyled"
# the pass, after copying the originals somewhere
PYTHONPATH=python_tools python3 -m gm art clean --backup /tmp/art_before --sprite 'spr_shroud_*'
# a before/after sheet, because "does the rim read right?" is an eye question
PYTHONPATH=python_tools python3 -m gm art preview --backup /tmp/art_before \
    --folder "Zombie Sprites/restyled" --state idle
```

`clean` snaps every alpha to 0 or 255 at the 50 % coverage contour, zeroes the
colour of the pixels it clears (or bilinear sampling drags the halo back in),
and strokes the contour **inside** the silhouette: a 1 px rim whose outer edge
*is* the silhouette, i.e. inset by half a pixel. Nothing outside the silhouette
moves, so the canvas, the origin and the bounding box stay as imported and **no
`.yy` is touched** (`gm roundtrip` stays at 0 differ). Both copies of every
frame are written from one buffer — `sprites/<spr>/<guid>.png` and
`sprites/<spr>/layers/<guid>/<layer>.png` — because the IDE shows the first and
the game samples the second (LL-073).

`check` fails on a partial alpha, a colour left in a cleared pixel, a contour
that is not `(0,0,0,255)`, or a layer copy that disagrees with its root. Run it
on every drop: it is the answer to "is this art ready to look right in game?",
and it costs a second per sprite.

The one judgement call the report hands back: an **isolated 1 px speck** (a
single opaque pixel that touches nothing, not even diagonally) becomes a black
dot, because the stroke inks it entirely. `clean` says how many it found; if the
preview shows one of them was meant to be visible, the fix is to drop specks in
`binarize`, not to widen the stroke.

### 3.1 Towers — one canvas, one origin, three states

| Field | Value |
| --- | --- |
| Canvas | **192×192**, every state, every frame |
| Origin | **(96, 157)** — the plant's feet, stays put in all states |
| States | `spr_<name>_idle_192x`, `_attack_192x`, `_return_192x` |
| Frames | 4–9 per state; **frame count is not timing** (LL-030 — speed is derived) |
| Naming | existing convention, `_192x` suffix is literal |
| Margins | ≥ 8 px transparent at the top and sides; the plant's base sits on y≈157 |

`attack` is played once on the shot, `return` once after it, `idle` loops. The
attack must **read as a recoil/fire**, not just a different pose: the tower is
96 px on screen and the player learns the rhythm from the silhouette.

### 3.2 Monsters — one canvas per character, feet on one row

The current rigs break this rule, which is why the art jumps between states
(§4.8). **New rigs must not repeat it.** For each new character:

| Field | Value |
| --- | --- |
| Canvas | **one size for all states** — recommended 240×200 |
| Origin | **fixed** at (120, 190) for every state and every frame |
| Feet row | the same y in every state sheet; nothing may move the ground contact |
| States | `idle`, `walk`, `attack`, `die` — 16 frames each, existing rig convention |
| Facing | right; the game mirrors with `image_xscale < 0` |
| Margins | 10 px minimum around the silhouette, so the black outline is never clipped |

**What the game currently uses** matters for sequencing: `obj_mon` plays
**`sprite_array[0]`, `[1]` and `[3]`** — `walk` while it is moving, `idle` while
it is blocked, and `die` when it is killed (`scr_zomb_art`: it switches only when
the state changes, so a one-sprite rig still works). **`attack` — slot 2 — is
never played**: a monster in this game does not fight, it walks to the gate and
takes a life, so that slot is drawn and unused until the gate grows a real
engage step (`zomb-attack-at-gate`). Dedicated `idle`/`die` sheets are therefore
worth drawing for a new rig; the walk cycle stays the one mandatory state (§4.2).

### 3.3 Portraits — 314×314, gold frame, painterly

| Field | Value |
| --- | --- |
| Canvas | **314×314**, one frame |
| Composition | head-and-shoulders bust, slightly turned, filling the frame under the border; background is a dark vignetted texture, not transparent |
| Frame | rusted gold, ~14 px, inset rounded-square; the same frame on every portrait or the popup looks like a different game |
| Light | warm rim from the upper left, cool shadow on the right |
| Naming | `spr_<character>_portrait` |
| Used by | the "Up Next…" textbox, via `MON.portrait` — **every new monster and boss needs one** |

### 3.4 Terrain atlases — greyscale, 17 frames, tinted by code

This is the least obvious contract in the project, so it is spelled out:

* A terrain atlas is **one sprite, 128×128, 17 frames**, drawn at `0.2525`
  scale (≈32.3 px) as a sprite-layer tile.
* **The art is greyscale.** Colour is applied at draw time with
  `layer_sprite_blend()` — a multiply. Existing atlases average ~150–175 grey
  precisely so a tint does not crush them. **Do not bake biome colour into the
  atlas**: it multiplies twice and turns to mud.
* **Frame 0 is empty.** Frames 1–16 are the 16 neighbour combinations, indexed
  by `1 + east·1 + north·2 + west·4 + south·8` (`set_bitmask`). Frame 1 = an
  isolated single tile; frame 16 = an interior tile with solid neighbours on
  all four sides.
* Because frame 16 tiles butt against each other, **its four edges must be
  seamless**. The isolated tile (1) needs a designed edge — it is the only place
  the player sees the underside of the terrain.
* The highest ground row is drawn from **frame 16 of `spr_dirt_128x`**, tinted
  `rgb(64,37,11)` — the dark top-soil cap. A new biome atlas does not replace
  that cap; changing it is a code/config job, not a sprite.
* Rows are tinted with a `merge_colour()` between two colours per band, so a
  biome reads as *value* first, hue second. Design in greyscale: the tile's
  silhouette (cracks, tufts, puddles) is what survives.

### 3.5 UI icons — shapes, not pictures

The Garden Book, the world map and the Deploy screen are **flat panels and
text** (`meta_panel()`, `meta_text()`, GUI pinned at 960×540). There is no icon
system to fit into, so the contract is simply:

* transparent PNG, **one subject, centred, 2 px dark outline**, readable at
  **24 px**;
* distinguishable **by silhouette**, because colour is the only other channel
  and the UI is text-heavy;
* **pad generously and centre the subject**: the code fits the ART (its bounding
  box) to the space available and scales it fractionally, so a 24×24 canvas
  holding 18×20 of art draws an 18×20 icon and a larger canvas is free room, not
  a larger icon ([LL-071](./lessons_learned.md#ll-071));
* no text and no numbers in the art (the code draws the numbers).

Recommended sizes: **24×24** currency icons, **64×64** candy and badge icons,
**48×48** tree / mastery / blood nodes.

**Where a sprite lands is decided by its art, not by its canvas or its origin.**
`icon_draw()` and `meta_sprite_fit()` measure `sprite_get_bbox_*` and centre that
rectangle, so an icon with a `(0,0)` origin and one with a centred origin land in
exactly the same place. Keep the origin sensible anyway — the *world* still uses
it (feet for a tower sheet) — but it is no longer a UI-position decision, and a
new icon does not need its origin negotiated before it can be used.

### 3.6 The level-complete banner — measured, not guessed

`scr_level_complete_draw()` measures the **automatic bbox of the art**, not the
canvas, then scales that art to **60 % of the 540 px port** and centres it. The
current sprite is 200×100 with only 165×62 of drawing, so it is blown up ~5×.
A replacement should therefore be authored at the size it is seen:

| Field | Value |
| --- | --- |
| Canvas | **680×360** (generous padding is fine) |
| Art bbox | **648×324** — exactly 1:1 at full size on a 960×540 GUI |
| Origin | **middle-centre (340, 180)** |
| bboxMode | automatic (a manual box *becomes* the measurement) |
| Animation | none; the 80 %→100 % scale and the fade are done in code |

### 3.7 Naming and import

* Sprites: `spr_<subject>_<state>`; tower trios keep `_192x`; atlases keep the
  `_128x` suffix the code already calls (`spr_swamp_128x` etc.).
* One sprite per state (not a strip), one frame per PNG in playback order,
  idle first.
* Import in the IDE, `bboxMode` automatic, origin per §3.1–3.3. Then tell cline
  the sprite names: nothing is wired until a `.gml` names it.

---

## 4. Card by card

### 4.1 `region-bosses` — four new bosses, and one deliberate reuse

**What the game does today.** There are two bosses, both in `spawn_boss`:

| Boss | Art | Portrait | Role |
| --- | --- | --- | --- |
| **Tusk-A-Lot** | `spr_tusk_*`, walk 153×161, 16 frames | `spr_tusk_portrait` | a hillbilly boar in a rusted bucket helmet, fur collar, red neckerchief |
| **Sub-Zero** | `spr_zero_*`, walk 127×155, 16 frames | `spr_zero_portrait` | a blue-hooded skeleton with a round bomb and fuse on its back |

`goal.md` §28.1 promises **six bosses: two retuned, four new**, and region 2
reuses the second existing boss. So this card is **four new rigs + four
portraits**, and nothing for region 2.

**The shape of every boss.** A boss is a *character*, not a big monster: it
should be recognisable from its portrait down to a 100 px gameplay sprite. Each
one gets a silhouette unlike every other creature in the game, a two-colour
palette that says its biome, one "tell" that telegraphs its attack, and a death
that pays off the design.

**Frame plan (per boss):** walk 16 frames (mandatory — it is the sprite the
level plays), attack 16, die 16. Idle is optional until `obj_mon` actually
switches states. All states on **one 240×200 canvas with the origin fixed at
(120, 190)** — the §3.2 rule, and what stops the boss jumping when it switches.

#### Region 3 — Desert (Bleached Ironworks): **"Foreman Rustlung"** *(proposal)*

A factory foreman who was welded into his own machine. The body is a dried husk
in a shredded work shirt and one boot; the rest is a cage of rusted girders
grown *through* him. His left arm ends in a crane hook on a chain; his right
shoulder carries a gearbox like a pauldron; a length of conveyor belt hangs off
his back as a cape. His face is still human enough to be sad, and a rusted
bucket helmet sits crooked on his head — a visual rhyme with Tusk-A-Lot, not a
copy.

* **Palette:** bleached bone and chalky sand as the base, oxide orange and
  dried-blood brown as accents, one hot brass glint on the hook.
* **Silhouette at 100 px:** a hunched, top-heavy mass with the hook hanging
  clear of the body on the left and a ragged belt trailing right. Nothing else
  in the game is that shape.
* **Tell:** the hook lifts and the chain goes taut a beat before the swing.
* **Attack:** a wide horizontal hook sweep that drags the tower line out of
  position.
* **Death:** the girders let go; he goes down as a heap of scrap and the helmet
  rolls free.
* **Portrait:** heat-bleached and sand-caked, one eye milky and one still sharp,
  white sky and a gantry behind him. A man who kept working after the factory
  died.

#### Region 4 — Jungle (Vines Take the Ruins): **"The Orchid Widow"** *(proposal)*

A gardener's body that has been comprehensively taken over. The head is gone;
in its place a huge carnivorous orchid with a wet, toothy throat and a
gardener's straw hat jammed behind the petals. Vines run where her tendons
should be and root her to the ground when she stops. One hand still holds a
pair of shears; the other has become a woody branch with three hooked claws.

* **Palette:** wet jungle green and moss, with the bloom in hot magenta and
  cream — the only saturated pink in the region, so the bloom is the read.
* **Silhouette:** a tall stalk with a wide flower crown and a low, spreading
  root skirt; the asymmetry is the shears, held low and forward.
* **Tell:** the petals fold shut, then flare open.
* **Attack:** the bloom lunges forward on a neck of vines and bites, spraying
  pollen; the shears follow as a shorter second swipe.
* **Death:** the bloom bursts into petals, the vines go slack, and the body
  drops out of frame leaving the shears standing in the ground.
* **Portrait:** the bloom fills most of the frame, petals curling under the gold
  border, one human eye still visible deep inside the throat.

#### Region 5 — Graveyard (The Digested Past): **"The Bellringer"** *(proposal)*

The gravedigger who never stopped ringing for the dead. He is fused with the
bell: a cracked church bell is his torso, his head hangs forward out of the
crown, and the rope runs down through his ribs to a clapper he drags behind him
like a tail. Moss, grave soil and verdigris on bronze; one shoulder still has
the shovel he was buried with.

* **Palette:** slate and indigo with verdigris bronze; the only warm note is the
  wet earth he drags with him.
* **Silhouette:** a wide bell shape on two thin legs, with the clapper trailing
  far behind — a shape that reads even when it overlaps a headstone.
* **Tell:** he plants his feet and the bell swings back.
* **Attack:** the bell swings forward and the clapper cracks the ground, a
  low-frequency pulse that stuns towers.
* **Death:** the bell cracks in half, the rope goes slack, and the last thing
  standing is the shovel.
* **Portrait:** a bell rim framing a dirt-caked face, rope through the teeth,
  a graveyard receding behind him. The most mournful portrait in the set.

#### Region 6 — Blood Fields (Slaughterhouse Meadow): **"The Gardener"** *(proposal)*

The final boss, and the game's thesis in one silhouette: a colossal, rotten
topiary of the player's own daisy. A daisy's head with a cracked, weeping face,
grown far too large; a body of braided vines and butcher's stitching; a rusted
watering can in one hand, a scythe of thorns in the other; red meadow flowers
packed into the chest cavity where a heart should be. It is the only boss that
looks *sad* rather than hungry, and the only one whose palette is the player's
own green.

* **Palette:** deep green and dried blood, with the flower head in bone-white
  petals and a gold-brown centre. Crimson only where it has been cut.
* **Silhouette:** tall, with an unmistakable daisy crown; the scythe arcs out
  to one side. At 100 px it must still read as *a daisy*, which is the point.
* **Tell:** it kneels and plants the scythe, and the meadow flowers in its chest
  open.
* **Attack:** roots erupt along the path in a line; the scythe follows as a
  second sweep.
* **Death:** it kneels, the crown drops, and the chest flowers bloom outward —
  the one death in the game that is beautiful rather than gory.
* **Portrait:** a wilting daisy face, one petal missing, tears of sap; the
  background is the red meadow and the quarantine fence.

#### And the region 2 boss is already done

**Sub-Zero** is reused as-is. Do not redraw it for the swamp: the brief's own
arithmetic is "two retuned, four new", and a familiar boss returning in a new
biome is a feature (the player knows its bomb tell). If it needs anything at
all, it is a swamp-tinted **portrait background**, which is a small optional
variant, not a new rig.

**Acceptance.** Each new boss is visible in its region's stage 10, its portrait
appears in the "Up Next…" popup, and a full idle→walk→attack cycle keeps the
feet on one screen row (§4.8's test, applied to the new rigs).

---

### 4.2 `region-zombies` — six walk cycles, six portraits

**What the game does today.** Three monsters, all region 1, all restyled already:

| Monster | Speed / life | Walk sprite | Design |
| --- | --- | --- | --- |
| **Grumble-Mulch** | 1.0 / 7 | 140×160 | the baseline: green, red flannel, wild dark-red hair, boots |
| **Dome-Alone** | 0.5 / 12 | 138×160 | the tank: oversized teal head, orange shirt, red tie, one tooth |
| **Professor-Cerebrisk** | 1.5 / 5 | 147×170 | the fast one: exposed pink brain, round glasses, lab coat |

**The honest budget.** `goal.md` §28.1 budgets "30 frames each", and that was
right for the game as it was built: the level used to play the **walk cycle
only**. Since 2026-10-24 it also plays **`idle`** (while blocked) and **`die`**
(on the kill), so a new rig is worth **walk + idle + die = 48 frames + one
portrait**; `attack` remains drawn-but-unplayed until the gate grows a real
engage step (`zomb-attack-at-gate`, §3.2). The ten rigs that landed with
`region-zombies` / `region-bosses` all carry the full four slots, so the art is
ahead of the code in exactly one place, on purpose.

**Per-zombie frame plan:** walk 16 frames on a **240×200 canvas, origin
(120,190)**; portrait 314×314. If a state sheet is drawn, it stays on the same
canvas and origin (§3.2).

The themes below are **proposals**, chosen so that each one *shows its region's
mechanic* rather than just wearing its colours.

#### Region 1 — the sixth slot: **"The Newly Turned"** *(proposal)*
The arithmetic of the card is six zombies and five regions after region 1, so
one slot is region 1's. The cleanest use is a **fresh** zombie: a suburbanite
turned this morning — polo shirt, bathrobe, one slipper, mail still in hand, no
decay yet except the eyes and the jaw. Small and fast, the "oh no, that was a
person" enemy for the tutorial region, and the reference point the other five
decompose away from.
*Palette:* clean pastels against the region's grey-green; the only bright shirt
in the game's monster set. **If the six are meant as one per region (2–6) plus
a Blood Fields elite instead, say so and this slot becomes "The Stitched"** — two
torsos sharing one spine, stitched at the hip, which is also the best base for
recolour variants.

#### Region 2 — Swamp (Toxic Stagnation): **"The Bog Wader"** *(proposal)*
Waist-deep in the water its region forbids towers from standing in. Only the
torso and arms show above a skirt of dripping silt, weed and bone; the ribcage
has a faint sickly glow inside it; a snapped boat oar is still gripped in one
hand. It should look **heavy** — the opposite of Dome-Alone's bob.
*Palette:* bog brown and olive with a green-yellow inner glow. *Silhouette:*
wide and low, arms trailing, weed skirt breaking the outline. *Tell:* the water
ripples stop for a beat before it lunges.
*Why it is the region's zombie:* it walks where the player cannot build.

#### Region 3 — Desert (Bleached Ironworks): **"The Sandblasted"** *(proposal)*
A dried-out worker in shredded overalls, sand pouring from a tear in its side,
a length of rebar through one shoulder, cracked lips pulled back from perfect
teeth. Tall, thin, leaning into a wind that is no longer blowing.
*Palette:* bleached tan and bone, one oxide-orange overall strap, sand-white
highlights. *Silhouette:* tall and narrow with a long drag-chain behind.
*Tell:* it raises one hand to shield its eyes before it speeds up.

#### Region 4 — Jungle (Vines Take the Ruins): **"The Rootbound"** *(proposal)*
A corpse being taken apart by the jungle in real time. Roots burst out of its
chest and anchor it to the ground with every step; one arm has become a woody
branch; leaves grow where hair was; a single bright orchid sits in the hollow of
its throat.
*Palette:* wet greens and dark bark, the orchid as the one hot accent.
*Silhouette:* asymmetric, tendrils trailing, one shoulder much higher than the
other. *Tell:* the roots pull taut and it lurches.

#### Region 5 — Graveyard (The Digested Past): **"The Shroud"** *(proposal)*
A body still wrapped in a burial shroud, dragging a collapsed headstone on a
chain. No legs are visible — it moves in a low, creeping crawl of cloth, and the
shroud is wet enough to leave a trail. It is the one zombie that must read
**while emerging from the ground at zero scale**, because region 5's mechanic is
zombies rising from graves mid-path.
*Palette:* bone-white cloth, wet slate, one warm candle-gold glow in the folds.
*Silhouette:* a low triangle of cloth with two hands out and a stone dragging
behind. *Tell:* the shroud swells before it lunges.

#### Region 6 — Blood Fields (Slaughterhouse Meadow): **"The Harvester"** *(proposal)*
A scarecrow built from stitched carcass and red meadow flowers: a pole through
the spine, a burlap face, a scythe blade lashed to one forearm, petals packed
into the ribcage. Tall, spiky and unmistakable at 37 px — the elite the night
modifier is for.
*Palette:* dried blood red, ash grey, straw yellow; the only zombie with a
weapon that reads in silhouette. *Tell:* it plants the scythe and the flowers in
its chest open.

**Variants are not new art.** `goal.md` §28.1's "1,800 → 850 frames" claim rests
on variants costing *data*: a variant is a recolour (`image_blend` is already
available per instance), a scale change, or one silhouette add-on (a hat, a
wound, a missing arm) on an existing rig. Do not draw a second walk cycle for a
stats change.

**Acceptance.** Each new zombie appears in its region's spawn mix, at 37 px, and
is distinguishable from the other five **in silhouette**, not only in colour.

---

### 4.3 `art-biome-tiles` — the Graveyard atlas, and what "tileset" means here

**The card says "only Grass has art". That is wrong**, in the same way the
Belladonna card was wrong: the repo already contains **four of the five**
region atlases, in the exact format the code needs.

| Region | Atlas sprite | State |
| --- | --- | --- |
| 1 Grass | `spr_grass_128x` (+ `spr_dirt_128x`, `spr_sand_128x`, `spr_thick_128x`) | in use |
| 2 Swamp | `spr_swamp_128x` | **exists**, 17 frames, unreferenced |
| 3 Desert | `spr_desert_128x` | **exists**, unreferenced |
| 4 Jungle | `spr_jungle_128x` | **exists**, unreferenced |
| 5 Graveyard | — | **missing** |
| 6 Blood Fields | `spr_blood_128x` | **exists**, unreferenced |

Opening frame 16 of each confirms they are real, distinct art: grass tufts /
cracked sand plates / root-and-moss / veined mud. They are old-style (soft,
photographic grey), which is why the card read as "no art", but they satisfy
§3.4 and would work today under a tint.

So the actual art job is:

1. **Draw the Graveyard atlas** to the §3.4 contract: wet dark soil with gravel,
   sunken coffin-lid planks, bone shards, puddles and a little moss — designed in
   greyscale, seamless on all four edges of frame 16, with a designed underside
   for frame 1. Region 5's mechanic (zombies rise from graves) means the **frame
   1 isolated tile** gets seen more than usual: it is the lip of an open grave.
2. **Optionally refresh the four existing atlases.** They are the correct format
   but they are the oldest art in the game and read softer than the restyled
   characters. That is a taste call for rayu; if it is a yes, it is 5 × 17 frames
   and should be one pass so the five biomes stay consistent with each other.
3. **Props per biome** (small, high-value, and mostly missing):
   * *Swamp:* reeds, a half-sunk dead tree, lily clumps, a protruding ribcage.
   * *Desert:* a leaning gantry leg, a dead conveyor roller, a half-buried
     barrel, heat-shimmer is code, not art.
   * *Jungle:* root arches, hanging vines, a broken flagstone, an overgrown
     statue.
   * *Graveyard:* **redraw the tombstones** — `spr_graves` is four flat grey
     pre-restyle stones (64×64) used as the spawn decoration; region 5 needs
     proper headstones, a crypt face and a leaning cross in the house style.
   * *Blood Fields:* the fence (`bck_fence`) and gore strip
     (`bck_debree_blood`) already exist; what is missing is red meadow grass and
     a quarantine-fence variant.

**Palette proposals** (the atlases are grey; these are the *tints*, i.e. the
colour pairs the code should merge per row). Pick or amend before the wiring
card is done:

| Biome | dark band | light band | accent |
| --- | --- | --- | --- |
| Swamp | `#3B4630` | `#6E7A45` | sick yellow-green `#9CAE52` |
| Desert | `#8A7350` | `#D6C39A` | oxide `#A8622F` |
| Jungle | `#233A26` | `#4F6B34` | orchid `#C86FA8` |
| Graveyard | `#3A3F49` | `#767C74` | candle `#D9B36A` |
| Blood Fields | `#4A2A28` | `#8A3B34` | bone `#D8CDBB` |

**What is NOT an art job, but is missing.** `GameLevelData` carries a `biome`,
and **nothing reads it to choose an atlas**: `scr_main_startup` hard-codes
thick → dirt → sand → grass by load row. Until that mapping exists, a finished
Graveyard atlas changes nothing on screen. That is now on the board as
`biome-tileset-wiring` (cline, code) precisely so the art is not handed over
into a void.

**Acceptance.** In a region 5 stage, the ground under the play field is
graveyard tiles, the top-soil cap is unchanged, and the tile edges do not seam.
Then the same for 2, 3, 4 and 6 once the wiring lands.

---

### 4.4 `art-garden-book` — the icon set for every meta screen

**What the game does today.** The Garden Book, the world map and the Deploy
screen are drawn from **flat rectangles and text** in `scr_meta_screen`. The
handful of sprites they touch are `spr_button` and `spr_title_image`; the tower
wall draws actual tower sprites. There are **no currency icons, no tree nodes,
no candy icons, no medals** — the card is asking for a whole visual vocabulary,
not a replacement set.

**How it is laid out** (GUI 960×540), so the art sizes itself to these slots:

* title at the top centre, currency line at (80, 24) — icons here are **24×24**;
* clover node rows at x=80, y=160, **430×56** each, 12 px apart — node icons
  **48×48**;
* seed-shop tower wall at (600, 160), **124×124 cells × 3 columns** — uses the
  tower sprites already;
* one primary button per screen — the existing `spr_button` is fine.

**The set to draw.** Names and counts are facts from `economy.md` / `goal.md`;
the visual one-liners are proposals.

**1. Currencies — four icons at 24×24** (they appear side by side in one line
and must not be confusable):

| Currency | Idea |
| --- | --- |
| 🌱 Seeds | a single sprouting seed, green, two leaves — the friendly one |
| ☘️ Clovers | a four-leaf clover, brighter green, distinct from Seeds by leaf count |
| 🩸 Blood Shards | a jagged red crystal droplet with a hard highlight |
| 🍬 Candy | a wrapped bonbon, pink/cream — the only round sweet shape |

**2. Clover trees — four branch emblems at 48×48**, one per branch, plus a
generic node pip used for the ten nodes in each: *Vitality* (a heart-shaped
leaf), *Offense* (a thorn / rose thorn), *Growth* (a two-leaf sprout with a
coin), *Harvest* (a coin with a leaf through it). Nodes 1–5 are the "obvious"
half and 6–10 the "special" half, so the pip should be drawable in a **bronze**
(ranks 0–5) and **gold** (6–10) variant — two frames, not ten icons.

**3. Mastery — five nodes at 48×48** (Garden Mastery I–V): a gate that opens
wider with each tier, or the same daisy with 1–5 rings of petals. Must read as
"the cap went up", so an ascending visual is more use than five decorative
badges.

**4. Blood tree — five nodes at 48×48**, one per named tier: Blood Magnet
(horseshoe magnet with a drop), Hemorrhagic Harvest (a sickle), Crimson Appetite
(an open maw), Blood Moon (a moon with a bite out of it), Crimson Garden (a red
flower on a black stem).

**5. Candy — eight icons at 64×64**, one per recipe, distinct by silhouette:

| Candy | Idea |
| --- | --- |
| Red Licorice | a twisted red rope, both ends frayed |
| Jawbreaker | a layered sphere, one layer chipped to show the rings |
| Gummy Worm | a segmented worm, one end lifted |
| Sour Drop | a lemon drop with a puckered face |
| Fireball Candy | a glowing orb with a flame curl and a cinnamon-red core |
| Frosted Flake | a six-point snowflake candy, icy blue |
| Blood Bonbon | a dark chocolate dome with a red drip and a bite |
| Everlasting Gob | a swirled lollipop with a tiny clock face |

**6. Badges — seven medals at 64×64** plus **one empty/locked medal**. The save
stores one boolean per (region, stage, badge), so these seven are reused across
all 60 stages — this is the "badge sheet": seven frames, not sixty icons.

| Badge | Medal idea |
| --- | --- |
| Untouched | a shield with a heart, no cracks |
| Frugal | a coin with a slash through it |
| Botanist | four different leaves fanned |
| Purist | a single flower alone on the medal |
| Exterminator | a boot print with a cross through it |
| Speed Grower | a clock with a wing |
| Brutalist | a cracked skull |

**7. Optional, low priority:** six tab icons for the Garden Book navigation
(trees, shop, blood tree, candy, badges, back), a 9-slice panel frame, and a
960×540 pressed-flower page background. **Do not draw these first** — the tabs
are currently text and the panels are 85 % alpha rectangles that read fine.

**Acceptance.** Every icon is legible at its slot size in greyscale (the UI is
colour-plus-text), no two share a silhouette, and nothing in the art contains
text the code will also draw.

---

### 4.5 `art-level-complete` — one banner, authored at the size it is seen

**What the game does today.** `spr_level_complete` is a 200×100 placeholder
containing thin outlined `LEVEL COMPLETE` lettering (165×62 of art), blown up
until its art is 60 % of the 540 px port — i.e. ~324 px tall, a 5× upscale of a
thin line. It reads as a placeholder because it is one.

**Draw this.** A hand-lettered, cartoon banner that reads instantly through a
fade-out:

* **"LEVEL COMPLETE"** in the game's chunky lettering — thick dark outline,
  cream/ivory fill, a warm gold highlight band across the top third, a deep
  green drop shadow. The lettering is the subject; it may curve slightly.
* A **daisy growing through the lettering** (stem behind the `L`, one flower
  head breaking above the word), and two or three vines/leaves holding the
  letters together. This is the visual rhyme with the title screen and the final
  boss.
* **A few petals blowing off to one side**, which gives the composition
  movement and stops it reading as a sign.
* Background: **transparent**. The banner sits over live gameplay; a plate or
  panel behind it would fight the fade.

**Do not** use thin gold filigree, small text, or a busy background: it is
scaled 80 %→100 % over three seconds and fades out in a quarter second, and all
of that detail dies in the fade.

**Spec:** canvas 680×360, art bbox **648×324**, origin **middle-centre**,
`bboxMode` automatic, no animation (§3.6).

**Acceptance.** On a stage clear, the banner appears centred, the art is 324 px
tall, the lettering is still cropped/faded cleanly at 80 %, and there is no
visible upscale blur.

---

### 4.6 `portrait-draw-fit` — a layout bug first, an art job second

**What is wrong.** `obj_textbox/Create_0` sets the picture slot to **64×64**
(`p_pos = 2, 16, 64, 64`) inside a **400×150** box, and `Draw_64` stretches the
whole portrait into it. The portraits are 314×314 with a **14 px rusted-gold
frame**, so at 64 px the frame eats the face. The level-complete banner already
demonstrates the right pattern: measure the **art bbox**, not the canvas.

**None of the fixes strictly need new drawing:**

| Option | What changes | Art needed |
| --- | --- | --- |
| A. Fit the art bbox | code measures `sprite_get_bbox_*` and fits that into the slot | none — but the frame is still in the bbox, so it only helps a little |
| B. Bigger slot | `p_pos` 96×96, text at `t_xf = 2+96+16 = 114` | none; **the face gets 50 % more pixels** |
| C. Frameless busts | new 256×256 portrait variants with no frame, head filling 85 % | one small redraw per character |
| D. Portrait panel | art for the whole 400×150 box with a built-in frame and a face window | a new asset per *style*, reused by everyone |

**Recommendation:** do **B** now (pure code, immediate) and **C** only if
portraits become a selling point — a frameless bust is the version that looks
right at 96 px, and it is five small redraws today plus one per new character.
Option D is the most art for the least benefit; a portrait panel is a second
frame style to keep consistent.

**If C is chosen**, the spec is: 256×256, transparent, head-and-shoulders,
no border, no background, the head's top at y≈10 and the chin at y≈200 — so it
composes inside any frame the code draws later.

**Acceptance.** At the size the box actually uses, the face is legible, the
gold frame is not crushing it, and the text still starts clear of the picture.

---

### 4.7 `legacy-boss-art-cleanup` — delete, do not repurpose

**No drawing.** Five sprites are in the project and referenced by no `.gml`:

| Sprite | Size / frames | What it is |
| --- | --- | --- |
| `spr_boss` | 32×32, 1 | a HUD-style boss icon |
| `spr_boss1_walk` | 117×143, 15 | purple cyclops in a flat yellow cap, green pants |
| `spr_boss1_climb` | 165×152, 15 | the same, climbing |
| `spr_boss2_walk` | 108×146, 15 | yellow clawed blob with red eyes and black spikes |
| `spr_boss2_climb` | 167×153, 15 | the same, climbing |

They are a trap: they *look* like the boss set, and they made the 2026-10-18
boss-portrait report ambiguous. They are also **pre-restyle** — flat fills, no
cel shading, no black contour — and would read as placeholders next to the
gold-framed portraits. Repurposing them for `region-bosses` would cost more
(repaint every frame to the house style) than drawing new rigs.

**Decision:** delete all five in the IDE. Keep `spr_boss` only if a HUD or map
marker is actually designed for it — and in that case it needs a caller, not
just a place in the `.yyp`.

**Acceptance.** The five no longer appear in the project, and nothing in the
game changed (they were referenced nowhere).

---

### 4.8 `art-state-origins` — no drawing; the numbers, and the rule

**What is wrong.** Each state sheet of a monster was drawn on its own canvas, so
the **y-origin** (the ground contact) differs between states. When the game
switches idle→walk→attack the body jumps:

| Creature | idle/walk y-origin | attack y-origin | jump |
| --- | --- | --- | --- |
| Grumble-Mulch | 150 | 170 | 20 px |
| Tusk-A-Lot | 151 | 173 | 22 px |
| Sub-Zero | 145 | 167 | 22 px |
| Professor-Cerebrisk | 159 | 182 | 23 px |
| Towers | — | — | 1–3 px |

On the title screen that is a ~40 px sprite dropping 20 px — it reads as a
glitch, and it is entirely in the **origin data**, not in the art.

**The fix (code, cline):** set each state sheet's y-origin to the ground contact
of its own frames, keep the x-origin, using `gm set-path` on the sprite's
`xorigin`/`yorigin` — **never by hand** (LL-009). Then verify with one body pixel
keeping the same screen y through idle→walk→attack→idle at `devMode`.

**The rule for every new drawing:** one canvas per character, feet on one row,
one origin for all states (§3.2). A drawing that puts each state on its own
canvas recreates this bug by hand.

**Note on redrawing:** if a state sheet is ever redrawn, align the feet to the
existing walk sheet's ground row rather than to the canvas bottom; that is how
the origin fix stays fixed.

---

### 4.9 Towers — two on borrowed art now, two with no design yet, and Belladonna

**Belladonna Blitz needs no art.** `spr_bella_{idle,attack,return}_192x` are in
the repo (5 / 8 / 7 frames, 192×192) and are real belladonna art — purple bell
flowers, a crouch attack, a return. `tower-belladonna` is a **code** card: add
the trio to `scr_tower_roster` as slot 12. The optional Oct-6 45-frame source is
polish, not a dependency (LL-030: frame count is not timing).

#### In the game now, on someone else's art: **Cannon Tulip** and **Meat Bulb**

`scr_tower_roster` says it plainly — both borrow the old `spr_t3_*` / `spr_t4_*`
trios "until roadmap 1.11 draws `spr_t5_*` / `spr_t6_*`". Roadmap 1.11 is
**NOT done**, so two of the six towers in the vertical slice are drawn as
different towers. This is the cheapest visible art win in the project: both
towers already exist, are already priced, already have stats, and only lack a
face.

* **Cannon Tulip** (200 damage, short range, slowest fire, small blast): a tulip
  whose bloom *is* the barrel. A thick green stem as the carriage, two leaves
  folded back as trail legs, iron banding around the flower head, a soot-stained
  muzzle where the petals part, and a bud-shell visible in the throat between
  shots. Palette: hot red-orange petals, deep green stem, gunmetal and brass.
  The silhouette is **a cannon first, a flower second** — that is the joke.
* **Meat Bulb** (90 damage, long range, fast, single target): a pale fleshy bulb
  with a mouth instead of a flower, rows of blunt teeth, a long tongue that
  snaps out on the attack, and a papery skin peeling at the base. It is the
  long-range sniper of the starters, so its eye-line must point forward and its
  head must be the highest point of the silhouette. Palette: bone cream, raw
  pink, dried-blood red; the ugliest plant in the garden, deliberately.

Spec: three states each (`idle` / `attack` / `return`), 192×192, origin (96,157),
5–9 frames per state, following §3.1. Names `spr_t5_*` / `spr_t6_*` as roadmap
1.11 says, or `spr_cannon_tulip_*` / `spr_meat_bulb_*` if the roster is renamed —
decide once, because the roster entry has to match.

#### Not built yet, no design: **Kaboom Kalanchoe** and **Money Marigold**

Roadmap 5.5 owes six unlockables and four already have finished trios (Chillip,
Thornamental, Bindweed, Belladonna). These two are provisional briefs so the
design cards have something concrete to accept or change:

* **Kaboom Kalanchoe** (slot 10, AoE + burn): a squat kalanchoe with thick
  scalloped leaves and a crown of scarlet "grenade" buds fused into one flower
  head; a lit stamen fuse; the attack lobs a bud that blooms into fire, the
  return shows it regrowing. Palette: succulent green, ember orange, charcoal.
  The silhouette must say *round, heavy, about to burst*.
* **Money Marigold** (slot 11, in-run economy): a marigold whose petals are gold
  coins, with a merchant's scale on one leaf and a small ledger leaf; the attack
  flicks a coin at the path, the idle jingles. Palette: marigold orange, brass
  gold, deep green. It is a support tower, so it should look **prosperous, not
  aggressive** — the only tower smiling.

**Two art questions already on the board, neither needing a redraw:**

* **Pina Collider is ~30 % smaller than its peers.** Either intentional (it is
  the cheap AoE) or its art should be scaled up. `draw_scale` is frozen at 0.5
  for the level look, so "scale it up" means redrawing the trio larger on the
  192 canvas, not changing the code.
* **`tower-level-palette`** (levels 6–10 ring colours) is a design card, but it
  constrains tower art: every trio needs a clean closed outline for the ring to
  trace. Check a new trio by drawing a 3 px outline around it and looking at it
  at 96 px.

---

## 5. Delivery checklist (the part that makes it "done")

- [ ] The sprite is imported **in the IDE** (never by editing `.yy`), with the
      canvas, origin and `bboxMode` from §3.
- [ ] `gm art check` passes on it (§3.0) — hard alpha, a black rim, and a layer
      copy that matches its root. A drop that fails this looks soft in game even
      though it looks fine in the sprite editor.
- [ ] A `.gml` **names it** — roster, spawn table, atlas mapping, UI draw call.
      A sprite nothing references is not content (LL-023).
- [ ] It is visible in the game at the scale in §2, not only in the IDE preview.
- [ ] The feet/ground contact is identical across every state (§3.2, §4.8).
- [ ] Terrain atlases are greyscale, 17 frames, seamless on frame 16, with frame
      0 empty (§3.4).
- [ ] No text baked into art that the code also draws.
- [ ] The board card is updated with the sprite names, and any follow-on code
      work has its own card (`biome-tileset-wiring` exists for the terrain one).

---

## 6. Open questions for rayu

1. **Which of these cards are yours?** (`art-track-ownership`) The document
   splits cleanly into drawing jobs — bosses, zombies, graveyard atlas, UI
   icons, banner — and non-drawing jobs — origins, portrait fit, legacy cleanup,
   biome wiring.
2. **The sixth zombie.** Is it region 1's "Newly Turned", or the Blood Fields
   elite ("The Stitched")? The card says six; the regions after region 1 give
   five.
3. **Are the four existing biome atlases good enough?** They are the correct
   format and real art, but old-style. Refreshing all five is 85 frames and
   should be one pass.
4. **Pina's size** — intentional, or a redraw?
5. **Boss and zombie names** in §4.1/§4.2 are proposals; settle them before the
   portraits, because the name is what the popup prints.
6. **Tower sprite names for the slice trios** — `spr_t5_*` / `spr_t6_*` as
   roadmap 1.11 says, or descriptive `spr_cannon_tulip_*` /
   `spr_meat_bulb_*`. The roster entry has to match whichever is chosen.

---

## 7. Where the facts came from

* Canvas sizes, frame counts and origins: the sprite `.yy` files, read with
  `gm.yy.load` (not from memory).
* Draw scales, tints, atlas bitmask and banner maths: `scr_buildTiles`,
  `test_tile`, `set_bitmask`, `scr_main_startup`, `Sprite_Layer_Manager`,
  `scr_level_complete_draw`, `scr_meta_screen`, `scr_tower_roster`.
* Roster, names and counts: `scr_setupSpawning`, `scr_badges`,
  `scr_clover_tree`, `region_data`, `goal.md` §25/§27.4/§28.1, `economy.md`
  §3/§5.2/§6, `roadmap.md` §9.1.
* Region mood and palette direction: the region briefs in
  `notes/Music-Generation/Music-Generation.md`, which describe the same places
  in sound.
