# CLAUDE.md

## Project Overview

This is a **dotfiles/system configuration repository** managed with [GNU Stow](https://www.gnu.org/software/stow/). It
symlinks configuration files from this repo into `$HOME`. There is no compiled source code, no build system, no test
framework, and no CI/CD pipeline.

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
  shell/                   # Shell modules (aliases, functions, env, node, completions, keybindings, cwd-history)
  starship.toml            # Starship prompt config
  yazi/                    # Yazi file manager config + plugins
.claude/
  CLAUDE.md                # User-level Claude Code preferences (stowed to ~/.claude/)
  skills/                  # Custom slash commands (see "AI Agent Configuration" below)
  agents/                  # Custom agent definitions (implementer.md)
  settings.json            # Claude Code settings (stowed to ~/.claude/settings.json)
.vscode/
  user_settings.json       # Cursor/VS Code settings
  keybindings.json         # Cursor/VS Code keybindings
```

### Shell Module Architecture

Shell config uses a split pattern: **shared** (`.sh`) vs **shell-specific** (`.zsh`/`.bash`).

- `.zshrc` sources zsh-specific modules first (zinit, cluster, history, keybindings, completions), then shared modules
  (functions, aliases, node, integrations)
- `.bashrc` auto-switches to zsh if available; otherwise sources shared modules directly
- `integrations.sh` detects the running shell via `$ZSH_VERSION`/`$BASH_VERSION` and loads the correct shell-specific
  completion/integration files
- Aliases in `aliases.sh` conditionally guard `eza`/`bat` replacements behind `[ -z "$AGENT" ] && [ -z "$CLAUDECODE" ]`
- `node.sh` puts nvm's default Node version on `PATH` by globbing `$NVM_DIR`, without sourcing `nvm.sh` (~10ms per shell
  instead of ~600ms for `nvm use default`). Only `nvm` itself is a lazy-load function shim, and it is deliberately self-contained: agent harnesses
  snapshot shell functions but drop underscore-prefixed ones, so a shim calling a `_helper` breaks in agent shells.
  Never reintroduce `node`/`npm`/`npx` shim functions - they masked the real node behind a broken shim and fell through
  to the distro's ancient `/usr/bin/node`.
- `cwd-history.zsh` must be sourced *after* `integrations.sh`, because that is where `~/.fzf.zsh` binds `^R`. It logs every
  command with its directory to `~/.local/share/cwd-history.tsv`, then ranks `^R` in four tiers (this dir, below it, rest of
  the git repo, everything else) and prepends a `cwd_history` strategy to `ZSH_AUTOSUGGEST_STRATEGY`. Each row carries a
  colored gutter cell naming its tier. Inside the picker `^R` cycles the scope (all -> here -> below -> repo -> all) and
  `^T` toggles fzf's relevance sort. Notes on the parts that are not obvious:
  - Scope is on `^R` rather than `alt-1`..`alt-4` because `.tmux.conf` binds `M-1`..`M-9` to `select-window`, so alt digits
    never reach fzf inside tmux. The cycle is stateless: the scope is encoded in the fzf prompt, and a `transform` binding
    reads it back from `$FZF_PROMPT`.
  - The ranking lives in `cwd-history.awk` rather than inline, because fzf's `reload` bindings run through `sh` and cannot
    call a zsh function. `_cwd_history_rank_cmd` builds the same call as a quoted string for them.
  - Never redirect fzf's stdin (`< /dev/tty`). The candidate list arrives on a pipe, and the redirect makes fzf fight the
    terminal for input: ~55ms per keypress instead of ~2ms. fzf's own history widget omits it for the same reason.
  - The one-time import of the pre-existing `$HISTFILE` lives in a separate `.seed` file. The in-memory cache re-reads the
    live log on every `cd`, and those thousands of directory-less records cost 7ms per `cd` when they shared a file.
  - Both `awk` calls run under `LC_ALL=C`: zsh metafies non-ASCII bytes into `$HISTFILE` and macOS awk aborts the entire
    run on the first multibyte conversion failure, which silently truncated the import to 706 of 4946 entries.

## Build / Lint / Test Commands

This repository has **no build, lint, or test commands**. It is purely configuration files.

The only operational command is:

```bash
# Symlink all dotfiles into $HOME
stow .

# Preview what stow would do (dry run)
stow -n -v .
```

Files excluded from stow are listed in `.stow-local-ignore` (includes `.git`, `docs/`, `misc/`, `todos/`, `.vscode/`,
and many `.claude/` transient dirs).

## Environment Notes

- **Primary shell:** Zsh with zinit plugin manager
- **Prompt:** Starship (2-line lean style)
- **Terminal:** Ghostty
- **Multiplexer:** tmux (prefix: `C-Space`)
- **Editor (terminal):** Neovim (Kickstart + lazy.nvim)
- **Editor (GUI):** Cursor (VS Code fork)
- **File manager:** Yazi
- **Platforms:** macOS (Homebrew) and Linux (SLURM GPU clusters with CUDA 12.4)
- **`$AGENT` / `$CLAUDECODE` env vars:** When either is set, shell aliases for `eza`/`bat` are disabled to prevent
  confusing AI agent output. Claude Code sets `CLAUDECODE=1` automatically.
- **Navigation:** `zoxide` replaces `cd` (`eval "$(zoxide init --cmd cd zsh)"`)
- **Search tools:** ripgrep (`rg`), fd (`fd --no-ignore`)

## AI Agent Configuration

### Claude Code

- **Claude Code user prefs:** `.claude/CLAUDE.md` (stowed to `~/.claude/CLAUDE.md`). Kept deliberately short; each skill
  owns its own format details rather than restating them here.
- **Claude Code skills:** 8 custom slash commands at `.claude/skills/`, each under 100 lines.
  - Tracked-work pipeline, shared by specs and TODOs: `spec-init` / `todo-init` create the artifact, `implement` builds
    it, `finalize` reconciles the docs, removes it, and commits. `grill` (a frontier-rounds interview that settles a
    fuzzy plan) is the escalation path for `spec-init`'s single-message interview.
  - Standalone: `commit`, `mr-description`, `dataset-readme`.
  - Deliberately **not** custom skills: code review (built-in `/code-review`, `/security-review`, `/simplify` cover it),
    documentation writing, and conflict resolution — all things Claude does competently without a template.
- **Claude Code agents:** `.claude/agents/implementer.md` — a single Sonnet implementer with Write/Edit, dispatched by
  `implement` for both spec tasks and TODO items. There is no reviewer subagent; the orchestrator scope-checks the diff
  and re-reads acceptance criteria itself.
- **Claude Code settings:** `.claude/settings.json` (stowed to `~/.claude/settings.json` — contains MCP servers,
  plugins, permissions, effort level). Claude Code writes to this file directly, so edits land in the repo and show up
  in `git status`.
