---
title: "GCPプロジェクトとAPIキーの作り方：AIツール連携の第一歩"
emoji: "🔑"
type: "tech"
topics: ["google", "gcp", "ai", "gemini", "mcp"]
published: false
---

:::message
この記事の情報は **2026 年 3 月時点** のものである。GCP のコマンドや画面は変更される可能性があるため、最新情報は各セクションの公式リンクを参照してほしい。
:::

## この記事でわかること

Antigravity や Claude Code、Cursor で Google の API（Developer Knowledge API、Cloud Run MCP など）を使いたい。でも GCP のプロジェクト作成や API キー発行の手順がわからない。

僕がまさにそうだった。gcloud CLI は入っていたが、「プロジェクトを自分で作る」という発想がなかった。AI Studio が自動生成した `gen-lang-client-*` プロジェクトをそのまま使い、403 エラーで半日潰した。

この記事では **Developer Knowledge API** を具体例にして、GCP プロジェクト作成から API キー発行までを一通り解説する。手順自体は他の Google API でも同じなので、一度覚えれば使い回せる。

:::message
Developer Knowledge API の MCP 設定や実際の使い方は、こちらの記事で詳しく書いた。
[llms.txtでは足りなかった — Google Developer Knowledge APIにたどり着いた話](google-developer-knowledge-api-mcp)
:::

---

## 前提条件

| 必要なもの | 備考 |
|-----------|------|
| Google アカウント | 個人の `@gmail.com` を推奨。Workspace アカウントは組織の管理者ポリシーで API 作成が制限されていることがある |
| gcloud CLI | Google Cloud の操作をターミナルから行うためのツール |
| gcloud CLI でログイン済み | `gcloud auth login` を実行してブラウザ認証を済ませておく |

gcloud CLI のインストールがまだの場合は、公式の手順に従ってほしい。OS ごとにインストーラーが用意されている。

