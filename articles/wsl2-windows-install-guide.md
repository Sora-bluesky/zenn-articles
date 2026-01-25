---
title: "非エンジニア向け WSL2 インストールガイド（Windows 10/11）"
emoji: "🐧"
type: "tech"
topics: ["wsl2", "windows", "claudecode", "linux", "初心者"]
published: false
---

## はじめに

この記事では、Windows に WSL2（Windows Subsystem for Linux 2）をインストールする手順を解説する。

WSL2 を入れると、Windows 上で Linux（Ubuntu）が使えるようになる。Claude Code や ClawdBot など、Linux 環境を前提としたツールを動かすために必要。

:::message
**シリーズ構成**
- **WSL2 インストールガイド**（この記事）
- [非エンジニアがWindowsでClaude Codeを使えるようになるまで](claude-code-windows-install-guide)
- [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips-and-features)
- [ClawdBotを導入してみた](clawdbot-setup-guide)
:::

---

## WSL2 とは

| 項目 | 内容 |
|------|------|
| 正式名称 | Windows Subsystem for Linux 2 |
| できること | Windows 上で Linux を動かす |
| 用途 | 開発ツール、コマンドで操作するツールの実行 |
| 料金 | 無料（Windows の機能） |

**イメージ**: Windows の中に「小さな Linux パソコン」が入っている状態。

---

## 事前確認

### Windows バージョンの確認

WSL2 を使うには、以下のバージョンが必要。

| OS | 必要バージョン |
|----|---------------|
| **Windows 11** | 全バージョン OK |
| **Windows 10** | バージョン 2004（Build 19041）以上 |

**確認方法:**

1. `Win + R` キーを押す
2. `winver` と入力して Enter
3. 表示されたウィンドウでバージョンを確認（「バージョン」と「OSビルド」が表示される）

:::message alert
**Windows 10 でバージョンが古い場合**
Windows Update を実行して最新版にアップデートする。
設定 → 更新とセキュリティ → Windows Update
:::

---

## インストール手順

### Step 1: PowerShell を管理者として起動

1. スタートメニューで「PowerShell」と検索
2. 「Windows PowerShell」を**右クリック**
3. 「管理者として実行」を選択
4. 「このアプリがデバイスに変更を加えることを許可しますか？」→「はい」

:::message
**なぜ管理者として実行するのか**
WSL2 のインストールは Windows のシステム設定を変更するため、管理者権限が必要。
:::

### Step 2: WSL2 のインストール

PowerShell に以下のコマンドを入力して Enter。

```powershell
wsl --install -d Ubuntu-24.04
```

**出力例:**

```
インストール中: 仮想マシン プラットフォーム
仮想マシン プラットフォーム はインストールされました。
インストール中: Linux 用 Windows サブシステム
Linux 用 Windows サブシステム はインストールされました。
インストール中: Ubuntu 24.04 LTS
Ubuntu 24.04 LTS はインストールされました。
要求された操作は正常に終了しました。変更を有効にするには、システムを再起動する必要があります。
```

:::message
**コマンドの意味**
- `wsl --install`: WSL をインストールする
- `-d Ubuntu-24.04`: Ubuntu 24.04 を指定してインストール
:::

### Step 3: PC を再起動

インストール完了後、PC を再起動する。

スタートメニュー → 電源 → 再起動。

### Step 4: Ubuntu の初期設定

再起動後、自動的に Ubuntu のウィンドウが開く（開かない場合はスタートメニューから「Ubuntu」を検索して起動）。

**ユーザー名とパスワードを設定:**

```
Installing, this may take a few minutes...
Please create a default UNIX user account.
Enter new UNIX username: あなたの名前（半角英字）
New password: パスワード（入力しても表示されない）
Retype new password: パスワード再入力
```

:::message alert
**パスワード入力時の注意**
パスワードを入力しても画面には何も表示されない。これは Linux の仕様で、セキュリティのため。見えなくても入力されているので、そのまま入力して Enter を押す。
:::

**成功すると以下のような画面になる:**

```
Welcome to Ubuntu 24.04 LTS (GNU/Linux 5.15.153.1-microsoft-standard-WSL2 x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

username@DESKTOP-XXXXX:~$
```

これで WSL2 のインストールは完了。

---

## 動作確認

### Ubuntu の起動方法

スタートメニューで「Ubuntu」と検索して起動する。

:::message
慣れてきたら PowerShell で `wsl` と入力するだけでも起動できる。
:::

### 基本コマンドの確認

