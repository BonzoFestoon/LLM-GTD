# Done record

Companion to `list-definitions.md`, which holds the core rules. Read this when moving finished work to `_done/`, closing a project, or reading the done record.


Completed next actions, received waiting-for items, finished projects, and cancelled project steps move to `_done/` with an outcome: what was done, what problems came up and how they were solved. This replaces deleting the item outright — the active lists still hold only open commitments, and the done record is the raw material for the Weekly Review's "done since last review" section and each project's after-action review (AAR). A cancelled *standalone* action, or a someday item you drop, is still simply deleted — only project-linked work is worth keeping a record of. `_done/` is never read by Engage, never counted as open, and never checked for orphans/stalled status.

- **Shape**: a finished action or waiting-for item is a flat `_done/<Title>.md` that keeps its filename, properties and body, and gains `completed`, `result` (done | cancelled), `list` and a `## Outcome` section (`Done:` / `Problems and fixes:` / `Links:`). A finished project moves as its whole folder to `_done/<Project name>/`: the README gains the same three properties plus its after-action review, the support material you chose to keep stays beside it, and every link to `projects/<Project name>/…` is rewritten to `_done/<Project name>/…`.
- **Recurring cycles**: an action with `from:` lands as `_done/<Title> YYYY-MM-DD.md` (its completion date), `result: done | skipped | cancelled`; an ended routine's tickle lands as `_done/<Title>.md` with `result: ended`, `list: tickler`.
- **Reading it**: only `gtd_list.sh done [--since DATE] [--project P] [--from ROUTINE] [--problems]`, the Weekly Review, and the AAR read the done record.

The five-heading AAR shape (intended outcome · what happened · problems and how they were overcome · what to do the same or differently next time · reusable how-tos) is in `templates/after-action-review.md`; the close steps are `update/SKILL.md`'s "Project close".
