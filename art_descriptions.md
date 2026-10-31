# Art descriptions

Draw-ready briefs and technical contracts for the project's art. Measurements
were taken from the repository on **2026-10-30**. The implemented names and
current ownership are recorded without proposal labels; the board tracks
completion and remaining runtime review. Art is complete only when the game uses
it; §5 is the integration checklist.

The 2026-10-21 drop delivered the level-complete banner, 18 biome props, 36
meta icons, four tower trios, and eight shot effects. Two Candy icons were
added 2026-10-30, bringing the meta icon set to 38. The Graveyard atlas was
added 2026-10-30. The boss/zombie rigs arrived in later drops. Naming and
unreferenced-sprite cleanup is tracked by `art-cleanup-unreferenced`.

Since **2026-10-28** the monster rigs are primarily **Spriter SCML** (the
SCML-custom import, `scripts/scr_scml_spriter_interface_system`): the
`zombies` collection carries 15 entities with four clips each
(walk/idle/attack/die), played through `scripts/scr_scml_rig` with pose
evaluation at 30hz. The four-slot sheets remain the automatic, loudly-logged
fallback for any creature without an entity, and the portraits still come
from the bank rows. Timing is the game's, not the art's: `ZOMB_CYCLE_SECS`
and `ZOMB_DIE_SECS` (`scr_zomb_art`) stretch each clip, whatever it was
authored as. Each rig also carries a **per-creature scale fix**
(`zomb_scml_scale_fix`, 2026-10-29): the rig's native posed height is
measured against its original walk sheet's art bbox and normalized to it,
so on-screen sizes match the sheet era — the Spriter rigs were authored
2–3× larger, and per-entity-varying, so the fix is measured per creature,
never hand-tuned. The title-screen zombie is the rigged Grumble-Mulch
(`obj_titleZomb`), at its sheet-era ~156px.

---

## 0. Open art jobs

| Card | Status | What remains | Drawing? |
| --- | --- | --- | --- |
| `region-bosses` | **done** | all 4 new boss rigs and portraits are wired; the six-boss roster includes the two original bosses and reuses Sub-Zero in Region 2 | — |
| `region-zombies` | **done** | all 6 new walker rigs and all 6 portraits are wired, including Sandblasted and Shroud. The attack slot remains decorative in v1 by decision (`zomb-attack-at-gate`, §3.2) | — |
| `tower-slice-trios` | **done** | all 12 roster towers use dedicated idle / attack / return trios, and all eight shot-effect sprites are wired (§4.9) | — |
| `art-biome-tiles` | **review** | the Graveyard atlas is integrated; runtime visual review remains. Keep the four existing regional atlases for v1 (§4.3) | no |
| `art-garden-book` | **done** | all 38 meta-screen icons are in the project; screen placement is covered by the UI cards | — |
| `art-level-complete` | **done** | the banner is integrated and drawn at 1:1 (§4.5) | — |
| `art-state-origins` | **review** | **no drawing** — visually check the accepted ≤5 px ground-contact differences (§4.8) | no |
| `portrait-draw-fit` | **review** | **no drawing** — fitted preview-card layout is implemented; check portrait readability in GameMaker (§4.6) | no |
| `art-sandblasted-portrait` | **review** | both missing portraits are now generated and wired; check them in the Up Next preview | no |
| `legacy-boss-art-cleanup` | **done** | all five unreferenced pre-restyle boss sprites were removed; no code behavior depended on them (§4.7) | — |

The three formerly unwired unlockables, Kaboom Kalanchoe, Money Marigold, and
Thornamental, now have roster entries and use their finished trios. Kaboom's
bud, fire burst, and burn marker are wired; Marigold's income sparkle plays
when a wave dividend is paid. All tower art assets are now integrated; the
remaining review is in-game readability and balance, not missing sprites.

---

## 1. What already exists (do not redraw these)

Verified by opening the files, not by listing names:

* **Tower trios, 192×192, 5–9 frames per state** — all 12 roster towers have
  dedicated idle / attack / return art, including Cannon Tulip, Meat Bulb,
  Thornamental, Kaboom Kalanchoe, and Money Marigold. The support Marigold uses
  its idle trio and income sparkle; its attack animation is not a combat action.
* **Monster rigs, 4 states × 16 frames** — Grumble-Mulch, Dome-Alone,
  Professor-Cerebrisk, plus the two bosses Tusk-A-Lot and Sub-Zero. Legacy
  sheet canvases differ by state; that alone is not a ground shift. The current
  primary rigs are SCML with a shared character root; the corrected pose audit
  is in §4.8.
