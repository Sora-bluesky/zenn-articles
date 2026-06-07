---
title: "【第3回】Hermes Agentの秘密をファイルに残さない──1Passwordで参照だけ渡す"
emoji: "🔑"
type: "tech"
topics: ["1password", "vps", "hermes", "ubuntu", "secrets"]
published: false
---

APIキーやトークンを設定ファイルに直接書いて、なんとなく不安なまま動かしている——個人開発ではよくある状態だ。うっかり公開リポジトリに上げてキーを失効させた、という話も珍しくない。第2回までで通信の安全は固めたが、肝心の秘密情報は、まだ平文のテキストとしてサーバーに残っている。

第3回は、その平文を1台から消す。鍵をファイルに置かず、起動するときだけ受け渡す仕組みに切り替える。

## 目次

- [この回の到達点](#この回の到達点)
- [第2回までの到達点と第3回の差分](#第2回までの到達点と第3回の差分)
- [秘密情報が漏れる経路を整理する](#秘密情報が漏れる経路を整理する)
- [AIへの接続と秘密管理を分けて考える](#aiへの接続と秘密管理を分けて考える)
- [では何を1Passwordで管理するか](#では何を1passwordで管理するか)
- [第3回終了時点の構成図](#第3回終了時点の構成図)
- [あえてMCPを使わず参照だけ渡す理由](#あえてmcpを使わず参照だけ渡す理由)
- [事前準備](#事前準備)
- [1Passwordサービスアカウントを発行する](#1passwordサービスアカウントを発行する)
- [VPSにopコマンドを入れて認証する](#vpsにopコマンドを入れて認証する)
- [op runで起動時だけ秘密を渡す](#op-runで起動時だけ秘密を渡す)
- [平文ファイルが消えたか最終確認する](#平文ファイルが消えたか最終確認する)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [まとめと第4回予告](#まとめと第4回予告)
- [番外編:1Password Environments(beta)とは何か](#%E7%95%AA%E5%A4%96%E7%B7%A8%3A1password-environments(beta)%E3%81%A8%E3%81%AF%E4%BD%95%E3%81%8B)
- [公式ドキュメント引用元](#公式ドキュメント引用元)

:::message
このシリーズはHermes AgentをVPSに常駐させるまでの実録だ。順次公開中で、回数は内容に応じて増えていく。

- 第1回──Hermes AgentをVPSに常駐させる(契約からログインまで)
- 第2回──Hermes Agentの公開SSHをTailscaleで安全に閉じる
- **第3回**(本記事)──Hermes Agentの秘密情報を1Passwordで平文に出さない運用
- 第4回──Hermes Agent本体をVPSに入れる(インストールとDockerサンドボックス)
- 第5回──Hermes Agentに頭脳と出入口をもう1系統足す(Grok OAuthとDiscord+承認モードの確認)
- 第6回──Hermes Agentをsystemdで24時間常駐させる
- 第7回──公式アプリ「Hermes Desktop」でマウス操作する
- 第8回──Web Dashboardで設定をブラウザ管理する
- 第9回──Hermes Agent Cronで毎朝の定型を任せる
- 第10回──Hermes Agent Skillsに手順を覚えさせる
- 第11回──Web/X検索の使い分け(SearXNG+Firecrawl+X Search)
- 第12回──家の余ったPCをLinux常駐GPUサーバーにする(VPSの手足)
:::

## この回の到達点

第2回でVPSの公開22番を閉じ、Tailscale経由でしかSSHログインできない状態にした。攻撃面は世界中のIPから「同じTailnet内の端末だけ」に絞られた。

第3回では、その先のレイヤー=**Hermes Agentが動くときに必要なbotトークン等の秘密情報をどこに置くか**を決める。やり方を間違えると、せっかく外からの侵入を絞ったのに、内側で平文ファイルから秘密が漏れる。

この回のゴールは「Hermesに秘密を渡す唯一の経路をop CLI(1Passwordのコマンドラインツール)に絞る」こと。

実機で打ちながら書いたメモなので、きれいな手順書ではない。詰まった場所も含めて読んでもらいたい。

## 第2回までの到達点と第3回の差分

| 項目 | 第2回完了時(現状) | 第3回完了後(ゴール) |
|---|---|---|
| VPSへのログイン経路 | Tailscale経由のSSHのみ | 変わらず |
| 1Password保管庫 | Hermes-Prod作成済(adminパスワード・Tailscale auth等) | サービスアカウント・Telegram/Discord botトークン用アイテム追加 |
| Hermesに渡す秘密 | Hermes本体が未導入なので渡していない | `op run`で`op://`参照を経由して渡す経路を構築 |
| MCPを使うか | 議論なし | 採用しない(理由は本文で) |

## 秘密情報が漏れる経路を整理する

「APIキーを`.env`に書く」は世界中で雑に行われているが、Hermesのような自律エージェントを24時間動かす運用ではいくつか別の漏れ方が存在する。

| 置き方 | 漏れ方 |
|---|---|
| `.env`を平文で`~/.hermes`等に置く | 誰かがVPSに侵入した瞬間、ファイル1個でbotトークン総取り |
| systemdの`EnvironmentFile`に平文 | 権限管理を間違えると同上。`systemctl show`でも環境変数が見える |
| ターミナルで`export TELEGRAM_BOT_TOKEN=...` | シェル履歴(`~/.bash_history`)とプロセス一覧(`ps eauxww`)に残る |
| **`op run --env-file=参照ファイル`** | 参照だけ書く。実値はopが実行時に注入。ファイルには平文がない |

第3回で目指すのは最後の構成だ。実値は1Password側に置いたまま、VPS側には「`op://`参照」だけを置く。

## AIへの接続と秘密管理を分けて考える

ひとつ最初に整理しておきたいことがある。**Codex(gpt-5.x)もGrok(grok-4.x)も、Hermesから接続するときの認証はOAuth方式**だ。

Hermesは内部で`hermes auth add openai-codex`や`hermes auth add xai-oauth`を実行すると、ブラウザでデバイスコードフロー(端末側に表示されるコードをブラウザで承認する仕組み)を実行する。取得したアクセストークンとリフレッシュトークンはHermes本体が`~/.hermes/auth.json`に保存し、有効期限が切れる前に自動で更新する。

つまり**OpenAI API key・xAI API keyを1Password管理する必要はない**。Hermes側の`auth.json`を上書きで壊さない限り、token rotationは自動。1Password運用の対象から外す。

これは公式リポジトリのドキュメント(`website/docs/guides/xai-grok-oauth.md`等)を読んで確定した方針で、本シリーズではこの線を守る。API keyを1Passwordに保管するのはOAuthが使えない代替経路のときだけ。

## では何を1Passwordで管理するか

第3回時点で1Password管理対象にするのは、Codex/Grok以外の連携=メッセージング系のbotトークンだ。

| 対象 | 環境変数名 | 第3回時点の値 | 実値の出どころ |
|---|---|---|---|
| Telegram botトークン | `TELEGRAM_BOT_TOKEN` | 実値あり(第3回で発行) | BotFather |
| Discord botトークン | `DISCORD_BOT_TOKEN` | 空(参照経路だけ) | 第5回でDiscord Developer Portalから発行 |
| Hermes Service Account token | (op自身の認証用) | 実値あり | 第3回の本文で発行 |

Telegramは第3回で実際にbotを発行して値を入れる。Discordは第5回で発行するので、第3回ではアイテムだけ作って中身は空にしておく(参照経路は事前に組んでおく)。

## 第3回終了時点の構成図

完成後の構成はこうなる。

![第3回終了時点の構成図(1Password Service Accountとop runでSecrets管理)](/images/hermes-vps/hermes-vps-03-architecture.png)

ファイル単位の関係性は次のとおり。

![1Passwordクラウド側とVPS側のファイル構成図](/images/hermes-vps/hermes-vps-03-files.png)

テキスト表記でも見ておく(コピペ参照用)。

```
┌──────────────────────────────────────────────────────────────┐
│   1Password.com                                              │
│   ├── Hermes-Prod 保管庫                                     │
│   │   ├── アイテム:Telegram bot token(認証情報フィールド)    │
│   │   ├── アイテム:Discord bot token(将来用、空)             │
│   │   └── アイテム:Hermes Service Account token              │
│   └── サービスアカウント(scope: Hermes-Prod read-only)       │
└──────────────────┬───────────────────────────────────────────┘
                   │ HTTPS + OP_SERVICE_ACCOUNT_TOKEN
                   ▼
┌──────────────────────────────────────────────────────────────┐
│   VPS(Ubuntu 26.04 / admin)                                  │
│   ├── /usr/bin/op (1Password CLI)                            │
│   ├── ~/.hermes/                                             │
│   │   ├── service-account.env(SAトークン本体、chmod 600)     │
│   │   ├── secrets.env(op://参照のみ、平文値なし)             │
│   │   └── auth.json(Codex/Grok OAuth、Hermes自動管理)        │
│   └── ~/.config/systemd/user/hermes-gateway.service(第4回)   │
│       └── ExecStart=op run --env-file=... --                 │
│              hermes gateway run                              │
└──────────────────────────────────────────────────────────────┘
```

ポイントは、VPS側の`secrets.env`には実値が1つも書かれないこと。中身は`TELEGRAM_BOT_TOKEN=op://Hermes-Prod/...`のような**1Passwordへの参照URL**だけ。`op run`がコマンド実行の瞬間にこの参照を解決し、子プロセスに環境変数として注入する。ディスクには平文が出ない。

## あえてMCPを使わず参照だけ渡す理由

1Password社は2025年に**MCP(Model Context Protocol)サーバー**を公式提供している。Claude DesktopやChatGPT等の対応AIから、自然言語で「`Hermes VPS - Telegram bot token`の値を教えて」と聞けば、保管庫から値を引いて返してくれる。便利。

しかし**本シリーズではHermesに渡す秘密の経路としてMCPを採用しない**。理由は明確で、MCPを通すと秘密値が**AIのコンテキスト・ログ・キャッシュに載る**経路ができてしまうからだ。

Hermesは24時間動く常駐エージェントで、起動の度にコンテキストが復元される性質を持つ。さらにreflectionで会話履歴をスキルファイルに書き出す機能もある。MCPで秘密を引いた瞬間、それがチャット履歴・思考ログ・スキルファイル・更には外部LLMへの送信に含まれる確率がゼロではない。

「AIに秘密を見せない」という線を引くために、Hermesへの秘密注入は**op CLI(`op run`/`op read`)に限定**する。1Password本体のMCPは便利だが、Hermesのプロセスには触らせない。これは意識的な制約だ。

## 事前準備

### 1Passwordの契約と`Hermes-Prod`保管庫を用意する

このシリーズで秘密情報を入れる箱が`Hermes-Prod`保管庫だ。第1回・第2回でadminパスワードやTailscaleの認証情報を入れる先として登場したが、まだ作っていない人向けに作成手順を書いておく。

1. [1password.com](https://1password.com)で個人またはファミリープランを契約する(無料プランには保管庫の追加機能がない)
2. 同じページから1Passwordデスクトップアプリ(Windows/Mac)をダウンロードして、契約したアカウントでサインインする
3. アプリ左下の保管庫一覧の横にある「**+**」(新しい保管庫を作成)をクリックし、名前に`Hermes-Prod`と入れて作成する

保管庫(英語UIではVault)は「アイテムをまとめて入れる引き出し」のこと。Hermes関連の秘密はすべてこの`Hermes-Prod`に集める。

### 手元PCに1Password CLI(op)をインストールする

WindowsならPowerShellで:

```powershell
winget install AgileBits.1Password.CLI
op --version
```

`op --version`で`2.x`系のバージョン(2026年5月時点は`2.34.0`)が表示されればOK。

![winget installで1Password CLIをインストール](/images/hermes-vps/hermes-vps-03-winget-install.png)

![op --versionで2.34.0が表示される](/images/hermes-vps/hermes-vps-03-op-version.png)

### 1Passwordデスクトップアプリと連携する

`op`コマンドが1Passwordアプリと連携するように設定する。1Passwordアプリの**設定→開発者**を開き、「1Password CLIと連携」をオンにする。

![1Password設定の開発者画面で「1Password CLIと連携」をオン](/images/hermes-vps/hermes-vps-03-cli-integration-toggle.png)

初めて`op vault list`を実行すると、1Passwordアプリから認証許可ダイアログが出る。**認証**(Touch ID/Windows Hello/マスターパスワード)で許可する。

![op vault list実行時の1Password認証許可ダイアログ](/images/hermes-vps/hermes-vps-03-cli-auth-dialog.png)

認証が通れば自分のすべての保管庫が一覧で表示される。

![op vault listで自分の保管庫一覧が表示される](/images/hermes-vps/hermes-vps-03-op-vault-list-host.png)

ここまでは「サービスアカウントを使わない、自分自身のアカウントでのCLI操作」だ。サービスアカウントはこのあと作る。

### BotFatherでHermes-VPS用Telegram botを発行する

Telegramのデスクトップ/モバイルアプリで[@BotFather](https://t.me/BotFather)を開く。`/newbot`コマンドを送信して、以下の順で質問に答える。

| 質問 | 回答例 |
|---|---|
| bot表示名(後で変更可能) | `Hermes VPS` |
| bot username(`_bot`で終わる必要があり、グローバル一意) | `hermes_vps_xxxxxx_bot` |

usernameは「`hermes_vps_`+自分の識別子+`_bot`」のような形式が一意性を確保しやすい。私の場合は自分のXハンドルを入れて衝突を回避した。

成功するとBotFatherから`Done! Congratulations on your new bot.`のメッセージが返り、続けて`Use this token to access the HTTP API:`の下に`<bot_id>:<auth_token>`形式のトークンが表示される。

![BotFatherがbot発行成功とトークンを返す](/images/hermes-vps/hermes-vps-03-botfather-new-bot.png)

:::message alert
このトークンは**漏れたら誰でもbotを操作できる**。今すぐ次のステップで1Passwordに移動して、BotFatherチャットから当該メッセージを削除する。
:::

:::message
既にWSL+Docker等の別環境でHermes Agentを動かしていてTelegram botを持っていても、**新しくもう1つ発行する**のが安全。同じトークンを複数環境からポーリング(Telegram APIへ定期的にメッセージ取得を問い合わせる方式)すると、Telegram側で`409 Conflict`(衝突)エラーが返り、どちらも安定動作しなくなる。
:::

### Hermes-Prod保管庫にアイテムを揃える

1Passwordのデスクトップアプリで`Hermes-Prod`保管庫を開き、新規アイテムを作る。

**新規アイテム**ボタン→種類選択ダイアログで「**詳細を表示する**」をクリックすると、「**API認証情報**」が現れる。これを選ぶ。

![新規アイテム種類選択でAPI認証情報を選ぶ](/images/hermes-vps/hermes-vps-03-new-item-api-credential.png)

API認証情報テンプレートのフィールド構成は「ユーザ名・認証情報・種類・ファイル名・有効開始年・有効期限・ホスト名・メモ」。今回主に使うのは**認証情報**フィールドとメモだけ。

#### Telegram botトークンアイテム(実値投入)

| フィールド | 値 |
|---|---|
| タイトル | `Hermes VPS - Telegram bot token` |
| 認証情報 | BotFatherから受け取った`<bot_id>:<auth_token>`を貼り付け |
| メモ | `bot username: <自分のusername> / 発行日: 2026/05/27 / VPS本番用` |

![1Password新規アイテム作成画面でTelegram botトークンを入力](/images/hermes-vps/hermes-vps-03-1pw-telegram-item-input.png)

保存できたら、BotFatherチャットの「Use this token to access the HTTP API:」を含むメッセージを削除する。1Passwordに転記したので、もう履歴に残しておく必要はない。

#### Discord botトークンアイテム(空、第5回用)

| フィールド | 値 |
|---|---|
| タイトル | `Hermes VPS - Discord bot token` |
| 認証情報 | 空のまま |
| メモ | `実値は第5回でDiscord Developer Portalから発行予定` |

第3回時点では空のアイテムだけ作っておく。`op`は参照先のフィールドが空でもエラーにはせず、空文字列を環境変数に注入する仕様なので、後で実値を埋めれば`secrets.env`を変更せずに展開先が変わる。

![Hermes-Prod保管庫のアイテム一覧](/images/hermes-vps/hermes-vps-03-vault-items-overview.png)

第1回・第2回で作ったアイテムも含め、`Hermes VPS - {用途}`命名規則で揃える。1Password検索で並んで見つかる。

## 1Passwordサービスアカウントを発行する

ここからが第3回の中心だ。VPSが1Passwordに接続するときの「ロボットアカウント」を作る。スコープを`Hermes-Prod`保管庫のread-onlyだけに絞ることで、VPSがハックされてもサービスアカウントトークンが盗まれても、被害が`Hermes-Prod`の読み取りだけに限定される。

ブラウザで以下のURLを開く(1Passwordへのログインが必要)。

```
https://start.1password.com/developer-tools/infrastructure-secrets/serviceaccount/?source=dev-portal
```

「サービスアカウントを作成」をクリックすると、4ステップのウィザードが始まる。

### サービスアカウント名を入力する(ウィザード1画面目)

「サービスアカウント名」に`hermes-vps-prod`を入力して「次へ」。

![ウィザード1画面目:サービスアカウント名にhermes-vps-prodを入力](/images/hermes-vps/hermes-vps-03-sa-wizard-step1-setup.png)

### 保管庫スコープを絞る(2画面目)

「保管庫を選択」リストから`Hermes-Prod`にチェックを入れる。右端のギアアイコンをクリックして**パーミッション設定**を開き、「**アイテムを読み取る**」だけON、「アイテムを書き込む」「アイテムの共有」はOFF。

![2画面目:Hermes-Prodにチェック+アイテムを読み取るのみON](/images/hermes-vps/hermes-vps-03-sa-wizard-step2-vault.png)

「新規保管庫の作成を許可する」もOFFのまま。最小権限の原則で、VPSが触れるのは`Hermes-Prod`の中身を読むことだけ。

### 環境設定はスキップする(3画面目)

「環境を選択する」が出るが、これは1Passwordの新機能「Environments」(beta)を使う場合の設定。本編では使わないので**何も選択せず**「アカウントを作成」をクリック。

![3画面目:環境は選択せずアカウントを作成](/images/hermes-vps/hermes-vps-03-sa-wizard-step3-env.png)

Environmentsの詳細は本記事末尾の番外編で扱う。

### サービスアカウントトークンを取り出す(4画面目)

ここで`ops_eyJ...`で始まるトークンが表示される。**このトークンは一度しか表示されない**。ページを離れた瞬間に1Password側でも再表示できなくなる。

![4画面目:トークンが表示される(本物の値はマスク)](/images/hermes-vps/hermes-vps-03-sa-wizard-step4-token.png)

:::message alert
画面右側に「**1Passwordに保存**」ボタンがあるが、これは**クリックしない**。これを押すとデフォルト保管庫(プライベート等)に「Service Account token」名で自動保存される。Hermes関連を全部`Hermes-Prod`保管庫に集めたいシリーズの命名規則から外れる。**コピーアイコン**(📋)でクリップボードに取得する。
:::

コピーしたら、4画面目を開いたまま、別タブで1Passwordデスクトップアプリを開いて手動でアイテムを作る。

| フィールド | 値 |
|---|---|
| タイトル | `Hermes VPS - Service Account token (hermes-vps-prod)` |
| 種類 | API認証情報 |
| 認証情報 | コピーした`ops_eyJ...`を貼り付け |
| 有効開始年 | `2026/05/27`(発行日) |
| 有効期限 | `2026/08/25`(90日後、1Passwordが自動で30日前にアラート設定) |
| メモ | `scope: Hermes-Prod read-only / 用途: VPS本番のop CLI認証` |

![1Passwordにサービスアカウントトークンを保存(値はマスク)](/images/hermes-vps/hermes-vps-03-sa-stored-in-1pw.png)

保存できたら、4画面目のブラウザタブを閉じてOK。トークンはこれで1Password側にだけ存在する。

### 手元PCで動作確認(VPS転送前)

VPSに転送する前に、発行したトークンが正しく動くかを手元PCで確認する。

```powershell
$env:OP_SERVICE_ACCOUNT_TOKEN = "ops_eyJ..."
op vault list
op item list --vault Hermes-Prod
Remove-Item env:OP_SERVICE_ACCOUNT_TOKEN
```

`op vault list`が`Hermes-Prod`のみを返すことを確認する(他の保管庫が見えたらスコープ設定が間違っている)。

![手元PCでop vault listがHermes-Prodだけを返す](/images/hermes-vps/hermes-vps-03-local-op-test.png)

確認できたら`Remove-Item`で環境変数を消す。PowerShellを閉じるだけでも消える(`$env:VAR`はそのPowerShellプロセス内だけ有効)。

## VPSにopコマンドを入れて認証する

### Tailscale経由でVPSにadminログイン

第2回で確立した経路を使う。手元PCのターミナル(WindowsならPowerShell、Macならターミナル)で:

```
ssh -i ~/.ssh/hermes_vps_ed25519 admin@<VPSのTailscale IP>
```

Tailscale IPがわからなければ[login.tailscale.com/admin/machines](https://login.tailscale.com/admin/machines)で`hermes-vps`の`100.x.x.x`形式のIPを確認する。MagicDNSが有効なら`admin@hermes-vps`でも接続可能。

### opのインストール

VPSのadminセッションで以下を順に実行する。1Password公式のDebian/Ubuntuリポジトリを追加してから`apt install`するパターンだ。

この6行は1Password公式が指定している署名検証(配布されたパッケージが本物かを確かめる手続き)の準備で、中身を1つずつ理解する必要はない。上から順に1行ずつ貼り付け、それぞれエラーが出ずにコマンド待ちの状態に戻ることだけ確認すればよい。何をしている行なのかはこの下の表で軽く触れる。

```bash
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' | sudo tee /etc/apt/sources.list.d/1password.list

sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol

sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
curl -sS https://downloads.1password.com/linux/keys/1password.asc | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

sudo apt update && sudo apt install -y 1password-cli
op --version
```

各ブロックの意味は以下。

| 部分 | 意味 |
|---|---|
| 1Passwordの公開鍵を`gpg --dearmor`で鍵束ファイル化 | これからインストールするパッケージが本物の1Password署名で配布されたか検証する材料 |
| `tee /etc/apt/sources.list.d/1password.list` | aptに「1Passwordの公式リポジトリも見に行け」と教える |
| debsig設定の2セット | 署名検証ポリシーを`dpkg`レベルでも有効化 |
| `apt install -y 1password-cli` | 本体インストール |
| `op --version` | 2.x系が表示されればOK |

![VPSでapt install -y 1password-cliが成功してop --versionが2.34.0を返す](/images/hermes-vps/hermes-vps-03-vps-op-install.png)

sudoは初回だけパスワードを聞かれる(adminのログインパスワード=1Passwordの`Hermes VPS - admin`)。一度認証すると約5分間はキャッシュされ、続くsudoコマンドではパスワード再入力なしで通る。

### サービスアカウントトークンの置き場と権限

Hermesは`~/.hermes/`配下に設定ファイル群を置く(第4回でHermes本体をインストールしたあと正式に使う)。サービスアカウントトークンもこのディレクトリに入れる。

```bash
mkdir -p ~/.hermes
nano ~/.hermes/service-account.env
```

`nano`が開いたら以下の1行を貼り付ける。`ops_eyJ...`は1Passwordの`Hermes VPS - Service Account token (hermes-vps-prod)`の認証情報フィールドから手動でコピーしたもの。

```
OP_SERVICE_ACCOUNT_TOKEN=ops_eyJ...
```

| キー操作 | 役割 |
|---|---|
| `Ctrl+O` → `Enter` | 保存(WriteOut) |
| `Ctrl+X` | nano終了 |

保存できたら権限を絞る。

```bash
chmod 600 ~/.hermes/service-account.env
ls -la ~/.hermes/
```

`ls -la`の出力で`-rw-------`(=600、admin本人だけが読み書き)になっていることを確認する。

![service-account.envが-rw-------(600)で所有者adminになっている](/images/hermes-vps/hermes-vps-03-service-account-env.png)

加えて、`~/.hermes/`ディレクトリ自体も700に絞る(中の`service-account.env`は600で守られているが、`~/.hermes/`がデフォルト775のままだと他ユーザーにディレクトリ一覧を見られる)。

```bash
chmod 700 ~/.hermes/
ls -la ~/ | grep .hermes
```

`drwx------`(=700)になっていれば、admin本人以外はディレクトリそのものを開けない。

![~/.hermesがdrwx------(700)になる](/images/hermes-vps/hermes-vps-03-hermes-dir-700.png)

:::message
**Linux権限の読み方**(初学者向け)

`ls -la`の出力左端の`-rw-------`や`drwx------`は10文字でファイル/ディレクトリの権限を表す。

| 位置 | 意味 |
|---|---|
| 1文字目 | 種別(`-`=ファイル、`d`=ディレクトリ、`l`=シンボリックリンク) |
| 2-4文字目 | 所有者の権限(r=読、w=書、x=実行) |
| 5-7文字目 | 同じグループのメンバーの権限 |
| 8-10文字目 | その他(他人)の権限 |

数字表記はr=4、w=2、x=1の合計を3桁並べたもの。

| 数字 | 文字表記 | 用途 |
|---|---|---|
| 600 | `-rw-------` | 秘密情報を含むファイル(`service-account.env`等) |
| 700 | `drwx------` | 秘密情報を含むディレクトリ(`~/.hermes/`、`~/.ssh/`等) |
| 644 | `-rw-r--r--` | 公開して問題ないファイル(参照のみの`secrets.env`等) |
| 755 | `drwxr-xr-x` | 一般的なディレクトリのデフォルト |

第1回で`~/.ssh/`を`700`、`authorized_keys`を`600`にしたのと同じ考え方。
:::

### opの動作確認(VPS上)

サービスアカウントトークンを使って、VPSからop CLIが動くかを確認する。ここで注意したいのが、環境変数(コマンドに値を渡すための入れ物)を一時的にセットする書き方が、手元PC(Windows)とVPS(Linux)で違うことだ。

| どこで打つか | 一時セットの書き方 | 削除の書き方 |
|---|---|---|
| 手元PC(Windows/PowerShell) | `$env:OP_SERVICE_ACCOUNT_TOKEN = "..."` | `Remove-Item env:OP_SERVICE_ACCOUNT_TOKEN` |
| VPS内(Linux/bash) | `set -a` → `source ...` → `set +a` | `unset OP_SERVICE_ACCOUNT_TOKEN` |

この先のコードブロックには【手元PC】【VPS内】のラベルを付けてある。打ち込む場所を間違えると構文エラーになるので、ラベルとプロンプト(行頭の`$`がWindows、`admin@hermes-vps:~$`等がVPS)を見て確認する。

```bash
set -a
source ~/.hermes/service-account.env
set +a

op vault list
op item list --vault Hermes-Prod

unset OP_SERVICE_ACCOUNT_TOKEN
```

| コマンド | 役割 |
|---|---|
| `set -a` | これ以降に作る変数を自動エクスポート(子プロセスに継承)するモードへ |
| `source ~/.hermes/service-account.env` | ファイル内の`OP_SERVICE_ACCOUNT_TOKEN=...`をシェル変数+環境変数として読み込み |
| `set +a` | 自動エクスポートモードを解除 |
| `op vault list` | アクセス可能なvaultを表示。`Hermes-Prod`のみ表示=スコープ設定OKの証拠 |
| `op item list --vault Hermes-Prod` | vault内の全アイテム一覧 |
| `unset OP_SERVICE_ACCOUNT_TOKEN` | シェルから環境変数を削除 |

:::message
最後の`unset`は「op CLIの認証が必要な瞬間だけ環境変数を持たせる」方針に基づく。テスト用にシェルでトークンを読み込んだ後、そのまま放置すると別コマンドの実行ログや子プロセスにトークンが混入する経路ができる。本番運用ではsystemdユニットの`EnvironmentFile`が必要なときだけ読み込むので、手動シェルでの常駐は不要。
:::

`op vault list`が`Hermes-Prod`のみを返し、`op item list`がHermes-Prodの全アイテムを返せば、サービスアカウント経由のVPSからの参照が成立した証拠。

![VPSで`op vault list`がHermes-Prodのみ、`op item list`が7アイテムを返す(IDマスク済)](/images/hermes-vps/hermes-vps-03-vps-op-test.png)

## op runで起動時だけ秘密を渡す

### そもそも`op run`とは何か

`op run`は1Password CLIに同梱されたサブコマンドで、ざっくり言うと「`.env`ファイルの中の`op://`参照を、実値に置き換えながら別のコマンドを起動するラッパー」だ。

普通のシェルでは:

```bash
# .env を export してから起動
export TELEGRAM_BOT_TOKEN=<実値>
export DISCORD_BOT_TOKEN=<実値>
hermes gateway run
```

このやり方だと`.env`に実値を書く必要があり、ディスクとシェル履歴に平文が残る。

`op run`を挟むとこうなる:

```bash
op run --env-file=$HOME/.hermes/secrets.env -- hermes gateway run
```

挙動を分解すると:

| 段階 | opがやること |
|---|---|
| 1.読み込み | `--env-file=`で指定したファイルを開き、`op://...`形式の値を探す |
| 2.解決 | 各`op://`参照を1Passwordに問い合わせて実値に置き換える(認証はサービスアカウントトークン) |
| 3.実行 | `--`の後ろのコマンド(`hermes gateway run`)を起動し、解決済みの環境変数を子プロセスにだけ渡す |
| 4.終了後 | 子プロセスが終わったら、実値はメモリから消える。ディスクには何も書き出されない |

ポイントは「実値が**メモリ上の子プロセスにだけ存在する**」こと。`secrets.env`(参照だけ)はディスクに残るが、平文値はディスクに書かれない。シェル履歴にも残らない(コマンドラインに値が並ばないので)。

これがHermesに秘密を渡す経路として`op run`を採用する技術的な根拠だ。

### secrets.envの設計

ここが`op run`の中核だ。**実値ではなく`op://`参照だけ**を書く。opがコマンド実行時に参照を解決して環境変数として子プロセスに注入する。

```bash
nano ~/.hermes/secrets.env
```

中身は以下の通り(平文値は1個も書かない)。

```
# Hermes Agent secrets (resolved by op run at execution time)
TELEGRAM_BOT_TOKEN=op://Hermes-Prod/Hermes VPS - Telegram bot token/credential
DISCORD_BOT_TOKEN=op://Hermes-Prod/Hermes VPS - Discord bot token/credential
```

`op://`参照のフォーマットは`op://<保管庫名>/<アイテム名>/<フィールド名>`。フィールド名は1Passwordの**内部識別子**を使うので、日本語UIで「認証情報」と表示されているフィールドは内部名`credential`になる。

主要フィールドの日本語UI⇔内部識別子の対応は以下。

| 日本語UI | 内部識別子 |
|---|---|
| 認証情報 | `credential` |
| ユーザ名 | `username` |
| ホスト名 | `hostname` |
| メモ | `notesPlain` |

自分で確認したい場合は、サービスアカウント認証済みの状態で以下を実行するとJSONで全フィールドが見える。

```bash
op item get "Hermes VPS - Telegram bot token" --vault Hermes-Prod --format json
```

:::message
`op://`参照のアイテム名・フィールド名に**スペースやハイフンを含めてもよい**。opは`/`区切りで分解するだけで、URLエンコード(`%20`等の置き換え)は不要。`op://Hermes-Prod/Hermes VPS - Telegram bot token/credential`がそのまま動く。
:::

権限は644でOK。

```bash
chmod 644 ~/.hermes/secrets.env
cat ~/.hermes/secrets.env
```

![secrets.envの中身がop://参照だけになっている](/images/hermes-vps/hermes-vps-03-secrets-env.png)

:::message
中身は`op://`参照だけで実値が含まれないため、admin以外が読めても直接の漏洩にならない。実値の解決にはサービスアカウントトークン(=`service-account.env`、こちらは600で守っている)が必要。`secrets.env`単体は無害。
:::

### op runで参照解決テスト

Telegramは実値を入れたので展開後に値が見えるはず、Discordはまだ空なので`(empty)`で返るはず。両方の挙動を1回のコマンドで確認できる。

```bash
set -a
source ~/.hermes/service-account.env
set +a

op run --env-file=$HOME/.hermes/secrets.env -- bash -c 'echo "TELEGRAM=${TELEGRAM_BOT_TOKEN:0:10}..."; echo "DISCORD=${DISCORD_BOT_TOKEN:-(empty)}"'

unset OP_SERVICE_ACCOUNT_TOKEN
```

bashの記法:

| 記法 | 意味 |
|---|---|
| `${VAR:0:10}` | 変数VARの先頭10文字だけ取り出す |
| `${VAR:-(empty)}` | VARが未定義/空のときに`(empty)`を表示 |

期待される出力はこうなる。

```
TELEGRAM=1234567890:...
DISCORD=(empty)
```

![op runでTELEGRAMの先頭10文字が展開、DISCORDが(empty)で返る(値マスク済)](/images/hermes-vps/hermes-vps-03-op-run-test.png)

これで「`op://`参照が`op run`に展開されて子プロセスに渡る」経路が完成した。第5回でDiscord botトークンの実値を1Passwordに入れた瞬間に、同じ`secrets.env`のままDiscordの値も流れるようになる(`secrets.env`は変更不要)。

### `~`と`$HOME`の違い

ひとつ罠を踏んだので書いておく。`op run --env-file=~/.hermes/secrets.env`のように`~`を使うと、

```
[ERROR] open ~/.hermes/secrets.env: no such file or directory
```

と失敗する。bashは行頭や引数単独の`~`を`$HOME`に展開するが、`--option=~/path`のように`=`の右側に来た場合は展開しないことがある。さらにopコマンド本体はGoで書かれていて`~`記号を理解しない。

解決はシェル変数`$HOME`を使うこと。`=`の右側でも確実に展開され、最終的にopには`/home/admin/.hermes/secrets.env`という絶対パスが渡る。

### systemdユニット(第4回への設計案)

第3回ではユニットファイルは作らない(`ExecStart`の対象となるHermes本体がまだ未インストール)。第4回でHermes本体導入後に正式作成する設計を先に置いておく。

```ini
# ~/.config/systemd/user/hermes-gateway.service(設計案、第4回で作成)
[Unit]
Description=Hermes Agent Gateway
After=network-online.target

[Service]
Type=simple
EnvironmentFile=%h/.hermes/service-account.env
ExecStart=/usr/bin/op run --env-file=%h/.hermes/secrets.env -- hermes gateway run
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=default.target
```

ポイント:

| 部分 | 意味 |
|---|---|
| `EnvironmentFile=%h/.hermes/service-account.env` | サービスアカウントトークンをsystemdが読み込み、子プロセスの環境変数にセット |
| `ExecStart=/usr/bin/op run --env-file=%h/.hermes/secrets.env -- ...` | opが`secrets.env`の`op://`参照を解決して、子プロセス(Hermes本体)に環境変数として注入 |
| `%h` | systemdの記法で`$HOME`相当 |
| ユーザーサービス(`~/.config/systemd/user/`) | rootではなくadminユーザーの権限で動く |

Hermes本体は`python-dotenv`で`.env`を読む実装(systemdの`EnvironmentFile`を使わない)なので、`op run`でラップする二段構成になる。

:::message
冒頭の漏れ方一覧で「systemdの`EnvironmentFile`に平文」を危険例として挙げた。ここで`EnvironmentFile=%h/.hermes/service-account.env`を使うことに矛盾を感じるかもしれないが、ここに入っているのはbotトークンではなく**スコープが`Hermes-Prod` read-onlyに絞られたサービスアカウントトークンだけ**。万が一`systemctl show`経由で漏れても、被害は`Hermes-Prod`保管庫の読み取りに限定される(書き込みも他Vaultへのアクセスもできない)。本番のbotトークンは`op run`が子プロセスにだけ渡す経路を守る。
:::

## 平文ファイルが消えたか最終確認する

第3回の完了条件は以下。

- [ ] Hermes-Prod保管庫にTelegram(実値)/Discord(空)/Service Account token(実値)の3アイテムが揃っている
- [ ] サービスアカウントのスコープが`Hermes-Prod` read-onlyのみ
- [ ] サービスアカウントトークンが1Passwordの新規アイテムに保管されている
- [ ] VPSの`~/.hermes/service-account.env`が`admin:admin/600`
- [ ] VPSの`~/.hermes/`ディレクトリが`admin:admin/700`
- [ ] VPSの`~/.hermes/secrets.env`が`admin:admin/644`で中身は`op://`参照のみ
- [ ] `op vault list`がVPSで成功し、`Hermes-Prod`のみが表示される
- [ ] `op run --env-file=$HOME/.hermes/secrets.env -- ...`でTelegram実値が展開、Discordは空で返る
- [ ] ターミナル履歴に生値が残っていない(`history`と`~/.bash_history`両方確認)
- [ ] BotFatherチャットからtoken表示メッセージを削除済み

## よくあるエラーと対処

実機で踏んだ落とし穴を残しておく。

### 1. API認証情報テンプレートは新規アイテム画面の最初には出ない

1Passwordの新規アイテム選択ダイアログには「ログイン/セキュアノート/クレジットカード/個人情報/パスワード/ドキュメント」の6種類しか最初は表示されない。「**詳細を表示する**」リンクを押すと、SSHキー・API認証情報・サーバー・データベース等が現れる。最初これを見落として「APIクレデンシャルがない」と思い込んで5分悩んだ。

### 2. `--env-file=~/...`の`~`は展開されない

前述。bashの`~`展開はオプションの`=`の右側では効かないことがあるうえ、Go製のopコマンドは`~`記号そのものを理解しない。`$HOME`を使う。

### 3. サービスアカウントトークンは一度しか表示されない

ウィザード最終画面を閉じてしまったら、同じトークンは二度と表示されない。サービスアカウントごと削除して作り直す必要がある。最終画面を開いたまま、別タブで1Passwordアプリを開いて手動アイテム作成→コピー貼り付け→保存、を一気にやる。

### 4. 「1Passwordに保存」ボタンを押すとデフォルト保管庫に入る

ウィザード最終画面の右側の「1Passwordに保存」ボタンは便利だが、押すとデフォルト保管庫(プライベート等)に「Service Account token」名で自動保存される。`Hermes-Prod`保管庫の外に出てしまうし、シリーズ命名規則`Hermes VPS - {用途}`から外れる。**コピーアイコン**でクリップボードに取得→手動で命名保存が正しい運用。

### 5. 1Password公式リポジトリのURLは`my.1password.com`ではなく`start.1password.com`

過去のドキュメントには`my.1password.com/developer-tools/...`と書かれているものもあるが、2026年5月時点の正しいURLは`start.1password.com/developer-tools/infrastructure-secrets/serviceaccount/?source=dev-portal`。`my.`で開くとサインインページに飛ばされてリダイレクトループになることがある。

## まとめと第4回予告

第3回で達成したのは、Hermesに秘密を渡す経路を**op CLI一択**に固定したこと。VPSのディスクには`op://`参照だけが書かれ、実値は1Password側に存在する。サービスアカウントのスコープは`Hermes-Prod` read-onlyだけで、最小権限の原則を守る。

第4回でHermes本体をインストールしたら、systemdユニットの`ExecStart`を`op run --env-file=$HOME/.hermes/secrets.env -- hermes gateway run`にすることで、起動時に自動で`op://`参照が解決され、Hermesプロセスに環境変数として注入される。MCPを使わないので、AIのコンテキスト・ログ・キャッシュに秘密が載る経路はない。

これで「Hermesに秘密をどう渡すか」の設計判断は終わった。第4回ではいよいよHermes本体をインストールする。

## 番外編:1Password Environments(beta)とは何か

本編では通常の「保管庫アイテム+`op run`」パターンで完結させた。読者が混乱しないよう、1Passwordが2025-2026年に提供を始めた新機能**Environments**(beta)について最後に触れておく。本編とは別の運用アプローチで、現時点では選択肢の一つとして頭の片隅に置く程度でよい。

### Environments(beta)とは何か

「環境(staging/prod/dev等)単位で変数の束を持つ」仕組み。通常のVaultがアイテム単位で「APIキー1個」「botトークン1個」のように個別管理するのに対し、Environmentsは「`hermes-prod`環境の変数束=`OPENAI_API_KEY`+`TELEGRAM_BOT_TOKEN`+`DATABASE_URL`...」のように環境ごとにまとめて管理する。

| 項目 | 通常のVault運用(本編) | Environments(beta) |
|---|---|---|
| 単位 | アイテム単位 | 環境単位 |
| 参照記法 | `op://Vault/Item/Field` | `op://Env/Variable` |
| ローカル`.env`同期 | なし(`op run --env-file=`で代用) | あり(`op env`サブコマンドで双方向同期) |
| AWS Secrets Manager連携 | なし | あり |
| エージェント連携(ローカル開発時の自動注入) | なし | あり |
| 本番運用適性 | 成熟(枯れている) | beta(API変更リスクあり) |

### 本編と何が違うのか

通常のVault運用は「アイテムを開いてフィールドを参照する」形。Environmentsは「環境ごとに変数の束を持って、まるごと注入する」形。

後者は**複数環境を切り替える運用に強い**(stagingとprodで違うキーを使う等)。例えば「staging環境ではTelegram bot Aを使い、prod環境ではbot Bを使う」のような切り替えが、環境名を差し替えるだけで済む。Hermesはprod環境1つだけなので、この優位性は出にくい。

### 有効化手順

興味がある人向けに、betaの参加手順を概略で記載する(2026年5月時点)。具体的な画面・コマンドは1Passwordの公式betaドキュメントが正で、本記事は実機検証していない。

1. 1Password.com→Developer Tools→Environments(beta)ページを開く
2. beta参加に同意
3. 新規Environment作成:名前`hermes-prod`
4. 変数追加:`TELEGRAM_BOT_TOKEN=<値>`等
5. 1Password提供の`op`サブコマンドで動作確認(コマンド名はbeta期間中に変わる可能性があるので公式ドキュメント参照)

### Hermesで使うべきか

**現時点では本編の`op run`基本構成のままで十分**。Environmentsは将来の選択肢として記憶しておく程度でよい。

| 観点 | 判断 |
|---|---|
| 環境切り替え需要 | Hermesはprod1個のみ→切り替え不要 |
| beta機能のリスク | API仕様変更で壊れる可能性 |
| 本編構成の安定性 | `op` CLI本体が動けば確実に動く(枯れている) |

「Codex/Telegram/Discord/自宅GPU連携でトークンの種類が10個以上に増えて、本編の`secrets.env`に書き並べるのが破綻してきた」と感じたら、移行を検討すればよい。

ここまでが第3回。次回は第4回でHermes Agent本体をインストールする。

## 公式ドキュメント引用元

| 項目 | 引用元 |
|---|---|
| 1Passwordサービスアカウントの発行 | [Service Accounts](https://www.1password.dev/service-accounts/get-started/) |
| opコマンド(1Password CLI)の導入 | [1Password CLI](https://www.1password.dev/cli/get-started/) |
| op://参照記法 | [Secret references](https://www.1password.dev/cli/secret-references/) |
| op runで環境変数に秘密を注入 | [Load secrets into env vars](https://www.1password.dev/cli/secrets-environment-variables/) |
