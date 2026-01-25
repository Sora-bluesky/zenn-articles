# RMOS Deep Research Protocol - Orchestration Guide

## Overview

RMOSプロトコルのオーケストレーション手順。
メインエージェントがこの手順に従い、各サブエージェントを連携させる。

## Protocol Flow

```
┌─────────────────────────────────────────────────────────┐
│ Phase 0: Exploratory Research & Selection               │
│ 実行者: メインエージェント                               │
│ 目的: 候補選定とユーザー確認                             │
└─────────────────────────────────────────────────────────┘
                          ↓ ユーザー承認後
┌─────────────────────────────────────────────────────────┐
│ Phase 1-2: Deep Investigation & Execution               │
│ 実行者: rmos-researcher (サブエージェント)               │
│ 目的: 技術検証とログ収集                                 │
└─────────────────────────────────────────────────────────┘
                          ↓ 検証結果返却
┌─────────────────────────────────────────────────────────┐
│ Phase 3: Content Generation                             │
│ 実行者: zenn-writer (サブエージェント)                   │
│ 目的: 記事ドラフト作成                                   │
└─────────────────────────────────────────────────────────┘
                          ↓ ドラフト返却
┌─────────────────────────────────────────────────────────┐
│ Phase 3.5: Quality Check                                │
│ 実行者: zenn-reviewer (サブエージェント)                 │
│ 目的: 品質確認とフィードバック                           │
└─────────────────────────────────────────────────────────┘
                          ↓ レビュー結果返却
┌─────────────────────────────────────────────────────────┐
│ Final: ユーザーへの成果物提示                            │
│ 実行者: メインエージェント                               │
└─────────────────────────────────────────────────────────┘
```

---

## Phase 0: Exploratory Research & Selection

**実行者**: メインエージェント（ユーザー対話が必要なため）

### Input
- `research_theme`: ユーザーから受け取ったテーマ
- `target_os`: 実行環境
- `article_platform`: 投稿先（Zenn / Qiita）

### Process

#### Step 1: Candidate Listing
WebSearchを使用してテーマに関連するツール/OSSを3〜5つリストアップ

```
検索クエリ例:
- "{theme} GitHub"
- "{theme} open source tool"
- "{theme} alternative comparison"
```

#### Step 2: Evaluation Matrix
各候補を以下の基準で評価：

| 基準 | 評価方法 | 重み |
|------|----------|------|
| Active | 最終更新が3ヶ月以内か | 高 |
| Popularity | Star数（急上昇中は例外許容） | 中 |
| Feasibility | `target_os` での動作可能性 | 高 |
| Documentation | README/Docs の充実度 | 中 |

#### Step 3: User Confirmation
候補リストをユーザーに提示し、確認を求める：

```markdown
## 候補ツール一覧

| # | ツール名 | Star | 最終更新 | 特徴 |
|---|---------|------|----------|------|
| 1 | xxx     | 5.2k | 2日前    | ... |
| 2 | yyy     | 3.1k | 1週間前  | ... |
| 3 | zzz     | 800  | 3日前    | ... |

**推奨**: #1 の xxx を検証対象として進めますがよろしいですか？
（#2, #3 は失敗時の代替候補として使用します）
```

### Output
- `target_repo`: 選定されたリポジトリURL
- `fallback_repos`: 次点候補のURL（2〜3個）

---

## Phase 0.5: Pre-flight Check（追加フェーズ）

**実行者**: メインエージェント

Phase 1 に進む前に、以下を確認する。

### Checklist

#### 1. 既存記事の依存関係確認
```
確認項目:
- 新記事が参照する既存記事の内容を読む
- 参照先に必要なセクションが存在するか確認
- 存在しない場合は、基盤記事の作成を先に行う
```

#### 2. 対象読者の懸念事項
```
確認項目:
- 料金体系（無料/有料、従量課金など）
- プライバシー・セキュリティ（データの扱い）
- 動作環境の制約
```

