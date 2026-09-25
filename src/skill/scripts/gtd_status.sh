#!/usr/bin/env bash
# gtd_status.sh — read every list in memory/gtd/ and print a GTD dashboard (pure bash, works on all three platforms)
# Usage: bash gtd_status.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"
VAULT_ROOT="$GTD_WORKSPACE_ROOT"
GTD_DIR="$VAULT_ROOT/memory/gtd"

if [ ! -d "$GTD_DIR" ]; then
  echo "memory/gtd/ does not exist. Run first: bash gtd_init.sh"
  exit 1
fi

# grep -c still prints "0" on zero matches but exits 1 — swallow the exit code with || true and return a single value
cnt() {
  local n
  n=$(grep -cE "$1" "$2" 2>/dev/null) || true
  echo "${n:-0}"
}

# Count open items starting with "- [ ] " in a file
count_open() {
  local f="$GTD_DIR/$1"
  [ -f "$f" ] || { echo 0; return; }
  cnt '^- \[ \] ' "$f"
}

# Inbox items to clarify: bullet lines
count_inbox() {
  local f="$GTD_DIR/inbox.md"
  [ -f "$f" ] || { echo 0; return; }
  cnt '^- ' "$f"
}

# projects: number of ## project blocks (GTD-native projects use ## )
count_projects() {
  local f="$GTD_DIR/projects.md"
  [ -f "$f" ] || { echo 0; return; }
  cnt '^## ' "$f"
}

# stalled projects: projects with no valid "Next actions" block link; "Next actions: none" counts as a leftover
count_stalled() {
  local f="$GTD_DIR/projects.md"
  [ -f "$f" ] || { echo 0; return; }
  awk '
    function has_action_link(line) {
      return line ~ /\[\[(next-actions|waiting-for)#\^/
    }
    function invalid_next_heading(line) {
      return line ~ /Next actions:([[:space:]]*)?(none|None|nothing|not needed|done|Done|completed|confirmed|N\/A)/
    }
    /^## / {
      if (in_project && !has_valid_next) stalled++
      in_project=1
      has_valid_next=0
      in_next_section=0
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
      if (in_project && !has_valid_next) stalled++
      print stalled + 0
    }
  ' "$f"
}

# calendar: dated lines
count_calendar() {
  local f="$GTD_DIR/calendar.md"
  [ -f "$f" ] || { echo 0; return; }
  cnt '^- [0-9]{4}-[0-9]{2}-[0-9]{2}' "$f"
}

echo "════════════════════════════════════"
echo "  GTD Dashboard · memory/gtd/"
echo "════════════════════════════════════"
printf "  📥 Inbox to clarify   : %s\n" "$(count_inbox)"
printf "  ✅ Next Actions       : %s\n" "$(count_open next-actions.md)"
printf "  🎯 Projects           : %s (stalled≈ %s)\n" "$(count_projects)" "$(count_stalled)"
printf "  ⏳ Waiting For        : %s\n" "$(count_open waiting-for.md)"
printf "  📅 Calendar (hard)    : %s\n" "$(count_calendar)"
printf "  💭 Someday/Maybe      : %s\n" "$(count_open someday-maybe.md)"
printf "  💡 Product Ideas      : %s\n" "$(count_open product-ideas.md)"
echo "────────────────────────────────────"

# Alerts
inbox_n=$(count_inbox)
stalled_n=$(count_stalled)
[ "$inbox_n" -gt 0 ] && echo "  ⚠️  Inbox has $inbox_n unclarified item(s) → run /gtd-clarify"
[ "$stalled_n" -gt 0 ] && echo "  ⚠️  ~$stalled_n project(s) lack a valid next action or are completed leftovers → /gtd-organize"
echo "  🔭 The Weekly Review (Reflect) is the critical success factor → /gtd-review"
echo "════════════════════════════════════"
