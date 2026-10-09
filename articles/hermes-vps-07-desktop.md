---
title: "【第7回】Hermes AgentがMicrosoft Storeに来た。Windowsアプリで入れてVPSにつなぐ（旧版からの入れ替えも）"
emoji: "🤖"
type: "tech"
topics: ["ai", "hermes", "desktop", "tailscale", "vps"]
published: true
---

:::message
**この記事をAIに読ませる**

この記事はGitHubの公開リポジトリで管理していて、本文のMarkdownをそのまま取得できる。Claude CodeやCodexなどのAIエージェントに手順を任せたいときは、次のURLを渡すだけでいい。

https://raw.githubusercontent.com/Sora-bluesky/zenn-articles/main/articles/hermes-vps-07-desktop.md

頼み方の例:「この記事を読んで、私の環境で手順を順番に実行して」に上のURLを添える。
:::

:::message
この連載は月1,800円ほどのVPSで、自分専用のAIエージェント(Hermes Agent)を24時間動かす実録だ。これはその第7回。全体の流れは[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::

## 目次

- [この回の到達点](#この回の到達点)
- [ターミナルとHermes Desktopの関係](#ターミナルとhermes-desktopの関係)
- [第7回終了時点の構成図](#第7回終了時点の構成図)
- [事前準備](#事前準備)
- [VPS側で接続先のdashboardを常駐させる](#vps側で接続先のdashboardを常駐させる)
- [自分のパソコンにHermes Desktopを入れる](#自分のパソコンにhermes-desktopを入れる)
  - [Microsoft Storeから入れる](#microsoft-storeから入れる)
  - [すでにダウンロード版を入れている人へ](#すでにダウンロード版を入れている人へ)
- [VPSのHermesにリモート接続する](#vpsのhermesにリモート接続する)
- [Hermes Desktopの基本操作](#hermes-desktopの基本操作)
- [どこから話しかけても同じ1体のエージェント](#どこから話しかけても同じ1体のエージェント)
- [最終確認チェックリスト](#最終確認チェックリスト)
- [Hermes Desktopをアンインストールするとき](#hermes-desktopをアンインストールするとき)
- [アプリが起動しないときの直し方](#アプリが起動しないときの直し方)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [コマンド早見表](#コマンド早見表)
- [引用元と参考](#引用元と参考)

この回が終わると、VPSのHermesを、黒い画面ではなくマウス操作のデスクトップアプリ「Hermes Desktop」からも使える。自分のパソコン(この連載ではWindows)にアプリを入れ、Tailscale越しにVPSのHermesへ繋ぐ。ブラウザでの管理画面の詳しい使い方は第8回で扱うので、この回では接続先として動かすところまでにとどめる。

第6回で、Hermes Agentは24時間VPSに常駐するようになった。SSHを切ってもVPSを再起動しても、Telegram/Discordに話しかければ返事が返る。

ただ、ここまでHermesに触れる窓口はずっとSSHのターミナル(黒い画面)のままだった。コマンドを打ち、コマンドを覚え、打ち間違えればやり直す。慣れればなんてことはないが、「黒い画面が苦手」という理由だけでAIエージェントから足が遠のく人は多い。

使うのは、普段使いのWindowsノートPCに入れる公式デスクトップアプリ「Hermes Desktop」。2026-06-05のv0.16.0で正式リリースされたアプリで、2026-10-08(米国時間)にMicrosoft Storeでの配信開始が告知された。この回ではStore版を入れる。

大事なのは、別のAIを入れるわけではないこと。CLI・Hermes Desktop・Web Dashboardは、同じ1体のエージェントに繋ぐ別々の手段にすぎない。片方で設定したことは、もう片方にもそのまま出る。

シリーズの全体像はこちら。

:::details シリーズのもくじ(タップで開く)

**第I部 VPSで24時間動かす**
- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy) サーバー代は月1,800円で足りる。Hermes AgentはVPSで24時間動き続ける
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale) パスワードはもう打つな。Hermes AgentへのSSHは鍵一発で入れる
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password) APIキーをそのまま書くな。Hermes Agentの秘密は1Passwordが預かる
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install) Hermes AgentをDockerで隔離して動かす方法
- [第5回](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord) コマンドを覚えるな。Hermes AgentはDiscordで話しかけるだけで動く
- [第6回](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd) 気づいたら止まっている、をなくせ。Hermes Agentはsystemdでいつも動き続け、落ちてもすぐ戻る

**第II部 デスクトップアプリとブラウザから操作する**
- **第7回**(本記事) Hermes AgentがMicrosoft Storeに来た。Windowsアプリで入れてVPSにつなぐ（旧版からの入れ替えも）
- [第8回](https://zenn.dev/sora_biz/articles/hermes-vps-08-dashboard) 手探りで動かすな。Hermes Agentはブラウザ1枚で中身が見える

**第III部 定時実行・スキル・Web検索を足す**
- [第9回](https://zenn.dev/sora_biz/articles/hermes-vps-09-cron) いつもの作業を毎回自分でやるな。Hermes Agentが決めた時刻や間隔で自動でこなす
- [第10回](https://zenn.dev/sora_biz/articles/hermes-vps-10-skills) 毎回教えるな。Hermes Agentは使えば使うほど自分で賢くなる
- [第11回](https://zenn.dev/sora_biz/articles/hermes-vps-11-web-search) 気になる情報を自分で探し回るな。Hermes Agentがネットで調べて要点だけまとめてくれる

**第IV部 記憶・話し方・スキルを管理する**
- [第12回](https://zenn.dev/sora_biz/articles/hermes-vps-12-memory) 好みを毎回言うな。Hermes AgentはMemoryで覚えている
- [第13回](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) メモを自分で探すな。Hermes AgentはObsidianを記憶として読む
- [第14回](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) 毎回最初から話すな。Hermes Agentは前回の続きからそのまま動く
- [第15回](https://zenn.dev/sora_biz/articles/hermes-vps-15-import-ai-sessions) 記憶を捨てるな。Hermes AgentはClaude Codeの続きを引き継ぐ

全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

所要時間の目安は60〜90分(うち初回のweb UIビルド待ちが数分)。VPS側でひと手間、自分のパソコン側でアプリを入れて繋ぐ、という二段構えになる。

## この回の到達点

第6回完了時と第7回完了後の差分を表にする。

| 項目 | 第6回完了時 | 第7回完了後 |
|---|---|---|
| 操作手段 | SSHのターミナル(CLI)だけ | **パソコン側のHermes Desktop**(GUIアプリ)が加わる |
| ファイルを渡す | パスを指定 | **チャットにドラッグ&ドロップ**・画像はコピペ |
| 操作を探す | コマンドを覚える | **Ctrl+K**(MacではCmd+K)で検索 |
| モデル切替 | `hermes model` | **入力欄の中のモデルピッカー**(マイクの左) |
| 接続経路 | なし | Hermes Desktop → Tailscale → VPSの`hermes dashboard` |
| 同じ1体の実証 | (意識しない) | **Telegram/Discordの会話がDesktopにも並ぶ** |

第7回でやるのは、VPSで動く同じHermesを、黒い画面だけでなく普通のアプリの窓からも触れるようにすることだ。

## ターミナルとHermes Desktopの関係

ここまでHermesはターミナル(黒い画面)でしか操作できなかった。この回でやるのは、その同じHermesをマウス操作でも動かせるようにすること。繰り返すが、別のAIを入れるのではない。同じ1体に、ターミナル(CLI)とアプリ(GUI)の両方から話せるようになる。

### v0.16.0「The Surface Release」で何が変わったか

Hermes Desktopは2026-06-05のv0.16.0で正式リリースされた、macOS/Windows/Linux対応のネイティブアプリだ。「Surface」の名のとおり、これまでターミナルの中で動いていたHermesが、普通のアプリとして使えるようになった回といえる。アプリ内での自己更新(ダウンロード版)・ファイルのドラッグ&ドロップ・Ctrl+Kコマンドパレット・モデル切替などが入った。

### この回で出てくる用語

| 用語 | 意味 |
|---|---|
| 自分のパソコン | 普段使いのWindowsノートPC。Hermes Desktopを動かし、VPSへ繋ぐ側。VPS・自宅GPU機とは別のマシン |
| Hermes Desktop | 自分のパソコンで動く公式デスクトップアプリ。Microsoft Storeでは「Hermes Agent」の名前で配布されている。CLIと同じエージェント核を使う(同じ設定・セッション・スキル・記憶) |
| Web Dashboard | `hermes dashboard`で立ち上がるブラウザ用の管理画面。この回ではDesktopの接続先として使い、管理機能の詳細は第8回で扱う |
| リモートバックエンド | Hermes Desktopが繋ぐ接続先。実体はVPS上で動く`hermes dashboard`プロセスそのもの |
| 認証ゲート | dashboardを外向きアドレスに開くと自動でかかるログイン要求。ユーザー名/パスワードで通す |

### 頭に入れる2つの「別物」

ここで混乱しやすい2点を先に潰しておく。

**1つ目、dashboard ≠ gateway**。Desktopが繋ぐのは`hermes dashboard`であって、第6回で常駐させたgateway(Telegram係)ではない。両者は別プロセスとして同時に動く。

**2つ目、Desktopは接続先を起動してくれない**。VPS側の`hermes dashboard`は自分でsystemdで常駐させる(この回の前半)。自分のパソコンのHermes Desktopは、そこに「繋ぎに行く」だけだ。

## 第7回終了時点の構成図

自分のパソコン・Tailscale・VPSの3つに焦点を絞った構成。

![第7回の構成図。自分のパソコンのHermes DesktopがTailscale(暗号化された専用通路)経由でVPSのhermes dashboardに接続・認証し、同じエージェントの状態を共有する。VPSにはhermes-gatewayも別プロセスで常駐し、Telegram/Discordを捌いている](/images/hermes-vps/hermes-vps-07-desktop-diagram.png)

Hermes本体はVPSで動き続け、自分のパソコンには操作用のアプリを置くだけの構成になる。だから自分のパソコンの電源を切っても、VPS上のHermesはTelegram/Discordで動き続ける。

## 事前準備

まずVPSにSSHで入り直し、第6回の常駐が生きていることを確認する。あわせて、この回で何度も使うVPSのTailscale IPを控えておく(後でdashboardのbind先・Desktopの接続先になる)。

```powershell
ssh admin@hermes-vps
```

入れたら、バージョンとgatewayの稼働を1画面で確認する。

```bash
hermes --version; echo; systemctl --user status hermes-gateway --no-pager | head -8
# → バージョン番号と Active: active (running) が出ればOK

tailscale ip -4   # VPS上で実行。出たTailscale IP(100.x.x.x)を控える(あとで自分のパソコンのDesktopの接続先になる)
```

:::message
`--no-pager`と`head -8`を付けているのは、素の`systemctl status`がログ末尾までスクロール表示し、そこにホスト名(グローバルIP)が出てしまうため。Active行までに絞って、画面に余計な情報を出さない。
:::

![VPSでhermesのバージョン番号が出て、hermes-gatewayがactive (running)を示す画面](/images/hermes-vps/hermes-vps-07-desktop-01-version-gateway.png)

自分のパソコンに入れるStore版のHermes Agentには、Windows 11 22H2以降が必要だ(出典:[公式windows-native](https://hermes-agent.nousresearch.com/docs/user-guide/windows-native))。この回の画面は、撮った時期が2つに分かれる。Store版の入れ方・初回設定・接続・アンインストールの画面は、Windows 11の1台で2026-10-09に実際に動かして撮った。VPS側の準備(desktop-01〜09)と、基本操作・Telegramの画面(desktop-19〜24)は、v0.16.0のころ(2026-06)の画面だ。

第7回の手順は、ここまでで第6回までを完了している(VPSにHermesが常駐し、Telegram/Discordが繋がっている)ことを前提にする。自分のパソコンとVPSが同じtailnetにいることも確認しておく(パソコン側で`tailscale status`にVPSが出る)。

## VPS側で接続先のdashboardを常駐させる

出典:[公式web-dashboard](https://hermes-agent.nousresearch.com/docs/user-guide/features/web-dashboard)

Hermes DesktopがVPSに繋ぐには、VPS側で`hermes dashboard`が動いている必要がある。この回ではdashboardを「接続先」として認証つきで常駐させるところまで。ブラウザでの管理(Cron/Skills/Memory等)は第8回でじっくり扱う。

### 管理画面の部品が入っているか確認する

いまのHermesは、dashboardに必要な部品(FastAPI/Uvicorn等)を標準で同梱している。まず入っているかを確認する。

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
クォート付きheredoc(`<<'EOF'`)で流し込むと`$(...)`がそのまま文字列として入ってしまう(実際に動かして確認済み)ので、ここはnanoで手書きするのが確実。書いたら`Ctrl+O`→`Enter`で保存し、`Ctrl+X`で閉じる。
:::

最後に、本人だけが読める権限にしておく。

```bash
chmod 600 ~/.hermes/.env
```

`SECRET`は、再起動してもログインが切れないための署名鍵だ。これが無いと、dashboardを再起動するたびにサインインがやり直しになる。

![~/.hermes/.envに3つのHERMES_DASHBOARD_BASIC_AUTH_*が追記された画面。キー名だけが見える状態](/images/hermes-vps/hermes-vps-07-desktop-03-env.png)

### 生成したパスワードを1Passwordにも保存する

dashboardのログインパスワードは長いランダム文字列で、自分のパソコンのDesktopからサインインするたびに必要になる。手打ちは現実的でないので、生成したいま、1Passwordなどのパスワードマネージャに保存しておく。後のサインインで呼び出すだけで済む。

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
# true / ["basic"] が出れば、自分のパソコンのDesktopのログインが通る状態
```

`active (running)`になり、`/api/status`が`true`/`["basic"]`を返せば、VPS側の準備は完了。もし起動に失敗するなら、`.env`に認証情報が入っているか(2つ前の手順)、venvパスが合っているか(`ls ~/hermes-agent/venv/bin/python`)を確かめる。

![systemctl --user statusでhermes-dashboardがactive (running)、別のcurlで/api/statusがtrue/["basic"]を返している画面](/images/hermes-vps/hermes-vps-07-desktop-09-systemd-active.png)

## 自分のパソコンにHermes Desktopを入れる

出典:[Nous Researchの告知](https://x.com/NousResearch/status/2108231536772596193) / [公式windows-native](https://hermes-agent.nousresearch.com/docs/user-guide/windows-native) / [公式updating](https://hermes-agent.nousresearch.com/docs/getting-started/updating)

ここからは自分のパソコン(普段使いのWindowsノートPC)での作業。この節が終わると、Hermes Desktopが入り、最初の設定の会話まで済んだ状態になる。VPSへの接続は次の「VPSのHermesにリモート接続する」で行うので、この節ではまだ繋がない。

### Microsoft Storeから入れる

下のStoreのページを開くか、Microsoft Storeアプリの検索欄に「Hermes Agent」と入れる。提供元が「Nous Research Inc.」のページを開いて「入手」を押す。

https://apps.microsoft.com/detail/9pmxk8czc7kr

![Microsoft StoreのHermes Agentのページ。提供元がNous Research Inc.で、青い「入手」ボタンが見える](/images/hermes-vps/hermes-vps-07-store-page.png)

約2.41GBのダウンロードが始まる(画面の表示のまま)。この回の環境で1回だけ測った値では、完了まで約10分だった。進捗が動いていれば待つ。

![インストール中のHermes Agentのページ。進捗が5%で、28.06 MB / 2.41 GBと表示されている](/images/hermes-vps/hermes-vps-07-store-installing.png)

終わると、「入手」だったボタンが「開く」に変わる。

![インストールが終わり、ボタンが「開く」に変わったHermes Agentのページ](/images/hermes-vps/hermes-vps-07-store-installed.png)

「開く」を押すか、スタートメニューの「Hermes Agent」から起動する。

はじめて開くと、英語で「Hi, I'm Hermes.」と話しかけてくる最初の設定のチャットが出る。ここからは、画面の質問に1問ずつ答える。この回の環境では、モデルのプロバイダやAPIキーは聞かれなかった。聞かれたら「あとで選ぶ」(Choose provider later)でよい。この回で自分のパソコンにキーを置く必要はない。

画面が英語のため、この回の画像には黄色のラベルで日本語の意味を足してある。聞かれた順番は次のとおりだ。

| 順番 | 画面の質問 | 意味 | この回の答え |
|---|---|---|---|
| 1 | What should I call you? | 何と呼べばいいか | 好きな名前を入れて「確定して続行」 |
| 2 | Which colour? | アクセントカラー(アプリの差し色)をどれにするか | 好きな色を選んで「確定して続行」(色を足す「+」もある) |
| 3 | Which of these do you use? | 連携するアプリはどれを使っているか | 飛ばす |
| 4 | Want any of these? | 入れたいプラグインはあるか | 飛ばす |
| 5 | Which layout? | どの画面構成にするか(Basicは「Hermesと話す用」、Eliteは「開発者向け」) | Basic |
| 6 | Want a look around first? | 先に一通り見て回るか(tourの画面には「その他(回答を入力)」もある) | Skip, let's build something |
| 7 | Know what you'd like it to make? | 作りたいものは決まっているか | 飛ばす |
| 8 | 最初に何を作りましょうか? | 7問目を飛ばしたあと、スキップ済みの表示で出る | そのまま |
| 9 | 最初にPCの健康診断を… | PCの健康診断の提案 | 飛ばす |

はじめに、最初の画面。1問目で名前を聞かれる。「スキップ」を押すと質問を飛ばせ、右下の「Skip setup」を押すと最初の設定そのものを飛ばせる。

![Store版をはじめて開いた画面。「Hi, I'm Hermes.」のあと、1問目「What should I call you?」で名前を聞かれている](/images/hermes-vps/hermes-vps-07-store-fresh-first-launch.png)

名前を入れて「確定して続行」を押す。

![名前の入力欄にそらと入れ、「確定して続行」を押そうとしている画面。赤枠で入力欄とボタンを示している](/images/hermes-vps/hermes-vps-07-store-fresh-setup-name.png)

2問目はアクセントカラー。8色の丸から1つ選ぶ。

![「Which colour?」でアクセントカラーを選ぶ画面。8色の丸のうちシアンが赤枠で選ばれている](/images/hermes-vps/hermes-vps-07-store-fresh-setup-colour.png)

3問目は連携するアプリ。Slack・Notion・Linearなどが並ぶ。後でいつでもできるので、ここでは飛ばす。

![「Which of these do you use?」で連携するアプリを選ぶ画面。Slack・Notion・Linear・Jiraなどが並んでいる](/images/hermes-vps/hermes-vps-07-store-fresh-setup-apps.png)

4問目はプラグイン。3問目をスキップしたあとのこの画面に、「アプリの接続には無料のNousアカウントが必要で、後でいつでもできる」という表示が出る。アカウントが要るのは3問目のアプリの接続で、プラグインではない。画面には「選んでも記録するだけ」とも出る。ここも飛ばす。

![「Want any of these?」でプラグインを選ぶ画面。Blender・NVIDIA App・NVIDIA Broadcastが並び、3問目をスキップした旨の案内も見える](/images/hermes-vps/hermes-vps-07-store-fresh-setup-plugins.png)

5問目は画面構成。「Basic」(Hermesと話す用)と「Elite」(開発者向け。ターミナル・ファイル・差分を並べる)から選ぶ。この回はBasicにした。

![「Which layout?」で画面構成を選ぶ画面。左のBasicが選ばれ、右にEliteが並んでいる](/images/hermes-vps/hermes-vps-07-store-fresh-setup-layout.png)

6問目は、先に一通り見て回るか。左から「Quick tour」「Show me everything」「Skip, let's build something」の3択で、この回は右端の「Skip, let's build something」を選んだ。

![「Want a look around first?」の画面。Quick tour・Show me everything・Skip, let's build somethingの3択があり、右端が選ばれている](/images/hermes-vps/hermes-vps-07-store-fresh-setup-tour.png)

7問目は、作りたいものが決まっているか。そのあとに「最初に何を作りましょうか?」(スキップ済みで表示)が出て、続けて「最初にPCの健康診断を…」という提案が出る。この回は飛ばした。

![「Know what you'd like it to make?」に続いて、PCの健康診断を提案される画面](/images/hermes-vps/hermes-vps-07-store-fresh-setup-make.png)

最後に「It's all yours, and this chat stays here if you want a hand.」と出て、最初の設定は終わる。手を借りたいときは、このチャットがそのまま残る。

![最初の設定の最後の画面。スキップした質問が並び、末尾に「It's all yours, and this chat stays here if you want a hand.」と出ている](/images/hermes-vps/hermes-vps-07-store-fresh-setup-done.png)

Store版の更新は、Microsoft Storeから届く。なお`hermes update`は、第4回で入れたVPS側の本体を更新するコマンドで、VPSで実行する。自分のパソコンで打っても、Store版は更新されない(公式windows-nativeによると、同梱版の`hermes update`はパッケージに対してgitを走らせない)。Store版は、Microsoft Storeの更新で別に最新にする。

### すでにダウンロード版を入れている人へ

:::message
この囲みは、第7回の旧手順(公式サイトのインストーラ)で入れた人向けだ。はじめて入れる人は読み飛ばしてよい。

古い版を先に消してはいけない。Store版が設定を引き継がなかったとき、戻せなくなる。順番は、戻らないデータをバックアップする、古い版を残したままStore版を入れる、引き継ぎと接続を画面で確かめる、問題がなければ最後に古い版を外す、の順だ。

バックアップは、再ダウンロードで戻らないものだけ取る。`%LOCALAPPDATA%\hermes`の大半はモデル・プログラム本体・キャッシュで、入れ直せば戻る。戻らない設定・会話・スキルなどだけを写す。Hermes Desktopを閉じてから、PowerShellで次を実行する。

```powershell
robocopy "$env:LOCALAPPDATA\hermes" "$env:USERPROFILE\hermes-backup" /E /XD models hermes-agent installs tools cache runtimes bin bootstrap-cache logs /R:1 /W:1
```

古い版を残したままStore版を入れて確かめると、次のことが分かった。

- Store版は`%LOCALAPPDATA%\hermes`をそのまま読み書きする。ダウンロード版のボット・会話・設定が、Store版の最初の画面から見えた。最初の設定の会話は出なかった。
- ダウンロード版で登録したVPSの接続先は、Store版の「保存済みの接続」に残っていた。
- 接続先と、ローカルかリモートかの選択は、データのフォルダではなくHermes Desktopのアプリ自身が覚えている。データの置き場所を空のフォルダに切り替えても、接続先とサインインの状態は残った。
- そのため、データのフォルダのバックアップには、接続先の設定は入っていない。
- Store版を入れると、ターミナルで`hermes`と打ったときにStore版の入口(`Microsoft\WindowsApps\hermes.exe`)が先に呼ばれるようになった。確かめるには`Get-Command hermes -All`を使う。
- ダウンロード版の`hermes uninstall`は、「Uninstall Complete!」と出ても「Could not fully remove」の警告が出ていれば、プログラム本体のフォルダが残る。この場合は手動でアンインストールが必要だ。古いデスクトップのショートカット「Hermes」も残る。手順は[Hermes Desktopをアンインストールするとき](#hermes-desktopをアンインストールするとき)にまとめた。

![ダウンロード版が入っている自分のパソコンでStore版を開いた画面。ボット一覧に既存のボットが見える](/images/hermes-vps/hermes-vps-07-store-first-launch.png)

![Get-Command hermes -Allの出力。1行目がStore版の入口で、2行目と3行目がダウンロード版の入口](/images/hermes-vps/hermes-vps-07-store-coexist.png)
:::

## VPSのHermesにリモート接続する

出典:[公式desktop](https://hermes-agent.nousresearch.com/docs/user-guide/desktop)「In the app」

インストールしたHermes Desktopを起動すると、最初は自分のパソコン上のローカルバックエンドで立ち上がる。ただし自分のパソコンには**モデルの鍵がない**ので、プロバイダを設定していなければ、このままではモデルを使えない(ダウンロード版では、この状態でチャットするとモデル認証エラーになった)。

だから最初にやるのは、VPSに常駐させた`hermes dashboard`に繋ぎ替えること。Hermes本体はVPSで動かし、自分のパソコンには操作用のアプリを置く構成にする。繋ぎ替えれば、モデルの鍵もVPS側のものが使われる。

設定画面は、右上の歯車アイコンから開く。

### リモートURLを入れてサインインする

| 順番 | 操作 | 入力 |
|---|---|---|
| 1 | 設定を開く | 設定 → ゲートウェイ → このウィンドウ |
| 2 | 接続方式を選ぶ | 「リモートゲートウェイ」 |
| 3 | リモートURL | `http://<tailscale-ip>:9119`(VPSのTailscale IP) |
| 4 | サインイン | 認証の「サインイン」ボタン → 別ウィンドウで`admin`とパスワードを入力 |
| 5 | 確定 | 「保存して再接続」 |

接続方式は4つある。「ローカルゲートウェイ」(自分のパソコンの中で動かす。既定)、「Hermes Cloud」、「リモートゲートウェイ」、「SSH で接続」だ。VPSには「リモートゲートウェイ」を選ぶ。

![設定のゲートウェイ配下の「このウィンドウ」で、接続方式の4つが並んでいる画面。ローカルゲートウェイが選ばれている](/images/hermes-vps/hermes-vps-07-store-connection-mode.png)

:::message alert
`<tailscale-ip>`はそのまま打たない。山かっこごと、VPSの実際のTailscale IP(`100.x.x.x`の形)に置き換える。例えばTailscale IPが`100.101.102.103`なら、`http://100.101.102.103:9119`と入れる。
:::

パスワードは、先ほど1Passwordに保存したdashboardのパスワードをここで呼び出して貼り付ける。長いランダム文字列なので手打ちしない。

「リモートゲートウェイ」を選ぶと、「リモートURL」の欄が出る。VPSのURLを入れる。下の画像は、サインインを済ませたあとで撮っているため、認証が「サインイン済み」になっている。はじめて繋ぐ人は、ここが「サインイン」ボタンになっている。

![「リモートゲートウェイ」を選び、リモートURLを入れた画面。赤枠で、左のゲートウェイ → このウィンドウ、リモートゲートウェイ、リモートURL、「保存して再接続」ボタンを示している](/images/hermes-vps/hermes-vps-07-store-fresh-remote-url.png)

認証の「サインイン」を押すと、別ウィンドウ「Sign in — Hermes Agent」が開く。USERNAMEに`admin`、PASSWORDに1Passwordのパスワードを入れて「SIGN IN」を押す。パスワードは、この回の[生成したパスワードを1Passwordにも保存する](#生成したパスワードを1passwordにも保存する)で保存した「Hermes VPS - dashboard (Desktop/Web)」のものだ。1Passwordの使い方は[第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password)で説明している。下部の「PUBLIC BIND · AUTH REQUIRED」は、外から届く設定なのでサインインが必要だという表示だ。

![別ウィンドウ「Sign in — Hermes Agent」。USERNAMEとPASSWORDの入力欄と「SIGN IN」ボタンが見え、各欄に日本語のラベルが添えてある](/images/hermes-vps/hermes-vps-07-store-fresh-signin.png)

:::message alert
サインインしたら、最後に必ず「保存して再接続」を押す。これを押さないとDesktopは自分のパソコン上のローカルのままでVPSに切り替わらない。切り替わったかどうかは、次の「接続できたことを確認する」の2つの目印で確かめる。
:::

#### OAuthとユーザー名/パスワードの違い

Hermes Desktopは2つの認証方式に対応する。

- **ユーザー名/パスワード**:TailscaleやLANなど信頼できるネットワーク内向け。本シリーズはこれ(Tailscale前提)。インターネットにそのまま晒す用途では使わない。
- **OAuth**(Nous Portal等):VPSを公開ホストとして晒す場合向け。

どちらも`--insecure`(認証なし)とは違う。本シリーズはTailscale+ユーザー名/パスワードで閉じる。

### 接続できたことを確認する

接続が成功すると、Desktopの中身がVPSのHermesに切り替わる。成功の目印は、設定画面を閉じてメイン画面に戻ったとき、左サイドバーにVPSの会話が並ぶことだ。VPSに届いているかだけを確かめたいときは、次の節の「Test」を使う。

VPSにつなぐと、表示が英語に変わった。

![VPSに繋がったあとのメイン画面。左サイドバーにVPS側の会話が並び、表示が英語になっている](/images/hermes-vps/hermes-vps-07-store-fresh-connected.png)

### 保存済みの接続とTest

一度繋いだVPSは、設定 → ゲートウェイ → 「保存済みの接続」に残る。ここには、自分のパソコン自身(This device。Current・Primaryの印が付く)と、保存したリモートゲートウェイが並ぶ。各行の「Test」を押すと、その接続先に届くかを確かめられる。

![設定の「保存済みの接続」。This deviceとリモートゲートウェイが並び、各行にTestボタンがある。「Make primary」「Add connection」「Update all instances」のボタンも見える](/images/hermes-vps/hermes-vps-07-store-saved-connections.png)

VPSの行の「Test」を押すと、右下に「Reachable」の通知が出て、しばらくすると消える。届いているという意味だ。

![VPSの行の「Test」を押した直後の画面。右下に「Reachable」の通知が出ている。赤枠でゲートウェイ → 保存済みの接続、Testボタン、通知を示している](/images/hermes-vps/hermes-vps-07-store-test-reachable.png)

「Make primary」は、保存済みの接続の行にあるボタンで、その接続をPrimaryにする。この回では押さない。

起動時にどのゲートウェイで開くかは、別のトグル「At startup, return to Sessions on the last-used gateway」(起動時に、最後に使ったゲートウェイのSessionsへ戻る)で決まる。画面の説明は「When off, Sessions opens on the Primary gateway.」(オフのときは、Primaryのゲートウェイで開く)だ。

:::message
**この先の使い方**:Hermes Desktopは、複数のprofile(担当)を1つのウィンドウで同時に動かせる。例えば「普段使い用」「Zenn原稿の編集者」「VPS運用担当」のように分ける。今回は「将来こう分けられる」という入口を見ておくだけで十分。本格的な役割分担は後の回で扱う。
:::

## Hermes Desktopの基本操作

VPSに繋がり、チャットが通るようになった。設定画面を閉じてメイン画面に戻ると、左サイドバーにVPS側の会話が並んでいるのが見える。第4〜6回でTelegramやDiscordから送った会話など、VPSのHermesが持っているデータがそのまま見える。

ここからはDesktopアプリそのものの触り方を押さえる。ここがDesktopで一番厚い部分で、「ターミナルのコマンドを覚える」から「アプリを普通に使う」へ変わる。

### チャットする

中央のチャット欄に書いて送るだけ。応答はリアルタイムに流れ(streaming)、左サイドバーに会話(session)が一覧で残る。過去の会話は検索・再開できる。

![チャットで送信すると応答がstreamingで返り、左サイドバーに会話一覧が見える画面。左サイドバーのセッション名はモザイク](/images/hermes-vps/hermes-vps-07-desktop-19-chat.png)

### ファイルを渡す(ドラッグ&ドロップ・画像コピペ)

チャット欄にファイルを**ドラッグ&ドロップ**するだけで添付できる。スクリーンショットは**クリップボードから直接貼り付け**(Ctrl+V)できる。「ファイルパスを指定する」必要がなくなった。

![PDFやテキストをチャット欄にドラッグ&ドロップして添付しているところ。左サイドバーのセッション名はモザイク](/images/hermes-vps/hermes-vps-07-desktop-20a-drag-drop.png)

![スクリーンショットをコピーしてCtrl+Vでチャット欄に貼り付けたところ。左サイドバーのセッション名はモザイク](/images/hermes-vps/hermes-vps-07-desktop-20b-paste-image.png)

### 迷ったらCtrl+K(コマンドパレット)

どこを押せばいいか分からなくなったら**Ctrl+K**(Macでは`Cmd+K`)。検索窓に「model」「skill」「new chat」のように打つと操作が見つかる。ターミナルのコマンドを覚えなくてよい道案内だ。

![Ctrl+Kで開いたコマンドパレット。検索窓とGO TO/コマンド一覧が見える状態。左サイドバーのセッション名はモザイク](/images/hermes-vps/hermes-vps-07-desktop-21-command-palette.png)

### モデルを切り替える

今の版では、モデルピッカーは入力欄の中、マイクのすぐ左にある(公式desktopの説明)。下の画像はv0.16.0のころの画面で、当時は画面下のstatus barにあり、**あいまい検索**(fuzzy search)で数文字打てば候補が出た。モデル名を全部覚えなくてよい。いつも最強モデルにせず、相談・文章・調査で場面ごとに切り替えるのがコツ。

![v0.16.0のころの画面。status barのモデルピッカー。あいまい検索で数文字打って候補が出ている。左サイドバーのセッション名はモザイク](/images/hermes-vps/hermes-vps-07-desktop-22-model-picker.png)

:::message
**覚えておくと安心、`/undo`**:変な方向に頼んでしまったら`/undo`で直前のN回の会話を巻き戻せる。ただし会話を戻すだけで、すでに送信したメール・削除したファイル・外部サービスで実行された操作まで取り消すわけではない。会話のやり直しと、外部操作の取り消しは別物だと覚えておく。
:::

## どこから話しかけても同じ1体のエージェント

この回の山場。Hermes Desktopの左サイドバーには、Desktopで送った会話だけでなく、**前の回で連携したTelegramやDiscordで送った会話も、同じ一覧に並ぶ**。

Telegram・Discord・ターミナル(SSH)・Desktopのどの窓から話しても、中にいるのは同じ1体・同じ記憶だ。これがHermesの仕組みで、「似たアプリを4つ別々に使う」のとは違う。

確かめ方は簡単。普段使っているTelegram(またはDiscord)で、Hermesに一言送ってみる。

```text
(Telegramで) 接続テスト。いま何時か教えて。
```

![Telegramでhermesに「接続テスト。いま何時か教えて」と送り、返事が返ってきた画面](/images/hermes-vps/hermes-vps-07-desktop-23-telegram-reply.png)

自分のパソコンのHermes Desktopに戻ると、いま送ったTelegramの会話が左サイドバーの一覧に現れる。逆にDesktopで新しい会話を始めれば、それも一覧に加わる。どこから話しかけても、受け取っているのは同じ1体だ。

![自分のパソコンのHermes Desktopの左サイドバーに、いま送ったTelegram/Discordの会話が並んでいる画面。同じエージェントである実証。対象の会話以外のセッション名はモザイク](/images/hermes-vps/hermes-vps-07-desktop-24-sidebar-sync.png)

:::message
ターミナル(SSHで操作してきた黒い画面)もその1つだ。第1〜6回で動かしてきたVPS上のHermesと、Telegram・Discord・Desktopは、全部同じ1体の別の入口にすぎない。黒い画面だけに閉じ込められず、用途に応じて入口を選べるのが強みだ。
:::

## 最終確認チェックリスト

VPSのHermesを、黒い画面・スマホ(Telegram/Discord)・自分のパソコンのアプリの3つの窓から、用途に応じて使い分けられる状態になった。その内訳が次の一覧だ。

- [ ] VPSで`hermes dashboard`が認証つき・Tailscale IP bindでsystemd常駐している
- [ ] `/api/status`が`auth_required: true`と`["basic"]`を返す
- [ ] Microsoft Storeから「Hermes Agent」が入り、最初の設定の会話を終えて起動する
- [ ] チャット・ドラッグ&ドロップ・Ctrl+K・モデル切替を一通り触った
- [ ] 「リモートゲートウェイ」にVPSのURLを入れ、ユーザー名/パスワードでサインインして「保存して再接続」するとVPSに繋がる
- [ ] 「保存済みの接続」でVPSの行の「Test」を押すと「Reachable」と出る
- [ ] Telegram/Discordで送った会話が、Desktopの左サイドバーにも出る(同じエージェントの実証)

---

| ← 前の回 | 次の回 → |
|---|---|
| [第6回 気づいたら止まっている、をなくせ。Hermes Agentはsystemdでいつも動き続け、落ちてもすぐ戻る](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd) | [第8回 手探りで動かすな。Hermes Agentはブラウザ1枚で中身が見える](https://zenn.dev/sora_biz/articles/hermes-vps-08-dashboard) |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## Hermes Desktopをアンインストールするとき

自分のパソコンからHermes Desktopを外す方法を、Store版とダウンロード版に分けて書く。この節が終わると、不要になった版が消え、残したい版だけが動いている状態になる。

### Store版

スタートメニューのアプリ一覧で「Hermes Agent」を右クリックし、「アンインストール」を選ぶ。Windowsの設定 → アプリ → インストール済みアプリからでも消せる。Store版を消したあとに、`%LOCALAPPDATA%\hermes`の中のデータが残るかどうかは、この回では確かめていない。

![スタートメニューのアプリ一覧で「Hermes Agent」を右クリックし、「アンインストール」が赤枠で示されている画面](/images/hermes-vps/hermes-vps-07-store-uninstall-store-app.png)

### ダウンロード版

ダウンロード版は、次のコマンドで外す。設定と会話のデータは残す形で外す。先にStore版のウィンドウを閉じておく。

はじめに、消えるものと残るものを`--dry-run`で見る。何も変更しない。

```powershell
& "$env:LOCALAPPDATA\hermes\hermes-agent\venv\Scripts\hermes.exe" uninstall --dry-run
```

![uninstall --dry-runの出力。「Dry run: no files, services, or environment entries will be changed.」のあと、消すものと残すものが並んでいる](/images/hermes-vps/hermes-vps-07-store-uninstall-dry-run.png)

出力の行は、次の意味だ。

| 画面の行 | 意味 |
|---|---|
| Dry run: no files, services, or environment entries will be changed. | 予行なので、ファイル・サービス・環境変数は何も変えない |
| Gateway services and standalone gateway processes | ゲートウェイのサービスと、単独で動いているゲートウェイのプロセス(消す) |
| Hermes PATH entries from shell configs / Windows User PATH | シェルの設定とWindowsのユーザーPATHにあるHermesの行(消す) |
| Hermes wrapper scripts and Hermes-managed node/npm/npx symlinks | 入口のスクリプトと、Hermesが置いたnode・npm・npxへのリンク(消す) |
| Desktop Chat GUI artifacts | 古いデスクトップアプリの部品(消す) |
| Code checkout: ...\hermes\hermes-agent | プログラム本体のフォルダ(消す) |
| Keep Hermes config/data: ...\hermes | 設定とデータ(残す) |
| Keep desktop app data: ...\Roaming\Hermes | デスクトップアプリのデータ(残す) |

確認できたら、実際に外す。

```powershell
& "$env:LOCALAPPDATA\hermes\hermes-agent\venv\Scripts\hermes.exe" uninstall
```

選択肢が3つ出る。「1) Keep data」(プログラムだけ消し、設定・会話・ログは残す)、「2) Full uninstall」(データも全部消す)、「3) Cancel」(やめる)だ。1を選び、確認の`yes`を打つ。2は選ばない。

![uninstallの選択画面。1を選び、確認で「yes」と打ったところ。赤枠で「1) Keep data」、入力した1、yesを示している](/images/hermes-vps/hermes-vps-07-store-uninstall-confirm.png)

実行すると、削除の経過が流れる。実際に動かした環境では、途中で「Could not fully remove」の警告が出た。末尾には「Uninstall Complete!」と、設定とデータを残した旨が出ている。警告が出ているときは、プログラム本体のフォルダが残っており、手動でアンインストールが必要だ。

![uninstallの実行結果。「Could not fully remove」の警告と「You may need to manually remove it」が出たあと、「Uninstall Complete!」と、設定とデータを保持した旨が表示されている](/images/hermes-vps/hermes-vps-07-store-uninstall-result.png)

手動で消すには、次のコマンドでプログラム本体のフォルダを削除する。

```powershell
Remove-Item -LiteralPath "$env:LOCALAPPDATA\hermes\hermes-agent" -Recurse -Force
```

古いデスクトップのショートカット「Hermes」も残る。スタートメニュー(`%APPDATA%\Microsoft\Windows\Start Menu\Programs\Hermes.lnk`)とデスクトップに残り、Store版の「Hermes Agent」と2つ並んで見える。リンク先の`Hermes.exe`はもう無いので、どちらも右クリックして削除する。`uninstall`の出力は「No packaged desktop app found in standard locations」で、ショートカットは対象外だった。

最後に、結果を確かめる。

```powershell
Get-Command hermes -All | Format-Table CommandType, Source
Test-Path "$env:LOCALAPPDATA\hermes\hermes-agent"
Test-Path "$env:LOCALAPPDATA\hermes\config.yaml"
```

1行目でStore版(`Microsoft\WindowsApps\hermes.exe`)だけが出て、2行目が`False`(プログラム本体は消えた)、3行目が`True`(設定は残った)なら成功だ。

![確認コマンドの出力。hermesはMicrosoft\WindowsAppsのStore版だけが出て、hermes-agentフォルダはFalse、config.yamlはTrueになっている](/images/hermes-vps/hermes-vps-07-store-uninstall-check.png)

## アプリが起動しないときの直し方

:::message
この節は、公式サイトのインストーラで入れたダウンロード版で起きた話だ。Store版で同じ症状が出るかは確かめていない。問題なく起動できた人は、読み飛ばして次へ進んでよい。
:::

インストールは完了したのに、アプリが起動しない。私もこれに当たった。ダブルクリックしてもウィンドウが出てこない。ChromeやEdgeは普通に開くのに、Hermes Desktopだけが反応しない。

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
`--no-sandbox`が切るのは、あくまでHermes Desktopの画面描画プロセスのサンドボックス機能だけ。第4回で設定したエージェントのコマンド実行(Dockerコンテナ隔離)とは別の話で、エージェント側の安全対策は何も変わらない。とはいえブラウザ由来の保護を1つ外すのは事実なので、最終的にはGPUドライバを最新に更新して、`--no-sandbox`なしで起動できる状態を目指すのがよい。
:::

## よくあるエラーと対処

| 症状 | 対処 |
|---|---|
| `hermes dashboard --host <tailscale-ip>`が起動せず終了する | 認証未設定で外向きbindを拒否している(fail-closed)。認証情報を`.env`に入れてから再起動。systemd経由なら`EnvironmentFile=%h/.hermes/.env`が付いているか確認 |
| Desktopが「backendはready」と言うのにチャットが繋がらない | 「保存して再接続」を押していない可能性が高い。押したうえで、VPS側はTailscale IPにbindし、リモートURLも同じIPにする。`127.0.0.1`にbindすると自分のパソコンからは届かない |
| アプリを再起動するたびにログインが切れる | `HERMES_DASHBOARD_BASIC_AUTH_SECRET`が未設定。`openssl rand -base64 32`で固定値を`.env`に入れる |
| サインインで「Invalid credentials / 401」 | ユーザー名かパスワードが`.env`と不一致。`curl -s http://<host>:9119/api/status \| jq '.auth_providers'`に`"basic"`が出るか確認 |
| `hermes dashboard`が「何かを入れろ」と出て起動しない | Web部品が未導入。`cd ~/hermes-agent && pip install -e '.[web]'` |
| Storeで「入手」を押してもなかなか終わらない | 約2.41GBのダウンロードで、この回の環境で1回だけ測った値では約10分だった。進捗が動いていれば待つ |
| Hermes Desktopが起動直後に落ちる・真っ白のまま固まる(ダウンロード版) | GPUとChromiumサンドボックスの相性問題(終了コード`0x80000003`、[#38216](https://github.com/NousResearch/hermes-agent/issues/38216))。[アプリが起動しないときの直し方](#アプリが起動しないときの直し方)を参照 |
| Ctrl+Kが効かない | Macでは`Cmd+K`。それでも開かなければアプリのキーボードショートカット設定を確認 |
| gatewayを止めたらdashboardも止まると思った | 両者は別プロセス。dashboardはdashboardで常駐させる。逆にdashboardを動かしてもTelegram等は常駐済みgatewayが別途必要 |

## コマンド早見表

```bash
# VPS側(接続先dashboardの常駐)
hermes dashboard --help                                   # Web部品が入っているか確認
systemctl --user enable --now hermes-dashboard            # systemd常駐
curl -s http://<tailscale-ip>:9119/api/status | jq '.auth_required, .auth_providers'  # 認証確認

# 自分のパソコン側(Windows)
# Microsoft Storeで「Hermes Agent」を検索 → 入手 → 開く
# 更新: Microsoft Storeから届く

# Hermes Desktopアプリ内
# 設定 → ゲートウェイ → このウィンドウ → 「リモートゲートウェイ」
#   リモートURL: http://<tailscale-ip>:9119
#   サインイン: admin + password(別ウィンドウ) → 「保存して再接続」
# Ctrl+K(MacではCmd+K): コマンドパレット / 入力欄のモデルピッカー: モデル切替 / /undo: 会話の巻き戻し

# ダウンロード版を外すとき(PowerShell)
& "$env:LOCALAPPDATA\hermes\hermes-agent\venv\Scripts\hermes.exe" uninstall --dry-run   # 予行(何も変えない)
```

## 引用元と参考

| 項目 | 引用元 |
|---|---|
| Hermes Desktop全般・CLIと同じエージェント核・リモート接続UI | [docs/user-guide/desktop](https://hermes-agent.nousresearch.com/docs/user-guide/desktop) |
| v0.16.0「Surface Release」の新機能(Desktop正式化・Ctrl+K・drag&drop・モデル切替・self-update(ダウンロード版)・/undo) | [release v2026.6.5](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.6.5) = v0.16.0 |
| 接続先dashboardのprerequisites・認証env var・fail-closed・Tailscale bind | [web-dashboard](https://hermes-agent.nousresearch.com/docs/user-guide/features/web-dashboard)「Connecting Hermes Desktop to a remote backend」 |
| Microsoft Store版の配信開始の告知(2026-10-08) | [Nous Researchの告知](https://x.com/NousResearch/status/2108231536772596193) |
| Microsoft StoreのHermes Agentのページ | [Microsoft Store](https://apps.microsoft.com/detail/9pmxk8czc7kr) |
| Store版の要件(Windows 11 22H2以降)・ダウンロード版との違い | [windows-native](https://hermes-agent.nousresearch.com/docs/user-guide/windows-native) |
| Store版の更新(Microsoft Storeから届く) | [updating](https://hermes-agent.nousresearch.com/docs/getting-started/updating) |
| ダウンロード版のインストール(旧手順) | [installation](https://hermes-agent.nousresearch.com/docs/getting-started/installation) |
| 起動直後crashの既知issue(`--no-sandbox`) | [#38216](https://github.com/NousResearch/hermes-agent/issues/38216) |
| Hermes Desktopの解説(日本語) | 公式ドキュメントの日本語訳: [Desktop](https://wiki.winsmux.dev/hermes/docs/user-guide/desktop/) / [Windowsで動かす(Store版の要件)](https://wiki.winsmux.dev/hermes/docs/user-guide/windows-native/) / [複数の接続先を使い分ける](https://wiki.winsmux.dev/hermes/docs/user-guide/multi-connection-desktop/) |
| Hermes全体の解説(日本語) | 公式ドキュメントの日本語訳: [Hermes全文](https://wiki.winsmux.dev/hermes/guide/all/) |

:::message
この連載はSubstack「そらのAIエージェント通信」で先行公開している。無料[登録](https://sorabiz.substack.com/subscribe)すると最新回がメールに届く。[Zennでフォロー](https://zenn.dev/sora_biz)すると新着通知が届き、全体像は[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::
