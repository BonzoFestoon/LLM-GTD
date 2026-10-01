# Changelog

All notable changes.

## v2.0.1 — Remove Chinese-language content
Deleted `README.zh-CN.md` and `docs/demo.zh-CN.md`, dropped the language-switch links, and removed the remaining Chinese strings from the evolution log. No behaviour change.

## v2.0.0 — One note per item only; no product-ideas list
**Breaking.** Two things LLM-GTD 1.x had are gone.

**The single-file layout.** Lists are always folders of one note per item
(`next-actions/`, `waiting-for/`, `projects/`, `someday-maybe/`, `tickler/`,
`_done/`), with general reference in a workspace-root `reference/` folder; the
inbox, calendar fallback and horizons stay single files. `gtd_init.sh` always
builds this layout, and its `--layout` and `--import-legacy` flags are gone.
Every script refuses a `memory/gtd/` that still holds 1.x single-file lists
(`next-actions.md`, `projects.md`, …) with exit 4 and a pointer to the
migration, instead of silently missing their items. **Upgrading from
single-file lists:** install 1.17.x, run its `scripts/gtd_migrate_to_notes.sh`
(dry run, then `--apply` on a clean git tree), then upgrade. The migration
script itself is not part of 2.0.0.

**The product-ideas list.** It was an extension, not one of Allen's lists. A
product or feature idea is now ordinary input: clarify files it like anything
else (committed to building it → a project, with the opportunity and
assumptions in its README, plus a next action; not committed → someday-maybe;
only knowledge → reference). The dashboard line, the review-prep audit and
intake sections, and the evidence / promotion / GTD-visibility fields are gone.
An existing `product-ideas/` folder is simply ignored; clarify its notes into
projects or someday-maybe, then delete it.

**Smaller changes.** The next-actions README no longer carries the legacy
`@computer/@calls/…` groups (context is a property). `templates/done-log.md`,
`templates/project-template.md` and `templates/product-idea-note.md` are
removed. Evals: E05 is now E05-feature-idea, E23 (migration) is retired, and
new E36 covers the single-file refusal; the static gate checks that refusal in
every script and fails on any remaining product-ideas mention.

## v1.17.1 — Standalone repository
The plugin's author, homepage, repository and install commands now point at
`BonzoFestoon/LLM-GTD` instead of the upstream `mikonos/LLM-GTD`, in both
plugin manifests, the marketplace file, both READMEs and the issue-template
link. This fork no longer tracks upstream. No skill behavior changes. The
original MIT copyright notice is unchanged.

## v1.17.0 — Tickler for committed work that waits on a date (per-item layout)
**New list: `memory/gtd/tickler/`.** Allen's tickler, one note per tickle, dated
with `tickle:` for when it becomes actionable. It's for committed work that
can't start until a date, which is neither someday/maybe (not committed) nor
waiting-for (nobody owes it). Clarify gains the branch "committed, but can't
act until a date → tickler"; a project that can't start yet keeps its folder
and gets a tickle.

**Stalled, defined once.** A project is in play when an open next action,
waiting-for item, or tickle links to it; `list-definitions.md` now defines
"stalled" explicitly and every other statement points to it. A tickled project
is on hold on purpose: `gtd_check.sh`, the dashboard, and the review prep never
call it stalled, organize never drafts a next action for it, and it isn't
closed while a tickle still links it.

**When the date arrives.** Organize moves a concrete project tickle into
`next-actions/` and queues anything else in the inbox as a line linking the
note (the note stays, so nothing is lost; clarify works on the note). It never
queues the same tickle twice. Engage lists what came due first, whatever the
calendar's reachability. The Weekly Review prep pack gains a Tickler section
(due now, next 14 days, projects on hold), and Get Current asks once whether
each on-hold date still holds; scheduled reviews only report.

**Always local.** The tickler is never written to the external calendar and is
never touched by organize's `calendar.md` reconcile; `calendar.md`'s contract is
unchanged. Organize flags a tickle whose day the calendar shows as blocked
(all-day or whole-workday busy) and suggests another date, never re-dating it.

**Scripts.** `gtd_list.sh tickler [--due | --within N] [--project P]`;
`gtd_check.sh` gives tickles the actions' project-link checks and adds
`tickler-due` (with "queued in inbox") and `tickler-date`; `gtd_status.sh` shows
`Tickler: N (M due)`; init creates `tickler/README.md` and, with `--with-bases`,
`tickler.base`; new `templates/tickler-note.md`, and project READMEs embed the
project's tickles.

**Per-item only.** The single-file layout is unchanged and has no tickler.

New evals E29-E35; the static gate gained a tickler fixture. The gate's
migration E23 header check now compares bytes: under a UTF-8 locale, Git Bash's
grep 3.0 missed lines containing 4-byte emoji.

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
labels (`- Next actions:`, `- [ ] Opportunity:`, `- GTD visibility:`); vaults using the
pre-1.13 label format need those labels updated.

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
