---
title: "Claude Code × Obsidian 連携ガイド：iPhoneのメモをAIが読み取れるようにする"
emoji: "🔗"
type: "tech"
topics: ["claudecode", "obsidian", "ai", "windows", "個人開発"]
published: true
---

## 経緯

この記事の手順を終えると、iPhoneのObsidianに書いたメモを、Windows上のClaude Codeが読み取れるようになります。「Obsidianのメモを見て」と頼むだけで、コピペなしでメモの検索や整理ができる状態です。

iCloudで同期するため、移動中にiPhoneでメモを書き、帰宅後にClaude Codeで整理する使い方ができます。

この記事で扱うのは、iPhone + Windows + 無料の構成だけです。Macの場合の連携方法と、Obsidian公式の有料Syncの設定手順は扱いません。有料Syncは代替手段として名前だけ挙げます。

---

## この記事を何度も書き直した理由

この記事は3回書き直しました。

最初は「Windows側でiCloud Driveにフォルダを作って、ObsidianでVaultを開き、後からiPhoneで同期する」という順番で進めました。ところが、iPhoneでObsidianを開くと次のエラーが出ました。

> **your iCloud vault was not detected**

Windowsで作ったフォルダがiPhoneから見えない状態です。公式ドキュメントとフォーラムを調べた結果、原因が分かりました。

### 判明した根本原因

**iOS版Obsidianが認識するフォルダと、Windowsで手動作成したフォルダは別のものでした。**

| フォルダ | 作成元 | iOS認識 |
|---------|--------|---------|
| `iCloud~md~obsidian` | iOSアプリが自動作成 | ✅ |
| `Obsidian`（手動作成） | Windows | ❌ |

iPhoneでVaultを作成すると、iCloud Drive内に `iCloud~md~obsidian` というフォルダが自動で作られます。これはiOSアプリ専用のコンテナフォルダで、Windowsで手動作成した「Obsidian」フォルダとは**別の場所**です。

このため、**iPhoneでVaultを先に作成しないと、iCloud同期はうまくいきません**。

### 公式フォーラムの警告

Obsidian公式フォーラムには次の記述があります：

> "Using iCloud on Windows is known to lead to file duplication and corruption issues."
> （WindowsでのiCloud使用は、ファイルの重複と破損の問題が知られている）

**Windows + iCloudの組み合わせは公式に非推奨**です。

### この記事の手順

それでも「iPhone + Windows + 無料」の条件を満たしたかったため、試行錯誤して動く手順を見つけました。この記事はその結果をまとめたものです。手順の順番には意味があります。「なぜこの順番なのか」を理解した上で進めてください。

:::message
**シリーズ構成**
- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ：使いこなすためのTips](claude-code-tips-and-features)
- [Claude Code が動かない時に見るページ（Windows）](claude-code-windows-troubleshoot)
- [Claude Code でAIにコードを書かせてAIにレビューさせる](claude-code-ai-review-workflow)
- [Claude Code への引っ越しガイド：Web版の知識を移行する](claude-code-migration-guide)
- [Claude Cowork Windows版ガイド：ターミナルなしでAIエージェントを使う](claude-cowork-windows-guide)
- **Claude Code × Obsidian 連携ガイド**（この記事）
:::

---

## この記事で実現すること

```
+----------------+     +----------------+     +----------------+
|  Claude Code   | ←→  |  iCloud Drive  | ←→  |    iPhone     |
|   (Windows)    |     |   (Obsidian    |     |  (Obsidian)   |
|                |     |    Vault)      |     |               |
+----------------+     +----------------+     +----------------+
         ↓                                           ↓
   AIでメモを分析・検索             移動中にメモを確認・追記
```

**できるようになること**:

- Claude Code に「Obsidian のメモを検索して」と指示できる
- iPhoneで書いたメモを、Claude Codeが分析できる
- 「先週の会議内容をまとめて」と頼んで、Obsidian内のメモから要約を作れる

---

