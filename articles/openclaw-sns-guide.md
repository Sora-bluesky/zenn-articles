---
title: "OpenClawでDiscord/LINEを個人AIアシスタント化する"
emoji: "🦞"
type: "tech"
topics: ["openclaw", "discord", "line", "ai", "個人開発"]
published: true
---

:::message alert
OpenClawのインストールが完了している前提で進める。まだの場合は先に導入ガイドを参照：
- [XServer VPSで安全に動かす](openclaw-setup-guide)（VPS推奨）
- [WSL2で無料で試してみた](openclaw-wsl2-setup-guide)（ローカル試用）
:::

:::message
**シリーズ構成**
- [Linux（Ubuntu）インストールガイド（Windows）](wsl2-windows-install-guide)
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- 🦞OpenClaw導入ガイド
  - [XServer VPSで安全に動かす](openclaw-setup-guide)
  - [WSL2で無料で試してみた](openclaw-wsl2-setup-guide)
- [🦞OpenClawでDiscord/LINEを個人AIアシスタント化する](openclaw-sns-guide)（この記事）
:::

---

## チャット連携で何が変わるのか

連携前：
- AIを使うにはPCでブラウザを開く必要がある
- 外出先ではスマホアプリでチャットするだけ
- AIに「これやって」と言っても、実際の作業は自分でやる
- 過去の会話内容は覚えていない

連携後：
- いつも使っているDiscordやLINEがAIアシスタントの窓口になる
- 外出先から「〇〇のファイルを確認して」と送るだけ
- AIが実際にPCを操作して結果を報告してくれる
- 過去の会話や決定事項を覚えている

### 活用シーン

外出先で急にファイルが必要になった：
> 「デスクトップの企画書.docxの内容を教えて」
> → OpenClawがファイルを開いて内容を要約して返信

毎朝の情報整理を自動化：
> 毎朝9時に「今日のカレンダー + やることリスト」が自動でLINEに届く

開発者向け（Claude Code連携）：
> 「プロジェクトXのテストを実行して結果を教えて」
> → OpenClawがClaude Codeと連携してテスト実行、結果をDiscordに報告

---

## 難易度比較

| プラットフォーム | 難易度 | 所要時間 | 特徴 |
|-----------------|--------|----------|------|
| Discord | やや複雑 | 15分 | Intent設定、権限設定が必要 |
| LINE | 複雑 | 30分 | LINE公式アカウント作成、HTTPS必須、プラグインインストール |

Discordはコア機能として組み込まれており、追加インストールが不要。LINEはプラグインのインストールに加え、Webhook用のHTTPS環境が必要になる。

まずDiscordで感覚をつかんで、その後LINEに挑戦する流れがおすすめ。

---

## Discord連携

### Discord Botを作成する

