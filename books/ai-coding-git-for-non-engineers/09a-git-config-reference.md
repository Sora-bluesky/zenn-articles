---
title: "Git 設定リファレンス — 全項目を非エンジニア向けに解説"
---

## この章のゴール

> この章を終えると、Git の主要な設定項目の意味と使いどころがわかり、自分の作業スタイルに合わせて Git をカスタマイズできるようになる。

## この章の使い方

ここまでの章で、Git の基本操作は一通り身についているはずだ。この章は**辞書のように使う**ことを想定している。最初から順番に読む必要はない。

- 「あの設定、何だっけ？」と思ったとき
- AI ツールが `.gitconfig` に何か書き込んでいて、意味を調べたいとき
- Git をもっと自分好みに調整したいとき

そんなときに、目次から該当箇所を探して読めばよい。

### 重要度の見方

各設定項目には重要度を付けてある。

| 表記 | 意味 |
| ---- | ---- |
| ★★★ | 必須 — 初回セットアップで設定すべき |
| ★★☆ | 推奨 — 知っておくと便利 |
| ★☆☆ | 参考 — 上級者向けだが知識として紹介 |

---

## ユーザー情報（user.* / commit.*）

**このカテゴリの設定は「誰がこの変更を行ったか」を記録するためのものである。**

### user.name — コミッターの名前 ★★★

**何をする設定か**: Git で記録を残すときに、「誰が変更したか」として表示される名前を登録する。

**日常の例え**: 会社の書類に押すゴム印の名前。どんな書類を作っても、この名前が自動で記録される。

```bash
git config --global user.name "Taro Yamada"
```

**いつ使うか**: 第 2 章で設定済み。GitHub アカウントの名前と揃えておくのが望ましい。

:::message
第 2 章「準備」で設定済みの項目。詳しい手順はそちらを参照。
:::

### user.email — コミッターのメールアドレス ★★★

**何をする設定か**: Git の記録に紐づくメールアドレス。GitHub はこのアドレスでアカウントと記録を結びつける。

**日常の例え**: 書類のフッターに入る連絡先のようなもの。

```bash
git config --global user.email "taro@example.com"
```

**いつ使うか**: 第 2 章で設定済み。GitHub に登録したメールアドレスと一致させること。

:::message
第 2 章「準備」で設定済みの項目。詳しい手順はそちらを参照。
:::

### user.signingkey — GPG/SSH 署名キー ★☆☆

**何をする設定か**: コミットに「電子署名」を付けるための鍵を指定する。

**日常の例え**: 契約書に使う実印のようなもの。ゴム印（user.name）は誰でも同じ名前で押せてしまうが、実印は本人しか持っていない。電子署名も同じで、「この変更は確かに本人が行った」と証明する仕組みである。

**GPG とは**: 「GNU Privacy Guard」の略で、暗号化や電子署名を行うソフトウェアのこと。SSH 鍵（GitHub に接続するときに使う鍵）でも代用できる。

```bash
# GPG 鍵の場合
git config --global user.signingkey XXXXXXXXXXXXXXXX

# SSH 鍵の場合
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global gpg.format ssh
```

**いつ使うか**: GitHub で「Verified」バッジ（緑色のマーク）を表示させたいときに使う。個人の趣味プロジェクトであれば、設定しなくても問題ない。オープンソースの開発に参加するときや、仕事のリポジトリで署名が必須とされている場合に必要になる。

### commit.gpgsign — 全コミットに署名を付ける ★☆☆

**何をする設定か**: コミットするたびに自動で電子署名を付けるかどうかを決める。

**日常の例え**: 「書類を出すときは必ず実印を押す」というルールを自分に課すようなもの。

```bash
git config --global commit.gpgsign true
```

**いつ使うか**: `user.signingkey` を設定した人向け。`true` にすると、毎回 `git commit -S` と打たなくても自動で署名される。署名キーを設定していない人はこの項目を無視してよい。

---

## エディタと表示（core.*）

**このカテゴリの設定は、Git が情報を「見せる方法」や「ファイルを扱う方法」を制御するものである。**

### core.editor — メッセージ編集に使うエディタ ★★☆

**何をする設定か**: コミットメッセージなどを書くとき、Git がどのテキストエディタを開くかを決める。

