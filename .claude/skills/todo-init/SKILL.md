---
name: todo-init
description: Scan the project and create initial TODO files organized by area
argument-hint: "[path to output dir, default todos/]"
---

# todo-init

Seed `<area>.md` files for this project, one per area. This skill is the source of truth for TODO file format.

`$ARGUMENTS` is the **directory to write them into**, relative or absolute, defaulting to `todos/` at the repo root
(e.g. `/todo-init packages/solver/todos`). Create it if it does not exist. If it already holds TODO files, read them
first and add only genuinely new items -- never overwrite or duplicate an existing one.

## Gather

Explore the code the output directory belongs to -- for `packages/solver/todos` that is `packages/solver`, not the whole
repo. Read its structure, source files, README, CLAUDE.md, and every `TODO`/`FIXME`/`HACK`/`XXX` comment (cite file and
line). Skim `git log` for recent activity, and pull open issues/MRs if a remote is configured. Also collect known bugs
and limitations mentioned in docs or comments, missing or thin test coverage, code-quality problems (dead code, unclear
naming, missing docs), and refactors worth doing.

Group findings by area, using names that match the project's own module and directory structure (`solver`, `api`, `cli`,
`infra`). One file per area -- **never create an empty file**.

Assign priorities: **P0** for bugs, broken functionality, and blockers; **P1** for missing features, significant
improvements, and tech debt that slows development; **P2** for minor and cosmetic improvements.

## File format

Three sections, in this order:

1. **Priority Summary table** at the very top -- every open item, highest priority first, with exactly three columns:
   `Task`, `Priority`, `Status`.
   - `Task` is a markdown link with link text `[#N](anchor)`, e.g. `[#5](#5-broken-cache-invalidation)`. No descriptions
     in the cell.
   - `Priority` is `P0` / `P1` / `P2`.
   - `Status` is `Pending` or `Blocked`. Newly seeded items are `Pending`. `Done` exists only transiently, while
     `/implement` and `/finalize` close an item out before removing it.
   - **Never** use HTML anchors (`<a id="5">`) -- invisible in plain markdown and unreliable in VS Code. **Never**
     strikethrough an item title -- change the `Status` instead.
2. **Suggested resolution order** -- a bullet list (not numbered, so removing a completed item forces no renumbering) of
   item numbers in recommended order with brief rationale per item: `- #5 -- prerequisite for #7`. Open items only.
3. **Detailed sections** -- one `###` heading per item with a clear description, the context and cited files/lines, and
   acceptance criteria wherever they can be stated.

A `Blocked` item stays in the file with a `_Blocked: <reason>_` line appended to its section. Resolved items are
**removed** entirely by `/finalize` once any affected docs are reconciled -- git history is the record, so there is no
`Done` ledger.

Run `npx prettier --write --print-width 120` on each file, then print a summary: files created **with their full
paths**, item counts, and priority breakdown. Mention that `/implement <path to one of these files>` is the next step.
