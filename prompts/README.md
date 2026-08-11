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

## Compiling to Copilot prompts and Claude skills

`node scripts/build-dist.js` compiles every prompt into ready-to-install formats
under `dist/` (the directory is regenerated on each run):

- **GitHub Copilot** — `dist/copilot/<category>/<name>.prompt.md`. Install with
  `cp -r dist/copilot/* /path/to/repo/.github/prompts/`.
- **Claude Code skills** — `dist/claude/skills/saboteur-<name>/SKILL.md`, namespaced
  under `saboteur-` and invocable as `/saboteur-<name>` (or auto-triggered from the
  `description`). Install with `cp -r dist/claude/skills/* /path/to/repo/.claude/skills/`
  (or `~/.claude/skills/` for personal use).

A prompt compiles to a skill only if its frontmatter has a `description`. The skill
body is derived from the `## Prompt` block, with placeholders rewritten into
natural-language instructions; see the template for the optional `## Skill inputs`,
`## Skill wrap-up`, and `## Skill body` sections and the `skill-saves-document` flag.

To keep installed skills tracking this repo instead of copying them, **symlink**
each one into your skills directory — e.g.
`ln -s "$PWD/dist/claude/skills/saboteur-break-into-tasks" ~/.claude/skills/`.
Two caveats: `dist/` is git-ignored, and each build wipes and regenerates it — so
after pulling changes, re-run `node scripts/build-dist.js` for symlinked skills to
pick them up. Skip skills that duplicate a Claude Code built-in (e.g. `code-review`)
or are framework-specific (e.g. `extract-reusable-react-components`, better scoped
to the relevant project's `.claude/skills/`).

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
| [`planning/break-into-features.md`](./planning/break-into-features.md) | medium | Break a product spec into independently shippable vertical-slice features |
| [`planning/break-into-tasks.md`](./planning/break-into-tasks.md)       | low    | Break a spec into a prioritised, estimated task list             |
| [`planning/write-adr.md`](./planning/write-adr.md)                                                         | low    | Document an architectural decision with context and consequences                      |
| [`planning/surface-architecture-decisions.md`](./planning/surface-architecture-decisions.md)               | high   | Discover and confirm implicit/explicit architecture decisions in a codebase, then hand off to write-adr |
| [`planning/estimate-complexity.md`](./planning/estimate-complexity.md) | low    | Estimate the complexity and risk of a piece of work              |

### Output schemas

Four of these prompts produce documents that an agent reads rather than a
person: `write-product-spec`, `write-feature-spec`, `break-into-features`, and
`break-into-tasks`. Each declares `output-schema:` in its frontmatter and has a
matching machine contract in [`../schemas/`](../schemas/README.md) covering the
document's required structure, ID scheme, dependency-graph invariants, and
conventional save path.

The contract is stated twice on purpose — as the output format authored in the
prompt, and as the schema — and `./tools/validate.sh --check outputs` asserts
the two agree, so neither can drift unnoticed. To check a produced document:

```bash
node tools/lib/check-outputs.js --doc <file> --schema sab.tasks/1
```

The other planning prompts produce documents for human review and deliberately
have no schema; a contract there would add ceremony without a consumer.

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
| [`agent-orchestration/retrospect-session.md`](./agent-orchestration/retrospect-session.md)       | low    | Turn a session's corrections into candidate rules, routed to the artifact that should carry each, and print the log entry it appends |