**日常の例え**: 「メモを書くときに使う文房具」を指定するようなもの。ボールペンを使うか万年筆を使うかの選択に近い。

```bash
# VS Code を使う場合（おすすめ）
git config --global core.editor "code --wait"
```

`--wait` は「VS Code でファイルを閉じるまで Git が待つ」という意味である。これがないと、Git はエディタを開いた瞬間に「メッセージなし」として処理を進めてしまう。

**いつ使うか**: `git commit` をオプションなしで実行したとき、エディタが開いてメッセージの入力を求められる。第 2 章のインストール時に「VS Code をデフォルトエディタに」を選んでいれば、すでに設定されているはずだ。もし Vim（黒い画面のエディタ）が開いて困った経験があれば、上のコマンドで VS Code に切り替えよう。

:::message alert
Vim が開いてしまった場合の脱出方法: `Esc` キーを押してから `:q!` と入力して `Enter`。これで保存せずに閉じられる。
:::

### core.pager — 出力の表示に使うページャー ★☆☆

**何をする設定か**: `git log` や `git diff` のように長い出力が出るとき、それをどのプログラムで表示するかを決める。

**日常の例え**: 長い巻物を読むとき、スクロールできるビューアで見るか、いきなり全部を広げるかの違いである。

**ページャーとは**: 長いテキストを1画面ずつスクロールして読むための表示プログラム。Git のデフォルトは `less` というプログラムで、矢印キーでスクロール、`q` で閉じる。

```bash
# ページャーを使わない（全部一気に表示）
git config --global core.pager ""

# デフォルト（less）を明示的に設定
git config --global core.pager "less"
```

**いつ使うか**: `git log` の出力が画面に収まらず操作に困った場合に変更する。普段は初期設定のままで問題ない。

### core.autocrlf — 改行コードの自動変換 ★★★

**何をする設定か**: Windows と Mac/Linux で異なる改行コードを自動的に変換するかどうかを決める。

**改行コードとは**: テキストファイルで「ここで改行する」を示す目に見えない記号のこと。Windows は `CRLF`（2 文字分）、Mac/Linux は `LF`（1 文字分）を使う。この違いがあると、同じファイルなのに Git が「変更された」と誤認することがある。

```bash
# Windows の場合
git config --global core.autocrlf true

# Mac の場合
git config --global core.autocrlf input
```

**いつ使うか**: 第 9 章のトラブルシューティング「改行コード問題」で解説済み。Windows ユーザーは `true`、Mac ユーザーは `input` が推奨。

:::message
第 9 章「改行コード問題」で解説済みの項目。具体的な症状と対処法はそちらを参照。
:::

### core.fileMode — ファイルの実行権限を追跡するか ★☆☆

**何をする設定か**: ファイルの「実行権限」が変わったときに、Git がそれを変更として扱うかどうかを決める。

**実行権限とは**: Mac/Linux では、ファイルに「このファイルはプログラムとして実行できる」という属性を付けられる。Windows にはこの概念がないため、Windows と Mac で共同作業していると、実行権限の差分が意図せず発生することがある。

```bash
# 実行権限の変更を無視する（Windows ユーザー推奨）
git config --global core.fileMode false
```

**いつ使うか**: Windows で開発していて、ファイルの中身を何も変えていないのに「変更あり」と表示される場合。Claude Code がスクリプトファイルを作成したときにも起きることがある。

### core.ignorecase — ファイル名の大文字小文字を区別するか ★☆☆

**何をする設定か**: `README.md` と `readme.md` を別のファイルとして扱うかどうかを決める。

**日常の例え**: 名刺の名前で「田中」と「たなか」を同一人物として扱うか、別人として扱うかの設定。

```bash
# 大文字小文字を区別しない（Windows / Mac のデフォルト）
git config --global core.ignorecase true

# 区別する（Linux のデフォルト）
git config --global core.ignorecase false
```

**いつ使うか**: 通常は OS に合わせて自動設定されるので変更不要。ただし、ファイル名を `App.js` から `app.js` にリネームしたのに Git が認識してくれない場合、この設定が原因であることがある。

### core.excludesfile — グローバルな .gitignore の場所 ★★☆

**何をする設定か**: すべてのリポジトリで共通して無視したいファイルのリストを、どこに置くかを指定する。

