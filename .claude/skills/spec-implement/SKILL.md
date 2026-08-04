---
name: spec-implement
description: Implement tasks from an approved spec, one at a time, via an independent implementer subagent per task. The main session acts as orchestrator only.
argument-hint: "[feature-name] [task-numbers | all]"
---

# spec-implement

## Role

You are the **orchestrator**. You do NOT write implementation code yourself. For each
task you dispatch a fresh **spec-implementer** subagent that writes the code. You
handle spec reading, task sequencing, committing, and updating `tasks.md`.

## Modes

- **No task numbers**: present pending tasks and ask which to implement (default).
  After each task, ask whether to continue to the next or stop.
- **Task numbers provided** (e.g. `my-feature 2.1 2.3`): implement those tasks in order.
- **Keyword `all`** (e.g. `my-feature all`): implement all pending tasks sequentially.

## Step 1: Resolve the target spec

Parse `$ARGUMENTS` to determine `{feature}`:

- If a feature name is given (e.g. `my-feature`), use `specs/{feature}/`.
- **If no feature name is given, auto-resolve to the most recently modified spec
  directory under `specs/`** (e.g. `ls -1t specs/ | head -n 20` then pick the
  newest entry that is a directory containing a `requirements.md`). If `specs/`
  contains no spec directories, stop and report.

When you auto-resolve, announce the resolved feature name on a single line
(e.g. `Auto-resolved to most recent spec: {feature}`) so the user can interject
if they meant a different one.

If the user later disambiguates by name, switch to that spec.

## Step 1b: Gather context

Read all spec files from `specs/{feature}/`. These reads are independent -- do them
in parallel:

1. `requirements.md` (and parse the YAML frontmatter -- an active spec is `status: active`;
   if `status` is `completed` or `superseded`, stop and report that the spec is already
   closed. Note that finalized specs are normally removed outright, so a lingering closed
   status is unusual -- surface it rather than implementing against it.)
2. `design.md`
3. `tasks.md`
4. `research.md` (if it exists)

If the spec directory does not exist, list available specs under `specs/` and stop.

Also run `git status --porcelain` to note any pre-existing uncommitted changes.

Retain the spec content in your context -- you need it to construct subagent prompts. This
is the only large payload you keep; everything else is summaries.

## Step 2: Build the task queue

Parse `tasks.md` and identify actionable sub-tasks (numbered like 1.1, 2.1, 2.2).
Major tasks (1., 2., 3.) are grouping headers, not execution units.

For each task, check:

