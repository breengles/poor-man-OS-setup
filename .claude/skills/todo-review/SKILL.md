---
name: todo-review
description: Validate a TODO file's format, freshness, and readiness before implementation begins
argument-hint: "[area or path]"
---

Review a TODO file before running `/todo-implement` against it. This is a **read-only**
audit -- it does not edit the file. If it finds problems, the fix is either a manual
edit or a follow-up pass with your own judgement (no separate revise command exists).

## Determine scope

Parse `$ARGUMENTS`:

- If a path is provided (e.g. `todos/solver.md`), review that file.
- If an area name is provided (e.g. `solver`), review `todos/<name>.md`.
- If no argument is provided, **auto-resolve to the most recently modified file under
  `todos/`** (e.g. `ls -1t todos/*.md | head -n 1`). Announce the resolved area on a
  single line so the user can interject if they meant a different one. If `todos/` has
  no files, stop and report.

If the resolved file does not exist, stop and report.

**Read the target file in full** before starting the review. Also note any pre-existing
uncommitted changes via `git status --porcelain` -- recent changes may indicate items
that have just been resolved but not yet flipped to `Done`.

## Review checklist

Work through each section below. For every item, assign a verdict:

- **PASS** -- meets the bar.
- **WARN** -- non-blocking concern worth noting.
- **FAIL** -- must fix before implementation.

Cite specific evidence (item number, line reference, file path) for every WARN and FAIL.

### 1. Format compliance

- The file opens with a **Priority Summary table** that has exactly **three columns**:
  `Task`, `Priority`, `Status`.
- Each `Task` cell is a markdown link of the form `[#N](#n-slug)` pointing at the
  matching detailed section. No descriptions in the cell.
- Every link anchor resolves to an actual `### N. <title>` heading later in the file.
  Broken anchors are **FAIL**.
- No HTML anchors (`<a id="N"></a>`) anywhere -- they don't navigate in VS Code.
- No strikethrough (`~~text~~`) on item titles -- the `Status` column is the source
  of truth.
- Rows are sorted by priority (P0 -> P1 -> P2), all statuses (`Pending`/`Done`/`Blocked`)
  included.

### 2. Suggested resolution order

- A **Suggested resolution order** section exists directly after the Priority Summary table.
- It is an **unnumbered bullet list** (`-`), not a numbered list.
- It lists **only still-pending items**. Any `Done` item in this list is **FAIL** (it
  should have been pruned when the item was completed); any `Blocked` item is **WARN**
  (acceptable but usually noise).
- Every `Pending` item from the Priority Summary table appears at least once in the
  resolution order. Missing items are **FAIL**.
- Each bullet carries a brief rationale (e.g. `- #5 -- prerequisite for #7`). Bullets
  with no rationale are **WARN**.

### 3. Status freshness

For each `Pending` item, do a quick sanity check that the underlying work hasn't already
been done:

- If the detailed section cites a file/line for a `TODO`/`FIXME`/`HACK`/`XXX` comment,
  grep that file. If the marker is gone, the item is likely stale -- **WARN** with the
  evidence (file, line, what was expected vs. what's there).
- If the detailed section describes a bug or missing feature in concrete enough terms
  to spot-check, read the relevant code briefly and flag if the symptom appears already
  fixed. Stale `Pending` items are **WARN**, not **FAIL** -- they may be intentional.
- Also skim recent `git log --oneline -20` for messages that mention the item's area or
  scope. If a commit looks like it resolved an item that is still `Pending`, **WARN**.

Do **not** try to fix anything here -- only report findings.

### 4. Item quality

For every item in the file (regardless of status):

- The detailed section has a clear description of **what** needs to change and **why**.
- Acceptance criteria are present or the description is concrete enough to substitute
  (e.g. "remove unused import in foo.py:42" doesn't need a separate checklist).
- For code-cited items, the file path and line reference are still valid (file exists,
  line is close enough to original even if shifted). Dead references are **WARN**.
- `Blocked` items have a `_Blocked: {reason}_` line in their section. Missing reason
  is **FAIL** (the blocker isn't recoverable without it).
- `Done` items have a `_Done: ..._` completion note. Missing note is **WARN**.

### 5. Priority sanity

- P0 items have been `Pending` for a reasonable time -- if a P0 has been sitting since
  the file was initialized and no other work has been done in the area, **WARN** (either
  it's not actually P0 or the area is stuck).
- Priorities ordered correctly in the Priority Summary table (P0 rows above P1, P1
  above P2). Out-of-order rows are **FAIL**.
- No bare `P3` or other ad-hoc priorities -- the scale is P0/P1/P2 only. Extra
  priorities are **FAIL**.

### 6. Dependency consistency

- For every "X is a prerequisite for Y" claim in the resolution order, both X and Y
  exist in the Priority Summary table. Dangling references are **FAIL**.
- If the resolution order says `#5 -- prereq for #7`, then #5 should appear above #7
  in the order. Inverted dependencies are **FAIL**.
- Items marked `Blocked` should not be cited as prereqs without a note -- if #5 is
  Blocked and #7 depends on it, #7's bullet should acknowledge the block. Silent
  cross-block deps are **WARN**.

## Output format

For each section, list items with their verdict and a one-line note. Then provide:

1. **Summary verdict**: READY (all pass, or only warns) / NEEDS REVISION (any fails).
2. **Fails to fix**: each FAIL with a specific, actionable suggestion (e.g. "anchor
   `#3-cache-fix` does not resolve -- rename the heading or update the link").
3. **Warns to consider**: each WARN briefly.

Be direct and specific. Do not pad with praise or filler. Do not edit the TODO file --
hand the report back to the user and let them decide what to fix.
