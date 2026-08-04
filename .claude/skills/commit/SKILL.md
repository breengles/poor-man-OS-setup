---
name: commit
description: Create a well-formatted git commit
---

# commit

Review `git diff` and `git diff --cached`, then create well-formed commits. Subject line imperative, lowercase, ~50
characters, and **no type prefix** -- `feat:` / `fix:` / `refactor:` are not used. Describe what changed and why, not
the category. Add a body for the "why" when the change is complex.

- **Only commit changes made during this session.** Leave pre-existing uncommitted work alone unless the user explicitly
  asks to include it.
- **Split into logical commits** when changes are cleanly separable -- different files or independent hunks. A bug fix
  and a new feature are separate commits; a refactor and its test updates are one. When unrelated changes are
  intertwined in the same hunks, commit them together with a message covering both. Never `git stash` or make
  intermediate broken commits just to split something inseparable.
- **Stage selectively** with `git add <files>`. No `git add .` or `-A` unless everything genuinely belongs to one
  commit.
- Never commit secrets (`.env`, credentials, API keys).
- Never include issue IDs (`#5`, `#123`) -- GitLab may auto-close the referenced issue.
- Use plain `git ...`, not `git -C <path> ...`, inside the project.

Finish with `git log --oneline --name-only -n <commits made>`.