**日常の例え**: プロジェクトごとの「ゴミ箱に入れるものリスト」とは別に、「家全体のルールとして捨てるもの」を決めるリスト。

```bash
git config --global core.excludesfile ~/.gitignore_global
```

上のコマンドを実行した後、`~/.gitignore_global` ファイルを作成して中身を書く。

```gitignore
# OS が勝手に作るファイル
.DS_Store
Thumbs.db

# エディタの設定ファイル
.vscode/settings.json
*.swp
```

:::message
`~`（チルダ）は「ホームフォルダ」を表す記号である。Windows なら `C:\Users\ユーザー名`、Mac なら `/Users/ユーザー名` のこと。
:::

**いつ使うか**: `.DS_Store`（Mac が自動で作るファイル）や `Thumbs.db`（Windows が作るサムネイルファイル）は、すべてのリポジトリで無視したい。プロジェクトごとに `.gitignore` に書く手間を省ける。

---

## リポジトリの初期化とブランチ（init.* / branch.*）

**このカテゴリの設定は、新しいリポジトリやブランチを作るときの初期値を決めるものである。**

### init.defaultBranch — デフォルトブランチ名 ★★★

**何をする設定か**: `git init` で新しいリポジトリを作ったとき、最初のブランチに何という名前をつけるかを決める。

**日常の例え**: 新しいノートを買ったとき、表紙に最初から書いておくタイトルのようなもの。

```bash
git config --global init.defaultBranch main
```

**いつ使うか**: 第 2 章で設定済み。GitHub は `main` が標準なので、ここが `master` のままだと push 時にエラーが発生する。

:::message
第 2 章「準備」で設定済みの項目。設定しないと Git のバージョンによっては `master` になり、GitHub の `main` と食い違ってトラブルの原因になる。
:::

### branch.autoSetupRebase — 新ブランチの rebase 戦略 ★☆☆

**何をする設定か**: 新しいブランチを作ったとき、`git pull` の動作を自動で「rebase モード」にするかどうかを決める。

**rebase（リベース）とは**: ブランチの「根元」を付け替える操作のこと。通常の `git pull` は「マージ」（合流）を行うが、rebase は「自分の変更を一度外して、最新の状態に乗せ直す」動作をする。履歴がきれいな一直線になるのが特徴である。

```bash
# always: 全ブランチで pull 時に rebase する
git config --global branch.autoSetupRebase always

# never: 常にマージ（デフォルト）
git config --global branch.autoSetupRebase never
```

**いつ使うか**: チームで「履歴をきれいに保つ」方針がある場合に使う。個人開発では設定しなくても困らない。AI コーディングの文脈では、Claude Code がブランチを作成して作業する際、この設定が効いてくる。

### branch.sort — ブランチ一覧の並び順 ★☆☆

**何をする設定か**: `git branch` でブランチ一覧を表示するとき、どの順番で並べるかを決める。

**日常の例え**: 本棚の本を「あいうえお順」にするか「最近読んだ順」にするかの違い。

```bash
# 最近コミットした順（最新が一番上）
git config --global branch.sort -committerdate
```

先頭の `-` は「降順（新しいものが上）」を表す。

**いつ使うか**: ブランチが増えてきたときに便利。AI ツールを使っていると、Claude Code が機能ごとにブランチを作るので、ブランチ数はすぐに増える。最近触ったブランチが上に来れば探しやすい。

---

## プッシュ設定（push.*）

**このカテゴリの設定は、ローカルの変更を GitHub に送るときの動作を制御するものである。**

### push.default — デフォルトの push 動作 ★★☆

**何をする設定か**: `git push` と打ったとき、どの範囲のブランチを送るかを決める。

**日常の例え**: 「棚に入れてきて」と頼まれたとき、手に持っている書類だけ入れるか、机の上の書類を全部入れるかの違い。

```bash
# simple: 今いるブランチだけ push する（デフォルト・推奨）
git config --global push.default simple

# current: 同名のリモートブランチがなければ自動作成して push
git config --global push.default current
```

**いつ使うか**: 通常は `simple`（デフォルト）のままでよい。`current` にすると `push.autoSetupRemote` に近い挙動になるが、明示的に `simple` + `push.autoSetupRemote true` の組み合わせが読みやすい。

### push.autoSetupRemote — 新ブランチの自動 upstream 設定 ★★☆

