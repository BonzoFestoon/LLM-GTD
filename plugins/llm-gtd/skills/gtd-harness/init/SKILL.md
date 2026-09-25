---
name: gtd-init
description: GTD skill scenario command · Set up / self-check the trusted system. Idempotently creates the memory/gtd/ eight core lists + product-ideas extension list + adapter-layer self-check + read-only check / explicit install of the automation cadence + optional import of old open loops. First-run entry point.
parent: gtd-harness
---


# GTD · init (set up / self-check)

**Perspective**: David Allen. GTD's first step is **setting out the boxes of the trusted system** — a system that can't initialize itself makes the user build it by hand, which violates "lower the barrier to entry".

## Loading and boundaries

- Setup only or `--status`: just run the script; no extra reference needed.
- `--install-cron` / initializing the automation cadence: read `references/automation-profiles.md` first.
- Questions about the adapter layer or calendar provider: read `references/capability-map.md`.
- Automation boundary: read-only check by default; create / update automation only when the user explicitly asks.

## When to run
- First time enabling the GTD skill (`memory/gtd/` doesn't exist).
- Any command's self-check reports missing lists.
- To confirm the three-platform adapter layer is wired up (`--status`).
- To confirm whether the GTD automation cadence (Weekly Review / Monthly Reflect / Daily Engage) is installed.
- The user explicitly asks to install / initialize GTD cron / automation (`--install-cron`).

## Workflow

1. **Run the init script** (idempotent, non-destructive; existing lists are skipped, never overwritten):
   ```
   bash <this-skill>/scripts/gtd_init.sh
   ```
   It creates the full set of `memory/gtd/` eight core lists (including the next-actions action pool compatibility skeleton and the Horizons template) plus the product-ideas extension list, self-checks the adapter layer, and does a read-only check of the automation cadence install status.

2. **Self-check only, no file writes**: `bash …/scripts/gtd_init.sh --status`

   `--status` checks:
   - Whether the GTD skill source of truth and the three platform entry points are reachable.
   - Whether Weekly Review / Monthly Reflect / Daily Engage already have a local automation.
   - It only reports status; it never creates, pauses, or modifies cron.

3. **Automation cadence install** (only when the user explicitly asks, e.g. `/gtd init --install-cron` / "initialize GTD cron"):
   - Read `references/automation-profiles.md` first.
   - Check existing `$CODEX_HOME/automations/*/automation.toml` first; prefer updating existing automations over creating duplicates.
   - In Codex you must call `automation_update` to create / update; don't hand-write `~/.codex/automations` from the shell.
   - Default install / update: Weekly Review, Monthly Reflect, Daily Engage + Approval Radar.
   - For Daily Engage, if a morning or evening entry already exists locally, reuse and update it; if neither exists, create the morning entry by default. If the user explicitly chose evening, create / update the evening entry.
   - Install Session Clarify only when the user explicitly wants Codex sessions scanned automatically.
   - After installing, run `bash …/scripts/gtd_init.sh --status` to verify.

4. **Optional one-time import of legacy data** (not run by default; the old `open loops.md` is read-only and never modified):
   ```
   bash <this-skill>/scripts/gtd_init.sh --import-legacy
   ```
   Maps the old self list → next-actions, waiting list → waiting-for, projects list → projects, and adds a marker to prevent duplicate imports. Imported items land in the "Needs light fields" section; clarify each one to add Time / Energy / Constraint.

5. **Read the readiness report**: confirm the created / skipped counts, adapter self-check results, and automation cadence status, then guide the user to run their first `capture`.

## Quality check
- [ ] Eight core lists + product-ideas extension list all present (`bash …/scripts/gtd_status.sh` produces a dashboard)
- [ ] Re-running only skips, never overwrites (idempotent)
- [ ] `--status` gives a read-only report of Weekly Review / Monthly Reflect / Daily Engage install status
- [ ] Automation created or modified only when the user explicitly requests `--install-cron` / initializing cron
- [ ] In Codex, created / updated via `automation_update`, no hand-written automation files
- [ ] If imported: the old `open loops.md` is byte-for-byte unchanged (compare `md5` before and after)
- [ ] If the self-check reports "source of truth / entry point missing" → prompt to confirm the skill install path or that the plugin entry point is reachable
