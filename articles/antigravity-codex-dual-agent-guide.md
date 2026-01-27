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

この記事では、Google 製 AI がコードを書き、OpenAI 製 AI がチェックするワークフローを構築する。

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
| 操作画面 | 2つのターミナルを行き来 | 1つの画面で完結 |
| 視点の多様性 | Google と OpenAI の2社の視点 | Claude のみ |
| トラブル発生率 | やや高い | 低い |

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

---

## Step 2: デュアルエージェント体制の構築

### 役割分担

| 役割 | ツール | AI モデル | 担当 |
|------|--------|-----------|------|
| **Builder**（作る人） | Google Antigravity | Gemini | コードを書く・修正する |
| **Auditor**（チェックする人） | OpenAI Codex CLI | GPT | コードをレビューする・問題を指摘する |

### ワークフロー

```
┌─────────────────────────────────────────────────────────────────┐
│  開発フロー                                                     │
│                                                                 │
│  1. Builder（Antigravity）が実装                               │
│     ↓                                                           │
│  2. コミット                                                    │
│     ↓                                                           │
│  3. Auditor（Codex CLI）がレビュー                             │
│     ↓                                                           │
│  4. 問題あり？ → Builder が修正 → 3 に戻る                      │
│     ↓                                                           │
│  5. 問題なし → 完了                                             │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step 3: プロジェクト初期化スクリプト

毎回同じ設定をするのは面倒なので、スクリプトを作っておく。

### スクリプトの作成

Ubuntu ターミナルで以下を実行。

**1. スクリプトファイルを作成**

```bash
nano ~/init-dual-agent.sh
```

:::message
**nano とは**
テキストエディタ。ファイルを開いて編集できる。
:::

**2. 以下の内容を貼り付ける**

```bash
#!/bin/bash

# デュアルエージェント開発 初期化スクリプト
# 使い方: bash ~/init-dual-agent.sh

set -e  # エラーが発生したら即座にスクリプトを停止する

# AGENTS.md を作成（ヒアドキュメントで一括書き込み）
cat > AGENTS.md << 'EOF'
# デュアルエージェント開発ガイド

## 役割分担

| 役割 | ツール | 担当 |
|------|--------|------|
| Builder | Google Antigravity | コードを書く・修正する |
| Auditor | Codex CLI | レビュー・問題を指摘する |

## ワークフロー

1. Antigravity で実装
2. `git add . && git commit -m "実装内容"` でコミット
3. 以下を実行してレビュー:

    codex exec "このプロジェクトのコードをレビューして。以下の形式で日本語で報告して。
    ## レビュー結果
    ### 🔴 重大（すぐに修正が必要）
    ### 🟡 注意（できれば修正を推奨）
    ### 🟢 軽微（余裕があれば対応）
    ### 💡 改善提案
    各項目は「何が問題か」「なぜ問題か」「どう直すか」を簡潔に説明すること。" --sandbox danger-full-access
4. 問題があれば Antigravity で修正
5. 問題がなくなるまで 2-4 を繰り返す

## レビュー出力フォーマット

レビュー結果は以下の形式で日本語出力すること：

### 🔴 重大（すぐに修正が必要）
### 🟡 注意（できれば修正を推奨）
### 🟢 軽微（余裕があれば対応）
### 💡 改善提案

各項目は以下を含めること：
- **何が問題か**: 問題の概要
- **なぜ問題か**: 放置した場合のリスク
- **どう直すか**: 具体的な修正方法

## 注意事項

- Auditor（Codex CLI）は読み取り専用として扱う
- 修正は必ず Builder（Antigravity）で行う
EOF

# .gitignore に追加（既に存在する場合はスキップ）
if [ ! -f .gitignore ]; then
    echo "# 環境・キャッシュ" > .gitignore
fi

# 完了メッセージ
echo ""
echo "デュアルエージェント開発環境を初期化しました"
echo ""
echo "作成されたファイル:"
echo "  - AGENTS.md（役割分担とワークフローの説明）"
echo ""
echo "次のステップ:"
echo "  1. Antigravity でプロジェクトを開く"
echo "  2. AGENTS.md を参照して開発を進める"
```

**3. 保存して終了**

- `Ctrl + O` を押して、Enter で保存
- `Ctrl + X` で終了

**4. 実行権限を付与**

```bash
chmod +x ~/init-dual-agent.sh  # このファイルをプログラムとして実行できるようにする
```

### 使い方

新しいプロジェクトを始めるとき、プロジェクトフォルダに移動してスクリプトを実行する。

```bash
cd /mnt/c/Users/あなたのユーザー名/Documents/my-project
bash ~/init-dual-agent.sh
```

![git init と初期化スクリプトの実行結果](/images/dual-agent-init-flow.png)
*git init 後に初期化スクリプトを実行すると、AGENTS.md が作成されます*

:::message
**`/mnt/c/` とは**
WSL から Windows の C ドライブにアクセスするためのパス。Windows のフォルダを WSL で操作するときに使う。
:::

---

## Step 4: 自動レビューゲートの仕組み

### AGENTS.md の役割

先ほどのスクリプトで作成した `AGENTS.md` は、開発の進め方をドキュメント化したもの。AI エージェントに読ませることで、役割分担を理解させる。

### codex exec コマンド

Codex CLI でレビューを実行するには、以下のコマンドを使う。

```bash
codex exec "このプロジェクトのコードをレビューして" --sandbox danger-full-access
```

:::message
**コマンドの意味**
- `codex exec`: Codex CLI をワンショット（1回実行して終了）で動かす
- `"..."`: AI への指示（プロンプト）
- `--sandbox danger-full-access`: サンドボックスを解除し、ファイルにアクセスできるようにする
:::

:::message alert
**`--sandbox danger-full-access` について**

このオプションは「全てのファイルへのアクセスを許可する」という意味。レビューにはファイルの読み取りが必要なため指定している。

ただし、このオプションを付けると AI がファイルを書き換えることもできてしまう。レビューでは「読み取りだけして修正はしない」という前提で使う。

心配な場合は、重要なファイルをコミットしてから実行することで、`git checkout` で戻せる状態にしておく。
:::

### レビュー結果の見方

Codex CLI がレビュー結果を出力する。例えば以下のような形式。

```
## レビュー結果

