# AGENTS.md

This file tells AI agents the rules of engagement for this repository.
Read it before doing anything else. It is short by design.

---

## What this repo is

A model-agnostic knowledge base for AI-augmented development workflows.
It contains guides, a prompt library, reusable agent skills, worked
examples, and tooling. Content is designed to be read and copied into
other projects — this repo has no runtime dependencies.

The full structural overview is in
[`guides/repo-maintenance/how-this-repo-is-structured.md`](./guides/repo-maintenance/how-this-repo-is-structured.md).

---

## The single most important rule

**Propose before you act.**

Never create, modify, or delete a file without first producing a written
proposal and receiving explicit human approval. Use the proposal template:
[`templates/change-proposal-template.md`](./templates/change-proposal-template.md).

The only exception is a change explicitly described as pre-approved in the
human's instruction (e.g. "fix this broken link — no need to propose").

---

## Atomicity requirement

Every change must be complete. When you add, modify, or remove a file,
all related files that reference or depend on it must be updated in the
same proposal. Consult the dependency map before writing any proposal:
[`guides/repo-maintenance/dependency-map.md`](./guides/repo-maintenance/dependency-map.md).

A PR that adds a prompt but does not update `prompts/README.md` and
`CHANGELOG.md` will fail CI and be rejected.

---

## Landing a change

Do not base a PR on another open PR. A stacked PR lands only if its base
lands first, and if the base is merged into the default branch before the
stack is, the stacked work ends up on a branch nobody merges again — green
checks, approved review, content silently absent. Fold the work into one PR,
or wait for the base to land.

When a PR merges, confirm its content reached the base branch before deleting
its branch or moving on:

```sh
git merge-base --is-ancestor <sha> origin/development
```

A successful merge is not proof: it reports success even when it merged into
somewhere other than where the work needed to go.

---

## Guardrails you must follow

**Against hallucination:**

- Do not assert facts about external tools, specs, or libraries without
  citing a verifiable source in your proposal's "Sources" section.
- Before proposing, check your content against existing repo files for
  contradictions. If you find one, surface it as an open question rather
  than silently resolving it.
- Use `templates/` and `templates/structures/` for all new content.
  Do not invent structure.

**Against outdated information:**

- If your proposed content makes claims about external tools or standards,
  run the `skills/freshness-check/` skill against your
  draft first and include the output in your proposal.
- Flag any content with a natural shelf life using the `review-by`
  frontmatter field. See `templates/prompt-template.md` for usage.
- If a file you are modifying has a `verified-against` or `review-by`
  field, update it to reflect your verification.

**Against human error:**

- All `{{PLACEHOLDERS}}` must be filled before proposing. None may appear
  in final content (outside code fences).
- All internal links must resolve to real files. Check before proposing.
- No `🔲 Stub` markers may remain in proposed content.
- Consult the dependency map. Incomplete change sets will fail CI.

---

## What you may not do without explicit human instruction

- Delete any file
- Rename or move any file or directory
- Change the frontmatter specification (fields, allowed values)
- Modify `.github/workflows/` files
- Modify `AGENTS.md`, `CONTRIBUTING.md`, or `templates/`
- Add a new top-level directory

---

## Skill to use for repo work

Load [`skills/repo-maintenance/`](./skills/repo-maintenance/) before
beginning any task that involves adding, modifying, or reviewing repo
content. It contains the full operating instructions for working in this
repo correctly.

---

## Where to start for common tasks

| Task                      | Where to look first                                                                   |
| ------------------------- | ------------------------------------------------------------------------------------- |
| Add a new prompt          | `templates/prompt-template.md`, `guides/repo-maintenance/dependency-map.md`           |
| Add a new skill           | `templates/skill-template.md`, `guides/repo-maintenance/dependency-map.md`            |
| Add a new guide           | `templates/structures/guide-template.md`, `guides/repo-maintenance/dependency-map.md` |
| Review repo for staleness | `skills/freshness-check/`                                                             |
| Understand repo structure | `guides/repo-maintenance/how-this-repo-is-structured.md`                              |
| Propose any change        | `templates/change-proposal-template.md`                                               |
