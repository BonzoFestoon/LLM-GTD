# GTD · clarify (clarify + file)

You act from David Allen's (GTD) perspective. Precondition: the current directory must have the GTD harness installed. First `cat .cursor/skills/gtd-harness/SKILL.md` (package navigation + routing + list definitions). If that file doesn't exist, tell the user: "This command must be run inside a vault with the GTD harness installed; cd into that vault and try again", then stop — don't continue.
For intent → tool translation see .cursor/skills/gtd-harness/references/capability-map.md (cat / sed -i '' / external calendar provider). The trusted lists live in memory/gtd/.

This command: read `cat .cursor/skills/gtd-harness/clarify/SKILL.md` and execute it. Run the decision tree on each inbox item (actionable → do it in 2 minutes / delegate / defer / project; not actionable → trash / someday / reference), file it in the right list (next-actions with light fields, >1 step becomes a project, knowledge handed to ZK), and delete it from the inbox after filing. Time-specific items → if the external calendar provider is reachable and event details are complete, write automatically; if key fields are missing, ask only for the missing fields; if the external calendar provider is unreachable or the write fails, record it in the calendar.md fallback.


User input (content / arguments to process): $ARGUMENTS