* **Portraits, 314×314** — all fifteen walkers and bosses have a distinct
  portrait: three legacy walkers, two legacy bosses, six restyled walkers and
  four new bosses. Rusted gold frame, painterly rim light, vignetted background.
* **Terrain atlases, 128×128 × 17 frames, greyscale** — grass, dirt, sand,
  thick, **swamp, desert, jungle, graveyard, blood**. The five regional atlases
  are distinct and in the format the game uses. See §4.3.
* **Props** — `bck_fence` (128×128), `bck_house` (128×128), `bck_debree_blood`
  (288×32 gore strip, used by every zombie death), four `spr_headstone_*`
  variants (64×64), `spr_gravestone_cross` (128×128), `spr_graveyard_crypt`
  (256×256), `bck_water` + `bck_waves` (water shader), and `spr_tower_grass`
  (48×48).
* **UI** — `spr_icon` (64×64, 2 frames), `spr_button` (36×36), `spr_coin`,
  `spr_heart`, `spr_flower`, `spr_timer`, and `bck_level_complete_banner`
  (680×360). Everything else in the Garden Book and world map is **rectangles
  and text**.

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

The older sheet-era measurements compared `yorigin` values across differently
sized canvases and overstated the pose jump (§4.8). **New sheet rigs must still
share one canvas and ground row.** For each new character:

| Field | Value |
| --- | --- |
| Canvas | **one size for all states** — recommended 240×200 |
| Origin | **fixed** at (120, 190) for every state and every frame |
| Feet row | the same y in every state sheet; nothing may move the ground contact |
| States | `idle`, `walk`, `attack`, `die` — 16 frames each, existing rig convention |
| Facing | right; the game mirrors with `image_xscale < 0` |
| Margins | 10 px minimum around the silhouette, so the black outline is never clipped |

**The v1 state contract** is settled: monsters use `walk` while moving, `idle`
while blocked, and `die` when killed. The SCML rig plays those named clips; the
sheet fallback maps them to `sprite_array[0]`, `[1]`, and `[3]`.
The attack clip is decorative and remains unplayed by design
(`zomb-attack-at-gate`, closed 2026-10-30): monsters walk to the gate and cause
a leak; they do not fight it. Dedicated `idle`/`die` sheets are used in-game,
while the walk cycle remains mandatory (§4.2).

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

### 4.1 `region-bosses` — six bosses: four new and two established

**Current roster.** The game has six bosses: the two original bosses below and
four new bosses for Regions 3–6. Region 2 reuses Sub-Zero:

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

**Frame plan (per new boss):** 16 frames each for walk, idle, attack, and die.
The v1 game plays walk / idle / die; attack art is loaded but remains unused by
the settled `zomb-attack-at-gate` decision. Sheet fallback states share one
**240×200 canvas and origin (120, 190)**, the §3.2 ground-contact contract.

#### Region 3 — Desert (Bleached Ironworks): **"Foreman Rustlung"**

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

#### Region 4 — Jungle (Vines Take the Ruins): **"The Orchid Widow"**

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

#### Region 5 — Graveyard (The Digested Past): **"The Bellringer"**

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

#### Region 6 — Blood Fields (Slaughterhouse Meadow): **"The Gardener"**

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

**Acceptance.** Each new boss is visible in its region's stage 10 and its
portrait appears in the "Up Next…" popup. The v1 idle / walk / die cycle keeps
feet on one screen row (§4.8); attack art remains decorative under the settled
`zomb-attack-at-gate` decision.

---

### 4.2 `region-zombies` — six walk cycles, six portraits

**Original Region 1 baseline.** These three established monsters remain the
shared reference for the six added types below:

| Monster | Speed / life | Walk sprite | Design |
| --- | --- | --- | --- |
| **Grumble-Mulch** | 1.0 / 7 | 140×160 | the baseline: green, red flannel, wild dark-red hair, boots |
| **Dome-Alone** | 0.5 / 12 | 138×160 | the tank: oversized teal head, orange shirt, red tie, one tooth |
| **Professor-Cerebrisk** | 1.5 / 5 | 147×170 | the fast one: exposed pink brain, round glasses, lab coat |

**The frame budget.** `goal.md` §28.1 budgets 30 frames per new type. The
implemented rigs carry 16-frame walk / idle / attack / die clips plus one
portrait. V1 uses walk, idle (while blocked), and die (on a kill); the attack
clip remains decorative by the closed `zomb-attack-at-gate` decision (§3.2).

