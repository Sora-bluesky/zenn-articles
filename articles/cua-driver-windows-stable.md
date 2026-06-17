---
title: "Cua Driver を Windows / Codex で検証した: 背景操作と no-focus-steal まで確認"
emoji: "🖥️"
type: "tech"
topics: ["cua", "mcp", "windows", "codex"]
published: false
---

## この記事で分かったこと

2026-06-05 時点で、Cua の公式ドキュメントを Windows / Codex 環境で確認しました。

結論から言うと、手元では **Cua Driver は限定的に使えるところまで確認できました**。中心の証拠は、明示パスの `cua-driver`、Codex からの read-only MCP tool、Calculator 限定の背景 UIA 操作です。

その後の追加検証で、制御済み WinForms / WPF 表示デモ、legacy-like form、`cmd.exe` への背景操作、recording artifact、一時 daemon、限定 installer、autostart の一時登録と復旧、さらに `launch_app(path)` の no-focus-steal integration test 1 件まで確認しました。

一方で、**Cua 全体が Windows / Codex で使える**とはまだ言いません。Cua MCP Server の AI task、VM / host desktop、screenshot、session cleanup、任意アプリ操作、WPF QA loop、動画録画、replay、PiP は未検証です。

## 検証の前提

今回の記事は、公式ドキュメントの内容を手元の Windows 環境でどこまで再現できたかを整理したものです。

手元で確認した `cua-driver` は `0.4.1` です。`PATH` へ追加して常用化するのではなく、インストール済み binary を明示パスで呼び出す形に限定しました。User PATH の編集、autostart の設定、Scheduled Task の作成、persistent daemon の起動はしていません。

また、Cua MCP Server については、Cua Driver とは別 runtime として扱いました。isolated venv で server 起動、`tools/list`、read-only の `get_session_stats` tool call までは確認しています。ただし `run_cua_task`、`run_multi_cua_tasks`、`screenshot_cua`、`cleanup_session` は未実行です。

## Cua は 2 つに分けて見る

公式ドキュメントを読むと、少なくとも次の 2 つを分けた方が安全です。この記事では、手元で検証した範囲に絞ります。

| 層 | 何をするものか | 今回の扱い |
| --- | --- | --- |
| Cua Driver | ローカル desktop を CLI / MCP から操作する driver | 一部を実測 |
| Cua MCP Server | AI task、session、VM または host desktop、screenshot を扱う MCP server | install / server 起動 / `tools/list` / read-only `get_session_stats` まで |

Cua Driver は、MCP over stdio と CLI の両方から使える単一 binary の driver です。Windows では UI Automation、Win32 API、named pipe、必要に応じた Scheduled Task が関係します。

今回参照した主な公式ドキュメント:

- https://cua.ai/docs/cua-driver/guide/getting-started/introduction
- https://cua.ai/docs/cua-driver/reference/mcp-tools
- https://cua.ai/docs/cua/reference/mcp-server/tools

## Cua Driver の特徴は「前面化」ではない

Cua Driver の重要な特徴は、対象アプリを前面に出して操作することではありません。

公式ドキュメントでは、ユーザーの前面作業を保ったまま、対象 window の状態取得や操作を行う前提になっています。Windows では UI Automation と Win32 API を使い、必要な場合だけ foreground fallback を考える設計です。

今回の検証でも、成功条件を次のように置きました。

| 条件 | 見るもの |
| --- | --- |
| 対象を前面化しない | `active:false`、非最前面 window |
| UIA element を使う | `get_window_state` で `element_index` を取得 |
| 背景経路で操作する | `click(element_index)` が UIA 操作として届く |
| 状態差分を見る | 操作後に再度 `get_window_state` で表示変化を確認 |
| 後片付けする | 対象アプリや daemon が残らないことを確認 |

## 手元で確認できたこと

### 1. 明示パスの `cua-driver` は動いた

手元の環境では、`PATH` から bare `cua-driver` は解決できませんでした。

ただし、インストール済みの明示パスにある `cua-driver.exe` は `cua-driver 0.4.1` として動きました。`--version`、`status`、`autostart status`、`list-tools`、`describe` は読み取り用途で確認できています。

ここでは User PATH の編集はしていません。

### 2. Codex から read-only MCP tool を呼べた

Codex 側から Cua Driver の MCP tool が見えることを確認し、read-only の `get_screen_size` を呼べました。

これは Codex の session から Cua Driver の read-only tool を呼べるかの確認です。アプリ操作や背景操作の成功証拠としては扱いません。

### 3. Calculator 限定で背景 UIA 操作が届いた

Calculator を対象に、次の流れを確認しました。

1. Calculator を `active:false` で起動する
2. window stack を見て、Calculator が最前面ではないことを確認する
3. `get_window_state(capture_mode=ax)` で UIA tree と `element_index` を取得する
4. `click(element_index)` を実行する
5. 再度 `get_window_state` し、表示が変わったことを確認する
6. Calculator を閉じる

