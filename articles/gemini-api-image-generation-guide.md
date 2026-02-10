---
title: "その Gemini 画像、透かし入ってるよ？API画像生成の著作権・料金を公式情報で整理"
emoji: "🎨"
type: "tech"
topics: ["GeminiAPI", "GoogleCloud", "画像生成", "AI", "初心者"]
published: true
---

:::message
この記事の情報は **2026 年 2 月時点** のものである。モデル ID・料金・無料枠は変更される可能性があるため、最新情報は各セクションに記載した公式リンクを参照してほしい。
:::

## 目次

1. [この記事の結論](#この記事の結論)
2. [Gemini アプリと Gemini API は別物](#gemini-アプリと-gemini-api-は別物)
3. [画像生成に使えるモデル一覧](#画像生成に使えるモデル一覧)
4. [モデル比較 - Nano Banana / Nano Banana Pro / Imagen 4](#モデル比較---nano-banana--nano-banana-pro--imagen-4)
5. [料金の全体像](#料金の全体像)
6. [画像生成を試せる場所](#画像生成を試せる場所)
7. [生成画像の著作権と利用権](#生成画像の著作権と利用権)
8. [AI 生成画像の著作権に関する法的留意点](#ai-生成画像の著作権に関する法的留意点)
9. [まとめ](#まとめ)

## この記事の対象読者

- Gemini API で画像生成をしたいが、無料でできるのか有料なのか分からない人
- 「Gemini で画像作れるんでしょ？」と思っているが、アプリと API の違いが分からない人
- API で生成した画像の著作権や商用利用について知りたい人
- どのモデルを選べばいいか分からない人

## この記事の結論

| 知りたいこと | 答え |
|---|---|
| API で画像生成は無料でできる？ | **できない。** すべてのモデルで無料枠は "Not available" |
| Gemini アプリ（gemini.google.com）なら？ | **無料で可能**（日次制限あり）。ただし API とは別物 |
| 生成画像の著作権は？ | Google は所有権を主張しない。ただし独占権はない |
| 商用利用は？ | 規約上、禁止されていない |
| 透かしは入る？ | **全画像に SynthID が自動付与**（不可視） |

:::message
Google Cloud の課金全般について知りたい方は、こちらの記事をどうぞ。
👉 [Google Cloud、課金してるアカウントどれだっけ？確認→判断→解約の3ステップ](/articles/google-cloud-billing-check)
👉 [Google Cloud の「無料」は3種類ある：無料トライアル・無料枠・有料アカウントの違い](/articles/google-cloud-console-basics)
:::

---

## Gemini アプリと Gemini API は別物

まず最も混同しやすい点を整理する。

| | Gemini アプリ | Gemini API |
|---|---|---|
| **URL** | [gemini.google.com](https://gemini.google.com/) | [ai.google.dev](https://ai.google.dev/) |
| **使い方** | ブラウザやアプリで対話形式 | API キーを使ってプログラムから呼び出す |
| **画像生成の無料利用** | **可能**（日次制限あり） | **不可**（全モデル有料のみ） |
| **対象ユーザー** | 一般ユーザー | 開発者・ビジネス利用 |
| **課金体系** | Google One AI Premium 等のサブスクリプション | Google Cloud の従量課金 |

**「Gemini で画像が無料で作れた」という体験は、Gemini アプリ（gemini.google.com）での話である。** API 経由で同じことをするには、Google Cloud の有料課金が必要になる。

> 公式料金ページにて、すべての画像生成モデルの Free tier（無料枠） 列に "Not available" と明記されている。
> — 出典：[Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)

---

## 画像生成に使えるモデル一覧

Gemini API で画像生成に使えるモデルは、大きく **2 つのファミリー** に分かれる。

### Nano Banana ファミリー

**Gemini ネイティブモデル（Nano Banana ファミリー）。** テキスト生成と画像生成を 1 つのモデルで行える「マルチモーダルモデル」である。

| モデル ID | 通称 | 最大解像度 | 料金（1 画像あたり） |
|---|---|---|---|
| `gemini-2.5-flash-image` | **Nano Banana** | 1K（1024px） | $0.039 |
| `gemini-3-pro-image-preview` | **Nano Banana Pro** | 4K（4096px） | $0.134（1K/2K）、$0.24（4K） |

:::message
「Nano Banana」は、Google が LMSYS Chatbot Arena（AI モデルの性能をユーザー投票で比較するオープンプラットフォーム）に匿名で投稿した際のコードネームだった。Midjourney や Flux を上回る評価を受け、そのままブランド名として定着した。
:::

— 出典：[Image generation | Gemini API](https://ai.google.dev/gemini-api/docs/image-generation)、[Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)

### Imagen 4

**専用画像生成モデル。** テキストプロンプトから画像のみを生成する。**英語プロンプトのみ対応**。

| モデル ID | バリアント | 最大解像度 | 料金（1 画像あたり） |
|---|---|---|---|
| `imagen-4.0-fast-generate-001` | Fast | 1K | **$0.02**（最安） |
| `imagen-4.0-generate-001` | Standard | 2K | $0.04 |
| `imagen-4.0-ultra-generate-001` | Ultra | 2K | $0.06 |

— 出典：[Imagen | Gemini API](https://ai.google.dev/gemini-api/docs/imagen)、[Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)

:::message alert
**廃止予定に注意：** `gemini-2.5-flash-image` は 2026/10/02、Imagen 4 系は 2026/06/24 に廃止予定。`gemini-3-pro-image-preview` は現時点で廃止予定なし。最新の廃止スケジュールは [Deprecations](https://ai.google.dev/gemini-api/docs/deprecations) を確認してほしい。
:::

---

## モデル比較 - Nano Banana / Nano Banana Pro / Imagen 4

3 つのモデルファミリーの違いを比較する。

| 比較項目 | Nano Banana | Nano Banana Pro | Imagen 4 |
|---|---|---|---|
| **モデル ID** | `gemini-2.5-flash-image` | `gemini-3-pro-image-preview` | `imagen-4.0-*-generate-001` |
| **コンセプト** | 高速・低コスト | 高品質・プロ向け | 画像生成専用・最安 |
| **最大解像度** | 1K | **4K** | 2K（Fast は 1K のみ） |
| **料金（1 画像）** | $0.039 | $0.134〜$0.24 | **$0.02〜$0.06** |
| **思考モード** | 非対応 | **対応**（構図を推敲してから出力） | 非対応 |
| **Google 検索連携** | 非対応 | **対応**（リアルタイムデータに基づく生成） | 非対応 |
| **テキスト描画（文字入れ）** | 基本的 | **高度**（図表・メニュー向け） | 限定的（25 文字以下推奨） |
| **アスペクト比指定** | 対応（10 種類） | 対応（10 種類） | 対応（5 種類） |
| **多言語プロンプト** | 対応 | 対応 | **英語のみ** |
| **画像編集** | 対応 | 対応 | 非対応 |
| **リファレンス画像** | 対応 | 対応（最大 14 枚） | 非対応 |

### アスペクト比の指定方法

Midjourney の `--ar 16:9` のようにプロンプト内で指定する方式とは異なり、Gemini API では **API パラメータ（`imageConfig.aspectRatio`）で指定する**。プロンプトに「16:9 で」と書いても反映される保証はない。

**Nano Banana / Nano Banana Pro（10 種類）：**
`1:1` / `2:3` / `3:2` / `3:4` / `4:3` / `4:5` / `5:4` / `9:16` / `16:9` / `21:9`

**Imagen 4（5 種類）：**
`1:1` / `3:4` / `4:3` / `9:16` / `16:9`

— 出典：[Image generation | Gemini API](https://ai.google.dev/gemini-api/docs/image-generation)、[Imagen | Gemini API](https://ai.google.dev/gemini-api/docs/imagen)

### 選び方の目安

- **日本語プロンプトで手軽に画像生成したい** → Nano Banana（$0.039/画像）
- **4K が必要、テキストの読みやすさが重要** → Nano Banana Pro（$0.134〜$0.24/画像）
- **英語 OK で最安を求める（短期利用向け）** → Imagen 4 Fast（$0.02/画像。ただし 2026/06 廃止予定）

:::message
**新規開発には Nano Banana 系を推奨する。** Imagen 4 系は全バリアント（Fast / Standard / Ultra）が 2026/06/24 に廃止予定のため、長期的に使うなら Nano Banana 系を選ぶのが安全だ。
:::

— 出典：[DeepMind - Gemini Image Flash](https://deepmind.google/models/gemini-image/flash/)、[DeepMind - Gemini Image Pro](https://deepmind.google/models/gemini-image/pro/)、[Imagen | Gemini API](https://ai.google.dev/gemini-api/docs/imagen)

---

## Gemini ネイティブ vs Imagen 4 - どちらを選ぶか

| 比較項目 | Gemini ネイティブ（Nano Banana 系） | Imagen 4 |
|---|---|---|
| **入力** | テキスト + 画像 | テキストのみ（**英語限定**） |
| **画像編集** | **対応** | 非対応 |
| **会話型操作** | マルチターン対応 | 単発リクエストのみ |
| **日本語プロンプト** | **対応** | 非対応 |
| **コスト** | $0.039〜$0.24/画像 | **$0.02〜$0.06/画像** |
| **API 形式** | `generateContent` | `predict`（専用エンドポイント） |

**判断基準：**
- **日本語プロンプトを使いたい、画像の編集もしたい** → Gemini ネイティブ一択
- **英語 OK、最安でシンプルに画像だけ生成したい** → Imagen 4

:::message
Google は Imagen 4 を段階的に Gemini ネイティブモデルに統合する方向で進めている。Imagen 4 は 2026/06/24 に廃止予定のため、新規開発には Gemini ネイティブモデルを推奨する。
:::

---

## 料金の全体像

### すべてのモデルの料金比較

| 通称 | モデル ID | 無料枠 | 料金（1 画像） | Batch API |
|---|---|---|---|---|
| **Nano Banana** | `gemini-2.5-flash-image` | なし | $0.039 | $0.0195 |
| **Nano Banana Pro** | `gemini-3-pro-image-preview` | なし | $0.134（1K/2K）、$0.24（4K） | $0.067 / $0.12 |
| **Imagen 4 Fast** | `imagen-4.0-fast-generate-001` | なし | $0.02 | — |
| **Imagen 4 Standard** | `imagen-4.0-generate-001` | なし | $0.04 | — |
| **Imagen 4 Ultra** | `imagen-4.0-ultra-generate-001` | なし | $0.06 | — |

> すべての画像生成モデルの Free tier（無料枠） 列は "Not available" と記載されている。
> — 出典：[Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)

:::message
**Batch API（まとめ割）とは：** リクエストを一括で送信し、最大 24 時間以内に結果を受け取る方式。即時応答の通常 API に対して**料金が半額**になる。「急ぎではないが大量に画像を生成したい」場合に有効だ。Imagen 4 は Batch API に非対応。

> "The Gemini Batch API processes large volumes of requests asynchronously at 50% of the standard cost."
> （和訳：Gemini Batch API は、大量のリクエストを非同期で処理し、標準料金の 50% で利用できる。）
> — 出典：[Batch API | Gemini API](https://ai.google.dev/gemini-api/docs/batch-api)
:::

### コスト感覚

| 用途 | モデル | 100 画像のコスト | 1,000 画像のコスト |
|---|---|---|---|
| とにかく安く | Imagen 4 Fast | $2.00（約 300 円） | $20（約 3,000 円） |
| 日本語 + 編集 | Nano Banana | $3.90（約 585 円） | $39（約 5,850 円） |
| 高品質 4K | Nano Banana Pro | $24.00（約 3,600 円） | $240（約 36,000 円） |

*※ 為替レートは 1 ドル = 150 円で概算*

---

## 画像生成を試せる場所

「いきなり API を叩くのは不安」という方のために、画像生成を試せる公式の場所を紹介する。

| プラットフォーム | 費用 | 特徴 |
|---|---|---|
| **Gemini アプリ**（[gemini.google.com](https://gemini.google.com/)） | 無料（日次制限あり） | 対話形式で手軽に試せる。**API とは別物**なので注意 |
| **Google AI Studio**（[aistudio.google.com](https://aistudio.google.com/)） | 有料（課金設定必要） | API と同じモデルを UI で操作できる。開発者向け |
| **Vertex AI Studio**（GCP Console 内） | $300 無料クレジットで試用可 | エンタープライズ向け。GCP プロジェクトが必要 |

:::message alert
**Google AI Studio は「UI の利用自体は無料」だが、画像生成機能は Free tier（無料枠） では使えない。** 料金ページで明確に "Not available" と記載されており、Free tier（無料枠） で画像生成を試すとクォータエラーになる。「AI Studio 無料 ＝ 画像生成も無料」ではない点に注意。

> "Google AI Studio usage is free of charge in all available regions."
> （和訳：Google AI Studio の利用は、提供されているすべてのリージョンで無料です。）

この「利用」はテキスト生成モデルの無料枠を指しており、画像生成モデルには適用されない。
— 出典：[Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)
:::

---

## 生成画像の著作権と利用権

API で生成した画像を使う前に、権利関係を確認しておこう。

### 所有権

> "Google won't claim ownership over that content."
> （和訳：Google はそのコンテンツの所有権を主張しない。）

> "You acknowledge that Google may generate the same or similar content for others and that we reserve all rights to do so."
> （和訳：Google が他のユーザーに対して同一または類似のコンテンツを生成する可能性があることを了承する。）

— 出典：[Gemini API Additional Terms of Service](https://ai.google.dev/gemini-api/terms)

つまり、**Google は所有権を主張しないが、同じ画像が他のユーザーにも生成される可能性がある**。独占的な権利はない。

### 商用利用

> "Use of Google AI Studio and Gemini API is for developers building with Google AI models for professional or business purposes, not for consumer use."
> （和訳：Google AI Studio および Gemini API は、プロフェッショナルまたはビジネス目的で Google AI モデルを使って開発する開発者向けであり、消費者向けではない。）

— 出典：[Gemini API Additional Terms of Service](https://ai.google.dev/gemini-api/terms)

**規約上、商用利用は禁止されていない。** むしろビジネス目的での利用が前提として記載されている。ただし、生成コンテンツの利用責任はユーザーにある。

### 無料枠と有料枠のデータ利用の違い

現時点で API の画像生成に無料枠は存在しないため、画像生成を行う時点で自動的に有料枠のデータ保護が適用される。ただし **テキスト生成の無料枠** を使う場合や、将来的に画像生成の無料枠が追加された場合に重要になるため、違いを整理しておく。

| 項目 | 無料枠 | 有料枠 |
|---|---|---|
| **入出力データの学習利用** | **あり**（Google の製品改善に使用） | **なし** |
| **人間レビュアーの閲覧** | **あり** | なし（違反検出目的のログのみ） |
| **機密情報の送信** | 非推奨 | Data Processing Addendum に基づき処理 |

> **無料枠：** "Google uses the content you submit to the Services and any generated responses to provide, improve, and develop Google products and services and machine learning technologies."
> （和訳：Google は、サービスに送信したコンテンツおよび生成された応答を、Google の製品・サービスおよび機械学習技術の提供・改善・開発に使用する。）

> **有料枠：** "Google doesn't use your prompts or responses to improve our products."
> （和訳：Google はプロンプトや応答を製品の改善に使用しない。）

— 出典：[Gemini API Additional Terms of Service](https://ai.google.dev/gemini-api/terms)


### 透かし

**SynthID（透かし）** は、Google が開発した AI 生成コンテンツの識別技術だ。

> "All generated images include a SynthID watermark."
> （和訳：すべての生成画像に SynthID 透かしが含まれる。）

— 出典：[Image generation | Gemini API](https://ai.google.dev/gemini-api/docs/image-generation)

| 項目 | 内容 |
|---|---|
| 可視性 | **人間の目には見えない**（不可視） |
| 画質への影響 | なし |
| 耐性 | クロップ、フィルター追加、非可逆圧縮にも耐える |
| 除去 | できない設計 |
| 目的 | AI 生成画像の識別 |

> "SynthID embeds digital watermarks directly into AI-generated images...The watermarks are...imperceptible to humans — but can be detected by SynthID's technology."
> （和訳：SynthID は AI 生成画像にデジタル透かしを直接埋め込む。透かしは人間には見えないが、SynthID の技術で検出可能。）

— 出典：[SynthID | Google DeepMind](https://deepmind.google/technologies/synthid/)

---

## AI 生成画像の著作権に関する法的留意点

:::message
以下は一般的な情報提供であり、法的助言ではない。具体的なケースでは専門家に相談することを推奨する。
:::

Google の規約では「所有権を主張しない」と明記されているが、これは **「ユーザーが著作権を持つ」とイコールではない**。

AI 生成コンテンツの著作権保護は各国の法律によって異なり、2026 年時点で多くの国では以下の傾向がある。

- AI が自律的に生成したコンテンツには、**著作権が認められない** 傾向がある
- ユーザーが十分な**創作的関与**（プロンプト設計、編集、選択など）を行った場合に、部分的な著作権保護が認められる可能性がある

つまり、「API で生成した画像をそのまま使う」場合、著作権保護を受けられない可能性がある点は理解しておくべきである。

---

## まとめ

| 知りたいこと | 答え |
|---|---|
| API で画像生成は無料でできる？ | **できない。** 全モデルの Free tier（無料枠） は "Not available" |
| 一番安いモデルは？ | Imagen 4 Fast（$0.02/画像 ≒ 約 3 円） |
| 日本語プロンプトで使えるモデルは？ | Nano Banana / Nano Banana Pro（Imagen 4 は英語のみ） |
| 4K 画像が必要なら？ | Nano Banana Pro（$0.134〜$0.24/画像） |
| 新規開発にはどのモデルがおすすめ？ | Nano Banana 系（Imagen 4 は 2026/06 廃止予定） |
| 商用利用は OK？ | 規約上、禁止されていない |
| 透かしは入る？ | 全画像に SynthID が自動付与（不可視・除去不可） |
| 無料で画像生成を試したいなら？ | Gemini アプリ（gemini.google.com）を使う（API とは別物） |

---

## 関連記事

- [Google Cloud、課金してるアカウントどれだっけ？確認→判断→解約の3ステップ](/articles/google-cloud-billing-check)
- [Google Cloud の「無料」は3種類ある：無料トライアル・無料枠・有料アカウントの違い](/articles/google-cloud-console-basics)

## 参考リンク

- [Image generation | Gemini API](https://ai.google.dev/gemini-api/docs/image-generation)
- [Imagen | Gemini API](https://ai.google.dev/gemini-api/docs/imagen)
- [Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)
- [Gemini API Billing](https://ai.google.dev/gemini-api/docs/billing)
- [Gemini API Additional Terms of Service](https://ai.google.dev/gemini-api/terms)
- [Models | Gemini API](https://ai.google.dev/gemini-api/docs/models)
- [Deprecations | Gemini API](https://ai.google.dev/gemini-api/docs/deprecations)
- [SynthID | Google DeepMind](https://deepmind.google/technologies/synthid/)
- [DeepMind - Gemini Image Flash](https://deepmind.google/models/gemini-image/flash/)
- [DeepMind - Gemini Image Pro](https://deepmind.google/models/gemini-image/pro/)
