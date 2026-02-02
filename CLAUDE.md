# Project: zenn-claude-code-guide

Zenn向けのClaude Code関連技術記事を管理するプロジェクト。
非エンジニア向けの技術ガイドを作成・公開する。

## Project Structure

```
articles/           # Zenn記事（Markdown）
.claude/
├── agents/         # サブエージェント定義
├── protocols/      # ワークフロー定義
└── skills/         # スキル定義
```

## Protocols

### RMOS Deep Research Protocol

調査・検証・記事化の一気通貫ワークフロー。
テーマから最適なOSSを選定し、検証から記事執筆まで自律実行する。

**詳細**: `.claude/protocols/rmos-orchestration.md`

**起動方法**:
```
RMOSプロトコルを実行してください。

テーマ: {調査したい内容}
環境: {Windows / WSL2 / macOS}
投稿先: {Zenn / Qiita}
```

**簡略形**:
```
RMOS: 「{テーマ}」 / {環境} / {投稿先}
```

**例**:
```
RMOS: 「MCPでファイルシステムを操作するツール」 / Windows / Zenn
```

## Agents

| エージェント | 役割 | 使用タイミング |
|-------------|------|---------------|
| `rmos-researcher` | OSS調査・検証 | RMOSプロトコル Phase 1-2 |
| `zenn-writer` | 記事作成 | 記事ドラフト作成時 |
| `zenn-reviewer` | 品質レビュー | 記事完成後のチェック |

## Skills

| スキル | 役割 |
|--------|------|
| `zenn-quality` | 記事品質基準とチェックリスト |
| `buzz-post` | Xバズポスト作成・「さらに表示」位置最適化 |
| `fact-check` | 調査結果を公式ドキュメント・公式ベストプラクティスと照合 |
| `new-series-workflow` | 新シリーズ作成時のDeep Research + メタ認知レビューワークフロー |
| `mcp-setup` | MCP サーバー設定コマンド集（登録済みサーバーの情報含む） |
| `mermaid-diagram` | Mermaid図表作成（フローチャート、シーケンス図、アーキテクチャ図） |

## Reference Sources

公式ドキュメント・ベストプラクティスの参照先：

| ツール | URL |
|--------|-----|
| Claude Code Best Practices | https://code.claude.com/docs/en/best-practices |
| Anthropic Engineering Blog | https://www.anthropic.com/engineering/claude-code-best-practices |
| Google Antigravity Docs | https://antigravity.google/docs |

## Article Guidelines

このプロジェクトの記事は非エンジニア向け。以下を遵守：

- 選択肢は1つに絞る（複数並べない）
- プロンプト例は自然な日本語（ファイルパス不要）
- 具体例は初心者向け（タイマー、電卓など）
- 暗黙の前提を説明する
- コマンドや記号（irm, iex, ~, PATH）には説明を追加

## Title Conventions

記事タイトルの統一ルール：

| ルール | 理由 |
|--------|------|
| 「【非エンジニア×AI開発】」プレフィックスは使わない | 冗長。Zenn一覧で切れる |
| 「非エンジニア向け」は使わない | 記事内容で示す |
| 「Antigravity」→「Google Antigravity」 | 正式名称で統一 |
| 「（Windows 10/11）」→「（Windows）」 | 冗長。現行Windowsは基本10/11 |
| 「WSL2」→「Linux（Ubuntu）」 | 非エンジニアに伝わりやすい |

**タイトルパターン**：
- Claude Code: `Claude Code [カテゴリ]：[ベネフィット]`
- Google Antigravity: `Google Antigravity [スキル名]スキル：[ベネフィット]`
- 実践Tips: `Claude Code 実践Tips [#]：[テーマ]`

## Series Structure

| シリーズ | ターゲット | 概要 |
|---------|-----------|------|
| Claude Code シリーズ | 非エンジニア・初心者 | インストール、基本操作、トラブルシューティング |
| Claude Code 実践Tips | 中級者 | 公式ベストプラクティス解説 |
| Google Antigravity シリーズ | 非エンジニア | Skills、Workflows、セキュリティ |

**棲み分け**：
- 既存シリーズ：機能の紹介（How）
- 実践Tips：ベストプラクティスの理解（Why & When）

新シリーズ作成時は、既存記事との重複を確認し、観点の違いで棲み分ける。

## Zenn Specifics

### Frontmatter（必須）
```yaml
---
title: "記事タイトル"
emoji: "🤖"
type: "tech"
topics: ["claudecode", "ai", "windows"]
published: false
---
```

### 人気topics
`claudecode`, `ai`, `生成ai`, `llm`, `windows`, `個人開発`

### 記法
- 見出し前に空行を入れる
- `:::message` は補足情報
- `:::message alert` は警告

## Commands

