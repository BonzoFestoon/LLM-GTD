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
| `tickler/` | Committed things you can't (or don't want to) act on until a date — Allen's tickler; one note per tickle, dated `tickle:` for when it becomes actionable. A tickle with `every:` is a recurring routine that stays here and creates a next action each cycle | Not appointments (calendar), not things someone owes you (waiting-for), not uncommitted maybes (someday-maybe); **never exported to the external calendar** | By `tickle` date |
| `reference/` (workspace root) | Non-actionable reference + knowledge / insight notes | Not actionable items (those go through clarify to next-actions / projects / waiting-for) | One note per topic; project support material lives in that project's own folder instead |
| `horizons.md` | The six Horizons of Focus | Not a task list (it's direction calibration) | Six levels, 50k → runway |
| `_done/` | A record of finished commitments: completed next actions, received waiting-for items, finished projects, and cancelled project steps, each with an outcome | Not a list you act from — never read by Engage, never counted as open in the dashboard, never given a stalled/orphan check | Flat done notes plus one `_done/<Project name>/` folder per finished project. See `references/done-record.md` |

## The boundaries most often violated
1. **Multi-step outcomes stuffed into next-actions** → split: the outcome goes to projects, the first step stays in next-actions.
2. **Ordinary to-dos stuffed into the calendar** → the calendar holds only "must happen on this day / at this time"; everything else goes to next-actions.
3. **Giving product ideas a list of their own** → A product / feature / scenario idea is ordinary input, not its own list: if the user is committed to building it, it is a project (keep the original opportunity, assumptions and evidence in the project README's body) with a next action; if not, someday-maybe; if it's only knowledge, reference.
4. **Knowledge notes stuffed into actionable lists** → knowledge / insights go to `reference/`, not `next-actions/` / `projects/` (overridable in `personalized.md` if you run a separate knowledge system).
5. **A full task tree stuffed into projects** → keep only current parallel next actions / waiting-for items; milestones, dependencies, and task trees go in a doc in the project's folder.
6. **A committed project waiting on a date parked in someday-maybe or waiting-for** → it stays a project and gets a tickle: someday-maybe is for what you haven't committed to, waiting-for for what someone else owes you.

## Stalled projects

A project is **in play** when at least one open next action, waiting-for item, or one-shot tickle links to it; otherwise it is **stalled**. A one-shot tickle means the project is on hold on purpose until its date: it stays in `projects/`, is never called stalled, and organize never drafts a next action for it. A **recurring** tickle (`every:`) never puts a project on hold — a project whose only link is a standing routine is still stalled, though the routine's open action, once created, counts like any other action. A tickle that has come due is organize's to handle (see `references/tickler.md`), not a stalled project. `gtd_check.sh` and the dashboard apply this rule; every other statement of it in the skill points here.

## Layout

One list = one folder of item notes, one commitment per note, with its fields in YAML frontmatter (see "Note formats" below). `next-actions/`, `waiting-for/`, `projects/`, `someday-maybe/`, `tickler/` and `_done/` are folders under `memory/gtd/`; general reference is a `reference/` folder at the workspace root (see "Reference folder"); `inbox.md`, `calendar.md`, `horizons.md`, and `personalized.md` are single files (the inbox must stay one-line capture from anywhere, and the others are documents, not item lists). Set up with `gtd_init.sh --confirm-create` (optionally `--with-bases`).

- **No single-file lists.** LLM-GTD 1.x could also keep each list as one `.md` file (`next-actions.md`, `projects.md`, …). Since 2.0.0 every script refuses a `memory/gtd/` that still holds those files (exit 4), because their items would be invisible to every command; migrate with LLM-GTD 1.17.x's `gtd_migrate_to_notes.sh` first.
- **Filenames.** A short, verb-first title, made filesystem-safe (no `: / \ ? * " < > |`), with `(2)`, `(3)`, … appended on a collision.
- **List README files.** Every list folder, plus `_done/`, gets a `README.md` holding the list's title, the rules for what belongs there and what doesn't, and its note format. **`README.md` is never an item** — `gtd_list.sh`, the status/review scripts, organize's checks (`gtd_check.sh`), and every Bases view skip it by name. Before creating, moving, or repairing a note in a list, read that list's `README.md` first: local rules the user added there apply; general rules still live in this file.
- **Project folders.** A project is a folder, not a single note: `memory/gtd/projects/<Project name>/README.md` holds the outcome, decisions, and an embedded next-actions view (see `references/note-formats.md`); any project-specific support material — plan docs, design notes, phase write-ups — lives as ordinary files directly inside that same folder, linked from the README with a bare `[[filename]]`.
- **Reference folder.** General reference is `reference/<Title>.md` **at the workspace root, outside `memory/gtd/`** — one plain note per topic (no id/type/pipeline scaffolding), found by title or full-text search. It is the general knowledge repository: GTD files into it, but it is not GTD state, so `memory/gtd/` holds only GTD-native lists. Project-specific support material lives in the project's own folder; when a project closes, you decide whether it is worth keeping.
- **Plain files.** Frontmatter is plain YAML in markdown; scripts and non-Obsidian agents can read it with no adaptation. `.base` files are an optional Obsidian extra, never required.

## Note formats

The properties are light fields — Time / Energy / Constraint / Project / Source / Date / Due — and a note with no properties is still a valid action. Clarify fills them; organize repairs missing or invalid ones; the user never has to tag anything. Worked examples of each note (next action, waiting for, someday, tickle, project, reference): `references/note-formats.md`; the list's `templates/*-note.md` has the same shape in short.

**Property values** (`scripts/gtd_check.sh` checks notes against this table, so change both together):

| Property | Values | Notes |
|---|---|---|
| `time` | a number of minutes | `2` / `10` / `30`; a range records its upper bound (`60-90 min` → `90`), so a lens never offers an action that won't fit the window |
| `energy` | `low` \| `medium` \| `deep` \| `low-emotional` | low energy / medium energy / deep work / low emotional load |
| `context` | a list drawn from: `computer`, `phone`, `errands`, `home`, `person-present`, `before-meeting`, `prep-chain`, `payment`, `documents`, `equipment` | The hard constraints (shopping and on-the-way errands → `errands`; ID → `documents`; something to raise with someone → `person-present`, the person in the body). Anything that doesn't map stays in the body's `Constraint:` line only |
| `due` | `YYYY-MM-DD` | Only a real deadline |
| `created` | `YYYY-MM-DD` | The day it was clarified |
| `tickle` | `YYYY-MM-DD` | Tickler only — the date the tickle becomes actionable (recurring: the date it is due again) |
| `every` | `<n><unit>`, unit `d` \| `w` \| `m` \| `y` | Tickler only — makes the tickle recurring (`7d`, `2w`, `3m`, `1y`); "at least quarterly" is `3m`. Absent = one-shot |
| `lead` | `<n><unit>`, as `every` | Recurring tickle only — create the cycle's action this long before `tickle` |
| `cadence` | `fixed` \| `floating` | Recurring tickle only — absent = `fixed` (the next schedule date after the completion); `floating` = completion + `every` |
| `last_completed` | `YYYY-MM-DD` | Recurring tickle only — written by update on each completion |
| `from` | `"[[tickler/<Title>\|<Title>]]"` | Next action only — the recurring tickle this action is one cycle of (written by organize) |

A tickle may also carry `time` / `energy` / `context` (same values as a next action); they are carried into the action it creates.

## Tickler

Tickles, recurring tickles and their dates, completion, skip / pause / end: `references/tickler.md`. Read it whenever a tickle is filed, comes due, is re-dated or completed.

## Tagged-note updates

The `gtd-update` tag and `## Update` section format, and how they are applied: `references/tagged-updates.md`.

## Done record

Finished work moves to `_done/` with an outcome instead of being deleted; never read by Engage, never counted as open. Shape, recurring cycles and who reads it: `references/done-record.md`.

## Action permissions

What runs automatically, what needs one confirmation, what never happens: `references/action-permissions.md`. Read it before deleting, moving, sending, or deciding anything on the user's behalf.

## Obsidian link rules

- A next action, waiting-for item, tickle or someday item is a real file, so it's linked directly — `[[next-actions/<Title>|Concrete next action]]`, `[[tickler/<Title>|…]]`.
- A project is linked from an action's `project:` frontmatter field (and from anywhere else) as `[[projects/<Project name>/README|<Project name>]]`; a general reference note as `[[reference/<Title>|<Title>]]`; a project's own support doc, from inside its folder, as a bare `[[filename]]`.
- A list itself is linked through its README, e.g. `[[projects/README|projects]]` in `horizons.md` — Obsidian resolves the path, so having several `README` files across folders is not ambiguous.
- Pointing to a heading inside a file: use `[[filename#Heading|Heading]]`. Don't write a heading as a bare `[[Heading]]`, or Obsidian will treat it as a new file to be created.
- A link to a note inside `memory/gtd/` uses its path relative to `memory/gtd/` — `[[projects/…]]`, `[[next-actions/…]]`, `[[tickler/…]]` — never the path from the vault root (`[[memory/gtd/projects/…]]`), from any note, including `reference/`. `gtd_check.sh` reports a frontmatter link written from the vault root as `link-form`, with the short form.
- A wikilink in a frontmatter property must be the property's whole value, quoted: `project: "[[projects/<Name>/README|<Name>]]"`. Anything else is plain text in Obsidian, not a link: text before or after the link (inside or outside the quotes), two links in one value, or an unquoted `[[…]]` (YAML reads it as a nested list). A whole quoted embed, `cover: "![[image.png]]"`, follows the same rule.
  - Extra detail goes inside the link's display text: `source: "[[projects/<Name>/PLAN|plan (Phase 4 step 5)]]"`, not `source: "[[projects/<Name>/PLAN|plan]] (Phase 4 step 5)"`. (An embed's display text sets its size, so detail beside an embed goes in another property.)
  - Several links are a YAML list, one quoted link per item: `related:` then `  - "[[reference/A|A]]"` and `  - "[[reference/B|B]]"` on their own lines.
  - `gtd_check.sh` reports any other shape as `property-link`, in any note under `memory/gtd/` or the workspace-root `reference/`; links in a note's body are free text and never checked.
