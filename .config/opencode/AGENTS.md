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
