# AI Tools Configuration

## Overview

The repository configures **Claude Code** (Anthropic's CLI agent) as the AI coding assistant, using Claude Opus 4.6 as the primary model.

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
- **glab** CLI (for GitLab MCP server)
- Anthropic API key (for Claude models)

## Relationship to Other Components

- **Git** conventions are enforced by the `/commit` workflow
- **Shell** `$AGENT`/`$CLAUDECODE` variables disable eza/bat aliases when agents run shell commands
- **tmux** propagates `$AGENT` to nested sessions
- **GitLab** MCP server provides issue/MR management inside the agent
