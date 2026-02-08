# 現在のプロジェクトにおける Pull Request レビュー

現在のプロジェクトにおける今のブランチから Pull Request を読み込み、main との差分を比較しいくつかの観点でレビューします。

## 技術スタック判定

まず、プロジェクトの技術スタックを判定します:

```bash
# 技術スタックの判定
BACKEND_STACK=""
FRONTEND_STACK=""

# バックエンド技術の判定
if [ -f "Gemfile" ]; then
  BACKEND_STACK="Ruby on Rails"
elif [ -f "go.mod" ]; then
  BACKEND_STACK="Go"
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  BACKEND_STACK="Python"
elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
  BACKEND_STACK="Java"
fi

# フロントエンド技術の判定
if [ -f "package.json" ]; then
  if grep -q "\"react\"" package.json; then
    FRONTEND_STACK="React"
  elif grep -q "\"vue\"" package.json; then
    FRONTEND_STACK="Vue"
  elif grep -q "\"@angular/core\"" package.json; then
    FRONTEND_STACK="Angular"
  elif grep -q "\"next\"" package.json; then
    FRONTEND_STACK="Next.js"
  elif grep -q "\"nuxt\"" package.json; then
    FRONTEND_STACK="Nuxt"
  else
    FRONTEND_STACK="Node.js"
  fi
fi

# 判定結果を表示
echo "検出された技術スタック:"
[ -n "$BACKEND_STACK" ] && echo "- バックエンド: $BACKEND_STACK"
[ -n "$FRONTEND_STACK" ] && echo "- フロントエンド: $FRONTEND_STACK"

# 技術スタックが検出されなかった場合
if [ -z "$BACKEND_STACK" ] && [ -z "$FRONTEND_STACK" ]; then
  echo "- 技術スタックを判定できませんでした。汎用的な観点でレビューします。"
fi

# 複数の技術スタックが検出された場合、ユーザーに確認
REVIEW_SCOPE="both"
if [ -n "$BACKEND_STACK" ] && [ -n "$FRONTEND_STACK" ]; then
  echo ""
  echo "このプロジェクトは複数の技術スタックを使用しています。"
  echo "どの観点でレビューしますか？"
  echo "(1) 両方の観点でレビュー"
  echo "(2) バックエンド観点のみ"
  echo "(3) フロントエンド観点のみ"
  read -p "選択 (1-3): " REVIEW_CHOICE

  case $REVIEW_CHOICE in
    2) REVIEW_SCOPE="backend" ;;
    3) REVIEW_SCOPE="frontend" ;;
    *) REVIEW_SCOPE="both" ;;
  esac
fi
```

## Pull Request 確認

Pull Request description は以下の実行で読み込みます:

```bash
gh pr view
```

## レビュー観点

レビューにおける観点のレベルは、Critical, Warning, Info の3種あります。観点に準じてレベルを決定してください。

### 共通観点（すべてのプロジェクト）

#### 1. コード品質 (Info/Warning)
- **単一責任の原則**: クラス・メソッドが1つの責務に集中しているか
- **重複コード**: DRY原則を遵守しているか
- **YAGNI**: 過剰な設計で不要な共通化や早期の最適化に踏み込んでいないか
- **防御的設計**: 必要以上にインターフェースを広くしていないか、利用者が誤用しない設計になっているか

#### 2. プロジェクトとの調和 (Warning)
- **規約**: プロジェクトに規約を含むドキュメントがある場合は規約に準拠しているか
- **調和**: プロジェクトの既存の設計やコードと調和し協調できるか
- **逸脱**: プロジェクトの既存の構造から逸脱していないか、同僚に認知負荷をかけないか

#### 3. エラーハンドリング (Warning)
- **例外処理**: 捕捉されない例外はないか、エラーハンドリング漏れがないか
- **バリデーション**: 保存処理において適切なルール設定がされているか

#### 4. テスト (Info)
- **テストの有無**: 新機能・バグ修正に対応するテストは過不足なく追加されているか
- **テストカバレッジ**: 重要なパスがカバーされているか、必要以上にテストケースを追加していないか
- **テストの品質**: テストの検証項目が大味すぎないか、テストケースに準じて過不足ない検証項目か

#### 5. セキュリティ全般 (Critical/Warning)
- **機密情報の露出**: パスワード、APIキー、トークンのハードコーディングがされていないか
- **ログ出力**: 本番環境で機密情報がログに出力されないか
- **環境変数**: ハードコードされた環境依存設定がないか
- **依存関係の脆弱性**: セキュリティアラートのある依存パッケージを使用していないか

#### 6. その他 (Info/Warning)
- **後方互換性**: 既存APIの破壊的変更がないか

