#!/usr/bin/env bash
# gtd_check.sh — read-only: organize's mechanical hygiene findings for the per-item layout.
# It never fixes anything; organize reads the findings, fixes the mechanical ones, and batches
# the rest as questions (see organize/SKILL.md).
#
# Usage:
#   bash gtd_check.sh
#
# Output: one tab-separated line per finding — check, path (relative to memory/gtd/), detail —
# then a "# N finding(s)" line. Checks:
#   orphan          an open action / waiting-for whose project: link resolves to no project
#   orphan-closed   ...whose project has already moved to _done/ (surface: close or re-link)
#   link-form       project: points at the project but not as [[projects/<Name>/README|<Name>]]
#   stalled         a project folder with no open next action or waiting-for linked to it
#   field           missing or out-of-vocabulary property (vocabulary: list-definitions.md
#                   "Property values")
#   duplicate       two notes in one list with the same title, ignoring case and a "(N)" suffix
#   filename        a note or project folder name with a character unsafe on some filesystem
#   done-completed  a _done/ note with no completed: date (organize fills today's date)
#   done-no-aar     a finished project in _done/ whose After action review section is empty
#                   (surface once, at the next Weekly Review)
# README.md is never an item. _done/ is only checked for its own two findings — its notes never
# count as open work, and never satisfy a project's "has a next action" check.
#
# In the single-file layout there is nothing to check here: organize scans the list files
# directly. Compatible with macOS bash 3.2 (no associative arrays / mapfile).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"
GTD_DIR="$GTD_WORKSPACE_ROOT/memory/gtd"

if [ ! -d "$GTD_DIR" ]; then
  echo "memory/gtd/ does not exist. Run first: bash gtd_init.sh" >&2
  exit 1
fi

if [ "$GTD_LAYOUT" != "notes" ]; then
  echo "# layout: files — per-item checks don't apply; organize scans the list files directly"
  exit 0
fi
echo "# layout: notes"

# Keep in step with references/list-definitions.md "Property values" (gtd_eval_check.sh verifies).
ENERGY_VOCAB="low medium deep low-emotional"
CONTEXT_VOCAB="computer phone errands home person-present before-meeting prep-chain payment documents equipment"

FINDINGS=0
finding() {
  printf '%s\t%s\t%s\n' "$1" "$2" "$3"
  FINDINGS=$((FINDINGS + 1))
}

in_words() {
  # in_words WORD "LIST OF WORDS"
  case " $2 " in *" $1 "*) return 0 ;; esac
  return 1
}

is_date() {
  echo "$1" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
}

# fm_get FILE KEY — one frontmatter value, or empty
fm_get() {
  frontmatter_kv "$1" | awk -F"$SEP" -v k="$2" '$1 == k { print $2; exit }'
}

