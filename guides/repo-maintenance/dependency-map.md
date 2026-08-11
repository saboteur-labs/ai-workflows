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
"Recommended" means no check enforces it, but a reviewer will expect it.

`tools/lib/check_atomicity.sh` is what actually blocks, and this map is
written to match it. Where the two disagree, the check wins and this file is
the bug. Note that the check fires on *any* change to a file, not only on
adding or removing one — modifying a prompt requires the same README update
that adding one does.

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
| `prompts/README.md` | **Required**           | The check fires on any prompt change, not just added or removed ones. Update the description column if the purpose changed; otherwise the row still has to be touched |

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
| `skills/README.md`          | **Required**           | Update the skill's row. Applies to skills nested under a category (`skills/<category>/<name>/`) — see the coverage gap below |
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
| Parent directory `README.md`         | **Required**           | Update the file's row — the check fires on any change to a guide, not only on adding one |
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

### Adding or modifying a step file in an existing example

| File to update        | Required / Recommended | What to change                                                        |
| --------------------- | ---------------------- | ---------------------------------------------------------------------- |
| `examples/README.md`  | **Required**           | This is the file the check looks for — any change under `examples/` needs it, not the example's own README |
| Example's `README.md` | Recommended            | Add or update the step in the steps table                             |
| `CHANGELOG.md`        | **Required**           | Add entry                                                             |

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

## Known gap: skills outside a category directory

The `skills/README.md` coupling and the `-minimal` sibling check both match
`skills/<category>/<name>/SKILL.md`. Five skills sit one level higher and are
matched by neither:

```
skills/repo-maintenance/          skills/improve-prompt/
skills/repo-maintenance-minimal/  skills/improve-agent/
skills/freshness-check/
```

Changing one of these will not be blocked for a missing `skills/README.md`
row, and adding a `context-budget: medium` skill there will not be blocked for
a missing minimal variant. The couplings still apply — nothing enforces them,
so satisfy them by hand until the check covers both layouts.

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
