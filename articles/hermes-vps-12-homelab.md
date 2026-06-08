---
title: "【第12回】家の余ったPCをLinuxの常駐GPUサーバーにする──VPSの手足を伸ばす"
emoji: "🖥️"
type: "tech"
topics: ["ai", "hermes", "vps", "ubuntu", "linux"]
published: false
---

第11回までで、VPSの上に「考えて、覚えて、自分から動く」エージェントができた。けれど、VPSのCPUには限界がある。画像生成や、手元で動かすLLMの推論、大量のバッチ処理——こういう「重い計算」をVPSに投げると、遅いし、ときどき落ちる。

家に、使っていないGPU搭載のPCはないだろうか。あるいは、Windowsのサポートが切れて持て余しているノートPCでもいい。第12回は、その1台をLinux(Ubuntu)に入れ替えて24時間つながる計算機にし、VPSのHermes Agentから重い処理だけを任せる。VPSが司令塔、自宅のGPU機が力仕事担当、という分担だ。

まずは「常時起動で確実に動かす」ことを優先する。電気代を抑える省電力運用(必要なときだけ起こすWake-on-LAN)は、最後に「任意・将来」として触れる。

:::message
この記事はHermes AgentをVPSに常駐させるシリーズの第12回。第1回のVPS契約から始まり、ここで自宅GPU機との分業まで到達する。連載はこの先も続く。
:::

## 目次

