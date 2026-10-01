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

# Per-item init fixture: builds the layout in a throwaway root, checks every list folder has its
# README, README is never listed as an item, and init refuses to switch an existing layout.
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/notes" "$fixture/files"
LLM_GTD_ROOT="$fixture/notes" CODEX_HOME="$fixture/codex" \
  bash "$ROOT/scripts/gtd_init.sh" --confirm-create --layout notes --with-bases >/dev/null \
  || fail "gtd_init.sh --layout notes failed"
for f in memory/gtd/inbox.md memory/gtd/calendar.md memory/gtd/horizons.md reference/README.md \
  memory/gtd/next-actions/README.md memory/gtd/waiting-for/README.md memory/gtd/projects/README.md \
  memory/gtd/someday-maybe/README.md memory/gtd/_done/README.md \
  memory/gtd/next-actions.base memory/gtd/done.base memory/gtd/tickler/README.md memory/gtd/tickler.base; do
  [ -f "$fixture/notes/$f" ] || fail "per-item init did not create $f"
done
grep -q '^## Note format' "$fixture/notes/memory/gtd/tickler/README.md" || fail "tickler README lacks its Note format section"
grep -qi 'tickle' "$fixture/notes/memory/gtd/projects/README.md" || fail "projects README's stalled rule does not name the tickle"
for f in next-actions waiting-for projects someday-maybe reference; do
  [ ! -e "$fixture/notes/memory/gtd/$f.md" ] || fail "per-item init also wrote single-file $f.md"
done
[ ! -e "$fixture/notes/memory/gtd/product-ideas" ] || fail "per-item init created a product-ideas/ list (retired in 2.0.0)"
grep -q '^## Note format' "$fixture/notes/memory/gtd/next-actions/README.md" || fail "next-actions README lacks its Note format section"
grep -q '^## Legacy groups' "$fixture/notes/memory/gtd/next-actions/README.md" || fail "next-actions README lacks its Legacy groups section"
[ -z "$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" next-actions)" ] || fail "gtd_list.sh counted README.md as an item"
[ -z "$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" projects)" ] || fail "gtd_list.sh counted projects/README.md as a project"
LLM_GTD_ROOT="$fixture/files" CODEX_HOME="$fixture/codex" bash "$ROOT/scripts/gtd_init.sh" --confirm-create >/dev/null \
  || fail "gtd_init.sh single-file init failed"
[ ! -e "$fixture/files/memory/gtd/tickler.md" ] && [ ! -e "$fixture/files/memory/gtd/tickler" ] \
  || fail "single-file init created a tickler (the tickler is per-item only)"
rc=0; LLM_GTD_ROOT="$fixture/files" bash "$ROOT/scripts/gtd_init.sh" --confirm-create --layout notes >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 4 ] || fail "init did not refuse to turn a single-file system into per-item (exit $rc, want 4)"
[ ! -d "$fixture/files/memory/gtd/next-actions" ] || fail "refused per-item init still created next-actions/"
ok "per-item init: folders + READMEs + bases created (tickler included), README never an item, layout switch refused"

# Per-item read path: lenses filter, _done/ is never listed, and gtd_check.sh finds each kind of
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
LLM_GTD_ROOT="$fixture/files" bash "$ROOT/scripts/gtd_check.sh" | grep -q '^# layout: files' || fail "gtd_check.sh did not stand down in the single-file layout"
ok "per-item read path: lenses filter, _done/ never listed, gtd_check.sh finds every kind of problem"

