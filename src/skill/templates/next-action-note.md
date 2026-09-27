---
id: na-short-id-YYYYMMDD
time: 10            # minutes, number
energy: low         # low | medium | deep | low-emotional
context: [computer] # real constraints: computer, phone, errands, home, person-present, prep-chain, payment, documents…
project: "[[projects/Project name]]"   # optional — omit for a standalone action
due: YYYY-MM-DD     # optional, only for a real deadline
source: inbox capture
created: YYYY-MM-DD
---
Concrete, verb-first action text (confirm / send / call / write — no vague verbs like "follow up / handle / research").
Constraint: the free-text detail behind the context tags above (needs computer, tax bill / account number, payment method, etc).

<!--
No new vocabulary: these are exactly the fields the single-file next-actions.md line already carries.
A note with no properties filled in is still a valid action — clarify fills them, organize repairs missing or invalid ones, the user never tags anything.
`context` holds only the lens values Engage already uses, not a free-form tag system.
Filename: short, verb-first, filesystem-safe (no : / \ ? * " < > |); add "(2)" on a collision. The old block id stays traceable as `id:`.
See references/list-definitions.md's "Note formats" section for the full contract, and the Obsidian link rules for how other notes should link to this one.
-->
