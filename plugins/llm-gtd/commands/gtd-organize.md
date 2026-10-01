---
name: gtd-organize
description: GTD structural hygiene (AI-automated) — fixes mechanical issues (orphans / stalled / contexts / stale checkmarks / duplicates) automatically and surfaces only what needs your decision
argument-hint: "[optional: 'monthly someday scan' or a specific list]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---
<objective>
GTD step 3, structural hygiene (AI-native): this is the step the AI should most fully automate. Mechanical bookkeeping (orphans, stalled, re-filing contexts, stale checkmarks, dedupe) is fixed automatically; only what truly needs the user's decision (stalled ones it can't fix / should be cut / someday to activate) is surfaced.
</objective>

<execution_context>
Read `${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/SKILL.md` (bundled with the plugin; no install step needed).
Read `${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/organize/SKILL.md` (bundled with the plugin; no install step needed).
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Follow organize/SKILL.md: 1) fix mechanical issues directly — re-link orphans, re-file wrong contexts, group @agenda by person, split overloaded contexts, clear stale checkmarks and dedupe; 2) for stalled projects (no open next action, waiting-for or tickle; a tickled project is on hold, never given a drafted action) the AI drafts and writes a next action and links it (act-then-surface), asking in a batch about the ones it can't draft; per-item, it turns due tickles into next actions or inbox pointers and flags tickle dates that clash with the calendar, never exporting the tickler; 3) monthly, flag ripe someday candidates and ask in a batch whether to activate them; 4) give a one-line summary of what was changed automatically + list everything needing a decision at once. Don't interrupt item by item; don't make commitment / project-cutting decisions for the user.
</process>
