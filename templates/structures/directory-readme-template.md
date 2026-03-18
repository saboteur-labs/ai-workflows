# Directory README template

Use this template for every new `README.md` placed inside a content
directory (`guides/`, `prompts/`, `skills/`, `examples/`, or a
subdirectory of any of these). Copy it, adapt the intro paragraph and
table structure to match the directory type, and replace all
`<!-- ... -->` comments.

---

## For guide subdirectories

```markdown
# guides/{{SUBDIRECTORY_NAME}}/

<!-- One or two sentences describing what this subdirectory covers
     and what a developer will find here. -->

| File                                   | Status     | Description                  |
| -------------------------------------- | ---------- | ---------------------------- |
| [`{{filename}}.md`](./{{filename}}.md) | {{STATUS}} | {{ONE_SENTENCE_DESCRIPTION}} |

<!-- STATUS values:
     ✅ Done  — complete content
     🔲 Stub  — placeholder with outline, not yet written -->
```

---

## For prompt category subdirectories

```markdown
# prompts/{{CATEGORY}}/

<!-- One or two sentences describing what kinds of tasks this category
     covers and when a developer would reach for prompts here. -->

| Prompt                                 | Budget                | Description                  |
| -------------------------------------- | --------------------- | ---------------------------- |
| [`{{filename}}.md`](./{{filename}}.md) | {{low\|medium\|high}} | {{ONE_SENTENCE_DESCRIPTION}} |
```

---

## For examples subdirectories

```markdown
# examples/{{EXAMPLE_NAME}}/

<!-- One sentence: what task or workflow this example demonstrates. -->

**Feature / task used:** {{CONCRETE_FEATURE_OR_TASK}}

| Step | File                                           | Prompt / skill                |
| ---- | ---------------------------------------------- | ----------------------------- |
| 1    | [`01-{{step-name}}.md`](./01-{{step-name}}.md) | `{{path/to/prompt-or-skill}}` |
```

---

## General rules

- Column headers must exactly match the examples above — CI checks
  README tables for consistency
- Status column uses only `✅ Done` or `🔲 Stub` — no other values
- Budget column uses only `low`, `medium`, or `high` — no other values
- Every file in the directory must have a row in the table — no omissions
- Descriptions are one sentence, sentence case, no trailing period
- Links are relative — never absolute URLs for internal files

---

## Checklist before committing

- [ ] Table column headers match the canonical format above
- [ ] Every file in the directory has a row in the table
- [ ] No `{{PLACEHOLDER}}` tokens remaining
- [ ] Status values are only `✅ Done` or `🔲 Stub`
- [ ] All links resolve to real files
- [ ] Change proposal submitted and approved before files were created
