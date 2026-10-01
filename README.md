# LLM-GTD

**A portable GTD skill for LLM agents.**

Not a todo app. Not another productivity prompt. LLM-GTD is a trusted external system that lets
Claude Code, Cursor, and Codex help you capture, clarify, update, organize, choose, and review your work
without turning your life into a pile of half-processed tasks.

> The installable Codex plugin is named `llm-gtd`.
> The legacy skill package remains `gtd-harness` for Cursor and manual installs.

## See it in one example

You don't hand it a task — you hand it an **intention**:

> **You:** I want to help a family member try a class
> **LLM-GTD:** Makes it a **project**; first action → *"talk for 10 min — do they want to try it, what constraints matter, how often could this happen…"*. It does **not** enroll, schedule, or contact anyone.

A while later you report back:

> **You:** Talked it through — they are interested, two sessions/week, ~1h each
> **LLM-GTD:** Checks the talk off; **advances the project** to *"shortlist 2-3 options — slots, price, distance, trial terms"*; logs the facts as support material; flags your "~1h" as **needs-confirmation**.

A project with nothing in play (no next action, no waiting-for, no dated tickle) is a stalled promise. LLM-GTD keeps the promise **live across
days** — you supply judgment and report reality; it does the bookkeeping.
→ [full walkthrough](docs/demo.md)

## The Short Version

Most AI productivity workflows fail for the same reason most human GTD systems fail: the inbox fills,
the next action is vague, the project has no current move, and the weekly review gets skipped.

LLM-GTD gives the agent a skill-backed trusted system:

- plain Markdown state in `memory/gtd/`
- a full GTD workflow, not just inbox triage
- one `/gtd` router plus seven workflow commands: `init`, `capture`, `clarify`, `update`, `organize`, `engage`, `review`
- one shared trusted system across Claude Code, Cursor, and Codex
- automatic calendar-provider writes for complete schedule items, with fail-closed reporting

The model does what it is good at: drafting next actions, cleaning structure, spotting stale items,
and preparing reviews.

You keep what should stay human: commitment, priority, reflection, and final choice.

## Why This Exists

Public agent skills around GTD tend to fall into two buckets:

1. **Single workflow skills** such as inbox processing or weekly review.
2. **Broad Life OS / second-brain systems** that include GTD as one part of a larger personal OS.

Those are useful, but they often miss the hardest part: a durable trusted system that an agent can
maintain every day without scattering state across tools, chats, and half-written notes.

LLM-GTD is narrower and deeper. It turns GTD into a reusable agent skill:

```
LLM = judgment, language, drafting
Skill = state, workflow, cadence, adapter, safety boundary
```

David Allen gave us the operating system for commitments. LLM-GTD makes that operating system
agent-native.

## What It Does

| You want to... | Command | What happens |
|---|---|---|
| set up the trusted system | `gtd-init` | creates the eight GTD lists and checks wiring; legacy installs also refresh Codex slash prompts |
| capture a thought or task | `gtd-capture` | writes it to inbox first, then auto-clarifies small inputs |
| process inbox items | `gtd-clarify` | turns vague "stuff" into next actions, projects, waiting-for, reference, or someday |
| report progress or changes | `gtd-update` | closes completed actions, advances projects, handles waiting-for replies, updates calendar details, or corrects existing state |
| clean the system | `gtd-organize` | fixes mechanical drift: orphan actions, stalled projects, bad contexts, duplicates |
| decide what to do now | `gtd-engage` | suggests 3-5 context-fit next actions based on context, time, energy, and priority |
| run the weekly review | `gtd-review` | generates a read-only prep package, cleans mechanical drift, then reviews inbox/calendar/waiting/projects/horizons |
| which command should I use | `gtd-help` | read-only: every command with what it does, when to run it, and its recommended model; the day-to-day rhythm; one "right now" suggestion; and where things live |

The important design choice: **capture, clarify, and mechanical organize can be mostly automated;
engage and review stay human-led.**

## The Trusted State

