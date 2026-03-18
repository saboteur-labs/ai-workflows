# Step 02: Break the spec into tasks

**Prompt used:** `prompts/planning/break-into-tasks.md`
**Input:** The reviewed spec from step 1
**Output:** An ordered, estimated task list
**Human review gate:** Review task order and done conditions before step 3

---

## Prompt sent

```
Break the following feature spec into an implementation task list.

Spec:
[spec from step 01 pasted here]

Granularity: half-day tasks, estimated in hours
```

---

## Model output

### Task 1: Add export service method

**What:** A service layer function that queries all activity records for
a user and returns them formatted for CSV export
**Files:** `src/services/activity-export.ts` (create)
**Done when:** The function accepts a `userId`, queries the activity log,
and returns an array of objects with `timestamp`, `actionType`,
`description`, and `ipAddress` fields — confirmed by a passing unit test
**Depends on:** none
**Estimate:** 2–3 hours
**Notes:** Check whether an existing query in the activity service can
be reused. The return type should be a plain object array, not a
database model, to keep the service layer clean.

---

### Task 2: Add CSV serialisation utility

**What:** A utility function that converts the export service output into
a correctly formatted CSV string with headers
**Files:** `src/lib/csv.ts` (create)
**Done when:** The function produces a valid CSV string with a header row
and one data row per record, with values correctly escaped — confirmed by
unit tests covering: empty input, special characters in values, and a
normal multi-row case
**Depends on:** none (can be developed in parallel with task 1)
**Estimate:** 1–2 hours
**Notes:** Use the built-in approach for your language rather than a
library unless escaping rules are complex. CSV escaping rules: wrap
values containing commas, quotes, or newlines in double quotes; escape
internal double quotes by doubling them.

---

### Task 3: Add export route handler

**What:** A GET endpoint at `/api/settings/export-activity` that calls
the export service, serialises to CSV, and returns it as a file download
**Files:** `src/routes/settings.ts` (modify)
**Done when:** A GET request to the endpoint by an authenticated user
returns a 200 response with `Content-Type: text/csv`,
`Content-Disposition: attachment; filename="activity-history-YYYY-MM-DD.csv"`,
and valid CSV body — confirmed by an integration test
**Depends on:** Task 1, Task 2
**Estimate:** 2 hours
**Notes:** The endpoint must be authenticated — use the existing auth
middleware. Return 500 with a user-facing error message if the export
fails; do not return a partial or empty file.

---

### Task 4: Add export button to settings page

**What:** An "Export activity history" button on the account settings
page that triggers the CSV download via the route from task 3
**Files:** `src/pages/settings.tsx` (or equivalent frontend file)
**Done when:** The button is visible on the settings page for
authenticated users, clicking it triggers a file download, and an error
message is shown if the download fails
**Depends on:** Task 3
**Estimate:** 1–2 hours
**Notes:** The download can be triggered by a standard anchor tag with
`href` pointing to the endpoint and `download` attribute set, or via a
`fetch` call followed by a blob URL. The anchor approach is simpler and
avoids holding the response in memory.

---

### Task 5: End-to-end test

**What:** An e2e test verifying the full user journey: navigate to
settings, click export, verify a CSV file is downloaded
**Files:** `tests/e2e/activity-export.spec.ts` (create)
**Done when:** The e2e test passes in CI covering: successful export for
a user with activity records, and appropriate error handling for a user
with no records
**Depends on:** Task 4
**Estimate:** 1–2 hours

---

## Summary

- Total tasks: 5
- Total estimated effort: 7–11 hours
- Critical path: Tasks 1 → 3 → 4 → 5 (tasks 1 and 2 can run in parallel)
- Risks: Task 1 depends on the activity log query being performant enough
  to meet the 5-second requirement from requirement 6 — validate this
  with a test query before committing to the synchronous approach

---

## What to check before proceeding to step 3

**Review gate — read the task list and verify:**

- [ ] The critical path (1 → 3 → 4 → 5) is correct and task 2 can
      genuinely run in parallel with task 1
- [ ] Each "Done when" condition is specific and verifiable — not "works
      correctly" but a concrete observable state
- [ ] The file paths match your actual project structure
- [ ] The performance risk in task 1 is on your radar — consider running
      a test query against the activity log before starting implementation
- [ ] The total estimate (7–11 hours) matches your intuition for this
      feature

**In this example:** the model correctly identified that tasks 1 and 2
are independent and can be parallelised. If working alone, you'd do them
sequentially — start with task 1 since the route (task 3) depends on it
more directly than the CSV utility does. The performance note on task 1
is worth heeding: run a `SELECT COUNT(*)` on the activity log for a
typical user before assuming synchronous export will meet the 5-second
requirement.
