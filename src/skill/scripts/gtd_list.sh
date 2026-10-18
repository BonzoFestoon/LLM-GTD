#!/usr/bin/env bash
# gtd_list.sh — read-only: print one compact line per item in a GTD list. Engage, organize,
# review and update call this instead of opening every note, so the AI does not get slower as
# notes multiply.
#
# Usage:
#   bash gtd_list.sh <list> [--max-time N] [--energy E] [--context C] [--project SUBSTRING]
#                    [--blocked | --all] [--depends-on SUBSTRING]
#   bash gtd_list.sh done [--since YYYY-MM-DD] [--project SUBSTRING] [--from SUBSTRING] [--problems]
#   bash gtd_list.sh tickler [--due | --within N | --overdue] [--recurring] [--project SUBSTRING]
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
#   next-actions   id  time=  energy=  context=  project=  due=  from=  blocked=  waits-on=  title
#   waiting-for    id  person=  delegated=  follow-up=  project=  title
#   someday-maybe  id  trigger=  title
#   projects       id  project=  blocked=  waits-on=  name -- outcome
#   reference      id  title
#   done           id  completed=  result=  list=  project=  problems=  title
#   tickler        id  tickle=  project=  every=  lead=  action=  title
# Only `done` reads the done record (memory/gtd/_done/);
# no active list ever includes a finished item. For done: --since keeps completed >= DATE,
# --project matches the project link (or a finished project's own name), --from matches the
# recurring tickle a cycle came from (its from: link), and --problems keeps only items whose
# "Problems and fixes" records a real problem (problems=yes).
# The tickler (memory/gtd/tickler/) holds committed things that can't be acted on until their
# tickle date. A tickle with a valid every: (7d, 2w, 3m, 1y) is recurring: it stays in the tickler,
# and organize creates one next action (from: links back to it) on its start date, the tickle date
# minus its optional lead:. Its start date is the one --due and --within use; a one-shot tickle's is
# its tickle date. action=open when an open next action's from: links the tickle.
#   --due        what organize must act on: a one-shot tickle whose date is today or earlier; a
#                recurring one whose start date has arrived and that has no open action
#   --within N   start date after today and on or before today + N days (never overlaps --due,
#                except a recurring tickle past its start that still has its action open: neither)
#   --overdue    a recurring tickle dated before today (its cycle is late; no grace)
#   --recurring  only recurring tickles
# A tickle with no valid date matches none of the date filters.
# Dependencies (next-actions and projects; list-definitions.md "Dependencies"): blocked= is no
# (no depends_on:, or every link done), yes (one still open) or broken (one cancelled, missing or a
# bad target: organize asks); waits-on= names the links not yet done. A blocked or broken next
# action is left out by default, because it can't be done yet; projects are all listed.
#   --blocked     only blocked or broken items
#   --all         next-actions: blocked and unblocked alike
#   --depends-on  only items with a depends_on: link to TITLE (what that item is blocking): the
#                 link's target, wherever it is now, has exactly that title (or project name),
#                 ignoring case; a list prefix (next-actions/, projects/<Name>/README) or a whole
#                 [[link]] is fine too. Implies --all
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
OVERDUE=0
RECURRING=0
FROM=""
BLOCKED=0
ALL=0
DEPENDS_ON=""
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
    --overdue) OVERDUE=1; shift ;;
    --recurring) RECURRING=1; shift ;;
    --from) FROM="$2"; shift 2 ;;
    --blocked) BLOCKED=1; shift ;;
    --all) ALL=1; shift ;;
    --depends-on) DEPENDS_ON="$2"; ALL=1; shift 2 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

gtd_require_gtd_dir
gtd_refuse_single_file

# normalize_energy TEXT — "low energy" / "deep work" / "low-emotional" -> low|medium|deep|low-emotional,
# into ENERGY_NORM. Only an unknown value costs a process (tr / sed): the lenses run once per note.
normalize_energy() {
  if gtd_icontains "$1" low-emotional; then ENERGY_NORM="low-emotional"
  elif gtd_icontains "$1" deep; then ENERGY_NORM="deep"
  elif gtd_icontains "$1" medium; then ENERGY_NORM="medium"
  elif gtd_icontains "$1" low; then ENERGY_NORM="low"
  else ENERGY_NORM="$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[[:space:]]*(energy|work)[[:space:]]*//g')"; fi
}

