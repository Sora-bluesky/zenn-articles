---
title: "Claude（Web版）で積み上げた知識、Claude Codeに引っ越せます"
emoji: "📦"
type: "tech"
topics: ["claudecode", "ai", "生成ai", "llm", "個人開発"]
published: true
---

:::message
**シリーズ構成**
- [非エンジニアがWindowsでClaude Codeを使えるようになるまで](claude-code-windows-install-guide)
- [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips-and-features)
- [Claude Codeが動かない時に見るページ（Windows編）](claude-code-windows-troubleshoot)
- [AIにコードを書かせてAIにレビューさせる開発スタイル](claude-code-ai-review-workflow)
- **Claude（Web版）の知識をClaude Codeに引っ越す方法**（この記事）
:::

## 半信半疑だった過去の自分へ

正直に言います。最初は「Claude Code？ターミナルで動くAI？エンジニアじゃないと無理でしょ」と思っていました。

私の「できなさ」を具体的に挙げると：

1. **ターミナルが怖い** — 黒い画面に白い文字、何をやっているか分からない
2. **設定ファイルが意味不明** — YAML？JSON？フロントマター？呪文にしか見えない
3. **公式ドキュメントが難しい** — 日本語に切り替えられるけど、内容が専門的すぎる。そもそもマニュアル読むの嫌い

そんな私が、Web版Claude.aiで3ヶ月かけて育てた「プロジェクトの知識」をCLI版に完全移行できました。この記事は、その方法を共有するものです。

---

## まずは完成品を見てください

**移行前：** Web版Claude.aiに散らばる複数のチャット。毎回「前に決めたルール覚えてる？」と聞く日々。

**移行後：** Claude Codeを起動した瞬間から、プロジェクトのルール・好み・定型作業をすべて把握した状態でスタート。

:::message
**完成した設定ファイル構成**
```
my-project/
├── CLAUDE.md                    # プロジェクトの脳（自動で読み込まれる）
├── .claude/
│   ├── skills/
│   │   └── generate-report/
│   │       └── SKILL.md         # 定型作業の手順書
│   ├── agents/
│   │   └── test-runner.md       # 専門エージェント
│   └── rules/
│       └── api-standards.md     # APIファイル専用ルール
└── ~/.claude/
    └── CLAUDE.md                # 個人の好み（全プロジェクト共通）
```
:::

**これで何ができるか：**

- ✅ 毎回「日本語で答えて」「このプロジェクトはReactで...」と説明する必要がなくなる
- ✅ 「レポート作って」だけで、決まった形式のレポートが出てくる
- ✅ ファイルの種類に応じて、自動でルールが切り替わる
- ✅ チャット履歴が消えても、知識は残る
- ✅ チームメンバーと設定を共有できる（Gitにコミット可能）

---

## なぜ作ったか — Web版への不満

Web版Claude.aiは素晴らしいツールです。でも、長期プロジェクトで使い込むほど、こんな不満が溜まっていきました。

### 不満1：知識が分散する

「この設計方針、前に決めたよね？」
「あのコーディング規約、どのチャットで決めたっけ？」

複数のチャットに知識が散らばり、毎回探すのが大変でした。

### 不満2：毎回説明し直す

新しいチャットを始めるたびに：
- 「このプロジェクトは〇〇で...」
- 「私の好みは〇〇で...」
- 「前回はここまで進んで...」

同じ説明を何度もするのは、正直しんどかった。

### 不満3：定型作業を毎回依頼

「週次レポート作って」と頼むたびに、フォーマットを説明し直す。何度も同じ手順を伝える無駄。

---

### 「ないなら作ろう」に至った経緯

Claude Codeの存在は知っていました。でも「CLIツールはエンジニア向け」と決めつけて、手を出していませんでした。

転機は、公式ドキュメントでこの一文を見つけたとき：

