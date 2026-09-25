<!--
Append the snippet below to your workspace's AGENTS.md (the Codex / general agent protocol file),
in a section like "tool and command conventions", away from any mirror / sync blocks.
Purpose: lets Codex know the GTD harness exists when it reads the protocol, so it "triggers on plain language".
-->

### GTD harness (personal task system)

When the user mentions GTD / tasks / capture / clarify / next actions / weekly review / mind sweep / "what should I do this week", load the GTD harness:

- **Read the source directly**: `rtk cat .cursor/skills/gtd-harness/SKILL.md` (package navigation), then `rtk cat` the subcommand matching the intent (init/capture/clarify/update/organize/engage/review).
- **Autonomous chaining**: spawn the `gtd-orchestrator` agent (`.codex/agents/gtd-orchestrator.toml`) to run the full flow.
- **Natural-language entry**: the user doesn't have to name a subcommand; when they state a task / commitment directly, default to capture → clarify.
- **State**: the trusted lists live in `memory/gtd/` (eight lists, plain markdown); `rtk bash .cursor/skills/gtd-harness/scripts/gtd_status.sh` shows the overview; for the weekly review run `rtk bash .cursor/skills/gtd-harness/scripts/gtd_review_prep.sh` first; first time, `… /gtd_init.sh`.
- **Boundaries**: a personal task system; writes to the external calendar provider automatically when event details are complete, and falls back when key fields are missing or the external calendar provider is unreachable (see `references/capability-map.md` in the package).
