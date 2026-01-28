---
title: "Google Antigravity インストールガイド（Windows）"
emoji: "🚀"
type: "tech"
topics: ["ai", "windows", "生成ai", "個人開発", "llm"]
published: true
---

## はじめに

Windows環境でGoogle Antigravityをセットアップする手順をまとめた。
非エンジニアでもできるように、すべての操作をステップごとに説明する。

:::message
**シリーズ構成**
- **非エンジニア向け Google Antigravity インストールガイド**（この記事）
- [【非エンジニア×AI開発】Google Antigravity × Codex CLI でデュアルエージェント開発](antigravity-codex-dual-agent-guide)
- [Antigravityを安全に使うために知っておくべきこと](antigravity-security-guide)
:::

---

## Google Antigravityとは

Google Antigravity は、Google が開発した **AIコーディングアシスタント**。
ターミナル（黒い画面）で動作し、チャットで指示を出すとファイルの作成・編集・コード実行などを自動でやってくれる。

内部では Google の AI モデル「**Gemini**」が使われている。

:::message
**Claude Code との違い**
Claude Code は Anthropic 社の Claude を使用、Antigravity は Google の Gemini を使用している。
どちらも「AIにコードを書いてもらう」という目的は同じだが、使用するAIが異なる。
:::

---

## 料金プラン

Google Antigravity には2つのプランがある。

| プラン | 料金 | 内容 |
|--------|------|------|
| **Free Preview** | 無料 | 基本機能が使える。利用制限あり |
| **Google AI Pro** | $19.99/月 | 利用制限が緩和される |

:::message
**無料でまず試せる**
Free Preview でも基本的な機能は使える。まずは無料で試してみて、気に入ったら有料プランを検討するのがおすすめ。
:::

---

## 動作環境

Google Antigravity を使うために必要なもの：

- **Windows 10 以降**
- **Google アカウント**（Gmail があれば持っている）
- **インターネット接続**

:::message
Windows 10 より前のバージョン（Windows 7 や 8）では動作しない。
:::

---

## インストール手順

### Step 1：ダウンロード

1. ブラウザで以下の公式サイトにアクセス：
   **https://antigravity.google/download**

2. 「**Download for Windows**」ボタンをクリック

3. `AntigravitySetup.exe` というファイルがダウンロードされる

:::message
ダウンロード先は通常「ダウンロード」フォルダ。
見つからない場合は、ブラウザの下部やダウンロード履歴を確認する。
:::

---

### Step 2：インストール

1. ダウンロードした `AntigravitySetup.exe` をダブルクリック

2. **Windows SmartScreen の警告が出た場合**：

   ```
   Windows によって PC が保護されました
   ```

   以下の手順で進める：
   - 「**詳細情報**」をクリック
   - 「**実行**」をクリック

:::message alert
**SmartScreen 警告について**
これは「あまり知られていないアプリです」という警告であり、ウイルスという意味ではない。
Google の公式サイトからダウンロードしたファイルであれば問題なく実行できる。
:::

3. 「このアプリがデバイスに変更を加えることを許可しますか？」と聞かれたら「**はい**」

4. インストーラーが起動したら、「**Install**」をクリック

5. インストールが完了したら「**Close**」をクリック

---

### Step 3：初回起動と設定

1. スタートメニューから「**Antigravity**」を検索して起動

   または、デスクトップにショートカットができていればそれをダブルクリック

2. 初回起動時、 **エージェントモードの選択** 画面が表示される：

   ```
   Select agent mode:

   > 1. Review-driven (recommended)
     2. Full auto
     3. Manual
   ```

   **「1. Review-driven」を選択**して Enter を押す。

:::message
**エージェントモードとは？**
AIがどの程度自動で操作するかの設定。

| モード | 説明 |
|--------|------|
| **Review-driven**（おすすめ） | 重要な操作は毎回確認してから実行する。安全で初心者向け |
| **Full auto** | AIが自動で操作を進める。操作に慣れてから使う |
| **Manual** | すべての操作を手動で承認する。最も慎重な設定 |

初めて使う場合は **Review-driven** を選ぶのが安全。
:::

---

### Step 4：Google アカウントでログイン

1. 「**Sign in with Google**」の画面が表示される

2. ブラウザが自動的に開き、Google のログイン画面が表示される

3. 普段使っている **Google アカウント**（Gmail）でログイン

4. 「Antigravity がアクセスをリクエストしています」という画面が出たら「**許可**」をクリック

