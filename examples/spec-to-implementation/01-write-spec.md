# Step 01: Write the feature spec

**Prompt used:** `prompts/planning/write-feature-spec.md`
**Input:** A rough feature idea in plain language
**Output:** A structured markdown spec document
**Human review gate:** Read the spec before proceeding to step 2

---

## The feature idea (input)

> Allow users to export their activity history as a CSV file from the
> account settings page.

---

## Prompt sent

The `write-feature-spec.md` prompt with placeholders filled in:

```
Write a feature spec for the following:

Feature: Allow users to export their activity history as a CSV file
from the account settings page.

Additional context:
We have an internal activity logging system that records all user
actions with timestamps. The export should draw from this. The account
settings page already exists at /settings. We do not currently have any
data export functionality for users.

[... remainder of the prompt as written in the template ...]
```

---

## Model output

> **Note:** This is representative of what a well-calibrated model
> produces. Your output will differ in wording but should match this
> structure and level of specificity.

---

## Overview

This feature allows users to download their own activity history as a
CSV file from the account settings page. It addresses a recurring support
request from users who want to audit their account activity or migrate
their data, and reduces manual data export work from the support team.

## Goals

- Users can initiate a CSV export of their activity history from the
  account settings page
- The export completes and downloads within a reasonable time for typical
  account sizes
- The exported CSV contains enough information to be useful for auditing
  and data portability purposes
- The feature is available to all authenticated users without additional
  permission requirements

## Non-goals

- Exporting data types other than activity history (orders, profile data,
  etc.) — these are separate features
- Scheduled or recurring exports — this is a manual, on-demand export only
- Custom date range filtering — the export covers all activity history;
  filtering can be added in a follow-up iteration
- Async background processing for large accounts — synchronous export is
  sufficient for the expected data volume; async can be added if needed

## User stories

- As a user, I want to download my activity history as a CSV so that I
  can review it offline or import it into a spreadsheet tool
- As a user, I want the exported file to be named clearly so that I can
  identify it among my downloads

## Functional requirements

1. The account settings page must include an "Export activity history"
   button visible to all authenticated users
2. Clicking the button must initiate a CSV file download in the browser
3. The CSV must include columns for: timestamp, action type, description,
   and IP address
4. The CSV must include all activity records for the authenticated user —
   no pagination or truncation
5. The downloaded file must be named `activity-history-YYYY-MM-DD.csv`
   where the date is the export date
6. The export must complete within 5 seconds for accounts with up to
   10,000 activity records
7. If the export fails, the user must receive an error message — the
   download must not silently produce an empty or corrupt file

## Open questions

- Should the IP address column be included given privacy implications in
  some jurisdictions? Confirm with legal/product before implementing.
- What is the maximum expected number of activity records per account?
  This affects whether the 5-second requirement is achievable
  synchronously.

## Out of scope (deferred)

- Date range filtering
- Async/background processing for large accounts
- Export formats other than CSV (JSON, PDF)
- Admin-initiated exports on behalf of users

---

## What to check before proceeding to step 2

**Review gate — read the spec and verify:**

- [ ] The feature described matches what you actually want to build
- [ ] The non-goals correctly exclude things you don't want in this
      iteration — especially "date range filtering" and "async processing"
- [ ] Requirement 6 (5 seconds for 10,000 records) is achievable given
      your database and infrastructure
- [ ] The open questions are noted — IP address inclusion should be
      confirmed before implementation, not during
- [ ] The spec is specific enough to implement from without further
      clarification

**In this example:** the open question about IP address is a real
ambiguity that the prompt surfaced. Before proceeding to step 2, the
right action is to decide: include IP address, exclude it, or make it
configurable. The example proceeds assuming "include it" was confirmed.

If anything in the spec is wrong, correct it now. It's much cheaper to
edit a spec document than to edit an implementation that was built from
a wrong spec.
