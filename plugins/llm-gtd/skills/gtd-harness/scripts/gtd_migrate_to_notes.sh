#!/usr/bin/env bash
# gtd_migrate_to_notes.sh — move a single-file GTD system to the per-item layout, in one reversible step.
#
# Usage:
#   bash gtd_migrate_to_notes.sh                     # dry run (the default): print what would be written, change nothing
#   bash gtd_migrate_to_notes.sh --apply             # do it
#   options: --titles FILE    tab-separated "key<TAB>Title" overrides for note titles; key is the item's id
#                             (^na-… / ^wf-… without the ^) or, for an item without one, the title the dry run proposed
#            --with-bases     also write the starter Obsidian .base lens views (passed to gtd_init.sh)
#            --allow-no-git   apply even though the workspace is not a git repository (make a backup first)
#
# What it does (see references/list-definitions.md "Layouts" and "Note formats"):
#   - next-actions / waiting-for / someday-maybe lines -> one note each, fields -> frontmatter
#     (Time/Energy/Constraint/Project/Source/Date/Due; legacy @groups -> context), text + free-text
#     constraint -> body; the old ^id is kept as id:
#   - projects.md "## Name" blocks -> projects/<Name>/README.md (outcome, notes, support material);
#     the hand-kept "Next actions" links are dropped — the action notes' project: field replaces them
#   - product-ideas.md "### Idea" blocks -> product-ideas/<Idea>.md
#   - reference.md "### Entry" blocks -> an entry used by exactly one project goes into that project's
#     folder; everything else -> reference/<Entry>.md at the workspace root
#   - done.md (if any) -> _done/ notes; a finished project line -> _done/<Name>/README.md
#   - every list's header and group notes (every line that isn't an item) -> <list>/README.md
#   - links anywhere in the workspace: [[next-actions#^id|…]] -> [[next-actions/<Title>|…]],
#     [[projects#Name|…]] -> [[projects/<Name>/README|…]], [[reference#Entry|…]] -> the new note,
#     bare [[projects]] -> [[projects/README|projects]], … (never inside `code` or ``` fences)
#   - the old list files move to memory/gtd/_migrated/ (never deleted); then gtd_init.sh fills in
#     _done/README.md, reference/README.md and (with --with-bases) the .base views
#   - areas/<dir>/ folders a project links to are listed for you to fold into that project's folder
#     by hand (git mv) — outside memory/gtd/, so never moved automatically
#
# Refuses: a workspace that is already (partly) per-item; --apply with uncommitted git changes.
# Compatible with macOS bash 3.2 and POSIX awk (no gawk extensions).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"
ROOT="$GTD_WORKSPACE_ROOT"
GTD_DIR="$ROOT/memory/gtd"
TEMPLATES="$GTD_SKILL_DIR/templates"

APPLY=0
TITLES=""
WITH_BASES=0
ALLOW_NO_GIT=0
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --titles) TITLES="$2"; shift 2 ;;
    --with-bases) WITH_BASES=1; shift ;;
    --allow-no-git) ALLOW_NO_GIT=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

die() { echo "gtd_migrate_to_notes: $1" >&2; exit "${2:-1}"; }

# --- preflight -------------------------------------------------------------------

[ -d "$GTD_DIR" ] || die "no memory/gtd/ under $ROOT"
for l in $GTD_NOTE_LISTS _done; do
  [ ! -e "$GTD_DIR/$l" ] || die "memory/gtd/$l/ already exists — this workspace is already (partly) per-item; finish or undo that first" 4
done
[ -f "$GTD_DIR/next-actions.md" ] || die "no memory/gtd/next-actions.md — nothing to migrate"
[ ! -e "$GTD_DIR/_migrated" ] || die "memory/gtd/_migrated/ already exists — a previous migration's backup; move it aside first" 4
if [ -n "$TITLES" ]; then
  [ -f "$TITLES" ] || die "--titles file not found: $TITLES" 2
fi

git_state="not a git repository"
if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if [ -z "$(git -C "$ROOT" status --porcelain)" ]; then git_state="clean"; else git_state="uncommitted changes"; fi
fi
if [ "$APPLY" -eq 1 ]; then
  case "$git_state" in
    clean) ;;
    "uncommitted changes") die "the workspace has uncommitted git changes — commit them first so the migration is one reversible commit" 5 ;;
    *) [ "$ALLOW_NO_GIT" -eq 1 ] || die "the workspace is not a git repository — back it up, then rerun with --allow-no-git" 5 ;;
  esac
fi

TODAY="$(date +%Y-%m-%d)"
STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT
S="$STAGE/tree"                 # the files to be written, mirroring the workspace
MAP="$STAGE/linkmap.tsv"        # old link target <TAB> new link target <TAB> default alias
MANIFEST="$STAGE/manifest.tsv"  # list <TAB> path <TAB> summary
REFUSE="$STAGE/refuse.tsv"      # reference entry <TAB> project that links it
AREAS="$STAGE/areas.tsv"        # areas/<dir> <TAB> project that links it
mkdir -p "$S/memory/gtd" "$S/reference"
: > "$MAP"; : > "$MANIFEST"; : > "$REFUSE"; : > "$AREAS"
for l in $GTD_NOTE_LISTS; do mkdir -p "$S/memory/gtd/$l"; done

