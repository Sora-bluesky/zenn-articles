---
title: "ObsidianをAIの「司令塔」にする ── MCP連携で39ソース自動収集の全貌"
emoji: "🧠"
type: "tech"
topics: ["obsidian", "mcp", "claudecode", "ai", "個人開発"]
published: true
---

## この記事で分かること

- **MCP** を使えば、AIツールからObsidianのノートを直接読み書きできる
- **39の公式ソース** からAIニュースを毎日自動収集する仕組みの全貌
- **コマンド一発・約3分** で4社のニュースが日次レポートとしてObsidianに保存される

:::message
**シリーズ構成**
- **ObsidianをAIの「司令塔」にする ── MCP連携で39ソース自動収集の全貌**（この記事）
- [Obsidian CLI セットアップ完全ガイド ── Windows環境でハマった全記録](obsidian-cli-setup-guide)

**関連記事**
- [Claude Code × Obsidian 連携ガイド：iPhoneのメモをAIが読み取れるようにする](claude-code-obsidian-icloud-guide) ── iCloud経由のVault同期手順
:::

:::message alert
**検証環境**: Windows 11 / Claude Code v2.1.39 / Obsidian v1.12.1 / Node.js v20
**検証日**: 2026年2月11日
本記事の情報は検証日時点のものです。最新情報は各公式ドキュメントを確認してください。
:::

## Before / After

| | Before（手動） | After（MCP連携） |
|--|---------------|-----------------|
| 情報収集 | 毎朝39サイトをブラウザで巡回 | **コマンド一発、約3分** |
| 整理 | コピペでメモに転記 | **Obsidianに自動保存** |
| 重複チェック | 「これ昨日も見た？」と記憶頼り | **自動で既読スキップ** |
| 要約 | 自分で読んで要点をまとめる | **AIが3段構成で要約** |

## はじめに

「AIツールを使いこなしたい。でも情報が散らばって追いきれない」

OpenAI、Google、Anthropicなど主要AI企業は、毎日のように新機能をリリースしている。APIの変更、アプリのアップデート、研究論文の発表──全部を手作業でチェックするのは現実的ではない。

本記事では、**Obsidian**をAI情報の「司令塔」として活用し、**39の公式ソースから毎日自動でニュースを収集・整理する仕組み**を紹介する。

使うのは以下の3つだけだ：
- **Obsidian**（ノートアプリ。無料）
- **Claude Code**（AIコーディングツール。Pro $20/月 または Max $100/月〜）
- **MCP**（Model Context Protocol ── AIとアプリをつなぐ標準規格。無料）

:::message
**料金について**
- Obsidian: **無料**（Sync等の有料機能は不要）
- Claude Code: **Pro（月額$20 / 約3,000円）** 以上が必要。頻繁に使うなら Max（月額$100〜 / 約15,000円〜）が安心
- Node.js: **無料**
:::

## MCPとは何か

**MCP（Model Context Protocol）** は、AIツールと外部アプリケーションを接続するための標準規格である。Anthropic（Claude の開発元）が策定し、オープンソース（誰でも無料で使える形式）で公開されている。

従来、AIツールからObsidianのノートを読み書きするには、専用のプラグイン（拡張機能）やAPI（外部連携の窓口）を個別に設定する必要があった。MCPはこの「接続」を標準化し、**一度設定すれば、どのAIツールからでも同じ方法でObsidianを操作できる**ようにする。

```
┌──────────────┐      MCP       ┌──────────────┐
│  Claude Code │ ◄──────────► │   Obsidian   │
│  (AIツール)   │   標準規格     │  (ノートアプリ) │
└──────────────┘               └──────────────┘
```

### 具体的にできること

| MCP操作 | 何ができるか | 実際の用途 |
|---------|-------------|-----------|
| ノート作成 | 新しいノートを自動で作る | 日次ニュースレポート自動生成 |
| ノート読み取り | 既存ノートの内容を取得 | 前日の記事との重複チェック |
| 末尾への追記 | 既存ノートに情報を追加 | ニュースの追記 |
| 見出し単位の編集 | 特定セクションだけを更新 | 「まとめ」だけ書き換え |
| テキスト検索 | Vault全体を横断検索 | 関連情報を探す |
| 外部URL取得 | Webページの内容を取得 | RSS（更新情報の配信形式）やHTMLの直接取得 |

