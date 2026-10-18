#!/usr/bin/env bash
# gtd_check.sh — read-only: organize's mechanical hygiene findings.
# It never fixes anything; organize reads the findings, fixes the mechanical ones, and batches
# the rest as questions (see organize/SKILL.md).
#
# Usage:
#   bash gtd_check.sh
#
# Output: one tab-separated line per finding — check, path (relative to memory/gtd/, or
# reference/<Title>.md for the workspace-root reference/ folder), detail —
# then a "# N finding(s)" line. Checks:
#   orphan          an open action / waiting-for / tickle whose project: link resolves to no project,
#                   or a next action whose from: link resolves to no tickle
#   orphan-closed   ...whose project (or from: tickle) has already moved to _done/ (close or re-link)
#   link-form       project: points at the project but not as [[projects/<Name>/README|<Name>]];
#                   from: points at the tickle but not as [[tickler/<Title>|<Title>]];
#                   or any frontmatter link written from the vault root ([[memory/gtd/…]])
#                   instead of relative to memory/gtd/ ([[projects/…]], [[next-actions/…]])
#   property-link   a frontmatter property whose wikilink isn't the whole quoted value — text
#                   before or after it (inside or outside the quotes), several links in one value,
#                   or an unquoted link — so Obsidian shows plain text; a whole "![[…]]" embed is
#                   fine. Links in the note body are never checked.
# property-link and the vault-root link-form also read the workspace-root reference/ folder; its
# notes are reported as reference/<Title>.md. A project: link the first link-form line already
# covers gets no second finding.
#   stalled         a project folder with no open next action, waiting-for or one-shot tickle linked
#                   to it (list-definitions.md "Stalled": a one-shot tickle means on hold on purpose;
#                   a recurring tickle never holds a project)
#   tickler-due     a one-shot tickle dated today or earlier (organize turns it into a next action,
#                   or adds an inbox pointer to it; "queued in inbox" when inbox.md already links the
#                   note); a recurring tickle (valid every:) whose start date — tickle minus its lead:
#                   — has arrived and that no open next action links with from: (organize creates it)
#   tickler-overdue a recurring tickle dated before today: its cycle is late (no grace). Reported,
#                   never re-dated
#   tickler-date    a tickle with no tickle: date, or one that isn't YYYY-MM-DD
#   tickler-every   an every: or lead: that isn't <n><unit> (7d, 2w, 3m, 1y), with the compact form
#                   when one is obvious; until fixed the tickle is one-shot (a bad lead: is ignored)
#   field           missing or out-of-vocabulary property (vocabulary: list-definitions.md
#                   "Property values")
#   duplicate       two notes in one list with the same title, ignoring case and a "(N)" suffix;
#                   or two open next actions whose from: links the same recurring tickle
#   filename        a note or project folder name with a character unsafe on some filesystem
#   done-completed  a _done/ note with no completed: date (organize fills today's date)
#   done-no-aar     a finished project in _done/ whose After action review section is empty
#                   (surface once, at the next Weekly Review)
#   done-link       a _done/ note whose project: still points at projects/<Name>/ after that
#                   project's folder moved to _done/<Name>/ (organize rewrites it)
# Dependencies (depends_on:, on a next action or project; list-definitions.md "Dependencies"):
#   depends-done-link   a link to an item that is finished but not yet written as [[_done/…]]
#                       (organize rewrites it)
#   depends-cancelled   a link to an item that was cancelled (result: cancelled): organize asks
#   depends-missing     a link that resolves to no next action, waiting-for item or project, open
#                       or in _done/: organize asks
#   depends-target      a link to something that can't be a dependency (a tickle, a someday item,
#                       a routine's cycle, a support doc, the note itself), or depends_on: on a
#                       waiting-for item or tickle
#   depends-form        depends_on: with no [[link]] in it
#   depends-cycle       items that wait on each other, so none can start
#   depends-hold        a project waiting on something (depends_on:) that still has unblocked open
#                       next actions: is it really on hold?
# A next action waiting on an open item still counts toward its project being in play; one with a
# broken link (cancelled / missing / bad target) doesn't. A project whose own depends_on: is open is
# on hold, never stalled.
# A finished project is its whole folder moved to _done/<Project name>/ (README.md + support
# material); a finished action or waiting-for item is a flat _done/<Title>.md.
# README.md is never an item. _done/ is only checked for its own two findings — its notes never
# count as open work, and never satisfy a project's "has a next action" check.
#
# Compatible with macOS bash 3.2 (no associative arrays / mapfile).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"
GTD_DIR="$GTD_WORKSPACE_ROOT/memory/gtd"

