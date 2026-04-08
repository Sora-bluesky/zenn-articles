---
title: "GitHubに公開する — push と pull"
---

## この章のゴール

> この章を終えると、自分のプロジェクトを GitHub に公開でき、AI ツールがクラウドで動く準備が整う。

## なぜ GitHub に公開するのか

前章まで、Git の記録はすべて**自分のパソコンの中（ローカル）**に保存されていた。これだけでも便利だが、GitHub にアップロードすると、さらに良いことがある。

| ローカルだけ                      | GitHub にも置く場合                       |
| --------------------------------- | ----------------------------------------- |
| 自分のPCでしか見られない          | **どこからでもアクセスできる**            |
| PCが壊れたらデータが消える        | **バックアップになる**                    |
| 自分しか使えない                  | **他の人と共有できる**                    |
| AI ツールがローカルでしか動かない | **GitHub Actions 等でクラウド連携できる** |

AI コーディングの文脈では、GitHub Copilot を使うには GitHub リポジトリが必要だし、Claude Code で作ったものを公開するのも GitHub 経由が最も簡単である。

## 覚える操作は 3 つだけ

| 操作                  | 意味                                  | 方向                |
| --------------------- | ------------------------------------- | ------------------- |
| **push（プッシュ）**  | ローカルの記録を GitHub に送る        | PC → GitHub         |
| **pull（プル）**      | GitHub の最新を取り込む               | GitHub → PC         |
| **clone（クローン）** | GitHub のリポジトリを丸ごとコピーする | GitHub → PC（初回） |

イメージとしてはこうだ。

- **ローカル** = 自分の机
- **GitHub** = チームの共有棚

push は「机から棚に資料を入れる」、pull は「棚から最新の資料を取り出す」操作である。

## GitHub にリポジトリを作る

まず、GitHub 側に「受け入れ先」を作る必要がある。

