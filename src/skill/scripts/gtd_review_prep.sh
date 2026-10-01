#!/usr/bin/env bash
# gtd_review_prep.sh — build a read-only weekly review prep pack; never modifies any list.
# Usage: bash gtd_review_prep.sh [--since YYYY-MM-DD]
#   --since: start of "Done since last review" (default: 7 days ago — pass the last review's date)
# Works in both layouts: the per-item layout is read through gtd_list.sh / gtd_check.sh, never
# by counting _done/ or README.md as open work.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"
VAULT_ROOT="$GTD_WORKSPACE_ROOT"
GTD_DIR="$VAULT_ROOT/memory/gtd"

SINCE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
[ -n "$SINCE" ] || SINCE="$(gtd_days_ago 7)"

if [ ! -d "$GTD_DIR" ]; then
  echo "memory/gtd/ does not exist. Run this skill's scripts/gtd_init.sh first"
  exit 1
fi

list() {
  bash "$SCRIPT_DIR/gtd_list.sh" "$@"
}

NOTES=0
[ "$GTD_LAYOUT" = "notes" ] && NOTES=1
CHECK=""
[ "$NOTES" -eq 1 ] && CHECK="$(bash "$SCRIPT_DIR/gtd_check.sh")"

file() {
  printf "%s/%s" "$GTD_DIR" "$1"
}

section() {
  echo ""
  echo "## $1"
}

open_items() {
  local path="$1"
  if [ -f "$path" ]; then
    grep -nE '^- \[ \] |^- ' "$path" 2>/dev/null || true
  fi
}

