# GTD Skill Evals

> Lightweight manual evals. Before and after changing the GTD skill, use these scenarios to check for regressions in triggering, routing, boundaries, and privacy. Every eval should yield stable behavior derivable from the current skill docs.

## How to run

1. Treat each "Input" as a user request.
2. Judge pass/fail against "Expected route / Must / Must not".
3. After changing the skill, run the core evals in this file; all must pass before a public sync. E16-E23 cover the per-item layout, the done record, and migration; run them against a scratch per-item workspace (`gtd_init.sh --confirm-create --layout notes` in a temp folder), and E17/E20/E21 in both layouts.
4. Static gate: `bash scripts/gtd_eval_check.sh` (inside the skill root) or `GTD_SKILL_ROOT=src/skill bash src/skill/scripts/gtd_eval_check.sh`.

## Initial manual run record

- 2026-06-11: E01-E14 manually reviewed against the current entry routing, the loading tables at the top of each sub-skill, and the `list-definitions.md` permission table; result 14/14 pass. The static gate `gtd_eval_check.sh` also passed.
- 2026-09-27: E15-calendar-free manually reviewed against `capability-map.md`'s new "read each event's availability" rule and its pointers from `clarify/SKILL.md`, `engage/SKILL.md`, and `review/SKILL.md`; pass.
- 2026-09-27: E24-E28 manually reviewed against `help/SKILL.md`, `gtd_help.sh` (tested directly: all 9 commands, single-command detail, unknown-command error path), the router's new help-first routing rule, capture's model-check exception branch, and `SKILL.md`/`model-guidance.md`'s shared model check (which the other 6 sub-skills inherit without duplicating); 5/5 pass.
- 2026-09-27: E02-non-trigger re-reviewed after the ZK-pipeline default was retired (Phase 1c) — "knowledge card" input still triggers no GTD action and now correctly routes the explanation to `reference.md` / the `personalized.md` override instead of the old ZK wording; pass. Static gate re-run clean after the sync.
- 2026-09-27: E16-E23 manually reviewed against `clarify/SKILL.md` "Filing in the per-item layout", `update/SKILL.md` "Done record" and "Project close", `engage/SKILL.md`, `review/SKILL.md`, and `list-definitions.md`'s Property values and Done record; 8/8 pass. The mechanical halves are also in the static gate: E19's lens filtering and `_done/` exclusion, E22's done listing (`gtd_list.sh done --since/--project/--problems`, both layouts), E23 via the migration fixture. `gtd_migrate_to_notes.sh` was also rehearsed on a copy of a real 16-action / 11-project vault: counts matched, no `gtd_check.sh` findings. E14 re-reviewed for the done-record change; pass.

## Core Evals

