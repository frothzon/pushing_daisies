"""The read-out - what the tester prints, and how to read it.

The format follows the in-game panel (``META [CURVE]``) deliberately: the two
are meant to be compared, so a human switching between the Output window and
this output should be reading the same shape of line.
"""

from __future__ import annotations

from typing import Iterable, List, Optional, Sequence

from . import model, policy, tables, terrain
from .model import Row, Scene
from .tables import Tables

WIDTH = 78


def rule(title: str = "") -> str:
    if not title:
        return "-" * WIDTH
    return "-- " + title + " " + "-" * max(0, WIDTH - len(title) - 4)


def round2(x: float) -> float:
    return round(x * 100) / 100


# ---------------------------------------------------------------------------
# the tables
# ---------------------------------------------------------------------------
def tables_report(t: Tables) -> List[str]:
    out = [rule("the tables this reads (one source per number, LL-021)")]
    for w in t.towers:
        out.append(f"   tower  {w.name:<18} ${w.price:<5g} range {w.range:<5g} "
                   f"dmg {w.damage:<5g} rate {w.fire_rate:<5g} targets {w.targets:<3d} "
                   f"nominal dps {w.dps:g}")
    for m in t.monsters:
        out.append(f"   mon    {m.name:<18} speed {m.speed:<5g} life {m.life:<6g} "
                   f"money {m.kill_money:<3d} count {m.spawn_count}")
    for m in t.bosses:
        out.append(f"   boss   {m.name:<18} speed {m.speed:<5g} life {m.life:<6g} "
                   f"money {m.kill_money:<3d} count {m.spawn_count}")
    for d in t.difficulties:
        out.append(f"   diff   {d.name:<18} seeds x{d.seeds:<4g} hp x{d.hp:<5g} "
                   f"speed x{d.speed:<5g} count +{d.count} money x{d.money:<5g} "
                   f"start x{d.life:g}")
    for r in t.regions:
        out.append(f"   region {r.region} {r.name:<14} seeds {r.seeds:<3d} "
                   f"waves {r.wave_first}+{r.wave_step}/stage  "
                   f"curve_end {r.curve_end:g} pow {r.curve_pow:g} "
                   f"boss_every {r.boss_every}")
    c = t.constants
    out.append(f"   const  fps {c.fps} start ${c.start_money:g} lives {c.start_life} "
               f"cell {c.cell} load_max {c.load_max:g}")
    out.append(f"   const  spawn gap {round2(c.spawn_gap_frames / c.fps)}s  "
               f"wave gap {round2(c.wave_gap_frames / c.fps)}s  "
               f"count div {c.count_div}  rungs {tuple(c.rung_costs)}  "
               f"cap {c.mastery_cap_base}+mastery")
    out.append(f"   ladder L1 dmg {t.ladder[0].damage:g} x{t.ladder[0].fire_rate:g} "
               f"-> L{len(t.ladder)} dmg {t.ladder[-1].damage:g} "
               f"x{t.ladder[-1].fire_rate:g}")
    return out


# ---------------------------------------------------------------------------
# the route
# ---------------------------------------------------------------------------
def route_report(scene: Scene, m=None) -> List[str]:
    out = [rule("the route (deterministic - the terrain is not)")]
    if m is not None:
        out.append(f"   room   {m.room} {m.width}x{m.height}  grid "
                   f"{m.cols()}x{m.rows()} cell {m.cell}  walls {len(m.walls)}  "
                   f"spawns {len(m.spawns)}")
    lo, hi = scene.route_spread()
    out.append(f"   route  {round(scene.route_length)}px mean over "
               f"{len(scene.routes)} spawns (spread {round(lo)}..{round(hi)}px)")
    out.append(f"   slots  {scene.slots} cells reach the longest route with "
               f"{scene.tower.name} ({scene.tower_range:g} range)")
    tower, dps, price = scene.placement()
    out.append(f"   shop   best dps/$ = {tower.name} ({dps:g} dps / ${price:g}) "
               f"- the panel's 'best placement dps'")
    return out