**何をする設定か**: 新しいブランチを初めて push するとき、`-u origin ブランチ名` を省略できるようにする。

**日常の例え**: 新しい棚を追加したとき、「この棚にはこの書類」という紐づけを自動でやってくれる機能。

```bash
git config --global push.autoSetupRemote true
```

**いつ使うか**: 第 5 章で、初回 push 時に `git push -u origin main` と打つ必要があると説明した。この設定を `true` にすると、`git push` だけで同じことが自動的に行われる。ブランチを頻繁に作る AI コーディングでは、毎回 `-u origin ブランチ名` と打つ手間が省けるので設定しておくと快適になる。

### push.followTags — push 時にタグも送る ★☆☆

**何をする設定か**: `git push` したとき、タグ（バージョン番号の目印）も一緒に GitHub に送るかどうかを決める。

**タグとは**: コミットに「v1.0.0」のようなバージョン番号のラベルを貼る機能。ソフトウェアのリリース時に使われる。

```bash
git config --global push.followTags true
```

**いつ使うか**: タグを使ってバージョン管理をしている場合に便利。設定しないと、`git push` とは別に `git push --tags` を実行する必要がある。個人開発の初期段階ではタグを使わないことが多いので、必要になったら設定すれば十分。

---

## プルとフェッチ（pull.* / fetch.*）

**このカテゴリの設定は、GitHub から変更を取り込むときの動作を制御するものである。**

### pull.rebase — pull 時に merge の代わりに rebase を使う ★★☆

**何をする設定か**: `git pull` で GitHub の変更を取り込むとき、「マージ」と「リベース」のどちらの方法を使うかを決める。

**違いを図で理解する**: 自分がコミット A → B と進めた間に、他の人が GitHub に C をプッシュしていたとする。

- **マージ（merge）**: A → B と C を合流させるコミット M を新しく作る。履歴に「合流点」が残る
- **リベース（rebase）**: 自分の B を C の後に乗せ直して、A → C → B' にする。一直線の履歴になる

```bash
# pull 時に rebase を使う
git config --global pull.rebase true

# マージを使う（デフォルト）
git config --global pull.rebase false
```

**いつ使うか**: 履歴をすっきりさせたい場合は `true` が便利。ただし、リベース中にコンフリクト（衝突）が起きると対処が少し面倒になる。迷ったらデフォルト（`false`）のままでよい。

### pull.ff — fast-forward ポリシー ★☆☆

**何をする設定か**: `git pull` で取り込むとき、fast-forward が可能な場合にどうするかを決める。

**fast-forward（ファストフォワード）とは**: 自分が何も変更していない状態で pull したとき、単に「最新地点まで進める」だけで済む状況のこと。録画した番組を「早送り」で追いつくイメージ。この場合、合流のためのコミットは不要になる。

```bash
# fast-forward できるときだけ pull する（マージコミットを作らない）
git config --global pull.ff only

# デフォルト動作（fast-forward できなければマージ）
git config --global pull.ff true
```

**いつ使うか**: `only` にすると、自分のローカルに未プッシュの変更があるときに pull が失敗する（意図的にエラーにして、手動で対処を促す）。安全策として使う人もいるが、初心者は設定しないほうが混乱しにくい。

### fetch.prune — リモートで消えたブランチを自動削除 ★★☆

**何をする設定か**: `git fetch` や `git pull` のとき、GitHub 側で削除されたブランチの参照をローカルからも自動で消すかどうかを決める。

**日常の例え**: 共有棚から撤去された書類の「棚ラベル」を、自分のメモからも自動で消してくれる機能。

```bash
git config --global fetch.prune true
```

**いつ使うか**: AI コーディングではブランチの作成・削除が頻繁に行われる。GitHub でマージ済みのブランチを削除しても、ローカルには「もう存在しないリモートブランチ」の参照がゾンビのように残り続ける。`true` にしておくと自動で掃除してくれる。

### fetch.pruneTags — リモートで消えたタグも自動削除 ★☆☆

**何をする設定か**: `fetch.prune` のタグ版。GitHub 側で消えたタグの参照をローカルからも自動で消す。

```bash
git config --global fetch.pruneTags true
```

**いつ使うか**: タグを頻繁に作り直す運用をしている場合に便利。そうでなければ設定不要。

---

## マージとリベース（merge.* / rebase.*）

