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

- No arguments, or a command name: run `scripts/gtd_help.sh [command]`; the script reads every sub-skill's frontmatter and `## When to run` section, so the output is never hand-written and never drifts. Nothing else needs loading: help doesn't use the main `SKILL.md`'s routing table.
- `lists` argument: read `references/list-definitions.md` and explain each list.
- Automation boundary: **read-only, always.** Help never creates, edits, or deletes anything in `memory/gtd/`, never runs init, never files an item — not even if the input sounds like a task ("help me remember to call the dentist" is capture's job, not help's; if genuinely ambiguous, ask which one was meant rather than guessing and writing).

## When to run

- "Help", "what can this do", "how do I use this", "which command should I use", "what commands are there".
- The user seems unsure which of the eight commands fits what they want, or asks what a specific one does.
- Anywhere the router (`SKILL.md`'s routing table) can't confidently match an intent to one of the other seven commands — offering help is better than guessing wrong.

## Workflow

1. **No arguments — the default view**: run `scripts/gtd_help.sh` (no argument) **once** and show its output. It prints the loaded LLM-GTD version (and where it was loaded from — a plugin runs from a per-version cache, so this shows whether a reinstall is needed) above all four parts, so don't run `gtd_status.sh`, `gtd_init.sh --status` or read other files to build them:
   1. **Commands table**: all nine commands (`gtd`, `gtd-init`, `gtd-capture`, `gtd-clarify`, `gtd-update`, `gtd-organize`, `gtd-engage`, `gtd-review`, `gtd-help`), each with its `description`, `example` and model tier, then the tier → model mapping read from `references/model-guidance.md`. The script can't see the session's model; add it in one line if you know it.
   2. **The rhythm**: capture any time (inbox only) → clarify when you choose to process the inbox → engage when choosing what to do → update when something changes (said in chat, or written into a note tagged `gtd-update` from anywhere, the phone included) → organize runs by itself before engage and review → Weekly Review once a week.
   3. **Right now**: one suggestion from the quick signals only — inbox items → `/gtd-clarify`, tagged notes → `/gtd-update`, due tickles → `/gtd-organize`, otherwise `/gtd-engage`. Stalled projects and the done count are left out on purpose: on a large vault they take minutes (`gtd_status.sh` has them), and organize finds stalled projects before engage anyway. If `memory/gtd/` can't be found, the script skips this part with a one-line note.
   4. **Where things live**: the resolved GTD folder and how it was resolved (`LLM_GTD_ROOT`, the legacy install, or the current directory), each list, `_done/`, and `reference/` at the workspace root. If the folder is missing, never offer init: ask where GTD lives (see `init/SKILL.md`'s "One inbox per human").

2. **`/gtd-help <command>`**: run `scripts/gtd_help.sh <command>` and show that one command's `description` plus its `## When to run` section, verbatim from the sub-skill — nothing summarized or reworded.

3. **`/gtd-help lists`**: read `references/list-definitions.md` and explain, per list, what belongs there and what doesn't — this is the one case help reads a reference file directly rather than going through `gtd_help.sh`, since list boundaries aren't part of any sub-skill's frontmatter.

## Quality check

- [ ] Never writes to any file in `memory/gtd/`, under any input
- [ ] Default view starts with the loaded version and its location, then has all four parts: commands table (with model tiers), the rhythm, one "right now" suggestion (or an honest skip), where things live
- [ ] Default view takes one `gtd_help.sh` call and no other reads or scripts
- [ ] Commands table content comes from `gtd_help.sh` reading sub-skill frontmatter/sections, never hand-typed into this file
- [ ] `<command>` argument shows that command's own description + When to run, unedited
- [ ] `lists` argument explains list boundaries from `references/list-definitions.md`, not reinvented here
- [ ] A missing `memory/gtd/` skips "right now" with a one-line note, never blocks or errors the rest of the output