結果として、非最前面の Calculator に対して `UIA Invoke` が届き、表示も変化しました。これは Cua Driver の背景 UIA 操作の実測証拠として扱えます。

ただし、これは **Calculator 限定**です。Notepad、browser、custom UI、canvas、ゲーム系 UI でも同じように動くとはまだ書けません。

### 4. 制御済みアプリでも背景操作を確認した

Calculator 以外では、制御済みの WinForms デモ、WPF 表示デモ、legacy-like form、`cmd.exe` で背景操作を確認しました。

ここで重要なのは、実在業務アプリで確認したわけではない、という点です。記事用の #08 / #09 は WPF 風の制御済み表示デモであり、実 WPF helper の修復成功や WPF QA loop の成功証拠ではありません。

### 5. `launch_app(path)` の no-focus-steal test が 1 件通った

`launch_app(path)` については、最初の検証では Electron test app を検出できず、test は skip 相当でした。

切り分けの結果、stdio MCP 経路では agent cursor overlay の full virtual-screen-sized layered-window update が response を止める有力候補として残りました。そこで、描画対象がない overlay tick だけ transparent 1x1 update に退避する小さな変更を試しました。

その後、`test_launch_app_no_focus_steal` は skip message なしで 1 件成功しました。つまり、Cua Driver の official integration test でも no-focus-steal を 1 件確認できた、とは書けます。

ただし、これは 1 件の integration test 成功です。任意アプリ、WPF QA loop、実在業務アプリ、Cua MCP Server の AI / screenshot tool が成功した、とは書きません。

### 6. Cua MCP Server は read-only tool まで確認した

Cua MCP Server は、isolated venv で install、server 起動、`tools/list`、read-only の `get_session_stats` tool call まで確認しました。

一方で、次の 4 tool は未実行です。

| 未実行 tool | 境界 |
| --- | --- |
| `run_cua_task` | API key、provider model、VM / host desktop、AI task、final screenshot に進む |
| `run_multi_cua_tasks` | 複数 task と concurrency に進む |
| `screenshot_cua` | VM / host desktop の screenshot と画像公開可否に進む |
| `cleanup_session` | session lifecycle を変える |

Cua Driver の背景操作や integration test 成功は、Cua MCP Server のこれらの tool が動いた証拠にはしません。

## まだ確認していないこと

今回、次の操作はしていません。

| 未検証 | 理由 |
| --- | --- |
| 任意の Windows アプリ操作 | 制御済みアプリでは確認したが、実在業務アプリや任意アプリには広げていない |
| Notepad 背景 UIA 操作 | 次の検証候補だが、別承認に分けた |
| WPF QA loop | 実 WPF helper は FontCache 初期化で失敗。記事用 #08/#09 は制御済み表示デモ |
| Cua MCP Server の AI / screenshot 系 tool | `get_session_stats` までは成功。残 4 tool は未実行 |
| default installer one-liner | User PATH / autostart 変更を伴うため未確認 |
| SSH daemon | persistent daemon や remote access に進む |
| 動画録画 / replay / AI review | `record_video:false` の artifact 生成まで。動画、replay、review は未検証 |
| PiP | UI 表示と設定に進むため未検証 |
| update / uninstall | OS や install state を変える |

特に Cua MCP Server は、Cua Driver とは別物として扱いました。`tools/list` と read-only `get_session_stats` までは確認しましたが、AI task、VM / host desktop、screenshot、session cleanup には進んでいません。現時点では「Cua MCP Server 全体が動いた」とは書けません。

## 記事としての現時点の結論

Windows / Codex 環境では、Cua Driver の明示パス運用、read-only MCP tool、制御済みアプリでの背景操作、`launch_app(path)` の no-focus-steal integration test 1 件まで確認できました。

Cua Driver の面白いところは、対象アプリを前面に出すのではなく、ユーザーの前面作業を保ったまま UIA element を取得し、背景経路で操作し、再取得で状態差分を見る点です。

ただし、任意アプリ、実在業務アプリ、WPF QA loop、Cua MCP Server の AI / screenshot 系 tool、SSH daemon、動画録画、replay、PiP まではまだ検証していません。現時点では「Cua Driver は限定的に使えた」と書くのが正確です。

## 次にやるなら

次に記事価値が高いのは、実際の本文から未検証の断言を外すことです。特に、合成カーソル、複数エージェント、WPF QA loop、実在業務アプリ、動画 / replay、Cua MCP Server の AI / screenshot tool は、実測済みと公式紹介を分けて書く必要があります。

追加検証としては、Notepad 1 件の背景 UIA 操作、Cua MCP Server の `screenshot_cua` または `run_cua_task` の実行契約、あるいは WPF harness の再挑戦が候補です。

ただし、Cua MCP Server の残 tool は API key、VM / host desktop、screenshot、session lifecycle に進むため、いきなり実行せず、対象 session、画像の扱い、secret の扱い、cleanup を固定してから進めます。
