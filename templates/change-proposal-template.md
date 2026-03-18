# Change proposal template

Use this template for every proposed addition, modification, or deletion
in this repo — whether you are an AI agent or a human contributor. A
proposal must be approved before any files are created, modified, or deleted.

Copy this template, fill it in, and submit it for review. Do not proceed
until you have received explicit approval.

---

```markdown
# Change proposal: [short title]

**Proposed by:** [your name / agent name]
**Date:** YYYY-MM-DD
**Type:** [New content / Modification / Deletion / Structural change]

---

## What is being proposed

[2–4 sentences. What change is being made, where, and what it adds or
improves. Be specific — "add a prompt for X" not "improve the prompt
library".]

## Why this change is needed

[1–3 sentences. What gap or problem does this address? If this was
requested by a human, quote or paraphrase the request.]

---

## Complete file list

All files that will be created, modified, or deleted in this change.
Derived from `guides/repo-maintenance/dependency-map.md`.

### Created

- [ ] `path/to/new-file.md` — [one sentence: what it contains]

### Modified

- [ ] `path/to/existing-file.md` — [specific section or row being changed]
- [ ] `CHANGELOG.md` — add entry under `[Unreleased]`
- [ ] `[relevant README].md` — add/update index table row

### Deleted

- [ ] `path/to/deleted-file.md` — [reason for deletion]

**Dependency map confirmed:** [Yes / No — if No, explain why a coupling
is intentionally omitted]

---

## Proposed content

[For new files: paste the complete draft content here, using the correct
template from `templates/` or `templates/structures/`.]

[For modifications: show the specific before/after for each changed
section. Do not paste the full file — show only what changes.]

[For deletions: confirm there are no remaining links to the deleted file,
or list the files where links will be removed.]

---

## Sources

[List every external claim in the proposed content and its source.
External claims are assertions about tools, specifications, libraries, or
systems outside this repo.]

| Claim         | Source URL | Verified date |
| ------------- | ---------- | ------------- |
| [exact claim] | [URL]      | YYYY-MM-DD    |

**Freshness check run:** [Yes / No]
[If Yes: paste the freshness report output or summarise its findings.]
[If No: explain why (e.g. "no external claims in this change").]

---

## Validation checklist

- [ ] All `{{PLACEHOLDERS}}` filled (none remain outside code fences)
- [ ] No `🔲 Stub` markers in proposed content
- [ ] All internal links resolve to real files
- [ ] Correct template used for content type
- [ ] Frontmatter complete and valid (prompts and skills)
- [ ] `context_budget` / `context-budget` set correctly
- [ ] `review-by` field added for any time-sensitive content
- [ ] Dependency map couplings satisfied (see file list above)
- [ ] Content checked against existing repo files for contradictions
- [ ] Style guide followed (sentence case, no hedging language, specific
      over vague)

---

## Open questions

[List any unresolved questions that require human input before the change
can proceed. If none, write "None".]

1. [Question requiring human decision before proceeding]

---

## What this proposal does NOT change

[Explicitly note the boundaries of this change — what related things are
intentionally left untouched. This prevents scope creep and makes review
easier.]

- Does not affect: [list]
- Explicitly deferred: [list, with brief reason]
```
