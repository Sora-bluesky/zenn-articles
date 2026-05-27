---
title: "Hermes Agentの公開SSHをTailscaleで安全に閉じる"
emoji: "🔒"
type: "tech"
topics: ["tailscale", "vps", "ssh", "hermes", "ubuntu"]
published: false
---

:::message
このシリーズはHermes AgentをVPSに常駐させるまでの実録だ。全7回を予定している。

- 第1回──Hermes AgentをVPSに常駐させる(契約からログインまで)
- **第2回**(本記事)──Hermes Agentの公開SSHをTailscaleで安全に閉じる
- 第3回──Hermes Agentの秘密情報を1Passwordで平文に出さない運用
- 第4回──Hermes Agentをインストールする(DockerサンドボックスとHermes setup)
- 第5回──Hermes AgentをCodex/GrokとTelegramに繋ぐ(承認モード固定の作法)
- 第6回──Hermes Agentをsystemdで24時間常駐させる
- 第7回──Hermes Agentの手足に自宅のデスクトップを使う(Wake-on-LANとzellij)
:::

## はじめに

第1回でVPS(XServer VPS 6GB/Ubuntu 26.04)にadminでSSHログインできる状態+rootのSSHログインを閉じるところまで来た。ただ、adminのSSHは22番ポートで全世界から接続可能な状態のままだ。世界中のIPからブルートフォースを試みる対象になっている。

第2回ではこの公開22番そのものを閉じる。代わりにTailscaleという**仮想プライベートネットワーク**(VPN)を使い、自分の端末とVPSだけが見える非公開のトンネルを作る。SSHはそのトンネルの中だけで動かす。

実機で打ちながら書いたメモなので、きれいな手順書ではない。詰まった場所も含めて読んでもらいたい。

## 第1回と第2回の差分

| 項目 | 第1回完了時(現状) | 第2回完了後(ゴール) |
|---|---|---|
| VPSの22番ポート | 全世界に開放 | 外部から閉鎖 |
| SSH接続経路 | グローバルIP→22番→admin | Tailscale IP(`100.x.x.x`)→22番→admin |
| 攻撃面 | 世界中のIPからの接続試行 | 同じTailnet内の端末のみ |
| 命綱 | シリアルコンソール | シリアルコンソール(変わらず) |

## そもそもTailscaleとは

Tailscaleは、WireGuardという技術を使った仮想プライベートネットワーク(VPN)サービスだ。複数の端末を1つの仮想LANに参加させ、インターネットを経由せずに端末同士で通信できるようにする。無料プランで最大100台まで参加可能。

登場する用語を整理しておく。

| 用語 | 意味 |
|---|---|
| Tailnet | 自分のTailscaleアカウントに紐づくプライベートネットワーク名。アカウント単位で1つ |
| Tailscale IP | `100.x.x.x`形式の仮想IPアドレス。Tailnet内でのみ通信可能 |
| Tailscale SSH | TailscaleがSSH鍵管理を代行する機能。Tailnet内のマシン間なら鍵不要で接続できる |
| MagicDNS | Tailscaleマシン名(`hermes-vps`等)をTailscale IPに自動解決する機能 |
| tailscale0 | Tailscaleが作る仮想ネットワークインターフェース名 |

### Tailscaleはネットワーク変化に強い

Tailscaleを採用する大きな理由のひとつが、**グローバルIPアドレスの変化に強い設計**になっていることだ。会社・自宅・カフェ・モバイル回線・出張先のホテル、物理ネットワークが何度変わっても同じTailnetで通信が継続する。手元PCはTailscaleに一度参加させれば、その後どこから接続してもVPSに入れる。

| 仕組み | 効果 |
|---|---|
| マシン認証はトークン+鍵 | グローバルIPで紐づけしないので、ネットワークが変わっても同じマシン扱い |
| Tailscale IPは仮想 | 物理ネットワークから独立。会社のWi-Fi・自宅のWi-Fi・テザリング、どこからでも同じTailnetで通信 |
| 厳しいネットワーク環境でも通る | 会社や宿のWi-Fiでも、特殊な技術(WireGuard等)で自動的にトンネルを通してくれる |

