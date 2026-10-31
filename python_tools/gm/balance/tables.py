"""The game's balance tables, read out of GML.

Standard library only, like the rest of ``gm``.  The parser here is small on
purpose: the tables are literal calls (``region_row(1, "Grass", ...)``,
``tower_entry("Daisy Pusher", [...], 5, scr_towerData(...), 0, 0)``), so a
tokenizer that understands strings, comments and nesting is enough - there is no
need to evaluate GML.

Every failure is loud.  A table that cannot be read raises :class:`TableError`
naming the file and what was expected, because a tester that silently falls back
to a guessed number is worse than no tester: it will report a curve the game
does not have.
"""

from __future__ import annotations

import math
import re
from dataclasses import dataclass, field, replace
from pathlib import Path
from typing import Any, Dict, List, NamedTuple, Optional, Sequence, Tuple


class TableError(RuntimeError):
    """A table could not be read.  Always names the file and the expectation."""


class Call(NamedTuple):
    """A parsed GML call: ``name(arg, arg, ...)``."""

    name: str
    args: List[Any]


# ---------------------------------------------------------------------------
# the GML mini-parser
# ---------------------------------------------------------------------------
def strip_comments(src: str) -> str:
    """Remove ``//`` and ``/* */`` comments, leaving string literals alone.

    Strings are left alone because a comment marker inside one is text, not a
    comment - and because arg-splitting must not trip over a comma in a name.
    """
    out: List[str] = []
    i, n = 0, len(src)
    in_str = False
    while i < n:
        ch = src[i]
        if in_str:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(src[i + 1])
                i += 2
                continue
            if ch == '"':
                in_str = False
            i += 1
            continue
        if ch == '"':
            in_str = True
            out.append(ch)
            i += 1
            continue
        if ch == "/" and i + 1 < n and src[i + 1] == "/":
            j = src.find("\n", i)
            i = n if j < 0 else j
            continue
        if ch == "/" and i + 1 < n and src[i + 1] == "*":
            j = src.find("*/", i + 2)
            i = n if j < 0 else j + 2
            continue
        out.append(ch)
        i += 1
    return "".join(out)


def _matching(text: str, start: int) -> int:
    """Index of the ``)`` / ``]`` / ``}`` that closes ``text[start]``."""
    pairs = {")": "(", "]": "[", "}": "{"}
    opening = text[start]
    closing = {v: k for k, v in pairs.items()}.get(opening)
    if closing is None:
        raise TableError(f"{opening!r} is not an opener")
    depth = 0
    i, n = start, len(text)
    in_str = False
    while i < n:
        ch = text[i]
        if in_str:
            if ch == "\\":
                i += 2
                continue
            if ch == '"':
                in_str = False
        elif ch == '"':
            in_str = True
        elif ch == opening:
            depth += 1
        elif ch == closing:
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise TableError(f"unbalanced {opening!r} at offset {start}")


def split_args(text: str) -> List[str]:
    """Split a call's argument list on top-level commas."""
    parts: List[str] = []
    depth = 0
    current: List[str] = []
    in_str = False
    i, n = 0, len(text)
    while i < n:
        ch = text[i]
        if in_str:
            current.append(ch)
            if ch == "\\" and i + 1 < n:
                current.append(text[i + 1])
                i += 2
                continue
            if ch == '"':
                in_str = False
            i += 1
            continue
        if ch == '"':
            in_str = True
            current.append(ch)
        elif ch in "([{":
            depth += 1
            current.append(ch)
        elif ch in ")]}":
            depth -= 1
            current.append(ch)
        elif ch == "," and depth == 0:
            parts.append("".join(current))
            current = []
        else:
            current.append(ch)
        i += 1
    tail = "".join(current).strip()
    if tail or parts:
        parts.append(tail)
    return [p.strip() for p in parts if p.strip() != ""]


