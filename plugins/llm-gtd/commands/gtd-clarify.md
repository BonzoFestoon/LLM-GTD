---
name: gtd-clarify
description: GTD clarify — runs the decision tree on each inbox item (actionable → 2 minutes / delegate / defer / project; not actionable → trash / someday / reference) and files it
argument-hint: "[optional: only clarify specific items; leave empty to clarify the whole inbox]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - AskUserQuestion
---
<objective>
GTD steps 2 + 3, Clarify + Organize: question the "stuff" in the inbox item by item into "next actions" and file each in the right list.
</objective>

<execution_context>
Read `${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/SKILL.md` (bundled with the plugin; no install step needed).
Read `${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/clarify/SKILL.md` (bundled with the plugin; no install step needed).
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Run the decision tree in clarify/SKILL.md: for each inbox item decide "is it actionable / what's the next concrete action", file it in the matching list (next-actions with light-field tags, >1 step becomes a project, knowledge handed to the ZK pipeline), and delete it from the inbox after filing. Recognize and flag the two-minute rule. When information is insufficient, ask one question; don't make things up.
</process>
