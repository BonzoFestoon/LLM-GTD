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
ok "shell scripts pass bash -n"

if [ "${GTD_PRIVACY_DENYLIST:-}" != "" ]; then
  if rg -n "$GTD_PRIVACY_DENYLIST" "$ROOT"; then
    fail "privacy denylist matched under skill root"
  fi
  ok "privacy denylist has no matches"
else
  echo "ℹ️  GTD_PRIVACY_DENYLIST not set; skipped private denylist scan"
fi

echo "GTD skill eval check passed"
