---
name: todo-init
description: Scan the project and create initial TODO files organized by area
---

Initialize a TODO tracking system for this project. Follow these steps:

1. **Explore the codebase thoroughly** — read the project structure, source files, existing issues, AGENTS.md, README, and any existing TODO/FIXME/HACK/XXX comments in the code. Check git log for recent activity and open issues/MRs if a remote is configured.

2. **Identify areas** — group discovered items semantically by project area (e.g. `solver`, `api`, `ui`, `cli`, `tests`, `docs`, `infra`). Use names that match the project's own module/directory structure.

3. **Create `todos/<area>.md` files** — one file per area. Each file must follow the TODO file format from AGENTS.md:
   - **Priority Summary table** at the top with only open items sorted by priority (P0/P1/P2). Each row links to its detailed section heading.
   - **Detailed sections** below the table — one heading per item with a clear description, context, and acceptance criteria where possible.
   - **Suggested resolution order** at the bottom — a numbered list of item numbers in recommended tackling order with brief rationale.

4. **Populate from all sources** — include items from:
   - `TODO`, `FIXME`, `HACK`, `XXX` comments in source code (cite file and line)
   - Known bugs or limitations mentioned in docs/comments
   - Missing tests or incomplete test coverage you can identify
   - Code quality issues (dead code, unclear naming, missing docs)
   - Potential improvements or refactors you notice
   - Open issues/MRs from the remote if available

5. **Assign priorities** — use this scale:
   - **P0 (Critical)**: Bugs, broken functionality, blockers
   - **P1 (Important)**: Missing features, significant improvements, tech debt that affects development
   - **P2 (Nice-to-have)**: Minor improvements, cosmetic issues, optional enhancements

6. **Do NOT create empty files** — only create a `todos/<area>.md` if there are actual items for that area.

7. **Print a summary** at the end — list all created files with item counts and priority breakdown.
