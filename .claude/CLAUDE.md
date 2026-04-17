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

### Tooling

Always use `uv` for Python project management instead of pip, venv, conda, poetry, or pipenv.

- Create venvs: `uv venv`
- Install packages: `uv pip install <package>`
- Run scripts: `uv run python script.py` or `uv run pytest`
- Add deps: `uv add <package>`, `uv add --dev <package>`
- Target version: Python 3.10+
- Formatter/linter: Ruff (line length 120, F401 ignored)
- Type checking: Pyright in `basic` mode

### Style

- Type-annotate all function signatures (params + return); skip local variables.
  Use modern syntax: `str | None`, `list[int]` (not `Optional`, `List`).
  **Exception — pyrallis dataclasses:** pyrallis does not support expression-style unions
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
  `sum(...)` or `\sum` not `∑`, `\int` not `∫`, `alpha`/`beta` not `α`/`β`.
  Wrong: `# g·f + f·g = 2∫gf dr` — Right: `# g * f + f * g = 2 * \int gf dr`

## Markdown

- After editing or creating any markdown file (`.md`), always run `npx prettier --write <file>` to format it before committing.

## Pre-commit Hooks

- If the project has a `.pre-commit-config.yaml`, run `pre-commit run` (staged files only) and fix any issues before committing.

## Git Commits

- Never include issue IDs or numbers (e.g. `#5`, `#123`) in commit messages — GitLab interprets
  `#N` as an issue reference and may auto-close issues unintentionally.

## Git Worktrees

