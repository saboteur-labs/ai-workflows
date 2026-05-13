---
title: Audit codebase for unused code
category: code
tags: [audit, dead-code, unused, cleanup, refactor, imports, dependencies]
context_budget: high
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2026-05-11
      note: Initial version
---

# Audit codebase for unused code

Analyses a codebase for unused imports, exports, functions, variables, types,
dead code paths, commented-out code, and unused package dependencies. Produces
a prioritised audit report that a human or AI agent can use as the direct
input to a cleanup session.

Does not modify any files. Separating analysis from deletion avoids removing
code that is used in ways that are not statically visible (dynamic imports,
plugin systems, framework conventions) without first confirming it is safe.

Use this before a cleanup pass, when a codebase has grown organically and
accumulated dead weight, or when you want to reduce bundle size, compile time,
or cognitive load.

## When to use

- Before a cleanup or tech-debt sprint to understand what is safe to remove
- After a large feature is deleted and its supporting code may be orphaned
- When static analysis tools (ESLint, Pyright, etc.) are not available or
  are not catching cross-file dead code
- When you need a human-readable rationale alongside each finding, not just
  a linter warning
- NOT when you want changes made immediately — use this to produce the audit
  first, then act on it in a separate session
- NOT as a substitute for a correctness review — use
  [`code/code-review.md`](./code-review.md) for logic errors and bugs
- NOT for a library's public API surface — exported symbols in a published
  package are not "unused" simply because no internal file imports them

## Interfaces

| Interface | Notes                                                                                                                                                                              |
| --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| IDE       | Point the agent at the target directory. In Claude Code, `@folder` brings the tree into context. Run with agent mode enabled so the model can traverse files and check references. |
| Chat      | Paste the output of `tree -L 4 --dirsfirst` plus key file contents into `{{SCOPE}}`. Best for small codebases; for large ones, use CLI or API mode.                                |
| CLI       | Run as an agentic session with filesystem access: `claude --scope src/ --prompt audit-unused-code.md`. The agent will traverse the tree and read files as needed.                  |
| API       | Pass the full source tree and manifest files (package.json, pyproject.toml, go.mod, etc.) programmatically. Include entry points in `{{ENTRY_POINTS}}`.                            |

## Prompt

```
You are auditing {{SCOPE}} for unused code.

Your goal is to identify every piece of code — imports, exports, variables,
functions, types, dead paths, commented-out blocks, and package dependencies
— that is no longer used and can safely be removed. Do not modify any files.
Produce only the audit report described below.

{{#if ADDITIONAL_CONTEXT}}
Additional context about this codebase:
{{ADDITIONAL_CONTEXT}}
{{/if}}

---

Step 1 — Understand the codebase

Before analysing, build a complete picture of the project:

- Identify the tech stack and its module resolution rules (static imports,
  dynamic imports, re-exports, barrel/index files, path aliases)
- Identify all entry points: main files, CLI scripts, exported public API
  surface, test runners, framework-generated routes (e.g. Next.js pages dir,
  FastAPI router registration)
{{#if ENTRY_POINTS}}
- Known entry points provided: {{ENTRY_POINTS}}
{{/if}}
- Note patterns that can hide usage: plugin systems, string-based requires,
  decorator-driven injection, config-driven imports, environment-conditional
  code, `eval`, dynamic `import()`, reflection

Do not mark code as unused if you cannot rule out dynamic usage. Flag it as
"requires verification" instead.

Step 2 — Identify unused code by category

Check each category below. For each finding, verify by searching for all
references — imports, string mentions in config files, indirect re-exports —
before concluding something is unused.

**Unused imports**
Symbols imported into a file but never referenced in the file body. Includes
type-only imports that have been superseded, and side-effect imports
(`import './foo'`) with no observable effect.

**Unused exports**
Symbols exported from a module but imported by no other file in the project.
Applies only to internal modules — do not flag symbols that are part of the
declared public API of a library or package.

**Unused variables and constants**
Declared variables or constants that are never read after assignment.
Includes values that are assigned more than once where intermediate
assignments are never observed.

**Unused functions and methods**
Functions or methods defined but never called from inside or outside the
module, including those reachable only through exports that are themselves
unused.

**Unused types and interfaces**
Type aliases, interfaces, enums, or similar constructs that are never
referenced in a type position anywhere in the project.

**Dead code paths**
Code that can never execute: statements after an unconditional `return`,
`throw`, or `exit`; branches whose condition is always true or always false
given surrounding logic; feature flags or constants hard-coded to a single
value that make one branch permanently unreachable.

**Commented-out code**
Blocks of source code that have been commented out rather than deleted.
Do not flag explanatory comments, documentation, or inline annotations —
only code that was once active and has been disabled in place.

**Unused dependencies**
Packages listed in the dependency manifest (package.json, requirements.txt,
pyproject.toml, Gemfile, go.mod, etc.) for which no import statement appears
anywhere in the source tree. Check dev dependencies and peer dependencies
separately.

Step 3 — Produce the audit report

## Unused Code Audit: {{SCOPE}}

### Overview
[2–3 sentences on the overall state. How much dead code is present? Which
categories dominate? What is the single highest-confidence removal?]

### Findings

Group findings by category. Omit any category with no findings. For each
finding, use this format:

**[CATEGORY]** `path/to/file` — `symbol or line range`
One paragraph: what is unused, the evidence that confirms it is unused, and
whether any dynamic usage pattern means removal requires extra care. End with
one sentence stating the recommended action.
Severity: high | medium | low
Safe to auto-remove: yes | no | verify first

Severity guide:
- High: dead code that actively misleads readers, creates a maintenance trap,
  or meaningfully inflates bundle or binary size
- Medium: unused definitions that add noise and increase cognitive load
- Low: trivial unused imports or commented-out lines with low risk and low
  payoff

"Safe to auto-remove: verify first" means a tool or agent should confirm
the absence of dynamic usage before deleting.

### Prioritised removal list

A flat, ordered list of recommended removals, highest-confidence and
highest-impact first. This list is the direct input for a cleanup session.

Format each item as:
- `path/to/file:symbol_or_line` — one-sentence action (e.g. "delete unused
  import", "remove function and its call sites", "uninstall package")

### Risks and caveats
[Patterns in this codebase that make static analysis unreliable: dynamic
imports, plugin loading, config-driven entry points, reflection, test
fixtures that import symbols indirectly. Note any findings above marked
"verify first" and what to check. If none, write "None identified."]
```

