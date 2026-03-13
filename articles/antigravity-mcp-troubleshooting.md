---
title: "Google Antigravity MCPトラブルシューティング：繋がらない時の原因7パターン"
emoji: "🔧"
type: "tech"
topics: ["google", "gemini", "mcp", "ai", "vscode"]
published: false
---

## 結論: エラーメッセージで原因は9割わかる

Antigravity の MCP が繋がらないとき、画面に出ているエラーメッセージを読めば大体の原因は特定できる。この記事では、僕自身がハマったものとコミュニティで頻出しているものを合わせて 7 パターンに整理した。

「エラーメッセージ → 原因 → 解決策」の逆引きをすぐ見たい人は、記事末尾の[逆引き表](#逆引き表)に飛んでほしい。

---

## エラーパターン全体像

まず全体を俯瞰する。

| 分類 | エラー | 解決の方向 |
|:---|:---|:---|
| **クライアント側** | EOF（初期化失敗） | パス修正・環境分離 |
| | server name not found | 設定ファイル確認 |
| | server crashed | 再インストール |
| **サーバー側** | ECONNREFUSED | ポート・FW確認 |
| | API_KEY 403 | プロジェクト統一 |
| **仕様上の制限** | OAuth 非対応 | Firebase MCP 経由 |
| | WSL パス問題 | wsl コマンドチェーン |

---

## 各エラーパターン詳細

### 1. `Error: calling 'initialize': EOF`

```
Error: calling 'initialize': EOF
```

stdio タイプの MCP サーバーで初期化に失敗したときに出る。僕が最初に遭遇したのがこれだった。

**原因**: Windows 環境で stdout にキャリッジリターン（CR: `\r`）が混入し、JSON-RPC のパースが壊れる。Node.js のパスが通っていない、または相対パスで指定しているケースでも発生する。

**解決策**:

1. `command` にはフルパス（絶対パス）を指定する

```json
{
  "mcpServers": {
    "my-server": {
      "command": "C:\\Program Files\\nodejs\\node.exe",
      "args": ["C:\\path\\to\\server.js"],
      "transportType": "stdio"
    }
  }
}
```

2. `.env` や `.bashrc` で余計な `echo` が走っていないか確認する。stdout に MCP プロトコル以外の出力が混ざると即死する

3. 環境を分離する。nvm や volta を使っている場合、シェル初期化スクリプトが stdout に文字列を吐くことがある

:::message
**公式ドキュメント**
- [English: Google AI Developers Forum - MCP Tool Execution Error](https://discuss.ai.google.dev/t/error-during-mcp-tool-execution-in-antigravity/118162)
:::

---

### 2. `server name not found`

```
server name not found
```

MCP サーバーの名前が解決できない。地味だが一番ハマりやすいエラーだと思う。僕も Developer Knowledge API の接続で数時間溶かした。

**原因は 2 つある**:

**原因 A: 設定ファイルの場所が違う**

Gemini CLI と Antigravity で読み込む設定ファイルが違う。これを知らないと永遠に解決しない。

| ツール | 設定ファイル |
|--------|------------|
| Gemini CLI | `~/.gemini/settings.json` |
| Antigravity（VS Code 拡張） | `~/.gemini/antigravity/mcp_config.json` |

`settings.json` に書いても Antigravity は一切見ない。しかも `mcp_config.json` が空でもエラーは出ない。静かに「そんなサーバー知りません」と返してくる。

**原因 B: httpUrl 型が認識されない**

2026年3月時点で、Antigravity は `httpUrl` 型（HTTP リモートサーバー）の MCP Server を認識しない場合がある。`mcp_config.json` に正しく書いても無視される。

**解決策**:

- まず `~/.gemini/antigravity/mcp_config.json` を開いて、サーバー名のスペルミスがないか確認
- `httpUrl` 型で `server name not found` が出るなら、Firebase MCP 経由に切り替える。Firebase MCP には Developer Knowledge のツールが内蔵されている（詳しくは[関連記事](https://zenn.dev/sora_biz/articles/google-developer-knowledge-api-mcp)を参照）

---

### 3. `ECONNREFUSED 127.0.0.1:XXXX`

```
Error: connect ECONNREFUSED 127.0.0.1:3000
```

TCP 接続そのものが拒否されている。要するにサーバーが起動していないか、ポートが間違っている。シンプルな原因のわりに、設定ファイル側ばかり疑って遠回りしがち。

**まずやること**: サーバープロセスが本当に生きているか確認する。

```bash
# Windows（PowerShell）
Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue

# macOS / Linux
lsof -i :3000
```

何も返ってこなければサーバーは起動していない。次に確認するのはこの 2 つだ。

- ファイアウォールがブロックしていないか（Windows Defender Firewall で Node.js の通信を許可する）
- ポート番号が設定ファイルとサーバー起動コマンドで一致しているか

僕が一度やらかしたのは、別ターミナルでサーバーを起動した「つもり」になっていたケース。実際にはそのターミナルでエラーが出て即終了していた。ターミナルの出力、ちゃんと見よう。

:::message
**公式ドキュメント**
- [English: Google AI Developers Forum - Connection Error](https://discuss.ai.google.dev/t/client-antigravity-connection-to-server-is-erroring-shutting-down-server/121223)
:::

---

### 4. `Antigravity server crashed unexpectedly`

```
Antigravity server crashed unexpectedly
```

Antigravity 拡張機能の内部クラッシュ。Windows、macOS、Linux のすべてで報告されている。MCP の問題ではなく、拡張機能自体の問題。

**解決策**（上から順に試す）:

1. VS Code を完全に終了して再起動
2. Antigravity 拡張を無効化 → 有効化
3. それでもダメなら完全アンインストール → 再インストール

```bash
# VS Code の拡張機能キャッシュを削除（Windows）
rm -rf "$APPDATA/Code/User/globalStorage/google.antigravity"
```

4. 別の Google アカウントでログインしてみる（アカウント固有の問題を切り分けるため）

このエラーは再現条件が不安定で、「昨日まで動いてたのに今日ダメ」ということが普通にある。拡張機能のアップデート直後に起きやすい印象がある。

---

### 5. `API_KEY_SERVICE_BLOCKED` (403)

```json
{
  "error": {
    "code": 403,
    "message": "API_KEY_SERVICE_BLOCKED",
    "status": "PERMISSION_DENIED"
  }
}
```

僕がDeveloper Knowledge API で踏んだ地雷がまさにこれ。

**原因**: API キーを作成したプロジェクトと、API を有効化したプロジェクトが違う。AI Studio が自動生成する `gen-lang-client-*` プロジェクトのキーを流用すると大体ここでコケる。

**解決策**: 同じプロジェクトで API 有効化とキー作成の両方を行う。

```bash
# 1. 自分のプロジェクトで API を有効化
gcloud services enable developerknowledge.googleapis.com \
  --project=YOUR_PROJECT_ID

# 2. 同じプロジェクトで API キーを作成
gcloud services api-keys create --project=YOUR_PROJECT_ID \
  --display-name="DK API Key" \
  --api-target=service=developerknowledge.googleapis.com
```

`gen-lang-client-*` プロジェクトは削除済みか API 無効のことが多い。`gcloud projects list` で表示されていても使えるとは限らない。自分で作ったプロジェクトを使うのが安全だ。

---

### 6. OAuth 非対応（公式 Known Issue）

エラーメッセージが出ないパターンなので厄介だ。MCP のツール一覧は表示される。サーバーとの接続も成功している。なのに実行すると認証が通らない。「全部合ってるのに動かない」状態で、最初は自分の設定ミスだと思い込んで延々と設定を見直した。

結論から言うと、2026年3月時点で **Antigravity は MCP の OAuth 認証フローをサポートしていない**。これは Antigravity 固有の Known Issue で、Gemini CLI は OAuth を正式サポートしている。Google Cloud の公式 Known Issues にも明記されている。

OAuth を要求する MCP サーバーだと、ツール一覧の取得（`tools/list`）は通るのに実際のツール呼び出しで認証エラーになる。見た目上「接続成功」しているから余計にタチが悪い。

回避するには、OAuth を必要としない接続方式に切り替える。API キー認証か Firebase MCP 経由を使う。

:::message
**公式ドキュメント**
- [English: Google Cloud MCP Known Issues](https://docs.cloud.google.com/mcp/known-issues)
- ブラウザの翻訳機能で日本語に変換して読める
:::

---

### 7. WSL 環境でのパス問題

```
Error: spawn /home/user/.nvm/versions/node/v20.x.x/bin/npx ENOENT
```

WSL（Windows Subsystem for Linux）上の Node.js を使って MCP サーバーを起動しようとすると、Windows 側のアプリが Linux 形式のパスを解決できずに失敗する。

**原因**: VS Code は Windows プロセスとして動作する。`command` に Linux パスを書いても Windows は実行できない。

**解決策**: `command` を `wsl` にして、Linux 側のシェル初期化を含めたコマンドチェーンを構築する。

```json
{
  "mcpServers": {
    "my-server": {
      "command": "wsl",
      "args": [
        "bash", "-c",
        "source ~/.nvm/nvm.sh && npx -y @example/mcp-server"
      ],
      "transportType": "stdio"
    }
  }
}
```

ポイントは `source ~/.nvm/nvm.sh` を挟むこと。WSL の bash を非対話モードで起動すると `.bashrc` が読み込まれないため、nvm のパスが通らない。

---

## 切り分けの基本

MCP が繋がらないとき、「サーバーが悪いのかクライアントが悪いのか」を最初に切り分ける。これをやらずに設定ファイルをいじり回すと泥沼にハマる。僕がまさにそうだった。

### サーバー側の検証: MCP プロトコルを直接叩く

PowerShell で MCP の `initialize` メソッドを直接送信する。これでサーバーが正常に応答するか 3 分で確認できる。

**HTTP サーバーの場合**:

```powershell
$body = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{
  "protocolVersion":"2024-11-05",
  "capabilities":{},
  "clientInfo":{"name":"test","version":"1.0"}}}'

Invoke-RestMethod -Uri "https://your-mcp-server.example.com/mcp" `
  -Method POST -ContentType "application/json" `
  -Headers @{"X-Goog-Api-Key"="YOUR_API_KEY"} -Body $body
```

正常なら `protocolVersion` と `serverInfo` を含む JSON が返る。

```json
{
  "result": {
    "serverInfo": { "name": "StatelessServer", "version": "ESF" },
    "protocolVersion": "2024-11-05"
  }
}
```

これが返ってきたらサーバー側は正常。問題はクライアント（Antigravity）側にある。

**stdio サーバーの場合**:

```powershell
# サーバーを直接起動して JSON-RPC を送る
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | node C:\path\to\server.js
```

### クライアント側の確認チェックリスト

サーバーが正常なのに繋がらない場合、以下を順番に確認する。

| # | 確認項目 | 確認方法 |
|---|---------|---------|
| 1 | 設定ファイルの場所は正しいか | Antigravity は `~/.gemini/antigravity/mcp_config.json` |
| 2 | JSON の構文エラーはないか | VS Code でファイルを開き、赤い波線がないか確認 |
| 3 | VS Code を再起動したか | MCP 設定はセッション起動時にしか読み込まれない |
| 4 | transportType は対応しているか | `stdio` と `sse` は対応。`httpUrl` は認識されない場合あり |
| 5 | サーバー名のスペルミスはないか | `mcp_config.json` のキー名と呼び出し時の名前が一致しているか |

---

## 逆引き表

エラーメッセージから解決策をすぐ引けるようにまとめた。

| エラーメッセージ | 原因 | 解決策 |
|----------------|------|--------|
| `Error: calling 'initialize': EOF` | stdout への不正出力、パス未指定 | 絶対パス指定、echo 除去 |
| `server name not found` | 設定ファイル違い、httpUrl 非対応 | `mcp_config.json` 確認、Firebase MCP 経由 |
| `ECONNREFUSED 127.0.0.1:XXXX` | サーバー未起動、ポート不一致 | プロセス確認、FW 確認 |
| `server crashed unexpectedly` | 拡張機能の内部エラー | 再インストール、別アカウント |
| `API_KEY_SERVICE_BLOCKED` | プロジェクトミスマッチ | 同一プロジェクトで API 有効化 + キー作成 |
| ツール一覧は出るが認証失敗 | OAuth 非対応（Known Issue） | API キー認証 or Firebase MCP |
| `spawn ... ENOENT`（WSL） | Windows が Linux パスを解決できない | `wsl bash -c` コマンドチェーン |

---

## まとめ

MCP のトラブルシューティングで一番大事なのは、**サーバーとクライアントの切り分けを最初にやる**こと。PowerShell で `initialize` を直接叩けば、サーバー側の検証は 3 分で終わる。

僕の場合、設定ファイルの場所違い（`settings.json` vs `mcp_config.json`）で半日溶かした。Antigravity と Gemini CLI で設定ファイルが違うという情報は、公式ドキュメントを丁寧に読まないと気づけない。次に同じエラーに遭遇したら、この記事の逆引き表を開いて 30 秒で片をつけてほしい。

---

## 関連記事

Developer Knowledge API の セットアップ手順と、Firebase MCP 経由の具体的な接続方法は以下の記事で詳しく書いている。

https://zenn.dev/sora_biz/articles/google-developer-knowledge-api-mcp

---

## 参考リンク

:::message
**公式ドキュメント**
- [English: Google AI Developers Forum - MCP Tool Execution Error](https://discuss.ai.google.dev/t/error-during-mcp-tool-execution-in-antigravity/118162)
- [English: Google AI Developers Forum - Connection Error](https://discuss.ai.google.dev/t/client-antigravity-connection-to-server-is-erroring-shutting-down-server/121223)
- [English: Google Cloud MCP Known Issues](https://docs.cloud.google.com/mcp/known-issues)
- [English: Google Antigravity Docs](https://antigravity.google/docs)
- [English: Developer Knowledge API MCP Server](https://developers.google.com/knowledge/mcp)
- ブラウザの翻訳機能で日本語に変換して読める
:::

**コミュニティ記事**:
- [WSL環境でのMCPサーバー設定](https://qiita.com/daruma30610/items/b216265db7db28599663)
