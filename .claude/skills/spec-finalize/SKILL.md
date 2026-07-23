---
name: spec-finalize
description: Close out an implemented spec by reconciling the project docs with the shipped code (updating them via opus subagents if stale), then removing the resolved spec directory so code + up-to-date docs remain the source of truth.
argument-hint: "<feature-name>"
---

# spec-finalize

## Role

You are the **closer**. The implementation phase is over. In this project's spec flow,
**code is the source of truth** and a spec is disposable scaffolding: once a feature
ships, the durable record is the code plus the project docs -- not a frozen spec. Your
job is to

1. make sure the docs reflect what actually shipped -- running an opus-subagent update
   cycle if they are stale -- and then
2. remove the resolved spec entirely (its `specs/<feature-name>/` directory),

so the repository ends up with code + up-to-date docs and no lingering spec.

For the doc-update cycle you are the **orchestrator**: you do NOT edit docs yourself.
Opus subagents revise the docs; an opus reviewer subagent verifies alignment against the
code. You never edit application/source code in this skill.

## Parse arguments

- `$ARGUMENTS` should be the kebab-case feature name (matching `specs/<feature-name>/`).
- If no argument is provided, list the spec directories under `specs/` (each is a
  candidate, since finalized specs are removed rather than kept) and ask which to
  finalize.

## Step 0: Read the spec and learn the doc surface

Read every file under `specs/<feature-name>/` in parallel:

1. `requirements.md` (parse the YAML frontmatter)
2. `design.md`
3. `tasks.md`
4. `research.md` (if it exists)

Also read the project's documentation surface so you know what "docs" means here:
`docs/README.md` and the other files under `docs/` (if the directory exists), the root
`README.md`, and `CLAUDE.md`.

If the spec directory does not exist, report that there is nothing to finalize (it may
already have been removed) and stop.

## Step 1: Verify readiness

Refuse to finalize if any of the following hold; report the blocker and stop:

1. **Pending tasks.** Parse the Task Summary table in `tasks.md`. Every row must be
   `Done`. If any row is `Pending`, list them and stop. If any row is `Blocked`, list
   them and ask the user to confirm finalization anyway (a spec can be closed with
   deliberately descoped tasks -- this requires explicit user approval).
2. **Unresolved markers.** Grep `requirements.md` and `design.md` for
   `[NEEDS CLARIFICATION:`. Any remaining marker blocks finalization. Report the file and
   line for each, stop, and ask the user to resolve them first.

There is no status guard: because finalizing removes the spec, a `completed` spec never
exists to re-finalize.

## Step 2: Gather "what shipped" context

Use read-only tools only -- do **not** modify code from this skill. Build a concise
picture of what was delivered so you can scope the docs:

- Run `git log --oneline -- specs/<feature-name>/` and, for the code paths the tasks
  touched, `git log --oneline -20 -- <source paths>`, to see the actual commits.
- Skim the `_Done:_` completion notes in `tasks.md` for one-liners.
- Map which components/modules the feature added or changed, and therefore which doc
  files *should* describe them.

Determine the **doc scope**: the set of documentation that should reflect this feature --
existing `docs/*.md` for the touched components, plus `README.md`/`CLAUDE.md` if the
feature changed user-facing setup, commands, or architecture. If the feature clearly
warrants a doc file that does not exist yet, add it to the scope as "missing". If the
project has no `docs/` directory at all, confirm with the user whether `README.md` /
`CLAUDE.md` are the only doc surface (and thus the only things to reconcile) before
continuing.

## Step 3: Check whether the docs are up to date

Compare the shipped **code** against the in-scope docs, following the `/docs-analyze`
methodology: read each doc, read the source it describes, diff the documented behavior
against the real code, and gauge staleness via git. Produce a short internal verdict per
doc file: **current**, **stale** (with the specific gap), or **missing**.

Announce the verdict on one line per doc (`current` / `stale: <gap>` / `missing`) so the
user can interject.

- If **every** in-scope doc is current and nothing is missing, skip the update cycle and
  go to Step 5.
- Otherwise, run the update cycle in Step 4.

## Step 4: Doc-update cycle (opus subagents, orchestrator loop)

