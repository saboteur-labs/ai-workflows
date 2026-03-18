# Dependency map

Every file change in this repo has a set of coupled files that must be
updated in the same PR. This map defines those couplings. Consult it
before writing any change proposal.

A PR that does not satisfy these couplings will fail the
`validate-change-atomicity` CI check and be blocked from merging.

---

## How to read this map

Each entry defines a trigger (what changed) and the required co-changes
(what must also change). "Required" means the PR is blocked without it.
"Recommended" means CI will warn but not block.

---

## Prompt changes

### Adding a new prompt file

| File to update      | Required / Recommended | What to change                                                     |
| ------------------- | ---------------------- | ------------------------------------------------------------------ |
| `prompts/README.md` | **Required**           | Add a row to the index table in the correct category section       |
| `CHANGELOG.md`      | **Required**           | Add entry under `[Unreleased]` using `changelog-entry-template.md` |

### Modifying a prompt file

| File to update      | Required / Recommended | What to change                                            |
| ------------------- | ---------------------- | --------------------------------------------------------- |
| `CHANGELOG.md`      | **Required**           | Add entry describing what changed and why                 |
| `prompts/README.md` | Recommended            | Update description column if the prompt's purpose changed |

### Deleting a prompt file

| File to update         | Required / Recommended | What to change                          |
| ---------------------- | ---------------------- | --------------------------------------- |
| `prompts/README.md`    | **Required**           | Remove the row from the index table     |
| `CHANGELOG.md`         | **Required**           | Add entry noting the removal and reason |
| Any file linking to it | **Required**           | Remove or update the broken link        |

---

## Skill changes

### Adding a new skill directory

| File to update                | Required / Recommended                     | What to change                                               |
| ----------------------------- | ------------------------------------------ | ------------------------------------------------------------ |
| `skills/README.md`            | **Required**                               | Add a row to the index table in the correct category section |
| `CHANGELOG.md`                | **Required**                               | Add entry under `[Unreleased]`                               |
| Sibling `-minimal/` directory | **Required** (if `context-budget: medium`) | Create minimal variant                                       |

### Adding or modifying a skill's `references/` files

| File to update | Required / Recommended | What to change                                                 |
| -------------- | ---------------------- | -------------------------------------------------------------- |
| `CHANGELOG.md` | Recommended            | Note the reference file addition if it changes skill behaviour |

### Modifying a `SKILL.md` file

| File to update              | Required / Recommended | What to change                                                 |
| --------------------------- | ---------------------- | -------------------------------------------------------------- |
| `CHANGELOG.md`              | **Required**           | Add entry describing what changed                              |
| Sibling `-minimal/SKILL.md` | Recommended            | Check if the minimal variant needs updating to stay consistent |

### Deleting a skill directory

| File to update                | Required / Recommended | What to change                   |
| ----------------------------- | ---------------------- | -------------------------------- |
| `skills/README.md`            | **Required**           | Remove the row                   |
| `CHANGELOG.md`                | **Required**           | Add entry noting the removal     |
| Any file linking to it        | **Required**           | Remove or update the broken link |
| Sibling `-minimal/` directory | **Required**           | Delete minimal variant too       |

---

## Guide changes

### Adding a new guide file

| File to update                                         | Required / Recommended | What to change                                      |
| ------------------------------------------------------ | ---------------------- | --------------------------------------------------- |
| Parent directory `README.md`                           | **Required**           | Add a row to the status table                       |
| `guides/README.md`                                     | Recommended            | Update the parent directory description if relevant |
| `CHANGELOG.md`                                         | **Required**           | Add entry under `[Unreleased]`                      |
| `skills/repo-maintenance/references/repo-structure.md` | Recommended            | Add the new file to the directory tree              |

### Adding a new guide subdirectory

| File to update                                         | Required / Recommended | What to change                                                   |
| ------------------------------------------------------ | ---------------------- | ---------------------------------------------------------------- |
| `guides/README.md`                                     | **Required**           | Add a row for the new subdirectory                               |
| `CHANGELOG.md`                                         | **Required**           | Add entry                                                        |
| `skills/repo-maintenance/references/repo-structure.md` | **Required**           | Add the new directory                                            |
| New `README.md` in the directory                       | **Required**           | Create using `templates/structures/directory-readme-template.md` |

### Modifying a guide file

| File to update                       | Required / Recommended | What to change                             |
| ------------------------------------ | ---------------------- | ------------------------------------------ |
| `CHANGELOG.md`                       | **Required**           | Add entry                                  |
| `verified-against` field in the file | Recommended            | Update if external claims were re-verified |

### Completing a stub guide (`🔲 Stub` → `✅ Done`)

| File to update               | Required / Recommended | What to change                    |
| ---------------------------- | ---------------------- | --------------------------------- |
| Parent directory `README.md` | **Required**           | Update status column to `✅ Done` |
| `CHANGELOG.md`               | **Required**           | Add entry                         |

---

## Example changes

### Adding a new example directory

| File to update       | Required / Recommended | What to change               |
| -------------------- | ---------------------- | ---------------------------- |
| `examples/README.md` | **Required**           | Add a row to the index table |
| `CHANGELOG.md`       | **Required**           | Add entry                    |

### Adding a step file to an existing example

| File to update        | Required / Recommended | What to change                  |
| --------------------- | ---------------------- | ------------------------------- |
| Example's `README.md` | **Required**           | Add the step to the steps table |
| `CHANGELOG.md`        | **Required**           | Add entry                       |

---

## Template changes

### Modifying any file in `templates/`

| File to update                    | Required / Recommended | What to change                                                   |
| --------------------------------- | ---------------------- | ---------------------------------------------------------------- |
| `CHANGELOG.md`                    | **Required**           | Add entry — note the template name and what changed              |
| Existing files using the template | Recommended            | Review for consistency; update if the change affects correctness |

Template changes require explicit human approval and may not be made by
agents without instruction.

---

## Tool changes

### Modifying or adding a tool in `tools/`

| File to update    | Required / Recommended | What to change             |
| ----------------- | ---------------------- | -------------------------- |
| `tools/README.md` | **Required**           | Update usage documentation |
| `CHANGELOG.md`    | **Required**           | Add entry                  |

---

## CI workflow changes

CI workflows may not be modified by agents without explicit human approval.
Any modification requires:

| File to update | Required / Recommended | What to change                             |
| -------------- | ---------------------- | ------------------------------------------ |
| `CHANGELOG.md` | **Required**           | Add entry describing the change and reason |

---

## Root file changes

### Modifying `README.md`

| File to update | Required / Recommended | What to change |
| -------------- | ---------------------- | -------------- |
| `CHANGELOG.md` | **Required**           | Add entry      |

### Modifying `CONTRIBUTING.md`

| File to update | Required / Recommended | What to change |
| -------------- | ---------------------- | -------------- |
| `CHANGELOG.md` | **Required**           | Add entry      |

### Modifying `AGENTS.md`

Requires explicit human approval. Cannot be modified by agents without
instruction. Required co-changes:

| File to update | Required / Recommended | What to change |
| -------------- | ---------------------- | -------------- |
| `CHANGELOG.md` | **Required**           | Add entry      |

---

## Cross-cutting: link changes

When any file is renamed, moved, or deleted, all files that link to it
must be updated in the same PR. The `validate-links` CI check will catch
broken links after the fact, but the dependency map requires proactive
repair — do not submit a PR with known broken links expecting CI to
catch them.

**Finding links to a file:**

```sh
grep -r "filename-to-check" . --include="*.md" -l
```
