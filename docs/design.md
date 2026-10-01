# Design — gtd-harness

> David Allen (GTD) × Andrej Karpathy ("Agent = LLM + harness").

## The thesis

You don't build the brain (the LLM ships with each platform). You build the **harness**: the
trusted external system that lets the mind stop *storing* and go back to *thinking*. GTD is exactly
such a system; this repo implements it as a portable, AI-native harness.

## Four layers

### Layer 0 — State (the trusted system)
`memory/gtd/` holds eight plain-markdown lists. Plain files = **zero adaptation** across platforms;
a file is a file. Lists are physically separated (Allen's rule) so each stays single-purpose:

| path | list | note |
|---|---|---|
| `inbox.md` | Inbox | capture sink, zero judgment |
| `next-actions/` | Next Actions | **an action pool with lightweight context signals** (time / energy / real constraint lenses) |
| `projects/` | Projects | one folder per outcome (>1 step): README + support material; a current next action links to it |
| `waiting-for/` | Waiting For | delegated/pending, with person + agreement |
| `someday-maybe/` | Someday/Maybe | incubating; monthly re-eval |
| `calendar.md` | Calendar | hard landscape only; an available calendar provider wins when connected |
| `reference/` | Reference | non-actionable knowledge, at the workspace root |
| `horizons.md` | Horizons | the six Horizons of Focus (purpose → runway) |

Every list that holds items is a folder of one-commitment-per-note files with their fields as YAML
frontmatter (a project is itself a folder, holding its README and its support material), plus a
`_done/` record folder for finished work with its outcome — nothing is deleted outright, so an
after-action review has raw material to draw on. `reference/` sits at the workspace root, outside
`memory/gtd/`: general knowledge that GTD files into but that isn't GTD state. `inbox.md`,
`calendar.md`, `horizons.md`, and `personalized.md` are single files. There is also a `tickler/`
folder (Allen's tickler): committed work that can't be acted on until a date, one note per tickle; a
project linked from a tickle is on hold, not stalled, and on the date organize turns the tickle into
a next action or queues it in the inbox. It is always local, never on the external calendar.
`gtd_init.sh --confirm-create` sets it all up. A read-only script, `gtd_list.sh`, gives the rest of
the harness one compact line per item, so nothing else has to open every note; its sibling
`gtd_check.sh` reports organize's mechanical findings (orphans, stalled projects, bad properties,
duplicates, unsafe filenames, tickler dates, `_done/` gaps) without fixing anything. LLM-GTD 1.x also
had a single-file layout (one `.md` per list); 2.0.0 dropped it, and every script refuses a
`memory/gtd/` that still holds those files rather than half-read it. Full folder structure, note
formats, and the done/AAR record are in `references/list-definitions.md`.


### Layer 1 — Logic (the workflow)
`skill/SKILL.md` (navigation) + eight sub-command `SKILL.md` files. Written in **intent language**
("read the list", "append a line") — **no platform tool names**. That neutrality is what lets one
source feed three platforms.

### Layer 2 — Adapter (three thin front-ends + one contract)
- Claude Code: `.claude/commands/gtd*.md` thin commands + Skill tool.
- Cursor: `.cursor/skill-rules.json` keyword hook → reads `SKILL.md`.
- Codex: `~/.codex/prompts/gtd*.md` + `AGENTS.md` routing + `gtd-orchestrator` agent.
- `references/capability-map.md` is the written contract: **intent verb → per-platform tool**
  (read/append/scan/run-script/read-calendar/write-calendar), with graceful degradation.

### Layer 3 — Cadence (the Reflect heartbeat)
Weekly review is GTD's critical success factor. Shipped as a command + documented rhythm;
a scheduled reminder is optional and off by default (a reminder can prep; it cannot reflect for you).

## Two seams worth knowing

**Allen × Luhmann (capture vs. knowledge).** Capture is shared; Clarify is the fork. Actions →
GTD lists; ideas/knowledge → your note system. Knowledge never pollutes the action lists.

**AI-native automation.** Capture→Clarify and the mechanical half of Organize run automatically
(act-then-surface; markdown is trivially reversible). The harness stops and asks only on genuine
forks: action-vs-knowledge, no derivable next action, an implied commitment, an unclear outcome,
or a calendar write. Engage and Review keep the human in the loop by design.

**Reality updates.** `update` is the bridge for "this already happened": completed next actions,
waiting-for replies, project progress, calendar corrections, cancellations, and factual edits.
It updates existing state and advances the project; it is not another inbox.

## Self-initialization

`init` is a first-class command: `gtd_init.sh` idempotently creates the eight lists, self-checks the
adapter wiring, and refuses to run over a 1.x single-file system rather than hide its items.
A harness that can't bootstrap itself isn't a harness.
