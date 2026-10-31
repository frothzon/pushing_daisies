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

from gm import gml, yy  # noqa: E402
from gm.art import png as art_png  # noqa: E402


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
LOADOUT_REL = "scripts/scr_loadout/scr_loadout.gml"
TOWER_CREATE_REL = "objects/obj_tower/Create_0.gml"
TOWER_EDIT_STEP_REL = "objects/obj_tower_edit/Step_0.gml"
EMERGE_REL = "scripts/scr_zombie_emerge/scr_zombie_emerge.gml"
ZPATH_REL = "scripts/scr_zombie_path/scr_zombie_path.gml"
ZSTATE_REL = "scripts/scr_zomb_state/scr_zomb_state.gml"
ZDIE_REL = "scripts/scr_zombie_die/scr_zombie_die.gml"
ZDEATH_REL = "scripts/scr_zomb_death/scr_zomb_death.gml"
MON_ALARM_REL = "objects/obj_mon/Alarm_0.gml"

PICK_REL = "scripts/scr_level_pick_spawn/scr_level_pick_spawn.gml"
WAIT_REL = "scripts/scr_level_wait/scr_level_wait.gml"
PORTRAIT_REL = "scripts/show_portrait_box/show_portrait_box.gml"
BOX_DRAW_REL = "objects/obj_textbox/Draw_64.gml"

# `spawn_mon[0] = scr_makeMonster("Grumble-Mulch",1,7,array(spr_grumble_walk),...`
#
# The fourth argument is a RIG: `array(walk, idle, attack, die)`.  It was a
# one-element `array(spr_x)` for the three originals and the two region-1 bosses
# long after their four sheets landed, and every check below passed anyway -
# which is how a corpse came to play its walk frames (LL-079).  So the pattern
# captures the WHOLE argument list and the reader decides: a pattern that
# insisted on one sprite would stop matching a row instead of reporting it
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

    def test_all_creatures_have_portrait_art(self):
        """No creature should keep the -1 no-portrait placeholder."""
        missing = sorted(name for (bank, idx), (name, _) in self.rows.items()
                         if self.portraits.get((bank, idx)) == "-1")
        self.assertEqual([], missing,
                         "portrait art is missing for: %s" % missing)
        by_name = {name: self.portraits.get(key)
                   for key, (name, _) in self.rows.items()}
        expected = {
            "Sandblasted": "spr_sandblasted_portrait",
            "Shroud": "spr_shroud_portrait",
        }
        for creature, sprite in expected.items():
            self.assertEqual(sprite, by_name.get(creature),
                             "%s must use its own portrait %s"
                             % (creature, sprite))


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
        function = gml.get_function(self.read(LEVEL_SPAWN_REL), "scr_level_spawn")
        self.assertIsNotNone(function, "scr_level_spawn function is missing")
        src = _code_only(function.source)
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
        # 2026-10-26 (LL-080): the walk is started by REQUESTING the state,
        # not by swapping a script reference behind the scene.
        self.assertIn("scr_zomb_request(ZOMB_STATE.PATH)", src)
        self.assertNotIn("scr_changeState(", src)

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
        self.assertIn("function scr_do_damage(_arr, _ind, _amount, _is_critical)", src)
        self.assertIn("data[MON.life] -= _final_dmg;", src)

    def test_no_scope_variable_is_left_behind(self):
        """`damage_calc` was the caller's variable; it must not exist in code."""
        for path in sorted(PROJECT_ROOT.rglob("*.gml")):
            src = _code_only(path.read_text(encoding="utf-8-sig"))
            self.assertNotIn("damage_calc", src, str(path.relative_to(PROJECT_ROOT)))

    def test_the_only_caller_passes_four_arguments(self):
        src = self.read(SHOOT_REL)
        self.assertIn("scr_do_damage(target, _i, _hit_damage, _is_critical)", src)
        # the shape that forced a scope read: for_array runs (array, index) only
        self.assertNotIn("for_array(target,scr_do_damage)", src)

    def test_the_swing_locks_its_own_damage(self):
        src = self.read(TOWER_CREATE_REL)
        self.assertIn("shot_damage = 0;", src)
        self.assertIn("shot_damage  = data[TOWER.damage];", self.read(SHOOT_REL))


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class LoadoutSandboxTests(unittest.TestCase):
    def test_dev_unlock_bypass_is_ephemeral(self):
        src = _code_only((PROJECT_ROOT / LOADOUT_REL).read_text(encoding="utf-8-sig"))

        def body(name, args):
            match = re.search(r"function " + name + r"\(" + args + r"\)\s*\{(.*?)\n\}",
                              src, re.S)
            self.assertIsNotNone(match, name + " is missing")
            return match.group(1)

        mode = body("loadout_dev_mode", "")
        self.assertIn('variable_global_exists("devMode") && global.devMode == true', mode)
        self.assertIn("LOADOUT DEV sandbox: unlock bypass is temporary; save unchanged", mode)

        unlock = body("loadout_unlocked", r"_name")
        self.assertRegex(unlock, r"if\s*\(\s*loadout_dev_mode\(\)\s*\)\s*return true;")

        save = body("loadout_set", r"_arr")
        self.assertRegex(save, r"global\.loadout\s*=\s*_arr;")
        self.assertRegex(save, r"&&\s*!loadout_dev_mode\(\)\s*\)\s*\{\s*"
                               r"global\.meta\[\$\s*\"loadout\"\]\s*=\s*_arr;")


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
#
# EVERY creature in both banks is listed, in spawn-table order.  The three
# originals and the two region-1 bosses were missing from this table for weeks
# after their idle/attack/die sheets landed, so nothing looked at their slots
# and a dying Grumble-Mulch played its walk frames (LL-079).  A creature that
# is not here is a creature no check in this file covers, which is why
# test_every_creature_row_is_in_the_rig_table pins the table to EQUALITY.
RIGGED = {
    "Grumble-Mulch":       "spr_grumble",
    "Dome-Alone":          "spr_dome_alone",
    "Professor-Cerebrisk": "spr_professor",
    "Newly-Turned":        "spr_newly_turned",
    "Bog-Wader":           "spr_bog_wader",
    "Sandblasted":         "spr_sand_blasted",
    "Root-Bound":          "spr_root_bound",
    "Shroud":              "spr_shroud",
    "Harvester":           "spr_harvester",
    "Tusk-A-Lot":          "spr_tusk",
    "Sub-Zero":            "spr_zero",
    "Foreman-Rustlung":    "spr_foreman_rustlung",
    "Orchid-Widow":        "spr_orchid",
    "Bell-Ringer":         "spr_bell_ringer",
    "Gardener":            "spr_gardener",
}

# The three places a monster's death touches its art: the Draw that places it,
# the script that plays a slot, and the kill that asks for the die slot (LL-079).
MON_DRAW_REL = "objects/obj_mon/Draw_0.gml"
ZOMB_ART_REL = "scripts/scr_zomb_art/scr_zomb_art.gml"
ZOMB_DEATH_REL = "scripts/scr_zomb_death/scr_zomb_death.gml"

# How far frame 0 of a die sheet may meet the ground from where frame 0 of the
# walk sheet does, in canvas px.  Measured 2026-10-24 on all fifteen rigs on
# disk: the worst is 5 px either way (Bog-Wader -2/+7, Zero +7/+2, Grumble
# -4/+3).  Six means "the same origin, not the same art": re-cutting a rig is
# allowed, re-origining it is the bug.  Monsters are drawn at their row's scale
# (Tusk 0.5, Grumble 1.0), so a pass is a few screen px - while the bug this
# guards against moved the Bell-Ringer 22 canvas px, 6.6 on screen at 0.3.
ART_GROUND_TOLERANCE = 6


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


