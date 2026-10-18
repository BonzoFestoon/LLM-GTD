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

# gtd_require_gtd_dir — stop if memory/gtd/ isn't under the resolved workspace. Names where the
# scripts looked and how they decide, so the agent fixes the location instead of guessing a path
# or running init and creating a second inbox (init/SKILL.md "One inbox per human").
gtd_require_gtd_dir() {
  [ -d "$GTD_WORKSPACE_ROOT/memory/gtd" ] && return 0
  echo "LLM-GTD: no memory/gtd/ under $GTD_WORKSPACE_ROOT." >&2
  if [ -n "${LLM_GTD_ROOT:-}" ]; then
    echo "  LLM_GTD_ROOT is set to that folder, but it has no memory/gtd/." >&2
  else
    echo "  LLM_GTD_ROOT is not set, so the scripts used the current directory." >&2
  fi
  echo "  GTD already set up elsewhere? Set LLM_GTD_ROOT to that folder (README: one canonical GTD" >&2
  echo "  folder). Don't run init here; that would start a second inbox. First-time setup only:" >&2
  echo "  bash gtd_init.sh" >&2
  exit 1
}

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

# Background jobs, for scripts that need several other scripts' output: run them at the same time,
# not one after another (each costs seconds on a large vault, more on Windows).
# gtd_jobs_init makes GTD_JOB_DIR, removed on exit; gtd_job NAME CMD... runs CMD in the background
# into $GTD_JOB_DIR/NAME (stderr still shows); gtd_jobs_wait waits for them all and fails if any did.
gtd_jobs_init() {
  GTD_JOB_DIR="$(mktemp -d)"
  GTD_JOB_PIDS=""
  trap 'rm -rf "$GTD_JOB_DIR"' EXIT
}
gtd_job() {
  local name="$1"
  shift
  "$@" > "$GTD_JOB_DIR/$name" &
  GTD_JOB_PIDS="$GTD_JOB_PIDS $!"
}
gtd_jobs_wait() {
  local p rc=0
  for p in $GTD_JOB_PIDS; do wait "$p" || rc=$?; done
  GTD_JOB_PIDS=""
  return $rc
}

# gtd_days_ago N — the date N days before today as YYYY-MM-DD (GNU date, then BSD/macOS date).
gtd_days_ago() {
  date -d "$1 days ago" +%Y-%m-%d 2>/dev/null || date -v-"$1"d +%Y-%m-%d
}

# gtd_days_ahead N — the date N days after today as YYYY-MM-DD (GNU date, then BSD/macOS date).
gtd_days_ahead() {
  date -d "+$1 days" +%Y-%m-%d 2>/dev/null || date -v+"$1"d +%Y-%m-%d
}

# Plain bash tests, no grep: these run once per note, and on Windows (Git Bash) every extra
# process costs tens of milliseconds. The regexes live in variables for bash 3.2.
GTD_DATE_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
GTD_SPAN_RE='^[1-9][0-9]*[dwmy]$'

# gtd_is_date TEXT — true for a well-formed YYYY-MM-DD.
gtd_is_date() {
  [[ $1 =~ $GTD_DATE_RE ]]
}

# gtd_is_span TEXT — true for a recurrence span <n><unit>: 7d, 2w, 3m, 1y (a tickle's every: / lead:).
gtd_is_span() {
  [[ $1 =~ $GTD_SPAN_RE ]]
}

# gtd_icontains TEXT PART — true when TEXT contains PART, ignoring case (no grep).
gtd_icontains() {
  local r=1
  shopt -s nocasematch
  [[ $1 == *"$2"* ]] && r=0
  shopt -u nocasematch
  return $r
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
  _gtd_from_title "$1"
  printf '%s\n' "$GTD_FROM_TITLE"
}

