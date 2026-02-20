# Yazi File Manager Configuration

## Overview

Yazi is a terminal file manager with vim-like keybindings. The configuration provides comprehensive keyboard navigation, file operations, and integration with external tools (fzf, zoxide, fd, ripgrep). Two plugins extend the default functionality: toggle-pane and zoom.

## File Structure

| File                        | Description                                           |
| --------------------------- | ----------------------------------------------------- |
| `.config/yazi/yazi.toml`    | General settings (preview wrapping, dimensions)       |
| `.config/yazi/keymap.toml`  | Complete keymap configuration (~788 lines)            |
| `.config/yazi/package.toml` | Plugin dependencies                                   |
| `.config/yazi/plugins/`     | Plugin directory (gitignored, installed via `ya pkg`) |

## Settings

```toml
[preview]
wrap = "yes"
max_width = 2048
max_height = 2048
```

Preview wrapping is enabled and supports large images/files up to 2048x2048.

## Plugins

| Plugin                        | Description                  |
| ----------------------------- | ---------------------------- |
| `yazi-rs/plugins:toggle-pane` | Toggle preview pane maximize |
| `yazi-rs/plugins:zoom`        | Zoom in/out on hovered files |

### Installing Plugins

```bash
ya pkg add yazi-rs/plugins:toggle-pane
ya pkg add yazi-rs/plugins:zoom
```

## Keybindings

### Navigation

| Key           | Action                         |
| ------------- | ------------------------------ |
| `h` / `Left`  | Go to parent directory         |
| `l` / `Right` | Enter child directory          |
| `j` / `k`     | Move cursor down / up          |
| `J` / `K`     | Move cursor 5 lines down / up  |
| `Ctrl+u/d`    | Half page up / down            |
| `Ctrl+b/f`    | Full page up / down            |
| `gg`          | Jump to top                    |
| `G`           | Jump to bottom                 |
| `H`           | History back                   |
| `L`           | History forward                |
| `Alt+j/k`     | Seek preview down / up 5 units |

### File Operations

| Key           | Action                                      |
| ------------- | ------------------------------------------- |
| `o` / `Enter` | Open selected files                         |
| `O`           | Open interactively (choose program)         |
| `y`           | Copy (yank) selected files                  |
| `x`           | Cut selected files                          |
| `p`           | Paste files                                 |
| `P`           | Paste (overwrite existing)                  |
| `d`           | Move to trash                               |
| `D`           | Permanently delete                          |
| `a`           | Create file (or directory if ends with `/`) |
| `r`           | Rename (cursor before extension)            |
| `Ctrl+l`      | Symlink (absolute path)                     |
| `_`           | Symlink (relative path)                     |

### Search and Filter

| Key       | Action                            |
| --------- | --------------------------------- |
| `s`       | Search files by name (fd)         |
| `S`       | Search files by content (ripgrep) |
| `/`       | Find next file                    |
| `?`       | Find previous file                |
| `n` / `N` | Go to next / previous found file  |
| `f`       | Filter files (smart)              |
| `Ctrl+x`  | Cancel search                     |

### Integration

| Key      | Action                          |
| -------- | ------------------------------- |
| `z`      | Jump via zoxide                 |
| `Z`      | Jump or reveal via fzf          |
| `Ctrl+s` | Open shell in current directory |

### Selection

| Key      | Action                         |
| -------- | ------------------------------ |
| `Space`  | Toggle selection and move down |
| `v`      | Enter visual (selection) mode  |
| `V`      | Enter visual unset mode        |
| `Ctrl+a` | Select all                     |
| `Ctrl+r` | Inverse selection              |

### Copy Paths

| Key  | Action                          |
| ---- | ------------------------------- |
| `cc` | Copy absolute path              |
| `cd` | Copy parent directory path      |
| `cf` | Copy filename                   |
| `cn` | Copy filename without extension |

### Sorting (`,` prefix)

| Key         | Sort by                  |
| ----------- | ------------------------ |
| `,m` / `,M` | Modified time (asc/desc) |
| `,c` / `,C` | Created time (asc/desc)  |
| `,e` / `,E` | Extension (asc/desc)     |
| `,a` / `,A` | Alphabetical (asc/desc)  |
| `,n` / `,N` | Natural order (asc/desc) |
| `,s` / `,S` | Size (asc/desc)          |

### Linemode (`m` prefix)

| Key  | Display mode  |
| ---- | ------------- |
| `ms` | Size          |
| `mp` | Permissions   |
| `mm` | Modified time |
| `mn` | None          |

### Tabs

| Key       | Action                        |
| --------- | ----------------------------- |
| `t`       | Create new tab (current path) |
| `1`-`9`   | Switch to tab N               |
| `[` / `]` | Previous / next tab           |
| `{` / `}` | Swap tab left / right         |

### Goto Shortcuts

| Key       | Directory      |
| --------- | -------------- |
| `gh`      | Home (`~`)     |
| `gc`      | `~/.config`    |
| `gd`      | `~/Downloads`  |
| `gt`      | `/tmp`         |
| `g Space` | Interactive cd |

### Plugin Keybindings

| Key | Action                  |
| --- | ----------------------- |
| `T` | Toggle maximize preview |
| `+` | Zoom in hovered file    |
| `-` | Zoom out hovered file   |

### Other

| Key | Action                       |
| --- | ---------------------------- |
| `.` | Toggle hidden files          |
| `;` | Run shell command            |
| `:` | Run shell command (blocking) |
| `w` | Show tasks manager           |
| `~` | Open help                    |

## Dependencies

- **Yazi** (install via Cargo: `cargo install --force yazi-build`)
- **fd** (file search)
- **ripgrep** (content search)
- **zoxide** (directory jumping)
- **fzf** (fuzzy finding)
- **bat** (previews)

## Relationship to Other Components

- **Starship** shows a `⊢` indicator when inside a Yazi subshell (`$YAZI_LEVEL`)
- **Shell** provides zoxide integration that Yazi's `z` key uses
- Uses the same search tools (fd, rg, fzf) as the shell fzf widgets
