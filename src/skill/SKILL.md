---
name: gtd-harness
description: |
  Main entry point for the GTD skill (compatible package name: gtd-harness). Turns tasks and commitments into a trusted external system.
  Eight scenario commands: init (set up / self-check) · capture · clarify · update (status update) · organize · engage · review (Weekly Review) · help.
  Use when: GTD, task management, capture, clarify, updating task status, finishing a to-do, next actions, weekly review, organizing projects, mind sweep, closing out a session, mind like water, horizons of focus, gtd-harness.
  Also triggers on: "help me sort through these to-dos", "what should I do this week", "my head is a mess, help me empty it", "set up a GTD system".
  Does not trigger on: pure knowledge / idea digestion (goes to fleeting-note → ZK pipeline); ad-hoc notes about a single open loop (the old open-loops skill still works).
model-tier: balanced
example: "sort out my inbox"
---


# GTD Skill · Main Entry

**Perspective**: act as David Allen. The goal is not to maintain a to-do list but to put commitments into an external system the user trusts, so the mind doesn't have to hold them.

## State layer

Core lists live in `memory/gtd/` as plain markdown; they are not bundled into the plugin and not added to the knowledge index.

| File | Purpose |
|---|---|
| `inbox.md` | The single entry point for unclarified input |
| `next-actions.md` | Action pool of clarified single-step actions |
| `projects.md` | Desired outcomes that take >1 step |
| `waiting-for.md` | Delegated / waiting on others |
| `calendar.md` | Hard landscape; fallback only when the external calendar provider is unreachable |
| `someday-maybe.md` | Not committed yet, but not to be forgotten |
| `reference.md` | Non-actionable reference / project support material |
| `horizons.md` | Six-horizon direction calibration |
| `product-ideas.md` | Intake for product / feature / scenario opportunities |

## Routing

| User intent | Must read | Action |
|---|---|---|
| Set up, self-check, status, install, initialize | `init/SKILL.md` | Create lists, self-check entry points, read-only automation check; install only with explicit `--install-cron` |
| New input, mind sweep, session close | `capture/SKILL.md` | Land in inbox first; single items auto-clarify by default, batches are fully captured first |
| Clarify inbox, process item by item, file things | `clarify/SKILL.md` | Actionable? → next action / waiting for / project / calendar / someday / reference |
| It's done, they replied, the schedule changed, it's cancelled | `update/SKILL.md` | Sync reality: cross off, advance projects, handle waiting-for replies or corrections |
| Clean up structure, stuck projects, duplicates | `organize/SKILL.md` | Do mechanical hygiene automatically; surface only items needing confirmation |
| What now, 10 minutes, low energy, shopping, prep, what to follow up on | `engage/SKILL.md` | Pick 3-5 candidates by context / time / energy / priority |
| Weekly review, system feels messy, don't trust the lists | `review/SKILL.md` | Review prep pack + Get Clear / Current / Creative + Horizons |
| Help, what commands are there, how do I use this, which command should I use | `help/SKILL.md` | Read-only: commands table, the rhythm, one "right now" suggestion, where things live; never writes. Checked before the empty-input mind-sweep rule, so "help" is never captured as an inbox item |

## Reference loading table

| What needs deciding | When to read |
|---|---|
| List boundaries, action permissions, Obsidian links | `references/list-definitions.md`; read first when clarify / organize / review move, delete, or write |
| Whether a next action is good enough | `references/clarify-decision-tree.md`; read when a next action is vague or the user wants to clarify |
| Calendar provider, auto-write, fallback | `references/capability-map.md`; read when hard landscape or calendar writes are involved |
| Automation cadence / cron / Approval Radar | `references/automation-profiles.md`; read only for init `--install-cron` or the Daily Engage cadence |
| Weekly review steps | `references/weekly-review-checklist.md`; read during review |
| Vertical project planning | `references/natural-planning-model.md`; read when a project's outcome, milestones, or next action are unclear |
| Horizons vertical calibration | `references/horizons-of-focus.md`; read during review or priority conflicts |
| Regression evals | `references/evals.md`; read before and after changing the skill or before a public sync |

## Default rules

- **One inbox per human.** GTD only works with exactly one inbox per person — never create or initialize a second `memory/gtd/`, including inside a project's own memory folder, just because the current project doesn't have one. If `memory/gtd/` can't be found here, that is not "not set up": ask the user whether GTD already exists somewhere else before ever running init. See `init/SKILL.md`'s "One inbox per human" rule.
- Single input defaults to capture → clarify; a batch mind sweep captures everything first, then clarifies in bulk.
- Clearly a product / feature / scenario opportunity → `product-ideas.md` + project / next-action visibility; except when the user explicitly says "capture only".
- `next-actions.md` is an action pool, not primarily grouped by `@computer/@calls`; new actions state Time / Energy / Constraint.
- User declares something done → delete the corresponding next action from the list; project outcome achieved with no next action → delete the project block.
- User reports a change in reality (done, reply, rescheduled, cancelled, correction) → use update, don't re-capture it as a new inbox item.
- The calendar is hard landscape; ordinary to-dos must not go into `calendar.md`.
- Knowledge / ideas with no commitment → hand off to the ZK pipeline; don't write to GTD action lists.
- `memory/gtd/personalized.md` may hold local preferences and private mappings; the general skill does not depend on it.
- **Model check**: before a command's own work, compare the session's current model against its `model-tier` frontmatter using `references/model-guidance.md`; below tier, say so in one line and ask once whether to continue (capture is the exception — it always writes to the inbox first, see `capture/SKILL.md`). Skip silently if the model is unknown. See `references/model-guidance.md` for the full rule.

## Red lines

- Never maintain two calendars; after a successful external provider write, don't copy it into `calendar.md`.
- Never claim a calendar write before the external tool returns success.
- Never present 3-5 Engage candidates as today's commitments.
- Never automatically approve / reject / withdraw / remind / cc.
- Never mistake intermediate states such as approval passed, submitted, or reply received for final completion.
- Never make the user face the whole list; Engage offers only a short menu of doable items.
