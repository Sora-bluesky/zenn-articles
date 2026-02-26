---
title: "OpenClawをWSL2で無料で試してみた"
emoji: "🦞"
type: "tech"
topics: ["openclaw", "ai", "wsl2", "docker", "windows"]
published: true
---

:::message alert
OpenClawは強力だが、セキュリティ対策なしに使うと危険。「セキュリティ対策」を読んでから利用してほしい。
:::

:::message
**シリーズ構成**
- [Linux（Ubuntu）インストールガイド（Windows）](wsl2-windows-install-guide)
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- 🦞OpenClaw導入ガイド
  - [XServer VPSで安全に動かす](openclaw-setup-guide)
  - [WSL2で無料で試してみた](openclaw-wsl2-setup-guide)（この記事）
- [🦞OpenClawでDiscord/LINEを個人AIアシスタント化する](openclaw-sns-guide)
:::

---

## この記事の位置づけ

OpenClawの本質は「24/7稼働の自律エージェント」で、[公式FAQ](https://docs.openclaw.ai/help/faq)でもVPSが推奨されている。この記事は「まず無料で触ってみたい人」向けのローカル環境構築ガイド。

気に入ったらVPSに移行する流れを想定している：
- [OpenClaw × XServer VPS：月990円でAIが24時間働く環境を作った](openclaw-setup-guide)

---

## WSL2 + Docker構成の特徴

| 利点 | 欠点 |
|------|------|
| 無料で使える | スリープ時にGatewayが停止する |
| 公式推奨の構成（Windowsローカル環境として） | 自宅PCにOpenClawが同居するリスク |
| Docker sandboxで隔離できる | セキュリティ設定は手動 |

### スリープ時の挙動

:::message alert
[公式FAQ](https://docs.openclaw.ai/help/faq)の原文：「sleep/network drops = disconnects」「must stay awake」

スリープするとGatewayが止まり、WhatsAppやTelegram等との接続が切れる。スリープ中はメッセージを受信できない。
:::

公式FAQの推奨：

> 「Short answer: if you want 24/7 reliability, use a VPS. If you want the lowest friction and you're okay with sleep/restarts, run it locally.」
> （24/7の信頼性が必要ならVPSを使え。最小限の手間でスリープ/再起動を許容できるなら、ローカルで）

| ユースケース | 対応 |
|--------------|------|
| 24/7メッセージを受信したい | VPSを使う（[XServer VPS編](openclaw-setup-guide)を参照） |
| 作業中だけ使えればいい | ラップトップで十分（スリープ許容） |
| ラップトップで常時稼働したい | Windowsの電源設定で「スリープ: なし」に変更 |

---

## 動作環境

| 項目 | 要件 |
|------|------|
| OS | Windows 10 Build 19041+ / Windows 11 |
| WSL2 | 必須（PowerShellネイティブは非対応） |
| Node.js | 22.12.0 以上 |
| Docker Desktop | 必須（sandbox用） |
| RAM | 8GB以上推奨 |
| ストレージ | 20GB以上の空き |

:::message alert
Node.js 22以上が必要。多くの環境にはNode.js 18や20が入っている。nvm（Node.jsのバージョン管理ツール）でのバージョン管理を推奨。
:::

### なぜWSL2が必要か

[公式ドキュメント](https://docs.openclaw.ai/platforms/windows)に「WSL2 is strongly recommended; native Windows is untested, more problematic, and has poorer tool compatibility」と明記されている。

PowerShellネイティブは「untested and more problematic」。依存関係がLinux前提の設計なので、WSL2を使うのが確実。

---

## WSL2でのインストール

### WSL2のセットアップ

既にWSL2を使っている場合はスキップ。詳細は [Linux（Ubuntu）インストールガイド](wsl2-windows-install-guide) を参照。

管理者PowerShellで：

```powershell
wsl --install -d Ubuntu-24.04
```

インストール後、PCを再起動。再起動後にUbuntuが自動起動するので、ユーザー名とパスワードを設定する。

### Docker Desktopのインストール

1. [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/) をダウンロード・インストール
2. インストール時に「WSL 2 backend」を選択
3. Docker Desktop を起動し、Settings → Resources → WSL Integration で Ubuntu-24.04 を有効化
4. Apply & Restart

Ubuntuターミナルで動作確認：

```bash
docker --version
docker run hello-world
```

### Node.js 22のインストール

WSL2のUbuntu内で実行する。

現在のバージョンを確認：

```bash
node --version
```

`v22.x.x` 以上ならOK。それ以外の場合は以下でインストール。

:::message
nvmはNode Version Managerの略。複数のNode.jsバージョンを切り替えて使えるツール。
:::

```bash
# nvmのインストール（未導入の場合）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
source ~/.bashrc

# Node.js 22のインストール
nvm install 22
nvm use 22
nvm alias default 22  # デフォルトに設定

# 確認
node --version
# → v22.x.x と表示されればOK
```

### OpenClawのインストール

npmのグローバルディレクトリ設定（権限エラー回避）：

```bash
# グローバルパッケージ用ディレクトリを作成
mkdir -p ~/.npm-global

# npmの設定を変更
npm config set prefix ~/.npm-global

# PATHに追加（コマンドを探す場所のリストに追加）
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

OpenClawのインストール：

```bash
npm install -g openclaw@latest
```

インストール確認：

```bash
openclaw --version
```

:::message
警告（deprecated packages）が出ることがあるが、動作に影響はない。無視して進める。
:::

### セットアップウィザード

OpenClawのインストールが終わったら、ウィザードでAIプロバイダーとチャット連携を一括設定する。

:::message
ウィザード実行前にAPI Keyを用意しておく。[Anthropic Console](https://console.anthropic.com/) でAPI Keyを作成する（[OpenClaw公式](https://docs.openclaw.ai/gateway/authentication)でAPI Key推奨と明記されている）。Discord Botも先に作成しておくと、ウィザードがスムーズに進む（[Discord/LINE連携ガイド](openclaw-sns-guide) の「Discord Botを作成する」を参照）。
:::

:::message alert
2026年1月9日、Anthropicは第三者ツールでのOAuth使用を完全にブロック済み。setup-tokenを使うと「This credential is only authorized for use with Claude Code」エラーで接続できず、最悪アカウント停止になる。API Keyを使うこと。
:::

```bash
openclaw onboard --install-daemon
```

ウィザードでは以下の順に聞かれる：

1. セキュリティ同意 → 内容を確認し「Yes」
2. Onboarding mode → 「QuickStart」を選択
3. LLMプロバイダー選択 → 「Anthropic」→「API Key」
4. API Key入力 → Anthropic ConsoleのAPI Keyを入力
5. モデル選択 → 任意のモデルを選択
6. チャットプラットフォーム → 「Discord」を選択（LINEは別途プラグインで設定）
7. Botトークン入力 → 事前に作成したBotトークンを入力
8. チャンネル権限 → 「Allowlist」推奨

API料金の目安（2026年2月時点）：

| モデル | 入力 | 出力 | 用途 |
|--------|------|------|------|
| Claude Opus 4.6 | $15/百万トークン | $75/百万トークン | 最高性能・複雑な推論 |
| Claude Opus 4.5 | $5/百万トークン | $25/百万トークン | 複雑な推論 |
| Claude Sonnet 4.5 | $3/百万トークン | $15/百万トークン | コーディング |
| Claude Haiku 4.5 | $1/百万トークン | $5/百万トークン | 高速・低コスト |

:::message
使用量により大きく変わるが、1日30分程度の利用で月$10〜$50程度が目安。
:::

### 動作確認

```bash
openclaw status --all
openclaw doctor
```

出力例：

```
✓ Gateway: running on ws://127.0.0.1:18789
✓ Agent: idle
✓ Channels: discord (connected)
```

---

## セキュリティ対策

:::message alert
この対策は全員必須。onboardウィザードで基本設定は済んでいるが、以下の項目を `~/.openclaw/openclaw.json` で確認・追加する。
:::

:::message
`~/.openclaw/openclaw.json` はonboardウィザードが自動生成する設定ファイル。直接編集してカスタマイズできる。WSL2のUbuntuターミナルから `nano ~/.openclaw/openclaw.json` で開ける。
:::

### Gateway認証の確認

`~/.openclaw/openclaw.json` に以下の設定があることを確認する：

```json
{
  "gateway": {
    "bind": "loopback",
    "auth": {
      "mode": "token"
    }
  },
  "channels": {
    "discord": {
      "dmPolicy": "pairing"
    }
  }
}
```

| 設定項目 | 説明 |
|----------|------|
| `gateway.bind: "loopback"` | ローカルのみアクセス可（必須） |
| `gateway.auth.mode: "token"` | トークン認証を有効化（必須。v2026.1.29で`"none"`は廃止済み） |
| `dmPolicy: "pairing"` | DM送信者を承認制に（推奨） |

### Docker sandbox設定

`~/.openclaw/openclaw.json` に追加：

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

エージェントのbashコマンドがDockerコンテナ内で実行されるようになる。コンテナが壊れてもホスト（WSL2）は無傷。問題が起きたらコンテナを削除して再構築すればいい。

### 専用アカウントの作成

OpenClawには専用のGoogleアカウントを作る。本番アカウントは絶対に使わないこと。

:::message alert
**2026年2月 実例**
2026年2月22-23日、OpenClaw経由でGoogle Antigravityを利用していたユーザーのGoogleアカウント全体（Gmail、YouTube、Workspace含む）が警告なしに停止された。**本番のGoogleアカウントでOpenClawを使うことは絶対に避けるべき。**
:::

---

## トラブルシューティング

### npmグローバルインストールの権限エラー

```
npm error EACCES: permission denied, mkdir '/usr/lib/node_modules/...'
```

```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### Node.js バージョンが古い

起動時にバージョンエラーが出る場合：

```bash
nvm install 22
nvm use 22
nvm alias default 22
```

### PATHにスペースが含まれる問題

```
export: `Files/Git/mingw64/bin:...': not a valid identifier
```

```bash
# ログインシェルとして実行
bash -lc "openclaw --version"
```

### 429エラー（レート制限）

```
LLM error: {"error": {"code": 429, "message": "Resource has been exhausted..."}}
```

1. しばらく待つ（API利用制限は時間経過でリセット）
2. 軽量モデルに変更する（制限に余裕がある場合が多い）
3. 翌日まで待つ（日次クォータは毎日リセット）

### モデル変更が反映されない

`openclaw configure` でモデルを変更したのに反映されない場合は、Gatewayを再起動する：

```bash
systemctl --user restart openclaw-gateway.service

# 設定を確認
cat ~/.openclaw/openclaw.json | grep -i model
```

### Dockerが起動しない

1. Docker Desktop が起動しているか確認
2. WSL Integration が有効か確認（Settings → Resources → WSL Integration）
3. Docker Desktop を再起動

---

## 導入前チェックリスト

WSL2 + Docker の場合：

- [ ] WSL2 + Ubuntu インストール済み
- [ ] Docker Desktop インストール済み
- [ ] Node.js 22 インストール済み
- [ ] `gateway.bind: "loopback"` 設定済み
- [ ] `gateway.auth.mode: "token"` 設定済み
- [ ] `dmPolicy: "pairing"` 設定済み
- [ ] 専用アカウントを使用（本番アカウント使用禁止）
- [ ] `sandbox.mode: "non-main"` 設定済み
- [ ] Moltbookに接続していない（Moltbookは旧名称時代のWebダッシュボード。Gateway認証なしでインターネットに公開されるリスクがある）

---

## 次はどうするか

### Discord/LINE連携

OpenClawをDiscordやLINEから操作する：
- [OpenClawでDiscord/LINEを個人AIアシスタント化する](openclaw-sns-guide)

### VPSへの移行

ローカルで試して気に入ったらVPSへ。24/7稼働なら：
- [OpenClaw × XServer VPS：月990円でAIが24時間働く環境を作った](openclaw-setup-guide)

---

## 参考リンク

- [OpenClaw 公式サイト](https://openclaw.ai/)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [公式ドキュメント](https://docs.openclaw.ai/)
- [Windows (WSL2) ガイド](https://docs.openclaw.ai/platforms/windows)
- [セキュリティガイド](https://docs.openclaw.ai/gateway/security)

---

## 関連記事

- [Linux（Ubuntu）インストールガイド（Windows）](wsl2-windows-install-guide)
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ](claude-code-tips-and-features)
