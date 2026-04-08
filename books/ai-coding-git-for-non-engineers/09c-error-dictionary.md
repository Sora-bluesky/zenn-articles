---
title: "エラーメッセージ逆引き辞典"
---

## この章のゴール

> この章を終えると、Git のエラーメッセージを見て「何が起きたか」「どうすればいいか」が自分で判断できるようになる。

## はじめに

Git のエラーメッセージは全て英語で表示される。初めて見ると怖いが、実はどのメッセージも「何が起きて、どうすればいいか」を教えてくれている。

このページをブックマークしておけば、エラーが出たときにすぐ引ける。

:::message
エラーメッセージの先頭にある単語で深刻度がわかる。

| 先頭の単語 | 深刻度 | 意味 |
|-----------|--------|------|
| `fatal` | 高 | 処理が中断された。何かを直さないと先に進めない |
| `error` | 中 | 問題があるが、一部は処理できた場合もある |
| `warning` | 低 | 処理は完了したが、注意してほしいことがある |
| `hint` | 情報 | 「次にこうすれば？」という Git からの提案 |
:::

---

### 1. `fatal: not a git repository (or any of the parent directories): .git`

**意味**: ここは Git リポジトリではない（`.git` フォルダが見つからない）

**よくある場面**: ターミナルで Git コマンドを実行したが、カレントディレクトリ（今いる場所）が Git で管理されていない。VS Code で別のフォルダを開いている場合にも発生する。

**解決策**:

正しいプロジェクトフォルダに移動する。

```bash
cd プロジェクトのフォルダパス
```

新規プロジェクトの場合は `git init` でリポジトリを作成する（第 3 章参照）。

**参照**: 第 3 章

---

### 2. `error: failed to push some refs to`

**意味**: push が拒否された（リモートにローカルにない変更がある）

**よくある場面**: 自分が作業している間に、他の人（または別のデバイスの自分）が GitHub に先に push していた。あるいは、GitHub 上で直接ファイルを編集した後、ローカルから push しようとした。

**解決策**:

まずリモートの変更を取り込んでから push する。

```bash
git pull origin main
# コンフリクトがあれば解消（第9章4参照）
git push
```

**参照**: 第 5 章、第 9 章

---

### 3. `error: src refspec main does not match any`

**意味**: 「main」というブランチが見つからない（まだ 1 回もコミットしていない）

**よくある場面**: `git init` でリポジトリを作った直後に、コミットせずに `git push` しようとした。Git はコミットが 1 つもない状態では、ブランチが存在しない扱いになる。

**解決策**:

まず最低 1 回のコミットを行う。

```bash
git add .
git commit -m "first commit"
git push -u origin main
```

**参照**: 第 4 章

---

### 4. `CONFLICT (content): Merge conflict in <file>`

**意味**: ファイルの同じ箇所が別々に変更されており、Git が自動で統合できなかった

**よくある場面**: `git pull` や `git merge` を実行したとき、自分の変更と相手の変更が同じファイルの同じ行にぶつかった。AI が生成したコードと、自分が手動で編集した箇所が重なった場合にも起きる。

**解決策**:

VS Code がコンフリクト箇所をハイライト表示する。「Accept Current Change」「Accept Incoming Change」「Accept Both Changes」のいずれかを選び、保存してからコミットする。

```bash
# コンフリクトを解消した後
git add .
git commit -m "fix: コンフリクトを解消"
```

**参照**: 第 9 章

---

### 5. `fatal: refusing to merge unrelated histories`

**意味**: 2 つの履歴がまったく関連のないものなので、マージを拒否した

**よくある場面**: ローカルで `git init` して作業した後、すでに README 等があるリモートリポジトリを追加して `git pull` しようとした。ローカルとリモートの履歴に共通の祖先がないため、Git が「これは間違いでは？」と止めてくれている。

**解決策**:

意図的にマージしたい場合は、オプションを付けて実行する。

```bash
git pull origin main --allow-unrelated-histories
```

ただし、コンフリクトが発生する可能性が高い。初心者はリモートリポジトリを `git clone` で取得してから作業を始めるほうが安全だ。

**参照**: 第 5 章

---

### 6. `error: Your local changes to the following files would be overwritten by merge`

**意味**: ローカルの未コミットの変更が、マージによって上書きされてしまう

**よくある場面**: ファイルを編集中（まだコミットしていない状態）で `git pull` や `git switch` を実行した。

**解決策**:

3 つの選択肢がある。状況に応じて選ぶ。

```bash
# 方法1: 変更を一時退避してからpull
git stash
git pull
git stash pop

# 方法2: 変更をコミットしてからpull
git add .
git commit -m "wip: 作業途中を保存"
git pull

# 方法3: 変更を捨ててよい場合
git restore .
git pull
```

