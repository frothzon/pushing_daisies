# Pushing Daisies — music brief

The soundtrack brief: **one entry for the title screen and one per region**,
written to be pasted into a music generator. Each entry says what the track has
to *be*, then gives the prompt text.

Everything is **early Nintendo 64** in voice — low-poly, heavily compressed 90s
sample libraries, and the harmonic language of Grant Kirkhope's darker levels
(*Banjo-Kazooie's* Mad Monster Mansion or Clanker's Cavern, *Donkey Kong 64's*
Creepy Castle):

* **Soundfont Character:** Low-poly, heavily compressed 90s sample libraries (detuned music boxes, hollow marimbas/xylophones, muted tubas, pizzicato strings, mournful woodwinds, eerie accordions, compressed choirs).
* **Harmonic Palette:** Tritone intervals, diminished chords, minor-key melodies, unresolved dissonance, and slow, lingering chord progressions.
* **Acoustic Space:** Modest polyphony, spacious hardware echo/reverb, and organic woodwind/percussion textures rather than harsh chiptune synth leads.

---

## How the tracks are wired in

The region of the stage the player deployed to picks the track (see
`scripts/music_data/music_data.gml` — the table there and this one must agree).

| Region | Biome | Track | BPM | Asset | Length | `loop_in` |
| --- | --- | --- | --- | --- | --- | --- |
| — | **Title screen** | *Pushing Daisies* | 68 | `mus_title` | 2:57 | 0 |
| 1 | Grass | *Wilted Sprouts* | 82 | `mus_world1` | 2:44 | 0 |
| 2 | Swamp | *Mires of the Undead* | 72 | `mus_world2` | 2:54 | 0 |
| 3 | Desert | *Rust in the Sun* | 88 | `mus_world3` | 2:54 | 0 |
| 4 | Jungle | *Vines Take the Ruins* | 78 | `mus_world4` | 2:58 | 0 |
| 5 | Graveyard | *Toll for the Nameless* | 70 | `mus_world5` | 2:54 | 0 |
| 6 | Blood Fields | *Where the Garden Ends* | 108 | `mus_world6` | 2:58 | 0 |

All seven tracks exist and are imported, one per region, in region order.
The BPM column is the brief's, and it was checked against the FILES rather
than assumed: estimating each track's tempo from its audio puts every one of
them within a couple of BPM of its brief, in file order (`mus_title` 68,
`mus_world1` 83, `mus_world2` 74, `mus_world4` 78, `mus_world5` 69). That is
what says `mus_worldN` really is region N - which is not something the file
name alone tells you.

### Looping

Every track plays **looped** for as long as its stage lasts. `loop_in` is the
**chorus start in seconds**: the track plays its intro once, then loops from
there to the end of the file for as long as the stage runs. That is the
"Intro & Outro" shape in the GameMaker *Audio Loop Points* manual, and it is
applied on the audio thread (`audio_sound_loop_start` / `audio_sound_loop_end`),
which is the only accurate way to loop a section of a track.

* `loop_in` of **0** means "loop the whole track".
* Give the number in **seconds**, or give a bar number and it is converted with
  `time_bpm_to_seconds(BPM) x beats_per_bar x bars`.
* The chorus is the right loop because it is usually the fullest, most
  recognisable section — so a stage's music should be built so the **chorus can
  follow itself**: end it on the same harmony it begins on, at the same energy,
  so the join cannot be heard.

---
### **Title Screen**

* **Track Title:** *Pushing Daisies*
* **BPM:** 68 BPM
* **Genre:** Early N64 Title Theme / Melancholic Signature Piece
* **Visual & Gameplay Context:** The fade-in on a dead suburban lawn: one daisy pushing up through cracked concrete, the game's name in the corner, the menu waiting. This is the melody the whole soundtrack quotes, and the first thing a player hears.
* **Instrumentation:** A lone detuned N64 music box carrying the daisy melody, answered a bar later by a mournful cello; low bassoon drone, sparse hollow marimba, a distant low-poly choir entering only in the last third, and one unexpected major-lift chord that keeps it from being hopeless.
* **Loop:** the melody statement is the chorus — loop from the second statement onwards, so the title screen never has to stop to breathe.

#### **Music Generator Prompt**

