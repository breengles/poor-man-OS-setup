---
name: mr-description
description: Generate or apply a GitLab merge request title and description from the actual branch diff.
---

# MR Description

With no MR URL or IID, generate copy-pasteable fields for the current branch.
With an MR URL or IID, resolve it, verify its author and source/target branches,
then update only its title and description. If resolution fails, stop rather than
falling back to generate mode.

Diff from `git merge-base HEAD <target>`, using `main` then `master` only in
generate mode. Read the commits, full diff, and current versions of changed
files. In update mode use the MR's actual target and preserve useful intent from
its existing description.

Use a Conventional Commits title because semantic-release consumes MR titles:
`<type>(<optional scope>)<!>: <imperative lowercase subject>`, under 72
characters. Valid types include `feat`, `fix`, `perf`, `refactor`, `docs`,
`test`, `build`, `ci`, `chore`, `revert`, and `style`.

Mark a breaking change only for a verified incompatible user-facing API, CLI,
configuration, data format, protocol, or supported-platform change. Internal
refactors, tooling, logs, performance work, and fixes restoring documented
behavior are not breaking. Ask before adding an unflagged ambiguous candidate.

Use this description shape, omitting the breaking block when absent:

```markdown
BREAKING CHANGE: <migration-relevant statement>

### Summary

<what and why in 1-3 sentences>

### Changes

- <meaningful grouped changes>
```

Add related issues only when real references exist. Invent no references.
Generate mode outputs only `## Title`, the title, `## Description`, and the body.
Update mode prefers the GitLab MCP, otherwise `glab mr update`, and confirms the
MR URL afterward. Auto Review handles any write approval; never alter labels,
target branch, or draft state unless asked.
