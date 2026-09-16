# Changelog — repo tools

Changes to the skills that maintain **this repository**, rather than the ones
copied into other projects. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.0.0/), same as
[`CHANGELOG.md`](./CHANGELOG.md).

A skill belongs here when its `SKILL.md` declares `audience: repo` under
`metadata:`. Everything else — the prompt library, the skills consumers copy,
guides, examples, templates, tooling — goes in `CHANGELOG.md`.

The split exists so the user-facing changelog stays a record of what changed
for someone consuming this knowledge base. Tuning the machinery that maintains
the repo is real work worth tracking, but it is not news to a reader who copied
`implement-feature` into their project.

`tools/lib/check_atomicity.sh` routes each changed skill to the right file by
reading that `audience` field, and blocks a PR that updates neither.

Entries before 2026-08-12 are in `CHANGELOG.md`; this file starts from the
split rather than being backfilled.

---

## [Unreleased]

### Changed

- `.gitignore` ignores `.claude/`, the local Claude Code config directory. It
  can hold symlinks to `repo-maintenance` and `freshness-check` that make Claude
  Code auto-load them for a session started in this repo, which would make
  `AGENTS.md`'s "load repo-maintenance first" rule enforce itself. Committing
  just those symlinks was deferred: they share the directory with machine-local
  settings and with a pipeline run's marker files, so the whole directory stays
  untracked and each clone links them by hand. The commands are in `.gitignore`
  next to the rule
- `repo-maintenance/references/repo-structure.md` lists the new `pipeline/`
  directory. A maintenance agent navigating from this tree would otherwise treat
  the `saboteur-ship` machinery as untracked clutter at the repo root

### Added

- `metadata.audience` on `repo-maintenance/`, `repo-maintenance-minimal/`,
  `freshness-check/`, and `improve-prompt/` — the declaration that routes a
  skill's changelog entry here instead of to `CHANGELOG.md`. Absent means
  user-facing, so no other skill needed touching