LLM-GTD stores its operating state as plain Markdown in `memory/gtd/`. Each list that holds items is a folder with one note per item, its fields as YAML properties; the inbox, calendar fallback, and horizons are single files:

| Path | GTD list | Purpose |
|---|---|---|
| `memory/gtd/inbox.md` | Inbox | zero-friction capture sink, one line per item |
| `memory/gtd/next-actions/` | Next Actions | concrete single-step actions in an action pool, with time, energy, and real constraints |
| `memory/gtd/projects/` | Projects | one folder per outcome that needs more than one action: its README plus its support material |
| `memory/gtd/waiting-for/` | Waiting For | delegated or pending items, with person and agreement |
| `memory/gtd/tickler/` | Tickler | committed work that can't start until a date |
| `memory/gtd/someday-maybe/` | Someday/Maybe | things you do not commit to now but do not want to lose |
| `memory/gtd/calendar.md` | Calendar fallback | hard landscape only, used only when the real calendar is unavailable |
| `reference/` (workspace root) | Reference | non-actionable knowledge, one note per topic |
| `memory/gtd/horizons.md` | Horizons | purpose, vision, goals, areas, projects, and runway |

Each list folder has a `README.md` with its rules and note format. You never tag anything by hand: clarify fills the properties and organize repairs them. One note per item also means you can filter the lists in Obsidian, by time, energy, or context, on desktop or phone.

Finished work isn't deleted. It moves to a done record (`memory/gtd/_done/`) with a short outcome: what was done, what got in the way, and how you got past it. A finished project gets a brief after-action review first, then its whole folder moves there. The Weekly Review reads the done record, and no active list or dashboard count ever does.

No database. No hidden app state. No vendor lock-in. A file is a file.

To set it up:

```bash
bash <skill>/scripts/gtd_init.sh --confirm-create --with-bases
```

`--with-bases` adds optional Obsidian Bases lens views ("15 min or less", "Low energy", "Errands", "Done this week"). Nothing depends on them.

**Coming from LLM-GTD 1.x single-file lists?** Version 2.0.0 keeps one note per item only. If `memory/gtd/` still holds `next-actions.md`, `projects.md` and friends, every command stops and says so. Install 1.17.x, run its `scripts/gtd_migrate_to_notes.sh` (dry run, then `--apply` on a clean git tree), then upgrade.

