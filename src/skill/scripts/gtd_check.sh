#!/usr/bin/env bash
# gtd_check.sh — read-only: organize's mechanical hygiene findings.
# It never fixes anything; organize reads the findings, fixes the mechanical ones, and batches
# the rest as questions (see organize/SKILL.md).
#
# Usage:
#   bash gtd_check.sh
#
# Output: one tab-separated line per finding — check, path (relative to memory/gtd/), detail —
# then a "# N finding(s)" line. Checks:
#   orphan          an open action / waiting-for / tickle whose project: link resolves to no project
#   orphan-closed   ...whose project has already moved to _done/ (surface: close or re-link)
#   link-form       project: points at the project but not as [[projects/<Name>/README|<Name>]];
#                   or, in any note under memory/gtd/, a frontmatter property whose wikilink isn't
#                   the whole quoted value — text before or after it (inside or outside the
#                   quotes), several links in one value, or an unquoted link. Obsidian shows
#                   those as plain text. Links in the note body are never checked.
#   stalled         a project folder with no open next action, waiting-for or tickle linked to it
#                   (list-definitions.md "Stalled": a tickle means on hold on purpose)
#   tickler-due     a tickle dated today or earlier (organize turns it into a next action, or adds
#                   an inbox pointer to it); "queued in inbox" when inbox.md already links the note
#   tickler-date    a tickle with no tickle: date, or one that isn't YYYY-MM-DD
#   field           missing or out-of-vocabulary property (vocabulary: list-definitions.md
#                   "Property values")
#   duplicate       two notes in one list with the same title, ignoring case and a "(N)" suffix
#   filename        a note or project folder name with a character unsafe on some filesystem
#   done-completed  a _done/ note with no completed: date (organize fills today's date)
#   done-no-aar     a finished project in _done/ whose After action review section is empty
#                   (surface once, at the next Weekly Review)
#   done-link       a _done/ note whose project: still points at projects/<Name>/ after that
#                   project's folder moved to _done/<Name>/ (organize rewrites it)
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

if [ ! -d "$GTD_DIR" ]; then
  echo "memory/gtd/ does not exist. Run first: bash gtd_init.sh" >&2
  exit 1
fi

