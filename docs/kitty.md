# Kitty Terminal Configuration

## Overview

Kitty is the primary terminal emulator on macOS. The configuration sets up a Nerd Font, custom tab styling, macOS-specific behaviors, and key mappings that translate Cmd/Alt combinations into escape sequences that the shell keybinding modules understand.

## File Structure

| File                       | Description                             |
| -------------------------- | --------------------------------------- |
| `.config/kitty/kitty.conf` | Main configuration                      |
| `.config/kitty/theme.conf` | Custom color theme (dark, KDE-inspired) |

## Font

- **Family**: MonaspiceNe Nerd Font
- **Size**: 18
- **Ligatures**: Disabled (`disable_ligatures always`)
- Bold, italic, and bold-italic variants use auto-detection

## Color Theme

A custom dark theme defined in `theme.conf`:

| Element    | Color                 |
| ---------- | --------------------- |
| Background | `#16181A`             |
| Foreground | `#fcfcfc`             |
| Cursor     | `#fcfcfc`             |
| Black      | `#232627` / `#7f8c8d` |
| Red        | `#ed1515` / `#c0392b` |
| Green      | `#11d116` / `#1cdc9a` |
| Yellow     | `#f67400` / `#fdbc4b` |
| Blue       | `#1d99f3` / `#3daee9` |
| Magenta    | `#9b59b6` / `#8e44ad` |
| Cyan       | `#1abc9c` / `#16a085` |
| White      | `#fcfcfc` / `#ffffff` |

## Tab Bar

Custom tab bar at the top with colored formatting:

- **Style**: Custom (not powerline/separator-based)
- **Position**: Top, left-aligned
- **Active tab**: Gold text (`#FFC552`)
- **Inactive tabs**: Gray text (`#adb5bd`)
- **Stack indicator**: `[]` appended when layout is `stack`
- **Margin**: 15px left, 10px top

## Key Mappings

### Tab Switching

| Key     | Action      |
| ------- | ----------- |
| `Cmd+1` | Go to tab 1 |
| `Cmd+2` | Go to tab 2 |
| ...     | ...         |
| `Cmd+9` | Go to tab 9 |

### Word/Line Navigation

These mappings send escape sequences that the shell keybinding modules interpret:

| Key         | Sends      | Shell interprets as        |
| ----------- | ---------- | -------------------------- |
| `Alt+Left`  | `\x1b\x62` | Backward word (Esc+b)      |
| `Alt+Right` | `\x1b\x66` | Forward word (Esc+f)       |
| `Cmd+Left`  | `\x01`     | Beginning of line (Ctrl+A) |
| `Cmd+Right` | `\x05`     | End of line (Ctrl+E)       |

This is the critical link between Kitty's GUI key events and the shell's readline/ZLE keybindings.

### Mouse

- `Cmd+Left Click`: Opens links (both in grabbed and ungrabbed mode)

## macOS Settings

| Setting                              | Value | Purpose                                    |
| ------------------------------------ | ----- | ------------------------------------------ |
| `macos_quit_when_last_window_closed` | yes   | Quit Kitty when the last window closes     |
| `macos_show_window_title_in_menubar` | no    | Cleaner menu bar                           |
| `macos_option_as_alt`                | yes   | Use Option key as Alt for escape sequences |

`macos_option_as_alt = yes` is essential for Alt-based keybindings to work. Without this, macOS sends special characters instead of escape sequences.

## Window Settings

- **Remember window size**: Yes
- **Initial size**: 100 columns x 36 rows
- **Padding**: 0px vertical, 5px horizontal

## Dependencies

- **Kitty** (install via Homebrew: `brew install --cask kitty`)
- **MonaspiceNe Nerd Font** (`brew install --cask font-monaspace-nerd-font`)

## Relationship to Other Components

- Sends escape sequences that **Shell** keybinding modules (`keybindings.bash`, `keybindings.zsh`) map to word/line navigation
- Hosts **tmux** sessions with true color pass-through
- Font choice (MonaspiceNe Nerd Font) is shared with **Cursor/VS Code** and assumed by **Neovim**
