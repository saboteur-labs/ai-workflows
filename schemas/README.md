# Output schemas

Machine contracts for the prompts whose output is consumed by an agent rather
than only read by a human.

A prompt's `## Prompt` block carries the output format a model reads; the schema
here carries the same contract in a form a program can check. Neither is
generated from the other — instead `tools/lib/check-outputs.js --prompts`
asserts they agree, so the two halves cannot drift apart unnoticed.

Only prompts with an agent downstream get a schema. `write-adr` and
`estimate-complexity` produce documents a person reads, and adding a contract
there would buy nothing.

| Schema | Prompt | Consumed by |
| --- | --- | --- |
| `sab.product-spec/1` | `write-product-spec` | `break-into-features`, automated open-question review |
| `sab.feature-spec/1` | `write-feature-spec` | `break-into-tasks`, automated open-question review |
| `sab.features/1` | `break-into-features` | `break-into-tasks` (per feature) |
| `sab.tasks/1` | `break-into-tasks` | an automated implementation runner |

## Using it

```bash
# Do the schemas still match the formats authored in their prompts?
./tools/validate.sh --check outputs

# Does a produced document conform?
node tools/lib/check-outputs.js --doc specs/features/csv-export/tasks.md --schema sab.tasks/1

# Does the feature breakdown cover every requirement in the spec?
node tools/lib/check-outputs.js --doc features.md --schema sab.features/1 --against specs/product/app.md

# Parsed structure for an agent to consume (ordering, dependencies, done conditions)
node tools/lib/check-outputs.js --doc tasks.md --schema sab.tasks/1 --json

# What schemas exist
node tools/lib/check-outputs.js --list
```

The `--json` output is derived on demand from the document, never authored
alongside it, so it cannot disagree with the prose you reviewed. It includes an
`execution_order` array — a dependency-respecting topological sort that an
orchestrator can walk directly.

## Writing a schema

Each file is `schemas/<id>.schema`, line-oriented, `#` for comments. Two-space
indentation marks a member of the construct above it.

### Header

```
schema: sab.tasks/1                        # stable id, referenced by --schema
doc: task-list                             # document kind
prompt: prompts/planning/break-into-tasks.md
output-path: specs/features/{slug}/tasks.md
```

The prompt must declare `output-schema: sab.tasks/1` in its frontmatter. The
link is stated on both sides deliberately: a half-finished rename fails loudly
instead of silently disabling validation.

`output-path` is where the document belongs, with `{slug}` standing for the
kebab-cased name of the thing it covers. Location is part of the contract —
downstream agents find these documents by convention, so a correct document in
an ad-hoc place still breaks the pipeline. It is required for any prompt marked
`skill-saves-document: true`; without it the compiled skill would have to ask or
guess, which is what this replaced.

`scripts/build-dist.js` turns it into a definite instruction in the compiled
skill. Prompts with no schema get a footer that says *ask* — never infer a
location from whichever folder looks relevant.

Validation reports a document filed somewhere else as a warning rather than an
error, since a repository may legitimately keep specs under its own layout.

### `item` — a repeating entity

```
item Task | min:1
  heading: ### Task {id:int}: {title:text}
  field: Done when | required | text
  field: Depends on | required | refs:Task.id or none
  field: Notes | optional | text
  field: Done | required | checkbox
```

Field order is part of the contract — the drift check enforces that the
authored format lists them in the same order.

### `section` — a fixed heading, optionally holding a list

```
section Functional requirements | required
  heading: ## Functional requirements
  list: numbered | min:1 | id:FR-{n:int} | match:\b(MUST|SHOULD|MAY)\b | refs:US.id

section Summary | required
  heading: ## Summary
  bullet: Total tasks | required | int | eq:count(Task)
```

List options: `min` / `max` cardinality, `id:PREFIX-{n:int}` for stable IDs,
`match:<regex>` the entry text must satisfy, `empty-literal:<text>` for the
sanctioned "nothing here" phrasing (e.g. `None identified.`).

Bullet option `eq:count(Item)` asserts a stated total matches what the document
actually contains — this is what catches a summary that says four tasks over a
list of two.

### `graph` — whole-document invariants

```
graph
  unique: Task.id                  # no duplicate IDs
  sequential: Task.id              # IDs run 1..n with no gaps
  acyclic: Task.Depends on         # no dependency cycles
  precedes: Task.Depends on        # a dependency must appear earlier
  partition: Feature.Requirements covered   # each requirement claimed once
  resolves: FR.refs -> US.id       # every [US-N] reference exists
```

`resolves: FR.blocked -> OQ.id` matches `[BLOCKED: OQ-N]` markers instead of
plain references.

## Versioning

The version lives in the schema id (`sab.tasks/1`). Change the contract in a way
that would invalidate existing documents — renaming a field, adding a required
one, tightening a matcher — and cut a new id rather than editing in place, so
documents already produced can still be validated against the schema they were
written under. Loosening a constraint can be done in place.
