---
title: "OpenClaw（旧Clawdbot）をDigitalOceanで安全に動かす"
emoji: "🦞"
type: "tech"
topics: ["openclaw", "ai", "vps", "digitalocean", "security"]
published: false
---

## はじめに

:::message alert
**⚠️ セキュリティ警告**
OpenClaw は強力なツールですが、適切なセキュリティ対策なしに使用すると重大なリスクがあります。**必ず「1. OpenClawとは」「2. おすすめ構成」を読んでから導入してください。**
:::

:::message
**シリーズ構成**
- [Linux（Ubuntu）インストールガイド（Windows）](wsl2-windows-install-guide)
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- **🦞OpenClaw導入ガイド**
  - [DigitalOceanで安全に動かす](openclaw-setup-guide)（この記事）
  - [WSL2で無料で試してみた](openclaw-wsl2-setup-guide)
- [🦞OpenClawでDiscord/Telegramを個人AIアシスタント化する](openclaw-discord-telegram-guide)
:::

---

## 1. OpenClawとは

### 1.1 名称変更の経緯（Clawdbot → Moltbot → OpenClaw）

OpenClaw は、オーストリアの開発者 **Peter Steinberger** 氏が作成したオープンソースの自律型AIパーソナルアシスタント。

| 時期 | 名称 | 変更理由 |
|------|------|----------|
| 2025年11月〜2026年1月 | **Clawdbot (Clawd)** | 初期リリース。Claude Code のロブスターマスコットに由来 |
| 2026年1月27日〜 | **Moltbot** | Anthropic からの商標に関する要請により変更 |
| 2026年1月30日〜 | **OpenClaw** | 旧Xアカウントが乗っ取られたため再度変更。「最終形態」 |

2026年2月時点で **135,000+ GitHub スター** を獲得し、史上最速で成長したオープンソースプロジェクトの1つとなった。

