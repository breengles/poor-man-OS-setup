# CLAUDE.md

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
  nvim/                    # Neovim config (Kickstart-based, lazy.nvim)
    init.lua               # Main config (~500 lines)
    lua/custom/plugins/    # Custom plugins (git, colorscheme)
    lua/kickstart/         # Kickstart modules
  shell/                   # Shell modules (aliases, functions, env, completions, keybindings)
  starship.toml            # Starship prompt config
  yazi/                    # Yazi file manager config + plugins
.claude/
  CLAUDE.md                # User-level Claude Code preferences (stowed to ~/.claude/)
  skills/                  # Custom slash commands (commit, todo-*, docs-*, mr-description, spec-review, spec-implement)
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
- Aliases in `aliases.sh` conditionally guard `eza`/`bat` replacements behind `[ -z "$AGENT" ] && [ -z "$CLAUDECODE" ]`

## Build / Lint / Test Commands

This repository has **no build, lint, or test commands**. It is purely configuration files.

The only operational command is:

```bash
# Symlink all dotfiles into $HOME
stow .

# Preview what stow would do (dry run)
stow -n -v .
```

Files excluded from stow are listed in `.stow-local-ignore` (includes `.git`, `docs/`, `misc/`, `todos/`, `.vscode/`, and many `.claude/` transient dirs).

## Environment Notes

- **Primary shell:** Zsh with zinit plugin manager
- **Prompt:** Starship (2-line lean style)
- **Terminal:** Ghostty
- **Multiplexer:** tmux (prefix: `C-Space`)
- **Editor (terminal):** Neovim (Kickstart + lazy.nvim)
- **Editor (GUI):** Cursor (VS Code fork)
- **File manager:** Yazi
- **Platforms:** macOS (Homebrew) and Linux (SLURM GPU clusters with CUDA 12.4)
- **`$AGENT` / `$CLAUDECODE` env vars:** When either is set, shell aliases for `eza`/`bat` are
  disabled to prevent confusing AI agent output. Claude Code sets `CLAUDECODE=1` automatically.
- **Navigation:** `zoxide` replaces `cd` (`eval "$(zoxide init --cmd cd zsh)"`)
- **Search tools:** ripgrep (`rg`), fd (`fd --no-ignore`)

## AI Agent Configuration

### Claude Code

- **Claude Code user prefs:** `.claude/CLAUDE.md` (stowed to `~/.claude/CLAUDE.md`)
- **Claude Code skills:** 11 custom slash commands at `.claude/skills/` — commit, todo-init,
  todo-revise, todo-analyze, todo-implement, docs-init, docs-revise, docs-analyze,
  mr-description, spec-review, spec-implement
- **Claude Code agents:** `.claude/agents/` — branch-code-reviewer, spec-implementer
  (Sonnet, Write/Edit), spec-reviewer (Opus, read-only + Bash), todo-implementer
  (Sonnet, Write/Edit), todo-reviewer (Opus, read-only + Bash)
- **Claude Code settings:** `~/.claude/settings.json` (managed by Claude Code itself, not stow —
  contains MCP servers, hooks, plugins, permissions)

## Key Reminders

1. This repo has **no tests to run** and **no build to execute**
2. Always use `uv` for any Python work, never pip/conda/poetry
3. Ruff line length is **120**
4. Shell scripts use **2-space indentation**
5. Guard shell aliases with `[ -z "$AGENT" ] && [ -z "$CLAUDECODE" ]` when they might confuse AI agents