**このカテゴリの設定は、ブランチを合流させるときの動作や表示を制御するものである。**

### merge.conflictstyle — コンフリクトマーカーのフォーマット ★★☆

**何をする設定か**: コンフリクト（衝突）が起きたとき、ファイルに書き込まれる「ここが衝突しています」のマーカーの形式を選ぶ。

**コンフリクトマーカーとは**: Git が衝突を知らせるために、ファイルの中に挿入する区切り線。`<<<<<<<` と `>>>>>>>` で囲まれた部分が衝突箇所である。

```bash
# diff3: 「共通の祖先（変更前の状態）」も表示する
git config --global merge.conflictstyle diff3

# zdiff3: diff3 の改良版（Git 2.35 以降）
git config --global merge.conflictstyle zdiff3
```

`diff3` を設定すると、衝突箇所に「もともとどうだったか」も表示されるため、どちらの変更を採用すべきか判断しやすくなる。

**いつ使うか**: コンフリクト解決に慣れてきたら `diff3` または `zdiff3` に変更するのがおすすめ。VS Code のコンフリクト解決画面と組み合わせると、より情報の多い状態で判断できる。

### merge.tool — コンフリクト解決ツール ★☆☆

**何をする設定か**: `git mergetool` コマンドで起動するコンフリクト解決専用ツールを指定する。

```bash
# VS Code を使う場合
git config --global merge.tool vscode
git config --global mergetool.vscode.cmd 'code --wait $MERGED'
```

**いつ使うか**: VS Code の標準機能（ソース管理パネル）でコンフリクトを解決できるので、無理に設定する必要はない。専用のマージツール（Beyond Compare, P4Merge など）を使いたい場合に設定する。

### rebase.autoStash — rebase 前に自動スタッシュ ★★☆

**何をする設定か**: リベースを実行するとき、まだコミットしていない変更を自動的に一時退避（スタッシュ）してくれるかどうかを決める。

**スタッシュ（stash）とは**: 作業途中の変更を一時的に「引き出し」にしまっておく機能。リベースはクリーンな状態（未コミットの変更がない状態）でないと実行できないため、手動でスタッシュする手間を省ける。

```bash
git config --global rebase.autoStash true
```

**いつ使うか**: `pull.rebase true` を設定している人は、これも `true` にしておくとよい。「作業中に pull したらエラーになった」という事態を防げる。

### rebase.autoSquash — fixup コミットの自動結合 ★☆☆

**何をする設定か**: `git commit --fixup` で作った「修正用コミット」を、リベース時に自動で元のコミットに統合するかどうかを決める。

**fixup コミットとは**: 「さっきのコミットの修正です」という印を付けた特別なコミット。リベース時に自動的に元のコミットと合体して、履歴をきれいに保つ。

```bash
git config --global rebase.autoSquash true
```

**いつ使うか**: コミット履歴を整理する習慣がある中級者以上向け。初心者は設定不要。

### rebase.updateRefs — 関連ブランチの自動更新 ★☆☆

**何をする設定か**: リベースで履歴を書き換えたとき、影響を受ける他のブランチの参照先も自動で更新するかどうかを決める。

```bash
git config --global rebase.updateRefs true
```

**いつ使うか**: 複数のブランチを連鎖的に管理している（ブランチ A の上にブランチ B を作っている等の）場合に便利。個人開発ではほぼ使わない。

---

## 差分表示とカラー（diff.* / color.*）

**このカテゴリの設定は、変更内容の表示方法や見た目を制御するものである。**

### diff.algorithm — diff アルゴリズム ★☆☆

**何をする設定か**: 2 つのファイルの違いを計算するとき、どの計算方法（アルゴリズム）を使うかを選ぶ。

**日常の例え**: 2 つの文章を見比べて「どこが変わったか」を見つける方法が複数あるということ。シンプルな方法は速いが、場合によっては「本当はここだけ変わったのに、全体が変わったように見える」ことがある。賢い方法は少し遅いが、より正確に差分を見つける。

```bash
# histogram: より正確な差分表示（おすすめ）
git config --global diff.algorithm histogram
```

**いつ使うか**: デフォルトの `myers` でも十分だが、`histogram` に変えると差分の表示がより直感的になることがある。処理速度の違いは体感できないので、`histogram` にしておいて損はない。

