# C155 — E 盘与 <OTHER_VM_LABEL> 快照链治理记录（2026-09-23）

## 0. 结论摘要

| 指标 | 治理前 | 治理后 | 变化 |
|---|---|---|---|
| E: 总容量 | 954G | 954G | — |
| E: 已用 | 936G | 685G | -251G |
| E: 可用 | 18G (99%) | 270G (72%) | +252G |
| <HOST_PATH>\VMs\<OTHER_VM_LABEL> | 299G | 128G | -171G |
| <HOST_PATH>\VMs\_read | 80G | ~0（仅剩 found/） | -80G |
| 快照节点数 | 48 | 16 | -32 |
| 孤儿介质登记 | 12 | 0 | -12 |

回收动作全部通过 VBoxManage 完成（snapshot delete / closemedium disk --delete），
未手工删除任何 .vdi / .sav 文件，未修改 EPT 权威样本，未回滚任何快照。

## 1. WSL 侧 VirtualBox 通道问题与绕行

<HOST_PATH>/Program Files 在 WSL 互操作下 stdout 不被捕获
（直接执行与 cmd.exe /C、powershell.exe 均返回空输出，但 exitCode=0）。

绕行方案（已验证可用，后续沿用）：

    cd <HOST_PATH>
    cmd.exe /C "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" snapshot <OTHER_VM_LABEL> list > vbox_out.txt 2>&1

即 Windows 侧执行 + 重定向到文件 + WSL 读回。不要依赖互操作 stdout。

## 2. 治理前快照树（48 节点）

当前分支（保留，未被触碰）：

    base (48491bc7)
    └── post-bootstrap (ca4a46e5)
        └── pre-ept (541531cd)
            ├── a2-run (099eab25)
            ├── b-run (96892e8b) → post-real-run (ec7bcf5c)
            └── c2-pre (9be816e8) → pre-drvload-20260913 (4dd3fc70)
                → pre-hexpatch-build-20260914 (56f4122b)
                → pre-current-driver-lifecycle-20260914 (5d802327)
                → pre-vtpm-20260914 (911bd9a4)
                → qoder-armed-20260919 (ad2c4f36) ← CurrentSnapshot

死端分支（清理对象）：
- 19 个 ept-real-decode-20260922{D..H15}-postmortem，自述 not evidence / instrument failure / not completion evidence
- 11 个 qoder-baked-20260921{b..k}，描述完全重复（arm22c.ps1 baked + EPTARM22 boot task）
- ept-real-decode-20260922A→B→C 共享镜像链（三条均 not evidence）
- qoder-backup-20260919（genB 暂存态，与当前快照冗余）
- qoder-armed2-20260919（policy-only 变体，冗余）

## 3. 实际执行的回收动作

### 3.1 快照删除（32 个，全部 rc=0，无合并阻塞）

| 批次 | 数量 | 目标 | 日志 |
|---|---|---|---|
| 试删 | 1 | ept-real-decode-20260922H15-postmortem | vbox_delete_H15.log |
| 批 1 | 16 | D/E/F/G/H2..H14-postmortem | vbox_delete_batch1.log |
| 批 2 | 15 | baked×10 + A/B/C + qoder-backup + qoder-armed2 | vbox_delete_batch2.log |

每个死端叶子快照删除耗时约 0.5–2s，未触发父盘合并（死端叶子 delta 无下游依赖，直接落盘删除）。

### 3.2 离线取证 VHD 回收（4 个，80G）

依据：<HOST_PATH> 记录这三块 VHD 内的
Hardware.exe 均为 genA 且已交叉核对，且已提取到手；genB 仅存在于 <OTHER_VM_LABEL> 活动 VDI，
不在这批 VHD 内。提取产物（199M）保留在 _reference/。

| 文件 | 大小 | 内容去向 |
|---|---|---|
| acceptance-r14-current.vhd | 18.9G | _reference/EPT/v5.0_sample/EPTv5_from_r14_vm.exe |
| current-state.vhd | 33.1G | genA 已交叉核对，无独立产物 |
| ept-real-run.vhd | 17.3G | _reference/EPT/vm_artifacts/ept-real-run_20260912/ |
| ept-run-current.vhd | 16.4G | genA 已交叉核对，无独立产物 |

