---
title: "過去の失敗を自動で次に活かす ── 振り返りを横断分析する「学びの継承」スキル"
emoji: "📊"
type: "tech"
topics: ["ai", "生成ai", "個人開発", "googleantigravity", "llm"]
published: false
---

## Before：基本編だけだと「やりっぱなし」

![基本編：一気通貫で終わり](/images/workflow-before.png)

## After：発展編で「好循環」に

![発展編：好循環サイクル](/images/workflow-after.png)

---

## はじめに

3つ目のプロジェクトを始めた。

また要件定義で苦労している。

---

「あれ、前回も同じところで詰まった気がする...」

振り返りレポートは書いた。でも、見返していない。

---

「API連携、前回どうやって解決したっけ？」

探すのが面倒で、また一から調べ直している。

---

振り返りを書いても、 **次に活かせていない**。

本記事では、 **複数プロジェクトの振り返りを自動で分析し、新プロジェクト開始時に提言してくれるスキル** を紹介する。

:::message
本記事は「非エンジニアのためのAIチーム開発」シリーズの発展編。
基本編（00-05）を完了してから読むことを推奨。
- 基本編: [「AIへの指示が難しい」を解決する](antigravity-noneng-workflow-overview)
- 前提: [振り返りスキル](antigravity-retrospective-skill)
:::

## 前提条件

- Google Antigravity インストール済み
  - まだの場合 → [Antigravityインストールガイド](antigravity-windows-install-guide)
- 基本編のワークフロー・スキルを導入済み
- **2つ以上のプロジェクトを完了している**（振り返りデータが必要）

## 解決策：学びの継承スキル

### コンセプト

**振り返りレポートを自動で集約・分析し、新プロジェクト開始時に過去の学びを提言する。**

```
プロジェクトA完了 → 振り返りレポート → .insights/ に自動コピー
プロジェクトB完了 → 振り返りレポート → .insights/ に自動コピー
プロジェクトC完了 → 振り返りレポート → .insights/ に自動コピー
        ↓
新プロジェクト開始（/team）
        ↓
AI: 過去3件のプロジェクトから以下の傾向があります：
    - 苦労フェーズ: 実装（3件中2件）
    - よくある問題: API連携で苦戦
    
    💡 提言: API連携がある場合は設計段階でプロトタイプを作る
```

### 3つの機能

| 機能 | 説明 | タイミング |
|------|------|-----------|
| 収集 | 振り返りレポートを `.insights/` にコピー | プロジェクト完了時（自動） |
| 分析 | 傾向を抽出（苦労フェーズ、よくある問題、成功パターン） | `/team` 実行時（自動） |
| 提言 | 過去の学びを新プロジェクトに反映 | Phase 0 で表示 |

## ファイル構成

```
projects/
├── .insights/                    ← 横断分析用フォルダ
│   ├── retrospectives/           ← 振り返りレポート集約
│   │   ├── 2026-01-expense-manager.md
│   │   ├── 2026-01-customer-bot.md
│   │   └── ...
│   ├── patterns.md               ← 傾向分析結果
│   └── checklist.md              ← 過去の学びから生成したチェックリスト
│
├── expense-manager/
│   └── docs/RETROSPECTIVE.md     ← プロジェクト固有
│
└── skills/
    ├── insights/
    │   └── SKILL.md              ← 学びの継承スキル
    └── retrospective/
        └── SKILL.md              ← 振り返りスキル（更新版）
```

:::message
**名称は自由に変更可能**: `.insights/` や `skills/insights/` はAntigravityの機能名ではなく、自分で決めた名前。`.learnings/` や `skills/knowledge/` など、好みに合わせて変更してよい。
:::

## ワークフローの変化

### Before（基本編）

```
/team 実行
    ↓
Phase 1: 要件定義
    ↓
Phase 2〜6: ...
```

### After（発展編）

