# Cursor / VS Code Configuration

## Overview

Cursor (a VS Code fork) is the primary GUI editor. The configuration covers editor behavior, Python development (Ruff + Pyright), LaTeX workflows, terminal integration with tmux, Git tooling, and extensive keybinding customization. Settings are designed to work on both macOS and Linux.

## File Structure

| File                         | Description                                |
| ---------------------------- | ------------------------------------------ |
| `.vscode/user_settings.json` | User settings (symlinked to Cursor config) |
| `.vscode/keybindings.json`   | Custom keybindings                         |

Note: These files are in `.vscode/` but are excluded from stow via `.stow-local-ignore`. They serve as a tracked backup — actual deployment is manual or via Cursor's settings sync.

## Editor Settings

### General

| Setting                    | Value                                | Purpose                            |
| -------------------------- | ------------------------------------ | ---------------------------------- |
| `editor.fontSize`          | 18                                   | Matches Kitty terminal font size   |
| `editor.fontFamily`        | MonaspiceNe Nerd Font, CaskaydiaCove | Nerd Font with fallback            |
| `editor.fontLigatures`     | Custom set                           | Selective ligatures enabled        |
| `editor.rulers`            | [120]                                | Line length guide at 120 chars     |
| `editor.tabSize`           | 4 (default)                          | 2 for Lua, Markdown, YAML, Fortran |
| `editor.formatOnSave`      | true                                 | Global format-on-save              |
| `editor.minimap.enabled`   | false                                | Minimap disabled                   |
| `editor.wordWrap`          | on                                   | Soft word wrap                     |
| `editor.detectIndentation` | true                                 | Auto-detect indentation per file   |
| `editor.renderWhitespace`  | selection                            | Show whitespace only in selections |

### File Handling

| Setting                    | Value           | Purpose                           |
| -------------------------- | --------------- | --------------------------------- |
| `files.autoSave`           | onWindowChange  | Save when switching windows       |
| `files.insertFinalNewline` | true            | Always end files with newline     |
| `files.associations`       | `*.log` -> ansi | Syntax highlighting for log files |

### Theme and Icons

- **Color theme**: Default Dark Modern
- **Icon theme**: Material Icon Theme
- **Zoom level**: 0.5

## Language-Specific Settings

### Python

| Setting                                          | Value                | Purpose                   |
| ------------------------------------------------ | -------------------- | ------------------------- |
| `editor.defaultFormatter`                        | `charliermarsh.ruff` | Ruff as primary formatter |
| `ruff.lineLength`                                | 120                  | Match ruler setting       |
| `ruff.lint.ignore`                               | `["F401"]`           | Allow unused imports      |
| `python.analysis.importFormat`                   | relative             | Prefer relative imports   |
| `python.analysis.inlayHints.functionReturnTypes` | true                 | Show return type hints    |
| `python.analysis.completeFunctionParens`         | true                 | Auto-add parentheses      |

Python format-on-save actions: `organizeImports` (Ruff), `fixAll` (Ruff), then format.

### LaTeX

Multiple build recipes configured:

| Recipe                            | Tools                       |
| --------------------------------- | --------------------------- |
| lualatex x2                       | lualatex, lualatex          |
| pdflatex x2                       | pdflatex, pdflatex          |
| lualatex -> biber -> lualatex x2  | Full bibliography workflow  |
| xelatex -> biber -> xelatex x2    | XeTeX bibliography workflow |
| pdflatex -> bibtex -> pdflatex x2 | Classic bibtex workflow     |
| latexmk                           | Automatic build tool        |

LaTeX format-on-save is **disabled**.

### Markdown

- Formatter: Prettier
- Tab size: 2
- markdownlint: MD024 (duplicate headings) disabled

### YAML

- Formatter: Red Hat YAML
- Tab size: 2
- Print width: 120
- Bracket spacing: disabled

### Fortran

- Tab size: 2 (both free and fixed form)
- Formatting: disabled
- Linter: gfortran
- Max line length: 120

## Terminal Integration

### tmux Auto-Session

The integrated terminal defaults to tmux on both Linux and macOS:

```json
"terminal.integrated.defaultProfile.osx": "tmux"
```

The tmux profile creates or reattaches to a session named after the current workspace directory.

### Terminal Settings

