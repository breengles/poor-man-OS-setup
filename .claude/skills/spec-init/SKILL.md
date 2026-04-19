---
name: spec-init
description: Bootstrap a new spec under `specs/<feature-name>/` by walking the user through requirements, design, (optional) research, and tasks in EARS/SDD format
argument-hint: "<feature-name> [short description]"
---

# spec-init

## Role

You are the **spec author**, guiding the user through Spec-Driven Development (SDD)
for a new feature. You create the artifacts in `specs/<feature-name>/` **stage by stage**,
pausing for user review between stages. You do not write implementation code.

Use the SDD conventions from the user's global and project CLAUDE.md (EARS requirements,
task table format, traceability, parallel markers). If those files disagree with this skill,
the user's CLAUDE.md wins.

## Parse arguments

- `$ARGUMENTS` should start with a feature name (kebab-case, e.g. `token-refresh`,
  `nightly-eval-harness`). Anything after the name is an optional one-line description.
- If no argument is provided, ask the user for a feature name and a one-line description.
- If the feature name is not kebab-case, suggest a kebab-case version and confirm.

## Step 0: Check preconditions

1. Run `git status --porcelain` to note any pre-existing uncommitted changes (for context only; do not block).
2. Check whether `specs/<feature-name>/` already exists:
   - If it exists and is non-empty, stop and ask the user whether to (a) pick a different name,
     (b) augment the existing spec in place, or (c) abort. Do not overwrite files silently.
   - If it does not exist, create the directory.
3. Decide whether this feature actually warrants a spec. Per CLAUDE.md, SDD is for long-lived
   engineering artifacts (pipelines, CLIs, APIs, shared libraries), **not** experiment scripts,
   notebooks, or one-off analysis. If the feature smells like throwaway research code, say so
   and ask the user to confirm they still want a spec before proceeding.

## Step 1: Scope-gathering interview

Before writing any files, interview the user to collect enough context to draft requirements.
Ask concise, targeted questions in a single message; do not drip-feed one question at a time.
Cover at least:

- **Goal / motivation** — what problem does this feature solve, and for whom?
- **Scope** — what is explicitly in scope; what is explicitly out of scope.
- **Primary users / callers** — humans, other services, CLI users, internal modules, etc.
- **Inputs, outputs, success criteria** — including any performance or quality targets.
- **Known constraints** — existing systems to integrate with, platforms, languages, deadlines.
- **Non-functional requirements** — reliability, observability, security, compliance, UX.
- **Unknowns / risks** — anything the user is unsure about that should go into `research.md`.

Also skim the repo (README, top-level directories, AGENTS.md/CLAUDE.md, any neighboring
specs under `specs/`) to ground the draft in the project's real structure. Do not read deeply
into source — the goal is context, not implementation detail.

If the user's answers are thin, say what's missing before drafting.

## Step 2: Draft `requirements.md`

Create `specs/<feature-name>/requirements.md` with:

1. **Title** — `# Requirements: <Human Readable Feature Name>`
2. **Summary** — 2–5 sentences stating goal, users, and scope.
3. **In scope / Out of scope** — two short bulleted lists.
4. **Requirements** — numbered sections (`## 1. <theme>`), each with sub-numbered EARS
   acceptance criteria (`1.1`, `1.2`, ...). Use the five EARS patterns:
   - `When [event], the [component] shall [action].`
   - `While [condition], the [component] shall [action].`
   - `If [trigger], the [component] shall [action].`
   - `Where [feature is included], the [component] shall [action].`
   - `The [component] shall [action].` (ubiquitous)
5. **Open questions** — bulleted list of things still unresolved that affect requirements.

Rules:

- Use concrete component names (e.g. "the eval harness", "the CLI entry point"), not "the system".
- Each requirement must be testable and describe a single behavior.
- Do not leak implementation details into requirements (WHAT, not HOW).
- Keep IDs dense and consecutive (no gaps, no alphabetic mixing).

After writing, run `npx prettier --write specs/<feature-name>/requirements.md`.

Then **pause**: print the open questions, summarize the requirements, and ask the user to
review before moving on. Do not start `design.md` until the user confirms requirements are
good (or patches them first).

## Step 3: Draft `design.md`

Once requirements are approved, create `specs/<feature-name>/design.md` with sections:

1. **Overview** — one paragraph restating the goal and the shape of the solution.
2. **Architecture** — components and their responsibilities. Use a small component list or
   a simple ASCII/Mermaid diagram if it helps. Make component boundaries explicit — these
   will later map to task boundaries.
3. **Data flow** — how inputs move through components to outputs. Call out async boundaries
   and external I/O.
4. **Data models / interfaces** — concrete type sketches, function signatures, API shapes,
   or schema outlines. No "TBD" on anything that affects a requirement.
5. **Build vs. adopt** — for each major component, state whether it is built from scratch
   or uses an existing library/tool, with a one-line rationale.
