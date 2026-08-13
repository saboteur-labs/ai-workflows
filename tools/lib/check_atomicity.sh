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
  changed=()
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && changed+=("$_line")
  done < "$CHANGED_FILES_PATH"
else
  changed=()
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && changed+=("$_line")
  done < <(
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

# ── Which skills maintain this repo rather than ship to consumers? ────────────
#
# A skill declaring `audience: repo` under `metadata:` logs to
# CHANGELOG-repo-tools.md; everything else logs to CHANGELOG.md. Routing on a
# declared field rather than on the path, because the two do not correlate:
# improve-agent sits at the same depth as the repo tools but tunes the user's
# own agents.
#
# Read from the working tree, so a deleted skill directory is no longer
# discoverable and its files fall through to CHANGELOG.md. That is the safe
# direction — a removal is worth announcing to consumers either way.
repo_skill_dirs=()
while IFS= read -r skill_file; do
  [[ -z "$skill_file" ]] && continue
  if awk '/^---$/{n++; next} n==1 && /^[[:space:]]*audience:[[:space:]]*repo[[:space:]]*$/{found=1} n>=2{exit} END{exit !found}' "$skill_file"; then
    repo_skill_dirs+=("$(dirname "$skill_file")")
  fi
done < <(find skills -name "SKILL.md" 2>/dev/null | sort)

is_repo_internal() {                      # $1 = changed path
  local d
  for d in ${repo_skill_dirs+"${repo_skill_dirs[@]}"}; do
    [[ "$1" == "$d/"* ]] && return 0
  done
  return 1
}

repo_internal_changes=""
consumer_changes=""
index_only_changes=""
while IFS= read -r cf; do
  [[ -z "$cf" ]] && continue
  if is_repo_internal "$cf"; then
    repo_internal_changes+="${cf}"$'\n'
  elif [[ "$cf" == "skills/README.md" ]]; then
    # The index is held separately. A repo-tools change is *required* to update
    # it, and counting that update as consumer content would demand a
    # CHANGELOG.md entry too — a deadlock where no combination of files
    # satisfies both checks. It still counts as consumer content on its own.
    index_only_changes+="${cf}"$'\n'
  elif [[ "$cf" =~ ^(prompts|skills|guides|examples|tools|templates)/ ]]; then
    consumer_changes+="${cf}"$'\n'
  fi
done <<< "$changed_str"

# An index touched with no repo-internal change behind it is an ordinary
# content change and owes the user-facing changelog like any other.
if [[ -n "$index_only_changes" && -z "$repo_internal_changes" ]]; then
  consumer_changes+="$index_only_changes"
fi

# ── Check: CHANGELOG updated when content changes ─────────────────────────────
if [[ -n "$consumer_changes" ]] && ! has_change "CHANGELOG.md"; then
  echo -e "${RED}FAIL${RESET}  Content files changed but CHANGELOG.md was not updated."
  echo "       Every addition, modification, or removal of content requires a CHANGELOG entry."
  echo "       See templates/structures/changelog-entry-template.md for format."
  echo "       Changed files:"
  echo "$consumer_changes" | grep -v '^$' | sed 's/^/         /'
  failed=1
fi

# ── Check: repo-tools changelog updated when a repo-audience skill changes ────
if [[ -n "$repo_internal_changes" ]] && ! has_change "CHANGELOG-repo-tools.md"; then
  echo -e "${RED}FAIL${RESET}  A skill with 'audience: repo' changed but CHANGELOG-repo-tools.md was not updated."
  echo "       Skills that maintain this repo log there, not in CHANGELOG.md."
  echo "       Changed files:"
  echo "$repo_internal_changes" | grep -v '^$' | sed 's/^/         /'
  failed=1
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
#
# Any depth. The old pattern required a category directory, so the five skills
# that sit directly under skills/ were enforced by nothing — including the four
# repo tools and improve-agent. Both audiences are indexed in skills/README.md,
# so both owe it an update.
skill_changes=$(echo "$changed_str" | grep -E '^skills/.*/SKILL\.md$' || true)
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