gtd_require_gtd_dir

gtd_refuse_single_file

# Keep in step with references/list-definitions.md "Property values" (gtd_eval_check.sh verifies).
ENERGY_VOCAB="low medium deep low-emotional"
CONTEXT_VOCAB="computer phone errands home person-present before-meeting prep-chain payment documents equipment"
CADENCE_VOCAB="fixed floating"

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
  gtd_is_date "$1"
}

# project_name LINK — the project name a project: value refers to, and how it's written: sets
# PN_NAME, and PN_FORM to "readme" ([[projects/<Name>/README|…]]) or "other". It sets variables
# instead of printing so the per-note loops start no subshell.
project_name() {
  local target="$1"
  PN_FORM=readme
  # text before the link is a property-link finding (below), not a different project
  case "$target" in *\[\[*) target="${target#*\[\[}"; target="${target%%]]*}"; target="${target%%|*}"; target="${target%%#*}" ;; esac
  # written from the vault root: the same project, but not the README form
  case "$target" in memory/gtd/*) target="${target#memory/gtd/}"; PN_FORM=other ;; esac
  case "$target" in
    projects/*/README) target="${target#projects/}"; PN_NAME="${target%/README}" ;;
    projects/*) PN_FORM=other; PN_NAME="${target#projects/}" ;;
    *) PN_FORM=other; PN_NAME="$target" ;;
  esac
}

# fm_link_problems — reads one note path per line on stdin, all in one awk, and prints
# "path<SEP>kind<SEP>key<SEP>message" for each frontmatter property (or list item)
# whose wikilink Obsidian won't render (property-link): the link (or an "![[…]]" embed) must be
# the whole value, quoted ("[[Note|Label]]"); several links are a YAML list, one quoted link per
# item. A well-shaped link written from the vault root ([[memory/gtd/…]]) is link-form; with a
# shape problem too, the one property-link fix already uses the short path. Reads only a
# frontmatter block that opens on line 1, so links in the body are never seen. Plain awk.
fm_link_problems() {
  awk -v SEP="$SEP" -v SQ="'" '
    function trim(s) { sub(/^[[:space:]]+/, "", s); sub(/[[:space:]]+$/, "", s); return s }
    # count_links S — how many [[...]] links S holds
    function count_links(s,   n, p, e) {
      n = 0
      while ((p = index(s, "[[")) > 0) {
        s = substr(s, p + 2)
        if ((e = index(s, "]]")) == 0) break
        n++; s = substr(s, e + 2)
      }
      return n
    }
    function out(kind, key, msg) { printf "%s%s%s%s%s%s%s\n", CUR, SEP, kind, SEP, key, SEP, msg }
    # check LABEL KEY V — one scalar value (or one [a, b] list, item by item)
    function check(label, key, v,   q, rest, inner, c, shown, after, all, p, e, link, lead, trail, bang, inside, short, why, bar, tgt, lbl, n, depth, item, items) {
      v = trim(v)
      if (index(v, "[[") == 0) return
      if (substr(v, 1, 1) == "[" && substr(v, 1, 2) != "[[") {
        # a [a, b] flow list: split on commas outside quotes and brackets, check each item
        rest = substr(v, 2); items = 0; item = ""; depth = 0; q = ""
        while (rest != "") {
          c = substr(rest, 1, 1); rest = substr(rest, 2)
          if (q != "") { item = item c; if (c == q) q = ""; continue }
          if (c == "\"" || c == SQ) { q = c; item = item c; continue }
          if (c == "[") depth++
          if (c == "]") { if (depth == 0) break; depth-- }
          if (c == "," && depth == 0) { items++; check(label " (item " items ")", key, item); item = ""; continue }
          item = item c
        }
        items++; check(label " (item " items ")", key, item)
        return
      }
      q = substr(v, 1, 1)
      if (q == "\"" || q == SQ) {
        rest = substr(v, 2); inner = ""
        while (rest != "") {
          c = substr(rest, 1, 1)
          if (q == "\"" && c == "\\") { inner = inner substr(rest, 1, 2); rest = substr(rest, 3); continue }
          if (c == q) {
            if (q == SQ && substr(rest, 2, 1) == q) { inner = inner q; rest = substr(rest, 3); continue }
            rest = substr(rest, 2); break
          }
          inner = inner c; rest = substr(rest, 2)
        }
        shown = substr(v, 1, length(v) - length(rest))
        after = rest
        if (after ~ /^[[:space:]]*#/) after = ""
        sub(/[[:space:]]+#.*$/, "", after)
        after = trim(after)
        if (after != "") shown = shown " " after
        all = trim(inner " " after)
      } else {
        q = ""
        sub(/[[:space:]]+#.*$/, "", v)
        shown = v; all = v
      }
      n = count_links(all)
      if (n == 0) return
      if (n > 1) {
        out("property-link", key, label ": " shown " — " n " links in one value -> a YAML list, one quoted link per item")
        return
      }
      p = index(all, "[["); e = index(substr(all, p + 2), "]]")
      link = substr(all, p, e + 3)
      lead = substr(all, 1, p - 1); trail = trim(substr(all, p + e + 3))
      # "!" right before the link makes it an embed: valid as the whole value, like a link
      bang = ""
      if (substr(lead, length(lead), 1) == "!") { bang = "!"; lead = substr(lead, 1, length(lead) - 1) }
      lead = trim(lead)
      # links inside memory/gtd/ are written relative to it: projects/..., next-actions/...
      inside = substr(link, 3, length(link) - 4)
      short = inside
      if (substr(short, 1, 11) == "memory/gtd/") short = substr(short, 12)
      if (lead == "" && trail == "") {
        if (q == "") {
          why = (bang == "") ? "YAML reads it as a nested list" : "YAML reads ! as a tag"
          out("property-link", key, label ": " shown " — unquoted (" why ") -> \"" bang "[[" short "]]\"")
        } else if (short != inside) {
          out("link-form", key, label ": " shown " — path from the vault root -> \"" bang "[[" short "]]\"")
        }
        return
      }
      if (bang != "") {
        out("property-link", key, label ": " shown " — text outside the embed -> \"![[" short "]]\" (the rest in another property)")
        return
      }
      if ((bar = index(short, "|")) > 0) { tgt = substr(short, 1, bar - 1); lbl = substr(short, bar + 1) }
      else { tgt = short; lbl = short }
      if (lead != "") lbl = lead " " lbl
      if (trail != "") lbl = lbl " " trail
      out("property-link", key, label ": " shown " — text outside the link -> \"[[" tgt "|" lbl "]]\"")
    }
    {
      CUR = $0; n = 0; key = ""; items = 0
      while ((getline < CUR) > 0) {
        n++
        sub(/\r$/, "")
        if (n == 1) { if ($0 ~ /^---[[:space:]]*$/) continue; break }
        if ($0 ~ /^(---|\.\.\.)[[:space:]]*$/) break
        if (match($0, /^[A-Za-z_][A-Za-z0-9_ .-]*:/)) {
          key = substr($0, 1, RLENGTH - 1); items = 0
          check(key, key, substr($0, RLENGTH + 1))
          continue
        }
        if ($0 ~ /^[[:space:]]*-[[:space:]]/ && key != "") {
          items++
          v = $0; sub(/^[[:space:]]*-[[:space:]]+/, "", v)
          check(key " (item " items ")", key, v)
        }
      }
      close(CUR)
    }
  '
}

# check_work_fields REL TIME ENERGY CONTEXT REQUIRED — a next action's time / energy / context
# (REQUIRED=1: each must be there); a tickle may carry them too, checked only when present.
check_work_fields() {
  local rel="$1" time="$2" energy="$3" context="${4//"$GTD_ITEM_SEP"/,}" required="$5" c old_ifs
  if [ -z "$time" ]; then [ "$required" -eq 0 ] || finding field "$rel" "missing time"
  elif ! [[ $time =~ $MINUTES_RE ]]; then finding field "$rel" "time '$time' is not a number of minutes"; fi
  if [ -z "$energy" ]; then [ "$required" -eq 0 ] || finding field "$rel" "missing energy"
  elif ! in_words "$energy" "$ENERGY_VOCAB"; then finding field "$rel" "energy '$energy' not in: $ENERGY_VOCAB"; fi
  if [ -z "$context" ]; then [ "$required" -eq 0 ] || finding field "$rel" "missing context"
  else
    old_ifs="$IFS"; IFS=','
    for c in $context; do
      in_words "$c" "$CONTEXT_VOCAB" || finding field "$rel" "context '$c' not in: $CONTEXT_VOCAB"
    done
    IFS="$old_ifs"
  fi
}

# span_hint TEXT — the compact every: / lead: form for common wording (quarterly -> 3m), or empty
span_hint() {
  local t
  t="$(echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/^(every|at least)[[:space:]]+//')"
  case "$t" in
    daily) echo 1d ;; weekly) echo 1w ;; fortnightly|biweekly) echo 2w ;; monthly) echo 1m ;;
    quarterly) echo 3m ;; "twice a year"|semiannually|half-yearly) echo 6m ;; yearly|annually|annual) echo 1y ;;
    *) echo "$t" | sed -nE 's/^([1-9][0-9]*)[[:space:]]*(d|w|m|y)[a-z]*$/\1\2/p' ;;
  esac
}

# --- open actions and waiting-for: project links + fields --------------------

LINKED=""   # newline-separated project names with at least one open action / waiting-for / one-shot tickle
READY=""    # newline-separated project names with at least one unblocked open next action
HELD=""     # newline-separated project names on hold because their own depends_on: is still open
DEP_EDGES=""   # "<waiting item><SEP><item it waits on>" per open dependency, for depends-cycle
FORM_DONE=""   # "<rel> <key>" lines already given a link-form finding (property links skip that key)
OPEN_FROM=""   # "<tickle title><SEP><action>" per open next action whose from: links a live tickle
TODAY="$(date +%Y-%m-%d)"
INBOX="$GTD_DIR/inbox.md"
MINUTES_RE='^[0-9]+$'

# check_deps REL SELF VALUE — the depends_on: VALUE of the note at REL (SELF: next-actions/<Title>
# or projects/<Name>/README): one finding per link that is finished but not rewritten, cancelled,
# missing or a bad target; open links go to DEP_EDGES. Leaves DEP_BLOCKED (gtd_dep_eval) set.
check_deps() {
  local rel="$1" self="$2" t state path why title n
  DEP_BLOCKED=no
  if [ "$DEP_ON" -eq 0 ]; then return 0; fi
  gtd_dep_eval "$3" "$self"
  if [ "$DEP_LINKS" -eq 0 ]; then
    finding depends-form "$rel" "depends_on: holds no [[link]] -> a YAML list of quoted links to next actions, waiting-for items or projects"
    return 0
  fi
  while IFS="$SEP" read -r t state path why title; do
    [ -n "$t" ] || continue
    case "$state" in
      open) DEP_EDGES="$DEP_EDGES$self$SEP$path"$'\n' ;;
      done)
        case "$t" in
          _done/*|memory/gtd/_done/*) ;;
          *) n="${path#_done/}"; n="${n%/README}"
             finding depends-done-link "$rel" "depends_on: [[$t]] is finished -> [[$path|$n]]" ;;
        esac ;;
      cancelled) finding depends-cancelled "$rel" "depends_on: [[$t]] was cancelled: drop the dependency, cancel this too, or link what replaces it" ;;
      missing) finding depends-missing "$rel" "depends_on: [[$t]] resolves to no next action, waiting-for item or project" ;;
      *) finding depends-target "$rel" "depends_on: [[$t]] can't be a dependency: $why" ;;
    esac
  done <<EOF
$DEP_EACH
EOF
}

# check_open_item FILE — one note of $list (next-actions, waiting-for or tickler); gtd_fm_each
# calls it with the note's properties in FM_*.
check_open_item() {
  local f="$1" base rel recurring project form name due from ft tickle every lead hint cadence last
  local start open person delegated followup
  base="${f##*/}"; base="${base%.md}"
  rel="$list/$base.md"

  # A recurring tickle (valid every:) never puts its project on hold.
  recurring=0
  if [ "$list" = "tickler" ] && gtd_is_span "${FM_every:-}"; then recurring=1; fi

  DEP_BLOCKED=no
  if [ -n "${FM_depends_on:-}" ]; then
    case "$list" in
      next-actions) check_deps "$rel" "next-actions/$base" "$FM_depends_on" ;;
      waiting-for) finding depends-target "$rel" "depends_on: on a waiting-for item, which is already in someone's hands -> put it on the next action that has to wait" ;;
      *) finding depends-target "$rel" "depends_on: on a tickle, which already waits on its date -> put it on the next action it becomes" ;;
    esac
  fi

  project="${FM_project:-}"
  if [ -n "$project" ]; then
    project_name "$project"; form="$PN_FORM"; name="$PN_NAME"
    if [ -f "$GTD_DIR/projects/$name/README.md" ]; then
      # a routine never holds a project; an action whose dependency is broken can't move it
      [ "$recurring" -eq 1 ] || [ "$DEP_BLOCKED" = broken ] || LINKED="$LINKED$name"$'\n'
      [ "$list" != next-actions ] || [ "$DEP_BLOCKED" != no ] || READY="$READY$name"$'\n'
      if [ "$form" != "readme" ]; then
        finding link-form "$rel" "project: $project -> [[projects/$name/README|$name]]"
        FORM_DONE="$FORM_DONE$rel project"$'\n'
      fi
    elif [ -f "$GTD_DIR/_done/$name/README.md" ]; then
      finding orphan-closed "$rel" "project '$name' is already in _done/"
    else
      finding orphan "$rel" "project: $project resolves to no project folder"
    fi
  fi

  if [ "$list" = "next-actions" ]; then
    check_work_fields "$rel" "${FM_time:-}" "${FM_energy:-}" "${FM_context:-}" 1
    due="${FM_due:-}"
    [ -z "$due" ] || is_date "$due" || finding field "$rel" "due '$due' is not YYYY-MM-DD"
    # from: — the recurring tickle this action is one cycle of
    from="${FM_from:-}"
    if [ -n "$from" ]; then
      _gtd_from_title "$from"; ft="$GTD_FROM_TITLE"
      if [ -f "$GTD_DIR/tickler/$ft.md" ]; then
        OPEN_FROM="$OPEN_FROM$ft$SEP$base"$'\n'
        case "$from" in
          "[[tickler/$ft|"*"]]"|"[[tickler/$ft]]") ;;
          *) finding link-form "$rel" "from: $from -> [[tickler/$ft|$ft]]"
             FORM_DONE="$FORM_DONE$rel from"$'\n' ;;
        esac
      elif [ -f "$GTD_DIR/_done/$ft.md" ]; then
        finding orphan-closed "$rel" "from: tickle '$ft' has ended (it is in _done/)"
      else
        finding orphan "$rel" "from: $from resolves to no tickle"
      fi
    fi
  elif [ "$list" = "tickler" ]; then
    tickle="${FM_tickle:-}"
    every="${FM_every:-}"
    lead="${FM_lead:-}"
    if [ -n "$every" ] && [ "$recurring" -eq 0 ]; then
      hint="$(span_hint "$every")"
      finding tickler-every "$rel" "every '$every' is not <n><unit> (7d, 2w, 3m, 1y)${hint:+ -> every: $hint}; one-shot until fixed"
    fi
    if [ "$recurring" -eq 1 ]; then
      if [ -n "$lead" ] && ! gtd_is_span "$lead"; then
        hint="$(span_hint "$lead")"
        finding tickler-every "$rel" "lead '$lead' is not <n><unit> (7d, 2w, 3m, 1y)${hint:+ -> lead: $hint}; ignored until fixed"
      fi
      cadence="${FM_cadence:-}"
      [ -z "$cadence" ] || in_words "$cadence" "$CADENCE_VOCAB" || finding field "$rel" "cadence '$cadence' not in: $CADENCE_VOCAB"
      last="${FM_last_completed:-}"
      [ -z "$last" ] || is_date "$last" || finding field "$rel" "last_completed '$last' is not YYYY-MM-DD"
    fi
    check_work_fields "$rel" "${FM_time:-}" "${FM_energy:-}" "${FM_context:-}" 0
    if [ -z "$tickle" ]; then finding tickler-date "$rel" "missing tickle: date"
    elif ! is_date "$tickle"; then finding tickler-date "$rel" "tickle '$tickle' is not YYYY-MM-DD"
    elif [ "$recurring" -eq 1 ]; then
      start="$tickle"
      ! gtd_is_span "$lead" || start="$(gtd_date_add "$tickle" "$lead" -)"
      # OPEN_FROM is complete here: next-actions/ is read before tickler/.
      open=0
      case $'\n'"$OPEN_FROM" in *$'\n'"$base$SEP"*) open=1 ;; esac
      if [ ! "$start" \> "$TODAY" ] && [ "$open" -eq 0 ]; then
        finding tickler-due "$rel" "routine (every $every) due $tickle — no open action: create its next action"
      fi
      if [ "$tickle" \< "$TODAY" ]; then
        if [ "$open" -eq 1 ]; then finding tickler-overdue "$rel" "routine (every $every) was due $tickle — its action is still open"
        else finding tickler-overdue "$rel" "routine (every $every) was due $tickle — no open action"; fi
      fi
    elif [ ! "$tickle" \> "$TODAY" ]; then
      # An inbox line linking the note means organize already queued it for clarify.
      if [ -f "$INBOX" ] && { grep -qF "[[tickler/$base]]" "$INBOX" || grep -qF "[[tickler/$base|" "$INBOX"; }; then
        finding tickler-due "$rel" "tickle $tickle — queued in inbox"
      else
        finding tickler-due "$rel" "tickle $tickle — now actionable"
      fi
    fi
  else
    person="${FM_person:-}"
    delegated="${FM_delegated:-}"
    followup="${FM_follow_up:-}"
    [ -n "$person" ] || finding field "$rel" "missing person"
    if [ -z "$delegated" ]; then finding field "$rel" "missing delegated"
    elif ! is_date "$delegated"; then finding field "$rel" "delegated '$delegated' is not YYYY-MM-DD"; fi
    [ -z "$followup" ] || is_date "$followup" || finding field "$rel" "follow-up '$followup' is not YYYY-MM-DD"
  fi

}

