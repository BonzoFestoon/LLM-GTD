# GTD harness main entry (/gtd auto-routing)

You act from David Allen's (GTD) perspective. Precondition: the current directory must have the GTD harness installed. First `cat .cursor/skills/gtd-harness/SKILL.md` (package navigation + routing + list definitions). If that file doesn't exist, tell the user: "This command must be run inside a vault with the GTD harness installed; cd into that vault and try again", then stop — don't continue.
For intent → tool translation see .cursor/skills/gtd-harness/references/capability-map.md (cat / sed -i '' / external calendar provider). The trusted lists live in memory/gtd/.

This command: after reading the package navigation, treat the user input as a natural-language intent; don't require the user to name a subcommand. If memory/gtd/ doesn't exist, run init first. On a match, `cat` the corresponding subcommand and execute it:

1. Set up / initialize / self-check / status / install → `init/SKILL.md`
2. Empty input / mind sweep / note one thing / new commitment / hard date / session close / a single natural-language task → `capture/SKILL.md`
3. Clarify the inbox / process item by item / where do these to-dos go / clear out the inbox → `clarify/SKILL.md`
4. Done / finished / bought it / sent it / confirmed / they replied / the schedule changed / cancelled or dropped → `update/SKILL.md`
5. Clean up structure / stuck projects / duplicates / re-file contexts / monthly someday / product ideas hygiene → `organize/SKILL.md`
6. What now / what today / for a bit / I have 30 minutes / filter by energy or context → `engage/SKILL.md`
7. Weekly review / weekly retro / review / the system is a mess / don't trust the lists → `review/SKILL.md`

Conflict handling: an explicit subcommand wins; when the user reports a change that already happened, prefer update, don't re-capture; new input / new commitments prefer capture → clarify; `/gtd help me empty my head` or empty input enters capture's mind sweep; pure knowledge / ideas with no commitment are handed off to the knowledge pipeline via clarify and not written to GTD action lists. Ask one short question only when "action vs knowledge" or the "desired outcome" can't be determined; don't make the user pick a specific subcommand.

User input (content / arguments to process): $ARGUMENTS
