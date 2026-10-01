#!/usr/bin/env bash
# gtd_list.sh — read-only: print one compact line per item in a GTD list. Engage, organize,
# review and update call this instead of opening every note, so the AI does not get slower as
# notes multiply.
#
# Usage:
#   bash gtd_list.sh <list> [--max-time N] [--energy E] [--context C] [--project SUBSTRING]
#   bash gtd_list.sh done [--since YYYY-MM-DD] [--project SUBSTRING] [--problems]
#   bash gtd_list.sh tickler [--due | --within N] [--project SUBSTRING]
#
# <list> is a bare list name: next-actions, waiting-for, projects, someday-maybe, or reference
# (a folder under memory/gtd/; reference/ sits at the workspace root instead). A list whose
# folder doesn't exist yet lists nothing.
#
# Reads each note's YAML frontmatter, skipping README.md. --max-time/--energy/--context are
# next-actions' lenses; on a list with no such field they match nothing. --project matches by substring
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
# Only `done` reads the done record (memory/gtd/_done/);
# no active list ever includes a finished item. For done: --since keeps completed >= DATE,
# --project matches the project link (or a finished project's own name), and --problems keeps
# only items whose "Problems and fixes" records a real problem (problems=yes).
# The tickler (memory/gtd/tickler/) holds committed things that can't be acted on until their
# tickle date. --due keeps tickles dated on or before today; --within N keeps tickles dated after
# today and on or before today + N days (the two never overlap); a tickle with no valid date
# matches neither.
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
gtd_refuse_single_file

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

# --- done record ---------------------------------------------------------------

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

if [ "$LIST" = "done" ]; then
  list_done_per_item
  exit 0
fi

# --- tickler -------------------------------------------------------------------

list_tickler() {
  local dir="$GTD_DIR/tickler" f base id tickle project key val today until
  [ -d "$dir" ] || return 0
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

# --- active lists --------------------------------------------------------------

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
    # Projects print "name -- outcome"; --project filters on the project's own name.
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

case "$LIST" in
  next-actions|waiting-for|projects|someday-maybe) LIST_DIR="$GTD_DIR/$LIST" ;;
  reference) LIST_DIR="$GTD_WORKSPACE_ROOT/reference" ;;
  *) echo "No such list: $LIST (one of next-actions, waiting-for, projects, someday-maybe, reference, done, tickler)" >&2; exit 2 ;;
esac
[ -d "$LIST_DIR" ] || exit 0
list_per_item
