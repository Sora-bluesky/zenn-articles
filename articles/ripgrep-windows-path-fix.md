---
title: "ripgrepがWindowsで動かないときの原因と恒久対策"
emoji: "🔍"
type: "tech"
topics: ["windows", "powershell", "cli", "ai"]
published: false
---

## TL;DR

- WindowsApps フォルダにある `rg.exe` が PATH で優先され、アクセス拒否で動かない
- `winget install BurntSushi.ripgrep.MSVC` で正規の ripgrep を入れれば解決する
- Codex CLI で発生した問題だが、Windows の `rg` を使うツール全般に適用できる

## AI コーディングツールで「rg が起動できない」と表示されたことはないだろうか

**ripgrep（コマンド名: `rg`）** は高速なファイル検索ツールで、多くの AI コーディングツールやエディタが内部的に利用している。Codex CLI、VS Code、その他のターミナルツールがプロジェクト内のコードを横断検索するとき、裏側で `rg` が走っていることが多い。

`rg` が動かないとどうなるか。ツール側は PowerShell の `Select-String` など遅い代替手段にフォールバックする。動きはするが、体感で分かるほど遅い。数千ファイルのプロジェクトだと、数秒で終わるはずの検索が十数秒かかる。

この記事では、Windows で `rg` が動かない原因の特定から恒久対策までを扱う。

