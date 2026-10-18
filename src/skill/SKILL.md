---
name: gtd-harness
description: |
  Main entry point for the GTD skill (compatible package name: gtd-harness). Turns tasks and commitments into a trusted external system.
  Eight scenario commands: init (set up / self-check) · capture · clarify · update (status update) · organize · engage · review (Weekly Review) · help.
  Use when: GTD, task management, capture, clarify, updating task status, finishing a to-do, next actions, weekly review, organizing projects, mind sweep, closing out a session, mind like water, horizons of focus, gtd-harness.
  Also triggers on: "help me sort through these to-dos", "what should I do this week", "my head is a mess, help me empty it", "set up a GTD system".
  Does not trigger on: pure knowledge / idea digestion (goes to reference/, not an action list); ad-hoc notes about a single open loop (the old open-loops skill still works).
model-tier: balanced
example: "sort out my inbox"
---


# GTD Skill · Main Entry

Read `shared-rules.md` first: the state layer, default rules, model check and red lines that every command follows. This file adds only what the router needs: which command handles an intent, and which reference to load for a decision.

## Routing

| User intent | Must read | Action |
|---|---|---|
| Set up, self-check, status, install, initialize | `init/SKILL.md` | Create lists, self-check entry points, read-only automation check; install only with explicit `--install-cron` |
| New input, mind sweep, session close | `capture/SKILL.md` | Write it to the inbox verbatim, nothing else; clarifying is a separate step (`/gtd-clarify`) |
| Clarify inbox, process item by item, file things | `clarify/SKILL.md` | Actionable? → next action / waiting for / project / calendar / someday / reference |
| It's done, they replied, the schedule changed, it's cancelled; "apply my tagged notes" | `update/SKILL.md` | Sync reality: cross off, advance projects, handle waiting-for replies or corrections, re-date a routine; apply notes tagged `gtd-update` |
| Clean up structure, stuck projects, duplicates | `organize/SKILL.md` | Do mechanical hygiene automatically; surface only items needing confirmation |
| What now, 10 minutes, low energy, shopping, prep, what to follow up on | `engage/SKILL.md` | Pick 3-5 candidates by context / time / energy / priority |
| Weekly review, system feels messy, don't trust the lists | `review/SKILL.md` | Review prep pack + Get Clear / Current / Creative + Horizons |
| Help, what commands are there, how do I use this, which command should I use | `help/SKILL.md` | Read-only: commands table, the rhythm, one "right now" suggestion, where things live; never writes. Checked before the empty-input mind-sweep rule, so "help" is never captured as an inbox item |

## Reference loading table

| What needs deciding | When to read |
|---|---|
| List boundaries, layout, property values, Obsidian links | `references/list-definitions.md` (the core); read first when clarify / organize / review / update move, delete, or write |
| What may run automatically, what needs confirmation | `references/action-permissions.md`; read before deleting, moving, sending, or deciding on the user's behalf |
| Tickles and recurring routines | `references/tickler.md`; read when a tickle is filed, comes due, is re-dated or completed |
| Done record, project close | `references/done-record.md`; read when moving finished work to `_done/` |
| Dependencies (`depends_on:`) | `references/dependencies.md`; read when a step has to wait for another, or something others wait on is completed or cancelled |
| Notes tagged `gtd-update` | `references/tagged-updates.md`; read when applying them |
| A note's full shape with examples | `references/note-formats.md`; the list's template is usually enough |
| Whether a next action is good enough | `references/clarify-decision-tree.md`; read when a next action is vague or the user wants to clarify |
| Calendar provider, auto-write, fallback | `references/capability-map.md`; read when hard landscape or calendar writes are involved |
| Automation cadence / cron / Approval Radar | `references/automation-profiles.md`; read only for init `--install-cron` or the Daily Engage cadence |
| Weekly review steps | `references/weekly-review-checklist.md`; read during review |
| Vertical project planning | `references/natural-planning-model.md`; read when a project's outcome, milestones, or next action are unclear |
| Horizons vertical calibration | `references/horizons-of-focus.md`; read during review or priority conflicts |
| Regression evals | `references/evals.md`; read before and after changing the skill or before a public sync |
