"""What actually happens, frame by frame.

WHY THIS EXISTS.  :mod:`gm.balance.model` is a closed form: it asks whether the
income at wave N can field enough coverage for that wave's demand, which is a
RATIO.  It puts one monster on the road at a time, assumes every shot lands on a
full target cap, and never wastes a swing.  LL-038 was the cost of trusting it -
the panel read `ok` while a full wrap leaked, because the model and the code
disagreed about what a tower delivers.

This module time-steps the real rules at the real frame rate instead, so the
things a ratio cannot express become measurable:

* **leaks and hearts.**  A leak applies Vitality prevention and boss saves to
  the life loss, then pays HALF the raw kill value (``lose_life``, economy.md
  4.5 - it paid nothing before 2026-10-18, which turned the first leak into an
  income cut too), and the stage FAILS at zero
  (``scr_main_normal``), so "how many leak" is the
  outcome that matters - not "is supply >= demand".
* **money is earned as it lands.**  A kill pays in the frame it dies
  (``scr_zomb_death``), so wave 10 cannot be bought at wave 1.
* **the fire cycle is real.**  A tower walks idle -> attack -> return with the
  ``>=`` beats, the ``time_offset`` stagger and the 0.25s return animation, so it
  wastes swings on monsters that die mid-swing and on ones still emerging.
* **the emerge.** Monsters are vulnerable while rising; ``scr_zombie_emerge``
  does not restore life, and ``scr_zomb_step`` checks death before dispatching
  the current state.
* **corpses keep the wave live.** A kill settles immediately, but the monster
  instance stays through the non-looping DIE animation (``ZOMB_DIE_SECS``).
  ``scr_level_wait`` starts its 354-frame gate only after the corpse is gone;
  Candy keeps ticking until that same boundary.
* **combat effects.** Crit rolls and on-hit statuses come from the roster's
  trait table. Slow, stun, root, burn, poison, bleed and vulnerability use a
  seeded RNG so repeated runs are reproducible.
* **specializations.** `--specialization TOWER=PATH` applies the GML path tiers
  at L3-L5, including Growth's early signature unlock, status overrides,
  projectile/target changes, knockback, hit-money, wave-income and implemented
  signature effects.
* **Candy.** Optional `--candy id:level:uses` profiles apply the authored stat,
  control and kill-money effects for their live-wave frame duration. Regular
  Candy starts at wave 1; Gob is used on the first boss wave while another
  Candy is active. This is a declared activation policy, not a model of pause
  timing or the player's saved stock.
* **terrain is a transient.**  ``z_climb`` starts at 10 and lerps 0.1 a frame
  toward the cell's height (``scr_zomb_pathSpeed``), so a monster's first second
  of walking is not at the speed its terrain implies.
* **the wave gate.**  The next wave waits for the field to be CLEAR and THEN
  counts 354 frames (``scr_level_wait``), so one straggler delays the next wave
  instead of overlapping it.

THE FRAME ORDER, and it is an assumption.  GameMaker runs instances in an order
this tool cannot read, so each frame is stepped as

    level (spawn / wait / clear)  ->  Candy tick  ->  towers  ->  monsters  ->  fail check

which means: a monster spawned this frame cannot be shot until the next frame; a
kill pays in the frame it is shot (towers before monsters) and leaves its corpse
for the authored DIE duration; and a monster that reaches the despawn this frame
still took that frame's shot. Sub-frame details can differ from the game by one
step - smaller than the differences this tool exists to find.

WHAT IS NOT MODELLED, stated rather than discovered later:

* **the per-wave ``irandom`` creature pick.**  The sim uses the MEAN monster of
  the stage's pool (``model.mean_field``, the same function the closed form
  uses), so one run is the expected wave rather than a sample of it.  A stage
  whose pool has one entry - stage 1-1, ``spawns = [0]`` - has no variance here
  at all.
* **the ground map.**  It is re-rolled every launch, so ``terrain.Terrain``
  brackets it as a band and ``z_climb`` lerps toward that band's height.
* **towers BLOCKING the path.**  ``obj_tower/Create_0`` adds its cell to
  ``path_grid``, and a monster that cannot get out escalates to the
  tower-ignoring grid after ~2s (``obj_mon/Alarm_0``).  Routes here are static.
* **a HUMAN's build.**  ``policy.plan`` spreads its towers across the route now
  (union coverage, not additive - it used to pile every tower onto the same
  stretch), and it buys rungs as well as placements, but it still builds with
  perfect information and no taste.  Read its numbers as a ceiling reached by
  a tidy robot, not as a picture of a person's garden.
* **the safety valve, and the player's own fingers.**
"""

from __future__ import annotations

import math
import random
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Sequence, Tuple

from . import geometry, model, policy, tables, terrain
from .geometry import Cell, Point
from .model import Scene
from .tables import HitStatus, Tower

# ---- frame counts.  Each is owned by a script; none is invented here. -----
EMERGE_START_Z = 10.0       # scr_zombie_path: `z_climb = 10` on entry
Z_CLIMB_LERP = 0.1          # scr_zomb_pathSpeed: `lerp(z_climb, ground, 0.1)`
WATER_SLOW = 0.25           # scr_zomb_pathSpeed: `if(z_climb < 2) _spd = 0.25`
WATER_Z = 2.0               # scr_zomb_pathSpeed: `if(z_climb < 2)`
SPEED_SLOPE = 1.5           # scr_zomb_pathSpeed: `((12-z)/12)*1.5 + 0.5`
SPEED_BASE = 0.5
SPEED_GAIN = 0.01           # scr_zomb_pathSpeed: `_spd += .01*_wave`
RAMP_DIVISOR = 30.0         # scr_zomb_pathSpeed: `1-power(2,-(_wave/30))`
LEAK_RADIUS = 16.0          # scr_zomb_updatePosition: point_in_circle(...,16)

#: How often ``--spend instant`` looks for something to buy while a wave is
#: live.  15 frames is a quarter second at 60fps: fast enough that a kill
#: becomes a tower inside the wave it was earned in, slow enough that the
#: greedy (over every free cell and every tower) does not run every frame.
INSTANT_SCAN_FRAMES = 15


class Track:
    """A route you can ask for a point at a given distance ALONG it.

    ``geometry.sample_points`` cannot be used for this: it restarts its spacing
    at every vertex, so its k-th point is not k px along.  Monsters walk one
    polyline, so the honest mapping is a cumulative length plus an interpolation
    between the two vertices that bracket the distance.
    """

    __slots__ = ("route", "cum", "length")

    def __init__(self, route: Sequence[Point]) -> None:
        self.route = [(float(p[0]), float(p[1])) for p in route]
        self.cum = [0.0]
        for a, b in zip(self.route, self.route[1:]):
            self.cum.append(self.cum[-1] + math.dist(a, b))
        self.length = self.cum[-1] if self.cum else 0.0

    def at(self, dist: float) -> Point:
        if not self.route:
            return (0.0, 0.0)
        d = min(max(float(dist), 0.0), self.length)
        lo, hi = 0, len(self.cum) - 1
        while lo < hi - 1:                      # binary search the segment
            mid = (lo + hi) // 2
            if self.cum[mid] <= d:
                lo = mid
            else:
                hi = mid
        a = self.route[lo]
        b = self.route[min(lo + 1, len(self.route) - 1)]
        span = self.cum[min(lo + 1, len(self.cum) - 1)] - self.cum[lo]
        t = (d - self.cum[lo]) / span if span > 0 else 0.0
        return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


