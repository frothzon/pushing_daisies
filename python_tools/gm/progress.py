"""The progress tracker: one JSON source of truth, two generated views, one gate.

``progress.json`` at the repo root is the ONLY thing anyone edits.  Two views are
generated from it and checked in, because both are read by people who will never
run a Python command:

* ``PROGRESS.md``   - renders on GitHub and at the top of the project;
* ``progress.html`` - a self-contained board that opens with a double-click.

That is the same shape as the rest of this repo - ``.yy`` files are written by
``gm``, never by hand (LL-009) - and it is guarded the same way: every generated
file carries a ``progress-sha`` fingerprint, and ``check`` FAILS if any of them
disagrees with the JSON.  Forgetting to rebuild is a red gate, not a silent lie.

Why ``awaiting`` exists
-----------------------
On a two-person project the only question that really matters is *"whose turn is
it?"*.  ``status`` says where the work is; ``awaiting`` says who has to move
next.  "blocked" is deliberately NOT a status - it is ``awaiting != none`` on an
unfinished card, so it cannot go stale.

Commands
--------
``check``   validate the JSON, then prove the generated views match it.
``build``   regenerate ``PROGRESS.md`` and ``progress.html``.
``list``    a compact board in the terminal (``--owner``, ``--awaiting``).
``set``     change fields on a card, validated, keeping canonical key order.
``add``     add a card with sensible defaults.
"""

from __future__ import annotations

import hashlib
import json
import re
from datetime import date
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Tuple

SCHEMA = 1

#: Where the cards live, in a fixed order.  The board renders the first four as
#: columns; "done" is history.
STATUSES = ["backlog", "next", "doing", "review", "done"]

#: Who has to act next.  The ``people`` keys are added to this at validation
#: time, so adding a third person needs no code change.
AWAITING = ["none", "external"]

AREAS = ["code", "art", "sound", "design", "docs", "tools", "data"]
SIZES = ["S", "M", "L"]
PHASES = ["0", "1", "2", "3", "4", "5", "infra"]
PRIOS = [1, 2, 3]

META_KEYS = ["schema", "project", "updated", "viewer", "how_to"]
PERSON_KEYS = ["name", "role", "color"]
FOCUS_KEYS = ["now", "next", "note"]
LOG_KEYS = ["date", "who", "task", "what"]
TOP_KEYS = ["meta", "people", "focus", "tasks", "log"]

TASK_KEYS = [
    "id", "title", "status", "owner", "awaiting", "area", "phase", "size",
    "prio", "needs", "notes", "refs", "created", "updated", "done",
]
TASK_REQUIRED = [
    "id", "title", "status", "owner", "awaiting", "area",
    "phase", "size", "prio", "refs", "created", "updated",
]

ID_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")

JSON_NAME = "progress.json"
MD_NAME = "PROGRESS.md"
HTML_NAME = "progress.html"


# -- canonical form ---------------------------------------------------------
def canonical(doc: Dict[str, Any]) -> Dict[str, Any]:
    """A copy with a fixed key order and the tasks sorted by ``id``.

    A stable order is not cosmetic.  This file changes several times a session,
    and a sorted, fixed-order file keeps the git diff down to the lines that
    actually changed instead of rewriting the whole document.
    """
    out: Dict[str, Any] = {}

    meta = doc.get("meta", {})
    out["meta"] = {k: meta[k] for k in META_KEYS if k in meta}

    people = doc.get("people", {})
    out["people"] = {
        key: {p: people[key][p] for p in PERSON_KEYS if p in people[key]}
        for key in sorted(people)
    }

    focus = doc.get("focus", {})
    out["focus"] = {k: focus[k] for k in FOCUS_KEYS if k in focus}

    out["tasks"] = [
        {k: t[k] for k in TASK_KEYS if k in t}
        for t in sorted(doc.get("tasks", []), key=lambda t: str(t.get("id", "")))
    ]

    # the log keeps insertion order, so a new entry is a one-line diff
    out["log"] = [{k: e[k] for k in LOG_KEYS if k in e} for e in doc.get("log", [])]
    return out


def dumps(doc: Dict[str, Any]) -> str:
    """Serialise the canonical form: 2-space indent, LF, trailing newline."""
    return json.dumps(canonical(doc), indent=2, ensure_ascii=False) + "\n"


def fingerprint(doc: Dict[str, Any]) -> str:
    """A short hash of the canonical JSON - the value the views embed."""
    return hashlib.sha256(dumps(doc).encode("utf-8")).hexdigest()[:16]


# -- reading and writing ----------------------------------------------------
def load(path: Path) -> Dict[str, Any]:
    """Read the tracker.  Raises ``SystemExit`` with a usable message."""
    try:
        text = Path(path).read_text(encoding="utf-8")
    except OSError as exc:
        raise SystemExit("cannot read %s: %s" % (path, exc))
    try:
        doc = json.loads(text)
    except json.JSONDecodeError as exc:
        raise SystemExit(
            "%s is not valid JSON: %s (line %d, column %d)"
            % (path, exc.msg, exc.lineno, exc.colno)
        )
    if not isinstance(doc, dict):
        raise SystemExit("%s: top level must be an object" % path)
    return doc


def save(path: Path, doc: Dict[str, Any]) -> None:
    Path(path).write_text(dumps(doc), encoding="utf-8")


# -- small helpers ----------------------------------------------------------
def _is_date(value: Any) -> bool:
    if not isinstance(value, str):
        return False
    try:
        date.fromisoformat(value)
        return True
    except ValueError:
        return False


