# Changelog

All notable changes.

## v1.16.0 — One note per item (opt-in), done record, after-action reviews
**Opt-in per-item layout.** Next actions, waiting-for, projects, someday/maybe,
and product ideas can each be a folder of one note per item, with the same
fields as YAML properties, so Obsidian (Bases, or plain property search) can
filter them by time, energy, and context. Each project is a folder holding its
README and support material; general reference moves to a `reference/` folder
at the workspace root. The inbox, calendar, and horizons stay single files, so
capture doesn't change. Single-file stays the default; every command detects
the layout and works in both. Set up fresh with
`gtd_init.sh --confirm-create --layout notes [--with-bases]`.

**Migration.** `gtd_migrate_to_notes.sh` moves an existing single-file system
over. It's a dry run by default, printing every note, README, and link rewrite.
`--apply` needs a clean git tree, never overwrites, keeps the old lists in
`memory/gtd/_migrated/`, rewrites links to list items across the workspace
(never inside code), and refuses if any list's item count would change.

**Behavior change, both layouts: finished work is recorded, not deleted.** A
finished next action or received waiting-for item moves to a done record
(`done.md`, or `_done/` per-item) with a short outcome: what was done, and any
problem and how it was solved. Update writes the outcome from the session, or
asks one optional question for project work or anything 30+ minutes; quick
standalone actions are never asked. A finished project gets a short
after-action review first, with reusable how-tos offered for filing to
reference, all on one confirmation. The Weekly Review prep pack gains "Done
since last review". Nothing that counts or offers open work reads the done
record. This replaces the old "delete, no archive" rule.

**Scripts.** New read-only `gtd_list.sh` (one line per item from either
layout, with lens filters, and `done --since/--project/--problems`) and
`gtd_check.sh` (organize's per-item hygiene findings). `gtd_status.sh` and
`gtd_review_prep.sh` read both layouts.

New evals E16-E23. The static gate gained per-item init, read-path,
done-record, and migration fixtures.

## v1.15.1 — Knowledge defaults to reference.md, not a ZK pipeline
Every place the skill said non-actionable knowledge/insight material gets "handed
off to the ZK pipeline / fleeting-note" now says it files to `reference.md`
instead: `list-definitions.md`, `capture`, `clarify`, the router `SKILL.md`,
`natural-planning-model.md`, `clarify-decision-tree.md`, `evals.md` (E02),
`templates/session-close-template.md`, `gtd_init.sh`'s written `reference.md`
header, all three platforms' command files, the Codex orchestrator, the Cursor
skill rules, and both READMEs. Still overridable: point the hand-off at a
separate knowledge system (a Zettelkasten or otherwise) via `personalized.md`,
the same override pattern already used for model-tier and the calendar rule.
The plugin never assumed such a system existed for everyone; `reference.md`
already existed for exactly this, so it's now the honest default.

## v1.15.0 — /gtd-help + per-command model guidance
New read-only command `gtd-help`: every command's description, when to run it,
and an example, sourced from each sub-skill's own frontmatter/body (via the
new `scripts/gtd_help.sh`, never hand-written); the day-to-day rhythm; one
"right now" suggestion from `gtd_status.sh`; and where things live.
`/gtd-help <command>` gives one command's detail; `/gtd-help lists` explains
list boundaries.

