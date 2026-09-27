---
name: gtd-capture
description: GTD skill scenario command · Capture. Writes input to the inbox with zero friction, then (by default) the AI auto-clarifies and files it; also used for session close. GTD step 1 + (automatic) step 2.
parent: gtd-harness
model-tier: balanced
example: "Note this: confirm the contract version with Colleague A"
---


# GTD · capture (capture → auto-clarify by default)

**Perspective**: David Allen, with an AI-native refinement. Allen deliberately separated capture and clarify for the *human* mind — switching into decision mode has a cost, so capture only dumps things out with zero friction, and clarifying waits for a dedicated session. **But the AI's switching cost is ≈0 and it can draft a next action instantly**, so here the default is **auto-clarify after capture** — provided it keeps Allen's two real insights: ① **writing to file always comes first** (nothing gets lost); ② **batches / mind sweeps are never interrupted item by item** (friction is most damaging at high volume).

## Loading and boundaries

- Session close: read `templates/session-close-template.md` first.
- Single-item auto-clarify: follow `clarify/SKILL.md`; read `references/list-definitions.md` when list boundaries are unclear.
- Automation boundary: capture may write to the inbox automatically; ask one question when the commitment itself, the desired outcome, or action-vs-knowledge is unclear.

## When to run
- The user comes up with a to-do, idea, reminder, commitment, open question, "don't forget…".
- The user says "note this", "put it in the inbox", "capture this for me".
- The user wants to wrap up "today / this session's status / close this session": turn the commitments, blockers, waiting-fors, hard dates, and project status changes from the conversation into GTD input, and output the fixed five sections.
- A one-time full mind sweep: "my head is a mess, help me empty it".

## Workflow

1. **Zero-friction write to file (always first, so nothing is lost)**: append each item verbatim to the end of the "To clarify" section of `memory/gtd/inbox.md`, one item per line, keeping the original wording:
   ```
   - Original wording · Captured: YYYYMMDD
   ```

2. **Model check exception**: capture is the one command that never waits on the model check in `references/model-guidance.md`. If the session is below capture's tier, skip straight to auto-clarify's off-switch: don't run the clarify decision tree, and report "Captured. You're on ⟨model⟩, so I didn't file it; switch to ⟨tier's model⟩ and run `/gtd-clarify`." instead of the usual one-line clarified-to report. The write in step 1 has already happened either way — nothing is ever lost waiting on a model check.

3. **Session-status preprocessing (not journaling)**: when the user says "wrap up today / this session's status / close out", read `templates/session-close-template.md` first, then compress the conversation into 3-5 GTD-relevant deltas: new commitments, pending confirmations, waiting on others, hard dates, project status changes or blockers. Write each as a separate inbox item from the raw facts; don't stuff a full chat summary, emotional log, or knowledge insights into `memory/gtd/`. Hand knowledge / insights to the ZK pipeline; only support material directly tied to an active project goes into `reference.md`. Before closing, run `scripts/gtd_status.sh`, then output the template's five sections.

4. **Triage by volume**:
   - **Single / few (≤3 items) → auto-clarify by default**: after writing to file, immediately run the `clarify` decision tree on each item (see `clarify/SKILL.md`), **clarify and file** it in the right list + set the next action, then delete it from the inbox, and **report in one line**: "Clarified: ⟨original⟩ → ⟨list⟩ ⟨context⟩ (next action: ⟨concrete action⟩). Tell me if you want a different list or action." — act-then-surface, no item-by-item Q&A (markdown is instantly editable; optimistic filing + easy correction beats up-front interrogation).
   - **Batch / mind sweep (many items) → capture everything first, no item-by-item interruptions**: use an incompletion trigger list to help the user sweep, drop everything into the inbox, **then** ask once "Want me to clarify these one by one now?" for a batch clarify. This keeps Allen's zero-friction capture.

5. **Human-judgment guard (stop and ask one question only in these cases; otherwise don't interrupt)**:
   - Can't tell "action vs knowledge / idea" (knowledge goes to the ZK pipeline `fleeting-note`, not GTD);
   - Clearly a product / feature / scenario opportunity → automatically file it in `product-ideas.md` keeping the original opportunity, and by default also create visible items in `projects.md` + `next-actions.md`; don't mix it into `someday-maybe.md`. Only when the user explicitly says "store it, don't process it / capture only" is it left un-promoted;
   - No concrete next action can be derived (not enough information);
   - It implies a commitment "you may not want to make" (whether to do it at all is your call);
   - It's a >1-step project but the desired outcome is unclear.
   In these cases: write to file first, then ask one confirming question — **never decide for the user**.

6. **Off-switch**: the user says "capture only / don't clarify yet / just record" → write to the inbox only, no auto-clarify; leave it for a later `/gtd-clarify`.

## Quality check
- [ ] Writing to file always precedes clarifying (nothing lost under any circumstance)
- [ ] Single items auto-clarified and filed by default + one-line report of where they went, correctable in one sentence
- [ ] Below the model-tier, still wrote to the inbox first, then said so and named the command to run instead of auto-clarifying
- [ ] Mind sweep not interrupted item by item (capture all first, then batch clarify)
- [ ] Stopped to ask only in the four "your call" cases; no other interruptions
- [ ] Session status extracted only changes that affect the commitment system, created no second log / daily report, and used the five-section template
- [ ] Knowledge / ideas handed to ZK; GTD lists not polluted
