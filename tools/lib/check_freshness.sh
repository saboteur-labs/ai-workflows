#!/usr/bin/env bash
# lib/check_freshness.sh
#
# Checks for files whose review-by date has passed or is within 30 days.
# This is a WARNING-only check — it does not block merges.
#
# Exit codes: 0 = pass (no expired dates), 2 = warn (expired or expiring soon)

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RESET='\033[0m'
else
  YELLOW=''; GREEN=''; RESET=''
fi

CHANGED_ONLY=0
[[ "${1:-}" == "--changed-only" ]] && CHANGED_ONLY=1

# ── Date helpers (cross-platform: macOS and Linux) ────────────────────────────
today=$(date +%Y-%m-%d)

# Add N days to today — handles macOS (BSD date) and Linux (GNU date)
date_plus_days() {
  local n="$1"
  if date -v+1d +%Y-%m-%d &>/dev/null 2>&1; then
    # macOS BSD date
    date -v+"${n}d" +%Y-%m-%d
  else
    # GNU date
    date -d "+${n} days" +%Y-%m-%d
  fi
}

warn_threshold=$(date_plus_days 30 2>/dev/null || echo "")

# ── Build file list ────────────────────────────────────────────────────────────
files=()
if [[ "$CHANGED_ONLY" -eq 1 ]]; then
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && files+=("$_line")
  done < <(
    { git diff --name-only HEAD; git diff --name-only --cached; } 2>/dev/null \
    | grep '\.md$' | sort -u || true
  )
else
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && files+=("$_line")
  done < <(
    find . -name "*.md" \
      -not -path "./.git/*" \
      -not -path "./node_modules/*" \
      -print | sort
  )
fi

expired=()
expiring_soon=()

for file in "${files[@]:-}"; do
  [[ -z "$file" || ! -f "$file" ]] && continue

  review_by=$(grep -m1 "^review-by:" "$file" 2>/dev/null \
    | sed 's/review-by:[ ]*//' | tr -d ' "' || true)
  [[ -z "$review_by" ]] && continue

  # Validate format
  if ! echo "$review_by" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'; then
    echo -e "${YELLOW}WARN${RESET}  Invalid review-by date format in $file: '$review_by'"
    echo "       Expected: YYYY-MM-DD"
    continue
  fi

  if [[ "$review_by" < "$today" ]]; then
    expired+=("$file (expired: $review_by)")
  elif [[ -n "$warn_threshold" && "$review_by" < "$warn_threshold" ]]; then
    expiring_soon+=("$file (expires: $review_by)")
  fi
done

has_warnings=0

if [[ ${#expired[@]} -gt 0 ]]; then
  echo -e "${YELLOW}WARN${RESET}  ${#expired[@]} file(s) have passed their review-by date:"
  for item in "${expired[@]}"; do
    echo "       $item"
  done
  echo ""
  echo "  These files contain time-sensitive content that should be re-verified."
  echo "  Run: ./tools/fetch-prompt.sh --skill freshness-check"
  echo "  Then update the content and reset the review-by date."
  has_warnings=1
fi

if [[ ${#expiring_soon[@]} -gt 0 ]]; then
  echo -e "${YELLOW}WARN${RESET}  ${#expiring_soon[@]} file(s) expire within 30 days:"
  for item in "${expiring_soon[@]}"; do
    echo "       $item"
  done
  has_warnings=1
fi

if [[ "$has_warnings" -eq 0 ]]; then
  echo -e "${GREEN}PASS${RESET}  No expired or soon-expiring review-by dates."
  exit 0
else
  echo ""
  echo "  This is a warning only — it will not block your PR."
  # Exit code 2 = warning (non-blocking)
  exit 2
fi