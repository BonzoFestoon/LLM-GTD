---
name: gtd-update
description: GTD skill scenario command · Update. Handles changes in reality the user reports — done, progress, a waiting-for reply, changed event details, a cancelled project, or a correction — and syncs the trusted lists forward.
parent: gtd-harness
model-tier: balanced
example: "The dentist appointment got moved to Friday"
---


# GTD · update (status update / reporting reality)

**Perspective**: David Allen, with an AI-native refinement. Update is not about "new stuff entering the system" but about **reality having already changed**: a next action got done, the person you were waiting on replied, project facts changed, event details were settled, a commitment was cancelled. A trusted system must stay in sync with reality, or it quickly becomes a burden the mind has to carry again.

## Loading and boundaries

- List boundaries and action permissions: read `references/list-definitions.md` first.
- Hard landscape / calendar changes: read `references/capability-map.md`.
- Unclear project outcome or next action: read `references/clarify-decision-tree.md` and `references/natural-planning-model.md` as needed.
- Done record and after-action review (AAR): `references/list-definitions.md` "Done record"; shapes in `templates/done-log.md` (single-file), `_done/README.md` (per-item) and `templates/after-action-review.md`.
- Automation boundary: clear completions, clear waiting-for replies, and clear text corrections can be updated automatically; ask one question on multiple matches, when a whole project would be closed or cut, or when a calendar event can't be uniquely identified.

## When to run

- The user says "done / finished / bought it / sent it / confirmed / it's scheduled / they replied".
- The user reports project progress: "I talked it over with my family and we've settled the arrangement."
- The user corrects an existing state: "Not Wednesday evening — the flight leaves Wednesday at 13:30."
- The user cancels or downgrades a commitment: "Skip this for now / no need to follow up / close this project."

## Boundaries with other commands

- **New input / new commitment** → `capture/SKILL.md`.
- **Unclarified items in the inbox** → `clarify/SKILL.md`.
- **Mechanical structural hygiene** (orphans, duplicates, stalled scan) → `organize/SKILL.md`.
- **Choosing what to do right now** → `engage/SKILL.md`.
- **Whether a direction / project is still worth it** → `review/SKILL.md`.

Update does one thing: sync the change in reality the user just reported into `memory/gtd/` and the real hard landscape.

## Workflow

