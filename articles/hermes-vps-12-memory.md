---
title: "【第12回】Hermes AgentにMemoryで好みと前提を記憶させる"
emoji: "🧠"
type: "tech"
topics: ["ai", "hermes", "memory", "vps", "claude"]
published: true
---

## 目次

- [この回の到達点](#この回の到達点)
- [2つのノートとfrozen snapshot](#2つのノートとfrozen-snapshot)
- [メモリ三層の全体像](#メモリ三層の全体像)
- [第12回終了時点の構成図](#第12回終了時点の構成図)
- [事前準備](#事前準備)
- [現状確認──hermes memory status](#現状確認hermes-memory-status)
- [TelegramでUSER.mdを育てる](#telegramでusermdを育てる)
- [Dashboardで保存を確認](#dashboardで保存を確認)
- [ファイル実体を覗く](#ファイル実体を覗く)
- [暴走を止める仕組み──Write Gate](#暴走を止める仕組みwrite-gate)
- [MEMORY.mdとの使い分け](#memorymdとの使い分け)
- [容量と整理](#容量と整理)
- [翌セッションでfrozen snapshotを実感](#翌セッションでfrozen-snapshotを実感)
- [外部プロバイダ8つの概観](#外部プロバイダ8つの概観)
- [運用例──続かない日記をHermesに任せる](#運用例続かない日記をhermesに任せる)
- [まとめと第13回予告](#まとめと第13回予告)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [操作早見表](#操作早見表)
- [引用元と参考](#引用元と参考)

第9回でCronを使って毎朝の定型仕事を任せ、第10回で手順そのものをSkillにまとめ、第11回で最新情報の取得まで届くようになった。ここまでで、エージェントはVPSの上で24時間動き、決まった時刻に自分から喋り出し、知識の引き出しも増えている。ただ、毎回のチャットの最初に「私の名前はそら、アラフィフの会社員、妻と高校生の娘の3人家族で」と打ち直していないだろうか。それを打ち直しているうちは、Hermes Agentはまだ「私」を覚えていない。

第12回でそこを終わらせる。Hermes本体に組み込みのMemory機能を使って、「私のこと」と「この環境のこと」を2枚のMarkdownノートに保存させる。次のセッションが始まると、その内容が自動でsystem promptに注入される。「私の名前は？」と聞いたら即答が返ってくる状態を作る。

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
- **第12回**(本記事) Hermes AgentにMemoryで好みと前提を記憶させる
- [第13回](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) Hermes AgentとObsidianを連携して知識を共有する方法

全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

手を動かすのは、SSHで`hermes memory status`を1回打つことと、Telegramで「私について次のことを覚えて」と1通送ることだ。あとはエージェントが自分で書き込む。

## この回の到達点

第11回完了時と第12回完了後の差分はこうなる。

| 項目 | 第11回完了時 | 第12回完了後 |
|---|---|---|
| 私のこと(名前/役割/前提) | 毎セッション言い直し | `~/.hermes/memories/USER.md`に保存・frozen snapshotで自動注入 |
| 恒久的な事実(環境/ファクト) | — | `~/.hermes/memories/MEMORY.md`にエージェントが書き溜める |
| 記憶の書き換え | — | memory tool(add/replace/remove・target=memory|user) |
| 安全装置 | — | Write Gate(承認制)が選べる |
| 容量管理 | — | MEMORY.md 2,200字 / USER.md 1,375字。超過時はエージェント自身がconsolidate |
| 外部プロバイダ | — | built-in onlyのまま運用。8プロバイダの存在は知っている |

一言でまとめると「Hermesに、私の前提と現場のメモを持たせる」回だ。

この回で出てくる用語を先に押さえておく。

| 用語 | 意味 |
|---|---|
| MEMORY.md | エージェントが書き溜める「環境ファクト」のノート。2,200字上限 |
| USER.md | 「私」の人物カード。1,375字上限。私自身が書く運用もできる |
| frozen snapshot | セッション開始時に注入される凍結スナップショット。途中で記憶が更新されても次回まで効かない=会話の前提が会話中に動かない |
| memory tool | エージェント側のツール。`add`/`replace`/`remove`、`target`は`memory`か`user` |
| Write Gate | 記憶書き換えに承認制を入れる仕組み。`memory.write_approval: true` |
| consolidate | 容量上限に近づいたときエージェント自身が要約・統合する作業 |

## 2つのノートとfrozen snapshot

Hermesの組み込みメモリは、ファイルが2枚だけだ。役割を分けて持つ。

| ノート | 主に書くのは | 中身 | 上限 |
|---|---|---|---|
| `USER.md` | 私(人間) | 名前 / 役割 / 主要環境 / 好み / NG / 文体など「私の前提」 | 1,375字(約500トークン) |
| `MEMORY.md` | エージェント | 動かしながら気づいた環境ファクト / 失敗→学び / 決定事項 | 2,200字(約800トークン) |

USER.mdは「自己紹介カード」、MEMORY.mdは「現場のメモ帳」。人が書くのもエージェントが書くのも両方できるが、書く主役を分けると暴走しにくい。

新しいセッションが始まると、Hermesはその時点のUSER.mdとMEMORY.mdを**固定して**system promptに注入する。途中でmemory toolが書き換えても、注入された内容はそのセッションの最後まで動かない。これがfrozen snapshotだ。

会話中にメモが書き換わると「さっきまでの前提」が崩れてエージェントの振る舞いがブレる。次回セッションの注入時点で初めて反映される設計にすることで、会話の一貫性を保つ。書いたことがその場で効いていないように見えるが、それは「次回からちゃんと効く」という設計の表れだ。

## メモリ三層の全体像

Hermesのメモリは3層に分かれている。第12回はそのうち1層目(Markdown)を主役にする。SQLite層は第14回(Session Search)で、外部メモリ層は本回の末尾で概観だけ触れる。読者の頭の地図を最初に渡しておく。

| 層 | 実体(実機v0.17.0で確認) | 誰が書くか | frozen snapshotに乗るか | 本連載で扱う回 |
|---|---|---|---|---|
| 1a. Markdown(人格) | `~/.hermes/SOUL.md`(直下・全大文字) | 私が書く(空ならデフォルトprompt) | 乗る(`hermes --ignore-rules`で除外可) | **第17回** |
| 1b. Markdown(人物カード) | `~/.hermes/memories/USER.md` | 私+エージェント | 乗る | **本回** |
| 1c. Markdown(環境ファクト) | `~/.hermes/memories/MEMORY.md` | エージェント(主) | 乗る | **本回** |
| 2. SQLite | `~/.hermes/state.db`(全session transcript+類似検索) | エージェント(自動) | 必要時にquery | **第14回Session Search** |
| 3. 外部メモリ | 8プロバイダ(byterover / hindsight / holographic / honcho / mem0 / openviking / retaindb / supermemory) | 各providerが管理 | 最初の質問後にquery=人間の「思い出し」と同パターン | 本回末尾で概観のみ |

Markdownの3ファイルが「いつもそこにある記憶」、SQLiteが「過去ログから引っ張れる記憶」、外部メモリが「もっと大きく/共有可能な記憶」だ。本回の射程は1bと1cの2枚に絞る。

## 第12回終了時点の構成図

第6回でsystemd常駐させたHermes Agentの中に、メモリ機能は最初から含まれている。新しく入れるものはない。VPS内のファイル配置と注入の流れはこうなる。

![Hermes Agent v0.16.0が常駐するVPSの中で、USER.mdとMEMORY.mdが~/.hermes/memories/に置かれ、セッション開始時にfrozen snapshotとしてsystem promptに注入される構成図](/images/hermes-vps/hermes-vps-12-memory-architecture-diagram.png)

ポイントは2つ。第一に、ファイルは2枚で済む。データベースを立てたり、外部サービスに繋いだりする必要は本回ではない。第二に、書き換えはエージェントが`memory` toolを呼ぶか、私がエディタで直接編集するかのどちらか。frozen snapshotで凍るので、変更は次セッションから効く。

## 事前準備

第11回までが完了していれば、追加で入れるものはない。VPSへSSHで入って稼働を確認する。

```bash
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps

hermes version                                  # v0.17.0(2026.6.19・The Reach Release)以降を確認
systemctl --user status hermes-gateway          # active (running)
ls -la ~/.hermes/memories/                      # USER.md / MEMORY.md があるか
```

`hermes-gateway`が`active (running)`で、`~/.hermes/memories/`の中に`USER.md`と`MEMORY.md`が並んでいれば準備は終わりだ。中身は空かもしれないが、それで構わない。Telegramからbotに「こんにちは」を送って返事が来ることも、最後にひととおり確認しておく。

## 現状確認──hermes memory status

記憶系のCLIサブコマンドは4つだけだ。まずは`--help`で全体像を掴む。

```bash
hermes memory --help
```

`Set up and manage external memory provider plugins.`の説明文のあと、サブコマンドが`setup` / `status` / `off` / `reset`の4つだけ並ぶ。built-inのMEMORY.md/USER.mdは常に動いているので、ここに「on」コマンドはない。これらの4サブコマンドが操作するのは、後で触れる外部プロバイダの方だ。

![hermes memory --helpの出力。Set up and manage external memory provider plugins.の説明と、setup / status / off / resetの4サブコマンドが並ぶターミナル画面](/images/hermes-vps/hermes-vps-12-memory-help.png)

次に、現状を見る。

```bash
hermes memory status
```

`Built-in: always active`と`Provider: (none — built-in only)`が出れば、まだ外部プロバイダは何も繋いでいない=built-inだけの素の状態だ。下に`Installed plugins:`として8プロバイダがリストされる。それぞれ`(requires API key)`(クラウド専用)/`(API key / local)`(両対応)/`(local)`(完全ローカル)の補足が付く。

![hermes memory statusの出力。Built-in: always activeとProvider: (none — built-in only)が表示され、Installed pluginsに8プロバイダ(byterover / hindsight / holographic / honcho / mem0 / openviking / retaindb / supermemory)が種別補足付きで並ぶターミナル画面](/images/hermes-vps/hermes-vps-12-memory-status.png)

8プロバイダが見えるが、今は全部使わない。本回はbuilt-inのMEMORY.md/USER.mdだけで完結させる。`holographic`だけが完全ローカル、`byterover`と`supermemory`はAPI Key必須、それ以外は両対応、という温度差を頭に置いておけば足りる。

## TelegramでUSER.mdを育てる

記憶を入れる一番自然な方法は、Telegramでエージェントに話しかけて、覚えるべきことを伝えることだ。エージェントが内部の`memory` toolを呼んでUSER.md/MEMORY.mdに書き込む。

### 「私について次のことを覚えて」と頼む

Telegramで次のように送る。最初は3〜4項目で十分だ。あとから足せる。

```text
私について次のことを覚えて。
- 名前はそら
- アラフィフの会社員
- 妻と高校生の娘の3人家族
```

Hermesは内部で`memory(action="add", target="user", content="...")`を呼び、USER.mdに3項目を追記する。返事は「USER.mdに記録した」「以下を追記しました」のような自然文で返ってくる。

![Telegramのチャット画面。私のメッセージ「私について次のことを覚えて。名前はそら、アラフィフの会社員、妻と高校生の娘の3人家族」が上に、botの応答「USER.mdに記録しました」と3項目の確認文が下に並ぶ画面](/images/hermes-vps/hermes-vps-12-telegram-add.png)

### エージェントが覚えるもの・捨てるもの

エージェントはなんでも書き込むわけではない。公式の指針では、何を保存して何を捨てるかが7分類で示されている。

| 保存する(save) | スキップする(skip) |
|---|---|
| 好み(口調・出力形式・NG語彙) | 些細な質問や雑談 |
| 環境(OS・パス・ホスト名) | 検索すればすぐ分かる事実 |
| 安定した事実(家族構成・職業) | 生データの丸ごとダンプ |
| 修正(「それは違う、こうしてほしい」) | そのセッション内だけで有効な情報 |
| 規約(常に守ってほしいルール) | |
| 完了した作業の合意 | |
| 「これを覚えて」と明示的に頼んだもの | |

「今日の天気」「いまの株価」のような時間で腐る情報はメモに残らない。「私の名前」「住んでいる地域」「文体の好み」のような腐りにくい前提だけが残る設計だ。

### 上限は機能──だから整理が促される

USER.mdは1,375字、MEMORY.mdは2,200字という小さな上限がある。これは制約ではなく**機能**として置かれている。上限がないと、エージェントは雑談やセッション固有の情報まで蓄積していき、ノートが「ゴミ箱」になる。上限があるからこそ「これは保存に値するか」「古い項目を畳めないか」と整理が促される。容量が80%を超えると、後述するconsolidate(統合・要約)が自然と必要になる。

## Dashboardで保存を確認

第8回で開いたWeb Dashboard(`http://hermes-vps:9119`等)で、書かれた中身を確かめる。実機v0.17.0時点ではDashboard左サイドバーに専用の「メモリ」ペインは存在しない。代わりに「セッション」ペインから、Telegramでの会話がどう保存されたかが見える。なおv0.17.0では本Dashboardにprofile builder(`config.yaml`手編集なしでmodel/skills/MCPを選べる)+secure login(token必須endpointは401返却)が追加されているが、本回は記憶の確認だけなので使わない。

左サイドバーの「セッション」を開くと、「最近のセッション」の一覧にTelegramで送った会話が新しいセッションとして並ぶ。タイトル(例「そらのプロフィール記憶」)はHermesが自動生成する。本文プレビューに「私について次のことを覚えて」の冒頭が表示されている。

![DashboardのSessions(セッション)ペインを開いた状態。最近のセッション一覧にTelegramの会話が新しいセッションカードとして表示され、Hermesが自動生成した日本語タイトル(例「そらのプロフィール記憶」)と本文プレビューが見える画面](/images/hermes-vps/hermes-vps-12-dashboard-sessions.png)

セッションカードをクリックすると、`memory` tool callの内訳(`memory(action="add", target="user", …)`)まで深掘りできる。本回の主役はUSER.mdの実体なので、ここは「確かに保存された」を確認するだけで十分だ。実体は次の章で見る。

## ファイル実体を覗く

GUIだけでは「本当に書かれた？」が分かりにくい。VPSのターミナルから直接ファイルを開く。

```bash
cat ~/.hermes/memories/USER.md
wc -m ~/.hermes/memories/USER.md   # 文字数(1,375字以内か)
```

`cat`で先ほど書いた3項目が本文に並んでいるのが見える。`wc -m`の数字が1,375以下に収まっていることも確認する。

![cat ~/.hermes/memories/USER.mdとwc -m ~/.hermes/memories/USER.mdの出力。Telegramで送った3項目(名前/アラフィフ/家族構成)が本文に並び、文字数が1,375字以内に収まっているターミナル画面](/images/hermes-vps/hermes-vps-12-user-md-cat.png)

MEMORY.mdは空かもしれない。USER.mdを育てただけならMEMORY.mdには何も書かれていない。エージェントが運用中に「失敗→学び」「決定事項」を書く想定なので、本回の時点で空でも問題ない。

```bash
cat ~/.hermes/memories/MEMORY.md
wc -m ~/.hermes/memories/MEMORY.md  # 2,200字以内か
```

## 暴走を止める仕組み──Write Gate

記憶は便利な一方で、自分の意図しないことまで書き込まれる可能性もある。そのための承認制が用意されている。

Hermesには「書き換え1件ごとに人間の承認を要求する」モードがあり、`~/.hermes/config.yaml`の`memory.write_approval`を`true`にすると、エージェントが`memory(action="add", …)`を呼ぶたびに保留状態になる。Telegramの`/memory pending`で保留中の書き込みを確認し、`/memory approve <id>`で承認、`/memory reject <id>`で却下する。

```bash
hermes config set memory.write_approval true     # 承認制に切替
hermes config set memory.write_approval false    # 自動書込に戻す(デフォルト)
systemctl --user restart hermes-gateway          # 反映に再起動が必要
```

Telegram上で`/memory approval on / off`を送っても同じ切り替えができる。

本連載ではWrite Gateを**オフ**(自動書込)のまま運用していく。理由は3つある。第一に、後述する「夜の振り返り」のような毎日の対話と相性が悪い。寝る前に承認操作を求められると、「続かない自分の代わりに記憶する相棒」の体感が壊れる。第二に、記憶が間違っていればnanoで直接編集すれば直る。事前承認のコストより事後修正のコストの方が圧倒的に軽い。第三に、USER.mdは1,375字、MEMORY.mdは2,200字の小さなファイルだ。週に1度`cat`で目を通せば、変な書き込みは目視で見つけられる。

「事実と違う書き込みが入って気づかないのが怖い」というケースのときだけ、Write Gateを一時的にオンにする運用もある。本連載では扱わないが、機能として存在することは覚えておく。

## MEMORY.mdとの使い分け

USER.mdとMEMORY.mdは似ているようで役割が違う。書く主役と中身を分けるとブレない。

| 場面 | どちらに書くか | 例 |
|---|---|---|
| 私の名前・好み・文体・主要環境 | USER.md | 「名前はそら」「文体は常体」「母艦はWindows 11」 |
| 固有名詞のパスやホスト | USER.md | 「VPSのホストはhermes-vps」「Vaultは`~/Documents/Obsidian Vault`」 |
| 運用中に分かった事実 | MEMORY.md | 「config.yamlのwebセクションはbackend: firecrawl」「Cronのprofileはdefault」 |
| 失敗から得た学び | MEMORY.md | 「DashboardのKey欄は平文保存になる→`op://`で扱う」(第11回) |
| 恒久的な決定 | MEMORY.md | 「ニュース要約は出典URLと取得状況を必ず付ける」(第9回morning-news) |

USER.mdは「先に渡しておく自己紹介」、MEMORY.mdは「一緒に働いて貯まる知見」。

### 私自身がUSER.mdを直接編集する

Telegram経由でなく、エディタで直接書いてもいい。エージェントが書くのと違って瞬時に反映できる(ただし**次セッションのfrozen snapshotから効く**)。

```bash
nano ~/.hermes/memories/USER.md
```

USER.mdの中身の書き方には決まった形がある。Hermesは「事実1行+その上下に`§`の区切り行」をエントリの単位として認識する。`§`は段落の境界記号で、エントリを増やすときは「`§`の行+次の行に事実1行」のセットで足していく。

![nanoエディタでUSER.mdを開いた画面。GNU nano 8.7.1のヘッダーの下に、§区切りで8項目(自己紹介3項目+好み3項目+趣味嗜好2項目)が日本語で並ぶ画面](/images/hermes-vps/hermes-vps-12-user-md-nano.png)

実際の内容はこんな並びになる。

```text
§
morning-newsスキルではx_searchを使う。Xのブックマーク整理はxurlを使う。両者を混ぜない。
§
応答は日本語が基本。他の言語が必要なときだけ明示的に頼む。
§
検索結果の提示は簡潔で構造化された形式が好み。一次ソースのURLだけをリスト化し、いいね数や冗長な説明は要らない。
§
名前はそら。
§
アラフィフの会社員。
§
妻と高校生の娘の3人家族。
§
好きな食べ物はカレー。
§
週末は娘とカラオケに行くことがある。
```

エージェントがTelegram経由で記憶した英語表記の項目を、ここで日本語に書き直しても構わない。事実が同じならフォーマットを揃える側のメリットの方が大きい(あとで`cat`して読み返しやすい)。

## 容量と整理

USER.md=1,375字、MEMORY.md=2,200字の上限がある。容量に近づくとエージェント自身がconsolidate(統合・要約)を行う。

### 文字数を見ながら回す

```bash
wc -m ~/.hermes/memories/USER.md
wc -m ~/.hermes/memories/MEMORY.md
```

目安として80%(USER.md=1,100字 / MEMORY.md=1,760字)を超えたら、Telegramで「USER.mdを整理して」と頼む。エージェントが古い項目を統合・短縮する。または、書き込み時に上限を超えるとエラーが返るので、その時点で自動的にconsolidateが走る設計になっている。エージェントは積極的に整理を強いられるわけだ。

容量超過に近づいたときの出口は2つある。

| 出口 | 方法 | 向く場面 |
|---|---|---|
| (a)畳む | Hermes自身にconsolidateさせる | 同じ話題の重複・古くなった事実の統合 |
| (b)逃がす | 知識をObsidian側に移す(第13回) | Web記事・論文・長文メモのような「メモリには収まらない知識」 |

USER.md/MEMORY.mdは「自分の前提と現場のメモ」に絞り、知識ベースは次回のObsidianに分ける、という棲み分けが基本になる。

### やり直したいときはreset

```bash
hermes memory reset        # MEMORY.md と USER.md を空に戻す
```

`reset`は取り消せない。事前にバックアップを取ってから実行する。

```bash
cp ~/.hermes/memories/USER.md   ~/USER.md.bak
cp ~/.hermes/memories/MEMORY.md ~/MEMORY.md.bak
```

## 翌セッションでfrozen snapshotを実感

記憶が本当に効いているかは、**翌日**(あるいは今のセッションを閉じて新しく始めたとき)に確かめる。

Telegramで新しいセッションを開いて、「私の名前は？」「私の年代は？」「私の家族構成は?」と短く3つ聞く。エージェントがUSER.mdから引いて即答すれば、frozen snapshotが効いている証拠だ。

![新しいTelegramセッションで3問3答。「私の名前は?」に「そら」、「私の年代は?」に「アラフィフ」、「私の家族構成は?」に「妻と高校生の娘の3人家族」とエージェントが即答している画面](/images/hermes-vps/hermes-vps-12-frozen-snapshot.png)

もし覚えていない応答が返ってきたら、原因は次のどれかだ。

- 書き込みが承認待ちで止まっている=`/memory pending`を確認
- 書いた直後で同セッション内のため未反映=新しいセッションを開く
- `config.yaml`の`memory:`節がエラー=`systemctl --user status hermes-gateway`でログ確認

3問が即答で返ってきたら、もう「私について毎回説明する」必要はない。Hermesは「私」を覚えている。

## 外部プロバイダ8つの概観

本回はbuilt-inで完結させた。記憶量が大きくなったり、チームで共有したり、ローカル完結したい場合は外部プロバイダを足せる。`hermes memory status`で並んでいた8つを概観する。

| provider | 種別 | 性格 |
|---|---|---|
| hindsight | API key / local | localモードあり・知識グラフ化 |
| holographic | local | 完全ローカル(API key不要) |
| byterover | requires API key | クラウド・dev向け |
| honcho | API key / local | クラウド・SDK系 |
| mem0 | API key / local | OSS・人気プロバイダ |
| openviking | API key / local | クラウド |
| retaindb | API key / local | クラウド |
| supermemory | requires API key | クラウド |

導入するなら`hermes memory setup`(インタラクティブ)で対話的に選ぶ。built-inに戻したくなったら`hermes memory off`。本連載では当面built-inのMEMORY.md/USER.mdで運用し、Obsidian Vaultを次回つなぐことで「外付けの脳」を別カテゴリで持つ方針を採る。

## 運用例──続かない日記をHermesに任せる

Memoryで自分の前提を持たせた。だが「自分の前提」は1日では書き切れない。本当は毎日少しずつ変わっている。それを書き留める習慣を持っている人はわずかだ。私もそうだった。

無料の日記アプリも何個か入れた。手帳に手書きもした。たいてい3日でアプリを開かなくなる。手帳は最初の1ページが詰まって、白いページが続く。「自分のことは自分にしかわからない」と頭ではわかっている。なのに書けない。眠いし、面倒だし、明日も同じことを思い出せる気がしてしまう。気がするだけで、1週間後にはぼやけていく。

第12回までで、USER.mdに「私のこと」を書く器ができた。frozen snapshotで毎セッション自動注入される。だがUSER.md自体は私が書かない限り増えない。3日で開かなくなるアプリと同じ運命をたどる。

ここで第9回のCronと本回のMemoryがつながる。毎晩22時、Hermesが3問を1通で送ってくる。Q1は今日の一面、Q2はその深掘り、Q3は明日への問い。布団の中で番号を返すだけ、正味30秒。歯磨きより軽い動作で、その日の私がUSER.mdに具体的なエピソードで1段落積み上がっていく。

### 仕組み

| 要素 | 値 |
|---|---|
| 発動 | VPSのCron `0 22 * * *`(第9回の`hermes cron add`そのもの) |
| 送信先 | 既存のHermes bot(朝のニュースbotとは別チャットにする) |
| 構造 | Q1+Q2+Q3を1通のメッセージで送信(1往復)。返信は任意のペースで番号を返す |
| 生成 | Hermes自身がUSER.md+過去30日の質問ログを読んで、その日の3問を動的生成。Q1=今日の一面 / Q2=Q1からの深掘り / Q3=明日への問い |
| 反映 | 私の返信→Hermes本体が`memory` tool→USER.md追記→翌朝のfrozen snapshotに乗る |

当初は「Q1を送って→回答を受けて→Q2/Q3を深掘り」の2往復で考えた。だがHermesのCron実行には、相手の返信を待ち受けて対話を続ける仕組みがない。そこで**3問を最初から1通にまとめて送り、私が番号で返す1往復**に落ち着いた。深掘りは「回答を待ってから分岐」ではなく「その日のUSER.mdと過去の質問履歴から、Q1→Q2→Q3が自然につながる3問をHermesがあらかじめ組み立てる」形で実現する。

### 1往復で完結する対話

22時、Hermesから3問が1通で届く。

```text
🌙 今夜の振り返り

おつかれさま、そら。今日も1日。寝る前に3問だけ。

📍 Q1  あ、これでよかったと思った瞬間
▸ 1 仕事がいつもより早く終わった
▸ 2 家族とゆっくり話せた
▸ 3 後回しにせず片付けた
▸ 4 早めに休めた
▸ 5 その他 自由記述

🔍 Q2  その瞬間にいちばん効いていた手
▸ 1 朝いちの段取り
▸ 2 連絡や依頼の置き方
▸ 3 やらないことを決めた
▸ 4 体を先に休ませた
▸ 5 その他 自由記述

💭 Q3  明日、最初に手をつけたいこと
▸ 1 重い1件を先に出す
▸ 2 メールや連絡を片付ける
▸ 3 体や生活側を整える
▸ 4 今日の続きを淡々と進める
▸ 5 その他 自由記述

返信は普通にこのbotへ。Hermesが読み取ってUSER.mdに少しずつ記憶していく。
```

![22時に届いた実際の3問。Cronjob Responseヘッダー+job_idの下に「今夜の振り返り」+Q1(今日、誰かと短く話した場面)/Q2(その場面で自然に動いた手や言葉)/Q3(明日も同じように話す場面で)が選択肢付きで並ぶTelegram画面](/images/hermes-vps/hermes-vps-12-evening-3questions.png)

毎晩の3問はUSER.md+過去30日の質問ログから動的に生成されるので、上のテキスト例と実機画像で問いの内容は異なる。同じ夜でも私と別の人では別の3問が届く。

布団の中で30秒、番号で答える。1問だけでも、全部スキップしても構わない。

```text
Q1: 2  夕飯のあと娘の進路の話を1時間
Q2: 3  口出ししたくなる癖を抑えて聞き手側に回れた
Q3: 1  明日朝いちで第14回の本文を仕上げる
```

Hermes本体は次に動いたタイミングで私の返信を通常のメッセージとして受け取り、`memory` toolで`~/.hermes/memories/USER.md`に「家族時間=娘の髪を乾かす時間に小さい頃を思い出した・心に残った」のような形で追記する。即時ではない。書き込みが完了するのは翌セッション開始時のfrozen snapshotからだ。

![そらの自由記述の返信(Q1 娘の髪を乾かしているとき / Q2 娘が小さいころを思い出して、ずっと頭をなでていたくなった / Q3 家族のちょっとした言葉や仕草を見落とさないように大切にしたい)の直下に、Hermesからの応答が並ぶTelegram画面。Hermesは返信内容を受け取り、温度のある一言で反応している](/images/hermes-vps/hermes-vps-12-evening-reflected.png)

実際のやり取りは番号で答えるだけでなく自由記述でも返せる。Hermesは返信を読み取り、その日のそらの一面を本文に反映してから翌朝のfrozen snapshotへ送る。翌朝の効果は§11(新しいセッションで「私は誰?」と聞く)の画面で既に示しているため再撮影は省略した。

### 3問の組み立て方

Hermesは22時にCronで起動した時点で、その日の3問をまとめて組み立てる。「Q1を聞いてから回答を見てQ2を考える」のではなく、**USER.mdの現在の人物像+過去30日の質問ログ**を読み、Q1→Q2→Q3が自然につながる3問を最初から1セットで作る。

| 問 | 役割 | 組み立ての観点 |
|---|---|---|
| Q1 | 今日の一面を取る | 「あ、これでよかった」「ふっと気が抜けた」など、その日の出来事を1つ選ばせる軽い問い |
| Q2 | Q1からの深掘り | Q1で出た場面の「効いた手」「重くなった理由」など、行動や原因の1段下に降りる問い |
| Q3 | 明日への問い | Q1Q2を統合し「明日最初に整えたいこと」「明日も続けたいこと」など未来軸の問い |

過去30日と重複しない角度を選ぶのもHermesの仕事だ。同じ「家族の話」テーマでも、前回が娘の進路相談なら今回は朝の会話のすれ違い、来週は週末の予定の合意の取り方、と角度をずらしていく。回答パターンも蓄積されるので、Q1で「3後回しにせず片付けた」が3週続いたら、Q2は「片付けた手の共通点」を聞きに行く=毎日の対話が層になって積み上がる。

### 翌朝・1週間後・1ヶ月後

翌朝のHermesは「昨日のそら」を覚えている。「昨日は娘の髪を乾かす時間に小さい頃を思い出して、心に残った一面があった、と覚えています」と前提を引いて記事相談に乗ってくる。

1週間後のHermesは「先週のそら」を引いてくる。「今週は家族の時間がBが多かったが先週は仕事の前進が多かった。何か変化があった?」と聞いてくる。

1ヶ月後のHermesは「この時期のそら」を要約できる。USER.mdが上限(1,375字)に近づいたら、Hermes自身がconsolidateで「そら像の月次要約」を作り、生データはMEMORY.md側の月次ログに送る。記憶が育っていく。

### 続かない自分の代わりに

ここまでで気づくと思う。Memoryは「便利機能」ではない。**続かない自分の代わりに記憶してくれる、相棒の本質**だ。日記アプリが続かない、手帳が続かない、振り返りが続かない、そのすべての「続かない」を、寝る前のタップ30秒の1往復に置き換える。それを続けるのは私ではなくHermesになる。

朝のニュース要約が「Hermesが世界を見る目」だとすれば、夜の振り返りは「Hermesが私を見る目」だ。第12回のMemoryは、この2つの目に共通の脳を作る。

## まとめと第13回予告

第12回でやったこと。

- `hermes memory --help`と`hermes memory status`でbuilt-inと8プロバイダの現状を把握
- Telegramで「私について次のことを覚えて」と1通送り、USER.mdに3項目が追記された
- Dashboardのセッションペインで「保存されたセッション」を確認
- VPSの`~/.hermes/memories/USER.md`を`cat`/`wc -m`で実体確認
- Write Gateの仕組みを知り、本連載ではoff(自動書込)で運用する方針を決めた
- USER.mdとMEMORY.mdの使い分け(自己紹介カードと現場のメモ帳)を整理
- `§`区切りでUSER.mdを直接編集する方法を確認
- 上限(USER.md 1,375字 / MEMORY.md 2,200字)が「整理を促す機能」であることを理解
- 容量超過時の2つの出口(畳む/逃がす)を把握
- 翌セッションで「私の名前は?」に即答が返り、frozen snapshotの効果を実感
- 外部プロバイダ8つの存在を地図として持った
- 「続かない日記」をHermes自身に任せる夜の振り返りの運用例を設計

これで、Hermes Agentは「私の前提を覚えている相棒」になった。毎回の自己紹介はもう要らない。

第13回は、Hermesに**外付けの脳**を持たせる回だ。USER.md+MEMORY.mdの上限は本回で見たとおり合計3,575字しかない。Web記事の保存、論文のメモ、自分用のナレッジ、過去の議事録──こうした「メモリには収まらない知識」をどこに置くか。

答えはObsidian Vaultだ。第13回ではHermesに公式のbundled `obsidian` skillを使わせて、VaultをHermes側から読み書きできるようにする。さらにそこへClaude CodeとCodexも同じVaultを共有する形で乗せていく(共有実装の手順は別回を予定している)。第12回までの「自分のこと」と、第13回からの「自分の知識」を両輪で持つことで、Hermesはようやく「自分専用のAI」と呼べる状態に育つ。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第11回 Hermes Agentに最新情報を自動取得させる方法](https://zenn.dev/sora_biz/articles/hermes-vps-11-web-search) | [第13回 Hermes AgentとObsidianを連携して知識を共有する方法](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## 補足:三層メモリの設計思想を改めて整理する

本回はUSER.md・MEMORY.md・SOUL.mdの三層+SQLite(state.db)+外部providerという整理で進めた。執筆の途中で見えてきた3つの設計判断を、補足として残しておく。

### 容量上限は制約ではなく機能

USER.md=1,375字、MEMORY.md=2,200字という上限を「窮屈」と感じる人は多い。だが上限が小さいことで「腐る情報を毎日選別する」判断を強いられる。容量が無制限なら、不要なメモまで残り続けてしまう。記憶が劣化していく。上限はバグではなく機能だと考えると運用が落ち着く。整理はあとからやるものではなく、毎回の書き込み時に行うものだ。

### save・skipの判断軸は「腐る情報かどうか」

「これは覚えさせるべきか」の判断はシンプルにできる。半年後にも役立つ情報か(=腐らない)?それともその場限りか(=腐る)?名前・所属・好み・繰り返し参照する数値は腐らない。今日の天気・一回限りのファイル名・即時の数値は腐る。腐らないものだけUSER.md・MEMORY.mdに残し、それ以外はObsidian Vault(第13回)へ逃がす。この軸を持つと、容量上限と上手に付き合える。

### 三層メモリ+Obsidianは別カテゴリで扱う

本連載は「Markdown(USER.md・MEMORY.md・SOUL.md)+SQLite(state.db)+外部provider」の三層+「Obsidian Vault(外付けの脳)」という構造で進めている。他の解説ではObsidianも含めて「4層」と数えることがある。どちらも同じ実体を指すが、本連載ではHermes内蔵のmemoryと外付けのObsidianを別カテゴリで明確に分けて扱う。第13回でObsidianに進むときも、この境界を意識すると整理が早い。

## よくあるエラーと対処

| 症状 | 原因 | 対処 |
|---|---|---|
| `Memory provider 'obsidian' not found.` | v0.17.0時点でも`obsidian`は公式memory providerではない | 第13回で扱うbundled `obsidian` skillを使う(memory providerではなくskill) |
| 新セッションで覚えていない | frozen snapshotの注入前に書き込んだ / 書き込みがpendingで止まっている / `config.yaml`にエラー | `/memory pending`を確認 / `systemctl --user restart hermes-gateway` / 新しいセッションを始める |
| `容量超過`のエラー | USER.md=1,375字 / MEMORY.md=2,200字を超えた | Telegramで「整理して」と頼んでconsolidateさせる / nanoで手動短縮 |
| `/memory approval on`が効かない | `config.yaml`の`memory:`節と競合している | `config.yaml`の`write_approval`を片方に絞り、gateway再起動 |
| `hermes memory reset`を誤実行した | resetは取り消せない | 事前バックアップ(`cp USER.md USER.md.bak`)から戻す |
| TelegramでUSER.mdの内容と違う前提で応答が返る | frozen snapshotがその日のセッション開始時点の値で凍っている | 新しいセッションを開く=次のfrozen snapshotで反映 |

## 操作早見表

```bash
# 状態確認
hermes memory --help
hermes memory status

# 実体を覗く
cat   ~/.hermes/memories/USER.md
cat   ~/.hermes/memories/MEMORY.md
wc -m ~/.hermes/memories/USER.md
wc -m ~/.hermes/memories/MEMORY.md

# 直接編集
nano  ~/.hermes/memories/USER.md
nano  ~/.hermes/memories/MEMORY.md

# Write Gate(承認制・任意)
# ~/.hermes/config.yaml に
#   memory:
#     write_approval: true
systemctl --user restart hermes-gateway
/memory approval on
/memory pending
/memory approve <id>
/memory reject  <id>

# やり直し(全消去・要バックアップ)
cp ~/.hermes/memories/USER.md   ~/USER.md.bak
cp ~/.hermes/memories/MEMORY.md ~/MEMORY.md.bak
hermes memory reset

# 外部プロバイダ(発展・本回では使わない)
hermes memory setup     # 対話的にプロバイダを選ぶ
hermes memory off       # built-inに戻す
```

## 引用元と参考

| 項目 | 引用元 |
|---|---|
| 組み込みmemory全般(USER.md / MEMORY.md / frozen snapshot / memory tool / Write Gate) | [memory](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory) |
| 外部プロバイダ8つの仕様 | [memory-providers](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory-providers) |
| Hermes Architecture(メモリ三層の俯瞰) | [HuggingFace公式動画「Hermes Architecture EXPLAINED: Memory, Context & Gateways」§コンテキスト(7:31〜)+§メモリ(28:00〜)](https://www.youtube.com/watch?v=n32qq7Kwzh0)(2026-06-16公開・約40分・英語・自動翻訳字幕で日本語可) |
| memory toolのbatch operations追加(2026-06-18) | [PR #48507](https://github.com/NousResearch/hermes-agent/pull/48507) |
| Memoryアーキテクチャの実装者視点(参考) | [Tonbi (@tonbistudio) Hermes Agent Masterclass Module 3: Memory, Plugins, Honcho, Obsidian](https://www.youtube.com/watch?v=ZKZLko9kLm4)(2026-05-18公開・約34分・英語・自動翻訳字幕で日本語可) |
| 続かない日記をHermesに任せる運用(参考) | [MGT_maccha (@MGT_maccha) X Article『AIに読ませるObsidianノートの作り方』](https://x.com/MGT_maccha/status/2067940523986534409) |

<!-- 2026-06-19ドラフト初版 -->
