# Git Configuration

## Overview

Git is configured with Neovim as the editor, delta for side-by-side diffs, LFS support, and a set of convenience aliases. Sensitive local configuration (username, email, signing keys) lives in a separate `~/.gitconfig.local` that is gitignored.

## File Structure

| File               | Description                                       |
| ------------------ | ------------------------------------------------- |
| `.gitconfig`       | Shared Git configuration (tracked)                |
| `.gitconfig.local` | Machine-specific config: name, email (gitignored) |
| `.gitignore`       | Global gitignore patterns                         |

## Configuration

### Core Settings

```ini
[core]
  excludesfile = ~/.gitignore
  editor = nvim
  pager = delta
```

- **Editor**: Neovim for commit messages and interactive rebase
- **Pager**: delta with side-by-side diffs enabled
- **Global gitignore**: `.gitignore` in the repo root (symlinked to `~/.gitignore`)

### Local Include

```ini
[include]
  path = ~/.gitconfig.local
```

Machine-specific settings (user name, email, GPG signing) go in `~/.gitconfig.local` which is gitignored. This keeps personal information out of the repo while allowing different identities on different machines.

### Delta Pager

```ini
[delta]
  side-by-side = true
```

Delta provides syntax-highlighted, side-by-side diffs in the terminal.

### Default Branch

```ini
[init]
  defaultBranch = main
```

### Git LFS

LFS is configured with clean, smudge, and process filters for handling large files.

## Aliases

| Alias  | Expansion                                                 |
| ------ | --------------------------------------------------------- |
| `co`   | `checkout`                                                |
| `st`   | `status`                                                  |
| `br`   | `branch`                                                  |
| `hist` | Compact log graph with dates                              |
| `lg1`  | Decorated graph log (relative dates, single-line)         |
| `lg2`  | Decorated graph log (absolute + relative dates, two-line) |
| `lg`   | Alias for `lg2` (default log view)                        |
| `type` | `cat-file -t` (show object type)                          |
| `dump` | `cat-file -p` (pretty-print object)                       |

## Global Gitignore

The `.gitignore` file covers:

- **OS**: `.DS_Store`
- **IDE**: `.idea`, `.vscode/*` (with exceptions for tracked settings files)
- **Python**: `__pycache__`, `.python-version`, `.venv*`, `*.egg-info`
- **ML**: `.aim`
- **Yazi plugins**: `.config/yazi/plugins` (installed via `ya pkg`)
- **Secrets**: `.env-global.sh`, `.gitconfig.local`

## Commit Conventions

From the project's AGENTS.md:

- **Format**: Conventional Commits (`feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, `test:`)
- **Subject line**: Max 72 characters
- **No issue IDs**: Never include `#N` in commit messages (GitLab auto-close risk)

## Dependencies

- **Git** (install via Homebrew or system package manager)
- **delta** (install via Cargo: `cargo install delta`)
- **Git LFS** (`git lfs install`)
- **Neovim** (for editor)

## Relationship to Other Components

- **Neovim** provides LazyGit integration (`<leader>gg`) and Diffview (`<leader>gd`)
- **Cursor/VS Code** has extensive Git settings (auto-fetch, blame, Git Graph)
- **Shell** sets `$EDITOR=nvim` via aliases
- **AI tools** have commit conventions defined in `AGENTS.md` and OpenCode slash commands
