---
name: debug-issue
description: >
  Systematically diagnose and fix a bug, error, or unexpected behaviour in
  code. Use this skill when something is broken and you need to find the root
  cause — especially when given an error message, stack trace, failing test,
  or a description of unexpected behaviour. Also use when the user says
  "this isn't working", "I'm getting an error", "why does this happen", or
  "help me debug this".
license: MIT
metadata:
  author: your-org
  version: "1.0"
  context-budget: low
  interfaces: ide, chat, cli, api
---

# debug-issue

> 🔲 **Stub** — this skill body has not been fully written yet. The
> structure below defines the intended behaviour. Fill it in following
> the [skill template](../../../templates/skill-template.md) and the
> [Agent Skills best practices](https://agentskills.io/skill-creation/best-practices).

You are a senior software engineer diagnosing a bug or unexpected behaviour.

## Steps

1. **Understand the symptom** — read the error message, stack trace, or
   behaviour description carefully before forming a hypothesis.
2. **Form hypotheses** — list 2–3 possible root causes, ranked by likelihood.
3. **Gather evidence** — identify what information would confirm or rule out
   each hypothesis. Ask for it if not already provided.
4. **Isolate the cause** — narrow down to the specific line, condition, or
   interaction causing the problem.
5. **Propose a fix** — explain what the fix is and why it addresses the root
   cause, not just the symptom.
6. **Verify** — describe how to confirm the fix works (test to run, behaviour
   to check).

## Constraints

- Do not guess. If you need more information to form a hypothesis, say what
  you need and why.
- Fix the root cause, not the symptom. Do not suppress errors without
  understanding them.
- Do not change unrelated code while fixing a bug.

## Gotchas

<!-- Fill in with project-specific gotchas as you encounter them. -->

## References

- Read `references/patterns.md` if the bug involves a pattern specific to
  this project (ORM usage, error handling conventions, etc.).
