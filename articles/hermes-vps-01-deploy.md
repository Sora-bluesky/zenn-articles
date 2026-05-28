---
title: "【第1回】Hermes AgentをVPSに常駐させる──契約からログインまで"
emoji: "🤖"
type: "tech"
topics: ["ai", "vps", "hermes", "ubuntu", "個人開発"]
published: false
---

## 本記事の章ジャンプ

- [はじめに](#section-1)
- [そもそも Hermes Agent とは](#section-2)
- [なぜいま Hermes Agent なのか](#section-3)
- [構成の全体像](#section-4)
- [XServer VPS 6GB を契約する](#section-5)
- [Linux でつまずかないための最低限の知識](#section-6)
- [root初回ログインからadminへの引っ越しまで](#section-7)
- [つまずき集](#section-8)
- [まとめ](#section-9)

:::message
このシリーズはHermes AgentをVPSに常駐させるまでの実録だ。全10回を予定している。

- **第1回**(本記事)──Hermes AgentをVPSに常駐させる(契約からログインまで)
- 第2回──Hermes Agentの公開SSHをTailscaleで安全に閉じる
- 第3回──Hermes Agentの秘密情報を1Passwordで平文に出さない運用
- 第4回──Hermes Agentを実体としてVPSに置く(インストールとDockerサンドボックス)
- 第5回──Hermes AgentをCodex/GrokとTelegramに繋ぐ(承認モード固定の作法)
- 第6回──Hermes Agentをsystemdで24時間常駐させる
- 第7回──Hermes Agent Cronで毎朝の定型を任せる
- 第8回──Hermes Agent Skillsに手順を覚えさせる
- 第9回──Hermes AgentのWeb/X検索を使い分ける
- 第10回──Hermes Agentの手足に自宅のデスクトップを使う(Wake-on-LANとzellij)
:::

<a id="section-1"></a>
## はじめに

自律型AIエージェント Hermes Agent を VPS に常駐させた記録だ。XServer VPS 6GB(Ubuntu 26.04)を契約し、ログイン可能な状態にして、管理ユーザー(admin)を作成し、SSH鍵認証に切り替え、rootのSSHログインを閉じるところまでを扱う。

実機で打ちながら書いたメモなので、きれいな手順書ではない。詰まった場所も含めて読んでもらいたい。

<a id="section-2"></a>
## そもそも Hermes Agent とは

Hermes Agent は Nous Research が公開しているオープンソースの自律型AIエージェントだ。永続的なメモリと自己生成スキルを持ち、Telegram などのメッセージングから話しかけて使える。

構成を役割で分けると、3つの登場人物がいる。

| 役割 | 担当 | 説明 |
|------|------|------|
| 司令塔 | Hermes Agent本体 | 指示を受け、計画を立て、実行を差配する |
| 考える役 | AIモデル(Codex gpt-5.5 / Grok 4.3) | 実際の思考を担当。複数モデルを切り替え可能 |
| 手足 | 作業用マシン | 重い処理・長時間タスクを実際にこなす |

ポイントは、Hermes本体は「段取り役」であり、思考そのものは外部のAIモデルに委ねている点だ。私の環境では既存のChatGPT/CodexサブスクリプションをOAuthで繋ぎ、`openai-codex`プロバイダ(2026年5月時点での最新Codexモデル)で動かしている。xAIの最新Grokに切り替えたい場合は`xai-oauth`プロバイダを選ぶ。具体的な切り替えコマンドは第5回(Codex/Telegram接続)で扱う。

<a id="section-3"></a>
## なぜいま Hermes Agent なのか

Hermes Agentが2026年に入ってから急激に存在感を増している。数字で言うと、2026年2月25日のローンチから約90日で**GitHubスター14万超・貢献者1,000人近く**を集め、5月10日時点で **OpenRouterの全AIエージェント中で日次トークン消費1位**(224B/日)に立った。前任者のOpenClawの186B/日を抜き、約30%のOpenClawユーザーが乗り換えたとされる(Reddit調査)。

参考:
- [OpenClaw vs Hermes Agent (MarkTechPost)](https://www.marktechpost.com/2026/05/10/openclaw-vs-hermes-agent-why-nous-researchs-self-improving-agent-now-leads-openrouters-global-rankings/)
- [Persistent AI Agents Compared (The New Stack)](https://thenewstack.io/persistent-ai-agents-compared/)
- [Hermes Agent公式GitHub README](https://github.com/NousResearch/hermes-agent)

### 他のAIツールとの違いは何か

「AIに話しかけて作業させる」だけなら、すでに Claude Code、Codex CLI、Cursor、Continue.dev など類似ツールは山ほどある。Hermes Agentが違うのは、**ツールではなく常駐型エージェント**として設計されている点だ。比較表で整理する。

| プロダクト | 形態 | 主用途 | 永続メモリ | 24時間運用 | 入口 |
|---|---|---|---|---|---|
| **Hermes Agent** | 常駐エージェント | 汎用タスク | 〇(セッション横断+スキル自動生成) | 〇(VPS/サーバレス対応) | Telegram/Discord/Slack等+CLI |
| OpenClaw | 常駐エージェント | 汎用タスク | △(統合の幅は広いが学習浅め) | 〇 | 多数のプラットフォーム |
| Claude Code | CLIツール | コーディング特化 | × セッション限り | × ローカル対話 | ターミナル/エディタ拡張 |
| Codex CLI | CLIツール | コーディング特化 | × セッション限り | × ローカル対話 | ターミナル |

Claude Code・Codex CLIは「対話型のコーディングアシスタント」で、Hermes Agentは「常駐の汎用秘書」と理解するとずれない。

### Hermes Agentがほかと違うところ

公式READMEと運用記事の双方から浮かぶ設計判断を見ていく。

**自己改善ループ**(Self-improving learning loop)

Hermes Agent最大の特徴は、5回以上ツールを呼んだタスクの後に**reflectionを実行して、再利用可能なスキルファイルを自動生成する**点だ。reflectionは振り返りの意味。同じ調査・同じセットアップを次回繰り返さない。OpenClawが「統合の幅」に振っていたのに対し、Hermes Agentは「学習の深さ」に振った設計上の判断がここに表れている。

**メッセージングから常駐操作**

Telegram、Discord、Slack、WhatsApp、Signal、CLIの6入口に対応(対応プラットフォーム数だけで言えばOpenClawの20より少ないが、コア機能は揃う)。スマホからLINEのような感覚で話しかけて、VPS上で長時間タスクを走らせる、という運用が成立する。音声メモも自動文字起こしされる。

**どこにでも置ける**(7つのバックエンド)

local / Docker / SSH / Singularity / Modal / Daytona / Vercel Sandboxの7つから実行先を選べる。ModalやDaytonaを使えば**使ってないときは寝かせておいて、要求が来た瞬間に起こす**サーバレス運用も可能。私はXServer VPS 6GBで常駐させているが、これも公式が想定するパターンの1つ。

### Xでよく見るリアクション

X(旧Twitter)・開発者コミュニティで頻出する反応は以下の3つに集約される。

- 「OpenClawから乗り換えて、初期設定の手間が減った」(Reddit/Medium複数)
- 「LLMのモデル選択肢が広い(Nous Portal経由なら300+モデル、OpenRouter経由で200+)。1サブスクで複数モデル切替えができる」
- 「自己生成スキルが地味に効く。同じ調査を二度しなくて済む」

OpenClawが2026年初頭にセキュリティ問題とリーダー離脱で揺れた時期と、Hermes Agentの台頭が重なったタイミングの要素も大きいが、技術的な勝因は**学習ループの設計**にあると見られている([Turing Post解説](https://www.turingpost.com/p/hermes))。

<a id="section-4"></a>
## 構成の全体像

私が落ち着いた構成はこうだ。

![Hermes Agent運用の全体像（VPS司令塔＋自宅デスクトップ手足の2層分離）](/images/hermes-vps/hermes-architecture.png)

- **VPS（クラウド上）= 司令塔**：Hermes 本体を常駐させる。24時間起きている安価な受付係
- **自宅のデスクトップ = 手足**：重い処理やGPUを使うタスクだけ、必要なときに引き受ける
- **Tailscale = 専用通路**：VPSと自宅マシンを、インターネットに晒さずに繋ぐ非公開トンネル
- **1Password = 保管庫**(英語UIではVault)：APIキー・botトークン・SSH鍵などの秘密情報を平文に出さず保管
- **Telegram = 窓口**：手元のスマホ/PCから Hermes に話しかけて応答を受ける
- **考える役 = Codex**(gpt-5.5):Hermes が思考を委ねる外部のAIモデル。OAuthで接続

VPSは常時起動が安く済むが非力、自宅機はパワーがあるが24時間つけっぱなしは電気代と発熱がかさむ。役割分担として「常に起きている受付」はVPSに、「重い処理」は自宅機にする構成だ。自宅側はLenovo ThinkStation P2(i7-14700K+RTX 4070、メモリ16GB)を使う。これは現役の高性能機だが、メイン作業はノートPC(Windows)で済ませる前提で、このデスクトップはAI推論専用機としてWindowsを消してLinuxを入れ直してある。

自宅機の構成判断(Linux専用機として運用する選択・GPUドライバ・BIOS設定の罠)の詳細は第10回(P2を実行先として追加)で詳述する。第1回では「自宅機=AI推論専用のLinux機」とだけ覚えておけばよい。

このシリーズでは、図の中の各要素を回ごとに実装する。第1回はVPSを契約してadminで安全にログインできるところまでを片付ける。

<a id="section-5"></a>
## XServer VPS 6GB を契約する

ここから実際の構築に入る。プロバイダは XServer VPS の 6GB プランを選んだ（4コア / 6GB / SSD 150GB / 月1,800円前後）。プラン選定の経緯はこの後の「つまずき集」で書く。

申込みからダッシュボードに到達するまでの実画面を順番に貼っておく。

**1. プランを選ぶ**(6GB)

![XServer VPS プラン選択画面（6GBプラン）](/images/hermes-vps/hermes-vps-01-plan-6gb.png)

**2. 申込フォームに必要事項を入力**

![XServer VPS 申込フォーム](/images/hermes-vps/hermes-vps-01-application-form.png)

**3. 申込内容の確認**

![申込内容確認画面](/images/hermes-vps/hermes-vps-01-application-review.png)

**4. 支払い方法を選ぶ**

![支払い方法選択画面](/images/hermes-vps/hermes-vps-01-payment-method.png)

**5. ダッシュボードでサーバーが起動していることを確認**

![XServer VPS ダッシュボード稼働中](/images/hermes-vps/hermes-vps-01-dashboard-running.png)

OSは Ubuntu 26.04 LTS を選んだ（XServerは2026年4月に26.04対応済み）。「Dockerアプリイメージ」のような構築済みテンプレートは選ばず、素のUbuntuにする。Dockerは後の回で手動で入れる方針だ。

なぜ Ubuntu 26.04 LTS を選んだかは次の節で書く。

<a id="section-6"></a>
## Linux でつまずかないための最低限の知識

「VPS を借りた、で、何をすればいいんだ」という人のために、この記事を読み進めるうえで最低限知っておいたほうがいい Linux の知識をまとめる。すでに分かっている人は読み飛ばしてかまわない。

### ディストリビューションの選び方

Linux には「ディストリビューション」と呼ばれる派生バージョンがいくつもある。Windows でいえば「Windows 11 Home / Pro」のような違い、ではなく、もう少し本格的な分岐で、それぞれ思想と用途が違う。

| ディストリ | 性格 | 採用される場面 |
|---|---|---|
| **Ubuntu** | デスクトップ・サーバーともに情報量No.1。LTSは5年サポート | 個人サーバー、AI開発、初学者 |
| Debian | 安定重視。Ubuntu のベースになっている派生元 | 長期運用前提のサーバー |
| CentOS Stream | Red Hat 系。本番用途には推奨されない（無印 CentOS は2021年末EOL） | 学習用途のみ |
| Fedora | Red Hat 系の最先端。更新サイクルが速い | 開発機・実験用 |

私が **Ubuntu 26.04 LTS** を選んだ理由は3つある。

1. **情報量**：何かに詰まったとき、日本語・英語ともに解決情報が一番多い。NVIDIA ドライバや CUDA、Docker の公式対応もまず Ubuntu から始まる
2. **長期サポート**(LTS):26.04 LTS は 2031年4月までサポートされる。常時起動のサーバー機には「大型更新に振り回されない安心」が要る
3. **VPSと自宅機の統一**：後に出てくる自宅機（P2）にも同じ Ubuntu 26.04 を入れる予定。2種類の Linux を覚えずに済む

「とりあえずサーバーを建てたい」目的なら、Ubuntu LTS を選んで間違いはほぼない。

### コマンドと用語のミニ辞書

この記事の後半（と、シリーズの後の回）に出てくるコマンドを、初級者目線で並べておく。

| 用語/コマンド | 何のためのもの |
|---|---|
| `sudo` | 普段は弱い権限で動き、必要なときだけ管理者で実行する命令の前置詞 |
| `apt update` | パッケージの「商品カタログ」を最新版に更新する |
| `apt upgrade -y` | 古いパッケージを実際に最新版に入れ替える。`-y`は「全部yesでいい」の意 |
| `&&` | 前のコマンドが成功したら次を実行する区切り。失敗したら止まる |
| `adduser admin` | 新しい一般ユーザー`admin`を対話的に作る |
| `usermod -aG sudo admin` | `admin`をsudoグループに「追加で(-aG)」入れる |
| `~/` と `~/.ssh` | そのユーザー専用の作業場所。`~/.ssh`はSSH関連ファイル置き場 |
| `chmod 700 ディレクトリ` | 「本人だけ読み書き実行できる」設定。他人完全シャットアウト |
| `chmod 600 ファイル` | 「本人だけ読み書きできる」設定。秘密鍵やトークン用 |
| `chmod 755 ディレクトリ` | 「本人は読み書き実行、他人は読み実行のみ」の標準的なホーム権限 |
| `chown -R user:user ディレクトリ` | ディレクトリと中身を再帰的に所有者変更(`-R`が再帰、`ユーザー名:グループ名`形式) |
| 公開鍵と秘密鍵 | 公開鍵=相手(サーバー)に渡してOK。秘密鍵=絶対に手元から出さない |

`sudo` と `apt update && apt upgrade -y` だけは絶対に出てくるので、これだけは意味を覚えてから先へ進む。

<a id="section-7"></a>
## root初回ログインからadminへの引っ越しまで

ここからは構築中に追記していく。シリアルコンソールからrootで入った直後の作業だ。

### ここから先で聞かれるパスワードを整理する

各場面で「ここで聞かれているのは何のパスワードか」を取り違えるのが、一番ありがちなミスだ。私自身も区別がつかず何度もミスした。先に対応表をまとめておく。

| 場面 | 何のパスワード | 1Passwordアイテム |
|---|---|---|
| シリアルコンソールの`login: root` | rootのログインパスワード | XServer発行の初期パスワード(後で`Hermes VPS - root`に置き換え) |
| `adduser admin`の対話 | adminの**新規**パスワードを設定 | `Hermes VPS - admin`(20文字ランダム生成) |
| `passwd root`の対話 | 現在のrootパスワード→新パスワード | 旧:XServer初期、新:`Hermes VPS - root` |
| `ssh-keygen`の`Enter passphrase` | SSH鍵のパスフレーズを設定 | `Hermes VPS - SSH key passphrase`(20文字) |
| `ssh -i ... admin@<IP>`の`Enter passphrase for key` | SSH鍵のパスフレーズ | `Hermes VPS - SSH key passphrase` |
| `sudo whoami`の`[sudo:authenticate]` | adminのログインパスワード | `Hermes VPS - admin` |
| シリアルコンソールの`login: admin` | adminのログインパスワード | `Hermes VPS - admin` |

要点は3つ:

- **シリアルコンソール経由のパスワード入力は画面に何も表示されない**(伏字すら出ない)。打ち間違えに気づきにくい
- **`Ctrl+V`は効かない**。貼り付けは右クリックメニューから
- **「鍵のパスフレーズ」と「ユーザーのログインパスワード」は別物**。鍵のパスフレーズはSSH接続時、ユーザーパスワードはsudo実行時やシリアルコンソール直接ログイン時

### シリアルコンソールの開き方

そもそも管理画面のどこからシリアルコンソールにアクセスするのか、私も最初は迷った。XServer VPSパネルの「VPS管理」ページを開いて、右上の「**コンソール**」ボタンをクリックすると、ドロップダウンに「シリアルコンソール」「VNCコンソール」の2つが現れる。今回使うのは「**シリアルコンソール**」だ。

![XServer VPSパネルの右上「コンソール」→「シリアルコンソール」メニュー位置](/images/hermes-vps/hermes-vps-01-xserver-console-menu.png)

VNCコンソールはGUI画面を遠隔表示する方式で、CUIだけで運用するHermesには不要。シリアルコンソールのほうがブラウザだけで完結し軽快だ。

シリアルコンソールが新しいタブで開いたら、**最初は黒い空画面**が表示される。ここでENTERキーを一度押すと、ようやく`<ホスト名> login:`プロンプトが現れる。私はこれを知らず、しばらく真っ黒な画面を眺めて固まっていた。

ENTERを押した後にプロンプトが表示されたら、`root`と入力してENTER。

![シリアルコンソールに接続後、loginプロンプトにrootと入力したところ(ホスト名はマスク)](/images/hermes-vps/hermes-vps-01-serial-login.png)

ここでパスワード(XServer発行の初期パスワード)を聞かれる。**シリアルコンソールは`Ctrl+V`が効かないので、貼り付けは右クリックメニューから**。パスワード入力中は画面に何も表示されない(伏字すら出ない)ので、貼り間違いに気づきにくい。

:::message alert
パスワードが通らないときは、まず右クリックメニューから貼り付けを試すこと。`Ctrl+V`が無効なシリアルコンソールに気づかず、パスワード自体を疑って堂々巡りになる人が多い。詳細はこの記事の最後の「つまずき集」に書いた。
:::

### 1. パッケージを最新にする

```bash
apt update && apt upgrade -y
```

このコマンドは「`apt update`(カタログ更新)」と「`apt upgrade -y`(中身の入れ替え・全部yes)」を`&&`で繋いだもの。サーバーを借りた直後に必ず一度通すコマンドだ。

実行すると、まずカタログ取得（`ヒット:1 http://...` の繰り返し）が走り、アップグレード対象が表示される。

![apt update 実行中・アップグレード対象3パッケージ表示](/images/hermes-vps/hermes-vps-01-apt-upgrade-progress.png)

私のVPSではアップグレード対象が3パッケージ（`base-files / distro-info-data / motd-news-config`）、ダウンロードサイズ 86.4 kB と表示された。

完了すると、カーネル更新が含まれていた場合は「Pending kernel upgrade!」と再起動推奨のメッセージが出る。

![apt upgrade 完了後・カーネル更新による再起動推奨表示](/images/hermes-vps/hermes-vps-01-apt-upgrade-complete.png)

カーネルが更新された場合は `reboot` で再起動しておく。再起動後はシリアルコンソールから入り直す。

### 2. 非rootユーザーを作る

root のまま運用するのは危ない。誤ったコマンドが即・全システム破壊につながる。普段使うユーザーとして `admin` を作り、必要なときだけ `sudo` で管理者権限を借りる、というのが Linux の作法だ。

```bash
adduser admin
usermod -aG sudo admin
mkdir -p /home/admin/.ssh
cp /root/.ssh/authorized_keys /home/admin/.ssh/authorized_keys
chown -R admin:admin /home/admin/.ssh
chmod 700 /home/admin/.ssh
chmod 600 /home/admin/.ssh/authorized_keys
chmod 755 /home/admin
```

何をしているか、1行ずつ短く解説する。

- `adduser admin`──adminユーザーを対話的に作る。会話形式でパスワードを聞かれる
- `usermod -aG sudo admin`──adminにsudoを使う権限を付ける
- `mkdir -p /home/admin/.ssh`──adminのSSH関連フォルダを作る
- `cp /root/.ssh/authorized_keys /home/admin/.ssh/authorized_keys`──rootに登録してある公開鍵をadminにもコピーする
- `chown -R admin:admin /home/admin/.ssh`──所有者をadminに変える(rootのままだとadminが読めない)
- `chmod 700 /home/admin/.ssh` と `chmod 600 ファイル`──本人以外に読み書きを禁じる。SSHは権限がゆるいと弾く仕様
- `chmod 755 /home/admin`──ホームフォルダ自体は「本人は読み書き実行、他人は読み実行のみ」に設定。adduserが同じ権限を自動で付けるので、ここは確認の意味で実行する

:::message
もし`cat /root/.ssh/authorized_keys`の中身が空だった場合、`cp`コマンドは空ファイルをコピーして終わる。これはXServerパネルでのSSH Key登録がサーバー内に反映されていないケースで、後でadminログインが鍵認証で弾かれる原因になる。つまずき集の「XServerでSSH Key登録しただけでは、サーバー内に書かれない」を先に処置してから戻ってきてほしい。
:::

`adduser`を実行すると、まずパスワード設定の対話が始まる。

![adduserコマンドが新しいパスワードの入力を求める画面](/images/hermes-vps/hermes-vps-01-adduser-password-prompt.png)

ここで設定するadminのパスワードは、後で`sudo`コマンドを使うたびに必要になる。**1Passwordなどのパスワードマネージャーで20文字以上のランダム文字列を生成して使うのが安全**。シリアルコンソールは`Ctrl+V`が効かないので、貼り付けは**右クリックメニュー**から。

パスワード設定後、adduserはフルネーム・部屋番号・電話などを順に聞いてくる。

![adduserがフルネーム・部屋番号・電話などを順に聞いてくる画面](/images/hermes-vps/hermes-vps-01-adduser-userinfo-prompt.png)

このユーザー情報は**全部空ENTERでスキップしてOK**。最後の「以上の情報を確認してください[Y/n]」で`Y`+ENTER。

![adduser対話完了画面・全項目空ENTERで通過して情報確認まで来た状態](/images/hermes-vps/hermes-vps-01-adduser-done.png)

### 3. rootのパスワードを変更する

サーバー契約時に発行されたroot初期パスワードは、契約画面・メール・パネル等に痕跡が残る。Hermes本番運用に入る前に、自分が完全にコントロールする新しいパスワードに置き換えておく。

```bash
passwd root
```

- 現在のパスワード(初期パスワード)を入力
- 新しいパスワード(1Passwordで20文字ランダム生成して貼り付け)
- 再入力で同じものを貼り付け

「passwd:パスワードは正しく更新されました」が出れば完了。

![passwd rootでrootパスワード変更が完了した画面](/images/hermes-vps/hermes-vps-01-passwd-root-done.png)

これで初期パスワードは無効化され、1Password側に保管した新パスワードのみがroot権限への鍵になる。

### 4. SSH鍵を手元で生成する

ここはVPS上ではなく、**自分のPC**でやる作業だ。秘密鍵はサーバーに置かない。手元で作り、公開鍵だけをVPSにコピーする。

PowerShellまたはGit Bashで以下を実行する。

```bash
ssh-keygen -t ed25519 -C "hermes-vps" -f ~/.ssh/hermes_vps_ed25519
```

コマンド各部分の意味は次のとおり。

| 部分 | 役割 |
|---|---|
| `ssh-keygen` | SSH用の鍵ペアを生成するコマンド本体 |
| `-t ed25519` | 鍵の方式(アルゴリズム)を指定 |
| `-C "hermes-vps"` | 鍵のコメント(用途メモ)。後で「これ何の鍵だっけ」と分からなくなる対策 |
| `-f ~/.ssh/hermes_vps_ed25519` | 出力先のファイル名 |

#### なぜ`ed25519`を選ぶか

SSH鍵の方式はいくつかあるが、2026年時点で新規生成するなら`ed25519`一択だ。

| 方式 | 鍵サイズ | 速度 | 採用すべきか |
|---|---|---|---|
| **ed25519** | 約68バイト(小) | 速い | 推奨 |
| RSA 2048 | 約400バイト | 遅い | 非推奨(やや弱め) |
| RSA 4096 | 約800バイト | 遅い | 互換性が必要なときのみ |
| ECDSA(NIST曲線) | 短め | 速い | 非推奨(設計に不信) |

`ed25519`はCurve25519という楕円曲線をベースにした現代の標準で、サイドチャネル攻撃にも強い。OpenSSH 6.5(2014年)以降で標準サポートされ、GitHub・GitLab・主要VPSプロバイダはすべて対応済み。`RSA 2048`は短さゆえに将来の計算能力向上で危なくなる懸念があり、`ECDSA`は採用されているNIST曲線そのものへの不信(Dual_EC_DRBG事件)があって、業界では`ed25519`に移行している。

#### 実行と完了

実行するとパスフレーズを2回聞かれる。

```
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
```

ここで設定するパスフレーズは、**秘密鍵そのものの第二の錠前**だ。万が一秘密鍵ファイルを盗まれても、このパスフレーズが破られない限り攻撃者はサーバーに入れない。空(empty)も技術的には可能だが、本番運用では必ず20文字以上のランダム文字列を1Passwordで生成して使う。

完了すると以下のように、生成された鍵の保存先・fingerprint・randomart(視覚的な指紋)が表示される。

![ssh-keygen実行完了画面・fingerprintとrandomart表示](/images/hermes-vps/hermes-vps-01-ssh-keygen-output.png)

そして以下の2ファイルが作られる。

| ファイル | 中身 | 渡してよいか |
|---|---|---|
| `~/.ssh/hermes_vps_ed25519` | 秘密鍵 | **絶対に手元から出さない** |
| `~/.ssh/hermes_vps_ed25519.pub` | 公開鍵 | サーバーに渡してOK |

### 5. 公開鍵をXServerに登録してadminでSSHログイン

生成した公開鍵(`.pub`の中身)をXServerパネルに登録する。

PowerShellで公開鍵を表示してクリップボードにコピーする。

```bash
cat ~/.ssh/hermes_vps_ed25519.pub
```

出力された1行(`ssh-ed25519 AAAA...hermes-vps`の形)を全選択してコピー。

XServerパネルの左サイドバー「**SSH Key**」を開き、登録方法で「**インポート**」を選択、公開鍵フィールドにコピーした1行を貼り付けて「確認画面へ進む」をクリック。

![XServerパネルのSSH Key登録画面(インポートを選択、公開鍵を貼り付け)](/images/hermes-vps/hermes-vps-01-xserver-ssh-key-register.png)

登録が完了したら、パケットフィルター設定で22番(SSH)を許可する。XServerパネルの「VPS管理」→対象サーバーを選択→左メニューの「パケットフィルター設定」を開く。

![VPSパネル左メニューの「パケットフィルター設定」(赤枠)](/images/hermes-vps/hermes-vps-01-xserver-packet-filter-menu.png)

パケットフィルター設定画面が表示される。現在は接続許可ポートが何も登録されていない状態なので、「**+パケットフィルター設定を追加する**」をクリック。

![パケットフィルター設定画面で「+パケットフィルター設定を追加する」をクリック](/images/hermes-vps/hermes-vps-01-xserver-packet-filter-list.png)

ルール追加フォームが現れるので、フィルターに**SSH**を選ぶ(プロトコル`TCP`、ポート番号`22`、許可する送信元IPアドレス「全て許可」が自動で入る)。「**追加する**」をクリック。反映に1〜2分かかる。

![フィルターでSSHを選び「追加する」をクリックする画面](/images/hermes-vps/hermes-vps-01-xserver-packet-filter-add-ssh.png)

:::message alert
「全て許可」は**世界中のIPから22番にアクセスできる状態**だ。鍵認証onlyなのですぐにロックアウトされる確率は低いが、ブルートフォースのログが溜まり始めるので、**第2回のTailscale設定はできるだけ早く済ませる**(最短で同日中、というイメージ)。終わったらこのルール自体を削除する。「許可する送信元IPアドレス」を自宅の固定IPだけに絞る運用も可能だが、根本対策はTailscale移行。
:::

ここまで来たら、手元のPCからadminでSSHログインを試す。

```bash
ssh -i ~/.ssh/hermes_vps_ed25519 admin@<グローバルIP>
```

初回は`The authenticity of host '...' can't be established`と聞かれるので`yes`+ENTERで進める。その後、鍵のパスフレーズを聞かれるので1Passwordの「Hermes VPS - SSH key passphrase」からコピーして貼り付ける。

ログインできたら以下を実行する。

```bash
sudo whoami
```

`root`が返れば、adminでの公開鍵ログイン+sudo権限が成立している。

![adminでSSHログインに成功し、sudo whoamiでrootが返った画面](/images/hermes-vps/hermes-vps-01-admin-login-success.png)

ターミナルのタブタイトルが`admin@<ホスト名>:~`になり、シリアルコンソールを通さずに手元のPowerShellから直接サーバーに入れる状態だ。ここまで来ればVPS構築の半分は終わっている。

### 6. rootのSSHログインを閉じる

adminでログインできることを確認したら、その流れで rootのSSHログインを締めておく。`root` という名前は世界中の攻撃者に知られていて、22番ポートが開いている限りブルートフォース対象になる。adminだけログインできる状態にしておけば、攻撃面を一段下げられる。

sshd_config を編集する。

```bash
sudo nano /etc/ssh/sshd_config
```

以下の3行を確認する(コメントアウト`#`があれば外す、値が違えば書き換える)。`Ctrl+W`で各キーワードを検索しながら見つけていくのが速い。

`PermitRootLogin no`は、rootのSSHログインを禁止する設定。

![sshd_configでPermitRootLogin noを設定したところ](/images/hermes-vps/hermes-vps-01-sshd-permit-root-login.png)

`PasswordAuthentication no`は、パスワードによるログインを禁止する設定(鍵認証のみ許可)。

![sshd_configでPasswordAuthentication noを設定したところ](/images/hermes-vps/hermes-vps-01-sshd-password-auth.png)

`PubkeyAuthentication yes`は、公開鍵認証を有効化する設定。デフォルトで`yes`だが、`#`コメントアウトされている場合は明示的に`#`を外して有効化する(後述のcloud-init上書き対策にもなる)。

![sshd_configでPubkeyAuthentication yesを設定したところ](/images/hermes-vps/hermes-vps-01-sshd-pubkey-auth.png)

保存(`Ctrl+O`+ENTER→`Ctrl+X`)したらSSHを再起動する。

```bash
sudo systemctl restart ssh
```

#### cloud-init側の上書き設定もチェック

Ubuntuのsshd_configは、メインファイル(`/etc/ssh/sshd_config`)の先頭で`Include /etc/ssh/sshd_config.d/*.conf`という1行を読み込んでいる。これは「`.d`フォルダの中の設定ファイルもまとめて取り込め」という指示で、クラウド系イメージ(XServerやAWS等)では cloud-init が `.d` 配下に追加設定を書き込んでくる。

その追加設定の中で `PermitRootLogin` の値が`prohibit-password`等で上書きされていると、メインのsshd_configを`no`にしたつもりが効かない、という事故が起きる。**メインだけ変えても安心できない**のがcloud-init絡みのSSH設定の罠だ。

念のため横断検索する。

```bash
sudo grep -r "PermitRootLogin" /etc/ssh/
```

結果の読み解きは以下の通り。

| 行のパス | 種類 | 効力 |
|---|---|---|
| `/etc/ssh/sshd_config:PermitRootLogin no` | 有効な設定行 | 効く |
| `/etc/ssh/sshd_config:# the setting of "..."` | コメント(`#`始まり) | 効力なし |
| `/etc/ssh/sshd_config.d/*.conf:PermitRootLogin ...` | cloud-init等が書いた上書き設定 | **要編集** |
| `/etc/ssh/sshd_config.ucf-dist:...` | ucfツールの配布元バックアップ | **無視してOK** |

`.ucf-dist`拡張子はDebian/Ubuntuのucf(Update Configuration File)ツールが使う「パッケージ配布時のオリジナル設定」のバックアップで、`apt`等でOpenSSHが更新されても自分の設定が消えないようにする仕組みです。sshd自体は`.ucf-dist`を読み込まないので、結果に出てきても気にしなくて構いません。

要対応は`/etc/ssh/sshd_config.d/`配下の`.conf`ファイルだけ。出てきたら開いて`PermitRootLogin no`に揃える。

```bash
sudo nano /etc/ssh/sshd_config.d/50-cloud-init.conf
```

私の環境では`/etc/ssh/sshd_config.d/`配下にcloud-initファイルが存在せず、メインの`/etc/ssh/sshd_config`の`PermitRootLogin no`が唯一の有効設定として効いている状態だった。XServer VPSのUbuntu 26.04クリーンイメージでは、cloud-initが`sshd_config.d`に介入していないようだ。

#### 別ターミナルからroot拒否を確認

別のPowerShellタブから`ssh root@<グローバルIP>`を試して、弾かれることを確認する。

```bash
ssh root@<グローバルIP>
```

`Permission denied (publickey).`が返れば成功。`(publickey,password)`ではなく`(publickey)`単独で出ていれば、`PasswordAuthentication no`も効いてパスワード認証経路ごと閉じている状態だ。

![rootへのSSH接続がPermission denied (publickey)で拒否される画面](/images/hermes-vps/hermes-vps-01-root-ssh-rejected.png)

:::message alert
sshd_configを変えるときは**必ず別ターミナルで自分のadminログインが生きていることを確かめてから**保存する。設定ミスでadminもログイン不可になったら、XServerのシリアルコンソールから入って`sudo nano /etc/ssh/sshd_config`で`PermitRootLogin yes`に戻し、`sudo systemctl restart ssh`で復旧する。命綱はコンソール、というのはこのためだ。
:::

<a id="section-8"></a>
## つまずき集

ここからは、公式手順をなぞるだけでは出てこない、実際にハマった箇所を時系列で記録する。

### 1. シリアルコンソールでログインに失敗──原因はコピペ方法だった

OSイメージに Ubuntu 26.04 を選び、いざブラウザのシリアルコンソールから root でログインしようとした。だが何度やっても弾かれる。

```
xNNN-NN-NN-NN login: root
パスワード:
ログインが失敗しました
```

パスワードは合っているはずなのに通らない。原因はパスワードそのものではなく、**コピペの方法**だった。ブラウザ上のシリアルコンソールは、キーボードの `Ctrl+V` での貼り付けが効かない。マウスの右クリックメニューから貼り付けたら、あっさり通った。

:::message alert
シリアルコンソールでパスワードが通らないときは、まず右クリックメニューからの貼り付けを試すこと。パスワードは入力しても画面に表示されない（伏せ字すら出ない）ので、打ち間違いに気づきにくい。
:::

### 2. 「デフォルトポート開放しない」で初回SSHが通らない理由

申し込み時に「デフォルトポート開放：利用しない」を選んだ。これはセキュリティ的には良い選択だ（最初から余計なポートを開けない）。だが副作用として、**初回のSSH（22番）接続が通らない**。

慌てる必要はない。ブラウザのシリアルコンソールは、ポート開放の設定に関係なく入れる。だから「まずコンソールから入り、ネットワークを締める前に必ずコンソールで入れることを確認しておく」のが鉄則になる。SSHが死んでもコンソールという生還経路が残っていれば、ロックアウトしない。

### 3. ログイン直後に打った最初のコマンドが弾かれた

シリアルコンソールでログインに成功し、ほっとして最初に打ったのが`root`の4文字だった。返ってきたのはこれ。

![rootコマンドが見つかりませんと表示されるシリアルコンソール](/images/hermes-vps/hermes-vps-01-root-not-found.png)

```
コマンド 'root' が見つかりません。次の方法でインストールできます:
snap install root-framework
```

ここで「ああ、入れないと使えないのか」と素直に`snap install root-framework`を実行してはいけない。提案されているROOTは、CERN（欧州原子核研究機構）が作っている**粒子物理データ解析ツール**の同名ソフトで、Hermesともサーバー運用とも一切関係がない。

そもそも何が起きていたかというと、自分はすでにrootユーザーとしてログイン済みだった、というだけの話だ。プロンプトの読み方を整理する。

| 表示 | 意味 |
|---|---|
| `root@` | 現在のユーザー名はroot |
| `xNNN-NN-NN-NN` | サーバーのホスト名（IPアドレス由来。本記事では仮値） |
| `~` | 現在の場所はホームディレクトリ（rootなら`/root`） |
| `#` | このユーザーがrootである印(一般ユーザーなら`$`) |

画像で言うと、行頭の`root@xNNN-NN-NN-NN:~#`の末尾の`#`がそれだ。rootは「コマンド」ではなく「ユーザー名」で、Linuxにrootというコマンドは存在しない。WindowsでいえばコマンドプロンプトにAdministratorと打つようなもので、当然「そんなコマンドはない」と返される。

:::message alert
snap（Ubuntuのパッケージ管理ツールの一つ）は、未知のコマンドが入力されると「名前が似ているパッケージ」を機械的に提案してくる。だが**提案されたものが本来の目的と一致するとは限らない**。素直に従う前に、提案されたパッケージ名を一度ググること。
:::

### 4. adduserをやり直したらグループ残骸エラー＋文字化けの二重苦

`adduser admin`を実行すると、設定途中で中断されて未完成のまま終わることがある（パスワード入力ミス、回線切断など）。そのまま気付かずに同じコマンドを再実行すると、こんなエラーに出会う。

![adduserでグループadminがすでに存在するエラーが文字化けして表示されている画面](/images/hermes-vps/hermes-vps-01-adduser-group-exists.png)

```
fatal: ã°ã«ã¼ã 'admin' ã¯ã§ã«å­å¨ã ã¾ã
```

文字化けしているが、実体は「**fatal: グループ 'admin' はすでに存在します**」というメッセージだ。シリアルコンソールがUTF-8の日本語を正しく表示できず、Latin-1で読んだ結果こうなる。サーバーのロケールを英語のままにする方針（公式手順通り）と整合しているので、これ自体は放置していい。化けたら「あ、これはUTF-8の日本語だな」と思って、頭の中でデコードする習慣をつけるしかない。

中身の意味は単純で、前回の`adduser`が途中で失敗したときに、グループだけ作成されてユーザー本体が作られなかった、という残骸が悪さをしている。対処はこう。

```bash
# 現状確認
id admin                  # → "no such user" ならユーザーは存在しない
getent group admin        # → 行が返ればグループだけ残っている

# 残骸を消して作り直す
groupdel admin
adduser admin             # 今度は最初から成功するはず
```

:::message
`id admin`がユーザー情報を返した場合（uid=...が出てくる）はユーザーも作成済みなので、`adduser`を再実行する必要はない。残りの手順（`usermod -aG sudo admin`など）から続ければよい。
:::

### 5. yesと答えたのに「Host key verification failed」

初回SSH接続でfingerprint確認のプロンプトに`yes`と答えたら、その直後に`Host key verification failed.`で接続が切れる、というケース。

原因は`~/.ssh/known_hosts`に**過去の同じIPの別の指紋**が残っていることだ。私の場合、以前別の用途で同じIPアドレスを使ったサーバーがあり、その時の指紋が`known_hosts`に居座っていた。`yes`と答えても、既存エントリと衝突して書き込みが拒否される。

対処は1行。

```bash
ssh-keygen -R <グローバルIP>
```

これで該当IPの古い指紋が削除される。改めて`ssh -i ... admin@<IP>`を試せば、まっさらな状態でfingerprint確認に入る。

### 6. XServerでSSH Key登録しただけでは、サーバー内に書かれない

XServerパネルの「SSH Key」機能で公開鍵を登録すれば、サーバー内のauthorized_keysに自動で入る、と思い込んでいた。違った。

XServerパネルのSSH Key機能で登録した公開鍵が`/root/.ssh/authorized_keys`に自動反映されるのは、**新規サーバー作成時のみ**。既にOSが動いているサーバーに後から登録しても、サーバー内のファイルには何も書かれない。だから`ssh -i ... admin@<IP>`が鍵認証で弾かれてパスワード認証にフォールバックし、結局通らない。

確認は単純。シリアルコンソールから入って:

```bash
cat /root/.ssh/authorized_keys 2>/dev/null
cat /home/admin/.ssh/authorized_keys 2>/dev/null
```

両方とも空ならXServerパネル側の登録は反映されていない。手元PCの`~/.ssh/hermes_vps_ed25519.pub`の中身を、シリアルコンソールで`nano /home/admin/.ssh/authorized_keys`を開いて右クリック貼り付けする方式で直接書き込む必要がある。

### 7. IPアドレスを1桁打ち間違えて別サーバーに繋ぐ

VPSのグローバルIPを入れるべきところで1桁打ち間違えた。SSH接続は別の何者かのサーバーに通り、fingerprintを聞かれ、`yes`と答えた瞬間に`known_hosts`に他人の指紋が混入した。当然鍵認証は通らないので`Permission denied`が並び、原因を「鍵が悪いのか」「サーバーの設定が悪いのか」と30分探した。

エラーメッセージは「鍵認証の失敗」だが、本当の原因は「接続先IPの間違い」だった、というパターン。`ssh-keygen -R <間違ったIP>`で残骸を消したうえで、正しいIPで接続し直せば解決する。

```bash
ssh-keygen -R <間違ったIP>    # 間違ったIPのエントリを削除
ssh -i ~/.ssh/hermes_vps_ed25519 admin@<正しいIP>    # 正しいIPで再接続
```

### 8. nanoで「ディレクトリは存在しません」と言われた

(つまずき集4で`adduser`をやり直したあと、本文の`mkdir -p /home/admin/.ssh`を飛ばして公開鍵書き込みに進むとここで止まる。本文通りに順番にやれば遭遇しない。)

`nano /home/admin/.ssh/authorized_keys`を実行したら画面下に「`ディレクトリ '/home/admin/.ssh' は存在しません`」と出て編集できない、というケース。

`adduser`で残骸エラーが出た時に`groupdel admin`+再`adduser admin`を回した結果、`.ssh`ディレクトリの作成手順が抜け落ちて、書き込み先がなかった。

対処はディレクトリを先に作るだけ。

```bash
mkdir -p /home/admin/.ssh
chown admin:admin /home/admin/.ssh
chmod 700 /home/admin/.ssh
```

その後で`nano /home/admin/.ssh/authorized_keys`を開けば、空のエディタが正しく開く。

<a id="section-9"></a>
## まとめ

第1回でやったこと:

- XServer VPS 6GBの契約とプラン選定
- シリアルコンソール経由でroot初回ログイン
- パッケージ最新化(`apt update && apt upgrade -y`)
- 管理ユーザーadminの作成とsudo権限付与
- rootパスワードを1Password管理の20文字ランダムに変更
- SSH鍵(ed25519)を手元で生成、公開鍵をVPSに登録、adminでログイン確認
- rootのSSHログインを禁止(`PermitRootLogin no`)

次回はTailscaleでVPSと手元端末を非公開トンネルで繋ぎ、公開SSH(22番ポート)そのものを安全に閉じる。今回でrootのSSHログインは閉じたが、adminは22番経由で入れる状態。これをTailnet経由だけに絞る。**順番を間違えるとログインできない事故になる**急所なので、丁寧に進める。
