---
title: "【第10回】Hermes Agentが使うほど自分専用に育つ──Skillsに手順を覚えさせる"
emoji: "🤖"
type: "tech"
topics: ["ai", "hermes", "skills", "自動化", "vps"]
published: false
---

## 目次

- [概念整理──Skillsで何が変わるか](#概念整理──skillsで何が変わるか)
- [事前準備](#事前準備)
- [標準スキルを見る・使う](#標準スキルを見る・使う)
- [Skillとtoolの関係を見る](#skillとtoolの関係を見る)
- [Skills Hubで外部Skillを探す](#skills-hubで外部skillを探す)
- [最初の自作Skillを作る──記事や動画の要約](#最初の自作skillを作る──記事や動画の要約)
- [Progressive Disclosure(段階的開示)を理解する](#progressive-disclosure(段階的開示)を理解する)
- [Telegramから呼ぶ](#telegramから呼ぶ)
- [CronにSkillを添付する──毎朝Hermesの最新を要約させる](#cronにskillを添付する──毎朝hermesの最新を要約させる)
- [Skillにファイルを添付する(Level 2)](#skillにファイルを添付する(level-2))
- [最終確認チェックリスト](#最終確認チェックリスト)
- [まとめと第11回予告](#まとめと第11回予告)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [操作早見表](#操作早見表)
- [公式ドキュメント引用元](#公式ドキュメント引用元)

第6回でsystemd常駐が完成し、第7回でHermes Desktop、第8回でWeb Dashboard、第9回でCronが揃った。エージェントはVPSの上で24時間動き、毎朝7時にニュース要約をTelegramへ届けるところまで来た。

ただ、第9回のジョブには長いプロンプトを丸ごと直書きしていた。「何項目で」「出典は付けて」「締めの一文はこう」と全部書き切った依頼文だ。同じ手順を別のジョブでも使いたくなったら、その長文をもう一度コピーして貼り直すことになる。「ここだけ少し直したい」と思っても、毎回プロンプト全体を上から読み返して該当の1行を探す。気付いた注意点を1行ずつ足していくと、プロンプト欄はだんだん手順書のように膨らんでいく。

第10回はここをスキル(Hermesに覚えさせる作業手順書)にする。よく使う手順を1枚のファイルに書いておくと、以後は短い呼び出しひとつで同じ仕事が始まる。スキルはファイルとして残るので、会話履歴を消しても消えない。VPSに置いたエージェントが、使うほど自分専用の手順をためていく回だ。

そして今回は、その作成も管理も**すべてWeb Dashboardの中で完結する**。第9回までは自作スキルやCron添付でSSH(ターミナル)を開いていたが、Hermesの実機v0.16.0(2026年6月のアップデート)で、新規スキルの作成も、Cronへの添付も、ブラウザの管制室に入った。SSHでターミナルを開く必要はない。スマホを使うのは、出先からHermesに頼んでスキルを書かせる場面と、できたスキルを呼ぶ場面だけだ。

シリーズの全体像はこちら。

- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy)──Hermes AgentをVPSに迎える──契約から最小構成のログインまで
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale)──Hermes Agentの玄関を世界から隠す──Tailscaleで公開SSHを閉じる
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password)──Hermes Agentの秘密をファイルに残さない──1Passwordで参照だけ渡す
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install)──Hermes Agent本体をVPSに入れる──Dockerサンドボックスで隔離する
- [第5回](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord)──Grok OAuthとDiscordを足す──承認モードの確認
- [第6回](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd)──systemd常駐化で24時間動かす
- [第7回](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop)──Hermes Desktopでマウス操作する
- 第8回──Hermes Agentをブラウザの管制室から操る──Web Dashboardで設定を見える化する
- 第9回──Dashboardで毎朝の定型タスクを任せる
- **第10回**(本記事)──Skillsに手順を覚えさせる
- 第11回──Hermes Agentが最新情報を自分で取りに行く──Web検索とX検索を使い分ける

## 概念整理──Skillsで何が変わるか

最初に、この回で起きることを言葉にしておく。

スキルは公式の言葉で言うと「on-demand knowledge documents」、必要な時だけ読み込まれる知識文書だ。エージェントが「今これが要る」と判断した時にだけ、その手順書を開いて読む。VPS上の`~/.hermes/skills/`(スキルの置き場所)にある`SKILL.md`という1枚のファイルが、その本体になる。

考え方はシンプルだ。**同梱のスキルを使う → 足りなければHubで探す → それでも無ければ自分で書く**。この3段で、使った手順が`~/.hermes/skills/`に積み上がっていく。本記事もこの順番で進む。

### 第9回までの到達点と第10回の差分

第9回完了時と第10回完了後で、何がどう変わるかを表にする。

| 項目 | 第9回完了時 | 第10回完了後 |
|---|---|---|
| 標準スキル | 存在を知らない | 同梱52件をスキルペインで一覧・有効/無効を切り替え |
| 足りないスキル | 探す手段がない | BROWSE HUBで検索してインストール |
| 独自の手順 | Cronに長いプロンプトを直書き | NEW SKILLでスキル化し、Cronに添付・`/summarize_to_japanese`でも呼ぶ |
| 知能の蓄積 | 会話履歴が消えれば手順も消える | ファイルに残り、消えない。使うほどたまる |

一言でまとめると「よく使う手順をファイルに覚えさせて、Telegramからもニュース配信のCronからも同じ手順を呼べるようにする」回だ。

### この回で出てくる言葉

レシピカードに見立てて整理しておく。

| 用語 | 意味 | たとえ |
|---|---|---|
| スキル(Skill) | 「特定の作業のやり方」を書いた`SKILL.md`ファイル | 料理のレシピカード。一度書けば何度でも使える |
| SKILL.md | スキルの本体。先頭にメタデータ、その下に手順の本文 | レシピカードの「料理名」と「材料・手順」 |
| frontmatter | `SKILL.md`冒頭の`---`で囲んだメタデータ部分 | レシピの「料理名・難易度」ラベル |
| スキルペイン | Dashboardのスキル管理画面。すべて/ツールセット/BROWSE HUBの3ビュー | レシピ帳のインデックス |
| builtin・local・hub-installed | スキルの出どころ。同梱/自作/Hub導入の別 | 付属レシピ/手書きレシピ/取り込んだレシピ |
| Skills Hub | 外部のスキルを検索してインストールできる仕組み | レシピサイトからレシピを取り込む感覚 |
| Trust Level | スキルの信頼度。builtin/official/trusted/communityの4段階 | 「公式レシピ」と「ユーザー投稿レシピ」の区別 |

### 第10回終了時点の構成図

自作スキルは、第6回で常駐させたHermes Agentの中の`~/.hermes/skills/`に置かれる。今回はその作成も添付も、母艦(手元のノートPC)のブラウザからTailscaleの安全な接続でDashboardにつなぎ、画面の中で済ませる。

![母艦のブラウザからTailscale経由でVPSのhermes-dashboardとhermes-gatewayにつなぐ構成図。Dashboardのスキルペインからは新規スキルの作成(NEW SKILL)と編集鉛筆で~/.hermes/skills/summarize-to-japaneseのSKILL.mdを書き、BROWSE HUBからresearch/duckduckgo-searchを導入し、CRON編集モーダルのSKILLS欄でスキルをCronジョブに添付する。Telegramからは/summarize_to_japaneseでスキルを呼び出す。すべてDashboardで完結しSSH不要であることが伝わる図](/images/hermes-vps/hermes-vps-10-skills-architecture-diagram.png)

ポイントは、`SKILL.md`を一度置けば、あとはTelegramからもCronからも同じ手順を呼べること。手順の本体は1箇所にしかないので、直す時もそこだけ直せば全部に効く。

## 事前準備

第10回は**すべてWeb Dashboardで完結する**。SSHでターミナルを開く必要はない。スキルを呼ぶ場面と、出先からHermesに頼んでスキルを書かせる場面だけスマホを使う。

### Dashboardを開く

第8回でブックマークしたDashboardのURLをブラウザで開く。

```text
http://<tailscale-ip>:9119   # 第7-8回で常駐させたdashboardのURL
                             # ID/passwordはbasic認証(第7回)
```

開いたら、左サイドバーの「スキル」を選ぶとスキルペインが開く。あわせてサイドバー下部の「ゲートウェイの状態:実行中」を確認しておく。これが動いていれば、スキルの呼び出しも結果の受け取りもできる。

### この回はSSH不要

従来は自作スキルの作成や、Cronへの添付でターミナル(nano)を使っていた。v0.16.0でそれらもDashboardに入ったので、今回はブラウザだけで完結する。出先でHermesに頼んでスキルを作らせる場面(後述5-3)だけ、スマホのTelegramを使う。

## 標準スキルを見る・使う

自分で作る前に、最初から入っているスキルを見ておく。「公式はどんな書き方をしているか」が、そのまま自作の見本になる。

### スキルペインの全体像

左サイドバーの「スキル」を開くと、スキルペインが出る。左側には3つのビューを切り替えるフィルターが並んでいる。

- **すべて**:全スキルの一覧。各行に有効/無効のトグル、左にカテゴリ(Creative・Research・MLOpsなど)と検索欄
- **ツールセット**:スキルが乗っている道具の一覧(次の章で見る)
- **BROWSE HUB**:外部スキルを探す画面(4章で見る)

ヘッダーには「スキル ○/○ 有効」と、この環境のスキル数が出る。右上に`+ NEW SKILL`ボタン、各行には**編集鉛筆**(えんぴつアイコン)がある。

![Dashboardのスキルペイン初期画面。左に「すべて/ツールセット/BROWSE HUB」のビュー切り替えフィルターとカテゴリ一覧、各スキル行に有効/無効トグル、右上に+ NEW SKILLボタンが見える画面](/images/hermes-vps/hermes-vps-10-skills-pane.png)

:::message
スキルには出どころが3種類ある。本体に同梱されている**builtin**、Hubから足した**hub-installed**、自分で作った**local**だ。実機では同梱(builtin)が52件入っていて、Hub導入や自作を合わせるとこの環境では合計71件すべてが有効になっている。ヘッダーの数字はその環境の合計を指す。本記事では「同梱52件」と「この環境の合計71件」を区別して読んでほしい。
:::

### 使いたい標準スキルはトグルでON

デフォルトでは「すべて」ビューが開く。各行の左端にあるトグルが、そのスキルの有効/無効だ。**使いたい標準スキルは、ここをONにするだけ**で使えるようになる。

カテゴリ(Creative・Research・Software Developmentなど)で絞り込んだり、検索欄に`arxiv`などと入れて名前で絞り込んだりできる。たとえばカテゴリ「Research」を選ぶと、論文検索の`arxiv`、Web検索の代替`duckduckgo-search`、ナレッジ参照の`llm-wiki`などに絞り込まれる。

![スキルペインでカテゴリ「Research」を選び、arxiv・duckduckgo-search・llm-wikiなどResearch系のスキルだけに絞り込まれた状態の画面](/images/hermes-vps/hermes-vps-10-skills-pane-category.png)

:::message
トグルをオフにしても、それは無効化であってアンインストールではない。オフにしてもファイルは残り、再度オンにすれば元に戻る。完全に削除できるのはHubから入れたスキルだけで、同梱(builtin/official)は無効化はできても削除はできない設計だ。ここでは存在を見るだけにしておく。
:::

## Skillとtoolの関係を見る

「スキルはtoolの上に乗る知識文書」と書いた。これは**ツールセットビュー**で実際に見える。toolが「できること」、スキルが「やり方」だ。たとえば「Web検索する」というtoolがあり、その上に「朝のニュースをこういう手順で集める」というスキルが乗る。

### ツールセットビューを開く

左のフィルターで「ツールセット」を選ぶと、Hermesが使える道具がカードで並ぶ。各カードには「名前+アクティブ/非アクティブ+使えるツール名のチップ+Configure(設定)ボタン」がある。設定の中身は第11回で扱うので、ここでは見るだけにする。

![ツールセットビュー全体。複数のツールセットがカードで並び、Skillsカードと、Cron Jobsカード(with optional attached skillsの説明つき)が見える画面](/images/hermes-vps/hermes-vps-10-skills-toolsets.png)

### 関係する2つのカード

この一覧の中で、今回の話に直結するカードが2つある。

- **Skills**(アクティブ):`skill_manage` / `skill_view` / `skills_list`というツールを持つ。つまり**スキル自体もtoolのひとつ**として管理されている、という証拠
- **Cron Jobs**(アクティブ):`create / list / update / pause / resume / run` に加えて `with optional attached skills`(任意でスキルを添付できる)とある。第9回のCronに**スキルを添付できる**ことの実機根拠で、8章で使う

ついでに **X (Twitter) Search** のカードも見える。こちらは非アクティブで、`requires xAI OAuth or XAI_API_KEY`(xAIのOAuthかAPIキーが要る)と書かれている。8章のニュース監視でX検索を使う伏線になるが、詳しい設定は第11回で扱う。

## Skills Hubで外部Skillを探す

同梱のスキルですべてを賄えるわけではない。Skills Hubは、その**外側**のスキルを足す仕組みだ。検索 → Trustバッジの確認 → インストールまで、すべてブラウザの中で完結する。

### BROWSE HUBで検索する

左フィルターで「BROWSE HUB」を選ぶ。検索バーと`Search`/`Update all`ボタン、その下に接続済みのHub一覧(Official (Nous)・Hermes Index・skills.sh・GitHub・ClawHub・Claude Marketplace・LobeHubなど)が並ぶ。各行には「名前+source/trustバッジ+説明+識別子+`Install`ボタン」がある。

検索バーに`duckduckgo`と入れると、打った時点で候補が絞り込まれる(`Search`ボタンや`Update all`は再検索・更新に使う)。

![BROWSE HUBで「duckduckgo」を検索した結果。duckduckgo-searchが1件ヒットし、説明文と(すでに導入済みのため)トグルが見える画面](/images/hermes-vps/hermes-vps-10-skills-hub-search.png)

`duckduckgo`で絞ると、公式(`official`)の`duckduckgo-search`が出る。すでに入れてあればトグル、未導入なら`Install`ボタンが付く。Hubには公式以外のスキルも並ぶので、**入れる前に必ずsource/trustバッジを見る**。次の4段階がその目安だ。

### Trust Levelの4段階

Hubから入れる時に必ず見るのが`Trust`(信頼レベル)だ。スキルは外部のコードを持ち込むので、どこの誰が作ったかで扱いが変わる。

| Trust Level | ソース例 | 判断 |
|---|---|---|
| `builtin` | Hermes Agent本体に同梱 | 常に信頼 |
| `official` | 本体に同梱されているが既定では無効なスキル | 本体相当。警告なし。Installで有効化される |
| `trusted` | openai/anthropics/huggingface/NVIDIA/garrytanの公式配布 | 比較的安全。中身は確認 |
| `community` | 上記以外すべて | 個別に中身を読んでから判断 |

`official`は「外部から取得」ではなく「同梱されている予備のスキルを有効化する」操作にあたり、安全側だ。`community`が本当の外部取得で、こちらは中身を読んでから入れる。

### Install・更新・削除

入れたいスキルの`Install`を1クリックすると、**セキュリティスキャン**が走る。データ流出・プロンプトインジェクション・破壊的コマンド・サプライチェーン異常をチェックし、問題なければ`~/.hermes/skills/`に入る。`dangerous`(危険)と判定されたスキルは、そもそもインストールできない設計だ。

入れたスキルの中身は、スキルペインに戻って各行の**編集鉛筆**を押せば`SKILL.md`を開いて読めるし、その場で直せる。

更新は`Update all`ボタンでまとめて取り込める。

:::message
Hubは内部でGitHubを見にいくので、たくさん操作するとレート制限に当たり、`HTTP 403`が返ることがある。その時は`~/.hermes/.env`に`GITHUB_TOKEN=...`を入れておくと上限が上がる。ターミナルから直接やりたい場合は`hermes skills check`(更新確認)・`hermes skills update`(更新取込)・`hermes skills uninstall <名前>`(Hub導入スキルの削除)も使える。
:::

## 最初の自作Skillを作る──記事や動画の要約

ここからが「使うほど自分専用に育つ」の核心だ。v0.16.0で`+ NEW SKILL`ボタンと**編集鉛筆**が付き、ブラウザだけで`SKILL.md`を書けるようになった。

作り方は2通りある。**自分で`SKILL.md`を書く**(Dashboard)と、**Hermesにざっくり頼んで書かせる**(Telegram)だ。同じ「スキルを作る」でも入口が違うのが分かるよう、別々のスキルで体験する。

- 5-1〜5-2:自分でDashboardから`summarize-to-japanese`を書く。英語の記事やYouTubeのURLを放り込むと、日本語3〜5行で要点が返る。毎朝のニュースチェックや海外記事の下読みに効くスキルだ
- 5-3:出先でTelegramからHermesに`plain-japanese`を書かせる。役所の通知や利用規約のような硬い文章を投げると、中学生にもわかる言葉で返る。スマホから頼めるのが要点だ

### 自分でSKILL.mdを書く(Dashboard)

スキルペイン右上の`+ NEW SKILL`を押すと、新規作成モーダルが開く。欄は`NAME`(スキル名)・`CATEGORY (optional)`(分類・任意)・`SKILL.MD`(本体)の3つだ。次のように埋めてみる。

- `NAME`:`summarize-to-japanese`
- `CATEGORY`:`productivity`
- `SKILL.MD`:下のfrontmatter+本文を貼る

```markdown
---
name: summarize-to-japanese
description: 記事やYouTubeのURLを渡すと内容を取得して日本語で要約する。英語など外国語のソースは日本語に翻訳して要約する。
version: 1.0.0
---
# Summarize to Japanese

## When to Use
- 記事やYouTubeのURLを渡されて「要約して」と言われた時
- 外国語のソースを日本語でまとめてほしい時
- Cronから定期的に最新情報を要約させたい時

## Procedure
1. 渡されたURLの本文(または字幕)を取得する
2. 内容を3〜5項目に絞り、各項目を2行以内で要約する
3. 外国語のソースは日本語に翻訳して要約する
4. 各項目の末尾に出典URLを付ける
5. 最後に「気になるトピックがあれば、深掘りしてください」と添える

## Verification
- 項目が3〜5になっているか
- 各項目に出典URLが付いているか
- 外国語ソースが日本語に訳されているか

## Pitfalls
- 本文が取得できない場合は、取得できた範囲で要約し、その旨を明記する
- 動画は字幕がない場合があるので、概要欄やタイトルから補う
```

`CREATE SKILL`を押すと、サーバー側がfrontmatterをチェックし、問題なければ`~/.hermes/skills/summarize-to-japanese/SKILL.md`に保存される。

![NEW SKILLモーダルにsummarize-to-japaneseのNAME・CATEGORY(productivity)・SKILL.MD(frontmatterと本文)を入力し、CREATE SKILLボタンを押す直前の状態の画面](/images/hermes-vps/hermes-vps-10-skills-new-skill-modal.png)

`frontmatter`の中で一番大事なのは`description`だ。後で見るProgressive Disclosureで、エージェントが最初に読むのはこの1行だけになる。「いつ使うスキルか」を、動詞で具体的に書く。

### 一覧に出たか確認する

`CREATE SKILL`を押すと、スキルペインの「すべて」ビューに`summarize-to-japanese`が増える(トグルはON)。各行の**編集鉛筆**を押せば、`SKILL.md`エディタが開いてその場で直せる。

作成直後に一覧へ出ない場合は、ブラウザをリロードする(または7章の`/reload_skills`を使う)。

![スキルペインの一覧に自作のsummarize-to-japaneseが追加され、トグルONで行の右端に編集鉛筆が見える状態の画面](/images/hermes-vps/hermes-vps-10-skills-pane-local.png)

### Hermesに頼んで書かせる(Telegram)

もうひとつの作り方が、出先からHermesにざっくり頼む方法だ。Hermesが`skill_manage`というツールを使って、自分で`SKILL.md`を書いて保存してくれる。

ここで作るのは、5-1とは別の小さなスキル`plain-japanese`(難しい文章を中学生にもわかるやさしい日本語に言い換える)だ。`/skills`はTelegram非対応なので、スラッシュコマンドではなく**自然文で頼む**。

```text
やさしい日本語に言い換えるスキルを作って。
名前は plain-japanese、カテゴリは productivity。
難しい文章を渡したら、中学生にもわかる平易な日本語に言い換えて返すスキルにして。
```

`Skill 'plain-japanese' created`と保存先のパスが返ってくれば成功だ。

![Telegramで「やさしい日本語に言い換えるスキルを作って」と頼み、Hermesがskill_manageでplain-japaneseを作成し、保存先パスを返したやり取りの画面](/images/hermes-vps/hermes-vps-10-skills-skill-create-telegram.png)

:::message alert
**落とし穴1:`platforms: [any]`だとDashboardに出ない**
作ったはずのスキルが一覧に出ない──ここで戸惑いやすい。Hermesが`skill_manage`で自動生成すると、frontmatterが`platforms: [any]`になることがある。Hermesは仕様上`any`を有効と見なさず「このプラットフォームでは非対応」扱いにするため、**Dashboardの一覧に出ず、スラッシュでも呼べない**。その時は編集鉛筆で`platforms: [linux, macos, windows]`に直し、リロードする(それでもダメならゲートウェイを再起動)。5-1のように自分で書く時は、`platforms`行を入れなければこの問題は起きない。入れるなら3つを明記する。
:::

:::message alert
**落とし穴2:呼び出しはアンダースコア**
スラッシュコマンドの区切りはアンダースコアだ。詳しくは7章の落とし穴1で説明する。
:::

## Progressive Disclosure(段階的開示)を理解する

「必要な時だけ読み込む」とは具体的にどういうことか。Hermes Agentは3段階でスキルを読む。これをProgressive Disclosure(段階的開示)と呼ぶ。

| Level | 読み込む内容 | いつ読まれるか |
|---|---|---|
| Level 0 | `name`/`description`/`category`などのメタデータだけ | 常時(全スキルをざっと把握) |
| Level 1 | `SKILL.md`の本文(When to Use / Procedure / Pitfalls) | そのスキルが選ばれた時 |
| Level 2 | 添付ファイル(`references/`・`scripts/`) | 本文がそのファイルを参照した時 |

ふだんエージェントが抱えているのはLevel 0の要約だけで、全スキル合わせても軽い。だから多数あっても重くならない。「これが要る」と判断した時にだけLevel 1の本文を開き、さらに細かい資料が要ればLevel 2まで降りる。本のタイトルを眺めて、気になれば目次を見て、必要なら本文を読む、という読み方に近い。

ここから導かれる一番大事な実践が、`description`を丁寧に書くことだ。Level 0で読まれるのは`description`だけなので、ここで「いつ使うスキルか」が伝わらないと、エージェントがそもそも選ばない。**動詞で始めて、具体的なきっかけを書く**のがコツだ。

- 悪い例:`description: 要約ツール`(抽象的すぎて選ばれない)
- 良い例:`description: 記事やYouTubeのURLを渡すと内容を取得して日本語で要約する`

## Telegramから呼ぶ

インストール済みのスキルは、自動でスラッシュコマンドになる(公式:「Every installed skill is automatically available as a slash command」)。ここでは5-3で作った`plain-japanese`をTelegramから呼ぶ(`summarize-to-japanese`は次の8章でCronから使う)。

呼ぶ前に、実機で確認した2つの一手間を押さえておく。

:::message alert
**落とし穴1:呼び出し名はアンダースコア・`/skill`は無い**
ディレクトリ名は`plain-japanese`(ハイフン)だが、スラッシュコマンドは`/plain_japanese`と**アンダースコア**になる。`/plain-japanese`(ハイフン)も`/skill plain-japanese`も「Unknown command」だ。`/commands`で全コマンドを見ると、すべてのスキルがアンダースコア表記になっている。スラッシュ名はディレクトリ名ではなく、frontmatterの`name:`から作られる。`/skill <名前>`という共通コマンドは存在しない。
:::

:::message alert
**落とし穴2:作成直後はgatewayが認識していない**
スキルを置いた直後は、常駐中のgatewayが古い一覧を覚えたままだ。Telegramで`/reload_skills`を送って、gatewayに一覧を取り直させる。成功すると`Skills Reloaded`と`Added Skills: <直前に作ったスキル>`のように、**前回のリロード以降に増えた分だけ**表示される(実機では直前に作った`plain-japanese`が出た)。何を直前に作ったかで出る名前は変わるので、決め打ちにしない。Dashboardには即出るが、Telegramのスラッシュ反映にはこの一手間が要る。
:::

botに、順に送ってみる。

```text
/reload_skills        … gatewayにスキルを取り直させる(追加直後の1回だけ)
/plain_japanese 本施策は段階的に導入される予定です
```

`/reload_skills`で一覧が更新されたあと、`/plain_japanese`に難しい文章を渡すと、むずかしい語にかんたんな言い換えが添えられて返ってくる。「やさしくして」のような自然文でも同じように動く。

![Telegramで/plain_japaneseに難しい文章を渡し、やさしい日本語に言い換えられて返ってきた画面。bot名はHermes VPS](/images/hermes-vps/hermes-vps-10-skills-skill-telegram-call.png)

## CronにSkillを添付する──毎朝Hermesの最新を要約させる

ここで第9回とつながる。v0.16.0で、第9回のCRONペインの作成・編集モーダルに**SKILLS**というセクションが付いた。スキルをチェックで選ぶ(複数選べる)と、そのCronジョブにスキルが添付され、ジョブカードに**スキルバッジ**が出る。3章のツールセットで見た`Cron Jobs … with optional attached skills`が、この機能だ。SSHで`hermes cron edit`を打っていたのと同じことが、ブラウザだけでできる。

題材は「**毎朝、Hermes自身の最新情報を要約して届ける**」にする。Hermesの新機能は、開発元の@Tekniumや@NousResearchがまずXで発表する。それを毎朝拾って要約させれば、開発元の動きが日本語で手元に届く。5章で作った`summarize-to-japanese`を、このCronに添付する。

### Cronジョブを作る

左サイドバーから「CRON」を選び、右上の「作成」を押す(既存ジョブを使うなら編集鉛筆)。各欄を次のように埋める。

| 欄 | 入れる値 |
|---|---|
| 名前 | `hermes-watch` |
| プロンプト | 「@Teknium と @NousResearch の直近24時間のHermes関連の投稿をx_searchで取得し、summarize-to-japaneseの手順で日本語要約して。投稿URLも添えて」 |
| スケジュール(CRON式) | `0 7 * * *`(毎朝7時。第9回の「毎日」モードで時刻を選べば自動生成される) |
| 配信先 | Telegram |
| SKILLS | `summarize-to-japanese`にチェック |

`summarize-to-japanese`にチェックを入れるのが、今回のポイントだ。

![CRON作成/編集モーダルのSKILLS欄で、summarize-to-japaneseのチェックボックスにチェックを入れた状態の画面](/images/hermes-vps/hermes-vps-10-skills-cron-skills-select.png)

「作成」(新規)または「SAVE CHANGES」(編集)で保存すると、ジョブカードに`summarize-to-japanese`のスキルバッジが付く。プロンプトは「どのスキルの手順でやるか」を1行書けばよく、第9回のような長文はもう要らない。手順の中身は`SKILL.md`の側にあるからだ。

![保存後、hermes-watchのCRONジョブカードにsummarize-to-japaneseのスキルバッジが付いた状態の画面](/images/hermes-vps/hermes-vps-10-skills-cron-skill-badge.png)

:::message
プロンプトのx_search(X検索)は第11回で詳しく扱う。まだ有効にしていない場合は、プロンプトの末尾に「x_searchが使えなければ@Teknium/@NousResearchのGitHub Releaseとweb検索で代替して」と一言足しておけば、代わりの手段で動く。
:::

### 今すぐ実行して確かめる

明日の朝7時を待たなくても、すぐに動作確認できる。ジョブカードの**稲妻アイコン**(今すぐ実行)を押すと、次のtick(次の実行タイミング)で実行され、2〜3分でTelegramに要約が届く。

![稲妻(今すぐ実行)を押したあと、Telegramにhermes-watchの結果としてHermesの最新情報の日本語要約が投稿URL付きで届いた画面。bot名はHermes VPS](/images/hermes-vps/hermes-vps-10-skills-cron-result-telegram.png)

これで「毎朝、Hermesの新機能・新リリースが日本語で手元に届く」状態になった。手順を変えたい時は`summarize-to-japanese`の`SKILL.md`を編集鉛筆で直すだけで、Cron側は触らない。同じスキルをTelegramの`/summarize_to_japanese`からも、会話からも呼べる。これが「Cron=いつ動くか」と「Skill=どうやるか」を分ける意味だ。

## Skillにファイルを添付する(Level 2)

ここからは**概念の紹介**にとどめる(実機の操作は、必要になった時でいい)。

`SKILL.md`にいろいろ書き足していくと、本文に全部書くと長くなりすぎる場面が出てくる。「信頼できるニュースソースの一覧」「除外したい話題」「重複を除く補助スクリプト」などだ。こうした細かい資料は、スキルディレクトリの中に別ファイルとして置く。これがProgressive DisclosureのLevel 2だ。

```text
~/.hermes/skills/summarize-to-japanese/
├── SKILL.md
├── references/
│   └── glossary.md       # 専門用語の訳語集
└── scripts/
    └── extract.py        # 本文抽出の補助スクリプト
```

`SKILL.md`の本文からは「`references/glossary.md`の訳語に従う」のようにファイル名で参照する。本文(Level 1)に長いリストやコードを書き切るとトークン消費が毎回増えるので、必要な時だけ読む添付ファイルに逃がす、というのが使いどころだ。

ただし、添付ファイルの追加はディレクトリの操作になるので、これだけは今回の範囲外だ。必要になったらSSHで足す、と考えておけばいい。まずは1ファイルの`SKILL.md`で十分。添付は、自作スキルに手順を足していく中で「本文が長くなってきた」と感じたら使う応用だ。

## 最終確認チェックリスト

第10回の到達点を確認する。Dashboardでやることと、Telegram(スマホ)でやることを分けて並べた。

- [ ] **Dashboard**:スキルペインを開き、「すべて」ビューで標準スキルの一覧とトグルを確認した
- [ ] **Dashboard**:ツールセットビューでSkillsカードとCron Jobsカード(with optional attached skills)を確認した
- [ ] **Dashboard**:BROWSE HUBで検索し、official/communityのTrustバッジの違いを確認した
- [ ] **Dashboard**:`+ NEW SKILL`で`summarize-to-japanese`を作り、一覧に出た
- [ ] **Telegram**:Hermesに頼んで`plain-japanese`を作らせ、保存先パスが返った
- [ ] **Telegram**:`/reload_skills`→`/plain_japanese`で、やさしい日本語に言い換えられて返ってきた
- [ ] **Dashboard**:CRONの作成モーダルでSKILLS欄に`summarize-to-japanese`をチェックし、ジョブカードにバッジが付いた
- [ ] **Dashboard→Telegram**:稲妻(今すぐ実行)で、hermes-watchの要約がTelegramに届いた

## まとめと第11回予告

第10回でやったこと。

- スキルペインで標準スキルの一覧・トグル・カテゴリ絞り込みを確認(同梱52件・この環境では71件)
- ツールセットビューで「スキルもtoolのひとつ」「CronにSKILLを添付できる」を実機で確認
- BROWSE HUBで`duckduckgo`を検索し、official/communityのTrustの違いを確認
- `+ NEW SKILL`で`summarize-to-japanese`を自分で作成(Dashboard完結)
- 出先からTelegramでHermesに`plain-japanese`を作らせ、`/plain_japanese`で呼べることを確認
- CRONのSKILLS欄で`summarize-to-japanese`を添付し、`hermes-watch`で毎朝Hermesの最新を要約させた

これで、第9回まで「決まった時刻に長いプロンプトを流す」だったエージェントが、「自分専用の手順を覚え、Telegramからもニュース配信からも同じ手順を呼ぶ」状態になった。手順はファイルとして残り、会話履歴を消しても消えない。使った手順が`~/.hermes/skills/`に積み上がり、エージェントが自分専用になっていく。そして今回はその全工程を、SSHを開かずブラウザの管制室だけで終えられた。

第11回はWeb/X検索の使い分けだ。今回の`hermes-watch`で使ったx_searchを含め、Hermes Agentが使える複数のWeb検索バックエンド(SearXNG・Firecrawl等)とX Searchを整理し、どれを有効にするかを決める。検索の質は、スキルの出力をそのまま左右するからだ。

---

| ← 前の回 | 次の回 → |
|---|---|
| 第9回 Dashboardで毎朝の定型を任せる | 第11回 Web検索とX検索を使い分ける(近日公開) |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## よくあるエラーと対処

| 症状 | 対処 |
|---|---|
| 自作スキルがDashboardの一覧に出ない | 1) ブラウザをリロード、またはTelegramで`/reload_skills`、2) ディレクトリ名と`name:`が一致しているか、3) frontmatterが`platforms: [any]`になっていないか(→編集鉛筆で`[linux, macos, windows]`に直す)、4) それでも直らなければ`hermes skills reset` |
| Telegramで`/skill_name`が「Unknown command」 | 1) 区切りはアンダースコア(`/plain_japanese`。`/plain-japanese`は不可)、2) 追加直後は`/reload_skills`で取り直す、3) スラッシュ名はディレクトリ名ではなくfrontmatterの`name:`から作られる、4) `/skill <名前>`という共通コマンドは存在しない |
| トグルをオフにしてもファイルが残る | 正常。トグルオフは無効化であってアンインストールではない。完全削除はHub導入スキルのみ可能、同梱(builtin/official)は無効化のみ |
| スキルの中身を読みたい/直したい | スキルペインの各行の編集鉛筆で`SKILL.md`が開く。名前をクリックしても開かない |
| スキルは呼ばれるが期待通りに動かない | `description`を具体化する。Level 0で読まれるのは`description`だけなので、抽象的だと選ばれない |
| Hubのインストールで`HTTP 403` | GitHub APIのレート制限。`~/.hermes/.env`に`GITHUB_TOKEN=...`を設定 |
| Hub Skillが`dangerous`判定 | そもそもインストールできない設計。中身を手で確認するか別スキルで代替 |

## 操作早見表

### Dashboard(本筋)

| やりたいこと | 場所 | 操作 |
|---|---|---|
| 標準スキルを見る・ON/OFF | スキルペイン「すべて」 | 各行左のトグル |
| カテゴリ/名前で絞る | スキルペイン「すべて」 | 左のカテゴリ・検索欄 |
| toolとの関係を見る | スキルペイン「ツールセット」 | Skills/Cron Jobsカード |
| 外部スキルを探す・入れる | スキルペイン「BROWSE HUB」 | 入力で絞り込み→Trust確認→`Install` |
| 自作スキルを書く | スキルペイン右上 | `+ NEW SKILL`→NAME/CATEGORY/SKILL.MD→`CREATE SKILL` |
| スキルの中身を直す | スキルペイン各行 | 編集鉛筆→`SKILL.md`エディタ |
| CronにSkillを添付 | CRON作成/編集モーダル | SKILLS欄でチェック→「作成」/「SAVE CHANGES」 |
| Cronを今すぐ実行 | CRONジョブカード | 稲妻アイコン |

### Telegram(スマホ)

```text
(自然文)やさしい日本語のスキルを作って … Hermesがskill_manageで作成
/reload_skills                              … 追加直後にgatewayへ取り直させる
/plain_japanese むずかしい文章               … アンダースコア区切りで呼ぶ
/commands                                   … 全スキルのスラッシュ名を一覧
```

## 公式ドキュメント引用元

| 項目 | 引用元 |
|---|---|
| Skills全般 | [features/skills](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills) |
| SKILL.mdの書式(frontmatter) | 同上「SKILL.md Format」 |
| Progressive Disclosure(Level 0/1/2) | 同上「Progressive Disclosure Pattern」 |
| スラッシュコマンドでの自動化 | 同上「Every installed skill is automatically available as a slash command」 |
| Skills Hub(official/community等のソース) | 同上「Supported Hub Sources」 |
| Trust Level(builtin/official/trusted/community) | 同上「Security Scanning & Trust Levels」 |
| NEW SKILL+編集鉛筆・CRONのSKILLS添付欄 | 実機Dashboard v0.16.0で確認(2026-06-11)。[@Teknium告知](https://x.com/Teknium/status/2066185784332562605) |