## しくみの全体像

![しくみの全体像](/images/obsidian-mcp/architecture.png)

Claude Codeが**4社分の担当を同時に起動**し、各ベンダーのソースを並列で取得する。取得結果は重複排除エンジンを通過し、新規記事だけがObsidianに書き込まれる。

## 3層フェッチ戦略

39のソースは、取得方法によって3つの層に分類している：

| 層 | 取得方法 | 対象 | ソース数 |
|----|---------|------|---------|
| **Layer 1** | 直接取得 | RSS（更新情報配信）、HTML、GitHub | 35 |
| **Layer 2** | Web検索で代替 | アクセスが拒否されるソース | 1 |
| **Layer 3** | ブラウザ自動操作 | JavaScriptで動的生成されるサイト | 3 |

**Layer 1** が大半を占める。MCPの取得機能は一般的なアクセスよりエラーが少なく、安定している。

**Layer 2** は、ChatGPT Release Notesのように直接アクセスが拒否されるソース。Web検索で代替取得する。

**Layer 3** は、Google Antigravityのようにページ全体がJavaScriptで動的に生成されるサイト。Playwright（ブラウザ自動操作ツール）で事前にページを読み込んでからテキストを抽出する。

:::details 対象ソース一覧（39ソース）

### OpenAI（9ソース）
| カテゴリ | ソース | 取得方法 |
|---------|--------|---------|
| 全般 | News RSS | 直接取得 |
| 全般 | YouTube | RSS |
| API | Developer Changelog RSS | 直接取得 |
| アプリ | ChatGPT Release Notes | Web検索（Layer 2） |
| 研究 | OpenAI Cookbook | GitHub |
| IDE | Codex Changelog | 直接取得 |
| IDE | Codex Docs | 直接取得 |
| IDE | Codex GitHub Releases | GitHub |

### Google（13ソース）
| カテゴリ | ソース | 取得方法 |
|---------|--------|---------|
| 全般 | Blog (AI) RSS | 直接取得 |
| 全般 | Developers Blog RSS | 直接取得 |
| 研究 | Research RSS | 直接取得 |
| 研究 | Gemini Cookbook | GitHub |
| API | Vertex AI GenAI Release Notes | 直接取得 |
| アプリ | Gemini App Release Notes | 直接取得 |
| アプリ | Google Labs | 直接取得 |
| IDE | Antigravity Changelog/Docs/Download | ブラウザ自動操作（Layer 3） |
| IDE | Antigravity YouTube | RSS |
| IDE | Antigravity Codelabs | 直接取得 |

### Anthropic（12ソース）
| カテゴリ | ソース | 取得方法 |
|---------|--------|---------|
| 全般 | News / YouTube / MCP Protocol Blog | 直接取得 / RSS |
| API | Developer Platform | 直接取得 |
| アプリ | Claude App Release Notes | 直接取得 |
| 研究 | Research / Alignment / Cookbooks | 直接取得 / GitHub |
| IDE | Claude Code (CHANGELOG / Docs / GitHub) | GitHub / 直接取得 |

### WordPress（5ソース）
| カテゴリ | ソース | 取得方法 |
|---------|--------|---------|
| 全般 | WordPress.org News | 直接取得 |
| API | MCP Adapter GitHub | GitHub |
| 研究 | Make WordPress AI | 直接取得 |
| IDE | Developer Blog / Agent Skills | 直接取得 / GitHub |

:::

## 重複排除のしくみ

毎日実行すると同じ記事が何度も出てくる。これを防ぐのが**重複排除エンジン**である。

```json
{
  "seen_ids": [
    "openai-codex-app-launch",
    "anthropic-opus-4-6",
    "claude-code-v2.1.39"
  ],
  "last_updated": "2026-02-11T12:00:00.000Z"
}
```

各記事に一意のID（識別子）を付与し、処理済みの記事をJSONファイルで管理する。次回実行時にこのリストと照合し、**既読記事はスキップ**する。

