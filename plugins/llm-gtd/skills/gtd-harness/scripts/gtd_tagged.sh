#!/usr/bin/env bash
# gtd_tagged.sh — read-only: list the notes anywhere in the workspace tagged gtd-update, so
# /gtd-update can apply the updates written into them (references/list-definitions.md
# "Tagged-note updates").
#
# Usage:
#   bash gtd_tagged.sh
#
# Output: one tab-separated line per tagged note, sorted by path —
#   <path from the workspace root>  updates=<N>  <title>
# N counts the lines still to apply: each non-empty line under a heading whose text is exactly
# "Update" (any level, any case; the section runs to the next heading of the same or a higher
# level), except lines ending in ✓ (applied in an earlier, partly finished run). A heading
# "Update (applied YYYY-MM-DD)" is history and never counted. updates=0 means tagged but nothing
# to apply.
#
# A note is tagged when its frontmatter tags: / tag: holds gtd-update (a [a, b] list, a block
# list, or a single value) or its body has an inline #gtd-update — as in Obsidian, not inside
# inline code or a fenced code block, and not a nested tag like #gtd-update/later.
# Skipped: hidden folders (.obsidian/, .trash/, .git/, …) and memory/gtd/_done/.
#
# Compatible with macOS bash 3.2 and BSD find / grep / awk.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"
ROOT="$GTD_WORKSPACE_ROOT"
gtd_refuse_single_file

# tagged_updates FILE — prints the number of lines to apply when FILE is tagged, nothing otherwise
tagged_updates() {
  awk '
    function lower(s) { return tolower(s) }
    # tag_value V — true when one frontmatter tag value is gtd-update
    function tag_value(v) {
      gsub(/^[[:space:]"'"'"']+|[[:space:]"'"'"']+$/, "", v)
      sub(/^#/, "", v)
      return lower(v) == "gtd-update"
    }
    { sub(/\r$/, "") }
    NR == 1 && /^---[[:space:]]*$/ { infm = 1; next }
    infm {
      if (/^(---|\.\.\.)[[:space:]]*$/) { infm = 0; next }
      if (match($0, /^[A-Za-z_][A-Za-z0-9_-]*:/)) {
        key = lower(substr($0, 1, RLENGTH - 1)); v = substr($0, RLENGTH + 1)
        intags = (key == "tags" || key == "tag")
        if (intags) {
          gsub(/^[[:space:]]*\[|\][[:space:]]*$/, "", v)
          n = split(v, parts, ",")
          for (i = 1; i <= n; i++) if (tag_value(parts[i])) tagged = 1
        }
        next
      }
      if (intags && /^[[:space:]]*-[[:space:]]/) {
        v = $0; sub(/^[[:space:]]*-[[:space:]]+/, "", v)
        if (tag_value(v)) tagged = 1
      }
      next
    }
    # fenced code blocks: no tags, no headings
    /^[[:space:]]*(```|~~~)/ { fence = !fence; next }
    fence { next }
    {
      line = $0
      gsub(/`[^`]*`/, "", line)
      # an inline tag, anywhere outside code (a heading line included)
      probe = line
      while (match(probe, /(^|[[:space:]])#gtd-update/)) {
        if (substr(probe, RSTART + RLENGTH, 1) !~ /[A-Za-z0-9_\/-]/) { tagged = 1; break }
        probe = substr(probe, RSTART + RLENGTH)
      }
      if (match(line, /^#+[[:space:]]/)) {
        lvl = RLENGTH - 1; h = substr(line, RLENGTH + 1)
        sub(/[[:space:]#]+$/, "", h); sub(/^[[:space:]]+/, "", h)
        if (inupd && lvl <= updlvl) inupd = 0
        if (lower(h) == "update") { inupd = 1; updlvl = lvl; next }
      }
      if (inupd) {
        t = $0; gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
        if (t != "" && t != "-" && t != "*" && t !~ /✓$/) updates++
      }
    }
    END { if (tagged) print updates + 0 }
  ' "$1"
}

find "$ROOT" -mindepth 1 -name '.*' -prune -o -type f -name '*.md' -print0 2>/dev/null \
  | { xargs -0 grep -lF -- 'gtd-update' 2>/dev/null || true; } \
  | LC_ALL=C sort \
  | while IFS= read -r f; do
      rel="${f#"$ROOT"/}"
      case "$rel" in memory/gtd/_done/*) continue ;; esac
      n="$(tagged_updates "$f")"
      [ -n "$n" ] || continue
      title="$(basename "$f" .md)"
      printf '%s\tupdates=%s\t%s\n' "$rel" "$n" "$title"
    done
