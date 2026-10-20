"""Fit a knob from SIM OUTCOMES, not from a ratio (card balance-fit-from-sim).

``gm balance project`` answers "is this stage in band WITH the numbers the game
has now?".  This answers the question the panel cannot: "which value of <knob>
puts these stages in band?" - by re-resolving the same stage with the knob moved
and measuring the same bites again.

Three rules make the answer worth having:

* **the knob moves on a COPY of the tables.**  ``model.resolve(t=...)`` takes a
table set in, so a sweep never writes to the project.  A sweep that edited the
GML would be a sweep that can leave the game broken when it is interrupted
(LL-009's rule, applied to data).
* **the band is the same one ``check`` uses.**  A candidate fits when every
measured stage is inside ``[FLOOR_BITE, CEILING_BITE]`` - so a value the ratio
likes but the model rejects is still rejected here.
* **it does not pick the price.**  That is a design decision.  It prints the
whole window that survives, so the decision is a choice INSIDE a measured range
instead of a guess, and names a middle-of-the-window value as a starting point.

The sim is the arbiter on outcomes (LL-042), but it costs a stage run per
candidate, so the closed form does the sweep and ``--sim`` confirms the
shortlist.  That ordering is deliberate: measure cheap, confirm expensive.
"""

from __future__ import annotations

from dataclasses import dataclass, field, replace
from typing import Callable, Iterable, List, Optional, Sequence

from . import model

#: the knobs a sweep may move, mapped to the Region field they name.  A closed
#: list: a typo must fail loudly rather than silently sweeping nothing.
PARAMS = {
    "curve_end": "curve_end",
    "curve_pow": "curve_pow",
    "wave_first": "wave_first",
    "wave_step": "wave_step",
}


@dataclass
class StageFit:
    """One stage measured at one candidate value."""

    stage: int
    worst: float                 # the hardest wave's bite
    easiest: float               # wave 1's bite
    lows: List[int] = field(default_factory=list)
    highs: List[int] = field(default_factory=list)
    cleared: Optional[bool] = None   # from the sim, when it ran
    leaks: Optional[int] = None

    @property
    def trivial_first(self) -> bool:
        """Is WAVE 1 itself below the floor?

        Reported, and deliberately NOT allowed to veto a fit.  Measured, wave
        one reads 0.11 at curve_end 10, 14 and 30 alike: the cap cannot move
        it, because it is the opening-money question `findings` already
        names (start money, the floor, or a tutorial wave - a human decides).
        A sweep that failed every candidate for a reason no candidate can
        fix would answer nothing."""
        return self.easiest < model.FLOOR_BITE

    @property
    def inside(self) -> bool:
        """In band, ignoring the trivial wave 1 (see trivial_first)."""
        hard_lows = [w for w in self.lows if w != 1]
        return (not hard_lows) and (not self.highs) and \
            (self.worst <= model.CEILING_BITE)


@dataclass
class Candidate:
    value: float
    stages: List[StageFit] = field(default_factory=list)

    @property
    def worst(self) -> float:
        return max((s.worst for s in self.stages), default=0.0)

    @property
    def lows(self) -> List[int]:
        """Stages with a LOW wave that is NOT just the trivial opener."""
        return [s.stage for s in self.stages if [w for w in s.lows if w != 1]]

    @property
    def highs(self) -> List[int]:
        return [s.stage for s in self.stages if s.highs or s.worst > model.CEILING_BITE]

    @property
    def inside(self) -> bool:
        return bool(self.stages) and all(s.inside for s in self.stages)

    @property
    def violations(self) -> int:
        return sum(len([w for w in s.lows if w != 1]) + len(s.highs)
                   for s in self.stages)


#: the middle of the band.  A stage pinned to either edge is one table edit away
#: from falling out of it, so "closest to the middle" is the robust pick, and the
#: whole window is printed anyway for a human to overrule.
TARGET = (model.FLOOR_BITE + model.CEILING_BITE) / 2


def values(start: float, stop: float, step: float) -> List[float]:
    """The candidate list.  Integer steps keep the numbers readable; a
    non-positive step is refused rather than silently producing one value."""
    if step <= 0:
        raise ValueError("step must be positive")
    out, v = [], start
    # a fixed number of iterations, not a `while v <= stop`: floats accumulate
    # error and the last candidate can vanish (the lesson LL-029 made about
    # equality tests against moving values).
    n = int(round((stop - start) / step)) + 1
    for _ in range(max(n, 0)):
        out.append(round(v, 6))
        v += step
    return out


def sweep(candidates: Iterable[float],
          measure: Callable[[float], Sequence[StageFit]]) -> List[Candidate]:
    """Run ``measure`` for every candidate.  Pure: it owns no state and writes
    nothing, which is what makes it testable without a GameMaker project."""
    return [Candidate(value=v, stages=list(measure(v))) for v in candidates]


def recommend(rows: Sequence[Candidate]) -> Optional[Candidate]:
    """The candidate to start from.

    Inside the band beats outside it; among the ones inside, closest to the
    middle wins.  With nothing inside, the fewest violations, then the closest to
    the band - never nothing, because "no value works, here is the least bad" is
    itself an answer (it means the knob is not the problem).
    """
    if not rows:
        return None
    inside = [r for r in rows if r.inside]
    if inside:
        return min(inside, key=lambda r: (abs(r.worst - TARGET), r.value))
    return min(rows, key=lambda r: (r.violations,
                                    max(0.0, model.FLOOR_BITE - r.worst),
                                    max(0.0, r.worst - model.CEILING_BITE),
                                    r.value))


def with_param(tables_obj, param: str, value: float, region: int):
    """A COPY of ``tables_obj`` with ``param`` set on one region.

    ``replace`` is the point: the caller's table set (and the game's files) are
    untouched, so a hundred candidates are a hundred copies and not a hundred
    edits.
    """
    if param not in PARAMS:
        raise ValueError(f"unknown param {param!r}; try {sorted(PARAMS)}")
    attr = PARAMS[param]
    regs = [replace(r, **{attr: value}) if r.region == region else r
            for r in tables_obj.regions]
    return replace(tables_obj, regions=regs)


def rows_for(candidate: Candidate) -> List[str]:
    out = []
    for s in candidate.stages:
        flags = []
        if s.lows:
            flags.append("LOW " + ",".join(str(w) for w in s.lows))
        if s.highs:
            flags.append("HIGH " + ",".join(str(w) for w in s.highs))
        sim = ""
        if s.cleared is not None:
            sim = f"  sim {'cleared' if s.cleared else 'LOST'} leaks {s.leaks}"
        out.append(f"      stage {s.stage:<2} w1 {s.easiest:>5.2f}  worst {s.worst:>5.2f}"
                   f"  {' '.join(flags) if flags else 'in band'}{sim}")
    return out
