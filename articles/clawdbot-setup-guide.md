---
title: "[検証] ClawdBotを導入してみた：Windows(WSL2)で動く個人AIアシスタント"
emoji: "🦞"
type: "tech"
topics: ["ai", "claudecode", "wsl2", "個人開発", "生成ai"]
published: true
---

## はじめに

この記事では、ClawdBot（クロードボット）をWindows環境（WSL2）に導入する手順を解説する。

ClawdBotは、Discord・Telegram・WhatsAppなど複数のメッセージングアプリから操作できる個人AIアシスタント。自分のPCで動かすので、データは手元に残る。

:::message
**シリーズ構成**
- [WSL2インストールガイド（Windows）](wsl2-windows-install-guide)
- [非エンジニアがWindowsでClaude Codeを使えるようになるまで](claude-code-windows-install-guide)
- [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips-and-features)
- **ClawdBotを導入してみた**（この記事）
- [ClawdBot活用ガイド：Discord/Telegram連携](clawdbot-discord-telegram-guide)
:::

---

## ClawdBotとは

### 概要

[ClawdBot](https://github.com/clawdbot/clawdbot)は、自分のPCで動かす個人AIアシスタント。

| 項目 | 内容 |
|------|------|
| 開発元 | Peter Steinberger (@steipete) |
| ライセンス | MIT |
| Star数 | 8.8k（2026年1月時点） |
| 対応プラットフォーム | Discord, Telegram, WhatsApp, Slack, iMessage等 |

### Claude Codeとの違い

Claude Codeユーザーなら、ClawdBotは「補完的なツール」として理解するとわかりやすい。

| 項目 | Claude Code | ClawdBot |
|------|------------|----------|
| 操作場所 | ターミナル | Discord, Telegram等 |
| 主な用途 | コーディング支援 | 汎用AIアシスタント |
| 動作環境 | ローカル | ローカル（Gateway常駐） |
| 会話の継続 | セッション単位 | 複数プラットフォームで継続 |

**ポイント**: ClawdBotには「coding-agent」スキルがあり、Claude CodeやCodex CLIを呼び出すこともできる。つまり、DiscordからClaude Codeを操作する、といった使い方も可能。

---

## ClawdBotの仕組み

ClawdBotの内部構造を理解しておくと、トラブル時に役立つ。

### 全体構成

```
┌─────────────────────────────────────────────────────────────┐
│                     Gateway（中核）                          │
│  ・全チャンネルを統括（バックグラウンドで常に動く）              │
│  ・内部通信用の接続先（127.0.0.1:18789）                      │
│  ・メッセージの振り分け                                       │
└─────────────────────────────────────────────────────────────┘
         ↑↓                    ↑↓                    ↑↓
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  Channels   │      │   Agent     │      │   Skills    │
│  （入出力）   │      │  （LLM連携）  │      │  （実行部）   │
├─────────────┤      ├─────────────┤      ├─────────────┤
│ ・Discord   │      │ ・Claude    │      │ ・github    │
│ ・Telegram  │      │ ・GPT-4     │      │ ・coding    │
│ ・WhatsApp  │      │ ・Bedrock   │      │ ・browser   │
└─────────────┘      └─────────────┘      └─────────────┘
```

### 各コンポーネントの役割

| コンポーネント | 役割 | 例え |
|---------------|------|------|
| **Gateway** | バックグラウンドで動き続けるプログラム | 脳 |
| **Channels** | メッセージの入出力を担当 | 耳と口 |
| **Agent** | AI（Claude等）との連携 | 思考 |
| **Skills** | 実際のアクション実行 | 手 |

### 設定ファイルの場所

:::message
**`~` の意味**
`~` はホームディレクトリを表す記号。WSL2では `/home/ユーザー名/` のこと。例えば `~/.clawdbot/` は `/home/aki/.clawdbot/` と同じ。
:::

| ファイル | パス | 役割 |
|----------|------|------|
| メイン設定 | `~/.clawdbot/clawdbot.json` | チャンネル設定、ユーザー制限 |
| 認証情報 | `~/.clawdbot/credentials/` | APIキー等 |
| セッション | `~/.clawdbot/agents/main/sessions/` | 会話履歴 |

---

## 動作環境

### 必要要件

| 項目 | 要件 |
|------|------|
| OS | Windows 10 Build 19041+ / Windows 11 |
| WSL2 | 必須（PowerShellネイティブは非対応） |
| Node.js | **22.12.0 以上**（重要） |
| RAM | 8GB以上推奨 |
| ストレージ | 20GB以上の空き |

:::message alert
**重要: Node.js 22以上が必要**
多くの環境ではNode.js 18や20が入っている。ClawdBotは22以上を要求するので、nvm（Node.jsのバージョン管理ツール）でのバージョン管理を推奨。
:::

### なぜWSL2が必要か

公式ドキュメントで「WSL2 strongly recommended」と明記されている。

- PowerShellネイティブは「untested and more problematic」
- 依存関係（Baileys, grammY等）がLinux前提の設計
- 将来のアップデートでも安定動作が期待できる

:::message alert
**重要：ClawdBotはWSL2内で実行する**

ClawdBotはLinux環境で動作するため、PowerShell（Windows側）からは直接実行できません。

```powershell
# ❌ PowerShellから直接実行 → エラーになる
clawdbot --version

# ✅ WSL2に入ってから実行
wsl
clawdbot --version

# ✅ または一行で
wsl clawdbot --version
```
:::

---

## 環境構築

### Step 1: WSL2のセットアップ

既にWSL2を使っている場合はスキップ。

詳細な手順は [WSL2インストールガイド](wsl2-windows-install-guide) を参照。

**最小手順（管理者PowerShell）:**

```powershell
wsl --install -d Ubuntu-24.04
```

インストール後、PCを再起動。

### Step 2: Node.js 22のインストール

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
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
source ~/.bashrc

# Node.js 22のインストール
nvm install 22
nvm use 22

# 確認
node --version
# → v22.x.x と表示されればOK
```

### Step 3: npmのグローバルディレクトリ設定

:::message alert
**ハマりポイント: 権限エラー**
WSL2でも `npm install -g` で権限エラーが発生する場合がある。以下の設定で回避できる。
:::

```bash
# グローバルパッケージ用ディレクトリを作成
mkdir -p ~/.npm-global

# npmの設定を変更
npm config set prefix ~/.npm-global

# PATHに追加（コマンドを探す場所のリストに追加）
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

:::message
**PATHとは**
コマンドを探す場所のリスト。ここに追加しないと `clawdbot` や `pnpm` コマンドが「見つからない」エラーになる。
:::

### Step 4: ClawdBotのインストール

```bash
# pnpmのインストール（npmより高速なパッケージ管理ツール）
npm install -g pnpm

# ClawdBotのインストール
npm install -g clawdbot@latest
```

**出力例:**

```
npm warn deprecated tar@6.2.1: Old versions of tar are not supported...
npm warn deprecated npmlog@6.0.2: This package is no longer supported.

added 666 packages in 1m
```

:::message
警告（deprecated packages）が出るが、動作に影響はない。無視して進める。
:::

### Step 5: インストール確認

```bash
clawdbot --version
```

**出力例:**

```
[agents/auth-profiles] synced openai-codex credentials from codex cli
2026.1.23-1
```

:::message
**発見: Codex CLI認証の自動同期**
既にCodex CLIを使っている場合、認証情報が自動で同期される。これは便利。
:::

---

## 初期設定

### Step 1: Gateway設定

```bash
# Gateway modeをlocalに設定
clawdbot config set gateway.mode local
```

### Step 2: 状態確認（Doctor）

```bash
clawdbot doctor
```

**出力例（初回）:**

```
┌  Clawdbot doctor
│
◇  Gateway ──────────────────────────────────────────────────────────╮
│  gateway.mode is unset; gateway start will be blocked.             │
│  Fix: run clawdbot configure and set Gateway mode (local/remote).  │
├────────────────────────────────────────────────────────────────────╯
│
◇  Skills status ────────────╮
│  Eligible: 8               │
│  Missing requirements: 41  │
├────────────────────────────╯
│
└  Doctor complete.
```

### Step 3: 自動修復

```bash
clawdbot doctor --fix
```

これで基本的な設定が完了する。

### Step 4: 設定ファイルの確認

```bash
cat ~/.clawdbot/clawdbot.json
```

**出力例:**

```json
{
  "agents": {
    "defaults": {
      "maxConcurrent": 4,
      "subagents": { "maxConcurrent": 8 }
    }
  },
  "gateway": { "mode": "local" },
  "commands": { "native": "auto", "nativeSkills": "auto" }
}
```

---

## API料金について

ClawdBotはAI APIを使用するため、利用量に応じた料金が発生する場合がある。**ただし、Claude サブスクリプション契約者は追加料金なしで利用できる**。

### Claude サブスクリプション契約者の場合（追加料金なし）

Claude Pro（$20/月）または Claude Max（$100/月）を契約している場合、ClawdBotはその認証情報を使用できる。追加のAPIキー取得は不要。

:::message
**Claude の契約プラン**
- **Claude Pro** ($20/月): 一般的な個人利用向け
- **Claude Max** ($100/月): ヘビーユーザー向け、利用枠が大きい

契約プランには利用制限（レートリミット）がある。頻繁に使いすぎると一時的に制限がかかる場合がある。
:::

### 料金の仕組み

| 利用パターン | 料金 | 備考 |
|-------------|------|------|
| **Claude サブスクリプション契約者** | 追加料金なし | 契約の利用枠内で使用可能 |
| **Anthropic API直接利用** | 従量課金 | 別途APIキーが必要 |
| **ローカルLLM（Ollama等）** | 無料 | 自分のPCで動かす |

### 無料で試す方法

1. **Claude サブスクリプションを使う**（契約者のみ）
   - 追加料金なしで利用可能

2. **ローカルLLMを使う**
   - Ollama や LM Studio でローカルにLLMを動かす
   - ClawdBotはローカルLLMもサポートしている
   - 設定方法: [ClawdBot Integrations](https://clawd.bot/integrations)

### API従量課金の目安（参考）

Anthropic APIを直接使う場合の料金目安。

:::message
**トークンとは**
AIが文章を処理する単位。日本語の場合、1文字あたり約1〜3トークン。100万トークンは日本語で約30万〜100万文字分に相当する。
:::

| モデル | 入力（質問側） | 出力（AI回答側） | 1日10往復の目安 |
|--------|---------------|-----------------|----------------|
| Claude Sonnet | $3/100万トークン | $15/100万トークン | 約$0.05〜0.10/日 |
| Claude Opus | $15/100万トークン | $75/100万トークン | 約$0.50〜1.00/日 |

:::message
**モデルの選び方**
- **Sonnet**: 通常の会話には十分。コスパが良い
- **Opus**: 高度な推論が必要な時だけ使う（上級者向け）

料金は利用パターンで大きく変動する。月末に請求を確認する習慣をつけると安心。
:::

### エージェント（AIプロバイダー）の変更

デフォルトではClaude（Anthropic）が使われる。他のプロバイダーに変更したい場合：

```bash
# 設定を確認
clawdbot config get agents

# 設定を変更（例）
clawdbot configure
```

対応プロバイダー：Claude、GPT-4、Bedrock、Ollama、LM Studio 等

---

## 利用可能なスキル

ClawdBotには最初から使えるスキルがいくつかある。

```bash
clawdbot skills list
```

**主要なスキル:**

| スキル | 説明 | 状態 |
|--------|------|------|
| **coding-agent** | Claude Code / Codex CLI の呼び出し | ✓ Ready |
| **github** | gh CLI連携（Issue, PR操作） | ✓ Ready |
| **bluebubbles** | iMessage連携用 | ✓ Ready |

:::message
**発見: coding-agentスキル**
ClawdBotからClaude CodeやCodex CLIを呼び出せる。DiscordでClawdBotに「このプロジェクトのコードをチェックして」と頼むと、内部でClaude Codeが動く、といった使い方ができる。
:::

---

## ハマりポイントと解決策

### 1. npm グローバルインストールの権限エラー

**エラー:**
```
npm error EACCES: permission denied, mkdir '/usr/lib/node_modules/...'
```

**原因:** WSL2でもシステムディレクトリへの書き込み権限がない

**解決策:**
```bash
mkdir -p ~/.npm-global
npm config set prefix ~/.npm-global
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

### 2. Node.js バージョンが古い

**エラー:** 起動時にバージョンエラー

**原因:** Node.js 22未満がインストールされている

**解決策:**
```bash
nvm install 22
nvm use 22
nvm alias default 22  # デフォルトに設定
```

### 3. PATHにスペースが含まれる問題

**エラー:**
```
export: `Files/Git/mingw64/bin:...': not a valid identifier
```

**原因:** WindowsのPATH（スペース含む）がWSLに引き継がれる

**解決策:**
```bash
# ログインシェルとして実行
bash -lc "clawdbot --version"
```

:::message
恒久的に解決したい場合は `/etc/wsl.conf` に `appendWindowsPath = false` を追加する方法もあるが、設定ファイルの編集に慣れていない場合は上記コマンドで十分。
:::

---

## 次のステップ

ClawdBotの基本インストールが完了した。次の記事では、実際にDiscordやTelegramと連携して使う方法を解説する。

- [ClawdBot活用ガイド：Discord/Telegram連携](clawdbot-discord-telegram-guide)

---

## 参考リンク

- [ClawdBot GitHub](https://github.com/clawdbot/clawdbot)
- [ClawdBot 公式ドキュメント](https://docs.clawd.bot/)
- [ClawdBot Setup Guide (addROM)](https://addrom.com/clawdbot-your-personal-ai-assistant-for-windows-macos-and-linux/)

---

## 関連記事

- [WSL2インストールガイド（Windows）](wsl2-windows-install-guide)
- [非エンジニアがWindowsでClaude Codeを使えるようになるまで](claude-code-windows-install-guide)
- [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips-and-features)
