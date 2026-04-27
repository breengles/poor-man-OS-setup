---
name: spec-implement
description: Implement tasks from an approved spec, one at a time, with independent implementer and reviewer subagents per task. The main session acts as orchestrator only.
argument-hint: "<feature-name> [task-numbers | all]"
---

# spec-implement

## Role

You are the **orchestrator**. You do NOT write implementation code yourself. For each
task you dispatch a fresh **spec-implementer** subagent that writes the code, then a
fresh **spec-reviewer** subagent that verifies it. You handle spec reading, task
sequencing, committing, and updating `tasks.md`.

This keeps the main session context clean -- implementation details live in subagent
contexts and don't accumulate here.

## Modes

- **No task numbers**: present pending tasks and ask which to implement (default).
  After each task, ask whether to continue to the next or stop.
- **Task numbers provided** (e.g. `my-feature 2.1 2.3`): implement those tasks in order.
- **Keyword `all`** (e.g. `my-feature all`): implement all pending tasks sequentially.

## Step 1: Gather context

Read all spec files from `specs/{feature}/`. These reads are independent -- do them
in parallel:

1. `requirements.md`
2. `design.md`
3. `tasks.md`
4. `research.md` (if it exists)

If the directory does not exist, list available specs under `specs/` and stop.

Also run `git status --porcelain` to note any pre-existing uncommitted changes.

Retain the spec content in your context -- you need it to construct subagent prompts.
This is the only large payload you keep; everything else is summaries.

## Step 2: Build the task queue

Parse `tasks.md` and identify actionable sub-tasks (numbered like 1.1, 2.1, 2.2).
Major tasks (1., 2., 3.) are grouping headers, not execution units.

For each task, check:

- **Already done?** Skip tasks marked `[x]`.
- **Blocked?** If a task has `_Blocked:_`, skip it and report why.
- **Dependencies met?** Check `_Depends:_` annotations -- all referenced tasks must
  be `[x]`. If a prerequisite is incomplete, implement it first or warn the user.
- **Boundary scope**: note the `_Boundary:_` annotation if present.
- **Requirements traced**: note the `_Requirements:_` IDs.

Present the task queue to the user and ask for confirmation before proceeding.

## Step 2b: Plan batches for parallel tasks

A **batch** is one or more tasks reviewed and committed together. Most batches are
size 1. You may batch only when consecutive queued tasks are parallel-eligible --
in spec-implement that means they are marked `(P)` (no dependency on the preceding
task) and have non-overlapping or compatible `_Boundary:_` annotations.

Batching is a **logical** grouping. Implementers and reviewers still run **strictly
sequentially** -- never dispatch implementers concurrently. What batching changes
is the _unit of review and commit_: one reviewer verdict and one commit cover the
whole batch.

For a multi-task batch, choose ONE strategy:

- **Separate implementers, one reviewer.** Dispatch implementers sequentially (one
  per task), accumulating their changes in the working tree. Once every implementer
  in the batch has returned `READY_FOR_REVIEW`, dispatch a single reviewer for the
  combined diff.
- **One combined implementer, one reviewer.** If the tasks are semantically
  entangled (overlap on files, share a refactor, only make sense together), pass
  the whole batch to a single implementer in one prompt, then dispatch one reviewer
  for the combined diff.

Prefer the combined-implementer strategy when splitting would force implementers to
duplicate context or step on each other's edits. Prefer separate implementers when
boundaries are clean.

"Parallel" here only authorizes batching of review and commit -- it does NOT mean
multiple implementers run at the same time.

## Step 3: Execute tasks (one batch at a time)

