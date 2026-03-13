---
title: "llms.txtでは足りなかった — Google Developer Knowledge APIにたどり着いた話"
emoji: "🔗"
type: "tech"
topics: ["googlecloud", "gemini", "mcp", "ai", "llm"]
published: true
---

:::message
この記事は `gcloud` CLI や REST API の基本操作に慣れている人を想定している。Google Antigravity（VS Code）で検証した内容がベースだが、Gemini CLI、Claude Code、Cursor でも同じ API を使える。
:::

## この記事でできること

Google の公式ドキュメントだけを、API 一発で検索できるようになる。

```
Cloud Runにコンテナをデプロイする方法を教えて
```

MCP 経由ならこの一言で、IDE が Developer Knowledge API を叩いて公式ドキュメントを5件返してくれる。MCP が使えない環境でも、REST API を直接叩けば同じ結果が得られる。

**Before**: Web 検索で公式ドキュメントを探す。古い情報や非公式記事が混ざって、正しい情報にたどり着けない
**After**: Developer Knowledge API で検索。公式ドキュメントだけが返り、[公式ブログによると](https://developers.googleblog.com/introducing-the-developer-knowledge-api-and-mcp-server/)24時間以内に再インデックスされる

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

僕は Google Chat ボットの不具合を調べようとして llms.txt を探したが、9 個の URL を試してすべて 404 だった。**Google のドキュメントは数百のサブドメインに分散しており、llms.txt で網羅するのは現実的ではない**。

Google の出した回答が Developer Knowledge API。11 以上の Google ドメインを横断して、自動で再インデックスされる。

### llms.txt との比較

| 項目 | llms.txt | Developer Knowledge API |
|------|----------|------------------------|
| 提供形式 | 静的テキストファイル | REST API + MCP Server |
| 更新頻度 | サイト側が手動更新 | 自動再インデックス |
| 検索機能 | なし（全文ダウンロード） | 自然言語で検索可能 |
| AI 統合 | ファイルをコンテキストに注入 | MCP で IDE / エージェントに直結 |
| 対象範囲 | サイト単位 | 11+ Google ドメイン横断 |
| コスト | 無料 | 無料（Public Preview） |

---

## セットアップ: REST API 直接利用

2026年3月時点で**最も確実な方法**。MCP の設定不要で、API キーさえあれば動く。

### Step 1: API を有効化する

Google Cloud Console で Developer Knowledge API を有効化する。

```bash
# gcloud services enable: 指定した API をプロジェクトで有効化するコマンド
gcloud services enable developerknowledge.googleapis.com --project=YOUR_PROJECT_ID
```

:::message
`YOUR_PROJECT_ID` は自分で作成・管理しているプロジェクトを指定する。AI Studio が自動生成する `gen-lang-client-*` プロジェクトは削除済みや API 無効のことが多い。必ず自分のプロジェクトを使う。
:::

### Step 2: API キーを作成する

```bash
# api-keys create: API キーを新規作成する。--api-target で利用可能な API を制限できる
gcloud services api-keys create --project=YOUR_PROJECT_ID \
  --display-name="DK API Key" \
  --api-target=service=developerknowledge.googleapis.com
```

コマンドの出力に含まれるキー文字列が `API_KEY` になる。

:::message alert
**API キーのプロジェクトに注意**: API キーを作成したプロジェクトと、API を有効化したプロジェクトが違うと `API_KEY_SERVICE_BLOCKED`（403）になる。同じプロジェクトで両方の操作を行うこと。
:::

### Step 3: 動作確認

```bash
# API_KEY に Step 2 で取得したキー文字列を入れる
curl -s "https://developerknowledge.googleapis.com/v1alpha/documents:searchDocumentChunks?query=Firestore&key=YOUR_API_KEY"
```

レスポンス:

```json
{
  "results": [
    {
      "parent": "documents/docs.cloud.google.com/firestore/...",
      "id": "c1",
      "content": "..."
    }
  ],
  "nextPageToken": "..."
}
```

`results` 配列に公式ドキュメントの内容が返ってくれば成功。

:::message alert
**レスポンスのフィールド名に注意**: REST API は **`results`** フィールドで結果を返す。MCP 経由の場合は `chunks` フィールドになる。同じ API なのにフィールド名が違うので、パース時に間違えやすい（Public Preview の仕様）。
:::

### 活用例: Tech Watch 自動チェック

使用中サービスの廃止・変更を定期チェックするスクリプト。

:::message alert
`.env` ファイルには API キーが含まれるため、**Git にコミットしないこと**。`.gitignore` に `.env` を追加しておく。
:::

```bash
#!/bin/bash
# .env ファイルから API キーの値を取り出す
API_KEY="$(grep DEVELOPERKNOWLEDGE_API_KEY .env | cut -d= -f2)"
QUERIES=(
  "Gemini model deprecation and migration guide"
  "Google Chat API updates and changes"
  "Cloud Run new features and updates"
  "Firestore new features and best practices"
)

for q in "${QUERIES[@]}"; do
  encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$q'))")
  echo "=== $q ==="
  curl -s "https://developerknowledge.googleapis.com/v1alpha/documents:searchDocumentChunks?query=${encoded}&key=${API_KEY}" \
    | python3 -c "import sys,json; r=json.load(sys.stdin); [print(f'  {x[\"parent\"]}') for x in r.get('results',[])[:3]]"
  echo
done
```

:::message
Windows の場合は WSL2（Windows 上で Linux コマンドを使える仕組み）内で実行するか、`python3` を `python` に読み替えること。
:::

---

## セットアップ: MCP 経由（IDE から直接検索）

REST API でも十分だが、MCP 経由なら IDE のチャットから「〜を Developer Knowledge で検索して」と自然言語で呼べる。ツールごとの設定方法を載せておく。

公式ドキュメント: [developers.google.com/knowledge/mcp](https://developers.google.com/knowledge/mcp)

### 事前準備

REST API のセットアップに加えて、MCP Server の有効化が必要:

```bash
# MCP Server を有効化する（REST API だけなら不要）
gcloud beta services mcp enable developerknowledge.googleapis.com --project=YOUR_PROJECT_ID
```

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

### Antigravity（Firebase MCP 経由）

:::message alert
**2026年3月時点の既知の問題**: firebase-tools の `developerknowledge_search_documents` ツールは `invalid argument` エラーで動作しない。バグが修正されるまでは REST API 直接利用を推奨。
:::

Antigravity は `httpUrl` 型の MCP Server を認識しない場合がある。その代わり、Firebase MCP が Developer Knowledge API をラップして提供している。バグが修正されれば、以下の手順で使えるようになる:

1. `npm install -g firebase-tools` でインストール
2. Antigravity の MCP Store で「Firebase」を検索して Install
3. Antigravity を再起動（MCP 設定はセッション開始時にしかロードされない）
4. チャットで Active Project を指定:

```
Firebase の Active Project を YOUR_PROJECT_ID に設定して
```

:::message
Active Project を設定しないと `"The resource id projects/ is invalid"` エラーになる。`gen-lang-client-*` ではなく、自分で管理しているプロジェクトを指定すること。
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

### API キーで 403、MCP で "not found"、設定ファイル違い

ここから怒涛のトラブルラッシュだった。

まず既存の API キーで叩いたら `API_KEY_SERVICE_BLOCKED`。AI Studio が自動生成した `gen-lang-client-*` プロジェクトのキーを使っていたのが原因で、自分のプロジェクトでキーを作り直して解決。

次に `~/.gemini/settings.json` に MCP 設定を書いたが `server name not found`。数時間悩んで気づいた — **Antigravity は `settings.json` ではなく `~/.gemini/antigravity/mcp_config.json` を読む**。しかも設定が空でもエラーは出ない。静かに失敗する。

| ツール | 設定ファイル |
|--------|------------|
| Gemini CLI | `~/.gemini/settings.json` |
| Antigravity | `~/.gemini/antigravity/mcp_config.json` |

### 「サーバーが悪いのか、クライアントが悪いのか」を切り分けた

`mcp_config.json` を直しても、まだ `server name not found`。ここで闇雲に設定を変えるのをやめて、**サーバー側とクライアント側の切り分け**に方針を変えた。PowerShell から MCP プロトコルを直接叩いてみる:

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

**サーバー側は完全に正常**。`tools/list` を叩いても `search_document_chunks` と `batch_get_documents` が返ってくる。問題は Antigravity 側にあった。

> MCP Server が「繋がらない」とき、サーバーとクライアントの切り分けが鉄則。MCP プロトコルを直接叩けばサーバー側の検証は 3 分で終わる。

### Firebase MCP で突破口が開けた

httpUrl 型がダメなら別のルートを探す。MCP Store で Firebase MCP をインストールして Antigravity を再起動したところ、ツール一覧に `developerknowledge_search_documents` が含まれていた。**Firebase MCP が Developer Knowledge API をラップしていた**。

ただし Active Project でもうひと波乱:

```
# gen-lang-client-* を3つ試す → 全部ダメ
firebase_update_environment(active_project="gen-lang-client-XXXXXXXXXX")
→ 403: "Project has been deleted" 💀

firebase_update_environment(active_project="gen-lang-client-YYYYYYYYYY")
→ 403: "Project has been deleted" 💀

# 自分のプロジェクトでようやく成功
firebase_update_environment(active_project="YOUR_PROJECT_ID")
→ 成功 ✅ — 5 件の公式ドキュメント取得
```

返ってきた結果を見て驚いた。「Workspace 系ドキュメント（Chat API）はコーパスに含まれていない」と思い込んでいたが、**Chat API のドキュメントは正常にインデックスされていた**。0 件だったのはすべて API キーとプロジェクト設定の問題だった。

> 0 件が返ってきたら、コーパスではなく設定を疑う。対象ドメインは公式の[コーパスリファレンス](https://developers.google.com/knowledge/reference/corpus-reference)で確認できる。

### Developer Knowledge API で Chat Bot のバグを一発で特定

![4日間「応答がありません」と言われ続けた Chat Bot が、Developer Knowledge API で原因を特定した直後にようやく応答した瞬間](/images/dk-api-chatbot-before-after.png)
*4日間の「応答がありません」→ Developer Knowledge API で原因特定 → ついに応答*

MCP 接続が完了したので、本題の Chat Bot が応答しない問題に使ってみた。

「Google Workspace Add-ons Chat response format」で検索したところ、5 件の公式ドキュメントが返ってきた。その中に正しい Add-on レスポンス形式が書かれていた:

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

副産物もあった。Cloud Run MCP を入れたことで、`deploy-local-folder`（ローカルフォルダを直接デプロイ）と `get-service-log`（ログ取得）が使えるようになり、調査からデプロイまで Antigravity のチャット内で完結するようになった。

:::message
**後日談**: この記事の公開準備中に firebase-tools がアップデートされ、`developerknowledge_search_documents` が `invalid argument` を返すようになった。現在は REST API 直接利用に移行している。
:::

---

## 今後の展望

Public Preview の段階なので、GA（正式リリース）時には以下が[公式ブログで予告](https://developers.googleblog.com/introducing-the-developer-knowledge-api-and-mcp-server/)されている:

- 構造化コンテンツ（コードサンプル、API リファレンス）のサポート追加
- コーパスの拡大（より多くの Google 開発者ドキュメント）
- 再インデックスのレイテンシ改善

Public Preview 中は無料。GA 後の料金体系は未発表（最新情報は[公式ブログ](https://developers.googleblog.com/introducing-the-developer-knowledge-api-and-mcp-server/)を確認してほしい）。

---

## まとめ

1. **Google のドキュメント検索は Developer Knowledge API が本命** — llms.txt は Google のドメイン分散に対応できない。Developer Knowledge API なら 11+ ドメインを横断検索できる
2. **REST API 直接利用が最も確実** — API キーさえあれば動く。MCP 経由は環境によって接続トラブルが起きやすい（2026年3月時点）
3. **0 件が返ったらクエリではなく設定を疑う** — 筆者の検証ではどんなクエリでもほぼ 5 件返った。0 件の原因は API キー・プロジェクト設定・レスポンスのパースミスのいずれか
4. **MCP が繋がらないときはサーバーとクライアントを切り分ける** — MCP プロトコルを直接叩いてサーバー側を検証すれば、設定ファイル違いや型の非対応に振り回されずに済む

---

## 参考リンク

- [公式ブログ: Introducing the Developer Knowledge API and MCP Server](https://developers.googleblog.com/introducing-the-developer-knowledge-api-and-mcp-server/)
- [MCP Server セットアップドキュメント](https://developers.google.com/knowledge/mcp)
- [API リファレンス](https://developers.google.com/knowledge/api)
- [コーパスリファレンス](https://developers.google.com/knowledge/reference/corpus-reference)
