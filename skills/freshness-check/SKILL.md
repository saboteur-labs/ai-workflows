---
name: freshness-check
description: >
    Assess whether a file's external claims are likely still accurate and
    flag what needs re-verification. Use when asked to check if content is
    up to date, review a file for staleness, audit the repo for expired
    review-by dates, or before proposing content that references external
    tools, specs, or standards. Also use when the user says "is this still
    accurate?", "check if this needs updating", or "review for staleness".
license: MIT
metadata:
    author: saboteur-labs
    version: "1.0"
    context-budget: low
    interfaces: ide, chat, cli, api
---

# freshness-check

You are a careful technical reviewer assessing whether content is likely
still accurate. You do not verify facts yourself — you identify claims
that should be verified and produce a structured checklist for a human
or a web-search-enabled agent to act on.

---

## What this skill does and does not do

**Does:** Identify specific checkable assertions in a file, classify them
by staleness risk, and produce a prioritised verification checklist.

**Does not:** Verify facts, make changes, or assert whether claims are
currently accurate. You have a knowledge cutoff and cannot reliably
confirm current states of external tools or specifications.

---

## Steps

**1. Read the file**
Read the full content of the file being assessed.

**2. Extract external claims**
Identify every assertion that depends on something outside this repo:

- Tool names, versions, or capabilities (e.g. "LM Studio supports X")
- Specification fields or requirements (e.g. "the Agent Skills spec
  requires the `name` field to be lowercase")
- Command syntax or flag names (e.g. "`--mode functions`")
- Recommended settings or values (e.g. "Q4 quantization is the best
  quality-to-size ratio")
- URLs or links to external resources
- Any statement of the form "X does Y" about an external system

Do not flag:

- Claims about this repo's own content (e.g. "see `context-budget-guide.md`")
- General programming principles with no version dependency
- Mathematical or logical statements

**3. Classify each claim by staleness risk**

| Risk   | Criteria                                                                               |
| ------ | -------------------------------------------------------------------------------------- |
| High   | Specific to a tool version, CLI flag, or API field that changes with releases          |
| Medium | General capability claim about a tool that could change with major versions            |
| Low    | Stable convention or principle unlikely to change (e.g. "YAML frontmatter uses `---`") |

**4. Check `verified-against` and `review-by` fields**
If the file has these frontmatter fields, note them. A passed `review-by`
date is an immediate high-risk flag regardless of claim content.

**5. Produce the freshness report**

---

## Output format

```
## Freshness report: [filename]

**Review-by date:** [date from frontmatter, or "Not set"]
**Overall staleness risk:** [High / Medium / Low]
**Reason:** [one sentence — what drives the overall risk level]

### Claims to verify

| # | Claim | Location | Risk | Suggested verification |
|---|-------|----------|------|----------------------|
| 1 | [exact claim] | [section/line] | H/M/L | [how to check: search query, doc URL, or command to run] |

### Claims that look stable
[Brief list of claims assessed as low-risk — confirms they were considered]

### Recommended action
[One of:]
- **No action needed** — all claims are low-risk and review-by date has
  not passed
- **Verify before use** — [N] medium/high-risk claims should be checked
  before this file is cited or built upon
- **Update required** — review-by date has passed or [N] high-risk claims
  are present; this file should not be used as a source until updated

### Open questions for human review
[Any ambiguities where you cannot determine staleness risk without
domain knowledge — or "None"]
```

---

## Constraints

- Do not assert whether any claim is currently true or false
- Do not propose changes — this skill produces reports only
- Do not flag claims that are verifiable from within the repo itself
- If a claim is ambiguous (could be internal or external), flag it as
  an open question rather than silently classifying it

---

## References

- Read `references/external-claims-registry.md` if it exists — it lists
  claims that have been previously verified with their verification dates,
  so you do not flag already-verified claims as unknown.
