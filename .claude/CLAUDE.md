# Personal Preferences

## Safety

NEVER use destructive commands without explicit user approval. The following are **absolutely forbidden** unless the user explicitly asks for them:

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

1. `requirements.md` -- What & why. EARS-format acceptance criteria (see below).
2. `design.md` -- How. Architecture, data flow, key decisions.
3. `tasks.md` -- Ordered implementation checklist with checkboxes (see format below).
4. `research.md` (optional) -- Rejected alternatives, trade-offs, constraints discovered during design. Valuable when "why not X" matters (e.g. ML architecture choices).

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

1. Create `requirements.md` first (EARS format). Review it before proceeding.
2. Generate `design.md` from the requirements. Optionally capture rejected
   alternatives and trade-offs in `research.md`. Review before proceeding.
3. Run `/spec-review` to validate design completeness against requirements.
4. Generate `tasks.md` from design + requirements (with traceability + parallel markers).
5. Implement task by task. Check off each in `tasks.md` with a brief completion note.

## TODO Files

TODO files live in `todos/` organized by area: `todos/<area>.md` (e.g. `todos/solver.md`, `todos/api.md`, `todos/ui.md`).

When working with TODO files, follow this structure:

1. **Priority Summary table** at the very top - only open items, sorted by priority
   (highest priority first). Exactly **three columns**: `Task`, `Priority`, and `Status`.
   - `Task` is a markdown link to the detailed section, with the link text as
     `[#N](anchor)` (e.g. `[#5](#5-broken-cache-invalidation)`). Do not put
     descriptions in the cell.
   - `Priority` is `P0` / `P1` / `P2` (or `High` / `Med` / `Low`, project-consistent).
   - `Status` is `Pending` or `Blocked`. Resolved items are deleted from the file
     entirely (no `Done` row).
   - **Never use HTML anchors** (`<a id="N"></a>`) -- they are invisible in plain
     markdown and don't navigate reliably in VS Code.
2. **Detailed sections** in the middle - full descriptions of open issues grouped
   by category.
3. **When an item is resolved**, remove it from the Priority Summary table and from
   the detailed sections entirely.
4. **When all items are resolved**, delete the TODO file entirely.
5. **Suggested resolution order** - after the Priority Summary table, include a short
   "Suggested resolution order" section listing item numbers in the order they should be
   tackled (e.g. dependencies first, quick wins, then larger efforts). Use an unnumbered
   (bullet) list with brief rationale per item (e.g. `- #5 -- prerequisite for #7`), not a
   numbered list, so removing a completed item doesn't force renumbering.
