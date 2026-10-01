#!/usr/bin/env bash
# gtd_init.sh — idempotently build the GTD trusted system (memory/gtd/ eight core lists) + adapter self-check + read-only automation cadence check
#
# Usage:
#   bash gtd_init.sh                  # REFUSES to create anything without --confirm-create (exit 3); prints where it would create the lists so the agent can ask the user first
#   bash gtd_init.sh --confirm-create # after the user has confirmed: idempotently create the eight core lists + self-check + read-only automation check (existing files are never overwritten)
#   bash gtd_init.sh --status         # self-check, read-only automation check, and readiness report only; writes no files, never requires --confirm-create
#   bash gtd_init.sh --install-cron   # explicitly request installing the GTD automation cadence; plain shell only prints an agent handoff — the gtd-init skill creates it via the platform automation tool
#   bash gtd_init.sh --confirm-create --with-bases
#                                     # also write starter Obsidian .base lens views (optional; nothing depends on them)
#
# Layout: inbox / calendar / horizons are files; next-actions, waiting-for, projects, someday-maybe and tickler
# are folders of one note per item, plus _done/, each with a README.md; general reference is a workspace-root
# reference/ folder. A memory/gtd/ that still holds LLM-GTD 1.x single-file lists is refused (exit 4).
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
AUTOMATIONS_DIR="${CODEX_HOME:-$HOME/.codex}/automations"
CODEX_HOME_DIR="${CODEX_HOME:-$HOME/.codex}"
CODEX_PROMPTS_DIR="$CODEX_HOME_DIR/prompts"
CODEX_PROMPT_TEMPLATES="$SKILL_DIR/templates/codex-prompts"
CODEX_PROMPT_FILES="gtd.md gtd-init.md gtd-capture.md gtd-clarify.md gtd-update.md gtd-organize.md gtd-engage.md gtd-review.md gtd-help.md"

STATUS_ONLY=0
INSTALL_CRON=0
CONFIRM_CREATE=0
WITH_BASES=0
while [ $# -gt 0 ]; do
  case "$1" in
    --status)        STATUS_ONLY=1 ;;
    --install-cron)  INSTALL_CRON=1 ;;
    --confirm-create) CONFIRM_CREATE=1 ;;
    --with-bases)    WITH_BASES=1 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
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

# 1.x single-file lists would be invisible to every command — refuse, with the way out.
gtd_refuse_single_file

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

# ── List contents ──
# Each list folder's README.md opens with that list's header (title + rules) — see
# references/list-definitions.md "List README files".

file_inbox() {
  cat <<'EOF'
# 📥 Inbox

> The single landing spot for GTD step one, Capture. **No judgment**: drop it in first; clarifying is left to /gtd-clarify.
> Anything that has your attention (actions, ideas, to-dos, reminders, open questions) goes here first. Your mind is for having ideas, not holding them.

## To clarify

EOF
}

header_next_actions() {
  cat <<'EOF'
# ✅ Next Actions

> The action pool of clarified, single-step actions you can do right away. Engage filters a 3-5 item menu on the spot by context / time / energy / priority; you never face the whole list.
> Verbs must be concrete (confirm / send / call / write) — no vague verbs like "follow up / handle / research".
> Where you can do it (computer, phone, errands, home, with a person present…) is the note's `context`, a constraint — not a reason for Engage to recommend it first.
EOF
}

header_projects() {
  cat <<'EOF'
# 🎯 Projects

> Any outcome that takes **more than one step** to complete. GTD hard rule: every project must have **at least one clear next action, waiting-for item or tickle**, or it stalls (a tickle means on hold on purpose until its date).
> Several next actions are fine, but only physical actions that can move forward in parallel right now — not a full task tree.
>
> Close-the-loop rule: once the desired outcome is achieved, draft a short after-action review and move the project to the done record; do not leave "Next actions: none".
EOF
}

