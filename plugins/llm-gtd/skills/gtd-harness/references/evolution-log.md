# gtd-harness Evolution Log

## v1.0 — First release
David Allen's GTD × Karpathy's "Agent = LLM + harness". A four-layer harness:
- **State layer**: `memory/gtd/` eight lists (GTD-native, next-actions action pool + Engage lens filtering)
- **Logic layer**: seven SKILL.md commands (platform-neutral, no tool names)
- **Adapter layer**: thin entry points for three platforms + `capability-map.md`
- **Cadence layer**: the Weekly Review command (cron optional, off by default)

Design principles:
- Build the system independently from GTD first principles; if the workspace already has another to-do system, this package coexists independently, with an optional one-time `init --import-legacy`.
- next-actions action pool + Engage lens filtering (@computer/@calls/@errands/@home/@agenda-person), returning to the true GTD model.
- `init` as the first-run / reinstall entry point (idempotent self-check) — a harness must be able to initialize itself.
- **Allen × Luhmann seam**: capture is shared, clarify triages. Actions go into GTD, knowledge goes into the note system. Capture isn't reinvented.

## v1.1 — Calendar reuse (external calendar provider read + confirmed write)
- **One calendar**: when an external calendar provider is reachable it is the only hard landscape; `calendar.md` becomes the unreachable fallback, with no copy (Allen's two-calendar hard rule).
- **Read**: engage reads today's hard appointments, review reads this week's hard landscape; external calendar provider first, falling back when unreachable.
- **Write (old policy)**: v1.1 used a confirmation gate; the current write rule was changed in v1.10 to auto-writing complete events.

## v1.2 — Codex slash commands + triggers complete on all three platforms
- Codex `~/.codex/prompts/gtd*.md` (8 prompts), vault-aware fail-soft (Codex prompts are global only, no project level).
- AGENTS.md auto-routing, so Codex "triggers on plain language".
- Triggers on three platforms: cc `/gtd-*` (project-level commands) · Cursor keywords (skill-rules) · Codex `/gtd-*` + AGENTS routing + orchestrator agent. One source of truth, one `memory/gtd/`.

## v1.3 — capture auto-clarifies by default (AI-native)
- Allen originally separated capture/clarify for the human mind (switching into decision mode has a cost); the AI's switching cost is ≈0, so capture → auto-clarify by default.
- Keeps two real insights: ① writing to file always comes first (nothing lost); ② batches / mind sweeps are never interrupted item by item.
- Single-item act-then-surface: clarify and file + one-line report + correctable in one sentence.
- Human-judgment guard: stop and ask only in four cases — "action vs knowledge / no derivable next action / implied commitment / unclear project outcome".

## v1.4 — organize becomes AI-automated structural hygiene
- organize = structural hygiene (per-item filing already happens in clarify). This is what the AI should fully automate: mostly pure mechanical bookkeeping.
- Mechanical issues handled silently and automatically (orphans / wrong contexts / stale checkmarks / duplicates / next actions for stalled projects), with a one-line summary; judgment calls asked in a batch.
- Runs automatically before engage; runs inside review's Get Current.

## v1.5 — Completed projects close automatically
- **Hard rule**: project desired outcome achieved and no next action still needs pushing → delete the whole project block; no archiving, no "Next actions: none".
- **Order fix**: organize/review first judge whether a project is complete; only unfinished ones get stalled next actions, avoiding forced actions for closed projects.
- **Regression guard**: `gtd_status.sh` treats "Next actions: none / done / confirmed" as no valid next action and prompts to run `/gtd-organize`.

## v1.6 — review upgraded to an AI review prep pack
- **Boundary redrawn**: review no longer just reminds the user to go through lists; the AI first does a system check-up, mechanical cleanup, candidate actions, and message drafts, and the user confirms only a few commitment decisions.
- **New read-only script**: `scripts/gtd_review_prep.sh` generates the review prep pack: dashboard, inbox summary, stalled projects, waiting-for, vague next actions, someday candidates, confirmation queue.
- **Flow upgrade**: review first runs the review prep pack + organize mechanical hygiene, then goes into Get Clear / Get Current / Get Creative / Horizons.
- **Scheduling boundary**: future cron / loop / launchd may only remind and call the review prep script; never auto-edit lists, write to the calendar, send messages, or decide next week's focus.
- **Template sync**: the weekly review snapshot gains "AI review prep pack" and "Written to file after confirmation" sections.

## v1.7 — GTD internal links switch to Obsidian heading links
- **Rule**: when pointing to a heading inside a `memory/gtd/` file, always write `[[filename#Heading|Heading]]`.
- **Examples**: project reference `[[projects#Project name|Project name]]`; support material reference `[[reference#Entry name|Entry name]]`.
- **Boundary**: bare `[[filename]]` is still used for real standalone files, e.g. `[[projects]]`, `[[next-actions]]`.

## v1.8 — init has built-in Codex slash command install / refresh
- `gtd_init.sh` adds install / refresh logic for `~/.codex/prompts/gtd*.md`, reading templates from `templates/codex-prompts/` inside the skill package.
- The `--status` self-check reports whether the Codex slash commands are complete.
- `install.sh` syncs `src/codex-prompts/` into the installed skill package, so running init alone can also fill in `/gtd*`.

## v1.9 — Codex plugin package
- Adds a public Codex plugin packaging path: the repo marketplace points to `plugins/llm-gtd/`, and the plugin skill is generated by syncing from `src/skill/`.
- Script state-root resolution becomes three-tiered: explicit `LLM_GTD_ROOT` → auto-locate the vault from a legacy `.cursor/skills/gtd-harness/` install → otherwise the current workspace, suiting Codex plugin mode.
- The plugin package contains only skill logic, not the user's `memory/gtd/` state; the external calendar provider remains an optional external capability, with no built-in app/MCP.

## v1.10 — external calendar provider auto-write
- **Write**: when clarify produces a time-specific item with complete event details → write directly to the external calendar provider, no per-item confirmation.
- **Missing fields**: when key fields such as date, start time, or event title / subject are missing, ask only for the missing fields; meetings without a duration default to 60 minutes.
- **Failure fallback**: external calendar provider unreachable or tool failure → report honestly and record the time-specific item in the `calendar.md` fallback, still honoring "never maintain two calendars".

## v1.11 — Projects support multiple current next actions
- **Format upgrade**: `Next actions` in `projects.md` can be multiple lines of block links pointing to `next-actions.md` or `waiting-for.md`.
- **Boundary kept**: attach only physical actions that can move forward in parallel right now; sequentially dependent task trees still go in support material / the Natural Planning Model, so `projects.md` doesn't become project management software.
- **Regression guard**: the stalled checks in `gtd_status.sh` and `gtd_review_prep.sh` now recognize valid block links; an empty heading, "Next actions: none", or a generic `see next-actions` no longer counts as a valid next action.

## v1.12 — update scenario command
- **New command**: `gtd-update` handles changes in reality the user reports: completed actions, project progress, waiting-for replies, changed event details, cancellations or corrections.
- **Routing fix**: when `/gtd` sees phrasing like "done / confirmed / they replied / the schedule changed / cancelled", it goes to update first, instead of re-capturing facts that already happened as inbox items.
- **Project advancement**: completed next actions are deleted from the list; if the project is still unfinished, a new current next action is drafted from the new facts; if the outcome is achieved, the project block is deleted.
- **Boundary**: new input still goes to capture; structural drift still goes to organize; for risky project deletion, multiple matches, or a non-unique calendar event, ask only one question.

## v1.13 — English translation
- All skill prompts, templates, and script output translated to English using David Allen's GTD terminology.
- **Parsed labels changed**: scripts now parse `- Next actions:`, `- [ ] Opportunity:`, `- GTD visibility:`; eval-check headings and the vague-verb list are now English. Existing `memory/gtd/` files using the pre-1.13 labels need these labels updated for the stalled / visibility checks to work.

## v1.14.1 — Calendar checks read event availability
- **Bug the general skill now fixes**: `clarify`, `engage`, and `review` previously had no way to tell a free-marked event (an informational all-day block, say) from a real busy conflict — they'd have had to guess from title or length. Fixed once in `capability-map.md`'s conflict and capacity judgment, pointed to from all three call sites instead of being copied three times.
- **Local rule retired**: this had been patched around per-vault in `personalized.md`; that override is removed now that the general skill covers it. New eval E15-calendar-free.

## v1.15 — `/gtd-help` + per-command model guidance
- **New command**: `gtd-help`, read-only, never writes. Shows every command's description, When to run, and example (sourced from each sub-skill's own frontmatter/body via the new `gtd_help.sh`, never hand-written), the day-to-day rhythm, one "right now" suggestion from `gtd_status.sh`, and where things live. `/gtd-help <command>` gives one command's detail; `/gtd-help lists` explains list boundaries.
- **Model tiers, not model names, in the skills**: every sub-skill's frontmatter gets `model-tier: fast | balanced | strongest`; `references/model-guidance.md` is the one place actual Claude model names appear, mapped to tiers, so a new model family means editing one file. `personalized.md` can override the mapping or turn the check off.
- **The check**: every command compares the session's current model against its tier before working; below tier, says so once and asks whether to continue or switch — except capture, which always writes to the inbox first and only then says it skipped auto-clarify. Above tier: at most one trailing tip, never an interruption. Once per session.
- **Routing**: "help / what can this do / which command should I use" routes to `help/SKILL.md` before the empty-input mind-sweep rule, so a genuine help request is never captured as an inbox item — distinct from "help me empty my head," which still means mind sweep.
- **New evals**: E24-help, E25-help-route, E26-model-under, E27-model-over, E28-model-unknown-and-once. `gtd_eval_check.sh` now also fails if a sub-skill is missing from `gtd_help.sh`'s output, lacks a valid `model-tier`, lacks a command/prompt file in all three platforms, or if a Claude model name leaks anywhere outside `references/model-guidance.md`.

