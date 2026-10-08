---
title: "【第13回】メモを自分で探すな。Hermes AgentはObsidianを記憶として読む"
emoji: "📚"
type: "tech"
topics: ["ai", "hermes", "obsidian", "vps", "claude"]
published: true
---

:::message
**この記事をAIに読ませる**

この記事はGitHubの公開リポジトリで管理していて、本文のMarkdownをそのまま取得できる。Claude CodeやCodexなどのAIエージェントに手順を任せたいときは、次のURLを渡すだけでいい。

https://raw.githubusercontent.com/Sora-bluesky/zenn-articles/main/articles/hermes-vps-13-obsidian.md

頼み方の例:「この記事を読んで、私の環境で手順を順番に実行して」に上のURLを添える。
:::

:::message
この連載は月1,800円ほどのVPSで、自分専用のAIエージェント(Hermes Agent)を24時間動かす実録だ。これはその第13回。全体の流れは[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::

## 目次

- [この回の到達点](#この回の到達点)
- [なぜObsidianを連携するのか](#なぜobsidianを連携するのか)
- [第IV部の4つの機能を1分で](#第iv部の4つの機能を1分で)
- [第13回終了時点の構成図](#第13回終了時点の構成図)
- [事前準備](#事前準備)
- [bundled obsidian skillの確認](#bundled-obsidian-skillの確認)
- [Vault実体の準備](#vault実体の準備)
- [4経路の整理](#4経路の整理)
- [動作確認(HermesにVault参照を依頼)](#動作確認(hermesにvault参照を依頼))
- [AIが読めるノートの書き方](#aiが読めるノートの書き方)
- [自分のパソコンとVPSのVault同期](#自分のパソコンとvpsのvault同期)
- [3エージェントで同じVaultを読む](#3エージェントで同じvaultを読む)
- [Vaultは配布対象外](#vaultは配布対象外)
- [まとめと第14回予告](#まとめと第14回予告)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [操作早見表](#操作早見表)
- [引用元と参考](#引用元と参考)

第13回が終わると、HermesはObsidian Vaultのノートを読み書きできる。Memoryに収まらない「長く残しておきたい情報」を、Memoryとは別のカテゴリで持てる状態だ。

第12回でHermes本体のMemory機能を入れ、USER.mdとMEMORY.mdの2枚に「私のこと」と「環境ファクト」を覚えさせた。frozen snapshotで毎セッション自動注入される設計のおかげで、新しいチャットを開くたびに自己紹介をやり直す必要はもうない。ただ、Memoryの上限は合計3,575字しかない。気になった記事の保存、論文や調べごとのメモ、過去の議事録、書きかけの下書きといった情報までUSER.mdに詰め込むと、すぐに上限に達する。

そこで第13回は、Memoryの外に置く知識ベースとしてObsidian Vaultを足す。HermesにVaultを読ませ、字数を気にせずノートを溜められるようにする。skillはHermes本体にbundledで入っているので、新規インストールは要らない。`~/.hermes/.env`も触らない。

シリーズの全体像はこちら。

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
- **第13回**(本記事) メモを自分で探すな。Hermes AgentはObsidianを記憶として読む
- [第14回](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) 毎回最初から話すな。Hermes Agentは前回の続きからそのまま動く
- [第15回](https://zenn.dev/sora_biz/articles/hermes-vps-15-import-ai-sessions) 記憶を捨てるな。Hermes AgentはClaude Codeの続きを引き継ぐ

全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

手を動かすのは2つだ。bundled `obsidian` skillが入っていることを確認し、VPS側のVaultディレクトリへのショートカット(symlink)を1本作る。あとはTelegramから「Vaultにメモを書いて」と頼めば、エージェントがbundled `obsidian` skillを使ってVault内に.mdファイルを作る。自分のパソコン(この連載ではWindows)とVPSのVaultをgitで同期する最小構成も作るが、Hermesが書いたノートをそのまま自動で同期するところまでは、この回ではやらない。

## この回の到達点

第13回が終わると、Hermesは「Memoryに収まらない、長く残しておきたい情報の置き場」を持つ。置き場はObsidian Vaultで、HermesはVault内の.mdファイルを読み書きできる。環境変数は設定しない。やらないこと(3エージェント共用の本格実装、Hermesが書いたノートの自動git同期)は後の回に回す。

第12回完了時と第13回完了後の差分を表にする。

| 項目 | 第12回完了時 | 第13回完了後 |
|---|---|---|
| 記憶できる範囲 | 「私のこと」(USER.md 1,375字)+「環境ファクト」(MEMORY.md 2,200字) | +「長く残しておきたい情報」(Obsidian Vault・字数無制限の知識ベース) |
| 記憶の置き場 | VPS内の`~/.hermes/memories/`のみ | +自分のパソコンのObsidian Vault(VPSとgitで同期) |
| HermesがVaultを読むか | 読まない | bundled `obsidian` skillでVault内.mdをファイル直アクセスで読み書き |
| 3エージェント共有 | VaultはClaude Code/Codexの個別管理 | 同じVaultをHermes/Claude Code/Codexの3つで共用(本格実装は第21回予定) |
| 配布対象 | USER.md/MEMORY.mdは個人所有で配布除外 | Vaultも同じく個人所有で配布除外(第43回Profile Distributionsで詳述) |

この回で出てくる用語を先に押さえておく。

| 用語 | 意味 |
|---|---|
| Vault(ボールト) | Obsidianが管理するノートの置き場。物理的にはMarkdownファイル(.md)が並んだフォルダ。1つのVaultが、Memoryの外に置く1つの知識ベースになる |
| bundled skill | Hermes本体の`.bundled_manifest`に登録されているskill。`obsidian`はその1つ。多くの場合は実体までシードされて`hermes skills list`に出るが、初期インストール時の状況によっては実体だけ未シードで`reset --restore`が必要なことがある |
| `OBSIDIAN_VAULT_PATH` | HermesがどのVaultを読むかを指定する環境変数。本回ではSKILL.md標準のフォールバック先をそのまま使うため設定不要 |
| Wikilink | Obsidianのノート間リンク記法。`[[ノート名]]`で他のノートを参照する。Hermesはこのリンクをたどって文脈を組み立てる |
| 5項目テンプレ | Hermesに読ませるノートの基本構造。Title/Summary/Source/Context/Links/Next Actionの6つの見出しで揃える |

## なぜObsidianを連携するのか

第12回で入れたMemoryには容量の上限がある。気になった記事や調べごと、長い記録をすべてUSER.mdに記憶させようとすると、すぐに1,375字に達してしまう。長く残しておきたい情報はObsidian Vaultに貯め、Memoryとは別カテゴリで持つ。

### Memory三層では届かない「知識」の置き場

第12回のMemoryは三層(Markdown第1層・SQLite第2層・外部provider第3層)で構成されるが、合計でも数千字の規模だ。「名前はそら」「妻と高校生の娘」のような人物カードは収まる。だが調べものの記事、読んだ論文のメモ、自分が書いた過去の記事の下書きまでMemoryに入れようとすると、たちまち上限に達する。

気になった記事や調べごと、書き溜めたメモはMemoryには入れず、Obsidian Vaultに置く。容量制限はファイルシステムの空きだけで、何万字でも入る。

### 「私のこと」と「世界のこと」を分ける

分け方は次のとおり。

| 層 | 覚えるもの | 例 |
|---|---|---|
| Memory(USER.md/MEMORY.md) | 私のこと=毎セッション必要な前提 | 名前・年齢・家族構成・好み・主な仕事・記事の文体ルール |
| Obsidian Vault | 長期保存したい知識 | 気になった記事のメモ・調べごとの記録・書きかけの下書き・プロジェクトの設計メモ |

Memoryは毎セッション開始時にfrozen snapshotで自動注入される。Vaultはskill経由で必要なときだけ参照する。役割が違うから両方持つ。

## 第IV部の4つの機能を1分で

第IV部で出てくる機能は4つある。それぞれに何が入っていて、いつ読まれる(動く)のかを、この連載で実際に動かした中身で並べる。

| 機能 | 何が入っているか | いつ読まれる・動くか | 本連載の該当回 |
|---|---|---|---|
| Memory(USER.md/MEMORY.md) | 上限は合計3,575字(USER.md 1,375字+MEMORY.md 2,200字)。名前・年齢・家族構成・好み・主な仕事・記事の文体ルール | 毎セッション開始時に自動で注入される | 第12回 |
| Obsidian Vault | 字数の上限はなく、容量はVPSの空きだけ。気になった記事のメモ、調べごとの記録、下書き、設計メモ。この回で`Hermes動作テスト.md`(81バイト)を作り、`/home/admin/hermes-vault`で確認した | 「Vaultに保存して」と頼んだときなど、`obsidian` skillが呼ばれたときだけ | **本回(第13回)** |
| Skills | 手順の定義。この回で使う`obsidian` skillは`~/.hermes/skills/note-taking/obsidian/SKILL.md`にあり、`search_files`/`read_file`/`write_file`/`patch`の4つのツールを使うと宣言している | 依頼の内容に合う手順が必要になったとき。この回では、Telegramで「Vaultに保存して」と頼むとHermesが`skill_view obsidian`を実行した | 第10回・第18回予定 |
| Cron | 実行時刻・プロンプト・配信先のセット。第9回で作った`morning-news`は毎日7時0分、配信先はTelegram | 指定した時刻になったとき。依頼する人がいなくても動く | 第9回・第19回予定(Curator) |

第12回(Memory)→第13回(Vault)→[第14回](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search)(過去会話の検索)→[第17回](https://zenn.dev/sora_biz/articles/hermes-vps-17-soul)(話し方を決めるSOUL.md)と並ぶ。本回は、第12回のMemoryとVaultで、入れるものを分ける話だ。

:::message
「Memoryにすべて詰め込まなくていい」。私のこと(毎回使う前提)はMemoryに残し、長く残しておきたい情報はVaultに移す。この2つを分けると、毎回同じ説明をする回数が大きく減る。
:::

## 第13回終了時点の構成図

HermesとObsidian Vaultがどう繋がるかを俯瞰する。第12回で書いた三層メモリ(Markdown/SQLite/外部provider)の右隣にObsidian Vaultが別カテゴリで並ぶ。

![Hermes Agentの内蔵メモリ(三層=Markdown/SQLite/外部provider)とObsidian Vault(自分のパソコンのローカル)が、bundled obsidian skill+ホスト側symlinkを介して役割分担する構成図](/images/hermes-vps/hermes-vps-13-obsidian-architecture-diagram.png)

接続レイヤーは4つだが、本回で使うのは上2つだけだ。

| レイヤー | 役割 | 本回での扱い |
|---|---|---|
| bundled `obsidian` skill | HermesがVault内の.mdをファイル直アクセスで読み書きする手順を定義したskill | 本回の中心 |
| `OBSIDIAN_VAULT_PATH`環境変数 | どのVaultを読むかを指定する1行設定 | 本回では使わない(SKILL.mdのフォールバック先をそのまま採用) |
| Obsidian MCPサーバー | Obsidianプラグイン経由のAPI(検索・グラフ操作) | 本回は使わない |
| git同期 | 自分のパソコンのVaultとVPS側のVaultを揃える | 基本のgit push/pullを扱う |

## 事前準備

第12回までが完了していれば、追加で入れるものはない。VPSへSSHで入って稼働を確認し、自分のパソコンのObsidian Vaultの場所を控える。

### VPSのバージョン確認

VPSにSSHで入り、Hermesのバージョンと常駐サービスの稼働を確認する。

```bash
ssh admin@hermes-vps

hermes --version                                  # v0.17.0(2026.6.19 The Reach Release)以降を確認
systemctl --user status hermes-gateway          # active (running)
```

![ターミナルでhermes versionを実行した結果。Hermes Agent v0.17.0(2026.6.19)upstream bb7ff7dc、Project /home/admin/hermes-agent、Python 3.11.15、OpenAI SDK 2.24.0、Up to date が並ぶ画面](/images/hermes-vps/hermes-vps-13-version-check.png)

v0.17.0より古いバージョンが出る場合は、`hermes update`で本体を最新に上げてからやり直す。v0.17.0ではOffice読み込みのread_file拡張など、本回のObsidian連携と相性のいい機能がいくつか追加されている。

### 自分のパソコンのObsidian Vaultの場所を控える

自分のパソコン(この連載ではWindows)でObsidianを起動し、Vault管理画面でVaultの絶対パスを確認する。Windowsなら`C:\Users\<name>\Documents\Obsidian Vault\`のような場所が一般的だ。

Obsidianを未導入なら公式サイトから入れてVaultを1つ作る。中身は空でよい。

![自分のパソコンの画面を左右に並べた様子。左はWindowsエクスプローラーで`ドキュメント\Hermes-Vault\`に`.obsidian\`フォルダと空の`無題のファイル.md`(0 KB・新規作成時の自動生成ファイル)が並ぶ画面・右はObsidianアプリでHermes-Vaultを開いた直後の画面で「無題のファイル」タブが1つ・本文は空](/images/hermes-vps/hermes-vps-13-vault-location.png)

このあとの§7では「VPS側にVault実体を作り、`/home/admin/hermes-vault`からショートカットで読み書きできる形にする」手順を扱う。自分のパソコンのパスをそのまま転記するわけではない。自分のパソコンとVPSのVaultを揃えるのは§11で扱うgit同期の役目だ。

## bundled obsidian skillの確認

Hermes本体の`~/.hermes/skills/.bundled_manifest`には`obsidian`がbundled skillとして登録されている。多くの場合は`~/.hermes/skills/note-taking/obsidian/SKILL.md`に実体がシードされていて`hermes skills list`に並ぶが、初期インストール時の状況によってはmanifestに登録されているのに実体だけシードされていないことがある(v0.17.0を実際に動かして観測)。まずskillが存在することを確認し、無ければ復旧してから先に進む。

### skill一覧でobsidianを探す

bundled skillの一覧に`obsidian`が出るかを確認する。

```bash
hermes skills list
```

出力の中に`obsidian`(`note-taking`カテゴリ)があれば配置済みで、そのまま§7に進める。

もしobsidianが出ない場合は、manifestに登録があっても実体ファイルがシードされていない状態だ。次のコマンド1発で復旧する。

```bash
hermes skills reset obsidian --restore --yes
```

このコマンドは`.bundled_manifest`の`obsidian`エントリを参照して、`~/.hermes/skills/note-taking/obsidian/`配下に実体ファイル一式を再コピーする。実行後にもう一度`hermes skills list`を打つとobsidian行が並ぶ。

![ターミナルでhermes skills listを実行した結果。表形式の出力にobsidian行が並んでいる画面。Categoryはnote-taking、Sourceはbuiltin、Trustはbuiltin、Statusはenabled](/images/hermes-vps/hermes-vps-13-skills-list-obsidian.png)

### SKILL.mdの中身を確認する

skillの定義ファイルSKILL.mdを表示して、中身を確認する。

```bash
cat ~/.hermes/skills/note-taking/obsidian/SKILL.md
```

冒頭のYAMLフロントマター(`---`で囲まれた領域)で、必要な環境変数(`OBSIDIAN_VAULT_PATH`)、未設定時のフォールバック(`~/Documents/Obsidian Vault`)、使うツール(`search_files`/`read_file`/`write_file`/`patch`)が宣言されている。

![ターミナルでcat ~/.hermes/skills/note-taking/obsidian/SKILL.md | head -20 を実行した結果。冒頭のYAMLフロントマター(name obsidian / description Read, search, create, and edit notes in the Obsidian vault. / platforms [linux, macos, windows])の下に、Obsidian Vault見出し+概要+Vault path節(OBSIDIAN_VAULT_PATH環境変数とフォールバック~/Documents/Obsidian Vault)+file toolsの注意書きが並ぶ画面](/images/hermes-vps/hermes-vps-13-skill-md-head.png)

:::message
SKILL.mdは、Hermesがこのskillで何をするかを書いた手順の定義だ。HermesがVaultをどう触るかは、ここに書かれた手順をHermesが読んで自分で組み立てる。読者がSKILL.mdを直接書く必要はないが、一度読んでおくと「skillとは何か」が分かる(第10回Skillsの復習)。
:::

## Vault実体の準備

Hermes本体は標準で`~/Documents/Obsidian Vault`という場所にVaultがあると想定して動く(bundled obsidian skillに記載されたフォールバック先)。VPSのHermesはコンテナ内でこのpathを見るため、ホスト側の実体は`~/.hermes/sandboxes/docker/default/home/Documents/Obsidian Vault/`という長いpathに置く。

毎回この長いpathを打つのは大変なので、`/home/admin/hermes-vault`からショートカット(symlink)を1本張って、短いpathで読み書きできる形にする。

### 実体ディレクトリの作成

VPSにSSHで入った状態で、Hermesが書く実体ディレクトリを作る。

```bash
ssh admin@hermes-vps
mkdir -p ~/.hermes/sandboxes/docker/default/home/Documents/Obsidian\ Vault
```

末尾の`\ `は「半角スペース」を含むpathを正しく扱うためのエスケープ記号(`Obsidian Vault`の間のスペース)。

### ショートカット(symlink)の作成

長いpathを毎回打たなくて済むよう、`/home/admin/hermes-vault`からショートカットを張る。

```bash
ln -sf ~/.hermes/sandboxes/docker/default/home/Documents/Obsidian\ Vault /home/admin/hermes-vault
ls -la /home/admin/hermes-vault
```

`ls -la`の出力で`lrwxrwxrwx ... /home/admin/hermes-vault -> /home/admin/.hermes/.../Obsidian Vault`の形が出ればOK(`l`はsymlinkの印・`->`の後に実体pathが見える)。

![ターミナルで`ls -la /home/admin/hermes-vault`を実行した結果。先頭が`l`から始まるsymlinkを示す行で、矢印`->`の後にサンドボックス配下の実体pathが表示されている。プロンプトのホスト名は黒塗りマスク済](/images/hermes-vps/hermes-vps-13-symlink-ls.png)

これで`/home/admin/hermes-vault`からVaultの中身を読み書きできる状態になった。Hermesがコンテナ内で`~/Documents/Obsidian Vault`に書いたファイルは、ホストではsymlink経由で`/home/admin/hermes-vault`にも同時に見える(物理的には同じファイル)。

:::message
環境変数`OBSIDIAN_VAULT_PATH`を`.env`で設定して任意のpathに変える流儀も公式で用意されているが、Hermes本体側で環境変数の取り扱いが今後変更される可能性があるため、本回では標準のフォールバック先をそのまま使う(設定不要)。`.env`で別pathを指定する応用は将来の発展回で扱う。
:::

## 4経路の整理

HermesとObsidianの接続経路は混乱しやすい。本回で使うのはbundled `obsidian` skillだけで、環境変数は設定しない。ほかの選択肢の存在を整理しておく。

### skill経由/環境変数/MCP/git同期

| 経路 | 役割 | 本回での扱い |
|---|---|---|
| bundled `obsidian` skill | HermesがVault内の.mdをファイルアクセスで読み書きする | 本回の中心。§6で確認・§9で動作確認 |
| `OBSIDIAN_VAULT_PATH`環境変数 | どのVaultを読むかを指定する | 本回では使わない(SKILL.mdのフォールバック先をそのまま採用・将来の発展回で扱う) |
| Obsidian MCPサーバー | Obsidianプラグイン経由のAPI(検索・グラフ・タグ操作) | 本回は使わない。skill主軸で十分 |
| git同期 | 自分のパソコンのVaultとVPSのVaultを揃える | §11で扱う(基本=git push/pull手動) |

![ターミナルで`hermes mcp list`を実行した結果。MCP Servers見出しの下にName/Transport/Tools/Status列のテーブルが1行だけ並び、agentwikis (npx -y agentwikis-mcp/all/✓ enabled)のみ表示。Obsidian用MCPは存在しない](/images/hermes-vps/hermes-vps-13-mcp-list.png)

MCPサーバー経由のObsidian連携は、リアルタイム検索やグラフ操作が必要になったときの選択肢だ。本連載は当面skill主軸で運用する。

### memory providerにobsidianが入らない理由

第12回§12で外部memory provider 8つ(byterover/hindsight/holographic/honcho/mem0/openviking/retaindb/supermemory)を概観したが、この一覧に`obsidian`は入っていない。

```bash
hermes memory --help
# providers: honcho, openviking, mem0, hindsight, holographic, retaindb, byterover, supermemory
```

![ターミナルで`hermes memory --help`を実行した結果。usageとサブコマンド(setup/status/off/reset)の説明文の中に「Available providers: honcho, openviking, mem0, hindsight, holographic, retaindb, byterover」と並び、Obsidianはこのprovider一覧に含まれていない](/images/hermes-vps/hermes-vps-13-memory-help-providers.png)

Obsidianはmemory providerではなく、note-taking skillとして提供されている。第12回の三層で言えば第3層(外部provider)には当たらず、別カテゴリになる。memoryコマンドで設定するものではない。Vault連携はbundled obsidian skill(§6)+ホスト側symlink(§7)の2本立てで行う。これが正しい経路だ。

## 動作確認(HermesにVault参照を依頼)

設定が効いているかをTelegramからHermesに頼んで確認する。VPS側のVaultにファイルが実際に生成されるかを`ls`で確認するまでを、この章で扱う。

### TelegramからVault参照を依頼する

自分のパソコンからTelegramを開いて、Hermesに頼む。

```text
Hermesテストノートを作って。タイトルは「Hermes動作テスト」、本文に「2026年6月24日、第13回でObsidian連携を試した」と書いて、Vaultに保存して。
```

![自分のパソコンからTelegramでHermesに依頼した直後の画面。依頼テキストの下にHermesの応答が並び、skill_view obsidian+terminalでecho `${OBSIDIAN_VAULT_PATH:-~/Documents/Obsidian Vault}`+`ls -la /root/hermes-vault`を実行した後、write_file `/root/hermes-vault/Hermes動作テスト.md`で保存完了。最終応答に保存先パスとノート本文プレビューが含まれている](/images/hermes-vps/hermes-vps-13-telegram-save-request.png)

エージェントはSKILL.mdの手順に従って、内部で`write_file`ツールを呼びVault内に.mdファイルを書き込む。Telegramには「保存しました」のような自然文で応答が返ってくる。応答の本文にVaultパスとファイル名が含まれていれば成功だ(Hermesの応答に出る`/root/hermes-vault`はコンテナ内のビュー・ホスト側ではsymlink経由で`/home/admin/hermes-vault`から同じファイルが見える)。

### 自分のパソコンとVPSのVaultで実体を確認する

VPS側のVaultに.mdファイルが実体として作られたかを、`ls`と`cat`で確認する。

```bash
ls -la /home/admin/hermes-vault/
# Hermes動作テスト.md のようなファイルが増えている
cat /home/admin/hermes-vault/Hermes動作テスト.md
```

![ターミナルで`ls -la /home/admin/hermes-vault/`を実行した結果。`total 12`の下に`.`と`..`に続いて`-rw------- 1 admin admin 81 Jun 24 10:39 Hermes動作テスト.md`が並んでいる。所有者はadmin:adminで、sudoなしで読める。プロンプトのホスト名は黒塗りマスク済](/images/hermes-vps/hermes-vps-13-vault-ls.png)

自分のパソコンのObsidianとVPSのVaultを§11のgit同期でつなげば、ここで作られたノートが自分のパソコンのObsidianアプリにも現れる。Hermesが代わりにノートを書く動作は、ここまでで確認できた。

## AIが読めるノートの書き方

Vault接続ができたら、次の問いは「で、何を書けばいいのか」になる。Hermesが迷わず読めるノートには共通の構造がある。実際に運用して確認した設計パターンとして、5項目テンプレと「Hermesが迷うノートの4特徴」を紹介する。

### 5項目テンプレ──Title/Summary/Source/Context/Links/Next Action

1枚のノートに次の5つの見出しを置く。これだけでHermes・Claude Code・Codexの3エージェントが再利用しやすい構造になる。

```markdown
# Title(対象と用途が分かるもの)

## Summary
このノートは何か。3行以内。

## Source
どこから来た情報か。URL・書籍名・会話・日付など。

## Context
なぜ保存したか。自分の目的・前提・判断材料。

## Links
関連ノート・プロジェクト・人物・記事。
[[ノート名]] 形式で他のノートを参照する。

## Next Action
AIまたは自分が次に何をすればいいか。
```

![自分のパソコンのObsidianでVault「Hermes-Vault」を開き、5項目テンプレを当てた`Hermes Agent調査.md`を表示している画面。Title/Summary/Source/Context/Links/Next Actionの6見出しが本文中に並び、それぞれに雛形テキスト(「対象と用途が分かるもの」「3行以内」「URL・書籍名・会話・日付など」など)が入っている。左ペインはファイルリスト、左下にVault名「Hermes-Vault」、右下は文字数カウンタ](/images/hermes-vps/hermes-vps-13-template-applied-note.png)

5項目それぞれが、Hermesにとって判断材料になる。SummaryでノートのID、Sourceで信頼度、Contextで目的、Linksで他文脈、Next Actionで作業指示。これらが分離して書かれていれば、Hermesは「事実」と「自分の解釈」と「次の作業」を取り違えない。

### AIが迷うノートの4特徴

裏返しに、次のような書き方をするとHermesは判断に迷う。

| 特徴 | 何が問題か |
|---|---|
| タイトルがあいまい | 「AIメモ」「あとで読む」のような汎用タイトル。Hermesは「これは何の話?」を本文を全部読まないと判断できない |
| 出典・引用・感想が混ざっている | 「事実」「自分の解釈」「次の作業指示」が同じ段落に並ぶ。Hermesは「これは事実か感想か」を取り違えやすい |
| 関連リンクがない(孤立ノート) | 1枚で完結していて他のノートと繋がっていない。Hermesは文脈を組み立てられない |
| Next Actionが書かれていない | 「で、次に何をすればいい?」がノートに書かれていない。Hermesに作業を任せようとすると毎回プロンプトに足す必要がある |

### テンプレ適用前後の比較

5項目テンプレの有無で、同じ題材のノートがどう変わるかを見比べる。例として「Hermes Agentを調べた」という同じ題材を、雑に書いたAIメモと、5項目テンプレで整理したノートで並べてみる。

**適用前(雑なAIメモ)**

![自分のパソコンのObsidianでVault「Hermes-Vault」を開き、`AIメモ.md`を表示している画面。本文は「最近Hermes調べた。よさそう。あとで読む記事=https://...」「インストール簡単」「設定ファイル多い気がする」「明日続きやる」が連なる短いメモ。タイトル「AIメモ」だけでは中身がわからず、事実(調べた)・解釈(よさそう)・作業指示(明日続きやる)が同じ段落に混ざる。左下にVault名「Hermes-Vault」、右下は46ワード・70文字のカウンタ](/images/hermes-vps/hermes-vps-13-messy-note.png)

「最近Hermes調べた」「あとで読む記事」「明日続きやる」が同じ段落に並ぶ。これだけ見せられても、自分でもHermesでも「これは何の調査結果なのか/次に何をすればいいのか」が判定できない。

**適用後(5項目テンプレ整理)**

同じ題材を§10-1のテンプレで書き直したのが、§10-1冒頭で示した`Hermes Agent調査.md`だ。Title/Summary/Source/Context/Links/Next Actionの6見出しに沿って書き直すと、Hermesが読んだとき「これは何のノートで、自分は次に何をすればいいか」が1秒で判定できるようになる。同じVault内で2つのノートを並べておくと、自分自身も「テンプレを当てる前のメモ」と「当てた後のメモ」をタブ切替で行き来できる。

:::message
`[[Wikilink]]`は、Hermesが文脈をたどるためのリンクだ。「プロジェクト・テーマ・次に使う場所」の3種類から始めると良い。HermesにVaultを読ませるときに「このノートを読んで、関連する`[[AI長期記憶]]`と`[[X記事ネタ]]`の文脈も踏まえて」と頼みやすくなる。
:::

## 自分のパソコンとVPSのVault同期

この節が終わると、自分のパソコンのVaultとVPS側の`~/hermes-vault-repo`が、GitHubのprivate repositoryを介してgitで同期できる。ただし同期されるのは`~/hermes-vault-repo`(VPS側の独立したgit repoのディレクトリ)だけだ。前の節でsymlinkとして用意した`/home/admin/hermes-vault`(HermesがDockerコンテナ越しに書き込む実体Vault)とは、いまの段階では別のディレクトリになっている。Hermesが書いたノートをそのままgit同期する統合は連載後半(Curator+cronの回)で扱う。本回は自分のパソコンとVPSの間でgit同期が動くことを確認するところまでにとどめる。

自分のパソコンのObsidianで書いたノートをVPSのHermesに読ませる、あるいはVPSのHermesが書いたノートを自分のパソコンのObsidianで開く。両方を同じVaultにする手段が必要だ。基本はgitで揃える。

### git双方向push/pull(基本)

自分のパソコンとVPSの両方で同じgitリポジトリをcloneし、変更があるたびに`git push`+`git pull`で同期する。GitHubでprivate repositoryを1つ作り、両方からcloneする想定だ(Vaultは個人所有の知識ベースなので必ずprivateにする)。認証はGitHubが提供する`gh` CLIに任せる(SSH鍵を別途生成して登録する手間を省ける・非エンジニアにとってブラウザでのWeb認証のほうが慣れている)。

#### GitHubにprivate repoを1つ作る(パソコン側のターミナル)

自分のパソコンのターミナルで、GitHub上に空のprivate repositoryを作る。

```bash
# 自分のパソコンのターミナルで(ghは第3回1Passwordセットアップ時にinstall済の想定)
gh repo create sora-bluesky/hermes-vault --private \
  --description "Shared AI long-term memory Vault (Obsidian)"
```

#### 自分のパソコンのVaultをinitial pushする

自分のパソコンのVaultフォルダをgit管理にして、作ったrepositoryへ最初のpushをする。`.gitignore`は、端末ごとに内容が変わる`.obsidian/workspace.json`などをgitに入れないための設定だ。

```bash
cd ~/Documents/Hermes-Vault/

# .gitignoreを用意して、端末固有の.obsidian/workspace.json等をexcludeする
cat > .gitignore <<'EOF'
.obsidian/*
!.obsidian/app.json
!.obsidian/appearance.json
!.obsidian/core-plugins.json
!.obsidian/community-plugins.json
!.obsidian/hotkeys.json
.trash/
.DS_Store
Thumbs.db
EOF

git init
git add .gitignore \
  .obsidian/app.json .obsidian/appearance.json .obsidian/core-plugins.json \
  "AIメモ.md" "Hermes Agent調査.md"
git commit -m "Initial Vault commit"
git branch -M main
git remote add origin https://github.com/sora-bluesky/hermes-vault.git
git push -u origin main
```

#### VPSで`gh` CLIをインストールしてGitHub認証する

VPS側にも`gh`を入れ、自分のパソコンと同じGitHubアカウントで認証する。

```bash
# VPS側で(sshで接続して実行・sudoパスワードを聞かれる)
(type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
  && sudo mkdir -p -m 755 /etc/apt/keyrings \
  && out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  && cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
  && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
     | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && sudo apt update \
  && sudo apt install gh -y

# 認証(対話形式・8桁codeをコピーして、自分のパソコンのブラウザで貼り付ける)
gh auth login -h github.com -p https -w
```

#### VPSにcloneする

VPSに、同じrepositoryをcloneする。

```bash
# VPS側で続けて
cd ~
git clone https://github.com/sora-bluesky/hermes-vault.git hermes-vault-repo
ls hermes-vault-repo  # 自分のパソコンと同じファイルが見える
```

#### 日常運用:push/pull

自分のパソコンで書いた変更を、GitHubへ送る。

```bash
# 自分のパソコンのターミナルで
cd ~/Documents/Hermes-Vault/
git add <変更したファイル>
git commit -m "変更内容の説明"
git push origin main
```

![自分のパソコンのPowerShellで`git push origin main`を実行した直後の画面。`Add §11-1 sync verification note`というcommitがpushされ、`Writing objects: 100% (4/4), 427 bytes`+`To https://github.com/Sora-bluesky/hermes-vault.git`+`<old-hash>..<new-hash>  main -> main`の3行で成功している。ユーザー名はプロンプトでマスク済](/images/hermes-vps/hermes-vps-13-git-push.png)

VPS側で、その変更を取り込む。

```bash
# VPS側で
cd ~/hermes-vault-repo
git pull origin main
```

![VPS側のターミナルで`git pull origin main`を実行した直後の画面。`From https://github.com/sora-bluesky/hermes-vault`+`a7c8cc2..02bef48  main       -> origin/main`+`Updating a7c8cc2..02bef48`+`Fast-forward`+`shared-ai/AGENT_INSTRUCTIONS.md | 2 ++`+`1 file changed, 2 insertions(+)`が表示され、自分のパソコンから送信したcommit `02bef48`がfast-forwardでマージされている。プロンプトのVPSホスト名は一部マスク済](/images/hermes-vps/hermes-vps-13-git-pull.png)

編集のたびに両側で`git pull`→`git push`を回す。Hermes側が書き込んだらパソコン側で`git pull`、パソコン側で書いたら`git push`してVPSで`git pull`。最初は手動でいい。第19回予定のCurator+cronで自動化する道が見えている。

### Obsidian Sync(補足)

Obsidian公式が提供する有料同期サービス(月額数ドル)を使うと、gitなしで自分のパソコンと複数デバイスの間の同期ができる。VPS側はgitで自分のパソコンと繋ぎ、自分のパソコンとスマホの間はObsidian Syncで繋ぐ運用も可能だ。本回は基本のgit同期だけで進める。Obsidian Syncは「やりたくなったときに足せばよい」補足扱いとする。

## 3エージェントで同じVaultを読む

同じVaultをHermes・Claude Code・Codexの3つが読む設計が可能だ。本回ではHermes側の接続まで扱う。3エージェント連携の実装手順は連載後半の予定回(自宅PCに重い処理を任せる回)で本格的に扱う。

### 3エージェントが同じVaultを共用する概念

自分のパソコンのVaultを1つの共有フォルダにしておけば、Hermes(VPS・本回で接続)、Claude Code(パソコン側のターミナル)、Codex(パソコン側のターミナル)の3つが同じノート群を読み書きできる。それぞれが得意なエージェントに得意な仕事を任せる構成が見えてくる。

| エージェント | 得意領域(本連載の想定) |
|---|---|
| Hermes(VPS常駐) | 夜間や朝の自動処理・Telegram対話・cron運用・長期メンテ |
| Claude Code(パソコン側) | 記事執筆・コードレビュー・対話的なリファクタ |
| Codex(パソコン側) | 監査・ファクトチェック・独立視点のレビュー |

実装手順(Tailscale+OpenSSHでVPSと自分のパソコンを繋ぐ・3つのエージェントが同じVaultを読む設定など)は別回で扱う予定だ。本回ではHermes側の「Vaultを読める状態」までで止める。

## Vaultは配布対象外

Hermesには「Profile Distributions」という、自分の設定一式を他のマシンに配る仕組みがある(連載後半の予定回で扱う)。配布対象はSOUL.md/config.yaml/Skills/Cron/MCP設定など「人格と手順」だ。一方、Memoryの中身(USER.md/MEMORY.md/sessions/state.db)+Obsidian Vaultは配布対象外になる。

### user-ownedとnever-touchedの境界

| 配布される(人格と手順) | 配布されない(個人の記憶とVault) |
|---|---|
| SOUL.md(文体・応答スタイル) | USER.md(本人の人物カード) |
| config.yaml(設定) | MEMORY.md(環境ファクト) |
| Skills(手順書) | sessions(過去の会話履歴) |
| Cron(スケジュール) | state.db(セッション検索DB) |
| MCP設定 | Obsidian Vault(個人所有の知識ベース) |

配布されるのは「人格と手順」、配布されないのは「個人の記憶とVault」だ。そのため、Hermesを他のマシンに配っても、自分のプライベートな情報が一緒についていく心配がない。

配布の具体的なコマンドや運用は別回で扱う予定だ。本回は「Vaultは配布対象外」の1行を覚えておけば十分だ。これで安心してVaultを育てられる。

## まとめと第14回予告

第13回が終わった時点で、HermesはVPS上のVaultにTelegram経由でノートを書ける。自分のパソコンとgitで同期できるのは別フォルダの`~/hermes-vault-repo`までで、Hermesが書くVault(`/home/admin/hermes-vault`)との統合は後の回で扱う。ここまでにやったことは次のとおり。

- bundled `obsidian` skillがHermes本体に最初から入っていることを確認した
- VPS側にVault実体ディレクトリを作り、`/home/admin/hermes-vault`からsymlinkで読み書きできる形にした
- TelegramからHermesに「Vaultにメモを書いて」と頼み、VPS側のVaultに.mdファイルが実体として作られることを確認した
- Hermesが読めるノートの構造(5項目テンプレ:Title/Summary/Source/Context/Links/Next Action)を整理した
- Hermesが迷うノートの4特徴(あいまいタイトル/事実と感想の混在/孤立ノート/Next Action欠落)を裏返しで把握した
- 自分のパソコンとVPSのVaultをgit push/pullで同期する最小構成を作った
- 3エージェント(Hermes/Claude Code/Codex)が同じVaultを読む設計の方向を示した
- Vaultが配布対象外であることを、配布されないものとして明示した

これでHermes Agentは、「毎回使う前提(Memory)」と「長く残しておきたい情報(Vault)」の両方を持てるようになった。Memoryの3,575字に収まらない気になった記事の保存、調べごとの記録、過去の議事録、書きかけの下書きは、これからすべてVault側に置ける。

第14回は**Session Search**だ。Hermesは過去のすべての会話を`~/.hermes/state.db`(SQLite+FTS5)に保存している。「先週Telegramで話した、名古屋旅行の映えスポット」を、Hermesが自分で検索して引っ張ってくる仕組みを入れる。

Memory(毎回使う前提)+Obsidian(長く残しておきたい情報)+Session Search(過去の会話)。この3つが揃うと、Hermesは会話をまたいで情報を引き継げる段階に入る。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第12回 好みを毎回言うな。Hermes AgentはMemoryで覚えている](https://zenn.dev/sora_biz/articles/hermes-vps-12-memory) | [第14回 毎回最初から話すな。Hermes Agentは前回の続きからそのまま動く](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## よくあるエラーと対処

| 症状 | 原因 | 対処 |
|---|---|---|
| 「Vaultが見つかりません」 | symlinkまたは実体ディレクトリが未作成 | `ls -la /home/admin/hermes-vault`でsymlinkがあるか確認・`ls -la ~/.hermes/sandboxes/docker/default/home/Documents/`でsymlink先の実体があるか確認 |
| `hermes memory setup --provider obsidian`が`not found.`になる | そのコマンドはv0.17.0に存在しない | VaultはMemory providerではない。bundled obsidian skill(§6)+ホスト側symlink(§7)で連携する |
| 環境変数を設定したのにHermesがVaultを読めない | Hermes本体未再起動 | `systemctl --user restart hermes-gateway`で反映 |
| Telegramで頼んでも「Vault機能がありません」と返ってくる | skillが無効化されている | `hermes skills list`で`obsidian`の有効状態を確認。無効なら有効化 |
| `hermes skills list`にobsidianが出ない | bundled manifestには登録があっても実体がシードされていない(v0.17.0初期インストールで観測) | `hermes skills reset obsidian --restore --yes`で実体を再シード |
| `git push`で「リモートに変更があります」エラー | パソコン側とVPS側の片方が先に更新した | `git pull --rebase`で取り込んでから再push |
| 自分のパソコンのObsidianとVPSのVaultが食い違う | git同期し忘れ | 編集後は両側で`git pull`→`git push`を習慣化する(将来的に第19回予定のCurator+cronで自動化) |
| Vaultフォルダ内の日本語ファイル名が文字化けする | VPS側のlocale設定がja_JP.UTF-8でない | `locale`で確認。`sudo dpkg-reconfigure locales`または`sudo locale-gen ja_JP.UTF-8` |

## 操作早見表

```bash
# skill確認
hermes skills list                              # bundled skill一覧
cat ~/.hermes/skills/note-taking/obsidian/SKILL.md   # SKILL.md表示

# Vaultパス設定
mkdir -p ~/.hermes/sandboxes/docker/default/home/Documents/Obsidian\ Vault   # 実体ディレクトリ作成
ln -sf ~/.hermes/sandboxes/docker/default/home/Documents/Obsidian\ Vault /home/admin/hermes-vault  # symlink張り
ls -la /home/admin/hermes-vault                 # symlinkが見えればOK
systemctl --user restart hermes-gateway         # Hermes再起動

# 動作確認
ls -la /home/admin/hermes-vault/                       # Vault内ファイル一覧
cat /home/admin/hermes-vault/<ノート名>.md             # 中身確認

# git同期(パソコン側・VPS側の両方で)
git pull origin main                            # 取り込み
git push origin main                            # 反映
```

## 補足:v0.17.0「The Reach Release」での関連機能

2026-06-19公開のv0.17.0「The Reach Release」では、本回のObsidian連携と相性のいい機能がいくつか追加されている。

- **read_file拡張(Office対応)**:従来の.txt/.mdに加えて.docx/.xlsxも直接読めるようになった。Vault内に貯めた会議メモのdocxをHermesがそのまま要約できる(v0.17.0時点では.pdfは読めず、テキストにしてから渡す必要があった)。**2026-08の更新でここがさらに広がり、PDF・旧Office(.doc/.ppt/.xls)・EPUBなども初回読み取り時に変換部品を自動で入れてMarkdown化して読めるようになった**([read_file拡張のcommit](https://github.com/NousResearch/hermes-agent/commit/b2598b41e)・実際に動かして抽出動作を確認済み)。Vaultに放り込んだPDF資料もそのまま読ませられる。
- **secure login(Dashboard)**:Dashboardにtoken必須endpointが導入された。本回では使わないが、第19回予定のCuratorでVault整理を自動化するときに関連してくる。

本回の手順はv0.17.0より前のバージョンでもbundled `obsidian` skillとsymlinkで動くが、最新版に保つほどObsidian連携の活用幅が広がる。`hermes update`で本体を最新に保ち続けるのが基本だ。

## 引用元と参考

| 項目 | 引用元 |
|---|---|
| bundled `obsidian` skill仕様 | [SKILL.md (note-taking/obsidian)](https://github.com/NousResearch/hermes-agent/blob/main/skills/note-taking/obsidian/SKILL.md) |
| 環境変数の扱い(`OBSIDIAN_VAULT_PATH`) | [Hermes configuration](https://hermes-agent.nousresearch.com/docs/user-guide/configuration) |
| Hermes memory全般(対比のため) | [memory](https://hermes-agent.nousresearch.com/docs/user-guide/features/memory) |
| Obsidian公式 | [obsidian.md](https://obsidian.md/) |
| Memoryアーキテクチャの実装者視点(参考) | [Tonbi (@tonbistudio) Hermes Agent Masterclass Module 3: Memory, Plugins, Honcho, Obsidian](https://www.youtube.com/watch?v=ZKZLko9kLm4)(2026-05-18公開・約34分・英語・自動翻訳字幕で日本語可) |
| AIに読ませるノート設計の参考 | [MGT_maccha (@MGT_maccha) X Article『AIに読ませるObsidianノートの作り方』](https://x.com/MGT_maccha/status/2067940523986534409) |
| Memoryの解説(日本語) | 公式ドキュメントの日本語訳: [Memory](https://wiki.winsmux.dev/hermes/concepts/memory/) |


:::message
この連載はSubstack「そらのAIエージェント通信」で先行公開している。無料[登録](https://sorabiz.substack.com/subscribe)すると最新回がメールに届く。[Zennでフォロー](https://zenn.dev/sora_biz)すると新着通知が届き、全体像は[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::
