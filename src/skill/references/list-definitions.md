# Eight Core Lists Definitions (what it is / what it isn't)

The boundaries of the trusted system. Each list has a single job; mixing in foreign items destroys its trustworthiness.

| List | What it is | What it **isn't** | How it's organized |
|---|---|---|---|
| `inbox.md` | The capture entry point for unclarified items | Not a to-do list (nothing here has been decided yet) | First in, first out |
| `next-actions/` | Action pool of clarified, single-step, doable actions | Not projects, not time-specific items, and not a category system maintained by soft tool tags | One note per action, with light properties: `time` / `energy` / `context` |
| `projects/` | Desired outcomes that take >1 step | Not single-step actions, not vague wishes, not a full task tree | One folder per project: a README with the outcome and an embedded view of its next actions, plus its support material |
| `waiting-for/` | Things delegated / waiting on others | Not your own next actions | One note per item: person + what you're waiting for + agreement + delegated date |
| `calendar.md` | **Only** hard commitments that matter on a specific day / time | Not ordinary to-dos (the calendar is sacred; clutter destroys its trustworthiness) | By date |
| `someday-maybe/` | Not committed yet, incubating | Not things already committed to | One note per item, with a trigger condition (when it becomes worth starting) |
| `tickler/` | Committed things you can't (or don't want to) act on until a date — Allen's tickler; one note per tickle, dated `tickle:` for when it becomes actionable | Not appointments (calendar), not things someone owes you (waiting-for), not uncommitted maybes (someday-maybe); **never exported to the external calendar** | By `tickle` date |
| `reference/` (workspace root) | Non-actionable reference + knowledge / insight notes | Not actionable items (those go through clarify to next-actions / projects / waiting-for) | One note per topic; project support material lives in that project's own folder instead |
| `horizons.md` | The six Horizons of Focus | Not a task list (it's direction calibration) | Six levels, 50k → runway |
| `_done/` | A record of finished commitments: completed next actions, received waiting-for items, finished projects, and cancelled project steps, each with an outcome | Not a list you act from — never read by Engage, never counted as open in the dashboard, never given a stalled/orphan check | Flat done notes plus one `_done/<Project name>/` folder per finished project. See "Done record" below |

## The boundaries most often violated
1. **Multi-step outcomes stuffed into next-actions** → split: the outcome goes to projects, the first step stays in next-actions.
2. **Ordinary to-dos stuffed into the calendar** → the calendar holds only "must happen on this day / at this time"; everything else goes to next-actions.
3. **Giving product ideas a list of their own** → A product / feature / scenario idea is ordinary input, not its own list: if the user is committed to building it, it is a project (keep the original opportunity, assumptions and evidence in the project README's body) with a next action; if not, someday-maybe; if it's only knowledge, reference.
4. **Knowledge notes stuffed into actionable lists** → knowledge / insights go to `reference/`, not `next-actions/` / `projects/` (overridable in `personalized.md` if you run a separate knowledge system).
5. **A full task tree stuffed into projects** → keep only current parallel next actions / waiting-for items; milestones, dependencies, and task trees go in a doc in the project's folder.
6. **A committed project waiting on a date parked in someday-maybe or waiting-for** → it stays a project and gets a tickle: someday-maybe is for what you haven't committed to, waiting-for for what someone else owes you.

## Stalled projects

A project is **in play** when at least one open next action, waiting-for item, or tickle links to it; otherwise it is **stalled**. A tickle means the project is on hold on purpose until its date: it stays in `projects/`, is never called stalled, and organize never drafts a next action for it. A tickle that has come due is organize's to handle (see "Tickler"), not a stalled project. `gtd_check.sh` and the dashboard apply this rule; every other statement of it in the skill points here.

## Layout

One list = one folder of item notes, one commitment per note, with its fields in YAML frontmatter (see "Note formats" below). `next-actions/`, `waiting-for/`, `projects/`, `someday-maybe/`, `tickler/` and `_done/` are folders under `memory/gtd/`; general reference is a `reference/` folder at the workspace root (see "Reference folder"); `inbox.md`, `calendar.md`, `horizons.md`, and `personalized.md` are single files (the inbox must stay one-line capture from anywhere, and the others are documents, not item lists). Set up with `gtd_init.sh --confirm-create` (optionally `--with-bases`).

- **No single-file lists.** LLM-GTD 1.x could also keep each list as one `.md` file (`next-actions.md`, `projects.md`, …). Since 2.0.0 every script refuses a `memory/gtd/` that still holds those files (exit 4), because their items would be invisible to every command; migrate with LLM-GTD 1.17.x's `gtd_migrate_to_notes.sh` first.
- **Filenames.** A short, verb-first title, made filesystem-safe (no `: / \ ? * " < > |`), with `(2)`, `(3)`, … appended on a collision.
- **List README files.** Every list folder, plus `_done/`, gets a `README.md` holding the list's title, the rules for what belongs there and what doesn't, and its note format. **`README.md` is never an item** — `gtd_list.sh`, the status/review scripts, organize's checks (`gtd_check.sh`), and every Bases view skip it by name. Before creating, moving, or repairing a note in a list, read that list's `README.md` first: local rules the user added there apply; general rules still live in this file.
- **Project folders.** A project is a folder, not a single note: `memory/gtd/projects/<Project name>/README.md` holds the outcome, decisions, and an embedded next-actions view (see "Note formats"); any project-specific support material — plan docs, design notes, phase write-ups — lives as ordinary files directly inside that same folder, linked from the README with a bare `[[filename]]`.
- **Reference folder.** General reference is `reference/<Title>.md` **at the workspace root, outside `memory/gtd/`** — one plain note per topic (no id/type/pipeline scaffolding), found by title or full-text search. It is the general knowledge repository: GTD files into it, but it is not GTD state, so `memory/gtd/` holds only GTD-native lists. Project-specific support material lives in the project's own folder; when a project closes, you decide whether it is worth keeping.
- **Plain files.** Frontmatter is plain YAML in markdown; scripts and non-Obsidian agents can read it with no adaptation. `.base` files are an optional Obsidian extra, never required.

## Note formats

The properties are light fields — Time / Energy / Constraint / Project / Source / Date / Due — and a note with no properties is still a valid action. Clarify fills them; organize repairs missing or invalid ones; the user never has to tag anything.

**Next action** (`memory/gtd/next-actions/Pay property taxes online.md`):

```markdown
---
id: na-proptax-20260926
time: 10            # minutes, number
energy: low         # low | medium | deep | low-emotional
context: [computer] # real constraints: computer, phone, errands, home, person-present, prep-chain, payment, documents…
project: "[[projects/Photos merged into one Google account/README|Photos merged into one Google account]]"   # optional
due: 2026-10-31     # optional, only for real deadlines
source: inbox capture
created: 2026-09-26
---
Pay the property taxes online (find the county tax bill/portal first).
Constraint: needs computer, tax bill / account number, payment method.
```

The body keeps the full concrete action text and the free-text constraint; `context` holds only the lens values Engage already uses.

**Property values** (`scripts/gtd_check.sh` checks notes against this table, so change both together):

| Property | Values | Notes |
|---|---|---|
| `time` | a number of minutes | `2` / `10` / `30`; a range records its upper bound (`60-90 min` → `90`), so a lens never offers an action that won't fit the window |
| `energy` | `low` \| `medium` \| `deep` \| `low-emotional` | low energy / medium energy / deep work / low emotional load |
| `context` | a list drawn from: `computer`, `phone`, `errands`, `home`, `person-present`, `before-meeting`, `prep-chain`, `payment`, `documents`, `equipment` | The hard constraints (shopping and on-the-way errands → `errands`; ID → `documents`; something to raise with someone → `person-present`, the person in the body). Anything that doesn't map stays in the body's `Constraint:` line only |
| `due` | `YYYY-MM-DD` | Only a real deadline |
| `created` | `YYYY-MM-DD` | The day it was clarified |
| `tickle` | `YYYY-MM-DD` | Tickler only — the date the tickle becomes actionable |

**Waiting for**: same shape, with `person`, `delegated`, `follow-up`, and optional `project` instead of `time`/`energy`/`context`.

**Someday / maybe**: adds `trigger` (the condition that makes it worth starting).

**Tickle** (`memory/gtd/tickler/Open the per-bot accounts.md`; format in `templates/tickler-note.md`): `id: tk-<short>-<created YYYYMMDD>` (the creation date, so re-dating never changes it), `tickle: YYYY-MM-DD`, optional `project:` in the same `[[projects/<Name>/README|<Name>]]` form as an action, `source`, `created`; the body says what becomes actionable, as concretely as possible.


**Project** (`memory/gtd/projects/Tastytrade broker service/README.md`):

```markdown
---
id: proj-tastytrade-service-20260925
outcome: A tastytrade service runs alongside the Schwab service behind one broker-neutral service contract.
source: inbox capture
created: 2026-09-25
---
A tastytrade service runs alongside the Schwab service behind one broker-neutral
service contract, so bots choose a broker by name and adding IBKR later needs no
caller changes.

## Decisions
- 20260925: the service is the abstraction (neutral wire contract, one service per
  broker), not a domain-level `AbstractBroker` with per-broker clients.

## Next actions
![[next-actions.base#For this project]]

## Support material
- [[Phase 0 findings]]

## After action review
(added once the outcome is achieved; see `templates/after-action-review.md`)
```

The README never lists actions by hand — it embeds the `For this project` view (action notes whose `project:` links to this README), computed live from the action notes, so there is one source of truth and no two-way link to go stale. Actions and waiting-for items link to the project as `project: "[[projects/<Project name>/README|<Project name>]]"` — a bare `[[projects/<Project name>]]` would not resolve, because the project is a folder. Without Obsidian, `gtd_list.sh next-actions --project "<Project name>"` gives the same list.

**Reference note** (`reference/gridv3 market-open clock fix.md`, workspace root):

```markdown
---
source: trading-suite repo, commit 4dcd438 on main
created: 2026-09-27
---
`tests/unit/test_gridv3_loop.py` had 30 tests that failed whenever the real wall
clock was a weekend or outside trading hours...
```

## Tickler

A tickle holds a commitment until its date; the project it links stays in `projects/`, on hold (see "Stalled projects").

- **Filing**: clarify files "committed, but can't act until a date" here (see `clarify-decision-tree.md`), never in someday-maybe or waiting-for, and never in the calendar unless it is a real appointment.
- **When the date arrives** (`gtd_list.sh tickler --due`, `gtd_check.sh` `tickler-due`): organize moves a project tickle whose body is a concrete action into `next-actions/` (drop `tickle`, fill time / energy / context, keep `project:`). Any other due tickle — standalone, or too vague to be an action — gets an **inbox pointer**: one line `- Tickle due: <title> → [[tickler/<title>]] · Captured: YYYYMMDD`, with the note left in place so nothing in its body is lost; clarify then works on the note itself (move it to `next-actions/`, make it a project, re-date it, move it to `someday-maybe/`, or delete it) and removes the line. While the inbox links the note, `gtd_check.sh` reports it as "queued in inbox" and organize does not queue it again. Engage lists due tickles first.
- **Calendar conflicts**: a tickle dated on a day the hard landscape shows as blocked is flagged (rule in `capability-map.md`), never re-dated automatically.
- **Always local**: the tickler is not part of the calendar adapter or its fallback chain; nothing in it is ever written to an external calendar provider, and organize's `calendar.md` reconcile never touches it.
- **Changes**: "the date moved" re-dates `tickle` (id unchanged); a cancelled tickle is deleted (no done record); cancelling or closing a project removes or resolves its tickles first — a project with an open tickle is not closed.

## Done record

Completed next actions, received waiting-for items, finished projects, and cancelled project steps move to `_done/` with an outcome: what was done, what problems came up and how they were solved. This replaces deleting the item outright — the active lists still hold only open commitments, and the done record is the raw material for the Weekly Review's "done since last review" section and each project's after-action review (AAR). A cancelled *standalone* action, or a someday item you drop, is still simply deleted — only project-linked work is worth keeping a record of. `_done/` is never read by Engage, never counted as open, and never checked for orphans/stalled status.

- **Shape**: a finished action or waiting-for item is a flat `_done/<Title>.md` that keeps its filename, properties and body, and gains `completed`, `result` (done | cancelled), `list` and a `## Outcome` section (`Done:` / `Problems and fixes:` / `Links:`). A finished project moves as its whole folder to `_done/<Project name>/`: the README gains the same three properties plus its after-action review, the support material you chose to keep stays beside it, and every link to `projects/<Project name>/…` is rewritten to `_done/<Project name>/…`.
- **Reading it**: only `gtd_list.sh done [--since DATE] [--project P] [--problems]`, the Weekly Review, and the AAR read the done record.

The five-heading AAR shape (intended outcome · what happened · problems and how they were overcome · what to do the same or differently next time · reusable how-tos) is in `templates/after-action-review.md`; the close steps are `update/SKILL.md`'s "Project close".

## Action permissions

| Action | Permission tier | Rule |
|---|---|---|
| Read lists, generate dashboard, generate review prep pack | Read-only | Doesn't change GTD state |
| Append new input to `inbox.md` | Auto | Capture always writes to file first |
| Clarify and file after a single capture | Auto | Ask one question only when action/knowledge, the commitment itself, or the desired outcome is unclear |
| Delete a clarified original item from `inbox.md` | Auto | Its note must already exist in the target list |
| Move clearly misfiled items | Auto | Create the note in the target list first, then delete it from the original spot |
| Fill in time / energy / context | Auto | List as pending confirmation when clearly uncertain |
| Delete a cancelled standalone action or a dropped someday item | Auto | The user explicitly cancelled it; project-linked work goes to the done record as `cancelled` instead |
| Draft a next action for a stalled project | Auto | Act-then-surface; the user can change it in one sentence. Never for a project on hold (a tickle links it) |
| Turn a due tickle into a next action, or add an inbox pointer to it | Auto | A concrete project tickle moves to `next-actions/`, anything else is queued in the inbox once; reported in organize's one-line summary |
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

## Obsidian link rules

- A next action, waiting-for item, tickle or someday item is a real file, so it's linked directly — `[[next-actions/<Title>|Concrete next action]]`, `[[tickler/<Title>|…]]`.
- A project is linked from an action's `project:` frontmatter field (and from anywhere else) as `[[projects/<Project name>/README|<Project name>]]`; a general reference note as `[[reference/<Title>|<Title>]]`; a project's own support doc, from inside its folder, as a bare `[[filename]]`.
- A list itself is linked through its README, e.g. `[[projects/README|projects]]` in `horizons.md` — Obsidian resolves the path, so having several `README` files across folders is not ambiguous.
- Pointing to a heading inside a file: use `[[filename#Heading|Heading]]`. Don't write a heading as a bare `[[Heading]]`, or Obsidian will treat it as a new file to be created.
- A wikilink in a frontmatter property must be the property's whole value, quoted: `project: "[[projects/<Name>/README|<Name>]]"`. Anything else is plain text in Obsidian, not a link: text before or after the link (inside or outside the quotes), two links in one value, or an unquoted `[[…]]` (YAML reads it as a nested list).
  - Extra detail goes inside the link's display text: `source: "[[projects/<Name>/PLAN|plan (Phase 4 step 5)]]"`, not `source: "[[projects/<Name>/PLAN|plan]] (Phase 4 step 5)"`.
  - Several links are a YAML list, one quoted link per item: `related:` then `  - "[[reference/A|A]]"` and `  - "[[reference/B|B]]"` on their own lines.
  - `gtd_check.sh` reports any other shape as `link-form`, in any note under `memory/gtd/`; links in a note's body are free text and never checked.
