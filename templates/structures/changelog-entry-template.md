# CHANGELOG entry template

Use this template when adding entries to `CHANGELOG.md`. All entries go
under `[Unreleased]` until a version is tagged.

---

## Single file addition

```markdown
- `path/to/new-file.md` — one sentence describing what it contains and
  what problem it solves
```

## Multiple related files (group under a label)

```markdown
- `category/new-feature/` — short label describing the group
    - `file-1.md` — what it contains
    - `file-2.md` — what it contains
```

## Modification

```markdown
- `path/to/file.md` — updated: [what changed and why in one sentence]
```

## Deletion

```markdown
- `path/to/file.md` — removed: [reason in one sentence]
```

## Structural or design change

```markdown
- [Short label]: [one sentence describing the change and its effect]
```

---

## Rules

- One entry per logical change, not one per file
- Entries are grouped by section (`### Added`, `### Changed`,
  `### Fixed`, `### Removed`) under the `[Unreleased]` header
- Descriptions are sentence case, past tense for removed/changed,
  present tense for added
- File paths use backtick formatting: `` `path/to/file.md` ``
- Do not add a date — dates are added when the version is tagged

---

## Section headers

Use these headers within each version block. Omit sections with no entries.

```markdown
### Added

### Changed

### Fixed

### Removed
```

---

## Example well-formed entry block

```markdown
## [Unreleased]

### Added

- `guides/repo-maintenance/dependency-map.md` — defines which files must
  change together for each type of repo modification; enforces atomicity
- `skills/repo-maintenance/` — agent skill for maintaining this repo;
  includes propose-before-act rules, template guidance, and style enforcement
    - `SKILL.md`
    - `references/repo-structure.md`
    - `references/style-guide.md`

### Changed

- `templates/prompt-template.md` — added `review-by` and `verified-against`
  optional frontmatter fields for time-sensitive content

### Fixed

- `prompts/README.md` — corrected broken link to `code/scaffold-module.md`
```