1. **Read the relevant lists before changing anything**:
   - By default scan next-actions, projects, and waiting-for first (`scripts/gtd_list.sh <list>`, which reads either layout; in the per-item layout, also read the list's `README.md` before moving a note out of it).
   - If dates / times / places / flights / meetings are involved → read the external calendar provider first; if all are unreachable, read the `calendar.md` fallback.
   - If project support facts are involved → read `reference.md` as needed.

2. **Determine the update type**:

   | Type | How to tell | Action |
   |---|---|---|
   | Next action done | Clearly matches one `next-actions` item | Move it to the done record with its outcome (see "Done record" below); if it belongs to a project, check whether the project needs a new next action or is finished |
   | Project progress | The user gave facts that affect the next action | Update project support facts; move the completed next action to the done record; derive a new concrete next action |
   | Waiting For reply | Clearly matches one `waiting-for` item | Move it to the done record with what arrived as its outcome; clarify the reply into a next action / reference / project closure |
   | Event details changed | Date / time / place / departure window changed | Update the external calendar provider event; if no clear event is found and details are complete, create one; ask one question if unsure |
   | Commitment cancelled / dropped | The user explicitly cancels | A project-linked action or waiting-for → done record with `result: cancelled` and the reason; a standalone action or a someday item → delete it; a tickle → delete it (no done record); a whole project → ask once, then close it as cancelled (the AAR is optional), removing its tickles too. If merely paused but still wanted, move it to someday-maybe |
   | Tickle date moved (per-item) | "That can't start until X now" / "push it to December" for a tickle | Change the note's `tickle:` (the `id` stays); if the project's whole timeline moved, say so in its README's Decisions |
   | Text correction | The user corrects an existing fact or wording | Minimally replace the corresponding list line / note, or project support material |

3. **Matching rules**:
   - Exactly one clear match → update directly.
   - Several similar items, closing or cutting a whole project, or a calendar event that can't be uniquely identified → ask one short question first; don't guess.
   - Moving a finished item to the done record closes the GTD loop; live lists hold only commitments that still need attention, never checked-off history.

4. **Advance projects**:
   - When a completed action belongs to a project, read that project (block or `README.md`) and its remaining open actions / waiting-for / tickles (`gtd_list.sh next-actions --project "<Name>"`, same for waiting-for and tickler). A tickle still linking it means the project is on hold until that date, not stalled: don't draft a new next action for it.
   - If the desired outcome is achieved and no next action still needs pushing → close it with an after-action review ("Project close" below).
   - If the project is still unfinished → draft **one** most suitable current next action from the new facts and link it to the project (single-file: point the project's next-action link to it; per-item: a note whose `project:` links the README).
   - If the new next action needs the user's value judgment or information is missing → don't force one; list the gap and ask one question.

## Done record

A finished item leaves its list and lands in the done record with an outcome. Never block the completion on the outcome, and never re-ask about it later.

- **Per-item layout**: move the note to `memory/gtd/_done/<same filename>` (add `(2)` on a collision). Keep every property and the body; add `completed: <today>`, `result: done | cancelled`, `list: <the list it came from>`; append `## Outcome` with `- Done:`, `- Problems and fixes:`, and `- Links:` when there are any.
- **Single-file layout**: delete the line from its list and add it to `memory/gtd/done.md` (create it from `templates/done-log.md` if missing) under today's `## YYYY-MM-DD` heading (add the heading at the end if it isn't there), as `- [x] <text> · From: <list> · Result: <done|cancelled> · Project: <link if any> ^<id>` with indented `- Done:` and `- Problems and fixes:` sub-bullets.
- **Writing the outcome**:
  - You did or watched the work in this session → write it yourself: the steps taken, errors hit, and the fix that worked. Ask nothing; the one-line report shows it, and the user can correct it in one sentence.
  - The user just says "done" with no context → ask **one optional** question, and only when the action belongs to a project or was estimated at 30 min or more / deep work: "Anything worth noting: what got in the way and how you got past it?" Silence or "no" records `Problems and fixes: none noted`. A quick standalone action is never asked.
- A received waiting-for records what arrived under `Done:`. A cancelled project step records the reason under `Done:`.

## Project close (after-action review)

When a project's outcome is achieved (here, or when organize / review hands one over), before it leaves the active list:

1. **Gather**: the project (per-item `README.md`; single-file block) plus its done items, cancelled steps included (`gtd_list.sh done --project "<Name>"`, then read those notes / lines).
2. **Draft the AAR** in the shape of `templates/after-action-review.md`: intended outcome · what happened (dated milestones from the done items) · problems and how they were overcome · the same or different next time · reusable how-tos. Per-item: under the README's `## After action review`. Single-file: as the sub-bullets of the project's `done.md` line.
3. **Offer filing, in the same message**: project-specific facts and how-tos → a note in the project's own folder (per-item) or its `reference.md` project-support entry (single-file); reusable how-tos and general insights → a new `reference/<Title>.md` (per-item) or `reference.md` (single-file), unless `personalized.md` names another destination. Never into an action list.
4. **One confirmation** covers the AAR and the filing: confirm, edit, or skip. Skipping still closes the project; per-item keeps the draft, or writes `Skipped (YYYY-MM-DD).` if there is none.
5. **Close**:
   - Per-item: add `completed`, `result`, and `list: projects` to the README, and ask in that same confirmation which support files are worth keeping (default: keep all). Move the whole folder to `memory/gtd/_done/<Project name>/`. Then rewrite links to it: every `[[projects/<Project name>/…` anywhere in the workspace becomes `[[_done/<Project name>/…`, including the `project:` of its done notes. `gtd_check.sh` should then report no `done-link` or `orphan-closed` for it.
   - Single-file: delete the project block from `projects.md` and add `- [x] Project: <Name> — <outcome> · From: projects · Result: done` with its `Done:`, `Problems and fixes:`, and AAR sub-bullets to `done.md`.
6. Open actions or tickles still linked to the project mean it isn't finished. Ask about them first (done, cancelled, or re-home them) rather than closing over them.

5. **Calendar update contract**:
   - When an external calendar provider is reachable, it is the hard landscape; never claim a write before the update succeeds.
   - Uniquely matches an existing event → update event.
   - No existing event found but title + date + start time are present → create event.
   - Key fields missing or possible duplicate → ask for the missing fields; never write a guessed event.
   - All external providers unreachable / failing → write the `calendar.md` fallback and say "not written to the external calendar".

6. **Verify**:
   - After changing, search for the relevant keywords to confirm the old action / waiting-for item is gone from its list and is in the done record, or the new event / new action exists. In the per-item layout, `gtd_check.sh` after a project close.
   - Run `scripts/gtd_status.sh` to see the dashboard when needed.
   - Report only the key changes; don't recite the whole list.

## Output format

Briefly output three things:
1. **Updated**: which list / calendar changed.
2. **What's left now**: the project's new next action, who you're still waiting on, or confirmation that it's closed.
3. **Verified**: state that you searched or read back to confirm.

## Quality check
- [ ] Read the lists before changing; nothing updated from memory
- [ ] Distinguished new input (capture) from changes in reality (update)
- [ ] Completed actions moved to the done record with an outcome; nothing checked-off left in the live list
- [ ] Asked at most one optional outcome question, and only for project-linked or 30+ min / deep work with no session context
- [ ] Waiting-for replies re-clarified and moved to the done record with what arrived
- [ ] Live projects have a new current next action; finished projects got an AAR draft (confirmed, edited, or skipped in one step) and moved to the done record, with links to them rewritten
- [ ] A cancelled standalone action or someday item was deleted, not recorded
- [ ] Calendar updates claimed complete only after the calendar provider / tool succeeded
- [ ] Asked one question on multiple matches or risky deletions; no guessing
