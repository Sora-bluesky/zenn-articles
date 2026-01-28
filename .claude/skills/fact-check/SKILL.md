---
name: fact-check
description: 調査結果を公式ドキュメント・公式ベストプラクティスと照合するファクトチェックスキル。rmos-researcherが調査完了後に必ず実行する。「ファクトチェック」「公式確認」「ソース検証」というキーワードで呼び出す。
---

# ファクトチェックスキル

## Overview

調査・検証で得た情報を、公式ドキュメントや公式ベストプラクティスと照合し、正確性を担保する。
rmos-researcher の調査完了時に必ず実行するフェーズ。

## Instructions

### Step 1: 公式ソースの特定

調査対象のツール・サービスに対し、以下の公式ソースを特定する：

| ソース種別 | 例 | 優先度 |
|-----------|-----|--------|
| 公式ドキュメント | docs.example.com, example.com/docs | 最高 |
| 公式ブログ | blog.example.com, developers.example.com/blog | 高 |
| 公式GitHub | github.com/official-org | 高 |
| 公式Codelabs/チュートリアル | codelabs.example.com | 高 |
| 公式リリースノート | releases, changelog | 中 |
| 公式フォーラム（運営回答） | discuss.example.com（運営の回答のみ） | 中 |

**非公式ソース**（個人ブログ、Qiita、Medium、Reddit等）は補足情報としてのみ使用し、事実の根拠としない。

### Step 2: 主要クレームの抽出

調査結果から、記事に記載する予定の **事実に基づくクレーム（主張）** を抽出する。

チェック対象：
- 機能の有無・動作仕様
- 料金・プラン情報
- 制限事項（レート制限、ファイルサイズ等）
- サポート対象OS・バージョン
- セキュリティ関連の仕様
- 比較情報（他ツールとの違い）

### Step 3: 公式ソースとの照合

各クレームについて、以下のいずれかに分類する：

| 分類 | 意味 | 対応 |
|------|------|------|
| ✅ 公式確認済み | 公式ドキュメントに記載あり | そのまま使用。公式URLを記録 |
| ⚠️ 公式に記載なし | 公式ドキュメントに該当情報なし | 「公式には明記されていない」と注記。情報源を明記 |
| ❌ 公式と矛盾 | 公式ドキュメントと異なる情報 | 公式の情報を優先。矛盾がある旨を記録 |
| 🔄 情報が古い可能性 | 公式の更新日が古い、または最近変更された可能性 | 「YYYY年MM月時点」と日付を明記 |

### Step 4: 日本語公式ソースの確認

英語の公式ドキュメントに加え、日本語の公式ソースも確認する：

| 確認先 | 例 |
|--------|-----|
| 公式日本語ドキュメント | docs.example.com/ja, example.com/docs/ja |
| 公式日本語ブログ | developers-jp.example.com |
| 日本法人の公式発表 | example.co.jp |
| 公式日本語YouTube | 公式チャンネルの日本語動画 |

日本語ソースが存在する場合は、英語ソースと併記する。

### Step 5: ファクトチェックレポートの作成

以下のフォーマットで結果を出力する：

```markdown
## ファクトチェックレポート

### 確認済みクレーム

| # | クレーム | 公式ソース | URL |
|---|---------|-----------|-----|
| 1 | {主張内容} | {ソース名} | {URL} |

### 未確認・要注意クレーム

| # | クレーム | 状況 | 対応 |
|---|---------|------|------|
| 1 | {主張内容} | ⚠️ 公式に記載なし | {推奨対応} |

### 公式ソース一覧

#### 英語
- [{ドキュメント名}]({URL})

#### 日本語
- [{ドキュメント名}]({URL})
```

### Step 6: 記事への反映

ファクトチェック結果に基づき、以下を記事に反映する：

1. **公式確認済みの情報**: そのまま記載。公式URLを参考リンクに追加
2. **未確認の情報**: 「公式には明記されていないが、ユーザー報告に基づく」等の注記を追加
3. **矛盾する情報**: 公式の情報を優先し、非公式情報は参考として補足
4. **日付の明記**: 変動しやすい情報（料金、制限値等）には「YYYY年MM月時点」を付記

## 主要ツールの公式ソース一覧

### Google Antigravity

| ソース | URL | 言語 |
|--------|-----|------|
| 公式サイト | https://antigravity.google | EN |
| 公式ドキュメント | https://antigravity.google/docs | EN |
| Google Developers Blog | https://developers.googleblog.com | EN |
| Google Codelabs | https://codelabs.developers.google.com | EN |
| Google AI Developers Forum | https://discuss.ai.google.dev | EN |
| Google Bug Hunters | https://bughunters.google.com | EN |

### Claude Code

| ソース | URL | 言語 |
|--------|-----|------|
| 公式ドキュメント | https://code.claude.com/docs/en | EN |
| 公式ドキュメント（日本語） | https://code.claude.com/docs/ja | JA |
| Anthropic Engineering Blog | https://www.anthropic.com/engineering | EN |
| Anthropic News | https://www.anthropic.com/news | EN |

### OpenAI Codex CLI

| ソース | URL | 言語 |
|--------|-----|------|
| GitHub | https://github.com/openai/codex | EN |
| OpenAI Docs | https://platform.openai.com/docs | EN |

## Constraints

- 公式ソースが見つからない場合でも「確認できなかった」と正直に報告する
- 非公式ソースの情報を公式として偽らない
- 公式ドキュメントがSPA（JavaScript動的レンダリング）で取得できない場合は、その旨を記録し、Google Codelabs や公式ブログなどの代替ソースで確認する
- 料金・制限値など変動しやすい情報は必ず日付を明記する
- 日本語の公式ソースが存在しない場合は「日本語の公式ドキュメントは未提供」と明記する
