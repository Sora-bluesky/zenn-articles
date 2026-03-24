---
title: "Claude Code Channels：スマホからDiscord / Telegram経由で遠隔操作する（Windows）"
emoji: "📱"
type: "tech"
topics: ["claudecode", "windows", "discord", "生成ai", "ai"]
published: true
---

## はじめに

2026年3月19日、Claude Code v2.1.80 で **Channels** という新機能が追加された。
Discord や Telegram からメッセージを送ると、PCで動いている Claude Code が反応して作業してくれる。結果もチャットアプリに返ってくる。

つまり、**スマホから Claude Code を遠隔操作できる**。

電車の中からコードの修正を指示したり、外出先からビルド結果を確認したり。
ターミナルの前に座っていなくても、Claude Code に仕事をさせられる。

この記事では、Windows 環境に限定して Channels のセットアップから実用的な使い方までを解説する。

:::message
**シリーズ構成**
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ：使いこなすためのTips](claude-code-tips-and-features)
- [Claude Code が動かない時に見るページ（Windows）](claude-code-windows-troubleshoot)
- [Claude Code でAIにコードを書かせてAIにレビューさせる](claude-code-ai-review-workflow)
- [Claude Code への引っ越しガイド：Web版の知識を移行する](claude-code-migration-guide)
- [Claude Cowork Windows版ガイド：ターミナルなしでAIエージェントを使う](claude-cowork-windows-guide)
- **Claude Code Channels：スマホから遠隔操作する**（この記事）
:::

