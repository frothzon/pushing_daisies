"""The level's grid and route - the geometry a run happens on.

THE GEOMETRY IS DETERMINISTIC, THE TERRAIN IS NOT.  ``rm_test`` is a fixed room
(2048x1024, 27 walls, six spawns, one despawn) so the *buildable ground*, the
*route* and therefore *how many towers can be placed* are all read straight out
of the ``.yy``.  What varies between launches is the ground height
(``scr_main_startup`` calls ``create_perlin_grid(..., random_get_seed())``),
and that feeds exactly one thing that matters here: walk speed
(``scr_zomb_pathSpeed``).  For a tower, ``obj_tower/Create_0`` sets ``inWater``
and ``obj_tower/Draw_0`` only uses it to sink the sprite - water does NOT block
a placement; only walls, the spawn and other towers do
(``obj_tower_edit/Step_0``).  So the only randomised input to a run is the
speed the route is walked at - see :mod:`gm.balance.terrain`.

ONE SOURCE FOR "WHICH CELL IS THIS" (LL-027).  The grid origin is
``(-cell, -cell)``, so a world point's cell is ``(x + cell) div cell`` - the
same expression ``obj_tower/Create_0``, ``obj_tower_edit/Step_0``,
``scr_grid_block_instances`` and ``scr_curve_slots`` all use.  This module uses
it too rather than inventing a second convention.
"""

from __future__ import annotations

import heapq
import math
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple

from .. import yy

Point = Tuple[float, float]
Cell = Tuple[int, int]

#: the eight neighbour steps, in a fixed order so the search is deterministic
_STEPS: Tuple[Cell, ...] = (
    (1, 0), (-1, 0), (0, 1), (0, -1),
    (1, 1), (1, -1), (-1, 1), (-1, -1),
)


