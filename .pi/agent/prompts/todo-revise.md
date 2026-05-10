---
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
   - **Mark resolved items as `Done`** — if a `Pending` TODO item has been addressed (code fixed, feature implemented, issue closed) since the last update, flip its `Status` column from `Pending` to `Done` and append a brief `_Done: ..._` completion note to its detailed section (e.g. `_Done: handled in commit abc1234, no tests added_`). Do **not** delete the row or the detailed section. Items that are no longer relevant should also be marked `Done` with a note like `_Done: no longer applicable -- {reason}_`.
   - **Add new items** — if you find new TODOs, bugs, or improvements not yet tracked, add them with appropriate priority and detail.
   - **Re-prioritize** — adjust priorities if the situation has changed (e.g. a P2 became a blocker, or a P1 is now less urgent). Update the row's `Priority` column and resort the Priority Summary table accordingly.
   - **Update descriptions** — refine descriptions if you now have better context or if the scope of an item has changed.
   - **Rebuild the Suggested resolution order** — reorder based on current state (dependencies, quick wins, urgency). List only still-pending items; drop any items that just flipped to `Done`.

5. **Maintain format** — ensure the file still follows the TODO file format from CLAUDE.md: Priority Summary table at top (three columns: `Task` link `[#N](anchor)`, `Priority`, `Status` — rows sorted by priority, all statuses tracked), suggested resolution order (pending items only), and detailed sections at the bottom (kept for `Done` and `Blocked` items too).

6. **Never delete the TODO file** — even if every item is now `Done`, keep the file in place as a historical record.

7. **Print a summary** of changes — list which items were marked `Done`, added, or re-prioritized in each file.
