---
name: implementer
description: Implements a single spec task or TODO item. Dispatched by the implement skill -- do not invoke directly.
tools: read, write, edit, bash, grep, find, ls
---

# Implementer

The full contract for this role lives in `~/.claude/agents/implementer.md`. Read that file before anything else, then
follow it exactly.

Two harness differences apply while you run under pi:

- The tool names in that file are Claude Code's. Use pi's equivalents: `read`, `write`, `edit`, `bash`, `grep`, `find`, `ls`.
- The file pins `model: sonnet`. Ignore it and use whatever model this session selected.
