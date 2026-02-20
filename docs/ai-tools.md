# AI Tools Configuration

## Overview

The repository configures two AI coding assistants: **Claude Code** (Anthropic's CLI agent) and **OpenCode** (a TUI-based coding agent). Both share similar conventions through `AGENTS.md` files and are configured to use Claude Opus 4.6 as the primary model.

## File Structure

| File                             | Description                                                 |
| -------------------------------- | ----------------------------------------------------------- |
| `AGENTS.md` (repo root)          | Project-level instructions for Claude Code and OpenCode     |
| `.claude/CLAUDE.md`              | Claude Code user-level preferences (stow → `~/.claude/`)   |
| `.claude/skills/*/SKILL.md`      | Claude Code custom slash commands (stow → `~/.claude/skills/`) |
| `.config/opencode/opencode.json` | OpenCode configuration (model, MCP servers, slash commands) |
| `.config/opencode/AGENTS.md`     | OpenCode agent instructions (Python, Git, GitLab)           |
| `.config/opencode/agent/ask.md`  | Read-only agent mode definition                             |

Note: `~/.claude/settings.json` (MCP servers, hooks, plugins, permissions) is managed by Claude Code itself and not stow-managed.

## Claude Code

### Configuration

Claude Code reads instructions from multiple sources:

- **Project-level:** `AGENTS.md` in the repo root (structure, code style, git conventions)
- **User-level preferences:** `.claude/CLAUDE.md` (stow-managed to `~/.claude/CLAUDE.md`)
- **User-level skills:** `.claude/skills/*/SKILL.md` (stow-managed to `~/.claude/skills/`)
- **Settings:** `~/.claude/settings.json` (managed by Claude Code — MCP servers, hooks, plugins, permissions)

### User-Level Preferences (`.claude/CLAUDE.md`)

Cross-project preferences that apply in every Claude Code session:

- **Python**: Always use `uv` (never pip/conda/poetry)
- **Markdown**: Format with `npx prettier --write` after editing
- **Git**: No issue IDs (`#N`) in commit messages
- **GitLab**: Prefer MCP tools, fall back to `glab` CLI
- **TODO files**: Priority table + detailed sections + resolution order

### Slash Commands (Skills)

Six custom skills are stow-deployed from `.claude/skills/` to `~/.claude/skills/`:

| Command         | Description                                                 |
| --------------- | ----------------------------------------------------------- |
| `/commit`       | Analyze changes, create well-formatted Conventional Commits |
| `/todo-init`    | Scan project and create initial TODO files by area          |
| `/todo-revise`  | Update existing TODO files based on recent changes          |
| `/todo-analyze` | Deep-analyze a TODO file, map dependencies, produce plan    |
| `/docs-init`    | Generate comprehensive technical documentation              |
| `/docs-revise`  | Update existing documentation to match codebase changes     |

These are identical to the OpenCode slash commands (same templates), providing feature parity between the two tools.

### Key Conventions

- **Python**: Always use `uv` (never pip/conda/poetry)
- **Git**: Conventional Commits format, no `#N` issue references
- **Shell**: 2-space indentation, guard aliases with `$AGENT`
- **Lua**: 2-space indentation, single-quoted strings
- **Line length**: 120 characters for Python, Fortran, YAML

## OpenCode

### Model Configuration

```json
{
  "model": "anthropic/claude-opus-4-6",
  "small_model": "anthropic/claude-sonnet-4-6",
  "disabled_providers": ["opencode"],
  "autoupdate": true
}
```

### MCP Servers

OpenCode connects to a GitLab MCP server via the `glab` CLI:

```json
"mcp": {
  "gitlab": {
    "type": "local",
    "command": ["glab", "mcp", "serve"]
  }
}
```

This provides GitLab issue, merge request, and project management directly from the coding agent.

### Slash Commands

OpenCode defines the same 6 custom slash commands as Claude Code (see table above). The templates are defined in `opencode.json` under the `command` key. Claude Code's skill files contain identical prompt templates.

#### `/commit` Details

The commit command enforces:

- Conventional Commits format
- Max 72-char subject lines
- Semantic commit splitting (separate logical changes)
- Selective `git add` (no `git add .`)
- No secrets in commits
- No issue IDs in messages
- Shows `git log --oneline --name-only` after committing

#### `/todo-init` and `/todo-revise`

TODO files follow a structured format in `todos/<area>.md`:

1. Priority Summary table (P0/P1/P2) with links to detail sections
2. Detailed sections with descriptions
3. Suggested resolution order

#### `/docs-init` and `/docs-revise`

Documentation files live in `docs/<component>.md` with a `docs/README.md` index.

### Ask Agent

The `ask.md` agent definition creates a read-only mode that:

- Answers questions about the codebase, external docs, and general topics
- Strictly denies all file modifications
- Can use web search/fetch for external information
- Directs users to switch agents when they want to make changes

## Shared Conventions (AGENTS.md)

Both tools share conventions defined in their respective `AGENTS.md` files:

| Convention             | Detail                                                |
| ---------------------- | ----------------------------------------------------- |
| Python package manager | `uv` exclusively                                      |
| Markdown formatting    | Run `npx prettier --write` after editing              |
| Git commit messages    | Conventional Commits, no `#N` references              |
| GitLab interaction     | Prefer MCP tools, fall back to `glab` CLI             |
| TODO file format       | Priority table + detailed sections + resolution order |

## Stow Deployment

Claude Code user-level config is stow-managed from this repo:

```
.claude/CLAUDE.md              → ~/.claude/CLAUDE.md
.claude/skills/commit/         → ~/.claude/skills/commit/
.claude/skills/todo-init/      → ~/.claude/skills/todo-init/
.claude/skills/todo-revise/    → ~/.claude/skills/todo-revise/
.claude/skills/todo-analyze/   → ~/.claude/skills/todo-analyze/
.claude/skills/docs-init/      → ~/.claude/skills/docs-init/
.claude/skills/docs-revise/    → ~/.claude/skills/docs-revise/
```

The `.stow-local-ignore` excludes Claude Code's auto-generated project files (`settings*.json`, `plans/`, `todos/`). The `.gitignore` uses `/.claude/*` with explicit un-ignores for `CLAUDE.md` and `skills/`.

`~/.claude/settings.json` is NOT stow-managed — Claude Code writes to it directly (hooks, plugins, MCP servers, permissions).

## Dependencies

- **Claude Code** (`claude` CLI)
- **OpenCode** (`brew install anomalyco/tap/opencode`)
- **glab** CLI (for GitLab MCP server)
- Anthropic API key (for Claude models)

## Relationship to Other Components

- **Git** conventions are enforced by both agents' `/commit` workflows
- **Shell** `$AGENT` variable disables eza/bat aliases when agents run shell commands
- **tmux** propagates `$AGENT` to nested sessions
- **GitLab** MCP server provides issue/MR management inside the agent
