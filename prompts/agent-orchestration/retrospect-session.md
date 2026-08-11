---
title: Retrospect a session into durable rules
description: Review a finished session for the corrections, re-explanations, and missing context that slowed it down, and convert them into a small set of candidate rules — each routed to the artifact that should carry it. Use when the user says "retrospect this session", "what slowed us down", "we kept going in circles", "you keep making that mistake", "turn that into a rule", or "how do I stop this happening again"; when the user asks why a session took more correction than it should have; or when the user is about to hand-edit CLAUDE.md or AGENTS.md, so the edit follows evidence rather than the most recent annoyance. Also offer it proactively at the end of a session that needed the same correction more than once. This skill produces standing rules for future sessions — for blog material from a session, use extract-postable-insights instead. Not for sessions that went well.
category: agent-orchestration
tags: [retrospective, self-improvement, tuning, feedback, rules, learning]
context_budget: low
interfaces: [ide, chat, cli, api]
versions:
    - version: 1.0.0
      date: 2026-08-07
      note: Initial version
    - version: 1.1.0
      date: 2026-08-11
      note: Trigger-oriented description; print the log entry when appending it
---

# Retrospect a session into durable rules

Reviews a finished session for the places where the model needed correcting,
had to be told something it should have been able to find, or repeated a
mistake — and turns those into candidate rules, each pointed at the specific
file that should carry it.

Where `summarize-for-handoff` carries state from one session to the next,
this carries lessons from one session to every session after it. The output
is a shortlist to approve, not an edit — nothing is changed by this prompt.

## When to use

- At the end of a session that took more correction than it should have
- When you notice you have given the same instruction in three sessions running
- Before editing `CLAUDE.md` / `AGENTS.md` by hand — run this first so the edit
  is driven by evidence rather than by the most recent annoyance
- As the input to `skills/improve-agent/` when the artifact at fault is a
  subagent definition
- NOT after a session that went well — there is nothing to learn and the model
  will invent rules to fill the output format
- NOT as a substitute for fixing the immediate problem. Retrospect after the
  work is done, not instead of doing it
- NOT on a session whose problems were all one-offs specific to that codebase
  area — those belong in code comments, not in standing instructions

## Interfaces

| Interface | Notes                                                                                              |
| --------- | --------------------------------------------------------------------------------------------------- |
| IDE       | Run as the last turn of a session, while the full session is still in context.                     |
| Chat      | Run as the last message; the model reads its own history, so `{{SESSION_CONTEXT}}` can be left out. |
| CLI       | Pipe a transcript in via `{{SESSION_CONTEXT}}` when retrospecting a session that has ended.         |
| API       | Run in batch over stored transcripts to find rules that recur across many sessions.                |

## Prompt

```
Retrospect this session. Find what went wrong, and turn only the parts worth
keeping into candidate rules.

{{#if SESSION_CONTEXT}}
Session to retrospect:
{{SESSION_CONTEXT}}
{{/if}}

{{#if PRIOR_RETROSPECTIVES}}
Previous retrospectives for this project:
{{PRIOR_RETROSPECTIVES}}
{{/if}}

Artifacts that may be tuned:
{{TUNABLE_ARTIFACTS}}

If that list is empty, identify the candidate artifacts yourself and list
them before routing anything. If you cannot inspect the filesystem, name the
kind of artifact instead and mark the destination unresolved — do not guess
at a filename.

Step 1 — Signals (do not write rules yet):
List the concrete moments where the session lost time or went off course.
A signal is one of:
- a correction the user made to your output or approach
- context you needed that you asked for, guessed at, or got wrong
- a step you repeated, or a mistake you made more than once
- an instruction you were given that you did not follow
- a convention you had to be told, that the codebase already demonstrates

For each signal, give the evidence — quote or cite the specific turn — and
what it cost (a turn, a wrong file edited, a rewrite, a failed test run).

If the session ran clean, say so and stop here. Do not proceed to Step 2.
An empty retrospective is a valid result.

Step 2 — Candidate rules:
Promote a signal to a candidate rule only if it passes both tests:
- It would apply again. A rule that only fires on this one file or this one
  bug is not a rule.
- It is checkable. Someone reading the next session's output must be able to
  say whether the rule was followed. "Be more careful" fails this test;
  "Run the module's own test file before editing it, not the full suite"
  passes.

For each candidate rule give:

**Rule:** [one sentence, imperative]
**Evidence:** [which signals from Step 1 support it, and how many times it fired.
               If previous retrospectives were supplied, check them: a signal
               that also appears there — including one previously discarded —
               has fired again, and you must say so here.]
**Destination:** [exactly one — see the routing table below]
**Confidence:** [high — appears in a previous retrospective too, or fired more
                        than once this session, or once at real cost
                 low  — fired once, cheaply; worth watching, not yet worth writing]

Routing table:
| If the fix belongs in…                                      | Destination           |
| ----------------------------------------------------------- | --------------------- |
| how this project must always be worked on                   | project instructions  |
| the wording or steps of a specific prompt or skill you ran   | that prompt or skill  |
| the behaviour of a specific subagent                         | that agent definition |
| a fact about the codebase that the code itself should state  | the code or its docs  |
| nothing — it was a one-off                                   | discard               |

Only name a destination that appears in the list of tunable artifacts — the
one supplied above, or the one you listed yourself. If the right destination
is not in that list, say so rather than picking the nearest available one.

Step 3 — Discarded:
List the signals you did not promote and why in a few words each. This
section matters: it is the record that a one-off was considered and
deliberately not turned into a standing rule.

Constraints:
- At most five candidate rules. If you have more, the session had one
  underlying problem and you have listed its symptoms — find the root cause
  and write that instead.
- Do not propose a rule that duplicates or contradicts an instruction already
  present in the tunable artifacts. If one nearly matches, propose an edit to
  the existing rule instead of a new one.
- Do not write the edits. This prompt produces a shortlist for approval.
```

