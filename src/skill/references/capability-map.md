# Capability Map (public package adapter contract)

> The GTD skill's SKILL.md files use **intent language** ("read that list" / "append a line" / "scan all lists") and don't bind to any single platform's tools.
> At runtime, Claude Code, Cursor, Codex, or another agent translates the intent into its own read/write, calendar, and automation capabilities.

## Runtime forms

| Form | Skill location | State location | Notes |
|---|---|---|---|
| Source package | `src/skill/` | Set by `LLM_GTD_ROOT` or the current directory when testing | Repo-maintained source of truth |
| Legacy install | `<workspace>/.cursor/skills/gtd-harness/` | `<workspace>/memory/gtd/` | Run after `install.sh` copies it; compatible with Cursor / manual install / legacy Codex prompts |
| Plugin install | plugin read-only skill directory | Current workspace `memory/gtd/` | The plugin carries only the skill, never user state |

## Intent verbs → runtime capabilities

| GTD intent verb | Capability needed | Fallback rule |
|---|---|---|
| Read a list | Read `memory/gtd/<list>.md` | If the file is missing, do not run init automatically — ask the user whether GTD is already set up somewhere else first (see `init/SKILL.md`'s "One inbox per human" rule) |
| Append / delete / minimally replace a line | File editing | Ask one question when high-risk or multiple matches |
| Scan all lists | Walk `memory/gtd/` | If the read-only scan fails, report the gap |
| Run the dashboard / init / review prep scripts | shell/script execution | If scripts are unavailable, read the lists manually |
| Schedule the GTD automation cadence | Platform automation/reminder capability | Never hand-write unknown platform state; only output a handoff |
| Read the hard landscape (calendar) | calendar provider adapter | If all providers are unreachable, read the `calendar.md` fallback |
| Write a calendar event | calendar provider adapter create/update | Never claim done before the tool succeeds; on failure write the fallback |
| Read approval radar | approval provider read-only adapter | If the provider is unreachable, state the gap and continue Engage |
| Send messages / follow up / delegate to others | messaging provider | Draft only; confirmation required before sending |

## Intent verbs by layout

The intent verbs above stay the same in both layouts; only the capability behind each one changes shape. See `references/list-definitions.md`'s "Layouts" section for the folder structure and layout-detection rule this table assumes.

| GTD intent verb | Single-file capability | Per-item capability |
|---|---|---|
| Read a list | Read `memory/gtd/<list>.md` | Run `scripts/gtd_list.sh <list> [--max-time N] [--energy E] [--context C] [--project P]`; falls back to opening every note only if the script is unavailable |
| Append an item | Append a line to `memory/gtd/<list>.md` | Create `memory/gtd/<list>/<Title>.md` from that list's `templates/*-note.md` with frontmatter, skipping `README.md` as a reserved filename; a project is a folder, `memory/gtd/projects/<Project name>/README.md` from `templates/project-note.md`; general reference is `reference/<Title>.md` at the workspace root |
| Link an item to its project | `Project: [[projects#Name\|Name]]` on the line, plus a block link back from the project | `project: "[[projects/<Project name>/README\|<Project name>]]"` in the note's frontmatter only — the project README's embedded view finds it, nothing is written back |
| Delete / minimally replace an item | Edit or remove the matching line | Edit or delete the matching note file |
| Complete an item | Delete the line (or, once the lifecycle phase ships, move it under `done.md`'s completion date with its outcome) | Move the note into `memory/gtd/_done/` with `completed`, `result`, and its outcome added to the frontmatter/body |
| Scan a list for stalled / orphaned / malformed items | `awk`/`grep` over the one file | `gtd_list.sh <list>` plus a frontmatter scan for missing/invalid fields; never scans `_done/` |
| Read a list's local rules before writing | Read the top of `memory/gtd/<list>.md` | Read `memory/gtd/<list>/README.md` |

## Calendar source adapter + auto-write contract

GTD hard rule: **never maintain two calendars.** Once an external calendar provider is reachable, it is the hard landscape; if the preferred provider fails, fall back along the fallback chain; `calendar.md` is the fallback only when all external providers are unreachable — **never keep a copy**.

**Calendar source resolution (fall back by reachability)**:

```text
When the hard landscape is needed (engage: today / review: this week):
1. Preferred calendar provider reachable? → read that provider
2. Preferred provider unreachable? → read the fallback calendar provider
3. All external providers unreachable? → read calendar.md (local fallback) and note "based on local fallback, may be incomplete"
```

> Specific provider names, authentication, CLI commands, and local preferences belong in a local personalized overlay, not in the general skill.

**Conflict and capacity judgment**:

- `clarify` before writing a hard appointment: read the target time slot plus the necessary buffer; if an event overlaps or the buffer is too small, stop writing and suggest reschedule / cancel / delegate / downgrade.
- `engage` before choosing a next action: read today's hard landscape and compute the free time window until the next hard appointment; filter next-actions by that window.
- `review` before choosing next week's focus: scan next week's hard landscape and identify obvious overcommitment; give only renegotiation suggestions, never auto-schedule ordinary next-actions.
- **Read each event's availability, not just its title or length.** When checking whether an event blocks time (any of the three judgments above), read that event's availability field (free/busy, "Show as" / transparency). An event marked free never blocks time, whatever its length or title. An event marked busy, or with no availability field at all, counts as a conflict. Never infer availability from a title, a guess, or a length alone.

**Auto-write contract**:

- Writing = a **high-consequence action**, but when event details are complete and the target slot has no conflict, you may call the preferred calendar provider's create/update; never claim it's written before the tool returns success.
- Minimum information to write: **event title + date + start time**. Location, people involved, source, and notes go into the description / location if present; meetings without a duration default to 60 minutes.
- When key fields such as date, start time, or event title / subject are missing, ask only for the missing fields; never write a guessed event.
- Preferred provider returns success → report "written to the external calendar".
- Preferred provider fails / unreachable → try the fallback calendar provider; fallback returns success → report "written to the fallback calendar provider".
- All external providers fail / unreachable → report "not written to the external calendar (reason)" and record the time-specific item in the `calendar.md` fallback for manual follow-up — **never misreport**.
- Distinguish four states: not attempted / attempted and failed / partially done / tool-confirmed done.

## Invariants

1. **Zero adaptation in the state layer**: user state lives only in `memory/gtd/`, as plain markdown, never bundled into the plugin.
2. **Single source for the logic layer**: the public repo maintains `src/skill/`; the plugin skill is generated by the sync script.
3. **Neutral runtime layer**: sub-skills write intents and never treat a particular local provider as a default fact.
4. **Explicit install of the automation cadence**: boundaries for Weekly Review / Monthly Reflect / Daily Engage + Approval Radar are in `references/automation-profiles.md`; `gtd_init.sh --status` only checks status, and `--install-cron` in an agent session triggers the platform automation tool to create or update.

## Self-check commands

```bash
bash src/skill/scripts/gtd_eval_check.sh
bash src/skill/scripts/gtd_init.sh --status
LLM_GTD_ROOT="$(mktemp -d)" bash src/skill/scripts/gtd_init.sh
```