# Names already taken in the workspace-root reference/ folder (it may predate the migration).
EXISTING_REF="$STAGE/existing-ref.txt"
: > "$EXISTING_REF"
if [ -d "$ROOT/reference" ]; then
  for f in "$ROOT"/reference/*.md; do [ -e "$f" ] && basename "$f" .md >> "$EXISTING_REF"; done
fi

# --- shared awk library ----------------------------------------------------------------

AWK_LIB='
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }
# plain: markdown -> text, for titles ([[a|b]] -> b, [t](u) -> t, drop * and `)
function plain(s,   inner, t, bar) {
  while (match(s, /\[\[[^]]*\]\]/)) {
    inner = substr(s, RSTART + 2, RLENGTH - 4)
    bar = index(inner, "|")
    if (bar) inner = substr(inner, bar + 1); else { sub(/#.*$/, "", inner); sub(/^.*\//, "", inner) }
    s = substr(s, 1, RSTART - 1) inner substr(s, RSTART + RLENGTH)
  }
  while (match(s, /\[[^]]*\]\([^)]*\)/)) {
    t = substr(s, RSTART + 1, RLENGTH - 1); sub(/\]\(.*$/, "", t)
    s = substr(s, 1, RSTART - 1) t substr(s, RSTART + RLENGTH)
  }
  gsub(/[`*]/, "", s)
  return s
}
# safe: a filesystem- and Obsidian-link-safe name (no : / \ ? * " < > | # ^ [ ])
function safe(s) {
  while (match(s, /[0-9]:[0-9]/)) s = substr(s, 1, RSTART) "." substr(s, RSTART + 2)   # 07:00 -> 07.00
  gsub(/:/, " -", s); gsub(/\//, "-", s)
  gsub(/[\\?*"<>|#^]/, "", s); gsub(/[][]/, "", s)
  gsub(/[ \t]+/, " ", s); s = trim(s); sub(/[. ]+$/, "", s)
  return s
}
# short: a proposed note title — the first clause of the text, capped at 70 characters
function short(s,   n, i, p, cut, seps) {
  s = plain(s)
  cut = length(s)
  n = split(" (|; | — | -- |. |, then ", seps, "|")
  for (i = 1; i <= n; i++) { p = index(s, seps[i]); if (p > 15 && p - 1 < cut) cut = p - 1 }
  s = safe(substr(s, 1, cut))
  if (length(s) > 70) { s = substr(s, 1, 70); sub(/ [^ ]*$/, "", s) }
  sub(/[,;: -]+$/, "", s)
  if (s == "") s = "Untitled"
  return s
}
# unique: add " (2)", " (3)", … on a (case-insensitive) collision within one folder
function unique(folder, t,   n) {
  if (tolower(t) == "readme") t = t " (2)"
  if (!((folder SUBSEP tolower(t)) in used)) { used[folder SUBSEP tolower(t)] = 1; return t }
  n = 2
  while ((folder SUBSEP tolower(t " (" n ")")) in used) n++
  used[folder SUBSEP tolower(t " (" n ")")] = 1
  return t " (" n ")"
}
# shq: single-quote for sh (system() runs a shell, and a name may hold $ or `)
function shq(s,   n, parts, i, out) {
  n = split(s, parts, "\047"); out = parts[1]
  for (i = 2; i <= n; i++) out = out "\047\\\047\047" parts[i]
  return "\047" out "\047"
}
# folder_name: a project heading -> its folder (the same rule wherever a project is named)
function folder_name(n) { return safe(plain(n)) }
function yq(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return "\"" s "\"" }
function isodate(s) {
  s = trim(s)
  if (s ~ /^[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]$/) return substr(s, 1, 4) "-" substr(s, 5, 2) "-" substr(s, 7, 2)
  if (s ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) return s
  return ""
}
function minutes(s,   m, best, t, v) {
  best = ""
  t = s
  while (match(t, /[0-9]+/)) { v = substr(t, RSTART, RLENGTH) + 0; if (best == "" || v > best) best = v; t = substr(t, RSTART + RLENGTH) }
  if (best != "" && tolower(s) ~ /(h|hr|hrs|hour|hours)([^a-z]|$)/ && tolower(s) !~ /min/) best = best * 60
  return best
}
function energy(s) {
  s = tolower(s)
  if (s ~ /emotional/) return "low-emotional"
  if (s ~ /deep/) return "deep"
  if (s ~ /medium/) return "medium"
  if (s ~ /low/) return "low"
  return ""
}
# contexts: the list-definitions "Property values" vocabulary, from the Constraint text and legacy group
function contexts(c, group,   out, l) {
  l = " " tolower(plain(c)) " "
  out = ""
  if (group == "computer" || l ~ /computer|laptop|online|ssh|terminal/) out = out ", computer"
  if (group == "phone" || l ~ /phone|call /) out = out ", phone"
  if (group == "errands" || l ~ /errand|shopping|store|on the way|pick up/) out = out ", errands"
  if (group == "home" || l ~ /at home|garage|house/) out = out ", home"
  if (group == "person-present" || l ~ /person present|[^a-z]in person[^a-z]|face to face/) out = out ", person-present"
  if (l ~ /before (the |a )?meeting/) out = out ", before-meeting"
  if (l ~ /prep chain|prep-chain/) out = out ", prep-chain"
  if (l ~ /payment|pay /) out = out ", payment"
  if (l ~ /document|passport|paperwork|tax bill| id /) out = out ", documents"
  if (l ~ /equipment/) out = out ", equipment"
  sub(/^, /, "", out)
  return out
}
function group_context(h) {
  h = tolower(h)
  if (h ~ /@computer/) return "computer"
  if (h ~ /@calls/) return "phone"
  if (h ~ /@errands/) return "errands"
  if (h ~ /@home/) return "home"
  if (h ~ /@agenda/) return "person-present"
  return ""
}
# project_name: "[[projects#Name|Alias]]" (or plain text) -> Name
function project_name(p,   t) {
  p = trim(p)
  if (match(p, /\[\[[^]]*\]\]/)) {
    t = substr(p, RSTART + 2, RLENGTH - 4); sub(/\|.*$/, "", t)
    if (t ~ /#/) sub(/^[^#]*#/, "", t)
    return trim(t)
  }
  return p
}
function project_link(name) { return yq("[[projects/" folder_name(name) "/README|" folder_name(name) "]]") }
function load_titles(   line, k) {
  if (TITLES == "") return
  while ((getline line < TITLES) > 0) {
    k = index(line, "\t"); if (!k) continue
    title_override[substr(line, 1, k - 1)] = substr(line, k + 1)
  }
  close(TITLES)
}
function load_existing(   line) {
  while ((getline line < EXISTING) > 0) used["reference" SUBSEP tolower(line)] = 1
  close(EXISTING)
}
function pick_title(key, text) { if (key in title_override) return safe(title_override[key]); return short(text) }
# readme_line: a non-item line goes to the list README; a heading there keeps its links working
# ([[someday-maybe#Incubating|…]] -> [[someday-maybe/README#Incubating|…]])
function readme_line(list, path, line,   h) {
  print line > path
  if (line ~ /^#+ /) { h = line; sub(/^#+ /, "", h); h = trim(h); maplink(list "#" h, list "/README#" h, h) }
}
function manifest(list, path, summary) { printf "%s\t%s\t%s\n", list, path, summary >> MANIFEST; close(MANIFEST) }
function maplink(old, new, alias) { printf "%s\t%s\t%s\n", old, new, alias >> MAP; close(MAP) }
function write_fm(path, keys, vals, n,   i) {
  print "---" > path
  for (i = 1; i <= n; i++) if (vals[i] != "") print keys[i] ": " vals[i] > path
  print "---" > path
}
# split_item: "- [ ] a · K: v · … ^id" -> parts[], returns count; sets ITEM_ID
function split_item(line, parts,   n) {
  sub(/^- \[[ x]\] /, "", line)
  ITEM_ID = ""
  if (match(line, /[ \t]\^[A-Za-z0-9_-]+[ \t]*$/)) { ITEM_ID = trim(substr(line, RSTART + 1)); sub(/^\^/, "", ITEM_ID); line = substr(line, 1, RSTART - 1) }
  n = split(line, parts, " · ")
  return n
}
function field_key(p) { if (match(p, /^[A-Za-z][A-Za-z -]*:/)) return tolower(substr(p, 1, RLENGTH - 1)); return "" }
function field_val(p) { sub(/^[A-Za-z][A-Za-z -]*:[ \t]*/, "", p); return trim(p) }
'

