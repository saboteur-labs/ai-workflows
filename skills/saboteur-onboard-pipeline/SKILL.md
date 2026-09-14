---
name: saboteur-onboard-pipeline
description: >
    Bring a repository that predates the saboteur-ship pipeline up to the
    state the pipeline expects, so a run does not stall on missing or invalid
    documents. Use this skill when a project started before the pipeline
    existed and `/saboteur-ship` keeps asking about artifacts that were never
    written, when a spec fails schema validation mid-run, when specs live
    somewhere other than `specs/`, or when a stale marker file from an aborted
    run is blocking writes. Triggers on "onboard this repo", "get this project
    ready for the pipeline", "why does saboteur-ship keep asking about the
    product spec", "the ship pipeline is complaining about my specs", and
    "check this repo against the ladder". It inventories the ladder, validates
    every artifact it finds, reports every gap with the evidence for it, and
    repairs only what the human approves at a gate. It never invents product
    intent and never presents a reconstruction as a record.
license: MIT
compatibility: >
    Requires the saboteur-ship pipeline: the `saboteur-spec-manager` and
    `saboteur-oq-triage` subagents, the `saboteur-*` spec skills, and
    `tools/lib/check-outputs.js` from the ai-workflows repo. Designed for the
    Claude Code CLI. Read/write access to the target repository is needed only
    at the repair step; the report step is read-only.
metadata:
    author: saboteur-labs
    version: "1.0"
    context-budget: medium
    interfaces: cli, ide
---

# saboteur-onboard-pipeline

You are onboarding an existing repository onto the `saboteur-ship` pipeline.
The pipeline derives each artifact from the one above it and validates each
one against a schema. A repository that predates it has none of that scaffolding,
so a run spends its first hour discovering gaps one at a time instead of shipping.
Your job is to find every gap up front, in one read-only pass, and then repair
the ones the human approves.

This is not a pipeline run. You produce no feature and write no code.

---

## The one rule you must never break

**Report everything before you change anything.**

The inventory and validation steps are read-only. You do not create a missing
document, move a misplaced one, or delete a marker file until you have presented
the full report and the human has told you what to repair. A repair made while
still discovering is a repair made without the human seeing the shape of the
problem.

The second rule follows from the first: **a reconstruction is not a record.**
When you backfill a concept or a product spec for a repository that already has
code, you are inferring intent from artifacts that only show behaviour. Say so,
in the document, every time. Never write a reconstructed rationale as though
someone had decided it.

---

## The ladder

`saboteur-ship` climbs these rungs, deriving each from the one above:

| Rung | Artifact     | Path                              | Schema               |
| ---- | ------------ | --------------------------------- | -------------------- |
| 1    | Concept      | `specs/concept.md`                | —                    |
| 2    | Product spec | `specs/product/{slug}.md`         | `sab.product-spec/1` |
| 3    | Feature list | `specs/product/{slug}.features.md`| `sab.features/1`     |
| 4    | Feature spec | `specs/features/{slug}.md`        | `sab.feature-spec/1` |
| 5    | Task list    | `specs/features/{slug}/tasks.md`  | `sab.tasks/1`        |
| 6    | Implementation | source                          | —                    |

**Onboarding targets rungs 1–3 only.** Those are the durable, product-level
artifacts a run reads on the way in, and their absence is what makes every
future run stumble. Rungs 4 and 5 are per-feature and are produced by the run
that ships that feature — backfilling a feature spec and a task list for code
that already shipped is archaeology, not onboarding.

Backfill a rung 4 or 5 artifact only when the human asks for it explicitly, and
say plainly that it documents work already done rather than work about to start.

---

## Step 1 — Establish the target

Confirm which repository you are onboarding. Default to the current working
directory; if `$ARGUMENTS` names a path, use that.

Then read enough of the repository to describe it in a sentence: its README,
its package manifest, its top-level directories. You need this to tell a
missing document from a document you failed to find.

State what the repository is before you start reporting on what it lacks.

---

## Step 2 — Inventory the ladder

For each of rungs 1, 2, and 3, record one of:

- **present, at the conventional path** — the file exists where the table says
- **present, elsewhere** — a document that plainly serves that rung lives at
  another path
- **absent** — nothing in the repository serves that rung

Look beyond `specs/`. A pre-pipeline repository commonly keeps these under
`docs/`, `planning/`, `design/`, `.github/`, a wiki directory, or as sections of
the README. Search by content, not only by filename:

```sh
ls specs docs planning design 2>/dev/null
grep -ril "product spec\|functional requirement\|user stor\|non-goal\|milestone" \
  --include="*.md" . | grep -v node_modules
```

