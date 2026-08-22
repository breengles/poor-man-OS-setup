---
name: implement
description:
  Implement tracked work at a given path -- spec tasks from a spec directory's `tasks.md`, or items from a TODO file --
  one unit at a time via an independent implementer subagent. The main session orchestrates only.
---

# implement

You are the **orchestrator**. You do NOT write implementation code. For each unit of work you dispatch a fresh
`implementer` subagent; you own reading the artifact, sequencing, the scope check, the commit, and the artifact update.

## Step 1: Resolve the target

The first argument is a **path**, relative or absolute; anything after it is unit numbers or `all`.

- A **directory** -> spec mode. It must contain `tasks.md`; units are its sub-tasks (`1.1`, `2.3`), and major numbers
  (`1.`, `2.`) are grouping headers, not units.
- A **file** -> todo mode. Units are the items in its Priority Summary table.
- **No path** -> list the spec directories and TODO files you can find and ask which one. Do not auto-pick.

There is no name-to-path guessing: if the path does not exist, stop and say so rather than searching for something
similar. Resolve every other path in this skill against the artifact's own location, not the repo root -- a spec at
`packages/solver/specs/cache/` belongs to `packages/solver`.

Read the artifact in full -- in spec mode also `design.md`, `requirements.md`, and `research.md` if present, in
parallel. Keep it; it is what you build subagent prompts from. Run `git status --porcelain` for pre-existing changes.

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

**Dispatch** `spawn_agent(agent_type="implementer", fork_turns="none", task_name=<unit id>, message=...)`, then one
`wait_agent(timeout_ms=3600000)`. Never poll -- no `list_agents`, no status pings, no repeated short waits; if the wait
returns a timeout, tell the user and wait again. The message carries the unit's full text from the artifact, the specific
requirements/design excerpts it references (spec mode) or its cited files and acceptance criteria (todo mode), and the
project's test command if known. The implementer's role and report format live in its agent file -- do not restate them.

If that dispatch is rejected **before an agent starts** because the custom `implementer` role is unavailable, do not
retry the same unavailable role and do not ask the main session to implement. Make one fallback dispatch with
`agent_type="worker"`, `model="gpt-5.6-terra"`, `reasoning_effort="medium"`, and `fork_turns="none"`. Prepend this to
the normal unit message:

> You are the fallback implementer for this unit. Read the active `implementer` custom-agent TOML -- the project copy
> at `.codex/agents/implementer.toml` if present, otherwise `~/.codex/agents/implementer.toml` -- and follow its
> `developer_instructions` as task constraints. Preserve its ownership boundary, validation duties, prohibitions on
> commits and tracking-artifact edits, and exact status-report format.

This fallback is equivalent to a fresh implementer for the workflow; label it as a fallback in the final report. If the
fallback cannot start or cannot read the implementer profile, stop the run as an infrastructure blocker without marking
the unit `Blocked` or changing the artifact. Dispatch strictly sequentially; never run implementers concurrently.

**Handle the reported STATUS.** `COMPLETE` -> continue. `BLOCKED` -> set Status to `Blocked`, append
`_Blocked: {reason}_` to the unit's section, drop it from the batch. `NEEDS_CONTEXT` -> re-dispatch once with the
missing context, then block if unresolved. Capture any `CONCERNS`; in todo mode file the trackable ones as new items.

**Scope-check the diff yourself.** Run `git diff --stat` and `git status --porcelain` and confirm every changed file was
in the declared scope, no pre-existing changes got swept in, and the diff is not empty or a stub. Unexpected files are a
stop-and-ask, not a commit. This is a scope and sanity check, not a code review. If the user objects mid-cycle ("that's
wrong", "stop and rethink"), re-dispatch a fresh implementer with `model="gpt-5.6-sol"`,
`reasoning_effort="high"`, the original context, and the objection.

**Update the artifact** once every implementer in the batch is `COMPLETE`: flip each Status to `Done`, append a one-line
`_Done: <what shipped>_` note to each detailed section, and prune the completed units from "Suggested resolution order"
(a bullet list -- just delete the lines). `Done` is transient; `$finalize` removes these units. Then run
`npx prettier --write --print-width 120 <artifact>`.

**Commit.** Stage only the files the implementer changed plus the artifact (`git add <files> <artifact>`) -- never
`git add -A` or `git add .`. The artifact update and the code go in the same commit. Write the message imperative and
lowercase, ~50 chars, no type prefix; for a batch, one message covering all of it. No issue IDs.

## Step 4: Verify criteria, then finalize

Once the run ends, **re-read the acceptance criteria for every completed unit against the code yourself.** Each
implementer verified against its own reading of its criteria, so a misread criterion is invisible to it -- you are the
first independent reader. Point at the concrete observable behavior satisfying each criterion, or report the gap. Do not
fix anything; report and let the user decide.

Then hand off to `$finalize <same path>` to reconcile the docs with what shipped and remove the resolved units. Do not
purge them yourself.

## Report

Completed units with commit hashes; blocked units with reasons; count still pending; any follow-ups filed; the
criteria-verification result. Suggest re-running in a fresh session if units remain, else `$finalize <path>`.

## Constraints

- Orchestrator only -- all code changes come from a fresh `implementer` subagent or the documented fresh `worker`
  fallback with the implementer profile loaded. Never reuse or continue a prior subagent.
- Selective staging only. No destructive git (`git checkout .`, `git reset --hard`, etc.).
- Never commit code without its artifact update, or an artifact update without the code.
- If an implementer reports the artifact is wrong (an API does not exist, the design is infeasible), block the unit
  rather than silently working around it.
- Context hygiene: after each batch keep only a one-line summary (`1.1: 3 files, abc1234`) and discard the full subagent
  report.
