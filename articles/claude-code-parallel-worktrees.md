---
title: "Claude Codeを2つ同時に動かしたら、ブランチ切り替え地獄から解放された"
emoji: "🌳"
type: "tech"
topics: ["claudecode", "ai", "生成ai", "git", "個人開発"]
published: true
---

## はじめに

### ブランチの切り替えとは

Gitでは「ブランチ」という仕組みで、作業を枝分かれさせることができる。

例えば、新機能を作りながら、同時にバグ修正もしたい場面。ブランチを分ければ、それぞれの作業を独立して進められる。

```
main ────────────────── 本番のコード
  ├── feature-a ─────── 新機能Aの開発
  └── bugfix-123 ────── バグ修正
```

ただし、通常のGitでは **1つのフォルダで1つのブランチしか作業できない**。別のブランチで作業するには「切り替え」が必要で、その度にフォルダ内のファイルが丸ごと書き換わる。

### Claude Codeで困ること

この「ブランチ切り替え」が、Claude Codeとの開発で問題になる。

- 機能Aを作っている途中で、別の箇所でバグを見つけてしまった
- 先にバグを直したいのでブランチを切り替えると、フォルダ内のファイルが別の内容に変わる
- **Claude Codeは「さっき読んだファイル」を覚えているのに、実際のファイルが変わってしまう**
- 元のブランチに戻っても、Claude Codeのコンテキストはもう壊れている

さらに、2つの機能を同時に進めたくても、ブランチの切り替えでは1つずつしか作業できない。

### この記事で解決すること

この問題を解決するのが **Git Worktree**（ワークツリー）を使った並列セッション開発だ。

公式ドキュメントでも紹介されている手法で、**ブランチごとに別のフォルダを用意し**、複数のClaude Codeインスタンスを **完全に分離された環境** で同時に動かせる。

:::message
**この記事の前提**
Gitの基本操作（コミット、プッシュ）を知っている方が対象。ブランチの経験が浅くても読めるように説明している。手順はWindows（PowerShell / Git Bash）、macOS、Linuxのいずれでも動作する。
:::

:::message
**シリーズ構成**
1. [ポンコツになる原因はコンテキスト](claude-code-context-management)
2. [「本当に合ってる？」と自問させる](claude-code-self-verification)
3. [CLAUDE.mdで別人にする](claude-code-claude-md)
4. [「いい感じにして」をやめる](claude-code-effective-prompts)
5. [もう一人のClaudeに調査を任せる](claude-code-subagents)
6. **2つ同時に動かす並列開発**（この記事）
7. [「昨日の続き」を一瞬で再開](claude-code-session-management)
:::

---

## Git Worktreeとは

Git Worktreeは、**1つのリポジトリから複数の作業ディレクトリを作る** Gitの標準機能。

通常、1つのリポジトリ（プロジェクトのフォルダ）には1つの作業ディレクトリしかない。ブランチ（作業の分岐）を切り替えるには `git checkout` や `git switch` が必要で、その都度ファイルが書き換わる。

Worktreeを使うと、**ブランチごとに別のフォルダ**が作られる。

```
my-project/              ← 元のリポジトリ（mainブランチ）
my-project-feature-a/    ← Worktree 1（feature-aブランチ）
my-project-bugfix/       ← Worktree 2（bugfix-123ブランチ）
```

それぞれのフォルダは独立しているが、**Git履歴とリモート接続は共有** される。つまり、同じリポジトリの「別の窓」が開いている状態だ。

---

## なぜ並列セッションに最適なのか

### ブランチ切り替えの問題

通常の開発フローでは、ブランチを切り替えるとファイルが全部書き換わる。

```bash
# 機能Aを作業中...
git stash                 # 今の作業を一時退避
git switch bugfix-123     # ブランチ切り替え（フォルダ内のファイルが書き換わる）
# バグ修正...
git switch feature-a      # 元のブランチに戻る（またファイルが書き換わる）
git stash pop             # 退避した作業を復元
```

この間、Claude Codeのコンテキストは **ファイルの状態と合わなくなる**。Claudeは「さっき読んだファイル」を覚えているが、実際のファイルは別ブランチの内容に変わっている。

### Worktreeなら完全に分離できる

```
my-project/              ← Claude Code セッション1（mainブランチ）
my-project-feature-a/    ← Claude Code セッション2（feature-aブランチ）
my-project-bugfix/       ← Claude Code セッション3（bugfix-123ブランチ）
```