> 「New shell, same lobster.」（新しい殻、同じロブスター）
> — [OpenClaw 公式](https://x.com/openclawai/status/2017505983678976021)

### 1.2 この記事を読む前に｜OpenClawは誰向けか

:::message alert
**⚠️ 重要: まずここを読んでください**
OpenClaw は強力なツールですが、すべての人に適しているわけではない。導入を検討する前に、以下の「向いている人・向いていない人」を確認すること。
:::

**向いている人：**
- セキュリティリスクを理解し、自己責任で運用できる技術者
- サンドボックス環境で AI エージェントを実験したい人
- マルチエージェントシステムを構築したい開発者

**向いていない人：**
- セキュリティ設定に自信がない人
- 本番環境や機密データがある環境で使いたい人
- 「インストールして放置」したい人

**開発者自身の言葉：**

[Peter Steinberger 氏](https://x.com/steipete)（OpenClaw 開発者）：
> 「It still isn't ready to be installed by normies, to be fair.」
> （正直なところ、まだ一般ユーザーがインストールできる状態ではない）

**セキュリティ専門家の警告：**

[Cisco セキュリティチーム](https://blogs.cisco.com/ai/personal-ai-agents-like-openclaw-are-a-security-nightmare)：
> 「From a capability perspective, OpenClaw is groundbreaking. [...] From a security perspective, it's an absolute nightmare.」
> （機能面では、OpenClawは画期的だ。[...] セキュリティ面では、完全な悪夢だ）

### 1.3 従来のAIとの違い

従来のAIアシスタント（ChatGPT、Claude.ai 等）には「継続性がない」という共通の問題があった。昨日の会話は消え、先週のリサーチはどこかに埋もれて見つからない。

OpenClawはこの問題を根本から解決する。

| 項目 | 従来のAI（ChatGPT / Claude.ai等） | OpenClaw |
|------|----------------------------------|----------|
| 記憶 | セッション終了で忘れる | **永続的なメモリを保持** |
| データ | クラウド（運営会社のサーバー） | **自分のPC/VPS（手元に残る）** |
| 動作 | 受動的（質問に答えるだけ） | **能動的（タスクを自律実行）** |
| 稼働 | 人間が常に指示 | **スケジュール実行（Cron + HeartBeat）** |
| 操作対象 | チャットUI内で完結 | **ファイルシステム + CLI + チャットアプリ** |

**一言で言うと：**
- ChatGPT/Claude.ai = 「**賢いチャットボット**」
- OpenClaw = 「**24/7稼働の自律型AIアシスタント**」

---

## 2. おすすめ構成

導入を決めた方は、以下から自分に合った構成を選ぶ。

:::message
**なぜVPSが推奨？** OpenClawの本質は「24/7稼働の自律エージェント」。[公式FAQ](https://docs.openclaw.ai/help/faq)でも「24/7の信頼性が必要ならVPSを使う」と明言されている。ローカルPC（WSL2）ではスリープ時にGatewayが停止し、メッセージを受信できない。
:::

### 2.1 構成比較表

| 構成 | コスト | 安全性 | おすすめ度 |
|------|--------|--------|------------|
| 🥇 **DigitalOcean 1-Click** | $24/月〜 | ◎（自動設定） | ⭐⭐⭐⭐⭐ |
| 🥈 Railway / その他VPS | $5〜10/月 | ○ | ⭐⭐⭐⭐ |
| 🥉 WSL2 + Docker | 無料 | ○ | ⭐⭐⭐ |

### 2.2 🥇 DigitalOcean 1-Click（この記事で解説）

**コスト**: $24/月〜 ｜ **難易度**: 低 ｜ **安全性**: ◎（自動設定）

[DigitalOcean 1-Click Deploy](https://www.digitalocean.com/community/tutorials/how-to-run-openclaw)は、以下のセキュリティ設定がすべて自動化される：

| セキュリティ項目 | 設定内容 |
|------------------|----------|
| コンテナ隔離 | Docker container isolation |
| 権限制限 | Non-root user execution |
| 認証 | Gateway token + DM pairing |
| ファイアウォール | Hardened firewall rules + Fail2ban |
| TLS暗号化 | Caddy + LetsEncrypt |

**メリット:**
- セキュリティ設定が自動化（非エンジニアの設定ミスリスクを排除）
- 24/7稼働（スリープ問題なし）
- 問題発生時は Droplet ごと削除して再構築
- 自宅PCと完全分離（個人データへのリスクなし）

**デメリット:**
- 月額 $24〜

### 2.3 🥈 Railway / その他VPS（リンクのみ）

[公式VPSリスト](https://docs.openclaw.ai/vps)に掲載されているプロバイダー：

- [Railway](https://docs.openclaw.ai/railway) - $5〜10/月、ブラウザ完結
- [Oracle Cloud Always Free](https://docs.openclaw.ai/platforms/oracle) - 無料
- [Hetzner](https://docs.openclaw.ai/platforms/hetzner) - €3.49/月〜

セキュリティ設定は手動で行う必要がある。[公式セキュリティガイド](https://docs.openclaw.ai/gateway/security)を参照。

### 2.4 🥉 WSL2 + Docker（別記事へ）

まず無料で試したい場合は、[OpenClaw（旧Clawdbot）をWSL2で無料で試してみた](openclaw-wsl2-setup-guide)を参照。

---

## 3. DigitalOcean 1-Clickでのインストール

[公式チュートリアル](https://www.digitalocean.com/community/tutorials/how-to-run-openclaw)に基づく手順。

### Step 1: DigitalOceanアカウント作成

1. [DigitalOcean](https://www.digitalocean.com/) にアクセス
2. アカウントを作成（クレジットカードまたはPayPalが必要）

### Step 2: 1-Clickイメージからdroplet作成

1. [DigitalOcean Marketplace](https://marketplace.digitalocean.com/) で「**OpenClaw**」または「**Moltbot**」で検索
2. 1-Click イメージを選択

:::message
**検索名について**: Marketplace上のイメージ名は時期により異なる場合がある。最新の名称は[公式チュートリアル](https://www.digitalocean.com/community/tutorials/how-to-run-openclaw)で確認。
:::

**推奨スペック:**
- **4GB RAM / 2 vCPU**（$24/月〜）
- リージョン: 自分に近い場所を選択

### Step 3: SSH接続

Droplet作成後、SSHで接続：

```bash
ssh root@<your-droplet-ip>
```

:::message
**SSHとは**
Secure Shell の略。リモートのサーバーに安全に接続するためのプロトコル。DigitalOceanのDropletを操作するために必要。
:::

### Step 4: 初期設定ウィザード

接続後、自動で初期設定ウィザードが起動する。画面の指示に従って進める。

### Step 5: AIプロバイダーの設定

OpenClaw で Claude を使用するには、以下の2つの認証方法がある。

| 方法 | 対象 | 料金体系 | 推奨度 |
|------|------|----------|--------|
| **API Key** | 全ユーザー | 従量課金（トークン単位） | ⭐⭐⭐⭐⭐ **推奨** |
| **setup-token** | Claude Pro/Max契約者 | サブスクリプション内 | ⚠️ ToS問題あり |

[OpenClaw公式ドキュメント](https://docs.openclaw.ai/gateway/authentication)では「For Anthropic accounts, we recommend using an **API key**.」と明記されている。

#### 方法1: API Key（推奨）

1. [Anthropic Console](https://console.anthropic.com/) でAPI Keyを作成
2. 初期設定ウィザードでAPI Keyを入力

**API料金（2026年1月時点）:**

| モデル | 入力 | 出力 | 推奨用途 |
|--------|------|------|----------|
| Claude Opus 4.5 | $5/百万トークン | $25/百万トークン | 最高性能、複雑な推論 |
| Claude Sonnet 4.5 | $3/百万トークン | $15/百万トークン | バランス、コーディング |
| Claude Haiku 4.5 | $1/百万トークン | $5/百万トークン | 高速、低コスト |

:::message
**コスト目安**: 使用量により大きく変動するが、1日30分程度の使用で月$10〜$50程度が目安。
:::

#### 方法2: setup-token（Claude Pro/Max契約者向け）

:::message alert
**⚠️ ToS違反のリスク**
2026年1月9日、Anthropicは第三者ツールでのOAuth使用を技術的にブロックした。OpenClawでsetup-tokenを使用すると「This credential is only authorized for use with Claude Code」エラーが発生する場合があり、**最悪の場合アカウント停止のリスク**がある。**API Keyの使用を強く推奨。**
:::

Claude Pro/Max契約者は`claude setup-token`コマンドでトークンを生成できる：

```bash
# Claude Code CLIでトークンを生成（別のターミナルで）
claude setup-token

# 表示されたトークンを初期設定ウィザードに入力
```

### Step 6: 動作確認

```bash
# 全体の状態確認
openclaw status --all

# ヘルスチェック
openclaw health
```

**出力例:**

```
✓ Gateway: running on ws://127.0.0.1:18789
✓ Agent: idle
✓ Channels: telegram (connected)
```

:::message
セキュリティ設定（Docker隔離・非root実行・ファイアウォール・Fail2ban・TLS）はすべて自動で構成済み。手動設定は不要。
:::

---

## 4. セキュリティ確認

DigitalOcean 1-Clickで自動設定される項目の確認方法。

### 自動設定の確認

```bash
# セキュリティ監査
openclaw security audit

# 詳細な監査（Gateway への接続テスト含む）
openclaw security audit --deep
```

### チェックリスト

**【DigitalOcean 1-Click の場合】自動設定の確認:**
- [ ] Droplet 作成完了
- [ ] [公式チュートリアル](https://www.digitalocean.com/community/tutorials/how-to-run-openclaw)の手順に従った
- [ ] Gateway が起動している（`openclaw status --all`）
- [ ] Moltbook に接続していない（セキュリティリスク）

### 緊急時の対応

問題が発生した場合：

```bash
# 1. Gateway を停止
openclaw gateway stop

# 2. ログ確認
openclaw logs

# 3. 問題解決しない場合は Droplet を削除して再構築
```

---

## 次のステップ

### Discord/Telegram連携

OpenClawをDiscordやTelegramから操作できるようにする：
- [🦞OpenClawでDiscord/Telegramを個人AIアシスタント化する](openclaw-discord-telegram-guide)

### WSL2で無料で試す

VPSの契約前に、まず無料で試したい場合：
- [🦞OpenClaw（旧Clawdbot）をWSL2で無料で試してみた](openclaw-wsl2-setup-guide)

---

## 参考リンク

- [OpenClaw 公式サイト](https://openclaw.ai/)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [公式ドキュメント](https://docs.openclaw.ai/)
- [公式VPSプロバイダーリスト](https://docs.openclaw.ai/vps)
- [DigitalOcean 1-Click チュートリアル](https://www.digitalocean.com/community/tutorials/how-to-run-openclaw)
- [DigitalOcean 技術解説ブログ](https://www.digitalocean.com/blog/technical-dive-openclaw-hardened-1-click-app)
- [セキュリティガイド](https://docs.openclaw.ai/gateway/security)

---

## 関連記事

- [Linux（Ubuntu）インストールガイド（Windows）](wsl2-windows-install-guide)
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ](claude-code-tips-and-features)
