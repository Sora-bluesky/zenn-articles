---
title: "Hermes Agent完全構築ガイド｜VPSに常駐させる「使うほど賢くなる」エージェント"
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

### 第1部：体を作る — サーバーに常駐するAIを用意する

- **第1回**：[Hermes AgentをVPSに迎える──契約から最小構成のログインまで](https://zenn.dev/sora_biz/articles/hermes-vps-01-deploy)
- **第2回**：[Hermes Agentの玄関を世界から隠す──Tailscaleで公開SSHを閉じる](https://zenn.dev/sora_biz/articles/hermes-vps-02-tailscale)
- **第3回**：[Hermes Agentの秘密をファイルに残さない──1Passwordで参照だけ渡す](https://zenn.dev/sora_biz/articles/hermes-vps-03-1password)
- **第4回**：[Hermes Agent本体をVPSに入れる──Dockerサンドボックスで隔離する](https://zenn.dev/sora_biz/articles/hermes-vps-04-install)
- **第5回**：[Hermes Agentの頭脳と出入口を2系統に増やす──GrokとDiscordを足す](https://zenn.dev/sora_biz/articles/hermes-vps-05-oauth-discord)
- **第6回**：[Hermes Agentを24時間止めずに動かす──systemdで自動起動・自動復帰](https://zenn.dev/sora_biz/articles/hermes-vps-06-systemd)

### 第2部：顔をつける — 黒い画面の外から操作する

- **第7回**：[Hermes Agentをマウス操作で動かす──公式アプリ「Hermes Desktop」を入れる](https://zenn.dev/sora_biz/articles/hermes-vps-07-desktop)
- **第8回**：[Hermes Agentをブラウザの管制室から操る──Web Dashboardで設定を見える化する](https://zenn.dev/sora_biz/articles/hermes-vps-08-dashboard)

### 第3部：育てる — 自分から動き、覚え、調べる

- **第9回**：[Hermes Agentが朝から話しかけてくる──Dashboardで毎朝の定型タスクを任せる](https://zenn.dev/sora_biz/articles/hermes-vps-09-cron)
- **第10回**：Hermes Agentが使うほど自分専用に育つ──Skillsに手順を覚えさせる
- **第11回**：Hermes Agentが最新情報を自分で取りに行く──Web検索とX検索を使い分ける

### 第4部：記憶を分けて育てる ─ 「覚える」を分けて整理する

- **第12回**：Hermes AgentにMemoryで好みと前提を記憶させる──毎回説明不要の自分専用AIへ
- **第13回**：Hermes AgentにObsidianを連携させる──外付けの脳として知識を共有する
- **第14回**：Hermes AgentにSession Searchで過去会話を思い出す──会話の文脈を自動復元
- **第15回**：Hermes Agentにllm-wikiで知識を貯める──同じことを二度調べない自分専用知識ベースへ
- **第16回**：Hermes AgentにSOUL.mdで人格を与える──口調と判断基準を一貫させる
- **第17回**：Hermes AgentにSkillsを育て直す──手順を定期的に見直して最適化
- **第18回**：Hermes AgentにCuratorでスキルを整理させる──増えた技術を棚卸ししてスリムに

この先も、段階を追って順次公開していく。最新回はSubstackの登録か、Zennの著者フォローで追ってほしい。

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
| コンテキスト | [7:31](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=451s) | 第12回(Memory) / 第16回(SOUL.md) |
| コンテキスト圧縮 | [13:28](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=808s) | 第18回(Curator)周辺 |
| コンテキスト圧縮プロンプト | [18:28](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=1108s) | 第18回(Curator)周辺 |
| ゲートウェイ | [19:59](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=1199s) | 第5回(Discord) / 第6回(systemd) |
| メモリ | [28:00](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=1680s) | 第12-14回(記憶系) |
| cronジョブ | [34:37](https://www.youtube.com/watch?v=n32qq7Kwzh0&t=2077s) | 第9回(Cron) |

:::message
動画は2026年6月公開で、本連載が依拠するHermes Agent v0.16.0(2026年6月5日)と近い時期だが、ファイル名や格納場所など実装の細部で一部食い違いがある(動画の`memory/`は実機で`memories/`複数形・動画の`hermes.db`は実機で`state.db`等)。本連載は実機v0.16.0で確認した名称・場所を採用している。動画は「設計の全体図」、連載は「v0.16.0で実際に動いた手順」と読み分けるとずれない。
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
