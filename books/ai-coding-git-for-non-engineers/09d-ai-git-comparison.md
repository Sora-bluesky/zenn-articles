---
title: "AI ツール別 Git 操作対応表"
---

## この章のゴール

> この章を終えると、主要な AI コーディングツールが Git のどの操作を自動でやってくれるかがわかり、自分が使うツールで「何を手動でやるべきか」が判断できるようになる。

## はじめに

AI コーディングツールによって、Git との関わり方は大きく異なる。「AI が全部やってくれる」ツールもあれば、「コードは AI、Git は自分で」というツールもある。

自分が使うツールがどこまでやってくれるかを知っておくと、作業の見通しが立てやすい。

:::message
ここで紹介する内容は 2026 年 4 月時点の情報である。AI ツールの進化は速いため、最新の仕様は各ツールの公式ドキュメントで確認してほしい。
:::

---

## メイン対応表

| Git 操作 | Claude Code | Google Antigravity | Codex | GitHub Copilot | Cursor |
|---------|------------|-------------------|-------|---------------|--------|
| リポジトリ作成（`git init`） | 不要（既存前提） | 不要（既存前提） | 不要（既存前提） | 不要（既存前提） | 不要 |
| `add` + `commit` | 自動（承認待ち） | 自動（承認待ち） | 自動 | 手動 | 手動 |
| `push` | 自動 or 手動 | 自動 or 手動 | 自動 | 手動 | 手動 |
| ブランチ作成 | 自動 | 自動 | 自動 | 手動 | 手動 |
| PR 作成 | 自動（`gh` 経由） | 手動（GitHub MCP 経由で自動化可能） | 自動 | 手動 | 手動 |
| コンフリクト解消 | 対話的に支援 | 対話的に支援 | -- | 手動 | AI 支援あり |
| `.gitignore` 生成 | 頼めば作る | 頼めば作る | -- | 提案あり | 提案あり |

表の見方:
- **自動** = AI が判断して勝手にやってくれる
- **自動（承認待ち）** = AI が実行するが、実行前に「いいですか？」と確認が入る
- **手動** = 自分で操作する必要がある
- **対話的に支援** = AI がやり方を教えてくれるが、最終操作は人間が承認する
- **頼めば作る** = 日本語で指示すれば生成してくれる
- **--** = 対応していない、または該当しない

---

## ツールごとの特徴

### Claude Code

ターミナルで動く AI コーディングツール。本書の[第 8 章](08-claude-code-practice)で実践した。

Git との統合が最も深い。コードを書くだけでなく、`add`、`commit`、`push`、ブランチ作成、PR 作成まで一気通貫で実行できる。ただし、コミットや push の前には必ず「この内容で実行していいですか？」と確認が入る。勝手に push されることはない。

日本語で「この変更をコミットして」「PR を作って」と頼めばよい。

