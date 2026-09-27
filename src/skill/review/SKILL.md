---
name: gtd-review
description: GTD skill scenario command · Weekly Review (the critical success factor). The AI first builds a review prep pack, then does Get Clear / Get Current / Get Creative + a Horizons vertical-focus check + a three-ring balance horizontal check (Laura Vanderkam). GTD step 4, Reflect.
parent: gtd-harness
model-tier: strongest
example: "Help me do my weekly review"
---


# GTD · review (Weekly Review / Reflect)

**Perspective**: in David Allen's words — "The Weekly Review is the critical success factor." Without it the other steps all collapse, and within two weeks the system loses trust and you fall back to anxiety in your head. The review isn't about catching up on work; it's **maintaining trust in the system**.

## Loading and boundaries

- Review steps: read `references/weekly-review-checklist.md`.
- List boundaries / delete / move permissions: read `references/list-definitions.md`.
- Hard landscape / capacity judgment: read `references/capability-map.md`.
- Horizons conflicts or priority judgment: read `references/horizons-of-focus.md`.
- Automation boundary: preprocessing and mechanical hygiene may be automatic; deleting uncertain items, cutting projects, and fixing next week's 3 things need user confirmation.

## When to run
- Once a week at a fixed time (Friday suggested; cadence in `references/weekly-review-checklist.md`).
- The user says "do my weekly review", "weekly retro", "go through my system", "weekly review".
- The system feels messy / untrustworthy — that is exactly the signal to review.

## Boundary: the AI does the grunt work, the user makes commitment decisions

The review isn't about making the user dig through the lists again. The AI should prepare the system check-up, mechanical cleanup, candidate actions, and message drafts as fully as possible, then surface only the few points that need the user's judgment.

| AI does by default | User must confirm |
|---|---|
| Run the dashboard / review prep pack; scan inbox, next-actions, projects, waiting-for, someday, product ideas, horizons; audit whether every product idea has project / next-action visibility | Deleting uncertain items, cutting projects, activating someday items, advancing a product idea to PRD / downgrading / deleting, fixing next week's 3 things |
| Call organize for mechanical hygiene: wrong contexts, duplicates, stale checkmarks, obvious orphans, stalled detection | Writing to the calendar, sending messages, notifying / delegating to others, any high-consequence action |
| Draft next actions for stalled projects; draft neutral follow-up messages for waiting-for; propose candidates for next week's focus | Deciding for the user when facts conflict, sources are unclear, or risk is high |

Principle: **preprocessing can be automatic; commitment decisions are not.** What the user sees should be a "system check-up report awaiting confirmation", not a pile of raw lists.

## 0. AI review prep pack (always first)