@dataclass
class SimTower:
    """One tower, carrying the state its scripts carry.

    The real cycle is ``normal -> shoot -> return``, with the beats taken from
    ``scr_tower_normal`` / ``scr_tower_shoot`` / ``scr_tower_return``:

    * ``normal`` fires when the COOLDOWN is up and something is in range.  The
      cooldown (``attack_cycle`` = fire period + return + stagger) ticks in
      EVERY state, in Step_0, so an idle tower is READY - it is not the old
      ``state_time > time_offset`` wait, which only ran inside one state
      (LL-054);
    * ``shoot`` swings for ``min(period, swing cap)`` frames - the ART is
      capped, it is not as long as the fire period - re-checks its CACHED
      target list every frame and re-scans with ``find_all_range`` only when
      nothing in it is still ALIVE (a started swing is committed);
    * damage lands on ``fire_frame`` against every cached target, with each
      target receiving one direct-hit packet per projectile;
    * ``return`` lasts as long as the return animation.

    ``state_time`` is the game's counter and a state change resets it, so the
    cycle length is a property of the arithmetic rather than a table of offsets.

    In ``nominal`` mode the same tower fires every ``Cycle.period`` frames
    whenever it can see something and never wastes a swing - which is exactly
    what the closed form assumes.  Running both is how the gap between the
    idealised cycle and the state machine is measured instead of argued about.
    """

    cell: Cell
    tower: Tower
    level: int
    x: float
    y: float
    hit: float                     # damage per shot at this level
    rate: float                    # fire_rate at this level
    reach: float                   # range at this level
    targets: int
    projectiles: int
    knockback: float
    time_offset: int
    mode: str = "real"             # real | nominal
    state: str = "normal"
    state_time: int = 0
    target: Optional[List["SimMonster"]] = None
    shot_stats: Optional[tables.TowerStats] = None
    shot_hit: float = 0.0
    shot_projectiles: int = 1
    did_damage: bool = False
    frame_number: float = 0.0     # the SWING, in frames (kept name: the GML
    fire_frame: int = 0           # one is swing_frame - see scr_tower_shoot
    swing_frame: float = 0.0
    attack_timer: float = 0.0     # obj_tower/Step_0: ticks in EVERY state
    attack_cycle: float = 0.0     # tower_cycle_frames: period + return
    next_fire: float = 0.0         # nominal mode: the frame the next shot is due
    shots: int = 0                 # swings that dealt damage
    wasted: int = 0                # swings that achieved nothing
    dealt: float = 0.0             # effective HP removed, including status damage
    tower_index: int = -1          # stable source id for status/DoT accounting

    @property
    def name(self) -> str:
        return self.tower.name


@dataclass
class WaveResult:
    """One wave, as it played out."""

    wave: int
    boss: bool
    count: int
    hp: float                      # the whole wave's hp: count x per-monster life
    spawn_frame: int
    end_frame: int
    clear_frame: int = 0           # the frame the field emptied; 0 = never cleared
    life: float = 0.0              # per-monster life, after the curve and difficulty
    speed: float = 1.0             # the pool's mean MON.speed
    kill_money: float = 1.0        # what one kill pays before the difficulty column
    lives_start: int = 0
    lives_end: int = 0
    kills: int = 0
    leaks: int = 0
    lives_lost: int = 0
    peak_alive: int = 0
    money_start: float = 0.0
    money_earned: float = 0.0
    spent: float = 0.0
    towers_built: int = 0
    towers: int = 0
    shots: int = 0
    wasted: int = 0
    money_end: float = 0.0        # the purse when the wave ended
    idle: float = 0.0             # money the top-of-wave plan could not spend

    @property
    def frames(self) -> int:
        return self.end_frame - self.spawn_frame


@dataclass
class Outcome:
    """A whole stage: cleared or failed, and what it cost."""

    waves: List[WaveResult] = field(default_factory=list)
    cleared: bool = False
    failed: bool = False
    frames: int = 0
    lives_left: int = 0
    leaks: int = 0
    kills: int = 0
    spawned: int = 0
    hp_total: float = 0.0
    hp_killed: float = 0.0
    money_earned: float = 0.0
    money_spent: float = 0.0
    start_money: float = 0.0       # the purse the stage opened with
    start_life: int = 0            # the hearts it opened with
    setup_cost: float = 0.0        # fixed deployment investment, when benchmarked
    towers_built: int = 0
    towers: int = 0
    shots: int = 0
    wasted: int = 0
    peak_alive: int = 0
    peak_in_range: int = 0         # the most monsters ONE tower ever saw at once
    walk_frames: List[int] = field(default_factory=list)
    cycle: str = "real"
    spend: str = "ceiling"
    terrain_z: float = 0.0
    truncated: bool = False        # stopped at the caller's wave cap, not at CLEAR
    candy_used: Dict[str, Tuple[int, int]] = field(default_factory=dict)
    candy_active_frames: Dict[str, int] = field(default_factory=dict)
    candy_pity_bonus_progress: float = 0.0
    candy_frozen_waves: int = 0

    @property
    def cleared_all(self) -> bool:
        return self.cleared and not self.truncated

    @property
    def money_left(self) -> float:
        """What is still in the purse at the end - idle money, and it should be small.

        NOT ``earned - spent``: the stage OPENS with a purse
        (``set_item_value(money, round(25 * ...))``), and a run that spends its
        whole opening stake with nothing left is exactly the outcome a price
        ladder is trying not to produce.
        """
        return self.start_money + self.money_earned - self.money_spent

    @property
    def mean_walk(self) -> float:
        return (sum(self.walk_frames) / len(self.walk_frames)
                if self.walk_frames else 0.0)


@dataclass
class SimMonster:
    """One creature on the road, with the state its scripts keep.

    ``z_climb`` starts at :data:`EMERGE_START_Z` when the path state begins and
    lerps toward the terrain, which is why a monster's speed changes over the
    first second of its walk even on flat ground. A killed monster remains as
    a non-targetable corpse until its timed DIE clip ends.
    """

    boss: bool = False
    max_life: float = 1.0
    life: float = 1.0
    spawn_frame: int = 0
    wave: int = 0
    speed: float = 1.0             # MON.speed, the multiplier on path_speed
    kill_money: float = 1.0        # what a kill pays before the difficulty column
    x: float = 0.0
    y: float = 0.0
    dist: float = 0.0
    state: str = "emerge"          # emerge | walk
    state_time: int = 0
    z_climb: float = 0.0
    path_speed: float = 0.0
    statuses: Dict[str, "SimStatus"] = field(default_factory=dict)
    elite: bool = False
    alive: bool = True
    leaked: bool = False
    killed: bool = False
    death_frame: int = 0
    corpse_until_frame: int = 0
    walk_frames: int = 0
    last_hit_tower_money_bonus: float = 0.0


@dataclass
class SimStatus:
    """One live status entry on a monster, matching ``scr_status``."""

    kind: str
    mult: float
    amount: float
    frames: int
    stacks: int = 1
    source_tower: int = -1
    wildfire_signature: bool = False


@dataclass(frozen=True)
class CandyUse:
    """A requested recipe level and number of stock units for one sim run."""

    id: str
    level: int = 1
    count: int = 1


@dataclass
class ActiveCandy:
    """One active non-Gob Candy and its remaining normal-speed game frames."""

    level: int
    remaining_frames: int


