#!/usr/bin/env bash
# lib/check_outputs.sh
#
# Checks that every prompt declaring an `## Output schema` block keeps that
# machine contract consistent with the output format authored in its `## Prompt`
# block. The two are the machine and human halves of one contract; this is what
# stops them drifting apart.
#
# Document-level validation (checking a produced spec or task list against a
# schema) is the same engine, invoked directly:
#
#   node tools/lib/check-outputs.js --doc <file> --schema <id>
#   node tools/lib/check-outputs.js --doc <file> --schema <id> --json
#
# Exit codes: 0 = pass, 1 = fail (blocking), 2 = warn only

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED='\033[0;31m'; RESET='\033[0m'
else
  RED=''; RESET=''
fi

if ! command -v node >/dev/null 2>&1; then
  echo -e "${RED}FAIL${RESET}  node is required for the outputs check but was not found on PATH."
  exit 1
fi

# --changed-only is accepted for interface parity with the other checks. The
# schema set is small and interdependent (cross-document reference integrity),
# so it is always checked as a whole.
exec node tools/lib/check-outputs.js --prompts
