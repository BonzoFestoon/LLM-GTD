---
name: gtd-capture
description: GTD skill scenario command · Capture. Writes input to the inbox verbatim with zero friction — nothing is clarified, filed or decided; also used for mind sweeps and session close. GTD step 1; clarifying is its own step (/gtd-clarify).
parent: gtd-harness
model-tier: fast
example: "Note this: confirm the contract version with Colleague A"
---


# GTD · capture (inbox only)

**Perspective**: David Allen. Capture gets things out of your head and into a trusted inbox **fast and easily**; deciding what each thing means is a different kind of thinking, done later, in its own step (`/gtd-clarify`). Mixing the two makes capture slow and makes you hesitate to capture at all, so capture never clarifies, files, or asks what something means.

## Loading and boundaries

- Session close: read `templates/session-close-template.md` first.
- Nothing else to load: capture needs no list definitions, decision tree or note templates.
- Automation boundary: capture only appends to `memory/gtd/inbox.md`. It never creates notes in other lists, never deletes from the inbox, and never asks a question about what an item means.

## When to run
- The user comes up with a to-do, idea, reminder, commitment, open question, "don't forget…".
- The user says "note this", "put it in the inbox", "capture this for me".
- The user wants to wrap up "today / this session's status / close this session": turn the commitments, blockers, waiting-fors, hard dates, project status changes and insights from the conversation into inbox items, and output the fixed five sections.
- A one-time full mind sweep: "my head is a mess, help me empty it".

## Workflow

1. **Write to the inbox, verbatim**: append each item to the end of the "To clarify" section of `memory/gtd/inbox.md`, one item per line, keeping the user's own wording (split a message into items only where the user clearly listed several things):
   ```
   - Original wording · Captured: YYYYMMDD
   ```

2. **Report in one line** and stop: "Captured N item(s) to the inbox (M waiting to clarify). Run `/gtd-clarify` when you're ready." Count M from the inbox's `- ` lines. No question, no suggested list, no next action.

3. **Mind sweep** (empty input, or "empty my head"): prompt with an incompletion trigger list (work: projects started, commitments to others, communications to send, upcoming events, waiting on; personal: home, family, health, finances, errands, someday ideas), writing each thing the user names to the inbox as it comes, without comment. When they're done, report the count once, as in step 2.

4. **Session close**: when the user says "wrap up today / this session's status / close out", read `templates/session-close-template.md`, then compress the conversation into 3-5 GTD-relevant deltas — new commitments, pending confirmations, waiting on others, hard dates, project status changes or blockers, and knowledge insights worth keeping. Write each as its own inbox item from the raw facts (an insight as `- Insight: … · Captured: YYYYMMDD`; clarify files it to `reference/`). Don't stuff a chat summary or emotional log into the inbox. Run `scripts/gtd_status.sh`, then output the template's five sections.

5. **Changes to existing items aren't captures**: "that's done", "they replied", "move it to Friday" are updates — route them to `update/SKILL.md` instead of adding an inbox line.

## Quality check
- [ ] Every item is in `inbox.md` verbatim, one per line, with its capture date
- [ ] Nothing filed, moved, deleted or decided; no note created outside the inbox
- [ ] No question asked about what an item means; one-line report naming `/gtd-clarify`
- [ ] Mind sweep captured everything as it came, with no commentary per item
- [ ] Session close wrote only GTD-relevant deltas (insights included) as inbox items and used the five-section template
