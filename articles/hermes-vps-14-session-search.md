---
title: "【第14回】Hermes Agentに過去の会話を自動で復元させる"
emoji: "🔍"
type: "tech"
topics: ["ai", "hermes", "sessionsearch", "vps", "claude"]
published: true
---

:::message
この連載は月1,800円ほどのVPSで、自分専用のAIエージェント(Hermes Agent)を24時間動かす実録だ。これはその第14回。全体の流れは[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::

## 目次

- [この回の到達点](#この回の到達点)
- [過去のやり取りが探せない、という痛み](#過去のやり取りが探せないという痛み)
- [今回は書庫に検索窓口を足す](#今回は書庫に検索窓口を足す)
- [概念整理(構成図)](#概念整理構成図)
- [事前準備](#事前準備)
- [過去会話の置き場を覗く](#過去会話の置き場を覗く)
- [自動発火を体感する(本回の核心)](#自動発火を体感する本回の核心)
- [sessionsとMemoryの使い分け](#sessionsとmemoryの使い分け)
- [まとめと第15回予告](#まとめと第15回予告)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [操作早見表](#操作早見表)
- [引用元と参考](#引用元と参考)

第12回でMemoryに「毎回使う前提」を、第13回でObsidian Vaultに「長く残しておきたい情報」を入れた。**付箋**(Memory)と**書庫**(Vault)の二段構えで、毎セッションの自己紹介と、気になった記事や調べごとの保存はもう困らない。

ただ、もう一つ足りない引き出しがある。「先週Telegramで相談した、あのAWSコスト最適化の件、どの順番で減らせばいいって言ってたっけ」のような**過去のやり取りそのもの**だ。これはMemoryに入れるには大きすぎるし、Vaultに自分の手で書き写すのも続かない。だが、Hermesは交わした会話を全部`~/.hermes/state.db`(SQLite+FTS5)に自動で記録している。第14回ではこの溜まった記録に検索の窓口を足し、**「思い出して」と頼むだけでHermesが自分で過去会話を引っ張ってくる**状態まで進める。書庫に**司書**を一人雇うイメージだ。

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
- [第9回](https://zenn.dev/sora_biz/articles/hermes-vps-09-cron) Hermes Agentに毎朝のタスクを自動実行させる
- [第10回](https://zenn.dev/sora_biz/articles/hermes-vps-10-skills) Hermes Agentが使うほど賢くなるSkillsの登録方法
- [第11回](https://zenn.dev/sora_biz/articles/hermes-vps-11-web-search) Hermes Agentに最新情報を自動取得させる方法

**第IV部 記憶を分けて育てる**
- [第12回](https://zenn.dev/sora_biz/articles/hermes-vps-12-memory) Hermes AgentにMemoryで好みと前提を記憶させる
- [第13回](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) Hermes AgentとObsidianを連携して知識を共有する方法
- **第14回**(本記事) Hermes Agentに過去の会話を自動で復元させる
- [第15回](https://zenn.dev/sora_biz/articles/hermes-vps-15-import-ai-sessions) Hermes AgentにClaude CodeやCodexの作業履歴を取り込む方法

全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

手を動かすのはほとんどない回だ。Session Searchは新しく設定するものがない。state.dbへの会話記録も、`session_search`ツールも、最初から有効になっている。だから本回は**すでに動いているものを目で確かめ、自動発火を体で理解する**のが主眼になる。SSHで現状を覗き、Telegramで「思い出して」と一言頼む。それで終わる。

## この回の到達点

第13回完了時と第14回完了後の差分を1分で押さえる。

| 項目 | 第13回完了時 | 第14回完了後 |
|---|---|---|
| 覚えている範囲 | 「毎回使う前提」(Memory)+「長く残しておきたい情報」(Obsidian Vault) | +「やり取りしたこと」(過去の全会話・state.db) |
| 過去の会話の扱い | 意識していない(裏で溜まってはいる) | Hermesが自分で検索して引っ張ってくる(`session_search`) |
| 「先週の話、何だっけ」 | 自分でチャットを遡るしかない | 「思い出して」と頼めば向こうが探す |
| 過去会話を覗く手段 | なし | `hermes sessions`で一覧・対話検索・統計が見える |

一言でまとめると「Hermesに、自分の過去の会話まで思い出させる」回だ。

この回で出てくる用語を先に押さえておく。

| 用語 | 意味 |
|---|---|
| Session(セッション) | Hermesとの1回分の会話。CLI・Telegram・Discord・cronなど、入口ごとに記録される |
| `state.db` | 過去の全会話が入ったSQLiteデータベース。場所は`~/.hermes/state.db`。全文検索用の索引(FTS5)が付いている |
| FTS5 | SQLiteの全文検索エンジン。大量の文章から該当箇所を高速に探す仕組み。Session Searchの土台 |
| `session_search` | Hermesが過去会話を検索するために**自分で呼び出す内蔵ツール**。人が直接打つコマンドではない。v0.15以降はLLMを使わない無料・高速(約0.06秒)の検索になった |
| `hermes sessions` | 人が手で過去会話を覗く・整理する管理コマンド。`list`(一覧)・`browse`(対話的に探す)・`stats`(統計)など |
| `/new`(Telegramコマンド) | 同じDM内で新しいセッションに明示的に切り替える。これを打つと、それまでのやり取りは「過去のセッション」として扱われ、自動発火の対象になる |
| セッションリセット | 同じDMでも一定時間(idle・デフォルト24時間)経過、または毎日特定時刻(daily・デフォルト4時)で会話の単位が自動的に切れる仕組み |

## 過去のやり取りが探せない、という痛み

機能の説明より先に、自分の「あるある」から入る。

### 「あれ、何て言ってたっけ」が探せない

前にHermesに相談した話を、もう一度持ち出したいときがある。「先週Telegramで話した、あのAWSコスト最適化の件、どんな順序で減らせって言ってたっけ」。チャットを遡るが、どの日だったか分からず、スクロールを10分続けて諦める。AIに相談した本人が、相談した内容を取り出せない。

第12回のMemoryは「毎回使う前提」(名前・家族・好み)を覚えるが、先週の具体的なやり取りまでは持っていない。第13回のObsidian Vaultは「長く残しておきたい情報」(調べた記事や自分のメモ)を貯める箱だが、Hermesとの会話そのものは手で書き写さない限り入らない。**過去のやり取りは、どちらの引き出しにも入っていない**。

これは第13回まで進めても、構造的に残ってしまう穴だ。「気になった記事」「自分の人物カード」は置き場が決まったが、「自分が交わした会話」は置き場が宙に浮いている。

### でも、記録は全部残っている

実は、Hermesは交わした会話を全部`~/.hermes/state.db`に自動で記録している。CLIで打った会話、Telegramで送った会話、Discordで来た会話、cronが自動で動いた朝のニュース要約まで、すべて同じデータベースに入っている。**消えてはいない**。問題は「探せない」ことだけだ。

Session Searchは、この溜まった記録に検索の窓口を付ける。しかも、人が検索ボタンを押すのではなく、**Hermesが「これは過去に話した件だな」と気づいて、自分で検索する**。「思い出して」と頼むだけで、向こうが探してくれる。第13回までの「書庫」に、司書を一人雇うイメージだ。

## 今回は書庫に検索窓口を足す

第13回で置いた4つの比喩を、もう一度フルで並べ直す必要はない。今回は1つだけ足す。

### 4つの比喩はそのまま、書庫に「司書」を置く

第13回で、Memory=付箋、Obsidian Vault=書庫、Skills=手順書、Cron=棚卸し、という4つの比喩を置いた。今回のSession Searchは、新しい5つ目の比喩ではない。**書庫に「司書」を置く**話だ。

| 比喩 | Hermes機能 | 役割 |
|---|---|---|
| 📝 付箋 | Memory(USER.md/MEMORY.md) | 短い前提・毎回使うもの・手元に貼っておく |
| 📚 書庫 | Obsidian Vault | 長いログ・調査・長期保存・棚から引き出す |
| 🧑‍🏫 司書 | Session Search(state.db) | **書庫の中身を自動で探して持ってくる**(本回で追加) |
| 📋 手順書 | Skills | 「こう動く」のレシピ・状況に応じて取り出す |
| 🧹 棚卸し | Cron | 定期的に整える・古いものを片付ける |

司書が扱う「書庫」は、第13回のObsidian Vault(自分で残したメモ)と本回の`state.db`(過去会話の自動記録)の両方を含む。物理的には別ファイルだが、Hermesから見ると同じ「書庫の棚」として扱われる。本回の司書(Session Search)が主に出入りするのは`state.db`の棚だ。

書庫(過去の記録)に本は溜まっている。だが棚から目当ての1冊を自分で探すのは大変だ。そこに司書を雇う。「先週相談した、あのAWSコスト最適化の件の記録、出してきて」と言えば、司書が書庫から該当の記録を見つけてくる。Session Searchは、この司書にあたる。

:::message
第12回(付箋)→第13回(書庫)→**第14回(書庫に司書=検索窓口)**、と積み上がっている。比喩の地図は前回のまま。今回はそこに動詞を1つ足すだけだ。「呼び戻す」という動作が書庫に加わる。
:::

## 概念整理(構成図)

過去会話に触れる経路は2つある。ここを分けて理解しておくと、本回の章立てが腑に落ちる。

### 同じstate.dbに、2つの経路がある

![Hermesの会話(CLI/Telegram/Discord/cron)が`~/.hermes/state.db`(SQLite+FTS5)に自動で記録され、そこから(a)Hermesが自分でsession_searchを呼ぶ自動経路と、(b)人がhermes sessionsコマンドで覗く手動経路の2つに分岐する構成図](/images/hermes-vps/hermes-vps-14-session-search-architecture-diagram.png)

会話は入り口を問わず1か所(`~/.hermes/state.db`)に集約される。そこから先に2つの経路が伸びる。

| 経路 | 誰が動かすか | 何のため |
|---|---|---|
| (a) 自動経路 | Hermesが自分で`session_search`を呼ぶ | 「思い出して」で発火し、過去会話を引いて答える |
| (b) 手動経路 | 人が`hermes sessions`コマンドで覗く | 中身を自分の目で確認する・整理する |

(a)が本回の主役=自動発火。(b)は「中身を自分の目で見たい」ときの手段で、(a)がうまく働かなかったときの確実な代わりにもなる。本回は(b)で中身を覗いてから(a)を体感する順で進む。

### session_searchは「無料・高速」になった

古い情報では「過去会話の検索には要約用のAIモデルを割り当てる」と書かれていることがあるが、v0.15以降は違う。`session_search`は**LLM(生成AI)を使わない、純粋な全文検索ツール**に作り直された。実機で測ると1回あたり約0.06秒。APIの料金もかからない。だから「検索のためにモデルを設定する」必要はない。すでに有効になっている。

:::message
過去会話を「要約」する別の仕組み(compression)は存在するが、それはSession Searchとは別物で、本回のスコープ外だ。本回は「探して引いてくる」までを扱う。
:::

## 事前準備

VPSに接続して稼働を確認し、過去会話の記録ファイル(`state.db`)が実在することを目で見る。次の2点が揃ったら次章へ進める。

### VPSの実機バージョン確認

```bash
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps
hermes version                                  # v0.17.0(2026.6.19 The Reach Release)以降を確認
```

![ターミナルでhermes versionを実行した結果。Hermes Agent v0.17.0(2026.6.19)upstream 4362c1a3、Project /home/admin/hermes-agent、Python 3.11.15、OpenAI SDK 2.24.0、Up to dateが並ぶ画面](/images/hermes-vps/hermes-vps-14-version-check.png)

v0.17.0より古いバージョンが出る場合は、`hermes update`で本体を最新に上げてからやり直す。本回の手順自体はv0.15以降で動くが、第15回以降との接続を考えると最新版で揃えておく方が安心だ。

### 過去会話の記録ファイル(state.db)を確認

Hermesが会話を溜めているデータベースが実在することを目で見る。`state.db`本体に加えて、書き込み中の一時ファイル(`-wal`/`-shm`)が並ぶのが正常な状態だ。

```bash
ls -la ~/.hermes/state.db*
# state.db / state.db-shm / state.db-wal が並ぶ
```

![ターミナルでls -la ~/.hermes/state.db*を実行した結果。state.db(約95MB)とstate.db-shm(32KB)とstate.db-wal(0バイト)の3ファイルが所有者adminで並んでいる画面](/images/hermes-vps/hermes-vps-14-statedb-ls.png)

このファイルが「書庫」の実体だ。サイズ(数十MB)を見ると、すでにそれなりの量の会話が溜まっていることが分かる。SQLiteは書き込み中の差分を`-wal`(Write-Ahead Log)に貯めてから本体にまとめる仕組みなので、3ファイル並んでいるのが普通の姿だ。なお、`ls`はバイト数を直接示し、`hermes sessions stats`(次章で使う)は同じ値をMiB(2進ベース)で「91.2 MB」と表示する。両者は同じ95,678,464バイトを別の単位で表しているだけだ。

:::message
紛らわしいが、`~/.hermes/sessions/`という別のフォルダもある。こちらは古い形式の会話ダンプ(`.jsonl`)が残っている置き場で、現在の検索が使うのは`state.db`のほうだ。本回で覚えるのは`state.db`だけでよい。
:::

### 撮影用に1往復だけ仕込んでおく(§7の下準備)

§7で「思い出して」と頼む核心の体感をするため、その前に**一度だけ普通の話題でHermesと話しておく**。これでstate.dbにその会話が記録され、後で確実に検索対象になる。実際に話していない話題を「思い出して」と頼んでも引けないので、必ず一度本当に話す。

先日、妻と高校生の娘に「名古屋、グルメ以外で何があるかわからん」と言われ、Hermesに映えスポットを聞いてみた。本回の題材はこれをそのまま再現する。Telegramで以下のような自然な会話を1往復する。

```text
(自分からHermesへ)
7月に家族で名古屋旅行に行くんだけど、高校生の娘が好きそうな映えスポットを教えて。

(Hermesからの応答)
候補スポットの提案が返ってくる
```

1往復で十分だ。これでstate.dbに「名古屋」「映えスポット」「娘」を含む会話が1つ記録される。普段の生活の中で実際に相談したい話題でやれば、それがそのまま§7の材料になる。

### 自動発火を体感する前にセッションを区切る(重要)

Telegramの同じDMは標準では1つの連続セッションとして続く。前項で仕込んだ直後に同じDMで「思い出して」と聞いても、それは**現在のセッションの一部**でしかなく、`session_search`は発火しない(Hermesは目の前のやり取りをそのまま使う)。仕込んだ会話を**過去のセッション**に変える必要がある。

方法は3つ。自分の運用に合うものを選ぶ。

| 方法 | 手順 | 確実さ・タイミング |
|---|---|---|
| 方式A・`/new`で明示リセット | 仕込みの直後にTelegramで`/new`を送信。即座に新セッションが切れる | 最確実・同日中に体感可 |
| 方式B・24時間以上空ける(idle reset) | 夜に仕込み→翌夜に体感。1440分(24時間)非活性で自動的に新セッションになる | 自然・運用想定に近い |
| 方式C・翌朝4時を跨ぐ(daily reset) | 夜に仕込み→翌朝に体感。デフォルトで毎日4時に新セッションが切れる | 自然・最短で翌朝体感可 |

:::message
出典:[messaging](https://hermes-agent.nousresearch.com/docs/user-guide/messaging)に「全プラットフォームで`/new`が使える」と「idle session resetはデフォルト1440分(24h)」「reset modesはboth/idle/daily/none、4 AMがdaily reset」が明記されている。第13回までで動かしてきたTelegram会話を実機で書き出すと、確かに時間境界でセッションが分かれていることが目で確認できる。
:::

本回ではAを採る。仕込みの直後に続けて体感まで進めるため、即座にセッションを切れる`/new`が最適だ。BとCは「24時間以上空けて翌日に試す運用」「翌朝に区切りを入れる運用」の選択肢として頭の隅に置いておけばよい。

## 過去会話の置き場を覗く

自動発火を体感する前に、人の側から「どれだけ溜まっているか」「どんな会話があるか」を覗いておく。これが構成図(b)の手動経路だ。

### どれだけ溜まっているか(stats)+最近の会話(list)

まず統計を見る。何セッション・何メッセージ溜まっているか、データベースのサイズはどれくらいか。

```bash
hermes sessions stats
```

実機ではこう表示される(数字は環境による)。

```text
Total sessions: 188
Total messages: 3789
  cli: 17 sessions
  telegram: 40 sessions
  discord: 2 sessions
Database size: 91.2 MB
```

連載をここまで進めてきた手元の実機(VPS常駐3か月相当)で、188セッション・3,789メッセージ・91.2MBが溜まっていた。stats出力にはcli/telegram/discordの3カテゴリしか出ないが、合計188との差分129件は次に見るlistのID列を見ると正体が分かる──`cron_*`プレフィックスのセッション(第9回で入れた毎朝のニュース要約や夜の振り返りなど)が大半を占めている。Telegramの40が「自分が能動的に話した会話」、CLIの17が「sshで入って打った会話」になる。

続けて最近の会話を一覧する。タイトルは自動で付けられている。

```bash
hermes sessions list
```

![ターミナルでhermes sessions statsとhermes sessions listを続けて実行した結果。statsの出力にTotal sessions 188・Total messages 3789・cli 17/telegram 40/discord 2・Database size 91.2 MBが並び、その下のlist出力に最近の会話タイトル(evening-tomorrow、morning-news、hermes-ecosystem-watch、hermes-watch、evening-reflectionなど)+ 仕込みで話した名古屋旅行の会話が23時間前の行に並んでいる画面](/images/hermes-vps/hermes-vps-14-sessions-stats-list.png)

「タイトル / プレビュー / 最終更新 / ID」が並ぶ。`morning-news`や`evening-reflection`のような自動会話(cron由来)と、自分が話した会話が混ざって見える。これが「書庫の棚」だ。

### 対話的に探す(browse)

一覧から目当ての会話を対話的に探して、その続きを再開(resume)できるのが`browse`だ。

```bash
hermes sessions browse
```

![ターミナルでhermes sessions browseを実行した結果。Browse sessionsのヘッダー(↑↓ navigate Enter select Type to filter Esc quit)の下にTitle/Preview/Active/Src/IDの5列テーブルが並び、カーソルが「名古屋家族旅行」の行に当たって緑にハイライトされている画面。Src列でcron/telegr/cliの区別が見える](/images/hermes-vps/hermes-vps-14-sessions-browse.png)

会話のピッカー(選択画面)が開き、キーワードで絞り込んで選べる。これは「司書に頼まず、自分で書庫の棚を歩く」経路だ。次章の自動発火がうまく働かないときも、ここから確実に過去会話へたどり着ける。Enterを押せば、その会話の続きをCLIから再開できる。

## 自動発火を体感する(本回の核心)

ここが本回の山場だ。何も設定していないのに、Hermesが過去会話を自分で引いてくる。それをTelegramで体感する。

### 「思い出して」と頼むだけ

ここで先に発火の勘所を1つ押さえておく。試しに「先週の名古屋旅行の件、覚えてる?」と聞くと、Memoryには名古屋という地名は無いのでHermesは「すぐには思い出せません」と返してしまうことがある(Memoryは「私のこと」しか持っていないため、雑談トピックは入っていない)。同じことを「どういう話だったか思い出して教えて」と頼み直すと、Hermesが自分で`state.db`を検索しに行く。同じ依頼でも、**依頼形ひとつで引き出しの開き方が変わる**。

母艦からTelegramで、仕込んだ名古屋旅行の映えスポット相談について「思い出して」と頼む。前章で`/new`を打ってセッションを切ってあれば、これが「過去のセッションへの参照」になる。

```text
前に7月の名古屋旅行で娘が好きそうな映えスポットを聞いたよね。
どこを薦めてくれたか、思い出して教えて。
```

![母艦のTelegram画面でHermesに「前に7月の名古屋旅行で娘が好きそうな映えスポットを聞いたよね。どこを薦めてくれたか、思い出して教えて。」と送り、Hermes側で細字のsession_search進捗(args付きのtool call)が表示された後、過去会話の中身を踏まえた応答が返ってきている画面](/images/hermes-vps/hermes-vps-14-telegram-recall-request.png)

:::message alert
**発火するプロンプトの作り方**

「覚えてる?」のように**yes/noで答えられる質問**だと、Hermesは「はい」だけ返して`session_search`を呼ばないことがある。「**どういう話だったか思い出して教えて**」のように**過去の中身の呼び出しを明示的に要求**すると、ほぼ確実に発火する。実機で繰り返し試した感触として、これが一番安定する依頼形だ。
:::

### Hermesが過去会話を引いて答える

依頼を送ると、Hermesは「これは過去に話した件だ」と判断し、自分で`session_search`を呼ぶ。実機v0.17.0(2026.6.19)では、Telegram画面の応答テキストの直前に細字でツールの呼び出し進捗が出ているのが確認できた。それ以前のバージョンで同じ進捗表示が出るかは未確認だが、本回時点のv0.17.0であれば見える挙動だ。そして過去会話の中身を引いて、「先週はこういう候補をお伝えしました」と答えが返ってくる。

**人は検索コマンドを一切打っていない**。「思い出して」と頼んだだけで、向こうが書庫まで取りに行って、該当の記録を引いて答えた。これがSession Searchの「自動で復元させる」の正体だ。

### 裏で何が起きているか(CLIで詳しく見る)

Telegramでも進捗の概要は出るが、より詳しく見たいときはCLIで`-v`(verbose)を付けて動かすと、検索クエリの中身まで露わになる。2026-06-24に手元の母艦からsshで入って、Xブックマークの整理話で実機検証したときのログを引いておく(別話題だが`session_search`の挙動を確認した実機ログ)。

```text
[thinking] 過去の関連会話を探すため session_search を使う

🛠️  Tool call: session_search
     args: {"query":"X ブックマーク 整理 カテゴリ","limit":10,"sort":"newest"}
✅ session_search completed (0.06s)
```

「思い出して」の一言から、Hermesが自分で検索クエリ(`X ブックマーク 整理 カテゴリ`)を組み立て、0.06秒で過去会話を引いている。クエリの単語はこちらが指定したわけではない。依頼文の中身から、Hermesが自分で抜き出して組んだものだ。

:::message
このログはCLIを`-v`で動かしたときだけ細かい中身まで見える。普段のTelegram運用では概要だけが裏に流れていて、利用者は「思い出して」と頼んで答えを受け取るだけでよい。仕組みを一度見ておくと、安心して任せられる。
:::

### ビフォー/アフター

| 状態 | 「先週の名古屋旅行の件、何て言ってた?」への反応 |
|---|---|
| Memoryだけ(第12回) | 「私のこと」は答えられるが、先週の具体的なやり取りは持っていない |
| Vaultも追加(第13回) | 自分で書き写したノートは引けるが、書き写していない会話は出てこない |
| Session Search(本回) | 過去会話を自分で検索し、「先週はこう話していました」と中身を引いて答える |

第12回→第13回→第14回で、覚えている範囲が「短い前提」「長く残した知識」「過去のやり取り全部」と3段階に広がった。3つの引き出しが揃って、初めてHermesは「忘れない相棒」と呼べる状態になる。

## sessionsとMemoryの使い分け

読者が混同しやすい「sessions(やり取りの記録)」と「Memory(私のこと)」の境界を整理し、普段は触らない方がよいものに触れておく。

### sessionsとMemoryは別物

| 層 | 中身 | 誰が読むか |
|---|---|---|
| Memory(USER.md/MEMORY.md) | 私のこと=名前・家族・好み・前提 | 毎セッション開始時に自動で読み込まれる |
| sessions(state.db) | 過去の会話そのもの=やり取りの全文 | 必要なときに`session_search`で検索される |

Memoryは「毎日カバンに入れて持ち歩く必需品」、sessionsは「必要なときに開く会話ログの書庫」。Memoryに会話を全部詰め込む必要はないし、できない(第12回で見たとおりUSER.mdは1,375字・MEMORY.mdは2,200字の上限がある)。会話の記録はsessionsが自動で受け持つ。役割が違う。

### 古い履歴の整理は「棚卸し」の回に任せる

会話が溜まり続けるとstate.dbは大きくなる。連載をここまで進めてきた手元では3か月で91MBだった。1年回せばさらに伸びるが、実際の増え方はcronの回し方やTelegramの利用量で大きく振れる。月1回程度`hermes sessions stats`の伸び方を見ておけば、整理が必要なタイミングは自然に判断できる。古い履歴をまとめて片付ける作業はあるが、それは「棚卸し」=Cron/Curatorの領域だ(連載後半の予定回で扱う)。本回では「呼び戻せること」に集中し、整理は棚卸しの回に回す。

### 普段は手で触らない

`state.db`はHermesが管理するSQLiteデータベースだ。中身の整理や削除をしたいときに必要なコマンド(`delete`/`prune`/`rename`)は`hermes sessions`サブコマンドとして既に揃っているので、直接エディタで開く必要はそもそも出てこない設計になっている。書き込み中(`-wal`に未反映の差分がある状態)でも`hermes sessions`経由なら安全に扱えるので、これに任せておけばよい。

:::message
「過去会話を書き出して別の道具に渡したい」「特定の会話に名前を付けたい」といった応用は`hermes sessions`の`export`/`rename`でできる(中級者向け)。コマンドは末尾の早見表にまとめた。本回の本筋は「自動で呼び戻る」体験なので、これらは必要になったときに使えばよい。
:::

## まとめと第15回予告

第14回でやったこと。

- VPSの実機v0.17.0で`~/.hermes/state.db`が実在することを確認した
- `hermes sessions stats`で累積セッション数・メッセージ数・DBサイズを目で見た
- `hermes sessions list`/`browse`で過去会話の棚を歩いた
- Telegramで「思い出して」と頼むだけで、Hermesが自分で`session_search`を呼んで過去会話を引いてくる自動発火を体感した
- 発火しやすい依頼形(「思い出して教えて」)と、発火しにくい依頼形(「覚えてる?」)の違いを押さえた
- 同じDMでセッションを区切る方法3つ(`/new`/idle reset/daily reset)を整理した
- sessionsとMemoryの役割の違い(やり取りの記録/私のこと)を境界として置いた

これで、Hermesは「毎回使う前提(Memory)」「長く残しておきたい情報(Obsidian Vault)」「やり取りしたこと(Session Search)」の3つを揃って持てる相棒に育った。「先週Telegramで話した、あのAWSコスト最適化の件」のような頭の隅にしか残っていない断片も、「思い出して」と頼めば向こうが書庫から引いてくる。

第15回(予定)は、その射程を**他のAI**に広げる。母艦で動かしているClaude CodeやCodexの会話履歴も、同じ書庫に取り込めるようにする。自分の会話を呼び戻せるようになったHermesが、次は別のAIとの会話まで束ねていく段階だ。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第13回 Hermes AgentとObsidianを連携して知識を共有する方法](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) | [第15回 Hermes AgentにClaude CodeやCodexの作業履歴を取り込む方法](https://zenn.dev/sora_biz/articles/hermes-vps-15-import-ai-sessions) |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## よくあるエラーと対処

| 症状 | 原因 | 対処 |
|---|---|---|
| 「思い出して」と頼んでも過去会話を引いてこない | その話題を実際には話していない(state.dbに無い) | 一度その話題でHermesと実際に話す。または`hermes sessions browse`で手動で探す |
| 同じTelegramのDMで仕込み→そのまま「思い出して」が効かない | 同一セッション内なので`session_search`が発火せず、Hermesは現在文脈から答えてしまう | Telegramで`/new`を送って新セッションに切る。または24時間空けて再依頼する(idle reset・デフォルト1440分) |
| 「覚えてる?」と聞いても発火しない | yes/noで答えられる質問だと、Hermesは現在の知識だけで答えてしまうことがある | 「どういう話だったか思い出して教えて」のように**過去の中身の呼び出しを明示**する形式に変える |
| 引いてくる会話が見当違い | 検索キーワードが曖昧 | もっと具体的な言葉で頼む(「名古屋旅行の映えスポットの件」のように固有の語を入れる) |
| `hermes sessions list`に何も出ない | まだ会話が記録されていない | 一度Hermesと会話してから再実行 |
| state.dbが大きくなりすぎた | 古い会話が溜まっている | `hermes sessions prune`で古い履歴を整理(自動化は連載後半のCurator回で扱う) |
| `state.db-wal`だけ巨大になる | Hermesが書き込み中に外から触った | Hermesを一度きれいに止めると本体側にまとまる。`systemctl --user restart hermes-gateway` |

:::message
**2026-07-03追記(v0.18.0)**:検索用インデックス(FTS5)の自動マージ(1000書き込みごと)+チェックポイント(50書き込みごと)が入り、通常運用で`state.db-wal`が放置されて肥大化することはほぼなくなった([#54752](https://github.com/NousResearch/hermes-agent/pull/54752)/[#54770](https://github.com/NousResearch/hermes-agent/pull/54770))。上記の対処は放置後の緊急復旧用として残しておく。
:::

## 操作早見表

```bash
# 過去会話を覗く・探す(人が手で叩く)
hermes sessions stats          # 累積数・メッセージ数・DBサイズ
hermes sessions list           # 最近の会話一覧
hermes sessions browse         # 対話的に検索して再開

# 過去会話を整える(必要になったら)
hermes sessions rename <id> "わかりやすいタイトル"   # 会話に名前を付ける
hermes sessions export out.jsonl                    # 会話を書き出す(中級者向け)
hermes sessions prune          # 古い会話を整理(破壊的・連載後半で自動化)

# 記録ファイルの場所
ls -la ~/.hermes/state.db*     # 過去会話のデータベース

# Telegramでセッションを区切る(Hermes側のチャットで打つ)
/new                            # 即座に新セッションへ切り替え
```

:::message
`session_search`(自動検索)は**コマンドではない**。Hermesが会話中に自分で呼ぶ内蔵ツールなので、ここに打つものは無い。人が叩くのは上の`hermes sessions`系と、Telegram側の`/new`だけだ。
:::

## 引用元と参考

| 項目 | 引用元 |
|---|---|
| Memory全般(sessions/state.dbの位置づけ) | [memory(features)](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory) |
| セッション境界(`/new`・idle reset・daily reset) | [messaging](https://hermes-agent.nousresearch.com/docs/user-guide/messaging) |
| `hermes sessions`コマンド | [configuration / CLI](https://hermes-agent.nousresearch.com/docs/user-guide/configuration) |
| クロスセッション記憶の実装者視点(参考) | [Tonbi (@tonbistudio) Hermes Agent Masterclass Module 3: Memory, Plugins, Honcho, Obsidian](https://www.youtube.com/watch?v=ZKZLko9kLm4)(英語・自動翻訳字幕で日本語可) |

<!-- 2026-06-25 ドラフト初版 -->

:::message
この連載はSubstack「そらのAIエージェント通信」で先行公開している。無料[登録](https://sorabiz.substack.com/subscribe)すると最新回がメールに届く。[Zennでフォロー](https://zenn.dev/sora_biz)すると新着通知が届き、全体像は[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::
