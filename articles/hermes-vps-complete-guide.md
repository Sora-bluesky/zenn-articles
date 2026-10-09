---
title: "Hermes Agent完全構築ガイド｜VPSに常駐する自分専用AIエージェントの作り方"
emoji: "🤖"
type: "tech"
topics: ["ai", "hermes", "vps", "個人開発", "自動化"]
published: true
---

この連載を読み進めると、Hermes Agentが月1,800円ほどのVPS(レンタルサーバー)1台に常駐し、24時間自分のために動く状態になる。順次公開中で、いまも続いている。ターミナルに不慣れでも、実際の画面を1枚ずつ確かめながら進められるように書いた。

ChatGPTもClaude CodeもCodexも、こちらが手順を教えれば賢く動く。けれど、覚えるのはいつもこちら側だ。同じ説明を書き直し、同じ指示を出し直す。Hermes Agentはここが違う。一度うまくいったやり方を、自分でスキル(再利用できる手順書)として書き残し、次からは勝手に使い回す。使うほど手順がたまり、こちらが教えなくても賢くなっていく。オープンソースの自律型エージェントだ。

このページには連載のもくじと読み方をまとめてある。上から順に読み進めれば、契約しただけの空っぽのサーバーが、毎朝7時にニュースを要約して届け、頼んだ手順を覚え、必要な情報を自分で検索しに行くエージェントに変わる。

## もくじ

