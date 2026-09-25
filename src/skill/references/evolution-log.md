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
- All skill prompts, templates, and script output translated from Chinese to English using David Allen's GTD terminology.
- **Parsed labels changed**: `- 下一步行动：` → `- Next actions:`, `- [ ] 机会：` → `- [ ] Opportunity:`, `- GTD 可见性：` → `- GTD visibility:`; eval-check headings and the vague-verb list are now English. Existing `memory/gtd/` files written in the old Chinese format need these labels updated for the stalled / visibility checks to work.
- **Kept**: `--import-legacy` still reads the Chinese `@自己` / `@等待` / `@项目` sections of a legacy `open loops.md`.

---

**AI automation overview**: capture → clarify automatic, clear updates automatic, organize (mechanical) automatic; review preprocesses first; engage offers candidates, and the user keeps commitment, choice, and reflection.

## To do / v2 candidates
- Connect `calendar.md` to a reminder provider + two-way reconciliation.
- Review automation cadence: cron / scheduled reminders (off by default, requires user consent).
- Hook engage into a daily routine.
