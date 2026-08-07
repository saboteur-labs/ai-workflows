# Step 03: Scaffold the module

**Prompt used:** `prompts/code/scaffold-module.md`
**Input:** Task 1 from step 2 (the export service), plus project conventions
**Output:** A scaffold file with typed signatures and placeholder bodies
**Human review gate:** Check that file paths and types match your project before implementing

---

## Why scaffold before implementing

Scaffolding separates two decisions that are easy to conflate: "what shape
should this code have?" and "what logic should it contain?". Settling the
shape first — function names, parameter types, return types, file location
— gives the implementation session a clear target and prevents the model
from making structural decisions mid-implementation.

For this example, we scaffold task 1 only. Tasks 2, 3, and 4 are simple
enough to implement directly from the task description without a separate
scaffold step.

---

## Prompt sent

````
Scaffold a new TypeScript module named activity-export.

Purpose: Service layer function that queries all activity records for a
user and returns them formatted for CSV export.

Follow the structure and conventions of this existing module:
```typescript
// src/services/user.ts (abbreviated for example)
import { db } from '../lib/db'
import type { User } from '../types'

export async function getUserById(userId: string): Promise<User | null> {
  throw new Error('getUserById: not yet implemented')
}

export async function updateUser(
  userId: string,
  data: Partial<User>
): Promise<User> {
  throw new Error('updateUser: not yet implemented')
}
```

Conventions to follow:
- Files in src/services/ export async functions, no classes
- Import db from '../lib/db'
- Return plain objects, not database model instances
- Errors thrown as plain Error objects with descriptive messages
- Test files colocated: src/services/activity-export.test.ts
````

---

## Model output

### src/services/activity-export.ts

```typescript
import { db } from "../lib/db";

export interface ActivityExportRecord {
    timestamp: string; // ISO 8601
    actionType: string;
    description: string;
    ipAddress: string;
}

export async function getActivityExportForUser(
    userId: string,
): Promise<ActivityExportRecord[]> {
    throw new Error("getActivityExportForUser: not yet implemented");
}
```

### src/services/activity-export.test.ts

```typescript
import { getActivityExportForUser } from "./activity-export";

describe("getActivityExportForUser", () => {
    it("TODO: getActivityExportForUser", () => {
        expect(true).toBe(true);
    });
});
```

---

## What to check before proceeding to step 4

**Review gate — read the scaffold and verify:**

- [ ] `src/services/activity-export.ts` is the correct file path for
      your project
- [ ] The `ActivityExportRecord` interface matches the columns defined in
      FR-3 of the spec (`timestamp`, `actionType`, `description`,
      `ipAddress`)
- [ ] The function signature (`userId: string`) matches how user IDs are
      typed elsewhere in your codebase — if user IDs are numbers or UUIDs
      with a branded type, update the parameter type now
- [ ] The import path `../lib/db` is correct for your project structure
- [ ] The test file location (`src/services/activity-export.test.ts`)
      matches your project's test co-location convention

**In this example:** the scaffold is minimal and correct. The one thing
worth checking is the `timestamp` field type — returning `string` (ISO 8601) is a deliberate choice to avoid timezone handling complexity in the
CSV serialiser. If your activity log stores timestamps as `Date` objects,
the service function should convert them to strings before returning,
not leave that to the CSV layer.

The scaffold is now the input for a `skills/coding/implement-feature/`
session: "Implement `getActivityExportForUser` in this scaffold. The
function should query the `activity_log` table for all records where
`user_id = userId`, ordered by timestamp descending, and return them
mapped to `ActivityExportRecord`."
