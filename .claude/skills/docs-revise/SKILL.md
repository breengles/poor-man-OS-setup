---
name: docs-revise
description: Revise existing documentation to match current codebase state
argument-hint: "[component or path]"
---

Revise existing project documentation to reflect the current state of the codebase. The user may provide an optional scope argument: $ARGUMENTS

**Determine scope:**

- If a path argument is provided (e.g. `docs/api.md`), revise only that file.
- If a component name is provided (e.g. `api`, `auth`), revise `docs/<name>.md`.
- If no argument is provided, revise ALL files in `docs/`.

For each documentation file in scope, follow these steps:

1. **Read the existing documentation file** and understand what is currently documented.

2. **Read the actual source files** that the doc describes — compare documented behavior against the real code to find discrepancies.

3. **Check recent changes** — run `git log --oneline -30 -- <relevant source paths>` to see what has changed since the docs were last updated. Also run `git log --oneline -5 -- <doc file>` to see when the doc itself was last modified.

4. **Identify discrepancies and gaps:**
   - **Stale content** — APIs, functions, classes, or behaviors documented but no longer present in the code
   - **Undocumented additions** — new modules, endpoints, functions, or features added to the code but not yet in the docs
   - **Incorrect descriptions** — behavior that has changed since the doc was written
   - **Missing context** — new design decisions or rationale that should be added
   - **Broken references** — file paths, line numbers, or links that no longer point to the right place
   - **New components** — entirely new modules or subsystems that need their own doc file

5. **Update the documentation:**
   - Remove references to deleted/removed code
   - Add documentation for new APIs, modules, features, or configuration
   - Correct any inaccurate descriptions or examples
   - Update file structure sections if files were added, removed, or renamed
   - Update dependency lists if new libraries or services were added
   - Refresh code snippets if the actual implementation has changed
   - Update API/interface tables to match the current signatures

6. **Update `docs/README.md`** if the revision scope includes it or if component docs were added/removed:
   - Ensure the index links are correct and complete
   - Update component descriptions if their scope changed
   - Update setup/build/test instructions if they changed

7. **Delete obsolete docs** — if a component was entirely removed from the project, delete its documentation file and remove it from the index.

8. **Create missing docs** — if you discover a component that exists in the code but has no documentation file at all, create one following the same structure as `docs-init`.

9. **Format with Prettier** — after modifying each markdown file, run `npx prettier --write <file>`.

10. **Print a revision summary** at the end:
    - Files updated (with a brief list of what changed in each)
    - Files created (new docs for previously undocumented components)
    - Files deleted (docs for removed components)
    - Items that could not be automatically resolved (ambiguities, questions for the user)
