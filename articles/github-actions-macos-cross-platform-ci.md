---
title: "macOSを持っていなくても、GitHub Actionsでクロスプラットフォームテストを回す"
emoji: "🍎"
type: "tech"
topics: ["githubactions", "ci", "npm", "nodejs", "個人開発"]
published: false
---

## はじめに

個人開発で CLI ツールを作っている。開発環境は Windows。npm に公開して、macOS や Linux のユーザーにも使ってもらいたい。

しかし、手元に Mac がない。

「macOS で動くかどうか」を確認するために Mac を買うのは現実的ではない。かといって、動作確認をせずにリリースするのも不安だ。

この記事では、**GitHub Actions のマトリックス戦略**を使って、macOS と Linux での動作確認を自動化する方法を解説する。

手元に Mac がなくても、`git push` するだけで macOS 上のテストが走る。

---

## 全体像

やりたいことはシンプルだ。

```
git push
    |
    v
GitHub Actions が起動
    |
    +---> macOS 環境でテストを実行
    |
    +---> Linux 環境でテストを実行
    |
    v
結果を確認（ブラウザ or GitHub Mobile）
```

GitHub Actions は、GitHub が提供する CI/CD（継続的インテグレーション/デリバリー）サービス。コードを push するたびに、指定した環境でコマンドを自動実行してくれる。

ポイントは **macOS の仮想マシンを無料で使える**こと。公開リポジトリなら、macOS ランナーも無料枠で利用できる。

---

## マトリックス戦略とは

GitHub Actions の**マトリックス戦略（matrix strategy）**は、複数の環境で同じテストを並列実行する仕組み。

```yaml
strategy:
  matrix:
    os: [macos-latest, ubuntu-latest]
```

こう書くと、**macOS と Ubuntu の2つの環境**でジョブが同時に走る。OS だけでなく、Node.js のバージョンなども掛け合わせられる。

```yaml
strategy:
  matrix:
    os: [macos-latest, ubuntu-latest]
    node-version: [18, 20, 22]
```

この場合、2 OS x 3 バージョン = **6パターン**のテストが並列で走る。

---

## ワークフローファイルの作成

GitHub Actions のワークフローは、`.github/workflows/` ディレクトリに YAML ファイルとして配置する。

### ファイル構成

```
プロジェクトルート/
  .github/
    workflows/
      cross-platform-test.yml   <-- これを作る
  bin/
  package.json
```

### 完成形

以下は、npm CLI ツールの「初期化 → セットアップ確認」を macOS / Linux で自動テストするワークフローの例。

```yaml:.github/workflows/cross-platform-test.yml
name: Cross-Platform Test

on:
  pull_request:
    branches: [main]
  workflow_dispatch:  # 手動実行ボタン

permissions:
  contents: read

jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [macos-latest, ubuntu-latest]
        node-version: [18]

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - name: Create test project
        run: |
          mkdir /tmp/cli-test-project
          cd /tmp/cli-test-project
          git init
          git config user.email "test@example.com"
          git config user.name "Test"
          npm init -y

      - name: Install CLI from local source
        run: |
          cd /tmp/cli-test-project
          npm install "${{ github.workspace }}"

      - name: Run CLI init
        run: |
          cd /tmp/cli-test-project
          npx my-cli init

      - name: Run CLI verify
        run: |
          cd /tmp/cli-test-project
          npx my-cli verify
```

:::message
`my-cli` の部分は、自分の CLI ツール名に置き換える。テストしたいコマンドも自分のツールに合わせて追加・変更する。
:::

---

## 各ステップの解説

### トリガー設定

```yaml
on:
  pull_request:
    branches: [main]
  workflow_dispatch:
```

- **pull_request**: main ブランチへの PR 作成時に自動実行
- **workflow_dispatch**: GitHub の画面から手動で実行できるボタンを追加

開発中は `workflow_dispatch` が便利。「今すぐ macOS で試したい」時にボタン一つで実行できる。

### fail-fast: false

```yaml
strategy:
  fail-fast: false
```

デフォルトでは、1つの OS でテストが失敗すると他の OS のテストも中断される。`fail-fast: false` にすると、**全 OS のテストが最後まで走る**。

macOS は通るが Linux は落ちる（またはその逆）というケースを見逃さないための設定。

### テストプロジェクトの作成

```yaml
- name: Create test project
  run: |
    mkdir /tmp/cli-test-project
    cd /tmp/cli-test-project
    git init
    git config user.email "test@example.com"
    git config user.name "Test"
    npm init -y
```

CI 上に**空のプロジェクト**を作る。実際のユーザーが CLI を初めて使う状況を再現している。

`git init` と `git config` は、Git リポジトリとして初期化するために必要（CLI が git 操作を行う場合）。`npm init -y` は `package.json` を自動生成する。

:::message
CLI ツールが git を使わない場合は `git init` と `git config` の行は不要。自分のツールの前提条件に合わせて調整する。
:::

### ローカルソースからのインストール

```yaml
- name: Install CLI from local source
  run: |
    cd /tmp/cli-test-project
    npm install "${{ github.workspace }}"
```

`${{ github.workspace }}` は、チェックアウトしたリポジトリのパス。npm に公開済みのバージョンではなく、**PR のコード**をそのままインストールしてテストする。

これにより「npm publish する前に macOS で動くか確認」できる。