:::message alert
**Channels はリサーチプレビュー（実験的機能）です。** `--channels` フラグの仕様やプロトコルは、フィードバックに基づいて変更される可能性があります。最新情報は [公式ドキュメント](https://code.claude.com/docs/en/channels) を確認してください。
:::

:::message
**検証環境**: Windows 11 / Claude Code v2.1.81 / Bun 1.3.11（2026年3月検証）
:::

---

## Channels とは

### しくみ

Channels は、外部のチャットアプリと Claude Code セッションを橋渡しする機能。
技術的には MCP（Model Context Protocol）サーバーとして動作する。

:::message
**MCP とは？**
MCP（Model Context Protocol）は、AIツールが外部サービスと通信するための共通ルール。Claude Code が Discord や Telegram と「会話」するための翻訳機のようなもの。
:::

```
+------------------+       +-------------------+       +------------------+
|  スマホ          |       |  チャネルサーバー  |       |  Claude Code     |
|  (Discord /      | ───→  |  (MCP サーバー)    | ───→  |  (PC上で動作)    |
|   Telegram)      | ←───  |  (PCで常駐)       | ←───  |                  |
+------------------+       +-------------------+       +------------------+
   メッセージ送信          プラグインがAPIに          ファイル操作、
                           定期的に問い合わせて転送  コマンド実行、
                                                     結果を返信
```

**ポイント：**

- チャネルサーバーは **自分のPC上** で動く。クラウドではない
- Claude Code のセッションが **開いている間だけ** メッセージを受信できる
- セッションを閉じるとメッセージは届かない

### 既存の遠隔操作との違い

Claude Code にはすでにいくつかの遠隔操作方法がある。Channels はその中でも「チャットアプリから直接操作できる」点が特徴。

| 方法 | 特徴 | 向いている場面 |
|------|------|----------------|
| **Channels** | Discord / Telegram から直接操作。ローカルファイルにフルアクセス | チャットで気軽に指示を出したい |
| **Remote Control** | claude.ai / Claude モバイルアプリ経由。ターミナルの様子が見える | 許可プロンプトへの対応が必要な時 |
| **Claude Code on the web** | `--remote` フラグでクラウド実行 | 長時間タスクをバックグラウンドで実行 |

---

## 前提条件

| 項目 | 要件 |
|------|------|
| **Claude Code** | v2.1.80 以上（`claude --version` で確認） |
| **認証** | claude.ai ログイン必須（API キー認証は非対応） |
| **プラン** | Pro / Max / Team / Enterprise |
| **ランタイム** | **Bun** が必要（公式プラグインは Bun で動作） |
| **OS** | Windows 10 以降 + Git for Windows |

:::message alert
**Team / Enterprise プランの場合**
管理者が事前に Channels を有効化する必要がある。
claude.ai → 管理設定 → Claude Code → Channels で `channelsEnabled` を有効にする。
:::

---

## 事前準備：Bun のインストール

Channels の公式プラグインは **Bun**（JavaScript ランタイム）で書かれている。公式プラグインを使う場合は Bun のインストールが必要。

:::message
**Bun とは**
Bun は高速な JavaScript ランタイム。Node.js の代替として使える。Channels のプラグインがこれで動くため、インストールが必要。
:::

### Windows（PowerShell）でのインストール

PowerShell を開いて以下を実行：

```powershell
powershell -c "irm bun.sh/install.ps1 | iex"
```

:::message
**コマンドの意味**
- `irm`：インターネットからファイルをダウンロード
- `iex`：ダウンロードしたスクリプトを実行
- `bun.sh/install.ps1`：Bun 公式の Windows 用インストールスクリプト
:::

### インストール確認

**PowerShell を一度閉じて開き直してから**、以下を実行：

```powershell
bun --version
```

バージョン番号（例：`1.3.11`）が表示されれば成功。

### 「bun が見つからない」と言われる場合

PATH が設定されていない可能性がある。以下を PowerShell で実行：

```powershell
[System.Environment]::SetEnvironmentVariable(
    "Path",
    [System.Environment]::GetEnvironmentVariable("Path", "User") + ";$env:USERPROFILE\.bun\bin",
    [System.EnvironmentVariableTarget]::User
)
```

PowerShell を再起動して再度 `bun --version` を確認。

---

## Fakechat で動作確認（推奨）

Discord や Telegram を設定する前に、**Fakechat** というテスト用チャネルで動作確認をする。
Fakechat は localhost でチャット UI を立ち上げるだけのシンプルなデモ。外部サービスの設定が不要なので、問題の切り分けに最適。

:::message alert
**重要：Fakechat が動かなければ、Discord も Telegram も動かない。**
先にここで問題を潰しておくことを強く推奨する。
:::

### 手順

**Step 1: Claude Code を起動してプラグインをインストール**

```
> /plugin install fakechat@claude-plugins-official
```

**Step 2: プラグインを読み込む**

```
> /reload-plugins
```

インストールしただけではプラグインは有効にならない。このコマンドで読み込む。

**Step 3: Claude Code を終了して、`--channels` フラグ付きで再起動**

```powershell
claude --channels plugin:fakechat@claude-plugins-official
```

**Step 4: ブラウザで確認**

ブラウザで `http://localhost:8787` を開く。
チャット画面が表示されるので、メッセージを入力してみる。

![Fakechat UI で送信→返答のループが完了](/images/channels-fakechat-ui-loop.png)
*Fakechat の UI。「こんにちは」を送信すると、Claude Code が処理して返答が表示される*

**成功の確認：**
1. ブラウザでメッセージを送信（`you:` の行）
2. Claude Code のターミナルにメッセージが届く
3. Claude が処理して返答する
4. ブラウザに返答が表示される（`bot:` の行）

![Claude Code がメッセージを受信して返答](/images/channels-fakechat-claude-reply.png)
*Claude Code 側。Fakechat から届いたメッセージを処理し、reply ツールで返答している*

このループが完了すれば、Channels の基盤は正常に動作している。

:::message
**うまくいかない場合は `/mcp` で確認**

Claude Code のターミナルで `/mcp` を実行し、fakechat の MCP サーバーが **connected** になっているか確認する。

![/mcp で fakechat が connected](/images/channels-fakechat-mcp-connected.png)
*Built-in MCPs の欄に `plugin:fakechat:fakechat` が connected と表示されていればOK*

**failed** になっている場合は、次のトラブルシューティングを参照。
:::

---

## Discord との連携

### Step 1: Discord Bot を作成

1. [Discord Developer Portal](https://discord.com/developers/applications) にアクセス
2. 「**New Application**」をクリックして、名前を付ける（例：「Claude Code Bot」）
3. 左メニューの「**Bot**」セクションに移動
4. Bot のユーザー名を設定
5. 「**Reset Token**」をクリックしてトークンをコピー

:::message alert
**トークンはパスワードと同じ。** 絶対に他人に見せない、コードにハードコードしない。
:::

### Step 2: Bot の権限を設定

同じ Bot 設定画面で：

1. 「**Privileged Gateway Intents**」までスクロール
2. **Message Content Intent** を **有効** にする（これがないとメッセージが読めない）

### Step 3: Bot をサーバーに招待

1. 左メニューの「**OAuth2**」→「**URL Generator**」
2. **Scopes** で `bot` にチェック
3. **Bot Permissions** で以下にチェック：
   - View Channels
   - Send Messages
   - Send Messages in Threads
   - Read Message History
   - Attach Files
   - Add Reactions
4. 生成された URL を開いて、自分の Discord サーバーに Bot を追加

### Step 4: Claude Code でプラグインを設定

Claude Code を起動して：

```
> /plugin install discord@claude-plugins-official
> /reload-plugins
```

トークンを設定：

```
> /discord:configure あなたのBotトークン
```

:::message
トークンは `~/.claude/channels/discord/.env` に保存される。手動で書き込んでもOK。
:::

### Step 5: `--channels` フラグ付きで再起動

Claude Code を一度終了して、以下で起動：

```powershell
claude --channels plugin:discord@claude-plugins-official
```

### Step 6: ペアリング

1. Discord で Bot に **DM（ダイレクトメッセージ）** を送る
2. Bot がペアリングコード（6文字）を返す
3. Claude Code のターミナルで以下を実行：

```
> /discord:access pair ペアリングコード
```

### Step 7: アクセスポリシーを変更

ペアリング完了後、セキュリティのためにポリシーを `allowlist` に変更する：

```
> /discord:access policy allowlist
```

:::message alert
**なぜ変更するのか？**
デフォルトの `pairing` モードでは、Bot にメッセージを送った人は誰でもペアリングコードを受け取れる。`allowlist` に変更すると、ペアリング済みの人だけがメッセージを送れるようになる。
:::

これで設定完了。Discord の DM から Claude Code にメッセージを送って、返答が来ることを確認する。

---

## Telegram との連携

Discord より手順が少ない。個人利用にはこちらの方が手軽。

### Step 1: Telegram Bot を作成

1. Telegram で **@BotFather** を検索してチャットを開く
2. `/newbot` と送信
3. Bot の表示名を入力（例：「My Claude Code」）
4. Bot のユーザー名を入力（末尾が `bot` で終わる必要がある。例：`my_claude_code_bot`）
5. BotFather がトークンを返す（`123456789:AAHfiqksKZ8...` のような形式）。コピーする

### Step 2: Claude Code でプラグインを設定

```
> /plugin install telegram@claude-plugins-official
> /reload-plugins
```

トークンを設定：

```
> /telegram:configure あなたのBotトークン
```

### Step 3: `--channels` フラグ付きで再起動

```powershell
claude --channels plugin:telegram@claude-plugins-official
```

### Step 4: ペアリング

1. Telegram で自分の Bot を見つけて、何かメッセージを送る
2. Bot がペアリングコード（6文字）を返す
3. Claude Code のターミナルで：

```
> /telegram:access pair ペアリングコード
```

### Step 5: アクセスポリシーを変更

```
> /telegram:access policy allowlist
```

完了。Telegram からメッセージを送って動作確認する。

:::message
**Discord と Telegram の違い**
| 項目 | Discord | Telegram |
|------|---------|----------|
| セットアップ | やや複雑（権限設定が多い） | シンプル（BotFather だけ） |
| サーバー招待 | 必要 | 不要（DM で直接使える） |
| 添付ファイル | 最大25MB、10ファイルまで | 最大50MB |
| メッセージ履歴 | Bot が過去メッセージを取得可能 | 取得不可（到着時のみ） |
| 向いている用途 | チーム利用、サーバー内共有 | 個人利用、手軽な操作 |
:::

---

## 許可プロンプトの問題と対策

Channels の最大の注意点がこれ。

Claude Code がファイルの書き込みやコマンドの実行をする時、通常はターミナルで「許可しますか？」と聞いてくる。何も対策しないと、チャットアプリから指示を出してもこの許可待ちで**セッションが止まってしまう**。

### 対策① Permission Relay（おすすめ）

v2.1.81 以降、許可プロンプトをチャットアプリに転送する **Permission Relay** が使える。公式の Discord / Telegram プラグイン（v0.0.2 以降）で対応済み。

**動作イメージ：**

1. Claude Code がファイル編集やコマンド実行の許可を求める
2. Telegram / Discord に「〇〇を実行していい？」というメッセージが届く
3. `yes abcde` または `no abcde` と返信する（`abcde` は5文字の確認コード）
4. Claude Code が許可を受けて作業を続行する

ターミナル側の許可プロンプトも同時に有効で、**先に返答した方が採用される**。外出先ではスマホから、帰宅後はターミナルから、と使い分けられる。

![Telegram で Permission Relay が動作している様子](/images/channels-permission-relay-telegram.jpg)
*Telegram に許可プロンプトが転送される。`yes xxxxx` と返信すれば、スマホからコマンド実行を許可できる*

:::message
**Permission Relay が動かない場合**
プラグインが古い可能性がある。Claude Code で以下を実行してプラグインを更新する：

```
> /plugin marketplace update claude-plugins-official
```
:::

### 対策② Auto-accept モード

Permission Relay の返答も面倒なら、ファイル編集を自動許可するモードもある。`~/.claude/settings.json` に以下を追加：

```json
{
  "permissions": {
    "defaultMode": "acceptEdits"
  }
}
```

ファイルの読み書きは確認なしで実行される。コマンド実行（`npm run build` 等）は引き続き確認が入るので、安全性とのバランスが良い。

:::details 対策③ 特定コマンドだけ許可する

`~/.claude/settings.json` の `permissions.allow` に許可するコマンドパターンを追加する：

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(npm test *)",
      "Bash(git *)"
    ]
  }
}
```
:::

---

## 常駐させる方法（Windows）

Channels はセッションが開いている間だけ動作する。ターミナルを閉じるとメッセージが届かなくなる。

「常に待ち受けたい」場合は、**Windows Terminal のタブを1つ専用にして開きっぱなしにする**のが一番シンプルで確実。

Claude Code を `--channels` で起動したタブを、他の作業用タブとは別のウィンドウにしておく。PCがスリープしない限り、タブを開いている間はずっとメッセージを受信できる。

:::details 上級者向け：WSL2 + tmux / 起動時自動実行
**WSL2 + tmux**

WSL2 で Claude Code を使っている場合、tmux でセッションを維持できる。ただし tmux は Windows ネイティブ（PowerShell / Git Bash）では使えない。

```bash
sudo apt install tmux
tmux new -s claude-channels
claude --channels plugin:telegram@claude-plugins-official
# デタッチ：Ctrl + B → D
# 再接続：tmux attach -t claude-channels
```

PC再起動や `wsl --shutdown` でセッションは消える点に注意。

**Windows Terminal の起動時自動実行**

Windows Terminal の設定で、起動時に Claude Code を立ち上げるプロファイルを作成できる。毎日使う場合に便利。
:::

---

## セキュリティに関する注意

### 送信者の制限

公式プラグインは **送信者ホワイトリスト** を実装している。ペアリングしたユーザー ID だけがメッセージを送信でき、それ以外は無視される。

### 注意すべきポイント

- **ペアリング済みユーザーは、あなたの PC 上で Claude Code にコマンドを実行させられる。** 信頼できる人だけペアリングすること
- チャネル経由の返答は外部プラットフォーム（Discord / Telegram のサーバー）を経由する。機密性の高いコードやトークンは、チャネル経由で出力させないこと
- **ペアリング後すぐに `allowlist` ポリシーに変更する**。デフォルトのまま放置すると、Bot にメッセージを送った第三者がペアリングコードを取得できる
- 定期的にペアリング済みユーザーの一覧を確認する

---

## トラブルシューティング

| 症状 | 原因 | 解決策 |
|------|------|--------|
| Bot がメッセージに反応しない | セッションが `--channels` なしで起動している | Claude Code を終了して `--channels` 付きで再起動 |
| プラグインが読み込まれない | Bun がインストールされていない | `bun --version` で確認。なければインストール |
| メッセージが届かない | `.mcp.json` に書いただけで `--channels` に指定していない | **`--channels` フラグは毎回必要**。`.mcp.json` だけでは不十分 |
| ペアリングコードが返ってこない | Claude Code のセッションが起動していない | ターミナルで Claude Code が動作中か確認 |
| 「Channels not enabled」と表示 | Team/Enterprise で管理者が有効化していない | 管理者に `channelsEnabled` の有効化を依頼 |
| Fakechat の MCP が **failed** | ポート 8787 が前回のプロセスに占有されている | 下記「ポート競合の解消」を参照 |
| バージョンが古い | v2.1.80 未満 | `claude update` または `winget upgrade Anthropic.ClaudeCode` |

### ポート競合の解消（Fakechat が failed になる場合）

Fakechat はデフォルトで **ポート 8787** を使う。前回のセッションで Fakechat の `bun.exe` プロセスが残っていると、新しいセッションで MCP サーバーが起動に失敗する。

**症状**: `/mcp` で fakechat が **failed** と表示される

**解決手順**:

```powershell
# 1. ポート 8787 を使っているプロセスを特定
netstat -ano | findstr 8787

