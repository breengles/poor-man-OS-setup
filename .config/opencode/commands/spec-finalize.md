---
description: Close out an implemented spec by removing the resolved spec directory, so code + up-to-date docs remain the source of truth.
argument-hint: "<feature-name>"
---

# spec-finalize

## Role

You are the **closer**. The implementation phase is over. In this project's spec flow,
**code is the source of truth** and a spec is disposable scaffolding: once a feature ships,
the durable record is the code plus the project docs -- not a frozen spec. Your job is to
verify the spec is fully implemented and then remove it entirely, so the repository ends up
with code + docs and no lingering spec.

You do NOT edit application/source code in this skill.

## Parse arguments

- `$ARGUMENTS` should be the kebab-case feature name (matching `specs/<feature-name>/`).
- If no argument is provided, list the spec directories under `specs/` (each is a
  candidate, since finalized specs are removed rather than kept) and ask which to finalize.

## Step 0: Read the spec

Read every file under `specs/<feature-name>/` in parallel:

1. `requirements.md` (parse the YAML frontmatter)
2. `design.md`
3. `tasks.md`
4. `research.md` (if it exists)

If the spec directory does not exist, report that there is nothing to finalize (it may
already have been removed) and stop.

## Step 1: Verify readiness

Refuse to finalize if any of the following hold; report the blocker and stop:

1. **Pending tasks.** Parse the Task Summary table in `tasks.md`. Every row must be `Done`.
   If any row is `Pending`, list them and stop. If any row is `Blocked`, list them and ask
   the user to confirm finalization anyway (a spec can be closed with deliberately descoped
   tasks -- this requires explicit user approval).
2. **Unresolved markers.** Grep `requirements.md` and `design.md` for
   `[NEEDS CLARIFICATION:`. Any remaining marker blocks finalization. Report the file and
   line for each, stop, and ask the user to resolve them first.

There is no status guard: because finalizing removes the spec, a `completed` spec never
exists to re-finalize.

## Step 2: Check the docs against what shipped

Use read-only tools only -- do **not** modify code from this skill. Build a concise picture
of what was delivered:

- Run `git log --oneline -- specs/<feature-name>/` and, for the code paths the tasks
  touched, `git log --oneline -20 -- <source paths>`, to see the actual commits.
- Skim the `_Done:_` completion notes in `tasks.md` for one-liners.

Then compare the shipped code against the project docs that describe the touched components
(`docs/*.md`, plus `README.md` / `CLAUDE.md` if the feature changed user-facing setup,
commands, or architecture). For each in-scope doc, judge whether it is `current` or `stale`.
The spec is about to disappear, so the docs are the only durable prose record: if a doc is
stale, tell the user exactly what is out of date and suggest they update it (e.g. via
`/docs-revise`) before or after removal.

Announce a one-line verdict per doc (`current` / `stale: <gap>`) so the user can interject.

## Step 3: Confirm and remove the resolved spec

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

## Step 4: Report

Print a wrap-up:

- **Doc status:** each in-scope doc (one line): `current` or `stale: <gap>`.
- **Spec removed:** the directory that was deleted.
- **Follow-ups (informational only):** any known gaps, deferred work, or code/design
  deviations you noticed. Print them for the user but do **not** file them anywhere. If the
  user wants them tracked, suggest a `todos/<area>.md` entry.
- **Next step:** the removal is staged-ready. Suggest `/commit` with a message like
  `chore(<feature>): finalize spec` -- but do NOT commit automatically.

## Critical constraints

- **Code is the source of truth.** When the docs or `design.md` disagree with the code, the
  code wins.
- **Read-only on code.** This skill must not edit any application/source code.
- **Removal needs explicit approval.** Never delete the spec directory without the user's
  explicit confirmation. Use `git rm -r` for tracked files; never `rm -rf`; ask before
  touching untracked files.
- **No destructive git.** Never `git reset --hard`, `git checkout .`, force-push, or
  similar. `git rm` of the resolved spec is the only removal, and it remains recoverable via
  history until committed.
- **No index.** There is no `specs/INDEX.md` to maintain; the spec directory's existence is
  the only record, and removing it is what marks the feature done.
- **No issue IDs.** Never include `#N` references in any text you write (commit messages,
  reports). They would auto-close GitLab issues.
- **ASCII only** in code and diagrams; plain prose in markdown is fine.
