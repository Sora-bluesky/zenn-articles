---
title: "Claude Code Orchestraをカスタマイズして情報発信CLIを作ってみた"
emoji: "🎼"
type: "tech"
topics: ["claudecode", "ai", "生成ai", "cli", "notion"]
published: false
---

:::message
**この記事の対象読者**: Claude Codeを使ったことがあり、さらに活用したい中級者向け。
**動作環境**: Windows + Claude Code 1.0以上
:::

## はじめに

AIにコードを書かせた後、毎回別のターミナルでレビューを回すの、面倒じゃないですか？

「ここでCodexにレビューさせたいな」と思っても、手動でコマンドを叩く必要がある。もっと自動化できないか。

そんなとき、「Claude Code Orchestra」という記事を見つけました。

**3エージェント協調**（Claude Code、OpenAI Codex、Google Geminiの3つのAIが連携する環境）。**Hooks**（特定の操作をきっかけに自動で処理を実行する仕組み）による自動提案。これを自分のプロジェクトにも導入したい。

でも、参考記事をそのまま使うだけでなく、**自分なりにカスタマイズして、実際にツールを作ってみよう**。

この記事では、Orchestra環境をカスタマイズしながら、実際に「情報発信パイプライン管理CLI」を作った過程を紹介します。

## 前提条件

:::message alert
**必要なツール**
- **Claude Code**: Anthropicの公式CLI（`npm install -g @anthropic-ai/claude-code`）
- **Codex CLI**: OpenAIの推論特化CLI（OpenAI APIキーが必要、課金あり）
- **Gemini CLI**: Googleの大規模リサーチ向けCLI（Googleアカウントで認証、無料枠あり）
:::

## 参考記事

今回参考にした2つの記事です。

### Claude Code Orchestra（松尾研究所 Taisei Ozaki氏）

https://zenn.dev/mkj/articles/claude-code-orchestra_20260120

3エージェント協調の基本設計。Hooks 6ファイル + 設定 6ファイル = 12ファイル構成。

### Claude Code Hooksの深い活用（ZAICO）

https://zenn.dev/zaico/articles/d6b882c78fe4b3

状態永続化、自己修正メカニズムなど、Hooksの実践的な活用法。

## 自分なりのカスタマイズ

参考記事をベースに、2つの工夫を加えました。

### 工夫1: オートレビュー機能の追加

参考記事では、レビューは手動で `/review` を実行する想定でした。でも、別タブでレビューを回すのは面倒。

そこで、**ファイルを保存するたびに自動で変更回数をカウントし、一定回数（デフォルト3回）を超えたらCodexで自動レビュー**する仕組みを追加しました。

やっていること：
1. ファイル変更のたびにカウンターを増加
2. 閾値を超えたらCodexでコードレビューを実行
3. 重大な問題（blocking）があれば自動修正を試みる

```python
# auto-review-fix.py（抜粋）
def main():
    # 変更カウンター
    state["change_count"] += 1

    if state["change_count"] >= threshold:
        # 閾値超え → Codexでレビュー実行
        print(f"🔍 {state['change_count']}回変更検出。Codexでレビュー中...")

        has_blocking, review_result = run_codex_review()

        if has_blocking and auto_fix_enabled:
            # blocking問題を自動修正（最大3回ループ）
            for i in range(max_fix_loops):
                if run_codex_fix(review_result):
                    # 再レビューで問題なければ完了
                    ...
```

設定ファイルでモードを選択できます。

```json
// .orchestra/config.json
{
  "auto_review": {
    "enabled": true,
    "change_threshold": 3,
    "auto_fix_enabled": true,  // false: 通知のみ
    "max_fix_loops": 3
  }
}
```

### 工夫2: スキル自動生成の追加

参考記事はHooks中心（12ファイル）でしたが、開発フロー系のスキルも欲しい。

そこで、**`/orchestra` 実行時に開発フロー系スキル6つも自動生成**するよう拡張しました。

| スキル | 役割 |
|--------|------|
| `/startproject` | マルチエージェント協調でプロジェクト開始 |
| `/tdd` | テスト駆動開発ワークフロー |
| `/checkpointing` | セッションコンテキストの永続化 |
| `/research-lib` | ライブラリ調査・ドキュメント作成 |
| `/codex-system` | Codex CLI連携 |
| `/gemini-system` | Gemini CLI連携 |

結果、**12ファイル → 18ファイル**に拡張。プロジェクトローカルに生成されるので、プロジェクトごとにカスタマイズできます。

## 実践: 情報発信CLIツールを作る

カスタマイズしたOrchestra環境で、実際にツールを作ってみました。

### 作るもの: publine

Notionで管理している原稿を、X / Zenn / note 向けに変換・管理するCLIツール。

```bash
# 原稿一覧を表示
publine list --status ready

# 原稿をX形式に変換
publine convert <id> --platform x

# ステータスを更新
publine status <id> --set published
```

### セットアップ

まず `/orchestra` でOrchestra環境をセットアップ。

