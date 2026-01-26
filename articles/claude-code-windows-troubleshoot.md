---
title: "Claude Codeが動かない時に見るページ（Windows編）"
emoji: "🔧"
type: "tech"
topics: ["claudecode", "windows", "ai", "初心者", "トラブルシューティング"]
published: true
---

## 経緯

Windows環境でClaude Codeを使っていてハマったポイントと解決策をまとめた。
「動かない！」となった時に見返す用。

:::message
**シリーズ構成**
- [非エンジニアがWindowsでClaude Codeを使えるようになるまで](claude-code-windows-install-guide)
- [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips-and-features)
- **Claude Codeが動かない時に見るページ（Windows編）**（この記事）
- [AIにコードを書かせてAIにレビューさせる開発スタイル](claude-code-ai-review-workflow)
:::

---

## 早見表

| 症状 | 原因 | 解決策 |
|------|------|--------|
| `claude` が見つからない | PATH未反映 | PowerShellを再起動。ダメならPATHを手動設定 |
| 文字化け・表示崩れ | エンコーディング | UTF-8設定を追加 |
| MCP接続エラー | npx直叩き | `cmd /c` でラップ |
| GitHub認証エラー | 認証設定 | Personal Access Token で対応 |
| ビルドエラー | コードの問題 | エラーをそのまま Claude Code に渡す |
| 動作が重い | 会話が長すぎ | `/clear` で会話をリセット |
| 変な変更をされた | — | `/rewind` で巻き戻し |

詳細は以下。

---

## 用語説明

このページでは少し難しい用語が出てくるので、先に説明しておく。

| 用語 | 説明 |
|------|------|
| **PATH（パス）** | コマンドを探す場所のリスト。「claudeが見つからない」エラーは、このリストに claude の場所が入っていないのが原因 |
| **環境変数** | パソコン全体で使える設定値。PATHも環境変数の一つ |
| **JSON** | 設定ファイルによく使われる形式。`{ "key": "value" }` のような書き方 |
| **プロファイル** | PowerShell を起動するたびに自動で読み込まれる設定ファイル |

:::message
**難しい作業は Claude Code に頼もう**
このページの手順が難しく感じたら、Claude Code が起動している状態で「PATHを設定して」「文字化けを直して」と頼んでみてください。多くの場合、Claude が自動で解決してくれます。
:::

---

## 「claude が見つからない」と言われる

### 症状

PowerShell で `claude` と入力すると：

```
claude: The term 'claude' is not recognized as a name of a cmdlet, function, script file, or executable program.
```

### 原因

インストール直後は、PATH（コマンドの検索場所）が反映されていない。

### 解決策

#### Step 1: PowerShell を完全に閉じて再起動

「新しいタブを開く」ではダメ。 **ウィンドウごと閉じる**。

それでもダメな場合、PCを再起動。

#### Step 2: それでもダメな場合、PATHを確認

まず、`claude.exe` が存在するか確認：

```powershell
Test-Path "$env:USERPROFILE\.local\bin\claude.exe"
```

`True` と表示されたら、ファイルは存在している。PATHに追加する必要がある。

#### Step 3: PATHを手動で追加（現在のセッションのみ）

```powershell
$env:PATH = "$env:USERPROFILE\.local\bin;$env:PATH"
```

これで `claude --version` が動くか確認。

#### Step 4: PATHを永続化

上記で動いた場合、永続化しておかないとPowerShellを閉じるたびに同じ問題が起きる。

```powershell
[Environment]::SetEnvironmentVariable("PATH", "$env:USERPROFILE\.local\bin;$([Environment]::GetEnvironmentVariable('PATH', 'User'))", "User")
```

PowerShellを再起動して、`claude --version` で確認。

:::message
**実際にハマったポイント**
インストール自体は成功していて `claude.exe` は存在するのに、PATHが自動で設定されないケースがあった。上記の手順で解決。
:::

---

## 文字化け・表示崩れ

### 症状

- 日本語が `?????` や意味不明な文字になる
- 画面のレイアウトが崩れる
- 絵文字が表示されない

### 原因

Windows のデフォルトの文字コードが UTF-8 ではない。

### 解決策

PowerShell の設定を変更する。

#### 手順1：PowerShell のプロファイルを開く

```powershell
notepad $PROFILE
```

「ファイルが存在しません。作成しますか？」と聞かれたら「はい」。

#### 手順2：以下を追記して保存

```powershell
# UTF-8を強制
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
```

#### 手順3：PowerShell を再起動

設定を反映させるため、PowerShell を閉じてもう一度開く。

### 推奨環境

- ターミナル：**Windows Terminal**（Microsoft Store からインストール）
- フォント：**Cascadia Code**（Windows Terminal に標準で入っている）

---

## MCP サーバーが接続エラー

### 症状

MCP（外部ツール連携）を設定したのに動かない。エラーメッセージ：

```
[Warning] mcpServers.github: Windows requires 'cmd /c' wrapper to execute npx
```

### 原因

Windows では `npx` コマンドを直接実行できない場合がある。

### 解決策

設定ファイルで `cmd /c` を追加する。

