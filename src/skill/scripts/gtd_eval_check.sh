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
  memory/gtd/someday-maybe/README.md memory/gtd/product-ideas/README.md memory/gtd/_done/README.md \
  memory/gtd/next-actions.base memory/gtd/done.base; do
  [ -f "$fixture/notes/$f" ] || fail "per-item init did not create $f"
done
for f in next-actions waiting-for projects someday-maybe product-ideas reference; do
  [ ! -e "$fixture/notes/memory/gtd/$f.md" ] || fail "per-item init also wrote single-file $f.md"
done
grep -q '^## Note format' "$fixture/notes/memory/gtd/next-actions/README.md" || fail "next-actions README lacks its Note format section"
grep -q '^## Legacy groups' "$fixture/notes/memory/gtd/next-actions/README.md" || fail "next-actions README lacks its Legacy groups section"
[ -z "$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" next-actions)" ] || fail "gtd_list.sh counted README.md as an item"
[ -z "$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" projects)" ] || fail "gtd_list.sh counted projects/README.md as a project"
LLM_GTD_ROOT="$fixture/files" CODEX_HOME="$fixture/codex" bash "$ROOT/scripts/gtd_init.sh" --confirm-create >/dev/null \
  || fail "gtd_init.sh single-file init failed"
rc=0; LLM_GTD_ROOT="$fixture/files" bash "$ROOT/scripts/gtd_init.sh" --confirm-create --layout notes >/dev/null 2>&1 || rc=$?
[ "$rc" -eq 4 ] || fail "init did not refuse to turn a single-file system into per-item (exit $rc, want 4)"
[ ! -d "$fixture/files/memory/gtd/next-actions" ] || fail "refused per-item init still created next-actions/"
ok "per-item init: folders + READMEs + bases created, README never an item, layout switch refused"

# Per-item read path: lenses filter, _done/ is never listed, and gtd_check.sh finds each kind of
# mechanical problem (and nothing on a clean note).
G="$fixture/notes/memory/gtd"
mkdir -p "$G/projects/Alpha" "$G/projects/Idle"
printf -- '---\noutcome: Alpha shipped\n---\n' > "$G/projects/Alpha/README.md"
printf -- '---\noutcome: Nothing linked\n---\n' > "$G/projects/Idle/README.md"
printf -- '---\ntime: 10   # minutes\nenergy: low\ncontext: [computer, phone]\nproject: "[[projects/Alpha/README|Alpha]]"\n---\nx\n' > "$G/next-actions/Quick call.md"
printf -- '---\ntime: 60-90 min\nenergy: deep work\ncontext: [lab]\nproject: "[[projects/Gone/README|Gone]]"\n---\nx\n' > "$G/next-actions/quick call (2).md"
printf -- '---\ntime: 5\nenergy: low\ncontext: [home]\ncompleted: 2026-01-01\nlist: next-actions\n---\nx\n' > "$G/_done/Finished thing.md"
printf -- '---\nlist: projects\n---\nx\n\n## After action review\n<!-- draft -->\n' > "$G/_done/Old project.md"
na="$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" next-actions --max-time 10 --energy low)"
[ "$(echo "$na" | grep -c .)" -eq 1 ] && echo "$na" | grep -q 'Quick call$' || fail "gtd_list.sh lenses returned: $na"
echo "$na" | grep -q 'due=-' || fail "gtd_list.sh next-actions lacks the due= column"
! LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_list.sh" next-actions | grep -q 'Finished thing' || fail "gtd_list.sh listed a _done/ note"
chk="$(LLM_GTD_ROOT="$fixture/notes" bash "$ROOT/scripts/gtd_check.sh")"
T=$'\t'
dup="next-actions/quick call (2).md"
for want in "orphan${T}$dup" "stalled${T}projects/Idle/README.md" "field${T}$dup${T}time" \
  "field${T}$dup${T}energy" "field${T}$dup${T}context 'lab'" "duplicate${T}next-actions/" \
  "done-completed${T}_done/Old project.md" "done-no-aar${T}_done/Old project.md"; do
  echo "$chk" | grep -qF "$want" || fail "gtd_check.sh missed: $want"
done
! echo "$chk" | grep -qF "${T}next-actions/Quick call.md${T}" || fail "gtd_check.sh flagged a clean note"
! echo "$chk" | grep -qF "stalled${T}projects/Alpha/" || fail "gtd_check.sh called a linked project stalled"
[ -z "$(echo "$chk" | awk -F'\t' '$2 ~ /README\.md$/ && $2 !~ /^projects\/[^\/]+\/README\.md$/')" ] \
  || fail "gtd_check.sh treated a list README as an item"
LLM_GTD_ROOT="$fixture/files" bash "$ROOT/scripts/gtd_check.sh" | grep -q '^# layout: files' || fail "gtd_check.sh did not stand down in the single-file layout"
ok "per-item read path: lenses filter, _done/ never listed, gtd_check.sh finds every kind of problem"

if [ "${GTD_PRIVACY_DENYLIST:-}" != "" ]; then
  if rg -n "$GTD_PRIVACY_DENYLIST" "$ROOT"; then
    fail "privacy denylist matched under skill root"
  fi
  ok "privacy denylist has no matches"
else
  echo "ℹ️  GTD_PRIVACY_DENYLIST not set; skipped private denylist scan"
fi

echo "GTD skill eval check passed"
