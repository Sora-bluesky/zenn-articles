---
title: "【非エンジニア×AI開発】Google Antigravity × Codex CLI でデュアルエージェント開発"
emoji: "🤝"
type: "tech"
topics: ["ai", "windows", "生成ai", "個人開発", "llm"]
published: true
---

## はじめに

この記事では、 **2つの AI を組み合わせた開発スタイル** を紹介する。

- **書く係（Builder）**: Google Antigravity（Gemini）
- **チェックする係（Auditor）**: OpenAI Codex CLI（GPT）

1つの AI に全部任せると、「自分が作ったものには甘くなりがち」という問題がある。人間の開発チームでも「作る人」と「チェックする人」を分けるのと同じで、 **AI でも役割分担すると品質が上がる**。

この記事では、Google 製 AI がコードを書き、OpenAI 製 AI が自動でチェックするワークフローを構築する。**ユーザーは Antigravity に指示を出すだけで、レビューと修正のサイクルが自動で回る。**

### 自動レビューサイクルの全体像

```
┌─────────────────────────────────────────────────┐
│ ユーザー: 「機能Xを作って」                      │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Antigravity: コード作成                          │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Antigravity: git commit → review.ps1 実行        │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Codex: レビュー結果（🔴🟡🟢💡）                  │
└─────────────────────────────────────────────────┘
                    ↓
            🔴 or 🟡 あり？
           ↓ はい      ↓ いいえ
    ┌──────────┐   ┌──────────┐
    │ 修正     │   │ 完了報告 │
    │（最大5回）│   └──────────┘
    └──────────┘
         ↓
     手順3に戻る
```

:::message alert
**WSL2 が必須**
この記事の手順は **WSL2（Windows Subsystem for Linux 2）** 上で実行する。WSL2 をまだセットアップしていない場合は、先に [WSL2 インストールガイド](wsl2-windows-install-guide) を参照。
:::

:::message
**シリーズ構成**
- [【非エンジニア×AI開発】Google Antigravity インストールガイド（Windows）](antigravity-windows-install-guide)
- **Google Antigravity × Codex CLI でデュアルエージェント開発**（この記事）
:::

:::message
**Claude Code ユーザーへ**
Claude Code には「サブエージェント」という機能があり、Claude だけで同様の役割分担ができる。Claude Code ユーザーは [AIにコードを書かせてAIにレビューさせる開発スタイル](claude-code-ai-review-workflow) を参照。
:::

---

## この方式を選ぶ理由

### Claude Code サブエージェント方式との比較

| 項目 | デュアルエージェント方式 | Claude Code サブエージェント方式 |
|------|-------------------------|--------------------------------|
| 必要な契約 | Google AI Pro + ChatGPT Plus/Pro | Claude Pro/Max のみ |
| セットアップ | WSL + Node.js + 2つの認証 | ファイルを作るだけ |
| 操作画面 | Antigravity の画面で完結（自動化） | 1つの画面で完結 |
| 視点の多様性 | Google と OpenAI の2社の視点 | Claude のみ |
| トラブル発生率 | やや高い（初回セットアップ時） | 低い |

### どちらを選ぶべきか

| あなたの状況 | おすすめ |
|-------------|---------|
| Claude Pro/Max を契約中で、シンプルにやりたい | [Claude Code サブエージェント方式](claude-code-ai-review-workflow) |
| Google AI Pro と ChatGPT Plus/Pro を既に契約中 | デュアルエージェント方式（この記事） |
| 複数の AI 会社の視点でチェックしたい | デュアルエージェント方式（この記事） |
| Antigravity をメインで使いたい | デュアルエージェント方式（この記事） |

---

## 前提条件

この記事を進めるには、以下が必要。

| 項目 | 準備 |
|------|------|
| **Google Antigravity** | [インストールガイド](antigravity-windows-install-guide) 参照 |
| **WSL2 + Ubuntu** | [WSL2 インストールガイド](wsl2-windows-install-guide) 参照 |
| **Node.js 22以上** | この記事で説明 |
| **Codex CLI** | この記事で説明 |
| **ChatGPT Plus または Pro** | OpenAI の有料プラン（月額 $20〜） |

:::message alert
**料金について**
この方式では Google AI Pro（$19.99/月）と ChatGPT Plus/Pro（$20/月〜）の両方が必要になる可能性がある。既に契約中でなければ、まずどちらか一方を試すことを推奨する。
:::

---

## Step 1: Codex CLI のセットアップ

Codex CLI は WSL（Ubuntu）上で動かす。Windows の PowerShell では動作しない。

### Node.js のインストール

Ubuntu ターミナルを開いて、以下を順番に実行する。

