# Eight Core Lists + Extension List Definitions (what it is / what it isn't)

The boundaries of the trusted system. Each list has a single job; mixing in foreign items destroys its trustworthiness.

| List | What it is | What it **isn't** | How it's organized |
|---|---|---|---|
| `inbox.md` | The capture entry point for unclarified items | Not a to-do list (nothing here has been decided yet) | First in, first out |
| `next-actions.md` | Action pool of clarified, single-step, doable actions | Not projects, not time-specific items, and not a category system maintained by soft tool tags | Action pool + light fields: Time / Energy / Constraint; legacy @computer/@calls/@errands/@home/@agenda groups kept only for historical compatibility |
| `projects.md` | Desired outcomes that take >1 step | Not single-step actions, not vague wishes, not a full task tree | Each ## block = outcome + one or more current next-action block links + support material pointers |
| `waiting-for.md` | Things delegated / waiting on others | Not your own next actions | [Person] + what you're waiting for + agreement + delegated date |
| `calendar.md` | **Only** hard commitments that matter on a specific day / time | Not ordinary to-dos (the calendar is sacred; clutter destroys its trustworthiness) | By date |
| `someday-maybe.md` | Not committed yet, incubating | Not things already committed to | Trigger condition (when it becomes worth starting) |
| `product-ideas.md` | Raw opportunities and assumptions in product, feature, scenario, and opportunity spaces; each should also have project / next-action visibility | Not ordinary life wishes, and not a cold-storage backlog with no next action | Opportunity / user scenario / assumptions / evidence status / promotion criteria / GTD visibility |
| `reference.md` | Non-actionable reference + project support material + knowledge / insight notes | Not actionable items (those go through clarify to next-actions / projects / waiting-for) | Two sections: general reference / project support |
| `horizons.md` | The six Horizons of Focus | Not a task list (it's direction calibration) | Six levels, 50k → runway |

## The boundaries most often violated
1. **Multi-step outcomes stuffed into next-actions** → split: the outcome goes to projects, the first step stays in next-actions.
2. **Ordinary to-dos stuffed into the calendar** → the calendar holds only "must happen on this day / at this time"; everything else goes to next-actions.
3. **Mixing product-ideas and someday** → product opportunities go to `product-ideas.md` and sync to project / next-action; ordinary "maybe someday" goes to `someday-maybe.md`.
4. **Knowledge notes stuffed into actionable lists** → knowledge / insights go to `reference.md`, not `next-actions.md` / `projects.md` (overridable in `personalized.md` if you run a separate knowledge system).
5. **A full task tree stuffed into projects** → keep only current parallel next-action / waiting-for block links; milestones, dependencies, and task trees go to `reference.md` or a project doc.

## Action permissions

| Action | Permission tier | Rule |
|---|---|---|
| Read lists, generate dashboard, generate review prep pack | Read-only | Doesn't change GTD state |
| Append new input to `inbox.md` | Auto | Capture always writes to file first |
| Clarify and file after a single capture | Auto | Ask one question only when action/knowledge, the commitment itself, or the desired outcome is unclear |
| Delete a clarified original item from `inbox.md` | Auto | Must already be written to the target list |
| Move clearly misfiled items | Auto | Append to the target list first, then delete from the original spot |
| Fill in Time / Energy / Constraint | Auto | List as pending confirmation when clearly uncertain |
| Delete a completed next action | Auto | The user explicitly declared it done or there is strong evidence |
| Delete a completed project block | Auto | Desired outcome achieved and no next action still needs pushing |
| Draft a next action for a stalled project | Auto | Act-then-surface; the user can change it in one sentence |
| Activate someday / delete a product idea / cut a project | Needs confirmation | These are commitment decisions; don't settle them automatically |
| Write to the external calendar provider | Conditional auto | Event details complete, no conflict in the target slot, provider reachable; never claim done before the tool succeeds |
| Delete a `calendar.md` fallback item | Conditional auto | Confirmed written to the external calendar, or moved back to another GTD list |
| Send messages, follow up, notify, delegate to others | Needs confirmation | May draft wording; never send automatically |
| approve / reject / withdraw / cc approval | Never auto | Approval Radar may only scan read-only |
| Schedule Engage candidates into the calendar | Needs confirmation | Candidates are a menu, not today's commitments |

## Obsidian link rules

- Pointing to a heading inside a `memory/gtd/` file: use `[[filename#Heading|Heading]]`, e.g. `[[reference#Project support material|Project support material]]`.
- Pointing to a specific action in `next-actions.md` / `waiting-for.md`: prefer a block link, e.g. append `^na-short-id-YYYYMMDD` to the end of the action line, and write one or more `[[next-actions#^na-short-id-YYYYMMDD|Concrete next action]] (constraint: needs computer)` in the project; waiting items are written `[[waiting-for#^wf-short-id-YYYYMMDD|Waiting for someone to deliver something]] (waiting)`.
- Pointing to a real standalone file: only then use a bare `[[filename]]`.
- Don't write in-list headings as bare `[[Heading]]`, or Obsidian will treat it as a new file to be created.
