# Personal Preferences

## Safety

Never use destructive commands without explicit user approval. The following are
forbidden unless the user explicitly authorizes the exact operation:

- `rm -rf` or any recursive force-delete
- `git push --force` or `git push --force-with-lease`
- `git pull --force`
- `git reset --hard`
- `git checkout .` or `git restore .`
- `git clean -f`
- `git branch -D`

Prefer recoverable operations and inspect exact targets before deleting or
overwriting anything.

## SLURM Cluster

On a SLURM-backed GPU cluster, never run compute-intensive scripts on the login
node. Use `sbatch` for long-running or reproducible work and `srun` with explicit
resources for short diagnostics.

For GPU work, start with the appropriate number of GPUs on `scalar100q`, 12 CPUs
per GPU, and 80 GB memory per GPU. Run `sinfo` before submitting. Use
`scalar6000q` when A100s are saturated or A6000s suffice. Avoid `defq` because
hardware assignment is nondeterministic, and do not use `hyperplaneq` for agent
diagnostics or experiments.

The agent scratchpad is login-node-local and invisible to compute nodes. Put
project files, job inputs, and outputs on a shared filesystem. Run Hugging Face
Xet uploads under a CPU `srun`; the token is cached in the shared `HF_HOME`.
Remember that `sbatch` snapshots the batch script at submission time and writes
logs to the submit directory unless configured otherwise.

If the correct partition or GPU count is unclear, ask before submitting.

## Python

Use `uv` for Python project and environment management instead of pip, venv,
conda, poetry, or pipenv.

- Do not add `from __future__ import annotations`.
- Use stdlib `logging`, or `loguru` when the project already uses it.
- Use f-strings for interpolation.
- Put public definitions before private helpers.
- Prefer relative imports within a package.
- Keep variant environments at the project root as `.venv-<variant>` and select
  them with `UV_PROJECT_ENVIRONMENT`.
- `uv pip` ignores `UV_PROJECT_ENVIRONMENT`; use `uv sync`, `uv run`, or
  explicitly activate the target environment.
- Run Pyright as `uv run pyright <files>`. Prefer a project Pyright config with
  `venvPath = "."` and `venv = ".venv"` when one is missing.
- Do not distort code with assertions, casts, or restructuring solely to silence
  Pyright. Scope checks to changed files in repositories with existing errors.

## Code and Comments

Use ASCII only in code and comments. For example, use `->`, `>=`, `<=`, and
`!=` instead of Unicode mathematical symbols.

## Tests

Do not add tests unless asked. Never delete or weaken existing coverage
unprompted. If an existing test fails after a change, fix the code or report the
conflict.

## Git Commits

Never include issue IDs such as `#5` or `#123` in commit messages because GitLab
may interpret them as issue references.

## Multi-Agent Work

Keep subagent workflows bounded. Use no more than six spawned threads at once,
excluding the primary thread. Prefer `gpt-5.6-terra` for focused implementation
or read-heavy scans and `gpt-5.6-sol` with high or xhigh reasoning for demanding
review and escalation. Run write-heavy agents sequentially when their file
ownership overlaps.

## Spec-Driven Development

For long-lived engineering work such as pipelines, CLIs, APIs, and shared
libraries, use the spec workflow. Skip it for throwaway scripts, notebooks, and
one-off analysis.

Code plus current documentation is the source of truth. A spec is disposable
scaffolding:

- `$spec-init <feature>` creates requirements, design, optional research, and
  tasks under `specs/<feature>/`, then reviews the finished spec.
- `$spec-review <feature>` adversarially checks the problem, reasoning, and
  solution before implementation.
- `$spec-implement <feature>` executes tasks through independent implementer and
  reviewer subagents.
- `$spec-finalize <feature>` reconciles documentation with shipped code, then
  removes the resolved spec.

The relevant `.agents/skills/spec-*/SKILL.md` files define the detailed formats
and lifecycle.

## TODO Files

Store open work in `todos/<area>.md`. Each file contains:

1. A three-column Priority Summary table (`Task`, `Priority`, `Status`) sorted
   by priority. Task cells are links such as `[#5](#5-title)`. Valid persistent
   statuses are `Pending` and `Blocked`; `Done` is transient during closeout.
2. An unnumbered Suggested resolution order list containing only open items.
3. One detailed section per item with context and acceptance criteria.
4. A transient `_Done: ..._` note while `$todo-implement` reconciles docs and
   removes completed work.
5. A `_Blocked: <reason>_` note for blocked items.

Do not use HTML anchors or strikethrough for TODO state. Completed items are
removed after documentation is reconciled; Git history retains the record.
