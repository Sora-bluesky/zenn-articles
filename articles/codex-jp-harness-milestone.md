---
title: "Codex CLI の日本語出力を MCP サーバーで整えた話（32→0 違反）"
emoji: "🎛️"
type: "tech"
topics: ["codex", "mcp", "ai", "openai", "個人開発"]
published: false
---

## はじめに

Codex CLI に進捗報告を書かせると、こんな文章が返ってくることがある。

> TASK-306 を codex/task306-stdin-parity-20260417 で開始し、prompt_transport=stdin を受け入れて pane dispatch で send-paste 経由に流す実装を入れました。

読めなくはない。でも、音読したら詰まる。ファイル名と一般語がバッククォートなしで混ざり、英語の比喩表現（slice, parity, fail-close）が助詞で直接つながり、1 文に英語識別子が 7 個以上詰め込まれている。

公式が日本語対応を強化してくれるのが本筋だが、待っている間も業務は進む。暫定対策として、**Codex が最終応答を出す直前に通る「検品ゲート」**を MCP サーバーで外付けした。結果、同じプロンプトに対する違反が 32 件から 0 件になった。

本記事はその記録である。リポジトリは [`sora-bluesky/codex-jp-harness`](https://github.com/sora-bluesky/codex-jp-harness) に置いてある。

## 先に結論

同一の進捗報告プロンプトに対し、3 段階の施策を重ねて違反数を計測した。

| 段階 | 違反数 | 施策 |
|---|---|---|
| Before | 32 | 施策なし |
| VOICEVOX directive 追加 | 4 | 「音読される場面を想像して書け」を AGENTS.md に注入 |
| 7.p 強化 | **0** | 発火トリガー・禁止事項・セルフチェックを明記 |

面白いのは、**プロンプト層だけで 87.5% が削れた**こと。ランタイム強制（Stop hook で呼び忘れを検知する層）は最後まで使わなかった。

以下、どうやってこの結果にたどり着いたかを書く。

## 問題: Codex の日本語は 6 つの壁で読みづらい

具体的な悪い例を挙げると症状が見えやすい。

> DesktopDigestItem の producer parity をそのままベストプラクティスで進めました。

この 1 文には 6 種類の問題が重なっている。

1. **英語語順の直訳**: `proceed with the producer parity of DesktopDigestItem` を機械的に日本語化している
2. **英単語の混在**: `parity` を日本語訳せず助詞で直結
3. **主語と動作主が曖昧**: 誰が何をしたか省略された名詞止め
4. **文の粒度が不統一**: 短い体言止めと長い複文の無秩序な混在
5. **「進捗」「判断」「事実」が同じトーンで流れる**: 見出しや強調で情報の重み付けがない
6. **助詞の直訳調**: 「ベストプラクティスで進める」ではなく「ベストプラクティスに沿って進める」が自然

1 つ 1 つは小さい癖だが、重なると脳内処理コストが一気に跳ねる。毎日の報告で読み返すたびに体力が削られる。

## 最初の失敗: ルールを書いたのに守られなかった

素直な対応として、`~/.codex/AGENTS.md` に詳細な日本語ルールを書いた。原語で書くべき語、カタカナで書くべき語、動詞で区切る、名詞句を 3 つ以上連結しない、など 15 項目以上。

翌日、同じプロンプトで同じ症状が再発した。ルールを読んではいるが、実装中の記述では元の癖が勝つ。毎回人間が指摘するのはスケールしない。

「ルールで書いてあるから守られる」は確率論で、毎回 100% 守られる保証はない。これは僕が過去に何度もハマっている失敗パターンだった。

## 調査: Codex に出力を書き換える公式機構はあるか

先に公式機能を調べた。`openai/codex` の Issue と docs を漁った結果、以下が分かった。

- **AGENTS.md**: 32KB でサイレント切り詰めの Issue（[#13386](https://github.com/openai/codex/issues/13386)）、グローバルとリポローカルのマージ動作が不明の Issue（[#18189](https://github.com/openai/codex/issues/18189)）あり
- **Skill 機構**: `~/.codex/skills/` を認識するが、自動発火は Progressive Disclosure（LLM 判定）で強制力なし
- **Hook 機構**: `codex_hooks` feature flag あり。SessionStart / Stop / Notification は動くが、リポジトリローカルの `config.toml` だと壊れる Issue あり（[#17532](https://github.com/openai/codex/issues/17532)）
- **Pre-response hook（出力前書き換え）**: **存在しない**
- **PreSkillUse / PostSkillUse**: Issue [#17132](https://github.com/openai/codex/issues/17132) で提案中、未実装

結論: 出力を書き換える公式ハンドルは無い。runtime 強制は諦めて、「呼ばれたら効く」タイプのゲートで代替するしかない。

## 設計: 4 層から Tier 2 を選ぶ

介入層を 4 つ洗い出した。

| Tier | 手段 | 実装 | UX | 強制力 |
|---|---|---|---|---|
| 1 | Stop hook + 次ターン注入 | 0.5 日 | 違反版も見える | 中 |
| **2** | **MCP finalize ゲート** | **1〜2 日** | **クリーン版のみ** | **中〜高** |
| 3 | 外部ラッパースクリプト | 1〜2 週 | 完全透過 | 高 |
| 4 | TUI プロキシ | 数週 | 完全透過 | 最高 |

Tier 3 / 4 は対話 TUI を自作する必要があり、Codex のバージョンアップで壊れる宿命を負う。Tier 1 は違反版をユーザーが一度見てしまう。

Tier 2 は「Codex が応答を出す前に必ず通る関所を MCP ツールとして提供する」設計。

- Codex が最終ドラフトを書く
- `mcp__jp_lint__finalize(draft)` を呼ぶ
- サーバーが違反を検出して `{"ok": false, "violations": [...]}` を返す
- Codex が違反を見て書き直し、再呼び出し
- `{"ok": true}` が返るまでループ
- クリーン版のみユーザーに届く

Codex に呼び出しさせる部分は AGENTS.md の rule で担保。ここが soft な点だが、後述のように最終的には自発呼び出しまで到達した。

## 想定外のヒント: VOICEVOX は register を切り替える

開発中、ずんだもんの音声合成（[VOICEVOX](https://voicevox.hiroshiba.jp/)）を別の用途で使っていた。通知用に Codex が `mcp__voicevox__speak` を呼んで一言喋らせるやつだ。

ある日、ふと気づいた。**音読される Codex の日本語は、書く Codex の日本語より遥かに自然**。100 文字以内に収まっていて、ファイル名や PR 番号のような音読不可能な識別子を自然と避ける。

なぜか？ 仮説を立てた。

- **文字数上限**（100 文字）が英語識別子の詰め込みを物理的に防ぐ
- **用途制約**（読み上げ）が音読不可能な要素を排除する
- **聴衆制約**（ユーザーが聞く）が意図伝達を最優先に押し上げる

つまり**「音読される」前提が Codex に register を切り替えさせている**。逆に技術報告では「後から読み返せる」前提で情報密度を上げる方向のバイアスが働く。

この仮説を利用できないか。AGENTS.md にこう書いた。

```
応答を書く時、ユーザーがこの応答を VOICEVOX で読み上げさせる場面を想像する。
音読して自然に意味が通る文章が目標。英語識別子の羅列・名詞句の過連続・
専門用語の直訳は音読で破綻する → 書き直す。
1 文は 80 文字以内を目安、英語識別子を含む文は 50 文字以内。
```

効果は絶大だった。同じ報告プロンプトで違反が 32 → 4 件。`bare_identifier`（バッククォート抜け）は 20 → 0 件で完全解消。Codex は出力時点で `slice` や `done` を「避けている」と自覚的に表明するようになった。

**具体的な想像対象を与える directive は、抽象的な「丁寧に書け」より桁違いに効く**。これは他のプロンプト強制ゲートでも使えるパターンだと思う。

## 実装: MCP finalize ゲート

コード全体は [`sora-bluesky/codex-jp-harness`](https://github.com/sora-bluesky/codex-jp-harness) にある。中核は 3 ファイル。

### `config/banned_terms.yaml`（禁止語の唯一の真実）

```yaml
banned:
  - { term: slice,     suggest: "限定的な変更、今回の範囲" }
  - { term: parity,    suggest: "差、差分、揃え" }
  - { term: done,      suggest: "完了" }
  - { term: dispatch,  suggest: "振り分け、受け渡し" }
  # ... 計 12 語

identifier_pattern: "[A-Za-z_][A-Za-z0-9]*[._/-][A-Za-z0-9_./-]+"
identifier_limit_per_sentence: 2

sentence_length:
  enabled: true
  max_chars: 80
  max_chars_with_identifiers: 50
```

識別子パターンの妙は、**内部に `._/-` を含むトークンだけ**を拾うところ。これで `HANDOFF.md` や `TASK-306` は引っかかり、`slice`（単純英単語）や `Codex`（一般名詞）は引っかからない。単純英単語は `banned` 側で個別に拾う。

### `src/codex_jp_harness/rules.py`（純関数の lint エンジン）

```python
def detect_banned_terms(text: str, cfg: RuleConfig) -> list[Violation]:
    # バッククォート内とコードブロック内は除外
    scan = _strip_code_blocks(text)
    for entry in cfg.banned:
        pattern = re.compile(
            r"(?<![A-Za-z0-9_])" + re.escape(entry["term"]) + r"(?![A-Za-z0-9_-])",
            re.IGNORECASE,
        )
        # ... マスクして line ごとに走査
```

ポイントは 3 点。

- **コードブロック除外**（` ``` ` で囲まれた範囲はスキップ）
- **インラインバッククォート除外**（` ` の中は検査しない）
- **単語境界**（`sliced` は `slice` に引っかけない）

誤検知を減らすために、`_mask_inline_code` で該当スパンを空白で埋めたマスク版を走査する。こうするとカラム位置を崩さず検査できる。

### `src/codex_jp_harness/server.py`（MCP ツール公開層）

```python
mcp = FastMCP("jp_lint")

@mcp.tool()
def finalize(draft: str) -> dict:
    cfg = load_rules(RULES_PATH)
    violations = lint(draft, cfg)
    if not violations:
        return {"ok": True}
    return {
        "ok": False,
        "violations": [v.to_dict() for v in violations],
        "summary": f"{len(violations)}件の違反を検出",
    }
```

FastMCP を使うとツール定義が 10 行で済む。Codex の `~/.codex/config.toml` には `[mcp_servers.jp_lint]` として 2 行登録する。

```toml
[mcp_servers.jp_lint]
command = "C:\\Users\\<user>\\Documents\\Projects\\apps\\codex-jp-harness\\.venv\\Scripts\\python.exe"
args = ["-m", "codex_jp_harness.server"]
```

最初に躓いた罠が 2 つあった。

1. **サーバー名の不一致**: `FastMCP("jp-lint")` のダッシュ版と `config.toml` のアンダースコア版がズレて、`mcp__jp_lint__finalize` で解決できなかった
2. **システム Python 問題**: `command = "python"` にするとシステム Python が呼ばれて `mcp[cli]` が無く ImportError。venv の Python を絶対パスで指す必要があった

両方とも Codex の MCP パネルでは「有効」と表示されるのに実際は動かないサイレント失敗。診断に 1 時間溶かした。install スクリプトで venv パス生成を自動化したので、他の人が踏む地雷ではなくなっている。

## 2 段ロケット: 呼び忘れ対策

MCP サーバー層ができても、Codex が自発的に `finalize` を呼ばなければゲートは空転する。最初の実戦テストで実際にそうなった。`jp_lint` MCP は有効、ツールは公開、しかし Codex は一度も呼ばずに違反だらけの報告を返した。

直感的対処は hook でのランタイム強制（Tier 1 の併用）だが、先にプロンプトを強化してみた。3 点を AGENTS.md 7.p に追加した。

- **① 発火トリガー**: 「やったこと／確認結果／次にやること」の見出しが現れた瞬間、報告である。そこから `finalize` 呼び出しは必須
- **② 禁止事項**: `finalize` を呼ばずに日本語技術報告を返すことは **ルール違反** と明記
- **③ セルフチェック**: 応答送信直前に「このターンで `finalize` を呼んだか?」を自問

結果、Codex は自発的に 2 回 `finalize` を呼ぶようになった。1 回目は 6 件の違反で `ok: false`、指摘内容を読んで書き直し、2 回目で `ok: true`。きれいな retry ループが動いた。

**Stop hook による runtime 強制を実装せずに、残り 12.5% を プロンプト強化 だけで拾い切った**。

## 結果: 32 → 0 違反

3 段階の違反数推移を並べ直す。

| 段階 | 違反数 | `banned_term` | `bare_identifier` | `sentence_too_long` | 他 |
|---|---|---|---|---|---|
| Before | 32 | 4 | 20 | 6 | 2 |
| VOICEVOX directive | 4 | 1 | 0 | 3 | 0 |
| 7.p 強化 | **0** | 0 | 0 | 0 | 0 |

fixture ファイル（`tests/fixtures/codex_*.txt`）としてリポに入れてある。lint を通せば誰でも再現できる。

## 知見: プロンプト層は想定以上に効く

この実装を通して得た一次データの知見は 3 つ。

### 1. プロンプト層で 87.5% は取れる

runtime 強制ゼロで、AGENTS.md のルール文だけでここまで削れるのは想定外だった。「強制されないと守られない」という先入観があったが、具体的な directive を与えれば大半は自主規律で処理できる。

### 2. 想像対象を与える directive が強い

「丁寧な日本語を書け」のような抽象指示より「**VOICEVOX で音読される想定で書け**」のような具体的想像対象の方が桁違いに効いた。他のプロンプト強制ゲートでも応用できるはず。

### 3. runtime 強制は保険で十分

`Stop hook` による呼び忘れ検知は最初から実装する予定だったが、プロンプト強化だけで 100% 到達したので保留した。「defense in depth の最後の砦」として v0.2.0 のオプション機能に降格させた。**runtime 強制は無くても回る**のが今回の一番の発見。

## 限界と撤去戦略

この暫定対策には本質的な限界がある。

- **Pre-response hook が Codex に存在しない**ので、Codex が finalize を呼ばなかった場合の runtime 捕捉は別実装が必要
- **Codex のバージョンアップで regression する可能性**あり。月次の観測で検知する
- **形態素解析を使っていない**ので、名詞句の過連続検出はヒューリスティック。必要なら fugashi 追加で高精度化できる

そして最重要: これは**暫定対策**だ。公式が以下のいずれかをリリースした時点で役目を終える。

- Codex CLI 本体が日本語自然化を標準装備
- Pre-response hook の公式機構
- `PreSkillUse` / `PostSkillUse` hook（[Issue #17132](https://github.com/openai/codex/issues/17132)）

`docs/DEPRECATION.md` に撤去手順を先に書いた。公式観測の `gh search` コマンドも入れてある。archive 前提の設計は意外と解放感がある。

## 導入: 2 パターン

Windows + PowerShell 7+ + `uv` + `git` の入った環境を前提にする。

### パターン A: 超簡易導入（Codex に丸投げ）

手動コマンドが億劫な人向け。Codex CLI に下記のプロンプトをそのまま貼り付けるだけ。Codex が自律的に clone → `uv sync` → install → 動作確認まで走らせる。

````
次のリポジトリを自分のマシンに導入してほしい:
https://github.com/Sora-bluesky/codex-jp-harness

手順:
1. Documents\Projects\apps\ 配下に git clone する
2. リポジトリ内で `uv sync` を実行する（uv 未導入なら導入から）
3. `pwsh scripts\install.ps1 -AppendAgentsRule` を実行する
   （config.toml への MCP 登録と、AGENTS.md への 7.p ルール追記を一括で行う）
4. `mcp__jp_lint__finalize(draft="slice を進めた")` を呼んで ok:false が返ることを確認する
5. 完了したら、Codex CLI の再起動が必要であることを私に伝える

各手順の結果を簡潔に報告しながら進めてよい。
破壊的な操作が必要になった時だけ確認して。それ以外は自律的に進めてよい。
````

再起動後、Codex に「進捗報告を書いて」と頼めば自発的に `mcp__jp_lint__finalize` を呼ぶようになる。

### パターン B: 手動導入

スクリプトを読んでから入れたい人向け。

```powershell
git clone https://github.com/Sora-bluesky/codex-jp-harness.git
cd codex-jp-harness
uv sync
pwsh scripts\install.ps1 -AppendAgentsRule
```

`install.ps1` が 2 つを実行:

- `~/.codex/config.toml` に `[mcp_servers.jp_lint]` を追記（venv の Python を絶対パスで指定）
- `-AppendAgentsRule` フラグ付き実行時、`~/.codex/AGENTS.md` に `config/agents_rule.md` の 7.p ルール本文を追記

`AGENTS.md` に独自のルールがあって自動追記されたくない場合は、`-AppendAgentsRule` を外して `config/agents_rule.md` の内容を手で貼り付ければよい。

## まとめ

ここまでの要点を 5 つに圧縮する。

1. Codex の日本語出力は 6 種の問題で読みづらいが、runtime 強制を使わずにプロンプト層 + MCP finalize ゲートで 32 → 0 違反を達成できた
2. VOICEVOX の「音読される前提」という制約は、Codex の日本語 register を切り替える強力な directive になる
3. MCP finalize ゲートは Codex CLI で設計できる「Tier 2 介入」の現実解。TUI プロキシは ROI が悪い
4. 「Codex が自発的にツールを呼ぶか」は AGENTS.md の書き方で制御できる。発火トリガー・禁止事項・セルフチェックの 3 点が効く
5. 暫定対策は archive 前提で作ると、過剰設計が消えて本質だけ残る

コードは [`Sora-bluesky/codex-jp-harness`](https://github.com/Sora-bluesky/codex-jp-harness) に置いてある。導入は上記のパターン A（Codex に丸投げ）かパターン B（手動）のどちらかで 1 分ほど。Windows 向け。

最後に。OpenAI の日本語対応を誰よりも早く迎え入れて、このリポを archive する日を楽しみにしている。

---

**関連リンク**

- GitHub: [`sora-bluesky/codex-jp-harness`](https://github.com/sora-bluesky/codex-jp-harness)
- [OpenAI Codex CLI](https://github.com/openai/codex)
- [VOICEVOX](https://voicevox.hiroshiba.jp/)
- 関連 Issue: [#13386](https://github.com/openai/codex/issues/13386), [#17132](https://github.com/openai/codex/issues/17132), [#17532](https://github.com/openai/codex/issues/17532), [#18189](https://github.com/openai/codex/issues/18189)
