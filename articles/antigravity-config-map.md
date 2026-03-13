---
title: "Google Antigravity 設定ファイル完全マップ：どれが何を制御するか"
emoji: "🗺️"
type: "tech"
topics: ["google", "gemini", "mcp", "ai", "vscode"]
published: false
---

## この記事でわかること

Antigravity と Gemini CLI、設定ファイルが散らばりすぎている。

自分の場合、`settings.json` に MCP を書いたのに Antigravity で一切認識されず、数時間溶かした。原因は「Antigravity は `settings.json` を読まない」というだけの話だった。エラーも出ない。静かに無視される。

この記事では、Antigravity / Gemini CLI が参照する全設定ファイルの場所・役割・優先順位を一覧にまとめた。「あのファイルどこだっけ」となったらここに戻ってくればいい。

---

## 設定ファイル一覧

まず全体像。これだけ押さえておけば迷わない。

| ファイル | 用途 | 対象ツール | 備考 |
|---------|------|-----------|------|
| `~/.gemini/settings.json` | グローバル設定（MCP含む） | Gemini CLI | CLI のメイン設定 |
| `~/.gemini/antigravity/mcp_config.json` | MCP サーバー設定 | Antigravity | Antigravity 専用の MCP 設定 |
| `~/.gemini/GEMINI.md` | グローバルルール | 両方 | システムプロンプト的に使われる。競合リスクあり |
| `<workspace>/GEMINI.md` | プロジェクトルール | 両方 | プロジェクト固有の指示 |
| `~/.gemini/antigravity/browserAllowlist.txt` | ブラウザアクセス許可リスト | Antigravity | Antigravity 専用 |
| `~/.gemini/antigravity/skills/` | グローバルスキル | Antigravity | Antigravity 専用 |
| `<workspace>/.agents/skills/` | プロジェクトスキル | Antigravity | プロジェクト固有 |
| `~/.gemini/google_accounts.json` | Google アカウント認証情報 | 両方 | 自動生成。手動編集しない |
| `~/.gemini/state.json` | 状態管理 | 両方 | 自動生成。手動編集しない |

`~` は Windows では `C:\Users\[USERNAME]` に読み替える。

| Gemini CLI のみ | 両方が読む | Antigravity のみ |
|:---|:---|:---|
| `settings.json` | `GEMINI.md`（グローバル） | `mcp_config.json` |
| | `GEMINI.md`（プロジェクト） | `browserAllowlist.txt` |
| | | `skills/`（グローバル） |
| | | `skills/`（プロジェクト） |

:::message
`google_accounts.json` と `state.json` は両ツールが自動生成・参照する。手動で編集するものではないため上の表からは省略。
:::

---

## 各ファイルの詳細

### settings.json（Gemini CLI のメイン設定）

**場所**: `~/.gemini/settings.json`
**読むツール**: Gemini CLI のみ（Antigravity は読まない）

Gemini CLI のグローバル設定ファイル。MCP サーバーの定義、テーマ、モデル指定などを記述する。

```json
{
  "mcpServers": {
    "google-developer-knowledge": {
      "httpUrl": "https://developerknowledge.googleapis.com/mcp",
      "headers": {
        "X-Goog-Api-Key": "YOUR_API_KEY"
      }
    }
  },
  "theme": "Default"
}
```

手動編集する。MCP サーバーを追加・変更するたびにここを書き換える。

### mcp_config.json（Antigravity の MCP 設定）

**場所**: `~/.gemini/antigravity/mcp_config.json`
**読むツール**: Antigravity のみ（Gemini CLI は読まない）

Antigravity が参照する MCP サーバー設定。`settings.json` とは別ファイルなので、両方のツールで同じ MCP サーバーを使いたい場合は両方に書く必要がある。

```json
{
  "mcpServers": {
    "my-mcp-server": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-server-example"],
      "env": {}
    }
  }
}
```

ここが空 `{}` でもエラーは出ない。MCP サーバーが「存在しない」として静かに処理される。これが一番やっかいで、設定ミスに気づけない原因になる。

