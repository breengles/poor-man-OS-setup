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
lifecycle: once by the outer `zsh -ic`, and again
by `exec zsh -i` after claude exits. On macOS this is roughly 100-300ms of extra work per
context.

Options to explore:

- Move heavy one-time setup (PATH, env vars, homebrew shellenv) from `.zshrc` into `.zshenv`
  so it runs once per process, and keep `.zshrc` focused on interactive-only state
  (aliases, prompt, completions, keybindings). Note that `.zshenv` runs for every zsh
  invocation including scripts, so anything put there must be cheap and side-effect-free.
- Alternatively, drop the interactive flag on the outer shell. The `-i` in `zsh -ic` existed
  to source `.zshrc` so the `claude` shell wrapper was defined before launch; that wrapper is
  gone, so the outer shell no longer needs `.zshrc` -- provided `claude` is on `PATH` without
  it (which the `.zshenv` move above ensures). Then only the post-exit `exec zsh -i` sources
  `.zshrc`.

Acceptance criteria:

- [ ] Cold-start time of a `ccs` context is within ~100ms of a plain `tmux new -d`.
- [ ] `.zshrc`-sourced interactive features (aliases, prompt, completions, keybindings)
      still work in the post-claude shell.
- [ ] Non-interactive `zsh` invocations are not slowed down by whatever moves to `.zshenv`.
