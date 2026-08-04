---
name: finalize
description: Close out shipped tracked work by reconciling project documentation with actual code, then removing resolved spec or TODO scaffolding.
---

# Finalize

Code is the source of truth and the tracking artifact is disposable scaffolding.
Do not edit source code.

Resolve the user-provided path as a spec directory containing
`requirements.md` and `tasks.md`, or as a TODO file. With no path, list
discoverable candidates and ask. Do not guess. Resolve documentation scope from
the artifact's owning project, not automatically from the repository root.

Read the artifact, in-scope `docs/`, root README, and applicable `AGENTS.md`.

## Verify readiness

Refuse closeout when any unit is `Pending` or a spec contains a
`[NEEDS CLARIFICATION: ...]` marker. List each problem. A `Blocked` unit may be
deliberately descoped, but requires explicit user confirmation first.

## Find what shipped

Read history over the artifact and changed source paths, then inspect `_Done:_`
notes and actual code. Map shipped modules and behavior to the docs that should
cover them. Include in-scope module docs and root README/AGENTS when setup,
commands, architecture, or other user-facing behavior changed.

Internal refactors, dead-code removal, and tests may require no documentation
change. If the project has no docs directory, confirm that README/AGENTS are the
whole documentation surface before continuing.

## Reconcile documentation

Compare code against each in-scope doc and announce `current`,
`stale: <specific gap>`, or `missing`. If everything is current, proceed to
removal.

Otherwise orchestrate without editing docs in the main session:

1. Dispatch focused Terra/medium `worker` agents with `fork_turns="none"`, unique
   task names, and explicit doc ownership. Use one per independent document,
   sequentially, or one combined updater for entangled docs. Provide the gap,
   `_Done:_` notes, changed code paths, and instructions to read real code,
   update only documentation, maintain doc indexes, and run the repository
   formatter.
2. After each dispatch, call `wait_agent(timeout_ms=3600000)` once. Never poll
   with status queries or repeated short waits.
3. After all updaters finish, dispatch one fresh Sol/high reviewer with
   `fork_turns="none"`. It reads code and docs independently, edits nothing, and
   returns `ALIGNED` or `NEEDS_REVISION` with specific findings. Use one long
   wait again.
4. On `NEEDS_REVISION`, send the findings to the responsible updater with
   `followup_task`, wait once, and re-run a fresh reviewer. Stop after two
   revision rounds. If gaps remain, retain the artifact and report them.

Keep only a one-line result per document in main-session context.

## Remove resolved scaffolding

Print the exact spec directory or TODO rows and sections to remove, then get
explicit user confirmation. Skip units whose documentation remains unresolved.

Use recoverable Git operations: `git rm -r <spec-dir>` for a tracked spec,
`git rm <todo-file>` when no items remain, or edit a partially resolved TODO in
place and format it. Never force removal. If untracked files are present, list
them and ask before touching them.

Report docs updated or already current, the reviewer verdict, removed paths or
sections, and remaining gaps. Leave changes ready for `$commit`; do not commit.
