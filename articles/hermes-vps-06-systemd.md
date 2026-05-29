---
title: "【第6回】Hermes Agent VPS常駐化──systemdで24時間動かす"
emoji: "🤖"
type: "tech"
topics: ["claudecode", "hermes", "systemd", "linux", "vps"]
published: false
---

## 本記事の章ジャンプ

- [この回の到達点](#この回の到達点)
- [systemdとは何か](#systemdとは何か)
- [第6回終了時点の構成図](#第6回終了時点の構成図)
- [事前準備](#事前準備)
- [`hermes gateway install --user`でユーザーunitを生成](#hermes-gateway-install---userでユーザーunitを生成)
- [生成されたunitファイルを読み解く](#生成されたunitファイルを読み解く)
- [`systemctl --user`でhermes gatewayを起動](#systemctl---userでhermes-gatewayを起動)
- [`journalctl --user`でログを追う](#journalctl---userでログを追う)
- [TelegramとDiscordで疎通確認](#telegramとdiscordで疎通確認)
- [provider切り替えの動作確認(Codex→Grok)](#provider切り替えの動作確認(codex→grok))
- [承認モードmanualの動作確認](#承認モードmanualの動作確認)
- [VPS再起動テスト](#vps再起動テスト)
- [まとめと第7回予告](#まとめと第7回予告)
- [Rescue:第6回でよくあるエラー](#rescue%3A%E7%AC%AC6%E5%9B%9E%E3%81%A7%E3%82%88%E3%81%8F%E3%81%82%E3%82%8B%E3%82%A8%E3%83%A9%E3%83%BC)
- [公式ドキュメント引用元](#公式ドキュメント引用元)

第5回で「Codex+Grok(頭脳2系統)+Telegram+Discord(出入口2系統)」までは揃った。ただこの時点ではSSHでログインして`op run -- hermes gateway`を手で叩いている状態で、SSHを切ると会話相手はいなくなる。

第6回はその手起動をやめて、VPSが起動した瞬間にHermes Agentが勝手に立ち上がる常駐運用に切り替える。Linuxの標準機構であるsystemdに登録するだけで、SSH切断・VPS再起動・プロセスの異常終了のすべてを自動で面倒見てくれる状態になる。

シリーズの全体像はこちら。

- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy)──VPSを契約して最小限の安全な状態でadminにログイン
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale)──Tailscaleで公開SSHを閉じる
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password)──1Password Service Accountと`op run`でsecrets管理
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install)──Docker sandboxとHermes Agentのインストール+Codex OAuth+Telegram疎通
- [第5回](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord)──Grok OAuthとDiscordを足す+承認モードの確認
- **第6回(本記事)**──systemd常駐化で24時間動かす
- 第7回──Cronで毎朝の定型タスクを任せる
- 第8回──Skillsに手順を覚えさせる
- 第9回──Web/X検索の使い分け(Firecrawl+SearXNG+X Search)
- 第10回──自宅PCをWake-on-LANで起こす+zellij

所要時間の目安は60〜90分(うちVPS再起動の待ち時間が10分前後)。手を動かすのは10コマンド程度で、`hermes gateway install --user`公式コマンドが入ったので、手書きでunitファイルを書く必要はない。

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
| 承認モード動作 | 設定だけ確認(`approvals.mode=manual`) | **`ls`等のコマンドで実際に承認プロンプトが挟まる** |

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

ユーザーunitはデフォルトだとadminがログアウトすると止まるが、`loginctl enable-linger admin`を一度だけ実行すると、ログイン状態と無関係に常駐し続ける(後述)。

## 第6回終了時点の構成図

systemd・hermes gateway・messengerの3層に焦点を絞った構成。

![第6回終了時点の構成図(systemdが常駐管理人、ユーザーはTelegram/Discordから話しかけるだけ)](/images/hermes-vps/hermes-vps-06-architecture.png)

ポイントは、ユーザーが触るのはTelegram/Discordの画面だけになる点。SSHを開かない・VPSを意識しない・hermesの起動を意識しない、という運用に切り替わる。

## 事前準備

<!-- TBD:実機作業後に追記。以下のチェックリストを実機で1つずつ確認してスクショ撮影 -->

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

<!-- TBD:この章は実機作業中に各コマンドの実出力を貼り付ける。1Password実値はマスク必須 -->

## `hermes gateway install --user`でユーザーunitを生成

<!-- TBD:実機作業 -->

第4回の`hermes setup gateway`で「Install gateway as systemd?」に**N**で答えたが、ここで改めて`hermes gateway install`を実行する(`--user`相当のオプションでユーザーunitとして生成される)。

<!-- TBD:実機検証で確定する事項
- 正式なオプション名(--userか--scope userか)
- 対話形式かフラグ形式か
- EnvironmentFileのデフォルト値
-->

```bash
cd ~/hermes-agent
source venv/bin/activate
hermes gateway install --user
```

<!-- TBD:実機実行時の対話内容(EnvironmentFileパス確認、ExecStart確認、出力先パス確認)を貼り付け -->

<!-- TBD:生成後の確認 -->
```bash
ls -la ~/.config/systemd/user/hermes-gateway.service
```

## 生成されたunitファイルを読み解く

<!-- TBD:実機で生成されたunitの実内容を貼り付け、各行の意味を表で解説 -->

`cat ~/.config/systemd/user/hermes-gateway.service`の出力を読む。第4回のセットアップウィザードで触れたunit構成と、`hermes gateway install`が自動生成した内容を突き合わせて、各行の意味を理解しておく。

<!-- TBD:実機出力を貼り付け後、以下のフォーマットで各ディレクティブを解説
| ディレクティブ | 意味 | このシリーズでの役割 |
|---|---|---|
| `[Unit] Description=` | unitの説明文 | journalctlの表示で使われる |
| `[Service] ExecStart=` | 起動コマンド本体 | `op run -- hermes gateway` |
| `[Service] EnvironmentFile=` | 環境変数ファイル | `service-account.env` |
| `[Service] Restart=` | 異常終了時の挙動 | `on-failure`(自動再起動) |
| `[Install] WantedBy=` | enable時の依存先 | `default.target`(ユーザーセッション開始時) |
-->

## `systemctl --user`でhermes gatewayを起動

<!-- TBD:実機作業 -->

ユーザーunitをsystemdに認識させて、自動起動を有効化(enable)し、起動(start)する。`sudo`は使わない。

```bash
# 1. systemdにunitを再読込させる
systemctl --user daemon-reload

# 2. ログイン状態と無関係に動かす(linger有効化)
sudo loginctl enable-linger admin

# 3. VPS起動時の自動起動を有効化
systemctl --user enable hermes-gateway.service

# 4. 今すぐ起動
systemctl --user start hermes-gateway.service

# 5. 状態確認
systemctl --user status hermes-gateway.service
```

<!-- TBD:status出力(active (running)の表示)を貼り付け、Main PID/Memory/CGroup欄を解説 -->

:::message
`loginctl enable-linger admin`はadminユーザーの「居残り権限」を有効化する。これを実行しないと、SSHログアウト時にsystemdユーザーマネージャーごと停止してhermesも止まる。1度だけ実行すればOK。
:::

## `journalctl --user`でログを追う

<!-- TBD:実機作業 -->

hermesの標準出力・標準エラーはsystemdが自動でjournalに記録する。SSHのターミナル画面と違って、ログアウトしても消えない。

```bash
# 直近100行
journalctl --user -u hermes-gateway.service -n 100

# リアルタイムで追従(Ctrl+Cで抜ける)
journalctl --user -u hermes-gateway.service -f

# 今日のログだけ
journalctl --user -u hermes-gateway.service --since today
```

<!-- TBD:起動直後のログ出力(provider登録/messenger接続/listenポート確認)を貼り付け、注目すべき行をハイライト -->

正常に起動していれば、`Telegram bot connected as @hermes_vps_xxx_bot`と`Discord bot logged in as Hermes VPS#1234`の両方が出力される。

## TelegramとDiscordで疎通確認

<!-- TBD:実機作業。スクショ4枚想定 -->

systemd経由で起動したhermesに、Telegram・Discord両方から話しかける。第4回でTelegram単体の挨拶は確認済みなので、本章では「両方の経路が並行で生きている」ことを示す。

1. スマホのTelegramで`@hermes_vps_xxx_bot`を開いて「hello」と送る→挨拶の返信を確認
   <!-- TBD:スクショ。マスク対象:bot名、user ID -->
2. PCのDiscordで`#hermes-channel`を開いて「hello」と送る→挨拶の返信を確認
   <!-- TBD:スクショ。マスク対象:サーバー名、自分のDiscord ID -->
3. SSHを切る(`exit`または`Ctrl+D`)
4. もう一度Telegramから「are you still alive?」と送る→返信が来ることを確認(systemd常駐の証拠)
   <!-- TBD:スクショ。SSH切断後にTelegramで返信が来ている状態 -->

## provider切り替えの動作確認(Codex→Grok)

<!-- TBD:実機作業 -->

第5回で2系統登録したprovider(Codex/Grok)が、両方とも実際に応答するか確認する。Hermes Agentは`/provider`コマンドで会話中に切り替えられる。

Telegramで以下を順に送る。

```
/provider openai-codex
今日の日付を教えて
/provider xai-oauth
今日の日付を教えて
```

<!-- TBD:両providerからの応答スクショ。返答の文体や絵文字使用に違いが出ることが多い -->

両方から日付付きの返答が返ってくれば、OAuth登録・provider切り替えの動作確認は完了。

## 承認モードmanualの動作確認

<!-- TBD:実機作業 -->

`approvals.mode=manual`を設定した目的は、「Telegram/Discord経由で来た指示でもコマンド実行前に1回確認が挟まる」状態を作ることだった。実際に確認する。

Telegramで以下を送る。

```
カレントディレクトリのファイル一覧を見せて
```

hermesは内部的に`ls`相当のコマンドを実行しようとするが、`approvals.mode=manual`が効いていれば、実行前にTelegramに承認プロンプトが表示される。

<!-- TBD:承認プロンプトのスクショ。「Approve / Deny / Edit」のような選択肢が出るはず -->

「Approve」を押すと実行→結果がTelegramに返ってくる。「Deny」を押すと実行されない。

<!-- TBD:Approve後の結果スクショ、Deny後の挙動スクショ -->

:::message alert
**ここが承認モードの本質**:Discord/Telegramからの指示は誰でも(allowlistに登録された範囲で)送れる経路なので、実行前の人間確認が安全装置として機能する。第5回でmanualに固定した意味が、この章で実際に動く形で見えるはずだ。
:::

## VPS再起動テスト

<!-- TBD:実機作業。所要時間10分前後 -->

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

<!-- TBD:再起動前後のstatus出力スクショ。起動時刻がreboot直後になっていることを確認 -->

このタイミングでSSHを開かずにスマホのTelegramから「hello」を送って返信が来れば、24時間常駐運用の完成。第4回・第5回で「動くけどSSHが必要」だったHermes Agentが、ここでようやく「VPSの上で勝手に動き続ける」状態に切り替わる。

## まとめと第7回予告

第6回でやったこと:

- `hermes gateway install`でsystemdユーザーunitが自動生成済み
- `loginctl enable-linger`でログアウト後も常駐する状態
- `systemctl --user enable + start`でVPS起動時の自動起動が有効
- `journalctl --user`でログ収集経路が確立済み
- Telegram+Discord両系統の疎通+SSH切断後の生存を確認済み
- Codex/Grok両providerの応答を確認済み
- 承認モードmanualが実際に承認プロンプトを挟むことを確認済み
- VPS再起動後の自動復帰を確認済み

第6回完了時点で、ユーザーがVPSに触らずにスマホだけでHermes Agentと会話できる状態になった。次は「会話を待つ」だけでなく「Hermesから話しかけてもらう」運用に進む。

第7回ではCronを使って、毎朝の定型タスク(ニュース要約、当日のスケジュール整理、TODOの提示など)をHermes Agent側から自発的に通知する仕組みを作る。systemdに常駐できたからこそ、Cron+hermesの組み合わせが意味を持つ。

## Rescue:第6回でよくあるエラー

| 症状 | 対処 |
|---|---|
| `systemctl --user status`が`failed`になる | `journalctl --user -u hermes-gateway.service -n 200`でExecStart直後のエラーを読む。多くは、(a)`op://`参照の解決失敗(`service-account.env`のtoken失効)、(b)Discord/Telegram tokenの参照ミス、(c)venvパスが`ExecStart`から見えていない、のいずれか |
| `enable hermes-gateway.service`で`Failed to enable: No such file or directory` | unitファイルのパスが`~/.config/systemd/user/`になっていない。`hermes gateway install --user`を再実行 |
| SSHログアウト後にhermesが止まる | `loginctl enable-linger admin`の実行漏れ。`loginctl show-user admin \| grep Linger`で`Linger=yes`を確認 |
| `journalctl --user`に何も出ない | (a)ユーザーマネージャー自体が起動していない場合は`systemctl --user status`で全体状態を確認、(b)journaldのrate limitに引っかかっている場合は`/etc/systemd/journald.conf`の`RateLimitBurst`を確認 |
| VPS再起動後にhermesが起動しない | (a)`systemctl --user is-enabled hermes-gateway.service`で`enabled`を確認、(b)`loginctl enable-linger admin`の実行漏れがないか確認、(c)`op run`の`service-account.env`のtokenが期限切れの場合は1Passwordで再発行 |
| Telegram/Discordの片方だけ応答しない | `journalctl --user -u hermes-gateway.service -f`でmessenger接続時のエラーログを確認。token失効・Privileged Intent設定(Discord)の取りこぼしが主因 |
| 承認プロンプトがTelegramに出ない | `~/.hermes/config.yaml`の`approvals.mode`を確認。`manual`以外になっていたら再設定 |
| メモリ消費が増え続ける | `systemctl --user status hermes-gateway.service`のMemory欄で確認。長時間運用で増加が顕著なら[Issues](https://github.com/NousResearch/hermes-agent/issues)で`memory`等のキーワード検索→該当Issueがなければ新規起票 |

## 公式ドキュメント引用元

| 項目 | 引用元 |
|---|---|
| Hermes Agentリポジトリ | [github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) |
| 本シリーズ参照tag | [release v2026.5.16](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.5.16) = v0.14.0(main運用) |
| `hermes gateway install`実装 | [hermes_cli/gateway.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/gateway.py) |
<!-- TBD:公式systemd常駐ガイドのURLは実機検証時に確定。
hermes-agent.nousresearch.com/docs/guides/systemdが存在するか確認、
存在しなければGitHub README該当節へのアンカーに差し替え -->
| 公式systemd常駐ガイド | [hermes-agent.nousresearch.com/docs/guides/systemd](https://hermes-agent.nousresearch.com/docs/guides/systemd) |
| systemd.unit (man) | [freedesktop.org/.../systemd.unit](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html) |
| systemd.service (man) | [freedesktop.org/.../systemd.service](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html) |
| systemctl (man) | [freedesktop.org/.../systemctl](https://www.freedesktop.org/software/systemd/man/latest/systemctl.html) |
| journalctl (man) | [freedesktop.org/.../journalctl](https://www.freedesktop.org/software/systemd/man/latest/journalctl.html) |
| loginctl (man) | [freedesktop.org/.../loginctl](https://www.freedesktop.org/software/systemd/man/latest/loginctl.html) |
| Arch Wiki:systemd/User | [wiki.archlinux.org/title/Systemd/User](https://wiki.archlinux.org/title/Systemd/User) |
| Ubuntu 26.04:systemd公式 | [ubuntu.com/server/docs/service-management-with-systemd](https://ubuntu.com/server/docs/service-management-with-systemd) |
| 1Password `op run`公式 | [developer.1password.com/docs/cli/secret-references](https://developer.1password.com/docs/cli/secret-references) |
