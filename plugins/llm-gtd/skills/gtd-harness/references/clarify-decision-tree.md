# Clarify Decision Tree (GTD's sharpest step)

For every inbox item, walk all the way through:

```
What is it?

┌─ Is it actionable?
│
├── No ──┬── Useless / expired ────────────→ 🗑️ Trash
│        ├── Not now, but don't forget ─────→ 💭 someday-maybe.md (incubate)
│        ├── Product / feature / scenario opportunity → 💡 product-ideas.md + 🎯 project + ✅ next-action
│        └── Look up later / support material, or knowledge / insight → 📚 reference.md
│
└── Yes ──→ What's the next concrete physical action?
            (must be a visible, doable physical action; concrete verb — reject "handle / follow up / research")
            │
            ├── < 2 minutes ─────────────→ ⚡ Do it (two-minute rule), cross it off when done
            ├── Someone else should ─────→ ⏳ Delegate it → waiting-for.md (person + agreement + delegated date)
            └── Mine, > 2 minutes → Defer it ─┬── Time- / day-specific → 📅 calendar.md
                                              ├── Committed, but can't act until a date → 🗂️ tickler/ (per-item layout; a dated tickle)
                                              └── As soon as possible  → ✅ next-actions.md (action pool; state Time / Energy / Constraint)

            ※ If the outcome takes > 1 step to complete:
              also create a project in 🎯 projects.md (write the desired outcome), put the currently doable action in next-actions, and link it back to the project with a block link.
              If there are several current actions that don't wait on each other, attach several; don't write sequentially dependent steps as a task tree.
              A committed project that can't start until a date still gets its project, plus a tickle linked to it instead of a next action:
              it is on hold, not stalled, and never goes to someday-maybe (that's for things not committed to) or waiting-for (that's for things someone else owes you).
```

## Why the two questions matter

1. **"Is it actionable?"** — the triage gate. Actions go into GTD's action lists, knowledge goes into `reference.md`. Piling knowledge into next-actions destroys the list's trustworthiness as "all doable actions".

2. **"What's the next concrete physical action?"** — the soul of GTD.
   - ❌ "Data" / "Project X planning" / "Deal with Colleague A's thing" (not actions, just topics)
   - ✅ "Call Colleague A to confirm the data definitions" / "Draft the first three paragraphs of the Project X brief"
   - Test: can you close your eyes and picture yourself doing it? If yes = a valid next action.

## Tickler vs calendar vs someday-maybe

- **Calendar**: it must happen on that day or at that time (an appointment, a deadline, a day-specific action).
- **Tickler**: you're committed, but you can't (or don't want to) act until a date; on the date it becomes a next action. Not an appointment, so it never goes on the external calendar.
- **Someday-maybe**: you haven't committed to it at all. "Reconsider X in March" is a tickle if you're committed to reconsidering it; a someday item if it's only a maybe.
- The tickler exists only in the per-item layout; in the single-file layout, use the calendar for a real date and next-actions or someday-maybe otherwise, as before.

## The logic of the two-minute rule
If the next action takes < 2 minutes, the cost of filing / delegating / recording it is ≥ just doing it. So do it immediately; it never enters the system.
