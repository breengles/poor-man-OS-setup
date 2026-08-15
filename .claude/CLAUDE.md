# Personal Preferences

## Response style

Keep responses brief and lead with the outcome. Match the response to the question -- a simple question gets a direct answer in prose, not headers and sections. Written deliverables follow the same rule: cover the substance, skip filler sections and redundant summaries. Do not narrate routine actions between tool calls. Keep explanations simple!

## Ultracode mode

Cap the fleet at 3 Opus or 6 Sonnet subagents in flight (count 1 Opus as 2 Sonnet slots). If a task looks like it needs
wider fan-out, interview the user about the unclear parts instead.

## Writing style

- No Unicode symbols in code or comments -- plain ASCII only.
- Never use em dashes (`—`); use regular dashes (`-`) instead

## Commits

- No conventional commit prefixes going forward (no `fix:`, `feat:`, `refactor:`, etc.)
- Use imperative mood, lowercase, ~50 char first line
- Describe what changed and why, not the category
- Never include issue IDs (`#5`, `#123`) in commit messages

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
  Use modern syntax: `str | None`, `list[int]` (not `Optional`, `List`).
- No `from __future__ import annotations`
- Data modeling: Pydantic for services/APIs, dataclasses for internal, dataclasses + pyrallis for CLI apps
- Web framework: FastAPI
- Logging: stdlib `logging` (or `loguru` if project already uses it)
- Async: `asyncio` when beneficial for I/O; sync by default
- Paths: always `pathlib.Path`, never `os.path`
- Strings: f-strings for all interpolation
- Docstrings: Google style (`Args:`, `Returns:`, `Raises:`); skip for trivial code
- Imports (PEP 8, PEP 328):
  - All imports at the top of the file, never inside functions or local scopes
  - Order: stdlib → third-party → local; prefer relative imports within packages
  - Never use wildcard imports (`from lib import *`) - always import specific names (PEP 8)
  - Use `ruff check --select I --fix` (isort) to sort and format imports

## Tests

Do not add tests unless asked; remove any added proactively. Never delete or weaken pre-existing coverage unprompted --
if a change makes a test fail, fix the code or raise it.

## SLURM cluster

Never run compute-intensive work on the login node -- it is shared, and meant for editing and job submission only.
Submit real work via `sbatch` / `srun`. Default partition: `scalar100q`.