1. [Discord Developer Portal](https://discord.com/developers/applications) にアクセス
2. 右上の「New Application」をクリック
3. アプリケーション名を入力（例: `My OpenClaw`）
4. 左メニューの「Bot」をクリック
5. 「Reset Token」をクリックしてトークンを取得

:::message alert
トークンは一度しか表示されない。忘れたら「Reset Token」で再発行が必要。必ずコピーして保存すること。
:::

### Intentを有効化する

Intent（インテント）は、ボットがどの情報にアクセスできるかの許可設定。「メッセージの内容を読む権限」のようなもの。これを忘れるとボットがメッセージを読めない。ハマりポイントの筆頭。

1. Bot設定ページで下にスクロール
2. 「Privileged Gateway Intents」セクションを見つける
3. 以下をONにする:
   - MESSAGE CONTENT INTENT（メッセージの中身を読む権限。必須）
   - SERVER MEMBERS INTENT（サーバーメンバー情報へのアクセス。推奨）
4. ページ下部の「Save Changes」をクリック

:::message alert
「ボットが反応しない」という場合は、まずIntentを確認。ここが原因のケースが圧倒的に多い。
:::

### ボットをサーバーに招待する

1. 左メニューの「OAuth2」→「URL Generator」をクリック（OAuth2はボットの認証・権限管理の仕組み）
2. 「SCOPES」で `bot` と `applications.commands` を選択（SCOPESはボットの権限範囲）
3. 「BOT PERMISSIONS」で以下を選択:
   - View Channels
   - Send Messages
   - Read Message History
   - Embed Links
   - Attach Files
   - Add Reactions
4. ページ下部に生成されたURLをコピー
5. ブラウザで開き、ボットを追加するサーバーを選択

### OpenClawに設定する

```bash
openclaw channels add --channel discord --token "YOUR_BOT_TOKEN"
```

### Gatewayを起動して動作確認

```bash
openclaw gateway
```

出力例：

```
🦞 Gateway started on ws://127.0.0.1:18789
[discord] Logged in as MyOpenClaw#1234
```

この表示が出ればGatewayは正常に起動している。`ws://127.0.0.1:18789` はローカルの通信先アドレスで、外部には公開されない。

Discordサーバーでボットがオンラインになっているか確認し、任意のチャンネルで `@MyOpenClaw こんにちは` とメンションする。AIから返信が来れば成功。

---

## Discordセキュリティ設定

セキュリティ設定は `~/.openclaw/openclaw.json` を編集する。`~` はホームディレクトリ（Linuxなら `/home/ユーザー名/`、WindowsのWSL2も同様）の省略記号。

### DMを無効化する

サーバー内でのみ利用可能にする設定：

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

### 特定のサーバーとユーザーだけ許可する

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
IDの調べ方：Discordの設定（歯車アイコン）→「アプリの設定」→「詳細設定」→「開発者モード」をON。サーバーやユーザーを右クリック →「IDをコピー」。
:::

### 特定のチャンネルだけ許可する

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

## LINE連携

LINEは日本で最も使われているメッセージアプリ。OpenClawと連携すれば、スマホのLINEからAIアシスタントに指示を出せるようになる。

Discordと違い、LINEはプラグインのインストールとHTTPS環境が必要になる。

### LINE公式アカウントを作る

2024年9月以降、LINE DevelopersコンソールからMessaging APIチャネルを直接作成する方法は廃止された。LINE Official Account Manager経由で作成する。

1. [LINE公式アカウント作成ページ](https://entry.line.biz/form/entry/unverified)にアクセス
2. LINEアカウントまたはメールアドレスでビジネスIDに登録
3. 必要事項を入力してLINE公式アカウントを作成

:::message
LINE公式アカウントは無料で作れる。コミュニケーションプラン（無料）で月200通まで送信可能。OpenClawの応答メッセージ（Reply API）は課金対象外なので、個人利用なら実質無料で使える。
:::

### Messaging APIを有効にする

1. [LINE Official Account Manager](https://manager.line.biz/) にログイン
2. 作成したアカウントを選択
3. 設定 → Messaging API → 「Messaging APIを利用する」をクリック
4. プロバイダーを選択（または新規作成）

:::message alert
プロバイダーの選択は後から変更できない。個人利用なら自分の名前で新規作成するのが無難。
:::

5. 応答メッセージを「オフ」に切り替え
6. あいさつメッセージも「オフ」推奨
7. Webhookを「有効」に

:::message
応答メッセージをオフにしないと、OpenClawの応答とLINEの自動応答が両方返ってしまう。
:::

### チャネルアクセストークンとシークレットを取得

1. [LINE Developersコンソール](https://developers.line.biz/console/) にログイン
2. プロバイダー → 作成したMessaging APIチャネルを選択
3. 「Messaging API設定」タブで以下を取得：
   - チャネルアクセストークン（「発行」ボタンで長期トークンを発行）
   - チャネルシークレット（「チャネル基本設定」タブに記載）

:::message alert
トークンとシークレットは秘密にする。他人に知られるとボットを乗っ取られる。
:::

### OpenClaw LINEプラグインをインストール

LINEはコア機能ではなくプラグインとして提供されている。

```bash
openclaw plugins install @openclaw/line
```

`@openclaw/line` の `@openclaw` はパッケージの提供元（公式プラグイン）を表す。npmのスコープ記法。

インストール確認：

```bash
openclaw plugins list
```

### HTTPS環境を用意する

LINE Messaging APIはWebhookの受信先にHTTPSを要求する。自分で作った証明書（自己署名証明書）では受け付けてもらえず、正規の認証局が発行したものが必要。ngrokやCloudflare Tunnelなら正規の証明書が自動で使われるので、この点を気にしなくていい。

| 方法 | 用途 | 特徴 |
|------|------|------|
| ngrok | テスト・検証 | 無料枠あり。URLが再起動で変わる |
| Cloudflare Tunnel | 本番運用 | 無料。URLが固定 |
| Caddy + ドメイン | VPS本番運用 | 自動SSL。ドメイン必要 |

まず試すならngrokが一番手軽。

```bash
# ngrokのインストール（未導入の場合）
# https://ngrok.com/ からダウンロード

# OpenClaw GatewayのポートをHTTPSで公開
ngrok http 18789
```

ngrokが表示するHTTPS URL（例: `https://xxxx-xx-xx.ngrok-free.app`）をコピーしておく。

:::message
ngrok無料枠ではURLが再起動のたびに変わる。毎回LINE DevelopersコンソールでWebhook URLを更新する必要がある。常時運用するならCloudflare Tunnelへの移行を検討。
:::

:::message alert
Tailscale Funnelは特殊ヘッダーの問題でLINE Webhookに対応していない。使わないこと。
:::

### openclaw.jsonに設定する

`~/.openclaw/openclaw.json` に以下を追加：

```json
{
  "channels": {
    "line": {
      "enabled": true,
      "channelAccessToken": "YOUR_CHANNEL_ACCESS_TOKEN",
      "channelSecret": "YOUR_CHANNEL_SECRET",
      "dmPolicy": "pairing"
    }
  }
}
```

`dmPolicy` はダイレクトメッセージの扱い方。`pairing` にすると、初回メッセージ時にペアリングコード（ターミナルに表示される認証コード）の入力を求める。知らない人がボットに話しかけても、コードを知らなければ操作できない。

環境変数を使う場合は `~/.openclaw/.env` に記載：

```
LINE_CHANNEL_ACCESS_TOKEN=xxxxxxxxxxxx
LINE_CHANNEL_SECRET=yyyyyyyyyyyy
```

### Webhook URLを設定する

1. [LINE Developersコンソール](https://developers.line.biz/console/) → チャネル → 「Messaging API設定」タブ
2. Webhook URL に以下を入力：

```
https://xxxx-xx-xx.ngrok-free.app/line/webhook
```

3. 「検証」ボタンをクリック → 「成功」と表示されればOK
4. 「Webhookの利用」を有効にする

### Gatewayを起動して動作確認

```bash
# Gatewayを再起動（設定変更後は再起動が必要）
openclaw gateway
```

1. スマホのLINEアプリで、作成したLINE公式アカウントを友だち追加
2. 何かメッセージを送信
3. ペアリングコードを求められた場合は、ターミナルに表示されるコードを入力
4. AIから返信が来れば成功

---

## LINEセキュリティ設定

### 特定のユーザーだけ許可する

自分だけがボットを使えるようにする設定：

```json
{
  "channels": {
    "line": {
      "enabled": true,
      "channelAccessToken": "YOUR_TOKEN",
      "channelSecret": "YOUR_SECRET",
      "dmPolicy": "allowlist",
      "allowFrom": ["U1234567890abcdef1234567890abcdef"]
    }
  }
}
```

:::message
LINE IDの形式はユーザーが `U` + 32桁の16進数、グループが `C` + 32桁。大文字小文字を区別する。自分のLINE IDはWebhookログから確認できる：`openclaw logs --follow` でメッセージを送り、ログに表示されるIDをコピー。
:::

### グループでの利用

```json
{
  "channels": {
    "line": {
      "enabled": true,
      "channelAccessToken": "YOUR_TOKEN",
      "channelSecret": "YOUR_SECRET",
      "groupPolicy": "allowlist",
      "groupAllowFrom": ["C1234567890abcdef1234567890abcdef"]
    }
  }
}
```

---

## LINE固有の制限事項

| 項目 | 制限 |
|------|------|
| テキスト最大文字数 | 5,000文字（超過分は自動分割） |
| メディアダウンロード | デフォルト10MB（`mediaMaxMb` で変更可） |
| Markdown | 自動削除（コードブロックとテーブルはFlexカードに変換） |
| リアクション | 未対応 |
| スレッド | 未対応 |
| ストリーミング応答 | バッファリング（ローディングアニメーション表示） |

### LINE公式アカウントの料金（2026年2月時点）

| プラン | 月額 | 無料メッセージ | 追加メッセージ |
|--------|------|---------------|---------------|
| コミュニケーション | ¥0 | 200通 | 不可 |
| ライト | ¥5,000（税別） | 5,000通 | 不可 |
| スタンダード | ¥15,000（税別） | 30,000通 | 約¥3/通〜 |

:::message
OpenClawの応答メッセージ（Reply API）は課金対象外。ユーザーがメッセージを送り、それに対してOpenClawが返信する使い方なら、無料プランで十分。課金対象になるのはPush API（ボット側から先にメッセージを送る場合）のみ。
:::

---

## トラブルシューティング

### Discord

| 問題 | 原因 | 解決策 |
|------|------|--------|
| ボットがオフラインのまま | Gatewayが起動していない | `openclaw gateway` を実行 |
| メッセージに反応しない | MESSAGE CONTENT INTENTが無効 | Developer Portalで有効化 |
| 「Missing Permissions」 | 権限不足 | ボットの役割に必要な権限を追加 |
| 招待URLが機能しない | スコープや権限の選択漏れ | URL Generatorで再生成 |

### LINE

| 問題 | 原因 | 解決策 |
|------|------|--------|
| Webhook検証が失敗する | HTTPS未対応またはシークレットの不一致 | ngrokのHTTPS URL確認、シークレットをコンソールと照合 |
| メッセージが届かない | Webhookパスの不一致 | URLが `/line/webhook` で終わっているか確認 |
| 二重応答になる | LINE応答メッセージがオン | Official Account Managerで応答メッセージをオフに |
| メディアがダウンロードできない | ファイルサイズ超過 | `mediaMaxMb` を引き上げ |
| ペアリングが承認されない | dmPolicyがpairingのまま | ターミナルのコード確認、または `allowFrom` にIDを追加 |

### 共通

```bash
# システム診断
openclaw doctor

# チャンネル状態確認
openclaw channels status

# リアルタイムログ
openclaw logs --follow

# プラグイン診断（LINE）
openclaw plugins doctor
```

---

## ユースケース

### 個人アシスタント（LINE）

LINEは日本のユーザー9,600万人が使っている。新しいアプリのインストールが不要で、スマホからそのままAIに指示を出せる。

- 外出先からスマホでAIに質問
- 調べ物、翻訳、要約をサクッと依頼
- メモ代わりに情報を送って後で整理

### グループ利用（Discord）

- サークルや趣味グループでの情報整理ボット
- 勉強会の質問受付アシスタント
- 特定チャンネルでのみ動作させてノイズを防ぐ

### Claude Code との連携

OpenClawの「coding-agent」スキルを使えば、DiscordやLINEからコード関連の指示も出せる。

```
@OpenClaw このプロジェクトのテストを実行して
```

内部でClaude CodeやCodex CLIが動く。

### 複数チャネル同時運用

DiscordとLINEを同時に起動し、それぞれのチャットにOpenClawが自動で応答する構成も可能。1つのGatewayプロセスで複数チャネルを管理できる。

---

## Gatewayの常駐化

PCを再起動してもOpenClawが自動で動くようにする：

```bash
openclaw onboard --install-daemon
```

状態確認：

```bash
openclaw status
```

停止：

```bash
openclaw gateway stop
```

---

## 参考リンク

- [OpenClaw 公式ドキュメント - Discord](https://docs.openclaw.ai/channels/discord)
- [OpenClaw 公式ドキュメント - LINE](https://docs.openclaw.ai/channels/line)
- [OpenClaw Gateway](https://docs.openclaw.ai/gateway)
- [OpenClaw Authentication](https://docs.openclaw.ai/gateway/authentication)
- [OpenClaw Troubleshooting](https://docs.openclaw.ai/help/troubleshooting)
- [Discord Developer Portal](https://discord.com/developers/applications)
- [LINE Developers](https://developers.line.biz/ja/)
- [LINE Messaging APIを始めよう](https://developers.line.biz/ja/docs/messaging-api/getting-started/)
- [LINE公式アカウント料金プラン](https://www.lycbiz.com/jp/service/line-official-account/plan/)

---

## 関連記事

- [Linux（Ubuntu）インストールガイド（Windows）](wsl2-windows-install-guide)
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
