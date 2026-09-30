# AI Tools TODOs

## Priority Summary

| Task                                                    | Priority | Status  |
| ------------------------------------------------------- | -------- | ------- |
| [#1](#1-add-a-block-choice-to-implement-step-2)         | P2       | Pending |
| [#2](#2-make-implement-file-new-items-in-todo-format)   | P2       | Pending |
| [#3](#3-live-test-the-implement-repair-and-block-paths) | P2       | Pending |
| [#4](#4-sync-the-codex-implement-mirror)                | P2       | Pending |

## Suggested resolution order

- #1 -- one sentence in `SKILL.md`; do it when an orchestrator next improvises a Block
- #2 -- one sentence in `SKILL.md`; do it when an invalid priority next shows up
- #3 -- needs a purpose-built playground unit, independent of #1 and #2
- #4 -- after #1 and #2, so the mirror picks up their changes in one pass

## Detailed sections

### 1. Add a Block choice to implement Step 2

Step 2 of `.claude/skills/implement/SKILL.md` sends a read-only agent to check that each queued unit is still real.
For a unit that looks resolved, it offers three choices: skip, queue anyway, or mark Done. It has no choice for a unit
whose premise is false.

Seen in a playground run: a TODO item told the implementer to wire in `textkit.config.load_settings()`, which does not
exist, and forbade new modules. The check found this, and the orchestrator improvised "Block both" for that item and
the item that depended on it. That was the right call, but the skill does not say it.

Acceptance criteria:

- [ ] Step 2 offers Block for a unit whose premise is false: set Status to `Blocked`, append `_Blocked: <reason>_`,
      and block the queued units that depend on it.
- [ ] The edit is left uncommitted like the other Step 2 edits, so the next landed commit carries it.

### 2. Make implement file new items in TODO format

Step 4 of `.claude/skills/implement/SKILL.md` says to file trackable concerns as new items in todo mode, but it does
not point at the format. In a playground run, the orchestrator filed a follow-up at priority `P3`. The TODO format in
`.claude/skills/todo-init/SKILL.md` allows only `P0`, `P1`, and `P2`.

Acceptance criteria:

- [ ] Step 4 says new items follow the `todo-init` format, with priority `P0` to `P2`.

### 3. Live-test the implement repair and block paths

Three playground runs have never exercised two paths of `.claude/workflows/implement-units.js`, the saved workflow
behind `/implement`. The fake-agent simulation covers both, but no live run has.

- **Repair round:** every verifier passed on the first try. The implementer even handled a planted exact-fit trap in a
  `slugify` max-length criterion.
- **Blocked unit and dependency skip:** the Step 2 check catches a false premise before the workflow starts, so an
  implementer never reports `BLOCKED` and the script never skips a dependent unit.

Both need units whose problem the Step 2 read-only check cannot see. For repair, use a criterion that only fails when
the tests run, with no example the implementer is likely to copy into a test. For block, use a premise that looks
valid on a read but fails during implementation, such as a real function whose behavior contradicts the item.

Acceptance criteria:

- [ ] A live run shows a verifier fail, an Opus repair round, and a second verify.
- [ ] A live run shows an implementer report `BLOCKED` and the script skip a unit that depends on it.

### 4. Sync the Codex implement mirror

`.agents/skills/implement/SKILL.md` mirrors the Claude skill for Codex, but it was left behind on purpose while the
Claude side changed. It lacks the "mark Done as already fixed" choice in Step 2, and the rule that the unit text must
never tell the implementer to edit the artifact or commit. It needs #1 and #2 as well once they land. The saved
workflow does not apply, because Codex has no workflow tool and runs the loop by hand.

Acceptance criteria:

- [ ] `diff .claude/skills/implement/SKILL.md .agents/skills/implement/SKILL.md` shows only harness differences.
