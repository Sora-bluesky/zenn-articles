---
title: "【第9回】Hermes Agentに毎朝のタスクを自動実行させる"
emoji: "🤖"
type: "tech"
topics: ["ai", "hermes", "cron", "自動化", "vps"]
published: true
---

## 目次

- [この回の到達点](#この回の到達点)
- [Cronとは何か](#cronとは何か)
- [第9回終了時点の構成図](#第9回終了時点の構成図)
- [事前準備](#事前準備)
- [スケジュール書式の基本](#スケジュール書式の基本)
- [Dashboardから最初のCronジョブを作る](#dashboardから最初のcronジョブを作る)
- [あとから手を入れる──編集モーダル](#あとから手を入れる──編集モーダル)
- [プロンプトは1通の依頼書として書く](#プロンプトは1通の依頼書として書く)
- [公式が示す5つの実用パターン](#公式が示す5つの実用パターン)
- [2つ目以降のジョブの例](#2つ目以降のジョブの例)
- [補足ターミナルから直接登録する](#補足ターミナルから直接登録する)
- [まとめと第10回予告](#まとめと第10回予告)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [操作早見表](#操作早見表)
- [引用元と参考](#引用元と参考)

第6回でsystemd常駐が完成し、第7回でHermes Desktop、第8回でWeb Dashboardの管制室が揃った。ここまでで、エージェントはVPSの上で24時間動き、ブラウザとデスクトップアプリの両方から触れる状態になっている。ただ、まだ「こちらから話しかけたら返事をする」受け身のままだ。

第9回はここに「自分から動く」を足す。Hermes AgentのCron機能を使って、たとえば毎朝7時に今日のニュースとX上の話題を要約してTelegramへ届ける、といった定型仕事を任せる。設定はすべて第8回で慣れたDashboardの中で完結する。新規モーダルが「毎日」「毎週」のような選択肢を用意してくれているので、まずcron式を手で書く必要はない(編集モーダルで後から細かく直したいときだけ、cron式の読み方が活きる)。

シリーズの全体像はこちら。

:::details シリーズのもくじ(タップで開く)

**第I部 体を作る**
- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy) Hermes AgentをVPSにデプロイする方法
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale) Hermes Agentの接続を安全にする方法
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password) Hermes Agentの認証情報を安全に管理する方法
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install) Hermes AgentをDockerで隔離して動かす方法
- [第5回](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord) Hermes AgentにGrokとDiscordを連携させる
- [第6回](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd) Hermes Agentをsystemdで常時起動させる方法

**第II部 顔と操作席**
- [第7回](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop) Hermes Agentをデスクトップアプリで操作する方法
- [第8回](https://zenn.dev/sora_biz/articles/hermes-vps-08-dashboard) Hermes AgentをWeb Dashboardで管理する方法

**第III部 生活リズム**
- **第9回**(本記事) Hermes Agentに毎朝のタスクを自動実行させる
- [第10回](https://zenn.dev/sora_biz/articles/hermes-vps-10-skills) Hermes Agentが使うほど賢くなるSkillsの登録方法
- [第11回](https://zenn.dev/sora_biz/articles/hermes-vps-11-web-search) Hermes Agentに最新情報を自動取得させる方法

**第IV部 記憶を分けて育てる**
- [第12回](https://zenn.dev/sora_biz/articles/hermes-vps-12-memory) Hermes AgentにMemoryで好みと前提を記憶させる
- [第13回](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) Hermes AgentとObsidianを連携して知識を共有する方法
- [第14回](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) Hermes Agentに過去の会話を自動で復元させる
- [第15回](https://zenn.dev/sora_biz/articles/hermes-vps-15-import-ai-sessions) Hermes AgentにClaude CodeやCodexの作業履歴を取り込む方法

全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

手を動かすのは、第8回でブックマークしたDashboardのURLを開いて、「CRON」ペインの「作成」ボタンから新規ジョブを1つ登録するだけ。SSHでターミナルを開く必要はない。

## この回の到達点

第8回完了時と第9回完了後の差分を表にする。

| 項目 | 第8回完了時 | 第9回完了後 |
|---|---|---|
| 常駐 | systemd経由のgateway+dashboardで24時間動く | 変わらず |
| 管制室 | DashboardでサイドバーやCRONペインを把握済み | CRONペインに自分のジョブが並ぶ |
| エージェントの仕事 | Telegram/Discord/Dashboardから話しかけたら返事する(受け身) | **決まった時刻に自分から仕事を始める**(能動) |
| 定型作業 | 毎回自分で「ニュース要約して」と打つ必要 | 毎朝7時に勝手にTelegramへ届く |
| ジョブ管理 | 該当機能なし | DashboardのCRONペインで一覧・編集・停止・再開・削除 |

一言でまとめると「Hermesに、毎日の決まった用事を仕込んで、寝ている間に片付けてもらう」回だ。

## Cronとは何か

HermesのCronは、Linuxに昔からある`crontab`とは別物だ。役割が違う。

- systemd(第6回):サービスを生かし続ける係。プロセスが止まっても起こし直す
- Hermes Cron(第9回):決まった時刻にエージェントを起こして、プロンプトを与え、結果を指定のチャットへ送る係

つまりsystemdが「人を雇い続ける」なら、Cronは「その人に毎朝の業務を割り当てる」イメージだ。

この回で出てくる言葉を先に押さえておく。

| 用語 | 意味 | たとえ |
|---|---|---|
| Cron(クーロン) | 「決まったタイミングで自動的に何かを実行する仕組み」の通称 | 目覚まし時計の設定一覧 |
| cron式 | `分 時 日 月 曜日`の5フィールドで時刻を表す書式。`0 9 * * *`=毎日9時0分 | 「毎週月曜の9時」を表す業界共通フォーマット |
| 配信先 | ジョブの結果をどこへ届けるかの指定。ローカル/Telegram/Discord/Slack/Emailの5択 | 宅配便を自宅に届けるかオフィスに届けるかの選択 |
| self-contained prompt | 過去の会話を覚えていない前提で、全部書き切った依頼文 | 初対面の人に頼むつもりで全部説明する依頼書 |
| 今すぐ実行 | ジョブ行の稲妻アイコン。次のtickで実行する=実機では2〜3分後にTelegramへ届く | 目覚ましの「テストならす」ボタン |
| `[SILENT]` | エージェントの最終応答にこの語が入っていると、その回の送信が止まる | 「変化があった時だけ知らせて」設定 |

## 第9回終了時点の構成図

Cronジョブは、第6回で常駐させたHermes Agentの中に登録される。VPSのファイルを手で編集するわけではなく、第8回のDashboardの「作成」モーダルで登録する。結果の配信先としてTelegram等を指定する。

![VPSのhermes-gateway.serviceとhermes-dashboard.serviceが常駐し、Dashboardの「作成」モーダルで登録したCronジョブmorning-newsが毎朝7時にエージェントを起動してプロンプトを実行しTelegramへ送信する構成図](/images/hermes-vps/hermes-vps-09-cron-architecture-diagram.png)

ポイントは、登録したあとは何もしなくていいこと。VPSが動いている限り、毎朝勝手に実行されて結果が届く。

## 事前準備

第8回までが完了していれば、追加で入れるものはない。Dashboardは第7回でsystemd常駐させてあるので、ブラウザでURLを開くだけだ。

```text
http://<tailscale-ip>:9119   # 第7-8回で設定したdashboardのURL
                             # ID/passwordはbasic認証(第7回)
```

開いたら、サイドバー下部の「ゲートウェイ状態:実行中」と、Telegram botに話しかけて返事が来る状態(第4回完了)を確認しておく。

## スケジュール書式の基本

Cronジョブの「いつ動かすか」は、公式ガイドが示す4書式から表現できる。

| 書式 | 例 | 意味 | 向いている用途 |
|---|---|---|---|
| cron式 | `0 7 * * *` | 毎日7時0分 | 毎朝・毎週など定期 |
| interval | `every 2h` | 2時間ごと | 定間隔の監視 |
| relative delay | `30m` | 今から30分後に1回 | テスト・1回限り |
| ISO timestamp | `2026-06-01T09:00:00+09:00` | 指定日時に1回 | 将来の1回だけ |

:::message alert
「毎朝7時」「来週の月曜」のような自然言語は使えない。必ず上の4書式のどれかに落とす。
:::

読み方が活きるのは、後ほど見る編集モーダル(EDIT JOB)でスケジュールを直接書き換えるときだ。新規モーダルでは「毎日」「毎週」のような選択肢から選ぶだけで済むので、ここはまず1枚で全体像を押さえておく。

![cron式の読み方──5つのフィールド「分 時 日 月 曜日」と、よく使うcron式の例(毎日7時/毎週月曜9時/30分ごと/毎月1日0時)と、曜日の値(0:日〜6:土)を1枚にまとめた図](/images/hermes-vps/hermes-vps-09-cron-schedule-syntax.png)

`*`は「すべて」の意味。`0 7 * * *`なら「日・月・曜日は問わず、毎日7時0分」になる。次の章で見るように、Dashboardの新規モーダルではこの式を手で書く必要はない。cron式は「内部での表現」として裏で生成される。

## Dashboardから最初のCronジョブを作る

例として「毎朝7時に、今日のニュースとX上の話題を要約してTelegramに届ける」ジョブを作る。

### CRONペインを開いて「作成」を押す

左サイドバーから「CRON」を選ぶ。ペインの見出しは「Cron」、その下に「スケジュール済みジョブ (N)」と現在の登録数が出る。右上のクリーム色のボタンが「作成」だ。

![CRONペインを開いた状態。スケジュール済みジョブが並び、右上の「作成」ボタンが赤枠と矢印で強調されている画面](/images/hermes-vps/hermes-vps-09-cron-pane-before-add.png)

「作成」を押すと、ブラウザ内に新しいジョブを作るモーダルが開く。

### モーダルの各欄を埋める

モーダルのタイトルは「新しい CRON ジョブ」。欄は上から順に並ぶ。

![新しい CRON ジョブモーダルの空欄状態。上からPROFILE(default)/名前(任意)/プロンプト/スケジュール(繰り返し間隔)/実行間隔30+単位分/送信形式 every 30m/配信先(ローカル)/作成ボタンが並ぶ画面](/images/hermes-vps/hermes-vps-09-cron-new-job-modal-empty.png)

| 欄 | 入れる値 |
|---|---|
| PROFILE | `default`のまま |
| 名前 (任意) | `morning-news` |
| プロンプト | 次の節のself-containedプロンプト全文 |
| スケジュール | 「毎日」を選択(下の解説を参照) |
| 時刻(「毎日」モード時) | `07:00` |
| 配信先 | `Telegram`(第8回でTelegramを有効化しているとドロップダウンに出る) |

スケジュール欄は初期表示で「繰り返し間隔」モードになっているが、ドロップダウンを開くと**6つのモード**が並ぶ。

![スケジュールのドロップダウンを開いた状態。繰り返し間隔/毎日/毎週/毎月/1回のみ/カスタム(cron式)の6モードが並ぶ画面](/images/hermes-vps/hermes-vps-09-cron-schedule-modes.png)

「毎日」を選ぶと「時刻」欄が現れ、時計アイコンつきの入力欄に`07:00`と入れる。配信先で「Telegram」を選んでおく。

ここまで埋めると、モーダル下部の小さな緑文字に「送信形式: `0 7 * * *`」というプレビューが出る。これが、選んだモードと値から自動生成されるcron式だ。読者は覚えなくていい。

![新しい CRON ジョブモーダルの入力完了状態。名前 morning-news、プロンプトはself-containedの長文、スケジュールはCRON式 0 7 * * * 相当、配信先はTelegramが選ばれている画面](/images/hermes-vps/hermes-vps-09-cron-new-job-modal-filled.png)

### プロンプト例(self-contained)

モーダルの「プロンプト」欄に入れる文。詳しい作法は[プロンプトは1通の依頼書として書く](#プロンプトは1通の依頼書として書く)の章で扱う。本記事はWeb検索だけで完結する素朴な例にしている。X検索を組み込んだ版は第11回で扱う。

```text
今日のニュースと、X上のAI関連の話題を要約して。

要約は3〜5項目、各2行以内で。出典URLを必ず付ける。
最新性が優先。24時間以内の情報のみ。
最後に「気になるトピックがあれば、深掘りしてください」と書く。
```

### 「作成」を押して一覧に追加

モーダル右下の「作成」ボタンを押すと、モーダルが閉じてCRONペインの一覧に`morning-news`が増える。

![作成直後のCRONペイン。一覧に新しい morning-news が追加され、scheduledバッジ・スケジュール「毎日 07:00」・配信先 telegram バッジ・右端のアクションアイコン4個が見える。赤枠で新規行が強調されている画面](/images/hermes-vps/hermes-vps-09-cron-pane-after-add.png)

各行の構成はこうなっている。

- 上段:名前(`morning-news`)とバッジ3つ(`scheduled` / `default` / `telegram`)
- 中段:プロンプトの要約
- 下段:スケジュールの日本語表示「毎日 07:00」と「前回 …」「次回 …」のタイムスタンプ
- 右端:アクションアイコン4個(左から ⏸一時停止 / ⚡今すぐ実行 / ✏編集 / 🗑削除)

### 稲妻アイコンで即時テストする

明日の朝7時を待たなくても、すぐに動作確認できる。`morning-news`の行の右端、アクションアイコンの2番目にある**稲妻**(⚡)が「今すぐ実行」だ。

![morning-news行の右端のアクションアイコン4個が赤枠で強調されている画面。一時停止・稲妻(今すぐ実行)・編集・削除の順に並ぶ](/images/hermes-vps/hermes-vps-09-cron-job-row-actions.png)

「今すぐ実行」と書いてあるが、押した瞬間に走るわけではない。内部では「次のscheduler tickで実行する」予約になり、エージェントがWeb検索や記事本文の取得に時間を使うため、**Telegramに届くのは2〜3分後**だ。じっと待つ。

しばらくすると、第4回でつないだTelegramのbotに、要約が届く。

![Telegram上のHermes VPS botにCronjob Response: morning-newsという見出しでニュース要約が届いた画面。5項目それぞれに2行の要約と出典URL、末尾に取得状況の併記](/images/hermes-vps/hermes-vps-09-cron-result.png)

確認したいのは、

- 項目が3〜5件で出ているか
- 各項目に出典URLが付いているか
- 末尾に「気になるトピックがあれば、深掘りしてください」が入っているか

これで、第6回で常駐させたHermesに、毎朝7時の仕事をひとつ覚えさせたことになる。

## あとから手を入れる──編集モーダル

self-containedプロンプトで運用していくと、スケジュールを変えたくなったり、プロンプトに注意点を足したくなったりする場面が必ず出る。そのときの直し方を先に見ておく。Dashboardの**編集モーダル**(EDIT JOB)が、これを安全に直す場所だ。

新規作成モーダルとは別UIで、欄が4つに絞られている。スケジュールはCRON式の自由入力に切り替わり、`30 6 * * *`のように直接書ける。

:::message
v0.17.0以降のDashboardでは、基本4欄の下に「Advanced fields」という応用設定の欄が初期から開いた状態で表示される。本記事の手順では触らなくてよい。詳しくは末尾の補足「Dashboardのcronモーダルに『Advanced fields』が追加された」を参照。
:::

### スケジュールを書き換える

例として、ジョブの時刻を朝7時から朝6時30分に変えてみる。`morning-news`の行の鉛筆(✏)を押すと、EDIT JOBモーダルが開く。

![EDIT JOBモーダル。名前 morning-news、プロンプトはself-containedの長文、スケジュール (CRON 式)に 30 6 * * * が入っている(赤枠強調)、配信先は Telegram、右下に SAVE CHANGES ボタンが並ぶ画面](/images/hermes-vps/hermes-vps-09-cron-edit-modal-schedule.png)

スケジュール欄を`0 7 * * *`から`30 6 * * *`に書き換えて、「SAVE CHANGES」を押す。CRONペインの一覧に戻ると、`morning-news`のスケジュール表示が「毎日 07:00」から「毎日 06:30」に変わっている。

![CRONペインの一覧で、morning-news のスケジュール表示が「毎日 06:30」に変わっている画面。該当行が赤枠と矢印で強調されている](/images/hermes-vps/hermes-vps-09-cron-pane-after-edit-schedule.png)

ここで、[スケジュール書式の基本](#スケジュール書式の基本)で見た図がそのまま役に立つ。新規作成モーダルでは「毎日」「時刻ピッカー」で済んでいたが、編集モーダルでは`30 6 * * *`を読み書きできる必要がある。Dashboardは「最初は易しく、後から細かく」の二段構えになっている。

### プロンプトに気付いた注意点を足す

数回受け取って気付いた注意点を、プロンプトの末尾に追記する。たとえば、

- いいね/RT等の数値を書かないでほしい(実は取得していないため捏造になる)
- 出典URLが付かない項目がたまにある→「必ず付ける」と明示する

同じEDIT JOBモーダルを開いて、プロンプト欄の末尾に1行ずつ追記して「SAVE CHANGES」を押す。

![EDIT JOBモーダル。プロンプト本文の末尾に「プロンプトに足す例(self-containedの末尾)」として2行の注意点が赤枠で追記された画面。「いいね/RT等の数値は書かない」「各項目に出典URLを必ず付ける」](/images/hermes-vps/hermes-vps-09-cron-edit-modal-prompt.png)

この「気付いたら1行ずつ足していく」運用は、第10回で扱うSkillsの設計に直結する話だ。プロンプトの中で全部書き切る今のやり方は、ジョブが増えるほど維持が大変になる。第10回ではこの手順そのものを「Skill」として独立させて、新しいCronのプロンプト欄を短い呼び出しに置き換える。

### 一時停止と再開・削除

EDIT JOBの隣には、もう3つのアイコンがある。

- ⏸ 一時停止:scheduled状態のジョブを止める。停止中はこのアイコンが再開アイコンに変わる
- ⚡ 今すぐ実行:[稲妻アイコンで即時テストする](#稲妻アイコンで即時テストする)で使った即時実行
- 🗑 削除:ジョブを削除

`morning-news`の一時停止アイコン(⏸)を押すと、行のバッジが`scheduled`から`paused`に変わり、右上に「一時停止: "MORNING-NEWS"」というトーストが出る。

![CRONペインで morning-news が paused 状態になり、バッジとアクションアイコンが赤枠で強調され、右上に「一時停止: "MORNING-NEWS"」のトースト通知が表示されている画面](/images/hermes-vps/hermes-vps-09-cron-paused.png)

停止中の行の再開アイコンを押すと、バッジが`scheduled`に戻り、右上に「再開: "MORNING-NEWS"」のトーストが出る。次回実行時刻も復帰する。

![CRONペインで morning-news が scheduled に復帰し、バッジとアイコンが赤枠で強調され、右上に「再開: "MORNING-NEWS"」のトースト通知が表示されている画面](/images/hermes-vps/hermes-vps-09-cron-resumed.png)

削除アイコン(🗑)も同じ場所にある。誤って消すとジョブそのものが消えるので、後で復元できる「一時停止」と使い分ける。

## プロンプトは1通の依頼書として書く

Cronジョブはここが一番のコツだ。Cronで実行されるとき、エージェントは**まっさらな会話**で動く。前日のやり取りも、いつもの口調も、過去の補正も、何ひとつ引き継がない。だからプロンプトの中で全部を言い切る必要がある。これをself-contained(自己完結)なプロンプトと呼ぶ。

### ダメな例

```text
いつものニュース要約をして。
```

エージェントは「いつもの」を知らない。何のニュースか、何項目か、出典は要るのか、すべて不明のまま動いてしまう。

### 良い例

```text
X上で最近議論になっているAI関連の話題を5件選び、
各投稿を2行で要約。投稿者ハンドルと投稿URLを必ず付ける。
最後に「興味があれば返信してください、原文を引用して論点を整理します」と書く。
```

何を・いつのデータから・何件・どんなフォーマットで・出典の付け方・締めの一文まで、全部指定してある。これなら毎朝同じ品質で返ってくる。

### 変化があった時だけ知らせる(`[SILENT]`)

監視系のジョブで毎回通知が来ると、すぐ麻痺して読まなくなる。そこで`[SILENT]`を使う。プロンプトの中で「変化がなければ最終応答を`[SILENT]`だけにして」と指示すると、**エージェントの最終応答に`[SILENT]`が含まれた回は送信が止まる**(公式の説明:"When the agent's final response contains [SILENT], delivery is suppressed")。

```text
監視対象のページを開いて、前回との差分を確認して。
変化があれば、何がどう変わったかを3行で要約して報告。
変化がなければ、最終応答を [SILENT] の一語だけにすること。
```

価格監視・サイトの更新チェック・リポジトリのwatchなど、「変わった時だけ教えてほしい」用途で効く。

## 公式が示す5つの実用パターン

公式ガイドは、Cronの使いどころとして5つのパターンを挙げている。

| パターン | 用途 | スケジュール例 | 補足 |
|---|---|---|---|
| 1. Website Monitoring | サイトの内容を取り、変化があったら通知 | `every 1h` | プロンプト末尾で`[SILENT]`を併用 |
| 2. Weekly Reports | 複数ソース(web検索/GitHub等)を集約してレポート | `0 9 * * 1`(月曜9時) | — |
| 3. Repository Watcher | `gh`コマンドでGitHubのissue/PR/releaseを監視 | `every 4h` | — |
| 4. Data Collection Pipeline | 定期的にデータ収集・傾向分析・異常検出 | `0 */6 * * *`(6時間ごと) | — |
| 5. Multi-Skill Workflows | 複数のSkillを連結(論文検索→保存など) | `0 22 * * *`(毎晩22時) | 第10回で扱う |

本記事の「毎朝のニュース要約」は、パターン2(Weekly Reports)を毎日に縮めた簡易版にあたる。パターン5のSkill連携は第10回で扱う。

## 2つ目以降のジョブの例

ジョブが1つだけだと「24時間動かす意味」を実感しにくい。2つ目を入れて、1日に2回エージェントが自分から喋り出す状態にしてみる。やり方は3章と同じで、CRONペインの「作成」を押してモーダルを埋めるだけだ。

### 例:夕方17時の「明日の天気とゴミ出し予定」

ゴミ出しのルールは市区町村ごとに違うので、プロンプトの中で自分の市区町村名と収集曜日まで具体的に書く。エージェントは住んでいる場所を知らないので、ここもself-containedに書き切る。

| モーダル欄 | 入れる値 |
|---|---|
| 名前 (任意) | `evening-tomorrow` |
| スケジュール | 「毎日」+時刻`17:00` |
| 配信先 | Telegram |
| プロンプト | 「明日の東京都世田谷区の天気(降水確率、最高・最低気温)を一行で。あわせて、世田谷区のゴミ収集ルール(燃えるゴミは月木、ペットボトルは水曜)に照らして、明日が何の収集日かを伝える。最後に『明日の予定の確認はいいですか?』と添える。」 |

例の「世田谷区」と収集曜日は、自分の市区町村と実際のルールに置き換える。実際に登録して動かすと、Telegramにこんな配信が届く。

![evening-tomorrowジョブの配信例。明日の天気予報と、その日に応じたごみ収集日がTelegramに届いた画面](/images/hermes-vps/hermes-vps-09-cron-evening-result.png)

### 例:毎週金曜23時の「今週の振り返りプロンプト」

| モーダル欄 | 入れる値 |
|---|---|
| 名前 (任意) | `friday-reflection` |
| スケジュール | 「カスタム(cron式)」+`0 23 * * 5` |
| 配信先 | Telegram |
| プロンプト | 「今週の振り返りを促す質問を3つ送ってほしい。仕事・個人・学習の各カテゴリから1つずつ。『答えてくれたら、来週の優先順位の整理を手伝う』と添える。」 |

「毎週金曜」は「毎週」モードでも作れるが、cron式に慣れているなら「カスタム(cron式)」モードで`0 23 * * 5`と直接書いてもいい。Dashboardは両方の入り口を用意している。

登録したら、CRONペインで2件並んでいることを確認して、稲妻アイコンで動作を見ておく。1日に2回、エージェントが自分から喋り出すようになる。

## 補足ターミナルから直接登録する

SSHのターミナルから直接登録したい人向けの代替手順。Dashboardの「作成」モーダルで埋めた内容と、結果は同じ`~/.hermes/config.yaml`に書き込まれる。両方使ってもいい(同じファイルを共有しているので競合しない)。

```bash
# VPSにSSH接続(第1〜2回で設定したTailscale経由)
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps

# 1行コマンドで登録(スケジュール・プロンプト・名前・配信先)
hermes cron add '0 7 * * *' '今日のニュースとX上のAI関連の話題を要約して(本文はプロンプト章を参照)' --name 'morning-news' --deliver telegram

# 管理
hermes cron list                  # 一覧
hermes cron run <job_id>          # 「今すぐ実行」(稲妻)相当
hermes cron pause <job_id>        # 一時停止
hermes cron resume <job_id>       # 再開
hermes cron edit <job_id>         # 編集
hermes cron remove <job_id>       # 削除
```

登録時に返る`job_id`(例 `8f74025f300e`)が以後の操作で対象を指すIDになる。Dashboardで作ったジョブもCLIの`hermes cron list`に同じく並ぶので、好きな方から触ればいい。

## まとめと第10回予告

第9回でやったこと。

- CRONペインの「作成」モーダルで、毎朝7時のニュース要約ジョブを登録
- 配信先=Telegramで、第4回でつないだbotへ要約を届ける
- ⚡今すぐ実行(稲妻)でテスト、2〜3分待つとTelegramに着信
- EDIT JOBモーダルで、スケジュールを`0 7 * * *`から`30 6 * * *`に書き換え
- プロンプトに気付いた注意点(数値を書かない/出典URL必須)を末尾に追記
- ⏸一時停止/再開で運用中のジョブを安全に止めて戻す
- self-contained promptで、まっさらな会話でも同じ品質を出す
- `[SILENT]`で「変化があった時だけ」に絞る
- 2つ目のジョブを足して、1日2回エージェントが自分から動く状態に

これで、第8回までの「待つだけ」の管制室から、「自分から動く」エージェントへ一歩進んだ。翌朝、SSHを開かずに枕元のスマホへ要約が届いていれば、24時間運用がちゃんと回っている証拠だ。

![翌朝7時台、morning-newsジョブが自動で実行され、ニュース要約がTelegramに届いた画面。左上の時刻が朝7時を指しているのがスケジュール実行の証拠](/images/hermes-vps/hermes-vps-09-cron-morning.png)

第10回は、第9回でプロンプトに足した「注意点」が、もうひと工夫で**手順そのもの**に変わる回だ。self-containedプロンプトを使い続けると、毎回同じ品質で動かすために手順とverificationを書き切る必要があり、プロンプト欄が手順書のように膨らんでいく。複数のジョブで似た手順を使い回したくなる場面も増える。

そこで登場するのが**Hermes Agent Skills**だ。手順そのものをSkillとして覚えさせると、Cronのプロンプト欄を「`summarize-to-japanese`スキルで要約して」のような短い呼び出しに置き換えられる。第10回では、記事や動画を日本語で要約するSkillを自分で作り、それを新しいCronに添付して『毎朝、Hermes自身の最新情報を要約して届ける』ところまでやる。品質はぶれず、保守も一気に楽になる。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第8回 Hermes AgentをWeb Dashboardで管理する方法](https://zenn.dev/sora_biz/articles/hermes-vps-08-dashboard) | [第10回 Hermes Agentが使うほど賢くなるSkillsの登録方法](https://zenn.dev/sora_biz/articles/hermes-vps-10-skills) |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## よくあるエラーと対処

| 症状 | 対処 |
|---|---|
| ブラウザで`ERR_CONNECTION_RESET`(接続がリセットされました) | アドレスバーが`https://`になっている可能性。dashboardは`http://`(sなし)で動いている(通信はTailscaleが暗号化)。`http://<tailscale-ip>:9119`で開き直す |
| Telegramで`/cron`が「Unknown command」 | cronはTelegramのスラッシュコマンドではなく、DashboardのCRONペインまたはSSHの`hermes cron`コマンド。Telegramは結果の配信先であって、登録・管理はDashboardかVPSのターミナルから行う |
| Cronが指定時刻に動かない | (1)サイドバー下部「ゲートウェイ状態:実行中」を確認、(2)CRONペインで該当ジョブが`paused`になっていないか、(3)スケジュール欄のcron式が5フィールドになっているか、(4)ブラウザがcacheで古い表示の場合はリロード |
| 結果が届かない | (1)プロンプトに「変化がなければ`[SILENT]`」と書いていてエージェントが`[SILENT]`を返した、(2)配信先のドロップダウンがローカルのままになっている。EDIT JOBモーダルで配信先をTelegramに直して再実行 |
| 「過去の話の続き」を求める返事が来る | self-contained promptになっていない。EDIT JOBモーダルでプロンプトを書き直す(依頼書として全部書き切る) |
| Telegramに二重で届く | 同じジョブが重複登録されている可能性。CRONペインで確認し🗑削除アイコンで片方を削除 |
| 返事が長すぎてTelegramで切れる | プロンプトに「全体で2000字以内」「項目は最大5件」など上限を明記する |
| 「作成」(または「SAVE CHANGES」)ボタンが押せない | 必須欄(プロンプト・スケジュール)に空欄が残っている可能性(名前は任意)。モーダル上部の警告メッセージを確認 |

## 操作早見表

### Dashboard(本筋)

| やりたいこと | 場所 | 操作 |
|---|---|---|
| 新規ジョブ追加 | CRONペイン | 右上「作成」→モーダルで名前/プロンプト/スケジュール/配信先を埋めて「作成」 |
| 一覧確認 | CRONペイン | サイドバー「CRON」を選ぶだけ |
| 即時テスト実行 | 各行右端 | ⚡今すぐ実行(稲妻)アイコン |
| 一時停止 | 各行右端 | ⏸一時停止アイコン |
| 再開 | 各行右端(停止中) | 再開アイコン(一時停止位置が切り替わる) |
| 編集 | 各行右端 | ✏鉛筆アイコン→EDIT JOBモーダル |
| 削除 | 各行右端 | 🗑ゴミ箱アイコン |

### ターミナルから直接登録する(CLI)

```bash
hermes cron add 'sched' 'prompt' --name 'ラベル' --deliver telegram   # 新規追加(1行)
hermes cron list                         # 一覧
hermes cron status                       # スケジューラが動いているか
hermes cron run <job_id>                 # 即時実行(稲妻)相当
hermes cron pause <job_id>               # 一時停止
hermes cron resume <job_id>              # 再開
hermes cron edit <job_id>                # 編集
hermes cron remove <job_id>              # 削除

# よく使うcron式
0 7 * * *          毎日7時
0 9 * * 1          毎週月曜9時
0 22 * * *         毎晩22時
*/30 * * * *       30分ごと
0 */4 * * *        4時間ごと
0 0 1 * *          毎月1日0時

# 配信先(モーダルの「配信先」欄と対応)
ローカル / Telegram / Discord / Slack / Email
```

## 補足:CronはHermes自身が時計を見ている

HuggingFace公式が[Hermes Agentのアーキテクチャを解説した動画](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=2077s)の最後の章(34:37〜)でCronを扱っている。動画によれば、Hermesのcronはサーバー側のsystem cronとは別系統で、Hermes本体が**毎分tickする独自の関数**でジョブを巡回するという。確かに本回のCRONペインで「今すぐ実行」を押した直後・cron式に従って次の発火を待つ動きは「Hermesが自分で時計を見て話しかけてくる」体感に近い。こちらが話しかける前に届く、という設計だ。

動画ではさらに2点踏み込んでいる。(a)ジョブの実体は`~/.hermes/cron/jobs.json`に保存されている(公式docはSQLite保存と書いている箇所があるが、実機v0.16.0で確認すると確かに`jobs.json`に書かれている)。(b)発火時の配信は`send_message`ツールを呼ぶのではなく、**最初に設定した「home gateway」に自動で届く**設計になっている。本回の手順で「配信先=Telegram」を選んでいれば、Hermesが裏でTelegram bot APIを直接叩いて届けてくれる。読者は意識せずTelegramに届く理由がここにある。

動画は英語で約40分・YouTube設定で日本語自動翻訳字幕も出せる。本回の手順だけで運用は完結するので無理に見る必要はないが、「裏で何が起きているか」をもう一段知りたい人向けの良質な補助線として置いておく。

## 補足:v0.17.0でAutomation Blueprintsが追加された

2026-06-19公開のv0.17.0「The Reach Release」で、Cron構文を一切覚えずに同等の自動化を組める**Automation Blueprints**が追加された。「毎朝8時に最新ニュースを要約」のような依頼を、blueprint定義1つでDashboard form/CLI-TUI-messengerのslash command/agent会話/docs catalogエントリの4経路から横断して呼べる。

本記事のCron CLI(`hermes cron`)とDashboardのCRONペインは引き続き使える(後方互換)。Blueprintsは追加の選択肢だ。「`0 7 * * *`を覚えるのが面倒」「自然言語で組みたい」読者向けに、第IX部Voice周辺で別途扱う予定。`hermes update`で最新に保てば自動で使えるようになる。

## 補足:Telegram Bot APIのRich Messages(v0.17.0で対応・日本語通知は従来表示)

2026年6月13日、Telegram創業者の[Pavel Durovが正式に告知](https://x.com/durov/status/2065896953519484976)したとおり、Telegram Bot APIに**Rich Messages**が入った。表(tables)・入れ子の箇条書き(nested lists)・本文中に埋め込む画像や動画(inline media)・数式(formulas)・見出し(headers)などを、Telegramのチャット欄に直接表示できる新APIだ。仕様は[公式doc](https://core.telegram.org/bots/api#rich-message-formatting-options)にまとまっている。

同日、Hermesの[Tekniumも追従を予告](https://x.com/Teknium/status/2065777563356774688)し、画像で「DEFAULT ON / No toggle / sendRichMessage API採用 / Agent system prompt hintに tables・task lists・math を追加」の方針を示している。

**2026-06-19公開のHermes v0.17.0「The Reach Release」で追従**された。ただし予告と違い、出荷時の挙動は**default OFF**(opt-in)だ。リッチ表示を使うには`config.yaml`で`telegram.extra.rich_messages: true`を明示的に設定する必要がある。さらに日本語を含むテキストは、表示崩れを避けるため従来表示(MarkdownV2)のまま送られる仕様になっている。

つまり本連載のように日本語でcron通知を受け取る運用では、opt-inしてもしなくても通知は従来表示のままになる。リッチ表示が効くのは英語中心の運用で`rich_messages: true`を設定したときだと理解しておけばよい。

## 補足:Dashboardのcronモーダルに「Advanced fields」が追加された(2026-06-27)

2026-06-27にDashboardのcron機能が拡張され([PR#53551](https://github.com/NousResearch/hermes-agent/pull/53551))、ジョブの作成/編集モーダル両方に「Advanced fields」というセクションが追加された。モーダルを開いた時点で初期から展開された状態で表示されるため、本記事の手順で開いた読者にも目に入る。

出る欄は8つ。

| 欄 | 用途 |
|---|---|
| `provider` / `model` / `base_url` | このジョブだけ別のproviderやmodelを使う(v0.18.0以降、`base_url`のoverrideはcustom/BYOK用途に限定される制約あり。詳細は下記追記参照) |
| `script` | 起動前に走らせるscript。出力をプロンプトの先頭にcontextとして渡せる |
| `no_agent` | LLMを呼ばずscriptの結果だけを配信先に届ける(LLMコスト$0) |
| `context_from` | 別ジョブの最終出力を自動でプロンプト先頭に付ける(複数ジョブのpipeline化) |
| `toolsets` | このジョブで使えるtoolを限定(`web,file`等で軽量化) |
| `workdir` | 実行ディレクトリを指定 |

本記事の手順では基本4欄(名前/プロンプト/スケジュール/配信先)だけで完結する。Advanced fieldsは「同じHermesにジョブごとの別人格を持たせる」「LLMを呼ばずに通知だけ流す」「複数ジョブをpipeline化する」などの応用編で、第IX部Voice周辺のAutomation Blueprintsで詳しく扱う予定だ。

![新しいCRONジョブモーダル全体。基本4欄(名前/プロンプト/スケジュール/配信先)の下に「Advanced fields」セクションが初期から開いた状態で表示され、Provider/Model/Base URL override/script/no_agent/context_from/enabled_toolsets/workdirの8欄が縦に並ぶ画面](/images/hermes-vps/hermes-vps-08-dashboard-cron-new-job-modal-advanced-fields.png)

第8回(Dashboard)で見たCRON新規作成モーダルのスクショはv0.16.0時点のもの。実機v0.17.0で開くと、同じモーダルの下に同じAdvanced fields欄が並ぶようになっているが、本記事の手順で入力する基本4欄の意味と動きは変わらない。

:::message
**2026-07-01追記**:pre-run scriptのdefaultタイムアウトが120秒から1時間(3600秒)へ引き上げられた([PR#55489](https://github.com/NousResearch/hermes-agent/pull/55489))。長時間かかるデータ収集scriptをcronから走らせるユースケースに合わせた変更で、以前のように「120秒で強制中断されて途中で止まる」ハマりが解消された。envや`cron.script_timeout_seconds`での明示上書きは引き続き有効で、そちらが優先される。scriptとエージェントは別の時間制限で動く点は変わらない(エージェント側は`HERMES_CRON_TIMEOUT`のidle基準で、default 600秒・0で無制限)。
:::

:::message
**2026-07-01追記**:cronジョブ出力に含まれる秘密(APIキーやトークン)のredactionが失敗した場合の挙動が改善された(commit `da4f15cdd`)。以前は失敗を静かに握りつぶしてstdout/stderrがそのまま流れる可能性があったが、現在は警告ログを出したうえで出力を`[REDACTED - redaction failed]`で置き換える。cronの配信先や実行ログに秘密が漏れないよう安全側に倒れる。
:::

:::message
**2026-07-01追記**:cron delivery経由でTelegramへ長文を送るとき、`Message is too long`で失敗する不具合が[PR#28557](https://github.com/NousResearch/hermes-agent/pull/28557)で修正された。MarkdownV2エスケープ後のUTF-16長を正しく計算するようになり、4096文字を超える整形済みメッセージも自動分割で届く。以前は生テキストのUTF-16長で判定していたため、`!`や`.`などが`\!`や`\.`に膨らんで上限超過する場合があった。長文の要約プロンプトを組んでも切れずに届く。
:::

:::message alert
**2026-07-03追記(v0.18.0・注意)**:`base_url`欄でこのジョブだけ別のproviderを使う設定は、v0.18.0以降**制約が入った**([PR#56196](https://github.com/NousResearch/hermes-agent/pull/56196))。`custom_providers`に事前登録したエントリ、またはoverride先のホストが元providerの正規endpointと一致する場合のみ許可され、それ以外の`base_url`上書きは資格情報漏洩防止のため拒否される。既知のprovider(OpenAI/Anthropic等)に対して勝手なホストを指定する実験は動かない仕様に変わった。既存のcron設定(base_urlを触っていないジョブ)には影響しない。
:::

:::message
**2026-07-03追記(v0.18.0)**:cronの結果に返信して会話を続けられるようになった(thread-preferred continuation+DM-mirror fallback)。以前はcronの通知は一発配信で終わりだったが、届いた要約に「これについてもっと詳しく」のように返信すると、Hermesがその文脈を引き継いで応答する。本記事の手順(結果を受け取るだけ)は変わらず有効。
:::

## 引用元と参考

| 項目 | 引用元 |
|---|---|
| Hermes Agent Cron全般 | [automate-with-cron](https://hermes-agent.nousresearch.com/docs/guides/automate-with-cron) |
| スケジュール書式(cron/interval/relative/ISO) | 同上「Hermes supports relative delays, intervals, standard cron expressions, ISO timestamps」 |
| 5つの実用パターン | 同上「Five Real-World Patterns」 |
| self-contained promptの必須性 | 同上「Prompts must be completely self-contained」 |
| 配信先(ローカル/Telegram/Discord等) | 同上「Delivery Targets」 |
| `[SILENT]`による送信抑制 | 同上「When the agent's final response contains [SILENT], delivery is suppressed」 |
| Cron配信先5択の実装 | [web/src/pages/CronPage.tsx](https://github.com/NousResearch/hermes-agent/blob/v2026.6.5/web/src/pages/CronPage.tsx) |
| Dashboard cron Advanced fields追加(2026-06-27) | [PR#53551 feat(dashboard): expose cron job execution fields](https://github.com/NousResearch/hermes-agent/pull/53551) — `provider`/`model`/`base_url`/`script`/`no_agent`/`context_from`/`enabled_toolsets`/`workdir`の8項目を新規作成/編集モーダル両方に追加 |
| Cron内部実装の俯瞰(動画) | [HuggingFace公式「Hermes Architecture EXPLAINED: Memory, Context & Gateways」§cronジョブ(34:37〜)](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=2077s)(2026-06-16公開・英語・自動翻訳字幕で日本語可) |
| Telegram Bot API Rich Messages追加(2026-06-13) | [Pavel Durov公式ポスト](https://x.com/durov/status/2065896953519484976) — `We now support rich formatting for all chatbots. Tables, nested lists, inline media, formulas, headers and more`+[Telegram公式doc](https://core.telegram.org/bots/api#rich-message-formatting-options) |
| Hermes側のRich Messages追従予告(2026-06-13) | [Teknium公式ポスト](https://x.com/Teknium/status/2065777563356774688) — `Telegram has Rich Messages support now! Enjoy`+画像で「DEFAULT ON / No toggle / sendRichMessage API採用 / Agent system prompt hintに tables・task lists・math 追加」 |
