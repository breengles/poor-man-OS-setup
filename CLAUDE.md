# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **dotfiles/system configuration repository** managed with [GNU Stow](https://www.gnu.org/software/stow/).
It symlinks configuration files from this repo into `$HOME`. There is no compiled source code,
no build system, no test framework, and no CI/CD pipeline.

**Deploy all configs:** `stow .` (from repo root)

### Repository Structure

```
.bashrc                    # Bash config (auto-switches to zsh if available)
.zshrc                     # Primary shell config (sources everything in .config/shell/)
.gitconfig                 # Git config (delta pager, aliases, LFS)
.tmux.conf                 # tmux config (C-Space prefix, TPM plugin manager)
.config/
  kitty/                   # Kitty terminal emulator (theme, fonts)
  nvim/                    # Neovim config (Kickstart-based, lazy.nvim)
    init.lua               # Main config (~1038 lines)
    lua/custom/plugins/    # Custom plugins (git, colorscheme)
    lua/kickstart/         # Kickstart modules
  shell/                   # Shell modules (aliases, functions, env, completions, keybindings)
  starship.toml            # Starship prompt config
  yazi/                    # Yazi file manager config + plugins
.claude/
  CLAUDE.md                # User-level Claude Code preferences (stowed to ~/.claude/)
  skills/                  # Custom slash commands (commit, todo-*, docs-*, mr-description)
  agents/                  # Custom agent definitions (branch-code-reviewer)
.vscode/
  user_settings.json       # Cursor/VS Code settings
  keybindings.json         # Cursor/VS Code keybindings
```

### Shell Module Architecture

Shell config uses a split pattern: **shared** (`.sh`) vs **shell-specific** (`.zsh`/`.bash`).

- `.zshrc` sources zsh-specific modules first (zinit, cluster, history, keybindings, completions), then shared modules (functions, aliases, integrations)
- `.bashrc` auto-switches to zsh if available; otherwise sources shared modules directly
- `integrations.sh` detects the running shell via `$ZSH_VERSION`/`$BASH_VERSION` and loads the correct shell-specific completion/integration files
- Aliases in `aliases.sh` conditionally guard `eza`/`bat` replacements behind `[ -z "$AGENT" ]`

## Build / Lint / Test Commands

This repository has **no build, lint, or test commands**. It is purely configuration files.

The only operational command is:

```bash
# Symlink all dotfiles into $HOME
stow .

# Preview what stow would do (dry run)
stow -n -v .
```

Files excluded from stow (via `.stow-local-ignore`):
`.DS_Store`, `.git`, `readme.*`, `LICENSE`, `COPYING`, `CLAUDE.md`, `/docs`, `/misc`, `/todos`, `/.vscode`, `/.config/yazi/plugins`, `/.claude/settings.local.json`, `/.claude/plans`, `/.claude/todos`

## Code Style Guidelines

### Shell Scripts (.sh, .zsh)

- **Shebang:** Use `#!/usr/bin/env bash` for portable bash scripts
- **Quoting:** Always double-quote variable expansions (`"$var"`, `"$HOME"`)
- **Conditionals:** Use `[ -x "$(command -v tool)" ]` to check for command availability
- **Functions:** Use `function name { ... }` syntax
- **Conditionally alias commands** only when available; guard aliases for AI agents with `[ -z "$AGENT" ]`
  to prevent aliased output from confusing agents (see `.config/shell/aliases.sh`)
- **Naming:** lowercase with underscores for functions and variables (`gpu_usage`, `gpu_alloc`)
- **Error handling:** Use `>&2` for error messages, `return 1` for function failures
- **Indentation:** 2 spaces
- **Linting:** ShellCheck is configured as a VS Code/Cursor extension

### Lua (Neovim config)

- **Formatter:** Stylua (auto-installed via Mason, runs on save via conform.nvim)
- **Indentation:** 2 spaces (enforced by modeline: `-- vim: ts=2 sts=2 sw=2 et`)
- **Strings:** Single quotes preferred (`'string'`)
- **Comments:** Use `-- NOTE:`, `-- WARN:`, `-- TODO:` prefixes for important annotations
- **Imports:** Use `require('module')` with single quotes
- **LSP:** lua_ls configured with `callSnippet = 'Replace'`
- **Style:** Follow Kickstart.nvim conventions - descriptive `desc` fields for keymaps

### Python

#### Tooling

- **Target version:** Python 3.10+ (use `X | Y` union types, `match`/`case`, `ParamSpec`)
- **Package manager:** Always use `uv` (never pip, venv, conda, poetry, or pipenv)
  - Create venvs: `uv venv`
  - Install packages: `uv pip install <package>`
  - Run scripts: `uv run python script.py` or `uv run pytest`
  - Add deps: `uv add <package>`, `uv add --dev <package>`
- **Formatter:** Ruff (`charliermarsh.ruff`)
- **Line length:** 120 characters
- **Linter:** Ruff with F401 (unused imports) ignored
- **Import sorting:** Ruff organize imports (on save)
- **Import format:** Relative imports preferred (`python.analysis.importFormat: "relative"`)
- **Type checking:** Pyright in `basic` mode (Pyright handles go-to-definition, completions;
  Ruff handles linting)
