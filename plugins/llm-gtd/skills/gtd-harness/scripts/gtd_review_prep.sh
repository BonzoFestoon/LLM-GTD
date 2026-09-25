#!/usr/bin/env bash
# gtd_review_prep.sh — build a read-only weekly review prep pack; never modifies any list.
# Usage: bash gtd_review_prep.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"
VAULT_ROOT="$GTD_WORKSPACE_ROOT"
GTD_DIR="$VAULT_ROOT/memory/gtd"

if [ ! -d "$GTD_DIR" ]; then
  echo "memory/gtd/ does not exist. Run this skill's scripts/gtd_init.sh first"
  exit 1
fi

file() {
  printf "%s/%s" "$GTD_DIR" "$1"
}

section() {
  echo ""
  echo "## $1"
}

open_items() {
  local path="$1"
  if [ -f "$path" ]; then
    grep -nE '^- \[ \] |^- ' "$path" 2>/dev/null || true
  fi
}

stalled_projects() {
  local f
  f="$(file projects.md)"
  [ -f "$f" ] || return 0
  awk '
    function has_action_link(line) {
      return line ~ /\[\[(next-actions|waiting-for)#\^/
    }
    function invalid_next_heading(line) {
      return line ~ /Next actions:([[:space:]]*)?(none|None|nothing|not needed|done|Done|completed|confirmed|N\/A)/
    }
    /^## / {
      if (in_project && !has_valid_next) print project
      in_project=1
      has_valid_next=0
      in_next_section=0
      project=$0
      sub(/^## /, "", project)
      next
    }
    in_project && /^- Next actions:/ {
      in_next_section=1
      if (has_action_link($0)) {
        has_valid_next=1
      }
      if (invalid_next_heading($0)) {
        in_next_section=0
      }
      next
    }
    in_project && in_next_section && /^- / {
      in_next_section=0
    }
    in_project && in_next_section && has_action_link($0) {
      has_valid_next=1
    }
    END {
      if (in_project && !has_valid_next) print project
    }
  ' "$f"
}

vague_next_actions() {
  local f
  f="$(file next-actions.md)"
  [ -f "$f" ] || return 0
  grep -inE '^- \[ \] .*(follow up|handle|deal with|work on|push forward|look into|research|check out|think about|sort out|figure out)' "$f" 2>/dev/null || true
}

product_ideas_summary() {
  local f
  f="$(file product-ideas.md)"
  [ -f "$f" ] || return 0
  awk '
    function flush() {
      if (title != "") {
        print "- " title
        if (opportunity != "") print "  " opportunity
        if (visibility != "") print "  " visibility
        else print "  ⚠️ missing GTD visibility"
      }
    }
    /^### / {
      flush()
      title=$0
      sub(/^### /, "", title)
      opportunity=""
      visibility=""
      next
    }
    /^- \[ \] Opportunity:/ { opportunity=$0; next }
    /^- GTD visibility:/ { visibility=$0; next }
    END { flush() }
  ' "$f"
}

product_visibility_gaps() {
  local f
  f="$(file product-ideas.md)"
  [ -f "$f" ] || return 0
  awk '
    function check() {
      if (title != "" && visibility !~ /\[\[projects#/) {
        print title ": missing project visibility"
      } else if (title != "" && visibility !~ /next-actions/) {
        print title ": missing next-actions visibility"
      }
    }
    /^### / {
      check()
      title=$0
      sub(/^### /, "", title)
      visibility=""
      next
    }
    /^- GTD visibility:/ { visibility=$0; next }
    END { check() }
  ' "$f"
}

today="$(date +%Y-%m-%d)"

echo "GTD Review Prep · $today"
echo "Read-only review prep pack: scan before the review; does not modify memory/gtd/."

if [ -f "$SCRIPT_DIR/gtd_status.sh" ]; then
  echo ""
  bash "$SCRIPT_DIR/gtd_status.sh"
else
  section "Dashboard"
  echo "gtd_status.sh not found."
fi

section "Inbox to clarify"
inbox_items="$(open_items "$(file inbox.md)")"
if [ -n "$inbox_items" ]; then
  echo "$inbox_items" | sed -n '1,12p'
  inbox_total="$(printf "%s\n" "$inbox_items" | wc -l | tr -d ' ')"
  [ "$inbox_total" -gt 12 ] && echo "... and $((inbox_total - 12)) more"
else
  echo "None."
fi

section "Stalled Projects"
stalled="$(stalled_projects)"
if [ -n "$stalled" ]; then
  echo "$stalled" | sed 's/^/- /'
else
  echo "None."
fi

section "Waiting For"
waiting_items="$(open_items "$(file waiting-for.md)")"
if [ -n "$waiting_items" ]; then
  echo "$waiting_items"
else
  echo "None."
fi

section "Next Action hygiene"
vague="$(vague_next_actions)"
if [ -n "$vague" ]; then
  echo "Possible vague verbs / fuzzy actions:"
  echo "$vague"
else
  echo "No obvious vague verbs found."
fi

section "Someday/Maybe candidates"
someday_items="$(open_items "$(file someday-maybe.md)")"
if [ -n "$someday_items" ]; then
  echo "$someday_items"
else
  echo "None."
fi

section "Product Ideas visibility audit"
product_gaps="$(product_visibility_gaps)"
if [ -n "$product_gaps" ]; then
  echo "$product_gaps" | sed 's/^/- /'
else
  echo "Every product opportunity has GTD visibility."
fi

section "Product Ideas work intake"
product_items="$(product_ideas_summary)"
if [ -n "$product_items" ]; then
  echo "$product_items"
else
  echo "None."
fi

section "Confirmation queue"
echo "- Empty the inbox: clarify item by item to zero."
echo "- Stalled projects: add at least one concrete next action per project; attach several parallel actions if needed, or confirm cutting it."
echo "- Waiting for: confirm which items to follow up on; AI can draft a neutral message first."
echo "- Someday/maybe: confirm whether to activate, delete, or keep incubating."
echo "- Product ideas: first fill missing project / next-action visibility; then confirm gathering evidence, advancing to PRD, downgrading, or deleting."
echo "- Next week's 3 things: AI proposes candidates; the user confirms."