- [この回の到達点](#この回の到達点)
- [VPSが脳で自宅機が手足](#vpsが脳で自宅機が手足)
- [完成すると何ができるようになるか](#完成すると何ができるようになるか)
- [この回で出てくる言葉](#この回で出てくる言葉)
- [どのPCをLinuxにするか](#どのpcをlinuxにするか)
- [換装の準備](#換装の準備)
- [Windowsを消してUbuntuを入れる](#windowsを消してubuntuを入れる)
- [初期設定とSSH](#初期設定とssh)
- [Tailscaleでtailnetに参加する](#tailscaleでtailnetに参加する)
- [NVIDIAのGPUドライバを入れる](#nvidiaのgpuドライバを入れる)
- [眠らせず画面を消して常時起動にする](#眠らせず画面を消して常時起動にする)
- [VPSから重い処理を任せる](#vpsから重い処理を任せる)
- [省電力は後から足す](#省電力は後から足す)
- [よくあるエラーと対処](#よくあるエラーと対処)
- [まとめと次回へ](#まとめと次回へ)
- [公式ドキュメント引用元](#公式ドキュメント引用元)

## この回の到達点

第11回完了時と第12回完了後の差分を表にする。

| 項目 | 第11回完了時 | 第12回完了後 |
|---|---|---|
| 常駐拠点 | VPSのCPU(2 vCPU/6GB) | 変わらず(司令塔) |
| 重い計算(画像生成・LLM推論) | VPSで実行=遅い・落ちる | 自宅のLinux GPU機にオフロード |
| 自宅機のOS | Windows(または未活用) | Ubuntuに換装した常駐サーバー |
| 自宅機の電源 | 手動オン/オフ | 常時起動・画面オフ(ヘッドレス) |
| VPS↔自宅の通信 | 該当機能なし | Tailscale経由(自宅のIPを世界に晒さない) |
| 遠隔から自宅機を見る | 該当機能なし | SSH+zellij(リモートターミナル) |

一言でまとめると「家の余ったPCをLinuxに入れ替えて、VPSのエージェントから重い計算を投げられる手足にする」回だ。

## VPSが脳で自宅機が手足

VPSは安く24時間動かせるが、画像生成・動画生成・ローカルLLM推論には能力が足りない。逆に、家のGPU機は強力だが、Windowsのまま日常使いだと「いつでもVPSから叩ける計算機」にはなりにくい。

そこで役割を分ける。VPSは常に起きている受付兼司令塔。自宅のLinux機は、呼ばれたときに重い計算をこなす力仕事担当。両者はTailscale(第2回で組んだ安全なトンネル)でつながり、VPSのHermes AgentがSSHやAPIで自宅機に仕事を投げ、結果を受け取ってTelegramへ返す。

```
VPS(常駐Hermes Agent)            自宅GPU機(Ubuntu・常時起動)
  ・司令塔                         ・Tailscaleで参加(常時オン)
  ・Tailscaleで参加      ◀─tailnet─▶ ・SSHサーバー(鍵認証)
  ・SSH/zellijクライアント          ・GPU(NVIDIA)+ドライバ
                                    ・画像生成/LLM推論サービス
  Telegram「画像生成して」          ・画面オフ・スリープ無効
      │
      ▼
  1. Tailscale越しにSSH/API接続 ─▶ すぐ応答(常時起動)
  2. GPU推論を依頼              ─▶ GPU推論(数秒〜数分)
  3. 結果を受け取りTelegramへ   ◀─ 結果返却
```

## 完成すると何ができるようになるか

この構成ができると、VPSのHermes Agentは「自宅GPU機を使える常駐オペレーター」になる。手順に入る前に、何ができるようになるのかを先に見ておく。

たとえばTelegramから、次のように頼める。

```
GPU機の状態を見て。温度、VRAM、動いているプロセスを教えて。
```

```
自宅GPU機で画像を1枚生成して、完成したらTelegramに送って。
```

```
この文章をローカルLLMで要約して。外部APIには出さないで。
```

```
夜中に重いバッチ処理を回して、朝までに結果をまとめて。
```

```
この記事に載せるコマンドを自宅GPU機で検証して、ログをZenn向けに整えて。
```

VPSは常駐・受付・記憶・通知を担当し、自宅GPU機は推論・画像生成・バッチ処理を担当する。GPU付きの高いVPSを借りなくても、安いVPSと家にあるPCを組み合わせれば、自分専用のAI実験基盤になる。

とくに大きいのがプライバシーだ。外部APIは便利だが、すべての文章やファイルを外に出したいわけではない。自宅GPU機でローカルLLMを動かせば、Hermes Agentから依頼しつつ、実際の推論は自宅の閉じた環境で実行できる。Tailscale越しなので、推論APIをインターネットに公開する必要もない。

さらに、一度成功した手順はHermesのSkillとして保存できる。「GPU状態確認」「画像生成」「ローカルLLMベンチマーク」のような手順をSkill化しておけば、次回からは自然文で呼び出せる。

ここまで来ると、Hermes AgentはただのチャットAIではない。VPSを脳、自宅GPU機を手足にした、自分専用の常駐AIオペレーターになる。

## この回で出てくる言葉

先に、この回で何度も出てくる言葉を説明しておく。

- **換装**(かんそう):PCのOSを入れ替えること。ここではWindowsを消してUbuntu(Linux)を入れ直す
- **Ubuntu**:もっとも普及しているLinuxの一種。サーバー用途で定番の、無料のOS
- **ヘッドレス運用**:モニタもキーボードも繋がず、別のPCからネットワーク越しに操作する使い方
- **常駐サーバー**:電源を入れっぱなしにして、いつでも応答する状態のPC
- **NVIDIAドライバ**:GPUを動かすためのソフト。これが無いとGPUを計算に使えない
- **zellij**:複数のターミナル画面を1つにまとめ、接続を切っても後から見直せる道具。遠隔の作業机を分割して覗く窓のようなもの

## どのPCをLinuxにするか

この回の主役は「家にあるGPU搭載のデスクトップ」を想定している。日常作業は別のノートPCで済むので、デスクトップ機はまるごと「AI推論専用機」と割り切り、Windowsを消してLinux専用にする。

GPUを使った画像生成やローカルLLM推論を本格的にやるなら、RTX 30シリーズ以上のGPUが目安になる。一方、「VPSのエージェントから叩ける計算機・SSHサーバー・軽い処理の実行先」としてなら、GPUの無い古いノートPCやIntel世代のMacでも十分に通用する。Linuxは軽いので、Windowsが重くて使えなくなった機材でも快適に動き、第二の生涯を与えられる。

:::message
**デュアルブートにしない理由**:1台で日常作業もAI推論も兼ねたいなら、この構成は重すぎる(その場合はWindowsを残してWSL2+CUDAで動かす案が向く)。本シリーズは「日常作業は別PC、GPU機はLinux専用の常駐サーバー」と割り切る。LLM推論サーバーやドライバはLinuxが第一級サポートで、Windows Updateが運用中に勝手に再起動する事故も避けられる。
:::

## 換装の準備

:::message alert
この回はWindowsを**消去**してUbuntuを入れる。GPU機の中に残したいファイル(写真・書類・ライセンス情報・ブラウザのブックマークなど)があれば、必ず先に外付けSSDやクラウドへ退避すること。退避が済むまで次に進まない。
:::

母艦(普段使いのノートPC)側で、次を準備する。

- GPU機の重要データを外付け/クラウドへ退避する
- GPU機の機種・GPU型番をメモする(ドライバ選定で使う)
- 16GB以上のUSBメモリを用意する(中身は消える)

セットアップ中はGPU機にモニタとキーボードをつなぐ。モニタはHDMI(またはDisplayPort)でよいが、グラフィックボードを挿しているデスクトップは**GPU側の端子**につなぐ(マザーボード側の映像出力は無効なことが多い)。キーボード・マウスはUSB接続(有線、またはUSBレシーバー型の無線)にする。Bluetoothのみのものはインストーラ中に使えないことがある。インストールと初期設定が済んだら外し、ヘッドレス運用にする。

次に、長期サポート版(LTS)のUbuntu DesktopのISOを[公式サイト](https://ubuntu.com/download)から落とす。画面付きで導入しやすいDesktop版でよい。導入後にヘッドレス運用へ寄せる。

落としたISOは、母艦のWindows機でRufus(またはbalenaEtcher)を使ってUSBに書き込み、起動できるインストーラにする。

## Windowsを消してUbuntuを入れる

作ったUSBをGPU機に挿し、USBから起動してUbuntuをインストールする。ここからはGPU機側の物理操作だ。

1. GPU機を再起動し、起動メニュー(F12・F2・Delなど。機種で異なる)からUSBを選ぶ
2. Ubuntuインストーラが起動したら、インストール種別で「ディスクを削除してUbuntuをインストール(Erase disk and install Ubuntu)」を選ぶ。これでWindowsは消える
3. ユーザー名とパスワードを設定する
4. インストールが終わったらUSBを抜いて再起動し、Ubuntuのデスクトップが起動すれば成功

## 初期設定とSSH

最初にシステムを更新し、別のPCから入るためのSSHサーバーを入れる。

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
ip a            # 自宅LAN内のIPを確認(次のSSH接続で使う)
```

次に、第1〜2回と同じ作法で鍵認証にし、パスワードログインを止める。第1〜2回で作ったSSH鍵はそのまま使ってよい。`<user>` は自分のユーザー名、`<gpu-lan-ip>` は先ほど `ip a` で確認したIPに置き換える。

```bash
# まだSSH鍵がない場合だけ、母艦(ノートPC)側で作る
ssh-keygen -t ed25519 -C "gpu-server"
# 母艦の公開鍵をGPU機へ送る
ssh-copy-id <user>@<gpu-lan-ip>
```

パスワードログインを止める前に、別のターミナルから鍵だけでSSHログインできることを必ず確認する。設定ファイルは書き換える前にバックアップを取っておくと安心だ。

```bash
# GPU機側で、設定をバックアップしてからパスワードログインを無効化する
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

母艦から鍵だけでSSHログインでき、パスワードでは入れなくなっていれば完了だ。

## Tailscaleでtailnetに参加する

第2回で組んだtailnet(自分の端末とサーバーだけが見える安全な網)に、自宅GPU機を参加させる。これでVPSから自宅機を `*.ts.net` のtailnet名で呼べる。自宅LANのIPを世界に晒したり、ルーターのポートを開けたりする必要はない。

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
tailscale status
```

表示された認証URLをブラウザで開き、第2回と同じtailnetに参加する。参加後、Tailscaleの管理コンソールでこのマシンの **Key expiry**をDisableにしておく(第2回と同じ理由で、再認証で止まらないようにするため)。

VPS側で `tailscale status` に自宅機が見え、VPSから自宅機へtailnet名でSSHできれば、神経がつながった。

## NVIDIAのGPUドライバを入れる

GPUを計算に使うにはドライバが要る。Ubuntuは推奨ドライバを自動で選んでくれる。

```bash
ubuntu-drivers devices              # 推奨ドライバを表示
sudo ubuntu-drivers autoinstall     # 推奨を自動導入
sudo reboot
```

再起動後に次を実行し、GPU名・ドライバ・VRAMが表示されれば成功だ。

```bash
nvidia-smi
```

GPUを持たない古いノートPCやMacを使う場合は、この章はスキップしてよい。「SSHサーバー・軽い処理の実行先」としては、それでも十分に機能する。

## 眠らせず画面を消して常時起動にする

常時つながる手足にするには、(1)システムが眠らない、(2)画面は付けっぱなしにしない、(3)電源が戻ったら自動で起動する、の3つをそろえる。

まず、スリープ・サスペンド・休止をまとめて無効化する。

```bash
sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

モニタは物理的に外すか、電源を切ってよい(システムは動き続ける)。GPUは画面ではなく計算に使う。より割り切るなら、起動時にGUIを上げないCUI常駐にして軽くできる(任意)。

```bash
# (任意)GUIを上げずCUI常駐にして軽くする
sudo systemctl set-default multi-user.target
```

最後に、停電やブレーカー断のあとに自動で復帰するよう、BIOS/UEFIの「AC電源復帰時の動作(AC Power Recovery / Restore on AC Power Loss)」をPower On(常にオン)にする。SSHとTailscaleが起動時に自動で立ち上がるかも確認する。

```bash
systemctl is-enabled ssh tailscaled    # 両方 enabled が理想
```

:::message
**無線LANで運用する場合**:有線LANが安定だが、無線でも運用できる。セットアップ時はモニタを繋いでいるので、Wi-FiはUbuntuのインストールGUIから設定すればよい。モニタを外す前に2点だけ確認する。(1)再起動して未ログインのまま母艦からSSHできるか。(2)次のコマンドで、ログイン前の自動接続と省電力オフにしておく。省電力のWoL(任意)は無線だと不安定なので、使うなら有線が前提だ。
:::

```bash
# <NAME>は nmcli c で確認。Wi-Fiをログイン前から自動接続+省電力オフにする
sudo nmcli connection modify "<NAME>" connection.autoconnect yes connection.permissions ""
sudo nmcli connection modify "<NAME>" wifi.powersave 2
```

## VPSから重い処理を任せる

ここまでで、自宅GPU機は「常時起きていて、VPSからtailnet名で到達できる計算機」になった。VPSのHermes Agentから仕事を投げてみる。

まず、VPSから自宅機へSSH越しにGPUを確認する。`<gpu-host>.tail-xxxx.ts.net` は自分のtailnet名に置き換える。

```bash
# VPS上で
ssh <user>@<gpu-host>.tail-xxxx.ts.net "nvidia-smi"
```

次に、処理の様子を後から覗ける「観察台」をzellijで作る。SSHを切ってもセッションは生きるので、次回は `zellij attach observatory` で再接続できる。

```bash
# 母艦またはVPSから、自宅GPU機にSSHでログインする
ssh <user>@<gpu-host>.tail-xxxx.ts.net
# 自宅GPU機の上でzellijを入れて観察台を作る
sudo apt install -y zellij
zellij attach observatory --create
```

zellij内で画面を分割し、各ペインに監視コマンドを仕込んでおくと、処理中のGPU使用率やログを一望できる。

| ペイン | コマンド |
|---|---|
| 左上 | `watch -n 1 nvidia-smi`(GPU使用率) |
| 右上 | `journalctl -fu <推論サービス名>`(サービスのログ) |
| 左下 | `htop`(CPU/メモリ) |
| 右下 | 任意のコマンド用 |

あとは、自宅機で画像生成サービス(例:Stable Diffusion WebUIのAPI)やOllamaを起動しておけば、TelegramからHermes Agentに自然文で依頼できる。常時起動なので「起こす」手順は要らない。

```
夕焼けの東京タワーの写真風画像を1枚作って。
自宅GPU機(Tailscale経由)に投げて、結果画像をここに添付して。
```

Hermes Agentが自宅機のAPIに接続し、生成画像がTelegramに届けば、VPSの脳と自宅の手足が一本につながったことになる。

## 省電力は後から足す

まずは常時起動で確実に動かすのが本筋だが、電気代や発熱が気になるなら、後から「使うときだけ起こして、終わったら寝かせる」省電力運用に発展できる。これは任意の最適化で、この回の必須ではない。

Wake-on-LAN(WoL)で実現する場合のポイントだけ挙げておく。

- BIOSでWoLを有効化(Wake on LANをEnabled、ErPをDisabled)し、Ubuntu側でも起動時に `ethtool <nic> wol g` を有効にする
- 眠っているPCはOSが止まっているためTailscaleでは直接起こせない。同じ自宅LAN上の常時オン機(ルーターのWoL機能・NAS・小型常駐機など)からmagic packetを流す。新しい機材を買い足さなくても、すでにある常時オン機で足りることが多い
- 起こす/寝かせる操作をHermesのSkillにして、Telegramから呼べるようにする

WoLはネットワーク機器との相性差が出やすい。本シリーズでは「常時起動で確実に動かす」を本筋にし、省電力は各自の環境で余裕ができてから足す位置づけにしておく。

## よくあるエラーと対処

| 症状 | 対処 |
|---|---|
| USBから起動できない | BIOS/UEFIで起動順を変えるか、F12などの起動メニューでUSBを選ぶ。Secure Bootが邪魔する場合は一時的に無効化する |
| 再起動後にGPU機へSSHが繋がらない | 1) `systemctl is-enabled ssh tailscaled` で自動起動を確認、2) tailnet IPでなくtailnet名で接続、3) `tailscale status` でオンライン確認 |
| `nvidia-smi` が「command not found」/応答しない | 1) `sudo ubuntu-drivers autoinstall` を再実行して再起動、2) カーネル更新後にドライバが外れた場合は再導入、3) Secure Boot有効だとMOK登録が要る場合がある |
| モニタを外すと固まる/起動しない | 一部のマザーボードはディスプレイ無しを嫌う。BIOSでヘッドレス(no display)を許可するか、HDMIダミープラグを挿す |
| 勝手にスリープして応答が止まる | `systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target` が効いているか確認。Desktop版は電源設定でも自動サスペンドを切る |
| VPSから画像生成APIに繋がらない | `sudo ufw status` で確認し、必要なら `sudo ufw allow in on tailscale0` でtailnet経由を許可する(画像生成WebUIは7860、Ollamaは11434を使うことが多い) |

## まとめと次回へ

第12回でやったこと。

- 家の余ったPCのデータを退避し、Windowsを消してUbuntuに換装した
- SSHを鍵認証にし、Tailscaleで第2回のtailnetに参加させた
- NVIDIAドライバを入れ、`nvidia-smi` でGPUを認識させた
- スリープを無効化し、画面を消しても、AC復帰でも動く常時起動サーバーにした
- VPSのHermes AgentからSSH/API経由で重い処理を任せ、zellijの観察台で様子を見られるようにした

第1回では、VPSはただの小さなLinuxサーバーだった。第12回の終わりには、それはTelegramから呼べる常駐AIの司令塔になり、Tailscale越しに自宅GPU機まで動かせるようになった。Hermes Agentは「VPSという脳」「Tailscaleという神経」「1Passwordという秘密の金庫」「Codex/Grokという思考エンジン」「systemdという心臓」「Cronという日課」「Skillsという技能」「Web/X検索という感覚器官」「自宅Linux GPU機という手足」を手にしたことになる。

ここから先は、自分のSkillsを育てていく時間だ。VPSは置いたままでいい。エージェントが少しずつ、あなたの仕事の癖を覚えていく。次の第13回からは、このエージェントに「記憶(Memory)」を持たせて、さらに自分専用に育てていく。

---

| ← 前の回 | 次の回 → |
|---|---|
| 第11回 Web検索とX検索を使い分ける | (これが今の最終回です) |

📑 [シリーズ全12回のもくじ](https://zenn.dev/sora_biz/articles/hermes-vps-complete-guide)

## 公式ドキュメント引用元

| 項目 | 引用元 |
|---|---|
| Ubuntu インストール/サーバー | https://ubuntu.com/server/docs |
| NVIDIAドライバ(ubuntu-drivers) | https://ubuntu.com/server/docs/nvidia-drivers-installation |
| Tailscale CLI / SSH | https://tailscale.com/kb/1080/cli ・ https://tailscale.com/kb/1193/tailscale-ssh |
| zellij ドキュメント | https://zellij.dev/documentation |
| systemd sleep/suspend(mask) | https://www.freedesktop.org/software/systemd/man/systemd.special.html |
| ethtool Wake-on-LAN | https://man7.org/linux/man-pages/man8/ethtool.8.html |
