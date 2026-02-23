---
title: "Claude Codeが勝手にファイルを消した日から、権限設定を真剣にやるようになった"
emoji: "🛡️"
type: "tech"
topics: ["claudecode", "ai", "生成ai", "llm", "個人開発"]
published: true
---

## はじめに

Claude Code に「リファクタリングして」と頼んだら、`.env` ファイルを書き換えられた。

「テストを直して」と言ったら、テストコードではなく本番コードの方を変更された。

毎回「このファイルは触らないで」と念押しする日々に疲れていた。

そこで**権限設定**を本気で調べたら、Claude Code には想像以上に細かい制御の仕組みがあった。この記事では、公式ドキュメントに基づいて、権限設定の全体像と実践的な使い方を解説する。

---

## 権限モデルの全体像

Claude Code のツールには3段階の権限がある。

| ツールタイプ | 例 | 承認が必要か |
|:-----------|:---|:-----------|
| 読み取り専用 | ファイル読み取り、Grep、Glob | **いいえ** |
| Bash コマンド | シェル実行 | **はい** |
| ファイル変更 | Edit、Write | **はい** |

つまり、Claude は黙ってファイルを読めるが、**変更や実行には承認が必要**。これがデフォルトの安全装置。

---

## パーミッションモード

Claude Code の起動モードによって、承認の厳しさが変わる。

| モード | 説明 | 向いている場面 |
|:------|:-----|:------------|
| **default** | 標準。各ツールの初回使用時に確認 | 通常の開発 |
| **acceptEdits** | ファイル編集の確認をスキップ | 信頼できるプロジェクト |
| **plan** | ファイルの分析のみ。変更不可 | コードレビュー、調査 |
| **dontAsk** | 事前承認されていないツールを自動拒否 | CI/CD、自動化 |
| **bypassPermissions** | 全ての確認をスキップ | コンテナ内のみ |

:::message alert
**bypassPermissions は隔離環境限定**
Docker や VM など、Claude Code が損害を引き起こせない環境でのみ使用。通常の開発マシンでは絶対に使わない。
:::

---

## `/permissions` で現在の設定を確認する

セッション中に入力する：

```
/permissions
```

現在の Allow / Deny ルールの一覧が表示され、その場で追加・編集もできる。

---

## Allow / Deny ルールの書き方

### 基本構文

```
ツール名
ツール名(スペシファイア)
```

### 3つのルールレベル

| レベル | 説明 |
|:------|:-----|
| **Allow** | 確認なしで実行を許可 |
| **Ask** | 毎回確認を求める |
| **Deny** | 完全に拒否 |

**評価順序**: Deny → Ask → Allow（Deny が常に最優先）

### 実践的な設定例

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test *)",
      "Bash(git commit *)"
    ],
    "deny": [
      "Bash(git push *)",
      "Bash(curl *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(./secrets/**)"
    ]
  }
}
```

**この設定の意味**：
- `npm run lint`、`npm run test`、`git commit` は確認なしで実行OK
- `git push`、`curl` は完全にブロック
- `.env` ファイルと `secrets/` フォルダは読み取りすらブロック

---

## ワイルドカードパターン

`*` でグロブマッチングが使える。

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(* --version)",
      "Bash(* --help *)"
    ]
  }
}
```

:::message
**スペースの位置が重要**
- `Bash(ls *)` → `ls -la` にマッチ。`lsof` にはマッチしない（単語境界を強制）
- `Bash(ls*)` → `ls -la` と `lsof` の両方にマッチ

`*` の前にスペースがあると、そこが単語の区切りになる。
:::

:::message
**セキュリティ対策**
Claude Code はシェルオペレータ（`&&` 等）を認識する。`Bash(safe-cmd *)` は `safe-cmd && rm -rf /` のような複合コマンドの実行を許可しない。
:::

---

## ファイルパスのパターン

Read と Edit のルールでは、パスの書き方に4種類ある。

| パターン | 意味 | 例 |
|:--------|:-----|:---|
| `//path` | ファイルシステムの**絶対**パス | `Read(//Users/alice/secrets/**)` |
| `~/path` | **ホーム**ディレクトリからのパス | `Read(~/Documents/*.pdf)` |
| `/path` | **設定ファイルからの相対**パス | `Edit(/src/**/*.ts)` |
| `path` | **カレントディレクトリからの相対**パス | `Read(*.env)` |