# Resolve dependencies only when some note has any (one grep).
DEP_ON=0
if gtd_dep_needed "$GTD_DIR/next-actions" "$GTD_DIR/waiting-for" "$GTD_DIR/tickler" "$GTD_DIR/projects"; then
  gtd_dep_index; DEP_ON=1
fi

for list in next-actions waiting-for tickler; do
  dir="$GTD_DIR/$list"
  [ -d "$dir" ] || continue
  gtd_notes_in "$dir"
  gtd_fm_each check_open_item -- ${GTD_NOTES[@]+"${GTD_NOTES[@]}"}
done

# Two open actions for one routine: organize keeps the oldest and asks about the other.
from_dupes="$(printf '%s' "$OPEN_FROM" | cut -d"$SEP" -f1 | sort | uniq -d)"
while IFS= read -r d; do
  [ -n "$d" ] || continue
  matches="$(printf '%s' "$OPEN_FROM" | awk -F"$SEP" -v d="$d" '$1 == d { print $2 }' | paste -sd ';' - | sed 's/;/; /g')"
  finding duplicate "next-actions/" "same from: tickler/$d: $matches"
done <<EOF
$from_dupes
EOF

# --- project dependencies and cycles -------------------------------------------

# check_project_deps FILE — one project README; gtd_fm_each calls it with its properties in FM_*.
check_project_deps() {
  local name="${1%/README.md}"
  name="${name##*/}"
  [ -n "${FM_depends_on:-}" ] || return 0
  check_deps "projects/$name/README.md" "projects/$name/README" "$FM_depends_on"
  [ "$DEP_BLOCKED" = yes ] || return 0
  HELD="$HELD$name"$'\n'
  case $'\n'"$READY" in
    *$'\n'"$name"$'\n'*) finding depends-hold "projects/$name/README.md" "waits on $DEP_WAITS but still has unblocked next actions: on hold, or not?" ;;
  esac
}

