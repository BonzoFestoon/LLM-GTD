---
name: gtd-engage
description: GTD skill scenario command · Engage. Uses the four criteria — context / time available / energy available / priority — to say "what to do right now" from the lists. GTD step 5.
parent: gtd-harness
---


# GTD · engage (engage / choose the next action)

**Perspective**: David Allen. Engage answers "what can I do right now with the most confidence". GTD isn't driven by a sense of "should"; it filters on the spot with the **four-criteria model** — provided the first four steps have already clarified the system, otherwise the choice itself is full of anxiety.

## Loading and boundaries

- Before choosing actions, run mechanical hygiene per `organize/SKILL.md`; read `references/list-definitions.md` when list boundaries are unclear.
- Hard landscape / free time windows: read `references/capability-map.md`.
- Daily Engage automation cadence or Approval Radar: read `references/automation-profiles.md`.
- Automation boundary: offer only a 3-5 item candidate menu; never present candidates as today's commitments, never schedule them into the calendar automatically.

## When to run
- The user asks "what should I do now", "what can I do for a bit", "I have 30 minutes, what can I get done".
- In the morning / before a stretch of free time, for a focused view.
- Before a 1:1 / project meeting, for actionable items related to a person / project (the review agenda view also works).

## Four-criteria filter (narrow in order)

```
1. Context          — which real constraints decide whether I can do it right now? → filter the action pool by hard setting / tool constraint / current-state lenses
2. Time available   — how long do I have?                      → short window, pick short tasks
3. Energy available — how's my mental / physical energy now?   → low energy, pick light tasks
4. Priority         — all else equal, which has the highest payoff? → Horizons calibration (which goal / area of focus it serves)
```

## Available lenses (fewer is better in v1)

- **Time lens**: 2 min / 10 min / 30 min / 60-90 min.
- **Energy lens**: low energy / medium energy / deep work / low emotional load.
- **Hard-setting lens**: shopping, on-the-way errands, materials at home, before a meeting, a person present, prep chain.
- **Tool / channel constraint**: needs computer, needs phone, needs documents, needs payment, needs ID, needs equipment.
- **Collaboration lens**: follow-ups due, @agenda-person, needs a decision.

Legacy `@computer/@calls/@errands/@home/@agenda` groups are read only as historical compatibility signals; an item is never recommended by default just because it's under `@computer`. Context is defined as "a constraint on whether it can really be done right now", not a location category.

## Allen's rules of judgment

- **Calendar before lists**: look at the hard landscape first and confirm how much free time really remains before the next hard appointment.
- **Next Actions are a menu from the action pool, not today's commitments**: clarify has already written actions clearly; engage just uses lenses to pick the right step for this moment from the action pool, without scheduling the whole list into the calendar or making the user face the whole list.
- **Three kinds of overload**: overlapping appointments = hard conflict; lots of next-actions = a big menu; declaring too many next-actions as must-finish-today = overcommitment, which needs deleting, deferring, delegating, or downgrading — not cramming into the calendar.

## Workflow

0. **Silently run organize structural hygiene first** (the mechanical automatic items in `organize/SKILL.md`: orphans / stalled / contexts / stale checkmarks / duplicates) — so "what to do now" is based on a clean structure and stalled projects don't slip. Add one line only if something needs your decision; otherwise don't interrupt.
1. First read **hard appointments for today / the current window** and compute the free time block until the next hard-landscape item; if the external calendar provider is reachable it is authoritative; if all are unreachable, read the `calendar.md` fallback and note "based on local fallback, may be incomplete".
2. If this run is the Daily Engage automation cadence and Approval Radar is enabled, do the read-only Approval Radar per `references/automation-profiles.md`: flag only approvals needing action or with status changes, never auto approve / reject / remind; if read-only permission is missing, state the gap and continue with Engage.
3. Ask (or infer from context) the user's **context, time available, energy**. Support natural-language lenses: `I only have 10 minutes`, `I'm out of energy`, `I'm heading out`, `I'm shopping`, `what do I need to prep for tomorrow morning`, `what needs a follow-up`. If the calendar-derived window differs from the time the user states, use the smaller one.
4. Read the `next-actions.md` action pool, honoring legacy `@computer/@calls/@errands/@home/@agenda` group signals but filtering by the four criteria and lenses, and give **3–5** "best to do now" candidates, each with its time estimate and why it fits "now".
5. When ranking by priority, **check upward against the Horizons**: which one best serves the current 30k goals / 20k areas of focus. Not "most urgent" but "most important and doable right now".
6. If there isn't enough free time today, or the user's declared today-musts clearly exceed the remaining time, output an "overcommitment" alert with four kinds of renegotiation suggestions — delete, defer, delegate, downgrade; don't automatically schedule next-actions into the calendar.
7. Also flag any waiting-for items that are due for a follow-up.
8. When the user finishes an item → close the loop (delete that line from next-actions).

## Quality check
- [ ] All candidates are doable in the user's **current context** (nothing recommended that can't be done)
- [ ] Looked at the hard landscape first and constrained candidates by the real free time window
- [ ] Gave time estimates matching the user's time available / energy
- [ ] Lenses like `10 min` / `low energy` / `deep work` / `shopping` / `prep` / `follow-ups due` can filter candidates from the action pool, without turning lenses into a big tagging system the user must maintain
- [ ] Nothing recommended by default just because it sits under a legacy `@computer/@calls` group; hard setting, time, and energy take precedence over soft tool groups
- [ ] Priority is grounded in the Horizons, not just "looks urgent"
- [ ] On overcommitment, gave renegotiation suggestions instead of cramming next-actions into the calendar
- [ ] Flagged waiting-for items due for a follow-up
- [ ] If the Daily Engage cadence has Approval Radar enabled, approvals were scanned read-only, and an approval provider failure did not interrupt Engage
