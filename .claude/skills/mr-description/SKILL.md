---
name: mr-description
description:
  Prepare a title and description for a GitLab Merge Request from the current branch to main/master, or apply them
  directly to an existing MR
argument-hint: "[<MR URL or IID> | leave empty for current branch]"
---

# mr-description

Produce a GitLab MR title and description following [Conventional Commits](https://www.conventionalcommits.org/) so
semantic-release can parse them.

**Generate mode** (`$ARGUMENTS` empty): analyze the current branch against its base (`main`, fallback `master`) and
output the title and description as one copy-pasteable message. Modify no MR.

**Update mode** (`$ARGUMENTS` is an MR URL or IID -- `123`, `!123`, or a `/-/merge_requests/<iid>` URL): resolve the MR
with `glab mr view <iid>` (or the `glab` MCP tools), capture its source branch, **target branch** (the diff base -- do
not assume `main`), current title, and current description, then apply the regenerated pair with `glab mr update`.
Confirm the MR is the right one first: if it was authored by someone else, or its branches and content clearly do not
match the work, surface that before overwriting. If the argument resolves to no MR, stop -- never fall back to generate
mode.

## Gather context

Diff against the base (`git merge-base HEAD <base>`), then read the commit list, the changed-file list, and the full
diff. **Read the full current version of each changed file** -- the diff hides surrounding context. Read any issue or
spec the commits reference. In update mode prefer the local checkout when the source branch is available so you can read
whole files, else `glab mr diff <iid>`; read the existing description so the new one improves on it rather than
discarding intent.

## Breaking changes

A `BREAKING CHANGE` is **only** something that breaks the **user-facing layer** -- what a downstream consumer,
integrator, or operator directly relies on:

- Public API: removed or renamed exports, changed signatures, changed return shapes or error types
- HTTP/RPC: removed or renamed routes, changed payloads, status codes, or auth requirements
- CLI: removed or renamed commands, flags, or positional args; changed default behavior of a flag
- Config: removed or renamed keys or env vars, changed accepted value shape, changed defaults that materially alter
  behavior
- Data: changed file formats, on-disk layouts, message or DB schemas without a migration path
- Platform: dropped support for a runtime, OS, or major dependency version

These do **not** qualify: internal refactors and renamed private symbols, test-only or dev-tooling changes, lockfile
bumps, performance work, log wording, internal metric names, and bug fixes that restore documented behavior (those are
`fix:`).

Check, in order: (1) the user's own assertion -- but **validate each claim against the diff**, and push back if a claim
only touches internal code or does not appear at all; (2) commits with `!` after the type/scope; (3) `BREAKING CHANGE:`
trailers in commit bodies; (4) the diff itself. Ask before including a candidate the user did not mention and the
commits did not flag.

## Output

The **title** is one line: `<type>(<optional scope>)<!>: <subject>`. `type` is one of `feat`, `fix`, `perf`, `refactor`,
`docs`, `test`, `build`, `ci`, `chore`, `revert`, `style`. Append `!` when there are breaking changes. The subject is
imperative, lowercase, no trailing period, whole title under 72 characters.

The **description** is the optional breaking-change block followed by three sections:

```
BREAKING CHANGE: <one line, imperative, no wrapping>

BREAKING CHANGE: <second one, blank line between>

### Summary

<1-3 sentences on what this does and why -- the motivation, not a restatement of the diff>

### Changes

<bulleted list of meaningful changes, grouped logically -- not a file-by-file dump>

### Impact

<what a reviewer should check, with concrete commands where they apply>
```

Omit the breaking-change block entirely when there are none -- no placeholder. If any exist, the title MUST carry `!`.
Add a `### Related issues` section only when commits or the branch name reference real GitLab issues.

**Generate mode** -- output exactly `## Title`, the title line, `## Description`, and the description body, with no
commentary around it. Those two headers are presentation only, delimiting the fields for copy-paste; never write them
into an MR.

**Update mode** -- apply with the `glab_mr_update` MCP tool where available (it handles the multi-line description
cleanly), else `glab mr update <iid> --title "..." --description "..."`. Pass only the title line and only the
description body. Change no other MR field -- not the target branch, draft status, or labels -- unless asked. Confirm
with a one-line summary and the MR URL, noting the `!` marker if present so the user knows a major release will trigger.

Interview the user about anything unclear rather than guessing. No filler, boilerplate, or invented issue references.
