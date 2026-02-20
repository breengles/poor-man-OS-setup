# Starship Prompt Configuration

## Overview

Starship provides a cross-shell prompt styled after the Powerlevel10k lean theme. It uses a 2-line format with directory, git info, and context on the first line, and a minimal prompt character on the second. Most language-specific modules are disabled to keep the prompt fast and uncluttered.

## File Structure

| File                    | Description              |
| ----------------------- | ------------------------ |
| `.config/starship.toml` | Complete Starship config |

## Prompt Layout

```
~/p/poor-man-OS-setup main [!1+2] .venv (3.12.0)          user@host
❯
```

**Line 1 (left to right):**

1. Directory (cyan, fish-style abbreviated)
2. Git branch (green)
3. Git status (yellow, bracketed)
4. Git metrics (disabled)
5. Fill (space)
6. Yazi level indicator (if inside Yazi subshell)
7. Python virtualenv + version
8. Conda environment
9. Command duration
10. Exit status (if non-zero)
11. Username + hostname (SSH only)

**Line 2:** Prompt character (`❯` green on success, red on error; `❮` in vim mode)

## Key Configuration Choices

### Directory Display

```toml
truncation_length = 5
truncate_to_repo = false
fish_style_pwd_dir_length = 1
```

- Shows up to 5 parent directories before truncating
- Uses fish-style abbreviation: middle directories show only their first character
- Home is displayed as `~`

### Git Status Format

```toml
format = '([\[$all_status$ahead_behind\]]($style) )'
```

Status indicators: `?` untracked, `!` modified, `+` staged, `*` stashed, `✘` deleted, `»` renamed, `⇡⇣` ahead/behind.

### Python

Shows virtualenv name and Python version only when relevant files are detected (`.python-version`, `pyproject.toml`, `requirements.txt`, etc.). Uses no symbol prefix to keep it compact.

### SSH Awareness

Username and hostname are only shown during SSH sessions (`ssh_only = true`), keeping the local prompt clean.

### Yazi Level Indicator

Displays a `⊢` symbol when inside a Yazi subshell (detects `$YAZI_LEVEL` env var).

### Disabled Modules

The following modules are explicitly disabled to prevent unwanted prompt segments: `package`, `nodejs`, `rust`, `golang`, `java`, `docker_context`, `gcloud`, `aws`, `azure`, `kubernetes`, `terraform`, `nix_shell`, `ruby`, `php`, `perl`, `lua`, `swift`, `elixir`, `haskell`.

## Dependencies

- **Starship** (install via Cargo: `cargo install starship`)
- Initialized in the shell via `integrations.sh`

## Relationship to Other Components

- **Shell** initializes Starship in `integrations.sh` (`eval "$(starship init zsh)"`)
- **`$STARSHIP_CONFIG`** is set in `env_vars.sh` pointing to `.config/starship.toml`
- **Yazi** level detection shows when operating inside a Yazi subshell