# ---------------------------------------------------------------------------
# the projection
# ---------------------------------------------------------------------------
def row_line(r: Row) -> str:
    tag = "BOSS" if r.boss else "    "
    return (f"   w{r.wave:<3d} {tag} {r.count:>2}x {r.hp:>8.2f}hp walk {r.walk:>6.1f}s "
            f"req {r.req:>7.1f} | ${r.money:>6.1f} buys {r.buys:>2d} -> "
            f"{r.avail:>8.1f} dps (full-target {r.avail_multi:>8.1f}, "
            f"panel {r.panel_avail:>9.1f}) | bite {r.bite:>5.2f} {r.verdict}")


def project_report(scene: Scene, cov=None, ter: Optional[terrain.Terrain] = None,
                   waves: Optional[Iterable[int]] = None) -> List[str]:
    t = scene.tables
    ter = ter or scene.terrains[0]
    title = (f"{scene.stage.region}-{scene.stage.stage} {scene.difficulty.name} "
             f"{ter}  {scene.waves}w")
    out = [rule(title),
           f"   curve  m(1) {t.life_mult(scene.stage.region, 1, scene.waves):.2f} "
           f"-> m({scene.waves}) "
           f"{t.life_mult(scene.stage.region, scene.waves, scene.waves):g}"
           f"   floor bite {model.FLOOR_BITE:g}  ceiling bite {model.CEILING_BITE:g}"]
    for r in model.project(scene, ter, waves=waves, cov=cov):
        out.append(row_line(r))
    return out


def band_report(scene: Scene, cov=None,
                terrains: Optional[Sequence[terrain.Terrain]] = None) -> List[str]:
    """The same projection across the terrain band the game can roll.

    This is why a single number is not honest: the ground height is re-rolled
    every launch, and it moves the walk speed - and therefore the demand - by a
    factor of four across the band.
    """
    terrains = list(terrains) if terrains else terrain.band(0.0, 12.0, 5)
    out = [rule("the terrain band - z is re-rolled every launch")]
    out.append(f"   {'z':>5} {'px/step':>8} {'walk':>8}  {'worst bite':>11} "
               f"{'at wave':>8}  HIGH waves")
    for ter in terrains:
        rows = model.all_waves(scene, ter, cov=cov)
        worst = max(rows, key=lambda r: r.bite)
        highs = [r.wave for r in rows if r.verdict == "HIGH"]
        speed = terrain.walk_speed(ter.mean_z, scene.waves, 1.0,
                                   scene.difficulty.speed)
        out.append(f"   {ter.mean_z:>5g} {speed:>8.3f} {worst.walk:>7.1f}s "
                   f"{worst.bite:>11.2f} {worst.wave:>8d}  "
                   f"{highs if highs else '-'}")
    return out