### diff.colorMoved — 移動行のハイライト ★★☆

**何をする設定か**: コードを「別の場所に移動しただけ」の変更を、通常の追加・削除とは違う色で表示する。

**日常の例え**: 文章校正で、段落の順番を入れ替えた箇所を「移動」と明示してくれるマーカーのようなもの。

```bash
# default: 移動した行を別の色で表示
git config --global diff.colorMoved default

# zebra: さらに見やすい交互ハイライト
git config --global diff.colorMoved zebra
```

**いつ使うか**: AI にコードを書き直してもらったとき、「新しく書いた部分」と「場所を変えただけの部分」を区別しやすくなる。`default` か `zebra` を設定しておくのがおすすめ。

### diff.mnemonicPrefix — ニーモニックプレフィックス ★☆☆

**何をする設定か**: `git diff` の出力で、比較元と比較先を示すプレフィックス（接頭辞）をわかりやすい文字に変更する。

**デフォルトの表示**: `a/ファイル名` と `b/ファイル名`（a と b には特に意味がない）

**この設定後の表示例**: `w/ファイル名`（working = 作業ディレクトリ）と `i/ファイル名`（index = ステージング）のように、場所を示す頭文字になる。

```bash
git config --global diff.mnemonicPrefix true
```

**いつ使うか**: ターミナルで `git diff` を頻繁に見る人向け。VS Code の GUI で差分を確認する場合は影響がないので、設定しなくてよい。

### diff.renames — リネーム検出 ★★☆

**何をする設定か**: ファイルの名前を変えたとき、Git がそれを「削除 + 新規作成」ではなく「名前変更」として認識するかどうかを決める。

**日常の例え**: 書類のファイル名を「報告書.doc」から「月次報告書.doc」に変えたとき、「報告書.doc を削除して月次報告書.doc を作った」と記録するか、「報告書.doc を月次報告書.doc にリネームした」と記録するかの違い。

```bash
# true: リネーム検出を有効にする（デフォルト）
git config --global diff.renames true

# copies: リネームだけでなくコピーも検出する
git config --global diff.renames copies
```

**いつ使うか**: デフォルトで有効なので、通常は変更不要。AI がファイル構成を大幅に変更した場合、`copies` にしておくとより正確な差分が見られることがある。

### color.ui — カラー出力 ★★☆

**何をする設定か**: Git のターミナル出力に色をつけるかどうかを決める。

```bash
# auto: ターミナルが色を表示できるなら色をつける（デフォルト・推奨）
git config --global color.ui auto
```

**いつ使うか**: 現在の Git ではデフォルトで `auto` が設定されているため、通常は変更不要。もしターミナルの Git 出力がすべて白黒で見づらい場合は、この設定を確認する。

---

## エイリアス（alias.*）

**このカテゴリの設定は、長いコマンドに短い名前をつけるショートカット機能である。**

**日常の例え**: スマートフォンの「短縮ダイヤル」のようなもの。よく電話する相手をワンタップで呼び出せるのと同じで、よく使う Git コマンドを短い名前で実行できる。

### よく使われるエイリアス一覧

```bash
# st → status（状態確認）
git config --global alias.st status

# co → checkout（ブランチ切り替え）
git config --global alias.co checkout

# br → branch（ブランチ一覧）
git config --global alias.br branch

# ci → commit（記録）
git config --global alias.ci commit

# lg → きれいなログ表示
git config --global alias.lg "log --oneline --graph --decorate"

# last → 直前のコミットを表示
git config --global alias.last "log -1 HEAD"

# unstage → ステージングの取り消し
git config --global alias.unstage "reset HEAD --"
```

**設定後の使い方**:

```bash
# 設定前: git status
# 設定後: git st

# 設定前: git log --oneline --graph --decorate
# 設定後: git lg
```

### いつ使うか ★★☆

エイリアスは完全に好みの問題で、設定しなくても Git の全機能を使える。ただし `git lg`（ログをグラフで表示）は、ブランチの分岐と合流を視覚的に確認できるので設定しておくと便利。AI が複数のブランチで作業した履歴を追うとき、一直線のログより格段に見やすい。

:::message alert
エイリアスの名前が既存の Git コマンドと被ると、エイリアスのほうが優先される。`alias.push` のような設定は避けること。
:::

---

## 認証情報（credential.*）

