#!/usr/bin/env bash
# gtd-harness installer — installs the GTD harness into a workspace (vault) and wires up triggers on all three platforms.
#
# Usage:
#   ./install.sh [VAULT_DIR]        # default VAULT_DIR = current directory
#   ./install.sh ~/notes            # install into the given workspace
#
# What gets installed:
#   1. skill package      → <VAULT>/.cursor/skills/gtd-harness/
#   2. Claude Code commands → <VAULT>/.claude/commands/gtd*.md      (/gtd + /gtd-* slash commands)
#   3. Codex slash commands → ${CODEX_HOME:-~/.codex}/prompts/gtd*.md (global, includes /gtd)
#   4. Codex agent        → <VAULT>/.codex/agents/gtd-orchestrator.toml
#   5. run gtd_init.sh    → creates the <VAULT>/memory/gtd/ eight lists (idempotent)
#   Cursor keyword triggers + AGENTS.md auto-routing are manual steps (see the note at the end).

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT="${1:-$(pwd)}"
VAULT="$(cd "$VAULT" && pwd)"   # make absolute
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"

echo "GTD Harness installer"
echo "  Repo: $REPO"
echo "  Workspace (VAULT): $VAULT"
echo ""

# 1. skill package
mkdir -p "$VAULT/.cursor/skills/gtd-harness"
cp -R "$REPO/src/skill/." "$VAULT/.cursor/skills/gtd-harness/"
# Sync the Codex prompt templates into the skill package, so running gtd_init.sh alone can also install/refresh /gtd*.
mkdir -p "$VAULT/.cursor/skills/gtd-harness/templates/codex-prompts"
cp "$REPO"/src/codex-prompts/gtd*.md "$VAULT/.cursor/skills/gtd-harness/templates/codex-prompts/"
echo "✅ skill package → .cursor/skills/gtd-harness/"

# 2. Claude Code commands (replace the __VAULT__ placeholder with the real absolute path)
mkdir -p "$VAULT/.claude/commands"
for f in "$REPO"/src/claude-commands/gtd*.md; do
  sed "s|__VAULT__|$VAULT|g" "$f" > "$VAULT/.claude/commands/$(basename "$f")"
done
echo "✅ Claude Code commands → .claude/commands/ (/gtd + /gtd-* )"

# 3. Codex slash commands (global; Codex prompts only support the CODEX_HOME level)
mkdir -p "$CODEX_HOME_DIR/prompts"
cp "$REPO"/src/codex-prompts/gtd*.md "$CODEX_HOME_DIR/prompts/"
echo "✅ Codex slash commands → $CODEX_HOME_DIR/prompts/ (global /gtd + /gtd-* )"

# 4. Codex agent
mkdir -p "$VAULT/.codex/agents"
cp "$REPO"/src/codex-agents/*.toml "$VAULT/.codex/agents/"
echo "✅ Codex agent → .codex/agents/gtd-orchestrator.toml"

# 5. Initialize the trusted system
echo ""
echo "── Initializing memory/gtd/ ──"
bash "$VAULT/.cursor/skills/gtd-harness/scripts/gtd_init.sh"

# Manual steps
cat <<'NOTE'

── Two manual wiring steps (optional, for "triggers on plain language") ──

A) Cursor keyword triggers: merge the "gtd-harness" entry from snippets/cursor-skill-rules.json
   into the "skills" object of your <VAULT>/.cursor/skill-rules.json.

B) Codex "triggers on plain language": append the contents of snippets/AGENTS.routing.md to your
   <VAULT>/AGENTS.md (in the tool/command conventions section, away from any mirror blocks).

Done. Usage:
  Claude Code:  /gtd  /gtd-init  /gtd-capture  /gtd-clarify  /gtd-update  /gtd-organize  /gtd-engage  /gtd-review  /gtd-help
  Codex:        /gtd or /gtd-*; or just talk in plain language
  Dashboard:    bash .cursor/skills/gtd-harness/scripts/gtd_status.sh
NOTE
