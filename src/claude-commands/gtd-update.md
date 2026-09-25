---
name: gtd-update
description: GTD update — handles completions, progress, waiting-for replies, schedule changes, cancellations or corrections, and advances the trusted lists
argument-hint: "[a change that already happened, e.g. 'submitted the passport paperwork' 'they replied' 'meeting moved to Wednesday 3 pm' 'cancel this project']"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---
<objective>
GTD Update: sync the changes in reality the user reports into the trusted system. This isn't capturing new tasks; it's closing completed actions, advancing projects, handling waiting-for replies, updating the calendar, or correcting existing state.
</objective>

<execution_context>
@__VAULT__/.cursor/skills/gtd-harness/SKILL.md
@__VAULT__/.cursor/skills/gtd-harness/update/SKILL.md
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Follow update/SKILL.md:
1. First read the relevant lists: next-actions.md / projects.md / waiting-for.md; for scheduling, check the external calendar provider first.
2. A next action that's clearly done → delete that line, and advance or close the related project.
3. A waiting-for reply → delete the waiting item and clarify the reply into a next action, support material, or project closure.
4. Changed event details → update the external calendar provider when uniquely identifiable; create an event if details are complete but none exists; ask one question if unsure.
5. Cancellation / correction → minimally delete, move, or replace the corresponding state.
6. After changing, always search or read back to verify, then report briefly.
</process>
