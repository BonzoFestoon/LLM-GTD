# Note formats

Companion to `list-definitions.md`, which holds the core rules (lists, boundaries, layout, property values, link rules). Read this when writing a note whose shape you need to see; each list's `templates/*-note.md` and folder `README.md` give the same shape in short.

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

**Waiting for**: same shape, with `person`, `delegated`, `follow-up`, and optional `project` instead of `time`/`energy`/`context`.

**Someday / maybe**: adds `trigger` (the condition that makes it worth starting).

**Tickle** (`memory/gtd/tickler/Open the per-bot accounts.md`; format in `templates/tickler-note.md`): `id: tk-<short>-<created YYYYMMDD>` (the creation date, so re-dating never changes it), `tickle: YYYY-MM-DD`, optional `project:` in the same `[[projects/<Name>/README|<Name>]]` form as an action, `source`, `created`; the body says what becomes actionable, as concretely as possible. A recurring tickle adds `every:` and, optionally, `lead:`, `cadence:` and `time` / `energy` / `context`; update writes `last_completed:` (see `references/tickler.md` "Recurring tickles").

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
