"""The closed form: what a wave demands, and what the money can answer with.

This is a faithful port of the in-game diagnostic (``scripts/scr_curve``) so the
two can be compared line for line WITHOUT launching the game - which is what
makes the tester trustworthy: if it disagrees with the panel, one of them is
wrong, and the disagreement is found in a second rather than in a playtest.

    demand(w)  = count(w) * hp(w) / walk_seconds(w)
    supply(w)  = min(money_through(w) / price, slots) * placement_dps
    bite(w)    = demand / supply

The ``slots`` term is the ceiling money alone does not capture (economy.md 4.5):
money buys towers, but only so many cells can reach the route.  ``bite`` is a
RATIO and is deliberately kept - the panel's target band (floor 0.35, ceiling
0.90) is calibrated on it - but a ratio is not a game feel.  The sim
(:mod:`gm.balance.sim`) turns it into leaks, hearts and idle money, and those
are what the feel targets are written against.
"""

from __future__ import annotations

import math
from dataclasses import dataclass, field
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

from . import geometry, tables, terrain
from .geometry import LevelMap, Point
from .tables import Difficulty, Monster, Region, Stage, TableError, Tables, Tower

#: the panel's target band: wave 1 must not be trivial, the last wave survivable
FLOOR_BITE = 0.35
CEILING_BITE = 0.90

#: a fresh save's four towers - the loadout the tutorial is balanced against
STARTERS = ("Daisy Pusher", "Burning Ivy", "Slender Mandrake", "Pina Collider")


# ---------------------------------------------------------------------------
# the scene: one stage, resolved to numbers
# ---------------------------------------------------------------------------
@dataclass
class Scene:
    """A stage with its route, its pool and its loadout already worked out."""

    tables: Tables
    region: Region
    stage: Stage
    difficulty: Difficulty
    terrains: List[terrain.Terrain] = field(default_factory=list)
    routes: List[List[Point]] = field(default_factory=list)
    route_lengths: List[float] = field(default_factory=list)
    loadout: List[Tower] = field(default_factory=list)
    tower: Optional[Tower] = None
    tower_range: float = 0.0
    slots: int = 0
    slot_cells: List[geometry.Cell] = field(default_factory=list)
    monsters: List[Monster] = field(default_factory=list)
    bosses: List[Monster] = field(default_factory=list)
    floor_level: int = 1
    clover_damage: float = 0.0
    clover_rate: float = 0.0

    @property
    def waves(self) -> int:
        return self.tables.waves(self.stage.region, self.stage.stage)

    @property
    def route_length(self) -> float:
        """The length a projection should use: the mean over the spawns.

        Every monster rolls its own spawn (``obj_mon/Create_0``:
        ``irandom(instance_number(obj_spawn) - 1)``), so one route is a sample,
        not the stage.  ``spawns="first"`` reproduces the panel, which measures
        ``instance_find(obj_spawn, 0)``, so the two can be compared.
        """
        if not self.route_lengths:
            return 0.0
        return sum(self.route_lengths) / len(self.route_lengths)

    def route_spread(self) -> Tuple[float, float]:
        if not self.route_lengths:
            return (0.0, 0.0)
        return (min(self.route_lengths), max(self.route_lengths))

    def longest_route(self) -> List[Point]:
        return max(self.routes, key=geometry.polyline_length)

    # -- the loadout ------------------------------------------------------
    def placement(self) -> Tuple[Tower, float, float]:
        """The best dps-per-dollar tower a placement can buy: (tower, dps, price).

        Nothing here is a second source of truth: the dps comes from the roster
        and ``tower_data_at_level``, so a ladder or price change moves this the
        moment it lands.
        """
        best: Optional[Tuple[float, Tower, float]] = None
        for t in self.loadout:
            if t.price <= 0:
                continue
            dps = self.tables.dps_at_level(t, self.floor_level,
                                           self.clover_damage, self.clover_rate)
            density = dps / t.price
            if best is None or density > best[0]:
                best = (density, t, dps)
        if best is None:
            raise TableError("no tower in the loadout has a price above zero")
        return (best[1], best[2], best[1].price)

    def rung_density(self) -> float:
        """DPS per unit money from buying ALL FOUR rungs (economy.md 4.6).

        Half of the inequality the rung price has to satisfy; the other half is
        :meth:`placement`'s dps-per-dollar.  When this is the smaller of the
        two, upgrading is dominated by simply placing another tower - which is
        the live finding, printed by ``gm balance project``.
        """
        tower, dps_floor, price = self.placement()
        dps_cap = self.tables.dps_at_level(tower, self.tables.cap(0),
                                           self.clover_damage, self.clover_rate)
        total = price * self.tables.constants.rung_total
        return (dps_cap - dps_floor) / total if total > 0 else 0.0


