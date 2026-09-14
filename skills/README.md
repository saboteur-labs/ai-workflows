# skills/

Reusable agent skills conforming to the
[Agent Skills specification](https://agentskills.io/specification).
Each skill is a directory containing a `SKILL.md` file and optional
`scripts/`, `references/`, and `assets/` subdirectories.

## How to use

Copy a skill directory into `.agents/skills/` in your project:

```sh
./tools/fetch-prompt.sh --install-skill coding/implement-feature
```

Or manually copy the directory. Then fill in
`references/patterns.md` and `references/conventions.md` with
project-specific details.

See [`../guides/workflows/`](../guides/workflows/) for interface-specific
injection instructions.

New skill? Use [`../templates/skill-template.md`](../templates/skill-template.md).

---

## coding/

| Skill                                                                      | Budget | Description                                                   |
| -------------------------------------------------------------------------- | ------ | ------------------------------------------------------------- |
| [`coding/implement-feature/`](./coding/implement-feature/)                 | medium | Implement a feature from a spec — plan, code, test, validate, record and triage deferred work in `sab.follow-up-work/1` |
| [`coding/implement-feature-minimal/`](./coding/implement-feature-minimal/) | low    | Low-context variant of implement-feature                      |
| [`coding/debug-issue/`](./coding/debug-issue/)                             | low    | Systematically diagnose and fix a bug or unexpected behaviour |
| [`coding/debug-issue-minimal/`](./coding/debug-issue-minimal/)             | low    | Low-context variant of debug-issue                            |

## planning/

| Skill                                                              | Budget | Description                                                  |
| ------------------------------------------------------------------ | ------ | ------------------------------------------------------------ |
| [`planning/spec-writer/`](./planning/spec-writer/)                 | low    | Write and refine feature specs through an iterative dialogue |
| [`planning/spec-writer-minimal/`](./planning/spec-writer-minimal/) | low    | Low-context variant of spec-writer                           |

## agents/

Skills for working on the user's own subagents.

| Skill                                  | Budget | Description                                                                       |
| -------------------------------------- | ------ | --------------------------------------------------------------------------------- |
| [`improve-agent/`](./improve-agent/)   | medium | Continuously improve a user-created agent by learning from how it actually runs   |

## pipeline

Skills for the `saboteur-ship` pipeline itself. The pipeline machinery — the
lead skill, its subagents, and the plan-gate hook — lives in
[`../pipeline/`](../pipeline/); what sits here is invoked on demand rather than
being part of a run. Both install into `~/.claude/` rather than into a project's
`.agents/skills/`:

```sh
ln -s "$PWD/skills/saboteur-onboard-pipeline" ~/.claude/skills/saboteur-onboard-pipeline
```

Symlink rather than copy, for the reason given in
[`../prompts/README.md`](../prompts/README.md) — the installed skill then
tracks this repo. These are source skills, not compiled ones, so no
`build-dist.js` run is needed after pulling. The trade is that the installed
skill follows whichever branch this repo is checked out on.

`tools/fetch-prompt.sh --install-skill` deliberately does not cover these: it
copies into a project's `.agents/skills/`, which is the wrong destination and
the wrong mechanism. Revisit tool support when a second pipeline skill lands —
one skill does not justify the flag.

| Skill                                                | Budget | Description                                                                 |
| ---------------------------------------------------- | ------ | --------------------------------------------------------------------------- |
| [`saboteur-onboard-pipeline/`](./saboteur-onboard-pipeline/) | medium | Bring a repo that predates the pipeline up to the ladder state a run expects |

## observability

Skills for seeing what agents actually did. These are Claude Code-specific:
they read logs written by Claude Code hooks, so they install into `~/.claude/`
by symlink rather than into a project's `.agents/skills/`. Installation,
including the hook registration, is in each skill's `references/install.md`.

| Skill                  | Budget | Description                                                                              |
| ---------------------- | ------ | ---------------------------------------------------------------------------------------- |
| [`runlog/`](./runlog/) | low    | Read the per-repo, per-session log of what agents attempted, written by Claude Code hooks |

## repo tools

Skills for maintaining this repo itself. These are not copied into other
projects — they are used in-place when working on this knowledge base.

They declare `audience: repo` under `metadata:`, which routes their changelog
entries to [`../CHANGELOG-repo-tools.md`](../CHANGELOG-repo-tools.md) instead
of the user-facing `CHANGELOG.md`. Note that `improve-agent/` above is *not*
one of these: it sits at the same directory depth but tunes the user's own
agents, so it logs to `CHANGELOG.md` like any other shipped skill.

| Skill                                                      | Budget | Description                                                                     |
| ---------------------------------------------------------- | ------ | ------------------------------------------------------------------------------- |
| [`repo-maintenance/`](./repo-maintenance/)                 | medium | Maintain and extend this repo — propose changes, check atomicity, enforce style |
| [`repo-maintenance-minimal/`](./repo-maintenance-minimal/) | low    | Low-context variant of repo-maintenance                                         |
| [`freshness-check/`](./freshness-check/)                   | low    | Assess whether a file's external claims are likely still accurate               |
| [`improve-prompt/`](./improve-prompt/)                     | medium | Tune a prompt or skill in this repo from evidence of how it actually performed  |

---

## Per-project reference files

Each skill directory contains reference files under `references/` that
are loaded on demand by the skill. These are stubs — fill them in with
project-specific content when you copy a skill into a project:

| File                         | Skill                          | What to fill in                                                       |
| ---------------------------- | ------------------------------ | --------------------------------------------------------------------- |
| `references/patterns.md`     | implement-feature, debug-issue | Project-specific code patterns, ORM usage, error handling conventions |
| `references/conventions.md`  | implement-feature              | Naming, file structure, import style, git conventions, deferred-work location |
| `references/known-issues.md` | debug-issue                    | Known bugs, recurring failure modes, technical debt                   |
| `references/domain.md`       | spec-writer                    | Domain language, entity names, business rules                         |
