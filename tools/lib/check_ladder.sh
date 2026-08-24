#!/usr/bin/env bash
# lib/check_ladder.sh
#
# The saboteur-ship ladder — which artifact sits at which rung, the path it is
# written to, and the schema it validates against — is restated in more than one
# document. The pipeline lead needs it to drive a run; the onboarding skill needs
# it to inventory a repository against. Neither can reasonably link to the other
# and expect an agent mid-run to follow the link.
#
# So the table is duplicated on purpose, and this check is the price of that:
# `pipeline/skills/saboteur-ship/SKILL.md` owns the ladder, and every other file
# carrying one must agree with it cell for cell. Formatting is normalised before
# comparison, so column padding may differ.
#
# The paths in that table are load-bearing — pipeline/hooks/pipeline-gate.sh
# exempts `specs/` from the plan gate and denies everything else — so a rung
# whose path drifts in one file and not another is not a documentation nit. It
# is a denied write halfway through someone's run.
#
# Also asserts every schema the ladder names is one check-outputs.js knows, so a
# renamed schema cannot leave the ladder pointing at nothing.
#
# NOT covered: ~/.claude/testbeds/ship-testbed.md carries a fourth copy and
# lives outside this repo deliberately (it is an answer key for pipeline runs).
# Nothing can check it from here. Update it by hand when the ladder changes.
#
# Exit codes: 0 = pass, 1 = fail (blocking)

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED='\033[0;31m'; GREEN='\033[0;32m'; RESET='\033[0m'
else
  RED=''; GREEN=''; RESET=''
fi

SOURCE_OF_TRUTH="pipeline/skills/saboteur-ship/SKILL.md"

# A carrier is a file with a heading matching /ladder/i. Only rows inside that
# section count — plenty of unrelated docs have numbered tables, and matching on
# row shape alone pulls them in as false carriers.
HEADING_RE='^#{1,6}[[:space:]].*[Ll]adder'

# Extract the ladder section's rows and collapse column padding, so only cell
# contents are compared and formatting may differ between files.
normalise_ladder() {
  awk -v hre="$HEADING_RE" '
    $0 ~ hre { inlad = 1; next }
    inlad && /^#{1,6}[[:space:]]/ { inlad = 0 }
    inlad && /^\|[[:space:]]*[0-9]+[[:space:]]*\|/ {
      out = ""
      n = split($0, cell, "|")
      for (i = 2; i < n; i++) {
        c = cell[i]
        gsub(/^[ \t]+|[ \t]+$/, "", c)
        out = out (i > 2 ? " | " : "") c
      }
      print out
    }
  ' "$1" 2>/dev/null
}

failed=0

if [[ ! -f "$SOURCE_OF_TRUTH" ]]; then
  echo -e "${RED}FAIL${RESET}  ladder source of truth not found: $SOURCE_OF_TRUTH"
  exit 1
fi

expected="$(normalise_ladder "$SOURCE_OF_TRUTH")"
if [[ -z "$expected" ]]; then
  echo -e "${RED}FAIL${RESET}  no ladder table found in $SOURCE_OF_TRUTH"
  exit 1
fi

# ── Every other carrier must match ───────────────────────────────────────────
carriers=()
while IFS= read -r f; do
  [[ -n "$f" ]] && carriers+=("$f")
done < <(
  grep -rlE "$HEADING_RE" --include="*.md" pipeline skills prompts guides examples 2>/dev/null \
    | grep -v "^${SOURCE_OF_TRUTH}$" | sort
)

compared=1   # the source of truth itself

for f in "${carriers[@]:-}"; do
  [[ -z "$f" ]] && continue
  actual="$(normalise_ladder "$f")"
  # A file may discuss the ladder without restating it. Prose is not a copy.
  [[ -z "$actual" ]] && continue
  compared=$(( compared + 1 ))
  if [[ "$actual" != "$expected" ]]; then
    echo -e "${RED}FAIL${RESET}  ladder in $f disagrees with $SOURCE_OF_TRUTH"
    echo "        expected (from $SOURCE_OF_TRUTH):"
    echo "$expected" | sed 's/^/          /'
    echo "        found:"
    echo "$actual" | sed 's/^/          /'
    failed=1
  fi
done

# ── Every schema the ladder names must exist ─────────────────────────────────
if command -v node >/dev/null 2>&1; then
  known="$(node tools/lib/check-outputs.js --list 2>/dev/null | awk '{print $1}')"
  while IFS= read -r id; do
    [[ -z "$id" ]] && continue
    if ! echo "$known" | grep -qx "$id"; then
      echo -e "${RED}FAIL${RESET}  ladder names schema '${id}', which check-outputs.js does not know"
      failed=1
    fi
  done < <(echo "$expected" | grep -oE 'sab\.[a-z-]+/[0-9]+' | sort -u)
fi

if [[ "$failed" -eq 0 ]]; then
  echo -e "${GREEN}PASS${RESET}  ladder consistent across ${compared} file(s) restating it; all named schemas exist."
  exit 0
fi
exit 1
