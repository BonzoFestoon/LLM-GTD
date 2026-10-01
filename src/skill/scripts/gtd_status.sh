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
gtd_refuse_single_file

# grep -c still prints "0" on zero matches but exits 1 — swallow the exit code with || true and return a single value
cnt() {
  local n
  n=$(grep -cE "$1" "$2" 2>/dev/null) || true
  echo "${n:-0}"
}

# Inbox items to clarify: bullet lines
count_inbox() {
  local f="$GTD_DIR/inbox.md"
  [ -f "$f" ] || { echo 0; return; }
  cnt '^- ' "$f"
}

# calendar: dated lines
count_calendar() {
  local f="$GTD_DIR/calendar.md"
  [ -f "$f" ] || { echo 0; return; }
  cnt '^- [0-9]{4}-[0-9]{2}-[0-9]{2}' "$f"
}

# Count notes through gtd_list.sh (README.md and _done/ never count) and take stalled projects
# from gtd_check.sh. A tickled project is on hold, so gtd_check.sh never calls it stalled.
count_lines() {
  grep -c . || true
}
n_next="$(bash "$SCRIPT_DIR/gtd_list.sh" next-actions | count_lines)"
n_projects="$(bash "$SCRIPT_DIR/gtd_list.sh" projects | count_lines)"
n_waiting="$(bash "$SCRIPT_DIR/gtd_list.sh" waiting-for | count_lines)"
n_someday="$(bash "$SCRIPT_DIR/gtd_list.sh" someday-maybe | count_lines)"
stalled_n="$(bash "$SCRIPT_DIR/gtd_check.sh" | awk -F'\t' '$1 == "stalled"' | count_lines)"
n_tickler="$(bash "$SCRIPT_DIR/gtd_list.sh" tickler | count_lines)"
n_tickler_due="$(bash "$SCRIPT_DIR/gtd_list.sh" tickler --due | count_lines)"
n_done_week="$(bash "$SCRIPT_DIR/gtd_list.sh" done --since "$(gtd_days_ago 7)" | count_lines)"

echo "════════════════════════════════════"
echo "  GTD Dashboard · memory/gtd/"
echo "════════════════════════════════════"
printf "  📥 Inbox to clarify   : %s\n" "$(count_inbox)"
printf "  ✅ Next Actions       : %s\n" "$n_next"
printf "  🎯 Projects           : %s (stalled≈ %s)\n" "$n_projects" "$stalled_n"
printf "  ⏳ Waiting For        : %s\n" "$n_waiting"
printf "  📅 Calendar (hard)    : %s\n" "$(count_calendar)"
printf "  🗂️  Tickler            : %s (%s due)\n" "$n_tickler" "$n_tickler_due"
printf "  💭 Someday/Maybe      : %s\n" "$n_someday"
printf "  🏁 Done, last 7 days  : %s\n" "$n_done_week"
echo "────────────────────────────────────"

# Alerts
inbox_n=$(count_inbox)
[ "$inbox_n" -gt 0 ] && echo "  ⚠️  Inbox has $inbox_n unclarified item(s) → run /gtd-clarify"
[ "$stalled_n" -gt 0 ] && echo "  ⚠️  ~$stalled_n project(s) lack a valid next action or are completed leftovers → /gtd-organize"
[ "$n_tickler_due" -gt 0 ] && echo "  ⚠️  $n_tickler_due tickle(s) now actionable → /gtd-organize"
echo "  🔭 The Weekly Review (Reflect) is the critical success factor → /gtd-review"
echo "════════════════════════════════════"
