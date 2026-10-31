"""How the money gets spent - and what a tower is actually worth.

THE PANEL'S ARITHMETIC IS TOO KIND, AND THIS IS WHERE IT SHOWS.  ``scr_curve``
computes

    available = min(money / price, slots) * best_placement_dps

with ``best_placement_dps`` taken from the tower with the highest dps per
dollar (``scr_curve_dps_per_money``).  That is a Pina Collider at $100 - so on
wave 1, where the player holds the starting $25, the formula buys NOTHING and
the row reads `?`.  In the game the same $25 buys five Daisy Pushers.  And a
placed tower does not project its whole dps down the entire route: it fires
only while a monster is inside its range, which is
:func:`gm.balance.geometry.covered_length` of the route.

So a tower is worth

    effective dps = nominal dps x coverage,   coverage = covered_len / route_len

and the supply a purse can field is the best SUM of those it can buy:

    while money is left and free cells remain:
        buy the (cell, tower) with the highest effective dps per dollar

That is the "optimal grid pattern" question the plan set out to answer, and it
is a budgeted maximum-coverage problem - which is why the greedy is the right
tool (a density greedy on a coverage objective carries the usual 1 - 1/e
bound), and why it is honest to call the result a CEILING: it is what perfect
play with perfect information could field, not what a human does.

Both numbers are reported side by side by ``gm balance project``: the panel's
kind formula and this one.  The gap is the answer to "why did I leak at wave 10
with a full wrap".
"""

from __future__ import annotations

import math

from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple

from . import geometry
from .geometry import Cell, LevelMap
from .model import Scene
from .tables import Tower


@dataclass(frozen=True)
class Buy:
    """One purchase: a tower, in a cell, at a level, and what it is worth.

    TWO dps figures, because ``damage x rate x targets x projectiles`` is a
    claim about CONGESTION:

    * ``dps`` is the single-target figure with the fire CYCLE charged (LL-040) -
      what the tower does when one monster is in range, which is the normal case
      on a long route.  It is the only figure a budget should be ranked by, and
      it is what :func:`plan` ranks on;
    * ``dps_multi`` is the roster's own ``targets x projectiles`` on its
      NOMINAL dps - what
      the shop card and the in-game panel print, and what
      :attr:`effective_multi` has to reproduce when it models the panel.

    They are only equal when enough monsters are inside the range at once to
    fill the target cap.  On stage 1-1 the monsters spawn 0.5 s apart and walk
    ~1.26 px a step, so they are roughly 37px apart along an 1840px route: a
    75px range holds two or three, not ten.  :attr:`effective` is therefore
    built on the SINGLE-target figure - the honest one - and the sim is the
    arbiter when the route is genuinely busy.
    """

    cell: Cell
    tower: Tower
    level: int
    price: float
    dps: float                    # single-target, CYCLE CHARGED, at this level
    coverage: float               # 0 < c <= 1, the share of the route it shoots
    dps_multi: float = 0.0        # damage x rate x targets x projectiles

    @property
    def effective(self) -> float:
        """The dps that actually reaches the route, singly and honestly."""
        return self.dps * self.coverage

    @property
    def effective_multi(self) -> float:
        """The dps if the target cap were always full - the panel's belief."""
        return (self.dps_multi or self.dps) * self.coverage

    def describe(self) -> str:
        return (f"{self.tower.name} L{self.level} at {self.cell[0]},{self.cell[1]} "
                f"${self.price:g} dps {self.dps:g} x cov {self.coverage:.3f} "
                f"= {self.effective:.1f}")



