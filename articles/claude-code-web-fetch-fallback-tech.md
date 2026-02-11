---
title: "Claude Code Web取得フォールバック機構：セットアップ手順"
emoji: "🔧"
type: "tech"
topics: ["claudecode", "mcp", "playwright", "ai"]
published: false
---

## この記事の位置づけ

[AIに「調べて」と言ったとき、裏側で何が起きているか](claude-code-web-fetch-fallback)で解説したWeb取得フォールバック機構を、自分の環境に導入する手順です。

やることは4つ。

1. Jina Reader MCPの登録
2. Playwright MCPの登録
3. サブエージェント（handoff）の作成
4. グローバル指示ファイル（CLAUDE.md）の設定

10〜15分で完了します。

## 前提

| 必要なもの | バージョン | 確認コマンド |
|-----------|-----------|-------------|
| Node.js | v18以上 | `node -v` |
| npm | （Node.jsに同梱） | `npm -v` |
| Git | 任意 | `git --version` |
| Claude Code | 最新版 | `claude --version` |

未インストールの場合はそれぞれ公式サイトから導入してください。

- Node.js: https://nodejs.org/ （LTS版）
- Git: https://git-scm.com/
- Claude Code: `npm install -g @anthropic-ai/claude-code`

:::message
以降のコマンドはすべてターミナル（Windowsならコマンドプロンプトや PowerShell、macOSならターミナル.app）で実行します。Claude Codeの対話画面に入力するものではありません。

コマンドの先頭に出てくる `claude` は、Claude Code自体のCLIコマンドです。`npm install -g @anthropic-ai/claude-code` でインストールすると使えるようになります。
:::

## Jina Reader MCPの登録

### APIキーの取得

