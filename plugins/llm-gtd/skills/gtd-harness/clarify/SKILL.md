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
- After a legacy import, the "Needs light fields" section needs re-evaluation.

## Decision tree (ask for each inbox item)

```
What is it? Is it actionable?
├── No → three destinations:
│   ├── Useless / expired             → Trash
│   ├── Not now, but don't forget     → someday-maybe.md (incubate)
│   ├── Product / feature / scenario opportunity → product-ideas.md (keep the original opportunity) + projects/next-actions (daily visibility)
│   └── Reference / support material  → reference.md (knowledge / ideas → hand off to the ZK pipeline fleeting-note)
│
└── Yes → What's the next concrete physical action?
    ├── < 2 minutes          → Do it (two-minute rule), cross it off when done
    ├── Someone else should  → Delegate it → waiting-for.md (record person + agreement + date)
    └── Mine, > 2 minutes    → Defer it:
         ├── Time- / day-specific → hard landscape (calendar): check the target time window first; if no conflict and details are complete, write to the reachable calendar provider; if unreachable or key fields are missing, fall back
         └── As soon as possible  → next-actions.md (action pool; state Time / Energy / Constraint)
    ※ If completion takes >1 step → also create a project in projects.md (outcome + next action); the next action goes into next-actions
```

## Workflow

1. Read `inbox.md` and run the decision tree item by item. One item at a time, no skipping.
2. **Key questions**:
   - "Is it actionable?" — this gate separates action from knowledge (knowledge → ZK pipeline, not GTD lists).
   - "What's the next concrete physical action?" — it must be a visible physical action ("Call Colleague A to confirm the data definitions"), not "handle the data". Concrete verbs; reject vague verbs.
   - "What exactly counts as done for this?" — define the **outcome / definition of done** first, then decide whether it goes to `waiting-for`, `next-actions`, `projects`, or can be closed. Don't automatically treat milestones such as "approval passed", "meeting time agreed", or "got a reply" as final completion unless the user defines it that way.
   - "What's this action's Time / Energy / Constraint?" — only fill in light fields; don't turn lenses into a complex tagging system. The AI estimates by default and asks only when clearly unsure.
3. **Filing**: append the item to the end of the matching group in the target list per the decision tree (see each list's template for the format).
   - Anything going into next-actions must carry three light fields: `Time` (2 min / 10 min / 30 min / 60-90 min), `Energy` (low energy / medium energy / deep work / low emotional load), `Constraint` (hard location / setting, tool / channel, person present, prep chain, shopping, before a meeting, ID / payment / documents / equipment, etc.). Legacy `@computer/@calls/@errands/@home/@agenda-name` groups are kept for compatibility only and are no longer the default primary grouping.
   - When it's clearly a product idea / feature opportunity / scenario opportunity, put it in `product-ideas.md` keeping the original opportunity, and by default also create visible work items in `projects.md` + `next-actions.md`; only when the user explicitly says "store it, don't process it / capture only" is it left un-promoted.
   - When creating a project, write the outcome + next action in projects.md and sync the next action into next-actions. A project's "Next actions" must not just say "see next-actions" or a generic context; link to the specific next-actions block, e.g. first append `^na-short-id-YYYYMMDD` to the action line, then write `[[next-actions#^na-short-id-YYYYMMDD|Concrete next action]] (constraint: needs computer)` in the project.
   - For headings inside GTD files, use Obsidian heading links: project references are `[[projects#Project name|Project name]]`; support material references are `[[reference#Entry name|Entry name]]`. Bare `[[Heading]]` is only for real standalone files.
   - When updating an existing project, if the desired outcome is achieved and no next action still needs pushing → delete the whole project block from projects.md; don't write "Next actions: none" or keep finished projects as records.
   - **Waiting-for items must state two layers**: `what you're currently waiting for` and `what finally counts as done`. Especially for payment flows, approval flows, legal routing, refunds, and reimbursements, `approval passed / submitted / they replied / technical evaluation started` are often just milestones, not closure. If the final definition of done is "payment received / fully signed / item received / actually scheduled and happened", state it in the waiting-for text or agreement to avoid deleting the item too early.
   - For anything doable in 2 minutes, tell the user "This one takes <2 minutes — I suggest doing it now."
   - **Time-specific items → calendar (hard landscape)**: one-calendar hard rule — when an external calendar provider is reachable, write to it first; only when all are unreachable write the `calendar.md` fallback; **never keep a copy**. Writing to an external calendar is a high-consequence action, but it may be done automatically when event details are complete. Before writing, read the target time slot's hard landscape (read each existing event's availability, not just its title or length — see `references/capability-map.md`'s conflict and capacity judgment); if an event already occupies it or the buffer before/after is too small to keep the commitment, list the conflict and stop, suggesting reschedule, cancel, delegate, or downgrade to next-action/someday. Report "written" only after the external tool returns success; on failure / unreachable, fall back step by step per `references/capability-map.md` and say so honestly — **never misreport**. When key fields such as date, time, or title / subject are missing, ask only for the missing fields; meetings without a duration default to 60 minutes.
4. After filing, **delete the item from the inbox** (once clarified it shouldn't stay in the inbox).
5. Not enough information to decide the next action → put it in next-actions as "TBD + what information is missing", or ask the user one question.

## Clarify rules for session-status input

- A session status is not itself a to-do; first split it into atomic items, then run each through the clarify decision tree.
- New commitments / project blockers → `projects.md` + `next-actions.md`; waiting on others → `waiting-for.md`; meaningful only on a specific day / time → calendar provider / `calendar.md` fallback chain; product opportunities → `product-ideas.md` + `projects.md` + `next-actions.md`; active-project support material → `reference.md`; pure knowledge insights → ZK pipeline.
- Don't leave a "today's summary / this session's summary" as a single item in `inbox.md` or `reference.md`. GTD holds only changes to the commitment system, not a chat log.
- After clarifying, output the fixed five sections from `templates/session-close-template.md`; write "None" for empty sections — never omit them.

## Quality check
- [ ] Every inbox item has a clear destination (one of the six), nothing left over
- [ ] Everything in next-actions is a **concrete physical action** + has Time / Energy / Constraint; each project's "Next actions" links directly to a specific action block
- [ ] Every >1-step item has a project with a next action (nothing stalled)
- [ ] Headings inside GTD files are referenced as `[[filename#Heading|Heading]]`; no in-list heading was mis-linked as a standalone file
- [ ] Projects whose desired outcome is achieved were deleted; no "Next actions: none" left behind
- [ ] Waiting-for items state what/which milestone is currently awaited and when it finally counts as done; no intermediate milestone mistaken for closure
- [ ] Target time slot checked for conflicts before writing a hard appointment; nothing written directly when there was a conflict
- [ ] Knowledge / ideas handed to the ZK pipeline; GTD lists not polluted
- [ ] Session status split into atomic GTD items, no whole summary stuffed into a list, closed with the fixed five sections
- [ ] Two-minute rule recognized and flagged
