#!/usr/bin/env bash
# gtd_list.sh — read-only: print one compact line per item in a GTD list, regardless of
# which layout (single-file or per-item) is live. Engage, organize, review and update call
# this instead of opening every note, so the AI does not get slower as notes multiply.
#
# Usage:
#   bash gtd_list.sh <list> [--max-time N] [--energy E] [--context C] [--project SUBSTRING]
#   bash gtd_list.sh done [--since YYYY-MM-DD] [--project SUBSTRING] [--problems]
#   bash gtd_list.sh tickler [--due | --within N] [--project SUBSTRING]
#
# <list> is a bare list name: next-actions, waiting-for, projects, someday-maybe,
# or reference (the folder-backed lists in per-item mode; reference/ sits at the
# workspace root, not under memory/gtd/).
#
# Per-item mode (memory/gtd/<list>/ is a directory): reads each note's YAML frontmatter,
# skipping README.md. Single-file mode (memory/gtd/<list>.md): falls back to parsing the
# list's own bullet/heading format. --max-time/--energy/--context are next-actions' lenses; on a
# list with no such field they match nothing. --project matches by substring
# against whatever the item's project link/field contains.
#
# Output: one tab-separated line per item — id, then key=value columns for that list, then the
# title last ("-" for a field the item doesn't carry):
#   next-actions   id  time=  energy=  context=  project=  due=  title
#   waiting-for    id  person=  delegated=  follow-up=  project=  title
#   someday-maybe  id  trigger=  title
#   projects       id  project=  name -- outcome
#   reference      id  title
#   done           id  completed=  result=  list=  project=  problems=  title
#   tickler        id  tickle=  project=  title
# Only `done` reads the done record (memory/gtd/_done/, or done.md in the single-file layout);
# no active list ever includes a finished item. For done: --since keeps completed >= DATE,
# --project matches the project link (or a finished project's own name), and --problems keeps
# only items whose "Problems and fixes" records a real problem (problems=yes).
# The tickler (memory/gtd/tickler/, per-item layout only) holds committed things that can't be
# acted on until their tickle date. --due keeps tickles dated on or before today; --within N keeps
# tickles dated after today and on or before today + N days (the two never overlap); a tickle with
# no valid date matches neither. In the single-file layout, or with no tickler/ folder, it lists
# nothing.
#
# Compatible with macOS bash 3.2 (no associative arrays / mapfile) — see gtd_init.sh's note.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"
GTD_DIR="$GTD_WORKSPACE_ROOT/memory/gtd"

if [ $# -eq 0 ]; then
  echo "Usage: gtd_list.sh <list> [--max-time N] [--energy E] [--context C] [--project SUBSTRING]" >&2
  exit 2
fi

LIST="${1%.md}"
shift

MAX_TIME=""
ENERGY=""
CONTEXT=""
PROJECT=""
SINCE=""
PROBLEMS=0
DUE=0
WITHIN=""
while [ $# -gt 0 ]; do
  case "$1" in
    --max-time) MAX_TIME="$2"; shift 2 ;;
    --energy) ENERGY="$2"; shift 2 ;;
    --context) CONTEXT="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --problems) PROBLEMS=1; shift ;;
    --due) DUE=1; shift ;;
    --within) WITHIN="$2"; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

if [ ! -d "$GTD_DIR" ]; then
  echo "memory/gtd/ does not exist. Run first: bash gtd_init.sh" >&2
  exit 1
fi

# normalize_energy TEXT — "low energy" / "deep work" / "low-emotional" -> low|medium|deep|low-emotional
normalize_energy() {
  local e
  e="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  case "$e" in
    *low-emotional*) echo "low-emotional" ;;
    *deep*) echo "deep" ;;
    *medium*) echo "medium" ;;
    *low*) echo "low" ;;
    *) echo "$e" | sed -E 's/[[:space:]]*(energy|work)[[:space:]]*//g' ;;
  esac
}

# first_int TEXT — the first integer substring, or empty
first_int() {
  echo "$1" | grep -oE '[0-9]+' | head -n1
}

# passes_lenses TIME ENERGY CONTEXT PROJECT — apply whichever of the 4 filters were set;
# an unset filter always passes; a filter with nothing to compare against fails.
passes_lenses() {
  local t="$1" e="$2" c="$3" p="$4"
  if [ -n "$MAX_TIME" ]; then
    local ti; ti="$(first_int "$t")"
    [ -n "$ti" ] || return 1
    [ "$ti" -le "$MAX_TIME" ] || return 1
  fi
  if [ -n "$ENERGY" ]; then
    [ "$(normalize_energy "$e")" = "$(normalize_energy "$ENERGY")" ] || return 1
  fi
  if [ -n "$CONTEXT" ]; then
    echo "$c" | grep -qi "$CONTEXT" || return 1
  fi
  if [ -n "$PROJECT" ]; then
    echo "$p" | grep -qi "$PROJECT" || return 1
  fi
  return 0
}

