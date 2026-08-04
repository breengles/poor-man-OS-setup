---
name: implement
description: Implement tracked work at a given path, one spec task or TODO item at a time, through an independent implementer subagent while the main session orchestrates.
---

# Implement

Act as the orchestrator. Do not write implementation code. For each unit,
dispatch an `implementer`; own artifact reading, sequencing, scope checks,
commits, and artifact updates.

## Resolve the target

Treat the first user-provided value as a relative or absolute path; remaining
values select unit numbers or `all`.

- A directory is spec mode and must contain `tasks.md`. Units are subtasks such
  as `1.1`; major numbers are grouping headers.
- A file is TODO mode. Units are its Priority Summary items.
- With no path, list discoverable spec directories and TODO files and ask. Do
  not auto-pick.

If the path does not exist, stop rather than guessing. Resolve related paths
against the artifact's owning project, not automatically against the repository
root. Read the artifact in full and, for a spec, `requirements.md`, `design.md`,
and optional `research.md`. Record pre-existing changes with
`git status --porcelain`.

## Build the queue

Skip `Done` units. Skip `Blocked` units and report their `_Blocked:_` reason.
Check `_Depends:_` in specs and Suggested Resolution Order in TODOs; warn when a
requested prerequisite remains open. Record each unit's boundary, requirements,
or priority.

Before dispatch, verify each queued problem still exists, especially cited
TODO/FIXME markers and concrete bug symptoms. Flag apparently stale units and
ask before implementing them. Present the dependency-ordered queue and confirm.
With explicit numbers, run those in order; with `all`, run all pending units;
otherwise ask which units to run and check in after each one.

Batching groups a commit, never concurrent execution. Batch only consecutive,
independent units. Use one implementer for an entangled batch or sequential
implementers for separate units. Default batch size is 1.

## Execute one batch at a time

Dispatch `spawn_agent` with `agent_type="implementer"`, `fork_turns="none"`, a
unique task name, and explicit file ownership. Provide the unit's full text,
relevant requirements/design or TODO context, dependencies, deferred work, and
known validation commands. State that the tree is shared and unrelated edits
must not be reverted.

After dispatch, call `wait_agent(timeout_ms=3600000)` once. Never poll with
`list_agents`, status messages, or repeated short waits. If the blocking wait
times out, update the user and make another long wait.

Handle the reported status:

- `COMPLETE`: continue to the scope check.
- `BLOCKED`: set Status to `Blocked`, append `_Blocked: <reason>_`, and drop the
  unit from its batch.
- `NEEDS_CONTEXT`: discover the missing context or ask the user if it requires a
  material choice, then use `followup_task` on the same thread. Block the unit if
  one remediation round does not resolve it.

Capture concerns. In TODO mode, add concerns that are concrete and trackable as
new items; otherwise report them at wrap-up.

Scope-check with `git diff --stat` and `git status --porcelain`. Confirm every
changed file belongs to the declared scope, pre-existing work was not swept in,
and the diff is neither empty nor a stub. Unexpected files require stopping and
asking. This is a scope and sanity check, not code review.

If the user objects mid-cycle, dispatch a fresh Sol/high implementer with the
original context and the specific objection, then use one long wait.

Once every implementer in a batch is `COMPLETE`, mark each unit transiently
`Done`, append `_Done: <what shipped>_`, remove it from Suggested Resolution
Order, and run `npx prettier --write --print-width 120 <artifact>`.

Stage only implementer-owned paths plus the artifact. Never use `git add -A` or
`git add .`. Commit code and artifact together with an imperative lowercase
subject of about 50 characters, no type prefix, and no issue IDs.

## Verify and report

At the end, independently re-read every completed unit's acceptance criteria
against the code. Point to concrete behavior satisfying each criterion or report
the gap without fixing it silently.

Report completed units and commit hashes, blocked units and reasons, remaining
work, concerns, and criteria verification. If work remains, suggest a fresh
`$implement` run with the same path; otherwise suggest `$finalize` with that
path. Do not purge the artifact here.
