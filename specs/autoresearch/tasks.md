# Tasks: Autoresearch

## Task Summary

| Task                                                     | Status  |
| -------------------------------------------------------- | ------- |
| [#1.1](#11-arpy-skeleton-config-ledger-and-lock)         | Done    |
| [#1.2](#12-arpy-init-stop-and-status)                    | Done    |
| [#2.1](#21-arpy-slurm-layer)                             | Done    |
| [#2.2](#22-arpy-mlflow-reader)                           | Pending |
| [#2.3](#23-arpy-collect-job-transitions-and-submissions) | Pending |
| [#2.4](#24-arpy-collect-verdicts-and-stop-conditions)    | Pending |
| [#2.5](#25-arpy-new-smoke-and-note)                      | Pending |
| [#3.1](#31-autoresearch-propose-workflow)                | Pending |
| [#3.2](#32-autoresearch-skill)                           | Pending |
| [#4.1](#41-documentation-and-stow)                       | Pending |
| [#4.2](#42-end-to-end-check-with-stubbed-slurm)          | Pending |

## Suggested Resolution Order

- 2.2 -- MLflow reader, independent of SLURM
- 2.3 -- needs both readers
- 2.4 -- builds on the transitions in 2.3
- 2.5 -- the build-side commands the workflow calls
- 3.1 -- workflow, needs the `ar.py` commands it calls
- 3.2 -- skill, ties `ar.py` and the workflow together
- 4.1 -- docs once the interfaces are final
- 4.2 -- end-to-end check of the deterministic path

## Detailed Tasks

### 1.1 ar.py skeleton, config, ledger, and lock

Create `.claude/skills/autoresearch/scripts/ar.py` as a `uv run --script` file.

- PEP 723 header with `requires-python = ">=3.11"` and no dependencies.
- `argparse` with subcommands `init`, `collect`, `new`, `smoke`, `note`, `stop`, `status`; global `--json`.
- Campaign path resolution from the git root: `.autoresearch/<campaign>/`.
- `campaign.toml` load and validation through `tomllib`. Report every missing or invalid key at once.
- `Ledger`, `Champion`, `Experiment`, `Job` dataclasses with load and atomic save (temp file, then `Path.replace`).
- `fcntl.flock` on `lock` with a 60-second wait. Every command that writes the ledger holds it.

- [ ] `uv run --script ar.py --help` lists all seven commands.
- [ ] An invalid `campaign.toml` reports every bad key in one message.
- [ ] A second writer waits for the lock and fails after 60 seconds.
- [ ] The file imports only standard library modules.

_Done: ar.py skeleton with config validation, ledger dataclasses, and flock lock_

_Requirements: 6.1, 6.7_

### 1.2 ar.py init, stop, and status

- `init <campaign> --config <toml> [--baseline <run-id>]`: refuse an existing campaign directory or champion branch;
  copy the config; add `.autoresearch/` to `.git/info/exclude` once; create `autoresearch/<campaign>/champion` at
  HEAD; write the first ledger. With `--baseline`, read the run's target metric through the MLflow reader (2.2) and
  store it as the champion metric. Until 2.2 lands, `--baseline` may fail with a clear message.
- `stop <campaign>`: set the state to `draining`.
- `status <campaign>`: state, champion with metric, and one line per experiment (ID, status, verdict, metric,
  hypothesis).

- [ ] `init` twice with the same name fails and changes nothing.
- [ ] `.git/info/exclude` holds `.autoresearch/` once after two campaigns.
- [ ] `git status` is clean after `init`.
- [ ] `stop` sets `draining`; `status` prints it.

_Done: ar.py init, stop, and status commands_

_Requirements: 1.3, 1.4, 1.5, 1.6, 3.7, 6.6_
_Depends: 1.1_

### 2.1 (P) ar.py SLURM layer

- `submit(script, worktree, out_dir) -> job_id` through `sbatch --parsable --chdir --output`.
- `states(job_ids) -> dict[str, str]` through one `sacct -n -P -X -j <ids> -o JobID,State` call. Strip suffixes such
  as `CANCELLED by 123`.
- Classify a state as `pending`, `ok`, `cluster-failure` (`NODE_FAIL`, `PREEMPTED`, `BOOT_FAIL`), or `failure`
  (everything else that is terminal).
- Raise a typed error when `sacct` or `sbatch` fails, with the first stderr line.

- [ ] Every job writes its output to the experiment directory, with the worktree as its working directory.
- [ ] One `sacct` call covers all jobs of a tick.
- [ ] A `sacct` failure raises before any ledger change.

_Requirements: 2.1, 2.9, 5.4, 5.5, 6.5_
_Depends: 1.1_
_Boundary: SlurmLayer_
_Done: ar.py slurm(), submit(), states(), classify(), and SlurmError_

### 2.2 (P) ar.py MLflow reader

- Open the database as `file:<path>?mode=ro` with a 30-second busy timeout.
- `find_run(campaign, exp, kind) -> run_id | None`: all three `autoresearch.*` tags match; take the latest
  `start_time`.
- `metric(run_id, key, aggregate) -> float | None`: rows with `is_nan = 0`; `last` by step then timestamp, or `min`,
  or `max`; return None for no finite value.

- [ ] Two runs with the same tags return the newer one.
- [ ] NaN and infinite values count as missing.
- [ ] The database file is never opened for writing.
- [ ] An unreadable database raises a typed error.

_Requirements: 2.2, 2.4, 2.9, 2.10_
_Depends: 1.1_
_Boundary: MlflowReader_

### 2.3 ar.py collect: job transitions and submissions

The first half of `collect`, under the lock.

- Query states for all non-terminal jobs (2.1).
- Smoke ended `ok` with a finite metric in the smoke run -> passed; any other end -> `smoke_failed` with the reason and
  the log path.
- Full ended `ok` -> read the run and metric (2.2) -> `done`, or `crashed` with `metric-missing`.
- `cluster-failure` with no prior resubmit -> submit the same script again, set `resubmitted`; else `crashed`.
- Passed smokes -> `running` when `running < max_parallel`, else `waiting`. Submit `waiting` experiments oldest first.
- `building` older than `build_timeout_hours` -> `abandoned`.
- Remove the worktree of every experiment that reached a terminal state. Keep the branch.
- On any reader error, exit non-zero and write nothing.

- [ ] Each transition in the design's status machine is reachable.
- [ ] Smoke jobs never block a full submission.
- [ ] A failed `sacct` leaves `ledger.json` byte-identical.
- [ ] Only paths under the campaign directory are touched by worktree removal.

_Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 4.11, 5.1, 5.2, 5.3, 6.9_
_Depends: 2.1, 2.2_

### 2.4 ar.py collect: verdicts and stop conditions

The second half of `collect`.

- Judge new `done` experiments in finish order: beat the champion by more than `min_delta` in `direction` ->
  `champion`, move the champion branch with `git branch -f`, push the previous champion to `history`; else `discard`.
- No champion metric -> verdict `pending`. When the baseline finishes, judge the pending ones in finish order.
- `max_experiments` reached -> `draining`. `plateau` consecutive `done` experiments without a new champion ->
  `draining`. Blank values disable the condition.
- `draining` with no non-terminal experiment -> `finished`.
- Return `{state, champion, free_slots, building, events}` with
  `free_slots = max_parallel - running - waiting - building - smoke`.

- [ ] An improvement equal to `min_delta` does not make a champion.
- [ ] `direction = "max"` flips the comparison.
- [ ] Pending verdicts resolve in finish order once the baseline is known.
- [ ] Only refs under `autoresearch/<campaign>/` move.

_Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.9, 3.10, 6.9_
_Depends: 2.3_

### 2.5 (P) ar.py new, smoke, and note

- `new <campaign> --hypothesis <text>`: allocate the next ID, create branch `autoresearch/<campaign>/<exp>` and a
  worktree under `worktrees/<exp>` from the champion commit, create `experiments/<exp>/`, record `building`.
- `smoke <campaign> <exp>`: list the paths changed between `parent` and the branch head; any path outside `scope`
  globs -> `crashed` with `out-of-scope: <paths>`; else record `commit`, submit `experiments/<exp>/smoke.sbatch`,
  set `smoke`. A missing script or a failed `sbatch` -> `crashed` with the reason.
- `note <campaign> --kind env|dead-end --text <text>`: append `- [<kind>] <text>` to `notes.md`, skipping exact
  repeats.

- [ ] Two concurrent `new` calls get different IDs.
- [ ] A commit that touches a file outside `scope` submits no job.
- [ ] A baseline experiment with no commits passes the scope check.

_Requirements: 4.5, 4.8, 4.9, 4.12, 6.9_
_Depends: 1.1, 2.1_
_Boundary: BuildCommands_

### 3.1 autoresearch-propose workflow

Create `.claude/workflows/autoresearch-propose.js`, in the style of `implement-units.js`.

- Guard: return an error when `args.slots` is missing, so a bare slash command does nothing.
- Phase Propose: three proposer agents in parallel. Each reads `ar.py status`, `notes.md`, and the champion code in
  scope, and returns `{proposals}`. Give each a different angle: architecture, optimization and schedule, and data
  and regularization. Each proposer considers combining finished winners that are not in the champion's lineage.
- Phase Judge: one agent picks at most `slots` proposals and rejects repeats of past hypotheses.
- Phase Build: builders in chunks of three. Each runs `ar.py new`, edits only in-scope files in its worktree, commits
  with a lowercase imperative subject and no type prefix, writes `smoke.sbatch` and `full.sbatch` from
  `referenceSbatch` with the three `autoresearch.*` MLflow tags, runs `ar.py smoke`, and reports notes through
  `ar.py note`. Builders run no training or tests on the login node.
- Return `{built, failed, rejected}`.

- [ ] At most three Opus agents run at the same time.
- [ ] Builders never edit `ledger.json` or the champion branch.
- [ ] The workflow parses as plain JavaScript and uses no `Date.now()` or `Math.random()`.

_Requirements: 4.3, 4.4, 4.6, 4.7, 4.10, 6.5_
_Depends: 2.5_

### 3.2 /autoresearch skill

Create `.claude/skills/autoresearch/SKILL.md`, under 100 lines.

- `init <campaign>`: one batched `AskUserQuestion` for every `campaign.toml` key and the baseline run ID; write the
  config to the scratchpad; run `ar.py init`. Without a baseline, create the baseline experiment through one builder
  agent that writes the scripts and changes no code. Print the permission rules for an unattended loop and the
  `/loop /autoresearch tick <campaign>` command.
- `tick <campaign>`: run `ar.py collect --json`. Start `autoresearch-propose` only when the state is `active`,
  `free_slots > 0`, and `building == 0`. Wait for its notification. Report in at most 10 lines. Schedule the next
  wakeup at 20 minutes with a smoke job in flight, else 60. On `finished`, stop the loop and print the final status.
- `status <campaign>` and `stop <campaign>`: pass through to `ar.py`.
- Never edit project code in the main session.

- [ ] A tick with no free slot starts no agent.
- [ ] A `draining` campaign starts no workflow.
- [ ] The skill file is under 100 lines.

_Requirements: 1.1, 1.2, 1.7, 1.8, 3.8, 4.1, 4.2, 6.2, 6.3, 6.4, 6.8_
_Depends: 1.2, 3.1_

### 4.1 Documentation and stow

- `CLAUDE.md`: add `autoresearch` to the skill list and update the count; add the `autoresearch-propose` workflow and
  the `ar.py` helper under "AI Agent Configuration".
- `docs/ai-tools.md`: a section on how to start a campaign, watch it with `status`, and stop it, plus the open question
  about compute-node API access.
- Run `stow .` so the new files link into `~/.claude/`.

- [ ] `~/.claude/skills/autoresearch/scripts/ar.py` and `~/.claude/workflows/autoresearch-propose.js` are symlinks.
- [ ] The skill count in `CLAUDE.md` matches `.claude/skills/`.

_Requirements: 7.1, 7.2_
_Depends: 3.2_

### 4.2 (P) End-to-end check with stubbed SLURM

A manual check in a scratch git repo. It adds no test files to this repo.

- Put stub `sbatch` and `sacct` scripts on `PATH` that hand out job IDs and read states from a file.
- Build a fixture MLflow SQLite database with the `runs`, `tags`, and `metrics` tables and tagged runs.
- Walk one campaign through init, a baseline, two experiments, a cluster failure with a resubmit, a new champion, and
  `draining` to `finished`.

- [ ] Every status in the design's status machine appears at least once.
- [ ] The champion branch points to the winning commit at the end.
- [ ] No `git` ref outside `autoresearch/<campaign>/` changed.

_Requirements: 2.3, 2.6, 2.7, 3.1, 3.4, 3.9_
_Depends: 2.4, 2.5_
_Boundary: Validation_

## Notes

- [1.1 env] UV_NO_SYNC=1 is set in this shell, so every `uv run --script ar.py` prints a harmless `--no-sync is a no-op` warning on stderr. Filter it when you parse output.
- [1.1 env] Run ruff on ar.py with `--target-version py311`. Without it, ruff treats tomllib as third-party and reports I001, because there is no pyproject to set the target.
- [1.1 deviation] ar.py main() takes the campaign lock for collect, new, smoke, note, and stop through LOCKED_COMMANDS and existing_campaign(). Handlers for these commands must not lock again. init must call campaign_lock(path) itself after it creates the directory.
- [1.1 deviation] Handlers have the signature `(args: argparse.Namespace) -> dict` and raise ArError for user errors. main() prints the dict through emit() as JSON or key: value lines, or prints {"error": msg} with exit 1. --json works before or after the subcommand.
- [1.2 deviation] ar.py emit() text mode now prints list values as 'key:' plus one indented line per item, and dict values as space-separated k=v pairs. Handlers can return nested dicts and lists and get readable text with no extra formatting code.
- [1.2 deviation] ar.py now has git(*args) -> str, which runs in repo_root() and raises ArError with stderr. It also has now() for ISO 8601 UTC timestamps and champion_branch(campaign). Reuse them in new, smoke, and collect.
- [1.2 env] init runs from a linked worktree and creates .autoresearch/ in that worktree's root, because repo_root() uses --show-toplevel. The exclude entry still goes to the shared .git/info/exclude.
- [2.1 deviation] ar.py SLURM API: slurm(*args)->stdout, submit(script, worktree, out_dir)->job_id, states(job_ids)->dict covering every requested id (unseen ids -> 'PENDING', empty list -> {} without calling sacct), classify(state)->'pending'|'ok'|'cluster-failure'|'failure'.
- [2.1 deviation] ar.py SlurmError subclasses ArError and str(exc) is just the first stderr line (e.g. 'sbatch: error: ...'), so collect can build f'submit-failed: {exc}' and an uncaught sacct failure exits 1 via main().
- [2.1 env] System python3 lacks tomllib, so importing ar.py for ad-hoc checks needs `uv run --python 3.11 --no-project python ...`.