run_awk() {
  # run_awk [-v VAR=VALUE ...] PROGRAM FILE... — the library plus a program, with the shared variables
  local -a vars=()
  while [ "$1" = "-v" ]; do vars+=(-v "$2"); shift 2; done
  local prog="$1"; shift
  awk -v S="$S" -v MAP="$MAP" -v MANIFEST="$MANIFEST" -v TITLES="$TITLES" -v EXISTING="$EXISTING_REF" \
      -v REFUSE="$REFUSE" -v AREAS="$AREAS" -v TODAY="$TODAY" ${vars[@]+"${vars[@]}"} "$AWK_LIB$prog" "$@"
}

# --- line-item lists: next-actions, waiting-for, someday-maybe --------------------------

# Every non-item line of a list goes to its README (header, group headings, group notes);
# an item is a "- [ ] " line plus any indented continuation lines under it.
migrate_line_list() {
  local list="$1" f="$GTD_DIR/$1.md"
  [ -f "$f" ] || return 0
  run_awk -v LIST="$list" '
    BEGIN { load_titles(); readme = S "/memory/gtd/" LIST "/README.md"; group = "" }
    function flush(   n, parts, i, k, v, text, title, path, keys, vals, extra, body, ctx, constraint, t, e, proj, due, src, created, person, deleg, fup, trig, nk) {
      if (!have) return
      n = split_item(item, parts)
      text = trim(parts[1]); extra = ""; constraint = ""; t = ""; e = ""; proj = ""; due = ""; src = ""; created = ""
      person = ""; deleg = ""; fup = ""; trig = ""
      if (LIST == "waiting-for" && n >= 2) { person = text; gsub(/^\[|\]$/, "", person); text = trim(parts[2]); i0 = 3 } else i0 = 2
      for (i = i0; i <= n; i++) {
        k = field_key(parts[i]); v = field_val(parts[i])
        if (k == "time") t = v
        else if (k == "energy") e = v
        else if (k == "constraint") constraint = v
        else if (k == "project") proj = v
        else if (k == "source") src = v
        else if (k == "date") created = v
        else if (k == "due") due = v
        else if (k == "delegated") deleg = v
        else if (k == "follow-up" || k == "follow up") fup = v
        else if (k == "trigger") trig = v
        else extra = extra "\n" trim(parts[i])
      }
      title = unique(LIST, pick_title(ITEM_ID != "" ? ITEM_ID : short(text), text))
      path = S "/memory/gtd/" LIST "/" title ".md"
      nk = 0
      keys[++nk] = "id"; vals[nk] = ITEM_ID
      if (LIST == "next-actions") {
        keys[++nk] = "time"; vals[nk] = minutes(t)
        keys[++nk] = "energy"; vals[nk] = energy(e)
        ctx = contexts(constraint, group)
        keys[++nk] = "context"; vals[nk] = (ctx == "" ? "" : "[" ctx "]")
      }
      if (LIST == "waiting-for") {
        keys[++nk] = "person"; vals[nk] = (person == "" ? "" : yq(person))
        keys[++nk] = "delegated"; vals[nk] = isodate(deleg)
        keys[++nk] = "follow-up"; vals[nk] = isodate(fup)
      }
      if (LIST == "someday-maybe") { keys[++nk] = "trigger"; vals[nk] = (trig == "" ? "" : yq(trig)) }
      keys[++nk] = "project"; vals[nk] = (proj == "" ? "" : project_link(project_name(proj)))
      keys[++nk] = "due"; vals[nk] = isodate(due)
      keys[++nk] = "source"; vals[nk] = (src == "" ? "" : yq(src))
      keys[++nk] = "created"; vals[nk] = isodate(created != "" ? created : deleg)
      write_fm(path, keys, vals, nk)
      body = text
      if (constraint != "") body = body "\nConstraint: " constraint
      if (due != "" && isodate(due) == "") body = body "\nDue: " due
      if (deleg != "" && isodate(deleg) == "") body = body "\nDelegated: " deleg
      if (fup != "" && isodate(fup) == "") body = body "\nFollow-up: " fup
      if (extra != "") body = body extra
      if (cont != "") body = body "\n" cont
      print body > path
      close(path)
      if (ITEM_ID != "") maplink(LIST "#^" ITEM_ID, LIST "/" title, title)
      manifest(LIST, "memory/gtd/" LIST "/" title ".md", (LIST == "next-actions" ? "time=" minutes(t) " energy=" energy(e) " context=" ctx : (LIST == "waiting-for" ? "person=" person : "trigger=" trig)) (proj == "" ? "" : " project=" folder_name(project_name(proj))))
      have = 0; cont = ""
    }
    /^- \[ \] / { flush(); have = 1; item = $0; cont = ""; next }
    have && /^[ \t]+[^ \t]/ { sub(/^  /, ""); cont = (cont == "" ? $0 : cont "\n" $0); next }
    { flush() }
    /^#+ / { g = group_context($0); if (g != "" || $0 ~ /^## /) group = g }
    { readme_line(LIST, readme, $0) }
    END { flush() }
  ' "$f"
}

