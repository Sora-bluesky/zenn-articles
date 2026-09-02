---
title: "Claude Code が全部忘れる問題を Hooks 3つで解決する"
emoji: "🔗"
type: "tech"
topics: ["claudecode", "ai", "生成ai", "llm", "個人開発"]
published: true
---

:::message
**前提知識**
この記事は Claude Code を日常的に使っていて、設定ファイル（JSON）と bash スクリプトを自分で編集できる人向け。以下の記事を先に読んでおくとスムーズに理解できる。
1. [ポンコツになる原因はコンテキスト](claude-code-context-management) — コンテキスト管理の基本
2. [「昨日の続き」を一瞬で再開](claude-code-session-management) — セッション管理の基本（本記事はこの発展版）
3. [保存したら自動でフォーマット](claude-code-auto-format-hooks) — Hooks の基本解説
:::

:::message
2026年9月時点の情報。Claude Code の仕様変更により動作が変わる可能性がある。
:::

:::details 修正履歴
| 日付 | 内容 |
|------|------|
| 2026-09-02 | 現行の Claude Code に合わせて全体を見直し。`stop-check.sh` に `stop_hook_active` のガードを追加（Stop Hook が8回連続でブロックすると上書きされるため）。スキルのディレクトリ形式、`transcript_path` が全イベント共通であること、`SessionStart` の `compact` matcher による再注入、公式の再開手段と transcript の保持期間、圧縮で何が残るかを追記 |
| 2026-03-05 | 公式メモリ機能（CLAUDE.md + auto memory）との違いを説明するセクションを追加 |
| 2026-03-04 | `session-start.sh` を `node -e` JSON 方式から `cat` プレーンテキスト方式に修正。SessionStart Hook は標準出力がそのまま `additionalContext` になるため、JSON ラップは不要だった |
:::

## この記事でできるようになること

Claude Code のセッションを終了しても、次のセッションで**前回の作業状態が自動的に引き継がれる**仕組みを作る。