| ID | Input | Expected route | Must | Must not |
|---|---|---|---|---|
| E01-trigger | "My head is a mess, help me empty it into GTD" | `capture/SKILL.md` | Enter a mind sweep; capture everything first, then ask whether to batch clarify | Jump straight into a weekly review; interrupt item by item |
| E02-non-trigger | "Turn this article into a knowledge card for me" | No GTD action triggered | Explain that this is knowledge / idea processing and should go to `reference.md`, not an action list (or wherever `personalized.md` redirects knowledge) | Write to next-actions |
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
| E14-update-reality | "It's done / they replied / the schedule changed / it's cancelled" | `update/SKILL.md` | Read the existing lists, then sync the change in reality; move completed items to the done record with an outcome (no question for a quick standalone action), re-clarify waiting-for replies, advance the project's next action or close the project with an AAR when needed | Re-capture the change in reality as an inbox item |
| E15-calendar-free | A 10-hour calendar event marked free (availability/"Show as": free) overlaps a proposed hard-appointment slot / today's free-time window / next week's capacity scan | `clarify/SKILL.md`, `engage/SKILL.md`, or `review/SKILL.md`, per which one is judging capacity | Read the event's availability field; treat it as not blocking time regardless of its length or title; proceed as if that slot is open | Flag it as a conflict, treat it as blocking time, or infer availability from the title / length alone |
| E16-clarify-note | "Note this: call the dentist to book a cleaning", per-item layout | `capture` → `clarify/SKILL.md` "Filing in the per-item layout" | Read `next-actions/README.md`; create one note `next-actions/<verb-first title>.md` with `time` (minutes), `energy`, and `context` filled from the "Property values" vocabulary, the action in the body; delete the inbox line only after the note exists; report the note path | Append a line to any list file; ask the user to pick tags or properties; write placeholder values |
| E17-done-note | "Done, the portal wanted the parcel number without dashes" for a project-linked action | `update/SKILL.md` "Done record" | Move the note to `_done/` (single-file: the line to `done.md` under today) with `completed`, `result: done`, `list`, and that fix under `Problems and fixes:`; then check the project: new next action, or close it with an AAR, or flag it stalled | Delete it outright; leave it in its list with a done status; ask the outcome question when the user already gave the outcome |
| E18-no-tag-burden | Any capture, then auto-clarify, in the per-item layout | `capture/SKILL.md`, `clarify/SKILL.md` | Capture asks nothing extra; clarify estimates properties itself and leaves out one it genuinely can't estimate (organize repairs it) | Ask the user to tag, choose a context, or fill properties; make capture slower |
| E19-engage-notes | "I only have 10 minutes", per-item layout | `engage/SKILL.md` | Read the pool with `gtd_list.sh next-actions --max-time 10` (plus any lens flags); offer 3-5 items | Open every note; offer anything from `_done/` / `done.md`; offer an item over 10 minutes |
| E20-done-quiet | "Done" on a 5-minute standalone action, with no session context | `update/SKILL.md` "Done record" | Ask nothing; record `Problems and fixes: none noted` in the done record | Ask the optional outcome question (it's only for project-linked or 30+ min / deep work) |
| E21-project-aar | The last open action of a project is done and its outcome is achieved | `update/SKILL.md` "Project close" | Gather the project's done items (`gtd_list.sh done --project`), draft the AAR, offer filing how-tos to the project folder or `reference/`, close on one confirmation: per-item, the whole folder moves to `_done/<Project name>/` and links to it are rewritten; single-file, a `- [x] Project:` line with the AAR goes to `done.md` | Close without offering the AAR; make the filing a separate interruption; close while open actions still link to it; write how-tos into an action list |
| E22-review-done | "Help me do my weekly review" after a week with done items, one with a real problem-and-fix | `review/SKILL.md` | The prep pack (`gtd_review_prep.sh --since <last review>`) shows "Done since last review": wins first, then the problem items; filing to reference is offered only for those, once | Offer filing for every done item; make the filing required; count done items as open work |
| E23-readme-kept | `gtd_migrate_to_notes.sh --apply` on a single-file system | migration script | Every non-item line of each old list (title, rules, format line, legacy group headings and notes) appears in that folder's `README.md`; no script counts `README.md` as an item. Checked mechanically by `gtd_eval_check.sh`'s migration fixture | Drop a header line; list `README.md` as an item |
| E24-help | "/gtd-help" | `help/SKILL.md` | List all nine commands (gtd + 8 sub-commands) with what they do, when to run them, and an example; give one "right now" suggestion; write no files | Write to any `memory/gtd/` file; skip a command; invent commands text not sourced from `gtd_help.sh` |
| E25-help-route | "How do I use GTD?" via `/gtd` | `help/SKILL.md` | Route to help before the mind-sweep rule; answer with the commands overview | Capture "how do I use GTD?" as an inbox item |
| E26-model-under | `/gtd-capture` on a model below capture's `model-tier`; then `/gtd-clarify` on a model below its tier (see `references/model-guidance.md` for which model that is right now) | `capture/SKILL.md`; `clarify/SKILL.md` | Capture: write to the inbox first, skip auto-clarify, say so and name the switch + rerun command. Clarify: ask once whether to continue or switch, before any change | Capture: lose the input, or file it anyway. Clarify: change any list without asking first |
| E27-model-over | `/gtd-capture` on a model above capture's `model-tier` (see `references/model-guidance.md`) | `capture/SKILL.md` | Capture and auto-clarify normally; at most one trailing tip, never an interrupting question | Ask before starting; repeat the tip on a later command in the same session |
| E28-model-unknown-and-once | Model information unavailable, two commands run in the same session; then `Model check: off` in `personalized.md` | any sub-skill | No model message when unknown; no repeated check on the second command in the same session; the override in `personalized.md` disables the check entirely | Guess a model and act on the guess; repeat the below-tier prompt on every command; ignore the `Model check: off` override |

## Automated checks

```bash
bash scripts/gtd_eval_check.sh
bash -n scripts/gtd_init.sh
bash -n scripts/gtd_env.sh
bash -n scripts/gtd_status.sh
bash -n scripts/gtd_review_prep.sh
bash -n scripts/gtd_review_prep_notify.sh
bash -n scripts/gtd_list.sh
bash -n scripts/gtd_check.sh
bash -n scripts/gtd_migrate_to_notes.sh
LLM_GTD_ROOT="$(mktemp -d)" bash scripts/gtd_init.sh --status
LLM_GTD_ROOT="$(mktemp -d)" bash scripts/gtd_init.sh --confirm-create --layout notes --with-bases
```

The privacy denylist is not written into this file; it comes from a private overlay or the runtime environment, so the general skill doesn't carry private terms itself.
