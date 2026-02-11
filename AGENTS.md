# AGENTS.md - Coding Agent Instructions

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
    init.lua               # Main config (~1039 lines)
    lua/custom/plugins/    # Custom plugins (git, colorscheme)
    lua/kickstart/         # Kickstart modules
  opencode/                # OpenCode AI tool config
  shell/                   # Shell modules (aliases, functions, env, completions, keybindings)
  starship.toml            # Starship prompt config
  yazi/                    # Yazi file manager config + plugins
.vscode/
  user_settings.json       # Cursor/VS Code settings
  keybindings.json         # Cursor/VS Code keybindings
```

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
`.git`, `readme.*`, `LICENSE`, `COPYING`, `AGENTS.md`, `/misc`, `/.vscode`, `/.config/yazi/plugins`

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

### Python (configured tooling, not in this repo)

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
- **Format on save:** Enabled (ruff_organize_imports, then ruff_format)

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

- **OpenCode:** Configured at `.config/opencode/opencode.json` with Claude Sonnet 4.6
  as default model, Claude Opus 4.6 for read-only "ask" agent
- **OpenCode AGENTS.md:** `.config/opencode/AGENTS.md` contains Python-specific `uv` preferences
  (also loaded as system instructions by the current session)

## Key Reminders

1. This repo has **no tests to run** and **no build to execute**
2. Always use `uv` for any Python work, never pip/conda/poetry
3. Ruff line length is **120**, not 80 or 88
4. Shell scripts use **2-space indentation**
5. Lua files use **2-space indentation** and **single-quoted strings**
6. Git commits follow **Conventional Commits** format
7. All editors are configured to **format on save**
8. Guard shell aliases with `[ -z "$AGENT" ]` when they might confuse AI agents
