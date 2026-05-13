# prompts/

Copy-paste prompt library. Each file is a standalone prompt you can paste
directly into a chat, IDE, CLI, or API call.

## How to use

1. Find the prompt you need in the table below or browse by category
2. Check the `context_budget` — use `low` prompts on small local models
3. Copy the text from the `## Prompt` section of the file
4. Replace all `{{PLACEHOLDERS}}` before use
5. For low-context variants, see the `## Low-context variant` section in each file

New prompt? Copy [`../templates/prompt-template.md`](../templates/prompt-template.md).

---

## code/

| Prompt                                                                   | Budget | Description                                                          |
| ------------------------------------------------------------------------ | ------ | -------------------------------------------------------------------- |
| [`code/generate-unit-tests.md`](./code/generate-unit-tests.md)           | medium | Generate a unit test suite for a module                              |
| [`code/code-review.md`](./code/code-review.md)                           | medium | Review code for quality, correctness, and conventions                |
| [`code/refactor-for-readability.md`](./code/refactor-for-readability.md) | medium | Refactor code to improve clarity without changing behaviour          |
| [`code/scaffold-module.md`](./code/scaffold-module.md)                   | low    | Scaffold a new module matching project conventions                   |
| [`code/explain-codebase.md`](./code/explain-codebase.md)                 | medium | Produce a plain-language explanation of what a codebase or file does |
| [`code/audit-unused-code.md`](./code/audit-unused-code.md)               | high   | Audit a codebase for unused imports, exports, functions, types, and dependencies |
| [`code/audit-codebase-structure.md`](./code/audit-codebase-structure.md) | high   | Audit file and folder structure for navigability issues and produce a prioritised change list |
| [`code/extract-reusable-react-components.md`](./code/extract-reusable-react-components.md) | high | Identify duplicated JSX patterns and extraction candidates in React component files |

## planning/

| Prompt                                                                 | Budget | Description                                                      |
| ---------------------------------------------------------------------- | ------ | ---------------------------------------------------------------- |
| [`planning/ideate-project.md`](./planning/ideate-project.md)           | medium | Develop a bare-bones idea into a structured concept with competitive analysis |
| [`planning/write-product-spec.md`](./planning/write-product-spec.md)   | medium | Expand a concept document into a milestone-organized product spec             |
| [`planning/write-feature-spec.md`](./planning/write-feature-spec.md)   | low    | Turn a rough idea into a structured feature spec                 |
| [`planning/break-into-tasks.md`](./planning/break-into-tasks.md)       | low    | Break a spec into a prioritised, estimated task list             |
| [`planning/write-adr.md`](./planning/write-adr.md)                                                         | low    | Document an architectural decision with context and consequences                      |
| [`planning/surface-architecture-decisions.md`](./planning/surface-architecture-decisions.md)               | high   | Discover and confirm implicit/explicit architecture decisions in a codebase, then hand off to write-adr |
| [`planning/estimate-complexity.md`](./planning/estimate-complexity.md) | low    | Estimate the complexity and risk of a piece of work              |

## testing/

| Prompt                                                                 | Budget | Description                                                                |
| ---------------------------------------------------------------------- | ------ | -------------------------------------------------------------------------- |
| [`testing/generate-test-cases.md`](./testing/generate-test-cases.md)   | low    | Generate a test case list (without writing code) for a feature or function |
| [`testing/review-test-coverage.md`](./testing/review-test-coverage.md) | medium | Review an existing test suite for gaps and quality                         |
| [`testing/write-e2e-scenario.md`](./testing/write-e2e-scenario.md)     | low    | Write an end-to-end test scenario in plain language or test code           |

## agent-orchestration/

| Prompt                                                                                           | Budget | Description                                                   |
| ------------------------------------------------------------------------------------------------ | ------ | ------------------------------------------------------------- |
| [`agent-orchestration/decompose-task.md`](./agent-orchestration/decompose-task.md)               | low    | Break a complex task into independently executable sub-tasks  |
| [`agent-orchestration/summarize-for-handoff.md`](./agent-orchestration/summarize-for-handoff.md) | low    | Summarize session state for handoff to a new session or agent |
| [`agent-orchestration/self-critique-loop.md`](./agent-orchestration/self-critique-loop.md)       | low    | Ask the model to critique and improve its own output          |
