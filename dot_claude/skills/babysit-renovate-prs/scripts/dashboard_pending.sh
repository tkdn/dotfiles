#!/usr/bin/env bash
# Usage: dashboard_pending.sh <org>/<team>
# Counts pending updates (Awaiting Schedule + Rate-Limited) on the Renovate Dependency Dashboard
# of every admin, non-archived repository of the team.
# Outputs TSV, one line per repo with pending updates, sorted by packages descending:
#   <owner/repo> <TAB> <packages> <TAB> <items>
# items    = unchecked update lines (unlimit-branch / unschedule-branch); the
#            "Create all rate-limited PRs at once" checkbox is not an update and is not counted.
# packages = distinct update targets among those items. Each major version of the same package
#            is a separate item but one package; a Renovate group (e.g. "eslint monorepo") is one package.
# A repo whose dashboard could not be fetched (rate limit, permission, network) is printed after the
# counted repos as:
#   <owner/repo> <TAB> ERROR <TAB> <first line of the error>
# A repo with no dashboard or no pending updates is not printed.

set -euo pipefail

count_repo() {
  local repo="$1" json body err
  err=$(mktemp)
  if ! json=$(gh issue list --repo "$repo" --search "Dependency Dashboard in:title" --json body --limit 1 2>"$err") \
    || ! body=$(printf '%s' "$json" | jq -r '.[0].body // ""' 2>>"$err"); then
    printf '%s\tERROR\t%s\n' "$repo" "$(head -n 1 "$err")"
    rm -f "$err"
    return 0
  fi
  rm -f "$err"
  [[ -z "$body" ]] && return 0
  printf '%s\n' "$body" | awk -v repo="$repo" '
    /^## Awaiting Schedule/ || /^## Rate-Limited/ { s = 1; next }
    /^## / { s = 0; next }
    s && /^ *- \[ \] <!-- (unlimit|unschedule)-branch=/ {
      t = $0
      sub(/.*-->/, "", t)
      sub(/^[a-z]+(\([^)]*\))?!?: */, "", t)        # conventional-commit prefix, e.g. "chore(deps): "
      sub(/^(update|pin|replace|bump) +/, "", t)
      sub(/^(dependency|module|package) +/, "", t)
      sub(/ +\(`.*$/, "", t)                         # package list of a group
      sub(/ +to +.*$/, "", t)                        # target version
      sub(/ +(action|docker tag|digest)$/, "", t)
      items++
      if (!(t in seen)) { seen[t] = 1; packages++ }
    }
    END { if (items) printf "%s\t%d\t%d\n", repo, packages, items }'
}

if [[ "${1:-}" == "--repo" ]]; then
  count_repo "$2"
  exit 0
fi

if [[ $# -ne 1 || "$1" != */* ]]; then
  echo "Usage: dashboard_pending.sh <org>/<team>" >&2
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

results=$(printf '%s\n' "$repos" | xargs -P 8 -n 1 bash "$0" --repo)
printf '%s\n' "$results" | awk -F '\t' 'NF && $2 != "ERROR"' | sort -t $'\t' -k2,2nr -k3,3nr
printf '%s\n' "$results" | awk -F '\t' '$2 == "ERROR"' | sort
