"""The headless balance tester.

Reads the game's own data tables out of GML, rebuilds the level's route and
grid, projects the curve in closed form, and time-steps a headless run so a
knob can be moved and its effect *seen* without playing sixty waves.

WHY A TESTER AND NOT MORE LOG LINES.  Every number that decides whether the
game is fun is already data (economy.md 4, goal.md 4/13): the curve in
``region_data``, the columns in ``difficulty_data``, the ladder in
``tower_levels``, the stats in ``tower_roster`` and ``scr_setupSpawning``.  Two
tables that only mean something together is the LL-022 trap, and a playtest can
only afford to answer one question per run.  This answers them by the hundred.

THE FIRST RULE: IT READS THE TABLES, IT DOES NOT RESTATE THEM.  A Python file
that repeats ``curve_end = 13`` becomes a *third* source of truth and drifts the
first time a knob moves - which is exactly the failure economy.md 4.6 documents.
``gm.balance.tables`` parses the calls, so moving a knob in GML moves the tester.

Modules:

* :mod:`gm.balance.tables`    -- the GML tables -> dataclasses
* :mod:`gm.balance.geometry`  -- the room -> grid, route, slots
* :mod:`gm.balance.terrain`   -- what the ground does to speed and placement
* :mod:`gm.balance.model`     -- the closed form (a port of ``scr_curve``)
* :mod:`gm.balance.sim`       -- the time-stepped run
* :mod:`gm.balance.policy`    -- how the money gets spent
* :mod:`gm.balance.report`    -- the read-out
"""

from . import geometry, model, policy, report, tables, terrain

__all__ = ["tables", "geometry", "terrain", "model", "policy", "report"]
