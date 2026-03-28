---
title: "Windows開発者がtmuxを手に入れる方法（WSL不要）"
emoji: "🖥️"
type: "tech"
topics: ["claudecode", "ai", "windows", "powershell", "ターミナル"]
published: true
---

## Windows 開発者の「tmux 使いたい問題」

tmux はターミナルの画面分割とセッション管理を行うツールで、macOS / Linux 開発者の間では定番の存在だ。

macOS や Linux のチームメイトが tmux でペインを分割し、サーバーにセッションを残して（デタッチ）、翌日つなぎ直して（アタッチ）続きから作業している。その横で僕は Windows Terminal のタブを 8 枚開き、どのタブで何を動かしていたか見失い、リモートデスクトップが切れるたびにセッションを作り直していた。

「WSL2 入れれば？」と何度も言われた。だが PowerShell と cmd.exe でビルドパイプラインを回している環境に、わざわざ Linux レイヤーを噛ませたくない。そもそも WSL2 を入れられない社内 PC もある。

痛みを整理するとこうなる。

- **SSH セッションが切れると作業が飛ぶ** -- リモートデスクトップが落ちたら最初からやり直し
- **タブ地獄** -- エディタ、ビルド、テスト、Git、ログ監視。タブが増え続けて収拾がつかない
- **AI エージェントを複数走らせたいが画面が足りない** -- Claude Code と Codex CLI を並べたい
- **WSL2 は入れたくない（or 入れられない）** -- ネイティブ Windows で完結させたい

2025 年末、Rust 製の Windows ネイティブターミナルマルチプレクサ **psmux** を見つけた。これが全部解決してしまった。

## psmux とは

