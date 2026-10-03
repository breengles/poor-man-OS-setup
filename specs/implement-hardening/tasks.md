# Tasks: Implement Hardening

## Task Summary

| Task                                        | Status  |
| ------------------------------------------- | ------- |
| [#1.1](#11-add-a-block-choice-to-step-2)    | Pending |
| [#2.1](#21-live-test-the-repair-round)      | Pending |
| [#2.2](#22-live-test-the-blocked-unit-path) | Pending |
| [#3.1](#31-sync-the-codex-implement-skill)  | Pending |

## Suggested Resolution Order

- 1.1 -- one sentence in the skill, no deps
- 2.1 -- independent; needs the playground repo
- 2.2 -- independent; needs the playground repo
- 3.1 -- after 1.1, so the mirror picks up the change in one pass

## Detailed Tasks

### 1.1 Add a Block choice to Step 2

Extend the Step 2 paragraph of `.claude/skills/implement/SKILL.md` that handles flagged units.

- Offer Block for a unit whose premise is false.
- Keep the skill under 100 lines.

Acceptance criteria:

- [ ] Step 2 offers Block for a unit whose premise is false.
- [ ] Block sets Status to `Blocked`, appends `_Blocked: <reason>_`, and blocks the queued units that depend on it.
- [ ] The edit is left uncommitted like the other Step 2 edits.

_Requirements: 1.1, 1.2, 1.3_

### 2.1 Live-test the repair round

(P) Run `/implement` by hand in the playground repo on a purpose-built repair unit. This task is a live run, not a code
change, so the user runs it rather than an implementer subagent.

Acceptance criteria:

- [ ] A live run shows a verifier fail, an Opus repair round, and a second verify.

_Requirements: 2.1_ _Boundary: playground repo_

### 2.2 Live-test the blocked-unit path

(P) Run `/implement` by hand in the playground repo on a block unit and a unit that depends on it. This task is a live
run, not a code change, so the user runs it rather than an implementer subagent.

Acceptance criteria:

- [ ] A live run shows an implementer report `BLOCKED` and the workflow skip the unit that depends on it.

_Requirements: 2.2_ _Boundary: playground repo_

### 3.1 Sync the Codex implement skill

Bring `.agents/skills/implement/SKILL.md` in line with the Claude skill.

- Add the "mark Done as already fixed" choice and the Block choice to Step 2.
- Add the rule that the unit text never tells the implementer to edit the artifact or commit.

Acceptance criteria:

- [ ] `diff .claude/skills/implement/SKILL.md .agents/skills/implement/SKILL.md` shows only harness differences.

_Requirements: 3.1_ _Depends: 1.1_
