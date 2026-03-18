#!/usr/bin/env bash
# lib/check_atomicity.sh
#
# Checks that all dependency-map couplings are satisfied for staged/changed
# files. Locally this checks git staged + unstaged changes. In CI it checks
# the PR diff against the base branch.
#
# Exit codes: 0 = pass, 1 = fail (blocking), 2 = warn only

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'; RESET='\033[0m'
else
  RED=''; YELLOW=''; GREEN=''; RESET=''
fi

CHANGED_ONLY=0
[[ "${1:-}" == "--changed-only" ]] && CHANGED_ONLY=1

# ── Get changed files ──────────────────────────────────────────────────────────
# In CI: set CHANGED_FILES_PATH to a file containing the diff list.
# Locally: use git status to find staged + unstaged changes.
if [[ -n "${CHANGED_FILES_PATH:-}" && -f "$CHANGED_FILES_PATH" ]]; then
  mapfile -t changed < "$CHANGED_FILES_PATH"
else
  mapfile -t changed < <(
    { git diff --name-only HEAD; git diff --name-only --cached; } 2>/dev/null \
    | sort -u || true
  )
fi

if [[ ${#changed[@]} -eq 0 ]]; then
  echo -e "${GREEN}PASS${RESET}  No changed files to check."
  exit 0
fi

changed_str=$( printf '%s\n' "${changed[@]}" )
failed=0

has_change() { echo "$changed_str" | grep -q "^${1}$"; }
any_match()  { echo "$changed_str" | grep -qE "$1"; }

# ── Check: CHANGELOG updated when content changes ─────────────────────────────
if any_match '^(prompts|skills|guides|examples|tools|templates)/'; then
  if ! has_change "CHANGELOG.md"; then
    echo -e "${RED}FAIL${RESET}  Content files changed but CHANGELOG.md was not updated."
    echo "       Every addition, modification, or removal of content requires a CHANGELOG entry."
    echo "       See templates/structures/changelog-entry-template.md for format."
    failed=1
  fi
fi

# ── Check: prompts/README.md updated when prompt added/removed ────────────────
if any_match '^prompts/[^/]+/[^/]+\.md$' && \
   ! echo "$changed_str" | grep -q '^prompts/README\.md$'; then
  # Only flag if non-README prompt files changed
  prompt_changes=$(echo "$changed_str" | grep -E '^prompts/[^/]+/[^/]+\.md$' \
    | grep -v 'README\.md' || true)
  if [[ -n "$prompt_changes" ]]; then
    echo -e "${RED}FAIL${RESET}  Prompt files changed but prompts/README.md was not updated."
    echo "       Changed prompts:"
    echo "$prompt_changes" | sed 's/^/         /'
    failed=1
  fi
fi

# ── Check: skills/README.md updated when skill added/removed ─────────────────
skill_changes=$(echo "$changed_str" | grep -E '^skills/[^/]+/[^/]+/SKILL\.md$' || true)
if [[ -n "$skill_changes" ]] && ! has_change "skills/README.md"; then
  echo -e "${RED}FAIL${RESET}  Skill SKILL.md files changed but skills/README.md was not updated."
  echo "       Changed skills:"
  echo "$skill_changes" | sed 's/^/         /'
  failed=1
fi

# ── Check: guide subdirectory READMEs updated when guides change ──────────────
for subdir in context workflows models agent-patterns repo-maintenance; do
  guide_changes=$(echo "$changed_str" | \
    grep -E "^guides/${subdir}/[^/]+\.md$" | grep -v 'README\.md' || true)
  if [[ -n "$guide_changes" ]] && \
     ! has_change "guides/${subdir}/README.md"; then
    echo -e "${RED}FAIL${RESET}  Files changed in guides/${subdir}/ but guides/${subdir}/README.md was not updated."
    echo "       Changed files:"
    echo "$guide_changes" | sed 's/^/         /'
    failed=1
  fi
done

# ── Check: examples/README.md updated when examples change ───────────────────
example_changes=$(echo "$changed_str" | grep -E '^examples/[^/]+/' || true)
if [[ -n "$example_changes" ]] && ! has_change "examples/README.md"; then
  echo -e "${RED}FAIL${RESET}  Files changed in examples/ but examples/README.md was not updated."
  echo "       Changed files:"
  echo "$example_changes" | sed 's/^/         /'
  failed=1
fi

# ── Check: medium/high-budget skills have a -minimal sibling ─────────────────
new_skills=$(echo "$changed_str" | grep -E '^skills/[^/]+/[^-][^/]+/SKILL\.md$' \
  | grep -v '\-minimal/SKILL\.md' || true)
for skill_file in $new_skills; do
  [[ ! -f "$skill_file" ]] && continue
  skill_dir=$(dirname "$skill_file")
  skill_name=$(basename "$skill_dir")
  budget=$(awk '/^---$/{fm++; next} fm==1 && /^[ ]*context-budget:/{print $2; exit}' \
    "$skill_file" 2>/dev/null || echo "")
  if [[ "$budget" == "medium" || "$budget" == "high" ]]; then
    minimal_dir="${skill_dir}-minimal"
    if [[ ! -d "$minimal_dir" ]]; then
      echo -e "${RED}FAIL${RESET}  Skill '${skill_name}' has context-budget: ${budget} but ${skill_name}-minimal/ does not exist."
      failed=1
    fi
  fi
done

if [[ "$failed" -eq 0 ]]; then
  echo -e "${GREEN}PASS${RESET}  All dependency-map couplings satisfied."
  exit 0
else
  echo ""
  echo "  See guides/repo-maintenance/dependency-map.md for coupling rules."
  exit 1
fi