:::message alert
**絶対パスは `//` が必要**
`/Users/alice/file` は絶対パスではなく、設定ファイルからの相対パスと解釈される。絶対パスには `//Users/alice/file` と書く。
:::

- `*` は単一ディレクトリ内のファイルにマッチ
- `**` はディレクトリを再帰的にマッチ

---

## 設定ファイルの場所と優先順位

| スコープ | 場所 | 共有 |
|:--------|:-----|:----|
| ユーザー設定 | `~/.claude/settings.json` | いいえ |
| プロジェクト共有 | `.claude/settings.json` | はい（Git管理） |
| ローカル専用 | `.claude/settings.local.json` | いいえ |
| 管理者設定 | システムレベル | IT展開 |

**優先順位**（上が最優先）：
1. 管理者設定（オーバーライド不可）
2. コマンドライン引数
3. ローカル設定
4. プロジェクト共有設定
5. ユーザー設定

:::message
**使い分けのコツ**
- **個人の好み**（lint を自動許可など）→ `~/.claude/settings.json`
- **チームルール**（`.env` を保護など）→ `.claude/settings.json`（Git管理）
- **自分だけの例外**→ `.claude/settings.local.json`（Git管理外）
:::

---

## MCP ツールの権限設定

MCP で追加したツールにも権限ルールが適用できる。

```json
{
  "permissions": {
    "allow": [
      "mcp__github__search_repositories"
    ],
    "deny": [
      "mcp__puppeteer__*"
    ]
  }
}
```

MCP ツール名は `mcp__サーバー名__ツール名` のパターン。`mcp__puppeteer__*` で Puppeteer サーバーの全ツールをブロックできる。

---

## よくある設定パターン

### パターン1：安全な開発環境

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git status)",
      "Bash(git diff *)"
    ],
    "deny": [
      "Bash(git push *)",
      "Bash(rm -rf *)",
      "Bash(curl *)",
      "Bash(wget *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "Edit(./.env)",
      "Edit(./.env.*)"
    ]
  }
}
```

### パターン2：読み取り専用レビュー

```json
{
  "permissions": {
    "deny": [
      "Edit(*)",
      "Write(*)",
      "Bash(*)"
    ]
  }
}
```

全ての変更と実行をブロック。ファイルの読み取りとGrepだけが可能。コードレビュー専用環境。

### パターン3：Web アクセスの制限

```json
{
  "permissions": {
    "allow": [
      "WebFetch(domain:github.com)",
      "WebFetch(domain:docs.anthropic.com)"
    ],
    "deny": [
      "WebFetch(*)",
      "Bash(curl *)",
      "Bash(wget *)"
    ]
  }
}
```

特定ドメインのみアクセス許可。`curl` や `wget` もブロックして抜け道を塞ぐ。

---

## Hooks との連携

[Hooks](claude-code-auto-format-hooks) と組み合わせると、さらに強力になる。

- **権限設定**: 「`.env` の読み取りを拒否する」（静的ルール）
- **Hooks**: 「`.env` を編集しようとしたら警告メッセージを返す」（動的処理）

権限設定が「壁」だとしたら、Hooks は「番人」。静的なルールでカバーできない複雑な条件は、Hooks の `PreToolUse` フックで処理する。

---

## まとめ

| ポイント | 内容 |
|---------|------|
| 確認コマンド | `/permissions` |
| ルールの優先順位 | Deny → Ask → Allow |
| 設定ファイル | `~/.claude/settings.json` or `.claude/settings.json` |
| ワイルドカード | `*`（スペースの位置に注意） |
| 絶対パス | `//` プレフィックスが必要 |
| MCP ツール | `mcp__サーバー名__ツール名` |

**覚えておくこと**：

> 「触らないで」と何度も言うくらいなら、
> 権限設定で「触れない」ようにする。

---

## 参考

- [Permissions - Claude Code Docs（公式）](https://code.claude.com/docs/en/permissions)
- [Settings - Claude Code Docs（公式）](https://code.claude.com/docs/en/settings)

---

## 関連記事

- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ：使いこなすためのTips](claude-code-tips-and-features)
- [Claude Code が動かない時に見るページ（Windows）](claude-code-windows-troubleshoot)
- [Claude Codeに「保存したら自動でフォーマット」を仕込んだら快適すぎた](claude-code-auto-format-hooks)