```
/team 実行
    ↓
Phase 0: 過去の学びを確認 ← 新規追加
    ↓
Phase 1: 要件定義
    ↓
Phase 2〜6: ...
    ↓
振り返り完了時: .insights/ に自動コピー ← 新規追加
```

## デモ：Phase 0 の動作

![Phase 0 の分析結果](/images/insights-phase0.png)
*過去3件のプロジェクトを自動分析し、傾向と具体的な提言を表示。*

```
ユーザー: /team

AI: 🚀 AIチーム開発ワークフロー開始

📊 過去のプロジェクトからの学び

過去 3件 のプロジェクトを分析した結果：

【苦労フェーズの傾向】
| フェーズ | 回数 | 割合 |
|----------|------|------|
| 🔴 実装 | 2 | 67% |
| 🟡 要件定義 | 1 | 33% |

→ 実装フェーズで苦労しがち。

⚠️ 注意すべき点（よくある問題）

1. API連携・外部ライブラリで苦戦（2件で言及）
   - Google Drive API、PDF生成ライブラリで予想外の工数
   - 対策: 設計段階でプロトタイプを作る

2. テストが後回しになる（2件で言及）
   - 最後にバグが多数発覚
   - 対策: テスト駆動開発を意識する

3. スケジュール遅延（2件で「やや遅れ」）
   - 外部連携がある場合は工数を1.5倍で見積もる

✅ これまでうまくいった方法（成功パターン）

1. 設計書を詳細に書くと実装がスムーズ（3件中2件で言及）
2. 5つの質問で要件が明確になった（2件で言及）
3. 設計段階でプロトタイプを作ると不確実性が減る（1件で言及）

📋 今回のプロジェクトへの提言

- 外部APIや新しいライブラリを使う場合は、設計段階でプロトタイプを作る
- 実装と並行してテストを書くことを意識する
- 外部連携がある場合は工数を1.5倍で見積もる

これらを意識して進めますか？
- はい → Phase 1（要件定義）へ進みます
- チェックリストを見る → .insights/checklist.md を表示します
- スキップ → 過去の学びを無視して開始します

ユーザー: はい

AI: Phase 1: 要件定義 に進みます。
    何を作りますか？
```

**ポイント**:
- 過去3件の振り返りから傾向を自動抽出
- 「実装で苦労しがち」「API連携で苦戦」などの具体的な傾向
- 「設計書を詳細に書く」「プロトタイプを作る」などの成功パターン
- 今回のプロジェクトへの具体的な提言

## 振り返りレポートのフォーマット

学びの継承スキルが分析しやすいよう、振り返りレポートにYAML frontmatterを追加した。

```yaml
---
project: expense-manager
date: 2026-01-26
satisfaction: B
hardest_phase: C
timeline: C
tags:
  - GAS
  - 経費精算
  - API連携
---

# 振り返りレポート

## Keep（良かった点）
- 設計書が明確で実装がスムーズだった

## Problem（問題点）
- API連携で苦戦した

## Try（次回試したいこと）
- API連携は設計段階でプロトタイプを作る
```

| フィールド | 値 | 意味 |
|-----------|-----|------|
| satisfaction | A/B/C/D | A=期待以上, B=期待通り, C=やや不満, D=不満 |
| hardest_phase | A/B/C/D/E | A=要件定義, B=設計, C=実装, D=レビュー, E=ドキュメント |
| timeline | A/B/C/D | A=早い, B=予定通り, C=やや遅れ, D=大幅遅れ |
| tags | リスト | 技術・ドメインのタグ |

## 分析項目

学びの継承スキルは以下の傾向を自動抽出する。

| 分析項目 | 例 |
|----------|-----|
| 苦労フェーズの傾向 | 「実装で毎回苦労している」 |
| よくある問題 | 「API連携で苦戦しがち」「テストが後回し」 |
| 成功パターン | 「設計書を詳細に書くとスムーズ」 |
| 満足度の傾向 | 「期待通りが多い」 |
| スケジュールの傾向 | 「やや遅れがち」 |

