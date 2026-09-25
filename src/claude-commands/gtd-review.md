---
name: gtd-review
description: GTD Weekly Review (the critical success factor) — AI review prep pack + Get Clear / Current / Creative + Horizons
argument-hint: "[optional: 'monthly' for a deeper monthly review]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - AskUserQuestion
---
<objective>
GTD step 4, Reflect: the Weekly Review, maintaining the system's trustworthiness. Allen calls it the critical success factor.
</objective>

<execution_context>
@__VAULT__/.cursor/skills/gtd-harness/SKILL.md
@__VAULT__/.cursor/skills/gtd-harness/review/SKILL.md
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Follow review/SKILL.md: first run `scripts/gtd_review_prep.sh` to generate the read-only review prep pack, falling back to the dashboard + a manual scan if the script is missing; then do organize's mechanical hygiene, gathering the points needing the user's decision into one batch; finally proceed through ① Get Clear (empty the inbox) ② Get Current (go through next-actions / calendar / waiting / projects, fixing stalled ones on the spot) ③ Get Creative (re-evaluate someday) ④ Horizons check. Record a snapshot with weekly-review-template (save it in your daily-notes folder), and close with a system status summary + next week's 3 things.
</process>
