# Personal Preferences

## Safety

NEVER use destructive commands without explicit user approval. The following are **absolutely forbidden**:

- `rm -rf` (or any recursive force-delete)
- `git push --force` / `git push --force-with-lease`
- `git pull --force`
- `git reset --hard`
- `git checkout .` / `git restore .` (discarding all changes)
- `git clean -f`
- `git branch -D` (force-delete branch)

If a task seems to require one of these, stop and ask the user first.

## Response Style

Keep responses focused, brief, and concise. Put most of the response on the main answer;
keep disclaimers and caveats short. When asked to explain something, give a high-level
summary unless an in-depth one is specifically requested.

Lead with the outcome -- the first sentence after finishing work should answer "what
happened" or "what did you find". Supporting detail and reasoning come after, for readers
who want them. Readable beats terse: keep output short by dropping details that don't
change what the reader would do next, not by compressing prose into fragments,
abbreviations, arrow chains, or jargon. Match the response to the question -- a simple
question gets a direct answer in prose, not headers and sections.

**Written deliverables** (Markdown files, reports, docs) follow the same rule: match length
to what the task needs. Cover the substance, but do not pad with filler sections, redundant
summaries, or boilerplate.

Do not narrate routine actions between tool calls ("Now I'll...", "Let me check..."). Write
when there is something to report: a finding, a change of direction, or a blocker.

## SLURM Cluster

When working on a SLURM-backed GPU cluster, **never run compute-intensive scripts on the
login node** (training, inference, data preprocessing, large builds, profiling, etc.). The
login node is shared and meant only for editing, lightweight setup, and job submission.

Instead, run all real work through the scheduler via `sbatch` or `srun`. Default partition is `scalar100q`.

## Python

Always use `uv` (https://docs.astral.sh/uv/) for Python project management instead of pip, venv, conda, poetry, or pipenv.

### Style

- No `from __future__ import annotations`
- Logging: stdlib `logging` (or `loguru` if project already uses it)
- Strings: f-strings for all interpolation
- **Module layout: public at the top, private at the bottom.** Put public/consumer-facing
  definitions first and underscored helpers at the end, so a reader meets the API before
  the implementation details.
- **Prefer relative imports within a package** -- `from .foo import X`, not
  `from mypkg.foo import X`.

### Type checking

- Always invoke pyright via `uv run pyright <files>` so it picks up the project's `.venv`.
- For projects without a `pyrightconfig.json` / `[tool.pyright]` block, prefer adding one
  (`venvPath = "."`, `venv = ".venv"`) over relying on the `uv run` prefix.
- **Do not contort code to satisfy pyright.** No asserts, casts, or restructuring added
  purely to silence it; a false-positive fire is acceptable and preferable to obscuring
  the real logic.
- Pyright IS the right tool after a rebase across a base-class refactor, but **scope it to
  the changed files** -- a repo-wide run in a codebase with pre-existing errors drowns the
  signal.

## Code and Comments

- **No Unicode symbols in code or comments.** Use plain ASCII equivalents instead.

## Tests

- **Do not add tests unless asked.** If tests were added proactively, remove them.
- **Never delete or weaken pre-existing coverage unprompted.** If a change makes an
  existing test fail, fix the code or raise it -- do not quietly drop the test.

## Git Commits

- Never include issue IDs or numbers (e.g. `#5`, `#123`) in commit messages.

## Ultracode Mode

When operating in ultracode mode (workflows and other multi-agent fan-out), keep the
subagent fleet small: **at most 3 Opus subagents or 6 Sonnet subagents** in flight at
once. For a mixed fleet, count 1 Opus as 2 Sonnet slots against the same budget (so
1 Opus + 4 Sonnet is the ceiling). If a task looks like it needs a wider fan-out,
interview a user for unclear or complex parts.

## Spec-Driven Development (SDD)

For long-lived engineering work (pipelines, CLIs, APIs, shared libraries), use the spec
workflow. Skip it for throwaway scripts, notebooks, or one-off analysis.

**Code (plus its docs) is the source of truth; a spec is disposable scaffolding.** A spec
drives the work while it is active, but once the feature ships the durable record is the
code and the project docs -- not a frozen spec. `/spec-finalize` therefore reconciles the
docs with the shipped code and then removes the resolved spec entirely.

Specs live in `specs/<feature-name>/` and are managed by dedicated slash commands:

- `/spec-init <feature>` -- bootstrap the full spec (`requirements.md` (EARS), `design.md`,
  optional `research.md`, `tasks.md`) in one pass, then run `/spec-review` once on the
  finished spec
- `/spec-review <feature>` -- adversarially test the spec's soundness (is the problem
  real, the reasoning valid, the proposed solution correct) plus readiness; format is a
  one-line afterthought