def _art_bottom(spr):
    """Frame 0's lowest painted row, as px BELOW the sprite's own origin.

    Read from the PNG, not from the .yy, because ``bbox_bottom`` in the .yy is
    one box for the whole sprite: the envelope of all sixteen frames. On a die
    sheet its lowest pixel belongs to the body lying on the ground, not to the
    frame that stands, so it is not the number a pose's contact point can be
    read from (LL-078).

    Alpha > 0 counts as painted - an anti-aliased foot is still the foot.
    """
    folder = PROJECT_ROOT / "sprites" / spr
    data = yy.load(folder / (spr + ".yy"))
    frames = data.get("frames") or []
    if not frames:
        raise AssertionError("%s: the .yy declares no frames" % spr)
    frame = folder / (frames[0]["name"] + ".png")
    if not frame.exists():
        raise AssertionError("%s: frame 0 is not on disk (%s)" % (spr, frame))
    width, height, rgba = art_png.read_png(frame)
    for y in range(height - 1, -1, -1):
        row = rgba[y * width * 4:(y + 1) * width * 4]
        if any(row[i] for i in range(3, len(row), 4)):
            return y - int(data["sequence"]["yorigin"])
    raise AssertionError("%s: frame 0 is fully transparent" % spr)


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

    def test_every_creature_row_is_in_the_rig_table(self):
        """A row missing from RIGGED is a row nothing here looks at.

        This is the hole five creatures fell through (LL-079): their rows were
        legal - a one-slot `array(spr_x)` is a documented shape - and nothing
        compared the table to the rig list, so their idle/attack/die sheets
        were never mentioned again and a dying monster played its walk frames.
        Equality in both directions, so a renamed rig or a deleted creature is
        caught in the same breath.
        """
        rows = sorted(name for (name, _sprites) in self.rows.values())
        self.assertEqual(sorted(RIGGED), rows,
                         "the rig table and the spawn table name different "
                         "creatures - every row needs a rig entry, or its "
                         "slots go unchecked")

    def test_every_rig_sprite_is_a_sprite_in_the_project(self):
        for (bank, idx), (name, sprites) in sorted(self.rows.items()):
            for spr in sprites:
                yy = PROJECT_ROOT / "sprites" / spr / (spr + ".yy")
                self.assertTrue(yy.exists(), "%s: %s is missing from the "
                                "project (%s)" % (name, spr, yy))

    def test_the_kill_line_names_the_slot_the_fall_uses(self):
        """A corpse with no die art must SAY so instead of looking broken.

        The fallback that keeps the previous animation is correct (a one-slot
        row is legal art-yet-to-land), but it is indistinguishable on screen
        from a broken death animation - which is how five creatures' walk
        frames played through their death (LL-079).  So the per-kill line
        names the slot, and the name is only read behind an existence guard
        (sprite_get_name on -1 is fatal, LL-012).
        """
        src = (PROJECT_ROOT / ZOMB_DEATH_REL).read_text(encoding="utf-8-sig")
        self.assertIn('" die=", _die_txt', src,
                      "the kill line no longer prints which sprite the corpse "
                      "fell with - a missing die slot would be silent again")
        self.assertIn("NONE (keeps the walk art)", src,
                      "an empty die slot must be spelled out, not left blank")
        self.assertRegex(src, r"if\s*\(\s*sprite_exists\(\s*_die_spr\s*\)\s*\)",
                         "sprite_get_name is not behind an existence guard, so "
                         "a row with no die art is a fatal error mid-kill")

    def test_the_die_frame_stands_where_the_walk_frame_stands(self):
        """Dying needs no vertical correction, because the origin IS the ground.

        The fall PIVOTS on the origin - which is why the LAST frame of a die
        sheet lies 23 px below the feet on Tusk and Zero.  That is the pose.
        Frame 0, though, must stand where the walk stands, and it does: within
        5 px on every rig (measured 2026-10-24, all fifteen).  So anything that
        "puts the corpse on the ground" takes it off the ground, which is what
        the old correction did (LL-078).
        """
        for name, prefix in sorted(RIGGED.items()):
            walk = _art_bottom(prefix + "_walk")
            die = _art_bottom(prefix + "_die")
            self.assertLessEqual(
                abs(die - walk), ART_GROUND_TOLERANCE,
                "%s: %s_die's frame 0 meets the ground at %+d px from its "
                "origin, but %s_walk's does at %+d px - the body would %s %d px "
                "the instant it dies.  Re-cut the die sheet onto the walk's "
                "origin; do not correct it in code"
                % (name, prefix, die, prefix, walk,
                   "drop" if die > walk else "jump", abs(die - walk)))

    def test_nothing_moves_a_monster_off_its_origin_to_reach_the_ground(self):
        """No code shifts a monster vertically at draw time (LL-078).

        The helper that did, zomb_ground_offset(), returned
        ``(height - 1) - bbox_bottom``: the empty canvas rows below the art -
        the room kept for the body to lie down, 22 rows of the Bell-Ringer's
        175 px sheet - a number with nothing to do with where the feet are.
        Every corpse sank by it (0.3 px on the Orchid-Widow, 28 on the Shroud)
        and standing poses keep canvas too, so the Grumble-Mulch walked 2 px
        inside the ground for the whole game. A vertical shift in the Draw is
        that bug coming back.
        """
        draw = _code_only(
            (PROJECT_ROOT / MON_DRAW_REL).read_text(encoding="utf-8-sig"))
        self.assertNotRegex(
            draw, r"(?m)^\s*y\s*[+-]=",
            "%s shifts y at draw time - the sprite's origin is the ground, so "
            "an offset moves the body off it (LL-078)" % MON_DRAW_REL)

        art = _code_only(
            (PROJECT_ROOT / ZOMB_ART_REL).read_text(encoding="utf-8-sig"))
        self.assertNotIn(
            "zomb_ground_offset", art,
            "%s measures a monster's ground offset again: that number is the "
            "empty canvas rows under the art, which says nothing about where "
            "the feet are (LL-078)" % ZOMB_ART_REL)


