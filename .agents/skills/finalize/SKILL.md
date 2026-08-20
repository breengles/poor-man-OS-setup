---
name: finalize
description:
  Close out shipped tracked work -- reconcile the project docs with the code that actually shipped, then remove the
  resolved spec directory or TODO items so code plus up-to-date docs remain the source of truth.
---

# finalize

The implementation is done. **Code is the source of truth and the tracking artifact is disposable scaffolding**, so your
job is to make the docs match what shipped and then remove the artifact. You never edit source code here.

Resolve the argument to a spec directory or a TODO file; with no argument, list the candidates under `specs/` and
`todos/` and ask. Read the artifact plus the project's doc surface: `docs/` (if it exists), the root `README.md`, and
`AGENTS.md`.

## Step 1: Verify readiness

Refuse and report if either holds: any unit is still `Pending` (list them), or any `[NEEDS CLARIFICATION:` marker
survives in a spec (report file and line). `Blocked` units are not an automatic refusal -- work can close with
deliberately descoped units, but ask the user to confirm explicitly first.

## Step 2: Find what shipped, and which docs should describe it

Read-only. Run `git log --oneline` over the artifact path and over the source paths the units touched, and read the
`_Done:_` notes. Map which modules the work added or changed, and therefore which docs _should_ cover them.

Doc scope is the in-scope `docs/*.md` for those modules, plus `README.md` / `AGENTS.md` if user-facing setup, commands,
or architecture changed. Add a doc that ought to exist but does not as "missing". Many units (internal refactors,
dead-code removal, added tests) change no documented behavior at all -- if none did, skip to Step 4.

If the project has no `docs/` directory, confirm with the user that `README.md` / `AGENTS.md` are the whole doc surface
before continuing.

## Step 3: Reconcile the docs (orchestrated, Sol/high subagents)

Compare the shipped **code** against each in-scope doc and announce a one-line verdict per file: `current`,
`stale: <the specific gap>`, or `missing`. If everything is current, skip to Step 4.

Otherwise you orchestrate -- **you do not edit docs yourself**:

1. **Dispatch doc-updaters** (`spawn_agent(fork_turns="none", model="gpt-5.6-sol", reasoning_effort="high")` with no
   `agent_type`, so each gets the default general subagent), one per doc when the files are independent (sequentially)
   or one combined updater when they are entangled. Follow every dispatch with one `wait_agent(timeout_ms=3600000)` --
   never `list_agents`, status pings, or repeated short waits. Each prompt gives the doc path(s),
   the specific gap, the `_Done:_` notes and the code paths that changed, and an instruction to **read the real code**
   -- `design.md` is only a hint and may have drifted from what shipped. The updater removes stale content, covers new
   behavior, fixes examples, runs `npx prettier --write --print-width 120` on what it touches, and edits **only**
   documentation -- never source code.
2. **Dispatch one Sol/high reviewer** once the updaters return, on the same `spawn_agent` settings. It reads code and
   docs independently, edits nothing, and returns **ALIGNED** or **NEEDS_REVISION** with specific findings.
3. **ALIGNED** -> continue. **NEEDS_REVISION** -> dispatch a fresh updater with those findings only and re-review,
   **maximum 2 rounds**. Still not aligned after 2 rounds: stop, report the outstanding gaps, and **do not remove the
   artifact**. It stays until the docs can be aligned; the user fixes them manually and re-runs.

Keep your context clean -- one line per doc (`docs/api.md: ALIGNED, rewrote auth section`).

## Step 4: Remove the resolved artifact

The artifact has served its purpose, so remove it without asking. **`git rm` every fully resolved artifact** -- the
work stays recoverable through history, so no confirmation is needed. Never `rm`, never `rm -rf`, and never leave an
emptied-out file behind:

```
git rm -r specs/<feature>/        # spec closed out: the whole directory goes
git rm todos/<area>.md            # TODO file whose every unit is now resolved
```

A resolved spec directory and a TODO file with no surviving units are both **always** `git rm`, not an edit. Only a
TODO file that still has unresolved units is edited in place -- purge the resolved rows and sections, then run
`npx prettier --write --print-width 120` on it. If that edit leaves the file with nothing but headers, `git rm` it
instead.

Skip any unit whose doc cycle stalled at `NEEDS_REVISION` -- those stay. Untracked files under the artifact path are
not covered by history: leave them in place, `git rm` the tracked ones around them, and report what you left. Never
force-remove.

## Step 5: Commit

Commit the doc edits and the artifact removal yourself -- do not leave them staged for the user. Invoke the `commit`
skill so the message follows the repo's convention; a subject like `finalize <feature>, reconcile docs` fits. Commit
only the doc changes and the artifact removal. If unrelated changes are in the working tree, stage the finalize paths
explicitly and leave the rest alone.

Do not commit if the doc cycle stalled at `NEEDS_REVISION` -- report and stop instead.

## Step 6: Report

Docs updated or created (one line each, or "already current"); the reviewer verdict; what was removed; the commit SHA
and subject; and any gaps, deferred work, or code/design deviations you noticed -- print those for the user but do
**not** file them anywhere (suggest a `todos/<area>.md` entry if they want them tracked).

## Constraints

Code wins over docs and over `design.md`, always. No git beyond the `git rm` and the commit above -- never push,
rebase, or amend an existing commit. Doc subagents touch only `docs/`, `README.md`, and `AGENTS.md`. No issue IDs in
anything you write. ASCII only in code and diagrams.
