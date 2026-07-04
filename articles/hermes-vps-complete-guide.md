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
| 1 | [サーバー代は月1,800円で足りる。Hermes AgentはVPSで24時間動き続ける。](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy) |
| 2 | [パスワードはもう打つな。Hermes AgentへのSSHは鍵一発で入れる。](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale) |
| 3 | [パスワードを一切書くな。Hermes Agentの秘密は1Passwordが預かる。](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password) |
| 4 | [Hermes AgentをDockerで隔離して動かす方法](https://zenn.dev/sora_biz/articles/hermes-vps-04-install) |
| 5 | [コマンドを覚えるな。Hermes AgentはDiscordで話しかけるだけで動く。](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord) |
| 6 | [再起動で消させるな。Hermes Agentはsystemdで自分で起き上がる。](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd) |

### 第II部　顔と操作席

| 回 | 見出し |
|----|--------|
| 7 | [SSHはもう開くな。Hermes Agentはデスクトップアプリから直接話せる。](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop) |
| 8 | [手探りで動かすな。Hermes Agentはブラウザ1枚で中身が見える。](https://zenn.dev/sora_biz/articles/hermes-vps-08-dashboard) |

### 第III部　生活リズム

| 回 | 見出し |
|----|--------|
| 9 | [毎朝の作業を自分でやるな。Hermes Agentは7時にCronで始める。](https://zenn.dev/sora_biz/articles/hermes-vps-09-cron) |
| 10 | [毎回教えるな。Hermes Agentは使えば使うほど自分で賢くなる。](https://zenn.dev/sora_biz/articles/hermes-vps-10-skills) |
| 11 | [新聞は自分で読むな。Hermes Agentは毎朝7時に朝刊を用意する。](https://zenn.dev/sora_biz/articles/hermes-vps-11-web-search) |

### 第IV部　記憶を分けて育てる

| 回 | 見出し |
|----|--------|
| 12 | [好みを毎回言うな。Hermes AgentはMemoryで覚えている。](https://zenn.dev/sora_biz/articles/hermes-vps-12-memory) |
| 13 | [メモを自分で探すな。Hermes AgentはObsidianを記憶として読む。](https://zenn.dev/sora_biz/articles/hermes-vps-13-obsidian) |
| 14 | [毎回最初から話すな。Hermes Agentは前回の続きからそのまま動く。](https://zenn.dev/sora_biz/articles/hermes-vps-14-session-search) |
| 15 | [記憶を捨てるな。Hermes AgentはClaude Codeの続きを引き継ぐ。](https://zenn.dev/sora_biz/articles/hermes-vps-15-import-ai-sessions) |
| 16 | 記憶を自分で残すな。Hermes Agentは会話とメモを自動で繋ぐ。 |
| 17 | 口調をブレさせるな。Hermes Agentは設定でいつも同じ口調を保つ。 |
| 18 | 技を放置するな。Hermes Agentは定期的にSkillsを磨き直す。 |
| 19 | 技を増やしすぎるな。Hermes Agentは自動で整理して動きを軽く保つ。 |

### 第V部　他のAIを束ねる

| 回 | 見出し |
|----|--------|
| 20 | 画面を増やすな。Hermes Desktopは1枚でコードを束ねる。 |
| 21 | PCの前に行くな。Hermes Agentは自宅のClaude Codeを触れる。 |
| 22 | 全部自分で指示するな。Hermes Agentはタスクを自分で振り分ける。 |
| 23 | 作業を追うな。Hermes Agentは1枚のボードで進捗が全部見える。 |
| 24 | 役割を1つに絞るな。Hermes Agentは何役も同時にこなせる。 |
| 25 | 1つのAIに頼るな。Hermes Agentは自宅GPUのAIも使い分ける。 |
| 26 | 長文は自分で書くな。Hermes AgentはGrokを呼んで書いてくれる。 |
| 27 | 1つの答えを信じるな。Hermes Agentは複数のAIで比べて決める。 |
| 28 | 確認なしで渡すな。Hermes Agentは自分でチェックしてから出す。 |

### 第VI部　手足を増やす

| 回 | 見出し |
|----|--------|
| 29 | 道具を散らかすな。Hermes Agentは1箇所にまとめてすぐ出せる。 |
| 30 | クリックは自分でするな。Hermes Agentはブラウザ作業を全部引き受ける。 |
| 31 | スクショを説明するな。Hermes Agentは画像の中身を自分で読む。 |
| 32 | 画像を探し回るな。Hermes Agentが指示だけで絵を描いてくれる。 |
| 33 | 画面は見なくていい。Hermes Agentは声で返事をしてくれる。 |
| 34 | 口だけで済ませるな。Hermes Agentは成果をファイルで渡してくれる。 |
| 35 | 報告書は自分で書くな。Hermes Agentが最後の1枚まで書いてくれる。 |
| 36 | 1社だけで揃えるな。Hermes Agentは外部サービスと繋いで道具を増やす。 |

### 第VII部　外部サービス連携

| 回 | 見出し |
|----|--------|
| 37 | 往復して探すな。Hermes AgentはNotionとDriveの両方を触れる。 |
| 38 | 自分で呼び出すな。Hermes Agentは合図が来たら勝手に動き出す。 |
| 39 | リモコンを探すな。Hermes Agentが家電を指示で動かしてくれる。 |
| 40 | 返事を後回しにするな。Hermes AgentはiMessageですぐ返してくれる。 |
| 41 | 1台だけで動かすな。Hermes Agentは複数台で仕事を分け合う。 |

### 第VIII部　自走させる

| 回 | 見出し |
|----|--------|
| 42 | 途中でやめさせるな。Hermes Agentは作業を最後までやり遂げる。 |
| 43 | 1つの人格で済ますな。Hermes Agentは場面ごとに顔を切り替える。 |
| 44 | 1台に縛るな。Hermes Agentは分身を他のマシンにも置ける。 |

### 第IX部　声と生活導線

| 回 | 見出し |
|----|--------|
| 45 | 手で操作するな。Hermes Agentは声だけで指示を受けて動く。 |
| 46 | 日報は自分で書くな。Hermes Agentは声で1日の作業を報告する。 |
| 47 | 通知を一律に送るな。Hermes Agentは急ぎだけ手元に届ける。 |
| 48 | 毎日ゼロから動くな。Hermes Agentは型を決めて勝手に回る。 |
| 49 | 撮り直すな。Hermes Agentは元の1枚から画像を直してくれる。 |

### 第X部　安全・費用・保守

| 回 | 見出し |
|----|--------|
| 50 | 費用をざっくり済ますな。Hermes Agentの月額は内訳まで数字で見える。 |
| 51 | 払いすぎを放置するな。Hermes Agentは無駄なリソースを削って安くする。 |
| 52 | 何でも許可するな。Hermes Agentは権限設定で範囲を制限する。 |
| 53 | 壊れたまま放っておくな。Hermes Agentはバックアップで数分で戻せる。 |
| 54 | 自分だけで抱え込むな。Hermes Agentは権限を絞って安全に渡せる。 |
| 55 | 全部を任せるな。Hermes Agentには任せない一線を先に決める。 |

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

:::message
この連載はSubstack「そらのAIエージェント通信」で先行公開している。無料[登録](https://sorabiz.substack.com/subscribe)すると最新回がメールに届く。[Zennでフォロー](https://zenn.dev/sora_biz)すると新着通知が届く。
:::