6. **Error handling** — how boundary errors (user input, external APIs, I/O) are surfaced.
7. **Observability** — logging, metrics, tracing (only as much as the project actually uses).
8. **Requirements traceability** — a short table mapping each requirement ID from
   `requirements.md` to the component(s)/section(s) in `design.md` that satisfy it. Every
   ID must appear.

Rules:

- No speculative abstractions. Every design element must trace to a requirement.
- Prefer concrete over generic. "A `TokenStore` protocol with `get(key)` / `set(key, value)`"
  beats "some storage layer".
- Respect project language/stack conventions from CLAUDE.md (Python: `uv`, ruff 120, Pyright
  basic, Pydantic/dataclasses split, etc.; shell scripts: 2-space indent, bash shebang; Lua:
  2-space indent, single quotes; etc.).

After writing, run `npx prettier --write specs/<feature-name>/design.md`.

## Step 4: (Optional) Draft `research.md`

Create `specs/<feature-name>/research.md` **only if** at least one of the following is true:

- The design rejected non-trivial alternatives that someone might reasonably reconsider later.
- There are load-bearing trade-offs (performance vs. simplicity, build vs. buy) worth recording.
- ML-style architecture choices where "why not X" matters.
- Constraints or risks surfaced during design that do not belong in `requirements.md`.

If none apply, skip this file — do not create an empty stub.

When creating it, use sections:

- **Rejected alternatives** — bullet list, each with `Option`, `Why considered`, `Why rejected`.
- **Trade-offs** — explicit "we chose X over Y because Z" entries.
- **Constraints / risks** — things that shaped the design or that future readers need to know.

Format with `npx prettier --write` after writing.

## Step 5: Run `/spec-review`

Before drafting `tasks.md`, instruct the user (or invoke via the Skill tool if available) to
run `/spec-review <feature-name>`. Do not silently skip this step — the review catches
traceability gaps, EARS violations, and architecture "TBD"s that would poison the task list.

If the review returns **NEEDS REVISION**, fix the cited issues in `requirements.md` /
`design.md` / `research.md` and re-run it. Only proceed to `tasks.md` once the verdict is
**READY** (all pass, or only warns that the user accepts).

## Step 6: Draft `tasks.md`

Generate `specs/<feature-name>/tasks.md` from the approved requirements + design. Follow the
exact structure from CLAUDE.md:

1. **Task Summary table** — columns: `#`, `Task` (markdown link to detailed section by
   standard heading slug), `Status` (`Pending` / `Done` / `Blocked`), `Depends on`.
   Never use HTML anchors. Never use strikethrough on task names.
2. **Suggested Resolution Order** — numbered list of task IDs with brief rationale
   (dependencies first, quick wins, then larger efforts).
3. **Detailed Tasks** — one `###` heading per task with:
   - A short description and any sub-bullets of what the task covers.
   - Acceptance criteria as a checkbox list.
   - `_Requirements: 1.1, 2.3_` line at the end (must reference IDs from `requirements.md`).
   - `(P)` marker at the start of the description for tasks with no dependency on the
     immediately preceding task, paired with a `_Boundary: <ComponentName>_` line.
   - `Depends on` column in the summary table matches the actual prerequisite task IDs.

Ordering guideline: Foundation -> Core -> Integration -> Validation.

Sizing guideline: each task should be 1–3 hours of focused work. If a task is bigger,
split it. If it is trivially small, merge it.

Traceability requirement: every requirement ID from `requirements.md` must appear in at
least one task's `_Requirements:_` line. Before finishing, cross-check this and report any
orphaned requirements.

Format with `npx prettier --write specs/<feature-name>/tasks.md`.

## Step 7: Wrap up

Print a short summary:

- Files created (with paths).
- Requirement count, task count, and how many tasks are marked `(P)`.
- Any open questions still unresolved in `requirements.md`.
- Next step: suggest `/spec-review <feature-name>` if it was skipped, otherwise
  `/spec-implement <feature-name>` once the user is ready to start building.

Do **not** commit the spec files automatically. Tell the user the files are ready to stage
and commit, and offer the `/commit` skill if they want help with the commit message.

## Critical constraints

- **Stage-by-stage, not all at once.** Always pause after requirements, after design, and
  before tasks so the user can review. Do not generate the whole spec in one shot.
- **No implementation.** This skill never edits source code, only files under
  `specs/<feature-name>/`.
- **No overwriting.** If a spec file already exists, diff against the current content and
  ask before overwriting. Augment in place where possible.
- **No empty files.** Skip `research.md` entirely when it has nothing meaningful to say.
- **EARS discipline.** Every acceptance criterion in `requirements.md` must match one of the
  five EARS patterns.
- **Traceability discipline.** Every requirement ID must map to at least one design section
  and at least one task.
- **ASCII only.** Follow the project rule against Unicode symbols in code and comments;
  plain prose in markdown is fine, but keep diagrams, math, and inline code ASCII.
- **Prettier pass.** Run `npx prettier --write` on every markdown file you create or modify
  before considering the stage done.
- **No issue IDs.** Never include `#N` references anywhere — they will auto-close GitLab
  issues if this lands in a commit message.
