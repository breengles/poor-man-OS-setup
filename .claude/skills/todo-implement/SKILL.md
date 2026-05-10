---
name: todo-implement
description: Implement items from a TODO file, one at a time, with independent implementer and reviewer subagents per item. The main session acts as orchestrator only.
argument-hint: "<area or path> [item-numbers | all]"
---

# todo-implement

## Role

You are the **orchestrator**. You do NOT write implementation code yourself. For each
item you dispatch a fresh **todo-implementer** subagent that writes the code, then a
fresh **todo-reviewer** subagent that verifies it. You handle TODO-file reading, item
sequencing, committing, and updating `todos/<area>.md`.

This keeps the main session context clean -- implementation details live in subagent
contexts and don't accumulate here.

## Modes

- **No item numbers**: present pending items and ask which to implement (default).
  After each item, ask whether to continue to the next or stop.
- **Item numbers provided** (e.g. `solver 3 5 7`): implement those items in order.
- **Keyword `all`** (e.g. `solver all`): implement all pending items following the
  "Suggested resolution order" in the file.

## Step 1: Resolve target file

Parse `$ARGUMENTS`:

- If a path is given (e.g. `todos/solver.md`), use it.
- If an area name is given (e.g. `solver`), use `todos/<name>.md`.
- If no argument, list files under `todos/` and ask which to target.

If the file does not exist, stop and report.

Read the target file. Also run `git status --porcelain` to note any pre-existing
uncommitted changes.

Retain the TODO content in your context -- you need it to construct subagent prompts.

## Step 2: Build the item queue

Parse the target file and identify open items from the Priority Summary table.

For each item, check:

