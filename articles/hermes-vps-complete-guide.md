---
title: "Hermes Agent完全構築ガイド｜VPSに常駐する自分専用AIエージェントの作り方"
emoji: "🤖"
type: "tech"
topics: ["ai", "hermes", "vps", "個人開発", "自動化"]
published: true
---

ChatGPTもClaude CodeもCodexも、こちらが手順を教えれば賢く動く。けれど、覚えるのはいつもこちら側だ。同じ説明を書き直し、同じ指示を出し直す。Hermes Agentはここが違う。一度うまくいったやり方を、自分でスキルとして書き残し、次からは勝手に使い回す。使うほど手順がたまり、こちらが教えなくても賢くなっていく——そういう設計の、オープンソースの自律型エージェントだ。

この連載は、そのHermes Agentを月1,800円ほどのVPS(レンタルサーバー)1台に常駐させ、24時間自分のために動く状態まで育てる実録だ。順次公開中で、いまも続いている。ターミナルに不慣れでも、実際の画面を1枚ずつ確かめながら進められるように書いた。

このページは連載の入口になっている。上から順に読み進めれば、契約しただけの空っぽのサーバーが、毎朝ニュースを要約して届け、頼んだ手順を覚え、必要な情報を自分で検索しに行くエージェントに変わる。

## もくじ