A document only counts as serving a rung if it actually does that rung's job.
A README section headed "Roadmap" is not a feature list, and a `docs/design.md`
that describes the database schema is not a product spec. When you are unsure,
record it as a candidate and let the human decide at the gate — do not resolve
it silently in either direction.

---

## Step 3 — Validate what you found

Every artifact that exists gets validated, including ones at non-conventional
paths. Run the schema engine from the ai-workflows repo:

```sh
node ~/Repositories/saboteur-labs/ai-workflows/tools/lib/check-outputs.js \
  --doc <path> --schema <schema id>
```

Exit codes: `0` pass, `1` fail (blocking), `2` warn only. `--list` shows every
schema the engine knows. If the ai-workflows repo is not at that path, find it
before continuing — do not skip validation and do not judge conformance by eye.
A document that looks complete fails on ID gaps and unresolved cross-references
that reading will not surface.

Cross-check rung 3 against rung 2 when both exist:

```sh
node ~/Repositories/saboteur-labs/ai-workflows/tools/lib/check-outputs.js \
  --doc specs/product/{slug}.features.md --schema sab.features/1 \
  --against specs/product/{slug}.md
```

This is the check that catches a feature list which has drifted from the spec it
was derived from — a requirement covered by no feature, or a feature citing a
requirement that no longer exists.

Record the validator's output verbatim. Its failures are measurements. Your
explanation of why a document fails is a hypothesis, and it belongs in a
separate column of the report, marked as such.

---

## Step 4 — Check the spec path convention

The plan-gate hook (`PreToolUse` on `Write`/`Edit`) denies every write while a
run is active and the plan is not yet approved, exempting only paths under
`specs/` and `.claude/` relative to the project directory. A subagent that hits
that denial loses its whole run rather than retrying.

So a repository that keeps its specs in `docs/` has a live problem, not a
cosmetic one. Record it, and at the gate offer the human the two resolutions:

- **Move the artifacts into `specs/`** — the pipeline's convention, and what
  every agent that locates a document by path expects. Requires updating links
  that point at the old paths.
- **Widen the hook to exempt the repository's own directory** — keeps the
  existing convention, at the cost of a hook that now differs per repository.

Recommend moving unless the human has a reason to keep the old layout. The
validator already flags this itself: a document at an unconventional path
returns a `WARN` naming the location agents will look in.

Do not adopt the repository's convention silently. That is exactly the choice
that surfaces as a denied write halfway through the next run.

---

## Step 5 — Check the pipeline plumbing

Three mechanical checks, all cheap:

1. **`.claude/` exists.** The marker files live there. `mkdir -p .claude` at
   repair time is enough.
2. **No stale marker files.** `.claude/.pipeline-active` left behind by an
   aborted run puts the repository in a permanently gated state: every write
   outside `specs/` and `.claude/` is denied, with a message about a plan gate
   for a run that ended days ago. Check for it, and check whether a run is
   genuinely in progress before proposing its removal.

   ```sh
   ls -la .claude/.pipeline-active .claude/.plan-approved 2>/dev/null
   ```

   `.claude/.plan-approved` present *without* `.claude/.pipeline-active` is
   inert but still stale — report it.

3. **Markers are ignored by git.** They are run state, not content. Check
   `.gitignore` for coverage, and check whether either file is already tracked:

   ```sh
   git check-ignore -v .claude/.pipeline-active .claude/.plan-approved
   git ls-files --error-unmatch .claude/.pipeline-active 2>/dev/null
   ```

   Read the exit codes carefully — both invert the intuitive reading, and
   misreporting them is worse than not checking:

   - `git check-ignore` exits **1 when nothing matched**, meaning the markers
     are *not* ignored. That is the finding. Exit 0 with a printed rule is the
     healthy case.
   - `git ls-files --error-unmatch` exits **1 when the file is not tracked**,
     which is the healthy case. Exit 0 means it is committed.

   A committed `.pipeline-active` gates every clone of the repository, for
   everyone.

---

## Step 6 — The report

Present one report covering everything. Structure it as:

### Repository

One sentence on what it is, and its path.

### Ladder

| Rung | Artifact | Found at | Validates | Finding |
| ---- | -------- | -------- | --------- | ------- |

`Validates` is the validator's verdict — `pass`, `fail (N)`, `warn`, or `n/a`
for the concept, which has no schema. `Finding` is one line. Put the full
validator output for each failing document below the table, unedited.

### Path convention

Where specs live, whether that is inside the hook's exemption, and the two
resolutions if it is not.

### Plumbing

The three checks, with what you found.

### Proposed repairs