header_waiting_for() {
  cat <<'EOF'
# ⏳ Waiting For

> Things you delegated or are waiting on someone else for — not your next action, but they must be tracked so they don't vanish on your side.
> Scan this before any 1:1 or project meeting so nothing slips.
EOF
}

header_someday_maybe() {
  cat <<'EOF'
# 💭 Someday / Maybe

> Not committed to yet, but you don't want to forget — projects you'd like to do, possible directions, interesting thoughts.
> **Not** an active list: nothing here is acted on now. Scan it at the monthly review and pull whatever has ripened into projects/next-actions.
EOF
}

file_calendar() {
  cat <<'EOF'
# 📅 Calendar (hard landscape)

> **Only** things that matter on a specific day / at a specific time — meetings, appointments, deadlines, day-specific actions.
> Allen's hard rule: the calendar is sacred territory. **Do not** put ordinary to-dos here (those go in next-actions). Once clutter gets in, the calendar loses its trustworthiness.
>
> **One calendar**: when an external calendar provider is reachable, it is the hard landscape; engage/review read it directly, and complete event details can be written to it automatically (see `references/capability-map.md`). **This file is only a fallback when the external provider is unreachable** — record time-specific items "to add to the calendar manually", and **never keep a copy of the external calendar**. Reminder provider is deferred to v2.
> Fallback format: `- YYYY-MM-DD [HH:MM] · Item · Source: [[note]] · ⚠️ add to external calendar manually`

## Time-specific items (fallback · when the external calendar provider is unreachable)

EOF
}

file_horizons() {
  cat <<'EOF'
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
> All current projects (= mirror of the projects/ folder; check they match during review).
> → see [[projects/README|projects]]

## Runway · Actions
> The current next actions list.
> → see [[next-actions/README|next-actions]]

EOF
}

# ── README.md for each list folder ──
# Order (list-definitions.md "List README files"): header → Note format → Views (only when .base files exist).

# note_format_section TEMPLATE INTRO — the per-item note shape, straight from templates/<TEMPLATE>
note_format_section() {
  local tpl="$SKILL_DIR/templates/$1"
  echo ""
  echo "## Note format"
  echo ""
  echo "$2"
  echo ""
  if [ -f "$tpl" ]; then
    echo '```markdown'
    cat "$tpl"
    echo '```'
  else
    echo "(See the skill's templates/$1.)"
  fi
}

views_section() {
  [ "$WITH_BASES" -eq 1 ] || [ -f "$GTD_DIR/$1.base" ] || return 0
  printf '\n## Views\n\n%s\n' "$2"
}

NOTE_RULES='One note per item: `<list>/<Short verb-first title>.md`, filesystem-safe (no `: / \ ? * " < > |`), with `(2)`, `(3)`, … added on a collision. `README.md` is reserved and is never an item. The properties below are filled by clarify and repaired by organize — you never have to tag anything, and a note with no properties is still valid.'

readme_next_actions() {
  header_next_actions
  note_format_section next-action-note.md "${NOTE_RULES//<list>/next-actions}"
  views_section next-actions '- [[next-actions.base]] — lens views: 15 min or less · Low energy · Errands. Each project README embeds its "For this project" view.'
}

readme_waiting_for() {
  header_waiting_for
  note_format_section waiting-for-note.md "${NOTE_RULES//<list>/waiting-for}"
}

readme_projects() {
  header_projects
  note_format_section project-note.md 'Each project is a folder, `projects/<Project name>/README.md`, not a single note: the README holds the outcome, decisions and an embedded next-actions view; plan docs, design notes and research for the project live as ordinary files beside it, linked with a bare `[[filename]]`. Actions point at the project with `project: "[[projects/<Project name>/README|<Project name>]]"` — the README never lists them by hand. When the outcome is achieved: after-action review, then the whole folder moves to `_done/<Project name>/`.'
}

