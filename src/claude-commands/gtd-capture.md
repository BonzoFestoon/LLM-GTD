---
name: gtd-capture
description: GTD capture — writes to the inbox verbatim with zero friction, nothing else; clarifying is its own step (/gtd-clarify). Empty input starts a mind sweep
argument-hint: "[things to capture, one or more; leave empty for a mind sweep]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---
<objective>
GTD step 1, Capture: get each item into memory/gtd/inbox.md fast, verbatim, with zero friction. Capture never clarifies, files, or asks what an item means — deciding is a different kind of thinking, done later in its own step (/gtd-clarify).
</objective>

<execution_context>
@__VAULT__/.cursor/skills/gtd-harness/shared-rules.md
@__VAULT__/.cursor/skills/gtd-harness/capture/SKILL.md
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Follow capture/SKILL.md:
1. Write each item in $ARGUMENTS verbatim to inbox.md, one per line with its capture date.
2. Report in one line — "Captured N item(s) to the inbox (M waiting to clarify). Run /gtd-clarify when you're ready." — and stop. No question, no suggested list or next action.
3. Empty input → mind sweep: prompt with the trigger list, capture each thing as it comes without comment, report the count once at the end.
4. Session close → the template's deltas (insights included) go to the inbox as items; nothing is filed.
5. A change to an existing item ("that's done", "they replied") is an update, not a capture → follow update/SKILL.md.
</process>