:::message
**MCP Store からインストールした場合**
VS Code の MCP Store（拡張機能パネル）からインストールした MCP サーバーは、`mcp_config.json` に自動追記される。手動で書く必要はない。ただし Store にないサーバーを使う場合は手動編集が必要。
:::

### GEMINI.md（グローバルルール）

**場所**: `~/.gemini/GEMINI.md`
**読むツール**: Gemini CLI、Antigravity の両方

Claude Code の `CLAUDE.md` に相当する。セッション開始時にシステムプロンプト的に読み込まれる。

```markdown
# グローバルルール

- 日本語で応答する
- コードにはコメントを付ける
- テストを書いてから実装する
```

手動で作成・編集する。**両方のツールが読む**ので、ツール固有の指示を書くと競合する（後述）。

### <workspace>/GEMINI.md（プロジェクトルール）

**場所**: プロジェクトルート直下の `GEMINI.md`
**読むツール**: Gemini CLI、Antigravity の両方

プロジェクト固有のルールを書く。グローバルの `GEMINI.md` より優先される（同じ指示が矛盾する場合、プロジェクト側が勝つ）。

Git リポジトリに含めれば、チームで共有できる。

### browserAllowlist.txt（ブラウザアクセス許可）

**場所**: `~/.gemini/antigravity/browserAllowlist.txt`
**読むツール**: Antigravity のみ

Antigravity がブラウザでアクセスできるドメインのホワイトリスト。1行に1ドメイン。

```
github.com
stackoverflow.com
developer.mozilla.org
```

### skills/（スキルファイル）

**グローバル**: `~/.gemini/antigravity/skills/`
**プロジェクト**: `<workspace>/.agents/skills/`
**読むツール**: Antigravity のみ

Claude Code のスキルに相当する。Markdown ファイルで定義し、Antigravity がタスク実行時に参照する。

### google_accounts.json / state.json（自動生成）

**場所**: `~/.gemini/google_accounts.json`、`~/.gemini/state.json`
**読むツール**: 両方

認証情報と内部状態を管理するファイル。`gemini auth login` や初回起動時に自動生成される。手動で編集する必要はない。中身を見ても問題ないが、書き換えると認証が壊れる可能性がある。