header_tickler() {
  cat <<'EOF'
# 🗂️ Tickler

> Committed things you can't (or don't want to) act on until a date — Allen's tickler. One note per tickle, dated with `tickle:` for when it becomes actionable.
> **Not** appointments (those go to the calendar), **not** things someone owes you (waiting-for), **not** uncommitted maybes (someday-maybe).
> A project linked from a tickle is on hold on purpose, not stalled; it stays in `projects/`.
> **Always local**: never exported to the external calendar, and never touched by organize's calendar-fallback reconcile.
> When the date arrives, organize moves a concrete project tickle into `next-actions/` (dropping `tickle`, adding time / energy / context) and queues anything else in the inbox for clarify, as a line linking the note. Engage lists due tickles first.
EOF
}

readme_tickler() {
  header_tickler
  note_format_section tickler-note.md "${NOTE_RULES//<list>/tickler}"
  views_section tickler '- [[tickler.base]] — Upcoming (by date). Each project README embeds its "For this project" view.'
}

readme_someday_maybe() {
  header_someday_maybe
  note_format_section someday-maybe-note.md "${NOTE_RULES//<list>/someday-maybe}"
}

readme_done() {
  cat <<'EOF'
# 🏁 Done

> A record of finished commitments — completed next actions, received waiting-for items, finished projects, and cancelled project steps — each with its outcome: what was done, what problems came up and how they were solved.
> **Not a list you act from.** Engage never reads it, the dashboard never counts it as open, and organize never checks it for stalled or orphaned items. It feeds the Weekly Review's "Done since last review" and each project's after-action review.
> A finished action or waiting-for item is a flat note here, keeping its original filename and properties and gaining `completed`, `result` (done | cancelled) and `list` (the list it came from). A finished project moves here as its whole folder, `_done/<Project name>/`: its README gains the same three properties plus the after-action review, and whatever support material you chose to keep stays beside it. A cancelled *standalone* action, or a dropped someday item, is simply deleted — only project-linked work is worth a record.
> Kept indefinitely by default; trimming is off unless enabled in `memory/gtd/personalized.md`.

## Note format

```markdown
---
# …the note's original properties (id, time, energy, context, project, source, created)…
completed: YYYY-MM-DD
result: done          # done | cancelled
list: next-actions    # the list it came from
---
The original body, unchanged.

## Outcome
- Done: what was actually done.
- Problems and fixes: what got in the way and how it was solved (or "none noted").
- Links: [[…]] or file paths, commits, emails
```
EOF
  views_section done '- [[done.base]] — Done this week.'
}

readme_reference() {
  cat <<'EOF'
# 📚 Reference

> Non-actionable information you'll want to look up later: checklists, specs, contact details, how-tos and insights worth keeping.
> One plain note per topic, `reference/<Title>.md`, found by title or full-text search. This folder sits outside `memory/gtd/` on purpose: GTD files knowledge here, but it is not GTD state.
> Project-specific support material lives in that project's own folder (`memory/gtd/projects/<Project name>/`) instead; when a project closes, you decide whether it's worth keeping.
> `memory/gtd/personalized.md` can point this hand-off somewhere else instead (a separate knowledge system) if you run one.
EOF
  note_format_section reference-note.md 'No id, type or pipeline scaffolding — just where it came from and when.'
}

# ── Optional Obsidian Bases (lens views only — never an "all actions" view) ──
# Bases syntax learned in Phase 0: negation is `!`, `order:` is the full visible-column list (file.name must be
# listed), and file.inFolder() is recursive. _done/ is a sibling of the list folders, so the lists need no exclusion.