#### ダメな例

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"]
    }
  }
}
```

#### 正しい例

```json
{
  "mcpServers": {
    "github": {
      "command": "cmd",
      "args": [
        "/c",
        "npx",
        "-y",
        "@modelcontextprotocol/server-github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ここにトークンを入れる"
      }
    }
  }
}
```

**変更ポイント：**
- `"command": "npx"` → `"command": "cmd"`
- `"args"` の先頭に `"/c"` を追加

### 設定ファイルの場所

| 場所 | パス |
|------|------|
| グローバル | `%APPDATA%\Claude\claude_desktop_config.json` |
| プロジェクト | `.mcp.json`（プロジェクトフォルダ直下） |

:::message
**%APPDATA% の開き方**
1. Windows キー + R を押す
2. `%APPDATA%\Claude` と入力して Enter
3. `claude_desktop_config.json` をメモ帳で開く
:::

---

## 「Posix shell environment required」エラー

### 症状

```
Claude CLI requires a Posix shell environment.
Please ensure you have a valid shell installed and the SHELL environment variable set.
```

### 原因

Git for Windows がインストールされていない、またはパスが設定されていない。

### 解決策

#### 方法1：Git for Windows をインストール

[Git for Windows](https://git-scm.com/downloads/win) をダウンロードしてインストール。

#### 方法2：パスを手動で設定

既にインストール済みなのにエラーが出る場合：

```powershell
$env:CLAUDE_CODE_GIT_BASH_PATH = "C:\Program Files\Git\bin\bash.exe"
```

毎回入力するのが面倒なら、PowerShell プロファイルに追記しておく。

---

## 動作が重い・反応が遅い

### 原因

会話（コンテキスト）が長くなりすぎている。

### 解決策

```text
/clear
```

これで会話がリセットされて軽くなる。

全部消したくない場合は：

```text
/compact
```

会話を要約して短くしてくれる。

---

## 変な変更をされた・元に戻したい

### 解決策

```text
/rewind
```

または **Esc キーを2回連打**。

巻き戻しメニューが開くので、戻したいポイントを選ぶ。

選択肢：
- **会話だけ戻す**（コードの変更はそのまま）
- **コードだけ戻す**（会話はそのまま）
- **両方戻す**

---

## ファイルの日本語が文字化けする

### 症状

Claude Code が作成・編集したファイルで、日本語が `???` や変な文字になっている。

### 原因

Claude Code の既知の問題。UTF-8 以外のエンコーディングを正しく扱えない場合がある。

### 回避策

- ファイルは UTF-8 で統一する
- 既存ファイルが UTF-8 以外の場合、事前に変換しておく
- 問題が起きたら手動で修正

---

## GitHub 認証エラー

### 症状

GitHub 操作時に以下のようなエラーが発生：

```
Error: connect ECONNREFUSED 127.0.0.1:xxxx
```

または

```
ERR_CONNECTION_REFUSED
```

### 原因

gh CLI（GitHub CLI）の認証が正しく設定されていない、またはファイアウォールの問題。

### 解決策

#### 方法1：Personal Access Token（PAT）で対応

1. [GitHub の設定ページ](https://github.com/settings/tokens) にアクセス
2. 「Generate new token (classic)」をクリック
3. 必要なスコープ（repo, workflow など）を選択して作成
4. 作成されたトークンをコピー
5. Claude Code 内で使用：

```
> GitHub にプッシュして。認証には Personal Access Token を使って：ghp_xxxx...
```

#### 方法2：gh CLI を再認証

```powershell
gh auth login
```

対話形式で認証を進める。

---

## ビルドエラーが出た時

### 症状

コードを書いてもらった後、ビルド（コンパイル）でエラーが出る。

```
error: 'username' is declared but never used
```

### 解決策

**エラーメッセージをそのまま Claude Code に渡す** のが一番早い。

```
> 以下のエラーが出た。直して：

error: 'username' is declared but never used
  --> src/main.rs:15:9
```

Claude Code がエラーを解析して、自動的に修正してくれる。

:::message
**ポイント**
エラーメッセージをコピペするだけでOK。「○行目のこれを△に変えて」のような細かい指示は不要。むしろ、そのまま渡した方が Claude Code が正しく修正できる。
:::

---

## デバッグ用コマンド

問題の原因を調べたい時に使う。

| コマンド | 説明 |
|----------|------|
| `claude doctor` | 環境チェック |
| `claude --verbose` | 詳細ログを表示して起動 |
| `claude --mcp-debug` | MCP のデバッグ |

---

## それでも解決しない場合

- [Claude Code 公式トラブルシューティング](https://code.claude.com/docs/en/troubleshooting)
- [GitHub Issues（Windows関連）](https://github.com/anthropics/claude-code/issues?q=is%3Aissue+label%3Aplatform%3Awindows)

---

## 関連記事

- [非エンジニアがWindowsでClaude Codeを使えるようになるまで](claude-code-windows-install-guide)
- [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips-and-features)
- [AIにコードを書かせてAIにレビューさせる開発スタイル](claude-code-ai-review-workflow)