### バックエンド特有の観点

このセクションは `REVIEW_SCOPE` が "backend" または "both" の場合に適用されます。

#### 1. セキュリティ (Critical)
- **SQLインジェクション**: ユーザー入力がそのままSQLに渡されていないか
- **認証・認可**: 未認可のアクションが実行されていないか

#### 2. パフォーマンス (Warning)
- **N+1クエリ**: Eager Loading の欠如やN+1の発生のおそれがある箇所がないか
- **不要なクエリ**: ループ内でのDBアクセスがないか
- **インデックス**: 検索条件に使用されるカラムのインデックスが考慮されているか
- **キャッシュ**: 頻繁にアクセスされるデータがあればオンメモリへのキャッシュなどを考慮しているか

#### 3. API設計 (Info/Warning)
- **RESTful設計**: REST原則に準拠しているか
- **エンドポイント命名**: 一貫性のある命名規則が使われているか

### フロントエンド特有の観点

このセクションは `REVIEW_SCOPE` が "frontend" または "both" の場合に適用されます。

#### 1. セキュリティ (Critical)
- **XSS**: エスケープされていないユーザー入出力がないか
  - React: `dangerouslySetInnerHTML` の不適切な使用
  - Angular: `DomSanitizer` を使わない `innerHTML` の使用
  - Vue: `v-html` の不適切な使用

#### 2. パフォーマンス (Warning)
- **再レンダリング最適化**: 不要な再レンダリングが発生していないか
  - React: `useMemo`, `useCallback`, `React.memo` の適切な使用
  - Angular: `OnPush` Change Detection戦略の活用
  - Vue: `computed` プロパティの適切な使用
- **バンドルサイズ**: 遅延ロード（lazy loading）やtree-shakingが考慮されているか
- **大規模リスト**: 仮想スクロールの検討が必要な大量データの表示がないか

#### 3. メモリ管理 (Warning)
- **リソース解放**: イベントリスナーやSubscriptionの解放漏れがないか
  - React: `useEffect` のクリーンアップ関数
  - Angular: `ngOnDestroy` でのSubscription解除
  - Vue: `onUnmounted` でのクリーンアップ

#### 4. アクセシビリティ (Info)
- **ARIA属性**: 適切なARIA属性が設定されているか
- **キーボード操作**: キーボードのみでの操作が可能か

## 出力

PR番号を取得してファイル名を決定し、プロジェクトのリポジトリルートに出力してください:

```bash
# PR番号の取得
PR_NUMBER=$(gh pr view --json number -q .number)

# PR番号が取得できない場合はタイムスタンプを使用
if [ -z "$PR_NUMBER" ]; then
  PR_NUMBER=$(date +%Y%m%d-%H%M%S)
fi

OUTPUT_FILE="pr-review-${PR_NUMBER}.md"
```

### 出力ルール

- **Critical**: すべて表示（無制限）
- **Warning**: 優先度の高いものから10件まで表示
- **Info**: 優先度の高いものから5件まで表示
- 冗長な言い回しをせず端的に解説を記載してください
- コード例は検出された技術スタックに応じた言語で記載してください

### 出力フォーマット

以下は出力フォーマットの例です:

```markdown
# レビューサマリー

- Critical: n件（全件表示）
- Warning: n件（最大10件まで表示）
- Info: n件（最大5件まで表示）

# レビュー項目

## [Critical]: WHERE句にクエリパラメータが直接渡されている

- **場所**: app/controllers/users_controller.rb:12
- **説明**: 以下のようにユーザー入力がそのまま渡されているためSQLインジェクションのリスクを孕んでいます

```ruby
# 該当箇所
user = User.where("name = '#{params[:name]}'")
```

```ruby
# 修正提案
user = User.where(name: params[:name])
```

## [Warning]: Subscriptionの解放漏れ

- **場所**: src/app/components/user-list/user-list.component.ts:25
- **説明**: ngOnDestroyでSubscriptionを解放していないため、メモリリークの可能性があります

```typescript
// 該当箇所
ngOnInit() {
  this.userService.getUsers().subscribe(users => {
    this.users = users;
  });
}
```

```typescript
// 修正提案
private subscription: Subscription;

ngOnInit() {
  this.subscription = this.userService.getUsers().subscribe(users => {
    this.users = users;
  });
}

ngOnDestroy() {
  this.subscription?.unsubscribe();
}
```

## [Info]: テストケースが不足している

- **場所**: src/app/services/auth.service.spec.ts
- **説明**: ログイン失敗時のエラーハンドリングに対するテストケースがありません

```typescript
// 追加すべきテストケース
it('should handle login error', () => {
  // エラー時の動作を検証するテスト
});
```
```