:::message
**この問題が発生するツールと発生しないツール**
- **Codex CLI**: システムの PATH 上の `rg` を使う → **発生しうる**
- **VS Code**: 拡張機能によってはシステムの `rg` を参照する → **発生しうる**
- **Claude Code**: ripgrep をバンドルしている（`vendor/ripgrep/`）ため、 **通常は発生しない**。ただしバンドル版の権限問題は報告されている（[Issue #42068](https://github.com/anthropics/claude-code/issues/42068)）
:::

:::message
**公式ドキュメント**
- [English: ripgrep README](https://github.com/BurntSushi/ripgrep)
:::

## こんなエラーが出たら

PowerShell やClaude Code のログに、以下のようなメッセージが出る。

```text
rg がこの環境で起動できないので、PowerShell 側で検索に切り替えます。
```

または PowerShell で直接 `rg` を叩くと、

```text
アクセスが拒否されました。
```

`rg` が入っていないのではなく、 **「見えているのに実行できない」** 状態。ここが厄介なところだ。

## 原因: WindowsApps の PATH 競合

### PATH とは

PATH は、Windows がコマンドを探すフォルダの順番リスト。`rg` と入力すると、PATH に登録されたフォルダを先頭から順に見ていき、最初に見つかった `rg.exe` を実行する。

### WindowsApps とは

`C:\Program Files\WindowsApps` は、Microsoft Store からインストールしたアプリが格納されるフォルダで、ここにあるファイルにはアクセス制限がかかっている。

### 何が起きているか

一部の Microsoft Store アプリが、内部に `rg.exe` を同梱している。PATH の中で優先度の高い位置にあるため、自分でインストールした ripgrep より先に見つかってしまう。

しかし WindowsApps 配下のファイルにはアクセス制限がある。結果、こうなる。

![WindowsApps PATH 競合の仕組み](/images/rg-path-conflict.png)

1. Windows が `rg` コマンドを受け取る
2. PATH を先頭から探す
3. WindowsApps 配下の `rg.exe` を最初に見つける
4. 実行しようとするが、アクセス制限で弾かれる
5. エラー

自分でインストールした正規の `rg.exe` は PATH のもっと後ろにいるので、出番が回ってこない。「入っているはずなのに動かない」の正体がこれだ。

## 診断: 3つのコマンドで状態を確認

PowerShell を開いて、以下の 3 つを実行する。

### 1. どの `rg.exe` が使われているか

```powershell
Get-Command rg
```

| 状態 | 出力例 |
|------|--------|
| 正常 | `C:\Users\[USERNAME]\.cargo\bin\rg.exe` や `C:\Program Files\ripgrep\rg.exe` |
| 異常 | `C:\Program Files\WindowsApps\...\rg.exe` |

WindowsApps 配下のパスが返ってきたら、これが原因だ。

### 2. `rg.exe` が複数存在するか

```powershell
where.exe rg
```

| 状態 | 出力例 |
|------|--------|
| 正常 | 1行だけ、または自分でインストールしたパスが先頭 |
| 異常 | 複数行表示され、WindowsApps のパスが先頭にいる |

先頭に表示されるパスが、Windows が優先する `rg.exe` だ。

### 3. 実行できるか

```powershell
rg --version
```

| 状態 | 出力例 |
|------|--------|
| 正常 | `ripgrep 14.1.1` のようなバージョン表示（バージョンは時期により異なる） |
| 異常 | 「アクセスが拒否されました」またはエラー |

3 つとも正常なら問題ない。1 つでも異常があれば、次の恒久対策に進む。

:::message
**公式ドキュメント**
- [English: ripgrep Installation](https://github.com/BurntSushi/ripgrep#installation)
:::

## 恒久対策: winget で ripgrep を導入

![診断から解決までの流れ](/images/rg-fix-flow.png)

Windows 標準のパッケージマネージャー winget で、正規の ripgrep をインストールする。

```powershell
winget install BurntSushi.ripgrep.MSVC
```

winget は Windows 10（1709 以降）と Windows 11 に標準搭載されている。追加のツールは不要。

インストールが完了したら、 **PowerShell を一度閉じて開き直す** 。PATH の変更はターミナルの再起動で反映される。

:::message
**他のインストール方法**
Scoop や Chocolatey を普段使っている場合は `scoop install ripgrep` や `choco install ripgrep` でも導入できる。Rust 環境がある場合は `cargo install ripgrep --locked` も選択肢になる。どの方法でも、次の確認手順で正しく動いていれば問題ない。
:::

## 導入後の確認

PowerShell を再起動してから、診断と同じ 3 つのコマンドを実行する。

```powershell
Get-Command rg
where.exe rg
rg --version
```

以下の状態になっていれば成功。

| コマンド | 期待する結果 |
|---------|-------------|
| `Get-Command rg` | `C:\Program Files\ripgrep\rg.exe` のような WindowsApps **以外** のパス |
| `where.exe rg` | 先頭に上記と同じパス |
| `rg --version` | `ripgrep 14.1.1` のようなバージョン表示（バージョンは時期により異なる） |

AI コーディングツール（Codex CLI 等）を使っている場合は、そちらも再起動する。新しい `rg` が認識され、検索速度が元に戻るはずだ。

:::message
ripgrep はデフォルトで `.gitignore` のルールに従って検索対象を絞り込む。Git リポジトリ内で使うと、無視対象のファイル（`node_modules` など）が自動的に除外される。
:::

## （補足）PATH 順序の調整が必要な場合

winget でインストールしても `Get-Command rg` が WindowsApps のパスを返す場合、PATH の順序を手動で調整する必要がある。

まず、現在の PATH を確認する。

```powershell
$env:Path -split ';'
```

出力されるフォルダ一覧のうち、上にあるものほど優先度が高い。WindowsApps を含む行が、ripgrep のインストール先より上にある場合、順序を入れ替える。

手順:

1. Windows キーを押して「環境変数」と検索し、「環境変数を編集」を開く
2. 「ユーザー環境変数」の `Path` を選択して「編集」を押す
3. ripgrep がインストールされたフォルダ（`C:\Program Files\ripgrep` など）を、WindowsApps より上に移動する
4. OK を押してダイアログを閉じる
5. PowerShell を再起動して `Get-Command rg` で確認する

:::message alert
**システム環境変数の Path は慎重に**
「ユーザー環境変数」の Path を編集するのは安全だが、「システム環境変数」の Path は Windows 全体に影響する。システム側は変更しなくても、ユーザー環境変数の調整で解決することが多い。
:::

:::message
**公式ドキュメント**
- [English: Windows Environment Variables](https://learn.microsoft.com/en-us/windows/win32/shell/user-environment-variables)
- ブラウザの翻訳機能で日本語に変換して読める
:::

## 確認コマンドチートシート

```powershell
# どの rg が使われているか
Get-Command rg

# rg が複数あるか（全候補を表示）
where.exe rg

# rg が実行できるか
rg --version

# PATH の一覧を確認
$env:Path -split ';'

# ripgrep のインストール
winget install BurntSushi.ripgrep.MSVC
```

:::message
**PowerShell の豆知識**: `Select-String` は ripgrep が使えないときの代替手段になる。`Get-ChildItem -Recurse | Select-String "検索したい文字列"` で再帰検索ができるが、速度は ripgrep に遠く及ばない。
:::

## 参考リンク

:::message
**公式ドキュメントまとめ**
- [ripgrep GitHub リポジトリ](https://github.com/BurntSushi/ripgrep) -- インストール方法、使い方、FAQ
- [ripgrep Installation Guide](https://github.com/BurntSushi/ripgrep#installation) -- 各 OS のインストール手順
- [Windows 環境変数の管理（Microsoft Learn）](https://learn.microsoft.com/en-us/windows/win32/shell/user-environment-variables) -- ブラウザの翻訳機能で日本語に変換して読める
- [winget 公式ドキュメント（Microsoft Learn）](https://learn.microsoft.com/en-us/windows/package-manager/winget/) -- ブラウザの翻訳機能で日本語に変換して読める
- [Claude Code ripgrep 関連 Issue #42068](https://github.com/anthropics/claude-code/issues/42068) -- バンドル版 ripgrep の権限問題
:::
