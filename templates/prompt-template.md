# Prompt template

Use this file as the starting point for every new file in `prompts/`. Copy it,
rename it to describe the task (e.g. `refactor-for-readability.md`), place it
in the appropriate category subdirectory, and replace every `<!-- ... -->`
comment and placeholder value with real content.

---

## Frontmatter reference

```yaml
---
title: # Short, imperative phrase — "Generate unit tests for a module"

# ------------------------------------------------------------
# description: one or two sentences for the compiled Claude skill —
#   what it does AND when to use it. Drives skill auto-triggering,
#   so lead with the key use case. Kept under the ~1,536-char skill
#   listing cap. REQUIRED to compile a SKILL.md; omit to ship this
#   prompt as a Copilot prompt only. (See scripts/build-dist.js.)
# ------------------------------------------------------------
description:

category: # One of: code | planning | testing | agent-orchestration
tags: # List of lowercase keywords, e.g. [unit-test, jest, python]

# ------------------------------------------------------------
# Claude skill options (all optional):
#   argument-hint: hint shown after /command in autocomplete,
#     e.g. "[feature name]". Omit when input comes from context.
#   skill-saves-document: true — append the standard "save the
#     output" footer. Set only for prompts that produce a document
#     to save (specs, task lists, ADRs); omit for code/review output.
# ------------------------------------------------------------
# argument-hint:
# skill-saves-document: true

# ------------------------------------------------------------
# context_budget: how much context window this prompt consumes
#   low    — fits comfortably in ~2k tokens; safe for small
#            local models (e.g. 7B running in LM Studio)
#   medium — needs ~4–8k tokens; fine for most hosted models
#            and mid-size local models (13B+)
#   high   — requires 16k+ tokens; use hosted models or a
#            machine with ample VRAM; consider chunking first
# ------------------------------------------------------------
context_budget: low | medium | high

# ------------------------------------------------------------
# interfaces: where this prompt can be used as-is
#   ide   — paste into IDE plugin context / system prompt
#           (Cursor, Continue.dev, Copilot Chat, etc.)
#   chat  — paste into a chat interface (Claude.ai, ChatGPT, etc.)
#   cli   — pipe into a CLI tool (Claude Code, Aider, etc.)
#   api   — use programmatically via API or scripted automation
# List all that apply. Most prompts work in all four.
# ------------------------------------------------------------
interfaces: [ide, chat, cli, api]

# ------------------------------------------------------------
# versions: optional — track meaningful prompt revisions
# ------------------------------------------------------------
versions:
    - version: 1.0.0
      date: YYYY-MM-DD
      note: Initial version


# ------------------------------------------------------------
# review-by: optional — set for prompts that reference external
# tools, CLI flags, or library APIs that may change over time.
# Format: YYYY-MM-DD. CI will warn when this date has passed.
#   6–12 months for tool-specific content
#   18–24 months for stable conventions
# Omit entirely for prompts with no external dependencies.
# ------------------------------------------------------------
# review-by: YYYY-MM-DD

# ------------------------------------------------------------
# verified-against: optional — records sources for any external
# claims in this prompt (tool behaviour, spec requirements, etc.)
# ------------------------------------------------------------
# verified-against:
#   - url: https://...
#     date: YYYY-MM-DD
#     note: One sentence on what was verified
---
```

---

## File body

Below the frontmatter, every prompt file has five sections. Omit a section only
if it genuinely does not apply; leave the heading as a placeholder otherwise so
reviewers know it was considered.

---

```markdown
# {{TITLE}}

<!-- One or two sentences. What does this prompt do and when should you reach
     for it? Be specific — "Use this when you have an existing module and want
     to generate a full unit-test suite. Not suitable for integration tests." -->

## When to use

<!-- Bullet list of the right conditions. Also note explicitly when NOT to use
     this prompt, e.g. "Not for files over 500 lines — use the chunked variant
     instead (see examples/low-context-chunked-review)." -->

-
-

## Interfaces

<!-- Which interfaces work for this prompt and any per-interface notes.
     E.g. "IDE: paste into the system prompt field before opening the file."
         "CLI: pipe file contents in via stdin." -->

| Interface | Notes |
| --------- | ----- |
| IDE       |       |
| Chat      |       |
| CLI       |       |
| API       |       |

## Prompt

<!-- The actual prompt text. Use {{DOUBLE_BRACES}} for every value the user must
     supply before using the prompt. Keep placeholders short and uppercase.
     Add a "Placeholders" table below if there are more than two. -->
```

{{PROMPT_TEXT}}

```

### Placeholders

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{{PLACEHOLDER_1}}` | What to put here | `example value` |

## Low-context variant

<!-- If context_budget is medium or high, provide a trimmed version of the
     prompt here that fits within ~2k tokens. This makes the prompt usable on
     small local models without rewriting it from scratch.
     If context_budget is already low, write "N/A — this prompt is already
     low-context." -->

N/A

## Notes & tips

<!-- Optional. Model-specific quirks, known failure modes, improvement ideas,
     links to related prompts or skills, example outputs. -->

- Related prompts: <!-- link -->
- Related skills:  <!-- link -->
```

---

## Skill compilation sections (optional)

`scripts/build-dist.js` compiles each prompt with a `description` into a Claude
skill at `dist/claude/skills/saboteur-<name>/SKILL.md`. By default it rewrites the
`## Prompt` block's `{{PLACEHOLDERS}}` into natural-language instructions. Three
optional sections tune that output — add them after the `## Notes & tips` section:

````markdown
## Skill inputs

<!-- Maps each {{VAR}} to the phrase the skill body should use in place of it.
     Write plain nouns (no "if the user…" clauses — the conditional lead-in adds
     that). Unmapped vars fall back to a humanized name. -->

- `CONCEPT_DOCUMENT`: the concept document from this conversation or a file the user references
- `MILESTONE_SCOPE`: a milestone scope

## Skill wrap-up

<!-- Prose appended after the body: chaining offers to the next skill
     (use the namespaced /saboteur-… command), interactive resolution steps, etc.
     Avoid `## ` headings inside this section. -->

After saving, offer to run `/saboteur-break-into-tasks` next.

## Skill body

<!-- A verbatim skill body that OVERRIDES the placeholder transform entirely.
     Use only when auto-flattening reads poorly (e.g. expression conditionals or
     fenced code-paste blocks). -->

```
…full skill body, no {{placeholders}}…
```
````

## Checklist before committing

- [ ] Frontmatter is complete and valid YAML
- [ ] `description` is set (single line) so the prompt compiles to a Claude skill
- [ ] `skill-saves-document: true` set if the prompt produces a document to save
- [ ] If `## Skill inputs` is present, every `{{VAR}}` in the prompt is mapped
- [ ] `context_budget` reflects the actual token cost of the filled-in prompt
- [ ] `interfaces` list has been verified — not just assumed
- [ ] All `{{PLACEHOLDERS}}` are documented in the Placeholders table
- [ ] Low-context variant is present if `context_budget` is `medium` or `high`
- [ ] `review-by` date set if prompt references external tools or APIs
- [ ] `verified-against` entries added for any externally-sourced claims
- [ ] File is named in `kebab-case` and placed in the correct category folder
- [ ] Entry added to the parent `README.md` index table
- [ ] Entry added to `CHANGELOG.md` under `[Unreleased]`
- [ ] Change proposal submitted and approved before this file was created