# first_int TEXT — the first integer substring into FIRST_INT, or empty
INT_RE='[0-9]+'
first_int() {
  FIRST_INT=""
  if [[ $1 =~ $INT_RE ]]; then FIRST_INT="${BASH_REMATCH[0]}"; fi
}

# passes_lenses TIME ENERGY CONTEXT PROJECT — apply whichever of the 4 filters were set;
# an unset filter always passes; a filter with nothing to compare against fails.
passes_lenses() {
  local t="$1" e="$2" c="$3" p="$4"
  if [ -n "$MAX_TIME" ]; then
    first_int "$t"
    [ -n "$FIRST_INT" ] || return 1
    [ "$FIRST_INT" -le "$MAX_TIME" ] || return 1
  fi
  if [ -n "$ENERGY" ]; then
    normalize_energy "$e"
    [ "$ENERGY_NORM" = "$ENERGY_WANT" ] || return 1
  fi
  if [ -n "$CONTEXT" ]; then
    gtd_icontains "$c" "$CONTEXT" || return 1
  fi
  if [ -n "$PROJECT" ]; then
    gtd_icontains "$p" "$PROJECT" || return 1
  fi
  return 0
}

ENERGY_WANT=""
if [ -n "$ENERGY" ]; then normalize_energy "$ENERGY"; ENERGY_WANT="$ENERGY_NORM"; fi

# --depends-on's TITLE as a bare title: "[[next-actions/Call Mom|Call Mom]]" -> Call Mom
DEP_WANT="$DEPENDS_ON"
case "$DEP_WANT" in *\[\[*) DEP_WANT="${DEP_WANT#*\[\[}"; DEP_WANT="${DEP_WANT%%]]*}"; DEP_WANT="${DEP_WANT%%|*}" ;; esac
DEP_WANT="${DEP_WANT#memory/gtd/}"; DEP_WANT="${DEP_WANT%.md}"; DEP_WANT="${DEP_WANT%/README}"
case "$DEP_WANT" in next-actions/*|waiting-for/*|projects/*|_done/*) DEP_WANT="${DEP_WANT#*/}" ;; esac

# dep_names_want — true when one of DEP_EACH's links (gtd_dep_eval) has the title DEP_WANT
dep_names_want() {
  local t s p w n r=1
  shopt -s nocasematch
  while IFS="$SEP" read -r t s p w n; do
    [ -n "$t" ] && [[ $n == "$DEP_WANT" ]] && { r=0; break; }
  done <<EOF
$DEP_EACH
EOF
  shopt -u nocasematch
  return $r
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
  next-actions) COLUMNS="time energy context project due from blocked waits-on" ;;
  waiting-for) COLUMNS="person delegated follow-up project" ;;
  someday-maybe) COLUMNS="trigger" ;;
  projects) COLUMNS="project blocked waits-on" ;;
  done) COLUMNS="completed result list project problems" ;;
  tickler) COLUMNS="tickle project every lead action" ;;
  *) COLUMNS="" ;;
esac

# --- done record ---------------------------------------------------------------

