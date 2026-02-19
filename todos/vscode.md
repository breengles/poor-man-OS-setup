# VS Code / Cursor Configuration TODOs

## Priority Summary

| Priority | ID | Description |
|----------|----|-------------|
| P2 | [#1 Massive cSpell dictionary bloats settings file](#1-massive-cspell-dictionary-bloats-settings-file) |
| P2 | [#2 SSH host names exposed in settings](#2-ssh-host-names-exposed-in-settings) |

## Suggested Resolution Order

1. **#2** — Security concern, quick edit to remove or redact host names.
2. **#1** — Large refactor to extract dictionary, moderate effort but improves maintainability.

---

## Detailed Sections

### #1 Massive cSpell dictionary bloats settings file

**Priority:** P2 (Nice-to-have)
**File:** `.vscode/user_settings.json:394-2188`

The `cSpell.userWords` array contains ~1794 words, making the settings file 2218 lines long. This is the vast majority of the file and makes it difficult to find and edit actual settings.

Consider moving the dictionary to a dedicated `.cspell.json` or `cspell.json` file, which the cSpell extension natively supports. This keeps the settings file focused on editor configuration.

**Acceptance criteria:** cSpell dictionary moved to a separate file. `user_settings.json` reduced to only editor settings.

---

### #2 SSH host names exposed in settings

**Priority:** P2 (Nice-to-have)
**File:** `.vscode/user_settings.json:144-151`

The `remote.SSH.remotePlatform` section contains infrastructure-specific host names (`office`, `pair`, `worker0`, `pair2`, `worker1`, `nebius`). Since this is a potentially public dotfiles repo, these internal host names are exposed.

Consider either:
- Moving SSH platform config to a local-only settings file (not tracked in git)
- Documenting that this section should be customized per-machine

**Acceptance criteria:** Internal host names not exposed in the public repository, or a comment explaining the section should be machine-specific.
