# Contributing

This repo grows by adding prompts, skills, and guides from real project
experience. The best contributions are grounded in tasks you actually did —
not prompts written speculatively.

**Before creating any files:** use
[`templates/change-proposal-template.md`](./templates/change-proposal-template.md)
to propose the change and get approval. This applies to human contributors
and AI agents equally. The proposal ensures the right files are updated
together and that any external claims are sourced before they enter the repo.

---

## Running validation locally

Before pushing, run the local validation suite to catch the same errors
that CI will flag:

```sh
# Check only your changed files (fastest)
./tools/validate.sh --changed-only

# Run all checks against the full repo
./tools/validate.sh

# Run a specific check
./tools/validate.sh --check links
./tools/validate.sh --check atomicity
```

See [`tools/README.md`](./tools/README.md) for all available checks and
their CI equivalents.

---

## Adding a prompt

1. Submit a change proposal using
   [`templates/change-proposal-template.md`](./templates/change-proposal-template.md)
2. Copy `templates/prompt-template.md` into the right category under `prompts/`
3. Name the file in `kebab-case.md` (e.g. `generate-migration-script.md`)
4. Fill in all frontmatter fields — do not leave defaults
5. Write the prompt text with `{{PLACEHOLDERS}}` for variable parts
6. Include a low-context variant if `context_budget` is `medium` or `high`
7. Set `review-by` if the prompt references external tools or APIs
8. Add an entry to the index table in `prompts/README.md`
9. Add an entry to `CHANGELOG.md` under `[Unreleased]`
10. Run `./tools/validate.sh --changed-only` before opening a PR

## Adding a skill

1. Submit a change proposal using
   [`templates/change-proposal-template.md`](./templates/change-proposal-template.md)
2. Copy the `templates/skill-template.md` guidance and create a new directory
   under `skills/<category>/<skill-name>/`
3. The directory name must match the `name` field exactly
4. Write `SKILL.md` following the [Agent Skills spec](https://agentskills.io/specification)
5. Add `references/` files if the skill has conditional reference content
6. Set `review-by` if the skill references external tools or APIs
7. Create a `-minimal` sibling directory if `context-budget` is `medium` or `high`
8. Run `skills-ref validate ./skills/<category>/<skill-name>` if available
9. Add an entry to `skills/README.md`
10. Add an entry to `CHANGELOG.md` under `[Unreleased]`
11. Run `./tools/validate.sh --changed-only` before opening a PR

## Adding a guide

1. Submit a change proposal using
   [`templates/change-proposal-template.md`](./templates/change-proposal-template.md)
2. Create a new `.md` file in the appropriate `guides/` subdirectory using
   [`templates/structures/guide-template.md`](./templates/structures/guide-template.md)
3. Set `review-by` if the guide references external tools, versions, or settings
4. Add `verified-against` entries for any externally-sourced claims
5. Add an entry to the parent directory's `README.md` status table
6. Update the status column (`🔲 Stub` → `✅ Done`) when content is complete
7. Add an entry to `CHANGELOG.md` under `[Unreleased]`
8. Run `./tools/validate.sh --changed-only` before opening a PR

## Content standards

- **Be specific.** Generic advice ("handle errors properly") is less useful
  than concrete patterns ("throw `AppError` with a `statusCode` field").
- **Be honest about scope.** Every prompt and skill should have explicit
  "when NOT to use" guidance.
- **Test before contributing.** Run the prompt or skill against a real task
  before submitting. Note any model-specific quirks you found.
- **Keep it model-agnostic.** Do not reference specific model names in
  prompt or skill text. Use `context_budget` tiers instead.

## Validation

Run the local validation suite before opening a PR:

```sh
./tools/validate.sh --changed-only
```

This runs the same checks as CI. Fixing failures locally is faster than
waiting for CI to report them. See [`tools/README.md`](./tools/README.md)
for available checks and flags.

CI enforces these checks automatically on every PR:

- Frontmatter fields are present and valid
- `context_budget` is one of `low`, `medium`, `high`
- Skill `name` matches the directory name
- Skill `description` is under 1024 characters
- All dependency-map couplings are satisfied (CHANGELOG + README index tables)
- All internal links resolve to existing files
- No `{{PLACEHOLDERS}}` outside code fences
- No `🔲 Stub` markers in non-reference files

CI warns (but does not block) on:

- Files whose `review-by` date has passed or is within 30 days

Fix all blocking failures before requesting review.
