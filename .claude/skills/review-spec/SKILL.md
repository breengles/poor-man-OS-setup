---
name: review-spec
description:
  Review every change a spec shipped, in one pass at the end -- an Opus subagent checks the code against the
  requirements and hunts bugs across units. Run after /implement and before /finalize.
argument-hint: "<path to spec dir>"
---

# review-spec

`/implement` commits each unit without an independent check. This skill is that check, for the whole spec at once. You
are the **orchestrator**: you find the change, dispatch one `reviewer`, and report what it found. You do not review
the code yourself, and you do not fix anything.

## Step 1: Resolve the spec

The argument is a path to a spec directory, which must contain `tasks.md`. With no path, list the spec directories you
can find and ask which one. If the path does not exist, stop and say so -- `/finalize` may have removed it already.

Find the project's test command in CLAUDE.md, AGENTS.md, the README, `package.json` scripts, `pyproject.toml`, or a
Makefile; if there is none, say so.

## Step 2: Find the change

Run `git log --format='%h %s' -- <spec>/tasks.md`. The commits that landed units are the ones that also change a file
outside the spec directory; check each with `git show --stat`. Drop the commits that change only spec files.

If no commit qualifies, stop and say so: nothing has landed yet. Warn if `tasks.md` still has `Pending` units, but
continue.

## Step 3: Dispatch the reviewer

Dispatch one `reviewer` with the spec path, the commit list, and the test command. If the caller reports a passing test
run at a sha, and `git diff --quiet <sha> HEAD -- . ':!<spec dir>'` shows no change since, send that result in place of
the test command, so the reviewer does not run the suite again. The agent file owns the role and pins Opus at high
effort -- do not restate the method in the prompt.

- **Claude Code:** `Agent({subagent_type: "reviewer", prompt})`.
- **pi:** `subagent({agent: "reviewer", task})`.

## Step 4: Report

Relay the verdict, the unmet requirements, and every finding with its `path:line`, most severe first. Report the test
result. Do not open the reviewer's transcript, and do not re-check its findings yourself.

Do not fix anything and do not commit. If the user wants a finding fixed, dispatch a fresh `implementer` with the
finding and the requirement it breaks, then commit its change through the `commit` skill. Suggest `/finalize <path>`
once the verdict is `CLEAN` or the user accepts the open findings.
