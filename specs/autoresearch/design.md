# Design: Autoresearch

## Overview

A campaign is a long-lived search over code changes to one project. One full training run can take from minutes to a
week, so the loop cannot live inside one session or one workflow run. The state lives on disk in the project, and short
**ticks** move it forward:

1. `ar.py collect` reads SLURM and MLflow, updates the ledger, picks champions, and submits waiting full jobs. This step
   is plain code and starts no agent.
2. If slots are free, the `autoresearch-propose` workflow proposes, judges, and builds new experiments, then submits
   their smoke jobs.

`/loop` in a tmux session on the login node runs ticks. Agents do only the creative work: they propose changes, edit code,
and write sbatch scripts. Every status change, comparison, and git ref update goes through `ar.py`.

## Architecture

| Component                   | File (in this repo)                         | Responsibility                                                                                               |
| --------------------------- | ------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `/autoresearch` skill       | `.claude/skills/autoresearch/SKILL.md`      | Interview at init, baseline, tick orchestration, loop cadence, status, stop. Never edits project code.       |
| `ar.py` helper              | `.claude/skills/autoresearch/scripts/ar.py` | Ledger, lock, campaign config, SLURM submit and state, MLflow reads, champion rule, worktrees, scope checks. |
| `autoresearch-propose` flow | `.claude/workflows/autoresearch-propose.js` | Three proposers, one judge, builders in chunks of three. Returns built and failed experiments.               |

Stow deploys all three to `~/.claude/`. Run `stow .` once after the files land, because `.stowrc` sets `--no-folding`.

Campaign state, in the target project:

```
<repo>/.autoresearch/<campaign>/
  campaign.toml          # config, written at init
  ledger.json            # all state; only ar.py writes it
  notes.md               # steering by the user, facts from builders
  lock                   # flock target
  experiments/<exp-id>/  # smoke.sbatch, full.sbatch, slurm-<jobid>.out
  worktrees/<exp-id>/    # git worktree, removed when the experiment ends
```

Git refs: `autoresearch/<campaign>/champion` and one `autoresearch/<campaign>/<exp-id>` branch per experiment.

## Data flow

```
/loop -> /autoresearch tick <campaign>
  ar.py collect --json
    lock
    sacct for each non-terminal job ------------> SLURM
    for finished jobs: read run by tags ---------> MLflow SQLite (read-only)
    apply transitions, verdicts, stop conditions
    submit waiting full jobs (sbatch) -----------> SLURM
    write ledger.json atomically, unlock
    print summary JSON
  if state == active and free_slots > 0 and nothing is building:
    Workflow autoresearch-propose (async; tick waits for its notification)
      3 proposers (parallel) -> judge -> builders (3 at a time)
        builder: ar.py new -> edit + commit in worktree -> write sbatch scripts -> ar.py smoke
  print <= 10 line report, schedule the next wakeup (20 or 60 min)
```

The next tick picks up smoke results. A smoke pass leads to a full submission in the same `collect` call when a slot is
free.

Experiment status machine:

```
building -> smoke -> waiting -> running -> done
   |          |         \________/  \
   |          |                      -> crashed
   |          -> smoke_failed
   -> abandoned            (also: building -> crashed on out-of-scope or submit failure)
```

`smoke -> running` skips `waiting` when a slot is free. Terminal states: `done`, `crashed`, `smoke_failed`, `abandoned`.

## Data models / interfaces

### `campaign.toml`

```toml
goal = "lower val loss of the 1B finetune on dataset X"
metric = "val/loss"
direction = "min"             # "min" | "max"
aggregate = "last"            # "last" | "min" | "max" over the logged steps
min_delta = 0.01              # absolute; an improvement must exceed this
scope = ["src/model/**", "configs/train/**"]
reference_sbatch = "scripts/train.sbatch"
smoke_hint = "trainer.max_steps=50, 1 GPU, --time=00:30:00, partition scalar100q"
mlflow_db = "/shared/mlflow/mlflow.db"
max_parallel = 5
max_experiments = 40          # omit for no limit
plateau = 10                  # omit for no limit
build_timeout_hours = 3
```

### `ledger.json`

```python
@dataclass
class Job:
    kind: str                 # "smoke" | "full"
    job_id: str
    resubmitted: bool
    state: str | None         # last SLURM state seen

@dataclass
class Experiment:
    id: str                   # "e0007"
    hypothesis: str
    parent: str               # champion commit at creation
    branch: str               # autoresearch/<campaign>/e0007
    commit: str | None        # head of the experiment branch at smoke submission
    status: str               # building | smoke | waiting | running | done | crashed | smoke_failed | abandoned
    verdict: str | None       # champion | discard | pending
    metric: float | None
    run_id: str | None        # MLflow run of the full job
    reason: str | None        # crash or failure reason
    jobs: list[Job]
    created_at: str           # ISO 8601, set by ar.py
    finished_at: str | None

@dataclass
class Champion:
    exp: str | None           # None for the init commit
    commit: str
    metric: float | None      # None until the baseline is known
    since: str

@dataclass
class Ledger:
    campaign: str
    state: str                # active | draining | finished
    champion: Champion
    history: list[Champion]
    next_id: int
    experiments: list[Experiment]
```

