---
description:
  Adversarial review of a GitLab Merge Request -- raise correctness, edge-case, security, and code-quality issues by
  reading the diff and, where feasible, running the code.
argument-hint: "[<MR URL or IID> | leave empty for current branch]"
---

Review a GitLab Merge Request for correctness, edge cases, potential failures, security, and code quality. Be
adversarial: assume there are bugs and look for them. Code clarity and simplicity matter, but they are not the only
axis -- behavior, edge cases, and runtime correctness matter at least as much.

## Scope

- If `$ARGUMENTS` is empty: review the **current branch** vs the base branch (`main`, fallback `master`).
- If `$ARGUMENTS` is a GitLab MR URL or IID (e.g. `123`, `!123`, or `https://gitlab.example.com/group/proj/-/merge_requests/123`):
  fetch the MR via `glab mr view <iid>` (or the `glab` MCP tools if available) and review the diff between the source
  and target branches. If the MR's source branch is checked out locally, prefer the local checkout so you can run code.

## Workflow

### Step 1 -- Gather context

1. Identify the base branch and merge base:
   ```
   git branch -a | grep -E '(main|master)' | head -1
   git merge-base HEAD <base-branch>
   ```
2. Get commits, changed files, and full diff:
   ```
   git log --oneline <merge-base>..HEAD
   git diff --name-status <merge-base>..HEAD
   git diff <merge-base>..HEAD
   ```
3. For every non-trivial changed file, **read the full current version** -- the diff alone hides surrounding context,
   call sites, and invariants you need to judge correctness.
4. Locate and read **callers and call sites** of changed public functions (`grep -rn`, `rg`) to understand how the
   change ripples through the codebase.
5. If the MR description / commit messages reference issues, tickets, or specs, read those too.

### Step 2 -- Try to run the code

You are not just a code reader -- exercise the code where feasible. Skip a step only when the project genuinely does
not have it (state this explicitly in the output).

- **Build / compile:** run the project's build (`cargo build`, `npm run build`, `go build ./...`, `tsc --noEmit`,
  `uv run python -c "import <pkg>"`, etc.).
- **Type check:** run the project's type checker if separate from the build (`mypy`, `pyright`, `tsc --noEmit`).
- **Lint / format:** run the project's linter and formatter check (`ruff check`, `eslint`, `shellcheck`, `stylua --check`,
  `cargo clippy`, `pre-commit run --files <changed>`).
- **Tests:** run the project's test suite (`pytest`, `npm test`, `cargo test`, `go test ./...`). If only some tests are
  relevant, run those plus a fast smoke subset of the rest. Report failing tests verbatim.
- **Smoke run:** if there is a CLI / script / endpoint affected by the change, actually invoke it with realistic input
  and observe behavior. Capture stdout/stderr.
- **New tests:** if the MR changes behavior but adds no test, note this as a finding. If tests exist, mutate or remove
  one assertion mentally (or actually) and confirm the test would catch the regression.

If a step is impossible (no tests, missing tooling, no executable entry point, sandboxed environment), say so in the
output rather than skipping silently.

### Step 3 -- Analyze

Walk every category below. For each finding, record: **file:line**, severity, what's wrong, why it matters, and a
concrete suggestion.

#### Correctness

- Logic bugs: off-by-one, wrong operator, inverted condition, wrong variable, swapped arguments.
- Control flow: unreachable branches, missing `return`, missing `break`, fallthrough, early-exit before cleanup.
- State / lifecycle: uninitialized fields, double-free / double-close, leaked resources (files, sockets, locks,
  goroutines, tasks).
- Concurrency: data races, missing locks, lock ordering, blocking calls in async code, cancellation not handled.
- API contract: function does not match its docstring / type signature; return type can include values callers don't
  handle.

#### Edge cases (force yourself to enumerate)

Walk inputs and ask: what if the value is...

- empty (`""`, `[]`, `{}`, length 0)
- single-element / boundary length
- `None` / `null` / missing key / unset env var
- very large (memory pressure, integer overflow, recursion depth)
- duplicates / non-unique
- unicode / non-ASCII / RTL / emoji / NUL byte
- negative / zero / `NaN` / `Infinity`
- timezone-naive vs aware datetimes; DST boundaries; epoch 0
- trailing whitespace / leading slash / Windows path separators
- concurrent writers / readers
- partial failure (network drops mid-write, disk full, OOM kill)
- retries: is the operation idempotent?

If the MR adds a function, mentally feed it each applicable shape and note the first one that breaks.

#### Security

