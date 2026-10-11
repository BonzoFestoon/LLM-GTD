# Tickler

Companion to `list-definitions.md`, which holds the core rules. Read this when filing, re-dating, converting or completing a tickle, or handling a recurring routine.

A tickle holds a commitment until its date; the project it links stays in `projects/`, on hold (see `list-definitions.md` "Stalled projects").

- **Filing**: clarify files "committed, but can't act until a date" here (see `clarify-decision-tree.md`), never in someday-maybe or waiting-for, and never in the calendar unless it is a real appointment.
- **When the date arrives** (`gtd_list.sh tickler --due`, `gtd_check.sh` `tickler-due`): organize moves a project tickle whose body is a concrete action into `next-actions/` (drop `tickle`, fill time / energy / context, keep `project:`). Any other due tickle — standalone, or too vague to be an action — gets an **inbox pointer**: one line `- Tickle due: <title> → [[tickler/<title>]] · Captured: YYYYMMDD`, with the note left in place so nothing in its body is lost; clarify then works on the note itself (move it to `next-actions/`, make it a project, re-date it, move it to `someday-maybe/`, or delete it) and removes the line. While the inbox links the note, `gtd_check.sh` reports it as "queued in inbox" and organize does not queue it again. Engage lists due tickles first.
- **Calendar conflicts**: a tickle dated on a day the hard landscape shows as blocked is flagged (rule in `capability-map.md`), never re-dated automatically.
- **Always local**: the tickler is not part of the calendar adapter or its fallback chain; nothing in it is ever written to an external calendar provider, and organize's `calendar.md` reconcile never touches it.
- **Changes**: "the date moved" re-dates `tickle` (id unchanged); a cancelled tickle is deleted (no done record); cancelling or closing a project removes or resolves its tickles first — a project with an open tickle is not closed.

### Recurring tickles

A routine with no fixed day and no hard deadline ("download statements at least quarterly", "verify the backups monthly") is a tickle with `every:`. Routines with a hard date (rent on the 1st, property tax in October) stay on the calendar.

- **Dates**: `tickle` is when the cycle is due. The cycle's **start date** is `tickle` minus `lead` (no `lead`: `tickle`). All date arithmetic goes through `scripts/gtd_next_date.sh` — never worked out by hand.
- **Creating the action**: on the start date, if no open next action's `from:` links the tickle, organize creates one (`gtd_check.sh` `tickler-due`): the body, `project:`, `time` / `energy` / `context` copied (filled by judgment when missing), plus `from: "[[tickler/<Title>|<Title>]]"`, `due: <tickle>`, `source: recurring tickle`. **The tickle stays, unchanged.** No asking: clarify only files a recurring tickle with a concrete body. If that action is deleted without being completed, the next organize creates another; never two at once (`duplicate` if there are).
- **Completing it** (update): the action goes to the done record as `_done/<Title> YYYY-MM-DD.md` (the completion date in the name, so cycles don't pile up as `(2)`, `(3)`), keeping `from:`. Then, in one edit, the tickle gets `last_completed: <completed>` and `tickle: $(gtd_next_date.sh next <every> <tickle> <completed> [floating])` — **fixed** (default): the first schedule date after the completion, so missed periods are skipped, never stacked; **floating** (`cadence: floating`): completion + `every`. Use the date the user names ("I did it on the 3rd") instead of today when they give one.
- **Overdue**: a recurring tickle dated before today (`gtd_list.sh tickler --overdue`, `gtd_check.sh` `tickler-overdue`) — no grace. Shown first in Engage after what came due today, in the Weekly Review, the dashboard and `tickler.base`; never re-dated or dropped automatically.
- **The log** is the done record: `gtd_list.sh done --from "<title>"` lists a routine's cycles. The tickle carries no log of its own.
- **Skip a cycle**: the action goes to the done record with `result: skipped` and the reason; `last_completed` is unchanged; `tickle` moves on by the same rule, counted from today.
- **Pause**: re-date `tickle` to the resume date (any open action is cancelled first); paused with no end → move the note to `someday-maybe/` keeping `every`, and back with a fresh `tickle` when resumed.
- **End**: the tickle moves to `_done/<Title>.md` with `completed`, `result: ended`, `list: tickler` (unlike a cancelled one-shot tickle, it is kept: its cycles link to it); any open action is cancelled into the done record.
- **Change the rule** (`every` / `lead` / `cadence`): edit in place; recompute `tickle` from `last_completed` (or `created`) with `gtd_next_date.sh`, never earlier than today; refresh `due` on an open action.
- **Invalid `every`** (`quarterly`, `3 months`): `tickler-every` with the compact form; organize converts it when the meaning is unambiguous. Until then the note is one-shot. An invalid `lead` is ignored until fixed.
- **Projects**: a recurring tickle never holds its project (see `list-definitions.md` "Stalled projects"); cancelling a project asks once whether to end its routines too. The calendar-conflict check is for one-shot tickles only.
