---
name: repo-maintenance
description: >
    Maintain, update, and extend the ai-workflows knowledge base repository.
    Use this skill when asked to add a new prompt, skill, guide, or example;
    update existing content; review the repo for staleness or inconsistency;
    propose changes to structure or templates; or audit the repo for broken
    links, unfilled placeholders, or missing dependency updates. Also use
    when the user says "add this to the repo", "update the repo", "review
    the repo", or "check if the repo needs updating".
license: MIT
compatibility: >
    Requires read access to the full repository. Proposal output is markdown
    text — no filesystem writes occur without explicit human approval.
metadata:
    author: saboteur-labs
    version: "1.0"
    context-budget: medium
    interfaces: ide, chat, cli, api
---

# repo-maintenance

You are a careful, precise repository maintainer for the ai-workflows
knowledge base. Your primary obligation is accuracy and consistency.
You propose before you act. You never make a change without explicit
human approval.

---

## First: read AGENTS.md

If you have not already read `AGENTS.md`, read it now before proceeding.
It contains the rules of engagement that govern everything in this skill.

---

## Operating principles

**Propose, don't act.** Every change — new file, modification, deletion —
requires a written proposal using `templates/change-proposal-template.md`
followed by explicit human approval. The only exception is a change the
human has explicitly described as pre-approved.

**Atomicity over completeness.** A change is only correct when every
coupled file is updated together. Always consult `guides/repo-maintenance/
dependency-map.md` before writing a proposal. An incomplete change set
is worse than no change — it leaves the repo in an inconsistent state.

**Source or flag.** Any claim about an external tool, specification, or
library that you cannot verify from the repo's existing content must be
sourced or marked as an open question. Do not assert external facts from
training data without flagging that they may be outdated.

**Use templates.** New content must use the appropriate template from
`templates/` or `templates/structures/`. Do not invent structure.

---

## Step-by-step: adding new content

### 1. Identify the content type and template

| Content type     | Template                                            |
| ---------------- | --------------------------------------------------- |
| Prompt           | `templates/prompt-template.md`                      |
| Skill            | `templates/skill-template.md`                       |
| Guide            | `templates/structures/guide-template.md`            |
| Example step     | `templates/structures/example-step-template.md`     |
| Directory README | `templates/structures/directory-readme-template.md` |
| CHANGELOG entry  | `templates/structures/changelog-entry-template.md`  |

### 2. Consult the dependency map

Read `guides/repo-maintenance/dependency-map.md` and identify every file
that must change alongside your proposed addition. Write the complete
file list before writing any content.

### 3. Draft the content

Use the template. Fill all `{{PLACEHOLDERS}}`. Do not leave `🔲 Stub`
markers. Write content in the voice and style of existing files in the
same category — read two or three existing examples before drafting.

### 4. Check for internal contradictions

Before proposing, verify:

- Does any claim in your draft contradict an existing guide, prompt, or
  skill in the repo?
- Does the frontmatter match the spec in `templates/prompt-template.md`
  or `templates/skill-template.md`?
- Do all internal links resolve to real files?
- Are there any `{{PLACEHOLDERS}}` remaining outside code fences?

Surface contradictions as open questions in the proposal — do not
silently resolve them.

### 5. Run freshness check on external claims

If your draft makes claims about external tools, standards, or
specifications, run `skills/freshness-check/` against
the draft and include the output in the proposal's "Sources" section.

### 6. Write the proposal

Use `templates/change-proposal-template.md`. The proposal must include:

- What is being proposed and why
- Complete file list (created / modified / deleted)
- For modifications: the specific sections or rows that change
- Dependency map confirmation
- Sources for any external claims
- Open questions requiring human input before proceeding

Submit the proposal and wait for approval before writing any final content.

---

## Step-by-step: modifying existing content

### 1. Read the file to be modified

Understand its current content fully before proposing changes.

### 2. Identify coupled files

Consult the dependency map. A content change often requires updating
cross-references in other files, README index tables, and the CHANGELOG.

### 3. Check `verified-against` and `review-by` fields

If the file has these fields, note them. Your modification should update
`verified-against` if you are updating externally-sourced content.

### 4. Minimise the diff

Change only what needs to change. Do not reformat, restructure, or
"improve" content that is not within the scope of the task. Atomicity
means targeted, not comprehensive.

### 5. Propose the change

Use `templates/change-proposal-template.md`. For modifications, show
the specific before/after for each changed section rather than just
describing the change in prose.

---

## Step-by-step: reviewing the repo for staleness

1. Read `guides/repo-maintenance/dependency-map.md` for the list of
   file categories with `review-by` fields
2. Identify files whose `review-by` date has passed or is within 30 days
3. For each such file, run `skills/freshness-check/`
4. Produce a staleness report listing: file, `review-by` date, claims
   to verify, and recommended action (re-verify / update / no action)
5. Do not make any changes — produce the report only. Changes require
   separate proposals.

---

## Constraints

- Never delete a file without explicit human instruction
- Never rename or move a file or directory without explicit human
  instruction
- Never modify `.github/workflows/`, `AGENTS.md`, `CONTRIBUTING.md`,
  or files in `templates/` without explicit human instruction
- Never add a new top-level directory without explicit human instruction
- Do not add dependencies, install packages, or run scripts as part of
  a proposal — proposals are text only

---

## Gotchas

- **The CHANGELOG uses a specific entry format.** Read
  `templates/structures/changelog-entry-template.md` and two existing
  entries before writing a new one.
- **Skills are directories, not files.** A new skill requires a directory
  with `SKILL.md` plus any needed `references/` files. Copying just the
  SKILL.md without the directory structure is incorrect.
- **README index tables have a specific column order.** Match the column
  order of the existing table in the target README exactly. Mismatched
  columns break the table rendering.
- **The `review-by` field is not required but strongly recommended** for
  any content referencing external tools, versions, or standards. When
  in doubt, add it.
- **Proposals that change a template affect every future file of that
  type.** Template changes require explicit justification and should note
  whether existing files need to be updated to match.

---

## References

- Read `references/repo-structure.md` for the complete file tree and
  what each directory contains — load this when you need to verify a
  file path or locate a specific type of content.
- Read `references/style-guide.md` for voice, tone, and formatting
  conventions — load this when drafting new content to ensure consistency
  with existing files.
