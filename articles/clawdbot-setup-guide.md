---
title: "[検証] ClawdBotを導入してみた：Windows(WSL2)で動く個人AIアシスタント"
emoji: "🦞"
type: "tech"
topics: ["ai", "claudecode", "wsl2", "個人開発", "生成ai"]
published: false
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

### ChatGPT・Claude・Geminiと何が違うの？

「ChatGPTやClaudeがあるのに、なぜClawdBot？」という疑問に答える。

| 項目 | ChatGPT / Claude / Gemini | ClawdBot |
|------|--------------------------|----------|
| 基本機能 | チャットで会話 | チャット＋**PC操作** |
| できること | 質問に答える | 質問に答える＋**実際に作業する** |
| 記憶 | セッション終了で忘れる | **過去の会話を覚えている** |
| データ保存 | クラウド（運営会社のサーバー） | **自分のPC（手元に残る）** |
| 操作場所 | ブラウザ/専用アプリ | Discord, Telegram等 |
| 能動性 | ユーザーの入力を待つ | **朝のブリーフィング等を自動送信** |

**一言で言うと：**
- ChatGPT/Claude/Gemini = 「**賢いチャットボット**」
- ClawdBot = 「**あなたの代わりにPCを操作してくれるAIアシスタント**」

:::message
**Siriとの違い**
「Siriは昨日話したことを覚えていない」という批判がある。ClawdBotはメモリ機能があり、過去の会話・決定事項・好みを記憶する。「AIアシスタントがあるべき姿」として注目されている。
:::

### なぜ今ClawdBotが話題なのか

2026年1月現在、ClawdBotは急速に注目を集めている。

**話題の理由：**
- **GitHub Stars 8,800以上** - オープンソースAIアシスタントとして急成長
- **開発コミュニティの活況** - 「Discordは狂乱状態、1日30件のPR」（開発者談）
- **「2026年はパーソナルエージェントの年」** - MacStoriesレビューで高評価
- **「ClawdBotはChatGPTとClaudeが夢見るパーソナルアシスタント」** - ユーザーの声

### こんな人におすすめ

- **外出先から自宅PCを操作したい** - DiscordやTelegramからファイル確認・操作が可能
- **定型作業を自動化したい** - 毎朝のタスク一覧送信、データ集計など
- **AIに「覚えていてほしい」** - 過去の会話や好みを記憶
- **Claude Codeユーザー** - 外出先から開発環境を操作できる

### 導入の手間 vs メリット

「面倒な設定をしてまで導入する価値はあるの？」

**正直な答え：**
- 初期設定は確かに手間がかかる（WSL2環境で30分〜1時間程度）
- しかし一度設定すれば、**スマホ1つでPCを操作できる環境**が手に入る
- 特にClaude Codeユーザーにとっては、外出先からの開発が可能になる大きなメリット

:::message
**具体的な活用例**
- 毎朝9時に「今日のカレンダー + やることリスト」が自動でTelegramに届く
- 「先月の食費はいくら？」とメッセージを送ると、データを自動集計して回答
- 「プロジェクトXのテストを実行して」→ Claude Codeが動いて結果を報告
:::

### Claude Codeとの関係

Claude Codeユーザーなら、ClawdBotは「**補完的なツール**」として理解するとわかりやすい。

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
# 現在の設定を確認
cat ~/.clawdbot/clawdbot.json

# モデル設定だけ確認
cat ~/.clawdbot/clawdbot.json | grep -i model

# 認証情報を確認
cat ~/.clawdbot/clawdbot.json | grep -i anthropic
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

:::message
**Canvas UI の「Bridge: missing」について**
TUI（clawdbot tui）で「Bridge: missing」と表示されるのは、Discord/Telegram等のチャンネルが未設定の状態では正常。チャンネル設定後に接続される。
:::

---

## API料金について

ClawdBotはAI APIを使用するため、利用量に応じた料金が発生する場合がある。**ただし、Claude サブスクリプション契約者は追加料金なしで利用できる**。

### Claude サブスクリプション契約者の場合

Claude Pro（$20/月）または Claude Max（$100〜$200/月）を契約し、**Claude Codeを使用している場合**、ClawdBotはその認証情報を共有できる。

**設定方法：**
1. 別のターミナルで `claude setup-token` を実行
2. 表示された長期トークンをコピー
3. `clawdbot configure` → Model → Anthropic → 「Anthropic token」を選択
4. トークンを貼り付け