**Per-zombie frame plan:** walk 16 frames on a **240×200 canvas, origin
(120,190)**; portrait 314×314. If a state sheet is drawn, it stays on the same
canvas and origin (§3.2).

The six added types are the implemented roster, with each design showing its
region's identity rather than only wearing its colours.

#### Region 1 — the sixth slot: **"The Newly Turned"**
The roster decision is settled: **The Newly Turned** is the sixth type and
belongs to Region 1. The other five new types fill Regions 2–6, one per region.
This keeps a fresh suburbanite — polo shirt, bathrobe, one slipper, mail still
in hand — as the tutorial's small, fast "oh no, that was a person" enemy and a
reference point for the later designs.
*Palette:* clean pastels against the region's grey-green; the only bright shirt
in the game's monster set.

#### Region 2 — Swamp (Toxic Stagnation): **"The Bog Wader"**
Waist-deep in the water its region forbids towers from standing in. Only the
torso and arms show above a skirt of dripping silt, weed and bone; the ribcage
has a faint sickly glow inside it; a snapped boat oar is still gripped in one
hand. It should look **heavy** — the opposite of Dome-Alone's bob.
*Palette:* bog brown and olive with a green-yellow inner glow. *Silhouette:*
wide and low, arms trailing, weed skirt breaking the outline. *Tell:* the water
ripples stop for a beat before it lunges.
*Why it is the region's zombie:* it walks where the player cannot build.

#### Region 3 — Desert (Bleached Ironworks): **"The Sandblasted"**
A dried-out worker in shredded overalls, sand pouring from a tear in its side,
a length of rebar through one shoulder, cracked lips pulled back from perfect
teeth. Tall, thin, leaning into a wind that is no longer blowing.
*Palette:* bleached tan and bone, one oxide-orange overall strap, sand-white
highlights. *Silhouette:* tall and narrow with a long drag-chain behind.
*Tell:* it raises one hand to shield its eyes before it speeds up.
*Portrait delivered 2026-10-30:* `spr_sandblasted_portrait` (314×314).

#### Region 4 — Jungle (Vines Take the Ruins): **"The Rootbound"**
A corpse being taken apart by the jungle in real time. Roots burst out of its
chest and anchor it to the ground with every step; one arm has become a woody
branch; leaves grow where hair was; a single bright orchid sits in the hollow of
its throat.
*Palette:* wet greens and dark bark, the orchid as the one hot accent.
*Silhouette:* asymmetric, tendrils trailing, one shoulder much higher than the
other. *Tell:* the roots pull taut and it lurches.

#### Region 5 — Graveyard (The Digested Past): **"The Shroud"**
A body still wrapped in a burial shroud, dragging a collapsed headstone on a
chain. No legs are visible — it moves in a low, creeping crawl of cloth, and the
shroud is wet enough to leave a trail. It is the one zombie that must read
**while emerging from the ground at zero scale**, because region 5's mechanic is
zombies rising from graves mid-path.
*Palette:* bone-white cloth, wet slate, one warm candle-gold glow in the folds.
*Silhouette:* a low triangle of cloth with two hands out and a stone dragging
behind. *Tell:* the shroud swells before it lunges.
*Portrait delivered 2026-10-30:* `spr_shroud_portrait` (314×314).

#### Region 6 — Blood Fields (Slaughterhouse Meadow): **"The Harvester"**
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

### 4.3 `art-biome-tiles` — five regional atlases, and what "tileset" means here

**The card says "only Grass has art". That is wrong**, in the same way the
Belladonna card was wrong: the repo already contains **all five** region
atlases, in the exact format the code needs.

| Region | Atlas sprite | State |
| --- | --- | --- |
| 1 Grass | `spr_grass_128x` (+ dirt/sand/thick elevation strata) | in use |
| 2 Swamp | `spr_swamp_128x` | exists, wired and tinted |
| 3 Desert | `spr_desert_128x` | exists, wired and tinted |
| 4 Jungle | `spr_jungle_128x` | exists, wired and tinted |
| 5 Graveyard | `spr_graveyard_128x` | delivered 2026-10-30; selected and tinted; runtime review pending |
| 6 Blood Fields | `spr_blood_128x` | exists, wired and tinted |

