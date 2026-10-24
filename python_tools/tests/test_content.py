"""Content integrity: the checks GML cannot make about itself.

``scr_setupSpawning`` pairs every creature with a WALK sprite and, in a
separate statement, with a PORTRAIT sprite.  Nothing in the game can tell
whether that pair is right - the "Up Next" popup draws whatever is in the row
- so a swap, a copy-paste or a missing assignment is invisible until someone
plays and says "the boss portrait doesn't match" (LL-057).

These tests read the table the way ``gm.balance.tables`` reads the balance
numbers: from the GML itself, so the game cannot drift away from its own
check.  They assert the pairing is a BIJECTION - every creature has a portrait,
no two share one, and every named sprite exists in the project.
"""

import re
import sys
import unittest
from pathlib import Path

TESTS_DIR = Path(__file__).resolve().parent
TOOLS_DIR = TESTS_DIR.parent
REPO_ROOT = TOOLS_DIR.parent
sys.path.insert(0, str(TOOLS_DIR))


def find_project_root():
    for candidate in [REPO_ROOT, *REPO_ROOT.parents]:
        if any(candidate.glob("*.yyp")):
            return candidate
    return None


PROJECT_ROOT = find_project_root()

SPAWN_REL = "scripts/scr_setupSpawning/scr_setupSpawning.gml"
MAKE_REL = "scripts/scr_makeMonster/scr_makeMonster.gml"
LEVEL_SPAWN_REL = "scripts/scr_level_spawn/scr_level_spawn.gml"
PREVIEW_REL = "scripts/scr_wave_preview/scr_wave_preview.gml"
DEPTH_REL = "scripts/scr_setDepth/scr_setDepth.gml"
STAGE_DATA_REL = "scripts/stage_data/stage_data.gml"
CURVE_REL = "scripts/scr_curve/scr_curve.gml"
LEAK_REL = "scripts/lose_life/lose_life.gml"
MONEY_REL = "scripts/difficulty_data/difficulty_data.gml"
DAMAGE_REL = "scripts/scr_do_damage/scr_do_damage.gml"
SHOOT_REL = "scripts/scr_tower_shoot/scr_tower_shoot.gml"
PATHSPEED_REL = "scripts/scr_zomb_pathSpeed/scr_zomb_pathSpeed.gml"
MON_STEP_REL = "objects/obj_mon/Step_0.gml"
MON_CREATE_REL = "objects/obj_mon/Create_0.gml"
SPAWN_CREATE_REL = "objects/obj_spawn/Create_0.gml"
TOWER_CREATE_REL = "objects/obj_tower/Create_0.gml"
TOWER_EDIT_STEP_REL = "objects/obj_tower_edit/Step_0.gml"
EMERGE_REL = "scripts/scr_zombie_emerge/scr_zombie_emerge.gml"
ZPATH_REL = "scripts/scr_zombie_path/scr_zombie_path.gml"

PICK_REL = "scripts/scr_level_pick_spawn/scr_level_pick_spawn.gml"
WAIT_REL = "scripts/scr_level_wait/scr_level_wait.gml"
PORTRAIT_REL = "scripts/show_portrait_box/show_portrait_box.gml"
BOX_DRAW_REL = "objects/obj_textbox/Draw_64.gml"

# `spawn_mon[0] = scr_makeMonster("Grumble-Mulch",1,7,array(spr_grumble_walk),...`
#
# The fourth argument is a RIG since 2026-10-24: `array(walk, idle, attack, die)`
# for the ten restyled creatures, and still a one-element `array(spr_x)` for the
# three originals.  So the pattern captures the WHOLE argument list and the
# reader decides - a pattern that insisted on one sprite would have stopped
# matching ten rows and gone on passing the checks below with them missing
# (LL-041: a suite that cannot notice a missing row has a hole in it).
ROW_RE = re.compile(
    r'spawn_(mon|boss)\s*\[\s*(\d+)\s*\]\s*=\s*scr_makeMonster\(\s*"([^"]+)"'
    r'[^;]*?array\(([^)]*)\)',
    re.S)
# `spawn_boss[0][MON.portrait] = spr_tusk_portrait;` and the documented
# `= -1;` for a creature whose portrait art has not been drawn yet.
PORTRAIT_RE = re.compile(
    r'spawn_(mon|boss)\s*\[\s*(\d+)\s*\]\s*\[\s*MON\.portrait\s*\]\s*=\s*'
    r'(-1|spr_\w+)\s*;')

