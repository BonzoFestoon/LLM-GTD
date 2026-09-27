#!/usr/bin/env bash
# gtd_init.sh — idempotently build the GTD trusted system (memory/gtd/ eight core lists + product-ideas extension list) + adapter self-check + read-only automation cadence check
#
# Usage:
#   bash gtd_init.sh                  # REFUSES to create anything without --confirm-create (exit 3); prints where it would create the lists so the agent can ask the user first
#   bash gtd_init.sh --confirm-create # after the user has confirmed: idempotently create the eight core lists + product-ideas extension list + self-check + read-only automation check (existing files are never overwritten)
#   bash gtd_init.sh --import-legacy  # combine with --confirm-create: also do a one-time import from the old memory/open loops.md (old file is not modified)
#   bash gtd_init.sh --status         # self-check, read-only automation check, and readiness report only; writes no files, never requires --confirm-create
#   bash gtd_init.sh --install-cron   # explicitly request installing the GTD automation cadence; plain shell only prints an agent handoff — the gtd-init skill creates it via the platform automation tool
#
# Safety: exactly ONE GTD inbox per person. Without --confirm-create this script only reports
# where it would create files and exits 3 — see init/SKILL.md's "One inbox per human" rule for
# the ask-first workflow the agent must follow before ever passing --confirm-create.
#
# Design: David Allen's GTD — a trusted system must be complete (eight core lists kept physically separate) and non-destructive (safe to re-run).
# Compatible with macOS bash 3.2 (no associative arrays / mapfile).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/gtd_env.sh"
SKILL_DIR="$GTD_SKILL_DIR"
VAULT_ROOT="$GTD_WORKSPACE_ROOT"
GTD_DIR="$VAULT_ROOT/memory/gtd"
LEGACY_FILE="$VAULT_ROOT/memory/open loops.md"
AUTOMATIONS_DIR="${CODEX_HOME:-$HOME/.codex}/automations"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
CODEX_PROMPTS_DIR="$CODEX_HOME_DIR/prompts"
CODEX_PROMPT_TEMPLATES="$SKILL_DIR/templates/codex-prompts"
CODEX_PROMPT_FILES="gtd.md gtd-init.md gtd-capture.md gtd-clarify.md gtd-update.md gtd-organize.md gtd-engage.md gtd-review.md"

IMPORT_LEGACY=0
STATUS_ONLY=0
INSTALL_CRON=0
CONFIRM_CREATE=0
for arg in "$@"; do
  case "$arg" in
    --import-legacy) IMPORT_LEGACY=1 ;;
    --status)        STATUS_ONLY=1 ;;
    --install-cron)  INSTALL_CRON=1 ;;
    --confirm-create) CONFIRM_CREATE=1 ;;
    *) echo "Unknown argument: $arg" >&2; exit 2 ;;
  esac
done

# Safety: GTD needs exactly ONE inbox per person, so init never bootstraps on its own.
# Creating files requires --confirm-create, which the agent may pass only after asking the
# user (1) whether GTD is already set up somewhere and (2) confirming the location below.
if [ "$STATUS_ONLY" -eq 0 ] && [ "$CONFIRM_CREATE" -eq 0 ]; then
  echo "GTD Skill · init — REFUSING to create files without confirmation." >&2
  echo "  Would create the GTD lists in: $GTD_DIR" >&2
  if [ -d "$GTD_DIR" ]; then
    echo "  That folder already exists. Use it; do not create another." >&2
  fi
  echo "  Ask the user: 'Is GTD already set up somewhere? If not, is this the right location?'" >&2
  echo "  Only after they confirm, re-run with --confirm-create. Use --status for a read-only check." >&2
  exit 3
fi

created=0
skipped=0

# Write only if the file does not exist (idempotent, non-destructive)
seed() {
  local path="$1"; shift
  if [ -f "$path" ]; then
    skipped=$((skipped+1))
    return 0
  fi
  cat > "$path"
  created=$((created+1))
  echo "  ✅ Created ${path#$VAULT_ROOT/}"
}

