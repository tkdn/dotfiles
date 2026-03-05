#!/usr/bin/env bash
# detect_stack.sh
# Detect backend and frontend tech stacks in the current project.
# Supports monorepos by searching recursively (up to 3 levels deep).
#
# Output (stdout, one per line):
#   BACKEND:<technology>
#   FRONTEND:<technology>
#
# Exit 0 always; empty output means nothing was detected.

detect_backend() {
  local dir="$1"
  if [ -f "$dir/Gemfile" ]; then
    echo "BACKEND:Ruby on Rails"
  elif [ -f "$dir/go.mod" ]; then
    echo "BACKEND:Go"
  elif [ -f "$dir/requirements.txt" ] || [ -f "$dir/pyproject.toml" ]; then
    echo "BACKEND:Python"
  elif [ -f "$dir/pom.xml" ] || [ -f "$dir/build.gradle" ]; then
    echo "BACKEND:Java"
  fi
}

detect_frontend() {
  local dir="$1"
  local pkg="$dir/package.json"
  [ -f "$pkg" ] || return

  if grep -q '"@angular/core"' "$pkg"; then
    echo "FRONTEND:Angular"
  elif grep -q '"next"' "$pkg"; then
    echo "FRONTEND:Next.js"
  elif grep -q '"nuxt"' "$pkg"; then
    echo "FRONTEND:Nuxt"
  elif grep -q '"react"' "$pkg"; then
    echo "FRONTEND:React"
  elif grep -q '"vue"' "$pkg"; then
    echo "FRONTEND:Vue"
  else
    echo "FRONTEND:Node.js"
  fi
}

# Search root and up to 3 levels of subdirectories
SEARCH_DIRS=(".")
while IFS= read -r d; do
  SEARCH_DIRS+=("$d")
done < <(find . -mindepth 1 -maxdepth 3 -type d \
  \( -name node_modules -o -name .git -o -name vendor -o -name dist -o -name tmp \) \
  -prune -o -type d -print 2>/dev/null)

declare -A seen_backends
declare -A seen_frontends

for dir in "${SEARCH_DIRS[@]}"; do
  result=$(detect_backend "$dir")
  if [ -n "$result" ] && [ -z "${seen_backends[$result]}" ]; then
    echo "$result"
    seen_backends[$result]=1
  fi

  result=$(detect_frontend "$dir")
  if [ -n "$result" ] && [ -z "${seen_frontends[$result]}" ]; then
    echo "$result"
    seen_frontends[$result]=1
  fi
done