:::message
**`/orchestra` とは**: この記事で作成した自作スキル（Claude Codeのカスタムコマンド）です。Hooksと設定ファイルを一括生成します。スキルの作り方は[公式ドキュメント](https://code.claude.com/docs/en/skills)を参照。
:::

```
✅ Orchestra セットアップ完了！

生成されたファイル（18ファイル）:

📁 Hooks（6ファイル）:
  - .claude/hooks/session-start.py
  - .claude/hooks/session-stop.py
  - .claude/hooks/agent-router.py
  - .claude/hooks/check-codex-before-write.py
  - .claude/hooks/auto-review-fix.py
  - .claude/hooks/suggest-gemini-research.py

📁 開発フロー系スキル（6ディレクトリ）:
  - .claude/skills/codex-system/SKILL.md
  - .claude/skills/gemini-system/SKILL.md
  - .claude/skills/startproject/SKILL.md
  - .claude/skills/tdd/SKILL.md
  - .claude/skills/checkpointing/SKILL.md
  - .claude/skills/research-lib/SKILL.md

📁 設定・ドキュメント（6ファイル）:
  - .claude/settings.local.json
  - .orchestra/config.json
  - .orchestra/mission.md
  - .codex/AGENTS.md
  - .gemini/GEMINI.md
  - CUSTOMIZE.md
```

### 技術選定（Geminiリサーチ）

`/startproject` で開始すると、Geminiがライブラリ調査を実行。

```
💡 提案: 「調査」を検出。調査・分析タスクにはGemini CLIが適しています。
```

結果、以下の技術スタックを採用しました。

| 用途 | ライブラリ |
|------|-----------|
| CLIフレームワーク | commander.js |
| Notion API | @notionhq/client |
| Markdown変換 | notion-to-md, remark |
| 表示 | chalk, ora |

### 設計レビュー（Codex連携）

設計を固めたら、Codexでレビュー。

```
💡 大きな変更を検出しました。
   Codexで設計レビューを行うことを推奨します:
   codex "この変更の設計をレビューして"
```

ADR（設計決定を記録する形式）で技術選定の理由を記録しました。

```markdown
# ADR-001: CLIフレームワーク選定

**決定**: commander.js を採用

**理由**:
- TypeScriptサポート良好
- 宣言的なコマンド定義
- サブコマンド対応

**却下案**: yargs（設定が冗長）、oclif（オーバースペック）
```

### 実装

主要な機能を実装しました。

**1. Notion連携（原稿管理）**

```typescript
// 原稿一覧を取得
const articles = await notionService.listArticles({
  status: 'ready',
  limit: 10,
});

// 原稿を取得（マークダウン変換込み）
const article = await notionService.getArticle(pageId);
```

**2. X形式変換**

```typescript
// マークダウンをX用に変換
const thread = await xConverter.convert(markdown);

// スレッド分割（280文字制限対応）
for (const post of thread.posts) {
  console.log(`ポスト ${post.index}/${thread.totalPosts}`);
  console.log(post.content);
}
```

変換ルール:

| Markdown | X形式 |
|----------|--------|
| `# 見出し` | 【見出し】 |
| `- item` | ・item |
| `> quote` | 「quote」 |

**3. ステータス管理**

```typescript
// ステータスを更新
await notionService.updateStatus(pageId, 'published');

// 公開プラットフォームを追加
await notionService.addPublishedPlatform(pageId, 'x');
```

### オートレビューが発火

実装中、3回目のファイル変更で自動レビューが発火しました。

```
🔍 3回変更検出。Codexでレビュー中...
✅ blocking問題なし
```

blocking問題がなければサイレントに完了。問題があれば自動修正を試みます。

## 完成したCLIツール

### コマンド一覧

```bash
# 原稿一覧
publine list
publine list --status ready
publine list --tag ai

# 原稿取得
publine fetch <id>

# プラットフォーム変換
publine convert <id> --platform x      # X形式
publine convert <id> --platform zenn   # Zenn形式
publine convert <id> --platform note   # note形式
publine convert <id> -p x -o output.txt  # ファイル出力

# ステータス更新
publine status <id> --set ready
publine status <id> --set published

# 公開記録
publine publish <id> --platform x
```

### 実行例

```bash
$ publine convert abc123 --platform x

# Claude Code Orchestra をカスタマイズして...
→ X形式に変換 (3 ポスト)

── ポスト 1/3 (267文字) ──

Claude Code Orchestraという記事を読んで、衝撃を受けました。

3エージェント協調。Hooksによる自動提案。
これを自分のプロジェクトにも導入したい。

でも、そのまま使うだけでは面白くない。
自分なりにカスタマイズして、実際にツールを作ってみよう。

🧵 1/3

...
```

## まとめ

### カスタマイズの価値

参考記事をそのまま使うだけでなく、**自分なりにカスタマイズ**することで：

- 自分のワークフローに合った環境が作れる
- 仕組みを深く理解できる
- 次のカスタマイズのアイデアが湧く

### 気づいたこと

1. **オートレビューは便利**
   - 別タブで `/review` を回す手間がなくなった
   - blocking問題だけ自動で検出・修正してくれる

2. **スキルはプロジェクトローカルがいい**
   - グローバルに置くとカスタマイズしにくい
   - プロジェクトごとに調整できる方が柔軟

3. **Hooksは控えめに**
   - 過剰な自動化は邪魔になる
   - 「提案のみ」がちょうどいい

### 次に試したいこと

- Obsidian MCPとの連携
- X APIによる直接投稿
- GitHub Actionsでの自動公開

## やってみたい人へ

1. [Claude Code Orchestra (GitHub)](https://github.com/DeL-TaiseiOzaki/claude-code-orchestra) をclone
2. `.claude/hooks/` 配下のスクリプトを自分のプロジェクトにコピー
3. `.claude/settings.local.json` にHooks設定を追加
4. Claude Codeを再起動してHooksを有効化

詳細な設定方法は[Claude Code Hooks 公式ドキュメント](https://code.claude.com/docs/en/hooks)を参照してください。

## 関連リンク

- [Claude Code Orchestra (GitHub)](https://github.com/DeL-TaiseiOzaki/claude-code-orchestra)
- [Claude Code Hooks 公式ドキュメント](https://code.claude.com/docs/en/hooks)
- [Claude Code Skills 公式ドキュメント](https://code.claude.com/docs/en/skills)
