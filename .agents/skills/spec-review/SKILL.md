---
name: spec-review
description: Adversarially test a design spec's soundness -- is the problem real, the reasoning valid, and the proposed solution correct -- before implementation begins
argument-hint: "<feature-name>"
---

Review the design spec for feature `$ARGUMENTS` before implementation begins.

**The goal is to adversarially test the proposal, not to grade its grammar.** Assume the
spec is wrong somewhere and go find it. Interrogate three things, in this order of priority:

1. **Nature** -- is the problem real and worth solving? Are these the right requirements?
2. **Reason** -- does the justification hold? Are the design decisions actually motivated?
3. **Proposed solution** -- does the design correctly and completely solve the problem,
   and will it survive contact with reality?

Format (EARS grammar, ID numbering, table layout, parallel markers) is a distant last
priority and gets exactly one sentence at the end -- see **Format check**.

**Determine scope:**

- The spec lives at `specs/$ARGUMENTS/`.
- If the directory does not exist, list available specs under `specs/` and ask the user which one to review.

**Read all spec files** in the directory (`requirements.md`, `design.md`, `tasks.md`, `research.md` if present) before starting the review.

Where the design makes a factual claim about the codebase (a module exists, an interface
has this shape, a library does X), **verify it against the actual code** rather than trusting
the spec. A design built on a wrong assumption about what already exists is unsound no matter
how well-written.

## Review

Work through each section below. For every finding, assign a verdict:

- **PASS** -- holds up under scrutiny.
- **WARN** -- non-blocking concern, weak justification, or unvalidated assumption worth noting.
- **FAIL** -- the proposal is unsound or not ready; must fix before implementation.

Cite specific evidence (requirement IDs, section names, line references, or the code you
checked) for every WARN and FAIL.

### 1. Problem and requirements (nature + reason)

- Is the problem real, and is solving it worth the work proposed? Flag requirements that
  solve a non-problem or gold-plate a minor one.
- Are these the **right** requirements? Hunt for ones that are missing (an obvious case the
  spec doesn't handle), contradictory (two requirements that can't both hold), or
  over-specified (a requirement that dictates HOW and so forecloses better designs).
- Is each requirement testable in a way that would actually catch a violation -- or is it so
  vague ("the system shall be fast") that any implementation trivially "passes"?
- Any requirement still undecided? Grep `requirements.md` and `design.md` for
  `[NEEDS CLARIFICATION:`. An open marker means the proposal isn't finished -- **FAIL** until
  it is resolved with a concrete answer or the surrounding scope is explicitly cut. Cite each.

### 2. Design soundness (proposed solution)

This is the heart of the review. For the design:

- **Trace a concrete end-to-end scenario** through the design (a real input, a real failure,
  a real concurrent case). Does it actually hold together, or does it break at a seam the
  spec glosses over?
- **Find the gaps:** does every requirement have a real mechanism that satisfies it, or are
  some only gestured at ("the service will handle this")? A requirement with no concrete
  design element behind it is a **FAIL**, not a bookkeeping nit.
- **Name the riskiest assumption** the design rests on, and judge whether it's validated. If
  the whole approach collapses when that assumption is false, say so.
- **Predict the most likely failure mode.** Where will this break first in production --
  scale, partial failure, bad input, an interface that doesn't behave as assumed?
- Error handling at external boundaries (user input, APIs, I/O): defined, or hand-waved?

### 3. Approach and alternatives (adversarial)

- Is this the right approach, or is there a **simpler one** that the spec dismissed without
  reason (or never considered)? Premature complexity is a real finding.
- Build-vs-adopt: for each major component, is the choice to build (or to pull in a
  dependency) actually justified, or arbitrary?
- Speculative abstractions: does everything in the design serve a stated requirement, or is
  there generalization for a future that may never come?
- Architecture integrity: is the dependency direction sane (no circular deps), and are
  component boundaries real seams rather than arbitrary splits?

### 4. Research quality (if research.md exists)

- Are rejected alternatives documented with rationale that actually withstands scrutiny, or
  is it a post-hoc rationalization of a decision already made?
- Are the key constraints and risks the *real* ones, or convenient ones?
- Are trade-offs honest ("we chose X over Y because Z, and we accept cost W"), not just "we chose X"?

### 5. Readiness to implement

- Can the design be decomposed into bounded, independently verifiable tasks (~1-3 hours
  each)? If not, the spec isn't ready regardless of how sound the idea is.
- Are parallel-safe boundaries identifiable -- can you tell which tasks won't collide?

## Format check

After the content review, emit **one sentence** that flags only format issues that actually
break something: a task that cites a requirement ID which doesn't exist, a design element
referencing a missing requirement, duplicate numeric IDs that break traceability, or an EARS
criterion so malformed it isn't testable. If there are none, say "Format: clean." Do **not**
itemize cosmetic issues (parallel-marker style, heading wording, table layout) -- they are
out of scope for this review.

## Output format

1. **Summary verdict**: READY (all pass, or only warns) / NEEDS REVISION (any fails).
2. **Fails to fix**: each FAIL with a specific, actionable suggestion -- and for design
   fails, the scenario or assumption that exposes the flaw.
3. **Warns to consider**: each WARN briefly.
4. **Format**: the single sentence from **Format check**.

Be direct and specific. Lead with the substantive risks to the idea. Do not pad with praise
or filler, and do not let a clean format buy a passing verdict for an unsound design.
