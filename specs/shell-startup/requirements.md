---
status: active
started: 2026-10-03
supersedes:
---

# Requirements: Shell Startup

## Summary

The `ccs`, `ccp`, and `cct` launchers in `.config/shell/claude-tmux.zsh` start each context with
`zsh -ic 'claude; exec zsh -i'`. So `.zshrc` is sourced twice per context: once by the outer `zsh -ic`, and again by
`exec zsh -i` after claude exits. On macOS this costs about 100-300 ms per context. This spec removes the first
sourcing for the user who opens claude contexts in tmux.

## In scope

- The startup command the claude-tmux launchers build
- Moving the setup that `claude` needs before launch from `.zshrc` into `.zshenv`

## Out of scope

- Other shell startup optimizations
- bash startup

## Requirements

## 1. Launcher startup

1.1 When the user starts a context with `ccs`, `ccp`, or `cct`, the claude-tmux launcher shall start claude without
sourcing `.zshrc`.

1.2 When claude exits in a launcher context, the post-claude shell shall provide the aliases, prompt, completions, and
keybindings that `.zshrc` sets up.

1.3 When the user starts a context with `ccs`, the claude-tmux launcher shall reach a running claude within 100 ms of
the cold-start time of a plain `tmux new -d`.

## 2. Non-interactive shells

2.1 While zsh runs non-interactively, `.zshenv` shall add no more than [NEEDS CLARIFICATION: budget in ms over today's
`zsh -c true` time] to its startup.

## Open questions

- What startup budget may `.zshenv` add to a non-interactive `zsh -c true`?
