---
title: Explain a codebase or file
description: Produce a plain-language explanation of what a codebase, file, or unit does and how it fits together. Use to onboard onto unfamiliar code or to document existing behaviour.
category: code
tags: [explain, understand, onboarding, documentation, exploration]
context_budget: medium
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2026-03-17
      note: Initial version
---

# Explain a codebase or file

Produces a plain-language explanation of what a file, module, or codebase
does — how it's structured, what its key parts are, and how they relate.
Calibrated to the audience and depth you specify.

Use this for onboarding to unfamiliar code, generating documentation, or
understanding what exists before modifying it. Understanding before modifying
is the single habit that most reduces unintended breakage in AI-assisted
development.

## When to use

- Before modifying an unfamiliar file or module
- Onboarding a new team member to a codebase area
- Generating a plain-language summary for documentation or a PR description
- Understanding AI-generated code before accepting it
- NOT as a substitute for reading critical code yourself before making
  high-risk changes — use this to orient, then read the relevant parts

## Interfaces

| Interface | Notes                                                                                                               |
| --------- | ------------------------------------------------------------------------------------------------------------------- |
| IDE       | Reference the file with `@filename`. Works well as a pre-task step before asking the model to modify the same file. |
| Chat      | Paste file contents into `{{CODE}}`. For large files, chunk first and run once per chunk, then consolidate.         |
| CLI       | `cat src/services/auth.ts \| your-model-cli --prompt explain-codebase.md`                                           |
| API       | Suitable for generating documentation at build time. Pass file contents programmatically.                           |

## Prompt

````
Explain the following {{LANGUAGE}} {{UNIT_TYPE}} to {{AUDIENCE}}.

```{{LANGUAGE}}
{{CODE}}
```

Depth: {{DEPTH}}

Structure your explanation as follows:

## Purpose
One paragraph. What does this {{UNIT_TYPE}} do and what problem does it
solve? Do not describe the implementation yet — only the what and why.

## Key components
A bullet list of the main functions, classes, or sections. For each:
- Name and signature (for functions/methods)
- What it does in one sentence
- Any important side effects, dependencies, or constraints to be aware of

## How it works
A narrative explanation of the main flow or logic. Describe what happens
from the entry point to the output. Use plain language — avoid restating
the code line-by-line. Focus on the decisions and patterns, not the syntax.

## Dependencies and interfaces
- What does this {{UNIT_TYPE}} depend on (imports, external services, config)?
- What does it export or expose to callers?
- What assumptions does it make about its inputs?

## Things to know before modifying
Gotchas, non-obvious constraints, or important context that someone would
need before making changes. If nothing non-obvious exists, write "None identified."
````

### Placeholders

| Placeholder     | Description                | Example                                                                                                                       |
| --------------- | -------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `{{LANGUAGE}}`  | Programming language       | `TypeScript`, `Python`                                                                                                        |
| `{{UNIT_TYPE}}` | What is being explained    | `file`, `module`, `service`, `component`, `function`                                                                          |
| `{{AUDIENCE}}`  | Who the explanation is for | `a new developer joining the team`, `a non-technical stakeholder`, `me — I'm unfamiliar with this codebase`                   |
| `{{CODE}}`      | The code to explain        | _(paste contents)_                                                                                                            |
| `{{DEPTH}}`     | Level of detail            | `high-level overview — skip implementation details`, `detailed — explain the logic and decisions`, `line-by-line walkthrough` |

## Low-context variant

````
Explain this {{LANGUAGE}} {{UNIT_TYPE}} to {{AUDIENCE}}.

```{{LANGUAGE}}
{{CODE}}
```

Cover: what it does, its main components, how they connect, and anything
important to know before modifying it. Plain language, no jargon.
````

## Notes & tips

- The "Things to know before modifying" section is the most valuable part
  for development workflows. If it's weak, prompt: "What would a developer
  most likely get wrong when modifying this code?"
- For a codebase overview across multiple files, run once per key file and
  consolidate with `prompts/agent-orchestration/summarize-for-handoff.md`.
- Setting `{{AUDIENCE}}` to something specific produces a better explanation
  than leaving it generic. "A developer familiar with Node but new to this
  codebase" gets a more useful explanation than just "a developer."
- Related prompts:
  [`code/code-review.md`](./code-review.md),
  [`agent-orchestration/summarize-for-handoff.md`](../agent-orchestration/summarize-for-handoff.md)