# 2. 表示された PID（末尾の数字）を kill
taskkill /PID <PID番号> /F

# 3. Claude Code を --channels 付きで再起動
claude --channels plugin:fakechat@claude-plugins-official
```

:::message
**なぜ起きるのか？**
Claude Code のセッションを終了しても、Fakechat の `bun.exe` プロセスが自動で終了しない場合がある。特に強制終了（ターミナルを直接閉じた場合など）で発生しやすい。
:::

### デバッグ用コマンド

```
> /plugin
```

インストール済みプラグインの一覧を確認できる。チャネルプラグインが表示されているか確認する。

---

## 活用例

### 外出先からファイルを修正

```
（Telegram から）
package.json の test スクリプトに --coverage フラグを追加して
```

Claude Code がローカルの `package.json` を編集して、結果を Telegram に返してくれる。

### ビルド結果の確認

```
（Discord から）
npm run build して結果を教えて
```

### レビューの依頼

```
（Telegram から）
直近のコミットをレビューして。セキュリティ問題があれば教えて
```

### 簡単な調査

```
（Discord から）
src/ 以下で TODO コメントが残っているファイルを一覧にして
```

---

## 既知の制限事項

- **リサーチプレビュー段階**。仕様が変更される可能性がある
- プレビュー期間中は **Anthropic 公式の許可リストに載ったプラグインのみ** 使用可能
- claude.ai ログインが必須。**API キー認証では使えない**
- セッションが閉じるとメッセージを受信できない（常駐の工夫が必要）
- 音声メッセージは非対応
- 自作チャネルのテストには `--dangerously-load-development-channels` フラグが必要

---

## まとめ

| やること | コマンド / 操作 |
|----------|----------------|
| Bun インストール | `powershell -c "irm bun.sh/install.ps1 \| iex"` |
| Fakechat で動作確認 | `/plugin install fakechat@claude-plugins-official` → `claude --channels plugin:fakechat@claude-plugins-official` |
| Discord 連携 | `/plugin install discord@claude-plugins-official` → トークン設定 → `--channels` で起動 → ペアリング |
| Telegram 連携 | `/plugin install telegram@claude-plugins-official` → トークン設定 → `--channels` で起動 → ペアリング |
| Permission Relay | v2.1.81 以降で自動有効。スマホから `yes/no` で許可・拒否 |
| セキュリティ強化 | ペアリング後に `/〇〇:access policy allowlist` |

Channels を使えば、PCの前にいなくても Claude Code に仕事を頼める。
まずは Fakechat で動作確認してから、Discord か Telegram を設定するのがおすすめ。

---

## 参考

- [Channels（公式ドキュメント）](https://code.claude.com/docs/en/channels)
- [Channels Reference（公式・自作チャネル向け）](https://code.claude.com/docs/en/channels-reference)
- [claude-plugins-official（GitHub）](https://github.com/anthropics/claude-plugins-official)
- [Bun インストールガイド](https://bun.com/docs/installation)

---

## 関連記事

- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ：使いこなすためのTips](claude-code-tips-and-features)
- [Claude Code が動かない時に見るページ（Windows）](claude-code-windows-troubleshoot)
- [Claude Code でAIにコードを書かせてAIにレビューさせる](claude-code-ai-review-workflow)
- [Claude Code への引っ越しガイド：Web版の知識を移行する](claude-code-migration-guide)
- [Claude Cowork Windows版ガイド：ターミナルなしでAIエージェントを使う](claude-cowork-windows-guide)
