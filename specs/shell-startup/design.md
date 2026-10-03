# Design: Shell Startup

## Overview

Drop the interactive flag from the outer shell, and make sure `claude` is on `PATH` without `.zshrc`. The outer
`zsh -c` then starts claude directly. Only the post-claude `exec zsh -i` sources `.zshrc`.

## Architecture

- **claude-tmux launcher** (`.config/shell/claude-tmux.zsh`, `_claude_go`): builds the tmux startup command. It changes
  from `zsh -ic <inner>` to `zsh -c <inner>`. The inner command keeps `exec zsh -i`.
- **`.zshenv`**: runs for every zsh, scripts included. It gains the `PATH` entry for the directory that holds the
  `claude` binary, `$HOME/.local/bin`. Today `.config/shell/env_vars.sh` sets it, and only `.zshrc` sources that file.
- **`.zshrc`**: unchanged, apart from not repeating what `.zshenv` now sets.

## Data flow

`ccs` -> `tmux new-window "zsh -c 'claude ...; exec zsh -i'"` -> `.zshenv` -> claude -> on exit, `exec zsh -i` ->
`.zshenv` and `.zshrc` -> interactive shell.

## Data models / interfaces

Startup command, before and after:

```
zsh -ic 'claude <args>; exec zsh -i'    # before: .zshrc sourced twice
zsh -c  'claude <args>; exec zsh -i'    # after: .zshrc sourced once
```

## Decisions

- Drop `-i` on the outer shell. The `-i` existed so the outer shell defined a `claude` wrapper function from `.zshrc`.
  That wrapper is gone.
- Move only the `claude` `PATH` entry into `.zshenv`. Rejected: moving all of `env_vars.sh` and the Homebrew
  `shellenv`, because `.zshenv` runs for every script and must stay cheap and free of side effects.
- Rejected: keep `-ic` and cache `.zshrc` work, because it keeps the double sourcing and adds cache invalidation.

## Error handling

If `claude` is not on `PATH` in the outer shell, the pane prints `command not found` and drops into `exec zsh -i`. The
context survives, so the failure is visible and recoverable.

## Requirements traceability

| Requirement | Design sections                        |
| ----------- | -------------------------------------- |
| 1.1         | Architecture, Data models / interfaces |
| 1.2         | Architecture, Data flow                |
| 1.3         | Overview, Decisions                    |
| 2.1         | Architecture, Decisions                |