:::message
私はこの第2回の作業を[スタバの無料Wi-Fi](https://www.starbucks.co.jp/mobile-app/wi-fi/)(My Starbucks会員専用Wi-Fi)で進めたが、自宅に戻ってもTailscale経由のSSHはそのまま動き続けた。Tailnetに一度参加させた端末は、Tailscaleアプリが緑になっていれば物理回線を問わず使える。
:::

## 構成の全体像(第2回終了時点)

第1回で導入したアーキテクチャ図のうち、第2回では「Tailscaleの専用通路」と「VPSの22番閉鎖」のブロックを完成させる。

![Hermes Agent運用の全体像(VPS司令塔+自宅デスクトップ手足の2層分離)](/images/hermes-architecture.png)

第2回終了時点で、手元PCからVPSへの接続経路は2系統から1系統に絞られる。グローバルIP+22番経由のSSHは閉じ、Tailscale IP(`100.x.x.x`)+22番経由だけが残る。

## 事前準備──命綱の確保と1Passwordアイテム

:::message alert
ここから先がシリーズ最大のロックアウト危険ゾーンだ。**公開22を閉じる前にTailscale経由で入れることを確認**してから初めて閉じる。順番を逆にすると、SSHでもTailscaleでも入れない事故になり得る。シリアルコンソールだけが残された生還経路になる。
:::

### Tailscale Authアイテムを1Passwordに作る

第3回(1Password運用)で扱うが、ここでもTailscale関連情報の保管場所を先に作っておく。

Hermes-Prod保管庫で新規アイテムを作成する。種類は「ログイン」を選ぶ。

| 項目 | 値 |
|---|---|
| タイトル | `Hermes VPS - Tailscale auth` |
| ユーザー名 | TailscaleログインのSSOメールアドレス(Google等) |
| パスワード | 空のままでOK |
| Webサイト | `https://login.tailscale.com` |
| メモ | マシン名・Tailscale IP・キー期限の状態をテンプレで書いておく |

パスワードを空にする理由は、TailscaleはSSO認証(Google/Microsoft/Apple/GitHubのいずれかのアカウントでログイン)なので、Tailscale自体に独自のパスワードが存在しないため。

Tailscaleアカウント本体は通常SSO(Google/Microsoft/Apple/GitHubのアカウント)でログインするので、Tailscale自体のパスワードを生成する必要はない。1Passwordに登録するのは「Tailscale関連情報の集約場所」としての意味合いが強い。

### シリアルコンソールタブを開いておく(命綱)

XServerパネル→VPS管理→対象サーバー→「コンソール」→「シリアルコンソール」で開いて、ENTERでログインプロンプトを出した状態で別タブに残しておく。ログインしないでOK。何かあった時の生還経路。

![シリアルコンソールでloginプロンプトが出ている状態(命綱として確保)](/images/hermes-vps-02-serial-console-ready.png)

### adminセッションを2タブ用意する

手元PCのPowerShellで2つのタブを用意する。

**タブA**(グローバルIP経由):

```bash
ssh -i ~/.ssh/hermes_vps_ed25519 admin@<グローバルIP>
```

![タブA:グローバルIP経由でadminでログインできた状態](/images/hermes-vps-02-tab-a-global-ssh.png)

タブBは後述「3. Tailscale経由でadminログイン確認」でTailscale経由で開く。今は空のままでOK。タブの混同を避けるため、タブタイトルを右クリック→「タブの名前を変更」で「VPS-Global」「VPS-Tailscale」等にリネームしておくと迷わない。

## 1. VPSにTailscaleを入れてTailnetに参加させる

### インストールスクリプト実行

タブAのadminセッションで以下を実行する。

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

このコマンドは「Tailscale公式の配布スクリプトをダウンロードして即実行する」という指示だ。各オプションの意味は以下。

| 部分 | 意味 |
|---|---|
| `curl` | URLからファイルを取得するコマンド |
| `-f` | HTTPエラーで失敗扱いにする(fail on error) |
| `-s` | 進捗バーを出さない(silent) |
| `-S` | silentでもエラーは表示する(Show errors) |
| `-L` | リダイレクトを追従する |
| `\| sh` | ダウンロードしたスクリプトをシェルに渡して実行 |

途中で`sudo`のパスワードを聞かれたら、1Passwordの`Hermes VPS - admin`を貼り付ける。

完了後、バージョンを確認する。

```bash
tailscale --version
```

数字3桁(`1.98.3`等)+commit hash+goバージョンが返ればOK。

### Tailnetに参加(認証)

```bash
sudo tailscale up --ssh
```

`--ssh`フラグはTailscale SSH機能を有効化する指定だ。Tailnet内のマシン間ならSSH鍵不要で接続できるオプションで、後の回で活用する選択肢を残すために今のうちから有効化しておく。

実行すると、画面に認証URLが表示される。

```
To authenticate, visit:

	https://login.tailscale.com/a/xxxxxxxxxxxxxxxx
```

このURLを手元PCのブラウザで開き、Tailscaleアカウントでログインする(初回ならGoogle/Microsoft/GitHub/AppleのSSO)。マシン情報の確認画面で「Connect」をクリック。

### 初回利用時のマーケティングアンケート画面

ログイン直後、Tailscale側のマーケティングアンケート画面が出る。

![Tailscale初回利用時のマーケティングアンケート画面](/images/hermes-vps-02-tailscale-survey.png)

これはTailscaleの動作には影響しない。気にせずスキップすればよい。ただし、ウィザード完了を強制される設計なので、URL直打ちで`/admin/machines`に飛んでも自動でアンケートに戻される。一度だけ適当に埋めて先に進む。

| 項目 | 推奨選択 |
|---|---|
| Primary reason | Personal or At-Home Use |
| Role | Engineer(またはPersonal user) |
| VPN providers | I don't use a VPN |
| How did you hear (optional) | 空欄でOK |

「Next: Add your first device」のあとに「もう1台つなぎませんか」のウィザード画面が出るが、VPSは既に参加済みなのでスキップ。

![Wizard「Add second device」画面:VPSは既に参加済みなのでスキップ可](/images/hermes-vps-02-wizard-add-device.png)

### VPSのTailscale情報を取得

VPS側のターミナルに戻り、参加できたかを確認する。

```bash
tailscale status
tailscale ip -4
```

`tailscale status`はTailnet内の全マシン一覧、`tailscale ip -4`は自分のVPSのTailscale IPv4アドレス(`100.x.x.x`)を返す。

ブラウザの`https://login.tailscale.com/admin/machines`を開いても同じことが確認できる。最初は1機(VPSのみ)が緑ドット(オンライン)で表示されているはず。

![Tailscale admin consoleでVPSが1台だけ参加した状態](/images/hermes-vps-02-machines-vps-only.png)

取得したTailscale IPは1Passwordの`Tailscale Auth - hermes-vps`のメモ欄に記録しておく。

## 2. 手元PCにもTailscaleを入れる

`https://tailscale.com/download/windows`からインストーラをダウンロードして実行する。インストール後、タスクトレイのTailscaleアイコンをクリック→「Log in」→VPSと同じTailscaleアカウントでログイン。

PowerShellで参加状況を確認する。

```bash
tailscale status
```

VPSと手元PCの両方が`100.x.x.x`のIPで表示されればOK。

![手元PCのtailscale statusでVPSと自分が両方表示される](/images/hermes-vps-02-tailscale-status-client.png)

Tailscale admin consoleでも、`2 machines`と表示されてVPS+PCの2台がオンライン表示になる。

![Tailscale admin consoleで2台(VPS+PC)が両方Connectedになった状態](/images/hermes-vps-02-machines-both-connected.png)

## 3. Tailscale経由でadminログイン確認(最重要)

ここで入れないうちは絶対に次に進まない。新しいPowerShellタブ(タブB)を開く。

```bash
ssh -i ~/.ssh/hermes_vps_ed25519 admin@<VPSのTailscale IP>
```

初回はhost key fingerprint確認→`yes`+ENTER→パスフレーズを1Passwordの`Hermes VPS - SSH key passphrase`から貼り付け。

![タブBでTailscale経由adminログインに成功した直後のプロンプト表示](/images/hermes-vps-02-tab-b-tailscale-ssh.png)

ログイン成功すると、見た目はタブAと同じ`admin@<ホスト名>:~$`プロンプトになる。経路がTailscale IPになっていることを明示するには、ログイン直後に以下を実行する。

```bash
echo "via Tailscale ($(echo $SSH_CONNECTION | awk '{print $1}'))"
```

`via Tailscale (100.x.x.x)`と表示され、接続元クライアントのTailscale IPが確認できる。

![タブBでTailscale経由adminログイン+via Tailscale echoで接続元IP確認](/images/hermes-vps-02-tab-b-via-tailscale-echo.png)

`sudo whoami`で`root`が返ることも確認しておく。Tailscale経由ログインでもsudoが効く=Hermes運用で必要な管理権限が同じく通ることの裏取りだ。adminのログインパスワード(1Passwordの`Hermes VPS - admin`)を聞かれる。

これでタブAとタブBの両方でadminセッションが生きている状態になった。グローバルIP経由とTailscale IP経由の2系統が同時に動いている。

## 4. 公開22番を二重に閉じる

次の3つを全て満たしているか最後に確認してから進む。

- タブAでadminセッションが生きている
- タブBでTailscale経由adminログインが成立した
- シリアルコンソールタブが別ウィンドウで生きている

### 4-1. XServerパケットフィルターで22番を削除

XServerパネル→VPS管理→対象サーバー→左メニュー「パケットフィルター設定」を開く。

![XServerパケットフィルター設定でSSH(22)ルールが残っている状態。削除ボタンをクリックする](/images/hermes-vps-02-xserver-before-delete.png)

第1回で追加した`SSH(プロトコル:TCP、ポート:22、許可する送信元IPアドレス:全て許可)`ルールを「削除」をクリックして消す。確認ダイアログで「OK」。

![SSH(22)ルール削除後の状態。接続許可ポートが何もない](/images/hermes-vps-02-xserver-after-delete.png)

「現在、接続許可ポートはありません。」と表示されればOK。反映に1〜2分かかる。

この操作の直後、タブA(グローバルIP経由)が数十秒〜1分以内に切断される。これは想定通り。タブB(Tailscale経由)は生きたまま。

### 4-2. VPS上のUFWでも閉じる(二重防御)

:::message alert
**必ずタブBで実行する**(タブBはTailscale経由のセッション)。タブAのグローバルIP経由は4-1で切断済みのはずだが、別端末などから誤ってグローバル経由でUFWを有効化すると、`tailscale0`の許可を入れる前に全入口が閉じてロックアウトする事故が起きうる。「`allow`を先に入れる→`enable`」の順序も厳守。
:::

タブB(Tailscale経由)で以下を順に実行する。

```bash
sudo ufw allow in on tailscale0
sudo ufw enable
sudo ufw status verbose
```

それぞれの意味は以下。

| コマンド | 意味 |
|---|---|
| `sudo ufw allow in on tailscale0` | `tailscale0`(Tailscaleが作る仮想ネットワークインターフェース)からの入力を許可。それ以外の入口は遮断される |
| `sudo ufw enable` | UFW(ファイアウォール)を有効化。実行した瞬間にデフォルト拒否ポリシーが効く |
| `sudo ufw status verbose` | 現在のファイアウォール設定を詳しく表示 |

`sudo ufw enable`の実行時に以下が出る。

```
Command may disrupt existing ssh connections. Proceed with operation (y|n)?
```

Tailscale経由(タブB)は`tailscale0`インターフェース経由なので切れない。`y`+ENTERで進む。

結果として`ufw status verbose`の出力は以下のようになる。

![ufw status verboseの出力。tailscale0からのみALLOW INの状態](/images/hermes-vps-02-ufw-status.png)

`Default: deny (incoming)`と`tailscale0`から`ALLOW IN`の2点が確認できればOK。

### なぜ二重防御か

二重に閉じる理由は、各レイヤーが守るものが違うからだ。

| レイヤー | 守るもの | 失敗するとどうなるか |
|---|---|---|
| XServerパケットフィルター | VPSに届く前の上位ネットワーク層 | XServer側の操作ミス・将来のプラン変更・契約更新時の設定リセット等で再開放される可能性 |
| UFW(VPS内部) | VPS到達後のOS層 | UFW誤操作で無効化される可能性 |

片方が偶発的に開いてももう片方が守る。

## 5. 最終確認とTailscaleキー無期限化

### 5-1. グローバル22は閉じ、Tailscale経由のみ通るかテスト

新しいPowerShellタブ(タブC)を開いて、2系統の接続を試す。

**① グローバルIP経由→失敗するはず**

```bash
ssh admin@<グローバルIP>
```

タイムアウトまたは`Connection refused`になる。

![グローバルIP経由のssh接続がConnection timed outで失敗する画面](/images/hermes-vps-02-global-22-rejected.png)

**② Tailscale IP経由→成功するはず**

```bash
ssh -i ~/.ssh/hermes_vps_ed25519 admin@<VPSのTailscale IP>
```

パスフレーズを入れてログイン成功する。

![2系統の接続テスト:グローバル22は拒否、Tailscale経由は成功](/images/hermes-vps-02-both-ssh-tests.png)

これでゴール達成だ。グローバル22は完全に閉じ、Tailscale経由のみで入れる状態になった。

### 5-2. Tailscaleキー無期限化(必須)

:::message alert
ここを忘れると180日後に**何の前触れもなくHermesが沈黙する**。Telegramに話しかけても無反応、SSHも入れず、原因に気づくまで数日かかる、ということが起きうる。**今この瞬間に**Disable key expiryを実行しておく。
:::

Tailscaleはデフォルトでマシンキーが**180日で期限切れ**になる。失効するとVPSがTailnetから消えて、再認証するまで誰も入れない。Hermesを24時間常駐させる以上、無期限化は必須。

ブラウザで`https://login.tailscale.com/admin/machines`を開き、`hermes-vps`をクリックして詳細画面を開く。右上の「Machine settings」をクリックすると、メニューが開く。

![Machine settingsメニューでDisable key expiryが赤枠ハイライト](/images/hermes-vps-02-machine-settings-menu.png)

「Disable key expiry」をクリック→確認ダイアログで「Disable」。

完了するとマシン詳細画面のStatus欄に`Expiry disabled`タグが表示される。

![Tailscale admin consoleで「Expiry disabled」が表示された状態](/images/hermes-vps-02-key-expiry-disabled.png)

これが第2回最大の落とし穴の対処。忘れやすいので、必ず今やっておく。

最後に1Passwordの`Hermes VPS - Tailscale auth`のメモに「Key expiry: Disabled(2026-05-27)」を追記しておく。

## つまずき集

### 1. Tailscaleの初回認証後、マーケティングアンケート画面でハマる

VPSで`sudo tailscale up --ssh`を実行してブラウザでログインすると、いきなり「Help us better understand your product needs and use-cases」というアンケート画面が出る。これは見た目もそれっぽくて、必須項目に見えてしまう。

実態はTailscaleのマーケティング用で、Tailscale本体の動作には一切影響しない。問題は、ウィザード完了を強制される設計になっている点。`https://login.tailscale.com/admin/machines`に直接アクセスしても、初回ユーザーは自動でアンケート画面にリダイレクトされる。

対処は1択で「適当に埋めて先へ進む」。`Personal or At-Home Use`+`Engineer`+`I don't use a VPN`+空欄で30秒。2回目以降のアクセスではURL直打ちでマシン一覧にそのまま入れる。

### 2. ssh-keygen -R で消した気でいた古い指紋がまた邪魔をする

過去にTailscaleで別のマシンを登録→退会・削除した経歴があると、今回引いたTailscale IP(`100.x.x.x`)が以前別マシンで使われていたことがあり、`Host key verification failed`が出る。第1回のつまずき集5番と同じ原因で、TailscaleのIPでもまったく同じことが起きる。

```bash
ssh-keygen -R <Tailscale IP>
```

で該当エントリを消してから再接続する。

### 3. Tailscaleキー失効(180日)の落とし穴

Tailscaleの公式仕様で、マシンキーは登録から180日でデフォルト失効する。常駐VPSのキーをDisable key expiryしておかないと、180日後にマシンが自動でTailnetから外され、再認証するまで誰も入れない。Hermesを24時間動かす運用では致命傷。

予防は本記事の5-2で。万一失効した場合の復旧は、VPSにシリアルコンソールから入って`sudo tailscale up --ssh`を再実行→認証URLを開いてログインし直すだけ。再認証後にadminコンソールでDisable key expiryも忘れずに。

### 4. UFW有効化前にtailscale0からのALLOW INを忘れて全切れ

順序を間違えて`sudo ufw enable`を先に実行すると、デフォルト拒否ポリシーが効いてTailscale経路も塞がる。本記事の4-2では先に`sudo ufw allow in on tailscale0`を打つよう書いているが、慌てて順序を逆にすると即ロックアウトする。

復旧はシリアルコンソールから入って`sudo ufw allow in on tailscale0`→`sudo ufw reload`。命綱はやはりコンソール。

### 5. XServerパケットフィルター削除直後にタブAが切れる(想定通り)

タブA(グローバルIP経由)が突然切れて焦るが、これはパケットフィルターで22番を閉じた直接の効果。想定通り。新規接続も既存接続も切れる。タブB(Tailscale経由)は`tailscale0`インターフェースを使うので影響なし。

「Aが切れた瞬間にBも切れていないか」を必ず確認してから次の作業(UFW設定)に進む。

## まとめ

第2回でやったこと:

- 1Passwordに`Tailscale Auth - hermes-vps`アイテムを作成(SSO情報の集約)
- VPSと手元PCの両方にTailscaleをインストールし、同じTailnetに参加
- Tailscale経由でadminログインが成立することを確認
- XServerパケットフィルターで22番ルールを削除(外部から閉鎖)
- VPS上のUFWで`tailscale0`からのみALLOW IN(二重防御)
- グローバル22経由は拒否、Tailscale経由のみ成功する状態を最終確認
- Tailscaleキー無期限化(`Disable key expiry`)で半年後のロックアウトを予防

次回は1Password運用の本番だ。Hermesに渡す秘密情報(Codex OAuthトークン、Telegram bot token、Service Account token等)を平文で持たず、`op run`で都度取り出す仕組みを作る。今回作った`Hermes-Prod`保管庫がいよいよ本格稼働する。