Opening frame 16 confirms each delivered region atlas is real, distinct art: mud and reeds / cracked sand plates / root-and-moss / veined mud. They are old-style (soft, photographic grey), but satisfy §3.4 and are now selected and tinted by region.

The Graveyard atlas follows §3.4: 128×128, 17 greyscale frames, empty frame 0,
an isolated open-grave lip in frame 1, and a repeating gravel/soil tile in frame
16. Frame 16's opposite edge pixels match exactly. Runtime cropping and tinting
still need a visual check.

The remaining art call is optional:

1. **Optionally refresh the four existing atlases.** They are the correct format
   but they are the oldest art in the game and read softer than the restyled
   characters. That is a taste call for rayu; if it is a yes, it is 5 × 17 frames
   and should be one pass so the five biomes stay consistent with each other.
2. **Props are already delivered and wired.** Swamp, Desert, Jungle, Graveyard,
   and Blood Fields each have biome-specific scenery in `scr_biome_props`; the
   runtime placement and route-clear check is the separate `biome-props` card.
   This audit also found `spr_bloodfields_grass` and `spr_quarantine_fence`, so
   those are not missing assets.

**Selected terrain tint pairs (2026-10-30).** The atlases are grey; the dark
and light colours interpolate across elevation rows with `load_amount`. The
accent is reserved for future prop art and is not baked into the atlas:

| Biome | dark band | light band | accent |
| --- | --- | --- | --- |
| Swamp | `#3B4630` | `#6E7A45` | sick yellow-green `#9CAE52` |
| Desert | `#8A7350` | `#D6C39A` | oxide `#A8622F` |
| Jungle | `#233A26` | `#4F6B34` | orchid `#C86FA8` |
| Graveyard | `#3A3F49` | `#767C74` | candle `#D9B36A` |
| Blood Fields | `#4A2A28` | `#8A3B34` | bone `#D8CDBB` |

**The atlas wiring landed (2026-10-30).** `GameLevelData.biome` selects all five
regional atlases in `region_terrain_style()`; Grass keeps its existing four
elevation strata. `scr_iniTileBuilder` still draws the highest top-soil cap
from dirt, unchanged. The startup log names the stage biome, first atlas, and
fallback flag, so an atlas mismatch is visible without guessing from the
screenshot.

**Acceptance.** In regions 1-6, confirm the title `LEVEL terrain biome=...`
line names the stage biome and expected atlas, startup still ends with
`rows=12`, and all six grounds render without missing tiles. Region 5 should
show `spr_graveyard_128x fallback=0` with the Graveyard tint. The top-soil cap
stays unchanged and tile edges must not seam.

---

### 4.4 `art-garden-book` — the icon set for every meta screen

**What the game does today.** Garden Book, world map and Deploy panels still use
flat rectangles and text, while icons supply their visual vocabulary. The repo
now contains **38 meta-screen icons**: four currencies, four clover branches,
two node pips, five mastery nodes, five Blood Alchemy tiers, ten candy recipes,
and seven medals plus the locked plate. The tower wall draws the actual tower
sprites. This brief records the silhouettes and sizes those delivered assets
follow.

**How it is laid out** (GUI 960×540), so the art sizes itself to these slots:

* title at the top centre, currency line at (80, 24) — icons here are **24×24**;
* clover node rows at x=80, y=160, **430×56** each, 12 px apart — node icons
  **48×48**;
* seed-shop tower wall at (600, 160), **124×124 cells × 3 columns** — uses the
  tower sprites already;
* one primary button per screen — the existing `spr_button` is fine.

**The icon set.** Names and counts are facts from `economy.md` / `goal.md`;
the one-liners record the intended silhouette for each delivered icon.

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

**5. Candy — ten icons at 64×64**, one per recipe, distinct by silhouette:

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
| Blood Orange | a glossy orange jelly wedge with a dark-red citrus center |
| Money Honey | an amber honey-drop bonbon with a small gold coin inset |

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

### 4.5 `art-level-complete` — banner shipped

**Shipped 2026-10-21.** The 680×360 `bck_level_complete_banner` replaced the
200×100 placeholder. `scr_level_complete_draw()` fits the visible art to 60 %
of the GUI height and centers it by its art bounds. On a clear it grows from
80 % to 100 % over three seconds before the results transition. The drawing
brief is complete; runtime legibility remains on the `level-complete-banner`
review card.

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

**No drawing.** These five registered sprites had no code callers and were
removed from the project on 2026-10-30:

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

