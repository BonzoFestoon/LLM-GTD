#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOT="${GTD_SKILL_ROOT:-$DEFAULT_ROOT}"

fail() {
  echo "❌ $*"
  exit 1
}

ok() {
  echo "✅ $*"
}

[ -d "$ROOT" ] || fail "skill root not found: $ROOT"

skill_lines="$(wc -l < "$ROOT/SKILL.md" | tr -d ' ')"
[ "$skill_lines" -le 120 ] || fail "SKILL.md too long: ${skill_lines} lines"
ok "SKILL.md <= 120 lines (${skill_lines})"

if grep -q '^## Version summary' "$ROOT/SKILL.md"; then
  fail "SKILL.md still contains version summary"
fi
ok "SKILL.md has no version summary"

core_heading_count="$(grep -c '^## Core lists' "$ROOT/organize/SKILL.md" || true)"
[ "$core_heading_count" -le 1 ] || fail "organize has duplicate core-list headings: $core_heading_count"
ok "organize has no duplicate core-list definition"

grep -q '^## Action permissions' "$ROOT/references/list-definitions.md" || fail "list-definitions lacks action permission table"
ok "list-definitions carries action permission table"

eval_count="$(grep -c '^| E[0-9][0-9]-' "$ROOT/references/evals.md" || true)"
[ "$eval_count" -ge 12 ] || fail "not enough eval cases: $eval_count"
ok "eval cases >= 12 (${eval_count})"

# Every sub-skill folder must: appear in gtd_help.sh's output, carry a valid
# model-tier, and have a command file on all three platforms. Guards future
# skills automatically — nothing here names a specific sub-skill.
# The three-platform check only makes sense from the repo checkout (src/skill as
# $ROOT); the synced plugins/llm-gtd/skills/gtd-harness copy has no sibling
# src/claude-commands etc. of its own, so that part is skipped there, not failed.
REPO_ROOT="$(cd "$ROOT/../.." && pwd)"
if [ -d "$REPO_ROOT/src/claude-commands" ]; then
  check_platforms=1
else
  check_platforms=0
  echo "ℹ️  Not running from the repo's src/skill/ (no sibling src/claude-commands/ found); skipping the three-platform command-file check"
fi
help_output="$(bash "$ROOT/scripts/gtd_help.sh" 2>/dev/null || true)"
for skill_md in "$ROOT"/*/SKILL.md; do
  dir="$(basename "$(dirname "$skill_md")")"
  short="gtd-$dir"

  echo "$help_output" | grep -qF "/$short" || fail "gtd_help.sh output is missing $short"

  tier="$(awk '
    /^---[[:space:]]*$/ { infm++; if (infm==2) exit; next }
    infm==1 && /^model-tier:/ { sub(/^model-tier:[[:space:]]*/, ""); print; exit }
  ' "$skill_md")"
  case "$tier" in
    fast|balanced|strongest) : ;;
    *) fail "$dir/SKILL.md has no valid model-tier (got: '${tier:-<empty>}')" ;;
  esac

  if [ "$check_platforms" -eq 1 ]; then
    [ -f "$REPO_ROOT/src/claude-commands/$short.md" ] || fail "missing Claude command: src/claude-commands/$short.md"
    [ -f "$REPO_ROOT/plugins/llm-gtd/commands/$short.md" ] || fail "missing plugin command: plugins/llm-gtd/commands/$short.md"
    [ -f "$REPO_ROOT/src/codex-prompts/$short.md" ] || fail "missing Codex prompt: src/codex-prompts/$short.md"
  fi
done
if [ "$check_platforms" -eq 1 ]; then
  ok "every sub-skill is in gtd_help.sh, has a model-tier, and has a command on all three platforms"
else
  ok "every sub-skill is in gtd_help.sh and has a model-tier"
fi

# The router's own tier lives in SKILL.md itself, not a subfolder — check it separately.
router_tier="$(awk '
  /^---[[:space:]]*$/ { infm++; if (infm==2) exit; next }
  infm==1 && /^model-tier:/ { sub(/^model-tier:[[:space:]]*/, ""); print; exit }
' "$ROOT/SKILL.md")"
case "$router_tier" in
  fast|balanced|strongest) ok "router SKILL.md has a valid model-tier ($router_tier)" ;;
  *) fail "SKILL.md (router) has no valid model-tier (got: '${router_tier:-<empty>}')" ;;
esac

# Model names are single-sourced in model-guidance.md; a name anywhere else in the
# skill means the tier system has started drifting.
model_name_hits="$(grep -RlE 'Opus 5\.5|Sonnet 5|Haiku 4\.5' "$ROOT" --include='*.md' --include='*.sh' 2>/dev/null | grep -v 'references/model-guidance.md' | grep -v 'gtd_eval_check.sh' || true)"
[ -z "$model_name_hits" ] || fail "Claude model name(s) leaked outside model-guidance.md: $model_name_hits"
ok "no Claude model name outside references/model-guidance.md"

if find "$ROOT" -name '*.bak-*' -print -quit | grep -q .; then
  fail "backup files remain under skill root"
fi
ok "no .bak-* files under skill root"

if grep -R -E --exclude='gtd_eval_check.sh' "description:[[:space:]]+GTD[[:space:]]+harness" "$ROOT" >/dev/null; then
  fail "public descriptions still use legacy harness wording"
fi
ok "public descriptions use GTD skill wording"

bash -n "$ROOT/scripts/gtd_init.sh"
bash -n "$ROOT/scripts/gtd_status.sh"
bash -n "$ROOT/scripts/gtd_review_prep.sh"
bash -n "$ROOT/scripts/gtd_review_prep_notify.sh"
bash -n "$ROOT/scripts/gtd_help.sh"
bash -n "$ROOT/scripts/gtd_list.sh"
bash -n "$ROOT/scripts/gtd_check.sh"
bash -n "$ROOT/scripts/gtd_next_date.sh"
bash -n "$ROOT/scripts/gtd_tagged.sh"
ok "shell scripts pass bash -n"

# product-ideas was retired in 2.0.0: product opportunities are clarified like any other input.
# Only the history (evolution-log.md) may still name it.
if grep -rni 'product-idea' "$ROOT" --include='*.md' --include='*.sh' --include='*.toml' --include='*.json' \
  | grep -v '/references/evolution-log.md:' | grep -v '/scripts/gtd_eval_check.sh:'; then
  fail "product-ideas is still mentioned (retired in 2.0.0)"
fi
ok "no product-ideas list anywhere"

