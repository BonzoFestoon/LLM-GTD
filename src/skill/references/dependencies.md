# Dependencies

Companion to `list-definitions.md`, which holds the core rules. Read this when filing a step that has to wait for another one, when something another item depends on is completed or cancelled, or when `gtd_check.sh` reports a `depends-*` finding.

A dependency lets a next action be written down before it can be done, without it cluttering the lists: it stays out of the action pool until what it waits on is finished, then shows up on its own. The lists still hold only what can be done now.

## The property

`depends_on:` sits only on the item that waits, as a YAML list of quoted links, even for one:

```yaml
depends_on:
  - "[[next-actions/Get the county tax bill|Get the county tax bill]]"
  - "[[projects/Tastytrade broker service/README|Tastytrade broker service]]"
```

There is no reverse property. What an item blocks is found by searching for links to it: `gtd_list.sh next-actions --depends-on "<title>"` (or `projects --depends-on`), or the note's backlinks in Obsidian. Storing both directions would leave two copies to drift apart.

| The item that waits | May wait on | Meaning while blocked |
|---|---|---|
| Next action | next actions, waiting-for items, projects | Left out of `gtd_list.sh next-actions`, so Engage never offers it |
| Project | next actions, waiting-for items, projects | On hold: in play, never stalled, and organize drafts no next action for it |

Not allowed:
- **Waiting-for items and tickles can't wait on anything.** A waiting-for item is already in someone's hands, and a tickle already waits on its date. Put the dependency on the next action that has to wait.
- **Some things can't be a dependency**, because they never finish once and for all: a tickle (if the wait is really for a date, file the action as a tickle instead), a someday item, a reference note, a project's support doc (link the project's README), a routine's cycle (an action with `from:`), and the note itself.

Dependencies may cross projects. Write a blocked step as a concrete next action, in the same shape as any other, but only when the order is real ("after X, do Y"). Milestones and long plans still go in a document in the project's folder, not as long chains of blocked actions.

## When it is done

Each link resolves to one state (`gtd_dep_state` in `scripts/gtd_env.sh`):

| State | When | Effect |
|---|---|---|
| open | the target is in `next-actions/`, `waiting-for/` or `projects/` | the item stays blocked |
| done | the target is in `_done/` with any result but `cancelled` | satisfied |
| cancelled | the target is in `_done/` with `result: cancelled` | broken |
| missing | the target is nowhere (a cancelled standalone action is deleted) | broken |
| bad target | the target can't be a dependency (see above) | broken |

An item is **blocked** while any link is open, and **broken** when any link is cancelled, missing or a bad target, or when `depends_on:` holds no link at all. A broken item is left out of the action pool too, until organize asks what to do. Once every link is done, the item is unblocked. Nothing needs to change in the note for that: the `depends_on:` stays as a record.

A target is looked for where its link says first, then by its title in the other places, so a link not yet rewritten after a move still resolves.

## When a dependency finishes

- **Completed** (update's done step): after moving the item to `_done/`, find what waited on it (`gtd_list.sh next-actions --depends-on "<title>"`, and the same for `projects`), rewrite each of those links to `[[_done/<Title>|<Title>]]` (a project: `[[_done/<Name>/README|<Name>]]`), and report "Now unblocked: …" for each item with nothing left open. Project close already rewrites links this way. A newly unblocked action missing time / energy / context gets them from organize, as any other action does.
- **Cancelled**: once, ask what to do with the items that waited on it: drop the dependency, cancel them too, or link what replaces it. Never decide this automatically.

## Organize's findings

| Finding | What organize does |
|---|---|
| `depends-done-link` | Rewrites the link to its `_done/` path (automatic) |
| `depends-cancelled`, `depends-missing` | Asks, in the batch: drop the dependency, cancel this too, or link what replaces it |
| `depends-target`, `depends-form` | Asks, in the batch, with the suggested fix |
| `depends-cycle` | Asks which of the items should go first, then drops that one's link |
| `depends-hold` | Asks whether the project is really on hold, since it still has actions it can do now |

## Projects in play

A next action waiting on an open item still counts toward its project being in play: something is moving, just not this step yet. One with a broken link doesn't. A project whose own `depends_on:` is open is on hold, like a project held by a one-shot tickle. A project whose dependency is broken is judged by the usual rule (`references/done-record.md` "Stalled projects").
