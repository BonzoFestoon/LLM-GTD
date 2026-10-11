#!/usr/bin/env bash
# gtd_help.sh — read-only: print the commands table (with When to run / example / model
# tier, sourced from each sub-skill's own frontmatter and body, never hand-written) or one
# command's detail. Writes nothing, ever.
#
# Usage:
#   bash gtd_help.sh              # the whole default view: the loaded LLM-GTD version and where
#                                  # it was loaded from, commands (name, description, model
#                                  # tier, example), models by tier, the rhythm, one "right now"
#                                  # suggestion, and where things live
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

# plugin_version — the version of the LLM-GTD copy this script belongs to, found from the
# script's own location, so it names the copy actually loaded (a plugin runs from a per-version
# cache, which can lag behind the repo): the plugin's plugin.json two levels above the skill,
# the VERSION file install.sh writes into a legacy .cursor/skills install, or, run from the repo's
# src/skill/, the repo's plugin.json. "unknown" when none is found.
plugin_version() {
  local f v
  for f in "$SKILL_DIR/../../.claude-plugin/plugin.json" "$SKILL_DIR/../../.codex-plugin/plugin.json" \
           "$SKILL_DIR/VERSION" "$SKILL_DIR/../../plugins/llm-gtd/.claude-plugin/plugin.json"; do
    [ -f "$f" ] || continue
    case "$f" in
      *.json) v="$(sed -n 's/^[[:space:]]*"version":[[:space:]]*"\([^"]*\)".*/\1/p' "$f" | head -n 1)" ;;
      *) v="$(head -n 1 "$f" | tr -d '[:space:]')" ;;
    esac
    if [ -n "$v" ]; then echo "$v"; return 0; fi
  done
  echo unknown
}

# tier_models —"  <tier>: <model>" per row of shared-rules.md's tier table, so the model names
# stay in that one file.
tier_models() {
  awk -F'|' '
    /^## Tiers/ { grab=1; next }
    /^## / && grab { exit }
    grab && /^\|/ {
      tier = $2; model = $4
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", tier)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", model)
      if (tier == "Tier" || tier ~ /^-+$/) next
      printf "  %-10s %s\n", tier ":", model
    }
  ' "$SKILL_DIR/shared-rules.md"
}

# right_now — one suggestion from the cheap signals only. Stalled projects and the done count
# are left to gtd_status.sh: on a large vault they take minutes, and help must stay quick.
right_now() {
  local gtd="$GTD_WORKSPACE_ROOT/memory/gtd" n
  if [ ! -d "$gtd" ]; then
    echo "  (skipped: no memory/gtd/ under $GTD_WORKSPACE_ROOT — see Where things live)"
    return 0
  fi
  n=0
  [ -f "$gtd/inbox.md" ] && { n=$(grep -cE '^- ' "$gtd/inbox.md" 2>/dev/null) || true; }
  if [ "${n:-0}" -gt 0 ]; then
    echo "  $n item(s) in the inbox → /gtd-clarify"; return 0
  fi
  n=$(bash "$SCRIPT_DIR/gtd_tagged.sh" 2>/dev/null | awk -F'\t' '$2 != "updates=0"' | grep -c .) || true
  if [ "${n:-0}" -gt 0 ]; then
    echo "  $n tagged note(s) to apply → /gtd-update"; return 0
  fi
  n=$(bash "$SCRIPT_DIR/gtd_list.sh" tickler --due 2>/dev/null | grep -c .) || true
  if [ "${n:-0}" -gt 0 ]; then
    echo "  $n tickle(s) now actionable → /gtd-organize"; return 0
  fi
  echo "  Inbox empty, nothing tagged or tickled → /gtd-engage"
}

# where_things_live — the resolved GTD folder, how it was resolved, and each list's location.
where_things_live() {
  local root="$GTD_WORKSPACE_ROOT" gtd="$GTD_WORKSPACE_ROOT/memory/gtd" how p mark
  if [ -n "${LLM_GTD_ROOT:-}" ]; then how="from LLM_GTD_ROOT"
  elif [ "$GTD_LEGACY_VAULT_INSTALL" = 1 ]; then how="from the .cursor/skills install"
  else how="the current directory; LLM_GTD_ROOT is not set"; fi
  echo "  GTD folder: $gtd ($how)"
  if [ ! -d "$gtd" ]; then
    echo "  ⚠️  It doesn't exist. If GTD lives elsewhere, set LLM_GTD_ROOT; don't init a second inbox."
    return 0
  fi
  for p in inbox.md calendar.md horizons.md next-actions/ projects/ waiting-for/ \
           someday-maybe/ tickler/ _done/; do
    mark=""; [ -e "$gtd/${p%/}" ] || mark="  (missing)"
    echo "    memory/gtd/$p$mark"
  done
  mark=""; [ -d "$root/reference" ] || mark="  (missing)"
  echo "  Reference: $root/reference/$mark"
  echo "  Each list folder has a README.md with its rules; finished items go to _done/."
}

if [ $# -eq 0 ]; then
  echo "LLM-GTD $(plugin_version) · loaded from $SKILL_DIR"
  echo ""
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
  echo "Models by tier (shared-rules.md):"
  tier_models
  echo "This script can't see the session's model; the agent compares it with the tier."
  echo ""
  echo "The rhythm"
  echo "════════════════════════════════════"
  echo "  capture any time (inbox only) → clarify when you choose to process the inbox"
  echo "  → engage when choosing what to do → update when something changes (said in"
  echo "  chat, or written into a note tagged gtd-update from anywhere, the phone"
  echo "  included) → organize runs by itself before engage and review → Weekly Review"
  echo "  once a week."
  echo ""
  echo "Right now"
  echo "════════════════════════════════════"
  right_now
  echo ""
  echo "Where things live"
  echo "════════════════════════════════════"
  where_things_live
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