# The roster: one struct per creature, its four slots read back BY NAME
# (LL-081).  Everything below is a text check on the SHAPE of that lookup,
# because a test that cannot run GML cannot watch a corpse fall - what it can
# pin is that no state asks for a slot by position any more, that the roster is
# built once from both banks, and that a missing slot is loud.
ROSTER_REL = "scripts/scr_mon_roster/scr_mon_roster.gml"


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class MonsterRigRosterTests(unittest.TestCase):
    """A monster's art is asked for by NAME, on one struct per creature.

    LL-081.  A rig used to be a bare array - ``array(walk, idle, attack, die)``
    - copied onto every instance by scr_level_spawn, and then read by INDEX from
    four scripts: emerge took ``[0]``, walk and idle went through
    ``zomb_art_play(array, ZOMB_ANIM.x)``, and the kill and the fall both asked
    for ``ZOMB_ANIM.die``.  Every read was correct in isolation and together
    they could not be checked: a slot past the end of a short row answers -1,
    "change nothing" is a legal answer, and a corpse that played its WALK frames
    was indistinguishable from art that had not landed (LL-079).

    So the slots are NAMED now: ``mon_rig_slot(rig, ZOMB_ANIM.die)``, on a
    struct built once per creature from the same bank rows scr_setupSpawning
    writes, cached in ``global.mon_roster`` and pulled per spawn.  These tests
    pin the four things that makes true.
    """

    @classmethod
    def setUpClass(cls):
        cls.roster = _code_only(
            (PROJECT_ROOT / ROSTER_REL).read_text(encoding="utf-8-sig"))
        cls.spawn = _code_only(
            (PROJECT_ROOT / SPAWN_REL).read_text(encoding="utf-8-sig"))
        cls.rows = _rows((PROJECT_ROOT / SPAWN_REL).read_text(encoding="utf-8-sig"))

    def read(self, rel):
        return _code_only((PROJECT_ROOT / rel).read_text(encoding="utf-8-sig"))

    def test_no_state_indexes_a_copied_rig_array(self):
        """The bug's shape was a POSITION; a name cannot be one slot out."""
        for rel in (EMERGE_REL, ZPATH_REL, ZDIE_REL, ZDEATH_REL):
            src = self.read(rel)
            self.assertNotIn(
                "sprite_array[", src,
                "%s still indexes the rig array by position - a short or "
                "reordered row answers -1 there, and -1 is silent (LL-081)"
                % rel)
            for old in ("zomb_art_play(", "zomb_art_sprite("):
                self.assertNotIn(
                    old, src,
                    "%s still calls %s, which took an array and an index - the "
                    "lookup is mon_rig_* now (LL-081)" % (rel, old))

    def test_every_state_asks_the_one_lookup(self):
        """Emerge, walk, fall and kill all ask zomb_rig() - one source of art."""
        for rel in (EMERGE_REL, ZPATH_REL, ZDIE_REL, ZDEATH_REL):
            self.assertRegex(
                self.read(rel), r"\bzomb_rig\(\)",
                "%s reads a monster's art without asking its rig - the roster "
                "is the only place the four slots are named (LL-081)" % rel)
    def test_the_fall_asks_for_the_die_slot_by_name(self):
        """The slot this whole card is about, spelled out."""
        self.assertIn("mon_rig_play(_rig, ZOMB_ANIM.die, ZOMB_DIE_SECS)",
                      self.read(ZDIE_REL),
                      "the fall no longer asks its rig for the die slot")
        self.assertIn("mon_rig_slot(zomb_rig(), ZOMB_ANIM.die)",
                      self.read(ZDEATH_REL),
                      "the kill line no longer names the slot the fall will use")

    def test_a_rig_with_no_die_art_is_loud(self):
        """The silent fallback is what hid the bug: it must say so, once."""
        self.assertIn("mon_rig_warn_no_die(_rig)", self.read(ZDIE_REL),
                      "a corpse with no die sheet falls on the step clock in "
                      "silence again - that is LL-079 all over")
        warn = self.roster[self.roster.index("function mon_rig_warn_no_die"):]
        self.assertIn("has NO die slot", warn)
        self.assertIn("mon_no_die_reported", warn,
                      "the warning is not once-per-creature, so it will spam")
        self.assertRegex(warn, r"if\s*\(\s*variable_struct_exists\(",
                         "the once-only set is read without a guard (LL-002)")

    def test_the_roster_is_built_once_from_both_banks(self):
        """One build, in the one scope where both banks exist (rule 6)."""
        self.assertIn("mon_roster_build(spawn_mon, spawn_boss);", self.spawn,
                      "%s does not build the roster, so no monster has a rig"
                      % SPAWN_REL)
        self.assertIn("global.mon_roster = [];", self.roster,
                      "the roster is not rebuilt from scratch - a second boot "
                      "would keep the old creatures' structs")
        self.assertIn("array_push(global.mon_roster", self.roster)

    def test_the_instance_pulls_its_rig_by_name(self):
        """scr_level_spawn hands over the SHARED struct; Create declares it."""
        src = self.read(LEVEL_SPAWN_REL)
        self.assertIn("_inst.rig = mon_rig_find(_mon[MON.name]);", src,
                      "a spawned monster is not given its rig, so the states "
                      "would rebuild one from the instance")
        self.assertRegex(self.read(MON_CREATE_REL), r"(?m)^rig\s*=\s*undefined",
                         "obj_mon/Create_0 does not declare `rig` - a read "
                         "would be the first writer (LL-002)")

    def test_the_lookup_is_defined_exactly_once(self):
        """A copy of the lookup is a second truth about where art comes from."""
        for name in ("mon_rig_slot", "mon_rig_play", "mon_rig_find",
                     "mon_rig_has", "mon_rig_dress",
                     "mon_roster_build", "zomb_rig"):
            defs = sum(len(re.findall(r"\bfunction\s+%s\s*\(" % name,
                                      p.read_text(encoding="utf-8-sig")))
                       for p in PROJECT_ROOT.rglob("*.gml"))
            self.assertEqual(1, defs, "%s() is defined %d times" % (name, defs))

    def test_every_rig_has_four_distinct_slots_and_its_own_die(self):
        """A row whose die slot IS its walk slot dies without a death.

        ``mon_rig_play`` leaves a sheet alone when it is already playing, and
        answers the sprite; the fall reads "not a change" as "no sheet to
        watch".  So a die slot copied from the walk - a one-word paste, and the
        exact shape of the art drops that have gone wrong here - would give back
        the silent walk-through-death, this time with every slot filled.
        Distinctness is the contract; the two suffixes say which name belongs in
        which position.
        """
        for (bank, idx), (name, sprites) in sorted(self.rows.items()):
            where = "%s[%d] %s" % (bank, idx, name)
            self.assertEqual(len(RIG_SLOTS), len(sprites),
                             "%s carries %d slots, not %d"
                             % (where, len(sprites), len(RIG_SLOTS)))
            self.assertEqual(len(set(sprites)), len(sprites),
                             "%s uses one sprite for two slots: %s"
                             % (where, sprites))
            self.assertTrue(sprites[0].endswith("_walk"),
                            "%s: slot 0 is %s, and slot 0 is the walk"
                            % (where, sprites[0]))
            self.assertTrue(sprites[RIG_SLOTS.index("die")].endswith("_die"),
                            "%s: the die slot is %s, which is not a die sheet"
                            % (where, sprites[RIG_SLOTS.index("die")]))

    def test_the_report_and_the_trace_name_every_slot(self):
        """A diagnostic must print NAMES, and it must be switchable off."""
        self.assertIn("for(var _i = 0; _i < 4; _i++)", self.roster,
                      "mon_rig_report no longer walks all four slots, so a "
                      "blank one would read as a shorter list")
        self.assertIn('#macro ZOMB_RIG_TRACE', self.roster,
                      "the trace has no switch, so it can only be deleted")
        self.assertEqual(2, self.roster.count("if(!ZOMB_RIG_TRACE) return;"),
                         "a trace line is not behind ZOMB_RIG_TRACE")
        self.assertIn("mon_rig_report(", self.read(ZOMB_ART_REL),
                      "the boot report no longer uses the roster's own report, "
                      "so it can disagree with what the monsters play")

    # ---- dressed at birth, healed every step (LL-082) -------------------
    # obj_mon's own sprite is spr_mon: ONE 32x32 frame.  It is the object's
    # spriteId, and a spriteId outlives every state that was meant to replace
    # it - so "all my monsters play one sprite for both animations" is what the
    # game looks like when nothing dresses the instance and no state runs.

    def test_a_spawn_is_born_in_its_class_walk_art(self):
        """The spawn dresses the instance it has just made, in the class's art."""
        src = self.read(LEVEL_SPAWN_REL)
        rig_at = src.index("_inst.rig = mon_rig_find(_mon[MON.name]);")
        dress_at = src.index("mon_rig_dress(rig);")
        self.assertLess(rig_at, dress_at,
                        "%s dresses the monster before it has a rig, so "
                        "mon_rig_dress has nothing to read" % LEVEL_SPAWN_REL)
        self.assertIn("with(_inst){", src[rig_at:dress_at],
                      "mon_rig_dress is called without with(_inst) - it writes "
                      "sprite_index on the CALLING instance, which would be the "
                      "level controller (rule 6)")

        dress = self.roster[self.roster.index("function mon_rig_dress"):]
        dress = dress[:dress.index("\n}")]
        self.assertIn("mon_rig_slot(_rig, ZOMB_ANIM.walk)", dress,
                      "mon_rig_dress does not ask the rig for the WALK slot by "
                      "name (LL-081)")
        self.assertNotIn("ZOMB_ANIM.die", dress,
                         "mon_rig_dress touches the die slot: falling is the "
                         "DIE state's job, and a live body dressed in its "
                         "corpse sheet is a body that has not died (LL-080)")
        self.assertIn("if(sprite_index == _walk) return _walk;", dress,
                      "mon_rig_dress re-brands the sheet it is already playing, "
                      "so a per-step caller restarts the walk cycle every step "
                      "(LL-030)")

    def test_no_step_can_leave_the_placeholder_on_screen(self):
        """The heal fires on the sprite, BEFORE the dispatch, never after it."""
        step = self.read(ZSTATE_REL)
        self.assertIn("if(!mon_rig_has(_rig, sprite_index)) mon_rig_dress(_rig);",
                      step,
                      "%s does not heal a monster whose sprite is not its "
                      "class's art - anything created outside scr_level_spawn "
                      "keeps spr_mon for its whole life (LL-082)" % ZSTATE_REL)
        self.assertLess(
            step.index("if(!mon_rig_has(_rig, sprite_index))"),
            step.index("switch(zomb_state)"),
            "the heal runs after the dispatch, so it can replace the die sheet "
            "a state has just played")

        has = self.roster[self.roster.index("function mon_rig_has"):]
        has = has[:has.index("\n}")]
        self.assertIn("mon_rig_slot(_rig, _i)", has,
                      "mon_rig_has does not ask the named lookup for each slot, "
                      "so it would answer for a sprite the rig never named "
                      "(LL-081)")

    def test_the_objects_own_sprite_is_a_placeholder_that_cannot_animate(self):
        """spr_mon is one frame; the Create says so and stops it animating."""
        create = self.read(MON_CREATE_REL)
        self.assertIn("sprite_array = [spr_mon,spr_mon];", create,
                      "obj_mon's placeholder row is gone - zomb_rig() rebuilds "
                      "a rig from it when the roster has no answer for a "
                      "creature")
        self.assertRegex(
            create, r"(?m)^image_speed\s*=\s*0\s*;",
            "obj_mon/Create_0 lets the one-frame placeholder animate: a "
            "drifting image_index on a still picture reads as a broken walk "
            "cycle rather than as a placeholder (LL-082)")

        raw = (PROJECT_ROOT / MON_CREATE_REL).read_text(encoding="utf-8-sig")
        self.assertIn("PLACEHOLDER", raw,
                      "obj_mon/Create_0 does not say that spr_mon is a "
                      "placeholder - the next reader will take it for the art")

        frames = (PROJECT_ROOT / "sprites/spr_mon/spr_mon.yy").read_text(
            encoding="utf-8-sig").count('"$GMSpriteFrame"')
        self.assertEqual(1, frames,
                         "spr_mon has %d frame(s) - if the placeholder has "
                         "become real art, dress the monsters in it and delete "
                         "this check (LL-082)" % frames)

    def test_mon_rig_pick_does_not_type_test_the_enum_slot(self):
        """is_real() answers FALSE for enum values - the manual says so.

        mon_rig_from passes ZOMB_ANIM constants as _slot, and enum values
        are stored as int64s, so an is_real guard there answers false for
        every perfectly good slot: every rig is built with all four slots
        -1, no monster is ever dressed in its class art, and the boot trace
        says ``slots=4 walk=none`` while the art sits in the row - which is
        the "every monster spawns as a 32x32 still (spr_mon)" report
        (LL-083, LL-034's shape).  The bounds checks are the real guards.
        """
        self.assertNotIn(
            "is_real(_slot)", self.roster,
            "mon_rig_pick type-tests its slot with is_real: ZOMB_ANIM "
            "values are int64s, is_real answers false for them, and every "
            "slot of every rig bails - no monster is ever dressed in its "
            "class art (LL-083, LL-034)")


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class GmlBraceShapeTests(unittest.TestCase):
    """Every .gml defines every function at depth ZERO, and ends at zero.

    LL-077 again, this time for the whole tree - because it happened again on
    2026-10-26 while scr_mon_roster was being written.  An insert landed one
    line early (right after the `array_push` instead of at EOF), so the TAIL of
    mon_roster_build - the trace call, the closing braces, `return` - ended up
    at the end of the file and mon_roster(), mon_rig_find(), zomb_rig() and
    mon_rig_warn_no_die() were nested inside its inner `for`.  Every gate was
    green: the braces balanced overall, `gm gml-functions scr_mon_roster` listed
    every function in it (it is a regex), and the whole suite passed, because
    every one of those checks reads TEXT.  The file only reads as a nested
    program to a counter that remembers where it is.

    A `function` at depth 0 is not a style rule - GML defines a function where
    the braces put it, so a nested one is simply not the function the file says.
    """

    #: SKIP these - generated or vendored, not GameMaker resources
    SKIP = ("Build/", "python_tools/", "datafiles/")

    def test_no_function_is_nested_inside_another(self):
        bad = []
        for path in sorted(PROJECT_ROOT.rglob("*.gml")):
            rel = path.relative_to(PROJECT_ROOT).as_posix()
            if rel.startswith(self.SKIP):
                continue
            blocks, end_depth = _function_blocks(
                path.read_text(encoding="utf-8-sig", errors="replace"))
            for name, depth in blocks:
                if depth != 0:
                    bad.append("%s: %s() starts %d block(s) deep"
                               % (rel, name, depth))
            if end_depth != 0:
                bad.append("%s: the file ends %+d braces from where it started"
                           % (rel, end_depth))

        self.assertEqual(
            [], bad[:20],
            "%d definition(s) are nested in a block that never closed - a "
            "function tail that ended up elsewhere in the file. GML defines a "
            "function where the braces put it, so this is not the program the "
            "file reads like (LL-077)" % len(bad))


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


