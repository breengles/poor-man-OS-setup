---
name: resolve-conflicts
description:
  Resolve in-progress merge, rebase, cherry-pick, or revert conflicts. Inspect repo state, understand each side's intent
  from commit history, edit files to a correct combined result, verify with build/tests, and finalize the operation.
argument-hint: "[<file path or directory to scope to> | leave empty to resolve all conflicts]"
---

Resolve conflicts left behind by an in-progress merge, rebase, cherry-pick, or revert. Read both sides of each conflict,
understand the intent behind them from commit messages and surrounding code, write the correct combined result, and
finalize the operation only after the working tree builds and tests pass (where applicable).

Be careful: the meaning of "ours" and "theirs" depends on the operation in progress. Get this wrong and you will silently
discard the wrong side. Confirm operation type before resolving anything.

## Scope

- If `$ARGUMENTS` is empty: resolve every conflicted path reported by `git status`.
- If `$ARGUMENTS` is a file or directory path: resolve only conflicts inside that path. Leave other conflicts for a
  later pass and do not finalize the operation until everything is resolved.
- If there is no operation in progress (no `MERGE_HEAD`, `REBASE_HEAD`, `CHERRY_PICK_HEAD`, or `REVERT_HEAD`), stop and
  ask the user what they want to do (start a merge/rebase, abort, etc.) rather than guessing.

## Workflow

### Step 1 -- Identify the operation in progress

Run these in parallel and inspect the output before doing anything else:

```
git status
git rev-parse --git-dir
ls "$(git rev-parse --git-dir)" | grep -E '^(MERGE_HEAD|REBASE_HEAD|CHERRY_PICK_HEAD|REVERT_HEAD|rebase-merge|rebase-apply)$' || true
```

Determine which one of these is happening:

- **Merge** -- `MERGE_HEAD` exists. `ours` = the branch you had checked out before `git merge`. `theirs` = the branch
  being merged in.
- **Rebase** -- `rebase-merge/` or `rebase-apply/` directory exists, often `REBASE_HEAD` too. **Ours and theirs flip**:
  `ours` = the upstream you are rebasing onto. `theirs` = the commit from your branch currently being replayed. Do not
  reason about rebase conflicts using merge-style "ours/theirs" intuition.
- **Cherry-pick** -- `CHERRY_PICK_HEAD` exists. `ours` = current `HEAD`. `theirs` = the commit being picked.
- **Revert** -- `REVERT_HEAD` exists. `ours` = current `HEAD`. `theirs` = the inverse of the commit being reverted.

Also note:

- The **target SHA** being applied (`cat .git/MERGE_HEAD` / `.git/CHERRY_PICK_HEAD` / etc., or
  `cat .git/rebase-merge/onto` and `cat .git/rebase-merge/stopped-sha` for rebase).
- The **current branch** (`git branch --show-current`) -- detached during rebase, so check `.git/rebase-merge/head-name`
  for the original branch.

State the operation, the two SHAs/refs involved, and which side is "ours" vs "theirs" in your first message before
making any edits. This forces you to get the framing right.

### Step 2 -- List conflicted paths

```
git diff --name-only --diff-filter=U
git status --porcelain=v1 | grep -E '^(UU|AA|DD|AU|UA|DU|UD) '
```

The two-letter codes from `git status --porcelain` tell you the conflict type:

- `UU` -- both modified (the common case).
- `AA` -- both added (different content for the same new path).
- `DD` -- both deleted (almost always trivially "remove the file").
- `AU` / `UA` -- added by one side, modified by the other.
- `DU` / `UD` -- deleted by one side, modified by the other (these need a real decision -- ask if intent is unclear).

For renames, also run `git status` (without `--porcelain`) -- it shows rename/rename and rename/delete cases in plain
English.

### Step 3 -- Understand each side's intent (do this before editing anything)

Generic "take both" or "take theirs" heuristics produce subtly wrong code. For each conflicted file:

1. Read the **current file** in full (not just the conflict hunks). The diff hides surrounding invariants and call sites.
2. Inspect the commits that touched this file on each side:
   ```
   git log --merge --oneline -- <path>
   git log --merge -p -- <path>
   ```
   For rebase, `--merge` is unreliable -- use `git log <onto>..HEAD -- <path>` and
   `git log HEAD..<stopped-sha> -- <path>` (or read `.git/rebase-merge/{onto,stopped-sha}` directly) instead.
3. If you need the three-way view (base / ours / theirs) inline in the file, switch the conflict style:
   ```
   git checkout --conflict=diff3 -- <path>
   ```
   This rewrites the conflict markers to include the merge base, which often makes the right resolution obvious.
4. Locate **callers** of any function whose signature is changing on either side (`rg -n <name>`). A change that looks
   safe in isolation can break callers introduced on the other side.
5. If commit messages reference issues, MRs, or specs, read them. Intent matters more than syntax.

### Step 4 -- Resolve each file

Pick the strategy per file, not per repo:

- **Both sides legitimately needed** -- edit the file by hand to combine them. Remove all conflict markers
  (`<<<<<<<`, `|||||||`, `=======`, `>>>>>>>`). Keep the result self-consistent (imports, types, tests, formatter).
