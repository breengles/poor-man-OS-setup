# Neovim Configuration TODOs

## Priority Summary

| Priority | ID | Description |
|----------|----|-------------|
| P0 | [#1 lazydev source not in blink.cmp defaults](#1-lazydev-source-not-in-blinkcmp-defaults) |
| P0 | [#2 Duplicate Title highlight in colorscheme](#2-duplicate-title-highlight-in-colorscheme) |
| P1 | [#3 Python missing from treesitter ensure_installed](#3-python-missing-from-treesitter-ensure_installed) |
| P1 | [#4 Hardcoded ruff binary path](#4-hardcoded-ruff-binary-path) |
| P2 | [#5 Unused Kickstart plugin files shipped in repo](#5-unused-kickstart-plugin-files-shipped-in-repo) |
| P2 | [#6 Empty custom/plugins/init.lua placeholder](#6-empty-custompluginsinitlua-placeholder) |
| P2 | [#7 Excessive Kickstart boilerplate comments](#7-excessive-kickstart-boilerplate-comments) |

## Suggested Resolution Order

1. **#1** — Broken feature: lazydev completions silently not working. One-line fix.
2. **#2** — Dead code bug causing unintended color. Quick fix, remove duplicate line.
3. **#3** — Python is the primary dev language; adding it to ensure_installed is trivial.
4. **#4** — Hardcoded path may break on different systems. Replace with dynamic lookup.
5. **#5** — Cleanup of dead files, low risk.
6. **#6** — Trivial cleanup.
7. **#7** — Large effort, low impact. Do incrementally as you touch init.lua.

---

## Detailed Sections

### #1 lazydev source not in blink.cmp defaults

**Priority:** P0 (Critical)
**File:** `.config/nvim/init.lua:888-891`

The `lazydev` provider is registered as a blink.cmp provider (line 890) but is not included in the `default` sources list on line 888:

```lua
default = { 'lsp', 'path', 'snippets' },
```

This means Neovim API type completions from lazydev never appear. The fix is to add `'lazydev'` to the defaults:

```lua
default = { 'lazydev', 'lsp', 'path', 'snippets' },
```

**Acceptance criteria:** After fix, typing `vim.api.` in a Lua file inside the nvim config should show Neovim API completions from lazydev.

---

### #2 Duplicate Title highlight in colorscheme

**Priority:** P0 (Critical)
**File:** `.config/nvim/lua/custom/plugins/mycolorscheme.lua:52,93`

`Title` highlight group is defined twice:

- Line 52: `hi('Title', { fg = '#81c6f6' })` (light blue)
- Line 93: `hi('Title', { fg = '#dadada' })` (white/gray)

The second definition silently overrides the first. Line 52 is dead code. Either:
- Remove line 52 (if white/gray is intended), or
- Remove line 93 (if light blue is intended).

**Acceptance criteria:** Only one `Title` highlight definition exists in the file.

---

### #3 Python missing from treesitter ensure_installed

**Priority:** P1 (Important)
**File:** `.config/nvim/init.lua:969`

The `ensure_installed` list includes bash, c, diff, html, lua, luadoc, markdown, markdown_inline, query, vim, vimdoc — but not `python`, despite Python being the primary development language (extensive Python tooling in VS Code settings, ruff LSP, pyright).

While `auto_install = true` will handle this on demand, explicit listing is more deterministic and avoids a first-open delay.

**Acceptance criteria:** `'python'` added to `ensure_installed` list.

---

### #4 Hardcoded ruff binary path

**Priority:** P1 (Important)
**File:** `.config/nvim/init.lua:699`

```lua
cmd = { vim.fn.expand '$HOME/.local/bin/ruff', 'server' },
```

This hardcodes the ruff binary location. If ruff is installed via Mason, Homebrew, or a different path on Linux vs macOS, this will fail silently or use the wrong binary. Consider:

```lua
cmd = { vim.fn.exepath('ruff') ~= '' and vim.fn.exepath('ruff') or (vim.fn.expand '$HOME/.local/bin/ruff'), 'server' },
```

Or better, let Mason manage ruff and remove the hardcoded path.

**Acceptance criteria:** Ruff LSP works regardless of where ruff is installed on the system.

---

### #5 Unused Kickstart plugin files shipped in repo

**Priority:** P2 (Nice-to-have)
**Files:**
- `.config/nvim/lua/kickstart/plugins/debug.lua`
- `.config/nvim/lua/kickstart/plugins/indent_line.lua`
- `.config/nvim/lua/kickstart/plugins/lint.lua`
- `.config/nvim/lua/kickstart/plugins/autopairs.lua`
- `.config/nvim/lua/kickstart/plugins/neo-tree.lua`

These five files are never loaded (all commented out in init.lua lines 998-1002). They are stowed into `~/.config/nvim/` but serve no purpose. Consider deleting them or adding a note about why they're kept.

**Acceptance criteria:** Unused plugin files removed, or a comment explaining they're kept intentionally.

---

### #6 Empty custom/plugins/init.lua placeholder

**Priority:** P2 (Nice-to-have)
**File:** `.config/nvim/lua/custom/plugins/init.lua`

This file contains only `return {}`. The actual custom plugins (git.lua, mycolorscheme.lua) are auto-discovered by `{ import = 'custom.plugins' }` in init.lua. This empty file is unnecessary.

**Acceptance criteria:** File removed if lazy.nvim auto-import works without it, or kept with a comment explaining it's required.

---

### #7 Excessive Kickstart boilerplate comments

**Priority:** P2 (Nice-to-have)
**File:** `.config/nvim/init.lua` (throughout)

The file is 1039 lines with roughly 40% being Kickstart tutorial comments (lines 46-88 intro, numerous NOTE: blocks, commented-out examples at lines 189-192, 204-207, 266-273, 833-838, 912-921). These make the file harder to scan for actual configuration.

This is low priority and should be done incrementally — remove tutorial comments as you touch nearby code rather than in one large pass.

**Acceptance criteria:** Tutorial comments reduced to essential documentation only.
