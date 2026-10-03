---
name: implement
description:
  Implement tracked work at a given path -- spec tasks from a spec directory's `tasks.md`, or items from a TODO file --
  one unit at a time. Each unit is implemented, verified, and committed; the main session orchestrates only.
---

# implement

You are the **orchestrator**. You do NOT write implementation code. You resolve the target, build and confirm the
queue, then run the per-unit loop. For each unit, that loop runs an `implementer`, an independent `verifier`, one
repair round if the verifier fails the unit, and a commit. You own every step that needs the user: the confirmation,
the stops, and the report.

## Step 1: Resolve the target

The first argument is a **path**, relative or absolute; anything after it is unit numbers or `all`.

- A **directory** -> spec mode. It must contain `tasks.md`, which is the artifact. Units are its sub-tasks (`1.1`,
  `2.3`); major numbers (`1.`, `2.`) are grouping headers, not units.
- A **file** -> todo mode. The file is the artifact. Units are the items in its Priority Summary table.
- **No path** -> list the spec directories and TODO files you can find and ask which one. Do not auto-pick.

There is no name-to-path guessing: if the path does not exist, stop and say so rather than searching for something
similar. Resolve every other path in this skill against the artifact's own location, not the repo root -- a spec at
`packages/solver/specs/cache/` belongs to `packages/solver`.

Read the artifact in full -- in spec mode also `design.md`, `requirements.md`, and `research.md` if present, in
parallel. Find the project's test command in AGENTS.md, CLAUDE.md, the README, `package.json` scripts,
`pyproject.toml`, or a Makefile; if there is none, say so. Save `git status --porcelain` as the baseline of
pre-existing changes.

## Step 2: Build the queue

Skip units whose Status is `Done`. Skip `Blocked` ones and report the reason from their `_Blocked:_` line. Check
prerequisites -- `_Depends:_` in spec mode, the "Suggested resolution order" in todo mode -- and warn if the user asked
for a unit whose prerequisites are still open.

**Check each queued unit is still real before spending a dispatch on it.** A unit that cites a
`TODO`/`FIXME`/`HACK`/`XXX` marker, or describes a bug concretely enough to spot-check, may already be fixed. Send one
subagent per such unit, all at once and at most 6 (`spawn_agent(fork_turns="none")` with no `agent_type`, told not to
edit). Each greps for the marker or reads the code and reports whether the problem survives. Flag the ones that look
resolved and ask before queueing them.

Each queue entry is one unit. Merge units into one entry only when they are entangled -- shared files, one refactor,
or they only make sense together -- so one implementer takes them all and one commit lands them.

Present the queue and the test command, and confirm before proceeding. With explicit numbers, queue those in order;
with `all`, every pending unit in order; with neither, ask which.

## Step 3: Run the loop

Codex has no workflow tool, so run the loop yourself, one entry at a time. Dispatch each agent with
`spawn_agent(agent_type=<role>, fork_turns="none", task_name=<unit id>, message=...)`, then one
`wait_agent(timeout_ms=3600000)`. Never poll -- no `list_agents`, no status pings, no repeated short waits; if the wait
returns a timeout, tell the user and wait again. Each message carries the entry's full unit text plus the requirement
and design excerpts it references (spec mode) or its cited files and acceptance criteria (todo mode), and the test
command. The agent files own the roles -- do not restate them. Agents read the artifact's `## Notes` section
themselves; collect the `NOTES` lines from every report for the entry.

1. **`implementer`.** `COMPLETE` -> step 2. `BLOCKED` with no changed files -> record it, skip the entries that depend
   on it, and go to the next entry. `NEEDS_CONTEXT`, or `BLOCKED` with changes in the tree -> stop.
2. **`verifier`**, also given the files the implementer reports. `PASS: true` -> step 4.
3. **One repair round:** a fresh `implementer` with `model="gpt-5.6-sol"`, `reasoning_effort="high"`, and the
   verifier's gaps. Then a fresh `verifier`. Still failing -> stop.
4. **Land it yourself.** Check that `git status --porcelain` shows only the implementer's files and the artifact beyond
   the baseline; anything else -> stop. Set each unit's Status to `Done`, append a one-line `_Done: <what shipped>_`
   note to its section, and delete its lines from the suggested resolution order. Append the entry's notes, minus
   repeats, to the `## Notes` section at the end of the artifact as `- [<unit id> <kind>] <fact>`; past 40 entries,
   merge the ones that say the same thing. Run `npx prettier --write --print-width 120 <artifact>`. Stage only those
   files with `git add` and commit: imperative, lowercase, ~50 chars, no type prefix, no issue IDs.

Keep one line per entry (`1.1: 3 files, abc1234`) and drop the full agent report. Do not end your turn between entries.

If a dispatch is rejected **before an agent starts** because a custom role is unavailable, make one fallback dispatch
with `agent_type="worker"`, `fork_turns="none"`, and the role's model and effort. Prepend: "You are the fallback
<role> for this unit. Read `.codex/agents/<role>.toml` if present, otherwise `~/.codex/agents/<role>.toml`, and follow
its `developer_instructions` exactly." Label it as a fallback in the report. If the fallback cannot start, stop the run
as an infrastructure blocker without changing the artifact.

## Step 4: Handle the result

- **Blocked units:** set each Status to `Blocked`, append `_Blocked: {reason}_` to its section, and append its notes to
  `## Notes`. Leave the edit uncommitted; the next landed commit carries it.
- **Concerns:** in todo mode, file the trackable ones as new items. Otherwise report them.
- **A stop:** report the unit and the reason, then ask the user. Append the unit's notes that still hold. Write a
  missing-context answer into the unit's section, or commit it to `design.md` or `requirements.md` first, because
  step 4 stops on any other changed file. Then restart that entry. Never discard changes yourself.

If the user objects to a unit that already landed, dispatch a fresh `implementer` with `model="gpt-5.6-sol"`,
`reasoning_effort="high"`, the unit's text, and the objection, then continue from there.

## Report

Completed units with commit hashes; blocked units with reasons; the stop, if any; count still pending; follow-ups
filed; any fallback dispatches. Suggest `$finalize <path>` once nothing is pending. Do not purge units yourself.

## Constraints

- Orchestrator only -- all code changes come from fresh `implementer` subagents or the documented `worker` fallback.
  Never reuse or continue a prior subagent.
- Selective staging only. No destructive git (`git checkout .`, `git reset --hard`, etc.).
- Never commit code without its artifact update.
- If an implementer reports the artifact is wrong (an API does not exist, the design is infeasible), block the unit
  rather than silently working around it.
