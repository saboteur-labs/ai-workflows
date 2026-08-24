---
name: saboteur-ship
description: Drive a feature from concept through implementation via the saboteur pipeline, pausing at a human gate between every stage. Explicit-invocation only; runs in the main session.
argument-hint: <the feature or idea, or the concept/spec to start from>
disable-model-invocation: true
allowed-tools: Agent, Skill, AskUserQuestion, Read, Grep, Glob, Bash
---

# Pipeline lead: $ARGUMENTS

You are the pipeline lead, running in the main session. You hold every human gate
yourself and NEVER delegate the gating — only you can talk to the user. You do
not write specs, resolve questions, implement, or edit docs yourself; you
delegate each stage to a subagent and STOP at each gate until I explicitly say
go. If I cancel at any gate, run Cleanup and stop.

Two marker files (managed with Bash) drive the deterministic gate hook:

- `.claude/.pipeline-active` — a run is in progress
- `.claude/.plan-approved` — the plan gate has cleared

## The ladder

Every artifact is derived from the one above it:

| Rung | Artifact | Path | Schema |
| --- | --- | --- | --- |
| 1 | Concept | `specs/concept.md` | — |
| 2 | Product spec | `specs/product/{slug}.md` | `sab.product-spec/1` |
| 3 | Feature list | `specs/product/{slug}.features.md` | `sab.features/1` |
| 4 | Feature spec | `specs/features/{slug}.md` | `sab.feature-spec/1` |
| 5 | Task list | `specs/features/{slug}/tasks.md` | `sab.tasks/1` |
| 6 | Implementation | source | — |

**The paths in this table are load-bearing.** The plan-gate hook exempts
`specs/*` and `.claude/*` and blocks every other write until the plan is
approved, so an artifact written anywhere else is denied — and a subagent that
hits that denial loses its entire run rather than retrying. When the repository
keeps its specs somewhere else, reconcile the conflict at Gate 0, before
delegating anything: either write this run's artifacts to `specs/` and note the
split, or widen the hook. Do not adopt the repo's convention and discover the
block at the first write.

You may enter partway up when a rung's artifact already exists, and rungs 2 and
3 may be skipped when I say so. **You may never skip a rung silently.** Going
straight from a concept to a task list is the specific failure this ladder
exists to prevent: it collapses the product-level decisions — what the whole
thing is, and which slice of it ships first — into an implementation detail
nobody was asked about.

Validate each artifact as it is produced, before its gate:

```bash
node ~/Repositories/saboteur-labs/ai-workflows/tools/lib/check-outputs.js \
  --doc <path> --schema <schema id>
```

A non-zero exit is a stage failure. Report the violations and route the repair
back to the agent that produced it — never repair it yourself, and never carry
an invalid artifact to the next rung.

## Triage (subroutine)

Every spec artifact carries an "## Open Questions" section — spec-manager
captures questions but is forbidden from answering them. **An artifact does not
pass its gate with unresolved questions still in it.** A question left open at
rung 2 does not stay open: whoever writes the next rung answers it by
implication, and nobody is asked.

Run this after each spec artifact validates, before its gate:

1. Delegate to `saboteur-oq-triage` against the artifact. If it reports
   "Nothing to resolve", say so at the gate and move on.
2. Present its "Resolved from evidence" list for confirmation — these are
   proposals with evidence, not decisions already made. Flag any marked
   low confidence.
3. Present "Needs your decision" as numbered questions with the options it
   gave. Stop and collect my answers.
4. Delegate back to `saboteur-spec-manager` (edit mode) to fold the answers
   into the artifact, then re-validate it.

Carry the answers forward. A decision made at rung 2 is an input to rung 3, not
a question to be asked again — when a later artifact repeats a question already
settled, say that it was settled and what the answer was.

## Stage 0 — Intake

Run: `mkdir -p .claude && rm -f .claude/.plan-approved && touch .claude/.pipeline-active`

Establish where on the ladder this run starts. Check which artifacts already
exist at the paths above, reading `$ARGUMENTS` for an explicit starting file.

**A concept is required.** If none exists, do not invent one and do not start
from `$ARGUMENTS` alone — a one-line feature request is not a concept. Run the
`saboteur-ideate-project` skill yourself, in this session: it asks clarifying
questions, and only you can answer them. Save the result to `specs/concept.md`
unless I name a path.

Then present a **run plan** — one line per rung, giving the artifact, its path,
and exactly one of:

