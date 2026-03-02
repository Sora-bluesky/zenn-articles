---
title: "Claude Code のコンテキスト切れ問題を Hooks 3つで解決する"
emoji: "🔗"
type: "tech"
topics: ["claudecode", "ai", "生成ai", "llm", "個人開発"]
published: true
---

:::message
この記事は Claude Code を日常的に使っていて、設定ファイル（JSON）と bash スクリプトを自分で編集できる人向け。Hooks の基本については [Claude Codeに「保存したら自動でフォーマット」を仕込んだら快適すぎた](https://zenn.dev/sora_biz/articles/claude-code-auto-format-hooks) で解説している。
:::

:::message
2026年3月時点の情報。Claude Code の仕様変更により動作が変わる可能性がある。
:::

## この記事でできるようになること

Claude Code のセッションを終了しても、次のセッションで**前回の作業状態が自動的に引き継がれる**仕組みを作る。

具体的には、Hooks API を使って以下の3つを自動化する:

1. **新セッション開始時**: 前回の引き継ぎ情報を自動でコンテキストに注入
2. **引き継ぎ忘れ防止**: 一定時間更新がなければ Claude が自動でリマインド
3. **コンテキスト圧縮時**: ログを記録して「そろそろ引き継ぎすべき」と気づける

---

## きっかけ：スキルまで自作した。それでもめんどくさかった

僕はこの問題に対して、`/handoff` と `/go` という2つのスキルを自作して運用していた。Claude Code にはカスタムコマンド（スキル）を自分で定義できる機能がある。`/handoff` はセッション終了時に打つと、Claude が今のセッションの状態を分析し、構造化された引き継ぎドキュメントを自動生成する。`/go` は新セッション開始時に打つと、その引き継ぎドキュメントを読み込んで前回の状態を復元し、そのまま作業に着手してくれる。

タスクの進捗、変更したファイル、重要な意思決定、次にやるべきことをまとめた `HANDOFF.md` をプロジェクトルートに吐き出す。こんな感じのファイルだ:

```markdown:HANDOFF.md（例）
# セッション引き継ぎ資料

## 完了した作業
- 認証モジュールのリファクタリング（auth.ts, middleware.ts）
- テスト追加（auth.test.ts）

## 作業中・未完了
- [ ] エラーハンドリングの改善（auth.ts:42）

## 次回やるべきこと
- エラーハンドリング完了後、PR作成
```

...それでもめんどくさかった。

毎回セッション終了前に `/handoff` を打つのを覚えていないといけない。忘れてセッションを閉じると、次のセッションでは白紙からやり直し。再開時の手間を減らすために `/go` というスキルも作った。新セッションで打つと HANDOFF.md を読み込んで、前回の完了作業・保留タスク・推奨アクションを整理し、そのまま作業に着手してくれる。でも結局、**終了時に `/handoff`、開始時に `/go`** と2つのコマンドを忘れずに打つ運用になる。

GitHub の Issue [#25695](https://github.com/anthropics/claude-code/issues/25695) を読んだとき、こう書かれていた。

> This is the single most frustrating experience in Claude Code.
> （これがClaude Codeで最もフラストレーションを感じる体験だ）

深くうなずいた。Issue を立てた [eikiyo](https://github.com/eikiyo) と朝まで酒飲みながら語り合いたい、そんな気分になった。

---

## Issue #25695 が言語化した5つの痛み

eikiyo が書いた Issue は、コンテキスト切れの問題を正確に言語化している:

| 痛み | 内容 | この記事の回答 |
|------|------|------|
| **再オリエンテーション税** | 新セッションで同じ説明を10〜15分かけてやり直す | SessionStart Hook で自動注入 |
| **ユーザーの悪い適応** | 手書きメモ、人為的なタスク分割、引き継ぎ忘れ | Stop Hook で忘れ防止 |
| **崖のような断絶** | 「生産的なセッション」→「白紙」に中間地点がない | HANDOFF.md が中間地点になる |
| **コンパクション品質の劣化** | 要約の要約の要約。「AはダメだからB」→「Bを選んだ」 | PreCompact Hook で早期警告 |
| **生産性ピークでの断絶** | 15ファイル読み込み、実装半分完了...そこで死ぬ | `/handoff` を余裕のあるうちに |

eikiyo は解決策として**セッションブランチング**（構造化された引き継ぎ付きで新セッションに自動分岐）を提案している。プロダクト機能としてはまだ実装されていない。

でも、**既存の Hooks API を組み合わせれば、今日この問題の80%は解決できる。** 完璧じゃなくても、毎日の痛みが減るなら作る価値はある。

---

## 公式ドキュメントを調べてわかったこと

Claude Code の [Hooks リファレンス](https://code.claude.com/docs/ja/hooks) を調べた結果、3つの使えるフックを見つけた。

| Hook | 発火タイミング | できること |
|------|-------------|----------|
| `SessionStart` | セッション開始時 | `additionalContext` としてテキストをコンテキストに注入 |
| `Stop` | Claude が応答を完了するたび | `decision: "block"` で Claude に続行を指示 |
| `PreCompact` | コンテキスト圧縮の直前 | シェルコマンドを実行（ログ記録等） |

特に **`SessionStart` の `additionalContext`** が核心だった。これを使えば、`HANDOFF.md` の内容を新セッション開始時に**自動で**コンテキストに入れられる。新しいセッションを開いた瞬間、Claude が前回の引き継ぎ内容を「既に読んだ状態」で始まるイメージだ。「HANDOFF.md を読んで」と手動で指示する必要がなくなる。自作の `/go` コマンドすら打つ手間が省けた。

---

## 全体アーキテクチャ

| フェーズ | Hook | 何が起きるか |
|:---|:---|:---|
| **① セッション中** | PreCompact | コンテキスト圧縮を検知 → ログ記録 |
| | （手動） | `/handoff` 実行 → HANDOFF.md 更新 |
| **② セッション境界** | Stop | HANDOFF.md の最終更新をチェック |
| | | → 1時間以上前なら `block`（/handoff を発動） |
| | | → 更新済みなら `allow`（セッション終了） |
| **③ 新セッション** | SessionStart | HANDOFF.md を `additionalContext` に自動注入 |
| | | → Claude が前回の状態で開始 |

- **HANDOFF.md** が3つの Hook をつなぐ中心的なファイル。eikiyo が言う「崖のような断絶」を「坂道」に変える
- `SessionStart` Hook が「再オリエンテーション税」を消す。10〜15分の説明し直しがゼロになる
- `Stop` Hook が「ユーザーの悪い適応」を防ぐ。忘れてセッションを閉じたら白紙、という恐怖から解放される
- `PreCompact` Hook が「要約の要約の要約」が始まる前に気づかせてくれる

---

## セットアップ手順

### 前提

- Claude Code が使えるプラン（Claude Pro $20/月 または Claude Max）
- プロジェクトに `HANDOFF.md` が存在する（まだなければ、上の例を参考に手書きでもいい）
- Windows の場合: Git Bash（Claude Code と一緒にインストールされる）で動作確認済み

### Step 1: スクリプトファイルを作成

`.claude/hooks/` ディレクトリを作成し、3つのスクリプトを配置する。

```bash
mkdir -p .claude/hooks .claude/logs
```

#### session-start.sh

セッション開始時に `HANDOFF.md` を読み込み、`additionalContext` として出力する。

```bash:session-start.sh
#!/bin/bash
HANDOFF="HANDOFF.md"
if [ -f "$HANDOFF" ]; then
  node -e "
    const fs = require('fs');
    const content = fs.readFileSync('HANDOFF.md', 'utf8');
    console.log(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'SessionStart',
        additionalContext: '## Previous Session Handoff\\n\\n' + content
      }
    }));
  "
fi
```

:::message
`hookSpecificOutput` でラップするのが公式フォーマット。`hookEventName` には対応するイベント名を指定する。JSON出力に `node -e` を使っているのもポイントで、bash だけでJSON文字列をエスケープしようとすると地獄を見る（後述）。
:::

最初にこの Hook が動いて前回の引き継ぎが自動注入されたとき、正直ちょっと感動した。毎回やっていた「HANDOFF.md を読んで」が不要になっただけで、新しいセッションを開くストレスが消えた。

![SessionStart Hook が発動し、前回の引き継ぎ情報が自動注入された様子](/images/session-start-hook-firing.png)
*セッションを開いた瞬間、前回の HANDOFF.md が自動で読み込まれている*

#### stop-check.sh

`HANDOFF.md` が1時間以上更新されていなければ、Claude に「引き継ぎを作ってから終わって」と続行を指示する。Claude が応答を完了するたびに呼ばれるので、閾値を超えた時点で自動的にリマインドが入る。

```bash:stop-check.sh
#!/bin/bash
HANDOFF="HANDOFF.md"
if [ -f "$HANDOFF" ]; then
  node -e "
    const fs = require('fs');
    const stats = fs.statSync('HANDOFF.md');
    const ageMinutes = (Date.now() - stats.mtimeMs) / 60000;
    if (ageMinutes > 60) {
      console.log(JSON.stringify({
        decision: 'block',
        reason: 'HANDOFF.md が' + Math.floor(ageMinutes) + '分間更新されていません。/handoff を実行してからセッションを終了してください。'
      }));
    }
  "
fi
# HANDOFF.mdが存在しない or 更新が新しい場合 → 何も出力せず exit 0（= 終了を許可）
```

実際に61分経過した状態でこの Hook が発動すると、こう表示される:

![Stop Hook が発動し、引き継ぎを促すリマインド](/images/stop-hook-reminder.png)
*HANDOFF.md が1時間以上更新されていないと、Claude Code が自動でリマインドし `/handoff` が発動する*

#### pre-compact-log.sh

コンテキスト圧縮（auto-compaction）が発生したらログに記録する。

```bash:pre-compact-log.sh
#!/bin/bash
mkdir -p .claude/logs
echo "[$(date -Iseconds)] Auto-compaction triggered. Consider running /handoff soon." >> .claude/logs/compaction.log
```

### Step 2: settings.local.json に Hook を登録

プロジェクトの `.claude/settings.local.json` の `hooks` セクションに追加する。

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-start.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/stop-check.sh"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "auto",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/pre-compact-log.sh"
          }
        ]
      }
    ]
  }
}
```

- `SessionStart` の `"matcher": "startup"` は新規セッション開始時のみ発火。`"resume"` や `"compact"` 時にも注入したい場合は matcher を省略する
- `Stop` は matcher をサポートしない（常に全ての停止時に発火する）ので省略
- `PreCompact` の `"matcher": "auto"` は自動コンパクション時のみ発火。手動 `/compact` では発火しない

:::message alert
Hook の設定変更は**セッション再起動後**に反映される。設定を書き換えた直後のセッションでは動作しない。
:::

### Step 3: 動作確認

プロジェクトのルートディレクトリで以下を実行する。

```bash
# SessionStart Hook のテスト
bash .claude/hooks/session-start.sh
# → {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}
# のようなJSON が出力されればOK

