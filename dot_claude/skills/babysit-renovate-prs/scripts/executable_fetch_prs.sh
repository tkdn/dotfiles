#!/usr/bin/env bash
# Usage: fetch_prs.sh <org>/<team>
# Outputs one JSON object per line (NDJSON), each representing an open Renovate, Dependabot, or release-please PR.
# Fields: repo, author, number, title, url, createdAt, labels, headRefName

set -euo pipefail

if [[ $# -ne 1 || "$1" != */* ]]; then
  echo "Usage: fetch_prs.sh <org>/<team>" >&2
  exit 1
fi

ORG="${1%%/*}"
TEAM="${1##*/}"

repos=$(gh api "/orgs/${ORG}/teams/${TEAM}/repos" --paginate \
  --jq '.[] | select(.role_name == "admin" and .archived == false) | .full_name')

if [[ -z "$repos" ]]; then
  echo "No admin repositories found for team ${1}" >&2
  exit 1
fi

while IFS= read -r repo; do
  # Renovate
  gh pr list --repo "$repo" --author "app/renovate" --state open \
    --json number,title,url,createdAt,labels,headRefName --limit 100 2>/dev/null \
    | jq -c --arg repo "$repo" --arg author "renovate" \
      '.[] | {repo: $repo, author: $author} + .'

  # Dependabot
  gh pr list --repo "$repo" --author "app/dependabot" --state open \
    --json number,title,url,createdAt,labels,headRefName --limit 100 2>/dev/null \
    | jq -c --arg repo "$repo" --arg author "dependabot" \
      '.[] | {repo: $repo, author: $author} + .'

  # release-please (label-based detection to handle custom bot names like app/release-please)
  gh pr list --repo "$repo" --label "autorelease: pending" --state open \
    --json number,title,url,createdAt,labels,headRefName,author --limit 100 2>/dev/null \
    | jq -c --arg repo "$repo" \
      '.[] | select(.author.login | test("release-please"; "i")) | {repo: $repo, author: .author.login} + (del(.author))'
done <<< "$repos"
