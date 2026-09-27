#!/usr/bin/env bash
# gtd_help.sh — read-only: print the commands table (with When to run / example / model
# tier, sourced from each sub-skill's own frontmatter and body, never hand-written) or one
# command's detail. Writes nothing, ever.
#
# Usage:
#   bash gtd_help.sh              # every command: name, description, model tier, example
#   bash gtd_help.sh <command>    # one command's description + full "## When to run" section
#                                  # <command> matches either form, e.g. "clarify" or "gtd-clarify"
#
# Compatible with macOS bash 3.2 (no associative arrays / mapfile) — see gtd_init.sh's note.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"
SKILL_DIR="$GTD_SKILL_DIR"

# Ordered list: "<short-name> <path-relative-to-SKILL_DIR>"
COMMANDS="gtd:SKILL.md
gtd-init:init/SKILL.md
gtd-capture:capture/SKILL.md
gtd-clarify:clarify/SKILL.md
gtd-update:update/SKILL.md
gtd-organize:organize/SKILL.md
gtd-engage:engage/SKILL.md
gtd-review:review/SKILL.md
gtd-help:help/SKILL.md"

# frontmatter_field FILE KEY — the first "key: value" line's value, quotes stripped.
# Handles both `key: value` and `key: |` (block scalar - returns the first indented
# content line instead, which is what description needs for the top-level SKILL.md).
frontmatter_field() {
  local file="$1" key="$2"
  awk -v key="$key" '
    BEGIN { infm=0; done=0 }
    /^---[[:space:]]*$/ { infm++; if (infm==2) exit; next }
    infm==1 && !done && $0 ~ "^" key ":" {
      line = $0
      sub("^" key ":[[:space:]]*", "", line)
      if (line == "|" || line == "") { block=1; next }
      gsub(/^"|"$/, "", line)
      print line
      done=1
      next
    }
    infm==1 && block && /^[[:space:]]/ {
      line = $0
      sub(/^[[:space:]]+/, "", line)
      print line
      done=1
      block=0
      next
    }
    infm==1 && block { block=0 }
  ' "$file"
}

# when_to_run_section FILE — every line of the "## When to run" section, verbatim.
when_to_run_section() {
  local file="$1"
  awk '
    /^## When to run/ { grab=1; next }
    /^## / && grab { grab=0 }
    grab { print }
  ' "$file"
}

# resolve_command NAME — echoes the matching "short-name path" line, or nothing.
resolve_command() {
  local want="$1" line short
  echo "$COMMANDS" | while IFS=: read -r short path; do
    [ -z "$short" ] && continue
    if [ "$short" = "$want" ] || [ "$short" = "gtd-$want" ] || [ "gtd-$want" = "$short" ]; then
      echo "$short:$path"
      return 0
    fi
  done
}

if [ $# -eq 0 ]; then
  echo "GTD commands"
  echo "════════════════════════════════════"
  printf "%-13s %-8s  %s\n" "Command" "Tier" "Description"
  echo "$COMMANDS" | while IFS=: read -r short path; do
    [ -z "$short" ] && continue
    f="$SKILL_DIR/$path"
    [ -f "$f" ] || { echo "  ⚠️  missing: $path"; continue; }
    tier="$(frontmatter_field "$f" "model-tier")"
    desc="$(frontmatter_field "$f" "description")"
    example="$(frontmatter_field "$f" "example")"
    printf "%-13s %-8s  %s\n" "/$short" "${tier:-?}" "$desc"
    [ -n "$example" ] && printf "              %-8s  e.g. %s\n" "" "$example"
  done
  echo "────────────────────────────────────"
  echo "See references/model-guidance.md for what each tier means and the current"
  echo "model recommendation; the agent compares that against this session's actual"
  echo "model, which this script has no way to know."
  echo ""
  echo "bash gtd_help.sh <command>   — one command's description + When to run"
  exit 0
fi

match="$(resolve_command "$1")"
if [ -z "$match" ]; then
  echo "Unknown command: $1" >&2
  echo "Known: $(echo "$COMMANDS" | cut -d: -f1 | tr '\n' ' ')" >&2
  exit 2
fi
short="${match%%:*}"
path="${match#*:}"
f="$SKILL_DIR/$path"

echo "/$short"
echo "════════════════════════════════════"
echo "$(frontmatter_field "$f" "description")"
echo ""
echo "Model tier: $(frontmatter_field "$f" "model-tier")"
echo "Example: $(frontmatter_field "$f" "example")"
echo ""
echo "When to run:"
when_to_run_section "$f"
