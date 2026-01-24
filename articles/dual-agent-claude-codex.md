---
title: "AIにコードを書かせてAIにレビューさせる開発スタイル"
emoji: "🤖"
type: "tech"
topics: ["claudecode", "ai", "llm", "codex", "個人開発"]
published: false
---

## はじめに

この記事では、Claude Code（コードを書く担当）とレビュー担当AIを組み合わせた開発スタイルを紹介する。

普通は1つのAIに全部任せる。でも、それだと**自分が作ったものには甘くなりがち**で、問題を見逃すことがある。
人間の開発チームでも「作る人」と「チェックする人」を分けるのと同じで、**AIでも役割分担すると品質が上がる**。

最初は Claude Code と OpenAI の Codex CLI を組み合わせる方法を試していた。
でも、**Claude Code だけで同じことができる**とわかったので、この記事ではそちらを中心に説明する。

:::message
Codex CLI との組み合わせ方法に興味がある方は「[参考：Codex CLI方式](#参考codex-cli方式)」をご覧ください。
:::

:::message
**シリーズ構成**
1. [非エンジニアがWindowsでClaude Codeを使えるようになるまで](claude-code-windows-setup)
2. [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips)
3. [Claude Codeが動かない時に見るページ（Windows編）](claude-code-troubleshooting-windows)
4. **AIにコードを書かせてAIにレビューさせる開発スタイル**（この記事）
:::

---

## 用語説明

この記事で使う言葉を先に説明しておく。

| 用語 | 意味 |
|------|------|
| サブエージェント | Claude Code の中で動く「別のAI担当者」のこと。メインのAIが別のAIに仕事を頼める機能 |
| Builder（ビルダー） | コードを書く担当。この記事では Claude Code のメインAI |
| Auditor（オーディター） | コードをチェックする担当。この記事ではサブエージェント |
| スキル | Claude Code に登録できる「よく使うコマンド」のこと。`/review` のように呼び出せる |

---

## 2つの方式の比較

役割分担する方法は2つある。**特別な理由がなければ、サブエージェント方式がおすすめ。**

| 項目 | サブエージェント方式 | Codex CLI方式 |
|------|----------------------|---------------|
| 追加契約 | **不要**（Claude Pro/Maxのみ） | ChatGPT Plus/Pro が必要 |
| セットアップ | ファイルを作るだけ | WSL + Node.js + 認証が必要 |
| 操作 | 同じ画面で完結 | 2つのターミナルを行き来 |
| 再利用 | 一度作れば全プロジェクトで使える | プロジェクトごとに設定が必要 |
| トラブル | ほぼなし | 認証エラーなど起きやすい |

---

## サブエージェント方式

### しくみ

Claude Code には「サブエージェント」という機能がある。
メインのAI（Builder）が、別のAI担当者（Auditor）に仕事を頼めるしくみ。

**ポイント：チェック担当のAIには「読み取り専用」の制限をかける**

これにより「チェックする人が勝手に直してしまう」問題を防げる。
指摘だけして、修正はメインのAIに任せる流れになる。

```
┌─────────────────────────────────────────────┐
│  Claude Code                                │
│                                             │
│  ┌─────────────┐      ┌─────────────┐      │
│  │  Builder    │ ──→  │  Auditor    │      │
│  │ (メインAI)   │ ←── │ (サブAI)    │      │
│  │             │      │             │      │
│  │ ・コードを書く │      │ ・レビューする │      │
│  │ ・修正する    │      │ ・問題を指摘  │      │
│  │ ・テスト作成  │      │ ・修正はしない │      │
│  └─────────────┘      └─────────────┘      │
└─────────────────────────────────────────────┘
```

---

### 環境構築

#### 前提条件

| 項目 | 要件 |
|------|------|
| Claude Code | インストール済み（[記事1](claude-code-windows-setup)参照） |
| 契約 | Claude Pro または Max |

#### Step 1: フォルダを作成

まず、サブエージェントの設定ファイルを置くフォルダを作る。

**Windows（PowerShell）:**
```powershell
New-Item -ItemType Directory -Force -Path ".claude\agents\code-auditor"
```

**macOS / Linux:**
```bash
mkdir -p .claude/agents/code-auditor
```

#### Step 2: サブエージェントの設定ファイルを作成

📝 `.claude/agents/code-auditor/code-auditor.md` を作成：

```markdown
---
name: code-auditor
description: コード品質・セキュリティ監査の専門家
tools: Read, Grep, Glob, Bash
model: sonnet
disallowedTools: Write, Edit, NotebookEdit
---

あなたはシニアコードレビュアーです。
変更されたコードを以下の観点で厳密に監査してください。

## 監査観点

### 1. セキュリティ（🔴 重大）
- XSS、コマンドインジェクション
- 機密情報のハードコード
- 外部からの入力をそのまま使用

### 2. バグの可能性（🔴 重大）
- null/undefined参照
- 境界条件の未処理（空配列、0、負の値）
- 非同期処理のエラーハンドリング漏れ
- 型エラー

### 3. パフォーマンス（🟡 改善推奨）
- 不要な再レンダリング（useCallback, useMemo の欠如）
- 大きなコンポーネントの分割
- 重い処理のメモ化

### 4. コーディング規約（🟡 改善推奨）
- 命名規則
- 関数の長さ（50行以上は分割検討）
- 使用されていない変数・import

## 出力形式

## 監査結果

### 🔴 重大な問題（blocking）
（必ず直すべき問題。なければ「なし」）

### 🟡 改善推奨（advisory）
（できれば直した方がいい問題。なければ「なし」）

### 🟢 良い点
（良いプラクティスがあれば記載）

### 📝 総評
（全体的な評価と次のアクション）
```

:::message
**disallowedTools の意味**
`disallowedTools: Write, Edit` と書くことで、このサブエージェントはファイルの書き込み・編集ができなくなる。読み取り専用になる。
:::

#### Step 3: レビュー用スキルを作成

`/review` と入力するだけでレビューできるようにする。

**Windows（PowerShell）:**
```powershell
New-Item -ItemType Directory -Force -Path ".claude\skills\review"
```

**macOS / Linux:**
```bash
mkdir -p .claude/skills/review
```

📝 `.claude/skills/review/SKILL.md` を作成：

```markdown
---
name: review
description: コードレビューを実行
context: fork
agent: code-auditor
---

直近の変更をレビューしてください。

## レビュー対象ファイル
!`git diff --name-only HEAD~1 2>/dev/null || git diff --name-only`

## 変更内容
!`git diff HEAD~1 2>/dev/null || git diff`
```

#### Step 4: グローバルに配置（他のプロジェクトでも使えるようにする）

一度作った設定を、どのプロジェクトでも使えるようにする。

**Windows（PowerShell）:**
```powershell
$claudeDir = "$env:USERPROFILE\.claude"

# エージェントをグローバルに配置
New-Item -ItemType Directory -Force -Path "$claudeDir\agents\code-auditor"
Copy-Item ".\.claude\agents\code-auditor\code-auditor.md" "$claudeDir\agents\code-auditor\"

# スキルをグローバルに配置
New-Item -ItemType Directory -Force -Path "$claudeDir\skills\review"
Copy-Item ".\.claude\skills\review\SKILL.md" "$claudeDir\skills\review\"
```

**macOS / Linux:**
```bash
mkdir -p ~/.claude/agents/code-auditor
mkdir -p ~/.claude/skills/review

cp .claude/agents/code-auditor/code-auditor.md ~/.claude/agents/code-auditor/
cp .claude/skills/review/SKILL.md ~/.claude/skills/review/
```

これで準備完了。

---

### 実践：修正サイクルの流れ

```
実装 → コミット → レビュー依頼 → 問題あり? → 修正 → 再レビュー → 完了
                                    ↑______________|
```

#### Step 1: Claude Code で実装

普通に Claude Code へ指示する。

```
シンプルなToDoリストを作って。タスクの追加・完了・削除ができるようにして。
```

#### Step 2: レビューを依頼

実装が終わったら、レビューを依頼する。方法は2つ。

**方法A：スキルを使う（簡単）**
```
/review
```

**方法B：直接サブエージェントを呼ぶ**
```
code-auditorサブエージェントを使って、直近の変更をレビューして
```

#### Step 3: レビュー結果を確認

こんな感じで結果が返ってくる：

| 重要度 | ファイル | 問題 | 推奨対応 |
|--------|----------|------|----------|
| 🔴 blocking | todo.js | 削除後に画面が更新されない | 再描画処理を追加 |
| 🟡 advisory | todo.js | 空タスクも追加できる | 入力チェックを追加 |

#### Step 4: 修正を依頼

レビュー結果をもとに修正を依頼する。

```
code-auditorのレビュー結果に基づいて、問題を修正して
```

:::message
**ポイント**
「どう直すか」は指示しなくて大丈夫。Claude Code が自分で考えて修正してくれる。
:::

#### Step 5: 再レビュー → 完了

修正が終わったら、もう一度レビューする。

```
/review
```

`🔴 重大な問題: なし` になったら完了。

---

### よく使うコマンド

| コマンド | 用途 |
|----------|------|
| `/review` | 直近の変更をレビュー |
| `〇〇ファイルをレビューして` | 特定ファイルをレビュー |
| `プロジェクト全体をレビューして` | 全体をチェック |

---

### うまく使うコツ

#### 1. Claude Code には「何をしたいか」だけ伝える

| 良い例 | 悪い例 |
|--------|--------|
| 「削除ボタンが動きません。直してください」 | 「○行目を△に変えて」と細かく指定 |
| 「レビュー結果の問題を修正して」 | 具体的なコードを書いて渡す |

#### 2. エラーが出たらそのまま貼り付ける

ビルドエラーが出たら、エラーメッセージをそのままコピペして「直してください」でOK。

#### 3. こまめにコミットする

AIが変な変更をした時に戻れるよう、CLAUDE.md に以下を追記しておくと便利：

```markdown
## Git運用規約

### 自動コミットのタイミング
以下のタイミングで必ずコミットを作成してください：
1. 機能実装が完了した時
2. バグ修正が完了した時
3. ユーザーから「区切り」「一段落」と言われた時

### コミットメッセージ
変更内容がわかる説明的なメッセージをつけてください。
```

#### 4. レビューのタイミング

| タイミング | 理由 |
|------------|------|
| 新機能の実装完了後 | 機能単位でチェック |
| 5ファイル以上変更した時 | 大きな変更は問題が潜みやすい |
| コミット前 | 品質を保証してから保存 |

---

## やってみてわかったこと

### うまくいったポイント

| ポイント | 詳細 |
|----------|------|
| 役割分担の効果 | Builder が見逃した問題を Auditor が見つけてくれる |
| 任せる姿勢 | 細かく指示するより、要件だけ伝えて任せた方が効率的 |
| グローバル設定 | 一度作った設定を全プロジェクトで再利用できる |

### つまずいたポイント

| 問題 | 解決策 |
|------|--------|
| GitHub認証でエラー | Personal Access Token で対応（[記事3](claude-code-troubleshooting-windows)参照） |
| ビルドエラー | エラーメッセージをそのまま Claude Code に渡して修正 |
| 指示が細かすぎた | 要件だけ伝えて任せる方がうまくいく |

### 事前に確認しておくとよいこと

| 確認項目 | 例 |
|----------|----|
| 環境 | Git の設定は済んでいるか |
| 希望 | デプロイ方法、公開/非公開の希望 |
| 動作確認 | 実機での表示確認方法 |

---

## まとめ

| 方式 | おすすめ度 | 理由 |
|------|------------|------|
| サブエージェント方式 | ⭐⭐⭐ | シンプル、追加契約不要、トラブル少ない |
| Codex CLI方式 | ⭐ | 複雑、追加契約必要、トラブル多い |

**「作る人」と「チェックする人」を分けると、1人（1つのAI）でやるより品質が上がる。**
Claude Code のサブエージェント機能を使えば、追加契約なしでこの体制が作れる。

---

## 参考：Codex CLI方式

:::details Codex CLI 方式の詳細（クリックで展開）

GPT系モデルの視点も取り入れたい場合や、既に ChatGPT Plus/Pro を契約している場合の代替手段。

### しくみ

Claude Code（Builder）と OpenAI Codex CLI（Auditor）を2つのターミナルで並行実行する。

```
┌──────────────────┐      ┌──────────────────┐
│  PowerShell      │      │  WSL Ubuntu      │
│                  │      │                  │
│  Claude Code     │ ───→ │  Codex CLI       │
│  (Builder)       │ ←─── │  (Auditor)       │
└──────────────────┘      └──────────────────┘
```

### 料金

| ツール | 必要な契約 |
|--------|------------|
| Claude Code | Claude Pro または Max |
| Codex CLI | ChatGPT Plus または Pro |

### セットアップの流れ

1. WSL2 をインストール（PowerShell 管理者で `wsl --install`）
2. PC を再起動
3. WSL 内で Node.js をインストール
4. Codex CLI をインストール
5. ChatGPT アカウントで認証

### WSL2 のインストール

**PowerShell（管理者として実行）:**
```powershell
wsl --install
```

完了したらPCを再起動。

### Codex CLI のインストール

**WSL内:**
```bash
# パッケージを更新
sudo apt update && sudo apt upgrade -y

# wsluをインストール（認証用）
sudo apt install -y wslu

# nvmをインストール
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
source ~/.bashrc

# Node.js v22をインストール
nvm install 22

# Codex CLI をインストール
npm i -g @openai/codex
```

### 認証

**WSL内:**
```bash
codex
```

初回起動時に「**Sign in with ChatGPT**」を選択すると、ブラウザが開く。

### 注意点

- ChatGPT Plus/Pro の契約が別途必要
- ブラウザ認証でエラー（ERR_CONNECTION_REFUSED）が出ることがある
- その場合は Personal Access Token 方式で対応

:::

---

## 参考リンク

- [Claude Code 公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code)
- [OpenAI Codex CLI](https://github.com/openai/codex)

:::message
リンク切れの場合は各公式サイトで検索してください。
:::

---

## 関連記事

- [非エンジニアがWindowsでClaude Codeを使えるようになるまで](claude-code-windows-setup)
- [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips)
- [Claude Codeが動かない時に見るページ（Windows編）](claude-code-troubleshooting-windows)
