# Stow / Deployment

## Overview

The repository uses [GNU Stow](https://www.gnu.org/software/stow/) to deploy configuration files by creating symlinks from the repo into `$HOME`. The repo structure mirrors the home directory layout: a file at `.config/nvim/init.lua` in the repo gets symlinked to `~/.config/nvim/init.lua`.

## Deployment

```bash
# From the repo root:
stow .

# Dry run (preview what would happen):
stow -n -v .
```

This creates symlinks for all files in the repo (minus exclusions) into the parent directory (which should be `$HOME`). The repo must be cloned into `$HOME/poor-man-OS-setup` (or any direct child of `$HOME`).

## Exclusions

`.stow-local-ignore` controls which files and directories stow skips:

| Pattern                 | What it excludes                            |
| ----------------------- | ------------------------------------------- |
| `.DS_Store`             | macOS Finder metadata                       |
| `\.git`                 | Git directory                               |
| `^/readme.*`            | README files                                |
| `^/LICENSE.*`           | License files                               |
| `^/COPYING`             | Alternative license filename                |
| `^/AGENTS\.md`          | AI agent instructions (repo-level only)     |
| `/docs`                 | Documentation directory                     |
| `/misc`                 | Miscellaneous non-config files              |
| `/todos`                | TODO tracking files                         |
| `/.vscode`              | VS Code/Cursor settings (deployed manually) |
| `/.config/yazi/plugins` | Yazi plugins (installed via `ya pkg`)       |

### Why `.vscode/` is Excluded

The VS Code/Cursor settings are tracked in the repo as a backup but excluded from stow because:

- Cursor has its own settings sync mechanism
- The settings path differs between VS Code and Cursor
- Manual deployment or settings sync is preferred

### Why Yazi Plugins are Excluded

Yazi plugins are gitignored and excluded from stow because they are installed via `ya pkg add` and may differ between machines or Yazi versions.

## Gitignored Files

The `.gitignore` complements stow exclusions by keeping sensitive or generated files out of the repo:

| Pattern                | Purpose                                     |
| ---------------------- | ------------------------------------------- |
| `.DS_Store`            | macOS metadata                              |
| `.idea`                | JetBrains IDE settings                      |
| `.vscode/*`            | VS Code (with exceptions for tracked files) |
| `__pycache__`          | Python bytecode                             |
| `.python-version`      | pyenv version file                          |
| `.venv*`               | Virtual environments                        |
| `*.egg-info`           | Python package metadata                     |
| `.aim`                 | ML experiment tracker                       |
| `.config/yazi/plugins` | Yazi plugins (installed separately)         |
| `.env-global.sh`       | Secrets and tokens                          |
| `.gitconfig.local`     | Machine-specific Git identity               |

## Cross-Platform Notes

The configuration works on both **macOS** (Homebrew) and **Linux** (HPC clusters with SLURM):

| Aspect            | macOS                         | Linux                             |
| ----------------- | ----------------------------- | --------------------------------- |
| Package manager   | Homebrew                      | apt (conditional in `update`)     |
| Terminal          | Kitty                         | SSH/tmux                          |
| Shell install     | Homebrew (`brew install zsh`) | System package or pre-installed   |
| Rust tools        | Cargo (same on both)          | Cargo (same on both)              |
| CUDA              | N/A                           | `module load cuda12.4` on cluster |
| Homebrew shellenv | Sourced in `.zshrc`           | Skipped (not installed)           |
| Bash trampoline   | Rarely triggered              | Primary mechanism on clusters     |

## Prerequisites

### macOS Setup

```bash
# 1. Install Xcode CLI tools
xcode-select --install

# 2. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 3. Install packages
brew install zsh wget curl git vim neovim tmux make cmake gfortran gcc btop stow rsync fzf lazygit
brew install --cask kitty keepingyouawake raycast mactex dockey transmission obsidian alt-tab maccy \
  font-caskaydia-cove-nerd-font font-monaspace-nerd-font

# 4. Install Rust toolchain
curl https://sh.rustup.rs -sSf | sh
cargo install --locked cargo-update ripgrep dua-cli eza zoxide bat fd-find starship pueue
cargo install --force yazi-build

# 5. Install uv (Python)
curl -LsSf https://astral.sh/uv/install.sh | sh

# 6. Clone and deploy
git clone <repo-url> ~/poor-man-OS-setup
cd ~/poor-man-OS-setup && stow .

# 7. Install tmux plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Then in tmux: prefix + I

# 8. Install Yazi plugins
ya pkg add yazi-rs/plugins:toggle-pane
ya pkg add yazi-rs/plugins:zoom
```

### Linux / HPC Setup

On Linux systems (especially HPC clusters), the Bash-to-Zsh trampoline in `.bashrc` handles shell switching. Homebrew steps are skipped; tools are installed via system package managers or Cargo.

## File Mapping

When `stow .` runs, the resulting symlinks look like:

```
~/.bashrc           -> ~/poor-man-OS-setup/.bashrc
~/.zshrc            -> ~/poor-man-OS-setup/.zshrc
~/.gitconfig        -> ~/poor-man-OS-setup/.gitconfig
~/.gitignore        -> ~/poor-man-OS-setup/.gitignore
~/.tmux.conf        -> ~/poor-man-OS-setup/.tmux.conf
~/.cspell-words.txt -> ~/poor-man-OS-setup/.cspell-words.txt
~/.config/nvim/     -> ~/poor-man-OS-setup/.config/nvim/
~/.config/kitty/    -> ~/poor-man-OS-setup/.config/kitty/
~/.config/shell/    -> ~/poor-man-OS-setup/.config/shell/
~/.config/starship.toml -> ~/poor-man-OS-setup/.config/starship.toml
~/.config/yazi/     -> ~/poor-man-OS-setup/.config/yazi/ (minus plugins/)
~/.config/opencode/ -> ~/poor-man-OS-setup/.config/opencode/
```

## Relationship to Other Components

- All components depend on stow for deployment to `$HOME`
- `.stow-local-ignore` and `.gitignore` work together to keep the repo clean
- The repo structure directly mirrors the home directory structure
