# Personal Preferences

## Response style

Keep responses brief and lead with the outcome. Match the response to the
question -- a simple question gets a direct answer in prose, not headers and
sections. Written deliverables follow the same rule: cover the substance, skip
filler sections and redundant summaries. Do not narrate routine actions between
tool calls.

## Multi-agent mode

Cap the fleet at 3 Sol or 6 Terra subagents in flight; count 1 Sol as 2 Terra
slots. If a task looks like it needs wider fan-out, interview the user about the
unclear parts instead.

Use Terra at medium reasoning for focused implementation and read-heavy scans.
Use Sol at high reasoning for demanding review or escalation. Parallelize
independent reads and serialize overlapping writes.

After dispatch, continue useful work or make one long blocking `wait_agent`
call. Never poll with `list_agents`, status messages, or repeated short waits.
Use `followup_task` only to provide new context or remediation to the same unit.

## Writing style

- No Unicode symbols in code or comments -- plain ASCII only.
- Never use em dashes; use regular dashes instead.

## Commits

- No conventional commit prefixes going forward (`fix:`, `feat:`, `refactor:`,
  etc.).
- Use imperative mood and a lowercase first line of about 50 characters.
- Describe what changed and why, not the category.
- Never include issue IDs (`#5`, `#123`) in commit messages.

## Python

### Tooling

Always use `uv` for Python project management instead of pip, venv, conda,
poetry, or pipenv.

- Create environments with `uv venv`.
- Install packages with `uv pip install <package>`.
- Run scripts with `uv run python script.py` and tests with `uv run pytest`.
- Add dependencies with `uv add <package>` or `uv add --dev <package>`.
- Target Python 3.10 or newer.
- Use Ruff with line length 120 and F401 ignored.
- Use Pyright in basic mode and pytest for testing.

### Style

- Type-annotate all function signatures, but not local variables. Use modern
  syntax such as `str | None` and `list[int]`.
- Do not add `from __future__ import annotations`.
- Use Pydantic for services and APIs, dataclasses for internal models, and
  dataclasses with Pyrallis for CLI applications.
- Use FastAPI for web services.
- Use stdlib `logging`, or Loguru when the project already uses it.
- Prefer synchronous code; use `asyncio` when it materially helps I/O.
- Use `pathlib.Path`, never `os.path`, and f-strings for interpolation.
- Use Google-style docstrings for non-trivial definitions.
- Put imports at module scope, order them stdlib/third-party/local, prefer
  relative package imports, and never use wildcard imports.
- Use `ruff check --select I --fix` to sort and format imports.

## Tests

Do not add tests unless asked; remove any added proactively. Never delete or
weaken pre-existing coverage unprompted. If a change makes a test fail, fix the
code or raise it.

## SLURM cluster

Never run compute-intensive work on the login node -- it is shared and intended
only for editing and job submission. Submit real work through `sbatch` or
`srun`. Use `scalar100q` by default.
