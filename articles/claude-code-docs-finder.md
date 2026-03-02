---
title: "Claude Codeのllms.txtを使って公式ドキュメント検索UIを作った話"
emoji: "🔍"
type: "tech"
topics: ["claudecode", "ai", "個人開発", "claude", "llm"]
published: true
---

Claude Code の公式ドキュメント、**どのページに何が書いてあるか分からない問題**を解決するために、`llms.txt` を使った検索UIをHTMLファイル1つで作った。Claudeに「こう直して」と伝えるだけで、コードは全部AIが書いている。

:::message
**必要なもの**: Claude Pro / Max / Team のいずれかのプラン
**技術レベル**: claude.aiでチャットできればOK
:::

## 使い方（PCのみ）

:::message alert
**スマホでは動きません。** モバイルアプリのArtifact環境はAPIリクエストの中継方式がPC版と異なるため、`Invalid response format` エラーになります。詳しくは [ウェブアプリとして配布しようとした](#ウェブアプリとして配布しようとした) で解説しています。
:::

1. [GitHubリポジトリ](https://github.com/Sora-bluesky/claude-code-docs-finder) を開く
2. `claude-code-docs-search.html` をクリック → 右上の「Download raw file」ボタンでダウンロード
3. PCブラウザで [claude.ai](https://claude.ai) を開く
4. チャット欄にダウンロードしたHTMLファイルを添付して「このHTMLをArtifactとして開いて」と送信（Artifactとは、claude.ai上でHTMLを実行できる機能のこと）
5. Artifactが表示されたら、検索ボックスに日本語で質問を入力

実際に「エージェントチーム」で検索した様子がこちら。

![Claude Code Docs Finder の動作デモ](/images/claude-code-docs-finder-demo.gif)

約20秒で関連ページが3枚のカードで表示される。各カードには日本語の説明文と関連度ラベル（高・中・低）がついていて、クリックすると公式ドキュメントの日本語ページに直接飛べる。

:::message
**「20秒は遅い」と思った方へ**: 時間がかかるのは、AIが毎回 `web_search` で llms.txt を取得しているため。体感速度を改善したいなら、llms.txt の内容をプロンプトに直接埋め込む（[静的版](#まず静的版を作る)のアプローチに戻す）のが最も効果的で、`web_search` の往復がなくなるぶん5秒前後まで短縮できる。ただし新ページの自動反映は諦めることになる。
:::

:::message
**検証環境**: Windows 11 / Chrome / claude.ai（PC）
**検証日**: 2026年3月
:::

---

ここからは、この検索UIをどうやって作ったかの記録。

## 目次

- [きっかけ](#きっかけ) — ドキュメント迷子になった話
- [llms.txt とは？](#llms.txt-とは？) — AIが読めるサイトマップ
- [全体アーキテクチャ](#全体アーキテクチャ) — 仕組みの全体像
- [まず静的版を作る](#まず静的版を作る) — ハードコードで動かす
- [リアルタイム取得に変更](#llms.txt-をリアルタイム取得に変更) — 最新ページを自動反映
- [ヒットしないページ問題](#「llms.txtにないページがヒットしない」問題) — llms.txtの穴と存在しないURL生成
- [タイトル表示の試行錯誤](#タイトル表示の試行錯誤) — 翻訳の揺れとの戦い
- [ウェブアプリとして配布しようとした](#ウェブアプリとして配布しようとした) — APIキー問題に気づく
- [AIへのプロンプト設計](#aiへのプロンプト設計) — 検索精度を左右する工夫
- [コード全体](#コード全体) — HTML1ファイルの構成
- [まとめ](#まとめ)
- [llms.txt の他の活用アイデア](#llms.txt-の他の活用アイデア)

人間がやったのは「こういう問題がある」「こう直して」と伝えることだけで、コードはすべてClaudeが書いている。

## きっかけ

Claude Code を使っていて、こんな経験はありませんか？

- 「MCP の設定をしたいけど、どのページを見ればいいの？」
- 「エージェントチームって何？どこに書いてある？」

公式ドキュメントはちゃんと整備されているのに、**どのページに何が書いてあるか把握しづらい**。

そんなモヤモヤを抱えていたある日、買い物中にふと「ドキュメントを横断検索できるツールを作れないか」と思いついた。その場でスマホのclaude.aiアプリを開いて聞いてみたところ、Claude Code が `llms.txt` という全ページインデックスを公開していることを教えてくれた。

```
https://code.claude.com/docs/llms.txt
```

**このURLをClaudeに渡すだけで、全ページを把握した上で質問に答えてくれる。**

スマホで調査を始めて、そのままclaude.ai上で「日本語で質問したら関連ページを教えてくれる検索UI」を作ろうと思い立った。Claude Codeではなくclaude.aiスタートだったのは、単純にスマホがきっかけだったからだ。

## llms.txt とは？

AIがドキュメントを効率よく読めるよう、**「このサイトにあるページの一覧」をまとめたファイル**だ。

```
# Claude Code Docs

## Docs

- [Claude Code overview](https://code.claude.com/docs/en/overview.md): Learn about Claude Code...
- [Connect Claude Code to tools via MCP](https://code.claude.com/docs/en/mcp.md): Learn how to connect...
- [Subagents](https://code.claude.com/docs/en/sub-agents.md): Create and use specialized AI subagents...
```

サイトマップのAI版、と思うとわかりやすい。

| 従来 | llms.txt |
|------|----------|
| サイトをクロールして全ページ発見 | 1行書くだけで全ページ一覧を取得 |
| 時間・コストがかかる | 即座・効率的 |

## 全体アーキテクチャ

```
ユーザーがclaude.ai上で日本語の質問を入力
        ↓
Artifact（claude.ai上のHTML実行環境）内のJavaScriptがClaude APIにリクエスト
（claude.aiが認証を代行するのでAPIキー不要）
        ↓
AIが web_search で llms.txt を取得
（毎回リアルタイムで最新ページ一覧を把握）
        ↓
最も関連性の高いページを3〜5件選定
        ↓
URL・説明文・関連度ラベルをJSON形式（プログラムが読めるデータ形式）で返す
        ↓
カード形式でUIに表示 → クリックで日本語ページへ
```

ポイントは、**ページ一覧をHTMLに直書きせず、毎回 llms.txt からリアルタイムで取得する**設計にしたこと。Anthropicが新しいページを追加しても自動で検索対象に入る。

## まず静的版を作る

最初のバージョンはシンプルで、llms.txt の内容をHTMLに直接コピーしてAIに渡す静的な実装だった。

```javascript
// 最初のアプローチ（静的）
const DOCS = [
  { title: "Claude Code overview", url: "...", desc: "..." },
  { title: "Connect Claude Code to tools via MCP", url: "...", desc: "..." },
  // 46ページ分をハードコード
];

const prompt = `以下のページ一覧から質問に関連するものを選んでください：
${DOCS.map(d => `${d.title}: ${d.desc}`).join('\n')}

質問: ${q}`;
```

これで動くには動く。ただ、すぐに問題に気づいた。

**HTMLを作った時点のページ一覧しか検索できない。**

## llms.txt をリアルタイム取得に変更

「新しいページが増えても自動で検索対象になるようにしたい」とClaudeに伝えたら、こういう設計を提案してきた。

```javascript
// リアルタイム取得版
const prompt = `まず web_search ツールを使って
https://code.claude.com/docs/llms.txt を取得し、
最新のページ一覧を把握してください。

その上で、以下の質問に関連するページを3〜5件選んでください：
「${q}」`;

const res = await fetch("https://api.anthropic.com/v1/messages", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 2000,
    tools: [{ type: "web_search_20250305", name: "web_search" }],
    messages: [{ role: "user", content: prompt }]
  })
});
```

`web_search` はAnthropicが提供するツール機能の一つで、AIにWeb上のURLを取得させることができる。プロンプトに「このURLを取得して」と書くだけで、AI側が自動的にアクセスしてくれる仕組みだ。

これで**AIがサーバー側から llms.txt を取得 → その内容をもとに検索**という流れが実現できた。

:::message
ブラウザのJavaScriptから直接 `code.claude.com` を fetch しようとすると403エラーになる（CORS制限: ブラウザが他サイトのデータを勝手に取れないようにするセキュリティの仕組み）。AIの `web_search` 経由ならサーバー側で取得するので問題ない。
:::

## 「llms.txtにないページがヒットしない」問題

リアルタイム取得版で試していたら、別の問題が出てきた。

```
検索ワード: エージェントチーム
↓
https://code.claude.com/docs/ja/agent-teams がヒットしない
```

原因を調査すると、**`agent-teams` は llms.txt に載っていなかった**。

```
# llms.txt の内容（抜粋）
- Subagents: ...
- Agent Skills: ...
# ← agent-teams は存在しない
```

llms.txt の更新が追いついていないページが一部あったらしい。

対策として、AIへのプロンプトに「llms.txtに載っていないページも積極的に含めること」と追記してみる。AIが自身の知識で補完してくれるようになった。

ところが今度は、**AIが存在しないURLを勝手に生成する**という別の問題が発生（`troubleshooting-guide` というページが実際には存在しなかった、など）。一つ穴を塞ぐと別の穴が開く。

最終的には「llms.txtにあるURLのみを返すこと」と厳命しつつ、llms.txt 自体を常に最新化するアプローチに落ち着いた。

## タイトル表示の試行錯誤

カードのタイトル表示でもハマった。

llms.txt のタイトルは英語なので、AIに日本語翻訳を指示したところ：

- llms.txt：`Claude Code sessions with agent teams`
- AIが返したタイトル：`Claude Codeセッションのチームを調整する`（スペース抜け）

翻訳の揺れが出てしまう。

次に「実際のページをfetchしてタイトルを取得する」方式を試したが、ページ数分のAPIコールが発生して**体感で2〜3倍遅くなった**。

結局「URLをそのままタイトル欄に表示する」というシンプルな解決策に落ち着いた。

```
code.claude.com/docs/ja/agent-teams  ← これがそのままタイトルに
```

URL自体がページの内容を表しているので、慣れればむしろわかりやすい。

## ウェブアプリとして配布しようとした

スマホでの調査から始まり、そのままclaude.ai上で開発・テストしてきて、検索UIはいい感じに仕上がった。次に考えたのは「これをウェブアプリとして公開して、誰でもブラウザで使えるようにしたい」ということだ。

ところが、調べてみると**それは簡単ではなかった**。

### なぜAPIキーが必要なのか

このHTMLの中身は、Claudeに「llms.txtを取得して、質問に合うページを選んで」とリクエストを投げている。llms.txtの一覧を表示してブラウザのCtrl+Fで検索するだけなら、AIは要らない。しかしそれでは「エージェントチームについて知りたい」と入力して `agent-teams` のページが出てくる、という**意味を理解した検索**ができない。

意味検索をするにはAIを呼ぶ必要がある。AIを呼ぶにはAPI認証が要る。ブラウザから直接 `api.anthropic.com` にリクエストを投げるには **APIキー（従量課金）が必須**だ。

### なぜ開発中に気づかなかったか

最初からclaude.ai上でArtifact（HTML実行環境）として作っていたからだ。claude.aiのArtifactは、APIリクエストをclaude.ai本体が中継してくれる。ユーザーのセッション認証が使われるため、コード上にAPIキーを書く必要がない。

開発中はずっとこの環境で動かしていたので、「これってAPIキーなしで動いてるんだ」と錯覚していた。HTMLをダウンロードしてブラウザで直接開こうとして初めて、認証エラーで動かないことに気づいた。

### 結論: claude.aiのArtifactとして配布する

| 方式 | APIキー | 意味検索 | 誰でも使えるか |
|------|---------|---------|--------------|
| llms.txt一覧 + Ctrl+F | 不要 | できない | Yes |
| ブラウザ単体で開く | 必要（従量課金） | できる | No |
| **claude.ai の Artifact** | **不要**（サブスクに含まれる） | **できる** | **Claude有料プランならOK** |

「誰でもブラウザで開ける」は実現できなかったが、Claude Pro / Max / Team ユーザーなら、claude.aiを開いてHTMLを渡すだけで使える。追加費用もかからない。

### もう一つの落とし穴: スマホでは動かない

Artifactで動くなら当然スマホでも使えるだろう、と思っていた。ところがスマホのClaude.aiアプリで試すと `Invalid response format` エラーが出る。正直がっくりきた。

PCのclaude.ai（ブラウザ版）では問題なく動く。同じHTMLなのに、だ。

原因は **モバイルアプリのArtifact環境が、API応答を中継する方式がPC版と異なる**こと。PC版のclaude.aiはブラウザ上でArtifactのHTMLを実行し、`fetch("https://api.anthropic.com/...")` を本体が透過的に中継する。一方、モバイルアプリはネイティブのWebView内でHTMLを実行しており、APIリクエストの中継経路が違う。レスポンスの形式が変わってしまい、JavaScriptのJSONパースで失敗する。

ダークモード対応、APIバージョンヘッダーの追加、エラーハンドリングの強化など手を尽くしたが、アプリ側の中継方式の問題なのでHTML側では解決できなかった。

**「Artifactで動く＝どのデバイスでも動く」ではない。** PC版とモバイル版はArtifactの実行環境が別物だ、という教訓がここにもあった。

## AIへのプロンプト設計

検索精度を左右するのがAIへのプロンプト。最終的にこういう構造になっている。

```javascript
const prompt = `あなたはClaude Codeの公式ドキュメントナビゲーターです。

まず web_search ツールを使って
https://code.claude.com/docs/llms.txt を取得し、
最新のページ一覧を把握してください。

ユーザーの質問: 「${q}」

返答フォーマット（JSONのみ）:
{
  "results": [
    {
      "url": "https://code.claude.com/docs/ja/ページパス",
      "desc": "初めてClaude Codeを使う人にも伝わるように日本語で2〜3文で説明",
      "relevance": "high" | "mid" | "low",
      "reason": "この質問に対してどう役立つか50文字以内で"
    }
  ]
}

注意:
- URLは必ず /en/ を /ja/ に変換すること
- llms.txtに記載されているページのみを返すこと`;
```

ポイントは：

| 工夫 | 理由 |
|------|------|
| 「JSONのみで返答」と明記 | パース失敗を防ぐ |
| `/en/` → `/ja/` の変換を指示 | 日本語ページへ誘導 |
| llms.txt以外のURL禁止 | 存在しないURLを生成させない |
| descは「初めての人にも伝わる文章で」 | 専門用語だらけの説明を防ぐ |

## コード全体

HTMLファイル1つで完結する。コード全体はGitHubで公開している。

:::message
**[→ GitHubでコードを見る](https://github.com/Sora-bluesky/claude-code-docs-finder)**
:::

主要な部分だけ抜粋するとこうなる。

**HTML構造（検索ボックス＋カード表示）**

```html
<div class="search-wrap">
  <input type="text" id="query" placeholder="例：MCP サーバーの設定方法を知りたい" />
  <button id="searchBtn">↑</button>
</div>
<div id="results"></div>
```

**API呼び出し部分（JavaScript）**

```javascript
const res = await fetch("https://api.anthropic.com/v1/messages", {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 2000,
    tools: [{ type: "web_search_20250305", name: "web_search" }],
    messages: [{ role: "user", content: prompt }]
  })
});
```

:::message
認証ヘッダー（`x-api-key`）がないことに気づいたかもしれない。claude.aiのArtifact内ではclaude.aiが認証を代行するため、コード上でAPIキーを指定する必要がない。逆に言えば、このHTMLをブラウザで直接開いても動かない理由がこれだ。
:::

**tool_useの処理**: claude.aiのArtifact環境では、`web_search` の応答が2回に分かれるケースがある。1回目で「Web検索したい」と返ってくるので、結果を受け取って2回目のリクエストで最終回答を得る。

:::message
公式APIでは `web_search` はサーバー側で自動実行される（server tool）ため、クライアントで tool_result を返す必要はない。以下はclaude.aiのArtifact環境で必要だった処理。
:::

```javascript
if (data.stop_reason === 'tool_use') {
  const toolResults = data.content
    .filter(b => b.type === 'tool_use')
    .map(b => ({ type: 'tool_result', tool_use_id: b.id, content: '' }));
  // 2回目のコールで最終レスポンスを取得
  const res2 = await fetch("https://api.anthropic.com/v1/messages", { ... });
}
```

## まとめ

llms.txt の存在を知ったところから始まり、claude.ai上でClaudeと一緒に検索UIを作り上げた。静的版 → リアルタイム取得 → タイトル表示の工夫と、問題が出るたびに「こう直して」と伝えるだけでコードが直っていく。

ウェブアプリとして配布しようとしたとき、初めて**意味検索にはAPIキーが必要**だと気づいた。claude.ai上で開発していたから、認証の問題が見えなかった。結果的にclaude.aiのArtifactとして使う形に落ち着いたが、「開発環境と配布環境の違い」は、AIと作るからこそハマるポイントかもしれない。

振り返ると、自分がやったのは「この問題をどうにかしたい」「こう直して」とClaudeに伝えることだけだ。コードは全部AIが書いて、自分は動かして問題を見つけるだけ。**雑に動かして壊れたところを直す**サイクルが、AIとの開発では自然に回る。

## llms.txt の他の活用アイデア

今回は検索UIを作ったが、llms.txt の使い道は他にもある。

たとえば、プロジェクトの `CLAUDE.md` に以下のように書いておくと、Claude Code が作業中に必要なドキュメントを自分で探して参照してくれる。

```markdown
## 参照ドキュメント

Claude Code の最新ドキュメント一覧:
https://code.claude.com/docs/llms.txt

新しい機能について不明な点があれば、上記から該当ページを探して参照すること。
```

他にもこんな使い方ができる。

| 活用例 | 概要 |
|--------|------|
| **CLAUDE.md に記載** | Claude Code 自身に最新ドキュメントを常時参照させる |
| **他サービスのllms.txt** | 同じアプローチで他のドキュメントサイトの検索UIも作れる |

llms.txtを公開しているサービスなら、URLを差し替えるだけで同じ検索UIが作れる。

---

PS：
llms.txt は Claude Code 以外にも多くのサービスが提供している。[directory.llmstxt.cloud](https://directory.llmstxt.cloud) で800件以上が登録されており、Mintlify がホスティングする全ドキュメントサイトへの一括展開をきっかけに急速に普及した。

### llms.txtでは足りない — Google Developer Knowledge API

Googleは一部サービス（Gemini API・ADK・Chrome等）で llms.txt を提供しているが、Firebase・Cloud Run・Google Chat API などは404を返す。2026年2月、その理由がわかった。Googleの本命は **Developer Knowledge API + MCPサーバー**だ。1つのMCPサーバーを接続するだけで、11以上のGoogleドメインのドキュメントを横断検索できる。llms.txtを1つずつ探して回る必要がない。

僕も実際にこのMCPサーバーをセットアップしたが、設定ファイルの罠やAPIキーのプロジェクトミスマッチなど、けっこうハマった。セットアップ手順とハマりポイントは別記事にまとめている。

:::message
**[→ llms.txtでは足りなかった — Google Developer Knowledge APIにたどり着いた話](https://zenn.dev/sora_biz/articles/google-developer-knowledge-api-mcp)**
:::

### 主要サービスの llms.txt 一覧

| サービス | llms.txt URL |
|----------|-------------|
| Anthropic Claude | https://claude.com/llms.txt |
| Model Context Protocol | https://modelcontextprotocol.io/llms.txt |
| Cursor | https://cursor.com/llms.txt |
| Perplexity | https://docs.perplexity.ai/llms.txt |
| Cloudflare | https://developers.cloudflare.com/llms.txt |
| Vercel AI SDK | https://sdk.vercel.ai/llms.txt |
| Supabase | https://supabase.com/docs/llms.txt |

同じアプローチで、これらのドキュメントを対象にした検索UIも作れる。
