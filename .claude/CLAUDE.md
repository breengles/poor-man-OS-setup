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

- No `from __future__ import annotations`
- Logging: stdlib `logging` (or `loguru` if project already uses it)
- Strings: f-strings for all interpolation

### Type checking

- Always invoke pyright via `uv run pyright <files>` so it picks up the project's `.venv`.
- For projects without a `pyrightconfig.json` / `[tool.pyright]` block, prefer adding one
  (`venvPath = "."`, `venv = ".venv"`) over relying on the `uv run` prefix.

## Code and Comments

- **No Unicode symbols in code or comments.** Use plain ASCII equivalents instead.
  Examples: `*` not `·`, `->` not `→`, `>=` not `≥`, `<=` not `≤`, `!=` not `≠`,
  `sum(...)` or `\sum` not `∑`. Wrong: `# g·f + f·g = 2∫gf dr` - Right: `# g * f + f * g = 2 * \int gf dr`

## Git Commits

- Never include issue IDs or numbers (e.g. `#5`, `#123`) in commit messages - GitLab interprets
  `#N` as an issue reference and may auto-close issues unintentionally.

## Spec-Driven Development (SDD)

For long-lived engineering work (pipelines, CLIs, APIs, shared libraries), use the spec
workflow. Skip it for throwaway scripts, notebooks, or one-off analysis.

Specs live in `specs/<feature-name>/` and are managed by dedicated slash commands:

- `/spec-init <feature>` -- bootstrap `requirements.md` (EARS), `design.md`, optional
  `research.md`, and `tasks.md`, stage by stage
- `/spec-review <feature>` -- validate completeness, EARS compliance, constitution
  alignment, and readiness before implementation
- `/spec-implement <feature>` -- implement task-by-task via implementer/reviewer
  subagents (orchestrator pattern)
- `/spec-finalize <feature>` -- freeze a fully-implemented spec (flip lifecycle to
  `completed`, append Implementation Notes, update `specs/INDEX.md`)

Two repo-level files complement the per-feature directories:

- `specs/INDEX.md` -- one-line entry per spec with status, dates, and a short summary
- `specs/constitution.md` (optional) -- non-negotiable project principles binding on
  every spec; consulted by all four slash commands above

Each skill file (`~/.claude/skills/spec-*/SKILL.md`) is the source of truth for the
format details: EARS patterns, lifecycle frontmatter, task table layout, traceability
rules, and the constitution-deviation protocol. Do not re-derive them from this file.

## TODO Files

TODO files live in `todos/` organized by area: `todos/<area>.md` (e.g. `todos/solver.md`, `todos/api.md`, `todos/ui.md`).

The TODO workflow mirrors the SDD task workflow above: items have a `Status` column
(`Pending` / `Done` / `Blocked`) and resolved items stay in the file with their status
flipped to `Done` and a brief completion note appended.

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
   table, so keeping them here just adds noise.
3. **Detailed sections** at the bottom - one heading per item with full description,
   context, and acceptance criteria
4. **Completion notes** - when an item is marked `Done`, append a brief note to its
   detailed section, e.g. `_Done: invalidation now runs on write; covered by tests_`.
5. **Blocked notes** - when an item is marked `Blocked`, append a `_Blocked: {reason}_`
   line to its detailed section so the cause is visible alongside the description.
