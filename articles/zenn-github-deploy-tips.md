---
title: "Zennの既存記事をGitHub連携で管理しようとしてハマったこと"
emoji: "🔧"
type: "tech"
topics: ["zenn", "github", "claudecode", "備忘録"]
published: true
---

## 結論

**GitHub連携して Claude Code から投稿するのがマジで楽。**

ただし、**Zennエディタで作成した既存記事は、GitHub連携では上書きできない**。

対処法は2つ：
1. 新規記事として公開する（別のslugで）
2. 既存記事を削除してから連携する

これを知らずに何度もデプロイエラーと戦った記録。

---

## この記事について

Claude Code シリーズの番外編として、Zenn × GitHub連携でハマったことをまとめた。

:::message
**関連記事：Claude Codeシリーズ**
- [非エンジニアがWindowsでClaude Codeを使えるようになるまで](claude-code-windows-install-guide)
- [Claude Codeを使いこなす！知っておきたい便利機能まとめ](claude-code-tips-and-features)
- [Claude Codeが動かない時に見るページ（Windows編）](claude-code-windows-troubleshoot)
- [AIにコードを書かせてAIにレビューさせる開発スタイル](claude-code-ai-review-workflow)
:::

---

## つまずいたこと

### 1. 既存記事が上書きできない

**やりたかったこと：**
Zennエディタで書いた記事を、GitHub連携で管理したい。

**やったこと：**
既存記事のslugをファイル名にして、フロントマターに `slug: xxx` を追加してpush。

**結果：**
```
slug の重複エラー
```

**原因：**
Zennエディタで作成した記事と、GitHub連携で作成した記事は**別管理**。
同じslugを使おうとすると重複扱いになる。

---

### 2. slugの仕組みを知らなかった

**やりたかったこと：**
わかりやすいファイル名（例：`claude-code-tips.md`）で管理したい。

**やったこと：**
フロントマターに `slug: f2260aa9006dd3` を追加。

**結果：**
まだ重複エラー。

**原因：**
Zennでは**ファイル名（拡張子除く）がslugになる**。
フロントマターの `slug:` は無視される場合がある。

---

### 3. ファイル名を変えても解決しない

**やりたかったこと：**
ファイル名を新しいslugに変更して公開。

**やったこと：**
`claude-code-tips.md` → `claude-code-tips-and-features.md` にリネーム。

**結果：**
まだエラー。

**原因：**
既存記事（エディタ作成）が残っている限り、同じ内容の記事は重複扱い。
**既存記事を削除してからpush**する必要があった。

---

## 事前に確認すべきだったこと

| 確認事項 | 理由 |
|----------|------|
| 既存記事の作成方法 | エディタ作成 vs GitHub連携で挙動が異なる |
| Zennのslug仕様 | **ファイル名 = slug** という仕様 |
| 上書きの可否 | エディタ作成記事はGitHub連携では上書き不可 |

:::message alert
**重要**
Zennエディタで作成した記事を GitHub 連携で管理したい場合は、**エディタ側の記事を削除してから**連携する。
:::

---

## 最終的な手順（成功パターン）

### Step 1: Zenn CLI セットアップ

```powershell
cd C:\Users\your-name\Documents\Projects\zenn-articles

# npm初期化
npm init -y

# Zenn CLIインストール
npm install zenn-cli
```

### Step 2: Git 初期化

```powershell
git init
```

### Step 3: GitHub リポジトリ作成 & push

**GitHub CLI を使う場合：**
```powershell
gh repo create zenn-articles --public --source=. --remote=origin --push
```

**手動でやる場合：**
1. https://github.com/new でリポジトリ作成
2. 以下を実行：

```powershell
git remote add origin https://github.com/your-name/zenn-articles.git
git branch -M main
git add .
git commit -m "Initial commit"
git push -u origin main
```

:::message
**認証エラーが出た場合**
Personal Access Token を使う。GitHub の Settings → Developer settings → Personal access tokens で作成。
:::

### Step 4: Zenn ダッシュボードで連携

1. https://zenn.dev/dashboard/deploys にアクセス
2. 「リポジトリを連携する」をクリック
3. 先ほど作成したリポジトリを選択
4. 「連携する」をクリック

### Step 5: 既存記事がある場合は削除

**重要：** エディタで作成した既存記事をGitHub連携で管理したい場合、**Zennエディタ側の記事を削除**する。

1. https://zenn.dev/dashboard にアクセス
2. 対象記事の「...」メニュー → 「記事を削除」

### Step 6: ファイル名をユニークに設定

```
articles/
  my-first-article.md      ← このファイル名がslugになる
  another-article.md
```

**注意：**
- ファイル名は12〜50文字
- 半角英数字（a-z, 0-9）とハイフン（-）、アンダースコア（_）のみ
- **わかりやすく、かつユニークな名前にする**

### Step 7: 公開

```powershell
# published: true に変更してから
git add .
git commit -m "Publish articles"
git push
```

---

## GitHub連携 + Claude Code の何が楽か

### 記事作成

```
> Zennの記事を書いて。タイトルは「〇〇」で。
```

→ ファイルが自動で作成される。

### 公開

```
> 公開して
```

→ `published: true` に変更 → git add → commit → push まで自動。

### 修正

```
> この部分、もう少しわかりやすく書き直して
```

→ 編集 → commit → push まで自動。

---

### Zennエディタとの比較

| 操作 | Zennエディタ | GitHub連携 + Claude Code |
|------|--------------|--------------------------|
| 記事作成 | 手動で書く | 「書いて」で生成 |
| 公開 | ボタンクリック | 「公開して」で完了 |
| 修正 | 手動で編集 | 「直して」で完了 |
| バージョン管理 | なし | Git で履歴が残る |
| 複数記事の一括操作 | 1記事ずつ | まとめて操作可能 |

**この記事自体も Claude Code で書いて push した。**

---

## 学んだこと

| 学び | 詳細 |
|------|------|
| 別管理だった | Zennエディタで作成した記事とGitHub連携は別管理 |
| 今後の方針 | 新規記事はGitHub連携で管理すると楽 |
| slug仕様 | **ファイル名 = slug** という仕様を覚えておく |
| 最強の組み合わせ | Claude Code + GitHub連携が最強の執筆環境 |

---

## まとめ

- Zennエディタで作成した記事は、GitHub連携では**上書きできない**
- 既存記事をGitHub管理したいなら、**エディタ側を削除してから**連携
- ファイル名 = slug なので、**わかりやすいユニークな名前**をつける
- Claude Code + GitHub連携 = **「書いて」「公開して」で完結する最強環境**

今後の記事はすべてGitHub連携で管理する予定。
