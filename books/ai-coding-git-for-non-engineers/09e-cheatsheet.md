---
title: "チートシート"
---

## この章のゴール

> このページは印刷して手元に置いたり、ブックマークしてすぐ引けるようにしたりすると便利。本書で登場した操作をすべてまとめた。

---

## 1. Git コマンド早見表（逆引き形式）

「やりたいこと」から Git コマンドを探せる。

### 初期設定

| やりたいこと | コマンド | 章 |
|------------|---------|-----|
| 名前を登録する | `git config --global user.name "名前"` | 第 2 章 |
| メールアドレスを登録する | `git config --global user.email "メール"` | 第 2 章 |
| 設定を確認する | `git config --list` | 第 9a 章 |
| 改行コードの自動変換を設定する（Windows） | `git config --global core.autocrlf true` | 第 9 章 |
| デフォルトブランチ名を main にする | `git config --global init.defaultBranch main` | 第 2 章 |

### リポジトリの作成・取得

| やりたいこと | コマンド | 章 |
|------------|---------|-----|
| 新しいリポジトリを作る | `git init` | 第 3 章 |
| GitHub のリポジトリをコピーする | `git clone URL` | 第 5 章 |

### 状態の確認

| やりたいこと | コマンド | 章 |
|------------|---------|-----|
| 変更の有無を確認する | `git status` | 第 3 章 |
| コミット履歴を見る | `git log --oneline` | 第 4 章 |
| 操作履歴を見る（最後の砦） | `git reflog` | 第 9 章 |
| リモートの登録状態を確認する | `git remote -v` | 第 5 章 |

### 記録する（add / commit）

| やりたいこと | コマンド | 章 |
|------------|---------|-----|
| 特定のファイルをステージングする | `git add ファイル名` | 第 4 章 |
| すべての変更をステージングする | `git add .` | 第 4 章 |
| ステージングを取り消す | `git restore --staged ファイル名` | 第 4 章 |
| 変更を記録する | `git commit -m "メッセージ"` | 第 4 章 |
| 直前のコミットメッセージを書き換える | `git commit --amend -m "新メッセージ"` | 第 9b 章 |

### GitHub とのやりとり（push / pull）

| やりたいこと | コマンド | 章 |
|------------|---------|-----|
| リモートを登録する | `git remote add origin URL` | 第 5 章 |
| 初めて push する | `git push -u origin main` | 第 5 章 |
| 2 回目以降の push | `git push` | 第 5 章 |
| GitHub の最新を取り込む | `git pull` | 第 5 章 |
| リモート URL を変更する | `git remote set-url origin 新URL` | 第 9c 章 |

### ブランチ操作

| やりたいこと | コマンド | 章 |
|------------|---------|-----|
| ブランチを作って移動する | `git switch -c ブランチ名` | 第 6 章 |
| ブランチを切り替える | `git switch ブランチ名` | 第 6 章 |
| ブランチを main にマージする | `git merge ブランチ名`（main 上で実行） | 第 6 章 |
| 変更を一時退避する | `git stash` | 第 6 章 |
| 退避した変更を復元する | `git stash pop` | 第 6 章 |

### 取り消し・復旧

| やりたいこと | コマンド | 章 |
|------------|---------|-----|
| コミット前の変更を元に戻す | `git restore ファイル名` | 第 9 章 |
| すべてのファイルの変更を元に戻す | `git restore .` | 第 9 章 |
| 直前のコミットを取り消す（変更は残す） | `git reset --soft HEAD~1` | 第 9 章 |
| push 済みのコミットを打ち消す | `git revert HEAD` | 第 8 章、第 9 章 |
| マージを中止する | `git merge --abort` | 第 9c 章 |

### .gitignore 関連

| やりたいこと | コマンド | 章 |
|------------|---------|-----|
| ファイルを Git の追跡から外す | `git rm --cached ファイル名` | 第 9 章 |
| フォルダごと追跡から外す | `git rm --cached -r フォルダ名` | 第 9 章 |

---

## 2. VS Code 操作と CLI 対応表

VS Code の画面操作と、裏で実行されている Git コマンドの対応。