### Placeholders

| Placeholder                | Description                                                                                                                                             | Example                                                                                     |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| `{{SESSION_CONTEXT}}`      | Optional. The transcript to retrospect. Remove the block when the session is still open and already in context.                                          | _(paste a transcript, or leave blank)_                                                      |
| `{{PRIOR_RETROSPECTIVES}}` | Optional. Previous retrospectives for this project. Supplying them is what makes recurrence checkable rather than remembered. Remove the block if none.  | _(paste the retrospective log, or leave blank)_                                             |
| `{{TUNABLE_ARTIFACTS}}`    | Optional. The files that may carry a rule. Supplying them constrains the routing; leave blank to have the model find and list the candidates itself.     | `CLAUDE.md (project root), .claude/agents/reviewer.md, prompts/code/generate-unit-tests.md` |

## Low-context variant

This prompt is already `context_budget: low`. For a long transcript that will
not fit, run it over the corrections alone rather than the full session:

```
Here are the points in a session where I corrected the model:
{{CORRECTIONS}}

For each, say whether it would recur in other sessions. For the ones that
would, write one checkable rule and name which file should carry it:
{{TUNABLE_ARTIFACTS}}. Ignore the rest.
```

## Notes & tips

- The evidence bar is what makes this useful. Without it the model promotes
  every mild correction to a standing rule and the instruction file doubles
  in size each month, which degrades every session that reads it.
- Low-confidence rules are worth leaving in the log rather than writing into
  an instruction file. A rule that fires a second time in a later session
  graduates to high confidence with no further argument — which only works
  if the log is passed back in as `{{PRIOR_RETROSPECTIVES}}`. Used without
  it, the prompt still works, but the recurrence check falls back to memory.
- The Step 3 discard list is the part people skip and then regret. Without
  it the same one-off gets re-litigated in every retrospective — and a
  discarded signal that shows up again is exactly the evidence that should
  promote it.
- If a rule keeps being written but sessions keep violating it, the rule is
  in the wrong place — an instruction the model reads but does not act on
  usually needs to be a hook or a check, not a sentence.
- Related prompts:
  [`agent-orchestration/summarize-for-handoff.md`](./summarize-for-handoff.md),
  [`agent-orchestration/self-critique-loop.md`](./self-critique-loop.md)
- Related skills:
  [`skills/improve-agent/`](../../skills/improve-agent/SKILL.md)
- Related guides:
  [`guides/agent-patterns/human-in-the-loop.md`](../../guides/agent-patterns/human-in-the-loop.md)

## Skill inputs

Used by the compiled Claude skill to rewrite the prompt's placeholders.

- `SESSION_CONTEXT`: the session to retrospect — this conversation, or a transcript the user references
- `PRIOR_RETROSPECTIVES`: this project's retrospective log
- `TUNABLE_ARTIFACTS`: the files that may carry a rule, such as project instruction files, agent definitions, prompts, or skills

## Skill wrap-up

Before Step 1, read `~/.claude/session-retrospectives/<project-slug>/log.md`
if it exists and use it as the previous retrospectives — where `<project-slug>`
is the current repository's directory name. This log is what makes the
recurrence check real rather than a matter of memory.

Present the candidate rules and ask which to apply. Apply only the ones the
user approves, one destination file at a time, showing the edit before making
it. Never apply a low-confidence rule without being asked to.

Then append an entry to that log — creating the directory with `mkdir -p` the
first time — whether or not any rule was applied, and including sessions that
ran clean. A run of clean retrospectives is itself signal, and a signal that
was discarded once and returns is the evidence that promotes it later.

Print the entry in your reply as you append it, and say which file it went to.
The log is the only thing this prompt writes without asking, so it is the one
part the user cannot check unless you show it.

```
## <UTC date-time> — <project-slug>
**Session:** <one line on what the session set out to do>
**Signals:** <count, then one line each>
**Promoted:** <rule → destination, per rule, or "none">
**Discarded:** <one line each, with the reason>
**Applied:** <which rules the user approved and where, or "none">
```