**このカテゴリの設定は、GitHub への接続時にユーザー名やパスワード（トークン）をどう管理するかを制御するものである。**

### credential.helper — 認証情報の保存方法 ★★★

**何をする設定か**: GitHub に push / pull するとき、毎回パスワード（トークン）を入力しなくて済むように、認証情報の保存方法を指定する。

**日常の例え**: 会社の入館カードをどこに保管するかの選択。「毎回受付で手続き」するか、「カードケースに入れて持ち歩く」か、「自宅の金庫にしまう」かの違い。

```bash
# Windows（Git Credential Manager を使用 — 推奨）
git config --global credential.helper manager

# Mac（キーチェーンに保存）
git config --global credential.helper osxkeychain

# Linux（一定時間メモリに保持）
git config --global credential.helper cache
```

**いつ使うか**: 第 5 章「push するたびに認証を求められる」で解説済み。最近の Git for Windows は Git Credential Manager を自動でセットアップするため、手動設定が必要になるのは認証の不具合が起きたときである。

:::message
第 5 章の「やらかした！復旧コーナー」で解説済みの項目。push のたびにログインを求められる場合の対処法はそちらを参照。
:::

### credential.useHttpPath — URL パスごとに別の認証情報を使う ★☆☆

**何をする設定か**: 同じ GitHub でも、リポジトリごとに異なるアカウントの認証情報を使い分けるかどうかを決める。

**日常の例え**: 同じビルに入るのに、3 階は A さんのカード、5 階は B さんのカードを使うようなもの。

```bash
git config --global credential.useHttpPath true
```

**いつ使うか**: GitHub アカウントを複数使い分けている場合（個人アカウントと仕事用アカウントなど）。1 つのアカウントしか使わないなら設定不要。

---

## 設定の確認・管理コマンド

ここまで紹介した設定を確認・修正するためのコマンドをまとめる。

### 全設定を一覧表示する

```bash
git config --list
```

設定中のすべての項目が表示される。量が多くなることがあるので、特定の項目だけ見たい場合は次のコマンドを使う。

### 設定ファイルの場所も表示する

```bash
git config --list --show-origin
```

各設定がどのファイルに書かれているかも表示される。「この設定はどこから来ているのか」を調べたいときに使う。

Git の設定は 3 つの階層があり、下の階層ほど優先される。

| 階層 | ファイルの場所 | 適用範囲 |
| ---- | ---- | ---- |
| system | Git のインストールフォルダ内 | PC 全体 |
| global | ホームフォルダの `.gitconfig` | 現在のユーザー全体 |
| local | リポジトリの `.git/config` | そのリポジトリだけ |

### 特定の設定値を確認する

```bash
git config --get user.name
```

### 設定ファイルを直接開く

```bash
git config --global --edit
```

テキストエディタで `.gitconfig` ファイルが開く。慣れてきたら、コマンドを 1 つずつ打つ代わりに、このファイルを直接編集するほうが速い。

### 設定を削除する

```bash
git config --global --unset 設定キー
```

例えば、`push.autoSetupRemote` を削除する場合:

```bash
git config --global --unset push.autoSetupRemote
```

---

## おすすめ初期設定まとめ

ここまでの設定から、非エンジニアが AI コーディングを始めるときに入れておくと便利なものを厳選した。第 2 章で設定済みの項目も含め、全体像を示す。

```bash
# === 第 2 章で設定済み ===
git config --global user.name "自分の名前"
git config --global user.email "自分のメールアドレス"
git config --global init.defaultBranch main

# === この章で追加するおすすめ設定 ===
# push でいちいち -u を書かなくて済む
git config --global push.autoSetupRemote true

# 消えたリモートブランチを自動掃除
git config --global fetch.prune true

# 差分表示がわかりやすくなる
git config --global diff.algorithm histogram
git config --global diff.colorMoved default

# コンフリクト時の情報量が増える
git config --global merge.conflictstyle diff3

# 見やすいログ表示のショートカット
git config --global alias.lg "log --oneline --graph --decorate"
```

上の「追加するおすすめ設定」を VS Code のターミナルにコピー & ペーストして、1 行ずつ Enter で実行すれば完了である。

:::message
設定を全部入れ終わったら `git config --list` で確認しよう。項目名と設定値がずらっと表示されるはずだ。
:::