# --- projects.md -------------------------------------------------------------------------

migrate_projects() {
  local f="$GTD_DIR/projects.md"
  [ -f "$f" ] || return 0
  run_awk -v NEXT_ACTIONS="$1" '
    BEGIN { load_titles(); readme = S "/memory/gtd/projects/README.md" }
    function flush(   dir, path, i, line, k, outcome, src, created, notes, support, t, keys, vals, nk, skip, r, a) {
      if (name == "") return
      folder = unique("projects", folder_name(name))
      dir = S "/memory/gtd/projects/" folder
      system("mkdir -p " shq(dir))
      path = dir "/README.md"
      outcome = ""; src = ""; created = ""; notes = ""; support = ""; skip = 0
      for (i = 1; i <= nl; i++) {
        line = lines[i]
        if (line ~ /^- Desired outcome:/) { outcome = line; sub(/^- Desired outcome:[ \t]*/, "", outcome); skip = 0; continue }
        if (line ~ /^- Next actions:/) { skip = 1; continue }
        if (skip && line ~ /^[ \t]+/) continue
        skip = 0
        if (line ~ /^- Source:/) {
          t = line; sub(/^- Source:[ \t]*/, "", t)
          if (match(t, / · Date:[ \t]*[0-9]+/)) { created = substr(t, RSTART, RLENGTH); sub(/^ · Date:[ \t]*/, "", created); t = substr(t, 1, RSTART - 1) }
          src = trim(t); continue
        }
        if (line ~ /^- Support material:/) { t = line; sub(/^- Support material:[ \t]*/, "", t); support = support "- " t "\n"; continue }
        if (line ~ /^[ \t]*$/ && notes == "") continue
        notes = notes line "\n"
      }
      nk = 0
      keys[++nk] = "outcome"; vals[nk] = (outcome == "" ? "" : yq(plain(outcome)))
      keys[++nk] = "source"; vals[nk] = (src == "" ? "" : yq(src))
      keys[++nk] = "created"; vals[nk] = isodate(created)
      write_fm(path, keys, vals, nk)
      if (outcome != "") print outcome "\n" > path
      if (notes != "") { sub(/\n+$/, "\n", notes); printf "## Notes\n\n%s\n", notes > path }
      print "## Next actions\n" NEXT_ACTIONS "\n" > path
      if (support != "") printf "## Support material\n\n%s\n", support > path
      print "## After action review\n<!-- Added once the outcome is achieved (templates/after-action-review.md). -->" > path
      close(path)
      maplink("projects#" name, "projects/" folder "/README", name)
      manifest("projects", "memory/gtd/projects/" folder "/README.md", "outcome=" substr(plain(outcome), 1, 60))
      # Which reference entries and areas/ folders this project points at.
      for (i = 1; i <= nl; i++) {
        line = lines[i]
        while (match(line, /\[\[reference#[^]|]*/)) { r = substr(line, RSTART + 12, RLENGTH - 12); printf "%s\t%s\n", r, folder >> REFUSE; line = substr(line, RSTART + RLENGTH) }
        line = lines[i]
        while (match(line, /\[\[areas\/[^]\/|]+/)) { a = substr(line, RSTART + 2, RLENGTH - 2); printf "%s\t%s\n", a, folder >> AREAS; line = substr(line, RSTART + RLENGTH) }
      }
      close(REFUSE); close(AREAS)
      name = ""; nl = 0
    }
    /^## / { flush(); name = $0; sub(/^## /, "", name); name = trim(name); nl = 0; next }
    name != "" { lines[++nl] = $0; next }
    { readme_line("projects", readme, $0) }
    END { flush() }
  ' "$f"
}

# --- product-ideas.md ----------------------------------------------------------------------

migrate_product_ideas() {
  local f="$GTD_DIR/product-ideas.md"
  [ -f "$f" ] || return 0
  run_awk '
    BEGIN { load_titles(); readme = S "/memory/gtd/product-ideas/README.md" }
    function firstpart(s) { s = plain(s); sub(/ — .*$/, "", s); sub(/\. .*$/, "", s); gsub(/"/, "", s); if (length(s) > 120) s = substr(s, 1, 117) "..."; return trim(s) }
    function flush(   title, path, i, line, ev, pr, keys, vals, nk) {
      if (name == "") return
      title = unique("product-ideas", safe(name in title_override ? title_override[name] : name))
      path = S "/memory/gtd/product-ideas/" title ".md"
      ev = ""; pr = ""
      for (i = 1; i <= nl; i++) {
        line = lines[i]
        if (line ~ /^- Evidence status:/ && ev == "") { ev = line; sub(/^- Evidence status:[ \t]*/, "", ev) }
        if (line ~ /^- Promotion criteria:/ && pr == "") { pr = line; sub(/^- Promotion criteria:[ \t]*/, "", pr) }
      }
      nk = 0
      keys[++nk] = "evidence"; vals[nk] = (ev == "" ? "" : yq(firstpart(ev)))
      keys[++nk] = "promotion"; vals[nk] = (pr == "" ? "" : yq(firstpart(pr)))
      keys[++nk] = "source"; vals[nk] = yq("migrated from product-ideas.md")
      keys[++nk] = "created"; vals[nk] = TODAY
      write_fm(path, keys, vals, nk)
      for (i = 1; i <= nl; i++) {
        line = lines[i]
        if (i == 1 && line ~ /^[ \t]*$/) continue
        sub(/^- \[[ x]\] Opportunity:/, "Opportunity:", line)
        print line > path
      }
      close(path)
      maplink("product-ideas#" name, "product-ideas/" title, name)
      manifest("product-ideas", "memory/gtd/product-ideas/" title ".md", "evidence=" firstpart(ev))
      name = ""; nl = 0
    }
    /^### / { flush(); name = $0; sub(/^### /, "", name); name = trim(name); nl = 0; next }
    /^##? / { flush(); readme_line("product-ideas", readme, $0); next }
    name != "" { lines[++nl] = $0; next }
    { readme_line("product-ideas", readme, $0) }
    END { flush() }
  ' "$f"
}

# --- reference.md ---------------------------------------------------------------------------

migrate_reference() {
  local f="$GTD_DIR/reference.md"
  [ -f "$f" ] || return 0
  run_awk '
    BEGIN {
      load_existing()
      readme = S "/reference/README.md"
      while ((getline line < REFUSE) > 0) { k = index(line, "\t"); e = substr(line, 1, k - 1); p = substr(line, k + 1); if (!((e SUBSEP p) in seen)) { seen[e SUBSEP p] = 1; nuse[e]++; owner[e] = p } }
      close(REFUSE)
    }
    function flush(   title, path, dir, rel, i, keys, vals, nk, proj) {
      if (name == "") return
      proj = (nuse[name] == 1 ? owner[name] : "")
      if (proj != "") { title = unique("projects/" proj, safe(name)); dir = S "/memory/gtd/projects/" proj; rel = "projects/" proj "/" title }
      else { title = unique("reference", safe(name)); dir = S "/reference"; rel = "reference/" title }
      path = dir "/" title ".md"
      nk = 0
      keys[++nk] = "source"; vals[nk] = yq("migrated from reference.md (" section ")")
      keys[++nk] = "created"; vals[nk] = TODAY
      write_fm(path, keys, vals, nk)
      for (i = 1; i <= nl; i++) { if (i == 1 && lines[i] ~ /^[ \t]*$/) continue; print lines[i] > path }
      close(path)
      maplink("reference#" name, rel, name)
      manifest(proj != "" ? "reference -> project" : "reference", (proj != "" ? "memory/gtd/" : "") rel ".md", (proj != "" ? "used only by project " proj : section))
      name = ""; nl = 0
    }
    /^### / { flush(); name = $0; sub(/^### /, "", name); name = trim(name); nl = 0; next }
    /^##? / { flush(); if ($0 ~ /^## /) { section = $0; sub(/^## /, "", section) } readme_line("reference", readme, $0); next }
    name != "" { lines[++nl] = $0; next }
    { readme_line("reference", readme, $0) }
    END { flush() }
  ' "$f"
}

# --- done.md ------------------------------------------------------------------------------

migrate_done() {
  local f="$GTD_DIR/done.md"
  [ -f "$f" ] || return 0
  mkdir -p "$S/memory/gtd/_done"
  run_awk '
    BEGIN { load_titles(); readme = S "/memory/gtd/_done/README.from-done-md.md" }
    function flush(   n, parts, i, k, v, text, title, path, dir, from, result, proj, keys, vals, nk, outcome, pname) {
      if (!have) return
      n = split_item(item, parts)
      text = trim(parts[1]); from = ""; result = ""; proj = ""
      for (i = 2; i <= n; i++) {
        k = field_key(parts[i]); v = field_val(parts[i])
        if (k == "from") from = v; else if (k == "result") result = v; else if (k == "project") proj = v
      }
      nk = 0
      if (from == "projects") {
        pname = text; sub(/^Project:[ \t]*/, "", pname); outcome = pname
        sub(/[ \t]+—.*$/, "", pname); sub(/^[^—]*—[ \t]*/, "", outcome)
        title = unique("_done", safe(pname))
        dir = S "/memory/gtd/_done/" title
        system("mkdir -p " shq(dir))
        path = dir "/README.md"
        keys[++nk] = "outcome"; vals[nk] = yq(outcome)
      } else {
        title = unique("_done", pick_title(ITEM_ID != "" ? ITEM_ID : short(text), text))
        path = S "/memory/gtd/_done/" title ".md"
        keys[++nk] = "id"; vals[nk] = ITEM_ID
        keys[++nk] = "project"; vals[nk] = (proj == "" ? "" : project_link(project_name(proj)))
      }
      keys[++nk] = "completed"; vals[nk] = date
      keys[++nk] = "result"; vals[nk] = (result == "" ? "done" : result)
      keys[++nk] = "list"; vals[nk] = from
      write_fm(path, keys, vals, nk)
      print text "\n" > path
      print (from == "projects" ? "## After action review" : "## Outcome") > path
      if (cont != "") print cont > path
      close(path)
      manifest("done", "memory/gtd/_done/" title (from == "projects" ? "/README.md" : ".md"), "completed=" date " list=" from)
      have = 0; cont = ""
    }
    /^## [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ { flush(); date = substr($0, 4, 10); next }
    /^- \[x\] / { flush(); have = 1; item = $0; cont = ""; next }
    have && /^[ \t]+[^ \t]/ { sub(/^  /, ""); cont = (cont == "" ? $0 : cont "\n" $0); next }
    { flush(); print > readme }
    END { flush() }
  ' "$f"
}

# --- README tails (appended after each list's own header lines) -----------------------------

note_format() {
  # note_format TEMPLATE INTRO
  printf '\n## Note format\n\n%s\n\n```markdown\n' "$2"
  cat "$TEMPLATES/$1"
  printf '```\n'
}

NOTE_RULES='One note per item: `<list>/<Short verb-first title>.md`, filesystem-safe (no `: / \ ? * " < > |`), with `(2)`, `(3)`, … added on a collision. `README.md` is reserved and is never an item. The properties below are filled by clarify and repaired by organize — you never have to tag anything, and a note with no properties is still valid.'

finish_readmes() {
  local g="$S/memory/gtd" r
  for r in "$g"/*/README.md "$S/reference/README.md"; do
    [ -f "$r" ] || continue
    # Squeeze runs of blank lines left where items were, and mark the old single-file Format line.
    awk 'NF { blank = 0; print; next } !blank { blank = 1; print }' "$r" \
      | sed '/^> Format:/ s/$/ (single-file format; see Note format below)/' > "$r.tmp"
    mv "$r.tmp" "$r"
  done
  if [ -f "$g/next-actions/README.md" ]; then
    {
      printf '\n## Legacy groups\n\nThe single-file list grouped actions under the @ headings above. In per-item notes a group is a `context` value instead: @computer → `computer`, @calls → `phone`, @errands → `errands`, @home → `home`, @agenda-[name] → `person-present` (the person goes in the body).\n'
      note_format next-action-note.md "${NOTE_RULES//<list>/next-actions}"
    } >> "$g/next-actions/README.md"
  fi
  [ -f "$g/waiting-for/README.md" ] && note_format waiting-for-note.md "${NOTE_RULES//<list>/waiting-for}" >> "$g/waiting-for/README.md"
  [ -f "$g/someday-maybe/README.md" ] && note_format someday-maybe-note.md "${NOTE_RULES//<list>/someday-maybe}" >> "$g/someday-maybe/README.md"
  [ -f "$g/product-ideas/README.md" ] && note_format product-idea-note.md "${NOTE_RULES//<list>/product-ideas}" >> "$g/product-ideas/README.md"
  [ -f "$g/projects/README.md" ] && note_format project-note.md 'Each project is a folder, `projects/<Project name>/README.md`: outcome, notes and an embedded next-actions view, with its support material as ordinary files beside it. Actions point at it with `project: "[[projects/<Project name>/README|<Project name>]]"`.' >> "$g/projects/README.md"
  if [ -f "$S/reference/README.md" ]; then
    if [ -f "$ROOT/reference/README.md" ]; then
      rm "$S/reference/README.md"   # keep the workspace's own reference/README.md; the old header stays in _migrated/
    else
      note_format reference-note.md 'One plain note per topic at the workspace root, found by title or full-text search. Project-specific material lives in that project'"'"'s own folder.' >> "$S/reference/README.md"
    fi
  fi
  if [ -f "$g/_done/README.from-done-md.md" ]; then
    rm "$g/_done/README.from-done-md.md"   # init writes _done/README.md; done.md's header is kept in _migrated/
  fi
}

# --- link rewriting ------------------------------------------------------------------------

# rewrite_links MODE FILE... — MODE "count" prints "<file>\t<rewritten>\t<unresolved>" per file with any
# GTD-list link; MODE "apply" rewrites the files in place. Links inside `code` and ``` fences are left alone.
rewrite_links() {
  local mode="$1"; shift
  local f
  for f in "$@"; do
    awk -v MAP="$MAP" -v MODE="$mode" -v FILE="$f" '
      BEGIN {
        while ((getline line < MAP) > 0) { split(line, a, "\t"); new[a[1]] = a[2]; alias[a[1]] = a[3] }
        close(MAP)
        split("next-actions waiting-for projects someday-maybe product-ideas reference done", L, " ")
        for (i in L) { new[L[i]] = L[i] "/README"; alias[L[i]] = L[i] }
        new["done"] = "_done/README"
      }
      function shq(s,   n, parts, i, out) {
        n = split(s, parts, "\047"); out = parts[1]
        for (i = 2; i <= n; i++) out = out "\047\\\047\047" parts[i]
        return "\047" out "\047"
      }
      function fix(link,   inner, target, al, bar, pre, t, isgtd) {
        inner = substr(link, 3, length(link) - 4)
        bar = index(inner, "|")
        if (bar) { target = substr(inner, 1, bar - 1); al = substr(inner, bar) } else { target = inner; al = "" }
        t = target; pre = ""
        if (t ~ /^memory\/gtd\//) { pre = "memory/gtd/"; sub(/^memory\/gtd\//, "", t) }
        isgtd = (t ~ /^(next-actions|waiting-for|projects|someday-maybe|product-ideas|reference|done)(#|$)/)
        if (!isgtd) return link
        if (t in new) {
          rewritten++
          if (al == "") al = "|" alias[t]
          return "[[" (new[t] ~ /^reference\// ? "" : pre) new[t] al "]]"
        }
        unresolved++
        return link
      }
      function fix_segment(s,   out, m) {
        out = ""
        while (match(s, /\[\[[^]]*\]\]/)) { out = out substr(s, 1, RSTART - 1) fix(substr(s, RSTART, RLENGTH)); s = substr(s, RSTART + RLENGTH) }
        return out s
      }
      /^[ \t>]*```/ { fence = !fence; out[++n] = $0; next }
      fence { out[++n] = $0; next }
      {
        # only rewrite outside inline `code` spans: even-numbered pieces between backticks are code
        m = split($0, seg, "`"); line = ""
        for (i = 1; i <= m; i++) line = line (i > 1 ? "`" : "") (i % 2 == 1 ? fix_segment(seg[i]) : seg[i])
        out[++n] = line
      }
      END {
        if (MODE == "count") { if (rewritten + unresolved > 0) printf "%s\t%d\t%d\n", FILE, rewritten, unresolved; exit }
        if (rewritten == 0) exit
        for (i = 1; i <= n; i++) print out[i] > (FILE ".gtdtmp")
        close(FILE ".gtdtmp")
        system("mv " shq(FILE ".gtdtmp") " " shq(FILE))
      }
    ' "$f"
  done
}

# Markdown files in the workspace that might link to a GTD list (never .git, .obsidian, or _migrated).
linking_files() {
  grep -rlE --include='*.md' '\[\[(memory/gtd/)?(next-actions|waiting-for|projects|someday-maybe|product-ideas|reference|done)(#|\||\]\])' "$1" 2>/dev/null \
    | grep -vE '/(\.git|\.obsidian|node_modules)/|/memory/gtd/_migrated/' || true
}

# --- build the staged tree -------------------------------------------------------------------

NEXT_ACTIONS_VIEW='(Computed from the action notes whose `project:` links here: `gtd_list.sh next-actions --project "<this project>"`.)'
if [ "$WITH_BASES" -eq 1 ] || [ -f "$GTD_DIR/next-actions.base" ]; then
  NEXT_ACTIONS_VIEW='![[next-actions.base#For this project]]'
fi

migrate_projects "$NEXT_ACTIONS_VIEW"      # first: its reference and areas/ usage decide where reference entries go
migrate_line_list next-actions
migrate_line_list waiting-for
migrate_line_list someday-maybe
migrate_product_ideas
migrate_reference
migrate_done
finish_readmes

# Counts: the single-file lists (via gtd_list.sh, before) against the notes staged (after).
count_before() { GTD_LAYOUT=files bash "$SCRIPT_DIR/gtd_list.sh" "$1" 2>/dev/null | grep -c . || true; }
count_after() { awk -F'\t' -v l="$1" '$1 == l' "$MANIFEST" | grep -c . || true; }
COUNT_MISMATCH=0
count_report() {
  local l b a
  for l in next-actions waiting-for projects someday-maybe product-ideas; do
    b="$(count_before "$l")"; a="$(count_after "$l")"
    printf '  %-14s %3s in %s.md -> %3s notes' "$l" "$b" "$l" "$a"
    if [ "$b" != "$a" ]; then printf '  ⚠️  MISMATCH'; COUNT_MISMATCH=1; fi
    printf '\n'
  done
  printf '  %-14s %3s entries -> %s in reference/, %s in project folders\n' reference \
    "$(awk -F'\t' '$1 ~ /^reference/' "$MANIFEST" | grep -c . || true)" \
    "$(count_after reference)" "$(awk -F'\t' '$1 == "reference -> project"' "$MANIFEST" | grep -c . || true)"
  [ -f "$GTD_DIR/done.md" ] && printf '  %-14s %3s done.md records -> _done/\n' done "$(count_after done)"
  return 0
}

# Links: counted against the workspace as it is now, plus the staged notes (their bodies carry old links too).
LINKS="$STAGE/links.tsv"
{
  linking_files "$ROOT" | while IFS= read -r f; do rewrite_links count "$f"; done
  find "$S" -name '*.md' | while IFS= read -r f; do rewrite_links count "$f"; done
} | sed "s#^$S/#(new) #; s#^$ROOT/##" > "$LINKS"

areas_report() {
  [ -s "$AREAS" ] || { echo "  none"; return 0; }
  sort -u "$AREAS" | while IFS="$(printf '\t')" read -r a p; do
    if [ -d "$ROOT/$a" ]; then echo "  $a/  -> memory/gtd/projects/$p/   (git mv by hand, then fix its [[$a/…]] links)"; fi
  done
}

echo "GTD migration to per-item notes — $([ "$APPLY" -eq 1 ] && echo APPLY || echo 'DRY RUN (nothing written; rerun with --apply)')"
echo "Workspace: $ROOT   (git: $git_state)"
echo ""
echo "── Counts ──"
count_report
echo ""
echo "── Notes to create ──"
awk -F'\t' '{ printf "  [%s] %s  %s\n", $1, $2, $3 }' "$MANIFEST"
echo ""
echo "── List READMEs (each list's header + group notes, then its Note format) ──"
( cd "$S" && find . -name README.md | grep -v '/projects/.*/README.md' | sed 's#^\./#  #' | sort )
echo ""
echo "── Links to rewrite (file, rewritten, unresolved) ──"
if [ -s "$LINKS" ]; then awk -F'\t' '{ printf "  %s: %d%s\n", $1, $2, ($3 > 0 ? "  (" $3 " unresolved — left as is)" : "") }' "$LINKS"; else echo "  none"; fi
echo ""
echo "── areas/ folders linked from a project (fold in by hand after the migration) ──"
areas_report
echo ""
echo "── Old lists (moved, never deleted) ──"
for l in next-actions waiting-for projects someday-maybe product-ideas reference done; do
  [ -f "$GTD_DIR/$l.md" ] && echo "  memory/gtd/$l.md -> memory/gtd/_migrated/$l.md"
done

if [ "$COUNT_MISMATCH" -eq 1 ]; then
  echo ""
  echo "⚠️  A list's item count changed. Check the lines above before applying." >&2
  [ "$APPLY" -eq 1 ] && die "refusing to apply with a count mismatch" 6
fi

if [ "$APPLY" -eq 0 ]; then
  echo ""
  echo "Titles: pass --titles FILE (id<TAB>Title per line) to replace any proposed title above."
  exit 0
fi

# --- apply ------------------------------------------------------------------------------------

# Never overwrite: every staged path must be free in the workspace.
clash=""
while IFS= read -r p; do
  rel="${p#"$S"/}"
  [ ! -e "$ROOT/$rel" ] || clash="$clash $rel"
done < <(find "$S" -type f)
[ -z "$clash" ] || die "these files already exist, nothing was changed:$clash" 4

( cd "$S" && find . -type d ) | while IFS= read -r d; do mkdir -p "$ROOT/${d#./}"; done
( cd "$S" && find . -type f ) | while IFS= read -r p; do cp "$S/${p#./}" "$ROOT/${p#./}"; done

mkdir -p "$GTD_DIR/_migrated"
for l in next-actions waiting-for projects someday-maybe product-ideas reference done; do
  [ -f "$GTD_DIR/$l.md" ] && mv "$GTD_DIR/$l.md" "$GTD_DIR/_migrated/$l.md"
done

linking_files "$ROOT" | while IFS= read -r f; do rewrite_links apply "$f"; done

echo ""
echo "── gtd_init.sh fills in what the migration doesn't write (existing files are never touched) ──"
init_args="--confirm-create --layout notes"
[ "$WITH_BASES" -eq 1 ] && init_args="$init_args --with-bases"
# shellcheck disable=SC2086
bash "$SCRIPT_DIR/gtd_init.sh" $init_args | grep -E '✅ Created|REFUS|⚠️' || true

echo ""
echo "── After ──"
GTD_LAYOUT=notes bash "$SCRIPT_DIR/gtd_status.sh" | sed -n '4,11p'
echo ""
GTD_LAYOUT=notes bash "$SCRIPT_DIR/gtd_check.sh" | awk -F'\t' '/^#/ { print "  " $0; next } { c[$1]++ } END { for (k in c) print "  " k ": " c[k] " (organize fixes or asks)" }'
echo ""
echo "Done. Review with git diff; to undo: git checkout -- . && git clean -fd memory/gtd reference (or restore from memory/gtd/_migrated/)."