stalled_projects() {
  local f
  if [ "$NOTES" -eq 1 ]; then
    printf '%s\n' "$CHECK" | awk -F'\t' '$1 == "stalled" { p = $2; sub(/^projects\//, "", p); sub(/\/README\.md$/, "", p); print p }'
    return 0
  fi
  f="$(file projects.md)"
  [ -f "$f" ] || return 0
  awk '
    function has_action_link(line) {
      return line ~ /\[\[(next-actions|waiting-for)#\^/
    }
    function invalid_next_heading(line) {
      return line ~ /Next actions:([[:space:]]*)?(none|None|nothing|not needed|done|Done|completed|confirmed|N\/A)/
    }
    /^## / {
      if (in_project && !has_valid_next) print project
      in_project=1
      has_valid_next=0
      in_next_section=0
      project=$0
      sub(/^## /, "", project)
      next
    }
    in_project && /^- Next actions:/ {
      in_next_section=1
      if (has_action_link($0)) {
        has_valid_next=1
      }
      if (invalid_next_heading($0)) {
        in_next_section=0
      }
      next
    }
    in_project && in_next_section && /^- / {
      in_next_section=0
    }
    in_project && in_next_section && has_action_link($0) {
      has_valid_next=1
    }
    END {
      if (in_project && !has_valid_next) print project
    }
  ' "$f"
}

# Tickler (per-item only): "- title · date · project" lines from gtd_list.sh tickler [flags].
tickle_lines() {
  list tickler "$@" | awk -F'\t' '{
    t = $2; sub(/^tickle=/, "", t)
    p = $3; sub(/^project=/, "", p)
    if (p ~ /\|/) { sub(/^.*\|/, "", p); sub(/\]\]$/, "", p) }
    else { gsub(/^\[\[|\]\]$/, "", p); sub(/^projects\//, "", p); sub(/\/README$/, "", p) }
    line = "- " $NF " · " t
    if (p != "-") line = line " · " p
    print line
  }'
}

# Projects on hold: each live project linked from a future tickle, with its earliest date.
projects_on_hold() {
  local today
  today="$(date +%Y-%m-%d)"
  list tickler | awk -F'\t' -v today="$today" '{
    t = $2; sub(/^tickle=/, "", t)
    if (t !~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ || t <= today) next
    p = $3; sub(/^project=/, "", p)
    if (p == "-") next
    gsub(/^\[\[|\]\]$/, "", p); sub(/\|.*$/, "", p); sub(/^projects\//, "", p); sub(/\/README$/, "", p)
    if (!(p in d) || t < d[p]) d[p] = t
  } END { for (p in d) print p "\t" d[p] }' | sort | while IFS=$'\t' read -r name date; do
    [ -f "$GTD_DIR/projects/$name/README.md" ] && echo "- $name · until $date"
  done
}

VAGUE_VERBS='(follow up|handle|deal with|work on|push forward|look into|research|check out|think about|sort out|figure out)'

vague_next_actions() {
  local f
  if [ "$NOTES" -eq 1 ]; then
    list next-actions | awk -F'\t' '{ print $NF }' | grep -iE "$VAGUE_VERBS" | sed 's/^/- /' || true
    return 0
  fi
  f="$(file next-actions.md)"
  [ -f "$f" ] || return 0
  grep -inE "^- \[ \] .*$VAGUE_VERBS" "$f" 2>/dev/null || true
}

# Per-item: open items of a folder list as "- title" lines (plus its key=value columns).
list_items() {
  list "$1" | awk -F'\t' '{ line = "- " $NF; for (i = 2; i < NF; i++) if ($i !~ /=-$/) line = line " · " $i; print line }'
}

product_ideas_summary() {
  local f
  if [ "$NOTES" -eq 1 ]; then
    list_items product-ideas
    return 0
  fi
  f="$(file product-ideas.md)"
  [ -f "$f" ] || return 0
  awk '
    function flush() {
      if (title != "") {
        print "- " title
        if (opportunity != "") print "  " opportunity
        if (visibility != "") print "  " visibility
        else print "  ⚠️ missing GTD visibility"
      }
    }
    /^### / {
      flush()
      title=$0
      sub(/^### /, "", title)
      opportunity=""
      visibility=""
      next
    }
    /^- \[ \] Opportunity:/ { opportunity=$0; next }
    /^- GTD visibility:/ { visibility=$0; next }
    END { flush() }
  ' "$f"
}

product_visibility_gaps() {
  local f vis
  if [ "$NOTES" -eq 1 ]; then
    for f in "$GTD_DIR"/product-ideas/*.md; do
      [ -e "$f" ] || continue
      [ "$(basename "$f")" = "README.md" ] && continue
      vis="$(grep -m1 'GTD visibility:' "$f" || true)"
      if ! echo "$vis" | grep -q '\[\[projects/'; then
        echo "$(basename "$f" .md): missing project visibility"
      elif ! echo "$vis" | grep -q '\[\[next-actions/'; then
        echo "$(basename "$f" .md): missing next-actions visibility"
      fi
    done
    return 0
  fi
  f="$(file product-ideas.md)"
  [ -f "$f" ] || return 0
  awk '
    function check() {
      if (title != "" && visibility !~ /\[\[projects#/) {
        print title ": missing project visibility"
      } else if (title != "" && visibility !~ /next-actions/) {
        print title ": missing next-actions visibility"
      }
    }
    /^### / {
      check()
      title=$0
      sub(/^### /, "", title)
      visibility=""
      next
    }
    /^- GTD visibility:/ { visibility=$0; next }
    END { check() }
  ' "$f"
}

today="$(date +%Y-%m-%d)"

echo "GTD Review Prep · $today"
echo "Read-only review prep pack: scan before the review; does not modify memory/gtd/."

if [ -f "$SCRIPT_DIR/gtd_status.sh" ]; then
  echo ""
  bash "$SCRIPT_DIR/gtd_status.sh"
else
  section "Dashboard"
  echo "gtd_status.sh not found."
fi

section "Inbox to clarify"
inbox_items="$(open_items "$(file inbox.md)")"
if [ -n "$inbox_items" ]; then
  echo "$inbox_items" | sed -n '1,12p'
  inbox_total="$(printf "%s\n" "$inbox_items" | wc -l | tr -d ' ')"
  [ "$inbox_total" -gt 12 ] && echo "... and $((inbox_total - 12)) more"
else
  echo "None."
fi

section "Done since last review ($SINCE)"
done_items="$(list done --since "$SINCE")"
if [ -n "$done_items" ]; then
  echo "Wins:"
  printf '%s\n' "$done_items" | awk -F'\t' '{ r = $3; sub(/^result=/, "", r); f = $4; sub(/^list=/, "", f); print "- " $NF " (" f ", " r ")" }'
  problems="$(printf '%s\n' "$done_items" | awk -F'\t' '$6 == "problems=yes" { print "- " $NF }')"
  if [ -n "$problems" ]; then
    echo "Problems solved (offer: file the how-to to reference now, or leave it for the project's after-action review):"
    echo "$problems"
  fi
else
  echo "None."
fi

if [ "$NOTES" -eq 1 ]; then
  section "Hygiene findings (gtd_check.sh)"
  # Stalled projects and due tickles have their own sections below.
  findings="$(printf '%s\n' "$CHECK" | grep -v '^#' | grep -v '^stalled' | grep -v '^tickler-due' || true)"
  if [ -n "$findings" ]; then
    echo "$findings" | awk -F'\t' '{ print "- " $1 ": " $2 " — " $3 }'
  else
    echo "None."
  fi
fi

section "Stalled Projects"
stalled="$(stalled_projects)"
if [ -n "$stalled" ]; then
  echo "$stalled" | sed 's/^/- /'
else
  echo "None."
fi

section "Waiting For"
if [ "$NOTES" -eq 1 ]; then waiting_items="$(list_items waiting-for)"; else waiting_items="$(open_items "$(file waiting-for.md)")"; fi
if [ -n "$waiting_items" ]; then
  echo "$waiting_items"
else
  echo "None."
fi

if [ "$NOTES" -eq 1 ]; then
  section "Tickler"
  echo "Due now (organize turns each into a next action, or queues it in the inbox for clarify):"
  out="$(tickle_lines --due)"; echo "${out:-None.}"
  echo "Next 14 days (anything to prepare now?):"
  out="$(tickle_lines --within 14)"; echo "${out:-None.}"
  echo "Projects on hold (does each date still hold?):"
  out="$(projects_on_hold)"; echo "${out:-None.}"
fi

section "Next Action hygiene"
vague="$(vague_next_actions)"
if [ -n "$vague" ]; then
  echo "Possible vague verbs / fuzzy actions:"
  echo "$vague"
else
  echo "No obvious vague verbs found."
fi

section "Someday/Maybe candidates"
if [ "$NOTES" -eq 1 ]; then someday_items="$(list_items someday-maybe)"; else someday_items="$(open_items "$(file someday-maybe.md)")"; fi
if [ -n "$someday_items" ]; then
  echo "$someday_items"
else
  echo "None."
fi

section "Product Ideas visibility audit"
product_gaps="$(product_visibility_gaps)"
if [ -n "$product_gaps" ]; then
  echo "$product_gaps" | sed 's/^/- /'
else
  echo "Every product opportunity has GTD visibility."
fi

section "Product Ideas work intake"
product_items="$(product_ideas_summary)"
if [ -n "$product_items" ]; then
  echo "$product_items"
else
  echo "None."
fi

section "Confirmation queue"
echo "- Empty the inbox: clarify item by item to zero."
echo "- Done since last review: for each problem solved, file its how-to to reference now or leave it for the project's after-action review."
echo "- Stalled projects: add at least one concrete next action per project; attach several parallel actions if needed, or confirm cutting it."
echo "- Waiting for: confirm which items to follow up on; AI can draft a neutral message first."
if [ "$NOTES" -eq 1 ]; then
  echo "- Tickler: organize handles due tickles; confirm each on-hold project's date still holds, and flag any calendar conflict."
fi
echo "- Someday/maybe: confirm whether to activate, delete, or keep incubating."
echo "- Product ideas: first fill missing project / next-action visibility; then confirm gathering evidence, advancing to PRD, downgrading, or deleting."
echo "- Next week's 3 things: AI proposes candidates; the user confirms."