#--------------------------------------------------------------------------------
# The menu backdrop blur: a shader pass over application_surface, in Draw GUI
#--------------------------------------------------------------------------------
# The four meta screens used to sit over a 683x384 sprite baked through shd_blur
# once per run (LL-074), then over a filter layer in rm_menu, which died when the
# room editor turned that layer into a background (LL-076).  The blur is a shader
# pass again - but every frame, into a reused surface.  Each of the ways it can
# break is invisible in a passing build: a shader used without checking that it
# compiled, a capture taken in Draw (a half-composed frame), a render target that
# is never released, a blur drawn AFTER the panels (which hides the buttons), or
# GML that reads a room layer the IDE can take away.
ROOM_MENU_REL = "rooms/rm_menu/rm_menu.yy"
MENU_BLUR_REL = "scripts/scr_menu_blur/scr_menu_blur.gml"
MENU_STEP_REL = "objects/Menu/Step_0.gml"
MENU_DRAW_REL = "objects/Menu/Draw_64.gml"
MENU_DRAW0_REL = "objects/Menu/Draw_0.gml"
BLUR_SHADER = "shd_blur"
BLUR_SHADER_FSH_REL = "shaders/shd_blur/shd_blur.fsh"
BLUR_SHADER_YY_REL = "shaders/shd_blur/shd_blur.yy"

BLURRED_STATES = ("WORLD_MAP", "DEPLOY", "GARDEN", "RESULTS")
SHARP_STATES = ("START", "NEW_GAME", "CONTINUE", "OPTIONS", "RETURN", "QUIT")


def _flat_layers(layers):
    """Every layer of a room, including the ones nested inside layer groups."""
    out = []
    for layer in layers:
        out.append(layer)
        out.extend(_flat_layers(layer.get("layers") or []))
    return out


def _body(src, name):
    """One GML function's text, up to the next `function` - comments kept."""
    after = src.split("function %s(" % name, 1)
    if len(after) != 2:
        raise AssertionError("no function %s() in the source" % name)
    return after[1].split("\nfunction ", 1)[0]


