---
title: "OpenClaw × XServer VPS：月990円でAIが24時間働く環境を作った"
emoji: "🦞"
type: "tech"
topics: ["openclaw", "ai", "vps", "生成ai", "個人開発"]
published: true
---

:::message alert
OpenClawは強力だが、セキュリティ対策なしに使うと危険なツールでもある。「OpenClawとは」「おすすめ構成」を読んでから導入に進んでほしい。
:::

:::message
**シリーズ構成**
- [Linux（Ubuntu）インストールガイド（Windows）](wsl2-windows-install-guide)
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- 🦞OpenClaw導入ガイド
  - [XServer VPSで安全に動かす](openclaw-setup-guide)（この記事）
  - [WSL2で無料で試してみた](openclaw-wsl2-setup-guide)
- [🦞OpenClawでDiscord/LINEを個人AIアシスタント化する](openclaw-sns-guide)
:::

---

## OpenClawとは

### 名称変更の経緯

OpenClawは、オーストリアの開発者 Peter Steinberger 氏が作ったオープンソースの自律型AIパーソナルアシスタント。名前が2回変わっている。

| 時期 | 名称 | 理由 |
|------|------|------|
| 2025年11月〜2026年1月 | Clawdbot (Clawd) | Claude Code のロブスターマスコットに由来 |
| 2026年1月27日〜 | Moltbot | Anthropic からの商標要請で変更 |
| 2026年1月30日〜 | OpenClaw | 旧Xアカウント乗っ取りにより再度変更 |

2026年2月時点でGitHubスター 170,000超。史上最速ペースで伸びたOSSプロジェクトの1つになった。