### Placeholders

| Placeholder              | Description                                                                                     | Example                                                                                                   |
| ------------------------ | ----------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- |
| `{{SCOPE}}`              | The directory or project to audit, or "the entire codebase"                                     | `src/`, `packages/api`, `the entire codebase`                                                             |
| `{{ENTRY_POINTS}}`       | Optional. Known entry points the model should treat as roots. Remove block if not needed.       | `src/index.ts, src/cli.ts, src/workers/processor.ts`                                                      |
| `{{ADDITIONAL_CONTEXT}}` | Optional. Stack quirks, dynamic patterns, or public API surface to protect. Remove if not used. | `This is a Next.js app. Files in pages/ and app/ are entry points automatically. Do not flag them unused.` |

## Low-context variant

```
Audit {{SCOPE}} for unused code. Do not modify anything.

Check each category: unused imports, unused exports, unused variables and
constants, unused functions and methods, unused types, dead code paths,
commented-out code, unused package dependencies.

For each finding: file path, symbol or line range, one-sentence description
of what is unused and why it is safe to remove, severity (high / medium / low).

End with a flat prioritised removal list, highest-confidence first. Flag
anything that requires dynamic-usage verification before deletion.
```

## Notes & tips

- "Unused" is easy to misidentify in dynamic languages. Before marking
  anything dead, check: string-based requires, `__import__`, `importlib`,
  `require.context`, decorator registries, and config files that reference
  module names as strings. Use `{{ADDITIONAL_CONTEXT}}` to describe any of
  these patterns present in your stack.
- For large codebases, run once per top-level package or directory and
  consolidate findings with
  [`agent-orchestration/summarize-for-handoff.md`](../agent-orchestration/summarize-for-handoff.md).
- The prioritised removal list is designed to be passed directly to a cleanup
  session. For long lists, use
  [`planning/break-into-tasks.md`](../planning/break-into-tasks.md) to
  sequence removals safely — some deletions expose others (e.g. removing an
  export may make its importing file's import unused too).
- Unused dependency detection is unreliable when packages are loaded by name
  at runtime (e.g. Jest transform plugins, Babel presets, ESLint plugins).
  Always verify package removals against your toolchain config before
  uninstalling.
- The "Risks and caveats" section is not decoration — a cleanup agent that
  skips it may delete code that is genuinely in use. Ensure the implementer
  reads it before acting on the removal list.
- Related prompts:
  [`code/audit-codebase-structure.md`](./audit-codebase-structure.md),
  [`code/code-review.md`](./code-review.md),
  [`code/refactor-for-readability.md`](./refactor-for-readability.md),
  [`planning/break-into-tasks.md`](../planning/break-into-tasks.md),
  [`agent-orchestration/summarize-for-handoff.md`](../agent-orchestration/summarize-for-handoff.md)
