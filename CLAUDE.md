# Project: zenn-claude-code-guide

Zenn向けのClaude Code関連技術記事を管理するプロジェクト。
非エンジニア向けの技術ガイドを作成・公開する。

## Project Structure

```
articles/           # Zenn記事（Markdown）
.claude/
├── agents/         # サブエージェント定義
├── protocols/      # ワークフロー定義
└── skills/         # スキル定義
```

## Protocols

### RMOS Deep Research Protocol

調査・検証・記事化の一気通貫ワークフロー。
テーマから最適なOSSを選定し、検証から記事執筆まで自律実行する。

**詳細**: `.claude/protocols/rmos-orchestration.md`

**起動方法**:
```
RMOSプロトコルを実行してください。

テーマ: {調査したい内容}
環境: {Windows / WSL2 / macOS}
投稿先: {Zenn / Qiita}
```

**簡略形**:
```
RMOS: 「{テーマ}」 / {環境} / {投稿先}
```

**例**:
```
RMOS: 「MCPでファイルシステムを操作するツール」 / Windows / Zenn
```

## Agents

| エージェント | 役割 | 使用タイミング |
|-------------|------|---------------|
| `rmos-researcher` | OSS調査・検証 | RMOSプロトコル Phase 1-2 |
| `zenn-writer` | 記事作成 | 記事ドラフト作成時 |
| `zenn-reviewer` | 品質レビュー | 記事完成後のチェック |

## Skills

| スキル | 役割 |
|--------|------|
| `zenn-quality` | 記事品質基準とチェックリスト |

## Article Guidelines

このプロジェクトの記事は非エンジニア向け。以下を遵守：

- 選択肢は1つに絞る（複数並べない）
- プロンプト例は自然な日本語（ファイルパス不要）
- 具体例は初心者向け（タイマー、電卓など）
- 暗黙の前提を説明する
- コマンドや記号（irm, iex, ~, PATH）には説明を追加

## Zenn Specifics

### Frontmatter（必須）
```yaml
---
title: "記事タイトル"
emoji: "🤖"
type: "tech"
topics: ["claudecode", "ai", "windows"]
published: false
---
```

### 人気topics
`claudecode`, `ai`, `生成ai`, `llm`, `windows`, `個人開発`

### 記法
- 見出し前に空行を入れる
- `:::message` は補足情報
- `:::message alert` は警告

## Commands

```bash
# プレビュー
npx zenn preview

# 新規記事作成
npx zenn new:article
```