if [ "$DEP_ON" -eq 1 ] && [ -d "$GTD_DIR/projects" ]; then
  PROJECT_READMES=()
  for readme in "$GTD_DIR"/projects/*/README.md; do
    [ -e "$readme" ] && PROJECT_READMES+=("$readme")
  done
  [ "${#PROJECT_READMES[@]}" -eq 0 ] || gtd_fm_each check_project_deps -- "${PROJECT_READMES[@]}"
fi

# Items that wait on each other: a depth-first search over the open dependencies, one line per
# cycle (rotated to start at its smallest member, so each is reported once).
if [ -n "$DEP_EDGES" ]; then
  while IFS= read -r cyc; do
    [ -n "$cyc" ] || continue
    finding depends-cycle "${cyc%% -> *}.md" "these wait on each other, so none can start: $cyc"
  done < <(printf '%s' "$DEP_EDGES" | awk -F"$SEP" '
    NF == 2 { if (!($1 in deg)) { nodes[++nn] = $1; deg[$1] = 0 }; adj[$1, ++deg[$1]] = $2 }
    function dfs(u, d,   i, v, j, m, k, s) {
      onst[u] = 1; pos[u] = d; stk[d] = u
      for (i = 1; i <= deg[u]; i++) {
        v = adj[u, i]
        if (onst[v]) {
          m = pos[v]
          for (j = pos[v]; j <= d; j++) if (stk[j] < stk[m]) m = j
          s = ""
          for (k = 0; k <= d - pos[v]; k++) s = s stk[pos[v] + (m - pos[v] + k) % (d - pos[v] + 1)] " -> "
          s = s stk[m]
          if (!(s in shown)) { shown[s] = 1; print s }
        } else if (!(v in seen)) dfs(v, d + 1)
      }
      onst[u] = 0; seen[u] = 1
    }
    END { for (n = 1; n <= nn; n++) if (!(nodes[n] in seen)) dfs(nodes[n], 1) }')
fi

# --- stalled projects ---------------------------------------------------------

if [ -d "$GTD_DIR/projects" ]; then
  for readme in "$GTD_DIR"/projects/*/README.md; do
    [ -e "$readme" ] || continue
    name="${readme%/README.md}"; name="${name##*/}"
    case $'\n'"$LINKED$HELD" in
      *$'\n'"$name"$'\n'*) ;;
      *) finding stalled "projects/$name/README.md" "no open next action, waiting-for or tickle links to it" ;;
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
      d="${d%/}"
      names="$names${d##*/}"$'\n'
    done
  else
    gtd_notes_in "$dir"
    for f in ${GTD_NOTES[@]+"${GTD_NOTES[@]}"}; do
      base="${f##*/}"
      names="$names${base%.md}"$'\n'
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