# ---------------------------------------------------------------------------
# the findings
# ---------------------------------------------------------------------------
def findings(scene: Scene, cov=None) -> List[str]:
    """Everything the projection says that someone should act on.

    Printed rather than implied, because every line is a claim about the GAME,
    not about the tool: the tool's job is to make them arithmetic instead of a
    feeling.
    """
    t = scene.tables
    out = [rule("findings")]
    tower, dps, price = scene.placement()
    place = dps / price
    rung = scene.rung_density()
    out.append(f"   rung vs place   place {place:.3f} dps/$   rung {rung:.3f} dps/$   "
               + ("<- rung is dominated (economy 4.6)"
                  if rung < place else "(a rung pays for itself)"))

    rows = model.all_waves(scene, cov=cov)
    low = [r.wave for r in rows if r.verdict == "LOW"]
    high = [r.wave for r in rows if r.verdict == "HIGH"]
    out.append(f"   the band        LOW {low if low else '-'}   "
               f"HIGH {high if high else '-'}")

    if low:
        out.append(f"   WAVE 1 IS TRIVIAL: bite {rows[0].bite:.2f} < "
                   f"{model.FLOOR_BITE:g} on {scene.difficulty.name}. Either the "
                   f"starting ${t.constants.start_money:g} is too generous, the "
                   f"band's floor is wrong, or wave 1 is meant to be a tutorial "
                   f"wave - decide which.")

    boss_rows = [r for r in rows if r.boss]
    plain = [r for r in rows if not r.boss and r.wave > 1]
    if boss_rows and plain:
        bmax = max(r.bite for r in boss_rows)
        amax = max(r.bite for r in plain)
        if bmax < amax:
            out.append(f"   BOSSES ARE THE EASY WAVES: worst boss bite {bmax:.2f} vs "
                       f"{amax:.2f} for an ordinary wave. A boss arrives ONE at a time "
                       f"(scr_level_spawn: MAX = 1), so the swarm is the real threat - "
                       f"and a boss that shrugs off towers (obj_mon/Alarm_0) is "
                       f"invisible to this model.")

    blind = [r.wave for r in rows if r.panel_avail <= 0 and r.avail > 0]
    if blind:
        cheapest = min(x.price for x in scene.loadout)
        out.append(f"   THE PANEL CANNOT BUY ANYTHING for waves {blind}: its formula "
                   f"prices every tower at the best dps/$ one ({tower.name}, "
                   f"${price:g}) and the purse is smaller than that. The real shop "
                   f"sells ${cheapest:g} towers.")
    out.append("   NOT IN THIS MODEL   a boss that ignores the towers, the ~2s "
               "escalation in obj_mon/Alarm_0, and player reaction - so read the bite "
               "as a lower bound on how bad a wave is.")
    return out


def feel_report(scene_for) -> List[str]:
    """The three difficulty profiles on one stage.

    ``scene_for`` is called with a difficulty name so each column gets its own
    scene - the caller should not have to know what changes between them.
    """
    out = [rule("the profile: worst bite, and where the wall is, per difficulty")]
    out.append(f"   {'difficulty':<10} {'worst bite':>10} {'at wave':>8} "
               f"{'1st HIGH':>9}  reading")
    for name in ("Normal", "Hard", "Brutal"):
        scene = scene_for(name)
        rows = model.all_waves(scene)
        worst = max(rows, key=lambda r: r.bite)
        highs = [r.wave for r in rows if r.verdict == "HIGH"]
        if not highs:
            note = "holds all the way" if worst.bite < 0.7 else "holds, but only just"
        elif highs[0] >= scene.waves:
            note = "breaks on the last wave"
        else:
            note = f"breaks from wave {highs[0]}"
        out.append(f"   {name:<10} {worst.bite:>10.2f} {worst.wave:>8d} "
                   f"{(highs[0] if highs else 0):>9}  {note}")
    return out


# ---------------------------------------------------------------------------
# the roster: the shop card against what the game delivers
# ---------------------------------------------------------------------------
def _best_coverage(cov, scene: Scene, reach: float) -> float:
    """The best share of the route any single buildable cell can shoot.

    ``Coverage.of`` is memoised on (cell, range), so calling this once per tower
    costs one route walk per distinct range - not one per cell.
    """
    if not scene.slot_cells:
        return 0.0
    return max(cov.of(cell, reach) for cell in scene.slot_cells)


def _dominated(rows: List[dict], axes: Sequence[str]) -> List[str]:
    """Which towers another entry beats on EVERY named axis.

    ``axes`` are columns where HIGHER is better; price is always lower-is-better
    and is required to be no worse.  One strict improvement is required, so two
    identical towers do not dominate each other.

    Comparing on different axis sets answers two different questions, and both
    are worth printing: ``card`` is a claim about congestion that nothing
    guarantees, so a tower can win the shop's axis and still lose the board.
    """
    out = []
    for r in rows:
        for q in rows:
            if q is r or q["price"] > r["price"]:
                continue
            if not all(q[a] >= r[a] for a in axes):
                continue
            if q["price"] < r["price"] or any(q[a] > r[a] for a in axes):
                out.append(f"{r['tower'].name} by {q['tower'].name}")
                break
    return out