# has_problem TEXT — PROBLEM=yes unless the Problems and fixes text is empty or says nothing was
# noted. Plain bash: trim spaces and one trailing period, then compare ignoring case.
has_problem() {
  local t="$1"
  t="${t#"${t%%[![:space:]]*}"}"; t="${t%"${t##*[![:space:]]}"}"
  t="${t%.}"; t="${t%"${t##*[![:space:]]}"}"
  PROBLEM=yes
  shopt -s nocasematch
  case "$t" in ""|none|"none noted"|n/a|-) PROBLEM=no ;; esac
  shopt -u nocasematch
}

emit_done() {
  # emit_done ID TITLE COMPLETED RESULT LIST PROJECT PROBLEMS FROM
  # YYYY-MM-DD sorts as text; an item with no completed date can't be placed, so --since drops it.
  if [ -n "$SINCE" ]; then
    [ -n "$3" ] && [ ! "$3" \< "$SINCE" ] || return 0
  fi
  [ -z "$PROJECT" ] || gtd_icontains "$6" "$PROJECT" || return 0
  [ "$PROBLEMS" -eq 0 ] || [ "$7" = "yes" ] || return 0
  if [ -n "$FROM" ]; then
    _gtd_from_title "${8:-}"
    gtd_icontains "$GTD_FROM_TITLE" "$FROM" || return 0
  fi
  emit "$1" "$2" "$3" "$4" "$5" "$6" "$7"
}

# done_item FILE — one _done/ note; gtd_fm_each calls it with the properties in FM_* and the
# "Problems and fixes:" text in GTD_FM_BODY.
done_item() {
  local f="$1" rel title from project
  rel="${f#"$GTD_DIR/_done"/}"
  case "$rel" in */README.md) title="${rel%/README.md}" ;; *) title="${rel%.md}" ;; esac
  from="${FM_list:-}"
  project="${FM_project:-}"
  [ "$from" = "projects" ] && project="$title"
  has_problem "$GTD_FM_BODY"
  emit_done "${FM_id:-}" "$title" "${FM_completed:-}" "${FM_result:-}" "$from" "$project" "$PROBLEM" "${FM_from:-}"
}

list_done_per_item() {
  local dir="$GTD_DIR/_done" f
  local -a notes=()
  # Flat done notes, plus one folder per finished project (_done/<Project name>/README.md).
  for f in "$dir"/*.md "$dir"/*/README.md; do
    [ -e "$f" ] || continue
    [ "$f" = "$dir/README.md" ] && continue
    notes+=("$f")
  done
  [ "${#notes[@]}" -gt 0 ] || return 0
  gtd_fm_each done_item "Problems and fixes:" -- "${notes[@]}"
}

if [ "$LIST" = "done" ]; then
  list_done_per_item
  exit 0
fi

# --- tickler -------------------------------------------------------------------

# tickler_item FILE — one tickle; gtd_fm_each calls it with the properties in FM_*.
tickler_item() {
  local f="$1" base id tickle project every lead start action
  base="${f##*/}"; base="${base%.md}"
  id="${FM_id:-}" tickle="${FM_tickle:-}" project="${FM_project:-}" every="${FM_every:-}" lead="${FM_lead:-}"
  action=""
  case $'\n'"$TICKLER_OPEN"$'\n' in *$'\n'"$base"$'\n'*) action=open ;; esac
  # A tickle with an invalid every: is one-shot until organize fixes it; an invalid lead: is ignored.
  start="$tickle"
  if gtd_is_span "$every"; then
    gtd_is_date "$tickle" && gtd_is_span "$lead" && start="$(gtd_date_add "$tickle" "$lead" -)"
  else
    [ "$RECURRING" -eq 0 ] || return 0
  fi
  # YYYY-MM-DD compares as text.
  if [ "$DUE" -eq 1 ]; then
    gtd_is_date "$start" && [ ! "$start" \> "$TICKLER_TODAY" ] || return 0
    ! gtd_is_span "$every" || [ "$action" != open ] || return 0
  fi
  if [ "$OVERDUE" -eq 1 ]; then
    gtd_is_span "$every" && gtd_is_date "$tickle" && [ "$tickle" \< "$TICKLER_TODAY" ] || return 0
  fi
  if [ -n "$WITHIN" ]; then
    gtd_is_date "$start" && [ "$start" \> "$TICKLER_TODAY" ] && [ ! "$start" \> "$TICKLER_UNTIL" ] || return 0
  fi
  [ -z "$PROJECT" ] || gtd_icontains "$project" "$PROJECT" || return 0
  emit "$id" "$base" "$tickle" "$project" "$every" "$lead" "$action"
}

list_tickler() {
  local dir="$GTD_DIR/tickler"
  [ -d "$dir" ] || return 0
  TICKLER_TODAY="$(date +%Y-%m-%d)"
  TICKLER_UNTIL=""
  [ -z "$WITHIN" ] || TICKLER_UNTIL="$(gtd_days_ahead "$WITHIN")"
  # Titles of the tickles an open next action links to with from:, one per line.
  TICKLER_OPEN="$(gtd_open_from "$GTD_DIR/next-actions" | cut -d"$SEP" -f1)"
  gtd_notes_in "$dir"
  gtd_fm_each tickler_item -- ${GTD_NOTES[@]+"${GTD_NOTES[@]}"}
}