さらに安全策として二重チェックを行う：
1. **前日のノートも確認** ── タイトルの一致でもスキップ判定
2. **ID + タイトル の二重チェック** ── どちらか一致でスキップ

## 出力フォーマット

各記事は以下の3段構成で保存される：

```markdown
### [記事タイトル](URL)
📅 **投稿日**: 2026-02-11

**1行要約**: 何についての更新か
**何が変わった？**: 技術的な変更点
**どう活かせる？**: 非エンジニアでも理解できる活用方法
```

| 項目 | 対象読者 | 読み方 |
|------|---------|--------|
| **1行要約** | 全員 | 流し読みで「気になる/気にならない」を判断 |
| **何が変わった？** | 技術者 | 具体的な変更点を把握 |
| **どう活かせる？** | 非エンジニア | 「自分にとって何が嬉しいのか」に答える |

### 実際の出力例

以下は2026年2月11日に自動収集されたAnthropicニュースの一部である。

> ### [Claude Code v2.1.39](https://github.com/anthropics/claude-code/releases/tag/v2.1.39)
> 📅 **リリース日**: 2026-02-10
> **1行要約**: ターミナル描画パフォーマンス改善と致命的エラーが表示されない問題の修正。
> **何が変わった？**: ターミナルの描画パフォーマンスを改善。致命的エラーが握りつぶされて表示されない問題を修正。セッション終了後にプロセスがハングする問題を修正。
> **どう活かせる？**: 致命的エラーが見えなくなっていた問題が修正されたため、トラブルシューティングが格段にしやすくなる。セッション終了後にターミナルが固まる事象も解消。

## 実行結果の実例

![AI Newsの出力結果](/images/obsidian-mcp/ai-news-output.png)

2026年2月11日の実行結果を紹介する。

| ベンダー | 新規 | 主な記事 |
|---------|------|---------|
| OpenAI | 8件 | Deep Research GPT-5.2アップデート、llms.txt対応 |
| Google | 3件 | Google Photos Askボタン、DialogLab |
| Anthropic | 2件 | Claude Code v2.1.38/39 |
| WordPress | 1件 | WP 7.0 Beta 1向け開発者まとめ |

Claude Codeで `/ai-news`（筆者が作成したカスタムコマンド）を実行すると、4社39ソースから**14件の新規記事**を収集し、Obsidianに日次レポートとして自動保存した。所要時間は約3分である。

:::message
**再現性について**
本記事のセットアップ手順（Step 1〜3）で、**ObsidianとClaude CodeのMCP接続が完了**する。39ソースの自動収集を再現するには、ソース定義やカスタムコマンドの追加設定が別途必要である（別記事で公開予定）。
:::

## セットアップ手順

### 前提条件

| 項目 | 必要なもの | 費用 |
|------|-----------|------|
| Obsidian | デスクトップ版（v1.0以上） | 無料 |
| Claude Code | CLI版 or VS Code拡張 | Pro $20/月〜 |
| Node.js | v18以上 | 無料 |