Ubuntu ターミナルで以下を実行してみる。

```bash
# 現在のディレクトリを表示
pwd

# ファイル一覧を表示
ls

# Ubuntu のバージョンを確認
cat /etc/os-release
```

**出力例:**

```
/home/username
.  ..  .bashrc  .profile
PRETTY_NAME="Ubuntu 24.04 LTS"
...
```

---

## Windows と Ubuntu のファイル共有

### Windows から Ubuntu のファイルにアクセス

エクスプローラーのアドレスバーに以下をコピー＆ペースト:

```
\\wsl$\Ubuntu-24.04
```

または、Ubuntu ターミナルで `explorer.exe .` を実行。

### Ubuntu から Windows のファイルにアクセス

Ubuntu では、Windows の C ドライブは `/mnt/c/` として見える（「マウント」＝外部のドライブを Linux から見えるようにすること）。

```bash
# Windows のドキュメントフォルダに移動
cd /mnt/c/Users/あなたのユーザー名/Documents

# ファイル一覧を確認
ls
```

---

## よくあるエラーと解決策

### エラー 0x80370102

**症状:**
```
WslRegisterDistribution failed with error: 0x80370102
```

**原因:** 仮想化機能が無効になっている

**解決策:**

:::message alert
**BIOS 設定の変更は慎重に**
BIOS はパソコンの根本的な設定画面。仮想化設定以外の項目は触らないこと。分からない場合は詳しい人に相談することを推奨。
:::

1. PC を再起動し、BIOS/UEFI 設定画面に入る
   - 起動時に `F2`, `F10`, `Del` などを連打（メーカーにより異なる）
   - 「PC のメーカー名 + BIOS 入り方」で検索すると手順が見つかる
2. 仮想化設定を探して有効化
   - Intel: 「Intel VT-x」または「Intel Virtualization Technology」
   - AMD: 「AMD-V」または「SVM Mode」
3. 設定を保存して再起動

### エラー 0x80004005

**症状:**
```
WslRegisterDistribution failed with error: 0x80004005
```

**原因:** Windows Update が必要、または WSL コンポーネントが破損

**解決策:**

1. Windows Update を実行
   - 設定 → 更新とセキュリティ → Windows Update
2. それでも解決しない場合、WSL を再インストール
   ```powershell
   wsl --unregister Ubuntu-24.04
   wsl --install -d Ubuntu-24.04
   ```

### 「Ubuntu」が見つからない

**症状:** スタートメニューに Ubuntu が表示されない

**解決策:**

1. Microsoft Store を開く
2. 「Ubuntu 24.04」を検索
3. 「入手」をクリックしてインストール

### ネットワークに接続できない

**症状:** Ubuntu 内から `apt update` や `curl` が失敗する

**解決策:**

この問題は DNS（ネットワークの名前解決）設定に起因することが多い。解決方法は複雑なため、以下を参照：

- [WSL のネットワーク トラブルシューティング - Microsoft Learn](https://learn.microsoft.com/ja-jp/windows/wsl/troubleshooting#networking-considerations-with-dns-tunneling)

自力で解決が難しい場合は、詳しい人に相談することを推奨。

---

## 次のステップ

WSL2 のインストールが完了したら、以下の記事に進む。

| やりたいこと | 次に読む記事 |
|-------------|-------------|
| Claude Code を使いたい | [非エンジニアがWindowsでClaude Codeを使えるようになるまで](claude-code-windows-install-guide) |
| ClawdBot を使いたい | [ClawdBotを導入してみた](clawdbot-setup-guide) |
| トラブルが発生した | [Claude Codeが動かない時に見るページ](claude-code-windows-troubleshoot) |

---

## まとめ

| ステップ | 内容 |
|---------|------|
| 1 | PowerShell を管理者として起動 |
| 2 | `wsl --install -d Ubuntu-24.04` を実行 |
| 3 | PC を再起動 |
| 4 | Ubuntu でユーザー名・パスワードを設定 |

WSL2 があれば、Windows 上で Linux 向けのツールが使えるようになる。Claude Code、ClawdBot、その他多くの開発ツールの基盤として活用できる。

---

## 参考リンク

- [WSL のインストール - Microsoft Learn](https://learn.microsoft.com/ja-jp/windows/wsl/install)
- [WSL のトラブルシューティング - Microsoft Learn](https://learn.microsoft.com/ja-jp/windows/wsl/troubleshooting)
- [Ubuntu on WSL - Ubuntu 公式](https://ubuntu.com/desktop/wsl)