class Coverage:
    """Memo for "how much of the route can this cell shoot".

    The answer depends only on (cell, range), and ranges repeat across the
    roster and the ladder, so the cache is keyed on a rounded range.  Without
    it the greedy would re-walk the route for every candidate cell and every
    purchase - which is the difference between a sweep that finishes and one
    that does not.
    """

    def __init__(self, map_: LevelMap, route: Sequence[geometry.Point],
                 length: float) -> None:
        self.map = map_
        self.route = route
        self.length = length or 1.0
        self._cache: Dict[Tuple[Cell, float], float] = {}
        # the same key, holding the route SAMPLE INDICES this cell can
        # shoot - what union coverage subtracts once a stretch is taken
        self._imask: Dict[Tuple[Cell, float], frozenset] = {}
        self._pts: Optional[List[Tuple[float, float]]] = None

    def of(self, cell: Cell, reach: float) -> float:
        key = (cell, round(float(reach), 1))
        hit = self._cache.get(key)
        if hit is None:
            px = geometry.covered_length(self.route, cell, reach, self.map.cell)
            hit = min(1.0, px / self.length) if self.length > 0 else 0.0
            self._cache[key] = hit
        return hit

    #: route sample spacing.  Matches geometry.covered_length's 4px walk,
    #: so the two estimators describe the same route to the same precision.
    SAMPLE_STEP = 4.0

    def _samples(self) -> List[Tuple[float, float]]:
        """The route as points every SAMPLE_STEP px, built once.

        :meth:`of` uses the exact segment length and this uses samples, so
        they are two estimators of one quantity - the test suite pins them
        together (they must agree to within a few percent) instead of one
        being defined in terms of the other, because :meth:`of` is the
        figure the in-game panel is matched against and must not move.
        """
        pts = self._pts
        if pts is None:
            pts = []
            for i in range(len(self.route) - 1):
                ax, ay = self.route[i]
                bx, by = self.route[i + 1]
                seg = math.hypot(bx - ax, by - ay)
                steps = max(1, int(seg / self.SAMPLE_STEP))
                for k in range(steps):
                    t = k / steps
                    pts.append((ax + (bx - ax) * t, ay + (by - ay) * t))
            pts.append(tuple(self.route[-1]))
            self._pts = pts
        return pts

    def indices(self, cell: Cell, reach: float) -> frozenset:
        """Which route samples this cell can shoot - the UNION key.

        Same centre convention as :func:`geometry.covered_length`: a cell is
        named by its grid index and its centre sits half a cell up and left.
        """
        key = (cell, round(float(reach), 1))
        hit = self._imask.get(key)
        if hit is None:
            cs = self.map.cell
            cx, cy = cell[0] * cs - cs * 0.5, cell[1] * cs - cs * 0.5
            r2 = float(reach) * float(reach)
            hit = frozenset(
                i for i, (px, py) in enumerate(self._samples())
                if (px - cx) ** 2 + (py - cy) ** 2 <= r2)
            self._imask[key] = hit
        return hit

    def marginal(self, cell: Cell, reach: float,
                 taken: frozenset) -> float:
        """The share of the route this cell shoots that NOTHING ELSE does.

        This is what makes the greedy spread: a second tower on an already
        covered stretch is worth almost nothing, so the next dollar goes
        where the route is still bare.
        """
        ids = self.indices(cell, reach)
        if not ids:
            return 0.0
        n = len(self._samples()) or 1
        return len(ids - taken) / float(n)


def coverage_for(scene: Scene, route: Sequence[geometry.Point] = (),
                 cache: Optional[Coverage] = None) -> Coverage:
    """The scene's coverage memo, over its LONGEST route unless told otherwise.

    The longest route is used deliberately: it is the one a player has to hold,
    so its coverage is the honest ceiling rather than an average nobody plays.
    """
    if cache is not None:
        return cache
    r = list(route) if route else scene.longest_route()
    return Coverage(geometry.load_map(scene.tables.root,
                                     cell=scene.tables.constants.cell),
                    r, geometry.polyline_length(r))


def rung_price(tower: Tower, level: int, scene: Scene,
               mastery: Optional[int] = None) -> float:
    """What the NEXT rung costs, or -1 at the cap (``tower_upgrade_price``)."""
    if mastery is None:
        mastery = scene.mastery
    return scene.tables.rung_price(tower.price, level, mastery,
                                   scene.clover_upgrade_discount)