:::message
**公式ドキュメント**
- [English: Gemini CLI Configuration](https://github.com/google-gemini/gemini-cli/blob/main/docs/configuration.md)
- [English: Antigravity MCP Guide](https://antigravity.google/docs/mcp)
:::

---

## settings.json vs mcp_config.json

ここが一番ハマるポイント。自分も「`settings.json` に MCP 書いたのに Antigravity で認識されない」で数時間溶かした。

結論を表にする。

| 項目 | settings.json | mcp_config.json |
|------|--------------|-----------------|
| 場所 | `~/.gemini/settings.json` | `~/.gemini/antigravity/mcp_config.json` |
| 読むツール | Gemini CLI | Antigravity |
| MCP 設定 | `mcpServers` キーに記述 | `mcpServers` キーに記述 |
| 空の場合 | Gemini CLI がデフォルト設定で動作 | Antigravity が MCP なしで動作（エラー出ない） |
| MCP Store | 関係なし | Store からのインストールで自動追記 |

**両方のツールを使っている場合、同じ MCP サーバーを2箇所に書く必要がある**。面倒だが、現時点ではこれが仕様。片方だけ書いて「繋がらない」は本当によくある。

具体的なシナリオで説明する。

### シナリオ: Developer Knowledge API を両方で使いたい

**Gemini CLI 側** (`~/.gemini/settings.json`):

```json
{
  "mcpServers": {
    "google-developer-knowledge": {
      "httpUrl": "https://developerknowledge.googleapis.com/mcp",
      "headers": {
        "X-Goog-Api-Key": "YOUR_API_KEY"
      }
    }
  }
}
```

**Antigravity 側**: MCP Store から Firebase MCP をインストール。`mcp_config.json` に自動追記される。Firebase MCP には `developerknowledge_search_documents` ツールが内蔵されているので、httpUrl 型を手動設定する必要はない。

（Developer Knowledge API の詳しいセットアップ手順は[別記事](https://zenn.dev/sora_biz/articles/google-developer-knowledge-api-mcp)にまとめている）

---

## GEMINI.md の競合問題

`~/.gemini/GEMINI.md` は Gemini CLI と Antigravity の両方が読む。ここに「Gemini CLI でだけ有効にしたい指示」を書くと、Antigravity にも適用されてしまう。

### 実際に起きる問題

たとえばグローバル GEMINI.md にこう書いたとする:

```markdown
# ルール
- ファイル編集は必ず差分表示してから実行する
- shell コマンドは実行前に確認する
```

Gemini CLI ではこれで問題ない。だが Antigravity は VS Code 上で動くため、ファイル編集の差分表示は VS Code 側のUIで処理される。「差分表示してから実行する」という指示が Antigravity の動作と噛み合わず、無駄な確認ステップが増えたりする。

### 推奨する使い分け

| レベル | ファイル | 書く内容 |
|--------|---------|---------|
| グローバル | `~/.gemini/GEMINI.md` | 両ツール共通のルール（言語設定、コードスタイルなど） |
| プロジェクト | `<workspace>/GEMINI.md` | プロジェクト固有のルール |
| ツール固有 | （現状手段なし） | Gemini CLI 専用 / Antigravity 専用の指示は分離できない |

現時点では、ツール固有の GEMINI.md を分離する公式手段がない。この問題は GitHub Issue でも議論されている。

> 参考: [gemini-cli#16058 - GEMINI.md should support tool-specific sections](https://github.com/google-gemini/gemini-cli/issues/16058)

実用的な回避策として、GEMINI.md の先頭に条件分岐の注釈を書いている人もいる:

```markdown
# 共通ルール
- 日本語で応答する

# Gemini CLI 専用（Antigravity では無視してください）
- shell コマンドは実行前に確認する
```

正直、「無視してください」がどこまで効くかは保証されない。ただ完全に無視されるよりはマシ、という温度感で使っている。

:::message
**公式ドキュメント**
- [English: GEMINI.md Guide](https://github.com/google-gemini/gemini-cli/blob/main/docs/gemini-md.md)
- [GitHub Issue #16058: GEMINI.md tool-specific sections](https://github.com/google-gemini/gemini-cli/issues/16058)
:::

---

## よくある間違い

自分が踏んだ地雷と、X やフォーラムで見かける報告をまとめた。

### 1. settings.json に MCP を書いて Antigravity で繋がらない

最も多い間違い。Antigravity は `settings.json` を読まない。MCP 設定は `~/.gemini/antigravity/mcp_config.json` に書く。

### 2. mcp_config.json が空なのに気づかない

`mcp_config.json` の中身が `{}` でも、Antigravity は何も言わずに起動する。MCP サーバーが一切ロードされていないのに、エラーメッセージゼロ。

確認方法:

```powershell
Get-Content ~/.gemini/antigravity/mcp_config.json
```

中身が `{}` や `{"mcpServers": {}}` だったら、何も設定されていない。

### 3. GEMINI.md に CLI 専用の指示を書いて Antigravity が混乱する

前述の競合問題。グローバル GEMINI.md には両ツール共通の指示だけ書く。

### 4. 設定変更後にセッション再起動を忘れる

MCP 設定ファイルを変更しても、現在のセッションには反映されない。Gemini CLI は `exit` して再起動、Antigravity は VS Code の Reload Window（`Ctrl+Shift+P` → `Developer: Reload Window`）が必要。

変更したのに繋がらない → まず再起動。これを忘れて「壊れた」と焦るのは全員が通る道。

### 5. .antigravity フォルダが API と競合する

プロジェクトルートに `.antigravity` フォルダが存在すると、Antigravity の動作に影響することがある。Google AI Developers Forum でも報告されている。

> 参考: [Solved: Antigravity error from .antigravity folder](https://discuss.ai.google.dev/t/solved-antigravity-error-from-antigravity-folder/126886)

心当たりがあれば `.antigravity` フォルダをリネームまたは削除して、Antigravity を再起動してみる。

:::message
**公式ドキュメント**
- [Google AI Developers Forum](https://discuss.ai.google.dev/)
:::

---

## 設定ファイルの確認コマンド

「今の設定がどうなっているか」をサッと確認するコマンド集。

### PowerShell（Windows）

```powershell
# MCP 設定の確認（Antigravity）
Get-Content ~/.gemini/antigravity/mcp_config.json

# MCP 設定の確認（Gemini CLI）
Get-Content ~/.gemini/settings.json

# GEMINI.md の確認（グローバル）
Get-Content ~/.gemini/GEMINI.md

# 設定ファイルの存在確認（一括）
Get-ChildItem ~/.gemini/ -Recurse -Filter *.json

# antigravity フォルダの中身
Get-ChildItem ~/.gemini/antigravity/ -Recurse
```

### bash（Linux / macOS / WSL）

```bash
# MCP 設定の確認（Antigravity）
cat ~/.gemini/antigravity/mcp_config.json

# MCP 設定の確認（Gemini CLI）
cat ~/.gemini/settings.json

# GEMINI.md の確認（グローバル）
cat ~/.gemini/GEMINI.md

# 設定ファイルの存在確認（一括）
find ~/.gemini -name "*.json" -type f

# antigravity フォルダの中身
ls -la ~/.gemini/antigravity/
```

### ディレクトリ構造の全体像

自分の環境で実際に確認すると、こんな構造になっているはず:

```
~/.gemini/
├── settings.json              ← Gemini CLI が読む
├── GEMINI.md                  ← 両方が読む
├── google_accounts.json       ← 自動生成（触らない）
├── state.json                 ← 自動生成（触らない）
└── antigravity/
    ├── mcp_config.json        ← Antigravity が読む
    ├── browserAllowlist.txt   ← Antigravity 専用
    └── skills/                ← Antigravity 専用
        └── my-skill.md
```

ファイルが存在しない場合は、ツールの初回起動時に自動生成されるものと、手動で作成が必要なものがある。`settings.json` と `mcp_config.json` は手動作成。`google_accounts.json` と `state.json` は自動生成。

---

## まとめ

設定ファイルが分散しているのは正直つらい。でも構造さえ把握すれば、「なぜ繋がらないのか」の切り分けが格段に速くなる。

押さえるべきポイントは3つだけ:

- **Antigravity と Gemini CLI は設定ファイルが別**。`settings.json` は CLI、`mcp_config.json` は Antigravity。両方使うなら両方に書く
- **`mcp_config.json` が空でもエラーは出ない**。繋がらないときはまずファイルの中身を確認する
- **GEMINI.md は両方が読む**。ツール固有の指示はワークスペースレベルに書くか、注釈で分離する

迷ったらこの記事の一覧表に戻ってくればいい。

---

## 関連記事

- [llms.txtでは足りなかった — Google Developer Knowledge APIにたどり着いた話](https://zenn.dev/sora_biz/articles/google-developer-knowledge-api-mcp)
- [Google Antigravity が動かない時に見るページ](https://zenn.dev/sora_biz/articles/antigravity-troubleshoot-guide)

## 参考リンク

- [Gemini CLI Configuration（GitHub）](https://github.com/google-gemini/gemini-cli/blob/main/docs/configuration.md)
- [Antigravity MCP Guide](https://antigravity.google/docs/mcp)
- [GitHub Issue #16058: GEMINI.md should support tool-specific sections](https://github.com/google-gemini/gemini-cli/issues/16058)
- [Google AI Developers Forum: Antigravity error from .antigravity folder](https://discuss.ai.google.dev/t/solved-antigravity-error-from-antigravity-folder/126886)