- 各フォルダでClaude Codeを起動すれば、それぞれ **独立したセッション** になる
- 1つのWorktreeでの変更は、他のWorktreeに一切影響しない
- 各Claude Codeインスタンスが干渉し合わない

---

## 実践手順

### ステップ1：Worktreeを作成する

ターミナル（PowerShellまたはGit Bash）で、プロジェクトのフォルダに移動して実行する。

**新しいブランチを同時に作る場合：**

```bash
git worktree add ../my-project-feature-a -b feature-a
```

| 部分 | 意味 |
|------|------|
| `git worktree add` | Worktreeを作成するコマンド |
| `../my-project-feature-a` | 新しい作業フォルダのパス（親ディレクトリに作成） |
| `-b feature-a` | 新しいブランチ `feature-a` を作成してチェックアウト |

**既存のブランチを使う場合：**

```bash
git worktree add ../my-project-bugfix bugfix-123
```

:::message
**フォルダ名のコツ**

何の作業用か一目でわかる名前をつける。
- `../my-project-feature-a` → 機能A開発用
- `../my-project-bugfix-login` → ログインバグ修正用
- `../my-project-refactor-auth` → 認証リファクタリング用
:::

### ステップ2：Worktreeに移動してClaude Codeを起動

```bash
cd ../my-project-feature-a
claude
```

これで、`feature-a` ブランチ専用のClaude Codeセッションが始まる。

### ステップ3：別のターミナルで、もう1つのWorktreeでもClaude Codeを起動

新しいターミナルウィンドウ（またはタブ）を開いて：

```bash
cd ../my-project-bugfix
claude
```

これで、2つのClaude Codeが **完全に独立した環境** で同時に動く。

```
ターミナル 1                    ターミナル 2
┌──────────────────────┐    ┌──────────────────────┐
│ my-project-feature-a │    │ my-project-bugfix    │
│                      │    │                      │
│ Claude Code          │    │ Claude Code          │
│ (feature-a ブランチ)  │    │ (bugfix-123 ブランチ) │
│                      │    │                      │
│ 機能Aの開発中...      │    │ バグ修正中...         │
└──────────────────────┘    └──────────────────────┘
         ↓                           ↓
    同じGit履歴を共有（でもファイルは独立）
```

### ステップ4：作業が終わったらWorktreeを管理・削除

```bash
# 現在のWorktree一覧を確認
git worktree list

# 不要になったWorktreeを削除
git worktree remove ../my-project-feature-a

# 削除済みフォルダの参照を掃除（たまに実行）
git worktree prune
```

:::message alert
**Worktreeを削除する前に**
- 作業内容がコミット・プッシュ済みか確認する
- 未コミットの変更があると削除に失敗する（安全装置がある）
- `git worktree remove` はフォルダを削除するだけで、ブランチは残る。ブランチも消したい場合は別途 `git branch -d <ブランチ名>`
:::

---

## 環境セットアップの注意点

Worktreeで作られたフォルダには、そのブランチのソースコードが展開される。ただし **依存パッケージはインストールされていない** 状態だ。

各Worktreeで最初にやること：

| プロジェクトの種類 | 実行するコマンド |
|------------------|----------------|
| JavaScript / TypeScript | `npm install` または `yarn` |
| Python | `pip install -r requirements.txt` またはvenv作成 |
| その他 | プロジェクトの標準セットアップ手順に従う |

```bash
# 例：Node.jsプロジェクトの場合
cd ../my-project-feature-a
npm install
claude
```

:::message
`node_modules` や `venv` はGitの管理対象外（`.gitignore` というファイルで除外指定されている）なので、Worktreeごとに個別にインストールが必要。

一方、`CLAUDE.md` や `.claude/settings.json` などGit管理下のファイルは **全てのWorktreeで自動的に共有される**。プロジェクトの指示やルールはWorktreeごとに設定し直す必要はない。
:::

---

## 実践的な使い方：3つのパターン

### パターン1：機能開発 + バグ修正の並行

最もよくあるケース。機能開発中にバグを見つけた場合。

```bash
# 元のリポジトリで機能Aを開発中
# → 別の箇所でバグを発見

# バグ修正用のWorktreeを作成
git worktree add ../my-project-hotfix -b hotfix/login-error

# 別ターミナルでバグ修正
cd ../my-project-hotfix
npm install
claude
# → 「ログインエラーを修正して」

# 元のターミナルでは機能Aの開発を継続できる
```

