---
name: gtd-organize
description: GTD skill scenario command · Organize (structural hygiene). The AI automatically runs mechanical bookkeeping (orphans / stalled / constraint lenses / stale checkmarks) and surfaces only what needs the user's decision. Runs automatically before engage/review. GTD step 3.
parent: gtd-harness
model-tier: balanced
example: "Clean up my GTD lists"
---


# GTD · organize (structural hygiene)

**Perspective**: David Allen, AI-native. Clarify already files each item on the spot; organize only repairs structural drift and does not reinvent the categories.

## When to run

- Automatically before engage, so stalled projects don't slip through.
- Automatically during review's Get Current stage.
- After the external calendar provider comes back from unreachable to reachable, to reconcile `calendar.md` fallback items.
- When a tickle has come due (per-item layout; `gtd_status.sh` says "tickle(s) now actionable").
- Monthly re-evaluation of someday / product ideas.
- When the user asks for `/gtd-organize` directly, or for cleaning up structure, stuck projects, duplicates, or re-filing contexts / constraints.

## Loading and boundaries

- Read `references/list-definitions.md` first: it is the single source of truth for list boundaries, action permissions, and Obsidian link rules.
- For external calendar reads / writes, also read `references/capability-map.md`.
- Automation boundary: mechanical hygiene may be automatic; commitment decisions, high-consequence external actions, sending messages, and approval actions may not.

## Automatic vs needs confirmation

| Category | Can do automatically | Needs user confirmation |
|---|---|---|
| Orphans | Detect next-action / project broken links; add the block link when there's a unique match | Several possible owners or unclear result |
| Completed projects | Outcome clearly achieved and no next action or tickle still links it → close it through `update/SKILL.md`'s "Project close" (AAR draft, one confirmation, done record) | Unsure whether the outcome is achieved; whether to cut the project; a tickle still links it |
| Stalled projects | Draft one concrete next action and attach it to the project. Stalled = no open next action, waiting-for or tickle links it (`references/list-definitions.md` "Stalled projects"); a project on hold (a tickle links it) is never given a drafted next action | Can't draft one; the commitment needs to change |
| Tickler (per-item) | A due tickle linked to a project whose body is a concrete action → move the note to `next-actions/` (drop `tickle`, fill time / energy / context, keep `project:`). Any other due tickle (standalone, or too vague to be an action) → one inbox pointer, `- Tickle due: <title> → [[tickler/<title>]] · Captured: YYYYMMDD`, the note left in place for clarify; never a second pointer while one exists | A tickle's project is closed or missing; its date is malformed; its date conflicts with the calendar (flag + suggested date, never re-date) |
| Constraint / lens hygiene | Fill clearly missing Time / Energy / Constraint; treat legacy @ groups as compatibility signals | Needs the user to judge setting or priority |
| Stale checkmarks / duplicates | Clean up completed leftovers and obvious duplicates | Looks duplicated but means something different |
| Calendar fallback | Delete fallback items confirmed in the external calendar; move ordinary to-dos back to next-actions | External calendar unreachable, expired with unclear status, conflict / possible duplicate |
| Someday / product ideas | Flag ripe candidates; draft a next action for product ideas missing visibility | Whether to activate / delete / downgrade |

## Workflow