# ── Self-check: adapter layer integrity ──
selfcheck() {
  echo ""
  echo "── Adapter layer self-check ──"
  local skill_real="$VAULT_ROOT/.cursor/skills/gtd-harness/SKILL.md"
  if [ -f "$skill_real" ]; then
    echo "  ✅ Source of truth reachable: .cursor/skills/gtd-harness/SKILL.md"
  elif [ -f "$SKILL_DIR/SKILL.md" ]; then
    echo "  ✅ Plugin source of truth reachable: $SKILL_DIR/SKILL.md"
  else
    echo "  ⚠️  Source of truth missing: cannot find gtd-harness/SKILL.md"
  fi

  if [ "$GTD_LEGACY_VAULT_INSTALL" -eq 1 ]; then
    local entry
    for entry in .claude/skills .agent/skills .agents/skills; do
      if [ -e "$VAULT_ROOT/$entry/gtd-harness/SKILL.md" ]; then
        echo "  ✅ Entry point reachable: $entry/gtd-harness (→ .cursor/skills)"
      else
        echo "  ℹ️  Entry point not resolved: $entry/gtd-harness (legacy adapter entry, optional)"
      fi
    done
    local chk="$VAULT_ROOT/.codex/scripts/check-agent-dirs.sh"
    if [ -f "$chk" ]; then
      echo "  ℹ️  Deep check available: bash .codex/scripts/check-agent-dirs.sh"
    fi

    local missing_codex=0
    local prompt
    for prompt in $CODEX_PROMPT_FILES; do
      if [ ! -f "$CODEX_PROMPTS_DIR/$prompt" ]; then
        missing_codex=$((missing_codex+1))
      fi
    done
    if [ "$missing_codex" -eq 0 ]; then
      echo "  ✅ Codex slash commands reachable: $CODEX_PROMPTS_DIR/gtd*.md"
    else
      echo "  ⚠️  $missing_codex Codex slash command(s) missing: $CODEX_PROMPTS_DIR/gtd*.md (in legacy install mode, init installs/refreshes them automatically)"
    fi
  else
    echo "  ℹ️  Plugin mode: the current workspace is the GTD state root; legacy symlink entry points are not needed."
  fi

  if [ -d "$CODEX_PROMPT_TEMPLATES" ]; then
    echo "  ✅ Codex prompt templates reachable: $CODEX_PROMPT_TEMPLATES"
  else
    echo "  ℹ️  Codex prompt templates missing (not needed in plugin mode): $CODEX_PROMPT_TEMPLATES"
  fi
}

# ── Install/refresh Codex slash commands (global, CODEX_HOME level) ──
install_codex_prompts() {
  if [ ! -d "$CODEX_PROMPT_TEMPLATES" ]; then
    echo "  ⚠️  Codex prompt templates not found, skipping: ${CODEX_PROMPT_TEMPLATES#$VAULT_ROOT/}"
    return 0
  fi
  mkdir -p "$CODEX_PROMPTS_DIR"

  local installed=0
  local updated=0
  local unchanged=0
  local prompt src dst
  for prompt in $CODEX_PROMPT_FILES; do
    src="$CODEX_PROMPT_TEMPLATES/$prompt"
    dst="$CODEX_PROMPTS_DIR/$prompt"
    if [ ! -f "$src" ]; then
      echo "  ⚠️  Template missing: $prompt"
      continue
    fi
    if [ -f "$dst" ] && cmp -s "$src" "$dst"; then
      unchanged=$((unchanged+1))
    elif [ -f "$dst" ]; then
      cp "$src" "$dst"
      updated=$((updated+1))
    else
      cp "$src" "$dst"
      installed=$((installed+1))
    fi
  done
  echo "  ✅ Codex slash commands → ${CODEX_PROMPTS_DIR}/ (new ${installed}, updated ${updated}, unchanged ${unchanged})"
}

# ── Self-check: current automation cadence (read-only; never creates cron / automation) ──
automation_status() {
  local id="$1"
  local label="$2"
  local file="$AUTOMATIONS_DIR/$id/automation.toml"
  if [ -f "$file" ]; then
    local status name
    status="$(awk -F'"' '/^status = / {print $2; exit}' "$file" 2>/dev/null || true)"
    name="$(awk -F'"' '/^name = / {print $2; exit}' "$file" 2>/dev/null || true)"
    [ -n "$status" ] || status="UNKNOWN"
    [ -n "$name" ] || name="$id"
    echo "  ✅ ${label}: installed (${name}, ${status})"
  else
    echo "  ⚪ ${label}: not installed (requires explicit install; see references/automation-profiles.md)"
  fi
}