## v1.15.1 — Knowledge defaults to reference.md, not a ZK pipeline
- **Default changed**: every place the skill previously said non-actionable knowledge / insight material gets "handed off to the ZK pipeline / fleeting-note" now says it files to `reference.md` instead — `list-definitions.md`, `capture/SKILL.md`, `clarify/SKILL.md`, the router `SKILL.md`, `references/natural-planning-model.md`, `references/clarify-decision-tree.md`, `references/evals.md` (E02), `templates/session-close-template.md`, `gtd_init.sh`'s written `reference.md` header, all three platforms' `gtd`/`gtd-clarify` command files, `gtd-orchestrator.toml`, `cursor-skill-rules.json`, and both READMEs.
- **Still overridable**: a vault that runs a separate knowledge system (a Zettelkasten or otherwise) points the hand-off there instead via `memory/gtd/personalized.md`, the same override pattern used for model-tier and the calendar rule. The general skill ships with no assumption that one exists.
- **Why**: the ZK pipeline was never part of this plugin — it assumed an external system every user was expected to have. Most don't; `reference.md` is already one of the eight core lists and already existed for exactly this (non-actionable, look-up material), so it's the honest default. No behavior changed for anyone who never had a ZK pipeline to begin with.
- New eval: E02-non-trigger's expectation rewritten to name `reference.md` (and the `personalized.md` override) instead of the ZK pipeline.

