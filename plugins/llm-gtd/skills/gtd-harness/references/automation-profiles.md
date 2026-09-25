# GTD Automation Cadence Profiles

> Purpose: turn reusable GTD cron/automation into a few trusted cadences, not a forest of background tasks.
> By default `gtd_init.sh` only does a read-only check; when the user explicitly requests `--install-cron`, the current agent / platform automation tool creates or updates them — the shell never hand-writes automation files.

## Install principles

1. **Explicit creation**: create or update background tasks only when the user says "install / initialize GTD cron" or uses `--install-cron`.
2. **Tool creation**: in Codex you must call `automation_update`; never write `~/.codex/automations` directly.
3. **Low frequency first**: install Weekly Review and Monthly Reflect by default; Daily Engage, as the engage entry point, is installed / updated together with `--install-cron`.
4. **One default entry per kind**: for Daily Engage, if a morning or evening entry already exists, reuse it; if neither exists, create the morning entry by default, so the system doesn't interrupt the user twice a day.
5. **Offer a menu, never commit for the user**: no automation cadence may auto-schedule ordinary next actions into the calendar, or present 3-5 candidates as today's commitments.
6. **Approval Radar scans read-only**: it may detect approval status changes, pending confirmations, and stuck items relevant to the current user, but may never automatically approve, reject, withdraw, remind, or cc.

## Profile overview

| Profile | Recommendation | Example id | Purpose | Boundary |
|---|---|---|---|---|
| Weekly Review | Recommended | `gtd-ai` | A true AI-judged review once a week: system trustworthiness, structural issues, next week's 3 things, capacity conflicts, follow-up messages | Never auto-delete, cut projects, send messages, write to the calendar, or make high-consequence commitments for the user |
| Monthly Reflect | Recommended | `gtd-2` | Monthly review of someday-maybe, product-ideas, horizons, and the next 30 days' capacity | Uses Reflect vocabulary, not organize; only suggests activate / keep / delete / add information |
| Daily Engage + Approval Radar | Installed / updated with `--install-cron` | `gtd` / `gtd-engage` | A light daily choice of "how to use the first block of time now / tonight / tomorrow morning", with Approval Radar | Not a daily review; never fully re-scans projects/someday/product-ideas/horizons |
| Session Clarify | Advanced, optional | `gtd-session-clarify` | Scan sessions for real commitments and clarify / file them | Session-provider specific; high frequency and wide scan surface, not part of init's default suggestions |

## Daily Engage + Approval Radar standard boundary

Daily Engage is Allen's Engage, not Review. It answers only "how to use the next block of time", outputting a small candidate menu.

Must do:
- Read the hard landscape: prefer the preferred calendar provider; if unreachable, fall back along the fallback provider chain; if all are unreachable, read `calendar.md` and state the limitation.
- Compute the current / first available time window; if it conflicts with the time the user states, use the smaller one.
- Filter the action pool by the four criteria: context / time / energy / priority.
- Scan Approval Radar: keep only approval items needing action or with status changes; if none, write "no approval actions today".
- Output a capacity judgment: green / yellow / red; when overloaded, only suggest delete, defer, delegate, downgrade.

Must not do:
- Never cram ordinary next actions into the calendar automatically.
- Never mistake approval passed for payment received; real completion is still payment received, delivery, or the user-defined loop closure.
- Never automatically approve, reject, withdraw, remind, or cc.
- Never treat an Approval Radar failure as a failure of the whole Engage; if read-only permission is missing, state the gap and finish Engage.

## Approval Radar checks

When the runtime has an approval provider capability, Daily Engage reads the corresponding approval provider adapter and does a read-only scan:

1. First check whether the approval provider adapter is available; never output tokens or secrets.
2. Scan approvals submitted by the current user, focusing on in-progress instances and approval ids recorded in GTD `waiting-for.md` / `reference.md`.
3. Scan approvals submitted by others that need the current user's confirmation; if read-only permission is missing, report the gap only and never attempt to authorize automatically.
4. If an approval status change affects GTD truth, you may conservatively update waiting-for/reference: e.g. from "waiting for approval" to "check payment received on the agreed date"; but never treat an intermediate state as done.

## init rules

`gtd_init.sh --status` only reports the install status of these profiles:
- Weekly Review
- Monthly Reflect
- Daily Engage (morning or evening)

If the user says "install the GTD automation cadence / create cron / install as suggested" or passes `--install-cron`, create or update the corresponding automation per this file. Default install order:
1. Weekly Review
2. Monthly Reflect
3. Daily Engage + Approval Radar (if not chosen, reuse the existing local daily engage; with no existing entry, create the morning entry)

Session Clarify is not in the default install sequence; install it only when the user explicitly wants to "scan Codex sessions automatically / organize session commitments daily".

## Codex creation rules

When `gtd-init` runs `--install-cron` in Codex:

1. First read the existing automation toml files, matching `gtd-ai`, `gtd-2`, `gtd`, `gtd-engage`, to avoid creating duplicates.
2. Update existing profiles with `automation_update`, preserving their enabled state, model, and workspace, unless the profile itself needs key prompt boundaries added.
3. Create missing Weekly Review / Monthly Reflect / Daily Engage with `automation_update`.
4. After creating or updating, run `gtd_init.sh --status` to confirm init can see the status.
5. Don't show the underlying schedule strings; describe the cadence name, whether it's installed, and whether it's active in plain language.
