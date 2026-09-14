# Installing the runlog hook

The runlog is written by one script, `scripts/runlog-record.sh`, registered for
eight hook events in the user's Claude Code settings. Installing it is two
steps: link the skill, then register the hook. Registration edits
`~/.claude/settings.json`, which affects every session on the machine — show
the user the exact change and get approval before making it.

## 1. Link the skill

Symlink rather than copy, so the installed skill and hook track the
ai-workflows repo:

```sh
ln -s "$PWD/skills/runlog" ~/.claude/skills/runlog
```

Run from the root of the ai-workflows checkout. The link follows whichever
branch that checkout is on; a branch without `skills/runlog/` removes the hook
script, and the guard in step 2 keeps that from erroring on every tool call.

## 2. Register the hook

Merge this into the `hooks` object of `~/.claude/settings.json`. Existing hooks
for the same events stay; each event takes a list, and every matching hook
runs.

```json
{
  "hooks": {
    "SessionStart":       [{ "hooks": [{ "type": "command", "async": true, "command": "f=$HOME/.claude/skills/runlog/scripts/runlog-record.sh; [ -f \"$f\" ] && bash \"$f\"; exit 0" }] }],
    "UserPromptSubmit":   [{ "hooks": [{ "type": "command", "async": true, "command": "f=$HOME/.claude/skills/runlog/scripts/runlog-record.sh; [ -f \"$f\" ] && bash \"$f\"; exit 0" }] }],
    "PreToolUse":         [{ "hooks": [{ "type": "command", "async": true, "command": "f=$HOME/.claude/skills/runlog/scripts/runlog-record.sh; [ -f \"$f\" ] && bash \"$f\"; exit 0" }] }],
    "PostToolUse":        [{ "hooks": [{ "type": "command", "async": true, "command": "f=$HOME/.claude/skills/runlog/scripts/runlog-record.sh; [ -f \"$f\" ] && bash \"$f\"; exit 0" }] }],
    "PostToolUseFailure": [{ "hooks": [{ "type": "command", "async": true, "command": "f=$HOME/.claude/skills/runlog/scripts/runlog-record.sh; [ -f \"$f\" ] && bash \"$f\"; exit 0" }] }],
    "SubagentStart":      [{ "hooks": [{ "type": "command", "async": true, "command": "f=$HOME/.claude/skills/runlog/scripts/runlog-record.sh; [ -f \"$f\" ] && bash \"$f\"; exit 0" }] }],
    "SubagentStop":       [{ "hooks": [{ "type": "command", "async": true, "command": "f=$HOME/.claude/skills/runlog/scripts/runlog-record.sh; [ -f \"$f\" ] && bash \"$f\"; exit 0" }] }],
    "Stop":               [{ "hooks": [{ "type": "command", "async": true, "command": "f=$HOME/.claude/skills/runlog/scripts/runlog-record.sh; [ -f \"$f\" ] && bash \"$f\"; exit 0" }] }]
  }
}
```

No `matcher` is set, so tool events fire for every tool, including MCP tools.
`async: true` means the hook never delays a tool call, and a slow or failed
write cannot block the agent. The trailing `exit 0` matters: exit code 2 from a
`PreToolUse` hook blocks the tool call.

## 3. Confirm it records

Start a new session in any repo, run one tool call, then:

```sh
~/.claude/skills/runlog/scripts/runlog-show.sh --list
```

A session listed with a few events means the hook is live.

## Configuration

| Variable            | Default              | Effect                                   |
| ------------------- | -------------------- | ---------------------------------------- |
| `RUNLOG_ROOT`       | `~/.claude/runlogs`  | Where sessions and repo logs are written |
| `RUNLOG_MAX_STRING` | `2000`               | Characters kept per string in a payload  |

Set them in the `env` block of `settings.json` so hooks and the reader agree.

## Uninstalling

Remove the eight entries from `settings.json`, then the symlink. Logs under
`RUNLOG_ROOT` are left in place; delete them separately if wanted.

## What it costs

Measured on macOS with synthetic payloads: about 35 ms per event, run in the
background. 200 concurrent appends of ~12 KB lines to one session file
produced 200 intact lines across three runs. Log growth is bounded per event
by `RUNLOG_MAX_STRING`, not per session — a long session is a large file.
