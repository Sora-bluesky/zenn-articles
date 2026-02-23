---
title: "Claude Codeに「保存したら自動でフォーマット」を仕込んだら快適すぎた"
emoji: "🪝"
type: "tech"
topics: ["claudecode", "ai", "生成ai", "llm", "個人開発"]
published: true
---

## はじめに

Claude Codeに「Prettierでフォーマットして」と毎回頼んでいないだろうか。

あるいは「`.env` は触らないで」と何度も言い聞かせていないだろうか。

CLAUDE.md に書いても、Claudeは**お願い**として受け取るだけで、100%守ってくれるとは限らない。

そこで **Hooks** を使う。Hooks は CLAUDE.md の「お願い」をコードレベルの「強制」に変える仕組みだ。

- ファイル編集後に**自動でフォーマッター実行**
- 機密ファイルへの変更を**完全にブロック**
- 全 Bash コマンドを**ログに記録**
- 入力待ちになったら**デスクトップ通知**

この記事では、Hooks の仕組みと実践的な設定例を解説する。

---

## Hooks とは

Hooks は、Claude Code のライフサイクルの様々なポイントで実行される**ユーザー定義のシェルコマンド**。

```
あなたの指示
    ↓
Claude が行動を決定
    ↓
[PreToolUse Hook] ← ツール実行前にチェック（ブロック可能）
    ↓
ツール実行（ファイル編集、コマンド実行など）
    ↓
[PostToolUse Hook] ← ツール実行後に自動処理（フォーマット等）
```

**CLAUDE.md との違い**：

| | CLAUDE.md | Hooks |
|---|-----------|-------|
| 性質 | お願い（提案） | 強制（コード） |
| 実行保証 | なし（無視される場合あり） | 100%（シェルコマンドとして実行） |
| 用途 | ルール、慣習、好み | 自動化、ガードレール、通知 |

---

## 設定方法

### 設定ファイルの場所

| ファイル | 用途 |
|---------|------|
| `~/.claude/settings.json` | 全プロジェクト共通（個人設定） |
| `.claude/settings.json` | プロジェクト共有（Git管理） |
| `.claude/settings.local.json` | ローカル専用（Git管理外） |

### 基本構造

```json
{
  "hooks": {
    "イベント名": [
      {
        "matcher": "ツール名パターン",
        "hooks": [
          {
            "type": "command",
            "command": "実行するコマンド"
          }
        ]
      }
    ]
  }
}
```

### `/hooks` コマンドで設定する

設定ファイルを直接編集する代わりに、Claude Code 内で `/hooks` と入力すると対話的に設定できる。

---

## フックの種類

よく使うものを中心に紹介する。

### PreToolUse（ツール実行前）

ツールが実行される**前**にチェックする。**ブロックも可能**。

使い道：機密ファイルの保護、コマンドの検証

### PostToolUse（ツール実行後）

ツールが正常に完了した**直後**に実行する。

使い道：自動フォーマット、lint実行

### Notification（通知）

Claude Code が入力待ちや権限確認を求めている時に発火する。

使い道：デスクトップ通知、サウンド再生

### Stop（停止時）

Claude Code が応答を終了した時に実行する。

使い道：完了通知、セッションログの保存

### その他

| フック | タイミング |
|--------|----------|
| UserPromptSubmit | ユーザーがプロンプトを送信した直後 |
| SessionStart | セッション開始・再開時 |
| SessionEnd | セッション終了時 |
| PreCompact | コンパクト実行前 |
| SubagentStop | サブエージェント終了時 |

---

## マッチャー（matcher）の仕組み

マッチャーで「どのツールに対して発火するか」を指定する。大文字小文字を**区別する**。

| パターン | マッチ対象 |
|---------|-----------|
| `Write` | Write ツールのみ |
| `Edit\|Write` | Edit または Write |
| `Bash` | Bash コマンドのみ |
| `Notebook.*` | Notebook 系全て |
| `*` または `""` | 全ツール |

MCP ツールの場合は `mcp__サーバー名__ツール名` のパターンに従う。

---

## 実践的な設定例

### 例1：ファイル編集後に自動フォーマット

