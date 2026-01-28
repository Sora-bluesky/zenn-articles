---
title: "Claude Code インストールガイド（Windows）"
emoji: "🚀"
type: "tech"
topics: ["claudecode", "windows", "ai", "生成ai", "初心者"]
published: true
---

## 経緯

Windows環境でClaude Codeをセットアップした時の手順をまとめた。
非エンジニアの自分でもできたので、同じような人の参考になれば。

:::message
**シリーズ構成**
- **非エンジニアがWindowsでClaude Codeを使えるようになるまで**（この記事）
- [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips-and-features)
- [Claude Codeが動かない時に見るページ（Windows編）](claude-code-windows-troubleshoot)
- [AIにコードを書かせてAIにレビューさせる開発スタイル](claude-code-ai-review-workflow)
- [Claude（Web版）の知識をClaude Codeに引っ越す方法](claude-code-migration-guide)
:::

---

## Claude Codeとは

Claude Code は、ターミナル（黒い画面）で動くAIコーディングアシスタント。
チャットで指示を出すと、ファイルの作成・編集・実行などを自動でやってくれる。

---

## 動作環境

公式の動作要件（2026年1月時点）：

- Windows 10 以降
- メモリ 4GB 以上
- インターネット接続

---

## 事前準備：Git for Windows のインストール

Claude Code を Windows で使うには、**Git for Windows** が必要。

### 手順

