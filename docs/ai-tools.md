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

Context length is the one value that needs care. Ollama serves `OLLAMA_CONTEXT_LENGTH` tokens and silently truncates
anything past it, so a larger window declared in `models.json` would quietly drop the head of the conversation instead
of erroring. `env_vars.sh` pins `OLLAMA_CONTEXT_LENGTH=262144` and `pi_sync_models` caps each declared `contextWindow`
at that value, so the client and the server always agree. Raising the variable costs KV-cache memory per loaded model.

The rest of the serving settings live next to it in `env_vars.sh`, tuned for one interactive agent rather than for
throughput:

| Variable                   | Value  | Why                                                                   |
| -------------------------- | ------ | --------------------------------------------------------------------- |
| `OLLAMA_FLASH_ATTENTION`   | `1`    | Cuts attention memory; also the prerequisite for a quantized KV cache |
| `OLLAMA_KV_CACHE_TYPE`     | `q8_0` | Halves the KV cache, which dominates memory at a 256K window          |
| `OLLAMA_NUM_PARALLEL`      | `1`    | One request at a time, so a single agent gets the whole window        |
| `OLLAMA_MAX_LOADED_MODELS` | `1`    | One resident model; a second eviction candidate just thrashes         |
| `OLLAMA_KEEP_ALIVE`        | `30m`  | Avoids reloading tens of GB between turns of the same session         |

`q8_0` without flash attention is silently ignored, so those two go together. The macOS Ollama app picks these up from
the login shell environment; confirm what the running server actually got with
`grep -m1 'server config' ~/.ollama/logs/server.log`.

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
