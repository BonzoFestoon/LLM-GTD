#!/usr/bin/env bash
# gtd_list.sh — read-only: print one compact line per item in a GTD list, regardless of
# which layout (single-file or per-item) is live. Engage, organize, review and update call
# this instead of opening every note, so the AI does not get slower as notes multiply.
#
# Usage:
#   bash gtd_list.sh <list> [--max-time N] [--energy E] [--context C] [--project SUBSTRING]
#
# <list> is a bare list name: next-actions, waiting-for, projects, someday-maybe,
# product-ideas, or reference (the folder-backed lists in per-item mode; reference/ sits at the
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
#   product-ideas  id  evidence=  title
#   projects       id  project=  name -- outcome
#   reference      id  title
# Never reads memory/gtd/_done/ — finished items are not part of any active list.
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
while [ $# -gt 0 ]; do
  case "$1" in
    --max-time) MAX_TIME="$2"; shift 2 ;;
    --energy) ENERGY="$2"; shift 2 ;;
    --context) CONTEXT="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
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
  product-ideas) COLUMNS="evidence" ;;
  projects) COLUMNS="project" ;;
  *) COLUMNS="" ;;
esac

# --- per-item mode ---------------------------------------------------------

# SEP and frontmatter_kv come from gtd_env.sh.

list_per_item() {
  local dir="$LIST_DIR" f base id time energy context project outcome title key val
  local due person delegated followup trigger evidence
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
    followup="" trigger="" evidence=""
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
        evidence) evidence="$val" ;;
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
      product-ideas) emit "$id" "$title" "$evidence" ;;
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

# product-ideas.md: one line per "### Idea title" block, with its opportunity line.
list_product_ideas_single() {
  local file="$GTD_DIR/product-ideas.md"
  [ -f "$file" ] || return 0
  [ -n "$MAX_TIME$ENERGY$CONTEXT" ] && return 0
  awk -v SEP="$SEP" '
    /^### / { title = $0; sub(/^### /, "", title); next }
    title != "" && /Opportunity:/ {
      opp = $0
      sub(/^-[[:space:]]*\[[ x]\][[:space:]]*Opportunity:[[:space:]]*/, "", opp)
      printf "%s%s%s\n", title, SEP, opp
      title = ""
    }
  ' "$file" | while IFS="$SEP" read -r title opp; do
    if [ -z "$PROJECT" ] || echo "$title" | grep -qi "$PROJECT"; then
      emit "-" "$title -- $opp"
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
  product-ideas) list_product_ideas_single ;;
  *) echo "No item listing for '$LIST' in single-file mode (not a per-item-eligible list)." >&2; exit 2 ;;
esac