5. ブラウザに以下のメッセージが表示されたら成功：

   ```
   You're all set!
   You can now close this window and return to Antigravity.
   ```

6. ブラウザを閉じて、Antigravity のウィンドウに戻る

7. 以下のようなプロンプトが表示されたら起動完了：

   ```
   Antigravity v1.x.x
   Logged in as your-email@gmail.com

   >
   ```

---

## 動作確認

起動できたら、簡単な動作確認をしてみる。

プロンプト（`>` の後）に以下を入力して Enter：

```
hello.txt に「Hello, Antigravity!」と書いて
```

Antigravity が応答し、現在のフォルダに `hello.txt` ファイルが作成されれば成功。

終了するときは `/exit` と入力（または `Ctrl + C`）。

---

## 日本語で応答させる

Antigravity はデフォルトでは英語で応答することがある。日本語で応答させるには設定が必要。

### 設定方法

Antigravity を起動した状態で、以下のように入力する：

```
設定で言語を日本語にして
```

Antigravity が自動的に設定ファイルを作成・更新してくれる。

これで次回以降、日本語で応答するようになる。

:::message
**補足**
「常に日本語で応答して」と毎回指示する方法もあるが、設定ファイルに保存しておく方が楽。
:::

---

## トラブルシューティング

### 起動しない

| 症状 | 対策 |
|------|------|
| ダブルクリックしても何も起きない | PCを再起動してから再度試す |
| 「.NET が必要です」と表示される | 画面の指示に従って .NET をインストールする |
| エラーメッセージが出る | エラーメッセージをコピーして Google 検索する |

### ログインできない

| 症状 | 対策 |
|------|------|
| ブラウザが開かない | 手動でブラウザを開いて antigravity.google にアクセスし、ログインを試す |
| 「アカウントにアクセスできません」 | 別の Google アカウントで試す。または、Google アカウントの2段階認証を確認 |
| ログイン後、Antigravity に戻れない | Antigravity を一度閉じて、再度起動する |

### レート制限（Rate Limit）

```
Rate limit exceeded. Please wait and try again.
```

このエラーは「短時間に多くのリクエストを送りすぎた」という意味。

**対策**：
- 数分〜数十分待ってから再度試す
- Free Preview プランの場合、利用制限が厳しいため有料プランを検討する

:::message
**レート制限とは？**
サーバーへの負荷を防ぐため、一定時間内のリクエスト数に制限がかけられている。
これはエラーではなく、サービスを安定運用するための仕組み。
:::

---

## アップデート

Antigravity は自動でアップデートされる。

起動時に「新しいバージョンがあります」と表示されたら、画面の指示に従ってアップデートする。

手動でアップデートを確認したい場合は、公式サイト（antigravity.google）から最新版をダウンロードして再インストールする。

---

## アンインストール

Antigravity を削除したい場合：

1. **Windows キー** を押して「設定」を開く
2. 「**アプリ**」→「**インストールされているアプリ**」を選択
3. 一覧から「**Antigravity**」を探す
4. 右側の「**...**」（三点メニュー）をクリック
5. 「**アンインストール**」を選択
6. 確認画面で「**アンインストール**」をクリック

:::message
設定ファイルも完全に削除したい場合は、以下のフォルダも手動で削除する：
- `C:\Users\あなたの名前\.antigravity`

**フォルダの開き方**：
1. Windows キー + R を押す
2. `%USERPROFILE%\.antigravity` と入力して Enter
3. 表示されたフォルダを削除
:::

---

## 用語集

| 用語 | 説明 |
|------|------|
| **Gemini** | Google が開発した AI モデル。ChatGPT や Claude と同様の大規模言語モデル |
| **エージェントモード** | AI がどの程度自動で操作するかの設定 |
| **レート制限** | サーバー負荷を防ぐため、一定時間内のリクエスト数を制限する仕組み |
| **プロンプト** | AI に入力する指示や質問のこと |
| **ターミナル** | コマンドを入力する黒い画面の総称 |

---

## 参考リンク

- [Google Antigravity 公式サイト](https://antigravity.google)
- [Google Antigravity ダウンロード](https://antigravity.google/download)
- [Google AI Pro プラン詳細](https://ai.google.dev/pricing)

---

## 次のステップ

インストールが完了したら、次は実際に使ってみよう。

- [【非エンジニア×AI開発】Google Antigravity × Codex CLI でデュアルエージェント開発](antigravity-codex-dual-agent-guide)
