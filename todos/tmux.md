# tmux Configuration TODOs

## Priority Summary

| Priority | ID | Description |
|----------|----|-------------|
| P1 | [#1 Missing escape-time setting](#1-missing-escape-time-setting) |
| P1 | [#2 Missing focus-events setting](#2-missing-focus-events-setting) |

## Suggested Resolution Order

1. **#1** — Directly impacts Neovim usability inside tmux. One-line fix.
2. **#2** — Improves Neovim autocommand behavior inside tmux. One-line fix.

---

## Detailed Sections

### #1 Missing escape-time setting

**Priority:** P1 (Important)
**File:** `.tmux.conf`

No `set -sg escape-time` is configured. The tmux default is 500ms, which causes a noticeable delay when pressing Escape in Neovim inside tmux. This makes mode switching feel sluggish.

**Fix:** Add to `.tmux.conf`:
```
set -sg escape-time 10
```

Common values are 0-50ms. 10ms is a safe choice that eliminates the perceived delay while still handling escape sequences correctly.

**Acceptance criteria:** Pressing Escape in Neovim inside tmux responds immediately with no perceptible delay.

---

### #2 Missing focus-events setting

**Priority:** P1 (Important)
**File:** `.tmux.conf`

`focus-events` is not enabled. Without it, Neovim doesn't receive `FocusGained`/`FocusLost` events inside tmux. This breaks:
- `autoread` (detecting external file changes)
- `CursorHold`-based autocommands when switching panes
- Plugins that rely on focus events (e.g., auto-save, git status refresh)

**Fix:** Add to `.tmux.conf`:
```
set -g focus-events on
```

**Acceptance criteria:** `:checkhealth` in Neovim inside tmux shows no warnings about focus events.