def towers_report(scene: Scene, cov=None) -> List[str]:
    """Every tower in the loadout, priced four ways.

    The four measures, in the order they should be read:

    * ``card``  - ``damage x rate x targets``: what the shop prints;
    * ``x1``    - the same with ``targets = 1``: one monster at a time;
    * ``deliv`` - ``x1`` with the fire CYCLE charged (LL-040);
    * ``eff``   - ``deliv x coverage``: what actually reaches the route.

    ``$/eff`` is the price per delivered dps at the tower's best cell, and it is
    the only column a budget should be ranked by.  Every step to the right is a
    step DOWN - ``targets`` multiplies the card, congestion may not fill it, the
    cycle is not free, and a tower only shoots while something is in range.  The
    size of each drop is the point of the table.
    """
    t = scene.tables
    cyc = t.cycle
    cov = policy.coverage_for(scene, cache=cov)
    out = [rule("the roster, priced four ways")]
    out.append(f"   the shot cycle: {cyc.fps}/rate + {cyc.offset_mean:g} stagger "
               f"+ {cyc.return_frames:g} return frames (LL-040)")
    out.append(f"   {'tower':<18}{'$':>4}{'dmg':>5}{'rate':>5}{'tgt':>4}"
               f"{'card':>7}{'x1':>7}{'deliv':>7}{'cover':>7}{'eff':>6}{'$/eff':>8}")

    rows: List[dict] = []
    for w in scene.loadout:
        dmg, rate, reach = t.data_at_level(w, scene.floor_level,
                                           scene.clover_damage, scene.clover_rate)
        card = t.dps_at_level(w, scene.floor_level, scene.clover_damage,
                              scene.clover_rate)
        x1 = t.dps_at_level(w, scene.floor_level, scene.clover_damage,
                            scene.clover_rate, targets=1)
        dlv = t.delivered_dps_at_level(w, scene.floor_level, scene.clover_damage,
                                       scene.clover_rate, targets=1)
        cover = _best_coverage(cov, scene, reach)
        eff = dlv * cover
        eff_multi = cyc.dps(dmg, rate, w.targets) * cover
        dollar = (w.price / eff) if eff > 0 else float("inf")
        out.append(f"   {w.name:<18}{w.price:>4g}{dmg:>5.3g}{rate:>5.3g}"
                   f"{w.targets:>4d}{card:>7.1f}{x1:>7.1f}{dlv:>7.1f}"
                   f"{cover:>7.3f}{eff:>6.1f}{dollar:>8.2f}")
        rows.append({"tower": w, "price": w.price, "deliv": dlv, "cover": cover,
                     "eff": eff, "eff_multi": eff_multi, "dollar": dollar,
                     "card": card, "x1": x1, "reach": reach})

    out.append("   card = the shop.  x1 = one target.  deliv = x1 less the cycle. "
               "eff = deliv x cover.")

    # ---- the same tower, priced three ways ------------------------------
    # The three figures disagree about WHO is the best buy, and that is the
    # point: 'nominal dps/$' ranks Pina Collider first (the panel's belief),
    # 'single dps/$' and the delivered one do not.
    out.append("")
    out.append("   price per dps, three ways, with the shop's terms "
               "(lower is better):")
    out.append(f"     {'tower':<18}{'$/card':>9}{'$/x1':>9}{'$/eff':>9}"
               f"{'seeds':>7}{'gate':>6}")
    for r in rows:
        out.append(f"     {r['tower'].name:<18}"
                   f"{r['price'] / r['card'] if r['card'] else 0:>9.2f}"
                   f"{r['price'] / r['x1'] if r['x1'] else 0:>9.2f}"
                   f"{r['dollar']:>9.2f}"
                   f"{r['tower'].unlock:>7d}{r['tower'].gate:>6d}")

    # ---- is there a CHOICE, or one correct answer? -----------------------
    # The complaint that started this work: every comparison resolved to a
    # single tower.  Value (dps per dollar) and power (absolute dps) are the two
    # questions a player asks, so when one tower answers both the roster has no
    # decision in it.
    live = [r for r in rows if r["eff"] > 0]
    if len(live) >= 2:
        value = min(live, key=lambda r: r["dollar"])
        power = max(live, key=lambda r: r["eff"])
        out.append("")
        if value["tower"].name == power["tower"].name:
            out.append(f"   NO CHOICE   {value['tower'].name} is BOTH the best "
                       f"value (${value['dollar']:.2f} per delivered dps) and the "
                       f"strongest ({power['eff']:.1f} eff dps).")
        else:
            out.append(f"   A CHOICE    best value {value['tower'].name} "
                       f"(${value['dollar']:.2f}/dps) vs best tower "
                       f"{power['tower'].name} ({power['eff']:.1f} eff dps)")

        # --- dominance, on two different axis sets -------------------------
        # STRICT: price, the card, one target, and the board.  Nothing in the
        # roster is beaten on all four.
        # ON THE BOARD: price and the delivered figure - the comparison a
        # player actually faces, with the congestion claim removed.  A tower
        # that loses here is bought only for its ceiling.
        strict = _dominated(live, ["card", "x1", "eff"])
        play = _dominated(live, ["eff"])
        out.append("   dominated   every axis (price+card+x1+eff): "
                   + (", ".join(strict) if strict else "none"))
        out.append("   dominated   on the board (price + delivered): "
                   + (", ".join(play) if play else "none"))
        spread = max(r["dollar"] for r in live) / min(r["dollar"] for r in live)
        out.append(f"   $/eff spread {spread:.1f}x across the roster "
                   f"(1.0x would mean one tower in four skins)")

    # ---- what a FULL target cap would be worth (the ceiling) -------------
    multi = [r for r in rows if r["tower"].targets > 1]
    if multi:
        out.append("")
        out.append("   congestion CEILING - what the cap would be worth if it were")
        out.append("   always full.  Nothing guarantees that: monsters spawn 0.5s "
                   "apart and")
        out.append("   walk ~1.3px a step, so a range holds a few, not ten.")
        for r in multi:
            ratio = (r["eff_multi"] / r["eff"]) if r["eff"] else 0.0
            out.append(f"     {r['tower'].name:<18} targets {r['tower'].targets:>2d}  "
                       f"x1 {r['eff']:>7.1f}  full {r['eff_multi']:>8.1f}  "
                       f"ceiling {ratio:>5.1f}x  (both columns are "
                       f"coverage-weighted eff dps)")
    return out


