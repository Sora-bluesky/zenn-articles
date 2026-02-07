---
title: "WordPress × Google Antigravity：デザインからPHPテンプレートを自動生成した"
emoji: "🚀"
type: "tech"
topics: ["antigravity", "wordpress", "php", "ai", "mcp"]
published: false
---

:::message
**シリーズ構成：AIでWordPressテーマを自作する**
1. [有料テーマを買わない選択肢：Google Stitch × Google AntigravityでWordPressテーマを自作する](https://zenn.dev/komei/articles/wordpress-ai-theme-overview)
2. [StitchでテーマのUIを作った](https://zenn.dev/komei/articles/wordpress-ai-theme-stitch)
3. **デザインからPHPテンプレートを自動生成した**（この記事）
4. [AI生成コードのセキュリティを固めた](https://zenn.dev/komei/articles/wordpress-ai-theme-quality)
5. [記事の執筆から投稿までを自動化した](https://zenn.dev/komei/articles/wordpress-ai-theme-automation)
:::

## 環境構築

### 必要なツール

| ツール | 用途 |
|---|---|
| [Google Antigravity](https://antigravity.google/) | AIファーストIDE |
| [Node.js](https://nodejs.org/) v18以上 | Playground CLIの実行に必要 |
| [@wp-playground/cli](https://www.npmjs.com/package/@wp-playground/cli) | ローカルWordPress環境（[GitHub](https://github.com/WordPress/wordpress-playground)） |

### Playground CLI でWordPressを起動

```bash
npx @wp-playground/cli@latest server --auto-mount --login
```

WordPress Playground CLIは、WordPress公式プロジェクトが提供するローカル開発環境。Docker不要で、コマンド一発でWordPressが起動する。`--auto-mount` はカレントディレクトリのテーマやプラグインを自動検出してマウントし、`--login` は管理者として自動ログインした状態でブラウザが開く。

:::message
`wp-now`（`@wp-now/wp-now`）は非推奨（deprecated）になった。後継が`@wp-playground/cli`で、機能はほぼ同じだがバグ修正や新機能は今後こちらにのみ追加される。参考：[GitHub Issue #2224](https://github.com/WordPress/wordpress-playground/issues/2224)
:::

## テーマのディレクトリ構成を準備

テーマフォルダを作成し、Playground CLIで起動できる状態にする。

```bash
mkdir -p my-stitch-theme/assets/css
cd my-stitch-theme
```

### 必要なファイル構成

```
my-stitch-theme/
├── style.css          # テーマ情報ヘッダー（必須）
├── functions.php      # テーマ機能の定義
├── index.php          # フォールバックテンプレート
├── front-page.php     # トップページ
├── page.php           # 固定ページ
├── single.php         # 個別記事ページ
├── archive.php        # 一覧ページ
├── header.php         # 共通ヘッダー
├── footer.php         # 共通フッター
├── sidebar.php        # サイドバー
└── assets/
    └── css/
        └── theme.css  # スタイルシート
```

### style.css の作成

`style.css` の先頭に必須のテーマヘッダーを記述する。これがないとWordPressがテーマとして認識しない（[Theme Handbook - Main Stylesheet](https://developer.wordpress.org/themes/basics/main-stylesheet-style-css/)）。

```css
/*
Theme Name: My Stitch Theme
Theme URI: https://example.com
Author: Your Name
Description: Google Stitch × Google Antigravityで生成したオリジナルテーマ
Version: 1.0.0
License: GNU General Public License v2 or later
Text Domain: my-stitch-theme
*/
```

## PHPテンプレート生成

以下のファイルをGoogle Antigravityに生成させる。

| 生成するファイル | 対応するStitch画面 | 主要なWordPress関数 |
|---|---|---|
| header.php | 共通ヘッダー部分 | `wp_head()`, `wp_nav_menu()`, `the_custom_logo()` |
| archive.php | 物件一覧ページ | `have_posts()`, `the_post_thumbnail()`, `get_post_meta()` |
| single.php | 物件詳細ページ | `the_title()`, `the_content()`, `get_post_meta()` |
| page.php | 事業内容ページ | `the_title()`, `the_content()`, `wp_list_pages()` |

Antigravityのチャットに以下のプロンプトを順に入力する。

### header.php を生成する

```
Stitch MCPから取得したデザインデータを参照して、WordPressの header.php を生成してください。

要件：
- <!DOCTYPE html> から <body <?php body_class(); ?>> まで含める
- wp_head() を </head> の直前に配置
- ナビゲーションメニューは wp_nav_menu() を使用（theme_location => 'primary'）
  メニュー項目：ホーム、事業内容、物件情報、お知らせ、会社概要、お問い合わせ
- ロゴ部分は the_custom_logo() を使用
- ヘッダー右上に電話番号と営業時間を表示するエリアを配置
- セマンティックHTML（<header>, <nav>）を使用
- CSSクラスはデザインを反映
```

### archive.php を生成する

```
物件一覧ページのデザインデータを参照して、archive.php を生成してください。

要件：
- get_header() と get_footer() で共通部分を読み込む
- 物件一覧は WordPress標準ループ（while have_posts() : the_post()）で実装
- 各物件カードには the_post_thumbnail(), the_title() を使用
- カスタムフィールドで賃料、間取り、所在地、築年数を表示（get_post_meta()）
- サイドバーは get_sidebar() で読み込む
- ページネーションは the_posts_pagination() を使用
- CSSクラスとレイアウトはデザインに合わせる
```

### single.php を生成する

```
物件詳細ページのデザインデータを参照して、single.php を生成してください。

要件：
- get_header() と get_footer() で共通部分を読み込む
- パンくずリストはカスタム関数またはプラグイン（Yoast SEO等）前提でOK
- 物件名は the_title()、説明文は the_content()
- 物件概要テーブル：カスタムフィールドから賃料、管理費、間取り、面積、築年数、構造、駐車場、入居可能日を取得（get_post_meta()）
- アイキャッチ画像は the_post_thumbnail('large')
- 「この物件について問い合わせる」CTAボタンを目立つ位置に配置
- サイドバーは get_sidebar() で読み込む
```

### page.php を生成する

```
事業内容ページのデザインデータを参照して、page.php を生成してください。

要件：
- get_header() と get_footer() で共通部分を読み込む
- ページタイトルは the_title()、本文は the_content()
- 固定ページテンプレートとして汎用的に使えるようにする
- 子ページがある場合はサブナビゲーションを表示（wp_list_pages()）
- セマンティックHTML（<main>, <article>, <section>）を使用
```

:::message
Antigravityならではの強みが2つある。
- Agent Managerで複数テンプレートを並列生成できる（header.php、archive.php、single.php、page.phpを同時に走らせられる）
- ブラウザエージェントでWordPressサイトを自動巡回し、レイアウト崩れを検出→修正できる
:::

## functions.php の実装

Antigravityに生成させることもできるが、バックエンドロジックはプロンプトで要件を明示するのがコツ。以下のコードをベースに、Antigravityで不足分を追加生成する。

```php
<?php
/**
 * My Stitch Theme functions
 */

// テーマサポート機能の登録
function my_stitch_theme_setup() {
    // アイキャッチ画像を有効化
    add_theme_support('post-thumbnails');

    // タイトルタグの自動出力
    add_theme_support('title-tag');

    // カスタムロゴ
    add_theme_support('custom-logo', array(
        'height'      => 60,
        'width'       => 200,
        'flex-height' => true,
        'flex-width'  => true,
    ));

    // HTML5マークアップ
    add_theme_support('html5', array(
        'search-form', 'comment-form', 'comment-list',
        'gallery', 'caption', 'style', 'script'
    ));

    // ナビゲーションメニューの登録
    register_nav_menus(array(
        'primary' => 'メインメニュー',
        'footer'  => 'フッターメニュー',
    ));
}
add_action('after_setup_theme', 'my_stitch_theme_setup');

// スタイルシートとスクリプトの読み込み
function my_stitch_theme_scripts() {
    // Stitchが生成したCSSを読み込む
    wp_enqueue_style(
        'theme-style',
        get_template_directory_uri() . '/assets/css/theme.css',
        array(),
        '1.0.0'
    );

    // WordPress標準のstyle.css
    wp_enqueue_style(
        'main-style',
        get_stylesheet_uri(),
        array('theme-style'),
        '1.0.0'
    );
}
add_action('wp_enqueue_scripts', 'my_stitch_theme_scripts');

// ウィジェットエリアの登録
function my_stitch_theme_widgets() {
    register_sidebar(array(
        'name'          => 'サイドバー',
        'id'            => 'sidebar-1',
        'before_widget' => '<div class="widget %2$s">',
        'after_widget'  => '</div>',
        'before_title'  => '<h3 class="widget-title">',
        'after_title'   => '</h3>',
    ));
}
add_action('widgets_init', 'my_stitch_theme_widgets');
```

このコードで実装される機能：

- アイキャッチ画像の有効化
- タイトルタグの自動出力
- カスタムロゴ対応
- HTML5マークアップ
- ナビゲーションメニュー2箇所（メイン＋フッター）
- CSSの読み込み
- サイドバーウィジェットの登録

## Playground CLIでローカル検証

テーマフォルダで以下を実行すると、WordPressが起動してブラウザが自動で開く。

```bash
npx @wp-playground/cli@latest server --auto-mount --login
```

`--auto-mount` がテーマフォルダを自動検出し、`wp-content/themes/` にマウントする。

### 修正が必要な場合

表示に問題があれば、Antigravityのチャットで追加指示を出す。

```
header.phpのナビゲーションが横並びになっていない。
ブラウザでWordPressサイトを確認して、CSSのFlexboxで横並びレイアウトに修正してください。
```

Antigravityのブラウザエージェントは、実際にWordPressサイトを開いて視覚的に確認しながら修正する。人間が目で確認→指示→修正のループを回すより早い。

## 現実的な期待値

AI生成コードは「80点のたたき台」と捉える。

| 項目 | 自動化できる割合 | 手動作業が必要な部分 |
|---|---|---|
| HTML構造 | 約80% | セマンティックタグの調整 |
| CSSスタイリング | 約70% | レスポンシブ・フォント調整 |
| PHPテンプレートタグ | 約60% | WordPress固有関数の正確な配置 |
| functions.php | 約30% | AI生成可能だが要検証 |
| **全体** | **約55〜65%** | **残りは手動調整** |

ゼロから書くよりは圧倒的に早い。残りの調整は次の記事で扱うセキュリティ・品質チェックでカバーする。

### よくある修正ポイント

| 問題 | 対処法 |
|---|---|
| `wp_head()` の位置が違う | `</head>` の直前に移動 |
| `wp_footer()` がない | `</body>` の直前に追加 |
| `body_class()` がない | `<body>` タグに追加 |
| メニューが表示されない | `register_nav_menus()` の設定を確認 |
| アイキャッチが表示されない | `add_theme_support('post-thumbnails')` を確認 |

## footer.php と sidebar.php

header.phpと同様に、footer.phpとsidebar.phpも生成させる。

### footer.php を生成する

```
共通フッターのデザインデータを参照して、footer.php を生成してください。

要件：
- </body> と </html> を含める
- wp_footer() を </body> の直前に配置
- フッターメニューは wp_nav_menu() を使用（theme_location => 'footer'）
- 会社情報（所在地、電話番号、営業時間）を表示
- コピーライト表記
- プライバシーポリシーへのリンク
- セマンティックHTML（<footer>）を使用
```

### sidebar.php を生成する

```
サイドバーのデザインデータを参照して、sidebar.php を生成してください。

要件：
- dynamic_sidebar('sidebar-1') でウィジェットエリアを読み込む
- ウィジェットがない場合のフォールバック表示
- セマンティックHTML（<aside>）を使用
```

## 参考リンク

**ツール**

- [Google Antigravity IDE](https://antigravity.google/)
- [@wp-playground/cli（npm）](https://www.npmjs.com/package/@wp-playground/cli)
- [WordPress Playground（GitHub）](https://github.com/WordPress/wordpress-playground)

**WordPress公式ドキュメント**

- [Theme Developer Handbook](https://developer.wordpress.org/themes/)
- [Template Hierarchy](https://developer.wordpress.org/themes/basics/template-hierarchy/)
- [Main Stylesheet（style.css）](https://developer.wordpress.org/themes/basics/main-stylesheet-style-css/)
- [テーマ関数リファレンス](https://developer.wordpress.org/themes/basics/theme-functions/)