- `exists` — already on disk and valid; this run reads it, does not rewrite it
- `run` — this run produces it
- `skip` — deliberately omitted, with the reason I gave

GATE 0: Present the run plan. Ask me explicitly about rungs 2 and 3 — whether
to write a product spec, and whether to break it into features — naming what is
lost by skipping each. Default to running both. Do not continue until I confirm.

## Stage 1 — Product spec (rung 2)

Skip only if marked `exists` or `skip` at Gate 0.

Delegate to saboteur-spec-manager: run the `saboteur-write-product-spec` skill
against the concept, saving to `specs/product/{slug}.md`. Validate against
`sab.product-spec/1`.

Then run **Triage** on it. These are the highest-leverage questions in the run —
they are product-level, so every rung below inherits whatever answer they get.
The concept deliberately leaves some unresolved; they arrive here.

GATE 1: Present the spec in full, with the triage results. Approve, edit, or
reject.

## Stage 2 — Feature list (rung 3)

Skip only if marked `exists` or `skip` at Gate 0.

Delegate to saboteur-spec-manager: run the `saboteur-break-into-features` skill
against the product spec, saving to `specs/product/{slug}.features.md`.
Validate against `sab.features/1`.

`sab.features/1` does not require an Open Questions section, but spec-manager
writes one anyway. If the breakdown carries questions, run **Triage** on it —
they are usually scoping calls about which milestone a capability belongs to,
and they change what you pick below.

GATE 2: Present the features. **I choose exactly one to carry forward.** The
rest are not this run's work — name them in the debrief as remaining, and say
that shipping each means another pass through this pipeline.

## Stage 3 — Feature spec (rung 4)

Delegate to saboteur-spec-manager: run the `saboteur-write-feature-spec` skill
for the chosen feature, saving to `specs/features/{slug}.md`. Validate against
`sab.feature-spec/1`.

If rungs 2 and 3 were skipped, this is written from the concept directly. Say
so when you present it, because its scope was never checked against a
product-level view.

Then run **Triage** on it. This is the largest set of questions in the run — the
feature spec is where the implementation-level unknowns land, and the task list
below is written directly from it, so anything still open here gets decided by
an implementor.

GATE 3: Present the spec in full, with the triage results. Approve, edit, or
reject.

## Stage 4 — Plan (rung 5)

Delegate to saboteur-spec-manager: run the `saboteur-break-into-tasks` skill
against the finalized feature spec, saving to `specs/features/{slug}/tasks.md`.
Validate against `sab.tasks/1` — the orchestrator hard-gates on this at its
entry, so a task list that fails here will not run. Do not enter plan mode —
this stage is the plan.
GATE 4: Present the task list in full, plus the file it was saved to. Write no
code until I approve.
On approval, run: `touch .claude/.plan-approved`

## Stage 5 — Execute (rung 6)

Delegate the approved feature spec + task list to saboteur-feature-orchestrator.
It implements tasks one at a time and commits each verified task.
Hard limits for this stage: do not change permissions, delete data, or
push/merge.
If it halts with a failure report, present the failed task and its options.
GATE 5: Stop and let me choose skip / resolve / cancel.

## Stage 6 — Document

Delegate to saboteur-scribe with the change set from this run so it can reconcile
documentation against what shipped. Include its updates in the review below.

## Stage 6.5 — Exercise it

Run the feature in the real app and use it as a user would, before the debrief.
A green suite proves the code the tests cover behaves as the tests say; it does
not prove the surface works. Use the `run` skill.

Report what you exercised and what you saw. If it cannot be run, say that
plainly in the debrief and name what is therefore unverified — do not let
passing tests stand in for a claim nobody checked.

## Stage 7 — Debrief

Summarize what changed: files, commits, test results, doc updates, and anything
deferred or that deviated from the plan.

Restate the run plan from Gate 0 with each rung's final state, and list the
features from Gate 2 that were not built. A rung that was skipped must appear
here — the debrief is the last chance for a skip to be visible.

List the decisions made at triage, with the rung each was settled at. These were
answered once and are now load-bearing across every artifact below them, so they
belong in the record rather than only in the specs.

GATE 6: Stop. Present the diff for my review before anything is merged.
On my approval to close out, run Cleanup.

## Cleanup

Run: `rm -f .claude/.pipeline-active .claude/.plan-approved`
Do this on successful close-out AND on any cancellation.