automation_selfcheck() {
  echo ""
  echo "── Automation cadence self-check (read-only, creates nothing) ──"
  if [ ! -d "$AUTOMATIONS_DIR" ]; then
    echo "  ⚪ Codex automations directory not found: $AUTOMATIONS_DIR"
    echo "  ℹ️  To install a cadence, read references/automation-profiles.md first, then create it explicitly with the platform's native automation tool."
    return 0
  fi

  automation_status "gtd-ai" "Weekly Review"
  automation_status "gtd-2" "Monthly Reflect"

  local daily_found=0
  if [ -f "$AUTOMATIONS_DIR/gtd/automation.toml" ]; then
    automation_status "gtd" "Daily Engage (morning)"
    daily_found=1
  fi
  if [ -f "$AUTOMATIONS_DIR/gtd-engage/automation.toml" ]; then
    automation_status "gtd-engage" "Daily Engage (evening)"
    daily_found=1
  fi
  if [ "$daily_found" -eq 0 ]; then
    echo "  ⚪ Daily Engage: not installed (optional; Approval Radar can be enabled together with Daily Engage)"
  fi

  echo "  ℹ️  init only checks and never creates silently; installing or changing cron requires the user's explicit consent."
}

cron_install_handoff() {
  echo ""
  echo "── Automation cadence install request (agent handoff) ──"
  echo "  --install-cron detected."
  echo "  Plain shell cannot call the Codex app's automation tool and should not hand-write ~/.codex/automations."
  echo "  In a Codex / gtd-init skill session, call automation_update as described in references/automation-profiles.md:"
  echo "  1. Install/update Weekly Review"
  echo "  2. Install/update Monthly Reflect"
  echo "  3. Install/update Daily Engage + Approval Radar (if an approval provider is enabled)"
  echo "  Then re-run: bash scripts/gtd_init.sh --status (legacy installs: .cursor/skills/gtd-harness/scripts/gtd_init.sh)"
}

# ── Optional: import from the old open loops.md (old file is read-only, never modified) ──
# The section names below (@自己 = self, @等待 = waiting, @项目 = projects) match the legacy
# Chinese-language open loops.md format and must stay as-is for the import to find them.
import_legacy() {
  if [ ! -f "$LEGACY_FILE" ]; then
    echo "  ⚠️  Legacy file not found, skipping import: ${LEGACY_FILE#$VAULT_ROOT/}"
    return 0
  fi
  local na="$GTD_DIR/next-actions.md"
  local wf="$GTD_DIR/waiting-for.md"
  local pj="$GTD_DIR/projects.md"
  local marker="<!-- imported-from-legacy-open-loops -->"
  if grep -qF "$marker" "$na" 2>/dev/null; then
    echo "  ⏭️  Already imported (marker found), skipping to stay idempotent"
    return 0
  fi
  echo "  📥 Importing from the old open loops.md (old file stays read-only)…"
  # awk: extract "- [ ] " lines after a given section header and before the next "## "
  extract() {
    awk -v sec="$1" '
      $0 ~ ("^## " sec) {grab=1; next}
      /^## / && grab {grab=0}
      grab && /^- \[ \] / {print}
    ' "$LEGACY_FILE"
  }
  {
    echo ""
    echo "## Needs light fields (legacy import $(cat "$VAULT_ROOT/.gtd_import_stamp" 2>/dev/null || echo "imported"))"
    echo "$marker"
    echo "> Imported from the legacy self list; run /gtd-clarify on each item to add Time / Energy / Constraint. Legacy @ groups are kept for compatibility only; migration is not required."
    extract "@自己"
  } >> "$na"
  { echo ""; echo "<!-- imported-from-legacy-open-loops -->"; extract "@等待"; } >> "$wf"
  { echo ""; echo "<!-- imported-from-legacy-open-loops -->"; extract "@项目"; } >> "$pj"
  local n_na n_wf n_pj
  n_na=$(extract "@自己" | wc -l | tr -d ' ')
  n_wf=$(extract "@等待" | wc -l | tr -d ' ')
  n_pj=$(extract "@项目" | wc -l | tr -d ' ')
  echo "  ✅ Import complete: self $n_na → next-actions / waiting $n_wf → waiting-for / projects $n_pj → projects"
}

# ════════════════════════════════════════════════════════
echo "GTD Skill · init"
echo "Vault: $VAULT_ROOT"

if [ "$STATUS_ONLY" -eq 1 ]; then
  selfcheck
  automation_selfcheck
  if [ "$INSTALL_CRON" -eq 1 ]; then
    cron_install_handoff
  fi
  echo ""
  echo "(--status mode, no files written)"
  exit 0