#### 3. シリーズ構成の確認
```
確認項目:
- 新記事はシリーズの何番目に位置するか
- 既存記事のシリーズ構成に新記事を追加する必要があるか
- 関連記事セクションの相互リンク
```

### ユーザー確認テンプレート

```markdown
## Phase 0.5: 事前確認

### 既存記事との関係
- 参照する既存記事: {リスト}
- 必要なセクションの存在: 確認済み / 要作成

### 対象読者への配慮
以下について記事内で触れますか？
- [ ] 料金体系
- [ ] セキュリティ・プライバシー
- [ ] 動作環境の制約

### シリーズ構成
- 新記事の位置づけ: {シリーズ名} の第{N}回
- 既存記事の更新: 必要 / 不要
```

---

## Phase 1-2: Deep Investigation & Execution

**実行者**: rmos-researcher サブエージェント

### 起動方法

Task toolを使用して rmos-researcher を起動：

```
Task tool 呼び出し:
- subagent_type: "rmos-researcher"
- prompt: 以下のパラメータを含める
```

### Prompt Template

```markdown
RMOSプロトコル Phase 1-2 を実行してください。

## Parameters
- target_repo: {選定されたリポジトリURL}
- target_os: {実行環境}
- fallback_repos: {次点候補URL、カンマ区切り}
- research_theme: {元のテーマ}

## Instructions
1. target_repo を解析し、導入計画を立てる
2. セキュリティチェックを実行する
3. 実際にインストール・動作確認を行う
4. 失敗した場合は fallback_repos で再試行（最大3回）
5. 全てのログを構造化して返却する
```

### Expected Output
rmos-researcher から以下が返却される：
- 検証結果サマリー
- セキュリティレポート
- 実行ログ
- トラブルシューティング記録
- 記事ネタメモ

---

## Phase 3: Content Generation

**実行者**: zenn-writer サブエージェント

### 起動方法

Task toolを使用して zenn-writer を起動：

```
Task tool 呼び出し:
- subagent_type: "zenn-writer"
- prompt: 以下のパラメータを含める
```

### Prompt Template

```markdown
以下の検証結果を元に、Zenn記事を作成してください。

## 記事タイトル形式
- 成功時: 「[検証] {theme}を実現するために{tool}を試してみた」
- 失敗時: 「[検証] {theme}を実現しようとして3つのツールを試した話」

## 記事構成
1. 導入: テーマと解決したい課題
2. ツール選定の過程: なぜこのツールを選んだか（比較検討）
3. 実装手順: 実際のインストール・設定手順
4. ハマりポイント: エラーと解決策
5. 結論: テーマに対する解決度合いの評価

## 検証結果データ
{rmos-researcher からの出力をここに貼り付け}

## 制約
- 非エンジニア向けに書く
- 選択肢は1つに絞る
- 具体例は初心者向け
```

### Expected Output
- 記事ドラフト（Markdown）

---

## Phase 3.5: Quality Check

**実行者**: zenn-reviewer サブエージェント

### 起動方法

Task toolを使用して zenn-reviewer を起動：

```
Task tool 呼び出し:
- subagent_type: "zenn-reviewer"
- prompt: 以下のパラメータを含める
```

### Prompt Template

```markdown
以下のZenn記事ドラフトをレビューしてください。

## 記事ドラフト
{zenn-writer からの出力をここに貼り付け}

## レビュー観点
1. 読者視点: 非エンジニアが「?」と思う箇所
2. 構成・表現: 選択肢が複数並んでいないか、前提の省略
3. Zenn仕様: Frontmatter、見出し、:::message の使い方
```

### Expected Output
- レビュー結果（問題点と改善案のリスト）

---

## Final: 成果物提示

**実行者**: メインエージェント

### Process

1. zenn-reviewer のフィードバックを記事に反映
2. 最終版をユーザーに提示
3. 必要に応じて追加修正

### Output Template

