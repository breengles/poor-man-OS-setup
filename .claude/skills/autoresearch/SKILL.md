---
name: autoresearch
description:
  Run an autoresearch campaign - agents propose and build code changes, SLURM trains them, and the best result becomes
  the champion. Ticks run under /loop.
argument-hint: "init | tick | status | stop | baseline <campaign>"
---

# autoresearch

You are the **campaign driver**. `ar.py` owns every status change, comparison, and git ref. Agents do the creative work
in experiment worktrees. You never edit project code, `ledger.json`, or a git ref in this session.

Run every `ar.py` call from the project root (`git rev-parse --show-toplevel`) as
`uv run --script ~/.claude/skills/autoresearch/scripts/ar.py <command> <campaign> ... --json`. Ignore warnings on
stderr. A non-zero exit prints `{"error": ...}`: report it and stop the current step.

The first argument is the subcommand. The second is the campaign name. Ask for a missing name.

## init

1. Check the prerequisites: the training code logs its hyperparameters and config to MLflow as run params, and can
   set MLflow run tags. If it cannot, stop and tell the user to add this first. Then skim the repo for defaults:
   sbatch scripts, the MLflow database path, logged metric names, and the code the change should touch.
2. Ask **one** `AskUserQuestion` call with four questions. Each option is a complete drafted value, and "Other" lets
   the user type their own:
   - Goal and metric: `goal`, `metric`, `direction` (`min` or `max`), `aggregate` (`last`, `min`, or `max`),
     `min_delta` (absolute).
   - Scope: `scope`, the globs of the only files an experiment may change.
   - Runs: `reference_sbatch`, `smoke_hint` (how to shrink a run to a short smoke job), `mlflow_db`.
   - Limits: `max_parallel`, `max_experiments` and `plateau` (blank for no limit), `build_timeout_hours`, and the
     baseline MLflow run ID (blank to run a baseline experiment).
3. Write `campaign.toml` to the scratchpad. Leave out `max_experiments` and `plateau` when they are blank.
4. Run `ar.py init <campaign> --config <scratchpad>/campaign.toml`, plus `--baseline <run-id>` when the user gave one.
   On an error, fix the config with the user and run it again.
5. Without a baseline run ID, run the **Baseline** section.
6. Print the permission rules and the loop command below.

Permission rules for `.claude/settings.local.json` in the project, so the loop runs without prompts:

```json
"allow": [
  "Bash(uv run --script ~/.claude/skills/autoresearch/scripts/ar.py *)",
  "Bash(cd *)", "Bash(git *)", "Bash(ls *)", "Bash(cat *)", "Bash(sacct *)", "Bash(seff *)", "Bash(tail *)",
  "Edit(/.autoresearch/**)", "Write(/.autoresearch/**)", "Workflow", "Agent(slurm-triage)"
]
```

Then start the loop in a tmux session on the login node: `/loop /autoresearch tick <campaign>`.

## Baseline

Without a baseline metric, `ar.py` judges no experiment. Dispatch **one** builder agent with the campaign values and:

1. Run `ar.py new <campaign> --baseline --hypothesis "baseline: the champion code" --json` -> `{exp, worktree, dir}`.
2. Change no code and make no commit.
3. Write `<dir>/smoke.sbatch` and `<dir>/full.sbatch` from `reference_sbatch`, with no hyperparameter override. They
   set only SLURM resources, the `smoke_hint` shrink, param logging, the MLflow tags `autoresearch.campaign=<campaign>`,
   `autoresearch.exp=<exp>`, and `autoresearch.kind=smoke|full` through the project's own tag mechanism, and the
   checkpoint and output directory: the absolute `<dir>`, because `ar.py` removes the worktree. No `--chdir`/`--output`.
4. Run `ar.py smoke <campaign> <exp> --json` and return its result.
5. Run no training, tests, or project code: this is a login node. Never touch `ledger.json` or a git ref.

If the builder fails while its experiment is `building`, run `ar.py abandon <campaign> <exp> --reason <error>` and
`ar.py note <campaign> --kind env --text <fact>`. Report the experiment ID and the smoke job ID.

## tick

1. Run `ar.py collect <campaign> --json`. It returns `{state, champion, free_slots, building, events}`. On an error,
   report it and go to step 5.
2. Start `autoresearch-propose` only when `state` is `active`, `free_slots > 0`, and `building == 0`. In every other
   case, start no agent and no workflow. A `draining` campaign only collects results.
3. To start it, read `.autoresearch/<campaign>/campaign.toml` and call
   `Workflow({name: "autoresearch-propose", args})` with `campaign`, `repo` (absolute project root), `campaignDir`
   (absolute), `slots: free_slots`, `goal`, `metric`, `direction`, `minDelta`, `scope` (an array), `referenceSbatch`,
   and `smokeHint`. If the tool cannot find the name, read `~/.claude/workflows/autoresearch-propose.js` and pass its
   text as `script`. Wait for its completion notification. It returns `{built, failed, rejected}`.
4. Run `ar.py status <campaign> --json` once. Send **one** `slurm-triage` agent the `<campaignDir>/experiments/<exp>/`
   of each failed run. Pass each `environment` or `cluster` cause to `ar.py note <campaign> --kind env --text <cause>`.
5. Report in **at most 10 lines**: a new champion and its metric, finished and failed experiments with causes, built
   and rejected experiments, and the next tick time. When the champion metric is still null and the experiment with
   `baseline: true` ended in a state other than `done`, say so. Later results stay `pending` until the user runs
   `/autoresearch baseline <campaign>` again.
6. Under `/loop`, call `ScheduleWakeup`: 20 minutes ahead when any experiment has status `smoke`, else 60 minutes.
   When `state` is `finished`, call it with `stop: true` instead, and print the full `ar.py status` output as the
   final report.

## status, stop, and baseline

- `status <campaign>`: run `ar.py status <campaign>` without `--json` and print its output.
- `stop <campaign>`: run `ar.py stop <campaign>`. The campaign drains: running jobs finish, and no new experiment
  starts. It becomes `finished` when nothing is left in flight.
- `baseline <campaign>`: run the **Baseline** section. Use it when the baseline experiment crashed.

## Constraints

- Never edit project code in this session. Only builder agents change code, and only in their own worktrees.
- Never edit `ledger.json`, `campaign.toml` after init, or any `autoresearch/<campaign>/` ref by hand.
- Run no training or tests on the login node. GPU work goes only through `sbatch`, which `ar.py` calls.