fi

mkdir -p "$GTD_DIR"
echo ""
echo "── Building memory/gtd/ eight core lists + product-ideas extension list (existing files skipped) ──"

seed "$GTD_DIR/inbox.md" <<'EOF'
# 📥 Inbox

> The single landing spot for GTD step one, Capture. **No judgment**: drop it in first; clarifying is left to /gtd-clarify.
> Anything that has your attention (actions, ideas, to-dos, reminders, open questions) goes here first. Your mind is for having ideas, not holding them.

## To clarify

EOF

seed "$GTD_DIR/next-actions.md" <<'EOF'
# ✅ Next Actions

> The action pool of clarified, single-step actions you can do right away. Engage filters a 3-5 item menu on the spot by context / time / energy / priority; you never face the whole list.
> Verbs must be concrete (confirm / send / call / write) — no vague verbs like "follow up / handle / research".
> Format: `- [ ] Concrete action · Time: 10 min · Energy: low energy · Constraint: needs computer / shopping / prep chain / person present · Project: [[projects#Project name|Project name]] (if part of a project) · Source: [[note]] · Date: YYYYMMDD`
> Legacy `@computer/@calls/@errands/@home/@agenda` groups are still supported; they are tool/setting constraints, no longer the main structure.

## @computer
> Legacy compatibility group: needing a computer / internet is a tool constraint, not a reason for Engage to recommend it first.

## @calls
> Legacy compatibility group: phone / voice is a channel constraint.

## @errands
> Legacy compatibility group: hard settings such as on-the-way errands / shopping / in-person tasks.

## @home
> Legacy compatibility group: things that need materials / equipment / surroundings at home.

## @agenda-[name]
> Legacy compatibility group: things to raise the next time you see or talk to someone (one subgroup per person, e.g. `### @agenda-Teacher-A`).

EOF

seed "$GTD_DIR/projects.md" <<'EOF'
# 🎯 Projects

> Any outcome that takes **more than one step** to complete. GTD hard rule: every project must have **at least one clear next action**, or it stalls.
> Format:
> ```
> ## [Project name]
> - Desired outcome: one sentence describing what "done" looks like
> - Next actions:
>   - [[next-actions#^block-id|Concrete next action]] (constraint/lens)
>   - [[waiting-for#^block-id|Waiting for someone to deliver something]] (waiting, optional)
> - Support material: [[reference#Entry name|Entry name]] / [[project doc]]
> - Source: [[note]] · Date: YYYYMMDD
> ```
> At least 1 next action, or the project is stalled. Several are fine, but only list physical actions that can move forward in parallel right now — not a full task tree.
>
> Close-the-loop rule: once the desired outcome is achieved, delete the whole project block; do not leave "Next actions: none".

EOF

seed "$GTD_DIR/waiting-for.md" <<'EOF'
# ⏳ Waiting For

> Things you delegated or are waiting on someone else for — not your next action, but they must be tracked so they don't vanish on your side.
> Scan this before any 1:1 or project meeting so nothing slips.
> Format: `- [ ] [Person] · what you're waiting for · Agreed: [content or deadline] · Source: [[note]] · Delegated: YYYYMMDD`

## Waiting

EOF

seed "$GTD_DIR/someday-maybe.md" <<'EOF'
# 💭 Someday / Maybe

> Not committed to yet, but you don't want to forget — projects you'd like to do, possible directions, interesting thoughts.
> **Not** an active list: nothing here is acted on now. Scan it at the monthly review and pull whatever has ripened into projects/next-actions.
> Format: `- [ ] Idea / possible project · trigger condition (when it becomes worth starting) · Source: [[note]] · Date: YYYYMMDD`

## Incubating

EOF

seed "$GTD_DIR/product-ideas.md" <<'EOF'
# Product Ideas / Product Work Intake

> Inputs that clearly belong to a product, feature, scenario, or opportunity space go here, keeping the original opportunity, assumptions, and evidence status.
> This file is not cold storage: product / requirements planning is core work, so by default every idea is also synced to `projects.md` / `next-actions.md` to enter the daily visible system.
> Only when the user explicitly says "store it, don't process it / capture only" is it left un-promoted.
> Teresa Torres' framing: keep the opportunity first and don't rush to a solution — but the GTD layer must still give a next validation action.
> Format: one subsection per idea; use `- [ ] Opportunity: ...` as the counted line, and include `GTD visibility`.

