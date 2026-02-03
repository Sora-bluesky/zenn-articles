---
title: "OpenClaw（旧Clawdbot）でDiscord/Telegramを個人AIアシスタント化する"
emoji: "🦞"
type: "tech"
topics: ["openclaw", "discord", "telegram", "ai", "security"]
published: false
---

## はじめに

この記事では、OpenClaw（旧Clawdbot/Moltbot）をDiscordやTelegramと連携して、メッセージアプリから操作できるAIアシスタントを作る方法を解説する。

:::message alert
**前提条件**
この記事は、OpenClawのインストールが完了している前提で進める。まだの場合は先に導入ガイドを参照：
- [DigitalOceanで安全に動かす](openclaw-setup-guide)（VPS推奨）
- [WSL2で無料で試してみた](openclaw-wsl2-setup-guide)（ローカル試用）
:::

:::message
**シリーズ構成**
- [Linux（Ubuntu）インストールガイド（Windows）](wsl2-windows-install-guide)
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- **🦞OpenClaw導入ガイド**
  - [DigitalOceanで安全に動かす](openclaw-setup-guide)
  - [WSL2で無料で試してみた](openclaw-wsl2-setup-guide)
- [🦞OpenClawでDiscord/Telegramを個人AIアシスタント化する](openclaw-discord-telegram-guide)（この記事）
:::

---

## Discord/Telegram連携で何が変わるのか

### Before（連携前）

- AIを使うには、PCでブラウザを開く必要がある
- 外出先ではスマホアプリでチャットするだけ
- AIに「これやって」と言っても、実際の作業は自分でやる
- 過去の会話内容は覚えていない

### After（連携後）

- **いつも使っているDiscord/TelegramがAIアシスタントの窓口に**
- 外出先から「〇〇のファイルを確認して」と送るだけ
- AIが**実際にPCを操作して**結果を報告してくれる
- 過去の会話・好み・決定事項を覚えている

### 具体的な活用シーン

**シーン1: 外出先で急にファイルが必要になった**
> 「デスクトップの企画書.docxの内容を教えて」
> → OpenClawがファイルを開いて内容を要約して返信

**シーン2: 毎朝の情報整理を自動化**
> 毎朝9時に「今日のカレンダー + やることリスト」が自動でTelegramに届く
> → 5つのアプリを開く手間がなくなる

**シーン3: 家計管理の効率化**
> 「先月の食費はいくら？」
> → OpenClawが会計データを集計して回答

**シーン4: 開発者向け（Claude Code連携）**
> 「プロジェクトXのテストを実行して結果を教えて」
> → OpenClawがClaude Codeと連携してテストを実行、結果をTelegramに報告

---

## この記事でできるようになること

| プラットフォーム | できること |
|-----------------|-----------|
| **Telegram** | 個人チャットでAIアシスタントと会話 |
| **Discord** | サーバー内でAIボットを運用 |

---

## 難易度比較

| プラットフォーム | 難易度 | セットアップ時間 | 特徴 |
|-----------------|--------|------------------|------|
| **Telegram** | 簡単 | 5分 | @BotFatherでトークン取得のみ |
| **Discord** | やや複雑 | 15分 | Intent設定、権限設定が必要 |

**おすすめ**: まずTelegramで試して、慣れたらDiscordに挑戦。

---

## Telegram連携（初心者向け）

### Step 1: Telegram Botを作成

1. Telegramアプリで **@BotFather** を検索してチャットを開始
2. `/newbot` と入力
3. ボットの名前を入力（例: `My OpenClaw`）
4. ボットのユーザー名を入力（末尾は `bot` で終わる必要あり。例: `myopenclaw_bot`）

**成功すると、トークンが表示される:**

```
Done! Congratulations on your new bot.
...
Use this token to access the HTTP API:
123456789:ABCdefGHIjklMNOpqrsTUVwxyz
```

:::message alert
**重要: トークンは秘密にする**
このトークンは「ボットのパスワード」のようなもの。他人に知られると、ボットを乗っ取られる可能性がある。
:::

### Step 2: OpenClawに設定

WSL2のUbuntu内で以下を実行（スタートメニューから「Ubuntu」を起動）。

```bash
openclaw channels add --channel telegram --token "123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
```

