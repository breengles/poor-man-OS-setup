# Documentation Index

## Project Overview

**poor-man-OS-setup** is a dotfiles repository managed with [GNU Stow](https://www.gnu.org/software/stow/). It symlinks configuration files from the repo into `$HOME`, providing a complete development environment across macOS and Linux (HPC clusters).

**Primary shell**: Zsh | **Terminal**: Kitty | **Multiplexer**: tmux | **Editor (TUI)**: Neovim | **Editor (GUI)**: Cursor

## Quick Start

```bash
# Prerequisites: Git, Stow, and a package manager (Homebrew on macOS)
git clone <repo-url> ~/poor-man-OS-setup
cd ~/poor-man-OS-setup
stow .
```

See [Stow / Deployment](stow.md) for full prerequisites and platform-specific setup instructions.

## Component Documentation

| Document                     | Component                             | Description                                                            |
| ---------------------------- | ------------------------------------- | ---------------------------------------------------------------------- |
| [Shell](shell.md)            | `.bashrc`, `.zshrc`, `.config/shell/` | Shell initialization, aliases, functions, keybindings, SLURM utilities |
| [Neovim](neovim.md)          | `.config/nvim/`                       | Plugin system (lazy.nvim), LSP, keymaps, custom colorscheme            |
| [tmux](tmux.md)              | `.tmux.conf`                          | Prefix key (C-Space), plugins (TPM), Cursor terminal integration       |
| [Kitty](kitty.md)            | `.config/kitty/`                      | Terminal emulator: fonts, theme, key-to-escape-sequence mappings       |
| [Starship](starship.md)      | `.config/starship.toml`               | Cross-shell prompt: 2-line lean style, git status, Python venv         |
| [Yazi](yazi.md)              | `.config/yazi/`                       | File manager: vim keybindings, fzf/zoxide integration, plugins         |
| [Git](git.md)                | `.gitconfig`                          | Aliases, delta pager, LFS, local config include                        |
| [Editor (GUI)](editor.md)    | `.vscode/`                            | Cursor/VS Code settings, keybindings, Python/LaTeX/Markdown            |
| [AI Tools](ai-tools.md)      | `.config/opencode/`, `AGENTS.md`      | Claude Code and OpenCode config, slash commands, MCP servers           |
| [Stow / Deployment](stow.md) | `.stow-local-ignore`                  | How the repo deploys, exclusions, prerequisites, cross-platform        |

## Architecture

### Shell Initialization

```
.bashrc (Bash entry) ──── trampoline ───→ exec zsh (if available)
                     │
                     └── sources shared modules (fallback if zsh unavailable)

.zshrc (Zsh entry)
  ├── env_vars.sh          ← PATH, environment variables
  ├── Homebrew shellenv    ← macOS only
  ├── zinit.zsh            ← Plugin manager + 4 Zsh plugins
  ├── cluster.zsh          ← SLURM/CUDA modules (HPC only)
  ├── history.zsh          ← History settings
  ├── keybindings.zsh      ← Key bindings + fzf widgets
  ├── completions.zsh      ← Completion styling (fzf-tab)
  ├── functions.sh         ← Shared: update, SLURM utils, venv
  ├── aliases.sh           ← Shared: conditional tool aliases
  ├── integrations.sh      ← Cargo, fzf, gcloud, Starship, completions
  ├── NVM                  ← Node Version Manager
  └── zoxide init          ← cd replacement
```

### Stow File Mapping

The repo root mirrors `$HOME`. Running `stow .` creates symlinks:

```
~/poor-man-OS-setup/.bashrc        →  ~/.bashrc
~/poor-man-OS-setup/.config/nvim/  →  ~/.config/nvim/
~/poor-man-OS-setup/.tmux.conf     →  ~/.tmux.conf
...
```

Files excluded from stow: `.git`, `readme.md`, `AGENTS.md`, `docs/`, `misc/`, `todos/`, `.vscode/`, `.config/yazi/plugins/`.

### Component Relationships

```
Kitty (terminal)
  ├── sends escape sequences → Shell keybinding modules
  ├── hosts → tmux sessions
  └── shares font → Neovim, Cursor

Shell (Zsh/Bash)
  ├── initializes → Starship prompt
  ├── sets $EDITOR → Neovim
  ├── fzf widgets open → Neovim or Cursor
  └── $AGENT var → disables eza/bat aliases for AI agents

tmux
  ├── propagates $AGENT → child shells
  └── auto-created by → Cursor terminal profile

Neovim
  ├── LSP (Ruff + Pyright) matches → Cursor Python settings
  ├── LazyGit integration → Git
  └── format-on-save mirrors → Cursor conform behavior

AI Tools
  ├── AGENTS.md → conventions for Git, Python, Shell
  ├── OpenCode MCP → GitLab via glab
  └── $AGENT env var → shell alias guards
```

## Platforms

| Platform | Use case                        | Key differences                             |
| -------- | ------------------------------- | ------------------------------------------- |
| macOS    | Primary development machine     | Homebrew, Kitty, full GUI stack             |
| Linux    | HPC clusters (SLURM, CUDA 12.4) | Bash trampoline to Zsh, no GUI, cluster.zsh |
