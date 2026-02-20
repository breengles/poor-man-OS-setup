---
name: todo-revise
description: Revise existing TODO files — optionally pass a path or area name to scope
argument-hint: "[area or path]"
---

Revise existing TODO files for this project. The user may provide an optional path argument: $ARGUMENTS

**Determine scope:**

- If a path argument is provided, revise only that specific file (e.g. `todos/solver.md`).
- If the argument is an area name without a path (e.g. `solver`), revise `todos/<name>.md`.
- If no argument is provided, revise ALL files in `todos/`.

For each TODO file in scope, follow these steps:

1. **Read the existing TODO file** and understand all current items.

2. **Scan the codebase for changes** — check recent git history (`git log --oneline -20`), current `git diff`, and search for new or removed `TODO`/`FIXME`/`HACK`/`XXX` comments in the source code relevant to this area.

3. **Check open issues/MRs** from the remote if available — look for newly opened or recently closed items that relate to this area.

4. **Update the file:**
   - **Remove resolved items** — if a TODO item has been addressed (code fixed, feature implemented, issue closed), delete it from both the Priority Summary table and the detailed sections entirely. Do NOT keep a "Resolved" section.
   - **Add new items** — if you find new TODOs, bugs, or improvements not yet tracked, add them with appropriate priority and detail.
   - **Re-prioritize** — adjust priorities if the situation has changed (e.g. a P2 became a blocker, or a P1 is now less urgent).
   - **Update descriptions** — refine descriptions if you now have better context or if the scope of an item has changed.
   - **Rebuild the Suggested resolution order** — reorder based on current state (dependencies, quick wins, urgency).

5. **Maintain format** — ensure the file still follows the TODO file format from AGENTS.md: Priority Summary table at top (with markdown links to headings), detailed sections, suggested resolution order at bottom.

6. **Delete empty files** — if all items in a file are resolved, delete the file entirely.

7. **Print a summary** of changes — list which items were added, removed, or re-prioritized in each file.
