# pipeline/

The `saboteur-ship` pipeline: the skill that leads a run, the subagents it
delegates each stage to, and the hook that enforces the plan gate.

Unlike the rest of this repo, these files are **Claude Code-specific** and are
not model- or interface-agnostic. They are machinery, not reference content —
you install them once and invoke them, rather than copying them into a project.
The scoping is the same as `dist/claude/` (built by
[`../scripts/build-dist.js`](../scripts/build-dist.js)): a subtree that targets
one interface, inside a repo whose content is otherwise portable.

---

## What is here

| File                                        | Role                                                             |
| ------------------------------------------- | ---------------------------------------------------------------- |
| `skills/saboteur-ship/SKILL.md`             | The pipeline lead. Runs in the main session and holds every gate  |
| `agents/saboteur-feature-orchestrator.md`   | Drives implementation, delegating tasks and committing each one   |
| `agents/saboteur-task-implementor.md`       | Implements a single task toward a feature                         |
| `agents/specs-tasks/saboteur-spec-manager.md` | Writes and edits every spec artifact                            |
| `agents/specs-tasks/saboteur-oq-triage.md`  | Resolves or escalates a spec's Open Questions                     |
| `agents/maintenance-upkeep/saboteur-scribe.md` | Reconciles documentation against what shipped                  |
| `hooks/pipeline-gate.sh`                    | `PreToolUse` hook: denies writes until the plan gate clears       |

The onboarding skill for repositories that predate the pipeline is *not* here —
it is a normal skill at
[`../skills/saboteur-onboard-pipeline/`](../skills/saboteur-onboard-pipeline/),
because it is invoked on demand rather than being part of a run.

---

## Installing

Symlink each file to where Claude Code looks for it, so the installed copy
tracks this repo:

```sh
ln -s "$PWD/pipeline/skills/saboteur-ship"                 ~/.claude/skills/saboteur-ship
ln -s "$PWD/pipeline/agents/saboteur-feature-orchestrator.md" ~/.claude/agents/saboteur-feature-orchestrator.md
ln -s "$PWD/pipeline/agents/saboteur-task-implementor.md"  ~/.claude/agents/saboteur-task-implementor.md
ln -s "$PWD/pipeline/agents/specs-tasks/saboteur-spec-manager.md" ~/.claude/agents/specs-tasks/saboteur-spec-manager.md
ln -s "$PWD/pipeline/agents/specs-tasks/saboteur-oq-triage.md" ~/.claude/agents/specs-tasks/saboteur-oq-triage.md
ln -s "$PWD/pipeline/agents/maintenance-upkeep/saboteur-scribe.md" ~/.claude/agents/maintenance-upkeep/saboteur-scribe.md
ln -s "$PWD/pipeline/hooks/pipeline-gate.sh"               ~/.claude/hooks/pipeline-gate.sh
```

Agents are linked file by file rather than by directory. `specs-tasks/` and
`maintenance-upkeep/` are groupings in `~/.claude/agents/` that may later hold
agents unrelated to the pipeline, and a directory symlink would silently pull
those into this repo.

`hooks/pipeline-gate.sh` is registered in `~/.claude/settings.json` by absolute
path. `bash` follows the symlink, so no settings change is needed — but the hook
runs on **every** `Write` and `Edit` in **every** repo, so a syntax error here
is not contained to pipeline runs. It is written to fail open at every step;
keep it that way.

**The symlink follows whatever branch this repo is checked out on.** Checking
out a branch without `pipeline/` removes the pipeline from your tooling until
you switch back.

---

## The ladder is checked

`skills/saboteur-ship/SKILL.md` **owns** the ladder — the rung table naming each
artifact, its path, and its schema. Other documents restate it, because an agent
mid-run cannot be expected to follow a link to find out where to write a file.

[`../tools/lib/check_ladder.sh`](../tools/lib/check_ladder.sh) asserts every
in-repo copy agrees with it cell for cell, and that every schema it names is one
`check-outputs.js` knows. It runs as part of `./tools/validate.sh`.

This matters more than a documentation nit: `hooks/pipeline-gate.sh` exempts
`specs/` from the plan gate and denies everything else, so a rung whose path
drifts in one document and not another surfaces as a denied write halfway
through someone's run — and a subagent that hits that denial loses its entire
run rather than retrying.

**One copy is not covered.** `~/.claude/testbeds/ship-testbed.md` carries a
fourth ladder and lives outside this repo deliberately — it is an answer key for
pipeline runs, and a testbed that ships its answers inside the repo under test
measures whether an agent can follow a document rather than whether the pipeline
drives itself. Nothing here can reach it. Update it by hand when the ladder
changes.

---

## Changing anything here

The propose-before-act rule in [`../AGENTS.md`](../AGENTS.md) applies. Two
additional cautions specific to this directory:

- **The hook is global.** It runs on every write in every repository on this
  machine. Test a change to it against a repository you do not mind breaking.
- **Agent definitions are contracts.** `saboteur-ship` delegates by agent name
  and expects a particular report shape back. Renaming an agent or changing what
  it returns breaks the lead silently — the run continues and produces something
  wrong rather than failing.
