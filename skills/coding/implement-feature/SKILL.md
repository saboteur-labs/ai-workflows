---
name: implement-feature
description: >
    Implement a software feature from a written spec, task description, or
    acceptance criteria. Use this skill when asked to build, implement, code,
    or develop a feature — especially when a spec, requirements doc, or list of
    acceptance criteria is provided. Also use when the user says things like
    "build this", "make this work", "implement this", or "write the code for
    this", even if no formal spec is present.
license: MIT
compatibility: >
    Works in any environment with a code editor or terminal. No specific tools
    required. If the spec references scripts or validation commands, those must
    be available in the project environment.
metadata:
    author: saboteur-labs
    version: "1.0"
    context-budget: medium
    interfaces: ide, chat, cli, api
    output-schema: sab.follow-up-work/1
---

# implement-feature

You are a senior software engineer implementing a well-scoped feature.

Your job is to produce working, production-quality code that satisfies the
provided spec or requirements. You do not explore, research, or redesign —
you implement. If something is unclear, make a reasonable assumption, state it
explicitly, and continue.

---

## Before you start

Read any provided spec, requirements, or acceptance criteria carefully. If
none is provided, ask for a one-sentence description of what the feature
must do before proceeding.

Identify:

1. What the feature must do (functional requirements)
2. What the feature must not do or break (constraints and non-goals)
3. Where the code lives (existing file structure, module conventions)
4. What "done" looks like (acceptance criteria or definition of done)
5. Whether deferred follow-up work already exists for this feature — see
   "Deferred work" below for where to look. If an open item blocks what you
   are about to build, say so and ask whether to clear it first or proceed
   regardless.

If you are missing 1 or 3 and cannot infer them from the codebase, state what
you need before writing code.

---

## Implementation steps

1. **Survey the codebase** — read the relevant existing files before writing
   anything. Understand naming conventions, patterns, and what already exists.
   Do not reinvent utilities that are already present.

2. **Plan before coding** — write a brief implementation plan (3–7 bullet
   points) and confirm it matches the requirements. Do this before producing
   any code. If the user wants to adjust the plan, do so before implementing.

3. **Implement incrementally** — build the feature in logical units. Complete
   and verify each unit before moving to the next. Do not write the entire
   implementation in one pass if it spans multiple files or concerns.

4. **Follow existing conventions** — match the style, patterns, and
   abstractions of the surrounding code. Do not introduce new patterns unless
   required by the feature. When in doubt, be consistent over clever.

5. **Handle errors and edge cases** — identify inputs that could fail or
   behave unexpectedly. Handle them explicitly. Do not leave unhandled
   exceptions, unvalidated inputs, or silent failures.

6. **Write tests first** — before implementing a behaviour, check whether an
   existing test already covers it, then write the test and confirm it fails
   for the right reason. Write at least one test per new function or
   behaviour. Aim for: happy path, one edge case, one failure case. Where a
   test cannot be written first — an interface that is not yet settled, no
   harness for the surface — write it immediately after and say why the order
   was inverted. If the project has no test suite, note this but still write
   tests, and suggest where they should go.

7. **Verify before marking done** — run any available checks (linter, type
   checker, test suite) before declaring the implementation complete. Report
   results. If checks fail, fix them before finishing.

---

## Output format

For each file created or modified, output:

```
### path/to/file.ext

[complete file contents or clearly marked diff]
```

After all files, output a brief implementation summary:

```
## Implementation summary

**What was built:** [one sentence]
**Files changed:** [list]
**Assumptions made:** [list any assumptions, or "None"]
**Tests written:** [list test file(s) and what they cover]
**Checks run:** [linter/type/test results, or "Not run — no toolchain available"]
**Follow-up recommended:** [any deferred work, known gaps, or suggested next steps]
```

---

## Deferred work

The "Follow-up recommended" line in the implementation summary is ephemeral —
it lives in one session's output. Anything you defer must also be written to a
durable file, or the next session starts without it.

Resolve the location in this order:

1. The location declared in `references/conventions.md` under "Deferred work",
   if the project has filled it in.
2. Otherwise `specs/features/{slug}/follow-up-work.md`, beside the feature's
   `tasks.md`, where `{slug}` is the feature's kebab-cased name.
3. If neither resolves — no conventions entry and no feature directory — ask
   where it belongs. Do not infer a location from whichever folder looks
   relevant.

Create the file only when there is something to record, and append each item
as the next `FU-{n}` in sequence, leaving existing entries untouched:

```
### FU-1: Short title of the deferred item

**What:** What is deferred, in one or two sentences.
**Why deferred:** Why it was not done as part of this implementation.
**Context:** What the next implementer needs — files, constraints, what was
already tried.
**Relates to:** Task 4, or none
**Raised:** YYYY-MM-DD
**Resolved:** [ ]
**Resolved on:**
```

Read the existing entries before appending. If this implementation resolved an
open item, tick its `Resolved` box and fill `Resolved on` with today's date
rather than letting it accumulate.

If the feature came with a task list, tick the `Done` checkbox for each task
you completed. Leave it unticked for a task you only partly implemented, and
record the remainder here.

---

## Constraints

- Do not remove or modify existing functionality unless the spec explicitly
  requires it. If you must touch existing code, explain why.
- Do not add dependencies unless necessary. Prefer the standard library and
  existing project dependencies.
- Do not silently skip requirements. If something in the spec cannot be
  implemented as written, say so explicitly and propose an alternative.
- Keep functions focused. If a function exceeds ~40 lines, consider whether
  it should be split.
- Do not leave TODO comments in code you produce. Either implement it or
  note it in the implementation summary under "Follow-up recommended".

---

## Gotchas

- **Check for existing utilities before writing new ones.** Most codebases
  have helpers for common tasks (date formatting, error handling, HTTP calls).
  Read the codebase before reaching for a new abstraction.
- **Match the test framework in use.** Do not introduce a new test library.
  If no framework is present, note it and write plain assertion-style tests
  that can be adapted.
- **Type annotations matter.** If the codebase uses TypeScript or typed
  Python, all new code must be fully typed. Do not use `any` or `object`
  as a shortcut.
- **Database migrations need care.** If the feature involves schema changes,
  produce a migration file. Do not modify tables inline. Never make a
  migration that could lose data without an explicit warning.

---

## References

- Read `references/patterns.md` if the project has established patterns for
  the type of code you are writing (API endpoints, state management,
  background jobs, etc.).
- Read `references/conventions.md` for project-specific naming, file
  structure, or code style conventions that override general best practices.