## Opportunity pool

EOF

seed "$GTD_DIR/calendar.md" <<'EOF'
# 📅 Calendar (hard landscape)

> **Only** things that matter on a specific day / at a specific time — meetings, appointments, deadlines, day-specific actions.
> Allen's hard rule: the calendar is sacred territory. **Do not** put ordinary to-dos here (those go in next-actions). Once clutter gets in, the calendar loses its trustworthiness.
>
> **One calendar**: when an external calendar provider is reachable, it is the hard landscape; engage/review read it directly, and complete event details can be written to it automatically (see `references/capability-map.md`). **This file is only a fallback when the external provider is unreachable** — record time-specific items "to add to the calendar manually", and **never keep a copy of the external calendar**. Reminder provider is deferred to v2.
> Fallback format: `- YYYY-MM-DD [HH:MM] · Item · Source: [[note]] · ⚠️ add to external calendar manually`

## Time-specific items (fallback · when the external calendar provider is unreachable)

EOF

seed "$GTD_DIR/reference.md" <<'EOF'
# 📚 Reference

> Non-actionable information you'll want to look up later — plus pointers to each project's support material.
> Note: **knowledge / idea** notes go through the ZK pipeline (fleeting-note → your daily-notes folder), not here; this file only holds
> look-up information tied directly to actions / projects (checklists, specs, contact details, links to project support material).
> For headings inside GTD files, use Obsidian heading links: `[[filename#Heading|Heading]]`; bare `[[Heading]]` is only for real standalone files.

## General reference

## Project support material

EOF

seed "$GTD_DIR/horizons.md" <<'EOF'
# 🔭 Horizons of Focus

> GTD's vertical focus: the horizontal five steps ensure "nothing slips"; the vertical horizons ensure "you're doing the right things".
> Most people are stuck firefighting between the runway and 10k and never look up — so they "efficiently do things they shouldn't be doing".
> At the end of each Weekly Review, rise to 30k+ and check whether projects still serve the higher horizons.

## 50,000 ft · Purpose & Principles
> Why do I exist? What are my core values and non-negotiables?
-

## 40,000 ft · Vision
> What does success look like 3–5 years from now?
-

## 30,000 ft · Goals & Objectives
> What specific goals do I want to achieve in 1–2 years?
-

## 20,000 ft · Areas of Focus & Accountabilities
> The roles / areas I'm continuously responsible for (work, health, family, finances, learning…), each maintained to some standard.
-

## 10,000 ft · Projects
> All current projects (= mirror of projects.md; check they match during review).
> → see [[projects]]

## Runway · Actions
> The current next actions list.
> → see [[next-actions]]

EOF

# The [[projects]]/[[next-actions]] links in horizons are same-directory file wikilinks that Obsidian can resolve;
# to point at a heading inside a file use [[filename#Heading|Heading]] to avoid creating a standalone file by mistake.

if [ "$IMPORT_LEGACY" -eq 1 ]; then
  echo ""
  echo "── Optional import (old open loops.md is read-only) ──"
  import_legacy
fi

if [ "$GTD_LEGACY_VAULT_INSTALL" -eq 1 ]; then
  echo ""
  echo "── Install/refresh Codex slash commands (global) ──"
  install_codex_prompts
else
  echo ""
  echo "── Plugin mode ──"
  echo "  Skipping legacy global slash prompt install; invoke LLM-GTD from the plugin entry point."
fi

selfcheck
automation_selfcheck
if [ "$INSTALL_CRON" -eq 1 ]; then
  cron_install_handoff
fi

echo ""
echo "── Readiness report ──"
echo "  Created $created file(s), skipped $skipped (already exist)."
echo "  Trusted system location: memory/gtd/"
if [ "$IMPORT_LEGACY" -eq 0 ]; then
  echo "  (Legacy data not imported. For a one-time import: bash gtd_init.sh --import-legacy)"
fi
echo ""
echo "  Next: run a capture — invoke the gtd-harness capture workflow (legacy installs: /gtd-capture)"
echo "  Dashboard: run scripts/gtd_status.sh (legacy installs: bash .cursor/skills/gtd-harness/scripts/gtd_status.sh)"
echo "  Automation cadence: see references/automation-profiles.md; install via gtd init --install-cron, which has the agent call the automation tool"
