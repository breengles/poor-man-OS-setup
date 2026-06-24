---
name: mr-description
description: Prepare a title and description for a GitLab Merge Request from the current branch to main/master, or apply them directly to an existing MR
argument-hint: "[<MR URL or IID> | leave empty for current branch]"
---

Analyze the changes and produce a ready-to-use GitLab Merge Request title and description following [semantic-release](https://semantic-release.gitbook.io/) / [Conventional Commits](https://www.conventionalcommits.org/) conventions.

## Modes

The behavior depends on the optional argument `$ARGUMENTS`:

- **Generate mode** (`$ARGUMENTS` empty): analyze the **current branch** vs the base branch (`main`, fallback `master`) and output the title and description as a single copy-pasteable message. Do **not** modify any MR.
- **Update mode** (`$ARGUMENTS` is a GitLab MR URL or IID, e.g. `123`, `!123`, or `https://gitlab.example.com/group/proj/-/merge_requests/123`): resolve the referenced MR, analyze its diff, generate the title and description, and **apply them directly to that MR** via `glab mr update`.

In update mode, extract the numeric IID from a URL (the `/-/merge_requests/<iid>` segment) or use the bare number. If the argument does not resolve to an existing MR, stop and tell the user instead of falling back to generate mode.

## Workflow

### Step 1: Identify the Base Branch and (Update Mode) the MR

**Generate mode** -- determine the base branch:

```
git branch -a | grep -E '(main|master)' | head -1
```

Use whichever of `main` or `master` exists. If both exist, prefer `main`.

**Update mode** -- resolve the MR first and confirm it is the right one before overwriting anything:

```
glab mr view <iid>
```

(or the `glab` MCP tools if available). From the MR, capture its **source branch**, **target branch**, current **title**, and current **description**. The target branch is the base branch for the diff -- do not assume `main`/`master`. Briefly confirm the MR matches the work you expect (title/branches). If the MR was authored by someone else or its branches/content clearly do not match, surface that to the user before proceeding rather than overwriting it.

### Step 2: Gather Context

**Generate mode** -- analyze the local branch:

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

**Update mode** -- analyze the MR's diff. If the MR's source branch is checked out locally, prefer the local commands above (diffing against the MR's target branch) so you can read full file versions. Otherwise, use `glab` to fetch the MR's diff and commits:

```
glab mr diff <iid>
```

Use the commit list and changed files from `glab mr view <iid>` plus the diff above as context. Also read the MR's existing description so the regenerated one improves on it rather than discarding intent.

### Step 3: Detect Breaking Changes

In semantic-release terms, a `BREAKING CHANGE` is **only** a change that breaks the **user-facing layer** of the project — anything a downstream consumer (human user, calling service, integrator, or operator) directly relies on. Examples that qualify:

- Public API surface: removed/renamed exported functions, classes, types; changed function signatures; changed return shapes; changed error types.
- HTTP/RPC contracts: removed/renamed routes, changed request/response payloads, changed status codes, changed auth requirements.
- CLI surface: removed/renamed commands, flags, or positional args; changed default behavior of an existing flag.
- Configuration: removed/renamed config keys or env vars; changed accepted value shape; changed defaults that materially alter behavior.
- Inputs/outputs: changed file formats, on-disk layouts, message schemas, DB schemas without a migration path.
- Runtime/platform requirements: dropped support for a previously supported runtime, OS, or major dependency version.

Examples that do **NOT** qualify (do not emit `BREAKING CHANGE` for these):

- Internal refactors, renamed private symbols, reorganized files, changed implementation details.
- Test-only changes, dev tooling, lockfile bumps that don't change the user-visible surface.
- Performance changes, log message wording, internal metric names.
- Bug fixes that restore documented behavior (those are `fix:`, not breaking).

Sources to check, in order:

1. **User assertion.** If the user explicitly says the MR contains breaking changes (and possibly enumerates them), treat that as the starting point — but **validate each claim against the diff** before including it. For each user-asserted breaking change:
   - Confirm the diff actually contains the change at the user-facing layer (per the criteria above).
   - If a claim does not match the diff, or only affects internal code, push back: tell the user what you found and ask whether to drop it, rephrase it, or whether you missed something.
   - If a claim is correct but worded vaguely, rewrite it as a one-line imperative description grounded in the diff.
2. Commit messages with a `!` after the type/scope (e.g. `feat!:`, `refactor(api)!:`) per Conventional Commits.
3. Commit bodies/footers containing a `BREAKING CHANGE:` (or `BREAKING-CHANGE:`) trailer.
4. The diff itself — even if commits don't flag it, look for the user-facing changes listed above. Ignore internal-only churn.

Collect a short, imperative-mood description for each confirmed breaking change (one line each). If you find candidate breaking changes that the user did NOT mention and the commits did NOT flag, ask the user to confirm before including them.

### Step 4: Produce the MR Title and Description

Produce the MR **title** and **description** in GitLab markdown format. The title and description follow [semantic-release](https://semantic-release.gitbook.io/) / [Conventional Commits](https://www.conventionalcommits.org/) conventions so release tooling can parse them.

The **title** is a single line:

```
<type>(<optional scope>)<!>: <short, imperative description under 72 characters>
```

The **description** is everything below — the optional `BREAKING CHANGE:` block followed by the sections:

```
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

The `## Title` / `## Description` headers are presentation only — they delimit the two fields for copy-paste in generate mode. Never write them into the actual MR title/description fields.

### Step 5: Output (Generate Mode) or Apply (Update Mode)

**Generate mode** -- output a single, copy-pasteable message using this exact structure (no commentary before or after):

```
## Title

<the title line>

## Description

<the description body>
```

**Update mode** -- apply the generated title and description directly to the MR:

```
glab mr update <iid> --title "<the title line>" --description "<the description body>"
```

Prefer the `glab_mr_update` MCP tool (pass `title` and the multi-line `description` as its flags) since it handles the multi-line description cleanly. Pass **only** the title line to `--title` and **only** the description body (BREAKING CHANGE block + sections, without the `## Title` / `## Description` headers) to `--description`. Do not change the target branch, draft status, labels, or any other MR field unless the user asked.

After updating, confirm to the user with a one-line summary and the MR URL (from `glab mr view`). If breaking changes were detected, mention that the title now carries the `!` marker so the user is aware the MR will trigger a major release.

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
10. In **generate mode**, output the title and description as a single, copy-pasteable message (per Step 5). Do not add commentary before or after.
11. In **update mode**, never silently overwrite an MR you did not author or that does not match the work — confirm identity first (Step 1). Apply the change directly only after the breaking-change interview (rule 6) is settled, then report what changed with the MR URL.
