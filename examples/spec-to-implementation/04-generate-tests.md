# Step 04: Generate unit tests

**Prompt used:** `prompts/code/generate-unit-tests.md`
**Input:** The implemented `activity-export.ts` service (after task 1 is done)
**Output:** A complete unit test suite for the export service
**Human review gate:** Run the tests; read the coverage before committing

---

## When to run this step

Run this after the implementation of task 1 is complete and the function
body is no longer a placeholder. Generating tests against a placeholder
that throws `NotImplementedError` produces meaningless tests.

For this example, we show the prompt and output for the export service
only. The CSV utility (task 2) and route handler (task 3) would follow
the same pattern with their own test generation passes.

---

## Assumed implementation (input)

After task 1 is implemented, `src/services/activity-export.ts` looks
something like this:

```typescript
import { db } from "../lib/db";

export interface ActivityExportRecord {
    timestamp: string;
    actionType: string;
    description: string;
    ipAddress: string;
}

export async function getActivityExportForUser(
    userId: string,
): Promise<ActivityExportRecord[]> {
    const rows = await db.query(
        `SELECT timestamp, action_type, description, ip_address
     FROM activity_log
     WHERE user_id = $1
     ORDER BY timestamp DESC`,
        [userId],
    );
    return rows.map((row) => ({
        timestamp: row.timestamp.toISOString(),
        actionType: row.action_type,
        description: row.description,
        ipAddress: row.ip_address,
    }));
}
```

---

## Prompt sent

````
I need unit tests for the following TypeScript code.

Framework: Jest

Source code:
```typescript
[implementation above pasted here]
```

Generate a complete unit test file that:
[... remainder of the prompt as written in the template ...]

Additional instructions: Mock the `db` module from '../lib/db'. The
`db.query` mock should return an array of database row objects with
snake_case keys matching the SELECT columns.
````

---

## Model output

```typescript
import { getActivityExportForUser } from "./activity-export";
import { db } from "../lib/db";

jest.mock("../lib/db");
const mockDb = db as jest.Mocked<typeof db>;

const mockRows = [
    {
        timestamp: new Date("2024-01-15T10:30:00Z"),
        action_type: "login",
        description: "User logged in",
        ip_address: "192.168.1.1",
    },
    {
        timestamp: new Date("2024-01-14T09:00:00Z"),
        action_type: "export",
        description: "Exported activity history",
        ip_address: "192.168.1.1",
    },
];

describe("getActivityExportForUser", () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    it("getActivityExportForUser returns mapped records for a valid user", async () => {
        mockDb.query.mockResolvedValue(mockRows);

        const result = await getActivityExportForUser("user-123");

        expect(result).toEqual([
            {
                timestamp: "2024-01-15T10:30:00.000Z",
                actionType: "login",
                description: "User logged in",
                ipAddress: "192.168.1.1",
            },
            {
                timestamp: "2024-01-14T09:00:00.000Z",
                actionType: "export",
                description: "Exported activity history",
                ipAddress: "192.168.1.1",
            },
        ]);
    });

    it("getActivityExportForUser returns empty array when user has no activity", async () => {
        mockDb.query.mockResolvedValue([]);

        const result = await getActivityExportForUser("user-no-activity");

        expect(result).toEqual([]);
    });

    it("getActivityExportForUser passes the correct userId to the query", async () => {
        mockDb.query.mockResolvedValue([]);

        await getActivityExportForUser("user-456");

        expect(mockDb.query).toHaveBeenCalledWith(
            expect.stringContaining("WHERE user_id = $1"),
            ["user-456"],
        );
    });

    it("getActivityExportForUser converts timestamps to ISO 8601 strings", async () => {
        mockDb.query.mockResolvedValue([mockRows[0]]);

        const result = await getActivityExportForUser("user-123");

        expect(result[0].timestamp).toBe("2024-01-15T10:30:00.000Z");
        expect(typeof result[0].timestamp).toBe("string");
    });

    it("getActivityExportForUser propagates database errors", async () => {
        mockDb.query.mockRejectedValue(new Error("Connection refused"));

        await expect(getActivityExportForUser("user-123")).rejects.toThrow(
            "Connection refused",
        );
    });
});
```

---

## What to check before committing

**Review gate — run the tests, then read the output:**

- [ ] All tests pass: `npx jest src/services/activity-export.test.ts`
- [ ] The test for userId propagation (`toHaveBeenCalledWith`) correctly
      reflects your actual SQL query string — update the `stringContaining`
      matcher if your query differs
- [ ] The ISO 8601 format assertion (`2024-01-15T10:30:00.000Z`) matches
      what JavaScript's `Date.toISOString()` actually produces for your
      timezone setup
- [ ] The error propagation test covers a realistic failure mode for your
      database client

**Coverage gaps to consider adding:**

- A test for a user ID that contains special characters (if your system
  allows non-UUID user IDs)
- A test verifying records are returned in descending timestamp order,
  if ordering is important for the CSV consumer

**In this example:** the generated tests are solid and cover the most
important cases. The one to scrutinise is the query matcher test —
`expect.stringContaining('WHERE user_id = $1')` is brittle if the query
is formatted differently (whitespace, line breaks). A more robust
approach is to assert on the parameters array only and trust the SQL to
be correct via a separate integration test.

---

## End of pipeline

After tests pass for all five tasks, the feature is complete. The next
steps are:

1. Run the full test suite to check for unintended breakage
2. Open a PR — the review gate at the PR level is human, not AI
3. If the PR review finds issues, use `skills/coding/debug-issue/` for
   bugs and `skills/coding/implement-feature/` for change requests