### CLI コマンドの実行

```yaml
- name: Run CLI init
  run: |
    cd /tmp/cli-test-project
    npx my-cli init

- name: Run CLI verify
  run: |
    cd /tmp/cli-test-project
    npx my-cli verify
```

CLI の主要コマンドを順番に実行する。どれか1つでも失敗すれば、そのステップで赤くなる。

ここでテストするのは「ユーザーが最初にやる操作」がベスト。初期化 → セットアップ確認のように、**ユーザーの最初の体験**が壊れていないかを検証する。

---

## OS ごとの注意点

クロスプラットフォームで CLI を動かすと、OS 固有の問題に遭遇する。CI で事前に検出できるものをまとめた。

### シェルスクリプトの実行権限

macOS / Linux では、シェルスクリプト（`.sh`）に**実行権限**が必要。

```javascript
// CLI の初期化処理で権限を設定する例
const { chmodSync } = require("node:fs");
chmodSync(path.join(targetDir, "run.sh"), 0o755);
```

Windows では権限の概念が異なるため、`process.platform` で分岐する。

```javascript
if (process.platform !== "win32") {
  chmodSync(scriptPath, 0o755);
}
```

これを忘れると、macOS / Linux で `Permission denied` エラーが出る。Windows だけで開発していると気づけない典型的なバグだ。

### Python コマンド名の違い

CLI が内部で Python スクリプトを呼ぶ場合、コマンド名が OS によって異なる。

| OS            | コマンド                                     |
| ------------- | -------------------------------------------- |
| macOS / Linux | `python3`（`python` は Python 2 の場合あり） |
| Windows       | `python`（Microsoft Store 版）               |

CLI 内で Python を検出する場合、両方を試す必要がある。

```javascript
const { execSync } = require("node:child_process");

function findPython() {
  for (const cmd of ["python3", "python"]) {
    try {
      execSync(`${cmd} --version`, { stdio: "pipe" });
      return cmd;
    } catch {
      // 次の候補を試す
    }
  }
  return null;
}
```

### パス区切り文字

| OS            | 区切り文字              | 例                 |
| ------------- | ----------------------- | ------------------ |
| Windows       | `\`（バックスラッシュ） | `C:\Dev\project`   |
| macOS / Linux | `/`（スラッシュ）       | `/opt/dev/project` |

`path.join()` を使えば OS に応じた区切り文字が自動で使われる。文字列結合（`dir + "/" + file`）は避ける。

```javascript
const path = require("node:path");

// 悪い例（Linux では動くが Windows で問題になりうる）
const filePath = configDir + "/" + "settings.json";

// 良い例（どの OS でも正しい）
const filePath = path.join(configDir, "settings.json");
```

### 改行コード

| OS            | 改行コード     |
| ------------- | -------------- |
| Windows       | `\r\n`（CRLF） |
| macOS / Linux | `\n`（LF）     |

`.gitattributes` で統一するのが定番。

```
* text=auto eol=lf
```

CLI がファイルを読み書きする場合、改行コードの不一致でテストが落ちることがある。`eol=lf` で統一しておけば、どの OS でも同じ改行コードになる。

---

## 実行結果の確認方法

### GitHub の画面で確認

PR を作成すると、**Checks タブ**にテスト結果が表示される。

- 緑のチェックマーク: 全 OS で成功
- 赤のバツ印: いずれかの OS で失敗

マトリックス戦略を使っていると、**どの OS で失敗したか**が一目でわかる。

### workflow_dispatch で手動実行

リポジトリの **Actions タブ** → ワークフロー名 → **Run workflow** ボタンで手動実行できる。

ブランチを選べるので、「この修正で macOS のテストが通るか」をすぐに確認できる。

---

## コスト

GitHub Actions の無料枠は公開リポジトリなら実質無制限。

ただし、**macOS ランナーは Linux の10倍のコスト**で計算される（プライベートリポジトリの場合）。

| ランナー       | 1分あたりの消費（プライベートリポ） |
| -------------- | ----------------------------------- |
| Linux (ubuntu) | 1分                                 |
| macOS          | 10分                                |
| Windows        | 2分                                 |

公開リポジトリなら気にする必要はないが、プライベートリポで使う場合は `workflow_dispatch`（手動実行）のみにして、PR ごとの自動実行を避けるのも手だ。

---

## まとめ

| ポイント     | 内容                                                |
| ------------ | --------------------------------------------------- |
| 解決した問題 | Mac を持っていなくても macOS での動作確認ができる   |
| 使う機能     | GitHub Actions のマトリックス戦略                   |
| コスト       | 公開リポジトリなら無料                              |
| テスト内容   | CLI の初期化 → セットアップ確認の E2E フロー        |
| OS 固有の罠  | 実行権限、Python コマンド名、パス区切り、改行コード |

**覚えておくこと**：

> Mac を買う前に、GitHub Actions を試せ。

---

## 参考

- [GitHub Actions - ワークフロー構文（公式）](https://docs.github.com/ja/actions/using-workflows/workflow-syntax-for-github-actions)
- [GitHub Actions - マトリックス戦略（公式）](https://docs.github.com/ja/actions/using-jobs/using-a-matrix-for-your-jobs)
- [GitHub Actions の課金について（公式）](https://docs.github.com/ja/billing/managing-billing-for-github-actions/about-billing-for-github-actions)
