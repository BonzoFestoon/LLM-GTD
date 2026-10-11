# Model Guidance

> Commands are tagged by **tier**, not by model name, because the plugin also runs on Codex and Cursor and model names change. The tier → model table lives in `shared-rules.md` ("Tiers → current Claude models"), the only place model names appear — a new model family means editing that table, nothing else. This file explains the check; `shared-rules.md` carries its short form, so commands read this only when the check fires or an override applies.

Last reviewed: 2026-09-27.

## The check

Done by every command before its own work, using each sub-skill's `model-tier` frontmatter:

1. **Identify the current model** from the session's own information. If it isn't known (another platform, or not stated), skip the check silently.
2. **Compare** it with the command's `model-tier`, using the table in `shared-rules.md`.
3. **Below the tier** (for example, clarify on Haiku, or review on Sonnet): say it in one line before starting, and ask once whether to continue or switch.
   - Example: "You're on ⟨fast-tier model⟩; clarify works best on ⟨balanced-tier model⟩ or better. Continue, or switch with `/model` and rerun?"
4. **Above the tier** (for example, capture on the strongest model): never interrupt. At most one line at the end, once per session: "Tip: ⟨fast-tier model⟩ is enough for capture." Switching and rerunning would cost more than just doing the small job, so this is only mentioned after the work.
5. **Once per session.** After you answer or continue, don't repeat the check in that session, even for other commands, unless the model changes.
6. **Never block a Weekly Review or an update because of the model.** Continuing is always an option.

## Overrides

`memory/gtd/personalized.md` may hold:

- `Model check: off` — disables the check entirely.
- A different tier mapping, for example "balanced = ⟨strongest-tier model⟩" — overrides the table in `shared-rules.md` for that vault.

## Single source, no drift

`scripts/gtd_help.sh` reads `model-tier:` straight from each sub-skill's frontmatter and `shared-rules.md`'s tier→model table, so `/gtd-help`'s model column always matches what the check actually does — nothing is duplicated by hand.
