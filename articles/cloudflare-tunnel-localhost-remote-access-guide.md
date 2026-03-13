---
title: "localhost アプリに外出先からアクセスする完全ガイド（Cloudflare Tunnel / Tailscale Funnel）"
emoji: "🌐"
type: "tech"
topics: ["cloudflare", "cloudflared", "tunnel", "windows", "tailscale"]
published: false
---

<a id="position"></a>

## この記事の位置づけ

自宅 PC で動かしているアプリ（Claude Code のダッシュボード、家計簿アプリ、作りかけのサービスなど）に、外出先のスマホや会社の PC から確認したい。でも VPS を借りたり、グローバル IP を晒したりはしたくない。

**Cloudflare Tunnel** や **Tailscale Funnel** を使えば、無料（または年 $5〜）でセキュアなリモートアクセスが手に入る。自宅 PC のポートを開放する必要もない。

この記事では、**2 つの方法を比較**した上で、Cloudflare Tunnel のフルセットアップ（アカウント作成〜ドメイン取得〜認証保護〜自動起動）と、Tailscale Funnel のセットアップを解説する。

:::message
**対象読者**: localhost で Web アプリを動かしている個人開発者（Windows 環境）
**前提知識**: コマンドライン操作の基本（PowerShell / ターミナル）
**検証環境**: Windows 11 + cloudflared 2026.3.0（2026 年 3 月時点）
:::

---

<a id="toc"></a>

## 目次

