---
name: runlog
description: >
    Read the hook-backed runlog: a per-repo, per-session record of what Claude
    Code agents attempted — every prompt, tool call, tool result, tool failure,
    subagent start and stop, and turn end. Use this skill when the user asks
    what an agent did, which tools a session called, where a run failed or
    stalled, what a subagent was asked and what it returned, or wants to walk
    through a past session. Triggers on "show the runlog", "what did the agent
    do", "what happened in that session", "which tool calls failed", "list my
    sessions in this repo", and "is the runlog hook installed". Also use it to
    install or check the recording hook. The runlog records facts only; this
    skill reads them and never labels an event as a mistake, a correction, or a
    denial on its own.
license: MIT
compatibility: >
    Claude Code CLI only — the log is written by Claude Code hooks. Requires
    bash, jq, and git; perl is used for append locking and is present on macOS
    and most Linux distributions.
metadata:
    author: saboteur-labs
    version: "0.1"
    context-budget: low
    interfaces: cli
    review-by: 2027-03-14
verified-against:
    - url: https://code.claude.com/docs/en/hooks
      date: 2026-09-14
      note: Hook event names, common input fields, async hooks, and that tool hooks fire inside subagents
---

# runlog

You read the runlog: a record of what agents did, one file per session, filed
under the repository the session started in. Your job is to show the user what
was recorded, accurately, and to keep what was recorded separate from what it
might mean.

## Where the log is

```
$RUNLOG_ROOT/                      default ~/.claude/runlogs
├── sessions/<session_id>          the repo key the session is filed under
└── repos/<repo-key>/<session_id>.jsonl
```

Each line is one hook event:

```json
{"v":1,"ts":"…","ts_ms":0,"repo":"…","event":"PreToolUse","session_id":"…","agent_id":null,"tool_use_id":"…","payload":{…}}
```

`payload` is the hook input as Claude Code sent it, with strings over 2000
characters truncated and common secret shapes replaced by `[REDACTED]`.

## Scripts

Both scripts live in `scripts/` next to this file.

- `scripts/runlog-show.sh --list [DIR]` — sessions filed under DIR's repo,
  newest first, with time span, event count, and the first prompt.
  Run when: the user has not named a session.
- `scripts/runlog-show.sh <session_id | file.jsonl>` — one session as a
  timeline: time, agent, event, tool, and a one-line summary.
  Run when: the user wants to see what happened in a session.
- `scripts/runlog-record.sh --repo-key DIR` — print the repo key for DIR.
  Run when: you need the log directory for a repo.
- `scripts/runlog-record.sh` — the hook itself. You do not run it by hand.

For anything the timeline does not show, query the JSONL directly with `jq`,
for example every failure in a session:

```sh
jq -c 'select(.event == "PostToolUseFailure") | {ts, tool: .payload.tool_name, error: .payload.error}' FILE
```

## Workflow

1. Check the hook is recording: `$RUNLOG_ROOT/repos/` exists and has a recent
   file. If it does not, read `references/install.md` and walk the user
   through it. Do not edit `settings.json` without their approval.
2. Find the session. The current session is usually the newest file in
   `--list`, but not necessarily — two sessions in one repo write at once.
   Confirm by the first prompt when it matters.
3. Show the timeline, or answer the question from a `jq` query.
4. Report what was recorded. Quote events; do not characterise them.

## Gotchas

- A `PreToolUse` with no `PostToolUse` or `PostToolUseFailure` shows as
  "no result recorded". That is the whole finding. The call may have been
  denied, rejected at a permission prompt, blocked by another hook, or
  interrupted, and the log does not say which. Do not pick one.
- A failed tool call is not a failed agent. A test run that exits non-zero may
  be exactly the planned red of a test the session just wrote. Do not call an
  event a mistake or a correction — that interpretation is not built yet.
- Events are written by async hooks and can land out of order. Order by
  `ts_ms`, not by line number. `runlog-show.sh` already does.
- A session stays filed under the repo it started in, even after it works in
  another repo or a worktree. Look at `payload.cwd` for where an event
  happened.
- Payload field names come from Claude Code, not from this skill, and can
  change between versions. Read a raw line before relying on a field you have
  not seen in this log.
- Truncated strings end in `…[truncated N chars]`. The full content, if it
  still exists, is in the transcript at `payload.transcript_path`.
- The log holds commands, file contents, and prompts. Redaction is
  best-effort pattern matching. Do not paste log contents anywhere outside the
  user's machine.

## References

- Read `references/install.md` when the hook is not recording, when the user
  asks to install or uninstall it, or when hook errors appear in the session.