:::message
**公式ドキュメント**
- [English: Install the gcloud CLI](https://cloud.google.com/sdk/docs/install)
:::

---

## GCP プロジェクトとは

Google Cloud のリソースはすべて「プロジェクト」単位で管理される。API を有効にするのも、API キーを発行するのも、プロジェクトに対して行う操作だ。

逆に言うと、**プロジェクトがなければ何も始まらない**。API キーは特定のプロジェクトに紐づいて発行されるので、「どのプロジェクトで作ったか」が後々まで響いてくる。

ここで1つ、強く言いたいことがある。AI Studio（aistudio.google.com）が裏で自動生成する `gen-lang-client-*` というプロジェクトは**使わないほうがいい**。僕はこれに痛い目に遭った。3つ試してすべて「削除済み」か「API 無効」。自分で作ったプロジェクトを使う、これだけで不毛なエラーの大半が消える。

:::message
**公式ドキュメント**
- [English: Creating and managing projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
- [日本語: プロジェクトの作成と管理](https://cloud.google.com/resource-manager/docs/creating-managing-projects?hl=ja)
:::

---

## プロジェクトを作成する

### ブラウザ（Google Cloud Console）で作る場合

1. [console.cloud.google.com](https://console.cloud.google.com) にアクセス
2. 画面上部のプロジェクト選択ドロップダウンをクリック
3. 「新しいプロジェクト」を選択
4. プロジェクト名を入力して「作成」

プロジェクト ID は後から変更できない。`my-ai-tools` のように用途がわかる名前にしておくと管理が楽になる。

### gcloud CLI で作る場合

```bash
gcloud projects create my-ai-tools --name="AI Tools"
```

| 部分 | 意味 |
|------|------|
| `gcloud projects create` | GCP プロジェクトを新規作成するコマンド |
| `my-ai-tools` | プロジェクト ID。グローバルで一意である必要がある（他の誰かが同じ ID を使っていると作成できない） |
| `--name="AI Tools"` | 管理画面に表示されるプロジェクト名。ID と違って自由に付けられる |

作成したら、このプロジェクトをデフォルトに設定しておく。

```bash
gcloud config set project my-ai-tools
```

こうしておくと、以降のコマンドで `--project=my-ai-tools` を毎回指定しなくて済む。

実行結果の例:

```
Updated property [core/project].
```

---

## API を有効化する

プロジェクトを作っただけでは、まだ API は使えない。使いたい API を個別に「有効化」する必要がある。

Developer Knowledge API を例にする。

```bash
gcloud services enable developerknowledge.googleapis.com --project=my-ai-tools
```

| 部分 | 意味 |
|------|------|
| `gcloud services enable` | 指定した API を有効化するコマンド |
| `developerknowledge.googleapis.com` | 有効化したい API のサービス名。API ごとに決まっている |
| `--project=my-ai-tools` | どのプロジェクトで有効化するか。`gcloud config set project` 済みなら省略可 |

実行結果の例:

```
Operation "operations/acat.p2-123456789-abcdef" finished successfully.
```

:::message
API 有効化直後は、Google Cloud Console の「Select APIs」リストに表示されないことがある。焦らず数分待てば反映される。
参考: [G-gen Tech Blog: Developer Knowledge API の利用手順](https://blog.g-gen.co.jp/entry/using-developer-knowledge-api-via-mcp)
:::

### 他の API の場合

サービス名が違うだけで手順は同じだ。

```bash
# Cloud Run Admin API の場合
gcloud services enable run.googleapis.com --project=my-ai-tools

# Gemini API の場合
gcloud services enable generativelanguage.googleapis.com --project=my-ai-tools
```

:::message
**公式ドキュメント**
- [English: Listing and enabling services](https://cloud.google.com/service-usage/docs/list-services)
- [日本語: サービスの一覧表示と有効化](https://cloud.google.com/service-usage/docs/list-services?hl=ja)
:::

---

## MCP Server を有効化する

MCP 経由で API を使う場合（Claude Code や Cursor から接続するケース）、API の有効化とは別に **MCP Server の有効化** が必要になる。

```bash
gcloud beta services mcp enable developerknowledge.googleapis.com --project=my-ai-tools
```

| 部分 | 意味 |
|------|------|
| `gcloud beta` | まだ正式リリースされていないベータ版コマンドを使う宣言 |
| `services mcp enable` | 指定した API の MCP Server を有効化する |
| `developerknowledge.googleapis.com` | MCP Server を有効化する対象の API |

実行結果の例:

```
Operation "operations/mcp.p2-123456789-abcdef" finished successfully.
```

:::message
`gcloud beta` コマンドが `unknown command` で失敗する場合、ベータコンポーネントが古い可能性がある。

```bash
gcloud components update beta
```

これでベータコンポーネントが最新版に更新される。
:::

:::message
2026年3月17日以降、MCP 有効化コマンドは不要になる予定。API 有効化だけで MCP Server も自動的に使えるようになる見込みだ。
参考: [DevelopersIO: Developer Knowledge API MCP Server のセットアップ](https://dev.classmethod.jp/articles/setup-google-developer-knowledge-api-mcp-server-claude-code/)
:::

---

## API キーを作成する

ここまでで「プロジェクト作成 → API 有効化 → MCP 有効化」が完了した。最後に API キーを発行する。

```bash
gcloud services api-keys create --project=my-ai-tools \
  --display-name="DK API Key" \
  --api-target=service=developerknowledge.googleapis.com
```

| 部分 | 意味 |
|------|------|
| `gcloud services api-keys create` | API キーを新規作成するコマンド |
| `--project=my-ai-tools` | キーを作成するプロジェクト。**API を有効化したプロジェクトと必ず同じにする** |
| `--display-name="DK API Key"` | キーの表示名。Google Cloud Console で管理するとき、どのキーか識別するための名前 |
| `--api-target=service=developerknowledge.googleapis.com` | このキーで呼び出せる API を制限する。セキュリティ上、制限をかけておくのが鉄則 |

実行結果の例:

```
Operation [operations/akmf.p12-123456789-abcdef] complete. Result: {
  "createTime": "2026-03-01T12:00:00.000000Z",
  "displayName": "DK API Key",
  "etag": "...",
  "keyString": "AIzaSy...(ここが実際のAPIキー)...",
  "name": "projects/123456789/locations/global/keys/abcdef-1234",
  "restrictions": {
    "apiTargets": [{"service": "developerknowledge.googleapis.com"}]
  },
  "uid": "..."
}
```

`keyString` の値が、MCP 設定や環境変数に入れる API キーだ。この値は**一度しか表示されない**ので、すぐにコピーして安全な場所に保存する。

:::message
**公式ドキュメント**
- [English: Create and manage API keys](https://cloud.google.com/docs/authentication/api-keys)
- [日本語: API キーの作成と管理](https://cloud.google.com/docs/authentication/api-keys?hl=ja)
:::

---

## API キーの管理

API キーをソースコードにハードコードするのは絶対にやめたほうがいい。GitHub にうっかり push して、数時間で不正利用されたという話は珍しくない。

### 環境変数で管理する

`.env` ファイルを作成して、そこに API キーを書く。

```bash
# .env
GOOGLE_DK_API_KEY=AIzaSy...
```

`.gitignore` に `.env` を追加して、Git で追跡されないようにする。

```bash
# .gitignore
.env
```

### Google Cloud Console でキーの制限を確認する

[Google Cloud Console の認証情報ページ](https://console.cloud.google.com/apis/credentials) で、作成した API キーの制限を確認できる。

| 制限の種類 | 内容 |
|-----------|------|
| API の制限 | このキーで呼び出せる API を限定する（`--api-target` で設定済み） |
| アプリケーションの制限 | IP アドレスやリファラーで利用元を限定する |

個人利用なら API の制限だけで十分だろう。本番サービスで使う場合は IP アドレス制限もかけておくと安心だ。

---

## ハマりポイント

僕が実際に踏んだ地雷と、調べていて「これはハマるだろうな」と感じたものをまとめた。

### 1. gen-lang-client-* プロジェクトは使えない

AI Studio が自動で作る `gen-lang-client-*` プロジェクト。存在はしているが、削除済みだったり API が無効だったりで、まともに使えないことが多い。

僕の場合、3つ試して全滅だった。

```
gen-lang-client-XXXXXXXXXX → "Project has been deleted"
gen-lang-client-YYYYYYYYYY → "Project has been deleted"
gen-lang-client-ZZZZZZZZZZ → "Service Usage API has not been used in project..."
```

自分でプロジェクトを作る。それだけの話なのに、ここに気づくまでが長かった。

### 2. API キーのプロジェクトミスマッチ

API キーを作ったプロジェクトと、API を有効化したプロジェクトが違うと `API_KEY_SERVICE_BLOCKED`（403）になる。

原因がわかれば「そりゃそうだ」なのだが、エラーメッセージからは読み取りにくい。

```
PERMISSION_DENIED: API_KEY_SERVICE_BLOCKED
```

対処は単純で、**同じプロジェクトで API 有効化と API キー作成の両方を行う**。コマンドの `--project=` を確認するだけだ。

### 3. gcloud beta が古い

`gcloud beta services mcp enable` を実行したら `unknown command "mcp"` と言われた場合、gcloud のベータコンポーネントが古い。

```bash
gcloud components update beta
```

これで更新される。

### 4. API 有効化直後のタイムラグ

API を有効化した直後に Google Cloud Console の「有効な API とサービス」を見ても、リストに反映されていないことがある。コマンドで有効化が成功しているなら問題ない。数分待てば表示される。

（僕はこれで「有効化できてない？」と不安になって、もう一度コマンドを叩いた。結果はもちろん「すでに有効」。）

### 5. 課金の心配

Developer Knowledge API は 2026 年 3 月時点で **Public Preview（無料）** だ。課金設定なしで使える。

ただし、GA（一般提供）に移行した段階で有料になる可能性はある。Google Cloud の「無料」には種類があるので、気になる方はこちらの記事で整理した。
[Google Cloud の「無料」は3種類ある：無料トライアル・無料枠・有料アカウントの違い](google-cloud-console-basics)

---

## まとめ

| 手順 | コマンド |
|------|---------|
| プロジェクト作成 | `gcloud projects create my-ai-tools --name="AI Tools"` |
| デフォルトプロジェクト設定 | `gcloud config set project my-ai-tools` |
| API 有効化 | `gcloud services enable developerknowledge.googleapis.com` |
| MCP Server 有効化 | `gcloud beta services mcp enable developerknowledge.googleapis.com` |
| API キー作成 | `gcloud services api-keys create --display-name="DK API Key" --api-target=service=developerknowledge.googleapis.com` |

覚えておくべきことは3つだけ。

1. **プロジェクトは自分で作る**。AI Studio の自動生成プロジェクトには頼らない
2. **API 有効化と API キー作成は同じプロジェクトで**。ミスマッチすると 403
3. **API キーはコードに書かない**。`.env` に入れて `.gitignore` で除外

---

## 関連記事

- [llms.txtでは足りなかった — Google Developer Knowledge APIにたどり着いた話](google-developer-knowledge-api-mcp)
- [Google Cloud の「無料」は3種類ある：無料トライアル・無料枠・有料アカウントの違い](google-cloud-console-basics)

## 参考リンク

:::message
Google Cloud の公式ドキュメントは、URL の末尾に `?hl=ja` を付けると日本語で表示できる。英語ページが表示された場合は試してほしい。
:::

- [gcloud CLI インストール](https://cloud.google.com/sdk/docs/install)
- [プロジェクトの作成と管理](https://cloud.google.com/resource-manager/docs/creating-managing-projects)
- [サービスの一覧表示と有効化](https://cloud.google.com/service-usage/docs/list-services)
- [API キーの作成と管理](https://cloud.google.com/docs/authentication/api-keys)
- [Developer Knowledge API](https://developers.google.com/knowledge/api)
- [Developer Knowledge MCP Server](https://developers.google.com/knowledge/mcp)
- [G-gen Tech Blog: Developer Knowledge API の利用手順](https://blog.g-gen.co.jp/entry/using-developer-knowledge-api-via-mcp)
- [DevelopersIO: Developer Knowledge API MCP Server のセットアップ](https://dev.classmethod.jp/articles/setup-google-developer-knowledge-api-mcp-server-claude-code/)