```bash
# プレビュー
npx zenn preview

# 新規記事作成
npx zenn new:article
```

## X（Twitter）運用の知見

### 文字数カウント（重要）

X のすべての文字数制限は **UTF-16 code units** で計測される。

| 制限 | 上限 |
|------|------|
| ポスト（ツイート） | 280 UTF-16 units |
| プロフィール欄 | 160 UTF-16 units |

```javascript
// ✅ 正しい（UTF-16 = X と一致）
text.length

// ❌ 間違い（Unicode code points = 絵文字で1ずれる）
[...text].length
```

絵文字（👉😀🔧等）は UTF-16 で **2 units** 消費する。`[...text].length` では 1 としてカウントされるため、絵文字1個につき1文字ずれる。

### 「さらに表示」の発生条件

| 条件 | 対象 |
|------|------|
| weighted length > 280 | 全端末（**Premium必須**。無料アカウントは280が投稿上限のため不可能） |
| 11行以上（weighted ≤ 280） | PCブラウザのみ |

weighted length の計算: 全角文字 = 2、半角英数・改行・スペース = 1、URL = 23固定。
半角英単語（Claude, Code, AI, Zenn等）が多いと、見た目より weighted が大幅に小さくなる。

### 外部リンクのインプレッション影響

外部リンク付きポストはリーチが **最大94%低下** する（Buffer社 1,880万投稿分析、Jesse Colombo氏 A/Bテスト）。

**対策**: URL はリプ欄に貼る（イーロン・マスク本人も推奨）。メイン投稿はテキストのみにする。

### コピペ時の改行混入

コードブロック（```）からコピーすると末尾に改行が付加され、文字数制限を超える場合がある。
プロフィール等の文字数ぴったりのテキストは **テキストファイルに改行なしで書き出し**、そこからコピーする。

```javascript
// 改行なしでファイル書き出し
fs.writeFileSync('output.txt', text, {encoding: 'utf8'});
```

## 参考ライター

| ライター | プラットフォーム | 特徴 |
|---------|----------------|------|
| ユニコ氏 | note.com | 対話形式の導入、結論先出し、比較表多用、「使うべき人/使わなくていい人」の明確化 |

技術ガイドを書く際は、このスタイルを参考にする。

## Obsidian 記事作成の知見

### iCloud同期のフォルダ構造（重要）

| フォルダ | 作成元 | iOS認識 |
|---------|--------|---------|
| `iCloud~md~obsidian` | iOSアプリが自動作成 | ✅ |
| 手動作成の「Obsidian」 | Windows | ❌ |

**必ずiPhoneでVaultを先に作成すること。** WindowsでVaultを先に作成すると「your iCloud vault was not detected」エラーが発生する。

iPhoneで作成したVaultのパス：
```
C:\Users\[ユーザー名]\iCloudDrive\iCloud~md~obsidian\[Vault名]
```

### iCloud同期の追加知見（2026-01-30）

| 挙動 | 詳細 |
|------|------|
| 同期タイミング | リアルタイムではない |
| Windows → iPhone | iPhoneのObsidian再起動またはプルリフレッシュで取得 |
| iPhone → Windows | 数秒〜数分で自動同期 |

**MCP接続確認:**
```
Obsidianのメモ一覧を取得して
```

**本文検索:**
```
本文も含めて探して
```
デフォルトはファイル名のみ検索。本文検索は明示的に指示が必要。

### Windows + iCloud Drive の注意点

| 問題 | 解決策 |
|------|--------|
| iCloud Driveのパスがエクスプローラーで見つからない | 左サイドバーの「iCloud Drive」をクリック。パス文字列はコピーできない |
| mcp-server.exe のパスを確認したい | `Get-ChildItem -Path "$env:USERPROFILE\iCloudDrive\iCloud~md~obsidian" -Recurse -Filter "mcp-server.exe"` |
| `.claude.json` が見つからない | PowerShellから: `notepad "$env:USERPROFILE\.claude.json"` |

### Obsidian UI の注意点

| 記事での表記 | 実際のUI |
|-------------|----------|
| 「制限モードをオフにする」 | 「コミュニティプラグインを有効化」ボタン |
| 「Obsidianを再起動」 | 「Relaunch」ボタンをクリック |
| 「Language設定」 | General → Language |
| 「Vault切り替え」 | 左下のVault名をクリック → Manage vaults |

## Claude Code MCP設定の知識

### 正しい設定方法

| 方法 | コマンド |
|------|---------|
| 登録 | `claude mcp add <name> <command> -e KEY=value --scope user` |
| 一覧 | `claude mcp list` |
| 削除 | `claude mcp remove <name>` |

詳細なコマンド例: `.claude/skills/mcp-setup.md`

### 設定ファイルの場所

| ファイル | 用途 |
|---------|------|
| `~/.claude.json` | ✅ 正式な設定保存先（コマンドが自動で設定） |
| `~/.claude/mcp_servers.json` | ❌ **読み込まれない**（非公式） |
| `.mcp.json`（プロジェクトルート） | チーム共有用 |

### 重要な挙動

- **設定反映は起動時のみ**: セッション中に `claude mcp add` しても `/mcp` には反映されない → 再起動必要
- **`claude mcp list` と `/mcp` の違い**: `list` は CLI 実行時に設定を読む。`/mcp` は現在のセッション状態を表示

### スコープの違い

| スコープ | オプション | 用途 |
|---------|-----------|------|
| User | `--scope user` | 全プロジェクト共通（推奨） |
| Local | 省略 or `--scope local` | 現在のプロジェクトのみ |
| Project | `.mcp.json` 作成 | チーム共有 |

## Deep Research プロトコル

表面的な対処ではなく根本原因を調査するときに使用：

1. **rmos-researcher エージェント**で公式ドキュメント + GitHub issues を調査
2. **メタ認知レビュー3回**で情報を検証
3. 誤情報を発見したら CLAUDE.md と引き継ぎ資料を修正

## 記事作成ワークフロー

### セキュリティレビュー

記事完成後、**code-auditor エージェント**でセキュリティレビューを実施する：

```
このZenn記事のセキュリティレビューを行ってください。
ファイル: articles/[記事ファイル名].md
```

レビュー観点：
- API Key、認証情報の取り扱い
- プライバシーリスクの説明
- プラグインのセキュリティリスク

※ `/security-review` は公式コマンドではない（カスタムスキルとして定義が必要）

### 非エンジニア向け活用法の書き方

抽象的な説明ではなく、以下の構成で書く：

1. **読者の悩み**（引用形式で生々しく）
2. **解決策**（具体的な手順）
3. **プロンプト例**（コードブロックで）

### 導入部の書き方パターン

読者の「あるある」から始め、共感→解決の流れを作る：

1. **共感**（あるある）: 「〜していて、こんな経験ありませんか？」
2. **痛み**（具体的な問題）: 「〜が面倒で続かない」
3. **挫折**（試したけどダメ）: 「そう思って試したこともあります。でも…」
4. **解決**（本題への導入）: 「そんな僕が今、〜と即答します」
5. **メリット**（ベネフィット）: 「この一言で、AIが勝手に〜」

**対象読者に刺さる例を使う:**
- X/Zenn/Qiita読者 → AIツール情報整理、技術記事の専門用語翻訳
- 非エンジニア → 会議メモ整理、アイデアの深掘り

## コマンドのベストプラクティス

### 長いコマンドは変数で分割

コピペ時の改行混入を防ぐため、PowerShellでは変数を使って分割する：

```powershell
# NG: 長すぎてコピペ時に改行が混入する
claude mcp add obsidian "長いパス" -e OBSIDIAN_API_KEY=長いキー --scope user

