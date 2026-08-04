---
name: commit
description: Create one or more well-scoped git commits from changes made in the current session.
---

# Commit

Inspect `git status --short`, `git diff`, and `git diff --cached` before staging.
Commit only changes made in this session unless the user explicitly includes
pre-existing work.

- Split cleanly separable changes into logical commits. Keep intertwined changes
  together rather than stashing or creating a knowingly broken intermediate state.
- Stage explicit paths with `git add <paths>`. Do not use `git add .` or
  `git add -A` unless every visible change unquestionably belongs to one commit.
- Use an imperative, lowercase subject of about 50 characters. Do not add a
  conventional-commit prefix such as `feat:` or `fix:`.
- Add a body when the motivation or trade-off is not obvious from the subject.
- Never include issue IDs, secrets, credentials, or unrelated generated files.
- Use plain `git` commands from the repository root.

After committing, show `git log --oneline --name-only -n <count>` and report any
changes intentionally left uncommitted.
