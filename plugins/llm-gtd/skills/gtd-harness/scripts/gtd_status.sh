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

# Per-item layout: count notes through gtd_list.sh (README.md and _done/ never count) and take
# stalled projects from gtd_check.sh. Inbox and calendar are files in both layouts.
count_lines() {
  grep -c . || true
}
if [ "$GTD_LAYOUT" = "notes" ]; then
  n_next="$(bash "$SCRIPT_DIR/gtd_list.sh" next-actions | count_lines)"
  n_projects="$(bash "$SCRIPT_DIR/gtd_list.sh" projects | count_lines)"
  n_waiting="$(bash "$SCRIPT_DIR/gtd_list.sh" waiting-for | count_lines)"
  n_someday="$(bash "$SCRIPT_DIR/gtd_list.sh" someday-maybe | count_lines)"
  n_ideas="$(bash "$SCRIPT_DIR/gtd_list.sh" product-ideas | count_lines)"
  stalled_n="$(bash "$SCRIPT_DIR/gtd_check.sh" | awk -F'\t' '$1 == "stalled"' | count_lines)"
  # The tickler is per-item only; a tickled project is on hold, so gtd_check.sh never calls it stalled.
  n_tickler="$(bash "$SCRIPT_DIR/gtd_list.sh" tickler | count_lines)"
  n_tickler_due="$(bash "$SCRIPT_DIR/gtd_list.sh" tickler --due | count_lines)"
  layout_label="per-item"
else
  n_next="$(count_open next-actions.md)"
  n_projects="$(count_projects)"
  n_waiting="$(count_open waiting-for.md)"
  n_someday="$(count_open someday-maybe.md)"
  n_ideas="$(count_open product-ideas.md)"
  stalled_n="$(count_stalled)"
  layout_label="single-file"
fi
n_done_week="$(bash "$SCRIPT_DIR/gtd_list.sh" done --since "$(gtd_days_ago 7)" | count_lines)"

echo "════════════════════════════════════"
echo "  GTD Dashboard · memory/gtd/ ($layout_label)"
echo "════════════════════════════════════"
printf "  📥 Inbox to clarify   : %s\n" "$(count_inbox)"
printf "  ✅ Next Actions       : %s\n" "$n_next"
printf "  🎯 Projects           : %s (stalled≈ %s)\n" "$n_projects" "$stalled_n"
printf "  ⏳ Waiting For        : %s\n" "$n_waiting"
printf "  📅 Calendar (hard)    : %s\n" "$(count_calendar)"
if [ "$GTD_LAYOUT" = "notes" ]; then
  printf "  🗂️  Tickler            : %s (%s due)\n" "$n_tickler" "$n_tickler_due"
fi
printf "  💭 Someday/Maybe      : %s\n" "$n_someday"
printf "  💡 Product Ideas      : %s\n" "$n_ideas"
printf "  🏁 Done, last 7 days  : %s\n" "$n_done_week"
echo "────────────────────────────────────"

# Alerts
inbox_n=$(count_inbox)
[ "$inbox_n" -gt 0 ] && echo "  ⚠️  Inbox has $inbox_n unclarified item(s) → run /gtd-clarify"
[ "$stalled_n" -gt 0 ] && echo "  ⚠️  ~$stalled_n project(s) lack a valid next action or are completed leftovers → /gtd-organize"
if [ "$GTD_LAYOUT" = "notes" ] && [ "$n_tickler_due" -gt 0 ]; then
  echo "  ⚠️  $n_tickler_due tickle(s) now actionable → /gtd-organize"
fi
echo "  🔭 The Weekly Review (Reflect) is the critical success factor → /gtd-review"
echo "════════════════════════════════════"
