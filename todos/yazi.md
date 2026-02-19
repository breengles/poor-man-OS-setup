# Yazi Configuration TODOs

## Priority Summary

| Priority | ID | Description |
|----------|----|-------------|
| P1 | [#1 Key conflict: - mapped to both link and zoom](#1-key-conflict---mapped-to-both-link-and-zoom) |

## Suggested Resolution Order

1. **#1** — The only item. Fixes an inaccessible feature due to key conflict.

---

## Detailed Sections

### #1 Key conflict: - mapped to both link and zoom

**Priority:** P1 (Important)
**File:** `.config/yazi/keymap.toml:176-177,784-786`

The `-` key is mapped to two different actions:

1. **Line 176-177** (base `[mgr]` keymap): `-` maps to `link` (create absolute symlink)
2. **Line 784-786** (`[[mgr.prepend_keymap]]`): `-` maps to `plugin zoom -1` (zoom out)

Since `prepend_keymap` takes priority, the `link` action on `-` is effectively dead code. The symlink feature is inaccessible via its documented key.

**Fix options:**
- Remap `link` to a different key (e.g., `L` or `<C-l>`)
- Remap `zoom -1` to a different key
- Choose which action `-` should perform and rebind the other

**Acceptance criteria:** Both `link` and `zoom -1` are accessible via unique, non-conflicting keys.
