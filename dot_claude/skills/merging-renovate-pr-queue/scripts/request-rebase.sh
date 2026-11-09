#!/usr/bin/env bash
# Tick Renovate's rebase checkbox in a PR body and print the head SHA before the request.
# Usage: bash request-rebase.sh <owner/repo> <pr-number>
set -euo pipefail

repo="$1"
pr="$2"

body_file="$(mktemp)"
trap 'rm -f "$body_file" "$body_file.bak"' EXIT

gh pr view "$pr" --repo "$repo" --json body --jq .body > "$body_file"

if ! grep -q -- '- \[ \] <!-- rebase-check -->' "$body_file"; then
  if grep -q -- '- \[x\] <!-- rebase-check -->' "$body_file"; then
    echo "already-requested" >&2
  else
    echo "no-rebase-checkbox" >&2
    exit 2
  fi
else
  sed -i.bak 's/- \[ \] <!-- rebase-check -->/- [x] <!-- rebase-check -->/' "$body_file"
  gh pr edit "$pr" --repo "$repo" --body-file "$body_file" > /dev/null
fi

gh pr view "$pr" --repo "$repo" --json headRefOid --jq .headRefOid
