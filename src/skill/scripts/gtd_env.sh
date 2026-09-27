#!/usr/bin/env bash
# Shared environment resolver for GTD scripts.
#
# Workspace root resolution:
# 1. LLM_GTD_ROOT, when explicitly set.
# 2. Legacy installed layout: <workspace>/.cursor/skills/gtd-harness/scripts/.
# 3. Current working directory, for plugin installs.

GTD_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
GTD_SKILL_DIR="$(cd "$GTD_SCRIPT_DIR/.." && pwd)"
GTD_LEGACY_VAULT_INSTALL=0

if [ -n "${LLM_GTD_ROOT:-}" ]; then
  GTD_WORKSPACE_ROOT="$(cd "$LLM_GTD_ROOT" && pwd)"
else
  legacy_root="$(cd "$GTD_SCRIPT_DIR/../../../.." && pwd)"
  legacy_script_dir="$legacy_root/.cursor/skills/gtd-harness/scripts"
  if [ -f "$legacy_root/.cursor/skills/gtd-harness/SKILL.md" ] \
    && [ -d "$legacy_script_dir" ] \
    && [ "$(cd "$legacy_script_dir" && pwd)" = "$GTD_SCRIPT_DIR" ]; then
    GTD_WORKSPACE_ROOT="$legacy_root"
    GTD_LEGACY_VAULT_INSTALL=1
  else
    GTD_WORKSPACE_ROOT="$(pwd)"
  fi
fi

# Layout (see references/list-definitions.md "Layouts"):
#   notes — per-item: one folder of notes per list (memory/gtd/next-actions/ exists)
#   files — single-file: one .md file per list (the default)
# GTD_LAYOUT=notes|files overrides detection, for testing or forcing a mode.
case "${GTD_LAYOUT:-}" in
  notes|files) ;;
  "")
    if [ -d "$GTD_WORKSPACE_ROOT/memory/gtd/next-actions" ]; then
      GTD_LAYOUT=notes
    else
      GTD_LAYOUT=files
    fi
    ;;
  *) echo "GTD_LAYOUT must be 'notes' or 'files' (got: $GTD_LAYOUT)" >&2; exit 2 ;;
esac

# Per-item lists: one folder each under memory/gtd/. General reference is not one of them —
# in the per-item layout it lives at the workspace root (reference/), outside memory/gtd/.
GTD_NOTE_LISTS="next-actions waiting-for projects someday-maybe product-ideas"
