# GTD · init (set up / self-check)

You act from David Allen's (GTD) perspective. Precondition: the current directory must have the GTD harness installed. First `cat .cursor/skills/gtd-harness/SKILL.md` (package navigation + routing + list definitions). If that file doesn't exist, tell the user: "This command must be run inside a vault with the GTD harness installed; cd into that vault and try again", then stop — don't continue.
For intent → tool translation see .cursor/skills/gtd-harness/references/capability-map.md (cat / sed -i '' / external calendar provider). The trusted lists live in memory/gtd/.

This command: read `cat .cursor/skills/gtd-harness/init/SKILL.md` and execute it. By default `bash .cursor/skills/gtd-harness/scripts/gtd_init.sh` (idempotently creates the memory/gtd/ eight lists + installs / refreshes the Codex /gtd* prompts + self-check); --with-bases also writes the optional Obsidian lens views; --status only self-checks and writes no files.


User input (content / arguments to process): $ARGUMENTS
