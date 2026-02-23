---
name: docs-analyze
description: Analyze existing project documentation for accuracy, completeness, and staleness
argument-hint: "[component or path]"
---

Analyze existing project documentation and produce a detailed quality report. The user may provide an optional scope argument: $ARGUMENTS

**Determine scope:**

- If a path is provided (e.g. `docs/api.md`), analyze that file.
- If a component name is provided (e.g. `api`, `auth`), analyze `docs/<name>.md`.
- If no argument is provided, analyze ALL files in `docs/`.
- If no `docs/` directory exists, inform the user and suggest running `/docs-init` first.

Follow these steps:

1. **Inventory existing documentation** — list all files in `docs/`, their sizes, and last-modified dates (`git log --oneline -1 -- <file>` for each).

2. **Read each documentation file** in scope and understand what it claims to document — which modules, APIs, configurations, and behaviors it describes.

3. **Read the actual source files** that each doc references — systematically compare documented content against the real code. For every claim the doc makes, verify it against the source.

4. **Check recent code changes** — for each documented component, run `git log --oneline -20 -- <relevant source paths>` and compare against `git log --oneline -1 -- <doc file>` to identify code changes that happened after the doc was last updated.

5. **Evaluate each doc file on these dimensions:**
   - **Accuracy** — are the documented APIs, functions, behaviors, and examples correct? Flag anything that contradicts the current code.
   - **Completeness** — are there modules, endpoints, classes, or features in the code that the doc fails to mention? Are there entirely undocumented components?
   - **Staleness** — how much has the code changed since the doc was last updated? Quantify: number of commits to source since last doc update.
   - **Structural quality** — does the doc follow the project's documentation conventions? Are sections well-organized, scannable, and properly formatted?
   - **Cross-references** — are links to other docs, file paths, or external resources still valid?

6. **Identify undocumented components** — scan the codebase for modules or subsystems that have no corresponding documentation file at all.

7. **Produce an analysis report** — print a clear summary:
   - **Per-file scorecard** — for each doc file, rate Accuracy / Completeness / Staleness (Good / Needs Update / Stale) with a one-line rationale
   - **Critical issues** — list specific inaccuracies or outdated content that could mislead readers (highest priority)
   - **Coverage gaps** — list components or features that exist in the code but have no documentation
   - **Staleness ranking** — order doc files from most stale to least stale, with commit counts
   - **Recommended actions** — a prioritized list of what to fix first (critical inaccuracies > coverage gaps > minor staleness)

8. **Do NOT modify any files** — this is a read-only analysis. Suggest running `/docs-revise` to apply fixes.
