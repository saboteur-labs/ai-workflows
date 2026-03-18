# External claims registry

A log of external claims in this repo that have been verified, with the
verification date and source. The `freshness-check` skill reads this file
to avoid re-flagging already-verified claims as unknown.

When a claim is verified (by a human or a web-search-enabled agent),
add an entry here. When a file is updated to reflect a changed claim,
remove or update the old entry.

---

## Format

```yaml
- claim: "Exact text of the claim as it appears in the source file"
  file: path/to/source-file.md
  section: "Section heading where the claim appears"
  verified-date: YYYY-MM-DD
  source-url: https://...
  note: One sentence on what was confirmed
```

---

## Verified claims

- claim: >
  Skills conform to the Agent Skills open specification
  (agentskills.io/specification)
  file: skills/README.md
  section: "How to use"
  verified-date: 2026-03-18
  source-url: https://agentskills.io/specification
  note: >
  Spec reviewed at time of repo creation. Key requirements confirmed:
  directory-per-skill, SKILL.md with name + description frontmatter,
  name must match directory, name is lowercase-kebab max 64 chars.

- claim: >
  The `name` field must be lowercase letters, numbers, and hyphens only.
  Must not start or end with a hyphen. Max 64 characters.
  file: templates/skill-template.md
  section: "Frontmatter reference"
  verified-date: 2026-03-18
  source-url: https://agentskills.io/specification
  note: Confirmed from specification name field rules.

- claim: >
  The `description` field maximum length is 1024 characters.
  file: templates/skill-template.md
  section: "Frontmatter reference"
  verified-date: 2026-03-18
  source-url: https://agentskills.io/specification
  note: Confirmed from specification description field constraints.

---

## Claims pending verification

<!-- Add entries here when a freshness-check report identifies a claim
     that needs verification but has not yet been checked. Move to
     "Verified claims" once confirmed, or update the source file if
     the claim is no longer accurate. -->
