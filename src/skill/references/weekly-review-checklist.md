# Weekly Review Checklist (Allen standard)

> **The critical success factor.** Use a fixed time slot (e.g. Friday afternoon, 60–90 minutes). Rhythm matters more than perfection.

## 0. AI review prep pack (let the system do the grunt work first)
- [ ] Run `scripts/gtd_review_prep.sh` to get overall counts + risk items + confirmation queue
- [ ] Automatically run organize's mechanical hygiene: wrong contexts, duplicates, stale checkmarks, obvious orphans, stalled detection (per-item layout: from `gtd_check.sh`, including finished projects still missing an after-action review), and due tickles (per-item: a concrete project tickle becomes a next action, anything else is queued in the inbox; a scheduled review only reports them)
- [ ] Generate candidates: to delete / needing a next action / needing a follow-up / someday items that could be activated / next week's 3 things
- [ ] Mark which items the AI already handled and which must be confirmed by the user

## ① Get Clear
- [ ] Gather loose "stuff" from everywhere (your head, sticky notes, promises made in chats) → capture it all into the inbox
- [ ] Empty `inbox.md`: clarify item by item to zero

## ② Get Current
- [ ] `next-actions.md`: move what's done to the done record; delete what's no longer relevant; is each still a valid next action?
- [ ] `calendar.md`: look back at last week (any loose ends?) + look ahead at this week (are hard appointments prepared?)
- [ ] `waiting-for.md`: check each delegated date — which ones need a follow-up?
- [ ] Tickler (per-item): what came due and what it became; the next 14 days (anything to prepare now?); each project on hold — does its date still hold, is it still committed?; calendar conflicts organize flagged
- [ ] Done since last review (`gtd_list.sh done --since <last review date>`): wins first, then each item whose outcome records a problem: file its how-to to reference now, or leave it for the project's after-action review
- [ ] `projects.md`: first close projects whose outcome is achieved (AAR, then the done record: update's "Project close"); confirm each remaining project has at least one valid next action, waiting-for or tickle (a tickled project is on hold, not stalled); keep only parallel actions (fix stalled ones on the spot); is the outcome still wanted?

## ③ Get Creative
- [ ] `someday-maybe.md`: has anything ripened to pull into active? Delete what's outdated
- [ ] Any new ideas / projects to add this week?

## ④ Horizons check (vertical focus)
- [ ] Read `horizons.md` and ask: do current projects serve the 30k goals / 20k areas of focus?
- [ ] Any projects where you're "efficiently doing things you shouldn't be doing" → cut or re-evaluate

## ⑤ Three-ring balance audit (horizontal · Laura Vanderkam)
- [ ] Roughly sort the 20k areas of focus into career / relationships / self, and see whether everything went to career while the other two got zero
- [ ] For an empty ring, add one "named" thing (specific activity + time + frequency) to next week; prompt only, no judgment, skippable

## Close
- [ ] Record a snapshot with `templates/weekly-review-template.md` (save it in your daily-notes folder)
- [ ] Give the **3 things** most worth pushing next week; translate what didn't make it in as "I don't have time = it's not a priority"; give the high-value one a same-week back-up slot; for recurring things, "three times a week is a habit"
- [ ] Write to file only after confirmation: clear the inbox, cross off, add next actions, move someday items, update waiting-for / projects

## Suggested trigger cadence
- v1.1: run `/gtd-review` at a fixed weekly time; the AI builds the review prep pack first, and the user only confirms a few decision points.
- Optional automation cadence: install the Weekly Review profile per `references/automation-profiles.md`. **Install only with the user's explicit consent**; not enabled by default.
- A scheduled task may generate the review prep pack and give AI-judged candidates, but never automatically edits lists, writes to the calendar, sends messages, or decides next week's commitments for the user.
