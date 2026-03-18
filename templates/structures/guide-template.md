# Guide template

Use this template for every new file in `guides/`. Copy it, rename it
in `kebab-case.md`, place it in the appropriate subdirectory, and replace
all `<!-- ... -->` comments and placeholder values.

---

## Frontmatter reference

```yaml
---
title: # Short descriptive title — matches the H1 heading below
category: # One of: context | workflows | models | agent-patterns | repo-maintenance

# ------------------------------------------------------------
# is_evergreen: whether this content is time-sensitive
#   true  — no external tool versions or release-dependent claims;
#           no review-by date needed
#   false — contains claims about specific tools, versions, or
#           settings; review-by date required
# ------------------------------------------------------------
is_evergreen: true | false

# Required if is_evergreen is false
review-by:
    YYYY-MM-DD # 6–12 months for fast-changing tools;
    # 18–24 months for slow-changing content

# Optional — use when the guide makes claims about external tools
# or specifications that have been explicitly verified
verified-against:
    - url: https://...
      date: YYYY-MM-DD
      note: One sentence on what was verified
---
```

---

## File body

```markdown
# {{TITLE}}

<!-- One to three sentences. What does this guide cover and when should
     a developer reach for it? Be specific about the problem it solves.
     Do not use "This guide covers..." — state what the reader will
     know or be able to do after reading it. -->

---

## {{FIRST_MAJOR_SECTION}}

<!-- Most guides open with the core concept, decision, or principle.
     Use plain declarative prose. No hedging language. State things
     directly. -->

---

## {{SECOND_MAJOR_SECTION}}

<!-- Guides typically have 3–6 major sections. Use ## for sections,
     ### for subsections. Rarely go deeper than ###. -->

---

## {{DECISION_OR_REFERENCE_SECTION}}

<!-- Most guides benefit from a decision table, quick-reference card,
     or checklist near the end — something the reader can scan on
     return visits without re-reading the whole guide. -->

| Situation       | Recommended action |
| --------------- | ------------------ |
| {{SITUATION_1}} | {{ACTION_1}}       |

---

## Further reading

<!-- Link to related guides, prompts, and skills that extend or
     depend on this guide's content. Use relative paths only. -->

- [`path/to/related.md`](./path/to/related.md) — one sentence description
```

---

## Checklist before committing

- [ ] Frontmatter is complete
- [ ] `is_evergreen: false` guides have a `review-by` date set
- [ ] All external claims have a source in `verified-against` or are
      flagged as open questions
- [ ] No hedging language ("try to", "if possible", "where appropriate")
      for things that are actually required
- [ ] No `{{PLACEHOLDER}}` tokens remaining
- [ ] All internal links verified to resolve to real files
- [ ] Entry added to the parent directory `README.md` status table
- [ ] Entry added to `CHANGELOG.md` under `[Unreleased]`
- [ ] Change proposal submitted and approved before files were created