> *"All memory files are automatically loaded into Claude Code's context when launched."*
> （すべてのメモリファイルは、Claude Code起動時に自動でコンテキストに読み込まれます）
> — [Manage Claude's memory](https://docs.anthropic.com/en/docs/claude-code/memory)

「起動時に自動で読み込んでくれるファイルがある？」

それなら、Web版で積み上げた知識をそのファイルに書き出せば、**引っ越し**できるのでは？

試してみたら、できました。

---

## どうやって作ったか — 専門用語なしで解説

### CLAUDE.mdって何？（例え話）

**CLAUDE.mdは「新入社員に渡すオンボーディング資料」** です。

新入社員（Claude）が入社初日に読む資料。そこには：
- 会社（プロジェクト）の概要
- 守るべきルール
- よく使うコマンド

これを読めば、初日から「このプロジェクトの人」として働ける。CLAUDE.mdはそういうファイルです。

> *"Claude Code offers four memory locations in a hierarchical structure, each serving a different purpose."*
> （Claude Codeは階層構造の4つのメモリ格納場所を提供し、それぞれ異なる目的を持ちます）
> — [Manage Claude's memory](https://docs.anthropic.com/en/docs/claude-code/memory)

### Skillsって何？（例え話）

**Skillsは「業務マニュアル」** です。

「週次レポートの作り方」「テストの実行手順」など、定型業務のマニュアル。必要なときだけ取り出して参照する。

CLAUDE.mdが「常に頭に入れておく基本情報」なら、Skillsは「必要なときに見るマニュアル棚」。

> *"Skills extend what Claude can do. Create a SKILL.md file with instructions, and Claude adds it to its toolkit. Claude uses skills when relevant, or you can invoke one directly with /skill-name."*
> （SkillsはClaudeができることを拡張します。SKILL.mdファイルに手順を書くと、Claudeはそれをツールキットに追加します。Claudeは関連するときに自動で使うか、/skill-nameで直接呼び出せます）
> — [Extend Claude with skills](https://docs.anthropic.com/en/docs/claude-code/slash-commands)

### わからないことの聞き方

移行作業中、何度もClaudeに助けを求めました。聞き方のコツは：

```
❌ 悪い例：「YAMLの書き方教えて」

✅ 良い例：「このファイルを作りたい。エラーが出た。
           エラーメッセージはこれ。何が間違ってる？」
```

**具体的な状況 + 実際のエラー** を見せると、的確な答えが返ってきます。

---

## 移行手順 — 5ステップで完了

### 移行の全体像

![移行の全体像](/images/migration-overview.png)

**ポイント：チャット内で「履歴を分析して」と頼む方法は使いません。**

なぜなら：
- 長い会話だとコンテキストリミット（AIが一度に処理できる文章量の上限）に引っかかる
- 複数チャットに分散した知識を一度に扱えない
- Claudeの「記憶」に依存するため、漏れが出る

代わりに、**履歴エクスポート機能**を使います。これなら：
- 完全な履歴がファイルとして手元にある
- 単一チャットでも複数チャットでも同じ手順
- Claude Codeがファイルを検索・分析できる

---

### ステップ1：チャット履歴をエクスポート

> *"Individual Claude users can export user information and chat history from Settings > Privacy on the web app or Claude Desktop."*
> （個人のClaudeユーザーは、WebアプリまたはClaude Desktopの「設定 > プライバシー」からユーザー情報とチャット履歴をエクスポートできます）
> — [How can I export my Claude data?](https://support.anthropic.com/en/articles/9450526-how-can-i-export-my-claude-ai-data)

**手順：**

1. [claude.ai](https://claude.ai) にログイン
2. **左下**のイニシャル（アカウントアイコン）をクリック
3. メニューから **「Settings」** を選択
4. **「Privacy」** セクションに移動
5. エクスポート対象を選択：
   - **Conversations**（会話）← 今回はこれが必要
   - **Users**（ユーザー情報）
   - **Projects**（プロジェクト）
6. **「Export data」** ボタンをクリック
7. メールでダウンロードリンクが届く（24時間で期限切れ）
8. ZIPを解凍すると以下のファイルが入っている：
   - `conversations.json` ← **移行に使用**
   - `memories.json`
   - `projects.json`
   - `users.json`

:::message alert
**注意点（公式より）：**
- エクスポートの生成には少し時間がかかる場合がある
- ダウンロードリンクは **24時間で期限切れ**
- ダウンロードにはログインが必要
- **iOS/Androidアプリからはエクスポート不可**（Web版またはDesktop版のみ）
:::

---

### ステップ2：Claude Codeをインストール

> *"Install, authenticate, and start using Claude Code on your development machine."*
> （開発マシンにClaude Codeをインストール、認証、使用開始します）
> — [Set up Claude Code](https://docs.anthropic.com/en/docs/claude-code/setup)

**対応OS：**
- macOS 13.0以上
- Ubuntu 20.04以上 / Debian 10以上
- Windows 10以上（WSL 1、WSL 2、または Git for Windows）

**インストール：**

以下はインストール用のコマンドです。意味がわからなくても大丈夫です — コピーして貼り付けるだけで動きます。

```bash
# Windows (PowerShell)
irm https://claude.ai/install.ps1 | iex
```

:::message
**Windows環境でのインストールに不安がある方へ**

詳細な手順は以下の日本語ガイドを参照してください：
[Claude CodeをWindowsにインストールする完全ガイド](claude-code-windows-install-guide)
:::

:::details macOS / Linuxの場合
```bash
curl -fsSL https://claude.ai/install.sh | sh
```
:::

**認証オプション（公式より）：**

**既にClaude Pro（月$20）またはMaxを契約していれば、追加料金なしでClaude Codeも使えます。**

> *"Claude Pro or Max plan (recommended): Subscribe to Claude's Pro or Max plan for a unified subscription that includes both Claude Code and Claude on the web."*
> （Claude ProまたはMaxプラン（推奨）：Claude CodeとWeb版Claudeの両方を含む統合サブスクリプション）
> — [Set up Claude Code](https://docs.anthropic.com/en/docs/claude-code/setup)

| プラン | Claude Code | Web版Claude | 月額 |
|--------|-------------|-------------|------|
| Pro | ✅ | ✅ | $20 |
| Max | ✅ | ✅ | $100〜 |

**認証方法：**

```bash
# 起動して認証
claude

# ブラウザが開いて認証画面へ
# Anthropicアカウントでログイン
```

---

### ステップ3：JSONファイルを配置

エクスポートしたZIPファイルを解凍し、JSONファイルを**プロジェクトディレクトリ**（あなたが作業しているプロジェクトのフォルダ）に配置します。

```bash
# 例：プロジェクトディレクトリに移動（cd = フォルダを移動するコマンド）
cd ~/my-project

# ZIPを解凍（4つのJSONファイルが出てくる）
unzip ~/Downloads/claude-export-XXXXXXXX.zip
```

:::message
**Windowsの場合**、エクスプローラーでZIPファイルを右クリック →「すべて展開」でも解凍できます。展開したファイルをプロジェクトフォルダにコピーしてください。
:::

**配置後の構成：**

```
my-project/
├── conversations.json   ← エクスポートされた会話履歴
├── memories.json        ← エクスポートされた記憶
├── projects.json        ← エクスポートされたプロジェクト情報
├── users.json           ← エクスポートされたユーザー情報
└── （既存のプロジェクトファイル）
```

:::message alert
**⚠️ 重要：配置場所に注意**

| 配置場所 | 結果 |
|----------|------|
| ✅ プロジェクトディレクトリ | 正しい。Claude Codeがファイルを読める |
| ❌ `~/.claude/` | 間違い。グローバル設定フォルダなのでJSONを置かない |
| ❌ ダウンロードフォルダのまま | Claude Codeがアクセスできない |

**`~/.claude/` はCLAUDE.mdやsettings.jsonなどの設定ファイル専用です。** 作業用のJSONファイルは置かないでください。
:::

---

### ステップ4：設定ファイルを生成

```bash
# プロジェクトディレクトリに移動（my-project はあなたのフォルダ名に置き換えてください）
cd my-project

# Claude Codeを起動
claude
```

:::message alert
**`my-project` は例です。** あなたのプロジェクトフォルダの名前に置き換えてください。
たとえば `cd todo-app` や `cd C:\Users\自分の名前\Documents\my-app` など。
「my-project」というフォルダが存在しないとエラーになります。
:::

**Claude Code起動後、`Shift + Tab` を2回押して Plan Mode に切り替えてから、以下を伝えます：**

:::message
**Plan Mode（計画モード）とは？**
Claudeにファイルを変更させず、計画だけを提示させる安全なモードです。計画を確認してから実行に移れるので、安心して使えます。
:::

````markdown
# 入力ファイル
以下のJSONファイルを読み込んでください：
- conversations.json（会話履歴）← メインで使用
- memories.json（記憶）
- projects.json（プロジェクト情報）
- users.json（ユーザー情報）

# 目的
このファイルから「プロジェクト〇〇」に関する知識を抽出し、
Claude Code用の設定ファイルに変換します。

# 現状と変更後の構成を提示してください

【1. 現状の構成】
まず以下を確認して表示してください：
- このディレクトリの現在の構成（既存のCLAUDE.md、.claude/があるか）
- ~/.claude/CLAUDE.md の有無と内容（あれば）

【2. JSONの分析結果】
次にJSONを分析し、以下の4カテゴリに分類して表示してください：

| カテゴリ | 配置先 | 内容 |
|---------|--------|------|
| A. このプロジェクト固有 | ./CLAUDE.md | 技術スタック、規約、コマンド |
| B. 除外候補 | （作成しない） | 別プロジェクトの情報 |
| C. 全プロジェクト共通 | ~/.claude/CLAUDE.md | 言語、スタイルのみ |
| D. 定型作業 | .claude/skills/ | 繰り返し手順 |

⚠️ カテゴリCには技術スタックやコーディング規約を含めないでください

【3. 変更後の構成】
実行後にどのような構成になるかを表示してください。

【4. 私の承認を待つ】
上記を表示したら、「実行してよいですか？」と確認してください。
私が「OK」「はい」「実行して」と言ったら：
1. Plan Modeを終了して実行
2. ファイル作成後、結果を表示
3. 確認後、JSONファイルを削除
````

**これだけです。** Plan Modeで計画を確認し、承認したら実行されます。

> *"Plan Mode instructs Claude to create a plan by analyzing the codebase with read-only operations, perfect for exploring codebases, planning complex changes, or reviewing code safely."*
> （Plan Modeは読み取り専用の操作でコードベースを分析し、計画を作成するようClaudeに指示します。コードベースの探索、複雑な変更の計画、安全なコードレビューに最適です）
> — [Common workflows](https://docs.anthropic.com/en/docs/claude-code/tutorials)

:::details 実行例：Claude Codeの応答（クリックで展開）

**① 対象プロジェクトの確認**

上記の指示を送ると、Claude Codeはまず対象プロジェクトを確認してきます。

```
☐ 対象プロジェクト
  現在のディレクトリ「my-project」は、どのプロジェクトに対応していますか？
  ./CLAUDE.md に書くプロジェクト固有の情報を決めるために必要です。

❯ 1. タスク管理アプリ
     React + TypeScript + Firebase の TODO アプリ
  2. 汎用ワークスペース
     特定プロジェクトではなく、全プロジェクト共通のワークスペースとして使う
  3. ブログサイト
     Next.js + MDX の技術ブログ
  4. 入力して指定する
```

**なぜ聞かれるのか：** JSONファイルには複数のプロジェクトに関する会話履歴が含まれている可能性があります。どのプロジェクトの情報を書くべきか確認しています。

**どれを選ぶべきか：**
- 特定プロジェクト専用のディレクトリ → そのプロジェクトを選択
- 複数プロジェクトを扱う作業場所 → 「2. 汎用ワークスペース」を選択

---

**② 分析結果の提示**

プロジェクトを選択すると、詳細な分析結果が提示されます。

```
● プランが完成しました。以下が分析結果のサマリーです。

1. 現状の構成
   - CLAUDE.md → なし
   - ~/.claude/CLAUDE.md → なし
   - .claude/ → settings.local.json のみ

2. JSON分析結果（4カテゴリ分類）
┌──────────────────────┬─────────────────────┬────────────────────────────────┐
│ カテゴリ             │ 配置先              │ 内容                           │
├──────────────────────┼─────────────────────┼────────────────────────────────┤
│ A. ワークスペース固有│ ./CLAUDE.md         │ 主要プロジェクト一覧、         │
│                      │                     │ 技術スタック、開発アプローチ   │
├──────────────────────┼─────────────────────┼────────────────────────────────┤
│ B. 除外              │ （作成しない）      │ 5件（画像生成プロンプト等の    │
│                      │                     │ Claude.ai専用プロジェクト）    │
├──────────────────────┼─────────────────────┼────────────────────────────────┤
│ C. 全プロジェクト共通│ ~/.claude/CLAUDE.md │ 日本語、SVG/ドキュメント/      │
│                      │                     │ コンテンツ作成ルール           │
├──────────────────────┼─────────────────────┼────────────────────────────────┤
│ D. 定型作業          │ .claude/skills/     │ 3スキル（週次レポート、        │
│                      │                     │ コードレビュー、引き継ぎ資料） │
└──────────────────────┴─────────────────────┴────────────────────────────────┘

3. 変更後の構成
   - 新規作成: 5ファイル
   - 削除予定: 4ファイル（JSON、承認後に削除）
```

**ポイント：**
- **カテゴリB（除外）** が自動で判定されている → 別プロジェクトの情報が混入しない
- **カテゴリC（全プロジェクト共通）** に技術スタックが含まれていない → 正しく分類されている

---

**③ 実行の承認**

```
Would you like to proceed?
❯ 1. Yes, clear context and auto-accept edits (shift+tab)
  2. Yes, auto-accept edits
  3. Yes, manually approve edits
  4. Type here to tell Claude what to change
```

**どれを選ぶべきか：**
- **1. Yes, clear context...** → コンテキストがクリアされる（今回は不要）
- **2. Yes, auto-accept edits** → ✅ **これを選択**（計画確認済みなので自動承認でOK）
- **3. Yes, manually approve edits** → ファイルごとに承認（慎重に進めたい場合）
- **4. Type here...** → 計画を修正したい場合

---

**④ 実行完了**

```
● 全ファイルが正常に作成されました。

変更後のディレクトリ構成

my-project/
├── CLAUDE.md                                    ← 新規作成 (2.9KB)
├── .claude/
│   ├── settings.local.json                      ← 既存（変更なし）
│   └── skills/
│       ├── weekly-report/
│       │   └── SKILL.md                         ← 新規作成
│       ├── code-review/
│       │   └── SKILL.md                         ← 新規作成
│       └── handoff-notes/
│           └── SKILL.md                         ← 新規作成

~/.claude/
├── CLAUDE.md                                    ← 新規作成 (1.2KB)
└── （その他既存ファイルは変更なし）

各ファイルのサマリー
┌─────────────────────────────┬────────┬─────────────────────────────────────┐
│ ファイル                    │ サイズ │ 内容                                │
├─────────────────────────────┼────────┼─────────────────────────────────────┤
│ ~/.claude/CLAUDE.md         │ 1.2KB  │ 言語（日本語）、SVG/ドキュメント    │
│                             │        │ 作成ルール                          │
├─────────────────────────────┼────────┼─────────────────────────────────────┤
│ ./CLAUDE.md                 │ 2.9KB  │ ユーザー情報、主要プロジェクト一覧、│
│                             │        │ 技術スタック、開発アプローチ        │
├─────────────────────────────┼────────┼─────────────────────────────────────┤
│ weekly-report/SKILL.md      │ 3.8KB  │ 週次レポート作成ワークフロー        │
├─────────────────────────────┼────────┼─────────────────────────────────────┤
│ code-review/SKILL.md        │ 2.2KB  │ コードレビューワークフロー          │
├─────────────────────────────┼────────┼─────────────────────────────────────┤
│ handoff-notes/SKILL.md      │ 2.5KB  │ セッション引き継ぎ資料テンプレート  │
└─────────────────────────────┴────────┴─────────────────────────────────────┘
```

最後にJSONファイルを削除するか確認されます。心配なら残しておきましょう。

```
● 全タスク完了です。

作成したファイル（5件）:
1. ~/.claude/CLAUDE.md - 全プロジェクト共通の言語・スタイル指示
2. ./CLAUDE.md - 汎用ワークスペースのプロジェクト一覧・開発パターン
3. .claude/skills/weekly-report/SKILL.md - 週次レポート作成ワークフロー
4. .claude/skills/code-review/SKILL.md - コードレビューワークフロー
5. .claude/skills/handoff-notes/SKILL.md - セッション引き継ぎ資料テンプレート

新しいターミナルで claude を起動すると、これらの設定が自動的に読み込まれます。
```

**これで移行完了です！**
:::

---

#### ファイル配置と影響範囲

| ファイル | 影響範囲 | 用途 |
|---------|---------|------|
| ./CLAUDE.md | このプロジェクトのみ | プロジェクト固有の設定 |
| ~/.claude/CLAUDE.md | **全プロジェクト** | プロジェクトに依存しない個人の好み |
| .claude/skills/ | このプロジェクトのみ | 定型作業 |
| CLAUDE.local.md | このプロジェクトのみ（Git共有されない） | 個人用のプロジェクト設定 |

> *"CLAUDE.local.md files are automatically added to .gitignore, making them ideal for private project-specific preferences that shouldn't be checked into version control."*
> （CLAUDE.local.mdファイルは自動的に.gitignoreに追加されるため、バージョン管理にチェックインすべきでないプライベートなプロジェクト固有の設定に最適です）
> — [Manage Claude's memory](https://docs.anthropic.com/en/docs/claude-code/memory)

:::message alert
**⚠️ ~/.claude/CLAUDE.md はグローバル設定です**

プロジェクト固有の内容（技術スタック、コーディング規約など）をここに書くと、**他のすべてのプロジェクトにも影響**します。

```markdown
# ❌ 間違い：~/.claude/CLAUDE.md に書いてはいけない内容
- インデントは2スペース（← プロジェクトによって異なる）
- Reactを使用（← このプロジェクトだけの話）

# ⭕ 正しい：~/.claude/CLAUDE.md に書くべき内容
- 日本語で回答する
- 回答は簡潔に
```
:::

:::message
**作成後の確認方法**

設定が正しく読み込まれているか、以下のコマンドで確認できます：

```bash
/memory   # 読み込まれているメモリファイルを確認
/skills   # 使用可能なスキルを確認
/context  # コンテキスト使用量を確認
```

> *"You can see what memory files are loaded by running /memory command."*
> （/memoryコマンドを実行すると、どのメモリファイルが読み込まれているか確認できます）
> — [Manage Claude's memory](https://docs.anthropic.com/en/docs/claude-code/memory)
:::

:::message
**今後の更新・メンテナンス方法**

設定を変更したい場合は、以下の方法があります：

1. **`/memory` コマンド**：エディタで直接編集できます
2. **ファイルを直接編集**：変更は次回起動時に反映されます
3. **Claude Codeに依頼**：「CLAUDE.mdに〇〇を追加して」

> *"Use the /memory command during a session to open any memory file in your system editor for more extensive additions or organization."*
> （セッション中に/memoryコマンドを使用して、システムエディタでメモリファイルを開き、より広範な追加や整理を行えます）
> — [Manage Claude's memory](https://docs.anthropic.com/en/docs/claude-code/memory)
:::

:::message
**ファイルの実際の保存場所（OS別）**

`~` はホームディレクトリを意味します。OSによって実際のパスが異なります：

| OS | ~/.claude/CLAUDE.md の実際のパス |
|----|----------------------------------|
| macOS | `/Users/あなたのユーザー名/.claude/CLAUDE.md` |
| Linux | `/home/あなたのユーザー名/.claude/CLAUDE.md` |
| Windows (WSL) | `\\wsl$\Ubuntu\home\あなたのユーザー名\.claude\CLAUDE.md` |
| Windows (Git Bash) | `C:\Users\あなたのユーザー名\.claude\CLAUDE.md` |
:::

---

### ステップ5：Claude Codeで知識を継続的に蓄積する

移行が完了したら、**今後はclaude.aiを使わずにClaude Codeで完結**できます。

#### 相談・計画はPlan Modeで

今までclaude.aiで行っていた「どうやって実装しよう？」という相談も、Claude Codeでできます。

```bash
# Plan Modeで起動
claude --permission-mode plan
```

または起動後に `Shift + Tab` を2回押して切り替え。

> *"Plan Mode instructs Claude to create a plan by analyzing the codebase with read-only operations, perfect for exploring codebases, planning complex changes, or reviewing code safely."*
> （Plan Modeは読み取り専用の操作でコードベースを分析し、計画を作成するようClaudeに指示します。コードベースの探索、複雑な変更の計画、安全なコードレビューに最適です）
> — [Common workflows](https://docs.anthropic.com/en/docs/claude-code/common-workflows)

**使い方の例：**

```
認証機能を追加したい。
どういう設計にすべきか、計画を立ててください。
```

Claudeがコードベースを分析し、計画を提示します。
計画を確認・修正してから、通常モードで実行できます。

#### 学びの記録は「Claudeに編集させる」

公式は「Claudeに直接CLAUDE.mdを編集させる」方式を推奨しています。

> *"Removed # shortcut for quick memory entry (tell Claude to edit your CLAUDE.md instead)"*
> （クイックメモリー入力の#ショートカットを廃止。代わりにClaudeにCLAUDE.mdを編集させてください）
> — [Claude Code Changelog](https://docs.anthropic.com/en/release-notes/claude-code)

**セッション終了前に、以下のように依頼するだけです：**

```
今日のセッションで得た学びをCLAUDE.mdに追加してください。

追加すべき内容：
- 新しく決まったルールや規約
- 今後も使いたいパターンやコマンド
- プロジェクト固有の知識
- 遭遇したエラーと解決策（繰り返し起きそうなもの）

追加前に内容を見せてください。
```

これにより、claude.aiで行っていた知識の蓄積を、Claude Code内で継続できます。

:::details 半自動化したい場合：`/learn` Skillを作成（クリックで展開）

毎回同じ依頼をするのが面倒なら、Skillにしましょう。

`~/.claude/skills/learn/SKILL.md`:

```markdown
---
name: learn
description: セッションから学びを抽出し、CLAUDE.mdに追記する
---

# 学びの記録

現在のセッションを振り返り、以下を抽出してください：

**抽出対象**
- 新しく決まったルール・規約
- 繰り返し使われたパターン
- プロジェクト固有の知識
- ユーザーの好み（回答スタイルなど）

**分類と配置先**
| 内容 | 配置先 |
|------|--------|
| このプロジェクト固有 | ./CLAUDE.md |
| 全プロジェクト共通 | ~/.claude/CLAUDE.md |
| 定型作業 | .claude/skills/ に新規Skill |

**処理**
1. 抽出結果をリストで提示（まだ編集しない）
2. 私が「OK」と言ったら、該当ファイルに追記
3. 既存の内容と重複しないようにする
```

**使い方：**

```
/learn
```

これで、学びの記録が半自動化されます。
:::

#### claude.aiとClaude Codeの使い分け

移行後は、以下のように使い分けられます：

| 用途 | 推奨 |
|------|------|
| コードを書く・修正する | Claude Code |
| 設計を相談する | Claude Code（Plan Mode） |
| 学びを記録する | Claude Code（「CLAUDE.mdに追加して」） |
| スマホで気軽に質問 | claude.ai（Web/アプリ） |
| 画像を見せて相談 | claude.ai |

**基本はClaude Codeで完結し、必要に応じてclaude.aiを併用**するのがおすすめです。

---

## トラブルシューティング

### 履歴ファイルが大きすぎる場合

conversations.jsonが数十MB〜数百MBになることがあります。その場合は、**フィルタリングを依頼**するのが最も簡単です：

```
conversations.jsonから、特定のプロジェクト「〇〇」に関する会話だけ抽出して分析してください。
```

:::details その他の方法（上級者向け）

**compactで要約**

> *"The /compact command summarizes the current conversation. If you include specific instructions in your /compact command, those instructions will be used for the summary."*
> （/compactコマンドは現在の会話を要約します。/compactコマンドに具体的な指示を含めると、その指示が要約に使用されます）
> — [Manage Claude's memory](https://docs.anthropic.com/en/docs/claude-code/memory)

```bash
/compact プロジェクト〇〇に関する設定情報だけ残して
```

**Subagent（サブエージェント）で分割処理**

サブエージェントとは、メインのClaudeとは別に動く補助AIのことです。大きなファイルを小さなチャンクに分割して処理させられます。詳しくは[シリーズ第2記事](claude-code-tips-and-features)を参照。

> *"When Claude Code encounters a task that matches a subagent's expertise, it can delegate that task to the specialized subagent, which works independently and returns results. Each subagent operates in its own context, preventing pollution of the main conversation."*
> （Claude Codeがサブエージェントの専門分野に一致するタスクに遭遇すると、その専門サブエージェントにタスクを委任できます。各サブエージェントは独自のコンテキストで動作し、メイン会話の汚染を防ぎます）
> — [Subagents](https://docs.anthropic.com/en/docs/claude-code/sub-agents)
:::

---

### 失敗したらロールバック

> *"Correct course early: If Claude starts going in the wrong direction, press Escape to stop it immediately. /rewind or pressing Escape twice will restore both the conversation and any file changes to a previous checkpoint."*
> （早めに軌道修正：Claudeが間違った方向に進み始めたら、Escapeを押してすぐに停止。/rewindまたはEscapeを2回押すと、会話とコードを以前のチェックポイントに復元できます）
> — [Manage costs effectively](https://docs.anthropic.com/en/docs/claude-code/costs)

| 状況 | 対処 |
|------|------|
| 実行中に止めたい | `Esc` |
| 直前に戻したい | `Esc` を2回、または `/rewind` |
| セッションを分岐したい | `/rewind` で任意のポイントから分岐 |

---

## 発展的な使い方

移行が完了したら、以下の機能も活用できます。

### CLAUDE.md（プロジェクトの脳）

> *"Project memory can be stored in either ./CLAUDE.md or ./.claude/CLAUDE.md."*
> （プロジェクトメモリは ./CLAUDE.md または ./.claude/CLAUDE.md に保存できます）
> — [Manage Claude's memory](https://docs.anthropic.com/en/docs/claude-code/memory)

```markdown
# プロジェクト概要
React + TypeScript のWebアプリケーション。

# コーディング規約
- 関数コンポーネントのみ使用
- 日本語コメント必須
- テストは jest で書く

# よく使うコマンド
- `npm run dev` - 開発サーバー起動
- `npm test` - テスト実行
```

これがClaude Codeを起動した瞬間に読み込まれます。

:::message alert
**500行以下を推奨**。詳細な手順はSkillsに分離しましょう。

> *"Keep SKILL.md under 500 lines. Move detailed reference material to separate files."*
> （SKILL.mdは500行以下に。詳細な参照資料は別ファイルに移動）
> — [Extend Claude with skills](https://docs.anthropic.com/en/docs/claude-code/slash-commands)
:::

### Skills（定型作業のマニュアル）

> *"Every skill needs a SKILL.md file with two parts: YAML frontmatter (between --- markers) that tells Claude when to use the skill, and markdown content with instructions Claude follows when the skill is invoked."*
> （すべてのスキルには2つの部分で構成されるSKILL.mdファイルが必要です：YAMLフロントマター（---マーカーの間）はClaudeにいつスキルを使用するかを伝え、マークダウンコンテンツはスキルが呼び出されたときにClaudeが従う指示です）
> — [Extend Claude with skills](https://docs.anthropic.com/en/docs/claude-code/slash-commands)

`.claude/skills/generate-report/SKILL.md`:

```markdown
---
name: generate-report
description: 週次レポートを生成する。「レポート作って」と言われたら使う。
---

# 手順

1. git log で今週のコミットを取得
2. 変更内容をカテゴリ分け（機能追加/バグ修正/その他）
3. Markdown形式で出力
```

これで「レポート作って」の一言で、決まった形式のレポートが出てきます。

### Rules（ファイル別ルール）

> *"Place markdown files in your project's .claude/rules/ directory... All .md files in .claude/rules/ are automatically loaded as project memory."*
> （プロジェクトの .claude/rules/ ディレクトリにマークダウンファイルを配置... .claude/rules/ 内のすべての.mdファイルはプロジェクトメモリとして自動読み込みされます）
> — [Manage Claude's memory](https://docs.anthropic.com/en/docs/claude-code/memory)

`.claude/rules/api-standards.md`:

```markdown
---
paths:
  - "src/api/**/*.ts"
---

# APIファイル専用ルール
- 必ず入力バリデーションを書く
- エラーレスポンスは統一フォーマット
```

`src/api/` 配下のファイルを触るときだけ、このルールが自動で適用されます。

---

## 結論とメッセージ

### 一文で要約すると

**Web版で育てた知識は、履歴エクスポート → Claude Codeで設定ファイルに変換でき、その後はClaude Codeで知識を蓄積し続けられる。**

### 読者への呼びかけ

「ターミナル怖い」「設定ファイル意味不明」——その気持ち、分かります。私もそうでした。

でも、やってみたら「エクスポートして、Claude Codeに作らせる」だけでした。コードは1行も書いていません。

そして移行後は、claude.aiに戻る必要もありません。Plan Modeで相談し、実行し、「学びを記録して」と依頼するだけ。**Claude Codeで完結するワークフロー**が手に入ります。

あなたがWeb版Claude.aiで積み上げてきた知識、捨てるのはもったいないです。この記事の手順で、CLI版に引っ越してみてください。

---

## 付録：クイックリファレンス

### 必要なもの

| 項目 | 説明 |
|------|------|
| Claude Code | [Set up Claude Code](https://docs.anthropic.com/en/docs/claude-code/setup) |
| 認証 | Claude Pro/Max または APIキー |
| 使用モデル | **Sonnet 4.5**（デフォルト、変更不要） |

:::message
**モデルについて**

Claude Codeは **Proプランの場合、デフォルトでSonnet 4.5を使用** します。特別な設定は不要です。Maxプランの場合はOpus系モデルが優先的に使用されます。

> *"If you're unsure which model to use, we recommend starting with Claude Sonnet 4.5. It offers the best balance of intelligence, speed, and cost for most use cases, with exceptional performance in coding and agentic tasks."*
> （どのモデルを使うか迷ったら、Claude Sonnet 4.5から始めることをお勧めします。ほとんどのユースケースでインテリジェンス、スピード、コストの最良のバランスを提供し、コーディングとエージェントタスクで卓越したパフォーマンスを発揮します）
> — [Models overview](https://docs.anthropic.com/en/docs/about-claude/models/overview)

今回の移行作業（JSONファイルの分析→設定ファイルの作成）はSonnet 4.5で十分です。
:::

:::details Opus 4.5に変更したい場合（上級者向け）

Claude Code内で `/model` コマンドを実行すると、モデルを変更できます：

```bash
/model opus      # Opus 4.5に変更
/model sonnet    # Sonnet 4.5に戻す
/model opusplan  # Plan ModeのみOpus、実行はSonnet（ハイブリッド）
```

> *"The opusplan model alias provides an automated hybrid approach: In plan mode - Uses opus for complex reasoning and architecture decisions. In execution mode - Automatically switches to sonnet for code generation and implementation."*
> （opusplanモデルエイリアスは自動化されたハイブリッドアプローチを提供します：Plan ModeではOpusを使用し、実行モードではSonnetに自動切り替えします）
> — [Model configuration](https://docs.anthropic.com/en/docs/claude-code/model-config)

**注意：** Opusは複雑なアーキテクチャ決定や多段階推論向けです。今回のような変換作業ではSonnetで十分であり、Opusに変更するメリットはほとんどありません。
:::

### 手順まとめ

```bash
# 1. 履歴エクスポート
#    claude.ai → 左下イニシャル → Settings → Privacy
#    → Conversations を選択 → Export data

# 2. Claude Codeインストール
curl -fsSL https://claude.ai/install.sh | sh

# 3. ZIPを展開してプロジェクトディレクトリに配置
#    ⚠️ ~/.claude/ には置かない

# 4. プロジェクトディレクトリでClaude Codeを起動
cd my-project
claude

# 5. Shift+Tab 2回で Plan Mode に切り替え → 指示を伝える
```

````
JSONファイルを読み込んで、プロジェクト「〇〇」の設定ファイルを作成してください。

【提示してほしい内容】
1. 現状の構成（既存のCLAUDE.mdがあるか）
2. JSONの分析結果（4カテゴリに分類）
   - A. このプロジェクト固有 → ./CLAUDE.md
   - B. 除外候補（別プロジェクトの情報）
   - C. 全プロジェクト共通 → ~/.claude/CLAUDE.md（言語、スタイルのみ）
   - D. 定型作業 → .claude/skills/
3. 変更後の構成

提示後、私が「OK」と言ったら実行してください。
````

### 確認コマンド

| コマンド | 用途 |
|----------|------|
| `/memory` | 読み込まれているメモリファイルを確認 |
| `/skills` | 使用可能なスキルを確認 |
| `/context` | コンテキスト使用量を確認 |
| `/compact` | 会話を要約してコンテキストを節約 |
| `/rewind` | 以前のチェックポイントに戻す |

### よくある質問

| 質問 | 回答 |
|------|------|
| JSONファイルは削除していい？ | 移行完了後は削除OK。心配なら残しておく |
| 設定ファイルを間違えたら？ | `Esc` 2回または `/rewind` で戻せる |
| 複数プロジェクトに移行したい場合は？ | プロジェクトごとにステップ3〜4を繰り返す |

---

## 公式ドキュメントリンク集

| リンク | 内容 |
|--------|------|
| [Manage Claude's memory](https://docs.anthropic.com/en/docs/claude-code/memory) | CLAUDE.md、メモリの階層構造 |
| [Extend Claude with skills](https://docs.anthropic.com/en/docs/claude-code/slash-commands) | Skills、カスタムコマンド |
| [Common workflows](https://docs.anthropic.com/en/docs/claude-code/tutorials) | Plan Mode、セッション継続 |
| [Set up Claude Code](https://docs.anthropic.com/en/docs/claude-code/setup) | インストール、認証 |
| [How can I export my Claude data?](https://support.anthropic.com/en/articles/9450526-how-can-i-export-my-claude-ai-data) | 履歴エクスポート |

---

## 関連記事

- [非エンジニアがWindowsでClaude Codeを使えるようになるまで](claude-code-windows-install-guide)
- [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips-and-features)
- [Claude Codeが動かない時に見るページ（Windows編）](claude-code-windows-troubleshoot)
- [AIにコードを書かせてAIにレビューさせる開発スタイル](claude-code-ai-review-workflow)
