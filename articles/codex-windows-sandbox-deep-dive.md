---
title: "なぜOpenAIはWindows専用サンドボックスをOSSで公開したのか——全ソースコードを読んでわかった「何十億人戦略」の技術的根拠"
emoji: "🔬"
type: "idea"
topics: ["openai", "codex", "windows", "セキュリティ", "sandbox"]
published: false
---

## はじめに——「何十億人」発言の真意

OpenAI の Codex 責任者、Thibault Sottiaux 氏はこう言っている。

> 「サンドボックスを適切に構築し、非技術者にとって安全にできれば、コーディングエージェントの力を**何十億人もの**ユーザーに届けられる」
> ——[Fortune, 2026年3月4日](https://fortune.com/2026/03/04/openai-codex-growth-enterprise-ai-agents/)

「何十億人」。エンジニア人口は世界で約3000万人。何十億人という数字は、明らかにエンジニア以外を指している。

この発言の翌日、OpenAI は Windows 版 Codex アプリをリリースし、同時にその安全装置の核心——**Windows 専用サンドボックスのソースコード**を GitHub 上にオープンソースで公開した。

https://github.com/openai/codex/tree/main/codex-rs/windows-sandbox-rs

Cisco、Nvidia、楽天、Harvey といった大企業がすでに Codex を導入している。週間アクティブユーザーは 160 万人を超え、数ヶ月で 3 倍に成長。Windows 版のウェイトリストには 50 万人以上が並んだ。

この記事では、GitHub API を使って全 27 の Rust ソースファイルと 41 項目のテストスイートを正確に取得・精読した結果に基づき、**なぜこのサンドボックスが「非エンジニア」と「企業」の両方を射程に入れることを可能にするのか**を、省略なしで解説する。

---

## 「非エンジニアに AI エージェントを使わせる」ことの本質的な難しさ

エンジニアが AI コーディングエージェントを使う場合、何が起きているか自分で理解できる。変なファイルを消されても、git でロールバックできる。ネットワーク接続の挙動がおかしければ、自分でプロセスを殺せる。

非エンジニアにはそれができない。

だから「AI エージェントに自分のパソコンでコードを実行させる」という行為は、非エンジニアにとっては**制御不能なリスク**だ。重要な業務ファイルを消される。社内ネットワークに予期しない接続をされる。秘密鍵やクラウド認証情報を外部に送信される。これらのリスクを「ユーザーの判断で回避してください」と言うのは、非エンジニア向けプロダクトとして成立しない。

企業の IT 部門も同じだ。CISO（最高情報セキュリティ責任者）は「AI エージェントが社員のマシンで任意のコードを実行します」と聞いた瞬間に拒否する。アプリケーションレベルのガードレールでは不十分で、**OS カーネルレベルでの強制的な制約**がなければ、企業のセキュリティ要件を満たせない。

OpenAI がこの問題を解決した方法が、今回公開されたサンドボックスだ。

---

## リポジトリ構成——27 ファイルで何を実現しているか

```
codex-rs/windows-sandbox-rs/
├── src/
│   ├── bin/
│   │   ├── command_runner.rs      # サンドボックス内コマンド実行バイナリ
│   │   └── setup_main.rs         # セットアップバイナリのエントリポイント
│   ├── acl.rs                    # DACL 操作（allow/deny ACE の追加・削除）
│   ├── allow.rs                  # ポリシーに基づくパス許可/拒否の計算
│   ├── audit.rs                  # world-writable ディレクトリの事前スキャン
│   ├── cap.rs                    # Capability SID の生成・永続化
│   ├── command_runner_win.rs     # サンドボックス内コマンドランナー（Windows実装）
│   ├── cwd_junction.rs           # CWD ジャンクション処理
│   ├── dpapi.rs                  # Windows DPAPI による暗号化/復号
│   ├── elevated_impl.rs          # 管理者権限での実行
│   ├── env.rs                    # 環境変数の操作（ネットワーク遮断・stub配置）
│   ├── firewall.rs               # Windows Firewall ルール管理
│   ├── helper_materialization.rs # ヘルパーバイナリの配置
│   ├── hide_users.rs             # サンドボックスユーザーの非表示化
│   ├── identity.rs               # サンドボックスユーザーの認証・選択
│   ├── lib.rs                    # ライブラリエントリポイント
│   ├── logging.rs                # 監査ログ
│   ├── path_normalization.rs     # パス正規化
│   ├── policy.rs                 # サンドボックスポリシー定義
│   ├── process.rs                # プロセス生成
│   ├── read_acl_mutex.rs         # ACL 操作の排他制御
│   ├── sandbox_users.rs          # サンドボックスユーザーの作成・管理
│   ├── setup_error.rs            # セットアップエラー処理
│   ├── setup_main_win.rs         # セットアップのWindows固有処理
│   ├── setup_orchestrator.rs     # セットアップの全体制御
│   ├── token.rs                  # Restricted Token の生成
│   ├── winutil.rs                # Windows ユーティリティ関数
│   └── workspace_acl.rs          # ワークスペース保護
├── BUILD.bazel                   # Bazel ビルド設定
├── Cargo.toml                    # Rust パッケージ定義
├── build.rs                      # ビルドスクリプト（マニフェスト埋め込み）
├── codex-windows-sandbox-setup.manifest  # UAC マニフェスト
└── sandbox_smoketests.py         # 41 項目のスモークテスト
```

---

## 7 層アーキテクチャ——「ユーザーが何もしなくても安全」を実現する構造

```
┌─────────────────────────────────────────────┐
│  Layer 7: Setup Orchestrator                │  セットアップの全体制御
│  (setup_orchestrator.rs, identity.rs)       │  UAC 昇格・ユーザー作成
├─────────────────────────────────────────────┤
│  Layer 6: Audit                             │  事前スキャン
│  (audit.rs)                                 │  world-writable 検出・修復
├─────────────────────────────────────────────┤
│  Layer 5: Environment                       │  環境変数操作
│  (env.rs)                                   │  ネットワーク遮断・stub 配置
├─────────────────────────────────────────────┤
│  Layer 4: Firewall                          │  ネットワーク制御
│  (firewall.rs)                              │  Outbound ブロックルール
├─────────────────────────────────────────────┤
│  Layer 3: ACL / Allow-Deny                  │  ファイルシステム制御
│  (acl.rs, allow.rs, workspace_acl.rs)       │  パスごとの許可/拒否
├─────────────────────────────────────────────┤
│  Layer 2: Token                             │  プロセス権限制限
│  (token.rs, cap.rs)                         │  Restricted Token + Capability SID
├─────────────────────────────────────────────┤
│  Layer 1: Policy                            │  ポリシー定義
│  (policy.rs)                                │  ReadOnly / WorkspaceWrite
└─────────────────────────────────────────────┘
```

この 7 層が連携して、**ユーザーが意識しなくても、AI エージェントの行動が OS カーネルレベルで制限される**仕組みを実現している。以下、各層を順番に解説する。

---

## Layer 1: Policy——「2 つのモード」というシンプルさ

**ファイル: `policy.rs`（25 行）**

非エンジニアに使わせるなら、選択肢はシンプルでなければならない。ポリシーは実質 2 つだけだ。

```rust
pub fn parse_policy(value: &str) -> Result<SandboxPolicy> {
    match value {
        "read-only" => Ok(SandboxPolicy::new_read_only_policy()),
        "workspace-write" => Ok(SandboxPolicy::new_workspace_write_policy()),
        "danger-full-access" | "external-sandbox" => anyhow::bail!(
            "DangerFullAccess and ExternalSandbox are not supported for sandboxing"
        ),
        other => {
            let parsed: SandboxPolicy = serde_json::from_str(other)?;
            if matches!(parsed, SandboxPolicy::DangerFullAccess | SandboxPolicy::ExternalSandbox { .. }) {
                anyhow::bail!("DangerFullAccess and ExternalSandbox are not supported");
            }
            Ok(parsed)
        }
    }
}
```

| ポリシー           | 意味                   | ディスク読み取り | ディスク書き込み     | ネットワーク |
| :----------------- | :--------------------- | :--------------- | :------------------- | :----------- |
| `ReadOnly`         | 読み取り専用           | 全体             | 不可                 | 不可         |
| `WorkspaceWrite`   | ワークスペース書き込み | 全体             | CWD + 追加ルートのみ | 設定次第     |
| `DangerFullAccess` | 全権限                 | **拒否される**   | —                    | —            |
| `ExternalSandbox`  | 外部サンドボックス     | **拒否される**   | —                    | —            |

注目すべきは、`DangerFullAccess` が**文字列プリセットでも JSON パースでも拒否される**こと。つまり「全権限」モードはサンドボックスから完全に排除されている。ユーザーが間違って危険な設定を選ぶことが構造的に不可能になっている。

**なぜこれが非エンジニア戦略に重要か：** 「よくわからないけど動かない」→「危険な設定にすれば動く」という安易なエスカレーションを、コードレベルで防いでいる。

---

## Layer 2: Token——OS カーネルが強制する「バイパス不可能な」権限制限

**ファイル: `token.rs`（約 250 行）、`cap.rs`（約 100 行）**

これがサンドボックスの核心であり、**アプリケーションレベルのガードレールとの決定的な違い**だ。

### Restricted Token の生成

```rust
const DISABLE_MAX_PRIVILEGE: u32 = 0x01;
const LUA_TOKEN: u32 = 0x04;
const WRITE_RESTRICTED: u32 = 0x08;

unsafe fn create_token_with_caps_from(
    base_token: HANDLE,
    psid_capabilities: &[*mut c_void],
) -> Result<HANDLE> {
    // 1. ログオン SID と Everyone SID を取得
    let mut logon_sid_bytes = get_logon_sid_bytes(base_token)?;
    let psid_logon = logon_sid_bytes.as_mut_ptr() as *mut c_void;
    let mut everyone = world_sid()?;
    let psid_everyone = everyone.as_mut_ptr() as *mut c_void;

    // 2. SID リストを構築: [Capabilities..., Logon, Everyone]
    let mut entries: Vec<SID_AND_ATTRIBUTES> =
        vec![std::mem::zeroed(); psid_capabilities.len() + 2];
    for (i, psid) in psid_capabilities.iter().enumerate() {
        entries[i].Sid = *psid;
    }
    entries[psid_capabilities.len()].Sid = psid_logon;
    entries[psid_capabilities.len() + 1].Sid = psid_everyone;

    // 3. 3 つのフラグで最大限の制限をかける
    let flags = DISABLE_MAX_PRIVILEGE | LUA_TOKEN | WRITE_RESTRICTED;
    let ok = CreateRestrictedToken(
        base_token, flags,
        0, std::ptr::null(),     // 無効化する SID なし
        0, std::ptr::null(),     // 削除する特権なし
        entries.len() as u32,
        entries.as_mut_ptr(),    // 制限 SID
        &mut new_token,
    );

    // 4. デフォルト DACL を設定（PowerShell パイプライン用）
    set_default_dacl(new_token, &dacl_sids)?;

    // 5. SeChangeNotifyPrivilege だけ有効化（ディレクトリ走査に必要）
    enable_single_privilege(new_token, "SeChangeNotifyPrivilege")?;

    Ok(new_token)
}
```

3 つのフラグの意味。

| フラグ                  | 効果                                      |
| :---------------------- | :---------------------------------------- |
| `DISABLE_MAX_PRIVILEGE` | 全ての特権を無効化                        |
| `LUA_TOKEN`             | 管理者トークンを通常ユーザーレベルに降格  |
| `WRITE_RESTRICTED`      | 書き込み制限付き SID のみで書き込みを許可 |

`WRITE_RESTRICTED` が最も重要だ。このフラグにより、トークンに含まれる Capability SID が ACL の allow エントリと一致した場合**のみ**書き込みが許可される。それ以外のパスへの書き込みは **OS カーネルが拒否する**。

**なぜこれが企業戦略に重要か：** アプリケーションレベルのガードレール（「このコマンドは危険なのでブロックします」）は、悪意あるプロンプトや巧妙なバイパスで突破される可能性がある。一方、OS カーネルレベルの制約は、サンドボックス内のプロセスがどんなコードを実行しても突破できない。CISO が求めるのはこのレベルの保証だ。

### Per-workspace Capability SID——ワークスペース間の完全隔離

```rust
#[derive(Serialize, Deserialize)]
pub struct CapSids {
    pub workspace: String,                          // workspace-write 用の SID
    pub readonly: String,                           // read-only 用の SID
    pub workspace_by_cwd: HashMap<String, String>,  // CWD ごとの SID
}

fn make_random_cap_sid_string() -> String {
    let mut rng = SmallRng::from_entropy();
    let a = rng.next_u32();
    let b = rng.next_u32();
    let c = rng.next_u32();
    let d = rng.next_u32();
    format!("S-1-5-21-{}-{}-{}-{}", a, b, c, d)
}
```

ワークスペースごとに一意のランダム SID（`S-1-5-21-{random}x4`）を生成する。

```rust
pub fn workspace_cap_sid_for_cwd(codex_home: &Path, cwd: &Path) -> Result<String> {
    let mut caps = load_or_create_cap_sids(codex_home)?;
    let key = canonical_path_key(cwd);  // 小文字化 + / 統一
    if let Some(sid) = caps.workspace_by_cwd.get(&key) {
        return Ok(sid.clone());
    }
    let sid = make_random_cap_sid_string();
    caps.workspace_by_cwd.insert(key, sid.clone());
    persist_caps(&path, &caps)?;
    Ok(sid)
}
```

プロジェクト A のサンドボックスがプロジェクト B のファイルにアクセスすることは、SID が異なるため不可能。

**なぜこれが企業戦略に重要か：** 企業では複数のプロジェクトを同じマシンで開発する。プロジェクト間のデータ漏洩を OS レベルで防止できるのは、コンプライアンス上の強力な保証になる。

### デフォルト DACL の設定

```rust
unsafe fn set_default_dacl(h_token: HANDLE, sids: &[*mut c_void]) -> Result<()> {
    let entries: Vec<EXPLICIT_ACCESS_W> = sids.iter().map(|sid| EXPLICIT_ACCESS_W {
        grfAccessPermissions: GENERIC_ALL,
        grfAccessMode: GRANT_ACCESS,
        grfInheritance: 0,
        Trustee: TRUSTEE_W {
            TrusteeForm: TRUSTEE_IS_SID,
            ptstrName: *sid as *mut u16,
            ..
        },
    }).collect();
    SetEntriesInAclW(entries.len() as u32, entries.as_ptr(), ..);
    SetTokenInformation(h_token, TokenDefaultDacl, ..);
}
```

PowerShell がパイプラインを構築する際に `ACCESS_DENIED` にならないようにする措置。サンドボックスプロセスが子プロセスやパイプを作成できるように、デフォルト DACL に Capability SID と Logon SID、Everyone SID を含めている。

---

## Layer 3: ACL——「ここは触っていい、ここはダメ」をパス単位で制御

**ファイル: `acl.rs`（約 400 行）、`allow.rs`（約 100 行）、`workspace_acl.rs`（約 30 行）**

### allow/deny パスの計算

```rust
pub fn compute_allow_paths(
    policy: &SandboxPolicy,
    policy_cwd: &Path,
    command_cwd: &Path,
    env_map: &HashMap<String, String>,
) -> AllowDenyPaths {
    let mut allow: HashSet<PathBuf> = HashSet::new();
    let mut deny: HashSet<PathBuf> = HashSet::new();

    if matches!(policy, SandboxPolicy::WorkspaceWrite { .. }) {
        // CWD を allow に追加
        add_allow(command_cwd.to_path_buf());

        // 追加の writable_roots を allow に追加
        for root in writable_roots { add_allow(root); }

        // ★ 保護対象ディレクトリは常に deny
        for protected_subdir in [".git", ".codex", ".agents"] {
            let protected_entry = canonical.join(protected_subdir);
            if protected_entry.exists() {
                add_deny(protected_entry);
            }
        }
    }

    // TEMP/TMP ディレクトリも許可（exclude_tmpdir_env_var が false の場合）
    if include_tmp_env_vars {
        for key in ["TEMP", "TMP"] {
            if let Some(v) = env_map.get(key) {
                add_allow(PathBuf::from(v));
            }
        }
    }

    AllowDenyPaths { allow, deny }
}
```

ここが設計上非常に重要なポイントだ。**writable root の中であっても `.git`、`.codex`、`.agents` は常に deny される**。AI エージェントがプロジェクトのソースコードを編集できても、git の設定や Codex の内部ファイルは書き換えられない。

**なぜこれが非エンジニア戦略に重要か：** 非エンジニアは `.git` フォルダの意味を知らない。「このフォルダ全部に書き込み権限をあげていいですか？」と聞かれても判断できない。だからサンドボックスが**自動的に**保護する。ユーザーに判断を求めない。

### DACL への ACE 追加

```rust
// allow ACE の追加
pub unsafe fn add_allow_ace(path: &Path, psid: *mut c_void) -> Result<bool> {
    // 1. 現在の DACL を取得
    GetNamedSecurityInfoW(to_wide(path).as_ptr(), ..);

    // 2. 既に write allow がある場合はスキップ（冪等性）
    if dacl_has_write_allow_for_sid(p_dacl, psid) {
        return Ok(false);
    }

    // 3. allow ACE を構築
    let mut explicit: EXPLICIT_ACCESS_W = zeroed();
    explicit.grfAccessPermissions = FILE_GENERIC_READ | FILE_GENERIC_WRITE | FILE_GENERIC_EXECUTE;
    explicit.grfAccessMode = 2;  // SET_ACCESS
    explicit.grfInheritance = CONTAINER_INHERIT_ACE | OBJECT_INHERIT_ACE;

    // 4. DACL に追加して書き戻し
    SetEntriesInAclW(1, &explicit, p_dacl, &mut p_new_dacl);
    SetNamedSecurityInfoW(..., p_new_dacl, ...);

    Ok(true)
}
```

```rust
// deny ACE の追加
pub unsafe fn add_deny_write_ace(path: &Path, psid: *mut c_void) -> Result<bool> {
    // write, append, delete, EA write, attribute write の全てを deny
    explicit.grfAccessPermissions = FILE_GENERIC_WRITE
        | FILE_WRITE_DATA | FILE_APPEND_DATA
        | FILE_WRITE_EA | FILE_WRITE_ATTRIBUTES
        | GENERIC_WRITE_MASK | DELETE | FILE_DELETE_CHILD;
    explicit.grfAccessMode = DENY_ACCESS;
}
```

deny マスクに `FILE_DELETE_CHILD` が含まれている。親ディレクトリに deny を設定することで、その中のファイルの削除も防ぐ。

### ACE の revoke（サンドボックス終了時）

```rust
pub unsafe fn revoke_ace(path: &Path, psid: *mut c_void) {
    explicit.grfAccessMode = 4;  // REVOKE_ACCESS
    SetEntriesInAclW(1, &explicit, p_dacl, &mut p_new_dacl);
    SetNamedSecurityInfoW(..., p_new_dacl, ...);
}
```

ReadOnly モードでは、サンドボックス終了時に一時的に追加した ACE を削除する。WorkspaceWrite モードでは ACE を永続化し、次回の起動を高速化する。

### ワークスペース保護

```rust
pub unsafe fn protect_workspace_codex_dir(cwd: &Path, psid: *mut c_void) -> Result<bool> {
    let path = cwd.join(".codex");
    if path.is_dir() { add_deny_write_ace(&path, psid) }
    else { Ok(false) }
}

pub unsafe fn protect_workspace_agents_dir(cwd: &Path, psid: *mut c_void) -> Result<bool> {
    let path = cwd.join(".agents");
    if path.is_dir() { add_deny_write_ace(&path, psid) }
    else { Ok(false) }
}
```

### NUL デバイスへのアクセス許可

```rust
pub unsafe fn allow_null_device(psid: *mut c_void) {
    let h = CreateFileW(to_wide(r"\\\\.\\NUL").as_ptr(), ...);
    // カーネルオブジェクトとして DACL に allow ACE を追加
    GetSecurityInfo(h, SE_KERNEL_OBJECT, ...);
    explicit.grfAccessPermissions = FILE_GENERIC_READ | FILE_GENERIC_WRITE | FILE_GENERIC_EXECUTE;
    SetSecurityInfo(h, SE_KERNEL_OBJECT, ...);
}
```

stdout/stderr のリダイレクト先として `NUL` デバイスへのアクセスを許可する。これがないと、サンドボックス内のプロセスが標準出力に書き込めなくなる。

### DACL マスクチェック

```rust
pub unsafe fn dacl_mask_allows(
    p_dacl: *mut ACL,
    psids: &[*mut c_void],
    desired_mask: u32,
    require_all_bits: bool,
) -> bool {
    for i in 0..(info.AceCount as usize) {
        let hdr = &*(p_ace as *const ACE_HEADER);
        if hdr.AceType != 0 { continue; }               // ACCESS_ALLOWED 以外はスキップ
        if (hdr.AceFlags & INHERIT_ONLY_ACE) != 0 { continue; }  // inherit-only はスキップ
        // SID が一致するか確認
        for sid in psids {
            if EqualSid(sid_ptr, *sid) != 0 { matched = true; break; }
        }
        // マスクチェック（MapGenericMask でファイル固有マスクに変換）
        let mut mask = ace.Mask;
        MapGenericMask(&mut mask, &mapping);
        if require_all_bits {
            if (mask & desired_mask) == desired_mask { return true; }
        } else {
            if (mask & desired_mask) != 0 { return true; }
        }
    }
    false
}
```

`MapGenericMask` で GENERIC_READ/WRITE/EXECUTE をファイルシステム固有のアクセスマスクに変換してから比較している。これを怠ると、GENERIC_WRITE を設定した ACE が FILE_WRITE_DATA のチェックに引っかからないケースが発生する。

---

## Layer 4: Firewall——ネットワーク接続の OS レベル遮断

**ファイル: `firewall.rs`（約 150 行）**

```rust
const OFFLINE_BLOCK_RULE_NAME: &str = "codex_sandbox_offline_block_outbound";

pub fn ensure_offline_outbound_block(offline_sid: &str, log: &mut File) -> Result<()> {
    let local_user_spec = format!("O:LSD:(A;;CC;;;{offline_sid})");

    CoInitializeEx(None, COINIT_APARTMENTTHREADED);

    let policy: INetFwPolicy2 = CoCreateInstance(&NetFwPolicy2, None, CLSCTX_INPROC_SERVER)?;
    let rules = policy.Rules()?;

    ensure_block_rule(&rules, OFFLINE_BLOCK_RULE_NAME, ..)?;
}

fn configure_rule(rule: &INetFwRule3, ...) -> Result<()> {
    rule.SetDirection(NET_FW_RULE_DIR_OUT)?;     // Outbound のみ
    rule.SetAction(NET_FW_ACTION_BLOCK)?;         // ブロック
    rule.SetEnabled(VARIANT_TRUE)?;               // 有効
    rule.SetProfiles(NET_FW_PROFILE2_ALL.0)?;     // 全プロファイル
    rule.SetProtocol(NET_FW_IP_PROTOCOL_ANY.0)?;  // 全プロトコル
    rule.SetLocalUserAuthorizedList(&BSTR::from(local_user_spec))?;

    // Read-back 検証: 設定が反映されたか確認
    let actual = rule.LocalUserAuthorizedList()?;
    if !actual.to_string().contains(offline_sid) {
        return Err(anyhow!("firewall rule user scope mismatch"));
    }
    Ok(())
}
```

特徴。

- **Outbound のみ**をブロック（Inbound は無関係）
- **全プロトコル**（TCP、UDP、ICMP 全て）
- **SID ベースの制限**: `LocalUserAuthorizedList` により、offline ユーザーのプロセスのみに適用
- **冪等性**: 既存ルールがあれば更新、なければ作成
- **Read-back 検証**: 設定後に値を読み返して、正しく反映されたか確認

**なぜこれが企業戦略に重要か：** 企業ネットワーク内で AI エージェントが外部に通信することは、データ漏洩（exfiltration）のリスクになる。Windows Firewall による OS レベルのネットワーク遮断は、IT 部門が監査可能な形で通信を制御できる。

---

## Layer 5: Environment——4 層のネットワーク遮断

**ファイル: `env.rs`（約 150 行）**

ファイアウォールだけでは不十分。アプリケーションレベルでもネットワークを多重に遮断する。

### プロキシ環境変数の注入

```rust
pub fn apply_no_network_to_env(env_map: &mut HashMap<String, String>) -> Result<()> {
    env_map.insert("SBX_NONET_ACTIVE".into(), "1".into());

    // 無効なプロキシ（port 9 = discard protocol）
    // discard protocol (port 9) のローカルアドレスを設定
    env_map.entry("HTTP_PROXY".into()).or_insert("http://localhost:9".into());
    env_map.entry("HTTPS_PROXY".into()).or_insert("http://localhost:9".into());
    env_map.entry("ALL_PROXY".into()).or_insert("http://localhost:9".into());

    // パッケージマネージャーをオフラインモードに
    env_map.entry("PIP_NO_INDEX".into()).or_insert("1".into());
    env_map.entry("NPM_CONFIG_OFFLINE".into()).or_insert("true".into());
    env_map.entry("CARGO_NET_OFFLINE".into()).or_insert("true".into());

    // Git のネットワーク接続を完全遮断
    env_map.entry("GIT_SSH_COMMAND".into()).or_insert("cmd /c exit 1".into());
    env_map.entry("GIT_ALLOW_PROTOCOLS".into()).or_insert("".into());

    // deny-bin stub を PATH 先頭に配置
    let base = ensure_denybin(&["ssh", "scp"], None)?;
    prepend_path(env_map, &base.to_string_lossy());
    reorder_pathext_for_stubs(env_map);
    Ok(())
}
```

### deny-bin stub——「exit 1 の .bat ファイル」という軽量で効果的な手法

```rust
fn ensure_denybin(tools: &[&str], denybin_dir: Option<&Path>) -> Result<PathBuf> {
    let base = home_dir().join(".sbx-denybin");
    fs::create_dir_all(&base)?;
    for tool in tools {
        for ext in [".bat", ".cmd"] {
            let path = base.join(format!("{}{}", tool, ext));
            if !path.exists() {
                let mut f = File::create(&path)?;
                f.write_all(b"@echo off\r\nexit /b 1\r\n")?;
            }
        }
    }
    Ok(base)
}
```

`~/.sbx-denybin/ssh.bat` の中身は `@echo off` + `exit /b 1`（即座にエラー終了）。これを PATH の先頭に配置し、PATHEXT を `.BAT;.CMD;.COM;.EXE` に並べ替えることで、本物の `ssh.exe` より先にこの stub が見つかるようにする。

```rust
fn reorder_pathext_for_stubs(env_map: &mut HashMap<String, String>) {
    let want = [".BAT", ".CMD"];
    // .BAT と .CMD を PATHEXT の先頭に移動
    // .EXE より先に .BAT を探させることで、stub が優先される
}
```

### ネットワーク遮断の 4 層まとめ

| 層                | 手法                         | 防御対象               |
| :---------------- | :--------------------------- | :--------------------- |
| **Firewall**      | Windows Firewall ルール      | 全 TCP/UDP/ICMP        |
| **Proxy**         | `HTTP_PROXY=localhost:9`     | HTTP/HTTPS ライブラリ  |
| **Offline mode**  | `NPM_CONFIG_OFFLINE=true` 等 | パッケージマネージャー |
| **deny-bin stub** | `ssh.bat` = `exit /b 1`      | SSH/SCP コマンド       |

1 つの層が突破されても、別の層が防御する。

### その他の環境変数操作

```rust
// /dev/null を NUL に正規化（Unix 向けの設定が混在する場合）
pub fn normalize_null_device_env(env_map: &mut HashMap<String, String>) {
    for k in keys {
        if t == "/dev/null" || t == "\\\\dev\\\\null" {
            env_map.insert(k, "NUL".to_string());
        }
    }
}

// GIT_PAGER をインタラクティブでないものに
pub fn ensure_non_interactive_pager(env_map: &mut HashMap<String, String>) {
    env_map.entry("GIT_PAGER".into()).or_insert("more.com".into());
    env_map.entry("PAGER".into()).or_insert("more.com".into());
}
```

---

## Layer 6: Audit——「ユーザーの環境が安全かどうか」を事前に確認する

**ファイル: `audit.rs`（約 250 行）**

サンドボックス起動前に、world-writable（Everyone に書き込み権限がある）ディレクトリをスキャンして、そこに deny ACE を適用する。

```rust
const MAX_ITEMS_PER_DIR: i32 = 1000;
const AUDIT_TIME_LIMIT_SECS: i64 = 2;
const MAX_CHECKED_LIMIT: i32 = 50000;

const SKIP_DIR_SUFFIXES: &[&str] = &[
    "/windows/installer",
    "/windows/registration",
    "/programdata",
];

pub fn audit_everyone_writable(
    cwd: &Path,
    env: &HashMap<String, String>,
    logs_base_dir: Option<&Path>,
) -> Result<Vec<PathBuf>> {
    let start = Instant::now();

    // 1. CWD の直下を最優先でスキャン（ワークスペースの問題を早期検出）
    if let Ok(read) = std::fs::read_dir(cwd) {
        for ent in read.flatten().take(MAX_ITEMS_PER_DIR as usize) {
            if start.elapsed() > Duration::from_secs(2) { break; }
            if ft.is_symlink() || !ft.is_dir() { continue; }
            if check_world_writable(&p) { flagged.push(p); }
        }
    }

    // 2. 広域スキャン（時間制限 2 秒、件数制限 50,000）
    let candidates = gather_candidates(cwd, env);
    for root in candidates {
        if start.elapsed() > 2sec || checked > 50000 { break; }
        if check_world_writable(&root) { flagged.push(root); }
        // 1 階層下もスキャン（symlink はスキップ、システムディレクトリはスキップ）
        for ent in read_dir(&root).take(1000) {
            if ft.is_symlink() { continue; }
            if SKIP_DIR_SUFFIXES.iter().any(|s| norm.ends_with(s)) { continue; }
            if check_world_writable(&p) { flagged.push(p); }
        }
    }
    Ok(flagged)
}
```

### スキャン対象の優先順位

```rust
fn gather_candidates(cwd: &Path, env: &HashMap<String, String>) -> Vec<PathBuf> {
    // 1. CWD（最優先）
    // 2. TEMP/TMP（小さいので高速）
    // 3. USERPROFILE, PUBLIC
    // 4. PATH の各エントリ
    // 5. C:\, C:\Windows（最後）
}
```

2 秒という時間制限は、ユーザー体験を損なわないための工夫だ。非エンジニアは「なぜ起動に 10 秒もかかるのか」を理解できない。

**なぜこれが非エンジニア戦略に重要か：** 非エンジニアのマシンは、エンジニアのマシンよりもセキュリティ設定が甘いことが多い。world-writable ディレクトリが意図せず存在していることもある。このスキャンがそれを自動で検出・修復する。

---

## Layer 7: Setup——「Setup ボタンを 1 回押すだけ」の裏側

**ファイル: `setup_orchestrator.rs`（約 500 行）、`identity.rs`（約 200 行）、`sandbox_users.rs`（約 350 行）**

Codex アプリの UI で「Setup」ボタンを押すと何が起きるか。裏側では以下が実行される。

### デュアルユーザーモデル

```rust
pub const OFFLINE_USERNAME: &str = "CodexSandboxOffline";
pub const ONLINE_USERNAME: &str = "CodexSandboxOnline";
```

Windows のローカルユーザーアカウントを 2 つ作成する。

| ユーザー              | 用途                   | ネットワーク        |
| :-------------------- | :--------------------- | :------------------ |
| `CodexSandboxOffline` | ネットワーク不要な操作 | Firewall で完全遮断 |
| `CodexSandboxOnline`  | ネットワーク必要な操作 | アクセス可能        |

### ユーザー作成

```rust
pub fn ensure_local_user(name: &str, secret: &str, log: &mut File) -> Result<()> {
    let info = USER_INFO_1 {
        usri1_name: name_w.as_ptr(),
        usri1_secret: pwd_w.as_ptr(),       // 認証トークン
        usri1_flags: UF_SCRIPT | UF_DONT_EXPIRE_PASSWD,
        usri1_priv: USER_PRIV_USER,
    };
    let status = NetUserAdd(std::ptr::null(), 1, &info, ...);
    // 既存ユーザーなら認証トークンだけ更新
    if status != NERR_Success {
        let pw_info = USER_INFO_1003 { usri1003_secret: pwd_w.as_ptr() };
        NetUserSetInfo(std::ptr::null(), name_w.as_ptr(), 1003, &pw_info, ...);
    }
}
```

### パスワードの暗号化保存——Windows DPAPI

```rust
// dpapi.rs
pub fn protect(data: &[u8]) -> Result<Vec<u8>> {
    CryptProtectData(
        &mut in_blob,
        std::ptr::null(),
        std::ptr::null(),
        std::ptr::null_mut(),
        std::ptr::null_mut(),
        CRYPTPROTECT_UI_FORBIDDEN | CRYPTPROTECT_LOCAL_MACHINE,
        &mut out_blob,
    );
}

pub fn unprotect(blob: &[u8]) -> Result<Vec<u8>> {
    CryptUnprotectData(
        &mut in_blob, ...,
        CRYPTPROTECT_UI_FORBIDDEN | CRYPTPROTECT_LOCAL_MACHINE,
        &mut out_blob,
    );
}
```

`CRYPTPROTECT_LOCAL_MACHINE` フラグにより、同一マシン上の全ユーザーが復号できる。管理者権限（elevated）でセットアップし、通常ユーザー権限（non-elevated）で使用するため。

パスワードの保存フロー。

1. ランダムパスワード生成（24 文字、英数字 + 記号）
2. DPAPI で暗号化
3. Base64 エンコード
4. `~/.codex/.sandbox-secrets/sandbox_users.json` に保存

### UAC 昇格

```rust
fn run_setup_exe(payload: &ElevationPayload, needs_elevation: bool, ...) -> Result<()> {
    if !needs_elevation {
        Command::new(&exe).arg(&payload_b64)
            .creation_flags(0x08000000)  // CREATE_NO_WINDOW
            .status()?;
    } else {
        // UAC 昇格（ShellExecuteEx + "runas"）
        sei.lpVerb = to_wide("runas").as_ptr();
        sei.nShow = 0;  // SW_HIDE
        ShellExecuteExW(&mut sei);
        WaitForSingleObject(sei.hProcess, INFINITE);
    }
}
```

ユーザーが見るのは Windows 標準の UAC ダイアログだけ。「このアプリがデバイスに変更を加えることを許可しますか？」→「はい」。それだけ。

### ユーザープロファイルの保護——秘密情報の自動除外

```rust
const USERPROFILE_READ_ROOT_EXCLUSIONS: &[&str] = &[
    ".ssh", ".gnupg", ".aws", ".azure", ".kube",
    ".docker", ".config", ".npm", ".pki", ".terraform.d",
];

fn profile_read_roots(user_profile: &Path) -> Vec<PathBuf> {
    entries
        .filter(|(name, _)| {
            !USERPROFILE_READ_ROOT_EXCLUSIONS.iter()
                .any(|excluded| name.eq_ignore_ascii_case(excluded))
        })
        .map(|(_, path)| path)
        .collect()
}
```

ユーザープロファイル配下の読み取りを許可する際、秘密情報が含まれるディレクトリを自動除外する。`.ssh`（SSH 秘密鍵）、`.aws`（AWS 認証情報）、`.kube`（Kubernetes 設定）など 10 種類のディレクトリがハードコードされている。

**なぜこれが非エンジニア戦略に決定的に重要か：** 非エンジニアは `.aws` フォルダに自分のクラウド認証情報が入っていることすら知らない。「全部読み取り許可しますか？」と聞かれたら「はい」と答えてしまう。だからサンドボックスが**聞かずに自動で除外する**。

### 機密ディレクトリの書き込み保護

```rust
fn filter_sensitive_write_roots(mut roots: Vec<PathBuf>, codex_home: &Path) -> Vec<PathBuf> {
    roots.retain(|root| {
        let key = canonical_path_key(root);
        key != codex_home_key
            && key != sbx_dir_key          // .sandbox
            && !key.starts_with(&sbx_dir_prefix)
            && key != sbx_bin_dir_key      // .sandbox-bin
            && !key.starts_with(&sbx_bin_dir_prefix)
            && key != secrets_dir_key      // .sandbox-secrets
            && !key.starts_with(&secrets_dir_prefix)
    });
    roots
}
```

サンドボックス自身の制御ファイル（暗号化パスワード、ヘルパーバイナリ、セットアップマーカー）は、いかなる場合も書き込み対象から除外される。

---

## パス正規化——Windows 固有の落とし穴を一元処理

**ファイル: `path_normalization.rs`（20 行）**

```rust
pub fn canonicalize_path(path: &Path) -> PathBuf {
    dunce::canonicalize(path).unwrap_or_else(|_| path.to_path_buf())
}

pub fn canonical_path_key(path: &Path) -> String {
    canonicalize_path(path)
        .to_string_lossy()
        .replace('\\', "/")     // バックスラッシュを統一
        .to_ascii_lowercase()   // 大文字小文字を統一
}
```

`dunce::canonicalize` を使う理由は、標準ライブラリの `std::fs::canonicalize` が Windows で `\\?\C:\Dir\...` という UNC プレフィクス付きパスを返すため。`dunce` クレートがこれを `C:\Dir\...` 形式に正規化する。

テストで保証している。

```rust
#[test]
fn canonical_path_key_normalizes_case_and_separators() {
    let windows_style = Path::new(r"C:\Dev\MyRepo");
    let slash_style = Path::new("c:/dev/myrepo");
    assert_eq!(canonical_path_key(windows_style), canonical_path_key(slash_style));
}
```

---

## 排他制御——Named Mutex による ACL 操作の保護

**ファイル: `read_acl_mutex.rs`（約 50 行）**

```rust
const READ_ACL_MUTEX_NAME: &str = "Local\\CodexSandboxReadAcl";

pub struct ReadAclMutexGuard {
    handle: HANDLE,
}

impl Drop for ReadAclMutexGuard {
    fn drop(&mut self) {
        unsafe {
            ReleaseMutex(self.handle);
            CloseHandle(self.handle);
        }
    }
}

pub fn acquire_read_acl_mutex() -> Result<Option<ReadAclMutexGuard>> {
    let handle = CreateMutexW(std::ptr::null_mut(), 1, name.as_ptr());
    let err = GetLastError();
    if err == ERROR_ALREADY_EXISTS {
        CloseHandle(handle);
        return Ok(None);  // 他のプロセスが保持中
    }
    Ok(Some(ReadAclMutexGuard { handle }))
}
```

RAII パターンで mutex を管理。`ReadAclMutexGuard` がスコープを抜けると自動的に mutex が解放される。プロセスがクラッシュしても mutex がリークしない。

---

## 監査ログ——UTF-8 安全な切り詰め

**ファイル: `logging.rs`（約 80 行）**

```rust
pub const LOG_FILE_NAME: &str = "sandbox.log";

pub fn log_start(command: &[String], base_dir: Option<&Path>) {
    log_note(&format!("START: {}", preview(command)), base_dir);
}

pub fn log_success(command: &[String], base_dir: Option<&Path>) {
    log_note(&format!("SUCCESS: {}", preview(command)), base_dir);
}

pub fn log_failure(command: &[String], detail: &str, base_dir: Option<&Path>) {
    log_note(&format!("FAILURE: {} ({})", preview(command), detail), base_dir);
}

fn preview(command: &[String]) -> String {
    let joined = command.join(" ");
    if joined.len() <= 200 { joined }
    else { take_bytes_at_char_boundary(&joined, 200).to_string() }
}
```

`take_bytes_at_char_boundary` でマルチバイト文字の途中で切断しないようにしている。日本語のような CJK 文字は UTF-8 で 3-4 バイトを消費するため、バイト単位で単純にスライスするとパニックする。

---

## メインの実行フロー——全層の統合

**ファイル: `lib.rs` の `windows_impl` モジュール（約 300 行）**

```rust
pub fn run_windows_sandbox_capture(
    policy_json_or_preset: &str,
    sandbox_policy_cwd: &Path,
    codex_home: &Path,
    command: Vec<String>,
    cwd: &Path,
    mut env_map: HashMap<String, String>,
    timeout_ms: Option<u64>,
) -> Result<CaptureResult> {
    // 1. ポリシー解析
    let policy = parse_policy(policy_json_or_preset)?;

    // 2. 環境変数の正規化
    normalize_null_device_env(&mut env_map);
    ensure_non_interactive_pager(&mut env_map);
    if should_apply_network_block(&policy) {
        apply_no_network_to_env(&mut env_map)?;
    }

    // 3. Capability SID のロード/生成
    let caps = load_or_create_cap_sids(codex_home)?;

    // 4. Restricted Token の生成（ポリシーに応じて）
    let (h_token, psid_generic, psid_workspace) = match &policy {
        SandboxPolicy::ReadOnly { .. } => {
            let psid = convert_string_sid_to_sid(&caps.readonly)?;
            let (h, _) = create_readonly_token_with_cap(psid)?;
            (h, psid, None)
        }
        SandboxPolicy::WorkspaceWrite { .. } => {
            let psid_generic = convert_string_sid_to_sid(&caps.workspace)?;
            let ws_sid = workspace_cap_sid_for_cwd(codex_home, cwd)?;
            let psid_workspace = convert_string_sid_to_sid(&ws_sid)?;
            let h = create_workspace_write_token_with_caps_from(
                base, &[psid_generic, psid_workspace]
            )?;
            (h, psid_generic, Some(psid_workspace))
        }
    };

    // 5. allow/deny パスの計算と ACE の適用
    let AllowDenyPaths { allow, deny } = compute_allow_paths(&policy, ...);
    for p in &allow { add_allow_ace(p, psid)?; }
    for p in &deny { add_deny_write_ace(p, psid_generic)?; }

    // 6. NUL デバイスへのアクセス許可
    allow_null_device(psid_generic);

    // 7. .codex と .agents ディレクトリの保護
    protect_workspace_codex_dir(&current_dir, psid_workspace)?;
    protect_workspace_agents_dir(&current_dir, psid_workspace)?;

    // 8. stdio パイプのセットアップ
    let (stdin_pair, stdout_pair, stderr_pair) = setup_stdio_pipes()?;

    // 9. CreateProcessAsUserW でサンドボックスプロセスを起動
    CreateProcessAsUserW(
        h_token,              // 制限付きトークン
        ptr::null(), cmdline.as_mut_ptr(),
        ptr::null_mut(), ptr::null_mut(),
        1,                    // ハンドル継承
        CREATE_UNICODE_ENVIRONMENT,
        env_block.as_ptr(),
        to_wide(cwd).as_ptr(),
        &si, &mut pi,
    );

    // 10. stdout/stderr を別スレッドで読み取り
    let t_out = std::thread::spawn(move || { /* ReadFile loop */ });
    let t_err = std::thread::spawn(move || { /* ReadFile loop */ });

    // 11. プロセス完了またはタイムアウトを待機
    let res = WaitForSingleObject(pi.hProcess, timeout);
    if timed_out { TerminateProcess(pi.hProcess, 1); }

    // 12. ログ記録
    if exit_code == 0 { log_success(&command, ...); }
    else { log_failure(&command, ..., ...); }

    // 13. ReadOnly の場合は ACE を revoke
    if !persist_aces {
        for (p, sid) in guards { revoke_ace(&p, sid); }
    }

    Ok(CaptureResult { exit_code, stdout, stderr, timed_out })
}
```

---

## 41 項目のスモークテスト——攻撃者の視点で検証する

**ファイル: `sandbox_smoketests.py`（約 400 行）**

Python で書かれた 41 項目のスモークテスト。**実際にサンドボックスを起動して**コマンドを実行し、期待通りに許可/拒否されるかを検証する。

### 基本的な読み書きテスト（11 項目）

| #   | テスト名                     | ポリシー       | 期待結果  |
| :-- | :--------------------------- | :------------- | :-------- |
| 1   | CWD への書き込み             | ReadOnly       | 拒否      |
| 2   | CWD への書き込み             | WorkspaceWrite | 許可      |
| 3   | ワークスペース外への書き込み | WorkspaceWrite | 拒否      |
| 3b  | 追加ルートへの書き込み       | WorkspaceWrite | 許可      |
| 3c  | 追加ルートへの書き込み       | ReadOnly       | 拒否      |
| 4   | TEMP への書き込み            | WorkspaceWrite | 許可      |
| 5   | TEMP への書き込み            | ReadOnly       | 拒否      |
| 6   | ファイル追記                 | WorkspaceWrite | 許可      |
| 7   | ファイル追記                 | ReadOnly       | 拒否      |
| 8-9 | PowerShell Set-Content       | WS/RO          | 許可/拒否 |

### ファイルシステム操作テスト（8 項目）

| #     | テスト名                        | 期待結果          |
| :---- | :------------------------------ | :---------------- |
| 10    | mkdir + 書き込み                | 許可              |
| 11    | ファイルリネーム                | 許可              |
| 12    | ファイル削除                    | 許可              |
| 24-25 | バイト書き込み（WriteAllBytes） | WS 許可 / RO 拒否 |
| 26    | 深いディレクトリ作成 + 書き込み | 許可              |
| 27    | ファイル移動                    | 許可              |
| 28    | cmd リダイレクション            | RO 拒否           |

### ネットワーク遮断テスト（3 項目）

| #   | テスト名                      | 期待結果           |
| :-- | :---------------------------- | :----------------- |
| 15  | curl でのネットワークアクセス | 拒否               |
| 16  | PowerShell Invoke-WebRequest  | 拒否               |
| 41  | Start-Process https           | 拒否（KNOWN FAIL） |

### パストラバーサル攻撃テスト（8 項目）——ここが最も重要

| #   | 攻撃手法                               | 説明                                                     | 期待結果 |
| :-- | :------------------------------------- | :------------------------------------------------------- | :------- |
| 29  | CWD ジャンクション poisoning           | CWD をジャンクション経由で外部ディレクトリに向ける       | 拒否     |
| 30  | ジャンクション → Windows               | `sys_link → C:\Windows` 経由でシステム改ざん             | 拒否     |
| 33  | 大文字小文字変更                       | `.GiT\config`（`.git` の case variation）で保護を bypass | 拒否     |
| 36  | symlink race condition                 | リンク先を高速にトグルして書き込みタイミングを狙う       | 拒否     |
| 37  | 深いジャンクション + world-writable    | junction + `icacls Everyone:(F)` の組み合わせ            | 拒否     |
| 38  | ワークスペースルート symlink poisoning | CWD 自体を `C:\` への symlink に差し替え                 | 拒否     |
| 39a | UNC パスエスケープ                     | `\\localhost\C$` 経由のアクセス                          | 拒否     |
| 39b | 他ドライブエスケープ                   | `D:\` への symlink                                       | 拒否     |

### デバイス・特殊パステスト（4 項目）

| #   | 攻撃手法                                        | 期待結果 |
| :-- | :---------------------------------------------- | :------- |
| 31a | raw デバイスアクセス（`\\.\PhysicalDrive0`）    | 拒否     |
| 31b | 名前付きパイプ作成（`\\.\pipe\codex_testpipe`） | 拒否     |
| 32a | ADS（Alternate Data Stream: `file.txt:stream`） | 拒否     |
| 32b | long-path escape（`\\?\C:\file.txt`）           | 拒否     |

### ポリシー改ざんテスト（3 項目）

| #   | 攻撃手法                                    | 期待結果 |
| :-- | :------------------------------------------ | :------- |
| 34a | cap_sid ファイルの直接書き込み              | 拒否     |
| 34b | `.codex/policy.json` の改ざん               | 拒否     |
| 35  | PATH stub bypass（偽の ssh.bat を PATH に） | 拒否     |

### その他（4 項目）

| #     | テスト名                     | 期待結果          |
| :---- | :--------------------------- | :---------------- |
| 13-14 | Python ファイル書き込み      | RO 拒否 / WS 許可 |
| 18-20 | curl/rg/git --version        | 許可（optional）  |
| 40    | タイムアウト後の外部書き込み | 拒否              |

---

## 防御の多層性——なぜ「1 つ突破されても大丈夫」なのか

| 攻撃ベクトル       | Layer 2 (Token)  | Layer 3 (ACL)  | Layer 4 (Firewall) | Layer 5 (Env)     |
| :----------------- | :--------------- | :------------- | :----------------- | :---------------- |
| CWD 外への書き込み | WRITE_RESTRICTED | allow ACE なし | —                  | —                 |
| .git 改ざん        | —                | deny ACE       | —                  | —                 |
| ネットワーク接続   | —                | —              | Outbound Block     | Proxy=localhost:9 |
| ssh 実行           | —                | —              | —                  | deny-bin stub     |
| cap_sid 改ざん     | WRITE_RESTRICTED | allow ACE なし | —                  | —                 |
| symlink escape     | —                | canonical path | —                  | —                 |
| ADS 書き込み       | WRITE_RESTRICTED | deny ACE 継承  | —                  | —                 |
| デバイスアクセス   | Token 権限不足   | —              | —                  | —                 |

---

## なぜこれが「何十億人戦略」を可能にするのか

ここまで読めば、冒頭の Sottiaux 氏の発言の技術的根拠が見えてくる。

### 1. 非エンジニアでも安全に使える理由

- **判断を求めない**: `.ssh`, `.aws`, `.git` などの保護は自動。ユーザーが「これは何？」と考える必要がない
- **危険な設定が選べない**: `DangerFullAccess` はコードレベルで排除
- **セットアップは UAC ダイアログ 1 回**: 技術的な知識ゼロで完了
- **world-writable スキャンが自動**: ユーザーの環境が安全でなければ自動で修復

### 2. 企業の IT 部門が承認できる理由

- **OS カーネルレベルの強制**: `CreateRestrictedToken` による権限制限は、アプリケーションレベルでは回避不可能
- **Windows Firewall 統合**: IT 部門が既に運用している仕組みに乗る
- **Per-workspace 隔離**: プロジェクト間のデータ漏洩を OS レベルで防止
- **監査ログ**: 全操作が `sandbox.log` に記録される
- **41 項目の攻撃テスト**: パストラバーサル、symlink race、ADS など、攻撃者視点の網羅的検証

### 3. OSS 公開が「プラットフォーム標準化」になる理由

Anthropic（Claude Code）も Google（Gemini CLI）も、Windows 上で AI エージェントを安全に実行する必要がある。しかし Windows のセキュリティ API（Restricted Token、DACL、Capability SID）を正しく使いこなすのは極めて難しい。`acl.rs` だけで 400 行、`token.rs` で 250 行の低レベル unsafe コードが必要になる。

OpenAI がこれを OSS で公開したことで、競合各社には 2 つの選択肢しかなくなる。

1. **OpenAI のコードを採用する**（事実上の標準として）
2. **同等の品質のサンドボックスをゼロから構築する**（数ヶ月の開発工数）

どちらを選んでも、OpenAI が先行者利益を得る。1 なら「業界標準を作ったのは OpenAI」という事実が残る。2 なら競合は数ヶ月遅れる。

これが Sottiaux 氏が言う「何十億人」の意味だ。安全装置を業界全体の基盤にすることで、**AI エージェントの実行環境そのものの主導権を取る**。アプリケーション層の争いを超えた、プラットフォームレベルの戦略だ。

---

## まとめ

| 特徴                          | 詳細                                                            |
| :---------------------------- | :-------------------------------------------------------------- |
| OS カーネルレベルの強制       | `CreateRestrictedToken` + DACL で回避不可能な制約               |
| Per-workspace 隔離            | ランダム Capability SID でワークスペース間の横断を防止          |
| 保護ディレクトリの絶対的 deny | `.git`, `.codex`, `.agents` は writable root 内でも書き込み不可 |
| 4 層のネットワーク遮断        | Firewall + Proxy 環境変数 + オフラインモード + deny-bin stub    |
| 秘密情報の自動除外            | `.ssh`, `.aws`, `.kube` など 10 種類をハードコードで除外        |
| 41 項目の攻撃テスト           | Junction poisoning, symlink race, ADS, UNC escape を網羅        |
| DPAPI による秘密管理          | パスワードをマシンスコープで暗号化保存                          |
| Named Mutex による排他制御    | 複数プロセスからの同時 ACL 操作を RAII で安全に処理             |

全 27 ファイル、約 3,500 行の Rust コード。これが「Setup」ボタン 1 つの裏側で動いている。

このサンドボックスの設計は、「AI エージェントが一般ユーザーのマシンでコードを実行する」という、これまで存在しなかった問題への回答だ。そしてそれを OSS で公開したことは、OpenAI が**アプリケーション競争ではなくプラットフォーム競争で勝とうとしている**ことの技術的証拠にほかならない。

:::message
この記事は、GitHub API（`gh api`）を使って全ソースコードを正確に取得し、精読した結果に基づいている。WebFetch による要約ではなく、実際のコードの全容を解説している。
:::
