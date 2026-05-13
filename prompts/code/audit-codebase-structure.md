---
title: Audit codebase structure for navigability
category: code
tags: [audit, structure, organization, dead-code, refactor, files, folders]
context_budget: high
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2026-04-10
      note: Initial version
---

# Audit codebase structure for navigability

Analyses the file and folder structure of a codebase or directory and
produces a prioritised audit of structural issues — things that make the
codebase harder to reason about, navigate, or safely change.

Does not modify any files. The output is an audit report that feeds into a
separate restructuring step. Separating analysis from implementation avoids
the model making consequential moves (renames, deletes) before the full
picture is understood.

Use this before a structural refactor, when onboarding to an unfamiliar
codebase, or when the directory layout has grown organically and needs a
deliberate review.

## When to use

- Before restructuring a codebase or subdirectory
- When navigating the project requires tribal knowledge that shouldn't be
  necessary
- When dead code or misplaced files are suspected but not confirmed
- After significant growth — the structure that made sense at 10 files may
  not make sense at 100
- NOT when you want changes made immediately — use this to produce the
  audit first, then act on it in a separate session
- NOT as a substitute for reading the code when correctness is the concern —
  use [`code/code-review.md`](./code-review.md) for that

## Interfaces

| Interface | Notes                                                                                                                                                                          |
| --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| IDE       | Point the agent at the target directory. In Claude Code, `@folder` brings the tree into context. Run with agent mode enabled so the model can navigate the filesystem.         |
| Chat      | Paste the output of `tree -L 5 --dirsfirst` (or equivalent) into `{{SCOPE}}`. For large trees, limit depth first and expand specific subtrees on request.                      |
| CLI       | Run as an agentic session with filesystem access: `claude --scope src/ --prompt audit-codebase-structure.md`. The agent will traverse the tree and read files as needed.       |
| API       | Pass the directory tree and key file contents (package.json, pyproject.toml, imports index, etc.) programmatically. Include any declared conventions from README or CLAUDE.md. |

## Prompt

```
You are auditing the file and folder structure of {{SCOPE}}.

Your goal is to identify what makes this structure hard to reason about,
navigate, or change — and to recommend what should be different.

Do not modify any files. Do not implement any changes. Produce only the
audit report described below.

{{#if ADDITIONAL_CONTEXT}}
Additional context about this codebase:
{{ADDITIONAL_CONTEXT}}
{{/if}}

---

Step 1 — Map the structure

Before analysing, build a complete picture of the layout. Traverse all
directories and files within {{SCOPE}}. Note:

- The technology stack and its conventional project layout (if known)
- Any declared structural conventions: README files, CLAUDE.md,
  package.json workspaces, monorepo config, module manifests
- The apparent intent of each top-level directory
- Where tests live relative to the code they test

Step 2 — Analyse for structural issues

Examine the structure for each of the following categories. Investigate
thoroughly before concluding something is or isn't an issue — check imports,
references in config files, and usages before calling code dead.

**Empty or near-empty directories**
Directories that contain no files, only a single placeholder (e.g.
`.gitkeep`), or only subdirectories with no leaf files. These add navigation
steps without contributing organisation.

**Unused or dead modules**
Files or directories that appear unreferenced anywhere in the codebase —
no imports, no references in config, no invocations. Common signals: files
with no inbound imports, directories never referenced by any entry point or
manifest, orphaned scripts or utilities with no callers.

**Misplaced files**
Source files or directories that appear to be in the wrong location given
the surrounding structure. Common signals: a utility buried inside a feature
module, a shared type definition inside an implementation directory, config
files scattered across subdirectories instead of centralised, a module whose
name and location describe different things.

**Structural complexity**
Directory hierarchies that are unnecessarily deep, require many steps to
reach common files, or use intermediate directories that contain only one
subdirectory. A well-structured codebase lets a new contributor locate any
file within a few directory levels without needing a guide.

**Test organisation**
Inconsistent test placement — mixing co-located tests (next to source) with
centrally grouped tests (in a top-level `tests/` directory) without clear
reason. Test utilities duplicated across test directories. Test files that
don't follow a consistent naming convention relative to the files they test.

**Naming inconsistencies**
Directory or file names that don't follow the conventions used elsewhere —
mixed case conventions (`camelCase` vs `kebab-case` vs `snake_case`),
abbreviations used inconsistently, names that are vague or misleading about
what they contain, index files used inconsistently as module entry points.

**Redundant or overlapping structure**
Directories that serve the same purpose and could be merged, near-duplicate
module hierarchies, or parallel structures that diverge without clear reason.

Step 3 — Produce the audit report

## Structural Audit: {{SCOPE}}

### Overview
[2–3 sentences on the overall state of the structure. Is it broadly sound
with isolated issues, or are there systemic problems? What is the single
highest-impact change?]

### Findings

Group findings by category. Omit any category with no findings. For each
finding, use this format:

**[CATEGORY]** `path/to/location`
One paragraph: what the issue is and why it makes the codebase harder to
reason about, navigate, or change. End with one sentence on the recommended
change — what should happen, not how to implement it.
Severity: high | medium | low

Severity guide:
- High: actively misleads navigation, hides important code, or creates real
  risk of unintended changes
- Medium: adds friction to common workflows or makes onboarding noticeably
  harder
- Low: minor inconsistency with limited practical impact

### Prioritised change list

A flat, ordered list of recommended changes, highest-impact first. This list
is the direct input for a restructuring session — it should be specific
enough to act on without re-reading the audit.

Format each item as:
- `path/to/location` — one-sentence action (e.g. "delete", "move to X",
  "merge with Y", "rename to Z")

### What is working well
[Structural patterns that are sound and should be preserved when making the
recommended changes. Knowing what to keep is as important as knowing what to
change. If nothing stands out, write "None identified."]
```