- **One side is wholesale correct** -- use `git checkout --ours <path>` or `git checkout --theirs <path>`. Remember the
  flip during rebase. State which side you took and why before running it.
- **Modify/delete** -- decide whether the file should exist. If yes, take the modified version with
  `git checkout --ours/--theirs <path>` and re-add it. If no, `git rm <path>`.
- **Rename/rename** -- pick the intended name, `git mv` if needed, and merge content into that one file.
- **Binary files (images, lockfiles)** -- usually take one side wholesale. For lockfiles (`package-lock.json`, `uv.lock`,
  `Cargo.lock`, `poetry.lock`, `yarn.lock`, `pnpm-lock.yaml`), do not hand-merge -- regenerate after resolving the
  manifest (`uv lock`, `npm install`, `cargo update -p <pkg>`, etc.).
- **Generated files** (compiled output, snapshots, `dist/`) -- regenerate from source rather than merging text.

After each file, sanity-check by reading it again top to bottom. Confirm there are no leftover markers:

```
git grep -nE '^(<{7}|={7}|>{7}|\|{7}) ' || true
```

Stage with `git add <path>` (or `git rm <path>` if deleted). Do not stage anything else.

### Step 5 -- Verify before finalizing

A resolution that compiles is not the same as a correct resolution, but a resolution that does not compile is
definitely wrong. Run whatever the project supports, in this order:

- **Build / compile:** `cargo build`, `npm run build`, `go build ./...`, `tsc --noEmit`, `uv run python -c "import <pkg>"`.
- **Type check:** `mypy`, `pyright` (`uv run pyright` for Python projects), `tsc --noEmit`.
- **Lint / format:** `ruff check`, `eslint`, `shellcheck`, `stylua --check`, `cargo clippy`. Run the project's formatter
  on touched files.
- **Tests:** the project's test suite, or at minimum the tests that cover the conflicted modules. Report failures
  verbatim.
- **Pre-commit hooks:** if the project has `.pre-commit-config.yaml`, run `pre-commit run` on the staged files.

If a check fails, treat the failure as a flag that the resolution is wrong, not as something to suppress. Re-read the
diff, fix the real problem, re-stage, and re-run. Do not skip hooks (`--no-verify`) to push the operation through.

If the project has none of the above, say so explicitly.

### Step 6 -- Finalize the operation

Use the right command for the operation in progress (Step 1):

- **Merge:** `git commit --no-edit` (the merge commit message is preset; only edit it if the user asked you to).
- **Rebase:** `git rebase --continue`. If the replayed commit became empty after resolution, run
  `git rebase --skip` instead -- but confirm with the user first, because skipping silently drops a commit.
- **Cherry-pick:** `git cherry-pick --continue` (or `--skip` for empty, with confirmation).
- **Revert:** `git revert --continue`.

After finalizing, run `git status` and `git log --oneline -n 5` so the user sees the new state. If a rebase has more
commits to replay, more conflicts may appear -- if so, loop back to Step 2.

## Aborting

`git merge --abort` / `git rebase --abort` / `git cherry-pick --abort` / `git revert --abort` discard all conflict
resolution work in progress. Treat them as destructive. Only run on **explicit user request**, and confirm in plain
language ("This will throw away the resolution work so far -- proceed?") even after the request.

`git reset --hard`, `git checkout .`, `git restore .`, `git clean -f` are forbidden as a way to "clean up" -- never use
them to escape a stuck conflict. Use the operation's own `--abort` if a reset is genuinely needed.

## Rules

1. **Identify the operation first, name "ours" vs "theirs" out loud, then resolve.** Misnamed sides cause silent data
   loss, especially during rebase.
2. **Read the file, the commits, and the call sites before editing.** Conflict markers without context are not enough.
3. **Never blindly take one side across the whole repo** (`git checkout --ours .`, `-X ours`, `-X theirs`). Decide per
   file.
4. **Regenerate lockfiles and generated artifacts** -- do not hand-merge them.
5. **Verify with build / typecheck / lint / tests** before finalizing. Report what you ran and the outcome.
6. **Do not skip pre-commit or commit hooks** to push the operation through. A failing hook is signal, not friction.
7. **Confirm before `--abort` or any destructive recovery.** The forbidden commands listed in `~/.claude/CLAUDE.md`
   (`git reset --hard`, `git checkout .`, `git restore .`, `git clean -f`, `git push --force*`, `rm -rf`) require
   explicit user approval -- conflict resolution does not justify them.
8. **Stage only resolved files** (`git add <path>` per file). Do not run `git add .` / `-A` -- it sweeps in unrelated
   working-tree changes.
9. **Do not amend or rewrite commit messages** beyond what the operation already prefilled, unless the user asked.
10. **No issue IDs in any commit message you author** (e.g. `#5`, `#123`) -- GitLab interprets `#N` as an issue
    reference and may auto-close issues unintentionally.
11. **Report what changed.** End with a short summary: which files were resolved, which side(s) won where, what was
    verified, and what's left if the operation has more commits to replay.