**Disposition:** all five entries were removed from the project manifest and
their sprite folders were deleted. `spr_boss` was not kept: no HUD or map
marker uses it, and a resource with no caller only makes the boss roster
ambiguous.

**Acceptance — met 2026-10-30.** The five no longer appear in the project; no
runtime behavior changed because none had a caller.

---

### 4.8 `art-state-origins` — accept the measured pose offsets; never shift the fall

**The original diagnosis was wrong.** The 2026-10-19 table compared `yorigin`
values across state sheets with different canvas sizes and called the resulting
20–23 px coordinate difference a body jump. Those values were not comparable.
LL-078 requires measuring the painted ground contact relative to that frame's
own origin.

**Corrected measurement (2026-10-24).** Across all 15 rigs and all four states,
the worst ground-contact disagreement against the walk pose is 5 art pixels.
Representative measurements (`lowest painted row - origin`, in walk / idle /
attack / die order):

| Creature | Art-relative ground contact |
| --- | --- |
| Grumble-Mulch | +7 / +4 / +3 / +3 px |
| Tusk-A-Lot | +7 / +4 / +5 / +6 px |
| Sub-Zero | +7 / +2 / +3 / +2 px |

The title-screen Grumble-Mulch changes idle→walk by 3 art pixels at the
sheet-era scale. **Decision: accept this small pose difference; do not re-origin
or redraw the states for this card.** A crouched-looking walk is a joint-pose
issue in the SCML rig, separate from this ground-contact check.

The playable rigs are now primarily SCML (`scripts/scr_scml_rig`), where the
character root is shared across clips. The four-slot sprite-sheet fallback
still uses one canvas and a fixed origin (120,190) for every state. In either
path, compare feet against the root, never canvas coordinates. `obj_mon/Draw_0`
keeps the origin on the ground line; no per-frame draw-time y correction is
allowed (LL-078).

**Never re-origin a die pose to solve a walk transition.** The fall pivots on
the origin and its first frame already stands on it (LL-078). If a future rig
exceeds the 5 px pose allowance, identify the exact creature and clip first;
correct that clip's anchor or art only after measuring its own frames.

---

### 4.9 Towers — all roster trios integrated

All 12 roster towers use dedicated 192×192 idle / attack / return trios under
the names in `scr_tower_roster()`. The unused legacy `spr_t3_*` / `spr_t4_*`
resources have been removed after confirming no runtime references. Chillip,
Bindweed, Thornamental, and Belladonna Blitz use the completed trios already in
the project.

**Kaboom Kalanchoe** (slot 10) uses `spr_kaboom_*`, launches
`spr_kalanchoe_bud_projectile`, bursts with `spr_kalanchoe_fire_burst`, and
shows `spr_kalanchoe_burn_marker` when its burn applies. The tower is AoE and
burn focused.

**Money Marigold** (slot 11) uses `spr_marigold_*` and is a passive economy
tower. It pays $1–3 per cleared wave through L5, then scales by 8% per
mastery level; `spr_marigold_income_sparkle` plays when paid. The attack trio
is retained as art, but does not imply that the passive tower damages monsters.

**V1 art decisions:** keep Pina Collider at its authored size and the shared
0.5 draw scale; its compact pineapple silhouette is distinctive, and no redraw
or per-tower scaling is planned. Check that it remains readable in the live
shop and at 32 px board-cell scale before reopening the art. The L6–L10 ring
palette is already named and implemented in `tower_levels.gml`; the runtime
contrast check is tracked separately as `tower-ring-mastery-palette`.

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

## 6. Settled choices and remaining visual review

The asset-owner assignments are recorded in `progress.json`; no ownership
answer is outstanding. The six-type split is final: Newly Turned is the Region
1 addition, followed by one added type in each of Regions 2–6. The boss and
walker names in §§4.1–4.2 are the names used by the roster and portraits, not
proposals.

For v1, keep the four existing Swamp, Desert, Jungle and Blood Fields atlases:
they meet the 128×128 / 17-frame contract and are distinct, wired terrain art.
The Graveyard atlas is the only new atlas in this pass. A coordinated refresh
can be opened later only if the in-game review finds a readability problem.

Keep Pina Collider's delivered proportions and shared tower draw scale. Its
compact shape is accepted for v1; the remaining check is whether it reads
clearly in the Garden Book and at board scale. `art-biome-tiles`,
`art-sandblasted-portrait`, `portrait-draw-fit`, and `art-state-origins` retain
their runtime visual reviews in the tracker.


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
