---
title: "WordPress × Google Antigravity：AI生成コードのセキュリティを固めた"
emoji: "🛡️"
type: "tech"
topics: ["wordpress", "security", "phpcs", "blocktheme", "ai"]
published: false
---

:::message
**シリーズ構成：AIでWordPressテーマを自作する**
1. [有料テーマを買わない選択肢：Google Stitch × Google AntigravityでWordPressテーマを自作する](wordpress-ai-theme-overview)
2. [StitchでテーマのUIを作った](wordpress-ai-theme-stitch)
3. [デザインからPHPテンプレートを自動生成した](wordpress-ai-theme-antigravity)
4. **AI生成コードのセキュリティを固めた**（この記事）
5. [記事の執筆から投稿までを自動化した](wordpress-ai-theme-automation)
:::

## 基本チェックリスト

AI生成コードは「80点のたたき台」。残りの20点をチェック・修正することで、本番運用に耐えるテーマになる。まずは最低限必要な要素が揃っているかを確認する。

### セマンティックHTMLチェック

- [ ] H1タグが各ページに1つだけ存在するか
- [ ] `<header>`, `<main>`, `<article>`, `<aside>`, `<footer>` を適切に使用しているか
- [ ] 画像に `alt` 属性が設定されているか
- [ ] ナビゲーションに `<nav>` タグを使用しているか

### WordPressテンプレートタグの検証

- [ ] `wp_head()` が `</head>` の直前にあるか
- [ ] `wp_footer()` が `</body>` の直前にあるか
- [ ] `wp_body_open()` が `<body>` タグの直後にあるか
- [ ] `language_attributes()` が `<html>` タグに設定されているか
- [ ] `bloginfo('charset')` が `<meta charset>` に使用されているか

## WordPress Coding Standards によるコード品質チェック

