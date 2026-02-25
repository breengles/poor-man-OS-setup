---
description: Analyze a TODO file, map dependencies, and produce a resolution plan
agent: build
---

Analyze a TODO file and produce a detailed resolution plan. The user provides a path argument: $ARGUMENTS

- If a path is provided (e.g. `todos/solver.md`), analyze that file.
- If an area name is provided (e.g. `solver`), analyze `todos/<name>.md`.
- If no argument is provided, list available files in `todos/` and ask which one to analyze.

Follow these steps:

1. **Read the TODO file** and understand every item -- its priority, description, and context.

2. **Deep-dive into the codebase** -- for each item, read the relevant source files to understand:
   - Current implementation state and how far it is from done
   - Dependencies between items (does fixing #3 require #1 first?)
   - Estimated complexity (small fix, medium refactor, large feature)
   - Risk and potential side effects of each change

3. **Map dependencies** -- identify which items block others, which can be parallelized, and which are independent. Note cross-area dependencies if they exist (items in other `todos/` files).

4. **Produce a resolution plan** -- present a clear, ordered plan:
   - **Dependency graph** -- which items depend on which (can be a simple list)
   - **Recommended resolution order** -- numbered list with rationale for ordering (dependencies first, then quick wins to build momentum, then larger efforts)
   - **Effort estimates** -- for each item: Small (< 1hr), Medium (1-4hrs), Large (4hrs+)
   - **Risk assessment** -- flag items that touch critical paths or have high regression risk
   - **Quick wins** -- highlight items that are low-effort and high-impact

5. **Update the TODO file if needed** -- if the analysis reveals:
   - New items not yet tracked (e.g. dependencies you discovered, prerequisite refactors), add them
   - Items that should be re-prioritized based on dependency analysis, update their priority
   - Items that are actually resolved or no longer relevant, remove them
   - Update the **Suggested resolution order** section to reflect your analysis

6. **Present the plan to the user** -- print the full analysis with the resolution order, effort estimates, and any changes made to the TODO file.
