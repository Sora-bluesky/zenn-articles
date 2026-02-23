---
title: "Claude Codeに外部ツールを繋ぐMCPの全体像と設定方法"
emoji: "🔌"
type: "tech"
topics: ["claudecode", "ai", "生成ai", "llm", "mcp"]
published: true
---

## はじめに

Claude Code は単体でもファイルの読み書きや検索ができる強力なツールです。

でも、こんな場面はありませんか?

> 「GitHub の Issue を確認して、関連するコードを修正して」
> 「Notion のドキュメントを参考にして、この機能を実装して」
> 「データベースの中身を見て、バグの原因を調べて」

こうした「外部ツールとの連携」を実現するのが **MCP（Model Context Protocol）** です。

MCPを設定すると、Claude Code が GitHub、Notion、データベースなどの外部サービスと直接やり取りできるようになります。コピペで情報を渡す必要がなくなり、「調べて → 判断して → 実行して」の流れをAIに一気通貫で任せられます。

ただ、MCPの設定方法は公式ドキュメントを読んでも分かりにくい部分があります。この記事では、MCPの仕組みから具体的な設定コマンドまで、体系的に整理しました。

:::message
**この記事の対象読者**
- Claude Code をインストール済みで、基本操作に慣れている方
- 外部ツールとの連携に興味がある方
- MCPの設定方法が分からず困っている方

Claude Code のインストールがまだの方は、先に[インストールガイド](claude-code-windows-install-guide)をご覧ください。
:::

