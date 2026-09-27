#!/usr/bin/env bash
# gtd_list.sh — read-only: print one compact line per item in a GTD list, regardless of
# which layout (single-file or per-item) is live. Engage, organize, review and update call
# this instead of opening every note, so the AI does not get slower as notes multiply.
#
# Usage:
#   bash gtd_list.sh <list> [--max-time N] [--energy E] [--context C] [--project SUBSTRING]
#
# <list> is a bare list name: next-actions, waiting-for, projects, someday-maybe,
# product-ideas, or reference (the folder-backed lists in per-item mode).
#
# Per-item mode (memory/gtd/<list>/ is a directory): reads each note's YAML frontmatter,
# skipping README.md. Single-file mode (memory/gtd/<list>.md): falls back to parsing the
# list's own bullet/heading format. --max-time/--energy/--context are next-actions' lenses;
# other lists ignore filters they have no matching field for. --project matches by substring
# against whatever the item's project link/field contains.
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

emit() {
  # emit ID TIME ENERGY CONTEXT PROJECT TITLE
  printf '%s\ttime=%s\tenergy=%s\tcontext=%s\tproject=%s\t%s\n' \
    "${1:--}" "${2:--}" "${3:--}" "${4:--}" "${5:--}" "$6"
}

# --- per-item mode ---------------------------------------------------------

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
      if (!match(line, /^[A-Za-z_][A-Za-z0-9_]*:/)) next
      key = substr(line, 1, RLENGTH-1)
      val = substr(line, RLENGTH+1)
      sub(/^[[:space:]]+/, "", val)
      sub(/[[:space:]]+$/, "", val)
      gsub(/^"|"$/, "", val)
      if (substr(val, 1, 2) != "[[") {
        gsub(/^\[|\]$/, "", val)
        gsub(/[[:space:]]*,[[:space:]]*/, ",", val)
      }
      printf "%s%s%s\n", key, SEP, val
    }
  ' "$1"
}

list_per_item() {
  local dir="$GTD_DIR/$LIST" f base id time energy context project title kv key val
  for f in "$dir"/*.md; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .md)"
    [ "$base" = "README" ] && continue
    id="" time="" energy="" context="" project=""
    while IFS="$SEP" read -r key val; do
      case "$key" in
        id) id="$val" ;;
        time) time="$val" ;;
        energy) energy="$val" ;;
        context) context="$val" ;;
        project) project="$val" ;;
      esac
    done < <(frontmatter_kv "$f")
    title="$base"
    if passes_lenses "$time" "$energy" "$context" "$project"; then
      emit "$id" "$time" "$energy" "$context" "$project" "$title"
    fi
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
      time = ""; energy = ""; constraint = ""; project = ""
      for (i = 2; i <= n; i++) {
        p = parts[i]
        if (p ~ /^Time:/)       { sub(/^Time:[[:space:]]*/, "", p); time = p }
        else if (p ~ /^Energy:/)     { sub(/^Energy:[[:space:]]*/, "", p); energy = p }
        else if (p ~ /^Constraint:/) { sub(/^Constraint:[[:space:]]*/, "", p); constraint = p }
        else if (p ~ /^Project:/)    { sub(/^Project:[[:space:]]*/, "", p); project = p }
      }
      printf "%s%s%s%s%s%s%s%s%s%s%s\n", id, SEP, time, SEP, energy, SEP, constraint, SEP, project, SEP, title
    }
  ' "$file" | while IFS="$SEP" read -r id time energy constraint project title; do
    if passes_lenses "$time" "$energy" "$constraint" "$project"; then
      emit "$id" "$time" "$energy" "$constraint" "$project" "$title"
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
      emit "-" "-" "-" "-" "-" "$line"
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
      emit "-" "-" "-" "-" "-" "$title -- $outcome"
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
      emit "-" "-" "-" "-" "-" "$title -- $opp"
    fi
  done
}

if [ -d "$GTD_DIR/$LIST" ]; then
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