def sim_report(o, scene=None) -> List[str]:
    """What the time-stepped run did, wave by wave.

    The columns are the questions a ratio cannot answer: how long each wave
    actually took, how much of that was spent waiting for the next one, how many
    leaked, what the purse did, and how much effective damage the towers dealt.
    """
    out = [rule("the sim: what actually happens")]
    who = (f"{scene.stage.region}-{scene.stage.stage} on {scene.difficulty.name}   "
           if scene is not None else "")
    out.append(f"   {who}cycle {o.cycle}   spend {o.spend}   z {o.terrain_z:g}")
    if scene is not None:
        out.append(f"   progression mastery {scene.mastery}   "
                   f"floor L{scene.floor_level}/cap L{scene.tables.cap(scene.mastery)}   "
                   f"clover damage +{scene.clover_damage:.1%}   "
                   f"fire rate +{scene.clover_rate:.1%}")
    if o.failed:
        verdict = "FAILED"
    elif o.truncated:
        verdict = f"stopped after {len(o.waves)} waves"
    else:
        verdict = "CLEARED"
    out.append(f"   {verdict} in {o.frames} frames ({o.frames / 60:.1f}s)   "
               f"lives {o.lives_left}/{o.start_life}   "
               f"kills {o.kills}/{o.spawned}   leaks {o.leaks}")
    out.append("")
    out.append(f"   {'wave':>4}{'n':>4}{'hp':>8}{'fight':>7}{'gate':>7}"
               f"{'kills':>7}{'leak':>6}{'lives':>7}{'money':>7}{'spent':>7}"
               f"{'tow':>5}")
    lives = o.start_life
    for w in o.waves:
        lives -= w.leaks
        # the gate is the 354 frames the countdown runs, INCLUSIVE of the frame
        # it lands on; fighting is everything from the first spawn to the frame
        # the field emptied.  They add up to the wave's whole span.
        gate = (w.end_frame - w.clear_frame + 1) if w.clear_frame else 0
        fight = (w.clear_frame - w.spawn_frame) if w.clear_frame else w.frames
        out.append(f"   {w.wave:>4}{w.count:>4}{w.hp:>8.0f}"
                   f"{fight / 60:>7.1f}{gate / 60:>7.1f}{w.kills:>7}{w.leaks:>6}"
                   f"{max(0, lives):>7}{w.money_earned:>7.0f}{w.spent:>7.0f}"
                   f"{w.towers:>5}")
    out.append("")
    out.append(f"   money    started {o.start_money:.0f}  earned {o.money_earned:.0f}  "
               f"spent {o.money_spent:.0f}  left {o.money_left:.0f}")
    out.append(f"   damage   hp killed {o.hp_killed:.0f} of {o.hp_total:.0f}")
    pct = (100.0 * o.wasted / o.shots) if o.shots else 0.0
    out.append(f"   towers   {o.towers} built   swings {o.shots} "
               f"({o.wasted} achieved nothing, {pct:.0f}%)")
    out.append(f"   targets  the widest list any tower held was {o.peak_in_range} "
               f"of its cap, with {o.peak_alive} alive at once - so a `targets` "
               f"of 10 is at best {100 * o.peak_in_range // 10}% reachable here")
    if o.walk_frames:
        out.append(f"   walking  the {len(o.walk_frames)} that died took "
                   f"{o.mean_walk:.0f} frames ({o.mean_walk / 60:.1f}s) each; "
                   f"peak {o.peak_alive} alive at once")
    else:
        out.append(f"   walking  nothing died; peak {o.peak_alive} alive at once")
    return out


