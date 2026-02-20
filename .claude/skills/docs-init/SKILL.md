---
name: docs-init
description: Generate technical documentation for the project or a specific component
---

Generate comprehensive technical documentation for this project. The user may provide an optional scope argument: $ARGUMENTS

**Determine scope:**

- If a path or component name is provided (e.g. `api`, `src/auth`, `database`), document only that component.
- If no argument is provided, document the entire project.

Documentation lives in `docs/` organized by component: `docs/<component>.md` (e.g. `docs/api.md`, `docs/database.md`, `docs/auth.md`). A top-level `docs/README.md` serves as the documentation index.

Follow these steps:

1. **Explore the entire codebase thoroughly** — read source files, AGENTS.md, the project README, configuration files, and all directories. Understand the project's purpose, architecture, and how components relate to each other.

2. **Identify documentable components** — group by functional area based on the project's actual structure. Look at the directory layout, module boundaries, and logical separations. Each component should map to a meaningful architectural unit (e.g. a service, module, library, subsystem, or major feature area).

3. **For each component, read ALL relevant files** and produce a documentation file that includes:
   - **Overview** — what the component does, its role in the system, why it's designed this way
   - **File structure** — list of key files with one-line descriptions
   - **Architecture and design** — data flow, key abstractions, patterns used
   - **API / Interface** — public functions, classes, endpoints, or CLI commands with signatures and descriptions
   - **Configuration** — environment variables, config files, feature flags
   - **Key design decisions** — non-obvious choices and their rationale
   - **Dependencies** — external libraries, services, or other components required
   - **Testing** — how to run tests, what's covered, testing patterns used
   - **Relationship to other components** — how this component interacts with others

4. **Create `docs/README.md`** — a documentation index that:
   - Briefly describes the project and its purpose
   - Lists all component docs with links and one-line descriptions
   - Includes a quick-start section (setup, build, run, test commands)
   - Documents the overall architecture and how components fit together

5. **Writing style:**
   - Be technical and precise — this is reference documentation, not a tutorial
   - Include actual code snippets or command examples where they clarify behavior
   - Use tables for API endpoints, configuration options, and environment variables
   - Use code blocks with appropriate language tags
   - Keep sections scannable — use headings liberally, avoid walls of text
   - Document the "why" not just the "what" — explain non-obvious design decisions
   - Do NOT document every single function — focus on public API, important internals, and non-obvious behavior

6. **Do NOT create empty docs** — only create a `docs/<component>.md` if there is meaningful content to document.

7. **Format with Prettier** — after creating each markdown file, run `npx prettier --write <file>` to ensure consistent formatting.

8. **Print a summary** at the end — list all documentation files created with a brief description of what each covers and the total scope documented.
