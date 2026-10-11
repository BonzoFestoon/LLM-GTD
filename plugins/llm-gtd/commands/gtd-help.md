---
name: gtd-help
description: Which GTD command to use, what each one does, and what's worth doing right now — read-only, never writes
model: haiku
argument-hint: "[optional: a command name for its detail, or 'lists' to explain each list]"
allowed-tools:
  - Read
  - Bash
  - Glob
---
<objective>
Read-only orientation: show the loaded LLM-GTD version, every GTD command with what it does, when to run it, and its recommended model; the day-to-day rhythm; one "right now" suggestion; and where things live. Never creates, edits, or deletes anything in memory/gtd/.
</objective>

<execution_context>
Read `${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/help/SKILL.md` (bundled with the plugin; no install step needed).
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Follow help/SKILL.md. No arguments: run `bash ${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/scripts/gtd_help.sh` once and show its output. It already holds the loaded LLM-GTD version and all four parts (commands with model tiers, the rhythm, one "right now" suggestion, where things live), so don't run gtd_status.sh or read other files for them. $ARGUMENTS is a command name: run `bash ${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/scripts/gtd_help.sh <command>` and show its description plus When to run, unedited. $ARGUMENTS is "lists": explain each list's boundaries from references/list-definitions.md.
</process>
