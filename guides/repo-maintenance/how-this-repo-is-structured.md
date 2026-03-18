# How this repo is structured

The authoritative reference for what lives where and why. Read this
before adding or modifying any content. The `repo-maintenance` skill
loads this file when it needs to verify a file path or understand the
rationale behind a structural decision.

---

## Design principles

**Content is for copying, not linking.** Prompts and skills are designed
to be copied into other projects. The repo has no runtime dependencies
and is not used as a submodule. All structure supports the copy workflow.

**Model-agnostic throughout.** No model names, vendor syntax, or pricing
appear in any prompt, skill, or guide. Capability tiers (`low`, `medium`,
`high`) and interface types (`ide`, `chat`, `cli`, `api`) are used instead.

**Context budget is first-class.** Every prompt and skill declares its
context cost so local model viability is immediately visible. This is
enforced by CI.

**Propose before act.** The repo is maintained by a small team and AI
agents. The propose-before-act rule and the CI guardrails together prevent
inconsistency from accumulating.

---

## The three core directories

### `guides/`

Conceptual documentation. Guides explain _how_ and _why_ — the reasoning
behind workflows, the principles behind model selection, the mechanics
of context management. They are written to be read, not copied.

Guides are evergreen where possible. Time-sensitive guides (tool setup,
model recommendations) carry a `review-by` frontmatter field.

New guides go in the appropriate subdirectory. New subdirectories require
explicit approval.

### `prompts/`

Copy-paste prompt library. Each file is a standalone prompt with filled-in
structure: frontmatter, when-to-use guidance, the prompt text with
`{{PLACEHOLDERS}}`, a placeholder table, a low-context variant, and notes.

Prompts are categorised into `code/`, `planning/`, `testing/`, and
`agent-orchestration/`. New categories require explicit approval.

### `skills/`

Agent Skills conforming to the [agentskills.io specification](https://agentskills.io/specification).
Each skill is a directory, not a file. The directory name must exactly
match the `name` field in `SKILL.md`. Skills include `references/` files
that are loaded conditionally and `assets/` for templates and static
resources.

Every `medium`-budget skill must have a `-minimal` sibling. Per-project
`references/` stubs are intentionally incomplete — they are filled in
when a skill is copied to a target project, not in this repo.

---

## Support directories

### `templates/`

Source of truth for all content structure. Every new prompt, skill,
guide, example step, and README must use the appropriate template.
Templates may not be modified without explicit human approval.

`templates/structures/` contains templates for document types that aren't
prompts or skills: guides, example steps, directory READMEs, and
CHANGELOG entries.

### `examples/`

Worked end-to-end demonstrations showing how prompts and skills chain
together for realistic tasks. Each example is a numbered sequence of
step files with a README. Steps show: the prompt used (with placeholders
filled), representative output, and what to check before the next step.

### `tools/`

Shell-first utilities. Every tool has a `.sh` entry point. Heavier logic
lives in `tools/lib/` (Python and Node stubs). Tools are designed to
compose: `fetch-prompt.sh` + `chunk-file.sh` + a model CLI = a complete
processing pipeline.

### `.github/`

CI workflows and GitHub templates. Workflows are the automated enforcement
layer for the repo's quality rules. They must not be modified by agents
without explicit human approval.

---

## Structural invariants

These properties must remain true at all times. CI enforces several of
them; the rest are checked during proposal review.

1. Every file in `prompts/` has complete frontmatter with valid
   `context_budget` value
2. Every skill directory `name` matches its directory name exactly
3. Every skill `description` is ≤ 1024 characters
4. Every `medium`-budget skill has a `-minimal` sibling
5. Every directory with content files has a `README.md` with an index
   table covering all files in that directory
6. `prompts/README.md` lists every file in `prompts/` (all categories)
7. `skills/README.md` lists every skill directory in `skills/`
8. `CHANGELOG.md` has an entry for every content addition or change
9. No file in `prompts/` or `skills/` contains `{{UNFILLED_PLACEHOLDER}}`
   tokens outside code fences
10. No internal markdown link resolves to a non-existent file

---

## What belongs where: decision guide

| Content type                                  | Correct location                        |
| --------------------------------------------- | --------------------------------------- |
| "How does X work" (conceptual)                | `guides/<subdirectory>/`                |
| "How do I do X" (step-by-step)                | `guides/workflows/`                     |
| Standalone copy-paste instruction for a model | `prompts/<category>/`                   |
| Persistent model role + operating rules       | `skills/<category>/<name>/`             |
| End-to-end worked pipeline demo               | `examples/<example-name>/`              |
| Utility script                                | `tools/`                                |
| Content authoring template                    | `templates/` or `templates/structures/` |
| Repo self-documentation                       | `guides/repo-maintenance/`              |

When in doubt: if a developer would read it once and refer back to it,
it's a guide. If they'd copy it into a session or project, it's a prompt
or skill.