## なぜObsidianなのか：他アプリとの比較

:::message
**結論：Windows + iPhone + 無料 ならObsidian一択**
:::

| 項目 | Obsidian | Notion | Craft |
|------|----------|--------|-------|
| モバイル操作性 | ○ 良い | △ やや重い | ◎ 最高 |
| オフライン対応 | ◎ 完全 | × 限定的 | ◎ 完全 |
| MCP対応（AI連携） | ◎ 対応済み | △ 一部 | ◎ 対応済み |
| Windows対応 | ◎ あり | ◎ あり | × なし |
| 価格 | ◎ 無料 | ○ 無料枠あり | ○ 無料枠あり |
| データ所有権 | ◎ ローカル保存 | △ クラウド | △ クラウド |

- **Craft** はモバイル最強だが Windows 非対応
- **Notion** はデータベース機能が強いがオフラインに弱い
- **Obsidian** は Windows + iPhone で無料かつローカル保存

---

## 用語説明

| 用語 | 説明 |
|------|------|
| **MCP** | Model Context Protocol の略。Claude が外部ツール（Obsidianなど）と連携するための仕組み |
| **API Key** | ソフトウェア同士が通信するときに使う認証用の文字列。この記事ではLocal REST APIプラグインが発行するもの |
| **Vault** | Obsidianでメモを保存するフォルダのこと。「金庫」の意味 |
| **プラグイン** | ソフトウェアに機能を追加する拡張パーツ |
| **iCloud Drive** | Apple のクラウドストレージ。iPhone と Windows で自動同期できる |
| **JSON** | 設定ファイルによく使われる形式。`{ "key": "value" }` のような書き方 |
| **cmd** | Windowsのコマンドプロンプト。プログラムを実行するための黒い画面 |

---

## 事前準備

以下が必要です：

- [ ] Claude Code がインストール済み（[未導入の方はこちら](claude-code-windows-install-guide)）
- [ ] iPhone（iCloud同期に必要）
- [ ] Apple ID（iPhoneを使っていればすでに持っているはず）

:::message
**料金について**
- **Obsidian**: 基本無料。今回使うiCloud同期も無料（iCloud無料枠5GB内で十分）
- **Claude Code**: Anthropicの料金プランが必要（詳細は[インストールガイド](claude-code-windows-install-guide)参照）
- **Obsidian公式のSync機能**（月額課金）は不要。iCloud経由で無料同期できます
:::

:::message alert
**重要：Windows + iCloud同期の注意事項**

Obsidian公式フォーラムでは、Windows + iCloudの組み合わせは**ファイル破損・重複のリスク**があるとして非推奨とされています。

> "Using iCloud on Windows is known to lead to file duplication and corruption issues."