| 項目 | 内容 |
|------|------|
| リポジトリ | [github.com/psmux/psmux](https://github.com/psmux/psmux) |
| 言語 | Rust |
| ライセンス | MIT |
| スター数 | 780+（2026 年 3 月時点） |
| 最新バージョン | v3.3.1（2026-03-26） |

一言でまとめると **Windows ネイティブの tmux**。Windows の ConPTY API を直接使い、WSL・Cygwin・MSYS2 は一切不要。76 個の tmux コマンドを実装し、`.tmux.conf` をそのまま読み込む。`psmux`・`pmux`・`tmux` の 3 つのコマンド名で起動できるので、tmux ユーザーは手癖を変えずに移行できる。

:::message
**ConPTY とは？**
ConPTY（Console Pseudo Terminal）は、Windows 10 以降に搭載された擬似端末 API。Unix の PTY に相当する仕組みで、これにより Windows でもターミナルマルチプレクサが実現可能になった。psmux はこの API を Rust から直接呼び出している。
:::

### tmux との比較

tmux を知っている人向けに、違いを先に整理しておく。

| 観点 | tmux | psmux |
|------|------|-------|
| 対象 OS | macOS / Linux | **Windows 10 / 11** |
| 実装言語 | C | Rust |
| 依存関係 | libevent, ncurses | なし（シングルバイナリ） |
| WSL 必要 | -- | **不要** |
| コマンド互換 | -- | 76 コマンド対応 |
| `.tmux.conf` 互換 | -- | そのまま読み込み可 |
| マウスサポート | 部分的 | フル（3 層マウスインジェクション） |
| AI エージェント統合 | smux / tmux-bridge | **Agent Teams 組み込み** |

tmux を知らない人は、この表は読み飛ばして OK。次の Level 1 から始めれば大丈夫。

---

## Level 1: 5 分でスタート

今日覚えるのは 4 つだけ。「インストール」「セッション作成」「ペイン分割」「デタッチ/アタッチ」。

### インストール

```powershell
winget install psmux
```

:::message
**winget** は Windows 10/11 に標準搭載されているパッケージマネージャ。PowerShell やコマンドプロンプトで `winget` と打てば使える。もし見つからない場合は Microsoft Store で「アプリ インストーラー」を更新する。
:::

scoop、choco、cargo でもインストールできるが、選択肢は 1 つに絞るなら winget が一番手軽。

PowerShell 7（pwsh）も入れておくと快適になる。

```powershell
winget install --id Microsoft.PowerShell
```

:::message
**PowerShell 5.1 と 7 の違い**
Windows に最初から入っている PowerShell（青い画面）はバージョン 5.1。PowerShell 7 は黒い画面で、クロスプラットフォーム対応の新しい世代。psmux は 5.1 でも動くが、一部の動作が異なる場合があるため 7 を推奨。
:::

### 最初のセッション

```powershell
psmux new-session -s work
```

`-s work` は「work という名前のセッションを作る」という意味。名前は何でもいい。画面下部にステータスバーが出ていれば成功。

### ペイン分割

psmux の画面構造は 3 層になっている。**セッション**（作業の大枠）の中に**ウィンドウ**（仮想画面）があり、ウィンドウを**ペイン**（区画）に分割する。まずはペインだけ覚えれば十分。1 画面に複数のターミナルを並べられる。

```powershell
psmux split-window -h         # 画面を左右に分割（-h = horizontal）
psmux split-window -v         # 画面を上下に分割（-v = vertical）
psmux select-pane -t 0        # 最初のペインに戻る（-t = target）
```

:::message
**-h と -v が直感と逆に感じる場合**
`-h` は「水平方向に分割線を引く」のではなく「水平方向にペインを並べる」つまり左右分割。`-v` は「垂直方向にペインを並べる」つまり上下分割。tmux と同じ仕様で、最初は混乱するが慣れる。
:::

Prefix キー（デフォルトは `Ctrl+b`）を使ったキーバインドでも操作できる。`Ctrl+b` を押してから次のキーを押す、という 2 ステップ操作になる。

| やりたいこと | コマンド | キーバインド |
|-------------|---------|-------------|
| セッション作成 | `psmux new-session -s <name>` | -- |
| 左右分割 | `psmux split-window -h` | `Ctrl+b` → `%` |
| 上下分割 | `psmux split-window -v` | `Ctrl+b` → `"` |
| ペイン移動 | `psmux select-pane -U/-D/-L/-R` | `Ctrl+b` → 矢印キー |
| セッション一覧 | `psmux ls` | -- |

### デタッチ & 再アタッチ -- tmux の真骨頂

tmux 系ツールを使う最大の理由がこれ。**ターミナルを閉じてもセッションが生き残る**。

何が嬉しいか。ビルドを走らせている最中にうっかりターミナルを閉じてしまっても、SSH が切断されても、セッションは裏で動き続けている。戻りたくなったらアタッチするだけ。

```powershell
# デタッチ（セッションから離れる。Ctrl+b → d でも可）
psmux detach-client

# 後から戻る
psmux attach -t work
```

SSH 切断、ターミナルクラッシュ、うっかりウィンドウを閉じた -- 全部これでリカバリできる。

:::message alert
**PC の再起動・シャットダウンだけは例外。** OS が終了するとプロセスが消えるため、セッションも失われる。これは tmux も同じ制約。
:::

Level 1 はここまで。この 4 つだけで日常の作業効率は確実に上がる。

---

## Level 2: 設定をカスタマイズする

psmux のデフォルト設定でも十分使えるが、カスタマイズすると格段に快適になる。

### 設定ファイルの場所

psmux は以下の順序で設定ファイルを探す。

1. `~/.psmux.conf`
2. `~/.psmuxrc`
3. `~/.tmux.conf`
4. `~/.config/psmux/psmux.conf`

:::message
**`~` は何？**
`~`（チルダ）はホームディレクトリを指す記号。Windows の PowerShell 7 では `C:\Users\[あなたのユーザー名]` に展開される。つまり `~/.psmux.conf` は `C:\Users\[あなたのユーザー名]\.psmux.conf` と同じ場所。
:::

既存の `.tmux.conf` があればそのまま読み込まれる。psmux 固有の設定を追加したい場合は `~/.psmux.conf` を作成する。

### コピペで使える .psmux.conf

以下をそのまま `~/.psmux.conf` に保存すれば、すぐに快適な環境になる。PowerShell で以下を実行すると、ファイルが作成される。

```powershell
# メモ帳で設定ファイルを開く（なければ新規作成）
notepad $HOME\.psmux.conf
```

メモ帳が開いたら、以下の内容を貼り付けて保存する。

```conf
# ~/.psmux.conf — psmux 設定ファイル
# tmux 互換の記法がそのまま使える

# === 基本設定 ===
set -g mouse on              # マウス有効（ペインクリック・ドラッグリサイズ・スクロール）
set -g history-limit 10000   # スクロールバック行数（過去のログを何行まで遡れるか）
set -g base-index 1          # ウィンドウ番号を 1 始まりに（0 始まりは直感に反するため）
set -g pane-base-index 1     # ペイン番号も 1 始まりに
set -g default-shell pwsh    # デフォルトシェルを PowerShell 7 に

# === ステータスバー ===
set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
set -g status-left "[#S] "
set -g status-right "%H:%M"

# === ペインボーダー（区切り線の見た目） ===
set -g pane-border-style "fg=#45475a"
set -g pane-active-border-style "fg=#89b4fa"
set -g pane-border-lines heavy
set -g pane-border-status top
set -g pane-border-format " #{pane_title} "

# === Alt キーバインド（Prefix 不要で直接操作できる） ===
bind-key -n M-i select-pane -U    # Alt+i: 上のペインへ
bind-key -n M-k select-pane -D    # Alt+k: 下のペインへ
bind-key -n M-j select-pane -L    # Alt+j: 左のペインへ
bind-key -n M-l select-pane -R    # Alt+l: 右のペインへ
bind-key -n M-n split-window -h \; select-layout tiled  # Alt+n: 新ペイン+自動配置
bind-key -n M-w kill-pane         # Alt+w: ペインを閉じる
bind-key -n M-o next-layout       # Alt+o: レイアウト切り替え
bind-key -n M-m new-window        # Alt+m: 新ウィンドウ
bind-key -n M-u next-window       # Alt+u: 次のウィンドウ
bind-key -n M-h previous-window   # Alt+h: 前のウィンドウ
```

ポイントは `bind-key -n M-*` の行。`-n` を付けると Prefix キー（`Ctrl+b`）なしで直接操作できる。`Alt+j/l` で左右移動、`Alt+n` で新しいペインを追加 -- Prefix を経由しないぶん操作が圧倒的に速い。この Alt キーバインドに変えた瞬間、Ctrl+b を毎回押していたのがバカバカしくなった。

### チートシート

この表だけ覚えれば日常操作はほぼカバーできる。ブックマークしておくと便利。

#### ペイン操作

| キー | 動作 |
|------|------|
| `Alt+i` / `Alt+k` | ペイン移動（上 / 下） |
| `Alt+j` / `Alt+l` | ペイン移動（左 / 右） |
| `Alt+n` | 新しいペイン（自動タイル配置） |
| `Alt+w` | ペインを閉じる |
| `Alt+o` | レイアウト切り替え |

#### ウィンドウ操作

| キー | 動作 |
|------|------|
| `Alt+m` | 新しいウィンドウ |
| `Alt+u` | 次のウィンドウ |
| `Alt+h` | 前のウィンドウ |

#### マウス操作（`mouse on` 時）

| 操作 | 動作 |
|------|------|
| ペインをクリック | そのペインを選択 |
| ボーダーをドラッグ | ペインのリサイズ |
| ホイールスクロール | 出力ログを遡る |
| テキストを選択 | クリップボードにコピー |

#### セッション管理

| コマンド | 動作 |
|---------|------|
| `psmux new-session -s <name>` | 名前付きセッション作成 |
| `psmux ls` | セッション一覧 |
| `psmux attach -t <name>` | セッションに再接続 |
| `psmux kill-session -t <name>` | セッション削除 |
| `Ctrl+b` → `d` | デタッチ（セッションから離れる） |

---

## Level 3: AI エージェントを並列実行する

ここが psmux の最大の差別化ポイント。2026 年現在、AI エージェント CLI を複数同時に走らせたい需要が急増している。psmux ならそれが Windows ネイティブでできる。

### なぜ psmux で AI エージェントなのか

- Claude Code、Codex CLI、Gemini CLI を **1 画面に並べて同時に走らせたい**
- タスクを分担させて並列で進めたい
- エージェントの出力をリアルタイムで見比べたい

Windows Terminal のタブ切り替えでは、各エージェントの進捗を同時に視認できない。psmux のペイン分割なら全部見える。

### セットアップ例: Claude Code + Codex を並べる

```powershell
psmux new-session -s ai-work
# 左ペインで Claude Code を起動
claude

# Alt+n で右ペインを作成してから Codex を起動
codex
```

たったこれだけで 2 つの AI エージェントが並走する環境ができる。左のペインで Claude Code にリファクタリングを任せつつ、右のペインで Codex にテストを書かせる、といった分業が可能になる。

### Agent Teams ネイティブサポート

psmux v3.3.1 には Claude Code の **Agent Teams** がネイティブ統合されている。psmux セッション内で Claude Code を起動すると、チームメイトエージェントが自動的に別ペインにスポーンする。

```powershell
# psmux セッション内で Claude Code を起動するだけ
psmux new-session -s work
claude  # エージェントチームが自動的にペイン分割される
```

psmux が以下の環境変数を自動設定するため、手動の設定は不要。

| 環境変数 | 値 | 役割 |
|---------|-----|------|
| `TMUX` | `/tmp/psmux-{pid}/...` | Claude Code に tmux 環境であることを通知 |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` | `1` | エージェントチーム機能を有効化 |
| `PSMUX_CLAUDE_TEAMMATE_MODE` | `tmux` | `--teammate-mode tmux` を自動注入 |

無効化したい場合は `.psmux.conf` に以下を追加する。

```conf
set -g claude-code-fix-tty off
```

:::message
**Opus モデルの補足**
Opus は worktree isolation（インプロセス・不可視）を選ぶ傾向がある。ペインで見える teammate 方式を強制したい場合は、プロジェクトの `CLAUDE.md` に以下を記述する。

```markdown
When spawning subagents, always use the teammate system (team_name + name parameters)
instead of worktree isolation.
```
:::

### winsmux: エージェント間通信ブリッジ

エージェント同士にメッセージをやり取りさせたい場合は、**winsmux** の `psmux-bridge` が使える。

```powershell
# winsmux をインストール
irm https://raw.githubusercontent.com/sora-biz/winsmux/main/install.ps1 | iex
```

:::message
**irm と iex とは？**
`irm` は `Invoke-RestMethod` の省略形で、URLからデータを取得するコマンド。`iex` は `Invoke-Expression` の省略形で、取得したスクリプトを実行する。つまり「ネットからスクリプトをダウンロードして、そのまま実行する」という意味。実行前にURLが公式リポジトリのものか確認すること。
:::

```powershell
# エージェント間でメッセージを送る
psmux-bridge read codex 20
psmux-bridge message codex "src/auth.ts をレビューしてください"
psmux-bridge keys codex Enter
```

winsmux の詳細は以下の記事で解説している。

https://zenn.dev/sora_biz/articles/winsmux-ai-agent-cross-pane-communication

---

## Windows Terminal との使い分け

psmux を入れたら Windows Terminal が要らなくなるわけではない。両方を組み合わせるのがベスト。

| 場面 | Windows Terminal | psmux |
|------|-----------------|-------|
| ちょっとした作業 | **タブで十分** | やりすぎ |
| 長時間の開発 | タブだと窮屈 | **ペイン分割が活きる** |
| SSH 先での作業 | 切断で消える | **セッション永続** |
| AI エージェント並列 | 手動切り替え | **同時に視認できる** |
| 操作の自動化 | 非対応 | **76 コマンドでスクリプト化** |

結論: **Windows Terminal の中で psmux を起動する**のが最強の構成。Windows Terminal はフォント・配色・透過度など見た目のカスタマイズが得意で、psmux はセッション管理とペイン分割が得意。役割が違う。

---

## 注意点とよくあるトラブル

### PowerShell 7 を使う

Windows 付属の PowerShell 5.1 では PSReadLine の予測表示やキーバインドの挙動が異なることがある。問題が起きたらまず `pwsh` で試す。インストールは `winget install --id Microsoft.PowerShell`。

### 初回起動が遅い場合

ウイルス対策ソフトが新しい実行ファイルをスキャンしていることが多い。2 回目以降は速くなる。改善しない場合は、psmux のインストールフォルダをウイルス対策の除外に追加する。

### psmux の中から psmux を起動しない

ネスト（入れ子）は非推奨。tmux も同じ制約がある。既に psmux セッションの中にいるかどうかは、ステータスバーの有無で判断できる。

### PSReadLine の予測表示

PowerShell 7 のコマンド予測機能（InlineView）がデフォルトで無効化される。予測表示を使いたい場合は、`.psmux.conf` に以下を追加する。

```conf
set -g allow-predictions on
```

---

## まとめ

Windows 開発者が tmux ワークフローを手に入れるのに、もう WSL は要らない。

```powershell
winget install psmux
psmux new-session -s work
```

この 2 行で始まる。ペイン分割、セッション永続化、AI エージェント並列実行 -- 全部 PowerShell ネイティブで動く。

僕自身、psmux に切り替えてからタブ地獄とは無縁になった。Claude Code と Codex CLI を並べて走らせる作業環境は、一度体験すると戻れない。

---

:::message
**公式ドキュメント**
- [psmux 公式リポジトリ](https://github.com/psmux/psmux) -- インストール方法、設定リファレンス、全コマンド一覧
- [Claude Code Agent Teams](https://code.claude.com/docs/en/agent-teams) -- Agent Teams の仕組みと設定
- [Claude Code 日本語ドキュメント](https://code.claude.com/docs/ja) -- Claude Code 全般
:::

*本記事は 2026 年 3 月 28 日時点の情報に基づいています。最新情報は [psmux 公式リポジトリ](https://github.com/psmux/psmux) を参照してください。*

*著者: sora（[@sora_biz](https://x.com/sora_biz)）*
