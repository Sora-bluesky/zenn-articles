---
title: "【第15回】記憶を捨てるな。Hermes AgentはClaude Codeの続きを引き継ぐ"
emoji: "📨"
type: "tech"
topics: ["hermes", "obsidian", "claudecode", "codex", "ai"]
published: true
---

:::message
この連載は月1,800円ほどのVPSで、自分専用のAIエージェント(Hermes Agent)を24時間動かす実録だ。これはその第15回。全体の流れは[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
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
- **第15回**(本記事) 記憶を捨てるな。Hermes AgentはClaude Codeの続きを引き継ぐ

全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

## この回の到達点

第14回でstate.db(Hermesが交わした会話を貯めるSQLiteデータベース)の中身を「思い出して」と頼める司書を雇った。ただ、その司書が見ているのは**Hermes本人と交わした会話だけ**(=Telegram/Discord/Dashboardで直接やりとりした内容)だ。

母艦のClaude CodeやCodexと深夜まで詰めて出した結論──「P0/P1/P2(最優先・次点・後回しの優先度記法)のどれから手をつけるか」「あのバグの原因はどこだったか」──は、別のローカルディレクトリにJSONL(1行1件のJSON形式・会話履歴の標準フォーマット)で沈んでいる。Claude Codeなら`~/.claude/projects/<encoded>/<uuid>.jsonl`、Codexなら`~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`の下だ。HermesからもVPSからも見えない。次の日にTelegramで「昨日Codexと話してた件の続き」と振っても、Hermesは何のことか分からない。朝の自分が昨日の自分に置いてけぼりにされる感覚に近い。

本回は、その「母艦で交わした他AIとの会話」をObsidian Vault(Obsidianの保管庫=ノートをまとめて置くフォルダ)に取り込んで、HermesからTelegramで自然言語で引けるようにする。

手順は3つだけだ。母艦のPowerShellスクリプトでJSONLをMarkdownに変換する。出力先はVault配下の`raw/transcripts/<agent>/YYYY-MM-DD_<sid8>.md`だ。次にVaultをgitで母艦からVPSへpushする。最後にVPS側でrsync(ファイル差分だけを効率よく同期するコマンド)を1コマンド打つ。これだけで、Hermesが見ているVaultに同じファイルが揃う。Telegramで「昨日winsmuxで何か困ってなかった?」と聞けば、HermesがVault内のtranscriptを自分で探して構造化して返してくる。

朝Telegramで「昨日の続き、結論どっちにした?」と振ると、Hermesが前夜の議論を踏まえて返してくる。深夜に一人でClaude CodeとCodexを行き来していた作業が、翌朝Telegramで3人会議として続けられる。3エージェント目として母艦の議論に加わる、ということだ。

第13回完了時と本回完了後の差分を表にする。

| 項目 | 第13回完了時 | 第15回完了後 |
|---|---|---|
| Hermesが知っているAI会話 | Hermes本人との会話のみ(state.db・第14回) | +Claude Code/Codexで母艦で交わした全会話(計3,490件・claude-code 35M+codex 31M) |
| 母艦のJSONL | 母艦の中だけ。Hermesからは見えない | Markdown化してVault配下に取り込み、git+rsyncでVPSへ同期 |
| 「昨日◯◯と話した件の続き」 | Hermesは何のことか分からない | Vault内transcriptを引いて構造化応答(優先順位の提案まで返ることがある) |
| エージェントの役割 | Claude Code・Codex・Hermesが各自バラバラに動く | Hermesが「3エージェント目」として母艦の議論に参加 |
| 同期コスト | 他AIの会話は取り込んでおらず該当なし | git push+rsyncで1分以内(差分同期時) |

一言でまとめると「**母艦のClaude CodeとCodexの作業履歴を、Hermesから自然言語で引けるようにする**」回だ。本回の構成は1枚の図に集約できる。

手を動かすのは、母艦でPowerShellスクリプトを1本走らせる、Vaultリポでgit pushする、VPSでrsyncを1行打つ──この3ステップだけだ。Hermes側に新しいskill(スキル=Hermesに作業手順を覚えさせる単位)をインストールする必要もない(bundled `obsidian` skill=最初から入っている連携スキルが第13回で入っている)。母艦側でPowerShellスクリプト1本と、VPS側でrsync 1コマンドが増えるだけだ。SKILL.md(Hermesに「このスキルはこう動かす」と教える定義ファイル)への追記は1度だけ。自然言語推測ロジックを足して無駄検索を減らすための最適化として行う。

:::message
本回の容量と件数は実機計測値だ。`du -sh`は項目ごとに独立に丸めるため、合計の`du -sh hermes-vault`は65M、内訳のclaude-code 35M+codex 31Mの単純和66Mとは1MB前後ずれる。同期時間の「1分以内」は差分同期時の値で、初回pushは履歴サイズ次第で数十秒〜数分かかることがある。詳細は§6で扱う。
:::

## 他のAIで作業した内容がHermesから見えない痛み

第13回でVaultをHermesに繋ぎ、第14回でHermes自身が交わした会話まで思い出せるようになった。書庫(Vault)・付箋(Memory)・司書(Session Search)の三点セットがVPSの上で揃ったわけだ。ここまでで「Hermes一人で完結する記憶」はだいぶ整った。

ただ、Telegramで実際に相談していると、毎日のように同じ場所でつまずく。

> 「昨日Claude Codeでwinsmuxのフックを直してたよな。あれ、結局どっちのexit codeで止めることにした?」

ここで言うexit codeは、プログラムが終了するときに返す数値のことだ。0なら成功、それ以外なら失敗、というのが慣習になっている。引用のやり取りでは「どの数値が来たら処理を止めるか」を議論していた、という前提で読んでほしい。

Hermesは黙る。当然だ。**Claude Codeで打った会話も、Codexで議論した結論も、母艦のローカルディスクの中**にしか無い。VPSのHermesが見ている書庫には1文字も入っていない。

母艦側のログがどこに転がっているかは把握している。Claude CodeとCodexは、それぞれ別のフォルダに1セッション1ファイルで履歴を貯め込んでいる。

```text
~/.claude/projects/<エンコードされたパス>/<uuid>.jsonl   # Claude Code
~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl              # Codex
```

`~/`はホームディレクトリ(自分のユーザーフォルダ)の省略表記、`jsonl`は1行に1つのJSONを並べた会話ログ形式、`<uuid>`はセッションごとに振られるランダムなIDだ。実測で合計3,490件。そして毎日数十件のペースで増え続けている。これだけの量を「昨日の自分が何で唸ってたか覚えてない」状態で眠らせたままにしているのは、正直もったいない。

困るのは、自分が思い出せないことだけではない。第13回§12で書いた**3エージェントで同じVaultを読む設計**(Claude Codeが実装、Codexがレビュー、Hermesが第三者視点で議論に加わる構図)の片足が、まだ宙に浮いていることだ。Claude Codeで実装してCodexにレビューさせるところまでは回る。だがTelegramからHermesに「この設計、3人目の意見ちょうだい」と振っても、Hermesは作業履歴を一切知らない。Vaultを共有する入口は第13回で開けてあるが、その中に流し込む材料(jsonl)が無いままだ。毎回ゼロから状況を貼り付けて説明するなら、ただの単発QAになる。連載の前提だった「議論に加わる3人目」は、まだ片肺飛行だ。

:::message alert
**この章の痛み**:3,490件分の作業履歴が、Hermesから見えないまま積み上がり続けている。第13回でVaultの入口は開いた。第14回でHermesは自分の会話を思い出せるようになった。だが、Claude CodeとCodexで議論した中身は、毎日数十件のペースでローカルディスクに溜まる一方で、VPSの3人目の席は空いたままだ。次の章で、この穴をどう塞ぐかを決める。
:::

## 5つ目の比喩=ノート

第13回で出した4つの比喩(📝付箋・📚書庫・📋手順書・🧹棚卸し)をそのまま引き継ぐ。本回はそこにもう1つだけ足す。**他のAIで書いたノート**=Claude CodeとCodexの作業履歴も、第13回で作った書庫(Obsidian Vault)の決まった棚に預ける、という話だ。

正直に言うと、3日前に自分がClaude Codeで何を試したかすら覚えていない。アラフィフの記憶力はそんなものだ。どうせ後から見返さないと思って放置していたが、第13回で書庫(Vault)を整えたタイミングで「ここに過去の作業履歴も棚として並べておけば、Hermesに聞けば思い出せるのでは」と気付いた。それが本回の出発点になる。

| 比喩 | Hermes機能 | 役割 | 本連載の該当回 |
|---|---|---|---|
| 📝 付箋 | Memory(USER.md/MEMORY.md) | 短い前提・毎回使う | 第12回 |
| 📚 書庫 | Obsidian Vault | 長期保存の知識ベース | 第13回 |
| 📋 手順書 | Skills | 「こう動く」のレシピ | 第10回・第18回予定 |
| 🧹 棚卸し | Cron | 定期的に整える | 第9回・後半のCurator回予定 |
| 🗒️ **ノート(新)** | 他AIの作業履歴 | **書庫の棚に預ける** | **本回(第15回)** |

### ノートの正体

ここで言う**ノート**とは、母艦(普段使っているノートPC)で動かしているClaude CodeとCodexが、裏で勝手に書き残しているセッションログのことだ。実体は次の2種類のファイルになる。

```
~/.claude/projects/<encoded>/<uuid>.jsonl    # Claude Codeの履歴
~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl # Codexの履歴
```

`jsonl`(1行=1イベントのログ形式)に、ユーザーの発言・AIの応答・ツール呼び出し・ツールの結果が時系列で記録されている。本回の変換スクリプト(§5で扱う)はこれらを要約せずMarkdownに転記するので、書き残された内容はそのまま残る。

自分では1通も書いた覚えがない。だが手元には、本回時点で約3,490通(Claude 1,272通+Codex 2,218通)積もっていた。「昨日winsmuxでどこに詰まったか」「Codexにどのリファクタを断られたか」が、全部このノートの中にある。

### ノートを書庫に預けると何が起きるか

書庫(Vault)にノートを並べておけば、後日Telegramで一言聞くだけでいい。

> 私: 昨日Claude Codeで何やってたっけ
>
> Hermes:2026-06-29のセッションが3件あります。主にwinsmuxのpane分割ロジックの修正で、tmux 3.4のbind-key挙動変更が原因でした。詳細は`raw/transcripts/claude-code/2026-06-29_a3f7b21c.md`にあります。

Hermesが該当するノートを棚から引き抜き、要点だけ返してくる。ファイルパスまで添えてくれるので、原文を読みたければObsidianで開けばよい。実体はbundled `obsidian` skillによるファイル一覧と検索だが、利用者から見ると「司書に聞いたら持ってきてくれた」体験になる。

### 棚の場所とファイル名の決め方

ノートを預ける棚の場所も決まっている。書庫(Vault)の中に`raw/`という生の素材置き場フォルダを切り、その下にAIごとの棚を2つ作る。フォルダ階層はこうなる。

```
hermes-vault/
├── (第13回で作った手書きノート).md  # 自分で書いたノート
└── raw/                              # 生の素材置き場
    └── transcripts/
        ├── claude-code/
        │   └── YYYY-MM-DD_sid8.md   # Claude Codeのノート
        └── codex/
            └── YYYY-MM-DD_sid8.md   # Codexのノート
```

ファイル名は`YYYY-MM-DD_sid8.md`に統一する。`sid8`はセッションIDの先頭8桁のことだ。Claude Codeの場合は`<uuid>.jsonl`のUUID先頭8桁、Codexの場合は`rollout-<timestamp>-<uuid>.jsonl`のUUID先頭8桁を使う。日付と8桁IDで人間が眺めて判別しやすくするための長さで、両者を同じ規約に揃えるのは§5の変換スクリプトの仕事になる。

### 第13回の手書きノートと棚を分ける理由

第13回で自分の手で書いたノート(調べごとのメモや読んだ記事のまとめ)はVault直下に`.md`で直置きしている。ノートは`raw/transcripts/`の下に隔離する。棚を分けるのは「自分が書いたノート」と「別AIから預かった生のノート」を混在させないためだ。

さらに§6で扱うrsyncのfilterで`raw/transcripts/**`は母艦→VPS方向のみに流れるよう構成する。Hermesが自分の手で書いたノートと、別AIから預かったノートが混ざる事故も起きない設計になる。

:::message
**本回スコープ**: Claude CodeとCodexの2系統のみを対象にする。Hermes自身のセッション履歴は第14回の`session_search`(SQLite `state.db`側)が担当しており、`raw/transcripts/`には入らない。「他のAIで書いたノート」と限定するのはこの棲み分けのためだ。
:::

### 第13回§11の整理との接続

第13回§11では、母艦↔VPSの同期用git repoは`~/hermes-vault-repo`、HermesがDockerコンテナ越しに書き込む実体Vaultは`/home/admin/hermes-vault`(symlink先)で、両者は別directoryになっていた。両者の統合は連載後半送りと書いた。

本回はその統合を完全自動化までは進めない。代わりに**rsync(差分だけ転送するファイル同期コマンド)を1本だけ挟んで、半手動で両者を繋ぐ段階に進める**。流れはこうなる。

```
母艦(変換スクリプトでノートを生成)
   ↓ git push(コード履歴と一緒にバージョン管理)
VPS ~/hermes-vault-repo
   ↓ rsync(差分のみ転送・速い)
VPS /home/admin/hermes-vault(Hermesが見るVault)
```

git pushとrsyncを並べる理由は役割が違うからだ。git pushは「母艦とVPSでVaultの履歴を揃える」担当、rsyncは「VPS内で同期repoからHermesが見るVaultへ素材を流す」担当になる。

:::message
**今回の到達点**: 司書(Hermes)がノートを引ける状態まで作る。母艦で変換スクリプトを走らせ、git push+rsyncで棚に並べ、Telegramで問い合わせれば該当のノートが引けることを確認する。本回時点で約3,490通を一気に持ち込む。
:::

:::message
**未来の自動化**: cronで毎晩棚卸しまで自動化する話は、連載後半のCurator回で扱う予定だ(連載の回数は前後する可能性がある)。本回は手で持ち込む段階にとどめ、運用が安定してから自動化する道を残す。
:::


## 構成図──母艦で整え、VPSで読ませる

本回は作業の置き場が2つに分かれる。母艦Windowsで他のAIの作業履歴を整え、VPS側でHermesがそれを読む。1枚の図で全体像を先に押さえると、§5以降の手順がどこに効くかが見える。

![【構成図】左カラム=母艦Windows:Claude Code(~/.claude/projects配下のjsonl)とCodex CLI(~/.codex/sessions配下のjsonl)をPowerShell変換スクリプトでMarkdownに整え、Obsidian Vaultのraw/transcripts/配下に出力する。git pushでGitHub経由でVPSへ届ける。右カラム=VPS:git pullで~/hermes-vault-repoに取り込み、rsyncで~/hermes-vault(コンテナのマウント元へのホスト側symlink)へ反映する。Hermesがbundled obsidian skillでmdを読み、Telegramから自然言語で呼び出せる。下部=次回(第16回予定)でllm-wiki skillが同じraw/transcripts/を入力にentities/concepts/queriesのセカンドブレイン(第二の脳)を組み立てる。](/images/hermes-vps/hermes-vps-15-architecture.png)

図に出てくる層を、まず母艦側の4つから並べる。

- **Claude Code transcript**(`~/.claude/projects/<encoded>/<uuid>.jsonl`):母艦のClaude Codeが1セッションごとに1ファイル吐く生ログ(jsonl=JSON Lines形式・1行1レコードの中間ファイル)。プロジェクト単位でフォルダが切られる(`<encoded>`はプロジェクトpathをURLエンコードした文字列・実物は§5で見る)。
- **Codex rollout**(`~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`):Codex CLIが1セッションごとに吐く生ログ。日付単位でフォルダが切られる。Claude Codeとは置き場の作りが違うので、変換スクリプト側で両対応にする。Codex Desktop Appが同じ場所に書くかは実機未検証のため、今回はCodex CLIのみ対象とする。
- **PowerShell変換スクリプト**(§6・自前1本):両方のjsonlを読み、`user`と`assistant`の本文ターンだけを抜き出してMarkdownに整える。LLMは呼ばない。文字列処理だけで決定論的に動く(同じjsonlを与えれば毎回同じMarkdownが出る)。
- **Vault raw/transcripts/**:前回作った`~/Documents/Obsidian Vault/`の中に新設するサブフォルダ(`claude-code/`と`codex/`)。出力先はここで固定する。新規git repoは作らず、前回のVault repoを再利用する。

ここまでが母艦の中で完結する作業。次の4項目は同期経路とVPS側で起こることだ。

- **git push→git pull**:前回§11で通した同期経路をそのまま使う。母艦で`git push`してGitHubに上げ、VPSの`~/hermes-vault-repo`で`git pull`する。
- **rsync**(VPS内・§6の最後の手順):`rsync`(ファイル差分同期コマンド・Linux標準)で`~/hermes-vault-repo`から`~/hermes-vault`へ片方向で反映する。Hermesが`~/hermes-vault`に書いた他のファイル(MEMORY.md等)を巻き込まないよう、コピー対象は`raw/transcripts/`配下に絞る(具体的なrsyncオプションは§6本体で示す)。
- **Hermes Agent**(VPS常駐):bundled(Hermesに最初から同梱されている)obsidian skillで`~/hermes-vault`配下のmdを直接読む。TelegramからHermesに自然言語で頼めば、obsidian skillが該当ファイルを読みに行く(§7)。
- **llm-wiki**(次回・第16回予定):同じ`raw/transcripts/`を入力として、entities(人物・モノ)/concepts(概念)/queries(検索クエリ)の3層構造のセカンドブレイン(第二の脳)に組み立てる。今回の出力がそのまま次回の入力になる。

:::message
前回§11で予告した通り、`~/hermes-vault-repo`(git同期用)と`~/hermes-vault`(コンテナがマウントしているサンドボックスディレクトリへのホスト側symlink・前回§7で作成)はあえて別管理にしてある。今回は両者を「rsync 1コマンド」で手で繋ぐ。まず1回流して、確かに繋がることを目で確認するところまで進める。
:::

自動化(cron常駐+Curator=履歴を整理する自動化エージェント)は連載後半(第19回予定のCurator+cron回)で本格的に扱う。最初から自動化に走ると、繋がっていないことに気づくのが3日後になる──そういう詰まり方が一番ヤバいので、まずは手で1回流して全体像を体に通す。

図の左半分(母艦の仕事)は§5〜§6で扱い、右半分(VPSとHermesの仕事)は§7で扱う。今回`raw/transcripts/`に貯めた履歴は、そのまま次回llm-wikiの入力になる。つまり今回の作業が次回の準備を兼ねる(図の右下の点線)。

## 事前準備:jsonl場所とVault接続の現役確認

§6(次章のスクリプト実行)に進む前に、足場が揃っているかを確認する。確認するのは2点。1つ目は、母艦(=日常の開発で使っているノートPC等)のClaude CodeとCodexが作業履歴を実際にどこへ書き出しているか(スクリプトが読みに行く先)。2つ目は、第13回で建てたObsidian Vaultが今も生きているか(スクリプトが書き込む先)。

なお本回では `jsonl`(JSON Lines形式:1行1レコードでログを貯めるテキストファイル)という言葉を多用する。以降は素のjsonl表記でいく。

### 5-1. Claude CodeとCodexのjsonl置き場を確認する

PowerShellを起動し、両AIの保存先を順に確認する。Codex側は年月でフォルダが切られるので、コマンドの中で「今日の年月」を自動で拾うようにしておくと、後日試した読者の環境でも空振りしない。

```powershell
ls $env:USERPROFILE\.claude\projects | Select-Object -First 5
$y = Get-Date -Format yyyy
$m = Get-Date -Format MM
ls $env:USERPROFILE\.codex\sessions\$y\$m | Select-Object -First 5
```

中身を全部理解する必要はないが、参考に1画面に並べて見ておくと§6の理解が早い。

![PowerShellで`$env:USERPROFILE\.claude\projects`と`$env:USERPROFILE\.codex\sessions\<年>\<月>`を続けて実行した画面。上半分にClaude Codeのエンコード済み(=特殊文字を変換した)プロジェクトディレクトリ名($env:USERPROFILE\.claude\projects\C--Users-...-Documents-Projects-...形式・社内名はマスク)、下半分にCodex側の日付フォルダ名が並ぶ。プロンプト内の`C:\Users\<name>`もマスク](/images/hermes-vps/hermes-vps-15-jsonl-locations.png)

1行目はClaude Codeの保存先で、長いディレクトリ名が並ぶ。これは作業対象のディレクトリ(cwd)のパスを、ファイル名で使える形に変換した名前だ。**作業対象のディレクトリ1個につき1ディレクトリ**作られる仕組みで、中に各セッションの `<uuid>.jsonl`(uuid=ランダムな識別子の文字列)が貯まる。一方2行目はCodexの保存先で、**日付ごとに2桁数字のフォルダ**が並ぶ。手元では今日時点で `01〜30` の範囲が見えるが、欠番もあるし、後日試せば現在日まで自然に増えていく。同じ作業履歴でも、Claude Codeは「ディレクトリごと」、Codexは「日付ごと」と切り方が違う。

§6の変換スクリプトはこの差を両対応で吸収するように書いてある。読者側は「保存場所のクセが違う」「だからスクリプトが両方を相手にしてくれる」だけ押さえれば十分だ。画面に出るディレクトリ数や日付範囲は環境と時期で変わるので、自分の画面とスクショの数字が完全一致していなくても気にしない。

:::message
両ディレクトリが空、もしくは存在しない場合は、まずClaude CodeかCodexで1回だけでもプロンプトを送って応答を受け取っておく必要がある。jsonlが0件だと、§6で変換しても出力されるmdが0件になる。日常的に母艦で両AIを使っている読者なら、すでに相当数貯まっているはずだ(自分の手元はClaude側で4桁、Codex側でも4桁に達している)。
:::

### 5-2. 第13回Vault接続の現役確認

スクリプトが書き込む先は、第13回で建てたObsidian Vault(`Hermes-Vault`)だ。母艦のObsidianを起動して、このVaultがそのまま開けることを確認する。

確認は2つだけ。

- 左下のVault名が `Hermes-Vault` になっているか
- 左サイドバーに第13回の成果物(`Hermes Agent調査.md` と `shared-ai/` フォルダ)が並んで見えるか

第13回から日が空くと「あれ、保管庫どこに置いたっけ」となるのは自分も同じだ。Obsidianを久しぶりに起動するとVaultが「最近使ったVault」一覧から消えていることがある。その場合は次の順で開き直すだけで戻る。

1. 左下のVault名をクリック
2. 「Vault管理」を選ぶ
3. 「フォルダーをVaultとして開く」を押す
4. `C:\Users\<name>\Documents\Hermes-Vault` を選ぶ

![母艦のObsidianでHermes-Vaultを開いた画面。左下のVault名が`Hermes-Vault`・左サイドバーに第13回で作った`shared-ai/`配下の`Hermes Agent調査`+本回作業で増えた`raw/transcripts/claude-code/`+`raw/transcripts/codex/`が並ぶ。右ペインに`Hermes Agent調査.md`の6項目テンプレ(Title/Summary/Source/Context/Links/Next Action)が表示されている](/images/hermes-vps/hermes-vps-15-vault-connection-alive.png)

(画像の右側は第13回で作った5項目テンプレ=タイトル/要約/詳細/示唆/出典の5見出し構成のmdが見えていればOK)

本回のスクリプトは、このVaultの直下に `raw/transcripts/` というサブディレクトリ(=配下に作る小さい部屋)を自動作成してmdを書き込む。`raw/transcripts/` はこの時点で**存在しなくてOK**で、§6でスクリプトが自動で切ってくれる。

:::message alert
ここまでで詰まる読者向けの注意。「Vaultが開けない」「ファイルツリーに第13回の成果物が見当たらない」場合は、§6に進む前に第13回まで戻ってVault側を直しておく。本回のスクリプトは「Vaultが正しく開ける状態」を前提にしか動かない。
:::

ここまでが揃ったら、§6でスクリプトをbinに保存して動かす段に進む。スクリプトは§5で確認した母艦Vault実体(`~/Documents/Hermes-Vault`)に `raw/transcripts/` を切って書き込み、§6-6でVPS側(第13回§11で建てた `~/hermes-vault-repo`)へgit push+rsyncで同期する。母艦側Vaultと、Hermesコンテナが実際に見るVault(`~/hermes-vault`)は別物として管理し、両者をrsync 1コマンドで繋ぐ流れだ(完全自動化は第19回のCuratorで扱う)。

## 変換スクリプトで作業履歴をVaultに取り込む

スクリプトの中身は読まなくていい。コピペで動く。理由は3つだけだ。

:::message
**先に結論──このスクリプトが安心して使える3つの根拠**

1. **LLM呼び出しゼロ**=PowerShell組み込みの`ConvertFrom-Json`と文字列処理だけで動く。OpenAI/Claude APIを1回も叩かないので、毎晩動かしても料金がかからない+挙動が予測できる
2. **jsonl(AIツールが会話を1行=1イベントで貯める形式)のノイズを落とす**=ツール呼び出し等のメタ情報を捨て、user/assistantの本文だけをmd化する
3. **1ファイル12万文字で打ち切る**=極端に長いセッションでも本文は400KB弱に収まり、Obsidianが重くならない

中身の3要点は§6最後の補足にもう少し丁寧に書いた。技術的に細かい話なので、読まずに進んで構わない。
:::

この章でやることは1つだけだ。母艦(普段使いのWindows PC)のClaude Code/Codexが残した会話履歴を、Hermesが読める形に整えてVPSに送る。手順はコピペだけで動く6ステップに分解した。難語(jsonl・rsync・symlink等)は初出のところで都度短く説明するので、構えなくていい。

:::message
**本章の流れ(step1〜step6・撮影8枚)**

| 重要度 | step | やること |
|---|---|---|
| ★★★ | step1 | スクリプトをファイルに保存する(初回のみ・ここが一番神経を使う) |
| ★★★ | step2 | スクリプトを動かして変換させる(初回はハングに見える落とし穴あり) |
| ★ | step3 | Vault配下にraw/transcripts/と変換mdができたか目視確認 |
| ★ | step4 | mdを1ファイル開いて読める形か確認 |
| ★★ | step5 | git statusで増えたファイルを見てpushでGitHubに送る |
| ★★ | step6 | VPSでgit pull→rsyncでHermesが見るVaultへ同期 |

前半(step1-3)で「変換して置く」、後半(step4-6)で「確認してVPSに送る」の2段構えだ。
:::

### step1=スクリプトをファイルに保存する(初回のみ・3つの小ステップ)

母艦Windowsで「①PowerShellを起動して保存先フォルダ(`bin/`)を作る → ②スクリプト全文をメモ帳で保存 → ③保存できたかlsで確認」の3つの小ステップを順に行う。スクリプトの中身を理解する必要はない。コピペで動く。

#### 1-a. PowerShellを起動して保存先フォルダを作る

スタートメニューから「PowerShell」を起動する(右クリックの「管理者として実行」は不要・通常起動でOK)。下のコマンドを貼り付けてEnter。すでに`bin/`がある人はこの手順をスキップしてよい。

```powershell
New-Item -ItemType Directory -Path $env:USERPROFILE\bin -Force
```

実行直後に`Directory: C:\Users\<name>`+`d----- 2026/MM/DD HH:MM  bin`のような1行が表示されればフォルダ作成成功だ。

![PowerShellで`New-Item -ItemType Directory -Path $env:USERPROFILE\bin -Force`を実行した直後の画面。Mode/LastWriteTime/Length/Nameのヘッダーの下に`d----- 2026/06/30 9:32  bin`の行が並び、bin/フォルダが作成された](/images/hermes-vps/hermes-vps-15-bin-folder-created.png)

#### 1-b. スクリプト全文をメモ帳で`sync-ai-transcripts.ps1`として保存

この1-bが本章で一番詰まりやすい箇所だ。3つの小ステップに分けた。

**1-b-1. スクリプト全文をコピーする**

下の折りたたみ(`📋 スクリプト全文`)を開いて、中のスクリプトを全選択(`Ctrl+A`)→コピー(`Ctrl+C`)する。右上のコピーアイコンでも同じだ。

**1-b-2. メモ帳を起動して貼り付ける**

スタートメニューから「メモ帳」を起動して、貼り付け(`Ctrl+V`)する。

**1-b-3. 4つの注意点を守って`Ctrl+S`で保存する**

`Ctrl+S`で保存ダイアログを開く。ここで以下の4点を守る。

:::message alert
**保存ダイアログで必ず守る4点(ここで詰まる人が一番多い)**

- 保存先:`C:\Users\<name>\bin\`(=1-aで作ったフォルダ)
- ファイル名:`sync-ai-transcripts.ps1`
- ファイルの種類:**「すべてのファイル(\*.\*)」**(デフォルトの「テキスト文書(\*.txt)」のままだと`sync-ai-transcripts.ps1.txt`という別物のファイル名で保存されて動かなくなる)
- 文字コード:**UTF-8**(メモ帳の保存ダイアログ下部のドロップダウン・`UTF-8 (BOM付き)`ではなく`UTF-8`を選ぶ)
:::

:::details 📋 スクリプト全文(`sync-ai-transcripts.ps1`・コピペ用)

```powershell
<#
.SYNOPSIS
  Claude Code / Codex の作業履歴(jsonl)を読めるMarkdownに変換し、
  Obsidian Vaultの raw/transcripts/ に置く。第15回(B案)用。
  LLM呼び出しゼロの決定論的処理。
#>
param(
  [string]$ClaudeRoot = "$env:USERPROFILE\.claude\projects",
  [string]$CodexRoot  = "$env:USERPROFILE\.codex\sessions",
  [string]$VaultRoot  = "$env:USERPROFILE\Documents\Hermes-Vault"
)

$ErrorActionPreference = 'Stop'

function Write-Utf8NoBom([string]$Path, [string]$Text) {
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

function Sanitize([string]$s) {
  if (-not $s) { return '' }
  return ($s -replace "`r", '')
}

function Truncate-Block([string]$s, [int]$head = 15, [int]$tail = 15) {
  if (-not $s) { return '' }
  $lines = ($s -replace "`r", '') -split "`n"
  if ($lines.Count -le ($head + $tail + 2)) { return ($lines -join "`n") }
  $h = $lines[0..($head - 1)]
  $t = $lines[($lines.Count - $tail)..($lines.Count - 1)]
  $omitted = $lines.Count - $head - $tail
  return (($h -join "`n") + "`n... ($omitted 行省略) ...`n" + ($t -join "`n"))
}

function Build-Md([string]$Source, [string]$SessionId, [string]$Created, [string]$Title, [object[]]$Turns) {
  $summary = ''
  foreach ($t in $Turns) {
    if ($t.role -eq 'user' -and $t.text.Trim()) {
      $summary = ($t.text.Trim() -replace "`n", ' ').Substring(0, [Math]::Min(80, $t.text.Trim().Length))
      break
    }
  }
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('---')
  [void]$sb.AppendLine("title: `"$Title`"")
  [void]$sb.AppendLine("summary: `"$summary`"")
  [void]$sb.AppendLine("source: $Source")
  [void]$sb.AppendLine("created: $Created")
  [void]$sb.AppendLine("session_id: $SessionId")
  [void]$sb.AppendLine('tags: [transcript, ' + $Source + ']')
  [void]$sb.AppendLine('---')
  [void]$sb.AppendLine('')
  foreach ($t in $Turns) {
    $body = Sanitize $t.text
    if (-not $body.Trim()) { continue }
    if ($t.role -eq 'user') { [void]$sb.AppendLine('## User') }
    else                    { [void]$sb.AppendLine('## Assistant') }
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine($body.Trim())
    [void]$sb.AppendLine('')
  }
  $result = $sb.ToString()
  $maxChars = 120000
  if ($result.Length -gt $maxChars) {
    $result = $result.Substring(0, $maxChars) + "`n`n... (セッションが大きいため以降省略) ...`n"
  }
  return $result
}

function Convert-ClaudeFile([string]$File) {
  $turns = @()
  $sid = [System.IO.Path]::GetFileNameWithoutExtension($File)
  $created = ''
  $stream = $null; $reader = $null
  try {
    $stream = [System.IO.File]::Open($File, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $reader = [System.IO.StreamReader]::new($stream, [System.Text.UTF8Encoding]::new($false))
  } catch {
    Write-Warning "Skip (locked or unreadable): $([System.IO.Path]::GetFileName($File))"
    if ($reader) { $reader.Dispose() }
    if ($stream) { $stream.Dispose() }
    return [pscustomobject]@{ session_id = $sid; created = ''; turns = @() }
  }
  try {
    while (($line = $reader.ReadLine()) -ne $null) {
      if (-not $line.Trim()) { continue }
      try { $o = $line | ConvertFrom-Json } catch { continue }
      if (-not $created -and $o.timestamp) { $created = $o.timestamp }
      $t = $o.type
      if ($t -ne 'user' -and $t -ne 'assistant') { continue }
      $content = $o.message.content
      if (-not $content) { continue }
      $parts = @()
      foreach ($item in $content) {
        if ($item -is [string]) { $parts += $item; continue }
        switch ($item.type) {
          'text' {
            if ($item.text) {
              if ($item.text -like '*<system-reminder>*' -or $item.text -like '<command-*' -or $item.text -like '<local-command*') { break }
              $parts += (Truncate-Block $item.text)
            }
          }
          'tool_use' {
            $nm = $item.name
            if ($nm -eq 'Bash' -and $item.input.command) {
              $parts += ('### Tool: Bash' + "`n" + '```bash' + "`n" + (Truncate-Block ([string]$item.input.command)) + "`n" + '```')
            } else {
              $parts += ("_(tool: $nm)_")
            }
          }
          'tool_result' {
            $rc = $item.content
            $rtext = ''
            if ($rc -is [string]) { $rtext = $rc }
            elseif ($rc -is [array]) { $rtext = (($rc | Where-Object { $_.type -eq 'text' } | ForEach-Object { $_.text }) -join "`n") }
            if ($rtext.Trim()) { $parts += ('```' + "`n" + (Truncate-Block $rtext) + "`n" + '```') }
          }
          'thinking' { }
          default { }
        }
      }
      if ($parts.Count -eq 0) { continue }
      $joined = ($parts -join "`n`n").Trim()
      if (-not $joined) { continue }
      $turns += [pscustomobject]@{ role = $t; text = $joined }
    }
  } catch {
    Write-Warning "Read error mid-file (kept partial): $([System.IO.Path]::GetFileName($File))"
  } finally {
    if ($reader) { $reader.Dispose() }
    if ($stream) { $stream.Dispose() }
  }
  return [pscustomobject]@{ session_id = $sid; created = $created; turns = $turns }
}

function Convert-CodexFile([string]$File) {
  $turns = @()
  $sid = ''
  $created = ''
  $stream = $null; $reader = $null
  try {
    $stream = [System.IO.File]::Open($File, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $reader = [System.IO.StreamReader]::new($stream, [System.Text.UTF8Encoding]::new($false))
  } catch {
    Write-Warning "Skip (locked or unreadable): $([System.IO.Path]::GetFileName($File))"
    if ($reader) { $reader.Dispose() }
    if ($stream) { $stream.Dispose() }
    return [pscustomobject]@{ session_id = [System.IO.Path]::GetFileNameWithoutExtension($File); created = ''; turns = @() }
  }
  try {
    while (($line = $reader.ReadLine()) -ne $null) {
      if (-not $line.Trim()) { continue }
      try { $o = $line | ConvertFrom-Json } catch { continue }
      if ($o.type -eq 'session_meta') {
        $p = $o.payload
        if ($p.session_id) { $sid = [string]$p.session_id }
        elseif ($p.id)     { $sid = [string]$p.id }
        if ($p.timestamp)  { $created = $p.timestamp }
        continue
      }
      if ($o.type -ne 'response_item') { continue }
      $p = $o.payload
      if ($p.type -ne 'message') { continue }
      $role = $p.role
      if ($role -ne 'user' -and $role -ne 'assistant') { continue }
      $texts = @()
      foreach ($item in $p.content) {
        if ($item -is [string]) { $texts += $item; continue }
        if (($item.type -eq 'input_text' -or $item.type -eq 'output_text' -or $item.type -eq 'text') -and $item.text) { $texts += $item.text }
      }
      if ($texts.Count -eq 0) { continue }
      $joined = ($texts -join "`n").Trim()
      if (-not $joined) { continue }
      if ($role -eq 'user' -and ($joined -like '# AGENTS.md*' -or $joined -like '*<environment_context>*' -or $joined -like '*<INSTRUCTIONS>*' -or $joined -like '<user_instructions>*')) { continue }
      $turns += [pscustomobject]@{ role = $role; text = $joined }
    }
  } catch {
    Write-Warning "Read error mid-file (kept partial): $([System.IO.Path]::GetFileName($File))"
  } finally {
    if ($reader) { $reader.Dispose() }
    if ($stream) { $stream.Dispose() }
  }
  if (-not $sid) { $sid = [System.IO.Path]::GetFileNameWithoutExtension($File) }
  return [pscustomobject]@{ session_id = $sid; created = $created; turns = $turns }
}

function Date-From($iso) {
  if ($null -eq $iso) { return (Get-Date -Format 'yyyy-MM-dd') }
  if ($iso -is [datetime]) { return $iso.ToString('yyyy-MM-dd') }
  $s = [string]$iso
  if ($s.Length -ge 10 -and $s[4] -eq '-') { return $s.Substring(0, 10) }
  try { return ([datetime]$s).ToString('yyyy-MM-dd') } catch { return (Get-Date -Format 'yyyy-MM-dd') }
}

function Sid8([string]$sid) {
  $clean = $sid -replace '[^A-Za-z0-9]', ''
  if ($clean.Length -ge 8) { return $clean.Substring(0, 8) }
  return $clean
}

$claudeCount = 0; $codexCount = 0; $skipCount = 0

# --- Claude Code ---
$claudeOut = Join-Path $VaultRoot 'raw\transcripts\claude-code'
New-Item -ItemType Directory -Path $claudeOut -Force | Out-Null
if (Test-Path $ClaudeRoot) {
  Get-ChildItem -Path $ClaudeRoot -Recurse -Filter '*.jsonl' -File | ForEach-Object {
    $r = Convert-ClaudeFile $_.FullName
    if ($r.turns.Count -eq 0) { return }
    $date = Date-From $r.created
    $name = "$date`_$(Sid8 $r.session_id).md"
    $dest = Join-Path $claudeOut $name
    if (Test-Path $dest) { $script:skipCount++; return }
    $title = "Claude Code session $($r.session_id.Substring(0,[Math]::Min(8,$r.session_id.Length))) ($date)"
    $md = Build-Md 'claude-code' $r.session_id $date $title $r.turns
    Write-Utf8NoBom $dest $md
    $script:claudeCount++
  }
}

# --- Codex ---
$codexOut = Join-Path $VaultRoot 'raw\transcripts\codex'
New-Item -ItemType Directory -Path $codexOut -Force | Out-Null
if (Test-Path $CodexRoot) {
  Get-ChildItem -Path $CodexRoot -Recurse -Filter 'rollout-*.jsonl' -File | ForEach-Object {
    $r = Convert-CodexFile $_.FullName
    if ($r.turns.Count -eq 0) { return }
    $date = Date-From $r.created
    $name = "$date`_$(Sid8 $r.session_id).md"
    $dest = Join-Path $codexOut $name
    if (Test-Path $dest) { $script:skipCount++; return }
    $title = "Codex session $(Sid8 $r.session_id) ($date)"
    $md = Build-Md 'codex' $r.session_id $date $title $r.turns
    Write-Utf8NoBom $dest $md
    $script:codexCount++
  }
}

$total = $claudeCount + $codexCount
Write-Output "[INFO] Claude Code: $claudeCount files"
Write-Output "[INFO] Codex: $codexCount files"
Write-Output "[INFO] Skipped (existing): $skipCount files"
Write-Output "[INFO] Total: $total markdown files -> $VaultRoot\raw\transcripts\"
```
:::

:::message
**スクリプトを別ファイルでダウンロードしたい場合**

メモ帳に貼り付けるのが面倒なら、連載リポジトリ(GitHub)の`scripts/sync-ai-transcripts.ps1`から直接ダウンロードしてもよい。手順は「リンクを開く → Raw表示 → `Ctrl+S`で保存」だけだ。本文中の折りたたみはリンクが死んだ時のバックアップとして残してある。
:::

#### 1-c. 保存できたかPowerShellで確認

PowerShellに戻って下のコマンドで保存を確認する。

```powershell
ls $env:USERPROFILE\bin\sync-ai-transcripts.ps1
```

lsの出力で**Length(ファイルサイズ)が0でない**+**LastWriteTimeが今日**+**Nameが`sync-ai-transcripts.ps1`**(`.ps1.txt`でないこと)の3点を確認する。

![PowerShellで`ls $env:USERPROFILE\bin\sync-ai-transcripts.ps1`を実行した画面。Length列に数千バイト規模の数値、LastWriteTimeは今日の時刻、Nameは`sync-ai-transcripts.ps1`になっている(`.ps1.txt`ではない)](/images/hermes-vps/hermes-vps-15-script-saved-ls.png)

### step2=スクリプトを動かして変換させる

保存したスクリプトを叩く。**初回は全件処理**(母艦に貯まっている過去全セッションを処理)するため数分から数十分かかる。母艦のjsonl総量による(Claude Code+Codex合計が10GB超なら1時間級も普通)。2回目以降は既存ファイルをスキップするので一瞬で終わる。

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $env:USERPROFILE\bin\sync-ai-transcripts.ps1
```

完走すると4行のサマリが出る。下は実機の例だ。

```text
[INFO] Claude Code: 1272 files
[INFO] Codex: 2218 files
[INFO] Skipped (existing): 1477 files
[INFO] Total: 3490 markdown files -> C:\Users\<name>\Documents\Hermes-Vault\raw\transcripts\
```

件数は環境によって違う(過去にどれだけClaude Code/Codexを使ったかで決まる)。**4行のサマリが出てプロンプト(`PS C:\Users\<name>>`)に戻れば成功**だ。エラー赤字が出たら§9-1の早見表にある「実行ポリシーで拒否される」「文字化け」「別のプロセスで使用中(ロック)」を参照する。

:::message
**実機サマリの`Skipped: 1477`の見方(完全な初回はここが0になる)**

上のサマリ例は撮影時にすでに途中まで変換済の状態から再実行した結果で、`Skipped (existing): 1477 files`が出ている。**まっさらな状態で初めて実行する場合はここが`0 files`になる**(全ファイルが新規変換扱い)。Totalが母艦の総セッション数と一致するかだけ確認すればよい。
:::

![PowerShellで変換スクリプトが完走した直後の画面。Claude Code/Codex/Skipped/Totalの4行サマリが並び、プロンプトが復帰している](/images/hermes-vps/hermes-vps-15-first-run-summary.png)

:::message alert
**初回はハングに見える(本回最大の落とし穴)**

このスクリプトは進捗を逐次表示しない=実行中は画面に何も出ない。jsonl総量が大きい母艦では10分以上「何も出ない」ことが普通で、ハングと勘違いして`Ctrl+C`で止めたくなる。

別のPowerShellウィンドウをもう1つ開いて、30秒ごとに件数を出すループを回しておくと安心だ。

```powershell
while ($true) {
  $cc = (ls $env:USERPROFILE\Documents\Hermes-Vault\raw\transcripts\claude-code\*.md -ErrorAction SilentlyContinue).Count
  $cx = (ls $env:USERPROFILE\Documents\Hermes-Vault\raw\transcripts\codex\*.md -ErrorAction SilentlyContinue).Count
  Write-Host "$(Get-Date -Format 'HH:mm:ss')  Claude: $cc  |  Codex: $cx"
  Start-Sleep 30
}
```

数字が増えていれば処理中=ハングではない。完走したらこのループは`Ctrl+C`で止める。
:::

実機の進捗例を見ておくと「これくらいで動いているのが正常」が掴める。下は2026-06-30に母艦で実行した時のループログだ。

![進捗ループの実機ログ。約4分で完走した。30秒ごとにClaude→Codexの順に件数が増えていく様子が見える](/images/hermes-vps/hermes-vps-15-progress-loop.png)

30秒ごとに数字が増えていれば「ハングではない・処理中」が一目で分かる。

### step3=Vault配下にraw/transcripts/と変換mdができたことを目視確認

step2のスクリプトはVault配下に`raw/transcripts/claude-code/`と`raw/transcripts/codex/`フォルダを自動で作って、そこにmdを置く。そのフォルダが本当にできて、mdが並んでいるかをObsidian(またはエクスプローラ)で目視する。

```powershell
# 念のためPowerShellで件数を確認
(ls $env:USERPROFILE\Documents\Hermes-Vault\raw\transcripts\claude-code\*.md).Count
(ls $env:USERPROFILE\Documents\Hermes-Vault\raw\transcripts\codex\*.md).Count
```

Obsidianを開いて左サイドバーをリフレッシュすると、`raw/`→`transcripts/`→`claude-code/`+`codex/`が並ぶ。各フォルダ配下に`YYYY-MM-DD_xxxxxxxx.md`形式のファイルが大量に並んでいるはずだ。

![Obsidianの左サイドバーで`raw/transcripts/claude-code/`と`raw/transcripts/codex/`フォルダが展開された画面。配下に`YYYY-MM-DD_sid8`形式のmdが大量に並ぶ](/images/hermes-vps/hermes-vps-15-vault-raw-transcripts-folders.png)

### step4=mdを1ファイル開いて読める形か確認

変換結果が本当に「人が読める形」になっているかを1ファイル開いて確認する。

- 冒頭にfrontmatter(`---`で囲まれたメタ情報・`title`/`summary`/`source`/`created`/`session_id`の5項目)
- その下に`## User`+発話+`## Assistant`+応答が交互に並ぶ
- jsonl生データに大量にあった`tool_use`/`thinking`/`progress`等のノイズが落ちている

この3点が揃っていればOKだ。

:::message
**frontmatterって何のためにあるのか**

frontmatterはMarkdownファイルの先頭にYAML形式で書くメタ情報で、Obsidianが一覧表示やソート、タグ検索に使う。本回の場合、`summary`にはセッション最初のuser発話冒頭80文字が入る=Obsidianの一覧で「何のセッションか」を一目で判別できる仕掛けだ。Hermesがあとから「○月○日のwinsmuxの話」と引く時にもこのメタ情報が手がかりになる。
:::

開くコマンドはコピペで動く1行版を用意した。

```powershell
notepad (ls $env:USERPROFILE\Documents\Hermes-Vault\raw\transcripts\claude-code\*.md | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
```

ObsidianならStep3の画面でmdをクリックすれば同じ中身が右ペインに開く。

![右ペインに変換済mdが開いた状態。frontmatter 5項目(title/summary/source/created/session_id)+tagsが表示され、その下に`## User`発話と`## Assistant`応答が交互に並ぶ。生jsonlの`tool_use`や`thinking`は除去されている](/images/hermes-vps/hermes-vps-15-output-md-content.png)

:::message
撮影した代表ファイルは最小往復(`Hello, respond with just OK`→`OK`)だが、実際のセッションmdを開けばコードブロック付きの長いやり取りが読める形で並ぶ。
:::

### step5=git statusで増えたファイルを見てpushでGitHubに送る

第13回で建てたVault git repo(GitHubの私的リポジトリ)に、変換したmdを送る。やることはコミット(変更を記録)→プッシュ(GitHubに送る)の2段だ。

ここで`git add`の前に**git status**で「何が新しく増えたか」を目で見ておく。意図しないファイルが混入していないかを確認するためだ。

```powershell
cd $env:USERPROFILE\Documents\Hermes-Vault

git status                                                # 増えたファイルを目で見る
git add raw/transcripts/                                  # raw/transcripts/配下だけstage(commit候補に登録)
git commit -m "transcripts: sync $(Get-Date -Format 'yyyy-MM-dd')"
git push
```

:::message
**stage(staged)って何**

`git add`を実行すると、ファイルが「stage(=次のcommit候補)」に登録された状態になる。実際の保存(commit)前の中間状態だ。`git status`で「Changes to be committed」と表示されているのがstaged状態のファイルになる。
:::

![PowerShellで`git add raw/transcripts/`の後に`git status`を実行した画面。Codex側のnew fileリストが緑字で並ぶ。staged 3490件のうち末尾の数十行が画面に収まる](/images/hermes-vps/hermes-vps-15-git-status-staged.png)

pushが通ればGitHubに変更が届いた=VPS側で`git pull`すれば受け取れる状態だ。

![PowerShellで`git push`を実行した直後の画面。Enumerating objects/Writing objects/Totalの行が並びリモート反映が完了している](/images/hermes-vps/hermes-vps-15-git-push-success.png)

:::message
**初回push時のサイズ感と「LF/CRLF」黄色警告について**

実機では3490ファイル(git内部の管理単位ではツリー情報を含み3496カウントになる)・約19MiBの初回pushが数十秒で終わった。2回目以降は差分(=前回からの変更分)だけpushされるので、毎回数件・数KBの軽い転送になる。

`git commit`時に`LF will be replaced by CRLF`という黄色の警告が大量に流れることがある。これはWindowsとLinuxで改行コードが違うために出る注意書きで、動作に影響はない。気になる場合の抑制方法は§9-1の早見表に書いた。
:::

### step6=VPSでgit pull→rsyncでHermesが見るVaultに同期

第13回で設計したように、母艦からpushしてもVPS側で`git pull`しただけではHermesから見えない。理由は、母艦と同期するgit用フォルダ(`~/hermes-vault-repo`)と、Hermesが実際に読みに行くフォルダ(`~/hermes-vault`)を別々にしているからだ。

本回ではこの2つを橋渡しする1コマンド(rsync)を手動で叩く。

:::message
**rsyncって何**

rsyncはLinuxで「ファイルを差分だけ高速にコピー」するツールだ。第8回で母艦↔VPSの設定同期に使ったのと同じ道具を、ここではVPS内のフォルダ間コピーに使う。何度叩いても安全(=同じ結果になる性質を「べき等」と呼ぶ。途中で止まっても再実行で安全に復旧できる)。
:::

```bash
# VPS側で(母艦からgit pushした後・1回だけ)
cd ~
git -C ~/hermes-vault-repo pull origin main          # 母艦pushを受け取る
rsync -a --include='raw/' --include='raw/transcripts/' \
  --include='raw/transcripts/**' --exclude='*' \
  ~/hermes-vault-repo/ ~/hermes-vault/                # raw/transcripts/配下のmdだけコピー
ls ~/hermes-vault/raw/transcripts/claude-code/*.md | wc -l   # 件数確認
ls ~/hermes-vault/raw/transcripts/codex/*.md | wc -l         # 件数確認
```

`rsync`のfilter(`--include`/`--exclude`)は`raw/transcripts/`配下のmdだけを母艦側から持っていく設定にしている。これでVaultのトップに置かれたHermes作成ノート(第13回でHermesに書かせた`Hermes動作テスト.md`等)はrsyncの同期対象に入らない=触られない。

最後の`wc -l`(行数=ファイル数)が母艦push件数と一致すれば同期成功だ。

![VPS sshで4コマンドを実行した結果が1画面に収まる。`git pull`は`Already up to date.`、`rsync`は出力なし(=同期済・べき等)、`wc -l`の結果がClaude側とCodex側でそれぞれ件数表示される](/images/hermes-vps/hermes-vps-15-vps-rsync-sync.png)

rsyncは何度叩いても安全だ。2回目以降は差分だけ転送されるので一瞬で終わる。

:::message
**なぜ今これを自動化しないか**

「git pullしたら即Hermes-Vaultにrsync」を毎晩自動で動かすのは簡単に見える。ただ、自動化するには3つの判断を先に決めておく必要がある。

- 毎晩自動で動かすか(=cronと呼ばれる定期実行の仕組みに乗せるか)
- Hermesが書いたメモも母艦に戻すか(=双方向同期)
- 母艦とHermesが同時に同じファイルを編集した時の優先順位

この3つは「自動保守」のテーマで、第19回予定のCurator(自動保守役)の回でまとめて扱う。本回は手動1コマンドで動作確認まで進めて、自動化は次回以降でやる。
:::

### 6補足. スクリプトの中身は読まなくていい・3つだけ知っておけば十分

冒頭に書いた3点をもう少し詳しく書く。長期運用で気になる読者向けで、読まずに飛ばしても構わない。

1. **LLM呼び出しゼロ**=スクリプトはPowerShell組み込みの`ConvertFrom-Json`と文字列処理とファイルIOだけで動く。OpenAI/Claude APIは1回も叩かない=毎晩動かしても料金がかからない+挙動が予測可能だ
2. **jsonl直接読み(ノイズ除去)**=Claude Code/Codexのjsonlは`tool_use`/`thinking`/`progress`等のメタ情報が全体の80〜90%を占める。スクリプトはuser/assistantの本文ターンだけを抜き出してmd化する=Vaultが肥大化しにくい
3. **1ファイル12万文字上限(肥大化防止)**=1セッションが極端に長いと変換mdも巨大になる。スクリプトは最大12万文字で切り詰めて末尾に省略マーカーを残す。日本語中心のセッションでも本文は400KB弱に収まり、Obsidianが重くならない+Hermesが読む時のtoken(LLMが入力を処理する単位)消費も抑えられる

もっと賢い仕組み(セッション要約・自動カテゴリ化・セカンドブレイン化)は本回ではやらない。次の第16回でHermes純正のllm-wiki skill(第10回で触れたskill機能のひとつ・Karpathy LLM Wikiパターンを実装したもの)が担う。本回は「読める形にしてVaultに貯める」までで止めて、整理は第16回でやる。

## HermesからVault越しに過去のAI履歴を引く

本回核心の動作確認だ。Telegramに英字技術用語抜きの普段の日本語1行を投げて、Hermesが母艦のClaude Codeで先週デバッグした件をVaultから引いて構造化して答える。

さらに続けて意見を求めれば、過去会話を踏まえてHermesが自分の判断を述べる。母艦のClaude Code・Codexに加えて、Hermesが3つ目の椅子を引いて議論の卓に座る形になる。

§6で母艦からgit pushして、VPSでgit pullして、最後にrsyncで`~/hermes-vault/raw/transcripts/`(母艦の会話ログを保管する書庫の中の「生ログ」フォルダ)まで運び込んだ。第13回§11で建てたとおり、`~/hermes-vault-repo`(git同期側)と`~/hermes-vault`(Hermesコンテナがマウント側)は別管理だ。だから母艦→VPSの同期だけでは足りず、最後にrsyncで運ぶ手動の一手が要る。この手動rsyncを毎晩自動で回すのは第19回予定のCurator(自動保守)回で扱う。本回はそこまで来た時点で、配下に母艦のClaude Code 1272件+Codex 2218件=計3490件のmd(マークダウン、Hermesが読みやすい平文形式)が並んでいる。

`--resume`(過去セッションを遡るClaude Codeのオプション)で1件ずつ開き直すのが面倒で「またあとで」と放置していた件を、Telegram1行で済ませる。これがやりたかった形だ。

### 普段の日本語で頼んでみる

題材は2026-06-29にClaude Codeで動かしたwinsmuxのPlaywright e2e(ブラウザ操作を自動で再現するテスト)。control pipeのトークン取得に失敗するエラーが出て、その日のうちにClaude Codeと長いやり取りをした件だ。普通なら「Claude Codeを立ち上げて`--resume`で先週分のセッションを遡って...」となるところを、Telegramでこう投げる。

```text
(soraからHermesへ)
昨日winsmuxで何か困ってなかった?
```

依頼文に英字技術用語が一切無い。「Claude Code」も「Playwright」も「transcript」も書いていない。「昨日」「winsmux」「何か困ってなかった?」の3語だけ。普段のチャットそのままだ。

なお、最初に試したときはHermesの内部検索(findやgrepというLinuxの検索ツール)が30回以上空回りして、応答まで時間がかかった。そこで第13回で作ったObsidian skillの`SKILL.md`に日付推測の手順を1ブロック追記してから撮影している。詳細は本節末尾に書く。

Hermesの応答(Telegramに届いたmarkdown整形済みメッセージをそのまま転記)はこう返ってきた。

> Vaultの2026-06-29 transcriptから確認したところ、winsmux関連で以下3つの問題に取り組んでいた:
>
> **1. control pipeのトークン取得エラー**
> e2e起動スクリプト実行時にトークンファイルが読めず、フォールバックの環境変数も設定されていないため接続失敗。
>
> **2. 起動前点検スクリプトのブロック**
> ウィンドウ側の起動経路が落ちて、harness-check(起動前点検)とorchestra-smoke(疎通確認)が止まる。
>
> **3. operator→worker間のdispatch失敗**
> 関連issueで議論中。dispatchルーティングの根本対応が未完。
>
> トークン、ウィンドウattach、dispatchのどこから深掘る?

![soraがTelegramに「昨日winsmuxで何か困ってなかった?」と日本語1行で送信。Hermesが「Vaultの2026-06-29 transcriptから確認」と引用元を最初に示した上で、3つの問題を箇条書きで構造化して返している応答画面。bot名・表示名・chat IDはマスク済み、winsmuxキーワードはsoraの公開OSSなのでマスクなし](/images/hermes-vps/hermes-vps-15-telegram-recall-claude.png)

ここで起きていることを分解する。Hermesはまず「昨日」をシステム日付から「2026-06-29」と解決した。次に「winsmux」をキーワードに`raw/transcripts/`配下のmdから該当ファイルを引き当てた。続いてuserとassistantの会話ターンを読み込み、最後に3つの問題を抽出して構造化した。

応答冒頭で「Vaultの2026-06-29 transcriptから確認」と引用元を明示しているので、どのmdから引いたかも分かる。

引用された「control pipeのトークン取得エラー」「dispatchルーティング」等は本回撮影の元になった実transcriptに含まれる内容だ。jsonl(JSON Lines、Claude Code/Codexが会話を1行1JSONで保存する形式)をmdに変換してVaultに置いただけで、Hermesから読めるようになっている。

### 続きを相談する=Hermesが3エージェント目になる

過去会話を引いて答えられるだけなら、ただの検索ボットだ。本回の真の価値は次の質問にある。

```text
(soraからHermesへ)
さっき思い出してくれたwinsmuxの認証トークン問題、
次のリリースで取り組むべき優先順位はどう整理する?
君の意見を聞きたい。
```

「君の意見を聞きたい」と明示的に頼んでいる。Hermesに「過去会話の検索結果を述べる」のではなく「自分の判断で次の一手を提案する」役割を与えている。応答はこう返ってきた。

> **次のリリースで取り組むべき優先順位**(私の意見)
>
> **P0**(最優先・今回エラーの直接原因)
> control pipeのトークン経路の確実性確保。トークンファイル生成→読み取り→環境変数フォールバックの3経路をテストで縛る。これが解消しない限りe2eが安定しない。
>
> **P1**(根本対応・関連issueの核心)
> ウィンドウattach経路の根本対応。起動が落ちる経路の代替パスを実装する。P0のテストが通ってからでないと検証ノイズが乗る。
>
> **P2**(運用改善・将来の自分を救う)
> エラーメッセージの明確化+起動前preflight(事前確認)の追加。次に同じ罠を踏んだとき、原因特定までの時間を短縮する。

![soraがTelegramに「次のリリースで取り組むべき優先順位はどう整理する?君の意見を聞きたい」と送信。Hermesが「(私の意見)」と明示してP0/P1/P2の3階層で構造化して返している応答画面。各階層に「今回エラーの直接原因」「関連issueの核心」「将来の自分を救う」と判断の根拠が併記されている。bot名・表示名・chat IDはマスク済み、winsmuxキーワードはマスクなし](/images/hermes-vps/hermes-vps-15-telegram-next-step.png)

応答冒頭で「私の意見」と書いてくる。これがポイントだ。Hermesは過去Claude Code会話を「引用」しただけでなく、その中身を踏まえて自分の判断としてP0/P1/P2を提示している。各階層に「今回エラーの直接原因」「核心」「将来の自分を救う」と理由を併記してくる。検索ボットでは返せない応答だ。

ここに来てやっと、第13回で建てたVault・第14回で雇った司書・本回で並べた他AIの作業履歴が3つ揃って一つの体験になる。母艦のClaude Codeで詰まった件をClaude Codeに聞き直すのではなく、Hermesに振って違う角度の意見をもらう。**自分一人と2つのAI(Claude CodeとCodex)だった作業卓に、Hermesが3つ目の椅子を引いて座る**。アラフィフの現場監督上がりとしては、こういう「相談相手が一人増える」感覚は実務的にありがたい。新人に聞いて、ベテランに聞いて、最後に第三者の親方に意見を求めるのと同じ動線が、家のVPSの中で成立する。

:::message alert
**ここを誤解しやすい**: Hermesは過去Claude Code会話のテキストをそのままコピーで返しているのではなく、読んで踏まえて自分の判断を述べている。だからP0/P1/P2の3階層分けはClaude Codeが言った内容ではなく、Hermesがmdを読んで考えた結論だ(引用元のtranscript md内には優先順位の階層分けが含まれていない)。同じ題材で別のAIに聞けば、当然別の優先順位が返ってくる。それでいい。過去会話を共通言語にして、複数AIが別々の角度から意見を出すのが本回ゴールの形だ。
:::

### Hermesの初動を効率化する一手(SKILL.md v2)

ここで一つ運用上の補足を挟んでおく。前述のとおり、最初に試したときはHermesが応答するまでに内部検索が30回以上空回りした。`find`で全ディレクトリを舐め、`grep`を連発し、ようやく該当mdに辿り着く。読み手に見えるのは「考え中...」が延々続く時間だ。

これを減らすため、第13回で作ったObsidian skillの`SKILL.md`に「自然言語の日付推測ロジック」を1ブロック追記した(skill自体は第13回で既にHermesに繋がっている)。中身を要約すると以下3点だけだ。

- 「昨日」「先週」のような相対日付は、応答時のシステム日付から先に解決してから検索する
- `raw/transcripts/`配下は日付プレフィクス(`YYYY-MM-DD_xxxxxxxx.md`)で並んでいるので、ファイル名で先に絞り込む
- 該当mdが見つかったら全文読み込みは1回で済ませる(同じmdを再読しない)

追記後、同じ依頼を再試行したら内部のtool call(エージェントが裏で叩く操作の回数)が片手で収まる回数まで減り、即時応答に近づいた。`SKILL.md`は第10回で扱った仕組みそのものだ。Vault越しに過去履歴を引く運用を始めた後で、必要に応じて足せばいい。詳細は§9-1早見表に1行載せておく。

### 第14回完了時点との比較

本回の到達点を表で押さえておく。質問例は「先週Claude Codeで作業したデバッグの件、何だっけ」を共通の題材とする。

| 観点 | 第14回完了時点 | 本回完了時点 |
|---|---|---|
| Hermesの応答 | 「私とのやり取りには見当たらない」 | Vault配下の`raw/transcripts/`を引いて構造化して答える |
| 追加相談 | 過去会話を持たないので相談にならない | P0/P1/P2で意見を述べる=3エージェント目として議論に参加 |
| 追加作業 | Claude Codeを開いて`--resume`で遡る | Telegramで1行投げるだけ |

書庫(Vault)に他のAIで書いたノートが並び、司書(Session Search)が背後で動き、Hermes本人が自分の判断を述べる。第13回・第14回・本回の3回で積み上げた仕組みが、Telegramの1行で繋がる。次の第16回予定では、貯まったノート群を別の道具(llm-wiki)で読み込み直して、相互リンクされた索引に再編集する。本回はその直前まで来た。

## 第16回への接続と長期運用

本回で母艦からVaultに取り込んだ作業履歴は、ここで終わりではない。`raw/transcripts/`という名前のとおり、これは「生データ」だ。読める形に整えたノートの束が、書庫の棚に並んだ状態でしかない。次の第16回でHermes純正の**llm-wiki**(エルエムウィキ)skillが、この束を読んでセカンドブレイン(第二の脳)として整える。本回はその前段=「読める形にして貯める」までを担う。

### 8-1. 本回の出力は、次回llm-wikiの入力にできる

第15回で母艦の変換スクリプトが作る`raw/transcripts/<agent>/*.md`は、第16回で扱うllm-wiki skillに**入力ソースとして渡す構成にできる**。

llm-wikiは、ある著名なAI研究者(Andrej Karpathy。ChatGPTの基礎研究で知られる元OpenAI/Tesla AIの研究者)が提案した**LLM Wikiパターン**をHermesに移植したskillだ。LLM Wikiパターンとは、AIとの対話を「人物」「概念」「比較」「よくある問い」のような項目別カードに分解し、カード同士をリンクでつなぐ知識整理法のこと。Hermes版のllm-wikiは、Vaultの中を**entities**(調べた相手や道具)・**concepts**(抽出した概念や設計判断)・**comparisons**(比較)・**queries**(自分の問い)の4種類のノートで相互リンクして束ねる。

ここで先に「raw層」という言葉を1行で定義しておく。llm-wikiは、Vaultの中を**raw層**(生データを貯める場所)と**KB層**(知識ベース層。整理済み知識を置く場所)の2階建てとして扱う。本回で作る`raw/transcripts/`は、名前のとおりraw層に該当する。

そのため、第16回でllm-wikiを設定するときは、llm-wikiが読むVaultを第13回で建てたVaultと同じディレクトリに向ける。そうすれば本回の`raw/transcripts/`がそのままllm-wikiの取り込み対象になる。**本回で貯める→第16回でセカンドブレイン化**の2段構成だ。設定の具体は第16回で扱う。

本回で出てくるパスと用語の対応は次のとおり。

| 用語 | 中身 | 場所 |
|---|---|---|
| Vault | Hermesの知識倉庫(第13回で構築) | `~/Documents/Hermes-Vault` |
| `WIKI_PATH` | llm-wikiが読む場所を指す環境変数 | 上のVaultと同じ場所を指す |
| `raw/transcripts/` | 本回で貯めるmd(他のAIの作業履歴) | Vaultの中 |

:::message
**比喩の地図(第13〜16回)**

- 第13回──書庫を建てる
- 第14回──司書を雇う
- 第15回(本回)──他のAIで書いたノートを清書して棚に並べる
- 第16回──司書がノートを読んでセカンドブレイン(第二の脳)を作る

比喩は連続している。本回で書庫の在庫が増え、次の回でそれが索引化される。
:::

### 8-2. Vault容量を見る──本回完了時点の参照値

「毎日変換スクリプトを叩いてmdを増やし続けて、VPSの容量は大丈夫か?」という不安は当然出る。正直、最初は自分も「md溜め放題でVPSが逼迫するのでは」と身構えた。実測したら拍子抜けだった。結論から書くと、**作業履歴のmdはほとんど容量を食わない**。本回完了直後の実測をVPS側で見ておく。

```bash
du -sh ~/hermes-vault/raw/transcripts/
du -sh ~/hermes-vault/raw/transcripts/claude-code/
du -sh ~/hermes-vault/raw/transcripts/codex/
```

![撮影13:VPS sshで`du -sh`を3回叩いた出力。`~/hermes-vault/raw/transcripts/`合計が65MB、`claude-code/`が35MB、`codex/`が31MB。sshプロンプトのホスト名はマスク済み。サイズ数値はマスクなし。duコマンドはサイズしか出さないため、件数はスクショには写っていない(件数は別途wcで取得した値)。](/images/hermes-vps/hermes-vps-15-du-sh-vault.png)

撮影時点の実測は**claude-code側35MB**+**codex側31MB**=合計**約65MB**。別途`find ~/hermes-vault/raw/transcripts/claude-code -name '*.md' | wc -l`で数えると、Claude Code 1272件・Codex 2218件で合計3490件だった。母艦で日常的にClaude CodeとCodexを使ってきた結果、本回時点で3490件・65MB前後で収まっている。

この理由は単純で、**§6-1で書いた変換スクリプトが、`tool_use`(AIが道具を使った記録)・`thinking`(AIの内部思考)・`progress`(処理の進捗ログ)などのメタ情報を全部捨てて、`user`(あなたの発言)と`assistant`(AIの返答)の本文ターンだけ抜き出している**ためだ。Claude CodeやCodexの生jsonlを直接置くと相当大きくなるが、本文以外を捨てる効果で容量がかなり小さくなる。

この増加ペースから見ても、半年運用しても数百MB程度で収まる見込みだ。第1回で借りたVPSの容量(40GB前後)に対しては余裕がある。

### 8-3. 長期運用で気になる3点と、本回での扱い

半年〜1年と運用が続くと、次の3点が気になり始める。

| 気になる点 | 本回での扱い | 解決の出口 |
|---|---|---|
| 古いtranscriptsを月単位でアーカイブしたい | 本回はやらない(手動でフォルダ移動すれば足りる) | 連載後半の自動保守回 |
| 母艦の変換+pushを毎晩自動化したい | 本回は手動で1日1回叩く前提 | 連載後半の自動保守回 |
| 母艦↔VPS↔Hermesが書いたノートの双方向同期 | 本回は片方向(母艦→VPS→Hermes Vault)のみ | 連載後半の自動保守回 |

3点とも「自動保守」というテーマでひとまとめにできる=連載後半の自動保守回で一気に解決する設計にした。本回は**手動1コマンドで動作確認まで**で止めて、自動化は連載後半に委ねる。「全部自動」を最初から目指すと設定項目が増えて挫折するので、まずは「Hermesから他のAIの作業履歴を引ける」状態を最小手数で完成させる方を優先した。なお双方向同期では、古い記録の整理(prune=刈り取り)や衝突解決も同じ回でまとめて扱う予定だ。

:::message
**4層が揃った**

第15回完了時点で、Hermesが参照できる記憶は4種類に整理された。

- **Memory**(第12回)──私のこと(名前・家族・好み・前提)
- **Vault knowledge/**(第13回)──世界のこと(調べた記事・自分のメモ)
- **state.db**(第14回)──自分の会話(Hermesと交わした過去)
- **raw/transcripts/**(本回)──他のAIで書いたノート(Claude Code/Codexの作業履歴)

これらの層を第16回以降でどう使い、どう整えていくかは順次扱う。連載の構成は調整中のため、第19回などの数字は最新の目次で確認してほしい。
:::

## まとめと第16回予告

第15回完了で、Hermesは「他のAIで書いたノート」も同じ書庫から引けるようになった。ノートの中身は、母艦のClaude CodeとCodexの作業履歴だ。第14回のsession_search(自分との会話履歴を司書が探してくれる仕組み)と並んで、第IV部で予告した4層メモリがここで出揃った。

これで第IV部の4階層「付箋・書庫・司書・他AIのノート」が揃った。Hermesは下の表のどこから引いた知識かを意識せず、自然に混ぜて返してくる。

| 層 | 中身 | 取り込み元 |
|---|---|---|
| 📝 付箋(Memory) | 名前・家族・好み・前提 | USER.md / MEMORY.md(第12回) |
| 📚 書庫(Vault knowledge) | 長く残しておきたい調査・自分のメモ | `~/hermes-vault/`(Hermesが読む書庫)に手で書き込む(第13回) |
| 🧑‍🏫 司書(state.db) | Hermes自身の過去会話 | `session_search`が自動発火(第14回) |
| 📬 他AIのノート(raw/transcripts/) | Claude Code・Codexの作業履歴 | 母艦の変換スクリプト+git+rsync(本回) |

4つとも置き場所と取り込み元が違う。Hermesは聞かれた内容に応じて適切な層から引いてくる。司書(session_search)が見ているのは`state.db`の棚で、本回で並べたノートの棚はファイル読み取り経路で開く別の引き出しだ。同じ書庫の中の、隣の棚と思えばいい。

ここまでで分かったのは、Hermesに「自分の会話」だけでなく「他のAIで書いたノート」まで持ち込めるようになったことだ。朝、別件のSlackを見ていて「あれ先週同じことやらなかったか」と引っかかった瞬間に、Telegramで「先週のwinsmuxの件を見て」と打てばHermesが`raw/transcripts/`配下のノートを開いてくれる。アラフィフになると昨日の自分が何で唸ってたか覚えていないので、向こうが覚えていてくれるのはありがたい。本回§7-2で見たように、Hermesは引いてきたノートを踏まえて**P0(今すぐ着手)/P1(今週中)/P2(来週以降)の優先順位提案**まで返してきた。過去の作業履歴をその場で読んで、提案まで返してくれる。検索結果のリンクを並べるだけのチャットでは出てこない応答だ。

次の第16回(予定)は、貯めたノートをHermesが「索引付きの百科事典=セカンドブレイン(第二の脳)」に作り変える話だ。元ネタはAndrej Karpathy氏(OpenAI共同創業者・AI教育で著名)が公開したllm-wikiパターンで、Hermesにbundledされているskillとして取り込まれている。書庫に貯めるだけで終わらせず、司書が読んで自分の頭の地図にしていく段階だ。連載の回数は変わる可能性があるので、着手時に最新の計画書を確認する。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第14回](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) 毎回最初から話すな。Hermes Agentは前回の続きからそのまま動く | 第16回(近日公開):記憶を自分で残すな。Hermes Agentは会話とメモを自動で繋ぐ。 |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## よくあるエラーと対処

| 症状 | 原因 | 対処 |
|---|---|---|
| `.\sync-ai-transcripts.ps1`と直叩きすると赤字で「このシステムではスクリプトの実行が無効になっているため」 | PowerShellの実行ポリシーが`Restricted`(初期値で全スクリプト実行禁止) | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File <スクリプトパス>`で起動する形に統一する。`Set-ExecutionPolicy`でシステム設定を緩めない |
| 変換後のmd本文が文字化けする | UTF-8 BOMなし(ファイル先頭のバイト順マークなしのUTF-8)で書き出していない(cp932は日本語Windowsの既定文字コード) | `Out-File -Encoding utf8NoBOM`を使う。※`utf8NoBOM`はPowerShell 6以降の機能。Windows標準のPowerShell 5.1で使う場合は`[System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))`形式を使う |
| 同じセッションのmdが日付違いで複数できる | ファイル名の日付にjsonl(1行1JSON・会話履歴の保存形式)の`LastWriteTime`(ファイルの最終更新日時)を使ってしまった。深夜0時をまたいで会話を続けると別ファイルに分かれる | 本回§6-1のスクリプトどおり、日付はjsonl内**最初のセッション開始時刻**から取る。重複が出たら`raw/transcripts/<agent>/`を空にして再実行 |
| `git push`後にVPS側で`git pull`しても変化なし | VPS側のclone元と母艦のpush先が違うリポを指している | VPS側`git remote -v`と母艦側`git remote -v`を見比べて同じremote URLか確認。第13回設定が今も生きているか再確認 |
| Hermesから「該当する会話が見当たらない」と返る | Vault配下に該当mdが無い・git pullが届いていない・第13回Vault接続が切れている | 順番に確認する。(1)VPS側で`ls ~/hermes-vault/raw/transcripts/<agent>/`を実行 → (2)ファイルが無ければ`git pull`+rsync → (3)あれば第13回§7のVault接続確認手順に戻る |
| 変換mdにAPIキーやトークンが混入していた | Claude Code/Codexの作業中に秘密情報をpasteしていた | 本回では深追いせず、`git push`する前に該当mdを目視して問題があれば手で削除。秘密情報の自動マスクは連載後半のCurator(自動保守の回・予定)で扱う |
| 古いjsonlが大量にあって初回実行が遅い | 初回は全件処理 | 初回だけ時間がかかるのは正常。本回実機は3490件で数分程度(母艦のスペックとjsonl総量で変動)。2回目以降は既存スキップで一瞬 |
| `git commit`時に`warning: in the working copy of 'raw/transcripts/...', LF will be replaced by CRLF`が大量に出る | Windows gitの改行コード自動変換の警告。動作には無害だが大量に流れて見づらい | 抑制したければVault直下に`.gitattributes`を作って`raw/transcripts/** text eol=lf`を1行入れる(LF=Unix系の改行で固定する明示)。何もしなくてもcommit/pushは成功する |
| `git commit`時に`ERROR: Potential secret detected in raw/transcripts/...`でブロックされる | 変換md内に取り込まれたClaude Code/Codexセッション本文に`password=<value>`/`api_key=<value>`形式の文字列(右辺が一定の長さを超える値)が含まれていた場合、母艦のglobal pre-commit hook(全リポ共通でcommit前に走るチェックスクリプト・git-guard等)が秘密と誤検知する | **(注意:このVaultリポがプライベートであることが前提。public化するならhookを絶対に切らない。)** プライベートを確認したうえで、このVaultリポだけhook継承(母艦の他リポで設定したcommit前チェックがこのリポにも自動で効く仕組み)を切る。手順:(1)`mkdir .git/hooks-empty` (2)`git config --local core.hooksPath .git/hooks-empty`。他リポは影響なし |

:::message alert
**秘密情報の取り扱い**: 変換mdの中身はClaude CodeやCodexで自分が打ち込んだ作業ログそのものだ。APIキーやトークンを手で貼り付けて作業した履歴があれば、md内にも残る。`git push`する前にmdの目視確認は必須。Vaultリポはprivateで運用し、publicへの切り替えは行わない。
:::

## 操作早見表

母艦のPowerShellで叩くものと、VPSのsshで叩くものを分けた。基本は母艦で変換+pushして、VPSでpull+rsyncする2段構成だ。コード内の`#`から始まる行は説明用コメントなので、コピペして実行する場合は飛ばしてよい(コメントの文字化けが起きてもコマンド本体は動く)。

まず母艦でノートの置き場を確認する。

```powershell
# [母艦Windows PowerShell] 会話履歴の置き場を覗く(任意・場所確認用)
ls $env:USERPROFILE\.claude\projects | Select-Object -First 12
ls $env:USERPROFILE\.codex\sessions\2026\06 | Select-Object -First 10
```

次に変換スクリプトの置き場を作る(初回のみ)。

```powershell
# [母艦Windows PowerShell] スクリプトの置き場を作る(初回のみ)
New-Item -ItemType Directory -Path $env:USERPROFILE\bin -Force
# (本文§6-1のスクリプトを bin\sync-ai-transcripts.ps1 に保存)
```

ここまで済めば、以後はこの3コマンドが日次の手順になる。

```powershell
# [母艦Windows PowerShell] 母艦でノートを変換してgitに乗せる
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File $env:USERPROFILE\bin\sync-ai-transcripts.ps1
cd $env:USERPROFILE\Documents\Hermes-Vault
git add raw/transcripts/
git commit -m "transcripts: sync $(Get-Date -Format 'yyyy-MM-dd')"
git push
```

VPS側は受け取って書庫に並べる。

```bash
# [VPS ssh] VPSがノートを受け取って書庫に並べる(第13回§11の設計=git repoとHermesが見るVaultは別管理)
git -C ~/hermes-vault-repo pull origin main
rsync -a \
  --include='raw/' \
  --include='raw/transcripts/' \
  --include='raw/transcripts/**' \
  --exclude='*' \
  ~/hermes-vault-repo/ ~/hermes-vault/

# [VPS ssh] 件数確認
ls ~/hermes-vault/raw/transcripts/{claude-code,codex}/*.md | wc -l

# [VPS ssh] 容量確認(半年運用後の見直し用)
du -sh ~/hermes-vault/raw/transcripts/
```

:::message
**rsync(ファイルやフォルダを差分だけコピーするコマンド)の`--include`+`--exclude`の意味**:`~/hermes-vault-repo/`(git管理側)から`~/hermes-vault/`(Hermesコンテナがマウントする側)へ、**`raw/transcripts/`配下だけ**を写す指定だ。第13回§11で「両者は別管理・統合は連載後半」と置いた橋渡しを、本回はこの1コマンドで最小限に繋いだ。安全の根拠は二段構えになっている。(1)`--delete`フラグを付けていないので、source側に無いファイルがdest側で消えることはない。(2)`--include`+`--exclude='*'`でsourceの`shared-ai/`配下(Hermesが書いた側のメモ)は同期対象から外れる。これでHermesが書いたメモは保護される(=安全)。何度叩いても`raw/transcripts/`の中身は同じ結果になる(コピー処理としてべき等)。本格的な双方向自動化は連載後半のCurator+cronの回(予定)で扱う。

※読者が将来この手順をいじって`--delete`を足すと、dest側で`raw/transcripts/`以外が消える危険がある。最初の形のまま使うこと。
:::

母艦の変換+pushの自動化は別記事で扱う。Windowsタスクスケジューラで毎日決まった時刻に走らせたい読者向けの番外編は、本回公開後に独立記事として出す予定だ。母艦を毎日起動する読者なら、本回§6を手動で叩く運用で十分。Mac/Linux/WSLで読者環境を組む場合は、本文のPowerShell部分を`bash`に置換すれば同じ流れで動く(`$env:USERPROFILE`→`$HOME`、`ls`はそのまま、`powershell.exe ...`→`pwsh ~/bin/sync-ai-transcripts.ps1`または`bash`版に書き直す)。

## 引用元と参考

| 項目 | 引用元 |
|---|---|
| Claude Code memory + transcriptsの配置 | [Claude Code memory(docs)](https://docs.claude.com/en/docs/claude-code/memory) |
| Codexのセッション保存場所(rollout/history・Desktop AppとCLIで共有) | [openai/codex(GitHub README)](https://github.com/openai/codex) + 2026-06-26母艦実機(Codex 0.142.0)で確認 |
| 次回(llm-wiki)で使う公式パターン(Karpathy LLM Wikiパターン) | [karpathy/llm-wiki gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)(Hermes純正llm-wiki skillの設計起点) |
| 第13回で構築したVault git同期(本回§6-5・§6-6の前提) | [第13回](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) メモを自分で探すな。Hermes AgentはObsidianを記憶として読む |
| 第14回のsession_search(同じ司書比喩・本回の隣の引き出し) | [第14回](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) 毎回最初から話すな。Hermes Agentは前回の続きからそのまま動く |
| 第9回Hermes Cron(本回の任意自動化=別記事側で再利用) | [第9回](https://zenn.dev/sora_biz/articles/hermes-vps-09-cron) いつもの作業を毎回自分でやるな。Hermes Agentが決めた時刻や間隔で自動でこなす |

※連載の回数は変わる可能性がある。次回(llm-wiki)・連載後半のCurator+cronの回番号は、着手時に最新の計画書を確認する。

Claude Code/Codexのjsonl構造(`type`フィールド・1行1JSON形式)は2026-06-26に母艦実機(Windows・Claude Code・Codex 0.142.0)で確認した。Hermes純正llm-wiki skillがVPS実機v0.17.0にbundled(`skills/research/llm-wiki/`・v2.1.0)されていることも2026-06-27に確認済(次回で使用)。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第14回](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) 毎回最初から話すな。Hermes Agentは前回の続きからそのまま動く | 第16回(近日公開):記憶を自分で残すな。Hermes Agentは会話とメモを自動で繋ぐ。 |

📑 [シリーズ全12回のもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

:::message
この連載はSubstack「そらのAIエージェント通信」で先行公開している。無料[登録](https://sorabiz.substack.com/subscribe)すると最新回がメールに届く。[Zennでフォロー](https://zenn.dev/sora_biz)すると新着通知が届き、全体像は[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::