# gtd_check.sh's property vocabulary must match list-definitions.md's "Property values" table.
for var in ENERGY_VOCAB CONTEXT_VOCAB; do
  prop="$(echo "$var" | sed 's/_VOCAB//' | tr '[:upper:]' '[:lower:]')"
  row="$(grep -E "^\| \`$prop\` \|" "$ROOT/references/list-definitions.md" | sed 's/\\|/,/g' | awk -F'|' '{ print $3 }')"
  [ -n "$row" ] || fail "list-definitions.md has no Property values row for $prop"
  for v in $(grep -E "^$var=" "$ROOT/scripts/gtd_check.sh" | sed -E 's/^[A-Z_]+="(.*)"$/\1/'); do
    echo "$row" | grep -qF "\`$v\`" || fail "gtd_check.sh $prop value '$v' is not in list-definitions.md's Property values"
  done
done
ok "gtd_check.sh vocabulary matches list-definitions.md Property values"

# Init fixture: builds the lists in a throwaway root, checks every list folder has its README,
# README is never listed as an item, and every script refuses LLM-GTD 1.x single-file lists.
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/notes" "$fixture/files/memory/gtd"
LLM_GTD_ROOT="$fixture/notes" CODEX_HOME="$fixture/codex" \
  bash "$ROOT/scripts/gtd_init.sh" --confirm-create --with-bases >/dev/null \
  || fail "gtd_init.sh failed"
for f in memory/gtd/inbox.md memory/gtd/calendar.md memory/gtd/horizons.md reference/README.md \
  memory/gtd/next-actions/README.md memory/gtd/waiting-for/README.md memory/gtd/projects/README.md \
  memory/gtd/someday-maybe/README.md memory/gtd/_done/README.md \
  memory/gtd/next-actions.base memory/gtd/done.base memory/gtd/tickler/README.md memory/gtd/tickler.base; do
  [ -f "$fixture/notes/$f" ] || fail "init did not create $f"
done
grep -q '^## Note format' "$fixture/notes/memory/gtd/tickler/README.md" || fail "tickler README lacks its Note format section"
grep -qi 'tickle' "$fixture/notes/memory/gtd/projects/README.md" || fail "projects README's stalled rule does not name the tickle"
for f in next-actions waiting-for projects someday-maybe reference; do
  [ ! -e "$fixture/notes/memory/gtd/$f.md" ] || fail "init wrote a single-file $f.md"
done
[ ! -e "$fixture/notes/memory/gtd/product-ideas" ] || fail "init created a product-ideas/ list (retired in 2.0.0)"
grep -q '^## Note format' "$fixture/notes/memory/gtd/next-actions/README.md" || fail "next-actions README lacks its Note format section"
[ -z "$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" next-actions)" ] || fail "gtd_list.sh counted README.md as an item"
[ -z "$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" projects)" ] || fail "gtd_list.sh counted projects/README.md as a project"
# A 1.x single-file system: every script refuses (exit 4) and init writes nothing.
touch "$fixture/files/memory/gtd/next-actions.md"
for sc in gtd_init.sh gtd_status.sh gtd_list.sh gtd_check.sh gtd_review_prep.sh gtd_tagged.sh; do
  case "$sc" in gtd_init.sh) arg="--confirm-create" ;; gtd_list.sh) arg="next-actions" ;; *) arg="" ;; esac
  rc=0; LLM_GTD_ROOT="$fixture/files" CODEX_HOME="$fixture/codex" bash "$ROOT/scripts/$sc" $arg >/dev/null 2>"$fixture/err" || rc=$?
  [ "$rc" -eq 4 ] || fail "$sc did not refuse single-file lists (exit $rc, want 4)"
  grep -q 'gtd_migrate_to_notes.sh' "$fixture/err" || fail "$sc refused single-file lists without naming the 1.17.x migration"
done
[ ! -d "$fixture/files/memory/gtd/next-actions" ] || fail "refused init still created next-actions/"
ok "init: folders + READMEs + bases created (tickler included), README never an item; single-file lists refused by every script"

# Read path: lenses filter, _done/ is never listed, and gtd_check.sh finds each kind of
# mechanical problem (and nothing on a clean note).
G="$fixture/notes/memory/gtd"
mkdir -p "$G/projects/Alpha" "$G/projects/Idle"
printf -- '---\noutcome: Alpha shipped\n---\n' > "$G/projects/Alpha/README.md"
printf -- '---\noutcome: Nothing linked\n---\n' > "$G/projects/Idle/README.md"
printf -- '---\ntime: 10   # minutes\nenergy: low\ncontext: [computer, phone]\nproject: "[[projects/Alpha/README|Alpha]]"\n---\nx\n' > "$G/next-actions/Quick call.md"
printf -- '---\ntime: 60-90 min\nenergy: deep work\ncontext: [lab]\nproject: "[[projects/Gone/README|Gone]]"\n---\nx\n' > "$G/next-actions/quick call (2).md"
printf -- '---\ntime: 5\nenergy: low\ncontext: [home]\ncompleted: 2026-01-01\nlist: next-actions\n---\nx\n' > "$G/_done/Finished thing.md"
mkdir -p "$G/_done/Old project"
printf -- '---\nlist: projects\n---\nx\n\n## After action review\n<!-- draft -->\n' > "$G/_done/Old project/README.md"
printf -- 'plan doc, not a done record\n' > "$G/_done/Old project/PLAN.md"
printf -- '---\ncompleted: 2026-02-01\nresult: done\nlist: next-actions\nproject: "[[projects/Old project/README|Old project]]"\n---\nx\n\n## Outcome\n- Done: shipped\n- Problems and fixes: the portal wanted no dashes; entering it without them worked.\n' > "$G/_done/Old step.md"
printf -- '---\ncompleted: 2025-12-01\nresult: cancelled\nlist: waiting-for\n---\nx\n\n## Outcome\n- Problems and fixes: none noted\n' > "$G/_done/Old wait.md"
na="$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" next-actions --max-time 10 --energy low)"
[ "$(echo "$na" | grep -c .)" -eq 1 ] && echo "$na" | grep -q 'Quick call$' || fail "gtd_list.sh lenses returned: $na"
echo "$na" | grep -q 'due=-' || fail "gtd_list.sh next-actions lacks the due= column"
! LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" next-actions | grep -q 'Finished thing' || fail "gtd_list.sh listed a _done/ note"
chk="$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_check.sh")"
T=$'\t'
dup="next-actions/quick call (2).md"
for want in "orphan${T}$dup" "stalled${T}projects/Idle/README.md" "field${T}$dup${T}time" \
  "field${T}$dup${T}energy" "field${T}$dup${T}context 'lab'" "duplicate${T}next-actions/" \
  "done-completed${T}_done/Old project/README.md" "done-no-aar${T}_done/Old project/README.md" \
  "done-link${T}_done/Old step.md"; do
  echo "$chk" | grep -qF "$want" || fail "gtd_check.sh missed: $want"
done
! echo "$chk" | grep -qF "${T}next-actions/Quick call.md${T}" || fail "gtd_check.sh flagged a clean note"
! echo "$chk" | grep -qF "stalled${T}projects/Alpha/" || fail "gtd_check.sh called a linked project stalled"
[ -z "$(echo "$chk" | awk -F'\t' '$2 ~ /README\.md$/ && $2 !~ /^(projects|_done)\/[^\/]+\/README\.md$/')" ] \
  || fail "gtd_check.sh treated a list README as an item"
! echo "$chk" | grep -qF "PLAN.md" || fail "gtd_check.sh treated a finished project's support doc as a done record"
ok "read path: lenses filter, _done/ never listed, gtd_check.sh finds every kind of problem"

# Done record: gtd_list.sh done lists every record once, never a support doc or the
# folder README, and --since / --project / --problems filter it.
done_all="$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" done)"
[ "$(echo "$done_all" | grep -c .)" -eq 4 ] || fail "gtd_list.sh done listed: $done_all"
echo "$done_all" | grep -q "list=projects${T}project=Old project${T}.*Old project$" || fail "gtd_list.sh done missed the finished project folder"
[ "$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" done --since 2026-01-15 | grep -c .)" -eq 1 ] || fail "gtd_list.sh done --since did not filter"
[ "$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" done --problems | cut -f1-7 | grep -c .)" -eq 1 ] || fail "gtd_list.sh done --problems did not filter"
[ "$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" done --project "Old project" | grep -c .)" -eq 2 ] || fail "gtd_list.sh done --project did not find the project and its step"
ok "done record: gtd_list.sh done filters by --since / --project / --problems"

# Tickler: a tickle puts its project in play (never stalled), a due tickle is
# tickler-due, --due / --within split by date, tickles get the actions' project-link checks, the inbox
# guard, the dashboard line and review prep's Tickler section; no tickler lists nothing.
# Dates are relative to the run date so the gate never goes stale.
TK="$fixture/tick"
mkdir -p "$TK"
LLM_GTD_ROOT="$TK" CODEX_HOME="$fixture/codex" bash "$ROOT/scripts/gtd_init.sh" --confirm-create >/dev/null \
  || fail "gtd_init.sh failed (tickler fixture)"
TG="$TK/memory/gtd"
mkdir -p "$TG/tickler"
tk_today="$(date +%Y-%m-%d)"
tk_soon="$(date -d '+3 days' +%Y-%m-%d 2>/dev/null || date -v+3d +%Y-%m-%d)"
for p in "On hold" "Due now" "Soon" "Nothing"; do
  mkdir -p "$TG/projects/$p"
  printf -- '---\noutcome: %s done\n---\n' "$p" > "$TG/projects/$p/README.md"
done
mkdir -p "$TG/_done/Closed"
printf -- '---\ncompleted: 2026-01-01\nresult: done\nlist: projects\n---\nx\n\n## After action review\n- fine\n' > "$TG/_done/Closed/README.md"
tickle() {
  # tickle TITLE TICKLE PROJECT — a tickler note; an empty TICKLE or PROJECT leaves that property out
  { printf -- '---\nid: tk-fixture-20260930\n'
    [ -z "$2" ] || printf 'tickle: %s\n' "$2"
    [ -z "$3" ] || printf 'project: "%s"\n' "$3"
    printf 'created: 2026-09-30\n---\n%s, the body.\n' "$1"; } > "$TG/tickler/$1.md"
}
tickle "Open the accounts" 2999-01-01 "[[projects/On hold/README|On hold]]"
tickle "Start the due work" 2000-01-01 "[[projects/Due now/README|Due now]]"
tickle "Prepare the soon work" "$tk_soon" "[[projects/Soon/README|Soon]]"
tickle "Reconsider the gym" "$tk_today" ""
tickle "reconsider the GYM (2)" 2999-01-01 ""
tickle "Points at nothing" 2999-01-01 "[[projects/Gone/README|Gone]]"
tickle "Points at closed" 2999-01-01 "[[projects/Closed/README|Closed]]"
tickle "Bare link form" 2999-01-01 "[[projects/On hold]]"
tickle "Bad date" "next week" ""
tickle "No date" "" ""

tl="$(LLM_GTD_ROOT="$TK" bash "$ROOT/scripts/gtd_list.sh" tickler 2>&1)" || fail "gtd_list.sh tickler failed: $tl"
[ "$(echo "$tl" | grep -c .)" -eq 10 ] || fail "gtd_list.sh tickler listed: $tl"
echo "$tl" | grep -q "^tk-fixture-20260930${T}tickle=2999-01-01${T}project=.*On hold.*${T}Open the accounts$" \
  || fail "gtd_list.sh tickler columns wrong: $tl"
[ -z "$(echo "$tl" | awk -F'\t' '$NF == "README"')" ] || fail "gtd_list.sh tickler listed README.md"
tl_due="$(LLM_GTD_ROOT="$TK" bash "$ROOT/scripts/gtd_list.sh" tickler --due)"
[ "$(echo "$tl_due" | grep -c .)" -eq 2 ] && echo "$tl_due" | grep -q 'Start the due work$' && echo "$tl_due" | grep -q 'Reconsider the gym$' \
  || fail "gtd_list.sh tickler --due returned: $tl_due"
tl_soon="$(LLM_GTD_ROOT="$TK" bash "$ROOT/scripts/gtd_list.sh" tickler --within 14)"
[ "$(echo "$tl_soon" | grep -c .)" -eq 1 ] && echo "$tl_soon" | grep -q 'Prepare the soon work$' \
  || fail "gtd_list.sh tickler --within 14 returned (want only the today+3 tickle, nothing due): $tl_soon"
[ -z "$(LLM_GTD_ROOT="$TK" bash "$ROOT/scripts/gtd_list.sh" tickler --within 2)" ] || fail "gtd_list.sh tickler --within 2 included a today+3 tickle"
[ "$(LLM_GTD_ROOT="$TK" bash "$ROOT/scripts/gtd_list.sh" tickler --project "On hold" | grep -c .)" -eq 2 ] || fail "gtd_list.sh tickler --project did not filter"

chk="$(LLM_GTD_ROOT="$TK" bash "$ROOT/scripts/gtd_check.sh")"
for want in "stalled${T}projects/Nothing/README.md" "tickler-due${T}tickler/Start the due work.md" \
  "tickler-due${T}tickler/Reconsider the gym.md" "orphan${T}tickler/Points at nothing.md" \
  "orphan-closed${T}tickler/Points at closed.md" "link-form${T}tickler/Bare link form.md" \
  "tickler-date${T}tickler/Bad date.md" "tickler-date${T}tickler/No date.md" "duplicate${T}tickler/"; do
  echo "$chk" | grep -qF "$want" || fail "gtd_check.sh missed: $want"
done
for p in "On hold" "Due now" "Soon"; do
  ! echo "$chk" | grep -qF "stalled${T}projects/$p/" || fail "gtd_check.sh called a tickled project stalled: $p"
done
! echo "$chk" | grep -qE "^tickler-due${T}tickler/(Open the accounts|Prepare the soon work)" || fail "gtd_check.sh called a future tickle due"
! echo "$chk" | grep -qF "tickler/README.md" || fail "gtd_check.sh treated tickler/README.md as a tickle"
! echo "$chk" | grep -F "tickler-due${T}tickler/Reconsider the gym.md" | grep -q 'queued in inbox' || fail "gtd_check.sh says queued in inbox with no inbox line"
printf -- '- Tickle due: Reconsider the gym → [[tickler/Reconsider the gym]] · Captured: 20260930\n' >> "$TG/inbox.md"
chk="$(LLM_GTD_ROOT="$TK" bash "$ROOT/scripts/gtd_check.sh")"
echo "$chk" | grep -F "tickler-due${T}tickler/Reconsider the gym.md" | grep -q 'queued in inbox' || fail "gtd_check.sh missed the inbox pointer (queued in inbox)"
! echo "$chk" | grep -F "tickler-due${T}tickler/Start the due work.md" | grep -q 'queued in inbox' || fail "gtd_check.sh called an unqueued tickle queued"

st="$(LLM_GTD_ROOT="$TK" bash "$ROOT/scripts/gtd_status.sh" 2>&1 || true)"
echo "$st" | grep -qE "Tickler +: 10 \(2 due\)" || fail "gtd_status.sh lacks 'Tickler: 10 (2 due)': $st"
echo "$st" | grep -q "Projects *: 4 (stalled[^0-9]* 1)" || fail "gtd_status.sh stalled count ignores tickles: $st"
echo "$st" | grep -qE "Calendar \(hard\) +: 0" || fail "gtd_status.sh calendar count changed: $st"

rp="$(LLM_GTD_ROOT="$TK" bash "$ROOT/scripts/gtd_review_prep.sh" 2>&1 || true)"
# part_of TEXT START END — the lines after the first line matching START, up to the next line matching END
part_of() { printf '%s\n' "$1" | awk -v s="$2" -v e="$3" 'f && $0 ~ e { exit } f { print } $0 ~ s { f = 1 }'; }
rp_tk="$(part_of "$rp" '^## Tickler' '^## ')"
[ -n "$rp_tk" ] || fail "gtd_review_prep.sh has no Tickler section: $rp"
rp_due="$(part_of "$rp_tk" '^Due now' '^(Next 14 days|Projects on hold)')"
rp_next="$(part_of "$rp_tk" '^Next 14 days' '^Projects on hold')"
rp_hold="$(part_of "$rp_tk" '^Projects on hold' '^$')"
echo "$rp_due" | grep -q 'Start the due work' && echo "$rp_due" | grep -q 'Reconsider the gym' || fail "review prep 'Due now' wrong: $rp_tk"
echo "$rp_next" | grep -q 'Prepare the soon work' && ! echo "$rp_next" | grep -q '2999-01-01' || fail "review prep 'Next 14 days' wrong: $rp_tk"
echo "$rp_hold" | grep -q 'On hold.*2999-01-01' || fail "review prep 'Projects on hold' lacks On hold with its date: $rp_tk"
! part_of "$rp" '^## Hygiene findings' '^## ' | grep -q 'tickler-due' || fail "review prep repeats tickler-due under Hygiene findings"
rp_stalled="$(part_of "$rp" '^## Stalled Projects' '^## ')"
echo "$rp_stalled" | grep -q 'Nothing' && ! echo "$rp_stalled" | grep -qE 'On hold|Due now|Soon' || fail "review prep Stalled Projects wrong: $rp_stalled"
part_of "$rp" '^## Confirmation queue' '^## ' | grep -q 'Tickler:' || fail "review prep confirmation queue lacks the tickler line"

NT="$fixture/notick"
mkdir -p "$NT"
LLM_GTD_ROOT="$NT" CODEX_HOME="$fixture/codex" bash "$ROOT/scripts/gtd_init.sh" --confirm-create >/dev/null || fail "gtd_init.sh failed (no-tickler fixture)"
rm -rf "$NT/memory/gtd/tickler"
out="$(LLM_GTD_ROOT="$NT" bash "$ROOT/scripts/gtd_list.sh" tickler 2>&1)" && [ -z "$out" ] || fail "gtd_list.sh tickler with no tickler/ folder: $out"
LLM_GTD_ROOT="$NT" bash "$ROOT/scripts/gtd_status.sh" >/dev/null 2>&1 || fail "gtd_status.sh failed with no tickler/ folder"
ok "tickler: tickled projects in play, due / within split, link checks, inbox guard, dashboard and review prep"

# Recurring tickles (E38-E43): gtd_next_date.sh's arithmetic (fixed by default, floating opt-in,
# month-end clamp, lead), and how a tickle with every: is listed and checked — due on tickle - lead
# only while no open action links it (from:), overdue the day after its date, never a project hold,
# from: links checked like project: links, two open actions for one routine a duplicate.
ND="$ROOT/scripts/gtd_next_date.sh"
nd_case() {
  # nd_case WANT ARGS... — gtd_next_date.sh ARGS must print WANT
  local want="$1" got; shift
  got="$(bash "$ND" "$@" 2>&1)" || true
  [ "$got" = "$want" ] || fail "gtd_next_date.sh $* gave '$got', want '$want'"
}
nd_case 2026-02-28 add 2026-01-31 1m
nd_case 2024-02-29 add 2024-01-31 1m
nd_case 2025-02-28 add 2024-02-29 1y
nd_case 2027-02-15 add 2026-11-15 3m
nd_case 2027-01-01 add 2026-12-30 2d
nd_case 2026-10-22 add 2026-10-01 3w
nd_case 2026-10-08 start 2026-10-15 7d
nd_case 2026-02-28 start 2026-03-31 1m
nd_case 2026-10-15 start 2026-10-15
nd_case 2027-04-15 next 3m 2027-01-15 2027-02-02
nd_case 2027-07-15 next 3m 2027-01-15 2027-05-03
nd_case 2027-04-15 next 3m 2027-01-15 2027-01-10
nd_case 2027-04-15 next 3m 2027-01-15 2027-01-15 fixed
nd_case 2027-01-12 next 3m 2026-10-15 2026-10-12 floating
nd_case 2026-02-28 next 1m 2026-01-31 2026-02-01
nd_case 2026-11-05 next 1w 2026-10-01 2026-10-30
bash "$ND" valid 3m || fail "gtd_next_date.sh valid rejected 3m"
for bad in quarterly 3 0m 3months 1m2w; do
  ! bash "$ND" valid "$bad" || fail "gtd_next_date.sh valid accepted '$bad'"
done
rc=0; bash "$ND" next quarterly 2026-01-01 2026-01-02 >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] || fail "gtd_next_date.sh next with a bad every exited $rc, want 2"
rc=0; bash "$ND" next 3m 2026-01-01 2026-01-02 weekly >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 2 ] || fail "gtd_next_date.sh next with a bad cadence exited $rc, want 2"
ok "gtd_next_date.sh: fixed by default (missed periods skipped), floating, month-end clamp, lead, bad input refused"

RC="$fixture/recur"
mkdir -p "$RC"
LLM_GTD_ROOT="$RC" CODEX_HOME="$fixture/codex" bash "$ROOT/scripts/gtd_init.sh" --confirm-create >/dev/null \
  || fail "gtd_init.sh failed (recurring fixture)"
RG="$RC/memory/gtd"
mkdir -p "$RG/projects/Home upkeep" "$RG/projects/Paused"
printf -- '---\noutcome: The house runs itself\n---\n' > "$RG/projects/Home upkeep/README.md"
printf -- '---\noutcome: Paused until spring\n---\n' > "$RG/projects/Paused/README.md"
rc_day() { bash "$ND" add "$tk_today" "$1"; }
rc_ago() { bash "$ND" start "$tk_today" "$1"; }
rtickle() {
  # rtickle TITLE FRONTMATTER-LINES — a tickler note with those properties
  printf -- '---\nid: tk-recur-20261010\n%s\ncreated: 2026-10-10\n---\n%s, the body.\n' "$2" "$1" > "$RG/tickler/$1.md"
}
# due: its lead window has opened (tickle in 3 days, lead 7d) and no action is open
rtickle "Pay the quarterly estimate" "every: 3m
lead: 7d
tickle: $(rc_day 3d)
project: \"[[projects/Home upkeep/README|Home upkeep]]\""
# overdue: dated 2 days ago with its action still open
rtickle "Water the plants" "every: 1w
tickle: $(rc_ago 2d)
time: 10
energy: low
context: [home]"
# coming up: dated in 20 days, no lead; its open action uses a bare from: link (link-form)
rtickle "Check the backups" "every: 1m
cadence: floating
tickle: $(rc_day 20d)
last_completed: $(rc_ago 10d)"
# the only link to a project: a recurring tickle never puts it on hold
rtickle "Review the garden" "every: 1y
tickle: 2999-01-01
project: \"[[projects/Paused/README|Paused]]\""
# invalid rules: treated as one-shot until fixed
rtickle "Bad every" "every: quarterly
tickle: 2999-01-01"
rtickle "Bad lead" "every: 1m
lead: soon
tickle: 2999-01-01"
rtickle "Bad fields" "every: 1m
cadence: weekly
last_completed: last week
energy: huge
tickle: 2999-01-01"
# a one-shot tickle in the same folder still behaves as before
rtickle "Start the one-shot" "tickle: 2000-01-01"
raction() {
  # raction TITLE FROM — an open next action created from a recurring tickle
  printf -- '---\ntime: 10\nenergy: low\ncontext: [home]\nfrom: "%s"\ndue: %s\n---\nx\n' "$2" "$(rc_ago 2d)" > "$RG/next-actions/$1.md"
}
raction "Water the plants" "[[tickler/Water the plants|Water the plants]]"
raction "Water the plants again" "[[tickler/Water the plants|Water the plants]]"
raction "Check the backups" "[[Check the backups]]"
raction "Feed the fish" "[[tickler/Feed the fish|Feed the fish]]"
printf -- '---\nfrom: "[[tickler/Water the plants|Water the plants]]"\ncompleted: 2026-09-01\nresult: done\nlist: next-actions\n---\nx\n' > "$RG/_done/Water the plants 2026-09-01.md"

tl="$(LLM_GTD_ROOT="$RC" bash "$ROOT/scripts/gtd_list.sh" tickler 2>&1)" || fail "gtd_list.sh tickler failed: $tl"
echo "$tl" | grep -q "${T}every=1w${T}lead=-${T}action=open${T}Water the plants$" || fail "gtd_list.sh tickler lacks every / lead / action columns: $tl"
echo "$tl" | grep -q "${T}every=-${T}lead=-${T}action=-${T}Start the one-shot$" || fail "gtd_list.sh tickler one-shot columns wrong: $tl"
echo "$tl" | grep -q "action=open${T}Check the backups$" || fail "gtd_list.sh tickler missed an action linked by a bare from: link: $tl"
rl_due="$(LLM_GTD_ROOT="$RC" bash "$ROOT/scripts/gtd_list.sh" tickler --due | awk -F'\t' '{ print $NF }' | sort | paste -sd ';' -)"
[ "$rl_due" = "Pay the quarterly estimate;Start the one-shot" ] || fail "gtd_list.sh tickler --due (want the lead-window routine and the one-shot): $rl_due"
rl_over="$(LLM_GTD_ROOT="$RC" bash "$ROOT/scripts/gtd_list.sh" tickler --overdue | awk -F'\t' '{ print $NF }' | paste -sd ';' -)"
[ "$rl_over" = "Water the plants" ] || fail "gtd_list.sh tickler --overdue: $rl_over"
rl_rec="$(LLM_GTD_ROOT="$RC" bash "$ROOT/scripts/gtd_list.sh" tickler --recurring | grep -c .)"
[ "$rl_rec" -eq 6 ] || fail "gtd_list.sh tickler --recurring counted $rl_rec, want 6 (bad every: is not recurring)"
rl_soon="$(LLM_GTD_ROOT="$RC" bash "$ROOT/scripts/gtd_list.sh" tickler --within 30 | awk -F'\t' '{ print $NF }' | paste -sd ';' -)"
[ "$rl_soon" = "Check the backups" ] || fail "gtd_list.sh tickler --within 30 (the lead-window routine is due, not upcoming): $rl_soon"
LLM_GTD_ROOT="$RC" bash "$ROOT/scripts/gtd_list.sh" next-actions | grep -q "from=\[\[tickler/Water the plants|Water the plants\]\]${T}Water the plants$" \
  || fail "gtd_list.sh next-actions lacks the from= column"
[ "$(LLM_GTD_ROOT="$RC" bash "$ROOT/scripts/gtd_list.sh" done --from "Water the plants" | grep -c .)" -eq 1 ] || fail "gtd_list.sh done --from did not find the routine's cycle"
[ -z "$(LLM_GTD_ROOT="$RC" bash "$ROOT/scripts/gtd_list.sh" done --from "Check the backups")" ] || fail "gtd_list.sh done --from matched another routine"

chk="$(LLM_GTD_ROOT="$RC" bash "$ROOT/scripts/gtd_check.sh")"
for want in "tickler-due${T}tickler/Pay the quarterly estimate.md" "tickler-overdue${T}tickler/Water the plants.md" \
  "tickler-due${T}tickler/Start the one-shot.md" "stalled${T}projects/Paused/README.md" \
  "tickler-every${T}tickler/Bad every.md" "tickler-every${T}tickler/Bad lead.md" \
  "field${T}tickler/Bad fields.md${T}cadence" "field${T}tickler/Bad fields.md${T}last_completed" \
  "field${T}tickler/Bad fields.md${T}energy" "orphan${T}next-actions/Feed the fish.md" \
  "link-form${T}next-actions/Check the backups.md${T}from:" "duplicate${T}next-actions/${T}same from:"; do
  echo "$chk" | grep -qF "$want" || fail "gtd_check.sh missed: $want"
done
! echo "$chk" | grep -qF "tickler-due${T}tickler/Water the plants.md" || fail "gtd_check.sh called a routine with an open action due"
! echo "$chk" | grep -qF "tickler-due${T}tickler/Check the backups.md" || fail "gtd_check.sh called a future routine due"
! echo "$chk" | grep -qE "tickler-overdue${T}tickler/(Pay the quarterly estimate|Check the backups|Start the one-shot)" || fail "gtd_check.sh called a routine overdue before its date (or a one-shot overdue)"
! echo "$chk" | grep -qE "${T}tickler/(Water the plants|Check the backups|Pay the quarterly estimate)\.md${T}(missing|.*not in)" || fail "gtd_check.sh flagged a routine's valid optional fields"
! echo "$chk" | grep -qF "orphan${T}next-actions/Water the plants" || fail "gtd_check.sh called a routine's action an orphan"
# Home upkeep's only link is a routine too, so it is stalled, like Paused
echo "$chk" | grep -qF "stalled${T}projects/Home upkeep/README.md" || fail "gtd_check.sh let a recurring tickle hold a project"

st="$(LLM_GTD_ROOT="$RC" bash "$ROOT/scripts/gtd_status.sh" 2>&1 || true)"
echo "$st" | grep -qE "Tickler +: 8 \(2 due\) · 6 recurring, 1 overdue" || fail "gtd_status.sh tickler line lacks recurring / overdue: $st"
echo "$st" | grep -q "1 routine(s) overdue" || fail "gtd_status.sh has no overdue-routine alert: $st"
rp="$(LLM_GTD_ROOT="$RC" bash "$ROOT/scripts/gtd_review_prep.sh" 2>&1 || true)"
rp_tk="$(part_of "$rp" '^## Tickler' '^## ')"
part_of "$rp_tk" '^Overdue routines' '^(Next 14 days|Projects on hold)' | grep -q 'Water the plants' || fail "review prep lacks the overdue routine: $rp_tk"
! part_of "$rp_tk" '^Projects on hold' '^$' | grep -q 'Paused' || fail "review prep calls a project on hold through a recurring tickle: $rp_tk"
! part_of "$rp" '^## Hygiene findings' '^## ' | grep -q 'tickler-overdue' || fail "review prep repeats tickler-overdue under Hygiene findings"
ok "recurring tickles: lead window, overdue, open-action guard, no project hold, from: links, duplicate routine actions, dashboard and review prep"

# Tagged-note updates (E44): gtd_tagged.sh finds every note in the workspace tagged gtd-update —
# in frontmatter tags (flow list, block list, scalar) or inline #gtd-update — and counts the lines
# still to apply under Update headings; it skips hidden folders, _done/, tags inside code, nested
# tags, applied headings and lines marked ✓.
TA="$fixture/tagged"
mkdir -p "$TA"
LLM_GTD_ROOT="$TA" CODEX_HOME="$fixture/codex" bash "$ROOT/scripts/gtd_init.sh" --confirm-create >/dev/null \
  || fail "gtd_init.sh failed (tagged-note fixture)"
mkdir -p "$TA/notes" "$TA/.obsidian"
tnote() { printf '%s\n' "$2" > "$TA/$1"; }
tnote "notes/Phone note.md" '---
tags: [daily, gtd-update]
---
Walked the dog.

## Update
- Statements are downloaded ✓
- Sam replied: the quote is approved

## Later
- not an update'
tnote "notes/Block tags.md" '---
tags:
  - journal
  - gtd-update
---
## Update
Push the dentist tickle to December'
tnote "notes/Scalar.md" '---
tags: gtd-update
---
# Day

### update
- one

- two
## Other
- not an update'
tnote "notes/Inline.md" 'Some text #gtd-update, more text.

## Update
- The backups check is done'
tnote "notes/Code only.md" 'Talking about `#gtd-update` in code.

