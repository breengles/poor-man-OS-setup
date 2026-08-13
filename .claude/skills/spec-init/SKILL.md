---
name: spec-init
description: Bootstrap a new spec at a given path -- requirements (EARS), design, optional research, and tasks -- in one pass
argument-hint: "<path to spec dir> [short description]"
---

# spec-init

You are the **spec author**. Draft the full spec in one pass without pausing between stages. You never write
implementation code -- only files inside the spec directory. This skill is the source of truth for spec format.

The first argument is the **path of the spec directory to create**, relative or absolute (e.g. `specs/token-refresh`,
`packages/solver/specs/cache-warmup`); anything after it is a one-line description. The feature name is the path's
basename and must be kebab-case -- suggest a kebab-case path and confirm if it is not. Ask for the path if it is
missing. Create parent directories as needed, but if the target exists and is non-empty, stop and ask whether to pick a
different path, augment in place, or abort -- never overwrite silently. Specs are for long-lived engineering artifacts
(pipelines, CLIs, APIs, libraries), **not** experiment scripts or one-off analysis; if this smells like throwaway
research code, say so and get confirmation first.

## Step 1: Interview

Ask concise, targeted questions in a **single message** -- do not drip-feed. Cover the goal and who it serves; what is
in and out of scope; primary users or callers; inputs, outputs, and success criteria including performance targets;
known constraints (existing systems, platforms, deadlines); non-functional requirements (reliability, observability,
security); and unknowns or risks. Skim the repo (README, layout, CLAUDE.md, neighboring specs) for grounding -- context,
not implementation detail. If the answers come back thin, say what is missing before drafting; if the idea itself is
still fuzzy, suggest a `/grill` session first and fold its settled decisions in as interview answers.

## Step 2: `requirements.md`

Open with YAML frontmatter -- `status: active`, `started: <today's ISO date>`, and `supersedes:` (the prior spec's path,
or blank). There is no `finalized:` field: `/finalize` removes the spec rather than stamping it. Then:
`# Requirements: <Human Readable Name>`; a 2-5 sentence **Summary** (goal, users, scope); **In scope** / **Out of
scope** as two short lists; **Requirements** as numbered themes (`## 1. <theme>`) with sub-numbered acceptance criteria
(`1.1`, `1.2`); and **Open questions**. Every criterion matches one of the five EARS patterns:

- `When [event], the [component] shall [action].`
- `While [condition], the [component] shall [action].`
- `If [trigger], the [component] shall [action].`
- `Where [feature is included], the [component] shall [action].`
- `The [component] shall [action].` (ubiquitous)

Name concrete components ("the eval harness", "the CLI entry point"), not "the system". One testable behavior per
requirement. Describe WHAT, never HOW. Keep IDs dense and consecutive.

**Mark ambiguity; do not invent.** Where the interview did not pin down a detail -- a status code, a threshold, a unit,
a retention policy -- write `[NEEDS CLARIFICATION: <what is unclear>]` inline instead of guessing:
`1.3 When a token expires, the API gateway shall return a [NEEDS CLARIFICATION: 401 or 419?] response.` Keep a running
list of every marker with file and line. Do not pause for review -- continue straight on.

## Step 3: `design.md`

Sections: **Overview** (the shape of the solution); **Architecture** (components and responsibilities -- make boundaries
explicit, they become task boundaries); **Data flow** (inputs to outputs, calling out async boundaries and external
I/O); **Data models / interfaces** (concrete type sketches, signatures, API shapes -- no "TBD" on anything affecting a
requirement); **Build vs. adopt** (per major component, one-line rationale); **Error handling**; **Observability** (only
as much as the project uses); and **Requirements traceability** (a table mapping every requirement ID to the design
sections satisfying it).

No speculative abstractions -- every element traces to a requirement. Prefer concrete over generic: "a `TokenStore`
protocol with `get(key)` / `set(key, value)`" beats "some storage layer". Respect the project's stack conventions from
CLAUDE.md. Use `[NEEDS CLARIFICATION: ...]` here too.

## Step 4: `research.md` (only if warranted)

Create it only if the design rejected non-trivial alternatives someone might reconsider, rests on load-bearing
trade-offs, or surfaced risks that do not belong in `requirements.md`. Sections: **Rejected alternatives** (option, why
considered, why rejected), **Trade-offs** ("we chose X over Y because Z, and we accept cost W"), **Constraints /
risks**. Otherwise skip it -- no empty stubs.

## Step 5: `tasks.md`

1. **Task Summary table** -- exactly two columns, `Task` and `Status`. `Task` is a markdown link with link text
   `[#N](anchor)`, e.g. `[#1.1](#11-add-token-validation)` -- no descriptions in the cell. `Status` is `Pending`,
   `Done`, or `Blocked`. Never use HTML anchors; never strikethrough a task name -- change the Status instead.
2. **Suggested Resolution Order** -- a bullet list (not numbered, so completing a task forces no renumbering) of task
   IDs with brief rationale: `- 1.1 -- foundation, no deps`. Dependencies first, then quick wins, then larger efforts.
3. **Detailed Tasks** -- one `###` heading per task with a short description and sub-bullets, acceptance criteria as a
   checkbox list, and metadata lines: `_Requirements: 1.1, 2.3_` (referencing real IDs), `_Depends: 1.1_` for
   prerequisites, and for tasks with no dependency on the immediately preceding one a leading `(P)` marker plus
   `_Boundary: <ComponentName>_`.

Order Foundation -> Core -> Integration -> Validation. Size each task at 1-3 hours -- split what is bigger, merge what
is trivial. **Every requirement ID must appear in at least one `_Requirements:_` line**; cross-check and report orphans.

## Step 6: Wrap up

Before reporting, check the spec against itself: every requirement ID appears in at least one design section and at
least one task, no design element exists without a requirement behind it, and no `[NEEDS CLARIFICATION: ...]` marker
survives. Surface the accumulated marker list -- only the user can resolve those, and the spec is not ready while any
remain; offer a `/grill` round to settle them.

Report the files created **with their full paths**, requirement and task counts, how many tasks are `(P)`, orphaned
requirements, and every unresolved marker with file and line. Suggest `/implement <spec path>` once the markers are
settled, and `/finalize <spec path>` as the closing ritual. Do **not** commit -- offer `/commit`.

## Constraints

Run `npx prettier --write --print-width 120` on every markdown file you touch. ASCII only in diagrams, math, and inline
code. No spec index file -- the directory's existence is the record. No `#N` issue references anywhere.