Every sub-skill's frontmatter now carries `model-tier: fast | balanced |
strongest` instead of a hard-coded model name — `references/model-guidance.md`
is the only place actual Claude model names appear, mapped to tiers, so a new
model family means editing one file. Every command compares the session's
model against its tier before working: below tier, says so once and asks to
continue or switch (capture is the exception — it always writes to the inbox
first, then reports it skipped auto-clarify); above tier, at most one trailing
tip, never an interruption; once per session. `personalized.md` can override
the tier mapping or turn the check off.

"Help / what can this do / which command should I use" routes to `help/SKILL.md`
before the empty-input mind-sweep rule, so a genuine help request is never
captured as an inbox item.

New evals E24-E28. `gtd_eval_check.sh` gained three new guards: every
sub-skill must appear in `gtd_help.sh`'s output, carry a valid `model-tier`,
and have a command file on all three platforms (skipped gracefully when run
from the synced plugin copy, which has no sibling command directories of its
own); and no Claude model name may appear anywhere in the skill except
`references/model-guidance.md`. Both of the latter two caught real issues
during development — a model-name leak in the eval fixture text and the
checker's own regex matching itself — fixed by rewriting the affected evals
to use tier-relative language and excluding the checker script from its own
scan, the same way the existing description-wording check already excludes
itself.

## v1.14.1 — Calendar checks read event availability, not just title/length
`clarify`, `engage`, and `review` now read each calendar event's availability
field (free/busy, "Show as" / transparency) before treating it as blocking
time. An event marked free never blocks time, whatever its length or title;
an event marked busy, or with no availability field, counts as a conflict.
The rule lives once in `capability-map.md`'s conflict and capacity judgment
and is pointed to from all three call sites, instead of being a local,
per-vault rule. New eval E15-calendar-free. This was previously a local
override in `personalized.md`; that override is removed now that the general
skill covers it.

## v1.14 — Init no longer bootstraps automatically
GTD needs exactly one inbox per person. `gtd_init.sh` now refuses to create
files without an explicit `--confirm-create` flag (bare `--status` stays
read-only and unchanged); the `init` skill's workflow, the `/gtd` router, the
Codex prompts and orchestrator, and `capability-map.md` all ask the user
whether GTD is already set up somewhere else before ever bootstrapping a new
`memory/gtd/`, instead of silently creating one whenever a command's
self-check found the folder missing in the current project. Scripts also
support `LLM_GTD_ROOT` as a persistent, cross-project canonical location —
set it once in your shell profile so every project resolves to the same GTD
folder instead of risking a second inbox in some other project's own
`memory/gtd/`; see the README's "Using one canonical GTD folder across every
project" section.

## v1.13 — English translation
All skill prompts, slash commands, Codex prompts, templates, and script output are
now in English, using David Allen's GTD terminology. Scripts parse the English
labels (`- Next actions:`, `- [ ] Opportunity:`, `- GTD visibility:`); vaults with
Chinese-format `memory/gtd/` files need those labels updated.

## v1.12 — Update command for reported reality
Added `gtd-update` for progress reports and corrections: completed next actions,
waiting-for replies, project facts, calendar changes, cancellations, and minimal
state edits. The `/gtd` router now treats "done / confirmed / replied / changed"
wording as an update instead of recapturing it as a new inbox item.

## v1.11 — Multiple current next actions per project
Projects can now list multiple current next-action / waiting-for block links
when the actions can proceed in parallel. Stalled-project detection now requires
a concrete `next-actions` or `waiting-for` block link, so empty headings and
generic "see next-actions" pointers no longer count as coverage.

## v1.10 — Calendar-provider auto-write
Complete schedule items now write directly to an available calendar provider
without per-event confirmation. Missing date/time/title fields are clarified
first; unavailable or failed provider writes fall back to `memory/gtd/calendar.md`
and are never reported as successful.

## v1.9 — Codex plugin package
Added a repo-scoped Codex plugin package under `plugins/llm-gtd/` plus
`.agents/plugins/marketplace.json`, generated from `src/skill/` by
`scripts/sync_codex_plugin.sh`. GTD scripts now support `LLM_GTD_ROOT`, legacy
`.cursor` installs, and Codex plugin mode where the current workspace is the
state root.

## v1.8 — Init installs Codex slash prompts
`gtd_init.sh` now installs or refreshes `~/.codex/prompts/gtd*.md` from bundled templates,
so running init alone can restore the Codex `/gtd` command set.

## v1.7 — Obsidian heading links for internal GTD references
Internal references to headings inside `memory/gtd/` now use `[[file#heading|heading]]`
to avoid accidentally creating standalone Obsidian files.

## v1.6 — Weekly review prep package
Weekly review now starts with an AI prep pass. Added read-only `gtd_review_prep.sh`
and optional local notification helper; updated review flow and snapshot template.

## v1.5 — Project auto-closure
Completed project blocks (outcome met, no live next action) are deleted, not archived.
Organize/review check "is it done?" before drafting a next action.

## v1.4 — Organize as AI structural hygiene
Mechanical bookkeeping (orphans / stalled / contexts / dead checkboxes) runs silently;
only genuine judgment calls (uncraftable stalled, kill?, someday promotion) are batched to you.
Auto-runs before engage and inside review.

## v1.3 — Capture auto-clarifies (AI-native)
Single captures are clarified and filed immediately (act-then-surface, one-line report, correct in one sentence).
Bulk / mind-sweep is captured first, then batch-clarified. Off-switch: "capture only".

## v1.2 — Codex slash commands + three-platform triggers
Global `~/.codex/prompts/gtd*.md` (vault-aware fail-soft), AGENTS.md routing,
plus Claude Code commands and Cursor keyword rules. One source, one `memory/gtd/` state.

## v1.1 — Calendar reuse (provider read + confirmed write)
An available calendar provider becomes the single hard landscape; `calendar.md` is fallback only.
Writes are drafted, confirmed, and only claimed done on tool success — fail-closed.

## v1.0 — Initial
Four-layer harness: `memory/gtd/` eight lists, six-command skill package, three-platform adapter,
weekly review cadence. GTD-native, context-grouped next actions, self-initializing `init`.