- [Cloudflare Tunnel とは何か](#what-is-tunnel)
- [全体像を先に把握する（構成図）](#overview)
- [費用まとめ](#cost)
- [Step 1: Cloudflare アカウント作成](#step1)
- [Step 2: ドメインを用意する](#step2)
- [Step 3: cloudflared をインストールする（Windows）](#step3)
- [Step 4: Tunnel を作成する（ダッシュボード方式）](#step4)
- [Step 5: Public Hostname を設定する](#step5)
- [Step 6: 接続を確認する](#step6)
- [Step 7: Cloudflare Access で認証を追加する](#step7)
- [Step 8: Windows サービス化（PC 起動時に自動接続）](#step8)
- [補足: Quick Tunnel（ドメイン不要・1 コマンドで試す）](#quick-tunnel)
- [補足: CLI 方式で Tunnel を管理する](#cli-method)
- [代替手段: Tailscale Funnel（ドメイン不要・完全無料）](#tailscale-funnel)
- [トラブルシューティング](#troubleshooting)
- [よくある質問（FAQ）](#faq)
- [公式リンク集](#links)

---

<a id="what-is-tunnel"></a>

## Cloudflare Tunnel とは何か

Cloudflare Tunnel（旧 Argo Tunnel）は、自宅やオフィスの PC で動いているサービスを、Cloudflare のエッジネットワーク経由でインターネットに安全に公開する仕組みだ。

**従来の方法との違い:**

| 方法 | ポート開放 | 固定IP | SSL | 認証 | ドメイン | コスト |
|------|:---:|:---:|:---:|:---:|:---:|:---:|
| ポートフォワーディング | 必要 | 必要 | 自前 | 自前 | 不要 | 無料 |
| ngrok | 不要 | 不要 | 自動 | 有料 | 不要 | 無料〜$20/月 |
| **Tailscale Funnel** | **不要** | **不要** | **自動** | **Tailscale** | **不要** | **無料** |
| **Cloudflare Tunnel** | **不要** | **不要** | **自動** | **Access（無料）** | **必要** | **年 $5〜** |

:::message
**ドメインにお金をかけたくないなら Tailscale Funnel が最有力候補。** ドメイン不要・完全無料で固定 URL（`*.ts.net`）が使える。詳しくは[記事末尾の比較セクション](#tailscale-funnel)を参照。
:::

Cloudflare Tunnel のポイントは 3 つ:

1. **ポート開放不要** — 自宅ルーターの設定を触らない。グローバル IP も晒さない
2. **SSL 自動** — Cloudflare が HTTPS 終端を行う。証明書の管理は不要
3. **認証が無料** — Cloudflare Access（Zero Trust）の無料プランで、メール認証をかけられる

> 公式ドキュメント: [Cloudflare Tunnel overview](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/)

---

<a id="overview"></a>

## 全体像を先に把握する（構成図）

```
外出先（スマホ / 別PC）
        │
        ▼
┌──────────────────────┐
│  Cloudflare Edge     │  ← SSL 終端 + Access 認証
│  (app.example.com)   │
└──────────┬───────────┘
           │ 暗号化トンネル（outbound のみ）
           ▼
┌──────────────────────┐
│  自宅 PC             │
│  cloudflared         │  ← デーモンが常駐
│      ↓               │
│  localhost:3000      │  ← あなたのアプリ
└──────────────────────┘
```

`cloudflared` は**自宅 PC 側からアウトバウンド接続**を張る。ルーターのインバウンドポートは一切開けない。

---

<a id="cost"></a>

## 費用まとめ

始める前に、かかる費用を整理しておく。

| 項目 | 費用 | 備考 |
|------|------|------|
| Cloudflare アカウント | **無料** | クレジットカード不要 |
| ドメイン | **年 $5〜** | `.uk` なら $4.94/年。`.com` は $10.44/年 |
| Cloudflare Tunnel | **無料** | Free プランで最大 1,000 Tunnel |
| Cloudflare Access | **無料** | 50 ユーザーまで |
| SSL 証明書 | **無料** | 自動発行・自動更新 |
| **合計** | **年 $5〜** | ドメイン代のみ |

ドメインを既に持っていればゼロ円で始められる。

:::message
**ドメイン代すら払いたくない場合は [Tailscale Funnel](#tailscale-funnel) を検討しよう。** 完全無料で固定 URL + HTTPS + 認証が手に入る。Cloudflare Tunnel は「カスタムドメインで運用したい」「Cloudflare Access のメール認証を使いたい」場合の選択肢だ。
:::

> 公式料金: [Zero Trust pricing](https://www.cloudflare.com/plans/zero-trust-services/) / [Cloudflare Registrar](https://www.cloudflare.com/products/registrar/)

---

<a id="step1"></a>

## Step 1: Cloudflare アカウント作成

1. [dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up) にアクセス
2. **メールアドレス**と**パスワード**を入力 →「Create Account」
3. 確認メールが届く →「**Verify Email**」をクリック

これだけ。無料プランではクレジットカードの入力は求められない。

:::message alert
**Zero Trust（Access 認証）を使う場合のみ**、後の Step 7 でクレジットカード登録が求められる。ただし Free プランでは課金は発生しない。
:::

> 公式手順: [Create a Cloudflare account](https://developers.cloudflare.com/fundamentals/account/create-account/)

---

<a id="step2"></a>

## Step 2: ドメインを用意する

Tunnel で固定 URL を使うにはカスタムドメインが必要になる。2 つの方法がある。

### 方法 A: Cloudflare Registrar で新規購入（推奨）

Cloudflare Registrar はドメインを**卸値（at-cost）**で販売している。マークアップなし。

**安い TLD を狙うのがコツ。** `.com` にこだわる必要はない:

| TLD | 登録/更新（年） | 備考 |
|-----|:-----------:|------|
| `.uk` | **$4.94** | 最安クラス。個人利用に最適 |
| `.link` | $7.18 | |
| `.work` | $7.18 | |
| `.com` | $10.44 | 定番だが高め |

> 全 TLD の価格一覧: [cfdomainpricing.com](https://cfdomainpricing.com/)

1. ダッシュボード左メニュー →「**Domain Registration**」→「**Register Domain**」
2. 希望ドメインを検索
3. カートに入れて購入

購入と同時に DNS が Cloudflare 管理になるので、ネームサーバーの変更作業が不要。これが一番ラクだ。

> 公式: [Cloudflare Registrar](https://www.cloudflare.com/products/registrar/)

### 方法 B: 他社で購入済みのドメインを Cloudflare に追加

お名前.com、Namecheap などで取得済みのドメインを使う場合:

1. ダッシュボード →「**Add a site**」→ ドメイン名を入力
2. **Free プラン**を選択
3. Cloudflare が**ネームサーバー 2 つ**を表示する（例: `xxx.ns.cloudflare.com`）
4. レジストラの管理画面でネームサーバーを上記に変更
5. 反映まで数時間〜最大 48 時間

:::message alert
**注意**: ネームサーバー変更前に、レジストラ側で **DNSSEC を無効化**すること。有効のまま変更すると名前解決に失敗する。
:::

> 公式手順: [Add a site to Cloudflare](https://developers.cloudflare.com/fundamentals/manage-domains/add-site/) / [Change your nameservers](https://developers.cloudflare.com/dns/zone-setups/full-setup/setup/)

---

<a id="step3"></a>

## Step 3: cloudflared をインストールする（Windows）

`cloudflared` は Cloudflare Tunnel のクライアントソフト。PC にインストールして常駐させる。

```powershell
winget install --id Cloudflare.cloudflared
```

:::message
`winget` が使えない場合は、[cloudflared GitHub Releases](https://github.com/cloudflare/cloudflared/releases) から `cloudflared-windows-amd64.msi` をダウンロードして実行する。
:::

### インストール確認

```powershell
cloudflared --version
# cloudflared version 2026.3.0 (built ...)
```

バージョンが表示されれば OK。

:::message
**Windows では cloudflared は自動更新されない。** 手動で更新が必要な場合は以下を実行する。

```powershell
winget upgrade --id Cloudflare.cloudflared
```
:::

> 公式リポジトリ: [cloudflare/cloudflared (GitHub)](https://github.com/cloudflare/cloudflared)

---

<a id="step4"></a>

## Step 4: Tunnel を作成する（ダッシュボード方式）

Tunnel の管理方法は 2 つある:

| 方式 | 設定の保存先 | 管理画面 | 推奨度 |
|------|------------|---------|:---:|
| **ダッシュボード管理**（Remotely-Managed） | Cloudflare サーバー | Web ダッシュボード | **推奨** |
| CLI 管理（Locally-Managed） | ローカル config.yml | コマンドライン | 上級者向け |

公式推奨はダッシュボード管理。設定が Cloudflare 側に保存されるため、PC を変えても設定を引き継げる。

**手順:**

1. Cloudflare ダッシュボードにログイン（以下どちらでも操作できる）
   - **Zero Trust ダッシュボード**: [one.dash.cloudflare.com](https://one.dash.cloudflare.com/) →「**Networks**」→「**Tunnels**」
   - **メインダッシュボード**: [dash.cloudflare.com](https://dash.cloudflare.com/) →「**Networking**」→「**Tunnels**」（2026年2月から利用可能）
3. 「**Create a tunnel**」をクリック
4. Connector type:「**Cloudflared**」を選択 →「Next」
5. Tunnel 名を入力（例: `my-app`）→「Save tunnel」
6. OS として「**Windows**」を選択
7. 表示されるインストールコマンドをコピーして **管理者権限の PowerShell** で実行:

```powershell
# 表示されるコマンドの例（トークンは自分のものに置き換わる）
cloudflared.exe service install eyJhIjoixxxx...
```

このコマンドで `cloudflared` が **Windows サービスとして登録**され、Cloudflare に接続される。

8. ダッシュボードに戻り、コネクタの Status が「**Connected**」になっていれば成功

:::message
ダッシュボード方式では、**Step 4 のコマンド実行で Step 8（サービス化）も同時に完了する**。CLI 方式より圧倒的に簡単だ。
:::

> 公式手順: [Create a remotely-managed tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/)

---

<a id="step5"></a>

## Step 5: Public Hostname を設定する

Tunnel が接続されたら、どのドメインでどのローカルサービスにアクセスするかを設定する。

1. 作成した Tunnel をクリック →「**Public Hostname**」タブ
2. 「**Add a public hostname**」をクリック
3. 以下を入力:

| 項目 | 入力例 | 説明 |
|------|--------|------|
| Subdomain | `app` | サブドメイン部分 |
| Domain | `example.com` | ドロップダウンから選択 |
| Type | `HTTP` | ローカルが HTTP なら HTTP |
| URL | `localhost:3000` | アプリのローカルアドレス |

4. 「**Save hostname**」

これで `https://app.example.com` へのアクセスが `localhost:3000` に転送される。SSL は Cloudflare が自動で処理する。

### 複数サービスの公開

同じ Tunnel で複数のホスト名を設定できる:

```
app.example.com  → localhost:3000  （メインアプリ）
api.example.com  → localhost:8080  （API サーバー）
db.example.com   → localhost:8081  （DB 管理画面）
```

Public Hostname を追加するだけで、Tunnel は 1 つで済む。

---

<a id="step6"></a>

## Step 6: 接続を確認する

### ブラウザで確認

`https://app.example.com`（自分が設定したドメイン）にアクセスし、ローカルアプリの画面が表示されれば成功。

### cloudflared のステータス確認

```powershell
# サービスの状態確認
sc query cloudflared

# または PowerShell
Get-Service cloudflared
```

`RUNNING` と表示されていれば正常稼働中。

### ダッシュボードで確認

Cloudflare One → Networks → Tunnels で、作成した Tunnel のステータスが「**Healthy**」になっていることを確認。

:::message alert
**502 Bad Gateway が出る場合**: ローカルアプリが起動していない、またはポート番号が間違っている。`localhost:3000` にブラウザで直接アクセスして動作確認すること。
:::

---

<a id="step7"></a>

## Step 7: Cloudflare Access で認証を追加する

ここまでの設定だと、URL を知っている人なら誰でもアクセスできてしまう。**Cloudflare Access** でメール認証を追加して保護する。

### 7-1: Zero Trust の初期セットアップ

1. [Cloudflare One ダッシュボード](https://one.dash.cloudflare.com/) にログイン
2. 初回アクセス時に「**Team name**」の入力を求められる
   - 例: `myteam` → `myteam.cloudflareaccess.com` が管理 URL になる
3. プランは「**Free**」を選択
4. **クレジットカード情報**の入力を求められる

:::message alert
**Free プランでもクレジットカード登録が必要**。ただし 50 ユーザーまでは課金されない。51 人目を追加すると有料プラン（$7/席/月 × 全席数）にアップグレードが必要になるので注意。個人利用なら心配不要。
:::

> 公式: [Get started with Cloudflare Zero Trust](https://developers.cloudflare.com/cloudflare-one/setup/)

### 7-2: メール認証（One-time PIN）を有効化する

1. 左メニュー「**Settings**」→「**Authentication**」
2. Login methods に「**One-time PIN**」が表示されていることを確認
   - 表示されていなければ「Add new」→「One-time PIN」を追加

One-time PIN はメールアドレスに 6 桁のコードを送信する方式。追加設定は不要。

> 公式: [One-time PIN login](https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/one-time-pin/)

### 7-3: Access Application（アクセスポリシー）を作成する

1. 左メニュー「**Access**」→「**Applications**」→「**Add an application**」
2. 「**Self-hosted**」を選択
3. 基本情報を入力:

| 項目 | 入力例 |
|------|--------|
| Application name | `My App` |
| Session Duration | `24 hours` |
| Application domain | `app.example.com` |

4. 「**Next**」→ Policy を作成:

| 項目 | 設定 |
|------|------|
| Policy name | `Allow me` |
| Action | **Allow** |
| Selector | **Emails** |
| Value | `your-email@example.com` |

5. 「**Next**」→「**Add application**」

:::message alert
**絶対にやってはいけない設定**: Selector を「Login Methods」= 「One-time PIN」だけにすること。これだと**任意のメールアドレスで誰でもログインできてしまう**。必ず **Emails** または **Emails Ending In** で対象者を限定すること。
:::

### 7-4: 認証フローの確認

設定完了後、`https://app.example.com` にアクセスすると:

1. Cloudflare Access のログイン画面が表示される
2. 許可したメールアドレスを入力
3. メールに 6 桁の PIN コードが届く（送信元: `noreply@notify.cloudflare.com`）
4. PIN を入力 → アプリにリダイレクト

セッション期間中（デフォルト 24 時間）は再認証不要。

:::message
PIN メールが届かない場合、メールフィルタ・迷惑メールフォルダを確認。`noreply@notify.cloudflare.com` をホワイトリストに追加すること。
:::

> 公式: [Add a self-hosted application](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/self-hosted-public-app/) / [Access policies](https://developers.cloudflare.com/cloudflare-one/policies/access/)

---

<a id="step8"></a>

## Step 8: Windows サービス化（PC 起動時に自動接続）

### ダッシュボード方式の場合（Step 4 で完了済み）

Step 4 で `cloudflared.exe service install <TOKEN>` を実行した時点で、Windows サービスとして登録済み。PC 再起動後も自動で Tunnel が接続される。

### 遅延起動を設定する（推奨）

ネットワーク接続が確立する前に `cloudflared` が起動するとエラーになることがある。遅延起動にしておくと安心:

```powershell
# 管理者権限の PowerShell で実行
Set-Service -Name "Cloudflared" -StartupType "AutomaticDelayedStart"
```

### 動作確認

```powershell
# PC を再起動して、サービスの状態を確認
Get-Service cloudflared

# Status が Running なら OK
```

再起動後に `https://app.example.com` にアクセスできれば完了。

> 公式: [Run cloudflared as a Windows service](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/as-a-service/windows/)

---

<a id="quick-tunnel"></a>

## 補足: Quick Tunnel（ドメイン不要・1 コマンドで試す）

ドメインもアカウントもなしで、とりあえず試したいなら Quick Tunnel が使える。

```powershell
cloudflared tunnel --url http://localhost:3000
```

実行すると `https://xxxx-yyyy-zzzz.trycloudflare.com` のようなランダム URL が表示される。この URL に外部からアクセスすればローカルアプリが見える。

### Quick Tunnel の制限

| 項目 | 制限 |
|------|------|
| URL | 起動のたびにランダム URL が変わる |
| 同時リクエスト | **最大 200 件**（超過で 429 エラー） |
| SSE（Server-Sent Events） | **非対応** |
| SLA / 稼働率保証 | なし |
| 認証（Access） | 使えない |

:::message alert
Quick Tunnel は**開発・テスト専用**。本格利用には Named Tunnel + カスタムドメインを使うこと。
:::

> 公式: [TryCloudflare (Quick Tunnels)](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/)

---

<a id="cli-method"></a>

## 補足: CLI 方式で Tunnel を管理する

ダッシュボードではなくローカルの設定ファイルで管理したい上級者向けの方法。

### 1. 認証

```bash
cloudflared tunnel login
```

ブラウザが開き、Cloudflare アカウントで認証する。成功すると `~/.cloudflared/cert.pem` が保存される。

### 2. Tunnel 作成

```bash
cloudflared tunnel create my-tunnel
# Created tunnel my-tunnel with id xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### 3. 設定ファイル作成

`~/.cloudflared/config.yml`:

```yaml
tunnel: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
credentials-file: C:\Users\<username>\.cloudflared\xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.json

ingress:
  - hostname: app.example.com
    service: http://localhost:3000
  - service: http_status:404
```

:::message alert
**ingress の最後のルールは必須**。`service: http_status:404` はキャッチオール（どのホスト名にも一致しないリクエスト用）。これがないとエラーになる。
:::

### 4. DNS ルーティング

```bash
cloudflared tunnel route dns my-tunnel app.example.com
```

### 5. 起動

```bash
cloudflared tunnel run my-tunnel
```

### CLI 方式でのサービス化

```powershell
# 管理者権限で実行
cloudflared.exe service install
```

サービスが config.yml を読むには、設定ファイルを以下のパスに配置する必要がある:

```
C:\Windows\System32\config\systemprofile\.cloudflared\config.yml
C:\Windows\System32\config\systemprofile\.cloudflared\<TUNNEL_ID>.json
C:\Windows\System32\config\systemprofile\.cloudflared\cert.pem
```

ユーザープロファイルの `~/.cloudflared/` からコピーすること。

> 公式: [Create a locally-managed tunnel](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/create-local-tunnel/) / [Configuration file](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/configuration-file/)

---

<a id="tailscale-funnel"></a>

## 代替手段: Tailscale Funnel（ドメイン不要・完全無料）

「ドメインにお金を払いたくない」「管理先を増やしたくない」という人には **Tailscale Funnel** が最適解になり得る。

### Tailscale Funnel とは

Tailscale は WireGuard ベースの VPN メッシュネットワーク。その機能の一つ **Funnel** を使うと、ローカルサービスをインターネットに公開できる。Cloudflare Tunnel と同じことが**ドメイン購入なし**でできる。

### Cloudflare Tunnel との比較

| 項目 | Cloudflare Tunnel | Tailscale Funnel |
|------|:---:|:---:|
| 費用 | 年 $5〜（ドメイン代） | **完全無料** |
| ドメイン | **必要** | **不要**（`*.ts.net` 自動付与） |
| 固定 URL | `app.yourdomain.com` | `your-pc.tailnet-xxxx.ts.net` |
| HTTPS | 自動 | 自動 |
| 認証 | Cloudflare Access（メール PIN） | Tailscale アカウント |
| SSE（ストリーミング） | 対応 | 対応 |
| ポート制限 | なし | 443, 8443, 10000 のみ |
| サービス化（自動起動） | Windows サービス | Windows サービス |
| カスタムドメイン | 対応 | 非対応 |

### セットアップ手順（Windows）

**1. インストール**

```powershell
winget install --id Tailscale.Tailscale
```

**2. ログイン**

Tailscale のアプリが起動するので、Google / Microsoft / GitHub アカウントでログイン。

**3. HTTPS Certificates を有効化（前提条件）**

Funnel は HTTPS を使用するため、まず証明書の有効化が必要。管理コンソール（[login.tailscale.com/admin/dns](https://login.tailscale.com/admin/dns)）の「**Settings**」→「**DNS**」→「**HTTPS Certificates**」をオンにする。

**4. Funnel を有効化**

Tailscale の管理コンソール（[login.tailscale.com/admin/acls](https://login.tailscale.com/admin/acls)）で ACL に Funnel 許可を追加:

```json
{
  "nodeAttrs": [
    {
      "target": ["autogroup:member"],
      "attr":   ["funnel"]
    }
  ]
}
```

**5. ローカルアプリを公開**

```powershell
# localhost:3000 を公開
tailscale funnel 3000
```

ターミナルに表示される `https://your-pc.tailnet-xxxx.ts.net` が公開 URL。外出先のスマホからアクセスできる。

**6. バックグラウンド実行（常時公開）**

```powershell
tailscale funnel --bg 3000
```

`--bg` を付けると、ターミナルを閉じても Funnel が動き続ける。PC 再起動後も Tailscale サービスが自動起動するため、アプリさえ起動していればアクセス可能。

### Tailscale Funnel の制限

- **URL がカスタムドメインにならない**（`*.ts.net` 固定）
- **ポートが 443 / 8443 / 10000 の 3 つに限定**（ローカル側は任意ポートを指定可能）
- **Tailscale アカウントが必要**（Google / Microsoft / GitHub 認証）

### どちらを選ぶべきか

| あなたの状況 | 推奨 |
|------------|------|
| とにかく無料で、管理の手間を最小にしたい | **Tailscale Funnel** |
| カスタムドメイン（`app.mydomain.com`）で運用したい | Cloudflare Tunnel |
| 複数サービスをサブドメインで分けたい | Cloudflare Tunnel |
| メールアドレスで第三者にアクセス権を渡したい | Cloudflare Tunnel（Access） |

> 公式ドキュメント: [Tailscale Funnel](https://tailscale.com/docs/features/tailscale-funnel) / [Tailscale 料金](https://tailscale.com/pricing)

---

<a id="troubleshooting"></a>

## トラブルシューティング

### 502 Bad Gateway

**原因**: ローカルアプリが起動していない、またはポート/プロトコルが間違っている。

**対処**:
1. ブラウザで `http://localhost:3000` に直接アクセスし、アプリが動いているか確認
2. Public Hostname の Type（HTTP / HTTPS）がアプリのプロトコルと一致しているか確認
3. ローカルアプリが `127.0.0.1` ではなく `0.0.0.0` でリッスンしている場合、URL を `0.0.0.0:3000` に変更

### Tunnel が Disconnected / Down になる

**対処**:
1. `cloudflared` サービスを再起動: `Restart-Service cloudflared`
2. PC のネットワーク接続を確認
3. Cloudflare のステータスページ ([cloudflarestatus.com](https://www.cloudflarestatus.com/)) を確認

### DNS_PROBE_FINISHED_NXDOMAIN

**原因**: DNS レコードがまだ反映されていない。

**対処**:
- ドメインを追加したばかりなら、最大 48 時間待つ
- ダッシュボード方式なら DNS レコードは自動作成されるはずだが、DNS タブで CNAME レコードの存在を確認

### サービスが起動しない（CLI 方式）

**対処**:
1. イベントビューア（`eventvwr.msc`）→ Windows ログ → Application で `cloudflared` のエラーを確認
2. `C:\Windows\System32\config\systemprofile\.cloudflared\` に config.yml と credentials ファイルがあるか確認
3. レジストリ `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Cloudflared` の `ImagePath` にスペースが混入していないか確認

### Access の PIN メールが届かない

**対処**:
1. 迷惑メールフォルダを確認
2. `noreply@notify.cloudflare.com` をホワイトリストに追加
3. Access Policy の Selector が正しいメールアドレスか確認

> 公式: [Tunnel common errors](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/troubleshoot-tunnels/common-errors/)

---

<a id="faq"></a>

## よくある質問（FAQ）

### Q: PC がスリープ / シャットダウンしたら？

Tunnel は切断される。外出先からはアクセスできなくなる。対策:

- **スリープ防止**: Windows の電源設定で「スリープしない」にする
- **Wake-on-LAN**: 外出先から PC を起動する（ルーター + BIOS 設定が必要）
- **タスクスケジューラ**: 定時に PC を起動する

### Q: 無料プランの上限は？

| リソース | 上限 |
|----------|------|
| Tunnel 数 | 1,000 |
| Access Application 数 | 500 |
| Access ユーザー数 | **50** |
| DEX テスト | 10 |

個人利用で困ることはまずない。

> 公式: [Account limits](https://developers.cloudflare.com/cloudflare-one/account-limits/)

### Q: HTTPS のローカルアプリの場合は？

Public Hostname の Type を `HTTPS` に変更し、TLS 設定で「**No TLS Verify**」を有効にする（自己署名証明書の場合）。

### Q: Tunnel を複数台の PC で使える？

同じ Tunnel に複数のコネクタ（`cloudflared`）を接続できる。ロードバランシングに使える。

### Q: 帯域制限はある？

Cloudflare Tunnel 自体に帯域制限は公表されていない。ただし、大量のトラフィックを流す場合は Cloudflare の AUP（Acceptable Use Policy）に注意。

---

<a id="links"></a>

## 公式リンク集

### アカウント・ドメイン

| トピック | URL |
|----------|-----|
| アカウント作成 | [developers.cloudflare.com/fundamentals/account/create-account/](https://developers.cloudflare.com/fundamentals/account/create-account/) |
| ドメイン追加 | [developers.cloudflare.com/fundamentals/manage-domains/add-site/](https://developers.cloudflare.com/fundamentals/manage-domains/add-site/) |
| ネームサーバー変更 | [developers.cloudflare.com/dns/zone-setups/full-setup/setup/](https://developers.cloudflare.com/dns/zone-setups/full-setup/setup/) |
| Cloudflare Registrar | [cloudflare.com/products/registrar/](https://www.cloudflare.com/products/registrar/) |

### Tunnel

| トピック | URL |
|----------|-----|
| Tunnel 概要 | [developers.cloudflare.com/.../cloudflare-tunnel/](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/) |
| ダッシュボードで Tunnel 作成 | [developers.cloudflare.com/.../create-remote-tunnel/](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/get-started/create-remote-tunnel/) |
| CLI で Tunnel 作成 | [developers.cloudflare.com/.../create-local-tunnel/](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/create-local-tunnel/) |
| Quick Tunnel | [developers.cloudflare.com/.../trycloudflare/](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/) |
| config.yml リファレンス | [developers.cloudflare.com/.../configuration-file/](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/configuration-file/) |
| Windows サービス | [developers.cloudflare.com/.../as-a-service/windows/](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/local-management/as-a-service/windows/) |
| トラブルシューティング | [developers.cloudflare.com/.../common-errors/](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/troubleshoot-tunnels/common-errors/) |
| Tunnel Changelog | [developers.cloudflare.com/.../changelog/tunnel/](https://developers.cloudflare.com/cloudflare-one/changelog/tunnel/) |

### Zero Trust / Access

| トピック | URL |
|----------|-----|
| Zero Trust セットアップ | [developers.cloudflare.com/cloudflare-one/setup/](https://developers.cloudflare.com/cloudflare-one/setup/) |
| One-time PIN 認証 | [developers.cloudflare.com/.../one-time-pin/](https://developers.cloudflare.com/cloudflare-one/integrations/identity-providers/one-time-pin/) |
| Self-hosted App | [developers.cloudflare.com/.../self-hosted-public-app/](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/self-hosted-public-app/) |
| Access Policy | [developers.cloudflare.com/.../access/](https://developers.cloudflare.com/cloudflare-one/policies/access/) |
| 料金・制限 | [cloudflare.com/plans/zero-trust-services/](https://www.cloudflare.com/plans/zero-trust-services/) |
| アカウント制限 | [developers.cloudflare.com/cloudflare-one/account-limits/](https://developers.cloudflare.com/cloudflare-one/account-limits/) |

### Tailscale

| トピック | URL |
|----------|-----|
| Tailscale Funnel | [tailscale.com/docs/features/tailscale-funnel](https://tailscale.com/docs/features/tailscale-funnel) |
| Tailscale 料金 | [tailscale.com/pricing](https://tailscale.com/pricing) |
| Tailscale ダウンロード | [tailscale.com/download](https://tailscale.com/download) |

### ツール

| トピック | URL |
|----------|-----|
| cloudflared GitHub | [github.com/cloudflare/cloudflared](https://github.com/cloudflare/cloudflared) |
| Cloudflare ステータス | [cloudflarestatus.com](https://www.cloudflarestatus.com/) |
| Cloudflare ドメイン価格一覧 | [cfdomainpricing.com](https://cfdomainpricing.com/) |

---

*最終確認: 2026 年 3 月*