### パターン2：複数機能の同時開発

2つ以上の機能を並行して進めたい場合。

```bash
# 機能A用
git worktree add ../my-project-feature-a -b feature/user-profile

# 機能B用
git worktree add ../my-project-feature-b -b feature/notification

# それぞれ別ターミナルでClaude Codeを起動
```

### パターン3：レビュー用の読み取り専用環境

PR（プルリクエスト）のコードレビューをClaude Codeに頼みたいが、今の作業を中断したくない場合。

```bash
# レビュー対象のブランチでWorktreeを作成
git worktree add ../my-project-review feature/target-branch

# 別ターミナルでレビュー
cd ../my-project-review
claude
# → 「このブランチの変更をレビューして」
```

---

## まとめ

| 方法 | メリット | デメリット |
|------|---------|-----------|
| ブランチ切り替え | 追加フォルダ不要 | コンテキストが壊れる、同時作業不可 |
| **Git Worktree** | **完全分離、並列作業可能** | フォルダが増える、依存パッケージの再インストールが必要 |

Git Worktreeを使えば：

- **中断なし**：機能開発中にバグが見つかっても、作業を止めなくていい
- **コンテキスト維持**：各Claude Codeセッションが独立しているので、コンテキストが混ざらない
- **並列開発**：複数のClaude Codeインスタンスが同時に、異なるタスクに取り組める

一度使うと、ブランチ切り替えには戻れなくなるはずだ。

:::message alert
**コストについて**
複数のClaude Codeを同時に動かすと、それぞれがAPIを消費する。Claude ProやMaxの利用量制限に早く達する可能性があるため、必要な時だけWorktreeを作り、終わったら削除するのがお勧め。
:::

:::message
**セッションの再開**
Worktreeごとのセッションは `claude --continue` で続行できる。`/resume` のピッカーはWorktreeを含む同じGitリポジトリからのセッションも表示する。詳しくは[第7部：セッション管理](claude-code-session-management)で解説。
:::

:::message alert
**同じブランチは2つのWorktreeで同時に使えない**
Gitの制約として、1つのブランチは1つのWorktreeでしかチェックアウトできない。必ず別のブランチ名を指定すること。
:::

---

## 並列化の3つの手段

Claude Codeには、作業を並列化する手段が3つある。目的によって使い分ける。

| 手段 | 何をするか | コスト | 向いている場面 |
|------|-----------|--------|--------------|
| **サブエージェント** | セッション内で調査を委譲。結果だけ返ってくる | 低 | 「ちょっと調べてきて」 |
| **Git Worktree**（この記事） | 手動で独立した並列セッションを作る | 中 | 「別の作業を並行で進めたい」 |
| **Agent Teams** | 自動調整付きの並列セッション。リーダーが統括 | 高 | 「チームで協調して1つの問題に取り組みたい」 |

**サブエージェント** はメインセッション内で動く「調査係」。100ファイル読んでもメインのコンテキストを消費しない。詳しくは[第5部](claude-code-subagents)で解説。

**Git Worktree** は完全に独立したセッションで、別の作業を進める仕組み。セッション間の連携は自分で管理する。

**Agent Teams** は複数のClaude Codeインスタンスが自動的に連携する仕組み。共有タスクリストとメッセージングで協調する。ただし現時点では **実験的機能**（デフォルト無効）で、トークン消費も大きい。

:::message
**Agent Teamsを試すには**
`settings.json` に以下を追加して有効化する。

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

詳細は[公式ドキュメント - Agent Teams](https://code.claude.com/docs/ja/agent-teams)を参照。
:::

---

## 参考

- [Claude Code公式ドキュメント - 一般的なワークフロー](https://code.claude.com/docs/ja/common-workflows)
- [Claude Code公式ドキュメント - Agent Teams](https://code.claude.com/docs/ja/agent-teams)
- [Git公式ドキュメント - git-worktree](https://git-scm.com/docs/git-worktree)

---

## 関連記事

- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ：使いこなすためのTips](claude-code-tips-and-features)
- [Claude Code が動かない時に見るページ（Windows）](claude-code-windows-troubleshoot)
- [Claude Codeの請求額を見て青ざめた人へ贈るコスト管理術](claude-code-cost-management)
- [Claude Codeを寝てる間に働かせる：ヘッドレスモード活用術](claude-code-headless-mode)