**The tickler.** Some committed work can't start until a date: an account you can open only after a trade settles, a renewal you'll decide in March. That is neither someday/maybe (you've committed) nor waiting-for (nobody owes it to you). Clarify files it in `memory/gtd/tickler/`, one note per tickle with a `tickle:` date. A project linked from a tickle is on hold on purpose, so it is never reported as stalled. When the date arrives, organize turns a concrete project tickle into a next action and queues anything else in the inbox for clarify; engage lists what came due first, and the Weekly Review shows what's due, what's coming in the next 14 days, and each project on hold. The tickler is always local: it is never written to your external calendar. Organize flags a tickle whose date the calendar shows as blocked, and suggests another date.

## How It Works

LLM-GTD has four layers:

```
LLM
  does judgment, interpretation, next-action drafting

Skill package
  State      memory/gtd/*.md
  Logic      src/skill/SKILL.md + sub-skills
  Adapter    Claude Code commands, Cursor skill rules, Codex prompts
  Cadence    weekly review workflow and optional reminders
```

The same skill package and the same `memory/gtd/` state can be used from multiple agent surfaces:

| Platform | Front end | State |
|---|---|---|
| Claude Code | plugin `llm-gtd` (skill + `/gtd` + `/gtd-*`); or `.claude/commands/gtd*.md` (manual) | same `memory/gtd/` |
| Cursor | `.cursor/skills/gtd-harness/` plus keyword rules | same `memory/gtd/` |
| Codex | Codex plugin `llm-gtd`; legacy `~/.codex/prompts/gtd*.md` also works | same `memory/gtd/` |

## Why It Is Different

**It is a complete GTD loop, not an inbox prompt.**
Capture, clarify, update, organize, engage, and review are all first-class.

**It packages GTD as a skill, not a chatbot personality.**
The agent can be replaced. The state and workflow remain.

**It keeps knowledge and action separate.**
Actions go to GTD's action lists. Non-actionable knowledge and ideas go to `reference/` by default — point `personalized.md` at a separate note system (such as a Zettelkasten) instead if you run one.

**It uses AI where AI actually helps.**
Drafting a concrete next action, finding stale projects, and cleaning list structure are good AI jobs.
Choosing what you value and what you commit to are not.

**It fails closed around calendar writes.**
If external calendar provider is connected, it is the only hard landscape. Complete schedule items are written
to external calendar provider automatically; missing date/time/title fields are clarified first. If the tool
fails, LLM-GTD does not pretend anything happened.

## Install

### Install as a Claude Code plugin

This repo is also a Claude Code plugin marketplace. From Claude Code:

```text
/plugin marketplace add BonzoFestoon/LLM-GTD
/plugin install llm-gtd@llm-gtd
```

The bundled GTD skill auto-activates on GTD phrasing, and the `/gtd` router plus `/gtd-*` commands
(`/gtd`, `/gtd-init`, `/gtd-capture`, `/gtd-clarify`, `/gtd-update`, `/gtd-organize`, `/gtd-engage`, `/gtd-review`, `/gtd-help`) are added.
State is written to your **current workspace**'s `memory/gtd/` — never bundled with the plugin
(`${CLAUDE_PLUGIN_ROOT}` holds the read-only skill; your lists live in your project). Run `/gtd-init`
(or just ask) in the workspace where you want your GTD lists to live.

### Install as a Codex plugin

LLM-GTD now includes a repo-scoped Codex plugin package:

```text
.agents/plugins/marketplace.json
plugins/llm-gtd/
```

Add this repository as a Codex plugin marketplace, then install `llm-gtd` from the Codex
plugin directory:

```bash
codex plugin marketplace add https://github.com/BonzoFestoon/LLM-GTD.git
codex plugin add llm-gtd@llm-gtd
```

After installing the plugin, start Codex in the workspace where you want your GTD state to live and
ask it to use LLM-GTD:

```text
Set up my GTD trusted system
Capture and clarify this task: renew passport before summer
Run my weekly GTD review
```

The plugin writes user state only under that workspace's `memory/gtd/`. It does not bundle any
personal GTD state, and it does not include external calendar provider as an app or MCP server. If your Codex
environment already has external calendar provider available, LLM-GTD can use it as the real hard landscape;
otherwise it falls back to `memory/gtd/calendar.md`.

### Install with the legacy multi-surface installer

```bash
git clone <your-fork-url> LLM-GTD
cd LLM-GTD
./install.sh /path/to/your/vault
```

If you omit the vault path, the installer uses the current directory:

```bash
./install.sh
```

The installer copies:

- `src/skill/` to `<vault>/.cursor/skills/gtd-harness/`
- Claude Code commands to `<vault>/.claude/commands/`
- Codex prompts to `~/.codex/prompts/`
- the Codex orchestrator to `<vault>/.codex/agents/`
- the initial GTD state to `<vault>/memory/gtd/`

It also prints two optional manual wiring steps:

- merge `snippets/cursor-skill-rules.json` into your Cursor skill rules
- merge `snippets/AGENTS.routing.md` into your workspace `AGENTS.md`

### Using one canonical GTD folder across every project (optional)

By default, plugin installs write state to **whatever workspace you're currently in** — run
`/gtd-init` per project if you want separate lists per project. GTD only works with **one**
trusted inbox per person, though, so if you work across many projects and want every one of them
to resolve to the same GTD folder (instead of risking a second inbox getting created in some
other project's `memory/gtd/`), set `LLM_GTD_ROOT` once, in your shell profile, to the vault that
should hold your lists:

```bash
# ~/.bashrc or ~/.zshrc
export LLM_GTD_ROOT="$HOME/vaults/second_brain"
```

```powershell
# PowerShell $PROFILE
$env:LLM_GTD_ROOT = "$HOME\vaults\second_brain"
```

Every GTD script checks `LLM_GTD_ROOT` first, before falling back to the legacy install layout or
the current directory — so once it's set, `memory/gtd/` under that folder is the canonical
location from any project, and `init/SKILL.md`'s "one inbox per human" rule always resolves there
instead of asking you to bootstrap a new one. `gtd_init.sh --status` prints the resolved folder as
`Vault:` if you want to confirm it picked up correctly.

## Requirements

- Bash
- Python 3 for status/dashboard helpers
- Claude Code, Cursor, or Codex, depending on which surface you use
- Optional: external calendar provider access if you want real calendar reads and automatic writes

## Quick Start

Initialize:

```bash
./install.sh /path/to/your/vault
```

Then try one of these from your agent:

```text
/gtd-capture Renew passport before the summer trip
/gtd-clarify
/gtd-update I submitted the passport documents
/gtd-engage
/gtd-review
```

Natural-language triggers are supported by the skill prompts, for example:

```text
Help me clear my head.
Help me sort through these pending items.
I have 30 minutes right now. What should I do?
Run a weekly review.
```

You can also use `/gtd` as a general entry point. You do not have to pick a specific sub-command:

```text
/gtd Schedule coffee with Jack tomorrow afternoon at the Starbucks near my home.
```

Check the system state:

```bash
bash .cursor/skills/gtd-harness/scripts/gtd_status.sh
```

## Example Flow

You say:

```text
/gtd-capture Ask Mei about the school form, renew passport, maybe learn piano, save the tax PDF
```

LLM-GTD first captures everything, then clarifies what can be safely inferred:

- `Ask Mei about the school form` becomes a concrete next action or waiting-for item.
- `renew passport` becomes a project if it needs multiple steps.
- `maybe learn piano` goes to someday/maybe unless you commit to it.
- `save the tax PDF` goes to reference unless it implies an action.

If the agent cannot safely infer your commitment, it asks instead of pretending.

→ Full five-step walkthrough (capture → clarify → engage → review): [docs/demo.md](docs/demo.md).

## Repository Layout

```text
src/skill/            core GTD skill package
plugins/llm-gtd/      Codex plugin package generated from src/skill/
.agents/plugins/      repo-scoped Codex marketplace
scripts/              repository maintenance scripts
src/claude-commands/  Claude Code slash commands
src/codex-prompts/    Codex slash prompts
src/codex-agents/     Codex orchestrator agent
snippets/             optional routing snippets for Cursor and AGENTS.md
docs/design.md        architecture and design notes
docs/demo.md          a day-with-LLM-GTD walkthrough (the five steps)
install.sh            installer
CHANGELOG.md          project changelog
```

## Design Boundaries

- **The inbox is not the system.** It is only the capture sink.
- **A next action must be physical and concrete.** "Handle taxes" is not a next action. "Email CPA the W-2 PDF" is.
- **Projects must have something in play.** A current next action, a waiting-for, or a dated tickle. A project with none of them is a stalled promise.
- **Calendar is sacred.** Only time-specific commitments belong there.
- **Weekly review is not optional.** Without review, GTD decays into a task pile.
- **No hidden writes.** Calendar writes and other high-consequence actions need confirmation.
- **Knowledge is not action.** Notes, insights, and research belong in your knowledge system, not in `next-actions/`.

## Related Work

LLM-GTD was shaped by looking at existing public agent-skill patterns:

- [natea/ExoMind](https://github.com/natea/ExoMind/tree/main/skills) includes Life OS skills such as inbox processing, email inbox processing, and weekly review.
- [huytieu/COG-second-brain](https://github.com/huytieu/COG-second-brain) is a broader agentic second-brain system with capture and weekly check-in workflows.
- [openai/skills](https://github.com/openai/skills) shows the current Codex skill packaging pattern.

LLM-GTD is deliberately smaller than a Life OS and more complete than a single inbox skill. It is the
GTD commitment loop, packaged as a portable skill.

## Language

The README and the skill prompts are written in English, using David Allen's GTD terminology.

## License

MIT. See [LICENSE](LICENSE).
