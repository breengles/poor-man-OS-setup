# Shell Configuration TODOs

## Priority Summary

| Priority | ID | Description |
|----------|----|-------------|
| P0 | [#1 .zshrc error handling masks source failures](#1-zshrc-error-handling-masks-source-failures) |
| P1 | [#2 Unquoted $HOME in .bashrc fzf source](#2-unquoted-home-in-bashrc-fzf-source) |
| P1 | [#3 NVM loading is synchronous and slow](#3-nvm-loading-is-synchronous-and-slow) |
| P1 | [#4 Duplicate git alias reci in .gitconfig](#4-duplicate-git-alias-reci-in-gitconfig) |
| P1 | [#5 .gitconfig editor hardcodes vim instead of nvim](#5-gitconfig-editor-hardcodes-vim-instead-of-nvim) |
| P1 | [#6 zinit check in update function is unreliable](#6-zinit-check-in-update-function-is-unreliable) |
| P2 | [#7 Duplicated fzf widget logic in keybindings.zsh](#7-duplicated-fzf-widget-logic-in-keybindingszsh) |
| P2 | [#8 gpu function has no argument validation](#8-gpu-function-has-no-argument-validation) |
| P2 | [#9 No starship command guard in .bashrc](#9-no-starship-command-guard-in-bashrc) |
| P2 | [#10 GRADIO_TEMP_DIR mkdir runs on every shell start](#10-gradio_temp_dir-mkdir-runs-on-every-shell-start) |
| P2 | [#11 rsync-synchronize has no short alias](#11-rsync-synchronize-has-no-short-alias) |
| P2 | [#12 Security: .env-global.sh and .gitconfig.local not in .gitignore](#12-security-env-globalsh-and-gitconfiglocal-not-in-gitignore) |
| P2 | [#13 Inconsistent tilde vs $HOME usage across configs](#13-inconsistent-tilde-vs-home-usage-across-configs) |

## Suggested Resolution Order

1. **#1** — Buggy error handling can mislead during debugging. Quick fix.
2. **#4** — Duplicate alias, trivial one-line delete.
3. **#2** — Style guide violation, one-line fix.
4. **#5** — Robustness fix, one-line change.
5. **#6** — Unreliable check, quick fix.
6. **#12** — Security safety net, add two lines to .gitignore.
7. **#9** — Missing guard, one-line addition.
8. **#3** — Performance improvement, moderate effort (lazy-load NVM).
9. **#8** — Missing validation, small addition.
10. **#10** — Minor perf, wrap in guard.
11. **#11** — Trivial consistency fix.
12. **#7** — Refactor, moderate effort but improves maintainability.
13. **#13** — Cosmetic consistency, low priority.

---

## Detailed Sections

### #1 .zshrc error handling masks source failures

**Priority:** P0 (Critical)
**File:** `.zshrc:22-24`

The file sourcing loop uses:

```zsh
[ -f "$file" ] && source "$file" || echo "File $file not found"
```

The `|| echo` branch triggers not only when the file doesn't exist, but also when `source` returns non-zero (e.g., syntax error in the sourced file). This prints the misleading message "File not found" when the real issue is a broken config file. Also, the error goes to stdout instead of stderr.

**Fix:**
```zsh
if [ -f "$file" ]; then
  source "$file"
else
  echo "File $file not found" >&2
fi
```

**Acceptance criteria:** Source errors are not masked by a misleading "not found" message. Errors go to stderr.

---

### #2 Unquoted $HOME in .bashrc fzf source

**Priority:** P1 (Important)
**File:** `.bashrc:56`

```bash
if [ -f $HOME/.fzf.bash ]; then source $HOME/.fzf.bash; fi
```

`$HOME` is not double-quoted in either the test or the source command. Every other line in the file properly quotes `"$HOME"`. Per the project style guide: "Always double-quote variable expansions."

**Acceptance criteria:** Line changed to `if [ -f "$HOME/.fzf.bash" ]; then source "$HOME/.fzf.bash"; fi`.

---

### #3 NVM loading is synchronous and slow

**Priority:** P1 (Important)
**File:** `.zshrc:46-48`

```zsh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

NVM loading typically adds 50-200ms to shell startup. Consider lazy-loading NVM using zinit's `wait` ice or a manual lazy-load wrapper that defers initialization until `nvm`, `node`, or `npm` is first called.

**Acceptance criteria:** Shell startup time not impacted by NVM when Node.js is not immediately needed.

---

### #4 Duplicate git alias reci in .gitconfig

**Priority:** P1 (Important)
**File:** `.gitconfig:10,19`

The alias `reci` (commit --amend -m) is defined twice with identical values. The second definition on line 19 silently overrides the first. One of them should be removed.

**Acceptance criteria:** Only one `reci` alias definition exists in `.gitconfig`.

---

### #5 .gitconfig editor hardcodes vim instead of nvim

**Priority:** P1 (Important)
**File:** `.gitconfig:5`

```ini
editor = vim
```

This relies on the shell alias `alias vim=nvim` from `aliases.sh` to invoke Neovim. However, git invoked from non-interactive contexts (GUI tools, cron, scripts) won't have the alias and will use plain vim.

**Fix:** Change to `editor = nvim` or `editor = $EDITOR` (though the latter may not work in gitconfig; use the full path or just `nvim`).

**Acceptance criteria:** `git commit` opens Neovim even in non-interactive contexts.

---

### #6 zinit check in update function is unreliable

**Priority:** P1 (Important)
**File:** `.config/shell/functions.sh:12`

```bash
if [ -x "$(command -v zinit)" ]
```

`zinit` is a zsh function loaded by the plugin manager, not a standalone executable. `command -v zinit` returns a function definition, and `[ -x ... ]` tests for file executability. This check may produce incorrect results.

**Fix:** Use `type zinit &>/dev/null` or `(( $+functions[zinit] ))`.

**Acceptance criteria:** The `update` function correctly detects whether zinit is available.

---

### #7 Duplicated fzf widget logic in keybindings.zsh

**Priority:** P2 (Nice-to-have)
**File:** `.config/shell/keybindings.zsh:23-82`

Four fzf widgets are defined with nearly identical logic:
- `fzf-vim-widget` (line 23-33) and `fzf-cursor-widget` (line 54-64) differ only in `vim` vs `cursor`
- `fzf-grep-vim-widget` (line 36-51) and `fzf-grep-cursor-widget` (line 67-82) differ only in `vim` vs `cursor`

Refactor into parameterized functions:

```zsh
_fzf_open_widget() {
  local editor="$1"
  local file
  file=$(command fd --type f --hidden --exclude .git 2>/dev/null | fzf ...)
  if [[ -n "$file" ]]; then
    BUFFER="$editor $file"
    zle accept-line
  fi
  zle reset-prompt
}
```

**Acceptance criteria:** Duplicated widget logic consolidated into shared helper functions.

---

### #8 gpu function has no argument validation

**Priority:** P2 (Nice-to-have)
**File:** `.config/shell/functions.sh:106`

```bash
function gpu { ssh "lambda-scalar$1" -t nvitop }
```

If called without arguments, this attempts `ssh lambda-scalar -t nvitop` which may hang or connect to an unintended host. Add a guard:

```bash
function gpu {
  if [ -z "$1" ]; then
    echo "Usage: gpu <node-number>" >&2
    return 1
  fi
  ssh "lambda-scalar$1" -t nvitop
}
```

**Acceptance criteria:** `gpu` with no arguments prints usage and returns an error.

---

### #9 No starship command guard in .bashrc

**Priority:** P2 (Nice-to-have)
**File:** `.bashrc:64`

```bash
eval "$(starship init bash)"
```

This runs unconditionally. If `starship` is not installed, it produces an error. Other tools are guarded with `[ -f ... ]` or `[ -x ... ]` checks.

**Fix:** Wrap with `[ -x "$(command -v starship)" ] && eval "$(starship init bash)"`.

**Acceptance criteria:** No error when starship is not installed.

---

### #10 GRADIO_TEMP_DIR mkdir runs on every shell start

**Priority:** P2 (Nice-to-have)
**File:** `.config/shell/env_vars.sh:6-7`

```bash
export GRADIO_TEMP_DIR="$HOME/.gradio_tmp"
mkdir -p "$GRADIO_TEMP_DIR"
```

`mkdir -p` runs on every shell invocation including non-interactive subshells. While idempotent, it's unnecessary overhead. Guard with:

```bash
[ ! -d "$GRADIO_TEMP_DIR" ] && mkdir -p "$GRADIO_TEMP_DIR"
```

**Acceptance criteria:** `mkdir` only runs when the directory doesn't exist.

---

### #11 rsync-synchronize has no short alias

**Priority:** P2 (Nice-to-have)
**File:** `.config/shell/aliases.sh:10-17`

The rsync aliases define both long-form and short-form versions, except `rsync-synchronize` which has no `rsync` short alias:

- `rsync-copy` / `rcopy`
- `rsync-move` / `rmove`
- `rsync-update` / `rupd`
- `rsync-synchronize` / ??? (missing `rsync` short alias)

**Acceptance criteria:** Add `alias rsync='rsync-synchronize'` or similar short alias for consistency.

---

### #12 Security: .env-global.sh and .gitconfig.local not in .gitignore

**Priority:** P2 (Nice-to-have)
**Files:** `.zshrc:30`, `.gitconfig:2`

`.zshrc` sources `~/.env-global.sh` (presumably contains API tokens). `.gitconfig` includes `~/.gitconfig.local` (may contain credentials). Neither is listed in `.gitignore`.

If someone accidentally places these files in the repo root, they could be tracked and pushed. Adding them to `.gitignore` is a safety net.

**Acceptance criteria:** `.env-global.sh` and `.gitconfig.local` added to `.gitignore`.

---

### #13 Inconsistent tilde vs $HOME usage across configs

**Priority:** P2 (Nice-to-have)
**Files:** `.bashrc:22` (`~/.bash_history`), `.config/shell/history.zsh:3` (`~/.zsh_history`), `.config/shell/env_vars.sh` (`$HOME/...`)

Shell configs inconsistently use `~` and `$HOME` for home directory references. The style guide prefers `"$HOME"` with double-quotes.

**Acceptance criteria:** Consistent use of `"$HOME"` across all shell config files.
