"""What the ground does to a walking monster.

THE ONE RANDOM INPUT.  ``scr_main_startup`` builds the ground with
``create_perlin_grid(ground_w, ground_h, 10, load_max, random_get_seed())``, so
the height under any cell is **re-rolled every launch** and cannot be read out
of the repo.  It feeds walk speed through ``scr_zomb_pathSpeed``:

    z = LEVEL.ground_map[# cell]             the ground height, 0..12
    if z == load_max: z *= 0.5              -- the tallest ground HALVES first
    _spd = ((12 - z)/12) * 1.5 + 0.5        z = ground height, 0..12
    if z < 2: _spd = 0.25                   water is three times slower
    if _spd < 1: _spd = _spd(1-w) + w       w = 1 - 2^(-wave/30)
    _spd += 0.01 * wave
    path_speed = _spd * MON.speed * difficulty_speed

THE TALLEST GROUND IS NOT THE SLOWEST (found 2026-10-13).  That second line is
real and it is not cosmetic: ``create_perlin_grid`` floors each cell to an
INTEGER, so ``_groundHeight == load_max`` fires for the cells at the very top,
and they end up walking like ``z = 6`` - faster than ``z = 11``.  So the slowest
non-water ground in the game is z = 11 (0.625 px/step), not z = 12 (1.25), and a
terrain band that reads the top of the range as a wall of mud is reading a hill
that is not there.  :func:`ground_height` owns the rule and
:func:`walk_speed` applies it; :func:`panel_walk_speed` deliberately does not,
because ``scr_curve_walk_seconds`` takes a MEAN z along the route and does no
per-cell test.

So the honest thing is a BAND, not a point: :func:`band` brackets the z range
and every projection is reported across it.  A single number would be a
guess wearing a decimal point.

A DIVERGENCE WORTH KNOWING (found 2026-10-13).  ``scr_curve_walk_seconds``
applies that third line UNCONDITIONALLY, while ``scr_zomb_pathSpeed`` only
applies it when ``_spd < 1``.  The ramp pulls a speed TOWARD 1.0, so on flat
ground (``z <= ~7.3``, where the base is 1.0 or more) the game leaves the
speed alone and the in-game panel slows the monster down instead - the panel is
optimistic exactly where the terrain is flat.  :func:`walk_speed` implements
the GAME; :func:`panel_walk_speed` implements the panel, and
``gm balance project`` prints both so the difference is visible rather than
argued about.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from typing import List


@dataclass(frozen=True)
class Terrain:
    """One terrain assumption: a height, and where it came from."""

    mean_z: float = 6.0
    label: str = "uniform"

    def base_speed(self) -> float:
        """The GAME's base speed here: the ground rule first, then the formula."""
        return base_speed(ground_height(self.mean_z))

    def __str__(self) -> str:
        return f"z={self.mean_z:g} ({self.label})"


#: ``scr_main_startup``: ``load_max = 12``, the top of the ground map.
LOAD_MAX = 12.0
WATER_Z = 2.0                  # scr_zomb_pathSpeed: `if(z_climb < 2)`
WATER_SLOW = 0.25              # scr_zomb_pathSpeed: `_spd = 0.25`
SPEED_SLOPE = 1.5
SPEED_BASE = 0.5


def ground_height(z: float, load_max: float = LOAD_MAX) -> float:
    """A cell's height as the GAME reads it - a load_max cell halves.

    ``scr_zomb_pathSpeed``::

        var _groundHeight = LEVEL.ground_map[# _x,_y];
        if(_groundHeight == _mainControl.load_max) _groundHeight *= 0.5;

    The test is an ``==`` against a value ``create_perlin_grid`` produces with
    ``floor``, so it is a test against an INTEGER and it really does fire.  The
    consequence is that the very top of the map walks like z = 6: the slowest
    non-water ground is z = 11, not z = 12.

    Idempotent at 6, which is why applying it twice (here and in
    :func:`walk_speed`) is harmless.
    """
    z = min(max(float(z), 0.0), load_max)
    return z * 0.5 if z == load_max else z


def base_speed(z: float) -> float:
    """``((12 - z)/12) * 1.5 + 0.5``, with water pinned to 0.25.

    This is the FORMULA.  The game runs the ground rule first
    (:func:`ground_height`) - use :func:`game_base_speed` for the game's figure
    at a raw height, and :func:`base_speed` when you already hold the height the
    game would use.
    """
    z = min(max(float(z), 0.0), LOAD_MAX)
    if z < WATER_Z:
        return WATER_SLOW
    return ((LOAD_MAX - z) / LOAD_MAX) * SPEED_SLOPE + SPEED_BASE


def game_base_speed(z: float) -> float:
    """The game's base speed at a RAW ground height: ground rule, then formula."""
    return base_speed(ground_height(z))


def _ramp(speed: float, wave: int) -> float:
    """The wave weight, applied the way ``scr_zomb_pathSpeed`` applies it."""
    if speed < 1:
        w = 1 - math.pow(2, -(wave / 30))
        return speed * (1 - w) + w
    return speed


def walk_speed(z: float, wave: int, monster_speed: float = 1.0,
               difficulty_speed: float = 1.0) -> float:
    """``scr_zomb_pathSpeed``, in px per step - what the game actually does.

    ``z`` is the RAW ground height: the ground rule (:func:`ground_height`) is
    applied here because the game applies it before the formula.
    """
    spd = _ramp(base_speed(ground_height(z)), wave) + 0.01 * wave
    return spd * monster_speed * difficulty_speed


def panel_walk_speed(z: float, wave: int, monster_speed: float = 1.0,
                     difficulty_speed: float = 1.0) -> float:
    """``scr_curve_walk_seconds``, in px per step - what the panel assumes.

    No :func:`ground_height`, deliberately: the panel is handed a MEAN height
    along the route and never does a per-cell test, so it cannot halve the
    tallest cells even in principle.
    """
    z = min(max(float(z), 0.0), LOAD_MAX)
    spd = base_speed(z)
    w = 1 - math.pow(2, -(wave / 30))
    spd = spd * (1 - w) + w + 0.01 * wave
    return spd * monster_speed * difficulty_speed


def walk_seconds(length: float, z: float, wave: int, monster_speed: float = 1.0,
                 difficulty_speed: float = 1.0, fps: int = 60,
                 panel: bool = False) -> float:
    """Seconds for one monster to cross ``length`` px of route."""
    speed = (panel_walk_speed if panel else walk_speed)(
        z, wave, monster_speed, difficulty_speed)
    if speed <= 0 or length <= 0:
        return 0.0
    return (length / speed) / max(fps, 1)


def band(z_min: float = 2.0, z_max: float = 12.0, steps: int = 6) -> List[Terrain]:
    """A spread of terrains to bracket the randomness, low z first.

    z is the mean height ALONG THE ROUTE, not the whole map - and it is
    reported as a band because it is re-rolled every launch.
    """
    if steps < 2:
        steps = 2
    out: List[Terrain] = []
    for i in range(steps):
        z = z_min + (z_max - z_min) * i / (steps - 1)
        out.append(Terrain(round(z, 2), "uniform"))
    return out
