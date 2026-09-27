# GTD · help (which command, what it does, what's next)

You act from David Allen's (GTD) perspective. Precondition: the current directory must have the GTD harness installed. First `cat .cursor/skills/gtd-harness/SKILL.md` (package navigation + routing + list definitions). If that file doesn't exist, tell the user: "This command must be run inside a vault with the GTD harness installed; cd into that vault and try again", then stop — don't continue.

This command: read `cat .cursor/skills/gtd-harness/help/SKILL.md` and execute it. Read-only, always — never creates, edits, or deletes anything in memory/gtd/. No arguments: `bash .cursor/skills/gtd-harness/scripts/gtd_help.sh` for the commands table (with model tiers and examples), plus the rhythm, one "right now" suggestion from `gtd_status.sh` (skip with a one-line note if it can't run), and where things live. Arguments = a command name: `bash .cursor/skills/gtd-harness/scripts/gtd_help.sh <command>` for that command's description and When to run, unedited. Arguments = "lists": explain each list's boundaries from `references/list-definitions.md`.


User input (content / arguments to process): $ARGUMENTS