class Sim:
    """The stage, stepped one frame at a time.

    ``spend`` is how the purse is emptied, and the three settings are three
    different claims about the player:

    * ``none`` buys nothing - the baseline that shows what a wave costs with no
      towers at all;
    * ``ceiling`` re-runs the greedy (:func:`policy.plan`) at the start of every
      wave with the money on hand - "perfect play with perfect information",
      the policy the closed form's supply assumes.  It is OPTIMISTIC in one
      specific way: money that arrives mid-wave sits idle for up to 20s until
      the next boundary, so the player fights the wave without towers they
      could have bought;
    * ``instant`` re-runs the same greedy while the wave is LIVE, so a kill's
      money becomes a tower within a quarter-second.  This is the policy a
      person actually plays, and it is the one the fit should use.

    Either way the towers already standing are passed to the policy, so a RUNG
    is a competitor and a level survives across waves.
    """

    def __init__(self, scene: Scene, *, ter: Optional[terrain.Terrain] = None,
                 cycle: str = "real", spend: str = "ceiling",
                 route: Optional[Sequence[Point]] = None, fps: Optional[int] = None,
                 m: Optional[geometry.LevelMap] = None,
                 max_waves: Optional[int] = None,
                 max_frames: int = 300000, seed: int = 0,
                 initial_placements: Sequence[Tuple[str, Cell]] = (),
                 candies: Sequence[CandyUse] = (),
                 candy_duration_rank: int = 0) -> None:
        t = scene.tables
        self.scene = scene
        self.fps = int(fps or t.constants.fps)
        self.cycle = cycle
        self.spend = spend
        self.max_waves = max_waves
        self.max_frames = int(max_frames)
        self.seed = int(seed)
        self.rng = random.Random(self.seed)
        self.initial_placements = tuple(initial_placements)
        if not 0 <= int(candy_duration_rank) <= 10:
            raise ValueError("Candy duration rank must be between 0 and 10")
        self.candy_duration_rank = int(candy_duration_rank)
        self.candy_uses: Dict[str, CandyUse] = {}
        for use in candies:
            if not isinstance(use, CandyUse):
                raise TypeError("candies must contain CandyUse records")
            if not 1 <= int(use.level) <= 10 or int(use.count) < 1:
                raise ValueError(f"invalid Candy use {use!r}")
            t.candy(use.id)  # fail loudly on an unknown recipe
            old = self.candy_uses.get(use.id)
            if old is not None and old.level != int(use.level):
                raise ValueError(f"Candy {use.id!r} has two requested levels")
            self.candy_uses[use.id] = CandyUse(
                use.id, int(use.level), int(use.count) + (old.count if old else 0))
        if "everlasting_gob" in self.candy_uses and len(self.candy_uses) == 1:
            raise ValueError("Everlasting Gob needs another active Candy to freeze")
        self.active_candies: Dict[str, ActiveCandy] = {}
        self._candy_started = False
        self._candy_gob_pending = self.candy_uses.get("everlasting_gob")
        self.candy_freeze_waves = 0
        self.candy_freeze_active_wave = 0
        self.candy_wave_live = False
        self.ter = ter if ter is not None else terrain.Terrain(6.0, "uniform")
        self.diff = scene.difficulty
        self.const = t.constants
        self.cycle_obj = t.cycle
        self.return_frames = int(round(self.cycle_obj.return_frames))
        # scr_tower_shoot: swing_frame = min(period, max(6, swing_seconds*fps))
        # - the attack ART is capped, it is not as long as the fire period
        # (LL-054).  Read from tower_levels.gml, so a retune moves the sim.
        self.swing_cap = max(6, math.floor(t.constants.tower_swing_seconds
                                          * self.fps))
        self.map = m if m is not None else geometry.load_map(
            t.root, cell=t.constants.cell)
        # scr_level_start: spawn_timer = _fps * 5.9, but it only counts down once
        # level_state_time >= _fps * 3 - so the deploy wait is BOTH of them, and
        # the first wave starts ~8.9s in.  The extra frame is the request
        # latency: the counter lands on 0 on the LAST counting frame, the
        # `spawn_timer <= 0` test sees it on the next one, and scr_level_begin
        # applies the change on the frame after that.
        self.deploy_frames = (int(round(t.constants.start_message_seconds * self.fps))
                             + int(round(t.constants.wave_gap_frames)) + 1)
        self.track = Track(route if route is not None else scene.longest_route())
        self.length = self.track.length
        self.cov = policy.coverage_for(scene)
        # the height the z_climb lerp converges on.  scr_zomb_pathSpeed HALVES a
        # cell that sits at load_max, so the tallest terrain is NOT the slowest -
        # terrain.ground_height owns that rule, and this is the same number.
        self.ground_z = terrain.ground_height(self.ter.mean_z)

        # the run's carried money fraction (LL-042).  ``scr_kill_money`` keeps
        # it on _levelControl; this is the same accumulator, and it is why a
        # x1.25 column really is +25% over a wave instead of +0%.
        self.money_carry = 0.0
        self.frame = 0
        self.life_max = t.constants.start_life + scene.clover_max_life
        self.lives = self.life_max
        self.life_loss_carry = 0.0
        self.boss_saves_remaining = scene.clover_boss_saves
        self.money = scene.starting_money
        self.monsters: List[SimMonster] = []
        self.towers: List[SimTower] = []
        self.built: set = set()
        # cell -> the tower standing in it, so a rung can find its tower
        # without scanning the list (and so an upgrade and a placement can
        # never both claim one cell)
        self._onboard: Dict[object, SimTower] = {}
        # frames until the next mid-wave affordability scan (instant only)
        self.buy_scan_left = 0
        self.out = Outcome(cycle=cycle, spend=spend, terrain_z=self.ground_z,
                           start_money=self.money, start_life=self.lives)

    def _active_candy_magnitude(self, field_name: str) -> float:
        """Add a Candy axis exactly as ``candy_active_magnitude`` does."""
        total = 0.0
        for candy_id, active in self.active_candies.items():
            if active.remaining_frames <= 0:
                continue
            total += self.scene.tables.candy(candy_id).magnitude(
                active.level).get(field_name, 0.0)
        return total

    def _candy_has_active(self) -> bool:
        return any(state.remaining_frames > 0
                   for state in self.active_candies.values())

    def _candy_start(self) -> None:
        """Activate selected duration Candy at the first live wave."""
        if self._candy_started:
            return
        self._candy_started = True
        duration_seconds = self.const.candy_base_seconds * (
            1.0 + self.candy_duration_rank * self.const.candy_duration_per_rank)
        frames_per_use = round(duration_seconds * self.const.candy_frame_hz)
        for candy_id, use in self.candy_uses.items():
            if candy_id == "everlasting_gob":
                continue
            self.active_candies[candy_id] = ActiveCandy(
                level=use.level, remaining_frames=frames_per_use * use.count)
            self.out.candy_used[candy_id] = (use.level, use.count)
            self.out.candy_active_frames[candy_id] = 0
        self._refresh_tower_stats()

    def _candy_wave_begin(self, wave: int, boss: bool) -> None:
        self.candy_wave_live = True
        if self.candy_freeze_waves > 0 and self.candy_freeze_active_wave <= 0:
            self.candy_freeze_active_wave = wave
        # The Gob waits for a boss so its first freeze is spent on a meaningful
        # wave. This is deterministic policy; the player can choose otherwise.
        use = self._candy_gob_pending
        if boss and use is not None and self._candy_has_active():
            magnitude = self.scene.tables.candy(use.id).magnitude(use.level)
            frozen = max(1, int(magnitude.get("freeze_waves", 1))) * use.count
            self.candy_freeze_waves += frozen
            self.candy_freeze_active_wave = wave
            self.out.candy_used[use.id] = (use.level, use.count)
            self.out.candy_frozen_waves += frozen
            self._candy_gob_pending = None

    def _candy_wave_end(self, wave: int) -> None:
        self.candy_wave_live = False
        if self.candy_freeze_active_wave == wave:
            self.candy_freeze_waves = max(0, self.candy_freeze_waves - 1)
            self.candy_freeze_active_wave = 0

    def _tick_candies(self) -> None:
        """Consume frames until scr_level_wait sees no obj_mon instances."""
        if not self.candy_wave_live:
            return
        if (self.candy_freeze_waves > 0
                and self.candy_freeze_active_wave == self.wave):
            return
        expired = False
        for candy_id, active in self.active_candies.items():
            if active.remaining_frames <= 0:
                continue
            active.remaining_frames -= 1
            self.out.candy_active_frames[candy_id] = (
                self.out.candy_active_frames.get(candy_id, 0) + 1)
            if active.remaining_frames <= 0:
                expired = True
        if expired:
            self._refresh_tower_stats()

    def _refresh_tower_stats(self) -> None:
        """Re-resolve placed towers when a Candy starts or expires."""
        damage = self._active_candy_magnitude("damage")
        fire_rate = self._active_candy_magnitude("fire_rate")
        reach = self._active_candy_magnitude("range")
        for tower in self.towers:
            stats = self._tower_stats(tower.tower, tower.level)
            tower.hit = stats.damage * (1.0 + damage)
            tower.rate = stats.fire_rate * (1.0 + fire_rate)
            tower.reach = stats.range * (1.0 + reach)
            tower.targets = stats.targets
            tower.projectiles = stats.projectiles
            tower.knockback = stats.knockback

    def _tower_stats(self, tower: Tower, level: int) -> tables.TowerStats:
        return self.scene.tables.tower_stats(
            tower, level, self.scene.clover_damage, self.scene.clover_rate,
            self.scene.clover_crit_chance, self.scene.clover_crit_damage,
            self.scene.growth_spec_rank)

    # -- the wave's creature, read the way the closed form reads it ---------
    def stat_waves(self, wave: int) -> int:
        """``STATINV.waves`` during ``wave`` - which is ``seed + wave``.

        ``_levelControl/Create_0`` seeds the item and ``scr_level_spawn`` raises
        it as each wave STARTS, so during wave N it reads ``seed + N``.  The seed
        was 1 while ``wave_count`` started at 0, so the speed ramp
        (``scr_zomb_pathSpeed`` reads ``get_item_value(STATINV.waves)``) computed
        for wave N+1 - the monsters were a wave faster than the ramp intends, and
        the HUD number and the level log were one high with them.

        The seed is 0 since LL-044, so the item equals ``wave_count`` and this is
        the identity.  It is READ from the GML (``constants.wave_seed``) rather
        than assumed, because the two tools have to agree: the closed form
        (``model.demand`` -> ``terrain.walk_seconds``) has always passed the TRUE
        wave, so while the seed was 1 the sim and the closed form were modelling
        the ramp one wave apart.
        """
        return self.const.wave_seed + wave

    def wave_spec(self, wave: int) -> Tuple[bool, int, float, float, float]:
        """``(boss, count, per-monster life, speed, kill_money)`` for ``wave``.

        ``count`` and ``life`` come straight out of :func:`model.demand`, so the
        sim's idea of what a wave IS cannot drift from the closed form's - the
        whole point is that the two differ only in what the dynamics make of it
        (LL-021).  ``speed`` and ``kill_money`` come from the same bank the closed
        form uses for that kind of wave.
        """
        d = model.demand(self.scene, wave, self.ter)
        # the STAGE's own creatures (scene.monsters / scene.bosses are built
        # from the row), falling back to the whole bank only if a row names
        # none - a bank mean is not a stage's demand (see model.demand)
        own = self.scene.bosses if d.boss else self.scene.monsters
        every = self.scene.tables.bosses if d.boss else self.scene.tables.monsters
        bank = list(own) or list(every)
        pool = list(range(len(bank)))
        speed = model.mean_field(bank, pool, "speed", 1)
        if d.boss:
            # a boss pays wave+1: scr_level_spawn OVERWRITES the bank's value
            kill_money = float(wave + 1)
        else:
            kill_money = model.mean_field(bank, pool, "kill_money", 1)
        return d.boss, d.count, d.hp, speed, kill_money

    # -- targeting ---------------------------------------------------------
    def _dist(self, tw: SimTower, m: SimMonster) -> float:
        return math.dist((tw.x, tw.y), (m.x, m.y))

    def _find_all_range(self, tw: SimTower) -> List[SimMonster]:
        """``find_all_range(x, y, obj_mon, range, targets)`` - nearest first.

        The cap takes the monsters CLOSEST TO THE TOWER, by circle distance
        exactly as the GML does - not the ones furthest along the route.
        """
        found = [m for m in self.monsters
                 if m.alive and self._dist(tw, m) <= tw.reach]
        found.sort(key=lambda m: self._dist(tw, m))
        # the widest list any tower ever holds is what decides whether a
        # `targets` cap can EVER fill - Pina Collider's 10 is the live question
        # (economy-prices-rebalance), and this is the measurement of it
        if len(found) > self.out.peak_in_range:
            self.out.peak_in_range = len(found)
        return found[:tw.targets]

    def _deal_damage(self, monster: SimMonster, amount: float,
                     source_tower: int = -1) -> float:
        """Apply damage through the same vulnerability multiplier as the game."""
        if not monster.alive or amount <= 0:
            return 0.0
        vuln = monster.statuses.get("vuln")
        multiplier = 1.0
        if vuln is not None and vuln.frames > 0:
            multiplier += min(4.0, max(0.0, vuln.amount))
        final = amount * multiplier
        applied = min(final, max(0.0, monster.life))
        monster.life -= final
        if source_tower >= 0 and source_tower < len(self.towers):
            self.towers[source_tower].dealt += applied
        return applied

    def _apply_status(self, monster: SimMonster, effect: HitStatus,
                      source_tower: int,
                      wildfire_signature: bool = False) -> None:
        """Apply one proc, matching status_apply's refresh/stack rules."""
        if not monster.alive or monster.life <= 0:
            return
        mult = effect.mult
        amount = effect.amount
        frames = max(1, round(effect.seconds * self.fps))
        status_class = "boss" if monster.boss else "elite" if monster.elite else "normal"
        if status_class in ("boss", "elite") and effect.kind in (
                "slow", "stun", "root"):
            factor = self.scene.tables.status_cc.get(status_class, {}).get(
                effect.kind, 1.0)
            frames = max(1, round(frames * factor))

        old = monster.statuses.get(effect.kind)
        if old is None or old.frames <= 0:
            monster.statuses[effect.kind] = SimStatus(
                effect.kind, mult, amount, frames,
                1, source_tower, wildfire_signature)
            return

        if effect.kind == "slow":
            old.mult = min(old.mult, mult)
        if effect.kind == "poison":
            old.stacks = min(old.stacks + 1, 5)
        stronger = amount >= old.amount
        old.amount = max(old.amount, amount)
        if stronger:
            old.source_tower = source_tower
        if effect.kind == "burn":
            old.frames += frames
        else:
            old.frames = max(old.frames, frames)
        if wildfire_signature:
            old.wildfire_signature = True

    def _apply_hit(self, tower: SimTower, monster: SimMonster,
                   stats: tables.TowerStats, base_hit: float) -> None:
        """One committed direct packet and its crit/signature side effects."""
        if not monster.alive or monster.life <= 0:
            return
        key = tower.tower.specialization
        strength = self.scene.tables.specialization_strength(
            self.scene.growth_spec_rank)
        sig_crit = 0.0
        bleed = monster.statuses.get("bleed")
        if (tower.name == "Meat Bulb" and key == "ripper"
                and stats.tier_limit >= 3 and bleed is not None
                and bleed.frames > 0):
            sig_crit = 0.25 * strength
        crit_chance = min(1.0, max(
            0.0, stats.crit_chance + sig_crit
            + self._active_candy_magnitude("crit_chance")))
        crit_damage = max(
            1.0, stats.crit_damage
            + self._active_candy_magnitude("crit_damage"))
        critical = self.rng.random() < crit_chance

        if stats.knockback > 0:
            push = stats.knockback * (0.25 if monster.boss else 1.0)
            displacement = min(push, self.length * 0.02)
            monster.dist = max(0.0, monster.dist - displacement)
            monster.x, monster.y = self.track.at(monster.dist)

        monster.last_hit_tower_money_bonus = min(
            1.0, max(0.0, tower.tower.money_bonus + stats.money))
        hit = base_hit * (crit_damage if critical else 1.0)
        vuln = monster.statuses.get("vuln")
        if (tower.name == "Meat Bulb" and key == "tenderizer"
                and stats.tier_limit >= 3 and vuln is not None
                and vuln.frames > 0):
            hit *= 1.0 + 0.20 * strength
        self._deal_damage(monster, hit, tower.tower_index)

        if (critical and tower.name == "Cannon Tulip" and key == "deadeye"
                and stats.tier_limit >= 3):
            already_hit = {id(target) for target in (tower.target or [])}
            candidates = [candidate for candidate in self.monsters
                          if candidate.alive and candidate.life > 0
                          and id(candidate) not in already_hit
                          and self._dist(tower, candidate) <= tower.reach]
            candidates.sort(key=lambda candidate: self._dist(tower, candidate))
            if candidates:
                self._deal_damage(candidates[0], hit * 0.50 * strength,
                                  tower.tower_index)

    def _apply_shot_statuses(self, tower: SimTower,
                             targets: Sequence[SimMonster],
                             stats: tables.TowerStats,
                             projectiles: int) -> None:
        """Apply the locked status list after all direct packets in a volley."""
        wildfire = (tower.name == "Burning Ivy"
                    and tower.tower.specialization == "wildfire"
                    and stats.tier_limit >= 3)
        for effect in stats.statuses:
            for monster in targets:
                for _projectile in range(projectiles):
                    if not monster.alive or monster.life <= 0:
                        break
                    if self.rng.random() >= effect.chance:
                        continue
                    mult, amount = effect.mult, effect.amount
                    if effect.kind == "slow":
                        mult = max(0.05, 1.0 - (1.0 - mult)
                                   * (1.0 + self._active_candy_magnitude("slow")))
                    elif effect.kind == "burn":
                        amount *= 1.0 + self._active_candy_magnitude("burn_damage")
                    before = 0
                    old_poison = monster.statuses.get("poison")
                    if effect.kind == "poison" and old_poison is not None:
                        before = old_poison.stacks if old_poison.frames > 0 else 0
                    applied_effect = HitStatus(effect.kind, effect.chance,
                                               mult, amount, effect.seconds)
                    self._apply_status(
                        monster, applied_effect, tower.tower_index,
                        wildfire_signature=wildfire and effect.kind == "burn")
                    if effect.kind == "poison" and before < 5:
                        poison = monster.statuses.get("poison")
                        if poison is not None and poison.frames > 0 and poison.stacks >= 5:
                            self._deal_damage(monster, amount * 5,
                                              tower.tower_index)

    @staticmethod
    def _status_speed_multiplier(monster: SimMonster) -> float:
        mult = 1.0
        for status in monster.statuses.values():
            if status.frames <= 0:
                continue
            if status.kind in ("stun", "root"):
                return 0.0
            if status.kind == "slow":
                mult = min(mult, status.mult)
        return min(1.0, max(0.0, mult))

    def _tick_statuses(self, monster: SimMonster) -> None:
        """One end-of-Step tick, including DoT and status expiration."""
        expired = []
        for kind, status in monster.statuses.items():
            if status.frames <= 0:
                expired.append(kind)
                continue
            if monster.alive and monster.life > 0:
                amount = 0.0
                if kind in ("burn", "poison"):
                    amount = status.amount * (status.stacks if kind == "poison" else 1) / self.fps
                elif kind == "bleed":
                    amount = status.amount * abs(monster.path_speed)
                if amount > 0:
                    self._deal_damage(monster, amount, status.source_tower)
            status.frames -= 1
            if status.frames <= 0:
                expired.append(kind)
        for kind in expired:
            monster.statuses.pop(kind, None)

    # -- the towers (scr_runState / scr_tower_*) ---------------------------
    def _step_towers(self) -> None:
        for tw in self.towers:
            if tw.mode == "nominal":
                self._step_tower_nominal(tw)
                continue
            # obj_tower/Step_0: the ATTACK TIMER ticks in every state, so a
            # tower with nothing to shoot is READY when something arrives
            # (LL-054).  The CYCLE is the fire period PLUS the return PLUS this
            # tower own stagger - the wait the old scr_tower_normal put after
            # every return, and the number the closed form charges
            # (Cycle.offset_mean).  Capping the SWING therefore shortens no
            # tower cycle: a fast tower fires the moment it finishes
            # returning, exactly as before.  The first time the cycle is known
            # the tower starts READY less its own stagger, as the GML does.
            period = (self.fps / tw.rate) if tw.rate > 0 else float(self.fps)
            cycle = period + self.return_frames + tw.time_offset
            if tw.attack_cycle <= 0:
                tw.attack_cycle = cycle
                tw.attack_timer = max(0.0, cycle - tw.time_offset)
            else:
                tw.attack_cycle = cycle
                if tw.attack_timer < tw.attack_cycle:
                    tw.attack_timer += 1
            # scr_runState: run the state, then advance the timer - unless the
            # state changed, because scr_changeState has already reset it to 0
            if not self._run_tower_state(tw):
                tw.state_time += 1

    def _run_tower_state(self, tw: SimTower) -> bool:
        """One frame of a tower's state machine.  True if it changed state."""
        if tw.state == "normal":
            # scr_tower_normal: fire when the COOLDOWN is up and something is
            # in range.  It used to wait on state_time > time_offset, i.e.
            # on a timer that had not been running while the tower was idle
            # (LL-054).
            if (tw.attack_timer >= tw.attack_cycle
                    and self._nearest(tw) is not None):
                tw.state, tw.state_time = "shoot", 0
                return True
            return False
        if tw.state == "shoot":
            return self._run_tower_shoot(tw)
        # "return" - scr_tower_return lasts as long as the return animation
        if tw.state_time >= self.return_frames:
            tw.state, tw.state_time = "normal", 0
            return True
        return False

    def _nearest(self, tw: SimTower) -> Optional[SimMonster]:
        """``instance_nearest(x, y, obj_mon)`` plus the range test ``normal`` does.

        ONE monster, not the cap: the idle state only asks whether anything is in
        range, and the capped list is built by ``find_all_range`` once the tower
        is already swinging.
        """
        best: Optional[SimMonster] = None
        best_d = 0.0
        for m in self.monsters:
            if not m.alive:
                continue
            d = self._dist(tw, m)
            if d <= tw.reach and (best is None or d < best_d):
                best, best_d = m, d
        return best

    def _run_tower_shoot(self, tw: SimTower) -> bool:
        """One frame of scr_tower_shoot.  True if it left the state."""
        if tw.state_time == 0:
            # the shot IS the cooldown restarting
            tw.attack_timer = 0
            period = (self.fps / tw.rate) if tw.rate > 0 else float(self.fps)
            # scr_tower_shoot: swing_frame = min(period, swing_cap) - the ART
            # is capped, so a slow tower strikes instead of winding up for its
            # whole fire period (LL-054)
            tw.swing_frame = min(period, self.swing_cap)
            tw.frame_number = tw.swing_frame
            # fire_frame = max(1, floor(swing_frame - time_offset)): the shot
            # lands BEFORE the swing ends, and max(1, ...) stops a very fast
            # tower firing on its entry frame
            tw.fire_frame = max(1, int(tw.swing_frame - tw.time_offset))
            tw.target = None
            tw.did_damage = False
            tw.shot_stats = self._tower_stats(tw.tower, tw.level)
            tw.shot_hit = tw.hit
            tw.shot_projectiles = tw.projectiles
        # the cached list is re-checked EVERY frame, and only a list in which
        # nothing is still ALIVE is re-scanned.  A started swing is COMMITTED:
        # the range test that used to be here cancelled a slow tower every
        # time its target walked out before the strike frame (LL-054).
        live = any(m.alive for m in (tw.target or []))
        if not live:
            tw.target = self._find_all_range(tw)
            if not tw.target:
                # nothing left to shoot: back to idle rather than holding the
                # attack pose (the playtest bug scr_tower_shoot comments on).
                # Nothing was fired, so the cooldown is put back and the tower
                # stays READY (LL-054).
                tw.wasted += 1
                tw.attack_timer = tw.attack_cycle
                tw.state, tw.state_time = "return", 0
                return True
        if not tw.did_damage and tw.state_time >= tw.fire_frame:
            tw.did_damage = True
            tw.shots += 1
            stats = tw.shot_stats or self._tower_stats(tw.tower, tw.level)
            targets = list(tw.target)
            for m in targets:
                for _projectile in range(tw.shot_projectiles):
                    if not m.alive or m.life <= 0:
                        break
                    self._apply_hit(tw, m, stats, tw.shot_hit)
            self._apply_shot_statuses(tw, targets, stats, tw.shot_projectiles)
        if tw.state_time >= tw.swing_frame:
            if not tw.did_damage:
                tw.wasted += 1                  # the target died before it landed
            tw.state, tw.state_time = "return", 0
            return True
        return False

    def _step_tower_nominal(self, tw: SimTower) -> None:
        """The cycle the closed form assumes: fire every ``Cycle.period`` frames.

        No transition frames, no wasted swings, damage on the beat.  Running this
        against ``real`` measures the state machine's cost instead of asserting
        it - and that difference is the honest size of the idealisation
        ``gm balance project`` is built on.
        """
        if self.frame < tw.next_fire:
            return
        tw.target = self._find_all_range(tw)
        if not tw.target:
            return
        tw.shots += 1
        stats = self._tower_stats(tw.tower, tw.level)
        targets = list(tw.target)
        for m in tw.target:
            for _projectile in range(stats.projectiles):
                if not m.alive or m.life <= 0:
                    break
                self._apply_hit(tw, m, stats, tw.hit)
        self._apply_shot_statuses(tw, targets, stats, stats.projectiles)
        tw.next_fire = self.frame + self.cycle_obj.period(tw.rate)

    # -- the monsters (scr_zombie_*) ---------------------------------------
    def _step_monsters(self) -> None:
        for m in self.monsters:
            # an instance created during another instance's Step does not run its
            # own Step until the next frame, so a monster spawned this frame waits
            if not m.alive or m.spawn_frame >= self.frame:
                continue
            if not self._run_mon_state(m):
                m.state_time += 1
            # obj_mon/Step_0 calls status_tick() last, even after the life
            # check requests DEATH and returns from scr_zomb_step().
            self._tick_statuses(m)
        alive = sum(1 for m in self.monsters if m.alive)
        if self.cur is not None:
            self.cur.peak_alive = max(self.cur.peak_alive, alive)
        self.out.peak_alive = max(self.out.peak_alive, alive)
        # The controller and Candy tick ran earlier this frame; remove a body
        # only after its final DIE Step, as scr_zombie_die() does.
        self.monsters = [
            m for m in self.monsters
            if m.alive or (m.killed and m.corpse_until_frame > self.frame)
        ]

    def _run_mon_state(self, m: SimMonster) -> bool:
        """One frame of a monster's state.  True if it changed state."""
        # scr_zomb_step checks life before dispatching EMERGE or PATH. Damage
        # dealt while a creature rises therefore persists and can kill it.
        if m.life <= 0:
            self._kill(m)
            return True

        if m.state == "emerge":
            # scr_zombie_emerge: the grow lasts 60 frames; life is not reset.
            if m.state_time >= 60:
                m.state, m.state_time = "walk", 0
                return True
            return False

        # walk - scr_zombie_path
        if m.state_time == 0:
            m.z_climb = EMERGE_START_Z      # scr_zombie_path sets it on entry
            return False
        # state_time > 0: scr_zomb_pathSpeed, then death, then updatePosition
        m.z_climb += (self.ground_z - m.z_climb) * Z_CLIMB_LERP
        speed = terrain.walk_speed(m.z_climb, self.stat_waves(m.wave), m.speed,
                                   self.diff.speed)
        m.path_speed = speed * self._status_speed_multiplier(m)
        m.dist += m.path_speed
        m.x, m.y = self.track.at(m.dist)
        m.walk_frames += 1
        if m.dist >= self.length:           # lose_life, at the despawn
            self._leak(m)
            return True
        return False

    def _payout(self, base: float, boss: bool = False, scale: float = 1.0,
                clover_bonus: bool = True) -> int:
        """``scr_kill_money``: the ramp, the column, and the CARRIED fraction.

        Three rules in the order the game applies them:

        1. the wave ramp - ``base * (1 + slope * (wave - 1))``, skipped for a
           boss because its base is already ``wave + 1`` (scr_level_spawn);
        2. the difficulty money column;
        3. the fraction, CARRIED rather than rounded.

        Step 3 is LL-042.  Money is a count, so the game used to ``round`` the
        column at the payout site - and on a base of 1 that made Hard's x1.25 a
        no-op while Brutal's x1.50 doubled, so hp-per-dollar was WORST on Hard.
        The carry lives on the run (``money_carry`` on ``_levelControl``) and
        this is the same rule, so the sim cannot disagree with the purse about
        what a wave earned.
        """
        ramp = 1.0 if boss else 1 + self.const.kill_money_slope * max(
            0, self.wave - 1)
        # `scale` is the LEAK share (0.5): it multiplies BEFORE the floor, so
        # the fraction is carried like every other fraction (LL-042).  Halving
        # the rounded payout instead would pay 0 for the cheapest creature.
        # scr_zomb_death applies clover kill/boss bonuses to kills. lose_life
        # calls scr_kill_money with the raw monster payout, so a leak receives
        # half the base payout and carries its fraction without those bonuses.
        bonus = (self.scene.clover_kill_money
                 + self._active_candy_magnitude("kill_money")) if clover_bonus else 0.0
        if boss and clover_bonus:
            bonus += self.scene.clover_boss_reward
        want = base * (1 + bonus) * ramp * self.diff.money * scale + self.money_carry
        pay = math.floor(want)
        self.money_carry = want - pay
        return int(pay)

    def _wildfire_on_death(self, monster: SimMonster) -> None:
        """Spread a marked Wildfire burn once, to the nearest living target."""
        burn = monster.statuses.get("burn")
        if (burn is None or not burn.wildfire_signature
                or burn.amount <= 0 or burn.frames <= 1):
            return
        burn.wildfire_signature = False
        nearby = [candidate for candidate in self.monsters
                  if candidate is not monster and candidate.alive
                  and candidate.life > 0
                  and math.dist((monster.x, monster.y),
                                (candidate.x, candidate.y)) <= 64.0]
        nearby.sort(key=lambda candidate: math.dist(
            (monster.x, monster.y), (candidate.x, candidate.y)))
        if not nearby:
            return
        frames = max(1, math.floor(burn.frames * 0.50))
        self._apply_status(
            nearby[0], HitStatus("burn", 1.0, 1.0, burn.amount * 0.50,
                                 frames / self.fps), -1)

    def _kill(self, m: SimMonster) -> None:
        """Settle a kill now; keep its obj_mon corpse through the DIE clip."""
        self._wildfire_on_death(m)
        base = m.kill_money * (1.0 + m.last_hit_tower_money_bonus)
        paid = self._payout(base, boss=m.boss)
        self.money += paid
        m.alive, m.killed = False, True
        m.death_frame = self.frame
        m.corpse_until_frame = self.frame + max(
            1, int(round(self.const.zombie_die_seconds * self.fps)))
        self.out.kills += 1
        self.out.money_earned += paid
        self.out.hp_killed += m.max_life
        self.out.walk_frames.append(m.walk_frames)
        if not m.boss:
            self.out.candy_pity_bonus_progress += self._active_candy_magnitude(
                "pity_fill")
        if self.cur is not None:
            self.cur.kills += 1
            self.cur.money_earned += paid

    def _leak(self, m: SimMonster) -> None:
        """``lose_life``: Vitality-adjusted life loss and HALF raw kill money.

        A leak used to pay nothing, so it cost a life AND the income the kill
        would have paid - the starvation spiral in the 2026-10-12 log. The game
        passes the raw creature payout to scr_kill_money at half scale; the
        clover kill and boss bonuses are only supplied by scr_zomb_death.
        """
        life_loss = 0
        if m.boss and self.boss_saves_remaining > 0:
            self.boss_saves_remaining -= 1
        else:
            # lose_life carries the fraction of a life actually lost. With
            # no Vitality this is one per leak; 25% prevention loses 3 per 4.
            self.life_loss_carry += 1.0 - self.scene.clover_life_loss_reduction
            life_loss = math.floor(self.life_loss_carry)
            self.life_loss_carry -= life_loss
            self.lives -= life_loss
        if self.cur is not None:
            self.cur.lives_lost += life_loss
            self.cur.lives_end = self.lives
        paid = self._payout(m.kill_money, boss=m.boss, scale=0.5,
                            clover_bonus=False)
        self.money += paid
        self.out.money_earned += paid
        m.alive, m.leaked = False, True
        self.out.leaks += 1
        self.out.walk_frames.append(m.walk_frames)
        if self.cur is not None:
            self.cur.leaks += 1
            self.cur.money_earned += paid

    # -- the whole stage ---------------------------------------------------
    def run(self) -> Outcome:
        """Step the stage to CLEAR, to game over, or to the frame ceiling."""
        self._init_level()
        while self.frame < self.max_frames:
            self._step_level()
            if self.out.cleared:
                break
            self._tick_candies()
            self._step_towers()
            self._step_monsters()
            if self.lives <= 0:
                # scr_main_normal: life <= 0 is the game-over test, and it zeroes
                # the counter before leaving the state
                self.lives = 0
                self.out.failed = True
                break
            self.frame += 1
        self._finish()
        return self.out

    def _finish(self) -> None:
        out = self.out
        out.frames = self.frame
        out.lives_left = max(0, self.lives)
        out.towers = len(self.towers)
        out.towers_built = len(self.towers)
        out.shots = sum(tw.shots for tw in self.towers)
        out.wasted = sum(tw.wasted for tw in self.towers)
        out.money_spent = sum(w.spent for w in out.waves)
        out.truncated = bool(not out.failed and self.max_waves
                             and self.wave < self.scene.waves)
    # -- spending ----------------------------------------------------------
    def _buy(self) -> List[SimTower]:
        """What the purse buys right now, under ``self.spend``.

        THREE things the ``balance-sim-policy`` card measured, all fixed here:

        * **the towers already standing are passed in** (``standing``).  Before
          this the policy was told which cells were TAKEN and nothing else, so
          a rung on an existing tower was invisible to it and the sim never
          upgraded anything - it could only ever buy new $5 Daisies;
        * **a rung is a competitor** (``allow_rungs``), scored by
          economy.md 4.6's inequality: gain in effective dps per dollar against
          the best new placement;
        * **the ranking is UNION coverage** (``spread``).  Additive coverage
          double-counts a stretch of route that two towers both shoot, which is
          why the old policy put 15 towers on 41% of a 1841px route with the
          last quartile empty.  ``dps x covered-share`` is what the shop card
          implies; ``dps x NOT-YET-covered share`` is what a monster actually
          faces.
        """
        if self.spend == "none":
            return []
        standing = [(tw.cell, tw.tower, tw.level) for tw in self.towers]
        bought = policy.plan(self.scene, self.money, cov=self.cov,
                             taken=self.built, allow_rungs=True, spread=True,
                             clover_damage=self.scene.clover_damage,
                             clover_rate=self.scene.clover_rate,
                             standing=standing,
                             candy_damage=self._active_candy_magnitude("damage"),
                             candy_rate=self._active_candy_magnitude("fire_rate"),
                             candy_range=self._active_candy_magnitude("range"),
                             candy_crit_chance=self._active_candy_magnitude("crit_chance"),
                             candy_crit_damage=self._active_candy_magnitude("crit_damage"))
        out: List[SimTower] = []
        for b in bought.buys:
            if b.price > self.money:
                continue
            self.money -= b.price
            tw = self._onboard.get(b.cell)
            if tw is not None:
                self._upgrade(tw, b)      # a rung on a tower already standing
            else:
                out.append(self._place(b))
                self.built.add(b.cell)
        return out

    def _upgrade(self, tw: SimTower, buy: policy.Buy) -> None:
        """Raise a standing tower to the level the policy just paid for."""
        stats = self._tower_stats(buy.tower, buy.level)
        tw.level = buy.level
        tw.hit = stats.damage * (1.0 + self._active_candy_magnitude("damage"))
        tw.rate = stats.fire_rate * (1.0 + self._active_candy_magnitude("fire_rate"))
        tw.reach = stats.range * (1.0 + self._active_candy_magnitude("range"))
        tw.targets = stats.targets
        tw.projectiles = stats.projectiles
        tw.knockback = stats.knockback

    def _instant_buy(self) -> None:
        """Spend the purse mid-wave - the policy a person actually plays.

        Cheap to gate: nothing is planned until the purse can afford the
        cheapest tower in the loadout, and the scan is throttled to
        ``INSTANT_SCAN_FRAMES`` so a 60fps step does not re-run a greedy over
        every free cell on every frame.
        """
        cheapest = min((t.price for t in self.scene.loadout if t.price > 0),
                       default=0.0)
        if cheapest <= 0 or self.money < cheapest:
            return
        before_money, before_n = self.money, len(self.towers)
        self._buy()
        if self.cur is not None:
            self.cur.spent += before_money - self.money
            self.cur.towers_built += len(self.towers) - before_n
            self.cur.towers = len(self.towers)

    def _place(self, buy: policy.Buy) -> SimTower:
        """Stand a tower in a cell, at the stats the ladder gives its level."""
        cx, cy = self.map.centre_of(*buy.cell)
        stats = self._tower_stats(buy.tower, buy.level)
        tw = SimTower(
            cell=buy.cell, tower=buy.tower, level=buy.level, x=cx, y=cy,
            hit=stats.damage * (1.0 + self._active_candy_magnitude("damage")),
            rate=stats.fire_rate * (1.0 + self._active_candy_magnitude("fire_rate")),
            reach=stats.range * (1.0 + self._active_candy_magnitude("range")),
            targets=stats.targets, projectiles=stats.projectiles,
            knockback=stats.knockback,
            # time_offset = irandom_range(1,8) per tower (obj_tower/Create_0).
            # The MEAN is the expected cost of the stagger, and the steady-state
            # cycle length depends on it - the spread only de-syncs a row.
            time_offset=int(round(self.cycle_obj.offset_mean)),
            mode=self.cycle, tower_index=len(self.towers))
        self.towers.append(tw)
        self._onboard[buy.cell] = tw
        return tw

    # -- the level flow (scr_level_step) -----------------------------------
    def _init_level(self) -> None:
        # _levelControl/Create_0 sets level_state = NONE and
        # level_state_next = START, so scr_level_begin APPLIES that request on the
        # very first Step - which is what gives START its level_state_time == 0
        # entry block (and the 3s + 5.9s deploy countdown).  Entering START
        # directly instead would skip it and start wave 1 at frame 6.
        self.state = "NONE"
        self.st = 0                    # level_state_time
        self.pending: Optional[str] = "START"
        self.spawn_timer = 0
        self.wait_timer = 0            # scr_setupSpawning: wait_timer = 0
        self.spawn_current = 0
        self.wave = 0
        self.cur: Optional[WaveResult] = None
        setup_cost = 0.0
        for name, cell in self.initial_placements:
            if cell in self.built:
                raise ValueError(f"duplicate initial tower cell: {cell}")
            tower = next((item for item in self.scene.loadout
                          if item.name == name), self.scene.tables.tower(name))
            price = float(tower.price)
            level = self.scene.floor_level
            stats = self._tower_stats(tower, level)
            reach = stats.range
            dps = self.scene.tables.cycle.dps(
                stats.damage, stats.fire_rate, targets=1,
                projectiles=stats.projectiles)
            multi = (stats.damage * stats.fire_rate * stats.targets
                     * stats.projectiles)
            buy = policy.Buy(cell, tower, level, price, dps,
                             self.cov.of(cell, reach), multi)
            self._place(buy)
            self.built.add(cell)
            setup_cost += price
        self.out.setup_cost = setup_cost

    def _step_level(self) -> None:
        """One frame of scr_level_step: apply a request, or advance a timer."""
        if self.pending is not None:
            self.state, self.st, self.pending = self.pending, 0, None
        else:
            self.st += 1
        if self.state == "START":
            self._step_start()
        elif self.state == "SPAWN":
            self._step_spawn()
        elif self.state == "WAIT":
            self._step_wait()
        else:
            self.out.cleared = True

        # instant spending: money that lands mid-wave becomes a tower within a
        # quarter-second, instead of idling until the next wave boundary and
        # being counted as if the player had fought the wave without it
        if self.spend == "instant" and self.state in ("SPAWN", "WAIT"):
            self.buy_scan_left -= 1
            if self.buy_scan_left <= 0:
                self.buy_scan_left = INSTANT_SCAN_FRAMES
                self._instant_buy()

    def _step_start(self) -> None:
        """scr_level_start: the deploy countdown antes up the first wave."""
        if self.st == 0:
            self.spawn_timer = int(round(self.const.wave_gap_frames))
        if self.spawn_timer <= 0 and self.st > 5:
            self.pending = "SPAWN"
        if self.st >= self.const.start_message_seconds * self.fps:
            self.spawn_timer -= 1

    def _step_spawn(self) -> None:
        """scr_level_spawn: one creature every 0.5s until MAX are out."""
        if self.st == 0:
            self.wave += 1
            boss, count, life, speed, kill_money = self.wave_spec(self.wave)
            if self.wave == 1:
                self._candy_start()
            self._candy_wave_begin(self.wave, boss)
            count = max(1, int(count))
            self.cur = WaveResult(
                wave=self.wave, boss=boss, count=count, hp=count * life,
                spawn_frame=self.frame, end_frame=self.frame, life=life,
                speed=speed, kill_money=kill_money, lives_start=self.lives,
                lives_end=self.lives, money_start=self.money,
                towers=len(self.towers))
            self.out.waves.append(self.cur)
            before = len(self.towers)
            self._buy()                      # the purse is spent at the top of it
            self.cur.towers_built = len(self.towers) - before
            self.cur.spent = self.cur.money_start - self.money
            # money the top-of-wave plan could not turn into anything:
            # either nothing was affordable or nothing on the board beat
            # the bar.  High here means the income cannot be spent.
            self.cur.idle = self.money
        cur = self.cur
        if cur is not None and cur.count > self.spawn_current:
            self.wait_timer -= 1
            if self.wait_timer <= 0:
                self.wait_timer = int(round(self.const.spawn_gap_frames))
                self._spawn_monster()
        else:
            self.spawn_current = 0
            self.spawn_timer = int(round(self.const.wave_gap_frames))
            self.pending = "WAIT"

    def _step_wait(self) -> None:
        """scr_level_wait: the gate only counts while the field is CLEAR."""
        if not self.monsters:
            if self.cur is not None and self.cur.clear_frame == 0:
                # the frame the field emptied - the split between "fighting" and
                # "waiting for the 354-frame gate" is what tells a stage's length
                # apart from its difficulty
                self.cur.clear_frame = self.frame
                self._pay_wave_income()
                self._candy_wave_end(self.wave)
            self.spawn_timer -= 1
        if self.spawn_timer <= 0:
            if self.cur is not None:
                self.cur.end_frame = self.frame
                self.cur.towers = len(self.towers)
                self.cur.money_end = self.money
                if self.wave % 5 == 0 and self.scene.clover_regen > 0:
                    self.lives = min(self.life_max,
                                     self.lives + self.scene.clover_regen)
                self.cur.lives_end = self.lives
            done = (self.wave >= self.scene.waves
                    or (self.max_waves is not None and self.wave >= self.max_waves))
            self.pending = "CLEAR" if done else "SPAWN"

    def _pay_wave_income(self) -> None:
        """Pay Money Marigold's per-clear income with the shared money carry."""
        for tower in self.towers:
            if tower.name != "Money Marigold" or tower.tower.wave_income <= 0:
                continue
            level = min(10, max(1, int(round(tower.level))))
            stats = self._tower_stats(tower.tower, level)
            base = min(3.0, tower.tower.wave_income
                       + math.floor((level - 1) * 0.5))
            mastery_scale = 1.0
            if level > 5 and len(self.scene.tables.ladder) >= 5:
                ladder = self.scene.tables.ladder
                mastery_scale = (ladder[min(level, len(ladder)) - 1].damage
                                 / max(0.01, ladder[4].damage))
            earned = base * mastery_scale * (1.0 + stats.money) + stats.income
            key = tower.tower.specialization
            strength = self.scene.tables.specialization_strength(
                self.scene.growth_spec_rank)
            if stats.tier_limit >= 3 and key == "compound_interest":
                earned *= min(1.0 + 0.20 * strength,
                              math.pow(1.0 + 0.02 * strength,
                                       max(0, self.wave - 1)))
            elif (stats.tier_limit >= 3 and key == "golden_harvest"
                  and self.wave % 5 == 0):
                earned += 5.0 * strength
            if earned <= 0:
                continue
            total = earned + self.money_carry
            paid = math.floor(total)
            self.money_carry = total - paid
            self.money += paid
            self.out.money_earned += paid
            if self.cur is not None:
                self.cur.money_earned += paid

    def _spawn_monster(self) -> None:
        cur = self.cur
        x, y = self.track.at(0.0)
        m = SimMonster(boss=cur.boss, max_life=cur.life, life=cur.life,
                       spawn_frame=self.frame, wave=cur.wave, speed=cur.speed,
                       kill_money=cur.kill_money, x=x, y=y)
        self.monsters.append(m)
        self.spawn_current += 1          # scr_level_spawn: spawn_current++
        self.out.spawned += 1
        self.out.hp_total += cur.life


