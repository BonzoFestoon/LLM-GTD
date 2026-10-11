# GTD Session Close Template

Use for "this session's status / close this session / wrap up today". The goal is not a daily report but a diff of the commitment system.

## Order of operations

1. Scan this session and extract only GTD-relevant deltas: changes already completed and written, new commitments, project status changes, blockers, waiting on others, hard dates, decisions the user must make, and knowledge insights not yet in GTD.
2. Write each delta that isn't already in a GTD list to `memory/gtd/inbox.md` as its own line (an insight as `- Insight: …`). Capture doesn't clarify: what each item means and where it goes is decided later, in `/gtd-clarify`.
3. Don't decide uncertain commitments for the user; capture them as they are.
4. Before closing, run `scripts/gtd_status.sh` and use the real dashboard numbers, not numbers from memory.
5. Output the five sections below; write "None" for an empty section — never omit a heading.

## Output format

**Completed and written to file**
- ...

**Captured to the inbox (clarify with /gtd-clarify)**
- ...

**Decisions for the user**
- ...

**Knowledge insights (captured as inbox items)**
- ...

**Current dashboard**
- Inbox: ...
- Next Actions: ...
- Projects: ... (stalled: ...)
- Waiting For: ...
- Calendar: ...
- Someday/Maybe: ...

## Quality bar

- Don't stuff a whole-chat summary into `inbox.md` or `reference/`.
- Don't treat "already mentioned" as "already written to file"; only actual file changes count as written.
- Don't invent next actions for things that are clearly done.
- Don't file anything at session close: insights and commitments both go to the inbox, and clarify files them (insights to `reference/`).
