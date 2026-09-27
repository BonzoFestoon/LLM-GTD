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
| Completed projects | Outcome clearly achieved and no next action still needs pushing → delete the project block | Unsure whether the outcome is achieved; whether to cut the project |
| Stalled projects | Draft one concrete next action and attach it to the project | Can't draft one; the commitment needs to change |
| Constraint / lens hygiene | Fill clearly missing Time / Energy / Constraint; treat legacy @ groups as compatibility signals | Needs the user to judge setting or priority |
| Stale checkmarks / duplicates | Clean up completed leftovers and obvious duplicates | Looks duplicated but means something different |
| Calendar fallback | Delete fallback items confirmed in the external calendar; move ordinary to-dos back to next-actions | External calendar unreachable, expired with unclear status, conflict / possible duplicate |
| Someday / product ideas | Flag ripe candidates; draft a next action for product ideas missing visibility | Whether to activate / delete / downgrade |

## Workflow

1. Scan the `memory/gtd/` core lists and `product-ideas.md`. **Per-item layout**: run `scripts/gtd_check.sh` for the mechanical findings and `scripts/gtd_list.sh <list>` for the contents; open individual notes only to fix them (see "Per-item layout" below).
2. Use `list-definitions.md` to check whether each item is in the right list; move mechanical misfilings directly and collect unclear ones.
3. Ask projects three questions: Is the outcome achieved? Is there a valid next-actions / waiting-for block link? Can multiple next actions really run in parallel?
4. Fill light fields on next-actions: Time / Energy / Constraint; keep legacy `@computer/@calls` only as tool-constraint signals.
5. Reconcile `calendar.md` fallback items against external calendar provider reachability; delete the local copy once successfully externalized, otherwise keep it and surface it.
6. Do the monthly re-evaluation of someday / product ideas; draft candidates for product ideas missing project / next-action visibility.
7. Output a one-line summary of what was handled automatically + one batch of questions needing confirmation; don't interrupt item by item.

## Per-item layout

`gtd_check.sh` finds; organize fixes. Before changing notes in a list, read that list's `README.md`. Each finding maps to a row of the table above:

| Finding | Automatic | Surface for confirmation |
|---|---|---|
| `link-form` | Rewrite `project:` to `"[[projects/<Name>/README\|<Name>]]"` | — |
| `orphan` | Re-link when exactly one project folder is a clear match (renamed / typo) | No match or several; whether it's now standalone (then drop `project:`) |
| `orphan-closed` | — | The project is already in `_done/`: finish this action, drop it, or re-link it to a live project |
| `stalled` | Draft one next-action note linked to the project (act-then-surface) | Can't draft one; the outcome may be achieved (closing it is `update/SKILL.md`'s job) |
| `field` | Fill or correct a value the body makes clear, using list-definitions' "Property values" | Genuinely unclear — leave it empty; a note with no properties is still valid |
| `duplicate` | Merge obvious duplicates into one note; delete the other | Same title, different commitments — rename one instead |
| `filename` | Rename to a safe title and update links to it | — |
| `done-completed` | Add `completed:` with today's date | — |
| `done-no-aar` | — | List once for the next Weekly Review: draft the AAR, or write `Skipped (YYYY-MM-DD).` under the heading so it isn't listed again |

Never move a note into `_done/` from organize (that's `update/SKILL.md`), and never count `_done/` notes as open work. The single-file checks above still apply to `inbox.md` and `calendar.md`, which stay files in both layouts.

## Quality check

- [ ] Read `references/list-definitions.md` first and did not duplicate another set of list definitions in this file
- [ ] Mechanical issues (orphans, missing light fields, stale checkmarks, obvious duplicates) fixed automatically and summarized
- [ ] Completed projects deleted; unfinished projects have a valid next-action / waiting-for block link or are listed for confirmation
- [ ] `calendar.md` reconciled: synced items removed, ordinary to-dos re-filed, unconfirmed hard appointments kept and surfaced
- [ ] Per-item layout: every `gtd_check.sh` finding either fixed or in the confirmation batch; `README.md` never treated as an item
- [ ] Judgment calls asked in a batch; no commitment decisions made for the user
- [ ] No high-consequence actions taken such as sending messages, automatic approvals, or unconfirmed external writes