| Setting           | Value                 | Purpose                           |
| ----------------- | --------------------- | --------------------------------- |
| `fontSize`        | 16                    | Slightly smaller than editor      |
| `scrollback`      | 20000                 | Large scrollback buffer           |
| `macOptionIsMeta` | true                  | Alt key works as Meta in terminal |
| `fontFamily`      | MonaspiceNe Nerd Font | Match editor font                 |
| `confirmOnKill`   | never                 | Don't confirm terminal kill       |
| `TERM` (Linux)    | xterm-256color        | Ensure color support              |

## Custom Keybindings

### Tab/Editor Navigation

| Key           | Action                            |
| ------------- | --------------------------------- |
| `Cmd+1`-`9`   | Switch to editor tab N            |
| `Cmd+p`       | Show all editors (not quick open) |
| `Cmd+e`       | Quick open with modes             |
| `Shift+Cmd+o` | Open folder                       |
| `Shift+Cmd+r` | Open recent                       |
| `Cmd+0`       | Reset zoom                        |

### Code Actions

| Key            | Action                                |
| -------------- | ------------------------------------- |
| `Cmd+j`        | Go to definition                      |
| `Cmd+r`        | Go to symbol                          |
| `Cmd+\`        | Trigger parameter hints               |
| `Ctrl+Space`   | Trigger autocomplete / inline suggest |
| `Shift+Cmd+i`  | Format document                       |
| `Cmd+k`        | AI generate (Cursor)                  |
| `Shift+Delete` | Delete line                           |

### Git Operations

| Key           | Action                  |
| ------------- | ----------------------- |
| `Cmd+g`       | Open Git Graph          |
| `Shift+Cmd+c` | Focus SCM view          |
| `Alt+s`       | Stage selected ranges   |
| `Shift+Alt+s` | Unstage selected ranges |
| `Alt+r`       | Revert selected ranges  |

### Terminal

| Key                | Action                |
| ------------------ | --------------------- |
| `` Ctrl+` ``       | New terminal editor   |
| `` Ctrl+Shift+` `` | Split terminal editor |

### Window Management

| Key           | Action                   |
| ------------- | ------------------------ |
| `Cmd+b`       | Toggle sidebar           |
| `Shift+Cmd+b` | Toggle auxiliary bar     |
| `Cmd+m`       | Toggle maximized panel   |
| `Ctrl+n`      | New window               |
| `Cmd+n`       | New file (in explorer)   |
| `Shift+Cmd+n` | New folder (in explorer) |
| `F5`          | Refresh file explorer    |
| `Shift+Cmd+d` | Start debugging          |

### Text Manipulation

| Key           | Action                 |
| ------------- | ---------------------- |
| `Cmd+Shift+u` | Transform to UPPERCASE |
| `Cmd+k l`     | Transform to lowercase |

### Preview

| Key           | Action                      |
| ------------- | --------------------------- |
| `Shift+Cmd+v` | Markdown preview            |
| `Shift+Cmd+v` | LaTeX PDF preview (in .tex) |

## Spelling

CSpell is configured with multiple languages: Russian, English (US), English (GB). A personal dictionary file (`~/.cspell-words.txt`) is tracked in the repo with domain-specific terms.

## Extensions

The project README lists all recommended extensions. Key categories:

- **Python**: Ruff, Pyright/Cursorpyright, Debugpy, Jupyter
- **Git**: GitBlame, Git Graph, Git History, Git Worktree Manager
- **LaTeX**: LaTeX Workshop
- **Languages**: ShellCheck, Even Better TOML, Red Hat YAML
- **Formatting**: Prettier, Ruff
- **Utilities**: Todo Tree, Data Preview, Code Spell Checker, Material Icon Theme

## Dependencies

- **Cursor** (or VS Code)
- Extensions listed in `readme.md` (installed via `cursor --install-extension`)
- **MonaspiceNe Nerd Font** and **CaskaydiaCove Nerd Font**
- **tmux** (for terminal integration)

## Relationship to Other Components

- **tmux** sessions are auto-created per workspace in the integrated terminal
- **Font** (MonaspiceNe Nerd Font) is shared with Kitty and Neovim
- **Python tooling** (Ruff line length 120, Pyright basic mode) matches Neovim's LSP config
- **Format-on-save** behavior mirrors Neovim's conform.nvim setup
- **Git** keybindings complement the terminal-based LazyGit workflow in Neovim
