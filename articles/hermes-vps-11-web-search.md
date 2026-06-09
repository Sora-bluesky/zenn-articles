---
title: "【第11回】Hermes Agentが最新情報を自分で取りに行く──Web検索とX検索を使い分ける"
emoji: "🔎"
type: "tech"
topics: ["ai", "hermes", "searxng", "firecrawl", "vps"]
published: false
---

## 目次

- [この回の到達点](#この回の到達点)
- [なぜWebとXを分けて考えるのか](#なぜwebとxを分けて考えるのか)
- [この回で出てくる言葉](#この回で出てくる言葉)
- [第11回終了時点の構成図](#第11回終了時点の構成図)
- [8つのバックエンドから2つを選ぶ](#8つのバックエンドから2つを選ぶ)
- [SearXNGで自前の検索エンジンを持つ](#searxngで自前の検索エンジンを持つ)
- [Firecrawlで難しいページの本文を取る](#firecrawlで難しいページの本文を取る)
- [検索先の優先順位を押さえる](#検索先の優先順位を押さえる)
- [検索とextractが効くか確かめる](#検索とextractが効くか確かめる)
- [Xでの議論を拾う(数値は出させない)](#xでの議論を拾う(数値は出させない))
- [morning-news Skillをハイブリッド検索に育てる](#morning-news-skillをハイブリッド検索に育てる)
- [まとめと第12回予告](#まとめと第12回予告)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [公式ドキュメント引用元](#公式ドキュメント引用元)

第10回でmorning-news Skillを作ったとき、毎朝のニュース要約に一文が混じっていた。「X検索は利用不可だったため、HN/Web中心で代替しました」。エージェントは正直に、使えなかった道具を申告していた。

検索の質は、Skillの出力をそのまま左右する。第10回までのHermes Agentは「決まった時刻に、覚えた手順で動く」ところまで来たが、その手順が見にいく情報源がまだ整っていない。第11回は、Hermes Agentが使える複数の検索バックエンドを整理し、**Web検索**と**X検索**を別の道具として有効化する。

シリーズの全体像はこちら。

- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy)──VPSを契約して最小限の安全な状態でadminにログイン
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale)──Tailscaleで公開SSHを閉じる
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password)──1Password Service Accountと`op run`でsecrets管理
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install)──DockerサンドボックスとHermes Agentのインストール+Codex OAuth+Telegram疎通
- 第5回──Grok OAuthとDiscordを足す+承認モードの確認
- 第6回──systemd常駐化で24時間動かす
- 第7回──公式アプリ「Hermes Desktop」でマウス操作する
- 第8回──Hermes Agentをブラウザの管制室から操る──Web Dashboardで設定を見える化する
- 第9回──Cronで毎朝の定型タスクを任せる
- 第10回──Skillsに手順を覚えさせる
- **第11回**(本記事)──Web/X検索の使い分け(SearXNG+Firecrawl+X Search)
- 第12回──家の余ったPCをLinux常駐GPUサーバーにする(VPSの手足)

手を動かすのは、VPSにSSHでつないでDockerで検索エンジンを1つ立て、APIキーを1つ取り、設定を3行書き換えるだけ。難しいプログラミングは出てこない。

## この回の到達点

第10回完了時と第11回完了後の差分を表にする。

| 項目 | 第10回完了時 | 第11回完了後 |
|---|---|---|
| Web検索 | 既定のキーレス検索だけ(質が安定しない) | **SearXNGを自前で持ち、回数を気にせず検索** |
| サイト本文の取得 | 手段が定まっていない | **Firecrawlを難しいページ用に確保** |
| X(旧Twitter)の話題 | 「利用不可」で代替されていた | **x_searchで議論と投稿URLを拾う** |
| 設定の考え方 | 1つのbackendだけ意識 | **機能別に検索先を切り替える優先順位を理解** |

一言でまとめると「検索という名前で一括りにしていたものを、Web検索・本文取得・X検索の3つに分け、それぞれに合った道具を割り当てる」回だ。

## なぜWebとXを分けて考えるのか

「検索して」と頼むと、つい1つの機能だと思ってしまう。だが中身は性質の違う3つの作業に分かれている。

- **Web検索**:キーワードから記事やドキュメントのURL一覧を引く。ニュースや技術情報の入口
- **本文取得**(extract):見つけたURLを開いて中身のテキストを取り出す。要約の材料
- **X検索**:Xでの人の反応・速報を拾う。「世間がどう受け止めたか」が分かる

ここで大事なのは、**Xの情報をWeb検索で取りにいかない**ことだ。公開Web検索でXを覗くと、投稿は拾えても「いいね数」「リポスト数」のような数値は正確に取れない。それでも数値を求めると、エージェントは取得できない数字を埋めようとする。後で実機で確かめるが、実際に頼むと「概算」と添えて、根拠のない数値を出してきた。

だからこの回では、Webは検索専用の道具(SearXNG)で、本文取得は別の道具(Firecrawl)で、Xは専用のX検索で拾う。そしてX検索では**数値を一切求めない**。これが捏造を防ぐ唯一の確実な方法だ。

## この回で出てくる言葉

| 用語 | 意味 | たとえ |
|---|---|---|
| SearXNG | 自分のサーバーに立てる検索エンジン(メタ検索) | 自宅に置く検索窓。回数制限なく使える |
| Firecrawl | URLの本文を整形して取り出す外部サービス | 散らかったページを読みやすく清書する係 |
| backend | 検索や本文取得を実際に担う「業者」の指定 | 配送を頼む運送会社の選択 |
| search_backend | 検索を担当する業者(機能別の指定) | 「検索はこの会社」と名指しする欄 |
| extract_backend | 本文取得を担当する業者(機能別の指定) | 「本文取りはこの会社」と名指しする欄 |
| x_search | XをGrok経由で検索し、議論の要約と投稿URLを返す道具 | Xの話題を聞ける窓口。数値は返さない |
| xai-oauth | 第5回で通したGrokのログイン。x_searchを動かす土台 | x_searchの電源 |

## 第11回終了時点の構成図

検索の3機能が、それぞれ別の業者に割り当てられる。Web検索は同じVPS上に立てたSearXNG、本文取得はFirecrawl、X検索はGrok経由のx_searchだ。

```text
┌─────────────────────────────────────────────────────┐
│  VPS(常駐中のHermes Agent)                            │
│                                                     │
│   検索の依頼 ──┬─ Web検索   → SearXNG(同じVPSの中)   │
│               │   (search_backend)  Dockerで自己ホスト │
│               │                                     │
│               ├─ 本文取得  → Firecrawl(外部API)     │
│               │   (extract_backend) 難しいページ用    │
│               │                                     │
│               └─ X検索     → x_search(Grok経由)      │
│                   xai-oauth(第5回)が土台。数値は返さない │
└─────────────────────────────────────────────────────┘
```

ポイントは、3つを別々に持てること。Web検索は自己ホストで無料枠を気にせず使えるSearXNGに任せ、有料枠のあるFirecrawlは「素のページでは歯が立たない難しいサイト」だけに温存できる。

## 8つのバックエンドから2つを選ぶ

Hermes Agentは8種類の検索バックエンドに対応している。まず現状を見ておく。

```bash
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps
hermes version                                  # v0.15.1 を確認
cat ~/.hermes/config.yaml | grep -A 4 "web:"    # 今の web: セクション
```

![cat config.yamlのweb:セクション。backend: ddgsで、search_backend/extract_backendが空の初期状態](/images/hermes-vps/hermes-vps-11-config-web-before.png)

8つの内訳はこうなっている。

| バックエンド | 検索 | 本文取得 | 無料枠 | 向き |
|---|---|---|---|---|
| Firecrawl(デフォルト) | ✓ | ✓ | 1,000/月 | 総合。ただし無料枠の消費が早い |
| SearXNG | ✓ | ✗ | 無制限(自己ホスト) | 検索特化、無料運用 |
| Brave Search | ✓ | ✗ | 2,000/月 | 検索強化、無料枠多め |
| DDGS(DuckDuckGo) | ✓ | ✗ | 無制限 | キー不要のフォールバック |
| Tavily | ✓ | ✓ | 1,000/月 | AI最適化検索 |
| Exa | ✓ | ✓ | 1,000/月 | セマンティック検索 |
| Parallel | ✓ | ✓ | 有料 | 並列大量検索 |
| xAI | ✓ | ✗ | 有料 | GrokのWeb検索(X Searchとは別物) |

表の「デフォルト」はコード上の既定がFirecrawlという意味で、利用にはAPIキーが要る。そのためキー未設定の初期状態では、キー不要のDDGSが既定値として入っている(実機のbackendもddgsになっている)。どちらにしても、このあと検索先を自分で指定し直すので気にしなくてよい。

このシリーズでは**SearXNG**(検索)と**Firecrawl**(本文取得)を組み合わせる。理由はシンプルで、検索は回数を気にせず使いたいから自己ホストのSearXNG、本文取得は質の高いFirecrawlを「ここぞ」という難しいページだけに使う、という役割分担にすると無料枠を長く保てる。

用途で道具を選ぶと質が上がる。キーワードから意味の近い結果が欲しいときは**Exa**(セマンティック検索)、JavaScriptで描画される重いページの本文取得は**Firecrawl**が向く。本シリーズはSearXNG+Firecrawlの2つで十分で、用途が増えたら表の他のbackendも候補になる(ブラウザを直接操作する高度な用途では低レベルのBrowser CDPという別系統の手もあるが、検索用途では不要)。

:::message
表の一番下の**xAI**は、GrokによるWeb検索であってX検索(x_search)とは別物だ。Xでの議論を拾いたいときに使うのは、この回の後半で扱う`x_search`のほう。混同しないよう注意する。
:::

## SearXNGで自前の検索エンジンを持つ

SearXNGは、自分のサーバーに立てる検索エンジンだ。GoogleやBingなど複数の検索結果をまとめて返す「メタ検索」で、自前APIキーや課金枠が要らず、検索語が外部のAPI業者に渡らない(上流の検索エンジン側の制限・ブロックはあり得る)。第4回で入れたDockerの上に1コンテナ立てるだけで動く。

### 置き場所を作って設定ファイルを書く

```bash
mkdir -p ~/searxng/searxng
cd ~/searxng
nano docker-compose.yml
```

![mkdirで~/searxngを作り、nanoでdocker-compose.ymlを開いた直後の画面](/images/hermes-vps/hermes-vps-11-searxng-compose-edit.png)

`docker-compose.yml`には最小構成を書く。外向きにポートを開かず、`127.0.0.1`(自分のVPSの中)だけに見せるのが安全面の肝だ。

```yaml
services:
  searxng:
    image: searxng/searxng:latest
    ports:
      - "127.0.0.1:8888:8080"
    volumes:
      - ./searxng:/etc/searxng
    environment:
      - BASE_URL=http://localhost:8888/
      - INSTANCE_NAME=hermes-searxng
    restart: unless-stopped
```

![保存後のdocker-compose.ymlの中身。127.0.0.1:8888へのポート割り当てが見える画面](/images/hermes-vps/hermes-vps-11-searxng-compose-saved.png)

### JSON出力を有効にする(必須)

ここが見落としやすい。SearXNGは初期状態だと人間向けのHTMLしか返さない。Hermes AgentはJSONで結果を受け取るので、`settings.yml`で`json`形式を明示的に許可する。これを忘れると、検索しても結果が取れない。

```bash
cat > ~/searxng/searxng/settings.yml <<EOF
use_default_settings: true
search:
  formats:
    - html
    - json
server:
  secret_key: "$(openssl rand -hex 32)"
EOF
```

![保存後のsettings.ymlの中身。formatsにhtmlとjsonが並んでいる画面](/images/hermes-vps/hermes-vps-11-searxng-settings.png)

### 起動して動作を確かめる

```bash
cd ~/searxng
docker compose up -d
docker compose logs --tail=30
curl -s "http://localhost:8888/search?q=test&format=json" | head -50
```

![docker compose up -d実行直後。イメージのpullとコンテナ起動のログが流れている画面](/images/hermes-vps/hermes-vps-11-searxng-up.png)

![docker compose psでsearxngがUp状態になっている画面](/images/hermes-vps/hermes-vps-11-searxng-ps.png)

最後の`curl`でJSONが返ってくれば、検索エンジンとして動いている。これがHermes Agentから叩く先になる。

![curlでlocalhost:8888にJSON形式の検索リクエストを送り、JSON応答が返ってきた画面](/images/hermes-vps/hermes-vps-11-searxng-curl-json.png)

## Firecrawlで難しいページの本文を取る

SearXNGは検索(URL一覧)はできるが、ページの**本文取得**はできない。そこをFirecrawlに任せる。

ただし誤解しないでおきたいのは、本文取得のすべてをFirecrawlがやるわけではない、という点だ。素のHTMLページなら、エージェントは自分で`curl`を使って読んでしまう。Firecrawlが本領を発揮するのは、JavaScriptで描画されるページや、HTMLが汚れていて読みやすいテキストに整形しないと使えない複雑なページだ。だからFirecrawlは「難しいページ用の保険」と考えると、無料枠の消費を抑えられる。

### APIキーを取って保管庫に入れる

[Firecrawl](https://www.firecrawl.dev/)にサインアップする。無料枠は月1,000クレジットで、これは難しいページの本文取得に絞れば個人利用で十分に保つ量だ。

![Firecrawlのサインアップ画面](/images/hermes-vps/hermes-vps-11-firecrawl-signup.png)

![Firecrawlダッシュボードのトップ。無料枠1,000/月の表示が見える画面](/images/hermes-vps/hermes-vps-11-firecrawl-dashboard.png)

ダッシュボードでAPIキー(`fc-`で始まる文字列)を発行する。

![APIキー発行画面。fc-で始まるキーが表示された画面](/images/hermes-vps/hermes-vps-11-firecrawl-apikey.png)

このキーは第3回と同じ作法で扱う。コードや設定ファイルに直接書かず、1Passwordの**保管庫**(英語UIではVault)にアイテムを作って保存し、参照だけを使う。第3回で作った保管庫`Hermes-Prod`に「Firecrawl」というアイテムを足し、APIキーを**認証情報**フィールド(英語UIではcredential)に入れておく。

![1Passwordの保管庫Hermes-Prodに新規アイテム「Firecrawl」を作りAPIキーを保存した画面](/images/hermes-vps/hermes-vps-11-firecrawl-1password.png)

## 検索先の優先順位を押さえる

道具がそろったので、Hermes Agentに「Web検索はSearXNG、本文取得はFirecrawl」と教える。ここで設定の**優先順位**を理解しておくと、後で混乱しない。

Hermes Agentは検索先をこの順で決める。

1. `web.search_backend` / `web.extract_backend`(機能別の指定。最優先)
2. `web.backend`(機能別が空のときの共有フォールバック)
3. 環境変数からの自動検出

つまり機能別の指定があれば、それが`web.backend`より優先される。そして覚えておきたい落とし穴がひとつ──設定できるのは**検索**と**本文取得**の2つだけで、`crawl_backend`(サイト巡回)のようなキーは存在しない。あると思って書いても無視される。

### secrets.envに参照を足す

```bash
nano ~/.hermes/secrets.env
```

```bash
FIRECRAWL_API_KEY=op://Hermes-Prod/Firecrawl/credential
SEARXNG_URL=http://localhost:8888
```

`FIRECRAWL_API_KEY`は1Passwordの参照(`op://`)で書く。`SEARXNG_URL`はさっき立てたコンテナの宛先だ。

![secrets.envにFIRECRAWL_API_KEY=op://...とSEARXNG_URL=...を追記した画面](/images/hermes-vps/hermes-vps-11-secrets-env.png)

### config.yamlのweb:セクションを書き換える

`config.yaml`にはすでに`web:`セクションがある。新しく足すのではなく、空だった2つの欄を埋める。

```bash
nano ~/.hermes/config.yaml
```

```yaml
web:
  backend: ddgs                 # 機能別が空のときのフォールバック
  search_backend: "searxng"     # ← '' から "searxng" に書き換えた
  extract_backend: "firecrawl"  # ← '' から "firecrawl" に書き換えた
  use_gateway: false
  # crawl_backend は存在しない(設定できるのは search と extract のみ)
```

![config.yamlのweb:セクションにsearch_backend: searxngとextract_backend: firecrawlが入った画面](/images/hermes-vps/hermes-vps-11-config-backend.png)

### 再起動して反映する

第6回でsystemd常駐化し、`op run`経由で起動しているので、サービスを再起動すれば`op://`参照が実際のキーに展開されて反映される。

```bash
systemctl --user restart hermes-gateway
systemctl --user is-active hermes-gateway        # active が返れば再起動成功
```

![systemctl --user is-active hermes-gatewayがactiveと返った画面(再起動成功の確認)](/images/hermes-vps/hermes-vps-11-gateway-restart.png)

## 検索とextractが効くか確かめる

Telegramからbotに頼んで、実際に検索が通るか見る。

```text
「systemdとは何か」を簡潔に検索して、3つの一次情報URLを並べて教えて
```

![Telegramで検索を依頼し、3件以上のURLと一行要約が返ってきた画面](/images/hermes-vps/hermes-vps-11-telegram-search.png)

URLが返ってきたら、それが本当にSearXNG経由かを確かめておく。VPS側でSearXNGのログを見ると、いま投げたクエリが処理された記録が残っている。設定が効いている動かぬ証拠だ。

```bash
cd ~/searxng && docker compose logs --tail=20
```

![docker compose logsにSearXNGがクエリを処理したログが出ている画面。gatewayからsearxngが使われた実証](/images/hermes-vps/hermes-vps-11-searxng-log.png)

本文取得も試す。URLを指定して中身を抜き出してもらう。

```text
https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html の主要セクション見出しだけ抜き出して
```

このページは素のHTMLなので、エージェントは`curl`で取得して見出しを返してくる。Firecrawlは温存されたままだ。手段はエージェントが状況で選ぶ。

![Telegramで本文取得を依頼し、ページの見出し一覧が返ってきた画面。今回はcurl経由で手段はエージェント判断](/images/hermes-vps/hermes-vps-11-telegram-extract.png)

## Xでの議論を拾う(数値は出させない)

ここからがこの回の山場だ。Web検索とは別に、Xでの反応を拾う`x_search`を使う。

`x_search`は第5回で通した`xai-oauth`(GrokのOAuthログイン)を土台に動く。だから追加の認証はいらない。状態は`hermes doctor`で数行で確認できる。`hermes tools`という対話メニューは画面が固まりやすいので、確認には使わない。

```bash
hermes auth list                                     # xai-oauth があるか
hermes doctor 2>&1 | grep -iE "xai oauth|x_search"   # ✓ が出れば有効
```

![hermes doctorの出力に✓ xAI OAuth (logged in)と✓ x_searchが並び、config.yamlのx_searchセクションも見える画面](/images/hermes-vps/hermes-vps-11-doctor-xsearch.png)

### 数値を求めない、が鉄則

`x_search`が返すのは、**Xでの議論の要約**と、その根拠になった**投稿のURL**が中心だ。いいね数・リポスト数・閲覧数のような数値は返さない(公式の仕様では、返ってくるのは要約と引用URL等であって、いいね数のような数値フィールドは無い)。

ところがここで「いいねが多い順に」などと数値を頼むと、エージェントは取得できない数値を埋めようとする。実際に試したときは、取れないはずの数字を「概算」と添えて出してきた。これは根拠のない捏造だ。

防ぐ方法はひとつ、**数値を一切求めない**こと。議論の中身と投稿URLだけを頼む。

```text
x_searchを使って、Hermes Agent(NousResearch)についてXで最近どんな
反応・議論があるか、代表的な投稿URLを3〜5件つけて教えて。
いいね数などの数値は付けず、議論の内容とURLだけで。
```

![x_searchでXの議論・反応の要約と投稿URLが返ってきた画面。いいね/RT等の数値は出ていない](/images/hermes-vps/hermes-vps-11-xsearch-result.png)

返ってきた投稿URLは、クリックすれば実在のX投稿に飛ぶ。もし出力に数値が混じったら、それは捏造なので採用せず、依頼文から数値の要求を消して頼み直す。

:::message
**Xに触れる道は3つあり、混同しない**

- **xai-oauth → x_search**(この記事):Grokが議論を要約し、根拠の投稿URLを返す。数値は返さない
- **xurl**(X開発者API):いいね数など正確な数値や特定アカウントのtimeline、自分のブックマークが要るときに使う。別途X APIの認証が必要で、本記事では使わない。xurlを認証して自分のブックマークを整理する活用は、この先の回で扱う
- **web_search**(公開Web検索):Xを覗くことはできるが正確な数値は取れない。Xの数値目的では使わない

「正確な数値が欲しい」と思ったら、それは`x_search`の役割ではなく`xurl`の領分だと切り分ける。ここで`x_search`に数値を求めないのは、機能の境界を守ることでもある。
:::

X検索がどうしても安定しない場合(第5回で触れた[Issue #26847](https://github.com/NousResearch/hermes-agent/issues/26847)のように、OAuthが弾かれることがある)は、無理に使わずWeb検索(SearXNG)中心で確定してよい。X検索は「あれば人の反応も拾える」加点要素だ。

## morning-news Skillをハイブリッド検索に育てる

最後に、第10回で作ったmorning-news Skillを、いまそろえた検索前提に書き換える。第10回の手順は「Hacker News上位・ArXiv新着・Xで最近話題の投稿」をまとめて取りに行く形で、検索の役割分担が曖昧だった。これをWeb検索とX検索に切り分け、末尾に取得状況を必ず残す形へ全文を入れ替える。

```bash
nano ~/.hermes/skills/morning-news/SKILL.md
```

手順(Procedure)を、検索の3機能に対応させ、**数値を一切出さない**形にする。

```text
## Procedure
1. **Web検索(SearXNG)**で過去24時間のAI関連記事のURL一覧を取得
2. 上位3〜5件の本文を取得し(エージェントがextractを選ぶ)、内容を確認
3. **x_search**でXでの議論・反応を取得して加える。根拠にしたX投稿のURL(x.com/…/status/…)を必ず添える。数値は付けない
4. Web側とX側を統合し、合計5項目に絞る
5. 各項目を2行で要約し、出典URLを末尾に付ける
6. 末尾に「取得状況」を必ず付ける(Web検索・本文取得・X検索を、使用/未使用で)

## Pitfalls
- いいね/RT等の数値は出さない(x_searchは数値を返さないため、書くと捏造になる)
- x_searchが無効・403の日はWebだけで5項目を埋め、取得状況に「X検索: 未使用」と正直に書く
- 「X検索: 使用(x_search)」と書くのは、X投稿URLを本文に載せたときだけ
- 手動cron実行の直後はmessage_countが0のまま見えることがある。完了を待ってから、本文・x_searchの呼び出し・取得状況の整合を確認する

## References
- references/x-search-output-consistency.md: X投稿URLと取得状況を照合する検証手順
```

![更新後のSKILL.md全文。手順にSearXNG・本文取得・x_searchが並び、末尾の取得状況と、X投稿URLを必ず添える注記が見える画面](/images/hermes-vps/hermes-vps-11-skill-updated.png)

中身を書き換えるだけなので`/reload_skills`は不要だ。Telegramから`/morning_news`(アンダースコア)で呼ぶ。

ここで効いてくるのが、末尾の「取得状況」だ。`x_search`が使えた朝は、X投稿のURL(`x.com/…/status/…`)が本文に並び、取得状況に「X検索: 使用(x_search)」と出る。逆に`x_search`に届かなかった朝は、エージェントがWebだけで記事を埋め、「X検索: 未使用」と正直に書く。**取得状況と本文がいつも一致するので、X検索が本当に効いた朝なのかを、ひと目で確かめられる**。数値さえ求めなければ、エージェントは無理に数字を作らず、できたこととできなかったことをそのまま残す。

この「投稿URLと取得状況の照合」は、SKILL.mdの末尾にReferencesとして書いた検証手順(`references/x-search-output-consistency.md`)に切り出してある。skillは本体から`references/`のファイルを参照でき、手順が増えても本体を短いまま保てる。

![Telegramで/morning_newsを送り、記事URLとX投稿URLのハイブリッド結果が届いた画面。末尾の取得状況に「X検索: 使用(x_search)」と出て、本文のX投稿URLと一致している](/images/hermes-vps/hermes-vps-11-morning-news-hybrid.png)

第9回で作ったCronジョブはこのSkillを添付済みなので、翌朝7時の自動配信も新しい手順で動く。手順を直したいときは、これからもSKILL.mdの1箇所を直すだけでいい。

## まとめと第12回予告

第11回でやったこと。

- 8つの検索バックエンドから、自己ホストで無料枠を気にせず使える**SearXNG**(検索)と**Firecrawl**(難しいページの本文取得)を選んで組み合わせた
- SearXNGをDockerで自己ホストし、`json`出力を有効にしてHermes Agentから使えるようにした
- `search_backend` / `extract_backend`を機能別に指定し、`web.backend`より優先される順位を理解した(`crawl_backend`は存在しない)
- `xai-oauth`を土台に`x_search`でXの議論と投稿URLを拾い、**数値は一切求めない**ことで捏造を防いだ
- morning-news Skillを、X投稿URLと末尾の「取得状況」を必ず残す形に書き換え、X検索が効いた朝もダメな朝も、本文と取得状況がいつも一致するようにした

これで、VPSのHermes Agentは「最新情報を自分で取りに行く」目を持った。決まった時刻に動き(第9回)、覚えた手順で(第10回)、必要な情報を自分で検索して(第11回)要約を届ける。

第12回は、この「思考と検索の拠点」に手足を足す。画像生成や大量バッチ、GPU推論はVPSのCPUでは荷が重い。そこで家の余ったPCをLinuxに換装し、24時間つながる常駐GPUサーバーにする。VPSはTailscale経由でその機械に重い計算を任せる——常に起きている受付がVPS、重い処理担当が自宅GPU機、という分担をHermes Agentがつなぐ形だ。

---

| ← 前の回 | 次の回 → |
|---|---|
| 第10回 Skillsに手順を覚えさせる | 第12回 自宅PCをGPUサーバーにする(近日公開) |

📑 [シリーズ全12回のもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## よくあるエラーと対処

| 症状 | 対処 |
|---|---|
| `curl`でSearXNGがJSONを返さない | `settings.yml`の`formats`に`json`を入れたか確認。直したら`docker compose restart`でコンテナを再起動 |
| 検索を頼んでもURLが返らない | 1) `search_backend: "searxng"`になっているか、2) `SEARXNG_URL`が`secrets.env`にあるか、3) `docker compose ps`でコンテナがUpか |
| Firecrawlが`402`やクレジット切れ | 無料枠(月1,000)を使い切っている。本文取得を多用しない。素のページはエージェントが`curl`で足りる |
| `x_search`が`403`で失敗する | 第5回で触れた[Issue #26847](https://github.com/NousResearch/hermes-agent/issues/26847)(OAuthが弾かれる)の可能性。Web検索中心で確定してよい |
| 出力にいいね/RT等の数値が出た | それは捏造。依頼文から数値の要求を消す。`x_search`は数値を返さない |
| エージェントが`x_search`でなく公開Web検索でXを覗く | `x_search`を名指しで頼み直す。それでも公開検索になる場合は、出力にその旨が正直に書かれる |

## 公式ドキュメント引用元

| 項目 | 引用元 |
|---|---|
| Web検索バックエンドの一覧(8種) | [features/web-search](https://hermes-agent.nousresearch.com/docs/user-guide/features/web-search)「Backends」 |
| backendの優先順位(機能別 > 共有 > 自動検出) | 同上「Per-capability configuration」 |
| X Search(`x_search`)の仕様・自動有効化 | [features/x-search](https://hermes-agent.nousresearch.com/docs/user-guide/features/x-search) |
| `x_search`の返り値は要約(`answer`)と引用URL(`citations`)が中心(他に`inline_citations`/`degraded`等の項目あり。いいね・リポスト等の数値フィールドは無い) | 同上「Tool parameters」 |
| SearXNGの`settings.yml`(`formats`にjson) | [SearXNG公式](https://docs.searxng.org/) |
| Firecrawlの無料枠(月1,000) | [Firecrawl公式](https://www.firecrawl.dev/) |
| `search_backend`/`extract_backend`・`crawl_backend`不在・8バックエンド | 実機v0.15.1で確認(2026-06-01)。`config.yaml` / `hermes doctor` / `docker compose logs` |