def _today() -> str:
    return date.today().isoformat()


def tasks(doc: Dict[str, Any]) -> List[Dict[str, Any]]:
    items = doc.get("tasks", [])
    return items if isinstance(items, list) else []


def people_keys(doc: Dict[str, Any]) -> List[str]:
    people = doc.get("people", {})
    return sorted(people) if isinstance(people, dict) else []


def by_id(doc: Dict[str, Any]) -> Dict[str, Dict[str, Any]]:
    return {t.get("id"): t for t in tasks(doc) if isinstance(t, dict)}


def open_tasks(doc: Dict[str, Any]) -> List[Dict[str, Any]]:
    return [t for t in tasks(doc) if t.get("status") != "done"]


def sorted_for_board(items: Sequence[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Highest priority first, then earliest phase, then id - the reading order."""
    return sorted(
        items,
        key=lambda t: (
            t.get("prio", 9),
            str(t.get("phase", "")),
            str(t.get("id", "")),
        ),
    )


# -- validation -------------------------------------------------------------
def validate(doc: Dict[str, Any], root: Optional[Path] = None) -> List[str]:
    """Every reason this document is wrong, as human-readable strings.

    A list rather than an exception, so ``check`` can print all of them in one
    run - fixing four typos across four runs is how a tracker stops being used.
    """
    errs: List[str] = []

    for key in doc:
        if key not in TOP_KEYS:
            errs.append("unknown top-level key %r (valid: %s)" % (key, ", ".join(TOP_KEYS)))
    for key in TOP_KEYS:
        if key not in doc:
            errs.append("missing top-level key %r" % key)

    meta = doc.get("meta") if isinstance(doc.get("meta"), dict) else {}
    for key in meta:
        if key not in META_KEYS:
            errs.append("meta has unknown key %r" % key)
    if meta.get("schema") != SCHEMA:
        errs.append("meta.schema is %r, expected %d" % (meta.get("schema"), SCHEMA))
    if not meta.get("project"):
        errs.append("meta.project is required")
    if not _is_date(meta.get("updated")):
        errs.append("meta.updated must be YYYY-MM-DD, got %r" % (meta.get("updated"),))

    people = doc.get("people") if isinstance(doc.get("people"), dict) else {}
    if not people:
        errs.append("people must list at least one person")
    for key, person in people.items():
        if not isinstance(person, dict):
            errs.append("people.%s must be an object" % key)
            continue
        for k in person:
            if k not in PERSON_KEYS:
                errs.append("people.%s has unknown key %r" % (key, k))
        if not person.get("name"):
            errs.append("people.%s.name is required" % key)

    valid_owner = set(people) | {"both"}
    valid_awaiting = set(people) | set(AWAITING)

    # meta.viewer is who the board calls "you" - the top strip is built from it
    if meta.get("viewer") is not None and meta.get("viewer") not in people:
        errs.append("meta.viewer %r is not one of the people" % (meta.get("viewer"),))

    items = tasks(doc)
    seen: Dict[str, int] = {}
    for index, t in enumerate(items):
        where = "tasks[%d]" % index
        if not isinstance(t, dict):
            errs.append("%s is not an object" % where)
            continue

        tid = t.get("id")
        if isinstance(tid, str) and tid:
            where = "task %r" % tid
        for k in t:
            if k not in TASK_KEYS:
                errs.append("%s: unknown key %r" % (where, k))
        for k in TASK_REQUIRED:
            if k not in t:
                errs.append("%s: missing required key %r" % (where, k))

        if not isinstance(tid, str) or not ID_RE.match(tid):
            errs.append("%s: id must be kebab-case (a-z, 0-9, -)" % where)
        elif tid in seen:
            errs.append("%s: duplicate id (also at tasks[%d])" % (where, seen[tid]))
        else:
            seen[tid] = index

        if "status" in t and t["status"] not in STATUSES:
            errs.append("%s: status %r not in %s" % (where, t["status"], "/".join(STATUSES)))
        if "owner" in t and t["owner"] not in valid_owner:
            errs.append("%s: owner %r must be one of %s"
                        % (where, t["owner"], ", ".join(sorted(valid_owner))))
        if "awaiting" in t and t["awaiting"] not in valid_awaiting:
            errs.append("%s: awaiting %r must be one of %s"
                        % (where, t["awaiting"], ", ".join(sorted(valid_awaiting))))
        for key, allowed in (("area", AREAS), ("size", SIZES), ("phase", PHASES)):
            if key in t and t[key] not in allowed:
                errs.append("%s: %s %r not in %s" % (where, key, t[key], "/".join(allowed)))
        if "prio" in t and t["prio"] not in PRIOS:
            errs.append("%s: prio %r must be 1, 2 or 3" % (where, t["prio"]))

        for key in ("created", "updated"):
            if key in t and not _is_date(t.get(key)):
                errs.append("%s: %s must be YYYY-MM-DD, got %r" % (where, key, t.get(key)))

        # done-ness is a small state machine: the date and the ball agree
        status = t.get("status")
        done = t.get("done")
        if status == "done":
            if not _is_date(done):
                errs.append("%s: a done card needs done: YYYY-MM-DD" % where)
            if t.get("awaiting") != "none":
                errs.append("%s: a done card must have awaiting \"none\"" % where)
        elif "done" in t and done is not None:
            errs.append("%s: done must be null unless status is \"done\"" % where)

        # the whole point of `awaiting` is that the card says what is wanted of you
        if t.get("awaiting") not in (None, "none") and not t.get("needs"):
            errs.append(
                "%s: awaiting %r, so it needs a 'needs' line saying what they must do"
                % (where, t.get("awaiting"))
            )

        # A person's name in `awaiting` puts the card in the board's top strip,
        # so a parked card cannot claim one - otherwise the strip fills up with
        # the wishlist and stops meaning "this is on you".  (Unenforced, this
        # drifted within the hour: see LL-022's sibling habit of writing a rule
        # down and then not checking it.)
        if status == "backlog" and t.get("awaiting") not in (None, "none", "external"):
            errs.append(
                "%s: a backlog card must not be awaiting a person - nobody is holding "
                "it yet (promote it to next if they really need to act)" % where
            )

        refs = t.get("refs")
        if refs is not None and not isinstance(refs, list):
            errs.append("%s: refs must be a list of paths" % where)
        elif refs and root is not None:
            for ref in refs:
                target = str(ref).split("#", 1)[0].strip()
                if target and not (Path(root) / target).exists():
                    errs.append("%s: ref %r does not exist in the repo" % (where, ref))

    focus = doc.get("focus") if isinstance(doc.get("focus"), dict) else {}
    for key in focus:
        if key not in FOCUS_KEYS:
            errs.append("focus has unknown key %r" % key)
    known = set(seen)
    for key in ("now", "next"):
        value = focus.get(key)
        if value is None:
            continue
        if not isinstance(value, list):
            errs.append("focus.%s must be a list of task ids" % key)
            continue
        for fid in value:
            if fid not in known:
                errs.append("focus.%s points at unknown task %r" % (key, fid))

    log = doc.get("log")
    if log is None:
        pass
    elif not isinstance(log, list):
        errs.append("log must be a list")
    else:
        for index, entry in enumerate(log):
            where = "log[%d]" % index
            if not isinstance(entry, dict):
                errs.append("%s is not an object" % where)
                continue
            for k in entry:
                if k not in LOG_KEYS:
                    errs.append("%s: unknown key %r" % (where, k))
            if not _is_date(entry.get("date")):
                errs.append("%s: date must be YYYY-MM-DD, got %r" % (where, entry.get("date")))
            if entry.get("who") not in people:
                errs.append("%s: who %r is not in people" % (where, entry.get("who")))
            if not entry.get("what"):
                errs.append("%s: what is required" % where)
            task_id = entry.get("task")
            if task_id is not None and task_id not in known:
                errs.append("%s: task %r is not a card" % (where, task_id))

    return errs


# -- the markdown view ------------------------------------------------------
MD_BANNER = "<!-- GENERATED by `python -m gm progress build` from progress.json - do not edit. -->"


def _cell(text: Any) -> str:
    """One table cell: no pipes, no newlines, no surprises."""
    return str(text if text is not None else "").replace("|", "\\|").replace("\n", " ").strip()


def _bar(done: int, total: int, width: int = 10) -> str:
    if total <= 0:
        return ""
    filled = int(round(width * done / float(total)))
    return "▓" * filled + "░" * (width - filled) + " %3d%%" % round(100.0 * done / total)


def build_md(doc: Dict[str, Any]) -> str:
    """The GitHub-facing view.  Deterministic: same JSON in, same bytes out."""
    meta = doc.get("meta", {})
    people = doc.get("people", {})
    focus = doc.get("focus", {})
    byid = by_id(doc)
    items = tasks(doc)
    out: List[str] = [MD_BANNER, "<!-- progress-sha: %s -->" % fingerprint(doc), ""]

    out.append("# %s — progress" % meta.get("project", "Progress"))
    out.append("")
    out.append(
        "_Generated from [`progress.json`](progress.json) on %s · "
        "edit that file (or run `python -m gm progress set <id> …`) then "
        "`python -m gm progress build`._" % meta.get("updated", "?")
    )
    out.append("")

    now = [byid[i] for i in focus.get("now", []) if i in byid]
    nxt = [byid[i] for i in focus.get("next", []) if i in byid]
    if now or nxt or focus.get("note"):
        out.append("## Right now")
        out.append("")
        if focus.get("note"):
            out.append(focus["note"])
            out.append("")
        if now:
            out.append("**On now:** " + ", ".join("`%s` %s" % (t["id"], t["title"]) for t in now))
            out.append("")
        if nxt:
            out.append("**Next up:** " + ", ".join("`%s` %s" % (t["id"], t["title"]) for t in nxt))
            out.append("")

    # The strip the board puts at the very top, one table per person.  This is
    # the reason the file exists, so it comes before the columns.
    unfinished = [t for t in items if t.get("status") != "done"]
    for key in people_keys(doc):
        waiting = [t for t in unfinished if t.get("awaiting") == key]
        if not waiting:
            continue
        out.append("## ⏳ Waiting on %s (%d)" % (people[key].get("name", key), len(waiting)))
        out.append("")
        out.append("| Card | Title | Owner | Area | What is needed |")
        out.append("| --- | --- | --- | --- | --- |")
        for t in sorted_for_board(waiting):
            out.append("| **%s** | %s | %s | %s | %s |"
                       % (_cell(t["id"]), _cell(t.get("title")), _cell(t.get("owner")),
                          _cell(t.get("area")), _cell(t.get("needs"))))
        out.append("")

    for status in STATUSES:
        group = [t for t in items if t.get("status") == status]
        if not group:
            continue
        if status == "done":
            group = sorted(group, key=lambda t: str(t.get("done", "")), reverse=True)[:15]
        out.append("## %s (%d)" % (status.title(), len([t for t in items if t.get("status") == status])))
        out.append("")
        out.append("| Card | Title | Owner | Area | Ph | Sz | Notes |")
        out.append("| --- | --- | --- | --- | --- | --- | --- |")
        for t in sorted_for_board(group):
            out.append("| **%s** | %s | %s | %s | %s | %s | %s |"
                       % (_cell(t["id"]), _cell(t.get("title")), _cell(t.get("owner")),
                          _cell(t.get("area")), _cell(t.get("phase")), _cell(t.get("size")),
                          _cell(t.get("needs") or t.get("notes"))))
        out.append("")

    return _md_tail(doc, items, people, out)


def _md_tail(doc: Dict[str, Any], items: List[Dict[str, Any]],
             people: Dict[str, Any], out: List[str]) -> str:
    """Phases, the log, and the footer - split out only to keep edits small."""
    phases = sorted({str(t.get("phase")) for t in items})
    if phases:
        out.append("## Progress by phase")
        out.append("")
        out.append("| Phase | Done | Total | |")
        out.append("| --- | --- | --- | --- |")
        for phase in phases:
            group = [t for t in items if str(t.get("phase")) == phase]
            done = len([t for t in group if t.get("status") == "done"])
            out.append("| %s | %d | %d | %s |" % (phase, done, len(group), _bar(done, len(group))))
        out.append("")

    log = doc.get("log", [])
    if log:
        out.append("## Log (newest first)")
        out.append("")
        for entry in reversed(log[-20:]):
            who = people.get(entry.get("who"), {}).get("name", entry.get("who"))
            task = entry.get("task")
            out.append("- **%s** %s — %s%s"
                       % (_cell(entry.get("date")), _cell(who), _cell(entry.get("what")),
                          (" (`%s`)" % task) if task else ""))
        out.append("")

    out.append("---")
    out.append("")
    out.append("`progress.json` is the source of truth. `gm progress check` fails if this "
               "file and `progress.html` disagree with it (sha `%s`)." % fingerprint(doc))
    out.append("")
    return "\n".join(out)


# -- the terminal board -----------------------------------------------------
def loose_signature(doc: Dict[str, Any]) -> str:
    """A cheap signature the BROWSER can recompute.

    The HTML embeds a snapshot of the JSON so it can be opened from the file
    system with no server, and it re-fetches ``progress.json`` when it can.  This
    lets it say "this page is stale" instead of quietly showing yesterday's
    board.  Both sides sort by id with plain code-point comparison, so Python
    and JavaScript agree exactly.
    """
    rows = sorted(
        ("%s:%s:%s" % (t.get("id", ""), t.get("status", ""), t.get("updated", ""))
         for t in tasks(doc)),
        key=lambda row: row,
    )
    return "%s|%d|%s" % (
        doc.get("meta", {}).get("updated", ""),
        len(rows),
        ",".join(rows),
    )


def summary(doc: Dict[str, Any]) -> str:
    meta = doc.get("meta", {})
    counts = {s: len([t for t in tasks(doc) if t.get("status") == s]) for s in STATUSES}
    awaiting: Dict[str, int] = {}
    for t in open_tasks(doc):
        key = str(t.get("awaiting"))
        awaiting[key] = awaiting.get(key, 0) + 1
    line1 = "%s  ·  updated %s  ·  schema %s  ·  %d cards" % (
        meta.get("project", "?"), meta.get("updated", "?"),
        meta.get("schema", "?"), len(tasks(doc)),
    )
    line2 = "  ".join("%d %s" % (counts[s], s) for s in STATUSES if counts[s])
    waiting = [k for k in sorted(awaiting) if k not in ("none", "None")]
    line3 = "awaiting:  " + " | ".join("%s %d" % (k, awaiting[k]) for k in waiting) \
        if waiting else "awaiting:  nobody"
    return "\n".join([line1, line2, line3])


def board_lines(
    doc: Dict[str, Any],
    owner: Optional[str] = None,
    awaiting: Optional[str] = None,
    include_done: bool = False,
) -> List[str]:
    """A compact board for the terminal - one line per card, grouped by status."""
    out: List[str] = []
    for status in STATUSES:
        if status == "done" and not include_done:
            continue
        group = [t for t in tasks(doc) if t.get("status") == status]
        if owner:
            group = [t for t in group if t.get("owner") in (owner, "both")]
        if awaiting:
            group = [t for t in group if t.get("awaiting") == awaiting]
        if not group:
            continue
        out.append("%s (%d)" % (status.upper(), len(group)))
        for t in sorted_for_board(group):
            flag = "  " if t.get("awaiting") in (None, "none") else "->"
            out.append("  %s %-28s %-5s %-6s %s %s  %s"
                       % (flag, t.get("id"), t.get("owner"), t.get("area"),
                          t.get("phase"), t.get("size"), t.get("title")))
            if t.get("awaiting") not in (None, "none") and t.get("needs"):
                out.append("       ^ waiting on %s: %s" % (t.get("awaiting"), t.get("needs")))
        out.append("")
    return out


# -- the HTML board ---------------------------------------------------------
_HTML_CSS = """
:root{
  --bg:#14171c; --panel:#1b1f26; --panel2:#222831; --line:#2c333d;
  --fg:#e7eaef; --dim:#96a0ae; --accent:#6fb1e8; --warn:#e8a33d;
  --ok:#6fcf97; --bad:#e8736f; --radius:10px;
}
*{box-sizing:border-box}
body{margin:0;padding:22px 26px 60px;background:var(--bg);color:var(--fg);
  font:14px/1.45 ui-sans-serif,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif}
a{color:var(--accent)}
h1{font-size:21px;margin:0 0 3px}
h2{font-size:12px;text-transform:uppercase;letter-spacing:.09em;color:var(--dim);
  margin:26px 0 10px;font-weight:600}
.sub{color:var(--dim);font-size:12.5px}
.stale{background:#3a2320;border:1px solid var(--bad);color:#ffd9d6;padding:9px 13px;
  border-radius:var(--radius);margin:14px 0;font-size:13px}
.filters{display:flex;flex-wrap:wrap;gap:7px;margin:16px 0 4px}
button.chip{cursor:pointer;background:var(--panel2);color:var(--dim);border:1px solid var(--line);
  border-radius:999px;padding:4px 11px;font-size:12px;font-family:inherit}
button.chip:hover{color:var(--fg);border-color:var(--accent)}
button.chip.on{background:var(--accent);border-color:var(--accent);color:#0d1116;font-weight:600}
.strip{display:flex;flex-wrap:wrap;gap:10px}
.strip.secondary .card{opacity:.72}
.board{display:grid;gap:12px;grid-template-columns:repeat(auto-fit,minmax(215px,1fr))}
.col{background:var(--panel);border:1px solid var(--line);border-radius:var(--radius);
  padding:10px;min-height:70px}
.col>h3{margin:0 0 9px;font-size:12px;letter-spacing:.08em;text-transform:uppercase;
  color:var(--dim);display:flex;justify-content:space-between}
.col.doing>h3{color:var(--accent)}
.col.review>h3{color:var(--warn)}
.card{background:var(--panel2);border:1px solid var(--line);border-left:3px solid #3d4756;
  border-radius:8px;padding:9px 10px;width:250px;max-width:100%;position:relative}
.card.prio1{border-left-color:var(--bad)}
.card.prio2{border-left-color:var(--warn)}
.card.prio3{border-left-color:#4b5768}
.card .ttl{font-weight:600;margin-bottom:6px;padding-right:56px}
.card .id{position:absolute;top:8px;right:9px;font:11px ui-monospace,monospace;color:var(--dim);
  opacity:.75}
.chips{display:flex;flex-wrap:wrap;gap:5px;margin-bottom:6px}
.chip.pill{font-size:11px;padding:1px 7px;border-radius:999px;background:#2b323c;
  border:1px solid var(--line);color:var(--dim);white-space:nowrap}
.await{background:#3a2f1d;border-color:#5c4a24;color:var(--warn)}
.needs{font-size:12.5px;color:var(--warn);margin:4px 0 2px}
.needs b{color:var(--warn)}
.notes{font-size:12.5px;color:var(--dim);margin-top:4px}
.refs{font:11px ui-monospace,monospace;color:var(--dim);margin-top:6px;opacity:.85;
  word-break:break-all}
.copy{cursor:pointer;background:none;border:1px solid var(--line);border-radius:6px;
  color:var(--dim);font:11px inherit;padding:2px 7px;margin-top:7px}
.copy:hover{color:var(--fg);border-color:var(--accent)}
.age{font-size:11px;color:var(--dim);opacity:.7}
.stale-card .age{color:var(--bad);opacity:1}
.focusrow{display:flex;flex-wrap:wrap;gap:22px;align-items:flex-start}
.focusrow div{font-size:13px}
.focusrow span.k{color:var(--dim);text-transform:uppercase;font-size:11px;
  letter-spacing:.08em;display:block}
table{border-collapse:collapse;font-size:13px;width:100%;max-width:900px}
th,td{text-align:left;padding:5px 9px;border-bottom:1px solid var(--line)}
th{color:var(--dim);font-size:11px;text-transform:uppercase;letter-spacing:.07em}
.bar{font:12px ui-monospace,monospace;color:var(--accent);white-space:nowrap}
.log{font-size:12.5px;color:var(--dim);max-width:900px}
.log li{margin:3px 0}
.log b{color:var(--fg)}
footer{margin-top:34px;color:var(--dim);font-size:11.5px}
"""


_HTML_JS_1 = r"""
const DATA = JSON.parse(document.getElementById('progress-data').textContent);
const SIG = document.getElementById('progress-data').dataset.sig;
let DOC = DATA;
const STATUSES = ['backlog', 'next', 'doing', 'review', 'done'];

const $ = (id) => document.getElementById(id);
const esc = (s) => String(s == null ? '' : s).replace(/[&<>"]/g,
  (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

/* Mirrors progress.loose_signature() exactly: sort by id with code-point
   comparison, then join id:status:updated.  If the files this page was built
   from have moved on, we say so instead of showing a stale board. */
function looseSig(d) {
  const rows = (d.tasks || []).map((t) => [t.id || '', t.status || '', t.updated || '']);
  rows.sort((a, b) => (a[0] < b[0] ? -1 : (a[0] > b[0] ? 1 : 0)));
  const meta = d.meta || {};
  return (meta.updated || '') + '|' + rows.length + '|' + rows.map((r) => r.join(':')).join(',');
}

function daysSince(iso) {
  const t = Date.parse(iso || '');
  if (isNaN(t)) return null;
  return Math.floor((Date.now() - t) / 86400000);
}

const personName = (key) => ((DOC.people || {})[key] || {}).name || key;
const personColor = (key) => ((DOC.people || {})[key] || {}).color || '#96a0ae';
const taskById = (id) => (DOC.tasks || []).find((t) => t.id === id);

/* Prefs are cosmetic only - the JSON stays the source of truth - so keeping
   them in localStorage is safe and makes the page open where you left it. */
const PREF_KEY = 'pd-progress-prefs';
let prefs = { who: 'all', area: 'all' };
try { Object.assign(prefs, JSON.parse(localStorage.getItem(PREF_KEY) || '{}')); } catch (e) {}
function savePrefs() { try { localStorage.setItem(PREF_KEY, JSON.stringify(prefs)); } catch (e) {} }

function visible(t) {
  if (prefs.who !== 'all') {
    const owned = t.owner === prefs.who || t.owner === 'both';
    if (!owned && t.awaiting !== prefs.who) return false;
  }
  if (prefs.area !== 'all' && t.area !== prefs.area) return false;
  return true;
}

const prio = (t) => t.prio || 9;
const byBoardOrder = (a, b) =>
  (prio(a) - prio(b)) || String(a.phase).localeCompare(String(b.phase)) || a.id.localeCompare(b.id);

function card(t, mode) {
  const chips = [`<span class="chip pill" style="color:${esc(personColor(t.owner === 'both' ? (DOC.meta.viewer || '') : t.owner))}">${esc(t.owner === 'both' ? 'both' : personName(t.owner))}</span>`];
  if (t.area) chips.push(`<span class="chip pill">${esc(t.area)}</span>`);
  if (t.size) chips.push(`<span class="chip pill">${esc(t.size)}</span>`);
  if (t.phase) chips.push(`<span class="chip pill">ph&nbsp;${esc(t.phase)}</span>`);
  chips.push(`<span class="chip pill">P${esc(t.prio)}</span>`);
  if (t.awaiting && t.awaiting !== 'none') {
    chips.push(`<span class="chip pill await">waiting on ${esc(personName(t.awaiting))}</span>`);
  }
  const age = daysSince(t.updated);
  const stale = age !== null && age > 14 && t.status !== 'done';
  const refs = (t.refs && t.refs.length)
    ? `<div class="refs">${t.refs.map(esc).join(' · ')}</div>` : '';
  const needs = t.needs ? `<div class="needs">&rarr; ${esc(t.needs)}</div>` : '';
  const notes = t.notes ? `<div class="notes">${esc(t.notes)}</div>` : '';
  const when = mode === 'done'
    ? `done ${esc(t.done || '')}`
    : `updated ${esc(t.updated || '')}${age !== null ? ' · ' + age + 'd' : ''}`;
  return `<article class="card prio${esc(t.prio)}${stale ? ' stale-card' : ''}" data-id="${esc(t.id)}">
    <div class="id">${esc(t.id)}</div>
    <div class="ttl">${esc(t.title)}</div>
    <div class="chips">${chips.join('')}</div>
    ${needs}${notes}${refs}
    <div class="age">${when}</div>
    <button class="copy" data-copy="${esc(t.id)}">copy JSON</button>
  </article>`;
}

function filterChips() {
  const out = [];
  const who = [['all', 'Everyone']].concat(Object.keys(DOC.people || {}).map((k) => [k, personName(k)]));
  out.push('<span class="sub" style="align-self:center;margin-right:2px">who</span>');
  who.forEach(([key, label]) => out.push(
    `<button class="chip${prefs.who === key ? ' on' : ''}" data-who="${esc(key)}">${esc(label)}</button>`));
  const areas = ['all'].concat([...new Set((DOC.tasks || []).map((t) => t.area))].sort());
  out.push('<span class="sub" style="align-self:center;margin:0 2px 0 12px">area</span>');
  areas.forEach((key) => out.push(
    `<button class="chip${prefs.area === key ? ' on' : ''}" data-area="${esc(key)}">${key === 'all' ? 'All areas' : esc(key)}</button>`));
  return out.join('');
}
"""


_HTML_JS_2 = r"""
function copyText(text) {
  if (navigator.clipboard && window.isSecureContext) return navigator.clipboard.writeText(text);
  const ta = document.createElement('textarea');
  ta.value = text;
  document.body.appendChild(ta);
  ta.select();
  try { document.execCommand('copy'); } catch (e) {}
  document.body.removeChild(ta);
  return Promise.resolve();
}

function render() {
  const meta = DOC.meta || {};
  const viewer = meta.viewer || Object.keys(DOC.people || {})[0];
  const all = DOC.tasks || [];
  const title = (meta.project || 'Progress') + ' — progress';
  document.title = title;
  $('title').textContent = title;

  const counts = {};
  STATUSES.forEach((s) => { counts[s] = all.filter((t) => t.status === s).length; });
  $('sub').textContent = 'Updated ' + (meta.updated || '?') + ' · ' + all.length + ' cards · '
    + STATUSES.filter((s) => counts[s]).map((s) => counts[s] + ' ' + s).join(' · ');
  $('filters').innerHTML = filterChips();

  /* ---- the strip: who has the ball ---------------------------------- */
  const open = all.filter((t) => t.status !== 'done');
  let strip = '';
  Object.keys(DOC.people || {}).forEach((key) => {
    const waiting = open.filter((t) => t.awaiting === key).sort(byBoardOrder).filter(visible);
    if (!waiting.length) return;
    const you = key === viewer;
    strip += '<h2>' + (you ? '⚠ ' : '') + 'Waiting on ' + (you ? 'you (' : '')
      + esc(personName(key)) + (you ? ')' : '') + ' — ' + waiting.length + '</h2>'
      + '<div class="strip' + (you ? '' : ' secondary') + '">'
      + waiting.map((t) => card(t)).join('') + '</div>';
  });
  $('waiting').innerHTML = strip
    || '<h2>Nothing is waiting on anyone</h2><div class="sub">Every open card has a free ball.</div>';

  /* ---- right now ---------------------------------------------------- */
  const focus = DOC.focus || {};
  const listOf = (ids) => (ids || []).map((id) => '<code>' + esc(id) + '</code>').join(', ') || '—';
  $('focusrow').innerHTML =
    (focus.note ? '<div style="flex:1 1 100%">' + esc(focus.note) + '</div>' : '')
    + '<div><span class="k">Now</span>' + listOf(focus.now) + '</div>'
    + '<div><span class="k">Next</span>' + listOf(focus.next) + '</div>';

  /* ---- the board ---------------------------------------------------- */
  const board = STATUSES.filter((s) => s !== 'done').map((status) => {
    let group = all.filter((t) => t.status === status && visible(t)).sort(byBoardOrder);
    return '<section class="col ' + status + '"><h3><span>' + status + '</span><span>'
      + group.length + '</span></h3>'
      + group.map((t) => card(t)).join('') + '</section>';
  }).join('');
  const done = all.filter((t) => t.status === 'done' && visible(t))
    .sort((a, b) => String(b.done || '').localeCompare(String(a.done || ''))).slice(0, 8);
  $('board').innerHTML = board
    + '<section class="col done"><h3><span>done — newest ' + done.length + ' of ' + counts.done
    + '</span></h3>' + done.map((t) => card(t, 'done')).join('') + '</section>';

  /* ---- phases and the log ------------------------------------------- */
  const phases = [...new Set(all.map((t) => String(t.phase)))].sort();
  const bar = (d, n) => {
    const filled = n ? Math.round(10 * d / n) : 0;
    return '▓'.repeat(filled) + '░'.repeat(10 - filled) + ' ' + (n ? Math.round(100 * d / n) : 0) + '%';
  };
  $('phases').innerHTML = '<table><tr><th>phase</th><th>done</th><th>total</th><th></th></tr>'
    + phases.map((p) => {
        const group = all.filter((t) => String(t.phase) === p);
        const d = group.filter((t) => t.status === 'done').length;
        return '<tr><td>' + esc(p) + '</td><td>' + d + '</td><td>' + group.length
          + '</td><td class="bar">' + bar(d, group.length) + '</td></tr>';
      }).join('') + '</table>';

  $('log').innerHTML = (DOC.log || []).slice(-15).reverse().map((e) =>
    '<li><b>' + esc(e.date) + '</b> ' + esc(personName(e.who)) + ' — ' + esc(e.what)
    + (e.task ? ' <code>' + esc(e.task) + '</code>' : '') + '</li>').join('');

  $('footer').textContent = 'Source of truth: progress.json (sha ' + SIG + '). '
    + (meta.how_to || '');
}

document.addEventListener('click', (ev) => {
  const who = ev.target.closest('[data-who]');
  if (who) { prefs.who = who.dataset.who; savePrefs(); render(); return; }
  const area = ev.target.closest('[data-area]');
  if (area) { prefs.area = area.dataset.area; savePrefs(); render(); return; }
  const copy = ev.target.closest('[data-copy]');
  if (copy) {
    const t = taskById(copy.dataset.copy);
    copyText(JSON.stringify(t, null, 2)).then(
      () => { copy.textContent = 'copied!'; setTimeout(() => { copy.textContent = 'copy JSON'; }, 1400); },
      () => { copy.textContent = 'clipboard blocked'; });
  }
});

render();

/* Opened from the file system?  fetch() rejects and we keep the embedded
   snapshot.  Served?  Re-read the JSON and shout if this page is behind it. */
fetch('progress.json', { cache: 'no-store' })
  .then((r) => (r.ok ? r.json() : null))
  .then((d) => {
    if (!d || looseSig(d) === SIG) return;
    DOC = d;
    const el = $('stale');
    el.hidden = false;
    el.textContent = 'This page was built from an older progress.json. '
      + 'Run  PYTHONPATH=python_tools python3 -m gm progress build  — '
      + 'showing the newer file below.';
    render();
  })
  .catch(() => {});
"""


_HTML_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>__TITLE__ — progress</title>
<meta name="progress-sha" content="__SHA__">
<meta name="generator" content="python -m gm progress build">
<style>__CSS__</style>
</head>
<body>
<header>
  <h1 id="title"></h1>
  <div class="sub" id="sub"></div>
  <div class="filters" id="filters"></div>
</header>
<div class="stale" id="stale" hidden></div>
<section id="waiting"></section>
<h2>Right now</h2>
<section class="focusrow" id="focusrow"></section>
<h2>Board</h2>
<section class="board" id="board"></section>
<h2>Progress by phase</h2>
<section id="phases"></section>
<h2>Log</h2>
<ul class="log" id="log"></ul>
<footer id="footer"></footer>
<script type="application/json" id="progress-data" data-sig="__SIG__">__DATA__</script>
<script>__JS__</script>
</body>
</html>
"""


def build_html(doc: Dict[str, Any]) -> str:
    """The board as ONE self-contained file.

    No server, no CDN, no build step - open it and it works.  The JSON is
    embedded so it renders offline, and the page re-fetches ``progress.json``
    when it is served, so it can tell you it is behind the file instead of
    quietly showing yesterday's board (see ``loose_signature``).
    """
    data = dumps(doc)
    # a literal "</script>" inside a string would end the data block early;
    # "<" cannot appear outside a JSON string, so this is safe
    data = data.replace("<", "\\u003c")
    meta = doc.get("meta", {})
    sig = (
        loose_signature(doc)
        .replace("&", "&amp;")
        .replace('"', "&quot;")
        .replace("<", "&lt;")
    )
    page = _HTML_PAGE
    for marker, value in (
        ("__TITLE__", str(meta.get("project", "Progress"))),
        ("__SHA__", fingerprint(doc)),
        ("__SIG__", sig),
        ("__DATA__", data),
        ("__CSS__", _HTML_CSS),
        ("__JS__", _HTML_JS_1 + _HTML_JS_2),
    ):
        page = page.replace(marker, value)
    return page


# -- commands ---------------------------------------------------------------
def _root(args: Any) -> Path:
    """The repo root: honour -p/--project, otherwise two levels up from here."""
    given = getattr(args, "project", None)
    if given:
        return Path(given)
    return Path(__file__).resolve().parents[2]


def check(root: Path) -> int:
    """Validate the JSON, then prove the generated views came from it."""
    doc = load(root / JSON_NAME)
    errs = validate(doc, root)
    for err in errs:
        print("ERROR   " + err)
    problems = len(errs)

    sha = fingerprint(doc)
    for name in (MD_NAME, HTML_NAME):
        path = root / name
        if not path.exists():
            print("MISSING %s - run: gm progress build" % name)
            problems += 1
        elif sha not in path.read_text(encoding="utf-8"):
            print("STALE   %s was not built from this %s - run: gm progress build"
                  % (name, JSON_NAME))
            problems += 1
        else:
            print("ok      %s in sync with %s" % (name, JSON_NAME))

    print(summary(doc))
    if problems:
        print("%d problem(s)" % problems)
        return 1
    print("progress.json, %s and %s agree" % (MD_NAME, HTML_NAME))
    return 0


def build(root: Path) -> int:
    """Write both views.  Refuses to write them from a broken document."""
    doc = load(root / JSON_NAME)
    errs = validate(doc, root)
    for err in errs:
        print("ERROR   " + err)
    if errs:
        print("not building: %d problem(s) in %s" % (len(errs), JSON_NAME))
        return 1

    (root / MD_NAME).write_text(build_md(doc), encoding="utf-8")
    (root / HTML_NAME).write_text(build_html(doc), encoding="utf-8")
    print("wrote %s and %s from %s (sha %s)"
          % (MD_NAME, HTML_NAME, JSON_NAME, fingerprint(doc)))
    print(summary(doc))
    return 0


def _coerce(key: str, raw: str) -> Any:
    if key == "prio":
        try:
            return int(raw)
        except ValueError:
            raise SystemExit("prio must be a number, got %r" % raw)
    if key == "refs":
        return [p.strip() for p in raw.split(",") if p.strip()]
    if raw in ("", "null", "none", "None"):
        return None
    return raw


def _apply(task: Dict[str, Any], changes: Dict[str, Any], today: str) -> None:
    """Write the changes, then let the small done/awaiting state machine settle."""
    for key, value in changes.items():
        task[key] = value
    task["updated"] = today
    if task.get("status") == "done":
        task["done"] = task.get("done") or today
        task["awaiting"] = "none"
    else:
        task["done"] = None


def _edit(root: Path, action: str, rest: Sequence[str]) -> int:
    if not rest:
        raise SystemExit("gm progress %s needs a task id (then key=value pairs)" % action)
    task_id = rest[0]
    changes: Dict[str, Any] = {}
    for pair in rest[1:]:
        if "=" not in pair:
            raise SystemExit("expected key=value, got %r" % pair)
        key, _, raw = pair.partition("=")
        key = key.strip()
        if key not in TASK_KEYS:
            raise SystemExit("unknown field %r (valid: %s)" % (key, ", ".join(TASK_KEYS)))
        changes[key] = _coerce(key, raw.strip())

    path = root / JSON_NAME
    doc = load(path)
    today = _today()

    if action == "add":
        if task_id in by_id(doc):
            raise SystemExit("a card %r already exists" % task_id)
        card: Dict[str, Any] = {
            "id": task_id, "title": "", "status": "backlog", "owner": "cline",
            "awaiting": "none", "area": "code", "phase": "2", "size": "M", "prio": 2,
            "needs": "", "notes": "", "refs": [], "created": today, "updated": today,
            "done": None,
        }
        card.update(changes)
        if not card.get("title"):
            raise SystemExit("add needs title=... so the card means something")
        if card.get("status") != "done":
            card["done"] = None
        doc.setdefault("tasks", []).append(card)
    else:
        target = by_id(doc).get(task_id)
        if target is None:
            raise SystemExit("no card %r (is that the id?)" % task_id)
        _apply(target, changes, today)

    doc.setdefault("meta", {})["updated"] = today

    errs = validate(doc, root)
    if errs:
        for err in errs:
            print("ERROR   " + err)
        print("nothing written - fix the values above and try again")
        return 1

    save(path, doc)
    print("%s %s" % ("added" if action == "add" else "updated", task_id))
    return build(root)


def cmd_progress(args: Any) -> int:
    root = _root(args)
    action = getattr(args, "action", None) or "check"

    if action == "check":
        return check(root)
    if action == "build":
        return build(root)
    if action == "list":
        doc = load(root / JSON_NAME)
        print(summary(doc))
        print()
        for line in board_lines(doc, owner=args.owner, awaiting=args.awaiting,
                                include_done=args.done):
            print(line)
        return 0
    if action in ("set", "add"):
        return _edit(root, action, getattr(args, "rest", []) or [])
    raise SystemExit("unknown action %r (check / build / list / set / add)" % action)