> 「New shell, same lobster.」（新しい殻、同じロブスター）
> — [OpenClaw 公式](https://x.com/openclawai/status/2017505983678976021)

### 導入前に確認すること

:::message alert
OpenClawは万人向けのツールではない。導入を決める前に、自分がどちらに当てはまるか確認してほしい。
:::

使ってみる価値がある人：

- セキュリティリスクを理解し、自己責任で運用できる
- サンドボックス環境でAIエージェントを実験したい
- マルチエージェントシステムを構築したい

今は手を出さないほうがいい人：

- セキュリティ設定に自信がない
- 本番環境や機密データがある環境で使いたい
- 「インストールして放置」で使いたい

開発者自身がこう言っている：

> 「It still isn't ready to be installed by normies, to be fair.」
> （正直なところ、まだ一般ユーザーがインストールできる状態ではない）
> — [Peter Steinberger](https://x.com/steipete)（OpenClaw 開発者）

Ciscoのセキュリティチームも警告を出した：

> 「From a capability perspective, OpenClaw is groundbreaking. [...] From a security perspective, it's an absolute nightmare.」
> （機能面では画期的。セキュリティ面では完全な悪夢）
> — [Cisco セキュリティチーム](https://blogs.cisco.com/ai/personal-ai-agents-like-openclaw-are-a-security-nightmare)

### 従来のAIとの違い

ChatGPTやClaude.aiには「継続性がない」という共通の弱点がある。昨日の会話は消え、先週のリサーチはどこかに埋もれる。OpenClawはここを根本から変えにきた。

| 項目 | 従来のAI（ChatGPT / Claude.ai等） | OpenClaw |
|------|----------------------------------|----------|
| 記憶 | セッション終了で消える | 永続的なメモリを保持 |
| データ | クラウド（運営会社のサーバー） | 自分のPC/VPS（手元に残る） |
| 動作 | 受動的（質問に答えるだけ） | 能動的（タスクを自律実行） |
| 稼働 | 人間が常に指示 | スケジュール実行（Cron + HeartBeat） |
| 操作対象 | チャットUI内で完結 | ファイルシステム + CLI + チャットアプリ |

ChatGPTやClaude.aiは「賢いチャットボット」。OpenClawは「24/7稼働の自律型AIアシスタント」。用途がまったく違う。

---

## おすすめ構成

導入を決めたなら、次は環境選び。

:::message
OpenClawの核は「24/7稼働の自律エージェント」で、[公式FAQ](https://docs.openclaw.ai/help/faq)でも「24/7の信頼性が必要ならVPSを使え」と書いてある。ローカルPC（WSL2）だとスリープでGatewayが止まり、メッセージを受信できない。
:::

### 構成比較

| 構成 | コスト | 安全性 | おすすめ度 |
|------|--------|--------|------------|
| 🥇 XServer VPS | ¥990/月〜（無料プランあり） | ◎（アプリイメージ） | ⭐⭐⭐⭐⭐ |
| 🥈 DigitalOcean 1-Click | $24/月〜 | ◎（自動設定） | ⭐⭐⭐⭐ |
| 🥉 Railway / その他VPS | $5〜10/月 | ○ | ⭐⭐⭐ |
| WSL2 + Docker | 無料 | ○ | ⭐⭐⭐ |

### 🥇 XServer VPS（この記事で解説）

[XServer VPS](https://vps.xserver.ne.jp/) は、レンタルサーバー国内シェアNo.1のエックスサーバーが提供する国産VPS。2026年2月6日から [OpenClawアプリイメージに正式対応](https://vps.xserver.ne.jp/support/news_detail.php?view_id=17624) し、申し込み時に「OpenClaw」を選ぶだけで環境が自動構築される。

私もサーバーはXserverを使っているが、国産VPSの安心感は桁違いだ。日本語の管理画面、日本語サポート（電話・メール・チャット）、国内データセンター。海外VPSで英語のドキュメントと格闘する必要がない。

| 特徴 | 内容 |
|------|------|
| OpenClawアプリイメージ | 申し込み時に選ぶだけで自動インストール（Ubuntu 24.04ベース） |
| 日本語サポート | 電話・メール・チャット対応 |
| 無料プラン | 4GB RAM / 3 vCPU / 30GB SSD が無料 |
| パケットフィルター | デフォルトON |
| セキュリティ認証 | ISMS（ISO/IEC 27001）・プライバシーマーク取得 |

料金プラン（36ヶ月契約時）：

| プラン | 月額 | vCPU | SSD | 用途 |
|--------|------|------|-----|------|
| 4GB（無料） | ¥0 | 3コア | 30GB | お試し |
| 2GB | ¥990 | 3コア | 50GB | 最小構成 |
| 6GB | ¥1,700 | 4コア | 150GB | 安定運用 |

:::message
無料プランは2〜4日ごとにコントロールパネルから手動更新が必要で、更新しないとサーバーが削除される。帯域は30Mbps。24/7の安定運用なら有料プラン（2GBプラン ¥990/月〜）にしておくのが無難。[無料VPSの詳細](https://vps.xserver.ne.jp/free.php)
:::

Claude Code / Codex CLI / Dify / Gemini CLI のアプリイメージも用意されているので、AI開発の拠点として使い回せる。問題が起きたらOS再インストールで環境をリセットできるのも地味にありがたい。

一方でDigitalOcean 1-Clickほどのセキュリティ自動設定はない。パケットフィルターは標準ONだが、Docker隔離やFail2banは手動になる。

### 🥈 DigitalOcean 1-Click

[DigitalOcean 1-Click Deploy](https://www.digitalocean.com/community/tutorials/how-to-run-openclaw)は月$24〜（約¥3,600〜）と高いが、セキュリティの自動設定は群を抜いている。

| セキュリティ項目 | 設定内容 |
|------------------|----------|
| コンテナ隔離 | Docker container isolation |
| 権限制限 | Non-root user execution |
| 認証 | Gateway token + DM pairing |
| ファイアウォール | Hardened firewall rules + Fail2ban |
| TLS暗号化 | Caddy + LetsEncrypt |

これがすべて自動で入る。セキュリティ設定に自信がなく、英語UIが苦にならないなら検討の余地はある。ただし月額はXServer VPSの3倍以上。コスパで選ぶならXServerだ。

### 🥉 Railway / その他VPS

[公式VPSリスト](https://docs.openclaw.ai/vps)に掲載されているプロバイダーは増え続けている。

| プロバイダー | コスト | 特徴 |
|-------------|--------|------|
| [Railway](https://docs.openclaw.ai/railway) | $5〜10/月 | ブラウザ完結 |
| [Northflank](https://docs.openclaw.ai/platforms/northflank) | - | 1-Click対応 |
| [Oracle Cloud Always Free](https://docs.openclaw.ai/platforms/oracle) | 無料 | ARM、最大4 OCPU / 24GB RAM |
| [Hetzner](https://docs.openclaw.ai/platforms/hetzner) | €3.49/月〜 | Docker-based |
| [Fly.io](https://docs.openclaw.ai/platforms/fly) | - | Docker対応 |
| [GCP](https://docs.openclaw.ai/platforms/gcp) | - | Google Cloud |
| [AWS](https://docs.openclaw.ai/platforms/aws) | - | EC2 / Lightsail |

セキュリティ設定はすべて手動。[公式セキュリティガイド](https://docs.openclaw.ai/gateway/security)を読んで自分で設定する必要がある。

### WSL2 + Docker（別記事）

VPS契約前にまず無料で触ってみたいなら、[WSL2で無料で試してみた](openclaw-wsl2-setup-guide)を参照。

---

## XServer VPSにインストールする

[XServer VPS 公式マニュアル](https://vps.xserver.ne.jp/support/manual/man_server_app_use_openclaw.php)に基づく手順。

### VPS申し込みとアプリイメージ選択

1. [XServer VPS](https://vps.xserver.ne.jp/) にアクセス
2. XServerアカウントを作成（クレジットカードが必要）
3. VPS申し込み画面で「イメージタイプ」→「アプリケーション」タブ→「OpenClaw」を選択

プランはお試しなら[無料プラン](https://vps.xserver.ne.jp/free.php)（4GB RAM / 3 vCPU / 30GB SSD）、安定運用なら2GBプラン（¥990/月〜）以上。

:::message
アプリイメージを選択するだけで、OpenClawが自動でインストール・構築される。Node.jsのインストールやnpm操作は不要。
:::

### パケットフィルターの確認

VPSパネルの「パケットフィルター設定」が「ONにする（推奨）」になっていることを確認する。

:::message
パケットフィルターはVPSへの通信で、接続を許可するポートを制限する機能。OpenClawの利用ではSSH（TCP 22）以外のポート開放は不要。
:::

### AIプロバイダーの設定

OpenClawでClaudeを使うにはAPI Keyが必要になる。

| 方法 | 対象 | 料金体系 | 推奨度 |
|------|------|----------|--------|
| API Key | 全ユーザー | 従量課金（トークン単位） | 推奨 |
| setup-token | Claude Pro/Max契約者 | サブスクリプション内 | ⚠️ ToS問題あり |

[OpenClaw公式](https://docs.openclaw.ai/gateway/authentication)で「For Anthropic accounts, we recommend using an API key.」と明記されている。

1. [Anthropic Console](https://console.anthropic.com/) でAPI Keyを作成
2. 次のセットアップウィザードでAPI Keyを入力する

API料金（2026年2月時点）：

| モデル | 入力 | 出力 | 用途 |
|--------|------|------|------|
| Claude Opus 4.5 | $5/百万トークン | $25/百万トークン | 複雑な推論 |
| Claude Sonnet 4.5 | $3/百万トークン | $15/百万トークン | コーディング |
| Claude Haiku 4.5 | $1/百万トークン | $5/百万トークン | 高速・低コスト |

:::message
使用量により大きく変わるが、1日30分程度の利用で月$10〜$50程度が目安。
:::

:::message alert
2026年1月9日、Anthropicは第三者ツールでのOAuth使用をブロックした。setup-tokenを使うと「This credential is only authorized for use with Claude Code」エラーが出る場合があり、最悪アカウント停止になる。API Keyを使うこと。
:::

:::message
XServer VPS公式マニュアルではOpenAIを使用する例で説明されている。Claude以外のAIサービス（OpenAI、Google等）も利用可能。
:::

### SSH接続とセットアップウィザード

VPSにSSH接続する：

```bash
ssh root@<VPSのIPアドレス>
```

:::message
SSH（Secure Shell）はリモートサーバーに安全に接続するプロトコル。VPSパネルの「コンソール」からも操作できる。
:::

セットアップウィザードを起動：

```bash
openclaw onboard --install-daemon
```

ウィザードでは以下の順に聞かれる：

1. セキュリティ同意 → 内容を確認し「Yes」
2. Onboarding mode → 「QuickStart」を選択（詳細設定は後から変更可能）
3. LLMプロバイダー選択 → 「Anthropic」→「API Key」
4. API Key入力 → Anthropic ConsoleのAPI Keyを入力
5. モデル選択 → 任意のモデルを選択
6. チャットプラットフォーム → 「Discord」を選択（LINEは別途プラグインで設定）
7. Botトークン入力 → 事前に作成したBotトークンを入力
8. チャンネル権限 → 「Allowlist」推奨

:::message
Allowlistは、OpenClawが反応するチャンネルを限定する設定。既に運用中のDiscordサーバーにBotを追加するなら、意図しないチャンネルでの動作を防ぐためにも設定しておきたい。
:::

:::message
Discord/LINEの事前準備（Bot作成）は [Discord/LINE連携ガイド](openclaw-sns-guide) を参照。[XServer VPS公式マニュアル](https://vps.xserver.ne.jp/support/manual/man_server_app_use_openclaw.php)にもDiscord Bot作成手順がある。
:::

### 動作確認

```bash
# 状態確認
openclaw status --all

# システム診断
openclaw doctor
```

出力例：

```
✓ Gateway: running on ws://127.0.0.1:18789
✓ Agent: idle
✓ Channels: discord (connected)
```

### ダッシュボード接続（任意）

OpenClawのWeb UIにはSSHトンネル経由でアクセスする。

ローカルPCから：

```bash
ssh -L 18789:localhost:18789 root@<VPSのIPアドレス>
```

ダッシュボードURLを取得：

```bash
openclaw dashboard
```

表示されたURLをブラウザで開く。

:::message
SSHトンネルは、SSH経由でVPS上のサービスにアクセスする方法。ダッシュボードのポートをインターネットに直接開放せずに済む。
:::

---

## DigitalOcean 1-Clickでのインストール

:::message
セキュリティ自動設定が最も充実しているのはDigitalOcean。Docker隔離・非root実行・ファイアウォール・Fail2ban・TLSがすべて自動で入る。月額$24〜と高いが、セキュリティ最優先ならこちら。
:::

[公式チュートリアル](https://www.digitalocean.com/community/tutorials/how-to-run-openclaw)に基づく手順：

1. [DigitalOcean](https://www.digitalocean.com/) でアカウント作成
2. [Marketplace](https://marketplace.digitalocean.com/) で「OpenClaw」を検索
3. 1-Click イメージから Droplet 作成（4GB RAM / 2 vCPU 推奨、$24/月〜）
4. SSH接続後、初期設定ウィザードに従う

詳細は[公式チュートリアル](https://www.digitalocean.com/community/tutorials/how-to-run-openclaw)と[技術解説ブログ](https://www.digitalocean.com/blog/technical-dive-openclaw-hardened-1-click-app)を参照。

---

## セキュリティ確認

### セキュリティ監査コマンド

```bash
# 監査
openclaw security audit

# 詳細監査（Gateway 接続テスト含む）
openclaw security audit --deep

# 問題の自動修正
openclaw security audit --fix
```

### チェックリスト

XServer VPS：

- [ ] パケットフィルターが「ON」
- [ ] SSH（TCP 22）以外の不要ポートを開放していない
- [ ] Gateway認証が有効（トークンまたはパスワード）
- [ ] チャンネル権限を「Allowlist」に設定
- [ ] Moltbookに接続していない（Moltbookは旧名称時代のWebダッシュボード。Gateway認証なしでインターネットに公開されるリスクがある）

DigitalOcean 1-Click：

- [ ] [公式チュートリアル](https://www.digitalocean.com/community/tutorials/how-to-run-openclaw)の手順通りに構築した
- [ ] Gatewayが起動している（`openclaw status --all`）
- [ ] Moltbookに接続していない

:::message alert
v2026.1.29のアップデートで、Gateway認証なし（auth mode "none"）は廃止された。トークンまたはパスワードによる認証が必須。
:::

### 緊急時の対応

```bash
# 1. Gateway を停止
openclaw gateway stop

# 2. ログ確認
openclaw logs

# 3. XServer VPS → OS再インストールで環境リセット
# 4. DigitalOcean → Droplet を削除して再構築
```

---

## アップデート

OpenClawは頻繁にアップデートされる。

```bash
# アップデート
curl -fsSL https://openclaw.ai/install.sh | bash -s -- --no-onboard

# 確認
openclaw doctor
```

---

## 対応チャットサービス（2026年2月時点）

OpenClawは20のチャットサービスに対応している。Discord/LINEだけではない。

### 追加インストール不要（コア）

| サービス | 日本での知名度 | 備考 |
|---------|--------------|------|
| WhatsApp | 低 | QRペアリングが必要。海外では最も人気 |
| Telegram | 低 | セットアップが最も簡単 |
| Discord | 高 | サーバー・チャンネル・DM対応 |
| Slack | 高 | Bolt経由 |
| Google Chat | 中 | Google Workspace利用者向け |
| Signal | 低 | セキュリティ重視のメッセンジャー |
| iMessage | 中 | Apple端末のみ。BlueBubblesの使用を推奨 |
| BlueBubbles | 低 | iMessageの上位互換実装 |
| WebChat | - | ブラウザベースUI |

### プラグイン（別途インストール）

| サービス | 日本での知名度 | 備考 |
|---------|--------------|------|
| LINE | 高 | LINE Messaging API経由。DM・グループ・Flexメッセージ対応 |
| Microsoft Teams | 高 | ビジネス利用者向け |
| Matrix | 低 | 分散型メッセンジャー |
| Feishu (飞书/Lark) | 低 | 中国のビジネスチャット |
| Mattermost | 低 | セルフホスト型チャット |
| Nostr | 低 | 分散型プロトコル |
| Tlon | 低 | Urbit系メッセンジャー |
| Twitch | 中 | ライブ配信チャット |
| Nextcloud Talk | 低 | セルフホスト型チャット |
| Zalo | 低 | ベトナムで人気 |
| Zalo Personal | 低 | Zaloの個人アカウント版 |

日本のユーザーなら、まずDiscordかSlackで試すのが手軽。LINEも使えるが、LINE Developersアカウントの作成とMessaging APIチャネルの設定が必要になるので、やや手間がかかる。

:::message
複数チャネルを1つのGatewayで同時運用できる。たとえばDiscordとSlackとLINEを同時に起動し、それぞれのチャットにOpenClawが自動で応答する構成も可能。
:::

Discord/LINEでの具体的なセットアップ手順は別記事にまとめた：
- [OpenClawでDiscord/LINEを個人AIアシスタント化する](openclaw-sns-guide)

VPS契約前にまず無料で触ってみるなら：
- [OpenClawをWSL2で無料で試してみた](openclaw-wsl2-setup-guide)

---

## 参考リンク

- [OpenClaw 公式サイト](https://openclaw.ai/)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [公式ドキュメント](https://docs.openclaw.ai/)
- [公式VPSプロバイダーリスト](https://docs.openclaw.ai/vps)
- [XServer VPS](https://vps.xserver.ne.jp/)
- [XServer VPS OpenClawマニュアル](https://vps.xserver.ne.jp/support/manual/man_server_app_use_openclaw.php)
- [XServer VPS 料金プラン](https://vps.xserver.ne.jp/price.php)
- [XServer VPS 無料VPS](https://vps.xserver.ne.jp/free.php)
- [DigitalOcean 1-Click チュートリアル](https://www.digitalocean.com/community/tutorials/how-to-run-openclaw)
- [DigitalOcean 技術解説ブログ](https://www.digitalocean.com/blog/technical-dive-openclaw-hardened-1-click-app)
- [セキュリティガイド](https://docs.openclaw.ai/gateway/security)

---

## 関連記事

- [Linux（Ubuntu）インストールガイド（Windows）](wsl2-windows-install-guide)
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ](claude-code-tips-and-features)