1. [Git for Windows ダウンロードページ](https://git-scm.com/downloads/win) にアクセス
2. 「**Click here to download**」をクリック
3. ダウンロードしたファイル（`Git-〇〇-64-bit.exe`）をダブルクリック
4. インストーラーが起動したら、 **すべて「Next」を押し続けて** 最後に「Install」
5. 完了したら「Finish」

:::message
インストール中の選択肢は、デフォルトのままで大丈夫。
:::

---

## インストール手順

### ステップ1：PowerShell を開く

1. キーボードの **Windows キー** を押す（または画面左下のスタートボタンをクリック）
2. 「**powershell**」と入力
3. 「**Windows PowerShell**」が表示されたら、 **右クリック** → 「**管理者として実行**」を選択
4. 「このアプリがデバイスに変更を加えることを許可しますか？」と聞かれたら「**はい**」

:::message
管理者として実行しなくても動く場合もあるが、うまくいかない時は管理者で試す。
:::

### ステップ2：インストールコマンドを実行

PowerShell の画面が開いたら、以下のコマンドをコピーして貼り付け、Enter キーを押す。

```powershell
irm https://claude.ai/install.ps1 | iex
```

:::message
**コマンドの意味**
- `irm`：Invoke-RestMethod の略。インターネットからファイルをダウンロードする
- `iex`：Invoke-Expression の略。ダウンロードしたファイルを実行する
- `|`（パイプ）：左のコマンドの結果を右のコマンドに渡す

つまり「インストール用のファイルをダウンロードして、そのまま実行する」という意味。
:::

:::message alert
**コピー＆ペーストの方法**
1. 上のコマンドを選択してコピー（Ctrl + C）
2. PowerShell の画面上で貼り付け：
   - **右クリック**（これで貼り付けられる）
   - または **Ctrl + V**（警告が出る場合があるが問題なし）
3. Enter キーを押す
:::

インストールが始まる。完了まで数分待つ。

### ステップ3：PowerShell を再起動

インストールが完了したら、 **PowerShell を一度閉じて、もう一度開く**。

これをやらないと、`claude` コマンドが使えない。

:::message alert
**重要：タブではなくウィンドウごと閉じる**
新しいタブを開くのではダメ。ウィンドウ自体を×ボタンで閉じて、もう一度開く。
:::

:::message
**それでも「claudeが見つからない」と言われる場合**
PATHが正しく設定されていない可能性がある。詳細な解決手順は Part 3（トラブルシューティング編）を参照。
:::

### ステップ4：インストール確認

新しく開いた PowerShell で、以下を入力して Enter：

```powershell
claude --version
```

バージョン番号（例：`2.1.12`）が表示されたら成功。

---

## 認証（アカウント連携）

### ステップ1：プロジェクトフォルダに移動

作業したいフォルダに移動する。例えば、デスクトップに `my-project` というフォルダを作って移動する場合：

```powershell
cd ~/Desktop/my-project
```

:::message
**コマンドの意味**
- `cd`：「change directory」の略。フォルダを移動するコマンド
- `~`（チルダ）：自分のユーザーフォルダを表す記号。`C:\Users\あなたの名前` と同じ意味

つまり「デスクトップの my-project フォルダに移動する」という意味。
:::

### ステップ2：Claude Code を起動

```powershell
claude
```

### ステップ3：初回起動時の設定画面

初回起動時はいくつかの設定画面が順番に表示される。↑↓キーで移動、Enter で決定。

---

**1. テーマ（テキストスタイル）の選択**

```
Let's get started.

Choose the text style that looks best with your terminal
To change this later, run /theme

> 1. Dark mode ✓
  2. Light mode
  3. Dark mode (colorblind-friendly)
  4. Light mode (colorblind-friendly)
  5. Dark mode (ANSI colors only)
  6. Light mode (ANSI colors only)
```

好みのテーマを選択。迷ったら **1. Dark mode** でOK。

画面下部にコードの差分サンプル（赤と緑の行）が表示され、見やすさを確認できる。

---

**2. ログイン方法の選択**

```
Claude Code can be used with your Claude subscription or billed based on
API usage through your Console account.

Select login method:

> 1. Claude account with subscription · Pro, Max, Team, or Enterprise
  2. Anthropic Console account · API usage billing
  3. 3rd-party platform · Amazon Bedrock, Microsoft Foundry, or Vertex AI
```

**「1. Claude account with subscription」を選択**して Enter。

:::message
**どれを選ぶ？**
| オプション | 説明 |
|------------|------|
| **Claude account with subscription** | Claude Pro / Max を契約している人向け。**おすすめ** |
| **Anthropic Console account** | API 従量課金（使った分だけ支払い） |
| **3rd-party platform** | Amazon Bedrock / Vertex AI など企業向け |

よく分からなければ **1** を選んで、Claude Pro（月額$20）または Max（月額$100〜）に加入するのが簡単。
:::

---

**3. ブラウザでログイン**

ブラウザが自動的に開き、Claude のログイン画面が表示される。

- **Googleアカウント** でログインしている場合 → 「Continue with Google」
- **メールアドレス** で登録している場合 → 「Continue with email」

ログインが完了すると、ブラウザに以下のメッセージが表示される：

```
Build something great

You're all set up for Claude Code.
You can now close this window.
```

ブラウザを閉じて、PowerShell に戻る。

---

**4. ログイン成功確認**

```
Logged in as your-email@example.com
Login successful. Press Enter to continue...
```

**Enter キーを押す**。

---

**5. Security notes（セキュリティに関する注意）**

```
Security notes:

  Claude can make mistakes
  You should always review Claude's responses, especially when
  running code.

  Due to prompt injection risks, only use it with code you trust
  For more details see:
  https://code.claude.com/docs/en/security

Press Enter to continue...
```

内容を確認して **Enter キーを押す**。

:::message
**セキュリティ注意事項の要約**
- Claude は間違えることがある → 特にコード実行時は結果を確認する
- プロンプトインジェクションのリスクがある → 信頼できるコードのみ使用する
:::

---

**6. フォルダの信頼確認**

```
Do you trust the files in this folder?

C:\Users\YourName\Documents\Projects

Claude Code may read, write, or execute files contained in this directory.
This can pose security risks, so only use files from trusted sources.

Learn more

> 1. Yes, proceed
  2. No, exit

Enter to confirm · Esc to cancel
```

自分で作成したフォルダや、信頼できるプロジェクトであれば **「1. Yes, proceed」を選択**。

:::message alert
**注意**：ダウンロードした怪しいプロジェクトや、他人から受け取ったコードの場合は注意。Claude Code はファイルの読み書き・実行ができるため、悪意のあるコードが含まれていると危険。
:::

---

### ステップ4：起動完了

以下のような画面が表示されたら成功：

```
╭─ Claude Code v2.1.19 ─────────────────────────────────────────────────╮
│                                                                       │
│   Welcome back YourName!            Tips for getting started          │
│                                     Run /init to create a CLAUDE.md   │
│        🦙                           file with instructions...         │
│                                                                       │
│   Opus 4.5 · Claude Max · YourName  Recent activity                   │
│   ~\Documents\Projects              No recent activity                │
│                                                                       │
╰───────────────────────────────────────────────────────────────────────╯

> Try "refactor <filepath>"

? for shortcuts                    ✓ Anthropic marketplace installed
```

`>` のプロンプトが表示されたら、Claude Code が使える状態。

---

## 動作確認

試しに何か入力してみる：

```
> hello.txt に「Hello, Claude Code!」と書いて
```

Claude が応答し、フォルダ内に `hello.txt` が作成されれば成功。

終了するときは `/exit` と入力（または `Ctrl + C`）。

---

## 日本語で応答させる設定

Claude Code はデフォルトでは英語で応答することがある。日本語で応答させるには設定が必要。

### 設定方法

Claude Code を起動した状態で、以下のように入力する：

```
> settings.json を作成して、languageをjapaneseに設定して
```

Claude が自動的に `~/.claude/settings.json` を作成してくれる。

これで次回以降、日本語で応答するようになる。

:::message
**補足**
他にも `CLAUDE.md` ファイルや `/init` コマンドを使う方法もある。詳しくは [公式ドキュメント](https://code.claude.com/docs/ja/memory) を参照。
:::

---

## うまくいかない場合

詳細は Part 3（トラブルシューティング編）を参照。

### よくある問題

| 症状 | 対策 |
|------|------|
| `claude` が見つからない | PowerShellをウィンドウごと閉じて開き直す。それでもダメならPATHを手動設定（Part 3参照） |
| 「Posix shell environment required」 | Git for Windows をインストールする |

---

## アップデート

Claude Code は自動でアップデートされる。

手動でアップデートしたい場合：

```powershell
claude update
```

---

## アンインストール

Claude Code を削除したい場合、2つの方法がある。

### 方法1：Claude Code に頼む（おすすめ）

Claude Code が起動している状態で：

```
> 自分自身をアンインストールして
```

Claude が自動的に削除コマンドを実行してくれる。

### 方法2：手動でコマンドを実行

PowerShell で以下を実行：

```powershell
Remove-Item -Path "$env:USERPROFILE\.local\bin\claude.exe" -Force
Remove-Item -Path "$env:USERPROFILE\.local\share\claude" -Recurse -Force
```

設定ファイルも消したい場合は以下も実行：

```powershell
Remove-Item -Path "$env:USERPROFILE\.claude" -Recurse -Force
Remove-Item -Path "$env:USERPROFILE\.claude.json" -Force
```

:::message
**コマンドの意味**
- `Remove-Item`：ファイルやフォルダを削除するコマンド
- `$env:USERPROFILE`：自分のユーザーフォルダ（`C:\Users\あなたの名前`）
- `-Force`：確認なしで削除
- `-Recurse`：フォルダの中身も全て削除
:::

---

## 用語集

| 用語 | 説明 |
|------|------|
| **PowerShell** | Windows に標準で入っているコマンド入力ツール |
| **Bash** | Linux や Mac で使われるコマンド入力ツール。Claude Code 内部はこれで動いている |
| **ターミナル** | コマンドを入力する画面の総称 |
| **CLI** | Command Line Interface の略。キーボードで操作するツール |
| **パス** | ファイルやフォルダの場所。例：`C:\Users\YourName\Desktop` |

---

## 参考

- [Claude Code 公式セットアップガイド](https://code.claude.com/docs/en/setup)
- [Git for Windows](https://git-scm.com/downloads/win)

---

## 次のステップ

- [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips-and-features)
- [Claude Codeが動かない時に見るページ（Windows編）](claude-code-windows-troubleshoot)
- [AIにコードを書かせてAIにレビューさせる開発スタイル](claude-code-ai-review-workflow)