- **Testing:** pytest (with fixtures, `parametrize`, `conftest.py`)
- **Format on save:** Enabled (ruff_organize_imports, then ruff_format)

#### Style & Conventions

- **Type hints:** Annotate all function signatures (params + return types); skip local variables
  unless it aids clarity. Use modern syntax: `str | None` not `Optional[str]`,
  `list[int]` not `List[int]`
- **No `from __future__ import annotations`** — avoid it; some libraries (Pydantic, FastAPI)
  need runtime-evaluable annotations
- **Data modeling:**
  - `pydantic.BaseModel` for services, APIs, config, and anything needing validation/serialization
  - `dataclasses.dataclass` for internal data structures
  - `dataclasses` + `pyrallis` for simple CLI applications and experiment configs
- **Web framework:** FastAPI for APIs and services
- **Logging:** stdlib `logging` module by default; use `loguru` if the project already uses it
- **Async:** Use `asyncio` for I/O-bound work when it provides clear benefit; default to sync
- **Paths:** Always use `pathlib.Path`, never `os.path`
- **Strings:** f-strings for all interpolation; `.format()` only when f-strings can't work
  (e.g., deferred formatting in logging)
- **Docstrings:** Google style (`Args:`, `Returns:`, `Raises:` sections). Write docstrings for
  public APIs and non-obvious functions; skip for trivial/self-explanatory code
- **Naming:** `snake_case` for functions/variables, `PascalCase` for classes,
  `UPPER_SNAKE_CASE` for constants
- **Imports:** Group in order: stdlib, third-party, local. Prefer relative imports within packages

### Markdown

- **Formatter:** Prettier (VS Code/Cursor)
- **Indentation:** 2 spaces
- **Format on save:** Enabled
- **Linting:** markdownlint with MD024 (duplicate headings) disabled

### YAML

- **Formatter:** Red Hat YAML extension
- **Indentation:** 2 spaces
- **Print width:** 120
- **Bracket spacing:** Disabled
- **Format on save:** Enabled

### JSON/JSONC

- **JSON:** VS Code built-in formatter
- **JSONC:** Prettier

### General Editor Settings

- **Line length / rulers:** 120 characters
- **Final newline:** Always insert (`files.insertFinalNewline: true`)
- **Tab size:** 4 (default), 2 for Lua/Markdown/YAML/Fortran
- **Indentation detection:** Enabled (`editor.detectIndentation: true`)
- **Format on save:** Enabled globally
- **Trailing whitespace:** Visible in selection (`editor.renderWhitespace: "selection"`)

## Git Conventions

- **Default branch:** `main`
- **Commit style:** Conventional Commits (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`)
- **Subject line:** Max 72 characters
- **Pager:** delta (side-by-side diffs)
- **LFS:** Enabled
- **Common aliases:** `co` (checkout), `ci` (commit -m), `st` (status), `br` (branch),
  `lg` (fancy log graph)

## Environment Notes

- **Primary shell:** Zsh with zinit plugin manager
- **Prompt:** Starship (2-line lean style)
- **Terminal:** Kitty (MonaspiceNe Nerd Font, size 18)
- **Multiplexer:** tmux (prefix: `C-Space`)
- **Editor (terminal):** Neovim (Kickstart + lazy.nvim)
- **Editor (GUI):** Cursor (VS Code fork)
- **File manager:** Yazi
- **Platforms:** macOS (Homebrew) and Linux (SLURM GPU clusters with CUDA 12.4)
- **`$AGENT` env var:** When set, shell aliases for `eza`/`bat` are disabled to prevent
  confusing AI agent output. Be aware of this if running shell commands.
- **Navigation:** `zoxide` replaces `cd` (`eval "$(zoxide init --cmd cd zsh)"`)
- **Search tools:** ripgrep (`rg`), fd (`fd --no-ignore`)

## AI Agent Configuration

- **Claude Code user prefs:** `.claude/CLAUDE.md` (stowed to `~/.claude/CLAUDE.md`)
- **Claude Code skills:** 8 custom slash commands at `.claude/skills/` — commit, todo-init,
  todo-revise, todo-analyze, docs-init, docs-revise, docs-analyze, mr-description
- **Claude Code agents:** `.claude/agents/` — branch-code-reviewer
- **Claude Code settings:** `~/.claude/settings.json` (managed by Claude Code itself, not stow —
  contains MCP servers, hooks, plugins, permissions)

## Key Reminders

1. This repo has **no tests to run** and **no build to execute**
2. Always use `uv` for any Python work, never pip/conda/poetry
3. Ruff line length is **120**, not 80 or 88
4. Shell scripts use **2-space indentation**
5. Lua files use **2-space indentation** and **single-quoted strings**
6. Git commits follow **Conventional Commits** format
7. All editors are configured to **format on save**
8. Guard shell aliases with `[ -z "$AGENT" ]` when they might confuse AI agents
