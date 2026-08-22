# AI Tools Configuration

## Overview

The repository configures **Claude Code** (Anthropic's CLI agent) as the primary AI coding assistant, using
Claude Opus 4.6 as the primary model, and **pi** (`@earendil-works/pi-coding-agent`) as a second harness that
runs local models served by ollama. pi reuses Claude Code's skills and its `implementer` agent rather than
keeping a parallel copy of them.

## File Structure

| File                        | Description                                                    |
| --------------------------- | -------------------------------------------------------------- |
| `CLAUDE.md` (repo root)     | Project-level instructions for Claude Code                     |
| `.claude/CLAUDE.md`         | Claude Code user-level preferences (stow → `~/.claude/`)       |
| `.claude/skills/*/SKILL.md` | Claude Code custom slash commands (stow → `~/.claude/skills/`) |

Note: `~/.claude/settings.json` (MCP servers, hooks, plugins, permissions) is managed by Claude Code itself and not stow-managed.

## Configuration

Claude Code reads instructions from multiple sources:

- **Project-level:** `CLAUDE.md` in the repo root (structure, code style, git conventions)
- **User-level preferences:** `.claude/CLAUDE.md` (stow-managed to `~/.claude/CLAUDE.md`)
- **User-level skills:** `.claude/skills/*/SKILL.md` (stow-managed to `~/.claude/skills/`)
- **Settings:** `~/.claude/settings.json` (managed by Claude Code — MCP servers, hooks, plugins, permissions)

## User-Level Preferences (`.claude/CLAUDE.md`)

Cross-project preferences that apply in every Claude Code session:

- **Python**: Always use `uv` (never pip/conda/poetry)
- **Markdown**: Format with `npx prettier --write --print-width 120` after editing
- **Git**: No issue IDs (`#N`) in commit messages
- **GitLab**: Prefer MCP tools, fall back to `glab` CLI
- **TODO files**: Priority table + detailed sections + resolution order

## Slash Commands (Skills)

Custom skills are stow-deployed from `.claude/skills/` to `~/.claude/skills/`:

| Command           | Description                                                            |
| ----------------- | ---------------------------------------------------------------------- |
| `/commit`         | Analyze changes, create well-formatted Conventional Commits            |
| `/todo-init`      | Scan project and create initial TODO files by area                     |
| `/todo-review`    | Read-only validation of a TODO file before `/todo-implement`           |
| `/todo-implement` | Implement TODO items via implementer/reviewer subagents (orchestrator) |
| `/docs-init`      | Generate comprehensive technical documentation                         |
| `/docs-revise`    | Update existing documentation to match codebase changes                |

### `/commit` Details

The commit command enforces:

- Conventional Commits format
- Max 72-char subject lines
- Semantic commit splitting (separate logical changes)
- Selective `git add` (no `git add .`)
- No secrets in commits
- No issue IDs in messages
- Shows `git log --oneline --name-only` after committing

### `/todo-init`, `/todo-review`, and `/todo-implement`

TODO files follow a structured format in `todos/<area>.md`:

1. Priority Summary table (P0/P1/P2) with links to detail sections
2. Suggested resolution order (pending items, bullet list)
3. Detailed sections with descriptions and acceptance criteria

`/todo-init` seeds the file from a codebase scan. `/todo-review` validates format,
freshness, and item quality without editing. `/todo-implement` runs items one at a
time through implementer/reviewer subagents; the main session orchestrates and
commits.

### `/docs-init` and `/docs-revise`

Documentation files live in `docs/<component>.md` with a `docs/README.md` index.

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
| `.pi/web-search.json`                 | pi-web-access settings: workflow and summary model              |

Everything else under `.pi/` is runtime state: `auth.json` and `trust.json` hold credentials and trust decisions,
`sessions/` holds transcripts, and `models-store.json` is a fetched catalog. All of it is excluded from both stow and
git, the same way `.codex/` is handled.

### Shared skills and agents

`settings.json` sets `skills: ["~/.claude/skills"]` with `enableSkillCommands: true`, so every skill in
[Slash Commands](#slash-commands-skills) is also a pi command. The skills are written once and both harnesses read the
same files.

`packages: ["npm:pi-subagents"]` supplies the subagent primitive that `/implement` needs, since pi has none built in.
pi's agent frontmatter is close to Claude Code's but not identical: tool names are lowercase (`read`, `write`, `edit`,
`bash`, `grep`, `find`, `ls`) and Claude model aliases do not resolve. Rather than duplicate the contract,
`.pi/agent/agents/implementer.md` carries only the pi frontmatter and tells the child to read
`~/.claude/agents/implementer.md` for the rest. One source of truth, one extra read per dispatch.

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

| Number             | Set in                                                       | Read by                                                    |
| ------------------ | ------------------------------------------------------------ | ---------------------------------------------------------- |
| client declaration | `OLLAMA_CONTEXT_LENGTH` in `env_vars.sh`                     | `pi_sync_models`, which caps every `contextWindow` at it    |
| server window      | `context_length` in `~/Library/Application Support/Ollama/db.sqlite` | the ollama server, which Ollama.app spawns          |

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
| `OLLAMA_NUM_PARALLEL`      | `1`   | One request at a time, so a single agent gets the whole window  |
| `OLLAMA_MAX_LOADED_MODELS` | `1`   | One resident model; a second eviction candidate just thrashes   |
| `OLLAMA_KEEP_ALIVE`        | `10m` | Keeps the weights and the prefix cache alive between turns      |

#### Reading the live configuration back

Every value above is worth verifying rather than assuming, because none of them come from a file in this repo.

| Question                              | Command                                                                       |
| ------------------------------------- | ----------------------------------------------------------------------------- |
| what env the server actually started with | `grep 'server config' ~/.ollama/logs/server.log \| tail -1`               |
| the window and keep-alive a loaded model got | `ollama ps` (`CONTEXT` and `UNTIL` columns)                            |
| the same as JSON                      | `curl -s localhost:11434/api/ps \| jq '.models[]'`                            |
| the window the app will impose next start | `sqlite3 ~/Library/Application\ Support/Ollama/db.sqlite 'select context_length from settings'` |
| a tag's own ceiling, quant and params | `ollama show qwen3.8:27b-mlx`                                                 |
| what the last requests really cost    | `grep -E 'peak memory\|speculative decode\|prefix_cache' ~/.ollama/logs/server.log \| tail -5` |

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

| Prompt |   Prefill | Generation |      Peak |
| -----: | --------: | ---------: | --------: |
|  5 942 |    95 t/s |   18.9 t/s | 20.32 GiB |
| 18 610 |    90 t/s |   18.5 t/s | 22.58 GiB |
| 38 319 |    81 t/s |   13.6 t/s | 25.75 GiB |

Generation is bandwidth-bound, prefill is compute-bound, and prefill is the one that hurts: filling the whole 64K
window takes about a quarter of an hour. Two features make that bearable, and neither has a knob to turn.

- The runner reuses the KV cache of a shared prefix. Repeating a 5 942-token prompt replays it in 0.4s instead of 63s,
  so a long prefix is paid for once for as long as the model stays resident. That is what the 10m keep-alive buys.
- MTP speculative decoding is on by default and picks its own draft depth. The `mtp.*` tensors ship inside the
  `27b-mlx` tag, so no draft model is loaded and no flag turns it on. The server logs `acceptance` and `avg_draft` per
  request; observed acceptance runs 0.63 to 0.87 at a draft depth of 2 to 6.

#### Settings that do nothing on this path

| Setting                     | Verified                                                                     |
| --------------------------- | ---------------------------------------------------------------------------- |
| `OLLAMA_FLASH_ATTENTION`    | The MLX runner ignores it                                                    |
| `OLLAMA_KV_CACHE_TYPE`      | `q8_0` and `f16` give a byte-identical 22.58 GiB peak and the same t/s        |
| `num_batch` request option  | 512 and 2048 both prefill at 90 t/s                                          |

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

| Convention             | Detail                                                     |
| ---------------------- | ---------------------------------------------------------- |
| Python package manager | `uv` exclusively                                           |
| Markdown formatting    | Run `npx prettier --write --print-width 120` after editing |
| Git commit messages    | Conventional Commits, no `#N` references                   |
| GitLab interaction     | Prefer MCP tools, fall back to `glab` CLI                  |
| TODO file format       | Priority table + detailed sections + resolution order      |

## Stow Deployment

Claude Code user-level config is stow-managed from this repo:

```
.claude/CLAUDE.md              → ~/.claude/CLAUDE.md
.claude/skills/commit/         → ~/.claude/skills/commit/
.claude/skills/todo-init/      → ~/.claude/skills/todo-init/
.claude/skills/todo-review/    → ~/.claude/skills/todo-review/
.claude/skills/todo-implement/ → ~/.claude/skills/todo-implement/
.claude/skills/docs-init/      → ~/.claude/skills/docs-init/
.claude/skills/docs-revise/    → ~/.claude/skills/docs-revise/
```

The `.stow-local-ignore` excludes Claude Code's auto-generated project files (`settings*.json`, `plans/`, `todos/`). The `.gitignore` uses `/.claude/*` with explicit un-ignores for `CLAUDE.md` and `skills/`.

`~/.claude/settings.json` is NOT stow-managed — Claude Code writes to it directly (hooks, plugins, MCP servers, permissions).

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