:::message
**公式ドキュメント**
- [English: Claude Code](https://code.claude.com/docs/en)
- [日本語: Claude Code](https://code.claude.com/docs/ja)
:::

### Google Antigravity

Google の AI コーディングツール。Gemini をベースにしており、Claude Code と似た操作感を持つ。

Git 操作の自動化レベルは Claude Code と同等で、`add`、`commit`、ブランチ作成を自動で行う。ルールファイルは2種類ある。

- **GEMINI.md** ── Antigravity 固有の設定ファイル。`~/.gemini/GEMINI.md` にグローバル設定、プロジェクトルートにプロジェクト設定を配置する（Claude Code の `CLAUDE.md` に相当）
- **AGENTS.md** ── クロスツール共有用のルールファイル。Claude Code や Cursor など他のツールからも読み込まれる

ワークスペース固有のルールは `.agents/rules/` ディレクトリに配置できる。

:::message
**公式ドキュメント**
- [English: Google Antigravity](https://antigravity.google/docs)
:::

### Codex（OpenAI）

OpenAI が提供する AI コーディングツール。Web 版と CLI 版の2種類がある。

- **Codex Web**（chatgpt.com/codex）: GitHub リポジトリに接続し、サンドボックス環境でコードを変更。完了後に PR を自動作成する。コードレビュー → マージは人間が判断
- **Codex CLI**（`npm install -g @openai/codex` または `brew install codex`）: ローカルで動作。ファイル編集は自動だが、Git 操作（commit, push）はユーザーのワークフローに委ねる

:::message
上の対応表は Codex Web の場合。CLI 版は Git 操作がユーザー任せになる。
:::

:::message
**公式ドキュメント**
- [English: OpenAI Codex](https://openai.com/index/openai-codex/)

日本語版はないが、ブラウザの翻訳機能で日本語に変換して読める。
:::

### GitHub Copilot

GitHub Copilot は2つの顔を持つ。VS Code 内の **Agent Mode** はリアルタイムのコード補完・編集支援が中心で、Git 操作は手動。一方 **Coding Agent**（クラウド版）は Issue を割り当てるだけで、ブランチ作成から PR 作成まで全自動で完了する。

**Agent Mode（VS Code 内）では Git 操作は自分で行う必要がある。** `commit` や `push` は VS Code の画面操作か CLI で自分で実行する。本書で学んだ Git 操作がそのまま活きる。

:::message
### GitHub Copilot の2つのモード
- **Agent Mode（VS Code 内）**: リアルタイムでコード編集を支援。Git 操作（commit, push）は手動
- **Coding Agent（クラウド版）**: Issue を割り当てると、ブランチ作成 → コード変更 → テスト → PR 作成まで全自動で完了する

上の対応表は Agent Mode（VS Code 内）の場合。Coding Agent を使う場合は、Claude Code や Codex Web と同等の自動化が可能。
:::

:::message
**公式ドキュメント**
- [English: GitHub Copilot](https://docs.github.com/en/copilot)
- [日本語: GitHub Copilot](https://docs.github.com/ja/copilot)
:::

### Cursor

VS Code をベースにした AI エディタ。見た目も操作感も VS Code とほぼ同じだが、AI によるコード編集・生成機能が組み込まれている。

Git 操作は VS Code の GUI（画面上のボタン操作）をそのまま使う。AI がコンフリクト解消を支援してくれる機能はあるが、`commit` や `push` は手動だ。

:::message
**公式ドキュメント**
- [English: Cursor](https://docs.cursor.com/)

日本語版はないが、ブラウザの翻訳機能で日本語に変換して読める。
:::

---

## 「手動」のツールでも Git の知識は無駄にならない

対応表を見ると、Claude Code や Google Antigravity は「ほぼ全自動」に見える。「じゃあ Git を覚えなくてもいいのでは？」と思うかもしれない。

そうではない。

自動化ツールが実行する操作は、本書で学んだ Git コマンドそのものだ。AI が「`git push origin main` を実行します。よろしいですか？」と聞いてきたとき、その意味がわからなければ判断のしようがない。

逆に、GitHub Copilot や Cursor のような「Git は手動」のツールでは、本書の知識がそのまま日常の操作になる。

どのツールを使うにせよ、Git の基本を理解していることが安全な AI コーディングの土台になる。

---

## ツール選びの判断基準

「どのツールを使えばいいか」は目的によって変わる。

| 目的 | 向いているツール |
|------|---------------|
| ターミナルから一気通貫で開発したい | Claude Code、Google Antigravity |
| コードの自動生成を PR で受け取りたい | Codex |
| VS Code でコード補完しながら書きたい | GitHub Copilot |
| VS Code ベースで AI 編集機能がほしい | Cursor |
| Git 操作を AI に任せたい | Claude Code、Google Antigravity、Codex |
| Git 操作は自分でやりたい | GitHub Copilot、Cursor |

本書では Claude Code を使って実践したが、Git の基本操作は全ツール共通である。ツールを乗り換えても、ここまでの知識は無駄にならない。

:::message
**公式ドキュメントまとめ**
- [Claude Code（日本語）](https://code.claude.com/docs/ja)
- [Google Antigravity](https://antigravity.google/docs)
- [OpenAI Codex](https://openai.com/index/openai-codex/)
- [GitHub Copilot（日本語）](https://docs.github.com/ja/copilot)
- [Cursor](https://docs.cursor.com/)
:::
