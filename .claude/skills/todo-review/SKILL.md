---
name: todo-review
description: Adversarially test a TODO file's items -- is each problem real, the reasoning valid, and the proposed fix correct -- before implementation begins
argument-hint: "[area or path]"
---

Review a TODO file before running `/todo-implement` against it. This is a **read-only**
audit -- it does not edit the file. If it finds problems, the fix is either a manual edit or
a follow-up pass with your own judgement (no separate revise command exists).

**The goal is to adversarially test the items, not to police the table's formatting.** For
each item, assume it might be stale, mis-reasoned, or wrongly scoped, and go check. Interrogate
three things, in this order of priority:

1. **Nature** -- is this a real, still-open problem worth doing? Or already fixed / imaginary / not worth it?
2. **Reason** -- does the stated "why" hold up, or does it rest on a false assumption?
3. **Proposed solution** -- does the described fix actually solve the problem, or treat a symptom?

Format (table columns, anchor syntax, bullets-vs-numbers, sort order) is a distant last
priority and gets exactly one sentence at the end -- see **Format check**.

## Determine scope

Parse `$ARGUMENTS`:

- If a path is provided (e.g. `todos/solver.md`), review that file.
- If an area name is provided (e.g. `solver`), review `todos/<name>.md`.
- If no argument is provided, **auto-resolve to the most recently modified file under
  `todos/`** (e.g. `ls -1t todos/*.md | head -n 1`). Announce the resolved area on a single
  line so the user can interject if they meant a different one. If `todos/` has no files,
  stop and report.

If the resolved file does not exist, stop and report.

**Read the target file in full** before starting the review. Also note any pre-existing
uncommitted changes via `git status --porcelain` and skim `git log --oneline -20` -- recent
work may have already resolved an item that is still marked `Pending`.

## Review

Work through each section below. For every finding, assign a verdict:

- **PASS** -- holds up under scrutiny.
- **WARN** -- non-blocking concern: likely stale, weak reasoning, mis-prioritized, or a
  symptom-level fix.
- **FAIL** -- the item is unsound or unactionable as written; must fix before implementation.

Cite specific evidence (item number, line reference, file path, commit, or the code you
checked) for every WARN and FAIL.

### 1. Is the problem real and still open? (nature)

For each `Pending` item, actively try to prove it shouldn't be done:

- If it cites a file/line for a `TODO`/`FIXME`/`HACK`/`XXX` marker, grep that file. If the
  marker is gone, the item is likely already resolved -- **WARN** with the evidence.
- If it describes a bug or missing feature concretely enough to spot-check, read the relevant
  code and judge whether the symptom is already gone. Looks-fixed items are **WARN** (they
  may be intentional follow-ups, so not FAIL).
- If a recent commit looks like it closed the item, **WARN** with the commit.
- Is the problem actually worth solving, or is it speculative / cosmetic churn dressed up as
  a task? Say so.

### 2. Does the reasoning hold? (reason)

- Examine the stated "why". Does the justification rest on a true premise, or on an
  assumption about the code/system that you can check and that turns out false?
- Does the item correctly diagnose the cause, or blame the wrong thing? An item whose
  premise is wrong will produce a wrong fix -- flag the premise, not just the fix.

### 3. Is the proposed fix correct? (proposed solution)

- Does the described change actually solve the stated problem, or only paper over a symptom
  while the root cause remains?
- Is there a simpler or more correct fix the item overlooks? Premature or over-scoped fixes
  are real findings.
- Would the proposed fix introduce a worse problem (regression, broken invariant, new edge
  case)? If so, that's a **FAIL** until reconsidered.
- Is the item actionable -- concrete enough (description or acceptance criteria) that an
  implementer knows what "done" means? Vague items that can't be verified are **FAIL**.

### 4. Priority honesty

- Is each `P0`/`P1`/`P2` justified by actual impact and urgency, or mis-ranked? A "P0" that
  has sat untouched while real work happened elsewhere is probably not P0 -- **WARN**.
- Conversely, flag a buried `P2` that the evidence suggests is actually urgent.

### 5. Completeness

- Given the area and what you saw in the code and recent git history, is something obviously
  missing that should be tracked here? A review that only checks the items present misses
  the gap. Note candidate items the file should probably contain.

### 6. Dependency reality

- For every "X is a prerequisite for Y" claim, check it's a **real** technical dependency,
  not just an asserted ordering. A fabricated dependency distorts the resolution order.
- If `X` blocks `Y` and `X` is `Blocked`, then `Y` is effectively blocked too -- flag if the
  file doesn't acknowledge it.

## Format check

After the content review, emit **one sentence** that flags only format issues that actually
break the file's usability: a Priority Summary link whose anchor doesn't resolve to a real
`### N. <title>` heading (broken navigation), a missing or malformed Priority Summary table
(unparseable), or a `Blocked` item with no `_Blocked: {reason}_` line (the blocker can't be
recovered). If there are none, say "Format: clean." Do **not** itemize cosmetic issues
(bullets vs. numbers, strikethrough, HTML anchors, row sort order) -- they are out of scope
for this review.

## Output format

1. **Summary verdict**: READY (all pass, or only warns) / NEEDS REVISION (any fails).
2. **Fails to fix**: each FAIL with a specific, actionable suggestion -- and for content
   fails, the evidence (file/line/commit) that exposes the flaw.
3. **Warns to consider**: each WARN briefly.
4. **Missing items**: candidate items the file probably should contain (from section 5), if any.
5. **Format**: the single sentence from **Format check**.

Be direct and specific. Lead with the substantive risks to the items. Do not pad with praise
or filler, do not edit the TODO file, and do not let a clean table buy a passing verdict for
a stale or mis-reasoned item.