# Done record (both layouts): gtd_list.sh done lists every record once, never a support doc or the
# folder README, and --since / --project / --problems filter it.
done_all="$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" done)"
[ "$(echo "$done_all" | grep -c .)" -eq 4 ] || fail "gtd_list.sh done (per-item) listed: $done_all"
echo "$done_all" | grep -q "list=projects${T}project=Old project${T}.*Old project$" || fail "gtd_list.sh done missed the finished project folder"
[ "$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" done --since 2026-01-15 | grep -c .)" -eq 1 ] || fail "gtd_list.sh done --since did not filter"
[ "$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" done --problems | cut -f1-7 | grep -c .)" -eq 1 ] || fail "gtd_list.sh done --problems did not filter"
[ "$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" done --project "Old project" | grep -c .)" -eq 2 ] || fail "gtd_list.sh done --project did not find the project and its step"
[ -f "$fixture/files/memory/gtd/done.md" ] || fail "single-file init did not seed done.md"
cat >> "$fixture/files/memory/gtd/done.md" <<'EOF'
## 2026-03-01
- [x] Pay the tax bill · From: next-actions · Result: done · Project: [[projects#Taxes|Taxes]] ^na-tax-20260201
  - Done: paid online
  - Problems and fixes: the portal timed out twice; paying before 8 am worked.
- [x] Project: Taxes — filed and paid · From: projects · Result: done
  - Done: filed and paid
  - Problems and fixes: none noted
EOF
done_sf="$(LLM_GTD_ROOT="$fixture/files" bash "$ROOT/scripts/gtd_list.sh" done)"
[ "$(echo "$done_sf" | grep -c .)" -eq 2 ] || fail "gtd_list.sh done (single-file) listed: $done_sf"
echo "$done_sf" | grep -q "^na-tax-20260201${T}completed=2026-03-01${T}result=done${T}list=next-actions${T}.*problems=yes" || fail "gtd_list.sh done (single-file) misparsed: $done_sf"
[ "$(LLM_GTD_ROOT="$fixture/files" bash "$ROOT/scripts/gtd_list.sh" done --project Taxes | grep -c .)" -eq 2 ] || fail "gtd_list.sh done --project (single-file) did not match the project line"
ok "done record: gtd_list.sh done reads both layouts and filters by --since / --project / --problems"

# Tickler (per-item only): a tickle puts its project in play (never stalled), a due tickle is
# tickler-due, --due / --within split by date, tickles get the actions' project-link checks, the inbox
# guard, the dashboard line and review prep's Tickler section; no tickler lists nothing.
# Dates are relative to the run date so the gate never goes stale.
TK="$fixture/tick"
mkdir -p "$TK"
LLM_GTD_ROOT="$TK" CODEX_HOME="$fixture/codex" bash "$ROOT/scripts/gtd_init.sh" --confirm-create --layout notes >/dev/null \
  || fail "gtd_init.sh --layout notes failed (tickler fixture)"
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
LLM_GTD_ROOT="$NT" CODEX_HOME="$fixture/codex" bash "$ROOT/scripts/gtd_init.sh" --confirm-create --layout notes >/dev/null || fail "gtd_init.sh failed (no-tickler fixture)"
rm -rf "$NT/memory/gtd/tickler"
out="$(LLM_GTD_ROOT="$NT" bash "$ROOT/scripts/gtd_list.sh" tickler 2>&1)" && [ -z "$out" ] || fail "gtd_list.sh tickler with no tickler/ folder: $out"
LLM_GTD_ROOT="$NT" bash "$ROOT/scripts/gtd_status.sh" >/dev/null 2>&1 || fail "gtd_status.sh failed with no tickler/ folder"
out="$(LLM_GTD_ROOT="$fixture/files" bash "$ROOT/scripts/gtd_list.sh" tickler 2>&1)" && [ -z "$out" ] || fail "gtd_list.sh tickler in the single-file layout: $out"
! LLM_GTD_ROOT="$fixture/files" bash "$ROOT/scripts/gtd_status.sh" 2>&1 | grep -q 'Tickler' || fail "gtd_status.sh shows a Tickler line in the single-file layout"
! LLM_GTD_ROOT="$fixture/files" bash "$ROOT/scripts/gtd_review_prep.sh" 2>&1 | grep -q '^## Tickler' || fail "gtd_review_prep.sh shows a Tickler section in the single-file layout"
ok "tickler: tickled projects in play, due / within split, link checks, inbox guard, dashboard and review prep; none in single-file"

if [ "${GTD_PRIVACY_DENYLIST:-}" != "" ]; then
  if rg -n "$GTD_PRIVACY_DENYLIST" "$ROOT"; then
    fail "privacy denylist matched under skill root"
  fi
  ok "privacy denylist has no matches"
else
  echo "ℹ️  GTD_PRIVACY_DENYLIST not set; skipped private denylist scan"
fi

echo "GTD skill eval check passed"
