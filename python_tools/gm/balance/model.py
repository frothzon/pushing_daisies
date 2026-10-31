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
from dataclasses import dataclass, field, replace
from typing import Dict, Iterable, List, Mapping, Optional, Sequence, Tuple

from . import geometry, tables, terrain
from .geometry import LevelMap, Point
from .tables import (Difficulty, Monster, Region, Stage, TableError, Tables,
                     Tower, TowerStats)

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
    mastery: int = 0
    floor_level: int = 1
    growth_spec_rank: int = 0
    clover_damage: float = 0.0
    clover_rate: float = 0.0
    clover_crit_chance: float = 0.0
    clover_crit_damage: float = 0.0
    clover_upgrade_discount: float = 0.0
    clover_kill_money: float = 0.0
    clover_starting_money: int = 0
    clover_boss_reward: float = 0.0
    clover_max_life: int = 0
    clover_life_loss_reduction: float = 0.0
    clover_regen: int = 0
    clover_boss_saves: int = 0

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

    @property
    def starting_money(self) -> int:
        """The GML opening purse, including its difficulty and clover bonuses."""
        return (round(self.tables.constants.start_money * self.difficulty.life)
                + self.clover_starting_money)

    def expected_crit_multiplier(self, tower: Tower,
                                 level: Optional[int] = None) -> float:
        """Expected direct-hit multiplier after tower traits and clover tech."""
        stats = self.tower_stats(
            tower, self.floor_level if level is None else level)
        return 1.0 + stats.crit_chance * (stats.crit_damage - 1.0)

    def tower_stats(self, tower: Tower, level: int) -> TowerStats:
        return self.tables.tower_stats(
            tower, level, self.clover_damage, self.clover_rate,
            self.clover_crit_chance, self.clover_crit_damage,
            self.growth_spec_rank)

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
            stats = self.tower_stats(t, self.floor_level)
            dps = (stats.damage * stats.fire_rate * stats.targets
                   * stats.projectiles * self.expected_crit_multiplier(t))
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
        cap_stats = self.tower_stats(tower, self.tables.cap(self.mastery))
        dps_cap = (cap_stats.damage * cap_stats.fire_rate * cap_stats.targets
                    * cap_stats.projectiles * self.expected_crit_multiplier(
                        tower, self.tables.cap(self.mastery)))
        total = (price * self.tables.constants.rung_total
                 * (1.0 - self.clover_upgrade_discount))
        return (dps_cap - dps_floor) / total if total > 0 else 0.0


