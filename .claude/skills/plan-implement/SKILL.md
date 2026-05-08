---
name: plan-implement
description: Implement an in-session implementation plan, one step at a time, with independent implementer and reviewer subagents per step. The main session acts as orchestrator only. Use when the user has just drafted a plan (in plan mode or in chat) or pointed at a plan file and now wants it executed step-by-step with an implementer/reviewer loop -- as opposed to ad-hoc coding in the main session.
argument-hint: "[plan-file-path] [step-numbers | all]"
---

# plan-implement

## Role

You are the **orchestrator**. You do NOT write implementation code yourself. For
each step you dispatch a fresh **plan-implementer** subagent that writes the code,
then a fresh **plan-reviewer** subagent that verifies it. You handle plan parsing,
step sequencing, committing, and progress tracking.

This keeps the main session context clean -- implementation details live in
subagent contexts and don't accumulate here.

This skill is the free-form counterpart to `/spec-implement` and `/todo-implement`.
Use it when the plan exists in the conversation or in a one-off file rather than
in a `specs/<feature>/` or `todos/<area>.md` artifact.

## Modes

- **No step numbers**: present the parsed step list and ask which to implement
  (default). After each step, ask whether to continue to the next or stop.
- **Step numbers provided** (e.g. `plan.md 1 3 5` or just `1 3 5` if the plan is
  in-conversation): implement those steps in order.
- **Keyword `all`** (e.g. `all` or `plan.md all`): implement every pending step
  sequentially.

## Step 1: Resolve the plan source

Parse `$ARGUMENTS`:

- If the first argument is a path that exists (e.g. `plan.md`,
  `docs/refactor-plan.md`), read it and treat its contents as the plan.
- Otherwise, look for a plan in the current conversation context. The plan is
  typically:
  - The output of a recent **plan mode** session (`ExitPlanMode` payload)
  - A multi-step proposal you or the user wrote out earlier in the conversation
  - A markdown block the user pasted

If no plan can be located, stop and ask the user to either pass a path or paste
the plan they want implemented.

Run `git status --porcelain` and note any pre-existing uncommitted changes
(those are not your work, do not bundle them into commits).

Retain the plan content in your context -- you need it to construct subagent
prompts. This is the only large payload you keep; everything else is summaries.

## Step 2: Normalize into a step list

Plans often arrive as prose, bullet lists, or numbered sections. Before
dispatching anything, normalize the plan into a numbered list of **steps**, where
each step is:

- A short title (5-10 words)
- A concrete goal ("what does this step deliver?")
- Files / modules expected to change
- Acceptance criteria (extracted from the plan; if missing, derive them and make
  them explicit)
- Optional notes (design constraints, things to avoid, follow-up steps to defer)

If the plan is already cleanly numbered, keep its numbering. Otherwise assign
your own (1, 2, 3, ...).

Track the step list using `TaskCreate` (one task per step) so the user can
follow progress live. The task list is the orchestrator's working tracker; it is
ephemeral and lives only for this session.

Present the normalized step list to the user and **ask for confirmation** before
dispatching the first implementer. The user may edit, reorder, or split/merge
steps. Update your tracker accordingly.

## Step 2b: Plan batches for independent steps

A **batch** is one or more steps reviewed and committed together. Most batches
are size 1. You may batch only when consecutive queued steps are independent of
each other -- they touch unrelated files or share a clear theme and have no
sequential dependency.

Batching is a **logical** grouping. Implementers and reviewers still run
**strictly sequentially** -- never dispatch implementers concurrently. What
batching changes is the _unit of review and commit_: one reviewer verdict and
one commit cover the whole batch.

For a multi-step batch, choose ONE strategy:

- **Separate implementers, one reviewer.** Dispatch implementers sequentially
  (one per step), accumulating their changes in the working tree. Once every
  implementer in the batch has returned `READY_FOR_REVIEW`, dispatch a single
  reviewer for the combined diff.
- **One combined implementer, one reviewer.** If the steps are semantically
  entangled (overlap on files, share a refactor, only make sense together),
  pass the whole batch to a single implementer in one prompt, then dispatch
  one reviewer for the combined diff.

