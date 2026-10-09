---
title: "【第18回】使ったスキルを古いままにするな。Hermes Agentは自分でSKILL.mdを書き直す。"
emoji: "🛠️"
type: "tech"
topics: ["hermes", "ai", "llm", "claudecode", "個人開発"]
published: false
---

:::message
**この記事をAIに読ませる**

この記事はGitHubの公開リポジトリで管理していて、本文のMarkdownをそのまま取得できる。Claude CodeやCodexなどのAIエージェントに手順を任せたいときは、次のURLを渡すだけでいい。

https://raw.githubusercontent.com/Sora-bluesky/zenn-articles/main/articles/hermes-vps-18-skill-rewrite.md

頼み方の例:「この記事を読んで、私の環境で手順を順番に実行して」に上のURLを添える。
:::

:::message
この連載は月1,800円ほどのVPSで、自分専用のAIエージェント(Hermes Agent)を24時間動かす実録だ。これはその第18回。全体の流れは[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
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
- [第7回](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop) Hermes AgentがMicrosoft Storeに来た。Windowsアプリで入れてVPSにつなぐ（旧版からの入れ替えも）
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
- [第17回](https://zenn.dev/sora_biz/articles/hermes-vps-17-soul) 口調をブレさせるな。Hermes Agentの話し方は実は変えられる
- **第18回**(本記事) 使ったスキルを古いままにするな。Hermes Agentは自分でSKILL.mdを書き直す。

全体像は[Hermes Agent完全構築ガイド](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にある。
:::

## 導入:6月17日から書き換えていないスキルが、毎朝の配信に使われている

毎朝7時のニュース配信(第9回のcron、ジョブ名morning-news)が読むスキルは、2026年6月17日から一度も書き換えていなかった。そのあいだに、cronの使い方は変わっている。10月7日に、前回の出力を見せて「すでに伝えたことは繰り返さない」と指示する設定(continuity、第9回)を付けた。スキルの手順には、そのことが書かれていなかった。

Hermesに書き直しを頼むと、2026年10月8日20:05の依頼から3分後の20:08には、スキルが新しい版(v1.3.0)になっていた。変更はTelegramの返事で箇条書きで受け取り、台帳(書き換えの記録)で書き換えを確かめ、`diff`で差分を読んだ。書き直したスキルでの配信も1回動かした。書き換えを1件だけ戻す操作も、テスト用のスキルで試した。この回は、その手順だ。

この回でやらないのは、使わないスキルの片付け(Curator)だ。第19回で扱う。

確かめたのは、Hermes v0.21.5+8509(2026-10-08)をVPSで動かした範囲だ。

## この回の到達点

スキルを、いまの使い方に合わせてHermesに書き直させ、何が変わったかを台帳と`diff`で確かめ、1件だけ戻せる状態にする。配信は書き直したスキルで1回動かした。

第17回完了時点との差分を表にする。

| 項目 | 第17回完了時点 | 本回(第18回)完了時点 |
|---|---|---|
| morning-newsのスキル | 6月17日のまま(2,116バイト・version 1.2.0) | 10月8日に書き直した(4,513バイト・version 1.3.0) |
| 変更の記録 | morning-newsの記録は0件 | 台帳にpatchが4件残っている |
| 戻し方 | 試していない | `hermes curator rollback`で1件だけ戻せる |
| 次の回への橋渡し | 話し方が決まったHermes(第17回) | 使わないスキルの整理(第19回) |

この回で出てくる用語を先に押さえておく。

| 用語 | 意味 |
|---|---|
| スキル | `~/.hermes/skills/morning-news/SKILL.md`のような、手順を書いたファイル。第10回で扱った |
| patch | スキルの書き直し操作。置き換える部分だけを渡すと一部の置き換えになる |
| patchに全文を渡す | SKILL.mdを丸ごと置き換える書き方。editは旧名 |
| 台帳 | `~/.hermes/skills/.curator_ledger.jsonl`。書き換えるたびに、変更前と変更後が残る |
| continuity | cronが前回の出力を見せて、すでに伝えたことを繰り返させない設定(第9回) |

## スキルが古くなるとき

第10回で作ったmorning-newsのスキルは、第11回でnanoを使って手で全文を書き換えた。その後、2026年6月17日から書き換えていない。

スキルは、誰かが書き直さない限り、書いた時点の手順のままだ。そのあいだに、cronには前回の出力を引き継ぐ設定(continuity)を付けた。配信の使い方は変わったのに、スキルの手順は変わっていない。この状態を、次の節で画面に出して確かめる。

## 事前準備:バックアップと、いまの状態

自分のパソコン(この連載ではWindows)のターミナル(PowerShell)から、VPSにSSH(遠隔ログイン)で入る。以降のコマンドは、すべてVPSの中で打つ。

```bash
ssh admin@hermes-vps
```

書き直す前に、スキルのフォルダを丸ごとコピーしておく。`cp -r`はフォルダごと複製するコマンドで、末尾の日付は見分けるための目印だ。

```bash
cp -r ~/.hermes/skills/morning-news ~/morning-news.bak-20261008
```

いまの状態を確かめる。`ls -la`は更新日つきの一覧、`wc -c`はバイト数を数えるコマンドだ。

```bash
ls -la ~/.hermes/skills/morning-news/
wc -c ~/.hermes/skills/morning-news/SKILL.md
```

![VPSでls -laとwc -cを実行した画面。morning-newsフォルダのSKILL.mdが、更新日Jun 17、サイズ2116バイトと表示されている。同じフォルダにreferencesフォルダもある](/images/hermes-vps/hermes-vps-18-skill-before-ls.png)

SKILL.mdは2,116バイトで、更新日は6月17日だった。次のコマンドで、このスキルの書き換え記録を見る。

```bash
hermes curator ledger --skill morning-news
```

![VPSでhermes curator ledger --skill morning-newsを実行した画面。curator: ledger is empty (or skills.ledger is disabled). と表示されている](/images/hermes-vps/hermes-vps-18-ledger-empty.png)

画面には`curator: ledger is empty (or skills.ledger is disabled).`と出た。台帳そのものは2026年10月8日時点で322件あるが、morning-newsの記録は0件だった。書き直す前の基準にする。

## 書き直し方は2通り、変更は台帳に残る

スキルの書き直し方には、2通りある。

| 方法 | 動き |
|---|---|
| patch(一部だけ置き換える) | 置き換える前の文と後の文を渡す |
| patch に全文を渡す(丸ごと置き換える。editは旧名) | SKILL.mdの全文を渡す |

どちらで書くかは、Hermesが選ぶ。台帳には、丸ごとでも一部でもpatchと記録される。変更前後は、ハッシュ値(内容から計算した短い識別値)しか残らない。この回では、1回の依頼の中で、台帳にpatchが4件残った(4件とも20:08:29の同じ秒)。

書き換えるたびに、変更前と変更後が台帳に残る。台帳を見るコマンドと、1件だけ戻すコマンドは次のとおりだ。

| 目的 | コマンド |
|---|---|
| あるスキルの書き換え記録を見る | `hermes curator ledger --skill <名前>` |
| 1件だけ戻す | `hermes curator rollback <id>` |

書き込みの承認(`skills.write_approval`)は、既定でオフになっている。今回も、承認を求められずに書き換わった。

もう1つ、押さえておくことがある。会話のあとにHermesが自動でスキルを直す仕組みは、既定でオンだ。ただし、自動で直すのは、会話のあとの自動の見直しでHermesが自分から作ったスキルと、`hermes curator adopt <名前>`で任せたスキルだけだ。会話の中で頼んで作らせたスキルも、人が作ったスキルと同じく対象外になる。morning-newsは第10回で自分で作ったので、放っておいても自動では書き換わらない。そのため、この回は頼んで書き直させる。使わないスキルの片付けは第19回で扱う。

## Telegramで頼む

書き直しは、Telegramから頼む。先に`/new`を送って、新しい会話で始める(第17回と同じ理由で、前の会話の続きだと古い指示文が使われることがあるため)。

頼んだ文面は次のとおりだ。

```text
morning-news のスキルを、いまの使い方に合わせて書き直して。cron に continuity を付けたので、前回の配信と同じ話題を繰り返さないことを手順に入れて。直したら、どこを変えたかを箇条書きで教えて。
```

![Telegramの画面。20:05に上の依頼を送ると、スキルの読み込み、スケジュール一覧の確認、過去のセッション検索、skill_manageの実行が順に表示され、20:08にmorning-newsをv1.3.0に更新したという返事が届いている。変更点が6つの箇条書きで書かれている](/images/hermes-vps/hermes-vps-18-rewrite-telegram.png)

Hermesは、morning-newsをv1.3.0に更新したと答えた。cronの設定は変えておらず、既存の朝7時のジョブでcontinuityが有効になっているのを確認した、とも書いてあった。変更点は6つだった。

- 毎回continuityで渡される前回の配信内容を、先に確認する手順を追加した
- 表現や掲載媒体が違っても同じ話題なら、再掲しない
- 続報は、直近24時間に重要な新情報がある場合に限り、「続報」と明記する
- 新しい話題が5件に満たない日は、既出ニュースで埋めず、確認できた件数だけ載せる
- Web記事とX投稿が同じニュースなら、別項目に分けない
- 検証項目と注意点に、重複確認・続報の条件・取得件数の照合を追加した

返事に出てきた変更点を、次の節で実際のファイルと照らす。

## 変更を確かめる

### 台帳を見る

Hermesの報告だけで済ませず、台帳で確かめる。

```bash
hermes curator ledger --skill morning-news --limit 5
```

![VPSでhermes curator ledger --skill morning-news --limit 5を実行した画面。2分前のpatchが4件、すべてactorがagent、skillがmorning-newsで並んでいる](/images/hermes-vps/hermes-vps-18-ledger-after.png)

patchが4件、すべて実行者(actor)がagentで、スキルはmorning-newsだった。書き直す前は0件だったので、この4件が今回の依頼で増えた分になる。

### 差分を読む

次に、バックアップと書き直したあとのSKILL.mdを`diff`で比べる。`diff -u`は2つのファイルの違いを、消えた行(`-`)と増えた行(`+`)で表示するコマンドだ。

```bash
diff -u ~/morning-news.bak-20261008/SKILL.md ~/.hermes/skills/morning-news/SKILL.md
```

![diff -uの出力の前半。versionが1.2.0から1.3.0に変わっている。手順の1番目に「前回配信を確認する」、5番目に「continuityによる重複回避」が加わり、取得状況の書式にも「x_searchは呼んだが投稿未採用」と「取得件数」が加わっている](/images/hermes-vps/hermes-vps-18-skill-diff.png)

手順の1番目に、前回配信を確認する項目が入った。5番目には、continuityによる重複回避が入った。取得状況の書式には、「x_searchは呼んだが投稿未採用」という書き方と、「取得件数」が加わった。

続きの確認項目と注意点も増えている。

![diff -uの出力の後半。確認項目に、5件に満たない日に既出の話題で穴埋めしていないか、前回出力と照合して言い換えや別媒体での再掲がないか、続報の条件、同じニュースをWebとXで別項目にしていないか、取得件数が一致しているか、が加わっている。注意点にも、前回出力を読まずに選定しない、同じ出来事を別媒体で再掲しない、続報の扱いが加わっている](/images/hermes-vps/hermes-vps-18-skill-diff-2.png)

確認項目と注意点にも、重複・続報・件数の項目が加わった。Telegramで受け取った6つは、どれも差分の中にあった。差分には、このほかに「確認できた範囲を越えて断定しない」「対話での依頼は3〜5項目を目安にする」「指定の書式やテンプレートがあれば優先する」の追加と、検索の使い分け(Firecrawl・Tavily・web_extract)の記述の削除も入っていた。バイト数は、2,116バイトから4,513バイトになった。

## 書き直したスキルで配信を動かす

翌朝7時の配信を待つこともできるが、この回では、次のコマンドで当日に1回、手動で動かした。`hermes cron run`は、指定したジョブを次のスケジューラの周回で1回すぐ実行するコマンドで、末尾はmorning-newsのジョブID(第9回で確認したもの)だ。

```bash
hermes cron run 18dd6b7a1580
```

2026年10月8日の20:17に、配信が届いた。

![Telegramに届いたmorning-newsの配信の画面。ジョブID 18dd6b7a1580のCronjob Responseとして、見出しは「2026-10-09 の朝ニュース」で、項目が3件並ぶ。取得状況には、対象が過去24時間のAI関連、方法がWeb検索使用・本文抽出3件成功・X検索は呼び出し済みで投稿は未採用、取得件数が3と書かれている](/images/hermes-vps/hermes-vps-18-delivery-after.png)

項目は3件で、取得状況は「X検索 呼び出し済み・投稿は未採用」「取得件数: 3」だった。新しい手順に書いた、5件に満たない日は確認できた件数だけ載せること、呼んだが投稿を採用しなかった場合の書き方と、同じ出方をしている。

見出しの日付は「2026-10-09 の朝ニュース」と出たが、実際は10月8日の夜に手動で動かした回だ。

1回の配信なので、「よくなった」とは言えない。確かめられたのは、書き直したスキルで配信が動いたことと、取得状況の書き方が新しい手順どおりに出たことまでだ。

## 1件だけ戻す

書き換えが気に入らないとき、台帳のidを指定して、その1件だけ戻せる。毎朝使うmorning-newsは戻さず、10月7日に作ったテスト用のスキルplain-japanese-v2で試した。このスキルは、Hermesに頼んで作らせたもので、作った直後に同じ流れで一度書き直していた。その書き直し(patch)の台帳idが`fba21d45fb0c`だ。

```bash
hermes curator rollback fba21d45fb0c
```

![VPSでhermes curator rollback fba21d45fb0cを実行した画面。戻す対象として、actionがpatch、skillがplain-japanese-v2、actorがagent、whenが2026-10-07、filesが1と表示されている。Restore this mutation's before-state? [y/N] にyと答えると、1 file(s) restored, 0 removed. と出て、Safety entry 5bda0b640bfbが戻す直前の状態を記録したと表示されている](/images/hermes-vps/hermes-vps-18-rollback.png)

戻す対象が表示され、`Restore this mutation's before-state? [y/N]`と確認された。`y`と答えると、`1 file(s) restored, 0 removed.`と出た。続けて`Safety entry 5bda0b640bfb captured the pre-rollback state.`とあり、戻す直前の状態も別に記録された。

台帳を見る。

```bash
hermes curator ledger --skill plain-japanese-v2 --limit 3
```

![VPSでhermes curator ledger --skill plain-japanese-v2 --limit 3を実行した画面。上から、rollback、pre-rollback、patchの3行が並ぶ。rollbackとpre-rollbackの行には、rollback of fba21d45fb0cと書かれている](/images/hermes-vps/hermes-vps-18-rollback-ledger.png)

台帳には、`pre-rollback`と`rollback`の2行が足された。元のpatchの行は残っている。戻したあとも、戻す前の記録は消えない。

台帳のそばには、スキル置き場(`~/.hermes/skills/`)全体のスナップショットを戻す方法(`hermes curator rollback --list`)もある、と画面に案内が出ていた。この回では試していない。

## うまくいかないとき

画面に出たものから、切り分けられるものを表にする。

| 症状 | わかること | 対処 |
|---|---|---|
| `hermes curator ledger --skill <名前>`が`ledger is empty`と出る | そのスキルの書き換え記録が0件。まだ書き換わっていないか、台帳が無効(`skills.ledger`が無効)の可能性がある | 台帳が有効かを確認する。書き換え前のmorning-newsでは、この表示が正常だった |
| 自分で作ったスキルが、自動では書き換わらない | 自動で直すのは、会話のあとの自動の見直しでHermesが自分から作ったスキルと、`hermes curator adopt <名前>`で任せたスキルだけ | Telegramで書き直しを頼む |
| 書き直しの結果が気に入らない | 変更前の状態が台帳に残っている | `hermes curator rollback <id>`で1件戻す。戻す直前の状態も記録される |

## 早見表・引用元・まとめと第19回予告

### 操作早見表

```bash
# [VPS ssh] バックアップ
cp -r ~/.hermes/skills/morning-news ~/morning-news.bak-20261008

# [VPS ssh] いまの状態を確認
ls -la ~/.hermes/skills/morning-news/
wc -c ~/.hermes/skills/morning-news/SKILL.md
hermes curator ledger --skill morning-news

# [Telegram] /new を送って新しい会話を始めてから、書き直しを頼む

# [VPS ssh] 変更を確認
hermes curator ledger --skill morning-news --limit 5
diff -u ~/morning-news.bak-20261008/SKILL.md ~/.hermes/skills/morning-news/SKILL.md

# [VPS ssh] 書き直したスキルで配信を1回動かす
hermes cron run 18dd6b7a1580

# [VPS ssh] 1件だけ戻す(idは台帳で確認する)
hermes curator rollback <id>
hermes curator ledger --skill <名前> --limit 3
```

### 引用元と参考

| 項目 | 引用元 |
|---|---|
| スキルの書き直し(公式ドキュメント) | [English: Skills](https://hermes-agent.nousresearch.com/docs/user-guide/features/skills) / [日本語訳: スキル](https://wiki.winsmux.dev/hermes/docs/user-guide/features/skills/) |
| 台帳と1件だけ戻す操作(公式ドキュメント) | [English: Curator](https://hermes-agent.nousresearch.com/docs/user-guide/features/curator) / [日本語訳: キュレーター](https://wiki.winsmux.dev/hermes/docs/user-guide/features/curator/) |
| 根拠(Hermes本体のコード) | patch(editは旧名)は`tools/skill_manager_tool.py`。自動の書き直しの対象は`tools/skill_manager_guards.py`。書き込みの承認(`write_approval`)の既定は`hermes_cli/config_defaults.py` |
| 版の注記 | 画面はHermes v0.21.5+8509(2026-10-08)で撮影した |

### まとめと第19回予告

第18回完了で、毎朝使うスキルをHermesに頼んで書き直させ、変更を台帳で確かめ、1件だけ戻せる状態になった。内訳は次のとおり。

- morning-newsのスキルは、6月17日から手を入れておらず、2,116バイト(version 1.2.0)だった。Telegramで頼むと、10月8日20:08には4,513バイト(version 1.3.0)になった
- 書き直しは、台帳にpatchが4件(すべてactorはagent)として残った。`diff`で、前回配信の確認と重複回避が手順に入ったことを確かめた
- 書き直したスキルで手動実行した配信の項目は3件で、取得状況は「X検索 呼び出し済み・投稿は未採用」「取得件数: 3」だった。1回の配信なので、よくなったとは言えない
- 戻したのは、テスト用のスキルplain-japanese-v2のpatch 1件。戻す直前の状態もSafety entryとして記録され、元のpatchの行も台帳に残った
- 自動の書き直しの対象は、Hermesが自分から作ったスキルと、`hermes curator adopt`で任せたスキルだけで、morning-newsは自動では書き換わらない

次の第19回は、作業履歴を毎晩取り込む話と、使わないスキルを片付ける話(Curator)だ。連載の回数は変わる可能性があるので、着手時に最新の計画書を確認してほしい。

---

| ← 前の回 | 次の回 → |
|---|---|
| [第17回](https://zenn.dev/sora_biz/articles/hermes-vps-17-soul) 口調をブレさせるな。Hermes Agentの話し方は実は変えられる | 第19回 取り込みを手でやるな。Hermes Agentは作業履歴を毎晩取り込み、使わないスキルを片付ける。(近日公開) |

📑 [シリーズのもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

:::message
この連載はSubstack「そらのAIエージェント通信」で先行公開している。無料[登録](https://sorabiz.substack.com/subscribe)すると最新回がメールに届く。[Zennでフォロー](https://zenn.dev/sora_biz)すると新着通知が届き、全体像は[連載ハブ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)にまとめてある。
:::