For each batch (size 1 by default; see Step 2b), execute this cycle. After each
completed batch, retain only a **one-line summary** (e.g. "1.1: APPROVED, 3 files
changed, commit abc1234"; or "batch [3.1, 3.2, 3.3]: APPROVED, commit abc1234")
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
Only proceed to the reviewer (step 3c) once every implementer in the batch has
returned `READY_FOR_REVIEW`.

The implementer's role, execution protocol, and status report format are defined
in its agent file -- do not repeat them in the prompt.

### 3b. Handle implementer status

Parse the implementer's `STATUS` from its `## Status Report` block:

- **READY_FOR_REVIEW**: in a size-1 batch, proceed to reviewer (step 3c). In a
  separate-implementers batch, dispatch the next task's implementer; only proceed
  to the reviewer once every implementer in the batch is `READY_FOR_REVIEW`.
- **BLOCKED**: append `_Blocked: {reason}_` to the task in `tasks.md`. If this was
  one task in a separate-implementers batch, drop only that task from the batch
  and continue with the rest; if the batch becomes empty, skip to the next batch.
- **NEEDS_CONTEXT**: re-dispatch once with the requested context; if still unresolved,
  block the task

### 3c. Dispatch reviewer

Dispatch the **spec-reviewer** subagent via the Agent tool:

```
Agent({
  subagent_type: "spec-reviewer",
  prompt: <task-specific context below>
})
```

The prompt must include:

- The task description, boundary, and requirement IDs. For a multi-task batch,
  include every task in the batch and make clear that the reviewer must verify
  the combined diff against all of them.
- Paths to the spec files: `specs/{feature}/requirements.md` and
  `specs/{feature}/design.md` (the reviewer reads them independently)
- The implementer's status report (for reference -- the reviewer verifies
  independently by running `git diff`). For a separate-implementers batch,
  concatenate every implementer's status report.

The reviewer's role, checklist, and verdict format are defined in its agent file --
do not repeat them in the prompt.

### 3d. Handle the verdict

Parse the reviewer's `VERDICT` from its `## Review Verdict` block:

- **APPROVED**: proceed to commit (step 3e).
- **REJECTED (round 1)**: dispatch a **new** spec-implementer subagent (default
  Sonnet) with:
  - The original task context
  - The reviewer's specific FINDINGS and REMEDIATION
  - Instruction to fix the cited issues only
    Then re-dispatch the spec-reviewer.
- **REJECTED (round 2)**: **escalate to Opus** -- dispatch a new spec-implementer
  with `model: "opus"` passed to the Agent tool (this overrides the agent's
  frontmatter default). Include the original task context, all accumulated
  FINDINGS from both prior rounds, and a note that this is an escalated attempt
  after two Sonnet rounds failed. Then re-dispatch the spec-reviewer.
- **REJECTED (round 3)**: append `_Blocked: reviewer rejected after 2 fix rounds
(including Opus escalation) -- {summary}_` to the task in `tasks.md`. Report
  to user, move to next task.

**User disagreement escalation.** If the user interjects mid-cycle with strong
pushback on the implementer's approach ("no, that's wrong", "this won't work",
"stop and rethink"), treat the next retry as an escalated Opus round regardless
of rejection count. Pass the user's specific objection as additional input to
the implementer alongside the original task context.

### 3e. Commit (orchestrator does this, not subagents)

Stage only the files the implementer(s) changed, plus `tasks.md`:

```
git add <file1> <file2> ... specs/{feature}/tasks.md
```

**Never** use `git add -A` or `git add .`.

For a size-1 batch, commit with: `feat({feature}): {brief task description}`.
For a multi-task batch, use a single commit covering all tasks in the batch with a
message that summarizes the batch (e.g. `feat({feature}): {shared theme} (tasks
3.1, 3.2, 3.3)`).

Do not include issue IDs in the commit message.

### 3f. Update tasks.md

Mark every task in the batch `[x]` and append a completion note to each:

```markdown
- [x] 2.1 (P) Add token validation middleware -- done: JWT validation
      middleware in auth/middleware.py, tested with pytest
```

### 3g. Decide next step

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
4. **Next step**: if tasks remain, suggest `/spec-implement {feature}` in a fresh session

## Critical constraints

- **You are the orchestrator.** Do NOT write implementation code in the main session.
  All code changes come from spec-implementer subagents.
- **Sequential dispatch.** Never dispatch multiple implementers simultaneously --
  even within a parallel-task batch, implementers run one after another. "Parallel"
  in `(P)` markers authorizes batched review and committing, not concurrent
  execution.
- **Fresh subagents.** Each dispatch is a new Agent call with a new context.
  Never reuse or continue a prior subagent.
- **Selective staging.** Never `git add -A` or `git add .`.
- **No destructive git.** Never `git checkout .`, `git reset --hard`, or similar.
- **Scope discipline.** If the implementer changed files outside the task's boundary,
  do NOT commit those changes. Flag it and ask the user.
- **Spec conflicts.** If the implementer reports a spec conflict (API doesn't exist,
  design is wrong), block the task rather than silently working around it.
- **Bounded retries.** Max 2 fix rounds per reviewer rejection, then block.
- **Context hygiene.** After each task, retain only the one-line summary. Do NOT
  carry forward the full implementer/reviewer reports into the next task's context.
