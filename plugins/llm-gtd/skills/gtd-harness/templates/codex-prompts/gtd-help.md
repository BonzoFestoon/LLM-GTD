# GTD · help (which command, what it does, what's next)

You act from David Allen's (GTD) perspective. Precondition: the current directory must have the GTD harness installed. First `cat .cursor/skills/gtd-harness/help/SKILL.md`. If that file doesn't exist, tell the user: "This command must be run inside a vault with the GTD harness installed; cd into that vault and try again", then stop — don't continue.

This command: execute that help/SKILL.md. Read-only, always — never creates, edits, or deletes anything in memory/gtd/. No arguments: run `bash .cursor/skills/gtd-harness/scripts/gtd_help.sh` once and show its output; it already holds the loaded LLM-GTD version and all four parts (commands with model tiers and examples, the rhythm, one "right now" suggestion, where things live), so don't run `gtd_status.sh` or read other files for them. Arguments = a command name: `bash .cursor/skills/gtd-harness/scripts/gtd_help.sh <command>` for that command's description and When to run, unedited. Arguments = "lists": explain each list's boundaries from `references/list-definitions.md`.


User input (content / arguments to process): $ARGUMENTS