# emit ID TITLE [VALUE ...] — the values follow this list's COLUMNS order (set below), so
# every list prints a fixed, self-describing shape.
emit() {
  local id="${1:--}" title="$2" out col v
  shift 2
  out="$id"
  for col in $COLUMNS; do
    v="${1:-}"
    [ $# -gt 0 ] && shift
    out="$out"$'\t'"$col=${v:--}"
  done
  printf '%s\t%s\n' "$out" "$title"
}

case "$LIST" in
  next-actions) COLUMNS="time energy context project due" ;;
  waiting-for) COLUMNS="person delegated follow-up project" ;;
  someday-maybe) COLUMNS="trigger" ;;
  projects) COLUMNS="project" ;;
  done) COLUMNS="completed result list project problems" ;;
  tickler) COLUMNS="tickle project" ;;
  *) COLUMNS="" ;;
esac

# --- done record (both layouts) ------------------------------------------------

# has_problem TEXT — "yes" unless the Problems and fixes text is empty or says nothing was noted
has_problem() {
  case "$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/^[[:space:]]+|[[:space:]]*\.?[[:space:]]*$//g')" in
    ""|none|"none noted"|n/a|-) echo no ;;
    *) echo yes ;;
  esac
}

emit_done() {
  # emit_done ID TITLE COMPLETED RESULT LIST PROJECT PROBLEMS
  # YYYY-MM-DD sorts as text; an item with no completed date can't be placed, so --since drops it.
  if [ -n "$SINCE" ]; then
    [ -n "$3" ] && [ ! "$3" \< "$SINCE" ] || return 0
  fi
  [ -z "$PROJECT" ] || echo "$6" | grep -qi -- "$PROJECT" || return 0
  [ "$PROBLEMS" -eq 0 ] || [ "$7" = "yes" ] || return 0
  emit "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

list_done_per_item() {
  local dir="$GTD_DIR/_done" f rel title id completed result from project problems key val
  # Flat done notes, plus one folder per finished project (_done/<Project name>/README.md).
  for f in "$dir"/*.md "$dir"/*/README.md; do
    [ -e "$f" ] || continue
    rel="${f#"$dir"/}"
    [ "$rel" = "README.md" ] && continue
    case "$rel" in */README.md) title="${rel%/README.md}" ;; *) title="${rel%.md}" ;; esac
    id="" completed="" result="" from="" project=""
    while IFS="$SEP" read -r key val; do
      case "$key" in
        id) id="$val" ;;
        completed) completed="$val" ;;
        result) result="$val" ;;
        list) from="$val" ;;
        project) project="$val" ;;
      esac
    done < <(frontmatter_kv "$f")
    [ "$from" = "projects" ] && project="$title"
    problems="$(has_problem "$(awk '
      /^---[[:space:]]*$/ && fm < 2 { fm++; next }
      fm >= 2 && /Problems and fixes:/ { sub(/.*Problems and fixes:[[:space:]]*/, ""); print; exit }
    ' "$f")")"
    emit_done "$id" "$title" "$completed" "$result" "$from" "$project" "$problems"
  done
}

# done.md: "## YYYY-MM-DD" headings, each with "- [x] title · From: list · Result: r · Project: … ^id"
# lines and indented "  - Problems and fixes: …" sub-bullets.
list_done_single() {
  local file="$GTD_DIR/done.md" id title completed result from project probtext
  [ -f "$file" ] || return 0
  awk -v SEP="$SEP" '
    function flush() {
      if (have) printf "%s%s%s%s%s%s%s%s%s%s%s%s%s\n", id, SEP, title, SEP, date, SEP, result, SEP, from, SEP, project, SEP, prob
      have = 0
    }
    /^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ { flush(); date = substr($0, 4, 10); next }
    /^- \[x\] / {
      flush()
      line = $0; sub(/^- \[x\] /, "", line)
      id = ""
      if (match(line, /[[:space:]]\^[A-Za-z0-9_-]+$/)) { id = substr(line, RSTART+2); line = substr(line, 1, RSTART-1) }
      n = split(line, parts, " · ")
      title = parts[1]; result = ""; from = ""; project = ""; prob = ""
      for (i = 2; i <= n; i++) {
        p = parts[i]
        if (p ~ /^From:/)         { sub(/^From:[[:space:]]*/, "", p); from = p }
        else if (p ~ /^Result:/)  { sub(/^Result:[[:space:]]*/, "", p); result = p }
        else if (p ~ /^Project:/) { sub(/^Project:[[:space:]]*/, "", p); project = p }
      }
      if (from == "projects") { sub(/^Project:[[:space:]]*/, "", title); t = title; sub(/[[:space:]]+—.*$/, "", t); project = t }
      have = 1
      next
    }
    have && /^[[:space:]]+- Problems and fixes:/ { prob = $0; sub(/^[[:space:]]+- Problems and fixes:[[:space:]]*/, "", prob) }
    END { flush() }
  ' "$file" | while IFS="$SEP" read -r id title completed result from project probtext; do
    emit_done "$id" "$title" "$completed" "$result" "$from" "$project" "$(has_problem "$probtext")"
  done
}

