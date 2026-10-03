# Tasks: Shell Startup

## Task Summary

| Task                                                  | Status  |
| ----------------------------------------------------- | ------- |
| [#1.1](#11-put-the-claude-path-entry-in-zshenv)       | Pending |
| [#1.2](#12-start-claude-from-a-non-interactive-shell) | Pending |

## Suggested Resolution Order

- 1.1 -- foundation: `claude` must be on `PATH` before the outer shell drops `-i`
- 1.2 -- the launcher change itself

## Detailed Tasks

### 1.1 Put the claude PATH entry in .zshenv

Add `$HOME/.local/bin` to `PATH` in `.zshenv`, guarded so repeated shells do not stack duplicates.

Acceptance criteria:

- [ ] `zsh -c 'command -v claude'` prints the claude path without sourcing `.zshrc`.
- [ ] A non-interactive `zsh -c true` stays within the budget in requirement 2.1.

_Requirements: 2.1_ _Boundary: .zshenv_

### 1.2 Start claude from a non-interactive shell

Change `_claude_go` in `.config/shell/claude-tmux.zsh` to build `zsh -c` instead of `zsh -ic`, and update its comments.

Acceptance criteria:

- [ ] A `ccs` context starts claude without sourcing `.zshrc`.
- [ ] After claude exits, the shell has the `.zshrc` aliases, prompt, completions, and keybindings.
- [ ] A `ccs` context reaches a running claude within 100 ms of a plain `tmux new -d` cold start.

_Requirements: 1.1, 1.2, 1.3_ _Depends: 1.1_ _Boundary: claude-tmux launcher_
