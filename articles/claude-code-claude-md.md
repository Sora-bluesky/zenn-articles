---
title: "CLAUDE.mdを書いたら、Claude Codeが別人になった"
emoji: "📝"
type: "tech"
topics: ["claudecode", "ai", "生成ai", "llm", "個人開発"]
published: false
---

## はじめに

Claude Codeを使うたびに、同じ説明を繰り返していないだろうか。

- 「このプロジェクトは TypeScript を使っていて...」
- 「テストは Jest で...」
- 「コミットメッセージは日本語で...」

毎回これを説明するのは面倒だし、説明し忘れると想定外の動作をされる。

**CLAUDE.md** は、この問題を解決する。一度書いておけば、Claudeが毎回自動で読んでくれる。

この記事では、CLAUDE.mdの書き方と、やってはいけないことを解説する。

:::message
**シリーズ構成**
1. [ポンコツになる原因はコンテキスト](claude-code-context-management)
2. [「本当に合ってる？」と自問させる](claude-code-self-verification)
3. **CLAUDE.mdで別人にする**（この記事）
4. [「いい感じにして」をやめる](claude-code-effective-prompts)
5. [もう一人のClaudeに調査を任せる](claude-code-subagents)
6. [2つ同時に動かす並列開発](claude-code-parallel-worktrees)
7. [「昨日の続き」を一瞬で再開](claude-code-session-management)
:::

---

## CLAUDE.md とは

CLAUDE.mdは、Claudeが会話の最初に自動で読むファイル。

```
プロジェクトフォルダ/
├── CLAUDE.md        ← Claudeが最初に読む
├── src/
├── package.json
└── ...
```

ここに書いた内容は、**コードを見ただけでは分からない情報**をClaudeに伝えるために使う。

---

## 始め方：`/init` コマンド

ゼロから書くのは大変なので、`/init` コマンドで雛形を生成する。

```
/init
```

Claudeがプロジェクトを分析して、ビルドシステム、テストフレームワーク、コードパターンなどを検出し、CLAUDE.mdの雛形を作ってくれる。

:::message
**ポイント**
`/init` で生成された内容をそのまま使うのではなく、自分のプロジェクトに合わせて調整する。
:::

---

## 何を書くべきか

### 書くべきもの

| カテゴリ | 例 |
|---------|-----|
| Claudeが推測できないコマンド | `npm run dev:local`（独自スクリプト） |
| デフォルトと異なるコードスタイル | 「セミコロンは付けない」「シングルクォートを使う」 |
| テストの実行方法 | `npm test -- --watch` |
| リポジトリのルール | 「ブランチ名は feature/xxx 形式」「PRは日本語で書く」 |
| プロジェクト固有の設計判断 | 「状態管理はReduxではなくZustandを使う」 |
| 開発環境の癖 | 「.env.local が必要」「Docker が必要」 |
| よくある落とし穴 | 「このAPIは非推奨。代わりに〇〇を使う」 |

### 書くべきでないもの

| カテゴリ | 理由 |
|---------|------|
| コードを読めば分かること | 冗長。コンテキストを消費するだけ |
| 言語の標準的な規約 | Claudeは既に知っている |
| 詳細なAPIドキュメント | リンクで済ませる |
| 頻繁に変わる情報 | メンテナンスが大変 |
| ファイルごとの説明 | Claudeはコードを読める |
| 「きれいなコードを書け」のような自明なこと | 書かなくてもやる |

---

## 実例：シンプルなCLAUDE.md

```markdown
# コードスタイル
- ES Modules（import/export）を使う。CommonJS（require）は使わない
- インポートは分割代入を使う（例：import { foo } from 'bar'）

# ワークフロー
- コード変更後は必ず型チェックを実行する
- テストは個別に実行する（全体実行は遅いため）

# コマンド
- 開発サーバー: npm run dev
- 型チェック: npm run typecheck
- テスト（単体）: npm test -- path/to/test.ts
```

**ポイント**：
- 短い（20行以内が理想）
- 具体的
- Claudeが間違えそうなことだけ書く

---

## CLAUDE.md の配置場所

複数の場所に配置できる。

