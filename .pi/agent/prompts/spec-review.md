---
description: Validate a design spec's completeness, EARS compliance, and readiness for implementation
argument-hint: "<feature-name>"
---

Review the design spec for feature `$ARGUMENTS` before implementation begins.

**Determine scope:**

- The spec lives at `specs/$ARGUMENTS/`.
- If the directory does not exist, list available specs under `specs/` and ask the user which one to review.

**Read all spec files** in the directory (`requirements.md`, `design.md`, `tasks.md`, `research.md` if present) before starting the review.

## Review checklist

Work through each section below. For every item, assign a verdict:

- **PASS** -- meets the bar.
- **WARN** -- non-blocking concern worth noting.
- **FAIL** -- must fix before implementation.

Cite specific evidence (requirement IDs, section names, line references) for every WARN and FAIL.

### 1. Requirements coverage

- Every numeric requirement ID from `requirements.md` appears in `design.md` (in component descriptions, data flows, or a traceability section).
- No requirement is only mentioned in passing -- each has a concrete design element (component, interface, data model, or flow) that satisfies it.
- No orphan design elements that don't trace back to any requirement.

### 2. EARS compliance

- All acceptance criteria in `requirements.md` follow EARS patterns (When/While/If/Where/The... shall).
- Each requirement is testable -- you can describe a concrete test for it.
- No implementation details leaked into requirements (requirements say WHAT, not HOW).
- Numeric IDs are consistent (no gaps, no duplicates, no alphabetic mixing).

### 3. Architecture readiness

- Component boundaries are explicit enough to assign as independent tasks.
- Interfaces between components are concrete (not "TBD" or "to be determined").
- Build-vs-adopt decisions are captured (for each major component: build from scratch or use existing library/tool, with brief rationale).
- Dependency direction is clear (which layer imports which; no circular deps).
- File/module structure is specified or inferable from the design.

### 4. Executability

- The design can be decomposed into bounded tasks (1-3 hours each).
- Parallel-safe boundaries are visible -- you can identify which tasks are independent.
- No speculative abstractions (everything in the design serves a stated requirement).
- Error handling strategy is defined for external boundaries (user input, APIs, I/O).

### 5. Task quality (if tasks.md exists)

- Every requirement ID from `requirements.md` is referenced by at least one task (`_Requirements: ..._`).
- Parallel markers `(P)` are used where tasks have no dependency on the preceding task, with `_Boundary:_` annotations confirming non-overlapping scope.
- Tasks are ordered Foundation -> Core -> Integration -> Validation.
- Each task is small enough to verify independently (1-3 hours).

### 6. Research quality (if research.md exists)

- Rejected alternatives are documented with rationale.
- Key constraints and risks are identified.
- Trade-offs are explicit (not just "we chose X" but "we chose X over Y because Z").

## Output format

For each section, list items with their verdict and a one-line note. Then provide:

1. **Summary verdict**: READY (all pass, or only warns) / NEEDS REVISION (any fails).
2. **Fails to fix**: each FAIL with a specific, actionable suggestion.
3. **Warns to consider**: each WARN briefly.

Be direct and specific. Do not pad with praise or filler.