### Placeholders

| Placeholder              | Description                                                                               | Example                                                                                                |
| ------------------------ | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `{{SCOPE}}`              | The directory to audit, or "the entire codebase"                                          | `src/`, `packages/api`, `the entire codebase`                                                          |
| `{{ADDITIONAL_CONTEXT}}` | Optional. Tech stack, team conventions, or known constraints. Remove block if not needed. | `This is a TypeScript monorepo. Tests are expected to be co-located with source files using .test.ts.` |

## Low-context variant

```
Audit the file and folder structure of {{SCOPE}}. Do not modify anything.

Look for: empty directories, unused or dead modules, misplaced files,
unnecessary depth, inconsistent test placement, naming inconsistencies, and
redundant structure.

For each issue found: path, one-sentence description, severity (high /
medium / low), and recommended change.

End with a flat prioritised list of changes, highest-impact first.
```

## Notes & tips

- Run this before any structural refactor, not after — the audit shapes what
  the refactor should do. Restructuring without an audit risks moving things
  into a layout that has the same problems in a different arrangement.
- "Unused" is easy to misidentify. Before marking a file dead, check: dynamic
  imports, string-based requires, config-driven entry points, CLI scripts
  invoked by name. Add `{{ADDITIONAL_CONTEXT}}` to flag any of these patterns
  present in your stack.
- The prioritised change list is designed to be passed directly to a
  restructuring session. Pair it with
  [`planning/break-into-tasks.md`](../planning/break-into-tasks.md) if the
  list is long — some moves depend on others and should be sequenced.
- For very large codebases, run once per top-level directory and consolidate
  findings with
  [`agent-orchestration/summarize-for-handoff.md`](../agent-orchestration/summarize-for-handoff.md).
- The "What is working well" section is not decoration — when restructuring,
  it's easy to disrupt patterns that are actually sound. Make sure the
  implementer reads it.
- Related prompts:
  [`code/explain-codebase.md`](./explain-codebase.md),
  [`code/code-review.md`](./code-review.md),
  [`planning/break-into-tasks.md`](../planning/break-into-tasks.md),
  [`agent-orchestration/summarize-for-handoff.md`](../agent-orchestration/summarize-for-handoff.md)