def _function_blocks(src):
    """(name, brace depth where it starts) for every definition, plus the end depth.

    Counting `{` against `}` proves only that a file CLOSES; it cannot show that
    the blocks NEST where you meant them to.  A function tail that ends up at EOF -
    which is what an edit that appends instead of inserts leaves behind - keeps the
    counts equal and puts every following function inside an unclosed block.  The
    file then looks fine to a brace count, to `gm gml-functions` (a regex) and to
    every test that greps it, and GameMaker compiles a different program from the
    one the file reads like (LL-077).
    """
    code = re.sub(r'"[^"]*"', '""', _code_only(src))
    blocks, depth = [], 0
    for line in code.splitlines():
        found = re.match(r"function\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", line)
        if found:
            blocks.append((found.group(1), depth))
        depth += line.count("{") - line.count("}")
    return blocks, depth


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class MenuBackdropBlurTests(unittest.TestCase):
    """The meta screens sit over a shader-blurred backdrop; the title stays sharp."""

    @classmethod
    def setUpClass(cls):
        cls.layers = _flat_layers(yy.load(PROJECT_ROOT / ROOM_MENU_REL)["layers"])
        cls.blur_src = (PROJECT_ROOT / MENU_BLUR_REL).read_text(encoding="utf-8-sig")
        cls.blur_code = _code_only(cls.blur_src)
        cls.step_code = _code_only(
            (PROJECT_ROOT / MENU_STEP_REL).read_text(encoding="utf-8-sig"))
        cls.draw_code = _code_only(
            (PROJECT_ROOT / MENU_DRAW_REL).read_text(encoding="utf-8-sig"))
        cls.draw0_code = _code_only(
            (PROJECT_ROOT / MENU_DRAW0_REL).read_text(encoding="utf-8-sig"))

    def test_the_blur_is_a_shader_pass_not_a_room_layer(self):
        for gone in ("layer_get_id(", "layer_enable_fx(", "layer_set_visible(",
                     "layer_fx_is_enabled(", "layer_get_visible(", "layer_depth("):
            self.assertNotIn(
                gone, self.blur_code,
                "%s is back in scr_menu_blur: a room layer is a switch the IDE can "
                "turn into a background layer that draws a sprite and filters "
                "nothing, and no flag in GML can tell (LL-076)" % gone)
        self.assertIn("shader_set(%s)" % BLUR_SHADER, self.blur_code,
                      "nothing draws the backdrop through the blur shader")
        self.assertIn("shader_reset()", self.blur_code,
                      "a shader left set would put every later draw in the frame "
                      "through the blur")

    def test_the_shader_must_have_compiled_before_it_is_used(self):
        self.assertIn("shader_is_compiled(%s)" % BLUR_SHADER, self.blur_code,
                      "nothing checks whether the blur shader compiled")
        self.assertLess(
            self.blur_code.index("shader_is_compiled("),
            self.blur_code.index("shader_set("),
            "shader_set() runs before anything asks whether the shader compiled, so "
            "a failed compile draws the world through it")

    def test_the_capture_is_the_room_at_a_fraction_of_the_canvas(self):
        self.assertIn("draw_surface_stretched(application_surface", self.blur_code,
                      "the blur does not capture application_surface, so it is not "
                      "blurring the composed room")
        self.assertIn("display_get_gui_width()", self.blur_code,
                      "the destination size is guessed instead of read from the canvas")
        self.assertIn("display_get_gui_height()", self.blur_code)
        self.assertIn("* MENU_BLUR_SCALE", self.blur_code,
                      "the size the blur is computed at must come from the macro")

    def test_the_scale_is_a_fraction_of_the_canvas(self):
        found = re.search(r"#macro\s+MENU_BLUR_SCALE\s+([0-9.]+)", self.blur_src)
        self.assertIsNotNone(found, "scr_menu_blur has no MENU_BLUR_SCALE macro")
        scale = float(found.group(1))
        self.assertGreater(scale, 0.0, "MENU_BLUR_SCALE is zero: nothing to blur")
        self.assertLessEqual(
            scale, 0.5,
            "MENU_BLUR_SCALE %.2f is more than half the canvas - shd_blur is 160 taps "
            "a pixel, so a full-size per-frame blur is ~83 M texture reads" % scale)

    def test_the_render_target_is_always_released(self):
        self.assertEqual(
            self.blur_code.count("surface_set_target("),
            self.blur_code.count("surface_reset_target("),
            "surface_set_target() without a matching reset leaves the rest of the "
            "frame painting into the blur surface")
        self.assertLess(self.blur_code.index("surface_set_target("),
                        self.blur_code.index("surface_reset_target("),
                        "the reset comes before the set")

    def test_the_surface_is_reused_and_guarded(self):
        self.assertIn('variable_global_exists("menu_blur_surf")', self.blur_code,
                      "the blur surface must live in a GLOBAL: a surface outlives the "
                      "instance that made it and Menu has no Clean Up event to free "
                      "one in, so a per-instance surface leaks one per room entry")
        self.assertIn("surface_create(", self.blur_code)
        self.assertIn("surface_free(", self.blur_code,
                      "a canvas resize must release the old surface, not abandon it")
        self.assertLess(
            self.blur_code.index("surface_exists("),
            self.blur_code.index("surface_get_width("),
            "surface_get_width() on a surface that may have been freed is a crash; "
            "existence has to be asked first (LL-002)")



    def test_a_failure_is_said_once_and_names_the_reason(self):
        body = _code_only(_body(self.blur_src, "menu_blur_fail"))
        self.assertIn("menu_blur_failed == _why", body,
                      "the failure line must be de-duplicated: a reason printed every "
                      "frame is noise, not a diagnostic")
        self.assertIn("print(", body)
        self.assertIn("menu_blur_fail(", self.blur_code,
                      "nothing reports a blur that could not be made - which is how "
                      "the layer version could log 'on' over a sharp screen")

    def test_only_the_four_meta_screens_ask_for_the_blur(self):
        body = _code_only(_body(self.blur_src, "menu_blur_wanted"))
        for state in BLURRED_STATES:
            self.assertIn("MENU_STATE.%s" % state, body,
                          "%s does not ask for the blur" % state)
        for state in SHARP_STATES:
            self.assertNotIn("MENU_STATE.%s" % state, body,
                             "%s asks for the blur but keeps the backdrop sharp"
                             % state)

    def test_menu_blur_wanted_does_not_type_test_the_enum_state(self):
        """is_real() answers FALSE for enum values - the manual says so.

        menu_state is a MENU_STATE value, stored as an int64, so an
        is_real guard on _state answered false for every state: no screen
        asked for the blur, every meta screen stayed sharp, and NOTHING
        said so, because the !wanted path prints nothing on the first
        screen (LL-083, LL-034's shape).  The guard was for -1.
        """
        body = _code_only(_body(self.blur_src, "menu_blur_wanted"))
        self.assertNotIn(
            "is_real", body,
            "menu_blur_wanted type-tests _state with is_real: MENU_STATE "
            "values are int64s, is_real answers false for them, and the "
            "blurred backdrop is silently never drawn (LL-083)")
        self.assertIn(
            "if(_state == -1) return false;", body,
            "the -1 first-frame sentinel is no longer guarded by name - "
            "switch() answers 'not one of ours', but -1 is the caller's "
            "first frame and deserves its own line")

    def test_nothing_outside_the_draw_can_switch_the_blur(self):
        self.assertIn("menu_blur_draw();", self.draw_code,
                      "Draw GUI never draws the blur")
        self.assertNotIn("menu_blur", self.step_code,
                         "the Step still calls a blur function: the blur is a DRAW, "
                         "and a Step-owned switch is what let the layer version look "
                         "alive while nothing happened")
        self.assertNotIn("menu_blur", self.draw0_code,
                         "Menu/Draw_0 is the room-space Draw, where application_surface "
                         "holds only the layers drawn so far - the capture belongs in "
                         "Draw GUI, after the room is composed")

    def test_the_blur_is_drawn_before_the_panels(self):
        at = self.draw_code.index("menu_blur_draw();")
        for panel in ("meta_draw_worldmap(", "meta_draw_deploy(",
                      "meta_draw_garden(", "meta_draw_results("):
            self.assertIn(panel, self.draw_code)
            self.assertLess(at, self.draw_code.index(panel),
                            "%s is painted before the blurred backdrop, so the blur "
                            "covers it" % panel)

    def test_the_shader_that_does_the_work_exists(self):
        fsh = PROJECT_ROOT / BLUR_SHADER_FSH_REL
        self.assertTrue(fsh.exists(), "there is no %s" % BLUR_SHADER_FSH_REL)
        self.assertTrue((PROJECT_ROOT / BLUR_SHADER_YY_REL).exists(),
                        "%s is not a project resource" % BLUR_SHADER)
        text = fsh.read_text(encoding="utf-8-sig")
        self.assertIn("gm_BaseTexture", text,
                      "the blur shader samples no texture, so it blurs nothing")
        self.assertIn("texture2D(", text)

    def test_no_room_layer_is_named(self):
        """The room may change under GML, so a layer is never the contract.

        rm_menu currently carries a layer called Blur_Effect that has an
        effectType and is NOT an effect layer - it draws a background.  If the
        code ever names a layer again, this is the shape it must not be fooled
        by (LL-076).
        """
        strays = [layer["name"] for layer in self.layers
                  if layer.get("effectType")
                  and layer.get("resourceType") != "GMREffectLayer"]
        for name in strays:
            self.assertNotIn(name, self.blur_code,
                             "scr_menu_blur names the layer '%s', which carries an "
                             "effectType on a background layer: it draws, it never "
                             "filters" % name)

    def test_every_function_is_closed_before_the_next_one_starts(self):
        """The four definitions are four blocks, not one block and three guests.

        This catches the shape a bad paste leaves behind: the tail of
        menu_blur_surface() appended at the END of the file, so the braces still
        count 14 and 14 while menu_blur_fail() and menu_blur_draw() sit inside an
        `if` that never closed. Every other test here passed on that file, because
        they all read text (LL-077).
        """
        blocks, end_depth = _function_blocks(self.blur_src)
        self.assertEqual(
            [name for name, _ in blocks],
            ["menu_blur_wanted", "menu_blur_surface", "menu_blur_fail",
             "menu_blur_draw"],
            "scr_menu_blur no longer defines the four blur functions, in this order")
        for name, depth in blocks:
            self.assertEqual(
                depth, 0,
                "function %s() starts %d block(s) deep, so a brace in an earlier "
                "function never closed and this one is nested inside it - GML will "
                "not define it where the file reads like it does (LL-077)"
                % (name, depth))
        self.assertEqual(
            end_depth, 0,
            "scr_menu_blur closes with %d block(s) still open: the file does not "
            "parse as the blocks it is written in (LL-077)" % end_depth)


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class MonsterStateMachineTests(unittest.TestCase):
    """The monster flow is an enum + switch, and DEATH is one of its states.

    Before 2026-10-26 obj_mon was dispatched by  scr_runState(scr_zombie_emerge)
    with the state held as a script reference and "no state" written as -1
    (LL-004), and death was a flag polled inside scr_zombie_path.  Four
    consequences, each pinned below (LL-080):

    * a monster killed while EMERGING was never checked, because the emerge has
      no life test - so a corpse could stand up and walk;
    * the fall's destroy was a second clock derived from ZOMB_DIE_SECS, which
      agreed with the sprite only by coincidence;
    * Alarm_0 could hand a toppling corpse a new route, and path_start moves
      x/y from the engine;
    * nothing logged a transition, so "which state is that monster in?" had no
      answer in the log at all.

    These are text checks, which is the honest limit of a test that cannot run
    GML: they pin the SHAPE (one switch, one life check, one exit) that made all
    four possible.
    """

    def read(self, rel):
        return _code_only((PROJECT_ROOT / rel).read_text(encoding="utf-8-sig"))

    def test_the_state_machine_is_defined_exactly_once(self):
        """One enum, one definition of each function - a copy is a second truth."""
        enums = sum(1 for p in PROJECT_ROOT.rglob("*.gml")
                    if "enum ZOMB_STATE" in p.read_text(encoding="utf-8-sig"))
        self.assertEqual(1, enums, "enum ZOMB_STATE is defined %d times" % enums)
        for name in ("scr_zomb_state_name", "scr_zomb_request", "scr_zomb_begin",
                     "scr_zomb_step", "scr_zombie_die"):
            defs = sum(len(re.findall(r"\bfunction\s+%s\s*\(" % name,
                                      p.read_text(encoding="utf-8-sig")))
                       for p in PROJECT_ROOT.rglob("*.gml"))
            self.assertEqual(1, defs, "%s() is defined %d times" % (name, defs))
        # and the enum is used by name, never by number
        src = self.read(ZSTATE_REL)
        for state in ("EMERGE", "PATH", "DIE"):
            self.assertIn("ZOMB_STATE.%s" % state, src)

    def test_the_legacy_runner_is_gone_from_the_monster(self):
        """No script-reference dispatch, and no `state_time` left behind."""
        step = self.read(MON_STEP_REL)
        self.assertIn("scr_zomb_step();", step)
        self.assertNotIn("scr_runState", step)
        self.assertNotIn("scr_setupState", self.read(MON_CREATE_REL))
        # `zomb_state_time` is the new name; a bare `state_time` is the runner's
        for rel in (EMERGE_REL, ZPATH_REL, ZSTATE_REL, ZDIE_REL):
            self.assertNotRegex(self.read(rel), r"(?<![\w.])state_time", rel)

    def test_every_variable_a_state_reads_is_declared_in_create(self):
        """LL-002: a read must never be the first writer."""
        src = self.read(MON_CREATE_REL)
        for var in ("zomb_state", "zomb_state_next", "zomb_state_time",
                    "zomb_die_steps", "zomb_die_art", "zomb_die_prev",
                    "zomb_die_warned", "dying", "dying_time", "rig"):
            self.assertRegex(src, r"(?m)^%s\s*=" % var,
                             "%s is read by a state but not declared in Create" % var)



    def test_death_is_checked_before_the_dispatch(self):
        """D1: no state can miss a death, because the check precedes the switch."""
        src = self.read(ZSTATE_REL)
        body = src[src.index("function scr_zomb_step()"):]
        check = body.index("if(!dying && zomb_state != ZOMB_STATE.DIE")
        check_block = body[check:body.index("switch(zomb_state)")]
        self.assertIn("data[MON.life] <= 0", check_block)
        self.assertRegex(check_block, r"scr_zomb_death\(\);")
        self.assertRegex(check_block, r"return;",
                         "the kill must not fall through into the old state's body")
        # ... and the switch dispatches all three states, in one place
        switch = body[body.index("switch(zomb_state)"):]
        for state, fn in (("EMERGE", "scr_zombie_emerge"),
                          ("PATH", "scr_zombie_path"),
                          ("DIE", "scr_zombie_die")):
            self.assertRegex(switch, r"case ZOMB_STATE\.%s:\s+%s\(" % (state, fn),
                             "the switch does not dispatch %s" % state)

    def test_the_walking_state_no_longer_finishes_a_fall(self):
        """D1: the fall is a state, not a branch inside the walk."""
        src = self.read(ZPATH_REL)
        self.assertNotIn("scr_zomb_death", src)
        self.assertNotIn("if(dying)", src)

    def test_the_fall_ends_when_its_animation_ends(self):
        """D3+D1: the destroy watches the sheet, so no frame 0 is drawn again."""
        src = self.read(ZDIE_REL)
        self.assertIn("image_index < zomb_die_prev", src)
        self.assertIn("instance_destroy();", src)
        self.assertLess(src.index("dying_time++;"), src.index("instance_destroy();"),
                        "the exit is decided after this step's frame advance")
        entry = src[src.index("if(zomb_state_time == 0)"):]
        self.assertIn("path_end();", entry)
        self.assertIn("alarm[0] = -1;", entry)
        # the clocks are chosen, not assumed: a rig with no die slot falls back
        self.assertIn("image_number > 1 && image_speed > 0", entry)
        self.assertIn("dying_time >= zomb_die_steps", src)

    def test_the_fallback_clock_is_logged_and_backstopped(self):
        """A sheet that cannot animate must not leave an immortal corpse."""
        src = self.read(ZDIE_REL)
        self.assertIn("die art did not advance", src)
        self.assertIn("corpse gone", src)
        self.assertRegex(src, r"dying_time > zomb_die_steps")

    def test_the_kill_only_kills(self):
        """scr_zomb_death settles, requests the fall, and owns no animation."""
        src = self.read(ZDEATH_REL)
        self.assertIn("scr_zomb_request(ZOMB_STATE.DIE);", src)
        self.assertIn("if(dying) return;", src)      # the payout stays guarded
        self.assertNotIn("instance_destroy", src)    # the fall owns the exit
        self.assertNotIn("zomb_art_play(", src)      # the DIE entry plays it
        self.assertIn("path_end();", src)            # one step of follower left

    def test_the_corpse_gets_no_new_route(self):
        """D2: a tower brush arms Alarm_0; a corpse must refuse to be re-pathed."""
        self.assertRegex(self.read(MON_ALARM_REL), r"(?m)^if\s*\(dying\)\s*exit;")
        self.assertIn("alarm[0] = -1;", self.read(ZDEATH_REL))