# Stop Hook のテスト（HANDOFF.md更新直後なら何も出力されない = 許可）
bash .claude/hooks/stop-check.sh
# → 何も出力されなければOK（ブロック時は {"decision":"block","reason":"..."} が出る）

# PreCompact Hook のテスト
bash .claude/hooks/pre-compact-log.sh
cat .claude/logs/compaction.log
# → [2026-03-01T12:00:00+09:00] Auto-compaction triggered... のようなログが記録されればOK
```

---

## 設計で工夫したこと

### JSON エスケープ地獄の回避

最初はインラインの `bash -c '...'` で書こうとした。

```
# こうなる（読めない）
"command": "bash -c 'echo \"{\\\"additionalContext\\\": \\\"$(cat HANDOFF.md | sed ...)\\\"}\"'"
```

JSON設定ファイルの中に、JSON を出力する bash コマンドを書く。エスケープが4重になって人間には読めない。

解決策は単純で、**スクリプトファイルに分離する**。

```
# こうする（読める）
"command": "bash .claude/hooks/session-start.sh"
```

スクリプト内では `node -e` で `JSON.stringify()` を呼ぶ。Node.js は Claude Code の前提環境なので追加インストール不要。

### 鶏と卵問題

eikiyo が指摘した「要約の要約の要約」問題の核心がここにある。

`PreCompact` Hook ではシェルコマンドは実行できるが、**Claude に引き継ぎサマリーを生成させることはできない**。コンテキストがいっぱいになってから「引き継ぎを作って」と頼むのは手遅れだ。引き継ぎサマリーの生成自体にトークンが必要だから。

だから `/handoff` は**コンテキストに余裕があるうちに手動で実行する**。「アプローチAは47行目で競合状態があったのでBを選んだ」という判断の過程を、コンパクションに潰される前に自分の手で保存しておく。`Stop` Hook はその「忘れ」を防ぐ安全ネットだ。

### 閾値のチューニング

僕は `stop-check.sh` の閾値を60分にしている。1時間もセッションを続けていたら、途中で一度引き継ぎを作っておくべきだろうという判断だ。短い作業なら30分に変えてもいい。

```javascript
// 30分に変更する場合
if (ageMinutes > 30) {
```

---

## Issue #25695 の提案との対応

| Issue の要求 | この記事の実装 | カバー |
|---|---|---|
| コンテキスト上限で通知 | PreCompact Hook でログ記録 | 70% |
| 構造化された引き継ぎ生成 | `/handoff` スキル（別途作成） | 100% |
| ディスクに保存 | HANDOFF.md | 100% |
| ユーザーが編集可能 | Markdown ファイル | 100% |
| 新セッションへ自動注入 | SessionStart Hook | 100% |
| セッション終了前のリマインド | Stop Hook（block） | 100% |
| セッションチェーニング（履歴リンク） | **未対応** | 0% |

**筆者の体感カバー率: 約80%**。eikiyo が提案したセッションチェーニング（`/history` でセッション履歴を辿る機能）だけはプロダクト機能が必要。残り20%は Anthropic に頑張ってもらうしかない。

---

## まとめ

コンテキスト切れの問題は、Claude Code を本格的に使い始めると誰もがぶつかる壁だ。

僕は `/handoff` スキルを自作して対処してきたけど、手動運用には限界があった。公式ドキュメントの Hooks API を調べたら、`SessionStart` の `additionalContext` 注入、`Stop` の `block` 判定、`PreCompact` のログ記録という3つの仕組みが既に用意されていた。

**プロダクト機能の追加を待たなくても、今日から使える。**

Issue #25695 が提案する「完全自動のセッションブランチング」には届かないけど、日常的な痛みの大部分はこの3つの Hook で解消できる。

まず `session-start.sh` だけ設定してみてほしい。それだけでも「HANDOFF.md を読んで」の手動指示がなくなる。実感できたら `stop-check.sh` を追加して、引き継ぎ忘れの安全ネットを張る。

いずれ eikiyo が Issue #25695 で提案したセッションブランチング——構造化された引き継ぎ付きで新セッションに自動分岐する仕組み——が公式機能として実装される日も来るかもしれない。そのとき、この Hook は不要になるだろう。でも、「公式に欲しい機能がないなら、今ある API で自分で作る」という経験自体が、ツールとの付き合い方を一段深くしてくれた。機能をねだる側から、足りないものを自分で埋める側に回る。その感覚を知れたのが、僕にとっては Hook の設定そのものより大きい収穫だった。

---

## 関連記事

- [Claude Codeが急にポンコツになる原因はコンテキストだった](https://zenn.dev/sora_biz/articles/claude-code-context-management) - コンテキスト管理の基本
- [Claude Codeの「昨日の続き」を一瞬で再開する技](https://zenn.dev/sora_biz/articles/claude-code-session-management) - セッション管理の基本（本記事はこの発展版）
- [Claude Codeに「保存したら自動でフォーマット」を仕込んだら快適すぎた](https://zenn.dev/sora_biz/articles/claude-code-auto-format-hooks) - Hooks の基本解説

---

## 参考

- [Claude Code Hooks リファレンス](https://code.claude.com/docs/ja/hooks)
- [Hooks ガイド（入門）](https://code.claude.com/docs/ja/hooks-guide)
- [Claude Code の仕組み - コンテキスト管理](https://code.claude.com/docs/ja/how-claude-code-works)
- [GitHub Issue #25695: Session branching with summarized context](https://github.com/anthropics/claude-code/issues/25695)
- [Claude Code ベストプラクティス](https://code.claude.com/docs/ja/best-practices)
