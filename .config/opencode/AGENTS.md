# Personal Python Preferences

Always use `uv` for Python project management instead of pip, venv, conda, poetry, or pipenv.

## Virtual Environments
- Use `uv venv` to create virtual environments
- Never use `python -m venv` or `virtualenv`

## Package Installation
- Use `uv pip install` to install packages
- Never use `pip install` directly
- Use `uv pip install -r requirements.txt` for requirements files

## Running Python
- Use `uv run` to execute Python scripts or commands
- This automatically uses the virtual environment if one exists
- Example: `uv run python script.py` or `uv run pytest`

## Adding Dependencies
- Use `uv add <package>` to add dependencies to pyproject.toml
- Use `uv add --dev <package>` for development dependencies

## General
- Prefer `uv` for all Python-related tasks including linting, formatting, and type checking
- If a project doesn't have a virtual environment yet, create one with `uv venv` first

## Git Commits

- Never include issue IDs or numbers (e.g. `#5`, `#123`) in commit messages — GitLab interprets
  `#N` as an issue reference and may auto-close issues unintentionally.

## GitLab

- Use `gitlab` MCP tools for interacting with GitLab (issues, merge requests, projects, etc.)
- If the GitLab MCP server fails, is unavailable, or does not provide enough information, fall back to the `glab` CLI tool instead
- Example `glab` commands: `glab issue list`, `glab mr list`, `glab mr view <id>`, `glab issue view <id>`

## TODO Files

TODO files live in `todos/` organized by area: `todos/<area>.md`
(e.g. `todos/solver.md`, `todos/api.md`, `todos/ui.md`).

When working with TODO files, follow this structure:

1. **Priority Summary table** at the very top — only open items, sorted by priority.
   Each issue in the table must be a **markdown link** to its detailed section heading
   (e.g. `[#5 Description](#5-heading-slug)`), so it's Cmd+click navigable.
2. **Detailed sections** in the middle — full descriptions of open issues grouped by category.
3. **When an item is resolved**, remove it from the Priority Summary table and from the
   open detailed sections. Do NOT keep a "Resolved" section — just delete the item entirely.
4. **When all items are resolved**, delete the TODO file entirely. Do not keep empty TODO files.
5. **Suggested resolution order** — after the Priority Summary table, include a short
   "Suggested resolution order" section listing item numbers in the order they should be
   tackled (e.g. dependencies first, quick wins, then larger efforts). Keep it to a simple
   numbered list with brief rationale per item.