1. Scan the `memory/gtd/` core lists and `product-ideas.md`. **Per-item layout**: run `scripts/gtd_check.sh` for the mechanical findings and `scripts/gtd_list.sh <list>` for the contents; open individual notes only to fix them (see "Per-item layout" below).
2. Use `list-definitions.md` to check whether each item is in the right list; move mechanical misfilings directly and collect unclear ones.
3. Ask projects three questions: Is the outcome achieved? Is there a valid next-actions / waiting-for / tickle link (per-item: `gtd_check.sh`'s `stalled` already applies this)? Can multiple next actions really run in parallel? A project on hold (a tickle links it) is in play: never draft a next action for it or call it stalled.
4. Fill light fields on next-actions: Time / Energy / Constraint; keep legacy `@computer/@calls` only as tool-constraint signals.
5. **Tickler** (per-item): handle due tickles from `gtd_list.sh tickler --due` / `gtd_check.sh` `tickler-due` as in the table above, skipping any "queued in inbox"; then check tickles due in the next 30 days (`gtd_list.sh tickler --within 30`) against the hard landscape for a blocked day (`references/capability-map.md` "Tickle date conflicts") and surface each conflict with a suggested date.
6. Reconcile `calendar.md` fallback items against external calendar provider reachability; delete the local copy once successfully externalized, otherwise keep it and surface it. This covers `calendar.md` only: the tickler is never reconciled, exported or deleted here.
7. Do the monthly re-evaluation of someday / product ideas; draft candidates for product ideas missing project / next-action visibility.
8. Output a one-line summary of what was handled automatically + one batch of questions needing confirmation; don't interrupt item by item. Name each tickler result, e.g. "Tickler: 2 now actionable → 1 next action for <Project>, 1 queued in the inbox; 1 date conflict to confirm".

## Per-item layout

`gtd_check.sh` finds; organize fixes. Before changing notes in a list, read that list's `README.md`. Each finding maps to a row of the table above:

| Finding | Automatic | Surface for confirmation |
|---|---|---|
| `link-form` | (action, waiting-for or tickle) Rewrite `project:` to `"[[projects/<Name>/README\|<Name>]]"` | — |
| `orphan` | Re-link when exactly one project folder is a clear match (renamed / typo) | No match or several; whether it's now standalone (then drop `project:`) |
| `orphan-closed` | — | The project is already in `_done/`: finish this action, drop it, or re-link it to a live project (a tickle: drop it, or re-link it) |
| `stalled` | Draft one next-action note linked to the project (act-then-surface) | Can't draft one; the outcome may be achieved (closing it is `update/SKILL.md`'s job) |
| `field` | Fill or correct a value the body makes clear, using list-definitions' "Property values" | Genuinely unclear — leave it empty; a note with no properties is still valid |
| `duplicate` | Merge obvious duplicates into one note; delete the other | Same title, different commitments — rename one instead |
| `filename` | Rename to a safe title and update links to it | — |
| `tickler-due` | Due tickle: move a concrete project tickle to `next-actions/`, otherwise add one inbox pointer ("Tickler" row above). "queued in inbox" → nothing to do, clarify has it | Project closed or missing |
| `tickler-date` | Fill `tickle` when the body states the date clearly | Otherwise surface: when does it become actionable? |
| `done-completed` | Add `completed:` with today's date | — |
| `done-no-aar` | — | List once for the next Weekly Review: draft the AAR, or write `Skipped (YYYY-MM-DD).` under the heading so it isn't listed again |
| `done-link` | Rewrite `project:` to `"[[_done/<Name>/README\|<Name>]]"` | — |

Never move a note into `_done/` from organize (that's `update/SKILL.md`), and never count `_done/` notes as open work. The single-file checks above still apply to `inbox.md` and `calendar.md`, which stay files in both layouts.

## Quality check

- [ ] Read `references/list-definitions.md` first and did not duplicate another set of list definitions in this file
- [ ] Mechanical issues (orphans, missing light fields, stale checkmarks, obvious duplicates) fixed automatically and summarized
- [ ] Completed projects closed through update's Project close (AAR + done record); unfinished projects have a valid next-action / waiting-for block link or are listed for confirmation
- [ ] `calendar.md` reconciled: synced items removed, ordinary to-dos re-filed, unconfirmed hard appointments kept and surfaced
- [ ] Tickler (per-item): due tickles moved to `next-actions/` or queued in the inbox once; no project with a tickle given a drafted next action or called stalled; no tickle exported or touched by the calendar reconcile; date conflicts surfaced, never re-dated
- [ ] Per-item layout: every `gtd_check.sh` finding either fixed or in the confirmation batch; `README.md` never treated as an item
- [ ] Judgment calls asked in a batch; no commitment decisions made for the user
- [ ] No high-consequence actions taken such as sending messages, automatic approvals, or unconfirmed external writes
