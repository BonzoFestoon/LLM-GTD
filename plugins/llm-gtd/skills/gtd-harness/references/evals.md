# GTD Skill Evals

> Lightweight manual evals. Before and after changing the GTD skill, use these scenarios to check for regressions in triggering, routing, boundaries, and privacy. Every eval should yield stable behavior derivable from the current skill docs.

## How to run

1. Treat each "Input" as a user request.
2. Judge pass/fail against "Expected route / Must / Must not".
3. After changing the skill, run at least the 14 core evals in this file; all must pass before a public sync.
4. Static gate: `bash scripts/gtd_eval_check.sh` (inside the skill root) or `GTD_SKILL_ROOT=src/skill bash src/skill/scripts/gtd_eval_check.sh`.

## Initial manual run record

- 2026-06-11: E01-E14 manually reviewed against the current entry routing, the loading tables at the top of each sub-skill, and the `list-definitions.md` permission table; result 14/14 pass. The static gate `gtd_eval_check.sh` also passed.

## Core Evals

| ID | Input | Expected route | Must | Must not |
|---|---|---|---|---|
| E01-trigger | "My head is a mess, help me empty it into GTD" | `capture/SKILL.md` | Enter a mind sweep; capture everything first, then ask whether to batch clarify | Jump straight into a weekly review; interrupt item by item |
| E02-non-trigger | "Turn this article into a knowledge card for me" | ZK pipeline, no GTD action triggered | Explain that this is knowledge / idea processing and should go to fleeting-note / ZK | Write to next-actions |
| E03-capture-single | "Note this: confirm the contract version with Colleague A" | `capture` → `clarify` | Land in inbox first; small inputs auto-clarify by default; output a one-line destination | Stop at the inbox without processing; ask the user to pick a subcommand |
| E04-mind-sweep | "Buy milk; reply to email; prep Friday's meeting; research a product idea" | `capture/SKILL.md` | Capture all items first; then batch clarify; the product idea goes to product-ideas with a visible next action | Ask for confirmation on every item separately |
| E05-product-idea | "An idea for a feature that auto-organizes the family shopping list" | `clarify/SKILL.md` | Goes into `product-ideas.md`; also creates project / next-action visibility by default | Drop it into someday as a cold-storage backlog |
| E06-waiting-final | "That approval has gone through" | `clarify/SKILL.md` | Ask about or record the final definition of done; distinguish approval passed from payment received / final completion | Delete the waiting-for item as done right away |
| E07-ten-min | "I only have 10 minutes, what should I do now?" | `engage/SKILL.md` | Look at the hard landscape first; give 3-5 short candidates from the action pool and explain why each is doable now | Recommend deep-work tasks; schedule candidates into the calendar |
| E08-low-energy | "I'm out of energy, I only want light stuff" | `engage/SKILL.md` | Use the low-energy lens; exclude high cognitive-load tasks | Recommend high-pressure conversations or deep work |
| E09-shopping-prep | "I'm out shopping / what do I need to prep for tomorrow morning?" | `engage/SKILL.md` | Filter by the shopping or prep-chain hard setting; legacy @ groups are only compatibility signals | Recommend by default because of the @computer group |
| E10-review | "Help me do my weekly review" | `review/SKILL.md` | Run the review prep pack first; Get Clear / Current / Creative; give 3 candidates for next week | Automatically cut projects, send messages, write to the calendar |
| E11-init-status | "Check the GTD init status" | `init/SKILL.md` | Run `gtd_init.sh --status`; read-only status report | Create or modify automation |
| E12-install-cron | "Initialize GTD cron" | `init/SKILL.md` + `automation-profiles.md` | Read profiles first; call the platform automation tool only for an explicit install; run status after installing to verify | Hand-write automation files from the shell; create duplicate crons of the same kind |
| E13-privacy | "Check privacy before publicly syncing this skill" | `references/evals.md` + privacy scan | Scan with a denylist from a private overlay or the external environment; real provider preferences belong only in the private overlay | Real names, real project names, or local paths appearing in the general skill |
| E14-update-reality | "It's done / they replied / the schedule changed / it's cancelled" | `update/SKILL.md` | Read the existing lists, then sync the change in reality; delete completed items, re-clarify waiting-for replies, advance the project's next action when needed | Re-capture the change in reality as an inbox item |

## Automated checks

```bash
bash scripts/gtd_eval_check.sh
bash -n scripts/gtd_init.sh
bash -n scripts/gtd_env.sh
bash -n scripts/gtd_status.sh
bash -n scripts/gtd_review_prep.sh
bash -n scripts/gtd_review_prep_notify.sh
LLM_GTD_ROOT="$(mktemp -d)" bash scripts/gtd_init.sh --status
```

The privacy denylist is not written into this file; it comes from a private overlay or the runtime environment, so the general skill doesn't carry private terms itself.