def sim_findings(o, scene=None) -> List[str]:
    """The two or three things the run says that a ratio could not.

    ``fight``/``gate`` are separated on purpose: a stage that is 40% gate is
    LONG, not hard, and the two get confused when only the total is reported.
    """
    out = [rule("what the sim says")]
    fighting = sum((w.clear_frame - w.spawn_frame) for w in o.waves if w.clear_frame)
    total = sum(w.frames for w in o.waves) or 1
    out.append(f"   the gate   {100.0 * (total - fighting) / total:.0f}% of the "
               f"waves' time is the between-wave gap - {total - fighting} of "
               f"{total} frames waiting, not fighting")
    if o.shots:
        out.append(f"   the cycle  {100.0 * o.wasted / o.shots:.0f}% of swings "
                   f"achieved nothing")
    out.append(f"   the purse  ${o.money_left:.0f} unspent at the end"
               + ("  <- the ladder ran out of things worth buying"
                  if o.money_left >= 10 * max(1, o.towers // 4) else ""))
    if o.waves:
        # what the top-of-wave plan COULD NOT turn into anything.  A high figure
        # is the measurable form of "the income cannot be spent" - the purse
        # arrives in $1-3 chunks and the cheapest tower costs $5.
        idle = [w.idle for w in o.waves]
        worst = max(range(len(idle)), key=lambda i: idle[i])
        out.append(f"   idle       ${sum(idle) / len(idle):.1f} sits unspent at the "
                   f"top of an average wave (worst: wave "
                   f"{o.waves[worst].wave} holding ${idle[worst]:.0f}) - money "
                   f"the player had and no tower used")
    if o.leaks == 0:
        out.append("   no leaks, so this run sits in the 'holds' band - the sim "
                   "cannot be pushed to a leak without a different policy or price")
    else:
        first = next((w.wave for w in o.waves if w.leaks), 0)
        out.append(f"   {o.leaks} leaks, the first on wave {first}, "
                   f"{o.lives_left} of {o.start_life} lives left")
    if o.failed:
        out.append("   FAILED: the game-over test is scr_main_normal's "
                   "`life <= 0`, which runs every step of the stage")
    if scene is not None:
        out.append(f"   for scale  a wave here is {o.waves[0].hp:.0f}hp on wave 1 "
                   f"rising to {o.waves[-1].hp:.0f}hp on wave {o.waves[-1].wave}"
                   if o.waves else "")
    return out


def sim_compare(real, nominal, scene=None) -> List[str]:
    """The same stage and the same policy, under both firing models.

    The point is the OUTCOME, not the arithmetic: the idealised cycle needs fewer
    towers to hold the same stage, and the size of that difference IS the error
    in anything built on the closed form.  It is roughly what
    :meth:`Tables.cycle`\\ 's continuous ``period`` leaves out - the two state
    transitions, the frame the swing is one step too long, and the swings that
    achieve nothing.
    """
    out = [rule("real cycle vs the idealised one (same stage, same policy)")]
    for label, o in (("state machine", real), ("idealised", nominal)):
        out.append(f"   {label:<14} {o.towers:>3} towers  {o.leaks:>2} leaks  "
                   f"{o.lives_left:>2}/{o.start_life} lives  "
                   f"${o.money_left:>4.0f} left  {o.frames:>6} frames")
    extra = nominal.towers - real.towers
    if extra > 0:
        out.append(f"   the idealisation is worth about {extra} tower(s) on this "
                   f"stage - so a price fitted against `deliv` dps is optimistic "
                   f"by that much")
    elif extra < 0:
        out.append(f"   the state machine CLEARED with {-extra} more tower(s) - "
                   f"check that both runs used the same policy")
    else:
        out.append("   no difference in tower count - the idealisation is not what "
                   "is deciding this stage")
    return out


def afford_report(scene: Scene) -> List[str]:
    """When the money can buy what - the ladder's real bottleneck.

    ``money_through`` is the panel's own figure (``scr_curve_money_through``), so
    the "money" column here and the in-game META [CURVE] line are the same
    number.  What this adds is the question the panel never asks: a tower that is
    affordable on paper is not a CHOICE until the player can also afford an
    alternative at the same moment.
    """
    out = [rule("when the money can buy what")]
    waves = scene.waves
    prices = sorted({w.price for w in scene.loadout if w.price > 0})
    out.append(f"   {'wave':>4}{'money':>9}  " +
               "".join(f"{('$' + format(p, 'g')):>7}" for p in prices) +
               "   cheapest buyable")
    for k in range(1, waves + 1):
        money = model.money_through(scene, k)
        counts = "".join(f"{int(money // p):>7d}" for p in prices)
        first = next((w.name for w in sorted(scene.loadout, key=lambda x: x.price)
                      if w.price > 0 and money >= w.price), "-")
        out.append(f"   {k:>4}{money:>9.0f}  {counts}   {first}")

    out.append("")
    out.append("   the columns are HOW MANY of that price the purse holds.  "
               "'cheapest")
    out.append("   buyable' is not the same thing as a choice.")
    for w in sorted(scene.loadout, key=lambda x: x.price):
        if w.price <= 0:
            continue
        at = next((k for k in range(1, waves + 1)
                   if model.money_through(scene, k) >= w.price), None)
        out.append(f"     {w.name:<18} ${w.price:<5g} " +
                   (f"from wave {at}" if at else
                    f"NEVER in this {waves}-wave stage"))
    out.append(f"   total money in the stage: ${model.money_through(scene, waves):.0f}"
               f" over {waves} waves")
    return out