@dataclass
class LevelMap:
    """A room, reduced to what a run needs.

    ``blocked`` holds the cells a monster cannot walk through (walls) and
    ``occupied`` the cells a tower cannot be built on (walls plus the spawn) -
    kept apart because they are two different questions.  Both are in the
    game's own grid coordinates, origin ``(-cell, -cell)``.
    """

    room: str
    width: int
    height: int
    cell: int
    grid_w: int
    grid_h: int
    blocked: Set[Cell] = field(default_factory=set)
    occupied: Set[Cell] = field(default_factory=set)
    spawns: List[Point] = field(default_factory=list)
    despawn: Point = (0.0, 0.0)
    walls: List[Point] = field(default_factory=list)

    # -- the one cell convention -----------------------------------------
    def cell_of(self, x: float, y: float) -> Cell:
        """The cell that CONTAINS a world point (``scr_grid_block_instances``)."""
        return (int((x + self.cell) // self.cell), int((y + self.cell) // self.cell))

    def centre_of(self, c: int, r: int) -> Point:
        """The world centre of a cell - where a tower's origin stands."""
        return (c * self.cell - self.cell * 0.5, r * self.cell - self.cell * 0.5)

    def cols(self) -> int:
        return self.grid_w + 2

    def rows(self) -> int:
        return self.grid_h + 2

    def walkable(self, c: int, r: int) -> bool:
        if c < 0 or r < 0 or c >= self.cols() or r >= self.rows():
            return False
        return (c, r) not in self.blocked

    def buildable(self, c: int, r: int) -> bool:
        if c < 0 or r < 0 or c >= self.cols() or r >= self.rows():
            return False
        return (c, r) not in self.occupied


def load_map(root: Path, room: str = "rm_test", cell: int = 32) -> LevelMap:
    """Read a room's grid: walls, spawns, despawn.

    A missing room, or one with no despawn, raises - a tester that silently
    invented a map would report a run nobody can play.
    """
    path = Path(root) / "rooms" / room / f"{room}.yy"
    if not path.exists():
        raise FileNotFoundError(f"no room {room!r} at {path}")
    d = yy.load(path)
    settings = d["roomSettings"]
    width, height = int(settings["Width"]), int(settings["Height"])

    m = LevelMap(room=room, width=width, height=height, cell=cell,
                 grid_w=width // cell, grid_h=height // cell)

    for layer in d.get("layers", []):
        for inst in layer.get("instances") or []:
            obj = (inst.get("objectId") or {}).get("name")
            x, y = float(inst["x"]), float(inst["y"])
            if obj == "obj_wall":
                m.walls.append((x, y))
            elif obj == "obj_spawn":
                m.spawns.append((x, y))
            elif obj == "obj_despawn":
                m.despawn = (x, y)

    for x, y in m.walls:
        m.blocked.add(m.cell_of(x, y))
    m.occupied = set(m.blocked)
    for x, y in m.spawns:
        m.occupied.add(m.cell_of(x, y))

    if not m.spawns:
        raise ValueError(f"{room}: no obj_spawn instances")
    if m.despawn == (0.0, 0.0):
        raise ValueError(f"{room}: no obj_despawn instance")
    return m


# ---------------------------------------------------------------------------
# the route
# ---------------------------------------------------------------------------
def _octile(a: Cell, b: Cell) -> float:
    dx, dy = abs(a[0] - b[0]), abs(a[1] - b[1])
    return (dx + dy) + (math.sqrt(2) - 2) * min(dx, dy)


def find_cells(m: LevelMap, start: Point, goal: Point,
               extra_blocked: Iterable[Cell] = ()) -> Optional[List[Cell]]:
    """A* over the grid, 8-directional, in the game's own cell space.

    DIAGONALS CANNOT CUT A CORNER: a diagonal step is only taken when both of
    its orthogonal neighbours are walkable.  The game asks ``mp_grid_path``
    with ``allowdiag = true``, and a corner-cut would let the tester's route
    squeeze between two wall cells that a 32px monster cannot fit through -
    which would read as an optimistically short route.

    The search is deterministic (fixed neighbour order, no randomness), but it
    is an independent A*, not a bit-for-bit copy of GameMaker's: where several
    routes are the same length the tie-break may differ.  ``gm balance route``
    prints the length so it can be checked against the in-game panel, which is
    the authority.
    """
    blocked = set(extra_blocked)
    s, g = m.cell_of(*start), m.cell_of(*goal)
    if not m.walkable(*g):
        return None
    if s == g:
        return [s]
    if not m.walkable(*s) or s in blocked:
        return None

    def passable(c: int, r: int) -> bool:
        return m.walkable(c, r) and (c, r) not in blocked

    open_heap: List[Tuple[float, int, Cell]] = [(0.0, 0, s)]
    came: Dict[Cell, Cell] = {}
    cost: Dict[Cell, float] = {s: 0.0}
    seen = 0
    while open_heap:
        _, _, here = heapq.heappop(open_heap)
        if here == g:
            out = [here]
            while here in came:
                here = came[here]
                out.append(here)
            out.reverse()
            return out

        for dc, dr in _STEPS:
            nxt = (here[0] + dc, here[1] + dr)
            if not passable(*nxt):
                continue
            if dc and dr:
                if not passable(here[0] + dc, here[1]) or not passable(here[0], here[1] + dr):
                    continue
                step = math.sqrt(2)
            else:
                step = 1.0
            new_cost = cost[here] + step
            if nxt in cost and new_cost >= cost[nxt] - 1e-12:
                continue
            cost[nxt] = new_cost
            came[nxt] = here
            seen += 1
            heapq.heappush(open_heap, (new_cost + _octile(nxt, g), seen, nxt))
    return None


def route_points(m: LevelMap, start: Point, goal: Point,
                 extra_blocked: Iterable[Cell] = ()) -> Optional[List[Point]]:
    """The walkable polyline from ``start`` to ``goal``, or ``None``.

    Cell centres, with the exact start and goal pinned on the ends - which is
    what ``mp_grid_path`` hands a monster, and what its length is measured from.
    """
    cells = find_cells(m, start, goal, extra_blocked)
    if cells is None:
        return None
    pts: List[Point] = [(float(start[0]), float(start[1]))]
    pts.extend(m.centre_of(c, r) for c, r in cells[1:-1])
    if len(cells) > 1:
        pts.append((float(goal[0]), float(goal[1])))
    return pts


def polyline_length(pts: Sequence[Point]) -> float:
    return sum(math.dist(pts[i], pts[i + 1]) for i in range(len(pts) - 1))


def sample_points(pts: Sequence[Point], every: float = 16.0) -> List[Point]:
    """Points every ``every`` px along a polyline - ``scr_curve_slots``' walk."""
    if len(pts) < 2 or every <= 0:
        return list(pts)
    out: List[Point] = [pts[0]]
    for i in range(len(pts) - 1):
        a, b = pts[i], pts[i + 1]
        seg = math.dist(a, b)
        if seg <= 0:
            continue
        k = 1
        while k * every < seg:
            t = (k * every) / seg
            out.append((a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t))
            k += 1
    if out[-1] != pts[-1]:
        out.append(pts[-1])
    return out


def slots(m: LevelMap, route: Sequence[Point], reach: float,
          taken: Iterable[Cell] = ()) -> List[Cell]:
    """Every free cell whose centre is within ``reach`` of the route.

    A port of ``scr_curve_slots``: walk the route in 16px steps, and for each
    step mark every cell whose centre is inside the range.  ``taken`` excludes
    cells already holding towers.

    This is the ceiling money alone does not capture - money buys towers, but
    only these cells can shoot the path (economy.md 4.5).
    """
    if not route or reach <= 0:
        return []
    taken_set = set(taken)
    half = int(math.ceil(reach / m.cell))
    found: Set[Cell] = set()
    for px, py in sample_points(route, 16.0):
        c, r = m.cell_of(px, py)
        for dx in range(-half, half + 1):
            for dy in range(-half, half + 1):
                cell = (c + dx, r + dy)
                if cell in found or cell in taken_set:
                    continue
                cx, cy = m.centre_of(*cell)
                if math.dist((px, py), (cx, cy)) > reach:
                    continue
                found.add(cell)
    out = [c for c in found if m.buildable(*c)]
    out.sort()
    return out


def covered_length(route: Sequence[Point], cell: Cell, reach: float,
                   cell_size: int) -> float:
    """How much of the ROUTE one cell can shoot, in px.

    A tower's worth is not "touches the path or not": while a monster is inside
    the range the tower is firing, so the damage it delivers per monster is
    ``dps x (time in range)``, and the time in range is this length over the
    monster's speed.  A cell covering a long straight leg is worth far more
    than one clipping a corner, and this is the number that says so.
    """
    cx, cy = (cell[0] * cell_size - cell_size * 0.5,
              cell[1] * cell_size - cell_size * 0.5)
    total = 0.0
    for i in range(len(route) - 1):
        a, b = route[i], route[i + 1]
        seg = math.dist(a, b)
        if seg <= 0:
            continue
        if math.dist(a, (cx, cy)) <= reach and math.dist(b, (cx, cy)) <= reach:
            total += seg
            continue
        steps = max(2, int(seg / 4))
        inside = sum(
            1 for k in range(steps + 1)
            if math.dist((a[0] + (b[0] - a[0]) * k / steps,
                          a[1] + (b[1] - a[1]) * k / steps), (cx, cy)) <= reach
        )
        total += seg * inside / (steps + 1)
    return total