Prefer the combined-implementer strategy when splitting would force implementers
to duplicate context or step on each other's edits. Prefer separate implementers
when the steps are clearly disjoint.

"Independent" / "parallel" here only authorizes batching of review and commit --
it does NOT mean multiple implementers run at the same time.

## Step 3: Execute steps (one batch at a time)

For each batch (size 1 by default; see Step 2b), execute this cycle. After each
completed batch, retain only a **one-line summary** (e.g. "step 2: APPROVED,
3 files changed, commit abc1234"; or "batch [3, 4, 5]: APPROVED, commit
abc1234") and discard the full subagent reports from your working memory.

Mark the corresponding `TaskCreate` entries `in_progress` when you dispatch and
`completed` when the batch is approved and committed.

### 3a. Dispatch implementer(s)

Dispatch the **plan-implementer** subagent via the Agent tool:

```
Agent({
  subagent_type: "plan-implementer",
  prompt: <step-specific context below>
})
```

The prompt must include:

- The step number and one-line title. For a combined-implementer batch, list
  every step number in the batch and make explicit that all of them are in
  scope for this implementer.
- The full normalized step content (goal, files, acceptance criteria, notes).
  Include all steps in the batch when using a combined implementer.
- Brief context on **preceding steps** if their results materially shape the
  current state of the working tree (e.g. "step 1 already added a new module
  at src/auth/jwt.py; you will be importing from it").
- Brief context on **upcoming steps** so the implementer knows what NOT to do
  yet (helps avoid scope creep).
- If a plan file exists on disk, its path -- so the implementer can re-read
  it independently.
- The project's test command if known (e.g. `pytest`, `npm test`).

For a separate-implementers batch, dispatch each implementer **sequentially**
(wait for each to return before dispatching the next), repeating step 3b after
each one. Only proceed to the reviewer (step 3c) once every implementer in the
batch has returned `READY_FOR_REVIEW`.

The implementer's role, execution protocol, and status report format are defined
in its agent file -- do not repeat them in the prompt.

### 3b. Handle implementer status

Parse the implementer's `STATUS` from its `## Status Report` block:

- **READY_FOR_REVIEW**: in a size-1 batch, proceed to reviewer (step 3c). In a
  separate-implementers batch, dispatch the next step's implementer; only
  proceed to the reviewer once every implementer in the batch is
  `READY_FOR_REVIEW`.
- **BLOCKED**: mark the step's `TaskCreate` entry `cancelled` (with the
  blocker as a note) and report to the user. If this was one step in a
  separate-implementers batch, drop only that step from the batch and continue
  with the rest; if the batch becomes empty, skip to the next batch.
- **NEEDS_CONTEXT**: re-dispatch once with the requested context; if still
  unresolved, treat as BLOCKED.

Also capture any `CONCERNS` field -- if the implementer flagged unrelated
issues they noticed, you will surface those at wrap-up (step 4).

### 3c. Dispatch reviewer

Dispatch the **plan-reviewer** subagent via the Agent tool:

```
Agent({
  subagent_type: "plan-reviewer",
  prompt: <step-specific context below>
})
```

The prompt must include:

- The step number and one-line title. For a multi-step batch, list every step
  in the batch and make clear the reviewer must verify the combined diff
  against all of them.
- The full normalized step content (goal, files, acceptance criteria, notes).
  Include all steps in the batch.
- The path to the plan file on disk if one exists (so the reviewer can read it
  independently).
- The implementer's status report (for reference -- the reviewer verifies
  independently by running `git diff`). For a separate-implementers batch,
  concatenate every implementer's status report.

The reviewer's role, checklist, and verdict format are defined in its agent
file -- do not repeat them in the prompt.

### 3d. Handle the verdict

Parse the reviewer's `VERDICT` from its `## Review Verdict` block:

- **APPROVED**: proceed to commit (step 3e). Mark the step's `TaskCreate`
  entry `completed`.
- **REJECTED (round 1)**: dispatch a **new** plan-implementer subagent
  (default Sonnet) with:
  - The original step context
  - The reviewer's specific FINDINGS and REMEDIATION
  - Instruction to fix the cited issues only
    Then re-dispatch the plan-reviewer.