| VS Code の操作 | 対応する CLI コマンド | 章 |
|---------------|---------------------|-----|
| ソース管理パネルの「+」ボタン | `git add ファイル名` | 第 4 章 |
| ソース管理パネルの「全てステージ」 | `git add .` | 第 4 章 |
| メッセージ入力 → チェックマーク | `git commit -m "メッセージ"` | 第 4 章 |
| ステータスバーの同期ボタン | `git pull` → `git push` | 第 5 章 |
| ステータスバーの発行ボタン | `git remote add` + `git push` | 第 5 章 |
| ステータスバーのブランチ名クリック → 新規作成 | `git switch -c ブランチ名` | 第 6 章 |
| ステータスバーのブランチ名クリック → 選択 | `git switch ブランチ名` | 第 6 章 |
| ソース管理パネルの「変更を破棄」 | `git restore ファイル名` | 第 9 章 |
| ソース管理パネルの「-」ボタン | `git restore --staged ファイル名` | 第 4 章 |
| ターミナルパネル（`` Ctrl+` ``） | CLI を直接入力 | 全章 |

:::message
VS Code の「同期」ボタンは `git pull` と `git push` を連続で実行する。つまり「最新を取り込んでから送信する」を一発で行う操作だ。
:::

---

## 3. トラブル対応フローチャート

エラーや困った状況に遭遇したとき、この流れで対応する。

### push できない

```
push できない
├── "failed to push some refs" と表示される
│   └── git pull してから git push → 第9章6、第9c章 #2
├── "no upstream branch" と表示される
│   └── git push -u origin ブランチ名 → 第9章6
├── "Permission denied (publickey)" と表示される
│   └── HTTPS に切り替え → 第9c章 #9
└── "Could not resolve host" と表示される
    └── インターネット接続を確認 → 第9c章 #14
```

### コンフリクトが出た

```
CONFLICT と表示された
├── VS Code にハイライトが出ている
│   ├── 自分の変更を採用 → Accept Current Change
│   ├── 相手の変更を採用 → Accept Incoming Change
│   └── 両方残す → Accept Both Changes
│   └── 保存 → git add . → git commit → 第9章4
└── マージ自体をやめたい
    └── git merge --abort → 第9c章 #18
```

### コミットを取り消したい

```
コミットを取り消したい
├── まだ push していない
│   └── git reset --soft HEAD~1 → 第9章2
└── すでに push した
    └── git revert HEAD → 第9章2
```

### ファイルの変更を元に戻したい

```
変更を元に戻したい
├── まだ add していない（ステージング前）
│   └── git restore ファイル名 → 第9章1
├── add したが commit していない
│   └── git restore --staged ファイル名 → 第4章
└── commit してしまった
    └── 上の「コミットを取り消したい」へ
```

### .gitignore が効かない

```
.gitignore に書いたのに追跡される
└── すでに追跡中のファイルだった
    └── git rm --cached ファイル名 → git commit → 第9章3
```

### 「detached HEAD」と表示された

```
detached HEAD
├── 変更がない
│   └── git switch main → 第9章7
└── 変更を保存したい
    └── git switch -c 退避用ブランチ名 → 第9章7
```

### Git が全く動かない（リポジトリが壊れた）

```
fatal: bad object HEAD / リポジトリが壊れた
├── GitHub にリモートがある
│   └── フォルダを退避 → git clone で取り直す → 第9c章 #17
└── ローカルにしかない
    └── git fsck --full で修復を試す → 第9b章5
```

---

## コマンド一覧（アルファベット順）

本書で登場したすべての Git コマンドを、引数なしのアルファベット順で並べた。

| コマンド | 概要 | 主な登場章 |
|---------|------|-----------|
| `git add` | ファイルをステージングする | 第 4 章 |
| `git clone` | リポジトリをコピーする | 第 5 章 |
| `git commit` | 変更を記録する | 第 4 章 |
| `git config` | Git の設定を確認・変更する | 第 2 章、第 9a 章 |
| `git fsck` | リポジトリの整合性を検査する | 第 9b 章 |
| `git init` | リポジトリを作成する | 第 3 章 |
| `git lfs` | 大きなファイルを管理する（Git LFS） | 第 9b 章 |
| `git log` | コミット履歴を表示する | 第 4 章 |
| `git merge` | ブランチを統合する | 第 6 章 |
| `git pull` | リモートの最新を取り込む | 第 5 章 |
| `git push` | ローカルの変更をリモートに送る | 第 5 章 |
| `git reflog` | 操作履歴を表示する（最後の砦） | 第 9 章 |
| `git remote` | リモートの登録を管理する | 第 5 章 |
| `git reset` | コミットを巻き戻す | 第 9 章 |
| `git restore` | ファイルの変更を元に戻す | 第 9 章 |
| `git revert` | コミットを打ち消す新しいコミットを作る | 第 8 章、第 9 章 |
| `git rm` | ファイルを Git の追跡から外す | 第 9 章 |
| `git stash` | 変更を一時退避する | 第 6 章 |
| `git switch` | ブランチを切り替える・作成する | 第 6 章 |

:::message
**公式ドキュメント**
- [English: Git Reference（全コマンド一覧）](https://git-scm.com/docs)
- [日本語: Git Book](https://git-scm.com/book/ja)
:::