## v1.16 — Per-item layout, done record, and after-action review
- **Opt-in per-item layout**: next-actions, waiting-for, projects, someday-maybe, and product-ideas can each be a folder of one note per item, the single-file fields moved into YAML properties with a fixed vocabulary (`list-definitions.md` "Property values"). A project is a folder holding its README and support material; general reference is a `reference/` folder at the workspace root. Inbox, calendar, horizons, and personalized stay files. Layout is detected from whether `memory/gtd/next-actions/` is a folder; single-file stays the default and every command works in both. Each list folder's `README.md` keeps the rules that used to head the list file, and is never an item.
- **Replaces the v1.5 "delete, no archive" rule, in both layouts**: a finished next action or received waiting-for moves to a done record (`_done/` or `done.md`) with an outcome (what was done, problems and how they were solved). The outcome comes from session context, or from one optional question only for project-linked or 30+ min / deep work; never blocks completion. A cancelled project step is recorded as cancelled; a cancelled standalone action or dropped someday item is still just deleted. The live lists still hold only open commitments, and nothing that counts or offers open work reads the done record.
- **After-action review**: a finished project gets a short AAR drafted from its done items (intended outcome, what happened, problems and fixes, same or different next time, reusable how-tos), with how-tos offered for filing to the project folder or reference, all on one confirmation. Per-item, the whole project folder then moves to `_done/<Project name>/` and links to it are rewritten.
- **Scripts**: new read-only `gtd_list.sh` (one line per item, either layout, lens filters, plus `done --since/--project/--problems`) and `gtd_check.sh` (organize's per-item findings: orphans, stalled projects, bad properties, duplicates, unsafe filenames, done-record gaps; finds, never fixes). `gtd_status.sh` and `gtd_review_prep.sh` read both layouts; review prep gains "Done since last review". `gtd_init.sh --layout notes [--with-bases]` builds the per-item layout and never switches an existing one.
- **Migration**: `gtd_migrate_to_notes.sh`, a dry run by default; `--apply` needs a clean git tree, never overwrites, keeps the old lists in `memory/gtd/_migrated/`, rewrites list links across the workspace (never inside code), and refuses if any list's item count would change.
- New evals E16-E23; the static gate gained per-item init, read-path, done-record, and migration fixtures.

## v1.17 — Tickler (per-item layout)
- **New list `tickler/`** (Allen's tickler): committed work that can't be acted on until a date, one note per tickle with a `tickle:` date. Not someday-maybe (uncommitted), not waiting-for (nobody owes it), not the calendar (not an appointment).
- **Stalled, defined once** in `list-definitions.md`: a project is in play when an open next action, waiting-for, or tickle links to it. A tickled project is on hold on purpose: never stalled, never given a drafted next action, never closed over an open tickle.
- **On the date**, organize moves a concrete project tickle into `next-actions/` and queues anything else in the inbox as a pointer to the note (never twice); engage leads with what came due; the Weekly Review shows due / next 14 days / on-hold projects and asks once whether each date holds.
- **Always local**: never exported to the external calendar, outside the calendar fallback chain; `calendar.md`'s contract is unchanged. Organize flags tickle dates the calendar shows as blocked and never re-dates them.
- **Why a separate list**: the first draft put the tickler in a `calendar.md` section, but that file is a fallback copy that organize exports and deletes, read only when the external calendar is unreachable, so a tickle there would have been exported or never seen.
- **Per-item only, relaxing v1.16's "every feature works in both layouts" rule for this feature.** The single-file layout behaves as in v1.16 with no tickler.
- New evals E29-E35; the static gate gained a tickler fixture (stalled rule, due/within split, inbox guard, dashboard, review prep, single-file stand-down).

## v2.0 — Per-item only; product-ideas retired
- **One layout.** The single-file layout is dropped: every list that holds items is a folder of one note per item, and `gtd_list.sh` / `gtd_check.sh` are the only readers. Keeping two storage shapes doubled every script and most skill text, the tickler had already gone per-item only in v1.17, and this fork's only system had migrated. A `memory/gtd/` with 1.x single-file lists is refused by every script (exit 4) rather than half-read; `gtd_migrate_to_notes.sh` stays in 1.17.x for anyone who needs it.
- **No product-ideas list.** It was an upstream extension, not one of Allen's lists, with its own fields and review steps. A product idea is now clarified like any input (committed → project + next action; not → someday-maybe; knowledge → reference).
- **Dropped with them**: `--layout`, `GTD_LAYOUT`, `--import-legacy`, the legacy `@context` groups in the next-actions README, `done.md`, and the single-file templates. Eval E23 retired, E05 rewritten, new E36.
- This fork no longer tracks upstream (`mikonos/LLM-GTD`) as of v1.17.1.

---

**AI automation overview**: capture → clarify automatic, clear updates automatic, organize (mechanical) automatic; review preprocesses first; engage offers candidates, and the user keeps commitment, choice, and reflection.

## To do / v2 candidates
- Connect `calendar.md` to a reminder provider + two-way reconciliation.
- Review automation cadence: cron / scheduled reminders (off by default, requires user consent).
- Hook engage into a daily routine.