**参照**: 第 6 章、第 9 章

---

### 7. `warning: LF will be replaced by CRLF`

**意味**: 改行コードが LF（Mac / Linux 形式）から CRLF（Windows 形式）に自動変換される

**よくある場面**: Windows で Git を使っているとき、ほぼ毎回表示される。これは **警告であって、エラーではない**。処理は正常に完了している。

**解決策**:

気になる場合は、Git の設定で自動変換を有効にする。

```bash
# Windows の場合
git config --global core.autocrlf true
```

多くの場合、この警告は無視しても問題ない。

**参照**: 第 9 章

---

### 8. `fatal: remote origin already exists`

**意味**: 「origin」という名前のリモートはすでに登録されている

**よくある場面**: `git remote add origin URL` を 2 回実行した。あるいは、リモートの URL を変更したいのに `add` を使ってしまった。

**解決策**:

URL を変更したい場合は `set-url` を使う。

```bash
# 登録済みのリモートURLを変更
git remote set-url origin 新しいURL

# 確認
git remote -v
```

一度削除してから追加し直す方法もある。

```bash
git remote remove origin
git remote add origin URL
```

**参照**: 第 5 章

---

### 9. `Permission denied (publickey)`

**意味**: SSH 認証に失敗した（公開鍵が GitHub に登録されていない、または鍵が見つからない）

**よくある場面**: SSH 方式（`git@github.com:...` 形式の URL）でリモートに接続しようとしたが、SSH キーの設定が完了していない。

**解決策**:

本書では HTTPS 接続を推奨している。リモート URL を HTTPS に切り替えれば、このエラーは解消する。

```bash
# 現在のリモートURLを確認
git remote -v

# SSH → HTTPS に変更
git remote set-url origin https://github.com/ユーザー名/リポジトリ名.git
```

SSH を使い続けたい場合は、第 10 章の「SSH 接続」を参照。

**参照**: 第 5 章、第 10 章

---

### 10. `error: pathspec '<file>' did not match any files`

**意味**: 指定したファイルが見つからない

**よくある場面**: `git add ファイル名` で、ファイル名のスペルを間違えた。あるいは、別のフォルダにいる状態でコマンドを実行した。

**解決策**:

ファイル名を確認する。

```bash
# 現在のフォルダにあるファイルを一覧
ls

# Git が認識している変更を確認
git status
```

`git status` に表示されるファイル名をそのままコピーして使うのが確実だ。

**参照**: 第 4 章

---

### 11. `fatal: 'origin' does not appear to be a git repository`

**意味**: 「origin」というリモートが認識できない（URL が間違っている、またはリモートが未登録）

**よくある場面**: `git push origin main` を実行したが、リモートの登録がまだ済んでいない。あるいは URL にタイプミスがある。

**解決策**:

まずリモートの登録状態を確認する。

```bash
# リモートの一覧を確認
git remote -v
```

何も表示されなければ、リモートを登録する。

```bash
git remote add origin https://github.com/ユーザー名/リポジトリ名.git
```

URL が表示されているのにエラーが出る場合は、URL のスペルを確認すること。

**参照**: 第 5 章

---

### 12. `error: The following untracked working tree files would be overwritten`

**意味**: まだ Git が追跡していないファイルが、マージによって上書きされてしまう

**よくある場面**: リモートに同名のファイルが存在し、ローカルにも同名の（まだ追跡していない）ファイルがある状態で `git pull` した。

**解決策**:

ローカルのファイルを別の場所に退避するか、名前を変えてから pull する。

```bash
# ファイルを退避
mv ファイル名 ファイル名.backup

# pull を実行
git pull

# 必要に応じてバックアップと内容を見比べる
```

**参照**: 第 5 章

---

### 13. `hint: Updates were rejected because the remote contains work that you do not have locally`

**意味**: リモートにローカルにない変更がある。まずリモートの変更を取り込んでから push してほしい

**よくある場面**: エラー 2 と同じ状況。`hint` なので Git が解決策を提案してくれている。

**解決策**:

Git の提案どおり、先に pull する。

```bash
git pull origin main
git push
```

**参照**: 第 5 章

---

### 14. `fatal: unable to access 'https://...' : Could not resolve host`

**意味**: 指定された URL のホスト（サーバー）に接続できない

**よくある場面**: インターネットに接続されていない。あるいは URL のドメイン名（`github.com` 部分）にタイプミスがある。VPN を使っている場合、VPN の設定で接続がブロックされることもある。

**解決策**:

1. インターネット接続を確認する（ブラウザで GitHub が開けるか試す）
2. リモート URL のスペルを確認する

```bash
git remote -v
```

