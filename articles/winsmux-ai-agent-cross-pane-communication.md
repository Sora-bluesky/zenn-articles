---
title: "司令塔はコードを触らない：WSL不要でAIエージェントを並列稼働させる winsmux を作った"
emoji: "🪟"
type: "tech"
topics: ["claudecode", "ai", "windows", "powershell", "個人開発"]
published: true
---

Claude Code を司令塔にして、Codex に実装させ、別の Codex にレビューさせたい。調査は Antigravity CLI に回してコストも抑えたい。それぞれが何をやっているか、ペインで見える化もしたい。macOS なら smux がある。でも僕の環境は Windows だ。

WSL2 を経由すれば tmux は使える。ただ、Windows Terminal と PowerShell で完結させたかった。ネイティブで動かないと、結局もう一枚レイヤーを噛ませることになる。それが嫌だった。

そこで作ったのが **winsmux** だ。当初は smux の Windows 移植として psmux-bridge を書いたが、現在は単独の `winsmux` CLI と Rust 製ランタイム `winsmux-core`、そして Tauri 製のデスクトップアプリが束になった「Windows ネイティブの管制デスク」になっている。Claude Code、Codex、Antigravity CLI を同じワークスペースで並走させ、ペイン制御・worktree 分離・資格情報保護・実行結果の比較・レビュー証跡までを一体で提供する。

https://github.com/Sora-bluesky/winsmux