:::message
**dmPolicy（初期設定）について**
このコマンドで追加すると、`"dmPolicy": "pairing"` が自動設定される。初回メッセージ時に「ペアリング」が必要になり、知らない人からの勝手なメッセージを防げる。
:::

### Step 3: Gatewayを起動

```bash
openclaw gateway
```

**出力例:**

```
🦞 Gateway started on ws://127.0.0.1:18789
[telegram] Connected as @myopenclaw_bot
```

### Step 4: 動作確認

1. Telegramアプリで作成したボット（例: `@myopenclaw_bot`）を検索
2. 「Start」または何かメッセージを送信
3. ペアリングコードが求められた場合は、ターミナルに表示されるコードを入力
4. AIから返信が来れば成功

---

## Telegram セキュリティ設定

セキュリティ設定は `~/.openclaw/openclaw.json`（`~` はホームディレクトリ）を編集して行う。

### 特定のユーザーだけ許可

自分だけがボットを使えるようにする設定。

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "YOUR_TOKEN",
      "dmPolicy": "pairing",
      "allowFrom": [123456789, "@yourusername"]
    }
  }
}
```

:::message
**ユーザーIDの調べ方**
Telegramで @userinfobot を検索し、何でもいいのでメッセージを送る。すると自分のユーザーID（数字）が返ってくる。
:::

### グループでの利用

グループチャットでボットを使う場合の設定。

```json
{
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "YOUR_TOKEN",
      "groupPolicy": "allowlist",
      "groups": {
        "*": {
          "requireMention": true
        }
      }
    }
  }
}
```

:::message
**requireMention: true とは**
グループ内では `@ボット名` でメンションした時だけ反応する設定。グループの会話に勝手に割り込まない。
:::

---

## Discord連携（中級者向け）

Discord連携はTelegramより設定項目が多い。手順通りに進めれば問題ない。

### Step 1: Discord Botを作成

1. [Discord Developer Portal](https://discord.com/developers/applications) にアクセス
2. 右上の「New Application」をクリック
3. アプリケーション名を入力（例: `My OpenClaw`）
4. 左メニューの「Bot」をクリック
5. 「Reset Token」をクリックしてトークンを取得

:::message alert
**重要: トークンをコピーして保存**
トークンは一度しか表示されない。忘れたら「Reset Token」で再発行が必要。
:::

### Step 2: Intent（ボットが読み取れる情報の許可）を有効化

**これを忘れるとボットがメッセージを読めない。**

1. Bot設定ページで下にスクロール
2. 「Privileged Gateway Intents」（特別な権限設定）セクションを見つける
3. 以下を **ON** にする:
   - **MESSAGE CONTENT INTENT** （必須）
   - **SERVER MEMBERS INTENT** （推奨）

4. ページ下部の「Save Changes」をクリック

:::message alert
**ハマりポイント: Intent設定忘れ**
Intentを有効化しないと、ボットはメッセージの内容を読めない。「ボットが反応しない」という場合は、まずここを確認。
:::

### Step 3: ボットをサーバーに招待

1. 左メニューの「OAuth2」→「URL Generator」をクリック
2. 「SCOPES」で以下を選択:
   - `bot`
   - `applications.commands`

3. 「BOT PERMISSIONS」で以下を選択:
   - View Channels
   - Send Messages
   - Read Message History
   - Embed Links
   - Attach Files
   - Add Reactions

4. ページ下部に生成されたURLをコピー
5. ブラウザで開き、ボットを追加するサーバーを選択

### Step 4: OpenClawに設定

WSL2のUbuntu内で以下を実行。

```bash
openclaw channels add --channel discord --token "YOUR_BOT_TOKEN"
```

### Step 5: Gatewayを起動

```bash
openclaw gateway
```

**出力例:**

```
🦞 Gateway started on ws://127.0.0.1:18789
[discord] Logged in as MyOpenClaw#1234
```

### Step 6: 動作確認

1. Discordサーバーでボットがオンラインになっているか確認
2. 任意のチャンネルでボットにメンション（例: `@MyOpenClaw こんにちは`）
3. AIから返信が来れば成功

---

## Discord セキュリティ設定

セキュリティ設定は `~/.openclaw/openclaw.json` を編集して行う。

### DMを無効化

サーバー内でのみ利用可能にする。

```json
{
  "channels": {
    "discord": {
      "enabled": true,
      "token": "YOUR_TOKEN",
      "dm": { "enabled": false }
    }
  }
}
```

### 特定のサーバー・ユーザーだけ許可

```json
{
  "channels": {
    "discord": {
      "enabled": true,
      "token": "YOUR_TOKEN",
      "guilds": {
        "YOUR_GUILD_ID": {
          "users": ["YOUR_USER_ID"],
          "requireMention": true
        }
      }
    }
  }
}
```

:::message
**IDの調べ方**
1. Discordの設定を開く（歯車アイコン）
2. 「アプリの設定」→「詳細設定」
3. 「開発者モード」をON
4. サーバーやユーザーを右クリック →「IDをコピー」
:::

### 特定のチャンネルだけ許可

```json
{
  "channels": {
    "discord": {
      "enabled": true,
      "token": "YOUR_TOKEN",
      "guilds": {
        "YOUR_GUILD_ID": {
          "channels": {
            "CHANNEL_ID": {
              "allow": true,
              "requireMention": true
            }
          }
        }
      }
    }
  }
}
```

---

## トラブルシューティング

### Telegram

| 問題 | 原因 | 解決策 |
|------|------|--------|
| ボットが返信しない | Gatewayが起動していない | `openclaw gateway` を実行 |
| 「認証エラー」 | トークンが間違っている | @BotFatherで確認・再発行 |
| グループで反応しない | Privacy Modeが有効 | @BotFatherで `/setprivacy` → Disable |

### Discord

| 問題 | 原因 | 解決策 |
|------|------|--------|
| ボットがオフラインのまま | Gatewayが起動していない | `openclaw gateway` を実行 |
| メッセージに反応しない | MESSAGE CONTENT INTENTが無効 | Developer Portalで有効化 |
| 「Missing Permissions」 | 権限不足 | ボットの役割に必要な権限を追加 |
| 招待URLが機能しない | スコープ/権限の選択漏れ | URL Generatorで再生成 |

### 共通

```bash
# 状態確認
openclaw doctor

