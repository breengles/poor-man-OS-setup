# Documentation TODOs

## Priority Summary

| Priority | ID | Description |
|----------|----|-------------|
| P1 | [#1 readme.md mkdir -P typo](#1-readmemd-mkdir--p-typo) |
| P1 | [#2 AGENTS.md references nonexistent .config/Claude/ path](#2-agentsmd-references-nonexistent-configclaude-path) |
| P2 | [#3 Duplicate VS Code extension in readme.md](#3-duplicate-vs-code-extension-in-readmemd) |
| P2 | [#4 readme.md unquoted $HOME variable](#4-readmemd-unquoted-home-variable) |
| P2 | [#5 Outdated cargo install --force for yazi](#5-outdated-cargo-install---force-for-yazi) |

## Suggested Resolution Order

1. **#1** — Typo that would cause the setup command to fail. One-character fix.
2. **#2** — Misleading path reference in the project's main instruction file.
3. **#3** — Causes duplicate install attempt, trivial delete.
4. **#4** — Style guide violation in the setup instructions.
5. **#5** — Outdated install command, verify current yazi crate name.

---

## Detailed Sections

### #1 readme.md mkdir -P typo

**Priority:** P1 (Important)
**File:** `readme.md:8`

```bash
mkdir -P $HOME/.completions
```

The `-P` flag (uppercase) does not exist in standard `mkdir`. This should be `-p` (lowercase) for "create parent directories as needed." Anyone following the setup instructions will get an error on this line.

**Acceptance criteria:** Changed to `mkdir -p "$HOME/.completions"` (also fix quoting per #4).

---

### #2 AGENTS.md references nonexistent .config/Claude/ path

**Priority:** P1 (Important)
**File:** `AGENTS.md` (Repository Structure section)

The AGENTS.md states:
```
.config/
  Claude/                # Claude Code AI tool config
```

And later: "Claude Code: Configured at `.config/Claude/Claude.json`"

However, this directory does not exist in the repository. The actual AI tool config is at `.config/opencode/`. This misleads anyone reading the project documentation.

**Acceptance criteria:** AGENTS.md updated to reflect actual directory structure (either add the Claude config or correct the reference).

---

### #3 Duplicate VS Code extension in readme.md

**Priority:** P2 (Nice-to-have)
**File:** `readme.md:59,83`

`"elazarcoh.simply-view-image-for-python-debugging"` appears twice in the Cursor extensions install list. The second occurrence causes a harmless "already installed" warning but is unnecessary clutter.

**Acceptance criteria:** Duplicate extension entry removed.

---

### #4 readme.md unquoted $HOME variable

**Priority:** P2 (Nice-to-have)
**File:** `readme.md:8`

`$HOME/.completions` is not quoted. Per the project style guide: "Always double-quote variable expansions." Should be `"$HOME/.completions"`.

**Acceptance criteria:** Variable properly quoted in the setup command.

---

### #5 Outdated cargo install --force for yazi

**Priority:** P2 (Nice-to-have)
**File:** `readme.md:46`

```bash
cargo install --force yazi-build
```

- `--force` is a deprecated cargo flag (replaced by `--locked` which is already used on the previous line's cargo install command)
- The crate name `yazi-build` may be outdated; verify with the current Yazi project documentation

**Acceptance criteria:** Cargo command updated to use current flags and correct crate name.