if [ "$LIST" = "done" ]; then
  if [ -d "$GTD_DIR/_done" ]; then list_done_per_item; else list_done_single; fi
  exit 0
fi

# --- tickler (per-item layout only) -------------------------------------------

list_tickler() {
  local dir="$GTD_DIR/tickler" f base id tickle project key val today until
  [ "$GTD_LAYOUT" = "notes" ] && [ -d "$dir" ] || return 0
  today="$(date +%Y-%m-%d)"
  [ -z "$WITHIN" ] || until="$(gtd_days_ahead "$WITHIN")"
  for f in "$dir"/*.md; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .md)"
    [ "$base" = "README" ] && continue
    id="" tickle="" project=""
    while IFS="$SEP" read -r key val; do
      case "$key" in
        id) id="$val" ;;
        tickle) tickle="$val" ;;
        project) project="$val" ;;
      esac
    done < <(frontmatter_kv "$f")
    # YYYY-MM-DD compares as text.
    if [ "$DUE" -eq 1 ]; then
      gtd_is_date "$tickle" && [ ! "$tickle" \> "$today" ] || continue
    fi
    if [ -n "$WITHIN" ]; then
      gtd_is_date "$tickle" && [ "$tickle" \> "$today" ] && [ ! "$tickle" \> "$until" ] || continue
    fi
    [ -z "$PROJECT" ] || echo "$project" | grep -qi -- "$PROJECT" || continue
    emit "$id" "$base" "$tickle" "$project"
  done
}

if [ "$LIST" = "tickler" ]; then
  list_tickler
  exit 0
fi

# --- per-item mode ---------------------------------------------------------

# SEP and frontmatter_kv come from gtd_env.sh.

list_per_item() {
  local dir="$LIST_DIR" f base id time energy context project outcome title key val
  local due person delegated followup trigger
  local -a notes
  # A project is a folder (projects/<Project name>/README.md); every other list is flat notes.
  # The list's own README.md is never an item in either shape. An unmatched glob stays literal
  # (one element), so the array is never empty under set -u on bash 3.2.
  if [ "$LIST" = "projects" ]; then notes=("$dir"/*/README.md); else notes=("$dir"/*.md); fi
  for f in "${notes[@]}"; do
    [ -e "$f" ] || continue
    if [ "$LIST" = "projects" ]; then
      base="$(basename "$(dirname "$f")")"
    else
      base="$(basename "$f" .md)"
      [ "$base" = "README" ] && continue
    fi
    id="" time="" energy="" context="" project="" outcome="" due="" person="" delegated=""
    followup="" trigger=""
    while IFS="$SEP" read -r key val; do
      case "$key" in
        id) id="$val" ;;
        time) time="$val" ;;
        energy) energy="$val" ;;
        context) context="$val" ;;
        project) project="$val" ;;
        outcome) outcome="$val" ;;
        due) due="$val" ;;
        person) person="$val" ;;
        delegated) delegated="$val" ;;
        follow-up) followup="$val" ;;
        trigger) trigger="$val" ;;
      esac
    done < <(frontmatter_kv "$f")
    title="$base"
    # Match single-file projects output ("name -- outcome"); --project filters on the project's own name.
    if [ "$LIST" = "projects" ]; then
      project="$base"
      [ -n "$outcome" ] && title="$base -- $outcome"
    fi
    passes_lenses "$time" "$energy" "$context" "$project" || continue
    case "$LIST" in
      next-actions) emit "$id" "$title" "$time" "$energy" "$context" "$project" "$due" ;;
      waiting-for) emit "$id" "$title" "$person" "$delegated" "$followup" "$project" ;;
      someday-maybe) emit "$id" "$title" "$trigger" ;;
      projects) emit "$id" "$title" "$project" ;;
      *) emit "$id" "$title" ;;
    esac
  done
}

# --- single-file fallback ---------------------------------------------------

# next-actions.md: "- [ ] text · Time: … · Energy: … · Constraint: … · Project: [[projects#...|Name]] · Source: … · Date: … · Due: … ^id"
list_single_bullets_with_lenses() {
  local file="$1"
  [ -f "$file" ] || return 0
  awk -v SEP="$SEP" '
    /^- \[ \] / {
      line = $0
      sub(/^- \[ \] /, "", line)
      n = split(line, parts, " · ")
      id = ""
      if (match(parts[n], /\^[A-Za-z0-9_-]+$/)) {
        id = substr(parts[n], RSTART+1)
        parts[n] = substr(parts[n], 1, RSTART-1)
        sub(/[[:space:]]+$/, "", parts[n])
      }
      title = parts[1]
      time = ""; energy = ""; constraint = ""; project = ""; due = ""
      for (i = 2; i <= n; i++) {
        p = parts[i]
        if (p ~ /^Time:/)       { sub(/^Time:[[:space:]]*/, "", p); time = p }
        else if (p ~ /^Energy:/)     { sub(/^Energy:[[:space:]]*/, "", p); energy = p }
        else if (p ~ /^Constraint:/) { sub(/^Constraint:[[:space:]]*/, "", p); constraint = p }
        else if (p ~ /^Project:/)    { sub(/^Project:[[:space:]]*/, "", p); project = p }
        else if (p ~ /^Due:/)        { sub(/^Due:[[:space:]]*/, "", p); due = p }
      }
      printf "%s%s%s%s%s%s%s%s%s%s%s%s%s\n", id, SEP, time, SEP, energy, SEP, constraint, SEP, project, SEP, due, SEP, title
    }
  ' "$file" | while IFS="$SEP" read -r id time energy constraint project due title; do
    if passes_lenses "$time" "$energy" "$constraint" "$project"; then
      emit "$id" "$title" "$time" "$energy" "$constraint" "$project" "$due"
    fi
  done
}

