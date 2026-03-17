# skills/

Reusable agent skills conforming to the
[Agent Skills specification](https://agentskills.io/specification).
Each skill is a directory containing a `SKILL.md` file and optional
`scripts/`, `references/`, and `assets/` subdirectories.

## How to use

Copy a skill directory into `.agents/skills/` in your project:

```sh
./tools/fetch-prompt.sh --install-skill coding/implement-feature
```

Or manually copy the directory. Then fill in
`references/patterns.md` and `references/conventions.md` with
project-specific details.

See [`../guides/workflows/`](../guides/workflows/) for interface-specific
injection instructions.

New skill? Use [`../templates/skill-template.md`](../templates/skill-template.md).

---

## coding/

| Skill | Budget | Description |
|-------|--------|-------------|
| [`coding/implement-feature/`](./coding/implement-feature/) | medium | Implement a feature from a spec — plan, code, test, validate |
| [`coding/implement-feature-minimal/`](./coding/implement-feature-minimal/) | low | Low-context variant of implement-feature |
| [`coding/debug-issue/`](./coding/debug-issue/) | low | Systematically diagnose and fix a bug or unexpected behaviour |

## planning/

| Skill | Budget | Description |
|-------|--------|-------------|
| [`planning/spec-writer/`](./planning/spec-writer/) | low | Write and refine feature specs through an iterative dialogue |
