---
title: "【第7回】SSHはもう開くな。Hermes Agentはデスクトップアプリから直接話せる"
emoji: "🤖"
type: "tech"
topics: ["ai", "hermes", "desktop", "tailscale", "vps"]
published: true
---

:::message
この連載は月1,800円ほどのVPSで、自分専用のAIエージェント(Hermes Agent)を24時間動かす実録だ。これはその第7回。全体の流れは[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::

## 目次

- [この回の到達点](#この回の到達点)
- [ターミナルとHermes Desktopの関係](#ターミナルとhermes-desktopの関係)
- [第7回終了時点の構成図](#第7回終了時点の構成図)
- [事前準備](#事前準備)
- [VPS側で接続先のdashboardを常駐させる](#vps側で接続先のdashboardを常駐させる)
- [母艦にHermes Desktopを入れる](#母艦にhermes-desktopを入れる)
- [アプリが起動しないときの直し方](#アプリが起動しないときの直し方)
- [VPSのHermesにリモート接続する](#vpsのhermesにリモート接続する)
- [Hermes Desktopの基本操作](#hermes-desktopの基本操作)
- [どの入口でも同じ1体のエージェント](#どの入口でも同じ1体のエージェント)
- [最終確認チェックリスト](#最終確認チェックリスト)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [コマンド早見表](#コマンド早見表)
- [引用元と参考](#引用元と参考)

第6回で、Hermes Agentは24時間VPSに常駐するようになった。SSHを切ってもVPSを再起動しても、Telegram/Discordに話しかければ返事が返る。

ただ、ここまでHermesに触れる窓口はずっとSSHのターミナル——黒い画面のままだった。コマンドを打ち、コマンドを覚え、打ち間違えればやり直す。慣れればなんてことはないが、「黒い画面が苦手」という理由だけでAIエージェントから足が遠のく人は多い。

第7回は、その同じHermesをマウス操作でも動かせるようにする。母艦(普段使いのWindowsノートPC)に公式デスクトップアプリ「Hermes Desktop」を入れ、Tailscale越しにVPSのHermesへ繋ぐ。2026-06-05のv0.16.0で正式リリースされた、机の上に出てきたばかりのアプリだ。

大事なのは、別のAIを入れるわけではないこと。CLI・Hermes Desktop・Web Dashboardは、同じ1体のエージェントの別の入口にすぎない。片方で設定したことは、もう片方にもそのまま出る。

シリーズの全体像はこちら。

:::details シリーズのもくじ(タップで開く)

**第I部 体を作る**
- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy) サーバー代は月1,800円で足りる。Hermes AgentはVPSで24時間動き続ける
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale) パスワードはもう打つな。Hermes AgentへのSSHは鍵一発で入れる
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password) APIキーをそのまま書くな。Hermes Agentの秘密は1Passwordが預かる
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install) Hermes AgentをDockerで隔離して動かす方法
- [第5回](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord) コマンドを覚えるな。Hermes AgentはDiscordで話しかけるだけで動く
- [第6回](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd) 気づいたら止まっている、をなくせ。Hermes Agentはsystemdでいつも動き続け、落ちてもすぐ戻る

**第II部 顔と操作席**
- **第7回**(本記事) SSHはもう開くな。Hermes Agentはデスクトップアプリから直接話せる
- [第8回](https://zenn.dev/sora_biz/articles/hermes-vps-08-dashboard) 手探りで動かすな。Hermes Agentはブラウザ1枚で中身が見える

**第III部 生活リズム**
- [第9回](https://zenn.dev/sora_biz/articles/hermes-vps-09-cron) いつもの作業を毎回自分でやるな。Hermes Agentが決めた時刻や間隔で自動でこなす
- [第10回](https://zenn.dev/sora_biz/articles/hermes-vps-10-skills) 毎回教えるな。Hermes Agentは使えば使うほど自分で賢くなる
- [第11回](https://zenn.dev/sora_biz/articles/hermes-vps-11-web-search) 気になる情報を自分で探し回るな。Hermes Agentがネットで調べて要点だけまとめてくれる

**第IV部 記憶を分けて育てる**
- [第12回](https://zenn.dev/sora_biz/articles/hermes-vps-12-memory) 好みを毎回言うな。Hermes AgentはMemoryで覚えている
- [第13回](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) メモを自分で探すな。Hermes AgentはObsidianを記憶として読む
- [第14回](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) 毎回最初から話すな。Hermes Agentは前回の続きからそのまま動く
- [第15回](https://zenn.dev/sora_biz/articles/hermes-vps-15-import-ai-sessions) 記憶を捨てるな。Hermes AgentはClaude Codeの続きを引き継ぐ

全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

所要時間の目安は60〜90分(うち初回のweb UIビルド待ちが数分)。VPS側でひと手間、母艦側でアプリを入れて繋ぐ、という二段構えになる。

## この回の到達点

第6回完了時と第7回完了後の差分を表にする。

| 項目 | 第6回完了時 | 第7回完了後 |
|---|---|---|
| 操作手段 | SSHのターミナル(CLI)だけ | **母艦のHermes Desktop**(GUIアプリ)が加わる |
| ファイルを渡す | パスを指定 | **チャットにドラッグ&ドロップ**・画像はコピペ |
| 操作を探す | コマンドを覚える | **Ctrl+K**(MacではCmd+K)で検索 |
| モデル切替 | `hermes model` | **status barのモデルピッカー**(数文字で検索) |
| 接続経路 | — | Hermes Desktop → Tailscale → VPSの`hermes dashboard` |
| 同じ1体の実証 | (意識しない) | **Telegram/Discordの会話がDesktopにも並ぶ** |

第7回でやることを一言でまとめると「VPSに住む同じHermesを、黒い画面だけでなく普通のアプリの窓からも触れるようにする」。

## ターミナルとHermes Desktopの関係

ここまでHermesはターミナル(黒い画面)でしか操作できなかった。この回でやるのは、その同じHermesをマウス操作でも動かせるようにすること。繰り返すが、別のAIを入れるのではない。同じ1体に、電話(CLI)と対面(GUI)の両方で話せるようになる、というイメージが近い。

### v0.16.0「The Surface Release」で何が変わったか

Hermes Desktopは2026-06-05のv0.16.0で正式リリースされた、macOS/Windows/Linux対応のネイティブアプリだ。「Surface(表に出る)」の名のとおり、これまでターミナルの中にいたHermesが、普通のアプリとして机の上に出てきた回といえる。アプリ内での自己更新・ファイルのドラッグ&ドロップ・Ctrl+Kコマンドパレット・status barでのモデル切替などが入った。

### この回で出てくる用語

| 用語 | 意味 | たとえ |
|---|---|---|
| 母艦 | 普段使いのWindowsノートPC。Hermes Desktopを動かし、VPSへ繋ぐ側。VPS・自宅GPU機とは別のマシン | 艦隊の母港。ここから各艦に指示を出す |
| Hermes Desktop | 母艦で動く公式デスクトップアプリ。CLIと同じエージェント核を使う(同じ設定・セッション・スキル・記憶) | いつもの相棒に、アプリの窓からも話しかけられる |
| Web Dashboard | `hermes dashboard`で立ち上がるブラウザ用の管理画面。この回ではDesktopの接続先として使い、管理機能の詳細は第8回で扱う | サーバーの管制室。今回は通り道、次回じっくり |
| リモートバックエンド | Hermes Desktopが繋ぐ接続先。実体はVPS上で動く`hermes dashboard`プロセスそのもの | 手元のアプリが、遠くのサーバーに繋ぐ |
| 認証ゲート | dashboardを外向きアドレスに開くと自動でかかるログイン要求。ユーザー名/パスワードで通す | 建物の入口の鍵 |

### 頭に入れる2つの「別物」

ここで混乱しやすい2点を先に潰しておく。

**1つ目、dashboard ≠ gateway**。Desktopが繋ぐのは`hermes dashboard`であって、第6回で常駐させたgateway(Telegram係)ではない。両者は別プロセスとして同時に動く。

**2つ目、Desktopは接続先を起動してくれない**。VPS側の`hermes dashboard`は自分でsystemdで常駐させる(この回の前半)。母艦のHermes Desktopは、そこに「繋ぎに行く」だけだ。

## 第7回終了時点の構成図

母艦・Tailscale・VPSの3つに焦点を絞った構成。

![第7回の構成図。母艦のHermes DesktopがTailscale(暗号化された専用通路)経由でVPSのhermes dashboardに接続・認証し、同じエージェントの状態を共有する。VPSにはhermes-gatewayも別プロセスで常駐し、Telegram/Discordを捌いている](/images/hermes-vps/hermes-vps-07-desktop-diagram.png)

ポイントは、AI本体はVPSに住み続け、母艦には「見るための窓」を置くだけという構図。母艦は窓であって頭脳ではない。だから母艦の電源を切っても、VPS上のHermesはTelegram/Discordで動き続ける。

## 事前準備

まずVPSにSSHで入り直し、第6回の常駐が生きていることを確認する。あわせて、この回で何度も使うVPSのTailscale IPを控えておく(後でdashboardのbind先・Desktopの接続先になる)。

```powershell
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps
```

入れたら、バージョンとgatewayの稼働を1画面で確認する。

```bash
hermes version; echo; systemctl --user status hermes-gateway --no-pager | head -8
# → v0.16系 + Active: active (running) が出ればOK

tailscale ip -4   # VPS上で実行。出たTailscale IP(100.x.x.x)を控える(あとで母艦のDesktopの接続先になる)
```

:::message
`--no-pager`と`head -8`を付けているのは、素の`systemctl status`がログ末尾までスクロール表示し、そこにホスト名(グローバルIP)が出てしまうため。Active行までに絞って、画面に余計な情報を出さない。
:::

![VPSでhermes versionがv0.16系、hermes-gatewayがactive (running)を示す画面](/images/hermes-vps/hermes-vps-07-desktop-01-version-gateway.png)

第7回の手順は、ここまでで第6回までを完了している(VPSにHermesが常駐し、Telegram/Discordが繋がっている)ことを前提にする。母艦とVPSが同じtailnetにいることも確認しておく(母艦側で`tailscale status`にVPSが出る)。

## VPS側で接続先のdashboardを常駐させる

出典:[公式web-dashboard](https://hermes-agent.nousresearch.com/docs/user-guide/features/web-dashboard)

Hermes DesktopがVPSに繋ぐには、VPS側で`hermes dashboard`が動いている必要がある。この回ではdashboardを「接続先」として認証つきで常駐させるところまで。ブラウザでの管理(Cron/Skills/Memory等)は第8回でじっくり扱う。

### 管理画面の部品が入っているか確認する

v0.16.0のHermesは、dashboardに必要な部品(FastAPI/Uvicorn等)を標準で同梱している。まず入っているかを確認する。

```bash
hermes dashboard --help   # usage(使い方)が表示されれば、部品は入っている
```

usageが出れば、何も足さなくてよい。もし「部品が足りない」と言われた場合だけ、第4回でソースを置いたディレクトリで追加する。

```bash
cd ~/hermes-agent && pip install -e '.[web]'
```

![hermes dashboard --helpのusage(使い方)が表示されている画面](/images/hermes-vps/hermes-vps-07-desktop-02-dashboard-help.png)

### ログイン情報を先に`.env`へ置く

dashboardを外向きアドレス(Tailscale IP)に開くと、自動でログイン要求(認証ゲート)がかかる。

:::message alert
**認証を設定する前に外向きで起動しない**。ログイン情報が未設定のまま外向きで起動しようとすると、Hermesは安全のため起動を拒否する(fail-closed)。だから先に`.env`へ認証情報を書く。
:::

まずパスワードと署名鍵を、それぞれランダム生成する。

```bash
openssl rand -base64 24 | tr -dc 'A-Za-z0-9' | head -c 24; echo   # PASSWORD(記号を除いた英数字24文字。コピペで事故りにくい)
openssl rand -base64 32                                            # SECRET(記号込みでOK)
```

出力された2つの文字列を控えて、`.env`を開く。

```bash
nano ~/.hermes/.env
```

末尾に3行を手書きする。`PASSWORD`と`SECRET`は、上の2つの`openssl`出力をそれぞれ貼る。

```bash
HERMES_DASHBOARD_BASIC_AUTH_USERNAME=admin
HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=<上のPASSWORD用openssl出力を貼る>
HERMES_DASHBOARD_BASIC_AUTH_SECRET=<openssl rand -base64 32 の出力を貼る>
```

:::message
クォート付きheredoc(`<<'EOF'`)で流し込むと`$(...)`がそのまま文字列として入ってしまう(実機で確認済み)ので、ここはnanoで手書きするのが確実。書いたら`Ctrl+O`→`Enter`で保存し、`Ctrl+X`で閉じる。
:::

最後に、本人だけが読める権限にしておく。

```bash
chmod 600 ~/.hermes/.env
```

`SECRET`は、再起動してもログインが切れないための署名鍵だ。これが無いと、dashboardを再起動するたびにサインインがやり直しになる。

![~/.hermes/.envに3つのHERMES_DASHBOARD_BASIC_AUTH_*が追記された画面。キー名だけが見える状態](/images/hermes-vps/hermes-vps-07-desktop-03-env.png)

### 生成したパスワードを1Passwordにも保存する

dashboardのログインパスワードは長いランダム文字列で、母艦のDesktopからサインインするたびに必要になる。手打ちは現実的でないので、生成したいま、1Passwordなどのパスワードマネージャに保存しておく。後のサインインで呼び出すだけで済む。

:::message alert
VPSのOSユーザー用に`Hermes VPS - admin`や`Hermes VPS - root`を既に作っている場合、**同じadminでもこれとは別物**(こちらはdashboardのWebログイン用)。名前が被ると必ず混同するので、dashboard用は別名にする。
:::

| 1Passwordの項目 | 入れる値 |
|---|---|
| タイトル | 「Hermes VPS - dashboard (Desktop/Web)」。OSユーザー用と分かる別名にする |
| ユーザー名 | `admin` |
| パスワード | 上で生成した`HERMES_DASHBOARD_BASIC_AUTH_PASSWORD`の値 |
| メモ(任意だが推奨) | Hermes Desktop/Web Dashboardのログイン用。Tailscale経由でサインインする時に使う |

署名鍵`SECRET`はサインインには使わないので、1Passwordに入れる必要はない(`.env`にだけ置く)。1Passwordに入れるのはユーザー名`admin`とパスワードの2つだけだ。

![1Passwordで「Hermes VPS - dashboard (Desktop/Web)」を作成し、ユーザー名adminとパスワードを保存した画面。パスワードは伏字](/images/hermes-vps/hermes-vps-07-desktop-04-1password.png)

### 初回はフォアグラウンドで起動して画面をビルドする

dashboardの画面(web UI)は、初回起動時に一度だけビルドが走る。これはNode(npm)を使う処理で、systemdのような自動起動の環境ではうまく走らないことがある。だから最初の1回は手で起動して、ビルドと認証を確かめてから常駐に移す。起動には、あとでsystemdに登録するのと同じ「venv内のpythonを直接指定する」形を使う(`hermes dashboard`でも起動はできるが、後のunitファイルと書き方を揃えておくと食い違わない)。

```bash
cd ~/hermes-agent
venv/bin/python -m hermes_cli.main dashboard --host <tailscale-ip> --port 9119 --no-open
# 初回はweb UIのビルドが走る(数分)。ビルドが終わると起動する
```

:::message alert
`<tailscale-ip>`は**そのまま打たない**。山かっこごと、事前準備で控えたVPSの実際のTailscale IP(`100.`で始まる番号)に置き換える。`<`と`>`を付けたまま打つと、シェルが別の意味(リダイレクト)に解釈してエラーになる。記号ごと自分の番号にするのが正解。
:::

ビルドの進捗が流れ、しばらくすると起動する。

![hermes dashboardの初回起動でweb UIのビルド(vite build)が進んでいる画面](/images/hermes-vps/hermes-vps-07-desktop-05-build.png)

![ビルドが終わってWeb UIが起動し、待ち受けURLが表示された画面](/images/hermes-vps/hermes-vps-07-desktop-06-built.png)

別のSSHタブを開き、認証ゲートがかかっているか確認する。

```bash
curl -s http://<tailscale-ip>:9119/api/status | jq '.auth_required, .auth_providers'
# true / ["basic"] が出れば、認証つきで外向きに開けている
```

:::message alert
**認証なしで開く`--insecure`は使わない**。`--insecure`は認証ゲートそのものを飛ばして外向きにbindする逃げ道で、APIキーや秘密を誰でも読める画面を晒してしまう。`.env`に認証情報を入れていれば、`--insecure`なしでもTailscale IPに開ける(認証つきのまま外向きにできる)。本シリーズは認証+Tailscaleで閉じ、`--insecure`は使わない。
:::

![別タブでcurlした/api/statusがauth_required: trueと["basic"]を返している画面](/images/hermes-vps/hermes-vps-07-desktop-07-api-status.png)

`true`と`["basic"]`が確認できたら、`Ctrl+C`で一旦止める。ビルドは済んだので、次は自動起動に載せる。

### systemdで常駐させる

第6回と同じく、systemdのユーザーunitに登録する。`--skip-build`を付けて「ビルドは済んでいる前提で起動」にすると、systemd環境でnpmを探さずに済む。起動コマンド自体は、初回に手で打ったものに`--skip-build`を足しただけで中身は同じだ。

```bash
nano ~/.config/systemd/user/hermes-dashboard.service
```

次の内容を書く。

```ini
[Unit]
Description=Hermes Web Dashboard
After=network-online.target
Wants=network-online.target

[Service]
EnvironmentFile=%h/.hermes/.env
ExecStart=%h/hermes-agent/venv/bin/python -m hermes_cli.main dashboard --host <tailscale-ip> --port 9119 --no-open --skip-build
Restart=on-failure
RestartSec=10

[Install]
WantedBy=default.target
```

`<tailscale-ip>`はここでも実際のIPに置き換える。`EnvironmentFile`で`.env`を読み込むので、認証情報はsystemd経由でもそのまま渡る。書いたら`Ctrl+O`→`Enter`→`Ctrl+X`で保存して閉じる。

:::message
`ExecStart`の`%h/hermes-agent/venv/bin/python`は、第4回でソースを置いた場所(`~/hermes-agent/venv`)。設定の置き場`~/.hermes`とは別なので混同しない。`%h`はホームディレクトリ(`/home/admin`)に展開されるsystemdの変数。
:::

![nanoでhermes-dashboard.serviceを編集している画面。unitの中身が見える](/images/hermes-vps/hermes-vps-07-desktop-08-unit.png)

反映して起動する。

```bash
systemctl --user daemon-reload
systemctl --user enable --now hermes-dashboard
systemctl --user status hermes-dashboard --no-pager | head -8   # active (running)
curl -s http://<tailscale-ip>:9119/api/status | jq '.auth_required, .auth_providers'
# true / ["basic"] が出れば、母艦のDesktopのログインが通る状態
```

`active (running)`になり、`/api/status`が`true`/`["basic"]`を返せば、VPS側の準備は完了。もし起動に失敗するなら、`.env`に認証情報が入っているか(2つ前の手順)、venvパスが合っているか(`ls ~/hermes-agent/venv/bin/python`)を確かめる。

![systemctl --user statusでhermes-dashboardがactive (running)、別のcurlで/api/statusがtrue/["basic"]を返している画面](/images/hermes-vps/hermes-vps-07-desktop-09-systemd-active.png)

## 母艦にHermes Desktopを入れる

出典:[公式desktop](https://hermes-agent.nousresearch.com/docs/user-guide/desktop) / [installation](https://hermes-agent.nousresearch.com/docs/getting-started/installation)

ここからは母艦(普段使いのWindowsノートPC)での作業。公式サイトからインストーラを落として実行する。**管理者権限は不要**だ。

```text
ダウンロード: https://hermes-agent.nousresearch.com/desktop
→ インストーラを実行(管理者権限の確認は出ない)
→ インストール先は %LOCALAPPDATA%\hermes\、hermesがPATHに追加される
```

ダウンロードページで、自分のOS(Windows)向けのボタンを押す。

![Hermes Desktopのダウンロードページ。どのボタンを押すか分かる画面](/images/hermes-vps/hermes-vps-07-desktop-10-download.png)

インストーラを起動する。管理者権限の確認(UAC)は出ない。

![インストーラの開始画面。Install Hermesのボタンとインストール先が見える](/images/hermes-vps/hermes-vps-07-desktop-11-install-start.png)

ファイルの展開が進む。

![インストール進捗の画面。進捗バーが動いている](/images/hermes-vps/hermes-vps-07-desktop-12-install-progress.png)

完了すると、アプリを起動できる状態になる。

![インストール完了の画面。Hermes is Ready / Launch Hermesが表示されている](/images/hermes-vps/hermes-vps-07-desktop-13-install-done.png)

起動すると、最初の画面(オンボーディングまたはチャット)が出る。

![Hermes Desktopの初回起動画面。アプリのトップと左サイドバー](/images/hermes-vps/hermes-vps-07-desktop-14-first-launch.png)

:::message
CLIだけ先に入れている場合は、ターミナルで`hermes desktop`でも起動できる(初回はElectronアプリのビルドが走るので時間がかかる)。v0.16.0からはアプリ内で自己更新できるので、一度入れれば更新はアプリ任せにできる。
:::

## アプリが起動しないときの直し方

:::message
ここは起動でつまずいた人向けの章。問題なく起動できた人は、読み飛ばして次へ進んでよい。
:::

インストールは完了したのに、アプリが起動しない——私もこれに当たった。ダブルクリックしてもウィンドウが出てこない。ChromeやEdgeは普通に開くのに、Hermes Desktopだけが反応しない。

自分では何が悪いのか見当もつかなかったので、Claude Codeに「Hermes Desktopのインストールは完了したが起動しない。原因を調査して」と投げた。

Claude Codeはまずアプリのログ(`desktop.log`)を調べて、`render-process-gone reason=crashed exitCode=-2147483645`という異常終了の痕跡を見つけた。この終了コード(`0x80000003`)でGitHubのissueを検索し、公式issue [#38216](https://github.com/NousResearch/hermes-agent/issues/38216)にたどり着いた。原因はこうだ。

Hermes Desktopの土台にはElectron(中身はChromium、Chromeと同じ描画エンジン)が使われている。そのChromiumの「サンドボックス機能」が、一部のGPU(私の場合はIntel Iris Xe)とドライバの組み合わせで、画面を描くプロセスごと異常終了させてしまう。ChromeやEdgeは独自にこの問題を回避しているが、Electron系アプリ(Hermes・Notion・Discord等)は回避策が入っていないため起動しない。実際、私のPCではNotionも同じ症状で起動しなかった。

issue #38216の報告者が試した結果はこうだ。

- そのまま起動 → 起動しない
- `--disable-gpu`(GPUを切る) → 起動しない
- **`--no-sandbox`(サンドボックス機能を切る) → 完全に安定動作**

これもClaude Codeに「ショートカットを作って」と頼んだ。やることはシンプルで、デスクトップにショートカットを作り、「リンク先」の末尾に`--no-sandbox`を足すだけだ。

| ショートカットの設定 | 値 |
|---|---|
| リンク先 | `%LOCALAPPDATA%\hermes\...\Hermes.exe --no-sandbox` |
| ポイント | 実行ファイルの後ろに半角スペースと`--no-sandbox`を付ける |

:::message
自分でショートカットを作る場合は、デスクトップを右クリック→「新規作成」→「ショートカット」で、リンク先にHermes.exeのフルパスと`--no-sandbox`を入れる。パスが分からなければClaude Codeに「Hermes Desktopのショートカットを`--no-sandbox`付きで作って」と頼めば、パスの特定からショートカットの作成まで一発でやってくれる。
:::

これで起動した。

何度も起動を試みた後だと、壊れたキャッシュが残っていることがある。ショートカットを作っても起動しない場合は、次の2つのフォルダを消してから試す。

- `%APPDATA%\Hermes\GPUCache`
- `%APPDATA%\Hermes\Code Cache`

エクスプローラのアドレスバーに`%APPDATA%\Hermes`と打てばフォルダが開く。`GPUCache`と`Code Cache`を削除してからショートカットで起動すると、キャッシュが初期化された状態で立ち上がる。

:::message
`--no-sandbox`が切るのは、あくまでHermes Desktopの画面描画プロセスのサンドボックス機能だけ。第4回で設定したエージェントのコマンド実行(Dockerコンテナ隔離)とは別の話で、エージェント側の安全境界は何も変わらない。とはいえブラウザ由来の保護を1枚はがすのは事実なので、最終的にはGPUドライバを最新に更新して、`--no-sandbox`なしで起動できる状態を目指すのがよい。
:::

## VPSのHermesにリモート接続する

出典:[公式desktop](https://hermes-agent.nousresearch.com/docs/user-guide/desktop)「In the app」

インストールしたHermes Desktopを起動すると、最初は母艦のローカルバックエンドで立ち上がる。ただし母艦には**モデルの鍵(頭脳)がない**ので、このままチャットしてもモデル認証エラーになる。

だから最初にやるのは、VPSに常駐させた`hermes dashboard`に繋ぎ替えること。「AI本体はVPSに住み、母艦には見るための窓を置く」構成にする。繋ぎ替えれば、モデルの鍵もVPS側のものが使われ、チャットが通るようになる。

設定画面は、右上の歯車アイコン(⚙)から開く。

![Hermes Desktopの初回起動画面。右上の歯車アイコン(⚙)を赤枠と矢印で示している](/images/hermes-vps/hermes-vps-07-desktop-14b-settings-icon.png)

### Remote URLを入れてサインインする

| 操作 | 入力 |
|---|---|
| 設定を開く | **Settings → Gateway → Remote gateway** |
| Remote URL | `http://<tailscale-ip>:9119`(VPSのTailscale IP) |
| サインイン | **Sign in**ボタン → `admin`とパスワードを入力 |
| 確定 | **Save and reconnect** |

:::message alert
`<tailscale-ip>`はそのまま打たない。山かっこごと、VPSの実際のTailscale IP(`100.x.x.x`の形)に置き換える。例えばTailscale IPが`100.101.102.103`なら、`http://100.101.102.103:9119`と入れる。
:::

パスワードは、先ほど1Passwordに保存したdashboardのパスワードをここで呼び出して貼り付ける。長いランダム文字列なので手打ちしない。

![Settings → Gateway → Remote gatewayを選び、Remote URLを入力したところ。左の設定メニュー、Remote URL欄、Sign inボタンが1画面に見える](/images/hermes-vps/hermes-vps-07-desktop-15-settings-gateway.png)

![サインインのフォーム。admin欄が見え、パスワードは伏字](/images/hermes-vps/hermes-vps-07-desktop-17-signin.png)

:::message alert
**ここが今回いちばんハマるポイント**。Signed inのあと、必ず「**Save and reconnect**」を押す。これを押さないとDesktopは母艦ローカルのままでVPSに切り替わらず、チャットがモデル認証エラー(ローカル側のモデルを見にいって失敗)になる。切り替わると画面下のモデル表示がVPS側のモデルに変わるので、それが成功の目印だ。
:::

#### OAuthとユーザー名/パスワードの違い

Hermes Desktopは2つの認証方式に対応する。

- **ユーザー名/パスワード**:TailscaleやLANなど信頼できるネットワーク内向け。本シリーズはこれ(Tailscale前提)。インターネットにそのまま晒す用途では使わない。
- **OAuth**(Nous Portal等):VPSを公開ホストとして晒す場合向け。

どちらも`--insecure`(認証なし)とは違う。本シリーズはTailscale+ユーザー名/パスワードで閉じる。

### 接続できたことを確認する

接続が成功すると、Desktopの中身がVPSのHermesに切り替わる。画面下のモデル表示がVPS側のモデルに変わっていれば成功だ。設定画面を閉じてメイン画面に戻ると、左サイドバーにもVPS側のデータが見えるようになる。

![リモート接続が成功し、GatewayのAuthenticationがSigned inになった画面。VPSのHermesに繋がった証拠](/images/hermes-vps/hermes-vps-07-desktop-18-signed-in.png)

:::message
**将来への伏線**:v0.16.0のHermes Desktopは、複数のprofile(担当)を1つのウィンドウで同時に動かせる。例えば「普段の相棒」「Zenn原稿の編集者」「VPS運用担当」のように分ける。今回は「将来こう分けられる」という入口を見ておくだけで十分。本格的な役割分担は後の回で扱う。
:::

## Hermes Desktopの基本操作

VPSに繋がって頭脳が動くようになった。設定画面を閉じてメイン画面に戻ると、左サイドバーにVPS側のチャット履歴やCronジョブが並んでいるのが見える。母艦単独の時は空だったサイドバーにデータが入っていれば、VPSのHermesに繋がった証拠だ。第4〜6回でTelegramやDiscordから送った会話、第9回で設定するCronの定期タスクなど、VPSのHermesが持っているデータがそのまま見える。

ここからはDesktopアプリそのものの触り方を押さえる。ここがv0.16.0で一番厚くなった部分で、「ターミナルのコマンドを覚える」から「アプリを普通に使う」へ変わる。

### チャットする

中央のチャット欄に書いて送るだけ。応答はリアルタイムに流れ(streaming)、左サイドバーに会話(session)が一覧で残る。過去の会話は検索・再開できる。

![チャットで送信すると応答がstreamingで返り、左サイドバーに会話一覧が見える画面。左サイドバーのセッション名はモザイク](/images/hermes-vps/hermes-vps-07-desktop-19-chat.png)

### ファイルを渡す(ドラッグ&ドロップ・画像コピペ)

v0.16.0では、チャット欄にファイルを**ドラッグ&ドロップ**するだけで添付できる。スクリーンショットは**クリップボードから直接貼り付け**(Ctrl+V)できる。「ファイルパスを指定する」必要がなくなった。

![PDFやテキストをチャット欄にドラッグ&ドロップして添付しているところ。左サイドバーのセッション名はモザイク](/images/hermes-vps/hermes-vps-07-desktop-20a-drag-drop.png)

![スクリーンショットをコピーしてCtrl+Vでチャット欄に貼り付けたところ。左サイドバーのセッション名はモザイク](/images/hermes-vps/hermes-vps-07-desktop-20b-paste-image.png)

### 迷ったらCtrl+K(コマンドパレット)

どこを押せばいいか分からなくなったら**Ctrl+K**(Macでは`Cmd+K`)。検索窓に「model」「skill」「new chat」のように打つと操作が見つかる。ターミナルのコマンドを覚えなくてよい道案内だ。

![Ctrl+Kで開いたコマンドパレット。検索窓とGO TO/コマンド一覧が見える状態。左サイドバーのセッション名はモザイク](/images/hermes-vps/hermes-vps-07-desktop-21-command-palette.png)

### モデルを切り替える

v0.16.0では画面下のstatus barにモデルピッカーがある。しかも**あいまい検索**(fuzzy search)対応で、数文字打てば候補が出る。モデル名を全部覚えなくてよい。いつも最強モデルにせず、相談・文章・調査で場面ごとに切り替えるのがコツ。

![status barのモデルピッカー。あいまい検索で数文字打って候補が出ている。左サイドバーのセッション名はモザイク](/images/hermes-vps/hermes-vps-07-desktop-22-model-picker.png)

:::message
**覚えておくと安心、`/undo`**:変な方向に頼んでしまったら`/undo`で直前のN回の会話を巻き戻せる(v0.16.0)。ただし会話を戻すだけで、すでに送信したメール・削除したファイル・外部サービスで実行された操作まで取り消すわけではない。会話のやり直しと、外部操作の取り消しは別物だと覚えておく。
:::

## どの入口でも同じ1体のエージェント

この回の山場。Hermes Desktopの左サイドバーには、Desktopで送った会話だけでなく、**前の回で連携したTelegramやDiscordで送った会話も、同じ一覧に並ぶ**。

Telegram・Discord・ターミナル(SSH)・Desktop——窓は違っても、中にいるのは同じ1体・同じ記憶。これがHermesの本質で、「似たアプリを4つ別々に使う」のとは決定的に違う。

確かめ方は簡単。普段使っているTelegram(またはDiscord)で、Hermesに一言送ってみる。

```text
(Telegramで) 接続テスト。いま何時か教えて。
```

![Telegramでhermesに「接続テスト。いま何時か教えて」と送り、返事が返ってきた画面](/images/hermes-vps/hermes-vps-07-desktop-23-telegram-reply.png)

母艦のHermes Desktopに戻り、左サイドバーを更新する(下の囲み参照)と、いま送ったTelegramの会話が一覧に現れる。逆にDesktopで新しい会話を始めれば、それも一覧に加わる。どこから話しかけても、受け取っているのは同じ1体だ。

![母艦のHermes Desktopの左サイドバーに、いま送ったTelegram/Discordの会話が並んでいる画面。同じエージェントである実証。対象の会話以外のセッション名はモザイク](/images/hermes-vps/hermes-vps-07-desktop-24-sidebar-sync.png)

:::message alert
**左サイドバーにすぐ出ないとき**(更新の一手間・v0.16.0時点):本記事の撮影時点(v0.16.0)では、Telegram/Discordで作った会話はDesktopの左サイドバーにリアルタイムでは出なかった(Hermes Desktopが通常の会話一覧を定期取得していなかったため。自動更新されるのはCronなど一部だけだった)。**この一手間はv0.18.1で不要になった**(次の段落を参照)。v0.18.0以前で出ないときは、Gateway設定で「Save and reconnect」を押すと再接続がかかり一覧が更新される(Windowsで実機確認済み)。それでも出なければアプリを再起動する。`Ctrl+R`(ウィンドウ再読み込み)はWindowsでは効かなかった。
:::

この挙動は公式issue [#41827](https://github.com/NousResearch/hermes-agent/issues/41827)で報告され、その後v0.18.1(2026-07-08公開)で解消された。外部(Telegram・Discord・WeChat)で作られた会話が、profileの切り替えや再起動なしでサイドバーに反映されるようになり、Teknium本人がissueをクローズしている(実装はcommit `52d0d671e`)。本体をv0.18.1以降に上げていれば、上の「更新の一手間」はもう要らない。

![GitHub issue #41827。左サイドバーの自動更新が効かない報告と、修正PRのリンクが見える](/images/hermes-vps/hermes-vps-07-desktop-25-issue-41827.png)

:::message
ターミナル(SSHで操作してきた黒い画面)も同じ仲間。第1〜6回で動かしてきたVPS上のHermesと、Telegram・Discord・Desktopは、全部同じ1体の別の入口にすぎない。「黒い画面を卒業」ではなく「黒い画面だけに閉じ込めない」——用途に応じて入口を選べるのが強みだ。
:::

## 補足:v0.17.0でDesktopはさらに強化された

本記事はv0.16.0「Surface Release」での執筆だが、2026-06-19公開の**v0.17.0**「The Reach Release」でHermes Desktopにいくつかの便利な機能が入った。

- **日本語+繁体字中国語の言語切替**=設定からアプリ全体のUIを切り替えられる。本記事は英語UIで撮影しているが、v0.17.0なら日本語UIで操作可
- **Rebindableキーボードショートカット**=キーバインドを自由に変更できるパネル追加
- **VS Code Marketplace Theme**=任意のVS Codeテーマをそのままインストール可能
- **OS Native通知**=タイプ別にON/OFF切替できる通知
- **Subagent Watch-Windows**=委譲したサブエージェントの活動を専用ペインで並列表示(第21回で扱う予定)
- **Resizable Terminal Pane**=VS Codeテーマ準拠の可変ターミナル
- **マルチターミナルパネル**(2026-06-28追加・[PR#54517](https://github.com/NousResearch/hermes-agent/pull/54517))=右レールがVS Code風のサイドアイコンレールに刷新され、複数ターミナルタブを開けるようになった(`Ctrl+Shift+`` で新規・`Ctrl+Shift+Up/Down` で切替・`Ctrl+Shift+W` でクローズ)。タブとscrollbackはアプリ再起動を生き残る。エージェントが背景で動かしているプロセスはread-onlyの`agent`タブとして同じレールにライブ表示される
- **`hermes serve`新CLI**(2026-06-28追加・[PR#54568](https://github.com/NousResearch/hermes-agent/pull/54568))=Hermes Desktopが内部で起動するbackendサーバーが`hermes dashboard`から`hermes serve`に分離された(同じ`start_server`を共有する別名subcommand)。本記事の常駐手順(`hermes-dashboard.service`+`hermes dashboard --no-open`)は後方互換shimで引き続き動く=既存読者は何もしなくてよい
- **Windows起動安定化**(2026-06-28追加)=`config.yaml`の`desktop.electron_flags`/`desktop.disable_gpu`で起動フラグを恒久指定できるようになった(ショートカットに`--no-sandbox`を付ける本記事の手順も引き続き有効)。packaged版の起動時クラッシュ・`hermes.exe`が`PATH`から消える現象の自己修復・コンソールウィンドウのチラつき抑制も同時に入った
- **status barのcontext usage内訳popover**(2026-06-29追加・[PR#54907](https://github.com/NousResearch/hermes-agent/pull/54907))=画面下status barのcontext usage表示がクリック可能になり、システムプロンプト/ツール定義/ルール/スキル/MCP/サブエージェント定義/メモリ/会話の8カテゴリ別token内訳がpopoverで見えるようになった(token数は`char/4`の概算)。コンテキストの何が大きいかを目で把握できる
- **Subagent Watch-Windowsがspectator専用化**(2026-06-29追加・[PR#55033](https://github.com/NousResearch/hermes-agent/pull/55033))=同僚エージェントの活動を覗くwatchウィンドウから、入力欄/停止ボタン/再実行ボタン/checkpoint切替が全部消えた。眺める専用の読み取りウィンドウになった(同僚を止めたければ元のウィンドウに戻る)
- **ペットの散歩(Roam)opt-in追加**(2026-06-29追加・[PR#55114](https://github.com/NousResearch/hermes-agent/pull/55114))=設定→ペットの「散歩」をONにすると、アイドル中にペット(マスコット)がウィンドウ内を歩き回る。デフォルトはOFFなので、ONにしない限り従来の浮遊だけ(2026-07-01追記:その後の調整でRoamの頻度は控えめになり、多くの時間は休憩・時々短く歩く程度になった。2026-07-03追記:v0.18.0でさらに自然な散歩挙動+`Alt`+マウスホイールでの拡縮+ポップアウト表示に成熟した)
- **返信を読み上げるcomposerトグル**(2026-06-29追加・[PR#55154](https://github.com/NousResearch/hermes-agent/pull/55154))=composerにスピーカーアイコンのトグルが追加され、ONにすると以後のエージェント返信を音声で読み上げる(`voice.auto_tts`に永続化)。ディクテーション(声で入力)やfull voice conversationを使わず「タイプして打って、返事だけ音声で聞く」運用ができる
- **Memory Graph(記憶グラフ)**(2026-07-01追加・[PR#55226](https://github.com/NousResearch/hermes-agent/pull/55226))=status barやコマンドパレットから開ける放射状タイムラインの新パネル。中心が最も古い記憶で、外側の輪ほど新しい。memoriesとskillsを時系列で可視化でき、再生・スクラブ操作で「エージェントの記憶が積み上がっていく過程」を辿れる。Desktopでは`/journey`を叩いても同じMemory Graph overlayが開く(v0.18.0以降・以前はテキスト出力だった)。第12回のMemoryと合わせて、記憶がどう成長したかを目で見られる仕組み
- **Skills/Tools/MCPが「Capabilities」ページに統合**(2026-07-05追加・[PR#57590](https://github.com/NousResearch/hermes-agent/pull/57590))=別々のタブだったSkillsとToolsets、設定の中にあったMCPが、1つのCapabilitiesハブ(Skills/Tools/MCP/Browse Hub)にまとまった。スキルは実際の使用頻度順に並び、learned/built-in/hubの出所バッジが付き、学習済みスキルはこの画面から編集・アーカイブできる。「エージェントに何ができるか」を1か所で見渡せる置き場になった
- **接続モードに「Hermes Cloud」追加**(2026-07-12追加・[PR#61912](https://github.com/NousResearch/hermes-agent/pull/61912))=local/remote(本記事のVPS接続)に続く第3のモード。公式ホスティング「Hermes Agent Cloud」(2026-07-08公開)上のエージェントへ、ポータルに1回サインインするだけで自動発見・接続できる。本記事のVPSへのリモート接続手順はそのまま変わらない
- **status barに承認モードの三択メニュー追加**(2026-07-14追加・[PR#63520](https://github.com/NousResearch/hermes-agent/pull/63520))=それまでの「承認をバイパスするか否か」の二択トグルが、画面下部のstatus barから開ける`Smart`/`Manual`/`Off`の三択メニューに置き換わった。日本語UIにも対応済み。第5回で`manual`固定を説明しているが、DesktopからならこのメニューでもGatewayの承認モードを直接切り替えられる

本記事の手順や画面はv0.16.0時点だが、`hermes update`で本体を最新に保ち続ければ自動で反映される。日本語UI切替は設定画面から1クリックなので、v0.17.0に上げた人は試してみるとよい。

## 最終確認チェックリスト

第7回完了の目安を一覧にする。

- [ ] VPSで`hermes dashboard`が認証つき・Tailscale IP bindでsystemd常駐している
- [ ] `/api/status`が`auth_required: true`と`["basic"]`を返す
- [ ] 母艦のHermes Desktop(v0.16.0)が入り、起動する
- [ ] チャット・ドラッグ&ドロップ・Ctrl+K・モデル切替を一通り触った
- [ ] DesktopからRemote URL+サインインでVPSに繋がる(ユーザー名/パスワード)
- [ ] Telegram/Discordで送った会話が、Desktopの左サイドバーにも出る(同じエージェントの実証)

ここまで揃えば、VPSに住むHermesを、黒い画面・スマホ(Telegram/Discord)・母艦のアプリの3つの窓から、用途に応じて使い分けられる状態になった。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第6回 気づいたら止まっている、をなくせ。Hermes Agentはsystemdでいつも動き続け、落ちてもすぐ戻る](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd) | [第8回 手探りで動かすな。Hermes Agentはブラウザ1枚で中身が見える](https://zenn.dev/sora_biz/articles/hermes-vps-08-dashboard) |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## よくあるエラーと対処

| 症状 | 対処 |
|---|---|
| `hermes dashboard --host <tailscale-ip>`が起動せず終了する | 認証未設定で外向きbindを拒否している(fail-closed)。認証情報を`.env`に入れてから再起動。systemd経由なら`EnvironmentFile=%h/.hermes/.env`が付いているか確認 |
| Desktopが「backendはready」と言うのにチャットが繋がらない | `Save and reconnect`を押していない可能性が高い。押したうえで、VPS側はTailscale IPにbindし、Remote URLも同じIPにする。`127.0.0.1`にbindすると母艦からは届かない |
| アプリを再起動するたびにログインが切れる | `HERMES_DASHBOARD_BASIC_AUTH_SECRET`が未設定。`openssl rand -base64 32`で固定値を`.env`に入れる |
| サインインで「Invalid credentials / 401」 | ユーザー名かパスワードが`.env`と不一致。`curl -s http://<host>:9119/api/status \| jq '.auth_providers'`に`"basic"`が出るか確認 |
| `hermes dashboard`が「何かを入れろ」と出て起動しない | Web部品が未導入。`cd ~/hermes-agent && pip install -e '.[web]'` |
| 母艦の`hermes desktop`が初回なかなか立ち上がらない | 初回はElectronビルドが走るため。エラーでなければ待つ。インストーラで入れた場合はビルド済み |
| Hermes Desktopが起動直後に落ちる・真っ白のまま固まる | GPUとChromiumサンドボックスの相性問題(終了コード`0x80000003`、[#38216](https://github.com/NousResearch/hermes-agent/issues/38216))。本文「アプリが起動しないときの直し方」を参照 |
| Ctrl+Kが効かない | Macでは`Cmd+K`。それでも開かなければアプリのキーボードショートカット設定を確認 |
| Telegram/Discordの会話が左サイドバーに出ない | v0.18.1(2026-07-08)以降は自動で反映される。v0.18.0以前は`Save and reconnect`またはアプリ再起動で更新する(本回「どの入口でも同じ1体のエージェント」参照) |
| gatewayを止めたらdashboardも止まると思った | 両者は別プロセス。dashboardはdashboardで常駐させる。逆にdashboardを動かしてもTelegram等は常駐済みgatewayが別途必要 |

## コマンド早見表

```bash
# VPS側(接続先dashboardの常駐)
hermes dashboard --help                                   # Web部品が入っているか確認
systemctl --user enable --now hermes-dashboard            # systemd常駐
curl -s http://<tailscale-ip>:9119/api/status | jq '.auth_required, .auth_providers'  # 認証確認

# 母艦側(Windows)
# インストーラ: https://hermes-agent.nousresearch.com/desktop
hermes desktop                                            # CLIから起動(任意)

# Hermes Desktopアプリ内
# Settings → Gateway → Remote gateway
#   Remote URL: http://<tailscale-ip>:9119
#   Sign in: admin + password → Save and reconnect
# Ctrl+K(MacではCmd+K): コマンドパレット / status bar: モデル切替 / /undo: 会話の巻き戻し
```

## 引用元と参考

| 項目 | 引用元 |
|---|---|
| Hermes Desktop全般・CLIと同じエージェント核・リモート接続UI | [docs/user-guide/desktop](https://hermes-agent.nousresearch.com/docs/user-guide/desktop) |
| v0.16.0「Surface Release」の新機能(Desktop正式化・Ctrl+K・drag&drop・status barモデル・self-update・/undo) | [release v2026.6.5](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.6.5) = v0.16.0 |
| 接続先dashboardのprerequisites・認証env var・fail-closed・Tailscale bind | [web-dashboard](https://hermes-agent.nousresearch.com/docs/user-guide/features/web-dashboard)「Connecting Hermes Desktop to a remote backend」 |
| Hermes Desktopのインストール(Windows・管理者権限不要) | [installation](https://hermes-agent.nousresearch.com/docs/getting-started/installation) / [windows-native](https://hermes-agent.nousresearch.com/docs/user-guide/windows-native) |
| 起動直後crashの既知issue(`--no-sandbox`) | [#38216](https://github.com/NousResearch/hermes-agent/issues/38216) |

:::message
この連載はSubstack「そらのAIエージェント通信」で先行公開している。無料[登録](https://sorabiz.substack.com/subscribe)すると最新回がメールに届く。[Zennでフォロー](https://zenn.dev/sora_biz)すると新着通知が届き、全体像は[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::