出典: [Official Guidelines for Use of Obsidian use in iCloud](https://forum.obsidian.md/t/official-guidelines-for-use-of-obsidian-use-in-icloud/83058)

それでもiCloud同期を使う場合は、以下の手順に従ってください。**手順の順番が重要**です。
:::

---

## 手順1：iPhoneでVaultを作成する

:::message alert
**なぜiPhoneが先なのか？**

iOS版ObsidianとWindows版Obsidianでは、認識するiCloudフォルダが異なります。

| フォルダ | 作成元 | iOS認識 |
|---------|--------|---------|
| `iCloud~md~obsidian` | iOSアプリが自動作成 | ✅ 認識する |
| 手動作成の「Obsidian」フォルダ | Windows | ❌ 認識しない |

**Windowsで先にフォルダを作成すると、iPhoneで「your iCloud vault was not detected」エラーが発生します。**
必ずiPhoneでVaultを先に作成してください。
:::

### 1-1. iPhoneにObsidianをインストール

App Storeから「[Obsidian](https://apps.apple.com/app/obsidian-connected-notes/id1557175442)」をインストールします（無料）。

### 1-2. iPhoneでVaultを作成する

1. Obsidianを起動
2. 「**Create new vault**」をタップ

すると、同期設定の画面が表示されます：

> To access your notes on other devices you need to set up sync. Because Obsidian stores your notes on your devices, you'll need to set up sync if you want to access your notes on another phone or computer.

3. 「**Setup Sync**」をタップ（「Continue without sync」は選ばない）

次に「Choose how to sync your notes」画面が表示されます：

| 選択肢 | 説明 | 選択 |
|--------|------|------|
| Obsidian Sync | 公式の有料サービス（$4/月） | × |
| **iCloud** | iOS/macOS向け。無料 | ✅ これを選択 |

4. 「**iCloud**」を選択（紫の枠で囲まれた状態にする）
5. 「**Use iCloud**」ボタンをタップ

:::message
**「Only for iOS and macOS」と表示されますが…**
iCloud for Windowsをインストールしていれば、Windowsでも同期できます。この表示は「Obsidian公式のサポート対象はiOS/macOSのみ」という意味です。
:::

次に「Configure your new vault.」画面が表示されます：

6. 「Vault name」にVault名を入力（例: `MainVault`）
7. 「**Create a vault**」ボタンをタップ

:::message alert
**「Skip」は選ばない**
同期方法選択画面で「Skip」を選ぶと、iPhone内にのみ保存され、Windows側から見えません。
:::

これでiPhoneでのVault作成が完了しました。

---

## 手順2：Windows側のセットアップ

### 2-0. iCloud同期のセキュリティについて（重要）

:::message alert
**データの保存場所とプライバシー**

この手順で同期されたメモは以下の場所に保存されます：

| 場所 | 保存先 |
|------|--------|
| iPhone内 | ローカルストレージ |
| Windows内 | ローカルストレージ |
| iCloud Drive | **Appleのサーバー**（米国ほか） |

**セキュリティ特性：**
- iCloud Driveは転送時・保存時に暗号化されます
- ただし**エンドツーエンド暗号化ではありません**（Appleは技術的に内容を復号できる）
- Apple IDのパスワードが漏洩すると、第三者がメモにアクセスできる可能性があります

**企業情報・機密情報を扱う場合：**
- 所属組織のセキュリティポリシーを確認してください
- 業務上の機密情報をiCloud同期するのは避けることを推奨します
- 代替手段: Obsidian Sync（エンドツーエンド暗号化対応、$4/月）
:::

### 2-1. iCloud for Windowsのインストール

1. Microsoft Storeから「[iCloud](https://www.microsoft.com/store/productId/9PKTQ5699M62)」をインストール
2. iCloudアプリを起動し、**iPhoneと同じApple ID**でサインイン
3. 「iCloud Drive」にチェックを入れて「適用」をクリック
4. エクスプローラーの左側に「iCloud Drive」が表示されればOK

:::message
**二段階認証（2FA）が有効な場合**
サインイン時にiPhoneに確認コードが送信されます。画面の指示に従って入力してください。サインインできない場合は、[Apple公式サポート](https://support.apple.com/ja-jp/HT204915)を参照してください。
:::

:::message
**iCloud Driveが表示されない場合**
PCを再起動してみてください。それでも表示されない場合は、iCloudアプリの設定画面で「iCloud Drive」にチェックが入っているか確認してください。
:::

### 2-2. 同期を待つ

iPhoneでVaultを作成すると、iCloud経由でWindowsに同期されます。

1. **5〜10分待つ**（同期に時間がかかることがあります）
2. エクスプローラーで iCloud Drive を開く
3. 「**iCloud~md~obsidian**」フォルダが表示されるか確認

:::message
**フォルダ名の違いに注意**
iPhoneでVaultを作成すると、Windows側では以下のパスに保存されます：
```
C:\Users\[ユーザー名]\iCloudDrive\iCloud~md~obsidian\[Vault名]
```
フォルダ名は「Obsidian」ではなく「`iCloud~md~obsidian`」になります。Windowsで手動作成したフォルダと取り違えないでください。
:::

**確認コマンド（PowerShell）：**
```powershell
Get-ChildItem -Path "$env:USERPROFILE\iCloudDrive\iCloud~md~obsidian" -Recurse -Depth 1
```

:::message
**同期されない場合**
- iCloud for Windowsを再起動（タスクトレイのiCloudアイコン右クリック → 終了 → 再起動）
- `iCloud~md~obsidian` フォルダを右クリック →「Always keep on this device」を選択
- PCを再起動
:::

### 2-3. WindowsにObsidianをインストール

[Obsidian公式サイト](https://obsidian.md/)からWindows版をダウンロードしてインストールします。

### 2-4. WindowsのObsidianでVaultを開く

1. Obsidianを起動
2. 「**Open folder as vault**」をクリック
3. `iCloud Drive/iCloud~md~obsidian/[Vault名]` フォルダを選択
4. 「フォルダーの選択」をクリック

**例：**
```
C:\Users\[ユーザー名]\iCloudDrive\iCloud~md~obsidian\MainVault
```

### 2-5. 同期確認

**確認ポイント：**

- iPhoneで新規メモを作成 → Windows側で表示されるか
- Windows側で新規メモを作成 → iPhoneで表示されるか

両方向で同期できていればOKです。反映まで数秒〜数分かかる場合があります。

:::message
**iPhoneに反映されない場合**

iCloud同期は**リアルタイムではありません**。Windows側でメモを作成・編集しても、iPhoneのObsidianにすぐ反映されないことがあります。

**対処法：**
1. iPhoneでObsidianアプリを**完全に閉じる**（タスクキル）
2. Obsidianを**再起動**する
3. Vault一覧画面で**下にスワイプ**（プルリフレッシュ）

これで同期が取得されます。

**それでも同期されない場合：**
- iPhoneの設定 → Apple ID → iCloud → 「Obsidian」がオンになっているか確認
- Wi-Fi接続を確認（モバイルデータでは同期しない設定の場合あり）
- 5〜10分待ってから再試行
:::

---

## 手順3：Obsidianにプラグインをインストールする

### 3-0. Obsidianを日本語化する（任意）

Obsidianのデフォルトは英語です。日本語で操作したい場合は先に設定を変更してください。

1. 左下の **歯車アイコン**（Settings）をクリック
2. 左メニューの「**General**」を選択
3. 「**Language**」のプルダウンから「**日本語**」を選択
4. 表示される「**Relaunch**」ボタンをクリックして再起動

以降の手順は日本語UIで説明します。

### 3-1. コミュニティプラグインを有効にする

1. 左下の歯車アイコン（設定）をクリック
2. 左メニューの「**コミュニティプラグイン**」を選択
3. 「**コミュニティプラグインを有効化**」（紫のボタン）をクリック

クリック後、画面が切り替わり「**閲覧**」ボタンが表示されます。

:::message
**「制限モード」について**
画面上部に「制限モードが無効になっています」と表示され、「有効化」ボタンがあります。これは制限モードを**再度オンにする**ためのボタンなので、**押さなくてOK**です。今の状態（制限モードがオフ）で正しいです。
:::

:::message alert
**コミュニティプラグインのセキュリティリスク**

コミュニティプラグインを有効にすると、サードパーティ製の拡張機能をインストールできるようになります。

**リスク：**
- プラグインはVault内の**すべてのファイルを読み書き**できます
- 悪意あるプラグインは、メモの内容を外部に送信する可能性があります
- Obsidian公式の審査はありません（開発者の自己責任）

**今回使用するプラグインの信頼性：**

| プラグイン | 特徴 |
|-----------|------|
| Local REST API | オープンソース、GitHub 500+ Star、活発にメンテナンス |
| MCP Tools | オープンソース、GitHub 100+ Star、活発にメンテナンス |

両プラグインとも**ソースコードが公開**されており、コミュニティで広く利用されています。不安な場合は、記事末尾のGitHubリンクからコードを確認できます。
:::

### 3-2. Local REST API をインストール

1. 「コミュニティプラグイン」の画面で「閲覧」をクリック
2. 検索欄に「Local REST API」と入力
3. 「Local REST API」を見つけたらクリック
4. 「インストール」→「有効化」をクリック

### 3-3. MCP Tools をインストール

1. 再び「閲覧」をクリック
2. 検索欄に「MCP Tools」と入力
3. 「MCP Tools for Obsidian」を見つけたらクリック
4. 「インストール」→「有効化」をクリック
5. 設定 → コミュニティプラグイン → MCP Tools の右側にある **歯車アイコン** をクリック
6. 設定画面で「Install server」ボタンをクリック

:::message
**Install serverとは？**
Claude CodeがObsidianと通信するためのプログラムをVault内にインストールします。
インストール完了後、以下の場所に `mcp-server.exe` が配置されます：

```
C:\Users\[ユーザー名]\iCloudDrive\iCloud~md~obsidian\[Vault名]\.obsidian\plugins\mcp-tools\bin\mcp-server.exe
```
:::

:::message alert
**確認方法**
`.obsidian` は隠しフォルダです。エクスプローラーで表示されない場合は、上部の「表示」→「隠しファイル」にチェックを入れてください。
:::

### 3-4. API Keyを取得する

1. 設定画面の左側で「Local REST API」をクリック
2. 表示される **API Key** をコピー（後で使います）

:::message alert
**API Keyのセキュリティに関する注意**

API Keyは**パスワードと同じ**です。以下に注意してください：

- ✅ コピー後はすぐに手順4-2で使用する
- ❌ テキストファイルに保存して放置しない
- ❌ スクリーンショットを撮らない
- ❌ チャットやメールで送信しない

API Keyが漏洩すると、第三者がObsidianのメモを読み取れる可能性があります。

なお、API Keyは自分のパソコン内のObsidianにアクセスするためのもので、インターネット経由で外部に送信されることはありません。
:::

---

## 手順4：Claude CodeにMCPサーバーを登録する

### 4-1. mcp-server.exe のパスを確認する

パスは環境によって異なるため、PowerShellで確認します：

```powershell
Get-ChildItem -Path "$env:USERPROFILE\iCloudDrive\iCloud~md~obsidian" -Recurse -Filter "mcp-server.exe" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
```

実行すると、以下のようにフルパスが表示されます：

```
C:\Users\[ユーザー名]\iCloudDrive\iCloud~md~obsidian\[Vault名]\.obsidian\plugins\mcp-tools\bin\mcp-server.exe
```

このパスをコピーしてください。

:::message
**パスが表示されない場合**
手順3-3の「Install server」が完了していない可能性があります。Obsidianに戻って確認してください。
:::

### 4-2. コマンドでMCPサーバーを登録する

PowerShellで以下のコマンドを実行します。**コマンドが長いので、2段階に分けます。**

**ステップ1：変数にパスとAPI Keyを設定**

```powershell
$path = "【手順4-1でコピーしたパス】"
$apikey = "【手順3-4でコピーしたAPI Key】"
```

**ステップ2：登録コマンドを実行**

```powershell
claude mcp add obsidian $path -e OBSIDIAN_API_KEY=$apikey --scope user
```

**設定例（ユーザー名が tanaka、Vault名が MainVault の場合）：**

```powershell
$path = "C:\Users\tanaka\iCloudDrive\iCloud~md~obsidian\MainVault\.obsidian\plugins\mcp-tools\bin\mcp-server.exe"
$apikey = "abc123def456..."
claude mcp add obsidian $path -e OBSIDIAN_API_KEY=$apikey --scope user
```

成功すると以下のメッセージが表示されます：

```
Added stdio MCP server obsidian with command: ...
```

:::message
**`--scope user` とは？**
この設定を**全プロジェクトで共通**で使う指定です。省略すると現在のプロジェクトでのみ有効になります。
:::

:::message
**設定の確認方法**
登録されたMCPサーバーを確認するには：
```powershell
claude mcp list
```
`obsidian: ... - ✓ Connected` と表示されればOKです。
:::

:::message alert
**エラーが出る場合**

**「command not found」エラー**
Claude Codeがインストールされていないか、PATHが通っていません。
[インストールガイド](claude-code-windows-install-guide)を参照してください。

**パスにスペースが含まれる場合**
パス全体をダブルクォートで囲んでください（上の例のように）。
:::

---

## 手順5：動作確認

:::message alert
**重要な前提条件**
Claude CodeでObsidianのメモを使うには、**Obsidianが起動している必要があります**。
毎回手動で起動するか、以下の方法でWindows起動時に自動起動する設定をしてください。

**自動起動の設定方法：**
1. `Win + R` を押して「ファイル名を指定して実行」を開く
2. `shell:startup` と入力してEnter
3. 開いたフォルダに、Obsidianのショートカットを作成（デスクトップのアイコンをCtrl+ドラッグ）
:::

### 5-1. Obsidianを起動しておく

MCP接続には**Obsidianが起動している必要があります**。
バックグラウンドで起動していればOKです。

### 5-2. Claude Codeを再起動

設定を反映するため、Claude Codeを**一度閉じて再起動**します。

### 5-3. 接続テスト

Claude Code で以下を入力してみてください：

```
Obsidianに接続できるか確認して
```

成功すると、MCPサーバーが認識されていることが表示されます。

### 5-4. メモを検索してみる

Vault内にテスト用のメモを1つ作成してから、以下を試してください：

```
Obsidianのメモ一覧を取得して
```

作成したメモが表示されれば成功です。

**本文を検索したい場合：**

```
本文も含めて「Claude Code」を探して
```

:::message
**本文検索の注意点**
デフォルトではファイル名のみ検索されます。本文を検索したい場合は「本文も含めて探して」と明示的に指示する必要があります。
:::

### 5-5. 次回以降の使い方

一度設定が完了すれば、**次回以降は特別なコマンドは不要**です。

**毎回やること：**
1. Obsidianを起動する（バックグラウンドでOK）
2. Claude Codeを起動する
3. 「Obsidianのメモを見て」と話しかける

MCP設定は保存されているため、`/mcp` や `claude mcp add` を再実行する必要はありません。

:::message alert
**Obsidianを起動し忘れると接続できません**
「Obsidianのメモを見て」と指示してエラーが出たら、Obsidianが起動しているか確認してください。
:::

---

## 活用法：こう使うと便利

以下は使い方の例です。依頼文はそのまま使えます。

### 例1：気になるXのポストを集めて「自分でも作れない？」と聞く

**手順：**
1. 外出先で、気になったXの投稿をObsidianにコピペ
2. 帰宅後、Claude Codeに聞く

```
Obsidianに保存した投稿を見て。
この中で、プログラミング経験ゼロの自分でも真似できそうなものはある？
```

Claude Codeが、投稿ごとに難しさを判断して仕分けします。

---

### 例2：技術記事の専門用語を、Claude Codeに説明してもらう

**手順：**
1. 記事のURLや本文をObsidianに保存
2. Claude Codeに聞く

```
このメモに書いた記事、専門用語が多すぎて分からない。
小学生でも分かる言葉で説明して。
```

専門用語が、日常の言葉に置き換えられた説明で返ってきます。

---

### 例3：会議のメモ書きを、Claude Codeに整理してもらう

**手順：**
1. 会議中はObsidianに箇条書きでざっくりメモ
2. 会議後にClaude Codeに依頼

```
今日の会議メモを見て。
決定事項、ToDo、次回持ち越しに分けて整理して。
```

ざっくりしたメモが、項目別に整理されます。

---

### 例4：外出先で思いついたアイデアを、帰宅後に整理する

**手順：**
1. 外出先でiPhoneのObsidianに音声入力でメモ
2. 帰宅後にClaude Codeで整理

```
今日のメモを見て。
断片的なアイデアを「やること」「調べること」「誰かに相談すること」に分けて。
```

---

### 例5：読んだ本のメモを、実践タスクに変換する

**手順：**
1. Kindleのハイライトや読書メモをObsidianに保存
2. Claude Codeに聞く

```
この読書メモを見て。
明日から試せる小さなアクションを3つ提案して。
```

読書メモから、すぐ試せる具体的な行動が3つ返ってきます。

---

## トラブルシューティング

### MCP接続関連

| 症状 | 原因 | 解決策 |
|------|------|--------|
| `/mcp` で「No MCP servers configured」 | 設定後に再起動していない | Claude Codeを終了→再起動 |
| `claude mcp list` では接続済みなのに `/mcp` で認識されない | セッション中の設定変更 | Claude Codeを終了→再起動 |
| 「パスが見つかりません」 | スペース含むパス | パスをダブルクォートで囲む |
| 「API Keyが無効」 | 環境変数未設定 | `-e OBSIDIAN_API_KEY=...` を確認 |
| 接続がタイムアウト | Obsidian未起動 | Obsidianを起動してから再試行 |

### iCloud同期関連

| 症状 | 原因 | 解決策 |
|------|------|--------|
| 「your iCloud vault was not detected」 | WindowsでVaultを先に作成した | **iPhoneでVaultを新規作成**する（手順1-2参照） |
| iPhoneでObsidianフォルダが見えない | 作成順序が逆 | iPhoneでVaultを先に作成する |
| WindowsにObsidianフォルダが表示されない | 同期の遅延 | 5〜10分待つ、iCloud for Windowsを再起動 |
| ファイルが重複・破損する | Windows + iCloudの既知問題 | 代替同期方法を検討（下記参照） |
| iPhoneに反映されない | iCloud同期が無効 | iPhone設定 → iCloud → iCloud Driveが有効か確認 |

### 「your iCloud vault was not detected」エラーの詳細

このエラーが発生する根本原因は、**iOS版Obsidianが認識する「Obsidian」フォルダとWindowsで手動作成した「Obsidian」フォルダが異なるもの**だからです。

**解決策：iPhoneでVaultを新規作成する**

手順1を最初からやり直してください：

1. iPhoneでObsidianを開く
2. 「Create new vault」→「Setup Sync」→「iCloud」を選択
3. Vault名を入力して「Create a vault」
4. Windows側でiCloud同期を待つ（5〜10分）
5. WindowsのObsidianで同期されたVaultを開く（手順2参照）

### iCloud同期の代替手段

Windows + iCloudの組み合わせで問題が続く場合は、以下の代替手段を検討してください。

| 方法 | 特徴 | コスト |
|------|------|--------|
| **Obsidian Sync** | 公式サービス、最も安定、E2E暗号化 | $4/月 |
| **Remotely Save** | コミュニティプラグイン、Dropbox/OneDrive対応 | 無料 |
| **OneDrive** | Microsoft製品との相性が良い | 無料 |

### セキュリティ関連

| 症状 | 原因 | 解決策 |
|------|------|--------|
| API Keyが漏洩した可能性がある | ファイル共有、スクリーンショット等 | ObsidianでAPI Keyを再生成（下記参照） |
| 不審なアクセスがある | API Keyの不正利用 | API Keyを再生成し、MCP設定を更新 |

**API Keyを再生成する方法：**

1. Obsidianを開く
2. 設定 → コミュニティプラグイン → Local REST API の歯車アイコン
3. 「Regenerate API Key」をクリック
4. 新しいAPI Keyをコピー
5. PowerShellで以下を実行：

```powershell
claude mcp remove obsidian --scope user
$path = "【mcp-server.exeのパス】"
$apikey = "【新しいAPI Key】"
claude mcp add obsidian $path -e OBSIDIAN_API_KEY=$apikey --scope user
```

6. Claude Codeを再起動

:::message alert
**設定が反映されない場合の確認手順**

1. **設定を確認**:
   ```powershell
   claude mcp list
   ```
   `obsidian: ... - ✓ Connected` と表示されるか確認

2. **表示されない場合は再登録**:
   ```powershell
   claude mcp add obsidian "パス" -e OBSIDIAN_API_KEY=キー --scope user
   ```

3. **Claude Codeを再起動**:
   設定は**起動時のみ**読み込まれます。セッション中に追加した設定は再起動するまで反映されません。
:::

:::message
**それでも解決しない場合**
Claude Codeが起動している状態で「MCP接続エラーを直して」と頼んでみてください。設定ファイルを自動で修正してくれる場合があります。
:::

---

## 補足：毎回の接続確認を省略するには

Claude Codeを再起動するたびに「Obsidianに接続できるか確認して」というやり取りが発生するのを避けたい場合は、以下を確認してください。

### 1. Obsidianの自動起動を設定する

手順5の冒頭で説明した方法で、Windows起動時にObsidianが自動起動するよう設定します。

### 2. MCPサーバーが正しく登録されているか確認

PowerShellで以下を実行：

```powershell
claude mcp list
```

`obsidian: ... - ✓ Connected` と表示されればOKです。

:::message
**登録されていない場合**
手順4に戻って `claude mcp add` コマンドを実行してください。
:::

### 3. 接続確認コマンド

Claude Codeのチャット画面で以下を入力：

```
/mcp
```

MCPサーバー一覧に「obsidian」が表示され、ステータスが緑（接続済み）であればOKです。

:::message alert
**重要：設定の反映タイミング**
MCPサーバーの設定は**Claude Code起動時のみ**読み込まれます。設定を追加・変更した後は、必ずClaude Codeを**再起動**してください。セッション中に設定を変更しても、`/mcp` には反映されません。
:::

---

## 使うべき人、使わなくていい人

### 使うべき人

- **iPhone + Windows** の組み合わせで使いたい
- **無料** でAI連携メモ環境を作りたい
- データを **ローカルに保存** したい（クラウド依存を避けたい）
- すでにObsidianを使っている
- メモの検索・分析をAIに任せたい

### 使わなくていい人

- **Notionで満足** している（移行コストが見合わない）
- **モバイルの操作性を最優先** したい（→ Craftがおすすめ）
- **セットアップに時間をかけたくない**（→ 純正メモ + AIアプリが手軽）
- Macユーザー（→ より簡単な連携方法がある）

---

## まとめ

iPhoneで書いたObsidianのメモを、iCloud経由でWindowsに同期し、Claude CodeがMCPで読み取れる状態になりました。

**構築した環境でできること**：

- iPhoneで書いたメモを Claude Code で検索・分析
- 「Obsidianのメモを参照して」の一言で、Claude Codeがメモを取得
- 外出先でiPhoneにメモ → 帰宅後にClaude Codeで整理

次回以降は、Obsidianを起動してからClaude Codeを起動するだけで使えます。

---

## 関連記事

- [Claude Code インストールガイド（Windows）](claude-code-windows-install-guide)
- [Claude Code 便利機能まとめ](claude-code-tips-and-features)
- [Claude Code が動かない時に見るページ（Windows）](claude-code-windows-troubleshoot)
- [ObsidianをAIの「司令塔」にする（MCP連携で39ソース自動収集の全貌）](obsidian-mcp-integration)
- [Obsidian CLI セットアップ完全ガイド（Windows環境でハマった全記録）](obsidian-cli-setup-guide)

---

## 参考リンク

- [Obsidian 公式サイト](https://obsidian.md/)
- [Local REST API プラグイン](https://github.com/coddingtonbear/obsidian-local-rest-api)
- [MCP Tools プラグイン](https://github.com/jacksteamdev/obsidian-mcp-tools)
- [iCloud for Windows](https://www.microsoft.com/store/productId/9PKTQ5699M62)
