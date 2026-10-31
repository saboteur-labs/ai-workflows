#!/usr/bin/env bash
# check-copy.sh — scan user guide Markdown for wording that belongs in a
# verification record or a developer doc rather than in user-facing copy.
#
# Usage:  check-copy.sh <file-or-folder> [<file-or-folder> ...]
# Output: matching lines under FAIL (remove) and REVIEW (judge for this reader).
# Exit:   0 no FAIL lines, 1 at least one FAIL line, 2 usage error.
#
# Front matter and fenced code blocks are skipped. This is a wording check only:
# a clean result says nothing about whether a page is true or clear.

set -u

if [[ $# -eq 0 ]]; then
  echo "usage: check-copy.sh <file-or-folder> [<file-or-folder> ...]" >&2
  exit 2
fi

# Test-report wording, and how the page was checked.
evidence='\b(in|during|from) (a|an|the|one|this|that|our|each|both) ([a-z-]+ )?(tests?|runs?|checks?|trials?|testing)\b'
evidence+='|\bin testing\b|\btest project\b|\b(two|three|four|five|six|[0-9]+) runs\b'
evidence+='|\b(was|were) (not )?(found|observed|measured|tested|checked|verified|tried|run|seen|re-checked|re-run)\b'
evidence+='|\b(not|un) ?(re-?)?(checked|tested|tried|measured|verified|established)\b'
evidence+='|\b(checked|tested|measured|read) (in|from|on|against) (the |a |an )?(code|source|unit|component|storybook|packaged|running|web|desktop|build)'
evidence+='|\bnone recorded\b|\bworking copy\b'

# Build, release and project-management references.
provenance='\bverified against\b|\bbase commit\b|\bmerged after\b|\bnot yet in a release\b|\bunreleased\b'
provenance+='|\b(a later|this|before this|after this) (change|fix)\b'
provenance+='|\b(unit|component|e2e|integration) tests?\b|\bstorybook\b|\bexperiments\.md\b|\bpackage\.json\b'
provenance+='|\b(FR|OQ|US)-[0-9]+\b|\b(Feature|Task|PR|Gate) #?[0-9]+\b'
provenance+='|\.(tsx?|jsx?|py|rs|go)\b'

# Likely jargon and talking-down words. Some are fine in context, which is why
# this only asks for review.
jargon='\b(uuid|json|yaml|api|endpoint|schema|payload|boolean|array|string|config|'
jargon+='backend|frontend|cache|debounce|metadata|canonical|repository|repo|cli|'
jargon+='focus|modal|toggle|render(s|ed)?|parse[sd]?|flag|legacy|non-canonical|'
jargon+='rgb|hex|id|ids|key|keys|utili[sz]e|leverage|purge|simply|just|easy|easily)\b'

# Prints a Markdown file with front matter and code blanked, keeping line numbers.
prose() {
  awk '
    NR == 1 && $0 == "---" { fm = 1; print ""; next }
    fm { if ($0 == "---") fm = 0; print ""; next }
    /^[[:space:]]*(```|~~~)/ { code = !code; print ""; next }
    code { print ""; next }
    { print }
  ' "$1"
}

files=()
for target in "$@"; do
  if [[ -d "$target" ]]; then
    while IFS= read -r found; do files+=("$found"); done \
      < <(find "$target" -type f -name '*.md' | sort)
  elif [[ -f "$target" ]]; then
    files+=("$target")
  else
    echo "not found: $target" >&2
    exit 2
  fi
done

fail_lines=""
review_lines=""
for file in ${files+"${files[@]}"}; do
  numbered="$(prose "$file" | grep -n '.')"
  [[ -z "$numbered" ]] && continue
  fail="$(printf '%s\n' "$numbered" | grep -E -i -e "$evidence" -e "$provenance")"
  review="$(printf '%s\n' "$numbered" | grep -E -i -e "$jargon" | grep -E -i -v -e "$evidence" -e "$provenance")"
  [[ -n "$fail" ]] && fail_lines+="$(printf '%s\n' "$fail" | sed "s|^|$file:|")"$'\n'
  [[ -n "$review" ]] && review_lines+="$(printf '%s\n' "$review" | sed "s|^|$file:|")"$'\n'
done

if [[ -n "$review_lines" ]]; then
  echo "REVIEW: is this term right for this reader?"
  printf '%s\n\n' "$review_lines"
fi

if [[ -n "$fail_lines" ]]; then
  echo "FAIL: move to the verification record or rewrite"
  printf '%s\n' "$fail_lines"
  exit 1
fi

echo "No FAIL lines."
