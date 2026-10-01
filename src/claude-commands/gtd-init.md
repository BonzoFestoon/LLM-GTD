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
@__VAULT__/.cursor/skills/gtd-harness/SKILL.md
@__VAULT__/.cursor/skills/gtd-harness/init/SKILL.md
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Follow init/SKILL.md. By default run the idempotent init; --with-bases also writes the optional Obsidian lens views; --status only self-checks and writes no files. Read the readiness report and guide the user to run their first capture.
</process>