- **REJECTED (round 2)**: **escalate to Opus** -- dispatch a new
  plan-implementer with `model: "opus"` passed to the Agent tool (this
  overrides the agent's frontmatter default). Include the original step
  context, all accumulated FINDINGS from both prior rounds, and a note that
  this is an escalated attempt after two Sonnet rounds failed. Then
  re-dispatch the plan-reviewer.
- **REJECTED (round 3)**: mark the step's `TaskCreate` entry `cancelled`
  with note `reviewer rejected after 2 fix rounds (incl. Opus escalation) --
{summary}`. Report to the user and move to the next step.

**Critical ordering:** never mark a step `completed` in the tracker, and never
land a commit, until the reviewer's verdict is `APPROVED` for the batch that
contains it. While the verdict is still `REJECTED` (across any retry round),
keep the step `in_progress` -- it is not done yet.

**User disagreement escalation.** If the user interjects mid-cycle with strong
pushback on the implementer's approach ("no, that's wrong", "this won't work",
"stop and rethink"), treat the next retry as an escalated Opus round
regardless of rejection count. Pass the user's specific objection as
additional input to the implementer alongside the original step context.

### 3e. Commit (orchestrator does this, not subagents)

Stage only the files the implementer(s) changed:

```
git add <file1> <file2> ...
```

**Never** use `git add -A` or `git add .`.

For a size-1 batch, derive a conventional-commit-style message from the step
title:

- `feat: {title}` for new behavior
- `fix: {title}` for bug fixes
- `refactor: {title}` for refactors with no behavior change
- `chore: {title}` / `docs: {title}` / `test: {title}` as appropriate

For a multi-step batch, summarize the batch in a single commit message
(e.g. `refactor: {shared theme} (steps 3, 4, 5)`).

If the plan file lives on disk and you want to record progress in it, prefer
adding completion notes there in a **separate, follow-up commit** -- do not
mix plan-tracking edits into the implementation commit unless the user has
explicitly asked for it.

Do not include issue IDs (`#N`) in the commit message -- GitLab interprets
them as issue references and may auto-close issues unintentionally.

### 3f. Decide next step

- **If step numbers were specified**: move to the next specified step (or batch).
- **If `all` mode**: move to the next pending step (or independent-step batch
  per Step 2b) per the normalized order.
- **If default mode**: ask the user whether to continue to the next step/batch
  or stop.

## Step 4: Wrap up

After finishing (all steps done, user stops, or session limit reached), report:

1. **Completed steps**: list with commit hashes
2. **Blocked / cancelled steps**: list with reasons
3. **Remaining steps**: count still pending, by number and title
4. **Concerns surfaced**: any `CONCERNS` fields the implementers raised that
   the user may want to file as new work (do NOT silently file them -- surface
   them and let the user decide)
5. **Next step**: if work remains, suggest re-running `/plan-implement` (with
   the same plan source) in a fresh session

## Critical constraints

- **You are the orchestrator.** Do NOT write implementation code in the main
  session. All code changes come from plan-implementer subagents.
- **Sequential dispatch.** Never dispatch multiple implementers simultaneously --
  even within an independent-step batch, implementers run one after another.
  "Parallel" / "independent" steps only authorize batched review and committing,
  not concurrent execution.
- **Fresh subagents.** Each dispatch is a new Agent call with a new context.
  Never reuse or continue a prior subagent.
- **Selective staging.** Never `git add -A` or `git add .`.
- **No destructive git.** Never `git checkout .`, `git reset --hard`, or similar.
- **Scope discipline.** If the implementer changed files outside the step's
  declared scope without justification, do NOT commit those changes. Flag it
  and ask the user.
- **No silent bundling.** If the implementer fixed something unrelated, either
  split it out into a follow-up commit (with user approval) or surface it at
  wrap-up -- don't bury it in the current commit.
- **Bounded retries.** Max 2 fix rounds per reviewer rejection (plus one Opus
  escalation), then block.
- **Context hygiene.** After each step, retain only the one-line summary. Do
  NOT carry forward the full implementer/reviewer reports into the next step's
  context.
