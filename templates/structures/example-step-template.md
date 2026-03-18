# Example step template

Use this template for every numbered step file in `examples/`. Copy it,
rename it with the correct zero-padded prefix (`01-`, `02-`, etc.), and
replace all `<!-- ... -->` comments and placeholder values.

---

## File body

```markdown
# Step {{NN}}: {{STEP_TITLE}}

**Prompt / skill used:** `{{PATH_TO_PROMPT_OR_SKILL}}`
**Input:** {{WHAT_THIS_STEP_RECEIVES}}
**Output:** {{WHAT_THIS_STEP_PRODUCES}}
**Human review gate:** {{WHAT_TO_CHECK_BEFORE_NEXT_STEP}}

---

## {{CONTEXT_SECTION_TITLE}}

<!-- Optional. Include when the step requires setup, context, or
     prerequisite state that isn't obvious from the previous step.
     E.g. "After step 2 is complete, the scaffold exists at..."
     Skip this section if the transition from the previous step is
     self-evident. -->

---

## Prompt sent

<!-- Show the actual prompt used — with all {{PLACEHOLDERS}} filled in
     as they would be for this example's specific feature/task.
     Use ~~~ as the outer fence if the prompt contains inner code fences. -->

```
{{FILLED_PROMPT_TEXT}}
```

---

## Model output

<!-- Show representative output. This should look like what a well-
     calibrated model actually produces — not idealised, but not
     unusually bad either. Include a note at the top: -->

> **Note:** This is representative output. Your result will differ in
> wording but should match this structure and level of specificity.

{{REPRESENTATIVE_OUTPUT}}

---

## What to check before proceeding to step {{NEXT_STEP_NUMBER}}

<!-- The review gate. A checklist of specific, verifiable things to
     confirm before moving on. Each item must be checkable — not
     "looks good" but a concrete observable state.
     Frame failures as corrections: "If X is wrong, do Y." -->

**Review gate — verify:**

- [ ] {{SPECIFIC_CHECKABLE_CONDITION_1}}
- [ ] {{SPECIFIC_CHECKABLE_CONDITION_2}}

**In this example:** {{ONE_OR_TWO_SENTENCES_ON_WHAT_TO_WATCH_FOR_IN_THIS_SPECIFIC_CASE}}
```

---

## For the final step

The last step in an example does not have a "before proceeding" gate.
Replace that section with:

```markdown
## End of pipeline

{{ONE_SENTENCE_SUMMARISING_WHAT_IS_NOW_COMPLETE}}

The next steps are:

1. {{NEXT_REAL_WORLD_ACTION_1}}
2. {{NEXT_REAL_WORLD_ACTION_2}}
```

---

## Checklist before committing

- [ ] Step number matches filename prefix (`01-`, `02-`, etc.)
- [ ] All `{{PLACEHOLDERS}}` filled with example-specific values
- [ ] Prompt text shows filled-in placeholders, not raw `{{VARIABLE}}` tokens
- [ ] Model output is representative, not idealised
- [ ] Review gate items are specific and verifiable
- [ ] Step added to the example's `README.md` steps table
- [ ] Entry added to `CHANGELOG.md` under `[Unreleased]`
- [ ] Change proposal submitted and approved before files were created
