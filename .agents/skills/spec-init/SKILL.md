---
name: spec-init
description: Bootstrap requirements, design, optional research, and tasks for a long-lived feature at a user-provided spec path.
---

# Spec Init

Treat the first user-provided value as the relative or absolute spec directory
to create; remaining text is a short description. Use the path's kebab-case
basename as the feature name. Ask for the path when missing and confirm a
kebab-case alternative when needed. Create parent directories, but never
overwrite a non-empty target without direction.

Specs are for long-lived pipelines, CLIs, APIs, and shared libraries, not
throwaway experiments. Ask one compact interview covering goal, users, scope,
inputs and outputs, success criteria, constraints, reliability, observability,
security, and known risks. Inspect the owning project, applicable `AGENTS.md`,
and neighboring specs. Then draft the whole spec without pausing between files.

## requirements.md

Add frontmatter with `status: active`, today's ISO date as `started`, and
`supersedes` containing the prior spec path or blank. Include Summary, In scope,
Out of scope, numbered Requirements, and Open questions. Express each testable
criterion in one EARS form: `When`, `While`, `If`, `Where`, or ubiquitous
`The <component> shall`. Describe behavior, not implementation. Use
`[NEEDS CLARIFICATION: ...]` instead of inventing details.

## design.md and research.md

Cover overview, explicit component boundaries, data flow, concrete models and
interfaces, build-versus-adopt choices, error handling, observability, and a
table mapping every requirement ID to design sections. Every design element
must serve a requirement. Add `research.md` only for load-bearing alternatives,
trade-offs, constraints, or risks worth preserving.

## tasks.md

Create a two-column Task Summary table (`Task`, `Status`), a bullet-list
Suggested Resolution Order, and detailed `###` tasks. Task cells are links such
as `[#1.1](#11-title)`. Status is `Pending`, `Done`, or `Blocked`; `Done` is
transient during closeout. Each task includes a short description, checkbox
acceptance criteria, `_Requirements:_`, optional `_Depends:_`, and
`_Boundary:_`. Mark independent work `(P)`. Size tasks for 1-3 hours and order
Foundation -> Core -> Integration -> Validation.

Before reporting, ensure every requirement maps to design and at least one task,
no design element is orphaned, and every clarification marker is listed with
file and line. A spec with unresolved markers is not ready to implement.

Run `npx prettier --write --print-width 120` on every Markdown file touched.
Report full paths, requirement/task counts, parallel-task count, orphans, and
unresolved markers. Suggest `$implement <spec path>` and later
`$finalize <spec path>`; do not commit. Create no spec index and no issue
references.
