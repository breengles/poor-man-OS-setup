---
name: mr-description
description: Prepare a title and description for a GitLab Merge Request from the current branch to main/master
---

Analyze all changes in the current branch compared to the main/master branch and produce a ready-to-use GitLab Merge Request title and description.

## Workflow

### Step 1: Identify the Base Branch

Determine the base branch:

```
git branch -a | grep -E '(main|master)' | head -1
```

Use whichever of `main` or `master` exists. If both exist, prefer `main`.

### Step 2: Gather Context

1. Get the current branch name:

   ```
   git branch --show-current
   ```

2. Get the merge base:

   ```
   git merge-base HEAD <base-branch>
   ```

3. Get commit messages for context:

   ```
   git log --oneline <merge-base>..HEAD
   ```

4. Get the list of changed files:

   ```
   git diff --name-status <merge-base>..HEAD
   ```

5. Get the full diff:

   ```
   git diff <merge-base>..HEAD
   ```

   If the diff is very large, review file by file.

6. For each changed file, read the full current version to understand context beyond the diff.

### Step 3: Detect Breaking Changes

Identify any breaking changes in the branch. A change is "breaking" if it would force consumers to update their code, configuration, or workflow. Sources to check:

1. Commit messages with a `!` after the type/scope (e.g. `feat!:`, `refactor(api)!:`) per Conventional Commits.
2. Commit bodies/footers containing a `BREAKING CHANGE:` (or `BREAKING-CHANGE:`) trailer.
3. The diff itself — even if commits don't flag it, look for: removed/renamed public APIs, changed function signatures, removed CLI flags or env vars, changed config schema, changed HTTP routes/payloads, changed DB schema without migration, bumped major versions of dependencies.

Collect a short, imperative-mood description for each breaking change (one line each). If you find breaking changes that the commits did NOT flag, ask the user to confirm before including them.

### Step 4: Produce the MR Title and Description

Output a single message containing the MR title and description in GitLab markdown format. The title and description follow [semantic-release](https://semantic-release.gitbook.io/) / [Conventional Commits](https://www.conventionalcommits.org/) conventions so release tooling can parse them.

Use this exact structure:

```
## Title

<type>(<optional scope>)<!>: <short, imperative description under 72 characters>

## Description

BREAKING CHANGE: <first breaking change, one line>

BREAKING CHANGE: <second breaking change, one line>

...

### Summary

<1-3 sentence overview of what this MR does and why>

### Changes

<bulleted list of the key changes, grouped logically>

### Impact

<brief instructions for reviewers to understand the impact of the changes>
```

If there are no breaking changes, omit the `BREAKING CHANGE:` block entirely (do not leave a placeholder).

## Rules

1. **Title** must follow Conventional Commits: `<type>(<optional scope>)<!>: <subject>`.
   - `type` is one of `feat`, `fix`, `perf`, `refactor`, `docs`, `test`, `build`, `ci`, `chore`, `revert`, `style`.
   - Append `!` after the type/scope when the MR introduces breaking changes (e.g. `feat(api)!: drop v1 endpoints`).
   - Subject is concise (whole title under 72 characters), imperative mood, lowercase first letter, no trailing period.
2. **BREAKING CHANGE block** comes first in the description, before `### Summary`. Enumerate one `BREAKING CHANGE:` line per breaking change, separated by blank lines, exactly as semantic-release expects:

   ```
   BREAKING CHANGE: drop support for Node 16

   BREAKING CHANGE: rename `--config` flag to `--config-file`
   ```

   Each line stays on a single line (no wrapping) and uses imperative mood. Omit the entire block if there are no breaking changes. If breaking changes exist, the title MUST include the `!` marker.

3. **Summary** should explain the "why" — motivation and context — not just restate the diff.
4. **Changes** should be a bulleted list of meaningful changes, not a file-by-file dump. Group related changes together. Focus on what matters to a reviewer. Do not just list the changed files.
5. **Impact** should give reviewers concrete steps or commands to get simple expression how to use it if applicable.
6. Agent should interview the user if there are any questions about the changes, the MR, or whether something qualifies as a breaking change.
7. If commits reference GitLab issues, include a `### Related issues` section with links (e.g. `Closes #123` or `Relates to #45`).
8. Do NOT pad the description with boilerplate, caveats, or filler. Keep it tight and useful.
9. Do NOT include issue references that don't actually exist — only include them if the commits or branch name clearly reference real issues.
10. Output the title and description as a single, copy-pasteable message. Do not add commentary before or after.