> *"A slow, brooding and melancholic early Nintendo 64 (N64) style title-screen theme at 68 BPM. A lone detuned N64 music box plays a simple, almost childlike melody over a low bassoon drone and sparse hollow marimba, answered by a mournful cello; a distant low-poly choir enters in the final section. Nostalgic, desolate, post-apocalyptic 90s platformer title music built with compressed N64 soundfonts and spacious hardware reverb, with one unexpected major-key lift."*

---

### **Region 1: Grass (Overgrown Suburban Ruins)**

* **Track Title:** *Wilted Sprouts*
* **BPM:** 82 BPM
* **Genre:** Early N64 Melancholic Platformer / Dark Post-Apocalyptic VGM
* **Visual & Gameplay Context:** Overgrown dead lawns, crumbling suburban fences, and rotting houses under a gray sky. A sombre, eerie tutorial area that establishes a desolate world.
* **Instrumentation:** Detuned N64 music box, sparse hollow marimba, low bassoon drone, soft pizzicato cellos, mournful pan flute lead, and quiet metallic clinks.
* **Loop:** whole track for now — the chorus start is not set yet.

#### **Music Generator Prompt**

> *"A brooding and melancholic early Nintendo 64 (N64) style video game track at 82 BPM. Features a detuned N64 music box lead melody, hollow marimba counterpoints, mournful woodwind phrases, low bassoon drones, and sparse pizzicato strings. Eerie, atmospheric, dark 90s platformer music for a post-apocalyptic zombie tutorial stage, built with compressed N64 soundfonts and spacious hardware reverb."*

---

### **Region 2: Swamp (Toxic Stagnation)**

* **Track Title:** *Mires of the Undead*
* **BPM:** 72 BPM
* **Genre:** Early N64 Gloomy RPG / Cavern Soundscape
* **Visual & Gameplay Context:** Stagnant murky waters, submerged skeletal remains, thick fog, and sluggish zombie hazards wading through mud.
* **Instrumentation:** Low compressed N64 tuba, pitch-bent echoing brass, eerie accordion pads, hollow bone-like xylophone, slow dripping water percussion, and dark cello pads.
* **Loop:** whole track for now — the chorus start is not set yet.

#### **Music Generator Prompt**

> *"A sombre, eerie, and low-tempo N64 video game background track at 72 BPM. Inspired by dark 90s platformer swamp stages using compressed N64 soundfont instruments. Features a low tuba bassline, pitch-bent echoing brass, weeping accordion pads, hollow bone xylophones, and slow sloshing percussion. Brooding, desolate, and haunting atmosphere for a post-apocalyptic zombie swamp."*

---

### **Region 3: Desert (Bleached Ironworks)**

* **Track Title:** *Rust in the Sun*
* **BPM:** 88 BPM
* **Genre:** Early N64 Sun-Bleached Wasteland / Spaghetti-Western VGM
* **Visual & Gameplay Context:** A dried-out industrial works half-buried in sand: skeletal gantries, dead conveyor belts, heat shimmer, and a sky with no shade in it. The region's threat is exposure — long sightlines, little cover, and zombies that come at you across open ground.
* **Instrumentation:** Dry hollow marimba and kalimba, sun-bleached detuned upright piano, a low tuba pulse like a compressor that will not start, gasping low woodwind, sand-shaker and wooden percussion, and a high lonely whistle over a wind drone with a tritone held underneath the melody.
* **Loop:** the chorus should be the full ensemble — loop it from the first statement onwards.

#### **Music Generator Prompt**

> *"A dry, brooding and melancholic early Nintendo 64 (N64) style desert wasteland track at 88 BPM. Uses compressed 90s soundfonts: hollow marimba and kalimba, a sun-bleached detuned upright piano, low muted tuba pulse, gasping low woodwind, sand-shaker and wooden percussion, and a high lonely whistle over a wind drone. Sparse, desolate, post-apocalyptic industrial-ruins-in-the-desert atmosphere with a tritone held under the melody and spacious N64 hardware echo."*

---
### **Region 4: Jungle (Strangling Canopy)**