Apply this rule **only when the user explicitly asks to create a new branch** (e.g. "create a
branch for X", "start a new branch and implement Y", "cut a branch off main and ..."). In that
case, do the work in a dedicated git worktree instead of creating the branch in the current
checkout — dispatch an agent with `isolation: "worktree"` (or run `git worktree add` explicitly)
so the main checkout stays untouched.

Do **not** apply this rule for plain "implement X" / "fix Y" / "refactor Z" requests that don't
mention a new branch — keep working in the current checkout as usual.

- **Location convention:** `<project-name>.worktrees/<sanitized-branch-name>`, placed as a
  sibling of the main repo directory (i.e. `../<project-name>.worktrees/<sanitized-branch-name>`).
- **Project name:** the basename of the main repo directory (e.g. for `/Users/artem/poor-man-OS-setup`
  the project name is `poor-man-OS-setup`).
- **Sanitized branch name:** replace every `/` in the branch name with `-`
  (e.g. `feat/new-thing` -> `feat-new-thing`). Keep all other characters as-is.
- **Example:** branch `feat/worktree-flow` in repo `poor-man-OS-setup` -> worktree path
  `../poor-man-OS-setup.worktrees/feat-worktree-flow`.
- Always create the worktree from the latest `main` (or the explicitly requested base branch).
- When the work is done and merged/abandoned, clean up with `git worktree remove <path>` —
  never delete the directory manually.

## GitLab

- Use `gitlab` MCP tools for interacting with GitLab (issues, merge requests, projects, etc.)
- If the GitLab MCP server fails, is unavailable, or does not provide enough information, fall back to the `glab` CLI tool instead
- Example `glab` commands: `glab issue list`, `glab mr list`, `glab mr view <id>`, `glab issue view <id>`

## Spec-Driven Development (SDD)

Use SDD selectively — only for long-lived engineering artifacts, never for exploratory research code.

### When to use specs

- User explicitly asks for SSD
- Training pipelines, data loaders, evaluation harnesses
- CLI tools, APIs, dashboards
- Shared libraries or frameworks
- Anything that will live beyond one experiment cycle

### When NOT to use specs

- Experiment scripts, notebooks, ablation code
- One-off analysis or visualization
- Anything in `experiments/`

### Spec structure

Specs live in `specs/<feature-name>/` with up to four files:

1. `requirements.md` -- What & why. EARS-format acceptance criteria (see below).
2. `design.md` -- How. Architecture, data flow, key decisions.
3. `tasks.md` -- Ordered implementation checklist with checkboxes (see format below).
4. `research.md` (optional) -- Rejected alternatives, trade-offs, constraints discovered
   during design. Valuable when "why not X" matters (e.g. ML architecture choices).

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

1. **Task Summary table** -- one row per task with links to detailed sections.
   Use standard markdown heading slugs for links (e.g. `[Description](#1-description-slug)`).
   **Never use HTML anchors** (`<a id="N"></a>`) -- they are invisible in plain
   markdown and don't navigate reliably in VS Code.
   Include a **Status** column (`Pending`, `Done`, `Blocked`) to track progress.
   **Never use strikethrough** (`~~text~~`) on task names -- it makes text
   unreadable and links unclickable. Update the Status column instead.
2. **Suggested Resolution Order** -- numbered list of task IDs with brief rationale.
3. **Detailed Tasks** -- one `###` heading per task with full description,
   files to modify, acceptance criteria checklist, and metadata.

Each task should include:

- **Requirements traceability:** end each task with `_Requirements: 1.1, 2.3_`
  (numeric IDs from `requirements.md`) so nothing gets orphaned.
- **Parallel markers:** append `(P)` to tasks that have no dependency on the
  immediately preceding task. Add `_Boundary: ComponentName_` to confirm
  non-overlapping scope. Default: tasks are sequential (order implies dependency).
- **Completion notes:** when checking off a task, append a brief note on what was
  done and what was tested. Helps when resuming across sessions.

Example:

```markdown
## Task Summary

| #   | Task                                                    | Status  | Depends on |
| --- | ------------------------------------------------------- | ------- | ---------- |
| 1   | [Define types module](#1-define-types-module)           | Done    | --         |
| 2   | [Add token validation](#2-add-token-validation)         | Pending | 1          |
| 3   | [Implement rate limiter](#3-implement-rate-limiter)     | Pending | 1          |
| 4   | [Wire middleware pipeline](#4-wire-middleware-pipeline) | Pending | 2, 3       |

## Detailed Tasks

### 1. Define types module

Create shared type definitions.

- [x] All types importable, pyright passes

_Requirements: 1.1_

---

### 2. Add token validation

(P) Verify JWT signature and expiry. Return 401 with structured error on failure.

- [ ] Middleware rejects expired tokens
- [ ] Middleware returns structured 401 error

_Requirements: 1.2, 1.3_
_Boundary: AuthMiddleware_

---

### 3. Implement rate limiter

(P) Sliding window per API key.

- [ ] Rate limiter enforces per-key limits

_Requirements: 3.1_
_Boundary: RateLimiter_

---

### 4. Wire middleware pipeline

Wire token validation and rate limiter into request pipeline.
Depends on 2 and 3.

- [ ] Requests pass through both middleware in order

_Requirements: 1.2, 3.1_
```

### Workflow

1. Create `requirements.md` first (EARS format). Review it before proceeding.
2. Generate `design.md` from the requirements. Optionally capture rejected
   alternatives and trade-offs in `research.md`. Review before proceeding.
3. Run `/spec-review` to validate design completeness against requirements.
4. Generate `tasks.md` from design + requirements (with traceability + parallel markers).
5. Implement task by task. Check off each in `tasks.md` with a brief completion note.

## TODO Files

TODO files live in `todos/` organized by area: `todos/<area>.md`
(e.g. `todos/solver.md`, `todos/api.md`, `todos/ui.md`).

When working with TODO files, follow this structure:

1. **Priority Summary table** at the very top — only open items, sorted by priority.
   Each issue in the table must be a **markdown link** to its detailed section heading
   (e.g. `[#5 Description](#5-heading-slug)`), so it's Cmd+click navigable.
2. **Detailed sections** in the middle — full descriptions of open issues grouped by category.
3. **When an item is resolved**, remove it from the Priority Summary table and from the
   open detailed sections.
4. **When all items are resolved**, delete the TODO file entirely.
5. **Suggested resolution order** — after the Priority Summary table, include a short
   "Suggested resolution order" section listing item numbers in the order they should be
   tackled (e.g. dependencies first, quick wins, then larger efforts). Keep it to a simple
   numbered list with brief rationale per item.
