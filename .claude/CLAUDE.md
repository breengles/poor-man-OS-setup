# Personal Preferences

## Response style

Lead with the outcome.
Scale length to the question - a simple question gets prose, not headers and sections.
Never pad an answer to look thorough.
Do not narrate routine actions between tool calls.

- One idea per sentence. At most one comma, except in a list.
- No clause nested inside another clause. One subordinate clause is fine; two in the same sentence is not.
- No parenthetical asides. No "not just X but Y" framing.
- Keep subject and verb adjacent - no interruption between them.
- Vary sentence length. Never two dense sentences in a row.
- Keep causal connectives (because, so, otherwise) even when cutting.
- Concrete noun over abstraction: "this function", not "this layer".
- Verbs over nominalizations: "we deploy", not "the deployment of".
- Define any acronym or term of art on first use, five words max.
- Banned unless technically required: leverage, robust, seamless, underscore, delve, pivotal, holistic, comprehensive, nuanced.
- No preamble and no closing restatement of what you just said.
- Written deliverables follow the same rules: substance only, no filler sections, no redundant summary.
- No Unicode symbols in code or comments -- plain ASCII only.
- Never use em dashes (`—`); use regular dashes (`-`) instead

## Ultracode mode

Cap the fleet at 3 Opus or 6 Sonnet subagents in flight (count 1 Opus as 2 Sonnet slots).
If a task looks like it needs wider fan-out, interview the user about the unclear parts instead.

## Commits

- No conventional commit prefixes going forward (no `fix:`, `feat:`, `refactor:`, etc.)
- Use imperative mood, lowercase, ~50 char first line
- Describe what changed and why, not the category
- Never include issue IDs (`#5`, `#123`) in commit messages

## Python

### Tooling

Always use `uv` for Python project management.

- Create venvs: `uv venv`
- Install packages: `uv pip install <package>`
- Run scripts: `uv run python script.py` or `uv run pytest`
- Add deps: `uv add <package>`, `uv add --dev <package>`
- Target version: Python 3.10+
- Formatter/linter: Ruff (line length 120, F401 ignored)
- Type checking: Pyright in `basic` mode

### Style

- Type-annotate all function signatures (params + return); skip local variables. Use modern syntax: `str | None`, `list[int]` (not `Optional`, `List`).
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

Do not add tests unless asked.
Never delete or weaken pre-existing coverage unprompted -- if a change makes a test fail, fix the code or raise it.

## SLURM cluster

Never run compute-intensive work on the login node -- it is shared, and meant for editing and job submission only.
Submit real work via `sbatch` / `srun`. Default partition: `scalar100q`.