- Injection (SQL, shell, LDAP, template, log injection).
- Path traversal, symlink attacks, `..` in untrusted paths.
- Secrets: hardcoded API keys, tokens, passwords; secrets logged; secrets in error messages.
- Auth / authz: missing permission check, IDOR, privilege escalation, predictable IDs.
- Crypto: rolled-your-own crypto, weak hash (MD5/SHA1 for security), missing constant-time compare, ECB mode, weak RNG.
- Deserialization of untrusted input (`pickle`, `yaml.load`, `eval`, `Function(...)`).
- SSRF, open redirect, CORS misconfig, CSRF gaps.
- Dependency / supply chain: unpinned versions, suspicious new dep, vendored binary.

#### Performance and resources

- Hot-path allocations, N+1 queries, unbounded loops, accidental quadratic behavior.
- Large payloads in memory when streaming would do.
- Synchronous I/O on an event loop, blocking the UI thread.
- Caches without size limits or eviction.

#### Tests

- Are tests added for the new behavior? Do they actually fail without the change?
- Are assertions meaningful (no `assert True`, `expect(true).toBe(true)`)?
- Are edge cases covered, or only the happy path?
- Are tests deterministic (no flake from time, randomness, ordering)?

#### Code quality and clarity

- Naming: variables/functions describe intent; abbreviations only where conventional.
- Complexity: control flow is straightforward; no clever tricks where plain code works.
- Abstractions: each one serves a current need; no speculative generalization. Three similar lines beat a premature
  abstraction.
- Dead code, commented-out blocks, leftover debug prints, unused parameters.
- Comments (if any) explain the non-obvious WHY, not the WHAT.
- Error handling: only at real boundaries; no try/except that swallows; no validation for cases that cannot occur.
- Project conventions: matches existing style, file layout, and idioms (read neighboring files to confirm).

#### Compatibility and migration

- Backwards-incompatible API or schema changes -- is there a migration / version bump / deprecation notice?
- Database migrations: reversible? safe under concurrent writes? backfill strategy?
- Config / env var changes: documented? defaulted safely?
- Public surface: are exported names, CLI flags, or HTTP routes broken?

#### Documentation

- README / changelog / inline docs updated where user-visible behavior changed.
- Public API has docstrings / type hints consistent with the change.

### Step 4 -- Output

Use the structured block below. Be direct and specific. Cite **file:line** for every finding. Do not pad with praise.

```
## MR Review

**Scope:** <branch or MR IID/URL>
**Base:** <base branch> @ <merge-base sha>
**Files changed:** <count>
**Verdict:** APPROVE | APPROVE WITH NITS | REQUEST CHANGES | BLOCK

### What I ran
- build: <command> -- PASS / FAIL / N/A (reason)
- typecheck: <command> -- PASS / FAIL / N/A
- lint: <command> -- PASS / FAIL / N/A
- tests: <command> -- PASS / FAIL / N/A (X failed of Y)
- smoke run: <what you invoked> -- <what you observed> / N/A

### Blocking issues
1. **[BLOCKER]** `path/to/file.py:42` -- <one-line problem>
   <2-4 lines: why it matters, repro / edge case that triggers it, concrete fix>

### Issues
1. **[MAJOR]** `path/to/file.py:88` -- <problem> -- <suggestion>
2. **[MINOR]** `path/to/file.py:120` -- <problem> -- <suggestion>

### Nits (non-blocking, style / clarity)
- `path/to/file.py:200` -- <suggestion>

### Edge cases I checked
- empty input -> <result>
- very large input -> <result>
- concurrent access -> <result>
- ... (only list ones actually relevant to the change)

### Tests
- New tests: <count> -- <quality assessment>
- Coverage gaps: <list>

### Summary
<2-3 sentences: what this MR does, what's solid, what most needs fixing>
```

## Severity definitions

- **BLOCKER** -- correctness bug, security hole, data loss, broken build/tests, or breaks production. Must fix before merge.
- **MAJOR** -- real defect or significant code-quality problem that should be fixed before merge but is not catastrophic.
- **MINOR** -- legitimate issue worth fixing but acceptable to defer (e.g. follow-up MR).
- **NIT** -- subjective style / clarity preference. Author may ignore.

## Rules

1. **Read the actual code, not just the diff.** Diffs hide surrounding invariants, callers, and shared state.
2. **Run things.** A review that did not build, typecheck, lint, or test the change is incomplete -- say so explicitly
   if you couldn't.
3. **Cite file:line for every finding.** No vague "consider improving error handling".
4. **No false positives.** If you are unsure something is a bug, mark it as a question, not a blocker. Do not invent
   issues to look thorough.
5. **Match severity honestly.** Do not inflate nits to majors; do not bury blockers in a "minor" list.
6. **Project conventions over personal taste.** Read neighboring files; do not flag a pattern the codebase uses
   consistently.
7. **No filler.** Skip "great job" / "LGTM overall" prefaces. Skip a section entirely if it has no findings rather than
   writing "none".
8. **Ask, don't assume, when intent is unclear.** If the MR description doesn't explain _why_, surface the ambiguity in
   the review rather than guessing and approving.
