---
name: implement
description:
  Implement tracked work -- spec tasks from `specs/<feature>/tasks.md` or TODO items from `todos/<area>.md` -- one unit
  at a time via an independent implementer subagent. The main session orchestrates only.
argument-hint: "[<feature> | <area> | path] [numbers | all]"
---

# implement

You are the **orchestrator**. You do NOT write implementation code. For each unit of work you dispatch a fresh
`implementer` subagent; you own reading the artifact, sequencing, the scope check, the commit, and the artifact update.

## Step 1: Resolve the target

Parse `$ARGUMENTS` to find the tracking artifact:

- A feature name or `specs/<feature>` -> spec mode, units are sub-tasks (`1.1`, `2.3`) in `specs/<feature>/tasks.md`.
  Major numbers (`1.`, `2.`) are grouping headers, not units.
- An area name or `todos/<area>.md` -> todo mode, units are items in the Priority Summary table.
- **No argument** -> auto-resolve to the most recently modified `specs/*/` (needs a `requirements.md`), else the most
  recently modified `todos/*.md`. Announce what you resolved on one line so the user can redirect you, and stop if
  neither exists.

Read the artifact in full -- in spec mode also `design.md`, `requirements.md`, and `research.md` if present, in parallel.
Keep this content; it is what you build subagent prompts from. Run `git status --porcelain` for pre-existing changes.

## Step 2: Build the queue

Skip units whose Status is `Done`. Skip `Blocked` ones and report the reason from their `_Blocked:_` line. Check
prerequisites -- `_Depends:_` in spec mode, the "Suggested resolution order" in todo mode -- and warn if the user asked
for a unit whose prerequisites are still open. Note each unit's `_Boundary:_` and `_Requirements:_` (spec) or priority
(todo).

**Check each queued unit is still real before spending a dispatch on it.** A tracking artifact goes stale: if a unit
cites a `TODO`/`FIXME`/`HACK`/`XXX` marker, grep for it -- gone usually means already fixed. If it describes a bug
concretely enough to spot-check, read the code and see whether the symptom survives. Flag anything that looks
already-resolved and ask before implementing it rather than dispatching an implementer at a non-problem.

Present the queue and confirm before proceeding. With explicit numbers, do those in order; with `all`, do every pending
unit in order; with neither, ask which and check in after each one.

**Batching is a commit grouping, never concurrent execution.** Batch only consecutive units that are independent --
`(P)`-marked with compatible boundaries in spec mode, unrelated files in todo mode. Either dispatch one implementer per
unit sequentially and commit the combined diff, or, if the units are entangled (shared files, one refactor, only make
sense together), pass the whole batch to a single implementer. Default batch size is 1.

## Step 3: Execute, one batch at a time

**Dispatch** `Agent({subagent_type: "implementer", prompt: ...})`. The prompt carries the unit's full text from the
artifact, the specific requirements/design excerpts it references (spec mode) or its cited files and acceptance criteria
(todo mode), and the project's test command if known. The implementer's role and report format live in its agent file --
do not restate them. Dispatch strictly sequentially; never run implementers concurrently.

**Handle the reported STATUS.** `COMPLETE` -> continue. `BLOCKED` -> set Status to `Blocked`, append
`_Blocked: {reason}_` to the unit's section, drop it from the batch. `NEEDS_CONTEXT` -> re-dispatch once with the missing
context, then block if still unresolved. Capture any `CONCERNS`; in todo mode file the trackable ones as new items.

**Scope-check the diff yourself.** Run `git diff --stat` and `git status --porcelain` and confirm every changed file was
in the declared scope, no pre-existing changes got swept in, and the diff is not empty or a stub. Unexpected files are a
stop-and-ask, not a commit. This is a scope and sanity check, not a code review.

If the user objects mid-cycle ("that's wrong", "stop and rethink"), re-dispatch a fresh implementer with
`model: "opus"`, the original context, and their specific objection.

**Update the artifact** once every implementer in the batch is `COMPLETE`: flip each Status to `Done`, append a one-line
`_Done: <what shipped>_` note to each detailed section, and prune the completed units from "Suggested resolution order"
(a bullet list -- just delete the lines). `Done` is transient; `/finalize` removes these units. Then run
`npx prettier --write --print-width 120 <artifact>`.

**Commit.** Stage only the files the implementer changed plus the artifact (`git add <files> <artifact>`) -- never
`git add -A` or `git add .`. The artifact update and the code go in the same commit. Message:
`feat(<scope>): <description>` (or `fix:` / `refactor:` / `chore:` as fits); for a batch, one message summarizing all of
it. No issue IDs.

## Step 4: Verify criteria, then finalize

Once the run ends, **re-read the acceptance criteria for every completed unit against the code yourself.** Each
implementer verified against its own reading of its criteria, so a misread criterion is invisible to it -- you are the
first independent reader. Point at the concrete observable behavior satisfying each criterion, or report the gap. Do not
fix anything; report and let the user decide.

Then hand off to `/finalize` to reconcile the docs with what shipped and remove the resolved units. Do not purge them
yourself.

## Report

Completed units with commit hashes; blocked units with reasons; count still pending; any follow-ups filed; the
criteria-verification result. Suggest re-running in a fresh session if units remain, else `/finalize`.

## Constraints

- Orchestrator only -- all code changes come from `implementer` subagents, each a fresh dispatch with a new context.
  Never reuse or continue a prior subagent.
- Selective staging only. No destructive git (`git checkout .`, `git reset --hard`, etc.).
- Never commit code without its artifact update, or an artifact update without the code.
- If an implementer reports the artifact is wrong (an API does not exist, the design is infeasible), block the unit
  rather than silently working around it.
- Context hygiene: after each batch keep only a one-line summary (`1.1: 3 files, abc1234`) and discard the full subagent
  report.