def resolve(root, *, region: int = 1, stage: int = 1, difficulty: str = "Normal",
            loadout: Optional[Sequence[str]] = None, spawns: str = "all",
            z: float = 6.0, room: str = "rm_test", t: Optional[Tables] = None,
            m: Optional[LevelMap] = None) -> Scene:
    """Build the scene for one stage: tables, map, route, slots, loadout.

    ``t`` and ``m`` exist so a caller can hand in a MODIFIED table set - which
    is how a sweep (or a test) asks "what would the curve have done at the old
    ceiling?" without editing the game.  Passing a table set in is the only way
    to move a knob, and it is deliberate that no argument mutates the game's
    files.
    """
    t = t if t is not None else tables.load(root)
    m = m if m is not None else geometry.load_map(root, room=room,
                                                  cell=t.constants.cell)
    reg = t.region(region)
    st = t.stage(region, stage)
    diff = t.difficulty(difficulty)
    names = list(loadout) if loadout is not None else list(STARTERS)


    scene = Scene(
        tables=t, region=reg, stage=st, difficulty=diff,
        terrains=[terrain.Terrain(z, "uniform")],
        loadout=[t.tower(n) for n in names],
        monsters=[t.monster(i) for i in st.spawns],
        bosses=[t.monster(i, boss=True) for i in st.bosses],
        floor_level=t.floor(0),
    )

    starts = m.spawns[:1] if spawns == "first" else list(m.spawns)
    for s in starts:
        pts = geometry.route_points(m, s, m.despawn)
        if pts is None:
            raise TableError(f"{room}: no route from spawn {s} to {m.despawn}")
        scene.routes.append(pts)
        scene.route_lengths.append(geometry.polyline_length(pts))

    # the tower whose range sets the slot ceiling, and the slots themselves.
    # The LONGEST route is used: it is the one that needs covering, so its slot
    # count is the honest ceiling rather than an average nobody plays.
    tower, _, _ = scene.placement()
    _, _, rng = t.data_at_level(tower, scene.floor_level,
                                scene.clover_damage, scene.clover_rate)
    scene.tower, scene.tower_range = tower, rng
    scene.slot_cells = geometry.slots(m, scene.longest_route(), rng)
    scene.slots = len(scene.slot_cells)
    return scene


# ---------------------------------------------------------------------------
# demand
# ---------------------------------------------------------------------------
def mean_field(bank: Sequence[Monster], pool: Iterable[int], attr: str,
               fallback: float) -> float:
    """The mean of one field over a pool of indices - ``scr_curve_pool_mean``."""
    vals = []
    for i in pool:
        if 0 <= i < len(bank):
            v = getattr(bank[i], attr, None)
            if isinstance(v, (int, float)):
                vals.append(float(v))
    return sum(vals) / len(vals) if vals else fallback


@dataclass(frozen=True)
class Demand:
    wave: int
    boss: bool
    count: int
    hp: float
    walk: float
    req: float


def demand(scene: Scene, wave: int, ter: Optional[terrain.Terrain] = None,
           panel: bool = False) -> Demand:
    """What ``wave`` sends, and the DPS needed to stop all of it.

    A boss wave is ONE creature from ``spawn_boss`` (``scr_level_spawn``:
    ``MAX = 1``), which is why projecting it from the ordinary pool understates
    it by roughly an order of magnitude (LL-036).
    """
    ter = ter or scene.terrains[0]
    t = scene.tables
    boss = t.is_boss_wave(scene.stage.region, scene.stage.stage, wave)

    if boss:
        # THE STAGE'S OWN BOSSES, not the whole bank (2026-10-24).  This read
        # `t.bosses` - every boss in the game - which was invisible while the
        # bank held two and is a 2.5x error once it holds six: stage 1-1's boss
        # waves were modelled on the mean of ALL six (210 life) instead of the
        # two the row names (Tusk-A-Lot and Sub-Zero, 82 life).  A bank's mean
        # is not a stage's demand; `scene.bosses` is built from the row.
        bank = list(scene.bosses) or list(t.bosses)
        pool = list(range(len(bank)))
        count = 1
    else:
        bank, pool = scene.monsters, list(range(len(scene.monsters)))
        count = t.wave_count(mean_field(bank, pool, "spawn_count", 5), wave,
                             scene.difficulty.count)

    life = mean_field(bank, pool, "life", 7)
    speed = mean_field(bank, pool, "speed", 1)
    hp = life * t.life_mult(scene.stage.region, wave, scene.waves) * scene.difficulty.hp
    walk = terrain.walk_seconds(scene.route_length, ter.mean_z, wave, speed,
                                scene.difficulty.speed, t.constants.fps,
                                panel=panel)
    return Demand(wave, boss, count, hp, walk,
                  (count * hp) / walk if walk > 0 else 0.0)