```
#gtd-update
```

## Update
- would apply if tagged'
tnote "notes/Nested.md" 'A #gtd-update/later tag is another tag.

## Update
- nope'
tnote "notes/Untagged.md" 'This note mentions gtd-update without a tag.

## Update
- nope'
tnote "notes/Applied.md" '---
tags: [gtd-update]
---
## Update (applied 2026-10-01)
- old line'
tnote "notes/No section.md" '#gtd-update but nothing to apply.'
tnote ".obsidian/Hidden.md" '#gtd-update

## Update
- hidden'
tnote "memory/gtd/_done/Old.md" '#gtd-update

## Update
- finished'
tnote "memory/gtd/next-actions/Tagged action.md" '---
time: 10
energy: low
context: [phone]
tags: [gtd-update]
---
Call Sam.

## Update
- done, no problems'
tg="$(LLM_GTD_ROOT="$TA" bash "$ROOT/scripts/gtd_tagged.sh" 2>&1)" || fail "gtd_tagged.sh failed: $tg"
tg_want="memory/gtd/next-actions/Tagged action.md${T}updates=1${T}Tagged action
notes/Applied.md${T}updates=0${T}Applied
notes/Block tags.md${T}updates=1${T}Block tags
notes/Inline.md${T}updates=1${T}Inline
notes/No section.md${T}updates=0${T}No section
notes/Phone note.md${T}updates=1${T}Phone note
notes/Scalar.md${T}updates=2${T}Scalar"
[ "$tg" = "$tg_want" ] || fail "gtd_tagged.sh listed:
$tg
want:
$tg_want"
st="$(LLM_GTD_ROOT="$TA" bash "$ROOT/scripts/gtd_status.sh" 2>&1 || true)"
echo "$st" | grep -qE "Tagged updates +: 5" || fail "gtd_status.sh lacks 'Tagged updates: 5': $st"
echo "$st" | grep -q "5 tagged note(s) to apply → /gtd-update" || fail "gtd_status.sh has no tagged-note alert: $st"
rp="$(LLM_GTD_ROOT="$TA" bash "$ROOT/scripts/gtd_review_prep.sh" 2>&1 || true)"
rp_tag="$(part_of "$rp" '^## Tagged notes' '^## ')"
echo "$rp_tag" | grep -q 'notes/Scalar.md (2 lines)' && echo "$rp_tag" | grep -q 'notes/No section.md (nothing to apply)' \
  || fail "review prep Tagged notes section wrong: $rp_tag"
