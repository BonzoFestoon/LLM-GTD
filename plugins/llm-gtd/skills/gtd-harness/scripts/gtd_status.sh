#!/usr/bin/env bash
# gtd_status.sh — read every list in memory/gtd/ and print a GTD dashboard (pure bash, works on all three platforms)
# Usage: bash gtd_status.sh [--from DIR]
#   --from DIR: reuse output a caller already has — DIR/check (gtd_check.sh), DIR/tagged
#   (gtd_tagged.sh), DIR/done-week (gtd_list.sh done --since 7 days ago); any missing one is run.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"
VAULT_ROOT="$GTD_WORKSPACE_ROOT"
GTD_DIR="$VAULT_ROOT/memory/gtd"

FROM=""
while [ $# -gt 0 ]; do
  case "$1" in
    --from) FROM="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

gtd_require_gtd_dir
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

count_lines() {
  grep -c . || true
}

# The three slow sources run at the same time; a caller that already has one (gtd_review_prep.sh)
# passes it with --from DIR as DIR/check, DIR/tagged or DIR/done-week.
gtd_jobs_init
source_of() {
  if [ -n "$FROM" ] && [ -f "$FROM/$1" ]; then echo "$FROM/$1"; else echo "$GTD_JOB_DIR/$1"; fi
}
[ -n "$FROM" ] && [ -f "$FROM/check" ] || gtd_job check bash "$SCRIPT_DIR/gtd_check.sh"
[ -n "$FROM" ] && [ -f "$FROM/tagged" ] || gtd_job tagged bash "$SCRIPT_DIR/gtd_tagged.sh"
[ -n "$FROM" ] && [ -f "$FROM/done-week" ] || gtd_job done-week bash "$SCRIPT_DIR/gtd_list.sh" done --since "$(gtd_days_ago 7)"

# Notes counted the way gtd_list.sh finds them (README.md and _done/ never count), in this shell.
count_notes() {
  gtd_notes_in "$GTD_DIR/$1"
  echo "${#GTD_NOTES[@]}"
}
n_next="$(count_notes next-actions)"
n_waiting="$(count_notes waiting-for)"
n_someday="$(count_notes someday-maybe)"
n_tickler="$(count_notes tickler)"
n_projects=0
for f in "$GTD_DIR"/projects/*/README.md; do
  [ -e "$f" ] || continue
  n_projects=$((n_projects + 1))
done
# Recurring tickles: a valid every: (gtd_list.sh tickler --recurring).
n_tickler_rec=0
count_recurring() {
  if gtd_is_span "${FM_every:-}"; then n_tickler_rec=$((n_tickler_rec + 1)); fi
}
gtd_notes_in "$GTD_DIR/tickler"
gtd_fm_each count_recurring -- ${GTD_NOTES[@]+"${GTD_NOTES[@]}"}

gtd_jobs_wait
# Stalled projects and due / overdue tickles come from gtd_check.sh's findings: the same tests as
# gtd_list.sh tickler --due / --overdue. A tickled project is on hold, so it is never stalled.
check_out="$(source_of check)"
stalled_n="$(awk -F'\t' '$1 == "stalled"' "$check_out" | count_lines)"
n_tickler_due="$(awk -F'\t' '$1 == "tickler-due"' "$check_out" | count_lines)"
n_tickler_over="$(awk -F'\t' '$1 == "tickler-overdue"' "$check_out" | count_lines)"
tickler_rec=""
[ "$n_tickler_rec" -eq 0 ] || tickler_rec=" · $n_tickler_rec recurring, $n_tickler_over overdue"
n_tagged="$(awk -F'\t' '$2 != "updates=0"' "$(source_of tagged)" | count_lines)"
n_done_week="$(count_lines < "$(source_of done-week)")"

echo "════════════════════════════════════"
echo "  GTD Dashboard · memory/gtd/"
echo "════════════════════════════════════"
printf "  📥 Inbox to clarify   : %s\n" "$(count_inbox)"
printf "  📝 Tagged updates     : %s\n" "$n_tagged"
printf "  ✅ Next Actions       : %s\n" "$n_next"
printf "  🎯 Projects           : %s (stalled≈ %s)\n" "$n_projects" "$stalled_n"
printf "  ⏳ Waiting For        : %s\n" "$n_waiting"
printf "  📅 Calendar (hard)    : %s\n" "$(count_calendar)"
printf "  🗂️  Tickler            : %s (%s due)%s\n" "$n_tickler" "$n_tickler_due" "$tickler_rec"
printf "  💭 Someday/Maybe      : %s\n" "$n_someday"
printf "  🏁 Done, last 7 days  : %s\n" "$n_done_week"
echo "────────────────────────────────────"

# Alerts
inbox_n=$(count_inbox)
[ "$inbox_n" -gt 0 ] && echo "  ⚠️  Inbox has $inbox_n unclarified item(s) → run /gtd-clarify"
[ "$n_tagged" -gt 0 ] && echo "  ⚠️  $n_tagged tagged note(s) to apply → /gtd-update"
[ "$stalled_n" -gt 0 ] && echo "  ⚠️  ~$stalled_n project(s) lack a valid next action or are completed leftovers → /gtd-organize"
[ "$n_tickler_due" -gt 0 ] && echo "  ⚠️  $n_tickler_due tickle(s) now actionable → /gtd-organize"
[ "$n_tickler_over" -gt 0 ] && echo "  ⚠️  $n_tickler_over routine(s) overdue → /gtd-engage (do it, skip this cycle, or change the rule)"
echo "  🔭 The Weekly Review (Reflect) is the critical success factor → /gtd-review"
echo "════════════════════════════════════"
