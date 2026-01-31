---
description: Mermaid図表を作成。「図を作って」「フローチャート」「シーケンス図」「アーキテクチャ図」で呼び出される。
triggers:
  - "図を作って"
  - "フローチャート"
  - "シーケンス図"
  - "アーキテクチャ図"
  - "mermaid"
---

# Mermaid Diagram スキル

Zenn記事向けのMermaid図表を作成する。

## 対応図表

| 図の種類 | 用途 | 非エンジニア向け |
|---------|------|----------------|
| シンプルフロー | 手順、プロセス | ◎ 推奨 |
| 比較図（Before/After） | 従来 vs 新方式 | ◎ 推奨 |
| アーキテクチャ図 | システム構成 | △ 簡略化必要 |
| シーケンス図 | 処理の流れ | △ 登場人物3人以内 |
| 状態遷移図 | 状態変化 | △ 状態5つ以内 |
| レイヤー構造図 | 階層関係 | × 避ける |
| ER図 | データ構造 | × 避ける |

## ディレクトリ構造

Mermaidではなくテキストツリーを使用する：

```
project/
├── src/
│   ├── index.js
│   └── utils/
└── package.json
```

## テンプレート

### 1. シンプルフロー（推奨）

```mermaid
flowchart LR
    A["ステップ1"] --> B["ステップ2"]
    B --> C["ステップ3"]
    C --> D["完了"]
```

### 2. 比較図（Before/After）

```mermaid
flowchart TB
    subgraph Before["従来の方法"]
        B1["問題点1"]
        B2["問題点2"]
    end

    Before -->|発想の転換| After

    subgraph After["新しい方法"]
        A1["① 改善点1"]
        A2["② 改善点2"]
        A3["③ 改善点3"]
    end
```

### 2. アーキテクチャ図

```mermaid
flowchart TB
    subgraph User["ユーザー"]
        Terminal["ターミナル"]
    end

    subgraph App["アプリケーション"]
        CLI["CLI"]
        Core["コア機能"]
    end

    subgraph External["外部サービス"]
        API["API"]
    end

    Terminal --> CLI
    CLI <--> Core
    Core <--> API
```

### 3. シーケンス図

```mermaid
sequenceDiagram
    actor User as ユーザー
    participant App as アプリ
    participant API as 外部API

    User->>App: リクエスト
    App->>API: API呼び出し
    API-->>App: レスポンス
    App-->>User: 結果表示
```

### 4. 状態遷移図

```mermaid
stateDiagram-v2
    [*] --> 初期状態
    初期状態 --> 処理中: 開始
    処理中 --> 完了: 成功
    処理中 --> エラー: 失敗
    エラー --> 処理中: リトライ
    完了 --> [*]
```

## 作成ルール

1. **ノード名は日本語で**: `A["日本語ラベル"]` 形式を使用
2. **矢印は意味を持たせる**: `-->` 単方向、`<-->` 双方向
3. **subgraphでグループ化**: 関連要素をまとめる
4. **色は使わない**: Zennのテーマに依存するため

## 非エンジニア向けガイドライン

- ノード数は最大10個まで
- 階層は3段まで
- 専門用語は避ける
- 「〜する」「〜される」で動詞を明確に
