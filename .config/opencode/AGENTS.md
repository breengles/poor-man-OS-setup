# Personal Preferences

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
- Testing: pytest

### Style

- Type-annotate all function signatures (params + return); skip local variables.
  Use modern syntax: `str | None`, `list[int]` (not `Optional`, `List`)
- No `from __future__ import annotations`
- Data modeling: Pydantic for services/APIs, dataclasses for internal, dataclasses + pyrallis for CLI apps
- Web framework: FastAPI
- Logging: stdlib `logging` (or `loguru` if project already uses it)
- Async: `asyncio` when beneficial for I/O; sync by default
- Paths: always `pathlib.Path`, never `os.path`
- Strings: f-strings for all interpolation
- Docstrings: Google style (`Args:`, `Returns:`, `Raises:`); skip for trivial code
- Imports: stdlib -> third-party -> local; prefer relative imports within packages

## Markdown

- After editing or creating any markdown file (`.md`), always run `npx prettier --write <file>` to format it before committing.

## Git Commits

- Never include issue IDs or numbers (e.g. `#5`, `#123`) in commit messages -- GitLab interprets
  `#N` as an issue reference and may auto-close issues unintentionally.

## GitLab

- Use `gitlab-cli` MCP tools for interacting with GitLab (issues, merge requests, projects, etc.)
- If the GitLab MCP server fails, is unavailable, or does not provide enough information, fall back to the `glab` CLI tool instead
- Example `glab` commands: `glab issue list`, `glab mr list`, `glab mr view <id>`, `glab issue view <id>`

## TODO Files

TODO files live in `todos/` organized by area: `todos/<area>.md`
(e.g. `todos/solver.md`, `todos/api.md`, `todos/ui.md`).

When working with TODO files, follow this structure:

1. **Priority Summary table** at the very top -- only open items, sorted by priority.
   Each issue in the table must be a **markdown link** to its detailed section heading
   (e.g. `[#5 Description](#5-heading-slug)`), so it's Cmd+click navigable.
2. **Detailed sections** in the middle -- full descriptions of open issues grouped by category.
3. **When an item is resolved**, remove it from the Priority Summary table and from the
   open detailed sections. Do NOT keep a "Resolved" section -- just delete the item entirely.
4. **When all items are resolved**, delete the TODO file entirely. Do not keep empty TODO files.
5. **Suggested resolution order** -- after the Priority Summary table, include a short
   "Suggested resolution order" section listing item numbers in the order they should be
   tackled (e.g. dependencies first, quick wins, then larger efforts). Keep it to a simple
   numbered list with brief rationale per item.
6. **Keep the Priority Summary table sorted** -- whenever adding or updating a TODO item,
   ensure the Priority Summary table remains sorted by priority (highest first).
