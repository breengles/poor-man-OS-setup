# Shell Configuration

## Overview

The shell setup uses **Zsh** as the primary shell with **Bash** as a fallback. Configuration is modular: `.bashrc` and `.zshrc` are thin entry points that source shared modules from `.config/shell/`. This design keeps shell-agnostic code (aliases, functions, environment variables) in one place while allowing shell-specific configuration (keybindings, history, completions) to diverge where necessary.

## File Structure

| File                             | Description                                                          |
| -------------------------------- | -------------------------------------------------------------------- |
| `.bashrc`                        | Bash entry point; trampolines to Zsh if available                    |
| `.zshrc`                         | Zsh entry point; sources all modules in order                        |
| `.config/shell/env_vars.sh`      | Environment variables (PATH, OLLAMA, Gradio, Starship)               |
| `.config/shell/zinit.zsh`        | Zinit plugin manager setup and Zsh plugins                           |
| `.config/shell/cluster.zsh`      | SLURM cluster-specific module loading (Lambda login nodes)           |
| `.config/shell/history.bash`     | Bash history configuration                                           |
| `.config/shell/history.zsh`      | Zsh history configuration                                            |
| `.config/shell/keybindings.bash` | Bash keybindings and fzf widgets                                     |
| `.config/shell/keybindings.zsh`  | Zsh keybindings and fzf widgets                                      |
| `.config/shell/completions.bash` | Bash completion system initialization                                |
| `.config/shell/completions.zsh`  | Zsh completion styling (case-insensitive, fzf-tab preview)           |
| `.config/shell/functions.sh`     | Shared functions (update, SLURM utilities, venv activation, GPU ops) |
| `.config/shell/aliases.sh`       | Shared aliases with conditional tool detection                       |
| `.config/shell/integrations.sh`  | Third-party integrations (Cargo, fzf, gcloud, Starship, completions) |

## Shell Initialization Flow

### Zsh (primary)

```
.zshrc
  ├── env_vars.sh          # PATH, environment variables
  ├── Homebrew shellenv     # macOS only
  ├── zinit.zsh             # Plugin manager + Zsh plugins
  ├── cluster.zsh           # SLURM modules (conditional)
  ├── history.zsh           # History settings
  ├── keybindings.zsh       # Key bindings + fzf widgets
  ├── completions.zsh       # Completion styling
  ├── functions.sh          # Shared functions
  ├── aliases.sh            # Shared aliases
  ├── integrations.sh       # Cargo, fzf, gcloud, Starship, tool completions
  ├── NVM                   # Node Version Manager
  └── zoxide init           # cd replacement
```

### Bash (fallback)

```
.bashrc
  ├── Zsh trampoline        # exec zsh if available (skipped on "login-*" hosts)
  ├── env_vars.sh
  ├── history.bash
  ├── keybindings.bash
  ├── completions.bash
  ├── functions.sh
  ├── aliases.sh
  └── integrations.sh
```

## Key Configuration Choices

### Bash-to-Zsh Trampoline

`.bashrc` automatically `exec`s Zsh when available, for machines where `chsh` is unavailable (e.g. HPC clusters). The `_no_zsh_patterns` array excludes specific hostnames (currently `login-*` prefixed hosts) where `exec zsh` would break.

### `$AGENT` Guard on Aliases

Aliases for `eza` (replacing `ls`) and `bat` (replacing `cat`) are guarded with `[ -z "$AGENT" ]`:

```bash
if [ -x "$(command -v eza)" ] && [ -z "$AGENT" ]; then
  alias ls="eza --color=always --group-directories-first"
fi
```

When `$AGENT` is set, these aliases are skipped. This prevents AI coding agents from receiving decorated/colored output that confuses their parsers. The tmux config propagates this variable via `set -ga update-environment AGENT`.

### `WORDCHARS` Empty

`WORDCHARS=''` is set in `env_vars.sh` so that Zsh word-movement commands (Alt+Left/Right, Alt+Backspace) stop at `/`, `.`, `-`, and other punctuation — matching the behavior of most modern editors rather than Zsh's default of treating `foo/bar.baz` as a single word.

## Zinit Plugin Manager

Zinit is auto-installed on first run. The following plugins are loaded:

| Plugin                                       | Purpose                                 |
| -------------------------------------------- | --------------------------------------- |
| `Aloxaf/fzf-tab`                             | Replace Zsh tab completion with fzf     |
| `zdharma-continuum/fast-syntax-highlighting` | Syntax highlighting in the command line |
| `zsh-users/zsh-completions`                  | Additional completion definitions       |
| `zsh-users/zsh-autosuggestions`              | Fish-like autosuggestions from history  |

Completion cache (`.zcompdump`) is only rebuilt every 24 hours to avoid startup latency.

## Keybindings

Keybindings are implemented in both Bash and Zsh variants with identical behavior.

### Navigation

| Key             | Action                | Notes                                  |
| --------------- | --------------------- | -------------------------------------- |
| `Up` / `Down`   | History prefix search | Searches history matching typed prefix |
| `Alt+Left`      | Backward word         | Kitty sends `\x1b\x62`                 |
| `Alt+Right`     | Forward word          | Kitty sends `\x1b\x66`                 |
| `Cmd+Left`      | Beginning of line     | Kitty sends `\x01` (Ctrl+A)            |
| `Cmd+Right`     | End of line           | Kitty sends `\x05` (Ctrl+E)            |
| `Alt+Backspace` | Delete word backward  | Standard terminal behavior             |

