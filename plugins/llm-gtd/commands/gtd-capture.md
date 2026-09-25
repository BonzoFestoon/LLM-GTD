---
name: gtd-capture
description: GTD capture — writes to the inbox with zero friction, then auto-clarifies and files by default (single items); batches / mind sweeps are fully captured first, then clarified in bulk
argument-hint: "[things to capture, one or more; leave empty for a mind sweep; say 'capture only' to skip auto-clarify]"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---
<objective>
GTD step 1, Capture (AI-native): first write to memory/gtd/inbox.md with zero friction (so nothing is lost), then by default auto-clarify and file for the user — you're an AI, your switching cost is ≈0, so the user shouldn't have to run step two by hand.
</objective>

<execution_context>
@__VAULT__/.cursor/skills/gtd-harness/SKILL.md
@__VAULT__/.cursor/skills/gtd-harness/capture/SKILL.md
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
Follow capture/SKILL.md:
1. First write each item in $ARGUMENTS verbatim to inbox.md (so nothing is lost).
2. Single / few items → by default run the clarify decision tree, clarify and file into the right list + set the next action, delete from the inbox, and report the destination in one line (act-then-surface, correctable in one sentence).
3. Batch / empty input mind sweep → capture everything first, then ask once "Want me to clarify these one by one now?"
4. Stop and ask one question only in the four decision cases (action vs knowledge / no derivable next action / implied commitment / unclear project outcome).
5. The user says "capture only / don't clarify yet" → write to the inbox only, no auto-clarify.
</process>