Run an updater + reviewer loop over the stale/missing docs. You orchestrate; opus
subagents do the writing and the verification. Keep your own context clean: after each
doc settles, retain only a one-line summary (e.g. "docs/api.md: ALIGNED, rewrote auth
section") and discard the full subagent reports.

### 4a. Dispatch doc-updater subagent(s)

Dispatch opus subagents via the Agent tool:

```
Agent({
  subagent_type: "general-purpose",
  model: "opus",
  prompt: <doc-update context below>
})
```

Prefer **one updater per doc file** when the files are independent -- dispatch them
sequentially, accumulating edits in the working tree. Use a **single combined updater**
when the docs are entangled (shared sections, one refactor). The prompt must include:

- The doc file path(s) to revise or create.
- The shipped behavior: the relevant `requirements.md` / `design.md` excerpts and the
  `_Done:_` notes, **plus the code paths that changed**. Instruct the subagent to read
  the real code -- the code is the source of truth, and `design.md` is only a hint that
  may have drifted from what shipped.
- The specific gap you found in Step 3 for each doc.
- Instruction to follow the `/docs-revise` methodology: reconcile the doc with the
  current code, remove stale content, add coverage for new behavior, fix examples,
  update the `docs/README.md` index if files were added or removed, and run
  `npx prettier --write --print-width 120` on each file it touches.
- Instruction to edit **only documentation** (`docs/`, `README.md`, `CLAUDE.md`) -- never
  source code.

### 4b. Dispatch doc-reviewer subagent

Once every updater has returned, dispatch one opus reviewer:

```
Agent({
  subagent_type: "general-purpose",
  model: "opus",
  prompt: <review context below>
})
```

The prompt must include:

- The doc file paths that were changed or created.
- The feature's code paths (the source of truth).
- Instruction to follow the `/docs-analyze` methodology and return one of two verdicts:
  **ALIGNED** (the docs now match the shipped code -- no critical inaccuracies and no
  coverage gaps for this feature) or **NEEDS_REVISION** with specific findings.
- Instruction that the reviewer reads code and docs independently (git + Read) and does
  **not** edit anything.

### 4c. Handle the verdict

- **ALIGNED** -> proceed to Step 5.
- **NEEDS_REVISION (round 1 or 2)** -> dispatch a fresh opus doc-updater with the
  reviewer's specific findings only, then re-dispatch the reviewer.
- **Still NEEDS_REVISION after 2 revision rounds** -> stop the cycle. Report the
  outstanding doc gaps and **do not remove the spec**. The spec stays in place until the
  docs can be aligned; the user can fix the docs manually and re-run `/spec-finalize`.

## Step 5: Confirm and remove the resolved spec

The spec has served its purpose -- the truth now lives in code + docs -- so remove it.

**Removal is destructive; get explicit confirmation first.** Print exactly what will be
removed: the `specs/<feature-name>/` directory (list its files).

Ask the user to confirm the removal explicitly. Do not proceed without a clear yes.

On confirmation, remove the spec directory with **git** so it stays recoverable via history
-- never `rm -rf`:

```
git rm -r specs/<feature-name>/
```

If `git rm` reports untracked files, list them and ask the user before removing anything
untracked. Never force-remove.

## Step 6: Report

Print a wrap-up:

- **Docs:** each file updated or created (one line), or "docs already current".
- **Doc-reviewer verdict:** ALIGNED (or the reason the cycle stopped, if it did).
- **Spec removed:** the directory that was deleted.
- **Follow-ups (informational only):** list any known gaps, deferred work, or
  code/design deviations you noticed. Print them for the user but do **not** file them
  anywhere. If the user wants them tracked, suggest a `todos/<area>.md` entry.
- **Next step:** the removals and doc edits are staged-ready. Suggest `/commit` with a
  message like `chore(<feature>): finalize spec, reconcile docs` -- but do NOT commit
  automatically.

## Critical constraints

- **Code is the source of truth.** When the docs or `design.md` disagree with the code,
  the code wins. Every subagent must read the real code, not trust `design.md`.
- **Orchestrator only for docs.** You do NOT edit docs yourself -- opus subagents do. You
  never edit application/source code in this skill; updaters touch only `docs/`,
  `README.md`, and `CLAUDE.md`.
- **Removal needs explicit approval.** Never delete the spec directory without the user's
  explicit confirmation. Use `git rm -r` for tracked files; never `rm -rf`; ask before
  touching untracked files.
- **No destructive git.** Never `git reset --hard`, `git checkout .`, force-push, or
  similar. `git rm` of the resolved spec is the only removal, and it remains recoverable
  via history until committed.
- **Bounded doc-review retries.** Max 2 revision rounds. If the docs cannot be aligned,
  leave the spec in place and report.
- **No index.** There is no `specs/INDEX.md` to maintain; the spec directory's existence
  is the only record, and removing it is what marks the feature done.
- **No issue IDs.** Never include `#N` references in any text you write (commit messages,
  doc edits, reports). They would auto-close GitLab issues.
- **ASCII only** in code and diagrams; plain prose in markdown is fine. Run
  `npx prettier --write --print-width 120` on every markdown file you or a subagent
  modifies.