# aar_written — reads one note path per line on stdin, all in one awk, and prints each path
# whose After action review section (after the frontmatter) has text beyond an HTML comment.
aar_written() {
  awk '
    {
      f = $0; fm = 0; in_aar = 0; in_comment = 0
      while ((getline line < f) > 0) {
        if (line ~ /^---[[:space:]]*$/ && fm < 2) { fm++; continue }
        if (fm < 2) continue
        if (line ~ /^## After action review/) { in_aar = 1; continue }
        if (in_aar && line ~ /^## /) in_aar = 0
        if (in_aar && line ~ /<!--/) in_comment = 1
        if (in_aar && !in_comment && line ~ /[^[:space:]]/) { print f; break }
        if (in_comment && line ~ /-->/) in_comment = 0
      }
      close(f)
    }
  '
}

# check_done_item FILE — one _done/ note; gtd_fm_each calls it with the properties in FM_*.
check_done_item() {
  local f="$1" rel project
  rel="${f#"$GTD_DIR"/}"
  [ -n "${FM_completed:-}" ] || finding done-completed "$rel" "no completed: date"
  project="${FM_project:-}"
  if [ -n "$project" ]; then
    project_name "$project"
    if [ ! -d "$GTD_DIR/projects/$PN_NAME" ] && [ -f "$GTD_DIR/_done/$PN_NAME/README.md" ]; then
      finding done-link "$rel" "project: $project -> [[_done/$PN_NAME/README|$PN_NAME]]"
    fi
  fi
  if [ "${FM_list:-}" = "projects" ]; then
    case $'\n'"$AAR_WRITTEN"$'\n' in
      *$'\n'"$f"$'\n'*) ;;
      *) finding done-no-aar "$rel" "finished project closed with no after-action review" ;;
    esac
  fi
}

