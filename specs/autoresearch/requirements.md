---
status: active
started: 2026-10-07
supersedes:
---

# Requirements: Autoresearch

## Summary

An autonomous research loop for ML training projects on the SLURM cluster, inspired by Karpathy's autoresearch. Agents
propose code changes to a project, the cluster trains each change for hours or days, and a deterministic rule keeps the
best result as the campaign's champion. The user starts a campaign once and lets `/loop` run ticks in a tmux session on
the login node. The deliverables live in this dotfiles repo and work in any project repository.

## In scope

- A `/autoresearch` skill with `init`, `tick`, `status`, and `stop`.
- An `ar.py` helper for the ledger, SLURM, MLflow, git worktrees, and the champion.
- An `autoresearch-propose` workflow that proposes, judges, builds, and smoke-submits experiments.
- Unattended operation under `/loop` in a tmux session on the login node.
- Documentation in this repo.

## Out of scope

- pi support.
- Early cancellation of running jobs.
- Approval gates and notifications.
- A screening stage beyond the smoke run.
- Starting ticks from cron, scrontab, or SLURM dependency jobs.
- Merging the champion into the project's main branch.
- Training, smoke runs, or tests on the login node.

## Requirements

## 1. Campaign setup

1.1 When the user runs `/autoresearch init <campaign>` in a git repository, the `/autoresearch` skill shall ask in one
batched question for the goal, metric name, metric direction, metric aggregation, minimum improvement, scope globs,
reference sbatch script, smoke-run guidance, MLflow database path, maximum experiment count, plateau count, and baseline
MLflow run ID.

1.2 The `/autoresearch` skill shall write the answers to a `campaign.toml` file that the `ar.py` helper validates.

1.3 When the `ar.py` helper creates a campaign, it shall add `.autoresearch/` to the repository's `.git/info/exclude`.

1.4 When the `ar.py` helper creates a campaign, it shall create the branch `autoresearch/<campaign>/champion` at the
current HEAD.

1.5 If the branch `autoresearch/<campaign>/champion` or the directory `.autoresearch/<campaign>/` already exists, the
`ar.py` helper shall refuse to create the campaign.

1.6 Where the user gives a baseline MLflow run ID, the `ar.py` helper shall record that run's target metric as the
champion metric.

1.7 Where the user gives no baseline run ID, the `/autoresearch` skill shall create a first experiment that runs the
champion code and is marked as the baseline.

1.8 When init finishes, the `/autoresearch` skill shall print the permission rules that an unattended loop needs and the
`/loop` command that starts it.

1.9 When the user creates an experiment with `--baseline`, the `ar.py` helper shall mark the experiment as the baseline
in the ledger.

## 2. Collecting results

2.1 When a tick starts, the `ar.py` helper shall read the SLURM state of every smoke and full job that is not in a
terminal state in the ledger.

2.2 When a smoke job ends with state `COMPLETED`, an MLflow run carries the experiment's tags with kind `smoke`, and that
run logged a finite value of the target metric, the `ar.py` helper shall mark the smoke as passed.

2.3 If a smoke job ends in any other way, the `ar.py` helper shall mark the experiment `smoke_failed` with the reason and
the path of the SLURM log.

2.4 When a full job ends with state `COMPLETED` and its MLflow run has a finite target metric, the `ar.py` helper shall
record the metric under the campaign's aggregation rule and mark the experiment `done`.

2.5 If a full job ends with state `COMPLETED` and its MLflow run has no finite target metric, the `ar.py` helper shall
mark the experiment `crashed` with reason `metric-missing`.

2.6 If a smoke or full job ends with state `NODE_FAIL`, `PREEMPTED`, or `BOOT_FAIL` and the job was not resubmitted
before, the `ar.py` helper shall submit the same sbatch script again and record the new job ID.