### `ar.py` command line

Run as `uv run --script ~/.claude/skills/autoresearch/scripts/ar.py <command> ...` from the project root. A PEP 723
header pins `requires-python = ">=3.11"` for `tomllib` and declares no dependencies. Each command prints JSON with
`--json`, and text without it.

| Command                                              | Effect                                                                                            |
| ---------------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `init <campaign> --config <toml> [--baseline <run>]` | Validate config, create the directory, the exclude entry, the champion branch, and the ledger.    |
| `collect <campaign>`                                 | The tick's deterministic part. Returns `{state, champion, free_slots, building, events}`.         |
| `new <campaign> --hypothesis <text>`                 | Allocate an ID, create the branch and worktree from the champion. Returns `{exp, worktree, dir}`. |
| `smoke <campaign> <exp>`                             | Scope check, record the commit, submit `smoke.sbatch`. Returns `{job}` or `{error}`.              |
| `note <campaign> --kind env\|dead-end --text <text>` | Append one line to `notes.md`, skipping exact repeats.                                            |
| `stop <campaign>`                                    | Set the state to `draining`.                                                                      |
| `status <campaign>`                                  | Print the campaign state, the champion, and one line per experiment.                              |

`free_slots = max_parallel - running - waiting - building - smoke`. Smoke jobs do not use a `max_parallel` slot. They
count here so that the tick does not build more experiments than the slots can run.

### Job submission

`sbatch --parsable --chdir <worktree> --output <campaign>/experiments/<exp>/slurm-%j.out <script>`. The builder writes
the scripts. `ar.py` sets the working directory and the output path, so a script cannot write outside the campaign.

### MLflow lookup

Open the database as `file:<path>?mode=ro` with a 30-second busy timeout. Find runs where tag `autoresearch.campaign`,
`autoresearch.exp`, and `autoresearch.kind` all match, and take the one with the latest `start_time`. Read the target
metric from `metrics` where `is_nan = 0`, and aggregate by `aggregate`. A value that is NaN or infinite is not finite.

### Workflow interface

`Workflow({name: "autoresearch-propose", args})` with:

```js
{
  campaign: "lr-sweep",
  repo: "/abs/path/to/project",
  campaignDir: "/abs/path/to/project/.autoresearch/lr-sweep",
  slots: 2,
  goal, metric, direction, minDelta, scope, referenceSbatch, smokeHint,
}
```

It returns `{built: [{exp, job}], failed: [{exp, reason}], rejected: [hypothesis]}`. Proposers return
`{proposals: [{hypothesis, change, files, rationale}]}`. The judge returns `{picked: [index], rejected: [{index, reason}]}`.
Builders return `{exp, job, error, notes: [{kind, note}]}`, and they report notes through `ar.py note` themselves.

## Decisions

- **One workflow run per tick, not per campaign.** A workflow is bound to a session, and its agents cannot wait days for a
  job. Rejected: one long workflow, and one long agent session in the style of Karpathy's `program.md`.
- **Bookkeeping in code, creative work in agents.** `ar.py` owns every status change, comparison, and ref update. Rejected:
  agents that edit the ledger. They drift after compaction and are slow and costly for mechanical work.
- **Champion rule in code.** Keep a result only if it beats the champion by more than `min_delta`. The agent that wrote a
  change never grades it.
- **A tree of experiments, not a line.** Several experiments run at the same time from the champion of their creation
  time. A finished experiment competes on its absolute metric. Combining two winners is a new proposal. Rejected:
  `git revert` or `git reset` on one branch, which assumes one job at a time.
- **One frozen worktree per experiment.** A job that runs for days must see code that does not change, also after a
  requeue. The worktree goes away only after the job ends. Rejected: `Workflow` `isolation: 'worktree'`, which is
  removed when the agent ends.
- **Standard library only.** `sqlite3` reads MLflow directly, `tomllib` reads the config, and `argparse` parses the
  commands. Rejected: the `mlflow` client, which needs the project venv or a dependency. Rejected: pyrallis, which has
  no subcommands. Rejected: YAML, which needs PyYAML.
- **JSON ledger, rewritten atomically.** Statuses change, so an append-only TSV does not fit. Write to a temp file, then
  `Path.replace`.
