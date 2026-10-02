---
name: gtd-clarify
description: GTD skill scenario command · Clarify. Runs the decision tree on every inbox item (actionable → do it in 2 minutes / delegate / defer / project; not actionable → trash / someday / reference) and files it. GTD steps 2 + 3 (clarifying includes filing).
parent: gtd-harness
model-tier: balanced
example: "Clarify my inbox"
---


# GTD · clarify (clarify + file)

**Perspective**: David Allen. Clarify is GTD's sharpest step — questioning vague "stuff" item by item until each becomes an actionable conclusion. Most people's to-do systems collapse because their inbox is full of unclarified "stuff" rather than "next actions". Clarifying and filing (organize) usually happen in one motion, so this command also does the filing.

## Loading and boundaries

- List destinations and action permissions: read `references/list-definitions.md` first.
- Vague next action or the standard needs explaining: read `references/clarify-decision-tree.md`.
- Hard landscape / calendar writes: read `references/capability-map.md`.
- Automation boundary: clear items can be filed automatically; ask one question when the commitment itself, the definition of done, or an external-write conflict is unclear.

## When to run
- `inbox.md` has items to clarify (the dashboard flags this).
- The user says "help me sort through my inbox", "where should these to-dos go", "go through these one by one".

## Decision tree (ask for each inbox item)

```
What is it? Is it actionable?
├── No → three destinations:
│   ├── Useless / expired             → Trash
│   ├── Not now, but don't forget     → someday-maybe/ (incubate)
│   └── Reference / support material, or knowledge / ideas → reference/ (or the project's folder)
│
└── Yes → What's the next concrete physical action?
    ├── < 2 minutes          → Do it (two-minute rule), cross it off when done
    ├── Someone else should  → Delegate it → waiting-for/ (record person + agreement + date)
    └── Mine, > 2 minutes    → Defer it:
         ├── Time- / day-specific → hard landscape (calendar): check the target time window first; if no conflict and details are complete, write to the reachable calendar provider; if unreachable or key fields are missing, fall back
         ├── Committed, but can't act until a date → tickler/ (a dated tickle; never someday-maybe or waiting-for)
         └── As soon as possible  → next-actions/ (action pool; state time / energy / context)
    ※ If completion takes >1 step → also create a project folder in projects/ (outcome); its next action goes into next-actions/
    ※ A committed project that can't start until a date → project + a tickle linked to it (on hold, not stalled); see "Filing notes"
```

## Workflow

1. Read `inbox.md` and run the decision tree item by item. One item at a time, no skipping.
2. **Key questions**:
   - "Is it actionable?" — this gate separates action from knowledge (knowledge → `reference/`, not an action list).
   - "What's the next concrete physical action?" — it must be a visible physical action ("Call Colleague A to confirm the data definitions"), not "handle the data". Concrete verbs; reject vague verbs.
   - "What exactly counts as done for this?" — define the **outcome / definition of done** first, then decide whether it goes to `waiting-for`, `next-actions`, `projects`, or can be closed. Don't automatically treat milestones such as "approval passed", "meeting time agreed", or "got a reply" as final completion unless the user defines it that way.
   - "What's this action's time / energy / context?" — only fill in light fields; don't turn lenses into a complex tagging system. The AI estimates by default and asks only when clearly unsure.
