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

    @property
    def dps(self) -> float:
        """Nominal DPS - ``damage x rate x targets``, the panel's figure.

        It is an UPPER BOUND: it assumes every shot lands on a full set of
        targets.  What the run actually delivers is measured by the sim, and
        the gap between the two is the interesting number.
        """
        return self.damage * self.fire_rate * self.targets


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

    :attr:`Tower.dps` is ``damage x rate x targets``, which assumes a tower
    fires every ``1 / fire_rate`` seconds forever.  The code does not.  One shot
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

    def dps(self, damage: float, fire_rate: float, targets: int = 1) -> float:
        """Delivered dps, with the cycle charged."""
        return damage * self.rate(fire_rate) * targets

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
    ladder: List[Ladder] = field(default_factory=list)
    constants: Constants = field(default_factory=Constants)
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

    def rung_price(self, base_price: float, level: int, mastery: int = 0) -> float:
        """``tower_upgrade_price``: the next rung above ``level``, or -1.

        Rungs are counted from the garden's FLOOR, so money always buys the
        same four-rung shape (goal.md 4).
        """
        if level >= self.cap(mastery):
            return -1.0
        rung = int(round(level)) - self.floor(mastery) + 1
        if rung < 1 or rung > self.constants.rung_count:
            return -1.0
        return round(base_price * self.constants.rung_costs[rung - 1])

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
                     targets: Optional[int] = None) -> float:
        dmg, rate, _ = self.data_at_level(tower, level, clover_damage, clover_rate)
        return dmg * rate * (tower.targets if targets is None else targets)

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
                               targets: int = 1) -> float:
        """``dps_at_level`` with the shot CYCLE charged - the honest figure.

        :meth:`dps_at_level` answers "damage x rate x targets", which is what the
        shop card prints and what the in-game panel believes.  This answers what
        a tower actually delivers once the idle stagger and the return animation
        are paid for.  The two should be printed side by side, never merged: the
        gap between them is the finding (LL-038, LL-040).
        """
        dmg, rate, _ = self.data_at_level(tower, level, clover_damage, clover_rate)
        return self.cycle.dps(dmg, rate, targets)


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

    # ---- towers: price and the four stats -----------------------------
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

    t.constants = constants

    if not t.regions or not t.difficulties or not t.towers or not t.ladder:
        raise TableError("a table came back empty: "
                         f"regions={len(t.regions)} difficulties={len(t.difficulties)} "
                         f"towers={len(t.towers)} ladder={len(t.ladder)}")
    return t




def parse_value(text: str) -> Any:
    """Parse one GML literal: a number, a string, a list, a call, or a token.

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
    m = _CALL_RE.match(t)
    if m is not None:
        open_paren = t.index("(", m.end() - 1)
        close = _matching(t, open_paren)
        return Call(m.group(1), [parse_value(p) for p in split_args(t[open_paren + 1:close])])
    return t