# The slots of a rig, in the order ZOMB_ANIM names them (scr_zomb_art).
RIG_SLOTS = ("walk", "idle", "attack", "die")


def _code_only(src):
    """Drop // comments, so an invariant is about CODE and not prose."""
    out = []
    for line in src.splitlines():
        cut = line.find("//")
        out.append(line if cut < 0 else line[:cut])
    return "\n".join(out)


def _rows(src):
    """{(bank, index): (name, [rig sprites])} from the spawn table."""
    out = {}
    for m in ROW_RE.finditer(src):
        sprites = [s.strip() for s in m.group(4).split(",") if s.strip()]
        out[(m.group(1), int(m.group(2)))] = (m.group(3), sprites)
    return out


def _portraits(src):
    """{(bank, index): portrait_sprite_or_-1} from the portrait assignments."""
    out = {}
    for m in PORTRAIT_RE.finditer(src):
        key = (m.group(1), int(m.group(2)))
        if key in out:
            raise AssertionError("%s[%d] has two portrait assignments"
                                 % key)
        out[key] = m.group(3)
    return out


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class SpawnRosterTests(unittest.TestCase):
    """The creature rows pair a walk sprite with a portrait (LL-057)."""

    @classmethod
    def setUpClass(cls):
        cls.src = (PROJECT_ROOT / SPAWN_REL).read_text(encoding="utf-8-sig")
        cls.rows = _rows(cls.src)
        cls.portraits = _portraits(cls.src)

    def test_the_table_was_actually_parsed(self):
        # a regex that stops matching must FAIL here, not silently pass the
        # bijection below with two empty dicts (LL-041)
        self.assertGreaterEqual(len(self.rows), 3)
        self.assertTrue(any(bank == "boss" for bank, _ in self.rows),
                        "no boss rows found in %s" % SPAWN_REL)
        self.assertTrue(any(bank == "mon" for bank, _ in self.rows))

    def test_every_creature_has_a_portrait(self):
        missing = sorted("%s[%d] %s" % (bank, idx, name)
                         for (bank, idx), (name, _) in self.rows.items()
                         if (bank, idx) not in self.portraits)
        self.assertEqual([], missing,
                         "these creatures would show NO portrait in the Up "
                         "Next popup: %s" % missing)

    def test_no_two_creatures_share_a_portrait(self):
        # the exact shape of "Tusk-A-Lot and Sub-Zero are swapped": a
        # duplicated portrait, or one assigned to the wrong row.
        seen = {}
        dupes = []
        for key, spr in sorted(self.portraits.items()):
            if spr == "-1":
                # two creatures with NO portrait art do not share a portrait:
                # that is the documented gap, pinned by its own test
                continue
            if spr in seen:
                dupes.append("%s used by %s and %s" % (spr, seen[spr], key))
            seen[spr] = key
        self.assertEqual([], dupes, "a duplicated portrait cannot be right: %s"
                         % dupes)

    def test_the_portrait_is_not_the_walk_sprite(self):
        for key, (name, sprites) in sorted(self.rows.items()):
            self.assertNotEqual(sprites[0], self.portraits.get(key),
                                "%s uses its walk sprite as its portrait" % name)

    def test_every_named_sprite_exists(self):
        for key, (name, sprites) in sorted(self.rows.items()):
            for spr in [sprites[0], self.portraits.get(key)]:
                if spr is None or spr == "-1":
                    continue
                yy = PROJECT_ROOT / "sprites" / spr / (spr + ".yy")
                self.assertTrue(yy.exists(), "%s: %s is not a sprite in the "
                                "project (%s)" % (name, spr, yy))

    def test_only_the_two_documented_creatures_have_no_portrait(self):
        """`-1` is legal, but only for a creature whose art has not landed.

        Pinned as EQUALITY, not as "at most two": a third creature quietly
        joining the list is exactly how a missing portrait ships, and a name
        staying on it after its art arrives is the same bug the other way.
        The art card is `art-sandblasted-portrait` (it covers both).
        """
        missing = sorted(name for (bank, idx), (name, _) in self.rows.items()
                         if self.portraits.get((bank, idx)) == "-1")
        self.assertEqual(["Sandblasted", "Shroud"], missing,
                         "the creature(s) with no portrait art changed - "
                         "update art-sandblasted-portrait on the board")


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class MonsterRowTests(unittest.TestCase):
    """``scr_makeMonster`` must leave no slot of a row unset (LL-057)."""

    def test_every_slot_the_enum_names_is_defaulted(self):
        src = (PROJECT_ROOT / MAKE_REL).read_text(encoding="utf-8-sig")
        for slot in ("maxLife", "debree", "portrait"):
            self.assertIn("_arr[MON.%s]" % slot, src,
                          "MON.%s is never written by %s, so a row can be "
                          "read with that slot unset" % (slot, MAKE_REL))
        self.assertIn("_arr[MON.portrait] = -1", src,
                      "a row without a portrait must say -1 (= none), not 0")


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class WavePreviewTests(unittest.TestCase):
    """The popup and the wave it names read ONE decision (LL-058).

    The failure this pins is the one a player reports as "the predicted
    monster is random": the popup named one creature and the wave sent
    another.  Each assertion here is one way that used to be possible.
    """

    def read(self, rel):
        return (PROJECT_ROOT / rel).read_text(encoding="utf-8-sig")

    def test_spawn_never_rolls_for_itself(self):
        src = _code_only(self.read(LEVEL_SPAWN_REL))
        self.assertNotIn("irandom", src,
                         "scr_level_spawn rolls a creature of its own: an "
                         "irandom there cannot be the creature the popup "
                         "named")
        self.assertIn("next_pick", src)

    def test_the_pick_is_made_once_per_wave(self):
        src = self.read(PICK_REL)
        self.assertIn("next_pick.wave == _wave", src,
                         "scr_level_pick_store has no per-wave identity "
                         "check, so anything that re-enters START or WAIT "
                         "can re-roll the creature the popup already named")
        self.assertEqual(1, src.count("function scr_level_pick_spawn"),
                         "a wave creature must be rolled in exactly one "
                         "function, or the popup and the wave can roll "
                         "separately")

    def test_the_popup_resets_the_box_instead_of_appending(self):
        src = self.read(PORTRAIT_REL)
        self.assertNotIn("array_length(_box.message)", src,
                         "show_portrait_box appends to the live box again - "
                         "the new preview then shares the box with the "
                         "previous creature")
        for pattern in (r"message_current\s*=\s*0",
                        r"message_length\s*=",
                        r"characters\s*=\s*0"):
            self.assertRegex(src, pattern,
                             "the reset path must clear the typewriter as "
                             "well, or the new line draws partly typed")

    def test_the_portrait_is_one_field_of_the_box(self):
        src = self.read(BOX_DRAW_REL)
        self.assertIn("var _portrait = portrait;", src)
        self.assertNotIn("message_portrait[", src,
                         "Draw_64 indexes a portrait by message again - "
                         "that is the popup showing another creature")


    def test_each_pick_branch_assigns_the_index(self):
        src = _code_only(self.read(PICK_REL))
        for branch in ("_index = _bosses[_slot];",
                       "_index = irandom(array_length(spawn_boss)",
                       "_index = _pool[irandom("):
            self.assertIn(branch, src,
                          "a branch rolls a creature but does not ASSIGN it "
                          "to _index, so the wave sends whatever the last "
                          "branch left behind")

    def test_the_popup_position_is_absolute(self):
        src = _code_only(self.read(PREVIEW_REL))
        self.assertNotIn("m_pos[1] +=", src,
                         "the popup shifts its own position by +=, so a "
                         "reused box walks down the screen every wave")
        self.assertIn("_box.m_pos[1] =", src)


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class DepthOrderTests(unittest.TestCase):
    """Everything on the ground sorts by the world y of its feet (LL-059).

    The bug this pins: monsters were a flat `depth = -60`, plants were
    `-60 - (y>>5)` and the gravestones were `-(y/room_height)-50`, so a
    plant ALWAYS drew in front of every monster, no monster sorted against
    another and the six gravestones shared one depth.  "Everything at one
    depth" is not sorting.
    """

    def read(self, rel):
        return _code_only((PROJECT_ROOT / rel).read_text(encoding="utf-8-sig"))

    def test_every_actor_asks_the_one_rule(self):
        for rel, call in ((MON_STEP_REL, "scr_depth_y(y)"),
                          (MON_CREATE_REL, "scr_depth_y(y)"),
                          (SPAWN_CREATE_REL, "scr_depth_y(y - 16)"),
                          (TOWER_CREATE_REL, "scr_depth_y(y)"),
                          (TOWER_EDIT_STEP_REL, "scr_depth_y(y)")):
            self.assertIn(call, self.read(rel),
                          "%s does not sort by the feet" % rel)

    def test_no_actor_pins_a_flat_depth(self):
        for rel in (EMERGE_REL, ZPATH_REL, MON_STEP_REL, MON_CREATE_REL):
            self.assertNotRegex(self.read(rel), r"depth\s*=\s*-60\b",
                                "%s pins a flat -60" % rel)
        self.assertNotIn("-60 - (y>>5)", self.read(TOWER_EDIT_STEP_REL))
        import re
        self.assertIsNone(re.search(r"\bdepth\s*=", self.read(PATHSPEED_REL)),
                          "scr_zomb_pathSpeed writes a depth again - it was a "
                          "fourth formula, view-relative, and dead")

    def test_the_gravestones_sort_by_their_own_base(self):
        src = self.read(SPAWN_CREATE_REL)
        self.assertNotIn("room_height", src,
                         "the gravestones are back on a fraction of the room, "
                         "which is one flat value for all of them")
        self.assertIn("scr_depth_y(y - 16)", src,
                      "the -16 is the grave art offset from Draw_0; without "
                      "it the stone sorts a frame-and-a-half late")

    def test_the_band_is_ordered_and_stays_between_ground_and_shadows(self):
        import re
        src = self.read(DEPTH_REL)
        m = re.search(r"return\s+(-60\s*-\s*_gy\s*/\s*32)\s*;", src)
        self.assertIsNotNone(m, "scr_depth_band has no readable formula")
        expr = m.group(1)
        depths = [eval(expr.replace("_gy", str(y))) for y in (0, 200, 400, 800)]
        self.assertEqual(depths, sorted(depths, reverse=True),
                         "a larger y must give a SMALLER depth (front), or "
                         "the whole sort is upside down")
        self.assertTrue(-86 <= depths[-1] and depths[0] == -60,
                        "the band left -60..-86, where the shadows are at "
                        "-50 and the ground at ~0")

    def test_the_tiebreak_cannot_reorder_two_different_y(self):
        src = self.read(DEPTH_REL)
        # The PROPERTY, not the expression (LL-063): the buffer must be
        # rolled ONCE and be too small to reorder two different y. Which
        # random it is - id mod 97 or irandom(97) - is not our business;
        # asserting the line made this test fail when the IDE re-saved the
        # script with an equivalent one.
        self.assertIn("irandom(97) * 0.00001", src)
        self.assertIn('variable_instance_exists(id, "depthBuffer")', src,
                      "the buffer is rolled every frame - that IS the flicker")
        self.assertLess(97 * 0.00001, 1 / 32,
                        "the tie-break is wider than one depth unit per "
                        "pixel of ground, so it would reorder real positions")

    def test_the_legacy_helper_is_gone(self):
        src = self.read(DEPTH_REL)
        self.assertNotIn("(room_height-y)", src,
                         "scr_setDepth is back: it pointed the wrong way - a "
                         "larger y gave a LARGER depth, i.e. behind")


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class StageBossTests(unittest.TestCase):
    """A stage names its MID boss and its END boss; nothing is rolled (LL-060)."""

    def read(self, rel):
        return (PROJECT_ROOT / rel).read_text(encoding="utf-8-sig")

    def test_every_stage_names_two_bosses(self):
        import re
        rows = [l for l in self.read(STAGE_DATA_REL).splitlines()
                if "stage_row(1," in l]
        self.assertEqual(10, len(rows), "the stage table lost a row")
        for line in rows:
            lists = re.findall(r"\[([^\]]*)\]", line)
            self.assertEqual(2, len(lists), "row lost an array arg: " + line.strip())
            bosses = [x for x in lists[1].split(",") if x.strip()]
            self.assertEqual(2, len(bosses), "not a [mid, end] pair: " + line.strip())

    def test_the_pick_never_rolls_a_boss(self):
        src = _code_only(self.read(PICK_REL))
        self.assertIn("_bosses[_slot]", src)
        self.assertIn("_row.boss_wave", src)
        self.assertNotIn("_bosses[irandom", src)

    def test_the_curve_asks_the_same_question(self):
        src = _code_only(self.read(CURVE_REL))
        self.assertIn("function scr_curve_is_boss_wave(_w, _waves, _boss_wave)", src)
        self.assertIn("_boss_wave = _row.boss_wave", src)
        self.assertNotIn("boss_every", src)


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class RepriceDecisionTests(unittest.TestCase):
    """The four reprice decisions of 2026-10-18, as the code now states them."""

    def read(self, rel):
        return _code_only((PROJECT_ROOT / rel).read_text(encoding="utf-8-sig"))

    def test_the_emerge_does_not_heal(self):
        src = self.read(EMERGE_REL)
        self.assertNotIn("data[MON.life] =", src)
        self.assertIn("scr_changeState(scr_zombie_path)", src)

    def test_a_leak_pays_half_through_the_carry(self):
        src = self.read(LEAK_REL)
        self.assertIn("scr_kill_money(_base, wave_count, !is_boss_wave, 0.5)", src)
        self.assertNotIn("* 0.5)", src)

    def test_the_scale_is_inside_the_rule(self):
        src = self.read(MONEY_REL)
        self.assertIn("function scr_kill_money(_base, _wave, _ramp, _scale)", src)
        self.assertIn("* _s + money_carry", src)


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class DamagePipelineTests(unittest.TestCase):
    """The damage function is told its amount; it never reads the caller (LL-062)."""

    def read(self, rel):
        return _code_only((PROJECT_ROOT / rel).read_text(encoding="utf-8-sig"))

    def test_the_amount_is_a_parameter(self):
        src = self.read(DAMAGE_REL)
        self.assertIn("function scr_do_damage(_arr, _ind, _amount)", src)
        self.assertIn("_obj.data[MON.life] -= _dmg;", src)

    def test_no_scope_variable_is_left_behind(self):
        """`damage_calc` was the caller's variable; it must not exist in code."""
        for path in sorted(PROJECT_ROOT.rglob("*.gml")):
            src = _code_only(path.read_text(encoding="utf-8-sig"))
            self.assertNotIn("damage_calc", src, str(path.relative_to(PROJECT_ROOT)))

    def test_the_only_caller_passes_three_arguments(self):
        src = self.read(SHOOT_REL)
        self.assertIn("scr_do_damage(target, _i, shot_damage)", src)
        # the shape that forced a scope read: for_array runs (array, index) only
        self.assertNotIn("for_array(target,scr_do_damage)", src)

    def test_the_swing_locks_its_own_damage(self):
        src = self.read(TOWER_CREATE_REL)
        self.assertIn("shot_damage = 0;", src)
        self.assertIn("shot_damage  = data[TOWER.damage];", self.read(SHOOT_REL))


