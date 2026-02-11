---
title: "Obsidian CLI セットアップ完全ガイド ── Windows環境でハマった全記録"
emoji: "⌨️"
type: "tech"
topics: ["obsidian", "cli", "windows", "claudecode", "個人開発"]
published: true
---

## この記事で分かること

- **2026年2月10日リリースのObsidian公式CLI**（v1.12.0 Early Access）のセットアップ手順
- **Windows環境で実際にハマった5つの罠** と、その回避方法
- CLIで何ができるのか ── 100以上のコマンドの概要

:::message
**シリーズ構成**
- [ObsidianをAIの「司令塔」にする ── MCP連携で39ソース自動収集の全貌](obsidian-mcp-integration) ── MCP接続の手順と自動ニュース収集の実例
- **Obsidian CLI セットアップ完全ガイド ── Windows環境でハマった全記録**（この記事）

**関連記事**
- [Claude Code × Obsidian 連携ガイド：iPhoneのメモをAIが読み取れるようにする](claude-code-obsidian-icloud-guide) ── iCloud経由のVault同期手順
:::

:::message alert
**検証環境**: Windows 11 / Obsidian v1.12.1 / PowerShell 7
**検証日**: 2026年2月11日
本記事の情報は検証日時点のものです。最新情報は[Obsidian公式サイト](https://obsidian.md)を確認してください。
:::

## はじめに

> **Anything you can do in Obsidian you can do from the command line.**
> Obsidian CLI is now available in 1.12 (early access).
> ── [Obsidian公式 (@obsdmd)](https://x.com/obsdmd/status/2021241384057930224) 2026年2月11日

「Obsidianでできることは、すべてコマンドラインからもできる」── 2026年2月11日、Obsidian公式がCLIのリリースを発表した。

ObsidianにはMCPプラグイン（前編で紹介）を使えばAIツールからノートを読み書きできる。しかし、**テンプレート適用、プラグイン管理、JavaScript実行**といったObsidian内部の機能にはアクセスできなかった。

2026年2月10日、Obsidianが**公式CLI（コマンドラインインターフェース ── キーボードだけでアプリを操作する方法）** をリリースした。バージョン1.12.0のEarly Access（正式リリース前の先行公開）機能として提供されている。

本記事では、Windows環境でCLIをセットアップする手順を、**実際にハマったポイントも含めて**すべて記録する。

:::message
**料金について**
- Obsidian本体: **無料**
- Catalyst License: **$25（約3,750円）の一回払い**（CLIのEarly Accessに必要）
- 将来的にCLIは全ユーザーに無料開放される予定
:::

## CLIでできること

Obsidian CLIは100以上のコマンドを提供する。主要なカテゴリを紹介する：

| カテゴリ | 代表コマンド | できること |
|---------|-------------|-----------|
| **ファイル操作** | `files list`, `files read`, `files write` | ノートの一覧・読み書き |
| **検索** | `search content`, `search path` | 全文検索、パス検索 |
| **タスク管理** | `tasks all`, `tasks pending` | チェックボックスの一括操作 |
| **テンプレート** | `templates list`, `templates apply` | テンプレートの適用 |
| **プラグイン** | `plugins list`, `plugins versions` | プラグイン管理 |
| **プロパティ** | `properties read`, `properties set` | フロントマター（ノート冒頭のメタ情報）操作 |
| **開発者** | `dev:eval` | **JavaScript実行** |
| **Vault情報** | `vault`, `files total`, `tags all` | Vault統計情報 |

## セットアップ手順

### 前提条件

| 項目 | 必要なもの | 費用 |
|------|-----------|------|
| Obsidianバージョン | **1.12.0以上**（Early Access版） | 無料 |
| Catalyst License | **Insider tier** | $25 / 約3,750円（一回限り） |
| OS | Windows / macOS / Linux | ─ |

:::message alert
2026年2月時点ではEarly Access機能のため、通常の安定版では使えない。Catalyst License（$25 / 約3,750円の一回払い）が必要である。将来的に全ユーザーに無料開放される予定。
:::

### Step 1: Catalyst Licenseの購入

1. [obsidian.md](https://obsidian.md) にログイン
2. **Account** ページ → **Catalyst** セクション
3. 「Join Catalyst」をクリック

![Catalystページ（Join Catalystボタン）](/images/obsidian-cli-setup/02-catalyst-join.png)

4. **Insider** tier（$25 / 約3,750円、一回限り）を選択

![Catalyst tier選択](/images/obsidian-cli-setup/03-catalyst-tier-select.png)

5. 支払い完了

![購入成功](/images/obsidian-cli-setup/04-catalyst-purchase-success.png)

:::message
Catalyst Licenseは**Obsidian開発チームへの支援**の意味合いが強い。Early Accessの機能は将来的に全ユーザーに無料開放される予定である。
:::

### Step 2: Insider Builds の有効化

1. Obsidianアプリを起動
2. 設定 → 一般 → アカウントでログイン

![設定画面（ログイン前）](/images/obsidian-cli-setup/01-settings-before-login.png)

3. ログイン後、**カタリストライセンス**が認識されていることを確認

![Catalyst認識済み](/images/obsidian-cli-setup/05-catalyst-recognized.png)

4. 「インサイダービルドを取得」をオン

![Insider builds ON](/images/obsidian-cli-setup/06-insider-toggle-on.png)

5. 「更新を確認」をクリック → アップデート後、アプリを再起動

![v1.12.1にアップデート](/images/obsidian-cli-setup/07-updated-v1.12.1.png)

:::message
アカウントタブが表示されない場合、アプリの**完全な再起動**が必要なことがある。タスクバーのObsidianアイコンも右クリック→終了してから起動し直す。
:::

### Step 3: CLIの有効化

1. 設定 → コマンドラインインターフェース
2. 初回は「CLIを登録」ダイアログが表示される

![CLI登録ダイアログ](/images/obsidian-cli-setup/08-cli-registration-dialog.png)

3. CLI をオンにする

![CLI有効化](/images/obsidian-cli-setup/09-cli-toggle-on.png)

### Step 4: Windows固有の設定（ここからが本番）

ここからがWindows環境特有のトラブルゾーンである。macOS/Linuxユーザーは読み飛ばして問題ない。

#### 4a. Obsidian.com ファイルの取得

Windows環境では、CLIの実行に `Obsidian.com` というターミナルリダイレクタファイルが必要だ。これは**Obsidian公式Discordサーバー**のInsider専用チャンネルで配布されている。

:::message
**Obsidian公式Discord** は、Obsidian開発チームが運営するコミュニティ。バグ報告、機能リクエスト、ユーザー同士の情報交換の場として公式に推奨されている。
:::

1. [obsidian.md/account](https://obsidian.md/account) → Catalyst → 「**Get Discord badge**」をクリック

![Discord badge取得](/images/obsidian-cli-setup/10-get-discord-badge.png)

2. [Obsidian公式Discord](https://discord.gg/obsidianmd) の `#insider-desktop-release` チャンネルへ移動
3. `Obsidian.com` ファイルをダウンロード

![Discord Obsidian.com](/images/obsidian-cli-setup/11-discord-obsidian-com.png)

4. ダウンロードした `Obsidian.com` を以下のディレクトリに配置：

```
C:\Users\[ユーザー名]\AppData\Local\Programs\Obsidian\
```

`Obsidian.exe` と同じフォルダに置く。

:::message alert
**重要**: 「Get Discord badge」を**先にクリック**しないと、Discordサーバーに参加しても `#insider-desktop-release` チャンネルが表示されない。この手順を飛ばすと「チャンネルが見つからない」で詰む。
:::

#### 4b. 管理者権限の罠（最大のハマりポイント）

`Obsidian.com` を正しく配置しても、以下のように出力が空になることがある：

```powershell
PS C:\Users\[ユーザー名]> obsidian help
Loading updated app package...
# ← 何も表示されない
```

**原因**: ターミナルが**管理者権限**で起動している。

Obsidian CLIは**通常のユーザー権限**で動作する必要がある。管理者権限のターミナルでは、Obsidianアプリとの通信（IPC ── プロセス間通信）が正しく行われない。

**解決方法**:

```
Win + R → 「powershell」と入力 → Enter
```

これで通常ユーザー権限のPowerShellが起動する。

:::message
**恒久対策**: Windows Terminal をデフォルトで管理者権限にしている場合は、設定 → プロファイル → 「このプロファイルを管理者として実行する」→ **オフ** にする。

あるいは、Obsidian CLI用に通常権限のプロファイルを別途作成する方法もある。
:::

### Step 5: 動作確認

通常権限のターミナルで以下を実行：

```powershell
PS> obsidian help
```

以下のような出力が表示されれば成功だ：

```
USAGE: obsidian [options] [command]

Obsidian CLI

OPTIONS:
  -v, --version      Print version info and exit
  -h, --help         Display help for command

COMMANDS:
  bookmarks          Commands related to bookmarks
  daily              Commands related to daily notes
  dev                Commands related to development
  files              Commands related to files in the vault
  links              Commands related to links
  plugins            Commands related to plugins
  properties         Commands related to properties
  search             Commands related to search
  sync               Commands related to Obsidian Sync
  tags               Commands related to tags
  tasks              Commands related to tasks
  templates          Commands related to templates
  themes             Commands related to themes
  vault              Display vault information
  version            Display version information
```

基本コマンドの確認：

```powershell
# バージョン確認
PS> obsidian version
Obsidian v1.12.1 (installer v1.11.7)

# Vault情報
PS> obsidian vault
MainVault
C:\Users\[ユーザー名]\iCloudDrive\iCloud~md~obsidian\MainVault
48 files, 13 folders

# ファイル数
PS> obsidian files total
48

# プラグイン一覧
PS> obsidian plugins versions
mcp-tools    0.2.27
obsidian-local-rest-api    3.4.2
```

## TUIモード

CLI にはTUI（Terminal User Interface ── ターミナル上で動くGUI風の操作画面）モードも搭載されている。引数なしで実行すると起動する：

```powershell
PS> obsidian
```

| キー | 操作 |
|------|------|
| `↑↓` | ファイル選択 |
| `Enter` | ファイルを開く |
| `/` | 検索 |
| `n` | 新規ファイル作成 |
| `d` | ファイル削除 |
| `r` | ファイル名変更 |
| `q` | 終了 |

GUIを使わずにターミナルだけでVaultを操作できる。SSH接続先でObsidianを操作したい場合にも有用だ。

## Windows トラブルシューティング一覧

今回のセットアップで実際に遭遇した問題と解決策をまとめる。

| # | 問題 | 原因 | 解決策 |
|---|------|------|--------|
| 1 | CLIコマンドが何も返さない | ターミナルが管理者権限 | `Win+R → powershell` で通常権限起動 |
| 2 | `#insider-desktop-release` が見えない | Discord badgeが未取得 | Account → Catalyst → Get Discord badge |
| 3 | アカウントタブが表示されない | アプリ再起動が必要 | Obsidianを完全終了 → 再起動 |
| 4 | `Obsidian.com` が見つからない | Discord insider チャンネル未参加 | 上記Discord badge手順を実行 |
| 5 | Insider builds トグルが見えない | バージョンが古い/未ログイン | ログイン → 設定確認 |

:::message
**最大のハマりポイント**は間違いなく**管理者権限の罠**（#1）である。エラーメッセージが一切出ず、ただ「何も表示されない」だけなので、原因の特定に時間がかかる。Discord上でも同じ問題を報告しているユーザーが複数いた。
:::

## まとめ

2026年2月10日にリリースされたObsidian CLI（v1.12.0 Early Access）をWindows環境でセットアップした。

**やってみた所感：**

- **セットアップはやや面倒**。特にWindowsは `Obsidian.com` の取得とDiscord badge手順が分かりにくい
- **管理者権限の罠**はエラーが出ないため原因特定が難しい。最大のハマりポイント
- **動いてしまえばシンプル**。`obsidian help` で全コマンドが一覧できる
- **100以上のコマンド**でテンプレート適用、タスク管理、プラグイン管理、JavaScript実行など、GUIでしかできなかった操作がターミナルから可能に

現在はEarly Access（Catalyst License $25 / 約3,750円の一回払い）だが、将来的に全ユーザーに無料開放される予定。MCP連携との組み合わせについては、別記事で検証予定。

---

## 参考

- [Obsidian 公式サイト](https://obsidian.md/)
- [Obsidian 公式Discord](https://discord.gg/obsidianmd)
- [Obsidian Catalyst ページ](https://obsidian.md/pricing)
- [前編: ObsidianをAIの「司令塔」にする ── MCP連携で39ソース自動収集の全貌](obsidian-mcp-integration)

※公式ドキュメントは英語です。ブラウザの翻訳機能で日本語に変換して読めます。

---

## 関連記事

- [ObsidianをAIの「司令塔」にする ── MCP連携で39ソース自動収集の全貌](obsidian-mcp-integration) ── MCP接続の手順と自動ニュース収集の実例
- [Claude Code × Obsidian 連携ガイド：iPhoneのメモをAIが読み取れるようにする](claude-code-obsidian-icloud-guide) ── iCloud経由のVault同期手順
