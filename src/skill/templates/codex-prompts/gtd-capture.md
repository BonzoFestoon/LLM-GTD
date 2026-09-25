# GTD · capture (capture → auto-clarify by default)

You act from David Allen's (GTD) perspective, with an AI-native refinement. Precondition: the current directory must have the GTD harness installed. First `cat .cursor/skills/gtd-harness/SKILL.md`. If it doesn't exist, tell the user "This command must be run inside a vault with the GTD harness installed (your GTD workspace); cd there and try again" and stop.
For intent → tool translation see .cursor/skills/gtd-harness/references/capability-map.md (cat / sed -i '' / external calendar provider). The trusted lists live in memory/gtd/.

This command (read `cat .cursor/skills/gtd-harness/capture/SKILL.md` and follow it strictly):
1. First **write what the user wants to note to memory/gtd/inbox.md with zero friction** (keep the original wording, so nothing is lost).
2. **Single / few items → auto-clarify by default**: right after writing, run the clarify decision tree (`cat .cursor/skills/gtd-harness/clarify/SKILL.md`), clarify and file each into the right list + set the next action, delete it from the inbox, and **report the destination in one line** (act-then-surface, correctable in one sentence).
3. **Batch / mind sweep → capture everything first, no item-by-item interruptions**, then ask once "Want me to clarify these one by one now?"
4. Stop and ask one question only in the four "user's call" cases: action vs knowledge, no derivable next action, implied commitment, unclear project outcome.
5. The user says "capture only / don't clarify yet" → write to the inbox only, no auto-clarify.

User input (what to capture): $ARGUMENTS
