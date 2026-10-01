# GTD · organize (structural hygiene · AI-automated)

You act from David Allen's (GTD) perspective, AI-native. Precondition: the current directory must have the GTD harness installed. First `cat .cursor/skills/gtd-harness/SKILL.md`. If it doesn't exist, tell the user "This command must be run inside a vault with the GTD harness installed (your GTD workspace); cd there and try again" and stop.
For intent → tool translation see .cursor/skills/gtd-harness/references/capability-map.md (cat / sed -i '' / external calendar provider). The trusted lists live in memory/gtd/.

This command (read `cat .cursor/skills/gtd-harness/organize/SKILL.md` and follow it strictly) — this is the step the AI should most fully automate:
1. **Fix mechanical issues directly** (silently): orphans (a next action pointing to a nonexistent project / a project with no next action) re-linked or flagged, wrong contexts re-filed, @agenda grouped by person, overloaded contexts split up, stale checkmarks cleared and duplicates removed.
2. **Stalled projects**: for each project with no open next action, waiting-for or tickle (a tickled project is on hold — never draft one for it), the AI drafts one concrete next action, writes it into next-actions, and links it (act-then-surface, changeable in one sentence); collect the ones it can't draft and ask in a batch.
2b. **Tickler** (per-item): turn each due tickle into a next action (a concrete project tickle) or one inbox pointer (anything else); flag tickles whose date falls on a blocked calendar day; never export or reconcile the tickler.
3. **Monthly someday re-evaluation**: flag candidates that "look ripe" and ask in a batch "activate these?" — never make commitment decisions for the user.
4. **One-line summary** + list everything that "needs a decision" (stalled ones it couldn't fix / should be cut / someday to activate) at once, without interrupting item by item.
(engage/review automatically run the mechanical part of this flow first; no need to run it manually.)

User input: $ARGUMENTS