@dataclass
class Plan:
    """What a purse bought, and what those towers are worth on the route."""

    buys: List[Buy]
    spent: float

    @property
    def effective(self) -> float:
        """The dps that actually reaches the route, summed over the buys."""
        return sum(b.effective for b in self.buys)

    @property
    def effective_multi(self) -> float:
        """The same sum under the panel's belief that target caps are full."""
        return sum(b.effective_multi for b in self.buys)

    @property
    def nominal(self) -> float:
        """The dps the shop card would print - always >= :attr:`effective`."""
        return sum(b.dps for b in self.buys)


    @property
    def cells(self) -> List[Cell]:
        return [b.cell for b in self.buys]

    def explain(self) -> str:
        return " | ".join(b.describe() for b in self.buys) or "(nothing)"


def plan(scene: Scene, money: float, cov: Optional[Coverage] = None,
         taken: Iterable[Cell] = (), allow_rungs: bool = False,
         clover_damage: Optional[float] = None,
         clover_rate: Optional[float] = None,
         limit: Optional[int] = None, spread: bool = False,
         standing: Sequence[Tuple[Cell, Tower, int]] = (),
         candy_damage: float = 0.0, candy_rate: float = 0.0,
         candy_range: float = 0.0, candy_crit_chance: float = 0.0,
         candy_crit_damage: float = 0.0) -> Plan:
    """Spend ``money`` on the best effective-dps-per-dollar the route allows.

    The greedy is the whole model of "optimal": every candidate is scored by
    ``dps x coverage / price``, and the best is bought while money and free
    cells last.  Towers stack additively (each one fires at whatever is in its
    own range), so the objective is a weighted maximum-coverage - the problem a
    density greedy is the standard tool for.

    ``allow_rungs`` turns the upgrade into a competitor: a rung is bought only
    when its effective-dps-per-dollar beats the best new placement, which is
    economy.md 4.6's inequality evaluated rather than argued about.

    ``spread`` changes WHAT coverage means, and it is the answer to a measured
    defect: additive coverage DOUBLE-COUNTS.  Two towers on the same stretch of
    route both score that stretch, so the greedy piles every tower into the
    first high-coverage block and leaves the last 40% of the route bare (the
    ``balance-sim-policy`` card).  A monster only dies once, so the honest
    objective is UNION coverage: a cell is worth the share of the route that
    NOTHING ELSE already shoots.  That is submodular, which is exactly the
    setting where a density greedy carries its 1 - 1/e bound.

    ``standing`` lists towers ALREADY on the board, as ``(cell, tower, level)``.
    Without it a caller that re-plans every wave can only ever buy NEW towers,
    because a rung on an existing one is invisible to it - which is why the sim
    never upgraded anything.  Their cells count as taken.

    The ``candy_*`` inputs are the currently active shared-axis bonuses. They
    adjust the ranking and the build's estimate together; :class:`Sim` supplies
    them from the same live-wave timer used by combat, so an expired Candy
    cannot keep influencing purchases.

    Returns a :class:`Plan`.  Never overspends, never reuses a cell.
    """
    if clover_damage is None:
        clover_damage = scene.clover_damage
    if clover_rate is None:
        clover_rate = scene.clover_rate
    cov = coverage_for(scene, cache=cov)
    standing = list(standing)
    used: Set[Cell] = set(taken) | {c for c, _t, _l in standing}
    placed: Dict[Cell, Buy] = {}
    spent = 0.0

    # the union of route samples already covered - only used when spread=True
    covered = frozenset()

    def stats_at(t, lvl):
        return scene.tables.tower_stats(
            t, lvl, clover_damage, clover_rate,
            scene.clover_crit_chance, scene.clover_crit_damage,
            scene.growth_spec_rank)

    def crit_at(t, lvl):
        stats = stats_at(t, lvl)
        chance = min(1.0, max(0.0, stats.crit_chance + candy_crit_chance))
        damage = max(1.0, stats.crit_damage + candy_crit_damage)
        return 1.0 + chance * (damage - 1.0)

    def dps_at(t, lvl):
        stats = stats_at(t, lvl)
        return scene.tables.cycle.dps(
            stats.damage * (1.0 + candy_damage),
            stats.fire_rate * (1.0 + candy_rate), targets=1,
            projectiles=stats.projectiles) * crit_at(t, lvl)

    def card_dps_at(t, lvl):
        stats = stats_at(t, lvl)
        return (stats.damage * stats.fire_rate * stats.targets
                * stats.projectiles * (1.0 + candy_damage)
                * (1.0 + candy_rate) * crit_at(t, lvl))

    def rng_at(t, lvl):
        return stats_at(t, lvl).range * (1.0 + candy_range)

    # hoisted: the floor-level dps and range of every tower in the loadout.
    # `dps` is SINGLE-target with the fire CYCLE charged - the honest ranking
    # key (LL-040) - and `dps_multi` keeps the roster's own `targets x
    # projectiles` nominal,
    # because that is the panel's belief and `effective_multi` has to model it.
    #
    # The ranking key MUST be the delivered figure: the cycle costs a fast
    # tower proportionally more than a slow one (1.97x on a Daisy Pusher
    # against 1.16x on a Cannon Tulip), so ranking on nominal multi-hit DPS
    # would order the roster wrongly and the greedy would buy the wrong tower.
    options = []
    for t in scene.loadout:
        if t.price <= 0:
            continue
        dps = dps_at(t, scene.floor_level)
        multi = card_dps_at(t, scene.floor_level)
        options.append((t, dps, multi, rng_at(t, scene.floor_level)))

    # what is on the board, and what each of those is worth right now.  ONE
    # dict, so a rung can never be offered twice for the same cell (a standing
    # tower and a just-placed one are the same entry).
    #   cell -> [tower, level, dps, coverage, range]
    onboard: Dict[Cell, list] = {}
    for cell, t, lvl in standing:
        rng = rng_at(t, lvl)
        onboard[cell] = [t, lvl, dps_at(t, lvl), cov.of(cell, rng), rng]
        covered |= cov.indices(cell, rng)

    while True:
        if limit is not None and len(placed) >= limit:
            break
        purse = money - spent
        best: Optional[Tuple[float, Cell, Buy, float]] = None

        # -- a new tower in a free cell ----------------------------------
        for cell in scene.slot_cells:
            if cell in used:
                continue
            for t, dps, multi, rng in options:
                if t.price > purse:
                    continue
                c = cov.marginal(cell, rng, covered) if spread else cov.of(cell, rng)
                eff = dps * c
                if eff <= 0:
                    continue
                density = eff / t.price
                if best is None or density > best[0]:
                    best = (density, cell, Buy(cell, t, scene.floor_level,
                                               t.price, dps, c, multi), rng)

        # -- a rung, on anything already standing ------------------------
        if allow_rungs:
            for cell, cur in onboard.items():
                t, lvl, cur_dps, c_cov, rng = cur
                price = rung_price(t, lvl, scene, scene.mastery)
                if price < 0 or price > purse:
                    continue
                nxt = lvl + 1
                dps = dps_at(t, nxt)
                gain = (dps - cur_dps) * c_cov
                if gain <= 0:
                    continue
                density = gain / price
                if best is None or density > best[0]:
                    best = (density, cell, Buy(
                        cell, t, nxt, price, dps, c_cov,
                        card_dps_at(t, nxt)), rng)

        if best is None:
            break
        _, cell, buy, rng = best
        placed[cell] = buy
        onboard[cell] = [buy.tower, buy.level, buy.dps, buy.coverage, rng]
        used.add(cell)
        covered |= cov.indices(cell, rng)
        spent += buy.price

    return Plan(list(placed.values()), spent)
