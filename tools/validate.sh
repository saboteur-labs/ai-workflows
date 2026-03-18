#!/usr/bin/env bash
# validate.sh
#
# Run all repo validation checks locally before pushing.
# Mirrors the full set of CI checks so failures are caught before CI.
#
# Usage:
#   ./tools/validate.sh                   Run all checks
#   ./tools/validate.sh --check frontmatter
#   ./tools/validate.sh --check atomicity
#   ./tools/validate.sh --check links
#   ./tools/validate.sh --check placeholders
#   ./tools/validate.sh --check freshness
#   ./tools/validate.sh --fix              Auto-fix what can be fixed (links index only)
#   ./tools/validate.sh --changed-only     Only check files changed since last commit
#   ./tools/validate.sh --help
#
# Exit codes:
#   0 — all blocking checks passed (warnings may be present)
#   1 — one or more blocking checks failed
#
# Checks and their CI equivalents:
#   frontmatter  → validate-frontmatter.yml    (blocks merge)
#   atomicity    → validate-change-atomicity.yml (blocks merge)
#   links        → validate-links.yml           (blocks merge)
#   placeholders → validate-placeholders.yml    (blocks merge)
#   freshness    → validate-freshness.yml       (warns only)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# ── Colours ──────────────────────────────────────────────────────────────────
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
  CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; CYAN=''; BOLD=''; RESET=''
fi

pass()  { echo -e "${GREEN}  PASS${RESET}  $*"; }
fail()  { echo -e "${RED}  FAIL${RESET}  $*"; }
warn()  { echo -e "${YELLOW}  WARN${RESET}  $*"; }
info()  { echo -e "${CYAN}  INFO${RESET}  $*"; }
header(){ echo -e "\n${BOLD}── $* ──${RESET}"; }

usage() {
  sed -n '/^# Usage:/,/^[^#]/{ /^#/{ s/^# \{0,1\}//; p }; /^[^#]/q }' "$0"
  exit 0
}

# ── Argument parsing ──────────────────────────────────────────────────────────
CHECKS=()
CHANGED_ONLY=0
FIX_MODE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)        usage ;;
    --check)          CHECKS+=("$2"); shift 2 ;;
    --changed-only)   CHANGED_ONLY=1; shift ;;
    --fix)            FIX_MODE=1; shift ;;
    --*)              echo "Unknown option: $1"; usage ;;
    *)                CHECKS+=("$1"); shift ;;
  esac
done

# Default: run all checks
if [[ ${#CHECKS[@]} -eq 0 ]]; then
  CHECKS=(frontmatter atomicity links placeholders freshness)
fi

cd "$REPO_ROOT"

# ── Changed-files helper ──────────────────────────────────────────────────────
get_changed_files() {
  if [[ "$CHANGED_ONLY" -eq 1 ]]; then
    git diff --name-only HEAD 2>/dev/null
    git diff --name-only --cached 2>/dev/null
  else
    echo ""
  fi
}

# ── Run each check ────────────────────────────────────────────────────────────
overall_failed=0
overall_warned=0

run_check() {
  local name="$1"
  local script="$LIB_DIR/check_${name}.sh"

  if [[ ! -f "$script" ]]; then
    warn "No check script found for '$name' at $script"
    return
  fi

  header "$name"

  local extra_args=()
  [[ "$CHANGED_ONLY" -eq 1 ]] && extra_args+=("--changed-only")
  [[ "$FIX_MODE" -eq 1 ]]     && extra_args+=("--fix")

  set +e
  bash "$script" "${extra_args[@]}"
  local exit_code=$?
  set -e

  case "$exit_code" in
    0) : ;;                      # passed
    2) overall_warned=1 ;;       # warned (non-blocking)
    *) overall_failed=1 ;;       # failed (blocking)
  esac
}

for check in "${CHECKS[@]}"; do
  run_check "$check"
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}── Summary ──${RESET}"

if [[ "$overall_failed" -eq 1 ]]; then
  echo -e "${RED}${BOLD}One or more blocking checks failed.${RESET}"
  echo "Fix the issues above before pushing."
  exit 1
elif [[ "$overall_warned" -eq 1 ]]; then
  echo -e "${YELLOW}${BOLD}All blocking checks passed. Warnings present.${RESET}"
  echo "Warnings will not block your PR but should be addressed."
  exit 0
else
  echo -e "${GREEN}${BOLD}All checks passed.${RESET}"
  exit 0
fi