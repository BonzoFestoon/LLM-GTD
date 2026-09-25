---
name: gtd-engage
description: GTD engage — says "what to do right now" from the lists by context / time available / energy / priority
argument-hint: "[optional: current context / time available / energy, e.g. '@computer 1 hour medium energy']"
allowed-tools:
  - Read
  - Bash
---
<objective>
GTD step 5, Engage: use the four-criteria model to filter "best to do right now" candidates from next-actions.
</objective>

<execution_context>
@__VAULT__/.cursor/skills/gtd-harness/SKILL.md
@__VAULT__/.cursor/skills/gtd-harness/engage/SKILL.md
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Follow engage/SKILL.md: ask about / infer context + time + energy, filter 3-5 candidates from next-actions with time estimates, check priority upward against the horizons, and also flag today's hard appointments and waiting-for items due for a follow-up. If a criterion is missing, ask one question.
</process>