# OK: 変数で分割
$path = "長いパス"
$apikey = "長いキー"
claude mcp add obsidian $path -e OBSIDIAN_API_KEY=$apikey --scope user
```

## エラーと解決策

### MCP関連

| 症状 | 原因 | 解決策 |
|------|------|--------|
| `/mcp` で「No MCP servers configured」 | 設定後に再起動していない | Claude Code を終了→再起動 |
| `claude mcp list` で Connected なのに `/mcp` で認識されない | セッション中の設定変更 | 再起動必要 |
| MCP設定が消える | `~/.claude/mcp_servers.json` に書いた | `claude mcp add` コマンドを使用 |

### SVG → PNG 変換（Windows）

Windows の `convert.exe` はディスク変換ツールであり ImageMagick ではない。

```bash
# ✅ 正しい方法
npx sharp-cli -i input.svg -o output.png -f png --density 144
```

`--density 144` で 2x 解像度になる。

### Python が使えない場合

Windows 環境で `python3` コマンドが見つからない場合は `node -e` で代替する。
文字数カウント等の簡易スクリプトは Node.js で実行可能。

## 並列セッション運用

| プロジェクト | 役割 | 起動ディレクトリ |
|-------------|------|-----------------|
| zenn-articles | Zenn記事管理・公開 | `C:\Users\[USERNAME]\Documents\Projects\zenn-articles` |
| x-article | X記事作成・投稿 | `C:\Users\[USERNAME]\Documents\Projects\x-article` |

**引き継ぎ方法:**
1. 調査結果を相手プロジェクトのCLAUDE.md/HANDOFF.mdに追記
2. 新セッションで「HANDOFF.mdを読んで」と指示

**Stopフック（自動提案）:**
記事公開後、X記事作成を自動提案するフックを設定済み（`.claude/settings.local.json`）。
提案のみで自動実行はしない（公式ベストプラクティスに準拠）。

## 記事公開チェックリスト（重要）

記事を公開する際は、以下を必ず確認する：

### 1. 記事の準備
- [ ] `published: true` に設定
- [ ] シリーズ構成が他記事と一致
- [ ] 関連記事リンクが正しい

### 2. Git 操作
- [ ] `git status` で未コミットファイルを確認
- [ ] `git add` で対象ファイルをステージング
- [ ] `git commit` でコミット作成
- [ ] `git push origin main` でプッシュ

### 3. デプロイ確認
- [ ] Zenn のデプロイ完了を待つ（数分）
- [ ] Zenn 管理画面で記事が表示されることを確認
- [ ] 公開 URL で記事が閲覧できることを確認

:::message alert
**過去の失敗事例**
記事ファイルを作成し `published: true` に設定したが、Git にコミット・プッシュし忘れて公開されなかった。
「ファイル作成完了」≠「記事公開完了」であることを忘れない。
:::

### 確認コマンド

```bash
# 未コミットファイルの確認
git status