def common_deployment_cells(scenes: Sequence[Scene], count: int = 4) -> List[Cell]:
    """Choose repeatable cells reachable by every tower in every scene.

    Loadout comparisons use the same four cells so they measure combat
    effects instead of placement luck. The cells greedily cover the route using
    the smallest range present in the compared loadouts, making each position
    valid for every tower under test.
    """
    if not scenes or count <= 0:
        return []
    first = scenes[0]
    route = first.longest_route()
    if not route:
        return []
    ranges = []
    for scene in scenes:
        for tower in scene.loadout:
            ranges.append(scene.tower_stats(tower, scene.floor_level).range)
    if not ranges:
        return []
    reach = min(ranges)
    m = geometry.load_map(first.tables.root, cell=first.tables.constants.cell)
    candidates = geometry.slots(m, route, reach)
    cov = policy.Coverage(m, route, geometry.polyline_length(route))
    covered = frozenset()
    chosen: List[Cell] = []
    while candidates and len(chosen) < count:
        cell = max(candidates, key=lambda c: len(cov.indices(c, reach) - covered))
        marginal = cov.indices(cell, reach) - covered
        if not marginal:
            break
        chosen.append(cell)
        covered |= cov.indices(cell, reach)
        candidates.remove(cell)
    if len(chosen) != count:
        raise ValueError(f"only {len(chosen)} common deploy cells for {count} towers")
    samples = geometry.sample_points(route, 4.0)
    def route_order(cell: Cell) -> int:
        centre = m.centre_of(*cell)
        return min(range(len(samples)), key=lambda i: math.dist(centre, samples[i]))
    chosen.sort(key=route_order)
    return chosen