3. **Filing**: create one note in the target list per the decision tree — see "Filing notes" below.
   - A product / feature / scenario idea is ordinary input, not its own list: if the user is committed to building it, it is a project (keep the original opportunity, assumptions and evidence in the project README's body) with a next action; if not, someday-maybe; if it's only knowledge, reference.
   - When updating an existing project, if the desired outcome is achieved and no next action still needs pushing → close it through `update/SKILL.md`'s "Project close" (AAR, then the done record); don't write "Next actions: none" or leave a finished project in the active list.
   - **Waiting-for items must state two layers**: `what you're currently waiting for` and `what finally counts as done`. Especially for payment flows, approval flows, legal routing, refunds, and reimbursements, `approval passed / submitted / they replied / technical evaluation started` are often just milestones, not closure. If the final definition of done is "payment received / fully signed / item received / actually scheduled and happened", state it in the waiting-for text or agreement to avoid deleting the item too early.
   - For anything doable in 2 minutes, tell the user "This one takes <2 minutes — I suggest doing it now."
   - **Time-specific items → calendar (hard landscape)**: one-calendar hard rule — when an external calendar provider is reachable, write to it first; only when all are unreachable write the `calendar.md` fallback; **never keep a copy**. Writing to an external calendar is a high-consequence action, but it may be done automatically when event details are complete. Before writing, read the target time slot's hard landscape (read each existing event's availability, not just its title or length — see `references/capability-map.md`'s conflict and capacity judgment); if an event already occupies it or the buffer before/after is too small to keep the commitment, list the conflict and stop, suggesting reschedule, cancel, delegate, or downgrade to next-action/someday. Report "written" only after the external tool returns success; on failure / unreachable, fall back step by step per `references/capability-map.md` and say so honestly — **never misreport**. When key fields such as date, time, or title / subject are missing, ask only for the missing fields; meetings without a duration default to 60 minutes.
4. After filing, **delete the item from the inbox** (once clarified it shouldn't stay in the inbox) — only after its note exists.
5. Not enough information to decide the next action → file it in next-actions as "TBD + what information is missing", or ask the user one question.

## Filing notes

Each filed item becomes one note (see `references/list-definitions.md` "Layout" and "Note formats").

1. **Read the target list's `README.md` first** (e.g. `memory/gtd/next-actions/README.md`) — local rules the user added there apply.
2. **Create one note per item** from that list's template: `templates/next-action-note.md`, `waiting-for-note.md`, `someday-maybe-note.md`, `tickler-note.md`. Filename = a short, verb-first title, filesystem-safe (drop `: / \ ? * " < > |`); if the name exists add ` (2)`, ` (3)`, …; never `README.md`. Fill `id` (`na-` / `wf-` / `sm-` / `tk-` + short id + `YYYYMMDD`), `source`, and `created` (today). Drop the template's HTML comment and any optional property that has no value — never write placeholders. A property that links to a note holds only the quoted link, with any extra detail inside its display text — `source: "[[projects/<Name>/PLAN|plan (Phase 4 step 5)]]"`, never `"[[…|plan]] (Phase 4 step 5)"`, which Obsidian shows as plain text; several links are a YAML list, one quoted link per item (`references/list-definitions.md` "Obsidian link rules").
3. **Next-action properties**: fill the light fields per the "Property values" table in `references/list-definitions.md` — `time` a number of minutes (a range → its upper bound), `energy` one of `low | medium | deep | low-emotional`, `context` only values from that table's list. The concrete action goes in the body; the full free-text constraint (hard location / setting, tool / channel, person present, prep chain, shopping, before a meeting, ID / payment / documents / equipment, etc.) goes on a `Constraint:` line under it. Estimate it yourself; a property you genuinely can't estimate is left out (organize repairs it), never asked about as a "tag". The user never tags anything.
4. **Projects are folders**: a new project is `memory/gtd/projects/<Project name>/README.md` from `templates/project-note.md` (`outcome:` one sentence; drop the empty Decisions / Support material / AAR stubs if there's nothing for them yet, keep `## Next actions` with its embedded view). Each of its actions or waiting-for items gets `project: "[[projects/<Project name>/README|<Project name>]]"`. **Don't write the actions into the README and don't add back-links** — the README's embedded view and `gtd_list.sh --project` find them. An existing project: check `projects/` for its folder before creating another.
5. **Tickler** (committed, but can't act until a date — `references/list-definitions.md` "Tickler"): `tickler/<Verb-first title>.md` with `tickle: YYYY-MM-DD` (when it becomes actionable), `project:` when it belongs to a project, and the body written as the concrete action it will become. A project waiting on a date keeps (or gets) its folder and gets this tickle instead of a next action; it is on hold, not stalled. Never file it in someday-maybe (not committed), waiting-for (nobody owes it), or the calendar (not an appointment).
   - **An inbox pointer to a due tickle** (`- Tickle due: <title> → [[tickler/<title>]]`, added by organize): clarify the **note itself**, not the line — move it to `next-actions/` (drop `tickle`, fill the properties), make it a project, re-date it, move it to `someday-maybe/`, or delete it — then delete the inbox line.
6. **Reference / knowledge**: project-specific support material → a note (or a short section in the README) inside that project's folder; general reference and knowledge → `reference/<Title>.md` at the **workspace root** (not `memory/gtd/`) from `templates/reference-note.md`, unless `personalized.md` redirects the hand-off.
7. **Not clarify's job**: closing a finished project is update's (after-action review, then the whole folder moves to `_done/`) — clarify never deletes a project folder.
8. **Report** each filed item with its note path, e.g. `→ next-actions/Call the dentist to book a cleaning.md (10 min · low · phone)`.

## Clarify rules for session-status input

- A session status is not itself a to-do; first split it into atomic items, then run each through the clarify decision tree.
- New commitments / project blockers → `projects/` + `next-actions/`; waiting on others → `waiting-for/`; meaningful only on a specific day / time → calendar provider / `calendar.md` fallback chain; active-project support material → the project's folder; pure knowledge insights → `reference/`.
- Don't leave a "today's summary / this session's summary" as a single item in `inbox.md` or `reference/`. GTD holds only changes to the commitment system, not a chat log.
- After clarifying, output the fixed five sections from `templates/session-close-template.md`; write "None" for empty sections — never omit them.

## Quality check
- [ ] Every inbox item has a clear destination (one of the six), nothing left over
- [ ] Everything in next-actions is a **concrete physical action** with time / energy / context filled from the fixed vocabulary (nothing asked of the user as a tag)
- [ ] Every >1-step item has a project with a next action, waiting-for item or tickle (nothing stalled; `references/list-definitions.md` "Stalled projects")
- [ ] One note per item in the right folder, the project linked from the note's `project:` field only, general reference at the workspace-root `reference/`
- [ ] Projects whose desired outcome is achieved were handed to update's Project close; no "Next actions: none" left behind
- [ ] Waiting-for items state what/which milestone is currently awaited and when it finally counts as done; no intermediate milestone mistaken for closure
- [ ] Target time slot checked for conflicts before writing a hard appointment; nothing written directly when there was a conflict
- [ ] Knowledge / ideas filed to `reference/`; action lists not polluted
- [ ] Session status split into atomic GTD items, no whole summary stuffed into a list, closed with the fixed five sections
- [ ] Two-minute rule recognized and flagged
- [ ] Committed-but-not-until-a-date items became tickles, not someday-maybe, waiting-for or calendar entries
