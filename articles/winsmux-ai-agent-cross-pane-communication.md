---
title: "AIエージェントを並列実行して会話させる：smux の Windows 版 winsmux を作った"
emoji: "🪟"
type: "tech"
topics: ["claudecode", "ai", "windows", "powershell", "個人開発"]
published: false
---

Claude Code にレビューさせながら、隣のペインで Codex に実装させたい。macOS なら smux がある。でも僕の環境は Windows だ。

WSL2 を経由すれば tmux は使える。ただ、Windows Terminal と PowerShell で完結させたかった。ネイティブで動かないと、結局もう一枚レイヤーを噛ませることになる。それが嫌だった。

そこで作ったのが **winsmux** だ。

https://github.com/Sora-bluesky/winsmux

## smux の発想が良かった

winsmux の話をする前に、元ネタの smux について触れておく。

smux は [ShawnPana](https://github.com/ShawnPana) が作った AI エージェントのマルチペイン運用ツールだ（GitHub スター 256）。構成はシンプルで、tmux と、tmux のペインを読み書きする CLI（tmux-bridge）の2つだけ。

エージェントは `tmux-bridge read` で他のペインの出力を読み、`tmux-bridge type` でテキストを入力し、`tmux-bridge keys Enter` で実行する。ペインの内容がそのまま通信チャネルになる。特別なプロトコルもメッセージキューもいらない。

この「ターミナルペインを通信チャネルにする」という発想がいい。ただし tmux は macOS と Linux 限定。Windows では動かない。

実は同じ領域のツールは 20 以上ある。cmux（11,200 スター、macOS 限定）、claude-squad（6,691 スター、WSL 必須）、Claude Code Bridge、Agent Deck、dmux……。だが「Windows ネイティブ」「ターミナルマルチプレクサ」「AI エージェント間のクロスペイン通信」の 3 つを同時に満たすツールは、調べた限り存在しなかった。

## winsmux の設計判断

winsmux は smux の「移植」ではなく、psmux 向けの再実装だ。

バックエンドには [psmux](https://github.com/marlocarlo/psmux) を使っている。Rust で書かれた Windows ネイティブの tmux 互換ツールで、ConPTY（Windows のネイティブ擬似端末）を使う。tmux のコマンド体系をほぼそのまま再現しているので、tmux に慣れた人なら違和感なく使える。

コマンド体系は smux に合わせた。`tmux-bridge` が `psmux-bridge` になる、くらいの違いしかない。smux ユーザーがそのまま移行できることを優先した。

### アーキテクチャ

```
┌──────────────┐     ┌──────────────┐
│  Claude Code  │     │    Codex      │
│   (pane %1)   │     │   (pane %2)   │
└──────┬───────┘     └──────┬───────┘
       │                      │
       └──────┐  ┌──────────┘
              │  │
       ┌──────┴──┴──────┐
       │  psmux-bridge   │
       │   (PowerShell)  │
       └───────┬────────┘
               │
       ┌───────┴────────┐
       │     psmux       │
       │  (Rust/ConPTY)  │
       └────────────────┘
```

各エージェントが `psmux-bridge` コマンドを呼ぶだけで、他のペインのエージェントと通信できる。psmux-bridge は psmux の `capture-pane` や `send-keys` を内部で呼び出す薄いラッパーだ。

## Read Guard -- 「読む前に触るな」

エージェントに自由にペインを操作させると、ろくなことにならない。確認プロンプトが出ているのに気づかず Enter を押す。入力待ちではないのにテキストを流し込む。

Read Guard はこれを防ぐ仕組みだ。**ペインを読む前に操作することを禁止する。**

```powershell
# これはエラーになる
psmux-bridge type codex "hello"
# → error: must read the pane before interacting. Run: psmux-bridge read codex
```

仕組みは単純で、`$env:TEMP\winsmux\read_marks\` にマークファイルを置いているだけだ。`read` でファイルが作られ、`type` や `keys` を実行すると消える。次の操作にはまた `read` が必要になる。

```
read → mark ON → type → mark OFF → read → mark ON → keys → mark OFF
```

ペイン ID の `%` や `:` はファイル名に使えないので `_` に置換している。`$env:TEMP` はユーザーごとに異なるから、マルチユーザー環境でも衝突しない。OS 再起動で TEMP がクリアされるのも都合がいい。

ファイルの存在チェックだけで動いている分、複数エージェントが同一ペインに同時アクセスすると競合する可能性はある。ファイルロックの導入は今後の課題。

## labels.json -- @name が使えなかった話

smux では tmux のユーザー定義オプション `@name` でペインにラベルを付けている。winsmux でも同じ方式を採用するつもりだった。

最初に試したのは `select-pane -T` でペインタイトルに名前を入れる方法だ。設定と取得はできる。ただ「ラベル名からペイン ID を逆引きする」には全ペインを走査する必要があって、ラベルテーブルとしては遠回りだった。

psmux v3.3.1 時点では `@name` 相当のユーザー定義ペインオプションがサポートされていない。正直に言うと、ここで半日くらい粘った末に JSON ファイルにフォールバックした。

```json
{
  "claude": "%1",
  "codex": "%2",
  "gemini": "%3"
}
```

`$env:APPDATA\winsmux\labels.json` に置いている。ファイル I/O が入る分はオーバーヘッドだけど、実用上は問題ない。ペイン破棄時にラベルが残る（orphan label）問題はあるが、`resolve` 時に `display-message` でペインの存在を検証しているので実害はない。

ペインタイトルの設定も best-effort で行うから、psmux のボーダーにラベル名は表示される。見た目は困らない。

## インストール

PowerShell でワンコマンド。

```powershell
irm https://raw.githubusercontent.com/Sora-bluesky/winsmux/main/install.ps1 | iex
```

:::message
`irm` は `Invoke-RestMethod`（Web からデータを取得するコマンド）、`iex` は `Invoke-Expression`（取得した内容を実行するコマンド）の省略形です。macOS/Linux の `curl | bash` に相当する Windows のインストール方法です。実行前にURLが公式リポジトリのものか確認すること。
:::

これで以下が自動的に行われる。

1. psmux がなければ winget、scoop、cargo、choco の順で自動インストール
2. `psmux-bridge` CLI を `~\.winsmux\bin\` に配置
3. `.psmux.conf`（Alt キーバインド、マウスサポート、ペインラベル表示）を配置
4. PATH の追加

手動でやる場合は、リポジトリを clone して `pwsh install.ps1` を実行する。

:::message alert
PowerShell 7（pwsh）が必要です。Windows に標準搭載されている PowerShell 5.1 では動作確認していません。`pwsh --version` で確認してください。未インストールの場合は `winget install Microsoft.PowerShell` で入る。
:::

## 使い方

### セッションの準備

```powershell
# psmux セッションを作成
psmux new-session -s work

# エージェント名を設定（message コマンドのヘッダーに使われる）
$env:WINSMUX_AGENT_NAME = "claude"
```

### コマンド一覧

10 個あるが、日常的に使うのは 6 つだ。

| コマンド | やること |
|---|---|
| `psmux-bridge list` | 全ペインの一覧表示（ID、プロセス、ラベル付き） |
| `psmux-bridge read <target> [lines]` | ペインの末尾 N 行を取得（デフォルト 50） |
| `psmux-bridge type <target> <text>` | テキストを入力（Enter は押さない） |
| `psmux-bridge keys <target> <key>...` | 特殊キーを送信（Enter, Escape, C-c など） |
| `psmux-bridge message <target> <text>` | 送信元情報付きでメッセージを送る |
| `psmux-bridge name <target> <label>` | ペインにラベルを付ける |

残り 4 つ（`resolve`, `id`, `doctor`, `version`）は補助的なもの。

### read-act-read サイクル

すべての操作は **read、act、read** の順で行う。Read Guard がこれを強制する。

```powershell
psmux-bridge read codex 20           # 1. ペインの状態を確認
psmux-bridge type codex "echo hello" # 2. テキストを入力
psmux-bridge read codex 10           # 3. 入力されたことを確認
psmux-bridge keys codex Enter        # 4. Enter を押す
```

ステップ 3 が地味に大事で、`type` したテキストが正しく入力されたことを確認してから Enter を押す。ミスタイプや入力先の取り違えを防げる。

### ペインにラベルを付ける

ペイン ID（`%1`, `%2` など）は覚えにくい。ラベルを付ける。

```powershell
psmux-bridge name %1 claude
psmux-bridge name %2 codex

# 以降はラベルで操作できる
psmux-bridge read codex 20
psmux-bridge type codex "review src/auth.ts"
```

## ユースケース

### Claude Code と Codex の協調

最も基本的な使い方。Claude Code でレビューし、Codex に実装させる。

```powershell
# === Claude Code 側（pane %1）===

# 自分と相手にラベルを付ける
psmux-bridge name (psmux-bridge id) claude
psmux-bridge list                           # 他のペインを確認
psmux-bridge name %2 codex                  # Codex のペインにラベル

# Codex にメッセージを送る（read-act-read）
psmux-bridge read codex 20
psmux-bridge message codex "src/auth.ts のリフレッシュトークン処理を実装してください"
psmux-bridge read codex 20
psmux-bridge keys codex Enter
```

`message` を使うと、送信元の情報がヘッダーとして自動で付く。

```
[psmux-bridge from:claude pane:%1 at:work:0.0 -- load the winsmux skill to reply]
src/auth.ts のリフレッシュトークン処理を実装してください
```

受信側のエージェントは、ヘッダーの `pane:%1` で返信先を特定できる。待機やポーリングは不要。相手がこちらのペインに `message` で返してくる。

### 3 エージェント体制

ペインを 3 つに分けてロール分担する。

| ペイン | ラベル | ロール | エージェント例 |
|--------|--------|--------|-------------|
| %1 | architect | 設計と指示 | Claude Code |
| %2 | builder | 実装 | Codex |
| %3 | reviewer | レビュー | Gemini CLI |

Architect が Builder に実装を指示し、完了したら Reviewer にレビューを依頼する。Reviewer のフィードバックを Builder に渡して修正させる。全部 `psmux-bridge message` で回る。

### AI エージェントと手動作業の併用

1 つのペインで自分がコードを書き、隣のペインで AI にテスト生成やリント修正をさせる。エージェントペインだけでなく、普通のシェルペインの出力も `read` で取得できるから、ビルドログを AI に読ませて修正案を出させるといった使い方もできる。

### ビルド監視

ビルド実行中のペインの出力を別ペインのエージェントに監視させる。

```powershell
# ビルドペインの出力を確認
psmux-bridge read build 50

# エラーが出ていたら修正を指示
psmux-bridge read codex 20
psmux-bridge message codex "ビルドエラーが出ている。psmux-bridge read build 50 で確認して修正してください"
psmux-bridge read codex 20
psmux-bridge keys codex Enter
```

## list コマンドの子プロセス検出

`psmux-bridge list` はペイン内で実行中のプロセスを表示する。psmux の `#{pane_current_command}` に加えて、`Get-CimInstance Win32_Process` で子プロセスの名前も取得している。

```
%1 12345 pwsh 120x30 claude (node.exe) [claude]
%2 12346 pwsh 120x30 codex (node.exe) [codex]
```

「このペインでは何が動いているのか」がひと目で分かる。エージェントが自分の list 出力を見て、相手が何をしているか判断する材料になる。

## スキル（AI エージェント向け）

winsmux skill をインストールすると、エージェントが `psmux-bridge` の使い方を自動的に理解する。

```powershell
npx skills add Sora-bluesky/winsmux
```

SKILL.md にはコマンドリファレンスだけでなく、行動規範も定義してある。「待機やポーリングをするな」「read-act-read サイクルを守れ」。返信を待たず、相手がこちらのペインに `message` で返してくるのを受け取ればいい。この非同期メッセージングの規約を skill 側で定義しておくことで、エージェントが自律的に通信できる。

## smux との比較

| 比較軸 | smux | winsmux |
|--------|------|---------|
| バックエンド | tmux | psmux（Rust / ConPTY） |
| bridge 実装 | Bash | PowerShell |
| 対象 OS | macOS / Linux | Windows |
| ラベル管理 | `@name` ペインオプション | `labels.json`（`$env:APPDATA`） |
| インストール | `curl \| bash` | `irm \| iex` |
| コマンド名 | `tmux-bridge` | `psmux-bridge` |
| Read Guard 状態 | tmp ファイル | `$env:TEMP\winsmux\read_marks\` |
| psmux 自動検出 | なし | winget、scoop、cargo、choco |

コマンド体系は 1:1 で対応している。smux ユーザーはコマンド名を置き換えるだけで移行できる。

## なぜ Agent Teams ではなく winsmux なのか

Claude Code には Agent Teams という公式のマルチエージェント機能がある。tmux 環境で動作し、チームメイトエージェントを自動的に別ペインにスポーンする。

ただし Windows では isTTY gate という制約により、Agent Teams がブロックされるケースがある（[Issue #24384](https://github.com/anthropics/claude-code/issues/24384)、[Issue #26244](https://github.com/anthropics/claude-code/issues/26244)）。winsmux はこの穴を埋める。Agent Teams とは別のレイヤーで、任意のエージェント間の対等な通信を実現する。Claude Code 同士だけでなく、Codex と Gemini CLI、あるいはエージェントと普通のシェルの間でも通信できる。

## 今後

- **Read Guard の並列エージェント対応**: ファイルロック、またはペイン ID とエージェント ID の複合キーで競合を回避する
- **psmux への @name 提案**: psmux 側でユーザー定義ペインオプションがサポートされれば labels.json を廃止できる
- **Windows Terminal との統合**: タブやペインとの連携

## 関連記事

psmux のインストールから設定、AI エージェント並列実行までの詳細は以下の記事で解説している。

https://zenn.dev/sora_biz/articles/psmux-windows-native-tmux

## 終わりに

smux が示した「ターミナルペインを通信チャネルにする」というコンセプトは OS に依存しない。Windows でも AI エージェントのマルチペイン協調ができるようになった。

試してみてほしい。

```powershell
irm https://raw.githubusercontent.com/Sora-bluesky/winsmux/main/install.ps1 | iex
```

:::message
**リポジトリ**: https://github.com/Sora-bluesky/winsmux
バグ報告や機能要望は GitHub Issues へ。
:::

---

**著者**: sora（[@sora_biz](https://x.com/sora_biz)）