# チャンネル状態確認
openclaw channels status

# ログ確認
openclaw logs
```

---

## 実用的なユースケース

### 個人アシスタント（Telegram）

- 外出先からスマホでAIに質問
- 調べ物、翻訳、要約をサクッと依頼
- メモ代わりに情報を送って後で整理

### グループ利用（Discord）

- サークルや趣味グループでの情報整理ボット
- 勉強会の質問受付アシスタント
- 特定チャンネルでのみ動作させてノイズを防ぐ

### Claude Code との連携

OpenClawの「coding-agent」スキル（AIに追加機能を与える設定）を使えば、Discordからコード関連の指示も可能。

```
@OpenClaw このプロジェクトのテストを実行して
```

→ 内部でClaude CodeやCodex CLIが動く

---

## Gatewayの常駐化

PCを再起動してもOpenClawが自動で動くようにする。

```bash
openclaw onboard --install-daemon
```

これでシステムサービスとして登録され、自動起動するようになる。

**サービスの状態確認:**

```bash
openclaw status
```

**サービスの停止:**

```bash
openclaw gateway stop
```

---

## まとめ

| プラットフォーム | おすすめ度 | 用途 |
|-----------------|-----------|------|
| **Telegram** | 初心者向け | 個人利用、手軽に試したい時 |
| **Discord** | 中級者向け | チーム利用、細かい権限制御が必要な時 |

OpenClawを使えば、Discord・Telegramがそのまま「AIアシスタントの窓口」になる。Claude Codeと組み合わせれば、外出先からでも開発環境を操作できる。

---

## 参考リンク

- [OpenClaw 公式ドキュメント - Telegram](https://docs.openclaw.ai/channels/telegram)
- [OpenClaw 公式ドキュメント - Discord](https://docs.openclaw.ai/channels/discord)
- [OpenClaw Gateway](https://docs.openclaw.ai/gateway)
- [OpenClaw Authentication](https://docs.openclaw.ai/gateway/authentication)
- [OpenClaw Troubleshooting](https://docs.openclaw.ai/help/troubleshooting)
- [Discord Developer Portal](https://discord.com/developers/applications)
- [Telegram BotFather](https://t.me/BotFather)

---

## 関連記事

- [Linux（Ubuntu）インストールガイド（Windows）](wsl2-windows-install-guide)
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
