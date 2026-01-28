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
| `buzz-post` | Xバズポスト作成・「さらに表示」位置最適化 |
| `fact-check` | 調査結果を公式ドキュメント・公式ベストプラクティスと照合 |

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

## X（Twitter）運用の知見

### 文字数カウント（重要）

X のすべての文字数制限は **UTF-16 code units** で計測される。

| 制限 | 上限 |
|------|------|
| ポスト（ツイート） | 280 UTF-16 units |
| プロフィール欄 | 160 UTF-16 units |

```javascript
// ✅ 正しい（UTF-16 = X と一致）
text.length

// ❌ 間違い（Unicode code points = 絵文字で1ずれる）
[...text].length
```

絵文字（👉😀🔧等）は UTF-16 で **2 units** 消費する。`[...text].length` では 1 としてカウントされるため、絵文字1個につき1文字ずれる。

### 「さらに表示」の発生条件

| 条件 | 対象 |
|------|------|
| weighted length > 280 | 全端末（**Premium必須**。無料アカウントは280が投稿上限のため不可能） |
| 11行以上（weighted ≤ 280） | PCブラウザのみ |

weighted length の計算: 全角文字 = 2、半角英数・改行・スペース = 1、URL = 23固定。
半角英単語（Claude, Code, AI, Zenn等）が多いと、見た目より weighted が大幅に小さくなる。

### 外部リンクのインプレッション影響

外部リンク付きポストはリーチが **最大94%低下** する（Buffer社 1,880万投稿分析、Jesse Colombo氏 A/Bテスト）。

**対策**: URL はリプ欄に貼る（イーロン・マスク本人も推奨）。メイン投稿はテキストのみにする。

### コピペ時の改行混入

コードブロック（```）からコピーすると末尾に改行が付加され、文字数制限を超える場合がある。
プロフィール等の文字数ぴったりのテキストは **テキストファイルに改行なしで書き出し**、そこからコピーする。

```javascript
// 改行なしでファイル書き出し
fs.writeFileSync('output.txt', text, {encoding: 'utf8'});
```

## エラーと解決策

### SVG → PNG 変換（Windows）

Windows の `convert.exe` はディスク変換ツールであり ImageMagick ではない。

```bash
# ✅ 正しい方法
npx sharp-cli -i input.svg -o output.png -f png --density 144
```

`--density 144` で 2x 解像度になる。

### Python が使えない場合

Windows 環境で `python3` コマンドが見つからない場合は `node -e` で代替する。
文字数カウント等の簡易スクリプトは Node.js で実行可能。

## 記事公開チェックリスト（重要）

記事を公開する際は、以下を必ず確認する：

### 1. 記事の準備
- [ ] `published: true` に設定
- [ ] シリーズ構成が他記事と一致
- [ ] 関連記事リンクが正しい

### 2. Git 操作
- [ ] `git status` で未コミットファイルを確認
- [ ] `git add` で対象ファイルをステージング
- [ ] `git commit` でコミット作成
- [ ] `git push origin main` でプッシュ

### 3. デプロイ確認
- [ ] Zenn のデプロイ完了を待つ（数分）
- [ ] Zenn 管理画面で記事が表示されることを確認
- [ ] 公開 URL で記事が閲覧できることを確認

:::message alert
**過去の失敗事例**
記事ファイルを作成し `published: true` に設定したが、Git にコミット・プッシュし忘れて公開されなかった。
「ファイル作成完了」≠「記事公開完了」であることを忘れない。
:::

### 確認コマンド

```bash
# 未コミットファイルの確認
git status

# コミット・プッシュ
git add articles/*.md
git commit -m "Publish: {記事タイトル}"
git push origin main

# プッシュ完了後、Zenn管理画面で確認
# https://zenn.dev/dashboard
```

### Zennレートリミット対策

Zennには投稿数の上限があり、制限にかかると記事がデプロイされない（HTTP 429エラー）。

**症状**:
```
次の記事は一定時間以内の投稿数の上限に達したためデプロイされませんでした
```

**公式情報:**
- 具体的な制限数値は非公開（スパム対策のため）
- [利用規約](https://zenn.dev/terms) 第12条に基づき、「サーバーに負担をかける行為」として制限
- 参考: [利用規約とコミュニティガイドライン改定（2025年6月）](https://info.zenn.dev/2025-06-02-guideline-update)

:::message
**ユーザー観測に基づく目安（公式ではない）**
- 1日1記事程度でも制限にかかる場合がある
- 解除まで約24時間かかるパターンが報告されている
- `git force-push` が新規投稿としてカウントされる可能性
- リトライを繰り返すと逆効果の可能性
- **レートリミット中でも、既に公開済みの記事の更新はデプロイ可能**（制限されるのは新規投稿のみ）
- **`published: false`（下書き）でpushすればレート制限に引っかからない**（公開しないため対象外）

参考: https://zenn.dev/kiitosu/scraps/82de0b7edd8618
:::

**推奨される対策:**
1. 複数記事の同時公開を避ける
2. `git force-push` ではなく通常の `git push` を使用
3. 細かい修正は1回のコミットにまとめてからpush
4. 大量移行は事前にZennに申請（お問い合わせフォーム）

**制限にかかった場合:**
1. **焦ってリトライしない**（逆効果の可能性）
2. **24時間程度待つ**
3. 改善しない場合はZennに問い合わせ
4. 空コミットで再デプロイをトリガー:
   ```bash
   git commit --allow-empty -m "Trigger Zenn redeploy"
   git push origin main
   ```