_NUMBER_RE = re.compile(r"^-?\d+$")
_FLOAT_RE = re.compile(r"^-?(?:\d+\.\d*|\.\d+|\d+)(?:[eE][-+]?\d+)?$")
_CALL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\(")




# ---------------------------------------------------------------------------
# finding things in a file
# ---------------------------------------------------------------------------
def find_calls(src: str, name: str) -> List[Call]:
    """Every ``name(...)`` call in ``src``, as :class:`Call` objects.

    The *definition* is matched too (``function region_row(...)``), so callers
    filter on the shape of the first argument - a definition's arguments are
    identifiers, a table row's are literals.
    """
    out: List[Call] = []
    pattern = re.compile(r"(?<![A-Za-z0-9_])" + re.escape(name) + r"\s*\(")
    for m in pattern.finditer(src):
        open_paren = m.end() - 1
        close = _matching(src, open_paren)
        out.append(Call(name, [parse_value(p)
                               for p in split_args(src[open_paren + 1:close])]))
    return out


def find_array_after(src: str, marker: str) -> List[Any]:
    """The first ``[...]`` literal after ``marker``, parsed."""
    at = src.find(marker)
    if at < 0:
        raise TableError(f"marker {marker!r} not found")
    start = src.find("[", at)
    if start < 0:
        raise TableError(f"no array literal after marker {marker!r}")
    stop = _matching(src, start)
    return parse_value(src[start:stop + 1])


def _read(path: Path) -> str:
    if not path.exists():
        raise TableError(f"missing file: {path}")
    return strip_comments(path.read_text(encoding="utf-8", errors="replace"))


# ---------------------------------------------------------------------------
# the rows
# ---------------------------------------------------------------------------
@dataclass(frozen=True)
class Region:
    """One biome's curve (region_data.gml)."""

    region: int
    name: str
    biome: str
    seeds: int
    wave_first: int
    wave_step: int
    curve_end: float
    curve_pow: float
    boss_every: int


@dataclass(frozen=True)
class Difficulty:
    """One column of difficulty_data.gml."""

    name: str
    seeds: float
    hp: float
    speed: float
    count: int
    money: float
    life: float


@dataclass(frozen=True)
class Stage:
    """One authored stage row (stage_data.gml)."""

    region: int
    stage: int
    seeds: int
    spawns: Tuple[int, ...]
    bosses: Tuple[int, ...]
    par_spend: int
    par_time: int


@dataclass(frozen=True)
class Monster:
    """One creature (scr_setupSpawning.gml -> scr_makeMonster)."""

    name: str
    speed: float
    life: float
    kill_score: int
    kill_money: int
    spawn_count: int
    boss: bool = False


@dataclass(frozen=True)
class HitStatus:
    """One on-hit status from ``tower_trait_table()`` in the game."""

    kind: str
    chance: float
    mult: float
    amount: float
    seconds: float


@dataclass(frozen=True)
class Tower:
    """One roster entry (tower_roster.gml)."""

    name: str
    price: float
    range: float
    damage: float
    fire_rate: float
    targets: int
    unlock: int
    gate: int
    crit_chance: float = 0.05
    crit_damage: float = 1.5
    statuses: Tuple[HitStatus, ...] = ()
    projectiles: int = 1
    money_bonus: float = 0.0
    wave_income: float = 0.0
    specialization: str = ""

    @property
    def dps(self) -> float:
        """Nominal DPS - ``damage x rate x targets x projectiles``.

        It is an UPPER BOUND: it assumes every shot lands on a full set of
        targets.  What the run actually delivers is measured by the sim, and
        the gap between the two is the interesting number.
        """
        return self.damage * self.fire_rate * self.targets * self.projectiles


@dataclass(frozen=True)
class SpecializationTier:
    """One tier from ``tower_spec_table()`` in the game."""

    damage: float = 0.0
    rate: float = 0.0
    range: float = 0.0
    crit: float = 0.0
    crit_damage: float = 0.0
    targets: int = 0
    projectiles: int = 0
    knockback: float = 0.0
    money: float = 0.0
    income: float = 0.0
    statuses: Tuple[HitStatus, ...] = ()


@dataclass(frozen=True)
class SpecializationPath:
    """A tower's named path and its three authored tiers."""

    tower: str
    key: str
    tiers: Tuple[SpecializationTier, ...]


@dataclass(frozen=True)
class TowerStats:
    """All level-dependent stats the game resolves for one tower."""

    damage: float
    fire_rate: float
    range: float
    targets: int
    projectiles: int
    crit_chance: float
    crit_damage: float
    knockback: float
    money: float
    income: float
    tier_limit: int
    statuses: Tuple[HitStatus, ...]


@dataclass(frozen=True)
class CandyRecipe:
    """A permanent Candy recipe and its level formula, read from GML."""

    id: str
    tier: int
    cost: int
    effect: str
    step: float
    gate: str
    # field -> (base, per-level step, divisor). A positive divisor represents
    # the Gob's one extra frozen wave per three levels.
    formulas: Tuple[Tuple[str, float, float, int], ...]

    def magnitude(self, level: int) -> Dict[str, float]:
        level = min(10, max(1, int(level)))
        steps = level - 1
        out: Dict[str, float] = {}
        for name, base, slope, divisor in self.formulas:
            out[name] = (base + math.floor(steps / divisor)
                         if divisor > 0 else base + steps * slope)
        return out


@dataclass(frozen=True)
class Ladder:
    """One rung of the tower level table."""

    level: int
    damage: float
    fire_rate: float
    range: float


@dataclass(frozen=True)
class Constants:
    """The run constants, each read from the place that owns it."""

    fps: int = 60
    start_money: float = 25
    start_life: int = 20
    cell: int = 32
    load_max: float = 12
    spawn_gap_frames: float = 30.0      # scr_level_spawn: wait_timer = _fps * 0.5
    wave_gap_frames: float = 354.0      # scr_setupSpawning: _fps * 5.9
    start_message_seconds: float = 3.0  # scr_level_start: level_state_time >= _fps * 3
    count_div: int = 5                  # scr_level_spawn: wave_count div 5
    # ---- the wave counter's seed (card hud-wave-offbyone, LL-044) ----------
    # `STATINV.waves` is seeded in _levelControl/Create_0 and raised by
    # scr_level_spawn as each wave STARTS, so during wave N it reads
    # `seed + N`.  Seeded at 1 it read N+1, which made every mid-wave reader -
    # the speed ramp in scr_zomb_pathSpeed above all - compute for the NEXT
    # wave.  Read out of the GML in load(), so a revert moves the tester too.
    wave_seed: int = 0
    rung_costs: Tuple[float, ...] = (0.50, 0.75, 1.00, 1.50)
    mastery_cap_base: int = 5           # tower_cap()   = 5 + mastery
    mastery_floor_base: int = 1         # tower_floor() = 1 + mastery
    sell_refund: float = 0.60
    # ---- the tower fire CYCLE (LL-040).  A shot is NOT one fire period: the
    # idle wait adds time_offset (a stagger) and the attack is followed by a
    # return animation.  Both of these are read out of obj_tower/Create_0 in
    # load(), so the tester cannot hold a private opinion about either.
    tower_offset_range: Tuple[int, int] = (1, 8)    # time_offset = irandom_range(1,8)
    tower_return_seconds: float = 0.25              # anim_seconds[TOWER_ANIM.return]
    # ---- the SWING CAP (card tower-firing-cooldown, LL-054) ---------------
    # A fire rate is a COOLDOWN that ticks in every state; the attack ART is
    # capped at this many seconds, so a slow tower STRIKES instead of winding
    # up for its whole fire period (Pina Collider: 600 frames, ten seconds -
    # longer than a zombie stays in range, so it never fired at all).  Read
    # out of tower_levels.gml in load(), so a retune moves the sim with it.
    tower_swing_seconds: float = 0.35               # tower_swing_seconds()
    # ---- what a kill PAYS (card kill-money-ramp, LL-042) -------------------
    # The payout is `base x ramp(wave) x the difficulty column`, with the
    # fraction CARRIED rather than rounded.  One literal in one function
    # (kill_money_slope) so tuning it moves the tester with it; `load()` reads
    # it, and `gm balance check` fails if it stops being readable.
    kill_money_slope: float = 0.06
    zombie_die_seconds: float = 0.8
    candy_frame_hz: int = 60
    candy_base_seconds: float = 30.0
    candy_duration_per_rank: float = 0.10
    candy_duration_costs: Tuple[int, ...] = (10, 20, 40, 80, 160, 320,
                                             640, 1280, 2560, 5120)
    specialization_level_one: int = 3
    specialization_level_two: int = 4
    specialization_signature_level: int = 5
    growth_spec_unlock_rank: int = 1
    growth_spec_rank_max: int = 5
    specialization_bonus_per_rank: float = 0.01
    specialization_bonus_cap: float = 0.05

    @property
    def rung_count(self) -> int:
        return len(self.rung_costs)

    @property
    def rung_total(self) -> float:
        """Base prices to take a tower from its floor to its cap (3.75)."""
        return sum(self.rung_costs)


# ---------------------------------------------------------------------------
# the whole table set
# ---------------------------------------------------------------------------
# ---------------------------------------------------------------------------
# the fire cycle (LL-040)
# ---------------------------------------------------------------------------
@dataclass(frozen=True)
class Cycle:
    """How long one shot really takes - and why the shop card overstates it.

    :attr:`Tower.dps` is ``damage x rate x targets x projectiles``, which
    assumes a tower fires every ``1 / fire_rate`` seconds forever. The code
    does not. One shot
    is

        idle wait     time_offset frames      (scr_tower_normal - a STAGGER)
        attack        fps/fire_rate frames    (scr_tower_shoot)
        return        0.25 s of art           (scr_tower_return)

    so the period is ``fps/fire_rate + offset + return`` and the delivered rate
    is LOWER than the card's - by ~1.3x for a slow tower and ~2.0x for a fast
    one.  That gap is not a constant: it grows with ``fire_rate``, so it
    re-orders the roster.  Which is why this is a table here rather than a
    caveat in a comment.

    It also carries the size of the bug fixed on 2026-10-13: ``scr_tower_normal``
    used to wait a WHOLE extra fire period, so the period was
    ``2 x fps/fire_rate + offset + return`` (:meth:`double_counted_frames` is
    that extra period, and it is what the "before" column of the fix measures
    against).
    """

    fps: int
    offset_lo: int
    offset_hi: int
    return_seconds: float

    @property
    def offset_mean(self) -> float:
        """The mean of ``irandom_range(lo, hi)`` - the stagger, in frames.

        It is a per-tower roll (``obj_tower/Create_0``), so the mean is the
        expected cost of one shot; the spread is what keeps a row of towers from
        firing in lockstep, which is the whole point of it.
        """
        return (self.offset_lo + self.offset_hi) / 2.0

    @property
    def return_frames(self) -> float:
        return self.return_seconds * self.fps

    @property
    def overhead_frames(self) -> float:
        """The frames a shot costs ON TOP of its own fire period."""
        return self.offset_mean + self.return_frames

    def nominal_period(self, fire_rate: float) -> float:
        """The card's period: ``fps / fire_rate`` frames."""
        return self.fps / fire_rate if fire_rate > 0 else float("inf")

    def period(self, fire_rate: float) -> float:
        """Frames between two shots, as the code actually runs it."""
        if fire_rate <= 0:
            return float("inf")
        return self.nominal_period(fire_rate) + self.overhead_frames

    def rate(self, fire_rate: float) -> float:
        """Shots per second, delivered."""
        period = self.period(fire_rate)
        if period in (0, float("inf")):
            return 0.0
        return self.fps / period

    def dps(self, damage: float, fire_rate: float, targets: int = 1,
            projectiles: int = 1) -> float:
        """Delivered dps, with the cycle charged."""
        return damage * self.rate(fire_rate) * targets * projectiles

    def double_counted_frames(self, fire_rate: float) -> float:
        """The extra fire period the pre-LL-040 cycle waited."""
        return self.nominal_period(fire_rate)


@dataclass
class Tables:
    """Every number the tester needs, each with the file it came from.

    Mutable on purpose: the sweep moves one knob by rebuilding this with
    :func:`dataclasses.replace`, so a swept value is a *different table*, not a
    global edit - and the un-swept run cannot be contaminated by the swept one.
    """

    root: Path
    regions: List[Region] = field(default_factory=list)
    difficulties: List[Difficulty] = field(default_factory=list)
    stages: List[Stage] = field(default_factory=list)
    monsters: List[Monster] = field(default_factory=list)
    bosses: List[Monster] = field(default_factory=list)
    towers: List[Tower] = field(default_factory=list)
    candies: Dict[str, CandyRecipe] = field(default_factory=dict)
    specializations: Dict[str, Dict[str, SpecializationPath]] = field(default_factory=dict)
    ladder: List[Ladder] = field(default_factory=list)
    constants: Constants = field(default_factory=Constants)
    status_cc: Dict[str, Dict[str, float]] = field(default_factory=dict)
    sources: Dict[str, str] = field(default_factory=dict)

    # -- lookups ----------------------------------------------------------
    def region(self, number: int) -> Region:
        for r in self.regions:
            if r.region == number:
                return r
        raise TableError(f"no region {number} in region_data()")

    def difficulty(self, name: str) -> Difficulty:
        wanted = name.strip().lower()
        for d in self.difficulties:
            if d.name.lower() == wanted:
                return d
        raise TableError(f"no difficulty {name!r}; have "
                         + ", ".join(d.name for d in self.difficulties))

    def stage(self, region: int, number: int) -> Stage:
        for s in self.stages:
            if s.region == region and s.stage == number:
                return s
        raise TableError(f"no stage {region}-{number} in stage_data()")

    def has_stage(self, region: int, number: int) -> bool:
        return any(s.region == region and s.stage == number for s in self.stages)

    def tower(self, name: str) -> Tower:
        for t in self.towers:
            if t.name == name:
                return t
        raise TableError(f"no tower {name!r} in tower_roster()")

    def candy(self, candy_id: str) -> CandyRecipe:
        try:
            return self.candies[candy_id]
        except KeyError as err:
            raise TableError(f"no Candy recipe {candy_id!r} in candy_recipe_table()") from err

    def specialization(self, tower: str, key: str) -> SpecializationPath:
        try:
            return self.specializations[tower][key]
        except KeyError as err:
            choices = ", ".join(self.specializations.get(tower, {}))
            if not choices:
                raise TableError(f"no specialization paths for {tower!r}") from err
            raise TableError(f"no specialization {key!r} for {tower!r}; have {choices}") from err

    def specialization_tier_limit(self, level: int, growth_spec_rank: int = 0) -> int:
        """The tier gate in ``tower_spec_tier_limit()``."""
        if level < self.constants.specialization_level_one:
            return 0
        if level >= self.constants.specialization_signature_level:
            return 3
        if level >= self.constants.specialization_level_two:
            return (3 if growth_spec_rank >= self.constants.growth_spec_unlock_rank
                    else 2)
        return 1

    def specialization_strength(self, growth_spec_rank: int = 0) -> float:
        rank = min(self.constants.growth_spec_rank_max,
                   max(0, int(growth_spec_rank)))
        return 1.0 + min(
            self.constants.specialization_bonus_cap,
            self.constants.specialization_bonus_per_rank * rank)

    def tower_stats(self, tower: Tower, level: int,
                    clover_damage: float = 0.0, clover_rate: float = 0.0,
                    clover_crit_chance: float = 0.0,
                    clover_crit_damage: float = 0.0,
                    growth_spec_rank: int = 0) -> TowerStats:
        """Resolve ladder, Clover, and selected specialization effects together."""
        damage, rate, reach = self.data_at_level(
            tower, level, clover_damage, clover_rate)
        limit = self.specialization_tier_limit(level, growth_spec_rank)
        selected = (self.specialization(tower.name, tower.specialization)
                    if tower.specialization else None)
        active = selected.tiers[:limit] if selected is not None else ()
        mods = {name: 0.0 for name in (
            "damage", "rate", "range", "crit", "crit_damage", "money",
            "income", "targets", "projectiles", "knockback")}
        statuses = {effect.kind: effect for effect in tower.statuses}
        for tier in active:
            for name in mods:
                mods[name] += getattr(tier, name)
            for effect in tier.statuses:
                statuses[effect.kind] = effect

        strength = self.specialization_strength(growth_spec_rank)
        for name in ("damage", "rate", "range", "crit", "crit_damage",
                     "money", "income"):
            mods[name] *= strength

        return TowerStats(
            damage=damage * max(0.0, 1.0 + mods["damage"]),
            fire_rate=rate * max(0.0, 1.0 + mods["rate"]),
            range=reach * max(0.0, 1.0 + mods["range"]),
            targets=max(1, round(tower.targets + mods["targets"])),
            projectiles=max(1, round(tower.projectiles + mods["projectiles"])),
            crit_chance=min(1.0, max(0.0, tower.crit_chance
                                     + clover_crit_chance + mods["crit"])),
            crit_damage=max(1.0, tower.crit_damage
                            + clover_crit_damage + mods["crit_damage"]),
            knockback=max(0.0, mods["knockback"]),
            money=mods["money"], income=mods["income"],
            tier_limit=limit, statuses=tuple(statuses.values()))

    def monster(self, index: int, boss: bool = False) -> Monster:
        bank = self.bosses if boss else self.monsters
        if index < 0 or index >= len(bank):
            raise TableError(f"no {'boss' if boss else 'monster'} index {index}")
        return bank[index]

    # -- derived rules (each a port of one GML function) -------------------
    def waves(self, region: int, stage: int) -> int:
        """``region_waves()``: stage 1 is ``wave_first``, +``wave_step`` a stage."""
        r = self.region(region)
        return r.wave_first + r.wave_step * (stage - 1)

    def life_mult(self, region: int, wave: int, waves: int) -> float:
        """``region_life_mult()``: 1.00 on wave 1 in every biome, -> curve_end.

        ``m(w) = 1 + (curve_end - 1) * ((w - 1) / (waves - 1)) ^ curve_pow``
        """
        r = self.region(region)
        last = max(1, waves - 1)
        t = min(max((wave - 1) / last, 0.0), 1.0)
        return 1 + (r.curve_end - 1) * (t ** max(0.0, r.curve_pow))

    def boss_wave(self, region: int, stage: int) -> int:
        """``GameLevelData.boss_wave``: the MID boss wave, ``waves // 2`` (LL-060)."""
        return self.waves(region, stage) // 2

    def is_boss_wave(self, region: int, stage: int, wave: int) -> bool:
        """``scr_curve_is_boss_wave``: the stage's MID wave, and its last wave.

        This mirrors play, which stopped rolling bosses on a ``boss_every``
        cadence and started sending the stage's own ``[mid, end]`` pair on the
        mid wave and the finale (LL-060).  A tester that still assumed the
        cadence would price waves the game does not send that way.
        """
        if wave <= 1:
            return False
        waves = self.waves(region, stage)
        mid = waves // 2
        return wave >= waves or (mid > 1 and wave == mid)

    def wave_count(self, spawn_count: float, wave: int, count_bonus: float = 0) -> int:
        """``scr_level_spawn``: ``spawn_count + wave div 5 + difficulty count``."""
        return max(1, int(spawn_count + (wave // self.constants.count_div)
                          + count_bonus))

    def cap(self, mastery: int = 0) -> int:
        return self.constants.mastery_cap_base + mastery

    def floor(self, mastery: int = 0) -> int:
        return self.constants.mastery_floor_base + mastery

    def rung_price(self, base_price: float, level: int, mastery: int = 0,
                   discount: float = 0.0) -> float:
        """``tower_upgrade_price``: the next rung above ``level``, or -1.

        Rungs are counted from the garden's FLOOR, so money always buys the
        same four-rung shape (goal.md 4).
        """
        if level >= self.cap(mastery):
            return -1.0
        rung = int(round(level)) - self.floor(mastery) + 1
        if rung < 1 or rung > self.constants.rung_count:
            return -1.0
        discount = min(0.25, max(0.0, discount))
        return round(base_price * self.constants.rung_costs[rung - 1]
                     * (1 - discount))

    def data_at_level(self, tower: Tower, level: int,
                      clover_damage: float = 0.0,
                      clover_rate: float = 0.0) -> Tuple[float, float, float]:
        """``tower_data_at_level``: (damage, fire_rate, range) at ``level``.

        Measured against the BASE, never compounding - which is what makes a
        rung a fixed, visible step (economy.md 4.4).
        """
        row = min(max(int(round(level)), 1), len(self.ladder))
        l = self.ladder[row - 1]
        return (tower.damage * (1 + clover_damage) * l.damage,
                tower.fire_rate * (1 + clover_rate) * l.fire_rate,
                tower.range * l.range)

    def dps_at_level(self, tower: Tower, level: int,
                     clover_damage: float = 0.0,
                     clover_rate: float = 0.0,
                     targets: Optional[int] = None,
                     projectiles: Optional[int] = None) -> float:
        dmg, rate, _ = self.data_at_level(tower, level, clover_damage, clover_rate)
        return (dmg * rate
                * (tower.targets if targets is None else targets)
                * (tower.projectiles if projectiles is None else projectiles))

    # -- the same figure, with the fire cycle charged (LL-040) -------------
    @property
    def cycle(self) -> Cycle:
        """The shot period, built from the constants ``load()`` read.

        A property rather than a field on purpose: it is derived, so there is
        one place the numbers live (``Constants``) and no way for a rebuilt
        table set to carry a stale cycle.
        """
        c = self.constants
        return Cycle(c.fps, c.tower_offset_range[0], c.tower_offset_range[1],
                     c.tower_return_seconds)

    def delivered_dps_at_level(self, tower: Tower, level: int,
                               clover_damage: float = 0.0,
                               clover_rate: float = 0.0,
                               targets: int = 1,
                               projectiles: Optional[int] = None) -> float:
        """``dps_at_level`` with the shot CYCLE charged - the honest figure.

        :meth:`dps_at_level` answers "damage x rate x targets x projectiles",
        which is what the shop card prints and what the in-game panel believes. This answers what
        a tower actually delivers once the idle stagger and the return animation
        are paid for.  The two should be printed side by side, never merged: the
        gap between them is the finding (LL-038, LL-040).
        """
        dmg, rate, _ = self.data_at_level(tower, level, clover_damage, clover_rate)
        count = tower.projectiles if projectiles is None else projectiles
        return self.cycle.dps(dmg, rate, targets, count)


# ---------------------------------------------------------------------------
# reading them
# ---------------------------------------------------------------------------
def _call_args(call: Call, count: int, where: str) -> List[Any]:
    if len(call.args) != count:
        raise TableError(f"{where}: expected {count} arguments, got "
                         f"{len(call.args)}: {call.args}")
    return call.args


def _num(src: str, pattern: str, where: str, cast=float) -> Any:
    m = re.search(pattern, src)
    if m is None:
        raise TableError(f"{where}: pattern not found ({pattern})")
    return cast(m.group(1))


def _fps(root: Path) -> int:
    """The project's game speed.  Falls back to 60 with a note, never silently."""
    path = root / "options" / "main" / "options_main.yy"
    if path.exists():
        m = re.search(r'"option_game_speed"\s*:\s*(\d+)', path.read_text(
            encoding="utf-8", errors="replace"))
        if m:
            return int(m.group(1))
    return 60


def load(root: Path) -> Tables:
    """Read every table.  Raises :class:`TableError` rather than guessing."""
    root = Path(root)
    t = Tables(root=root)
    t.constants = Constants(fps=_fps(root))

    def src_of(rel: str) -> str:
        t.sources[rel] = rel
        return _read(root / rel)

    # ---- regions: the curve -------------------------------------------
    rel = "scripts/region_data/region_data.gml"
    for c in find_calls(src_of(rel), "region_row"):
        if not isinstance(c.args[0], int):
            continue                      # the definition, not a row
        a = _call_args(c, 9, f"{rel} region_row")
        t.regions.append(Region(int(a[0]), str(a[1]),
                                str(a[2]).split(".")[-1], int(a[3]), int(a[4]),
                                int(a[5]), float(a[6]), float(a[7]), int(a[8])))

    # ---- difficulty: the columns --------------------------------------
    rel = "scripts/difficulty_data/difficulty_data.gml"
    for c in find_calls(src_of(rel), "difficulty_row"):
        if not isinstance(c.args[0], str) or not isinstance(c.args[1], (int, float)):
            continue                      # the definition, not a row
        a = _call_args(c, 7, f"{rel} difficulty_row")
        t.difficulties.append(Difficulty(str(a[0]), float(a[1]), float(a[2]),
                                         float(a[3]), int(a[4]), float(a[5]),
                                         float(a[6])))

    # ---- stages: the spawn mix and par --------------------------------
    rel = "scripts/stage_data/stage_data.gml"
    for c in find_calls(src_of(rel), "stage_row"):
        if not isinstance(c.args[0], int) or not isinstance(c.args[1], int):
            continue
        a = _call_args(c, 7, f"{rel} stage_row")
        t.stages.append(Stage(int(a[0]), int(a[1]), int(a[2]),
                              tuple(a[3] or []), tuple(a[4] or []),
                              int(a[5]), int(a[6])))

    # ---- the ladder, and what a rung costs ----------------------------
    rel = "scripts/tower_levels/tower_levels.gml"
    src = src_of(rel)
    for row in find_array_after(src, "function tower_level_table"):
        t.ladder.append(Ladder(int(row[0]), float(row[1]), float(row[2]),
                               float(row[3])))
    t.constants = replace(
        t.constants,
        rung_costs=tuple(float(x) for x in
                         find_array_after(src, "function tower_rung_cost")),
        mastery_cap_base=int(_num(src, r"function tower_cap\(\)\s*\{\s*"
                                       r"return\s+(\d+)", rel)),
        mastery_floor_base=int(_num(src, r"function tower_floor\(\)\s*\{\s*"
                                        r"return\s+(\d+)", rel)),
        sell_refund=float(_num(src, r"return round\(_invested\s*\*\s*([\d.]+)\)", rel)),
    )

    # ---- towers: price and the base stats -----------------------------
    rel = "scripts/scr_tower_roster/scr_tower_roster.gml"
    for c in find_calls(src_of(rel), "tower_entry"):
        if not isinstance(c.args[0], str) or not isinstance(c.args[2], (int, float)):
            continue
        a = _call_args(c, 6, f"{rel} tower_entry")
        data = a[3]
        if not isinstance(data, Call) or data.name != "scr_towerData":
            raise TableError(f"{rel} tower_entry({a[0]}): expected "
                             f"scr_towerData(...), got {data!r}")
        d = _call_args(data, 5, f"{rel} scr_towerData")
        t.towers.append(Tower(str(a[0]), float(a[2]), float(d[0]), float(d[1]),
                              float(d[2]), int(d[4]), int(a[4]), int(a[5])))

    # ---- crit and on-hit statuses ------------------------------------
    # These live beside the roster, deliberately outside scr_towerData's
    # five-argument contract.  Keep the sim's combat outcomes sourced from the
    # same records as the game rather than maintaining a second status list.
    base_crit_rel = "scripts/scr_towerData/scr_towerData.gml"
    base_crit_src = src_of(base_crit_rel)
    base_crit = float(_num(base_crit_src,
                           r"_data\[TOWER\.crit_chance\]\s*=\s*([\d.]+)",
                           base_crit_rel))
    base_crit_damage = float(_num(base_crit_src,
                                  r"_data\[TOWER\.crit_damage\]\s*=\s*([\d.]+)",
                                  base_crit_rel))
    base_projectiles = int(_num(base_crit_src,
                                r"_data\[TOWER\.projectiles\]\s*=\s*(\d+)",
                                base_crit_rel))
    trait_src = src_of(rel)
    raw_traits = find_array_after(trait_src, "function tower_trait_table")
    trait_rows: Dict[str, Dict[str, Any]] = {}
    for row in raw_traits:
        if not isinstance(row, dict) or not isinstance(row.get("name"), str):
            continue
        trait_rows[row["name"]] = row
    updated_towers: List[Tower] = []
    for tower in t.towers:
        row = trait_rows.get(tower.name, {})
        statuses: List[HitStatus] = []
        for status in row.get("statuses", []) if isinstance(row, dict) else []:
            if not isinstance(status, dict):
                continue
            kind = status.get("kind", "")
            if isinstance(kind, str):
                kind = kind.rsplit(".", 1)[-1].lower()
            if kind not in {"slow", "stun", "burn", "poison", "root", "bleed", "vuln"}:
                continue
            chance = status.get("chance", 0)
            mult = status.get("mult", 1)
            amount = status.get("amount", 0)
            seconds = status.get("seconds", 0)
            if not all(isinstance(v, (int, float)) for v in
                       (chance, mult, amount, seconds)):
                raise TableError(f"{rel} {tower.name}: invalid {kind} status row")
            if chance <= 0 or seconds <= 0:
                continue
            statuses.append(HitStatus(kind, float(chance), float(mult),
                                      float(amount), float(seconds)))
        trait_crit = row.get("crit", 0) if isinstance(row, dict) else 0
        trait_crit_damage = row.get("crit_damage", 0) if isinstance(row, dict) else 0
        trait_money = row.get("money", 0) if isinstance(row, dict) else 0
        trait_income = row.get("wave_income", 0) if isinstance(row, dict) else 0
        if not isinstance(trait_crit, (int, float)):
            trait_crit = 0
        if not isinstance(trait_crit_damage, (int, float)):
            trait_crit_damage = 0
        if not isinstance(trait_money, (int, float)):
            trait_money = 0
        if not isinstance(trait_income, (int, float)):
            trait_income = 0
        updated_towers.append(replace(
            tower,
            crit_chance=min(1.0, base_crit + float(trait_crit)),
            crit_damage=base_crit_damage + float(trait_crit_damage),
            statuses=tuple(statuses),
            projectiles=base_projectiles,
            money_bonus=float(trait_money), wave_income=float(trait_income)))
    t.towers = updated_towers

    # ---- tower specializations: all path tiers ------------------------
    # Path effects are literal helper calls, so unwrap those helpers instead
    # of maintaining a second set of balance numbers in Python.
    rel = "scripts/scr_tower_specs/scr_tower_specs.gml"
    spec_src = src_of(rel)
    spec_rows = find_array_after(spec_src, "function tower_spec_table")
    status_kinds = {"slow", "stun", "burn", "poison", "root", "bleed",
                    "vuln", "vulnerable"}

    def parse_spec_tier(raw: Any, where: str) -> SpecializationTier:
        values: Dict[str, float] = {"money": 0.0, "income": 0.0,
                                    "projectiles": 0.0}
        if not isinstance(raw, Call):
            raise TableError(f"{where}: expected a specialization tier call")
        while raw.name != "tower_spec_tier":
            if raw.name not in ("tower_spec_projectile_tier",
                                "tower_spec_income_tier",
                                "tower_spec_flat_income_tier") or len(raw.args) != 2:
                raise TableError(f"{where}: unsupported tier wrapper {raw.name}")
            inner, amount = raw.args
            if not isinstance(amount, (int, float)) or isinstance(amount, bool):
                raise TableError(f"{where}: invalid {raw.name} amount {amount!r}")
            field_name = {
                "tower_spec_projectile_tier": "projectiles",
                "tower_spec_income_tier": "money",
                "tower_spec_flat_income_tier": "income",
            }[raw.name]
            values[field_name] = (float(round(amount)) if field_name == "projectiles"
                                  else float(amount))
            raw = inner
            if not isinstance(raw, Call):
                raise TableError(f"{where}: wrapper does not contain a tier call")
        a = _call_args(raw, 8, f"{where} tower_spec_tier")
        names = ("damage", "rate", "range", "crit", "crit_damage",
                 "targets", "knockback")
        if not all(isinstance(a[i], (int, float)) and not isinstance(a[i], bool)
                   for i in range(7)):
            raise TableError(f"{where}: non-numeric tier modifier")
        values.update({name: float(a[i]) for i, name in enumerate(names)})
        if values["targets"] != round(values["targets"]):
            raise TableError(f"{where}: target modifier must resolve to an integer")
        statuses: List[HitStatus] = []
        if not isinstance(a[7], list):
            raise TableError(f"{where}: tier statuses are not an array")
        for status in a[7]:
            if (not isinstance(status, Call) or status.name != "tower_spec_status"
                    or len(status.args) != 5):
                raise TableError(f"{where}: unsupported status {status!r}")
            kind, chance, mult, amount, seconds = status.args
            if (not isinstance(kind, str) or kind.lower() not in status_kinds
                    or not all(isinstance(v, (int, float)) and not isinstance(v, bool)
                               for v in (chance, mult, amount, seconds))):
                raise TableError(f"{where}: invalid status row {status!r}")
            normalized = "vuln" if kind.lower() == "vulnerable" else kind.lower()
            statuses.append(HitStatus(normalized, float(chance), float(mult),
                                      float(amount), float(seconds)))
        return SpecializationTier(
            damage=values["damage"], rate=values["rate"], range=values["range"],
            crit=values["crit"], crit_damage=values["crit_damage"],
            targets=int(values["targets"]),
            projectiles=int(round(values["projectiles"])),
            knockback=values["knockback"], money=values["money"],
            income=values["income"], statuses=tuple(statuses))

    for row in spec_rows:
        if (not isinstance(row, dict) or not isinstance(row.get("tower"), str)
                or not isinstance(row.get("paths"), list)):
            raise TableError(f"{rel}: invalid tower specialization row {row!r}")
        tower_name = row["tower"]
        if tower_name not in {tower.name for tower in t.towers}:
            raise TableError(f"{rel}: specialization row for unknown tower {tower_name!r}")
        paths: Dict[str, SpecializationPath] = {}
        for path in row["paths"]:
            if (not isinstance(path, Call) or path.name != "tower_spec_path"
                    or len(path.args) != 4 or not isinstance(path.args[0], str)
                    or not isinstance(path.args[3], list)):
                raise TableError(f"{rel} {tower_name}: invalid specialization path {path!r}")
            key = path.args[0]
            tiers = tuple(parse_spec_tier(tier, f"{tower_name}/{key}")
                          for tier in path.args[3])
            if len(tiers) != 3 or key in paths:
                raise TableError(f"{rel} {tower_name}/{key}: expected three unique tiers")
            paths[key] = SpecializationPath(tower_name, key, tiers)
        if len(paths) != 2:
            raise TableError(f"{rel} {tower_name}: expected two paths, found {len(paths)}")
        t.specializations[tower_name] = paths
    if len(spec_rows) != len(t.towers) or len(t.specializations) != len(t.towers):
        raise TableError(f"{rel}: expected one specialization row per tower "
                         f"({len(t.towers)}), found {len(spec_rows)}")

    limit_at = spec_src.find("function tower_spec_tier_limit")
    modifier_at = spec_src.find("function tower_spec_modifiers", limit_at)
    if limit_at < 0 or modifier_at < 0:
        raise TableError(f"{rel}: missing specialization tier gate")
    limit_src = spec_src[limit_at:modifier_at]
    def spec_limit(pattern: str, label: str) -> int:
        match = re.search(pattern, limit_src)
        if not match:
            raise TableError(f"{rel}: cannot read {label} from tier gate")
        return int(match.group(1))
    level_one = spec_limit(r"if\s*\(_level\s*<\s*(\d+)\)\s*return\s+0", "L3 unlock")
    signature_level = spec_limit(r"if\s*\(_level\s*>=\s*(\d+)\)\s*return\s+3", "signature level")
    level_two = spec_limit(r"if\s*\(_level\s*>=\s*(\d+)\)\s*\{", "L4 unlock")
    growth_rank_match = re.search(
        r"clover_rank\(\s*\"growth_spec_tier\"\s*\)\s*>\s*(\d+)",
        limit_src)
    if not growth_rank_match:
        raise TableError(f"{rel}: cannot read Growth signature rank gate")
    growth_unlock_rank = int(growth_rank_match.group(1)) + 1

    clover_rel = "scripts/scr_clover_tree/scr_clover_tree.gml"
    clover_src = src_of(clover_rel)
    clover_node = next((c for c in find_calls(clover_src, "clover_node")
                        if len(c.args) == 6 and c.args[1] == "growth_spec_tier"), None)
    if clover_node is None or not isinstance(clover_node.args[4], dict):
        raise TableError(f"{clover_rel}: missing Master Gardener node effects")
    per_rank = clover_node.args[4].get("specialization_bonus")
    if not isinstance(per_rank, (int, float)):
        raise TableError(f"{clover_rel}: Master Gardener has no specialization bonus")
    rank_max = int(_num(clover_src, r"ranks\s*:\s*(\d+)", clover_rel, cast=int))
    bonus_cap = float(_num(
        clover_src,
        r"function\s+clover_specialization_bonus\(\)\s*\{\s*return\s+clamp\([^,]+,\s*0\s*,\s*([\d.]+)\)",
        clover_rel))
    t.constants = replace(
        t.constants, specialization_level_one=level_one,
        specialization_level_two=level_two,
        specialization_signature_level=signature_level,
        growth_spec_unlock_rank=growth_unlock_rank,
        growth_spec_rank_max=rank_max,
        specialization_bonus_per_rank=float(per_rank),
        specialization_bonus_cap=bonus_cap)

    # Control effects lose duration on elite and boss monsters.  Parse the
    # ordered assignments from the same function the game calls so resistance
    # changes cannot silently leave the balance sim behind.
    status_rel = "scripts/scr_status/scr_status.gml"
    status_src = src_of(status_rel)
    marker = "function status_cc_frames"
    status_at = status_src.find(marker)
    if status_at < 0:
        raise TableError(f"{status_rel}: missing {marker}()")
    status_body = status_src[status_at:]
    assignments = re.findall(
        r"case STATUS\.(SLOW|STUN|ROOT):\s*_scale\s*=\s*([\d.]+)",
        status_body)
    if len(assignments) != 6:
        raise TableError(f"{status_rel}: expected six elite/boss CC scales, "
                         f"found {len(assignments)}")
    t.status_cc = {
        "elite": {kind.lower(): float(scale) for kind, scale in assignments[:3]},
        "boss": {kind.lower(): float(scale) for kind, scale in assignments[3:]},
    }

    # ---- creatures: the two banks -------------------------------------
    rel = "scripts/scr_setupSpawning/scr_setupSpawning.gml"
    src = src_of(rel)
    bank_re = re.compile(r"(spawn_(?:mon|boss))\s*\[\s*(\d+)\s*\]\s*=\s*"
                         r"scr_makeMonster\s*\(")
    for m in bank_re.finditer(src):
        close = _matching(src, m.end() - 1)
        a = [parse_value(p) for p in split_args(src[m.end():close])]
        if len(a) != 7:
            raise TableError(f"{rel} scr_makeMonster: expected 7 arguments, "
                             f"got {len(a)}")
        mon = Monster(str(a[0]), float(a[1]), float(a[2]), int(a[4]), int(a[5]),
                      int(a[6]), boss=(m.group(1) == "spawn_boss"))
        (t.bosses if mon.boss else t.monsters).append(mon)
    if not t.monsters:
        raise TableError(f"{rel}: no spawn_mon[..] rows found")

    # ---- the run constants --------------------------------------------
    rel = "objects/_levelControl/Create_0.gml"
    src = src_of(rel)
    constants = replace(
        t.constants,
        start_money=float(_num(src, r"set_item_value\(\s*money\s*,\s*round\(\s*(\d+)",
                               rel)),
        start_life=int(_num(src, r"set_item_value\(\s*life\s*,\s*(\d+)\s*\)", rel)),
        cell=int(_num(src, r"cell_w\s*=\s*(\d+)", rel)),
    )
    rel = "scripts/scr_main_startup/scr_main_startup.gml"
    constants = replace(constants, load_max=float(
        _num(src_of(rel), r"load_max\s*=\s*(\d+)", rel)))
    rel = "scripts/scr_level_spawn/scr_level_spawn.gml"
    src = src_of(rel)
    constants = replace(
        constants,
        spawn_gap_frames=float(_num(src, r"wait_timer\s*=\s*_fps\s*\*\s*([\d.]+)", rel))
                         * t.constants.fps,
        count_div=int(_num(src, r"wave_count\s+div\s+(\d+)", rel)),
    )
    rel = "scripts/scr_setupSpawning/scr_setupSpawning.gml"
    constants = replace(constants, wave_gap_frames=float(_num(
        src_of(rel),
        r"spawn_wait_time\s*=\s*game_get_speed\(gamespeed_fps\)\s*\*\s*([\d.]+)",
        rel)) * t.constants.fps)
    rel = "scripts/scr_level_start/scr_level_start.gml"
    constants = replace(constants, start_message_seconds=float(_num(
        src_of(rel), r"level_state_time\s*>=\s*_fps\s*\*\s*([\d.]+)", rel)))
    # ---- the fire cycle: the stagger and the return animation (LL-040) ---
    # A shot costs its own fire period PLUS these two, in frames.  The idle
    # wait is only a stagger (time_offset) and scr_tower_return plays 0.25s of
    # art - and it was the WAIT that used to repeat the whole period, which is
    # the bug LL-040 fixed.  Both numbers live in obj_tower/Create_0.
    rel = "objects/obj_tower/Create_0.gml"
    src = src_of(rel)
    m = re.search(r"time_offset\s*=\s*irandom_range\(\s*(\d+)\s*,\s*(\d+)\s*\)", src)
    if m is None:
        raise TableError(f"{rel}: time_offset = irandom_range(lo,hi) not found")
    constants = replace(constants,
                        tower_offset_range=(int(m.group(1)), int(m.group(2))))

    m = re.search(r"anim_seconds\s*=\s*array\(([^)]*)\)", src, re.S)
    if m is None:
        raise TableError(f"{rel}: anim_seconds = array(...) not found")
    anim = [parse_value(p) for p in split_args(m.group(1))]
    # index 2 is TOWER_ANIM.return.  Index 1 (the attack) is unused by
    # design: the swing comes from tower_swing_seconds() below, capped
    # against the fire period (scr_tower_shoot, LL-054)
    if len(anim) < 3:
        raise TableError(f"{rel}: anim_seconds has {len(anim)} slot(s), need 3")
    constants = replace(constants, tower_return_seconds=float(anim[2]))

    # the SWING CAP (LL-054).  scr_tower_shoot takes
    # min(fire period, max(6, swing_seconds*fps)) frames for the swing, so
    # this one number decides how long a slow tower strikes for.  Read from
    # the function that owns it, so the sim cannot hold a private opinion.
    rel = "scripts/tower_levels/tower_levels.gml"
    constants = replace(constants, tower_swing_seconds=float(_num(
        src_of(rel),
        r"function\s+tower_swing_seconds\s*\(\s*\)\s*\{\s*return\s+([\d.]+)",
        rel)))

    # ---- the kill payout ramp (card kill-money-ramp, LL-042) --------------
    # A flat `kill_money` of 1/2/3 means income grows only with the COUNT while
    # demand grows with the square of the wave - $30 on wave 1 to $122 on wave
    # 15, about 4x, against demand's 21x.  scr_kill_money now multiplies the
    # base by `1 + slope * (wave - 1)`, and the slope lives in
    # kill_money_slope() so the tester reads it instead of holding its own.
    rel = "scripts/difficulty_data/difficulty_data.gml"
    constants = replace(constants, kill_money_slope=float(_num(
        src_of(rel),
        r"function\s+kill_money_slope\s*\(\s*\)\s*\{\s*return\s+([\d.]+)", rel)))

    # ---- the wave counter's seed (card hud-wave-offbyone, LL-044) ---------
    # `set_item_value(waves, seed)` in _levelControl/Create_0, raised once per
    # wave by scr_level_spawn - so during wave N the item reads `seed + N`, and
    # the speed ramp (scr_zomb_pathSpeed) is fed that number.  It is 0 now,
    # which makes the item equal wave_count; it was 1, which put the ramp one
    # wave ahead of the wave being fought.  Read rather than assumed, so the
    # sim follows the GML and a revert fails the test that pins the intent
    # instead of the sim and the closed form quietly disagreeing.
    rel = "objects/_levelControl/Create_0.gml"
    constants = replace(constants, wave_seed=_num(
        src_of(rel), r"set_item_value\(\s*waves\s*,\s*(\d+)\s*\)", rel, cast=int))

    # ---- the corpse lifetime ------------------------------------------
    # Kills settle immediately, but obj_mon remains until its die clip ends.
    # scr_zombie_die stretches either the SCML clip or fallback sheet to this
    # duration, and scr_level_wait will not start the clear gate until the
    # instance is gone. Read the one timing source used by both paths.
    rel = "scripts/scr_zomb_art/scr_zomb_art.gml"
    constants = replace(constants, zombie_die_seconds=float(_num(
        src_of(rel), r"#macro\s+ZOMB_DIE_SECS\s+([\d.]+)", rel)))

    # ---- Candy recipes, levels and live-time units -----------------------
    # Recipe costs/effects and their level formulas live in one GML system.
    # Read both the call table and candy_magnitude() so the simulator follows
    # the game when a Candy changes instead of carrying a parallel balance.
    rel = "scripts/scr_candy_system/scr_candy_system.gml"
    candy_src = src_of(rel)
    recipe_rows: Dict[str, Tuple[int, int, str, float, str]] = {}
    for call in find_calls(candy_src, "candy_recipe"):
        if (len(call.args) != 9 or not isinstance(call.args[0], str)
                or not isinstance(call.args[3], (int, float))):
            continue                         # the function definition
        candy_id, _label, _icon, tier, cost, effect, step, _desc, gate = call.args
        if not all(isinstance(value, (int, float)) for value in
                   (tier, cost, step)) or not isinstance(effect, str):
            raise TableError(f"{rel} {candy_id}: invalid recipe row")
        if not isinstance(gate, str):
            raise TableError(f"{rel} {candy_id}: invalid progression gate")
        recipe_rows[candy_id] = (int(tier), int(cost), effect, float(step), gate)

    magnitude_at = candy_src.find("function candy_magnitude")
    if magnitude_at < 0:
        raise TableError(f"{rel}: missing candy_magnitude()")
    magnitude_src = candy_src[magnitude_at:]
    cases = {
        match.group(1): match.group(2)
        for match in re.finditer(
            r'case\s+"([A-Za-z0-9_]+)"\s*:(.*?)(?:break\s*;)',
            magnitude_src, re.S)
    }
    for candy_id, (tier, cost, effect, step, gate) in recipe_rows.items():
        case_body = cases.get(candy_id)
        if case_body is None:
            raise TableError(f"{rel} {candy_id}: no magnitude case")
        formulas: List[Tuple[str, float, float, int]] = []
        for assignment in re.finditer(
                r"_out\.([A-Za-z_][A-Za-z0-9_]*)\s*=\s*([^;]+);",
                case_body):
            field_name, expression = assignment.group(1), assignment.group(2).strip()
            match = re.fullmatch(
                r"([\d.]+)\s*\+\s*_steps\s*\*\s*_recipe\.step", expression)
            if match:
                formulas.append((field_name, float(match.group(1)), step, 0))
                continue
            match = re.fullmatch(
                r"([\d.]+)\s*\+\s*_steps\s*\*\s*([\d.]+)", expression)
            if match:
                formulas.append((field_name, float(match.group(1)),
                                 float(match.group(2)), 0))
                continue
            match = re.fullmatch(
                r"([\d.]+)\s*\+\s*floor\(\s*\(?\s*_lv\s*-\s*1\s*\)?\s*/\s*(\d+)\s*\)",
                expression)
            if match:
                formulas.append((field_name, float(match.group(1)), 0.0,
                                 int(match.group(2))))
                continue
            raise TableError(f"{rel} {candy_id}: unsupported magnitude formula {expression!r}")
        if not formulas:
            raise TableError(f"{rel} {candy_id}: empty magnitude formula")
        t.candies[candy_id] = CandyRecipe(
            candy_id, tier, cost, effect, step, gate, tuple(formulas))
    if len(t.candies) != 10 or len(t.candies) != len(recipe_rows):
        raise TableError(f"{rel}: expected 10 complete Candy recipes, found {len(t.candies)}")

    candy_hz = int(_num(candy_src, r"#macro CANDY_BASE_FRAME_HZ\s+(\d+)", rel,
                        cast=int))
    duration_seconds = float(_num(
        candy_src,
        r"function\s+candy_duration_seconds\s*\(\s*\)\s*\{\s*return\s+([\d.]+)\s*\*",
        rel))
    duration_per_rank = float(_num(
        candy_src,
        r"function\s+candy_duration_bonus\s*\(\s*\)\s*\{\s*return\s+candy_duration_rank\(\)\s*\*\s*([\d.]+)",
        rel))
    duration_costs = find_array_after(candy_src, "function candy_duration_cost")
    if not duration_costs or not all(isinstance(value, int) for value in duration_costs):
        raise TableError(f"{rel}: invalid candy duration cost table")
    constants = replace(
        constants, candy_frame_hz=candy_hz,
        candy_base_seconds=duration_seconds,
        candy_duration_per_rank=duration_per_rank,
        candy_duration_costs=tuple(duration_costs))

    t.constants = constants

    if not t.regions or not t.difficulties or not t.towers or not t.ladder:
        raise TableError("a table came back empty: "
                         f"regions={len(t.regions)} difficulties={len(t.difficulties)} "
                         f"towers={len(t.towers)} ladder={len(t.ladder)}")
    return t




def parse_value(text: str) -> Any:
    """Parse one GML literal: a number, string, list, struct, call, or token.

    An identifier that is not a literal (``BIOME.GRASS``, ``_eff_puff``) is
    returned as its own text - the tables only use them for enums and sprite
    names, and a caller that needs the enum can read the last segment.
    """
    t = text.strip()
    if t == "":
        return None
    if t.startswith("["):
        end = _matching(t, 0)
        inner = t[1:end]
        return [parse_value(p) for p in split_args(inner)] if inner.strip() else []
    if t.startswith("{"):
        end = _matching(t, 0)
        inner = t[1:end]
        fields: Dict[str, Any] = {}
        for part in split_args(inner):
            in_str = False
            depth = 0
            colon = -1
            i = 0
            while i < len(part):
                ch = part[i]
                if in_str:
                    if ch == "\\":
                        i += 2
                        continue
                    if ch == '"':
                        in_str = False
                elif ch == '"':
                    in_str = True
                elif ch in "([{":
                    depth += 1
                elif ch in ")]}":
                    depth -= 1
                elif ch == ":" and depth == 0:
                    colon = i
                    break
                i += 1
            if colon < 0:
                raise TableError(f"struct field has no colon: {part!r}")
            key = part[:colon].strip()
            if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", key):
                raise TableError(f"invalid struct key: {key!r}")
            fields[key] = parse_value(part[colon + 1:])
        return fields
    if t.startswith('"'):
        # a string literal: find its closing quote, honouring \"
        i, out = 1, []
        while i < len(t):
            ch = t[i]
            if ch == "\\" and i + 1 < len(t):
                out.append(t[i + 1])
                i += 2
                continue
            if ch == '"':
                break
            out.append(ch)
            i += 1
        return "".join(out)
    if _NUMBER_RE.match(t):
        return int(t)
    if _FLOAT_RE.match(t):
        return float(t)
    if t == "true":
        return True
    if t == "false":
        return False
    m = _CALL_RE.match(t)
    if m is not None:
        open_paren = t.index("(", m.end() - 1)
        close = _matching(t, open_paren)
        return Call(m.group(1), [parse_value(p) for p in split_args(t[open_paren + 1:close])])
    return t