if __name__ == "__main__":
    unittest.main()


# ---------------------------------------------------------------------------
# The rigs, and the stages that actually send them
# ---------------------------------------------------------------------------
#
# Four animations per creature is a promise the game makes to the art, and an
# authored stage table is a promise it makes to the player.  Neither can be
# checked from inside GML: a rig in the wrong slot order draws the idle as the
# walk, and a creature no stage names is art the player never sees.

# `stage_row(1,  1,  3, [0],           [0,1],     40,  90),`
STAGE_RE = re.compile(
    r"stage_row\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,"
    r"\s*\[([^\]]*)\]\s*,\s*\[([^\]]*)\]\s*,\s*(\d+)\s*,\s*(\d+)\s*\)")

# creature name -> the prefix its four sprites share.  The two do NOT always
# agree with the creature's name (Orchid-Widow's rig is spr_orchid_*), which is
# why the pairing is written down here instead of guessed from the string.
RIGGED = {
    "Newly-Turned":     "spr_newly_turned",
    "Bog-Wader":        "spr_bog_wader",
    "Sandblasted":      "spr_sand_blasted",
    "Root-Bound":       "spr_root_bound",
    "Shroud":           "spr_shroud",
    "Harvester":        "spr_harvester",
    "Foreman-Rustlung": "spr_foreman_rustlung",
    "Orchid-Widow":     "spr_orchid",
    "Bell-Ringer":      "spr_bell_ringer",
    "Gardener":         "spr_gardener",
}