```markdown
## RMOS検証完了

### 検証結果
- テーマ: {research_theme}
- 選定ツール: {target_repo}
- 結果: 成功 / 失敗 / 部分成功

### 作成記事
{最終版記事 or ファイルパス}

### 次のステップ
- [ ] 記事内容の最終確認
- [ ] articles/ ディレクトリへの保存
- [ ] Zennへの公開
```

---

## Phase 4: Cross-article Consistency Check（追加フェーズ）

**実行者**: メインエージェント

記事公開前に、シリーズ全体の整合性を確認する。

### Checklist

#### 1. シリーズ構成の整合性
- [ ] 全記事のシリーズ構成が一致しているか
- [ ] 新記事が正しく含まれているか
- [ ] 「この記事」「前の記事」「次の記事」の表記が正しいか

#### 2. 相互リンクの確認
- [ ] 全記事の「関連記事」セクションに新記事が含まれているか
- [ ] リンク先のslugが正しいか
- [ ] リンク形式が統一されているか（相対リンク推奨）

#### 3. 回遊動線の最適化
- [ ] 「次のステップ」セクションが適切か
- [ ] 読者の自然な流れに沿った導線になっているか

#### 4. Git コミット・プッシュ確認（重要）

:::message alert
**過去の失敗事例**: 記事ファイルを作成・編集したが、Git にコミット・プッシュし忘れて公開されなかった。
:::

- [ ] `git status` で新規・修正ファイルを確認
- [ ] `git add` で対象ファイルをステージング
- [ ] `git commit` でコミット作成
- [ ] `git push` でリモートにプッシュ
- [ ] プッシュ完了メッセージを確認

#### 5. デプロイ・公開確認（必須）

- [ ] Zenn（またはデプロイ先）のデプロイ完了を確認
- [ ] 管理画面で新記事が表示されているか確認
- [ ] 公開URLにアクセスして表示を確認

### 確認コマンド例

```bash
# シリーズ構成の確認
grep -l "シリーズ構成" articles/*.md | xargs grep -A10 "シリーズ構成"

# 関連記事リンクの確認
grep -l "関連記事" articles/*.md | xargs grep -A5 "関連記事"

# Git 状態確認
git status

# 未コミットの新規ファイル確認
git status --porcelain | grep "^??"

# コミット・プッシュ（必要な場合）
git add articles/*.md
git commit -m "Add/Update articles"
git push origin main
```

### 公開完了チェックリスト

Phase 4 の全チェックが完了したら、ユーザーに以下を報告：

```markdown
## 公開完了レポート

### Git 操作
- コミット: {コミットハッシュ}
- プッシュ: 完了

### 公開された記事
| # | タイトル | slug | 状態 |
|---|---------|------|------|
| 1 | {title} | {slug} | 公開済み |

### 確認事項
- [ ] Zenn管理画面で記事が表示されることを確認してください
- [ ] 公開URLで記事が閲覧できることを確認してください
```

---

## Quick Reference: 起動プロンプト

### ユーザーからの起動例

```
RMOSプロトコルを実行してください。

テーマ: {調査したい内容}
環境: {Windows / WSL2 / macOS}
投稿先: {Zenn / Qiita}
```

### 簡略形

```
RMOS: 「{テーマ}」 / {環境} / {投稿先}
```

### 例

```
RMOS: 「MCPでファイルシステムを操作するツール」 / Windows / Zenn
```

---

## Error Handling

### Phase 0 で候補が見つからない場合
- テーマを分解して再検索
- ユーザーにテーマの具体化を依頼

### Phase 1-2 で全ツール失敗の場合
- 失敗レポートとして記事化を提案
- 「3つのツールを試して全部失敗した話」も価値あるコンテンツ

### Phase 3 で記事が長すぎる場合
- 複数記事への分割を提案
- Part 1: 選定編、Part 2: 実装編

---

## Related Resources

- エージェント定義: `.claude/agents/rmos-researcher.md`
- 品質基準: `.claude/skills/zenn-quality/SKILL.md`
- レビュー手順: `.claude/agents/zenn-reviewer.md`
- 記事作成: `.claude/agents/zenn-writer.md`