- `/spec-implement <feature>` -- implement task-by-task via implementer subagents
  (orchestrator pattern); no reviewer in the loop
- `/impl-review spec <feature>` -- review the shipped code against the spec's acceptance
  criteria. Separate, user-invoked, and optional; run it when you want the work checked
- `/spec-finalize <feature>` -- close out a fully-implemented spec: reconcile the project
  docs with the shipped code (running an opus-subagent update cycle if they are stale),
  then remove the resolved spec directory so only code + up-to-date docs remain

There is no repo-level index: the presence of a `specs/<feature-name>/` directory _is_ the
record. A spec exists while the feature is active or not yet fully implemented; once it
ships, `/spec-finalize` removes the directory, so no spec means the work is done.

Each skill file (`~/.claude/skills/spec-*/SKILL.md`) is the source of truth for the
format details: EARS patterns, lifecycle frontmatter, task table layout, and traceability
rules. Do not re-derive them from this file.

## TODO Files

TODO files live in `todos/` organized by area: `todos/<area>.md` (e.g. `todos/solver.md`, `todos/api.md`, `todos/ui.md`).

The TODO workflow mirrors the SDD flow above: **code (plus its docs) is the source of
truth, and a TODO file tracks only open work.** Items have a `Status` column
(`Pending` / `Blocked`), plus a transient `Done` state used only while `/todo-implement`
is closing an item out. Once an item is implemented and any affected docs have been
reconciled, `/todo-implement` **removes** it from the file (git history keeps the record)
-- resolved items are not retained as a `Done` ledger.

When working with TODO files, follow this structure:

1. **Priority Summary table** at the very top - lists every open item (`Pending` or
   `Blocked`), sorted by priority (highest priority first). Exactly **three columns**:
   `Task`, `Priority`, and `Status`.
   - `Task` is a markdown link to the detailed section, with the link text as
     `[#N](anchor)` (e.g. `[#5](#5-broken-cache-invalidation)`). Do not put
     descriptions in the cell.
   - `Priority` is `P0` / `P1` / `P2`.
   - `Status` is `Pending` or `Blocked`. `Done` appears only transiently while
     `/todo-implement` closes an item out, before the item is removed from the file.
   - **Never use HTML anchors** (`<a id="N"></a>`) -- they are invisible in plain
     markdown and don't navigate reliably in VS Code. **Never use strikethrough**
     (`~~text~~`) on item titles -- update the `Status` column instead.
2. **Suggested resolution order** - after the Priority Summary table, an unnumbered
   (bullet) list of item numbers in recommended tackling order with brief rationale
   per item (e.g. `- #5 -- prerequisite for #7`). It naturally lists only still-open
   items, since resolved items are removed from the file entirely.
3. **Detailed sections** at the bottom - one heading per item with full description,
   context, and acceptance criteria
4. **Completion notes** - when `/todo-implement` marks an item `Done`, it appends a
   brief `_Done: ..._` note to the item's detailed section (e.g.
   `_Done: invalidation now runs on write; covered by tests_`). This note is transient:
   it records what shipped so the wrap-up doc-reconciliation step knows what changed, and
   it is removed along with the rest of the item when the item is purged from the file.
5. **Blocked notes** - when an item is marked `Blocked`, append a `_Blocked: {reason}_`
   line to its detailed section so the cause is visible alongside the description.
   Blocked items stay in the file (they are still open work).