2.7 If a job ends with `FAILED`, `TIMEOUT`, `OUT_OF_MEMORY`, `CANCELLED`, or a second cluster failure, the `ar.py` helper
shall mark the experiment `crashed` with the SLURM state as the reason.

2.8 When an experiment reaches a terminal state, the `ar.py` helper shall remove its worktree and keep its branch.

2.9 If `sacct` or the MLflow database cannot be read, the `ar.py` helper shall exit with an error and change no ledger
entry.

2.10 When several MLflow runs carry the same experiment tags and kind, the `ar.py` helper shall use the run with the
latest start time.

## 3. Champion and stop conditions

3.1 When an experiment becomes `done` and a champion metric exists, the `ar.py` helper shall make the experiment the
champion if its metric beats the champion metric by more than the minimum improvement in the metric direction.

3.2 When an experiment becomes champion, the `ar.py` helper shall move `autoresearch/<campaign>/champion` to the
experiment's commit and append the previous champion to the ledger's champion history.

3.3 When a `done` experiment does not beat the champion, the `ar.py` helper shall set its verdict to `discard`.

3.4 While no champion metric exists, the `ar.py` helper shall take the champion metric from the first `done` experiment
that is marked as the baseline, set the verdict of other `done` experiments to `pending`, and judge them in finish
order once the baseline metric arrives.

3.5 When the number of created experiments reaches the maximum experiment count, the `ar.py` helper shall set the
campaign state to `draining`.

3.6 When the plateau count of consecutive `done` experiments passes without a new champion, the `ar.py` helper shall set
the campaign state to `draining`.

3.7 When the user runs `/autoresearch stop <campaign>`, the `ar.py` helper shall set the campaign state to `draining`.

3.8 While the campaign state is `draining`, the `/autoresearch` skill shall create no experiments and shall keep
collecting results.

3.9 When a `draining` campaign has no experiment in a non-terminal state, the `ar.py` helper shall set the campaign state
to `finished`.

3.10 Where the maximum experiment count or the plateau count is blank in `campaign.toml`, the `ar.py` helper shall not
apply that stop condition.

3.11 If the number of created experiments has reached the maximum experiment count, the `ar.py` helper shall refuse to
create an experiment.

3.12 Where a maximum experiment count is set, the `ar.py` helper shall report no more free slots than the number of
experiments that the count still allows.

## 4. Proposing and building experiments

4.1 When a tick finds the campaign `active` with free slots, the `/autoresearch` skill shall start the
`autoresearch-propose` workflow with the number of free slots.

4.2 While an experiment of the campaign is `building`, the `/autoresearch` skill shall not start the
`autoresearch-propose` workflow.

4.3 The `autoresearch-propose` workflow shall run three proposer agents in parallel, each reading the ledger,
`notes.md`, and the champion code in scope.

4.4 The `autoresearch-propose` workflow shall run one judge agent that picks at most the number of free slots from all
proposals and rejects a proposal that repeats a past experiment's hypothesis.

4.5 When the judge picks a proposal, the `ar.py` helper shall create the branch `autoresearch/<campaign>/<exp-id>` and a
worktree from the current champion commit, and record the experiment as `building`.

4.6 The builder agent shall put every change of the experiment in files that match the campaign's scope globs, in the
experiment's worktree, and commit the change on the experiment branch.

4.7 The builder agent shall write a smoke sbatch script and a full sbatch script for the experiment, based on the
reference sbatch script, that set the MLflow tags `autoresearch.campaign`, `autoresearch.exp`, and `autoresearch.kind`.
The scripts shall set only SLURM resources, the smoke shrink from the smoke-run guidance, the MLflow tags, the checkpoint
directory, and MLflow param logging. They shall set no hyperparameter override.

4.8 When the builder agent finishes, the `ar.py` helper shall check that the experiment's commits change only paths in
scope, then submit the smoke job and mark the experiment `smoke`.