- **`.git/info/exclude`, not `.gitignore`.** A campaign changes no tracked file in the project.
- **Smoke jobs through `sbatch`.** The login node is only for editing and job submission. Pass means exit `COMPLETED`
  plus a finite target metric in a run with the right tags. The tag check also proves that the tags reach MLflow.
- **Builders write their own sbatch scripts.** The user asked for this. Each experiment needs its own MLflow tags, and
  the builder bases the scripts on `reference_sbatch`.
- **Three proposers and one judge.** Tokens are cheap and GPU-days are expensive. Three Opus proposers plus builders in
  chunks of three fit the fleet cap of three Opus agents in flight.
- **Resubmit once, only for cluster failures.** `NODE_FAIL`, `PREEMPTED`, and `BOOT_FAIL` are not the change's fault.
  `FAILED`, `TIMEOUT`, and `OUT_OF_MEMORY` are.
- **`/loop` in tmux as the scheduler.** The user always runs Claude Code in tmux. Rejected for now: cron and SLURM
  dependency jobs. It is not known if compute nodes can reach the API.
- **Build vs. adopt.** Rejected: `uditgoenka/autoresearch`. Its global hooks block `*.log`, `out/`, `.venv/`, and
  `git reset --hard` in every session, and its loop runs one job at a time. Karpathy's `program.md` is an idea source
  only.
- **No early cancellation, no approval gate, no notifications.** The user chose this.

## Error handling

| Failure                                  | Behavior                                                                                           |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------- |
| `sacct` fails or the MLflow DB is locked | `collect` exits non-zero and writes nothing. The tick reports it and waits for the next tick.      |
| `ledger.json` does not parse             | Every command stops with the path. The user repairs it by hand. `ar.py` never rewrites it blindly. |
| `sbatch` fails at smoke or full submit   | The experiment becomes `crashed` with reason `submit-failed: <stderr first line>`.                 |
| Builder returns null or the session dies | The experiment stays `building`, then becomes `abandoned` after `build_timeout_hours`.             |
| Out-of-scope paths in the commits        | `crashed`, reason `out-of-scope: <paths>`. No job.                                                 |
| Second lock holder                       | The second `ar.py` call waits up to 60 seconds, then exits with an error.                          |
| `git worktree add` or `branch` fails     | `new` exits with an error and records nothing.                                                     |

## Observability

- `/autoresearch status <campaign>` for the full table.
- One tick report of up to 10 lines: new champion, finished and failed experiments, submissions, and the next tick time.
- SLURM logs in `experiments/<exp-id>/`.
- MLflow UI: filter by tag `autoresearch.campaign`.
- `notes.md` for learned facts and user steering.

## Requirements traceability

| Requirement | Design sections                                          |
| ----------- | -------------------------------------------------------- |
| 1.1, 1.2    | Architecture (skill), `campaign.toml`                    |
| 1.3-1.6     | `ar.py` command line (`init`), Decisions (exclude)       |
| 1.7, 1.8    | Architecture (skill), Data flow                          |
| 2.1         | Data flow, Job submission                                |
| 2.2, 2.3    | MLflow lookup, Decisions (smoke), status machine         |
| 2.4, 2.5    | MLflow lookup, status machine                            |
| 2.6, 2.7    | Decisions (resubmit), status machine                     |
| 2.8         | Decisions (frozen worktree)                              |
| 2.9         | Error handling                                           |
| 2.10        | MLflow lookup                                            |
| 3.1-3.4     | Decisions (champion rule, tree), `ledger.json`           |
| 3.5-3.10    | `ledger.json` (state), `campaign.toml`, `ar.py` (`stop`) |
| 4.1, 4.2    | Data flow, `ar.py` command line (free slots)             |
| 4.3, 4.4    | Workflow interface, Decisions (three proposers)          |
| 4.5         | `ar.py` command line (`new`)                             |
| 4.6, 4.7    | Workflow interface, Decisions (builders write sbatch)    |
| 4.8, 4.9    | `ar.py` command line (`smoke`), Error handling           |
| 4.10        | Decisions (three proposers)                              |
| 4.11        | Error handling, `campaign.toml`                          |
| 4.12        | `ar.py` command line (`note`)                            |
| 5.1-5.3     | Data flow, `ar.py` command line (free slots)             |
| 5.4, 5.5    | Job submission                                           |
| 6.1         | Error handling (lock), campaign state layout             |
| 6.2-6.4     | Data flow                                                |
| 6.5         | Decisions (smoke through sbatch)                         |
| 6.6         | `ar.py` command line (`status`), Observability           |
| 6.7         | Decisions (standard library only)                        |
| 6.8         | Observability                                            |
| 6.9         | Job submission, campaign state layout                    |
| 7.1, 7.2    | Architecture                                             |
