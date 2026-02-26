---
title: "Google Cloud の「無料」は3種類ある：無料トライアル・無料枠・有料アカウントの違い"
emoji: "☁️"
type: "tech"
topics: ["googlecloud", "ai", "生成ai", "GeminiAPI", "初心者"]
published: true
---

:::message
この記事の情報は **2026 年 2 月時点** のものである。料金・無料枠は変更される可能性があるため、最新情報は各セクションに記載した公式リンクを参照してほしい。
:::

## この記事の結論

- **Google Cloud の「無料」は 3 種類ある。** 無料トライアル（$300 クレジット）/ 有料アカウント（従量課金）/ 無料枠（Always Free）
- **登録しただけではお金はかからない。** 手動でアップグレードしない限り請求は発生しない
- **「課金を有効にする」≠ 即請求。** 無料枠内ならコストゼロ
- **有料アカウントへのアップグレードは不可逆。** 慎重に判断すること

## 目次

1. [この記事の結論](#この記事の結論)
2. [Google Cloud Console とは](#google-cloud-console-とは)
3. [無料トライアルと有料アカウントと無料枠の違い](#無料トライアルと有料アカウントと無料枠の違い)
4. [課金しないとできないこと](#課金しないとできないこと)
5. [課金しなくても使えるサービス](#課金しなくても使えるサービス)
6. [まとめ](#まとめ)

## この記事の対象読者

- 「Google Cloud Console ってそもそも何？」という人
- 無料トライアルと有料アカウントと無料枠の違いがよく分からない人
- Google Cloud に登録したけど、お金がかかるのか不安な人

:::message
「すでに課金されてるけど止め方が分からない」「どのアカウントが課金されてるか調べたい」という方は、こちらの記事をどうぞ。
👉 [Google Cloud、課金してるアカウントどれだっけ？確認→判断→解約の3ステップ](google-cloud-billing-check)
:::

## Google Cloud Console とは

**Google Cloud Console** は、Google が提供するクラウドサービス群「Google Cloud」を管理するための Web ベースの管理画面だ。

ブラウザで [console.cloud.google.com](https://console.cloud.google.com/) にアクセスして使う。150 以上のサービスを GUI（マウスやキーボードで操作する画面）で操作できる。

> "Build a free proof of concept with $300 in free credit and try over 150 products in the Google Cloud console."
> （和訳：$300 の無料クレジットで概念実証を構築し、Google Cloud Console で 150 以上のプロダクトを試せる。）
> — 出典：[Google Cloud Console](https://cloud.google.com/cloud-console)

### どんなときに使うのか

「自分には関係なさそう」と思うかもしれないが、以下のような場面で Cloud Console を使うことになる。

| やりたいこと | Cloud Console での操作 |
|---|---|
| **Gemini API でテキスト生成したい** | API キーは [Google AI Studio](https://aistudio.google.com/api-keys) で発行する。Cloud Console では課金状況やクォータ（利用上限）を確認する |
| **Gemini API で画像を生成したい** | 画像生成は全モデル有料。Cloud Console で課金設定を行う。詳細は [画像生成の記事](gemini-api-image-generation-guide) を参照 |
| **「毎月 Google から請求が来てるけど何？」** | まず [Google アカウントの支払い管理](https://myaccount.google.com/payments-and-subscriptions) を確認。YouTube Premium や Google One 等はそちらに表示される。**Google Cloud の利用料金だけ**が Cloud Console の「課金」メニューに表示される |
| **ファイルをクラウドに保存したい** | Cloud Storage でファイルを保存・共有できる（5 GB/月 まで無料） |
| **大量のデータを分析したい** | BigQuery で SQL（データベースの操作言語）を使ってデータ分析ができる（1 TB/月 まで無料） |

つまり Cloud Console は **「Google Cloud で何かやるときの入口」** だ。直接ここで何かを作るというより、**設定・管理・確認** をする場所である。

— 出典：[Google Cloud overview](https://cloud.google.com/docs/overview)

---

## 無料トライアルと有料アカウントと無料枠の違い

Google Cloud には「無料」に関する仕組みが 3 つあり、混同しやすい。

| 名称 | 内容 | 期間 |
|---|---|---|
| **無料トライアル** | 新規登録時にもらえる $300 分のクレジット | 90 日間 |
| **有料アカウント** | 無料トライアル終了後（またはアップグレード後）の状態。使った分だけ請求される | 無期限 |
| **無料枠（Always Free）** | 一部サービスが毎月一定量まで無料で使える枠 | 無期限 |

### 無料トライアルと有料アカウントの比較

| | 無料トライアル | 有料アカウント |
|---|---|---|
| 課金 | されない | される |
| クレジット | $300（90 日間） | 残りがあれば引き続き使える |
| 制限 | GPU・Windows VM 等に制限あり | フルアクセス |
| アップグレード | → 有料アカウントに変更可能 | **元に戻せない** |
| トライアル終了後 | リソースが停止（30 日猶予） | そのまま継続 |
| 放置した場合 | 課金されない | **課金される可能性あり** |

:::message alert
**最も重要なポイント：** 無料トライアル → 有料アカウントへのアップグレードは**不可逆**だ。一度アップグレードすると無料トライアルには戻せない。
:::

### 課金を有効にしても即請求ではない

Google Cloud の多くのサービスは、**無料枠の範囲内でも請求先アカウントへのリンクが必要**だ。つまり「課金を有効にする」という操作は、「請求先アカウントを紐づける」という意味であり、即座にお金がかかるわけではない。

無料枠内で使っている限り、コストはゼロである。

### 請求の仕組み

有料アカウントにアップグレードした場合、料金体系は**従量課金（pay-as-you-go）**だ。事前にチャージする方式ではなく、**使った分だけ後から請求される**。

> "You only pay for what you use with no lock-in."
> （和訳：ロックインなしで、使った分だけ支払う。）
> — 出典：[Google Cloud Pricing](https://cloud.google.com/pricing)

| 項目 | 内容 |
|---|---|
| **料金体系** | 従量課金（使った分だけ請求） |
| **請求タイミング** | 月末締め、または利用額が一定額に達した時点（アカウントごとに自動決定） |
| **支払い方法** | クレジットカード / デビットカード（セルフサービスアカウントの場合） |
| **予算アラート** | **自動では届かない。** 自分で設定する必要がある |
| **上限設定** | アラートを設定しても、**使用量は自動停止しない** |

:::message alert
**予算アラートは自分で設定しないと届かない。** さらに、アラートが届いても Google Cloud のサービスは止まらない。使いすぎを防ぐには、[予算とアラートの設定](https://cloud.google.com/billing/docs/how-to/budgets)を事前に行うことを推奨する。

> "Budget alerts are used to track your actual Google Cloud spend against your planned spend. (...) Budget alerts do not cap your Google Cloud spend."
> （和訳：予算アラートは、計画した支出に対して実際の Google Cloud 支出を追跡するために使用する。（中略）予算アラートは Google Cloud の支出に上限を設けるものではない。）
> — 出典：[Set budgets and budget alerts](https://cloud.google.com/billing/docs/how-to/budgets)
:::

---

## 課金しないとできないこと

「無料トライアルで何ができないの？」が一番気になるところだと思う。正直、ほとんどの人には関係ない制限ばかりだ。

### Gemini API

| 制限事項 | どんな人に影響するか |
|---|---|
| **画像生成（全モデル）** | Gemini API で画像を自動生成したい人。**全モデル有料、無料枠なし** |
| **レート制限の緩和** | API を頻繁に呼び出すアプリを作りたい人。無料枠は 1 日 25 回（2.5 Pro）まで |
| **データの学習利用を拒否** | 入力した文章を Google の AI 改善に使われたくない人 |
| **EU/EEA/UK/スイスのユーザー向けサービス** | ヨーロッパ向けのサービスを提供したい人 |

:::message
画像生成は課金が必須な代表例だ。Gemini アプリ（gemini.google.com）なら無料で画像生成できるが、API 経由では全モデル有料。モデルの違い・料金・著作権については別記事で解説している。
👉 [その Gemini 画像、透かし入ってるよ？API画像生成の著作権・料金を公式情報で整理](gemini-api-image-generation-guide)
:::

— 出典：[Gemini API Billing](https://ai.google.dev/gemini-api/docs/billing)、[Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)

### Google Cloud 全般

| 制限事項 | どんな人に影響するか |
|---|---|
| **GPU の追加** | AI モデルの学習を自分の環境で回したい人 |
| **Windows Server の仮想マシン作成** | Windows 環境をクラウド上に構築したい人。Linux なら無料トライアルでも可 |
| **Google Cloud Marketplace** | 他社製のソフトウェアを Google Cloud 上でワンクリック導入したい人 |
| **クォータ（利用上限）の引き上げ** | 無料枠のリクエスト数や容量では足りない人 |

> 公式ドキュメントの原文：
> "You cannot add GPUs to your VM instances."
> "You cannot create VM instances that are based on Windows Server images."
> "You cannot use Google Cloud Marketplace."
> "You cannot request a quota increase."
> — 出典：[Free cloud features](https://cloud.google.com/free/docs/free-cloud-features)

:::message
上記はすべて **無料トライアル中の制限** だ。ほとんどの人には関係ない。「GPU で AI を学習させたい」「Windows サーバーを立てたい」といった明確な目的がなければ、無料トライアルのままで十分である。
:::

---

## 課金しなくても使えるサービス

Google Cloud には、**無料トライアル終了後も毎月無料で使い続けられる「Always Free」枠** がある。以下は特に使う機会がありそうなものを抜粋したリストだ。

### AI / データ分析系

| サービス | 無料枠 | どんなサービスか |
|---|---|---|
| **Gemini API（テキスト生成）** | 2.5 Pro: 5 RPM（1分あたり5回）・25 RPD（1日あたり25回） / Flash: 15 RPM・500 RPD | AI にテキスト生成・要約・翻訳などを頼める |
| **Google AI Studio** | テキスト生成は無料。**画像生成は有料のみ** | Gemini API をブラウザ上で試せるツール |
| **BigQuery** | 1 TB クエリ/月、10 GB ストレージ | 大量データを SQL で分析できるサービス |
| **Cloud Natural Language API** | 5,000 ユニット/月 | テキストから感情や重要な語句（人名・地名・組織名など）を抽出 |
| **Cloud Vision** | 1,000 ユニット/月 | 画像の中身を AI が分析（ラベル付け、文字認識） |
| **Speech-to-Text** | 60 分/月 | 音声をテキストに変換 |

— 出典：[Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)、[Google Cloud 無料枠の一覧](https://cloud.google.com/free)

### ストレージ / Web アプリ系

| サービス | 無料枠 | どんなサービスか |
|---|---|---|
| **Cloud Storage** | 5 GB/月（米国リージョン＝米国のデータセンター） | ファイルをクラウドに保存・共有 |
| **Cloud Run** | 200 万リクエスト/月 | Web アプリやAPIをサーバー管理なしで動かす |
| **Firestore** | 1 GB ストレージ（データ保存領域）、5 万読取/日 | モバイル・Web アプリ向けのデータベース |
| **Compute Engine** | e2-micro（最小構成の仮想サーバー）1 台/月（米国リージョン） | 小さな仮想サーバーを 1 台無料で動かせる |
| **Cloud Shell** | 5 GB 永続ディスク | ブラウザ上でコマンド操作ができるツール |

— 出典：[Google Cloud 無料枠の一覧](https://cloud.google.com/free)

:::details その他の無料枠サービス（クリックで展開）

| サービス | 無料枠 |
|---|---|
| Cloud Run functions | 200 万呼び出し/月 |
| App Engine | F1 インスタンス 28 時間/日 |
| Pub/Sub | 10 GB メッセージ/月 |
| Cloud Build | 2,500 ビルド分/月 |
| Artifact Registry | 0.5 GB ストレージ/月 |
| Secret Manager | 6 アクティブシークレット（API キーやパスワードなどの機密情報を暗号化して安全に保管するサービス。[概要](https://cloud.google.com/secret-manager/docs/overview?hl=ja)） |
| Cloud KMS | 100 アクティブキーバージョン |
| Workflows | 内部ステップ 5,000 回/月 |
| Video Intelligence API | 1,000 ユニット/月 |
| Cloud Observability | ログ 50 GB/月 |

— 出典：[Google Cloud 無料枠の一覧](https://cloud.google.com/free)

:::

:::message
Google AI Studio の UI 利用自体は無料だが、**画像生成は無料枠の対象外** で課金設定が必要。「完全無料」はテキスト生成モデルに限った話だ。

> "Google AI Studio usage is free of charge in all available regions."
> （和訳：Google AI Studio の利用は、提供されているすべてのリージョンで無料です。）

また、無料枠は無料トライアル終了後も継続的に使える。ただし、無料枠を利用するにもアクティブな請求先アカウントへのリンクは必要である。
— 出典：[Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)
:::

---

## まとめ

| 知りたいこと | 答え |
|---|---|
| Google Cloud Console って何？ | Google Cloud の設定・管理・確認をする Web 画面 |
| 登録しただけでお金かかる？ | かからない。無料トライアルは $300 クレジット付き |
| 「課金を有効にする」って怖い？ | 無料枠内なら請求ゼロ。請求先アカウントの紐づけ＝即課金ではない |
| 無料トライアルが終わったらどうなる？ | 作成したサーバーやデータベースなどが停止されるだけ。放置しても課金されない |
| 有料アカウントにしたら戻せる？ | **戻せない。** 不要になったら[請求先アカウントを閉鎖する](google-cloud-billing-check) |
| 使いすぎたら自動で止まる？ | **止まらない。** 予算アラートは自分で設定が必要。設定しても自動停止はしない |
| Gemini API で画像生成するには？ | 有料課金が必須。[画像生成の記事](gemini-api-image-generation-guide)で詳しく解説 |

:::message
「すでに課金されてるアカウントを特定して止めたい」という方はこちら。
👉 [Google Cloud、課金してるアカウントどれだっけ？確認→判断→解約の3ステップ](google-cloud-billing-check)
:::

### 次のステップ

1. まずは [console.cloud.google.com](https://console.cloud.google.com/) にアクセスして、自分のアカウント状態を確認してみよう
2. 「有料のアカウント」と表示されていて不要なら → [課金管理の記事](google-cloud-billing-check)で止め方を確認
3. Gemini API で画像生成をしたい場合 → [画像生成の記事](gemini-api-image-generation-guide)で料金やモデルを確認

---

## 関連記事

- [Google Cloud、課金してるアカウントどれだっけ？確認→判断→解約の3ステップ](google-cloud-billing-check)
- [その Gemini 画像、透かし入ってるよ？API画像生成の著作権・料金を公式情報で整理](gemini-api-image-generation-guide)

## 参考リンク

:::message
Google Cloud の公式ドキュメントは、URL の末尾に `?hl=ja` を付けると日本語で表示できる。英語で表示される場合は試してほしい。
:::

- [Google Cloud Console](https://cloud.google.com/cloud-console)
- [Google Cloud overview](https://cloud.google.com/docs/overview)
- [Cloud Billing の概要 | Google Cloud](https://cloud.google.com/billing/docs/concepts)
- [Google Cloud Pricing](https://cloud.google.com/pricing)
- [Set budgets and budget alerts | Google Cloud](https://cloud.google.com/billing/docs/how-to/budgets)
- [無料トライアルと無料枠 | Google Cloud](https://cloud.google.com/free/docs/free-cloud-features)
- [Google Cloud 無料トライアル FAQ | Google Cloud](https://cloud.google.com/signup-faqs)
- [Google Cloud 無料枠の一覧 | Google Cloud](https://cloud.google.com/free)
- [Gemini API 課金 | Google AI for Developers](https://ai.google.dev/gemini-api/docs/billing)
- [Gemini API 料金 | Google AI for Developers](https://ai.google.dev/gemini-api/docs/pricing)
- [Gemini API キーの取得 | Google AI for Developers](https://ai.google.dev/gemini-api/docs/api-key)
- [Billing anomaly detection and alerting | Google Cloud](https://cloud.google.com/billing/docs/how-to/manage-anomalies)
- [Essential Contacts の管理 | Google Cloud](https://cloud.google.com/resource-manager/docs/managing-notification-contacts)
- [Secret Manager の概要 | Google Cloud](https://cloud.google.com/secret-manager/docs/overview)
