---
title: "司令塔はコードを触らない：WSL不要でAIエージェントを並列稼働させる winsmux を作った"
emoji: "🪟"
type: "tech"
topics: ["claudecode", "ai", "windows", "powershell", "個人開発"]
published: true
---

Claude Code を司令塔にして、Codex に実装させ、Codex Spark にレビューさせたい。調査は Claude Sonnet に回してコストも抑えたい。それぞれが何をやっているか、ペインで見える化もしたい。macOS なら smux がある。でも僕の環境は Windows だ。

WSL2 を経由すれば tmux は使える。ただ、Windows Terminal と PowerShell で完結させたかった。ネイティブで動かないと、結局もう一枚レイヤーを噛ませることになる。それが嫌だった。

そこで作ったのが **winsmux** だ。当初は smux の Windows 移植として psmux-bridge を書いたが、v0.10.0 ではマルチベンダー・エージェント・オーケストレーション・プラットフォームに進化した。Claude Code、Codex、Gemini CLI を同一セッションで協調させ、ロール制御・ファイルロック・資格情報管理・ヘルスチェックまでを一体で提供する。

https://github.com/Sora-bluesky/winsmux

@[tweet](https://x.com/sora_biz/status/2038184690361016626)

## smux の発想が良かった

winsmux の話をする前に、元ネタの smux について触れておく。

smux は [ShawnPana](https://github.com/ShawnPana) が作った AI エージェントのマルチペイン運用ツールだ（GitHub スター 256、2026 年 3 月時点）。構成はシンプルで、tmux と、tmux のペインを読み書きする CLI（tmux-bridge）の2つだけ。

エージェントは `tmux-bridge read` で他のペインの出力を読み、`tmux-bridge type` でテキストを入力し、`tmux-bridge keys Enter` で実行する。ペインの内容がそのまま通信チャネルになる。特別なプロトコルもメッセージキューもいらない。

この「ターミナルペインを通信チャネルにする」という発想がいい。ただし tmux は macOS と Linux 限定。Windows では動かない。

実は同じ領域のツールは 20 以上ある。cmux（11,200 スター）、claude-squad（6,691 スター）、Claude Code Bridge、Agent Deck、dmux……（スター数は 2026 年 3 月時点）。だが「Windows ネイティブ」「ターミナルマルチプレクサ」「AI エージェント間のクロスペイン通信」の 3 つを同時に満たすツールは、調べた限り存在しなかった。

## winsmux の設計判断

winsmux は smux の「移植」ではなく、psmux 向けの再実装から始まり、現在はエージェント・オーケストレーション・プラットフォームに発展した。コマンド体系は smux 互換を維持しつつ、Orchestra（Commander / Builder / Reviewer のマルチロール構成）、Shield Harness（22 の security hooks）、Vault（DPAPI ベースの資格情報管理）、Mailbox（Named Pipe IPC）などを追加している。

バックエンドには [psmux](https://github.com/marlocarlo/psmux) を使っている。Rust で書かれた Windows ネイティブの tmux 互換ツールで、ConPTY（Windows のネイティブ擬似端末）を使う。tmux のコマンド体系をほぼそのまま再現しているので、tmux に慣れた人なら違和感なく使える。

コマンド体系は smux に合わせた。`tmux-bridge` が `psmux-bridge` になる、くらいの違いしかない。smux ユーザーがそのまま移行できることを優先した。

### アーキテクチャ

```
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Claude Code  │  │    Codex      │  │  Gemini CLI   │
│   (Builder)   │  │  (Builder)    │  │  (Reviewer)   │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                  │                  │
       └────────┐  ┌─────┘  ┌──────────────┘
                │  │  │
         ┌──────┴──┴──┴──────┐
         │    psmux-bridge    │
         │ ┌───────────────┐ │
         │ │ Role Gate      │ │
         │ │ Shared Task    │ │
         │ │ Mailbox Router │ │
         │ │ Vault (DPAPI)  │ │
         │ │ Health Check   │ │
         │ └───────────────┘ │
         └────────┬──────────┘
                  │
         ┌────────┴──────────┐
         │  Shield Harness    │
         │   (22 hooks)       │
         └────────┬──────────┘
                  │
         ┌────────┴──────────┐
         │      psmux         │
         │   (Rust/ConPTY)    │
         └───────────────────┘
```

各エージェントが `psmux-bridge` コマンドを呼ぶだけで、他のペインのエージェントと通信できる。psmux-bridge は psmux をバックエンドとしたエージェント・オーケストレーション CLI だ。基本操作（read / send / type / keys）は psmux の capture-pane / send-keys を内部で呼び出すが、ロール制御・ファイルロック・Vault・Mailbox・ヘルスチェックなど、エージェント間協調に必要な機能を一体化している。

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

ファイルの存在チェックだけで動いている分、複数エージェントが同一ファイルに同時アクセスする場合の競合が心配だった。v0.10.0 で導入した `lock` / `unlock` コマンドで解決した。`FileMode::CreateNew` を使ったアトミックなロック獲得により、複数エージェントが同時に `lock` を試みてもレース安全に動作する。ロックには 30 分の自動期限があり、エージェントの異常終了時にも放置されない。

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

実はもっと楽な方法がある。Claude Code や Codex に GitHub リポジトリの URL を渡して「このプロジェクトに winsmux をインストールして」と言えばいい。インストールスクリプトの中身を読んで、環境に合わせて勝手にやってくれる。自分でコマンドを打つ時代はもう終わった。

:::message alert
PowerShell 7（pwsh）が必要です。Windows に標準搭載されている PowerShell 5.1 では動作確認していません。`pwsh --version` で確認してください。未インストールの場合は `winget install Microsoft.PowerShell` で入る。
:::

## 使い方

以下はコマンドの詳細だが、正直、全部覚える必要はない。Claude Code や Codex に winsmux skill をインストールすれば、エージェントが `psmux-bridge` の使い方を勝手に理解して動く。人間が叩くコマンドは `psmux new-session` くらいだ。

コマンドを暗記する必要はない。わからないことをエージェントに素直に聞ける人が、いちばん速く動ける時代になった。

### セッションの準備

```powershell
# psmux セッションを作成
psmux new-session -s work

# エージェント名を設定（message / send の送信元識別に使われる）
$env:WINSMUX_AGENT_NAME = "claude"
```

### コマンド一覧

28 コマンド（vault は 4 サブコマンドを持つ）あるが、日常的に使うのは `list` / `read` / `send` / `name` / `health-check` の 5 つだ。

#### 基本操作（日常的に使う）

| コマンド | 説明 |
|---|---|
| `list` | 全ペイン一覧（ID、プロセス、ラベル付き） |
| `read <target> [lines]` | ペインの末尾 N 行を取得（デフォルト 200） |
| `send <target> <text>` | テキスト入力 + Enter + 変更検出（推奨） |
| `name <target> <label>` | ペインにラベルを付ける |
| `resolve <label>` | ラベルからペイン ID を引く |
| `id` | 自分のペイン ID を表示 |
| `focus <label\|target>` | アクティブペインを切替 |

#### テキスト入力（細かい制御が必要な場合）

| コマンド | 説明 |
|---|---|
| `type <target> <text>` | テキストを入力（Enter は押さない） |
| `keys <target> <key>...` | 特殊キーを送信（Enter, Escape, C-c 等） |
| `message <target> <text>` | 送信元情報付きでメッセージを送る（Enter なし） |

#### 同期制御

| コマンド | 説明 |
|---|---|
| `wait <channel> [timeout]` | シグナル待機（デフォルト 120 秒） |
| `signal <channel>` | シグナル送信 |
| `watch <label> [silence_s] [timeout_s]` | ペイン出力が静かになるまで待機 |
| `wait-ready <target> [timeout]` | エージェントプロンプト出現を待機 |
| `health-check` | 全ペインの READY/BUSY/HUNG/DEAD 判定 |

#### ファイルロック

| コマンド | 説明 |
|---|---|
| `lock <label> <file>...` | ファイルロック獲得（レース安全） |
| `unlock <label> <file>...` | ファイルロック解放 |
| `locks` | アクティブロック一覧 |

#### Mailbox（Named Pipe IPC）

| コマンド | 説明 |
|---|---|
| `mailbox-create <ch>` | チャネルのリスナーを作成 |
| `mailbox-send <ch> <json>` | JSON メッセージを送信 |
| `mailbox-listen <ch>` | mailbox-create のエイリアス |

#### Vault（資格情報管理）

| コマンド | 説明 |
|---|---|
| `vault set <key> [value]` | Windows Credential Manager に保存（DPAPI） |
| `vault get <key>` | 資格情報取得 |
| `vault inject <pane>` | 全資格情報を環境変数として注入 |
| `vault list` | 保存済みキー一覧 |

#### 入力支援

| コマンド | 説明 |
|---|---|
| `ime-input <target>` | GUI ダイアログで日本語 IME 入力 |
| `image-paste <target>` | クリップボード画像を保存しパス送信 |
| `clipboard-paste <target>` | クリップボードテキストをペインに送信 |

#### ユーティリティ

| コマンド | 説明 |
|---|---|
| `profile [name] [agents]` | Windows Terminal プロファイル登録 |
| `doctor` | 環境チェック + IME 診断 |
| `version` | バージョン表示 |

### read-act-read サイクル

すべての操作は **read、act、read** の順で行う。Read Guard がこれを強制する。

```powershell
psmux-bridge read codex 20           # 1. ペインの状態を確認
psmux-bridge send codex "echo hello" # 2. テキスト入力 + Enter + 変更検出
psmux-bridge read codex 20           # 3. 結果を確認
```

`send` は内部で テキスト入力 → 300ms 待機 → Enter → `[Pasted Content]` 検出時の二重 Enter 対策 → watermark 保存 を一括実行する。細かい制御が必要な場合は従来の `type` + `keys` も使える。

ステップ 3 で結果を確認することで、意図したコマンドが正しく実行されたかを検証できる。

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

# Codex にタスクを送る（read-act-read）
psmux-bridge read codex 20
psmux-bridge send codex "src/auth.ts のリフレッシュトークン処理を実装してください"
```

:::message
`send` はテキストをそのまま送る。送信元情報のヘッダーを付けたい場合は `message` + `keys Enter` を使う。`message` を使うと、送信元の情報がヘッダーとして自動で付く。
:::

`message` のヘッダー例:

```
[psmux-bridge from:claude pane:%1 at:work:0.0 -- load the winsmux skill to reply]
src/auth.ts のリフレッシュトークン処理を実装してください
```

受信側のエージェントは、ヘッダーの `pane:%1` で返信先を特定できる。待機やポーリングは不要。相手がこちらのペインに `message` で返してくる。

### 3 エージェント体制

ペインを 3 つに分けてロール分担する。

| ペイン | ラベル    | ロール     | エージェント例          |
| ------ | --------- | ---------- | ----------------------- |
| %1     | architect | 設計と指示 | Claude Code             |
| %2     | builder   | 実装       | Codex                   |
| %3     | reviewer  | レビュー   | Codex（別インスタンス） |

Architect が Builder に実装を指示し、完了したら Reviewer にレビューを依頼する。Reviewer のフィードバックを Builder に渡して修正させる。全部 `psmux-bridge send` で回る。ヘッダー付きで送りたいときだけ `message` を使う。

実際に僕が使っている構成がこれ。4 ペインに分けて、Claude Code が全体を指揮し、Codex 2 台が実装とレビューを分担、残り 1 ペインで dev server を監視している。

![winsmux 4ペイン構成の実例：Claude Code（commander）+ Codex×2（builder/reviewer）+ dev server（monitor）](/images/winsmux-4pane-demo.png)

| ペイン  | ラベル    | ロール     | 実行中のエージェント/プロセス   |
| ------- | --------- | ---------- | ------------------------------- |
| 左上 %1 | commander | 全体指揮   | Claude Code                     |
| 右上 %3 | builder   | 実装       | Codex（gpt-5.4）                |
| 右下 %6 | reviewer  | レビュー   | Codex（gpt-5.3-codex-spark）    |
| 左下 %5 | monitor   | ビルド監視 | Next.js dev server（port 3003） |

### コマンダーを psmux から切り離す構成

もうひとつ、こういうやり方もできる。psmux の 4 ペインを完全にバックグラウンド処理にして、別のターミナルをコマンダー専用に立ち上げる構成だ。

![winsmux コマンダー切り離し構成：psmux 4ペイン（ビルダー×2 + リサーチャー + レビュアー）＋別ターミナルの指揮官](/images/winsmux-detached-commander.png)

| 位置         | ロール       | エージェント       |
| ------------ | ------------ | ------------------ |
| psmux 左上   | ビルダー 1   | Codex              |
| psmux 右上   | ビルダー 2   | Codex              |
| psmux 左下   | リサーチャー | Claude Code Sonnet |
| psmux 右下   | レビュアー   | Codex              |
| 別ターミナル | 指揮官       | Claude Code Opus   |

コマンダーは psmux の中にいないが、`psmux-bridge` コマンドで各ペインとの通信は問題なくできる。psmux から切り離すメリットは日本語入力だ。psmux 内のペインでは IME の挙動が不安定になることがあるが、独立したターミナルならその制約がない。指揮官は指示を出す側なので、日本語で自然に書けるほうが圧倒的に楽だ。

別ターミナルのコマンダーには、最初にこういうプロンプトを渡す。

```
あなたはCommanderです。自分でコードを書いたり設計を進めたりしないでください。

あなたの役割は指揮のみです。作業は以下のエージェントに psmux-bridge で委任してください：
- builder-1, builder-2: 実装（並列可能）
- researcher: 調査・分析
- reviewer: コードレビュー
```

これでコマンダーが自分で手を動かさなくなる。実装は builder に振り、調査は researcher に回し、完成したら reviewer にレビューさせる。人間がやることは、最初にこのプロンプトを渡して「〇〇を作って」と言うだけだ。

### AI エージェントと手動作業の併用

1 つのペインで自分がコードを書き、隣のペインで AI にテスト生成やリント修正をさせる。エージェントペインだけでなく、普通のシェルペインの出力も `read` で取得できるから、ビルドログを AI に読ませて修正案を出させるといった使い方もできる。

### ビルド監視

ビルド実行中のペインの出力を別ペインのエージェントに監視させる。

```powershell
# ビルドペインの出力を確認
psmux-bridge read build 50

# エラーが出ていたら修正を指示
psmux-bridge read codex 20
psmux-bridge send codex "ビルドエラーが出ている。psmux-bridge read build 50 で確認して修正してください"
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

| 比較軸          | smux                     | winsmux                         |
| --------------- | ------------------------ | ------------------------------- |
| バックエンド    | tmux                     | psmux（Rust / ConPTY）          |
| bridge 実装     | Bash                     | PowerShell                      |
| 対象 OS         | macOS / Linux            | Windows                         |
| ラベル管理      | `@name` ペインオプション | `labels.json`（`$env:APPDATA`） |
| インストール    | `curl \| bash`           | `irm \| iex`                    |
| コマンド名      | `tmux-bridge`            | `psmux-bridge`                  |
| Read Guard 状態 | tmp ファイル             | `$env:TEMP\winsmux\read_marks\` |
| psmux 自動検出  | なし                     | winget、scoop、cargo、choco     |

コマンド体系は 1:1 で対応している。smux ユーザーはコマンド名を置き換えるだけで移行できる。

## なぜ Agent Teams ではなく winsmux なのか

Claude Code には Agent Teams という公式のマルチエージェント機能がある。tmux 環境で動作し、チームメイトエージェントを自動的に別ペインにスポーンする。

ただし Windows では isTTY gate という制約により、Agent Teams がブロックされるケースがある（[Issue #24384](https://github.com/anthropics/claude-code/issues/24384)、[Issue #26244](https://github.com/anthropics/claude-code/issues/26244)）。winsmux はこの穴を埋める。Agent Teams とは別のレイヤーで、任意のエージェント間の対等な通信を実現する。Claude Code 同士だけでなく、Codex と Gemini CLI、あるいはエージェントと普通のシェルの間でも通信できる。

## 今後

### 実装済み

- ~~**Read Guard の並列エージェント対応**~~ → v0.10.0 で `lock` / `unlock` コマンドとして実装済み。`FileMode::CreateNew` によるアトミックなロック獲得、30 分自動期限切れ、ラベル所有権チェック。
- ~~**Windows Terminal との統合**~~ → v0.10.0 で `profile` コマンドとして実装済み。Windows Terminal Fragments 経由で winsmux Orchestra プロファイルをドロップダウンに自動登録。

### 残タスク

- **psmux への @name 提案** -- labels.json で実用上の問題がないため、優先度を下げている。psmux 側でユーザー定義ペインオプションがサポートされれば移行を検討。

### 新たな展望

- **Agent Teams 互換の統合テスト** -- Orchestra のフルサイクル（タスク作成 → Claim → 完了 → Hook 発火 → 次タスク自動ディスパッチ）の実機検証
- **ExecPolicy DSL** -- 宣言的コマンド許可ルール（TOML ベース）
- **Event Stream** -- Orchestra 全体のリアルタイム・イベントバス
- **Guardian サブエージェント** -- マルチベンダー相互チェック（builder が Codex なら Guardian は Claude）

## v0.10.0: smux 互換を超えて

v0.10.0 で winsmux は「smux の Windows 版」から「マルチベンダー・エージェント・オーケストレーション・プラットフォーム」に変わった。ここでは主要な追加機能を紹介する。

### Orchestra -- マルチエージェント自動起動

`.psmux-bridge.yaml` でエージェント構成を定義し、`orchestra-start` で一括起動する。ペイン配置、エージェント起動、ラベル付け、Vault 注入が自動化される。

```powershell
# Commander 1 + Builder 4 + Reviewer 1 を一括起動
orchestra-start
```

### Shield Harness -- 22 のセキュリティフック

`.claude/hooks/` に 22 の JavaScript フックを配置する。プロンプトインジェクション検出、データ境界制御、Evidence Ledger（OCSF 準拠の監査ログ + SHA-256 ハッシュチェーン）を自動適用する。エージェントを野放しにしないためのガードレールだ。

### Shared Task List -- エージェント間のタスク協調

Claude Code Agent Teams の Shared Task List と同等の機能。ファイルロック付きの自己 Claim、依存関係の自動解決、TaskCreated / TaskCompleted フックによる Commander への自動通知。タスクが終わったら次のタスクが勝手に回る。

### Mailbox -- Named Pipe による非同期メッセージング

ペインのテキスト注入（`send` / `message`）に加えて、Named Pipe ベースの構造化メッセージングを使える。broadcast 対応、リトライキュー内蔵。ペインを経由しない裏の通信チャネルだ。

### マルチベンダー対応

Claude Code、Codex、Gemini CLI を同一 Orchestra で同時運用できる。ベンダーロックインなしで、各エージェントの得意分野を組み合わせられる。実装は Codex、レビューは Gemini、指揮は Claude Code という使い分けが自然にできる。

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
