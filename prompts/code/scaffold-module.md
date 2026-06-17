---
title: Scaffold a new module
description: Scaffold a new module that matches the project's existing conventions and structure. Use when starting a new module and you want boilerplate consistent with the codebase.
category: code
tags: [scaffold, boilerplate, module, structure, conventions]
context_budget: low
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2026-03-17
      note: Initial version
---

# Scaffold a new module

Generates the skeleton of a new module — file structure, exports, types,
and placeholder implementations — matching the conventions you describe.
Produces structure and interfaces, not logic. Logic comes from a subsequent
implementation session using `skills/coding/implement-feature/`.

Use this at the start of a new feature to establish the module's shape
before implementation begins. A good scaffold makes the implementation
session faster and more consistent because the model isn't deciding
structure and logic simultaneously.

## When to use

- Starting a new module, service, route handler, or component from scratch
- Establishing consistent structure across multiple related modules
- Before an implementation session — scaffold first, implement second
- NOT when an existing module just needs new functions — add to it directly
- NOT when the implementation is trivial enough to not need a scaffold step

## Interfaces

| Interface | Notes                                                                                                                                                     |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| IDE       | Ideal interface — the model can create files directly in agent mode. Reference an existing similar module with `@filename` to show the pattern to follow. |
| Chat      | Use to generate the scaffold text, then create files manually.                                                                                            |
| CLI       | Pipe output directly to a file for review.                                                                                                                |
| API       | Suitable for automated scaffolding pipelines. Parse the output for individual file contents.                                                              |

## Prompt

````
Scaffold a new {{LANGUAGE}} module named {{MODULE_NAME}}.

Purpose: {{PURPOSE}}

{{#if EXAMPLE_MODULE}}
Follow the structure and conventions of this existing module:
```{{LANGUAGE}}
{{EXAMPLE_MODULE}}
```
{{/if}}

Conventions to follow:
{{CONVENTIONS}}

Generate the following:
1. File list — the files that make up this module and what each contains
2. Each file's complete scaffold — imports, type definitions, exported
   function/class signatures with placeholder bodies, and any boilerplate
   that every file of this type requires

Placeholder body format:
- Functions should throw a `NotImplementedError` (or language equivalent)
  with the message: "{{MODULE_NAME}}: [function name] not yet implemented"
- Do not write any logic — only structure, types, and signatures

Also include:
- A test file scaffold with one describe block per exported function,
  each containing a single placeholder test:
  `it('TODO: [function name]', () => { expect(true).toBe(true) })`
- Any index/barrel file needed to export the module's public API

Output each file as:
### path/to/filename.ext
[file contents]
````

### Placeholders

| Placeholder          | Description                                                                               | Example                                                                                      |
| -------------------- | ----------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `{{LANGUAGE}}`       | Language and framework                                                                    | `TypeScript`, `Python 3`, `Node.js/Express`                                                  |
| `{{MODULE_NAME}}`    | Name of the module                                                                        | `user-export`, `PaymentService`, `authRouter`                                                |
| `{{PURPOSE}}`        | One sentence: what this module will do                                                    | `Handle CSV export of user activity data via a REST endpoint`                                |
| `{{EXAMPLE_MODULE}}` | Optional. An existing similar module to use as a pattern. Remove the block if not needed. | _(paste an existing service or route file)_                                                  |
| `{{CONVENTIONS}}`    | Project-specific conventions to follow                                                    | _(paste relevant sections from `skills/coding/implement-feature/references/conventions.md`)_ |

## Low-context variant

This prompt is already `context_budget: low`. If `{{EXAMPLE_MODULE}}` is
large, omit it and describe the pattern in `{{CONVENTIONS}}` instead:

```
Scaffold a new {{LANGUAGE}} module named {{MODULE_NAME}}.
Purpose: {{PURPOSE}}
Conventions: {{CONVENTIONS}}

Output: file list, then each file with typed signatures and placeholder
bodies that throw NotImplementedError. Include a test file scaffold.
```

## Notes & tips

- The more concrete `{{CONVENTIONS}}` is, the better the scaffold. Paste
  directly from `skills/coding/implement-feature/references/conventions.md`
  rather than summarising.
- If the model generates logic in the placeholder bodies, add: "Placeholder
  bodies must only throw NotImplementedError. Do not implement any logic."
- After scaffolding, pass the scaffold output as context to an
  `implement-feature` skill session: "Implement the functions in this
  scaffold according to this spec: [spec]"
- Related prompts:
  [`planning/write-feature-spec.md`](../planning/write-feature-spec.md),
  [`code/generate-unit-tests.md`](./generate-unit-tests.md)
- Related skills:
  [`skills/coding/implement-feature/`](../../skills/coding/implement-feature/)

## Skill body

A verbatim skill body (overrides the placeholder transform, since inputs and any
example module come from context rather than pasted values and fenced blocks).

```
Scaffold a new module. Use the module name and language/framework the user gave
(infer the language from the project if unstated). The module's purpose is what
the user described.

If the user pointed to an existing similar module, follow its structure and
conventions. Otherwise match the conventions of the surrounding codebase, plus
any conventions the user specified.

Generate the following:
1. File list — the files that make up this module and what each contains
2. Each file's complete scaffold — imports, type definitions, exported
   function/class signatures with placeholder bodies, and any boilerplate that
   every file of this type requires

Placeholder body format:
- Functions should throw a NotImplementedError (or language equivalent) with the
  message: "[module name]: [function name] not yet implemented"
- Do not write any logic — only structure, types, and signatures

Also include:
- A test file scaffold with one describe block per exported function, each
  containing a single placeholder test:
  it('TODO: [function name]', () => { expect(true).toBe(true) })
- Any index/barrel file needed to export the module's public API

Output each file as:
### path/to/filename.ext
[file contents]
```
