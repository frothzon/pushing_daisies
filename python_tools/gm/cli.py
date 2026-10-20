"""Command line interface: ``python -m gm <command>``.

Run ``python -m gm --help`` for the full list of commands.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, List, Optional, Tuple

from . import events as events_mod
from . import gml as gml_mod
from . import progress as progress_mod
from . import project as project_mod
from . import save as save_mod
from . import yy


def _load_project(args: argparse.Namespace) -> "project_mod.Project":
    return project_mod.Project(args.project)


def _print(value: Any, as_json: bool = False) -> None:
    if as_json or not isinstance(value, str):
        print(json.dumps(value, indent=2, ensure_ascii=False))
    else:
        print(value)


def _parse_value(text: str, force_json: bool, force_raw: bool) -> Any:
    if force_raw:
        return text
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        if force_json:
            raise
        return text


def _resolve_event(spec: str) -> Tuple[int, int]:
    """Turn ``Draw_75`` or ``Create`` into an ``(eventType, eventNum)`` pair."""
    parsed = events_mod.parse_event_filename(f"{spec}.gml")
    if parsed is not None:
        type_id, num = parsed
        return type_id, int(num)
    if spec in events_mod.EVENT_TYPE_IDS:
        return events_mod.EVENT_TYPE_IDS[spec], 0
    raise SystemExit(f"unrecognised event {spec!r} (try Create, Step_0, Draw_75, ...)")


def _target_file(resource: "project_mod.Resource", event: Optional[str]) -> Path:
    if event is None:
        if resource.type == "GMScript":
            return resource.script_path()
        raise SystemExit(f"{resource.name} is not a script; pass --event, or --function")
    event_type, event_num = _resolve_event(event)
    return resource.event_path(event_type, event_num)


def _read_target(resource: "project_mod.Resource", event: Optional[str]) -> str:
    path = _target_file(resource, event)
    return gml_mod.read_gml(path) if path.exists() else ""


# -- commands ---------------------------------------------------------------
def cmd_list(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    resources = proj.resources(args.type)
    if args.json:
        print(json.dumps(
            [{"name": r.name, "type": r.type, "path": r.path} for r in resources],
            indent=2,
        ))
    else:
        for resource in resources:
            print(f"{resource.type:<10} {resource.name}")
    return 0


def cmd_info(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    resource = proj.resource(args.resource)
    print(f"name:  {resource.name}")
    print(f"type:  {resource.type}")
    print(f"path:  {resource.path}")
    if resource.type == "GMObject":
        for event_type, event_num, filename in resource.events():
            label = events_mod.event_label(event_type, event_num)
            print(f"event: {label:<16} {filename}")
    functions = resource.functions()
    if functions:
        print("funcs: " + ", ".join(functions))
    return 0


def cmd_get(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    resource = proj.resource(args.resource)
    if args.json:
        print(json.dumps(resource.data, indent=2, ensure_ascii=False))
    else:
        sys.stdout.write(resource.document().dumps())
        sys.stdout.write("\n")
    return 0


def cmd_keys(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    for key in proj.resource(args.resource).data:
        print(key)
    return 0


def cmd_get_path(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    value = project_mod.get_path(proj.resource(args.resource).data, args.keypath)
    _print(value)
    return 0


def cmd_set_path(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    resource = proj.resource(args.resource)
    value = _parse_value(args.value, args.json, args.raw)
    project_mod.set_path(resource.data, args.keypath, value, sort=not args.no_sort)
    resource.save()
    printed = json.dumps(value, ensure_ascii=False)
    print(f"set {args.resource}.{args.keypath} = {printed}")
    return 0


def cmd_del_path(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    resource = proj.resource(args.resource)
    if not project_mod.del_path(resource.data, args.keypath):
        raise SystemExit(f"{args.keypath} not found in {args.resource}")
    resource.save()
    print(f"deleted {args.resource}.{args.keypath}")
    return 0


def cmd_sort(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    for name in args.resources:
        resource = proj.resource(name)
        resource.document()
        resource.save(sort=True)
        print(f"sorted {name}")
    return 0


def cmd_events(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    for event_type, event_num, filename in proj.resource(args.resource).events():
        print(f"{event_type}\t{event_num}\t{filename}")
    return 0


def cmd_gml_functions(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    resource = proj.resource(args.resource)
    text = _read_target(resource, args.event)
    for function in gml_mod.find_functions(text):
        print(f"{function.name}({function.params})")
    return 0


def cmd_gml_get(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    resource = proj.resource(args.resource)
    text = _read_target(resource, args.event)
    if args.function:
        function = gml_mod.get_function(text, args.function)
        if function is None:
            raise SystemExit(f"function {args.function!r} not found")
        sys.stdout.write(function.source + "\n")
    else:
        sys.stdout.write(text)
    return 0


def cmd_gml_set(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    resource = proj.resource(args.resource)
    if args.file:
        new_text = Path(args.file).read_text(encoding="utf-8")
    elif args.text is not None:
        new_text = args.text
    else:
        raise SystemExit("provide --file or --text")
    if not new_text.endswith("\n"):
        new_text += "\n"

    if args.function:
        text = _read_target(resource, args.event)
        text = gml_mod.replace_function(text, args.function, new_text.rstrip("\n"))
        if not text.endswith("\n"):
            text += "\n"
        if args.event is not None:
            event_type, event_num = _resolve_event(args.event)
            resource.write_event(event_type, event_num, text)
        elif resource.type == "GMScript":
            resource.write_script(text)
        else:
            resource.write_event(0, 0, text)
    elif args.event is not None:
        event_type, event_num = _resolve_event(args.event)
        resource.write_event(event_type, event_num, new_text)
    else:
        resource.write_script(new_text)
    resource.save()
    print(f"wrote {args.resource}")
    return 0


def cmd_add_event(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    resource = proj.resource(args.resource)
    event_type, event_num = _resolve_event(args.event)
    path = resource.add_event(event_type, event_num)
    resource.save()
    print(f"added {path.relative_to(proj.root)}")
    return 0


def cmd_new_script(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    source = Path(args.source).read_text(encoding="utf-8") if args.source else None
    resource = proj.create_script(args.name, source)
    print(f"created {resource.path}")
    return 0


def cmd_new_object(args: argparse.Namespace) -> int:
    proj = _load_project(args)
    resource = proj.create_object(args.name, args.sprite, args.parent)
    print(f"created {resource.path}")
    return 0


def cmd_roundtrip(args: argparse.Namespace) -> int:
    root = Path(args.project) if args.project else project_mod.find_project_root(".")
    if args.paths:
        paths = [Path(p) for p in args.paths]
    else:
        paths = sorted(root.glob("**/*.yy"))
        paths += sorted(root.glob("*.yyp"))
        paths += sorted(root.glob("*.resource_order"))
    ok = bad = 0
    for path in paths:
        original = path.read_bytes()
        try:
            rebuilt = yy.Document.from_file(path).dumps().encode("utf-8")
        except Exception as exc:  # pragma: no cover - reported to user
            print(f"PARSE-FAIL {path}: {exc}")
            bad += 1
            continue
        if rebuilt == original:
            ok += 1
            if args.verbose:
                print(f"ok   {path}")
        else:
            bad += 1
            limit = min(len(original), len(rebuilt))
            index = next((i for i in range(limit) if original[i] != rebuilt[i]), limit)
            print(f"DIFF {path} at byte {index}")
    print(f"{ok} file(s) round-trip byte-for-byte, {bad} differ")
    return 1 if bad else 0


def cmd_balance(args: argparse.Namespace) -> int:
    """``gm balance ...`` - the headless balance tester.

    Reads the game's own tables, rebuilds the stage's route, and projects the
    curve without launching the game.  See ``python_tools/gm/balance``.
    """
    from .balance import model, policy, report, tables as btables

    proj = _load_project(args)
    root = proj.root

    if args.action == "tables":
        for line in report.tables_report(btables.load(root)):
            print(line)
        return 0

    scene_for = lambda diff: model.resolve(  # noqa: E731
        root, region=args.region, stage=args.stage, difficulty=diff,
        loadout=args.loadout, spawns=args.spawns, z=args.z)

    if args.action == "route":
        from .balance import geometry
        scene = scene_for(args.difficulty)
        m = geometry.load_map(root, cell=scene.tables.constants.cell)
        for line in report.route_report(scene, m):
            print(line)
        for i, route in enumerate(scene.routes):
            print(f"   spawn {i}  {round(scene.route_lengths[i])}px  "
                  f"{len(route)} waypoints")
        return 0

    if args.action == "project":
        from .balance import terrain as bterrain
        scene = scene_for(args.difficulty)
        cov = policy.coverage_for(scene)
        ter = bterrain.Terrain(args.z, "uniform")
        lines = report.route_report(scene)
        lines += report.project_report(scene, cov, ter)
        if args.all_waves:
            lines += [report.row_line(r)
                      for r in model.all_waves(scene, ter, cov=cov)]
        else:
            lines += report.band_report(scene, cov)
        lines += report.findings(scene, cov)
        if args.profile:
            lines += report.feel_report(
                lambda name: model.resolve(root, region=args.region,
                                           stage=args.stage, difficulty=name,
                                           loadout=args.loadout,
                                           spawns=args.spawns, z=args.z))
        for line in lines:
            print(line)
        return 0

    if args.action == "fit":
        from .balance import fit as bfit

        stages = list(args.stages) if args.stages else [args.stage]
        if args.from_value is None or args.to_value is None:
            print("fit needs a window: --from <value> --to <value> [--step 2]")
            print("   e.g.  gm balance fit --stages 1 2 3 --from 10 --to 60 --step 2")
            return 2
        try:
            cands = bfit.values(args.from_value, args.to_value, args.step)
        except ValueError as err:
            print(f"fit: {err}")
            return 2
        if not cands:
            print("fit: that window is empty")
            return 2

        base = btables.load(root)

        def measure(value):
            """One candidate: every measured stage, in band or not."""
            t2 = bfit.with_param(base, args.param, value, args.region)
            out = []
            for st in stages:
                scene = model.resolve(root, region=args.region, stage=st,
                                      difficulty=args.difficulty,
                                      loadout=args.loadout, spawns=args.spawns,
                                      z=args.z, t=t2)
                cov = policy.coverage_for(scene)
                rows = model.all_waves(scene, cov=cov)
                out.append(bfit.StageFit(
                    stage=st,
                    worst=max(r.bite for r in rows),
                    easiest=rows[0].bite,
                    lows=[r.wave for r in rows if r.verdict == "LOW"],
                    highs=[r.wave for r in rows if r.verdict == "HIGH"]))
            return out

        rows = bfit.sweep(cands, measure)
        print(report.rule(f"fit {args.param} on region {args.region}, "
                          f"{args.difficulty}, stages "
                          f"{', '.join(str(s) for s in stages)}"))
        for c in rows:
            mark = "->" if c.inside else "  "
            if c.inside:
                note = "in band"
            elif c.lows:
                note = "LOW on stage " + ",".join(str(s) for s in c.lows)
            elif c.highs:
                note = "HIGH on stage " + ",".join(str(s) for s in c.highs)
            else:
                note = "outside"
            print(f"   {mark} {args.param} {c.value:<6g} worst {c.worst:>5.2f}   {note}")

        inside = [c for c in rows if c.inside]
        pick = bfit.recommend(rows)
        if inside:
            print(report.rule("the window that fits"))
            print(f"   {args.param} {inside[0].value:g} .. {inside[-1].value:g}"
                  f"   ({len(inside)} of {len(rows)} candidates)")
        else:
            print(report.rule("nothing fits"))
            print("   No value in this window puts every measured stage in band,")
            print("   which is an answer too: the knob is not the constraint -")
            print("   look at the floor/ceiling, the roster or the wave count.")
        if pick is not None:
            print(f"   starting point: {args.param} {pick.value:g}"
                  f"  (worst {pick.worst:.2f}, band middle {bfit.TARGET:.2f})")
            print(report.rule("per stage at the starting point"))
            for line in bfit.rows_for(pick):
                print(line)

        if args.sim and inside:
            from .balance import sim as bsim
            from .balance import terrain as bterrain
            print(report.rule("the sim on the candidates that fit "
                              "(LL-042: it is the arbiter)"))
            simmed = []
            for c in inside:
                t2 = bfit.with_param(base, args.param, c.value, args.region)
                bits, holds, leaks = [], True, 0
                for st in stages:
                    scene = model.resolve(root, region=args.region, stage=st,
                                          difficulty=args.difficulty,
                                          loadout=args.loadout, spawns=args.spawns,
                                          z=args.z, t=t2)
                    o = bsim.Sim(scene, ter=bterrain.Terrain(args.z),
                                 spend="ceiling").run()
                    holds = holds and o.cleared_all
                    leaks += o.leaks
                    bits.append(f"{st}:{'clear' if o.cleared_all else 'LOST'}"
                                f"/{o.leaks}leak")
                print(f"   {args.param} {c.value:<6g} "
                      f"{'holds ' if holds else 'LOSES '}  " + "  ".join(bits))
                simmed.append((c.value, holds, leaks))

            # the arbiter gets the last word, so say what it narrowed to.  A
            # candidate that clears with leaks still fits the BAND - the bound
            # is about difficulty, not about a flawless run - so this is a
            # second, narrower window rather than a redefinition of the first.
            clean = [v for v, h, lk in simmed if h and lk == 0]
            print(report.rule("narrowed by the sim"))
            if len(clean) == len(simmed):
                print("   every candidate that fits the band also clears with no leaks")
            elif clean:
                print(f"   {args.param} {min(clean):g} .. {max(clean):g}"
                      f"   ({len(clean)} of {len(simmed)} clear every stage with no leaks)")
            else:
                print("   none of them clears clean - the band and the sim disagree")
        return 0

    if args.action == "towers":
        # the roster arithmetic: the shop card against what the game delivers.
        # Four measures per tower (card, x1, cycle-corrected, coverage-weighted)
        # and a verdict on whether the roster contains a CHOICE at all.
        scene = scene_for(args.difficulty)
        for line in report.towers_report(scene):
            print(line)
        return 0

    if args.action == "afford":
        # when the purse can buy what - the ladder's real bottleneck
        scene = scene_for(args.difficulty)
        for line in report.afford_report(scene):
            print(line)
        return 0

    if args.action == "sim":
        # the time-stepped run (gm.balance.sim): leaks, hearts and the real
        # fire cycle, which is what the closed form in `project` cannot express.
        from .balance import sim as bsim
        from .balance import terrain as bterrain
        scene = scene_for(args.difficulty)
        ter = bterrain.Terrain(args.z, "uniform")
        wants = ["real", "nominal"] if args.cycle == "both" else [args.cycle]
        runs = {mode: bsim.Sim(scene, ter=ter, cycle=mode, spend=args.spend,
                               max_waves=args.max_waves).run()
                for mode in wants}
        lines = report.sim_report(runs[wants[0]], scene)
        lines += report.sim_findings(runs[wants[0]], scene)
        if len(wants) > 1:
            lines += report.sim_compare(runs["real"], runs["nominal"], scene)
        for line in lines:
            print(line)
        return 0

    if args.action == "check":
        # the conservative gate: every number the tester needs must be readable
        t = btables.load(root)
        scene = scene_for("Normal")
        cov = policy.coverage_for(scene)
        rows = model.all_waves(scene, cov=cov)
        problems = []
        for r in rows:
            if r.hp <= 0:
                problems.append(f"wave {r.wave}: hp {r.hp}")
            if r.req < 0 or r.avail < 0:
                problems.append(f"wave {r.wave}: negative req or avail")
        for name in ("Normal", "Hard", "Brutal"):
            s = scene_for(name)
            if not s.slot_cells:
                problems.append(f"{name}: no slot can reach the route")
        print(f"   tables    {len(t.regions)} regions, {len(t.towers)} towers, "
              f"{len(t.monsters)}+{len(t.bosses)} creatures, "
              f"{len(t.ladder)} ladder rungs")
        print(f"   route     {round(scene.route_length)}px over "
              f"{len(scene.routes)} spawns, {scene.slots} slots")
        print(f"   waves     {len(rows)} projected for "
              f"{scene.stage.region}-{scene.stage.stage}")
        print(f"   payout    kill money ramp slope "
              f"{t.constants.kill_money_slope:g} per wave, carried not rounded "
              f"(LL-042); shop prices "
              f"{', '.join(str(int(x.price)) for x in t.towers[:4])}")
        if problems:
            for p in problems:
                print(f"   PROBLEM   {p}")
            return 1
        print("   ok        the tester has every number it needs")
        return 0

    print(f"unknown balance action {args.action!r}", file=sys.stderr)
    return 2


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python -m gm",
        description="Read and edit GameMaker Studio 2 project files.",
    )
    parser.add_argument("-p", "--project", metavar="DIR", help="project root directory")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("list", help="list resources")
    p.add_argument("type", nargs="?", help="filter by resource type (e.g. GMObject)")
    p.add_argument("--json", action="store_true")
    p.set_defaults(func=cmd_list)

    p = sub.add_parser("info", help="show a resource's details")
    p.add_argument("resource")
    p.set_defaults(func=cmd_info)

    p = sub.add_parser("get", help="print a resource's .yy")
    p.add_argument("resource")
    p.add_argument("--json", action="store_true", help="pretty standard JSON")
    p.set_defaults(func=cmd_get)

    p = sub.add_parser("keys", help="print a resource's top-level keys")
    p.add_argument("resource")
    p.set_defaults(func=cmd_keys)

    p = sub.add_parser("get-path", help="print a nested value (a.b.0.c)")
    p.add_argument("resource")
    p.add_argument("keypath")
    p.set_defaults(func=cmd_get_path)

    p = sub.add_parser("set-path", help="set a nested value and save")
    p.add_argument("resource")
    p.add_argument("keypath")
    p.add_argument("value")
    p.add_argument("--json", action="store_true", help="parse value as JSON (default)")
    p.add_argument("--raw", action="store_true", help="treat value as a plain string")
    p.add_argument("--no-sort", action="store_true", help="append new keys, don't sort")
    p.set_defaults(func=cmd_set_path)

    p = sub.add_parser("del-path", help="delete a nested value and save")
    p.add_argument("resource")
    p.add_argument("keypath")
    p.set_defaults(func=cmd_del_path)

    p = sub.add_parser("sort", help="rewrite resources with GameMaker key order")
    p.add_argument("resources", nargs="+")
    p.set_defaults(func=cmd_sort)

    p = sub.add_parser("events", help="list an object's events")
    p.add_argument("resource")
    p.set_defaults(func=cmd_events)

    p = sub.add_parser("gml-functions", help="list functions in a GML file")
    p.add_argument("resource")
    p.add_argument("--event", help="event name, e.g. Create_0")
    p.set_defaults(func=cmd_gml_functions)

    p = sub.add_parser("gml-get", help="print GML source")
    p.add_argument("resource")
    p.add_argument("--event", help="event name, e.g. Create_0")
    p.add_argument("--function", help="only this function")
    p.set_defaults(func=cmd_gml_get)

    p = sub.add_parser("gml-set", help="write GML source")
    p.add_argument("resource")
    p.add_argument("--event", help="event name, e.g. Create_0")
    p.add_argument("--function", help="replace only this function")
    p.add_argument("--file", help="read new source from a file")
    p.add_argument("--text", help="new source as a literal argument")
    p.set_defaults(func=cmd_gml_set)

    p = sub.add_parser("add-event", help="add an event to an object")
    p.add_argument("resource")
    p.add_argument("event", help="e.g. Create, Step_0, Draw_75")
    p.set_defaults(func=cmd_add_event)

    p = sub.add_parser("new-script", help="create a new script resource")
    p.add_argument("name")
    p.add_argument("--source", help="file with initial GML")
    p.set_defaults(func=cmd_new_script)

    p = sub.add_parser("new-object", help="create a new object resource")
    p.add_argument("name")
    p.add_argument("--sprite")
    p.add_argument("--parent")
    p.set_defaults(func=cmd_new_object)

    p = sub.add_parser("progress", help="the progress tracker (check/build/list/set/add)")
    p.add_argument("action", nargs="?", default="check",
                   choices=["check", "build", "list", "set", "add"])
    p.add_argument("rest", nargs="*", help="for set/add: <id> key=value ...")
    p.add_argument("--owner", help="list: only cards this person owns")
    p.add_argument("--awaiting", help="list: only cards waiting on this person")
    p.add_argument("--done", action="store_true", help="list: include finished cards")
    p.set_defaults(func=progress_mod.cmd_progress)

    p = sub.add_parser("balance", help="the headless balance tester")
    p.add_argument("action", nargs="?", default="project",
                   choices=["tables", "route", "project", "towers", "afford",
                            "sim", "check", "fit"])
    p.add_argument("--region", type=int, default=1)
    p.add_argument("--stage", type=int, default=1)
    p.add_argument("--difficulty", default="Normal",
                   choices=["Normal", "Hard", "Brutal"])
    p.add_argument("--loadout", nargs="+", metavar="TOWER",
                   help="the four towers to price (default: the starters)")
    p.add_argument("--spawns", default="all", choices=["all", "first"],
                   help="'first' reproduces the in-game panel's single spawn")
    p.add_argument("--z", type=float, default=6.0,
                   help="mean ground height along the route, 0..12")
    p.add_argument("--all-waves", action="store_true",
                   help="every wave instead of wave 1 / boss / last")
    p.add_argument("--profile", action="store_true",
                   help="add the Normal / Hard / Brutal comparison")
    p.add_argument("--cycle", default="real", choices=["real", "nominal", "both"],
                   help="sim: the real state machine, the idealised period, or both")
    p.add_argument("--spend", default="ceiling", choices=["none", "ceiling", "instant"],
                   help="sim: buy nothing, or re-plan the greedy at every wave")
    p.add_argument("--max-waves", type=int, default=None,
                   help="sim: stop after N waves instead of running the stage out")
    p.add_argument("--param", default="curve_end",
                   help="fit: the Region field to sweep (fit.PARAMS)")
    p.add_argument("--from", dest="from_value", type=float, default=None,
                   help="fit: first candidate value (required)")
    p.add_argument("--to", dest="to_value", type=float, default=None,
                   help="fit: last candidate value (required)")
    p.add_argument("--step", type=float, default=2.0,
                   help="fit: gap between candidates (default 2)")
    p.add_argument("--stages", nargs="+", type=int, default=None,
                   help="fit: which stages to measure (default: --stage)")
    p.add_argument("--sim", action="store_true",
                   help="fit: also run the sim on the candidates that fit")
    p.set_defaults(func=cmd_balance)

    p = sub.add_parser("save", help="inspect the meta save (LL-052)")
    p.add_argument("action", nargs="?", default="inspect", choices=["inspect"])
    p.add_argument("--file", help="a specific garden_meta.dat")
    p.set_defaults(func=save_mod.cmd_save)

    p = sub.add_parser("roundtrip", help="verify .yy files round-trip byte-for-byte")
    p.add_argument("paths", nargs="*")
    p.add_argument("-v", "--verbose", action="store_true")
    p.set_defaults(func=cmd_roundtrip)

    return parser


def main(argv: Optional[List[str]] = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main())
