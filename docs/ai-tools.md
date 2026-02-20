# AI Tools Configuration

## Overview

The repository configures two AI coding assistants: **Claude Code** (Anthropic's CLI agent) and **OpenCode** (a TUI-based coding agent). Both share similar conventions through `AGENTS.md` files and are configured to use Claude Opus 4.6 as the primary model.

## File Structure

| File                             | Description                                                 |
| -------------------------------- | ----------------------------------------------------------- |
| `AGENTS.md` (repo root)          | Project-level instructions for Claude Code                  |
| `.config/opencode/opencode.json` | OpenCode configuration (model, MCP servers, slash commands) |
| `.config/opencode/AGENTS.md`     | OpenCode agent instructions (Python, Git, GitLab)           |
| `.config/opencode/agent/ask.md`  | Read-only agent mode definition                             |

Note: Claude Code's own config (`.config/Claude/`) is referenced in the root `AGENTS.md` but the actual config directory is not present in this repo — it's configured outside the dotfiles.

## Claude Code

### Configuration

Claude Code reads project-level instructions from `AGENTS.md` in the repo root and from `~/.config/Claude/AGENTS.md` for user-level preferences. The root `AGENTS.md` contains:

- Complete repository structure and purpose
- Code style guidelines for all languages (Shell, Lua, Python, Markdown, YAML, JSON)
- Editor settings reference (rulers, formatters, tab sizes)
- Git conventions (Conventional Commits, no issue IDs)
- Environment notes (platforms, tools, shell setup)

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

OpenCode defines several custom slash commands:

| Command         | Description                                                 |
| --------------- | ----------------------------------------------------------- |
| `/commit`       | Analyze changes, create well-formatted Conventional Commits |
| `/todo-init`    | Scan project and create initial TODO files by area          |
| `/todo-revise`  | Update existing TODO files based on recent changes          |
| `/todo-analyze` | Deep-analyze a TODO file, map dependencies, produce plan    |
| `/docs-init`    | Generate comprehensive technical documentation              |
| `/docs-revise`  | Update existing documentation to match codebase changes     |

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
