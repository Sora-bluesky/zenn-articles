---
title: "Google Workspace MCPサーバー実践ガイド"
emoji: "📋"
type: "tech"
topics: ["claudecode", "mcp", "googleworkspace", "ai", "個人開発"]
published: false
---

:::message
**シリーズ構成**
1. [導入編：作った話](google-workspace-mcp-overview)
2. [開発編：Claude Codeとの共同開発](google-workspace-mcp-dev-process)
3. **実践編：セットアップと使い方**（この記事）
:::

セットアップは1回だけ。終わればClaudeに話しかけるだけでGoogle Workspaceが動く。

:::message
**動作確認環境**: Windows 11 + Node.js 20 / 2026年2月時点
:::

---

## セットアップ

### 用意するもの

- [Node.js](https://nodejs.org/ja) 20以上（JavaScriptの実行環境。インストール後、ターミナルで `node -v` と打って `v20.x.x` 以上が表示されればOK）
- Googleアカウント
- Claude Code または Claude Desktop（Claude Proプラン 月額$20〜 が必要）

### Google Cloudプロジェクトの準備

[Google Cloud Console](https://console.cloud.google.com)（Googleのサービスを管理するための画面）で以下を行う。Google Cloud自体の利用は無料。

1. 新しいプロジェクトを作成
2. 6つのAPI（アプリ同士が情報をやりとりするための窓口）を有効化する
   - Google Docs API
   - Google Drive API
   - Google Sheets API
   - Google Calendar API
   - Google Tasks API
   - Gmail API
3. OAuth（Googleアカウントの権限を安全に貸し出す仕組み）同意画面を設定する。ユーザーの種類は外部を選び、テストユーザーに自分のGoogleアカウントを追加する
4. OAuthクライアントID（このアプリをGoogleに識別させるための番号）を作成する。アプリケーションの種類はデスクトップアプリ。作成後にJSONをダウンロードする

:::message
テストユーザーに追加したアカウントでないと認証時にアクセス拒否される。ここを忘れるとハマる。
:::

### インストールと認証

```bash
# リポジトリ（ソースコード置き場）からファイルをダウンロード
git clone https://github.com/Sora-bluesky/google-workspace-mcp-ja.git
cd google-workspace-mcp-ja

# ダウンロードしたJSONをcredentials.jsonとして配置
# Windowsの場合:
copy <ダウンロードしたJSONファイルのパス> credentials.json
# Mac/Linuxの場合:
# cp <ダウンロードしたJSONファイルのパス> credentials.json

npm install    # 必要な部品をダウンロード
npm run build  # プログラムを実行可能な形に変換
npm run setup  # Googleアカウントとの認証を行う
```

:::message
gitがインストールされていない場合は、[GitHubのリポジトリページ](https://github.com/Sora-bluesky/google-workspace-mcp-ja)から「Code → Download ZIP」でダウンロードし、展開しても同じことができる。
:::

`npm run setup` でブラウザが開く。Googleアカウントでログインして権限を許可する。

:::message
「このアプリはGoogleで確認されていません」と表示されたら、詳細 → 安全ではないページに移動で進める。自分で作ったアプリなので問題ない。
:::

認証が完了すると `token.json` が生成される。

:::message alert
`token.json` には自分のGoogleアカウントへのアクセス権が含まれている。他人と共有しないこと。gitリポジトリにコミットしないこと（`.gitignore` で除外済み）。
:::

### Claude Codeでの設定

`~/.claude/settings.json`（Windowsの場合 `C:\Users\[ユーザー名]\.claude\settings.json`）に追加する。

```json
{
  "mcpServers": {
    "google-workspace-ja": {
      "command": "node",
      "args": ["C:/Users/[ユーザー名]/google-workspace-mcp-ja/build/index.js"]
    }
  }
}
```

`[ユーザー名]` の部分は自分のWindowsユーザー名に置き換える。パスの区切りは `/` でも `\\` でも動く。

### 動作確認

```bash
npm run inspect
```

MCP Inspector（MCPサーバーの動作を確認するためのテストツール）が起動する。Connect → Tools → List Toolsで36個のツールが表示されれば成功。

Claude Code上で確認する場合は、起動後に `/mcp` と入力して `google-workspace-ja` が `Connected` と表示されればOK。

---

## 使う前に知っておくこと

### サーバーの起動は自動

settings.jsonにMCPサーバーを登録すると、Claude Codeを起動するたびに自動で立ち上がる。毎回 `npm run build` や `node build/index.js` を手動で実行する必要はない。Claude Codeを閉じればサーバーも止まる。

### ファイルの認識はリクエスト型

MCPサーバーはGoogleドライブの中身を常時監視しているわけではない。Claudeがツールを呼ぶたびに、その都度Google APIに問い合わせる仕組みだ。

新しく作ったドキュメントでも、URLやファイルIDを渡せばすぐ操作できる。逆に言えば、何も指示しなければサーバーはGoogleに一切アクセスしない。

### 認証は2系統ある

Google Workspace（Docs、Drive、Gmail等）の認証はOAuth（Googleアカウントの権限を安全に貸し出す仕組み）。セットアップ時に `npm run setup` で取得した `token.json` がこれにあたる。

Gemini連携ツール（敬語チェック、返信下書き等）を使う場合は、別途Gemini APIキーが必要になる。[Google AI Studio](https://aistudio.google.com/)で無料で発行できる（2026年2月時点）。Gemini連携を使わないなら、この設定は不要。

---

## 試し実行モード（dryRun）の使い方

書き込み、更新、削除を行うツールは全て試し実行モード（dryRun）がデフォルトでONになっている。

操作の流れ:

1. Claudeに操作を頼む（例: メールを送って）
2. プレビューが返ってくる（実際には送信されない）
3. 内容を確認して問題なければ「dryRun: falseで実行して」と伝える
4. 実行される

読み取り系のツールにはdryRunがないので、そのまま結果が返る。

---

## Google Docs

基本ツールは2つ（読み取り、書き込み）。Gemini連携ツール（報告書構造化、議事録構造化）は[Geminiツール編](google-workspace-mcp-gemini-tools)で解説している。

試すこと:

- このドキュメントを読んで、とGoogleドキュメントのURLを渡す
- このドキュメントの末尾にテスト追記と書き込んで → プレビュー確認 → 実行

URLからドキュメントIDを自動で抽出するので、URLをそのまま貼ればいい。

---

## Google Drive

7ツール。一覧、検索、フォルダ作成、アップロード、コピー、移動、削除。

試すこと:

- マイドライブのファイル一覧を見せて
- マイドライブからPDFを検索して
- マイドライブにテスト用フォルダを作って → プレビュー → 実行
- このファイルをゴミ箱に移動して → プレビュー → 実行

削除はゴミ箱移動のみ。完全削除はできない設計にしてある。

---

## Google Sheets

4ツール。読み取り、書き込み、行追加、新規作成。

試すこと:

- このスプレッドシートを読んで、とURLを渡す
- A1セルにテストと書き込んで → プレビュー → 実行
- 最終行にデータを追加して: 名前, 日付, 金額 → プレビュー → 実行
- 新しいスプレッドシートを作って → プレビュー → 実行

セル範囲はA1記法（Excelと同じセルの指定方法）で指定する。A1:C10のような範囲指定も対応。

---

## Google Calendar

5ツール。カレンダー一覧、イベント取得、作成、更新、削除。

試すこと:

- カレンダーの一覧を見せて
- 今週の予定を教えて
- 明日の14時から1時間の打ち合わせを入れて → プレビュー → 実行
- 来週の月曜の会議を15時に変更して → プレビュー → 実行
- このイベントを削除して → プレビュー → 実行

日本語の日時表現に対応している。来週の月曜、3日後、今月末、再来週の金曜などが使える。

---

## Google Tasks

6ツール。リスト一覧、詳細、作成、更新、完了、削除。

試すこと:

- タスクリストを見せて
- デフォルトのリストにタスクを追加: 牛乳を買う → プレビュー → 実行
- このタスクを完了にして → プレビュー → 実行
- このタスクを削除して → プレビュー → 実行

タスクIDはリスト表示で確認できる。

---

## Gmail

基本ツールは6つ（一覧、読み取り、送信、下書き作成、返信、ゴミ箱移動）。Gemini連携ツール（返信下書き自動生成、敬語チェック）は[Geminiツール編](google-workspace-mcp-gemini-tools)で解説している。

試すこと:

- 受信トレイの最新5件を見せて
- このメールを読んで、とメールIDを渡す
- 下書きを作成して: 宛先〇〇@example.com、件名テスト、本文MCPサーバーからの送信テスト → プレビュー → 実行
- 〇〇@example.comにメールを送って → プレビュー → 必ず確認してから実行
- このメールに返信して: 了解しました → プレビュー → 実行

メール送信は特にプレビューを慎重に確認すること。宛先、件名、本文が意図通りかを目視で確かめてから実行する。

---

## 日本語の日時解析

datetime-parserが日本語の日時表現を日付に変換する。

対応する表現の例:

- 来週の月曜
- 3日後
- 今月末
- 再来週の金曜
- 明後日の15時

カレンダーやタスクと組み合わせて使う。

---

## トラブルシューティング

### Node.jsが見つからない

`node -v` でバージョンが表示されない場合は、[Node.js公式サイト](https://nodejs.org/ja)からLTS版をインストールする。インストール後はターミナルを再起動すること。

### npm installでエラーが出る

管理者権限が必要な場合がある。Windowsなら「管理者として実行」でターミナルを開き直す。

### アクセスをブロック、access_deniedが出る

OAuth同意画面のテストユーザーに自分のアカウントを追加しているか確認する。追加後もエラーが出る場合はシークレットウィンドウで `npm run setup` を再実行。

### 認証の有効期限が切れた

```bash
# Windowsの場合:
del token.json
# Mac/Linuxの場合:
# rm token.json

npm run setup
```

### 新しいサービスが使えない、スコープ不足

APIを追加で有効化した場合やサーバーをアップデートした場合も、token.jsonを削除して再認証する。

### ドキュメントが見つからない

ドキュメントIDが正しいか確認する。他のアカウントのリソースは共有設定が必要。

---

## テスト運用チェックリスト

一通り試して動作を確認する。

- [ ] セットアップ完了。MCP Inspectorで36ツール表示
- [ ] Docs: 読み取り → 書き込み（プレビュー → 実行）
- [ ] Drive: 一覧 → 検索 → フォルダ作成
- [ ] Sheets: 読み取り → 書き込み → 行追加
- [ ] Calendar: 一覧 → イベント作成 → 更新
- [ ] Tasks: リスト表示 → タスク追加 → 完了
- [ ] Gmail: 一覧 → 読み取り → 下書き作成 → 送信
- [ ] 日本語日時解析: 「来週の月曜」で正しい日付が返る
- [ ] dryRun: プレビュー → 実行の2段階が機能する

Geminiを活用したツール（敬語チェック、返信下書き、報告書・議事録の構造化）は[こちらの記事](google-workspace-mcp-gemini-tools)で紹介している。