if [ -d "$GTD_DIR/_done" ]; then
  DONE_NOTES=()
  for f in "$GTD_DIR"/_done/*.md "$GTD_DIR"/_done/*/README.md; do
    [ -e "$f" ] || continue
    [ "$f" = "$GTD_DIR/_done/README.md" ] && continue
    DONE_NOTES+=("$f")
  done
  if [ "${#DONE_NOTES[@]}" -gt 0 ]; then
    AAR_WRITTEN="$(printf '%s\n' "${DONE_NOTES[@]}" | aar_written)"
    gtd_fm_each check_done_item -- "${DONE_NOTES[@]}"
  fi
fi

# --- wikilinks in frontmatter properties: memory/gtd/ and the root reference/ ---

# md_files DIR — every .md under DIR, hidden folders skipped, sorted
md_files() {
  [ -d "$1" ] || return 0
  find "$1" -mindepth 1 -name '.*' -prune -o -type f -name '*.md' -print | LC_ALL=C sort
}

REF_DIR="$GTD_WORKSPACE_ROOT/reference"
while IFS="$SEP" read -r f kind key msg; do
  [ -n "$kind" ] || continue
  case "$f" in
    "$GTD_DIR"/*) rel="${f#"$GTD_DIR"/}" ;;
    *) rel="reference/${f#"$REF_DIR"/}" ;;
  esac
  # a project: / from: link the link-form checks above already flagged gets one finding, not two
  case $'\n'"$FORM_DONE" in *$'\n'"$rel $key"$'\n'*) continue ;; esac
  finding "$kind" "$rel" "$msg"
done < <({ md_files "$GTD_DIR"; md_files "$REF_DIR"; } | fm_link_problems)

echo "# $FINDINGS finding(s)"
