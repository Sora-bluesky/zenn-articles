---
title: "【第5回】Hermes Agentの頭脳と出入口を2系統に増やす──GrokとDiscordを足す"
emoji: "🤖"
type: "tech"
topics: ["vps", "hermes", "discord", "oauth", "xai"]
published: false
---

## 目次

- [この回の到達点](#この回の到達点)
- [なぜ頭脳も出入口も2系統持つのか](#なぜ頭脳も出入口も2系統持つのか)
- [用語の最低限の理解](#用語の最低限の理解)
- [第5回終了時点の構成図](#第5回終了時点の構成図)
- [事前準備](#事前準備)
- [Grokを2つ目のAIとして登録する](#grokを2つ目のaiとして登録する)
- [Discordを2つ目の窓口として追加する](#discordを2つ目の窓口として追加する)
- [providerとmessengerの選び方](#providerとmessengerの選び方)
- [実行前に承認を挟む設定を確認する](#実行前に承認を挟む設定を確認する)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [まとめと第6回予告](#まとめと第6回予告)
- [公式ドキュメント引用元](#公式ドキュメント引用元)

第4回で「Codex(頭脳1系統)+Telegram(出入口1系統)」の最小構成が動いた。第5回はその構成を広げる回。

頭脳(provider)をCodex単独からCodex+Grokの2系統に、出入口(messenger)をTelegram単独からTelegram+Discordの2系統に広げる。最後に安全モデルを確認する——コマンドは第4回のDockerコンテナの中で隔離実行され、その外側に承認モード(`approvals.mode=manual`)をlocal時の保険として置く。

シリーズの全体像はこちら。

- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy)──VPSを契約して最小限の安全な状態でadminにログイン
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale)──Tailscaleで公開SSHを閉じる
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password)──1Password Service Accountと`op run`でsecrets管理
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install)──DockerサンドボックスとHermes Agentのインストール+Codex OAuth+Telegram疎通
- **第5回**(本記事)──Grok OAuthとDiscordを足す+承認モードの確認
- 第6回──systemd常駐化(`hermes gateway install`)
- 第7回──公式アプリ「Hermes Desktop」でマウス操作する
- 第8回──Web Dashboardで設定をブラウザ管理する
- 第9回──Cronで毎朝の定型タスクを任せる
- 第10回──Skillsに手順を覚えさせる
- 第11回──Web/X検索の使い分け(SearXNG+Firecrawl+X Search)
- 第12回──家の余ったPCをLinux常駐GPUサーバーにする(VPSの手足)

## この回の到達点


第4回完了時と第5回完了後の差分を表にする。動作確認(`hermes gateway`起動+疎通)は第4回でやったので、第5回では繰り返さない。常駐化と「Grokもmessengerも実際に動く」確認は第6回で一気通貫でやる。

| 項目 | 第4回完了時 | 第5回完了後 |
|------|------------|------------|
| Hermes Agent本体 | インストール+`hermes setup`完了+main運用 | 変わらず |
| backend | docker | 変わらず |
| provider(頭脳) | Codex(`openai-codex`)1系統 | **Codex+Grok(`xai-oauth`)2系統** |
| messenger(出入口) | Telegram 1系統 | **Telegram+Discord 2系統** |
| Discord botトークン | `secrets.env`に参照だけ書いた状態 | **Developer Portal発行→1Password格納→hermes config登録** |
| 承認モード | セットアップウィザードで決めた | **`approvals.mode=manual`を明示確認+周辺設定を理解** |
| 常駐起動 | なし | なし(第6回でsystemd化) |

第4回末尾で `hermes setup` のProvider選択(OpenAI Codex)時に**デバイスコードフローでOAuth登録も同時に走る**ので、`hermes auth list`を打つと既に `openai-codex (1 credentials): #1 device_code oauth` のように出ているはずだ。第5回で再登録する必要はない。

## なぜ頭脳も出入口も2系統持つのか


「Codexが動いてTelegramで会話できてるんだから、十分じゃないか」と思うかもしれない。実際、第4回時点でHermes Agentとしては動く。

ただ、現場で運用していると以下のような声を見かける。

> Codex CLI、たまにstreamingで止まる。30秒待っても応答こない時がある。
> ([GitHub Issue](https://github.com/NousResearch/hermes-agent/issues/33102) 等で類似報告)

> Telegram BotAPIが落ちると会話できない。Discord Bridgeでフォールバックしたい。
> (Hermes Agent Discord公式チャンネル2026-05投稿)

> SuperGrok契約でGrokが使えるようになった。エージェント側からネイティブで呼べるなら試したい。
> ([x.ai/news/grok-hermes](https://x.ai/news/grok-hermes) 2026-05-15)

つまり、片方が落ちても会話を続けられる冗長構成と、用途で使い分けられる選択肢が要る。Hermes Agent本体は元から複数provider・複数messengerを同時に持てる設計なので、第5回でその設計を実際に使う形に組む。

## 用語の最低限の理解


第5回で出てくる用語をざっくり押さえておく。

| 用語 | 意味 |
|------|------|
| OAuth | 「自分のアカウントへのアクセス権を、安全に他のアプリに渡す」標準の仕組み。マスターキーは渡さず、特定の機能だけ開けられるカードキーを渡す感覚 |
| デバイスコードフロー | 端末側にコードが表示されて、それを別端末のブラウザで承認するOAuth方式。テレビにコードが出てスマホで承認するNetflixログインに近い |
| loopback OAuth | 端末内の特定のポート(56121等)にブラウザがリダイレクトして承認するOAuth方式。Grokがこの方式を使う |
| SSHトンネリング | 手元PC↔VPSの間に「特定のポート番号だけを通す仮想トンネル」を作る。VPSにブラウザが無いので、loopback OAuthを成立させるために必要 |
| 承認モード(`approvals.mode`) | エージェントがコマンドを実行する前に「これ実行していい?」と人間に確認する設定。`manual`(=旧名ask)で固定する設定。ただしDocker backend(本シリーズ既定)では承認は原則出ず、これはlocal backendに戻したときの保険(第6回参照) |

## 第5回終了時点の構成図


provider・messenger・承認モードの3つに焦点を絞った構成。

![第5回終了時点の構成図(provider 2系統+messenger 2系統+承認モードmanual)](/images/hermes-vps/hermes-vps-05-architecture.png)

ファイル配置と設定の関係は次のとおり。

![第5回終了時点のVPS内ファイル構成図(★第5回で追加された部分)](/images/hermes-vps/hermes-vps-05-files.png)

テキスト表記でも見ておく(コピペ参照用)。

```
┌──────────────────────────────────────────────────────────────┐
│   VPS(Ubuntu 26.04 / admin)                                  │
│                                                              │
│   ~/.hermes/                                                 │
│   ├── service-account.env(SA、第3回)                         │
│   ├── secrets.env(op://参照、第3回)                          │
│   │     ├── TELEGRAM_BOT_TOKEN=op://...    ← 第4回で実値投入  │
│   │     └── DISCORD_BOT_TOKEN=op://...     ←★第5回で実値投入 │
│   ├── .env / config.yaml(第4回)                              │
│   └── auth.json                                              │
│        ├── openai-codex (1 credentials)    ← 第4回setupで登録 │
│        └── xai-oauth    (1 credentials)    ←★第5回で追加     │
│                                                              │
│   config.yaml                                                │
│   ├── approvals.mode = manual              ← 安全装置を明示確認│
│   └── messaging.discord (有効化)            ←★第5回で追加     │
│                                                              │
│            ┌─── @hermes_vps_xxxxxx_bot(Telegram、第4回)      │
│   Hermes ──┤                                                 │
│            └─── #hermes-channel(Discord、★第5回)            │
└──────────────────────────────────────────────────────────────┘
```

動作確認(`op run -- hermes gateway`+Telegram/Discord疎通)は第6回(systemd常駐化)に統合する。第4回で1度見せた疎通フローを本回で繰り返さない方針だ。

## 事前準備


VPSにadminでSSHログインしてHermes作業環境に入る。

```bash
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps
cd ~/hermes-agent
source venv/bin/activate
hermes version
```

`(venv) admin@hermes-vps:~/hermes-agent$` のプロンプトになり、`hermes version`でv0.14系が表示されればOK。

:::message
「Update available: N commits behind」が出ても気にしない。第4回末尾で`git pull origin main`済みなので必要な修正(`43a3f119f`)は既に取り込まれている。mainは不安定なので、動作確認済みの第4回時点のHEADで進める。第5回作業開始時の基準commit SHAだけ`git rev-parse HEAD`で記録しておくと、トラブル時の比較対象になる。
:::

![SSH接続後のプロンプトが(venv) admin@...:~/hermes-agent$になっている画面+~/.hermes/のファイル一覧](/images/hermes-vps/hermes-vps-05-ssh-login-hermes-files.png)

第4回で作った設定とCodex OAuth登録済みを再確認する。

```bash
ls -la ~/.hermes/
cat ~/.hermes/secrets.env
hermes auth list
```

`hermes auth list`のv0.14.0時点の出力フォーマットは以下の形だ。

```text
openai-codex (1 credentials):
  #1  device_code          oauth   device_code ←
```

「authenticated」という単語ではなく、プロバイダ名+credential数+認証方式+矢印(`←`)で「ログイン済み」を示す。矢印は「現在アクティブなcredential」のマーカーだ。

![cat secrets.envの出力+hermes auth listでopenai-codexにdevice_code ←が付いている](/images/hermes-vps/hermes-vps-05-secrets-env-auth-list.png)

:::message alert
`~/.hermes/auth.json`を絶対に手で編集しない。Hermes Agentがクロスプロセスファイルロックで排他管理しており、手動編集するとtoken refreshが壊れて再認証が必要になる。中身の閲覧も基本的に不要だ。

出典:[hermes_cli/auth.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/auth.py)冒頭コメント「persisted in `~/.hermes/auth.json` with cross-process file locking」
:::

## Grokを2つ目のAIとして登録する


Grokの認証は**loopback OAuth**(OAuth 2.0 PKCE)。xAI側でログインしたあと、ブラウザが `http://127.0.0.1:56121/callback?code=...&state=...` に**端末自身の56121ポート**へリダイレクトして承認完了する仕組みだ。

本来は端末のブラウザで完結する設計だが、VPSにはブラウザがない。だから**SSHトンネリングで56121ポートを手元PCに引き出す**必要がある。これはHermes Agent側のバグではなく、xAI OAuthが厳格な`redirect_uri`検証(ループバック固定)をしているための仕様だ。

[2026年5月15日のxAI公式連携](https://x.ai/news/grok-hermes)で、SuperGrokまたはX Premium+契約者はOAuth経由でAPIキー不要でGrok 4.3 / Grok TTS / Grok Imagine / Xリアルタイム検索が使えるようになった。本シリーズはSuperGrok前提で進める。

### SSHトンネリング用の新規ターミナルを開く

「VPSの`localhost:56121`を手元PCの`localhost:56121`に転送する」だけのSSH接続を、別タブで張っておく。コマンド入力には使わない。

```bash
# 手元PCで新しいPowerShell/ターミナルタブを開いて
ssh -N -L 56121:127.0.0.1:56121 -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps
```

各オプションの意味は以下の通りだ(出典:[Hermes Agent公式OAuth over SSHガイド](https://hermes-agent.nousresearch.com/docs/guides/oauth-over-ssh))。

| オプション | 意味 |
|---|---|
| `-N` | SSH接続にシェルを要求しない(転送だけ動かす)。公式ガイド推奨 |
| `-L 56121:127.0.0.1:56121` | 「手元PCのポート56121に来た通信を、VPSの`localhost:56121`に転送する」 |

:::message
**ここがつまずきやすい**:Enterを押してもカーソルが戻らず、固まったように見えるのが成功のサインだ(`-N`はシェルを開かない指定なので、何も表示されないのが正常)。ここでウィンドウを閉じてはいけない。ブラウザでの認証が終わるまでこのタブはそのまま放置する。なお56121番は、Grokの認証が内部で使う固定の窓口番号(ポート)で、xAI側がこの番号以外を受け付けないため番号を変えられない。
:::

![手元PCの新規タブでssh -N -L ...を打った直後、エラーなくカーソルが返らない状態](/images/hermes-vps/hermes-vps-05-ssh-tunnel.png)

踏み台(bastion/jump host)経由の場合は`-J`でジャンプホストを挟む。

```bash
ssh -N -L 56121:127.0.0.1:56121 -J jump-user@jump-host admin@hermes-vps
```

### 元のadminセッションで `hermes auth add xai-oauth --no-browser`

トンネリング用タブはそのままに、**元のadminタブ**(`(venv) admin@hermes-vps:~/hermes-agent$`)で以下を実行する。

```bash
hermes auth add xai-oauth --no-browser
```

VPSにはブラウザがないので`--no-browser`でブラウザ自動起動を抑止する(公式ガイド記載)。

表示される認証URL(`http://127.0.0.1:56121/...`形式)を手元PCのブラウザにコピペで開く。SSHトンネリングのおかげで`127.0.0.1:56121`はVPS側に転送されてつながる。

![hermes auth add xai-oauth --no-browser実行直後、認証URLが表示された画面](/images/hermes-vps/hermes-vps-05-xai-oauth-auth-url.png)

手元PCのブラウザでxAIアカウント(SuperGrokまたはX Premium+)にログインすると、「Grok Buildを承認」画面が出る。Verify your identity / Read your profile / Read your email address / Maintain access when you're not present / Make authenticated requests from Grok Build / Use the xAI APIの6つの権限が列挙されるので、「**許可**」を押す。

![xAI認証画面「Grok Buildを承認」のスコープ一覧+「許可」ボタン](/images/hermes-vps/hermes-vps-05-xai-authorize.png)

「Grok Build」というのはxAI側のアプリ名で、Hermes Agent側のprovider名は`xai-oauth`だ。命名がずれているが同じものを指す。

承認するとブラウザがリダイレクトされて「接続に成功しました」の完了画面が出る。

![「接続に成功しました」完了画面](/images/hermes-vps/hermes-vps-05-xai-callback-success.png)

VPS側のターミナルでは以下のメッセージが返ってきて完了する。

```text
Added xai-oauth OAuth credential #1: "xai-oauth-oauth-1"
```

続けて`hermes auth list`を再実行すると、`openai-codex`と`xai-oauth`の両方にcredentialが付いている状態になっている。

![hermes auth listで両方のproviderにcredentialが付いている画面](/images/hermes-vps/hermes-vps-05-credential-added-auth-list.png)

OAuth登録が完了したらSSHトンネリングは不要だ。手元PC側のトンネル用タブで`Ctrl+C`か`exit`で閉じる。

:::message
OAuthのアクセストークン・リフレッシュトークンは`~/.hermes/auth.json`でHermes Agent本体が排他管理する。1Password管理対象には入れない。Hermes Agentが自動で`token refresh`する機構を尊重するためだ(第3回の方針継続)。
:::

### SSHトンネリングが使えない環境の代替

Cloud Shell / GitHub Codespaces / EC2 Instance Connectなど、SSHトンネリングが取れない環境向けに、公式は`--manual-paste`を用意している。

```bash
hermes auth add xai-oauth --manual-paste
```

表示されたURLを手元PCのブラウザで開き、ログイン後にブラウザのアドレスバーに表示される`http://127.0.0.1:56121/...`のフルURLをコピーしてVPS側のターミナルに貼り付ける。

本シリーズはSSHトンネリングを採用するので`--manual-paste`は使わない。環境の制約で`-L`転送が取れない場合の逃げ道として把握しておくとよい(出典:[同公式ガイド](https://hermes-agent.nousresearch.com/docs/guides/oauth-over-ssh))。

## Discordを2つ目の窓口として追加する


Telegram単独で運用するなら、この章はまるごと飛ばして次章の「[providerとmessengerの選び方](#providerとmessengerの選び方)」に進んでよい。後でDiscordを足したくなったらここに戻ればいい。


ここからの章はオプションだ。**Telegramだけで運用しても、Hermes Agentの7割以上の機能は損なわれない**。ボイスモード・image/file入出力・stream応答・skill自動ロード・cron配信・DM topicによるskill切替、すべてTelegram単独で動く。ソロ運用ならむしろTelegramのほうが軽量・モバイル可読性が高い。

**Discordを足す価値が高いのは以下のケース**だ。

- **複数人で同じHermes Agentを共有したい**:Discordはserver channel+role allowlistで承認フローが組める。Telegramはuser_id allowlist+group chat_id止まりで、role階層がない
- **応答UXを最大化したい**:絵文字リアクション(👀処理中→✅成功→❌失敗、`reactions: true`)とスラッシュコマンドのネイティブ補完(オートコンプリート選択肢)で「触っていて気持ちいい」プラットフォーム
- **ボイスチャンネルでbotと同期会話したい**:Telegramのvoiceは録音→送信→文字起こしの非同期、Discordはボイスチャンネルにbot入室して常時会話可能
- **PC主環境で運用したい**:Discord PCクライアントはチャンネル切替・history scroll・ピン留めなど操作UIが厚い

**逆に、以下のケースではDiscord追加の優先度は下がる**。

- ソロ運用+モバイル主体 → Telegramで必要十分
- 閉域網/プロキシ環境 → Discordは標準でプロキシ非対応、Telegramは`proxy_url`+`fallback_ips`対応
- 「とりあえず動かす」段階 → DiscordはMESSAGE CONTENT INTENTの罠で初期セットアップでつまずきやすく、学習コストがTelegramより高い

「自分の用途だとTelegramだけで足りそう」と判断したら、この章は読み飛ばして「[providerとmessengerの選び方](#providerとmessengerの選び方)」へ進んでいい。あとでDiscordを足したくなった時にここに戻ってくれば、同じ手順で追加できる。

---

第4回末尾で`secrets.env`に`DISCORD_BOT_TOKEN=op://...`の参照だけは書いた(1Password側のアイテム値は空)。第5回でDiscord Developer Portalでbotを作って実値を取得し、1Passwordに格納してHermes Agentで有効化する。「op://参照を先に書く→あとから実値を流し込む」のは第3回からの一貫したパターン(token平文をディスクに残さない方針)だ。

### Discord Developer Portalでアプリケーション作成

[discord.com/developers/applications](https://discord.com/developers/applications)にDiscordアカウントでログインする。Discord本体のUI言語が日本語なら、Developer Portalも日本語表記になる(本記事は日本語UI前提)。

1. 右上の青いボタン「**新しいアプリケーション**」をクリック
2. モーダル「**アプリを新規作成する**」が開くので、「**名前**」欄に`Hermes VPS`(任意)を入力 → 開発者向けサービス利用規約と開発者ポリシーへの同意チェック → 「**作成**」
3. 作成後、「**一般情報**」ページが開く。「**概要**」と「**タグ**」は空欄でOK(個人用Bot、Discord App Directoryに公開しないため)
4. 「**アプリID**」と「**公開キー**」は操作不要。後段のOAuth2 URLジェネレーターが自動で参照する。技術的には公開しても害は薄いが、本シリーズの記事スクショでは個人運用Bot特定を避けるためマスクする

![一般情報ページで「名前」にHermes VPS、概要・タグは空欄、アプリID・公開キーはマスク](/images/hermes-vps/hermes-vps-05-discord-general-info.png)

左サイドバーで「**Bot**」を開く。「**認可フロー**」セクションの「**公開Bot**」トグルはONのままで問題ない。

![Developer Portal左サイドバーで「Bot」を選択](/images/hermes-vps/hermes-vps-05-discord-sidebar-bot.png)

個人用Botでも招待URLを公開しなければ他人はインストールできないため実害なしだ。OFFに変更しようとすると「プライベートアプリケーションはデフォルトの認証リンクを持つことはできません」というエラーが出るが、これは別設定の「デフォルトインストール設定」を「なし」に変えてから保存する必要がある連動仕様。シンプルさ優先でONのまま進める。

「**Privileged Gateway Intents**」セクションで**Message Content Intent**を**ON**にする(HermesがDiscord上のメッセージ本文を読むのに必須)。残る2つ(Presence Intent / Server Members Intent)は**OFFのまま**でよい。後述の許可ユーザーを数値IDで指定すればServer Membersは不要だ(ユーザー名やロールで指定する場合だけServer Membersも要る)。画面下部に出る「**変更を保存**」ボタン(緑色)で保存する。

![Botページ:Privileged Gateway IntentsでMessage Content IntentのみON(Server Members / PresenceはOFF)、変更を保存済み](/images/hermes-vps/hermes-vps-05-discord-intent-on.png)

「**トークン**」セクションの「**トークンをリセット**」ボタンを押す。Discordアカウントに設定済みの多要素認証(2FA)で本人確認が走る。

:::message
**「トークンをリセット」で多要素認証(MFA)が要求される**:Discordアカウントに2FAが設定済みでないと先に進めない。2FA未設定なら、Discord本体「ユーザー設定」→「マイアカウント」→「二要素認証を有効化」(認証アプリ推奨)で先に有効化する必要がある。Developer Portalで機微操作するためのセキュリティ要件だ。
:::

認証アプリ(Google Authenticator / Authy等)が登録済みなら、6桁の認証コード入力欄が出る。認証アプリで生成した6桁を入力して「**送信**」。

承認すると新しいtokenが画面に表示される。**この場でコピー**しないと再表示不可だ(忘れたら再度リセットすれば良いが、その場合既存tokenは即無効化される)。

![トークンをリセット直後、新しいtokenが表示+「コピー」ボタン強調(tokenは黒塗りマスク)](/images/hermes-vps/hermes-vps-05-discord-token-reset.png)

なお、「**Botの権限**」セクション(画面下部の権限チェックボックス群)はこの画面では何もチェックしない。後述のOAuth2 URLジェネレーターで招待時に選ぶためだ。

### 取得したtokenを1Passwordに格納

第3回で作った保管庫`Hermes-Prod`のアイテム`Hermes VPS - Discord bot token`を開き、「**認証情報**」フィールドにtokenを貼り付けて保存する。

:::message
1Passwordの日本語UIでは「認証情報」と表示されるフィールドが、`op://`参照では内部名`credential`で参照される(第3回参照)。文中の操作説明は「認証情報」、コード/コマンド上の表記は`credential`と使い分ける。
:::

`secrets.env`の参照`DISCORD_BOT_TOKEN=op://Hermes-Prod/Hermes VPS - Discord bot token/credential`はそのまま再利用する(第4回末尾で書いた)。

VPSで`op run`経由で実値が展開されるか確認する。

```bash
op run --env-file=$HOME/.hermes/secrets.env -- bash -c 'echo ${DISCORD_BOT_TOKEN:0:10}'
```

token先頭10文字程度が表示されればOK(全文は出さない、頭だけで動作確認)。

![1Passwordで認証情報入力済み+メモ欄更新済み](/images/hermes-vps/hermes-vps-05-1password-discord.png)

![VPS側でop run経由でDISCORD_BOT_TOKEN先頭10文字が展開出力される](/images/hermes-vps/hermes-vps-05-discord-op-run-test.png)

### Hermes Agent側でDiscordを有効化

セットアップウィザードの**gateway**セクションを実行する。Messaging Platforms関連の設定はgatewayセクションに含まれる(出典:[hermes_cli/setup.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/setup.py)のセクション定義)。

```bash
hermes setup gateway
```

「Select platforms to configure:」の画面が出る。矢印キーで「Discord」までカーソル移動 → **SPACE**でチェック → **ENTER**で確定する。

![Select platforms画面でDiscordにチェック](/images/hermes-vps/hermes-vps-05-discord-wizard-select.png)

:::message
**Messaging Platforms画面で既設Telegramが「(not configured)」と表示される**:セットアップウィザードは各messengerの設定状態を`~/.hermes/.env`のtoken存在で判定する(出典:[setup.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/setup.py)の`setup_gateway`関数)。本シリーズは第4回末尾で`TELEGRAM_BOT_TOKEN`行を`.env`から除去している(平文をディスクに残さない方針)。そのためセットアップウィザードの画面ではTelegramも「(not configured)」と表示されるが、**実運用は1Password+`op run`経路で正常に動作している**。Discord有効化後も同じ理由で「(not configured)」表示になる。

ここで**Discordだけにチェックを入れる**。Telegramにチェックは不要だ。Discordだけが新規設定対象として処理され、既存のTelegram設定(`config.yaml`の`allowed_users`等)には触らない。
:::

Discordの設定プロンプトが順に出る。

1. **Discord botトークン**:1Passwordに保存した実tokenを貼り付ける。「Discord token saved」が緑文字で出れば成功
2. **Allowed user IDs or usernames**:**数値のユーザーIDを入れる**(推奨)。Discord本体「ユーザー設定」→「詳細設定」→「**開発者モード**」をON → 自分のアイコン右クリック → 「**ユーザーIDをコピー**」で取得。ユーザー名でも設定はできるが、自分のDiscordユーザー名と正確に一致が必要で(XやTelegramのハンドルとは別物のことが多い)、解決にServer Membersインテントも要る。数値IDなら一致ズレもインテントも不要で確実
3. **Home channel ID**(cron出力や通知の配信先チャンネル):**空Enter**でスキップ。チャンネルIDはbot招待後に取得する。home channelの設定はDiscord配信を使う場合の任意設定で、本シリーズの必須手順ではない
4. **Install the gateway as a systemd service?** [Y/n]:**n** で答える(常駐化は第6回でやる)

「`Messaging Platforms (Gateway) configuration complete!`」が緑文字で出れば完了だ。

![hermes setup gatewayの実行全体:Discord token saved→allowlist→home channel空→systemd n→completion](/images/hermes-vps/hermes-vps-05-discord-wizard-complete.png)

:::message
**許可ユーザーの指定はDiscordだけ数値IDが前提**(messengerで仕様が違う):Telegramは自分のユーザー名をそのまま許可リストに書ける。一方Discordは、ユーザー名で書くとbotが内部で「名前→数値ID」を解決する必要があり、その解決にServer Membersインテントが要る。本記事はServer MembersをOFFにする最小構成なので、Discordは最初から数値ユーザーIDで指定する。XやTelegramのハンドルとDiscordユーザー名は別物のことも多いので、数値IDなら取り違えも起きない。
:::

完了後、第4回でやったTelegram tokenと同じ後処理を踏む。`.env`に書かれたDiscord botトークン行を除去する(平文をディスクに残さない)。

```bash
sed -i '/^DISCORD_BOT_TOKEN=/d' ~/.hermes/.env
cat ~/.hermes/.env
```

`DISCORD_BOT_TOKEN`行が消えて、`DISCORD_ALLOWED_USERS=...`が残った状態になる。

![cat .envでDISCORD_BOT_TOKEN行が無い+DISCORD_ALLOWED_USERSが残っている](/images/hermes-vps/hermes-vps-05-discord-env-removed.png)

念のため、`config.yaml`側にDiscord有効化が書き込まれているか確認する。

```bash
grep -A 10 -i discord ~/.hermes/config.yaml
```

`discord:`セクションに`require_mention: true`、`free_response_channels: ''`、`allowed_channels: ''`、`auto_thread: true`、`history_backfill: true`等が並ぶ。

![grep -A 10 -i discord ~/.hermes/config.yamlでdiscordセクションが書き込まれている](/images/hermes-vps/hermes-vps-05-discord-config-enabled.png)

### Discordサーバーにbotを招待

Discord本体(デスクトップアプリまたはWeb版 [discord.com/app](https://discord.com/app))で、テスト用サーバーを作る。

1. 左サイドバー下部の「+」アイコン → 「サーバーの作成」モーダル表示
2. 「**オリジナルの作成**」を選択(テンプレートは事前設定チャンネルが入るので個人テストには不向き)
3. 用途は「**自分と友達のため**」を選択(クラブやコミュニティは公開向け)
4. サーバー名入力(`Hermes VPS Server`等)→「作成」
5. 「一般」(general)チャンネルが自動生成される

![「サーバーの作成」モーダル(「オリジナルの作成」を選ぶ)](/images/hermes-vps/hermes-vps-05-discord-server-create-modal.png)

![用途選択モーダル(「自分と友達のため」を選ぶ)](/images/hermes-vps/hermes-vps-05-discord-server-purpose.png)

![Hermes VPS Serverの作成完了画面](/images/hermes-vps/hermes-vps-05-discord-server-created.png)

Developer Portalに戻り、左サイドバー「**OAuth2**」を開く。「**OAuth2 URLジェネレーター**」セクションまでスクロール。

![Developer Portal左サイドバーで「OAuth2」を選択](/images/hermes-vps/hermes-vps-05-discord-oauth2-sidebar.png)

![OAuth2ページ上部のクライアント情報(クライアントIDマスク済み)](/images/hermes-vps/hermes-vps-05-discord-oauth2-client-info.png)

「**スコープ**」セクションで以下にチェック。

- `bot`(必須、botとして招待)
- `applications.commands`(`/set-home`等のスラッシュコマンドを使うために必須)

![スコープでbotとapplications.commandsにチェック済み](/images/hermes-vps/hermes-vps-05-discord-oauth2-scopes.png)

`bot`にチェックを入れると「**Botの権限**」セクションが下に出現する。日本語UIでは3列構成(「**一般権限**」「**テキストの権限**」「**音声の権限**」)。以下の5項目を選択する。

| カテゴリ | 権限名 |
|---|---|
| 一般権限 | **チャンネルを表示** |
| テキストの権限 | **メッセージを送る** |
| テキストの権限 | **メッセージ履歴を読む** |
| テキストの権限 | **リンクを埋め込み** |
| テキストの権限 | **スラッシュコマンドを使用** |

![Botの権限で5項目(チャンネルを表示・メッセージを送る・リンクを埋め込み・メッセージ履歴を読む・スラッシュコマンドを使用)にチェック済み](/images/hermes-vps/hermes-vps-05-discord-oauth2-bot-permissions.png)

「**連携タイプ**」は「**ギルドのインストール**」のままでOK(サーバー単位のインストール)。

最下部「**生成されたURL**」欄に招待URLが自動表示される。「コピー」ボタンでコピーして新規ブラウザタブで開く。

![OAuth2 URLジェネレーター:連携タイプ「ギルドのインストール」+生成URL(マスク済み)+「コピー」ボタン強調](/images/hermes-vps/hermes-vps-05-discord-oauth2-url-generated.png)

招待URLを開くと、Discord本体の招待画面が4段階で表示される。

1. **サーバー選択画面**:「Hermes VPSが次のDiscordアカウントへのアクセスを要求しています」+「サーバーに追加:」プルダウンで`Hermes VPS Server`を選択→「はい」

![招待画面1段目:サーバー選択(Hermes VPS Serverを選択)](/images/hermes-vps/hermes-vps-05-discord-invite-server-select.png)
2. **権限同意画面**:Hermes VPSが要求する権限(チャンネルを表示/メッセージを送信/埋め込みリンク/メッセージ履歴を読む/アプリコマンドを使う)の一覧表示→「認証」

![招待画面2段目:権限同意画面](/images/hermes-vps/hermes-vps-05-discord-invite-permissions.png)
3. **hCaptcha認証**:「ちょっと待って!あなた、本当に人間ですよね?」が出るので「**私は人間です**」にチェック(bot対策の人間確認)

![招待画面3段目:hCaptcha認証「私は人間です」](/images/hermes-vps/hermes-vps-05-discord-invite-hcaptcha.png)
4. **成功画面**:「成功!Hermes VPSが`Hermes VPS Server`に追加されました。」→画面を閉じる

![招待画面4段目:「成功!Hermes VPSがHermes VPS Serverに追加されました。」](/images/hermes-vps/hermes-vps-05-discord-invite-success.png)

:::message
上の招待画面(サーバー選択・権限同意・成功)は、サーバーのリネーム前に撮影したため旧名「Hermes Test」のまま表示されています。後で「Hermes VPS Server」へ名前を変えただけで、同じサーバーです。
:::

![Discord本体「Hermes VPS Server」でメンバー一覧にHermes VPSアプリが表示](/images/hermes-vps/hermes-vps-05-discord-bot-in-server.png)

Discord本体で`Hermes VPS Server`を開き、右上のメンバーアイコンを押してメンバー一覧を展開すると、**Hermes VPS**(`[アプリ]`バッジ付き)が表示される。`オフライン`状態だが、これは`hermes gateway`がまだ起動していないからだ(第6回で起動する)。

:::message
:warning: 権限を最小限にする理由

「管理者」「サーバー管理」「ロールの管理」等の強権限は付与しない。Hermes Agentが返信する以上の操作をbotに許可する必要はなく、万一tokenが漏洩した場合の被害を最小化するためだ。後で権限が足りなければ追加できる(サーバーのロール設定から)。
:::

### この先エージェントを複数に増やすときのヒント

いまは1つのHermes Agentに1つのbotだが、用途別にエージェント(プロファイル)を増やすなら、Discord側も「1エージェントにつき1つのbot」を割り当てると扱いやすい。

| 利点 | 中身 |
|---|---|
| 誰が返したか一目で分かる | エージェントごとに表示名とアイコンを変えられる |
| トークンを分離できる | プロファイルごとの`.env`にbotトークンを置けば、万一の漏洩も1体に閉じ込められる |
| チャンネルを整理できる | 増えたbotはDiscordの「カテゴリー」機能でエージェント専用チャンネルとして折りたためる |

ここでは1体のまま進める。複数エージェントを束ねる運用そのものは、別途まとまった話題になる。

## providerとmessengerの選び方

:::message
**迷ったら、頭脳はCodex・出入口はTelegram**でいい。Codexはコードと日本語が安定し、Telegramは設定が手軽で1メッセージの文字数上限も大きい(4096)。下の比較表は「なぜそれが最初の無難な選択か」「どんなときに足すか」を理解するためのものだ。完璧に選ぼうとせず、まず動かしてから足せばいい。
:::


### provider(頭脳)2系統のメリット

| メリット | 具体例 |
|---|---|
| 片方が落ちても他方で会話継続 | Codexで返答が遅いときにGrokに切り替え |
| モデル特性で使い分け | コード生成はCodex、リアルタイム情報はGrok |
| 料金/契約状態でフォールバック | Grokがレート制限ならCodexにフォールバック |

provider切り替えは2通り。

```bash
# 永続切り替え(再起動時もこのproviderで起動)
hermes config set model.provider xai-oauth

# 一時切り替え:Telegramで「providerをGrokにして」とメッセージするとconfig書き換え+リロード(承認確認あり)
```

出典:[hermes_cli/config.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/config.py)の`cmd_config_set`。

:::message
2系統にすると切り替えたくなるが、**常用するproviderは1本に決めて使い続ける**のが結局おトクだ。乗り換えるたびにAPI互換・認証・タイムアウトの調整で時間がかかるし、直接契約だと割引や接続性で得をしやすい。とはいえ上の2系統は無駄ではない——片方が落ちたときの保険として**予備の1本は残しておく**。「常用は1本、予備に1本」が落としどころだ。
:::

### messenger(出入口)の選び方

TelegramとDiscordの違いをHermes Agent観点で整理する。両者の機能はかなり重なるが、実装の出自が違う(出典:[gateway/platforms/](https://github.com/NousResearch/hermes-agent/tree/main/gateway/platforms)と[plugins/platforms/discord/](https://github.com/NousResearch/hermes-agent/tree/main/plugins/platforms/discord))。

| 軸 | Telegram | Discord |
|---|---|---|
| Hermes Agent側の位置付け | 本体組込み(gateway/platforms/) | プラグイン分離(plugins/platforms/) |
| 1メッセージ文字数上限 | 4096 | 2000 |
| メッセージ長超過時 | edit-then-continueで連続送信、最後の行を伸ばす | `_SPLIT_THRESHOLD = 1900`で分割、chunkごとに送信 |
| 添付ファイル上限 | 20MB(public API)/ 2GB(local mode) | Free 10MB / Nitro 500MB |
| reactionによる進捗UX | ✗ | ✅ (👀→✅/❌) |
| スラッシュコマンドnative UI | △ (`/cmd`は動くがオートコンプリート無し) | ✅ skillごとに登録(上限100) |
| ボイスチャンネル入室 | ✗ (音声ファイル送信→STT/TTS、非同期) | ✅ bot入室で同期会話 |
| role/channel単位の権限 | ✗ (user_id+group chat_id止まり) | ✅ role単位allowlist、channel単位prompt、user単位session分離 |
| プロキシ対応 | ✅ (`proxy_url`+`fallback_ips`) | ✗ 標準サポートなし |
| Privacy mode | bot privacy mode(group入退室で再認識必要) | MESSAGE CONTENT INTENT(OFFだとメッセージ本文が空で配信される罠) |

出典:[Hermes Agent公式messaging docs](https://hermes-agent.nousresearch.com/docs/user-guide/messaging) のcapability表。

### 用途別の使い分け

| 用途 | 推奨messenger | 理由 |
|---|---|---|
| ソロ運用+モバイル中心 | **Telegram** | 4096文字でスクロール無し、`pretty_tables`で表整形、軽量 |
| 複数人で共有(家族・小規模チーム) | **Discord** | role単位の承認フロー、channel単位の権限分離 |
| ボイスチャンネル常時接続で会話したい | **Discord** | ボイスチャンネル入室+RTP復号+無音検出が標準装備 |
| PC主環境で長時間運用 | **Discord** | PC clientのチャンネル切替・history scroll・reactionが快適 |
| 閉域網/プロキシ経由で動かす | **Telegram** | Discordはプロキシ標準非対応 |
| 大容量ファイル(50MB超)を頻繁に投げる | **Telegram local mode** | local mode構築で2GBまで対応 |
| 「とりあえず動かす」初期段階 | **Telegram** | DiscordはMESSAGE CONTENT INTENTの罠で初期つまずきが多い |

### 「Telegramだけで運用する」場合の許容範囲

**損なわれないもの**(7割以上の機能):

- ボイスモード(音声入出力)
- image/file入出力
- stream応答(タイピング中表示+message edit)
- skill自動ロード
- cron配信
- DM topic切替(Telegram Bot API 9.4 "Private Chat Topics"で1:1 DMでもスレッド分割可能)

**損なわれるもの**:

- 絵文字リアクションによる視覚的な進捗表示(代替:typing indicatorとmessage edit)
- スラッシュコマンドのnative補完UI(`/cmd`自体は動く)
- role/channel単位の権限設計(代替:user_id allowlist+group chat_id)
- 50MB超のファイル添付(代替:Telegram local mode構築)

つまり、**ソロ運用ならTelegramだけで必要十分**だ。Discord追加は「複数人共有」「voice同期会話」「PC主環境のUX最適化」のいずれかが必要になった時点で検討する位置付け。

### messengerは両方常時listenする設計

両方有効化していれば、Hermes Agentは**両messengerを同時並列でlisten**する。送信元のmessengerに対して返信するので、ユーザー側で「Telegramから送ったか、Discordから送ったか」を意識して選ぶだけだ。Hermes側の設定切り替えは不要。

Telegramの会話とDiscordの会話は別チャンネル扱いで履歴は混ざらない。例えばTelegramで「今日の予定教えて」と聞いて、続けてDiscordで「さっきの予定もう一度」と言っても通じない(別session扱い)。これは設計上の意図で、誤って別経路に情報を漏らさない安全装置でもある。

## 実行前に承認を挟む設定を確認する


第4回でコマンドの実行場所(backend)を`docker`にした。エージェントのコマンドは隔離されたDockerコンテナの中で実行される。**このコンテナ自体が安全境界**なので、コンテナ内では危険コマンドのチェックはスキップされる——つまり本シリーズの構成では、承認プロンプトは原則出ない。

公式ドキュメントはこう明記している。

> When running in a container backend (Docker...), dangerous command checks are skipped because the container is the security boundary.
> (コンテナの中で動かす場合、コンテナ自体が安全境界なので、危険コマンドのチェックはスキップされる)
> 出典:[Hermes Agent公式tipsガイド](https://hermes-agent.nousresearch.com/docs/guides/tips)

では`approvals.mode`は何のために設定するのか。**backendを`local`(ホスト上で直接実行)に戻したときの保険**だ。providerもmessengerも2系統に増え、Telegram・Discord・Codex・Grokとコマンドの流入経路が広がった以上、将来localに切り替える場面に備えて承認モードを`manual`で固定しておく。第4回のセットアップウィザードで選んだ値を明示確認する。

```bash
grep -A 5 -i approval ~/.hermes/config.yaml
```

期待される出力。

```yaml
approvals:
  mode: manual
  timeout: 60
  cron_mode: deny
  mcp_reload_confirm: true
  destructive_slash_confirm: true
```

子キーの意味は以下の通り。

| 子キー | 意味 |
|---|---|
| `mode: manual` | 承認確認を有効化(=旧名ask)。Docker既定では原則出ず、local時の保険 |
| `timeout: 60` | 承認待ち60秒(超過で却下扱い) |
| `cron_mode: deny` | cronから呼ばれた時は自動拒否(第7回で活きる安全弁) |
| `mcp_reload_confirm: true` | MCP再読込時にも承認確認 |
| `destructive_slash_confirm: true` | 破壊的スラッシュコマンドにも承認確認 |

![grep -A 5 -i approval ~/.hermes/config.yamlでapprovals.mode: manualが見えている](/images/hermes-vps/hermes-vps-05-approvals-mode-manual.png)

:::message
**v0.14系のキー名整理**:正規キーは`approvals:`(複数形、トップレベル)で、子キーに`mode:`を持つ。値は`manual`(=旧名ask、毎回確認)/`auto`(全自動)等。設定ファイルには別に`approval:`(単数形)というキーも存在するが、これは「承認判定用サブエージェントの設定」(別LLMに承認判定をさせる構成)で、承認モードそのものとは別の機能だ。本シリーズで触るのは`approvals.mode`のみ。
:::

もしmanual以外になっていたら、setupのagentセクションだけ再実行する。

```bash
hermes setup agent
```

### なぜmanualで固定するか

承認は普段出ないのに、なぜ`manual`にしておくのか。**安全を二段構えにするため**だ。

| 層 | 役割 |
|---|---|
| 第4回のコンテナ隔離(主) | エージェントのコマンドをコンテナ内に閉じ込め、ホスト(VPS本体・SSH鍵・トークン)に触れさせない。安全の本体はこれ |
| `approvals.mode=manual`(従) | backendを`local`に戻したときだけ効く保険。`auto`だと`rm -rf /`のような指示も無確認で通るので`manual`で固定しておく |

ただし**コンテナの中なら何をしても安全、ではない**。隔離が守るのはホストであって、コンテナの中ではエージェントがファイルの作成・上書き・削除を確認なしで行える。だから「誰がエージェントに指示できるか」をallowlist(本記事で設定した数値ユーザーID)で絞ることが、隔離と並ぶもう一本の防御線になる。第10回(自宅GPU連携)等でリモート操作が増えるほど、この**コンテナ隔離+allowlist**の二重の壁が効いてくる。

## まとめと第6回予告


第5回完了時点で以下が揃った。

- `hermes auth list`で`openai-codex`と`xai-oauth`の両方にcredentialが付いている
- `~/.hermes/config.yaml`の`approvals.mode`が`manual`
- Discord Developer Portalでapplication作成・botトークン取得済み
- 1Passwordアイテム`Hermes VPS - Discord bot token`の「認証情報」フィールドに実値格納済み
- `~/.hermes/.env`に`DISCORD_BOT_TOKEN`行が無い(平文をディスクに残さない方針継続)
- `hermes setup gateway`でDiscord有効化済み
- 自分のDiscordサーバーにbot招待済み(メンバー一覧にHermes VPS botがオフライン状態で表示)

第6回ではsystemdユーザーサービスとして登録して、VPS再起動時も自動で復帰する常駐運用に切り替える。`hermes gateway install`の公式コマンドが入ったので、手書きunitを書く必要はなくなった。常駐後、TelegramとDiscord両方で疎通+CodexとGrok両方の応答+承認モードmanualの動作を一気通貫で確認する。

## よくあるエラーと対処


| 症状 | 対処 |
|---|---|
| `hermes auth add xai-oauth`のブラウザURLが開けない | SSHトンネリング(`ssh -N -L 56121:127.0.0.1:56121`)未実行か終了済み |
| Grok OAuth後にHTTP 403が返る | SuperGrok層でサーバ側がHeavy-only相当に絞り込む既知Issue([#26847](https://github.com/NousResearch/hermes-agent/issues/26847))。回避策はxAI APIキー方式への切り替え:`hermes config set model.provider xai`+環境変数`XAI_API_KEY`。本シリーズはOAuth前提なのでX Premium+(=Heavy相当)契約での運用を推奨 |
| Discord botがサーバーで反応しない | (1) `Message Content Intent`がOFFのまま:Developer Portalで再ONにして`hermes gateway`再起動 (2) botがサーバーに招待されていない:OAuth2 URLジェネレーターで再招待 (3) token間違い:1Passwordの認証情報を上書きして`op run -- bash -c 'echo ${DISCORD_BOT_TOKEN:0:10}'`で実値展開確認 |
| Discord token reset直後にbotが応答しない | token resetすると旧tokenは即無効化される。新tokenを1Passwordに上書き保存して`op run`経由で再起動 |
| 承認モードがmanualにならない | `hermes setup agent`で再対話、または`config.yaml`の`approvals.mode`を直編集 |
| 状態確認が一括でやりたい | `hermes doctor`を実行。`Auth Providers`欄で`openai-codex` / `xai-oauth`の認証状態が一覧表示される |

## 公式ドキュメント引用元


| 項目 | 引用元 |
|---|---|
| Hermes Agentリポジトリ | [github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) |
| 本シリーズ参照tag | [release v2026.5.16](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.5.16) = v0.14.0(執筆時点でmain運用。最新は[v2026.5.29.2](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.5.29.2)=v0.15.2でNoneType修正済み、新規読者は最新tagで進めてよい) |
| OAuth実装(Codex/Grok) | [hermes_cli/auth.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/auth.py) |
| OAuth over SSH公式ガイド | [hermes-agent.nousresearch.com/docs/guides/oauth-over-ssh](https://hermes-agent.nousresearch.com/docs/guides/oauth-over-ssh) |
| セットアップウィザード構成 | [hermes_cli/setup.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/setup.py) |
| xAI x Hermes Agent公式連携(2026/5/15) | [x.ai/news/grok-hermes](https://x.ai/news/grok-hermes) |
| SuperGrok層HTTP 403既知Issue | [github.com/NousResearch/hermes-agent/issues/26847](https://github.com/NousResearch/hermes-agent/issues/26847) |
| Discord Developer Portal | [discord.com/developers/applications](https://discord.com/developers/applications) |
| Discord公式Getting Started | [discord.com/developers/docs/quick-start/getting-started](https://discord.com/developers/docs/quick-start/getting-started) |
| MESSAGE CONTENT INTENT(必須設定) | [Privileged Intents](https://discord.com/developers/docs/topics/gateway#privileged-intents) |
