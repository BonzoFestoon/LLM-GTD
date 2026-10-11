#!/usr/bin/env bash
# gtd_next_date.sh — read-only date arithmetic for recurring tickles, so update and organize
# never work out a date by hand. Plain awk: GNU and BSD/macOS give the same answer.
#
# Usage:
#   bash gtd_next_date.sh next <every> <tickle> <completed> [fixed|floating]
#       The recurring tickle's next date after a completion.
#       fixed (default): the first <tickle> + k*<every> (k >= 1) strictly after <completed> —
#         missed periods are skipped, never stacked; an early completion moves one period on.
#       floating: <completed> + <every>.
#   bash gtd_next_date.sh start <tickle> [<lead>]
#       The day organize creates the cycle's next action: <tickle> - <lead> (no lead: <tickle>).
#   bash gtd_next_date.sh add <date> <span>
#       <date> + <span>.
#   bash gtd_next_date.sh valid <span>
#       Exit 0 when <span> is a valid every: / lead: value, else 1.
#
# <every>, <lead> and <span> are <n><unit>, unit d | w | m | y (7d, 2w, 3m, 1y). Month and year
# arithmetic clamps to the month's last day: Jan 31 + 1m = Feb 28, Feb 29 + 1y = Feb 28.
# Dates are YYYY-MM-DD. Bad input prints a reason on stderr and exits 2.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"

usage() {
  sed -n '5,18p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

need_date() { gtd_is_date "$1" || { echo "not a YYYY-MM-DD date: '$1'" >&2; exit 2; }; }
need_span() { gtd_is_span "$1" || { echo "not a span like 7d, 2w, 3m, 1y: '$1'" >&2; exit 2; }; }

[ $# -ge 1 ] || usage
cmd="$1"; shift
case "$cmd" in
  next)
    [ $# -ge 3 ] || usage
    every="$1" tickle="$2" completed="$3" cadence="${4:-fixed}"
    need_span "$every"; need_date "$tickle"; need_date "$completed"
    case "$cadence" in fixed|floating) ;; *) echo "cadence must be fixed or floating: '$cadence'" >&2; exit 2 ;; esac
    awk -v every="$every" -v tickle="$tickle" -v done_on="$completed" -v cadence="$cadence" "$GTD_DATE_AWK"'
      BEGIN {
        n = substr(every, 1, length(every) - 1) + 0; u = substr(every, length(every), 1)
        if (cadence == "floating") { print gtd_add(done_on, n, u); exit }
        # k * every is added to the original tickle each time, so a month-end clamp happens once
        for (k = 1; ; k++) { c = gtd_add(tickle, k * n, u); if (c > done_on) break }
        print c
      }'
    ;;
  start)
    [ $# -ge 1 ] || usage
    need_date "$1"
    if [ -n "${2:-}" ]; then need_span "$2"; gtd_date_add "$1" "$2" -; else echo "$1"; fi
    ;;
  add)
    [ $# -ge 2 ] || usage
    need_date "$1"; need_span "$2"
    gtd_date_add "$1" "$2"
    ;;
  valid)
    [ $# -ge 1 ] || usage
    gtd_is_span "$1"
    ;;
  *) usage ;;
esac
