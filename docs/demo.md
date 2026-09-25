# Demo — a day with LLM-GTD

[中文](demo.zh-CN.md) | English

A realistic transcript of the five steps. Examples are illustrative; your wording can be natural.

---

## Featured: a project that advances as you report back

This is the move generic to-do tools can't make. You don't hand the agent a tidy task — you hand it
an *intention*. It recognizes a multi-step **project**, sets the *right first action*, and when you
come back with progress, it **closes the old next action and derives the next one** — keeping the
project alive without you re-planning.

**Turn 1** — a vague intention:

> You:
```
/gtd I want to get my family member into a class
```
> LLM-GTD:
```
Filed per GTD.

Made it a project:  📁 "Daughter's table-tennis interest & training path"

First action → Next Actions @home:
  Talk with her for 10 min — does she want to try it, current level,
  how many sessions/week she'd accept, what she does/doesn't enjoy.

I did NOT enroll, schedule, contact a coach, or write to the calendar.
GTD state verified: Inbox 0, Projects 3, Next Actions 3, stalled 0.

Note: the organizer suggests a later @computer action — "shortlist 3 nearby kids'
table-tennis options". My call: ask her first, then research providers.
```
*It refused to jump to enrollment. The right first action for a project about a *person* is to talk
to that person — and it deferred the research step on purpose.*

**Turn 2** — later, you report back:

> You:
```
/gtd-update Talked with my family member — she's really into a class, can do two sessions/week, ~1h each
```
> LLM-GTD:
```
Clarified and filed.

Your "talk with her 10 min" is checked off Next Actions; the project advances to its next action:
  Shortlist 2-3 table-tennis classes suitable for her — record slots for two
  sessions/week (~1h each), price, distance, and trial-class options.
  → next-actions.md

Project support material updated: she's interested, OK with two sessions/week;
I read your "~1h" as the session length but marked it needs-confirmation.
  → projects.md + reference.md

Check: Inbox 0, Projects 3, no stalled.
```
*This is the explicit update form; the general `/gtd` router would choose the same path
from the "talked with..." wording. The project moved one step forward on its own. The completed action was closed, the new next action
was derived from what you learned, support material captured the facts, and an inferred detail
("~1h") was flagged rather than assumed.*

**Why this matters:** a project without a current next action is a stalled promise. Here the harness
keeps the promise live across days, doing the bookkeeping, while you only ever supply judgment and
report reality.

---

## 0. Set up (once)

```bash
./install.sh ~/my-vault
```
```
✅ skill package → .cursor/skills/gtd-harness/
✅ Claude Code commands → .claude/commands/ (/gtd + /gtd-* )
✅ Codex slash commands → ~/.codex/prompts/ (global /gtd + /gtd-* )
✅ Codex agent → .codex/agents/gtd-orchestrator.toml
── Initializing memory/gtd/ ──  ✅ eight lists created
```

---

## 1. Capture → auto-clarify (single item)

> You:
```
/gtd-capture Renew passport before the summer trip
```
> LLM-GTD:
```
Clarified: "Renew passport before the summer trip"
→ projects.md "Renew passport" (desired outcome: valid passport in hand before the trip)
→ next-actions @errands: look up the nearest passport office and the documents it needs
Tell me if you want a different list or action.
```
*It captured first (never lost), then clarified one item and filed it. A multi-step outcome became a
project with a concrete next action.*

---

## 2. Mind sweep (bulk → captured first, then batch-clarified)

> You:
```
Help me clear my head.
```
> LLM-GTD walks a trigger list, dumps everything to `inbox.md` **without interrupting**, then:
```
Captured 14 items to the inbox. Want me to clarify them one by one now? (batch)
```
*High-volume capture stays zero-friction; clarify happens as a batch afterward.*

---

## 3. Engage — what to do now

> You:
```
/gtd-engage  I have 30 minutes, low energy, at my computer
```
> LLM-GTD (silently runs organize hygiene first, then):
```
@computer · 30 min · low energy — best to do now:
1. Reply to the email confirming next week's review time (~5 min)
2. Put the passport document checklist into reference (~10 min)
3. Draft the first three paragraphs of the weekly report (~20 min)
(Today's hard appointments: 16:00 team sync · Follow up: the data delegated to a colleague last week hasn't come back)
```
*Filtered by context + time + energy; priority cross-checked against Horizons. You choose.*

---

## 4. Review — the weekly keystone

> You:
```
/gtd-review
```
> LLM-GTD generates a read-only prep package, cleans mechanical drift, then walks you through:
```
── System overview ── inbox 0 · next-actions 9 · projects 4 (stalled 0) · waiting 2 · someday 6
① Get Clear    ✅ inbox emptied
② Get Current  crossed off 3; follow up 1 (colleague's data); every project has a valid next action
③ Get Creative someday "learn piano" doesn't look ready to start yet, keeping it
④ Horizons     "rewrite personal website" doesn't serve any goal this quarter → suggest cutting or moving to someday
Next week's 3 focus items: ①… ②… ③…
```
*The AI preps and cleans; **you** do the reflection — that part can't be outsourced.*

---

## What stayed human

Capture, clarify, and mechanical organize were automated. **Engage** (what to do now) and
**Update** handles reported reality, while **Engage** (what to do now) and
**Review** (is this still the right direction) kept you in the loop by design — which is exactly
where GTD's value lives.