**1. nvm（Node.js のバージョン管理ツール）をインストール**

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
```

:::message
**コマンドの意味**
- `curl`: インターネットからファイルをダウンロードするコマンド
- `-o-`: ダウンロードした内容を直接次のコマンドに渡す
- `| bash`: ダウンロードした内容をシェルスクリプトとして実行する
:::

**2. 設定を反映**

```bash
source ~/.bashrc
```

:::message
**`~` （チルダ）とは**
「ホームディレクトリ」を表す記号。Ubuntu では `/home/あなたのユーザー名/` と同じ意味。
:::

**3. Node.js 22 をインストール**

```bash
nvm install 22
```

**4. インストール確認**

```bash
node --version
```

`v22.x.x` と表示されれば成功。

### Codex CLI のインストール

```bash
npm i -g @openai/codex
```

:::message
**コマンドの意味**
- `npm`: Node.js のパッケージ管理ツール（アプリストアのようなもの）
- `i`: install の略
- `-g`: グローバル（システム全体で使える場所）にインストール
- `@openai/codex`: OpenAI が公開している Codex CLI パッケージ
:::

### 認証

```bash
codex
```

初回起動時に認証方法を選択する画面が出る。

```
? How would you like to authenticate? (Use arrow keys)
❯ Sign in with ChatGPT
  Use API key
