---
name: gtd-update
description: GTD skill scenario command · Update. Handles changes in reality the user reports — done, progress, a waiting-for reply, changed event details, a cancelled project, or a correction — and syncs the trusted lists forward.
parent: gtd-harness
---


# GTD · update (status update / reporting reality)

**Perspective**: David Allen, with an AI-native refinement. Update is not about "new stuff entering the system" but about **reality having already changed**: a next action got done, the person you were waiting on replied, project facts changed, event details were settled, a commitment was cancelled. A trusted system must stay in sync with reality, or it quickly becomes a burden the mind has to carry again.

## Loading and boundaries

- List boundaries and action permissions: read `references/list-definitions.md` first.
- Hard landscape / calendar changes: read `references/capability-map.md`.
- Unclear project outcome or next action: read `references/clarify-decision-tree.md` and `references/natural-planning-model.md` as needed.
- Automation boundary: clear completions, clear waiting-for replies, and clear text corrections can be updated automatically; ask one question on multiple matches, when a whole project block would be deleted, or when a calendar event can't be uniquely identified.

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
   - By default scan `next-actions.md`, `projects.md`, `waiting-for.md` first.
   - If dates / times / places / flights / meetings are involved → read the external calendar provider first; if all are unreachable, read the `calendar.md` fallback.
   - If project support facts are involved → read `reference.md` as needed.

2. **Determine the update type**:

   | Type | How to tell | Action |
   |---|---|---|
   | Next action done | Clearly matches one `next-actions` item | Delete that next-action line; if it belongs to a project, check whether the project needs a new next action or is closed |
   | Project progress | The user gave facts that affect the next action | Update project support facts; remove the completed next action; derive a new concrete next action |
   | Waiting For reply | Clearly matches one `waiting-for` item | Delete the waiting-for line; clarify the reply into a next action / reference / project closure |
   | Event details changed | Date / time / place / departure window changed | Update the external calendar provider event; if no clear event is found and details are complete, create one; ask one question if unsure |
   | Commitment cancelled / dropped | The user explicitly cancels | Delete the corresponding action or project block; if merely paused but still wanted, move it to someday-maybe |
   | Text correction | The user corrects an existing fact or wording | Minimally replace the corresponding list line or project support material |

3. **Matching rules**:
   - Exactly one clear match → update directly.
   - Several similar items, deleting a whole project block, or a calendar event that can't be uniquely identified → ask one short question first; don't guess.
   - Deleting a list line closes a GTD loop; it is not deleting a file. This command may directly delete action lines that are clearly done.
   - Don't keep "done" as checked-off history; live lists hold only commitments that still need attention.

4. **Advance projects**:
   - When a completed action belongs to a project, read that project block.
   - If the desired outcome is achieved and no next action still needs pushing → delete the whole project block.
   - If the project is still unfinished → draft **one** most suitable current next action from the new facts and point the project's next-action link to it.
   - If the new next action needs the user's value judgment or information is missing → don't force one; list the gap and ask one question.

5. **Calendar update contract**:
   - When an external calendar provider is reachable, it is the hard landscape; never claim a write before the update succeeds.
   - Uniquely matches an existing event → update event.
   - No existing event found but title + date + start time are present → create event.
   - Key fields missing or possible duplicate → ask for the missing fields; never write a guessed event.
   - All external providers unreachable / failing → write the `calendar.md` fallback and say "not written to the external calendar".

6. **Verify**:
   - After changing, search for the relevant keywords to confirm the old action / waiting-for item is gone or the new event / new action exists.
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
- [ ] Completed actions deleted from next-actions, no checked-off history left
- [ ] Waiting-for replies re-clarified and no longer on the waiting list
- [ ] Live projects have a new current next action; completed projects had their whole block deleted
- [ ] Calendar updates claimed complete only after the calendar provider / tool succeeded
- [ ] Asked one question on multiple matches or risky deletions; no guessing