[ -z "$(LLM_GTD_ROOT="$RC" bash "$ROOT/scripts/gtd_tagged.sh")" ] || fail "gtd_tagged.sh found tagged notes in a workspace with none"
ok "tagged notes: frontmatter and inline tags found, code / nested tags / hidden folders / _done/ skipped, applied headings and ✓ lines not counted; dashboard and review prep"

# Property links (E37): Obsidian renders a wikilink in a frontmatter property only when the link is
# the property's whole value, quoted; several links are a YAML list, one quoted link per item.
# gtd_check.sh's property-link flags any other shape in any note under memory/gtd/ or the
# workspace-root reference/, and never a link in the note body; link-form flags a link written
# from the vault root (memory/gtd/...) instead of relative to memory/gtd/.
LK="$fixture/links"
mkdir -p "$LK"
LLM_GTD_ROOT="$LK" CODEX_HOME="$fixture/codex" bash "$ROOT/scripts/gtd_init.sh" --confirm-create >/dev/null \
  || fail "gtd_init.sh failed (property-link fixture)"
LG="$LK/memory/gtd"
mkdir -p "$LG/projects/Alpha" "$LG/projects/Beta"
printf -- '---\noutcome: Alpha shipped\n---\n' > "$LG/projects/Alpha/README.md"
# lnote PATH FRONTMATTER-LINES [BODY] — a note under memory/gtd/ with that frontmatter
lnote() {
  { printf -- '---\n%s\n---\n' "$2"; printf '%s\n' "${3:-The body.}"; } > "$LG/$1"
}
P='[[projects/Alpha/README|Alpha]]'
# bad: text after the link, before it, after the closing quote; two links; unquoted; a list
# item with text; a project README; a [a, b] list with an unquoted link
lnote "next-actions/Trailing text.md" "project: \"$P\"
source: \"[[projects/Alpha/PLAN|plan]] (Phase 4 step 5)\""
lnote "next-actions/Leading text.md" "project: \"$P\"
source: \"see [[projects/Alpha/PLAN|plan]]\""
lnote "next-actions/After the quote.md" "project: \"$P\"
source: \"[[projects/Alpha/PLAN|plan]]\" (Phase 4 step 5)"
lnote "next-actions/Two links.md" "project: \"$P\"
related: \"[[projects/Alpha/PLAN|plan]], [[reference/Notes|Notes]]\""
lnote "next-actions/Unquoted.md" "project: \"$P\"
source: [[projects/Alpha/PLAN|plan]]"
lnote "someday-maybe/List item text.md" "related:
  - \"[[reference/Notes|Notes]]\"
  - \"[[projects/Alpha/PLAN|plan]] and more\""