# project_name LINK — the project name a project: value refers to, and how it's written:
# prints "<form><SEP><name>" where form is "readme" ([[projects/<Name>/README|…]]) or "other".
project_name() {
  local v="$1" target
  target="$v"
  case "$target" in \[\[*) target="${target#\[\[}"; target="${target%%]]*}"; target="${target%%|*}"; target="${target%%#*}" ;; esac
  case "$target" in
    projects/*/README) target="${target#projects/}"; printf 'readme%s%s\n' "$SEP" "${target%/README}" ;;
    projects/*) printf 'other%s%s\n' "$SEP" "${target#projects/}" ;;
    *) printf 'other%s%s\n' "$SEP" "$target" ;;
  esac
}

# --- open actions and waiting-for: project links + fields --------------------

LINKED=""   # newline-separated project names that have at least one open action / waiting-for

for list in next-actions waiting-for; do
  dir="$GTD_DIR/$list"
  [ -d "$dir" ] || continue
  for f in "$dir"/*.md; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .md)"
    [ "$base" = "README" ] && continue
    rel="$list/$base.md"

    project="$(fm_get "$f" project)"
    if [ -n "$project" ]; then
      IFS="$SEP" read -r form name < <(project_name "$project")
      if [ -f "$GTD_DIR/projects/$name/README.md" ]; then
        LINKED="$LINKED$name"$'\n'
        [ "$form" = "readme" ] || finding link-form "$rel" "project: $project -> [[projects/$name/README|$name]]"
      elif [ -f "$GTD_DIR/_done/$name.md" ] || [ -f "$GTD_DIR/_done/$name/README.md" ]; then
        finding orphan-closed "$rel" "project '$name' is already in _done/"
      else
        finding orphan "$rel" "project: $project resolves to no project folder"
      fi
    fi

    if [ "$list" = "next-actions" ]; then
      time="$(fm_get "$f" time)"
      energy="$(fm_get "$f" energy)"
      context="$(fm_get "$f" context)"
      due="$(fm_get "$f" due)"
      if [ -z "$time" ]; then finding field "$rel" "missing time"
      elif ! echo "$time" | grep -qE '^[0-9]+$'; then finding field "$rel" "time '$time' is not a number of minutes"; fi
      if [ -z "$energy" ]; then finding field "$rel" "missing energy"
      elif ! in_words "$energy" "$ENERGY_VOCAB"; then finding field "$rel" "energy '$energy' not in: $ENERGY_VOCAB"; fi
      if [ -z "$context" ]; then finding field "$rel" "missing context"
      else
        old_ifs="$IFS"; IFS=','
        for c in $context; do
          in_words "$c" "$CONTEXT_VOCAB" || finding field "$rel" "context '$c' not in: $CONTEXT_VOCAB"
        done
        IFS="$old_ifs"
      fi
      [ -z "$due" ] || is_date "$due" || finding field "$rel" "due '$due' is not YYYY-MM-DD"
    else
      person="$(fm_get "$f" person)"
      delegated="$(fm_get "$f" delegated)"
      followup="$(fm_get "$f" follow-up)"
      [ -n "$person" ] || finding field "$rel" "missing person"
      if [ -z "$delegated" ]; then finding field "$rel" "missing delegated"
      elif ! is_date "$delegated"; then finding field "$rel" "delegated '$delegated' is not YYYY-MM-DD"; fi
      [ -z "$followup" ] || is_date "$followup" || finding field "$rel" "follow-up '$followup' is not YYYY-MM-DD"
    fi
  done
done

# --- stalled projects ---------------------------------------------------------

if [ -d "$GTD_DIR/projects" ]; then
  for readme in "$GTD_DIR"/projects/*/README.md; do
    [ -e "$readme" ] || continue
    name="$(basename "$(dirname "$readme")")"
    case $'\n'"$LINKED" in
      *$'\n'"$name"$'\n'*) ;;
      *) finding stalled "projects/$name/README.md" "no open next action or waiting-for links to it" ;;
    esac
  done
fi

# --- duplicates and unsafe filenames, per list --------------------------------

for list in $GTD_NOTE_LISTS; do
  dir="$GTD_DIR/$list"
  [ -d "$dir" ] || continue
  names=""
  if [ "$list" = "projects" ]; then
    for d in "$dir"/*/; do
      [ -d "$d" ] || continue
      names="$names$(basename "$d")"$'\n'
    done
  else
    for f in "$dir"/*.md; do
      [ -e "$f" ] || continue
      base="$(basename "$f" .md)"
      [ "$base" = "README" ] && continue
      names="$names$base"$'\n'
    done
  fi
  [ -n "$names" ] || continue

  while IFS= read -r n; do
    [ -n "$n" ] || continue
    case "$n" in *[:?*\"\<\>\|]*|*'\'*) finding filename "$list/$n" "unsafe character in name (: \\ ? * \" < > |)" ;; esac
  done <<EOF
$names
EOF

  dupes="$(printf '%s' "$names" | sed -E 's/ \([0-9]+\)$//' | tr '[:upper:]' '[:lower:]' | sort | uniq -d)"
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    matches="$(printf '%s' "$names" | awk -v d="$d" '{ k = tolower($0); sub(/ \([0-9]+\)$/, "", k); if (k == d) print }' | paste -sd ';' - | sed 's/;/; /g')"
    finding duplicate "$list/" "same title: $matches"
  done <<EOF
$dupes
EOF
done

# --- _done/ record --------------------------------------------------------------

if [ -d "$GTD_DIR/_done" ]; then
  for f in "$GTD_DIR"/_done/*.md "$GTD_DIR"/_done/*/README.md; do
    [ -e "$f" ] || continue
    rel="${f#"$GTD_DIR"/}"
    [ "$rel" = "_done/README.md" ] && continue
    [ -n "$(fm_get "$f" completed)" ] || finding done-completed "$rel" "no completed: date"
    if [ "$(fm_get "$f" list)" = "projects" ]; then
      has_aar="$(awk '
        /^---[[:space:]]*$/ && fm < 2 { fm++; next }
        fm < 2 { next }
        /^## After action review/ { in_aar = 1; next }
        in_aar && /^## / { in_aar = 0 }
        in_aar && /<!--/ { in_comment = 1 }
        in_aar && !in_comment && /[^[:space:]]/ { print "yes"; exit }
        in_comment && /-->/ { in_comment = 0 }
      ' "$f")"
      [ "$has_aar" = "yes" ] || finding done-no-aar "$rel" "finished project closed with no after-action review"
    fi
  done
fi

echo "# $FINDINGS finding(s)"
