# examples/

Worked end-to-end workflow demonstrations. Each example shows how to chain
prompts, skills, and tools together to complete a realistic development task.

| Example                                                        | Description                                                                |
| -------------------------------------------------------------- | -------------------------------------------------------------------------- |
| [`spec-to-implementation/`](./spec-to-implementation/)         | Full feature workflow: spec → task breakdown → scaffold → implement → test |
| [`low-context-chunked-review/`](./low-context-chunked-review/) | Code review on a large file using chunking for small local models          |

## Schema conformance

The documents produced in `spec-to-implementation/` steps 01 and 02 are not
just illustrative — they conform to the schemas their prompts declare, and are
meant to stay that way:

```sh
node tools/lib/check-outputs.js --doc examples/spec-to-implementation/01-write-spec.md --schema sab.feature-spec/1
node tools/lib/check-outputs.js --doc examples/spec-to-implementation/02-break-into-tasks.md --schema sab.tasks/1
```

Both report a warning that the file is not at the schema's conventional output
path, which is expected — they are examples, not real specs.

`./tools/validate.sh` does **not** check these documents; it verifies only that
each schema agrees with the output format authored in its prompt. So when a
schema or a prompt's output format changes, run the two commands above — the
examples are the most likely thing to drift, and nothing else will catch it.

Write them at the repo's normal width. Conformance does not depend on where
lines break: the checker joins a list entry or field value that wraps onto
indented continuation lines, so a user story may carry its `so that` clause
and a requirement its `[US-n]` reference on the following line. A blank line
ends an entry, so prose after a list is never absorbed into it.