# ---------------------------------------------------------------------------
# SCML-custom: every monster draws as its Spriter rig when its class has an
# entity; the pose is evaluated at half the room's rate, staggered.
# ---------------------------------------------------------------------------

SCML_REL = "scripts/scr_scml_rig/scr_scml_rig.gml"
SYSTEM_REL = "scripts/scr_scml_spriter_interface_system/scr_scml_spriter_interface_system.gml"
MON_DRAW_REL = "objects/obj_mon/Draw_0.gml"
MON_DIE_REL = "scripts/scr_zombie_die/scr_zombie_die.gml"
LEVEL_CONTROL_STEP_REL = "objects/_levelControl/Step_0.gml"
LEVEL_BOOT_REL = "scripts/scr_level_boot/scr_level_boot.gml"
MON_HP_DRAW_REL = "objects/obj_mon/Draw_73.gml"
SHADOW_DRAW_REL = "scripts/scr_drawLight/scr_drawLight.gml"
REFLECTION_DRAW_REL = "scripts/scr_drawReflections/scr_drawReflections.gml"
WATER_OBJECT_DRAW_REL = "objects/obj_water/Draw_0.gml"

ENTITY_PAIR_RE = re.compile(r'"([A-Za-z][A-Za-z-]*)":\s*"([A-Za-z][A-Za-z-]*)"')


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class ScmlRigAdapterTests(unittest.TestCase):
    """The SCML half answers first inside the rig seam; sheets stay the fallback.

    SCML-custom (2026-10-28).  ONE shared SpriterInterfaceSystem plays every
    monster's clips; the caller's seconds still win (set_speed stretches the
    clip - LL-030's shape), the pose evaluates at SCML_POSE_HZ with a
    per-monster phase (the "native 30fps" headroom), and a corpse is removed
    when its die clip reports playing == false.  SEVEN of the fifteen bank
    names differ from their SCML entities, so an explicit map is the only
    thing standing between a creature and a silent sheet fallback (LL-082's
    shape).  These tests pin that map and each seam behavior.
    """

    @classmethod
    def setUpClass(cls):
        cls.adapter = _code_only(
            (PROJECT_ROOT / SCML_REL).read_text(encoding="utf-8-sig"))
        cls.system = (PROJECT_ROOT / SYSTEM_REL).read_text(encoding="utf-8-sig")
        cls.roster = _code_only(
            (PROJECT_ROOT / ROSTER_REL).read_text(encoding="utf-8-sig"))
        cls.rows = _rows((PROJECT_ROOT / SPAWN_REL).read_text(encoding="utf-8-sig"))
        cls.mon_draw = _code_only(
            (PROJECT_ROOT / MON_DRAW_REL).read_text(encoding="utf-8-sig"))
        cls.die = _code_only(
            (PROJECT_ROOT / MON_DIE_REL).read_text(encoding="utf-8-sig"))
        cls.lc_step = _code_only(
            (PROJECT_ROOT / LEVEL_CONTROL_STEP_REL).read_text(encoding="utf-8-sig"))
        cls.boot = _code_only(
            (PROJECT_ROOT / LEVEL_BOOT_REL).read_text(encoding="utf-8-sig"))
        cls.hp_draw = _code_only(
            (PROJECT_ROOT / MON_HP_DRAW_REL).read_text(encoding="utf-8-sig"))
        cls.shadow_draw = _code_only(
            (PROJECT_ROOT / SHADOW_DRAW_REL).read_text(encoding="utf-8-sig"))
        cls.reflection_draw = _code_only(
            (PROJECT_ROOT / REFLECTION_DRAW_REL).read_text(encoding="utf-8-sig"))
        cls.water_object_draw = _code_only(
            (PROJECT_ROOT / WATER_OBJECT_DRAW_REL).read_text(encoding="utf-8-sig"))
        cls.title_create = _code_only(
            (PROJECT_ROOT / "objects/obj_titleZomb/Create_0.gml").read_text(encoding="utf-8-sig"))
        cls.title_step = _code_only(
            (PROJECT_ROOT / "objects/obj_titleZomb/Step_0.gml").read_text(encoding="utf-8-sig"))
        cls.title_draw = _code_only(
            (PROJECT_ROOT / "objects/obj_titleZomb/Draw_0.gml").read_text(encoding="utf-8-sig"))

    def _bank_names(self):
        return {name for (_bank, _i), (name, _sprites) in self.rows.items()}

    def _map_pairs(self):
        start = self.adapter.index("global.scml_entity_map = {")
        end = self.adapter.index("};", start)
        return ENTITY_PAIR_RE.findall(self.adapter[start:end])

    def test_every_bank_name_maps_to_an_scml_entity(self):
        """Seven of the fifteen bank names differ from their entities.

        A creature missing from the map resolves to "" and silently plays
        its sprite sheets while fourteen others are rigged - LL-082's shape
        with a different door.  The map must cover the whole bank, exactly.
        """
        pairs = self._map_pairs()
        self.assertTrue(pairs, "the entity map is empty or moved")
        self.assertEqual(
            self._bank_names(), {k for k, _v in pairs},
            "the entity map does not cover exactly the bank's creature names")
        renames = {k: v for k, v in pairs if k != v}
        self.assertGreaterEqual(
            len(renames), 5,
            "the import renamed creatures (7 of 15) - a map with almost no "
            "renames means the map was flattened back to identity and the "
            "renamed creatures are silently on sheets")

    def test_every_mapped_entity_exists_in_the_import(self):
        """A map value the collection does not carry is a silent fallback."""
        match = re.search(r"entities:\[([^\]]+)\]", self.system)
        self.assertIsNotNone(
            match, "the zombies collection's entity list moved in the import")
        imported = {s.strip().strip('"') for s in match.group(1).split(",")}
        for _bank, _entity in self._map_pairs():
            self.assertIn(
                _entity, imported,
                "the map points %r at entity %r, which the zombies "
                "collection does not carry" % (_bank, _entity))

    def test_the_seam_plays_scml_first_and_keeps_the_sheets(self):
        """mon_rig_play answers through the player, then through the sheets."""
        self.assertIn("zomb_scml_play(_rig, _anim, _secs)", self.roster,
                      "the SCML half no longer answers inside mon_rig_play")
        self.assertIn("is_string(_clip)", self.roster,
                      "the clip-name answer is no longer distinguished")
        self.assertIn("var _spr = mon_rig_slot(_rig, _anim);", self.roster,
                      "the sheet fallback is gone from mon_rig_play")

    def test_the_draw_branch_is_a_chain_not_two_draws(self):
        """A drawn rig must not also draw_self - one monster, one render."""
        self.assertIn("if(zomb_scml_draw(zomb_rig())){", self.mon_draw,
                      "the SCML draw branch is gone from obj_mon Draw_0")
        self.assertIn("} else if(inWater){", self.mon_draw,
                      "the water crop is not the rig branch's else - a "
                      "rigged monster in water would draw twice")

    def test_the_transform_carries_the_facing_sign_not_its_absolute(self):
        """A negative image_xscale mirrors the rig - right-to-left walking."""
        self.assertIn("image_xscale * _fix, image_yscale * _fix", self.adapter,
                      "set_transform no longer receives the instance's own "
                      "scale pair (with the per-entity fix riding it)")
        self.assertNotIn("abs(image_xscale)", self.adapter,
                         "the mirror was cleaned up into an absolute - "
                         "right-to-left walking would moonwalk")

    def test_one_update_owner_above_the_early_returns(self):
        """One zomb_scml_update per step, before CLEAR/FAILED bail out.

        Corpses keep playing their fall while the clear banner runs, so
        the single update call must sit above the early returns in
        _levelControl's Step.
        """
        idx = self.lc_step.index("zomb_scml_update();")
        self.assertLess(
            idx, self.lc_step.index("LEVEL_STATE.CLEAR"),
            "zomb_scml_update moved below the CLEAR/FAILED early return - "
            "corpses freeze during the clear banner")

    def test_the_pose_rate_is_half_the_room(self):
        """30hz pose, staggered by phase - the headroom the plan bought."""
        self.assertIn("#macro SCML_POSE_HZ 30", self.adapter,
                      "the pose rate is no longer half of 60")
        self.assertIn("set_pose_rate(_name, SCML_POSE_HZ, _phase)", self.adapter,
                      "players are no longer created with a staggered "
                      "half-rate pose")

    def test_the_corpse_clock_is_the_clips_end(self):
        """A rigged fall is removed when its clip reports playing == false."""
        self.assertIn("zomb_die_scml", self.die,
                      "the die state no longer knows which clock it runs on")
        self.assertIn("!_st.playing", self.die,
                      "the clip-end exit check is gone - rigged corpses "
                      "would wait for the backstop every time")

    def test_boot_resets_the_players(self):
        """Every room entry starts from an empty player list (LL-049)."""
        self.assertIn("zomb_scml_reset();", self.boot,
                      "scr_level_boot no longer resets the Spriter players - "
                      "a room_restart() inherits stale players")

    def test_the_scale_fix_is_measured_and_stamped_on_the_rig(self):
        """Rig-native height is normalized to the original walk sheet.

        The Spriter rigs were authored at a larger, per-entity-varying
        pixel scale than the sheets they replace (single appendage canvases
        run to 300px against whole walk sheets of 98-161px), so without a
        per-entity fix the creatures come out inconsistent with the sheet
        era and with each other.  The fix is MEASURED (a scratch player's
        posed footprint through get_part_world) against the sheet's ART
        bbox - never its padded canvas - and clamped, so a bad measurement
        cannot make a monster invisible or giant.
        """
        self.assertIn("zomb_scml_scale_fix(_s.scml, _s.walk)", self.roster,
                      "mon_rig_from no longer stamps the per-entity scale "
                      "fix on every rig it builds")
        self.assertIn("sprite_get_bbox_bottom(_sheet)", self.adapter,
                      "the fix is no longer anchored to the sheet's art "
                      "bbox - a canvas anchor would import the padding rows")
        self.assertIn("#macro SCML_FIX_MIN", self.adapter,
                      "the fix lost its clamp band - a bad measurement can "
                      "now make a monster invisible or giant")

    def test_the_draw_multiplies_the_instance_scale_by_the_fix(self):
        """The fix rides the same transform, after scale and facing sign."""
        self.assertIn("image_xscale * _fix, image_yscale * _fix", self.adapter,
                      "zomb_scml_draw no longer applies the scale fix - "
                      "rigged creatures render at their authored size")
        self.assertIn("is_real(_rig.scml_fix)", self.adapter,
                      "the fix read is unguarded (LL-002)")

    def test_the_title_zombie_is_rigged_and_owns_its_rooms_update(self):
        """rm_menu has no _levelControl: the one instance is the owner.

        The title zombie builds its rig directly (the roster only exists
        after level boot), re-asserts idle/walk per step like
        scr_zombie_path does (safe on looping clips, and it re-rigs after a
        stage boot reset), plays the grab ONCE and ends it on the clip -
        a per-step grab would restart the finished clip forever.
        """
        destroy = _code_only((PROJECT_ROOT /
                              "objects/obj_titleZomb/Destroy_0.gml"
                              ).read_text(encoding="utf-8-sig"))
        self.assertIn('mon_rig_from("Grumble-Mulch"', self.title_create,
                      "the title zombie no longer builds a rig - it cannot "
                      "draw rigged without one")
        self.assertIn("zomb_scml_update();", self.title_step,
                      "the title zombie is not its room's update owner - "
                      "rm_menu has no _levelControl, so its rig would "
                      "never advance")
        self.assertIn("mon_rig_play(rig, ZOMB_ANIM.idle, ANIM_SECONDS_ZOMBIE_IDLE)",
                      self.title_step,
                      "the idle state lost its seconds-based duration "
                      "(LL-072) or its rig call")
        self.assertIn("!_st.playing", self.title_step,
                      "the grab no longer ends on its clip - the title "
                      "zombie would grab forever (a per-step restart) or "
                      "never (no end check)")
        self.assertIn("if(zomb_scml_draw(rig)){", self.title_draw,
                      "the title zombie no longer draws through the rig "
                      "chain - no player, no mirror, no fix")
        self.assertIn("zomb_scml_remove();", destroy,
                      "the title zombie's player is not removed on "
                      "destroy - it ticks under the next room's update")

    def test_status_tint_reaches_every_spriter_part(self):
        """The runtime's c_white draw gets a per-monster status shader pass."""
        self.assertIn("status_tint()", self.adapter,
                      "rig draws no longer read the calling monster's status color")
        self.assertIn("shader_set(shd_scml_tint)", self.adapter,
                      "the SCML draw is not wrapped in its tint shader")
        self.assertIn("shader_set_uniform_color(_uniform, _tint, 1)", self.adapter,
                      "the status color is not supplied to the shader uniform")
        self.assertIn("shader_reset()", self.adapter,
                      "the SCML shader can leak into later draws")
        fragment = (PROJECT_ROOT / "shaders/shd_scml_tint/shd_scml_tint.fsh").read_text(
            encoding="utf-8-sig")
        self.assertIn("uniform vec4 tintColour", fragment)
        self.assertIn("* v_vColour * tintColour", fragment,
                      "the shader no longer preserves per-part alpha while tinting")

    def test_rigged_monsters_share_the_sheet_water_seam(self):
        """The top, submerged and mirrored passes clip at one world seam."""
        self.assertIn("SCML_DRAW_ABOVE", self.adapter)
        self.assertIn("gpu_get_scissor()", self.adapter)
        self.assertIn("gpu_set_scissor(_clip)", self.adapter)
        self.assertIn("zomb_scml_draw(rig, SCML_DRAW_SUBMERGED)", self.water_object_draw)
        self.assertIn("zomb_scml_draw(rig, SCML_DRAW_REFLECTION, _alpha)",
                      self.reflection_draw)
        self.assertIn("water_sink()", self.adapter,
                      "the rig seam no longer follows the shared origin-based waterline")
        self.assertIn("draw_self()", self.water_object_draw,
                      "sheet-backed monsters lost their original submerged fallback")

    def test_hp_bars_and_shadows_use_the_current_rig_footprint(self):
        """The 32x32 placeholder cannot size UI or shadows for a live rig."""
        self.assertIn("zomb_scml_bounds(rig)", self.hp_draw,
                      "the HP bar still reads bbox_* from the placeholder sprite")
        self.assertIn("zomb_scml_bounds(rig)", self.shadow_draw,
                      "the shadow box still reads sprite_width/height from the placeholder")
        self.assertIn("zomb_scml_part_alpha_bounds(_part)", self.adapter,
                      "the rig footprint stopped measuring painted part pixels")
        self.assertIn("bbox_left - 4", self.hp_draw,
                      "sheet-backed monsters lost their existing HP bar fallback")


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class BiomePropTests(unittest.TestCase):
    """The delivered scenery table is complete and keeps the route buildable."""

    @classmethod
    def setUpClass(cls):
        cls.src = _code_only((PROJECT_ROOT /
                              "scripts/scr_biome_props/scr_biome_props.gml"
                              ).read_text(encoding="utf-8-sig"))
        cls.level_start = _code_only((PROJECT_ROOT /
                                      "scripts/scr_level_start/scr_level_start.gml"
                                      ).read_text(encoding="utf-8-sig"))
        cls.tower_edit = _code_only((PROJECT_ROOT /
                                     "objects/obj_tower_edit/Step_0.gml"
                                     ).read_text(encoding="utf-8-sig"))

    def test_every_delivered_prop_is_in_its_biome_table(self):
        rows = re.findall(
            r"biome_prop_row\((spr_\w+),\s*BIOME\.(\w+),\s*"
            r"(\d+),\s*(\d+),\s*(\d+)\)", self.src)
        counts = {}
        for sprite, biome, size, weight, footprint in rows:
            counts[biome] = counts.get(biome, 0) + 1
            self.assertGreater(int(size), 0, "%s has no render size" % sprite)
            self.assertGreater(int(weight), 0, "%s has no selection weight" % sprite)
            self.assertGreater(int(footprint), 0, "%s has no grid footprint" % sprite)
            self.assertTrue(
                (PROJECT_ROOT / "sprites" / sprite / (sprite + ".yy")).is_file(),
                "%s is named by the prop table but is not a project sprite" % sprite)
        self.assertEqual(len(rows), 18, "the prop table dropped or duplicated delivered art")
        self.assertEqual(counts, {
            "SWAMP": 3, "DESERT": 3, "JUNGLE": 4,
            "GRAVEYARD": 6, "BLOOD_FIELDS": 2,
        }, "the biome table no longer matches the delivered sprite inventory")

    def test_props_are_stage_seeded_and_keep_off_the_route(self):
        self.assertIn("random_get_seed()", self.src,
                      "the spawner does not save the combat RNG state (LL-016)")
        self.assertIn("random_set_seed(_seed)", self.src)
        self.assertIn("random_set_seed(_previous_seed)", self.src)
        self.assertIn("biome_prop_route_clear(_x,_y,_path_pad)", self.src)
        self.assertIn("scr_resetDrawPath();", self.src,
                      "the visible path is not rebuilt after prop reservations")
        self.assertNotRegex(self.src, r"other\._(?:entry|scale|col|row|footprint|clear|mark_)")

    def test_stage_start_and_tower_placement_use_prop_reservations(self):
        self.assertIn("biome_props_spawn(_row.biome,_row.region,_row.stage)",
                      self.level_start,
                      "stage start does not scatter the current biome's props")
        self.assertLess(self.level_start.index("scr_resetDrawPath();"),
                        self.level_start.index("biome_props_spawn("),
                        "the route must exist before scenery placement")
        self.assertIn("biome_props_block_grid(placement_grid,grid_w,grid_h)",
                      self.tower_edit,
                      "tower placement can overlap reserved prop footprints")
        self.assertIn("depth = scr_depth_y(y)", self.src,
                      "prop instances do not use the shared ground depth sort")


