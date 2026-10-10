---
name: implement
description:
  Implement the tasks of a spec directory's `tasks.md`, one unit at a time. A workflow script implements and commits
  each unit; the main session orchestrates only.
argument-hint: "<path to spec dir> [numbers | all]"
---

# implement

You are the **orchestrator**. You do NOT write implementation code. You resolve the target, build the
queue, then hand the per-unit loop to the saved workflow `implement-units`. Stow deploys it from the dotfiles repo to
`~/.claude/workflows/implement-units.js`. For each unit, that script runs an `implementer`, then a `test-runner`
when there is a test command, with one repair round on a failure, then a land step that checks the scope and commits.
You own every step that needs the user: the unit choice, the stops, and the report.

## Step 1: Resolve the target

The first argument is a **path**, relative or absolute; anything after it is unit numbers or `all`.

- A **spec directory** must contain `tasks.md`, which is the artifact. Units are its sub-tasks (`1.1`, `2.3`); major
  numbers (`1.`, `2.`) are grouping headers, not units.
- **No path** -> list the spec directories you can find and ask which one. Do not auto-pick.

There is no name-to-path guessing: if the path does not exist, stop and say so rather than searching for something
similar. Resolve every other path in this skill against the artifact's own location, not the repo root -- a spec at
`packages/solver/specs/cache/` belongs to `packages/solver`.

Read the artifact in full, and `design.md` and `requirements.md` in parallel. Find the project's test command in
CLAUDE.md, AGENTS.md, the README, `package.json` scripts, `pyproject.toml`, or a Makefile; if there is none, say so.
Save `git status --porcelain` as the baseline of pre-existing changes.

## Step 2: Build the queue

Skip units whose Status is `Done`. Skip `Blocked` ones and report the reason from their `_Blocked:_` line. Check
`_Depends:_` prerequisites, and warn if the user asked for a unit whose prerequisites are still open.

**Check each queued unit is still real before spending a dispatch on it.** A unit that cites a
`TODO`/`FIXME`/`HACK`/`XXX` marker, or describes a bug concretely enough to spot-check, may already be fixed. Send one
read-only subagent per such unit, all at once and at most 6 (Claude Code: `Explore`; pi: `scout` in `runs.all`). Each
greps for the marker or reads the code and reports whether the problem survives. For each one that looks resolved,
ask whether to skip it, queue it anyway, or mark it Done. To mark it Done, set its Status to `Done`, append
`_Done: already fixed before this run - <evidence>_`, and delete its lines from the resolution order. The next landed
commit carries that edit; if nothing lands, commit the artifact alone.

Each queue entry is one unit. Merge units into one entry only when they are entangled -- shared files, one refactor,
or they only make sense together -- so one implementer takes them all and one commit lands them.

With explicit numbers, queue those in order; with `all`, every pending unit in order. In both cases, present the queue
and the test command, then proceed without asking. With neither, propose the pending units in order and ask which to
run.

## Step 3: Run the workflow

Build `args`: `artifact` (path), `testCmd` (string or null), `baseline` (the saved porcelain output), and `queue`, a
list of `{ids, text, depends}`. `text` carries the unit's full text plus the requirement and design excerpts it
references. `depends` lists queued unit ids it needs. The agent file owns the implementer role -- do not restate it
in `text`, and never tell the implementer there to edit the artifact or commit; only the land step does that. This
contract is the whole interface, so do not read the script to learn it. Agents read the artifact's `## Notes` section
themselves.

- **Claude Code:** `Workflow({name: "implement-units", args})`. If the tool cannot find that name, read
  `~/.claude/workflows/implement-units.js` and pass its full text as `script` with the same `args`.
- **pi:** read `~/.claude/workflows/implement-units.js`, take everything below its `// pi:` marker line, and prepend
  `const args = <args JSON>;`. Pass that as `subagent({workflowScript, async: false, mission: false, timeoutMs})`, with
  `timeoutMs` at 45 minutes per queue entry.
- **Neither tool exists:** run the script's steps yourself, one unit at a time, dispatching the `implementer`,
  `test-runner`, and land agents in order. Treat `implement-units.js` as the spec. Do not end your turn between units.

## Step 4: Handle the result

The workflow returns `{done, blocked, concerns, stopped, tests}`. Read only this value; do not open subagent transcripts
unless you must debug a stop.

- **blocked:** set each unit's Status to `Blocked`, append `_Blocked: {reason}_` to its section, and append its `notes`
  to the `## Notes` section at the end of the artifact. Leave the edit uncommitted; the next landed commit carries it.
- **concerns:** report them.
- **stopped:** report the unit and the reason, then ask the user. The script stops on missing context, a blocked unit
  with changes in the tree, tests that still fail after the repair round, unexpected changed files, and a failed commit.
  Append its `notes` that still hold. Write a missing-context answer into the unit's section, or commit it to
  `design.md` or `requirements.md` first, because the land step stops on other changed paths. Add it as `extraContext`
  and relaunch. Never discard changes yourself.

To continue, relaunch with the entries not yet in `done`. If the user objects to a unit that already landed, dispatch
a fresh `implementer` with the unit's `text` and the objection, then relaunch from there.

## Report

Completed units with commit hashes; blocked units with reasons; the stop, if any; count still pending; follow-ups filed.
Do not purge units yourself. When the run did not stop and no unit is `Pending`, invoke the `review-spec` skill on the
spec without asking, pass it `tests` (the last passing test run), and follow it to its own report.

## Constraints

- Orchestrator only -- all code changes come from `implementer` subagents, each a fresh dispatch with a new context.
- Selective staging only. No destructive git (`git checkout .`, `git reset --hard`, etc.).
- Never commit code without its artifact update.
- If an implementer reports the artifact is wrong (an API does not exist, the design is infeasible), block the unit
  rather than silently working around it.