def resolve(root, *, region: int = 1, stage: int = 1, difficulty: str = "Normal",
            loadout: Optional[Sequence[str]] = None, spawns: str = "all",
            z: float = 6.0, mastery: int = 0, growth_spec_rank: int = 0,
            specializations: Optional[Mapping[str, str]] = None,
            clover_damage: float = 0.0, clover_rate: float = 0.0,
            clover_crit_chance: float = 0.0,
            clover_crit_damage: float = 0.0,
            clover_upgrade_discount: float = 0.0,
            clover_kill_money: float = 0.0,
            clover_starting_money: int = 0,
            clover_boss_reward: float = 0.0,
            clover_max_life: int = 0,
            clover_life_loss_reduction: float = 0.0,
            clover_regen: int = 0,
            clover_boss_saves: int = 0,
            room: str = "rm_test", t: Optional[Tables] = None,
            m: Optional[LevelMap] = None) -> Scene:
    """Build the scene for one stage: tables, map, route, slots, loadout.

    ``t`` and ``m`` exist so a caller can hand in a MODIFIED table set - which
    is how a sweep (or a test) asks "what would the curve have done at the old
    ceiling?" without editing the game.  Passing a table set in is the only way
    to move a knob, and it is deliberate that no argument mutates the game's
    files.
    """
    t = t if t is not None else tables.load(root)
    if not isinstance(mastery, int) or isinstance(mastery, bool) or not 0 <= mastery <= 5:
        raise TableError("mastery must be an integer from 0 through 5")
    if (not isinstance(growth_spec_rank, int) or isinstance(growth_spec_rank, bool)
            or not 0 <= growth_spec_rank <= t.constants.growth_spec_rank_max):
        raise TableError("growth_spec_rank must be an integer from 0 through "
                         f"{t.constants.growth_spec_rank_max}")
    if specializations is None:
        specializations = {}
    if not isinstance(specializations, Mapping):
        raise TableError("specializations must map tower names to path keys")
    fractions = (
        ("clover_damage", clover_damage, 0.35),
        ("clover_rate", clover_rate, 0.05),
        ("clover_crit_chance", clover_crit_chance, 0.05),
        ("clover_crit_damage", clover_crit_damage, 0.25),
        ("clover_upgrade_discount", clover_upgrade_discount, 0.25),
        ("clover_kill_money", clover_kill_money, 0.20),
        ("clover_boss_reward", clover_boss_reward, 0.25),
        ("clover_life_loss_reduction", clover_life_loss_reduction, 0.25),
    )
    for label, value, ceiling in fractions:
        if (not isinstance(value, (int, float)) or isinstance(value, bool)
                or not math.isfinite(value) or value < 0
                or (ceiling is not None and value > ceiling)):
            limit = f" and at most {ceiling:g}" if ceiling is not None else ""
            raise TableError(f"{label} must be a finite fraction from 0{limit}")
    integers = (
        ("clover_starting_money", clover_starting_money, 15),
        ("clover_max_life", clover_max_life, 40),
        ("clover_regen", clover_regen, 5),
        ("clover_boss_saves", clover_boss_saves, 5),
    )
    for label, value, ceiling in integers:
        if (not isinstance(value, int) or isinstance(value, bool)
                or value < 0 or value > ceiling):
            raise TableError(f"{label} must be an integer from 0 through {ceiling}")
    m = m if m is not None else geometry.load_map(root, room=room,
                                                  cell=t.constants.cell)
    reg = t.region(region)
    st = t.stage(region, stage)
    diff = t.difficulty(difficulty)
    names = list(loadout) if loadout is not None else list(STARTERS)

    selected: Dict[str, str] = {}
    for name, key in specializations.items():
        if not isinstance(name, str) or not isinstance(key, str):
            raise TableError("specialization names and path keys must be strings")
        t.specialization(name, key)
        selected[name] = key
    resolved_loadout = [replace(t.tower(name), specialization=selected.get(name, ""))
                        for name in names]


    scene = Scene(
        tables=t, region=reg, stage=st, difficulty=diff,
        terrains=[terrain.Terrain(z, "uniform")],
        loadout=resolved_loadout,
        monsters=[t.monster(i) for i in st.spawns],
        bosses=[t.monster(i, boss=True) for i in st.bosses],
        mastery=mastery,
        floor_level=t.floor(mastery),
        growth_spec_rank=growth_spec_rank,
        clover_damage=float(clover_damage),
        clover_rate=float(clover_rate),
        clover_crit_chance=float(clover_crit_chance),
        clover_crit_damage=float(clover_crit_damage),
        clover_upgrade_discount=float(clover_upgrade_discount),
        clover_kill_money=float(clover_kill_money),
        clover_starting_money=clover_starting_money,
        clover_boss_reward=float(clover_boss_reward),
        clover_max_life=clover_max_life,
        clover_life_loss_reduction=float(clover_life_loss_reduction),
        clover_regen=clover_regen,
        clover_boss_saves=clover_boss_saves,
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
    rng = scene.tower_stats(tower, scene.floor_level).range
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
    money = scene.starting_money
    carry = 0.0
    kill_money = mean_field(scene.monsters, pool, "kill_money", 1)
    spawn_count = mean_field(scene.monsters, pool, "spawn_count", 5)
    slope = t.constants.kill_money_slope
    for k in range(1, wave + 1):
        if t.is_boss_wave(scene.stage.region, scene.stage.stage, k):
            n, base, ramp = 1, k + 1, 1.0
            bonus = scene.clover_kill_money + scene.clover_boss_reward
        else:
            n = t.wave_count(spawn_count, k, diff.count)
            base, ramp = kill_money, 1 + slope * max(0, k - 1)
            bonus = scene.clover_kill_money
        # n kills of the same value: n successive floor-with-carry applications
        # pay the same whole dollars as one floor over the total
        want = n * (base * (1 + bonus) * ramp * diff.money) + carry
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



