---
name: deps-check
description: GitHubリポジトリのDependabotアラートを取得し、各脆弱パッケージが直接依存か推移的依存かを判定し、推移的依存の場合は親パッケージを特定してマークダウンテーブルにまとめクリップボードにコピーする。対応パッケージマネージャーはnpm/pnpm/yarn/go。ユーザーが「Dependabotのアラートを確認したい」「脆弱性の一覧をまとめたい」「依存関係の脆弱性を整理したい」「deps-check」などと言ったときに使用する。
---

## 概要

`scripts/deps-check.sh` を実行してマークダウンテーブルを生成し、クリップボードにコピーする。

## 実行手順

1. カレントディレクトリがGitリポジトリであることを確認する
2. 以下のコマンドを実行する：

```bash
bash "$(dirname "$0")/../skills/deps-check/scripts/deps-check.sh"
```

スキルのパスが不明な場合は以下で確認できる：

```bash
find ~/.claude/skills/deps-check -name deps-check.sh
```

## スクリプトの動作

- `git remote get-url origin` から `org/repo` を自動取得
- ロックファイルの存在でパッケージマネージャーを自動判定：
  - `pnpm-lock.yaml` → pnpm
  - `yarn.lock` → yarn
  - `package.json`（上記なし）→ npm
  - `go.mod` → go
  - いずれもなし → unknown（親パッケージ列を省略）
- GitHub API で open 状態のDependabotアラートを全件取得
- 各パッケージについて `pnpm why` / `npm explain` / `yarn why` / `go mod why` で直接依存の親パッケージを特定
- マークダウンテーブルを標準出力 + `pbcopy` でクリップボードへ

## 出力形式

**npm/pnpm/yarn/go の場合（親パッケージあり）:**

| package.name | package.ecosystem | relationship | 推移的依存の場合の親パッケージ |
|---|---|---|---|
| ws | npm | transitive | @angular/build, @apollo/client |
| lodash | npm | direct | - |

**unknown（gem等）の場合（親パッケージなし）:**

| package.name | package.ecosystem | relationship |
|---|---|---|
| rack | rubygems | transitive |

## 前提条件

- `gh` CLI がインストール済みで認証済みであること
- `jq` がインストール済みであること
- macOS（クリップボードに `pbcopy` を使用）