@[tweet](https://x.com/sora_biz/status/2038184690361016626)

## smux の発想が良かった

winsmux の話をする前に、元ネタの smux について触れておく。

smux は [ShawnPana](https://github.com/ShawnPana) が作った AI エージェントのマルチペイン運用ツールだ。構成はシンプルで、tmux と、tmux のペインを読み書きする CLI（tmux-bridge）の2つだけ。

エージェントは `tmux-bridge read` で他のペインの出力を読み、`tmux-bridge type` でテキストを入力し、`tmux-bridge keys Enter` で実行する。ペインの内容がそのまま通信チャネルになる。特別なプロトコルもメッセージキューもいらない。

この「ターミナルペインを通信チャネルにする」という発想がいい。ただし tmux は macOS と Linux 限定。Windows では動かない。

同じ領域のツールは 20 以上ある。cmux、claude-squad、Claude Code Bridge、Agent Deck、dmux……。だが「Windows ネイティブ」「ターミナルマルチプレクサ」「AI エージェント間のクロスペイン通信」の 3 つを同時に満たすツールは、調べた限り存在しなかった。

## winsmux のいま

winsmux は smux の「移植」ではなく、psmux-bridge という Windows 用 PowerShell ブリッジから始まり、その後 Rust 製ランタイム `winsmux-core` を取り込み、Tauri 製のデスクトップアプリまで持つ管制デスクに進化した。

現在の構成は3層になっている。

- **`winsmux` CLI**：人間とエージェントが叩く統一インターフェース。`psmux-bridge` という名前は今は使わない
- **`winsmux-core`**：ConPTY（Windows のネイティブ擬似端末）を使う Rust 製のターミナルランタイム
- **デスクトップアプリ**：Tauri + xterm.js で組んだ専用の管制画面。プロジェクトを選んでオペレーターと worker のペインを並べる。ワークスペース自体は `winsmux launch` が立ち上げる Windows Terminal 側で、デスクトップアプリはその上に乗せる管制 UI(ペイン状況・ワーカー一覧・記録済みセッションの復元)

`winsmux launch` を打つと、管理されたワークスペースが立ち上がり、既定で 6 つの **ワーカースロット**（w1〜w6）が用意される。各スロットはバックエンドを持っていて、ローカル CLI、Codex、Antigravity CLI、Grok Build、OpenRouter 経由の外部 API モデル、仮置きから選べる。生成される最初のスロットは既定で Codex レビュー用になる。

最近の版では、記録済みセッションの復元候補（Agent Vault で検索して、選んだ実行をワーカーペインへドラッグして復元）と、外部自動化クライアント向けのローカル named pipe JSON-RPC（外部コントロールプレーン API）も入った。

「自分は smux の Windows 移植が欲しかっただけなんだが？」と聞かれたら、その通りだと答える。ただ、Windows でエージェントを並列稼働させ続けて分かったのは、ペインの読み書きだけでは足りないということだった。誰がどのファイルを触ったか、どっちの結果を採用するか、どこに資格情報を置くか。そこまで面倒を見ないと、結局オペレーターが消耗する。

### アーキテクチャ

![winsmuxのシステム構成図](/images/winsmux-architecture.png)

人間(USER)が直接叩くのはオペレーターペイン(Operator Pane)だけだ。オペレーターペインに座ったClaude Codeが、`winsmux send` / `read`で6つのワーカーペインへ指示を流し、各ペインで走っているClaude Code / Codex / Antigravity CLI / Grok Build / Sakana AI / Z.aiなどへ作業を委ねる(図中の「Antigravity」は「Antigravity CLI」を指す)。やり取りは双方向で、ワーカー側の出力もそのままペインを通って戻ってくる。ワーカー同士もペイン経由で直接やり取りできる。`winsmux`は管制CLIで、内部で`winsmux-core`のペイン操作を呼びつつ、ロール制御・worktree分離・Vault・Mailbox・ヘルスチェック・実行結果の比較まで一体化している。

ライセンスは Apache 2.0。互換維持のため core 配下の一部に上流 MIT 通知が残っている。

## Read Guard -- 「読む前に触るな」

エージェントに自由にペインを操作させると、ろくなことにならない。確認プロンプトが出ているのに気づかず Enter を押す。入力待ちではないのにテキストを流し込む。

Read Guard はこれを防ぐ仕組みだ。**ペインを読む前に操作することを禁止する。**

```powershell
# これはエラーになる
winsmux type worker-1 "hello"
# → error: must read the pane before interacting. Run: winsmux read worker-1
```

仕組みは単純で、`$env:TEMP\winsmux\read_marks\` にマークファイルを置いているだけだ。`read` でファイルが作られ、`type` や `keys` を実行すると消える。次の操作にはまた `read` が必要になる。

```
read → mark ON → type → mark OFF → read → mark ON → keys → mark OFF
```

`$env:TEMP` はユーザーごとに異なるから、マルチユーザー環境でも衝突しない。OS 再起動で TEMP がクリアされるのも都合がいい。

複数エージェントが同じファイルを編集する場合の競合は `winsmux lock` / `unlock` で吸収する。PowerShell から `[IO.FileMode]::CreateNew` でファイルを排他作成するアトミックなロック獲得により、同時に `lock` を試みてもレース安全に動作する。ロックには 30 分の自動期限があり、エージェントの異常終了時にも放置されない。

## ワーカースロットというラベリング

初期の winsmux ではペインに自前でラベルを付ける必要があり、`labels.json` というファイルで管理していた。今はその仕組みごと **ワーカースロット** モデルに置き換わっている。

`winsmux launch` で立ち上がるワークスペースには、最初から `w1`〜`w6` という固定のスロットが用意される。短縮名 `w1` と長い名前 `worker-1` のどちらでも参照できる。各スロットにはバックエンド（local / Codex / Antigravity CLI / Grok Build / 外部 API（OpenRouter 等）/ placeholder）が紐づき、状況は `winsmux workers status` で見える。

```powershell
winsmux workers status
# w1  ready    codex
# w2  ready    claude-code
# w3  ready    antigravity
# ...
```

一時期 Google Colab の GPU ワーカー（H100/A100）にも対応していたが、この経路は廃止された。ローカル CLI で動かないクラウド側モデルは、OpenRouter 経由の外部 API ワーカーとして統一的に扱う。

ラベルの命名で悩む必要がなくなったし、worktree も slot ごとに自動的に分離される。

## インストール

:::message alert
PowerShell 7（pwsh）と Windows Terminal、Node.js + `npm` が必要です。`pwsh --version` と `node --version` で確認してください。未インストールの場合は `winget install Microsoft.PowerShell` と `winget install OpenJS.NodeJS.LTS` で入る。
:::

公式ドキュメント上の推奨経路はデスクトップアプリのインストーラーに変わったが、この記事は CLI 中心の運用を扱うので npm 経路で説明する。CLI 中心で入れる場合の最短手順は次の 4 行だ。

```powershell
npm install -g winsmux
winsmux install --profile full
winsmux init
winsmux launch
```

`npm install -g winsmux` で CLI 本体が入り、`winsmux install --profile full` で支援スクリプトと Windows Terminal プロファイル、Vault、監査スクリプトを所定の場所に配置する。`winsmux init` でプロジェクト設定を作り、`winsmux launch` で管理ワークスペースを起動する。

デスクトップアプリを使う場合は、対象の [GitHub Release](https://github.com/Sora-bluesky/winsmux/releases) から `winsmux_<version>_x64-setup.exe` を取得して実行し、エージェントに作業させたいプロジェクトフォルダーを選ぶ。配布ツール向けの MSI（`winsmux_<version>_x64_en-US.msi` / `_ja-JP.msi`）と、確認用の `SHA256SUMS-desktop` も同じリリースに置いてある。

### プロファイル

| プロファイル | 入るもの | 向いている用途 |
|---|---|---|
| `core` | ランタイム、ラッパースクリプト、PATH、基本設定 | ターミナルランタイムだけ欲しい |
| `orchestra` | core + オーケストレーション用スクリプト + Windows Terminal プロファイル | 1 人のオペレーターが管理ペインを動かす |
| `security` | core + vault + 監査スクリプト | フル構成は要らないが資格情報は守りたい |
| `full` | core + orchestra + security | 標準。迷ったらこれ |

インストールが終わったら確認する。

```powershell
winsmux version
winsmux doctor
```

`winsmux doctor` は PowerShell の起動、Windows Terminal、リポジトリ設定、プロセス数、ワークスペースの前提条件を一通りチェックしてくれる。

更新は `winsmux update`。前回のプロファイルを覚えているので、プロファイル指定なしでも問題ない。アンインストールは `winsmux uninstall`。エージェント CLI 本体と認証情報は触らない。

## 使い方

ここからはコマンドの詳細だが、正直、全部覚える必要はない。`winsmux skills` でエージェントが読めるコマンド仕様を出力できるので、Claude Code や Codex はそれを読んで勝手に使う。人間が叩くのは最初の4行（`npm install` から `winsmux launch` まで）と、たまの `list` / `read` / `send` / `compare runs` くらいだ。

コマンドを暗記する必要はない。わからないことをエージェントに素直に聞ける人が、いちばん速く動ける時代になった。

### コマンド一覧

`winsmux help` で全量見られるが、よく使うのを抜き出しておく。

#### セッション操作（日常的に使う）

| コマンド | 説明 |
|---|---|
| `winsmux init` | プロジェクト設定を作成 |
| `winsmux launch` | 管理ワークスペースを起動 |
| `winsmux list` | 全ペイン一覧 |
| `winsmux read <target> [lines]` | ペイン末尾 N 行を取得 |
| `winsmux send <target> <text>` | テキスト + Enter + 変更検出を一括実行 |
| `winsmux message <target> <text>` | 送信元ヘッダー付きでテキスト送信(`pane:`で返信先を特定) |
| `winsmux health-check` | 全ペインの READY / BUSY / HUNG / DEAD 判定 |
| `winsmux focus <target>` | アクティブペインを切替 |

#### ワーカー制御

| コマンド | 説明 |
|---|---|
| `winsmux workers status` | スロット一覧（バックエンド / 状態 / プロバイダー / モデル / 直近コマンド） |
| `winsmux workers doctor` | ワーカー設定、外部 API メタデータ、認証、状態ファイルを診断 |
| `winsmux workers exec <slot> ...` | OpenAI 互換 API（`api_llm`）または Antigravity CLI での一回実行。API キー未設定なら通信前に停止 |
| `winsmux workers logs <slot>` | `api_llm` / Antigravity ワーカー実行の保存済みログを読む |
| `winsmux launcher presets` | 起動プリセットとペア構成テンプレートを表示 |

#### 比較と証跡

| コマンド | 説明 |
|---|---|
| `winsmux review-pack <run_id>` | 変更ファイル / テスト結果 / リスク / 実行コマンド / 成果物参照だけの「レビュー用パケット」を書き出す |
| `winsmux compare runs <l> <r>` | 2 つの記録済み実行の証跡と信頼度を比較 |
| `winsmux compare preflight <l> <r>` | マージ前に 2 つの git 参照を確認 |
| `winsmux compare promote <run_id>` | 採用した実行結果を次の実行の入力として書き出す |
| `winsmux meta-plan --task "..."` | 実行前に読み取り専用で、複数ロールでの計画パケットを作成 |

#### 資格情報

| コマンド | 説明 |
|---|---|
| `winsmux vault set <key> [value]` | Windows DPAPI で資格情報を保存 |
| `winsmux vault get <key>` | 取得 |
| `winsmux vault inject <slot>` | 保存済み資格情報を対象ペインの環境変数として注入 |
| `winsmux vault list` | 保存済みキー一覧 |

#### その他

| コマンド | 説明 |
|---|---|
| `winsmux skills [--json]` | エージェント向けコマンド仕様の出力 |
| `winsmux lock` / `unlock` / `locks` | ファイルロックの獲得 / 解放 / 確認 |
| `winsmux doctor` | 環境チェック |
| `winsmux version` | バージョン表示 |

互換目的の旧コマンド名 `psmux` / `pmux` / `tmux` は配布していない。スクリプトやドキュメントでは `winsmux` を使う。tmux 互換の設定・ターゲット・コマンドは、ドキュメントで明記した範囲では引き続き使える。

### read-act-read サイクル

すべての操作は **read、act、read** の順で行う。Read Guard がこれを強制する。

```powershell
winsmux read worker-1 20             # 1. ペインの状態を確認
winsmux send worker-1 "echo hello"   # 2. テキスト入力 + Enter + 変更検出
winsmux read worker-1 20             # 3. 結果を確認
```

`send` は内部で テキスト入力 → 300ms 待機 → Enter → `[Pasted Content]` 検出時の二重 Enter 対策 → watermark 保存 を一括で行う。細かい制御が必要な場合は `type` + `keys` も使える。

ステップ 3 で結果を確認することで、意図したコマンドが正しく実行されたかを検証できる。

## ユースケース

### Claude Code と Codex の協調

最も基本的な使い方。Claude Code に設計と指揮を任せ、Codex に実装させる。

```powershell
winsmux launch                       # ワークスペースが立ち上がる
winsmux workers status               # w1 / w2 ... を確認

# w1 = Claude Code, w2 = Codex として、Codex にタスクを送る
winsmux read worker-2 20
winsmux send worker-2 "src/auth.ts のリフレッシュトークン処理を実装してください"
```

送信元情報のヘッダーを付けたい場合は `winsmux message` を使う。ヘッダーの `pane:` で返信先を特定できるので、相手は待たずにこちらのペインへ返してくる。

### 6 ワーカー体制

実際に僕が使っている構成がこれ。司令塔の Opus 4.8 が左のオペレーターペインに座り、右側の6つのワーカーペインに別々のエージェントを並走させている。

![winsmuxの実機構成:左にオペレーターペイン(Opus 4.8)、右に6つのワーカーペインが並んでいる](/images/winsmux-6workers-live.jpg)

ロールは各モデルの特性と単価で振り分けている。実装で手を動かすのは worker-2 だけで、残りはレビュー・調査・テスト生成・リサーチなど「コードを直接書かない」役割に寄せた。「高単価で能力の高いモデルは判断専用にし、実装は安価モデルに並列で投げる」という方針を 1 ペイン = 1 ロールに落とし込んでいる。

| 位置 | スロット | ロール | 実行中のエージェント / モデル |
| --- | --- | --- | --- |
| オペレーターペイン | — | オペレーター(指揮・最終承認) | Claude Code(Opus 4.8) |
| 右上 左 | worker-1 | 設計レビュー・アーキ判定 | Claude Code(Opus 4.8 / Ultra effort) |
| 右上 中 | worker-2 | メイン実装(難所) | Codex(GPT-5.6 Sol / X High) |
| 右上 右 | worker-3 | 調査・長文要約 | Antigravity CLI(Gemini 3.5 Flash / High) |
| 右下 左 | worker-4 | リアルタイム情報リサーチ | Grok Build(Grok 4.3) |
| 右下 中 | worker-5 | コードレビュー(2次・詳細) | Sakana Fugu Ultra(OpenRouter経由) |
| 右下 右 | worker-6 | テスト生成・バグ再現 | Z.ai GLM-5.2(OpenRouter経由) |

ペイン枠の色や状態(`live output` / `idle` / `ready`)が一目でわかるので、誰が止まっているか・誰が走っているかをオペレーターペインから眺めるだけで判断できる。

worker-1 の Opus 4.8 で大局的なレビュー(設計とアーキの妥当性)、worker-5 の Sakana Fugu Ultra でコードの詳細レビューと、レビューを 2 段構えにしている。Sakana Fugu Ultra は単価が高いぶん能力も高いので、メイン実装の代わりに「実装結果に対する詳細レビュー専用」として置いておくのが費用対効果がよい。

### ワーカーごとにモデルとエフォートを切り替える

ロール分担を実現するための設定 UI は Settings → RUNTIME → Pane model settings にある。

![winsmuxの設定画面:各worker paneにprovider/model/effortを個別に割り当てる](/images/winsmux-pane-settings.png)

「All panes use the default」(全ペイン共通モデル)と「Set each pane individually」(ペインごとに別モデル)の 2 モードがあり、後者を選ぶと worker-1〜worker-6 それぞれに provider + model + effort を別々に割り当てられる。スクリーンショットは worker-5 を OpenRouter 経由の Sakana Fugu Ultra、worker-6 を Z.ai GLM-5.2 に切り替えた状態。

実装は GLM-5.2 や Gemini 3.5 Flash のような安価高速モデルに大量並列で投げて、レビューは Sakana Fugu Ultra や Opus 4.8 にだけ通す。逆に試したいだけの軽い検証用ペインは Gemini 3.5 Flash のような低単価モデルで回す、という具合に「単価とロール」を 1:1 で結びつけられる。

各行の右側には `runnable` / `setup-required` / `blocked` といった状態バッジと Source(`Official docs` / `Local CLI catalog` / `Provider API`)が出るので、API キー未設定や CLI 未インストールでハマることもなくなった。

### 並走させて比較する

同じタスクを 2 つのワーカーに並走させ、終わったあとに結果を比較する使い方もある。

```powershell
winsmux workers exec w1 --task-json tasks/auth-refresh.json --run-id auth-a
winsmux workers exec w2 --task-json tasks/auth-refresh.json --run-id auth-b

# 終わったら比較
winsmux compare runs auth-a auth-b

# 採用した方を次の入力に
winsmux compare promote auth-a
```

`compare runs` は 2 つの記録済み実行を、変更ファイルの重なり、レビュー状態、検証状態、チェックポイントの観点で並べる。レビュー材料を出すだけで、採用するか捨てるかは人間が決める。

### AI エージェントと手動作業の併用

1 つのペインで自分がコードを書き、隣のペインで AI にテスト生成やリント修正をさせる。エージェントペインだけでなく、普通のシェルペインの出力も `winsmux read` で取得できるから、ビルドログを AI に読ませて修正案を出させるといった使い方もできる。

## list コマンドの子プロセス検出

`winsmux list` はペイン内で実行中のプロセスを表示する。psmux 系の `#{pane_current_command}` に加えて、`Get-CimInstance Win32_Process` で子プロセスの名前も取得している。

```
worker-1  12345  pwsh  120x30  claude (node.exe)  [claude-code]
worker-2  12346  pwsh  120x30  codex  (node.exe)  [codex]
```

「このペインでは何が動いているのか」がひと目で分かる。エージェントが自分の list 出力を見て、相手が何をしているか判断する材料になる。

## エージェント向けのスキル

`winsmux skills` を叩くと、エージェント向けのコマンド仕様（contract）が出力される。Claude Code や Codex はこれを読むことで `winsmux` の使い方を自動的に理解する。

```powershell
winsmux skills
winsmux skills --json
```

行動規範も skill 側に書いてある。「待機やポーリングをするな」「read-act-read サイクルを守れ」。返信を待たず、相手がこちらのペインに `message` で返してくるのを受け取ればいい。この非同期メッセージングの規約を skill 側で固定しておくと、エージェントが自律的に通信できる。

## smux との比較

| 比較軸          | smux                     | winsmux                                  |
| --------------- | ------------------------ | ---------------------------------------- |
| バックエンド    | tmux                     | winsmux-core（Rust / ConPTY）            |
| bridge 実装     | Bash                     | PowerShell + Rust コア                   |
| 対象 OS         | macOS / Linux            | Windows                                  |
| ラベル管理      | `@name` ペインオプション | ワーカースロット（`w1`〜`w6` / `worker-N`） |
| インストール    | `curl \| bash`           | `npm install -g winsmux` + `winsmux install` |
| デスクトップアプリ | なし                  | Tauri 製のインストーラあり               |
| Read Guard 状態 | tmp ファイル             | `$env:TEMP\winsmux\read_marks\`          |
| worktree 分離   | なし                     | 標準（`managed-worktree`）               |
| 資格情報保護    | なし                     | Windows DPAPI vault                      |
| 比較証跡        | なし                     | `compare runs` / `review-pack`           |

コマンド体系は smux の `tmux-bridge <verb>` から `winsmux <verb>` に置き換わっている。動詞（`read` / `send` / `list` / `lock` など）は意図的に揃えてある。

## なぜ Agent Teams ではなく winsmux なのか

Claude Code には Agent Teams という公式のマルチエージェント機能がある。tmux 環境で動作し、チームメイトエージェントを自動的に別ペインにスポーンする。

ただし Windows では isTTY gate という制約により、Agent Teams がブロックされるケースがある(2026-07-18時点で [Issue #24384](https://github.com/anthropics/claude-code/issues/24384) は open のまま、関連する Issue #26244 は stale 扱いで打ち切られている)。winsmux はこの穴を埋める。Agent Teams とは別のレイヤーで、任意のエージェント間の対等な通信を実現する。Claude Code 同士だけでなく、Codex と Antigravity CLI、あるいはエージェントと普通のシェルの間でも通信できる。

## 認証の境界

winsmux 自身は AI サービスへ代理ログインしない。各 CLI エージェントは、それぞれ自分のサインインや API キー設定を使う。

| ツール          | 認証方式                              | winsmux での扱い          |
| --------------- | ------------------------------------- | ------------------------- |
| Claude Code     | API key / 企業向け認証                | 公式に対応                |
| Claude Code     | Pro / Max OAuth                       | 当該 PC での対話利用のみ  |
| Codex           | API key                               | 公式に対応                |
| Codex           | ChatGPT OAuth                         | 当該 PC での対話利用のみ  |
| Antigravity CLI | 公式 Antigravity CLI のサインイン     | 当該 PC での対話利用のみ  |
| Grok Build      | Grok Build の headless（ローカル）    | 当該 PC での対話利用のみ  |
| OpenRouter      | `OPENROUTER_API_KEY` による API key   | 公式に対応                |
| Gemini          | Gemini API key / Vertex AI            | 公式に対応                |
| Gemini          | Google OAuth                          | 互換目的 / tier 制限あり  |

Gemini CLI と Gemini Code Assist IDE 拡張は、個人向けの Gemini Code Assist / Google AI Pro / Google AI Ultra からのリクエスト提供を 2026-06-18 に停止し、対象ユーザーは Antigravity CLI へ移行する扱いになっている。winsmux も対話利用は Antigravity CLI に寄せつつ、Gemini API key と Vertex AI の Gemini API は API 経路として公式にサポートする。

## 関連記事

psmux のインストールから設定、AI エージェント並列実行までの背景は以下の記事で解説している。

https://zenn.dev/sora_biz/articles/psmux-windows-native-tmux

## 終わりに

smux が示した「ターミナルペインを通信チャネルにする」というコンセプトは OS に依存しない。Windows でも AI エージェントのマルチペイン協調はできるし、そこにワーカースロット、worktree 分離、Vault、compare runs を足せば、「司令塔はコードを触らない」体制を 1 人で運用できる。

試してみてほしい。

```powershell
npm install -g winsmux
winsmux install --profile full
winsmux init
winsmux launch
```

:::message
**リポジトリ**: https://github.com/Sora-bluesky/winsmux
バグ報告や機能要望は GitHub Issues へ。
:::

---

**著者**: sora（[@sora_biz](https://x.com/sora_biz)）