[Jina AI](https://jina.ai/)にアカウントを作成し、ダッシュボードからAPIキーを取得します。`jina_`で始まる文字列です。

### 登録コマンド

```bash
claude mcp add jina-reader -s user -e JINA_API_KEY=<your_jina_api_key> -- npx -y jina-mcp-local
```

| オプション | 意味 |
|-----------|------|
| `-s user` | グローバル（全プロジェクト共通）で登録 |
| `-e JINA_API_KEY=...` | APIキーを環境変数として設定 |
| `npx -y jina-mcp-local` | 実行時に自動ダウンロード、事前インストール不要 |

### 確認

```bash
claude mcp list
```

`jina-reader`が表示されれば完了。

## Playwright MCPの登録

### 登録コマンド

```bash
claude mcp add playwright -s user -- npx -y @playwright/mcp@latest --headless
```

`--headless`でブラウザがバックグラウンド動作します（GUI表示なし）。

### 確認

```bash
claude mcp list
```

`playwright`が表示されれば完了。

:::message alert
初回実行時にPlaywrightがブラウザバイナリをダウンロードする場合があります。Claude Code内で`browser_navigate`が失敗したら`npx playwright install`を実行してください。
:::

## サブエージェントの作成

`~/.claude/agents/`ディレクトリに`web-fetch.md`を配置します。

```bash
# macOS / Linux
mkdir -p ~/.claude/agents

# Windows（コマンドプロンプト）
mkdir "%USERPROFILE%\.claude\agents"
```

`~/.claude/agents/web-fetch.md`を以下の内容で作成してください。

```markdown
---
name: web-fetch
description: >
  Web content fetcher with automatic fallback.
  Use proactively whenever web pages need to be read, web searches need to be performed,
  or screenshots of websites need to be captured.
  Handles all web content retrieval with Jina Reader as primary and Playwright browser as fallback.
model: haiku
---

You are a web content retrieval specialist. Your job is to fetch web content and return it cleanly.

## Fallback Protocol

Always follow this exact order when fetching web content.

### Primary: Jina Reader

Try Jina Reader first. It is fast and lightweight.

| Task | Tool |
|------|------|
| Read a single URL | `mcp__jina-reader__read_url` |
| Read multiple URLs in parallel | `mcp__jina-reader__parallel_read_url` |
| Web search | `mcp__jina-reader__search_web` |
| Parallel web search | `mcp__jina-reader__parallel_search_web` |
| Screenshot | `mcp__jina-reader__capture_screenshot_url` |

If Jina Reader succeeds, return the result immediately.

### Fallback: Playwright Browser

If Jina Reader fails (403, timeout, empty content, error), use Playwright:

1. `mcp__playwright__browser_navigate` — Navigate to the URL
2. `mcp__playwright__browser_snapshot` — Get accessibility snapshot of the page content
3. If more detail needed: `mcp__playwright__browser_evaluate` — Extract specific element text via JavaScript
4. `mcp__playwright__browser_close` — Close the browser when done

### Rules

- NEVER use the native WebFetch tool
- NEVER use the native WebSearch tool
- Always report which method was used (Jina Reader or Playwright fallback)
- If Playwright fallback was used, include the reason (e.g., "Jina Reader returned 403")
- Return content in clean markdown format
- For search tasks, return structured results with title, URL, and snippet
```

### ここがポイント

- `model: haiku`で軽量AIが担当する。コストを抑えられる
- `description`の`Use proactively`がカギ。Claude CodeがWeb取得タスクを自動的にこのサブエージェントに回す
- サブエージェントの詳細は[公式ドキュメント（英語）](https://docs.anthropic.com/en/docs/claude-code/sub-agents) / [日本語](https://docs.anthropic.com/ja/docs/claude-code/sub-agents)を参照

## グローバル指示ファイルの設定

`~/.claude/CLAUDE.md`に以下を追記します。既存の内容がある場合は末尾に追加してください。

```markdown
## Web Fetch Protocol

Webコンテンツの取得（URL読み取り、Web検索、スクリーンショット）が必要な場合は、web-fetchサブエージェントに委譲すること。

- ネイティブのWebFetch / WebSearchは使用禁止
- web-fetchサブエージェントがJina Reader → Playwrightの自動フォールバックを処理する
- ブラウザ操作（フォーム入力、クリック等）が必要な場合のみ、直接Playwrightを使用してよい
```

## 動作確認

Claude Codeを新規セッションで起動します。

```bash
claude
```

### テストサイト

前編で「がっかりパターン」の実例として使った https://antigravity.google/ がテストに最適です。このサイトはJavaScriptで描画されるため、標準のWebFetchではページ本文を取得できません。

フォールバック機構がない場合、Claude Codeは標準のWebFetchを使います。厄介なのは、エラーにはならないこと。HTTP通信自体は成功するので、Claude Codeは「取得できた」として回答してきます。ただし中身はフォントの定義ファイルやアクセス解析のコード片だけで、ページの本文は一切含まれていません。エラーが出ないぶん、ユーザーは取得に失敗したこと自体に気づきにくい。これが前編で紹介した「がっかりパターン」の正体です。

フォールバック機構を入れた状態で、以下を試してください。

```
https://antigravity.google/ の内容を読んで
```

私の環境では、以下の流れで動作しました。

1. web-fetchサブエージェント（Haiku）が自動で起動される
2. まずJina Readerで取得を試みる → コンテンツは返ってくるが、CSSアニメーション（SplitText）の影響で1文字ずつバラバラの1,629行が返る
3. サブエージェントが「まともに読めない」と判断し、Playwrightにフォールバック
4. Playwrightがブラウザでページを開き、アクセシビリティスナップショットを取得（約13,400トークン）
5. ブラウザを閉じて、結果をメインのClaude Codeに返す

きれいな本文がそのまま返ってくるわけではありません。Playwrightのスナップショットも文字がバラバラの部分を含みますが、見出しやaria-labelから「Google Antigravityは次世代のagentic開発プラットフォーム」といった意味を読み取れます。

フォールバック機構がない場合はフォントの定義やトラッキングコードしか返ってこないので、「何もわからない」と「断片的でも意味がわかる」の差は大きい。

## ファイル構成

最終的なファイル構成はこうなります。

```
~/.claude/
├── CLAUDE.md                  ← グローバル指示（web-fetchに委譲）
├── agents/
│   └── web-fetch.md           ← サブエージェント定義（フォールバックロジック）
└── mcp_servers.json           ← MCP設定（claude mcp addで自動生成）
    ├── jina-reader
    └── playwright
```

## トラブルシューティング

### MCPサーバーが接続できない

```bash
# 登録状況の確認
claude mcp list

# 一度削除して再登録
claude mcp remove jina-reader -s user
claude mcp add jina-reader -s user -e JINA_API_KEY=<key> -- npx -y jina-mcp-local
```

### Playwrightのブラウザが見つからない

```bash
npx playwright install
```

### サブエージェントが使われない

- Claude Codeを再起動してください。サブエージェントはセッション開始時に読み込まれます
- `~/.claude/agents/web-fetch.md`のファイルパスと内容を確認
- Claude Code内で`/agents`コマンドを実行し、web-fetchが一覧に表示されるか確認

### Jina APIキーのエラー

- [Jina AI](https://jina.ai/)のダッシュボードでキーが有効か確認
- キーは`jina_`で始まる文字列
- 再登録: `claude mcp remove jina-reader -s user`のあと再度`claude mcp add`

## 既知の制限

前編で詳しく触れていますが、把握しておくべき制限が3つあります。

| 制限 | 影響 |
|------|------|
| ビルトインサブエージェントはCLAUDE.mdを読まない | claude-code-guide等はネイティブWebFetchを使い続ける |
| サブエージェントの入れ子は不可 | web-fetchから別のサブエージェントは呼べない |
| セッション途中で追加しても反映されない | 新規セッションの開始が必要 |

大半のケース（ユーザーが直接「調べて」と指示する場面）ではカスタムサブエージェントが使われるので、実害は限定的です。

---

:::message
この記事は[AIに「調べて」と言ったとき、裏側で何が起きているか](claude-code-web-fetch-fallback)の実装手順をまとめたものです。フォールバック機構の背景や設計判断についてはそちらをお読みください。
:::

## 参考リンク

- [Claude Opus 4.6 リリース](https://www.anthropic.com/news/claude-opus-4-6)
- [Claude Code サブエージェント（英語）](https://docs.anthropic.com/en/docs/claude-code/sub-agents) / [日本語](https://docs.anthropic.com/ja/docs/claude-code/sub-agents)
- [Jina AI（公式サイト）](https://jina.ai/)
- [Jina Reader MCP（GitHub）](https://github.com/jina-ai/mcp-jina)
- [Playwright MCP（GitHub / Microsoft）](https://github.com/microsoft/playwright-mcp)
- [Model Context Protocol（MCP）公式サイト](https://modelcontextprotocol.io/)