:::message
**Claude の契約プラン**
- **Claude Pro** ($20/月): 一般的な個人利用向け、5倍の利用制限
- **Claude Max 5x** ($100/月): ヘビーユーザー向け、Proの5倍の利用制限
- **Claude Max 20x** ($200/月): 超ヘビーユーザー向け、Proの20倍の利用制限

**注意点：**
- 契約プランには利用制限（レートリミット）があり、Claude.aiとClaude Codeで共有される
- ClawdBotでの使用もこの制限にカウントされる
- 頻繁に使いすぎると一時的に制限がかかる場合がある
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

### エージェント（AIプロバイダー）の選択

ClawdBotは複数のAIプロバイダーに対応している。**この記事シリーズはClaude Codeユーザー向けのため、Claudeの使用を推奨**。

```bash
# 設定を確認
clawdbot config get agents

# 設定を変更
clawdbot configure
```

**対応プロバイダー：**

| プロバイダー | おすすめ度 | 備考 |
|-------------|-----------|------|
| **Claude（Anthropic）** | ★★★ | 推奨。Claude サブスクリプション契約者は追加料金なし |
| GPT-4（OpenAI） | ★★☆ | APIキーが必要、従量課金 |
| Gemini（Google） | ★★☆ | 無料枠あるが制限厳しめ |
| Ollama, LM Studio | ★★☆ | ローカルLLM。無料だがPCスペック必要 |

:::message
**Claude推奨の理由**
- Claude Pro/Max契約者は `setup-token` で追加料金なしで利用可能
- Claude Codeとの連携がスムーズ
- このシリーズの他の記事との整合性
:::

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

### 4. 429エラー（レート制限）

**エラー:**
```
LLM error: {"error": {"code": 429, "message": "Resource has been exhausted..."}}
```

**原因:** APIのレート制限（利用枠）を超過

**解決策（Claude利用時）:**
1. **しばらく待つ**: Claude Pro/Maxの利用制限は時間経過でリセット
2. **Claude.aiやClaude Codeの使用を控える**: 利用枠はClaude.ai、Claude Code、ClawdBotで共有される
3. **上位プランを検討**: Max 5x（$100/月）やMax 20x（$200/月）は利用枠が大きい

**解決策（他のプロバイダー利用時）:**
1. **別のモデルに変更**: 軽量モデルは制限に余裕がある場合が多い
2. **翌日まで待つ**: 日次クォータは毎日リセット
3. **課金を有効化**: 無料枠を超えて利用する場合

### 5. モデル変更が反映されない

**症状:** `clawdbot configure` でモデルを変更したのに反映されない

**解決策:** Gatewayを再起動する
```bash
# Gatewayを再起動
systemctl --user restart clawdbot-gateway.service

# 設定を確認
cat ~/.clawdbot/clawdbot.json | grep -i model
```

:::message
設定ファイル（`~/.clawdbot/clawdbot.json`）を直接編集することも可能。編集後は必ずGatewayを再起動する。
:::

### 6. 設定変更後も古いエラーが出る

**症状:** 設定を変更したのに古いエラーが出続ける、TUIに古いモデル名が表示される

**解決策:** セッションをクリアする
```bash
# セッションをクリア
rm -rf ~/.clawdbot/agents/main/sessions/*

# Gatewayを再起動
systemctl --user restart clawdbot-gateway.service

# TUIを再起動
clawdbot tui
```

---

## 次のステップ

ClawdBotの基本インストールが完了した。

---

## 参考リンク

- [ClawdBot GitHub](https://github.com/clawdbot/clawdbot)
- [ClawdBot 公式ドキュメント](https://docs.clawd.bot/)
- [ClawdBot Gateway](https://docs.clawd.bot/gateway)
- [ClawdBot Authentication](https://docs.clawd.bot/gateway/authentication)
- [ClawdBot Troubleshooting](https://docs.clawd.bot/help/troubleshooting)
- [ClawdBot Setup Guide (addROM)](https://addrom.com/clawdbot-your-personal-ai-assistant-for-windows-macos-and-linux/)

---

## 関連記事

- [WSL2インストールガイド（Windows）](wsl2-windows-install-guide)
- [非エンジニアがWindowsでClaude Codeを使えるようになるまで](claude-code-windows-install-guide)
- [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips-and-features)