A numbered list. Each entry: what would change, which agent or skill does it,
and what it costs. Order by what unblocks the most — plumbing first, because it
is mechanical and cannot be wrong; reconstructed documents last, because they
need the most human input.

Separate the ones you can do mechanically from the ones that need the human's
own knowledge of what the product is for. Do not merge them into one list of
"fixes" — the second kind is not a fix, it is an interview.

---

## GATE — stop here

Present the report and stop. Ask which repairs to make, by number. Do not begin
any repair, including a mechanical one, until the human answers.

If they decline all of them, the report is the deliverable. Offer to save it to
a file and stop.

---

## Step 7 — Repair what was approved

Work in the order below, and re-validate after every artifact.

**Plumbing.** Do these yourself — `mkdir -p .claude`, remove stale markers, add
the `.gitignore` entries. If a marker file is tracked in git, `git rm --cached`
it and say so.

**Moving misplaced artifacts.** `git mv` so history follows the file, then find
and update every reference:

```sh
grep -rn "old/path" --include="*.md" . | grep -v node_modules
```

Validate each artifact again after the move — the location `WARN` should clear.

**Rung 1, a missing concept.** Run `saboteur-ideate-project` **yourself, in this
session.** It asks clarifying questions and only the human can answer them, so
it cannot be delegated to a subagent. Save the result to `specs/concept.md`.

For a repository with substantial existing code, seed the interview rather than
starting cold: run `saboteur-explain-codebase`, and `saboteur-surface-architecture-decisions`
if the decisions are undocumented, and bring their output in as material. It
makes the questions sharper. It does not make the answers yours to give.

Mark the result as reconstructed, in the document, with the date and the fact
that it was inferred from an existing codebase.

**Rung 2, a missing or invalid product spec.** Delegate to
`saboteur-spec-manager`: run `saboteur-write-product-spec` against the concept,
saving to `specs/product/{slug}.md`. Validate against `sab.product-spec/1`.

For an existing product, the spec has to cover behaviour that already ships as
well as what comes next. The schema groups functional requirements under
`### {milestone} Requirements` headings, so use a milestone that names the
distinction — `Shipped`, then whatever is planned. A product spec that describes
only the future silently un-specifies everything the repository already does,
and the next feature list will not account for it.

Then run triage: delegate to `saboteur-oq-triage` against the artifact, present
its "Resolved from evidence" proposals for confirmation and its "Needs your
decision" items as numbered questions, collect the answers, and delegate back to
`saboteur-spec-manager` in edit mode to fold them in. Re-validate.

An onboarding pass leaves more open questions than a fresh run, because it is
recovering decisions nobody wrote down. That is the point — resolve them here,
where they can be answered once, rather than letting each future run answer them
by implication.

**Rung 3, a missing or invalid feature list.** Delegate to
`saboteur-spec-manager`: run `saboteur-break-into-features` against the product
spec, saving to `specs/product/{slug}.features.md`. Validate against
`sab.features/1`, and cross-check with `--against` the product spec.

Mark the features that already ship. The list's job here is to make the next
run's Gate 2 a real choice, and a list that offers already-built features as
candidates makes it a worse one.

**An invalid artifact you did not write.** Route the repair through
`saboteur-spec-manager` in edit mode with the validator output attached. Do not
hand-patch a document to make a validator pass — an ID renumbered by hand to
close a gap breaks every reference to it, and the cross-reference checks will
find that later, in a worse place.

---

## Step 8 — Close out

Report:

- Every repair made, with the artifact and its final validator verdict
- Every finding left unrepaired, and whose call that was
- Every open question resolved during triage, with the answer, because those are
  now load-bearing for every future run
- Which rungs the repository now stands at, and what the next `/saboteur-ship`
  run will therefore do

Then say what remains unverified. Onboarding proves that documents exist and
conform. It does not prove they are true. A reconstructed product spec that
validates is a spec the human should read before the next run derives anything
from it — say that, rather than letting a green validator stand in for a review
nobody did.

Offer the next step: `/saboteur-ship <the next feature>`.

---

## What this skill does not do

- **It does not run the pipeline.** It writes no feature spec, no task list, and
  no code.
- **It does not backfill rungs 4 and 5** unless asked. See "The ladder" above.
- **It does not audit `sab.follow-up-work/1` documents.** Deferred-work records
  are produced by `implement-feature`; their absence does not block a run.
- **It does not touch repository conventions beyond the pipeline's needs** —
  licensing, `package.json` metadata, and the rest of the saboteur-labs project
  standards are a separate concern.
- **It does not decide what the product is.** Where the record is missing, it
  asks.
