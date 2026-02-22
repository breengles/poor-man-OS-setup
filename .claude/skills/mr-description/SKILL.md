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

### Step 3: Produce the MR Title and Description

Output a single message containing the MR title and description in GitLab markdown format. Use this exact structure:

```
## Title

<short, descriptive title under 72 characters>

## Description

### Summary

<1-3 sentence overview of what this MR does and why>

### Changes

<bulleted list of the key changes, grouped logically>

### How to test

<brief instructions for reviewers to verify the changes>
```

## Rules

1. **Title** must be concise (under 72 characters), written in imperative mood (e.g. "Add user authentication" not "Added user authentication").
2. **Summary** should explain the "why" — motivation and context — not just restate the diff.
3. **Changes** should be a bulleted list of meaningful changes, not a file-by-file dump. Group related changes together. Focus on what matters to a reviewer. Do not just list the changed files.
4. **How to test** should give reviewers concrete steps or commands to verify correctness.
5. If commits reference GitLab issues, include a `### Related issues` section with links (e.g. `Closes #123` or `Relates to #45`).
6. Do NOT pad the description with boilerplate, caveats, or filler. Keep it tight and useful.
7. Do NOT include issue references that don't actually exist — only include them if the commits or branch name clearly reference real issues.
8. Output the title and description as a single, copy-pasteable message. Do not add commentary before or after.