gtd_refuse_single_file

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
  # text before the link is a property-link finding (below), not a different project
  case "$target" in *\[\[*) target="${target#*\[\[}"; target="${target%%]]*}"; target="${target%%|*}"; target="${target%%#*}" ;; esac
  case "$target" in
    projects/*/README) target="${target#projects/}"; printf 'readme%s%s\n' "$SEP" "${target%/README}" ;;
    projects/*) printf 'other%s%s\n' "$SEP" "${target#projects/}" ;;
    *) printf 'other%s%s\n' "$SEP" "$target" ;;
  esac
}

# fm_link_problems FILE — "key<SEP>message" for each frontmatter property (or list item) whose
# wikilink Obsidian won't render: the link must be the whole value, quoted ("[[Note|Label]]");
# several links are a YAML list, one quoted link per item. Reads only a frontmatter block that
# opens on line 1, so links in the body are never seen. Plain awk (no gawk extensions).
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
    # check LABEL KEY V — one scalar value (or one [a, b] list, item by item)
    function check(label, key, v,   q, rest, inner, c, shown, after, all, p, e, link, lead, trail, inside, bar, tgt, lbl, n, depth, item, items) {
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
        printf "%s%s%s: %s — %d links in one value -> a YAML list, one quoted link per item\n", key, SEP, label, shown, n
        return
      }
      p = index(all, "[["); e = index(substr(all, p + 2), "]]")
      link = substr(all, p, e + 3)
      lead = trim(substr(all, 1, p - 1)); trail = trim(substr(all, p + e + 3))
      if (lead == "" && trail == "") {
        if (q == "") printf "%s%s%s: %s — unquoted (YAML reads it as a nested list) -> \"%s\"\n", key, SEP, label, shown, link
        return
      }
      inside = substr(link, 3, length(link) - 4)
      if ((bar = index(inside, "|")) > 0) { tgt = substr(inside, 1, bar - 1); lbl = substr(inside, bar + 1) }
      else { tgt = inside; lbl = inside }
      if (lead != "") lbl = lead " " lbl
      if (trail != "") lbl = lbl " " trail
      printf "%s%s%s: %s — text outside the link -> \"[[%s|%s]]\"\n", key, SEP, label, shown, tgt, lbl
    }
    { sub(/\r$/, "") }
    NR == 1 { if ($0 ~ /^---[[:space:]]*$/) next; exit }
    /^(---|\.\.\.)[[:space:]]*$/ { exit }
    match($0, /^[A-Za-z_][A-Za-z0-9_ .-]*:/) {
      key = substr($0, 1, RLENGTH - 1); items = 0
      check(key, key, substr($0, RLENGTH + 1))
      next
    }
    /^[[:space:]]*-[[:space:]]/ && key != "" {
      items++
      v = $0; sub(/^[[:space:]]*-[[:space:]]+/, "", v)
      check(key " (item " items ")", key, v)
    }
  ' "$1"
}

# --- open actions and waiting-for: project links + fields --------------------

LINKED=""   # newline-separated project names that have at least one open action / waiting-for / tickle
PROJECT_FORM=""   # notes already given a project: link-form finding (property links skip their project:)
TODAY="$(date +%Y-%m-%d)"
INBOX="$GTD_DIR/inbox.md"

for list in next-actions waiting-for tickler; do
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
        if [ "$form" != "readme" ]; then
          finding link-form "$rel" "project: $project -> [[projects/$name/README|$name]]"
          PROJECT_FORM="$PROJECT_FORM$rel"$'\n'
        fi
      elif [ -f "$GTD_DIR/_done/$name/README.md" ]; then
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
    elif [ "$list" = "tickler" ]; then
      tickle="$(fm_get "$f" tickle)"
      if [ -z "$tickle" ]; then finding tickler-date "$rel" "missing tickle: date"
      elif ! is_date "$tickle"; then finding tickler-date "$rel" "tickle '$tickle' is not YYYY-MM-DD"
      elif [ ! "$tickle" \> "$TODAY" ]; then
        # An inbox line linking the note means organize already queued it for clarify.
        if [ -f "$INBOX" ] && { grep -qF "[[tickler/$base]]" "$INBOX" || grep -qF "[[tickler/$base|" "$INBOX"; }; then
          finding tickler-due "$rel" "tickle $tickle — queued in inbox"
        else
          finding tickler-due "$rel" "tickle $tickle — now actionable"
        fi
      fi
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
    project="$(fm_get "$f" project)"
    if [ -n "$project" ]; then
      IFS="$SEP" read -r form name < <(project_name "$project")
      if [ ! -d "$GTD_DIR/projects/$name" ] && [ -f "$GTD_DIR/_done/$name/README.md" ]; then
        finding done-link "$rel" "project: $project -> [[_done/$name/README|$name]]"
      fi
    fi
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

# --- wikilinks in frontmatter properties, every note under memory/gtd/ ---------

while IFS= read -r f; do
  rel="${f#"$GTD_DIR"/}"
  while IFS="$SEP" read -r key msg; do
    [ -n "$key" ] || continue
    # a project: link already flagged above gets one finding, not two
    if [ "$key" = "project" ]; then
      case $'\n'"$PROJECT_FORM" in *$'\n'"$rel"$'\n'*) continue ;; esac
    fi
    finding link-form "$rel" "$msg"
  done < <(fm_link_problems "$f")
done < <(find "$GTD_DIR" -mindepth 1 -name '.*' -prune -o -type f -name '*.md' -print | LC_ALL=C sort)

echo "# $FINDINGS finding(s)"
