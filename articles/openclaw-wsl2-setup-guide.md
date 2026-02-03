---
title: "OpenClaw（旧Clawdbot）をWSL2で無料で試してみた"
emoji: "🦞"
type: "tech"
topics: ["openclaw", "ai", "wsl2", "docker", "windows"]
published: false
---

## はじめに

この記事では、OpenClaw（旧Clawdbot/Moltbot）をWindows環境（WSL2）に導入する手順を解説する。

:::message
**この記事の位置づけ**
OpenClawの本質は「24/7稼働の自律エージェント」のため、[公式FAQ](https://docs.openclaw.ai/help/faq)では**VPS推奨**。この記事は「まず無料で試したい人」向けのローカル環境構築ガイド。
:::

:::message alert
**⚠️ セキュリティ警告**
OpenClaw は強力なツールですが、適切なセキュリティ対策なしに使用すると重大なリスクがあります。**必ず「4. セキュリティ対策【必須】」を読んでから利用してください。**
:::

:::message
**シリーズ構成**
- [Linux（Ubuntu）インストールガイド（Windows）](wsl2-windows-install-guide)
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- **🦞OpenClaw導入ガイド**
  - [DigitalOceanで安全に動かす](openclaw-setup-guide)
  - [WSL2で無料で試してみた](openclaw-wsl2-setup-guide)（この記事）
- [🦞OpenClawでDiscord/Telegramを個人AIアシスタント化する](openclaw-discord-telegram-guide)
:::

---

## 1. WSL2 + Docker構成の特徴

### 1.1 メリット・デメリット

| メリット | デメリット |
|----------|------------|
| 無料で利用可能 | スリープ時にGatewayが停止 |
| 公式推奨の構成（Windowsローカル環境として） | 自宅PCにOpenClawが同居するリスク |
| Docker sandboxによる隔離 | セキュリティ設定は手動 |

### 1.2 スリープ時の挙動

:::message alert
**⚠️ スリープ時の挙動**
[公式FAQ](https://docs.openclaw.ai/help/faq)によると：「**sleep/network drops = disconnects**」「**must stay awake**」

スリープすると Gateway が停止し、WhatsApp/Telegram 等との接続が切断される。**スリープ中はメッセージを受信できない。**
:::

**公式FAQの推奨:**

> 「**Short answer: if you want 24/7 reliability, use a VPS. If you want the lowest friction and you're okay with sleep/restarts, run it locally.**」
> （24/7の信頼性が必要ならVPSを使う。最小限の手間でスリープ/再起動を許容できるなら、ローカルで実行）

| ユースケース | 推奨対応 |
|--------------|----------|
| **24/7メッセージを受信したい** | VPS を使う（[DigitalOcean編](openclaw-setup-guide)を参照） |
| **作業中だけ使えればよい** | ラップトップで OK（スリープ許容） |
| **ラップトップで常時稼働したい** | Windows の電源設定で「スリープ: なし」に変更 |

### 1.3 24/7稼働が必要な場合はVPSへ

ローカル環境で試して気に入った場合は、VPSへの移行を検討：
- [🦞OpenClaw（旧Clawdbot）をDigitalOceanで安全に動かす](openclaw-setup-guide)

---

## 2. 動作環境

### 必要要件

| 項目 | 要件 |
|------|------|
| OS | Windows 10 Build 19041+ / Windows 11 |
| WSL2 | 必須（PowerShellネイティブは非対応） |
| Node.js | **22.12.0 以上**（重要） |
| Docker Desktop | 必須（sandbox用） |
| RAM | 8GB以上推奨 |
| ストレージ | 20GB以上の空き |

:::message alert
**重要: Node.js 22以上が必要**
多くの環境ではNode.js 18や20が入っている。OpenClawは22以上を要求するので、nvm（Node.jsのバージョン管理ツール）でのバージョン管理を推奨。
:::

### なぜWSL2が必要か

[公式ドキュメント](https://docs.openclaw.ai/platforms/windows)で「WSL2 is **strongly recommended**; native Windows is untested, more problematic, and has poorer tool compatibility」と明記されている。

- PowerShellネイティブは「untested and more problematic」
- 依存関係がLinux前提の設計
- 将来のアップデートでも安定動作が期待できる

---

## 3. WSL2でのインストール

### Step 1: WSL2のセットアップ

既にWSL2を使っている場合はスキップ。

詳細な手順は [Linux（Ubuntu）インストールガイド](wsl2-windows-install-guide) を参照。

**最小手順（管理者PowerShell）:**

```powershell
wsl --install -d Ubuntu-24.04
```

インストール後、PCを再起動。

再起動後、Ubuntu が自動で起動する。ユーザー名とパスワードを設定。

### Step 2: Docker Desktopのインストール

1. [Docker Desktop for Windows](https://docs.docker.com/desktop/setup/install/windows-install/) をダウンロード・インストール
2. インストール時に「WSL 2 backend」を選択
3. Docker Desktop を起動し、Settings → Resources → WSL Integration で **Ubuntu-24.04** を有効化
4. Apply & Restart

Ubuntu ターミナルで動作確認：

```bash
docker --version
docker run hello-world
```

### Step 3: Node.js 22のインストール

WSL2のUbuntu内で以下を実行。

**現在のバージョン確認:**

```bash
node --version
```

`v22.x.x` 以上が表示されればOK。それ以外の場合は以下でインストール。

**nvmを使ったインストール:**

:::message
**nvmとは**
Node Version Manager の略。複数のNode.jsバージョンを切り替えて使えるツール。プロジェクトごとに違うバージョンが必要な時に便利。
:::

```bash
# nvmのインストール（未導入の場合）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc

# Node.js 22のインストール
nvm install 22
nvm use 22
nvm alias default 22  # デフォルトに設定

# 確認
node --version
# → v22.x.x と表示されればOK
```

### Step 4: OpenClawのインストール

**npmのグローバルディレクトリ設定（権限エラー回避）:**

```bash
# グローバルパッケージ用ディレクトリを作成
mkdir -p ~/.npm-global

# npmの設定を変更
npm config set prefix ~/.npm-global

# PATHに追加（コマンドを探す場所のリストに追加）
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

**OpenClawのインストール:**

```bash
npm install -g openclaw@latest
```

**インストール確認:**

```bash
openclaw --version
```

:::message
警告（deprecated packages）が出るが、動作に影響はない。無視して進める。
:::

### Step 5: AIプロバイダーの設定

OpenClaw で Claude を使用するには、以下の2つの認証方法がある。

| 方法 | 対象 | 料金体系 | 推奨度 |
|------|------|----------|--------|
| **API Key** | 全ユーザー | 従量課金（トークン単位） | ⭐⭐⭐⭐⭐ **推奨** |
| **setup-token** | Claude Pro/Max契約者 | サブスクリプション内 | ⚠️ ToS問題あり |

[OpenClaw公式ドキュメント](https://docs.openclaw.ai/gateway/authentication)では「For Anthropic accounts, we recommend using an **API key**.」と明記されている。

#### 方法1: API Key（推奨）

1. [Anthropic Console](https://console.anthropic.com/) でAPI Keyを作成
2. 環境変数に設定：

```bash
# ~/.openclaw/.env に追加
echo 'ANTHROPIC_API_KEY=<your-api-key>' >> ~/.openclaw/.env
```

または onboard ウィザードで設定：

```bash
openclaw onboard --install-daemon
```

**API料金（2026年1月時点）:**

| モデル | 入力 | 出力 | 推奨用途 |
|--------|------|------|----------|
| Claude Opus 4.5 | $5/百万トークン | $25/百万トークン | 最高性能、複雑な推論 |
| Claude Sonnet 4.5 | $3/百万トークン | $15/百万トークン | バランス、コーディング |
| Claude Haiku 4.5 | $1/百万トークン | $5/百万トークン | 高速、低コスト |

#### 方法2: setup-token（Claude Pro/Max契約者向け）

:::message alert
**⚠️ ToS違反のリスク**
2026年1月9日、Anthropicは第三者ツールでのOAuth使用を技術的にブロックした。OpenClawでsetup-tokenを使用すると「This credential is only authorized for use with Claude Code」エラーが発生する場合があり、**最悪の場合アカウント停止のリスク**がある。**API Keyの使用を強く推奨。**
:::

### Step 6: Gatewayを起動

```bash
# Gateway modeをlocalに設定
openclaw config set gateway.mode local

# デーモンとして起動
openclaw gateway start

# または手動起動（デバッグ用）
openclaw gateway --port 18789 --verbose
```

**動作確認:**

```bash
openclaw status --all
openclaw health
```

**出力例:**

```
✓ Gateway: running on ws://127.0.0.1:18789
✓ Agent: idle
```

---

## 4. セキュリティ対策【必須】

:::message alert
**この対策は全員必須。**
:::

### 4.1 Gateway認証の設定

`~/.openclaw/openclaw.json` に以下を設定：

```json
{
  "gateway": {
    "bind": "loopback",
    "auth": {
      "mode": "token"
    }
  },
  "channels": {
    "telegram": {
      "dmPolicy": "pairing"
    }
  }
}
```

| 設定項目 | 説明 |
|----------|------|
| `gateway.bind: "loopback"` | ローカルのみアクセス可（必須） |
| `gateway.auth.mode: "token"` | トークン認証を有効化（必須） |
| `dmPolicy: "pairing"` | DM送信者を承認制に（推奨） |

### 4.2 Docker sandbox設定

`~/.openclaw/openclaw.json` に以下を追加：

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

**メリット:**
- エージェントの bash コマンドが Docker コンテナ内で実行される
- コンテナが破壊されてもホスト（WSL2）は無傷
- 問題発生時はコンテナを削除して再構築

### 4.3 専用アカウントの作成

OpenClaw には**専用の Google アカウント**を作成する。本番アカウントは絶対に使用しない。

---

## 5. トラブルシューティング

### 1. npm グローバルインストールの権限エラー

**エラー:**
```
npm error EACCES: permission denied, mkdir '/usr/lib/node_modules/...'
```

**解決策:**
```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### 2. Node.js バージョンが古い

**エラー:** 起動時にバージョンエラー

**解決策:**
```bash
nvm install 22
nvm use 22
nvm alias default 22
```

### 3. PATHにスペースが含まれる問題

**エラー:**
```
export: `Files/Git/mingw64/bin:...': not a valid identifier
```

**解決策:**
```bash
# ログインシェルとして実行
bash -lc "openclaw --version"
```

### 4. 429エラー（レート制限）

**エラー:**
```
LLM error: {"error": {"code": 429, "message": "Resource has been exhausted..."}}
```

**解決策:**
1. **しばらく待つ**: API利用制限は時間経過でリセット
2. **別のモデルに変更**: 軽量モデルは制限に余裕がある場合が多い
3. **翌日まで待つ**: 日次クォータは毎日リセット

### 5. モデル変更が反映されない

**症状:** `openclaw configure` でモデルを変更したのに反映されない

**解決策:** Gatewayを再起動する
```bash
systemctl --user restart openclaw-gateway.service

# 設定を確認
cat ~/.openclaw/openclaw.json | grep -i model
```

### 6. Docker が起動しない

**症状:** Docker コマンドがエラーになる

**解決策:**
1. Docker Desktop が起動しているか確認
2. WSL Integration が有効か確認（Settings → Resources → WSL Integration）
3. Docker Desktop を再起動

---

## 6. 導入前チェックリスト

**【WSL2 + Docker の場合】手動設定:**
- [ ] WSL2 + Ubuntu インストール済み
- [ ] Docker Desktop インストール済み
- [ ] Node.js 22 インストール済み
- [ ] `gateway.bind: "loopback"` 設定済み
- [ ] `gateway.auth.mode: "token"` 設定済み
- [ ] `dmPolicy: "pairing"` 設定済み
- [ ] 専用アカウントを使用（本番アカウント使用禁止）
- [ ] `sandbox.mode: "non-main"` 設定済み
- [ ] Moltbook に接続していない（セキュリティリスク）

---

## 次のステップ

### Discord/Telegram連携

OpenClawをDiscordやTelegramから操作できるようにする：
- [🦞OpenClawでDiscord/Telegramを個人AIアシスタント化する](openclaw-discord-telegram-guide)

### VPSへの移行

ローカル環境で試して気に入った場合は、24/7稼働のVPSへの移行を検討：
- [🦞OpenClaw（旧Clawdbot）をDigitalOceanで安全に動かす](openclaw-setup-guide)

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
