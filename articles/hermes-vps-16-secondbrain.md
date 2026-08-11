---
title: "【第16回】同じことを二度調べさせるな。Hermes Agentは作業履歴からセカンドブレインを作る"
emoji: "🧠"
type: "tech"
topics: ["hermes", "obsidian", "claudecode", "codex", "ai"]
published: true
---

:::message
この連載は月1,800円ほどのVPSで、自分専用のAIエージェント(Hermes Agent)を24時間動かす実録だ。これはその第16回。全体の流れは[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::

:::details シリーズのもくじ(タップで開く)

**第I部 体を作る**
- [第1回](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy) サーバー代は月1,800円で足りる。Hermes AgentはVPSで24時間動き続ける
- [第2回](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale) パスワードはもう打つな。Hermes AgentへのSSHは鍵一発で入れる
- [第3回](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password) APIキーをそのまま書くな。Hermes Agentの秘密は1Passwordが預かる
- [第4回](https://zenn.dev/sora_biz/articles/hermes-vps-04-install) Hermes AgentをDockerで隔離して動かす方法
- [第5回](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord) コマンドを覚えるな。Hermes AgentはDiscordで話しかけるだけで動く
- [第6回](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd) 気づいたら止まっている、をなくせ。Hermes Agentはsystemdでいつも動き続け、落ちてもすぐ戻る

**第II部 顔と操作席**
- [第7回](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop) SSHはもう開くな。Hermes Agentはデスクトップアプリから直接話せる
- [第8回](https://zenn.dev/sora_biz/articles/hermes-vps-08-dashboard) 手探りで動かすな。Hermes Agentはブラウザ1枚で中身が見える

**第III部 生活リズム**
- [第9回](https://zenn.dev/sora_biz/articles/hermes-vps-09-cron) いつもの作業を毎回自分でやるな。Hermes Agentが決めた時刻や間隔で自動でこなす
- [第10回](https://zenn.dev/sora_biz/articles/hermes-vps-10-skills) 毎回教えるな。Hermes Agentは使えば使うほど自分で賢くなる
- [第11回](https://zenn.dev/sora_biz/articles/hermes-vps-11-web-search) 気になる情報を自分で探し回るな。Hermes Agentがネットで調べて要点だけまとめてくれる

**第IV部 記憶を分けて育てる**
- [第12回](https://zenn.dev/sora_biz/articles/hermes-vps-12-memory) 好みを毎回言うな。Hermes AgentはMemoryで覚えている
- [第13回](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) メモを自分で探すな。Hermes AgentはObsidianを記憶として読む
- [第14回](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) 毎回最初から話すな。Hermes Agentは前回の続きからそのまま動く
- [第15回](https://zenn.dev/sora_biz/articles/hermes-vps-15-import-ai-sessions) 記憶を捨てるな。Hermes AgentはClaude Codeの続きを引き継ぐ
- **第16回**(本記事) 同じことを二度調べさせるな。Hermes Agentは作業履歴からセカンドブレインを作る

全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

## 導入:Karpathyが提唱したLLM Wikiパターン

本回のテーマは、Hermes専用の**セカンドブレイン**(第二の脳)だ。Hermes自身が、貯まった作業履歴を読んで索引と相互参照を作り、二度同じことを調べさせない仕組みのことを指す。実はこれ、Hermesが独自に考えた機能ではない。元ネタがある。

:::message
**公式ドキュメント**
- [English: llm-wiki(Hermes Agent)](https://hermes-agent.nousresearch.com/docs/user-guide/skills/bundled/research/research-llm-wiki)
- [SKILL.md(GitHub・v2.1.0)](https://github.com/NousResearch/hermes-agent/blob/main/skills/research/llm-wiki/SKILL.md)
:::

2026年4月3日、Andrej Karpathy氏(OpenAI共同創業者・Tesla AI元責任者)が「LLM Knowledge Bases」というポストを投稿した。2146万インプレッションを集め、AIエージェント向けの個人用ナレッジベースのテンプレートとして急速に広まった。

@[tweet](https://x.com/karpathy/status/2039805659525644595)

Karpathy氏が説明していたのは、次のような流れだ。Web記事や論文、リポジトリを`raw/`に投げ込むと、LLMがそれを少しずつ`.md`のwikiにまとめていく。要約を書き、バックリンクを張り、概念ページを作って相互リンクさせる。フロントエンドはObsidianで、rawデータもコンパイル済みのwikiも同じ場所で見える。LLMがwikiの全データを書き、人は直接触らない。wikiが育ってくると、複雑な質問をLLMエージェントに投げるだけで答えが返ってくる。凝ったRAG(検索して回答を生成する仕組み)に手を出すまでもなく、LLMがindexファイルと要約を自動でメンテしながら関連データを読んでくれる、という話だった。回答はテキストだけでなく`.md`ファイルやスライド、画像としてレンダリングされ、その出力自体がまたwikiに書き戻される。さらにLLMで「health check」を回して、不整合や欠損を見つけたり、次に深掘りすべき問いを提案させたりもできる。

人が手で書く伝統的なwikiでもなく、毎回ゼロから探すRAGでもない、第三の道だ。

このポストから4日後の2026年4月7日、Nous ResearchのTeknium氏(Hermes Agentのコア開発者)が動いた。

@[tweet](https://x.com/Teknium/status/2041370915012071577)

「Hermes Agentは今、ObsidianのナレッジベースやリサーチVault作成にKarpathyのLLM-Wikiをパッケージとして同梱している。`hermes update`を実行して`/llm-wiki <research x>`と打つだけ」という告知だった。添付画像には、TekniumがHermes Agentで作ったNous Researchテーマの相互参照グラフが写っている。ノードがwikiページ、エッジが`[[wikilinks]]`(ページ同士のリンク)で、密に絡み合ったクラスタが浮かび上がっていた。

つまり読者の手元のHermesには、第6回で`hermes update`を済ませた時点で、**すでにこのパターンの実装が入っている**。本回でやるのは`.env`に2行追記して`/llm-wiki`を呼ぶことだけだ。道具を作るのではなく、使う。

もう1つ押さえておきたいことがある。連載でここまで扱ってきたHermesの記憶は、Memory(第12回)・Vault knowledge(第13回)・state.db(第14回)・raw/transcripts(第15回)の4層で、いずれも公式ドキュメントの「Which File Does What」というメモリ地図に載っている構成要素だ。だが本回のllm-wikiが作るentities/concepts/queriesは、この公式の地図には出てこない。**公式の地図の外に、自分で足す第5の層**という位置づけになる。地図にないからといって非公式のハックというわけではなく、Hermes本体にbundled(同梱)されたskillとして正式に提供されている。ただ、標準の記憶階層とは別枠で、自分の判断で足す層だという点は覚えておくといい。

## この回の到達点

「先週Codexで詰まった件、今後同じ問題が出たら最初にどこを見る?」とHermesに頼むと、過去事実(raw/transcripts/の生履歴)だけでなく、**一般化された教訓**(llm-wikiが整理したconcept page)を引いて答える状態を作る。本回でVault配下に`entities/`・`concepts/`・`queries/`の3フォルダが生まれる。

第15回完了時点との差分を表にする。

| 項目 | 第15回完了時点 | 本回(第16回)完了時点 |
|---|---|---|
| Hermesがraw/transcripts/を引く方法 | 毎回mdファイルを直接読む(検索と読み込みの繰り返し・数千件相手だと重い) | llm-wikiが整理した`entities/`(人物・ツール)・`concepts/`(概念)・`queries/`(よくある問い)から引く。入口が「索引」になる |
| 「先週のエラー、今後どう対処?」への応答 | 該当sessionのmdから事実だけを引いて答える(過去事実の再生) | 該当事実に加えて、llm-wikiが他のsessionと相互参照して作ったconceptを引いて答える(教訓の一般化) |
| 追加した道具 | 母艦の変換スクリプト1本(自前) | Hermes純正の`llm-wiki`skill(bundled・research・自前コードはゼロ)と`.env`への2行追記 |
| 次の回への橋渡し | 第16回でllm-wikiがraw/transcripts/をセカンドブレイン化する前提を作った | 本回で生まれた`entities/concepts/queries/`を、第17回以降が「整理されたwiki」前提で扱う |

この回で出てくる用語を先に押さえておく。

| 用語 | 意味 |
|---|---|
| llm-wiki(Hermes純正skill) | bundled・researchカテゴリ。Andrej Karpathy氏の**LLM Wikiパターン**をHermesがskill化したもの。RAGの「毎回ゼロから探す」と対比して「一度コンパイルして最新に保つ」。本質は「二度同じことを調べさせない」 |
| raw層(本回で再利用) | Vault配下の`raw/`。第15回で作った不変の原本置き場。llm-wikiはここを読むだけで書き換えない |
| entities(本回で新設) | Vault配下の`entities/`。人物・組織・製品・モデル・ツールのページ置き場。1ページ1エンティティ |
| concepts(本回で新設) | Vault配下の`concepts/`。概念・技術トピックのページ置き場 |
| queries(本回で新設) | Vault配下の`queries/`。よくある問いと、wikiが答えた結果の保存 |
| wikilink(`[[page-name]]`) | wiki内ページ同士のリンク。Hermesが「関連ページ」を辿れる。Obsidianで開けばクリックで遷移する |
| SCHEMA.md(本回で新設) | Vault直下に置く規約ファイル。domain(このwikiが何を扱うか)・ファイル名規則・frontmatter形式・tag taxonomy(タグの分類体系)・ページ作成の閾値を1ファイルに集約する。Hermesはwikiに触るたびにこれを最初に読む |
| index.md / log.md(本回で新設) | index.mdは全ページの目録。log.mdはingestやlintやcreateの追記専用記録。どちらも「次のセッションのHermesが何をすればいいか」を1秒で掴むための入口 |
| WIKI_PATH(環境変数) | llm-wikiが読み書きするwiki本体の絶対パス。`.env`で設定する。未設定時の既定は`~/wiki` |
| OBSIDIAN_VAULT_PATH(環境変数) | 第13回で使ったobsidian skillが読むVaultパス。llm-wikiと併用するときは同じディレクトリに揃えるのが公式推奨だ |

## raw層に手紙を貯めただけでは、読まれない

本回開始時点で、筆者の環境ではVault配下の`raw/transcripts/`に、claude-code 3,424件・codex 2,963件・grok 266件・antigravity 21件、合計6,674件のmdが並んでいる。手元の件数は第15回でどれだけ取り込んだか次第で決まるので、数十件でも本回の手順はそのまま動く。ここで「先週のエラー、今後同じ問題が出たらどう対処する?」とHermesに聞くとどうなるか。Hermesはそのうち関連しそうなmdを検索し、見つけたmdを1件ずつ読み、答えを組み立てる。**件数が多いほど、毎回ゼロから全件を相手にする**わけで、これがRAGの素朴な姿だ。

確かに動く。だが2つの限界がある。1つは、同じ問いを2回したら、Hermesは2回ともゼロから探すこと。「以前答えた内容」が蓄積されない。もう1つは、全件を横断して「複数session間の共通教訓」を抽出する作業を毎回やり直すこと。トークンコストと時間が件数に応じて膨らんでいく。件数が数十件でも数千件でも、この2つの限界そのものは変わらない。

家の書庫に本を積み上げただけでは図書館にならない。本を分類し、目録を作り、互いの参照関係を書き出して、ようやく使える知識になる。raw/transcripts/への蓄積は**貯める**側の仕事で、次に必要なのは**整理する**側の仕事だ。

解は単純だ。raw/に貯まった原本を読んで、entities・concepts・queriesに整理する仕事をHermesにskillとして委ねる。それがllm-wiki(Hermes純正・bundled・research)で、第6回で`hermes update`を済ませた読者の環境には既にインストールされている。本回でやるのは`.env`に環境変数を2行足して、Hermesにwiki初期化を頼むだけだ。

## 司書が、手紙を読んで索引を作る

第13回で書庫(Obsidian Vault)を建て、第14回で司書(Session Search)を雇い、第15回で他のAIで書いたノート(Claude Code/Codex作業履歴)を書庫の棚(raw/transcripts/)に並べた。だが司書がノートを「整理する」までは、棚に並んでいるだけだ。

本回はその司書に、**ノートを読んで索引と相互参照を作る仕事**を頼む。entities(登場人物・ツール一覧)・concepts(出てきた概念のページ)・queries(よくある問いの答え集)を別の棚に作り、互いを`[[wikilinks]]`で繋ぐ。一度索引を作れば、次に似た問いが来たとき、司書は数千通の手紙を読み直さず、concepts配下の1枚を開いて答えられる。

| 比喩 | Hermes機能 | 役割 | 本連載の該当回 |
|---|---|---|---|
| 📝 付箋 | Memory | 短い前提・毎回使う | 第12回 |
| 📚 書庫 | Obsidian Vault | 長期保存の知識ベース | 第13回 |
| 🧑‍🏫 司書 | Session Search | 自分との会話を思い出す | 第14回 |
| 🗒️ ノート | 他AIの作業履歴 | 書庫の棚に預ける | 第15回 |
| 🧭 **索引(新)** | llm-wiki | **ノートを読んで索引と相互参照を作る** | **本回(第16回)** |

第13回(書庫を建てる)、第14回(司書を雇う)、第15回(他AIのノートを書庫に並べる)ときて、本回は**司書がノートを読んでセカンドブレイン、つまり索引付きの百科事典を作る**段階になる。比喩の地図はそのままに、書庫が使える図書館へと育つ回だ。

## raw層からセカンドブレインが育つ流れを、1枚の図で見る

本回の作業は第15回と違い、VPS側で完結する。母艦の役目はTelegramでのやり取りと、Obsidianでの目視確認だけだ。raw/transcripts/(第15回の出力)を入力に、llm-wikiがentities/concepts/queries/(本回の出力)を生み出す。

![第16回の統合フロー図。VPS上の.envにWIKI_PATHとOBSIDIAN_VAULT_PATHを本回追記し、~/hermes-vault内でLayer 1(raw/transcripts・不変の原本)からllm-wiki skillを経てLayer 2(SCHEMA.md/index.md/log.md/entities/concepts/comparisons/queries)が育ち、Telegram経由のqueryとlintでHermes Agentが過去事実と一般化された教訓で応答する。母艦WindowsのObsidianが同じVaultを別経路で読んでGraph Viewで可視化する構図](/images/hermes-vps/hermes-vps-16-architecture.png)

第15回の構成図は「母艦→Vault→VPSのHermesがraw/を読む」までだった。本回はそのVPS側を拡張する。Vault配下のraw/から、llm-wikiがLayer 2(entities/concepts/queries/)を生み出す。母艦のObsidianは同じVaultを別経路で読むので、Hermesが書いたwikiページはそのまま母艦のGraph Viewに表示される。分業の構図が1枚で見える。

## 事前準備:WIKI_PATHの設定とllm-wiki skillの確認

llm-wikiを動かす前に、3つの仕込みを済ませる。`.env`に2行追記して`WIKI_PATH`と`OBSIDIAN_VAULT_PATH`を同じVaultに向ける。`hermes update`でbundled skillを最新に同期する。raw/transcripts/が第15回成果物として揃っているか件数を確認する。この3点が揃ったら次章へ進む。

### `.env`にWIKI_PATHとOBSIDIAN_VAULT_PATHを追記

VPS sshで`hermes config env-path`を実行して`.env`の正確な場所を確認する(通常は`~/.hermes/.env`)。エディタで開いて2行追記する。両方とも`~/hermes-vault`(第13回symlink先のコンテナ内Vault、第15回でraw/transcripts/を置いた場所)に向け、llm-wikiと既存obsidian skillが同じVaultを共有するようにする。

```bash
# VPS sshにログインしたら最初にvenvをactivate(以降hermesコマンドが使える)
source ~/hermes-agent/venv/bin/activate

hermes config env-path           # .envの場所を確認
nano ~/.hermes/.env              # またはお好きなエディタで開く

# 末尾に2行追記(両方ともhermes-vaultを向ける。公式推奨「同じディレクトリ」)
WIKI_PATH=/home/admin/hermes-vault
OBSIDIAN_VAULT_PATH=/home/admin/hermes-vault
```

nanoでの追記操作は次の順だ。矢印キーでファイルの一番下の行まで移動し、改行して上の2行を打つ(またはターミナルに貼り付ける)。打ち終わったら保存して閉じる。

```bash
# nanoの保存・終了操作(画面下部にも同じ記号で案内が出ている)
Ctrl+O    # 書き込み(Write Out)。ファイル名を確認する行が出たらEnter
Enter     # 上書き保存を確定
Ctrl+X    # nanoを終了して元のシェルに戻る
```

`Ctrl+O`の`O`はアルファベットのオーで、数字のゼロではない。編集をやめて何も保存せず閉じたいときは`Ctrl+X`のあと変更を保存するか聞かれたら`n`と打つ。

:::message
**hermesコマンドのパス**:第6回でsystemd常駐化する際、HermesはPythonの仮想環境(venv、`~/hermes-agent/venv/`)にインストールされている。SSHでログイン直後の素のシェルからは`hermes`コマンドがPATHに見えず`command not found`になることがある。最初に`source ~/hermes-agent/venv/bin/activate`を1回実行しておけば、以降そのシェル内で`hermes update`や`hermes skills list`を短縮形で叩ける。activateしない場合はフルパス`~/hermes-agent/venv/bin/hermes ...`で実行する。
:::

`~/wiki`(llm-wikiの既定値)は新規作成しない。Vaultが既にあるので、そこに統合する。連載の積み上げをそのまま再利用する判断だ。

追記後は行頭固定のgrepで確認する。

```bash
# 行頭固定+末尾の=まで含める(他の行に紛れず2行ちょうどになる)
grep -E "^(WIKI_PATH|OBSIDIAN_VAULT_PATH)=" ~/.hermes/.env
```

![VPS sshで.envに追記した2行を行頭固定grepで確認した画面。WIKI_PATH=/home/admin/hermes-vaultとOBSIDIAN_VAULT_PATH=/home/admin/hermes-vaultの2行ちょうどが表示され、venv activate済みのプロンプトになっている](/images/hermes-vps/hermes-vps-16-env-wiki-path.jpg)

2行ずつ出たら追記が二重に入っている。nanoで下の余分な2行を消してから確認し直す。`grep`を緩い書き方にすると第13回で設定した別の環境変数の行も一緒に引っかかるので、上の行頭固定形で書くのがコツだ。

### hermes updateでbundled skillを最新化

llm-wiki skillはbundled(Hermes本体に同梱)なので、本来は別途インストール不要だ。だが第6回でHermesを最初に入れた時点から日数が経っているなら、`hermes update`でコード本体とbundled skillを同期する。

```bash
hermes update                        # コード本体+bundled skill同期
hermes skills list | grep llm-wiki   # llm-wikiが登録されている確認
```

![VPS sshでhermes updateを実行した直後の画面。3コミット取り込みからhermes-agent==0.20.0への更新、Update complete、gateway/dashboardの再起動までが1画面に収まっている](/images/hermes-vps/hermes-vps-16-hermes-update-output.jpg)

![VPS sshでhermes skills list | grep llm-wikiを実行した画面。llm-wiki・researchカテゴリ・enabledの状態が並ぶ行が見える](/images/hermes-vps/hermes-vps-16-skills-list-llm-wiki.jpg)

:::message
`hermes skills list`の列はName/Category/Source/Trust/Statusで、バージョン列は持たない。llm-wikiのバージョン(v2.1.0)はSKILL.mdのfrontmatterで別途確認できる事実で、上のコマンドの画面には写らない。
:::

:::message alert
**もし`hermes skills list | grep llm-wiki`が空返りする場合**

過去にllm-wikiのディレクトリを手動で削除した履歴があると、Hermesはそれを「利用者が意図的に消した」と判定して`hermes update`でも復活させない仕様になっている(バグではなく設計通りの挙動)。この場合、下記の1行で復旧する。

```bash
hermes skills reset llm-wiki --restore --yes
hermes skills list | grep llm-wiki   # 再確認。llm-wiki | research | builtin | enabled が返れば復旧完了
```

`hermes skills opt-in --sync`は同じ判定に落ちて空振りする。`hermes skills install ...`もbundled skillには効かない(hub経由の別カテゴリ扱いになる仕様)。復旧は`reset --restore --yes`の1行で完結する。
:::

### 取り込む素材が「最新か」を確認する

llm-wikiが取り込むraw層が空だと初回ingestが空振りになる。だが空でなくても「古い」ことがある。第15回の手順は母艦で変換スクリプトを走らせて初めてファイルが増える作りなので、しばらく走らせていないと、件数はあるのに中身が数週間前で止まっていることがある。**件数と一緒に、必ず最終日を見る**。

```bash
# 全ソースの件数+合計+最終日を1画面で
for d in $(ls ~/hermes-vault/raw/transcripts); do printf "%-13s: %s\n" "$d" "$(ls ~/hermes-vault/raw/transcripts/$d/*.md | wc -l)"; done
echo "合計: $(find ~/hermes-vault/raw/transcripts -name '*.md' | wc -l)"
echo "最新: $(ls ~/hermes-vault/raw/transcripts/claude-code/ | sort | tail -1)"
```

![VPS sshでraw/transcripts/の件数と最新ファイルを確認した画面。antigravity 21・claude-code 3424・codex 2963・grok 266・合計6674・最新2026-08-11の6行が並ぶ](/images/hermes-vps/hermes-vps-16-raw-transcripts-count.jpg)

「最新」の行に出るファイル名の先頭が今日から数日前の日付なら素材は最新だ。1週間以上前で止まっていたら、母艦で変換スクリプトを実行し、母艦で`git add -A`・`commit`・`push`したあと、VPSで`git pull`する。

:::message alert
筆者の環境で確認したら7/19で止まっていたことがあった。母艦の変換が23日間動いていなかったためだ。母艦で変換スクリプトを実行したところ2,211件が一気に増え、最終日が当日まで進んだ。この確認を飛ばすと、数週間前までの知識しか持たないwikiが出来上がってしまう。なお変換時、APIキーやBearerトークンなどの秘密情報は自動で伏せ字に置き換わる(筆者の実測で288件)。止まっていた日数や増えた件数は環境ごとに違うが、「件数だけでなく最終日を見る」という確認そのものは、どの環境でも同じように効く。
:::

:::message
このVaultは「中継リポからrsyncでコピーする」構成をやめ、Hermesが読む場所とgitリポを同一にしてある。第15回で使ったrsyncの工程は、今の構成では不要になった。
:::

## Hermesにwikiを初期化させて、作業履歴を取り込ませる

本回の作業は3つのstepだけだ。step1でTelegramから「wikiを初期化して」と頼み、SCHEMA.md/index.md/log.mdを生成させる。step2で「raw/transcripts/の直近2週間をingestして」と頼み、entities/concepts/queries/を生み出させる。step3で母艦のObsidianで生成されたwikiページを目視確認する。コードを書く作業はゼロで、全部Telegramでの自然言語のやり取りで進む。

### 着手前の事前確認

`.env`に書いた`WIKI_PATH`は、**Hermesが端末コマンドを動かすDockerコンテナの中には自動では届かない**(第4回でDocker backendにしているため)。届いていないと、llm-wikiは既定値の`~/wiki`にVaultとは無関係な空wikiを作ってしまう。この初期化は非冪等(2回目に頼むと「既に存在します」という別の応答になる)操作なので、頼む前に読み取りだけの確認を1回入れておくと安全だ。

SSHのシェルで`echo $WIKI_PATH`を打っても意味がない。`.env`はHermesが読むファイルで、ログインしたシェルには展開されないので必ず空になる。聞く相手はHermes本人だ。Telegramで、本番と同じ経路で次のように聞く。

```text
llm-wikiスキルの手順に従うと、これからwikiを作る場所はどのパスになる?
実際のパスだけ答えて。まだ何も作らないで。
```

| Hermesの答え | 判断 |
|---|---|
| `/home/admin/hermes-vault`(Vault) | そのまま次へ進む |
| `~/wiki`・`/root/wiki`など、Vault以外 | 止める。依頼文に絶対パスを明示して回避する |

![Telegramで「これからwikiを作る場所はどのパスになる」と聞いた画面。Hermesがllm-wiki skillを読み込み、端末で環境変数を確認し、実際のパスだけを答えるまでの一連が見える](/images/hermes-vps/hermes-vps-16-telegram-wiki-path-preflight.jpg)

Hermesが端末コマンドを動かすコンテナの中では`WIKI_PATH`が空になる。Hermesがファイル操作ツールでVaultを直接読み書きする場合は問題ないが、端末経由で`$WIKI_PATH`を解決しようとすると既定の`~/wiki`に落ちる。どちらの経路を通るかはHermesの判断次第なので、上の質問で先に確かめておく。依頼文には最初から絶対パスを書いておけば、通常はそのまま進んで問題ない。

### wikiを初期化する

Telegramで以下のように頼む。domain(このwikiが何を扱うか)を1文で指定するのがポイントだ。広すぎても狭すぎてもlintで困るので、自分が繰り返し調べ直しているものを思い浮かべて書くとちょうどいい。

```text
llm-wikiで wikiを初期化して。
場所はさっき教えてくれたパス(絶対パスで)。~/wikiは作らないで。
domain=「(このwikiで何を扱うか・1文で)」
既存の raw/ の中身は後で取り込む。
```

`~`はHermesの実行環境では別のホームディレクトリに展開されてしまうため、そのままだとVaultではない場所を指す。事前確認でHermesが答えた絶対パスをそのまま書き、`~/wiki`を作らないと明示すれば、1回で狙った場所に作られる。

Hermesはllm-wiki skillの初期化手順に従い、Vault直下に`SCHEMA.md`(domain・frontmatter形式・tag taxonomy)、`index.md`(空の目録)、`log.md`(初回createエントリ)を作る。

![Telegramでwiki初期化を依頼し、Hermesが既存の状態を確認してからSCHEMA.md/index.md/log.mdを書き込み、完了を報告するまでの一連が1画面に収まっている。何を維持し、何をしていないかまで報告されている](/images/hermes-vps/hermes-vps-16-telegram-init-request.jpg)

### Hermesが作ったものを母艦のObsidianへ運ぶ

ここまでの作業は、すべてVPSの中で起きている。母艦のObsidianが開いているのは母艦側のフォルダなので、このままアプリを開いても`SCHEMA.md`は現れない。第13回で用意したgitの往復で運ぶ。VPS側で送って、母艦側で受け取る、この2手だけだ。

```bash
# --- VPSで(送る) ---
cd ~/hermes-vault
git add -A
git commit -m "wiki: 初期化(SCHEMA/index/log)"
git push origin main
```

```powershell
# --- 母艦のPowerShellで(受け取る) ---
cd ~\Documents\Hermes-Vault
git pull origin main
```

:::message alert
**フォルダが4つ足りなく見えるのは正常**:`entities/`・`concepts/`・`comparisons/`・`queries/`は初期化直後まだ空で、gitは空のフォルダを運ばない仕様がある。この4つは次のingestで中身ができた瞬間に母艦へ現れる。いま母艦で見えるのは`SCHEMA.md`・`index.md`・`log.md`の3つで正しい。
:::

![母艦のObsidianでVault直下にSCHEMA.md・index.md・log.mdが並び、右ペインにSCHEMA.mdの中身が見える画面。対象外(ページ化しない)節に一時的な雑談や機密情報が除外対象として書かれている](/images/hermes-vps/hermes-vps-16-vault-schema-files.jpg)

![Obsidianでindex.mdを開いた画面。Total pages: 0でEntities/Concepts/Comparisons/Queriesの各セクションが空欄になっている。Legacy節に既存ノートがnot yet migratedとして分類されている](/images/hermes-vps/hermes-vps-16-index-empty.jpg)

### raw/transcripts/の直近2週間をingestする

Telegramで「raw/transcripts/の直近2週間をingestして」と頼む。初回ingestを直近2週間に限定するのは、初回コストと時間の見積もりを取りやすくし、結果を目視できる規模に抑えるためだ。残りは§10で扱う「定期取り込み」運用で順次取り込んでいく。

```text
llm-wikiで raw/ の直近2週間分を取り込んで(ingest)。
出力は entities/concepts/queries/ に振り分けて。
終わったら index.md と log.md も更新して、何ページ作ったか教えて。
```

:::message
**なぜ全部でなく「直近2週間」なのか**:初回から数千件を一度に投げると時間もお金もかかり、出来上がりを確かめる前に走り切ってしまう。まず2週間分で「どんなページができるか」を見て、良ければ範囲を広げる。期間は自分の貯まり具合に合わせて変えてよい。
:::

:::message
初回のingestは、他の作業と混ぜず新しいTelegramセッションで頼むと安定する。
:::

Hermesはllm-wiki skillの手順に従い、各mdを読んで既存のentities/conceptsを確認し(初回なので空)、新ページを書き、互いに`[[wikilinks]]`で繋ぎ、index.mdとlog.mdに追記して報告する。

![Telegramでのingest完了報告。14ページ(entities5+concepts9)の全ページ名と、wikilink壊れなし・孤児なしの自己検査結果、最下部にSelf-improvement reviewの1行が見える](/images/hermes-vps/hermes-vps-16-telegram-ingest-summary.jpg)

筆者の環境では直近2週間分で14ページ(entities5+concepts9)ができた。何ページできるかは持っている素材の量と密度次第で、数ページのこともあれば数十ページのこともある。ページ数の多い少ないより、`[[wikilinks]]`で繋がった状態になっているかを見るとよい。

![Obsidianでlog.mdを開いた画面。createエントリとingestエントリが時系列で並び、左サイドバーにentities・conceptsフォルダが出現している](/images/hermes-vps/hermes-vps-16-log-timeline.jpg)

生成されたページは、母艦のObsidianで実体を確認する。左サイドバーをリフレッシュすると`entities/`・`concepts/`・`queries/`(初回ingestではqueriesは空のこともある)が見え、各フォルダ配下にmdが並んでいる。代表1ページを開いて、ちゃんと「読める形」になっているか確かめる。

![Obsidianでconceptページを開いた画面。title/created/updated/type/tags/sources/confidenceのプロパティ、関連リンク、原本へのsourcesリンク、試して駄目だった方式とその理由を書いた表が見える](/images/hermes-vps/hermes-vps-16-concept-page-content.jpg)

sourcesには原本パスへのリンクが入っている。どの会話から導いた記述かを辿れるということだ。「失敗した方式とその理由」まで残っているページもあり、原本を読み返すだけでは得られない形で情報が整理されているのがわかる。

最後にGraph Viewで、ページ同士のつながりを俯瞰する。

![ObsidianのGraph View。設定でraw層を除外しconcepts/entitiesだけを表示するフィルタをかけた状態で、本回生成したノードが名前付きで表示され、wikilinkのエッジで繋がっている](/images/hermes-vps/hermes-vps-16-obsidian-graph-view.jpg)

:::message
素のGraph Viewはraw/transcripts/の数千件が支配し、本回生成した14ノードは砂粒に埋もれる。設定(歯車)からFiltersの検索欄に`path:concepts OR path:entities`と入れてrawを除外し、Text fade thresholdを下げてノード名を表示させると、Tekniumのポストで見たのと同じ形の相互参照グラフが浮かび上がる。
:::

## 整理済みの知識でHermesが答える(本回山場)

Telegramで「先週詰まった件、今後同じパターンが出たら最初にどこを見る?」と頼むと、Hermesがraw原本ではなく**llm-wikiが整理したconcept page**を引いて答える。「過去事実の再生」から「一般化された教訓」への進化が、ここで体感できる。

聞き方のコツは、「その時どうだったか」ではなく「次に同じことが起きたらどうするか」を聞くことだ。前者は原本を読み返せば済むが、後者は複数回の出来事から共通点を抜き出した答えになる。wikiに整理された知識でないと返ってこない。自分が先週や先月に詰まったことを1つ思い出して、その言葉で聞けばいい。

```text
先週(使っていたAI)で詰まった(困っていた内容)の件、
今後また同じことが起きたら最初にどこを見るべきか教えて。
llm-wikiで整理した内容で。
```

実際に「Vaultの同期が1か月止まっていて気づかなかった件、今後また同じことが起きたら最初にどこを見るべきか」と聞いてみた。

![Telegramでの質問と、Hermesが該当するwikiページを複数読み込む過程、回答冒頭が見える画面。回答は「最初に見るのは同期処理そのものではなく、処理の外にある痕跡と中身の鮮度」という一般化された結論から始まっている](/images/hermes-vps/hermes-vps-16-telegram-query-concept.jpg)

この応答が強いのは、Hermesが答える前に**何ページかの読み込みが画面に表示される**ことだ(筆者の環境では4ページだった。読む枚数は自分のwikiの育ち具合で変わる)。wikiから答えたことが推測ではなく可視化されている。もう1つ注目したいのが、「いまのVaultにはまだ用意されていない仕組みがあるが、それは設計案の段階で、実際には無い」と正直に断ったうえで、じゃあ今は何を見ればいいかを答えている点だ。**持っていない機能を持っているかのように答えない**のは、AIの回答をどこまで信頼していいかを判断する材料になる。

応答の末尾には、持ち帰れる形のチェックリストと覚え方が返ってきた。

```text
1枚チェックリスト(再発時コピペ)
□ 心拍/痕跡があるか(直近の動作ログ)
□ rawの鮮度(最終更新が数日以内か)
□ どの橋が古いか(同期経路のどこで止まっているか)

覚え方(wikiの芯):
「壊れたら『コマンド』を最初に見ない。
 ①心拍/痕跡 → ②rawの鮮度 → ③どの橋が古いか」
```

![Telegramでの応答末尾。1枚チェックリスト5項目と、引用ブロックで強調された覚え方の3ステップが見える](/images/hermes-vps/hermes-vps-16-telegram-query-checklist.jpg)

前回の根本原因は「打ち忘れ」ではなく、「打たないと壊れる橋が構造にあること」だったという一文もあった。Hermesが自分の言葉で、今日の教訓に到達している。

第15回で同じ題材を「思い出して」と聞いたときは、Hermesはraw原本を引いて事実だけを答えた。過去事実の再生だ。本回はconceptページを引いて答える。同じ事実が一段抽象化された教訓に変換されている。両者の応答を読み比べると、llm-wikiが何をやったのかが腑に落ちる。

| 状態 | 「先週のエラー、今後どう対処?」への反応 |
|---|---|
| 第15回完了時点 | raw/transcripts/原本から事実だけを引いて答える(過去事実の再生) |
| 本回完了時点 | llm-wikiが書いたconceptページ(複数sessionをcross-referenceした一般化教訓)を引いて答える |

## lintで穴を見つける(第19回Curatorへの橋渡し)

本回はwikiを作るだけでは終わらない。作ったwikiを**lint**(健全性チェック)して、穴、つまりorphan page(どこからも参照されないページ)やbroken wikilink(リンク切れ)や索引の欠落を見つけるところまでで「使える図書館」になる。lintは人がレポートを読んで判断する手動の保守で、本回のスコープはここまでだ。自動でwikiを整理し続ける仕組みは第19回のCuratorで扱う。

Telegramで「今のwikiを健全性チェックして」と頼む。

```text
今のwikiを llm-wikiでlintして。
orphan page・broken wikilink・index欠落・frontmatter不備・
contested・confidence low・page肥大化(200行超)・tagずれを
重要度順で見せて。
```

![Telegramでのlint依頼と応答。致命0/orphan0/中2件/低0の構造が1画面に収まっている](/images/hermes-vps/hermes-vps-16-telegram-lint-report.jpg)

筆者の環境での実行結果は致命的な問題0件・orphan page 0件・要対応2件だった。1件は特定のページのsourcesが空だったこと、もう1件は特定のページが設計案段階で内容が確定していない(contested)ことだ。この2件はあえて直さずそのまま見せる。要対応の件数は自分のwikiの育ち具合で変わり、0件のこともあれば2件より多いこともある。件数の多寡より、「完璧なwiki」ではなく「lintが問題を見つけてくれる状態」を見せるのが、この章の狙いだからだ。

![Obsidianでlog.mdを開いた画面。ingestエントリの後ろにlintエントリが追記され、broken 0・orphan 0・index一致・frontmatter1・contested1・log entries3の内訳が読める](/images/hermes-vps/hermes-vps-16-log-lint-appended.jpg)

Telegramの報告は流れて消えるが、log.mdに残った記録はVaultに永続化されて、次回の自分が辿れる。

本回のlintと、第19回で扱うCuratorは別レイヤーで、重複しない。

| 項目 | 本回のlint | 第19回 Curator |
|---|---|---|
| 主役 | 人がlintレポートを読んで判断する | Hermesがバックグラウンドで自動実行する |
| 対象 | llm-wikiが書いたwikiページ(entities/concepts/queries) | Skills(使われなくなったskill自体) |
| 頻度 | 気が向いた時に手動 | 一定サイクルで自動 |
| 削除・統合 | レポートを出すだけ。実際の削除は人が判断する | 一定期間で自動的にstale扱い・archive扱いにする |

本回でlintを体験しておくと、第19回で「自動でやる」と聞いたときに何が便利で何が危険かが直感的にわかる。手動lintから自動Curatorへ、という自然な学習順序だ。

なお、llm-wikiが書くwikiページは1ページあたり数KB〜数十KB程度で、1000ページ書いても十数MB程度に収まる。Vault容量の心配は当面ない。気にするべきは更新頻度のほうで、raw/transcripts/が毎日大量に増えるなら、ingestを毎日手動でやるのは現実的でない。定期取り込みの運用パターンは§10で触れる。

## Hermesが、次回の自分のために手順を残した

取り込みが終わった直後、頼んでいないのにHermesが1行だけ報告を足していた。

```text
Self-improvement review: Memory updated · Skill 'hermes-vault-wiki' created.
```

wikiを作っただけでなく、**その作り方を次回の自分のためにスキルとして書き残していた**。本回のテーマ「二度同じことを調べさせない」が、説明ではなく出来事として出た瞬間だ。

実体を確認すると、`~/.hermes/skills/research/hermes-vault-wiki/`にSKILL.mdとreferencesが置かれていた。frontmatterの`author`は`Hermes Agent (curator)`。人間ではなく、Hermes自身が著者になっている。

![VPS sshでhermes skills list | grep hermes-vault-wikiを実行した画面。hermes-vault-wiki・research・Source列がlocalの行が見える。bundledではなくこの環境で作られたことを示している](/images/hermes-vps/hermes-vps-16-skills-list-self-created.jpg)

Source列が`local`になっているのがポイントだ。最初から同梱されているbundledではなく、この環境の作業の中で生まれたスキルだということがわかる。

中身で本文に引用する価値があるのは、パスの正本を宣言している箇所だ。「必ずコンテナから見える`/root/hermes-vault`を正として読む・書く。ホスト側のパスはdocker端末から見えない」という一文が書かれている。これは、今日の作業で自分が事前確認まで踏んで突き止めたことを、Hermesが同じ結論として自分の言葉で残していたことになる。

これは頼んでいないのに起きたことなので、必ず読者の環境で同じことが起きるとは限らない。今回の環境ではこうなった、という実例として捉えてほしい。「自分で技を作る」という発想は、第10回のSkillsや、この先のSkills育て直し・Curatorの回に繋がっていく。書庫が整い、司書が索引を作り、その司書自身が次の自分への手順書まで残す。ここまで来ると、Hermesは単なる記憶装置ではなく、育っていく相棒に近づいている。

## 早見表+引用元+第17回予告

### よくあるエラーと対処

| 症状 | 原因 | 対処 |
|---|---|---|
| Hermesが「`~/wiki`を作りました」と言う(`~/hermes-vault`でなく) | `.env`の`WIKI_PATH`が未設定、または反映されていない | `.env`の値を確認し、Hermes gatewayを再起動して`.env`を読み直させたうえで、再度Telegramで初期化を依頼する。誤ってできた`~/wiki`は手動で削除する |
| Hermesが「ingest対象のmdが見つからない」と言う | raw/transcripts/が空、またはWIKI_PATHが間違ったVaultを指している | 件数を確認し、0なら第15回の取り込み手順から再実行する。`WIKI_PATH`と`OBSIDIAN_VAULT_PATH`が両方同じVaultを指しているか`.env`を再確認する |
| 初回ingestがいつまで経っても終わらない | 対象範囲が広すぎる(raw/transcripts/全件をいきなり投げた) | 「直近2週間」に範囲を絞って再依頼する。Hermesは1回のingestで一定数のページを書くため、範囲を狭めて複数回に分けるのが基本だ |
| Obsidianの左サイドバーに`entities/`等が出ない | HermesはVaultに書いたが、Obsidianがリフレッシュしていない | Obsidianを再起動する。それでも出ない場合はターミナルでVault実体側に存在しているか確認する |
| `[[wikilinks]]`が赤く表示される(リンク切れ扱い) | llm-wikiが書いたページ名と`[[link]]`内の名前がずれている | lintでbroken wikilinkとして検出される。Hermesに「broken wikilinkを修正して」と頼むと自動で直る |
| 同じconceptで2つのページができている | ingest時にHermesが既存ページを確認せず重複作成した | lintでorphan pageとして両方検出される。Hermesに「重複conceptを統合して」と頼む |
| frontmatterに`contested: true`が大量に出る | 同じトピックで矛盾する記述が複数sessionにあった | 正常な動作。矛盾を炙り出すのがlintの仕事だ。気が向いたタイミングで該当ページを開き、現在の判断で書き直す |
| `hermes skills list | grep llm-wiki`が空返り(`hermes update`は完走している) | 過去にllm-wikiのディレクトリを手動削除した履歴があり、Hermesが「利用者が意図的に消した」と判定している | `hermes skills reset llm-wiki --restore --yes`で1行復旧する |
| SSHログイン直後に`hermes`コマンドが`command not found` | venvがactivateされていないSSHの素のシェル | `source ~/hermes-agent/venv/bin/activate`を1回実行する、またはフルパスで叩く |

### 操作早見表

```bash
# [VPS ssh] 事前準備(初回のみ)
source ~/hermes-agent/venv/bin/activate      # SSHログイン直後に1回だけvenv activate
hermes config env-path                       # .env場所の確認
echo "WIKI_PATH=/home/admin/hermes-vault" >> ~/.hermes/.env
echo "OBSIDIAN_VAULT_PATH=/home/admin/hermes-vault" >> ~/.hermes/.env
hermes update                                # bundled skill同期
systemctl --user restart hermes-gateway      # .env再読込
hermes skills list | grep llm-wiki           # skill登録確認(空返りなら次行で復旧)
hermes skills reset llm-wiki --restore --yes # llm-wikiが未seed時のみ実行(復旧)
ls ~/hermes-vault/raw/transcripts/{claude-code,codex}/*.md | wc -l   # raw件数

# [Telegram] wiki初期化(初回のみ)
# 「llm-wikiで wikiを初期化して。domain=(1文で)。
#  場所は絶対パスで指定」

# [Telegram] 初回ingest(直近2週間に限定)
# 「raw/transcripts/の直近2週間をingestして。
#  終わったらindex.md+log.mdも更新して何ページ作ったか教えて」

# [Telegram] query(運用)
# 「先週の◯◯の件、今後同じパターンが出たら
#  最初にどこを見るべきか教えて(llm-wikiの整理済み内容で)」

# [Telegram] 月1回のlint(運用)
# 「今のwikiをllm-wikiでlintして。
#  orphan page・broken wikilink・index欠落・contested・confidence low・
#  page肥大化(200行超)を重要度順で見せて」

# [VPS ssh] Vault容量の長期参照(年1回)
du -sh ~/hermes-vault/{entities,concepts,queries,raw}/
```

:::message
cron化(raw/transcripts/が増えるたびに自動ingestする仕組み)は本回のスコープ外だ。第9回のCronで組んだ「Hermesに毎朝決まったタスクを依頼する」仕組みと同じ要領で組めるが、初回ingestの検索がコンテキストを食うことや、確認なしに大量ページを作らせないためのプロンプト設計が必要になるので、第19回のCuratorと合わせて扱う。本回は手動ingestで体感し、自動化は後の回で習う、という分業にした。
:::

### 引用元と参考

| 項目 | 引用元 |
|---|---|
| llm-wiki skill本体(v2.1.0・Hermes純正・bundled) | [SKILL.md(GitHub)](https://github.com/NousResearch/hermes-agent/blob/main/skills/research/llm-wiki/SKILL.md) / [公式doc llm-wiki](https://hermes-agent.nousresearch.com/docs/user-guide/skills/bundled/research/research-llm-wiki) |
| LLM Wikiパターン(着想元) | [karpathy/llm-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)(Andrej Karpathy氏) |
| Karpathy氏の原典ポスト | [x.com/karpathy/status/2039805659525644595](https://x.com/karpathy/status/2039805659525644595) |
| Teknium氏の同梱告知ポスト | [x.com/Teknium/status/2041370915012071577](https://x.com/Teknium/status/2041370915012071577) |
| 第15回で構築したraw/transcripts/(本回入力) | [第15回](https://zenn.dev/sora_biz/articles/hermes-vps-15-import-ai-sessions) 記憶を捨てるな。Hermes AgentはClaude Codeの続きを引き継ぐ |
| 第13回で構築したVault git同期(本回WIKI_PATH先) | [第13回](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) メモを自分で探すな。Hermes AgentはObsidianを記憶として読む |
| llm-wiki-compiler(参考・関連ツール) | [atomicmemory/llm-wiki-compiler(GitHub)](https://github.com/atomicmemory/llm-wiki-compiler)。同じKarpathyパターンの別実装。本連載のagent-in-the-loop curationとは別アプローチ(batch compile) |
| 複数wiki並列運用の参考事例(本文では触れず参照のみ) | [Tonbi Tutorials「16 wikis」動画](https://www.youtube.com/watch?v=hbKvO5MWq08)。本連載は1 wikiから始める方針を取っている |
| 自前wikiの参考例として読める既製wiki | [agentwikis.com/wiki/hermes](https://agentwikis.com/wiki/hermes)(Tonbi氏運営) |

### コラム:自前wikiの参考例として既製wikiも読める

本回で組んだ自前wikiを育てていくとき、参考になるのが[agentwikis.com/wiki/hermes](https://agentwikis.com/wiki/hermes)だ。Hermes Agentについての公開wikiが100ページ超で並んでおり、無料プランで全文を読める。運営はTonbi氏(本人がXの固定ポストで宣言済み)で、本回の冒頭で見たTekniumのグラフ画像と同じ仕組みが「実運用例」として外から眺められる。

面白いのは、サイト全ページの目録である`llms.txt`が公開されていることだ。自分のHermesにこのURLを渡すと、agentwikisをMCPサーバー経由で一覧・読み込み・検索できる。外部の整った知識ベースを自分のwikiから引きにいく動線が成立する、ということだ。自前で1から書くことと、他人の完成形を読みにいくことは両立する。

本回の目的はあくまで「自分のwikiを1つ持つ」ことだ。agentwikisは、自分のwikiが大きくなってきたときに他のwikiも読めるようにする、次の探索方向の例として置いておく。2026年6月時点でagentwikis.comはベータ段階なので、URL変更やサービス終了の可能性はある。

### まとめと第17回予告

第16回完了で、Hermesは「貯まった作業履歴」を「整理されたセカンドブレイン」に変える仕組みを手に入れた。raw/transcripts/に置かれたmdが、llm-wikiによってentities/concepts/queriesの相互参照ページに昇華される。同じ問いに二度と最初から答えなくて済む状態だ。Memory(私のこと)・Vault knowledge(世界のこと)・state.db(自分の会話)・raw/transcripts(他AIの履歴)に、本回でentities/concepts/queries(整理済み教訓)が加わり、5層が役割分担で揃った。

次の第17回(予定)は、ここで整理した知識を**どんな声・口調で読者に返すか**、Hermesの「文体(SOUL)」を扱う。同じ事実を返すにしても、固い参考書のように返すか、親しい先輩のように返すかで体験は別物になる。書庫が整い、司書が索引を作った今、次は司書の話し方を仕立てる段だ。連載の回数は変わる可能性があるので、着手時に最新の計画書を確認してほしい。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第15回](https://zenn.dev/sora_biz/articles/hermes-vps-15-import-ai-sessions) 記憶を捨てるな。Hermes AgentはClaude Codeの続きを引き継ぐ | 第17回 整理した知識をどんな声で返すか。Hermesの文体を仕立てる(近日公開) |

📑 [シリーズ全12回のもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

:::message
この連載はSubstack「そらのAIエージェント通信」で先行公開している。無料[登録](https://sorabiz.substack.com/subscribe)すると最新回がメールに届く。[Zennでフォロー](https://zenn.dev/sora_biz)すると新着通知が届き、全体像は[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::

:::message
**この記事をAIに読ませる**

この記事はGitHubの公開リポジトリで管理していて、本文のMarkdownをそのまま取得できる。Claude CodeやCodexなどのAIエージェントに手順を任せたいときは、次のURLを渡すだけでいい。

https://raw.githubusercontent.com/Sora-bluesky/zenn-articles/main/articles/hermes-vps-16-secondbrain.md

頼み方の例:「この記事を読んで、私の環境で手順を順番に実行して」に上のURLを添える。
:::
