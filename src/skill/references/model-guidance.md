# Model Guidance

> Commands are tagged by **tier**, not by model name, because the plugin also runs on Codex and Cursor and model names change. This file is the only place model names appear — a new model family means editing this file, nothing else.

Last reviewed: 2026-09-27.

## Tiers → current Claude models

| Tier | Commands | Current Claude model | Why |
|---|---|---|---|
| strongest | `review`, project after-action reviews, the migration | Opus 5.5 | Reads across many lists and notes, weighs priorities against your horizons, and writes summaries you'll rely on later |
| balanced | `capture`, `clarify`, `update`, `organize`, `engage`, `gtd` (router), `init` | Sonnet 5 (Opus 5.5 also fine) | Rule-following edits with moderate judgment. A misfiled item or broken link is what makes a GTD system feel untrustworthy, so never go below this tier |
| fast | `help` | Haiku 4.5 (any model is fine) | Read-only, mostly script output |

## The check

Done by every command before its own work, using each sub-skill's `model-tier` frontmatter:

1. **Identify the current model** from the session's own information. If it isn't known (another platform, or not stated), skip the check silently.
2. **Compare** it with the command's `model-tier`, using the table above.
3. **Below the tier** (for example, clarify on Haiku, or review on Sonnet): say it in one line before starting, and ask once whether to continue or switch.
   - Example: "You're on Haiku 4.5; clarify works best on Sonnet 5 or better. Continue, or switch with `/model sonnet` and rerun?"
   - **Capture is the exception.** Capture never waits: it writes the input to the inbox first (nothing is ever lost), then skips auto-clarify and says "Captured. You're on Haiku 4.5, so I didn't file it; switch to Sonnet 5 and run `/gtd-clarify`."
4. **Above the tier** (for example, capture on Opus): never interrupt. At most one line at the end, once per session: "Tip: Sonnet 5 is enough for capture." Switching and rerunning would cost more than just doing the small job, so this is only mentioned after the work.
5. **Once per session.** After you answer or continue, don't repeat the check in that session, even for other commands, unless the model changes.
6. **Never block a Weekly Review or an update because of the model.** Continuing is always an option.

## Overrides

`memory/gtd/personalized.md` may hold:

- `Model check: off` — disables the check entirely.
- A different tier mapping, for example "balanced = Opus 5.5" — overrides the table above for that vault.

## Single source, no drift

`scripts/gtd_help.sh` reads `model-tier:` straight from each sub-skill's frontmatter and this file's tier→model table, so `/gtd-help`'s model column always matches what the check actually does — nothing is duplicated by hand.