lnote "projects/Beta/README.md" "outcome: Beta shipped
source: \"[[reference/Notes|Notes]] (section 2)\""
lnote "waiting-for/Flow list.md" "person: Sam
delegated: 2026-09-01
related: [\"[[reference/Notes|Notes]]\", [[projects/Alpha/PLAN|plan]]]"
# an embed with text; a general reference note at the workspace root
lnote "next-actions/Embed text.md" "cover: \"![[img.png]] (old)\""
mkdir -p "$LK/reference"
printf -- '---\nrelated: "[[projects/Alpha/README|Alpha]] (see notes)"\n---\nx\n' > "$LK/reference/Bad ref.md"
printf -- '---\nrelated:\n  - "[[projects/Alpha/README|Alpha]]"\n---\nx\n' > "$LK/reference/Good ref.md"
# long-form paths (from the vault root): link-form, with the short form; text around one too is
# one property-link finding whose fix already uses the short form
lnote "next-actions/Long path.md" "project: \"$P\"
source: \"[[memory/gtd/projects/Alpha/PLAN|plan]]\""
lnote "next-actions/Long text.md" "project: \"$P\"
source: \"[[memory/gtd/projects/Alpha/PLAN|plan]] (step 5)\""
# a project: link in the wrong form (bare, unquoted; long-form) is reported once, by the
# project-form check, not again by the property checks — and the long form isn't an orphan
lnote "next-actions/Bare project.md" "project: [[projects/Alpha]]"
lnote "next-actions/Long project.md" "project: \"[[memory/gtd/projects/Alpha/README|Alpha]]\""
# good: whole quoted value (with a YAML comment, single quotes), a YAML list, a [a, b] list of
# quoted links, detail inside the display text, and bad-looking links only in the body
lnote "next-actions/Whole link.md" "project: \"$P\"   # optional
source: '[[projects/Alpha/PLAN|plan]]'"
lnote "next-actions/Link list.md" "project: \"$P\"
related:
  - \"[[projects/Alpha/PLAN|plan]]\"
  - \"[[reference/Notes|Notes]]\""
lnote "next-actions/Embed ok.md" "cover: \"![[img.png]]\"
images:
  - \"![[a.png]]\"
  - '![[b.png|200]]'"
lnote "next-actions/Flow list ok.md" "project: \"$P\"
related: [\"[[projects/Alpha/PLAN|plan]]\", \"[[reference/Notes|Notes]]\"]"
lnote "next-actions/Detail inside.md" "project: \"$P\"
source: \"[[projects/Alpha/PLAN|plan (Phase 4 step 5)]]\""
lnote "next-actions/Body links.md" "project: \"$P\"" "Project: [[projects/Alpha/README|Alpha]] · Date: 20260925
source: \"[[projects/Alpha/PLAN|plan]] (Phase 4 step 5)\"

---
related: \"see [[reference/Notes|Notes]]\""
printf 'No frontmatter here.\n\n---\nsource: "[[reference/Notes|Notes]] (x)"\n---\n' > "$LG/next-actions/No frontmatter.md"

chk="$(LLM_GTD_ROOT="$LK" bash "$ROOT/scripts/gtd_check.sh")"
pl="property-link${T}"
lf="link-form${T}"
for want in \
  "${pl}next-actions/Trailing text.md${T}source: \"[[projects/Alpha/PLAN|plan]] (Phase 4 step 5)\" — text outside the link -> \"[[projects/Alpha/PLAN|plan (Phase 4 step 5)]]\"" \
  "${pl}next-actions/Leading text.md${T}source: \"see [[projects/Alpha/PLAN|plan]]\" — text outside the link -> \"[[projects/Alpha/PLAN|see plan]]\"" \
  "${pl}next-actions/After the quote.md${T}source: \"[[projects/Alpha/PLAN|plan]]\" (Phase 4 step 5) — text outside the link -> \"[[projects/Alpha/PLAN|plan (Phase 4 step 5)]]\"" \
  "${pl}next-actions/Two links.md${T}related: \"[[projects/Alpha/PLAN|plan]], [[reference/Notes|Notes]]\" — 2 links in one value -> a YAML list, one quoted link per item" \
  "${pl}next-actions/Unquoted.md${T}source: [[projects/Alpha/PLAN|plan]] — unquoted (YAML reads it as a nested list) -> \"[[projects/Alpha/PLAN|plan]]\"" \
  "${pl}someday-maybe/List item text.md${T}related (item 2): \"[[projects/Alpha/PLAN|plan]] and more\" — text outside the link -> \"[[projects/Alpha/PLAN|plan and more]]\"" \
  "${pl}projects/Beta/README.md${T}source: \"[[reference/Notes|Notes]] (section 2)\" — text outside the link -> \"[[reference/Notes|Notes (section 2)]]\"" \
  "${pl}waiting-for/Flow list.md${T}related (item 2): [[projects/Alpha/PLAN|plan]] — unquoted (YAML reads it as a nested list) -> \"[[projects/Alpha/PLAN|plan]]\"" \
  "${pl}next-actions/Embed text.md${T}cover: \"![[img.png]] (old)\" — text outside the embed -> \"![[img.png]]\" (the rest in another property)" \
  "${pl}reference/Bad ref.md${T}related: \"[[projects/Alpha/README|Alpha]] (see notes)\" — text outside the link -> \"[[projects/Alpha/README|Alpha (see notes)]]\"" \
  "${lf}next-actions/Long path.md${T}source: \"[[memory/gtd/projects/Alpha/PLAN|plan]]\" — path from the vault root -> \"[[projects/Alpha/PLAN|plan]]\"" \
  "${pl}next-actions/Long text.md${T}source: \"[[memory/gtd/projects/Alpha/PLAN|plan]] (step 5)\" — text outside the link -> \"[[projects/Alpha/PLAN|plan (step 5)]]\"" \
  "${lf}next-actions/Long project.md${T}project: [[memory/gtd/projects/Alpha/README|Alpha]] -> [[projects/Alpha/README|Alpha]]"; do
  echo "$chk" | grep -qxF "$want" || fail "gtd_check.sh missed: $want"
done
# links_in PATH — the link-form and property-link findings for one note
links_in() { echo "$chk" | grep -E "^(link-form|property-link)${T}" | grep -F "${T}$1${T}" || true; }
for once in "next-actions/Bare project.md" "next-actions/Long project.md" "next-actions/Long text.md" \
  "next-actions/Long path.md" "waiting-for/Flow list.md" "someday-maybe/List item text.md" "reference/Bad ref.md"; do
  [ "$(links_in "$once" | grep -c .)" -eq 1 ] || fail "gtd_check.sh reported $once other than once: $(links_in "$once")"
done
links_in "next-actions/Bare project.md" | grep -q "^${lf}" || fail "a bare project: link is not link-form"
! echo "$chk" | grep -qF "orphan${T}next-actions/Long project.md" || fail "gtd_check.sh called a long-form project: link an orphan"
for clean in next-actions/"Whole link" next-actions/"Link list" next-actions/"Flow list ok" next-actions/"Detail inside" \
  next-actions/"Body links" next-actions/"No frontmatter" next-actions/"Embed ok" reference/"Good ref"; do
  [ -z "$(links_in "$clean.md")" ] || fail "gtd_check.sh flagged a good property link: $(links_in "$clean.md")"
done
[ -z "$(echo "$chk" | grep -E "^(link-form|property-link)${T}" | grep -vF "projects/Beta/README.md${T}" | grep -F "README.md${T}")" ] \
  || fail "gtd_check.sh flagged a list README's links: $chk"
ok "property links: text around a link or embed, several links, unquoted and [a, b] lists flagged (memory/gtd/ and reference/); long paths are link-form; one finding per property; whole links, embeds, YAML lists and the body left alone"

if [ "${GTD_PRIVACY_DENYLIST:-}" != "" ]; then
  if rg -n "$GTD_PRIVACY_DENYLIST" "$ROOT"; then
    fail "privacy denylist matched under skill root"
  fi
  ok "privacy denylist has no matches"
else
  echo "ℹ️  GTD_PRIVACY_DENYLIST not set; skipped private denylist scan"
fi

echo "GTD skill eval check passed"
