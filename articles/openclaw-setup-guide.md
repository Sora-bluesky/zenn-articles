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
| 稼働 | 人間が常に指示 | スケジュール実行（定期的な自動実行 + 死活監視） |
| 操作対象 | チャットUI内で完結 | ファイルシステム + コマンド操作 + チャットアプリ |

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

### 1. アプリイメージのインストール

1. [XServer VPS](https://vps.xserver.ne.jp/) にアクセス
2. XServerアカウントを作成（クレジットカードが必要）
3. VPS申し込み画面で「イメージタイプ」→「アプリケーション」タブ→「OpenClaw」を選択

プランはお試しなら[無料プラン](https://vps.xserver.ne.jp/free.php)（4GB RAM / 3 vCPU / 30GB SSD）、安定運用なら2GBプラン（¥990/月〜）以上。

:::message
アプリイメージを選択するだけで、OpenClawが自動でインストール・構築される。Node.jsのインストールやnpm操作は不要。
:::

### 2. 事前準備

#### IPアドレスとrootパスワードの確認

VPS構築が完了したら（通常5〜10分）、VPSパネルでIPアドレスとrootパスワードを確認しておく。この後のSSH接続で使う。

1. [VPSパネル](https://secure.xserver.ne.jp/xapanel/login/xvps/)にログイン
2. 対象VPSを選択
3. 「VPS情報」タブにIPアドレスが表示されている（例: `198.51.100.1`）
4. rootパスワードはVPS申し込み時に自分で設定したもの

:::message
rootパスワードを忘れた場合は、VPSパネルから「rootパスワードの再設定」ができる。
:::

#### パケットフィルターの確認

:::message alert
[XServer VPS公式のOpenClaw告知](https://vps.xserver.ne.jp/support/news_detail.php?view_id=17624)で、パケットフィルター有効化が強く推奨されている。設定不備があると、OpenClawのダッシュボードが第三者からアクセスされるリスクがある。
:::

パケットフィルターはVPSへの通信で、接続を許可するポートを制限する機能。VPSパネルで以下を確認する。

**確認手順：**

1. [VPSパネル](https://secure.xserver.ne.jp/xapanel/login/xvps/)にログイン
2. 対象VPSを選択
3. 左サイドメニューの「パケットフィルター設定」をクリック
4. 「ONにする（推奨）」にチェックが入っていることを確認
5. フィルタールール一覧に「SSH（TCP 22）」があることを確認

:::message
デフォルトでONになっている。変更していなければ問題ない。もしOFFにしてしまった場合は「ONにする（推奨）」に戻し、「変更する」ボタンをクリックする。
:::

OpenClawの利用ではSSH（TCP 22）以外のポート開放は不要。他のアプリ（Difyなど）で80番や443番を開放している場合、OpenClawのGateway（18789番）が意図せずインターネットに露出しないか注意する。

**フィルタールールの追加方法：**

1. 「パケットフィルター設定を追加する」をクリック
2. フィルターで「SSH」を選択
3. 「追加する」をクリック

手動で特定IPからのみ許可する場合は「手動で設定」を選び、プロトコル・ポート番号・許可する送信元IPアドレスを指定する。フィルタールールは最大20個まで設定可能。

#### AIプロバイダーの設定

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

#### チャットサービスBot/ツールの準備

セットアップウィザードでBotトークンの入力を求められるため、事前にDiscord Botを作成しておく必要がある。

1. [Discord Developer Portal](https://discord.com/developers/docs/intro) でアプリケーションを作成
2. 「Bot」メニューでトークンを発行し、コピーして控えておく
3. 「Privileged Gateway Intents」の「Message Content Intent」をONにする
4. 「OAuth2」→「URL Generator」で `bot` にチェックし、生成されたURLからBotをサーバーに招待する

:::message
詳しい手順は [Discord/LINE連携ガイド](openclaw-sns-guide) の「1. アプリケーションを作成する」以降、または [XServer VPS公式マニュアル](https://vps.xserver.ne.jp/support/manual/man_server_app_use_openclaw.php) を参照。
:::

### 3. セットアップ

#### SSH接続とセットアップウィザード

VPSにSSH接続する。WindowsのPowerShellを開いて以下を入力する。

:::message
PowerShellの開き方: Windowsキーを押して「powershell」と入力し、「Windows PowerShell」をクリック。
:::

```powershell
ssh root@<VPSのIPアドレス>
```

`<VPSのIPアドレス>` は先ほどVPSパネルで確認したIPアドレスに置き換える（例: `ssh root@198.51.100.1`）。

初回接続時は以下のような確認が出る：

```
The authenticity of host '198.51.100.1' can't be established.
ED25519 key fingerprint is SHA256:xxxxx...
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

`yes` と入力してEnter。これは「このサーバーを信頼しますか？」という確認で、初回のみ表示される。

パスワードを聞かれるので、VPS申し込み時に設定したrootパスワードを入力する（入力中は画面に何も表示されないが、正常な動作）。

:::message
SSH（Secure Shell）はリモートサーバーに安全に接続するための通信方式。VPSパネルの「コンソール」からも操作できる。
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
7. Botトークン入力 → 事前準備で控えたBotトークンを入力
8. チャンネル権限 → 「Allowlist」を選択し、対象のサーバー名/チャンネル名を入力
9. 追加設定 → 「No」を選択（後から変更可能）
10. Bot起動 → 「Do this later（後でやる）」を選択。管理画面を使わなくても、DiscordからBotに話しかけて操作できる
11. 自動補完有効化 → 「Yes」を選択

:::message
Allowlistは、OpenClawが反応するチャンネルを限定する設定。既に運用中のDiscordサーバーにBotを追加するなら、意図しないチャンネルでの動作を防ぐためにも設定しておきたい。
:::

#### ペアリング承認

ウィザード完了後、DiscordでBotにメンションすると初回はペアリングコードが表示される。VPS側で以下を実行して承認する。

```bash
openclaw pairing approve discord <code>
```

`<code>` にはDiscord側に表示されたペアリングコードを入力する。承認が完了すると、Botとの通常のやり取りが可能になる。

DiscordでBotにメンション（`@Bot名 こんにちは`）を送り、AIから返信が来れば連携成功。

#### 動作確認

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

### 4. ダッシュボード接続（任意）

OpenClawのWeb UI（ダッシュボード）にはSSHトンネル経由でアクセスする。ダッシュボードはインターネットに直接公開してはいけない。

:::message
**SSHトンネルとは**
VPSの特定のポート（この場合18789番）を、自分のPC経由でだけアクセスできるようにする技術。イメージとしては「自分のPCからVPSまでの秘密のトンネルを掘る」感覚。トンネルを通さないと管理画面は見えないので、インターネットから直接アクセスされる心配がない。
:::

**方法1：PowerShell / ターミナルから（推奨）**

```powershell
# SSHトンネルを開通する（このウィンドウは開いたままにする）
ssh -N -L 18789:localhost:18789 root@<VPSのIPアドレス>
```

`-N` はコマンドを実行せずトンネルだけ維持するオプション。このウィンドウを閉じるとトンネルも切れる。

別のターミナルを開いてVPSにSSH接続し、ダッシュボードURLを取得：

```bash
openclaw dashboard
```

表示されたURLをブラウザで開く。`http://localhost:18789/...` のようなURLになる。

**方法2：Tera Termから**

1. Tera TermでVPSにSSH接続
2. メニューの「設定」→「SSH転送」を開く
3. 「追加」をクリック
4. 以下を入力：
   - ローカルのポート：`18789`
   - リモート側ホスト：`localhost`
   - ポート：`18789`
5. 「OK」をクリック
6. ブラウザで `http://localhost:18789` にアクセス

**方法3：SSH configで自動化**

後述の「セキュリティ強化」セクションにある「SSH接続を簡略化する」でSSH configを設定すると、`ssh xserver-vps-tunnel` だけでトンネルが開通するようになる。先にセキュリティ強化を済ませてからここに戻ってくると便利。

:::message alert
Gateway（18789番ポート）をパケットフィルターで外部に開放しないこと。SSHトンネル経由なら、パケットフィルターはSSH（22番）だけ開放すれば十分。
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

### XServer VPS と DigitalOcean のセキュリティ比較

| セキュリティ項目 | DO 1-Click | XServer VPS |
|---|---|---|
| Docker隔離 | 自動 | 手動（下記で設定） |
| 非rootユーザー実行 | 自動 | 手動（マニュアルに案内あり） |
| Gateway認証 + DMペアリング | 自動 | 半自動（onboard時に設定） |
| ファイアウォール + Fail2ban | 自動 | 部分自動（パケットフィルターのみ） |
| TLS暗号化（Caddy + LE） | 自動 | 不要（SSHトンネル前提） |

:::message
**XServer VPSの設計上の利点**: XServer VPSではWeb UI（ダッシュボード）をインターネットに公開せず、SSHトンネル経由のローカルアクセスのみを推奨している。2026年初頭にOpenClawのControl UIに[RCE脆弱性（CVE-2026-25253）](https://adversa.ai/blog/openclaw-security-101-vulnerabilities-hardening-2026/)が報告され、インターネットに露出した[42,000件以上のインスタンス](https://www.digitalocean.com/blog/technical-dive-openclaw-hardened-1-click-app)が影響を受けた。SSHトンネル前提の設計はWeb UIが外部に露出しないため、この種の脆弱性の影響を受けにくい。
:::

DigitalOceanのようなフル自動セキュリティが必要なら、Docker/Fail2ban/Caddyの手動インストールも可能。詳細は[OpenClaw公式セキュリティガイド](https://docs.openclaw.ai/gateway/security)と[DigitalOcean技術解説ブログ](https://www.digitalocean.com/blog/technical-dive-openclaw-hardened-1-click-app)を参照。

---

## セキュリティ強化

OpenClawが動いたら、次はセキュリティを固める。

### 公開鍵認証に切り替える

:::message alert
XServer VPSの公開データによると、VPS公開後1時間で約400件の不正アクセスが発生し、その69.2%がrootユーザーへの攻撃。パスワード認証はブルートフォース攻撃（総当たり攻撃）で突破されるリスクがあるため、公開鍵認証への切り替えを推奨する。
:::

Windows PowerShellで以下を実行する。

```powershell
# 鍵ペアの生成（Ed25519推奨）
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\xserver-vps-key
```

`Enter passphrase` と聞かれたら、そのままEnter（空パスフレーズ）でよい。パスフレーズを設定するとSSH接続のたびに追加入力が必要になる。

```powershell
# 公開鍵をVPSに転送（rootパスワードを求められる）
type $env:USERPROFILE\.ssh\xserver-vps-key.pub | ssh root@<VPSのIPアドレス> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
```

鍵認証で接続できることを確認：

```powershell
ssh -i $env:USERPROFILE\.ssh\xserver-vps-key root@<VPSのIPアドレス>
```

パスワードなしでログインできれば成功。

### SSH接続を簡略化する

毎回長いコマンドを打つのは面倒なので、`~/.ssh/config` に設定を書いておく。

```powershell
# configファイルを作成（または追記）
notepad $env:USERPROFILE\.ssh\config
```

メモ帳が開くので、以下を入力して保存：

```
Host xserver-vps
    HostName <VPSのIPアドレス>
    User root
    IdentityFile ~/.ssh/xserver-vps-key
    Port 22
```

以降は `ssh xserver-vps` だけで接続できるようになる。

ダッシュボード用のSSHトンネル設定も一緒に書いておくと便利：

```
Host xserver-vps-tunnel
    HostName <VPSのIPアドレス>
    User root
    IdentityFile ~/.ssh/xserver-vps-key
    LocalForward 18789 127.0.0.1:18789
```

`ssh xserver-vps-tunnel` でトンネルも自動開通する。

### Docker sandboxでエージェントを隔離する

:::message alert
**なぜ必要か**: OpenClawの `sandbox.mode` は[デフォルトで「off」](https://docs.openclaw.ai/gateway/security)。この状態では、Discordから送られた指示がVPSのホストOS上で**直接実行**される。悪意ある指示（ファイル削除、情報窃取など）がそのままVPSに影響する。Docker sandboxを有効にすれば、エージェントのコマンドがDockerコンテナ内で隔離実行され、ホストOSを保護できる。
:::

:::message
[DigitalOcean 1-Click](https://www.digitalocean.com/blog/technical-dive-openclaw-hardened-1-click-app)ではDocker隔離が自動で構成されるが、XServer VPSアプリイメージにはDockerが含まれない。手動でインストールする。
:::

SSH接続中のVPSで実行：

```bash
# Dockerのインストール
apt install -y docker.io
systemctl enable docker && systemctl start docker
```

`~/.openclaw/openclaw.json`（`~` はホームディレクトリの省略記号で、Linuxでは `/home/ユーザー名/` にあたる）にsandbox設定を追加：

```bash
nano ~/.openclaw/openclaw.json
```

（nanoの操作方法: 編集が終わったら `Ctrl+O` → Enter で保存、`Ctrl+X` で終了）

```json
{
  "agents": {
    "defaults": {
      "sandbox": {
        "mode": "non-main"
      }
    }
  }
}
```

| sandbox.mode | 動作 |
|---|---|
| `"off"`（デフォルト） | 全コマンドがホストで直接実行（危険） |
| `"non-main"` | グループ/チャネルはDocker内、個人DMはホスト |
| `"all"` | 全コマンドがDocker内で実行（最も安全） |

Gatewayを再起動して反映：

```bash
systemctl --user restart openclaw-gateway.service
```

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

- [ ] パケットフィルターが「ON」（[VPSパネル](https://secure.xserver.ne.jp/xapanel/login/xvps/) → パケットフィルター設定で確認）
- [ ] SSH（TCP 22）以外の不要ポートを開放していない
- [ ] 公開鍵認証を使用している（パスワード認証は非推奨）
- [ ] Gateway認証が有効（トークンまたはパスワード）
- [ ] ダッシュボードにはSSHトンネル経由でアクセスしている（18789番を直接開放していない）
- [ ] Docker sandboxが有効（`sandbox.mode: "non-main"` 以上）
- [ ] チャンネル権限を「Allowlist」に設定
- [ ] Moltbookに接続していない（Moltbookは旧名称「Moltbot」時代のクラウドダッシュボード。現在は非推奨で、Gateway認証なしでインターネットに公開されるリスクがある。名称変更の経緯は記事冒頭を参照）

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
- [XServer VPS OpenClaw追加のお知らせ（セキュリティ注意事項）](https://vps.xserver.ne.jp/support/news_detail.php?view_id=17624)
- [XServer VPS パケットフィルター設定](https://vps.xserver.ne.jp/support/manual/man_server_port.php)
- [XServer VPS SSH接続方法](https://vps.xserver.ne.jp/support/manual/man_server_ssh_connect.php)
- [XServer VPS 契約直後のセキュリティ対策](https://vps.xserver.ne.jp/vps-media/initial-security/)
- [XServer VPS 料金プラン](https://vps.xserver.ne.jp/price.php)
- [XServer VPS 無料VPS](https://vps.xserver.ne.jp/free.php)
- [DigitalOcean 1-Click チュートリアル](https://www.digitalocean.com/community/tutorials/how-to-run-openclaw)
- [DigitalOcean 技術解説ブログ](https://www.digitalocean.com/blog/technical-dive-openclaw-hardened-1-click-app)
- [セキュリティガイド](https://docs.openclaw.ai/gateway/security)
- [Sandboxing（公式）](https://docs.openclaw.ai/gateway/sandboxing)
- [DigitalOcean Marketplace - OpenClaw](https://docs.digitalocean.com/products/marketplace/catalog/openclaw/)
- [OpenClaw Security 101（adversa.ai）](https://adversa.ai/blog/openclaw-security-101-vulnerabilities-hardening-2026/)

---

## 関連記事

- [Linux（Ubuntu）インストールガイド（Windows）](wsl2-windows-install-guide)
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ](claude-code-tips-and-features)