:::message
**公式ドキュメント**
- [English: MCP - Claude Code](https://code.claude.com/docs/en/mcp)
- [日本語: MCP - Claude Code](https://code.claude.com/docs/ja/mcp)
:::

---

## MCPとは何か

**MCP（Model Context Protocol）** は、AIツールと外部サービスを接続するためのオープンソース標準です。

分かりやすく言えば、Claude Code に「手」を増やすようなものです。

素の Claude Code にできることは、目の前のファイルの読み書きとターミナルでのコマンド実行です。MCPを使うと、ここに「GitHub の Issue を読む手」「Notion のページを取得する手」「データベースにクエリを投げる手」が追加されます。

```mermaid
flowchart LR
    CC["Claude Code"] --> F["ファイル操作"]
    CC --> T["ターミナル"]
    CC --> MCP["MCP"]
    MCP --> GH["GitHub"]
    MCP --> NT["Notion"]
    MCP --> DB["データベース"]
    MCP --> ETC["その他"]
```

MCPで接続される外部サービスのことを **MCPサーバー** と呼びます。Claude Code が「クライアント」、GitHub や Notion 側のプログラムが「サーバー」です。

:::message
**MCPの公式情報**
- [English: Model Context Protocol](https://modelcontextprotocol.io/)
- MCPはAnthropic社が開発したオープンソースの標準仕様で、Claude Code 以外のAIツールでも採用が進んでいます
:::

---

## MCPサーバーの接続方式（トランスポート）

MCPサーバーには3つの接続方式があります。**結論から言えば、HTTP方式が使えるサーバーはHTTP方式一択**です。

| 方式 | 特徴 | おすすめ度 |
|:-----|:-----|:----------|
| **HTTP（Streamable HTTP）** | URLを指定するだけ。インストール不要 | **推奨** |
| **stdio** | ローカルにプログラムをインストールして起動 | 必要に応じて |
| **SSE** | 古い方式。新規では使わない | 非推奨 |

### HTTP方式（推奨）

URLを1つ指定するだけで接続できます。ローカルに何もインストールする必要がなく、最もシンプルです。

GitHub、Notion、Sentry、Stripe など、主要サービスの多くがHTTP方式に対応しています。

```bash
claude mcp add --transport http サーバー名 URL
```

### stdio方式

ローカルPC上でプログラム（MCPサーバー）を起動し、Claude Code と直接通信します。データベース接続やローカルファイル操作など、PCの中のリソースにアクセスする場合に使います。

```bash
claude mcp add --transport stdio サーバー名 -- コマンド 引数...
```

:::message alert
**Windowsでstdio方式を使う場合の注意点**

`npx` コマンドで起動するMCPサーバーは、Windows環境では `cmd /c` ラッパーが必要です。これを付けないと正常に起動しません。

```bash
# Windows の場合（cmd /c を付ける）
claude mcp add --transport stdio my-server -- cmd /c npx -y @some/mcp-package

# macOS / Linux の場合（そのまま）
claude mcp add --transport stdio my-server -- npx -y @some/mcp-package
```

`cmd /c` は「コマンドプロンプト経由で実行する」という意味です。Windows の環境変数やパスの解決に必要なおまじないと考えてください。
:::

### SSE方式（非推奨）

古い方式です。新しくMCPサーバーを追加する際には使わないでください。既存のSSE方式サーバーがHTTPにまだ対応していない場合にのみ使用します。

:::message
**公式ドキュメント**
- [English: MCP - Transport types](https://code.claude.com/docs/en/mcp#add-mcp-servers)
- [日本語: MCP - トランスポートタイプ](https://code.claude.com/docs/ja/mcp#mcp%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E3%81%AE%E8%BF%BD%E5%8A%A0)
:::

---

## MCPサーバーの追加手順

### 基本コマンド

MCPサーバーの追加は `claude mcp add` コマンドで行います。

```bash
claude mcp add [オプション] サーバー名 [-- コマンド 引数...]
```

**重要なルール**: すべてのオプション（`--transport`、`--scope`、`--env` など）は **サーバー名の前** に書きます。`--` の後ろに書いたものはMCPサーバーに渡されるコマンド引数として扱われます。

### HTTP方式の追加例

```bash
# GitHub を追加
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# Notion を追加
claude mcp add --transport http notion https://mcp.notion.com/mcp
```

コマンドを実行すると、ブラウザが開いて認証画面が表示されます。画面の指示に従って認証すれば完了です。

### stdio方式の追加例

```bash
# データベース接続（PostgreSQL）
claude mcp add --transport stdio db -- npx -y @bytebase/dbhub --dsn "postgresql://user:pass@localhost:5432/mydb"
```

環境変数を渡す場合は `--env` オプションを使います。

```bash
# 環境変数付きで追加
claude mcp add --transport stdio --env API_KEY=xxx my-server -- npx -y @some/mcp-package
```

### 追加完了後の確認

サーバーを追加したら、**Claude Code を再起動**してから確認してください。

```bash
# 設定ファイルの内容を確認（再起動不要）
claude mcp list

# セッション内の接続状態を確認（再起動が必要）
/mcp
```

:::message
**公式ドキュメント**
- [English: MCP - Add MCP servers](https://code.claude.com/docs/en/mcp#add-mcp-servers)
- [日本語: MCP - MCPサーバーの追加](https://code.claude.com/docs/ja/mcp#mcp%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E3%81%AE%E8%BF%BD%E5%8A%A0)
:::

---

## スコープの使い分け

MCPサーバーの設定には「どの範囲で有効にするか」を指定する **スコープ** があります。

| スコープ | オプション | 保存先 | 有効範囲 |
|:---------|:----------|:-------|:---------|
| **local** | `--scope local`（省略時のデフォルト） | `.claude/settings.local.json` | 自分の、このプロジェクトのみ |
| **project** | `--scope project` | `.mcp.json` | このプロジェクトの全メンバー |
| **user** | `--scope user` | `~/.claude.json` | 自分の全プロジェクト |

### どれを選べばいいか

迷ったら以下の基準で判断してください。

- **個人で使うツール**（GitHub、Notion など）→ `--scope user`
  - 全プロジェクトで共通して使えるので便利
- **特定プロジェクトだけで使うツール**（そのプロジェクト専用のDB接続など）→ `--scope local`
  - 他のプロジェクトに影響しない
- **チームで共有したいツール** → `--scope project`
  - `.mcp.json` がGitにコミットされ、チーム全員に適用される

```bash
# 個人用：全プロジェクトで GitHub を使う
claude mcp add --transport http --scope user github https://api.githubcopilot.com/mcp/

# プロジェクト限定：このプロジェクトでのみ DB 接続を使う
claude mcp add --transport stdio --scope local db -- npx -y @bytebase/dbhub --dsn "postgresql://..."
```

:::message
**`~/.claude.json` とは**
`~`（チルダ）は「ユーザーのホームフォルダ」を意味する記号です。Windows の場合は `C:\Users\[ユーザー名]` に相当します。つまり `~/.claude.json` は `C:\Users\[ユーザー名]\.claude.json` のことです。
:::

:::message
**公式ドキュメント**
- [English: MCP - Configuration scopes](https://code.claude.com/docs/en/mcp#configuration-scopes)
- [日本語: MCP - 設定スコープ](https://code.claude.com/docs/ja/mcp#%E8%A8%AD%E5%AE%9A%E3%82%B9%E3%82%B3%E3%83%BC%E3%83%97)
:::

---

## 認証情報の管理

MCPサーバーによっては、APIキーやトークンなどの認証情報が必要です。管理方法は接続方式によって異なります。

### HTTP方式：OAuth認証（自動）

GitHub や Notion などのHTTP方式サーバーは、**OAuth 2.0 認証** を使います。初回接続時にブラウザが開き、画面の指示に従って認証するだけです。APIキーを手動で管理する必要はありません。

認証が必要になると、Claude Code が自動的にブラウザを開きます。認証完了後は `/mcp` コマンドで接続状態を確認できます。

### stdio方式：環境変数で渡す

stdio方式のサーバーでは、`--env` オプションで環境変数として認証情報を渡します。

```bash
claude mcp add --transport stdio --env API_KEY=xxx my-server -- npx -y @some/package
```

複数の環境変数が必要な場合は、`--env` を繰り返します。

```bash
claude mcp add --transport stdio --env DB_HOST=localhost --env DB_PORT=5432 db-server -- npx -y @some/db-package
```

### `.mcp.json` での環境変数展開

チーム共有用の `.mcp.json` では、認証情報をハードコードせずに環境変数を参照できます。

```json
{
  "mcpServers": {
    "my-server": {
      "command": "npx",
      "args": ["-y", "@some/package"],
      "env": {
        "API_KEY": "${API_KEY}",
        "DB_HOST": "${DB_HOST:-localhost}"
      }
    }
  }
}
```

| 記法 | 意味 |
|:-----|:-----|
| `${API_KEY}` | 環境変数 `API_KEY` の値を使う |
| `${DB_HOST:-localhost}` | 環境変数 `DB_HOST` が未設定なら `localhost` を使う |

こうすることで、`.mcp.json` をGitにコミットしても認証情報が漏れません。各メンバーが自分のPCで環境変数を設定します。

:::message alert
**APIキーの取り扱い注意**
- APIキーはパスワードと同じです。テキストファイルに保存して放置したり、チャットで共有したりしないでください
- `.mcp.json` にAPIキーを直接書かないでください（`${VAR}` 形式で環境変数を参照しましょう）
- 誤ってGitにコミットした場合は、APIキーを再生成してください
:::

:::message
**公式ドキュメント**
- [English: MCP - Authentication](https://code.claude.com/docs/en/mcp#authentication)
- [日本語: MCP - 認証](https://code.claude.com/docs/ja/mcp#%E8%AA%8D%E8%A8%BC)
:::

---

## よく使われるMCPサーバー

以下は代表的なMCPサーバーの一覧です。HTTP方式が使えるものはHTTP方式で接続するのが最も簡単です。

### HTTP方式で接続できるサーバー

| サーバー | 用途 | 追加コマンド |
|:---------|:-----|:------------|
| **GitHub** | Issue管理、PR操作 | `claude mcp add --transport http github https://api.githubcopilot.com/mcp/` |
| **Notion** | ドキュメント参照・編集 | `claude mcp add --transport http notion https://mcp.notion.com/mcp` |
| **Sentry** | エラー監視・デバッグ | `claude mcp add --transport http sentry https://mcp.sentry.dev/mcp` |
| **Stripe** | 決済情報の参照 | `claude mcp add --transport http stripe https://mcp.stripe.com` |

初回実行時にブラウザで認証画面が開きます。認証するだけで接続完了です。

### stdio方式で接続するサーバー

| サーバー | 用途 | 追加コマンド |
|:---------|:-----|:------------|
| **PostgreSQL** | DB操作 | `claude mcp add --transport stdio db -- npx -y @bytebase/dbhub --dsn "postgresql://..."` |
| **Obsidian** | メモ連携 | [別記事で詳しく解説](claude-code-obsidian-icloud-guide) |

:::message
**その他のMCPサーバーを探す**
MCPサーバーの一覧は公式リポジトリで確認できます。
- [MCP Servers リポジトリ](https://github.com/modelcontextprotocol/servers)
- ブラウザの翻訳機能で日本語に変換して読めます
:::

:::message
**公式ドキュメント**
- [English: MCP - Popular MCP servers](https://code.claude.com/docs/en/mcp#popular-mcp-servers)
- [日本語: MCP - 人気のMCPサーバー](https://code.claude.com/docs/ja/mcp#%E4%BA%BA%E6%B0%97%E3%81%AEmcp%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC)
:::

---

## 確認とデバッグ

MCPサーバーの管理に使うコマンドをまとめます。

### 基本コマンド

| コマンド | 用途 | 再起動不要 |
|:---------|:-----|:----------|
| `claude mcp list` | 設定済みサーバーの一覧表示 | はい |
| `claude mcp get サーバー名` | 特定サーバーの詳細情報 | はい |
| `claude mcp remove サーバー名` | サーバーの削除 | はい（反映は再起動後） |
| `/mcp` | セッション内の接続状態を確認 | **いいえ（要再起動）** |

### `claude mcp list` と `/mcp` の違い

この2つは似ているようで別物です。

```mermaid
flowchart TB
    subgraph FILE["設定ファイル（.claude.json など）"]
        CONFIG["MCPサーバー設定"]
    end

    subgraph SESSION["Claude Code セッション"]
        RUNNING["起動中のMCPサーバー"]
    end

    CONFIG -->|"起動時に読み込み"| RUNNING
    CONFIG -->|"claude mcp list で参照"| LIST["一覧表示"]
    RUNNING -->|"/mcp で参照"| STATUS["接続状態表示"]
```

| コマンド | 参照先 | 用途 |
|:---------|:-------|:-----|
| `claude mcp list` | 設定ファイル | 「何が設定されているか」を確認 |
| `/mcp` | 現在のセッション | 「今、実際に接続されているか」を確認 |

**よくある混乱**: セッション中に `claude mcp add` で新しいサーバーを追加しても、`/mcp` には反映されません。設定ファイルには書き込まれますが、実際の接続はClaude Code の**起動時にのみ**行われるためです。追加後は必ず **Claude Code を再起動** してください。

### サーバーの削除

不要になったMCPサーバーは `remove` で削除できます。

```bash
# 削除
claude mcp remove サーバー名

# スコープを指定して削除（user スコープで追加した場合）
claude mcp remove サーバー名 --scope user
```

:::message
**公式ドキュメント**
- [English: MCP - Manage MCP servers](https://code.claude.com/docs/en/mcp#manage-mcp-servers)
- [日本語: MCP - MCPサーバーの管理](https://code.claude.com/docs/ja/mcp#mcp%E3%82%B5%E3%83%BC%E3%83%90%E3%83%BC%E3%81%AE%E7%AE%A1%E7%90%86)
:::

---

## MCPツールの権限設定

MCPサーバーが提供する個々の機能（ツール）に対して、権限を細かく制御できます。

例えば、「GitHub の Issue は読みたいけど、勝手に閉じられたくない」という場合、特定のツールをブロックできます。

### 権限設定の方法

`settings.json` の `permissions.deny` に、ブロックしたいツールを追加します。

ツール名は `mcp__サーバー名__ツール名` というパターンです。

```json
{
  "permissions": {
    "deny": [
      "mcp__github__close_issue",
      "mcp__github__delete_branch"
    ]
  }
}
```

この設定により、Claude Code は GitHub の Issue を閉じたりブランチを削除したりする操作ができなくなります。読み取りは引き続き可能です。

### ツール名の確認方法

接続済みのMCPサーバーが提供するツール名は、`/mcp` コマンドで確認できます。サーバー名をクリックすると、利用可能なツールの一覧が表示されます。

:::message
権限設定の詳細は、別記事で解説予定です。
:::

:::message
**公式ドキュメント**
- [English: MCP - MCP tool permissions](https://code.claude.com/docs/en/mcp#mcp-tool-permissions)
- [日本語: MCP - MCPツールの権限](https://code.claude.com/docs/ja/mcp#mcp%E3%83%84%E3%83%BC%E3%83%AB%E3%81%AE%E6%A8%A9%E9%99%90)
:::

---

## `.mcp.json` でチーム共有

チームで同じMCPサーバーを使いたい場合は、プロジェクトルートに `.mcp.json` を作成してGitにコミットします。

### 設定方法

`--scope project` を指定すると、`.mcp.json` に設定が書き込まれます。

```bash
claude mcp add --transport http --scope project github https://api.githubcopilot.com/mcp/
```

これにより、プロジェクトルートに `.mcp.json` が作成されます。

```json
{
  "mcpServers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    }
  }
}
```

### チーム共有のルール

| やること | 理由 |
|:---------|:-----|
| `.mcp.json` をGitにコミットする | チーム全員が同じ設定を使える |
| 認証情報は `${VAR}` で参照する | APIキーがGitに入らない |
| READMEに必要な環境変数を記載する | 新メンバーがセットアップしやすい |

### セキュリティ：承認プロンプト

`.mcp.json` で定義されたMCPサーバーは、初回使用時に**承認プロンプト**が表示されます。チームメンバーが意図せずMCPサーバーに接続されることはありません。

:::message
**公式ドキュメント**
- [English: MCP - Project configuration](https://code.claude.com/docs/en/mcp#project-configuration)
- [日本語: MCP - プロジェクト設定](https://code.claude.com/docs/ja/mcp#%E3%83%97%E3%83%AD%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E8%A8%AD%E5%AE%9A)
:::

---

## トラブルシューティング

### よくある問題と解決策

| 症状 | 原因 | 解決策 |
|:-----|:-----|:-------|
| `/mcp` で「No MCP servers configured」 | 設定後に再起動していない | Claude Code を終了 → 再起動 |
| `claude mcp list` では表示されるのに `/mcp` に出ない | セッション中に追加した | Claude Code を終了 → 再起動 |
| HTTP方式でブラウザが開かない | ネットワーク環境の問題 | ファイアウォールやプロキシの設定を確認 |
| stdio方式で「command not found」 | Node.js / npx 未インストール | [Node.js公式サイト](https://nodejs.org/ja)からインストール |
| Windows で stdio サーバーが起動しない | `cmd /c` が付いていない | コマンドの先頭に `cmd /c` を追加 |
| 「認証に失敗しました」 | OAuth トークンの期限切れ | `claude mcp remove` → 再追加で再認証 |

### デバッグの手順

接続がうまくいかない場合は、以下の順序で確認してください。

1. **設定を確認**: `claude mcp list` でサーバーが登録されているか
2. **Claude Code を再起動**: 設定は起動時のみ読み込まれる
3. **接続状態を確認**: `/mcp` でステータスが緑（接続済み）か
4. **サーバー側を確認**: Obsidian など、接続先のアプリが起動しているか
5. **再登録**: `claude mcp remove` → `claude mcp add` でやり直す

---

## まとめ

この記事で解説した内容を表にまとめます。

| 項目 | 内容 |
|:-----|:-----|
| **MCPとは** | AIツールと外部サービスを接続するオープンソース標準 |
| **接続方式** | HTTP（推奨）、stdio（ローカル用）、SSE（非推奨） |
| **追加コマンド** | `claude mcp add --transport [方式] [--scope スコープ] サーバー名 [URL or -- コマンド]` |
| **スコープ** | local（プロジェクト個人）、project（チーム共有）、user（全プロジェクト） |
| **認証** | HTTP方式はOAuth自動認証、stdio方式は `--env` で環境変数を渡す |
| **確認コマンド** | `claude mcp list`（設定確認）、`/mcp`（接続確認、要再起動） |
| **設定反映** | Claude Code の**再起動が必要**（セッション中の変更は反映されない） |

MCPを使いこなすと、Claude Code が「目の前のファイルだけ見えるAI」から「外部サービスと連携できるAI」に進化します。まずは GitHub や Notion など、普段使っているサービスから試してみてください。

---

## 関連記事

- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ：使いこなすためのTips](claude-code-tips-and-features)
- [Claude Code が動かない時に見るページ（Windows）](claude-code-windows-troubleshoot)
- [Claude Code x Obsidian 連携ガイド：iPhoneのメモをAIが読み取れるようにする](claude-code-obsidian-icloud-guide)

---

## 参考リンク

すべての公式ドキュメントURLをまとめます。

### Claude Code 公式ドキュメント

- [English: MCP - Claude Code](https://code.claude.com/docs/en/mcp)
- [日本語: MCP - Claude Code](https://code.claude.com/docs/ja/mcp)

### MCP 公式

- [Model Context Protocol 公式サイト](https://modelcontextprotocol.io/)
- [MCP Servers リポジトリ（GitHub）](https://github.com/modelcontextprotocol/servers)

### 関連ツール

- [Node.js 公式サイト（日本語）](https://nodejs.org/ja)
