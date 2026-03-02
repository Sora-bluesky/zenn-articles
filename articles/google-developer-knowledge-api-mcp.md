---
title: "llms.txtでは足りなかった — Google Developer Knowledge APIにたどり着いた話"
emoji: "🔗"
type: "tech"
topics: ["google", "gemini", "mcp", "ai", "llm"]
published: false
---

## この記事でできること

Antigravity や Claude Code から、Google の公式ドキュメントを自然言語で直接検索できるようになる。

```
developerknowledge_search_documents(query="Google Chat APIのメッセージ形式")
→ 5件の公式ドキュメントが即座に返ってくる
```

| Before | After |
|--------|-------|
| Web検索で公式ドキュメントを探す → 古い情報や非公式記事が混ざる | Developer Knowledge API で検索 → 公式ドキュメントのみ、24時間以内に再インデックス |

**結論を先に書く**。Antigravity で使うなら **Firebase MCP をインストールするだけ**でいい。Developer Knowledge のツールが内蔵されている。独立した MCP Server を手動設定する必要はない。

---

## Developer Knowledge API とは

2026年2月4日、Google が [Developer Knowledge API と MCP Server](https://developers.googleblog.com/introducing-the-developer-knowledge-api-and-mcp-server/) を Public Preview として発表した。ひとことで言うと、**Google の公式開発者ドキュメントを AI から直接検索できる API**。

### なぜ llms.txt では足りないのか

2025年後半から `llms.txt` が普及した。Cloudflare、Anthropic など多くのサービスが提供を始めている。Google も一部は対応している:

- ✅ `developer.chrome.com/docs/llms.txt`
- ✅ `ai.google.dev/gemini-api/docs/llms.txt`
- ❌ Google Chat API → 404
- ❌ Cloud Run → 404
- ❌ Firebase → 404

Google Chat ボットの不具合を調べようとして llms.txt を探したが、9 個の URL を試してすべて 404 だった。**Google のドキュメントは数百のサブドメインに分散しており、llms.txt で網羅するのは現実的ではない**。

Google の出した回答が Developer Knowledge API。11 以上の Google ドメインを横断して、24時間以内に自動再インデックスされる。

### llms.txt との比較

| 項目 | llms.txt | Developer Knowledge API |
|------|----------|------------------------|
| 提供形式 | 静的テキストファイル | REST API + MCP Server |
| 更新頻度 | サイト側が手動更新 | 24時間以内に自動再インデックス |
| 検索機能 | なし（全文ダウンロード） | 自然言語で検索可能 |
| AI 統合 | ファイルをコンテキストに注入 | MCP で IDE / エージェントに直結 |
| 対象範囲 | サイト単位 | 11+ Google ドメイン横断 |
| コスト | 無料 | 無料（Public Preview） |

---

## 全体構成

最終的にたどり着いた接続構成:

```
Antigravity (VS Code)
  ├── Cloud Run MCP (stdio) ← npm install -g → MCP Store で Install
  └── Firebase MCP (stdio) ← npm install -g → MCP Store で Install
        └── developerknowledge ツール ← Firebase MCP に内蔵
```

ポイントは、**Developer Knowledge API の独立した MCP Server（httpUrl 型）を手動設定する必要がない**こと。Firebase MCP をインストールすれば、`developerknowledge_search_documents` ツールが自動的に使える。

---

## セットアップ: Firebase MCP 経由（Antigravity 向け）

Antigravity で Developer Knowledge API を使う最短ルート。

### API を有効化する

Google Cloud Console で Developer Knowledge API を有効化する。`gcloud` CLI が使える場合:

```bash
gcloud services enable developerknowledge.googleapis.com --project=YOUR_PROJECT_ID
```

:::message
`YOUR_PROJECT_ID` は自分で作成・管理しているプロジェクトを指定する。AI Studio が自動生成する `gen-lang-client-*` プロジェクトは削除済みや API 無効のことが多く、使えない可能性が高い。
:::

### Firebase MCP をインストール

**npm でグローバルインストールしてから、MCP Store で Install する**。この順番が重要。

```bash
npm install -g firebase-tools
```

:::message alert
MCP Store の Install ボタンを先にクリックすると、依存パッケージの解決に失敗してエラーになることがある。Cloud Run MCP（`@google-cloud/cloud-run-mcp`）も同様。**先に npm でインストールしておけば、MCP Store は設定ファイルの追記だけで済む**のでエラーが出にくい。
:::

npm インストール後、Antigravity の MCP Store で「Firebase」を検索して Install。その後 **Antigravity を再起動する**。MCP 設定はセッション開始時にしかロードされないため、再起動しないと反映されない。

### Active Project を設定

Firebase MCP は起動時にどの GCP プロジェクトを使うか知らない。Antigravity のチャットで Active Project を指定する:

```
Firebase の Active Project を YOUR_PROJECT_ID に設定して
```

未設定のまま Developer Knowledge を呼ぶと `"The resource id projects/ is invalid"` エラーになる。

### 動作確認

```
Cloud Runにコンテナをデプロイする方法を Developer Knowledge で検索して
```

公式ドキュメントの内容が返ってくれば完了。

---

## セットアップ: httpUrl 直接接続（Gemini CLI / Claude Code / Cursor）

Firebase MCP を経由せず、Developer Knowledge MCP Server に直接接続する公式手順。Gemini CLI、Claude Code、Cursor で使う場合はこちら。

公式ドキュメント: [developers.google.com/knowledge/mcp](https://developers.google.com/knowledge/mcp)

### 事前準備: API キーの作成

```bash
# API を有効化
gcloud services enable developerknowledge.googleapis.com --project=YOUR_PROJECT_ID

# MCP Server を有効化
gcloud beta services mcp enable developerknowledge.googleapis.com --project=YOUR_PROJECT_ID

# API キーを作成（Developer Knowledge API 制限付き）
gcloud services api-keys create --project=YOUR_PROJECT_ID \
  --display-name="DK API Key" \
  --api-target=service=developerknowledge.googleapis.com
```

:::message
`YOUR_PROJECT_ID` は Google Cloud Console で作成した自分のプロジェクト ID。最後の `api-keys create` コマンドの出力に含まれるキー文字列が、次の設定で使う `YOUR_API_KEY` になる。
:::

:::message
`gcloud beta` コマンドが失敗する場合は `gcloud components update beta` でベータコンポーネントを更新する。
:::

### Gemini CLI

```json
// ~/.gemini/settings.json
{
  "mcpServers": {
    "google-developer-knowledge": {
      "httpUrl": "https://developerknowledge.googleapis.com/mcp",
      "headers": {
        "X-Goog-Api-Key": "YOUR_API_KEY"
      }
    }
  }
}
```

### Claude Code

```bash
claude mcp add google-dev-knowledge \
  --transport http \
  https://developerknowledge.googleapis.com/mcp \
  --header "X-Goog-Api-Key: YOUR_API_KEY"
```

### Cursor

```json
// .cursor/mcp.json
{
  "mcpServers": {
    "google-developer-knowledge": {
      "url": "https://developerknowledge.googleapis.com/mcp",
      "headers": {
        "X-Goog-Api-Key": "YOUR_API_KEY"
      }
    }
  }
}
```

:::message alert
**Antigravity で httpUrl 型を使う場合の注意**: 2026年3月時点で、Antigravity は `httpUrl` 型の MCP Server を認識しない場合がある。`mcp_config.json` に正しく設定しても `server name not found` になるケースを確認している。この場合は前述の Firebase MCP 経由を使う。
:::

---

## 僕がハマった全記録

自作の Google Chat Bot が DM に応答しない。Cloud Run は正常に 200 を返しているのに、Chat 側で「応答がありません」と表示される。Antigravity に調査させてもコード修正 → デプロイ → テストのループを3日間繰り返すだけで原因がわからない。「公式ドキュメントをピンポイントで引ければ解決するのでは」と思い Developer Knowledge API のセットアップを始めたが、そこからさらに1日ハマった。

### llms.txt を 9 個試して全滅

Google Chat ボットが DM に応答しない問題を調べるため、まず llms.txt を探した。

```
試したURL（すべて 404）:
- developers.google.com/workspace/chat/llms.txt
- developers.google.com/workspace/chat/docs/llms.txt
- cloud.google.com/run/docs/llms.txt
- cloud.google.com/run/docs/llms-full.txt
- cloud.google.com/docs/llms.txt
- firebase.google.com/llms.txt
- developers.google.com/workspace/docs/llms.txt
- developers.google.com/chat/api/docs/llms.txt
- developers.google.com/apps-script/docs/llms.txt
```

全滅。ここで Developer Knowledge API の存在を知った。

### API キーが 403 で弾かれた

既存の API キーで Developer Knowledge API を叩いたら `API_KEY_SERVICE_BLOCKED`。原因は単純で、**API キーを作ったプロジェクトと Developer Knowledge API を有効化したプロジェクトが違っていた**。AI Studio が自動生成する `gen-lang-client-*` プロジェクトのキーを使っていたのが間違い。

自分で管理しているプロジェクトで API を有効化し、新しい API キーを作り直して解決した。

### MCP を設定したのに繋がらない

`~/.gemini/settings.json` に MCP Server の設定を追加して「完了」としたが、次のセッションで `list_resources` を実行すると `server name not found`。

調べてみると、**Antigravity は `settings.json` ではなく `~/.gemini/antigravity/mcp_config.json` を読み込む**。しかも `mcp_config.json` が空でもエラーは出ない。MCP が「存在しない」だけで静かに失敗する。

この落とし穴に気づくまで数時間かかった:

| ツール | 設定ファイル |
|--------|------------|
| Gemini CLI | `~/.gemini/settings.json` |
| Antigravity | `~/.gemini/antigravity/mcp_config.json` |

### httpUrl 型が認識されない

`mcp_config.json` に設定を書いて Antigravity を再起動しても、まだ `server name not found`。

ここで「そもそもサーバー側が悪いのか、クライアント側が悪いのか」を切り分けることにした。PowerShell から MCP プロトコルを直接叩いてみた:

```powershell
$body = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{
  "protocolVersion":"2024-11-05",
  "capabilities":{},
  "clientInfo":{"name":"test","version":"1.0"}}}'

Invoke-RestMethod -Uri "https://developerknowledge.googleapis.com/mcp" `
  -Method POST -ContentType "application/json" `
  -Headers @{"X-Goog-Api-Key"="YOUR_API_KEY"} -Body $body
```

```json
{
  "result": {
    "serverInfo": { "name": "StatelessServer", "version": "ESF" },
    "protocolVersion": "2024-11-05"
  }
}
```

**サーバー側は完全に正常**。`tools/list` を叩くと `search_document_chunks` と `batch_get_documents` の 2 つのツールも返ってくる。

| 検証項目 | 結果 |
|----------|------|
| MCP `initialize` | ✅ 成功 |
| MCP `tools/list` | ✅ 2 ツール返却 |
| Antigravity `list_resources` | ❌ `server name not found` |

問題は Antigravity 側にあった。**Antigravity が `httpUrl` 型（HTTP リモートサーバー）の MCP Server を認識していない**可能性が高い。`stdio` / `sse` 型のみサポートしているのかもしれない。

> MCP Server が「繋がらない」とき、サーバーが悪いのかクライアントが悪いのかを切り分けるのが鉄則。PowerShell で MCP プロトコルを直接叩けばサーバー側の検証は 3 分で終わる。

### Firebase MCP に Developer Knowledge が内蔵されていた

httpUrl 型がダメなら別のルートを探す。MCP Store を見ると、Cloud Run MCP と Firebase MCP が利用可能だった。両方インストールしてみた。

Cloud Run MCP は副産物だったが、これが思わぬ収穫だった。`deploy-local-folder`（ローカルフォルダを直接デプロイ）と `get-service-log`（ログ取得）が使えるようになり、**Antigravity がシェルコマンドを介さずに Cloud Run を直接操作できる**。それまでは Antigravity が `gcloud run deploy` をシェル経由で実行していたが、Cloud Run MCP があれば MCP ツールとしてネイティブにデプロイ・ログ確認まで完結する。

そして Firebase MCP。Antigravity を再起動したところ、ツール一覧に `developerknowledge_search_documents` が含まれていた。**Firebase MCP が Developer Knowledge API をラップして提供していた**。これが正解のルートだった。

ただし Active Project の設定でもうひと波乱:

```
# gen-lang-client-* プロジェクトを試す
firebase_update_environment(active_project="gen-lang-client-XXXXXXXXXX")
→ 403: "Project has been deleted" 💀

firebase_update_environment(active_project="gen-lang-client-YYYYYYYYYY")
→ 403: "Project has been deleted" 💀

firebase_update_environment(active_project="gen-lang-client-ZZZZZZZZZZ")
→ 403: "Service Usage API has not been used in project..." 💀

# 自分で管理しているプロジェクトを指定
firebase_update_environment(active_project="YOUR_PROJECT_ID")
→ 成功 ✅ — 5 件の公式ドキュメント取得
```

AI Studio が自動生成する `gen-lang-client-*` プロジェクトは軒並み削除済みか API 無効。自分のプロジェクトを指定してようやく解決した。

返ってきた結果を見て驚いた。「Workspace 系ドキュメント（Chat API）はコーパスに含まれていない」と思い込んでいたが、**Chat API のドキュメントは正常にインデックスされていた**。0 件だったのはすべて API キーとプロジェクト設定の問題だった。

### Developer Knowledge API で Chat Bot のバグを一発で特定した

![4日間「応答がありません」と言われ続けた Chat Bot が、Developer Knowledge API で原因を特定した直後にようやく応答した瞬間](/images/dk-api-chatbot-before-after.png)
*4日間の「応答がありません」→ Developer Knowledge API で原因特定 → ついに応答*

MCP 接続が完了したので、本題の Chat Bot が応答しない問題に Developer Knowledge API を使ってみた。

「Google Workspace Add-ons Chat response format」を検索したところ、5 件の公式ドキュメントが返ってきた。その中に正しい Add-on レスポンス形式が明記されていた:

```json
// ❌ 僕のコード
{"renderActions": {"hostAppAction": {"chatDataAction": ...}}}

// ✅ 公式ドキュメント
{"hostAppDataAction": {"chatDataAction": {"createMessageAction": {"message": {...}}}}}
```

**根本原因**: トップレベルのキー名が `renderActions.hostAppAction` ではなく `hostAppDataAction` だった。1 単語の違いで Chat が応答しなくなる。

修正して Cloud Run MCP 経由で再デプロイ → Chat Bot がついに応答した。

振り返ると、こういう流れだった:

1. Chat Bot が双方向通信できない問題が発生
2. Antigravity に調査させる → コード修正 → Cloud Run にデプロイ → Chat でテスト → 「応答がありません」、のループを **3日間**
3. Developer Knowledge API を使おうとして設定トラブルで **さらに1日**
4. Developer Knowledge API が動いた瞬間、**数分で根本原因を特定**

4日かけても見つからなかったキー名の1単語違いを、Developer Knowledge API は数分で教えてくれた。Web 検索では公式ドキュメントの正しい箇所にたどり着けなかったのに、Developer Knowledge API なら「Add-ons Chat response format」と聞くだけでピンポイントで返ってくる。**これが llms.txt にはない「検索型 API」の強み**だった。

結果的に、Firebase MCP（Developer Knowledge API で原因特定）と Cloud Run MCP（デプロイ・ログ確認）の組み合わせで、**調査からデプロイまで Antigravity のチャット内で完結する**環境が手に入った。Developer Knowledge API を使おうとして入れた MCP が、開発ワークフロー全体を変えた形になった。

---

## ハマりポイント集

僕が踏んだ地雷を整理しておく。

### ① API キーのプロジェクトミスマッチ

| 項目 | 内容 |
|------|------|
| エラー | `API_KEY_SERVICE_BLOCKED` |
| 原因 | API キー作成プロジェクト ≠ API 有効化プロジェクト |
| 解決 | 同じプロジェクトで API 有効化 + キー作成する |

### ② Antigravity は settings.json を読まない

| 項目 | 内容 |
|------|------|
| Gemini CLI | `~/.gemini/settings.json` |
| Antigravity | `~/.gemini/antigravity/mcp_config.json` |
| 危険な理由 | `mcp_config.json` が空でもエラーは出ない。静かに失敗する |

### ③ httpUrl 型が認識されない場合がある

Antigravity は `httpUrl` 型の MCP Server を認識しないことがある。その場合は Firebase MCP 経由で使う（`developerknowledge` ツールが内蔵されている）。

### ④ gen-lang-client-* プロジェクトは信用するな

AI Studio が自動生成する `gen-lang-client-*` プロジェクトは削除済みまたは API 無効であることが多い。`list_projects` で表示されても、Active Project として使えるとは限らない。自分で管理しているプロジェクトを使う。

### ⑤ Active Project の設定が必要

Firebase MCP で Developer Knowledge API を使うには Active Project の指定が必須。未設定だと `"The resource id projects/ is invalid"` エラーになる。

### ⑥ MCP 設定変更はセッション再起動が必要

MCP 設定ファイルを変更しても現在のセッションには反映されない。Antigravity の再起動が必要。セッション中に「接続テスト → 失敗」で焦らない。

### ⑦ MCP Server 有効化を忘れがち

API を直接呼べても MCP Server は別途有効化が必要:

```bash
gcloud beta services mcp enable developerknowledge.googleapis.com --project=YOUR_PROJECT_ID
```

:::message
`YOUR_PROJECT_ID` は前述のセットアップで使ったものと同じプロジェクト ID。
:::

### ⑧ コーパスの対象範囲

Workspace 系ドキュメント（Chat API 等）もコーパスに含まれている。「0 件」が返ってきたら、コーパスではなく API キーやプロジェクト設定を疑う。対象ドメインは公式の[コーパスリファレンス](https://developers.google.com/knowledge/reference/corpus-reference)で確認できる。

---

## 今後の展望

Public Preview の段階なので、GA（正式リリース）時には以下が予告されている:

- 構造化コンテンツ（コードサンプル、API リファレンス）のサポート追加
- コーパスの拡大（より多くの Google 開発者ドキュメント）
- 再インデックスのレイテンシ改善

---

## まとめ

1. **Google は llms.txt ではなく Developer Knowledge API + MCP Server が本命**
2. **Antigravity なら Firebase MCP が最短ルート** — インストールするだけで Developer Knowledge ツールが内蔵されている
3. **httpUrl 型は Antigravity で認識されない場合がある** — Gemini CLI / Claude Code / Cursor なら公式手順で直接接続可能
4. **Active Project の設定を忘れずに** — `gen-lang-client-*` は避けて自分のプロジェクトを使う
5. **繋がらないときはサーバーとクライアントを切り分ける** — PowerShell で MCP プロトコルを直接叩けば 3 分で検証できる
6. **Firebase MCP + Cloud Run MCP で開発ループが変わる** — Developer Knowledge API で原因特定、Cloud Run MCP でデプロイ・ログ確認。調査からデプロイまで Antigravity 内で完結する

---

## 参考リンク

- [公式ブログ: Introducing the Developer Knowledge API and MCP Server](https://developers.googleblog.com/introducing-the-developer-knowledge-api-and-mcp-server/)
- [MCP Server セットアップドキュメント](https://developers.google.com/knowledge/mcp)
- [API リファレンス](https://developers.google.com/knowledge/api)
- [コーパスリファレンス](https://developers.google.com/knowledge/reference/corpus-reference)
