# AI Tools Configuration

## Overview

The repository configures **Claude Code** (Anthropic's CLI agent) as the primary AI coding assistant, and **pi**
(`@earendil-works/pi-coding-agent`) as a second harness that runs local models served by ollama. pi reuses Claude
Code's skills and its `implementer` and `verifier` agents rather than keeping a parallel copy of them.

## File Structure

| File                            | Description                                                             |
| ------------------------------- | ----------------------------------------------------------------------- |
| `CLAUDE.md` (repo root)         | Project-level instructions for Claude Code                              |
| `.claude/CLAUDE.md`             | User-level preferences, loaded in every project                         |
| `.claude/settings.json`         | MCP servers, plugins, permissions, hooks, status line, per-model effort |
| `.claude/keybindings.json`      | Claude Code keybindings                                                 |
| `.claude/statusline-command.sh` | Status line script that `settings.json` runs                            |
| `.claude/skills/*/SKILL.md`     | Custom slash commands                                                   |
| `.claude/workflows/*.js`        | Saved workflows: `implement-units`, the per-unit loop of `/implement`   |
| `.claude/agents/*.md`           | Custom subagents: `implementer` and `verifier`                          |

Claude Code writes to `settings.json` itself, so its edits land in the repo through the symlink and show up in
`git status`. `.claude/skills/synced/` holds claude.ai skills that Claude Code syncs down. It is ignored by both stow
and git.

## User-Level Preferences (`.claude/CLAUDE.md`)

Cross-project preferences that apply in every Claude Code session. The file is kept short, because each skill owns its
own format details.

- **Response style**: lead with the outcome, plain short sentences, Simplified Technical English, no filler
- **Ultracode**: at most 3 Opus or 6 Sonnet subagents in flight
- **Commits**: imperative, lowercase, about 50 characters, no type prefix, no issue IDs
- **Code comments**: never cite specs, TODO items, or line numbers; cite a `docs/` page or state the reason
- **Python**: `uv` for everything, Ruff, Pyright in `basic` mode, modern type syntax, `pathlib`
- **Tests**: add none unless asked, and never weaken existing ones
- **SLURM**: no heavy work on the login node; submit through `sbatch` or `srun`

## Slash Commands (Skills)

| Command           | Description                                                                             |
| ----------------- | --------------------------------------------------------------------------------------- |
| `/spec-init`      | Draft a spec directory in one pass: EARS requirements, design, optional research, tasks |
| `/todo-init`      | Scan the project and seed TODO files by area                                            |
| `/grill`          | Interview the user in rounds until a plan has no open questions                         |
| `/implement`      | Implement spec tasks or TODO items one unit at a time; the main session orchestrates    |
| `/finalize`       | Reconcile the docs with what shipped, remove the resolved artifact, and commit          |
| `/commit`         | Create commits in the repo's message style, staging selectively                         |
| `/mr-description` | Write or apply a GitLab merge request title and description                             |
| `/dataset-readme` | Write an `install.md` for an image dataset                                              |

Code review is deliberately not a custom skill. The built-in `/code-review`, `/security-review`, and `/simplify` cover
it.

### Tracked work: `/spec-init` and `/todo-init` to `/implement` to `/finalize`

Specs and TODO files share one pipeline. The artifact is temporary scaffolding: `/finalize` removes it once the work
ships, and the code plus the docs stay as the record.

- A **spec** is a directory with `requirements.md`, `design.md`, an optional `research.md`, and `tasks.md`. Its units
  are the sub-tasks in `tasks.md`.
- A **TODO file** is `todos/<area>.md`: a Priority Summary table, a suggested resolution order, and one detailed
  section per item. Its units are the items.

`/spec-init` asks its questions in one message. When the idea is still unclear, `/grill` settles it first.

### `/implement`

The main session resolves the artifact, finds the test command, and builds the queue. It sends read-only subagents in
parallel to check that each queued unit is still a real problem. After the user confirms the queue, the main session
hands the loop to the saved workflow `.claude/workflows/implement-units.js`. For each unit, the script does these steps
in order:

1. The `implementer` agent (Sonnet) makes the change.
2. The `verifier` agent (Opus, medium effort, read-only) checks each acceptance criterion against the code and runs the
   tests. It also checks that only the expected files changed. When it is unsure, it fails the unit.
3. If the verifier fails the unit, the implementer gets one repair round with the verifier's gaps, on Opus. The
   verifier then checks again.
4. A landing agent (Sonnet, medium effort) marks the unit `Done` in the artifact, appends the unit's notes, and commits
   the code and the artifact together.

The artifact's `## Notes` section is the run's memory. It holds run-time facts that no other section owns: `env` for
command quirks and failures that existed before the run, `deviation` for code that left the design in a way later units
depend on, and `dead-end` for approaches that failed. Decisions go in the spec files, and progress stays in Status and
`_Done:_` lines. Agents read Notes before they start, and treat entries as hints the code can overrule. They do not edit
Notes. They return notes in their structured output, the script collects them per unit, and the landing agent writes
them only after the verifier passes the unit. So a failed attempt cannot plant an unverified fact. `/finalize` moves
lasting notes into the docs, then removes them with the artifact.

Units run one after another, because they share one working tree. The script stops and returns control to the main
session when a unit needs more context, fails twice, or changes unexpected files. The main session then asks the user.
It reads only the script's return value, so subagent reports do not fill its context on a long run.

Claude Code runs the script by name, `Workflow({name: "implement-units", args})`. A saved workflow in
`~/.claude/workflows/` is available in every project. A `scriptPath` is not: the Workflow tool starts a script only
from a file the session can already read, and `~/.claude/skills/` is outside the working directory in other repos. If
the name does not resolve, the skill reads the file and passes its text inline as `script`. Saving the script also
makes `/implement-units` a slash command, so the script returns an error when it gets no `args.queue`. pi runs the same
file through pi-subagents, see [Shared skills and agents](#shared-skills-and-agents).

### `/commit`

Subjects are imperative and lowercase, about 50 characters, with no `feat:` or `fix:` prefix and no issue IDs. The
skill commits only this session's changes, splits separable changes into separate commits, stages files by name, and
ends with `git log --oneline --name-only`.

## pi (local-model harness)

pi is a second agent CLI, installed from npm as `@earendil-works/pi-coding-agent`. It reads its global configuration
from `~/.pi/agent/`, and this repo owns the hand-authored part of that directory.

| File                                  | Description                                                     |
| ------------------------------------- | --------------------------------------------------------------- |
| `.pi/agent/settings.json`             | Provider, thinking level, skills path, extensions, packages     |
| `.pi/agent/models.json`               | The `ollama` provider and its model list (generated, see below) |
| `.pi/agent/extensions/footer-info.ts` | Footer: cwd, branch, cost, context use, model, t/s, thinking    |
| `.pi/agent/extensions/pi-context.ts`  | `/context` command: inspect the live system prompt              |
| `.pi/agent/agents/implementer.md`     | pi-subagents shim pointing at the Claude `implementer` contract |
| `.pi/agent/agents/verifier.md`        | pi-subagents shim pointing at the Claude `verifier` contract    |
| `.pi/web-search.json`                 | pi-web-access settings: workflow and summary model              |

Everything else under `.pi/` is runtime state: `auth.json` and `trust.json` hold credentials and trust decisions,
`sessions/` holds transcripts, and `models-store.json` is a fetched catalog. All of it is excluded from both stow and
git, the same way `.codex/` is handled.

### Shared skills and agents

`settings.json` sets `skills: ["~/.claude/skills"]` with `enableSkillCommands: true`, so every skill in
[Slash Commands](#slash-commands-skills) is also a pi command. The skills are written once and both harnesses read the
same files.

`packages: ["npm:pi-subagents"]` supplies the subagent primitive that `/implement` needs, since pi has none built in.
`/implement` runs its per-unit loop through pi-subagents' `workflowScript`, using the same
`~/.claude/workflows/implement-units.js` that Claude Code's Workflow tool runs. pi has no script-path parameter
and no `args` global, so the orchestrator sends the text below the script's `// pi:` marker line with
`const args = <JSON>;` prepended.
pi's agent frontmatter is close to Claude Code's but not identical: tool names are lowercase (`read`, `write`, `edit`,
`bash`, `grep`, `find`, `ls`) and Claude model aliases do not resolve. Rather than duplicate the contract,
each shim in `.pi/agent/agents/` carries only the pi frontmatter and tells the child to read the matching
`~/.claude/agents/` file for the rest. One source of truth, one extra read per dispatch.

### Local models via ollama

pi has no ollama discovery. Every local model has to be declared in `models.json` under a provider that speaks
OpenAI Chat Completions:

```json
{
  "providers": {
    "ollama": {
      "baseUrl": "http://127.0.0.1:11434/v1",
      "api": "openai-completions",
      "apiKey": "ollama",
      "compat": { "supportsDeveloperRole": false, "supportsReasoningEffort": false },
      "models": []
    }
  }
}
```

The `apiKey` is a placeholder that ollama ignores, but pi treats every model as needing auth before it appears in
`/model`, so it cannot be omitted. The two `compat` flags are off because ollama's OpenAI shim understands neither the
`developer` role nor `reasoning_effort`.

Run `pi_sync_models` (in `.config/shell/functions.sh`) after every `ollama pull`. It reads `/api/tags` and `/api/show`
and rewrites the provider's `models` array only. It does not touch `defaultModel` or `summaryModel`; those are set by
hand.
Per model it derives the display name from parameter size and quantization, sets `reasoning` from the `thinking`
capability, sets `input` from the `vision` capability, and zeroes the cost fields so the footer reads `$0.00`.
For `gemma4:*` and `qwen3.8:*` models it also pins `samplingParams` to each family's published best practice
(`temperature=1.0`, `top_p=0.95` for both; `top_k=64` for Gemma 4, `top_k=20` for Qwen3.8). The `top_k` is recorded for
documentation only: ollama's OpenAI shim drops it, so the model's baked-in default supplies the actual value. Only
`temperature` and `top_p` are honored through that shim.

`qwen3.8:*` additionally sets `compat.supportsReasoningEffort` and a `thinkingLevelMap` (off/low/medium/high), because
Qwen3.8 exposes `reasoning_effort` and ollama's OpenAI endpoint honors it -- unlike Gemma 4, which gates thinking
behind the `<|think|>` system-prompt token.

Context length is the one value that needs care, and on Apple Silicon it is not set where it looks like it is set.
Ollama truncates anything past the server's window without erroring, so a larger `contextWindow` in `models.json`
would quietly drop the head of the conversation. Two numbers have to agree, and each comes from a different place:

| Number             | Set in                                                               | Read by                                                  |
| ------------------ | -------------------------------------------------------------------- | -------------------------------------------------------- |
| client declaration | `OLLAMA_CONTEXT_LENGTH` in `env_vars.sh`                             | `pi_sync_models`, which caps every `contextWindow` at it |
| server window      | `context_length` in `~/Library/Application Support/Ollama/db.sqlite` | the ollama server, which Ollama.app spawns               |

The app wins on the window. It passes its own `context_length` to the server, overriding `OLLAMA_CONTEXT_LENGTH`, so
that one export only ever configures `pi_sync_models`.

Every other export reaches the server or not depending on how Ollama.app started, because the server is its child and
inherits its environment. Started as a login item, which is the normal case, the app sees the login environment and
none of the `.zshrc` exports, so the server runs on its own defaults: that is how it ended up serving a 5m keep-alive
with flash attention off. Started from a terminal that sourced `env_vars.sh`, the same exports land. Applying an edit
is therefore one restart from a shell:

```bash
pkill -f "Ollama.app/Contents/MacOS/Ollama" && open -a Ollama
```

launchd also caches an environment snapshot per application job, and the snapshot survives an app relaunch. A server
reporting values that no longer exist anywhere on disk means the snapshot is stale; it clears once the app process is
gone, which the `pkill` above takes care of. `launchctl setenv OLLAMA_KEEP_ALIVE 10m` is the other way in, and the only
one that survives a start from the Dock, but launchd forgets it on reboot.

| Variable                   | Value | Why                                                            |
| -------------------------- | ----- | -------------------------------------------------------------- |
| `OLLAMA_NUM_PARALLEL`      | `1`   | One request at a time, so a single agent gets the whole window |
| `OLLAMA_MAX_LOADED_MODELS` | `1`   | One resident model; a second eviction candidate just thrashes  |
| `OLLAMA_KEEP_ALIVE`        | `10m` | Keeps the weights and the prefix cache alive between turns     |

#### Reading the live configuration back

Every value above is worth verifying rather than assuming, because none of them come from a file in this repo.

| Question                                     | Command                                                                                         |
| -------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| what env the server actually started with    | `grep 'server config' ~/.ollama/logs/server.log \| tail -1`                                     |
| the window and keep-alive a loaded model got | `ollama ps` (`CONTEXT` and `UNTIL` columns)                                                     |
| the same as JSON                             | `curl -s localhost:11434/api/ps \| jq '.models[]'`                                              |
| the window the app will impose next start    | `sqlite3 ~/Library/Application\ Support/Ollama/db.sqlite 'select context_length from settings'` |
| a tag's own ceiling, quant and params        | `ollama show qwen3.8:27b-mlx`                                                                   |
| what the last requests really cost           | `grep -E 'peak memory\|speculative decode\|prefix_cache' ~/.ollama/logs/server.log \| tail -5`  |

`ollama ps` is the quickest sanity check: a `CONTEXT` that disagrees with `OLLAMA_CONTEXT_LENGTH` means
`pi_sync_models` is declaring a window the server will silently truncate.

#### What a 36 GiB M3 Pro holds

`qwen3.8:27b-mlx` is a dense 27.8B model with a hybrid attention stack. 48 of its 64 layers use linear attention
(Gated DeltaNet) with a constant recurrent state, and only the other 16 keep a KV cache that grows with the
conversation. Peak memory measured at 6K, 18K and 38K tokens is linear in the window:

```
peak = 19.28 GiB + 176 KB per context token
```

macOS lets Metal wire down about 76% of unified memory, which is 27.6 of 36 GiB, so the window stops fitting near 49K
tokens. The declared 65536 is a deliberate overcommit: past the limit MLX serves the overflow from pageable memory and
generation drops by roughly a third rather than failing, and most sessions never fill the window. `iogpu.wired_limit_mb`
could raise the ceiling, but it is left at the system default so macOS keeps deciding. A 131072-token window would need
41.3 GiB, which this machine does not have at any setting.

#### Measured throughput

| Prompt | Prefill | Generation |      Peak |
| -----: | ------: | ---------: | --------: |
|  5 942 |  95 t/s |   18.9 t/s | 20.32 GiB |
| 18 610 |  90 t/s |   18.5 t/s | 22.58 GiB |
| 38 319 |  81 t/s |   13.6 t/s | 25.75 GiB |

Generation is bandwidth-bound, prefill is compute-bound, and prefill is the one that hurts: filling the whole 64K
window takes about a quarter of an hour. Two features make that bearable, and neither has a knob to turn.

- The runner reuses the KV cache of a shared prefix. Repeating a 5 942-token prompt replays it in 0.4s instead of 63s,
  so a long prefix is paid for once for as long as the model stays resident. That is what the 10m keep-alive buys.
- MTP speculative decoding is on by default and picks its own draft depth. The `mtp.*` tensors ship inside the
  `27b-mlx` tag, so no draft model is loaded and no flag turns it on. The server logs `acceptance` and `avg_draft` per
  request; observed acceptance runs 0.63 to 0.87 at a draft depth of 2 to 6.

#### Settings that do nothing on this path

| Setting                    | Verified                                                               |
| -------------------------- | ---------------------------------------------------------------------- |
| `OLLAMA_FLASH_ATTENTION`   | The MLX runner ignores it                                              |
| `OLLAMA_KV_CACHE_TYPE`     | `q8_0` and `f16` give a byte-identical 22.58 GiB peak and the same t/s |
| `num_batch` request option | 512 and 2048 both prefill at 90 t/s                                    |

All three matter only on the llama.cpp path, which is what a GGUF tag takes. Every MLX tag skips them.

`pi_sync_models` writes through the stow symlinks with `cat >` rather than `mv`, because `mv` would replace the symlink
with a regular file and detach the deployed config from the repo.

### Web access

pi has no web tool of its own. Its built-in tools are `read`, `bash`, `edit`, `write`, `grep`, `find`, and `ls`, so
without a package the only way out to the network is shelling out to `curl`. `packages` therefore includes
[`npm:pi-web-access`](https://pi.dev/packages/pi-web-access), which registers `web_search`, `fetch_content`,
`source_check`, and `get_search_content`. It needs no API key: search falls back to Exa MCP, and page extraction falls
back to a local Readability pass.

Its config is `~/.pi/web-search.json`, and two keys matter here.

`workflow` is `auto-summary`. The default, `summary-review`, opens a curator page in a browser for every search, which
is wrong for a terminal-first setup. `auto-summary` returns a model-written summary inline instead. Set it to `none` to
get raw results with no model call at all.

`summaryModel` must be set by hand. Summarization is a real completion call, and the package's default candidate list
is hosted models (Claude Haiku, then Codex tiers, then DeepSeek V4 Flash), so on a local setup it must be pointed at an
ollama tag. Picking a tag that differs from the session's active model makes ollama evict the resident model and reload
on every search (`OLLAMA_MAX_LOADED_MODELS` is `1`), so either keep it on the active model's tag or use a small
summarizer so the reload stays cheap.

Query rewriting cannot be pinned the same way. Its candidate list is hardcoded to `anthropic/claude-haiku-4-5`,
`google/gemini-3.6-flash`, and `openai/gpt-5-mini`, with no config key. On a local-only setup none of those resolve, so
the rewrite step fails and the raw query is searched as typed. That is a degradation, not a break.

**Never put an API key in `.pi/web-search.json`.** The file is tracked in this repo. pi-web-access reads
`BRAVE_API_KEY`, `EXA_API_KEY`, `GEMINI_API_KEY` and the rest from the environment, and env vars take precedence over
literal values in the file, so keys belong in `.env-global.sh` instead. The package also writes this file itself when
you change the search provider at runtime, so expect it to show up in `git status`.

### Extensions

`footer-info.ts` replaces pi's footer with one line: cwd and git branch on the left, then session cost, context use,
model id with its window, generation speed, and thinking level on the right. Speed is measured per turn from
`message_start` to `message_end`. Tools run between turns, so tool time never enters the denominator and the number
stays pure generation speed, which is the signal that matters when the model is running locally. All fields are
fixed-width so the right block does not jitter between repaints.

`pi-context.ts` adds `/context`, a scrollable pane showing the live system prompt plus the context files, skills, and
options that produced it.

Both are adapted from [JanRocketMan/dotfiles](https://github.com/JanRocketMan/dotfiles). The upstream footer also
resolves jujutsu bookmarks, and the upstream `/context` shipped alongside a Linux sandbox shim; neither applies here.

## Key Conventions

| Convention             | Detail                                                        |
| ---------------------- | ------------------------------------------------------------- |
| Python package manager | `uv` exclusively                                              |
| Markdown formatting    | Skills run `npx prettier --write --print-width 120` on output |
| Git commit messages    | Imperative, lowercase, no type prefix, no `#N` references     |
| Tracked work           | `/spec-init` or `/todo-init`, then `/implement`, `/finalize`  |

## Stow Deployment

Claude Code's user-level config is stow-managed from this repo. `.stowrc` sets `--no-folding`, so stow links each file
separately. Run `stow .` after adding any file:

```
.claude/CLAUDE.md                → ~/.claude/CLAUDE.md
.claude/settings.json            → ~/.claude/settings.json
.claude/keybindings.json         → ~/.claude/keybindings.json
.claude/statusline-command.sh    → ~/.claude/statusline-command.sh
.claude/skills/                  → ~/.claude/skills/
.claude/agents/                  → ~/.claude/agents/
.claude/workflows/               → ~/.claude/workflows/
```

`.stow-local-ignore` and `.gitignore` both exclude the state that Claude Code writes under `~/.claude/`:
`settings.local.json`, `backups/`, `cache/`, `debug/`, `plugins/`, `projects/`, `session-env/`, `shell-snapshots/`,
`todos/`, `history.jsonl`, and `skills/synced/`. Stow also skips `plans/`.

Links made before `.stowrc` existed can still be whole-directory links. On the original Mac, `~/.claude/skills/`,
`~/.claude/agents/`, and `~/.agents/skills/` are directory links, so new files there show up at once. A fresh machine
gets per-file links.

## Dependencies

- **Claude Code** (`claude` CLI)
- **pi** (`pi` CLI, npm `@earendil-works/pi-coding-agent`) plus the `pi-subagents` and `pi-web-access` packages
- **glab** CLI (for GitLab MCP server)
- **ollama** and **jq** (for the pi local-model provider and `pi_sync_models`)
- Anthropic API key (for Claude models)

## Relationship to Other Components

- **Git** conventions are enforced by the `/commit` workflow
- **Shell** `$AGENT`/`$CLAUDECODE` variables disable eza/bat aliases when agents run shell commands
- **tmux** propagates `$AGENT` to nested sessions
- **GitLab** MCP server provides issue/MR management inside the agent
