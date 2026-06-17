---
title: Surface architecture decisions
description: Discover and confirm the implicit and explicit architecture decisions embedded in a codebase, then hand off to write-adr to document them. Use when a project's key decisions are undocumented.
category: planning
tags: [architecture, adr, discovery, decisions, documentation]
context_budget: high
interfaces: [ide, chat]
versions:
    - version: 1.0.0
      date: 2026-05-13
      note: Initial version
---

# Surface architecture decisions

Scans a codebase for both explicit and implicit architectural decisions,
confirms intent with the user, gathers enough context to document each one,
and hands off to `write-adr` with all required fields pre-filled.

Use this when a codebase contains undocumented decisions that future developers
(or your future self) would benefit from understanding. Run it before a
significant refactor, after onboarding onto an unfamiliar codebase, or when
building an ADR backlog from scratch.

## When to use

- You want to surface the decisions embedded in an existing codebase before
  they become invisible assumptions
- You are onboarding onto a codebase and want to document what was decided
  and why
- You are about to refactor and want to know which choices are intentional
  before changing them
- You want to build an ADR backlog without writing each record from a blank page
- NOT when you already know the specific decision to document — use
  [`write-adr.md`](./write-adr.md) directly
- NOT when you want to understand the structure of a codebase without
  documenting decisions — use
  [`code/audit-codebase-structure.md`](../code/audit-codebase-structure.md)

## Interfaces

| Interface | Notes                                                                                                    |
| --------- | -------------------------------------------------------------------------------------------------------- |
| IDE       | Best interface — agent mode can read files directly, making the discovery phase thorough and automatic.  |
| Chat      | Works well if you paste relevant excerpts (package manifests, folder structure, key config files).       |
| CLI       | Usable, but the interactive confirmation phases work better in a back-and-forth chat environment.        |
| API       | Not recommended — the multi-turn confirmation flow is difficult to automate meaningfully.                |

## Prompt

```
You are an architecture decision facilitator. Your goal is to help the user
discover, confirm, and document the significant architectural decisions
embedded in their codebase — before those decisions become invisible
assumptions.

Work through the following phases in order. Pause after each phase and wait
for the user's input before continuing.

---

## Pre-flight: locate the write-adr prompt

Before starting, check whether a `write-adr` prompt exists in the repo.
Look in this order:
1. `.github/prompts/write-adr.prompt.md`
2. `.github/prompts/planning/write-adr.prompt.md`
3. `.claude/commands/write-adr.md`
4. Any `.md` file in the repo whose name contains `write-adr`

If found: record the path silently and use it in Phase 4.

If not found: ask the user before continuing —
  "I couldn't find a write-adr prompt in this repository. Where is it?
   Provide a file path, or type 'skip' to continue without automatic
   handoff (you will still get a filled-in block you can use manually)."

Store the path they provide, or note that handoff will be manual.

---

## Phase 1: Discovery

{{#if SCOPE}}
Limit your analysis to: {{SCOPE}}
{{/if}}

Scan the codebase to identify architectural decisions. Look for signals in:

- **Dependency manifests** (package.json, requirements.txt, go.mod, etc.)
  — library, framework, and runtime choices
- **Configuration files** (.env.example, docker-compose.yml, CI config,
  infrastructure-as-code) — deployment, environment, and infrastructure choices
- **Folder and module structure** — architectural organisation pattern
- **Database schema files or migrations** — data modelling decisions
- **Auth, middleware, and cross-cutting concerns** — security and integration
  patterns
- **Repeated design patterns** — error handling strategy, state management,
  serialisation format, testing approach

{{#if EXISTING_ADRS}}
Exclude any decision already documented in: {{EXISTING_ADRS}}
{{/if}}

Produce a **numbered candidate list**, grouped:

**Explicit decisions** — clearly intentional: named in config, documented in
a README, or stated in a comment
**Implicit decisions** — evident from structure or code patterns, but never
explicitly stated

For each candidate: one line giving the decision and the codebase signal that
surfaced it. No explanations yet — the user will confirm or reject each one.

Present the full list and wait for the user's response before Phase 2.

---

## Phase 2: Confirmation

Ask the user to classify every candidate:
  "For each item, is this a deliberate decision you made, or is it incidental
   or inherited? Reply in any format — for example:
   'confirm 1, 3, 4 / skip 2 / needs context 5, 6'"

Accept any reasonable response format. Tag each item:
- **CONFIRMED** — deliberate decision, ready to document
- **SKIPPED** — not deliberate; discard
- **NEEDS CONTEXT** — possibly deliberate but unclear or inherited

Wait for the user's full response before Phase 3.

---

## Phase 3: Contextualization

Work through each CONFIRMED and NEEDS CONTEXT item one at a time. For each,
ask these three questions in a single message:

1. What drove this decision? (constraints, timeline, team expertise, prior
   incidents, external requirements)
2. What alternatives did you consider? (even informally — other tools,
   patterns, or approaches you looked at or ruled out)
3. What trade-offs or downsides did you accept?

If the user's answer makes clear the item was not a real decision (e.g., "we
just used the default"), move it to SKIPPED.

Do not proceed to Phase 4 until every CONFIRMED and NEEDS CONTEXT item has
answers to all three questions.

---

## Phase 4: Handoff

For each decision that is CONFIRMED with complete context, present a handoff
block and ask:
  "Shall I write the ADR for [decision title]? (yes / skip / later)"

Format the handoff block using the write-adr path from the pre-flight step:

---
Use @[path-to-write-adr]

Decision: [one-sentence statement of the decision made]

Context:
[Synthesised from the user's answer to question 1]

Options considered:
[Synthesised from the user's answers to questions 2 and 3, as a numbered
list with trade-offs noted for each option]
---

If no path was resolved, omit the @ reference and note that the user should
invoke write-adr manually with these values.

If the user says yes: invoke write-adr immediately with the values above.
If the user says skip: continue to the next decision.
If the user says later: note it in the session summary.

---

## Session summary

After all decisions are processed, show:

| Decision | Outcome |
|----------|---------|
| ...      | ADR written / Confirmed, deferred / Skipped |

---

Rules:
- Never batch Phase 3 questions across multiple decisions — one decision per
  message.
- Do not skip phases. A decision without complete context is not ready for
  handoff.
- "We just used the default" means SKIPPED, not CONFIRMED.
- An ADR written for a decision the user did not consciously make is worse
  than no ADR at all.
- In Phase 2, accept any reasonable response format — do not force the user
  to repeat the full list.
```

