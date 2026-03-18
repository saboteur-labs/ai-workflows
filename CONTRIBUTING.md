# Contributing

This repo grows by adding prompts, skills, and guides from real project
experience. The best contributions are grounded in tasks you actually did —
not prompts written speculatively.

---

## Adding a prompt

1. Copy `templates/prompt-template.md` into the right category under `prompts/`
2. Name the file in `kebab-case.md` (e.g. `generate-migration-script.md`)
3. Fill in all frontmatter fields — do not leave defaults
4. Write the prompt text with `{{PLACEHOLDERS}}` for variable parts
5. Include a low-context variant if `context_budget` is `medium` or `high`
6. Add an entry to the index table in `prompts/README.md`
7. Open a PR — the frontmatter validator runs automatically

## Adding a skill

1. Copy the `templates/skill-template.md` guidance and create a new directory
   under `skills/<category>/<skill-name>/`
2. The directory name must match the `name` field exactly
3. Write `SKILL.md` following the [Agent Skills spec](https://agentskills.io/specification)
4. Add `references/` files if the skill has conditional reference content
5. Create a `-minimal` sibling directory if `context-budget` is `medium` or `high`
6. Run `skills-ref validate ./skills/<category>/<skill-name>` if available
7. Add an entry to `skills/README.md`
8. Open a PR

## Adding a guide

1. Create a new `.md` file in the appropriate `guides/` subdirectory
2. Use the stub format if writing a placeholder, or write the full content
3. Add an entry to the parent directory's `README.md` table
4. Update the status column (`🔲 Stub` → `✅ Done`)

## Content standards

- **Be specific.** Generic advice ("handle errors properly") is less useful
  than concrete patterns ("throw `AppError` with a `statusCode` field").
- **Be honest about scope.** Every prompt and skill should have explicit
  "when NOT to use" guidance.
- **Test before contributing.** Run the prompt or skill against a real task
  before submitting. Note any model-specific quirks you found.
- **Keep it model-agnostic.** Do not reference specific model names in
  prompt or skill text. Use `context_budget` tiers instead.

## Frontmatter validation

The CI workflow checks:

- All required fields are present
- `context_budget` is one of `low`, `medium`, `high`
- Skill `name` matches the directory name
- Skill `description` is under 1024 characters

Fix validation failures before requesting review.
