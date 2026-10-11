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

# Layout (see references/list-definitions.md "Layout"): one folder of notes per list under
# memory/gtd/, plus the inbox, calendar and horizons as files. This is the only layout since 2.0.0.

# Per-item lists: one folder each under memory/gtd/. General reference is not one of them —
# it lives at the workspace root (reference/), outside memory/gtd/.
GTD_NOTE_LISTS="next-actions waiting-for projects someday-maybe tickler"

# gtd_refuse_single_file — stop if memory/gtd/ still holds LLM-GTD 1.x single-file lists. Every
# command would silently miss their items, so refuse with the way out instead of half-reading them.
gtd_refuse_single_file() {
  local l found=""
  for l in next-actions waiting-for projects someday-maybe reference done; do
    [ -f "$GTD_WORKSPACE_ROOT/memory/gtd/$l.md" ] && found="$found $l.md"
  done
  [ -z "$found" ] && return 0
  echo "LLM-GTD: memory/gtd/ holds single-file lists (${found# })." >&2
  echo "  Since 2.0.0 LLM-GTD keeps one note per item only. Migrate first with LLM-GTD 1.17.x's" >&2
  echo "  scripts/gtd_migrate_to_notes.sh (dry run, then --apply), then run this again." >&2
  exit 4
}

# gtd_days_ago N — the date N days before today as YYYY-MM-DD (GNU date, then BSD/macOS date).
gtd_days_ago() {
  date -d "$1 days ago" +%Y-%m-%d 2>/dev/null || date -v-"$1"d +%Y-%m-%d
}

# gtd_days_ahead N — the date N days after today as YYYY-MM-DD (GNU date, then BSD/macOS date).
gtd_days_ahead() {
  date -d "+$1 days" +%Y-%m-%d 2>/dev/null || date -v+"$1"d +%Y-%m-%d
}

# gtd_is_date TEXT — true for a well-formed YYYY-MM-DD.
gtd_is_date() {
  echo "$1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
}

# gtd_is_span TEXT — true for a recurrence span <n><unit>: 7d, 2w, 3m, 1y (a tickle's every: / lead:).
gtd_is_span() {
  echo "$1" | grep -qE '^[1-9][0-9]*[dwmy]$'
}

# Date arithmetic in plain awk, so GNU and BSD/macOS give the same answer. Months and years add
# calendar months and clamp to the month's last day (Jan 31 + 1m = Feb 28; Feb 29 + 1y = Feb 28).
GTD_DATE_AWK='
function gtd_jdn(y, m, d,   a) { a = int((14 - m) / 12); y = y + 4800 - a; m = m + 12 * a - 3
  return d + int((153 * m + 2) / 5) + 365 * y + int(y / 4) - int(y / 100) + int(y / 400) - 32045 }
function gtd_ymd(j,   a, b, c, d, e, m) { a = j + 32044; b = int((4 * a + 3) / 146097); c = a - int(146097 * b / 4)
  d = int((4 * c + 3) / 1461); e = c - int(1461 * d / 4); m = int((5 * e + 2) / 153)
  return sprintf("%04d-%02d-%02d", 100 * b + d - 4800 + int(m / 10), m + 3 - 12 * int(m / 10), e - int((153 * m + 2) / 5) + 1) }
function gtd_dim(y, m) { if (m == 2) return (y % 4 == 0 && (y % 100 != 0 || y % 400 == 0)) ? 29 : 28
  return (m == 4 || m == 6 || m == 9 || m == 11) ? 30 : 31 }
# gtd_add DATE N UNIT — DATE plus N (may be negative) days / weeks / months / years
function gtd_add(date, n, unit,   p, y, m, d, t) { split(date, p, "-"); y = p[1] + 0; m = p[2] + 0; d = p[3] + 0
  if (unit == "d") return gtd_ymd(gtd_jdn(y, m, d) + n)
  if (unit == "w") return gtd_ymd(gtd_jdn(y, m, d) + 7 * n)
  if (unit == "y") n = n * 12
  t = y * 12 + m - 1 + n; y = int(t / 12); m = t % 12 + 1
  if (d > gtd_dim(y, m)) d = gtd_dim(y, m)
  return sprintf("%04d-%02d-%02d", y, m, d) }
'

# gtd_date_add DATE SPAN [-] — DATE plus SPAN (7d, 2w, 3m, 1y); a third argument "-" subtracts.
gtd_date_add() {
  awk -v date="$1" -v span="$2" -v sign="${3:-+}" "$GTD_DATE_AWK"'
    BEGIN { n = substr(span, 1, length(span) - 1) + 0; if (sign == "-") n = -n
            print gtd_add(date, n, substr(span, length(span), 1)) }'
}

# gtd_from_title VALUE — the tickle title a next action's from: link points at:
# "[[tickler/Water the plants|Water the plants]]" -> Water the plants (a bare [[Title]] too).
gtd_from_title() {
  local t="$1"
  case "$t" in *\[\[*) t="${t#*\[\[}"; t="${t%%]]*}" ;; esac
  t="${t%%|*}"; t="${t%%#*}"; t="${t#memory/gtd/}"; t="${t#tickler/}"; t="${t%.md}"
  printf '%s\n' "$t"
}

# gtd_open_from DIR — one line per open next action in DIR (memory/gtd/next-actions):
# "<tickle title><SEP><action filename without .md>" for each action that has a from: link.
gtd_open_from() {
  local f base v
  [ -d "$1" ] || return 0
  for f in "$1"/*.md; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .md)"
    [ "$base" = "README" ] && continue
    v="$(frontmatter_kv "$f" | awk -F"$SEP" '$1 == "from" { print $2; exit }')"
    [ -n "$v" ] || continue
    printf '%s%s%s\n' "$(gtd_from_title "$v")" "$SEP" "$base"
  done
}

# SEP is a unit separator (0x1f), not tab: bash's `read` treats IFS whitespace
# characters (including tab) as collapsing, which silently swallows empty fields
# between two consecutive delimiters. 0x1f is not IFS whitespace, so empty fields
# (a missing Project:, an empty context) survive the round trip.
SEP=$'\x1f'

# frontmatter_kv FILE — "key<SEP>value" per simple frontmatter line; strips trailing
# " # comment", surrounding quotes, and [bracket] array syntax down to a comma list.
frontmatter_kv() {
  awk -v SEP="$SEP" '
    /^---[[:space:]]*$/ { infm++; if (infm==2) exit; next }
    infm==1 {
      line = $0
      sub(/[[:space:]]+#.*$/, "", line)
      if (!match(line, /^[A-Za-z_][A-Za-z0-9_-]*:/)) next
      key = substr(line, 1, RLENGTH-1)
      val = substr(line, RLENGTH+1)
      sub(/^[[:space:]]+/, "", val)
      sub(/[[:space:]]+$/, "", val)
      if (val ~ /^".*"$/) {
        # a quoted string: drop the quotes and unescape \" — commas inside are text, not a list
        val = substr(val, 2, length(val) - 2)
        gsub(/\\"/, "\"", val)
      } else if (substr(val, 1, 1) == "[" && substr(val, 1, 2) != "[[") {
        # a [a, b] list -> a,b
        gsub(/^\[|\]$/, "", val)
        gsub(/[[:space:]]*,[[:space:]]*/, ",", val)
      }
      printf "%s%s%s\n", key, SEP, val
    }
  ' "$1"
}
