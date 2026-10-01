---
name: gtd-init
description: Set up / self-check the GTD trusted system — idempotently creates the memory/gtd/ eight lists + adapter-layer self-check
argument-hint: "[optional: --status to self-check only / --with-bases for Obsidian lens views]"
allowed-tools:
  - Read
  - Bash
  - Glob
---
<objective>
First-time enable or reinstall of the GTD harness: idempotently build the memory/gtd/ eight lists, self-check the three-platform adapter layer.
</objective>

<execution_context>
Read `${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/SKILL.md` (bundled with the plugin; no install step needed).
Read `${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/init/SKILL.md` (bundled with the plugin; no install step needed).
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Follow init/SKILL.md. By default run the idempotent init; --with-bases also writes the optional Obsidian lens views; --status only self-checks and writes no files. Read the readiness report and guide the user to run their first capture.
</process>
