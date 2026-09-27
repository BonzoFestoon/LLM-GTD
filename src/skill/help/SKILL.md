---
name: gtd-help
description: GTD skill scenario command · Help. Read-only — never writes. Shows every command with what it does, when to run it, and its recommended model; the day-to-day rhythm; one "right now" suggestion; and where things live. `/gtd-help <command>` gives one command's detail; `/gtd-help lists` explains each list.
parent: gtd-harness
model-tier: fast
example: "Which GTD command should I use?"
---


# GTD · help (which command, what it does, what's next)

**Perspective**: David Allen. A trusted system nobody can navigate isn't trusted for long — help exists so the eight commands and their rhythm are never a memory burden either.

## Loading and boundaries

- No arguments, or a command name: run `scripts/gtd_help.sh [command]`; the script reads every sub-skill's frontmatter and `## When to run` section, so the output is never hand-written and never drifts.
- `lists` argument: read `references/list-definitions.md` and explain each list.
- Automation boundary: **read-only, always.** Help never creates, edits, or deletes anything in `memory/gtd/`, never runs init, never files an item — not even if the input sounds like a task ("help me remember to call the dentist" is capture's job, not help's; if genuinely ambiguous, ask which one was meant rather than guessing and writing).

## When to run

- "Help", "what can this do", "how do I use this", "which command should I use", "what commands are there".
- The user seems unsure which of the eight commands fits what they want, or asks what a specific one does.
- Anywhere the router (`SKILL.md`'s routing table) can't confidently match an intent to one of the other seven commands — offering help is better than guessing wrong.

## Workflow

1. **No arguments — the default view**, built entirely from `scripts/gtd_help.sh` (no argument):
   1. **Commands table**: all nine commands (`gtd`, `gtd-init`, `gtd-capture`, `gtd-clarify`, `gtd-update`, `gtd-organize`, `gtd-engage`, `gtd-review`, `gtd-help`), each with its `description`, `## When to run`, `example`, and a **Model** column from `references/model-guidance.md`'s tier table plus this session's current model (or "unknown" if it can't be determined).
   2. **The rhythm**: capture any time → clarify when the inbox has items (usually automatic) → engage when choosing what to do → update when something changes → organize runs by itself before engage and review → Weekly Review once a week.
   3. **Right now**: run `scripts/gtd_status.sh` and turn its top finding into one suggestion, e.g. "3 items in the inbox → `/gtd-clarify`", "2 stalled projects → `/gtd-organize`", or "nothing pending → `/gtd-engage`". If the status script can't run, skip this section and say so in one line — never block the rest of the output on it.
   4. **Where things live**: the resolved GTD folder (from `gtd_init.sh --status`'s `Vault:` line or equivalent), the lists (plus their `README.md`, in per-item layout), and `_done/` (per-item layout only).

2. **`/gtd-help <command>`**: run `scripts/gtd_help.sh <command>` and show that one command's `description` plus its `## When to run` section, verbatim from the sub-skill — nothing summarized or reworded.

3. **`/gtd-help lists`**: read `references/list-definitions.md` and explain, per list, what belongs there and what doesn't — this is the one case help reads a reference file directly rather than going through `gtd_help.sh`, since list boundaries aren't part of any sub-skill's frontmatter.

## Quality check

- [ ] Never writes to any file in `memory/gtd/`, under any input
- [ ] Default view has all four parts: commands table (with model column), the rhythm, one "right now" suggestion (or an honest skip), where things live
- [ ] Commands table content comes from `gtd_help.sh` reading sub-skill frontmatter/sections, never hand-typed into this file
- [ ] `<command>` argument shows that command's own description + When to run, unedited
- [ ] `lists` argument explains list boundaries from `references/list-definitions.md`, not reinvented here
- [ ] A status-script failure skips that one section with a one-line note, never blocks or errors the rest of the output