## 導入手順

### Step 1: 既存スキルの更新

Antigravityに以下を指示:

```
skills/retrospective/SKILL.md を更新してください。

【変更内容】
- 振り返りレポートにYAML frontmatterを追加
- 振り返り完了時に .insights/retrospectives/ へ自動コピー
```

### Step 2: 学びの継承スキルの作成

```
skills/insights/SKILL.md を作成してください。

【機能】
- 収集: 振り返りレポートを .insights/retrospectives/ に集約
- 分析: YAML frontmatterから傾向を抽出
- 提言: 新プロジェクト開始時に過去の学びを表示

【分析項目】
- 苦労フェーズの傾向
- よくある問題
- 成功パターン
```

### Step 3: ワークフローの更新

```
.agent/workflows/team.md を更新してください。

【変更内容】
- Phase 0「過去の学びを確認」を追加
- .insights/ がない場合はスキップ
- ある場合は分析結果を表示してから Phase 1 へ
```

### Step 4: フォルダ作成

```
.insights/retrospectives/ フォルダを作成してください。
.insights/patterns.md と .insights/checklist.md も作成してください。
```

## つまずきポイント

### 1. Phase 0 が表示されない

**問題**: `/team` を実行しても Phase 0 が表示されない。

**原因**: `.insights/retrospectives/` に振り返りレポートがない。

**解決策**: 最低2つのプロジェクトを完了させ、振り返りを書く。

### 2. 分析結果が的外れ

**問題**: 傾向分析の結果が実感と合わない。

**原因**: データが少ない（2-3件では傾向が出にくい）。

**解決策**: 5件以上のプロジェクトを完了させると精度が上がる。

### 3. 既存の振り返りが反映されない

**問題**: 以前のプロジェクトの振り返りが分析に含まれない。

**原因**: 旧フォーマット（YAML frontmatterなし）で書かれている。

**解決策**: 既存の振り返りにYAML frontmatterを追加し、`.insights/retrospectives/` に手動コピー。

## まとめ

- **振り返りを書いて終わり、にしない** — 自動で次に活かす
- プロジェクト完了時に `.insights/` へ自動集約
- `/team` 実行時に過去の傾向を自動分析
- **「また同じところで詰まった」を防ぐ**

:::message
この仕組みは「PDCAサイクル」や「継続的改善」の考え方に基づいている。
Plan（計画）→ Do（実行）→ Check（振り返り）→ Act（改善）を回し続けることで、
プロジェクトを重ねるごとにAIの提言が的確になり、開発の質が上がっていく。
:::

**振り返りは書くだけでは意味がない。次に活かして初めて価値がある。**

---

## シリーズリンク

| # | 記事 | 内容 |
|---|------|------|
| 0 | [全体像](antigravity-noneng-workflow-overview) | ワークフローで一気通貫開発 |
| 1 | [要件定義スキル](antigravity-requirements-skill) | 5つの質問で要件を引き出す |
| 2 | [設計スキル](antigravity-design-skill) | AIが選択肢を出してくれる |
| 3 | [レビュースキル](antigravity-review-skill) | AIダブルチェックで品質担保 |
| 4 | [ドキュメントスキル](antigravity-documentation-skill) | 上司報告資料まで自動生成 |
| 5 | [振り返りスキル](antigravity-retrospective-skill) | 良かった点・問題点・次やることを整理 |
| 6 | **学びの継承スキル**（本記事） | 過去の学びを自動で次に活かす |

---

## 参考リンク

- [Antigravity Skills 公式ドキュメント](https://antigravity.google/docs/skills)
- [Getting Started with Antigravity Skills（Google Codelabs）](https://codelabs.developers.google.com/getting-started-with-antigravity-skills)
- [Getting Started with Google Antigravity（Google Codelabs）](https://codelabs.developers.google.com/getting-started-google-antigravity)
