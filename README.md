# Pushing Daisies

A tower-defence game with a garden that grows between runs. GameMaker Studio 2,
converted from GameMaker 8.

## Where to look first

| If you want... | Read |
| --- | --- |
| **what we are working on, and whose turn it is** | **[`PROGRESS.md`](./PROGRESS.md)** — or open [`progress.html`](./progress.html) for the board |
| the design | [`goal.md`](./goal.md) |
| the numbers | [`economy.md`](./economy.md) |
| the plan and its phases | [`roadmap.md`](./roadmap.md) |
| the bug post-mortems | [`lessons_learned.md`](./lessons_learned.md) |
| the working agreement (agents **and** humans) | [`AGENTS.md`](./AGENTS.md) |
| the tooling | [`python_tools/README.md`](./python_tools/README.md) |

## The tracker

[`progress.json`](./progress.json) is the **single source of truth** for what is
being done and whose turn it is. [`PROGRESS.md`](./PROGRESS.md) and
[`progress.html`](./progress.html) are **generated** from it — never edit them.

```bash
PYTHONPATH=python_tools python3 -m gm progress          # is everything consistent?
PYTHONPATH=python_tools python3 -m gm progress build    # regenerate the views
```

Open `progress.html` by double-clicking it: no server, no build step, works
offline. The strip at the top of the board is what is waiting on **you**; the
kanban columns underneath are where everything else is. Details in
[`AGENTS.md` §6](./AGENTS.md#6-the-progress-tracker).

## Opening the project

GameMaker Studio 2. The IDE **must be closed** while files are edited from
outside it — it rewrites `.yy`/`.yyp` from its own in-memory buffers when it
saves, silently discarding outside work ([`AGENTS.md` §1.1](./AGENTS.md#11-gamemaker-holds-the-files)).
