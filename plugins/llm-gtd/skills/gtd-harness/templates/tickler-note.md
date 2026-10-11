---
id: tk-short-id-YYYYMMDD
tickle: YYYY-MM-DD   # one-shot: when it becomes actionable · recurring: when it is due again
project: "[[projects/Project name/README|Project name]]"   # optional — omit for a standalone tickle
every: 3m            # optional — makes it recurring: <n> + d | w | m | y (7d, 2w, 3m, 1y); omit = one-shot
lead: 7d             # optional, recurring only — create the next action this long before the date
cadence: floating    # optional, recurring only — count from the completion; omit = fixed schedule
last_completed: YYYY-MM-DD   # recurring only — written by update on each completion
time: 45             # optional — carried into the next action (same vocabulary as next actions)
energy: low          # optional
context: [computer]  # optional
source: inbox capture
created: YYYY-MM-DD
---
What becomes actionable on that date, written as concretely as you can (a concrete next action can be moved straight into next-actions/ when the date arrives).

<!--
A tickle is a commitment you can't (or don't want to) act on until a date: not an appointment (calendar), not something someone owes you (waiting-for), not an uncommitted maybe (someday-maybe).
One-shot (no every): a project linked here is on hold on purpose, not stalled. When the date arrives, organize moves a concrete project tickle into next-actions/ (dropping `tickle`, adding time / energy / context) and queues anything else in the inbox for clarify.
Recurring (every set): a routine with no fixed day. On `tickle` minus `lead`, organize creates one next action (body, project, time / energy / context copied; `from:` linking here; `due:` = tickle) and this note stays. Completing it sets `last_completed` and moves `tickle` on — fixed: the next schedule date after the completion (missed periods skipped); floating: completion + every. Overdue the day after `tickle`. It never puts its project on hold. Leave out the lines you don't use.
Never exported to the external calendar. The id's date is the creation date, so re-dating a tickle never changes it. Filename: short, verb-first, filesystem-safe.
-->