# コミット・プッシュ
git add articles/*.md
git commit -m "Publish: {記事タイトル}"
git push origin main

# プッシュ完了後、Zenn管理画面で確認
# https://zenn.dev/dashboard
```

### Zennレートリミット対策

Zennには投稿数の上限があり、制限にかかると記事がデプロイされない（HTTP 429エラー）。

**症状**:
```
次の記事は一定時間以内の投稿数の上限に達したためデプロイされませんでした
```

**公式情報:**
- 具体的な制限数値は非公開（スパム対策のため）
- [利用規約](https://zenn.dev/terms) 第12条に基づき、「サーバーに負担をかける行為」として制限
- 参考: [利用規約とコミュニティガイドライン改定（2025年6月）](https://info.zenn.dev/2025-06-02-guideline-update)

:::message
**ユーザー観測に基づく目安（公式ではない）**
- 1日1記事程度でも制限にかかる場合がある
- 解除まで約24時間かかるパターンが報告されている
- `git force-push` が新規投稿としてカウントされる可能性
- リトライを繰り返すと逆効果の可能性
- **レートリミット中でも、既に公開済みの記事の更新はデプロイ可能**（制限されるのは新規投稿のみ）
- **`published: false`（下書き）でpushすればレート制限に引っかからない**（公開しないため対象外）

参考: https://zenn.dev/kiitosu/scraps/82de0b7edd8618
:::

**推奨される対策:**
1. 複数記事の同時公開を避ける
2. `git force-push` ではなく通常の `git push` を使用
3. 細かい修正は1回のコミットにまとめてからpush
4. 大量移行は事前にZennに申請（お問い合わせフォーム）

**制限にかかった場合:**
1. **焦ってリトライしない**（逆効果の可能性）
2. **24時間程度待つ**
3. 改善しない場合はZennに問い合わせ
4. 空コミットで再デプロイをトリガー:
   ```bash
   git commit --allow-empty -m "Trigger Zenn redeploy"
   git push origin main
   ```

## GitHub公開リポジトリのプライバシーチェック（重要）

### 背景（2026-01-31 発覚）

zenn-articlesリポジトリがPublicのため、CLAUDE.mdに記載したローカルパスが外部から閲覧可能な状態だった。

### チェックリスト（push前に確認）

| 項目 | 確認内容 |
|------|---------|
| ユーザー名 | `C:\Users\[実名]\` → `C:\Users\[USERNAME]\` に匿名化 |
| APIキー | `.env` に記載、`.gitignore` で除外されているか |
| 認証情報 | パスワード、トークンがハードコードされていないか |
| 個人情報 | メールアドレス、電話番号が含まれていないか |

### 匿名化すべきパターン

```
# NG（実名が露出）
C:\Users\yourname\Documents\Projects\
/home/yourname/.config/

# OK（匿名化済み）
C:\Users\[USERNAME]\Documents\Projects\
/home/[USERNAME]/.config/
$env:USERPROFILE\Documents\Projects\
```

### リポジトリの公開状態確認

```bash
# 認証なしでアクセス → 200ならPublic、404ならPrivate
curl -s -o /dev/null -w "%{http_code}" https://api.github.com/repos/[OWNER]/[REPO]
```

### 対応済みリポジトリ

| リポジトリ | 状態 | 対応 |
|-----------|------|------|
| zenn-articles | Public | CLAUDE.mdのパス情報を匿名化 |
| publine | Private | プライベート化で対応 |

:::message alert
**教訓**: CLAUDE.md、HANDOFF.md、設定ファイルにローカルパスを書く際は、公開リポジトリかどうかを確認する。公開リポジトリの場合は匿名化必須。
:::