1. ブラウザで [github.com](https://github.com/) にログイン
2. 右上の **+** アイコン →「New repository」をクリック
3. 以下を入力する

| 項目                       | 入力内容                                             |
| -------------------------- | ---------------------------------------------------- |
| Repository name            | `my-first-project`（ローカルと同じ名前が望ましい）   |
| Description                | 空欄で OK                                            |
| Public / Private           | **Public**（公開）または **Private**（非公開）を選ぶ |
| Initialize this repository | **チェックを入れない**                               |

4. 「Create repository」をクリック

:::message
「Initialize this repository with a README」のチェックは**入れない**こと。ローカルにすでにリポジトリがあるので、GitHub 側を空にしておく必要がある。
:::

リポジトリが作成されると、セットアップ手順の画面が表示される。ここに書かれている URL（`https://github.com/ユーザー名/my-first-project.git`）を使う。

## VS Code から push する

### 手順 1: リモートリポジトリを登録する

VS Code のターミナルで以下を実行する。

```bash
git remote add origin https://github.com/ユーザー名/my-first-project.git
```

:::message
`origin` は「送り先の名前」である。慣例として `origin` を使う。URL は GitHub のリポジトリ画面からコピーできる。
:::

### 手順 2: push する

```bash
git push -u origin main
```

初回の push 時には、GitHub のログインを求められる場合がある。ブラウザが開いたら、画面の指示に従って認証する。

:::message
`-u` は「次回からこの送り先をデフォルトにする」という意味である。2 回目以降は `git push` だけで OK。
:::

### 手順 3: GitHub で確認する

ブラウザで GitHub のリポジトリページを開くと、ローカルで作ったファイルが表示されているはずだ。

おめでとう。あなたのプロジェクトがインターネット上に公開された。

## VS Code の GUI で push する方法

ターミナルを使わなくても、VS Code の GUI から push できる。

1. 「ソース管理」パネルを開く
2. 上部の **「...」メニュー** →「プッシュ」をクリック

初回は「リモートが設定されていません」と聞かれるので、「リモートの追加」→ GitHub の URL を入力する。

2 回目以降は、コミット後にステータスバー（画面下部）の同期アイコン（↑↓）をクリックするだけでよい。

## pull — GitHub の変更を取り込む

別のパソコンで作業したり、GitHub 上でファイルを直接編集したりすると、GitHub 側のほうが新しくなることがある。

そのとき、ローカルに最新の変更を取り込むのが **pull** である。

### VS Code での操作

1. 「ソース管理」パネルを開く
2. **「...」メニュー** →「プル」をクリック

または、ステータスバーの同期アイコン（↑↓）をクリックすると、push と pull が同時に行われる。

## clone — 既存のリポジトリをコピーする

GitHub 上にあるリポジトリを、自分のパソコンにコピーするのが **clone** である。

1. GitHub でリポジトリのページを開く
2. 緑色の「Code」ボタン → URL をコピー
3. VS Code で `Ctrl + Shift + P`（Mac は `Cmd + Shift + P`）→ 「Git: Clone」と入力
4. コピーした URL を貼り付け
5. 保存先フォルダを選択

これで、GitHub のリポジトリがローカルにコピーされる。

## GitHub Pages — 作ったものを無料で公開する

GitHub には、リポジトリの中身をそのまま**ウェブサイトとして公開できる**機能がある。それが **GitHub Pages** だ。

AI に作ってもらった自己紹介ページやポートフォリオサイトを、この機能で世界中に公開できる。

### 設定手順

1. GitHub のリポジトリページで「Settings」タブをクリック
2. 左メニューの「Pages」をクリック
3. 「Source」で **Deploy from a branch** を選択
4. ブランチを **main**、フォルダを **/ (root)** にして「Save」

数分待つと、`https://ユーザー名.github.io/リポジトリ名/` でサイトが公開される。

:::message
GitHub Pages で公開されるのは **Public リポジトリのみ**（無料プランの場合）。Private リポジトリで使うには GitHub Pro（有料）が必要。
:::

## push / pull / clone の関係を整理する

ここまで 3 つの操作を学んだ。関係を図にまとめる。

![push / pull / clone の関係](/images/book-05-push-pull-clone.png)

| 操作    | いつ使うか                                  | 方向        |
| ------- | ------------------------------------------- | ----------- |
| `clone` | 初めてリポジトリをコピーするとき（1回だけ） | GitHub → PC |
| `pull`  | 他の人（やAI）の変更を取り込むとき          | GitHub → PC |
| `push`  | 自分の変更を GitHub に反映するとき          | PC → GitHub |

**AI コーディングでよくある流れ:**

1. GitHub でリポジトリを clone
2. Claude Code でコードを書いてもらう
3. 変更を commit
4. push して GitHub に反映
5. GitHub Pages で公開

## 「やらかした！」復旧コーナー

### 「push したら `no upstream branch` エラーが出た」

以下のコマンドを実行すれば解決する。

```bash
git push -u origin main
```

これは「main ブランチを origin（GitHub）に紐づけて push する」という意味である。初回 push 時に必要になることがある。

### 「push したら認証エラーが出た」

GitHub の認証方式が変わっている場合がある。以下を試してほしい。

1. VS Code のターミナルで `git push` を実行
2. ブラウザが開いたら、GitHub にログインして認証を許可する

それでも解決しない場合は、GitHub の「Settings」→「Developer settings」→「Personal access tokens」から Personal Access Token を発行して認証する方法がある。

### 「push するたびに認証を求められる」

最近の Git for Windows インストーラは **Git Credential Manager** を自動でセットアップする。これが有効なら、一度ログインすれば次回以降は認証を求められない。

もし毎回聞かれる場合は、ターミナルで以下を実行する。

```bash
# Windows
git config --global credential.helper manager

# Mac
git config --global credential.helper osxkeychain
```

これで認証情報がパソコンに安全に保存され、push / pull のたびにログインする必要がなくなる。

---

## 裏で何が起きているか（CLI 解説）

| VS Code の操作 | CLI コマンド                | 意味                        |
| -------------- | --------------------------- | --------------------------- |
| リモート追加   | `git remote add origin URL` | 送り先を登録                |
| プッシュ       | `git push`                  | ローカル → GitHub           |
| プル           | `git pull`                  | GitHub → ローカル           |
| クローン       | `git clone URL`             | GitHub のリポジトリをコピー |
