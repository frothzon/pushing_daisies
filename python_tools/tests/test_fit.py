"""Tests for ``gm balance fit`` - the knob sweep (card balance-fit-from-sim).

Two properties matter more than the arithmetic:

* **the sweep never moves the game.**  ``with_param`` works on a copy, so a
  hundred candidates are a hundred copies and not a hundred edits (LL-009's
  rule applied to data).  ``test_with_param_leaves_the_caller_alone`` pins it.
* **wave 1 does not veto a fit.**  Measured, wave 1 sits at 0.11 whatever the
  cap is: it is the opening-money question ``findings`` already names, not
  something a cut-off can fix.  A sweep that failed every candidate for a reason
  no candidate can fix would answer nothing.
"""

import sys
import unittest
from dataclasses import dataclass
from pathlib import Path

TESTS_DIR = Path(__file__).resolve().parent
TOOLS_DIR = TESTS_DIR.parent
REPO_ROOT = TOOLS_DIR.parent
sys.path.insert(0, str(TOOLS_DIR))

from gm.balance import fit, model, tables  # noqa: E402


def find_project_root():
    for candidate in [REPO_ROOT, *REPO_ROOT.parents]:
        if any(candidate.glob("*.yyp")):
            return candidate
    return None


PROJECT_ROOT = find_project_root()


@dataclass
class _Region:
    region: int
    curve_end: float = 13.0


@dataclass
class _Tables:
    regions: list


class ValueTests(unittest.TestCase):
    def test_a_window_is_inclusive_at_both_ends(self):
        self.assertEqual([10, 12, 14], fit.values(10, 14, 2))

    def test_a_single_point_window_is_one_candidate(self):
        self.assertEqual([13], fit.values(13, 13, 2))

    def test_a_non_positive_step_is_refused(self):
        with self.assertRaises(ValueError):
            fit.values(0, 10, 0)


class StageFitTests(unittest.TestCase):
    def test_a_trivial_wave_one_does_not_veto_a_fit(self):
        s = fit.StageFit(stage=1, worst=0.55, easiest=0.11, lows=[1])
        self.assertTrue(s.trivial_first)
        self.assertTrue(s.inside)

    def test_a_low_wave_after_one_vetoes(self):
        s = fit.StageFit(stage=2, worst=0.50, easiest=0.40, lows=[3])
        self.assertFalse(s.inside)

    def test_a_high_wave_vetoes(self):
        s = fit.StageFit(stage=1, worst=1.10, easiest=0.40, highs=[4])
        self.assertFalse(s.inside)

    def test_worst_over_the_ceiling_vetoes_even_with_nothing_flagged(self):
        s = fit.StageFit(stage=1, worst=model.CEILING_BITE + 0.05, easiest=0.40)
        self.assertFalse(s.inside)


class CandidateTests(unittest.TestCase):
    def test_inside_needs_every_measured_stage(self):
        good = fit.StageFit(1, 0.55, 0.11, lows=[1])
        bad = fit.StageFit(2, 1.10, 0.40, highs=[5])
        self.assertTrue(fit.Candidate(15, [good]).inside)
        self.assertFalse(fit.Candidate(15, [good, bad]).inside)

    def test_an_empty_candidate_is_not_inside(self):
        self.assertFalse(fit.Candidate(15, []).inside)

    def test_violations_ignore_the_trivial_opener(self):
        c = fit.Candidate(15, [fit.StageFit(1, 0.55, 0.11, lows=[1])])
        self.assertEqual(0, c.violations)


class SweepTests(unittest.TestCase):
    def test_one_measurement_per_candidate_in_order(self):
        seen = []

        def measure(v):
            seen.append(v)
            return [fit.StageFit(1, v / 100, 0.11)]

        rows = fit.sweep([10, 20], measure)
        self.assertEqual([10, 20], seen)
        self.assertEqual([10, 20], [r.value for r in rows])


class RecommendTests(unittest.TestCase):
    def _c(self, value, worst):
        return fit.Candidate(value, [fit.StageFit(1, worst, 0.11, lows=[1])])

    def test_the_middle_of_the_window_wins(self):
        rows = [self._c(10, 0.37), self._c(15, 0.55), self._c(20, 0.73)]
        self.assertEqual(15, fit.recommend(rows).value)

    def test_with_nothing_in_band_the_least_bad_wins(self):
        rows = [fit.Candidate(10, [fit.StageFit(1, 1.40, 0.50, highs=[3])]),
                fit.Candidate(12, [fit.StageFit(1, 0.95, 0.50)])]
        self.assertEqual(12, fit.recommend(rows).value)

    def test_an_empty_sweep_has_no_recommendation(self):
        self.assertIsNone(fit.recommend([]))


class WithParamTests(unittest.TestCase):
    def setUp(self):
        self.t = _Tables([_Region(1), _Region(2)])

    def test_it_moves_the_named_region_only(self):
        t2 = fit.with_param(self.t, "curve_end", 20, 1)
        self.assertEqual(20, t2.regions[0].curve_end)
        self.assertEqual(13, t2.regions[1].curve_end)

    def test_with_param_leaves_the_caller_alone(self):
        fit.with_param(self.t, "curve_end", 20, 1)
        self.assertEqual(13, self.t.regions[0].curve_end)

    def test_an_unknown_param_is_refused(self):
        with self.assertRaises(ValueError):
            fit.with_param(self.t, "wave_count", 5, 1)


class ParamNameTests(unittest.TestCase):
    """A knob that does not exist on Region would fail at the FIRST sweep,
    far from the typo - so the names are checked against the dataclass once."""

    def test_every_param_is_a_region_field(self):
        from gm.balance.tables import Region
        fields = set(Region.__dataclass_fields__)
        for name, attr in fit.PARAMS.items():
            self.assertIn(attr, fields, f"fit.PARAMS[{name!r}] is not a Region field")


class RowTests(unittest.TestCase):
    def test_it_says_what_the_sim_did_when_it_ran(self):
        c = fit.Candidate(15, [fit.StageFit(1, 0.55, 0.11, lows=[1],
                                           cleared=True, leaks=0)])
        text = "\n".join(fit.rows_for(c))
        self.assertIn("w1", text)
        self.assertIn("sim cleared", text)

    def test_it_says_in_band_when_nothing_is_flagged(self):
        c = fit.Candidate(15, [fit.StageFit(1, 0.55, 0.40)])
        self.assertIn("in band", "\n".join(fit.rows_for(c)))


@unittest.skipIf(PROJECT_ROOT is None, "no GameMaker project above this file")
class SweepOnTheProjectTests(unittest.TestCase):
    """The sweep reads the real tables - and never edits them."""

    def test_a_higher_cap_makes_the_worst_wave_harder(self):
        t = tables.load(PROJECT_ROOT)
        before = t.region(1).curve_end

        def measure(v):
            scene = model.resolve(PROJECT_ROOT, region=1, stage=1,
                                  t=fit.with_param(t, "curve_end", v, 1))
            rows = model.all_waves(scene)
            return [fit.StageFit(1, max(r.bite for r in rows), rows[0].bite)]

        rows = fit.sweep([10, 30], measure)
        self.assertLess(rows[0].worst, rows[1].worst)
        self.assertEqual(before, t.region(1).curve_end,
                         "the sweep must not move the game's own tables")


if __name__ == "__main__":  # pragma: no cover
    unittest.main()
