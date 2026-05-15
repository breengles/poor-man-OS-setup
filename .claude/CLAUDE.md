# Personal Preferences

## Safety

NEVER use destructive commands without explicit user approval. The following are **absolutely forbidden**:

- `rm -rf` (or any recursive force-delete)
- `git push --force` / `git push --force-with-lease`
- `git pull --force`
- `git reset --hard`
- `git checkout .` / `git restore .` (discarding all changes)
- `git clean -f`
- `git branch -D` (force-delete branch)

If a task seems to require one of these, stop and ask the user first.

## Python

Always use `uv` (https://docs.astral.sh/uv/) for Python project management instead of pip, venv, conda, poetry, or pipenv.

### Style

- Type-annotate all function signatures (params + return); skip local variables.
  Use modern syntax: `str | None`, `list[int]` (not `Optional`, `List`).
  **Exception - pyrallis dataclasses:** pyrallis does not support expression-style unions
  (`X | Y`) in dataclass field annotations. Use `Optional[X]` and `Union[X, Y]` from `typing`
  instead when defining pyrallis CLI config dataclasses.
- No `from __future__ import annotations`
- Data modeling: Pydantic for services/APIs, dataclasses for internal, dataclasses + pyrallis for CLI apps
- Logging: stdlib `logging` (or `loguru` if project already uses it)
- Paths: always `pathlib.Path`, never `os.path`
- Strings: f-strings for all interpolation
- Docstrings: Google style (`Args:`, `Returns:`, `Raises:`); skip for trivial code

### Type checking

- Always invoke pyright via `uv run pyright <files>` so it picks up the project's `.venv`.
- Treat LSP/IDE import errors as suspect when the symbol is widely used elsewhere in the repo or
  exists in `.venv` - re-verify with `uv run pyright` before "fixing" the import.
- For projects without a `pyrightconfig.json` / `[tool.pyright]` block, prefer adding one
  (`venvPath = "."`, `venv = ".venv"`) over relying on the `uv run` prefix.

## Code and Comments

- **No Unicode symbols in code or comments.** Use plain ASCII equivalents instead.
  Examples: `*` not `·`, `->` not `→`, `>=` not `≥`, `<=` not `≤`, `!=` not `≠`,
  `sum(...)` or `\sum` not `∑`. Wrong: `# g·f + f·g = 2∫gf dr` - Right: `# g * f + f * g = 2 * \int gf dr`

## Markdown

- After editing or creating any markdown file (`.md`), always run `npx prettier --write --print-width 120 <file>` to format it before committing.

## Pre-commit Hooks

- If the project has a `.pre-commit-config.yaml`, run `pre-commit run` (staged files only) and fix any issues before committing.

## Git Commits

- Never include issue IDs or numbers (e.g. `#5`, `#123`) in commit messages - GitLab interprets
  `#N` as an issue reference and may auto-close issues unintentionally.

## Git Worktrees

Apply this rule **only when the user explicitly asks to create a new branch** (e.g. "create a
branch for X", "start a new branch and implement Y", "cut a branch off main and ..."). In that
case, do the work in a dedicated git worktree instead of creating the branch in the current
checkout - dispatch an agent with `isolation: "worktree"` (or run `git worktree add` explicitly)
so the main checkout stays untouched.

Do **not** apply this rule for plain "implement X" / "fix Y" / "refactor Z" requests that don't
mention a new branch - keep working in the current checkout as usual.

- **Location convention:** `<project-name>.worktrees/<project-name>-<sanitized-branch-name>`, placed as a sibling of the main repo directory (i.e. `../<project-name>.worktrees/<project-name>-<sanitized-branch-name>`).
- **Project name:** the basename of the main repo directory (e.g. for `/Users/artem/poor-man-OS-setup` the project name is `poor-man-OS-setup`).
- **Sanitized branch name:** replace every `/` in the branch name with `-` (e.g. `feat/new-thing` -> `feat-new-thing`). Keep all other characters as-is.
- **Example:** branch `feat/worktree-flow` in repo `poor-man-OS-setup` -> worktree path `../poor-man-OS-setup.worktrees/feat-worktree-flow`.
- Always create the worktree from the latest `main` from remote if it exists, otherwise use local `main` (or the explicitly requested base branch).
- When the work is done and merged/abandoned, clean up with `git worktree remove <path>` - never delete the directory manually.

## Spec-Driven Development (SDD)

### Spec structure

Specs live in `specs/<feature-name>/` with up to four files:

1. `requirements.md` -- What & why. EARS-format acceptance criteria (see below). Carries the
   spec's lifecycle frontmatter (see "Spec lifecycle").
2. `design.md` -- How. Architecture, data flow, key decisions.
3. `tasks.md` -- Ordered implementation checklist with checkboxes (see format below).
4. `research.md` (optional) -- Rejected alternatives, trade-offs, constraints discovered during design. Valuable when "why not X" matters (e.g. ML architecture choices).

Two repo-level files complement the per-feature directories:

- `specs/constitution.md` (optional) -- non-negotiable project principles that every spec is
  bound by (see "Project constitution").
- `specs/INDEX.md` (maintained) -- one-line entry per spec with status, dates, and a short
  summary, so the active vs. completed surface is visible at a glance (see "Spec lifecycle").

### Project constitution (optional)

A repo can declare immutable engineering principles in `specs/constitution.md`. When present,
it acts as a compile-time gate for every spec: `spec-init` reads it before drafting,
`spec-review` checks the design against it, and `spec-implement` passes it to every
implementer and reviewer subagent as binding context alongside `design.md`.

Good constitution entries are short, numbered, and testable. Examples:

- `1. Every public function is type-annotated; CI runs pyright in strict mode.`
- `2. No new top-level dependencies without a one-paragraph rationale in research.md.`
- `3. Integration tests must hit a real database, not a mock.`
- `4. CLIs accept --json and exit non-zero on failure.`

The constitution is **not** a style guide. Style lives in CLAUDE.md and lint configs. The
constitution captures architectural non-negotiables that should outlive any single spec.

A spec is allowed to violate a constitution principle only if `design.md` (or `research.md`)
explicitly names the principle and justifies the deviation. `spec-review` should call out
unjustified deviations as FAIL.

### Requirements format (EARS)

Write acceptance criteria using EARS patterns -- each requirement gets a numeric ID
and one of these forms:

- **Event-driven:** `When [event], the [system/component] shall [action].`
- **State-driven:** `While [condition], the [system/component] shall [action].`
- **Unwanted behavior:** `If [trigger], the [system/component] shall [action].`
- **Optional feature:** `Where [feature is included], the [system/component] shall [action].`
- **Ubiquitous:** `The [system/component] shall [action].`

Use concrete component names (e.g. "the training loop", "the API gateway"), not generic
"the system". Each requirement must be testable and describe a single behavior.

**Ambiguity markers.** When drafting requirements (or design), mark unresolved questions
inline with `[NEEDS CLARIFICATION: <what is unclear>]` rather than guessing or writing a
plausible-but-fictional default. Examples:

- `1.3 When a token expires, the API gateway shall return a [NEEDS CLARIFICATION: 401 or 419?] response.`
- `2.1 The eval harness shall checkpoint every [NEEDS CLARIFICATION: every N steps or every N minutes?] iterations.`

These markers make ambiguity legible to humans and to downstream agents. `/spec-review` treats
any remaining `[NEEDS CLARIFICATION: ...]` marker in `requirements.md` or `design.md` as a
FAIL: the spec is not ready for implementation until every marker is resolved (either by
filling in the answer or by explicitly descoping the requirement).

### Spec lifecycle

Each `requirements.md` carries a small YAML frontmatter block describing the spec's state:

```yaml
---
status: active # active | completed | superseded
started: 2026-05-15 # ISO date the spec was bootstrapped
finalized: # ISO date when /spec-finalize closed it; blank while active
supersedes: # optional kebab-case name of a prior spec this replaces
---
```

States:

- `active` -- the spec is being designed or implemented. `tasks.md` may still mutate.
- `completed` -- every task is `Done`, `/spec-finalize` has been run, the design + requirements
  are frozen. New related work creates a **new spec** with `supersedes: <this-spec>`, rather
  than re-opening this one.
- `superseded` -- a later spec replaced this one. The directory stays in git as history.

The repo-level `specs/INDEX.md` is a simple table listing every spec, its status, the start
and finalize dates, and a one-line summary -- updated by `spec-init` on creation and by
`spec-finalize` on closure:

```markdown
# Specs Index

| Spec                            | Status     | Started    | Finalized  | Summary                       |
| ------------------------------- | ---------- | ---------- | ---------- | ----------------------------- |
| [token-refresh](token-refresh/) | active     | 2026-05-15 | --         | Rotate JWT tokens server-side |
| [eval-harness](eval-harness/)   | completed  | 2026-03-01 | 2026-04-12 | Nightly model eval pipeline   |
| [legacy-auth](legacy-auth/)     | superseded | 2025-09-10 | 2026-02-01 | Replaced by token-refresh     |
```

Once a spec is `completed`, its files are **immutable history**, not editable plans. Bug
fixes against the implementation do not retroactively edit the spec; substantive scope
changes create a new spec that supersedes it. Do **not** delete completed specs -- the
EARS requirements and design rationale are valuable context for future agents reading
the resulting code.

### Task format

`tasks.md` has three sections:

1. **Task Summary table** -- exactly **two columns**: `Task` and `Status`.
   - `Task` is a markdown link to the detailed section, with the link text as `[#N](anchor)`
     where `N` is the task ID (e.g. `[#1](#1-add-token-validation)`, `[#2.3](#23-...)`).
     Do not put descriptions in the cell -- those live in the detailed section.
   - `Status` is one of `Pending`, `Done`, or `Blocked`.
   - Use standard markdown heading slugs for the anchors. **Never use HTML anchors**
     (`<a id="N"></a>`) -- they are invisible in plain markdown and don't navigate
     reliably in VS Code. **Never use strikethrough** (`~~text~~`) -- update the
     `Status` column instead.
2. **Suggested Resolution Order** -- unnumbered (bullet) list of task IDs with brief rationale, e.g.
   `- 1.1 -- foundation, no deps`. Use bullets, not a numbered list, so removing a completed
   task doesn't force renumbering.
3. **Detailed Tasks** -- one `###` heading per task with full description, files to modify, acceptance criteria checklist, and metadata.

Each task should include:

- **Requirements traceability:** end each task with `_Requirements: 1.1, 2.3_`
  (numeric IDs from `requirements.md`) so nothing gets orphaned.
- **Parallel markers:** append `(P)` to tasks that have no dependency on the
  immediately preceding task. Add `_Boundary: ComponentName_` to confirm
  non-overlapping scope. Default: tasks are sequential (order implies dependency).
- **Dependencies:** capture cross-task prerequisites as `_Depends: 1.1, 1.2_` in
  the detailed section (since the table no longer has a `Depends on` column).
- **Completion notes:** when a task is marked `Done`, append a brief note on
  what was done and what was tested in the detailed section. Helps when resuming
  across sessions.

Example:

```markdown
## Task Summary

| Task                          | Status  |
| ----------------------------- | ------- |
| [#1](#1-add-token-validation) | Pending |
| [#2](#2-add-rate-limiter)     | Pending |

## Detailed Tasks

### 1. Add token validation

(P) Verify JWT signature and expiry. Return 401 with structured error on failure.

- [ ] Middleware rejects expired tokens
- [ ] Middleware returns structured 401 error

_Requirements: 1.2, 1.3_
_Boundary: AuthMiddleware_

---

### 2. Add rate limiter

(P) Sliding window per API key.

- [ ] Rate limiter enforces per-key limits

_Requirements: 3.1_
_Boundary: RateLimiter_
```

### Workflow

1. Create `requirements.md` first (EARS format, lifecycle frontmatter, any
   `[NEEDS CLARIFICATION: ...]` markers for unresolved questions). Review it before proceeding.
2. Generate `design.md` from the requirements. Optionally capture rejected
   alternatives and trade-offs in `research.md`. Review before proceeding.
3. Run `/spec-review` to validate completeness, EARS compliance, constitution alignment,
   and that no `[NEEDS CLARIFICATION: ...]` markers remain.
4. Generate `tasks.md` from design + requirements (with traceability + parallel markers).
5. Implement task by task with `/spec-implement`. Check off each in `tasks.md` with a brief
   completion note.
6. When every task is `Done`, run `/spec-finalize` to freeze the spec: flip the frontmatter
   to `status: completed`, append an Implementation Notes block to `design.md` capturing
   what shipped vs. what was descoped, and update `specs/INDEX.md`.

## TODO Files

TODO files live in `todos/` organized by area: `todos/<area>.md` (e.g. `todos/solver.md`, `todos/api.md`, `todos/ui.md`).

The TODO workflow mirrors the SDD task workflow above: items have a `Status` column
(`Pending` / `Done` / `Blocked`) and resolved items stay in the file with their status
flipped to `Done` and a brief completion note appended -- they are not deleted.

When working with TODO files, follow this structure:

1. **Priority Summary table** at the very top - lists every tracked item regardless of
   status, sorted by priority (highest priority first). Exactly **three columns**:
   `Task`, `Priority`, and `Status`.
   - `Task` is a markdown link to the detailed section, with the link text as
     `[#N](anchor)` (e.g. `[#5](#5-broken-cache-invalidation)`). Do not put
     descriptions in the cell.
   - `Priority` is `P0` / `P1` / `P2`.
   - `Status` is one of `Pending`, `Done`, or `Blocked`.
   - **Never use HTML anchors** (`<a id="N"></a>`) -- they are invisible in plain
     markdown and don't navigate reliably in VS Code. **Never use strikethrough**
     (`~~text~~`) on item titles -- update the `Status` column instead.
2. **Suggested resolution order** - after the Priority Summary table, an unnumbered
   (bullet) list of item numbers in recommended tackling order with brief rationale
   per item (e.g. `- #5 -- prerequisite for #7`). List **only still-pending items** --
   completed items are already tracked via their `Done` status in the Priority Summary
   table, so keeping them here just adds noise. Bullets (not numbers) keep the list
   stable as items are completed.
3. **Detailed sections** at the bottom - one heading per item with full description,
   context, and acceptance criteria. Sections for `Done` and `Blocked` items stay in
   place; do not delete them.
4. **Completion notes** - when an item is marked `Done`, append a brief note to its
   detailed section, e.g. `_Done: invalidation now runs on write; covered by tests_`.
   Helps when resuming across sessions.
5. **Blocked notes** - when an item is marked `Blocked`, append a `_Blocked: {reason}_`
   line to its detailed section so the cause is visible alongside the description.
6. **Never delete the TODO file** even when every item is `Done` -- the historical
   record is useful context for future work in that area.
