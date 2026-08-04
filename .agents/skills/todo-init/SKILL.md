---
name: todo-init
description: Scan a project and create structured TODO files grouped by area in a user-provided output directory.
---

# TODO Init

Treat the user-provided path as the relative or absolute output directory,
defaulting to `todos/` at the repository root. Create it when absent. If it
already contains TODO files, read them first and add only genuinely new items;
never overwrite or duplicate existing work.

Infer project scope from the output directory: `packages/solver/todos` belongs
to `packages/solver`, not automatically to the whole repository. Inspect that
project's structure, source, README, applicable `AGENTS.md`, open
`TODO`/`FIXME`/`HACK`/`XXX` markers, recent history, and configured remote issues
or merge requests. Include evidenced bugs, limitations, missing functionality,
important test or documentation gaps, and worthwhile refactors. Cite paths and
lines and group findings by existing project area. Never create an empty file.

Assign `P0` to bugs, blockers, and broken behavior; `P1` to missing features,
significant improvements, or costly debt; `P2` to minor improvements.

Each `<area>.md` contains, in order:

1. A Priority Summary table with exactly `Task`, `Priority`, and `Status`, sorted
   by priority. Task cells are links such as `[#5](#5-title)`. Persistent status
   is `Pending` or `Blocked`; `Done` is transient during closeout.
2. An unnumbered Suggested resolution order containing open items only.
3. One `###` section per item with a clear problem statement, evidence and
   context, and observable acceptance criteria.

A blocked section ends with `_Blocked: <reason>_`. Do not use HTML anchors or
strikethrough. `$finalize` removes completed items after documentation is
reconciled; Git history is the record.

Run `npx prettier --write --print-width 120` on every created or updated file.
Report full paths, counts, and priority breakdown, then suggest
`$implement <path to one TODO file>`. Do not commit.
