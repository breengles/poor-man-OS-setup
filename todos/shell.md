# Shell TODOs

## Priority Summary

| Task                                                         | Priority | Status  |
| ------------------------------------------------------------ | -------- | ------- |
| [#1](#1-avoid-double-zshrc-sourcing-in-claude-tmux-contexts) | P2       | Pending |

## Suggested resolution order

- #1 — purely cosmetic/perf, not blocking anything. Pick up when doing other shell startup work.

## Detailed sections

### 1. Avoid double .zshrc sourcing in claude-tmux contexts

The `ccs`/`ccp`/`cct` launchers in `.config/shell/claude-tmux.zsh` spawn a pane/window via
`zsh -ic 'claude; exec zsh -i'`. That means `.zshrc` is sourced twice over the context's
lifecycle: once by the outer `zsh -ic` (so the `claude` shell function is defined), and again
by `exec zsh -i` after claude exits. On macOS this is roughly 100-300ms of extra work per
context.

Options to explore:

- Move heavy one-time setup (PATH, env vars, homebrew shellenv) from `.zshrc` into `.zshenv`
  so it runs once per process, and keep `.zshrc` focused on interactive-only state
  (aliases, prompt, completions, keybindings). Note that `.zshenv` runs for every zsh
  invocation including scripts, so anything put there must be cheap and side-effect-free.
- Alternatively, detect in `_claude_go` whether the real `claude` binary can be invoked
  without pre-sourcing the shell function (e.g. call `~/.claude/update-theme.sh` from the
  launcher itself, then `exec claude` in the pane), eliminating the first zsh entirely.
  Trade-off: loses the theme-sync wrapper for manual `claude` invocations inside the pane
  after the first exit.

Acceptance criteria:

- [ ] Cold-start time of a `ccs` context is within ~100ms of a plain `tmux new -d`.
- [ ] `.zshrc`-sourced interactive features (aliases, prompt, completions, keybindings)
      still work in the post-claude shell.
- [ ] Non-interactive `zsh` invocations are not slowed down by whatever moves to `.zshenv`.
