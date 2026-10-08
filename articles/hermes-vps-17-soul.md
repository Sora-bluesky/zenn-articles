---
title: "【第17回】口調をブレさせるな。Hermes Agentの話し方は実は変えられる"
emoji: "🗣️"
type: "tech"
topics: ["hermes", "ai", "llm", "claudecode", "個人開発"]
published: true
---

:::message
**この記事をAIに読ませる**

この記事はGitHubの公開リポジトリで管理していて、本文のMarkdownをそのまま取得できる。Claude CodeやCodexなどのAIエージェントに手順を任せたいときは、次のURLを渡すだけでいい。

https://raw.githubusercontent.com/Sora-bluesky/zenn-articles/main/articles/hermes-vps-17-soul.md

頼み方の例:「この記事を読んで、私の環境で手順を順番に実行して」に上のURLを添える。
:::

:::message
この連載は月1,800円ほどのVPSで、自分専用のAIエージェント(Hermes Agent)を24時間動かす実録だ。これはその第17回。全体の流れは[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::

:::details シリーズのもくじ(タップで開く)

**第I部 VPSで24時間動かす**
- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy) サーバー代は月1,800円で足りる。Hermes AgentはVPSで24時間動き続ける
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale) パスワードはもう打つな。Hermes AgentへのSSHは鍵一発で入れる
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password) APIキーをそのまま書くな。Hermes Agentの秘密は1Passwordが預かる
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install) Hermes AgentをDockerで隔離して動かす方法
- [第5回](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord) コマンドを覚えるな。Hermes AgentはDiscordで話しかけるだけで動く
- [第6回](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd) 気づいたら止まっている、をなくせ。Hermes Agentはsystemdでいつも動き続け、落ちてもすぐ戻る

