---
title: "Claude Code × Codex × Antigravity: 指示資産の散乱を防ぐ設定共有ガイド"
emoji: "🧩"
type: "tech"
topics: ["claudecode", "codex", "生成ai", "個人開発", "windows"]
published: false
---

<a id="position"></a>
## この記事の位置づけ

Claude Code / Codex / Google Antigravity を併用していると、Skills・Rules・Commands などの「指示資産」がツールごとに散乱しがちになる。この記事では、3ツール間で指示資産を安全に共有する設計と手順をまとめた。

:::message
**対象読者**: Claude Code を日常的に使っている個人開発者（Windows + PowerShell 環境前提）
**前提**: Claude Code の基本操作（CLAUDE.md、Skills、Rules）を理解していること
**検証環境**: Windows 11 + PowerShell 7.x（2026年2月時点）
:::

急ぐ方は、末尾の [コピペ用指示書](#gift-prompt) だけ使ってください。
設計意図まで押さえたい方は、本文を順に読むのがおすすめです。

---

<a id="toc"></a>
## 目次

- [この記事で得られること](#what-you-get)
- [結論](#conclusion)
- [想定環境の前提（構成イメージ）](#assumptions)
- [先に押さえる公式仕様（最新版）](#official-specs)
- [移植の設計方針（事故を防ぐ）](#design-policy)
- [共有リポジトリの推奨レイアウト（先に完成形を確認）](#target-layout)
- [手順A: Claude Codeの資産をCodexグローバルへ移植](#step-a)
- [手順B: 同じ資産をGoogle Antigravityグローバルへ展開](#step-b)
- [手順C: グローバル資産を共有リポジトリへ落とし込む](#step-c)
- [検証チェックリスト（実行順）](#checklist)
- [よくある失敗と回避策](#pitfalls)
- [公式リンク（再掲）](#links)
- [コピペ用指示書（そのまま使える版）](#gift-prompt)
- [最後に](#closing)

---

<a id="what-you-get"></a>
## この記事で得られること

- Claude Code のグローバル設定・Skills・Rules・Commands を Codex へ安全に移植する手順
- Codex / Google Antigravity でも破綻しない共通ディレクトリ設計
- 失敗時に戻せるバックアップ手順と検証手順

---

<a id="conclusion"></a>
## 結論

3ツール併用で崩れにくい設計は、指示資産を3層に分けること。

1. **チーム共有のルールブック**（人間が読む版）: `docs/ai-playbook.md` に「コードレビューの観点」「命名規則」などを1か所にまとめる
2. **ツールごとの設定ファイル**（機械が読む版）: ルールブックの内容を `AGENTS.md`（Codex用）/ `GEMINI.md`（Antigravity用）/ 各 `skills` / `rules` に変換して配置
3. **個人の好み**（ローカル限定）: `settings.local.*` にモデル選択やフック設定など、人によって違う部分だけ置く

ポイントは「ルールブックを更新 → 各ツール設定に反映」の一方向フローを守ること。逆方向（ツール設定を直接編集）をやると、すぐに散乱する。

---

<a id="assumptions"></a>
## 想定環境の前提（構成イメージ）

本記事のコマンドは、以下のような構成をイメージしています。

```text
C:\Users\username\
|-- .agents\
|   `-- skills\
|-- .claude\
|   |-- agents\
|   |-- settings.json
|   |-- skills\
|   |-- rules\
|   `-- commands\
`-- .codex\
    |-- config.toml
    `-- rules\
        `-- default.rules
```

---

<a id="official-specs"></a>
## 先に押さえる公式仕様（最新版）

### Codex（OpenAI公式）

- [Rules](https://developers.openai.com/codex/rules) は `~/.codex/rules/` とプロジェクトの `.codex/rules/`（`.md/.txt`）を読み込む
- [AGENTS.md](https://developers.openai.com/codex/agents-md) はカレントから親へ探索（最寄り優先）
- [Skills](https://developers.openai.com/codex/skills) は `~/.agents/skills/` を正本にし、必要に応じて `<project>/.codex/skills/` を併用する
- [IDE commands](https://developers.openai.com/codex/ide/commands) はIDE内コマンドとして提供される（Claudeのカスタムコマンドは1:1移植ではなく、Skillsへ再設計するのが安全）

### Claude Code（Anthropic公式）

- [Settings](https://docs.anthropic.com/en/docs/claude-code/settings) は `~/.claude/settings.json`、個人設定は `~/.claude/settings.local.json`
- [Custom commands](https://docs.anthropic.com/en/docs/claude-code/slash-commands) は `~/.claude/commands`（ユーザー）と `.claude/commands`（プロジェクト）
- [Skills](https://docs.anthropic.com/en/docs/claude-code/skills) は `~/.claude/skills`（ユーザー）と `.claude/skills`（プロジェクト）
- [Sub-agents](https://docs.anthropic.com/en/docs/claude-code/sub-agents) は `~/.claude/agents`（ユーザー）と `.claude/agents`（プロジェクト）で管理できる

### Google Antigravity（Google公式）

- [Antigravity公式Codelab](https://codelabs.developers.google.com/codelabs/create-an-agent-with-google-antigravity) では Rules / Workflows / Skills を `.agent/` 配下で管理（グローバルは `~/.gemini/...`）
- [Gemini CLI Configuration](https://google-gemini.github.io/gemini-cli/docs/get-started/configuration.html) は `settings.json` を `~/.gemini/settings.json` または `<project>/.gemini/settings.json` に配置
- [GEMINI.md](https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html) の階層コンテキスト（グローバル: `~/.gemini/GEMINI.md`）が Rules 相当
- [Gemini CLI Custom Commands](https://google-gemini.github.io/gemini-cli/docs/cli/custom-commands.html) は `~/.gemini/commands/` と `<project>/.gemini/commands/`

---

<a id="design-policy"></a>
## 移植の設計方針（事故を防ぐ）

1. まずバックアップを取る（復元可能性を確保）
2. いきなり全コピーしない（Rules/Commands/Skillsを段階移植）
3. Settings は「共通化できる最小キー」だけ反映する
4. 反映後は必ず `help/list/status` 系コマンドで検証する
5. 組み込みスラッシュコマンド名は予約語として扱い、Skills/Commandsで同名定義しない

---

<a id="target-layout"></a>
## 共有リポジトリの推奨レイアウト（先に完成形を確認）

`手順A/B` はグローバル環境の整備、`手順C` で共有リポジトリへ反映します。

```text
repo/
|-- docs/
|   `-- ai-playbook.md
|-- AGENTS.md
|-- GEMINI.md
|-- .codex/
|   |-- rules/
|   `-- skills/            # プロジェクト固有がある場合のみ（通常は空運用）
|-- .claude/
|   |-- agents/
|   |-- settings.json
|   |-- commands/
|   |-- skills/
|   `-- rules/
`-- .agent/
    |-- rules/
    |-- workflows/
    `-- skills/
```

:::message
**運用メモ（重要）**
- Codex Skills の正本は `~/.agents/skills` に固定し、`.codex/skills` はプロジェクト固有の追加がある場合だけ使う
- 共有時は「正本を更新 → 各ツールへ同期」の一方向フローで運用する
:::

---

<a id="step-a"></a>
## 手順A: Claude Codeの資産をCodexグローバルへ移植

### 1. バックアップを作成

```powershell
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$bk = Join-Path $HOME "Desktop\ai-migration-backup-$ts"
New-Item -ItemType Directory -Path $bk | Out-Null
Copy-Item "$HOME\.claude" -Destination (Join-Path $bk "claude") -Recurse
Copy-Item "$HOME\.codex"  -Destination (Join-Path $bk "codex")  -Recurse
Write-Host "Backup: $bk"
```

### 2. Codex/Skills側の受け皿を作成

```powershell
New-Item -ItemType Directory -Force "$HOME\.agents\skills"  | Out-Null
New-Item -ItemType Directory -Force "$HOME\.codex\rules"    | Out-Null
New-Item -ItemType Directory -Force "$HOME\.codex\migration" | Out-Null
```

### 3. Skillsを移植（Claude -> `~/.agents/skills`）

```powershell
robocopy "$HOME\.claude\skills" "$HOME\.agents\skills" /E /R:1 /W:1
```

### 4. Rulesを移植

```powershell
robocopy "$HOME\.claude\rules" "$HOME\.codex\rules" /E /R:1 /W:1
```

### 5. Sub-agentsを移植（Claude -> Codex Skillsへ再設計）

Claudeの Sub-agents は `~/.claude/agents` で管理されます。  
Codex側には Sub-agent の同等概念が公式に明示されていないため、Skills へ再設計する前提でいったん退避します。

```powershell
if (Test-Path "$HOME\.claude\agents") {
  robocopy "$HOME\.claude\agents" "$HOME\.codex\migration\claude-agents" /E /R:1 /W:1
}
```

### 6. Custom commandsを移植（Claude -> Codex Skillsへ再設計）

Claudeの custom commands も 1:1 での移植先が公式に固定されていないため、Skills 変換用に退避します。

```powershell
if (Test-Path "$HOME\.claude\commands") {
  robocopy "$HOME\.claude\commands" "$HOME\.codex\migration\claude-commands" *.md /R:1 /W:1
}
```

### 7. Claude設定からCodexへ最小反映

Claude 側設定の代表キーは `language / model / permissions / hooks / spinnerVerbs` です。  
Codex 側 `config.toml` へは、まず衝突しにくい `model` と `model_personality` のみ手動反映してください（`permissions` や `hooks` は互換性が1対1ではないため）。

例:

```toml
# ~/.codex/config.toml
model = "gpt-5"
model_personality = "pragmatic"
```

### 8. フィロソフィ/設計原則をCodex rulesへ同期

`CLAUDE.md` の参照先を Codex 側でも同等に使えるように、主要ルールを `~/.codex/rules/` へ同期します。

```powershell
Copy-Item "$HOME\.claude\philosophy-global.md" "$HOME\.codex\rules\philosophy-global.md" -Force
Copy-Item "$HOME\.claude\philosophy\core.md"   "$HOME\.codex\rules\philosophy-core.md"   -Force
Copy-Item "$HOME\.claude\design-rules\core.md" "$HOME\.codex\rules\design-rules-core.md" -Force
```

必要に応じて Codex のグローバル指示ファイルを追加します。

```text
~/.codex/AGENTS.md
```

---

<a id="step-b"></a>
## 手順B: 同じ資産をGoogle Antigravityグローバルへ展開

### 1. Rules（GEMINI.md / .agent/rules）へ変換

最初は Claude Rules の本文を `GEMINI.md` に集約するのが安全です。

```powershell
if (!(Test-Path "$HOME\.gemini")) { New-Item -ItemType Directory "$HOME\.gemini" | Out-Null }
Get-ChildItem "$HOME\.claude\rules" -File | ForEach-Object { "`n`n# from $($_.Name)`n" + (Get-Content $_.FullName -Raw) } | Set-Content "$HOME\.gemini\GEMINI.md"
```

### 2. Commands（Claude -> Gemini Custom Commands）

Gemini CLI の Custom Commands は `.toml` 形式です。  
最初は「1コマンドずつ」変換してください（全自動変換は事故率が高い）。

最小テンプレ:

```toml
# ~/.gemini/commands/review.toml
description = "Code review helper"
prompt = """
以下の観点でレビューしてください。
- 仕様逸脱
- セキュリティ
- テスト不足
"""
```

### 3. Skills（Antigravity仕様）

公式Codelab準拠で、グローバルは `~/.gemini/skills/`、プロジェクトは `.agent/skills/` を使います。  
`SKILL.md` を必須にして、必要なら `scripts/` と `references/` を追加します。

---

<a id="step-c"></a>
## 手順C: グローバル資産を共有リポジトリへ落とし込む

以下は「共有してよい資産だけ」をリポジトリへ同期する例です。  
`settings.local.*`、個人トークン、個人用フックは含めないでください。

### 1. 共有先ディレクトリを作成

```powershell
New-Item -ItemType Directory -Force ".codex\rules",".codex\skills" | Out-Null
New-Item -ItemType Directory -Force ".claude\rules",".claude\skills",".claude\commands",".claude\agents" | Out-Null
New-Item -ItemType Directory -Force ".agent\rules",".agent\workflows",".agent\skills" | Out-Null
```

### 2. Codex共有資産を反映

```powershell
robocopy "$HOME\.codex\rules"    ".codex\rules"    /E /R:1 /W:1
robocopy "$HOME\.codex\skills"   ".codex\skills"   /E /R:1 /W:1
```

### 3. Claude共有資産を反映

```powershell
robocopy "$HOME\.claude\rules"    ".claude\rules"    /E /R:1 /W:1
robocopy "$HOME\.claude\skills"   ".claude\skills"   /E /R:1 /W:1
robocopy "$HOME\.claude\commands" ".claude\commands" /E /R:1 /W:1
if (Test-Path "$HOME\.claude\agents") { robocopy "$HOME\.claude\agents" ".claude\agents" /E /R:1 /W:1 }
Copy-Item "$HOME\.claude\settings.json" ".claude\settings.json" -Force
```

### 4. Antigravity/Gemini共有資産を反映

```powershell
Copy-Item "$HOME\.gemini\GEMINI.md" ".\GEMINI.md" -Force -ErrorAction SilentlyContinue
if (Test-Path "$HOME\.gemini\commands") { robocopy "$HOME\.gemini\commands" ".agent\workflows" /E /R:1 /W:1 }
if (Test-Path "$HOME\.gemini\skills")   { robocopy "$HOME\.gemini\skills"   ".agent\skills"    /E /R:1 /W:1 }
```

### 5. 共有対象外を明示（.gitignore）

```text
.claude/settings.local.json
.gemini/settings.local.json
.env
*.secrets.*
```

---

<a id="checklist"></a>
## 検証チェックリスト（実行順）

1. Codexで `rules/skills/AGENTS.md` が見えるか確認（`~/.codex/rules/philosophy-global.md` など）
2. `~/.codex/migration` に退避した `claude-agents` / `claude-commands` から、優先度の高いものを Skills 化して実行確認
3. Gemini CLIで `/memory show` を実行し `GEMINI.md` の読み込み内容を確認
4. Gemini CLIで `/help` を実行し custom commands が出るか確認
5. Antigravityで `.agent` 配下の rules/workflows/skills が認識されるか確認
6. 予約語衝突チェックを実施（組み込みスラッシュコマンド名が custom commands/skills に存在しないこと）

---

<a id="pitfalls"></a>
## よくある失敗と回避策

1. 全設定を機械的に移植して壊す  
対策: `model` 以外は段階的に反映
2. コマンド形式差（`.md` vs `.toml`）を無視する  
対策: Gemini向けは手動変換を前提にする
3. グローバルとプロジェクトの責務が混ざる  
対策: 個人設定はホーム配下、チーム共有はリポジトリ配下に限定
4. 組み込みスラッシュコマンド名と custom commands/skills が衝突する  
対策: 予約語ポリシーを先に固定し、衝突時は改名（例: `project-status`, `task-plan`）してから移植する

---

<a id="links"></a>
## 公式リンク（再掲）

- Codex Rules  
  https://developers.openai.com/codex/rules
- Codex AGENTS.md  
  https://developers.openai.com/codex/agents-md
- Codex Skills  
  https://developers.openai.com/codex/skills
- Codex IDE Commands  
  https://developers.openai.com/codex/ide/commands
- Claude Code Settings  
  https://docs.anthropic.com/en/docs/claude-code/settings
- Claude Code Skills  
  https://docs.anthropic.com/en/docs/claude-code/skills
- Claude Code Sub-agents  
  https://docs.anthropic.com/en/docs/claude-code/sub-agents
- Claude Code Slash Commands  
  https://docs.anthropic.com/en/docs/claude-code/slash-commands
- Google Antigravity Codelab  
  https://codelabs.developers.google.com/codelabs/create-an-agent-with-google-antigravity
- Gemini CLI Configuration  
  https://google-gemini.github.io/gemini-cli/docs/get-started/configuration.html
- Gemini CLI GEMINI.md  
  https://google-gemini.github.io/gemini-cli/docs/cli/gemini-md.html
- Gemini CLI Custom Commands  
  https://google-gemini.github.io/gemini-cli/docs/cli/custom-commands.html

---

<a id="gift-prompt"></a>
## コピペ用指示書（そのまま使える版）

下の指示書をCodexにそのまま貼れば、移植を実行依頼できる。

:::message
まずは `Claude → Codex` を最小移植し、検証が通ってから `Antigravity` に展開するのがおすすめ。
:::

```text
あなたは実装担当エンジニアです。私の Windows + PowerShell 環境で、
Claude Code 環境から Codex 環境へ移植を実施してください。

[目的]
- ~/.claude の共有可能資産を ~/.codex に移植し、認識確認まで完了する
- Claude の sub-agents / custom commands は Codex Skills へ再設計する
- OpenAI Codex 公式ガイドに準拠した配置/設定にする

[完了条件]
- ~/.codex 配下に rules が反映されている
- ~/.agents/skills 配下に skills が反映されている（公式優先）
- ~/.codex/migration 配下に claude-agents / claude-commands が退避されている
- ~/.codex/rules に philosophy-global.md / philosophy-core.md / design-rules-core.md が反映されている
- ~/.codex/AGENTS.md が存在する
- config は公式キー準拠（例: model_personality）
- rules / skills / AGENTS.md の認識確認結果が報告されている
- 組み込みスラッシュコマンド予約語との衝突がないこと（custom commands/skills 側で同名定義しない）
- ロールバック手順が提示されている

[スコープ]
- 対象: ~/.claude/{rules,skills,commands,agents}
- 非対象: settings.local.* / token / secrets / 個人用フック / 認証情報
- 方針: 共有対象だけ同期し、個人設定はローカルに残す

[タスク]
Task 0: 公式準拠チェック（承認待ち）
Task A: 現状確認とバックアップ作成
Task B: Dry-runでコピー計画を提示（承認待ち）
Task C: 本実行（rules移植 + skillsを~/.agents/skillsへ移植 + commands/agents退避）
Task D: settings最小キーの提案（例: model, model_personality）と承認後反映
Task E: commands/agents の Skills 変換方針提示（優先順位つき）
Task F: 認識確認と最終報告

[Task 0 要件（必須）]
- 以下を読了してから実作業を開始する
  - https://developers.openai.com/codex/config-basic
  - https://developers.openai.com/codex/config-advanced
  - https://developers.openai.com/codex/config-reference
  - https://developers.openai.com/codex/config-sample
  - https://developers.openai.com/codex/skills
  - https://developers.openai.com/codex/rules
  - https://developers.openai.com/codex/guides/agents-md
- 「公式準拠チェック表」を提示する
  - 設定キー名
  - ディレクトリ配置先
  - 現状との差分
  - 反映方針
- 私が「承認」と返すまで、Task A以降の実変更は実行しない

[予約語ポリシー（必須）]
- 組み込みスラッシュコマンド名は予約語として扱い、custom commands / skills で同名を作成しない
- 予約語の正本は公式ドキュメントとし、移植前に衝突チェックを実施する
- 衝突が見つかった場合は削除ではなく改名して退避する（例: `project-status`, `task-plan`）

[実行ルール]
1) 先にバックアップを作成する（~/.claude と ~/{.codex,.agents}）
2) Task 0 と Task B は承認待ちゲートにする
3) settings は全移植しない。最小キーのみ提案し、承認後に反映する
4) 各Taskで「実行コマンド」「結果要約」「次チェックポイント」を報告する
5) 競合・機密混入疑い・重大エラー時は中断し、理由と次アクションを提示する
6) 破壊的操作（削除・reset系）は行わない
7) 公式仕様とローカル慣例が衝突した場合は公式優先。例外は私の明示指示のみ

[検証]
- rules / skills / AGENTS.md の認識確認を実施し、結果を報告する
- 退避した commands / agents から、変換対象候補と変換優先度を報告する
- 公式準拠チェック表の「反映後ステータス」を更新して提出する
- 予約語衝突チェック結果（Pass/Fail）を提出する

[最終報告フォーマット]
- 実施したTask一覧
- 変更ファイル/ディレクトリ一覧
- 公式準拠チェック結果（項目別 Pass/Fail）
- 検証結果
- 未対応事項
- ロールバック手順
```

---

<a id="closing"></a>
## 最後に

モデルを跨いだ運用で効くのは、モデル性能差より「指示資産の整備品質」。この記事は実運用の出発点であり、環境差分で想定外の問題が起きる可能性はある。検証結果にもとづいて順次調整していく運用をおすすめする。

関連記事:
- コスト検証: [Claude Max 20x→5xを狙う月$100削減の検証](claude-code-codex-plus-cost-optimization)
- ログ自動化: [使用量ログを1分で自動化する手順](ai-usage-log-skill-automation-guide)