TypeScript ファイルを Prettier で自動フォーマットする。

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | { read file_path; if echo \"$file_path\" | grep -q '\\.ts$'; then npx prettier --write \"$file_path\"; fi; }"
          }
        ]
      }
    ]
  }
}
```

**仕組み**：
1. `Edit` または `Write` ツールが実行された後に発火
2. stdin（標準入力）から渡された JSON を `jq` で解析し、ファイルパスを取得
3. `.ts` ファイルなら Prettier を実行

:::message
**`jq` とは**
JSON データを加工するコマンドラインツール。Hook には実行されたツールの情報が JSON 形式で stdin（標準入力）に渡される。`jq -r '.tool_input.file_path'` で「編集されたファイルのパス」を取り出している。
:::

### 例2：機密ファイルへの変更をブロック

`.env`、`package-lock.json`、`.git/` への編集を完全にブロックする。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | { read fp; case \"$fp\" in *.env|*.env.*|package-lock.json|.git/*) echo \"Protected file: $fp\" >&2; exit 2;; esac; }"
          }
        ]
      }
    ]
  }
}
```

**ポイント**：終了コード `2` を返すと、そのツール呼び出しが**ブロック**される。stderr（標準エラー出力：エラーメッセージ用の出力先）のメッセージが Claude にフィードバックされる。

### 例3：入力待ちのデスクトップ通知

Claude Code が入力を待っている時に通知を送る。離席時に便利。

**Windows（PowerShell経由）:**

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "powershell.exe -Command \"[System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms'); [System.Windows.Forms.MessageBox]::Show('Claude Code is waiting for input')\""
          }
        ]
      }
    ]
  }
}
```

**macOS:**

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code is waiting\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

### 例4：全 Bash コマンドをログに記録

Claude Code が実行した全コマンドを記録する。何をしたか後から確認できる。

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '\"[\" + (now | strftime(\"%Y-%m-%d %H:%M:%S\")) + \"] \" + .tool_input.command' >> ~/.claude/bash-command-log.txt"
          }
        ]
      }
    ]
  }
}
```

---

## 終了コードの意味

Hook の終了コードで動作が変わる。

| 終了コード | 動作 |
|-----------|------|
| **0** | 成功。stdout は詳細モードで表示 |
| **2** | **ブロック**。stderr がエラーメッセージとして Claude にフィードバック |
| その他 | エラーだがブロックしない。stderr が詳細モードで表示 |

`PreToolUse` で終了コード 2 を返すと、そのツール呼び出しの実行を**阻止**できる。これが「ガードレール」の仕組み。

---

## 注意点

### セキュリティ

Hooks は**任意のシェルコマンドを自動実行**する。つまり：

- ユーザーアカウントがアクセスできる全ファイルを変更・削除可能
- 悪意のあるスクリプトが仕込まれると危険

**対策**：
- 入力を検証する（stdin の JSON を盲目的に信頼しない）
- シェル変数は常にクォートする（`"$VAR"`）
- 絶対パスを使用する
- `.env` や `.git/` はスキップする

### 設定の反映タイミング

- Hook の設定は**起動時にスナップショット**される
- セッション中に設定を変更しても**即座には反映されない**
- 変更が検出されると警告が表示され、`/hooks` で確認が必要

### タイムアウト

- デフォルト **60秒** でタイムアウト
- `"timeout": 30` のように個別に設定可能

---

## まとめ

| ポイント | 内容 |
|---------|------|
| Hooks とは | ツール実行前後に自動で走るシェルコマンド |
| CLAUDE.md との違い | 「お願い」→「強制」 |
| 主な用途 | 自動フォーマット、ファイル保護、ログ、通知 |
| ブロックの方法 | PreToolUse で終了コード 2 を返す |
| 設定ファイル | `~/.claude/settings.json` or `.claude/settings.json` |

**覚えておくこと**：

> CLAUDE.md に「〜しないで」と書いて守られなかったら、
> それは Hook で強制すべきルール。

---

## 参考

- [Hooks - Claude Code Docs（公式）](https://code.claude.com/docs/en/hooks)
- [Best Practices - Claude Code Docs（公式）](https://code.claude.com/docs/en/best-practices)

---

## 関連記事

- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ：使いこなすためのTips](claude-code-tips-and-features)
- [Claude Code が動かない時に見るページ（Windows）](claude-code-windows-troubleshoot)
- [Claude Codeが勝手にファイルを消した日から、権限設定を真剣にやるようになった](claude-code-permissions)