def money_through(scene: Scene, wave: int) -> float:
    """Money EARNED by the time ``wave`` starts: ``scr_curve_money_through``.

    The starting purse (difficulty-scaled) plus every kill up to and including
    that wave.  A kill pays ``base x kill_money_ramp(wave) x the money column``,
    and the fraction is CARRIED rather than rounded - which is what makes the
    column exact: rounding each kill is what made Hard's x1.25 a no-op on a base
    of 1, so Hard earned 1.02x Normal while paying for 1.5x the hp (LL-042).

    A boss pays ``wave + 1`` - ``scr_level_spawn`` overwrites the bank's own
    ``kill_money`` - and takes the column and the carry but NOT the ramp,
    because its base is already wave-scaled (``scr_kill_money``'s third
    argument, in difficulty_data.gml).
    """
    t, diff = scene.tables, scene.difficulty
    pool = list(range(len(scene.monsters)))
    money = t.constants.start_money * diff.life
    carry = 0.0
    kill_money = mean_field(scene.monsters, pool, "kill_money", 1)
    spawn_count = mean_field(scene.monsters, pool, "spawn_count", 5)
    slope = t.constants.kill_money_slope
    for k in range(1, wave + 1):
        if t.is_boss_wave(scene.stage.region, scene.stage.stage, k):
            n, base, ramp = 1, k + 1, 1.0
        else:
            n = t.wave_count(spawn_count, k, diff.count)
            base, ramp = kill_money, 1 + slope * max(0, k - 1)
        # n kills of the same value: n successive floor-with-carry applications
        # pay the same whole dollars as one floor over the total
        want = n * (base * ramp * diff.money) + carry
        money += math.floor(want)
        carry = want - math.floor(want)
    return money


@dataclass(frozen=True)
class Supply:
    """What a purse can field: this tool's figure, and the panel's, side by side.

    ``avail`` is coverage-weighted (a tower only shoots what is in its range);
    ``panel_avail`` is ``scr_curve``'s kinder ``min(money / price, slots) x
    best_placement_dps``, kept so the two can be compared rather than argued
    about.  The gap is the answer to "why did I leak with a full wrap".
    """

    money: float
    price: float
    placeable: int
    slots: int
    dps: float
    avail: float
    avail_multi: float
    panel_avail: float
    buys: int


def supply(scene: Scene, wave: int, cov=None) -> Supply:
    """What the money earned by ``wave`` can actually field.

    The plan comes from :mod:`gm.balance.policy` - the same greedy the sim
    spends with, so the projection and the run cannot disagree about what a
    purse buys (LL-021).  Imported here, not at module scope, only because
    ``policy`` needs :class:`Scene` from this module.
    """
    from . import policy as policy_mod

    _, dps, price = scene.placement()
    money = money_through(scene, wave)
    bought = policy_mod.plan(scene, money, cov=cov)
    placeable = int(min(money // price if price else 0, scene.slots))
    return Supply(money, price, placeable, scene.slots, dps, bought.effective,
                  bought.effective_multi, placeable * dps, len(bought.buys))


@dataclass(frozen=True)
class Row:
    wave: int
    boss: bool
    count: int
    hp: float
    walk: float
    req: float
    money: float
    buys: int
    slots: int
    avail: float
    avail_multi: float
    panel_avail: float
    bite: float
    panel_bite: float
    verdict: str


def row(scene: Scene, wave: int, ter: Optional[terrain.Terrain] = None,
        panel: bool = False, cov=None) -> Row:
    """One projected wave, with the panel's own verdict band."""
    d = demand(scene, wave, ter, panel=panel)
    s = supply(scene, wave, cov=cov)
    bite = (d.req / s.avail) if s.avail > 0 else -1.0
    panel_bite = (d.req / s.panel_avail) if s.panel_avail > 0 else -1.0
    if bite < 0:
        verdict = "?"
    elif wave <= 1:
        verdict = "ok" if bite >= FLOOR_BITE else "LOW"
    else:
        verdict = "ok" if bite <= CEILING_BITE else "HIGH"
    return Row(wave, d.boss, d.count, d.hp, d.walk, d.req, s.money, s.buys,
               s.slots, s.avail, s.avail_multi, s.panel_avail, bite, panel_bite,
               verdict)




def interesting_waves(scene: Scene) -> List[int]:
    """Wave 1, the first mid-stage boss, and the last - the panel's choice."""
    out = [1]
    for w in range(2, scene.waves):
        if scene.tables.is_boss_wave(scene.stage.region, scene.stage.stage, w):
            out.append(w)
            break
    out.append(scene.waves)
    return sorted(set(out))


def project(scene: Scene, ter: Optional[terrain.Terrain] = None,
            waves: Optional[Iterable[int]] = None, cov=None) -> List[Row]:
    which = list(waves) if waves is not None else interesting_waves(scene)
    return [row(scene, w, ter, cov=cov) for w in which]


def all_waves(scene: Scene, ter: Optional[terrain.Terrain] = None,
              cov=None) -> List[Row]:
    return [row(scene, w, ter, cov=cov) for w in range(1, scene.waves + 1)]


def first_high(scene: Scene, ter: Optional[terrain.Terrain] = None,
               cov=None) -> Optional[Row]:
    """The first wave the projection calls HIGH - the wall, if there is one."""
    for r in all_waves(scene, ter, cov=cov):
        if r.verdict == "HIGH":
            return r
    return None



