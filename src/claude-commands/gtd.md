---
name: gtd
description: GTD harness main entry — routes to init/capture/clarify/update/organize/engage/review, or handles task-management requests directly
argument-hint: "[something to capture / an intent, e.g. 'sort out my inbox' 'what should I do this week' 'Schedule coffee with Jack tomorrow afternoon']"
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - Task
  - AskUserQuestion
---
<objective>
Run the GTD harness from David Allen's perspective: turn tasks / commitments into a "mind like water" trusted external system. Route to the right scenario command based on the user's intent.
</objective>

<execution_context>
@__VAULT__/.cursor/skills/gtd-harness/SKILL.md
</execution_context>

<context>
$ARGUMENTS
</context>

<process>
1. First read the GTD harness package navigation. If `memory/gtd/` doesn't exist here, do **not** run init automatically — read `init/SKILL.md`'s "One inbox per human" rule and ask the user whether GTD is already set up somewhere else before doing anything else, then continue with the user's input.
2. Treat $ARGUMENTS as a natural-language intent; don't require the user to name a subcommand. Route by the following priority; on a match, read the corresponding subcommand's `SKILL.md` and execute it:
   - Help / what can this do / how do I use this / which command should I use / what commands are there → `help/SKILL.md` (checked first, so "help" is never captured as an inbox item — distinct from "help me empty my head" / "help me sort through these", which are mind-sweep requests and stay routed to capture below)
   - Set up / initialize / self-check / status / install → `init/SKILL.md`
   - Empty input / mind sweep / note one thing / new commitment / hard date / session close / a single natural-language task → `capture/SKILL.md`
   - Clarify the inbox / process item by item / where do these to-dos go / clear out the inbox → `clarify/SKILL.md`
   - Done / finished / bought it / sent it / confirmed / they replied / the schedule changed / cancelled or dropped → `update/SKILL.md`
   - Clean up structure / stuck projects / duplicates / re-file contexts / monthly someday / product ideas hygiene → `organize/SKILL.md`
   - What now / what today / for a bit / I have 30 minutes / filter by energy or context → `engage/SKILL.md`
   - Weekly review / weekly retro / review / the system is a mess / don't trust the lists → `review/SKILL.md`
3. Conflict handling:
   - When the user explicitly states a subcommand intent, respect it.
   - When the user reports a change that already happened, prefer update; don't re-capture.
   - When the sentence itself is new input / a new commitment, prefer capture → clarify; don't lecture on GTD theory first.
   - For `/gtd help me empty my head` or an empty `/gtd`, enter capture's mind-sweep flow and first ask the user to dump everything line by line.
   - Pure knowledge / ideas with no commitment are handed off to the ZK pipeline via the clarify gate and not written to GTD action lists.
4. Ask one short question only when "action vs knowledge" or the "desired outcome" can't be determined; don't make the user pick a specific subcommand.
</process>