ネットワーク自体は問題ないのにこのエラーが出る場合は、社内ネットワークのプロキシ設定が原因の可能性がある。

**参照**: 第 5 章

---

### 15. `error: cannot lock ref 'refs/heads/main'`

**意味**: main ブランチのロックファイルを作成できない（別のプロセスがロックしている）

**よくある場面**: 前回の Git 操作が途中で中断された（PCがスリープした、ターミナルを強制終了した等）結果、ロックファイル（`.git/refs/heads/main.lock`）が残っている。

**解決策**:

ロックファイルを削除する。

```bash
# ロックファイルを削除
rm .git/refs/heads/main.lock
```

:::message alert
`.git` フォルダ内のファイルを削除する数少ない正当なケースである。ただし、削除するのは `.lock` ファイルだけ。それ以外のファイルには触らないこと。
:::

**参照**: 第 9b 章

---

### 16. `warning: ignoring broken ref refs/remotes/origin/HEAD`

**意味**: リモートの HEAD 参照が壊れている

**よくある場面**: リモートリポジトリのデフォルトブランチ名が変更された（例: `master` から `main` に変わった）後に発生する。

**解決策**:

リモート情報を更新する。

```bash
git remote set-head origin --auto
```

この警告は無視しても通常の操作には影響しないが、気になるなら上記コマンドで解消できる。

**参照**: 第 5 章

---

### 17. `fatal: bad object HEAD`

**意味**: HEAD（現在のコミットを指すポインタ）が壊れている

**よくある場面**: `.git` フォルダの中身が破損した。PCの異常終了、ディスクの問題、あるいは `.git` フォルダを手動でいじった場合に発生する。

**解決策**:

GitHub にリモートの正本がある場合は、プロジェクトフォルダを別名に変えて `git clone` し直すのが最も確実だ。

```bash
# 壊れたフォルダを退避
mv プロジェクト名 プロジェクト名_broken

# GitHub から取り直す
git clone https://github.com/ユーザー名/リポジトリ名.git
```

ローカルだけの未 push コミットがある場合は、壊れたフォルダからファイルをコピーして新しいリポジトリにコミットする。

**参照**: 第 9b 章

---

### 18. `error: You have not concluded your merge (MERGE_HEAD exists)`

**意味**: マージが途中のまま放置されている

**よくある場面**: コンフリクトが発生して、解消もキャンセルもしないままコミットしようとした。

**解決策**:

2 つの選択肢がある。

```bash
# マージを完了する（コンフリクトを解消済みの場合）
git add .
git commit -m "merge: コンフリクトを解消"

# マージを中止して元に戻す
git merge --abort
```

**参照**: 第 9 章

---

### 19. `fatal: destination path '...' already exists and is not an empty directory`

**意味**: clone 先のフォルダがすでに存在し、空でもない

**よくある場面**: `git clone` を実行しようとしたが、同じ名前のフォルダがすでにある。

**解決策**:

別の名前を指定して clone する。

```bash
# フォルダ名を指定して clone
git clone https://github.com/ユーザー名/リポジトリ名.git 別のフォルダ名
```

既存フォルダが不要なら削除してから clone する。既存フォルダに作業中のファイルがある場合は、内容を確認してから判断すること。

**参照**: 第 5 章

---

### 20. `error: unable to create file: Permission denied`

**意味**: ファイルの作成に失敗した（権限がない）

**よくある場面**: Windows で、ファイルが別のプログラム（VS Code、AI ツールなど）で開かれている状態で Git 操作を行った。あるいは、管理者権限が必要なフォルダで作業している。

**解決策**:

1. 該当ファイルを開いているプログラムを閉じる
2. VS Code を一度閉じて再度開く
3. Windows の場合、ターミナルを「管理者として実行」で開き直す

それでも解決しない場合は、プロジェクトフォルダの場所を変更する。`C:\Program Files\` 配下ではなく、`C:\Users\ユーザー名\Documents\` 配下などのユーザーフォルダで作業するのが安全だ。

**参照**: 第 2 章

---

## 逆引きインデックス — 場面からエラーを探す

| 場面 | 該当するエラー |
|------|--------------|
| `git push` が通らない | #2, #3, #9, #11, #13, #14 |
| `git pull` で怒られる | #4, #5, #6, #12 |
| ファイル操作で失敗する | #1, #10, #15, #20 |
| マージ・コンフリクト関連 | #4, #5, #18 |
| リポジトリ自体がおかしい | #1, #15, #16, #17 |
| clone がうまくいかない | #14, #19 |
| 警告が出るが処理は成功している | #7, #16 |

:::message
**公式ドキュメント**
- [English: Git Reference](https://git-scm.com/docs)
- [日本語: Git Book](https://git-scm.com/book/ja)
:::