base_next_actions() {
  cat <<'EOF'
# LLM-GTD lens views over the next-actions pool. Optional Obsidian extra: every GTD command works without it.
# Lens views only — there is deliberately no unfiltered "all actions" view (never face the whole list).
# "For this project" is meant to be embedded in a project README: ![[next-actions.base#For this project]]
filters:
  and:
    - file.inFolder("memory/gtd/next-actions")
    - file.basename != "README"
views:
  - type: table
    name: 15 min or less
    filters:
      and:
        - time <= 15
    order:
      - file.name
      - time
      - energy
      - context
      - project
  - type: table
    name: Low energy
    filters:
      and:
        - energy == "low"
    order:
      - file.name
      - time
      - context
      - project
  - type: table
    name: Errands
    filters:
      and:
        - context.contains("errands")
    order:
      - file.name
      - time
      - energy
      - project
  - type: table
    name: For this project
    filters:
      and:
        - file.hasLink(this.file)
    order:
      - file.name
      - time
      - energy
      - context
EOF
}

base_done() {
  cat <<'EOF'
# LLM-GTD done record. Optional Obsidian extra: every GTD command works without it.
# A done record is any note in _done/ with a completed date: flat done notes, and each finished
# project's README in _done/<Project name>/ (its support docs have no completed, so they stay out).
filters:
  and:
    - file.inFolder("memory/gtd/_done")
    - file.hasProperty("completed")
views:
  - type: table
    name: Done this week
    filters:
      and:
        - completed >= today() - "7d"
    order:
      - file.name
      - completed
      - result
      - list
      - project
    sort:
      - property: completed
        direction: DESC
EOF
}

base_tickler() {
  cat <<'EOF'
# LLM-GTD tickler views. Optional Obsidian extra: every GTD command works without it.
# "For this project" is meant to be embedded in a project README: ![[tickler.base#For this project]]
filters:
  and:
    - file.inFolder("memory/gtd/tickler")
    - file.basename != "README"
views:
  - type: table
    name: Upcoming
    order:
      - file.name
      - tickle
      - project
    sort:
      - property: tickle
        direction: ASC
  - type: table
    name: For this project
    filters:
      and:
        - file.hasLink(this.file)
    order:
      - file.name
      - tickle
EOF
}

build_lists() {
  local l
  for l in $GTD_NOTE_LISTS _done; do
    mkdir -p "$GTD_DIR/$l"
  done
  mkdir -p "$VAULT_ROOT/reference"
  seed "$GTD_DIR/inbox.md" < <(file_inbox)
  seed "$GTD_DIR/next-actions/README.md" < <(readme_next_actions)
  seed "$GTD_DIR/projects/README.md" < <(readme_projects)
  seed "$GTD_DIR/waiting-for/README.md" < <(readme_waiting_for)
  seed "$GTD_DIR/someday-maybe/README.md" < <(readme_someday_maybe)
  seed "$GTD_DIR/tickler/README.md" < <(readme_tickler)
  seed "$GTD_DIR/_done/README.md" < <(readme_done)
  seed "$GTD_DIR/calendar.md" < <(file_calendar)
  seed "$VAULT_ROOT/reference/README.md" < <(readme_reference)
  seed "$GTD_DIR/horizons.md" < <(file_horizons)
  if [ "$WITH_BASES" -eq 1 ]; then
    seed "$GTD_DIR/next-actions.base" < <(base_next_actions)
    seed "$GTD_DIR/done.base" < <(base_done)
    seed "$GTD_DIR/tickler.base" < <(base_tickler)
  fi
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
echo "── Building memory/gtd/: inbox, calendar, horizons + 5 list folders (incl. tickler) + _done/, and reference/ (existing files skipped) ──"
build_lists

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
echo "  Trusted system location: memory/gtd/; general reference: reference/"
if [ "$WITH_BASES" -eq 0 ]; then
  echo "  (No Obsidian lens views written. Optional: bash gtd_init.sh --confirm-create --with-bases)"
fi
echo ""
echo "  Next: run a capture — invoke the gtd-harness capture workflow (legacy installs: /gtd-capture)"
echo "  Dashboard: run scripts/gtd_status.sh (legacy installs: bash .cursor/skills/gtd-harness/scripts/gtd_status.sh)"
echo "  Automation cadence: see references/automation-profiles.md; install via gtd init --install-cron, which has the agent call the automation tool"
