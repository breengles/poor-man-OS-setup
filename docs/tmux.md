# tmux Configuration

## Overview

tmux is configured as the default terminal multiplexer with `C-Space` as the prefix key. The configuration focuses on true color support, mouse usage, sensible pane/window numbering, and a minimal status bar. tmux sessions are auto-created when opening terminals in Cursor/VS Code.

## File Structure

| File         | Description                            |
| ------------ | -------------------------------------- |
| `.tmux.conf` | Complete tmux configuration (37 lines) |

## Key Configuration Choices

### Prefix Key: `C-Space`

The default `C-b` is replaced with `C-Space` because:

- `C-b` conflicts with backward-word in readline/Zsh
- `C-Space` is ergonomic and rarely conflicts with terminal applications
- It matches the Neovim leader key convention (Space)

```
unbind C-b
set -g prefix C-Space
bind C-Space send-prefix
```

### True Color Support

Both `tmux-256color` and `xterm*:Tc` overrides are set to ensure true color rendering works in Neovim and other applications:

```
set-option -g default-terminal "tmux-256color"
set-option -sa terminal-overrides ",xterm*:Tc"
set-option -sa terminal-overrides ",*256col*:Tc"
```

### 1-Based Indexing

Windows and panes start at index 1 (not 0), and windows are renumbered on close:

```
set -g base-index 1
set -g pane-base-index 1
set-option -g renumber-windows on
```

### `$AGENT` Environment Propagation

The `AGENT` environment variable is included in `update-environment` so that when an AI agent sets `$AGENT` in the outer shell, it propagates into tmux sessions. This ensures shell aliases for `eza`/`bat` are correctly disabled inside tmux when agents are running.

```
set -ga update-environment AGENT
```

### Terminal Environment Variables

`TERM` and `TERM_PROGRAM` are also propagated to ensure proper terminal detection inside tmux:

```
set -ga update-environment TERM
set -ga update-environment TERM_PROGRAM
```

## Keybindings

| Key          | Action                                  |
| ------------ | --------------------------------------- |
| `C-Space`    | Prefix key                              |
| `S-Left`     | Previous window (no prefix needed)      |
| `S-Right`    | Next window (no prefix needed)          |
| `prefix + "` | Split pane vertically (preserves cwd)   |
| `prefix + %` | Split pane horizontally (preserves cwd) |

Pane splits preserve the current working directory via `-c "#{pane_current_path}"`.

## Settings

| Setting        | Value | Purpose                               |
| -------------- | ----- | ------------------------------------- |
| `escape-time`  | 10ms  | Reduces delay after pressing Escape   |
| `focus-events` | on    | Required for Neovim autocommands      |
| `mouse`        | on    | Enables mouse scrolling and selection |
| `xterm-keys`   | on    | Passes xterm key sequences through    |

## Plugins

Managed by [TPM](https://github.com/tmux-plugins/tpm) (Tmux Plugin Manager):

| Plugin                            | Purpose                  |
| --------------------------------- | ------------------------ |
| `tmux-plugins/tpm`                | Plugin manager itself    |
| `niksingh710/minimal-tmux-status` | Minimal status bar theme |

### Installing Plugins

```bash
# First time: clone TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Then inside tmux: prefix + I to install plugins
```

## Visual

- Active pane border: blue (`fg=blue`)
- Status bar: minimal theme via `minimal-tmux-status` plugin

## Cursor/VS Code Integration

The editor settings define a tmux terminal profile for both Linux and macOS:

```json
"terminal.integrated.profiles.osx": {
  "tmux": {
    "path": "zsh",
    "args": ["-lc", "ses=${PWD##*/} && tmux new -dAs ${ses//[.:]/_} && tmux attach; exit"]
  }
}
```

This creates or attaches to a tmux session named after the current directory (with `.` and `:` replaced by `_`). The default terminal profile is set to `tmux` on both platforms.

## Dependencies

- **tmux** (install via Homebrew or package manager)
- **TPM** (clone manually, see above)

## Relationship to Other Components

- **Kitty** provides the terminal that tmux runs inside; true color overrides ensure colors pass through correctly
- **Shell** keybindings (`Alt+Left/Right`, `Cmd+Left/Right`) are passed through tmux via `xterm-keys on`
- **Cursor/VS Code** auto-creates tmux sessions per workspace
- **`$AGENT`** environment variable is propagated from the outer shell through tmux to inner shells
