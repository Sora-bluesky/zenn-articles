---
title: "【第7回】Hermes Agentが朝から話しかけてくる──Cronで毎朝の定型タスクを任せる"
emoji: "🤖"
type: "tech"
topics: ["claudecode", "hermes", "cron", "自動化", "vps"]
published: false
---

## 目次

- [この回の到達点](#この回の到達点)
- [Cronとは何か](#cronとは何か)
- [第7回終了時点の構成図](#第7回終了時点の構成図)
- [事前準備](#事前準備)
- [スケジュール書式を選ぶ](#スケジュール書式を選ぶ)
- [最初のCronジョブを作る](#最初のcronジョブを作る)
- [ジョブを管理する](#ジョブを管理する)
- [プロンプトは1通の依頼書として書く](#プロンプトは1通の依頼書として書く)
- [公式が示す5つの実用パターン](#公式が示す5つの実用パターン)
- [2つ目のジョブを自分で足す](#2つ目のジョブを自分で足す)
- [まとめと第8回予告](#まとめと第8回予告)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [公式ドキュメント引用元](#公式ドキュメント引用元)

第6回でsystemd常駐が完成し、Hermes AgentはVPSの上で24時間動き続けるようになった。ただ、ここまでは「こちらが話しかけたら返事する」という受け身の状態だ。SSHを切ってもTelegramから呼べば返事は来るが、自分からは何もしてこない。

第7回はここに「自分から動く」を足す。HermesのCron機能を使って、たとえば毎朝7時に今日のニュースとX上の話題を要約してTelegramに届ける、といった定型仕事を任せる。24時間VPSに置いた意味が、ここで一気に出る。

シリーズの全体像はこちら。

- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy)──VPSを契約して最小限の安全な状態でadminにログイン
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale)──Tailscaleで公開SSHを閉じる
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password)──1Password Service Accountと`op run`でsecrets管理
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install)──DockerサンドボックスとHermes Agentのインストール+Codex OAuth+Telegram疎通
- [第5回](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord)──Grok OAuthとDiscordを足す+承認モードの確認
- [第6回](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd)──systemd常駐化で24時間動かす
- **第7回**(本記事)──Cronで毎朝の定型タスクを任せる
- 第8回──Skillsに手順を覚えさせる
- 第9回──Web/X検索の使い分け(Firecrawl+SearXNG+X Search)
- 第10回──自宅PCをWake-on-LANで起こす+zellij

手を動かすのは、VPSにSSHでつないで`hermes cron`コマンドを数行打つだけ。cron式の設定ファイルを手で書く必要はない。登録したジョブの結果は、第4回・第5回でつないだTelegramに届く。

## この回の到達点

第6回完了時と第7回完了後の差分を表にする。

| 項目 | 第6回完了時 | 第7回完了後 |
|---|---|---|
| 常駐 | systemdで24時間動く | 変わらず |
| エージェントの仕事 | 話しかけられたら返事する(受け身) | **決まった時刻に自分から仕事を始める**(能動) |
| 定型作業 | 毎回自分で「ニュース要約して」と打つ | 毎朝7時に勝手にTelegramへ届く |
| ジョブ管理 | 機能なし | `hermes cron list`等で一覧・停止・再開・削除 |

一言でまとめると「Hermesに、毎日の決まった用事を仕込んで、こちらが寝ている間に片付けてもらう」回だ。

## Cronとは何か

HermesのCronは、Linuxに昔からある`crontab`とは別物だ。役割が違う。

- systemd(第6回):サービスを生かし続ける係。プロセスが落ちても起こし直す
- Hermes Cron(第7回):決まった時刻にエージェントを起こして、プロンプトを与え、結果を指定のチャットへ送る係

つまりsystemdが「人を雇い続ける」なら、Cronは「その人に毎朝の業務を割り当てる」イメージだ。

この回で出てくる言葉を先に押さえておく。

| 用語 | 意味 | たとえ |
|---|---|---|
| Cron(クーロン) | 「決まったタイミングで自動的に何かを実行する仕組み」の通称 | 目覚まし時計の設定一覧 |
| cron式 | `分 時 日 月 曜日`の5つで時刻を表す書式。`0 9 * * *`=毎日9時0分 | 「毎週月曜の9時」を表す共通フォーマット |
| delivery target | ジョブの結果をどこへ届けるかの指定(origin/telegram/discord等) | 宅配便を自宅に届けるかオフィスに届けるかの選択 |
| self-contained prompt | 過去の会話を覚えていない前提で、全部書き切った依頼文 | 初対面の人に頼むつもりで全部説明する依頼書 |
| `[SILENT]` | エージェントの最終応答にこの語が入っていると、その回の送信が止まる | 「変化があった時だけ知らせて」設定 |

## 第7回終了時点の構成図

Cronジョブは、第6回で常駐させたHermes Agentの中に登録される。VPSのファイルを手で編集するわけではなく、SSHでつないで`hermes cron`コマンドで登録・管理する。結果の配信先としてTelegram等を指定する。

```text
┌──────────────────────────────────────────────┐
│  VPS(第6回でsystemd常駐したHermes Agent)      │
│                                              │
│   登録済みCronジョブ                           │
│   ├─ morning-news   毎朝7時   → Telegramへ     │
│   └─ (2つ目以降も追加できる)                   │
│                                              │
│   毎朝7時 → エージェント起動 → プロンプト実行   │
│           → 結果をTelegramへ送信               │
└──────────────────────────────────────────────┘
```

ポイントは、登録したあとは何もしなくていいこと。VPSが動いている限り、毎朝勝手に実行されて結果が届く。

## 事前準備

第6回までが完了していれば、追加で入れるものはない。Cronの登録と管理はVPS上の`hermes cron`コマンドで行うので、まずSSHでVPSにつなぐ。各回は別の日に作業することが多いので、毎回ここから接続し直す。

```bash
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps
systemctl --user status hermes-gateway
hermes cron status
```

以下を確認しておく。

- `hermes-gateway`が`active (running)`(第6回の常駐が効いている)
- `hermes cron status`が「Gateway is running — cron jobs will fire automatically」と出る(スケジューラが生きている)
- Telegramでbotに話しかけて返事が来る状態(ジョブの結果をTelegramに届けるため)
- ニュースやX検索を使うジョブを作るなら、第5回末尾でX Searchを有効化済み(Web検索の本格設定は第9回)

## スケジュール書式を選ぶ

Cronジョブの「いつ動かすか」は、4つの書式から選ぶ。

| 書式 | 例 | 意味 | 向いている用途 |
|---|---|---|---|
| cron式 | `0 7 * * *` | 毎日7時0分 | 毎朝・毎週など定期 |
| interval | `every 2h` | 2時間ごと | 定間隔の監視 |
| relative delay | `30m` | 今から30分後に1回 | テスト・1回限り |
| ISO timestamp | `2026-06-01T09:00:00+09:00` | 指定日時に1回 | 将来の1回だけ |

:::message alert
「毎朝7時」「来週の月曜」のような自然言語は**使えない**。必ず上の4書式のどれかで指定する。
:::

いちばん使うのはcron式だ。読み方はこう。

```text
┌───── 分 (0-59)
│ ┌─── 時 (0-23)
│ │ ┌─ 日 (1-31)
│ │ │ ┌─ 月 (1-12)
│ │ │ │ ┌─ 曜日 (0-6、0=日曜)
│ │ │ │ │
0 7 * * *      毎日7時0分
0 9 * * 1      毎週月曜9時0分
*/30 * * * *   30分ごと
0 0 1 * *      毎月1日0時0分
```

`*`は「毎回」の意味。`0 7 * * *`なら「日・月・曜日は問わず、毎日7時0分」になる。

## 最初のCronジョブを作る

例として「毎朝7時に、今日のニュースとX上のAI関連の話題を要約してTelegramに届ける」ジョブを作る。

### 1行のコマンドで登録する

VPSのターミナルで、次の形のコマンドを1行で打つ。スケジュールとプロンプトを引用符でくくり、名前と送り先をオプションで足す。

```bash
hermes cron add '0 7 * * *' '今日のニュースとX上のAI関連の話題を要約して。要約は3〜5項目、各2行以内で。出典URLを必ず付ける。' --name 'morning-news' --deliver telegram
```

部品の意味は次のとおり。

| 部品 | 意味 |
|---|---|
| `'0 7 * * *'` | スケジュール(必須・1番目)。毎日7時0分 |
| `'今日のニュース…'` | プロンプト(必須・2番目)。後述のself-contained形式で書く |
| `--name 'morning-news'` | 一覧で見分けるための名前(任意) |
| `--deliver telegram` | 結果の送り先。Telegramのbotへ届ける(後述) |

:::message
公式の最小サンプルは`--script`でスクリプトの出力をプロンプトに渡す形だが、本記事ではスクリプトを使わず、プロンプトだけのジョブから始める。
:::

実行すると`Created job: <job_id>`に続けて、名前・スケジュール・次回実行時刻が返る。この`job_id`(下の画面では`18dd6b7a1580`)が、以後の操作で対象を指すIDになる。

![ターミナルでhermes cron addを実行し、Created jobとjob_id・morning-news・スケジュール・次回実行時刻が表示された画面](/images/hermes-vps/hermes-vps-07-cron-add.png)

### 送り先(delivery target)を決める

`--deliver`で結果をどこへ送るかを指定する。指定できるのは`origin` / `local` / `telegram` / `discord` / `signal` / `platform:chat_id`。

| 値 | 送り先 | 向いている場面 |
|---|---|---|
| `origin` | ジョブを登録したチャット | Telegram等のチャットから登録したとき |
| `telegram` | Telegramへ送信 | 今回のようにSSHから登録したとき |
| `discord` / `signal` | 各プラットフォームへ送信 | 別経路で受け取りたいとき |
| `local` | ファイルに保存するだけ、通知なし | ログとして溜める |

注意したいのは`origin`だ。`origin`は「ジョブを登録したチャット」を指すので、チャットからではなくSSHのコマンドで登録する今回は、宛先になるチャットがない。だから`--deliver telegram`を使い、第4回でつないだTelegramのbotに直接届くようにする。実際、この指定で登録したジョブをテスト実行すると、そのままTelegramのDMに要約が届いた。

### すぐにテストする

明日の朝7時を待たなくても、今すぐ動作確認できる。まず`hermes cron list`で登録したジョブのIDを確認し、そのIDを指定して実行を促す。

```bash
hermes cron run 18dd6b7a1580
```

`run`は「次のスケジューラのtickで実行する」という予約で、画面には`It will run on the next scheduler tick`と出る。常駐しているゲートウェイが数分以内にそれを拾い、要約がTelegramに届く(手元では1〜2分で届いた)。出典URLが付いているか、3〜5項目で出ているかを確認する。

![ターミナルでhermes cron runを実行し、Triggered jobと「次のtickで実行する」旨が表示された画面](/images/hermes-vps/hermes-vps-07-cron-run.png)

![少し待つと、Telegramのbotにニュース要約が届いた画面。項目ごとに出典URLが付いている](/images/hermes-vps/hermes-vps-07-cron-result.png)

## ジョブを管理する

登録したジョブは、すべてVPS上の`hermes cron`コマンドで管理する。実行・停止・再開・削除のときは、`hermes cron list`で表示される**job_id**で対象を指定する(`--name`で付けた名前は一覧で見分けるためのラベルで、操作はIDで行う)。

| コマンド | 役割 |
|---|---|
| `hermes cron list` | 登録済みジョブの一覧(job_idと名前が出る) |
| `hermes cron status` | スケジューラが動いているかの確認 |
| `hermes cron run <job_id>` | 次のtickで実行(テスト用) |
| `hermes cron pause <job_id>` | 一時停止(削除はしない) |
| `hermes cron resume <job_id>` | 一時停止したジョブを再開 |
| `hermes cron edit <job_id>` | スケジュールやプロンプトを変更 |
| `hermes cron remove <job_id>` | 完全に削除 |

![ターミナルでhermes cron listを実行し、morning-newsが1件active状態でjob_id・スケジュール・配信先telegramまで表示された画面](/images/hermes-vps/hermes-vps-07-cron-list.png)

![hermes cron pauseでPaused、続けてhermes cron resumeでResumedとなり、次回実行時刻が戻った画面](/images/hermes-vps/hermes-vps-07-cron-pause-resume.png)

`pause`で止めたジョブは`resume`でそのまま再開でき、次回実行時刻も元に戻る。サブコマンドは`list` / `status` / `run` / `pause` / `resume` / `edit` / `remove`がそろっている。試しに一度止めて動かしておくと、運用中に慌てない。

## プロンプトは1通の依頼書として書く

Cronジョブはこれが一番のコツだ。Cronで実行されるとき、エージェントは**まっさらな会話**で動く。前日のやり取りも、いつもの口調も、過去の補正も、何ひとつ引き継がない。だからプロンプトの中で全部を言い切る必要がある。これをself-contained(自己完結)なプロンプトと呼ぶ。

### ダメな例

```text
いつものニュース要約をして。
```

エージェントは「いつもの」を知らない。何のニュースか、何項目か、出典は要るのか、すべて不明のまま動いてしまう。

### 良い例

```text
X上のAI関連投稿のうち、過去24時間で1000リポスト以上のものを5件選び、
各投稿を2行で要約。投稿者ハンドルと投稿URLを必ず付ける。
最後に「興味があれば返信してください、原文を引用して論点を整理します」と書く。
```

何を・いつのデータから・何件・どんなフォーマットで・出典の付け方・締めの一文まで、全部指定してある。これなら毎朝同じ品質で返ってくる。

### 変化があった時だけ知らせる([SILENT])

監視系のジョブで毎回通知が来ると、すぐ麻痺して読まなくなる。そこで`[SILENT]`を使う。プロンプトの中で「変化がなければ最終応答を`[SILENT]`だけにして」と指示すると、**エージェントの最終応答に`[SILENT]`が含まれた回は送信が止まる**(公式の説明:"When the agent's final response contains [SILENT], delivery is suppressed")。

```text
監視対象のページを開いて、前回との差分を確認して。
変化があれば、何がどう変わったかを3行で要約して報告。
変化がなければ、最終応答を [SILENT] の一語だけにすること。
```

価格監視・サイトの更新チェック・リポジトリのwatchなど、「変わった時だけ教えてほしい」用途で効く。

## 公式が示す5つの実用パターン

公式ガイドは、Cronの使いどころとして5つのパターンを挙げている。

| パターン | 用途 | スケジュール例 |
|---|---|---|
| 1. Website Monitoring | サイトの内容を取り、変化があったら通知 | `every 1h` + `[SILENT]` |
| 2. Weekly Reports | 複数ソース(web検索/GitHub等)を集約してレポート | `0 9 * * 1`(月曜9時) |
| 3. Repository Watcher | `gh`コマンドでGitHubのissue/PR/releaseを監視 | `every 4h` |
| 4. Data Collection Pipeline | 定期的にデータ収集・傾向分析・異常検出 | `0 */6 * * *`(6時間ごと) |
| 5. Multi-Skill Workflows | 複数のSkillを連結(論文検索→保存など) | `0 22 * * *`(毎晩22時) |

本記事の「毎朝のニュース要約」は、パターン2(Weekly Reports)を毎日に縮めた簡易版にあたる。パターン5のSkill連携は第8回で扱う。

## 2つ目のジョブを自分で足す

ジョブが1つだけだと「24時間動かす意味」を実感しにくい。2つ目を入れて、1日に2回エージェントが自分から喋り出す状態にしてみる。やり方は1つ目と同じで、スケジュールとプロンプトを変えるだけだ。

夕方17時に「明日の天気とゴミ出し予定」を送る例。ゴミ出しのルールは市区町村ごとに違うので、プロンプトの中で自分の市区町村名と収集曜日まで具体的に書く。エージェントは住んでいる場所を知らないので、ここもself-containedに書き切る必要がある。

```bash
hermes cron add '0 17 * * *' '明日の東京都世田谷区の天気(降水確率、最高・最低気温)を一行で。あわせて、世田谷区のゴミ収集ルール(燃えるゴミは月木、ペットボトルは水曜)に照らして、明日が何の収集日かを伝える。最後に「明日の予定の確認はいいですか?」と添える。' --name 'evening-tomorrow' --deliver telegram
```

例の「世田谷区」と収集曜日は、自分の市区町村と実際のルールに置き換える。

毎週金曜23時に「今週の振り返り」を促す例。

```bash
hermes cron add '0 23 * * 5' '今週の振り返りを促す質問を3つ送って。仕事・個人・学習の各カテゴリから1つずつ。「答えてくれたら、来週の優先順位の整理を手伝う」と添える。' --name 'friday-reflection' --deliver telegram
```

登録したら`hermes cron list`で2件並んでいることを確認し、`hermes cron run <job_id>`で動作を見ておく。1日に2回エージェントが自分から喋り出すようになる。

## まとめと第8回予告

第7回でやったこと。

- `hermes cron add`の1行コマンドで、毎朝7時のニュース要約ジョブを登録
- `--deliver telegram`で結果をTelegramのbotへ
- `hermes cron run`でテスト実行、`hermes cron list` / `pause` / `resume` / `edit` / `remove`で管理
- self-contained promptで、まっさらな会話でも同じ品質を出す
- `[SILENT]`で「変化があった時だけ」に絞る
- 2つ目のジョブを足して、1日2回エージェントが自分から動く状態に

これで、第6回で常駐させたHermesが「待つだけ」から「自分から動く」へ変わった。翌朝、SSHを開かずに枕元のスマホへ要約が届いていれば、24時間運用がちゃんと回っている証拠だ。

<!-- TBD:撮影後に有効化 → ![翌朝、ジョブが自動実行されTelegramに届いた画面(時刻表示が7時台)](/images/hermes-vps/hermes-vps-07-cron-morning.png) -->

第8回はHermes Agent Skillsで「自分用の手順を覚えさせる」回だ。毎回同じ長いプロンプトをコピペするのは面倒なので、よく使う手順をSkillにまとめてしまう。Skill化したものはCronからも呼べるので、第7回の長いプロンプトが短い呼び出しひとつで済むようになる。

## よくあるエラーと対処

| 症状 | 対処 |
|---|---|
| Telegramで`/cron`が「Unknown command」になる | cronはTelegramのスラッシュコマンドではなく、SSHで打つ`hermes cron`コマンド。Telegramは結果の配信先であって、登録・管理はVPSのターミナルから行う |
| Cronが指定時刻に動かない | 1) `systemctl --user is-active hermes-gateway`で常駐を確認、2) `hermes cron status`でスケジューラが動いているか、3) `hermes cron list`でジョブが`paused`になっていないか、4) cron式が5フィールドになっているか |
| 結果が届かない | (1) プロンプトに「変化がなければ`[SILENT]`」と書いていてエージェントが`[SILENT]`を返した、(2) `--deliver`の宛先が違う(SSHから登録したのに`origin`にしている)。`hermes cron edit`で直して再実行 |
| 「過去の話の続き」を求める返事が来る | self-contained promptになっていない。`hermes cron edit`でプロンプトを書き直す(依頼書として全部書き切る) |
| Telegramに二重で届く | 同じジョブが重複登録されている可能性。`hermes cron list`で確認し`hermes cron remove`で片方を削除 |
| 返事が長すぎてTelegramで切れる | プロンプトに「全体で2000字以内」「項目は最大5件」など上限を明記する |
| 検索を使うジョブが失敗する | 第5回でX Searchが有効か、Web検索を使うなら第9回の設定が済んでいるかを確認 |

## 公式ドキュメント引用元

| 項目 | 引用元 |
|---|---|
| Hermes Agent Cron全般 | [automate-with-cron](https://hermes-agent.nousresearch.com/docs/guides/automate-with-cron) |
| スケジュール書式(cron/interval/relative/ISO) | 同上「Hermes supports relative delays, intervals, standard cron expressions, ISO timestamps」 |
| 5つの実用パターン | 同上「Five Real-World Patterns」 |
| self-contained promptの必須性 | 同上「Prompts must be completely self-contained」 |
| delivery target(origin/local/telegram等) | 同上「Delivery Targets」 |
| `[SILENT]`による送信抑制 | 同上「When the agent's final response contains [SILENT], delivery is suppressed」 |
