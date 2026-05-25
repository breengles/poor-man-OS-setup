---
description: Close out a completed spec by flipping its lifecycle frontmatter to `completed`, appending Implementation Notes to `design.md`, and updating `specs/INDEX.md`.
argument-hint: "<feature-name>"
---

# spec-finalize

## Role

You are the **closer**. The implementation phase is over; this skill freezes the spec so
that what shipped becomes legible history. You do NOT write or modify application code in
this skill. You only edit files under `specs/<feature-name>/` and the repo-level
`specs/INDEX.md`.

Once finalized, the spec is **immutable history**. Future related work creates a new spec
that supersedes this one rather than mutating it.

## Parse arguments

- `$ARGUMENTS` should be the kebab-case feature name (matching `specs/<feature-name>/`).
- If no argument is provided, list the active specs under `specs/` (those with
  `status: active` in their `requirements.md` frontmatter) and ask which to finalize.

## Step 0: Read the spec

Read every file under `specs/<feature-name>/` in parallel:

1. `requirements.md` (parse the YAML frontmatter)
2. `design.md`
3. `tasks.md`
4. `research.md` (if it exists)

If `requirements.md` has no frontmatter, fall back to treating `status` as `active`.

## Step 1: Verify readiness

Refuse to finalize if any of the following hold; report the blocker and stop:

1. **Wrong status.** If `status` is already `completed` or `superseded`, say so and stop --
   finalization is a one-way operation. The user can manually edit the frontmatter if they
   need to reopen.
2. **Pending tasks.** Parse the Task Summary table in `tasks.md`. Every row must be `Done`.
   If any row is `Pending`, list them and stop. If any row is `Blocked`, list them and ask
   the user to confirm finalization anyway (a spec can be closed with deliberately blocked
   tasks if those have been descoped -- this requires explicit user approval).
3. **Unresolved markers.** Grep `requirements.md` and `design.md` for
   `[NEEDS CLARIFICATION:`. Any remaining marker blocks finalization. Report the file and
   line for each, stop, and ask the user to resolve them first.

## Step 2: Gather "what shipped" context

Before editing `design.md`, build a concise picture of what was actually delivered. Use
read-only tools only -- do **not** modify application code from this skill.

- Run `git log --oneline -- specs/<feature-name>/ "$(git rev-list --max-parents=0 HEAD)"..HEAD`
  to see commits touching this spec's files. (If the command shape is awkward in the
  shell, fall back to `git log --oneline -- specs/<feature-name>/`.)
- Note any tasks marked `Blocked` -- those are deliberately descoped items.
- Skim the completion notes (`_Done:_` lines) in `tasks.md` for one-liners.

If anything is ambiguous (e.g. a task was marked `Done` with no completion note and an
unclear diff), ask the user one targeted question rather than guessing.

## Step 3: Append Implementation Notes to design.md

Append a new section at the bottom of `design.md`:

```markdown
## Implementation Notes

_Added by `/spec-finalize` on <today's ISO date>._

**Shipped:**

- <one bullet per task that shipped, summarizing the actual behavior delivered>

**Descoped or deferred:**

- <one bullet per Blocked / descoped task, with the reason>
- <or "None." if nothing was descoped>

**Deviations from design:**

- <one bullet per place the implementation diverged from the original design, with reason>
- <or "None." if the implementation matched the design exactly>

**Follow-ups:**

- <one bullet per known follow-up worth tracking elsewhere (link to TODO file or new spec)>
- <or "None." if no follow-ups>
```

Keep each bullet to one line. The goal is a quick legible record, not a postmortem.

## Step 4: Update requirements.md frontmatter

Edit the YAML frontmatter at the top of `requirements.md`:

- Flip `status: active` to `status: completed`.
- Set `finalized: <today's ISO date>`.
- Leave `started`, `supersedes`, and any other fields unchanged.

Do **not** edit the body of `requirements.md`. Requirements are frozen as-shipped.

## Step 5: Update specs/INDEX.md

If `specs/INDEX.md` does not exist, create it with this header:

```markdown
# Specs Index

_One section per spec, ordered with most recently started at the top._
```

Then ensure exactly one section exists for this feature, in the form:

```markdown
## [<feature>](<feature>/)

- **Status:** completed
- **Started:** <started-date> -- **Finalized:** <today's-date>
- <summary>
```

- The summary is a single short sentence -- pull it from the Summary section of
  `requirements.md` if present, or ask the user for one if the existing summary is too long.
- If a section for `<feature>` already exists, update it in place (don't add a duplicate).
- Keep sections roughly ordered by `Started` date (most recent first).

## Step 6: Format and report

1. Run `npx prettier --write --print-width 120` on every file you touched
   (`specs/<feature-name>/requirements.md`, `specs/<feature-name>/design.md`,
   `specs/INDEX.md`).
2. Print a wrap-up summary:
   - Files modified.
   - Tasks shipped, descoped, blocked.
   - The new INDEX section.
   - **Next step:** suggest `git add` + `/commit` with a message like
     `chore(<feature>): finalize spec` -- but do NOT commit automatically. Tell the user
     the changes are staged-ready and offer to invoke `/commit`.

## Critical constraints

- **Read-only on application code.** This skill must not edit any file outside of
  `specs/<feature-name>/` and `specs/INDEX.md`.
- **One-way.** Once a spec is `completed`, treat its files as immutable history. Do not
  invoke `spec-finalize` to "re-finalize" or to update a closed spec. If the user wants
  to amend a closed spec, ask them to revert the frontmatter manually first.
- **No silent edits to requirements.** The body of `requirements.md` and `tasks.md` is
  frozen as-shipped. The only allowed mutation is the frontmatter flip in step 4.
- **No issue IDs.** Never include `#N` references in any text you write (commit messages,
  INDEX sections, Implementation Notes). They would auto-close GitLab issues.
- **No destructive git.** Never `git reset --hard`, `git checkout .`, or similar. This
  skill only edits markdown.
- **Prettier pass.** Every markdown file you create or modify must be formatted with
  `npx prettier --write --print-width 120` before the wrap-up.
