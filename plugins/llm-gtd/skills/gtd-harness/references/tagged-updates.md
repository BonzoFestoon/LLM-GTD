# Tagged-note updates

Companion to `list-definitions.md`, which holds the core rules. Read this when applying notes tagged `gtd-update` (`/gtd-update`).


An update can be written into **any note in the workspace** (a daily note on the phone, a project doc, an action note) and applied by the next `/gtd-update`, exactly as if it had been typed in chat.

```markdown
---
tags: [gtd-update]
---
…the note…

## Update
- Statements are downloaded, no problems
- Sam replied: the quote is approved
- Push the dentist tickle to December
```

- **The tag is the request**: `gtd-update` in frontmatter `tags:` (or `tag:`; flow list, block list or a single value) or an inline `#gtd-update` in the body — not inside code, and not a nested tag like `#gtd-update/later`. An `Update` section without the tag is ignored; a tagged note without one is reported and left alone.
- **The section**: a heading whose text is exactly `Update` (any level, any case), up to the next heading of the same or a higher level. Each non-empty line or bullet is one update.
- **Found by** `scripts/gtd_tagged.sh` (the whole workspace, minus hidden folders and `memory/gtd/_done/`); counted on the dashboard and in the review prep pack.
- **Targets**: what the line names; else the note itself when it is a GTD item; else the GTD item it links to (one link → that item).
- **Applied** through update's own rules: clear lines without asking, unclear lines asked once in a batch, a project close still confirmed once.
- **Finished** when every line is applied or answered: the tag is removed and the heading renamed `## Update (applied YYYY-MM-DD)` — kept as a record, never applied again. **Partly done**: the tag stays and each applied line gets ` ✓`, which the next run skips.