# The three creatures that shipped before rigs: one sprite, and it is the walk.
SINGLE_SPRITE = ("Grumble-Mulch", "Dome-Alone", "Professor-Cerebrisk")


def _stages(src):
    """The authored stage rows, as dicts of ints and index lists."""
    out = []
    for m in STAGE_RE.finditer(src):
        out.append({
            "region": int(m.group(1)),
            "stage":  int(m.group(2)),
            "seeds":  int(m.group(3)),
            "spawns": [int(x) for x in m.group(4).split(",") if x.strip()],
            "bosses": [int(x) for x in m.group(5).split(",") if x.strip()],
        })
    return out


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class ZombieRigTests(unittest.TestCase):
    """A rig is four sprites, in ZOMB_ANIM's order, named after its creature."""

    @classmethod
    def setUpClass(cls):
        cls.rows = _rows((PROJECT_ROOT / SPAWN_REL).read_text(encoding="utf-8-sig"))

    def row(self, name):
        for (bank, idx), (n, sprites) in self.rows.items():
            if n == name:
                return sprites
        self.fail("%s is not a creature row in %s" % (name, SPAWN_REL))

    def test_every_rigged_creature_carries_its_own_four_slots(self):
        for name, prefix in sorted(RIGGED.items()):
            expected = ["%s_%s" % (prefix, slot) for slot in RIG_SLOTS]
            self.assertEqual(expected, self.row(name),
                             "%s's rig is not %s - a slot out of order draws "
                             "the idle as the walk" % (name, expected))

    def test_the_originals_keep_a_single_walk_sprite(self):
        for name in SINGLE_SPRITE:
            sprites = self.row(name)
            self.assertEqual(1, len(sprites),
                             "%s grew a rig without art for it" % name)
            self.assertTrue(sprites[0].endswith("_walk"),
                            "%s's only sprite is not its walk art" % name)

    def test_every_rig_sprite_is_a_sprite_in_the_project(self):
        for (bank, idx), (name, sprites) in sorted(self.rows.items()):
            for spr in sprites:
                yy = PROJECT_ROOT / "sprites" / spr / (spr + ".yy")
                self.assertTrue(yy.exists(), "%s: %s is missing from the "
                                "project (%s)" % (name, spr, yy))


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class StageCoverageTests(unittest.TestCase):
    """Every creature is sent somewhere, and every index a stage names exists."""

    @classmethod
    def setUpClass(cls):
        cls.rows = _rows((PROJECT_ROOT / SPAWN_REL).read_text(encoding="utf-8-sig"))
        cls.stages = _stages((PROJECT_ROOT / STAGE_DATA_REL).read_text(encoding="utf-8-sig"))

    def bank_size(self, bank):
        return max([idx for (b, idx) in self.rows if b == bank] or [-1]) + 1

    def test_the_table_is_six_regions_of_ten(self):
        self.assertEqual(60, len(self.stages),
                         "the stage table is not six regions of ten - the world "
                         "map draws a 6x10 grid and offers what exists")
        keys = {(r["region"], r["stage"]) for r in self.stages}
        self.assertEqual(60, len(keys), "a region+stage appears twice")

    def test_every_stage_names_a_creature_that_exists(self):
        for r in self.stages:
            for idx in r["spawns"]:
                self.assertLess(idx, self.bank_size("mon"),
                                "%d-%d sends spawn_mon[%d], which does not exist"
                                % (r["region"], r["stage"], idx))
            for idx in r["bosses"]:
                self.assertLess(idx, self.bank_size("boss"),
                                "%d-%d names boss %d, which does not exist"
                                % (r["region"], r["stage"], idx))

    def test_every_creature_is_sent_by_at_least_one_stage(self):
        sent = {"mon": set(), "boss": set()}
        for r in self.stages:
            sent["mon"].update(r["spawns"])
            sent["boss"].update(r["bosses"])

        unused = sorted("%s[%d] %s" % (bank, idx, self.rows[(bank, idx)][0])
                        for (bank, idx) in self.rows
                        if idx not in sent[bank])
        self.assertEqual([], unused,
                         "these creatures have art and numbers and no stage "
                         "sends them: %s" % unused)