本連載は、Substackのニュースレターで先行公開している。[無料で登録](https://sorabiz.substack.com/subscribe)すれば、Zennに出るより先に最新回を読める。Zennには少し遅れて順番に公開していく。

連載は全27回（予定）で、いまは第18回まで公開済みだ。ここでは第27回までのもくじをまとめておく。未公開の回は、公開しだいリンクを足していく。

### 第I部　VPSで24時間動かす

| 回 | 見出し |
|----|--------|
| 1 | [サーバー代は月1,800円で足りる。Hermes AgentはVPSで24時間動き続ける](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy) |
| 2 | [パスワードはもう打つな。Hermes AgentへのSSHは鍵一発で入れる](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale) |
| 3 | [APIキーをそのまま書くな。Hermes Agentの秘密は1Passwordが預かる](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password) |
| 4 | [Hermes AgentをDockerで隔離して動かす方法](https://zenn.dev/sora_biz/articles/hermes-vps-04-install) |
| 5 | [コマンドを覚えるな。Hermes AgentはDiscordで話しかけるだけで動く](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord) |
| 6 | [気づいたら止まっている、をなくせ。Hermes Agentはsystemdでいつも動き続け、落ちてもすぐ戻る](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd) |

### 第II部　デスクトップアプリとブラウザから操作する

| 回 | 見出し |
|----|--------|
| 7 | [Hermes AgentがMicrosoft Storeに来た。Windowsアプリで入れてVPSにつなぐ（旧版からの入れ替えも）](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop) |
| 8 | [手探りで動かすな。Hermes Agentはブラウザ1枚で中身が見える](https://zenn.dev/sora_biz/articles/hermes-vps-08-dashboard) |

### 第III部　定時実行・スキル・Web検索を足す

| 回 | 見出し |
|----|--------|
| 9 | [いつもの作業を毎回自分でやるな。Hermes Agentが決めた時刻や間隔で自動でこなす](https://zenn.dev/sora_biz/articles/hermes-vps-09-cron) |
| 10 | [毎回教えるな。Hermes Agentは使えば使うほど自分で賢くなる](https://zenn.dev/sora_biz/articles/hermes-vps-10-skills) |
| 11 | [気になる情報を自分で探し回るな。Hermes Agentがネットで調べて要点だけまとめてくれる](https://zenn.dev/sora_biz/articles/hermes-vps-11-web-search) |

### 第IV部　記憶・話し方・スキルを管理する

| 回 | 見出し |
|----|--------|
| 12 | [好みを毎回言うな。Hermes AgentはMemoryで覚えている](https://zenn.dev/sora_biz/articles/hermes-vps-12-memory) |
| 13 | [メモを自分で探すな。Hermes AgentはObsidianを記憶として読む](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) |
| 14 | [毎回最初から話すな。Hermes Agentは前回の続きからそのまま動く](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) |
| 15 | [記憶を捨てるな。Hermes AgentはClaude Codeの続きを引き継ぐ](https://zenn.dev/sora_biz/articles/hermes-vps-15-import-ai-sessions) |
| 16 | [同じことを二度調べさせるな。Hermes Agentは作業履歴からセカンドブレインを作る](https://zenn.dev/sora_biz/articles/hermes-vps-16-secondbrain) |
| 17 | [口調をブレさせるな。Hermes Agentの話し方は実は変えられる](https://zenn.dev/sora_biz/articles/hermes-vps-17-soul) |
| 18 | [使ったスキルを古いままにするな。Hermes Agentは自分でSKILL.mdを書き直す。](https://zenn.dev/sora_biz/articles/hermes-vps-18-skill-rewrite) |
| 19 | 取り込みを手でやるな。Hermes Agentは作業履歴を毎晩取り込み、使わないスキルを片付ける。 |

### 第V部　Claude Code・自宅PC・ローカルモデルと分担する

| 回 | 見出し |
|----|--------|
| 20 | 画面を増やすな。Hermes Desktopは1枚でコードの作業を進める。 |
| 21 | PCの前に行くな。Hermes Agentは自宅のClaude Codeを触れる。 |
| 22 | 1つのAIに頼るな。Hermes Agentは自宅GPUのローカルモデルも使い分ける。 |
| 23 | 全部自分で指示するな。Hermes Agentはタスクを子エージェントに振り分ける。 |
| 24 | 作業を追うな。Hermes AgentはKanbanの1枚で進捗が全部見える。 |
| 25 | 1つの答えを信じるな。Hermes Agentは複数のAIで比べ、確かめてから出す。 |

### 第VI部　長い作業を任せ、任せない一線を決める

| 回 | 見出し |
|----|--------|
| 26 | 途中でやめさせるな。Hermes Agentは作業を最後までやり遂げる。 |
| 27 | 全部を任せるな。Hermes Agentには任せない一線を先に決める。 |

本編は第27回で完結する予定だ。最新回は[Substackの登録](https://sorabiz.substack.com/subscribe)か、Zennの著者フォローで追ってほしい。

## 応用ガイド（連載とは別の独立記事。順次公開）

連載の外に、用途別の独立記事を「応用ガイド」として出していく。下の順に出す予定で、公開したら、このページにリンクを足す。

1. 費用と安全の運用（月額の内訳・無料枠・認証情報の管理・更新と復旧）
2. profileで役割を分け、複数台のHermesで仕事を分ける
3. 外部サービスとMCPでできることを増やす
4. LINEなどに、急ぎの知らせだけを届ける
5. 画像を読ませる・描かせる、ブラウザを操作させる
6. 成果をファイルで受け取る
7. 声で話しかけ、声で返事を受け取る

## このシリーズで作るもの

この連載は、Hermes Agentに少しずつ能力を足していく成長の記録だ。大きな流れはこうなっている。

第I部では、サーバーを借り、外から見えないようにSSHのポートを閉じ、秘密情報を守り、本体を入れ、AIモデルとメッセージアプリをそれぞれ2系統用意する。ここまでで「話しかけたら返ってくる」状態になる。

次に、自分のパソコンから操作できる画面を用意する。黒い画面(ターミナル)だけでなく、デスクトップアプリやブラウザの管理画面からも扱えるようにする。

そこから先は、毎朝7時に自分から動かし、よく使う手順を覚えさせ、調べたことを貯め、話し方とスキルを整え、やがて細かく言わなくても自分で進めるように育てていく。コードの作業は自宅のClaude Codeやローカルモデルに分担し、最後に長い作業を任せる範囲と、任せない一線を決める。

連載は全27回（予定）で、順次公開中だ。いまは第18回まで公開済みで、その先へ進んでいるところだ。画像・ブラウザ操作・外部サービス・通知・声・費用と安全の運用は、連載とは別の「応用ガイド」で扱う。

:::message
**2026-07-12追記**:公式のホスティング版「Hermes Agent Cloud」が公開された(ポータルでモデルとサーバーサイズを選ぶと60秒ほどで起動する)。まず触ってみるなら、Cloudは手軽な方法だ。この連載はその上で、**自分のVPSに自分専用の環境を構築する**路線を扱う。会話も記憶も秘密も自分のサーバーに残り、スキルや外部連携を根っこから自由に組めて、費用はVPS代の月1,800円ほどで固定という違いがある。Cloudで気に入ってから自分のVPSへ移る人にも、この連載の手順はそのまま使える。
:::

## 参考動画(連載と併読推奨・任意)

[Hermes Architecture EXPLAINED: Memory, Context & Gateways](https://www.youtube.com/watch?v=n32qq7Kwzh0)

HuggingFace公式チャンネル提供の解説動画。約40分・英語(YouTubeの設定→字幕→自動翻訳→日本語で日本語字幕も出せる)。2026年6月公開。

**動画=全体図/連載=実装手順**という分担にしてある。動画はHermes Agentの内部設計(エージェントループ・コンテキスト構築・メモリ三形式・ゲートウェイ・cronの仕組み)を俯瞰する。本連載はVPSで実際に動かし、月1,800円ほどで毎日育てていく運用手順を日本語で実際に動かして検証する。両方読むと立体的に理解できる。動画を見なくても連載は完結する。

最初の章「アーキテクチャの概要」(0:57〜3:49・約3分)だけ見ると、この連載が何を作っているかが30秒で分かる。それ以降は読んでいる回に該当する章だけ拾えばよい。

| 動画チャプター | 開始時刻 | 対応する連載回 |
|---|---|---|
| アーキテクチャの概要 | [0:57](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=57s) | 第1回(全体図) |
| エージェントループ | [3:49](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=229s) | 第10回(Skills) / 第12回(Memory) |
| コンテキスト | [7:31](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=451s) | 第12回(Memory) / 第17回(SOUL.md) |
| コンテキスト圧縮 | [13:28](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=808s) | 第19回(Curator)周辺 |
| コンテキスト圧縮プロンプト | [18:28](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=1108s) | 第19回(Curator)周辺 |
| ゲートウェイ | [19:59](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=1199s) | 第5回(Discord) / 第6回(systemd) |
| メモリ | [28:00](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=1680s) | 第12-14回(記憶系) |
| cronジョブ | [34:37](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=2077s) | 第9回(Cron) |

:::message
動画は2026年6月公開で、本連載が依拠するHermes Agent v0.16.0(2026年6月5日)と近い時期だが、ファイル名や格納場所など実装の細部で一部食い違いがある(動画の`memory/`は実際には`memories/`複数形・動画の`hermes.db`は実際には`state.db`等)。本連載は実際にv0.16.0を動かして確認した名称・場所を採用している。動画は「設計の全体図」、連載は「v0.16.0で実際に動いた手順」と読み分けるとずれない。なお2026-06-19公開の**v0.17.0**「The Reach Release」で、iMessage連携(Photon Spectrum)・Automation Blueprints・Dashboard profile builder・Subagent watch-windows・Skills Hub刷新等の大型追加が入った。連載各回の末尾コラムでv0.17.0新機能の差分は順次補足する。`hermes update`で本体を最新に保ち続けていれば自動で反映される。
:::

:::message
2026-06-21にNousResearch公式の Docker イメージ `nousresearch/hermes-agent` も公開された。第4回は第三者製の `nikolaik/python-nodejs:python3.11-nodejs20` で書いているが、新規読者は公式イメージから始めても同じ手順で動く。既存読者は乗り換え不要(両方使える)。第4回末尾コラムに詳細を補足してある。
:::

## はじめる前に必要なもの

詳しい手順は各回で説明するが、全体を通して使うものを先に挙げておく。

- レンタルサーバー(VPS)1台:月1,800円ほど。第1回で契約から説明する
- スマホのメッセージアプリ:TelegramかDiscord。エージェントに話しかけるときに使う
- パスワード管理アプリの1Password:APIキーなどの秘密情報を安全に預ける(第3回)

特別なプログラミングの知識はいらない。コマンドはすべてコピーして使える形で載せている。

## このシリーズの読み方

順番に積み上げていく構成なので、第1回から読むのがいちばん迷わない。すでにVPSを持っている人や、特定の話題(常駐・検索など)だけ知りたい人は、上のもくじで気になる回を探して読んでもいい。各回の冒頭に「その回の到達点」を置いているので、自分に必要かどうかはそこで判断できる。

このシリーズは、VPSで実際に動かした手順と画面の記録だ。公式ドキュメントの日本語訳と逆引きは wiki.winsmux.dev にある。初めての人は[初めての方へ](https://wiki.winsmux.dev/hermes/first/)、やりたいことから探すなら[逆引き](https://wiki.winsmux.dev/hermes/howto/)。本連載の画面は、各回を撮影した時点の版(v0.14〜0.20)のもので、最新版(v2026.9.24)との差は[更新履歴](https://wiki.winsmux.dev/hermes/updates/)で追える。

それでは、第1回でサーバーを1台借りるところから始めよう。

:::message
この連載はSubstack「そらのAIエージェント通信」で先行公開している。無料[登録](https://sorabiz.substack.com/subscribe)すると最新回がメールに届く。[Zennでフォロー](https://zenn.dev/sora_biz)すると新着通知が届く。
:::