:::message
Claude Code には公式のメモリ機能（CLAUDE.md + 自動メモリ）もあるが、それは「プロジェクトの知識」を保持するもの。この記事で扱うのは「作業の文脈」の引き継ぎで、公式メモリとは補完関係にある。[詳しくは後述する](#公式の自動メモリとは何が違うのか)。
:::

具体的には、Hooks API を使って以下の3つを自動化する。

1. **新セッション開始時**: 前回の引き継ぎ情報を自動でコンテキストに注入
2. **引き継ぎ忘れ防止**: コンテキストの消費量が閾値に達したら Claude が自動でリマインド（閾値はこの記事の仕組みが決める値で、Claude Code 自体の仕様ではない）
3. **コンテキスト圧縮時**: ログを記録して「そろそろ引き継ぎすべき」と気づける

## 目次

1. [きっかけ：スキルまで自作した。それでもめんどくさかった](#きっかけ：スキルまで自作した。それでもめんどくさかった)
2. [Issue #25695 が言語化した5つの痛み](#issue-%2325695-が言語化した5つの痛み)
3. [公式ドキュメントを調べてわかったこと](#公式ドキュメントを調べてわかったこと)
4. [公式の自動メモリとは何が違うのか](#公式の自動メモリとは何が違うのか)
5. [全体アーキテクチャ](#全体アーキテクチャ)
6. [圧縮で消えるもの、残るもの](#圧縮で消えるもの、残るもの)
7. [セットアップ手順](#セットアップ手順): [Step 1: スクリプト作成](#step-1%3A-スクリプトファイルを作成) / [Step 2: Hook 登録](#step-2%3A-settings.local.json-に-hook-を登録) / [Step 3: スキル作成](#step-3%3A-%2Fhandoff-スキルを作成) / [Step 4: 動作確認](#step-4%3A-動作確認)
8. [設計で工夫したこと](#設計で工夫したこと): [JSON エスケープ地獄](#json-エスケープ地獄の回避) / [鶏と卵問題](#鶏と卵問題) / [transcript の罠](#transcript-の罠) / [閾値のチューニング](#閾値のチューニング) / [作った仕組みが本当に動いていたか](#作った仕組みが本当に動いていたか)
9. [Issue #25695 の提案との対応](#issue-%2325695-の提案との対応)

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

eikiyo が書いた Issue は、コンテキスト切れの問題を正確に言語化している。

| 痛み | 内容 | この記事の回答 |
|------|------|------|
| **再オリエンテーション税** | 新セッションで同じ説明を10〜15分かけてやり直す | [SessionStart Hook](#セットアップ手順) で自動注入 |
| **ユーザーの悪い適応** | 手書きメモ、人為的なタスク分割、引き継ぎ忘れ | [Stop Hook](#セットアップ手順) で忘れ防止 |
| **崖のような断絶** | 「生産的なセッション」から「白紙」に中間地点がない | [HANDOFF.md](#step-3%3A-%2Fhandoff-スキルを作成) が中間地点になる |
| **コンパクション品質の劣化** | 要約の要約の要約。「A はダメだから B」が「B を選んだ」に化ける | [PreCompact Hook](#セットアップ手順) で早期警告 |
| **生産性ピークでの断絶** | 15ファイル読み込み、実装半分完了、そこで途切れる | [`/handoff`](#step-3%3A-%2Fhandoff-スキルを作成) を余裕のあるうちに |

eikiyo は解決策として**セッションブランチング**（構造化された引き継ぎ付きで新セッションに自動分岐）を提案している。この Issue は2026年4月15日（UTC）に closed（not_planned）になっており、プロダクト機能としては採用されなかった。

でも、Issue が言語化した痛みそのものは消えていない。**既存の Hooks API を組み合わせれば、今日この問題の80%は解決できる。** 完璧じゃなくても、毎日の痛みが減るなら作る価値はある。

---

## 公式ドキュメントを調べてわかったこと

Claude Code の [Hooks リファレンス](https://code.claude.com/docs/ja/hooks) を調べた結果、3つの使えるフックが見つかった。

| Hook | 発火タイミング | できること |
|------|-------------|----------|
| `SessionStart` | セッション開始時（matcher は `startup` / `resume` / `clear` / `compact` / `fork` の5種類） | 標準出力に出したテキストがそのまま `additionalContext` としてコンテキストに注入される |
| `Stop` | Claude が応答を完了するたび | `decision: "block"` で Claude に続行を指示 |
| `PreCompact` | コンテキスト圧縮の直前 | シェルコマンドを実行（ログ記録等）。`type: "prompt"` で Claude モデルに判断させたり、`type: "agent"` でサブエージェントにファイルを読ませて判断させたりもできる |

特に **`SessionStart` の `additionalContext`** が核心だった。SessionStart Hook は標準出力に出したテキストがそのまま `additionalContext` として注入され、Claude はそれをプレーンテキストの system reminder として読む。ユーザーが何も入力しなくても、セッション開始と同時に Claude が「既に読んだ状態」になる。これを使えば、`HANDOFF.md` の内容を新セッション開始時に**自動で**コンテキストに入れられる。「HANDOFF.md を読んで」と手動で指示する必要がなくなる。自作の `/go` コマンドは完全に不要になった。

この「標準出力がそのままコンテキストに入る」という挙動は `SessionStart` に限らない。`UserPromptSubmit` など一部のイベントも同じ扱いだ。一方 `Stop` の `decision: "block"` のように判定を返すイベントは、`hookSpecificOutput` や規定の JSON キーで応答する必要がある。イベントごとに出力の受け取り方が違う、という前提を持っておくと Hook の設計で迷わない。

---

## 公式の再開手段だけでは足りない理由

セッションを再開する手段は、公式にも用意されている。`claude --continue` は現在のディレクトリの最新セッションを引数なしで再開する。`claude --resume` はセッションピッカーを開き、引数でセッションを直接指定することもできる。セッションの中からは `/resume` で別の会話へ切り替えられる（[公式ドキュメント](https://code.claude.com/docs/en/sessions)）。

これで足りない理由が2つある。1つは、会話を再開できても、コンパクションで要約された後は細部が落ちていることだ（後述する）。もう1つは、transcript が既定30日で消えることだ。`~/.claude/projects/<project>/<session-id>.jsonl` に保存され、保持期間は `cleanupPeriodDays` で決まる（[出典](https://code.claude.com/docs/en/data-usage)）。3か月前に何をどう決めたかは、そこには残らない。だから「何をどこまでやったか」を自分のファイルに落とす。

## 公式の自動メモリとは何が違うのか

Claude Code には公式のセッション間メモリ機構が3つある（[公式ドキュメント](https://code.claude.com/docs/ja/memory)）。

1. **CLAUDE.md ファイル**: ユーザーが書くプロジェクト指示。コーディング規約、ビルドコマンド、アーキテクチャの決定などを記述する
2. **`.claude/rules/*.md`**: CLAUDE.md を分割して置く公式の機構。frontmatter の `paths:` でパスを限定してロードできる。`paths` を指定しなければ起動時にロードされる
3. **自動メモリ**（auto memory）: Claude が自動で `~/.claude/projects/<project>/memory/MEMORY.md` に学習を蓄積する。デバッグの知見、コードスタイルの好みなどを Claude 自身が判断して保存する

公式ドキュメントにはこう書かれている。

> Claude Code の各セッションは、新しいコンテキストウィンドウで始まります。2つのメカニズムがセッション間で知識を保持します。CLAUDE.md ファイルと自動メモリです。

これを見て「じゃあ公式だけで足りるのでは」と思うかもしれない。でも、公式メモリとこの記事の Hooks システムは**解いている問題が違う**。

| 観点 | 公式メモリ（CLAUDE.md + rules + auto memory） | この記事のシステム（Hooks + HANDOFF.md） |
|------|------|------|
| 保存するもの | プロジェクトの知識・規約・パターン | 作業の進捗・次のタスク・判断根拠 |
| 例 | 「main ブランチは PR 必須」「テストは pytest」 | 「PR #79 をマージ済み、次はエラーハンドリング」 |
| 誰が書くか | CLAUDE.md・rules はユーザー、auto memory は Claude | `/handoff` で Claude が構造的に生成 |
| コンパクション対策 | CLAUDE.md は `/compact` 後に再読込される。auto memory はセッション開始時に読込 | PreCompact Hook で早期警告、Stop Hook で事前検知 |
| セッション限界の検知 | なし | Stop Hook で閾値到達を検知 → 引き継ぎ促進 |

公式メモリは「Claude に記憶力を与える」仕組みだ。この記事のシステムは「Claude に仕事の引き継ぎ能力を与える」仕組みだ。

たとえば、自動メモリが「このプロジェクトは TypeScript + React で、テストは vitest」と覚えていても、「昨日 auth.ts のリファクタリングが半分終わっていて、42行目のエラーハンドリングが未着手」という作業状態は保存しない。逆に、HANDOFF.md に「auth.ts:42 が未着手」と書いてあっても、「このプロジェクトのテストコマンドは vitest」という恒久的な知識を保持する場所ではない。

:::message
自動メモリはデフォルトで有効なので、意識せずに使っている人も多いはずだ。`/memory` コマンドで確認できる。MEMORY.md はセッション開始時に**先頭200行または25KBのうち先に来たほう**までしか読み込まれないという制限がある。
:::

**両方を使う。** 公式メモリはプロジェクトの知識を貯める。Hooks は作業の状態を次のセッションへ渡す。役割が違うので、どちらかで代用しようとすると片方が抜ける。

---

## 全体アーキテクチャ

| フェーズ | Hook | 何が起きるか |
|:---|:---|:---|
| **① セッション中** | PreCompact | コンテキスト圧縮を検知 → ログ記録 |
| | （手動） | `/handoff` 実行 → HANDOFF.md 更新 |
| **② セッション境界** | Stop | transcript を解析し、`compact_boundary` 以降のサイズからコンテキスト消費量を推定 |
| | | → 閾値を超えたら `block`（/handoff を発動） |
| | | → 未達なら `allow`（セッション終了） |
| **③ 新セッション** | SessionStart | HANDOFF.md をコンテキストに自動注入 |
| | | → Claude が前回の状態で開始 |
| **（発展）コンパクション直後** | PostCompact / SessionStart(compact) | コンパクションで要約された直後に HANDOFF.md を再注入する構成も組める（[詳しくは後述する](#圧縮で消えるもの、残るもの)） |

- **HANDOFF.md** が3つの Hook をつなぐ中心的なファイル。eikiyo が言う「崖のような断絶」を「坂道」に変える
- `SessionStart` Hook が「再オリエンテーション税」を消す。10〜15分の説明し直しがゼロになる
- `Stop` Hook が「ユーザーの悪い適応」を防ぐ。忘れてセッションを閉じたら白紙、という恐怖から解放される
- `PreCompact` Hook が「要約の要約の要約」が始まる前に気づかせてくれる

---

## 圧縮で消えるもの、残るもの

ここまでの3つの Hook は「HANDOFF.md を手動または `/handoff` で書き出し、次のセッションで読み直す」という運びだった。でも実際にコンパクション（`/compact` または自動コンパクション）が起きたとき、セッションには何が残っていて何が消えているのか。ここを公式仕様で確認しておく。

プロジェクトルートの `CLAUDE.md` は `/compact` を生き残る。コンパクションが起きるとディスクから読み直されて、要約されたコンテキストに再注入される。

残らないものが2つある。サブディレクトリに置いた `CLAUDE.md`（そのディレクトリ内のファイルを触ったときだけ読み込まれる分）は自動では戻らない。もう一度そのディレクトリのファイルを触るまで待つことになる。

もう1つは、会話の中だけで伝えた指示だ。「今回はこのルールで進めて」のような口頭の指示は、要約に取り込まれなければ消える。

この記事が「ファイルに落とす」ことにこだわっている理由がここにある。

HANDOFF.md もプロジェクトルートのファイルだが、CLAUDE.md と同じ扱いにはならない。自動で読み直される対象に入っているのは CLAUDE.md のほうだ。HANDOFF.md が注入されているのは、SessionStart Hook が明示的に読みに行っているからにすぎない。だから Hook で能動的に注入する設計にしている。

`PostCompact` という Hook イベントも用意されている。コンパクション完了後に発火する。`SessionStart` の matcher にも `compact` という値があり、コンパクション後の新しいコンテキストが始まるタイミングで発火する。

公式の [Hooks ガイド](https://code.claude.com/docs/en/hooks-guide) は、この2つのうち `SessionStart` + `compact` matcher による再注入を名指しで勧めている。「`SessionStart` hook を `compact` matcher と組み合わせて使い、コンパクションのたびに重要なコンテキストを再注入する」という一文がガイドにある。この記事の[Step 2](#step-2%3A-settings.local.json-に-hook-を登録)で示す構成は、この案内に沿ったものだ。

一方、`PostCompact` が `hookSpecificOutput` でコンテキストへの注入を受け付けるかどうかは、現時点のドキュメントに記載がない。こちらは断定できない。

## セットアップ手順

### 前提

- Claude Code が使えるプラン（価格は公式ドキュメントに記載がなく変わりやすいので、ここには書かない）
- `HANDOFF.md` はなくても動く（Step 3 で作成する `/handoff` スキルで自動生成される。上の例を参考に手書きで作っておいてもいい）
- Windows の場合: Git for Windows（Git Bash）は必須ではない。入れると Bash ツールが使えるようになり、この記事のスクリプトをそのまま動かせる。入れなければ Claude Code は PowerShell ツールでシェルを実行する

### 完成形のディレクトリ構造

すべてのファイルは **プロジェクトルート**（Claude Code を起動するディレクトリ）を基準に配置する。

```
your-project/
├── .claude/
│   ├── hooks/
│   │   ├── session-start.sh   ← Step 1 で作成
│   │   ├── stop-check.sh      ← Step 1 で作成
│   │   └── pre-compact-log.sh ← Step 1 で作成
│   ├── skills/
│   │   └── handoff/
│   │       └── SKILL.md       ← Step 3 で作成
│   ├── logs/                   ← 自動生成される
│   └── settings.local.json    ← Step 2 で編集
├── HANDOFF.md                  ← /handoff が生成・更新する
└── （既存のプロジェクトファイル）
```

:::message
`.claude/` ディレクトリは Claude Code がプロジェクトごとの設定を保存する場所。まだ存在しない場合は `mkdir -p .claude/hooks` で作成される。
:::

:::message
`.claude/` ディレクトリは Claude Code がプロジェクトごとの設定を保存する場所。まだ存在しない場合は `mkdir -p .claude/hooks` で作成される。
:::

### Step 1: スクリプトファイルを作成

以下の3つのスクリプトファイルをテキストエディタ（VS Code、メモ帳など）で作成し、指定のパスに保存する。

まずプロジェクトルートで以下を実行し、ディレクトリを作成する。

```bash
mkdir -p .claude/hooks .claude/skills .claude/logs
```

#### session-start.sh

セッション開始時に `HANDOFF.md` を読み込み、`additionalContext` として出力する。

```bash:.claude/hooks/session-start.sh
#!/bin/bash
# stop-check.sh が作るフラグファイルをリセット（詳細は stop-check.sh セクション参照）
rm -f .claude/hooks/.context-warned

HANDOFF="HANDOFF.md"
if [ -f "$HANDOFF" ]; then
  echo "## Previous Session Handoff"
  echo ""
  cat "$HANDOFF"
fi
```

:::message
SessionStart Hook は、**標準出力に出したテキストがそのまま `additionalContext` として Claude のコンテキストに注入される**。JSON でラップする必要はない。`cat` でファイル内容を流すだけでいい。
:::

最初にこの Hook が動いて前回の引き継ぎが自動注入されたとき、正直ちょっと感動した。毎回やっていた「HANDOFF.md を読んで」が不要になっただけで、新しいセッションを開くストレスが消えた。

![SessionStart Hook が発動し、前回の引き継ぎ情報が自動注入された様子](/images/session-start-handoff-injection.png)
*新セッションを開いた瞬間、前回の HANDOFF.md が自動注入され「HANDOFF.md の注入を確認できました」と応答している*

#### stop-check.sh

transcript（会話ログ）を解析してコンテキスト消費量を推定し、閾値（約80%・800KB）に達したら Claude に「引き継ぎを作ってから終わって」と続行を指示する。コンパクションサイクルごとに1回だけ発火するフラグ制御付き。

Stop Hook は発火時に stdin で `transcript_path` を含む JSON を受け取る。`transcript_path` は SessionStart を含む全イベント共通の入力フィールドだ。SessionStart Hook では標準出力がそのままコンテキストに入る仕組みのおかげで transcript を読みに行く必要がなく、使っていないだけで、フィールド自体は届いている。stop-check.sh で使うのは、会話ログを読んでコンテキスト消費量を推定する処理に必要だからだ。

```bash:.claude/hooks/stop-check.sh
#!/bin/bash
cat | node -e "
  const fs = require('fs');
  const FLAG = '.claude/hooks/.context-warned';
  let d = '';
  process.stdin.on('data', c => d += c);
  process.stdin.on('end', () => {
    try {
      const input = JSON.parse(d);

      // Stop Hook が decision: block を8回連続で返すと、
      // Claude Code 側がその判定を上書きして応答を終わらせる。
      // stop_hook_active は「直前の Stop Hook が既に block した直後」を意味するフラグで、
      // ここで早期 exit しないと同じサイクル内で block を連発してループする。
      if (input.stop_hook_active) process.exit(0);

      const tp = input.transcript_path;
      if (!tp || !fs.existsSync(tp)) process.exit(0);

      const content = fs.readFileSync(tp, 'utf8');

      // compact_boundary の数 = これまでのコンパクション回数
      // transcript はセッション全体の累積ログなので、
      // ファイルサイズではなく「現サイクル」だけを見る（→ transcript の罠）
      const boundaryCount =
        (content.match(/\"compact_boundary\"/g) || []).length;

      // 前回警告したサイクルと同じなら skip
      if (fs.existsSync(FLAG)) {
        const lastWarned =
          parseInt(fs.readFileSync(FLAG, 'utf8').trim());
        if (boundaryCount === lastWarned) process.exit(0);
      }

      // 最後の compact_boundary 以降 = 現在のサイクル
      const marker = '\"compact_boundary\"';
      const lastIdx = content.lastIndexOf(marker);
      let cycleStart = 0;
      if (lastIdx !== -1) {
        const eol = content.indexOf('\n', lastIdx);
        cycleStart = eol !== -1 ? eol + 1 : content.length;
      }
      const currentKB =
        Buffer.byteLength(content.slice(cycleStart), 'utf8') / 1024;

      // Opus 200K context ≈ 1MB in JSONL（→ 閾値のチューニング）. 80% ≈ 800KB.
      if (currentKB < 800) process.exit(0);

      // HANDOFF.md updated recently → user is already wrapping up
      if (fs.existsSync('HANDOFF.md')) {
        const ageMin =
          (Date.now() - fs.statSync('HANDOFF.md').mtimeMs) / 60000;
        if (ageMin <= 10) process.exit(0);
      }

      // 現サイクルの警告済みフラグを記録
      fs.mkdirSync('.claude/hooks', { recursive: true });
      fs.writeFileSync(FLAG, String(boundaryCount));

      console.log(JSON.stringify({
        decision: 'block',
        reason: 'コンテキストが約80%に達しました（現サイクル: '
          + Math.round(currentKB) + 'KB）。'
          + '/handoff でセッションを引き継いでください。'
      }));
    } catch(e) {}
  });
"
```

`stop_hook_active` のガードが無いと何が起きるか。閾値超過を検知して `block` を返すと、Claude はそのまま続行して応答を作る。次の停止でもまだ閾値を超えていれば、また `block` が返る。この繰り返しが8回続くと、Claude Code 側が「このスクリプトはループしている」と判断して block 判定を上書きし、Stop Hook の意思に関わらずセッションを終わらせる。ガードを入れておけば、直前の `block` を受けて Claude が動いた直後のサイクルではもう一度警告を出さずに済み、ループそのものが起きなくなる。

実際に発火した場面がこれだ。あるセッションでコンテキストが約80%に達した時点で Stop Hook が割り込み、`block` の指示を受けた Claude が `/handoff` を実行した。

![Stop Hook が発火し、コンテキスト80%到達を通知している様子](/images/stop-hook-context-warning.png)
*Stop Hook が割り込んだ瞬間。「現サイクル: 867KB」と表示されている*

`/handoff` で HANDOFF.md を生成した結果、トークンをさらに消費する。引き継ぎ完了後のステータスバーがこれだ。

![/handoff 実行後、ステータスバーが97%に達している様子](/images/stop-hook-handoff-97pct.png)
*97%。auto-compaction の直前で引き継ぎが完了した*

800KB で警告 → `/handoff` 実行 → 97% で着地。ギリギリだが、これが狙い通りの動作だ。閾値を 900KB にしていたら間に合わなかっただろう。

#### pre-compact-log.sh

コンテキスト圧縮（auto-compaction）が発生したらログに記録する。

```bash:.claude/hooks/pre-compact-log.sh
#!/bin/bash
mkdir -p .claude/logs
echo "[$(date -Iseconds)] Auto-compaction triggered. Consider running /handoff soon." >> .claude/logs/compaction.log
```

### Step 2: settings.local.json に Hook を登録

`.claude/settings.local.json`（プロジェクトルート直下の `.claude/` 内）に `hooks` セクションを追加する。ファイルが存在しない場合は新規作成する。既に `permissions` 等の設定がある場合は、同じ階層に `hooks` キーを追加すればいい。

```json:.claude/settings.local.json
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

- `SessionStart` の matcher は `startup` / `resume` / `clear` / `compact` / `fork` の5種類がある。上の設定は `startup`（新規セッション開始時）だけを対象にしている
- `Stop` は matcher をサポートしない（常に全ての停止時に発火する）ので省略する
- `PreCompact` の `"matcher": "auto"` は自動コンパクション時のみ発火する。手動 `/compact` では発火しない

コンパクション直後にも HANDOFF.md を入れ直したい場合は、`startup` 用のエントリを書き換えるのではなく、`SessionStart` の配列にもう1つ登録を足す。

```json:.claude/settings.local.json（SessionStart 配列に追加する分）
"SessionStart": [
  {
    "matcher": "startup",
    "hooks": [
      { "type": "command", "command": "bash .claude/hooks/session-start.sh" }
    ]
  },
  {
    "matcher": "compact",
    "hooks": [
      { "type": "command", "command": "bash .claude/hooks/session-start.sh" }
    ]
  }
]
```

`startup` は新規セッションで HANDOFF.md を注入し、`compact` はコンパクションで要約された直後に同じものを入れ直す。この2本立ては[圧縮で消えるもの、残るもの](#圧縮で消えるもの、残るもの)で触れたとおり、公式の [Hooks ガイド](https://code.claude.com/docs/en/hooks-guide)が名指しで勧めている構成だ。

:::message alert
Hook の設定変更は、通常はファイル監視によって自動で読み込まれる。数秒待っても反映されない場合は、セッションを再起動して読み直させる（[出典](https://code.claude.com/docs/en/hooks-guide)）。
:::

### Step 3: /handoff スキルを作成

ここまでの Hook は「HANDOFF.md を読む」「HANDOFF.md の存在を前提にリマインドする」仕組みだ。肝心の HANDOFF.md を生成するのが `/handoff` スキルになる。

スキルは `.claude/skills/<スキル名>/SKILL.md` というディレクトリ形式で置く（[Skills リファレンス](https://code.claude.com/docs/ja/skills)）。`.claude/skills/handoff.md` のようにファイルを直接置く形式は現行では使えない。

```bash
mkdir -p .claude/skills/handoff
```

```markdown:.claude/skills/handoff/SKILL.md
---
name: handoff
description: セッション引き継ぎ。HANDOFF.md を更新する。
user-invocable: true
---

# セッション引き継ぎ

プロジェクトルート直下の `HANDOFF.md` を以下のフォーマットで作成・更新する。

## フォーマット

- 完了した作業
- 保留中の作業（優先度付き）
- 決定事項（理由も含む）
- 次回セッションで再開に必要なコンテキスト
```

セッション終了前に `/handoff` と打つと、Claude が会話の内容を分析して HANDOFF.md を自動生成する。

:::message
スキルを作るのが面倒なら、Claude に直接「HANDOFF.md にセッションの状態をまとめて」と頼めば同じ結果になる。スキルにする利点は、毎回フォーマットを指示しなくて済むことだ。
:::

### Step 4: 動作確認

プロジェクトのルートディレクトリで以下を実行する。

```bash
# SessionStart Hook のテスト
bash .claude/hooks/session-start.sh
# → HANDOFF.md があれば内容がそのまま出力される。なければ何も出力されない（= 正常）

# Stop Hook のループ防止ガードのテスト
echo '{"stop_hook_active":true}' | bash .claude/hooks/stop-check.sh
# → 何も出力されなければOK（stop_hook_active を見て即座に早期 exit している）

# Stop Hook のテスト（実際のセッションで確認するのが確実）
# テスト用の小さいダミーファイルを作成
echo '{"type":"user"}' > .claude/test-transcript.jsonl
echo '{"transcript_path":".claude/test-transcript.jsonl"}' \
  | bash .claude/hooks/stop-check.sh
# → 何も出力されなければOK（閾値未達）

# テスト用のクリーンアップ
rm -f .claude/test-transcript.jsonl .claude/hooks/.context-warned

# PreCompact Hook のテスト
bash .claude/hooks/pre-compact-log.sh
cat .claude/logs/compaction.log
# → [2026-03-01T...] Auto-compaction triggered... のようなログが記録されればOK
```

:::message
Stop Hook の本格的なテストは難しい。800KB のダミー transcript を作っても、実際の JSONL フォーマットと異なるためテストとしては不完全。**実際にセッションを使い込んで発火するのを確認するのが最も確実**。ステータスバーの「% used」が70%を超えたあたりから注意していればいい。
:::


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

スクリプト内で JSON 出力が必要な場合は `node -e` で `JSON.stringify()` を呼ぶ。Node.js は Claude Code の前提環境なので追加インストール不要。なお `session-start.sh` は SessionStart Hook の仕様（標準出力がそのまま `additionalContext` になる）のおかげで、JSON を一切使わず `cat` だけで済む。JSON エスケープが必要なのは `stop-check.sh`（`decision: "block"` の JSON レスポンスが必要）のみ。

### 鶏と卵問題

eikiyo が指摘した「要約の要約の要約」問題の核心がここにある。

`PreCompact` Hook ではシェルコマンドは実行できるが、**Claude に引き継ぎサマリーを生成させることはできない**。コンテキストがいっぱいになってから「引き継ぎを作って」と頼むのは手遅れだ。引き継ぎサマリーの生成自体にトークンが必要だから。

だから `/handoff` は**コンテキストに余裕があるうちに手動で実行する**。「アプローチAは47行目で競合状態があったのでBを選んだ」という判断の過程を、コンパクションに潰される前に自分の手で保存しておく。`Stop` Hook はその「忘れ」を防ぐ安全ネットだ。

### transcript の罠

ここでハマった。最初はこう書いていた。

```javascript
// 初期バージョン（間違い）
const sizeKB = fs.statSync(tp).size / 1024;
if (sizeKB < 800) process.exit(0);
```

transcript のファイルサイズを、そのままコンテキスト消費量の代理指標にしていた。ところがあるセッションでは、transcript が7873KBまで膨らんでも警告が出ない。「800KBで警告するはずなのに、なぜ」

原因は、**transcript がコンパクション後も累積する**ことだった。コンテキスト圧縮（auto-compaction）が起きると、Claude のコンテキストはリセットされる。でも transcript ファイルには過去の会話がすべて残ったまま、`compact_boundary` というマーカーが挿入されて次のサイクルが始まる。ファイルサイズは増え続けるが、実際のコンテキスト使用量は圧縮後にリセットされている。

```json
// transcript 内の compact_boundary エントリ（実物）
{
  "type": "system",
  "subtype": "compact_boundary",
  "compactMetadata": { "trigger": "auto", "preTokens": 167052 }
}
```

だからファイルサイズをそのまま使うと、最初のサイクルでは概ね動くが、コンパクション後は累積値が増え続けて閾値が意味をなさなくなる。上の `stop-check.sh` では `compact_boundary` を見つけて**現サイクルだけを計測する**ことで、この問題を解決している。

:::message
`transcript_path` が指すファイルは非同期で書き込まれる。Stop Hook が発火した瞬間に、直前の Claude の最終応答がまだ transcript に反映されていないことがある。現サイクルのサイズを見るだけの用途（この記事の `stop-check.sh`）ではほぼ影響しないが、**Claude の最終応答の本文そのものが必要なときは transcript を読みに行かず、stdin で渡ってくる `last_assistant_message` フィールドを使う**。
:::

### 閾値のチューニング

僕は閾値を800KB（コンテキストの約80%）にしている。根拠は自分の実測だ。**auto-compaction が発動するしきい値を、Claude Code の公式ドキュメントは数値で公開していない。**「コンテキストが埋まってきたら」としか書かれていない。以下の数字はすべて僕の環境での実測からの推定だ。公式の仕様として読まないでほしい。

あるセッションで Stop Hook が発火したとき、transcript の現サイクルは982KBで、ステータスバーのコンテキスト使用率は95%だった。ここから逆算すると、次のようになる。

- 982KB ÷ 95% × 100% ≈ **1033KB ≈ 1MB**(Opus 200K tokens の JSONL サイズの実測値)
- 800KB ÷ 1033KB ≈ **77%** の時点で閾値を超える計算

このセッションでは auto-compaction が約83%で発動していた。出力バッファ分を差し引いた値だろうと僕は推測しているが、これも実測からの推定にすぎない。80%前後で警告すれば `/handoff` を実行する余裕が残る、というのが僕の環境での経験則だ。

```javascript
// 変更する場合はこの行を編集する
if (currentKB < 800) process.exit(0);
```

| 閾値 | 動作 | 向いている人 |
|------|------|------------|
| 500KB（50%） | 早めに警告 | 短いセッションを好む人 |
| **800KB**(80%) | **デフォルト** | **/handoff の余裕あり** |
| 900KB（90%） | ギリギリまで使う | 引き継ぎが間に合わないリスク |

:::message
**JSONL サイズはセッション内容で変わる。** ファイル読み込みが多いセッション（`tool_result` にファイル内容がまるごと入る）では JSONL が早く膨らみ、200K tokens で 2MB 近くになることもある。逆に会話メインのセッションでは 1MB 前後に収まる。閾値は目安として運用し、自分の使い方に合わせて調整してほしい。
:::

---

### 作った仕組みが本当に動いていたか

仕組みを作った時点では「動くはず」でしかない。半年近く運用してみて、実際に動いていたかどうかを `.claude/logs/compaction.log` で確認した。

このリポジトリのログには、2026年3月1日から2026年8月25日までの間に、自動コンパクションが36回記録されている。作った直後の1回だけでなく、半年の間ずっと `PreCompact` Hook が発火し続けていたということだ。

「仕組みを導入した」で終わらせず、ログを取る設計にしておくと、後から仕組みそのものの当否を検証できる。動いているつもりで実は発火していない、という状態にも気づける。

## Issue #25695 の提案との対応

| Issue の要求 | この記事の実装 | カバー |
|---|---|---|
| コンテキスト上限で通知 | [PreCompact Hook](#セットアップ手順) でログ記録 | 70% |
| 構造化された引き継ぎ生成 | [`/handoff` スキル](#step-3%3A-%2Fhandoff-スキルを作成) | 100% |
| ディスクに保存 | [HANDOFF.md](#step-3%3A-%2Fhandoff-スキルを作成) | 100% |
| ユーザーが編集可能 | Markdown ファイル | 100% |
| 新セッションへ自動注入 | [SessionStart Hook](#セットアップ手順) | 100% |
| セッション終了前のリマインド | [Stop Hook](#セットアップ手順)（block） | 100% |
| セッションチェーニング（履歴リンク） | **未対応** | 0% |

**筆者の体感カバー率: 約80%。** Issue #25695 は2026年4月15日（UTC）に closed（not_planned）になった。eikiyo が提案したセッションブランチング（構造化された引き継ぎ付きで新セッションに自動分岐する機能）は、プロダクト機能としては採用されなかった。だからこそ、既存の Hooks API で自分で埋める意味がある。

---

## まとめ

コンテキスト切れの問題は、Claude Code を本格的に使い始めると誰もがぶつかる壁だ。

僕は `/handoff` スキルを自作して対処してきたけど、手動運用には限界があった。公式ドキュメントの Hooks API を調べたら、`SessionStart` の `additionalContext` 注入、`Stop` の `block` 判定、`PreCompact` のログ記録という3つの仕組みが既に用意されていた。

**プロダクト機能の追加を待たなくても、今日から使える。**

Issue #25695 が提案する「完全自動のセッションブランチング」には届かないけど、日常的な痛みの大部分はこの3つの Hook で解消できる。

まず `session-start.sh` だけ設定してみてほしい。それだけでも「HANDOFF.md を読んで」の手動指示がなくなる。実感できたら `stop-check.sh` を追加して、引き継ぎ忘れの安全ネットを張る。

いずれ eikiyo が Issue #25695 で提案したセッションブランチング——構造化された引き継ぎ付きで新セッションに自動分岐する仕組み——が公式機能として実装される日も来るかもしれない。そのとき、この Hook は不要になるだろう。でも、「公式に欲しい機能がないなら、今ある API で自分で作る」という経験自体が、ツールとの付き合い方を一段深くしてくれた。機能をねだる側から、足りないものを自分で埋める側に回る。その感覚を知れたのが、僕にとっては Hook の設定そのものより大きい収穫だった。

公式の自動メモリ（auto memory）と併用するとさらに効果的だ。自動メモリがプロジェクトの知識（ビルドコマンド、テスト方法、アーキテクチャ決定）を蓄積し、この記事のシステムが作業状態（進捗、次のタスク、判断の経緯）を引き継ぐ。土台と橋の両方があって、初めて「昨日の続き」から本当に再開できる。

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
- [GitHub Issue #25695: Feature Request: Auto-branch into new session with summarized context when context limit is reached instead of forcing to /clear](https://github.com/anthropics/claude-code/issues/25695)
- [Claude Code メモリ（CLAUDE.md + rules + 自動メモリ）](https://code.claude.com/docs/ja/memory)
- [Claude Code ベストプラクティス](https://code.claude.com/docs/ja/best-practices)
- [セッションの管理（resume・continue）](https://code.claude.com/docs/ja/sessions)
- [プロンプトキャッシュ](https://code.claude.com/docs/ja/prompt-caching)
- [データの取り扱い（transcript の保持期間）](https://code.claude.com/docs/ja/data-usage)
