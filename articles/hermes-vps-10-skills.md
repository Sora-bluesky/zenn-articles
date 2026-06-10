---
title: "【第10回】Hermes Agentが使うほど自分専用に育つ──Skillsに手順を覚えさせる"
emoji: "🤖"
type: "tech"
topics: ["ai", "hermes", "skills", "自動化", "vps"]
published: false
---

## 目次

- [この回の到達点](#この回の到達点)
- [Skillとは何か](#skillとは何か)
- [第10回終了時点の構成図](#第10回終了時点の構成図)
- [事前準備](#事前準備)
- [組み込みSkillを見る](#組み込みskillを見る)
- [最初の自作Skillを作る](#最初の自作skillを作る)
- [段階的に読み込む仕組み(Progressive Disclosure)](#段階的に読み込む仕組み(progressive-disclosure))
- [CronにSkillを紐付ける](#cronにskillを紐付ける)
- [Skills Hubから足す](#skills-hubから足す)
- [Skillにファイルを添付する](#skillにファイルを添付する)
- [まとめと第11回予告](#まとめと第11回予告)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [公式ドキュメント引用元](#公式ドキュメント引用元)

第9回でCronが入り、Hermes Agentは「決まった時刻に自分から動く」ようになった。毎朝7時にニュース要約がTelegramに届くところまで来ている。

ただ、第9回のジョブには長いプロンプトを丸ごと直書きしていた。「何項目で」「出典は付けて」「締めの一文はこう」と全部書き切った依頼文だ。これを毎回コピペするのは無駄だし、文面を少し直したくなるたびにジョブを開いて書き換えることになる。

第10回はここをSkillにする。よく使う手順を`SKILL.md`という1枚のファイルに書いておくと、以後は`/morning_news`という短い呼び出しひとつで同じ仕事が始まる。Skillはファイルとして残るので、会話履歴を消しても消えない。VPSに置いたエージェントが、使うほど自分専用に育っていく回だ。

シリーズの全体像はこちら。

- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy)──VPSを契約して最小限の安全な状態でadminにログイン
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale)──Tailscaleで公開SSHを閉じる
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password)──1Password Service Accountと`op run`でsecrets管理
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install)──DockerサンドボックスとHermes Agentのインストール+Codex OAuth+Telegram疎通
- [第5回](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord)──Grok OAuthとDiscordを足す+承認モードの確認
- 第6回──systemd常駐化で24時間動かす
- 第7回──公式アプリ「Hermes Desktop」でマウス操作する
- 第8回──Hermes Agentをブラウザの管制室から操る──Web Dashboardで設定を見える化する
- 第9回──Cronで毎朝の定型タスクを任せる
- **第10回**(本記事)──Skillsに手順を覚えさせる
- 第11回──Web/X検索の使い分け(SearXNG+Firecrawl+X Search)
- 第12回──家の余ったPCをLinux常駐GPUサーバーにする(VPSの手足)

手を動かすのは、VPSにSSHでつないで`SKILL.md`を1枚作り、Telegramから呼び出すだけ。難しいプログラミングは出てこない。

## この回の到達点

第9回完了時と第10回完了後の差分を表にする。

| 項目 | 第9回完了時 | 第10回完了後 |
|---|---|---|
| 定型作業 | Cronジョブに長いプロンプトを毎回直書き | Skill化して`/morning_news`で呼ぶ |
| 手順の再利用 | 不可(プロンプトを都度書く) | **Skillとして保存し、何度でも呼ぶ** |
| 手順の変更 | ジョブを開いて書き直す | **`SKILL.md`を1箇所直すだけ** |
| 外部の手順を借りる | 機能なし | **Skills Hub経由でインストール** |

一言でまとめると「よく使う手順をファイルに覚えさせて、Telegramからもニュース配信のCronからも同じ手順を呼べるようにする」回だ。

## Skillとは何か

Skillは公式の言葉で言うと「on-demand knowledge documents」、必要な時だけ読み込まれる知識文書だ。`~/.hermes/skills/`の下に置いた`SKILL.md`を、エージェントが「今これが要る」と判断した時にだけ開いて読む。

第9回のCronと並べると役割の違いがはっきりする。

- Cron(第9回):**いつ**動くかを決める係。毎朝7時、2時間ごと、といったスケジュール
- Skill(第10回):**どうやる**かを決める係。ニュース要約ならどのソースを見て何項目に絞るか、という手順

「毎朝7時に(Cron)、この手順で(Skill)、ニュースをまとめる」と、時刻と手順を別々に持てるようになる。だから手順を直したい時はSkillだけ、時刻を変えたい時はCronだけを触ればよくなる。

もうひとつ、第9回までで出てきた`hermes tools`(エージェントが使える道具の一覧)との違いも押さえておく。toolが「できること」、Skillが「やり方」だ。たとえば「Web検索する」というtoolがあり、その上で「朝のニュースをこういう手順で集める」というSkillが乗る。実は**Skill自体もtoolのひとつ**として管理されている。これは後で実機の画面で確認する。

この回で出てくる言葉を先に押さえておく。

| 用語 | 意味 | たとえ |
|---|---|---|
| Skill | 「特定の作業のやり方」を書いた`SKILL.md`ファイル | 料理のレシピカード。一度書けば何度でも使える |
| SKILL.md | Skillの本体。先頭にメタdata、その下に手順の本文 | レシピカードの「料理名」と「材料・手順」 |
| frontmatter | `SKILL.md`冒頭の`---`で囲んだメタdata部分 | レシピの「料理名・難易度・所要時間」ラベル |
| Progressive Disclosure | 必要な時だけ詳細を読む段階的な読み込み方 | タイトルだけ見て、気になれば目次、必要なら本文 |
| Skills Hub | 外部のSkillを検索してインストールできる仕組み | レシピサイトからレシピを取り込む感覚 |
| Trust Level | Skillの信頼度。builtin/official/trusted/communityの4段階 | 「公式レシピ」と「ユーザー投稿レシピ」の区別 |

## 第10回終了時点の構成図

自作Skillは、第6回で常駐させたHermes Agentの中の`~/.hermes/skills/`に置かれる。Telegramから呼ぶと、エージェントがそのファイルを読んで手順どおりに動き、結果を返してくる。

![VPSに常駐するHermes Agentの~/.hermes/skillsに、ターミナルで作成した自作のmorning-newsとHubから入れたduckduckgo-searchが置かれる。最初からたくさんのskillが入っていてすぐ使える。母艦のブラウザからTailscaleの安全な接続でDashboardのスキルペインにつなぎ、一覧表示・有効/無効の切り替え・Hubで探す・中身プレビューができる。ターミナルでSKILL.mdを作成してCronに添付し、Cronが定期実行で/morning_newsからSKILL.mdを読み込んで実行し結果をTelegramへ送信する構成図](/images/hermes-vps/hermes-vps-10-skills-architecture-diagram.png)

ポイントは、`SKILL.md`を一度置けば、あとはTelegramからもCronからも同じ手順を呼べること。手順の本体は1箇所にしかないので、直す時もそこだけ直せば全部に効く。

## 事前準備

第6回までが完了していれば、追加で入れるものはない。Skillの作成と管理はVPS上で行うので、まずSSHでVPSにつなぐ。各回は別の日に作業することが多いので、毎回ここから接続し直す。

```bash
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps
hermes version                                  # v0.15.1 を確認
ls ~/.hermes/skills/ 2>/dev/null || mkdir -p ~/.hermes/skills/
hermes skills list
```

以下を確認しておく。

- `hermes-gateway`が`active (running)`(第6回の常駐が効いている)
- `~/.hermes/skills/`がある(なければ`mkdir -p`で作る。ここに自作Skillを置く)
- `hermes skills list`の末尾に`85 builtin … 85 enabled`と出る(同梱Skillが最初から全部使える状態)
- Telegramでbotに話しかけて返事が来る(Skillの呼び出しと結果の受け取りに使う)

![ターミナルでls ~/.hermes/skills/を実行した画面。ディレクトリが空、またはmkdirで作成した直後の状態](/images/hermes-vps/hermes-vps-10-skills-dir.png)

![hermes skills listの初期表示。SkillがName/Category/Source/Trustの列で並んでいる画面](/images/hermes-vps/hermes-vps-10-skills-list-top.png)

![hermes skills listの末尾。集計行に「0 hub-installed, 85 builtin, 0 local — 85 enabled, 0 disabled」と出ている画面](/images/hermes-vps/hermes-vps-10-skills-list.png)

集計行の読み方はこうだ。`builtin`が同梱Skill、`hub-installed`がHubから足したSkill、`local`が自分で作ったSkill。今は同梱の85件だけ、すべて`enabled`(有効)になっている。この回が終わる頃には、`local`に1件(自作)、`hub-installed`に1件(Hubから導入)が増える。

## 組み込みSkillを見る

自分で作る前に、最初から入っているSkillを覗いておく。「公式はどんな書き方をしているか」が、そのまま自作の見本になる。

### 一覧を見る

```bash
hermes skills list
```

`Source`列がすべて`builtin`、`Status`列が`enabled`になっている。`Category`で`creative`(20件超と最多)、`software-development`、`research`などにグループ分けされている。`plan`(作業計画)、`test-driven-development`(テスト駆動)、`github-pr-workflow`(PR作業)、`arxiv`(論文検索)、`obsidian`(ノート操作。第15回の布石)など、開発や調べ物の定番手順が並ぶ。

この回で一番の見本になるのが`hermes-agent-skill-authoring`だ。名前のとおり「Skillの作り方を教えるSkill」で、書式に迷ったらこれを開けば作法が分かる。

### 中身はファイルを直接開く

組み込みSkillの中身は、本体に同梱されているファイルを直接開いて読む。全文は長いので、先頭30行だけ切り出せば書式は分かる。

```bash
# 組み込みSkillはここに入っている(カテゴリ/スキル名/SKILL.md)
ls ~/hermes-agent/skills/

# 先頭30行(frontmatter+本文の入り)だけ見る
sed -n '1,30p' ~/hermes-agent/skills/autonomous-ai-agents/claude-code/SKILL.md
```

冒頭の`---`で囲まれた部分が`frontmatter`(名前・説明・バージョン・タグ)、その下が手順の本文だ。この「ラベル+手順」の2段構成が、次に自分で書く時のひな形になる。

![sed -n '1,30p'で組み込みSkillのSKILL.mdの先頭30行を表示した画面。frontmatterと本文の入りが1画面に収まっている](/images/hermes-vps/hermes-vps-10-builtin-skillmd.png)

:::message alert
組み込みSkillの中身を見るのに`hermes skills inspect <名前>`は**使わない**。`inspect`はSkills Hub(外部のレジストリ)を見にいくコマンドで、組み込みの名前(例:`claude-code`)を渡すと、Hub上にある同名の別Skill(コミュニティ製の別物)が出てしまう。組み込みの中身は上のようにファイルを直接開く。`inspect`はHubから入れる時(後半)に使う。
:::

### Skillとtoolの関係を画面で見る

「Skillはtoolの上に乗る知識文書」と書いた。これは`hermes tools`の画面で実際に見える。

```bash
hermes tools
```

`hermes tools`はエージェントが使える道具の一覧を出す対話画面だ。ここで見てほしいのは2点。

- 一覧の中に`Skills`そのものが1つの道具として並んでいる(`Skills (list, view, manage)`)。つまりSkillはtoolの一種
- `Cron Jobs`の説明に`with optional attached skills`とある。第9回のCronに**Skillを紐付けられる**ことの実機根拠。これは後半で使う

![hermes toolsのCLIツール一覧。「Skills (list, view, manage)」と「Cron Jobs … with optional attached skills」が並んでいる画面](/images/hermes-vps/hermes-vps-10-tools.png)

:::message
`hermes tools`は道具のオン/オフを切り替える画面でもあるが、ここでは中身を見るだけにしてそのまま閉じる(`ESC`または`Done`)。道具を切り替えるのは第11回の検索回で扱う。
:::

## 最初の自作Skillを作る

第9回でCronプロンプトとして書いた「毎朝のニュース要約」を、そのままSkillにする。プロンプトを書き直す手間が消えるだけでなく、Telegramから`/morning_news`で呼べるようになる。

### ディレクトリを作ってエディタを開く

Skillは`~/.hermes/skills/<スキル名>/SKILL.md`という置き場所が決まっている。ディレクトリを作って、そのままエディタ(nano)を開く。

```bash
mkdir -p ~/.hermes/skills/morning-news && nano ~/.hermes/skills/morning-news/SKILL.md
```

![mkdirでmorning-newsディレクトリを作り、nanoでSKILL.mdを開いた直後の空のエディタ画面](/images/hermes-vps/hermes-vps-10-skill-create.png)

nanoは普段使わない人が多いので、保存と終了のキーだけ覚えておく。画面の下部にも常に表示されている(`^`は`Ctrl`の意味)。

| 操作 | キー |
|---|---|
| 貼り付け後に保存 | `Ctrl`+`O` → `Enter`(ファイル名はそのままEnter) |
| エディタを終了 | `Ctrl`+`X` |
| 保存せず破棄して終了 | `Ctrl`+`X` → `N` |

### SKILL.mdの中身を書く

次の内容をエディタに貼る。`---`で囲んだ`frontmatter`に名前・説明・バージョンを書き、その下に手順を書く。

```markdown
---
name: morning-news
description: 朝のニュースと、X上のAI関連の話題を要約してTelegramに届ける
version: 1.0.0
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
1. 24時間以内のAI関連ニュース(Hacker News上位、ArXiv新着、Xで最近話題のAI関連投稿)を収集
2. 3〜5項目に絞る。優先度:技術的に新規性が高い → 業界影響が大きい → 個人開発者目線で使える
3. 各項目を2行以内で要約し、出典URLを末尾に付ける
4. 最後に「気になるトピックがあれば、深掘りしてください」と添える

## Verification
- 項目数が3〜5になっているか
- 各項目に出典URLが付いているか
- 24時間以上前の情報が混ざっていないか

## Pitfalls
- X検索が無効な場合、X上の話題は省略してWeb検索で代替する
- レート制限に当たった場合、Hacker News単独で5項目埋める
```

書き終えたら`Ctrl`+`O`→`Enter`で保存、`Ctrl`+`X`で抜ける。

![nanoでSKILL.mdのfrontmatterと本文を書き終えた編集中の画面](/images/hermes-vps/hermes-vps-10-skill-nano.png)

本文の見出し(When to Use / Procedure / Verification / Pitfalls)は決まりではないが、「いつ使うか・手順・確認・落とし穴」を分けて書くと、エージェントが手順を追いやすく、後から自分が直す時も読みやすい。

### 保存できたか確認する

保存したら、ファイルが想定どおりか中身を表示して確かめる。

```bash
hermes skills list | grep morning-news      # 一覧に出るか
cat ~/.hermes/skills/morning-news/SKILL.md   # 中身の最終確認
```

![cat ~/.hermes/skills/morning-news/SKILL.mdで保存したSKILL.mdの全文が表示された画面](/images/hermes-vps/hermes-vps-10-skill-cat.png)

`hermes skills list`で`morning-news`を抜き出すと、`Source`列が`builtin`ではなく`local`(自分で作ったSkill)になっている。集計行も`85 builtin, 1 local — 86 enabled`に変わる。

![hermes skills list | grepでmorning-news行が抜き出され、Source列がlocal・Status列がenabledになっている画面](/images/hermes-vps/hermes-vps-10-skill-list-local.png)

:::message alert
自作Skillの確認に`hermes skills inspect morning-news`は使わない。`inspect`はHubを見にいくので、自作の名前を渡すと別物が出るか「見つからない」になる。手元のSkillは`hermes skills list`に並ぶか確認し、中身は`cat`で開く。
:::

### Telegramから呼ぶ

インストール済みのSkillは、自動でスラッシュコマンドになる(公式:「Every installed skill is automatically available as a slash command」)。Cronと違ってTelegramからも呼べる。ただし実機(v0.15.1)で確認した**2つの落とし穴**がある。

:::message alert
**落とし穴1:呼び出し名はアンダースコア区切り**
ディレクトリ名は`morning-news`(ハイフン)だが、Telegramのスラッシュコマンドは`/morning_news`と**アンダースコア**になる。`/morning-news`(ハイフン)で送ると「Unknown command」になる。`/commands`で全コマンドを一覧表示すると、`/ascii_art`・`/github_pr_workflow`のように、すべてのSkillがアンダースコア表記になっているのが分かる。
:::

:::message alert
**落とし穴2:作成直後はgatewayが認識していない**
`SKILL.md`を置いた直後は、常駐中のgatewayが古い一覧を覚えたままになっている。Telegramで`/reload_skills`を送って、gatewayに一覧を取り直させる必要がある。成功すると`Skills Reloaded`・`Added Skills: morning-news`・`86 skill(s) available`のように、増えたSkillが表示される(85→86)。第9回で`/cron`がTelegramでは使えなかったのと同じく、**公式ドキュメントの記載と実機の一手間が違う**ポイントだ。
:::

Telegram botに、順に送る。

```text
/reload_skills        … gatewayにSkillを取り直させる(追加直後の1回だけ)
/morning_news         … アンダースコア区切りで呼ぶ
```

`/reload_skills`で一覧が更新されたあと、`/morning_news`を送ると数十秒後にニュース要約が届く。第9回でCronプロンプトに直書きしていたのと同じ品質の出力が、短い呼び出しひとつで返ってくる。

![Telegramで/reload_skillsを送るとSkills Reloaded・Added Skills: morning-news・86 skill(s) availableが表示され、続けて/morning_newsでニュース要約が出典URL付きで届いた画面。bot名はHermes VPS](/images/hermes-vps/hermes-vps-10-skill-telegram-call.png)

## 段階的に読み込む仕組み(Progressive Disclosure)

「必要な時だけ読み込む」とは具体的にどういうことか。Hermes Agentは3段階でSkillを読む。これをProgressive Disclosure(段階的開示)と呼ぶ。

| Level | 読み込む内容 | いつ読まれるか |
|---|---|---|
| Level 0 | `description`などのメタdataだけ | 常時(全Skillをざっと把握) |
| Level 1 | `SKILL.md`の本文(手順) | そのSkillが選ばれた時 |
| Level 2 | 添付ファイル(参考リンク集・スクリプト) | 本文がそのファイルを参照した時 |

ふだんエージェントが抱えているのはLevel 0の要約だけで、全Skill合わせても軽い。だから85件あっても重くならない。「これが要る」と判断した時にだけLevel 1の本文を開き、さらに細かい資料が要ればLevel 2まで降りる。本のタイトルを眺めて、気になれば目次を見て、必要なら本文を読む、という読み方に近い。

ここから導かれる一番大事な実践が、`frontmatter`の`description`を丁寧に書くことだ。Level 0で読まれるのは`description`だけなので、ここで「いつ使うSkillか」が伝わらないと、エージェントがそもそも選ばない。**動詞で始めて、具体的なきっかけを書く**のが鉄則だ。

- 悪い例:`description: ニュース関連`(抽象的すぎて選ばれない)
- 良い例:`description: 朝のニュースと、X上のAI関連の話題を要約してTelegramに届ける`

## CronにSkillを紐付ける

ここで第9回とつながる。第9回で作った`morning-news`のCronジョブは、長いプロンプトをジョブ本文に直書きしていた。これを、いま作ったSkillの**添付**に置き換える。「組み込みSkillを見る」で`hermes tools`に出ていた`Cron Jobs … with optional attached skills`が、この機能の正体だ。

Cronの登録・編集は、第9回と同じくVPSのターミナルで`hermes cron`を使う(Telegramの`/cron`は「Unknown command」になる)。`hermes cron edit`は対話エディタではなく、オプションを引数で渡す形式だ。

```bash
hermes cron list                                # morning-news の job_id を確認

# job_id を指定して、skillを添付しつつプロンプトを短い指示に置き換える
hermes cron edit <job_id> --add-skill morning-news --prompt 'morning-news スキルの手順でニュース要約を実行して'
```

`hermes cron edit`の主なオプションはこう。

| オプション | 役割 |
|---|---|
| `--add-skill <名前>` | Skillを添付(繰り返し指定で複数添付) |
| `--skill <名前>` | 添付Skillを総入れ替え |
| `--remove-skill <名前>` | 添付を個別に外す |
| `--clear-skills` | 添付を全部外す |
| `--prompt '...'` | 指示文を差し替え |
| `--schedule '...'` | 実行時刻を変更 |

実行すると`Updated job`と`Skills: morning-news`が表示され、ジョブにSkillが付いたことが分かる。プロンプトは「どのSkillの手順でやるか」を1行書けばよく、第9回のような長文はもう要らない。手順の中身は`SKILL.md`の側にあるからだ。

![hermes cron edit <job_id> --add-skill morning-news --prompt '...'を実行し、Updated jobとSkills: morning-newsが表示された画面](/images/hermes-vps/hermes-vps-10-cron-add-skill.png)

第9回と同じく、明日の朝を待たずにテスト実行できる。

```bash
hermes cron run <job_id>
```

`run`は「次のスケジューラのtickで実行する」予約で、常駐中のgatewayが1〜2分でそれを拾い、要約をTelegramに届ける。

![hermes cron run <job_id>を実行し、Triggered jobと「次のtickで実行する」旨が表示されたターミナル画面](/images/hermes-vps/hermes-vps-10-cron-run-skill.png)

![少し待つと、Telegramに「Cronjob Response: morning-news」としてニュース要約が届いた画面。冒頭に「X検索は利用不可だったため、HN/Web中心で代替しました」とあり、SKILL.mdのPitfallsどおりに動いている。bot名はHermes VPS](/images/hermes-vps/hermes-vps-10-cron-skill-result.png)

届いた要約の冒頭に「X検索は利用不可だったため、HN/Web中心で代替しました」と出ているのに注目したい。これは`SKILL.md`の`Pitfalls`に書いた「X検索が無効な場合はWeb検索で代替する」が、そのまま実行されている証拠だ。手順をファイルに書いておくと、こうした例外処理まで毎回同じように効く。

:::message
これで、ニュース要約の手順を変えたい時は`~/.hermes/skills/morning-news/SKILL.md`を直すだけでよくなった。Cronジョブの側は触らない。件数を変える、出典の付け方を変える、といった調整が1箇所で完結し、同じSkillをTelegramの`/morning_news`からも会話からも呼べる。これが「Cron=いつ動くか」と「Skill=どうやるか」を分ける意味だ。
:::

## Skills Hubから足す

同梱の85件はすでに全部使える。Skills Hubは、その**外側**のSkillを足す仕組みだ。ここでは例として、Web検索のフォールバック用`duckduckgo-search`を入れてみる。第11回のWeb検索回への布石にもなる。

### 検索して中身を下見する

```bash
hermes skills search duckduckgo                       # キーワードで検索
hermes skills inspect official/research/duckduckgo-search   # 入れる前に中身を見る
```

`search`で候補が並び、`inspect`で入れる前に中身を確認できる。組み込みでは使えなかった`inspect`が、Hubでは本来の「インストール前プレビュー」として効く。

![hermes skills search duckduckgoの結果。最上段のduckduckgo-searchはSource/Trustがofficial、残りはclawhub/communityで、同じ用途でも信頼レベルが混在しているのが分かる画面](/images/hermes-vps/hermes-vps-10-hub-search.png)

![hermes skills inspect official/research/duckduckgo-searchのプレビュー。frontmatterにweb検索の代替として動く設定が見える画面](/images/hermes-vps/hermes-vps-10-hub-inspect.png)

### 信頼レベルを確認してから入れる

Hubから入れる時に必ず見るのが`Trust`列だ。Skillは外部のコードを持ち込むので、どこの誰が作ったかで扱いが変わる。

| Trust Level | ソース例 | 判断 |
|---|---|---|
| `builtin` | Hermes Agent本体に同梱 | 常に信頼(同梱の85件) |
| `official` | 本体に同梱されているが既定では無効なSkill | 本体相当。警告なし |
| `trusted` | openai/anthropics/huggingface/NVIDIA/garrytanの公式配布 | 比較的安全。中身は確認 |
| `community` | 上記以外すべて | 個別に中身を読んでから判断 |

さきほどの検索結果がそのまま実例になっている。`duckduckgo`で出た候補のうち`Trust`が`official`は最上段の1件だけで、残りは`community`(`Source`列が`clawhub`)だった。**同じ用途でもofficialとcommunityが混ざる**ので、入れる前に`Trust`列と`inspect`の中身を必ず確かめる。今回は安全な`official/research/duckduckgo-search`を選ぶ。

:::message alert
「インストール」には実は2種類ある(実機で確認)。
- **official**(今回の`duckduckgo-search`):これは本体に同梱されているが既定では無効なSkill。インストール画面に`It ships with hermes-agent but is not activated by default`と出る。つまり「外部から取得」ではなく「同梱されている予備のSkillを有効化(skillsディレクトリにコピー)」する操作。安全側
- **community**(検索結果の`clawhub`の候補):これが本当の外部取得。中身を読んでから入れる

今回は安全なofficialで「Hubから足す手順」を体験する。
:::

### インストールする

```bash
hermes skills install official/research/duckduckgo-search
```

実行するとセキュリティスキャンが走り、データ流出・プロンプトインジェクション・破壊的コマンド・サプライチェーン異常をチェックする。officialの場合は`Verdict: SAFE`、`Decision: ALLOWED (builtin source, safe verdict)`と進み、最後に`Install 'duckduckgo-search'? Confirm [y/N]:`の確認が出る。`Y`で実行すると`Installed: research/duckduckgo-search`と完了し、`~/.hermes/skills/research/duckduckgo-search/`に置かれる。

![hermes skills installを実行し、Running security scan・Verdict: SAFE・Decision: ALLOWEDと、Official Skillの説明が表示された画面](/images/hermes-vps/hermes-vps-10-hub-install.png)

:::message
`dangerous`判定が出たSkillは`--force`を付けても入れられない設計になっている。中身を手で確認するか、別のSkillで代替する。
:::

インストール後にもう一度集計行を見ると、`hub-installed`が1件に増えている。この回の通しで、集計行は`85 builtin`(初期)→`1 local`を追加(morning-news作成)→`1 hub-installed`を追加(duckduckgo-search導入)と動き、最終的に`1 hub-installed, 85 builtin, 1 local — 87 enabled`になる。

![hermes skills list | tail -3で集計行が「1 hub-installed, 85 builtin, 1 local — 87 enabled, 0 disabled」に変わった画面](/images/hermes-vps/hermes-vps-10-hub-list.png)

更新と削除も覚えておく。`hermes skills check`で更新の有無を確認、`hermes skills update`で更新を取り込み、`hermes skills uninstall <名前>`で削除する。Hubは内部でGitHubを見るので、たくさん操作するとレート制限に当たることがある。`~/.hermes/.env`に`GITHUB_TOKEN=...`を入れておくと上限が上がる。

## Skillにファイルを添付する

ここからは**概念の紹介**にとどめる(実機の操作は次の段階で必要になったら)。

Skillが育ってくると、`SKILL.md`本文に全部書くと長くなりすぎる場面が出てくる。「信頼できるニュースソースの一覧」「除外したい話題」「重複を除く補助スクリプト」などだ。こうした細かい資料は、Skillディレクトリの中に別ファイルとして置く。

```text
~/.hermes/skills/morning-news/
├── SKILL.md
├── references/
│   ├── trusted-sources.md     # 信頼できるニュースソース一覧
│   └── exclusions.md          # 除外したい話題
└── scripts/
    └── deduplicate.py         # 重複記事を除く補助スクリプト
```

`SKILL.md`の本文からは「`references/trusted-sources.md`にあるソースだけを対象にする」のようにファイル名で参照する。これらの添付ファイルが、Progressive DisclosureのLevel 2だ。本文(Level 1)に長いリストやコードを書き切るとトークン消費が毎回増えるので、必要な時だけ読む添付ファイルに逃がす、というのがコツになる。

もう一段踏み込むと、`SKILL.md`本体は手順だけで短く(目安100行以内に)保ち、APIのクセ・長い一覧・補助スクリプトは`references/`・`scripts/`に逃がすのがよい。本文が短いほど呼び出しのたびのトークンが軽くなり、セッションを重ねるほどコスト差は複利で効いてくる。

まずは1ファイルの`SKILL.md`(この回の`morning-news`)で十分だ。添付ファイルは、自作Skillを育てていく中で「本文が長くなってきた」と感じたら使う応用と考えておけばよい。

## まとめと第11回予告

第10回でやったこと。

- `~/.hermes/skills/morning-news/SKILL.md`を1枚作り、第9回の長いプロンプトをSkill化
- `frontmatter`の`description`を具体的に書き、Progressive DisclosureのLevel 0で選ばれるようにした
- Telegramから`/reload_skills`→`/morning_news`で呼べることを確認(呼び出し名はアンダースコア区切り)
- 第9回のCronジョブを`hermes cron edit --add-skill`でSkill添付に置き換え、プロンプトを1行に短縮
- Skills Hubから`duckduckgo-search`を導入し、`Trust`レベル(builtin/official/trusted/community)の見方を確認

これで、第9回まで「決まった時刻に長いプロンプトを流す」だったエージェントが、「自分専用の手順を覚え、Telegramからもニュース配信からも同じ手順を呼ぶ」状態になった。手順はファイルとして残り、会話履歴を消しても消えない。使うほど`~/.hermes/skills/`に手順がたまり、自分専用に育っていく。

第11回はWeb/X検索の使い分けだ。今回のニュース要約で「X検索は利用不可だったため代替した」と出たとおり、検索の質はSkillの出力をそのまま左右する。第11回ではHermes Agentが使える複数のWeb検索バックエンド(Firecrawl/SearXNG等)とX Searchを整理し、どれを有効にするかを決める。

---

| ← 前の回 | 次の回 → |
|---|---|
| 第9回 Cronで毎朝の定型を任せる | 第11回 Web検索とX検索を使い分ける(近日公開) |

📑 [シリーズ全12回のもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## よくあるエラーと対処

| 症状 | 対処 |
|---|---|
| 自作Skillが`hermes skills list`に出ない | 1) ディレクトリ名と`name:`フィールドが一致しているか、2) `frontmatter`の`---`が前後にあるか、3) `hermes skills reset <名前>`で一覧を作り直す |
| Telegramで`/skill_name`が「Unknown command」 | 1) 区切りはアンダースコア(`/morning_news`。`/morning-news`は不可)、2) 追加直後はgatewayが未認識なので`/reload_skills`で取り直す、3) スラッシュ名はディレクトリ名ではなく`frontmatter`の`name:`から作られる |
| Skillは呼ばれるが期待通りに動かない | `description`/`Procedure`/`Verification`を書き直す。特に`description`が抽象的だとエージェントが選ばない |
| 組み込みSkillの中身を`inspect`で見ようとすると別物が出る | `inspect`はHub用。組み込みは`cat ~/hermes-agent/skills/<カテゴリ>/<名前>/SKILL.md`で直接開く |
| Hubのインストールで`HTTP 403` | GitHub APIのレート制限。`~/.hermes/.env`に`GITHUB_TOKEN=...`を設定 |
| Hub Skillが`dangerous`判定 | `--force`でも入れられない。中身を手で確認するか別Skillで代替 |
| HubのSkillを自分で編集したら更新で上書きされた | Hermesは「自分が触ったSkill」を追跡して更新から守る設計。挙動がおかしい時は`hermes skills reset <名前>`で追跡をクリアし、公式版に戻すなら`hermes skills repair-official`。自作・編集したSkillはgitでバックアップしておくと安心 |

## 公式ドキュメント引用元

| 項目 | 引用元 |
|---|---|
| Skills全般 | [features/skills](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills) |
| SKILL.mdの書式(frontmatter) | 同上「SKILL.md Format」 |
| Progressive Disclosure(Level 0/1/2) | 同上「Progressive Disclosure Pattern」 |
| スラッシュコマンドでの呼び出し | 同上「Every installed skill is automatically available as a slash command」 |
| Skills Hub(official/community等のソース) | 同上「Supported Hub Sources」 |
| Trust Level(builtin/official/trusted/community) | 同上「Security Scanning & Trust Levels」 |
| サブコマンド・85 builtin・config・tools連携・呼び出し名・`/reload_skills`・`--add-skill` | 実機v0.15.1で確認(2026-06-01)。`hermes skills --help` / `hermes skills list` / `hermes tools` / `hermes cron edit --help` |