# _gtd_from_title VALUE — gtd_from_title into GTD_FROM_TITLE, for loops that can't afford $(...).
_gtd_from_title() {
  local t="$1"
  case "$t" in *\[\[*) t="${t#*\[\[}"; t="${t%%]]*}" ;; esac
  t="${t%%|*}"; t="${t%%#*}"; t="${t#memory/gtd/}"; t="${t#tickler/}"; t="${t%.md}"
  GTD_FROM_TITLE="$t"
}

# gtd_open_from DIR — one line per open next action in DIR (memory/gtd/next-actions):
# "<tickle title><SEP><action filename without .md>" for each action that has a from: link.
gtd_open_from() {
  [ -d "$1" ] || return 0
  gtd_notes_in "$1"
  gtd_fm_each _gtd_open_from_one -- ${GTD_NOTES[@]+"${GTD_NOTES[@]}"}
}
_gtd_open_from_one() {
  local base="${1##*/}"
  [ -n "${FM_from:-}" ] || return 0
  _gtd_from_title "$FM_from"
  printf '%s%s%s\n' "$GTD_FROM_TITLE" "$SEP" "${base%.md}"
}

# SEP is a unit separator (0x1f), not tab: bash's `read` treats IFS whitespace
# characters (including tab) as collapsing, which silently swallows empty fields
# between two consecutive delimiters. 0x1f is not IFS whitespace, so empty fields
# (a missing Project:, an empty context) survive the round trip.
SEP=$'\x1f'

# GTD_ITEM_SEP (0x1d) joins a YAML block list's items in one FM_<key> value (gtd_fm_each).
GTD_ITEM_SEP=$'\x1d'

# GTD_FM_AWK — the frontmatter line parser frontmatter_kv and frontmatter_kv_files share:
# fm_kv(LINE) prints "key<SEP>value" for a simple frontmatter line; strips trailing
# " # comment", surrounding quotes, and [bracket] array syntax down to a comma list. It returns
# the key when the value is empty (a YAML block list may follow), "-" for any other key line,
# and "" for a line that isn't one. fm_item(KEY, LINE) prints "+key<SEP>item" for one
# "  - item" line of KEY's block list, its quotes stripped.
GTD_FM_AWK='
function fm_unquote(val) {
  sub(/^[[:space:]]+/, "", val)
  sub(/[[:space:]]+$/, "", val)
  if (val ~ /^".*"$/) {
    # a quoted string: drop the quotes and unescape \" — commas inside are text, not a list
    val = substr(val, 2, length(val) - 2)
    gsub(/\\"/, "\"", val)
  }
  return val
}
function fm_kv(line,   key, val) {
  sub(/[[:space:]]+#.*$/, "", line)
  if (!match(line, /^[A-Za-z_][A-Za-z0-9_-]*:/)) return ""
  key = substr(line, 1, RLENGTH-1)
  val = fm_unquote(substr(line, RLENGTH+1))
  if (substr(val, 1, 1) == "[" && substr(val, 1, 2) != "[[") {
    # a [a, b] list -> a,b
    gsub(/^\[|\]$/, "", val)
    gsub(/[[:space:]]*,[[:space:]]*/, ",", val)
  }
  printf "%s%s%s\n", key, SEP, val
  return (val == "") ? key : "-"
}
function fm_item(key, line) {
  sub(/[[:space:]]+#.*$/, "", line)
  sub(/^[[:space:]]*-[[:space:]]+/, "", line)
  printf "+%s%s%s\n", key, SEP, fm_unquote(line)
}
'

# frontmatter_kv FILE — "key<SEP>value" per simple frontmatter line (see GTD_FM_AWK).
frontmatter_kv() {
  awk -v SEP="$SEP" "$GTD_FM_AWK"'
    /^---[[:space:]]*$/ { infm++; if (infm==2) exit; next }
    infm==1 && lk != "" && /^[[:space:]]*-[[:space:]]/ { fm_item(lk, $0); next }
    infm==1 { r = fm_kv($0); if (r != "") lk = (r == "-") ? "" : r }
  ' "$1"
}

# GTD_FILE_MARK (0x1e) starts each note's block in frontmatter_kv_files' output; no path or
# property holds it.
GTD_FILE_MARK=$'\x1e'

# frontmatter_kv_files [MARKER] — frontmatter_kv for many notes in one awk. Reads one path per
# line on stdin (so no argument-length limit) and prints, per note in that order, "<MARK><path>"
# and then its "key<SEP>value" lines. With MARKER, also "@body<SEP><text>" for the first body
# line holding MARKER, with the text after it. An empty or unreadable note still gets its
# "<MARK><path>" line.
frontmatter_kv_files() {
  awk -v SEP="$SEP" -v MARK="$GTD_FILE_MARK" -v MARKER="${1:-}" "$GTD_FM_AWK"'
    {
      f = $0; infm = 0; lk = ""
      printf "%s%s\n", MARK, f
      while ((getline line < f) > 0) {
        if (infm < 2 && line ~ /^---[[:space:]]*$/) {
          infm++
          if (infm == 2 && MARKER == "") break
          continue
        }
        if (infm == 1) {
          if (lk != "" && line ~ /^[[:space:]]*-[[:space:]]/) { fm_item(lk, line); continue }
          r = fm_kv(line); if (r != "") lk = (r == "-") ? "" : r
          continue
        }
        if (infm == 2 && (p = index(line, MARKER)) > 0) {
          line = substr(line, p + length(MARKER)); sub(/^[[:space:]]+/, "", line)
          printf "@body%s%s\n", SEP, line
          break
        }
      }
      close(f)
    }
  '
}

# gtd_notes_in DIR — GTD_NOTES becomes DIR's notes (*.md, README.md left out), in glob order.
# Expand it as ${GTD_NOTES[@]+"${GTD_NOTES[@]}"}: an empty array trips set -u on bash 3.2.
gtd_notes_in() {
  local f
  GTD_NOTES=()
  for f in "$1"/*.md; do
    [ -e "$f" ] || continue
    [ "${f##*/}" = README.md ] && continue
    GTD_NOTES+=("$f")
  done
}

# gtd_fm_each CALLBACK [MARKER] -- FILE... — read every FILE's frontmatter with one awk, then
# call CALLBACK FILE once per file, in order, in this shell (so its variables and counters stick).
# During the call each property is in FM_<key>, any character other than a letter, digit or _
# turned into _ (follow-up -> FM_follow_up); when a key repeats, the first line wins. Read them
# as "${FM_key:-}". A YAML block list's items are joined with GTD_ITEM_SEP. With MARKER,
# GTD_FM_BODY holds the @body text (see frontmatter_kv_files).
# Loop over notes this way, not with frontmatter_kv per note: on Windows each awk costs tens of
# milliseconds, and a vault has hundreds of notes.
gtd_fm_each() {
  local _fe_cb="$1" _fe_marker="" _fe_line _fe_cur="" _fe_started=0 _fe_k _fe_v _fe_name _fe_lk=""
  shift
  if [ "${1:-}" != "--" ]; then _fe_marker="${1:-}"; shift; fi
  shift
  [ $# -gt 0 ] || return 0
  while IFS= read -r _fe_line <&3; do
    if [ "${_fe_line:0:1}" = "$GTD_FILE_MARK" ]; then
      [ "$_fe_started" -eq 0 ] || "$_fe_cb" "$_fe_cur"
      _fe_started=1; _fe_cur="${_fe_line:1}"
      for _fe_name in ${!FM_@}; do unset "$_fe_name"; done
      GTD_FM_BODY=""; _fe_lk=""
      continue
    fi
    _fe_k="${_fe_line%%"$SEP"*}"; _fe_v="${_fe_line#*"$SEP"}"
    if [ "$_fe_k" = "@body" ]; then GTD_FM_BODY="$_fe_v"; continue; fi
    if [ "${_fe_k:0:1}" = "+" ]; then
      # one item of a block list, kept only under its key's first (winning) line
      _fe_name="FM_${_fe_k:1}"; _fe_name="${_fe_name//[^A-Za-z0-9_]/_}"
      [ "$_fe_name" = "$_fe_lk" ] || continue
      if [ -z "${!_fe_name:-}" ]; then printf -v "$_fe_name" '%s' "$_fe_v"
      else printf -v "$_fe_name" '%s%s%s' "${!_fe_name}" "$GTD_ITEM_SEP" "$_fe_v"; fi
      continue
    fi
    _fe_name="FM_${_fe_k//[^A-Za-z0-9_]/_}"
    _fe_lk=""
    [ -n "${!_fe_name+x}" ] || { printf -v "$_fe_name" '%s' "$_fe_v"; _fe_lk="$_fe_name"; }
  done 3< <(printf '%s\n' "$@" | frontmatter_kv_files "$_fe_marker")
  [ "$_fe_started" -eq 0 ] || "$_fe_cb" "$_fe_cur"
}

# --- dependencies (depends_on:) ---------------------------------------------------
# A next action or project may wait on next actions, waiting-for items and projects
# (references/list-definitions.md "Dependencies"). The link lives only on the item that waits;
# what an item blocks is worked out by searching for links to it (gtd_list.sh --depends-on).

# gtd_dep_needed DIR... — true when any note under DIR has a depends_on: line, so a script builds
# the index only when there is something to resolve (one grep, not one per note).
gtd_dep_needed() {
  local d
  local -a dirs=()
  for d in "$@"; do [ -d "$d" ] && dirs+=("$d"); done
  [ ${#dirs[@]} -gt 0 ] || return 1
  grep -rqs --include='*.md' '^depends_on:' "${dirs[@]}"
}

# gtd_dep_index — read once what resolving needs, before any gtd_fm_each loop that calls
# gtd_dep_eval (gtd_fm_each can't run inside its own callback): GTD_DEP_DONE holds
# "<path><SEP><result>" per finished item ("_done/<Title>", or "_done/<Name>/README" for a
# project), GTD_DEP_CYCLES "next-actions/<Title>" per open action that is one cycle of a routine.
gtd_dep_index() {
  local g="$GTD_WORKSPACE_ROOT/memory/gtd" f line
  local -a notes=()
  GTD_DEP_DONE=$'\n'; GTD_DEP_CYCLES=$'\n'
  for f in "$g"/_done/*.md "$g"/_done/*/README.md; do
    [ -e "$f" ] || continue
    [ "$f" = "$g/_done/README.md" ] && continue
    notes+=("$f")
  done
  [ ${#notes[@]} -eq 0 ] || gtd_fm_each _gtd_dep_index_done -- "${notes[@]}"
  while IFS= read -r line; do
    [ -n "$line" ] && GTD_DEP_CYCLES="${GTD_DEP_CYCLES}next-actions/${line#*"$SEP"}"$'\n'
  done < <(gtd_open_from "$g/next-actions")
  GTD_DEP_INDEXED=1
}
_gtd_dep_index_done() {
  local rel="${1#"$GTD_WORKSPACE_ROOT/memory/gtd/"}"
  GTD_DEP_DONE="$GTD_DEP_DONE${rel%.md}$SEP${FM_result:-done}"$'\n'
}

# gtd_dep_state TARGET — resolve one depends_on: link target (the part of the [[...]] before | or
# #, relative to memory/gtd/). Sets DEP_STATE to open | done | cancelled | missing | bad-target,
# DEP_NAME to its title (a project's name), DEP_PATH to where it is now (next-actions/<Title>,
# waiting-for/<Title>, projects/<Name>/README, _done/<Title> or _done/<Name>/README; empty when
# missing) and, for bad-target, DEP_WHY. A target is looked for where its link says first, then by
# its title in the other places (a link not yet rewritten after a move still resolves). Anything
# finished that isn't result: cancelled counts as done. Plain bash: no processes.
gtd_dep_state() {
  local g="$GTD_WORKSPACE_ROOT/memory/gtd" t="$1" kind=any name l key r
  DEP_STATE=missing; DEP_PATH=""; DEP_WHY=""
  t="${t#memory/gtd/}"; t="${t%.md}"
  case "$t" in
    projects/*/README|_done/*/README) kind=project; name="${t#*/}"; name="${name%/README}" ;;
    projects/*/*) DEP_STATE=bad-target; DEP_WHY="a project's support doc, not the project ([[projects/<Name>/README|<Name>]])"; name="${t##*/}" ;;
    projects/*) kind=project; name="${t#projects/}" ;;
    next-actions/*|waiting-for/*|_done/*) kind=item; name="${t#*/}" ;;
    tickler/*|someday-maybe/*) DEP_STATE=bad-target; DEP_WHY="a ${t%%/*} note never completes as a dependency"; name="${t#*/}" ;;
    */*) DEP_STATE=bad-target; DEP_WHY="not a next action, waiting-for item or project"; name="${t##*/}" ;;
    *) name="$t" ;;
  esac
  DEP_NAME="$name"
  [ "$DEP_STATE" = missing ] || return 0
  if [ "$kind" != item ] && [ -f "$g/projects/$name/README.md" ]; then
    DEP_STATE=open; DEP_PATH="projects/$name/README"; return 0
  fi
  if [ "$kind" != project ]; then
    for l in next-actions waiting-for; do
      [ -f "$g/$l/$name.md" ] || continue
      DEP_STATE=open; DEP_PATH="$l/$name"
      case "$GTD_DEP_CYCLES" in
        *$'\n'"$DEP_PATH"$'\n'*) DEP_STATE=bad-target; DEP_WHY="one cycle of a routine (from:), which comes back every period" ;;
      esac
      return 0
    done
  fi
  for key in "_done/$name/README" "_done/$name"; do
    [ "$kind" = project ] && [ "$key" = "_done/$name" ] && continue
    [ "$kind" = item ] && [ "$key" = "_done/$name/README" ] && continue
    case "$GTD_DEP_DONE" in
      *$'\n'"$key$SEP"*)
        r="${GTD_DEP_DONE#*$'\n'"$key$SEP"}"; r="${r%%$'\n'*}"
        DEP_PATH="$key"
        if [ "$r" = cancelled ]; then DEP_STATE=cancelled; else DEP_STATE=done; fi
        return 0 ;;
    esac
  done
  if [ "$kind" = any ]; then
    for l in tickler someday-maybe; do
      [ -f "$g/$l/$name.md" ] || continue
      DEP_STATE=bad-target; DEP_PATH="$l/$name"; DEP_WHY="a $l note never completes as a dependency"
      return 0
    done
  fi
  return 0
}

