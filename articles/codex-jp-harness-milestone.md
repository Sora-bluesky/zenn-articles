---
title: "Codex の日本語を救ったのは「ずんだもん」だった"
emoji: "🎛️"
type: "tech"
topics: ["codex", "mcp", "ai", "openai", "個人開発"]
published: true
---

## はじめに

AGENTS.md（Codex の指示書）に「日本語で返してくれ」と書く。書いても、書いても、翌朝には `slice` と `parity` が混ざった直訳調の日本語が戻ってくる。ファイル名はバッククォート抜きで地の文に埋め込まれ、1 文に英語識別子が 7 個並んでいる。読めなくはない。でも、音読したら詰まる。

これは僕だけの話ではない。

- 「thinking（AI が考えている部分）を日本語にできず諦めた」という声（[Mojofull](https://x.com/furoku/status/1953970698877366648)）
- AGENTS.md に工夫を書いたら、コードのコメントまで日本語化されてしまった報告（[hpp](https://x.com/hpp_ricecake/status/1970629996298584485)）
- 「日本語で指示するより、全部英語で思考させた方が精度がいい」という実践者の共通見解（[zenn.dev/chiji](https://zenn.dev/chiji/articles/57cb52773391ab)）

つまり **Codex の素の日本語出力は実用水準に達していない** と、日本の現場は内々に認めている。CLI でも App でも、進捗報告を頼むとたとえばこうなる。

> TASK-306 を codex/task306-stdin-parity-20260417 で開始し、prompt_transport=stdin を受け入れて pane dispatch で send-paste 経由に流す実装を入れました。

朝いちに進捗報告を開いて「あ、今日もか」と呟く瞬間がある。読み切るのに 30 秒かかる。30 秒は人生からすれば一瞬だが、毎日だと真綿で首を絞められる感覚に近い。

公式が日本語対応を強化してくれるのが本筋だが、待っている間も業務は進む。そこで、**Codex が最終応答を出す直前に通る「検品係」** を MCP サーバーとして外付けした。結果、同じ報告を書かせても、読みにくい箇所（英単語の混入・長すぎる文・ファイル名の裸表記など）が 32 箇所から 0 箇所になった。

ちなみに、この読みやすさを救ってくれたのは、ずんだもんである。どういうことか、これから書く。リポジトリは [`Sora-bluesky/codex-jp-harness`](https://github.com/Sora-bluesky/codex-jp-harness) に置いてある。

## 先に結論

同じ進捗報告の指示に対して、3 段階で改善を重ねた。数字は「読みにくい箇所」の数である。

| 段階 | 読みにくい箇所 | やったこと |
|---|---|---|
| 施策前 | 32 | 何もしていない状態 |
| 音読前提の指示を追加 | 4 | 「ずんだもんに音読される場面を想像して書け」を AGENTS.md に追加 |
| 指示をさらに具体化 | **0** | 「いつ検品を呼ぶか・呼ばないのは違反・送信前のセルフチェック」を明記 |

面白いのは、**指示文の工夫だけで 87.5% が削れた** こと。実行時に呼び忘れを検知する仕組み（Stop hook）は最後まで使わなかった。

以下、どうやってこの結果にたどり着いたかを書く。

## 問題: 読みづらさの正体を 6 つに分解する

悪い例を 1 文挙げる。

> DesktopDigestItem の producer parity をそのままベストプラクティスで進めました。

この 1 文には 6 種類の問題が重なっている。

1. **英語の語順をそのまま日本語にしている**（`proceed with the producer parity of DesktopDigestItem` を機械翻訳したような並び）
2. **英単語がそのまま混ざる**（`parity` を訳さず助詞で直結）
3. **主語と動作主が曖昧**（誰が何をしたか省略した名詞止め）
4. **文の長さがバラバラ**（短い体言止めと長い複文が無秩序に混ざる）
5. **進捗・判断・事実が同じトーンで流れる**（見出しや強調で重要度を区別しない）
6. **助詞の選び方が直訳調**（「ベストプラクティスで進める」ではなく「ベストプラクティスに沿って進める」が自然）

1 つ 1 つは小さい癖だ。読み流せばなんとなく意味は通る。でも、これが毎日 10 本も 20 本も積み上がる。月末に振り返ろうと過去ログを開いた瞬間、**「これ、先月の自分が読んでも解読に 5 分かかるやつだ」** と気づく。そして解読に 5 分かけた自分を呪うことになる。

## 最初の失敗: ルールを書いても守られない

まず素直に、`~/.codex/AGENTS.md` に詳細な日本語ルールを書いた。原語で残すべき語、カタカナで書くべき語、動詞で区切る、名詞句を 3 つ以上連結しない、など 15 項目以上。書いているうちに「これは効くぞ」という確信が膨らんでいった。

翌朝、Codex が返してきた進捗報告には、見覚えのある `parity` と `dispatch` が揃って鎮座していた。昨日書いたルールなど、どこかへ消え去っていた。ルール自体は読まれている。ただ、実装で手を動かしているうちに元の癖が勝つ。毎回人間が指摘するのは続かない。

「ルールに書いてあるから守られる」は確率の話で、毎回 100% 守られる保証はない。僕が過去に何度もハマっている失敗パターンだった。**文書は、静かに無視される。**

## 調査: 出力を書き換える公式の仕組みはあるか

先に公式機能を調べた。`openai/codex` の Issue とドキュメントを漁った結果、以下が分かった。

- **AGENTS.md**: 32KB を超えると黙って切り詰められる問題あり（[#13386](https://github.com/openai/codex/issues/13386)）。グローバルとリポローカルを併用したときの動作が不明（[#18189](https://github.com/openai/codex/issues/18189)）
- **Skill の仕組み**: `~/.codex/skills/` を認識するが、発火するかどうかは LLM の判断まかせ。強制力はない
- **フックの仕組み**: `codex_hooks` フラグがある。SessionStart / Stop / Notification は動くが、リポジトリローカルの `config.toml` だと動かない Issue あり（[#17532](https://github.com/openai/codex/issues/17532)）
- **応答の直前に介入する仕組み（Pre-response hook）**: **存在しない**
- **PreSkillUse / PostSkillUse**: Issue [#17132](https://github.com/openai/codex/issues/17132) で提案中、未実装

結論、出力を書き換える公式の入り口は無い。実行時に強制するのは諦めて、「呼ばれたら効く」タイプの関所を自分で置くしかない。

## 設計: 4 段階のうち、第 2 段階を選ぶ

介入のやり方を 4 つ洗い出した。

| 段階 | 手段 | 実装の手間 | 読者の体験 | 強制力 |
|---|---|---|---|---|
| 1 | 応答の終了後に検知して、次のターンで書き直しを促す | 半日 | 読みにくい版も 1 度見える | 中 |
| **2** | **MCP の検品係を挟む** | **1〜2 日** | **整った版しか見えない** | **中〜高** |
| 3 | Codex を包む外部スクリプトで中継する | 1〜2 週 | 完全に透過 | 高 |
| 4 | ターミナル画面ごと自作のプロキシ経由にする | 数週 | 完全に透過 | 最高 |

段階 3 と 4 はターミナル画面を自作することになり、Codex のバージョンアップで壊れる運命を背負う。段階 1 は読みにくい版を一度ユーザーが見てしまう。

段階 2 は「Codex が応答を出す前に必ず通る関所を、MCP ツールとして用意する」設計だ。イメージは空港の出国審査に近い。パスポート（応答）を出すと審査官（検品係）が中身を見て、問題があれば突き返す。通ったものだけが外に出る。

- Codex が下書きを書く
- `mcp__jp_lint__finalize(draft)` を呼ぶ
- サーバーが問題を検出して `{"ok": false, "violations": [...]}` を返す
- Codex が指摘を見て書き直し、もう一度呼ぶ
- `{"ok": true}` が返るまで繰り返す
- 整った版だけがユーザーに届く

Codex に呼ばせる部分は AGENTS.md の指示で担保する。ここは頼りない部分だが、後述のとおり最終的には自発的に呼ぶようになった。

## 想定外のヒント: ずんだもんが文体を切り替えた

開発中、ビルド完了の通知をずんだもんに喋らせていた。[VOICEVOX](https://voicevox.hiroshiba.jp/) で合成した「終わったのだ」「テストが落ちたのだ」みたいな短いやつだ。Codex が `mcp__voicevox__speak` を呼んで一言だけ読み上げる。深夜に無表情でキーボードを叩いていると、ふいにずんだもんが喋るので、ちょっと気が和む。

https://x.com/0xfene/status/2033096160299332029?s=20

ある深夜、疲れた頭でそれを聞きながら、ふと気づいた。**この子が読み上げている日本語、チャット欄に返ってくる日本語より、明らかに自然じゃないか？** 100 文字以内に収まっていて、ファイル名や PR 番号のような音読できない識別子を自然に避けている。

なぜか。仮説を立てた。

- **100 文字という上限** が、英語識別子の詰め込みを物理的に防ぐ
- **読み上げるという用途** が、音読できない要素を排除する
- **ユーザーが耳で聞く** ので、意図が伝わることが最優先になる

つまり **「音読される」という前提が、Codex に文体を切り替えさせている**。逆に技術報告では「後から読み返せる」前提で、情報を詰め込む方向の力が働く。

この仮説、利用できないだろうか。AGENTS.md にこう書いた。

```
応答を書くとき、ユーザーがこの応答を VOICEVOX で読み上げる場面を想像する。
音読して自然に意味が通る文章が目標。英語識別子の羅列・名詞句の連鎖・
専門用語の直訳は音読で破綻する → 書き直す。
1 文は 80 文字以内を目安、英語識別子を含む文は 50 文字以内。
```

効果は絶大だった。同じ報告の指示で、読みにくい箇所が 32 → 4 件。ファイル名のバッククォート抜けは 20 → 0 件で完全に消えた。Codex は出力の時点で `slice` や `done` を「避けている」と自覚的に表明するようになった。

**具体的に想像できる対象を与える指示は、抽象的な「丁寧に書け」より桁違いに効く**。「良い文章を書け」と言われてもピンと来ないが、「ずんだもんが読み上げる場面を想像しろ」と言われると、脳内に絵が浮かぶ。絵が浮かぶ指示は、守られやすい。

## 実装: MCP の検品係

コード全体は [`Sora-bluesky/codex-jp-harness`](https://github.com/Sora-bluesky/codex-jp-harness) にある。中核は 3 ファイル。

### `config/banned_terms.yaml`（禁止語の元データ）

```yaml
banned:
  - { term: slice,     suggest: "限定的な変更、今回の範囲" }
  - { term: parity,    suggest: "差、差分、揃え" }
  - { term: done,      suggest: "完了" }
  - { term: dispatch,  suggest: "振り分け、受け渡し" }
  # 他に active, ready, squash, handoff, regression,
  # fail-close, fast-forward, contract drift（計 12 語）

identifier_pattern: "[A-Za-z_][A-Za-z0-9]*[._/-][A-Za-z0-9_./-]+"
identifier_limit_per_sentence: 2

sentence_length:
  enabled: true
  max_chars: 80
  max_chars_with_identifiers: 50
```

識別子パターンの妙は、**内部に `.`, `_`, `/`, `-` のいずれかを含むトークンだけ**を拾うところ。これで `HANDOFF.md`、`TASK-306`、`prompt_transport` は引っかかる。`slice`（単純英単語）や `Codex`（一般名詞）は引っかからない。単純英単語は `banned` 側で個別に拾う。網を 2 枚に分けることで、誤検知が減る。

### `src/codex_jp_harness/rules.py`（検品エンジン）

```python
from mcp.server.fastmcp import FastMCP  # server.py で使う

def detect_banned_terms(text: str, cfg: RuleConfig) -> list[Violation]:
    # バッククォート内とコードブロック内は除外
    scan = _strip_code_blocks(text)
    for entry in cfg.banned:
        pattern = re.compile(
            r"(?<![A-Za-z0-9_])" + re.escape(entry["term"]) + r"(?![A-Za-z0-9_-])",
            re.IGNORECASE,
        )
        # マスクして 1 行ずつ走査
```

工夫は 3 点。

- **コードブロックを除外**（` ``` ` で囲まれた範囲は検査しない）
- **インラインのバッククォートも除外**（ `` ` `` で囲まれた部分はマスク）
- **単語境界を守る**（`sliced` は `slice` に引っかけない）

誤検知を減らすために、`_mask_inline_code` でバッククォート内を同じ長さの空白に置換する。こうすると検査対象から外れつつ、カラム位置（何文字目か）はズレないので、指摘の「何行目の何文字目」が正確になる。

### `src/codex_jp_harness/server.py`（MCP ツールを公開する層）

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

FastMCP を使うとツール定義が 10 行で済む。Codex の `~/.codex/config.toml` に `[mcp_servers.jp_lint]` として登録すれば認識される。登録は後述の `install.ps1` が自動でやってくれるので、ここでは内容だけ示す。

```toml
[mcp_servers.jp_lint]
command = "C:\\Users\\<user>\\Documents\\Projects\\apps\\codex-jp-harness\\.venv\\Scripts\\python.exe"
args = ["-m", "codex_jp_harness.server"]
```

`install.ps1` は **venv（Python の仮想環境）の絶対パスを自動で検出して書き込む** ので、上記を手で書く必要はない。

最初につまずいた罠が 2 つあった。

1. **サーバー名の不一致**: 最初 `FastMCP("jp-lint")` とハイフン版にしてしまい、`config.toml` のアンダースコア版（`jp_lint`）とズレて `mcp__jp_lint__finalize` として解決できなかった
2. **システム Python 問題**: `command = "python"` にするとシステム側の Python が呼ばれ、そこには `mcp[cli]` が入っていないので import エラー。venv の Python を絶対パスで指す必要があった

どちらも Codex の MCP パネルでは緑のチェックマークが光って「有効」と表示される。でも `finalize` は呼ばれない。Codex は素知らぬ顔で読みにくい報告を返してくる。「おまえ、見てるんじゃないのか」と画面に問いかけること数回、1 時間が溶けた。導入スクリプトで自動化したので、他の人が同じ地雷を踏むことはなくなっている。

## 2 段構え: ツールの呼び忘れを防ぐ

MCP サーバーを用意しても、Codex が自発的に `finalize` を呼ばなければ検品係は空振りする。最初の実戦テストで実際にそうなった。`jp_lint` MCP は有効、ツールは公開されている。しかし Codex は一度も呼ばずに、読みにくい報告をそのまま返した。関所があっても、誰もそこを通らなかったら意味がない。

直感的な対処は Stop hook による実行時強制（前述の段階 1 との併用）だが、先に指示文だけを強化してみた。3 点を AGENTS.md に追加した。

- **① 呼び出しの合図**: 「やったこと／確認結果／次にやること」の見出しが現れたら、それは報告である。`finalize` を呼ぶのは必須
- **② 禁止事項**: `finalize` を呼ばずに日本語の技術報告を返すことは **ルール違反** と明記
- **③ 送信前セルフチェック**: 応答を送る直前に「このターンで `finalize` を呼んだか?」を自問

結果、Codex は自発的に 2 回 `finalize` を呼ぶようになった。1 回目は 6 件の問題で `ok: false` が返り、指摘を読んで書き直し、2 回目で `ok: true`。きれいな書き直しループが動いた。

**実行時に強制する仕組みを実装せず、残り 12.5% を指示文の工夫だけで拾い切った**。最初は「結局 hook 書かないと無理だろうな」と思っていたので、これは嬉しい誤算だった。

## 結果: 32 → 0

3 段階の推移を並べ直す。列名の意味は次のとおり。

- `banned_term`: 禁止語（slice、parity、done など 12 語）が混入した数
- `bare_identifier`: ファイル名・ブランチ名などがバッククォートなしで地の文に書かれた数
- `sentence_too_long`: 1 文が長すぎる（80 文字超、識別子を含む文は 50 文字超）
- `too_many_identifiers`: 1 文に英語識別子が 3 個以上ある

| 段階 | 合計 | banned_term | bare_identifier | sentence_too_long | too_many_identifiers |
|---|---|---|---|---|---|
| 施策前 | 32 | 4 | 20 | 6 | 2 |
| 音読前提の指示を追加 | 4 | 1 | 0 | 3 | 0 |
| 指示をさらに具体化 | **0** | 0 | 0 | 0 | 0 |

確認用のテキスト（fixture）は `tests/fixtures/codex_*.txt` として 3 本リポに入れてある。検品エンジンに通せば誰でも同じ数字を再現できる。

## 知見: 指示文の工夫だけで大半が解決する

この実装を通して得た、実測に基づく知見は 3 つ。

### 1. 指示文だけで 87.5% は取れる

実行時の強制ゼロで、AGENTS.md のルール文だけでここまで削れるのは想定外だった。「強制しないと守られない」という先入観があったが、**具体的で想像できる指示を与えれば、大半は自主規律で処理できる**。強制は、いざというときの保険でいい。

### 2. 想像できる対象を与える指示は強い

「丁寧な日本語を書け」は抽象的すぎて効かない。「ずんだもんに音読される想定で書け」だと、脳内に具体的な絵が浮かぶ。絵が浮かぶ指示は、守られやすい。他のプロンプト強制ゲートにも応用できるはずだ。読み手や聞き手を具体的な人物（あるいはキャラクター）に置き換える、というテクニックは、人間が人間に指示を出すときと同じ原理かもしれない。

### 3. 実行時の強制は保険で十分

応答終了後に呼び忘れを検知する Stop hook は、最初から実装する予定だった。が、指示文の強化だけで 100% 到達したので保留した。「多層防御の最後の砦」として、次のバージョンの任意機能に降格させた。**実行時の強制は無くても回る**、というのが今回の一番の発見である。

## 限界と、この対策をいつ捨てるか

この暫定対策には本質的な限界がある。

- **Codex に応答直前の介入口が無い** ので、Codex が `finalize` を呼ばなかった場合に後から捕まえるには別の仕組みが必要
- **Codex のバージョンアップで品質が戻る（デグレする）可能性** あり。月 1 回の観測で検知する
- **形態素解析を使っていない** ので、名詞句の連鎖検出は簡易ルール。必要なら fugashi を足して精度を上げられる

そして最重要。これは **暫定対策** である。公式が以下のいずれかをリリースした時点で役目を終える。

- Codex CLI 本体が日本語自然化を標準装備
- 応答直前に介入する公式の仕組み
- `PreSkillUse` / `PostSkillUse` フック（[Issue #17132](https://github.com/openai/codex/issues/17132)）

`docs/DEPRECATION.md` に撤去手順を先に書いた。公式の動きを観測する `gh search` コマンドは `docs/OPERATIONS.md` に入れてある。**「いつ捨てるか」を先に決めて作ると、妙な開放感がある**。未来永劫メンテし続けると思うと機能を足し続けてしまうが、「公式対応が来たら捨てる」と決めると、今必要な最小限だけ作ればよくなる。

## 導入: 2 パターン

前提: Windows + PowerShell 7+ + `uv` + `git` + Codex CLI（`~/.codex/` が存在する）が揃っている環境。

### パターン A: 超簡易導入（Codex に丸投げ）

手動コマンドが面倒な人向け。Codex CLI に下記のプロンプトをそのまま貼り付けるだけ。Codex が自律的に clone → `uv sync` → install → 動作確認まで進める。

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

`install.ps1` は次の 2 つを実行する。再インストールしても、既存の登録を書き直すだけなので安全に動く。

- `~/.codex/config.toml` に `[mcp_servers.jp_lint]` を追記（venv の Python の絶対パスを自動で検出して埋め込む）
- `-AppendAgentsRule` を付けて実行したとき、`~/.codex/AGENTS.md` に `config/agents_rule.md` の本文を追記する

`AGENTS.md` に独自のルールがあって自動追記されたくない場合は、`-AppendAgentsRule` を外し、`config/agents_rule.md` の内容を手で貼り付ければよい。

## まとめ

ここまでの要点を 5 つに圧縮する。

1. Codex の日本語出力には 6 種類の癖がある。でも、実行時の強制を使わず、指示文の工夫＋ MCP 検品係だけで、読みにくい箇所を 32 → 0 に減らせた
2. ずんだもんの「音読される」前提は、Codex の日本語の文体を切り替える強力な指示になった。抽象的な「丁寧に書け」より、絵が浮かぶ指示の方が桁違いに効く
3. MCP の検品係は、Codex で設計できる「第 2 段階の介入」の現実解である。ターミナル画面の自作はコストが合わない
4. 「Codex が自発的にツールを呼ぶか」は AGENTS.md の書き方で制御できる。呼び出しの合図・禁止事項・送信前セルフチェックの 3 点が効く
5. 暫定対策は「いつ捨てるか」を先に決めて作ると、過剰設計が消えて本質だけ残る

コードは [`Sora-bluesky/codex-jp-harness`](https://github.com/Sora-bluesky/codex-jp-harness) に置いてある。導入は上のパターン A（Codex に丸投げ）かパターン B（手動）のどちらかで 1 分ほど。Windows 向け。

最後に。OpenAI の日本語対応を誰よりも早く迎え入れて、このリポを役目終わりにする日を楽しみにしている。その日まで、ずんだもんには毎晩喋ってもらう。

## v0.2.0 で入った拡張（2026-04-18 追記）

記事公開後、自分で毎日使っているうちに「12 語だと足りない」「このプロジェクトでは `slice` を公式用語として使っているから緩めたい」という場面が出てきた。全部を 1 つの yaml に詰め込むと、他の人の事情と衝突する。そこで v0.2.0 で 4 つを足した。

### 禁止語 12 → 26 語

普遍的に読みにくくなるカテゴリを追加。

- プロセス系: `merge`, `rebase`, `cherry-pick`
- 概念系: `fingerprint`, `fallback`, `fixture`, `payload`, `helper`, `wrapper`
- 状態系: `pending`, `idle`
- レビュー系: `verdict`, `blocker`

加えて、`冪等` を入れた。自分の README で「冪等に動く」と書いていたのが、読み上げさせたら詰まったので、自ツールで自分を叩く形になった。

### severity 三段階（ERROR / WARNING / INFO）

v0.1.x は「1 件でも違反があれば `ok: false`」という硬い判定だった。運用しているうちに「これは直さなくていい」「むしろ指摘として残しておきたい」の中間が欲しくなった。

- **ERROR**: これがゼロになるまで `ok: true` は返さない（書き直し必須）
- **WARNING**: `advisories` フィールドで通知される（無視できる）
- **INFO**: 同上、参考情報

`finalize` の返り値も `5件の違反を検出 (3 ERROR, 1 WARNING, 1 INFO)` のように内訳を返すようにした。書き直しループは ERROR のみが回る。

### User-local override（`~/.codex/jp_lint.yaml`）

リポジトリのバンドル規則を触らず、利用者側で調整できる。探索優先順位は `$CODEX_JP_HARNESS_USER_CONFIG` → `$XDG_CONFIG_HOME/codex-jp-harness/jp_lint.yaml` → `~/.codex/jp_lint.yaml`。ファイル不在ならバンドル値がそのまま使われる。

```yaml
disable:
  - slice          # プロジェクト用語として常用するなら外す
overrides:
  handoff:
    severity: WARNING
add:
  - term: foobar
    suggest: "foobar は日本語訳を使う"
    severity: ERROR
```

### `codex-jp-tune` CLI

override ファイルを対話的に編集するコマンド。`pyyaml` だけに依存する軽量スクリプト。

```bash
codex-jp-tune path                        # 設定ファイルパス
codex-jp-tune show                        # 有効な禁止語一覧
codex-jp-tune disable <term>              # 無効化
codex-jp-tune enable <term>               # 無効化の取り消し
codex-jp-tune set-severity <term> WARNING # severity 調整
codex-jp-tune add <term> --suggest "..."  # 追加
```

### `jp-harness-tune` skill（Claude Code 用）

`codex-jp-tune` は手が早い分、安易に無効化されやすい。そこで、Claude Code 用に **「本当にルールを緩める必要があるか」を問い直す skill** を同梱した（`skills/jp-harness-tune/skill.md`）。類義の日本語表現で置換できるなら、緩めずに書き直す方向へ誘導する。`~/.claude/skills/` に置けば `/jp-harness-tune` で呼べる。

1 つのルールを緩めると、そのぶん書き手の自主規律は下がる。緩めるかどうかの判断にもう 1 人の目を挟む、という設計である。

### cross-platform

当初は Windows + PowerShell 専用だったが、`install.sh` を追加して macOS / Linux / Git Bash on Windows でも動くようになった。Git Bash 上では MSYS パスを native Windows 形式に自動変換する。

---

v0.2.0 の各機能の背景は、GitHub の [Release v0.2.0](https://github.com/Sora-bluesky/codex-jp-harness/releases/tag/v0.2.0) にも書いてある。

---

**関連リンク**

- GitHub: [`Sora-bluesky/codex-jp-harness`](https://github.com/Sora-bluesky/codex-jp-harness)
- [OpenAI Codex CLI](https://github.com/openai/codex)
- [VOICEVOX](https://voicevox.hiroshiba.jp/)
- 関連 Issue: [#13386](https://github.com/openai/codex/issues/13386), [#17132](https://github.com/openai/codex/issues/17132), [#17532](https://github.com/openai/codex/issues/17532), [#18189](https://github.com/openai/codex/issues/18189)