if [ "$LIST" = "tickler" ]; then
  list_tickler
  exit 0
fi

# --- active lists --------------------------------------------------------------

# SEP, gtd_notes_in and gtd_fm_each come from gtd_env.sh.

# list_item FILE — one note of $LIST; gtd_fm_each calls it with the properties in FM_*.
list_item() {
  local f="$1" base title project d self context
  if [ "$LIST" = "projects" ]; then
    d="${f%/README.md}"; base="${d##*/}"; self="projects/$base/README"
  else
    base="${f##*/}"; base="${base%.md}"; self="$LIST/$base"
  fi
  project="${FM_project:-}"
  title="$base"
  # Projects print "name -- outcome"; --project filters on the project's own name.
  if [ "$LIST" = "projects" ]; then
    project="$base"
    [ -n "${FM_outcome:-}" ] && title="$base -- $FM_outcome"
  fi
  # a context written as a YAML block list reads like the [a, b] form
  context="${FM_context:-}"; context="${context//"$GTD_ITEM_SEP"/,}"
  passes_lenses "${FM_time:-}" "${FM_energy:-}" "$context" "$project" || return 0
  DEP_BLOCKED=no; DEP_WAITS=""
  case "$LIST" in
    next-actions|projects)
      [ "$DEP_ON" -eq 0 ] || gtd_dep_eval "${FM_depends_on:-}" "$self"
      [ -z "$DEPENDS_ON" ] || { [ "$DEP_ON" -eq 1 ] && dep_names_want; } || return 0
      if [ "$BLOCKED" -eq 1 ]; then [ "$DEP_BLOCKED" != no ] || return 0
      elif [ "$LIST" = next-actions ] && [ "$ALL" -eq 0 ]; then [ "$DEP_BLOCKED" = no ] || return 0; fi ;;
  esac
  case "$LIST" in
    next-actions) emit "${FM_id:-}" "$title" "${FM_time:-}" "${FM_energy:-}" "$context" "$project" "${FM_due:-}" "${FM_from:-}" "$DEP_BLOCKED" "$DEP_WAITS" ;;
    waiting-for) emit "${FM_id:-}" "$title" "${FM_person:-}" "${FM_delegated:-}" "${FM_follow_up:-}" "$project" ;;
    someday-maybe) emit "${FM_id:-}" "$title" "${FM_trigger:-}" ;;
    projects) emit "${FM_id:-}" "$title" "$project" "$DEP_BLOCKED" "$DEP_WAITS" ;;
    *) emit "${FM_id:-}" "$title" ;;
  esac
}

list_per_item() {
  local dir="$LIST_DIR" f
  local -a notes=()
  # A project is a folder (projects/<Project name>/README.md); every other list is flat notes.
  # The list's own README.md is never an item in either shape.
  if [ "$LIST" = "projects" ]; then
    for f in "$dir"/*/README.md; do
      [ -e "$f" ] || continue
      notes+=("$f")
    done
  else
    gtd_notes_in "$dir"
    notes=(${GTD_NOTES[@]+"${GTD_NOTES[@]}"})
  fi
  [ "${#notes[@]}" -gt 0 ] || return 0
  gtd_fm_each list_item -- "${notes[@]}"
}

case "$LIST" in
  next-actions|waiting-for|projects|someday-maybe) LIST_DIR="$GTD_DIR/$LIST" ;;
  reference) LIST_DIR="$GTD_WORKSPACE_ROOT/reference" ;;
  *) echo "No such list: $LIST (one of next-actions, waiting-for, projects, someday-maybe, reference, done, tickler)" >&2; exit 2 ;;
esac
[ -d "$LIST_DIR" ] || exit 0
# Resolve dependencies only when some note in this list has any (one grep).
DEP_ON=0
case "$LIST" in
  next-actions|projects) if gtd_dep_needed "$LIST_DIR"; then gtd_dep_index; DEP_ON=1; fi ;;
esac
list_per_item
