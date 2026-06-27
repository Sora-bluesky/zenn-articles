---
title: "【第6回】Hermes Agentをsystemdで常時起動させる方法"
emoji: "🤖"
type: "tech"
topics: ["ai", "hermes", "systemd", "linux", "vps"]
published: true
---

## 目次

- [この回の到達点](#この回の到達点)
- [systemdとは何か](#systemdとは何か)
- [第6回終了時点の構成図](#第6回終了時点の構成図)
- [事前準備](#事前準備)
- [ユーザーunitを生成する](#ユーザーunitを生成する)
- [生成されたunitを読み解く](#生成されたunitを読み解く)
- [op runで秘密を渡すdrop-inを足す](#op-runで秘密を渡すdrop-inを足す)
- [起動・停止・再起動を操作する](#起動・停止・再起動を操作する)
- [ログを永続的に追えるようにする](#ログを永続的に追えるようにする)
- [TelegramとDiscordで疎通を確認する](#telegramとdiscordで疎通を確認する)
- [providerを切り替える](#providerを切り替える)
- [コンテナ隔離と承認モード](#コンテナ隔離と承認モード)
- [VPS再起動後も自動で立ち上がるか確認する](#vps再起動後も自動で立ち上がるか確認する)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [まとめと第7回予告](#まとめと第7回予告)
- [引用元と参考](#引用元と参考)

第5回で「Codex+Grok(頭脳2系統)+Telegram+Discord(出入口2系統)」までは揃った。ただこの時点ではSSHでログインして`op run -- hermes gateway`を手で叩いている状態で、SSHを切ると会話相手はいなくなる。

第6回はその手起動をやめて、VPSが起動した瞬間にHermes Agentが勝手に立ち上がる常駐運用に切り替える。Linuxの標準機構であるsystemdに登録するだけで、SSH切断・VPS再起動・プロセスの異常終了のすべてを自動で面倒見てくれる状態になる。

シリーズの全体像はこちら。

:::details シリーズのもくじ(タップで開く)

**第I部 体を作る**
- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy) Hermes AgentをVPSにデプロイする方法
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale) Hermes Agentの接続を安全にする方法
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password) Hermes Agentの認証情報を安全に管理する方法
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install) Hermes AgentをDockerで隔離して動かす方法
- [第5回](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord) Hermes AgentにGrokとDiscordを連携させる
- **第6回**(本記事) Hermes Agentをsystemdで常時起動させる方法

**第II部 顔と操作席**
- [第7回](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop) Hermes Agentをデスクトップアプリで操作する方法
- [第8回](https://zenn.dev/sora_biz/articles/hermes-vps-08-dashboard) Hermes AgentをWeb Dashboardで管理する方法

**第III部 生活リズム**
- [第9回](https://zenn.dev/sora_biz/articles/hermes-vps-09-cron) Hermes Agentに毎朝のタスクを自動実行させる
- [第10回](https://zenn.dev/sora_biz/articles/hermes-vps-10-skills) Hermes Agentが使うほど賢くなるSkillsの登録方法
- [第11回](https://zenn.dev/sora_biz/articles/hermes-vps-11-web-search) Hermes Agentに最新情報を自動取得させる方法

**第IV部 記憶を分けて育てる**
- [第12回](https://zenn.dev/sora_biz/articles/hermes-vps-12-memory) Hermes AgentにMemoryで好みと前提を記憶させる
- [第13回](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) Hermes AgentとObsidianを連携して知識を共有する方法
- [第14回](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) Hermes Agentに過去の会話を自動で復元させる

全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

所要時間の目安は60〜90分(うちVPS再起動の待ち時間が10分前後)。手を動かすのは10コマンド程度で、`hermes gateway install`という公式コマンドが入ったので、手書きでunitファイルを書く必要はない。

## この回の到達点

第5回完了時と第6回完了後の差分を表にする。

| 項目 | 第5回完了時 | 第6回完了後 |
|---|---|---|
| `hermes gateway`起動 | SSHで手動`op run -- hermes gateway` | **systemdユーザーunitで自動起動** |
| SSH切断時 | プロセス終了→Telegram/Discord応答停止 | **継続動作**(SSHから独立) |
| VPS再起動時 | 起動しなおしてSSH→`op run`が必要 | **自動復帰** |
| 異常終了時 | 気づかない/手動再起動 | **systemdが自動再起動+ログ収集** |
| ログの場所 | ターミナル画面(SSH切ると消える) | **`journalctl --user`で永続的に追える** |
| Telegram/Discord疎通 | 第4回でTelegramだけ確認 | **両方で挨拶+具体的な指示の往復が成立** |
| 安全境界 | 設定だけ確認(`approvals.mode=manual`) | **コマンドはコンテナ内で隔離実行**(ホスト無傷) |

第6回でやることを一言でまとめると「Hermes Agentの起動・監視・ログ収集をsystemdに任せて、人間はTelegram/Discordから話しかけるだけにする」。

## systemdとは何か

### 一言で言うと

systemdはLinuxの「裏方の管理係」。パソコンを起動したときに、利用者が見えないところで勝手に立ち上がるサービス(常駐プロセス)をまとめて世話する仕組み。

Windowsで例えると、PCを起動した瞬間にバックグラウンドで動き始める「サービス」や、決まった時間に自動実行される「タスクスケジューラ」と役割が近い。

Ubuntu 26.04を含む今どきのLinuxは、起動直後にsystemdが最初に走り、そこからDocker・SSH・cron・ネットワーク管理などのサービスをすべて起こす設計になっている。第4回でDockerをインストールしたとき`systemd serviceに登録`という表示が出ていたのも同じ仕組みだ。

### なぜhermes gatewayをsystemdに預けるのか

第4回から第5回まではSSHでVPSにログインして、手動で`hermes gateway`を起動していた。この方式には3つの問題がある。

1. **SSHを切るとhermesも止まる**:ターミナルを閉じた瞬間にプロセスが終わるので、Telegram/Discordから話しかけても返事が来ない
2. **VPS再起動で消える**:メンテや障害でVPSが再起動すると、SSHログインしなおして手動で立ち上げる必要がある
3. **何かの拍子に落ちたら気づけない**:24時間動かす前提なのに、勝手に止まっていても誰も復旧できない

systemdに登録すると、これらが解決する。

| 課題 | systemdが代わりにやってくれること |
|---|---|
| SSHを切ると止まる | バックグラウンドで動き続ける(ログアウトしても継続) |
| 再起動で消える | VPS起動時に自動で立ち上げ直す |
| 落ちても気づけない | 異常終了を検知して自動再起動+ログ収集 |

### 「ユーザーunit」を選ぶ理由

systemdに登録する設定ファイルを「unit」と呼ぶ。unitには2種類ある。

- **システム全体unit**…`/etc/systemd/system/`配下に置く。`sudo`が必要で、OS起動と同時に立ち上がる
- **ユーザーunit**…`~/.config/systemd/user/`配下に置く。`sudo`不要で、adminユーザーのログインセッションに紐づく

今回はadminユーザー専用にしたいのでユーザーunitを使う。理由は2つ。

1. `sudo`を使わない方式なので、管理権限の事故リスクを減らせる
2. 1Password Service Accountの認証情報やhermesのvenvがadminユーザー配下にある→ユーザーunitと相性が良い

ユーザーunitはデフォルトだとadminがログアウトすると止まるが、lingerという設定を有効にすると、ログイン状態と無関係に常駐し続ける。このlingerは、後述の`hermes gateway install`が自動で有効化してくれる(手動で`loginctl enable-linger`を打つ必要はない)。

## 第6回終了時点の構成図

systemd・hermes gateway・messengerの3層に焦点を絞った構成。

![第6回終了時点の構成図(systemdが常駐管理人、ユーザーはTelegram/Discordから話しかけるだけ)](/images/hermes-vps/hermes-vps-06-architecture.png)

ポイントは、ユーザーが触るのはTelegram/Discordの画面だけになる点。SSHを開かない・VPSを意識しない・hermesの起動を意識しない、という運用に切り替わる。

## 事前準備


### 4-1. VPSにSSHで入る

PowerShell(またはWindows Terminal)から、第2回で設定した鍵+ホスト名でVPSに入る。

```powershell
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps
```

第2回でTailscaleを入れた読者は、`hermes-vps`がTailnetのMagicDNS名で解決される。第1回までで止まっている読者はTailscale経由ではなくグローバルIP+22番(または変更後ポート)でアクセスする必要がある。

### 4-2. 作業ディレクトリへ移動してvenv有効化

```bash
cd ~/hermes-agent
source venv/bin/activate
```

プロンプトの先頭に`(venv)`が付けば成功。

### 4-3. 第5回完了時点のチェック

第5回完了時点で揃っているべきものを順に確認する。1つでも欠けていると後段の`hermes gateway install`が失敗する。

| 確認項目 | 確認コマンド | 期待される結果 |
|---|---|---|
| Codex/Grok両方のOAuth登録 | `hermes auth list` | `openai-codex (1 credentials)`と`xai-oauth (1 credentials)`が並ぶ |
| 承認モードmanual | `grep "mode:" ~/.hermes/config.yaml` | `mode: manual`(approvalsセクション内) |
| Telegram bot有効 | `grep -A2 "telegram:" ~/.hermes/config.yaml` | `enabled: true` |
| Discord bot有効 | `grep -A2 "discord:" ~/.hermes/config.yaml` | `enabled: true` |
| 1Passwordサービスアカウント | `cat ~/.hermes/service-account.env` | `OP_SERVICE_ACCOUNT_TOKEN=ops_...`の1行 |
| op run疎通 | `op run --env-file=$HOME/.hermes/secrets.env -- env \| grep TOKEN` | TELEGRAM/DISCORDの両tokenが実値展開される |


## ユーザーunitを生成する

第4回の`hermes setup gateway`で「Install gateway as systemd?」に**N**で答えたが、ここで改めて`hermes gateway install`を実行する。**フラグは付けない**——フラグなしで実行すると、adminのユーザーunitとして生成される(`--user`というオプションは存在しない)。一方`sudo hermes gateway install --system`を付けると、ログイン状態に依存しないboot-time system serviceになる(rootではなく、あなたのユーザーとして走る。linger不要なのでVPS・ヘッドレス向き)。本シリーズはユーザーunit+lingerで進めるが、VPSなら`--system`も選べる。出典:[Messaging Gateway(systemd)](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/)。

```bash
cd ~/hermes-agent
source venv/bin/activate
hermes gateway install
```

実行すると、対話形式で2つの質問が順に出る。

```
Start the gateway now after installing the service? [Y/n]: Y
Start the gateway automatically on login/boot with systemd? [Y/n]: Y
```

| 質問 | 意味 | 本記事の回答 |
|---|---|---|
| Start the gateway now …? | install直後に今すぐ起動するか | Y(すぐ起動して確認したいため) |
| Start … automatically on login/boot …? | ログイン/起動時に自動起動するか | Y(常駐の核心。再起動後も自動復帰) |

両方に**Y**で答えると、次のような出力でユーザーunitの生成・linger有効化・起動までが一気に終わる。

```
Installing user systemd service to: /home/admin/.config/systemd/user/hermes-gateway.service
✓ User service installed!
…
Enabling linger so the gateway survives SSH logout...
✓ Linger enabled — gateway will persist after logout
✓ User service started
```

注目すべきは`✓ Linger enabled`の行。**lingerは`hermes gateway install`が自動で有効化する**ので、手動で`sudo loginctl enable-linger`を打つ必要はない。

:::message
2問目に**n**と答えると、サービスは作られて今は起動するが、再起動後に自動復帰しない(enableされない)。やり直しは不要で、後から`systemctl --user enable hermes-gateway`を1回打てば有効化できる(linger自体はinstallが有効化済み)。
:::

生成先を確認する。

```bash
ls -la ~/.config/systemd/user/hermes-gateway.service
```

## 生成されたunitを読み解く

生成されたunitの中身を見る。

```bash
systemctl --user cat hermes-gateway
```

`hermes gateway install`が書き出した本体は次の内容だ(抜粋)。

```ini
[Unit]
Description=Hermes Agent Gateway - Messaging Platform Integration
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/home/admin/hermes-agent/venv/bin/python -m hermes_cli.main gateway run --replace
WorkingDirectory=/home/admin/hermes-agent
Environment="HERMES_HOME=/home/admin/.hermes"
Restart=always
RestartSec=5
RestartForceExitStatus=75
KillMode=mixed
ExecReload=/bin/kill -USR1 $MAINPID
TimeoutStopSec=210

[Install]
WantedBy=default.target
```

主要な行の意味。

| 行 | 意味 |
|---|---|
| `ExecStart=` | 起動コマンド本体。venvのpythonが`gateway run`を起動する |
| `Restart=always` | 異常終了でも通常終了でも、必ず起動し直す(24時間常駐の要) |
| `RestartForceExitStatus=75` | 終了コード75は「計画的な再起動要求」として即起動し直す印 |
| `ExecReload=/bin/kill -USR1` | リロード信号(SIGUSR1)で、処理中タスクを取りこぼさず再起動する |
| `TimeoutStopSec=210` | 停止時に最大210秒待つ(実行中タスクの完了を待つため) |
| `WantedBy=default.target` | ユーザーセッション開始時に自動起動する |

:::message alert
**ここが最大の注意点**:`ExecStart=`が`op run`を経由していない。venvのpythonを直接起動するだけだ。つまりこのまま起動すると、第3回で組んだ1Password(`op run`が`op://`参照を実トークンに展開する仕組み)が働かず、TelegramもDiscordもトークンを受け取れない。プロセス自体は起動するが「No messaging platforms enabled(messengerが1つも有効になっていない)」状態になる。
:::

`hermes gateway install`は「venvのpythonを常駐させる」ところまでは面倒を見るが、「秘密情報をどう注入するか」は環境ごとに違うので踏み込まない。本シリーズは1Password+`op run`方式なので、生成されたunitに`op run`の衣を着せてやる必要がある。

## op runで秘密を渡すdrop-inを足す

unit本体を手で書き換えるのは避ける。`hermes gateway restart`や`hermes update`が本体unitを再生成する場面があり、手編集は上書きで消えるからだ(出典:[hermes_cli/gateway.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/gateway.py)の`refresh_systemd_unit_if_needed`)。

そこでsystemdの**drop-in**を使う。drop-inは本体unitの上に設定を後付けで重ねる仕組みで、本体を書き換えないので再生成されても消えない。

`~/.config/systemd/user/hermes-gateway.service.d/op-run.conf`を作る。

```bash
mkdir -p ~/.config/systemd/user/hermes-gateway.service.d
cat > ~/.config/systemd/user/hermes-gateway.service.d/op-run.conf <<'EOF'
[Service]
EnvironmentFile=%h/.hermes/service-account.env
ExecStart=
ExecStart=/usr/bin/op run --env-file=%h/.hermes/secrets.env -- %h/hermes-agent/venv/bin/python -m hermes_cli.main gateway run --replace
EOF
```

3行の意味は次のとおり。

| 行 | 役割 |
|---|---|
| `EnvironmentFile=...service-account.env` | 1Passwordサービスアカウントのトークンを読み込む。`op run`がこれを使って`op://`参照を解決する |
| `ExecStart=`(空の代入) | 本体unitの`ExecStart`を一度消す。systemdは空代入で前の値をクリアする仕様で、起動コマンドが二重になるのを防ぐために必須 |
| `ExecStart=/usr/bin/op run ...` | 起動コマンドを`op run`でくるみ直す。これで`secrets.env`の`op://`参照が実トークンに展開されてからgatewayが起動する |

`%h`はそのユーザーのホームディレクトリ(`/home/admin`)に展開されるsystemdの変数だ。これでsystemd常駐の下ごしらえは完了。次の章で実際に起動する。

![systemctl --user cat hermes-gatewayの出力。本体unit(ExecStartはop run無し)の下にop-runドロップインが重なって読み込まれている](/images/hermes-vps/hermes-vps-06-unit-cat.png)

## 起動・停止・再起動を操作する

ドロップインをsystemdに反映して、サービスを起動し直す。installの段階で起動・自動起動(enable)・lingerはすでに済んでいるので、ここで打つのは「再読込」と「再起動」が中心になる。`sudo`は使わない。

```bash
# 1. ドロップインをsystemdに認識させる
systemctl --user daemon-reload

# 2. 自動起動を有効化(installの2問目をnにした場合の保険。Yなら既に有効)
systemctl --user enable hermes-gateway.service

# 3. ドロップインを反映するため再起動
systemctl --user restart hermes-gateway.service

# 4. 状態確認
systemctl --user is-active hermes-gateway.service
systemctl --user status hermes-gateway.service
```

成功していれば、`is-active`は`active`、`status`の先頭は`active (running)`になり、Main PIDはop run(秘密を渡すラッパー)を指す。フラップ(再起動ループ)していなければ`NRestarts=0`だ。

```text
active
ActiveState=active
SubState=running
NRestarts=0
```

![systemctl --user statusでactive (running)・Main PIDがop・ドロップイン(op-run.conf)が認識されている画面](/images/hermes-vps/hermes-vps-06-service-status.png)

![systemctl --user showでis-active=active・NRestarts=0(フラップしていない証拠)](/images/hermes-vps/hermes-vps-06-active-nrestarts.png)

:::message
lingerはadminユーザーの「居残り権限」(SSHログアウト後もユーザーサービスを動かし続ける設定)で、これが無いとログアウト時にsystemdユーザーマネージャーごと止まってhermesも止まる。本シリーズでは`hermes gateway install`が自動で有効化済みなので、手動操作は不要。`loginctl show-user "$USER" | grep -i Linger`で`Linger=yes`を確認できる。
:::

## ログを永続的に追えるようにする

hermesの標準出力・標準エラーはsystemdが自動でjournalに記録する。SSHのターミナル画面と違って、ログアウトしても消えない。

```bash
# 直近100行
journalctl --user -u hermes-gateway.service -n 100

# リアルタイムで追従(Ctrl+Cで抜ける)
journalctl --user -u hermes-gateway.service -f

# 今日のログだけ
journalctl --user -u hermes-gateway.service --since today
```

ドロップイン反映後は秘密が渡るので`No messaging platforms enabled`は出なくなり、`Started hermes-gateway.service`に続いて警告がいくつか出る。次の3つはいずれも無害だ。

```text
WARNING gateway.run: Docker backend is enabled ... no explicit host-visible output mount ... is configured.
WARNING hermes_plugins.discord_platform.adapter: Opus codec not found — voice channel playback disabled
WARNING tools.environments.docker: Docker storage driver does not support per-container disk limits ...
```

`Docker backend ... output mount`はメディア配信のときだけ影響、`Opus codec not found`はボイス再生のみ無効、`Docker storage driver ... disk limits`はディスク上限が付かないだけで、Telegram/Discordのテキストやり取りには関係ない。

## TelegramとDiscordで疎通を確認する

systemd経由で起動したhermesに、Telegram・Discord両方から話しかける。第4回でTelegram単体の挨拶は確認済みなので、本章では「両方の経路が並行で生きている」ことを示す。

まずTelegram。botに「hello」と送ると挨拶が返る。

![Telegramでbotに話しかけると挨拶が返る(systemd常駐下で稼働)](/images/hermes-vps/hermes-vps-06-telegram-reply.png)

次にDiscord。第5回で招待したサーバーでbotにメンションすると、同じように返事が来る。常駐起動時には`Gateway online — Hermes is back and ready.`の通知も届く。

![Discordサーバーでbotにメンションすると返信が来る](/images/hermes-vps/hermes-vps-06-discord-reply.png)

SSHを切っても(`exit`)、Telegram/Discordから話しかければ返事が来る。これがSSHから独立して動くsystemd常駐の証拠だ。

## providerを切り替える

第5回で2系統登録したprovider(Codex/Grok)が、両方とも実際に応答するか確認する。Hermes Agentは`/provider`コマンドで会話中に切り替えられる。

Telegramで以下を順に送る。

```
/provider openai-codex
今日の日付を教えて
/provider xai-oauth
今日の日付を教えて
```

`/provider`で切り替えると、Hermesが新しいモデルとprovider情報を返す。例えば`xai-oauth`に切り替えると、grok系モデルへの切り替えが表示される。

```text
Model switched to grok-4.3
Provider: xAI Grok OAuth (SuperGrok / Premium+)
Context: 1,000,000 tokens
Max output: 30,000 tokens
(session only — add --global to persist)
```

![Telegramで/provider xai-oauthに切り替え、grok系モデルに切り替わった応答が返る](/images/hermes-vps/hermes-vps-06-provider-switch.png)

両方から日付付きの返答が返ってくれば、OAuth登録・provider切り替えの動作確認は完了。

## コンテナ隔離と承認モード

第5回で`approvals.mode=manual`(危険なコマンドの前に人間へ確認を求める安全弁)を設定した。ただし**本シリーズの構成では、この承認プロンプトは原則出ない**。理由を理解しておくと混乱しない。

第4回でコマンドの実行場所(backend)を`docker`にした。これはエージェントのコマンドを**隔離されたDockerコンテナの中で実行する**設定だ。ここでの「ホスト」とは、第1回で契約したVPS本体——あなたのSSHログイン鍵、1Passwordのトークン、sshdやsystemdの設定が載っている土台——を指す。コンテナはそのホストから壁で仕切られているので、エージェントがコンテナの中で何をしようと、ホスト側のファイルやプロセスには手が届かない。もし実行場所を`local`にしてホスト上で直接動かしていたら、`rm`の打ち間違い一発でSSHログイン鍵やトークンごと消え、VPSに二度と入れなくなる事故もあり得た。第4回でDockerを選んだのは、それを先回りで防ぐためだ。

公式ドキュメントはこう明記している。

> When running in a container backend (Docker...), dangerous command checks are skipped because the container is the security boundary.
> (コンテナの中で動かす場合、コンテナ自体が安全境界なので、危険コマンドのチェックはスキップされる)
> 出典:[Hermes Agent公式tipsガイド](https://hermes-agent.nousresearch.com/docs/guides/tips)

つまり、**安全を担保しているのは「1回ずつの承認」ではなく「コンテナによる隔離」だ**。試しにTelegramで「カレントディレクトリのファイル一覧を見せて」と送ると、承認を挟まず即実行されて結果が返る。コンテナの外(ホスト)に害が及ばないので、いちいち止めない、という設計だ。

![Telegramで「ファイル一覧を見せて」と送ると、承認を挟まずコンテナ内で即実行され結果が返る](/images/hermes-vps/hermes-vps-06-sandbox-noprompt.png)

:::message alert
**「コンテナ内なら何でも安全」ではない**:隔離が守るのは**ホスト**(VPS本体)だ。コンテナの中では、エージェントはファイルの作成・上書き・削除を確認なしで行える。うっかり消えると困るデータをコンテナ内に置かないこと、そして**誰がエージェントに指示できるかをallowlistで絞ること**(第5回の数値ユーザーID)が、隔離と並ぶ防御線になる。「ホストは守られる」ことと「コンテナの中なら絶対安全」は別の話だ。
:::

:::message
**承認モードはいつ効くのか**:もし実行場所を`local`(ローカル=ホスト上で直接実行)に戻すと、今度は承認プロンプトが復活し、`rm`等の危険コマンドの前に確認が入る。ローカル実行は速いがホストに直接触れるので、その場合の安全弁として`manual`が活きる。本シリーズはコンテナ隔離を主、承認モードを従とする二段構えだ。
:::

## VPS再起動後も自動で立ち上がるか確認する

systemd常駐の最終確認として、VPSを再起動してhermesが勝手に復帰するか見る。

```bash
# 1. 再起動直前の状態を記録
systemctl --user is-active hermes-gateway.service
# 期待値:active

# 2. VPS再起動(SSHは切断される)
sudo reboot

# 3. 1〜2分待ってからSSH再ログイン
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps

# 4. hermesが自動で起動しているか確認
systemctl --user is-active hermes-gateway.service
# 期待値:active(=lingerが効いてユーザーマネージャー経由で自動起動した)

# 5. ログで起動時刻を確認
journalctl --user -u hermes-gateway.service --since "5 minutes ago"
```

再接続して値を見ると、再起動→自動復帰→疎通までが揃っているのが分かる。

```text
20:05:48 up 2 min,  1 user,  load average: 0.31, 0.09, 0.03
ActiveState=active
SubState=running
ActiveEnterTimestamp=Fri 2026-05-29 20:03:33 JST
NRestarts=0
Linger=yes
```

`up 2 min`で再起動を、`ActiveEnterTimestamp`がboot直後を指すことで「手を触れず自動で立ち上がった」ことを、`NRestarts=0`で安定を、`Linger=yes`で常駐の土台を、それぞれ値で裏取りできる。

![sudo reboot実行でSSHが切れる画面](/images/hermes-vps/hermes-vps-06-reboot.png)

![再接続後、uptimeが数分・is-active=active・ActiveEnterTimestampがreboot直後を指す(手動操作なしで自動復帰した証拠)](/images/hermes-vps/hermes-vps-06-reboot-recovery.png)

このタイミングでSSHを開かずにスマホのTelegramから「hello」を送って返信が来れば、24時間常駐運用の完成。第4回・第5回で「動くけどSSHが必要」だったHermes Agentが、ここでようやく「VPSの上で勝手に動き続ける」状態に切り替わる。

## よくあるエラーと対処

| 症状 | 対処 |
|---|---|
| `systemctl --user status`が`failed`になる | `journalctl --user -u hermes-gateway.service -n 200`でExecStart直後のエラーを読む。多くは、(a)`op://`参照の解決失敗(`service-account.env`のtoken失効)、(b)Discord/Telegram tokenの参照ミス、(c)venvパスが`ExecStart`から見えていない、のいずれか |
| `enable hermes-gateway.service`で`Failed to enable: No such file or directory` | unitファイルのパスが`~/.config/systemd/user/`になっていない。`hermes gateway install --force`で再生成する |
| SSHログアウト後にhermesが止まる | lingerが無効。`loginctl show-user admin \| grep Linger`で`Linger=yes`を確認(通常はinstallが自動で有効化済み)。無効なら`loginctl enable-linger admin`を1回実行 |
| `journalctl --user`に何も出ない | (a)ユーザーマネージャー自体が起動していない場合は`systemctl --user status`で全体状態を確認、(b)journaldのrate limitに引っかかっている場合は`/etc/systemd/journald.conf`の`RateLimitBurst`を確認 |
| VPS再起動後にhermesが起動しない | (a)`systemctl --user is-enabled hermes-gateway.service`で`enabled`を確認(installの2問目をnにしたなら`enable`を打つ)、(b)`loginctl show-user admin \| grep Linger`で`Linger=yes`を確認、(c)`op run`の`service-account.env`のtokenが期限切れの場合は1Passwordで再発行 |
| Telegram/Discordの片方だけ応答しない | `journalctl --user -u hermes-gateway.service -f`でmessenger接続時のエラーログを確認。token失効・Privileged Intent設定(Discord)の取りこぼしが主因 |
| grokが`Could not decrypt the provided encrypted_content`(HTTP 400)を返しセッションが詰まる | 1セッション中にprovider/modelを切り替えた後、旧providerの暗号化推論データを再送するため起きる既知挙動(gateway自体は落ちず別providerにフォールバックすることが多い)。当面はセッション途中でproviderを切り替えない、または詰まったセッションを`sessions.json`で`suspended:true`にして`hermes gateway restart`。v0.15.x以降で再発しにくくなる(完全解消は未確認)。参照:[#32617](https://github.com/NousResearch/hermes-agent/issues/32617) |
| (local backendで)承認プロンプトが出ない | `~/.hermes/config.yaml`の`approvals.mode`が`manual`か確認。なお**Docker backend(本シリーズ既定)では承認は原則出ない**のが正常(本回「コンテナ隔離と承認モード」参照) |
| メモリ消費が増え続ける | `systemctl --user status hermes-gateway.service`のMemory欄で確認。長時間運用で増加が顕著なら[Issues](https://github.com/NousResearch/hermes-agent/issues)で`memory`等のキーワード検索→該当Issueがなければ新規起票 |

## まとめと第7回予告

第6回でやったこと:

- `hermes gateway install`でsystemdユーザーunitが自動生成済み
- `hermes gateway install`がlingerを自動有効化→ログアウト後も常駐する状態
- installの2問目Yで自動起動(enable)が有効。ドロップイン反映は`systemctl --user restart`
- `journalctl --user`でログ収集経路が確立済み
- Telegram+Discord両系統の疎通+SSH切断後の生存を確認済み
- Codex/Grok両providerの応答を確認済み
- Dockerコンテナでエージェントのコマンドが隔離実行され、ホストに触れないことを確認済み(`approvals.mode=manual`はローカル実行時の保険)
- VPS再起動後の自動復帰を確認済み

第6回完了時点で、ユーザーがVPSに触らずにスマホだけでHermes Agentと会話できる状態になった。次は、この同じHermesを「黒い画面(SSH)」以外からも触れるようにしていく。

第7回では、母艦(普段使いのPC)に公式デスクトップアプリ「Hermes Desktop」を入れ、Tailscale越しにVPSのHermesをマウス操作で動かす。コマンドを打たなくても、普通のアプリの窓から同じエージェントを使えるようにする回だ。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第5回 Hermes AgentにGrokとDiscordを連携させる](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord) | [第7回 Hermes Agentをデスクトップアプリで操作する方法](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop) |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## 引用元と参考

| 項目 | 引用元 |
|---|---|
| Hermes Agentリポジトリ | [github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) |
| 本シリーズ参照tag | [release v2026.5.16](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.5.16) = v0.14.0(執筆時点。最新は[v2026.5.29.2](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.5.29.2)=v0.15.2。NoneTypeバグは解消済みで、`hermes gateway install`のフローは最新版でも変わらない) |
| `hermes gateway install`実装 | [hermes_cli/gateway.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/gateway.py) |
| 公式messaging gateway(systemd常駐) | [docs/user-guide/messaging](https://hermes-agent.nousresearch.com/docs/user-guide/messaging/) |
| systemd.unit (man) | [freedesktop.org/.../systemd.unit](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html) |
| systemd.service (man) | [freedesktop.org/.../systemd.service](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html) |
| systemctl (man) | [freedesktop.org/.../systemctl](https://www.freedesktop.org/software/systemd/man/latest/systemctl.html) |
| journalctl (man) | [freedesktop.org/.../journalctl](https://www.freedesktop.org/software/systemd/man/latest/journalctl.html) |
| loginctl (man) | [freedesktop.org/.../loginctl](https://www.freedesktop.org/software/systemd/man/latest/loginctl.html) |
| Arch Wiki:systemd/User | [wiki.archlinux.org/title/Systemd/User](https://wiki.archlinux.org/title/Systemd/User) |
| Ubuntu 26.04:systemd公式 | [ubuntu.com/server/docs/service-management-with-systemd](https://ubuntu.com/server/docs/service-management-with-systemd) |
| 1Password `op run`公式 | [developer.1password.com/docs/cli/secret-references](https://developer.1password.com/docs/cli/secret-references) |
