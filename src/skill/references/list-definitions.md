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
| `reference.md` | Non-actionable reference + project support material + knowledge / insight notes | Not actionable items (those go through clarify to next-actions / projects / waiting-for) | Two sections: general reference / project support (per-item layout: workspace-root `reference/` notes + each project's own folder) |
| `horizons.md` | The six Horizons of Focus | Not a task list (it's direction calibration) | Six levels, 50k → runway |
| `_done/` (per-item) / `done.md` (single-file) | A record of finished commitments: completed next actions, received waiting-for items, finished projects, and cancelled project steps, each with an outcome | Not a list you act from — never read by Engage, never counted as open in the dashboard, never given a stalled/orphan check | Per-item: flat done notes plus one `_done/<Project name>/` folder per finished project; single-file: `done.md`, one `## YYYY-MM-DD` heading per completion date, newest last. See "Done record" below |

## The boundaries most often violated
1. **Multi-step outcomes stuffed into next-actions** → split: the outcome goes to projects, the first step stays in next-actions.
2. **Ordinary to-dos stuffed into the calendar** → the calendar holds only "must happen on this day / at this time"; everything else goes to next-actions.
3. **Mixing product-ideas and someday** → product opportunities go to `product-ideas.md` and sync to project / next-action; ordinary "maybe someday" goes to `someday-maybe.md`.
4. **Knowledge notes stuffed into actionable lists** → knowledge / insights go to `reference.md`, not `next-actions.md` / `projects.md` (overridable in `personalized.md` if you run a separate knowledge system).
5. **A full task tree stuffed into projects** → keep only current parallel next-action / waiting-for block links; milestones, dependencies, and task trees go to `reference.md` or a project doc.

## Layouts

Two layouts hold the same eight lists and the same rules; only the storage shape differs.

- **Single-file (default).** One list = one `.md` file, as the table above describes. Every skill in this package works this way unless per-item mode is detected.
- **Per-item (opt-in).** One list = one folder of item notes, one commitment per note, with the same fields as the single-file item line moved into YAML frontmatter (see "Note formats" below). `next-actions/`, `waiting-for/`, `projects/`, `someday-maybe/`, and `product-ideas/` become folders under `memory/gtd/`, plus `_done/`; `reference.md` is replaced by a `reference/` folder at the workspace root (see "Reference folder"); `inbox.md`, `calendar.md`, `horizons.md`, and `personalized.md` always stay single files (the inbox must stay one-line capture from anywhere, and the others are documents, not item lists). Set up with `gtd_init.sh --confirm-create --layout notes` (optionally `--with-bases`); init never switches an existing layout — that is the migration script's job.
- **Layout detection.** Per-item mode if `memory/gtd/next-actions/` exists as a directory, otherwise single-file. An optional `GTD_LAYOUT=notes|files` override is read by `gtd_env.sh` for testing or forcing a mode.
- **Filenames.** A short, verb-first title, made filesystem-safe (no `: / \ ? * " < > |`), with `(2)`, `(3)`, … appended on a collision. The old block id (`^na-…`, `^wf-…`) is kept as the note's `id:` field so existing links stay traceable during migration.
- **List README files.** Every folder-backed list, plus `_done/`, gets a `README.md` holding what used to sit at the top of the single-file list: the title, the rules for what belongs there and what doesn't, the item format, and (for `next-actions/`) a note per legacy `@computer/@calls/@errands/@home/@agenda` group and the `context` value it now maps to. **`README.md` is never an item** — `gtd_list.sh`, the status/review scripts, organize's checks (`gtd_check.sh`), and every Bases view skip it by name. Before creating, moving, or repairing a note in a list, read that list's `README.md` first, the same way earlier skills read the top of the single-file list; general rules still live in this file.
- **Project folders.** A project is a folder, not a single note: `memory/gtd/projects/<Project name>/README.md` holds the outcome, decisions, and an embedded next-actions view (see "Note formats"); any project-specific support material — plan docs, design notes, phase write-ups — lives as ordinary files directly inside that same folder, linked from the README with a bare `[[filename]]`.
- **Reference folder.** `reference.md`'s two sections split: project-specific support material moves into each project's own folder; general reference becomes `reference/<Title>.md` **at the workspace root, outside `memory/gtd/`** — one plain note per topic (no id/type/pipeline scaffolding), found by title or full-text search. It is the general knowledge repository: GTD files into it, but it is not GTD state, so `memory/gtd/` holds only GTD-native lists. When a project closes, you decide whether its folder's support material is worth keeping.
- **Both layouts stay plain files.** Frontmatter is plain YAML in markdown; scripts and non-Obsidian agents can read it with no adaptation. `.base` files are an optional Obsidian extra, never required.

## Note formats (per-item layout)

The properties are exactly the fields a single-file item already carries (Time / Energy / Constraint / Project / Source / Date / Due) — no new vocabulary, and a note with no properties is still a valid action. Clarify fills them; organize repairs missing or invalid ones; the user never has to tag anything.

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

**Property values** (the single-file light fields, converted — no new vocabulary; `scripts/gtd_check.sh` checks notes against this table, so change both together):

| Property | Values | From the single-file field |
|---|---|---|
| `time` | a number of minutes | `Time: 2 min / 10 min / 30 min` → `2` / `10` / `30`; a range records its upper bound (`60-90 min` → `90`), so a lens never offers an action that won't fit the window |
| `energy` | `low` \| `medium` \| `deep` \| `low-emotional` | `low energy` / `medium energy` / `deep work` / `low emotional load` |
| `context` | a list drawn from: `computer`, `phone`, `errands`, `home`, `person-present`, `before-meeting`, `prep-chain`, `payment`, `documents`, `equipment` | The hard constraints in `Constraint:` (shopping and on-the-way errands → `errands`; ID → `documents`); legacy `@computer/@calls/@errands/@home/@agenda` → `computer`/`phone`/`errands`/`home`/`person-present`. Anything that doesn't map stays in the body's `Constraint:` line only |
| `due` | `YYYY-MM-DD` | `Due:` — only a real deadline |
| `created` | `YYYY-MM-DD` | `Date: YYYYMMDD` |

**Waiting for**: same shape, with `person`, `delegated`, `follow-up`, and optional `project` instead of `time`/`energy`/`context`.

**Someday / maybe**: adds `trigger` (the condition that makes it worth starting).

**Product idea**: adds `evidence` and `promotion` (criteria), with project and next-action links kept in the body — the "GTD visibility" rule is unchanged.

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

The README never lists actions by hand — it embeds the `For this project` view (action notes whose `project:` links to this README), computed live from the action notes, so there is one source of truth instead of the two-way block links the single-file layout uses. Actions and waiting-for items link to the project as `project: "[[projects/<Project name>/README|<Project name>]]"` — a bare `[[projects/<Project name>]]` would not resolve, because the project is a folder. Without Obsidian, `gtd_list.sh next-actions --project "<Project name>"` gives the same list.

**Reference note** (`reference/gridv3 market-open clock fix.md`, workspace root):

```markdown
---
source: trading-suite repo, commit 4dcd438 on main
created: 2026-09-27
---
`tests/unit/test_gridv3_loop.py` had 30 tests that failed whenever the real wall
clock was a weekend or outside trading hours...
```

## Done record

Completed next actions, received waiting-for items, finished projects, and cancelled project steps move to `_done/` (per-item) or `done.md` (single-file, one line per item under its completion date) with an outcome: what was done, what problems came up and how they were solved. This replaces deleting the item outright — the active lists still hold only open commitments, and the done record is the raw material for the Weekly Review's "done since last review" section and each project's after-action review (AAR). A cancelled *standalone* action, or a someday item you drop, is still simply deleted — only project-linked work is worth keeping a record of. `_done/` and `done.md` are never read by Engage, never counted as open, and never checked for orphans/stalled status.

- **Per-item shape**: a finished action or waiting-for item is a flat `_done/<Title>.md` that keeps its filename, properties and body, and gains `completed`, `result` (done | cancelled), `list` and a `## Outcome` section (`Done:` / `Problems and fixes:` / `Links:`). A finished project moves as its whole folder to `_done/<Project name>/`: the README gains the same three properties plus its after-action review, the support material you chose to keep stays beside it, and every link to `projects/<Project name>/…` is rewritten to `_done/<Project name>/…`.
- **Single-file shape**: `done.md` (header and line format in `templates/done-log.md`), one `- [x] … · From: <list> · Result: … ^id` line per item under its completion date, with `Done:` / `Problems and fixes:` sub-bullets; a finished project is a `- [x] Project: <Name> — <outcome>` line with its AAR as sub-bullets.
- **Reading it**: only `gtd_list.sh done [--since DATE] [--project P] [--problems]`, the Weekly Review, and the AAR read the done record.

The five-heading AAR shape (intended outcome · what happened · problems and how they were overcome · what to do the same or differently next time · reusable how-tos) is in `templates/after-action-review.md`; the close steps are `update/SKILL.md`'s "Project close".

## Action permissions

| Action | Permission tier | Rule |
|---|---|---|
| Read lists, generate dashboard, generate review prep pack | Read-only | Doesn't change GTD state |
| Append new input to `inbox.md` | Auto | Capture always writes to file first |
| Clarify and file after a single capture | Auto | Ask one question only when action/knowledge, the commitment itself, or the desired outcome is unclear |
| Delete a clarified original item from `inbox.md` | Auto | Must already be written to the target list |
| Move clearly misfiled items | Auto | Append to the target list first, then delete from the original spot |
| Fill in Time / Energy / Constraint | Auto | List as pending confirmation when clearly uncertain |
| Delete a cancelled standalone action or a dropped someday item | Auto | The user explicitly cancelled it; project-linked work goes to the done record as `cancelled` instead |
| Draft a next action for a stalled project | Auto | Act-then-surface; the user can change it in one sentence |
| Move a completed item to `_done/` / `done.md` with its outcome | Auto | The user explicitly declared it done or there is strong evidence; act-then-surface; never blocks on the outcome text, never re-asked later |
| Close a finished project into the done record | Auto after the AAR confirmation | Desired outcome achieved and no open action still linked; the AAR confirm / edit / skip is the one confirmation |
| Draft a project after-action review | Auto | Act-then-surface when the project's outcome is achieved; the user confirms, edits, or skips in one step |
| File AAR how-tos and insights to reference (project folder or `reference/`) | Needs confirmation, once | Offered together with the AAR draft, not as a separate interruption |
| Trim `_done/` / `done.md` | Needs confirmation | Off by default; only runs if enabled in `personalized.md` |
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
- **Per-item layout only:** a next action or waiting-for item is a real file, so it's linked directly — `[[next-actions/<Title>|Concrete next action]]` — not with a block link. A project is linked from an action's `project:` frontmatter field (and from anywhere else) as `[[projects/<Project name>/README|<Project name>]]`; a general reference note as `[[reference/<Title>|<Title>]]`. A bare link to a list file, such as today's `[[projects]]` or `[[next-actions]]` in `horizons.md`, becomes `[[projects/README|projects]]` — Obsidian resolves the path, so having several `README` files across folders is not ambiguous.
