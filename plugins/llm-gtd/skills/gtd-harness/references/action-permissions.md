# Action permissions

Companion to `list-definitions.md`, which holds the core rules. Read this before deleting, moving, sending, or deciding anything on the user's behalf: what runs automatically, what needs one confirmation, and what never happens.


| Action | Permission tier | Rule |
|---|---|---|
| Read lists, generate dashboard, generate review prep pack | Read-only | Doesn't change GTD state |
| Append new input to `inbox.md` | Auto | Capture only writes to the inbox; nothing is filed or decided at capture time |
| Clarify and file an inbox item (`/gtd-clarify`) | Auto | Capture never clarifies; clarify asks one question only when action/knowledge, the commitment itself, or the desired outcome is unclear |
| Delete a clarified original item from `inbox.md` | Auto | Its note must already exist in the target list |
| Move clearly misfiled items | Auto | Create the note in the target list first, then delete it from the original spot |
| Fill in time / energy / context | Auto | List as pending confirmation when clearly uncertain |
| Delete a cancelled standalone action or a dropped someday item | Auto | The user explicitly cancelled it; project-linked work goes to the done record as `cancelled` instead |
| Draft a next action for a stalled project | Auto | Act-then-surface; the user can change it in one sentence. Never for a project on hold (a tickle links it) |
| Turn a due tickle into a next action, or add an inbox pointer to it | Auto | A concrete project tickle moves to `next-actions/`, anything else is queued in the inbox once; reported in organize's one-line summary |
| Create the next action for a due recurring tickle | Auto | Only when no open action links it (`from:`); the tickle stays; reported in organize's one-line summary |
| Re-date a recurring tickle after its action is completed | Auto | Through `gtd_next_date.sh`; part of update's done step |
| Rewrite a `depends_on:` link to a finished item's `_done/` path | Auto | Part of update's done step and organize's `depends-done-link` fix; reported as "Now unblocked: …" |
| Drop a dependency, or cancel what waited on a cancelled item | Needs confirmation | Asked once when the item is cancelled, or in organize's batch; never decided automatically |
| Skip a cycle, pause, end a routine, or change its rule | Needs confirmation | The user says so; an overdue routine is never skipped, re-dated or ended automatically |
| Apply a tagged note's Update section | Auto for clear lines | Each line under update's own rules; unclear lines asked once, in a batch; the tag is removed only when every line is resolved |
| Re-date a tickle that conflicts with the calendar | Needs confirmation | Organize flags it with a suggested date; never re-dates on its own |
| Export a tickle to the external calendar | Never | The tickler is local: when things become actionable, not appointments |
| Move a completed item to `_done/` with its outcome | Auto | The user explicitly declared it done or there is strong evidence; act-then-surface; never blocks on the outcome text, never re-asked later |
| Close a finished project into the done record | Auto after the AAR confirmation | Desired outcome achieved and no open action still linked; the AAR confirm / edit / skip is the one confirmation |
| Draft a project after-action review | Auto | Act-then-surface when the project's outcome is achieved; the user confirms, edits, or skips in one step |
| File AAR how-tos and insights to reference (project folder or `reference/`) | Needs confirmation, once | Offered together with the AAR draft, not as a separate interruption |
| Trim `_done/` | Needs confirmation | Off by default; only runs if enabled in `personalized.md` |
| Activate someday / cut a project | Needs confirmation | These are commitment decisions; don't settle them automatically |
| Write to the external calendar provider | Conditional auto | Event details complete, no conflict in the target slot, provider reachable; never claim done before the tool succeeds |
| Delete a `calendar.md` fallback item | Conditional auto | Confirmed written to the external calendar, or moved back to another GTD list |
| Send messages, follow up, notify, delegate to others | Needs confirmation | May draft wording; never send automatically |
| approve / reject / withdraw / cc approval | Never auto | Approval Radar may only scan read-only |
| Schedule Engage candidates into the calendar | Needs confirmation | Candidates are a menu, not today's commitments |
