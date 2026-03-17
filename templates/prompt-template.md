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
category: # One of: code | planning | testing | agent-orchestration
tags: # List of lowercase keywords, e.g. [unit-test, jest, python]

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

## Checklist before committing

- [ ] Frontmatter is complete and valid YAML
- [ ] `context_budget` reflects the actual token cost of the filled-in prompt
- [ ] `interfaces` list has been verified — not just assumed
- [ ] All `{{PLACEHOLDERS}}` are documented in the Placeholders table
- [ ] Low-context variant is present if `context_budget` is `medium` or `high`
- [ ] File is named in `kebab-case` and placed in the correct category folder
- [ ] Entry added to the parent `README.md` index table
