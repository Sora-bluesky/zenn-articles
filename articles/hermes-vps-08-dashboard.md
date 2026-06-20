---
title: "【第8回】Hermes AgentをWeb Dashboardで管理する方法"
emoji: "🎛️"
type: "tech"
topics: ["ai", "hermes", "dashboard", "vps", "ux"]
published: true
---

## 目次

- [この回の到達点](#この回の到達点)
- [Hermes Desktopとの違い──顔と管制室](#hermes-desktopとの違い──顔と管制室)
- [v0.16.0「Surface Release」で何が変わったか](#v0.16.0「surface-release」で何が変わったか)
- [この回で出てくる用語](#この回で出てくる用語)
- [第8回終了時点の構成図](#第8回終了時点の構成図)
- [事前準備](#事前準備)
- [ブラウザで管制室を開く](#ブラウザで管制室を開く)
- [同じ情報がCLIとブラウザの両方から見える](#同じ情報がcliとブラウザの両方から見える)
- [最初に日本語UIに切り替える](#最初に日本語uiに切り替える)
- [サイドバー全体像と横断UI](#サイドバー全体像と横断ui)
- [状態と履歴──セッション・ログ・分析・チャット](#状態と履歴──セッション・ログ・分析・チャット)
- [自動と技能──CRON・スキル・プラグイン](#自動と技能──cron・スキル・プラグイン)
- [モデルと人格──モデル・プロファイル](#モデルと人格──モデル・プロファイル)
- [設定とキー──手書きの設定ファイルから卒業する](#設定とキー──手書きの設定ファイルから卒業する)
- [連携と窓口──MCP・チャンネル・Webhooks・ペアリング](#連携と窓口──mcp・チャンネル・webhooks・ペアリング)
- [保守──System・ドキュメント・サイドバー下部](#保守──system・ドキュメント・サイドバー下部)
- [動作確認──ブラウザの変更がCLIに出る](#動作確認──ブラウザの変更がcliに出る)
- [どこからでも同じ1体のエージェント](#どこからでも同じ1体のエージェント)
- [最終確認チェックリスト](#最終確認チェックリスト)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [早見表](#早見表)
- [関連記事](#関連記事)
- [公式ドキュメント引用元](#公式ドキュメント引用元)

## このシリーズの読み方

このシリーズは、VPS(=自分専用に契約するサーバー)1台にHermes AgentというAIエージェントを常駐させて、自分専用の相棒を育てていく連載。第7回までで「黒い画面でHermesと話す」「Telegram/Discordから話す」「母艦のDesktopアプリで話す」までを揃えた。第8回からは「ブラウザの管制室から設定を触る」段階に入る。

:::details シリーズのもくじ(全45回・タップで開く)

**第I部 体を作る**
- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy) Hermes AgentをVPSにデプロイする方法
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale) Hermes Agentの接続を安全にする方法
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password) Hermes Agentの認証情報を安全に管理する方法
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install) Hermes AgentをDockerで隔離して動かす方法
- [第5回](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord) Hermes AgentにGrokとDiscordを連携させる
- [第6回](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd) Hermes Agentをsystemdで常時起動させる方法

**第II部 顔をつける**
- [第7回](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop) Hermes Agentをデスクトップアプリで操作する方法
- **第8回**(本記事) Hermes AgentをWeb Dashboardで管理する方法

**第III部 育てる**
- [第9回](https://zenn.dev/sora_biz/articles/hermes-vps-09-cron) Hermes Agentに毎朝のタスクを自動実行させる
- [第10回](https://zenn.dev/sora_biz/articles/hermes-vps-10-skills) Hermes Agentが使うほど賢くなるSkillsの登録方法
- 第11回 Hermes Agentに最新情報を自動取得させる方法

**第IV部 記憶を分けて育てる**
- 第12回 Hermes AgentにMemoryで好みと前提を記憶させる
- 第13回 Hermes AgentとObsidianを連携して知識を共有する

全45回の全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

所要時間の目安は60〜90分(うち画面を眺めて慣れる時間が大半)。第7回で常駐させた`hermes dashboard`を、今度はブラウザで開いて触っていく。

## この回の到達点

第7回で母艦に[Hermes Desktop](https://hermes-agent.nousresearch.com/docs/user-guide/desktop)を入れて、VPSのHermesと繋いだ。同じVPSのHermesにつながる窓がもう1つある。それが**Web Dashboard**=ブラウザで開く管理画面。

第7回までの僕は、設定を変えるたびにSSHでVPSに入って`nano ~/.hermes/config.yaml`を開いていた。ボットの有効化、APIキーの追加、サーバー設定の編集──ぜんぶ黒い画面の中で手で書いていた。

v0.16.0(コードネーム"Surface Release")でWeb Dashboardが大きく進化した。**設定もキーもCronもスキルもMCPもチャンネルもWebhookも、ぜんぶブラウザのフォームから触れる**ようになっている。手書きYAMLとはそろそろお別れだ。

到達点を表にする。

| 項目 | 第7回完了時 | 第8回完了後 |
|---|---|---|
| Hermesへの窓 | Telegram/Discord/SSH+Desktop | 同左+ブラウザのDashboard |
| 設定変更 | SSH+`nano config.yaml` | ブラウザのフォームで保存 |
| APIキー追加 | SSH+`nano .env` | ブラウザのフォームで設定 |
| Cronジョブ追加 | `hermes cron add`をSSHで | ブラウザの「作成」ボタン |
| プラットフォーム(Telegram等)有効化 | `.env`+`config.yaml`を手書き | ブラウザでSAVE & ENABLE |
| 公式docを読む | ブラウザの別タブ | Dashboard内のドキュメントペインで |
| バージョン確認 | SSH+`hermes version` | ログイン直後に常時表示 |

「ターミナルがダメ」「黒い画面が苦手」というだけで、ここまで作ってきた一切をあきらめなくていい──それを実物で示すのがこの回。

## Hermes Desktopとの違い──顔と管制室

第7回のHermes Desktopと、この回のWeb Dashboardは、どちらも同じVPSのHermesにつながる別の窓だ。役割が違うので「両方ある」ことに意味がある。

| 観点 | 第7回 Hermes Desktop | この回 Web Dashboard |
|---|---|---|
| 正体 | 母艦で動くネイティブアプリ | ブラウザで開く管理画面 |
| 主な用途 | 日常の会話・ファイル投下・モデル切替 | 設定・Cron・スキル・記憶・MCP・窓口の管理 |
| たとえ | 毎日会いに行く相棒の「顔」 | 裏側を整える「管制室」 |
| 起動 | アプリアイコンをダブルクリック | ブラウザに`http://<tailscale-ip>:9119`を入力 |
| 接続先 | VPSの`hermes dashboard`(常駐) | VPSの`hermes dashboard`(常駐) |

接続先は同じ。第7回でVPSに常駐させた`hermes dashboard`が、Desktopアプリにとっては「Remote Gateway」、ブラウザにとっては「Webサイト」に見えているだけ。実体は1つ。

:::message
Desktop=顔・Dashboard=管制室。両方とも同じ1体のエージェントを別の窓から操作している。
:::

## v0.16.0「Surface Release」で何が変わったか

v0.16.0(2026-06-05公開・コードネーム"Surface Release")でDashboardは「セッションを見る画面」から「設定をまるごと管理する管制室」に変わった。

主な追加:

- **MCPカタログ**(Nous Research承認の外部ツールをワンクリックで導入)
- **チャンネル管理**(Telegram/Discord/Slack/Mastodon等23プラットフォーム)
- **APIキー管理**(`.env`の中身をフォームから安全に編集)
- **Webhook購読**(GitHub/GitLab等から呼ばれる窓口を作成)
- **メモリ操作**(`MEMORY.md`/`USER.md`の状態確認とリセット)
- **保守オペレーション**(`doctor`/`security-audit`/`backup`等のワンクリック保守)
- **デバッグ共有**(障害報告用の状態ダンプを1ボタンで生成)
- **ブラウザ内チャット常時有効化**(ブラウザの中にHermesのターミナルUIをそのまま埋め込んで動かす)

v0.15以前のDashboardが「ビューア」だったのに対して、v0.16.0は「エディタ兼コントローラ」になった。

## この回で出てくる用語

| 用語 | 意味 |
|---|---|
| 母艦 | 普段使いのノートPC(僕の場合はWindows機)。ここのブラウザでDashboardを開く |
| ペイン(pane) | Dashboard内の各管理画面(セッション/CRON/スキル等)。サイドバーで切り替える |
| TUI | ターミナル上で動くテキスト版のUI(Hermesの`hermes`コマンドで開く対話画面)。Dashboardの「チャット」はこのTUIをブラウザに埋め込んだもの |
| ブラウザ内チャット | サイドバーの「チャット」ペイン。VPSのTUIをブラウザでそのまま動かす |
| MCP | 外部の道具(検索エンジン・GitHub等)をHermesにつなぐ仕組み |
| messenger | Telegram/Discord/Slack/Mastodon等のメッセージングサービスの総称 |
| チャンネル(Channels) | messengerの窓口を管理するペイン |
| Webhook | 外部のイベント(GitHubのpushや決済通知等)を受け取ってHermesを起こす入口 |
| ペアリング(Pairing) | messengerユーザーを承認する仕組み。第5回の`allowFrom`の標準化UI |
| YAML | コンピューターの設定を「キー: 値」の字下げで書くテキスト書式。Hermesは`~/.hermes/config.yaml`がこれ |
| HMAC | webhookの送信元(GitHub等)が「自分が送った」と証明するための署名方式。共有のシークレットを使う |

YAMLは慣れないとインデント(字下げ)で詰まりやすい書式。Dashboardはこれをフォームで代わりに編集してくれるので、字下げのことを意識せずに済む。

## 第8回終了時点の構成図

![第8回終了時点の構成図。母艦(ノートPC)のブラウザとHermes DesktopがTailscaleの暗号化トンネルでVPSに繋がる。VPS側ではhermes dashboard(常駐・port 9119)が管制室を表示、hermes gateway(常駐・RESTART NOWで再読込)が設定を反映、~/.hermes/config.yamlは管制室から書き換わる設定ファイル、~/.hermes/.envはAPIキー類、Telegram/Discord/Webhook等はチャンネルペインで管理される構成図](/images/hermes-vps/hermes-vps-08-dashboard-architecture-diagram.png)

第6回で立ち上げた`hermes gateway`は今までずっと走っていて、Telegram/DiscordからのメッセージにもHermesが応答していた。そこに第7回でDesktopが、この回でDashboardが「同じVPSのHermesへの別の窓」として加わる。

## 事前準備

第7回でVPSの`hermes dashboard`は認証つきでsystemd常駐済みのはず。まずそれが生きているか確認する。

```bash
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps
tailscale ip -4
systemctl --user status hermes-dashboard
curl -s http://<tailscale-ip>:9119/api/status | jq '.auth_required, .auth_providers'
tailscale status
grep BASIC_AUTH_SECRET ~/.hermes/.env
```

期待される出力:

- `systemctl status`が`active (running)`(=第7回の常駐が生きている)
- `/api/status`が`true / ["basic"]`(=認証が有効)
- `tailscale status`に母艦のホスト名(例:`thinkpad-x13`)+`active; direct`(=同じtailnetにいる)
- `BASIC_AUTH_SECRET`が固定値(=未設定だと再起動の度にログインが切れる)

![systemctl status hermes-dashboardの出力(active running)](/images/hermes-vps/hermes-vps-08-dashboard-systemctl-active.png)

![curl /api/statusとtailscale statusの結果(同じtailnetにいる証拠)](/images/hermes-vps/hermes-vps-08-dashboard-curl-tailscale.png)

:::message
母艦とVPSが同じtailnetにいるかは、VPS側で`tailscale status`を打って母艦のホスト名行が見えるか、または母艦のWindowsで`tailscale.exe status`を打ってVPSが見えるか、どちらでもOK。
:::

## ブラウザで管制室を開く

母艦のブラウザで、VPSのTailscale IPとポート9119を開く。

```
http://<tailscale-ip>:9119
```

サインイン画面が出る。

![dashboardのサインイン画面(NOUS RESEARCH+SIGN IN+admin+PUBLIC BIND・AUTH REQUIRED)](/images/hermes-vps/hermes-vps-08-dashboard-signin.png)

入れる値は第7回で決めたとおり。

- USERNAME=`admin`
- PASSWORD=第7回で決めて1Passwordに保管したやつ
- 下部に`PUBLIC BIND · AUTH REQUIRED`(=非loopbackにbindしているので認証が必須、という証拠)

ボタンを押すと、サイドバーつきの管理画面に着地する。

:::message
このサインイン画面、第7回のHermes Desktopアプリ内で見たRemote接続時の画面と中身がまったく同じ。同じバックエンドの`/signin`ページが、片方ではブラウザに、片方ではDesktopアプリ内のウィンドウに表示されているだけ。違うのはウィンドウの「枠」だけ。
:::

## 同じ情報がCLIとブラウザの両方から見える

サインインしたら、最初にやってほしいことがある。**ターミナルとブラウザを並べて比較する**ことだ。

第8回の主題=「黒い画面から管制室へ」を、まず1枚で証明したいので。

VPSのターミナルで:

```bash
hermes version
```

出力:

```
Hermes Agent v0.16.0 (2026.6.5) · upstream c4066091
Project: /home/admin/hermes-agent
Python: 3.11.15
OpenAI SDK: 2.24.0
Update available: 18 commits behind — run 'hermes update'
```

![CLIでのhermes versionの出力](/images/hermes-vps/hermes-vps-08-dashboard-version-cli.png)

つぎにブラウザで、サイドバー左の「SYSTEM」(まだ英語UIのままなので英語だが、すぐ日本語に変える)をクリック。

![Dashboard SYSTEMペイン(Host+Nous Portal+Skill curator+Gateway+Memory+Credential pool+Operations+Share debug report+Checkpoints+Shell hooks)](/images/hermes-vps/hermes-vps-08-dashboard-version-gui.png)

`Host`セクションの`HERMES v0.16.0`+`18 behind`バッジが、CLIで打った`hermes version`の結果とぴったり一致する。それだけじゃなく:

- ターミナルでは見えなかった**OS/CPU/メモリ/ディスク/UPTIME**が一覧で出る
- ターミナルでは別途打つ必要があった**Check for updates**と**Update now**がボタンで並ぶ
- さらに下にスクロールすると**Skill curator**や**Gateway**の状態、**Operations**(`doctor`/`security audit`/`backup`等のワンクリック保守)、**Memory**(MEMORY.md/USER.mdのリセット)まで一望できる

つまり「**`hermes version`を打たなくても、ログインした瞬間からバージョンも更新状況も全部見える**」。これがDashboardの本領で、第8回の主題そのものだ。

:::message
左サイドバーの最下部にも小さく`v0.16.0`+`Nous Research`が表示されている(常時表示)。どのペインを開いていてもバージョンが視界に入る設計。
:::

## 最初に日本語UIに切り替える

サイドバーやペイン名はデフォルトで英語(`CHAT`/`SESSIONS`/`MODELS`等)。これを日本語UIに切り替えると、非エンジニアの読者にも一気に距離が縮まる。

ログイン直後の画面はこんな状態(英語UI)。

![ログイン直後の英語UIサイドバー(CHAT/SESSIONS/MODELS/LOGS/CRON/SKILLS/PLUGINS/MCP/CHANNELS/WEBHOOKS/PAIRING/PROFILES/CONFIG/KEYS/SYSTEM/DOCUMENTATION)](/images/hermes-vps/hermes-vps-08-dashboard-sessions-sidebar-en.png)

サイドバー最下部の左下に**国旗アイコン**+`EN`の表示がある。これをクリック。

![言語スイッチャー展開(English/日本語/한국어/Deutsch/Italiano/Français/Portugues等)](/images/hermes-vps/hermes-vps-08-dashboard-language-switcher.png)

「日本語」を選ぶ。

![日本語UI後のサイドバー(チャット/セッション/モデル/ログ/CRON/スキル/プラグイン/MCP/CHANNELS/WEBHOOKS/PAIRING/プロファイル/設定/キー/SYSTEM/ドキュメント+Plugins下にKANBAN/ACHIEVEMENTS+下部「ゲートウェイ状態:実行中」「ゲートウェイを再起動」「Hermesを更新」)](/images/hermes-vps/hermes-vps-08-dashboard-sessions-sidebar-ja.png)

サイドバー全部+各ペインのラベル+下部のシステムアクションまで、即座に日本語になる。「CRON」「CHANNELS」「WEBHOOKS」「PAIRING」「SYSTEM」のように原文のままのものもあるが、これは固有名詞に近いので翻訳しないのが自然。

:::message
言語スイッチャーには英語/日本語のほかに한국어(韓国語)・Deutsch(ドイツ語)・Italiano(イタリア語)・Français(フランス語)・Portugues(ポルトガル語)もある。Hermes本体は多言語UIに対応していて、Dashboardもその恩恵を受けている。
:::

以降のスクリーンショットはすべて日本語UI状態のものを使う。記事の中の表記も「セッション(Sessions)」「設定(Config)」のように、初出時に日本語と英語を併記して、2回目以降は日本語UIラベルだけにする。

## サイドバー全体像と横断UI

日本語UIに切り替えたあとのサイドバーを上から下まで見ていく。

### ベース16ペイン+`分析`で17

`/`(ルート)を開くと「セッション」(Sessions)ペインに着地する。サイドバーには次のペインが縦に並ぶ。

| カテゴリ | 日本語ラベル | 英語ラベル | この記事で扱う章 |
|---|---|---|---|
| 状態と履歴 | チャット | Chat | 後述 |
| 状態と履歴 | セッション | Sessions | 後述 |
| 状態と履歴 | 分析 | Analytics(フラグ有効時のみ) | 後述 |
| 状態と履歴 | モデル | Models | 後述 |
| 状態と履歴 | ログ | Logs | 後述 |
| 自動と技能 | CRON | Cron | 後述 |
| 自動と技能 | スキル | Skills | 後述 |
| 自動と技能 | プラグイン | Plugins | 後述 |
| 連携と窓口 | MCP | MCP | 後述 |
| 連携と窓口 | CHANNELS | Channels | 後述 |
| 連携と窓口 | WEBHOOKS | Webhooks | 後述 |
| 連携と窓口 | PAIRING | Pairing | 後述 |
| モデルと人格 | プロファイル | Profiles | 後述 |
| YAML卒業 | 設定 | Config | 後述 |
| YAML卒業 | キー | Keys | 後述 |
| 保守 | SYSTEM | System | 後述 |
| 保守 | ドキュメント | Documentation | 後述 |

ベースは**16ペイン**で、`config.yaml`の`dashboard.show_token_analytics`をtrueにすると「分析」が加わって17ペインになる。

これに加えて、プラグイン由来で**カンバン**(Kanban)と**アチーブメント**(Achievements)がサイドバー下部の「Plugins」グループに並ぶ。

### サイドバーは折りたためる

サイドバー上部のロゴ横にある折りたたみアイコンを押すと、サイドバーがアイコン幅に縮む。

![サイドバー折りたたみ後(アイコンのみ表示・本体は広く使える)](/images/hermes-vps/hermes-vps-08-dashboard-sidebar-collapsed.png)

メインエリアを広く使いたいときに便利。展開状態と折りたたみ状態の切り替えはブラウザの`localStorage`に記憶されるので、次回ログイン時も同じ状態で開く。

### サイドバー下部に並ぶ常時アクション

サイドバーの最下部には、どのペインを開いていても触れる常時表示の機能が並ぶ。

| 表示 | 役割 |
|---|---|
| ゲートウェイの状態: 実行中(緑) | gatewayが動いていることのインジケータ |
| アクティブなセッション数: N | 現在実行中のセッション数 |
| ↻ ゲートウェイを再起動 | CLIの`hermes gateway restart`のGUI版 |
| ⬇ Hermesを更新 | CLIの`hermes update`のGUI版 |
| HERMES TEAL | 現在のテーマ表示(クリックで7テーマ+5フォントのドロップアップ) |
| 日本語 | 現在の言語表示(クリックで8言語の切替) |
| admin / via basic / ↩ | ログインユーザー名+認証方式+ログアウト |
| v0.16.0 / Nous Research | バージョンと著作表示 |

つまり「設定変更を反映したい」と思ったときに、SYSTEMペインまでスクロールしなくても**サイドバー下部の「ゲートウェイを再起動」を押すだけ**で済む。

## 状態と履歴──セッション・ログ・分析・チャット

サイドバー上部の4つは、Hermesの「現在」と「過去」を見るためのペイン。

### セッション(Sessions)

ログイン直後にデフォルトで着地するのが、この「セッション」ペイン。過去にHermesと交わした会話がすべて並ぶ。

![セッションペイン(検索窓に「hermes」入力済+履歴ビュー+各行のチェックボックス+▶ボタン+sourceバッジ)](/images/hermes-vps/hermes-vps-08-dashboard-sessions.jpg)

上部に「概要」(Overview)と「履歴」(History)のタブがあり、履歴に切り替えると一覧モードに。検索窓に文字を入れると本文中まで全文検索してくれて、ヒット箇所は強調表示される。

| できること | 説明 |
|---|---|
| FTS5全文検索 | 検索窓に文字を入れるとデバウンスで実行・ヒット箇所をハイライト |
| Shift-クリック範囲選択 | Gmail式の範囲選択でまとめてチェック |
| 一括削除 | 選択した複数を一気に削除 |
| 古いセッション掃除 | 日数を指定して古い分を一括削除 |
| JSONエクスポート | 1セッションを構造化テキストで書き出し |
| インラインリネーム | タイトルをその場で編集 |
| 概要/履歴切替 | 統計サマリと一覧の切り替え |
| ▶でチャットへ引き継ぎ | その会話の続きを「チャット」タブで再開 |
| Source/Liveバッジ | 緑のパルスがアクティブ中のセッション |

第6回までずっとCLIで`hermes --continue`していた作業が、ここで一気に視覚化された。`cron`から起動された会話、Telegramからの会話、Discordからの会話、CLIから打った会話──すべてが同じセッションリストに混ざって並ぶ。

### ログ(Logs)

「ログ」ペインは裏方の動作確認。第6回で`journalctl --user -u hermes-gateway`で見ていたものが、ここで完結する。

![ログペイン(AGENT/ERRORS/GATEWAYファイル切替+ALL/GATEWAY/AGENT/TOOLS/CLI/CRONコンポーネント絞り込み+ALL/DEBUG/INFO/WARNING/ERRORレベル+行数50/100/200/500+自動更新+ログ更新)](/images/hermes-vps/hermes-vps-08-dashboard-logs.png)

絞り込み軸が4種類ある。

- **ファイル**:`agent`/`errors`/`gateway`の3ファイル
- **コンポーネント**:`gateway`/`agent`/`tools`/`cli`/`cron`等の発信元
- **レベル**:`DEBUG`/`INFO`/`WARNING`/`ERROR`
- **行数**:50/100/200/500

`WARNING`だけに絞ったり、自動更新をONにしてリアルタイム監視したり、用途に合わせて使い分けできる。

### 分析(Analytics)

「分析」ペインは、Hermesがどれだけトークンを使ったか・どのモデルにどれだけ仕事をさせたか・何セッション動かしたか、を見るための画面。

このペインは少し特殊で、**`config.yaml`の`dashboard.show_token_analytics`をtrueにしたときだけサイドバーに出てくる**。デフォルトはoff。トークン数や費用の数字は解釈に注意が要るので、見たい人だけ見せる、というDashboard側の配慮。

ここで管制室の本領発揮ポイントだ。**この有効化作業もブラウザだけで完結する**。

サイドバーで「設定」を開き、上部の検索窓に`analytics`と入力。「SHOW TOKEN ANALYTICS」がヒットするので、トグルをONにして右上の「保存」を押すだけ。

![設定ペインでshow_token_analyticsトグルON+右上に保存ボタン](/images/hermes-vps/hermes-vps-08-dashboard-analytics-toggle.png)

これだけで、VPSの`~/.hermes/config.yaml`に`dashboard.show_token_analytics: true`が書き込まれる。SSHは不要・`nano`も不要。F5でブラウザをリロードすると、サイドバーに「分析」が現れる。

![分析ペイン(期間トグル7d/30d/90d+合計トークン数/入力/出力/合計セッション数/APS呼び出し+日次トークン使用量グラフ+日次内訳テーブル+モデル別内訳)](/images/hermes-vps/hermes-vps-08-dashboard-analytics.png)

期間トグル(7日/30日/90日)・合計トークンや入力出力のサマリーカード・日次のトークン使用量グラフ・日別/モデル別/スキル別の内訳テーブル。ここまで揃って初めて「あ、Hermesってこんなに動いてたんだ」と実感できる。

### チャット──ブラウザの中にターミナル

サイドバー最上部の「チャット」をクリックすると、ブラウザの中に**HermesのTUI**(ターミナル上で動くテキスト版のUI)がそのまま埋め込まれて動く。

![チャットペイン(HERMES-AGENT ASCIIアートロゴ+利用可能なツール一覧+「こんにちは」→「こんにちは!今日は何をお手伝いしましょうか?」+下部にステータスバー)](/images/hermes-vps/hermes-vps-08-dashboard-chat.png)

実体は`xterm.js`+WebSocketで、VPSのPTYに接続している。Windowsネイティブの母艦から開いていても、描画はVPS側で走るので動く。

v0.16.0以前は`--tui`フラグで制御していたが、Surface Releaseで**常時有効化**された。`config.yaml`に何か書く必要はない。

「セッション」ペインで各行の右端にある**▶ボタン**(Resume in Chat)を押すと、その会話の続きをこのチャットタブで再開できる。チャットタブは他のペインに移動しても停止されない設計(`display:none`で隠すだけ)なので、行ったり来たりしても会話が途切れない。

## 自動と技能──CRON・スキル・プラグイン

「CRON」「スキル」「プラグイン」の3ペインは、これから先の回(第9回・第10回)で詳しく作るものの**入口**だ。この回では「管制室にこういう場所がある」を見ておくだけで十分。

### CRON

第9回で登録する予定の定期実行ジョブが、ここで一覧管理できる。

![CRONペイン(スケジュール済みジョブ一覧+各行にバッジ+PROFILEフィルタ+「作成」ボタン)](/images/hermes-vps/hermes-vps-08-dashboard-cron.png)

各ジョブの右端にアクションアイコン(実行/編集/削除等)。右上の「作成」ボタンを押すと、ブラウザだけで新しいジョブを作れるモーダルが開く。

![新しいCRONジョブモーダル(PROFILE/名前/プロンプト/スケジュール/実行間隔/単位/次回実行UTC/配信先=ローカル選択中/保存)](/images/hermes-vps/hermes-vps-08-dashboard-cron-new-job-modal.png)

配信先は`ローカル`(=Hermes本体に通知)/Telegram/Discord/Slack/Emailの5択。CLIで`hermes cron add`を打つのと、ブラウザでこのモーダルを埋めるのとで、行き着く先は同じ`config.yaml`だ。

:::message
詳しくは第9回「Hermes Agentが朝から話しかけてくる──Dashboardで毎朝の定型タスクを任せる」で、Dashboardから新規ジョブを作成→`Trigger now`で即実行→Telegram配信までを一気通貫で扱う。この回ではセクションを開いて存在を確認するだけで十分。
:::

### スキル(Skills)

「スキル」ペインはエージェントに「手順」を覚えさせる仕組みの管理画面。

![スキルペイン(カテゴリ別にskillが縦に並ぶ・各行にトグル・左に3ビューのフィルター)](/images/hermes-vps/hermes-vps-08-dashboard-skills.png)

左のフィルターで3つのビュー(すべて/ツールセット/BROWSE HUB)を行き来できる。

- **すべて**(Skills):インストール済みskill一覧・トグルで有効/無効
- **ツールセット**(Toolsets):複数skillを束ねたセット
- **BROWSE HUB**:新規skillを探す・ワンクリック導入

:::message
詳しくは第10回「Hermes Agentが使うほど自分専用に育つ──Skillsに手順を覚えさせる」で扱う。
:::

### プラグイン(Plugins)

「プラグイン」ペインは、スキルとは別の**拡張プラグイン**を管理する画面。

![プラグインペイン(GITHUB/GIT URLからインストールフォーム+チェックボックス2つ+インストールボタン+インストール済みプラグイン)](/images/hermes-vps/hermes-vps-08-dashboard-plugins.png)

`owner/repo`の短縮形か、`https://`または`git@`のクローンURLを入力欄に貼って、`インストール`ボタンを押すと取り込まれる。チェックボックスで「既存フォルダを先に削除(強制再インストール)」「インストール後に有効化」も指定できる。

サイドバー下部の「Plugins」グループに表示されている`カンバン`と`アチーブメント`は、このプラグイン経由でサイドバーに追加されたエントリだ。

## モデルと人格──モデル・プロファイル

「モデル」と「プロファイル」の2ペインで、Hermesの**頭の中身**を組み立てる。

### モデル(Models)

「モデル」ペインは3ブロック構成。

![モデルペイン(MODEL SETTINGS=MAIN MODEL+CHANGE+AUXILIARY TASKS+CONFIGURE・集計カード5項目・モデル別カード=gpt-5.5にmainバッジ+capability badges+TokenBar+USE AS)](/images/hermes-vps/hermes-vps-08-dashboard-models.png)

1. **MODEL SETTINGS**(新規セッションへの設定)
   - MAIN MODEL=現在のメインモデル(例:`openai-codex / gpt-5.5`)+`CHANGE`ボタン
   - AUXILIARY TASKS=補助タスク状態(例:`tasks · all auto`)+`CONFIGURE`ボタン
2. **集計カード**(右側)
   - 検出モデル/合計トークン数/入力/推定コスト/合計セッション数
   - ヘッダーの期間トグル(7d/30d/90d)と連動
3. **モデル別カード**(下部)
   - 検出された各モデル(例:`gpt-5.5`/`gpt-5`)にカード
   - capability badges(Tools/Vision/Reasoning)+stacked TokenBar+メトリクス

`AUXILIARY TASKS`の`CONFIGURE`を押すと、補助タスクの一覧モーダルが開く。

![AUXILIARY TASKSモーダル(11枠=Vision/Web Extract/Compression/Skills Hub/Approval/MCP/Title Gen/Triage Specifier/Kanban Decomposer/Profile Describer/Curator+RESET ALL TO AUTO+各CHANGE)](/images/hermes-vps/hermes-vps-08-dashboard-models-auxiliary-tasks.png)

**11個の補助タスク**にそれぞれ別のモデルを割り当てられる。

| 補助タスク | 用途 | 軽量モデルでよいか |
|---|---|---|
| Vision | 画像解析 | 視覚対応モデルが要る・安いのでOK |
| Web Extract | ページ要約 | 軽量で十分 |
| Compression | 文脈圧縮 | 軽量で十分 |
| Skills Hub | skill検索 | 軽量で十分 |
| Approval | 賢い自動承認 | 判断精度のため中位以上 |
| MCP | MCPツールルーティング | 軽量で十分 |
| Title Gen | セッションタイトル生成 | 最小モデルでOK |
| Triage Specifier | Kanban詳細化 | 中位推奨 |
| Kanban Decomposer | タスク分解 | 中位推奨 |
| Profile Describer | 自動プロファイル説明 | 軽量で十分 |
| Curator | skill使用レビュー | 軽量で十分 |

設計の鍵は「**主モデルに高性能なものを置き、補助業務には軽量モデル**」だ。`Vision`や`Title Gen`のような単純作業に高性能モデルを使うとコストがかさむ。`RESET ALL TO AUTO`で一括して「メインモデルと同じ」に戻せる。

各タスクの`CHANGE`を押すと、モデル選択ダイアログが開く。

![SET AUXILIARY WEB EXTRACTモーダル(Current gpt-5.5/Default openai-codex+検索バー+左にプロバイダー一覧+右にモデル一覧gpt-5.5/gpt-5/gpt-5-mini/gpt-5-codex-spack+Cancel/Switch)](/images/hermes-vps/hermes-vps-08-dashboard-models-auxiliary-tasks2.png)

左カラムにプロバイダー(Nous Portal/OpenRouter/Anthropic/OpenAI Codex/xAI Grok Studio等)、右カラムにそのプロバイダーのモデル一覧。`Switch`で確定する。

### プロファイル(Profiles)

「プロファイル」ペインは、Hermesに**複数の人格**を持たせて切り替える画面。

![プロファイルペイン(Active profile: default+「プロファイル(1)」カウント+defaultカード+ACTIVE+デフォルトバッジ+No description+Gateway running+LLM情報+...メニュー)](/images/hermes-vps/hermes-vps-08-dashboard-profiles.png)

デフォルトは`default`profileだけだが、「コード仕事用」「日常会話用」「英語学習用」のように、別のSOUL.md・別のskills構成・別のモデルを束ねたprofileを作って切り替えられる。アクティブなprofileに緑のチェックがつく。

## 設定とキー──手書きの設定ファイルから卒業する

この回の主役の章だ。これまでSSHでVPSに入って`nano ~/.hermes/config.yaml`していた作業を、ブラウザのフォームでやる。

### YAMLって何

YAML(ヤムル)は、コンピューターの設定をテキストで書くための書式のひとつ。Hermesの設定ファイル`~/.hermes/config.yaml`はこの書式で書かれていて、たとえばこんな見た目になっている。

```yaml
model:
  default: gpt-5.5
  context_length: 8192

display:
  resume_exchanges: 10
  resume_max_user_chars: 300
```

`キー: 値`の組み合わせを字下げ(インデント)で表現するのが特徴。インデントが半角スペース2つでないとエラーになる、`:`の後に半角スペースが必須、というような細かい規則があって、慣れないとつまずきやすい書式だ。

Dashboardの「設定」ペインは、このYAMLをフォームのトグルや入力欄で代わりに編集してくれる。**書式の心配をしなくていい**わけだ。

### 設定(Config)

サイドバーの「設定」を開くと、左カラムにカテゴリ一覧、右側がフォーム本体の2カラム構成になっている。

![設定ペインのフォームモード(左に多数のカテゴリ+件数バッジ+「一般」選択中+本体に MODEL/MODEL CONTEXT LENGTH/FALLBACK PROVIDERS/TOOLSETS等)](/images/hermes-vps/hermes-vps-08-dashboard-config-form.png)

カテゴリは**20以上**ある。

- **基本グループ**:一般・エージェント・ターミナル・表示・委任・メモリ・圧縮・セキュリティ・ブラウザ・ロギング・補助
- **プロバイダー/連携**:Discord・Slack・Bedrock・Curator・Gateway・Kanban・Lsp・Matrix・Mattermost・Model_catalog・Openrouter・Secrets・Sessions・Streaming・Tools・Web・X_search等

各カテゴリ名の右に件数バッジが表示されて、何個の設定項目が含まれるかが一目でわかる。

主要機能:

| 機能 | 説明 |
|---|---|
| フォーム/YAML切替 | 右上のトグルで「フォームで触る」「YAMLで直接書く」を切替 |
| リアルタイム検索 | 右上の検索窓でkey/label/descriptionをまたいで検索 |
| Scoped Reset | 検索結果やactiveカテゴリだけ初期値に戻す(全リセットしなくていい) |
| 保存/リセット/エクスポート/インポート | 設定の持ち運びもできる |

右上のトグルをYAML側に切り替えると、同じ設定が生のYAMLとして見られる。

![設定ペインのYAML rawモード(toolsets/known_plugin_toolsets/image_gen/Fallback Modelコメント等のYAMLテキストが縦に並ぶ)](/images/hermes-vps/hermes-vps-08-dashboard-config-yaml.png)

実際のYAMLは数百行〜千行クラス。toolsets配列・既知プラグインのネスト・image_gen設定・フォールバックモデルのコメントつき設定・サポートプロバイダー一覧などが延々続く。「これを`nano`で開いて1か所だけ直す」というのが従来のVPS運用だった。

フォームモードならカテゴリで絞ってトグル1つ。**この長さを意識しないで済む**のが、設定ペインの真の価値だ。

### キー(Keys)

「キー」ペインは`~/.hermes/.env`のAPIキー類をフォームで管理する画面。

![キーペイン(上部5タブ=キー/OAUTH/PROVIDERS/TOOLS/GATEWAY/SETTINGS+4セクション=プロバイダーログイン(OAUTH 2/7)+LLMプロバイダー(0/5)+キー(0/21)+設定(0/5)+OpenAI/xAI Grok接続済バッジ+「詳細設定を表示」)](/images/hermes-vps/hermes-vps-08-dashboard-keys.png)

上部に**5つのタブ**(キー/OAUTH/PROVIDERS/TOOLS/GATEWAY/SETTINGS)があり、「キー」タブ内に**4セクション**が並ぶ。

| セクション | 内容 |
|---|---|
| 🔐 プロバイダーログイン(OAUTH) | Nous Portal/OpenAI OAuth/Qwen/MiniMax/xAI Grok OAuth/Anthropic API Key/Anthropic OAuth |
| ⚡ LLMプロバイダー | DashScope(Qwen)/DeepSeek/Hugging Face/Xiaomi MiMo/その他 |
| 🔑 キー | EXA/PARALLEL/FIRECRAWL/TAVILY/SEARXNG_URL/BRAVE_SEARCH/BROWSERBASE等のツール系API Key |
| ⚙ 設定 | SUDO_PASSWORD/HERMES_TOOL_PROGRESS/HERMES_PREFILL_MESSAGES_FILE等の動作設定 |

v0.16.0の特徴は、**OAuth方式とAPI Key方式が明確に分離されている**ことだ。たとえば`xAI Grok OAuth(SuperGrok / Premium+)`を使うとAPI Key不要で月額サブスクリプション枠でモデルを使える。料金体系がシンプルで、キー漏洩のリスクもない。

一方、ツール系(Brave Search/Firecrawl/Tavily等)はOAuth未対応なので、従来どおりAPI Key方式で管理する。

:::message
Telegram/Discord/Slackのbot tokenはこの「キー」ペインから除外されていて、代わりに次の「チャンネル」ペインで管理される。`.env`は共有しているが、UIの管理場所は分けてある。
:::

## 連携と窓口──MCP・チャンネル・Webhooks・ペアリング

「MCP」「CHANNELS」「WEBHOOKS」「PAIRING」の4つは、Hermesと外の世界をつなぐ4つの窓だ。

### MCP

「MCP」ペインは外部の道具(検索エンジン・GitHub等)をHermesにつなぐ仕組みの管理画面。

![MCPペイン(右上「ADD SERVER」+🔌 Your MCP servers (0)空状態+🌐 Catalog (2)=Nous(http)/github(stdio)+INSTALL)](/images/hermes-vps/hermes-vps-08-dashboard-mcp.png)

2セクション構成:

- **🔌 Your MCP servers**:自前で追加したMCPサーバー(まだ空なので「No MCP servers configured.」)
- **🌐 Catalog**:Nous Research承認カタログからワンクリック導入(`INSTALL`ボタン)

右上の`ADD SERVER`ボタンを押すと、自前のMCPサーバーを追加するモーダルが開く。

![ADD MCP SERVERモーダル(NAME入力欄+TRANSPORT selector=HTTP/SSE/stdio+URL入力欄+ENVIRONMENT(KEY=VALUE PER LINE)+Add)](/images/hermes-vps/hermes-vps-08-dashboard-mcp-add-server-modal.png)

入力項目:

- NAME=サーバー名
- TRANSPORT=`HTTP/SSE`か`stdio`
- URL(HTTP/SSE時)またはCommand+Args(stdio時)
- ENVIRONMENT=`KEY=VALUE`を1行ずつ並べる

### チャンネル(Channels)

「CHANNELS」ペインはTelegram/Discord/Slack/Mastodon/Bluesky/WhatsApp/Signal等の多数プラットフォームを管理する画面。第4回・第5回でCLIから設定したTelegram/Discordも、ここで扱う。

![チャンネルペイン(N of M channels enabledカウント+多数のプラットフォーム一覧+各行にEnabled/Disabledバッジ+Test/CONFIGURE)](/images/hermes-vps/hermes-vps-08-dashboard-channels.png)

ここでひとつ気づいたことがある。**TelegramもDiscordもDisabledと表示されている**。実際には第4回・第5回でCLI設定済みで動いているのに、なぜか。

理由はこうだ。

- `~/.hermes/.env`にはbot tokenやallowed_usersは入っている
- **`~/.hermes/config.yaml`の`{platform}.enabled: true`フラグが立っていない**=CLI設定では`.env`に値を書いただけ
- Dashboardは「`config.yaml`のenabledフラグ」を見てバッジを出す

つまりgatewayは`.env`を読んで動いているが、Dashboard観点では「未有効化」扱いになるわけだ。

これがv0.16.0時代の運用パターン=「**CLIで構築済みのものをDashboardで引き取って統一管理する**」。手順はこう。

該当行(例:Telegram)の`CONFIGURE`を押すと、設定モーダルが開く。

![CONFIGURE TELEGRAMモーダル(TELEGRAM BOT TOKEN伏字+ALLOWED TELEGRAM IDS空欄+TELEGRAM PROXY URL空欄+Cancel/SAVE & ENABLE)](/images/hermes-vps/hermes-vps-08-dashboard-channels-configure-modal.png)

既存のbot tokenは伏字で表示されていて、そのまま残る。`SAVE & ENABLE`ボタンを押すだけで、`config.yaml`の`telegram:`セクションに`enabled: true`が書き込まれる。

`SAVE & ENABLE`を押した後にチャンネル一覧画面に戻ると、Telegramが緑の`Enabled`バッジになる。

![チャンネル一覧after状態(Telegram=緑Enabledバッジ+SET UP ACTIVE QRボタン+「Changes are saved. Restart the gateway for them to take effect.」アラート+右上RESTART NOW)](/images/hermes-vps/hermes-vps-08-dashboard-channels-telegram-enabled-after.png)

上部に黄色のアラートバナー「Changes are saved. Restart the gateway for them to take effect.」と右上の`RESTART NOW`ボタンが現れる。これを押すとgatewayが再起動して有効化が即反映される。

### Webhooks

「WEBHOOKS」ペインはGitHubのpush・Stripeの決済通知・Zapierのイベント等を受け取ってHermesを起こすwebhookの管理画面。

最初に開くとこんな画面になっている。

![Webhooksペイン初期(「⚠ Webhook platform disabled」警告バナー+🔔 Subscriptions (0)+「No webhook subscriptions yet」+右上「+ NEW SUBSCRIPTION」)](/images/hermes-vps/hermes-vps-08-dashboard-webhooks.png)

`⚠ Webhook platform disabled`という警告バナー。**Webhookも独立した有効化フラグが必要**で、チャンネルペインのWebhookエントリを有効化しないと使えない仕組みだ。Telegramと同じパターン。

順を追って有効化する。

まずチャンネルペインに戻ってリストを下にスクロールし、`Webhook`エントリを探す。

![チャンネル一覧でWebhookエントリ発見(Enabledバッジなし+「Receive events from GitHub, GitLab, and other webhook sources.」+CONFIGURE)](/images/hermes-vps/hermes-vps-08-dashboard-channels-webhook-disabled.png)

「Receive events from GitHub, GitLab, and other webhook sources.」と説明された行がそれだ。`CONFIGURE`を押すと設定モーダルが開く。

![CONFIGURE WEBHOOKSモーダル(ENABLE WEBHOOKS=true+WEBHOOK PORT=8644+WEBHOOK SECRET伏字+Cancel/SAVE & ENABLE)](/images/hermes-vps/hermes-vps-08-dashboard-channels-webhook-configure-modal.png)

3フィールドを入力する。

- **ENABLE WEBHOOKS**=`true`
- **WEBHOOK PORT**=`8644`(デフォルト)
- **WEBHOOK SECRET**=VPSで`openssl rand -hex 32`で生成した64文字の16進文字列(HMAC SHA256署名検証用)

`WEBHOOK_SECRET`はとても大事な値だ。GitHubなどがwebhookペイロードに署名するときに使うシークレットで、漏れると外部から偽イベントを投げられてしまう。生成したら必ず1Password vaultに保管しておく。

:::message
僕の場合は1Password vault「Hermes-Prod」に第3回でService Accountを作ったので、そこに新しいアイテム`Hermes VPS - Webhook HMAC Secret`を追加して保管している。第3回・第5回からの「Hermes VPS - 用途名」命名規則のまま。
:::

`SAVE & ENABLE`を押して、チャンネル一覧に戻るとWebhookが緑のEnabledに変わる。

![チャンネル一覧でwebhookがEnabledに(緑バッジ+Test/CONFIGURE)](/images/hermes-vps/hermes-vps-08-dashboard-channels-webhook-enabled.png)

右上の`RESTART GATEWAY`を押してgatewayを再起動。Webhooksペインに戻ると警告バナーが消えている。

![Webhooks画面のafter状態(警告消えた+🔔 Subscriptions (0)+「No webhook subscriptions yet」+右上「+ NEW SUBSCRIPTION」)](/images/hermes-vps/hermes-vps-08-dashboard-webhooks-platform-enabled.png)

これで`+ NEW SUBSCRIPTION`から個別購読を作れる状態になった。

:::message alert
ただし、ここまではあくまで**Dashboard側の受け口を有効化**したところまで。Tailscale IPは外部公開されないネットワーク内のアドレスなので、GitHub等の外部サービスから直接たたいてもらうには、**別途公開IPかTailscale Funnel/reverse proxy**等の経路が必要になる。実用例(GitHubのpushでHermesを起こす)までは、別の回で扱う予定。この回ではプラットフォーム自体を有効化するところまでを確認する。
:::

「チャンネルで受け口を有効化して、Webhooksで個別購読を作る」=2段階の設計だ。

### ペアリング(Pairing)

「PAIRING」ペインは、messengerユーザーの承認を扱う画面。第5回でDiscord/Telegramの`allowFrom`に数値user_idを書いて運用していたものが、v0.16.0でこのUIに標準化された。

![Pairingペイン(🕐 Pending requests (0)=「No pending pairing requests.」+👤 Approved users (0)=「No approved users.」)](/images/hermes-vps/hermes-vps-08-dashboard-pairing.png)

新しいユーザーがmessengerから話しかけてきたら`Pending requests`に並ぶ。承認すれば`Approved users`に移動。`allowFrom`で数値IDを書いていた運用と両方併用できる。

## 保守──System・ドキュメント・サイドバー下部

長く使うための保守機能は、「SYSTEM」「ドキュメント」、そしてサイドバー下部にまとまっている。

### System

「SYSTEM」ペインは10のセクションが縦に並ぶ大きな画面。

![SYSTEMペイン全体(縦長スクロール・Host+Nous Portal+Skill curator+Gateway+Memory+Credential pool+Operations+Share debug report+Checkpoints+Shell hooks)](/images/hermes-vps/hermes-vps-08-dashboard-system-operations.png)

| # | セクション | 役割 |
|---|---|---|
| 1 | 🖥 Host | OS/ARCH/CPU/MEMORY/DISK/UPTIME/LOAD AVG+Check for updates+Update now |
| 2 | 🌐 Nous Portal | Tool Gateway routingとサブスクリプション状態 |
| 3 | 🌱 Skill curator | skill使用状況の定期レビュー(Pause/Run now) |
| 4 | ⏻ Gateway | START/RESTART/STOPボタン |
| 5 | 🧠 Memory | MEMORY.md/USER.mdのサイズ+Reset個別+Reset all |
| 6 | 🔑 Credential pool | providerごとの複数キーローテーション(キーペインとは別) |
| 7 | △ Operations | 7種のワンクリック保守:Run doctor/Security audit/Create backup/Update skills/Prompt size/Support dump/Migrate config |
| 8 | 🔗 Share debug report | Generate share link+バックアップから復元 |
| 9 | 🗄 Checkpoints | `/rollback` shadow storeのPrune |
| 10 | >_ Shell hooks | 任意のシェルコマンドをイベントで起動(consent checkbox必須) |

10番目の`Shell hooks`は強力な機能だ。指定イベント(Hermesが特定の操作をしたタイミング等)で**任意のシェルコマンドを実行**する。これは便利だが、間違えればVPS上で何でも実行できてしまうので、`+ NEW HOOK`ボタンで開くモーダルにはconsent checkboxがあり、チェックしないと作成できない安全装置になっている。

:::message
Memory/Credential pool/Checkpoints/Nous Portal/Skill curator/Shell hooksの実操作は、連載の保守回(後半)で扱う。この回ではセクションを見るだけで十分。
:::

### ドキュメント(Documentation)

「ドキュメント」ペインは、公式ドキュメント(`hermes-agent.nousresearch.com/docs/`)をdashboard内のiframeで開く画面。

![ドキュメントペイン(公式docs全体がiframeに埋め込み・上部ナビDocs/Skills/Download+右上の外部リンク群+左の docsサイドバー+メインに「Hermes Agent」ページ+Install手順)](/images/hermes-vps/hermes-vps-08-dashboard-documentation.png)

タブを切り替えずにdashboard内で公式docを参照できて、右上の外部リンクボタンで普通のブラウザタブでも開ける。

### サイドバー下部の常時アクション群

サイドバーの最下部を改めて見ておく。

![サイドバー下部クロップ(システム/ゲートウェイの状態:実行中/アクティブなセッション数/ゲートウェイを再起動/Hermesを更新/HERMES TEAL/日本語/admin via basic+logoutアイコン/v0.16.0+Nous Research)](/images/hermes-vps/hermes-vps-08-dashboard-sidebar-bottom.png)

ペインを開かずに押せるアクションが、上から順に並ぶ。「ゲートウェイを再起動」と「Hermesを更新」は、CLIで`hermes gateway restart`や`hermes update`を打つのと同じだ。

`HERMES TEAL`をクリックすると、テーマとフォントが同じドロップアップに統合されたメニューが開く。

![Theme switcher展開(7テーマがドロップアップに並ぶ・HERMES TEALに緑チェック+区切り線下にFontセクションも同時表示)](/images/hermes-vps/hermes-vps-08-dashboard-theme-switcher.png)

7種のテーマ(Hermes Teal/Midnight/Ember/Mono/Cyberpunk/Rosé/nous-blue)+5種のフォント(System Sans/Sila Italic/With Pro Sans/Albatross Hypertraffic/Old Sans)を1つのスイッチャーで切り替えられる。terminal background色もテーマに連動する。

## 動作確認──ブラウザの変更がCLIに出る

この回の山場だ。**ブラウザで設定を1つ変えて、VPSの`config.yaml`にも同じ変更が出る**ことを目視で確認する。これで「Dashboardは別物でなく、同じHermesの管制室」だと胸を張れる。

サイドバーで「設定」を開き、左カラムで「表示」カテゴリを選ぶ。`RESUME EXCHANGES`の値を`10`から`20`に変えて、右上の「保存」ボタンを押す。

![設定ペインでRESUME EXCHANGESを10→20に変更+右上の保存ボタン](/images/hermes-vps/hermes-vps-08-dashboard-config-saved-browser.png)

つぎにVPSのターミナルで確認する。

```bash
grep -A1 resume_exchanges ~/.hermes/config.yaml
```

出力:

![CLIでgrepするとresume_exchanges: 20が赤色強調で表示+次行にresume_max_user_chars: 300](/images/hermes-vps/hermes-vps-08-dashboard-config-cat-cli.png)

`resume_exchanges: 20`が`config.yaml`に書き込まれている──ブラウザのフォームで触った値が、SSH越しの`grep`でちゃんと見える。これで「同じHermesの管制室を別の窓から触っていた」ことが目に見える形で証明された。

:::message
逆方向(`.env`の値を変えてHermes側で再読み込みする)には、CLIで`/reload`スラッシュコマンドが使える。キーを更新したあとに`/reload`を打つと、gateway再起動なしで`~/.hermes/.env`を読み直してくれる。
:::

## どこからでも同じ1体のエージェント

第7回でも触れたとおり、Telegram・Discord・ターミナル(SSH)・Desktop──窓は違っても、中にいるのは同じ1体・同じ記憶のエージェントだ。

第8回でDashboardが加わったあとも、これは変わらない。

- 第6回:Telegram/Discordから話しかけられる
- 第7回:Desktopアプリで話せる
- 第8回:**ブラウザの「チャット」タブからも話せる**

「チャット」タブで送ったメッセージは、`hermes --continue`したCLIにも、Hermes Desktopの左サイドバーにも、同じセッションとして表示される。**どの窓から覗いても、奥にいるエージェントは1体**だ。

Hermesは「分散」したのではなく、「窓を増やした」だけ。設定もキーもジョブも、`~/.hermes/`配下の同じファイルから読まれていて、Dashboardでもターミナルでも同じ実体を触っている。

## 最終確認チェックリスト

- [ ] ブラウザで`http://<tailscale-ip>:9119`を開いてサインインできた
- [ ] サイドバー下部の言語スイッチャーで日本語に切り替えた
- [ ] サイドバーに「チャット」「セッション」「モデル」「ログ」「CRON」「スキル」「プラグイン」「MCP」「CHANNELS」「WEBHOOKS」「PAIRING」「プロファイル」「設定」「キー」「SYSTEM」「ドキュメント」が並んでいる
- [ ] サイドバー下部に「ゲートウェイの状態: 実行中」(緑)が表示されている
- [ ] サイドバーを折りたたんで再展開した
- [ ] テーマを別の色に切り替えてみた(Hermes Teal以外を試したらまたHermes Tealに戻した、等)
- [ ] 「設定」→「表示」カテゴリで何か1つ値を変えて「保存」が効いた
- [ ] VPS側で`grep`したら、ブラウザで変えた値が同じく見える
- [ ] 「分析」を見たかったら「設定」→`analytics`検索でトグルON→F5でサイドバーに「分析」が現れた
- [ ] チャンネルペインでTelegramの`CONFIGURE`→`SAVE & ENABLE`で「引き取り」した(=`config.yaml`に`telegram.enabled: true`が書き込まれた)
- [ ] チャンネル→Webhook→`CONFIGURE`→3フィールド入力→`SAVE & ENABLE`でWebhookプラットフォームを有効化した
- [ ] WEBHOOK SECRETを1Password vault「Hermes-Prod」に`Hermes VPS - Webhook HMAC Secret`として保管した

## よくあるエラーと対処

| 症状 | 対処 |
|---|---|
| ブラウザで`http://<tailscale-ip>:9119`が開けない | 第7回のdashboardが落ちている可能性。VPSで`systemctl --user status hermes-dashboard`を確認。activeでなければ`systemctl --user restart hermes-dashboard`。母艦とVPSが同じtailnetにいるかも確認 |
| サインインの代わりに「session token」を求められる | username/password認証が有効になっていない。第7回「ログイン情報を先に`.env`へ置く」の手順で`HERMES_DASHBOARD_BASIC_AUTH_USERNAME`と`HERMES_DASHBOARD_BASIC_AUTH_PASSWORD`が`.env`に入っているか確認 |
| ログインが毎回切れる | `HERMES_DASHBOARD_BASIC_AUTH_SECRET`が未設定。固定値を`.env`に入れる(第7回「ログイン情報を先に`.env`へ置く」)。未設定だと再起動の度に署名鍵が再生成されて全セッションが無効化される |
| 「分析」がサイドバーに出ない | `dashboard.show_token_analytics: true`にしないと出ない仕様。「設定」→`analytics`検索でトグルON→F5 |
| チャンネル一覧でTelegram/DiscordがDisabled | `config.yaml`の`{platform}.enabled: true`が立っていないため。`CONFIGURE`→`SAVE & ENABLE`で明示的に有効化する。CLI設定だけでは`.env`に値があってもDashboardはDisabled表示 |
| Webhooksペインで`Webhook platform disabled` | Webhookも独立した有効化が必要。CHANNELS→Webhook→CONFIGURE→3フィールド入力→SAVE & ENABLE |
| 「チャット」タブが動かない | v0.16.0でブラウザ内チャットは常時有効。`config.yaml`にフラグを書く必要はない(書いても無視される)。VPS側はLinuxなので問題ないはず |
| `RESTART NOW`を押しても変更が効かない | ブラウザのキャッシュ。Ctrl+F5でハードリロード |
| ドキュメント内のサブパスが404 | web-dashboardの公式docsは1枚物のページに集約されている仕様 |

## 早見表

| やりたいこと | やる場所 |
|---|---|
| バージョン確認 | サイドバー左下のv0.16.0 / SYSTEMペインの🖥 Host |
| 設定変更 | 設定ペイン+フォーム |
| YAMLを直接見たい | 設定ペイン+右上トグルでYAMLモード |
| APIキー追加 | キーペイン+「設定」ボタン |
| OAuth接続 | キーペイン+「プロバイダーログイン」セクション+「ログイン」ボタン |
| Cronジョブ追加 | CRONペイン+「作成」(詳しくは第9回) |
| スキル追加 | スキルペイン+「Hub」ビュー(詳しくは第10回) |
| MCP追加 | MCPペイン+「ADD SERVER」または「Catalog」のINSTALL |
| Telegram/Discord有効化 | チャンネルペイン+CONFIGURE+SAVE & ENABLE |
| Webhook作成 | チャンネルペインでWebhook有効化→Webhooksペインで「+ NEW SUBSCRIPTION」 |
| Hermes本体を更新 | サイドバー下部「Hermesを更新」 or SYSTEMの🖥 Host+Update now |
| ゲートウェイ再起動 | サイドバー下部「ゲートウェイを再起動」 or SYSTEMの⏻ Gateway+RESTART |
| 障害報告用ダンプ生成 | SYSTEMの🔗 Share debug report+Generate share link |
| 過去のセッションを再開 | セッションペインで該当行の▶ボタン |
| 公式docsを読む | ドキュメントペイン |

## 補足:v0.17.0「The Reach Release」でDashboardはさらに強化された

本記事はv0.16.0「Surface Release」での執筆だが、2026-06-19公開の**v0.17.0**「The Reach Release」でWeb Dashboardに大きな変化が入った。

1. **Profile Builder追加**=`config.yaml`を手で書き換えなくても、ブラウザからmodel/skills/MCP serverを選んでプロファイルを組める。複数プロファイルを1画面で管理するglobal switcherも追加。第14回(Quick Setup)で詳しく扱う予定だ。
2. **Secure Login**=token必須エンドポイントはOAuth gate裏で正しく401を返し、WebSocket認証もdashboard token経由になった。`public_url`オーバーライドがあると暗黙のreject時に警告が出る。Dashboardをネットワーク公開する運用がデフォルトで安全になった。
3. **Subagent Watch-Windows**=委譲したサブエージェントの活動を専用ペインで並列ストリーム表示できる。第18回(Claude Code/Codex連携)で本格的に使う。
4. **VS Code Marketplace Theme導入**=任意のVS Codeテーマをそのままインストールできる。プロファイル別テーマ割り当ても可能。

本記事のスクショ・手順はv0.16.0時点の画面なので、v0.17.0では一部UIが変わっている。`hermes update`で本体を最新に保ち続けていれば、自動で反映される。

## まとめと次回予告

第7回でHermes Desktopを母艦に入れて、第8回でWeb Dashboardをブラウザで開けるようになった。これでHermesと話す窓は3つになった。

1. Telegram/Discord(第4回・第5回)=スマホからもPCからも
2. Hermes Desktop(第7回)=母艦のネイティブアプリで
3. **Web Dashboard(この回)=ブラウザで管制室を開いて、設定もキーも全部管理する**

第7回・第8回で「窓と顔と管制室」が揃った。ここから先は、この相棒に技能を足していく。

次回からは生活リズム(Cron)・手順の記憶(スキル)・外の情報を取る目(Web/X検索)へ進む。今日見たCRON画面やスキル画面が、実際に中身で埋まっていく。

第9回(Cron)では、いま空のように見えていたあのCRONペインに、毎朝Hermesがニュースを届けてくれるジョブを登録する。Dashboardから新規ジョブを作って、`Trigger now`で即実行、Telegramに通知が届く──までを1本でやる。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第7回 Hermes Agentをデスクトップアプリで操作する方法](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop) | [第9回 Hermes Agentに毎朝のタスクを自動実行させる](https://zenn.dev/sora_biz/articles/hermes-vps-09-cron) |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## 公式ドキュメント引用元

| 項目 | 引用元 |
|---|---|
| Web Dashboard全般 | [web-dashboard](https://hermes-agent.nousresearch.com/docs/user-guide/features/web-dashboard) |
| v0.16.0リリースノート | [v2026.6.5 The Surface Release](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.6.5) |
| サイドバー実装(ペイン並び順) | [web/src/App.tsx](https://github.com/NousResearch/hermes-agent/blob/v2026.6.5/web/src/App.tsx) |
| ブラウザ内チャット常時有効の実装根拠 | [web/src/lib/dashboard-flags.ts](https://github.com/NousResearch/hermes-agent/blob/v2026.6.5/web/src/lib/dashboard-flags.ts) |
| Auxiliary Tasks 11枠の定義 | [web/src/pages/ModelsPage.tsx](https://github.com/NousResearch/hermes-agent/blob/v2026.6.5/web/src/pages/ModelsPage.tsx) |
| Cron配信先5択 | [web/src/pages/CronPage.tsx](https://github.com/NousResearch/hermes-agent/blob/v2026.6.5/web/src/pages/CronPage.tsx) |
| Hermes Desktop(第7回参照) | [desktop](https://hermes-agent.nousresearch.com/docs/user-guide/desktop) |