### 重大な問題
- main.js 23行目: ユーザー入力を検証せずに使用している（セキュリティリスク）

### 改善推奨
- utils.js 45行目: 同じ処理が複数箇所にあるので共通化を検討

### 良い点
- エラーハンドリングが適切に実装されている
```

---

## 実践チュートリアル

実際にデュアルエージェント開発を体験してみよう。

**作るもの**: Qiita のトレンド記事タイトルを取得して表示するスクリプト

### Step 1: Antigravity でプロジェクトを作成

1. Windows で Antigravity を起動
2. `C:\Users\あなたのユーザー名\Documents\Projects` フォルダを開く
3. 以下のように指示する：

```
qiita-trend というフォルダを作成して、その中に Qiita API でトレンド記事を取得する Node.js スクリプトを作って
```

Antigravity がフォルダ作成からコード生成まで行う。生成が完了したら確認を求められるので、内容を確認して承認する。

:::message
Antigravity がフォルダ名を変更した場合（例: `qiita-trend-node`）は、そのフォルダ名に読み替えて作業を続けてください。
:::

### Step 2: デュアルエージェント環境を初期化

WSL を開き、Antigravity が作成したフォルダに移動して初期化する。

```bash
cd /mnt/c/Users/あなたのユーザー名/Documents/Projects/qiita-trend

# Git を初期化
git init

# デュアルエージェント環境を初期化
bash ~/init-dual-agent.sh
```

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

### Step 3: 自動レビューを見守る

生成されたコードをコミットしてから、Codex CLI でレビューする。

:::message
**Git とコミットについて**
`git` はファイルの変更履歴を管理するツール。コミット（commit）は「この時点の状態を保存する」という操作で、いつでもその時点に戻れるようになる。

- `git add .` : 変更したファイルを「次に保存するリスト」に追加
- `git commit -m "メッセージ"` : リストに追加したファイルを保存（メッセージ付き）

詳しい使い方は [Git 公式ドキュメント](https://git-scm.com/book/ja/v2) を参照。
:::

```bash
# コミット
git add .
git commit -m "Add Qiita trend fetcher"

# レビューを実行
codex exec "このプロジェクトの index.js をレビューして。以下の形式で日本語で報告して。

## レビュー結果

### 🔴 重大（すぐに修正が必要）
- 該当なしの場合は「なし」と記載

### 🟡 注意（できれば修正を推奨）
- 該当なしの場合は「なし」と記載

### 🟢 軽微（余裕があれば対応）
- 該当なしの場合は「なし」と記載

### 💡 改善提案
- より良くするためのアイデア

各項目は「何が問題か」「なぜ問題か」「どう直すか」を簡潔に説明すること。" --sandbox danger-full-access
```

レビュー結果を確認する。問題があれば、Antigravity に修正を依頼する。

```
Codex CLI のレビューで以下の問題が指摘されました。修正してください。

- API エラー時のエラーハンドリングが不足
- レート制限を考慮していない
```

修正後、再度コミットしてレビューを実行。問題がなくなるまで繰り返す。

### Step 4: 実行

問題がなくなったら、スクリプトを実行する。

```bash
node index.js
```

Qiita のトレンド記事タイトルが表示されれば成功。

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

### codex exec がタイムアウトする

**症状**: レビューが途中で止まる、またはタイムアウトエラーが出る

**対策**:
- ファイルが多すぎる場合は、対象ファイルを指定する
  ```bash
  codex exec "src/main.js をレビューして" --sandbox danger-full-access
  ```
- ネットワーク接続を確認する

### Landlock エラー

**症状**: 以下のようなエラーが出る
```
Error: Landlock sandbox initialization failed
```

**対策**:
- `--sandbox danger-full-access` オプションが付いているか確認
- WSL を再起動する
  ```bash
  wsl --shutdown
  ```
  その後、Ubuntu を再度起動

### 5回修正しても問題が収束しない

**症状**: 修正 → レビュー → 新しい問題 → 修正... が繰り返される

**対策**:
- 問題を1つずつ修正する（一度に全部直そうとしない）
- レビュー観点を絞る（例: 「セキュリティだけチェックして」）
- 一旦コミットして区切りをつける

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
| **役割分担** | 「作る人」と「チェックする人」を分けることで品質が上がる |
| **既存契約の活用** | 既に両方のサービスを契約していれば追加費用なし |

### デメリット

| デメリット | 説明 |
|-----------|------|
| **セットアップが複雑** | WSL + Node.js + 2つの認証が必要 |
| **2つのターミナル** | 画面を行き来する手間がある |
| **追加費用** | 両方のサービスを新規契約すると月額 $40 程度 |
| **トラブルが起きやすい** | 認証エラー、サンドボックスエラーなど |

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
