---
title: "Google Cloud、課金してるアカウントどれだっけ？確認→判断→解約の3ステップ"
emoji: "💸"
type: "idea"
topics: ["GoogleCloud", "GCP", "課金", "GeminiAPI", "初心者"]
published: false
---

## この記事の対象読者

- Google アカウントを複数持っていて、どれが Google Cloud に有料課金しているか分からなくなった人
- 「なんか毎月 Google Cloud から請求来てるけど、どのアカウント？」という人（YouTube Premium や Google One の請求は [Google アカウントの支払い管理](https://myaccount.google.com/payments-and-subscriptions) で確認できる）
- Gemini API を使うために課金したけど、本当に必要だったか振り返りたい人

:::message
Google Cloud Console の基本や「無料トライアルと有料アカウントの違い」を先に知りたい方は、こちらの記事をどうぞ。
👉 [Google Cloud の「無料」は3種類ある：無料トライアル・無料枠・有料アカウントの違い](/articles/google-cloud-console-basics)
:::

## 目次

本記事は **確認 → 判断 → 停止** の 3 ステップで構成されている。

**Step 1. 確認する**
- [方法 1：Cloud Console で確認する](#方法-1：google-cloud-console-で確認する)
- [方法別の使い分けまとめ](#方法別の使い分けまとめ)

**Step 2. 判断する**
- [よくある「課金しちゃった」勘違い](#よくある「課金しちゃった」勘違い)
- [課金が必要なケースと不要なケース](#課金が「必要なケース」と「不要なケース」)
- [Gemini API の課金判断フローチャート](#gemini-api-の課金判断フローチャート)

**Step 3. 止める**
- [方法 A：プロジェクトの課金を無効にする](#方法-a：特定プロジェクトの課金を無効にする)
- [方法 B：請求先アカウントを閉鎖する](#方法-b：請求先アカウントを閉鎖する)
- [方法 C：プロジェクトを削除する](#方法-c：プロジェクトを削除する)
- [どの方法を選ぶべきか](#どの方法を選ぶべきか)

**まとめ**
- [学んだこと](#まとめ：学んだこと)

## きっかけ

Google Cloud をいくつかのアカウントで触っていたら、**どのアカウントが有料アカウントで、どれが無料トライアルなのか**分からなくなった。

心当たりはいくつかある。

- **コンソールに「無料トライアルが終了します」と表示されて、焦ってアップグレードした**
- **X（Twitter）のポストや note の記事を読んで、「とりあえず課金しておけば安心」と思った**
- **Gemini API を使うために課金が必要だと勘違いした**

同じような経験をした方、いないだろうか。

まず「どのアカウントが課金されてるか調べる方法」を説明して、その後「そもそも本当に課金する必要があったのか？」を一次情報から振り返る。

---

# どのアカウントが課金されてる？ 確認方法

## 方法 1：Google Cloud Console で確認する

**おすすめの方法。** ブラウザの GUI だけで完結するため、最も簡単で確実だ。

### 手順

1. [Google Cloud Console](https://console.cloud.google.com/) に確認したいアカウントでログイン
2. 左のナビゲーションメニューから **「課金」** をクリック
3. 請求先アカウントの **概要ページ** が開く
4. ページ上部の「概要」の右側に、以下のどちらかが表示される：

| 表示 | 意味 |
|---|---|
| **⚠ 有料のアカウント** | 有料課金中。使った分だけ請求される |
| **無料トライアルのアカウント** | 無料トライアル中。$300 のクレジットを消費するか 90 日経過するまで無料 |

**実際の画面を見てみよう。**

**有料のアカウントの場合：**

![有料のアカウントの表示例](/images/gcloud-billing-paid.png)
*「概要」の右側に「有料のアカウント」と表示されている。この場合、使った分だけ請求される状態。*

**無料トライアルのアカウントの場合：**

![無料トライアルのアカウントの表示例](/images/gcloud-billing-free-trial.png)
*「無料トライアルのクレジット」が表示されている。この状態なら課金されない。*

**「有料のアカウント」と表示されていれば、そのアカウントは課金されている状態だ。**

> **公式ドキュメントの根拠**：[Free cloud features](https://cloud.google.com/free/docs/free-cloud-features) に「Paid account indicates that your account is billed」「Free trial account indicates that your account isn't billed」と明記されている。
> （和訳：「有料のアカウント」はそのアカウントに請求が発生していることを示す。「無料トライアルのアカウント」は請求が発生していないことを示す。）

### 複数の請求先アカウントがある場合

概要ページ上部の **「請求先アカウントを管理」** をクリックすると、自分がアクセスできる請求先アカウントの一覧が表示される。ここで各アカウントが「有料」か「無料トライアル」かを確認できる。

### 有料アカウントに紐づいているプロジェクトを確認する

有料アカウントを見つけたら、次に**そのアカウントにどのプロジェクトが紐づいているか**を確認しよう。不要なプロジェクトが紐づいたままだと、意図しない課金が発生する可能性がある。

1. 課金の概要ページで、左メニューの **「アカウント管理」** をクリック
2. **「このアカウントにリンクされているプロジェクト」** の一覧が表示される
3. 各プロジェクトについて、以下を確認する：

| 確認ポイント | 判断基準 |
|---|---|
| プロジェクト名に見覚えがあるか | 不明なプロジェクトは要注意 |
| 最終利用日はいつか | 長期間使っていなければ不要の可能性が高い |
| 実際にリソースが動いているか | VM（仮想マシン：クラウド上のパソコンのようなもの）やストレージが残っていると課金される |

**「使っていないけど紐づいたまま」のプロジェクトが課金の原因になっていることが多い。**

### 実際の請求金額を確認したい場合

概要ページに **合計費用・コスト削減・総費用** が表示されている。より詳しく見たい場合は、左メニューの **「料金の履歴」** を開くと、過去の請求履歴が確認できる。

### 注意点

複数の Google アカウントを持っている場合、**アカウントごとにログインし直して確認する必要がある**。アカウント横断で一括確認する公式の方法は残念ながらない。

:::message
**ほとんどの場合、方法 1 だけで十分だ。** 以下の方法 2・3 は「Google 全体の課金状況を横断確認したい」「CLI で一括操作したい」など、特殊な用途向けのため折りたたんでいる。
:::

---

:::details 方法 2：Google お支払いセンターで確認する（クリックで展開）

Google Cloud に限らず、**Google 全体で何に課金されているか**を確認できる。

### 手順

1. [payments.google.com](https://payments.google.com/) にアクセス
2. 確認したい Google アカウントでログイン
3. **「ご利用内容」** タブで取引履歴を確認
4. **「定期購入」** タブで継続課金中のサービスを確認

[myaccount.google.com/payments-and-subscriptions](https://myaccount.google.com/payments-and-subscriptions) でも同様の情報を確認できる。

Google Cloud だけでなく Google One、Google Workspace、Google Play なども含めて確認できるので、「Google から毎月何か引き落とされてるけど何だっけ？」という場合にも便利だ。

:::

:::details 方法 3：gcloud CLI で確認する（クリックで展開）

複数のプロジェクトやアカウントをまとめて確認したい場合、コマンドラインが便利だ。

### 前提：gcloud CLI のインストール

PowerShell で `gcloud` と打ってこのエラーが出たら、まだインストールされていない。

```
gcloud: The term 'gcloud' is not recognized as a name of a cmdlet, function, script file, or executable program.
```

私も最初これが出て「え？」となった。

### gcloud CLI インストール手順

以下は Windows 環境での手順だ。

#### 方法 A：インストーラーを使う

**推奨の方法。** 手順が少なくトラブルも起きにくい。

1. [Google Cloud SDK のインストールページ](https://cloud.google.com/sdk/docs/install?hl=ja) にアクセス
2. **「Windows」** タブを選択
3. **「Google Cloud CLI インストーラ」** をダウンロード
4. ダウンロードした `.exe` ファイルを実行
5. インストーラーの指示に従って進める（基本デフォルトで OK）
6. インストール完了後、**新しいターミナル（PowerShell / コマンドプロンプト）を開き直す**

:::message alert
インストール後、必ずターミナルを開き直してほしい。既に開いているターミナルでは PATH が反映されない。
:::

#### 方法 B：winget を使う

```powershell
winget install Google.CloudSDK
```

#### インストール確認

```powershell
gcloud --version
```

バージョン情報が表示されれば OK だ。

### 初期設定

初回のみ必要な設定だ。2 回目以降はスキップしてよい。

```powershell
gcloud init
```

ブラウザが開くので、確認したい Google アカウントでログインして認証する。

### 請求先アカウントの一覧を取得

```powershell
gcloud billing accounts list
```

出力例：

```
ACCOUNT_ID            NAME                  OPEN   MASTER_ACCOUNT_ID
012345-ABCDEF-678901  My Billing Account    True
FEDCBA-987654-FEDCBA  Test Account          False
```

- **OPEN = True** → アクティブな課金アカウント
- **OPEN = False** → 閉じられた（非アクティブな）アカウント

### 特定の請求先アカウントの詳細を確認

```powershell
gcloud billing accounts describe ACCOUNT_ID
```

出力例：

```yaml
displayName: My Billing Account
masterBillingAccount: ''
name: billingAccounts/012345-ABCDEF-678901
open: true
```

### 特定プロジェクトの課金状態を確認

```powershell
gcloud billing projects describe PROJECT_ID
```

- `billingEnabled: true` → 課金有効
- `billingEnabled: false` → 課金無効

### CSV で一覧出力

```powershell
gcloud alpha billing accounts list --format="csv(displayName,masterBillingAccount,name,open)" > billingAccounts.csv
```

:::

## 方法別の使い分けまとめ

| やりたいこと | おすすめの方法 |
|---|---|
| とりあえずどのアカウントが有料か知りたい | 方法 1（Cloud Console の「課金」） |
| Google 全体で何に課金されてるか調べたい | 方法 2（payments.google.com） |
| 複数プロジェクトの課金状態を一括チェック | 方法 3（gcloud CLI） |

---

# その課金、本当に必要だった？

ここからが本題だ。一次情報（公式ドキュメント）をもとに振り返る。

## よくある「課金しちゃった」勘違い

私が課金してしまった理由を振り返ると、**すべて勘違い**だった。

| 勘違い | 事実（公式ドキュメントより） |
|---|---|
| 「無料トライアルが終了します」に焦ってアップグレードした | **何もしなければ課金されない。** トライアル終了後はリソースが停止されるだけ。手動でアップグレードしない限り請求は発生しない |
| Gemini API を使うには課金が必要だと思った | **テキスト生成・要約・コード補助なら課金不要。** 無料枠で Gemini 2.5 Pro / Flash が使える |
| チュートリアルの手順で課金を有効化した | **「課金を有効にする ≠ お金がかかる」。** 請求先アカウントへのリンクは必要だが、無料枠内ならコストゼロ |

> 無料トライアルを終了するために特別な操作は不要だ。$300 のクレジットを使い切るか、91 日が経過すると自動的に終了する。**手動で有料アカウントにアップグレードしない限り、請求されることはない。**

— 出典：[Google Cloud Free Trial FAQs](https://cloud.google.com/signup-faqs)

:::message alert
**無料トライアル → 有料アカウントへのアップグレードは不可逆だ。** 一度アップグレードすると無料トライアルには戻せない。

> 公式 FAQ：「If you unintentionally upgraded to a paid account, follow these steps to close your account.」
> （和訳：意図せず有料アカウントにアップグレードしてしまった場合は、以下の手順でアカウントを閉じてください。）

— 出典：[Google Cloud Free Trial FAQs](https://cloud.google.com/signup-faqs)
:::

---

## 課金が「必要なケース」と「不要なケース」

「結局、自分は課金する必要があるの？」を判断するための一覧だ。

Google Cloud 全般の無料枠・無料トライアルの詳細は、[Google Cloud Console 入門記事](/articles/google-cloud-console-basics)にまとめている。ここでは **Gemini API に特化した判断基準** を解説する。

### Gemini API：課金しないとできないこと

| 制限事項 | 備考 |
|---|---|
| **レート制限の緩和** | 無料枠は 2.5 Pro で 5 RPM / 25 RPD まで |
| **画像生成（全モデル）** | 無料枠では利用不可。詳細は [Gemini API 画像生成ガイド](/articles/gemini-api-image-generation-guide) を参照 |
| **データの学習利用を拒否** | 無料枠はモデル改善に使用される可能性あり |
| **EU/EEA/UK/スイスのユーザー向けサービス提供** | 有料枠でないと提供不可 |

— 出典：[Gemini API 課金ドキュメント](https://ai.google.dev/gemini-api/docs/billing?hl=ja)、[料金ページ](https://ai.google.dev/gemini-api/docs/pricing)

### Gemini API：課金しなくても使えること

| サービス | 無料枠 |
|---|---|
| **Gemini API（テキスト生成）** | 2.5 Pro: 5 RPM・25 RPD / Flash: 15 RPM・500 RPD |
| **Google AI Studio** | テキスト生成は無料（全リージョン）。**画像生成は有料のみ** |

:::message
Google AI Studio の UI 利用自体は無料だ。ただし **画像生成は無料枠の対象外** であり、課金設定が必要。詳細は [Gemini API 画像生成ガイド](/articles/gemini-api-image-generation-guide) を参照してほしい。

> "Google AI Studio usage is free of charge in all available regions."
> （和訳：Google AI Studio の利用は、提供されているすべてのリージョンで無料です。）

— 出典：[Gemini API Pricing](https://ai.google.dev/gemini-api/docs/pricing)
:::

---

## Gemini API の課金判断フローチャート

```
Gemini API を使いたい
    │
    ├─ Google AI Studio でブラウザから試すだけ
    │   → 課金不要（完全無料）
    │
    ├─ API キーで自分のアプリから呼び出す
    │   │
    │   ├─ テキスト生成・要約・コード補助
    │   │   │
    │   │   ├─ 1 日数十リクエスト程度 → 課金不要（無料枠で十分）
    │   │   └─ 1 日数百〜数千リクエスト → 課金必要（Tier 1 以上）
    │   │
    │   ├─ 画像生成（全モデル）
    │   │   → 課金必須（無料枠では利用不可）
    │   │
    │   └─ EU/EEA/UK/スイスのユーザー向けサービス
    │       → 課金必須（有料枠でないと提供不可）
    │
    └─ データを Google に学習利用されたくない
        → 課金必要（有料枠のみデータ非利用）
```

---

# 不要な課金を止める 3つの方法

課金アカウントを特定し、「実は不要だった」と分かったら、次は実際に課金を止めよう。

やりたいことに応じて、3つの方法がある。

| やりたいこと | 方法 | 影響範囲 |
|---|---|---|
| 特定のプロジェクトの課金だけ止めたい | プロジェクトの課金を無効にする | そのプロジェクトのみ |
| 請求先アカウントごと閉じたい | 請求先アカウントを閉鎖する | アカウントに紐づく全プロジェクト |
| プロジェクト自体をもう使わない | プロジェクトを削除する | プロジェクト内の全リソースが削除 |

---

## 方法 A：特定プロジェクトの課金を無効にする

「このプロジェクトは使っていないから課金を外したい」という場合に最適だ。

### 手順

1. [Google Cloud Console](https://console.cloud.google.com/) にログイン
2. 左メニューの **「課金」** をクリック
3. **「アカウント管理」** を開く
4. 「このアカウントにリンクされているプロジェクト」の一覧から、対象プロジェクトの右端の **「︙」（3 点メニュー）** をクリック
5. **「課金を無効にする」** を選択
6. 確認ダイアログで **「課金を無効にする」** をクリック

:::message
課金を無効にすると、そのプロジェクトの有料リソース（VM インスタンス、Cloud Storage のデータ等）は**一定期間後に削除される**。無料枠のみで使っている場合は影響ない。

**注意**：確約利用割引（CUD）がアクティブまたは保留中の場合、課金を無効にできない。先に CUD の状態を確認してほしい。
:::

— 参考：[プロジェクトの課金の変更・無効化 | Google Cloud](https://cloud.google.com/billing/docs/how-to/modify-project)

---

## 方法 B：請求先アカウントを閉鎖する

請求先アカウント自体を閉じる方法だ。**そのアカウントに紐づくすべてのプロジェクトで有料サービスが停止される。**

### 手順

1. [Google Cloud Console](https://console.cloud.google.com/) にログイン
2. 左メニューの **「課金」** をクリック
3. 閉じたい請求先アカウントを選択
4. **「アカウント管理」** を開く
5. ページ上部の **「アカウントを閉鎖」** をクリック
6. 確認ダイアログの内容を読み、**「閉鎖」** をクリック

### 閉鎖した後の挙動

| 項目 | 閉鎖後の動作 |
|---|---|
| 新たな課金 | 発生しない |
| 未払い残高 | 支払い義務が残る |
| リンク済みプロジェクト | 有料リソースが停止・削除される |
| 再開 | **閉鎖後も再開可能**（データが残っている期間内） |

:::message
請求書払い（インボイス）アカウントの場合は、オンラインでの閉鎖ができない。Google Cloud の営業担当またはサポートに連絡してほしい。
:::

— 参考：[請求先アカウントの閉鎖・再開 | Google Cloud](https://cloud.google.com/billing/docs/how-to/close-or-reopen-billing-account)

---

## 方法 C：プロジェクトを削除する

プロジェクト自体を完全に削除する方法だ。**プロジェクト内の全リソース（VM、ストレージ、API キー等）が削除される。**

### 手順

1. [Google Cloud Console](https://console.cloud.google.com/) にログイン
2. 削除したいプロジェクトを選択
3. 左メニューの **「IAM と管理」** → **「設定」** を開く
4. **「シャットダウン」** をクリック
5. プロジェクト ID を入力
6. **「シャットダウン」** をクリックして確認

:::message alert
- プロジェクト削除後は **30 日間の復元猶予期間** がある。30 日を過ぎると完全に削除され、復元できない。
- **削除したプロジェクトのプロジェクト ID は再利用できない。**
:::

— 参考：[プロジェクトのシャットダウン | Google Cloud](https://cloud.google.com/resource-manager/docs/creating-managing-projects#shutting_down_projects)

---

## どの方法を選ぶべきか

```
不要な課金を止めたい
    │
    ├─ 他のプロジェクトは引き続き使いたい
    │   │
    │   ├─ プロジェクトのリソースを残したい → 方法 A（課金を無効にする）
    │   └─ プロジェクトごと不要 → 方法 C（プロジェクトを削除する）
    │
    └─ この請求先アカウント全体をもう使わない
        → 方法 B（請求先アカウントを閉鎖する）
```

---

## まとめ：学んだこと

1. **「無料トライアルが終了します」に焦る必要はなかった。** 放置しても課金されない。
2. **Gemini API のテキスト生成は課金なしで使える。** 無料枠のレート制限が足りなくなるまで課金不要。
3. **X や note の情報を鵜呑みにせず、公式ドキュメントで確認すべきだった。** 「課金必須」と書いてある記事の多くは、特定のユースケース（高レート、画像生成、EU 向け）の話だった。
4. **Google Cloud の「課金を有効にする」は「お金がかかる」とイコールではない。** 無料枠内ならコストゼロ。
5. **不要な課金は「プロジェクトの課金無効化」「請求先アカウントの閉鎖」「プロジェクト削除」で止められる。**

「どのアカウントで課金してたっけ？」「そもそもこれ課金する必要あった？」という地味だけど困る問題、同じ悩みを持った方の参考になれば幸いだ。

---

## 関連記事

- [その Gemini 画像、透かし入ってるよ？API画像生成の著作権・料金を公式情報で整理](/articles/gemini-api-image-generation-guide)
- [Google Cloud の「無料」は3種類ある：無料トライアル・無料枠・有料アカウントの違い](/articles/google-cloud-console-basics)

## 参考リンク

- [Cloud Billing の概要 | Google Cloud](https://cloud.google.com/billing/docs/concepts)
- [プロジェクトの課金ステータスの確認 | Google Cloud](https://cloud.google.com/billing/docs/how-to/verify-billing-enabled)
- [無料トライアルと無料枠 | Google Cloud](https://cloud.google.com/free/docs/free-cloud-features)
- [Google Cloud 無料トライアル FAQ | Google Cloud](https://cloud.google.com/signup-faqs)
- [Google Cloud 無料枠の一覧 | Google Cloud](https://cloud.google.com/free)
- [請求先アカウントの管理 | Google Cloud](https://cloud.google.com/billing/docs/how-to/manage-billing-account)
- [請求先アカウントの閉鎖・再開 | Google Cloud](https://cloud.google.com/billing/docs/how-to/close-or-reopen-billing-account)
- [プロジェクトの課金の変更・無効化 | Google Cloud](https://cloud.google.com/billing/docs/how-to/modify-project)
- [プロジェクトのシャットダウン | Google Cloud](https://cloud.google.com/resource-manager/docs/creating-managing-projects#shutting_down_projects)
- [Google Cloud SDK インストール | Google Cloud](https://cloud.google.com/sdk/docs/install?hl=ja)
- [gcloud billing accounts list | Google Cloud SDK](https://cloud.google.com/sdk/gcloud/reference/billing/accounts/list)
- [Gemini API 課金 | Google AI for Developers](https://ai.google.dev/gemini-api/docs/billing?hl=ja)
- [Gemini API 料金 | Google AI for Developers](https://ai.google.dev/gemini-api/docs/pricing)
- [Google お支払いセンター](https://payments.google.com/)
