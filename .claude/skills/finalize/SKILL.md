---
name: finalize
description:
  Close out shipped tracked work -- reconcile the project docs with the code that actually shipped, then remove the
  resolved spec directory or TODO items so code plus up-to-date docs remain the source of truth.
argument-hint: "[<feature> | <area>]"
---

# finalize

The implementation is done. **Code is the source of truth and the tracking artifact is disposable scaffolding**, so your
job is to make the docs match what shipped and then remove the artifact. You never edit source code here.

Resolve `$ARGUMENTS` to a spec directory or a TODO file; with no argument, list the candidates under `specs/` and
`todos/` and ask. Read the artifact plus the project's doc surface: `docs/` (if it exists), the root `README.md`, and
`CLAUDE.md`.

## Step 1: Verify readiness

Refuse and report if either holds: any unit is still `Pending` (list them), or any `[NEEDS CLARIFICATION:` marker
survives in a spec (report file and line). `Blocked` units are not an automatic refusal -- work can close with
deliberately descoped units, but ask the user to confirm explicitly first.

## Step 2: Find what shipped, and which docs should describe it

Read-only. Run `git log --oneline` over the artifact path and over the source paths the units touched, and read the
`_Done:_` notes. Map which modules the work added or changed, and therefore which docs _should_ cover them.

Doc scope is the in-scope `docs/*.md` for those modules, plus `README.md` / `CLAUDE.md` if user-facing setup, commands,
or architecture changed. Add a doc that ought to exist but does not as "missing". Many units (internal refactors,
dead-code removal, added tests) change no documented behavior at all -- if none did, skip to Step 4.

If the project has no `docs/` directory, confirm with the user that `README.md` / `CLAUDE.md` are the whole doc surface
before continuing.

## Step 3: Reconcile the docs (orchestrated, opus subagents)

Compare the shipped **code** against each in-scope doc and announce a one-line verdict per file: `current`,
`stale: <the specific gap>`, or `missing`. If everything is current, skip to Step 4.

Otherwise you orchestrate -- **you do not edit docs yourself**:

1. **Dispatch doc-updaters** (`Agent({subagent_type: "general-purpose", model: "opus"})`), one per doc when the files
   are independent (sequentially) or one combined updater when they are entangled. Each prompt gives the doc path(s),
   the specific gap, the `_Done:_` notes and the code paths that changed, and an instruction to **read the real code**
   -- `design.md` is only a hint and may have drifted from what shipped. The updater removes stale content, covers new
   behavior, fixes examples, runs `npx prettier --write --print-width 120` on what it touches, and edits **only**
   documentation -- never source code.
2. **Dispatch one opus reviewer** once the updaters return. It reads code and docs independently, edits nothing, and
   returns **ALIGNED** or **NEEDS_REVISION** with specific findings.
3. **ALIGNED** -> continue. **NEEDS_REVISION** -> dispatch a fresh updater with those findings only and re-review,
   **maximum 2 rounds**. Still not aligned after 2 rounds: stop, report the outstanding gaps, and **do not remove the
   artifact**. It stays until the docs can be aligned; the user fixes them manually and re-runs.

Keep your context clean -- one line per doc (`docs/api.md: ALIGNED, rewrote auth section`).

## Step 4: Remove the resolved artifact

The artifact has served its purpose. **Removal is destructive -- print exactly what will go and get an explicit yes
first.** For a spec, that is the whole `specs/<feature>/` directory (list its files); for TODOs, the Priority Summary
rows and detailed sections of every purged unit. Skip any unit whose doc cycle stalled at `NEEDS_REVISION` -- those
stay.

On confirmation, use **git** so the work stays recoverable through history -- never `rm -rf`:

```
git rm -r specs/<feature>/        # spec
git rm todos/<area>.md            # TODO file left with no units at all
```

Otherwise edit the TODO file in place and run `npx prettier --write --print-width 120` on it. If `git rm` reports
untracked files, list them and ask before removing anything untracked. Never force-remove.

## Step 5: Commit

Commit the doc edits and the artifact removal yourself -- do not leave them staged for the user. Invoke the `commit`
skill so the message follows the repo's convention; a subject like `finalize <feature>, reconcile docs` fits. Commit
only the doc changes and the artifact removal. If unrelated changes are in the working tree, stage the finalize paths
explicitly and leave the rest alone.

Do not commit if the doc cycle stalled at `NEEDS_REVISION` or the user declined the artifact removal -- report and stop
instead.

## Step 6: Report

Docs updated or created (one line each, or "already current"); the reviewer verdict; what was removed; the commit SHA
and subject; and any gaps, deferred work, or code/design deviations you noticed -- print those for the user but do
**not** file them anywhere (suggest a `todos/<area>.md` entry if they want them tracked).

## Constraints

Code wins over docs and over `design.md`, always. No git beyond the `git rm` and the commit above -- never push,
rebase, or amend an existing commit. Doc subagents touch only `docs/`, `README.md`, and `CLAUDE.md`. No issue IDs in
anything you write. ASCII only in code and diagrams.
