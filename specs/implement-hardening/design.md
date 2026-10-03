# Design: Implement Hardening

## Overview

Two documentation edits and two live runs. The Claude implement skill gains a Block choice in Step 2. The Codex skill is
then re-synced in one pass. The live runs use purpose-built playground units whose problem the Step 2 read-only check
cannot see.

## Architecture

- **Claude implement skill** (`.claude/skills/implement/SKILL.md`): owns Step 2 choices. Must stay under 100 lines.
- **Codex implement skill** (`.agents/skills/implement/SKILL.md`): mirrors the Claude skill. Codex has no workflow
  tool, so its Step 3 runs the loop by hand. That difference is harness-specific and stays.
- **Playground repo**: a throwaway project for live `/implement` runs. Location: [NEEDS CLARIFICATION: path of the
  playground repo used for earlier runs].
- **implement-units workflow** (`.claude/workflows/implement-units.js`): exercised, not changed.

## Data flow

Step 2 check -> user choice -> artifact edit, uncommitted -> next landed commit carries it.

Live run: playground spec -> `/implement` -> workflow -> `{done, blocked, concerns, stopped}` -> the run's transcript
shows which path ran.

## Data models / interfaces

Step 2 choices for a unit the check flags:

| Finding          | Choices                       |
| ---------------- | ----------------------------- |
| Looks resolved   | skip, queue anyway, mark Done |
| Premise is false | skip, queue anyway, Block     |

Playground units:

- **Repair unit**: a criterion that fails only when the tests run, with no worked example the implementer is likely to
  copy into a test. A read of the code cannot show the gap.
- **Block unit**: a premise that reads as valid but fails during implementation, such as a real function whose
  behavior contradicts the task. A second unit depends on it.

## Decisions

- Block reuses the existing `Blocked` Status and `_Blocked:_` line. Rejected: a new Status, because `/finalize` and the
  workflow already handle `Blocked`.
- Live runs use real playground units. Rejected: fault injection into the script, because it tests a modified script,
  and the fake-agent simulation already covers the script's logic.
- The Codex sync runs after the Step 2 change. Rejected: syncing first, because the mirror would need a second pass.

## Error handling

If a live run takes the wrong path, for example the verifier passes the repair unit, the unit design is at fault. Adjust
the unit and run again. Do not change the workflow to force a path.

## Requirements traceability

| Requirement   | Design sections                                   |
| ------------- | ------------------------------------------------- |
| 1.1, 1.2, 1.3 | Architecture, Data models / interfaces, Decisions |
| 2.1, 2.2      | Architecture, Data models / interfaces, Decisions |
| 3.1           | Architecture, Decisions                           |