```

**「Sign in with ChatGPT」を選択して Enter を押す。**

ブラウザが開き、ChatGPT のログイン画面が表示される。ログインして認証を許可すると、ターミナルに戻って使えるようになる。

:::message alert
**ブラウザが開かない場合**

WSL から Windows のブラウザを開けない場合がある。その場合は `wslu` をインストールする。

```bash
sudo apt update && sudo apt install -y wslu
```

再度 `codex` を実行すると、ブラウザが開くようになる。

:::

認証が成功すると、以下のような起動画面が表示される。

![Codex CLI 起動画面（gpt-5.2-codex モデル使用時）](/images/codex-cli-startup.png)
*Codex CLI を起動すると、使用モデルとコマンド一覧が表示される*

画面に表示されるコマンドの意味は以下の通り。

| コマンド | 意味 |
|---------|------|
| `/init` | AGENTS.md（AI への指示書）を作成する |
| `/status` | 現在の設定を表示する |
| `/approvals` | AI が自動で実行できる操作を選ぶ |
| `/permissions` | AI に許可する操作を選ぶ |
| `/model` | 使用するモデルを変更する |
| `/review` | コードの変更点をレビューする |

`/exit` または `Ctrl + C` で終了できる。

### Git の初期設定（初回のみ）

初めて Git を使う場合、コミット時に「誰がコミットしたか」を記録するための設定が必要。

```bash
git config --global user.email "あなたのメールアドレス"
git config --global user.name "あなたの名前"
```

**何を設定すればいい？**

- **GitHub アカウントがある場合**: GitHub に登録しているメールアドレスとユーザー名を設定（コミット履歴が GitHub アカウントと紐付く）
- **GitHub アカウントがない場合**: 任意のメールアドレスと名前で OK（後から変更も可能）

例：
```bash
git config --global user.email "example@gmail.com"
git config --global user.name "Taro Yamada"
```

:::message
この設定は PC ごとに一度だけ行えば OK です。
:::

---

## Step 2: 自動レビュー環境のセットアップ

ここでは、Antigravity が自動でレビューを実行できる環境を作る。必要なファイルは2つ。

| ファイル | 役割 |
|---------|------|
| `review.ps1` | Codex CLI を呼び出してレビューを実行するスクリプト |
| `.agent/workflows/review-cycle.md` | レビュー→修正のサイクルを定義するワークフロー |

:::message
**review.ps1 とは**
PowerShell スクリプト。Windows 上で動作し、WSL 経由で Codex CLI を呼び出す。Antigravity がこのスクリプトを実行することで、自動レビューが可能になる。
:::

### review.ps1 の作成

Antigravity を起動し、プロジェクトフォルダを開いた状態で以下のように依頼する。

```
review.ps1 を作成して。Codex CLI で自動レビューを行い、🔴 または 🟡 があれば終了コード 1、なければ 0 を返すスクリプト。WSL 経由で実行する形式で。
```

Antigravity から node と codex のパスを聞かれたら、**WSL で以下を実行して確認する**。

```bash
which node
which codex
```

![which コマンドでパスを確認](/images/dual-agent-which-paths.png)
*WSL で which node と which codex を実行した結果*

表示されたパスを Antigravity に伝える。

例：
```
node: /home/aki/.nvm/versions/node/v22.22.0/bin/node
codex: /home/aki/.nvm/versions/node/v22.22.0/bin/codex
```

![Antigravity にパスを伝える](/images/dual-agent-tell-paths.png)
*確認したパスを Antigravity に伝える*

:::message
**パスが異なる場合**
ユーザー名や Node.js のバージョンによってパスは異なる。必ず自分の環境で `which` コマンドを実行して確認すること。
:::

### ワークフロー定義の作成

続けて Antigravity に以下のように依頼する。

```
.agent/workflows/review-cycle.md を作成して。自動レビューサイクルの手順を定義するファイル。最大5回ループ、🔴と🟡がゼロになったら完了。
```

Antigravity が `.agent/workflows/review-cycle.md` を作成する。このファイルには以下のような内容が含まれる。

- コード作成後に `git commit` する手順
- `review.ps1` を実行してレビューを取得する手順
- 🔴 または 🟡 があれば修正して再レビューする手順
- 最大5回で打ち切るルール

:::message
**`.agent` フォルダとは**
Antigravity がプロジェクトの設定やワークフローを保存するフォルダ。Antigravity が自動で作成・管理する。
:::

---

## Step 3: 使い方

セットアップが完了すれば、あとは Antigravity に指示を出すだけ。

### 基本的な使い方

1. Antigravity を起動してプロジェクトフォルダを開く
2. 以下のように指示する：

```
Qiita API でトレンド記事を取得するスクリプトを作って、自動レビューサイクルを回して
```

3. Antigravity が自動で以下を行う：
   - コード作成
   - `git commit`
   - `review.ps1` 実行（Codex CLI によるレビュー）
   - 🔴 や 🟡 があれば修正して再レビュー（最大5回）
   - 問題がなくなったら完了報告

![自動レビューサイクル実行中](/images/dual-agent-review-cycle.png)
*Antigravity が自動で review.ps1 を実行し、レビュー結果を取得*

Codex が 🔴 重大 の指摘を出した場合、Antigravity は自動的に修正を行い、再度レビューを実行する。

![修正と再レビューのループ](/images/dual-agent-fix-loop.png)
*🔴 重大 の指摘があると、Antigravity が自動修正して再レビュー*

このサイクルは最大5回まで繰り返され、🔴 重大 がゼロになるまで続く。

![レビュー通過](/images/dual-agent-review-passed.png)
*問題がなくなると「レビュー通過」と表示される*

:::message
**ポイント**
「自動レビューサイクルを回して」というフレーズを指示に含めることで、Antigravity が `.agent/workflows/review-cycle.md` のワークフローに従って動作する。
:::

---

## レビュー結果の見方

Codex CLI のレビュー結果は、緊急度別に整理されて出力される。

![Codex CLI による日本語レビュー結果](/images/dual-agent-codex-review-ja.png)
*Codex CLI のレビュー結果。🔴重大 → 🟡注意 → 🟢軽微 → 💡改善提案 の順に、緊急度別で表示されます*

| 記号 | 意味 | 対応 |
|------|------|------|
| 🔴 重大 | すぐに修正が必要 | Antigravity が自動修正 |
| 🟡 注意 | できれば修正を推奨 | Antigravity が自動修正 |
| 🟢 軽微 | 余裕があれば対応 | 任意（無視しても OK） |
| 💡 改善提案 | より良くするアイデア | 任意（無視しても OK） |

🔴 と 🟡 が **ゼロになるまで** 自動で修正→再レビューが繰り返される。🟢 と 💡 は参考情報として表示されるだけで、修正対象にはならない。

---

## フォルダ構成

自動レビューサイクルを使うためのファイル配置：

```
C:\Users\<ユーザー名>\Documents\Projects\
├── review.ps1                    # 自動レビュースクリプト（共通）
│
├── qiita-trend\                  # プロジェクトA
│   ├── .agent\
│   │   └── workflows\
│   │       └── review-cycle.md   # ワークフロー定義
│   ├── AGENTS.md                 # Antigravity 用の指示書（任意）
│   ├── index.js
│   └── ...
│
├── another-project\              # プロジェクトB
│   ├── .agent\
│   │   └── workflows\
│   │       └── review-cycle.md
│   └── ...
│
└── ...
```

**ポイント**:
- `review.ps1` は Projects フォルダ直下に1つだけ配置（全プロジェクト共通）
- `.agent/workflows/review-cycle.md` は各プロジェクトごとに配置
- これにより、どのプロジェクトでも自動レビューサイクルが使える

---

## トラブルシューティング

### git init が「Operation not permitted」で失敗する

**症状**: `/mnt/c/` 以下のフォルダで `git init` を実行すると、以下のエラーが出る
```
error: chmod on .git/config.lock failed: Operation not permitted
fatal: could not set 'core.filemode' to 'false'
```

**原因**: WSL2 から Windows のフォルダ（`/mnt/c/` 以下）にアクセスする際、ファイルの権限操作が制限されることがある

**対策1: WSL2 の設定を変更する**
```bash
sudo nano /etc/wsl.conf
```

以下を追加：
```
[automount]
options = "metadata"
```

保存後（`Ctrl + O` → `Enter` → `Ctrl + X`）、PowerShell で WSL を再起動：
```powershell
wsl --shutdown
```

再度 Ubuntu を起動して `git init` を実行する。

**対策2: PowerShell から実行する（簡単）**

設定変更が面倒な場合は、PowerShell または コマンドプロンプトから `git init` を実行：
```powershell
cd C:\Users\あなたのユーザー名\Documents\Projects\プロジェクト名
git init
```

その後、WSL2 に戻って作業を続けられる。

### review.ps1 で「Codex CLI が見つかりません」と表示される

**症状**: Antigravity が review.ps1 を実行した際に、Codex CLI が見つからないというエラーが出る

**原因**: WSL 内の codex へのパスが review.ps1 に正しく設定されていない

**対策**:
1. WSL で `which node` と `which codex` を実行してパスを確認
2. Antigravity に以下のように伝える：
```
review.ps1 のパスを更新して。node: (表示されたパス), codex: (表示されたパス)
```

### review.ps1 で「node: No such file or directory」と表示される

**症状**: review.ps1 実行時に node が見つからないエラーが出る

**原因**: nvm を使っている場合、WSL の非対話シェルでは node にパスが通らないことがある

**対策**: review.ps1 内で node の**絶対パス**が指定されているか確認する。`/home/ユーザー名/.nvm/versions/node/v22.x.x/bin/node` のような形式になっていなければ、上記と同じ手順でパスを伝えて更新してもらう。

### codex exec がタイムアウトする

**症状**: レビューが途中で止まる、またはタイムアウトエラーが出る

**対策**:
- ファイルが多すぎる場合は、Antigravity に「レビュー対象を src/ フォルダに絞って」と伝える
- ネットワーク接続を確認する

### Landlock エラー

**症状**: 以下のようなエラーが出る
```
Error: Landlock sandbox initialization failed
```

**対策**:
- `--sandbox danger-full-access` オプションが review.ps1 に含まれているか確認
- WSL を再起動する
  ```powershell
  wsl --shutdown
  ```
  その後、Ubuntu を再度起動

### 5回修正しても問題が収束しない

**症状**: 自動レビューサイクルが最大回数（5回）に達しても問題が残る

**対策**:
- Antigravity に「セキュリティの問題だけ修正して」のように観点を絞って再依頼する
- 一旦コミットして区切りをつけ、別のタスクとして修正を進める

### レート制限

**症状**: 以下のようなエラーが出る
```
Rate limit exceeded
```

**対策**:
- 数分〜数十分待ってから再度試す
- ChatGPT Plus から Pro へのアップグレードを検討する

---

## まとめ

### メリット

| メリット | 説明 |
|---------|------|
| **視点の多様性** | Google と OpenAI、2社の AI の視点でチェックできる |
| **完全自動化** | 指示を出すだけでレビュー→修正が自動で回る |
| **役割分担** | 「作る人」と「チェックする人」を分けることで品質が上がる |
| **既存契約の活用** | 既に両方のサービスを契約していれば追加費用なし |

### デメリット

| デメリット | 説明 |
|-----------|------|
| **初回セットアップが必要** | WSL + Node.js + 2つの認証 + review.ps1 の作成が必要 |
| **追加費用** | 両方のサービスを新規契約すると月額 $40 程度 |
| **パス設定のトラブル** | nvm 環境では node/codex のパス指定でつまずくことがある |

### どちらを選ぶべきか（再掲）

| あなたの状況 | おすすめ |
|-------------|---------|
| Claude Pro/Max を契約中で、シンプルにやりたい | [Claude Code サブエージェント方式](claude-code-ai-review-workflow) |
| Google AI Pro と ChatGPT Plus/Pro を既に契約中 | デュアルエージェント方式（この記事） |
| 複数の AI 会社の視点でチェックしたい | デュアルエージェント方式（この記事） |
| Antigravity をメインで使いたい | デュアルエージェント方式（この記事） |

---

## 参考リンク

- [Google Antigravity 公式サイト](https://antigravity.google)
- [OpenAI Codex CLI GitHub](https://github.com/openai/codex)
- [nvm (Node Version Manager) GitHub](https://github.com/nvm-sh/nvm)

:::message
リンク切れの場合は各公式サイトで検索してください。
:::

---

## 関連記事

- [【非エンジニア×AI開発】Google Antigravity インストールガイド（Windows）](antigravity-windows-install-guide)
- [非エンジニア向け WSL2 インストールガイド](wsl2-windows-install-guide)
- [AIにコードを書かせてAIにレビューさせる開発スタイル](claude-code-ai-review-workflow)（Claude Code 版）