### fzf Widgets

Custom fzf-powered widgets for file finding and content searching:

| Key      | Action                                             |
| -------- | -------------------------------------------------- |
| `Ctrl+O` | Fuzzy find file (fd), open in vim                  |
| `Ctrl+G` | Fuzzy grep file contents (rg), open in vim at line |
| `Alt+O`  | Fuzzy find file, open in Cursor                    |
| `Alt+G`  | Fuzzy grep file contents, open in Cursor at line   |

All fzf widgets use `fd` for file discovery and `bat` for syntax-highlighted previews.

## Aliases

### Conditional Aliases

Aliases are only defined when the underlying tool is installed:

| Alias  | Expands to                                     | Condition                  |
| ------ | ---------------------------------------------- | -------------------------- |
| `vim`  | `nvim`                                         | nvim installed             |
| `ls`   | `eza --color=always --group-directories-first` | eza installed, no `$AGENT` |
| `l`    | `eza --color=always --long ...`                | eza installed, no `$AGENT` |
| `ll`   | `eza --color=always -abghHlS ...`              | eza installed, no `$AGENT` |
| `cat`  | `bat`                                          | bat installed, no `$AGENT` |
| `code` | `cursor`                                       | cursor installed           |
| `fd`   | `fd --no-ignore`                               | fd installed               |
| `s`    | `sbatch`                                       | SLURM available            |
| `oc`   | `opencode`                                     | opencode installed         |
| `ol`   | `ollama`                                       | ollama installed           |

### Rsync Aliases

| Alias        | Command                                            |
| ------------ | -------------------------------------------------- |
| `rcopy`      | `rsync -ah --info=progress2`                       |
| `rmove`      | `rsync -ah --remove-source-files --info=progress2` |
| `rupd`       | `rsync -auh --info=progress2`                      |
| `rsync-sync` | `rsync -auh --delete --info=progress2`             |

## Functions

### General

| Function           | Description                                               |
| ------------------ | --------------------------------------------------------- |
| `update`           | Updates zinit, Homebrew, apt (non-login nodes), and Cargo |
| `act [path]`       | Activates a Python venv (default: `.venv`)                |
| `calcimages <dir>` | Counts image files (jpg/jpeg/png) in a directory          |
| `calcjson <dir>`   | Counts JSON files in a directory                          |

### SLURM Cluster Functions

| Function                        | Description                                                        |
| ------------------------------- | ------------------------------------------------------------------ |
| `q`                             | Shows `sinfo` + user's job queue with summary counts               |
| `qq`                            | Live-updating `watch` of job queue                                 |
| `gpu <N>`                       | SSH to `lambda-scalar<N>` and launch `nvitop`                      |
| `gpu_usage`                     | Per-user GPU usage table across all partitions (jobs + GPU counts) |
| `gpu_alloc [-p part] [-n node]` | Per-node GPU allocation table with optional filters                |

The `scancel` command has tab completion that shows job IDs with job names as descriptions (implemented for both Bash and Zsh).

## Completions

### Zsh Completion Styling

```zsh
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'     # Case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # Colored completions
zstyle ':completion:*' menu no                               # Disable menu (fzf-tab handles it)
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 ...'   # Directory preview for cd
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview '...'  # Directory preview for zoxide
```

### Tool Completions

The integrations module loads completions for: `adkb`, `uv`, `opencode`, `glab`, `pueue`, `pcpctl`. It looks for shell-specific completion files (`~/.completion.<tool>.zsh` or `~/.completion.<tool>.bash`) falling back to generic `.sh` variants.

## Integrations

Loaded via `integrations.sh` (shell-agnostic):

| Integration  | Description                                     |
| ------------ | ----------------------------------------------- |
| Cargo        | Sources `~/.cargo/env` for Rust toolchain       |
| fzf          | Sources `~/.fzf.{zsh,bash}`                     |
| Google Cloud | Sources SDK path and completions                |
| lesspipe     | Makes `less` handle non-text files (Linux only) |
| Starship     | Initializes the prompt                          |
| Secrets      | Sources `~/.env-global.sh` (gitignored)         |

## Cluster Support

`cluster.zsh` conditionally loads SLURM and CUDA modules when the hostname matches `lambda-loginnode*`:

```zsh
if [[ $(hostname) == "lambda-loginnode"* ]]; then
    emulate sh -c "source /etc/profile"
    module load slurm
    module load cuda12.4/toolkit/12.4.1
fi
```

## Dependencies

- **Zsh** (primary shell)
- **zinit** (auto-installed)
- **fzf** (fuzzy finder)
- **fd** (file finder, used in fzf widgets)
- **ripgrep** (`rg`, used in fzf grep widgets)
- **bat** (syntax-highlighted previews)
- **eza** (modern `ls` replacement)
- **zoxide** (smart `cd` replacement)
- **Starship** (prompt)
- **NVM** (Node version manager, optional)

## Relationship to Other Components

- **Kitty** sends special escape sequences for `Cmd+Left/Right` and `Alt+Left/Right` that the keybinding modules interpret
- **Starship** is initialized in `integrations.sh` using the config from `.config/starship.toml`
- **tmux** propagates the `$AGENT` variable to child shells via `update-environment`
- **Neovim** is aliased as `vim` and set as `$EDITOR`
