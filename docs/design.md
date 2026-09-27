# Design — gtd-harness

> David Allen (GTD) × Andrej Karpathy ("Agent = LLM + harness").

## The thesis

You don't build the brain (the LLM ships with each platform). You build the **harness**: the
trusted external system that lets the mind stop *storing* and go back to *thinking*. GTD is exactly
such a system; this repo implements it as a portable, AI-native harness.

## Four layers

### Layer 0 — State (the trusted system)
`memory/gtd/` holds eight plain-markdown lists. Plain files = **zero adaptation** across platforms;
a file is a file. Lists are physically separated (Allen's rule) so each stays single-purpose. Two
layouts hold the same lists and the same rules — only the storage shape differs:

| file | list | note |
|---|---|---|
| `inbox.md` | Inbox | capture sink, zero judgment |
| `next-actions.md` | Next Actions | **kept in an action pool with lightweight context signals** (time / energy / real constraint lenses, with legacy @context compatibility) |
| `projects.md` | Projects | outcome (>1 step) + a current next action; closed project blocks are deleted |
| `waiting-for.md` | Waiting For | delegated/pending, with person + agreement |
| `someday-maybe.md` | Someday/Maybe | incubating; monthly re-eval |
| `calendar.md` | Calendar | hard landscape only; an available calendar provider wins when connected |
| `reference.md` | Reference | non-actionable + project support material |
| `horizons.md` | Horizons | the six Horizons of Focus (purpose → runway) |

**Single-file (default)** is the table above: one list, one file. **Per-item (opt-in)** turns
`next-actions`, `waiting-for`, `projects`, `someday-maybe`, and `product-ideas` into folders of
one-commitment-per-note files with the same fields as YAML frontmatter (a project is itself a folder,
holding its README and its support material), plus a `_done/` record folder for finished work with
its outcome — nothing here is deleted outright anymore, so an after-action review has raw material to
draw on. `reference.md` becomes a `reference/` folder at the workspace root, outside `memory/gtd/`:
general knowledge that GTD files into but that isn't GTD state. `inbox.md`, `calendar.md`,
`horizons.md`, and `personalized.md` always stay single files. `gtd_init.sh --layout notes` sets it up. Layout is auto-detected from whether `next-actions/`
exists as a directory; a new read-only script, `gtd_list.sh`, gives the rest of the harness one
compact-line-per-item view regardless of which layout is live, so nothing else has to special-case
storage shape; its sibling `gtd_check.sh` reports organize's mechanical findings (orphans, stalled
projects, bad properties, duplicates, unsafe filenames, `_done/` gaps) without fixing anything. Full folder structure, note formats, and the done/AAR record are in
`references/list-definitions.md`.

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
adapter wiring, and (optionally, `--import-legacy`) imports from a pre-existing todo file read-only.
A harness that can't bootstrap itself isn't a harness.