- Run `scripts/gtd_review_prep.sh` to generate a read-only review prep pack: overall counts, inbox summary, stalled projects, waiting-for, vague next actions, someday candidates, product ideas visibility audit, confirmation queue.
- Read the external calendar provider (preferred if reachable); only if all are unreachable, read the `calendar.md` fallback and note it may be incomplete.
- Do a capacity scan of next week's hard landscape: which days are already full of hard appointments, which focus items lack an available time window; only suggest renegotiating commitments — never automatically cram next-actions into the calendar. Read each event's availability, not just its title or length, before counting it as filling a day (`references/capability-map.md`'s conflict and capacity judgment).
- Call the mechanical hygiene flow in `organize/SKILL.md`: fix what can be fixed automatically; batch-list what needs a decision.
- Compress the review into 3 kinds of output:
  - **Handled automatically**: mechanical cleanup, dedupe, drafts, filing.
  - **Suggested for confirmation**: delete / activate / cut project / add next action / follow up.
  - **Next week's candidates**: the 3 focus items the AI suggests + reasons.

## Three stages + vertical + horizontal (Allen's three stages + Horizons vertical focus + Laura's three-ring horizontal balance)

### ① Get Clear
- Empty `inbox.md`: clarify item by item to zero (invoke the clarify workflow).
- Gather loose "stuff" from everywhere (notes, open loops in your head) and capture it all into the system.

### ② Get Current
- Go through `next-actions.md`: cross off what's done; delete what's no longer relevant; is each one still a valid next action?
- Go through the **calendar (hard landscape)**: leftovers from last week / hard appointments coming this week. Read the external calendar provider first (preferred if reachable, see `references/capability-map.md`); only if all are unreachable, read the `calendar.md` fallback and note it may be incomplete. **Never copy the external calendar into calendar.md** (single fallback). Next week's 3 things must be checked against available time windows; if focus exceeds capacity, suggest deleting, deferring, delegating, or downgrading.
- Go through `waiting-for.md`: which ones need a follow-up? Check each delegated date.
- Go through `projects.md`: first ask **whether the project outcome has already been achieved**; if so, delete the whole project block (no archiving, no "Next actions: none"). For unfinished projects, ask whether each has at least one valid next-actions / waiting-for block link; keep only current actions that can run in parallel; fix stalled ones on the spot. Is the project outcome still wanted?
- Go through `product-ideas.md`: does every product opportunity have `GTD visibility` pointing to a project / next action? If missing, add a project or next action on the spot; don't let product opportunities sit as a cold-storage backlog.

### ③ Get Creative
- Go through `someday-maybe.md`: has anything ripened enough to pull into active?
- Go through `product-ideas.md`: which product opportunities need more evidence, deletion, downgrading, or advancing to a PRD? This is product trade-off work, not the structural "is it visible" check.
- Any new ideas / projects this week to add?

### ④ Horizons check (vertical focus, the review's elevation)
- Rise to 30k+: read `horizons.md` and ask "Do current projects still serve my goals / areas of focus?"
- Are there projects where I'm "efficiently doing things I shouldn't be doing"? Cut what should be cut.

### ⑤ Three-ring balance audit (horizontal · Laura Vanderkam, complementing the vertical)

> The vertical (④) checks "should each thing be done at all"; the horizontal checks "are the three big categories out of balance" — the two complement each other: one prevents doing the wrong things, the other prevents neglecting whole areas. Source: Laura Vanderkam's career / relationships / self three rings (Ringmaster).

- **Roughly sort** the 20k areas of focus in `horizons.md` **into career / relationships / self**, and see whether this week's energy all went to career while relationships / self got zero.
- For each empty ring, ask: **does this ring have one "named" thing this week** (a specific activity + time + frequency, e.g. "Wednesday 9:00 pm, 30 minutes with family", not "spend more time with family")? If you can't name one = the ring has gone silent; add one to next week.
- **Calm red line (this skill's style)**: the three rings are only a balance prompt — no scoring, no judgment, no nagging if the user skips it.

## Workflow
1. Run this skill's `scripts/gtd_review_prep.sh` to get the review prep pack; if the script is missing, fall back to `gtd_status.sh` + a manual scan of all lists.
2. Do organize's mechanical hygiene first: handle what can safely be handled automatically; gather decisions into one batch of questions.
3. Proceed through ①②③④ in order; in each stage give the user only the points needing judgment, and let the AI organize, draft, and file the rest.
4. Write to file only after the user confirms: clear the inbox, cross off, add next actions, move someday items, fill product ideas visibility, advance / downgrade / delete product ideas, update projects / waiting-for.
5. Record a weekly review snapshot with `templates/weekly-review-template.md` (save it in your daily-notes folder or a project directory, **not** memory/gtd/).
6. Close with a one-line "system status" summary + the 3 things most worth pushing next week. **Close the 3 things with Laura Vanderkam's three moves**: ① translate what didn't make it in as "I don't have time for X = X isn't a priority this week", confirming it's a deliberate trade-off, not an omission; ② give the one of the 3 most likely to be squeezed out by work (usually in the relationships / self ring) a **back-up slot in the same week** (a spare time slot: when the main slot gets eaten, automatically jump to the backup without re-deciding); ③ for recurring things, "three times a week is a habit" — not every day, and don't let perfectionism rule it out.

## Quality check
- [ ] Inbox emptied to zero
- [ ] Completed projects deleted; every remaining project has at least one valid next-action block link (no stalled leftovers)
- [ ] Every product idea has `GTD visibility` pointing to a project / next action
- [ ] Waiting-for items due for a follow-up flagged
- [ ] Did the Horizons check, not just horizontal clarifying
- [ ] Gave next week's 3 focus items, checked against hard-landscape capacity
- [ ] Did the three-ring balance audit (no empty ring among career / relationships / self; any empty ring got one item for next week)
- [ ] Next week's 3 things closed with the priority translation; the high-value one has a same-week back-up slot
- [ ] The user only had to confirm a few decision points and wasn't forced to go through raw lists item by item