# waiting-for.md / someday-maybe.md: plain "- [ ] …" lines, no lens fields to filter on.
list_single_bullets_plain() {
  local file="$1"
  [ -f "$file" ] || return 0
  [ -n "$MAX_TIME$ENERGY$CONTEXT" ] && return 0
  awk '
    /^- \[ \] / {
      line = $0
      sub(/^- \[ \] /, "", line)
      print line
    }
  ' "$file" | while IFS= read -r line; do
    if [ -z "$PROJECT" ] || echo "$line" | grep -qi "$PROJECT"; then
      emit "-" "$line"
    fi
  done
}

# projects.md: one line per "## Project name" block, with its desired-outcome line.
list_projects_single() {
  local file="$GTD_DIR/projects.md"
  [ -f "$file" ] || return 0
  [ -n "$MAX_TIME$ENERGY$CONTEXT" ] && return 0
  awk -v SEP="$SEP" '
    /^## / { title = $0; sub(/^## /, "", title); outcome = ""; next }
    title != "" && /^- Desired outcome:/ {
      outcome = $0
      sub(/^- Desired outcome:[[:space:]]*/, "", outcome)
      printf "%s%s%s\n", title, SEP, outcome
      title = ""
    }
  ' "$file" | while IFS="$SEP" read -r title outcome; do
    if [ -z "$PROJECT" ] || echo "$title" | grep -qi "$PROJECT"; then
      emit "-" "$title -- $outcome" "$title"
    fi
  done
}

LIST_DIR="$GTD_DIR/$LIST"
if [ "$LIST" = "reference" ] && [ "$GTD_LAYOUT" = "notes" ]; then
  LIST_DIR="$GTD_WORKSPACE_ROOT/reference"
fi
if [ -d "$LIST_DIR" ]; then
  list_per_item
  exit 0
fi

FILE="$GTD_DIR/$LIST.md"
if [ ! -f "$FILE" ]; then
  echo "No such list: $LIST (looked for $GTD_DIR/$LIST/ and $FILE)" >&2
  exit 2
fi

case "$LIST" in
  next-actions) list_single_bullets_with_lenses "$FILE" ;;
  waiting-for|someday-maybe) list_single_bullets_plain "$FILE" ;;
  projects) list_projects_single ;;
  *) echo "No item listing for '$LIST' in single-file mode (not a per-item-eligible list)." >&2; exit 2 ;;
esac
