---
title: "デザインできなくてもOK：Google StitchでWordPressのUIを生成する"
emoji: "🧵"
type: "tech"
topics: ["googlestitch", "wordpress", "ai", "figma", "webdesign"]
published: false
---

:::message
**シリーズ構成：AIでWordPressテーマを自作する**
1. [有料テーマを買わない選択肢：Google Stitch × Google AntigravityでWordPressテーマを自作する](https://zenn.dev/komei/articles/wordpress-ai-theme-overview)
2. **デザインできなくてもOK**（この記事）
3. [コードを書かずにPHPテンプレートを作る：Google Antigravity活用ガイド](https://zenn.dev/komei/articles/wordpress-ai-theme-antigravity)
4. [プロ品質に仕上げる：Google Antigravityでセキュリティと品質管理を自動化](https://zenn.dev/komei/articles/wordpress-ai-theme-quality)
5. [AIで記事を量産する：Google Antigravityで執筆→入稿を自動化](https://zenn.dev/komei/articles/wordpress-ai-theme-automation)
:::

## はじめに

前回の記事では、AIでWordPressテーマを自作するワークフローの全体像を解説しました。

この記事では、**Google Stitchを使ってWordPressテーマに必要なUIデザインを生成する**方法を解説します。デザインツールの経験がなくても、テキストプロンプトだけで本格的なUIが手に入ります。

## なぜ「普通のプロンプト」ではダメなのか

Google Stitchにただ「Webサイトを作って」と指示すると、単一のランディングページが生成されます。しかしWordPressテーマには複数のテンプレートファイルが必要です。

| WordPressテンプレート | 役割 |
|---|---|
| `front-page.php` | トップページ |
| `archive.php` | 一覧ページ（記事一覧、カテゴリ一覧など） |
| `single.php` | 個別記事ページ |
| `page.php` | 固定ページ |
| `header.php` | 共通ヘッダー |
| `footer.php` | 共通フッター |

**Google Stitchに生成させるべき画面は、WordPressのテンプレート階層に対応させる**のがポイントです。

## プロンプトの基本型

Google Stitchのプロンプトは、以下の5要素を埋めるだけで高品質なUIが生成できます。

```
① 用途：Web向け。[業種]の[ページ種別]。
② レイアウト：[配置する要素を箇条書き]
③ 配色：[メインカラー]に[テキストカラー]、アクセントカラーは[アクセント]
④ 雰囲気：[2〜3語のキーワード]
⑤ ターゲット：[想定ユーザー]
```

この型を使って、WordPressの各テンプレートに対応するUIを順番に生成していきます。

## 実践：不動産会社サイトを例に

本記事では、地域密着型の不動産会社（賃貸管理・駐車場運営・仲介・空き家対策・リフォーム）を例に解説します。末尾の「業種カスタマイズテンプレート」で自分の業種に簡単に置き換えられます。

### フロントページ（front-page.php 相当）

```
Web向け。町の不動産会社のコーポレートサイト トップページ。
事業内容：不動産賃貸管理、遊休地・スペース活用（駐車場・収納運営）、不動産仲介・代理、空き家対策コンサルティング、建設・リフォーム
レイアウト：
- 上部にロゴとナビゲーションメニュー（ホーム、事業内容、物件情報、お知らせ、会社概要、お問い合わせ）
- ヒーローセクション（「地域の暮らしと資産を支える」のようなキャッチコピー＋物件検索CTAボタン）
- 事業紹介セクション：5つの事業をアイコン付きカードで横並び表示
- 新着物件3件をカード型で表示（物件写真、間取り、賃料、所在地）
- お知らせ・コラム 最新3件
- Google Maps埋め込み＋会社概要（所在地、電話番号、営業時間）
- フッターに事業一覧リンク、プライバシーポリシー、免許番号
配色：ネイビー（#1B2A4A）背景にホワイトテキスト、アクセントカラーはテラコッタオレンジ（#C4704A）
雰囲気：信頼感がありつつ親しみやすい、地域密着
ターゲット：地元で物件を探している個人、土地活用を検討しているオーナー
```

### 物件一覧ページ（archive.php 相当）

```
Web向け。不動産会社の物件一覧ページ。
レイアウト：
- 共通ヘッダー（ロゴ＋ナビ）
- 検索フィルターバー（エリア、物件種別、賃料範囲、間取り）
- メインエリア（幅70%）：物件カード一覧を縦に6件
  - 各カード：物件写真、物件名、所在地、賃料/価格、間取り、築年数、タグ（新着/おすすめ）
- 右サイドバー（幅30%）：条件で絞り込み、おすすめ物件、お問い合わせバナー
- 物件一覧の下にページネーション（前へ / 1 2 3 / 次へ）
- 共通フッター
配色：前の画面と同じテーマカラーを維持
```

### 物件詳細ページ（single.php 相当）

```
Web向け。不動産会社の物件詳細ページ。
レイアウト：
- 共通ヘッダー
- パンくずリスト（ホーム > 物件情報 > エリア名 > 物件名）
- メイン画像ギャラリー（スライダー形式、サムネイル付き）
- 物件概要テーブル（所在地、賃料/価格、管理費、間取り、面積、築年数、構造、駐車場、入居可能日）
- 物件説明文（見出しH2/H3、段落）
- 周辺環境情報（最寄り駅、スーパー、学校などへの距離）
- 「この物件について問い合わせる」CTAボタン（目立つ配置）
- 右サイドバー：担当者情報、関連物件、お問い合わせフォームへのリンク
- 共通フッター
配色：同じテーマカラー
```

### 固定ページ：事業内容（page.php 相当）

```
Web向け。不動産会社の事業内容紹介ページ。
レイアウト：
- 共通ヘッダー
- ページタイトル付きヒーローバナー
- 事業ごとのセクション（5事業分）：
  各セクションに見出し、説明文、関連写真、「詳しく見る」ボタン
  - 不動産賃貸管理：入居者募集から退去精算までワンストップ
  - 遊休地・スペース活用：駐車場・トランクルーム運営
  - 不動産仲介・代理：売買・賃貸の仲介
  - 空き家対策コンサルティング：管理・活用提案
  - 建設・リフォーム：新築からリノベーションまで
- 実績・数字で見る当社（管理戸数、取引実績など）
- 共通フッター
配色：同じテーマカラー
```

:::message alert
**Google Stitchの現在の制限事項（2026年2月時点）**
Google Stitchは1回の生成で2〜3画面が限度です。上記の4画面はそれぞれ別セッションで生成し、テーマカラーの統一は「配色：前の画面と同じテーマカラーを維持」と明示することで対応します。

[Stitch 2.0](https://www.aifire.co/p/google-stitch-2-0-a-guide-to-the-free-ai-coding-design-agent)では、標準モード（Gemini 2.5 Flash）が無制限、Experimentalモード（Gemini 2.5 Pro）が月400回に拡充されています。制限は変動する可能性があるため、[公式サイト](https://stitch.withgoogle.com/)で最新情報を確認してください。
:::

## Google AntigravityにStitchのデザインを渡す

Google Stitchで生成したデザインは、2つのルートでGoogle Antigravityに渡せます。

### ルートA：Stitch MCP直結（推奨）

Stitch MCPを使えば、Figmaを経由せずStitchの出力を直接Antigravityに接続できます。

**セットアップ手順**

```bash
npx @_davideast/stitch-mcp init
# 対話式セットアップが起動
# クライアント選択 → 「Antigravity」を選択
# Google Cloud認証を完了
```

セットアップウィザードではAntigravityがデフォルトの第一選択肢として表示されます。

**Stitch Skillsのインストール**

Google公式が提供するStitch Skillsで、StitchのデザインデータをAntigravityがより正確に解釈できるようになります。

```bash
npx add-skill google-labs-code/stitch-skills \
  --skill react:components --global
```

利用可能なスキル：`design-md`、`react:components`、`stitch-loop`、`enhance-prompt`

### ルートB：Figma経由

StitchからFigmaにエクスポートし（Paste to Figma）、デザインを微調整してからAntigravityに渡すルートです。

**FigmaでのAIフレンドリーなデザイン整理**

StitchからFigmaにペーストしたデザインは、以下の整理を行うとAntigravityの読み取り精度が向上します。

**1. Auto Layoutの適用**

Figma MCPは[Auto Layout](https://help.figma.com/hc/en-us/articles/360040451373-Guide-to-auto-layout)（CSSのFlexboxに相当）で構造化された要素の読み取り精度が高いです。主要なセクションをAuto Layoutに変換します（`Shift + A`）。

**2. レイヤー名のセマンティック化**

```
❌ Frame 48 > Group 12 > Text
✅ header > nav-menu > menu-item-blog
```

**3. テンプレート別フレームの整理**

```
📁 My WordPress Theme
  ├── 🖼 front-page（フロントページ）
  ├── 🖼 archive（物件一覧）
  ├── 🖼 single（物件詳細）
  ├── 🖼 page（事業内容等の固定ページ）
  ├── 🖼 header（共通ヘッダー）
  └── 🖼 footer（共通フッター）
```

**Figma MCPのセットアップ（Antigravity）**

AntigravityへのFigma MCP導入は簡単です。

1. Antigravityエディタ → 右上「...」メニュー → MCP Servers
2. MCP Storeから「Figma MCP」をインストール

手動でJSON設定ファイルを編集する必要はありません。

## 業種カスタマイズテンプレート

上記は不動産業者の例ですが、以下のテンプレートの `[  ]` 部分を自分の業種に置き換えれば、どんな業種でも同じ手順でテーマを作れます。

### フロントページ用テンプレート

```
Web向け。[業種名]のコーポレートサイト トップページ。
事業内容：[事業①]、[事業②]、[事業③]...
レイアウト：
- 上部にロゴとナビゲーションメニュー（[メニュー項目をカンマ区切り]）
- ヒーローセクション（「[キャッチコピー]」＋[主要CTAボタンの文言]）
- 事業紹介セクション：[N]つの事業をアイコン付きカードで横並び表示
- [メインコンテンツの説明：例「新着実績3件をカード型で表示」]
- [信頼要素：例「お客様の声」「取引実績」「資格・認定」]
- フッターに[フッター要素]
配色：[メインカラー]に[テキストカラー]、アクセントカラーは[アクセント]
雰囲気：[2〜3語のキーワード：例「清潔感・安心・プロフェッショナル」]
ターゲット：[想定ユーザー]
```

### 一覧ページ用テンプレート

```
Web向け。[業種名]の[一覧コンテンツ名：例「施工事例一覧」「メニュー一覧」]ページ。
レイアウト：
- 共通ヘッダー（ロゴ＋ナビ）
- [フィルター要素：例「カテゴリ、エリア、価格帯で絞り込み」]
- メインエリア（幅70%）：[カード内容]を縦に6件
- 右サイドバー（幅30%）：[サイドバー要素]
- ページネーション
- 共通フッター
配色：前の画面と同じテーマカラーを維持
```

### 詳細ページ用テンプレート

```
Web向け。[業種名]の[詳細コンテンツ名：例「施工事例詳細」「商品詳細」]ページ。
レイアウト：
- 共通ヘッダー
- パンくずリスト（ホーム > [カテゴリ] > [個別名]）
- [メインビジュアル：例「施工写真ギャラリー」「商品画像」]
- [基本情報テーブル：例「工期、費用、面積」「価格、サイズ、素材」]
- [本文・説明エリア]
- [CTA：例「無料見積もりを依頼する」「カートに入れる」]
- 右サイドバー：[サイドバー要素]
- 共通フッター
配色：同じテーマカラー
```

### 業種別の記入例

| 業種 | 一覧ページ | 詳細ページ | CTA |
|---|---|---|---|
| 工務店 | 施工事例一覧 | 施工事例詳細 | 無料見積もりを依頼する |
| 飲食店 | メニュー一覧 | メニュー詳細 | 来店予約する |
| 美容室 | スタイル一覧 | スタイル詳細 | このスタイルで予約する |
| 税理士事務所 | サービス一覧 | サービス詳細 | 無料相談を申し込む |
| 整体院 | 施術メニュー一覧 | 施術メニュー詳細 | 初回体験を予約する |

## 参考サイトのURL・スクリーンショットを活用する

Google Stitchで生成したデザインだけでなく、**既存の参考サイトのURLやスクリーンショットをGoogle Antigravityに直接渡して、デザインの方向性を指示する**ことも可能です。

### 方法1：参考サイトのURLを渡す

Antigravityのブラウザエージェントは、指定したURLを実際に訪問してページ構造やデザインを解析できます。

```
以下のサイトをブラウザで確認し、デザインの特徴を分析してください。
https://example.com

このサイトの以下の要素を参考にして、WordPressテーマのheader.phpを生成してください：
- ナビゲーションメニューの配置とスタイル
- ヒーローセクションのレイアウト
- カラースキームとフォントの雰囲気
```

### 方法2：スクリーンショットをワークスペースに配置する

参考にしたいサイトのスクリーンショットを撮影し、PNG/JPG形式でAntigravityのプロジェクトフォルダに配置します。

```bash
# プロジェクトフォルダに参考画像用のディレクトリを作成
mkdir -p my-stitch-theme/references

# スクリーンショットを配置（例）
# references/archive-page-ref.png
# references/header-ref.png
```

Antigravityのチャットで以下のように指示します。

```
references/archive-page-ref.png を参照してください。
このスクリーンショットのデザインを参考にして、archive.phpを生成してください。

参考にする要素：
- 記事カードのレイアウト（アイキャッチの比率、テキスト配置）
- サイドバーのウィジェット構成
- 全体のカラースキーム

ただし、以下はStitch MCPから取得したデザインデータに従ってください：
- ヘッダー・フッターのデザイン
- フォントファミリー
```

### 方法3：複数の参考サイトを組み合わせる

複数サイトのスクリーンショットをワークスペースに配置し、要素ごとに異なる参考画像を指定できます。

```
以下の参考画像を確認し、各要素を組み合わせたWordPressテーマを設計してください。

- ヘッダーの参考：references/header-ref.png
- 記事一覧（物件一覧）の参考：references/archive-ref.png
- フッターの参考：references/footer-ref.png

Stitch MCPから取得したカラースキームとフォント設定は維持してください。
```

:::message alert
**注意：参考サイトの活用はあくまで「インスピレーション」として**
既存サイトのデザインをそのまま複製することは著作権の観点から避けてください。レイアウトの構成やカラースキームの方向性など、抽象的な要素を参考にするのが適切です。
:::

## 次の記事へ

Google Stitchでデザインを生成し、Google Antigravityに渡す準備ができました。次は実際にPHPテンプレートを自動生成するステップに進みましょう。

**次の記事**: [コードを書かずにPHPテンプレートを作る：Google Antigravity活用ガイド](https://zenn.dev/komei/articles/wordpress-ai-theme-antigravity)

## まとめ

- Google Stitchでは、WordPressのテンプレート階層を意識したプロンプト設計が重要
- プロンプトは「用途・レイアウト・配色・雰囲気・ターゲット」の5要素で構成
- 業種カスタマイズテンプレートを使えば、どんな業種でも応用可能
- Stitch MCP直結ルートが最短、Figma経由ルートは微調整が必要な場合に有効
- 参考サイトのURLやスクリーンショットでデザインの方向性を補強できる

## 参考リンク

**Google Stitch**

- [Google Stitch 公式](https://stitch.withgoogle.com/)
- [Stitch 2.0 ガイド](https://www.aifire.co/p/google-stitch-2-0-a-guide-to-the-free-ai-coding-design-agent)
- [Stitch MCP（npm）](https://www.npmjs.com/package/@_davideast/stitch-mcp)
- [Stitch MCP（GitHub）](https://github.com/davideast/stitch-mcp)
- [Stitch Skills（GitHub）](https://github.com/google-labs-code/stitch-skills)

**Figma**

- [Figma Auto Layout ガイド](https://help.figma.com/hc/en-us/articles/360040451373-Guide-to-auto-layout)
- [Figma MCP公式ガイド](https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Figma-MCP-server)