4.9 If an experiment's commits change a path outside the scope, the `ar.py` helper shall mark the experiment `crashed`
with reason `out-of-scope` and submit no job.

4.10 The `autoresearch-propose` workflow shall run at most three Opus agents at the same time.

4.11 If an experiment stays `building` longer than the campaign's build timeout, the `ar.py` helper shall mark it
`abandoned` and remove its worktree.

4.12 When a builder agent reports an environment fact or a dead end, the `ar.py` helper shall append it to `notes.md`.

4.13 The builder agent shall make every smoke and full run log its hyperparameters and config to MLflow as run params.
Where the project logs no run params, the builder agent shall add the logging as a change in scope.

4.14 If the param logging needs a change outside the scope, the builder agent shall report it as an `env` note and
return an error.

4.15 The builder agent shall set the training checkpoint and output directory, in the sbatch scripts, to the absolute
path of the experiment's directory in the campaign.

4.16 If the experiment's worktree has uncommitted changes or untracked files that git does not ignore, the `ar.py`
helper shall mark the experiment `crashed` with reason `dirty-worktree` and the paths, and submit no job.

4.17 If a builder agent returns an error or no result while its experiment is `building`, the `autoresearch-propose`
workflow shall mark the experiment `abandoned` through the `ar.py` helper.

4.18 If the user asks the `ar.py` helper to abandon an experiment that is not `building`, the helper shall refuse and
change nothing.

## 5. Submitting full runs

5.1 When an experiment's smoke passes and the number of queued or running full jobs is below `max_parallel`, the
`ar.py` helper shall submit the experiment's full sbatch script and mark it `running`.

5.2 When an experiment's smoke passes and no slot is free, the `ar.py` helper shall mark it `waiting` and submit it in a
later tick, oldest first.

5.3 The `ar.py` helper shall not count smoke jobs toward `max_parallel`.

5.4 The `ar.py` helper shall submit every job with the experiment's worktree as its working directory.

5.5 The `ar.py` helper shall write the SLURM output of every job to the experiment's directory in the campaign.

## 6. Unattended operation

6.1 The `ar.py` helper shall hold an exclusive lock on the campaign while it changes the ledger.

6.2 When a tick finds no free slot, the `/autoresearch` skill shall finish the tick without starting an agent.

6.3 While ticks run under `/loop`, the `/autoresearch` skill shall schedule the next tick 20 minutes ahead when a smoke
job is in flight, and 60 minutes ahead otherwise.

6.4 When the campaign state is `finished`, the `/autoresearch` skill shall end the loop and print the final report.

6.5 The `ar.py` helper and the workflow agents shall start GPU work only through `sbatch`, never on the login node.

6.6 When the user runs `/autoresearch status <campaign>`, the `ar.py` helper shall print the campaign state, the
champion with its metric, and one line per experiment with its ID, status, verdict, metric, and hypothesis.

6.7 The `ar.py` helper shall use only the Python standard library.

6.8 The `/autoresearch` skill shall report each tick in at most 10 lines.

6.9 The `ar.py` helper shall change no git ref outside the `autoresearch/<campaign>/` namespace and no worktree outside
the campaign directory.

## 7. Documentation

7.1 The repository's `CLAUDE.md` shall list the `autoresearch` skill, the `autoresearch-propose` workflow, and the
`ar.py` helper.

7.2 The `docs/ai-tools.md` page shall describe how to start, watch, and stop a campaign.

## Open questions

- Can compute nodes reach the Anthropic API? Check this in a session on the cluster. If they can, a later change can
  start ticks from a SLURM `--dependency=afterany` job, so the loop no longer needs a live tmux session. This is not a
  blocker: `/loop` in tmux works without it.
- The `ar.py` helper reads the MLflow SQLite database directly. Check the table names (`runs`, `tags`, `metrics`)
  against the MLflow version on the cluster.
- Check that `sacct` is available to users on the cluster. The SLURM layer depends on it.