- **Already done?** Skip tasks whose Status column is `Done`.
- **Blocked?** Skip tasks whose Status column is `Blocked` (the reason should be
  in the task's detailed section, typically as a `_Blocked:_` line). Report why.
- **Dependencies met?** Check `_Depends:_` annotations in the detailed section --
  all referenced tasks must have Status `Done`. If a prerequisite is incomplete,
  implement it first or warn the user.
- **Boundary scope**: note the `_Boundary:_` annotation if present.
- **Requirements traced**: note the `_Requirements:_` IDs.

Present the task queue to the user and ask for confirmation before proceeding.

## Step 2b: Plan batches for parallel tasks

A **batch** is one or more tasks committed together. Most batches are
size 1. You may batch only when consecutive queued tasks are parallel-eligible --
in spec-implement that means they are marked `(P)` (no dependency on the preceding
task) and have non-overlapping or compatible `_Boundary:_` annotations.

Batching is a **logical** grouping. Implementers still run **strictly
sequentially** -- never dispatch implementers concurrently. What batching changes
is the _unit of commit_: one commit covers the whole batch.

For a multi-task batch, choose ONE strategy:

- **Separate implementers.** Dispatch implementers sequentially (one
  per task), accumulating their changes in the working tree. Once every implementer
  in the batch has returned `COMPLETE`, commit the combined diff.
- **One combined implementer.** If the tasks are semantically
  entangled (overlap on files, share a refactor, only make sense together), pass
  the whole batch to a single implementer in one prompt and commit the combined diff.

Prefer the combined-implementer strategy when splitting would force implementers to
duplicate context or step on each other's edits. Prefer separate implementers when
boundaries are clean.

"Parallel" here only authorizes batching of commits -- it does NOT mean
multiple implementers run at the same time.

## Step 3: Execute tasks (one batch at a time)

For each batch (size 1 by default; see Step 2b), execute this cycle. After each
completed batch, retain only a **one-line summary** (e.g. "1.1: 3 files
changed, commit abc1234"; or "batch [3.1, 3.2, 3.3]: commit abc1234")
and discard the full subagent reports from your working memory.

### 3a. Dispatch implementer(s)

Dispatch the **spec-implementer** subagent via the Agent tool:

```
Agent({
  subagent_type: "spec-implementer",
  prompt: <task-specific context below>
})
```

The prompt must include:

- The full text of the task from `tasks.md` (description, sub-bullets, boundary,
  requirements IDs, depends). For a combined-implementer batch, include the full
  text of every task in the batch and an explicit note that all of them are in
  scope for this implementer.
- The relevant EARS requirements from `requirements.md` (only the sections
  referenced by this task's `_Requirements:_` IDs; union of IDs across the batch)
- The relevant design sections from `design.md` (components, interfaces, data
  models that this task touches based on its boundary)
- Any relevant notes from `research.md`
- The project's test command if known (e.g. `pytest`, `npm test`)

For a separate-implementers batch, dispatch each implementer **sequentially** (wait
for each to return before dispatching the next), repeating step 3b after each one.
Only proceed to step 3c once every implementer in the batch has returned `COMPLETE`.

The implementer's role, execution protocol, and status report format are defined
in its agent file -- do not repeat them in the prompt.

### 3b. Handle implementer status

Parse the implementer's `STATUS` from its `## Status Report` block:

- **COMPLETE**: in a size-1 batch, proceed to step 3c. In a
  separate-implementers batch, dispatch the next task's implementer; only proceed
  to step 3c once every implementer in the batch is `COMPLETE`.
- **BLOCKED**: flip the task's Status column to `Blocked` and append a
  `_Blocked: {reason}_` line to its detailed section in `tasks.md`. If this was
  one task in a separate-implementers batch, drop only that task from the batch
  and continue with the rest; if the batch becomes empty, skip to the next batch.
- **NEEDS_CONTEXT**: re-dispatch once with the requested context; if still unresolved,
  block the task

**Scope check (you do this yourself -- do not delegate it).** Before touching any
tracking file or staging a commit, run `git diff --stat` and `git status --porcelain`
and confirm:

- Every changed file was in the declared scope for this batch. Unexpected files are a
  stop-and-ask, not a commit.
- No pre-existing uncommitted changes from before the run got swept in.
- The change is not obviously empty or a stub (a batch reporting `COMPLETE` with no
  diff, or only comment churn, is a red flag -- re-dispatch or ask).

This is a scope and sanity check on the diff, not a code review. If you want a real
review of the implementation, run `/impl-review` after the run.

**User pushback.** If the user interjects mid-cycle with strong objections to the
implementer's approach ("no, that's wrong", "this won't work", "stop and rethink"),
re-dispatch a fresh implementer with `model: "opus"` passed to the Agent tool, the
original context, and the user's specific objection.

### 3c. Update tasks.md

Run this step **only after** every implementer in the batch has returned
`COMPLETE`. For every completed task in the batch:

- Flip its `Status` column in the Task Summary table from `Pending` to `Done`.
- Append a brief completion note to the task's detailed section, e.g.:

  ```markdown
  ### 1. Add token validation

  ...

  _Done: JWT validation middleware in auth/middleware.py, tested with pytest_
  ```

Also **prune the "Suggested Resolution Order" section** so it lists only the
still-pending tasks. Completed tasks are already tracked via their `Done` status
in the Task Summary table; keeping them in the resolution order just makes it
harder to see what's left. The order is an **unnumbered (bullet) list**, so just
delete the bullets for completed tasks -- there is nothing to renumber.

After editing `tasks.md`, run `npx prettier --write --print-width 120 specs/{feature}/tasks.md`.

### 3d. Commit (orchestrator does this, not subagents)

Stage only the files the implementer(s) changed, plus the `tasks.md` edits
from step 3c. The `tasks.md` update and the implementation changes go in the
**same commit** -- never commit code without the matching `tasks.md` update,
and never commit a `tasks.md` update without the implementation behind it:

```
git add <file1> <file2> ... specs/{feature}/tasks.md
```

**Never** use `git add -A` or `git add .`.

For a size-1 batch, commit with: `feat({feature}): {brief task description}`.
For a multi-task batch, use a single commit covering all tasks in the batch with a
message that summarizes the batch (e.g. `feat({feature}): {shared theme} (tasks
3.1, 3.2, 3.3)`).

Do not include issue IDs in the commit message.

### 3e. Decide next step

- **If task numbers were specified**: move to the next specified task (or batch).
- **If `all` mode**: re-read `tasks.md`, find the next pending task (or parallel
  batch per Step 2b), continue.
- **If default mode**: ask the user whether to continue to the next task/batch
  or stop.

## Step 4: Wrap up

After finishing (all tasks done or user stops), report:

1. **Completed tasks**: list with commit hashes
2. **Blocked tasks**: list with reasons
3. **Remaining tasks**: count still pending
4. **Next step**:
   - If pending tasks remain, suggest `/spec-implement {feature}` in a fresh session.
   - If every task in `tasks.md` is now `Done` (no `Pending`, no unresolved `Blocked`),
     suggest `/spec-finalize {feature}` to reconcile the project docs with the shipped
     code (updating them via opus subagents if stale) and then remove the resolved spec
     -- leaving code + up-to-date docs as the source of truth.

## Critical constraints

- **You are the orchestrator.** Do NOT write implementation code in the main session.
  All code changes come from spec-implementer subagents.
- **Sequential dispatch.** Never dispatch multiple implementers simultaneously --
  even within a parallel-task batch, implementers run one after another. "Parallel"
  in `(P)` markers authorizes batched committing, not concurrent
  execution.
- **Fresh subagents.** Each dispatch is a new Agent call with a new context.
  Never reuse or continue a prior subagent.
- **Selective staging.** Never `git add -A` or `git add .`.
- **No destructive git.** Never `git checkout .`, `git reset --hard`, or similar.
- **Scope discipline.** If the implementer changed files outside the task's boundary,
  do NOT commit those changes. Flag it and ask the user.
- **Spec conflicts.** If the implementer reports a spec conflict (API doesn't exist,
  design is wrong), block the task rather than silently working around it.
- **Context hygiene.** After each task, retain only the one-line summary. Do NOT
  carry forward the full implementer reports into the next task's context.
