---
name: gtd-init
description: GTD skill scenario command · Set up / self-check the trusted system. Idempotently creates the memory/gtd/ eight core lists + product-ideas extension list + adapter-layer self-check + read-only check / explicit install of the automation cadence + optional import of old open loops. First-run entry point.
parent: gtd-harness
model-tier: balanced
example: "Set up my GTD trusted system"
---


# GTD · init (set up / self-check)

**Perspective**: David Allen. GTD's first step is **setting out the boxes of the trusted system** — a system that can't initialize itself makes the user build it by hand, which violates "lower the barrier to entry".

## Loading and boundaries

- Setup only or `--status`: just run the script; no extra reference needed.
- `--install-cron` / initializing the automation cadence: read `references/automation-profiles.md` first.
- Questions about the adapter layer or calendar provider: read `references/capability-map.md`.
- Automation boundary: read-only check by default; create / update automation only when the user explicitly asks.

## One inbox per human (hard rule)

GTD only works with exactly one inbox per person. The canonical GTD folder is whatever `gtd_init.sh --status` prints as `Vault:` — the configured GTD folder (set via the `LLM_GTD_ROOT` environment variable; see the install docs for how to set it once so every project resolves to the same folder). If the user has told you the location directly (for example in a global instructions file), that takes precedence over asking again.

- **Never run init (with or without flags other than `--status`) automatically.** Not because a command's self-check found `memory/gtd/` missing, not because the current project has no GTD folder, and not as a side effect of capture / clarify / update / engage / review.
- **Always ask the user first**, and say which folder would be created. If the configured/canonical folder above exists, do not create another one: use it, whatever the current project is.
- Treat a missing project-relative `memory/gtd/` as "resolve to the configured folder", not "not set up".
- Only bootstrap a new GTD folder after the user explicitly confirms it, and only when the configured folder does not exist.

## When to run
- First time enabling the GTD skill (`memory/gtd/` doesn't exist).
- Any command's self-check reports missing lists.
- To confirm the three-platform adapter layer is wired up (`--status`).
- To confirm whether the GTD automation cadence (Weekly Review / Monthly Reflect / Daily Engage) is installed.
- The user explicitly asks to install / initialize GTD cron / automation (`--install-cron`).

## Workflow

0. **Ask before bootstrapping (mandatory, every time)**:
   1. Ask: "Is GTD already set up somewhere (an existing inbox / `memory/gtd/`)?" If yes, get the path, use it, and stop — do not run init.
   2. If not, work out the location the script would create (run `bash <this-skill>/scripts/gtd_init.sh --status`, which prints `Vault:` and writes nothing) and ask the user to confirm that exact folder, or give a different one.
   3. Only after they confirm, run step 1 with `--confirm-create`. Without that flag the script refuses and exits 3.

1. **Run the init script** (idempotent, non-destructive; existing lists are skipped, never overwritten) — only after step 0:
   ```
   bash <this-skill>/scripts/gtd_init.sh --confirm-create
   ```
   It creates the full set of `memory/gtd/` eight core lists (including the next-actions action pool compatibility skeleton and the Horizons template) plus the product-ideas extension list, self-checks the adapter layer, and does a read-only check of the automation cadence install status.

   **Per-item layout (opt-in)** — only when the user asks for one note per item (for example to filter by time / energy / context in Obsidian):
   ```
   bash <this-skill>/scripts/gtd_init.sh --confirm-create --layout notes [--with-bases]
   ```
   Creates `inbox.md`, `calendar.md` and `horizons.md` as files; `next-actions/`, `waiting-for/`, `projects/`, `someday-maybe/`, `product-ideas/`, `tickler/` (per-item only: committed work dated for when it becomes actionable) and `_done/` as folders, each with a `README.md` holding that list's rules and note format; and a `reference/` folder at the workspace root for general reference. `--with-bases` adds starter Obsidian lens views (`next-actions.base`, `done.base`, `tickler.base`) — optional, nothing depends on them. Once created, later runs detect the layout by themselves; no flag needed.
   - **Init never switches layouts.** If the folder already holds single-file lists (or per-item folders, for `--layout files`), the script refuses with exit 4 so no items become invisible. Switching an existing system needs the migration script from LLM-GTD 1.17.x (`gtd_migrate_to_notes.sh`, dry run first) — tell the user that, don't work around it.

2. **Self-check only, no file writes**: `bash …/scripts/gtd_init.sh --status` (also prints the live layout, and warns if both layouts are present)

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
- [ ] Eight core lists + product-ideas extension list all present (`bash …/scripts/gtd_status.sh` produces a dashboard); in the per-item layout, every list folder (including `tickler/`) and `_done/` has its `README.md`
- [ ] Per-item layout only created when the user asked for it; an existing system in the other layout was left alone (exit 4) and pointed at the migration
- [ ] Re-running only skips, never overwrites (idempotent)
- [ ] `--status` gives a read-only report of Weekly Review / Monthly Reflect / Daily Engage install status
- [ ] Automation created or modified only when the user explicitly requests `--install-cron` / initializing cron
- [ ] In Codex, created / updated via `automation_update`, no hand-written automation files
- [ ] If imported: the old `open loops.md` is byte-for-byte unchanged (compare `md5` before and after)
- [ ] If the self-check reports "source of truth / entry point missing" → prompt to confirm the skill install path or that the plugin entry point is reachable
