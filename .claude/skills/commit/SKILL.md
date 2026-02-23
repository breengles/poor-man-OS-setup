---
name: commit
description: Create a well-formatted git commit
---

Review all staged and unstaged changes using `git diff` and `git diff --cached`. Analyze the changes and create well-formatted git commits.

Follow these rules:

1. Write concise commit messages following the Conventional Commits format (e.g. feat:, fix:, refactor:, docs:, chore:, test:)
2. The subject line should be max 72 characters
3. Add a body if the changes are complex, explaining the "why" not just the "what"
4. IMPORTANT: Only commit changes that were made during this session. Do NOT commit pre-existing uncommitted changes unless the user explicitly asks to commit all changes.
5. Divide changes into logical, semantic commits when they are cleanly separable (i.e., they touch different files or independent hunks). Group related changes together and separate unrelated changes into distinct commits. For example, a bug fix and a new feature should be separate commits, a refactor and its associated test updates should be one commit. However, if unrelated changes are intertwined in the same files/hunks and cannot be separated without stashing or producing intermediate broken states, commit them together in a single commit with a message that covers all changes. Never use `git stash` or create intermediate partial commits just to split inseparable changes.
6. Stage files selectively for each commit using `git add <specific files>` — do NOT use `git add .` or `git add -A` unless all changes belong to a single logical unit.
7. Do NOT commit files that contain secrets (.env, credentials, API keys)
8. Use plain `git ...` commands instead of `git -C <path> ...` inside the project.
9. Never include issue IDs or numbers (e.g. #5, #123) in commit messages — GitLab interprets #N as an issue reference and may auto-close issues unintentionally.
10. Show the final result with `git log --oneline --name-only -n <number of commits made>` after committing
