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
Read `${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/SKILL.md` (bundled with the plugin; no install step needed).
Read `${CLAUDE_PLUGIN_ROOT}/skills/gtd-harness/update/SKILL.md` (bundled with the plugin; no install step needed).
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Follow update/SKILL.md:
1. First read the relevant lists: next-actions / projects / waiting-for (files or per-item folders); for scheduling, check the external calendar provider first.
2. A next action that's clearly done → move it to the done record (done.md / _done/) with its outcome, and advance the related project, or close it with an after-action review.
3. A waiting-for reply → move the waiting item to the done record with what arrived, and clarify the reply into a next action, support material, or project closure.
4. Changed event details → update the external calendar provider when uniquely identifiable; create an event if details are complete but none exists; ask one question if unsure.
5. Cancellation / correction → project-linked work goes to the done record as cancelled; a standalone item is deleted; corrections minimally replace the corresponding state.
6. After changing, always search or read back to verify, then report briefly.
</process>