删除前元数据留档：C155_read_vhd_predelete_inventory.txt。

### 3.3 孤儿介质登记注销（8 个）

<HOST_PATH>/vmctl/*.vhd（6 个）与 <HOST_PATH>/VMs/hexpatch-inject/*（2 个）目录已不存在，
但登记仍留在全局 VirtualBox.xml，会导致 VirtualBox 启动时报缺失介质。
已用 closemedium disk <uuid>（不带 --delete）注销，日志：vbox_closemedium_stale.log。

## 4. 治理后保留状态（16 节点）

    base, post-bootstrap, pre-ept,
    a2-run, b-run, post-real-run, c2-pre,
    pre-drvload-20260913, pre-hexpatch-build-20260914,
    pre-current-driver-lifecycle-20260914, pre-vtpm-20260914,
    qoder-armed-20260919 (★ CurrentSnapshot),
    ├── qoder-clean-20260920
    │   └── qoder-baked-20260921k
    ├── pre-ept-run-20260922          (decode-core 前安全点)
    └── ept-real-decode-20260922H5-postmortem  (C153 对应的 H5 现场，保留备查)

保留理由：
- pre-ept 及更早：EPT 原始采集基线，不可再生
- qoder-armed-20260919：当前态，genB 已就位（cfa6998e），是主线实验的起点
- qoder-clean-20260920：干净可回滚基线
- qoder-baked-20260921k：最后一版烘焙臂（channel-free），保留一份以防需要
- pre-ept-run-20260922：decode-core 运行前安全点
- H5-postmortem：C153 证据指向的现场，唯一保留的 postmortem

## 5. 配置与校验

配置备份（含 SHA-256）：artifacts/evidence/vbox_config_backup_20260923/

| 文件 | SHA-256 |
|---|---|
| <OTHER_VM_LABEL>.vbox | 567534c5150818371a74980fe9beab0f363b0328a5452ab2927163a53c8ba336 |
| <OTHER_VM_LABEL>.vbox-prev | 6f3267124c0ab218355100ebc96b9ede13148569bdf3c0a90d8518226ba61268 |
| VirtualBox.xml | 62fe5f12223528fdf0e73a066d14082774792e0588899e27eed417e207b63052 |

治理后验证：
- showvminfo <OTHER_VM_LABEL> → rc=0，State: powered off (since 2026-09-22T17:31:56)
- 快照树 16 节点，qoder-armed-20260919 * 标记仍在
- 共享目录 HexPatch → <HOST_PATH>\HexPatch 映射未变
- EPT 权威样本未触碰：<HOST_PATH> 保持原状

## 6. 未处理项（需人工决定）

| 对象 | 大小 | 说明 |
|---|---|---|
| <HOST_PATH>\VMs\<OTHER_VM_LABEL> | 21G | 已注册 VM，2026-09-22 创建，含 1 个快照；归属待确认 |
| <HOST_PATH>\VMs\<OTHER_VM_LABEL>\share\{ghidra,jdk21}.zip | 0.65G | 可重下安装包 |
| <HOST_PATH>\VirtualBox VMs\<OTHER_VM_LABEL> | 未测 | 已注册 VM，非 EPT 主线 |
| <HOST_PATH>\cachy桌面构建\vbox\<OTHER_VM_LABEL> | 未测 | 已注册 VM，非 EPT 主线 |

以上均未触碰。

## 7. 最终收尾（同轮追加）

- 交叉核对快照目录与 VM 注册表，发现 2 个已无对应快照节点的孤儿状态文件并删除：
  - 2026-09-19T09-44-22-271513500Z.sav（1.75G）
  - 2026-09-19T08-01-59-422486300Z.sav（0.63G）
- 最终空间：E: 可用 18G -> 272G（+254G），已用 936G -> 683G。
- EPT 权威样本完整性核验：sample/EPT专业游戏维修工具箱V5.1.exe
  SHA-256 = ca6b4c6a9a4ddc1c791a0bb3e98585856540c2baa7cac73f92cb21d87acaa3b2
  与 artifacts/CHECKSUMS.sha256 第 3 行记录逐字节一致，样本未被触碰。
- 防膨胀规则已落盘：method/DISK_BUDGET.md；空间守卫脚本：method/disk_guard.sh（只读，含 60G 停止线 / 100G 警戒线）。