**第II部 デスクトップアプリとブラウザから操作する**
- [第7回](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop) SSHはもう開くな。Hermes Agentはデスクトップアプリから直接話せる
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
- [第16回](https://zenn.dev/sora_biz/articles/hermes-vps-16-secondbrain) 同じことを二度調べさせるな。Hermes Agentは作業履歴からセカンドブレインを作る
- **第17回**(本記事) 口調をブレさせるな。Hermes Agentの話し方は実は変えられる

全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

## 導入:同じ質問に、Telegramでは敬語、CLIでも敬語で、挙げる理由は別々だった

同じ質問をTelegramとCLIで試したら、どちらも敬語で答えたが、気になる点として挙げた理由は別々だった。Hermesの話し方を書くファイル(`SOUL.md`)を自分で書いたあとは、どちらも常体で、同じ結論になった。この回は、その書き方と確かめ方だ。

この回でやらないのは、プロジェクトごとの指示(規約やパス)の整備と、スキルの書き直しだ。

確かめたのは、Hermes v0.21.5+8509(2026-10-07)をVPSで動かした範囲だ。使った質問は次の1文で、書き換える前も後も同じ文面にした。

```text
昨日のVPSの調子を教えて。気になる点があれば1つだけ挙げて。
```

## この回の到達点

どの会話にも共通する話し方の指示を、自分で書いてシステムプロンプトの先頭に入る状態にする。今回の比較では、同じ質問を送ったTelegramとCLIが、2つとも常体で同じ結論になった。定時配信は、10月8日6:35に届いたhermes-watchの配信を見て、口調と、SOUL.mdが読まれることを確かめた。同じ質問を送ったのはTelegramとCLIの2つだけだ。

第16回完了時点との差分を表にする。

| 項目 | 第16回完了時点 | 本回(第17回)完了時点 |
|---|---|---|
| SOUL.mdの中身 | Hermesが最初から入れている英文1行(667バイト) | 自分で書いた4節(496バイト) |
| 答え方 | 敬語で答える。理由の挙げ方は質問ごとに変わる | SOUL.mdに書いた話し方で答える |
| Hermesの更新 | 手を入れていないSOUL.mdは、新しい英文に置き換えられる | 一度書き換えたファイルは置き換えられない |
| 次の回への橋渡し | 整理されたwiki(第16回) | 話し方が決まったHermesに、使ったスキルを書き直させる(第18回) |

この回で出てくる用語を先に押さえておく。

| 用語 | 意味 |
|---|---|
| SOUL.md | `~/.hermes/SOUL.md`。Hermesの話し方を書くテキストファイル |
| システムプロンプト | Hermesが新しい会話を始めるときに組み立て、モデルへ渡す、画面に出ない指示文。同じ会話の続きでは、最初に組み立てたものを使い回す |
| AGENTS.md | プロジェクトごとの指示(規約・パス・構成)を書くファイル |
| gateway | Telegramとのやりとりを受け持つ常駐プログラム。第6回でsystemdに登録した`hermes-gateway` |
| `hermes -z` | 質問を1回だけ投げて答えを受け取るCLIの実行形式 |

## SOUL.mdとは

SOUL.mdは、Hermesが新しい会話を始めるときに、いちばん最初に読む、話し方を書いたテキストファイルだ。置き場所は`~/.hermes/SOUL.md`の1か所に決まっている。

Hermesは新しい会話を始めるときに、システムプロンプトを組み立ててモデルに渡す。同じ会話の続きでは、最初に組み立てたものを使い回す。その一番最初に入るのがSOUL.mdだ。次の図は、システムプロンプトの中身が並ぶ順番を示している。

![Hermesの応答までの流れの図。セッション開始の次に、システムプロンプトが上から順に4段で組み立てられる。1段目がSOUL.md(~/.hermes/直下・会話の始めに読む・書いた文面のまま)で、「この回で書くファイル」の印が付いている。2段目がHermesの使い方の案内・ツールの注意・固定したスキル。3段目が.hermes.md、AGENTS.md、CLAUDE.md、.cursorrulesから最初に見つかった1種だけのプロジェクト指示ファイル。4段目がスキルの一覧・Memory・ユーザー情報・いまの日時。最後に、Telegram・CLI・cronのどこから話しかけても、先頭は同じSOUL.mdになるという応答が置かれている](/images/hermes-vps/hermes-vps-17-system-prompt-order.png)

1番目がSOUL.mdで、そのあとにHermesの使い方の案内、プロジェクトの指示ファイル、覚えたこと(Memory)などが続く。

役割の分け方は、次のとおりだ。

- 話し方は、SOUL.mdに書く
- プロジェクトごとの指示(規約・パス・構成)は、AGENTS.mdに書く。AGENTS.mdは作業しているフォルダから探して読み込まれるので、プロジェクトが変われば中身も変わる

SOUL.mdは作業フォルダに関係なく、いつも`~/.hermes/`から読まれる。そのため、作業フォルダに関係なく、共通の話し方の指示を渡せる。定時配信(第9回のcron)は実行のたびに新しい会話なので、実行のたびにSOUL.mdが読まれる。

第12〜16回で足したMemory・Obsidianのノート・Session Search・wikiは、おもにHermesが何を知っているかを増やす仕組みだった。SOUL.mdは、どの会話にも共通する話し方の指示を書く場所だ。個別の好み(第12回のように、USER.mdへ文体を保存する例)や、スキルの書式も、答え方に影響する。

## 書かずに置いておくとどうなるか

SOUL.mdは、自分で書かなくても最初から存在する。第4回のセットアップで、2026年5月27日にHermesが置いたファイルだ。この中身は、Hermesが用意した英文1行になっている。いまの状態を確かめる。`ls -la`は更新日つきの一覧、`wc -c`はバイト数を数えるコマンドだ。

```bash
ls -la ~/.hermes/SOUL.md
wc -c ~/.hermes/SOUL.md
```

![VPSでls -laとwc -cを実行した画面。~/.hermes/SOUL.mdの更新日がAug 31、サイズが667バイトと表示されている](/images/hermes-vps/hermes-vps-17-soul-before-ls.png)

サイズは667バイト、更新日は8月31日だった。5月27日に置かれてから、自分では一度も書き換えていない。それなのに更新日が変わっている。中身を見る。

```bash
cat ~/.hermes/SOUL.md; echo
```

![VPSでcatを実行した画面。SOUL.mdの全文が、You are Hermes Agent, built by Nous Research. Be direct: で始まる英文1行で表示されている](/images/hermes-vps/hermes-vps-17-soul-before-cat.png)

「You are Hermes Agent, built by Nous Research. Be direct: ...」で始まる英文1行だった。この英文には、日本語で話すことも、敬語で話すか常体で話すかも書かれていない。

更新日が変わった理由は、Hermes本体の処理にある。手を入れていないSOUL.mdは、Hermesを起動するたびに、新しい世代の英文へその場で置き換えられる。8月31日の更新日は、これによるものだった。一度でも自分で書き換えたファイルは、置き換えの対象から外れる。

書かずに置いておくと、話し方はHermesの更新のたびに、Hermes側の都合で変わる。一度書けば、上書きされない。

## 書き換える前の答えを記録する

書き換えた後では、この答えは再現できない。先に記録した。

先ほどの質問を、Telegramに送った。

![書き換え前のTelegramの画面。質問「昨日のVPSの調子を教えて。気になる点があれば1つだけ挙げて。」に、スキルの読み込みと過去のセッション検索を経て、敬体の答えが表示されている。取り込み待ちが0件であることと、気になる点としてVPS側のINDEXが古いことが書かれている](/images/hermes-vps/hermes-vps-17-before-telegram.png)

答えは敬語だった。過去のセッションを検索したうえで、Grok Bot確認cronが複数回動き、取り込み待ちは0件だったと答えた。気になる点として挙げたのは、VPS側のINDEXが古いことだ。

同じ質問を、CLIにも送った。

```bash
hermes -z "昨日のVPSの調子を教えて。気になる点があれば1つだけ挙げて。"
```

![書き換え前のCLIの画面。hermes -zで同じ質問を送ると、この環境からVPSの稼働ログにアクセスできないという前置きから始まる敬体の答えが表示されている。気になる点として、受信ファイルが9月30日以降増えていないことが挙げられている](/images/hermes-vps/hermes-vps-17-before-cli.png)

こちらも敬語だった。ただし「この環境からVPSの稼働ログにアクセスできない」と最初に断っていて、気になる点には別の理由(受信ファイルが9/30以降増えていない)を挙げた。

同じ質問なのに、Telegramでは「INDEXが古い」、CLIでは「受信ファイルが増えていない」と、挙げる理由が違った。1回ずつの比較なので、毎回こうなる保証ではない。SOUL.mdの英文には話し方の指定がないので、答え方は、そのときのモデルと検索結果しだいになる。

## SOUL.mdを書き換える

### バックアップを取る

元に戻せるよう、先にバックアップを取る。`cp`はファイルを複製するコマンドで、末尾の日付はあとで見分けるための目印だ。

```bash
cp ~/.hermes/SOUL.md ~/.hermes/SOUL.md.bak-20261007
```

戻すときは、この2つのファイル名を逆にして`cp`し、gatewayを再起動する。

### 4節で書く

次の4節を書いた。話し方に関することだけを置いている。公式ガイドが勧める構成(Identity・Style・Avoid・Defaults)で、4〜8行ほどの短さにする書き方だ。プロジェクトの規約やパスは、AGENTS.md側に書く。

```bash
nano ~/.hermes/SOUL.md
```

nanoは、ターミナルで使う簡易エディタだ。書き終えたら`Ctrl+O`のあと`Enter`で保存し、`Ctrl+X`で終了する。中身は次のとおり。

```markdown
# Identity
そら(sora)の常駐アシスタント。日本語で、落ち着いた常体で話す。
# Style
- 結論を先に。前置きと復唱をしない
- 不確かなことは不確かと言う。推測を断定にしない
- 数字と固有名詞は正確に。曖昧な形容で盛らない
# Avoid
- 過剰な敬語、絵文字の連発、感嘆符の乱用
- 「素晴らしい質問ですね」のような追従
# Defaults
- 迷ったら、短い答え+根拠1つ+次の一手1つ
```

4節の意図は、次のとおりだ。

| 節 | 書いたこと | 狙い |
|---|---|---|
| Identity | 日本語で、落ち着いた常体で話す | 既定の英文に無かった、言語と文体の指定 |
| Style | 結論を先に・不確かなことは不確かと言う・数字と固有名詞は正確に | 答えの順番と、言い切り方 |
| Avoid | 過剰な敬語・絵文字・追従 | やってほしくない話し方を先に消す |
| Defaults | 短い答え+根拠1つ+次の一手1つ | 迷ったときの答えの形 |

### 保存した中身を確認する

全文とバイト数を確認する。

```bash
cat ~/.hermes/SOUL.md
wc -c ~/.hermes/SOUL.md
```

![VPSでcatとwc -cを実行した画面。書き換え後のSOUL.mdの全文が、Identity・Style・Avoid・Defaultsの4節で表示され、サイズは496バイトになっている](/images/hermes-vps/hermes-vps-17-soul-after-cat.png)

4節で496バイトだった。もとの英文の667バイトより小さい。長く書くことより、短く絞って書くことが目的だ。

### gatewayを再起動し、新しい会話で確かめる

SOUL.mdは、新しい会話を始めるときに読まれる。書き換えただけでは、すでに動いているTelegramの会話には反映されない。まず、Telegramとのやりとりを受け持つ常駐プログラム(gateway)を再起動する。

```bash
systemctl --user restart hermes-gateway
systemctl --user status hermes-gateway --no-pager | head -8
```

![VPSでgatewayを再起動した画面。systemctl --user statusの出力で、hermes-gateway.serviceがactive (running)で、起動時刻がWed 2026-10-07 17:13:48 JSTと表示されている](/images/hermes-vps/hermes-vps-17-gateway-restart.png)

`Active: active (running)`と、新しい起動時刻(17:13:48)が出れば再起動できている。再起動したら、Telegramで`/new`を送って新しい会話を始め、そこで質問する。前の会話の続きで聞くと、最初に組み立てた古い指示文が使われることがある。CLIの`hermes -z`は実行のたびに新しい会話なので、実行のたびにSOUL.mdが読まれ、再起動はいらない。

## 書き換えた後の答え

書き換える前と同じ質問を、TelegramとCLIの2つに送った。定時配信は、同じ質問を送らず、届いた配信を見て確かめた。

### Telegramの答え

gatewayを再起動したあと、Telegramで`/new`を送って新しい会話を始めてから、同じ質問を送った。

![書き換え後のTelegramの画面。同じ質問に、スキルの読み込みとスケジュール一覧の確認を経て、常体の答えが表示されている。エラー報告は見当たらなかったことと、気になる点は1つだけで、CPU・メモリ・ディスク容量などVPS本体の数値は確認できず、サーバー全体が健全だったとは言い切れないことが書かれている](/images/hermes-vps/hermes-vps-17-after-telegram.png)

答えは常体に変わった。結論が先に来て、気になる点は1つだけだ。「CPU・メモリ・ディスク容量などVPS本体の数値は確認できず、サーバー全体が健全だったとは言い切れない」という言い方は、SOUL.mdに書いた「不確かなことは不確かと言う」に沿っている。

### CLIの答え

```bash
hermes -z "昨日のVPSの調子を教えて。気になる点があれば1つだけ挙げて。"
```

![書き換え後のCLIの画面。hermes -zで同じ質問を送ると、Hermesの定期処理とGrok Botの15分ごとの処理が夜まで動いていて、エラー報告も見当たらなかったという常体の答えが表示されている。気になる点は1つとして、CPU・メモリ・ディスクなどVPS本体の数値は確認できず、サーバー全体が健全だったとは言い切れないことが挙げられている](/images/hermes-vps/hermes-vps-17-after-cli.png)

CLIも常体で、気になる点は1つだった。書き換える前は、TelegramとCLIで挙げた理由が違っていた。書き換えた後は、どちらも「CPU・メモリ・ディスクなどVPS本体の数値は確認できず、サーバー全体が健全とは言い切れない」という同じ結論になった。

### 定時配信の答え

人が話しかけない定時配信でも、実行のたびにSOUL.mdが読まれる。2026年10月8日6:35に届いたhermes-watchの定時配信を確かめた。

![書き換え後に届いたTelegramのhermes-watchの定時配信の画面。2026-10-08のHermes関連投稿が6件、常体の短い要約で並び、取得状況として対象・方法・取得件数が書かれている](/images/hermes-vps/hermes-vps-17-after-cron.png)

定時配信も常体で届いた。ただし、書き換える前の10月6日の配信も常体だった。この配信の口調は、スキル(hermes-watch)に書かれた書式でも決まる。そのため、SOUL.mdを書き換えたから定時配信の口調が変わった、とはここでは言えない。確かめられたのは、定時配信でもSOUL.mdが実行のたびに読まれることと、定時配信が同じ常体で届くことまでだ。

## 反映されないときの切り分け

公式ガイドが挙げる、よくある失敗は次のとおり。

| 症状 | 原因 | 対処 |
|---|---|---|
| 書き換えたのに、話し方が変わらない | gatewayを再起動していない(SOUL.mdは新しい会話を始めるときに読まれる) | `systemctl --user restart hermes-gateway`を実行する。CLIの`hermes -z`は実行のたびに新しい会話なので、再起動はいらない |
| 再起動したのに、Telegramで話し方が変わらない | 前の会話の続きで聞いている(最初に組み立てた指示文が使い回される) | Telegramで`/new`を送り、新しい会話で聞き直す |
| 書き換え前の状態に戻したい | | `cp ~/.hermes/SOUL.md.bak-20261007 ~/.hermes/SOUL.md`のあと、gatewayを再起動する |

## 早見表・引用元・まとめと第18回予告

### 操作早見表

```bash
# [VPS ssh] バックアップ
cp ~/.hermes/SOUL.md ~/.hermes/SOUL.md.bak-20261007

# [VPS ssh] いまの状態を確認
ls -la ~/.hermes/SOUL.md
wc -c ~/.hermes/SOUL.md
cat ~/.hermes/SOUL.md

# [VPS ssh] 書き換えて、反映
nano ~/.hermes/SOUL.md
systemctl --user restart hermes-gateway
# [Telegram] /new を送って新しい会話を始めてから、質問して確かめる

# [VPS ssh] CLIで答え方を確認(再起動は不要)
hermes -z "昨日のVPSの調子を教えて。気になる点があれば1つだけ挙げて。"

# [VPS ssh] 元に戻す
cp ~/.hermes/SOUL.md.bak-20261007 ~/.hermes/SOUL.md
systemctl --user restart hermes-gateway
```

### 引用元と参考

| 項目 | 引用元 |
|---|---|
| SOUL.mdの使い方(公式ガイド。システムプロンプトの先頭に入ることは、公式ドキュメントでは`slot #1`と書かれている) | [English: Use SOUL.md with Hermes](https://hermes-agent.nousresearch.com/docs/guides/use-soul-with-hermes) / [日本語訳: SOUL.md を使う](https://wiki.winsmux.dev/hermes/docs/guides/use-soul-with-hermes/) |
| プロジェクトの指示ファイルの優先順位(公式ドキュメント) | [English: Context Files](https://hermes-agent.nousresearch.com/docs/user-guide/features/context-files) / [日本語訳: コンテキストファイル](https://wiki.winsmux.dev/hermes/docs/user-guide/features/context-files/) |
| 根拠(Hermes本体のコード) | システムプロンプトを組み立てる順番は`agent/system_prompt.py`。手を入れていないSOUL.mdを新しい英文に置き換える処理は`hermes_cli/default_soul.py`と`hermes_cli/config.py`の`_ensure_default_soul_md`。定時配信でSOUL.mdを必ず読む指定は`cron/scheduler.py`の`load_soul_identity=True` |
| 版の注記 | 画面はHermes v0.21.5+8509(2026-10-07)で撮影した |

### まとめと第18回予告

第17回完了で、どの会話にも共通する話し方の指示を、自分で書いたSOUL.mdとしてシステムプロンプトの先頭に入れる状態になった。内訳は次のとおり。

- 4か月間手を入れていなかったSOUL.mdは、Hermes本体の処理で新しい英文(667バイト)に置き換わっていた。自分で書き換えると、この置き換えの対象から外れる
- 書き換えは、バックアップ→編集→gateway再起動→Telegramで`/new`の順。496バイトの4節で足りた
- 同じ質問への答えは、書き換え前は敬語で、TelegramとCLIで挙げる理由が違った。書き換え後は常体になり、どちらも同じ結論になった
- 定時配信でもSOUL.mdは実行のたびに読まれる。定時配信の口調はスキルの書式にも左右されるので、SOUL.mdだけで決まるとは言えない

次の第18回は、話し方が決まったHermesに、使ったスキルを自分で書き直させる。スキルは第10回で扱った。連載の回数は変わる可能性があるので、着手時に最新の計画書を確認してほしい。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第16回](https://zenn.dev/sora_biz/articles/hermes-vps-16-secondbrain) 同じことを二度調べさせるな。Hermes Agentは作業履歴からセカンドブレインを作る | 第18回 使ったスキルを古いままにするな。Hermes Agentは自分でSKILL.mdを書き直す。(近日公開) |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

:::message
この連載はSubstack「そらのAIエージェント通信」で先行公開している。無料[登録](https://sorabiz.substack.com/subscribe)すると最新回がメールに届く。[Zennでフォロー](https://zenn.dev/sora_biz)すると新着通知が届き、全体像は[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::
