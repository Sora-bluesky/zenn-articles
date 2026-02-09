---
title: "【Claude Code×Codex運用最適化①】Claude Max 20x→Claude Max 5xを狙う: 月$100削減を検証"
emoji: "🧪"
type: "tech"
topics: ["claudecode", "codex", "vscode", "生成ai", "個人開発"]
published: false
---

<a id="conclusion"></a>
## 結論

この記事の結論はシンプル。

対象読者は `Windows + PowerShell` 環境を前提にしています。

- すでに `ChatGPT Plus` を契約しているなら、Codexを併用して `Claude Max 20x -> Claude Max 5x` を狙う価値がある
- 20x依存を下げられれば、**月額合計は下がる**
- 品質は「1つのAIに全部任せない」運用にすると落ちにくい

---

<a id="what-you-get"></a>
## この記事で得られること

- `Claude Max 20x -> Claude Max 5x` 移行を判断する、実測ベースの基準
- Codexの残量確認（`/status` と VS Code左下UI）の具体手順
- 月$100削減と品質維持を両立する運用の型

---

<a id="toc"></a>
## 目次

1. [結論](#conclusion)
2. [この記事で得られること](#what-you-get)
3. [経緯](#sec-background)
4. [この記事の前提（Plusユーザー向け）](#sec-prereq)
5. [コストの見立て（2026-02-09時点）](#sec-cost)
6. [まず用語整理（ここ重要）](#sec-terms)
7. [先にハマった点：`codex /status` で使用量が見えない](#sec-status-gotcha)
8. [残量の確認方法（/status と VS Code UI）](#sec-usage-check)
9. [運用ルール（20x依存を落とす）](#sec-rules)
10. [併用運用のデメリットと対策（Claude / Codex / Gemini）](#sec-multi-tool-risks)
11. [5x移行の判断基準（公式値ベース）](#sec-criteria)
12. [1週間の検証プラン](#sec-plan)
13. [まとめ](#sec-summary)
14. [関連記事](#sec-related)
15. [参考](#references)

---

<a id="sec-background"></a>
## 経緯

システム開発、記事作成、検証メモ整理まで、ほぼ全部を Claude Code で回していた。
便利だったが、作業量が増えるほど **Claude Max 20xでも週間制限に触れる週** が出てきた。

「あと30分あれば前に進めるのに、今週はここで打ち止め」が続くと、平日は本業、深夜と週末で積み上げる副業勢には致命的だった。
しかも、個人の副業目線では `Claude Max 20x` 自体が固定費として重く、運用を見直す理由としては十分だった。
そこで持った疑問がこれ。

- Claude Codeに全部寄せるのをやめる
- VS Code拡張のCodexも併用する
- コストを抑えつつ品質を保てるか検証する

↑ [目次に戻る](#toc)

---

<a id="sec-prereq"></a>
## この記事の前提（Plusユーザー向け）

この記事は、**ChatGPT Plusをすでに契約している人** を対象にしている。
新規でProを追加する話ではない。

前提:

- 現在: `Claude Max 20x + ChatGPT Plus`
- 目標: `Claude Max 20x -> Claude Max 5x`
- 条件: 品質を落とさない

---

<a id="sec-cost"></a>
## コストの見立て（2026-02-09時点）

| プラン構成 | 月額 |
|---|---:|
| 現在: Claude Max 20x + ChatGPT Plus | `$220` |
| 移行後: Claude Max 5x + ChatGPT Plus | `$120` |
| 差分 | **`-$100/月`** |

年間では **-$1,200** の削減余地。

↑ [目次に戻る](#toc)

---

<a id="sec-terms"></a>
## まず用語整理（ここ重要）

- ChatGPTの通常チャット: ChatGPT側の枠を消費
- CodexのLocal: Codex側の `Local messages` を消費
- CodexのCloud: Codex側の `Cloud tasks` を消費

普段のChatGPT利用と、Codex利用は**別のメーター**で管理される。

:::message
**補足：ChatGPT側の残量は"厳密な数字"で見えにくい**

ChatGPT本体は、Codexの`/status`のように「残量○%」を常時表示する設計ではない。
多くの場合は、モデルごとの**リセット時刻**や、上限到達時の**通知**で管理する形になる。

つまり、
- ChatGPT本体: 厳密な残量メーターは見えにくい
- Codex: `/status`で残量とリセット時刻を確認しやすい

という違いがある。
:::

---

<a id="sec-status-gotcha"></a>
## 先にハマった点：`codex /status` で使用量が見えない

最初にターミナルで次を実行して失敗した。

```bash
codex /status
```

返ってきたのは使用量ではなく環境情報。
原因は、`/status` が **Codex起動後の対話画面で入力するコマンド** だから。

正しい手順:

```bash
codex
/status
```

↑ [目次に戻る](#toc)

---
<a id="sec-usage-check"></a>
## 残量の確認方法（/status と VS Code UI）

### 実測スクリーンショット（Plus）

![Codex /status の表示（Plus）](/images/codex-status-plus.png)
*5時間枠・週次枠の残量とリセット時刻が表示される。*

この表示を見て「こんなに余裕があったのか」と正直驚いた。毎月どれだけOpenAIに無駄金を払っていたのか、冷静に見直すきっかけになった。

この時点の表示:

- Account: `Plus`
- 5h limit: `96% left`（`resets 14:42`）
- Weekly limit: `94% left`（`resets 14:29 on 10 Feb`）

### VS Code拡張の左下メニューからも確認できる

`/status` だけでなく、VS Code拡張の画面左下からも確認できる。

1. 左下の `ローカル環境` をクリック
2. `残りのレート制限` を開く
3. 5時間枠・週次枠・リセット時刻を確認する

![左下のローカル環境メニュー](/images/codex-rate-limit-entry.png)
*左下の `ローカル環境` から `残りのレート制限` に進める。*

![残りのレート制限の表示](/images/codex-rate-limit-panel.png)
*`/status` と同様に、残量とリセット時刻をUI上で確認できる。*

↑ [目次に戻る](#toc)

---

<a id="sec-rules"></a>
## 運用ルール（20x依存を落とす）

役割を分ける。

- Claude Code: 実装本体（連続作業）
- Codex: レビュー、設計チェック、記事推敲

ポイントは1つ。

- **CodexはLocal中心、Cloudは必要時のみ**

↑ [目次に戻る](#toc)

---

<a id="sec-multi-tool-risks"></a>
## 併用運用のデメリットと対策（Claude / Codex / Gemini）

結論として、併用は有効だが「放置すると破綻しやすい」。
先にデメリットを明示しておく方が、読者の再現性は上がる。

### デメリット

1. 指示が分散して、ツールごとに挙動がズレる  
2. 設定ファイルやカスタム指示が増えて、保守コストが上がる  
3. コンテキストを盛りすぎると、使用量とレスポンス品質が不安定になる  
4. 権限・除外設定の統一が崩れると、セキュリティ事故の確率が上がる  

### 対策（実務で効く最小セット）

1. 指示の正本を1つに決める（例: `docs/ai-playbook.md`）  
2. ツール固有ファイルは「正本から転記」する運用にする  
3. 共有すべき設定はリポジトリに置く、個人設定はローカルに分離する  
4. 月1回、古いルール・スキル・MCPを棚卸しする  

### Agent Skillsやルールをどう共有するか（公式ベース）

- Codex skills: `.agents/skills` をリポジトリで共有できる  
  公式: https://github.com/openai/codex/blob/main/docs/advanced.md
- Claude Code settings: `.claude/settings.json`（共有）と `.claude/settings.local.json`（個人）を分離できる  
  公式: https://docs.anthropic.com/en/docs/claude-code/settings
- Claude Code: `.claude/agents/` と `.claude/commands/` をプロジェクト共有できる  
  公式: https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/sub-agents  
  公式: https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/slash-commands
- Gemini Code Assist: Rules は `IDE/Project` スコープで管理される  
  公式: https://cloud.google.com/gemini/docs/discover/write-prompts-gemini
- Gemini Code Assist Enterprise: コードカスタマイズ共有、除外は `.aiexclude`  
  公式: https://cloud.google.com/gemini/docs/codeassist/gemini-code-customization

詳細手順は別記事に分離した。この記事では判断軸だけに集中する。  
→ [AI併用時代の「指示資産」設計: Skills・Rules・Commandsの共有運用ガイド](ai-tooling-skills-rules-sharing-guide)

↑ [目次に戻る](#toc)

---

<a id="sec-criteria"></a>
## 5x移行の判断基準（公式値ベース）

先に結論だけ。

- `Claude Max 20x -> Claude Max 5x` は、体感ではなく**残量%の減り方**で判断する
- ClaudeとCodexは単位が違うので、**5時間あたり消費率(%)**に統一して比較する
- 2週間連続で基準を満たせたら、5x移行の現実性が高い

### 公式で押さえる前提

- Claude Max 5x/20xの価格: https://claude.com/pricing/max
- Claude Code目安（旧モデル基準）: 5xは `50-200 prompts/5h`、20xは `200-800 prompts/5h`  
  公式: https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan
- Codex Plus目安: `Local 45-225/5h`、`Cloud 10-60/5h`、`Code Reviews 10-25/週`  
  公式: https://developers.openai.com/codex/pricing

※ 公式値はレンジ。会話長・コード量・モデル・タスク複雑さで変動する。

### 共通の測定単位（これだけ使う）

`5h消費率(%) = 開始時の残量% - 終了時の残量%`

例: `95% -> 72%` なら `23%消費`

`prompts` と `Local/Cloud件数` は見かけの単位が違うため、移行判断はこの `%` にそろえる。

### 5x移行の判定スコアカード（2週間）

次の4条件を2週間連続で満たせたら、5x移行候補。

1. Claudeの5h消費率: 1日の最大値が `70%以下`
2. Codexの5h消費率（Local+Cloud合算）: 1日の最大値が `60%以下`
3. 制限到達による停止: `週1回以下` かつ `30分以内/週`
4. 手戻り件数（レビュー差し戻し）: 20x運用時より増えない

※ `70%/60%` は公式固定値ではなく、移行可否を見極める実務目安。

### どう記録するか（毎日1分）

1. 作業開始時に `claude /status` と `codex /status`（または左下の `残りのレート制限`）を確認
2. 作業終了時に同じ画面を再確認
3. 開始%と終了%の差分をメモ
4. 上限通知が出た時刻と復帰時刻、差し戻し回数を記録

この記録は、毎日手動で続けるより「スキル化」した方が継続しやすい。  
→ [AI使用量ログを1分で残す: 日次記録をスキル化する手順](ai-usage-log-skill-automation-guide)

### 推論の労力（low / medium）の使い分け

- 日常作業は `low`
- 次だけ `medium`
  - 価格や上限など、公式値を断定する場面
  - 複数ソースの整合を取る場面
  - 誤ると結論が崩れる場面

公式上、`reasoning.effort` は使用量に影響するが、増加率の固定値は公開されていない。

↑ [目次に戻る](#toc)

<a id="sec-plan"></a>
## 1週間の検証プラン

1. まず3日間、現状（20x中心）で記録
2. 次の4日間、役割分担運用に変更（Claude実装中心 + Codexレビュー中心）
3. 毎日、Claude/Codexの`/status`で5時間枠と週次枠を記録

↑ [目次に戻る](#toc)

---

<a id="sec-summary"></a>
## まとめ

この検証は「新しい課金を増やす話」ではない。
**すでに持っているPlusを活かして、Claude 20x依存を5xへ下げられるか** の話。

まずは1週間、役割分担だけ変えて記録してみるのがいちばん確実。

↑ [目次に戻る](#toc)

---

<a id="sec-related"></a>
## 関連記事

- 次は②へ: [Claude/Codex/Gemini指示資産の共有運用ガイド](ai-tooling-skills-rules-sharing-guide)
- 記録を自動化するなら③へ: [Claude Code/Codex使用量ログを1分で自動化する手順](ai-usage-log-skill-automation-guide)

↑ [目次に戻る](#toc)

---

<a id="references"></a>
## 参考

- Claude Max pricing: https://claude.com/pricing/max
- Claude Code with Pro/Max usage: https://support.claude.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan
- About Max plan usage: https://support.anthropic.com/en/articles/11014257-about-claude-s-max-plan-usage
- ChatGPT Plus: https://help.openai.com/en/articles/6950777-chatgpt-plus
- CodexとChatGPTプラン: https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan
- Codex pricing and rate limits: https://developers.openai.com/codex/pricing
- Codex IDE extension（推論の労力）: https://developers.openai.com/codex/ide
- OpenAI model controls（reasoning.effort）: https://help.openai.com/en/articles/5072518-controlling-the-length-of-openai-model-responses
- ChatGPT usage limits: https://help.openai.com/en/articles/9824962
