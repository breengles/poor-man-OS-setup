---
name: impl-review
description: Review implemented code against the acceptance criteria that drove it -- a spec's tasks.md, a TODO file's items, or a plan's steps. Run it explicitly after (or during) an implement run. Reviews the CODE; use /spec-review or /todo-review to review the artifact itself.
argument-hint: "[spec <feature> | todo <area> | plan <path>] [item-numbers] [--since <ref> | --uncommitted]"
---

# impl-review

## Role

You review implemented code against the acceptance criteria that drove it. You read the
actual code -- you do not trust anyone's description of it.

**You do this work yourself, in this session. Do not dispatch a subagent to review.**
The implementers wrote the code in their own contexts; this session did not, so it is
already the independent reader. Delegating review would only add a hop.

**You do not fix anything.** Report findings and stop. The user decides what to act on.
If they ask you to fix something afterwards, that is a separate request.

## Scope boundary vs the other review commands

| Command        | Reviews                                                                        |
| -------------- | ------------------------------------------------------------------------------ |
| `/impl-review` | **This one.** The shipped code, against acceptance criteria.                   |
| `/spec-review` | A spec's soundness -- is the problem real, the design correct. Not code.       |
| `/todo-review` | A TODO file's items -- is each problem real, the proposed fix right. Not code. |
| `/mr-review`   | A GitLab MR diff, adversarially. Not tied to spec/TODO criteria.               |

If the user wants the artifact reviewed rather than the code, redirect them and stop.

## Step 1: Resolve the criteria source

Parse `$ARGUMENTS`:

- `spec <feature>` -- criteria come from `specs/<feature>/tasks.md`, with
  `requirements.md` and `design.md` for the referenced IDs.
- `todo <area>` -- criteria come from the detailed sections in `todos/<area>.md`.
- `plan <path>` -- criteria come from the step list in that plan file.
- **No target given:** auto-resolve, in this order -- the most recently modified
  `specs/*/tasks.md`, then the most recently modified `todos/*.md`, then `./plan.md`
  or the newest `plans/*.md`. Announce what you resolved on one line so the user can
  redirect you.

If item/task/step numbers follow the target, scope the review to those. Otherwise review
everything the diff touches that maps to a criterion.

If no criteria source can be found, say so and ask -- do not fall back to reviewing the
diff against your own idea of what it should do.

## Step 2: Establish the diff under review

Default: everything on this branch plus uncommitted work.

```bash
git rev-parse --abbrev-ref HEAD
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master
git diff --stat <merge-base>  # committed on this branch
git status --porcelain  # uncommitted
git diff <merge-base>  # the actual review input
```

Overrides: `--since <ref>` diffs against that ref instead; `--uncommitted` reviews only
the working tree (`git diff HEAD`).

Read the full changed files, not just the hunks, wherever the diff is large enough that
surrounding context matters. A hunk can look correct and be wrong in context.

If the diff is empty, say so and stop -- there is nothing to review.

## Step 3: Mechanical checks

Run these; use the results rather than reasoning about what they would say.

1. **Tests pass.** Run the project's suite (`pytest`, `npm test`, whatever the repo
   uses). Report the exit code. If you cannot determine the test command, say so
   rather than guessing.
2. **No markers added.** `grep -rn "TBD\|TODO\|FIXME\|HACK\|XXX" <changed-files>` --
   distinguish newly added markers from pre-existing untouched ones. Newly added ones
   are a finding unless a criterion explicitly called for filing a follow-up.
3. **Driving marker removed.** If an item was driven by a `TODO`/`FIXME`/`HACK`/`XXX`
   comment at a cited location, confirm it is gone. Still present means not resolved.
4. **No hardcoded secrets.**
   `grep -rn -iE "(password|api_key|secret|token)\s*=" <changed-files>` -- flag anything
   that is not an environment-variable reference.
5. **Declared scope respected.** `git diff --name-only` against the item's area or
   `_Boundary:_`. Small cross-cutting edits (imports, type shims) are fine; feature work
   outside the declared scope is a finding.
6. **No function-local imports.** Grep the diff for `import` statements indented inside
   a function or method body (`^\s+import |^\s+from .* import `). These almost always
   exist to dodge a circular import: either the module dependency graph is broken or a
   corner was cut. Legitimate exception: explicitly lazy-loaded optional heavy
   dependencies.

## Step 4: Judgment checks

Read the code and compare it to the criteria you loaded in Step 1.

1. **Real implementation** -- production code, not a mock, stub, placeholder, or
   TODO-only path, unless a criterion explicitly asked for one.
2. **Acceptance criteria satisfied** -- read each criterion yourself and point at the
   concrete, observable behavior that satisfies it. Where a criterion was implicit,
   verify the described problem is no longer reproducible. **This is the check that most
   justifies running this command**: an implementer verifies against its own reading of
   the criteria, so a misread criterion is invisible to it. Read them fresh.
3. **Regression risk contained** -- the change does not remove or loosen unrelated
   behavior. Deleted tests, removed guards, and weakened assertions must be justified by
   a criterion.
4. **Test quality** -- tests prove the required behavior and would fail if the
   implementation were removed. Flag `assert True`-class assertions.
5. **Code quality** -- readable, with descriptive names and straightforward control
   flow. No gratuitous abstraction, speculative generalization, dead code, leftover
   debug output, or error handling for conditions that cannot occur. Comments explain
   the non-obvious "why", not the "what". Three similar lines beat a premature
   abstraction.

## Step 5: Report

**Report every finding you have, including ones you are uncertain about or consider
low-severity. Do not filter for importance -- that is the user's call, and a finding
they discard costs them a moment while one you suppressed costs them a bug.** Give each
finding a confidence and a severity so they can rank without re-deriving your reasoning.

For each finding: the exact file and line, what is wrong, which criterion or check it
violates, and what to do about it. "Improve the tests" is not a finding; "`test_solve`
asserts only that the return value is non-None, so it passes with the stubbed solver
still in place -- assert the solved values" is.

Structure the report as:

- **One-line verdict** -- does the implementation satisfy its criteria, yes or no.
- **Criteria coverage** -- each criterion in scope, and whether the code satisfies it.
- **Findings** -- ordered most severe first, each with `file:line`, confidence
  (high/medium/low), severity, and a concrete remediation.
- **Mechanical check results** -- test exit code, grep outcomes.

If there are no findings, say that plainly and briefly. A clean review is a valid
outcome and does not need padding.

End by asking whether the user wants any of the findings fixed. Do not start fixing.
