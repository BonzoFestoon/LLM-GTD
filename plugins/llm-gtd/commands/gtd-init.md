---
name: gtd-init
description: Set up / self-check the GTD trusted system — idempotently creates the memory/gtd/ eight lists + adapter-layer self-check (optionally imports old open loops)
argument-hint: "[optional: --import-legacy to import old data / --status to self-check only]"
allowed-tools:
  - Read
  - Bash
  - Glob
---
<objective>
First-time enable or reinstall of the GTD harness: idempotently build the memory/gtd/ eight lists, self-check the three-platform adapter layer, optionally import old open loops.
</objective>

<execution_context>
Read `${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/SKILL.md` (bundled with the plugin; no install step needed).
Read `${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/init/SKILL.md` (bundled with the plugin; no install step needed).
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Follow init/SKILL.md. By default run the idempotent init; if $ARGUMENTS contains --import-legacy, also do the one-time import (old file read-only, never modified); --status only self-checks and writes no files. Read the readiness report and guide the user to run their first capture.
</process>
