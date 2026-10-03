---
status: active
started: 2026-10-03
supersedes:
---

# Requirements: Implement Hardening

## Summary

The `/implement` pipeline has three gaps found in playground runs. Step 2 has no choice for a unit whose premise is
false. Two paths of the saved workflow have never run live: the repair round and the blocked-unit skip. The Codex mirror
of the implement skill lags behind the Claude skill. This spec closes all three for the user who runs `/implement` in
Claude Code and in Codex.

## In scope

- A Block choice in Step 2 of the implement skill
- Live runs that exercise the repair round and the blocked-unit path of `implement-units.js`
- Bringing `.agents/skills/implement/SKILL.md` in line with the Claude skill

## Out of scope

- Changes to the logic of `implement-units.js`
- New agent roles or new Status values

## Requirements

## 1. Step 2 premise check

1.1 If the Step 2 read-only check finds that a queued unit's premise is false, the implement skill shall offer Block
next to skip, queue anyway, and mark Done.

1.2 When the user chooses Block in Step 2, the implement skill shall set the unit's Status to `Blocked`, append
`_Blocked: <reason>_` to its section, and block each queued unit that depends on it.

1.3 When the implement skill records a Block in Step 2, the implement skill shall leave the artifact edit uncommitted,
so the next landed commit carries it.

## 2. Live workflow coverage

2.1 When a verifier fails a unit in a live run, the implement-units workflow shall run one Opus repair round and then a
second verify.

2.2 When an implementer reports `BLOCKED` with no changed files in a live run, the implement-units workflow shall record
the unit as blocked and skip each queued unit that depends on it.

## 3. Codex mirror

3.1 The Codex implement skill shall differ from the Claude implement skill only in harness-specific instructions.

## Open questions

- None.