# gtd_dep_eval VALUE SELF — all of one note's depends_on: links (VALUE as gtd_fm_each gives it;
# SELF the note's own path, next-actions/<Title> or projects/<Name>/README). Sets DEP_BLOCKED to
# no (no links, or all done) | yes (one still open) | broken (one cancelled, missing, or not
# something that can be depended on, or a VALUE with no [[link]] at all: organize asks); DEP_WAITS
# to the titles not yet done, "; "-joined, a broken one tagged (cancelled) / (missing) / (bad
# target) / (not a link); DEP_LINKS to how many links VALUE holds; and DEP_EACH to one
# "<target><SEP><state><SEP><path><SEP><why><SEP><title>" line per link.
gtd_dep_eval() {
  local v="$1" self="$2" t open=0 broken=0 tag
  DEP_BLOCKED=no; DEP_WAITS=""; DEP_LINKS=0; DEP_EACH=""
  [ -n "$v" ] || return 0
  if [ "${GTD_DEP_INDEXED:-0}" != 1 ]; then echo "gtd_dep_eval: run gtd_dep_index first" >&2; return 1; fi
  while [[ $v == *'[['*']]'* ]]; do
    v="${v#*\[\[}"; t="${v%%]]*}"; v="${v#*]]}"
    t="${t%%|*}"; t="${t%%#*}"
    DEP_LINKS=$((DEP_LINKS + 1))
    gtd_dep_state "$t"
    if [ -n "$self" ] && [ "$DEP_PATH" = "$self" ]; then DEP_STATE=bad-target; DEP_WHY="the note itself"; fi
    DEP_EACH="$DEP_EACH$t$SEP$DEP_STATE$SEP$DEP_PATH$SEP$DEP_WHY$SEP$DEP_NAME"$'\n'
    case "$DEP_STATE" in
      done) continue ;;
      open) open=1; tag="" ;;
      cancelled) broken=1; tag=" (cancelled)" ;;
      missing) broken=1; tag=" (missing)" ;;
      *) broken=1; tag=" (bad target)" ;;
    esac
    DEP_WAITS="${DEP_WAITS:+$DEP_WAITS; }$DEP_NAME$tag"
  done
  if [ "$DEP_LINKS" -eq 0 ]; then broken=1; DEP_WAITS="${1//"$GTD_ITEM_SEP"/; } (not a link)"; fi
  if [ $broken -eq 1 ]; then DEP_BLOCKED=broken; elif [ $open -eq 1 ]; then DEP_BLOCKED=yes; fi
  return 0
}