* **Track Title:** *Vines Take the Ruins*
* **BPM:** 78 BPM
* **Genre:** Early N64 Overgrown Temple / Humid Cavern VGM
* **Visual & Gameplay Context:** A suburb that the jungle has finished eating: roots through roof tiles, standing water, filtered green light, and things moving where the canopy is too thick to see. Damp, close and claustrophobic — the opposite of the Desert's open ground.
* **Instrumentation:** Insect-like ratchet and shaker percussion, hollow log drums, breathy pan pipes and a low wooden flute, detuned music box picking out a half-remembered children's tune, a buzzing reedy drone, and very sparse bird-call samples used as counter-melody.
* **Loop:** the chorus is the percussion-led section — loop from there, with the log drums carrying the join.

#### **Music Generator Prompt**

> *"A humid, brooding and melancholic early Nintendo 64 (N64) style jungle temple track at 78 BPM. Uses compressed 90s soundfont instruments: insect-ratchet shakers, hollow log drums, breathy pan pipes, a low wooden flute, a detuned music box playing a half-remembered melody, a buzzing reedy drone and sparse distant bird calls. Close, damp, overgrown post-apocalyptic atmosphere, claustrophobic rather than triumphant, with 64-bit hardware reverb."*

---

### **Region 5: Graveyard (The Digested Past)**

* **Track Title:** *Toll for the Nameless*
* **BPM:** 70 BPM
* **Genre:** Early N64 Requiem / Crypt Soundscape
* **Visual & Gameplay Context:** Rows of headstones sinking into wet ground, collapsed crypts, open graves the zombies have come up out of, and a bell that no longer has a tower. The slowest and most mournful region — the one where the game stops pretending the world can be saved.
* **Instrumentation:** A tolling low bell on the downbeat, bone-xylophone, pizzicato cellos, a single mournful oboe line, ghostly compressed low-poly choir, sparse grave-dirt percussion, and long organ pedal notes holding under everything.
* **Loop:** the chorus is the bell-and-choir section — loop from the first toll of that section.

#### **Music Generator Prompt**

> *"A slow, grieving and melancholic early Nintendo 64 (N64) style graveyard track at 70 BPM. Uses compressed 90s soundfonts: a tolling low bell, bone-xylophone, pizzicato cellos, a solitary mournful oboe, a ghostly compressed low-poly choir and long pipe-organ pedals, over sparse grave-dirt percussion. Funeral-procession post-apocalyptic atmosphere, minor-key and unresolved, with spacious 64-bit hardware echo."*

---

### **Region 6: Blood Fields (Slaughterhouse Meadow)**

* **Track Title:** *Where the Garden Ends*
* **BPM:** 108 BPM
* **Genre:** Early N64 Tragic Final Region / Dark Action
* **Visual & Gameplay Context:** The last region: a meadow gone red, the quarantine fence, and the thing the whole game has been walking towards. Fast and loud, but tragic rather than triumphant — this is the region the boss waves and the final stage live in, and the music has to carry both the fight and the grief.
* **Instrumentation:** Compressed N64 pipe organ, weeping low cello section, eerie low-poly vocal choir, ominous timpani rolls, tritone woodwind stabs, and a distant snare cadence that never quite resolves into a march.
* **Loop:** the chorus is the organ-and-choir climax — loop from there, so the fight can run as long as it needs to.

#### **Music Generator Prompt**

> *"A dark, tragic and brooding early Nintendo 64 (N64) style final-region track at 108 BPM. Uses compressed 90s soundfonts: solemn pipe organ, a weeping low cello section, eerie low-poly vocal choir, heavy timpani rolls, tritone woodwind stabs and a distant snare cadence that never resolves into a march. Melancholic yet tense post-apocalyptic zombie endgame music, dramatic minor-key harmonies, tragic rather than triumphant, with spacious N64 hardware echo."*

---

### Key Prompt Keywords Used for the Generator:

* **Style:** `Early Nintendo 64`, `N64 Soundfont`, `90s Platformer VGM`
* **Vibe:** `Brooding`, `Melancholic`, `Desolate`, `Eerie`, `Sombre`, `Tragic`
* **Instrumentation:** `Detuned music box`, `Hollow marimba`, `Low bassoon`, `Compressed choir`, `Pizzicato strings`, `Pipe organ`, `Bone xylophone`, `Log drums`, `Sand shaker`