| 場所 | 用途 |
|------|------|
| `~/.claude/CLAUDE.md` | 全プロジェクト共通のルール |
| `./CLAUDE.md` | このプロジェクトのルール（Git管理推奨） |
| `./CLAUDE.local.md` | 個人的な設定（.gitignoreに追加） |
| `./subdir/CLAUDE.md` | サブディレクトリ固有のルール |

**読み込み順**：ホーム → 親ディレクトリ → プロジェクトルート → 子ディレクトリ

---

## 他のファイルを参照する

`@` 記法で他のファイルを参照できる。

```markdown
プロジェクトの概要は @README.md を参照。
npm コマンドは @package.json を参照。

# 追加の指示
- Git ワークフロー: @docs/git-workflow.md
- 個人設定: @~/.claude/my-overrides.md
```

これにより、CLAUDE.md自体を短く保ちつつ、必要な情報を参照できる。

---

## よくある失敗：長すぎるCLAUDE.md

### 問題

CLAUDE.mdが長すぎると、**Claudeは内容を無視する**。

重要なルールが大量の文章に埋もれ、結果として守られない。

### 対策

各行について問いかける：

> 「この行を削除したら、Claudeは間違えるか？」

答えが「No」なら、削除する。

### 目安

- 理想：20行以内
- 許容：50行以内
- 危険：100行以上

---

## うまくいかない時のデバッグ

### Claudeがルールを無視する

**原因1**：CLAUDE.mdが長すぎる
→ 短くする。本当に必要な情報だけ残す。

**原因2**：表現が曖昧
→ 具体的に書く。「きれいなコードを書け」ではなく「関数は20行以内にする」。

**原因3**：強調が足りない
→ 重要なルールには「IMPORTANT」「必ず」などを付ける。

### Claudeが同じ質問を繰り返す

**原因**：CLAUDE.mdに答えが書いてあるが、表現が分かりにくい
→ より直接的な表現に書き換える。

---

## 応用：チームで共有する

CLAUDE.mdをGitにコミットすると、チーム全員で共有できる。

```
project/
├── CLAUDE.md           ← チーム共有（Gitにコミット）
├── CLAUDE.local.md     ← 個人設定（.gitignoreに追加）
└── ...
```

`.gitignore`:
```
CLAUDE.local.md
```

**チーム共有のメリット**：
- 新メンバーがClaude Codeを使い始めても、プロジェクトのルールが適用される
- 「このプロジェクトでは〇〇を使う」という暗黙知を明文化できる

---

## Skills（スキル）との使い分け

CLAUDE.mdは**毎回読み込まれる**。

一方、**Skills**は必要な時だけ読み込まれる。

| | CLAUDE.md | Skills |
|--|-----------|--------|
| 読み込み | 毎回 | 必要な時だけ |
| 用途 | 常に適用するルール | 特定の作業に必要な知識 |
| 例 | コードスタイル、テストコマンド | APIの使い方、特定機能の実装手順 |

**使い分け**：
- 「どんな作業でも守ってほしいルール」→ CLAUDE.md
- 「特定の作業でだけ必要な知識」→ Skills

---

## まとめ

| ポイント | 内容 |
|---------|------|
| 目的 | コードを見ただけでは分からない情報を伝える |
| 始め方 | `/init` で雛形を生成 |
| 書くべきもの | 独自コマンド、スタイルルール、落とし穴 |
| 書くべきでないもの | コードを読めば分かること、自明なこと |
| 長さ | 短く（20行以内が理想） |
| 配置 | プロジェクトルートに置いてGit管理 |

**覚えておくこと**：

> CLAUDE.mdが長すぎると、Claudeはルールを無視する。
> 短く、具体的に、本当に必要なことだけ書く。

---

## 次の記事

第4部「効果的なプロンプト術」では、Claudeに的確に指示を伝える方法を解説する。

---

## 参考

- [CLAUDE.md - Claude Code Docs（公式）](https://code.claude.com/docs/en/memory)
- [Best Practices - Claude Code Docs（公式）](https://code.claude.com/docs/en/best-practices)

---

## 関連記事

- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ：使いこなすためのTips](claude-code-tips-and-features)
- [Claude Code が動かない時に見るページ（Windows）](claude-code-windows-troubleshoot)