:::message
Node.js（ノードジェイエス）はプログラムの実行環境。MCPサーバーの起動に必要。[公式サイト](https://nodejs.org/ja)からダウンロードしてインストールする。
:::

### Step 1: Obsidian MCP プラグインの導入

1. Obsidian → 設定 → コミュニティプラグイン
2. 「**Local REST API**」を検索してインストール・有効化
3. プラグイン設定でAPIキー（接続用のパスワード）を確認

![Local REST API設定画面](/images/obsidian-mcp/rest-api-settings.png)

### Step 2: Claude Code にMCPサーバーを登録

**Windows** の場合、PowerShellで以下のコマンドを実行する：

```powershell
# APIキーを変数に設定（「あなたのAPIキー」を実際のキーに置き換える）
$apikey = "あなたのAPIキー"

# MCPサーバーを登録
claude mcp add obsidian -e OBSIDIAN_API_KEY=$apikey --scope user -- cmd /c npx -y obsidian-mcp
```

:::message
**コマンドの意味**
- `claude mcp add obsidian`: Claude Codeに「obsidian」という名前でMCPサーバーを登録
- `-e OBSIDIAN_API_KEY=...`: Step 1で確認したAPIキーを環境変数として渡す
- `--scope user`: 全プロジェクトで共通して使う設定にする
- `cmd /c npx -y obsidian-mcp`: Windows環境でMCPサーバーを起動するコマンド
:::

:::details macOS / Linux の場合

```bash
claude mcp add obsidian \
  -e OBSIDIAN_API_KEY="あなたのAPIキー" \
  --scope user \
  -- npx -y obsidian-mcp
```

:::

:::message alert
**重要**: 登録後、Claude Codeを**再起動**する必要がある。セッション中に登録しても、現在のセッションには反映されない。
:::

### Step 3: 動作確認

Claude Codeを再起動し、以下を試す：

```
Obsidianのノート一覧を見せて
```

![MCP接続成功](/images/obsidian-mcp/mcp-connected.png)

MCP経由でVault内ファイルが表示されれば成功だ。

うまくいかない場合は、以下のコマンドで接続状態を確認する：

```powershell
# 登録済みのMCPサーバーを確認
claude mcp list
```

`obsidian` が `Connected` と表示されていればOK。表示されない場合はStep 2を再確認する。

## 運用で分かった知見

### うまくいったこと

- **MCP取得の安定性**: 一般的なHTTPリクエストと比べてアクセス拒否エラーが格段に少ない
- **並列実行**: 4ベンダーを同時に取得することで所要時間を大幅短縮
- **重複排除の確実性**: ID + タイトルの二重チェックで漏れ・重複がほぼゼロ

### ハマったこと

| 問題 | 原因 | 対処 |
|------|------|------|
| 日本語見出しで部分編集が失敗 | MCPの制約 | 末尾追記で代替 |
| Google Developers Blog RSSに日付がない | RSS仕様の問題 | 記事内容から推定 |
| ChatGPT Release Notesがアクセス拒否 | OpenAI側の制限 | Web検索で代替取得 |

### 廃止したソース

運用中にアクセスできなくなったソースは、代替ソースに統合して対処した：

| 旧ソース | 代替 | 理由 |
|----------|------|------|
| OpenAI API Changelog (HTML) | Developer Changelog RSS | アクセス拒否 |
| OpenAI Research Blog | News RSS | アクセス拒否 |
| Gemini API Changelog | Vertex AI GenAI Release Notes | リダイレクト+JavaScript必須 |

**重要な教訓**: 「動かなくなったソースを黙ってスキップ」は最悪の選択肢である。取得失敗は必ずレポートに記載し、代替手段を検討する運用にしている。

## まとめ

- **MCP** を使えば、ObsidianをAIツールの「外部記憶装置」として活用できる
- **39ソース** をLayer別に分類し、最適な取得方法で並列収集
- **重複排除** で同じ記事が何度も出てこない
- **3段構成の要約** で、流し読みから深掘りまで対応
- コマンド一発、約3分で完了

### 次のステップ

1. **まずMCP接続を試す**: 本記事のStep 1〜3で、ObsidianとClaude Codeが繋がる
2. **ノート操作を試す**: 「新しいノートを作って」「既存のノートを検索して」と指示してみる
3. **CLIも追加する**: Obsidian 1.12.0で追加された公式CLIを組み合わせると、さらに強力な自動化が可能になる → [Obsidian CLI セットアップ完全ガイド](obsidian-cli-setup-guide)

---

## 参考

- [Model Context Protocol 公式サイト](https://modelcontextprotocol.io/)
- [Obsidian Local REST API プラグイン](https://github.com/coddingtonbear/obsidian-local-rest-api)
- [Claude Code MCP ドキュメント](https://code.claude.com/docs/en/mcp)
- [obsidian-mcp（npm）](https://www.npmjs.com/package/obsidian-mcp)

※公式ドキュメントは英語です。ブラウザの翻訳機能で日本語に変換して読めます。

---

## 関連記事

- [Claude Code × Obsidian 連携ガイド：iPhoneのメモをAIが読み取れるようにする](claude-code-obsidian-icloud-guide) ── iCloud経由のVault同期手順
- [Claude Code 実践Tips 1：コンテキスト管理が全ての土台](claude-code-context-management)