WordPressには公式のコーディング規約（[WordPress Coding Standards](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/)）がある。AI生成コードがこの規約に準拠しているかを、PHP_CodeSnifferと[WPCS（WordPress Coding Standards）](https://github.com/WordPress/WordPress-Coding-Standards)パッケージで自動チェックできる。

### PHP_CodeSniffer のセットアップ

```bash
# Composerでインストール（Packagist: https://packagist.org/packages/wp-coding-standards/wpcs）
composer require --dev wp-coding-standards/wpcs dealerdirect/phpcodesniffer-composer-installer

# ルールセットの確認
./vendor/bin/phpcs -i
# 出力例: WordPress, WordPress-Core, WordPress-Docs, WordPress-Extra
```

### コードチェックの実行

```bash
# テーマ全体をチェック
./vendor/bin/phpcs --standard=WordPress ./my-stitch-theme/

# 特定ファイルをチェック
./vendor/bin/phpcs --standard=WordPress ./my-stitch-theme/functions.php
```

### よくある指摘と修正例

| 指摘内容 | 修正前 | 修正後 |
|---|---|---|
| インデントはタブを使用 | スペース4つ | タブ1つ |
| Yoda条件式を使用 | `if ($var == 'value')` | `if ('value' === $var)` |
| エスケープ不足 | `echo $title;` | `echo esc_html($title);` |
| 翻訳関数を使用 | `'Submit'` | `__('Submit', 'my-theme')` |

### 自動修正の実行

```bash
# 自動修正可能な問題を修正
./vendor/bin/phpcbf --standard=WordPress ./my-stitch-theme/
```

:::message
**Google Antigravityへの指示例**
```
WordPress Coding Standards に準拠するように、以下のファイルを修正してください。
- インデントはスペースではなくタブを使用
- Yoda条件式を使用（変数を右側に）
- 出力はすべてエスケープ関数を通す
- 文字列は翻訳関数で囲む
```
:::

## セキュリティ対策

AI生成コードはセキュリティ面で脆弱になりがちだ。以下の対策を必ず確認する。

### 出力のエスケープ（Escaping）

ユーザー入力やデータベースから取得した値を出力する際は、必ず[エスケープ関数](https://developer.wordpress.org/apis/security/escaping/)を使用する。

```php
// ❌ 危険：XSS脆弱性
echo $user_input;
echo $title;

// ✅ 安全：エスケープ済み
echo esc_html($user_input);      // HTMLコンテキスト
echo esc_attr($title);           // HTML属性
echo esc_url($link);             // URL
echo esc_js($script);            // JavaScript
echo wp_kses_post($content);     // 許可されたHTMLタグのみ
```

### 入力のサニタイズ（Sanitization）

フォームやクエリパラメータから受け取った値は、保存前に[サニタイズ](https://developer.wordpress.org/apis/security/sanitizing/)する。

```php
// ❌ 危険：SQLインジェクション、XSSの可能性
$search = $_GET['s'];
update_post_meta($post_id, 'key', $_POST['value']);

// ✅ 安全：サニタイズ済み
$search = sanitize_text_field($_GET['s']);
$value = sanitize_text_field($_POST['value']);
update_post_meta($post_id, 'key', $value);
```

### Nonce検証（CSRF対策）

フォーム送信やAjaxリクエストでは、Nonceを使用して正当なリクエストかを検証する。

```php
// フォームにNonceフィールドを追加
wp_nonce_field('my_action', 'my_nonce');

// 処理側でNonceを検証
if (!wp_verify_nonce($_POST['my_nonce'], 'my_action')) {
    wp_die('不正なリクエストです');
}
```

### データベースクエリの安全な書き方

```php
// ❌ 危険：SQLインジェクション
$query = "SELECT * FROM $wpdb->posts WHERE post_title = '$title'";

// ✅ 安全：プリペアドステートメント
$query = $wpdb->prepare(
    "SELECT * FROM $wpdb->posts WHERE post_title = %s",
    $title
);
```

### セキュリティチェックリスト

- [ ] すべての出力がエスケープされているか
- [ ] すべての入力がサニタイズされているか
- [ ] フォーム送信にNonce検証があるか
- [ ] データベースクエリが `$wpdb->prepare()` を使用しているか
- [ ] ファイルアップロードが適切に検証されているか
- [ ] `eval()` や `create_function()` を使用していないか
- [ ] `$_GET`, `$_POST`, `$_REQUEST` を直接使用していないか

## Gutenberg（ブロックエディタ）対応

Google Stitchが生成した「カード型レイアウト」や「CTAセクション」を、ブロックパターンとして登録しておくと運用が楽になる。

### ブロックパターンの登録

```php
// functions.php に追加
function my_stitch_register_patterns() {
    register_block_pattern(
        'my-stitch-theme/cta-section',
        array(
            'title'       => 'CTAセクション',
            'description' => 'お問い合わせを促すCTAセクション',
            'categories'  => array('buttons'),
            'content'     => '<!-- wp:group {"className":"cta-section"} -->
                <div class="wp-block-group cta-section">
                    <!-- wp:heading -->
                    <h2>お問い合わせはこちら</h2>
                    <!-- /wp:heading -->
                    <!-- wp:buttons -->
                    <div class="wp-block-buttons">
                        <!-- wp:button -->
                        <div class="wp-block-button">
                            <a class="wp-block-button__link">お問い合わせ</a>
                        </div>
                        <!-- /wp:button -->
                    </div>
                    <!-- /wp:buttons -->
                </div>
                <!-- /wp:group -->',
        )
    );
}
add_action('init', 'my_stitch_register_patterns');
```

### ブロックパターンカテゴリの追加

```php
function my_stitch_register_pattern_categories() {
    register_block_pattern_category(
        'my-stitch-theme',
        array('label' => 'My Stitch Theme')
    );
}
add_action('init', 'my_stitch_register_pattern_categories');
```

## ブロックテーマへの移行

現在のクラシックテーマ（PHPテンプレート）から、WordPress 5.9以降で導入されたブロックテーマ（フルサイト編集）への移行も視野に入れておく。

### ブロックテーマの構成

```
my-stitch-theme/
├── style.css
├── functions.php
├── templates/           # ブロックテンプレート
│   ├── index.html
│   ├── front-page.html
│   ├── single.html
│   ├── archive.html
│   └── page.html
├── parts/               # テンプレートパーツ
│   ├── header.html
│   ├── footer.html
│   └── sidebar.html
└── theme.json           # グローバルスタイル設定
```

### theme.json の基本設定

[theme.json](https://developer.wordpress.org/block-editor/reference-guides/theme-json-reference/)はブロックテーマのグローバルスタイル設定ファイルだ。

```json
{
    "$schema": "https://schemas.wp.org/trunk/theme.json",
    "version": 3,
    "settings": {
        "color": {
            "palette": [
                {
                    "slug": "primary",
                    "color": "#1B2A4A",
                    "name": "Primary"
                },
                {
                    "slug": "accent",
                    "color": "#C4704A",
                    "name": "Accent"
                }
            ]
        },
        "typography": {
            "fontFamilies": [
                {
                    "fontFamily": "'Noto Sans JP', sans-serif",
                    "slug": "body",
                    "name": "Body"
                }
            ]
        },
        "layout": {
            "contentSize": "800px",
            "wideSize": "1200px"
        }
    }
}
```

### クラシック→ブロックテーマ移行のメリット

| 項目 | クラシックテーマ | ブロックテーマ |
|---|---|---|
| 編集方法 | PHP直接編集 | サイトエディター（GUI） |
| カスタマイズ性 | コード知識必須 | ノーコードで可能 |
| パフォーマンス | テーマ依存 | 最適化されている |
| 将来性 | レガシー | WordPress推奨 |

:::message
**Google Antigravityへの指示例**
```
現在のクラシックテーマをブロックテーマに変換してください。
- PHPテンプレートをHTMLテンプレートに変換
- theme.json でグローバルスタイルを定義
- テンプレートパーツ（header, footer）を作成
```
:::

## SEO最適化

テーマレベルでのSEO対策も重要だ。

### 構造化データの追加

[Schema.org](https://schema.org/)の構造化データを追加すると、検索エンジンがコンテンツを理解しやすくなる。

```php
// functions.php に追加
function my_stitch_add_schema() {
    if (is_single()) {
        global $post;
        $schema = array(
            '@context' => 'https://schema.org',
            '@type' => 'Article',
            'headline' => get_the_title(),
            'datePublished' => get_the_date('c'),
            'dateModified' => get_the_modified_date('c'),
            'author' => array(
                '@type' => 'Person',
                'name' => get_the_author()
            )
        );
        echo '<script type="application/ld+json">' . wp_json_encode($schema) . '</script>';
    }
}
add_action('wp_head', 'my_stitch_add_schema');
```

### パンくずリストの実装

```php
function my_stitch_breadcrumb() {
    echo '<nav class="breadcrumb" aria-label="パンくずリスト">';
    echo '<ol itemscope itemtype="https://schema.org/BreadcrumbList">';

    // ホーム
    echo '<li itemprop="itemListElement" itemscope itemtype="https://schema.org/ListItem">';
    echo '<a itemprop="item" href="' . esc_url(home_url()) . '">';
    echo '<span itemprop="name">ホーム</span></a>';
    echo '<meta itemprop="position" content="1" /></li>';

    // カテゴリ・ページ階層を追加...

    echo '</ol></nav>';
}
```

## パフォーマンス最適化

### 画像の遅延読み込み

WordPress 5.5以降は自動で `loading="lazy"` が付与されるが、明示的に指定することもできる。

```php
// functions.php に追加
function my_stitch_lazy_load_images($content) {
    return preg_replace(
        '/<img(.*?)>/i',
        '<img$1 loading="lazy">',
        $content
    );
}
add_filter('the_content', 'my_stitch_lazy_load_images');
```

### CSS/JSの最適化

```php
// 不要なスクリプトを削除
function my_stitch_dequeue_scripts() {
    // 例：絵文字スクリプトを無効化
    remove_action('wp_head', 'print_emoji_detection_script', 7);
    remove_action('wp_print_styles', 'print_emoji_styles');
}
add_action('init', 'my_stitch_dequeue_scripts');
```

## 品質チェック自動化

Google Antigravityに品質チェックを依頼するプロンプト例。

```
このWordPressテーマの品質チェックを行ってください。

確認項目：
1. セマンティックHTMLの使用状況
2. WordPressテンプレートタグの正確性
3. セキュリティ（エスケープ、サニタイズ、Nonce）
4. WordPress Coding Standards への準拠
5. アクセシビリティ（ARIA属性、キーボードナビゲーション）
6. SEO（構造化データ、メタタグ）

問題点を一覧で報告し、修正コードを提案してください。
```

## 参考リンク

**WordPress公式ドキュメント**

- [WordPress Coding Standards](https://developer.wordpress.org/coding-standards/wordpress-coding-standards/)
- [WordPress Theme Security](https://developer.wordpress.org/themes/security/)
- [Escaping Data](https://developer.wordpress.org/apis/security/escaping/)
- [Sanitizing Input](https://developer.wordpress.org/apis/security/sanitizing/)
- [Block Theme Developer Guide](https://developer.wordpress.org/block-editor/how-to-guides/themes/)
- [theme.json Reference](https://developer.wordpress.org/block-editor/reference-guides/theme-json-reference/)

**ツール**

- [WPCS（GitHub）](https://github.com/WordPress/WordPress-Coding-Standards)
- [WPCS（Packagist）](https://packagist.org/packages/wp-coding-standards/wpcs)
- [Google Antigravity IDE](https://antigravity.google/)

**その他**

- [Schema.org](https://schema.org/)
