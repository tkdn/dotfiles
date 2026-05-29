#!/usr/bin/env bash
set -euo pipefail

# org/repo を git remote から動的取得
repo=$(git remote get-url origin 2>/dev/null \
  | sed -E 's|.*github\.com[:/]||; s|\.git$||')

if [ -z "$repo" ]; then
  echo "Error: GitHub リポジトリを特定できませんでした" >&2
  exit 1
fi

echo "リポジトリ: $repo" >&2

# パッケージマネージャーを検出
detect_pm() {
  if [ -f "go.mod" ]; then
    echo "go"
  elif [ -f "package.json" ]; then
    if [ -f "pnpm-lock.yaml" ]; then
      echo "pnpm"
    elif [ -f "yarn.lock" ]; then
      echo "yarn"
    else
      echo "npm"
    fi
  else
    echo "unknown"
  fi
}

PM=$(detect_pm)
echo "パッケージマネージャー: $PM" >&2

# パッケージの親依存を取得する関数
get_parents() {
  local name="$1"
  local parents=""

  case "$PM" in
    pnpm)
      parents=$(pnpm why "$name" 2>/dev/null \
        | grep -E '^(dependencies|devDependencies|optionalDependencies):' -A1 \
        | grep -oE '^[a-zA-Z@][^ ]+' \
        | grep -v -E '^(dependencies|devDependencies|optionalDependencies):$' \
        | sort -u \
        | tr '\n' ', ' \
        | sed 's/, $//')
      ;;
    npm)
      parents=$(npm explain "$name" 2>/dev/null \
        | grep -E '^node_modules/[^/]+$' \
        | sed 's|^node_modules/||' \
        | grep -v "^${name}$" \
        | sort -u \
        | tr '\n' ', ' \
        | sed 's/, $//')
      ;;
    yarn)
      parents=$(yarn why "$name" 2>/dev/null \
        | grep -E '"[^"]+" depends on' \
        | grep -oE '"[^"]+"' | head -1 \
        | tr -d '"' \
        | sort -u \
        | tr '\n' ', ' \
        | sed 's/, $//')
      ;;
    go)
      parents=$(go mod why -m "$name" 2>/dev/null \
        | grep -v '^#' \
        | grep -v '^$' \
        | head -1)
      ;;
    *)
      parents=""
      ;;
  esac

  echo "$parents"
}

# Dependabot open alerts を取得してユニークなパッケージ一覧を生成
echo "Dependabot アラートを取得中..." >&2
packages=$(gh api "repos/${repo}/dependabot/alerts" --paginate \
  --jq '.[] | select(.state=="open") | {name: .dependency.package.name, ecosystem: .dependency.package.ecosystem, relationship: .dependency.relationship}' \
  | jq -sc 'unique_by(.name)[]')

if [ -z "$packages" ]; then
  echo "オープンなアラートはありません"
  exit 0
fi

# PM が unknown の場合は親パッケージ列なし
if [ "$PM" = "unknown" ]; then
  output="| package.name | package.ecosystem | relationship |
|---|---|---|"

  while IFS= read -r pkg; do
    name=$(echo "$pkg" | jq -r '.name')
    ecosystem=$(echo "$pkg" | jq -r '.ecosystem')
    relationship=$(echo "$pkg" | jq -r '.relationship')
    output="$output
| $name | $ecosystem | $relationship |"
  done < <(echo "$packages")
else
  output="| package.name | package.ecosystem | relationship | 推移的依存の場合の親パッケージ |
|---|---|---|---|"

  while IFS= read -r pkg; do
    name=$(echo "$pkg" | jq -r '.name')
    ecosystem=$(echo "$pkg" | jq -r '.ecosystem')
    relationship=$(echo "$pkg" | jq -r '.relationship')

    if [ "$relationship" = "transitive" ]; then
      parents=$(get_parents "$name")
      [ -z "$parents" ] && parents="-"
    else
      parents="-"
    fi

    output="$output
| $name | $ecosystem | $relationship | $parents |"
  done < <(echo "$packages")
fi

echo "$output"
echo ""
echo "$output" | pbcopy
echo "(クリップボードにコピーしました)"