本連載は、Substackのニュースレターで先行公開している。[無料で登録](https://sorabiz.substack.com/subscribe)すれば、Zennに出るより先に最新回を読める。Zennには少し遅れて順番に公開していく。

連載は続いており、回の順番や数は内容の充実に合わせて変わることがある。ここでは公開済みの回をまとめておく。以降の回は、公開しだいこのページに追加していく。

### 第I部　体を作る

| 回 | 見出し |
|----|--------|
| 1 | [Hermes AgentをVPSにデプロイする方法](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy) |
| 2 | [Hermes Agentの接続を安全にする方法](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale) |
| 3 | [Hermes Agentの認証情報を安全に管理する方法](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password) |
| 4 | [Hermes AgentをDockerで隔離して動かす方法](https://zenn.dev/sora_biz/articles/hermes-vps-04-install) |
| 5 | [Hermes AgentにGrokとDiscordを連携させる](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord) |
| 6 | [Hermes Agentをsystemdで常時起動させる方法](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd) |

### 第II部　顔と操作席

| 回 | 見出し |
|----|--------|
| 7 | [Hermes Agentをデスクトップアプリで操作する方法](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop) |
| 8 | [Hermes AgentをWeb Dashboardで管理する方法](https://zenn.dev/sora_biz/articles/hermes-vps-08-dashboard) |

### 第III部　生活リズム

| 回 | 見出し |
|----|--------|
| 9 | [Hermes Agentに毎朝のタスクを自動実行させる](https://zenn.dev/sora_biz/articles/hermes-vps-09-cron) |
| 10 | [Hermes Agentが使うほど賢くなるSkillsの登録方法](https://zenn.dev/sora_biz/articles/hermes-vps-10-skills) |
| 11 | [Hermes Agentに最新情報を自動取得させる方法](https://zenn.dev/sora_biz/articles/hermes-vps-11-web-search) |

### 第IV部　記憶を分けて育てる

| 回 | 見出し |
|----|--------|
| 12 | [Hermes AgentにMemoryで好みと前提を記憶させる](https://zenn.dev/sora_biz/articles/hermes-vps-12-memory) |
| 13 | [Hermes AgentとObsidianを連携して知識を共有する方法](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) |
| 14 | [Hermes Agentに過去の会話を自動で復元させる](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) |
| 15 | Hermes Agentに他のAIのセッションも吸収させる方法 |
| 16 | Hermes Agent専用の知識ベースを構築する方法 |
| 17 | Hermes Agentに一貫した人格を与える方法 |
| 18 | Hermes AgentのSkillsを定期的に最適化する |
| 19 | Hermes Agentのスキルを整理・スリム化する方法 |

### 第V部　他のAIを束ねる

| 回 | 見出し |
|----|--------|
| 20 | Hermes Agentから自宅PCを操作できるようにする |
| 21 | Hermes Agentにタスクを分担させる方法 |
| 22 | Hermes Agentで作業を見える化するKanbanの導入 |
| 23 | Hermes Agentに役割を割り振って運用する方法 |
| 24 | Hermes AgentからローカルLLMを呼び出す方法 |
| 25 | Hermes AgentからGrok Composerを直接呼び出す方法 |

### 第VI部　手足を増やす

| 回 | 見出し |
|----|--------|
| 26 | Hermes Agentのツールを一括管理する方法 |
| 27 | Hermes Agentにブラウザ操作をさせる方法 |
| 28 | Hermes Agentに画像や画面を理解させる方法 |
| 29 | Hermes Agentに画像生成をさせる方法 |
| 30 | Hermes Agentに音声で返答させる方法 |
| 31 | Hermes Agentに成果物を自動で出力させる方法 |
| 32 | Hermes Agentにレポートや資料を作成させる方法 |
| 33 | Hermes Agentに外部ツールを連携させる方法 |

### 第VII部　外部サービス連携

| 回 | 見出し |
|----|--------|
| 34 | Hermes AgentとNotion・Google Driveを連携させる方法 |
| 35 | Hermes AgentをWebhooksで外部から起動させる方法 |
| 36 | Hermes Agentで家電を操作する方法 |
| 37 | Hermes AgentにiMessageを送受信させる方法 |
| 38 | Hermes Agentを複数台で連携運用する方法 |

### 第VIII部　自走させる

| 回 | 見出し |
|----|--------|
| 39 | Hermes Agentに最後まで作業を完遂させる |
| 40 | Hermes Agentを用途別に使い分ける方法 |
| 41 | Hermes AgentをDigital Twinsとして運用する |

### 第IX部　声と生活導線

| 回 | 見出し |
|----|--------|
| 42 | Hermes Agentを音声で操作する方法 |
| 43 | Hermes Agentに音声日報を自動作成させる方法 |
| 44 | Hermes Agentの通知先を使い分ける方法 |
| 45 | Hermes Agentで毎日の自動運用を組み立てる方法 |
| 46 | Hermes Agentに既存画像を加筆編集させる方法 |

### 第X部　安全・費用・保守

| 回 | 見出し |
|----|--------|
| 47 | Hermes Agentの月額費用を把握する方法 |
| 48 | Hermes Agentの運用コストを下げる方法 |
| 49 | Hermes Agentの権限を安全に制限する方法 |
| 50 | Hermes Agentのバックアップと復旧方法 |
| 51 | Hermes Agentを家族や同僚と安全に共有する方法 |
| 52 | Hermes Agentに何を任せるかを決める方法 |

この先も、段階を追って順次公開していく。最新回は[Substackの登録](https://sorabiz.substack.com/subscribe)か、Zennの著者フォローで追ってほしい。

## このシリーズで作るもの

この連載は、Hermes Agentに少しずつ能力を足していく成長の記録だ。大きな流れはこうなっている。

まず体を作る。サーバーを借り、外から見えないように玄関を閉じ、秘密情報を守り、本体を入れ、頭脳(AIモデル)と窓口(メッセージアプリ)を二重化する。ここまでで「話しかけたら返ってくる」状態になる。

次に、手元から操作できる顔をつける。黒い画面(ターミナル)だけでなく、デスクトップアプリやブラウザの管理画面からも扱えるようにする。

そこから先は、毎朝決まった時刻に自分から動かし、よく使う手順を覚えさせ、調べたことを貯め、声や画像やファイルを扱い、やがて細かく言わなくても自分で進める相棒に育てていく。重い処理は家で余っているPCに任せる分担も作る。

連載は順次公開中で、回は内容の充実に合わせて増えたり並び替わったりする。いまは最初の「体を作る」段階まで公開し、その先へ進んでいるところだ。

## 参考動画(連載と併読推奨・任意)

[Hermes Architecture EXPLAINED: Memory, Context & Gateways](https://www.youtube.com/watch?v=n32qq7Kwzh0)

HuggingFace公式チャンネル提供の解説動画。約40分・英語(YouTubeの設定→字幕→自動翻訳→日本語で日本語字幕も出せる)。2026年6月公開。

**動画=全体図/連載=実装手順**という分担にしてある。動画はHermes Agentの内部設計(エージェントループ・コンテキスト構築・メモリ三形式・ゲートウェイ・cronの仕組み)を俯瞰する。本連載はVPSで実際に動かし、月1,800円ほどで毎日育てていく運用手順を日本語で実機検証する。両方読むと立体的に理解できる。動画を見なくても連載は完結する。

最初の章「アーキテクチャの概要」(0:57〜3:49・約3分)だけ見ると、この連載が何を作っているかが30秒で腑に落ちる。それ以降は読んでいる回に該当する章だけ拾えばよい。

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
動画は2026年6月公開で、本連載が依拠するHermes Agent v0.16.0(2026年6月5日)と近い時期だが、ファイル名や格納場所など実装の細部で一部食い違いがある(動画の`memory/`は実機で`memories/`複数形・動画の`hermes.db`は実機で`state.db`等)。本連載は実機v0.16.0で確認した名称・場所を採用している。動画は「設計の全体図」、連載は「v0.16.0で実際に動いた手順」と読み分けるとずれない。なお2026-06-19公開の**v0.17.0**「The Reach Release」で、iMessage連携(Photon Spectrum)・Automation Blueprints・Dashboard profile builder・Subagent watch-windows・Skills Hub刷新等の大型追加が入った。連載各回の末尾コラムでv0.17.0新機能の差分は順次補足する。`hermes update`で本体を最新に保ち続けていれば自動で反映される。
:::

:::message
2026-06-21にNousResearch公式の Docker イメージ `nousresearch/hermes-agent` も公開された。第4回は第三者製の `nikolaik/python-nodejs:python3.11-nodejs20` で書いているが、新規読者は公式イメージから始めても同じ手順で動く。既存読者は乗り換え不要(両方使える)。第4回末尾コラムに詳細を補足してある。
:::

## はじめる前に必要なもの

詳しい手順は各回で説明するが、全体を通して使うものを先に挙げておく。

- レンタルサーバー(VPS)1台──月1,800円ほど。第1回で契約から説明する
- スマホのメッセージアプリ──TelegramかDiscord。エージェントに話しかける窓口になる
- パスワード管理アプリの1Password──APIキーなどの秘密情報を安全に預ける(第3回)

特別なプログラミングの知識はいらない。コマンドはすべてコピーして使える形で載せている。

## このシリーズの読み方

順番に積み上げていく構成なので、第1回から読むのがいちばん迷わない。すでにVPSを持っている人や、特定の話題(常駐・検索など)だけ知りたい人は、上のもくじで気になる回を探して読んでもいい。各回の冒頭に「その回の到達点」を置いているので、自分に必要かどうかはそこで判断できる。

それでは、第1回でサーバーを1台借りるところから始めよう。
