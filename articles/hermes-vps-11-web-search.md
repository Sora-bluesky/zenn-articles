---
title: "【第11回】Hermes Agentに最新情報を自動取得させる方法"
emoji: "🔎"
type: "tech"
topics: ["ai", "hermes", "firecrawl", "tavily", "vps"]
published: true
---

## 目次

- [概念整理──なぜWebとXを分けるか](#概念整理──なぜwebとxを分けるか)
- [事前準備](#事前準備)
- [検索と本文抽出の考え方──このシリーズの選択](#検索と本文抽出の考え方──このシリーズの選択)
- [FirecrawlのAPIキーを取得して1Passwordに入れる](#firecrawlのapiキーを取得して1passwordに入れる)
- [secrets.envとconfig.yamlで設定を反映](#secrets.envとconfig.yamlで設定を反映)
- [動作確認──検索と本文抽出が効くか](#動作確認──検索と本文抽出が効くか)
- [無料枠を使い切ったらTavilyに切り替える──web-failover skillで自動化](#無料枠を使い切ったらtavilyに切り替える──web-failover-skillで自動化)
- [X Searchの設定──hermes doctorの落とし穴と--platform telegramの罠](#x-searchの設定──hermes-doctorの落とし穴と--platform-telegramの罠)
- [morning-news Skillをハイブリッド検索に育てる](#morning-news-skillをハイブリッド検索に育てる)
- [最終確認チェックリスト(第11回)](#最終確認チェックリスト(第11回))
- [まとめ](#まとめ)
- [実検証コラム──SearXNG自己ホストの罠](#実検証コラム──searxng自己ホストの罠)
- [もっと自由にやりたい人へ(自己ホスト抽出)](#もっと自由にやりたい人へ(自己ホスト抽出))
- [よくあるエラーと対処](#よくあるエラーと対処)
- [コマンド早見表](#コマンド早見表)
- [引用元と参考](#引用元と参考)

第10回で、Hermes Agentに「自分専用の手順」を覚えさせるところまで来た。`~/.hermes/skills/`に置いた`SKILL.md`を、Telegramからも毎朝のCronからも同じ口で呼べる状態だ。

ただ、ここで一つ問題が残る。スキルがどれだけ整っていても、検索の質が悪ければ、要約も提案も浅いままになる。第9回の`morning-news`が朝の話題を5項目並べてくれても、その元になるURLが古かったり的外れだったりすれば、出力は雑談以下になる。

第11回はそこを直す回だ。Hermes Agentの検索を「Web(過去のページ)」と「X(リアルタイムの会話)」の2系統に分け、それぞれに必要な道具を入れる。本シリーズの推奨は**公式デフォルトのFirecrawlを本線にする**。無料枠(500クレジット/月)を使い切ったらTavily(1,200クレジット/月)に切り替えられる構成にする。XのほうはGrok経由で議論を拾い、いいね数などの数値は一切扱わない。

そして今回の山場は、Firecrawlの無料枠を実際に使い切ったときに起きる。402 Insufficient creditsで止まった検索を、第10回で書いたskillが自動で拾い、Tavily切替のランブックを提示する。手で慌てて設定を直すのではなく、エージェントが自分で運用を引き継ぐ。これが「使うほど自分専用に育つ」の到達点になる。

途中で、SearXNGを自己ホストして完全無料の検索を作ろうとした検証も挟む。結論から書くと、これは記事末尾のコラムに降ろした。実機で動かすと主要engine(duckduckgo・wikipedia・brave)が軒並みbot対策で止まる事実を確認したからだ。一次情報として証拠ログまで残す。

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
- **第11回**(本記事) Hermes Agentに最新情報を自動取得させる方法

**第IV部 記憶を分けて育てる**
- [第12回](https://zenn.dev/sora_biz/articles/hermes-vps-12-memory) Hermes AgentにMemoryで好みと前提を記憶させる
- [第13回](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) Hermes AgentとObsidianを連携して知識を共有する方法
- [第14回](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) Hermes Agentに過去の会話を自動で復元させる
- [第15回](https://zenn.dev/sora_biz/articles/hermes-vps-15-import-ai-sessions) Hermes AgentにClaude CodeやCodexの作業履歴を取り込む方法

全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

## 概念整理──なぜWebとXを分けるか

最初に、この回で起きることを言葉にしておく。

Web検索は「過去のページから情報を拾う」もの。X Searchは「リアルタイムの会話から空気を拾う」もの。両方を分けて持っていると、ニュース要約のときに「事実(Web)+人の反応(X)」が一つの応答に揃う。さらにWeb側は「検索(URL探し)」と「抽出(本文取り)」に分かれる。同じbackendで両方をまかなえる構成にしておけば、設定は`config.yaml`の1行で済む。

### 第10回までの到達点と第11回の差分

第10回完了時と第11回完了後で、何がどう変わるかを表にする。

| 項目 | 第10回完了時 | 第11回完了後 |
|---|---|---|
| Web検索 | 第4回setupでデフォルト(DDGS等)のまま | Firecrawl(default・検索と本文抽出の両対応・500クレジット/月)が本線 |
| Web抽出 | 未設定 or デフォルト | 同じくFirecrawl。1つのbackendで検索も本文抽出も済む |
| 枠切れ対策 | なし | Tavily(1,200クレジット/月)に1行で切り替える手順を用意。web-failover skillで自動化 |
| X Search | 第5回でGrok OAuth(xai-oauth)は追加済み | platformごとに有効化し、Xの議論を拾えるようにする。数値は出させない |
| 設定の置き場所 | バラバラ | 秘密キーは1Password(op://参照)、backendはconfig.yamlの1行 |

一言でまとめると「Hermesに事実(Web)と反応(X)を両方取りに行かせて、無料枠が切れても自分で運用を引き継がせる」回だ。

### この回で出てくる言葉

| 用語 | 意味 | たとえ |
|---|---|---|
| web_search | クエリでURL一覧を返すtool | 検索結果ページの取得 |
| web_extract | 特定URLの本文を抽出するtool | 1ページを開いて中身だけ取り出す |
| Firecrawl | AI向け検索・本文抽出のクラウドサービス。Hermes公式のデフォルトbackend。検索と本文抽出の両対応 | Webページを綺麗な印刷物に変換してくれるサービス |
| Tavily | AI最適化検索・抽出のクラウドサービス。同じく検索と本文抽出の両対応。本シリーズではFirecrawlの枠切れ時の切替先 | 同上(別ベンダー) |
| backend | web検索・抽出を実装する道具の選択。`backend: firecrawl`のようにconfig.yamlに書く | 使うブラウザを決める |
| op://参照 | config/envに秘密の実値を書かず、1Passwordの場所だけを指す書き方。実値は起動時に`op run`が注入する(第3回) | 金庫の中身でなく、金庫の番号だけメモに書く |
| x_search | XでのGrokによる議論・反応の要約。投稿URLは返るが、いいね/RT等の数値は返さない | 「Xで今この話題どうなってる?」をGrokに聞く |
| ランブック | 「ここで止まったらこの順で直す」と書いた手順書。第10回のskillに添付できる | 非常時マニュアル |

### 第11回終了時点の構成図

![VPS上のHermes AgentがFirecrawlを本線にしてWeb検索とWeb抽出を行い、無料枠が切れたらconfig.yamlの1行書き換えでTavilyに切り替え、X検索はGrok OAuth経由のx_searchで議論を拾う構成図。秘密キーは1Passwordにop://参照で格納され、起動時にop runが注入する](/images/hermes-vps/hermes-vps-11-web-search-architecture-diagram.png)

ポイントは、`backend`を1つ選べば検索も本文抽出も済むこと、そしてキーは1Passwordに置いてconfig.yamlには参照しか書かないことだ。秘密を平文でディスクに残さない第3回の作法を、今回もそのまま使う。

## 事前準備

各回は別の日に作業することが多い。まず、いつものVPSにSSHで接続し直すところから始める(第1〜2回で設定したTailscale経由、ユーザー`admin`・ホスト`hermes-vps`)。第10回と同じく、本文を書く前に実機(v0.16.0)の実体を確認しておく。

### 接続して稼働を確認する

次の4つは「動いているか」の確認用だ。

```bash
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps
hermes version                                  # v0.16.0 を確認
systemctl --user status hermes-gateway          # active (running)
docker ps                                       # Docker engine 稼働(第4回)
systemctl --user cat hermes-gateway | grep -i exec   # op run経由で起動しているか(第6回)
```

`hermes version`が`v0.16.0`、hermes-gatewayが`active (running)`、Docker engineが動いていて、起動コマンドが`op run --env-file=~/.hermes/secrets.env -- hermes gateway run`になっていれば、第10回までの構成は崩れていない。Telegramからbotに何か話しかけて返事が来ることもあわせて確認しておく。

### 今のweb:セクションを確認する(出発点)

この回で書き換える`web:`セクションの現状を見ておく。下のコマンド1つの出力が出発点になる。

```bash
grep -A 6 "^web:" ~/.hermes/config.yaml
```

![ターミナルでgrep -A 6 web: config.yamlを実行した出力。第4回setup直後の状態でbackendの値が未設定のままになっている画面](/images/hermes-vps/hermes-vps-11-config-before.png)

`backend:`の値や`search_backend:`・`extract_backend:`の有無、`use_gateway:`の値が見える。ここを今回`backend: "firecrawl"`に整える。

## 検索と本文抽出の考え方──このシリーズの選択

HermesのWebは「検索(URL探し)」と「抽出(本文取り)」の2つに分かれる。両方をまかなえるbackendを1つ選べば、設定はconfig.yamlの1行で済む。主なbackendは次のとおり。

| backend | search | extract | 料金 | キー | このシリーズでの扱い |
|---|---|---|---|---|---|
| **Firecrawl**(default・公式推奨) | ✓ | ✓ | 無料500クレジット/月 | `FIRECRAWL_API_KEY` | **採用**(本線)。公式が「Recommended for most users」と明記 |
| **Tavily** | ✓ | ✓ | 無料1,200クレジット/月 | `TAVILY_API_KEY` | **切替先**。Firecrawl枠切れ時の受け皿 |
| Exa | ✓ | ✓ | 有料(無料トライアル) | `EXA_API_KEY` | 用途別の選択肢 |
| SearXNG(自己ホスト) | ✓ | ✗ | 無料(自己ホスト) | `SEARXNG_URL` | **降格**。実検証で主要engineがbot対策で停止すると判明(末尾コラム) |
| Brave Search | ✓ | ✗ | 無料2000/月 | `BRAVE_SEARCH_API_KEY` | 検索の代替候補 |
| DDGS(DuckDuckGo) | ✓ | ✗ | 無料 | 不要 | キーレスのフォールバック |

出典は[公式web-searchドキュメント](https://hermes-agent.nousresearch.com/docs/user-guide/features/web-search)。Firecrawlが`Recommended for most users`と明記されている。

### 本線=Firecrawl(default)、枠切れ時はTavily

:::message
- **本線はFirecrawl**:Hermes公式の`backend`デフォルトであり、「Recommended for most users」と公式docが明記している。1つのbackendで検索も本文抽出も済むので設定がシンプル(config.yamlの1行)
- **枠切れ時はTavily**:無料1,200クレジット/月でFirecrawlより枠が広い。同じく1つのbackendで検索も本文抽出も済む。切替は`backend: firecrawl`を`backend: tavily`に直すだけ
:::

「最初からTavilyにすればよいのでは」と思うかもしれない。Hermes公式が推奨するレールに乗ると、`hermes setup`のwizardやエラーメッセージとの整合が取りやすい。まずは公式のレールに乗り、枠が切れたら切り替える、が一番楽だ。

### SearXNGはこのシリーズでは降格(理由は実検証コラムで)

当初は「SearXNGで検索を無料・無制限に」と考えた。実機で動かしてみたら、主要engine(duckduckgo・wikipedia・brave等)がクラウド側のbot対策で軒並み弾かれる事実を確認した。詳しい証拠ログは末尾の[実検証コラム](#実検証コラム──searxng自己ホストの罠)に残す。SearXNGを使うならBrave Search APIキー等の追加が要り、それなら最初からFirecrawl/Tavilyで素直に進めるほうが速い。

### 自動fallbackの公式PRはオープン中

公式リポジトリでは、`search_fallback_backends`と`extract_fallback_backends`を導入するPRが進んでいる([#23315](https://github.com/NousResearch/hermes-agent/pull/23315)・[#23366](https://github.com/NousResearch/hermes-agent/pull/23366)・どちらも執筆時点ではopen)。これがマージされれば、Firecrawl枠切れ時に自動で次のbackendへフォールバックする仕様になる。それまでは「設定を1行直す」操作が必要で、本記事ではその操作自体を第10回のskillに引き取らせる方針で進める。

## FirecrawlのAPIキーを取得して1Passwordに入れる

### Firecrawlのアカウントを作る

Firecrawlは[firecrawl.dev](https://www.firecrawl.dev)で無料アカウントを作る。無料枠は500クレジット/月(最新の上限は公式で確認)。

![Firecrawlのサインアップ画面。Sign Upパネルにメールアドレス・パスワード欄とContinue with GitHub/Googleボタンが並ぶ画面](/images/hermes-vps/hermes-vps-11-firecrawl-signup.png)

### APIキーを発行する

ダッシュボードで`fc-`で始まるAPIキーを確認する。

![FirecrawlダッシュボードのAPI Keys画面。Personal Teamの欄に無料枠のクレジット表示とfc-で始まるAPIキーが赤枠で囲まれている](/images/hermes-vps/hermes-vps-11-firecrawl-apikey.png)

### 1Passwordに格納する(第3回の作法)

キーの実値は平文でファイルに書かず、第3回で作った保管庫`Hermes-Prod`に新規アイテム`Hermes VPS - Firecrawl API key`を作って入れる(命名は第5回のDiscord bot tokenと揃える)。

![1Passwordの保管庫Hermes-Prodに「Hermes VPS - Firecrawl API key」アイテムを保存した画面](/images/hermes-vps/hermes-vps-11-1password-firecrawl.png)

「**認証情報**」フィールドにFirecrawlのキーを貼り付けて保存する。1Passwordの日本語UIでは「認証情報」と表示されるが、`op://`参照では内部名`credential`で参照する。文中の操作は「認証情報」、コード上の表記は`credential`と使い分ける(第3回・第5回参照)。

## secrets.envとconfig.yamlで設定を反映

秘密キーは1Passwordの参照(op://)を`secrets.env`に書き、backendは`config.yaml`の1行に書く。これで平文の秘密をディスクに残さない第3回の方針を守れる。

### secrets.envにFirecrawlのop://参照を追加する

```bash
nano ~/.hermes/secrets.env
```

エディタが開いたら、ファイルの末尾に以下の1行を追加する(保管庫名は第3回と同じ`Hermes-Prod`、アイテム名は前章で作った`Hermes VPS - Firecrawl API key`に合わせる)。

```text
FIRECRAWL_API_KEY=op://Hermes-Prod/Hermes VPS - Firecrawl API key/credential
```

追記したら保存して閉じる(`Ctrl`+`O`→`Enter`で保存、`Ctrl`+`X`で終了)。実値は`op run`が起動時に注入する。gatewayは第6回のsystemdユニットで`op run --env-file=~/.hermes/secrets.env -- hermes gateway run`として起動しているので、ここに足した参照は次回起動時に解決される。

![secrets.envをnanoで開いた画面。TELEGRAM/DISCORD/FIRECRAWL/SEARXNG_URL/TAVILYの各op://参照が6行で並んでいる](/images/hermes-vps/hermes-vps-11-secrets-env-new.png)

### config.yamlでbackendをfirecrawlにする

:::message alert
config.yamlは長い。`web:`セクションは**すでに存在する**(事前準備で見たとおり)。ここに新しい`web:`を貼ると二重定義で壊れる。**既存の`backend:`の値だけ直す**。
:::

```bash
nano ~/.hermes/config.yaml
```

`Ctrl`+`W`で検索を開き、`backend:`または`web:`で位置を出す。書き換え後の`web:`はこうなる。

```yaml
web:
  backend: "firecrawl"          # 公式デフォルト・本線(search+extract両対応)
  search_backend: ""            # 空でよい(backendが両方をまかなう)
  extract_backend: ""           # 空でよい
  use_gateway: false
```

![config.yamlのweb:セクションを書き換えた後の画面。backend firecrawlと並んでsearch_backendとextract_backendが空、use_gateway falseが赤枠でハイライトされている](/images/hermes-vps/hermes-vps-11-config-after-firecrawl.png)

`search_backend`と`extract_backend`は空のままでよい(`backend`が両方をまかなうため)。両方を`"firecrawl"`と明記する書き方でも動く。保存して終了する(`Ctrl`+`O`→`Enter`、`Ctrl`+`X`)。

### 反映(再起動)

```bash
systemctl --user restart hermes-gateway
systemctl --user is-active hermes-gateway        # active が返れば再起動成功
```

![systemctl --user restart hermes-gatewayを実行し、続いてis-activeがactiveを返した画面](/images/hermes-vps/hermes-vps-11-gateway-restart.png)

`active`が返れば設定が反映された。`status=1/FAILURE`の表示が混じることがあるが、旧プロセスがSIGKILLされた表示で、再起動自体は正常だ。`is-active`が`active`を返すかで判断する。

## 動作確認──検索と本文抽出が効くか

### Telegram検索が返るか

botに以下を送る。

```text
「systemdとは何か」を簡潔に検索して、3つの一次情報URLを並べて教えて
```

数秒〜10秒で結果が返り、実在URLが3件以上+各URLに一行要約が付いていれば成功だ。

![Telegramで検索クエリを送信し、Tavily経由で3件のsystemd公式URLが一行要約付きで返ってきた画面。bot名はHermes VPS](/images/hermes-vps/hermes-vps-11-telegram-search.png)

Tavily切替後の同クエリ再送でも同じ挙動になる(切替時の動作確認は次章のskill経由のフローで詳しく扱う)。

### 本文抽出の確認

次に、特定URLの本文を取り出せるかを確かめる。

```text
https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html の主要セクション見出しだけ抜き出して
```

ここで起きたことを正直に書く。指定したURLはbot対策で阻まれた。普通なら「取れません」で終わる場面だが、エージェントはそこで止まらなかった。

エージェントは`web_extract`を2回呼び直し(freedesktop / GitHub raw)、`execute_code`まで動員して約3分間試行錯誤を続け、最終的にGitHub上に置かれた公式原本の元データ(XML形式・systemdプロジェクト自身が管理する一次資料)から主要セクション見出し7つ(Description / Service Templates / Automatic Dependencies / Options / Command lines / Examples / See Also)を取得して返した。

![Telegramでextract指示を出し、指定URLがbot対策で阻まれた後、エージェントがweb_extractを2回(freedesktop / GitHub raw)とexecute_codeで自律的に迂回し、公式原本XMLから7つの主要セクション見出しを抽出した画面](/images/hermes-vps/hermes-vps-11-telegram-extract.png)

これがエージェントの真価=自律的迂回だ。素のHTMLは`curl`で足り、`backend`に設定したFirecrawlが効くのはJS描画や本文をきれいに取り出す必要がある複雑なページだが、阻まれたときに代替経路を自分で見つけて完遂できるかは別の能力で、ここで初めて見える。

## 無料枠を使い切ったらTavilyに切り替える──web-failover skillで自動化

Firecrawlの無料枠(500クレジット/月)を使い切ったら、Tavily(無料1,200クレジット/月)に切り替える。準備さえしておけば、切替は`config.yaml`の1行を直すだけだ。

### Tavilyのアカウントとキーを準備する(事前)

枠切れに備えて、最初からTavilyのキーも1Passwordに入れておく(使うかどうかは別として、用意するだけならコストゼロ)。

手順はFirecrawlとほぼ同じだ。

1. [app.tavily.com](https://app.tavily.com/home)でアカウント作成
2. ダッシュボードでAPIキー(`tvly-...`)を確認
3. 1Password保管庫`Hermes-Prod`にアイテム`Hermes VPS - Tavily API key`を作成し「認証情報」にキーを格納
4. `secrets.env`にTavilyのop://参照も追加(まだ使わなくても問題ない)

```text
TAVILY_API_KEY=op://Hermes-Prod/Hermes VPS - Tavily API key/credential
```

ここまでやっておけば、切替はあと1行の書き換えだけになる。

### 実機で踏んだ402──そしてskillが自動で動いた

ここからが本題だ。執筆中に、Firecrawlの無料枠を本当に使い切った。普段は枠を意識せず使っていたが、検証で検索を回しすぎてクレジットが0になり、次の検索でこのエラーが返ってきた。

```text
Insufficient credits to perform this request. For more credits, you can upgrade your plan...
```

ここで第10回が効いた。事前に書いておいた`web-failover` skillが、このエラーを見て自動で起動した。skillの本文はこうなっている。

```markdown
## When to Use
- Firecrawl のレスポンスに 402 / "Insufficient credits" / "credits required" が含まれた時
- ユーザーから「Tavilyに切り替えて」「Firecrawl枠が切れた」と頼まれた時

## Procedure
1. ~/.hermes/config.yaml の web.backend を "tavily" に書き換える
2. hermes-gateway を再起動する
3. 月初にクレジットがリセットされたら "firecrawl" に戻す手順を最後に提示する

## Runbook (出力する2行)
yq -i '.web.backend = "tavily"' ~/.hermes/config.yaml
systemctl --user restart hermes-gateway
```

エージェントはこのskillを読み、ユーザー(私)に向かって**切替用のランブック2行**を提示してきた。402のエラー文と一緒に、yqでconfig.yamlを書き換えるコマンドと、systemd再起動コマンドが並ぶ。翌月クレジットがリセットされたらfirecrawlに戻す注意も末尾に付いた。

![Firecrawl 402 Insufficient creditsエラーをトリガーにweb-failover skillが自動起動し、Tavily切替用のランブック2行(yq -i書き換え+systemctl restart)と翌月戻しの注意が1つの応答に並んだ画面](/images/hermes-vps/hermes-vps-11-skill-runbook-firecrawl-402.png)

ここからは人間の出番だ。提示されたランブックの2行を、host shellのターミナルでそのまま実行する。動作確認の`is-active`を末尾に足して、切替成功までを一気通貫で見る。

```bash
yq -i '.web.backend = "tavily"' ~/.hermes/config.yaml
systemctl --user restart hermes-gateway
systemctl --user is-active hermes-gateway
```

![ランブックの2行を実機で実行し、yqでconfig.yamlのbackendをtavilyに書き換え、systemctl --user restart hermes-gatewayの後にis-activeがactiveを返した画面](/images/hermes-vps/hermes-vps-11-skill-runbook-execute.png)

切替が効いているかは、`yq`で読み取って確認する。

```bash
yq '.web.backend' ~/.hermes/config.yaml         # → tavily
systemctl --user is-active hermes-gateway        # → active
```

![yqでweb.backendがtavilyを返し、systemctl --user is-activeがactiveを返している1画面。切替確認の証拠](/images/hermes-vps/hermes-vps-11-tavily-active.png)

そのままTelegramで同じ検索クエリ(`「systemdとは何か」を簡潔に検索して、3つの一次情報URLを並べて`)を送ると、今度はTavily経由で3件のsystemd公式URLが返ってきた。402で止まっていた検索が、skill→ランブック→実行→検索成功と一連で繋がった瞬間だ。

ここで起きたことを整理すると、こうなる。

- Hermesがエラーを見てskillを自動選択した(skill自動切替)
- skillの中身にしたがって、エージェントが切替手順を整形して提示した
- ユーザー(私)はランブックの2行を実行するだけで運用を引き継げた
- 切替後の動作確認まで、同じ会話の中で完結した

公式PR [#23315](https://github.com/NousResearch/hermes-agent/pull/23315) / [#23366](https://github.com/NousResearch/hermes-agent/pull/23366) がマージされて`search_fallback_backends`が入れば、この手順はさらに自動化される。それまでは「skillに運用を引き取らせる」が、非エンジニアにとって最も実用的な落とし所になる。

:::message
動作確認が取れたら、本線をFirecrawlに戻すかどうかは月のクレジット状況で判断する。月初にFirecrawlのクレジットがリセットされたら、`yq -i '.web.backend = "firecrawl"' ~/.hermes/config.yaml`と再起動で戻せる。Tavilyのほうが枠は広いので、当面そのまま使い続けてもよい。
:::

## X Searchの設定──hermes doctorの落とし穴と--platform telegramの罠

ここから先のX検索は、第5回でGrok OAuth(`xai-oauth`)を入れていることが前提になる。Grok OAuthがx_searchの動作土台で、追加のキーは要らない。詳細は[公式x-searchドキュメント](https://hermes-agent.nousresearch.com/docs/user-guide/features/x-search)。

### Xに使う道を混同しない

| 道 | 何をするか | 認証 |
|---|---|---|
| Grok OAuth(第5回) | Grokを動かす土台。`x_search`もこれで動く | 設定済み(`hermes doctor`で✓ xAI OAuth) |
| `x_search` | **Xでの議論・反応をGrokが要約し、根拠の投稿URLを返す**。いいね/RT等の数値は返さない | Grok OAuthで動く(追加不要) |
| `web_search` | 公開web検索。Xには不向き(正確な数値が取れず、捏造を招く) | (Firecrawl/Tavily側) |

### 数値(いいね/RT)を求めない=捏造させない

:::message alert
`x_search`は**いいね/RT/閲覧などの数値を返さない**(公式schemaは`answer`+引用URLのみ)。それなのに「いいね数が多い順に」等と頼むと、エージェントは取得できない数値を**推測で埋める=捏造する**。本記事では**数値を一切求めず**、議論の内容と`x_search`が返した投稿URLだけを扱う。**出力に数値が出たら捏造なので採用しない**。
:::

### hermes doctorの✓だけでは足りない

まず現状を確認する。

```bash
hermes auth list                                  # xai-oauthがあるか(第5回で追加)
hermes doctor 2>&1 | grep -iE "xai oauth|x_search"
```

![hermes doctorの出力をgrepで絞り、✓ xAI OAuth (logged in)と✓ x_searchが並んでいる画面](/images/hermes-vps/hermes-vps-11-doctor-xsearch.png)

`✓ xAI OAuth (logged in)`と`✓ x_search`が並んで出る。ここで「使える状態だ」と判断すると、実際には呼べない。実機で踏んだ罠だ。

### 一次情報:doctorの✓は「有効化可能」の意味だった

Telegramで`x_search`を試したら、エージェントは「x_searchが利用できない」と返してきた。doctorは✓を出しているのに、だ。

調べてみると、`hermes tools enable`でplatformごとに別途有効化が要ると判明した。doctorの✓は「有効化可能な状態」を示すだけで、実際にsessionから呼べる状態にするには次のコマンドが要る。

```bash
hermes tools enable x_search                       # CLI platform で有効化
hermes tools list | grep x_search                  # ✓ enabled x_search 🐦 X (Twitter) Search
```

![hermes tools enable x_searchで✓ Enabledが返り、続いてhermes tools listでx_searchがenabled表示になっている画面](/images/hermes-vps/hermes-vps-11-tools-enable-xsearch.png)

ここでもう一段の罠がある。`hermes tools enable x_search`の`--platform`はデフォルトが`cli`だ。Telegramから呼ぶには、`--platform telegram`で別途有効化しないといけない。

```bash
hermes tools enable x_search --platform telegram
hermes tools list --platform telegram | grep x_search   # ✓ enabled x_search 🐦 X (Twitter) Search
```

![hermes tools enable x_search --platform telegramで✓ Enabledが返り、--platform telegram指定のlistでもenabled表示になっている画面。platform別の有効化が完了した証拠](/images/hermes-vps/hermes-vps-11-tools-enable-xsearch-telegram.png)

この一次情報は本シリーズで初めて記録する。「doctorで✓が出ていても、platformごとに`hermes tools enable --platform <name>`が要る」は、公式docには明示されておらず、実機で詰まって初めて気付いた挙動だ。第5回でGrok OAuthを入れて第11回でx_searchを使う読者は、ここで必ず通る道になる。

### モデルはgpt-5.5のままで呼べる

もう一つ実機で確認した事実を残す。私のHermesは普段gpt-5.5(openai-codex)で動かしている。「x_searchはGrok系メインモデルじゃないと使えないのでは」と思っていたが、`--platform telegram`を有効化した後は、gpt-5.5 sessionからもx_searchが普通に呼べた。

config.yamlの`x_search.model`はツール内部実行用で別軸の設定だ。sessionのメインモデルと、x_searchが内部で使うモデルは独立している。ここを取り違えると「メインモデルをgrokに変えなければ」と無駄な変更を入れることになる。

### 動作確認(数値を出させない)

botに以下を送る。**数値を求めない**のがポイントだ。

```text
x_searchを使って、Hermes Agent(NousResearch)についてXで最近どんな反応・議論があるか、代表的な投稿URLを3〜5件つけて教えて。いいね数などの数値は付けず、議論の内容とURLだけで。
```

![Telegramでx_searchクエリを送り、bot応答にx_searchの呼び出しログ・議論要約・3〜5件のX投稿URLが並び、いいね数などの数値は一切出ていない画面](/images/hermes-vps/hermes-vps-11-x-search-result.png)

返ってきた投稿URL(`x.com/<ユーザー名>/status/<数字>`形式)が実在するかをクリックして確認する。`x_search`は捏造URLを返さない設計だが、念のため本物に飛ぶかを最初の1回は確かめる。出力に「いいね○件」「RT○件」のような数値が混じっていたら、それは捏造なので採用しない。プロンプトを「数値なしで」と書き直して再実行する。

## morning-news Skillをハイブリッド検索に育てる

第10回で作った`~/.hermes/skills/morning-news/SKILL.md`を、新しい検索の役割分担(Firecrawl検索+Firecrawl抽出+x_search)に合わせて全文置換する。末尾に取得状況を必ず残す形にする。

```bash
nano ~/.hermes/skills/morning-news/SKILL.md
# Ctrl+K連打で全行削除 → 下のSKILL.md全文を貼り付け → Ctrl+O → Enter → Ctrl+X
```

更新後の`SKILL.md`全文(数値は一切出さない=x_searchは数値を返さず、書くと捏造になる)。

```markdown
---
name: morning-news
description: 朝のニュースと、X上のAI関連の話題を要約してTelegramに届ける
version: 1.2.0
metadata:
  hermes:
    tags: [news, daily, x-search]
    category: information
---
# Morning News Summary

## When to Use
- 朝の情報収集の時間
- Cronから毎朝7時に自動実行
- 「今日の話題は?」と聞かれた時

## Procedure
1. **Web検索**で過去24時間のAI関連記事のURL一覧を取得(backendはconfig.yamlの設定どおり・Firecrawlまたは枠切れ後Tavily)
2. 上位3〜5件の本文を取得し(必要なページはweb_extract、素のページはそのまま)、内容を確認
3. **x_search**でXでの議論・反応を取得して加える。根拠にしたX投稿のURL(x.com/<ユーザー名>/status/<数字>)を必ず添える。数値は付けない
4. Web側とX側を統合し、合計5項目に絞る
5. 各項目を2行以内で要約し、出典URL(記事URLまたはX投稿URL)を末尾に付ける
6. 末尾に「取得状況」を必ず付ける:
   - Web検索: 使用 / 未使用
   - 本文抽出: N件成功
   - X検索: 使用(x_search) / 未使用(理由)
   ※「使用(x_search)」と書けるのは、X投稿URL(x.com/status)を本文に1件以上載せたときだけ

## Verification
- 項目数が3〜5になっているか
- 各項目に出典URL(記事URLまたはX投稿URL)が付いているか
- X由来の項目にx.com/statusの投稿URLが付いているか
- いいね/RT等の数値が出ていないか(x_searchは数値を返さないため、出たら捏造)
- 末尾に「取得状況」が付き、本文の実態と一致しているか

## Pitfalls
- いいね/RT等の数値は出さない(x_searchは数値を返さないため、書くと捏造になる)
- x_searchが無効・403の日はWebだけで5項目を埋め、取得状況に「X検索: 未使用」と正直に書く
- 「使用(x_search)」と書くのにX投稿URLが本文に無い不一致を作らない

## References
- references/x-search-output-consistency.md: X投稿URLと取得状況を照合する検証手順
```

![nanoで開いた更新後のmorning-news SKILL.md v1.2.0。Procedure / Verification / Pitfalls / References各セクションが見える画面](/images/hermes-vps/hermes-vps-11-skill-md.png)

:::message
既存Skillの**中身を書き換えるだけ**なら`/reload_skills`は不要(第10回参照)。呼び出し名はアンダースコアの`/morning_news`だ。
:::

### Telegramから呼んで取得状況を確認する

botに`/morning_news`(アンダースコア)を送る。返ってきた応答で見るのは次の点だ。

- 5項目に絞られているか
- 各項目に記事URLまたはX投稿URLが付いているか
- いいね/RT等の数値が出ていないか
- 末尾の「取得状況」がWeb検索・本文抽出・X検索の3行で書かれているか
- 「X検索: 使用(x_search)」と書かれていれば、本文中にx.com/statusのURLが1件以上載っているか(本文の実態と一致しているか)

![Telegramで/morning_newsを呼び出し、OpenAI / Anthropic / Z.AI / Google ADK / OpenAI Partner Networkの5項目が記事URL+X投稿URL3件のハイブリッドで並び、末尾にWeb検索 使用 / 本文抽出 N件成功 / X検索 使用(x_search)と取得状況が明示され、数値は一切出ていない画面](/images/hermes-vps/hermes-vps-11-morning-news.png)

ここで「X検索: 使用(x_search)」と書けるのは、本文中にX投稿URLが1件以上載っているときだけ、というルールをSKILL.md側に書いておくのが要点だ。skillに自己整合性を持たせると、応答の信頼性が一段上がる。

このskillは第9回のCronジョブにも添付されているので、明日の朝7時には自動で同じハイブリッド配信がTelegramに届くようになる。

## 最終確認チェックリスト(第11回)

第11回の到達点を確認する。

- [ ] `FIRECRAWL_API_KEY`が1Password(`Hermes VPS - Firecrawl API key`)に格納され、`secrets.env`に`op://`参照がある
- [ ] 切替用に`TAVILY_API_KEY`も1Passwordに格納され、`secrets.env`に`op://`参照がある(使う日が来たとき即切替可能)
- [ ] `~/.hermes/config.yaml`に`backend: firecrawl`(本線)
- [ ] Telegramからの検索で実在URLが3件以上返る
- [ ] 本文抽出の指示で見出しが返る。阻まれた場合はエージェントが自律的迂回をした
- [ ] `hermes doctor`で`✓ x_search`を確認し、`hermes tools enable x_search --platform telegram`まで実行した
- [ ] `x_search`でXの議論+投稿URLが返り、**数値が出ない**
- [ ] morning-news Skillが新Procedure(Web検索+web_extract+x_search・数値なし)で動作し、取得状況が末尾に付く
- [ ] 第9回Cronから翌朝7時に自動配信が届く

## 補足:x_searchが数値を返さない設計

本回の手順で、x_searchがいいね数・RT数・閲覧数といった指標を返さないことに気づいた人も多いはずだ。「使いにくいバグ」ではなく、捏造を防ぐための故意の設計だと考えると腑に落ちる。

X検索系のAPIはその時点での数値しか取れない。30分後に再取得すれば違う数値が返る。だがLLMはその性質を理解しないまま、一度見た数値を「事実」として記事に書いてしまう。結果として「本日10万いいねを獲得」のような、再現性のない数字が量産されやすい。

x_searchはこれを構造的に防ぐ。数値を最初から返さないので、LLMが書ける余地がない。投稿のURLと本文だけが残り、読者が必要なら自分で開いて最新の数値を確かめにいく。

morning-newsのProcedureで「数値は付けない」と注意書きを足すだけでは、別の検索ツールを使ったときに同じ事故が起きる。ツール側で構造的にブロックされていることが、運用の安全弁になっている。

## まとめ

第10回までで、エージェントは「24時間動く+自分専用の手順を覚える」状態になっていた。第11回は、そこに「事実(Web)と反応(X)を自分で取りに行く」道を足した。

今回でやったこと。

- Firecrawlを本線にしてWeb検索とWeb抽出を1つのbackendでまかなう構成にした
- 切替先のTavilyを事前準備し、1Passwordとsecrets.envに参照を入れた
- 実機でFirecrawl 402を踏み、web-failover skillが自動でランブックを提示することを確認した
- `hermes doctor`の✓と`hermes tools enable --platform telegram`の罠を実機で記録した
- gpt-5.5 sessionからx_searchが呼べることを確認した
- morning-news Skillをハイブリッド検索(Web+X)に育て、取得状況を必ず末尾に付ける形にした

Hermes Agentは「事実(Web)+反応(X)」を自分で取りに行ける状態になった。Web検索・抽出はFirecrawl、枠切れ時はTavilyに1行で切替、Xの議論はGrok経由。skillが運用を引き取ってくれるので、無料枠が切れて慌てる場面でもエージェントが自分で次の手を出してくれる。続きは順次公開していく。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第10回 Hermes Agentが使うほど賢くなるSkillsの登録方法](https://zenn.dev/sora_biz/articles/hermes-vps-10-skills) | [第12回 Hermes AgentにMemoryで好みと前提を記憶させる](https://zenn.dev/sora_biz/articles/hermes-vps-12-memory) |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## 実検証コラム──SearXNG自己ホストの罠

執筆過程でSearXNGを自己ホストして検索を全部無料・無制限にしようとした。実機で動かしてみたら主要engineが軒並みbot対策で停止していた。この一次情報を読者に残す。

### 試した構成(自己ホスト一式を実際に立てた)

SearXNG公式のDockerイメージを`127.0.0.1:8888`でlistenさせ、`settings.yml`でJSON出力を有効化し、`SEARXNG_URL=http://localhost:8888`をHermesに設定した。`config.yaml`で`search_backend: searxng`+`extract_backend: tavily`のハイブリッドにした。実際にコンテナが立ち上がり、疎通も取れた状態まで作った。

![SearXNG自己ホスト用のdocker-compose.yml。127.0.0.1:8888でlisten、restart unless-stoppedで常駐させる構成](/images/hermes-vps/hermes-vps-11-searxng-compose.png)

![SearXNGのsettings.ymlでJSON出力を有効化した画面(formats html json)](/images/hermes-vps/hermes-vps-11-searxng-settings.png)

![docker compose up -d直後の起動ログ。searxng-1がRunning表示](/images/hermes-vps/hermes-vps-11-searxng-up.png)

![docker compose psでSearXNGがUp状態、127.0.0.1:8888->8080/tcpでlistenしている画面](/images/hermes-vps/hermes-vps-11-searxng-ps.png)

![curlでlocalhost:8888/searchにformat=jsonでアクセスし、JSON応答が返ってSearXNG単体は動いていることを示す画面](/images/hermes-vps/hermes-vps-11-searxng-curl-json.png)

### botは応答を返したが、ログを見ると主要engineは軒並み停止していた

Telegramから`「systemdとは何か」を簡潔に検索して、3つの一次情報URLを並べて教えて`と送ると、botは確かに3つの一次情報URL(`systemd.io`/`github.com/systemd/systemd`/`freedesktop.org`)を返してきた。一見成功に見える。

ところが裏でSearXNGコンテナのログを見ると、主要engineは以下のエラーが連発していた。

| engine | 症状 |
|---|---|
| duckduckgo | `SearxEngineCaptchaException: CAPTCHA (wt-wt) (suspended_time=0)`(CAPTCHA表示で停止) |
| wikipedia | `HTTP requests timeout`(タイムアウト) / `500 Internal Server Error` |
| brave | `SearxEngineTooManyRequestsException: Too many request (suspended_time=180)`(レート制限・180秒停止) |

![docker compose logs --tail=20の出力に上記エラーが並ぶ画面。一次情報の証拠](/images/hermes-vps/hermes-vps-11-searxng-logs.png)

:::message alert
**応答が返ったのは「SearXNGが効いた」とは限らない**

botが3つのURLを返せたのは、(1)LLMが内部知識から既知URLを出した可能性、(2)エラー後にretryで別engineから取れた可能性、(3)他のbackend(Tavilyの抽出等)が補った可能性のどれかだ。**SearXNG単体が「無料・無制限の検索」を担えたわけではない**。ログがそれを示している。表面の成功と内部のログを両方見ないと、実態が分からない。
:::

### なぜこうなるか・どうすれば直るか

SearXNGは「複数の検索engineをまとめて叩くメタ検索エンジン」だが、APIキー無しで各検索サイト(`search.brave.com`等)を直接スクレイピングするため、クラウド側のbot対策(CAPTCHA・レート制限)で弾かれる。これは公開SearXNGインスタンスでも自己ホストでも変わらない構造的問題だ。

直す方法は、Brave Search APIキー(無料2000/月)等を取得して`BRAVE_SEARCH_API_KEY`として設定する手があり、これでSearXNG経由でAPI叩きになるためbot対策を回避できる。ただしキーを足すなら、最初からFirecrawl/Tavilyを直接使う方が話が早い。

### 本シリーズの結論

「SearXNGで検索を完全無料・無制限」は、APIキー追加なしでは現実的でない。Hermes公式が推奨するFirecrawl(default)に乗るのが、非エンジニアにとってシンプルで確実。SearXNGは「もっと自由にやりたい人へ」の選択肢として末尾コラムに残す。

## もっと自由にやりたい人へ(自己ホスト抽出)

「クラウドの無料枠を一切使いたくない=完全に自己ホストで無制限にしたい」という人向けの発展。非エンジニアには一段難しいので、本編はFirecrawl/Tavilyで十分。ここは読み物として。

| 選択肢 | 長所 | 短所 |
|---|---|---|
| **SearXNG+Brave Search APIキー** | 検索を自己ホスト化+APIキー無料枠2000/月でbot対策回避 | APIキーが増える。本文抽出は別途必要(SearXNGは検索専用) |
| **crawl4ai**(自己ホスト) | 単一コンテナで軽く、このクラスのVPSにも乗る。無料・無制限・キー不要。本文のmarkdown化がきれい | Hermesの`extract_backend`に名前で指定できない。`hermes mcp`で外部MCPツールとして繋ぎ、エージェントに使わせる誘導が要る(上級) |
| **Firecrawl**(自己ホスト) | Hermesに`FIRECRAWL_API_URL`で素直に繋がる | サーバ(API+Redis+RabbitMQ+Postgres+ブラウザ)で**メモリを大量に使う**。小型VPSには重く、常駐中のHermesを圧迫する。8GB以上の専用機向け |

:::message
つまり「VPSに乗る軽さ(crawl4ai)」と「Hermesに素直に繋がる(自己ホストFirecrawl)」は両立しにくい。自宅に余力のあるPCがあるなら、そこに抽出サーバを建ててVPSのHermesから繋ぐ手もある(この話は別の機会に)。本編はFirecrawl(枠切れたらTavily)で素直に動かすのが結局いちばん速い。
:::

## よくあるエラーと対処

| 症状 | 対処 |
|---|---|
| Firecrawlで「Insufficient credits」「402 Payment Required」 | 無料500クレジット/月を使い切った。Tavilyに切替(web-failover skillが自動でランブックを提示する)。月初にリセットされたら戻してもよい |
| Firecrawlキーが認識されない | 1) `secrets.env`の`op://`パス間違い(保管庫名/アイテム名/credential)、2) 1Password側のアイテム名と一致確認、3) `op run --env-file=~/.hermes/secrets.env -- bash -c 'echo ${FIRECRAWL_API_KEY:0:6}'`で実値が展開されるか確認 |
| 抽出が空 or 期待と違う | v0.17.0 rolling以降は大きいページは先頭+末尾だけが返り、中略部分は`cache/web`配下にフルテキストが保存される([PR#54843](https://github.com/NousResearch/hermes-agent/pull/54843)で2026-06-29にLLM要約→truncate+store方式へ変更・char budget初期15000は`config.yaml`の`web.extract_char_limit`で調整可)。SKILL.mdで「特定セクションだけ抜き出す」と明示するか、応答末尾の`read_file`案内に従って`cache/web`内のフルテキストを深掘りする。FirecrawlはJS描画や複雑なページに効く(素のHTMLはcurlで足りる) |
| X Searchで`degraded: true` | xAI側のレート制限。少し時間を置く+クエリを単純化 |
| 再起動で`status=1/FAILURE`表示 | 旧プロセスがSIGKILLされた表示で再起動では正常。`is-active`が`active`を返せば成功 |
| SearXNGに切り替えたら検索結果が薄い/エラー | 主要engineがbot対策で停止している可能性が高い(コラム参照)。Brave Search APIキー追加、または本線のFirecrawlに戻す |
| `hermes doctor`で✓ x_searchなのにTelegramから呼べない | `hermes tools enable x_search --platform telegram`を実行する。`hermes doctor`(健康診断コマンド・第8回〜第10回で導入)の✓は「有効化可能」の意味で、platformごとの有効化が別途必要 |

## コマンド早見表

```bash
# 設定確認・反映
cat ~/.hermes/config.yaml | grep -A 4 "^web:"                                  # 現在のbackend確認
op run --env-file=~/.hermes/secrets.env -- bash -c 'echo ${FIRECRAWL_API_KEY:0:6}'   # キー展開確認
systemctl --user restart hermes-gateway                                        # 反映
hermes doctor 2>&1 | grep -iE "firecrawl|tavily|x_search"                      # 効いているか

# backend切替(Firecrawl ↔ Tavily)
yq -i '.web.backend = "tavily"' ~/.hermes/config.yaml                          # skillが提示するランブックと同じ
systemctl --user restart hermes-gateway
yq '.web.backend' ~/.hermes/config.yaml                                        # 切替確認

# X Searchの有効化(platformごと)
hermes tools enable x_search                                                   # cli platform
hermes tools enable x_search --platform telegram                               # telegram platform
hermes tools list --platform telegram | grep x_search                          # 確認

# Telegramから動作確認(例)
「systemdとは何か」を検索して
https://example.com の主要セクション見出しを抽出して
x_searchで NousResearch のXでの反応を投稿URLつきで(数値は不要)
/morning_news        # 第10回Skill経由(呼び出し名はアンダースコア)
```

## 引用元と参考

| 項目 | 引用元 |
|---|---|
| Web検索全般・バックエンド比較・Firecrawlがdefaultで推奨 | [hermes-agent.nousresearch.com/docs/user-guide/features/web-search](https://hermes-agent.nousresearch.com/docs/user-guide/features/web-search)(「Firecrawl (default), Recommended for most users.」) |
| 機能別バックエンドはsearch/extractのみ(crawl_backendは存在しない) | 同上 per-capability backends |
| 自動fallback `search_fallback_backends` / `extract_fallback_backends`(執筆時点open) | NousResearch/hermes-agent PR [#23315](https://github.com/NousResearch/hermes-agent/pull/23315) / PR [#23366](https://github.com/NousResearch/hermes-agent/pull/23366) |
| SearXNG自己ホスト(Docker)+JSON format必須 | [Hermes同梱skill searxng-search](https://github.com/NousResearch/hermes-agent/blob/main/optional-skills/research/searxng-search/SKILL.md) |
| SearXNGはsearch専用(extract不可) | [NousResearch/hermes-agent#32698](https://github.com/NousResearch/hermes-agent/issues/32698) |
| Tavily(search+extract・無料枠) | [app.tavily.com](https://app.tavily.com/home) / 公式web-search |
| 秘密はop://参照で1Passwordに置く(平文をディスクに残さない) | 第3回・第5回(本シリーズ) |
| X Search全般・数値非対応(answer+引用URLのみ) | [公式x-search](https://hermes-agent.nousresearch.com/docs/user-guide/features/x-search) |
| `hermes tools enable --platform <name>`が必要(doctorの✓は有効化可能の意味) | 実機v0.16.0で確認(2026-06-17) |
