# Neovim Configuration

## Overview

The Neovim configuration is based on [Kickstart.nvim](https://github.com/nvim-kickstart/kickstart.nvim) and uses **lazy.nvim** as the plugin manager. It provides a complete IDE experience with LSP, fuzzy finding, Git integration, autocompletion, and format-on-save. The configuration lives in a single `init.lua` supplemented by modular plugin files.

## File Structure

| File                                                | Description                                              |
| --------------------------------------------------- | -------------------------------------------------------- |
| `.config/nvim/init.lua`                             | Main config: options, keymaps, plugin setup (~508 lines) |
| `.config/nvim/lua/custom/plugins/git.lua`           | LazyGit and Diffview integration                         |
| `.config/nvim/lua/custom/plugins/mycolorscheme.lua` | Custom dark colorscheme                                  |
| `.config/nvim/lua/kickstart/plugins/gitsigns.lua`   | Gitsigns keymaps (hunk navigation, blame toggle)         |
| `.config/nvim/lua/kickstart/health.lua`             | Health check (version + external tools)                  |
| `.config/nvim/lazy-lock.json`                       | Plugin version lockfile                                  |

## Key Configuration Choices

### Leader Key

`Space` is both `mapleader` and `maplocalleader`. Set before any plugins load.

### Clipboard

Clipboard sync (`unnamedplus`) is deferred via `vim.schedule()` to avoid slowing startup:

```lua
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)
```

### Nerd Font Assumption

`vim.g.have_nerd_font = true` — the config assumes a Nerd Font is installed (MonaspiceNe Nerd Font, configured in Kitty). This enables icons in which-key, statusline, and diagnostic signs. Fallback text symbols are defined when Nerd Fonts are unavailable.

### Custom Colorscheme

Instead of using a third-party theme, a custom colorscheme is defined in `mycolorscheme.lua`. It's a dark theme with these main color groups:

| Color             | Hex       | Used for                                |
| ----------------- | --------- | --------------------------------------- |
| Background        | `#1f1f1f` | Normal background                       |
| Foreground        | `#dadada` | Normal text                             |
| Teal              | `#3cb9ab` | Types, Identifiers, PreProc, Errors     |
| Blue              | `#3a7cce` | Constants, Keywords, Repeat             |
| Light blue        | `#81c6f6` | Strings, Numbers, Conditionals, Special |
| Yellow            | `#dad491` | Functions                               |
| Purple            | `#b984b9` | Directories, Includes, Storage          |
| Cyan              | `#6de5ff` | Statements, Operators                   |
| Violet (comments) | `#c481ff` | Comments (italic), NonText              |

## Plugin System

Plugins are managed by **lazy.nvim** (auto-installed on first run).

### Plugin List

| Plugin                 | Purpose                                          |
| ---------------------- | ------------------------------------------------ |
| `guess-indent.nvim`    | Auto-detect indentation                          |
| `gitsigns.nvim`        | Git gutter signs + hunk navigation               |
| `which-key.nvim`       | Keymap discovery popup (0ms delay)               |
| `telescope.nvim`       | Fuzzy finder (files, grep, LSP symbols, buffers) |
| `telescope-fzf-native` | Native fzf sorter for Telescope                  |
| `telescope-ui-select`  | Use Telescope for `vim.ui.select`                |
| `lazydev.nvim`         | Lua LSP workspace library for Neovim API         |
| `nvim-lspconfig`       | LSP client configuration                         |
| `mason.nvim`           | LSP/tool installer                               |
| `mason-lspconfig`      | Bridge between Mason and lspconfig               |
| `mason-tool-installer` | Auto-install specified tools                     |
| `fidget.nvim`          | LSP progress indicator                           |
| `conform.nvim`         | Format-on-save engine                            |
| `blink.cmp`            | Autocompletion (with LuaSnip snippets)           |
| `todo-comments.nvim`   | Highlight TODO/FIXME/NOTE in comments            |
| `mini.nvim`            | AI textobjects, surround, statusline             |
| `nvim-treesitter`      | Syntax highlighting + indent                     |
| `lazygit.nvim`         | LazyGit TUI integration                          |
| `diffview.nvim`        | Multi-file diff viewer + file history            |

## LSP Configuration

### Configured Language Servers

| Server    | Language | Notes                                                       |
| --------- | -------- | ----------------------------------------------------------- |
| `ruff`    | Python   | Linting and formatting; import sorting                      |
| `pyright` | Python   | Type checking (`basic` mode), go-to-definition, completions |
| `lua_ls`  | Lua      | `callSnippet = 'Replace'` for better completion             |

### Python LSP Strategy

Ruff and Pyright work together with clear role separation:

- **Ruff**: linting, formatting, import organization
- **Pyright**: type checking, go-to-definition, references, completions
- Pyright's `disableOrganizeImports = true` avoids conflict with Ruff

A shared `positionEncodings = { 'utf-16' }` capability is set to prevent offset encoding warnings when both servers attach to the same buffer.

### Auto-Installed Tools

Mason automatically installs: `ruff`, `pyright`, `lua_ls`, `stylua`.

## Formatting

Conform.nvim handles format-on-save:

| Filetype | Formatters                                 |
| -------- | ------------------------------------------ |
| Lua      | `stylua`                                   |
| Python   | `ruff_organize_imports` then `ruff_format` |
| C/C++    | Disabled (no format-on-save)               |
| Others   | Falls back to LSP formatting               |

Manual formatting: `<leader>f` formats the current buffer.

## Keymaps

### General

| Key               | Mode | Action                        |
| ----------------- | ---- | ----------------------------- |
| `<Esc>`           | n    | Clear search highlight        |
| `<leader>e`       | n    | Show diagnostic float         |
| `<leader>q`       | n    | Open diagnostic quickfix list |
| `<Esc><Esc>`      | t    | Exit terminal mode            |
| `<C-h/j/k/l>`     | n    | Navigate between splits       |
| `<S-h>` / `<S-l>` | n    | Previous / next buffer        |
| `<leader>f`       | all  | Format buffer                 |

### Telescope (Search)

| Key               | Action                                |
| ----------------- | ------------------------------------- |
| `<leader>sh`      | Search help tags                      |
| `<leader>sk`      | Search keymaps                        |
| `<leader>sf`      | Search files (hidden, excluding .git) |
| `<leader>ss`      | Search Telescope builtins             |
| `<leader>sw`      | Search current word (grep)            |
| `<leader>sg`      | Live grep                             |
| `<leader>sd`      | Search diagnostics                    |
| `<leader>sr`      | Resume last search                    |
| `<leader>s.`      | Search recent files                   |
| `<leader><Space>` | Find open buffers                     |
| `<leader>/`       | Fuzzy search in current buffer        |
| `<leader>s/`      | Live grep in open files               |
| `<leader>sn`      | Search Neovim config files            |

### LSP (on attach)

| Key          | Action                |
| ------------ | --------------------- |
| `grn`        | Rename symbol         |
| `gra`        | Code action           |
| `grr`        | Go to references      |
| `gri`        | Go to implementation  |
| `grd`        | Go to definition      |
| `grD`        | Go to declaration     |
| `gO`         | Document symbols      |
| `gW`         | Workspace symbols     |
| `grt`        | Go to type definition |
| `<leader>th` | Toggle inlay hints    |

### Git

| Key          | Action                      |
| ------------ | --------------------------- |
| `<leader>gg` | Open LazyGit                |
| `<leader>gd` | Toggle Diffview             |
| `<leader>gh` | File history (current file) |
| `<leader>gH` | Branch history (all files)  |
| `<leader>gq` | Close Diffview              |
| `]c` / `[c`  | Next / previous git hunk    |
| `<leader>tb` | Toggle git blame line       |
| `<leader>tD` | Preview hunk inline         |

### Which-Key Groups

| Prefix      | Group name |
| ----------- | ---------- |
| `<leader>s` | [S]earch   |
| `<leader>t` | [T]oggle   |
| `<leader>g` | [G]it      |

## Treesitter

Auto-installed parsers: `bash`, `c`, `diff`, `html`, `lua`, `luadoc`, `markdown`, `markdown_inline`, `python`, `query`, `vim`, `vimdoc`.

Additional parsers are installed automatically when a file of that type is opened (`auto_install = true`).

## Diagnostics

- Sorted by severity
- Rounded floating windows
- Underline only for errors
- Nerd Font icons: `󰅚` (error), `󰀪` (warn), `󰋽` (info), `󰌶` (hint)
- Virtual text with source shown when multiple sources exist

## Dependencies

- **Neovim** >= 0.10
- **git**, **make**, **unzip**, **rg** (verified via `:checkhealth`)
- **Nerd Font** (MonaspiceNe Nerd Font recommended)
- **LazyGit** (for `<leader>gg`)
- **Node.js** (for some LSP servers via Mason)

## Relationship to Other Components

- Uses **MonaspiceNe Nerd Font** configured in Kitty
- `$EDITOR` is set to `nvim` in the shell aliases
- Shell fzf widgets (`Ctrl+O`, `Ctrl+G`) open files in Neovim
- Python formatting matches the Ruff configuration used in Cursor/VS Code
