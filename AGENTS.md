# AGENTS.md

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
.stowrc                    # Disables directory folding so ignore rules apply per file
.config/
  nvim/                    # Neovim config (Kickstart-based, lazy.nvim)
    init.lua               # Main config (~500 lines)
    lua/custom/plugins/    # Custom plugins (git, colorscheme)
    lua/kickstart/         # Kickstart modules
  shell/                   # Shell modules (aliases, functions, env, completions, keybindings)
  starship.toml            # Starship prompt config
  yazi/                    # Yazi file manager config + plugins
.codex/
  AGENTS.md                # User-level Codex preferences (stowed to ~/.codex/)
  config.toml              # Codex defaults, agents, TUI, status line, and MCP
  agents/                  # Custom subagent definitions
  rules/                   # Command allow and prompt policies
.agents/skills/            # User-level reusable Codex workflows
.vscode/
  user_settings.json       # Cursor/VS Code settings
  keybindings.json         # Cursor/VS Code keybindings
```

### Shell Module Architecture

Shell config uses a split pattern: **shared** (`.sh`) vs **shell-specific** (`.zsh`/`.bash`).

- `.zshrc` sources zsh-specific modules first (zinit, cluster, history, keybindings, completions), then shared modules (functions, aliases, integrations)
- `.bashrc` auto-switches to zsh if available; otherwise sources shared modules directly
- `integrations.sh` detects the running shell via `$ZSH_VERSION`/`$BASH_VERSION` and loads the correct shell-specific completion/integration files
- Aliases in `aliases.sh` conditionally guard `eza`/`bat` replacements behind `[ -z "$AGENT" ] && [ -z "$Codex" ]`

## Build / Lint / Test Commands

This repository has **no build, lint, or test commands**. It is purely configuration files.

The only operational command is:

```bash
# Symlink all dotfiles into $HOME
stow .

# Preview what stow would do (dry run)
stow -n -v .
```

Files excluded from stow are listed in `.stow-local-ignore` (includes `.git`, `docs/`, `misc/`, `todos/`, `.vscode/`, and Codex runtime state under `.codex/`). `.stowrc` disables directory folding so Stow deploys only the allowlisted Codex configuration rather than symlinking the entire runtime directory.

## Environment Notes

- **Primary shell:** Zsh with zinit plugin manager
- **Prompt:** Starship (2-line lean style)
- **Terminal:** Ghostty
- **Multiplexer:** tmux (prefix: `C-Space`)
- **Editor (terminal):** Neovim (Kickstart + lazy.nvim)
- **Editor (GUI):** Cursor (VS Code fork)
- **File manager:** Yazi
- **Platforms:** macOS (Homebrew) and Linux (SLURM GPU clusters with CUDA 12.4)
- **`$AGENT` / `$Codex` env vars:** When either is set, shell aliases for `eza`/`bat` are
  disabled to prevent confusing AI agent output. Codex sets `Codex=1` automatically.
- **Navigation:** `zoxide` replaces `cd` (`eval "$(zoxide init --cmd cd zsh)"`)
- **Search tools:** ripgrep (`rg`), fd (`fd --no-ignore`)

## AI Agent Configuration

### Codex

- **Codex user prefs:** `.codex/AGENTS.md` (stowed to `~/.codex/AGENTS.md`)
- **Codex skills:** seven reusable workflows at `.agents/skills/` -- `spec-init`
  and `todo-init` create tracked work, `implement` executes it, `finalize` closes
  it out, and `commit`, `mr-description`, and `dataset-readme` cover standalone
  operations. Built-in Codex behavior handles ordinary docs, conflict resolution,
  and code review (`/review` or `codex review`).
- **Codex agents:** `.codex/agents/implementer.toml` -- one focused Terra/medium
  implementer shared by spec and TODO workflows. The Sol/high main session owns
  orchestration and final acceptance-criteria verification.
- **Codex settings:** `.codex/config.toml` is the portable base configuration.
  `.codex/macos.config.toml` and `.codex/server.config.toml` provide host-specific
  profile overrides. Stow deploys all three under `~/.codex/`.
- **Codex approvals:** routine workspace actions run directly; eligible escalation
  prompts are routed to Codex Auto Review while sandbox boundaries remain active.
- **Codex profiles:** use `codex --profile macos` on the local macOS machine and
  `codex --profile server` on remote non-macOS machines.
- **Invocation:** use `$skill-name` in a prompt or choose a workflow with `/skills`.
  Codex custom prompts are deprecated, so Claude-style slash commands are represented
  as skills rather than duplicated under `.codex/prompts/`.
