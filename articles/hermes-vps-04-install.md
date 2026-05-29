---
title: "【第4回】Hermes Agent本体をVPSに入れる──インストールとDockerサンドボックス"
emoji: "🤖"
type: "tech"
topics: ["hermes", "vps", "docker", "python", "uv"]
published: false
---

## 本記事の章ジャンプ

- [はじめに](#はじめに)
- [第3回までの到達点と第4回の差分](#第3回までの到達点と第4回の差分)
- [本記事で出てくる用語の最低限の理解](#本記事で出てくる用語の最低限の理解)
- [なぜDocker backendを選ぶか](#なぜdocker-backendを選ぶか)
- [第4回終了時点の構成図](#第4回終了時点の構成図)
- [事前準備](#事前準備)
- [Hermes Agentをインストール](#hermes-agentをインストール)
- [hermes setupで対話的に初期設定](#hermes-setupで対話的に初期設定)
- [手動起動でTelegram疎通を確認する](#手動起動でtelegram疎通を確認する)
- [最終確認チェックリスト](#最終確認チェックリスト)
- [つまずき集(まとめ)](#つまずき集(まとめ))
- [まとめ](#まとめ)
- [公式ドキュメント引用元一覧](#公式ドキュメント引用元一覧)

:::message
このシリーズはHermes AgentをVPSに常駐させるまでの実録だ。全10回を予定している。

- 第1回──Hermes AgentをVPSに常駐させる(契約からログインまで)
- 第2回──Hermes Agentの公開SSHをTailscaleで安全に閉じる
- 第3回──Hermes Agentの秘密情報を1Passwordで平文に出さない運用
- **第4回**(本記事)──Hermes Agent本体をVPSに入れる(インストールとDockerサンドボックス)
- 第5回──Hermes Agentに頭脳と出入口をもう1系統足す(Grok OAuthとDiscord+承認モードの確認)
- 第6回──Hermes Agentをsystemdで24時間常駐させる
- 第7回──Hermes Agent Cronで毎朝の定型を任せる
- 第8回──Hermes Agent Skillsに手順を覚えさせる
- 第9回──Hermes AgentのWeb/X検索を使い分ける
- 第10回──Hermes Agentの手足に自宅のデスクトップを使う(Wake-on-LANとzellij)
:::

## はじめに

第3回までで、1Password Service AccountとVPSの`op` CLIで秘密情報を扱える状態にした。ただし**Hermes Agent本体はまだVPSに存在しない**。第4回はその本体を入れる回だ。

第4回のゴールは、VPSの中に:

- Hermes Agent v0.14.0をクローン+インストール
- Docker engineを入れて、Hermes Agentのコマンド実行が**コンテナの中で隔離**される構成にする
- `hermes setup`の5パートウィザードで本シリーズの方針(backend=docker)を全部入力する
- 既知バグ(後述)を回避するため、`main`ブランチで運用に切り替える
- `op run -- hermes gateway`で起動 → Telegramでbotに話しかけてHermes Agentから返信が来るところまで

を作ること。OAuth(Codex/Grok)の詳細設定や承認モード固定は第5回でまとめる。

実機で打ちながら書いたメモなので、きれいな手順書ではない。詰まった場所も含めて読んでもらいたい。

## 第3回までの到達点と第4回の差分

| 項目 | 第3回完了時 | 第4回完了後 |
|---|---|---|
| 1Password運用 | Service Account+op CLI完成 | 変わらず |
| `~/.hermes/secrets.env` | `op://`参照のみ | 変わらず(op run経由で読まれる) |
| **Hermes Agent本体** | 未インストール | **mainブランチでインストール完了+手動起動できる** |
| Docker engine | 未インストール | adminユーザーで`docker`コマンド実行可能 |
| Codex OAuth | 未登録 | `hermes setup`実行中に併走で登録される(実機検証) |
| Telegram bot疎通 | tokenの参照経路だけ | 「hello」と話しかけたら「Hello! How can I help?」相当の挨拶が返る |
| 常駐起動 | なし | なし(第6回でsystemd化) |

## 本記事で出てくる用語の最低限の理解

非エンジニアでも追えるよう、ここで先に用語を揃えておく。

| 用語 | 意味 | たとえ |
|---|---|---|
| リポジトリ | プログラムのソースコード一式を管理する場所 | 本のフォルダ |
| クローン | GitHubから自分のVPSにコピーしてくる操作 | 図書館から本を借りて手元にコピーする |
| tag | プログラムの「特定バージョン」につけた目印 | 本の第5刷、第6刷 |
| チェックアウト | その目印のバージョンに切り替えること | 第5刷の本だけ手元に置く |
| Python仮想環境(venv) | プロジェクト専用のPython実行環境 | 仕事用と趣味用でPCを使い分ける感じ |
| Docker | ソフトを軽量な箱(コンテナ)で隔離して動かす技術 | 洗える台所マット。汚れても台所本体は無事 |
| サンドボックス | 外と切り離された安全な実行空間 | 子供が安全に遊べる砂場 |
| Docker backendのサンドボックス | Hermes Agentの実行用に専用のDockerコンテナを置く構成。コマンドはコンテナ内で完結し、ホスト側に影響しない | 台所本体の中に独立したミニキッチン(=コンテナ)を置いて、料理(=コマンド実行)はそこだけでやる |
| backend | Hermes Agentが実際にコマンドを走らせる場所の選択肢 | 自宅で料理する/出前を頼む/外食する、みたいな実行先の指定 |

## なぜDocker backendを選ぶか

Hermes Agentは複数のbackendを選べる。README宣伝コピーは「local / Docker / SSH / Singularity / Modal / Daytona / Vercel Sandboxの7backend」と謳う(出典:[公式README@v2026.5.16](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/README.md))。

本シリーズではDockerを採用する。

| backend | 採用判断 | 理由 |
|---|---|---|
| local | 採用しない | Hermes Agentがadminのシェルで直接コマンドをexecするのでVPSのファイルやプロセスに直接影響。事故時の被害が大きい |
| **docker** | **採用** | Hermes Agentのコマンド実行が全てコンテナ内で隔離される。ホストOSへの影響が限定される(壊れても`docker rm`で復旧) |
| SSH / Modal / Daytona / Vercel Sandbox | 採用しない | 外部マシン/外部サービスへの委譲。本シリーズは1台のVPSで完結させる方針 |
| Singularity | 採用しない | HPC向け。一般的なVPS運用には過剰 |

Telegramから飛んできた指示が`rm -rf /`のような破壊コマンドでも、Docker backendなら**コンテナの中で完結**する。ホスト側のadminファイルやsshd設定には触れない。後段の第5回で承認モード(ask)を固定するので、人間の許可なしには発動しないが、二重の防御線を張る。

## 第4回終了時点の構成図

![第4回終了時点の構成図(Dockerサンドボックス+Codex+Telegram疎通)](/images/hermes-vps/hermes-vps-04-architecture.png)

ファイル配置とコマンドの関係は次のとおり。

![第4回終了時点のVPS内ファイル構成図](/images/hermes-vps/hermes-vps-04-files.png)

テキスト表記でも見ておく(コピペ参照用)。

```
┌──────────────────────────────────────────────────────────────┐
│   VPS(Ubuntu 26.04 / admin)                                  │
│                                                              │
│   ~/hermes-agent/  ← git clone先(mainブランチで運用)         │
│   ~/.hermes/                                                 │
│   ├── service-account.env(SAトークン、第3回で配置)          │
│   ├── secrets.env(op://参照、第3回で配置)                   │
│   ├── .env(./setup-hermes.shが.env.exampleから複製)          │
│   ├── config.yaml(hermes setupが対話で生成)                 │
│   └── auth.json(Codex OAuth、setup wizard中に作成される)    │
│                                                              │
│   docker engine ← adminで動かせる(usermodで権限付与)         │
│                                                              │
│   起動コマンド(foreground):                                  │
│   op run --env-file=$HOME/.hermes/secrets.env -- hermes gateway │
└──────────────────────────────────────────────────────────────┘
```

## 事前準備

### Tailscale経由でVPSにadminログイン

第2回で確立した経路を使う。

```
ssh -i ~/.ssh/hermes_vps_ed25519 admin@hermes-vps
```

MagicDNSが有効でない場合は[Tailscale admin console](https://login.tailscale.com/admin/machines)で`hermes-vps`の`100.x.x.x`形式のIPを確認して使う。

### Pythonバージョンの確認

Hermes Agentは**Python 3.11以上**を要求する(出典:[pyproject.toml@v2026.5.16](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/pyproject.toml)の`requires-python = ">=3.11"`)。

```bash
python3 --version
```

Ubuntu 26.04のデフォルトPythonは3.14系のはず(私の実機は3.14.4だった)。3.11未満なら以下:

```bash
sudo apt update && sudo apt install -y python3.12 python3.12-venv python3-pip
```

### uvをインストール

Hermes Agent公式READMEがuv(Astralの高速Pythonパッケージ管理ツール)を推奨している。

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
uv --version
```

`uv --version`で`uv 0.11.x`のような表示が出ればOK(私の実機は`uv 0.11.16`)。

### Docker engineのインストール

Hermes Agent Docker backendで使う。Docker公式リポジトリを追加して`apt install`するパターン。これはHermes Agent側の制約ではなくDocker公式の手順だ。

```bash
sudo apt update && sudo apt install -y ca-certificates curl

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

docker --version
```

`docker --version`で`Docker version 29.x.x`のような表示が出ればOK。

![Docker engine 29.5.2インストール完了+systemd serviceに登録](/images/hermes-vps/hermes-vps-04-docker-install.png)

### admin権限でdockerコマンドを動かせるようにする

デフォルトでは`docker`コマンドはrootしか動かせない。adminを`docker`グループに入れる(これもDocker公式の手順)。

```bash
sudo usermod -aG docker admin
newgrp docker
docker run hello-world
```

| コマンド | 役割 |
|---|---|
| `sudo usermod -aG docker admin` | adminユーザーを`docker`グループに追加(`-aG`は「既存グループに追加、上書きしない」) |
| `newgrp docker` | 現在のシェルに新しいグループ所属を即時反映(ログアウト不要) |
| `docker run hello-world` | テスト用の極小コンテナを取得→実行→自動終了 |

「Hello from Docker!」が出ればOK。

![docker run hello-worldで「Hello from Docker!」が表示される](/images/hermes-vps/hermes-vps-04-docker-hello.png)

これでDocker engineが「ネット越しに必要なコンテナを取ってこられる+adminユーザーで起動できる」状態になった。Hermes Agent本体も同じ仕組みで起動時に必要なコンテナを取りに行くので、ここで動けば後の安心材料になる。

## Hermes Agentをインストール

### リポジトリをクローン+tag確認

```bash
cd ~
git clone https://github.com/NousResearch/hermes-agent.git
cd hermes-agent
git tag --sort=-creatordate | head -5
```

`--sort=-creatordate`は「作成日降順」の意味で、最新tagが先頭に来る。本シリーズ執筆時点では`v2026.5.16`が最新(=`v0.14.0`、2026年5月16日リリース)だった。

![git clone成功+git tag一覧でv2026.5.16が最新](/images/hermes-vps/hermes-vps-04-clone-tag.png)

### 既知バグ回避のためmainブランチで運用する

ここで重要な判断がある。普通なら`git checkout v2026.5.16`してリリースtagで運用するのが筋だが、本シリーズの執筆時点で**v0.14.0には致命的なバグが残っていた**。

| 症状 | エラーログ |
|---|---|
| Telegramにメッセージ送ると即落ち | `'NoneType' object is not iterable` / `provider=openai-codex / model=gpt-5.5` |

これは2026-05-26頃からChatGPT Codex backendが`response.output=null`を返す挙動に変わったのに、v0.14.0のparseロジックが追従していないためだ。修正は[PR #32963](https://github.com/NousResearch/hermes-agent/pull/32963)で**2026-05-27 02:37 UTC**にmainへマージされた(関連Issueは[#11179 canonical](https://github.com/NousResearch/hermes-agent/issues/11179)、[#33041](https://github.com/NousResearch/hermes-agent/issues/33041)等)。

つまり**v0.14.0 tagチェックアウトでは修正が入っていない**ので、mainブランチで運用する必要がある。

```bash
git checkout main
git pull
```

`git pull`で当該PRの修正(`agent/codex_runtime.py`と`agent/auxiliary_client.py`のNoneガード追加)が降りてくる。

![git checkout main+git pullで最新HEAD取得](/images/hermes-vps/hermes-vps-04-checkout.png)

:::message
**バグ回避のためのmain運用が、本記事の最大の判断**:Hermes Agentは活発に開発されており、リリースtagには上記のような未解決バグが残ることがある。「最新tagをチェックアウトすれば安全」とは限らない。**該当のIssue/PRを確認→修正がmainにあればmain運用に切り替える**、を毎回考える必要がある。

本の刷り直しにたとえると、tagは製本済みの第5刷、mainは日々修正が入る最新の原稿だ。今回は第5刷に印刷ミスがあり、その直しは原稿側にしか入っていなかった、という状況にあたる。
:::

:::message
**【2026-05-29追記】このバグは最新リリースで解消済み**。NoneType修正(PR #32963)は、その後の正式リリースv0.15.0(tag v2026.5.28)以降に取り込まれた。最新のv0.15.1(tag v2026.5.29)では修正済みなので、いま新しく始める読者は`git fetch --tags && git checkout v2026.5.29`で最新リリースtagを使えば、本節のmainブランチ運用をしなくてもこのバグを踏まない。以下のmain運用手順は、執筆時点(v0.14.0)の記録として残している。
:::

### インストール

本シリーズは**`./setup-hermes.sh`一発**でインストールする。

```bash
./setup-hermes.sh
```

このスクリプトが内部で行うこと:

- `venv/`(Python仮想環境)を作成
- 依存パッケージ(`.[all]`extras含む)を`uv pip install`でインストール
- `.env`を`.env.example`から複製(初回のみ)
- `$HERMES_HOME`(デフォルト`~/.hermes/`)に必要ファイルを配置

途中で`ripgrep`(高速ファイル検索ツール)のインストールを聞かれる。`Y`+ENTERで進める。

:::message
手動で展開したい場合は`uv venv .venv --python 3.11 && source .venv/bin/activate && uv pip install -e ".[all]"`の順で実行する。`uv sync`は`[all]`extraを読まないため使わない。
:::

:::message alert
`./setup-hermes.sh`は`venv/`(ピリオドなし)を作る。`.venv/`(ピリオド付き)ではない。`source venv/bin/activate`で有効化する(ピリオドの位置に注意)。
:::

### hermesコマンドの存在確認

```bash
which hermes
hermes version
```

`which hermes`で`~/.local/bin/hermes`(`~/hermes-agent/venv/bin/hermes`へのシンボリックリンク)が返り、`hermes version`で`0.14.0`系が表示されればOK。`source venv/bin/activate`でvenvを有効化した後はvenv内のパスが直接返る。

:::message
Hermes Agentは`hermes version`(サブコマンド形式)でも`hermes --version`(ダッシュ付き)でも同じバージョンが表示される。`hermes doctor`(自己診断)、`hermes auth list`(認証一覧)等の機能はサブコマンド形式が標準(出典:[hermes_cli/main.py@v2026.5.16](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/main.py))。
:::

## hermes setupで対話的に初期設定

`hermes setup`は対話形式のウィザード。実機では最初に「Quick setup / Full setup」を聞かれる。本シリーズは**Full setup**を選ぶ(Quickだとbackend設定が漏れる)。

その後、以下の5パートに分かれた質問が来る(出典:[hermes_cli/setup.py@v2026.5.16](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/setup.py)のdocstring)。

| パート | 内容 |
|---|---|
| 1. Model & Provider | プロバイダ選択(OpenAI Codex / xAI Grok等)とデフォルトモデル |
| 2. Terminal Backend | backendの種類とGateway working directory |
| 3. Agent Settings | 最大反復回数・ツール進捗表示・圧縮閾値・セッションリセット |
| 4. Messaging Platforms | 連携するメッセージング(Telegram / Discord等) |
| 5. Tools | 利用するツール群+各ツールのプロバイダ選択 |

### 本シリーズで取った回答一覧

私が実機で入力した値を表で残しておく。Hermes Agentの対話は項目数が多く、一つずつ判断するのは負担が大きいので、ここでまとめて参照できるようにする。

なお表中の★印は、このあとの「つまずきポイント」で詳しく説明する項目を指す。

| 質問 | 回答 | 補足 |
|---|---|---|
| Setup mode | **Full setup** | Quickだとbackend設定が漏れる |
| Provider | **OpenAI Codex** | Codex CLIと同じOAuth経路。第5回でGrok追加 |
| TTS Provider(初期) | Keep current (Edge TTS) | 無料、APIキー不要 |
| Terminal Backend | **docker** | 採用判断は前述 |
| Docker image | デフォルト(`nikolaik/python-nodejs:python3.11-nodejs20`) | PythonとNode.jsが最初から入った標準のコンテナ。中身は気にしなくてよい。初回起動時にdocker hubから自動で取ってくる |
| Persist filesystem | yes | コンテナ内のファイルがセッション間で残る |
| CPU cores | **2** | VPS 4コア中の半分 |
| Memory MB | **3072**(=3GB) | VPS 6GBの半分 |
| Disk MB | デフォルト(51200=50GB) | VPS 150GBの1/3 |
| Max iterations | デフォルト(90) | 一般用途向け |
| Tool progress mode | デフォルト(all) | 学習段階で全ツール実行を見る |
| Compression threshold | デフォルト(0.5) | 早めに圧縮、長時間運用で安定 |
| Session reset mode | デフォルト(Inactivity + daily reset) | 常駐運用最適 |
| Inactivity timeout | デフォルト(1440分=24時間) | 1日無活動でリセット |
| Daily reset hour | デフォルト(4=午前4時) | 人間活動最少帯 |
| Messaging Platforms | **Telegramのみ**チェック | Discordは第5回で発行後追加 |
| **Telegram botトークン** | **BotFatherから取得した値**を入力 | ★後で事後処理(後述) |
| Allowed user IDs | 自分のTelegram user ID | Telegramで[@userinfobot](https://t.me/userinfobot)に話しかけると`123456789`のような数値IDが返る。それを貼り付け |
| Home Channel | 自分のuser ID(=Y) | Hermes Agentからの通知が自分のDMに届く |
| Install gateway as systemd? | **N** | 第6回でカスタムunitを作る |
| Tools for CLI / Telegram | デフォルト(主要ツールON) | Xサーチは第5回、Discordも第5回 |
| Browser Provider | Local Browser(★recommended・free) | VPS内Chromium、APIキー不要 |
| Image Generation Provider | **OpenAI (Codex auth) [free]** | ★罠あり、下矢印を**2回**押す(後述) |
| Image Generation Model | デフォルト(gpt-image-2-medium) | 画像生成に使うモデル名。Codex OAuth枠で追加料金なしで使える |
| Search Provider | DuckDuckGo (ddgs) | APIキー不要 |

### つまずきポイント1:Image Generation Providerの「下矢印1回罠」

Image Generation Provider選択で、選択肢の並びは以下のようになっている。

```
 → (●) FAL.ai [paid]
   (○) OpenAI [paid]                  ← 下矢印1回でここ(罠)
   (○) OpenAI (Codex auth) [free]    ← 下矢印2回でここ(正解)
   (○) xAI Grok Imagine (image) [paid]
   (○) Skip
```

下矢印を**1回**押して`OpenAI [paid]`を選んでしまうと、次に「OpenAI API key:」の入力を求められる。本シリーズの方針(Codex OAuth経由=APIキー不要)から外れる。

**正しくは下矢印2回**で`OpenAI (Codex auth) [free]`にカーソルを合わせてENTER。これでChatGPT/Codex OAuth経由で`gpt-image-2`が無料(=ChatGPT契約枠内)で使える。

万一API key入力画面に入ってしまったら、空欄のままENTERでskip→setup完了後に部分再対話で修正できる:

```bash
hermes setup --section tools
```

### つまずきポイント2:Telegram botトークンが.envに平文保存される(setup完了直後の必須処理)

セットアップウィザードの「Telegram botトークン」入力では**実値を入れるしかない**(wizard側で空欄skipができない仕様)。値を入れた瞬間、`~/.hermes/.env`に`TELEGRAM_BOT_TOKEN=<実値>`として**平文で書かれる**。本シリーズ方針(`op://`参照経由でディスク平文を残さない、第3回参照)と矛盾するので、**setup完了の直後に必ず削除する**。

```bash
nano ~/.hermes/.env
# TELEGRAM_BOT_TOKEN=... の行を削除して保存(Ctrl+O→Enter→Ctrl+X)
```

残しておくのは以下のみ:

```
TERMINAL_DOCKER_IMAGE=nikolaik/python-nodejs:python3.11-nodejs20
TERMINAL_ENV=docker
TELEGRAM_ALLOWED_USERS=<user ID>
TELEGRAM_HOME_CHANNEL=<user ID>
```

:::message alert
**シェル履歴とエディタundo bufferへの残存も気にする**:tokenを一度でもディスクに書いた以上、エディタのundo buffer(`nano`の`.swp`等)に残る可能性がある。気になる場合は`rm ~/.hermes/.env.*`で残骸を消す。シェル履歴は`history -c`+`echo > ~/.bash_history`で全消去できるが、本記事ではtokenをコマンドラインに貼ったわけではないので影響は限定的。
:::

これ以降、`hermes gateway`を直接実行するとTelegram接続に失敗する(`.env`にtokenがないため)。**必ず`op run --env-file=$HOME/.hermes/secrets.env -- hermes gateway`経由で起動**する。これが本シリーズの一貫した運用パターン。

### つまずきポイント3:Codex OAuthはセットアップウィザードで一緒に登録される

これは予想外の挙動だった。セットアップウィザードの「Provider選択でOpenAI Codex」を選んだ段階で、**OAuth登録(デバイスコードフロー)も同時に走る**。第4回終了時点で`hermes auth list`を確認すると:

```
openai-codex (1 credentials):
  #1  device_code          oauth   device_code
```

のように既に登録済みになっている。`~/.hermes/auth.json`も作成されている。

そのため、本シリーズの第5回で「Codex OAuth登録」を別途やる必要はない。token期限切れ等で再認証が必要になった場合は`hermes auth add openai-codex`を再実行すれば良い、と[公式CLI(hermes_cli/auth.py)](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/auth.py)の仕様に書かれている(実機での再認証は本シリーズではまだ試していない)。第5回でやるのはGrok OAuth(SSHトンネリングが必要)と承認モード固定。

### セットアップ完了

5パート全部回答すると以下のように完了画面が出る。

![hermes setup完了画面、Settings/API Keys/Dataのパス案内+各種コマンド一覧](/images/hermes-vps/hermes-vps-04-setup-complete.png)

`~/.hermes/`配下に以下が揃う。

| ファイル | 由来 | 役割 | あなたが触る? |
|---|---|---|---|
| `service-account.env` | 第3回で自作 | `OP_SERVICE_ACCOUNT_TOKEN` | 触る(SA再発行時のみ) |
| `secrets.env` | 第3回で自作 | `op://`参照のみ | 触る(参照を追加する時) |
| `.env` | setup-hermes.shが複製 | Hermes Agent固有設定 | 触らない(setup再実行で更新) |
| `config.yaml` | hermes setupが生成 | backend・モデル・messaging・toolsの設定 | 触らない(`hermes setup`で再対話) |
| `auth.json` | セットアップウィザードのProvider選択時に作成 | OAuth token保管 | **絶対に触らない**(Hermes Agentが排他管理) |

`auth.json`は`agent/file_safety.py`でクロスプロセスファイルロックされており、手動編集すると壊れる(出典:[hermes_cli/auth.py@v2026.5.16](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/auth.py))。

## 手動起動でTelegram疎通を確認する

ここまでで「Hermes Agent本体+Docker環境+設定ファイル一式+Codex OAuth」が揃った。最後に、第3回で作った`op run`パターンで起動して、Telegramからの返信が来るかを確認する。

### 起動コマンド

```bash
cd ~/hermes-agent
source venv/bin/activate

set -a
source ~/.hermes/service-account.env
set +a

op run --env-file=$HOME/.hermes/secrets.env -- hermes gateway
```

各行の役割:

| コマンド | 役割 |
|---|---|
| `cd ~/hermes-agent && source venv/bin/activate` | Hermes Agentの作業環境に入る(venvをアクティベート) |
| `set -a; source ~/.hermes/service-account.env; set +a` | `OP_SERVICE_ACCOUNT_TOKEN`を環境変数として読み込み(opが認証に使う) |
| `op run --env-file=$HOME/.hermes/secrets.env -- hermes gateway` | `op run`は第3回で作った仕組み。`secrets.env`の中の`op://`参照(秘密情報の置き場所だけを書いた目印)を実際の値に置き換えてから、後ろのコマンドを起動するラッパーだ。`--`はこの記号より後ろが実行したいコマンド本体という区切り。つまりここでは`hermes gateway`(messaging gateway起動)に秘密情報を環境変数として渡して起動する |

:::message
`hermes gateway`(`hermes run`ではない、ここよく間違える)。`run`コマンドは存在せず、messaging gateway起動は`hermes gateway`が正(出典:[hermes_cli/main.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/main.py) line 1469付近の`cmd_gateway`)。
:::

### つまずきポイント4:初回起動時にNode.jsとChromiumの自動インストールが走る

`op run -- hermes gateway`を初回起動すると、Browser tools用にNode.jsとChromiumの自動インストールが始まる。`Browser engine (Chromium, for web browsing tools) is not installed. Install now? [Y/n]`と聞かれたら`Y`で進める。

ただし、**Ubuntu 26.04ではPlaywrightのChromium installが失敗する**:

```
Failed to install browsers
Error: ERROR: Playwright does not support chromium on ubuntu26.04-x64
```

Ubuntu 26.04(2026年4月リリース)が新しすぎてPlaywright未対応(2026年5月時点)。**Browser toolsはHermes Agentに「このページを見てきて」と頼むと、VPS内のChromiumでサイトを開いて情報を取ってくる機能**だが、これが使えなくなる。一方で**Hermes Agent本体のテキスト応答とDuckDuckGo検索は問題なく動く**ので、本シリーズの第5-7回の範囲では支障なし。Playwrightのバージョンアップ待ち、または旧Ubuntu(22.04/24.04)を選ぶ判断が必要だが、Browser toolsを多用する予定がなければそのままで構わない。本シリーズではUbuntu 26.04のまま、Browser toolsはオプション扱いで進める。

### つまずきポイント5:Telegram「Chat not found」エラー

`hermes gateway`起動時に以下のエラーで失敗することがある。

```
ERROR gateway.platforms.telegram: [Telegram] Failed to send Telegram message: Chat not found
telegram.error.BadRequest: Chat not found
```

原因はTelegram Bot APIの仕様で、**botはユーザーから最初のメッセージを受け取るまでユーザーにDMを送れない**。`TELEGRAM_HOME_CHANNEL`(=自分のuser ID)宛に起動通知を送ろうとして「Chat not found」になる。

対処:Telegramアプリで自分のbot(`@hermes_vps_xxxxxx_bot`)を開いて`/start`または任意のメッセージを1回送る→chat確立→再起動でエラーが消える。

### つまずきポイント6:`'NoneType' object is not iterable`が出る場合

本記事冒頭の「既知バグ回避のためmainブランチで運用する」(`git checkout main && git pull`)を実施した読者は**踏まない**罠。もしリリースtag(`v2026.5.16`)のままで運用していると、`op run -- hermes gateway`起動後、Telegramでメッセージを送ると以下のエラーで異常終了する:

```
WARNING run_agent: API call failed (attempt 1/3) error_type=TypeError
provider=openai-codex base_url=https://chatgpt.com/backend-api/codex model=gpt-5.5
summary='NoneType' object is not iterable
```

その場合の解消:

```bash
cd ~/hermes-agent
git checkout main
git pull
source venv/bin/activate
uv pip install -e ".[all]"
```

`agent/codex_runtime.py`+`agent/auxiliary_client.py`が更新されてNoneガードが入る。詳細は本記事冒頭の「既知バグ回避」節を参照。

### Telegramで疎通確認

ここまで来てやっとTelegramの会話が動く。Telegramアプリで自分のbotに「hello」と送ると、Hermes Agentから「Hello! How can I help?」相当の挨拶が返ってくる。

![Telegramで「hello」送信→Hermes Agentから「Hello! How can I help?」と返信(ターミナル側はop run経由でhermes gateway起動中、機密情報マスク済)](/images/hermes-vps/hermes-vps-04-telegram-success.png)

これが第4回の到達点だ。手動起動でHermes AgentがTelegram経由で返事をしてくれる状態。Codex OAuth経由でgpt-5.5を呼び、Docker backendで応答処理を完結している。

`Ctrl+C`でhermes gatewayを止める。プロセスは数秒で止まる。SSHを抜けるとHermes Agentも止まる(常駐起動は第6回)。

## 最終確認チェックリスト

第4回の完了条件は以下。

- [ ] Docker engine+admin権限で`docker`コマンド実行可能(`docker run hello-world`成功)
- [ ] Hermes Agentクローン+main pull完了
- [ ] `./setup-hermes.sh`(または`uv pip install -e ".[all]"`)でインストール完了
- [ ] `hermes version`で0.14系が表示される
- [ ] `hermes setup`の5パート完了(Full setup選択、backend=docker)
- [ ] `~/.hermes/config.yaml`と`~/.hermes/.env`が生成されている
- [ ] `~/.hermes/auth.json`が存在(`hermes auth list`で`openai-codex`が表示される)
- [ ] `~/.hermes/.env`からTelegram botトークン行を削除済み
- [ ] `op run --env-file=$HOME/.hermes/secrets.env -- hermes gateway`で起動成功
- [ ] Telegramで自分のbotに話しかけてHermes Agentから返信が来る

## つまずき集(まとめ)

第4回で踏んだ落とし穴を再掲する。

### 1. v0.14.0の既知バグ(`'NoneType' object is not iterable`)

リリースtag(`v2026.5.16`)で運用すると踏む。**mainブランチに切り替えて再インストール**が解消法。

### 2. セットアップウィザードの「Quick / Full」選択

Quickだとbackend設定が漏れる。**Fullを選ぶ**のが本シリーズの方針に合う。

### 3. Image Generation Providerの下矢印1回罠

`OpenAI [paid]`(API key必須)を間違えて選ばないよう、**下矢印2回**で`OpenAI (Codex auth) [free]`に合わせる。

### 4. Telegram botトークンの`.env`平文化

セットアップウィザード中に入力するとディスクに平文で残る。setup完了後に該当行を削除し、`op run`経由で起動する運用に一本化する。

### 5. Codex OAuthはセットアップウィザードで一緒に登録される

`hermes auth add openai-codex`を別途実行する必要はない(第5回で再認証する場合は実行)。

### 6. `./setup-hermes.sh`が作るvenvは`venv/`(`.venv/`ではない)

`source venv/bin/activate`でアクティベートする。ピリオドの位置に注意。

### 7. Telegram「Chat not found」エラー

botにユーザーから最初のメッセージを送ってchat確立してから再起動。

### 8. Ubuntu 26.04ではPlaywright Chromiumが未対応

Browser toolsは当面使えない。Hermes Agent本体のテキスト応答は問題なし。Playwright更新待ち。

## まとめ

第4回で「Hermes Agent本体がVPSで動く」状態を作った。第3回までで作った1Password運用の上にHermes Agentを乗せて、Telegramから話しかけたら返事が来る。

最大の判断は「リリースtagではなくmainブランチで運用する」こと。Hermes Agentは開発が活発で、tagリリースに未解決バグが残る場面がある。**Issueを追って、必要ならmain運用に切り替える**判断を都度する必要がある。

第5回でGrok OAuth(SSHトンネリング必要)を追加し、承認モード(ask)を固定して、具体的な指示の疎通確認に進む。第6回でsystemdユーザーサービスに登録して、SSH切断後も24時間動く常駐運用に切り替える。

## 公式ドキュメント引用元一覧

| 項目 | 引用元 |
|---|---|
| Hermes Agentリポジトリ | [github.com/NousResearch/hermes-agent](https://github.com/NousResearch/hermes-agent) |
| 本記事参照tag | [release v2026.5.16](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.5.16)=v0.14.0(執筆時点。最新は[v2026.5.29](https://github.com/NousResearch/hermes-agent/releases/tag/v2026.5.29)=v0.15.1で、NoneTypeバグは解消済み) |
| Pythonバージョン要件 | [pyproject.toml](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/pyproject.toml) `requires-python = ">=3.11"` |
| CLIコマンド定義 | [hermes_cli/main.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/main.py) |
| セットアップウィザード構成 | [hermes_cli/setup.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/setup.py) |
| OAuth実装 | [hermes_cli/auth.py](https://github.com/NousResearch/hermes-agent/blob/v2026.5.16/hermes_cli/auth.py) |
| 既知バグ修正PR | [PR #32963 fix(agent): recover Codex Responses streams with null output](https://github.com/NousResearch/hermes-agent/pull/32963) |
| 関連Issue(canonical) | [#11179](https://github.com/NousResearch/hermes-agent/issues/11179) |
| Docker公式インストール手順 | [docs.docker.com/engine/install/ubuntu](https://docs.docker.com/engine/install/ubuntu/) |