- **Already done?** Skip items whose Status column is `Done`.
- **Blocked?** Skip items whose Status column is `Blocked` (the reason should be in
  a `_Blocked:_` line in the item's detailed section). Report why.
- **Dependencies**: read the "Suggested resolution order" section. If the user asked
  for a specific item whose prerequisites are still open, warn before proceeding.
- **Priority**: note P0/P1/P2 -- used in subagent prompts and commit messages.

Present the item queue to the user and ask for confirmation before proceeding.

## Step 2b: Plan batches for independent items

A **batch** is one or more items reviewed and committed together. Most batches are
size 1. You may batch only when consecutive queued items are independent of each
other -- typically the "Suggested resolution order" lists them adjacently with no
inter-dependency, and they touch unrelated files or share a clear theme.

Batching is a **logical** grouping. Implementers and reviewers still run **strictly
sequentially** -- never dispatch implementers concurrently. What batching changes
is the _unit of review and commit_: one reviewer verdict and one commit cover the
whole batch.

For a multi-item batch, choose ONE strategy:

- **Separate implementers, one reviewer.** Dispatch implementers sequentially (one
  per item), accumulating their changes in the working tree. Once every implementer
  in the batch has returned `READY_FOR_REVIEW`, dispatch a single reviewer for the
  combined diff.
- **One combined implementer, one reviewer.** If the items are semantically
  entangled (overlap on files, share a refactor, only make sense together), pass
  the whole batch to a single implementer in one prompt, then dispatch one reviewer
  for the combined diff.

Prefer the combined-implementer strategy when splitting would force implementers to
duplicate context or step on each other's edits. Prefer separate implementers when
the items are clearly disjoint.

"Independent" / "parallel" here only authorizes batching of review and commit -- it
does NOT mean multiple implementers run at the same time.

## Step 3: Execute items (one batch at a time)

For each batch (size 1 by default; see Step 2b), execute this cycle. After each
completed batch, retain only a **one-line summary** (e.g. "solver#5: APPROVED,
2 files changed, commit abc1234"; or "solver batch [#5,#7]: APPROVED, commit
abc1234") and discard the full subagent reports from your working memory.

### 3a. Dispatch implementer(s)

Dispatch the **todo-implementer** subagent via the Agent tool:

```
Agent({
  subagent_type: "todo-implementer",
  prompt: <item-specific context below>
})
```

The prompt must include:

- The area name and item number. For a combined-implementer batch, list every
  item number in the batch and make explicit that all of them are in scope for
  this implementer.
- The full detailed section for that item from `todos/<area>.md`
  (description, context, acceptance criteria, cited files/lines). Include the
  detailed section for every item in the batch when using a combined implementer.
- The item's priority (P0/P1/P2)
- Any dependencies on other items from the "Suggested resolution order"
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
  separate-implementers batch, dispatch the next item's implementer; only proceed
  to the reviewer once every implementer in the batch is `READY_FOR_REVIEW`.
- **BLOCKED**: flip the item's Status column in the Priority Summary table from
  `Pending` to `Blocked` and add a `_Blocked: {reason}_` line under the item's
  detailed section in `todos/<area>.md`. If this was one item in a
  separate-implementers batch, drop only that item from the batch and continue
  with the rest; if the batch becomes empty, skip to the next batch.
- **NEEDS_CONTEXT**: re-dispatch once with the requested context; if still
  unresolved, block the item

Also capture any `CONCERNS` field -- if the implementer flagged unrelated issues
they noticed, you will file those as new TODO items in step 3f.

### 3c. Dispatch reviewer

Dispatch the **todo-reviewer** subagent via the Agent tool:

```
Agent({
  subagent_type: "todo-reviewer",
  prompt: <item-specific context below>
})
```

The prompt must include:

- The area name and item number. For a multi-item batch, list every item in the
  batch and make clear that the reviewer must verify the combined diff against
  all of them.
- The full detailed section for the item (the reviewer must see the same criteria).
  For a multi-item batch, include the detailed section for every item.
- The path `todos/<area>.md` so the reviewer can read context if needed
- The implementer's status report (for reference -- the reviewer verifies
  independently by running `git diff`). For a separate-implementers batch,
  concatenate every implementer's status report.

The reviewer's role, checklist, and verdict format are defined in its agent file --
do not repeat them in the prompt.

### 3d. Handle the verdict

Parse the reviewer's `VERDICT` from its `## Review Verdict` block:

- **APPROVED**: proceed to update the TODO file (step 3e), then commit (step 3f).
- **REJECTED (round 1)**: dispatch a **new** todo-implementer subagent (default
  Sonnet) with:
  - The original item context
  - The reviewer's specific FINDINGS and REMEDIATION
  - Instruction to fix the cited issues only
    Then re-dispatch the todo-reviewer.
- **REJECTED (round 2)**: **escalate to Opus** -- dispatch a new todo-implementer
  with `model: "opus"` passed to the Agent tool (this overrides the agent's
  frontmatter default). Include the original item context, all accumulated
  FINDINGS from both prior rounds, and a note that this is an escalated attempt
  after two Sonnet rounds failed. Then re-dispatch the todo-reviewer.
- **REJECTED (round 3)**: flip the item's Status column to `Blocked` and add
  `_Blocked: reviewer rejected after 2 fix rounds (including Opus escalation) --
{summary}_` under the item's detailed section in `todos/<area>.md`. Report
  to user, move to next item.

**Critical ordering:** never mark a TODO item `Done` or write its completion
note into `todos/<area>.md` until the reviewer's verdict is `APPROVED` for
the batch that contains it. While the verdict is still `REJECTED` (across any
retry round), leave the TODO file untouched -- the item is not done yet, and
a premature edit would lose the source of truth driving the retry.

**User disagreement escalation.** If the user interjects mid-cycle with strong
pushback on the implementer's approach ("no, that's wrong", "this won't work",
"stop and rethink"), treat the next retry as an escalated Opus round regardless
of rejection count. Pass the user's specific objection as additional input to
the implementer alongside the original item context.

### 3e. Update the TODO file (only after APPROVED)

Run this step **only after** step 3d returned `APPROVED` for the batch. For
every approved item in the batch:

- Flip its `Status` column in the Priority Summary table from `Pending` to `Done`.
- Append a brief completion note to the item's detailed section, e.g.:

  ```markdown
  ### 5. Broken cache invalidation

  ...

  _Done: cache invalidation now triggered on write, tested with pytest_
  ```

Then once for the batch:

- **Prune the "Suggested resolution order" section** so it lists only the
  still-pending items. Completed items are already tracked via their `Done`
  status in the Priority Summary table; keeping them in the resolution order
  just makes it harder to see what's left. The order is an unnumbered (bullet)
  list, so just delete the bullets for completed items -- there is nothing
  to renumber.
- **Add follow-up items** if any implementer reported CONCERNS worth tracking
  (new bugs noticed, unrelated tech debt). Assign reasonable priority and
  include a one-line description + cited files.

Never delete the TODO file, even if every item is now `Done` -- the
historical record is useful context for future work in the area.

After editing the `.md`, run `npx prettier --write --print-width 120 todos/<area>.md`.

### 3f. Commit (orchestrator does this, not subagents)

Stage only the files the implementer(s) changed, plus the `todos/<area>.md`
edits from step 3e. The TODO update and the implementation changes go in the
**same commit** -- never commit code without the matching TODO update, and
never commit a TODO update without the implementation behind it:

```
git add <file1> <file2> ... todos/<area>.md
```

**Never** use `git add -A` or `git add .`.

For a size-1 batch, commit with: `fix({area}): {brief item description}` for P0
bug fixes, `feat({area}): ...` for new behavior, or `refactor({area}): ...` /
`chore({area}): ...` as appropriate. For a multi-item batch, use a single commit
covering every item with a message that summarizes the batch (e.g.
`refactor({area}): {shared theme} (items #3, #5, #7)`). Do not include issue IDs
in the commit message.

### 3g. Decide next step

- **If item numbers were specified**: move to the next specified item (or batch).
- **If `all` mode**: re-read `todos/<area>.md`, find the next pending item (or
  independent-item batch per Step 2b) per resolution order, continue.
- **If default mode**: ask the user whether to continue to the next item/batch
  or stop.

## Step 4: Wrap up

After finishing (all items done, user stops, or session limit reached), report:

1. **Completed items**: list with commit hashes
2. **Blocked items**: list with reasons
3. **Remaining items**: count still pending
4. **Follow-ups filed**: any new TODO items you added from CONCERNS
5. **Next step**: if items remain, suggest `/todo-implement {area}` in a fresh session

## Critical constraints

- **You are the orchestrator.** Do NOT write implementation code in the main session.
  All code changes come from todo-implementer subagents.
- **Sequential dispatch.** Never dispatch multiple implementers simultaneously --
  even within an independent-item batch, implementers run one after another.
  "Parallel" / "independent" items only authorize batched review and committing,
  not concurrent execution.
- **Fresh subagents.** Each dispatch is a new Agent call with a new context.
  Never reuse or continue a prior subagent.
- **Selective staging.** Never `git add -A` or `git add .`.
- **No destructive git.** Never `git checkout .`, `git reset --hard`, or similar.
- **Scope discipline.** If the implementer changed files outside the item's area
  without justification, do NOT commit those changes. Flag it and ask the user.
- **No silent bundling.** If the implementer fixed something unrelated, either
  split it out into a follow-up commit (with user approval) or file it as a new
  TODO item -- don't bury it in the current commit.
- **Bounded retries.** Max 2 fix rounds per reviewer rejection, then block.
- **Context hygiene.** After each item, retain only the one-line summary. Do NOT
  carry forward the full implementer/reviewer reports into the next item's context.