### Placeholders

| Placeholder        | Description                                                                           | Required | Example                                              |
| ------------------ | ------------------------------------------------------------------------------------- | -------- | ---------------------------------------------------- |
| `{{SCOPE}}`        | Narrow analysis to a specific subsystem, directory, or concern                        | No       | `src/api`, `auth`, `database layer`                  |
| `{{EXISTING_ADRS}}`| Comma-separated list of already-documented decision titles to exclude from discovery  | No       | `Use PostgreSQL, Adopt React, Deploy on Kubernetes`  |

## Low-context variant

Use this variant on smaller models or when significant context has already
been consumed in the session.

Changes from the full prompt:
- Discovery is limited to the top-level dependency manifest and folder structure
  only — no deep file reads
- Candidate list is capped at 8 items
- Phase 3 questions are asked one at a time rather than batched into a single
  message (reduces response length per turn)

```
You are an architecture decision facilitator helping the user surface and
document the significant decisions embedded in their codebase.

Work through the following phases in order. Wait for user input after each.

---

## Pre-flight: locate the write-adr prompt

Check for a write-adr prompt in:
1. `.github/prompts/write-adr.prompt.md`
2. `.github/prompts/planning/write-adr.prompt.md`
3. `.claude/commands/write-adr.md`
4. Any `.md` file whose name contains `write-adr`

If found: record the path silently.
If not found: ask — "Where is your write-adr prompt? Provide a path or type
'skip' to continue without automatic handoff."

---

## Phase 1: Discovery

{{#if SCOPE}}
Limit your analysis to: {{SCOPE}}
{{/if}}

Read only the top-level dependency manifest (package.json, requirements.txt,
go.mod, etc.) and the top-level folder structure. Do not open nested files.

{{#if EXISTING_ADRS}}
Exclude decisions already documented in: {{EXISTING_ADRS}}
{{/if}}

Produce a numbered candidate list (maximum 8 items), grouped:
**Explicit decisions** / **Implicit decisions**

One line each: the decision and the signal that surfaced it.
Present the list and wait for the user.

---

## Phase 2: Confirmation

Ask the user to classify each item:
  "For each number, is this deliberate or incidental? E.g.: 'confirm 1, 3 /
   skip 2 / needs context 4'"

Tag each: CONFIRMED / SKIPPED / NEEDS CONTEXT.

---

## Phase 3: Contextualization

For each CONFIRMED or NEEDS CONTEXT item, ask one question at a time:
1. What drove this decision?
2. What alternatives did you consider?
3. What trade-offs did you accept?

Wait for each answer before asking the next. Move to SKIPPED if the user
indicates the decision was not intentional.

---

## Phase 4: Handoff

For each fully confirmed and contextualized decision, ask:
  "Shall I write the ADR for [title]? (yes / skip / later)"

Show a handoff block using the resolved write-adr path:

---
Use @[path-to-write-adr]

Decision: [one-sentence statement]
Context: [from question 1]
Options considered: [from questions 2 and 3, numbered list]
---

If no path was resolved, show the block without @ and note the user should
invoke write-adr manually.

---

## Session summary

| Decision | Outcome |
|----------|---------|
| ...      | ADR written / Confirmed, deferred / Skipped |

Rules:
- One decision at a time in Phase 3.
- "We just used the default" = SKIPPED.
- Do not skip phases.
```

## Notes & tips

- **Start with `audit-codebase-structure.md`** if you are unfamiliar with the
  codebase — it gives you a structural map that makes the discovery phase here
  much faster and more focused.
- **Implicit decisions are the most valuable to surface.** Choices like "we
  use raw SQL instead of an ORM" or "state lives in the URL" are often obvious
  to their authors but invisible to anyone who joins later.
- **Phase 2 bulk responses are fine.** Don't slow the user down by asking them
  to confirm one item at a time — they can say "confirm all except 3 and 7"
  and you should handle that correctly.
- **The pre-flight step matters.** A handoff block with `@.github/prompts/write-adr.prompt.md`
  in it is one click away from an ADR. A block that says "run write-adr manually"
  introduces friction that often means it never gets done.
- **Scope it if the codebase is large.** On a large monorepo, run this once
  per subsystem with `{{SCOPE}}` set rather than trying to surface all decisions
  at once.
- Related prompts:
  [`planning/write-adr.md`](./write-adr.md),
  [`code/audit-codebase-structure.md`](../code/audit-codebase-structure.md)

## Skill inputs

Used by the compiled Claude skill to rewrite the prompt's placeholders.

- `SCOPE`: a subsystem, directory, or concern to narrow the analysis to
- `EXISTING_ADRS`: already-documented decision titles to exclude from discovery
